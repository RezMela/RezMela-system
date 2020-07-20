// NPC team rezzor v0.3
//
// v0.3 - fix for reading wrong prim name for team allocation
// v0.2 - add following behaviour when object moved
//
// When this object is rezzed, NPCs are created according to the notecards in inv.
//
// If the prim description is "debug", no NPC is created. That allows maintenance:
//
// - Normal click on scripted prim to rez an NPC (rezzer remains)
// - Long-click (click and hold) on scripted prim to clone your avatar to the notecard
//
// So to update the weapon, wear the weapon and long-click. You can click the rezzer to test or take a copy of
// the rezzer and change its description in inventory to make an automatic version.
//
// Multiple notecards containing different avatar data can be in the contents. Ideally these should match the number
// of prims in the rezzer (ie the number of NPCs, each looking different) but that's not essential. Supernumerary
// NPCs will be clones of the first.
//

integer CHAT_CHANNEL = 29904047;		// chat channel for RegionSay comms

float TIMER_PERIOD = 1.2;		// period of timer when idle, for detection of changed position/rotation and for long-click timing

key ClickAvId;
key NpcId;
key WeaponId;
integer ListenHandle;
integer IsDebug;

vector MyPos;
rotation MyRot;
vector LastPos;
rotation LastRot;

integer NpcCount;		// count of NPCs who have not yet been communicated with (doesn't include those who have)
integer NotecardCount;	// number of notecards in inventory

string FactionUs;
string FactionThem;

list NpcIds;		// list of all NPCs this rezzer has spawned
list NpcPosLocals;	// parallel list of the local position of their spawning prims

integer LM_DELETE_RECEIVED = -7044002;

