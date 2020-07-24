// Basic NPC creation v0.5

// v0.5 - implement avatar animation
// v0.4 - added config file and sit and animate functions
// v0.3 - pick up avatar name from prim description (if it's two words)

string CONFIG_NOTECARD = "NPC creation config";

key NpcId;
string Forename;
string Surname;
vector SitTarget;
rotation SitRotation;
rotation StandRotation;
string Animation;
integer RespawnOnMove;
vector SpawnPosOffset;
string FloatingText;

integer NpcSitting = FALSE;
integer NpcMoving = FALSE;
integer IsSelected = FALSE;

// LM values from WorldObject
integer WO_SELECT = 3005;
integer WO_DESELECT = 3006;
integer LM_DELETE_RECEIVED = -7044002;

vector LastPos;
rotation LastRot;

CreateNpc() {
	string NpcNotecard = GetFirstNotecard();
	if (Forename + Surname == "") {
		list L = llParseStringKeepNulls(llGetObjectDesc(), [ " " ], []);
		if (llGetListLength(L) == 2) {
			Forename = llList2String(L, 0);
			Surname = llList2String(L, 1);
		}
		else {
			Forename = NpcNotecard;
		}
	}
	NpcId = osNpcCreate(Forename, Surname, llGetPos() + SpawnPosOffset, NpcNotecard);
	if (SitTarget != ZERO_VECTOR) {
		NpcSitting = TRUE;
		osNpcSit(NpcId, llGetKey(), OS_NPC_SIT_NOW);
	}
	else {
		NpcSitting = FALSE;
		SetStandRotation();
	}
	if (Animation != "") osNpcPlayAnimation(NpcId, Animation);
}
SetStandRotation() {
	osNpcSetRot(NpcId, llGetRot() * StandRotation);
}
MoveNpc() {
	if (NpcId == NULL_KEY) return;
	if (NpcSitting) return;		// if NPC is sitting, they'll move with the object
	vector MyPos = llGetPos();
	rotation MyRot = llGetRot();
	if (llVecDist(LastPos, MyPos) > 0.1 || MyRot != LastRot) {	// if world object has moved or rotated significantly
		if (RespawnOnMove) {
			// if this option is specified in config, we simply respawn the NPC
			RemoveNpc();
			CreateNpc();
		}
		else {
			osNpcMoveToTarget(NpcId, MyPos, OS_NPC_NO_FLY);	// tell NPC to come here
			NpcMoving = TRUE;
		}
		LastPos = MyPos;
		LastRot = MyRot;
	}
	if (NpcMoving) {
		integer AgentInfo = llGetAgentInfo(NpcId);
		if (AgentInfo & AGENT_WALKING) {	// still walking, so wait for them to arrive
			llSetTimerEvent(1.0);
		}
		else {
			// they've presumably arrived, so rotate them if necessary
			SetStandRotation();
			if (!IsSelected)
				llSetTimerEvent(0.0);	// and stop the timer, since we don't need to do this any more
			NpcMoving = FALSE;
		}
	}
	else {	// NPC is not moving
		// if the object is selected, keep checking to see if it's been moved or rotated
		if (IsSelected) llSetTimerEvent(2.0);
		else llSetTimerEvent(0.0);
	}
}
RemoveNpc() {
	osNpcSay(NpcId, "Goodbye!");
	osNpcRemove(NpcId);
	NpcId = NULL_KEY;
}
// Returns first notecard that is NOT the config card
string GetFirstNotecard() {
	integer Num = llGetInventoryNumber(INVENTORY_NOTECARD);
	integer N;
	for (N = 0; N < Num; N++) {
		string CardName = llGetInventoryName(INVENTORY_NOTECARD, N);
		if (CardName != CONFIG_NOTECARD) return CardName;
	}
	return "";
}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
// Note that notecard is optional, but defaults are set if missing
ReadConfig() {
	// Set config defaults
	Forename = Surname = "";
	SitTarget = ZERO_VECTOR;	// by default, no sit target
	SitRotation = ZERO_ROTATION;
	StandRotation = ZERO_ROTATION;
	RespawnOnMove = FALSE;
	SpawnPosOffset = <0.0, 0.0, 2.0>;
	FloatingText = "Avatar Creator";
	Animation = "";
	// If no notecard, skip to post-processing
	if (llGetInventoryType(CONFIG_NOTECARD) == INVENTORY_NOTECARD) {
		integer Lines = osGetNumberOfNotecardLines(CONFIG_NOTECARD);
		integer I;
		for(I = 0; I < Lines; I++) {
			string Line = osGetNotecardLine(CONFIG_NOTECARD, I);
			integer Comment = llSubStringIndex(Line, "//");
			if (Comment != 0) {	// Not a complete comment line
				if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);	// strip from comments characters onwards
				if (llStringTrim(Line, STRING_TRIM) != "") {	// if there's something left after comments are removed
					// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
					list L = llParseStringKeepNulls(Line, [ "=" ], [ ]);	// Separate LHS and RHS of assignment
					if (llGetListLength(L) == 2) {	// so there is a "X = Y" kind of syntax
						string OName = llStringTrim(llList2String(L, 0), STRING_TRIM);		// original parameter name
						string Name = llToLower(OName);		// lower-case version for case-independent parsing
						string Value = llStringTrim(llList2String(L, 1), STRING_TRIM);
						// Interpret name/value pairs
						if (Name == "forename")	Forename = StripQuotes(Value, Line);
						else if (Name == "surname")	Surname = StripQuotes(Value, Line);
						else if (Name == "sittarget") SitTarget = (vector)Value;
						else if (Name == "sitrotation") SitRotation = String2Rot(Value);
						else if (Name == "standrotation") StandRotation = String2Rot(Value);
						else if (Name == "positionoffset") SpawnPosOffset = (vector)Value;
						else if (Name == "respawnonmove") RespawnOnMove = String2Bool(Value);
						else if (Name == "floatingtext") FloatingText = StripQuotes(Value, Line);
						else if (Name == "animation") {
							// Can be either:
							// 1. Animation = "jazz hands"		// animate with jazz hands (for example)
							// or:
							// 2. Animation = inventory			// animate with whatever's in inventory
							if (llToLower(Value) == "inventory")
								Animation = llGetInventoryName(INVENTORY_ANIMATION, 0);
							else
								Animation = StripQuotes(Value, Line);

						}
						else llOwnerSay("Invalid keyword in config file: '" + OName + "'");
					}
					else {
						llOwnerSay("Invalid line in config file: " + Line);
					}
				}
			}
		}
	}
	llSitTarget(SitTarget, SitRotation);
}
//     Takes a string in double quotes, and strips out the quotes. Validates the format.
// <Text> is the string with quotes; <Line> is the entire line for error reporting
string StripQuotes(string Text, string Line) {
	if (Text == "") {    // allow empty string
		return("");
	}
	if (Text == "\"\"") {    // allow empty string in quotes
		return("");
	}
	if (llGetSubString(Text, 0, 0) == "\"" && llGetSubString(Text, -1, -1) == "\"") {     // if surrounded by quotes
		return(llGetSubString(Text, 1, -2));    // strip quotes
	}
	else {
		llOwnerSay("Invalid string literal (missing \"\"?): " + Line);
		return("");
	}
}
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
// Convert Euler degrees (as string) to quaternion rotation
// Also handles string quaternion input
rotation String2Rot(string Value) {
	integer Parts = llGetListLength(llCSV2List(llGetSubString(Value, 1, -2)));    // count the number of parts
	if (Parts == 3) // vector
		return(llEuler2Rot((vector)Value * DEG_TO_RAD));
	else            // assume quaternion
		return((rotation)Value);
}
default {
	on_rez(integer Param) {
		ReadConfig();
		// Create NPC if it's rezzed by rezzor, not by hand
		if (Param) {
			CreateNpc();
		}
		IsSelected = FALSE;
		if (FloatingText != "") llSetText(FloatingText, <1.0, 1.0, 1.0>, 1.0);
		LastPos = llGetPos();
		LastRot = llGetRot();
	}
	changed(integer Change)	{
		if (Change & (CHANGED_REGION_RESTART | CHANGED_REGION_START)) {
			CreateNpc();
		}
		if (Change & CHANGED_INVENTORY) ReadConfig();
	}
	touch(integer Count) {
		RemoveNpc();
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number== LM_DELETE_RECEIVED){
			RemoveNpc();
		}
		else if (Number == WO_SELECT) {
			IsSelected = TRUE;
			MoveNpc();
		}
		else if (Number == WO_DESELECT) {
			IsSelected = FALSE;
			MoveNpc();
		}
	}
	timer() {
		MoveNpc();
	}
}
// Basic NPC creation v0.5