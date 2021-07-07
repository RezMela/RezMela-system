// Panocube v1.1.0

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

// v1.1.0 - change to use dynamic textures (instead of MOAP)
// v1.0.3 - add script PIN
// v1.0.2 - improve debugging
// v1.0.1 - temporarily remove unsupported options, rename to 'Panocube', save bookmarks to start of list
// v0.13 - fix bug whereby heavy relinking (as in ML) caused wrong surfaces to be used
// v0.12 - process lat/lon as well as pano ID from extension
// v0.11 - add Chrome extension integration
// v0.10 - remove redisplay when avatar enters region; add redisplay button
// v0.9 - minor fix for state whereby needless messages are being sent
// v0.8 - workround OpenSim bug that resets variables on region restart
// v0.7 - bug fixes, receive coordinates via link message, remember bookmarks page
// v0.6 - rescan link numbers on changed_link rather than restart
// v0.5 - added ML integration
// v0.4 - added search feature
// v0.3 - added interactivity
//
//    Note that if part of a ML, this script and associated files should be in the street view button itself
//
// Google API documentation:
// https://developers.google.com/maps/documentation/streetview/intro
// Previous method here:
// https://developers.google.com/maps/documentation/javascript/streetview
// Search API key: AIzaSyAmdGed6n7oOmU-HJEBm4wNvh4Mi_xlJPo
//

integer DEBUGGER = -391867620;
integer SCRIPT_PIN = -19318100;
integer DebugMode = FALSE;

integer MAP_CHAT_CHANNEL = -40101912;

integer GMW_LOCATION = -90153000;

integer LM_RESET = -405535;

string CONFIG_NOTECARD = "Panocube config";
string BOOKMARKS_NOTECARD = "Places";

rotation CurrentRot;

integer Fov;
string ApiKey;
string SearchApi;
float DisplayDelay = 5.0;
key LoadingTexture = TEXTURE_BLANK;

integer LinkSetChanged = FALSE;
integer NeedDisplay = FALSE;

// Details of prim to be used to display pano
string PrimName = "";
integer PanoObjectLinkNum = LINK_THIS;    // LINK_THIS (-4) for same prim
// Faces data
list Faces = [];
list Angles = [];
list Pitches = [];
integer DisplaysCount = 0;

integer PrimMenu;    // -1 if prim doesn't exist (including if we're part of a ML)
integer PrimCount;

integer StandAlone = TRUE;        // TRUE if it's a standalone, so no integration with control board, etc
string LastExtraData;                // The last extra data sent, so don't resend if it's the same

// Malleable linkset stuff
integer IsMl;
// External Touch Handling messages
integer ETH_LOCK = -44912700;        // Send to central script to bypass touch handling
integer ETH_UNLOCK = -44912701;        // Send to central script to return to normal touch handling
integer ETH_TOUCHED = -44912702;    // Sent to external script to notify of touch
integer ETH_PROCESS = -44912703;    // Sent to central script to mimic touch

// Search integration
integer GMC_SEARCH = -90152000;
integer GMC_MOVE_TO = -90152001;

// RezMela world object, request for icon ID, etc
integer RWO_ICON_UUID = 808399100;    // +ve for request, -ve for reply
integer RWO_EXTRA_DATA_SET = 808399102;    // +ve for incoming, -ve for outgoing
integer RWO_INITIALISE = 808399110;    // +ve for data (received repeateadly at startup), we send -ve to disable. Icon ID is sent as key portion, ExtraData as string

integer WO_COMMAND = 3007;

// Receiving coordinates from other scripts
integer LM_STREETVIEW_COORDS = -71143300;
// Extension integration
integer LM_EXTENSION_MENU = -71143301;
integer LM_EXTENSION_PANO = -71143302;

integer DisplayType = 0;
integer DISP_UNDEFINED = 0;
integer DISP_LAT_LON = 1;
integer DISP_PANO_ID = 2;

string PanoId;
float CurrentLat;
float CurrentLon;
integer Heading;

list Bookmarks;
integer BOOK_NAME = 0;
integer BOOK_LAT = 1;
integer BOOK_LON = 2;
integer BOOK_PANOID = 3;
integer BOOK_MODE = 4;
integer BOOK_STRIDE = 5;
integer BookmarksCount;
string BookmarkName;

