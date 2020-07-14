// Melacraft light block v1.0.1


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
float Intensity;
float Radius;
float FallOff;

ProcessResponse(string Menu, string Response) {
	if (Menu == "Color") {
		Color = Response;
	}
	else if (Menu == "Brightness") {
		integer Percent = (integer)Response;
		Intensity = (float)Percent / 100.0;
	}
	else if (Menu == "Radius") {
		integer Metres = (integer)Response;
		Radius = (float)Metres;
	}
	else if (Menu == "Fall-off") {
		integer Percent = (integer)Response;
		FallOff = (float)Percent / 50.0; // 0.01 - 2.0
	}
	string Data = llDumpList2String([ Color, Intensity, Radius, FallOff ], "^");
	MessageStandard(RootUuid, LM_EXTRA_DATA_SET, [ Data ]);	
	SetLight();
}
list Colors() {
	return [
		"White", <1.0, 1.0, 1.0>,
		"Warm white", <1.0, 1.0, 0.8>,
		"Cool white", <0.8, 1.0, 0.8>,
		"Red", <1.0, 0.0, 0.0>,
		"Green", <0.0, 1.0, 0.0>,
		"Blue", <0.0, 0.0, 1.0>,
		"Yellow", <1.0, 1.0, 0.0>,
		"Cyan", <0.0, 1.0, 1.0>,
		"Magenta", <1.0, 0.0, 1.0>,
		"Purple", <0.502, 0.0, 0.502>
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
SetLight() {
	list ColorList = Colors();
	integer Ptr = llListFindList(ColorList, [ Color ]);
	vector RGB = llList2Vector(ColorList, Ptr + 1);
	llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_POINT_LIGHT, TRUE, RGB, Intensity, Radius, FallOff ]);
}
NoLight() {
	llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_POINT_LIGHT, FALSE, ZERO_VECTOR, 0.1, 0.1, 0.1 ]);
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
		NoLight();		
		Intensity = 0.5;
		Radius = 5.0;
		FallOff = 0.01;
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
			SendMenuCommand(MENU_ADD, [ "!Light", "You can change the appearance of the light using the options below", "*Color", "*Brightness", "*Radius", "*Fall-off", "DONE" ]);
			SendMenuCommand(MENU_ADD, [ "!Color", "Select color" ] + ColorNames() + [ "*" ]);
			SendMenuCommand(MENU_ADD, [ "!Brightness", "Select the brightness (intensity) of the light", "5%", "10%", "25%", "50%", "75%", "100%", "*" ]);
			SendMenuCommand(MENU_ADD, [ "!Radius", "Select the radius (distance) of the light in metres", "1m", "2m", "5m", "8m", "10m", "15m", "20m", "*" ]);
			SendMenuCommand(MENU_ADD, [ "!Fall-off", "Select the fall-off (fading amount) of the light", "1%", "10%", "25%", "50%", "75%", "100%", "*" ]);
			SendMenuCommand(MENU_SETVALUE, [ "persist=true", "close=Light,DONE" ]);
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
			string Menu = llList2String(Selected, 0);
			string Response = llList2String(Selected, 1);
			if (Response == "DONE") return;
			ProcessResponse(Menu, Response);
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
			Intensity = (float)llList2String(Elements, 1);
			Radius = (float)llList2String(Elements, 2);
			FallOff = (float)llList2String(Elements, 3);
			SetLight();
		}
	}	
	timer() {
		if (!DataReceived) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, (string)SIDE_HAMBURGER, NULL_KEY);
		}
		else {
			llSetTimerEvent(0.0);
		}
	}
}
// Melacraft light block v1.0.1