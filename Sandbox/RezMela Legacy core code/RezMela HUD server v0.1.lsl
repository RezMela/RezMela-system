// RezMela HUD server v0.1

// This goes in the control board's root prim

string HUD_MIN_VERSION = "0.3";

string HUD_OBJECT = "ML HUD";
string OBJECTS_LIST = "HUD objects";
integer HUD_ATTACH_POINT = ATTACH_HUD_TOP_RIGHT;

integer HUD_CHAT_GENERAL = -95471602;	// chat channel for general talk in region
integer HUD_CHAT_SPECIFIC = -95471603;	// chat channel for comms from HUD to main object

integer LM_PRIM_SELECTED = -405500;        // A prim has been selected
integer LM_PRIM_DESELECTED = -405501;    // A prim has been deselected
//integer LM_EXECUTE_COMMAND = -405502;    // Execute command (from other script)
integer LM_HUD_COMMAND = -405509;    // Execute command (from other script)
integer LM_OUTSOURCE_COMMAND = -405510;
integer LM_SEAT_USER = -405520;
integer LM_EXTERNAL_LOGIN = -405521;
integer LM_EXTERNAL_LOGOUT = -405522;

//list Users;
//integer U_AV_ID = 0;
//integer U_SEAT = 1;
//integer U_HUD_ID = 2;
//integer U_STRIDE = 3;

key AvId;
key HudId;
key MyUuid;
integer MySeatNum;
integer LoginPrimLinkNum;

integer AttachAttempted;

