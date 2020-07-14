// Melacraft colorable block v1.0.1

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

key RootUuid = NULL_KEY;

integer DataRequested;
integer DataReceived;

integer HamburgerVisible;          // Is hamburger visible?

string Color;

list Colors() {
	return [
		"White", <1.0, 1.0, 1.0>,
		"Red", <1.0, 0.0, 0.0>,
		"Green", <0.0, 1.0, 0.0>,
		"Blue", <0.0, 0.0, 1.0>,
		"Yellow", <1.0, 1.0, 0.0>,
		"Cyan", <0.0, 1.0, 1.0>,
		"Magenta", <1.0, 0.0, 1.0>,
		"Orange", <1.0, 0.647, 0.0>,
		"Black", <0.0, 0.0, 0.0>,
		"Gray", <0.4, 0.4, 0.5>,
		"Off-white", <0.9, 0.9, 0.9>,
		"Gold", <1.0, 0.843, 0.0>,
		"Silver", <0.753, 0.753, 0.753>,
		"Purple", <0.502, 0.0, 0.502>,
		"Brown", <0.502, 0.251, 0.0>,
		"Khaki", <0.765, 0.690, 0.569>,
		"Cream", <1.0, 0.992, 0.816>,
		"Tan", <0.824, 0.706, 0.549>,
		"Olive", <0.502, 0.502, 0.0>,
		"Maroon", <0.502, 0.0, 0.0>,
		"Navy", <0.0, 0.0, 0.502>,
		"Aquamarine", <0.498, 1.0, 0.831>,
		"Turquoise", <0.0, 1.0, 0.937>,
		"Lime", <0.749, 1.0, 0.0>,
		"Teal", <0.0, 0.502, 0.502>,
		"Indigo", <0.435, 0.0, 1.0>,
		"Violet", <0.561, 0.0, 1.0>,
		"Fuchsia", <0.976, 0.518, 0.937>,
		"Ivory", <1.0, 1.0, 0.941>,
		"Plum", <0.557, 0.271, 0.522>
			];
}
list ColorNames() {
	list Return = [];
	list ColorList = Colors();
	integer ColorsLength = llGetListLength(ColorList);
	integer C;
	for (C = 0; C < ColorsLength; C += 2) {
		Return += llList2String(ColorList, C);
	}
	return Return;
}
SetColor() {
	list ColorList = Colors();
	integer Ptr = llListFindList(ColorList, [ Color ]);
	vector RGB = llList2Vector(ColorList, Ptr + 1);
	list Params = [
		PRIM_COLOR, ALL_SIDES, RGB, 1.0,
		PRIM_COLOR, SIDE_HAMBURGER, <1.0, 1.0, 1.0>, 1.0
		];
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
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
		Color = "White";
		SetColor();
		DataRequested = DataReceived = FALSE;
		SetHamburgerVisibility(TRUE);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_LOADING_COMPLETE) {
			ProcessLoadingComplete();
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			if (!HamburgerVisible) return;
			SendMenuCommand(MENU_RESET, []);
			SendMenuCommand(MENU_ADD, [	"!Main", "Select color" ] + ColorNames() + [ "CANCEL" ]);
			SendMenuCommand(MENU_START, [ Id ]);
		}
		else if (Number == HUD_API_LOGIN) {
			SetHamburgerVisibility(TRUE);
		}
		else if (Number == HUD_API_LOGOUT) {
			SetHamburgerVisibility(FALSE);
		}
		else if (Number == MENU_RESPONSE) {
			list Selected = llCSV2List(String);
			//string SelectedMenu = llList2String(Selected, 0);
			string SelectedOption = llList2String(Selected, 1);
			if (SelectedOption == "CANCEL") return;
			Color = SelectedOption;
			SetColor();
			MessageStandard(RootUuid, LM_EXTRA_DATA_SET, [ Color ]);
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
			list Elements = llParseStringKeepNulls(SaveData, [ "^" ], []);
			Color = llList2String(Elements, 0);
			SetColor();
		}
	}
	timer() {
		if (!DataReceived) {
			MessageStandard(RootUuid, LM_EXTRA_DATA_GET, [ SIDE_HAMBURGER ]);
		}
		else {
			llSetTimerEvent(0.0);
		}
	}
}
// Melacraft colorable block v1.0.1