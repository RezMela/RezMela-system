// Door animator for windows v.0.2
//
// Instructions:
// 1. Use normal door animator to set up door, window and other prims separately in open and closed positions
// 2. Remove scripts from door, window, etc prims
// 3. Put other prim names (must be unique) into a notecard called "Door data" in door, one on each line
// 4. Put this script in main door prim
//
string NOTECARD_NAME = "Door data";
integer IsOpen = FALSE;

integer WindowLinkNum;
list OpenParams;
list CloseParams;

string ThisScriptName;
string ThisPrimName;
integer ThisLinkNum;
integer PrimCount;

key OwnerID;
string Sound;

OpenClose(integer Open) {
	IsOpen = Open;
	list Params = [];
	if (Open) {
		llSetPrimitiveParams(OpenParams);
	}
	else {
		llSetPrimitiveParams(CloseParams);
	}
	if (Sound != "") llTriggerSound(Sound, 1.0);
}
// Find all the necessary data about prims - return FALSE if anything wrong
integer GetData() {
	// First, some basic sanity checks
	if (PrimCount == 1) return FALSE;	// Unlinked, so fail silently
	if (ThisLinkNum == 1) {		// In the root prim
		llOwnerSay("Script '" + ThisScriptName + "' should not be in root prim");
		return FALSE;
	}
	OpenParams = CloseParams = [];		// initialise both lists
	// First, get door data for main prim (the one this script is in)
	if (!GetPrimParams(ThisLinkNum)) return FALSE;

	// build table of link numbers and prim names (note that we know we're linked)
	list Links = [];
	integer P;
	for(P = 1; P <= PrimCount; P++) {
		Links += [ P, llGetLinkName(P) ];
	}
	list Prims =  llParseString2List(osGetNotecard(NOTECARD_NAME), [ "\n" ], []);	// Read prim names into list from notecard
	integer Lines = llGetListLength(Prims);
	integer LineNum;
	for(LineNum = 0; LineNum < Lines; LineNum++) {
		string PrimName = llList2String(Prims, LineNum);	// Prim name from notecard
		integer LinkPtr = llListFindList(Links, [ PrimName ]);	// Look for it in link numbers table
		if (LinkPtr == -1) {	// it's not found - the prim name in the notecard doesn't exist in the linkset
			llOwnerSay("Prim not found: '" + PrimName + "' (referenced in '" + NOTECARD_NAME + "' in prim '" + llGetObjectName() + "'");
			return FALSE;
		}
		integer LinkNum = llList2Integer(Links, LinkPtr - 1);	// Link number precedes prim name in links table
		// Get prim params for this one
		if (!GetPrimParams(LinkNum)) return FALSE;
	}
	return TRUE;
}
// Get open/close params (in llSetPrimitiveParams format) from given link number
integer GetPrimParams(integer LinkNum) {
	OpenParams += [ PRIM_LINK_TARGET, LinkNum ];
	CloseParams += [ PRIM_LINK_TARGET, LinkNum ];
	string Desc =  llList2String(llGetLinkPrimitiveParams(LinkNum, [ PRIM_DESC ]), 0);	// get description from prim
	if (llGetSubString(Desc, 0, 1) != "@D") {	// it's not in the correct format
		llOwnerSay("Door description not in correct format for prim '" + llGetObjectName() + "'");
		return FALSE;
	}
	// Get the parts from the description
	list Parts = llParseStringKeepNulls(llGetSubString(Desc, 2, -1), [ "/" ], []);
	vector ClosedPos = (vector)llList2String(Parts, 0);
	rotation ClosedRot = (rotation)llList2String(Parts, 1);
	vector OpenPos = (vector)llList2String(Parts, 2);
	rotation OpenRot = (rotation)llList2String(Parts, 3);
	OpenParams += [ PRIM_POS_LOCAL, OpenPos, PRIM_ROT_LOCAL, OpenRot ];
	CloseParams += [ PRIM_POS_LOCAL, ClosedPos, PRIM_ROT_LOCAL, ClosedRot ];
	return TRUE;
}

default {
	state_entry() {
		state Bootup;
	}
}
state Bootup {
	on_rez(integer Start) { state Bootup; }
	state_entry() {
		OwnerID = llGetOwner();
		if (llGetInventoryNumber(INVENTORY_SOUND) == 1)
			Sound = llGetInventoryName(INVENTORY_SOUND, 0);
		else
			Sound = "";

		ThisScriptName = llGetScriptName();
		ThisPrimName = llGetObjectName();
		ThisLinkNum = llGetLinkNumber();
		PrimCount = llGetNumberOfPrims();

		// Read notecard and find open/close data in the prims
		if (!GetData()) state Hang;
		state Normal;
	}
}
state Normal  {
	on_rez(integer Start) { state Bootup; }
	state_entry() {
		OpenClose(FALSE);
	}
	touch_start(integer Total) {
		OpenClose(!IsOpen);
	}
	changed(integer Change)	{
		if (Change & CHANGED_INVENTORY) state Bootup;
		if (Change & CHANGED_LINK) {
			if (!GetData()) state Hang;
		}
	}
}
state Hang {
	on_rez(integer Start) { state Bootup; }
	changed(integer Change) {
		if (Change & CHANGED_LINK) state Bootup;
		if (Change & CHANGED_INVENTORY) state Bootup;
	}
}
// Door animator for windows v.0.2