// Object creator v0.1

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

string CONFIG_NOTECARD = "Creator config";
string OBJECTS_NOTECARD = "Creator objects";

// LMs for ML (Composer)
integer LM_EXTERNAL_LOGIN = -405521;
integer LM_EXTERNAL_LOGOUT = -405522;
integer LM_LOADING_COMPLETE = -405530;
integer LM_RESET = -405535;
integer LM_MOVED_ROTATED = -405560;
integer LM_DELETE_RECEIVED = -7044002;

// LMs for Moveable Prim (Apps)
integer MP_DO_NOT_DELETE 	= -818442500;
integer MP_DELETE_OBJECT	= -818442501;

list Objects = [];
integer OBJ_UUID = 0;
integer OBJ_NAME = 1;
integer OBJ_POSITION = 2;
integer OBJ_ROTATION = 3;
integer OBJ_STRIDE = 4;
integer ObjectsCount = 0; // number of strides, not elements

// Config variables
float AlphaLoggedIn;
float AlphaLoggedOut;

// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	// Set config defaults
	AlphaLoggedIn = 1.0;
	AlphaLoggedOut = 1.0;
	//
	integer Errors = 0;
	string ConfigContents = osGetNotecard(CONFIG_NOTECARD);	// Set config defaults
	list Lines = llParseStringKeepNulls(ConfigContents, [ "\n" ], []);
	integer LineCount = llGetListLength(Lines);
	integer I;
	for(I = 0; I < LineCount; I++) {
		string Line = llList2String(Lines, I);
		integer Comment = llSubStringIndex(Line, "//");
		if (Comment != 0) {    // Not a complete comment line
			if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);    // strip from comments characters onwards
			if (llStringTrim(Line, STRING_TRIM) != "") {    // if there's something left after comments are removed
				// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
				integer Equals = llSubStringIndex(Line, "=");
				if (Equals > -1) {    // so there is a "X = Y" kind of syntax
					string OName = llStringTrim(llGetSubString(Line, 0, Equals - 1), STRING_TRIM);        // original parameter name
					string Name = llToLower(OName);        // lower-case version for case-independent parsing
					string Value = llStringTrim(llGetSubString(Line, Equals + 1, -1), STRING_TRIM);
					// Interpret name/value pairs
					if (Name == "alphaloggedin") AlphaLoggedIn = (float)Value;
					else if (Name == "alphaloggedout") AlphaLoggedOut = (float)Value;
					else {
						llOwnerSay("Invalid line in config file: " + Line);
						Errors++;
					}
				}
			}
		}
	}
	if (Errors > 0) {
		return (FALSE);
	}
	return(TRUE);
}
integer ReadObjectsCard() {
	ObjectsCount = 0;
	list Errors = [];
	Objects = [];
	if (llGetInventoryType(OBJECTS_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Can't find objects list notecard '" + OBJECTS_NOTECARD + "'");
		return FALSE;
	}
	list Lines = llParseStringKeepNulls(osGetNotecard(OBJECTS_NOTECARD), [ "\n" ], []);
	integer LineCount = llGetListLength(Lines);
	integer LinePtr;
	for (LinePtr = 0; LinePtr < LineCount; LinePtr++) {
		string Line = llStringTrim(llList2String(Lines, LinePtr), STRING_TRIM);
		if (Line += "") {
			list Parts = llParseStringKeepNulls(Line, [ "|" ], [ "" ]);
			integer PartsCount = llGetListLength(Parts);
			// format of line is: <name>|<position>[|<rotation>]
			if (PartsCount < 2 || PartsCount > 3) {
				Errors += "Invalid line:\n" + Line;
			}
			else {
				string Name = llList2String(Parts, 0);
				if (llGetInventoryType(Name) != INVENTORY_OBJECT) {
					Errors += "Can't find object '" + Name + "'";
				}
				vector Pos = (vector)llList2String(Parts, 1);
				rotation Rot = ZERO_ROTATION;
				if (PartsCount == 3) {
					vector RotV = (vector)llList2String(Parts, 2);
					Rot = EulerDeg2RotRad(RotV);
				}
				Objects += [ NULL_KEY, Name, Pos, Rot ];
				ObjectsCount++;
			}
		}
	}
	if (Errors != []) {
		llOwnerSay("Errors in '" + OBJECTS_NOTECARD + "':\n" + llDumpList2String(Errors, "\n"));
		return FALSE;
	}
	return TRUE;
}
RezObjects() {
	integer ObjectNum;
	for (ObjectNum = 0; ObjectNum < ObjectsCount; ObjectNum++) {
		integer Ptr = ObjectNum * OBJ_STRIDE;
		string Name = llList2String(Objects, Ptr + OBJ_NAME);
		llRezObject(Name, llGetPos() + <0.0, 0.0, 4.0>, ZERO_VECTOR, ZERO_ROTATION, 0);
	}
}
MoveObjects() {
	integer ObjectNum;
	for (ObjectNum = 0; ObjectNum < ObjectsCount; ObjectNum++) {
		integer Ptr = ObjectNum * OBJ_STRIDE;
		MoveObjectByPtr(Ptr);
	}
}
MoveObjectByPtr(integer Ptr) {
	key Uuid = llList2Key(Objects, Ptr + OBJ_UUID);
	string Name = llList2String(Objects, Ptr + OBJ_NAME);
	vector Pos = llList2Vector(Objects, Ptr + OBJ_POSITION);
	rotation Rot = llList2Rot(Objects, Ptr + OBJ_ROTATION);
	rotation MyRot = llGetRot();
	Pos = llGetPos() + (Pos * MyRot);
	Rot = Rot * MyRot;
	osSetPrimitiveParams(Uuid, [ PRIM_POSITION, Pos, PRIM_ROTATION, Rot ]);
}
RemoveObjects() {
	integer ObjectNum;
	for (ObjectNum = 0; ObjectNum < ObjectsCount; ObjectNum++) {
		integer Ptr = ObjectNum * OBJ_STRIDE;
		key Uuid = llList2Key(Objects, Ptr + OBJ_UUID);
		osDie(Uuid);
	}
}
rotation EulerDeg2RotRad(vector EulerD) {
	return llEuler2Rot(EulerD * DEG_TO_RAD);
}
// Handle login/logout events
Login(key Uuid) {
	if (AlphaLoggedIn != AlphaLoggedOut) { // only process if there's a difference
		float Alpha = AlphaLoggedIn;
		if (Uuid == NULL_KEY) {
			Alpha = AlphaLoggedOut;
		}
		if (llGetAlpha(0) != Alpha) { // don't change alpha unnecessarily (causes viewer updates)
			llSetAlpha(Alpha, ALL_SIDES);
		}
	}
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		if (!ReadConfig()) state Hang;
		if (!ReadObjectsCard()) state Hang;
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == LM_LOADING_COMPLETE) {	// Message from ML
			Login(Id); // Id is UUID of user
			state Normal;
		}
		else if (Number == LM_EXTERNAL_LOGIN) {
			Login(Id);
		}
		else if (Number == LM_EXTERNAL_LOGOUT) {
			Login(NULL_KEY);
		}
	}
}
state Normal {
	state_entry() {
		llMessageLinked(LINK_THIS, MP_DO_NOT_DELETE, "", NULL_KEY);	// tell moveable prim script not to delete us (we'll do that)
		llSetTimerEvent(2.0);
	}
	timer() {
		llSetTimerEvent(0.0);
		RezObjects();
	}
	object_rez(key Uuid) {
		// Put UUID into Objects table
		string Name = llKey2Name(Uuid);
		integer ObjectNum;
		for (ObjectNum = 0; ObjectNum < ObjectsCount; ObjectNum++) {
			integer Ptr = ObjectNum * OBJ_STRIDE;
			key OldUuid = llList2Key(Objects, Ptr + OBJ_UUID);
			string ThisName = llList2String(Objects, Ptr + OBJ_NAME);
			if (OldUuid == NULL_KEY && ThisName == Name) {
				Objects = llListReplaceList(Objects, [ Uuid ], Ptr + OBJ_UUID, Ptr + OBJ_UUID);
				MoveObjectByPtr(Ptr);
				return;
			}
		}
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == LM_EXTERNAL_LOGIN) {
			Login(Id);
		}
		else if (Number == LM_EXTERNAL_LOGOUT) {
			Login(NULL_KEY);
		}
		else if (Number== LM_DELETE_RECEIVED){
			RemoveObjects();
		}
		else if (Number == LM_MOVED_ROTATED) {
			MoveObjects();
		}
		else if (Number == MP_DELETE_OBJECT) {	// moveable prim script tells us it's time to die
			RemoveObjects();
			state Die;
		}
		else if (Number == LM_RESET) {
			RemoveObjects();
			llResetScript();
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			if (!ReadConfig()) state Hang;
			if (!ReadObjectsCard()) state Hang;
		}

	}
}
state Die {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llDie();
	}
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
	changed(integer Change)	{
		if (Change & CHANGED_INVENTORY) llResetScript();
	}
}
// Object creator v0.1