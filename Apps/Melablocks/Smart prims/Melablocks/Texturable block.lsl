// Melacraft texturable block v1.0.1

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

// v1.0.1 - change to use osMessageObject for comms (type 1)

integer SIDE_HAMBURGER = 1;

integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_RESERVED_TOUCH_FACE = -44088510;		// Reserved Touch Face (RTF)

integer HUD_API_LOGIN = -47206000;
integer HUD_API_LOGOUT = -47206001;

integer MENU_RESET 		= -291044301;
integer MENU_ADD 	 	= -291044302;
integer MENU_SETVALUE 	= -291044303;
integer MENU_START 		= -291044304;
integer MENU_RESPONSE	= -291044305;
integer MENU_TEXTBOX	= -291044306;

key RootUuid = NULL_KEY;

integer DataRequested;
integer DataReceived;

integer HamburgerVisible;          // Is hamburger visible?

key Texture;

SetTexture() {
	integer NumberOfSides = llGetNumberOfSides();
	integer Side;
	for (Side = 0; Side < NumberOfSides; Side++) {
		if (Side != SIDE_HAMBURGER) llSetTexture(Texture, Side);
	}
}
// Deal with LM_LOADING_COMPLETE messages, either by linked message or dataserver
ProcessLoadingComplete() {
	if (!DataRequested) {
		RootUuid = llGetLinkKey(1);
		MessageStandard(RootUuid, LM_EXTRA_DATA_GET, [ SIDE_HAMBURGER ]);
		llSetTimerEvent(12.0 + llFrand(6.0));
		DataRequested = TRUE;
	}
}
// Set hamburger visibility
SetHamburgerVisibility(integer IsVisible) {
	HamburgerVisible = IsVisible;
	if (IsVisible) {
		llSetAlpha(1.0, SIDE_HAMBURGER);
	}
	else {
		llSetAlpha(0.0, SIDE_HAMBURGER);
	}
}
SendMenuCommand(integer Command, list Values) {
	string SendString = llDumpList2String(Values, "|");
	llMessageLinked(LINK_ROOT, Command, SendString, NULL_KEY);
}
// Uses standard messaging protocol
MessageStandard(key Uuid, integer Command, list Params) {
	MessageObject(Uuid, llDumpList2String([ Command ] + Params, "|"));
}
// Wrapper for osMessageObject() that checks to see if target exists
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
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Texture = TEXTURE_BLANK;
		SetTexture();
		DataRequested = DataReceived = FALSE;
		SetHamburgerVisibility(TRUE);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_LOADING_COMPLETE) {
			ProcessLoadingComplete();
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			if (!HamburgerVisible) return;
			SendMenuCommand(MENU_TEXTBOX,  [ Id, "Enter UUID of texture and click \"Submit\".\n\nYou can find the UUID by right-clicking the texture in your inventory and selecting \"Copy Asset UUID\".\n\nLeave blank to cancel." ]);
		}
		else if (Number == HUD_API_LOGIN) {
			SetHamburgerVisibility(TRUE);
		}
		else if (Number == HUD_API_LOGOUT) {
			SetHamburgerVisibility(FALSE);
		}
		else if (Number == MENU_RESPONSE) {
			if (String == "") return;
			Texture = (key)String;
			SetTexture();
			MessageStandard(RootUuid, LM_EXTRA_DATA_SET, [ Texture ]);
		}
	}
	dataserver(key Requested, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		string sCommand = llList2String(Parts, 0);
		integer Command = (integer)sCommand;
		list Params = llList2List(Parts, 1, -1);
		if (Command == LM_LOADING_COMPLETE) {
			ProcessLoadingComplete();
		}
		else if (Command == LM_EXTRA_DATA_SET) {
			llSetTimerEvent(0.0);
			string SaveData = llList2String(Params, 0);
			DataReceived = TRUE;	// we don't really need this because we can just stop the timer, but I'm leaving it in case we use the timer for something else later
			if (SaveData == "") return; // no data
			Texture = SaveData;
			SetTexture();
		}
	}	
	timer() {
		if (!DataReceived) {
			MessageStandard(RootUuid, LM_EXTRA_DATA_GET, [ Texture ]);
		}
		else {
			llSetTimerEvent(0.0);
		}
	}
}
// Melacraft texturable block v1.0.1