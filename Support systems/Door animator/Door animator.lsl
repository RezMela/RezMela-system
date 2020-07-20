// Door animator v.0.5

// v0.5 - remote control
// v0.4 - added menu suppression with ALLOW_MENUS (was getting triggered accidentally)

integer ALLOW_MENUS = FALSE; // change to TRUE to allow positioning menu on long click


string CONFIG_NOTECARD = "Door config";

integer REMOTE_PIN = 1978123;	// just in case we need it later

integer IsOpen = FALSE;

integer LM_DOOR_OPEN = -66353000;
integer LM_DOOR_CLOSE = -66353001;

vector ClosedPos;
rotation ClosedRot;
vector OpenPos;
rotation OpenRot;

key OwnerID;
key AvId;
integer MenuChannel;
integer MenuListen;
string Sound;

string DoorType;

OpenClose(integer Open) {
	IsOpen = Open;
	list Params = [];
	if (Open) {
		Params = [ PRIM_POS_LOCAL, OpenPos, PRIM_ROT_LOCAL, OpenRot ];
	}
	else {
		Params = [ PRIM_POS_LOCAL, ClosedPos, PRIM_ROT_LOCAL, ClosedRot ];
	}
	llSetPrimitiveParams(Params);
	if (Sound != "") llTriggerSound(Sound, 1.0);
}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
ReadConfig() {
	// Set config defaults
	DoorType = "";
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
					if (Name == "doortype")	DoorType = llToLower(StripQuotes(Value, Line));
				}
			}
		}
	}
}
// Takes a string in double quotes, and strips out the quotes. Validates the format.
// <Text> is the string with quotes; <Line> is the entire line for error reporting
string StripQuotes(string Text, string Line) {
	if (Text == "") {	// allow empty string for null value
		return("");
	}
	if (llGetSubString(Text, 0, 0) == "\"" && llGetSubString(Text, -1, -1) == "\"") { 	// if surrounded by quotes
		return(llGetSubString(Text, 1, -2));	// strip quotes
	}
	else {
		llOwnerSay("Invalid string literal (missing \"\"?): " + Line);
		return("");
	}
}
string CompactFloat(float Float) {
	string Str = (string)Float;
	integer Ptr = llSubStringIndex(Str, ".");
	Str = llGetSubString(Str, 0, Ptr + 3);
	return Str;
}
string CompactVector(vector V) {
	return "<" + CompactFloat(V.x) + "," + CompactFloat(V.y) + "," + CompactFloat(V.z) + ">";
}
string CompactRotation(rotation R) {
	return "<" + CompactFloat(R.x) + "," + CompactFloat(R.y) + "," + CompactFloat(R.z) + "," + CompactFloat(R.s) + ">";
}

default {
	state_entry() {
		MenuChannel = -10000 - (integer)llFrand(10000000.0);
		llSetRemoteScriptAccessPin(REMOTE_PIN);
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
		if (llGetNumberOfPrims() == 1) state Hang;	// Unlinked
		if (llGetLinkNumber() == 1) state Hang;		// In the root prim
		ReadConfig();
		string Desc = llGetObjectDesc();
		if (llGetSubString(Desc, 0, 1) != "@D") state InitSetup;	// it's not in the correct format
		list Parts = llParseStringKeepNulls(llGetSubString(Desc, 2, -1), [ "/" ], []);
		if (llGetListLength(Parts) != 4) state InitSetup;		// not the correct layout
		ClosedPos = (vector)llList2String(Parts, 0);
		ClosedRot = (rotation)llList2String(Parts, 1);
		OpenPos = (vector)llList2String(Parts, 2);
		OpenRot = (rotation)llList2String(Parts, 3);
		state Normal;
	}
}
state Normal  {
	on_rez(integer Start) { state Bootup; }
	state_entry() {
		OpenClose(FALSE);
	}
	touch_start(integer Total) {
		AvId = llDetectedKey(0);
		if (AvId == OwnerID && ALLOW_MENUS) {
			llSetTimerEvent(0.5);
		}
		else {
			OpenClose(!IsOpen);
		}
	}
	touch_end(integer Total) {
		if (AvId == OwnerID && ALLOW_MENUS) {
			OpenClose(!IsOpen);
			AvId = NULL_KEY;
		}
	}
	timer()
	{
		if (AvId == OwnerID) {
			llSetTimerEvent(0.0);
			state Setup;
		}
	}
	link_message(integer Sender, integer Number, string Str, key Id) {
		if (Number == LM_DOOR_OPEN) {
			if (Str == "" || Str == DoorType)
				OpenClose(TRUE);
		}
		else if (Number == LM_DOOR_CLOSE) {
			if (Str == "" || Str == DoorType)
				OpenClose(FALSE);
		}
	}
	changed(integer Change)	{
		if (Change & CHANGED_LINK && llGetNumberOfPrims() == 1) state Bootup;	// reboot if unlinked
		if (Change & CHANGED_INVENTORY) state Bootup;
	}
}
// Init setup - first time setup, creating defaults
state InitSetup {
	on_rez(integer Start) { state Bootup; }
	state_entry()
	{
		ClosedPos = llGetLocalPos();
		ClosedRot = llGetLocalRot();
		OpenPos = ClosedPos;
		OpenRot = ClosedRot;
		state Setup;
	}
}
state Setup {
	on_rez(integer Start) { state Bootup; }
	state_entry() {
		string Text = "\n\nSET OPEN/CLOSE POS/ROT";
		Text += "\n\nEdit door to set appropriate rot/pos and select:\n\n";
		list Buttons = [ "Set OPEN", "Set CLOSED" ];
		if (OpenPos != ClosedPos || OpenRot != ClosedRot) {		// if the positions have been set
			Buttons = ["Test OPEN", "Test CLOSED", "Finish" ] + Buttons;
		}
		MenuListen = llListen(MenuChannel, "", OwnerID, "");
		llDialog(OwnerID, Text, Buttons, MenuChannel);
	}
	listen(integer Channel, string Name, key ID, string Message) {
		if (Channel == MenuChannel && ID == OwnerID) {
			if (Message == "Set OPEN") {
				OpenPos = llGetLocalPos();
				OpenRot = llGetLocalRot();
			}
			else if (Message == "Set CLOSED") {
				ClosedPos = llGetLocalPos();
				ClosedRot = llGetLocalRot();
			}
			else if (Message == "Test OPEN") {
				OpenClose(TRUE);
			}
			else if (Message == "Test CLOSED") {
				OpenClose(FALSE);
			}
			else if (Message == "Finish") {
				string Desc = "@D" +
					CompactVector(ClosedPos) + "/" +
					CompactRotation(ClosedRot) + "/" +
					CompactVector(OpenPos) + "/" +
					CompactRotation(OpenRot)
						;
				llSetObjectDesc(Desc);
				llDialog(OwnerID, "\n\nPos/rots recorded.\n\n", [ "OK" ], -99999);  // dummy channel
				state Bootup;
			}
			state ReloadSetup;
		}
	}
	touch_start(integer Total) {
		if (llDetectedKey(0) == OwnerID) state ReloadSetup;
	}
	changed(integer Change)	{
		if (Change & CHANGED_LINK) state Bootup;
	}
}
state ReloadSetup {
	state_entry() {
		state Setup;
	}
}
state Hang {
	on_rez(integer Start) { state Bootup; }
	changed(integer Change) {
		if (Change & CHANGED_LINK) state Bootup;
		if (Change & CHANGED_INVENTORY) state Bootup;
	}
}
// Door animator v0.5