// Menu stuff
integer MenuChannel;
integer MenuListener;
key AvId;
integer CurrentMenu;
string MenuMessage;
integer MENU_NONE = 0;
integer MENU_MAIN = 1;
integer MENU_BOOKMARKS = 2;
integer MENU_MESSAGE = 3;

integer BOOKMARKS_PAGE_SIZE = 9;
integer MenuOptionPtr;
string BTN_COORDINATES = "Go to place";
string BTN_FINISH = "< FINISH";
string BTN_BOOKMARKS = "Places";
string BTN_REFRESH = "Refresh";
string BTN_EXTENSION = "Queue check";
string BTN_MODE_PANOID = "Pano ID";
string BTN_MODE_LATLON = "Lat/Long";
string BTN_QUIT_BOOKMARKS = "< CANCEL";
string BTN_NEXT = ">>";
string BTN_PREV = "<<";
string BTN_ADD_BOOKMARK = "Save ...";
string BTN_SEARCH = "Search ...";
string BTN_BLANK = " ";

integer TextboxMode;
integer TM_COORDINATES = 1;
integer TM_SAVE_NAME = 2;
integer TextboxChannel;
integer TextboxListener;

Debug(string Text) {
	if (DebugMode) {
		llOwnerSay("Pano: " + Text);
		llRegionSay(DEBUGGER, "Pano: " + Text);
	}
}
// Display is in two stages. DisplayStart() renders the dynamic textures on the invisible
// cube (which is hollow and cut in order to provide sufficient faces). osSetDynamicTextureURLBlendFace() is
// asynchronous for some reason (despite what the OpenSim wiki says), so we need a delay between doing that
// and picking up the dynamic texture IDs from those faces. DisplayEnd() does that second part, after a
// timer delay defined by DisplayDelay.
DisplayStart() {
	Debug("Displaying " + (string)DisplaysCount + " views");
	if (LinkSetChanged) {    // if we've had unlinking/linking, we need to get the prim data again
		GetPrimData();
		LinkSetChanged = FALSE;
	}
	list Params = [];
	integer P = DisplaysCount;
	while(P--) {
		integer Face = llList2Integer(Faces, P);
		integer Angle = llList2Integer(Angles, P);
		integer Pitch = llList2Integer(Pitches, P);
		integer FaceHeading = Heading + Angle;
		while (FaceHeading > 360) FaceHeading -= 360;
		while (FaceHeading < 0) FaceHeading += 360;
		string Url = BuildUrl(FaceHeading, Pitch);
		osSetDynamicTextureURLBlendFace("", "image", Url, "", FALSE, 2, 600, 255, Face);
		Params += [ PRIM_TEXTURE, Face, LoadingTexture, <-1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, FaceRot(Face) ];
		Debug("Face " + (string)Face + " (" + (string)Angle + "°/" + (string)Pitch + "°):\n" + Url);
	}
	llSetLinkPrimitiveParamsFast(PanoObjectLinkNum, Params);
	SetExtraData();
	NeedDisplay = TRUE;
	llSetTimerEvent(DisplayDelay);
}
DisplayEnd() {
	if (!NeedDisplay) return;
	list Params = [];
	integer P = DisplaysCount;
	while(P--) {
		integer Face = llList2Integer(Faces, P);
		string TextureUuid = llGetTexture(Face);
		Params += [ PRIM_TEXTURE, Face, TextureUuid, <-1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, FaceRot(Face) ];
	}
	llSetLinkPrimitiveParamsFast(PanoObjectLinkNum, Params);
	NeedDisplay = FALSE;
}
float FaceRot(integer Face) {
	float Rot = 0.0;
	// Due to UV mapping issue, these faces need a non-zero rotation
	if (Face == 3) Rot = -90.0;
	else if (Face == 4) Rot = 180.0;
	else if (Face == 7) Rot = 180.0;
	Rot *= DEG_TO_RAD;
	return Rot;
}
string BuildUrl(integer Head, integer Pitch) {
	string Place;
	if (DisplayType == DISP_LAT_LON)
		Place = "location=" + (string)CurrentLat + "," + (string)CurrentLon;
	else if (DisplayType == DISP_PANO_ID)
		Place = "pano=" + PanoId;
	return "https://maps.googleapis.com/maps/api/streetview?size=640x640" +
		"&" + Place +
		"&fov=" + (string)Fov + "&heading=" + (string)Head +
		"&pitch=" + (string)Pitch + "&key=" + ApiKey;
}
// Set debug mode according to this prim description
SetDebug() {
	DebugMode = (llGetObjectDesc() == "debug");
}
ShowMenu(integer WhichMenu, key pAvId) {
	CurrentMenu = WhichMenu;
	if (AvId != NULL_KEY && pAvId != AvId) {
		if (llGetAgentSize(AvId) != ZERO_VECTOR) {    // if they're still logged in and in the region
			llDialog(AvId, llKey2Name(pAvId) + " now has control of the menu", [ "OK" ], -12839378984);
			MenuOptionPtr = 0;    // So the new user isn't left with the remembered bookmarks page from the previous user
		}
	}
	AvId = pAvId;
	string MenuText = "STREET VIEW PANORAMAS\n\n";
	list Buttons = [];
	if (CurrentMenu == MENU_MAIN) {
		if (DisplayType == DISP_LAT_LON) {
			MenuText += "Lat/Long: " + (string)CurrentLat + ", " + (string)CurrentLon + "\n";
		}
		else if (DisplayType == DISP_PANO_ID) {
			MenuText += "Panorama ID: " + PanoId + "\n";
		}
		MenuText +=
			//            DescribeButton(BTN_EXTENSION, "Check for queued panoramas") +
			//            DescribeButton(BTN_MODE_PANOID, "Best for Google images") +
			//            DescribeButton(BTN_MODE_LATLON, "Best for user images") +
			DescribeButton(BTN_COORDINATES, "Go to specified Lat/Long") +
			DescribeButton(BTN_BOOKMARKS, "Load a place") +
			DescribeButton(BTN_ADD_BOOKMARK, "Save current place") +
			DescribeButton(BTN_REFRESH, "Redisplay") +
			DescribeButton(BTN_SEARCH, "Search for an address");

		Buttons = [
			BTN_FINISH, BTN_REFRESH, BTN_SEARCH,
			BTN_COORDINATES, BTN_BOOKMARKS, BTN_ADD_BOOKMARK
				//            BTN_EXTENSION, BTN_MODE_PANOID, BTN_MODE_LATLON
				];
	}
	else if (CurrentMenu == MENU_BOOKMARKS) {
		integer P = MenuOptionPtr;
		integer Q = MenuOptionPtr + BOOKMARKS_PAGE_SIZE;    // Q is 1-counting, not 0-counting
		if (Q > BookmarksCount) Q = BookmarksCount;
		MenuText += "Select place to display:\n";
		list Options = [];
		integer OptionsCount = 0;
		for (; P < Q && OptionsCount < 9; P++) {
			string Name = llList2String(Bookmarks, P * BOOK_STRIDE);
			string OptionStr = (string)(P + 1);
			MenuText += "\n" + OptionStr + " - " + Name;
			Options += OptionStr;
			OptionsCount++;
		}
		while (OptionsCount < 9) { Options += BTN_BLANK; OptionsCount++; }    // fill buttons up to 9 with blanks
		Buttons = [ BTN_QUIT_BOOKMARKS ];
		if (MenuOptionPtr) Buttons += BTN_PREV; else Buttons += BTN_BLANK;
		if (Q < BookmarksCount) Buttons += BTN_NEXT; else Buttons += BTN_BLANK;
		Buttons += OrderButtons(Options);
	}
	else if (CurrentMenu == MENU_MESSAGE) {
		MenuText += MenuMessage;
		Buttons = [ "OK" ];
	}
	MenuChannel = 10000 - (integer)llFrand(1000000);
	MenuListener = llListen(MenuChannel, "", AvId, "");
	llDialog(AvId, "\n" + MenuText, Buttons, MenuChannel);
}
string DescribeButton(string Button, string Description) {
	return "\n[" + Button + "] " + Description;
}
ShowTextBox(integer Mode, string Text) {
	TextboxChannel = 10000 - (integer)llFrand(1000000);
	TextboxListener = llListen(TextboxChannel, "", AvId, "");
	llTextBox(AvId, "\n" + Text, TextboxChannel);
	TextboxMode = Mode;
}
ProcessMenu(string Input) {
	Debug("Processing menu: " + Input);
	if (Input == BTN_BLANK) {        // if they've selected a blank button, just redisplay the same menu
		ShowMenu(CurrentMenu, AvId);
		return;
	}
	if (CurrentMenu == MENU_MAIN) {
		if (Input == BTN_FINISH) {
			AvId = NULL_KEY;
			llListenRemove(MenuListener);
			return;
		}
		else if (Input == BTN_COORDINATES) {
			ShowTextBox(TM_COORDINATES, "Enter coordinates or blank to cancel");
			return;
		}
		else if (Input == BTN_BOOKMARKS) {
			ShowMenu(MENU_BOOKMARKS, AvId);
			return;
		}
		else if (Input == BTN_ADD_BOOKMARK) {
			ShowTextBox(TM_SAVE_NAME, "Enter description of place\nor blank to cancel");
			return;
		}
		else if (Input == BTN_SEARCH) {
			llMessageLinked(LINK_SET, GMC_SEARCH, SearchApi, AvId);
			return;
		}
		else if (Input == BTN_REFRESH) {
			DisplayStart();
			return;
		}
		else if (Input == BTN_EXTENSION) {
			llMessageLinked(LINK_THIS, LM_EXTENSION_MENU, "ext", AvId);
			return;
		}
		else if (Input == BTN_MODE_LATLON) {
			if (DisplayType == DISP_PANO_ID) {
				DisplayType = DISP_LAT_LON;
				DisplayStart();
			}
		}
		else if (Input == BTN_MODE_PANOID) {
			if (DisplayType == DISP_LAT_LON && PanoId != "") {
				DisplayType = DISP_PANO_ID;
				DisplayStart();
			}
		}
	}
	else if (CurrentMenu == MENU_BOOKMARKS) {
		if (Input == BTN_QUIT_BOOKMARKS) {
			ShowMenu(MENU_MAIN, AvId);
			return;
		}
		else if (Input == BTN_NEXT) {
			MenuOptionPtr += BOOKMARKS_PAGE_SIZE;
			if (MenuOptionPtr > BookmarksCount - BOOKMARKS_PAGE_SIZE) MenuOptionPtr = BookmarksCount - BOOKMARKS_PAGE_SIZE;
			ShowMenu(MENU_BOOKMARKS, AvId);
			return;
		}
		else if (Input == BTN_PREV) {
			MenuOptionPtr -= BOOKMARKS_PAGE_SIZE;
			if (MenuOptionPtr < 0) MenuOptionPtr = 0;
			ShowMenu(MENU_BOOKMARKS, AvId);
			return;
		}
		else if ((integer)Input) {
			integer Choice = (integer)Input - 1;
			LoadBookmark(Choice);
			CurrentMenu = MENU_NONE;
			return;
		}
	}
	else if (CurrentMenu == MENU_MESSAGE) {
		ShowMenu(MENU_MAIN, AvId);    // they've OK'd the message dialog, so return them to the main menu
		return;
	}
	ShowMenu(MENU_MAIN, AvId);
}
ProcessTextBox(string Input) {
	Debug("Processing textbox: " + Input);
	if (TextboxMode == TM_COORDINATES) {
		if (Input == "") {
			ShowMenu(MENU_MAIN, AvId);
			return;
		}
		list Parts = llParseStringKeepNulls(Input, [ ",", "|" ], []);
		integer PartsCount = llGetListLength(Parts);
		if (PartsCount == 2) {    // Probably lat/lon?
			float Lat = (float)llList2String(Parts, 0);
			float Lon = (float)llList2String(Parts, 1);
			if (Lat == 0.0 || Lon == 0.0) {
				ShowMenuMessage("Invalid lat/lon:\n\n" + Input);
				return;
			}
			DisplayType = DISP_LAT_LON;
			CurrentLat = Lat;
			CurrentLon = Lon;
		}
		else if (PartsCount == 1) {    // Let's guess it's a pano id
			DisplayType = DISP_PANO_ID;
			PanoId = llList2String(Parts, 0);
		}
		DisplayStart();
	}
	else if (TextboxMode == TM_SAVE_NAME) {
		if (Input == "") {
			ShowMenu(MENU_MAIN, AvId);
			return;
		}
		// So we have a name for a bookmark. First, check it's not already been used
		integer P = llListFindList(Bookmarks, [ Input ]);
		if (P > -1) {
			ShowMenuMessage("Place already exists with name '" + Input + "'");
			return;
		}
		if (llSubStringIndex(Input, "|") > -1) {    // We can't allow this because it's a separator in the notecard
			ShowMenuMessage("Invalid character in name: '|'");
			return;
		}
		BookmarkName = Input;
		state SaveBookmark;
	}
}
// Shows a special menu with just a message and an OK button that returns to main menu.
ShowMenuMessage(string Message) {
	MenuMessage = Message;
	ShowMenu(MENU_MESSAGE, AvId);
}
list OrderButtons(list Buttons) {
	return llList2List(Buttons, -3, -1) + llList2List(Buttons, -6, -4)
		+ llList2List(Buttons, -9, -7) + llList2List(Buttons, -12, -10);
}
GetDefaultBookmark() {
	Debug("Getting default bookmark");
	LoadBookmark(0);
}
LoadBookmark(integer Which) {
	Debug("Loading bookmark " + (string)Which);
	integer Ptr = Which * BOOK_STRIDE;
	CurrentLat = llList2Float(Bookmarks, Ptr + BOOK_LAT);
	CurrentLon = llList2Float(Bookmarks, Ptr + BOOK_LON);
	PanoId = llList2String(Bookmarks, Ptr + BOOK_PANOID);
	string M = llList2String(Bookmarks, Ptr + BOOK_MODE);
	if (M == "L") DisplayType = DISP_LAT_LON; else DisplayType = DISP_PANO_ID;
	DisplayStart();
}
integer ReadBookmarks() {
	Debug("Reading bookmarks");
	if (llGetInventoryType(BOOKMARKS_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Can't find notecard '" + BOOKMARKS_NOTECARD + "'");
		return FALSE;
	}
	Bookmarks = [];
	BookmarksCount = 0;
	integer LineCount = osGetNumberOfNotecardLines(BOOKMARKS_NOTECARD);
	integer First = TRUE;
	integer P;
	for (P = 0; P < LineCount; P++) {
		string Line = llStringTrim(osGetNotecardLine(BOOKMARKS_NOTECARD, P), STRING_TRIM);
		if (Line != "") {
			list Parts = llParseStringKeepNulls(Line, [ "|" ], []);
			// Older notecards only have name, lat, lon, so we default the rest
			if (llGetListLength(Parts) < 3) {
				llOwnerSay("Invalid line in places:\n" + Line);
				return FALSE;
			}
			string bName = llList2String(Parts, 0);
			string Lat = llList2String(Parts, 1);
			string Lon = llList2String(Parts, 2);
			string PanoId = llList2String(Parts, 3);
			string Mode = llList2String(Parts, 4);
			if (Mode == "") Mode = "L";
			Bookmarks += [ bName, Lat, Lon, PanoId, Mode ];
			BookmarksCount++;
			if (First && DisplayType == DISP_UNDEFINED) {    // Load first entry as current if we have nothing set
				Debug("Displaying first bookmark");
				LoadBookmark(0);
			}
		}
		First = FALSE;
	}
	Debug("Bookmarks loaded");
	return TRUE;
}
// Obtain integer heading (in degrees) from given rotation
integer Rot2Heading(rotation Rot) {
	vector Euler = llRot2Euler(Rot);
	return -(integer)(Euler.z * RAD_TO_DEG);
}
//ClearAllMedia() {
//    integer P = 0;
//    while(++P <= PrimCount) {
//        llClearLinkMedia(P, ALL_SIDES);
//    }
//}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
integer ReadConfig() {
	Debug("Reading config card");
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	integer IsOK = TRUE;
	// Set config defaults
	ApiKey = "ApiKeyUnknown";
	SearchApi = "ApiKeyUnknown";
	Fov = 90;
	PrimName = "Pano";
	Faces = [];
	Angles = [];
	Pitches = [];
	DisplaysCount = 0;
	DisplayDelay = 5.0;
	LoadingTexture = TEXTURE_BLANK;
	IsMl = FALSE;
	StandAlone = FALSE;
	integer Lines = osGetNumberOfNotecardLines(CONFIG_NOTECARD);
	integer I;
	for(I = 0; I < Lines; I++) {
		string Line = osGetNotecardLine(CONFIG_NOTECARD, I);
		integer Comment = llSubStringIndex(Line, "//");
		if (Comment != 0) {    // Not a complete comment line
			if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);    // strip from comments characters onwards
			if (llStringTrim(Line, STRING_TRIM) != "") {    // if there's something left after comments are removed
				// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
				list L = llParseStringKeepNulls(Line, [ "=" ], [ ]);    // Separate LHS and RHS of assignment
				if (llGetListLength(L) == 2) {    // so there is a "X = Y" kind of syntax
					string OName = llStringTrim(llList2String(L, 0), STRING_TRIM);        // original parameter name
					string Name = llToLower(OName);        // lower-case version for case-independent parsing
					string Value = llStringTrim(llList2String(L, 1), STRING_TRIM);
					// Interpret name/value pairs
					if (Name == "apikey")    ApiKey = StripQuotes(Value, Line);
					else if (Name == "searchapikey")    SearchApi = StripQuotes(Value, Line);
					else if (Name == "fov")    Fov = (integer)Value;
					else if (Name == "primname") PrimName = StripQuotes(Value, Line);
					else if (Name == "displaydelay") DisplayDelay = (float)Value;
					else if (Name == "loadingtexture") LoadingTexture = (key)Value;
					else if (Name == "display") {
						list FaceData = llCSV2List(Value);
						if (llGetListLength(FaceData) != 3) {
							llOwnerSay("Invalid \"Display\" entry in config file: '" + Value + "' (should be <face#>,<angle>,<pitch>)");
							IsOK = FALSE;
						}
						else {
							integer Face = (integer)llList2String(FaceData, 0);
							integer Angle = (integer)llList2String(FaceData, 1);
							integer Pitch = (integer)llList2String(FaceData, 2);
							Faces += Face;
							Angles += Angle;
							Pitches += Pitch;
							DisplaysCount++;
						}
					}
					else if (Name == "isml") {
						IsMl = String2Bool(Value);
					}
					else if (Name == "standalone") {
						StandAlone = String2Bool(Value);
					}
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
		if (IsMl)
			llMessageLinked(LINK_ROOT, ETH_LOCK, "", NULL_KEY);    // prevent ML from acting on clicks on menu
	}
	return IsOK;
}
// Takes a string in double quotes, and strips out the quotes. Validates the format.
// <Text> is the string with quotes; <Line> is the entire line for error reporting
string StripQuotes(string Text, string Line) {
	if (Text == "") {    // allow empty string for null value
		return("");
	}
	if (llGetSubString(Text, 0, 0) == "\"" && llGetSubString(Text, -1, -1) == "\"") {     // if surrounded by quotes
		return(llGetSubString(Text, 1, -2));    // strip quotes
	}
	else {
		llOwnerSay("Invalid string literal (missing \"\"?): " + Line);
		return("");
	}
}
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
GetExtraData(string ExtraData) {
	if (ExtraData != "") {
		list L = llParseStringKeepNulls(ExtraData, [ "^" ], []);
		CurrentLat = (float)llList2String(L, 0);
		CurrentLon = (float)llList2String(L, 1);
	}
	DisplayStart();
}
SetExtraData() {
	string ExtraData = llDumpList2String([
		CurrentLat,
		CurrentLon
			], "^");
	if (ExtraData != LastExtraData && !StandAlone) {
		llMessageLinked(LINK_SET, RWO_EXTRA_DATA_SET, ExtraData, NULL_KEY);
		LastExtraData = ExtraData;
	}
}
// Calculate link numbers - always call this after we call ReadConfig()
GetPrimData() {
	PrimCount = llGetNumberOfPrims();
	PrimMenu = -1;
	PanoObjectLinkNum = LINK_THIS;
	integer P;
	// Process linkset
	for (P = 1; P <= PrimCount; P++) {
		string Name = llGetLinkName(P);
		if (!IsMl && (Name == "menu")) PrimMenu = P;
		if (Name == PrimName) PanoObjectLinkNum = P;
	}
	LinkSetChanged = FALSE;
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetRemoteScriptAccessPin(SCRIPT_PIN);
		SetDebug();
		state Boot;
	}
}
state Boot {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Debug("Initialising (script: " +llGetScriptName() + ")");
		CurrentLat = CurrentLon = 0.0;
		if (ReadConfig()) {
			GetPrimData();
			if (!ReadBookmarks()) return;
			if (!StandAlone) {    // if it's part of a rezmela setup
				state RezMelaListen;
			}
			else {
				//                GetDefaultBookmark();
				state Normal;
			}
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			llResetScript();
		}
	}
}
state RezMelaListen {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Debug("Listening for RezMela data");
		llSetTimerEvent(2.0);    // Longer than worldobject script's timer, enough to receive data if there is any
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == RWO_INITIALISE) {    // message from worldobject script, giving extra data
			llSetTimerEvent(0.0);
			GetExtraData(String);
			llMessageLinked(LINK_SET, -RWO_INITIALISE, "", NULL_KEY);    // send message to worldobject script to tell it to stop sending us data
			state Normal;
		}
	}
	timer() {
		// No extra data received, so load first bookmark
		llSetTimerEvent(0.0);
		GetDefaultBookmark();
		state Normal;
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(DisplayDelay); // we may have a default pano to show
		MenuOptionPtr = 0;
		Debug("Ready");
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == GMC_MOVE_TO) {
			list L = llParseStringKeepNulls(String, [ "," ], []);
			CurrentLat = (float)llList2String(L, 0);
			CurrentLon = (float)llList2String(L, 1);
			DisplayStart();
		}
		else if (Number == LM_STREETVIEW_COORDS) {
			list L = llParseStringKeepNulls(String, [ "," ], []);
			CurrentLat = (float)llList2String(L, 0);
			CurrentLon = (float)llList2String(L, 1);
			DisplayStart();
		}
		else if (Number == RWO_INITIALISE) {    // message from worldobject script, giving extra data (which we already have)
			llMessageLinked(LINK_SET, -RWO_INITIALISE, "", NULL_KEY);    // send message to worldobject script to tell it to stop sending us data
		}
		else if (Number == LM_EXTENSION_MENU) {
			if (String == "main") {        // extension script is returning control to us from its menu
				AvId = Id;
				ShowMenu(MENU_MAIN, AvId);
			}
		}
		else if (Number == LM_EXTENSION_PANO) {
			list Parts = llParseStringKeepNulls(String, [ "|" ], []);
			PanoId = llList2String(Parts, 0);
			CurrentLat = (float)llList2String(Parts, 1);
			CurrentLon = (float)llList2String(Parts, 2);
			DisplayType = DISP_LAT_LON;
			DisplayStart();
		}
		else if (Number == LM_RESET) {    // global reset
			llResetScript();
		}
	}
	touch_start(integer Number) {
		// We respond if (a) we're part of a ML, or (b) they clicked the "menu" prim (which doesn't exist for a ML, since we're inside the menu button anyway)
		if (IsMl || (llDetectedLinkNumber(0) == PrimMenu)) {
			ShowMenu(MENU_MAIN, llDetectedKey(0));
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == AvId) {
			ProcessMenu(Message);
		}
		else if (Channel == TextboxChannel && Id == AvId) {
			llListenRemove(TextboxListener);
			ProcessTextBox(Message);
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		DisplayEnd();
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			state Boot;
		}
		if (Change & CHANGED_REGION_START) {
			BTN_BLANK = " ";    // Shouldn't be necessary - OpenSim sets this variable to "" (null) on region restart
			DisplayStart();
		}
		if (Change & CHANGED_LINK) {
			LinkSetChanged = TRUE;
		}
	}
}
// We have a separate state for saving a bookmark because we need to work around the OpenSim bug that causes notecard deletion/rewriting to fail
state SaveBookmark {
	state_entry() {
		string M = "L";
		if (DisplayType == DISP_PANO_ID) M = "P";
		Bookmarks = [ BookmarkName, CurrentLat, CurrentLon, PanoId, M ] + Bookmarks;
		BookmarksCount ++;
		llRemoveInventory(BOOKMARKS_NOTECARD);
		llSetTimerEvent(0.5);
	}
	timer() {
		llSetTimerEvent(0.0);
		// Save bookmarks list to notecard
		list NotecardLines = [];
		integer P;
		for (P = 0; P < BookmarksCount; P++) {
			integer B = P * BOOK_STRIDE;
			string Name = llList2String(Bookmarks, B  +  BOOK_NAME);
			NotecardLines += llDumpList2String(llList2List(Bookmarks, B, B + BOOK_STRIDE - 1), "|");
		}
		osMakeNotecard(BOOKMARKS_NOTECARD, NotecardLines);
		ShowMenuMessage("Place '" + BookmarkName + "' saved OK");
		ReadBookmarks();     // Not strictly necessary, but will make problems apparent earlier
		state Normal;
	}
}
// Panocube v1.0.4