HandleHudMessage(string Data) {
	if (Data == "o") {
		SendObjectsList(HudId);	// Send list of available objects to HUD
	}
	else { // all other messages are presumably button commands
		llMessageLinked(LINK_THIS, LM_HUD_COMMAND, Data, AvId);
	}
}
integer UserNotHere() {
	return (llGetAgentSize(AvId) == ZERO_VECTOR);	// this is a legitimate way of checking!
}
SendObjectsList(key HudId) {
	string S = osGetNotecard(OBJECTS_LIST);
	MessageObject(HudId, "o" + S);
}
DisconnectUser() {
	llMessageLinked(LINK_ROOT, LM_EXTERNAL_LOGOUT, "", AvId);
	// deactivate their HUD
	if (HudId != NULL_KEY)
		MessageObject(HudId, "d");	// "d" for "deactivate"
}
SetSelect(key AvId, integer IsSelected) {
	if (IsSelected)
		MessageObject(HudId, "sy");	// selected yes
	else
		MessageObject(HudId, "sn");	// selected no
}
ShowName() {
	string Name = "";
	if (AvId != NULL_KEY) Name = llKey2Name(AvId);
	if (LoginPrimLinkNum > -1) {
		llSetLinkPrimitiveParamsFast(LoginPrimLinkNum, [ PRIM_TEXT, Name, <0.6, 0.6, 1.0>, 1.0 ]);
	}
}
// From http://wiki.secondlife.com/wiki/String_Compare
// Is equivalent to (s1 > s2)
integer StringCompare(string s1, string s2) {
	if (s1 == s2)
		return FALSE;
	if (s1 == llList2String(llListSort([s1, s2], 1, TRUE), 0))
		return FALSE;
	return TRUE;
}
// Wrapper for osMessageObject() that checks to see if destination exists
MessageObject(key Uuid, string Text) {
	if (ObjectExists(Uuid)) {
		osMessageObject(Uuid, Text);
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
default {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		MyUuid = llGetKey();
		LoginPrimLinkNum = -1;
		state Idle;
	}
}
state Idle {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		AvId = HudId = NULL_KEY;
		ShowName();
	}
	link_message(integer Sender, integer Num, string String, key Id) {
		if (Num == LM_OUTSOURCE_COMMAND) {
			list Parts = llCSV2List(String);
			string Command = llList2String(Parts, 0);
			if (Command == "hud") {
				// They've clicked on the HUD login prim
				//				integer SeatNum = (integer)llList2String(Parts, 1);
				//				string Argument = llList2String(Parts, 2);
				//				integer IsAdmin = (integer)llList2String(Parts, 3);
				LoginPrimLinkNum = (integer)llList2String(Parts, 4);
				MySeatNum = (integer)llGetObjectDesc();
				llMessageLinked(LINK_ROOT, LM_EXTERNAL_LOGIN, (string)MySeatNum, Id);		// 0 is in place of seat number
				llSetTimerEvent(10.0);
			}
		}
		else if (Num == LM_SEAT_USER) {
			if (String != "") {	// not a logging out event, must be logging in
				AvId = Id;
				state ActivateHud;
			}
		}
	}
	timer() {
		llOwnerSay("HUD Login timed out");
		llSetTimerEvent(0.0);
	}
}
state ActivateHud {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		llRegionSay(HUD_CHAT_GENERAL, "D" + (string)AvId);	// we tell all other MLs to disconnect this user
		AttachAttempted = FALSE;
		llListen(HUD_CHAT_GENERAL, "", NULL_KEY, "");
		llSetTimerEvent(3.0);
	}
	listen(integer Channel, string Name, key Id, string String) {
		if (Channel == HUD_CHAT_GENERAL) {
			// Quick and dirty check to (relatively) cheaply filter out irrelevant messages
			if (llGetSubString(String, 2, 37) != (string)AvId) return;
			string MessageType = llGetSubString(String, 0, 0);
			if (MessageType == "H") {
				key ThisAvId = (key)llGetSubString(String, 2, 37);
				string ThisHudVersion = llGetSubString(String, 39, -1);
				key ThisHudId = Id;
				if (ThisAvId == AvId) {
					// if it's from the user we're trying to contact
					// This means they have the HUD attached but deactivated
					// Check the HUD's version
					if (StringCompare(HUD_MIN_VERSION, ThisHudVersion)) {	// if minimum version is greater than this HUD's version
						if (!AttachAttempted)	// If we haven't attached the HUD this time
							return;		// Allow the timer to kick in, hence attaching a new HUD to upgrade them
						llOwnerSay("Attached HUD, but it's an old version!");
						state Idle;
					}
					llSetTimerEvent(0.0);
					HudId = ThisHudId;
					MessageObject(HudId, "a");	// "a" for "activate"
					state Normal;
				}
			}
		}
	}
	timer() {
		// We waited for a HUD heartbeat that didn't appear in the timeframe,
		// meaning the user doesn't have a HUD attached
		// So we give out the HUD
		// Is the user in the region?
		if (UserNotHere()) state Idle;
		// They exist and are in the region
		if (!AttachAttempted) {	// if we're not already trying to attach something
			if (llGetInventoryType(HUD_OBJECT) == INVENTORY_OBJECT) {
				osForceAttachToOtherAvatarFromInventory((string)AvId, HUD_OBJECT, HUD_ATTACH_POINT);
			}
			else {
				llOwnerSay("ERROR: HUD object '" + HUD_OBJECT + "' missing from ML inventory");
				state Idle;
			}
		}
		AttachAttempted++;
		if (AttachAttempted > 5) {
			llOwnerSay("Unable to attach HUD to user " + llKey2Name(AvId));
			state Idle;
		}
	}
}
state Normal {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		ShowName();
		llListen(HUD_CHAT_GENERAL, "", NULL_KEY, "");
		llListen(HUD_CHAT_SPECIFIC, "", HudId, "");
		llSetTimerEvent(5.0);
	}
	link_message(integer Sender, integer Num, string String, key Id) {
		if (Num == LM_OUTSOURCE_COMMAND) {
			list Parts = llCSV2List(String);
			string Command = llList2String(Parts, 0);
			if (Command == "hud") {
				//				integer SeatNum = (integer)llList2String(Parts, 1);
				//				string Argument = llList2String(Parts, 2);
				//				integer IsAdmin = (integer)llList2String(Parts, 3);
				LoginPrimLinkNum = (integer)llList2String(Parts, 4);
				key ThisAvId = Id;
				if (ThisAvId == AvId) { // current user has clicked on hud button, so is logging out
					state Logout;
				}
				// so someone else has clicked on hud button, and we need to log out current user and log them in
				DisconnectUser();
				llOwnerSay("logged out " + llKey2Name(AvId));///%%%
				// Switch to new user
				AvId = ThisAvId;
				llOwnerSay("login for " + llKey2Name(AvId));///%%%
				HudId = NULL_KEY;
				llMessageLinked(LINK_ROOT, LM_EXTERNAL_LOGIN, (string)MySeatNum, AvId);
				state ActivateHud;
			}
		}
		else if (Num == LM_SEAT_USER) {
			llOwnerSay("seat_user: " + String + "/" + (string)Id);	///%%%
			key ThisAvId = Id;
			if (String == "") {	// Empty string means they're logging out
				if (ThisAvId == AvId) {
					state Logout;
				}
			}
			else {	// String contains seat number, so someone else is logging in
				// log out current user
				DisconnectUser();
				// sign in new user
				llOwnerSay("disconnected " + llKey2Name(AvId));///%%%
				AvId = Id;
				state ActivateHud;
			}
		}
		// Prim selection/deselection. We handle messages from the main ML script telling us when the user selects/deselects prims.
		else if (Num == LM_PRIM_SELECTED) {
			SetSelect(Id, TRUE);
		}
		else if (Num == LM_PRIM_DESELECTED) {
			SetSelect(Id, FALSE);
		}
	}
	listen(integer Channel, string Name, key Id, string String) {
		if (Id == MyUuid) return;	// we never listen to our own messages
		if (Channel == HUD_CHAT_GENERAL) {
			// The only message here that is relevant to us in this state is a disconnect for our user from another ML in the region
			// (meaning they were using us, but have moved on to that other ML)
			if (String == "D" + (string)AvId) {
				state Logout;
			}
		}
		else if (Channel == HUD_CHAT_SPECIFIC) { //if it's a message directly from the HUD
			HandleHudMessage(String);
		}
	}
	// while we're not using osMessageObject, this isn't necessary
	//	dataserver(key Id, string Data) {
	//		if (Id == HudId) HandleHudMessage(Data);
	//	}
	timer() {
		if (UserNotHere()) {
			state Logout;
		}
	}
}
state Logout {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		DisconnectUser();
	}
	link_message(integer Sender, integer Num, string String, key Id) {
		if (Num == LM_SEAT_USER) state Idle;
	}
}
// RezMela HUD server v0.1