// Panorama location v1.0.0

// v1.0.0 - better integrated touch handling, name changed from "Street view location"
// v0.7 - wasn't ignoring empty data
// v0.6 - put RTF data in "extra data get"
// v0.5 - no longer reset on relink
// v0.4 - reserve faces
// v0.3 - new method of storing data

string CONFIG_NOTECARD = "Location config";

// Link messaage number, sent by ML main script
integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_PRIM_SELECTED = -405500;        // A prim has been selected
integer LM_PRIM_DESELECTED = -405501;    // A prim has been deselected
integer LM_RESERVED_TOUCH_FACE = -44088510;		// Reserved Touch Face (RTF)
integer LM_TOUCH_NORMAL    = -66168300;

integer DataRequested;
integer DataReceived;
string RtfString;

float Lat;
float Lon;
integer LatLonSet = FALSE;

integer FaceSet;
integer FaceSelect;
integer Selected = FALSE;

integer TextboxChannel;
integer TextboxListener;
key AvId;

// Sent to street view script to set location
integer LM_STREETVIEW_COORDS = -71143300;


// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	integer IsOK = TRUE;
	FaceSet = -1;
	FaceSelect = -1;
	// Set config defaults
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
					if (Name == "faceset")	FaceSet = (integer)Value;
					else if (Name == "faceselect")	FaceSelect = (integer)Value;
					else {
						llOwnerSay("Invalid keyword in config file: '" + OName + "'");
						IsOK = FALSE;
					}
				}
				else {
					llOwnerSay("Invalid line in config file: " + Line);
					IsOK = FALSE;
				}
			}
		}
	}
	return IsOK;
}
// Shows a special menu with just a message and an OK button that returns to main menu.
Alert(key Id, string Message) {
	llDialog(Id, "\n" + Message, [ "OK" ], -1928932);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Lat = Lon = 0.0;
		ReadConfig();
		RtfString = llList2CSV([ FaceSet, FaceSelect ]);
		DataRequested = DataReceived = FALSE;
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_LOADING_COMPLETE && !DataRequested) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, RtfString, NULL_KEY);
			llSetTimerEvent(12.0 + llFrand(6.0));
			DataRequested = TRUE;
		}
		else if (Number == LM_EXTRA_DATA_GET) {
			llSetTimerEvent(0.0);
			DataReceived = TRUE;	// we don't really need this because we can just stop the timer, but I'm leaving it in case we use the timer for something else later
			list Elements = llParseStringKeepNulls(String, [ "^" ], []);
			LatLonSet = (integer)llList2String(Elements, 0);
			Lat = (float)llList2String(Elements, 1);
			Lon = (float)llList2String(Elements, 2);
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			AvId = Id;
			list TouchData = llParseStringKeepNulls(String, [ "|" ], []);    // Parse the data into a list of the four different parts
			if (Selected) {    // If we're selected, we just report the click to the ML
				llMessageLinked(LINK_ROOT, LM_TOUCH_NORMAL, llList2CSV(llGetLinkNumber() + TouchData), AvId);
				return;
			}			
			integer TouchFace = (integer)llList2String(TouchData, 0);
			if (TouchFace == FaceSet) {
				TextboxChannel = 10000 - (integer)llFrand(1000000);
				TextboxListener = llListen(TextboxChannel, "", AvId, "");
				llTextBox(AvId, "Enter coordinates or blank to cancel:", TextboxChannel);
			}
			else if (TouchFace == FaceSelect) {
				if (LatLonSet) {
					llMessageLinked(LINK_SET, LM_STREETVIEW_COORDS, (string)Lat + "," + (string)Lon, AvId);
				}
				else {
					Alert(AvId, "Coordinates not set.\n\nClick the edge to set them.");
				}
			}
		}
		else if (Number == LM_PRIM_SELECTED) {
			if ((integer)String == llGetLinkNumber()) {    // if it's our link number
				Selected = TRUE;
			}
		}
		else if (Number == LM_PRIM_DESELECTED) {
			if ((integer)String == llGetLinkNumber()) {    // if it's our link number
				Selected = FALSE;
			}
		}		
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == TextboxChannel && Id == AvId) {
			Message = llStringTrim(Message, STRING_TRIM);
			if (Message == "") return;
			llListenRemove(TextboxListener);
			list Parts = llParseStringKeepNulls(Message, [ ",", "|" ], []);
			if (llGetListLength(Parts) != 2) {
				Alert(AvId, "Must be latitude and longitude separated by \",\":\n\n" + Message);
				return;
			}
			Lat = (float)llList2String(Parts, 0);
			Lon = (float)llList2String(Parts, 1);
			LatLonSet = TRUE;
			string Data = llDumpList2String([ LatLonSet, Lat, Lon ], "^");
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_SET, Data, NULL_KEY);
		}
	}
	timer() {
		if (!DataReceived) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, RtfString, NULL_KEY);
		}
	}
}
// Panorama location v1.0.0