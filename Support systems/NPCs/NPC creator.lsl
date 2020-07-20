// NPC creator v1.2

// DEEPSEMAPHORE CONFIDENTIAL
// __
//
//  [2018] - [2028] DEEPSEMAPHORE LLC
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of DEEPSEMAPHORE LLC and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to DEEPSEMAPHORE LLC
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from DEEPSEMAPHORE LLC. For more information, or requests for code inspection,
// or modification, contact support@rezmela.com

// v1.2 - don't log error if MessageObject key is null

string CONFIG_NOTECARD = "NPC creation config";

float TIMER_FAST = 1.0;
float TIMER_SLOW = 5.0;

integer NPC_CONTROL_CHANNEL = -72;

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
key ModuleId;

integer ServerMessageNeeded = FALSE;

integer NpcSitting = FALSE;
integer NpcMoving = FALSE;
integer IsSelected = FALSE;

// LM values from WorldObject (we'll need this for Maps)
integer WO_SELECT = 3005;
integer WO_DESELECT = 3006;

// LMs for ML (Apps/Maps engine)
integer LM_LOADING_COMPLETE = -405530;
integer LM_RESET = -405535;
integer LM_MOVED_ROTATED = -405560;
integer LM_DELETE_RECEIVED = -7044002;

// LMs for Moveable Prim (Apps)
integer MP_DO_NOT_DELETE 	= -818442500;
integer MP_DELETE_OBJECT	= -818442501;

vector LastPos;
rotation LastRot;

CreateNpc() {
	string NpcNotecard = GetFirstNotecard();
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
	ServerMessageNeeded = TRUE;
	llSetTimerEvent(TIMER_FAST);
}
SetStandRotation() {
	if (NpcExists()) osNpcSetRot(NpcId, llGetRot() * StandRotation);
}
MoveNpc() {
	SendToServer("M", [ NpcId, llGetPos() ]);
}
RemoveNpc() {
	SendToServer("R", [ NpcId ]); // tell server to remove NPC
	NpcId = NULL_KEY;
}
integer NpcExists() {
	return (NpcId != NULL_KEY && llGetObjectDetails(NpcId, [ OBJECT_POS ]) != []);
}
OnRez(integer Param) {
	ReadConfig();
	// Continue and create NPC if it's rezzed by rezzor, not by hand
	if (Param) {
		ModuleId = osGetRezzingObject();
		state Wait;
	}
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
	FloatingText = "";
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
							// 2. Animation = Inventory			// animate with whatever's in inventory
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
	llSetText(FloatingText, <1.0, 1.0, 1.0>, 1.0);
	llSitTarget(SitTarget, SitRotation);
}
// Takes a string in double quotes, and strips out the quotes. Validates the format.
// This is a variation that tolerates missing quotes. Mandatory quotes were an OK idea in theory, but more hassle
// than it's worth.
//
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
		return Text;
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
// Send message to NPC server in correct format
SendToServer(string Command, list Params) {
    list Message = [ "*NPC*", Command ] + Params;	
	MessageObject(ModuleId, Message);
}
// Wrapper for osMessageObject
MessageObject(key Destination, list Message) {
	if (Destination == NULL_KEY) return; // we're tolerant of this because it does happen somehow on occassions
	if (ObjectExists(Destination)) {
		osMessageObject(Destination, llDumpList2String(Message, "|"));
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
LogError(string Text) {
	llRegionSay(-7563234, Text);
}
default {
	on_rez(integer Param) { OnRez(Param); }
	state_entry() {
		ReadConfig();	// If not rezzed by ML, just read the config file
	}
}
state Wait {
	on_rez(integer Param) { OnRez(Param); }
	state_entry() {
		llSetTimerEvent(4.0);
	}
	timer() {
		state Normal;
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == LM_LOADING_COMPLETE) {	// Message from ML
			state Normal;
		}
	}
}
state Normal {
	on_rez(integer Param) { OnRez(Param); }
	state_entry() {
		llSetTimerEvent(TIMER_SLOW);
		SendToServer("Q", []); // Request permission to creat NPC
		IsSelected = FALSE;
		LastPos = llGetPos();
		LastRot = llGetRot();
		llMessageLinked(LINK_THIS, MP_DO_NOT_DELETE, "", NULL_KEY);	// tell moveable prim script not to delete us (we'll do that)
	}
	changed(integer Change)	{
		// If the region was restarted and we're not a zombie (unlinked) object
		if (Change & (CHANGED_REGION_RESTART | CHANGED_REGION_START) && llGetNumberOfPrims() > 1) {
			SendToServer("Q", []); // Request permission to create NPC
		}
		if (Change & CHANGED_INVENTORY) ReadConfig();
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number== LM_DELETE_RECEIVED){
			RemoveNpc();
		}
		else if (Number == LM_MOVED_ROTATED) {
			MoveNpc();
		}
		else if (Number == MP_DELETE_OBJECT) {	// moveable prim script tells us it's time to die
			RemoveNpc();	// remove the NPC (which is why we're doing our own deletion in the first place)
			state Die;
		}
		else if (Number == WO_SELECT) {
			IsSelected = TRUE;
			MoveNpc();
		}
		else if (Number == WO_DESELECT) {
			IsSelected = FALSE;
			MoveNpc();
		}
		else if (Number == LM_RESET) {
			RemoveNpc();
			llResetScript();
		}
	}
	dataserver(key Id, string Data) {
		if (llGetSubString(Data, 0, 4) == "*NPC*") {
			// Format of messages is: *NPC*|<command>|<data>
			list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
			string Command = llList2String(Parts, 1);
			list Params = llList2List(Parts, 2, -1);
			if (Command == "Q") {		// Received permission to create an NPC
				CreateNpc();
			}
		}
	}
	timer() {
		if (ServerMessageNeeded) {
			SendToServer("C", [ NpcId ]); // tell server that we've created this NPC
			ServerMessageNeeded = FALSE;
		}
	}
}
state Die {
	on_rez(integer Param) { OnRez(Param); }
	state_entry() {
		llDie();
	}
}
// NPC creator v1.2