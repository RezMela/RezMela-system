// Street view extension server v0.2

// v0.2 - get lat/lon as well as pano ID

string PHP_URL = "http://rezmela.net/extint/v1/";
string PHP_GET_ID_SCRIPT = "GetUserId.php";
string PHP_GET_PANOS_SCRIPT = "GetPanos.php";

integer LM_EXTENSION_MENU = -71143301;
integer LM_EXTENSION_PANO = -71143302;

list Panos;
integer PA_PANOID = 0;
integer PA_LAT = 1;
integer PA_LON = 2;
integer PA_DESC = 3;
integer PA_STRIDE = 4;
integer PanosCount;	// number of rows, not elements

list MenuPanos = [];		// pointers to panos table

key AvId;
string AvName;
string Grid;
string UserId;

key IdRequestId;
key PanosRequestId;

integer MenuChannel;
integer MenuListener;
integer MENU_MAX = 9;	// how many can be displayed at once

string BTN_CLEARALL = "Clear all";
string BTN_BACK = "< Back";
string BTN_CLEAR = "Clear";
string BTN_CANCEL = "Cancel";

ShowMenu() {
	RemoveListener();
	if (!llGetListLength(Panos)) {
		Alert("No panoramas waiting");
		return;
	}
	string MenuText = "Panoramas: \n";
	PanosCount = llGetListLength(Panos) / PA_STRIDE;
	integer Start = PanosCount - MENU_MAX;
	if (Start < 0) Start = 0;
	integer LineNum = 0;
	list Buttons = [];
	MenuPanos = [];
	integer P;
	for (P = Start; P < PanosCount; P++) {
		MenuPanos += P;
		string VisLineNum = (string)(LineNum + 1);
		integer B = P * PA_STRIDE;	// pointer to panos table
		string Description = llList2String(Panos, B + PA_DESC);
		if (Description == "") Description = "[No description]";
		MenuText +=  VisLineNum + ": " + Description + "\n";
		Buttons += VisLineNum ;
		LineNum++ ;
	}
	// Pad to width of 3 buttons
	while(LineNum % 3) {
		Buttons += " ";
		LineNum++;
	}
	// Rearrange for silly LSL button order
	Buttons = llList2List(Buttons, 6, 8) + llList2List(Buttons, 3, 5) + llList2List(Buttons, 0, 2);
	MenuText += "\nSelect:";
	Buttons = [ BTN_BACK, " ", BTN_CLEARALL ] + Buttons;
	Dialog(MenuText, Buttons, MenuChannel);
}
Alert(string Text) {
	Dialog(Text, [ BTN_BACK ], MenuChannel);
}
Dialog(string Text, list Buttons, integer MenuChannel) {
	Text = "\nCHROME EXTENSION PANORAMAS\n\nYour user id is: " + UserId + "\n\n" + Text + "\n\n";
	MenuListener = llListen(MenuChannel, "", AvId, "");
	llDialog(AvId, Text, Buttons, MenuChannel);
}
RemoveListener() {
	if (MenuListener) {
		llListenRemove(MenuListener);
		MenuListener = 0;
	}
}
RequestPanos() {
	string PHPCall = PHP_URL + PHP_GET_PANOS_SCRIPT +
		"/?uid=" + UserId
			;
	PanosRequestId = llHTTPRequest(PHPCall, [], "");
}
ProcessPanos(list PanoLines) {
	integer L = llGetListLength(PanoLines);
	integer P;
	for (P = 0; P < L; P++) {
		string Line = llStringTrim(llList2String(PanoLines, P), STRING_TRIM);
		if (Line != "" && Line != "EOF") {
			//llOwnerSay("Pano: " + llList2String(PanoLines, P));
			list Parts = llParseStringKeepNulls(Line, [ "|" ], []);
			string PanoId = llList2String(Parts, 1);
			float Lat = (float)llList2String(Parts, 2);
			float Lon = (float)llList2String(Parts, 3);
			string Description = llList2String(Parts, 4);
			Panos  += [
				PanoId,
				Lat,
				Lon,
				Description
					];
			PanosCount++;
		}
	}
}
RequestUserId() {
	string PHPCall = PHP_URL + PHP_GET_ID_SCRIPT +
		"/?grid=" + llEscapeURL(Grid) +
		"&uname=" + llEscapeURL(AvName);
	;
	IdRequestId = llHTTPRequest(PHPCall, [], "");
}
default {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		Grid = "RG";	// if we go multi-grid, we'll need this to be configurable
		state Idle;
	}
}
state Idle {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		RemoveListener();
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_EXTENSION_MENU) {
			if (String == "ext") {
				AvId = Id;
				state GetUserId;
			}
		}
	}
}
state GetUserId {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		MenuChannel = -10000 - (integer)llFrand(1000000);
		AvName = llKey2Name(AvId);
		RequestUserId();
		llSetTimerEvent(30.0);
	}
	http_response(key Id, integer Status, list Metadata, string Body) {
		//	llOwnerSay("Response: " + (string)Status + "/" + llList2CSV(Metadata) + ": " + Body);
		if (Id == IdRequestId) {
			if (Status == 200) {
				llSetTimerEvent(0.0);
				UserId = llStringTrim(Body, STRING_TRIM);
				state GetPanos;
			}
			else {	// Error return status - try again
				llSetTimerEvent(30.0);
				llSleep(1.0);
				RequestUserId();
			}
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		llOwnerSay("Web server access timed out");
		state Normal;
	}
}
state GetPanos {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		RequestPanos();
	}
	http_response(key Id, integer Status, list Metadata, string Body) {
		//	llOwnerSay("Response: " + (string)Status + "/" + llList2CSV(Metadata) + ": " + Body);
		if (Id == PanosRequestId) {
			if (Status == 200) {
				if (Body != "") {
					list PanoLines = llParseString2List(Body, [ "\n" ], []);
					ProcessPanos(PanoLines);
				}
				state Menu;
			}
			else {
				// Ignore non-zero returns. They seem to happen sometimes
				//llOwnerSay("Panos request returned status " + (string)Status + ":\n" + Body);
			}
		}
	}
}
state Menu {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		ShowMenu();
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_EXTENSION_MENU) {
			if (String == "ext") {		// shouldn't happen in this state, but we'll handle it anyway
				state GetUserId;
			}
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (MenuChannel && Channel == MenuChannel && Id == AvId) {
			if (Message == BTN_BACK) {
				llMessageLinked(LINK_THIS, LM_EXTENSION_MENU, "main", Id);
				state Idle;
			}
			else if (Message == BTN_CLEARALL) {
				llDialog(AvId,
					"\nWarning: This will remove all panoramas that are waiting to be processed.\n\nClick '" + BTN_CLEAR + "' to continue",
					[ BTN_CLEAR, BTN_CANCEL ], MenuChannel);
				return;
			}
			else if (Message == BTN_CLEAR) {	// clear all, after warning
				Panos = [];
				PanosCount = 0;
				Alert("Panorama(s) cleared");
				state Idle;
			}
			else if ((integer)Message) {	// if it's a numeric response
				integer Which = (integer)Message - 1;	// Their input, 0-starting
				integer Ptr = Which * PA_STRIDE;	// pointer to panos table
				string PanoId = llList2String(Panos, Ptr + PA_PANOID);
				float Lat = llList2Float(Panos, Ptr + PA_LAT);
				float Lon = llList2Float(Panos, Ptr + PA_LON);
				Panos = llDeleteSubList(Panos, Ptr, Ptr + PA_STRIDE - 1);
				// We could just get the data straight from the list, but this is more explicit
				string Data = llDumpList2String([ PanoId, Lat, Lon ], "|");
				llMessageLinked(LINK_THIS, LM_EXTENSION_PANO, Data, Id);
				state Idle;
			}
			ShowMenu();
		}
	}
}
// Street view extension server v0.2