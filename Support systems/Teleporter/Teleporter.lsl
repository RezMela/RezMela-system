// Teleporter v0.1

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

integer FACE_TELEPORT = 0;
integer FACE_CONFIGURE = 3;
list FACES_HANDLE = [ 1, 2, 4 ];

// Link message number, sent by ML main script
integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_RESERVED_TOUCH_FACE = -44088510;

integer HUD_API_LOGIN = -47206000;
integer HUD_API_LOGOUT = -47206001;

list SpecialFaces;	// faces which are invisible when signed out
integer SpecialFacesCount;
integer SpecialFacesVisible;

string MENU_HEADING = "\nTELEPORTER CONFIGURATION\n\n";

string TpRegion;
vector TpPosition;

integer InputMode;
integer INPUT_MODE_NONE = 0;
integer INPUT_MODE_REGION = 1;
integer INPUT_MODE_POSITION = 2;
integer INPUT_MODE_CONFIRM = 3;
string InputRegion;
vector InputPosition;

integer MenuChannel;
key AvId;
integer MenuListener;
string MenuError;

integer DataRequested;
integer DataReceived;

Teleport(key AvId) {
	if (TpPosition == ZERO_VECTOR) {
		llRegionSayTo(AvId, 0, "Sorry, this teleporter is not configured.");
		return;
	}
	if (TpRegion == "") {	// TP in same region
		TpRegion = llGetRegionName();
	}
	osTeleportAgent(AvId, TpRegion, TpPosition, ZERO_VECTOR);
}
ShowMenu() {
	if (MenuListener > 0) llListenRemove(MenuListener);
	MenuListener = llListen(MenuChannel, "", AvId, "");
	if (InputMode == INPUT_MODE_REGION) {
		TextBox("Enter name of destination region, or leave blank to use the current region.");
	}
	else if (InputMode == INPUT_MODE_POSITION) {
		TextBox ("Enter coordinates, or leave blank to cancel.\n\nCoordinates are the X, Y and Z values separated by commas.");
	}
	else if (InputMode == INPUT_MODE_CONFIRM) {
		string SPos =
			(string)llFloor(InputPosition.x) + ", " +
			(string)llFloor(InputPosition.y) + ", " +
			(string)llFloor(InputPosition.z);
		string Message = MENU_HEADING;
		Message += "Set destination to " + SPos;
		if (InputRegion != "") Message += " in region '" + InputRegion + "'";
		Message += "?\n\n";
		llDialog(AvId, Message, [ "OK", "Cancel", "Retry" ], MenuChannel);
	}
}
EndMenu() {
	if (MenuListener > 0) {
		llListenRemove(MenuListener);
		MenuListener = 0;
	}
	InputMode = INPUT_MODE_NONE;
}
MenuCancelled() {
	EndMenu();
	llDialog(AvId, MENU_HEADING + "Configuration cancelled\n", [ "OK" ], -934911412);
}
TextBox(string Message) {
	string BoxMessage = MENU_HEADING;
	if (MenuError != "") BoxMessage += "ERROR: " + MenuError + "\n\n";
	BoxMessage += Message + "\n";
	llTextBox(AvId, BoxMessage, MenuChannel);
	MenuError = "";
}
SetVisibilty(integer IsVisible) {
	SpecialFacesVisible = IsVisible;
	float Alpha = 0.0;
	if (SpecialFacesVisible) Alpha = 1.0;
	integer FacePtr;
	for (FacePtr = 0; FacePtr < SpecialFacesCount; FacePtr++) {
		integer Face = llList2Integer(SpecialFaces, FacePtr);
		// We can't do it all in a single SetPrimParams because we
		// don't know the colours.
		llSetAlpha(Alpha, Face);
	}
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		SpecialFaces = FACES_HANDLE + FACE_CONFIGURE;
		SpecialFacesCount = llGetListLength(SpecialFaces);
		SetVisibilty(TRUE);		
		TpRegion = "";
		TpPosition = ZERO_VECTOR;
		MenuChannel = -10000 - (integer)llFrand(1000000);
		MenuListener = 0;
		MenuError = "";
	}
	link_message(integer Sender, integer Number, string String, key Id)    {
		if (Number == LM_LOADING_COMPLETE && !DataRequested) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, llList2CSV([ FACE_CONFIGURE, FACE_TELEPORT ]), NULL_KEY);
			llSetTimerEvent(12.0 + llFrand(6.0));
			AvId = Id;
			DataRequested = TRUE;
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			// The ML is telling us that someone clicked our reserved face. The string portion of the message contains a pipe-delimited
			// list of the following data: face, position, normal, binormal, ST, UV
			list TouchData = llParseStringKeepNulls(String, [ "|" ], []);    // Parse the data into a list of the four different parts
			integer TouchFace = (integer)llList2String(TouchData, 0);
			if (TouchFace == FACE_TELEPORT) {
				Teleport(Id);
			}
			else if (TouchFace == FACE_CONFIGURE && SpecialFacesVisible) {
				InputRegion = "";
				InputPosition = ZERO_VECTOR;
				InputMode = INPUT_MODE_REGION;
				ShowMenu();
			}
		}
		else if (Number == LM_EXTRA_DATA_GET) {
			AvId = Id;
			// We can stop the timer because we have our data
			llSetTimerEvent(0.0);
			DataReceived = TRUE;
			if (String != "") {
				list Elements = llParseStringKeepNulls(String, [ "^" ], []);
				TpRegion = llList2String(Elements, 0);
				TpPosition = (vector)llList2String(Elements, 1);
			}
		}
		else if (Number == HUD_API_LOGIN) {
			AvId = Id;
			SetVisibilty(TRUE);
		}
		else if (Number == HUD_API_LOGOUT) {
			AvId = Id;
			SetVisibilty(FALSE);
		}
	}
	timer() {
		if (!DataReceived) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, llList2CSV([ FACE_CONFIGURE, FACE_TELEPORT ]), NULL_KEY);
		}
	}
	listen(integer Channel, string Name, key Id, string Text) {
		if (Id == AvId && Channel == MenuChannel) {
			if (InputMode == INPUT_MODE_REGION) {
				InputRegion = Text;
				InputMode = INPUT_MODE_POSITION;
				ShowMenu();
			}
			else if (InputMode == INPUT_MODE_POSITION) {
				if (Text == "") {
					MenuCancelled();
					return;
				}
				list Coords = llCSV2List(Text);
				if (llGetListLength(Coords) != 3) {
					MenuError = "Coordinates must have three numbers";
					ShowMenu();	// retry
					return;
				}
				vector Vec = <llList2Float(Coords, 0), llList2Float(Coords, 1), llList2Float(Coords, 2)>;
				if (Vec.x == 0.0 || Vec.y == 0.0 || Vec.z == 0.0) {
					MenuError = "Zero not valid in coordinates";
					ShowMenu();	// retry
					return;
				}
				vector RegionSize = osGetRegionSize();
				if (Vec.x >= RegionSize.x || Vec.y >= RegionSize.y || Vec.z > 4000.0) {
					MenuError = "Coordinate(s) out of range";
					ShowMenu();	// retry
					return;
				}
				InputPosition = Vec;
				InputMode = INPUT_MODE_CONFIRM;
				ShowMenu();
			}
			else if (InputMode == INPUT_MODE_CONFIRM) {
				if (Text == "OK") {
					// Save new configuation
					TpRegion = InputRegion;
					TpPosition = InputPosition;
					string Data = llDumpList2String([ TpRegion, TpPosition ], "^");
					llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_SET, Data, NULL_KEY);
					EndMenu();
				}
				else if (Text == "Cancel") {
					MenuCancelled();
				}
				else if (Text == "Retry") {
					InputRegion = "";
					InputPosition = ZERO_VECTOR;
					InputMode = INPUT_MODE_REGION;
					ShowMenu();
				}
			}
		}
	}
}
// Teleporter v0.1