MoveNpcs() {
	integer N;
	for (N = 0; N < NpcCount; N++) {
		key NpcId = llList2Key(NpcIds, N);
		vector PosLocal = llList2Vector(NpcPosLocals, N);
		vector PosRegion = MyPos + (PosLocal * MyRot);
		osNpcMoveToTarget(NpcId, PosRegion + <0.0, 0.0, 1.0>, OS_NPC_NO_FLY);
	}
	LastPos = MyPos;
	LastRot = MyRot;
}
default {
	on_rez(integer start_param)	{ llResetScript(); }
	state_entry()	{
		string RootDescription = llList2String(llGetLinkPrimitiveParams(1, [ PRIM_DESC ]), 0);	// get root prim description
		if (llToUpper(RootDescription) == "DEBUG") {
			IsDebug = TRUE;
			llOwnerSay("Running in debug mode");
		}
		state Init;
	}
}
state Init {
	on_rez(integer start_param)	{ llResetScript(); }
	state_entry()	{
		// Extract faction names from object name
		// Format of name is: <name>: <us>/<enemy>
		// where <name> is description of object ("NPC rezzer" or whatever), <us> is our NPCs' faction and <them> is the opposing faction
		// eg: "Solder rezzer: Red/Blue" for Red soldiers who target Blue soldiers
		string Str = llGetLinkName(LINK_THIS);		// get name of root prim
		integer P = llSubStringIndex(Str, ":");
		Str = llStringTrim(llGetSubString(Str, P + 1, -1), STRING_TRIM);
		P = llSubStringIndex(Str, "/");
		FactionUs = llStringTrim(llGetSubString(Str, 0, P - 1), STRING_TRIM);
		FactionThem = llStringTrim(llGetSubString(Str, P + 1, -1), STRING_TRIM);
		// Get notecard names into list
		if (IsDebug) state Idle;
		LastPos = llGetRootPosition();
		LastRot = llGetRot();
		state RezNPCs;
	}
}
state Idle {
	on_rez(integer start_param)	{ llResetScript(); }
	state_entry()	{
		ClickAvId = NULL_KEY;
		llSetTimerEvent(TIMER_PERIOD);
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == LM_DELETE_RECEIVED && !IsDebug) {	// message from RezMela board to delete rezzer and associated NPCs
			integer I = llGetListLength(NpcIds);
			while(I--) {
				osNpcRemove(llList2Key(NpcIds, I));
			}
			llDie();
		}
	}
	// touch and timer processing combines to implement short- and long-click handling
	touch_start(integer Total)	{
		ClickAvId = llDetectedKey(0);
		llSetTimerEvent(TIMER_PERIOD);	// timer value gives long-click delay
	}
	touch_end(integer Total) {
		if (ClickAvId != NULL_KEY) {
			// short click
			llSetTimerEvent(TIMER_PERIOD);
			state RezNPCs;
		}
	}
	timer() {
		if (ClickAvId != NULL_KEY) {
			// long click
			llSetTimerEvent(TIMER_PERIOD);
			string Name = llKey2Name(ClickAvId);
			llRegionSayTo(ClickAvId, 0, "Copying " + Name);
			osAgentSaveAppearance(ClickAvId, "NPC avatar data");
			llRegionSayTo(ClickAvId, 0, "Copied.");
			ClickAvId = NULL_KEY;
		}
		MyPos = llGetRootPosition();
		MyRot = llGetRot();
		if (llVecDist(LastPos, MyPos) > 0.1 || MyRot != LastRot) {	// if world object has moved or rotated significantly
			MoveNpcs();		// move npcs to new positions
		}
	}
}
// Rez a batch of NPCs
state RezNPCs {
	on_rez(integer start_param)	{ llResetScript(); }
	state_entry()	{
		MyRot = llGetRot();
		NpcIds = [];
		NpcPosLocals = [];
		NpcCount = 0;
		NotecardCount = llGetInventoryNumber(INVENTORY_NOTECARD);
		vector RootPos = llGetRootPosition();
		integer P = llGetNumberOfPrims();
		while (P > 1) {
			// get associated notecard
			integer N = (integer)llFrand((float)NotecardCount);
			string Notecard = llGetInventoryName(INVENTORY_NOTECARD, N);		// get notecard name
			vector LocalPos = llList2Vector(llGetLinkPrimitiveParams(P, [ PRIM_POS_LOCAL ]), 0);
			vector RegionPos = RootPos + (LocalPos * MyRot);
			integer Num = 100 + (integer)llFrand(899.0);		// get pseudo-unique number for NPC surname
			NpcId = osNpcCreate(FactionUs, (string)Num, RegionPos + <0.0, 0.0, 1.0>, Notecard);
			NpcIds += NpcId;
			NpcPosLocals += LocalPos;
			NpcCount++;			// this is the count of NPCs we're rezzing (not including any already rezzed)
			P--;
		}
		state Comms;
	}
}
// Comms - communicate with the NPCs we've rezzed
state Comms {
	on_rez(integer start_param)	{ llResetScript(); }
	state_entry()	{
		llListen(CHAT_CHANNEL, "", NULL_KEY, "");
		llSetTimerEvent(20.0);		// timeout in case an NPC doesn't respond
	}
	listen(integer Channel, string Name, key Id, string Message) {
		string MessageType = llGetSubString(Message, 0, 0);
		if (MessageType == "R") {		// notification from weapon secondary
			key tId = (key)llGetSubString(Message, 1, -1);		// get NPC's UUID (Id of listen event is other weapon's UUID)
			integer P = llListFindList(NpcIds, [ tId ]);		// look it up in our table of rezzed NPCs
			if (P > -1) {		// it's one of ours
				llRegionSayTo(Id, CHAT_CHANNEL, "F" + FactionThem);		// tell them the faction to target
				NpcCount--;		// one less left to tell
				if (NpcCount == 0) {
					NpcCount = llGetListLength(NpcIds);		// from now on, NpcCount is simply the number of NPCs
					state Idle;			// we've informed all our NPCs, so return to idle state
				}
			}
		}
	}
	timer() {		// timeout - not all NPCs responded, so quietly forget about it
		llOwnerSay("NPC rezzer timeout");
		state Idle;
	}
}
// NPC team rezzor v0.3