// Bookmark v1.0.2

//
// Used to store and recall URLs to be sent to web browsers.
//

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

// v1.0.2 - implement LM_REGION_START
// v1.0.1 - fix bug with cover color not being initialised correctly
// v1.0 - name change (from "Hotlink", bug fixes, major version change
// v0.13 - improved LMs on loading
// v0.12 - remove initial delay
// v0.11 - streamlined load procedure
// v0.10 - new method of getting data (LM rather than prim text)
// v0.8 - added feature to color bookmark on creation
// v0.7 - improved formatting of titles (multi-line, scaling)
// v0.6 - orientations of titles added
// v0.5 - tidy up parsing of prim text parameters
// v0.4 - set transparent texture on loading
// v0.3 - extended functions
// v0.2 - added functionality for "book" UI

string CONFIG_NOTECARD = "Bookmark config";

string Url;
key LoggedAvId;		// Maybe we don't need this any more - leaving it just in case

// RezMela world object, request for icon ID, etc
//integer RWO_ICON_UUID = 808399100;	// +ve for request, -ve for reply
//integer RWO_EXTRA_DATA_SET = 808399102;	// +ve for incoming, -ve for outgoing
integer RWO_INITIALISE = 808399110;	// +ve for data (received repeateadly at startup), we send -ve to disable. Icon ID is sent as key portion, ExtraData as string

// Messages from ML 
integer LM_PRIM_SELECTED = -405500;		// A prim has been selected
integer LM_PRIM_DESELECTED = -405501;	// A prim has been deselected
integer LM_SEAT_USER = -405520;			// Someone has logged in/out of the ML

// Message to browser to load URL
integer WST_LOAD_URL = -588137200;	// Instruction to us to load given URL

// Menu stuff
integer MenuChannel;
integer MenuListener;
key AvId;

integer TextboxChannel;
integer TextboxListener;

string Title;
vector CoverColor;
string TitleColor;
list CoverColors;	// Strings of "<name>,<rgb>"
list TitleColors; 	// Strings of "<name>, <color string>"
// Color strings are here: http://msdn.microsoft.com/en-us/library/aa358802.aspx or in theory you can use "aarrggbb"
// e.g. FFFF0000 for solid red; 800000FF for semi-transparent blue
// Refer here for more info: http://opensimulator.org/wiki/OsSetPenColor

// Parallel lists
list TitleFaces;
list TitleRepeats;
list TitleRotations;
list TitlePosXs;
list TitlePosYs;
list TitleFontNames;
list TitleFontSizes;
list TitleLineHeights;
list TitleMaxWidths;

list MenuFaces;
list MenuRegionsStartS;
list MenuRegionsEndS;
list MenuRegionsStartT;
list MenuRegionsEndT;

list ColorFaces = [];

string BrowserString = "";

integer DataRequested;
integer DataReceived;
string RtfString;
integer Selected = FALSE;

integer CurrentMenu;

integer MENU_MAIN = 1;
integer MENU_COLOR = 2;
integer MENU_SET_URL = 3;
integer MENU_SET_TITLE = 4;

integer MenuColor;
integer MENU_COLOR_TITLE = 1;
integer MENU_COLOR_COVER = 2;

string BTN_SET_URL = "Set URL";
string BTN_LAUNCH = "LAUNCH";
string BTN_SET_TITLE = "Set title";
string BTN_TITLE_COLOR = "Title color";
string BTN_COVER_COLOR = "Cover color";
string BTN_CANCEL = "Cancel";
string BTN_BACK = "<< Back";

// Link messaage number, sent by ML main script
integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_REGION_START = -405533; // region restart
integer LM_RESERVED_TOUCH_FACE = -44088510;
integer LM_TOUCH_NORMAL	= -66168300;

SendToWebBrowser() {
	// We try to find the nearest browser. They're identified by virtue of containing a set string,
	// and we find the nearest to us in the linkset. Thus, a bookmark should work only on the closest browser.
	vector MyPos = llList2Vector(llGetPrimitiveParams([ PRIM_POS_LOCAL ]), 0);
	integer TargetLinkNum = -1;
	float TargetDistance = 1000000.0;
	integer PrimCount = llGetNumberOfPrims();
	integer P;
	for (P = 2; P <= PrimCount; P++) {
		string PrimName = llGetLinkName(P);
		if (llGetSubString(PrimName, 0, 0) != "!") {	// if it's not a button
			if (llSubStringIndex(llToLower(PrimName), BrowserString) > -1) {
				vector PrimPos = llList2Vector(llGetLinkPrimitiveParams(P, [ PRIM_POS_LOCAL ]), 0);
				float PrimDistance = llVecDist(MyPos, PrimPos);
				if (PrimDistance < TargetDistance) {
					TargetDistance = PrimDistance;
					TargetLinkNum = P;
				}
			}
		}
	}
	if (TargetLinkNum == -1) TargetLinkNum = LINK_SET;	// If we didn't find any prims by name, broadcast to all prims
	llMessageLinked(TargetLinkNum, WST_LOAD_URL, Url, AvId);
}
DisplayTitle() {
	list Params = [];
	integer L = llGetListLength(TitleFaces);
	integer I;
	for (I = 0; I < L; I++) {
		string CommandList = "";
		integer Face = llList2Integer(TitleFaces, I);
		if (Title == "") {
			Params += [ PRIM_TEXTURE, Face, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0 ];
		}
		else {
			vector Repeats = llList2Vector(TitleRepeats, I);
			float Rotation = llList2Float(TitleRotations, I) * DEG_TO_RAD;
			integer PosX = llList2Integer(TitlePosXs, I);
			integer PosY = llList2Integer(TitlePosYs, I);
			string FontName = llList2String(TitleFontNames, I);
			integer FontSize = llList2Integer(TitleFontSizes, I);
			integer LineHeight = llList2Integer(TitleLineHeights, I);
			integer MaxWidth = llList2Integer(TitleMaxWidths, I);
			// Extract words (ie non-space strings) into a list
			list Words = llParseString2List(Title, [ " " ], []);
			// Next, find out what font size will fit all words into line
			FontSize = FindFontSizeByWidth(Words, FontName, FontSize, MaxWidth);
			// Next, lay out lines of text
			list Lines = [];
			string Line;
			integer WordCount = llGetListLength(Words);
			integer W;
			for (W = 0; W < WordCount; W++) {
				string Word = llList2String(Words, W);
				string TryLine = llStringTrim(Line + " " + Word, STRING_TRIM);	// add word onto current line to see how it fits
				vector DrawSize = osGetDrawStringSize("vector", TryLine, FontName, FontSize);
				if ((integer)DrawSize.x > MaxWidth) {// if it's wider than the max width, we leave the line alone and start on a new one
					Lines += Line;
					Line = Word;
				}
				else {				// if it fits OK
					Line = TryLine;		// we can continue, using this line
				}
			}
			// The last line won't have been added in, so we do that now
			Lines += Line;
			// Now lay out the page
			CommandList = osSetPenColor(CommandList, TitleColor);
			integer LineCount = llGetListLength(Lines);
			integer LinePtr;
			integer X; integer Y;
			for (LinePtr = 0; LinePtr < LineCount; LinePtr++) {
				Line = llList2String(Lines, LinePtr);
				// First, calculate the position
				// Vertical position is start position (based on number of lines) + the number of heights to get to this line + adjustment of half a line if an even number of lines
				Y = PosY - ((LineCount / 2) * LineHeight) + (LinePtr * LineHeight) + (LineHeight / 2 * !(LineCount % 2));
				// Horizontal position is centred
				vector DrawSize = osGetDrawStringSize("vector", Line, FontName, FontSize);	// Find pixel width of line
				integer LineDrawWidth = (integer)DrawSize.x;
				X = PosX + (MaxWidth / 2) - (LineDrawWidth / 2);	// Position to centre this line: middle of area minus half the line text length
				// And do the actual drawing
				CommandList = osMovePen(CommandList, X, Y);
				CommandList = osSetFontName(CommandList, FontName);
				CommandList = osSetFontSize(CommandList, FontSize);
				CommandList = osDrawText(CommandList, Line);
			}
			osSetDynamicTextureDataBlendFace("", "vector", CommandList, "width:256,height:256,alpha:0",
				FALSE	, 2, 0, 255, Face);
			list TextureParams = llGetPrimitiveParams([ PRIM_TEXTURE, Face ]);
			key TextureId = llList2Key(TextureParams, 0);
			Params += [ PRIM_TEXTURE, Face, TextureId, Repeats, <1.0, 1.0, 0.0>, Rotation ];
		}
	}
	if (Params != []) {
		llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
	}
}
// Find out maximum font size (return value is font size)
integer FindFontSizeByWidth(list Words, string FontName, integer FontSize, integer MaxWidth) {
	integer Ok;
	do {
		Ok = TRUE;
		integer L = llGetListLength(Words);
		integer P;
		for (P = 0; P < L; P++) {
			string Word = llList2String(Words, P);
			vector DrawSize = osGetDrawStringSize("vector", Word, FontName, FontSize);
			if ((integer)DrawSize.x > MaxWidth) Ok = FALSE;	// if it's wider than the max width, it's not OK
		}
		if (!Ok) FontSize--;	// It wasn't OK, so reduce font size and try again
	} while(!Ok);
	return FontSize;
}
ShowMenu(integer WhichMenu) {
	CurrentMenu = WhichMenu;
	string MenuText;
	list Buttons;
	MenuChannel = -10000 - (integer)llFrand(1000000);
	MenuListener = llListen(MenuChannel, "", AvId, "");
	if (CurrentMenu == MENU_MAIN) {
		MenuText = "Select option:";
		Buttons = [ BTN_SET_TITLE, BTN_TITLE_COLOR, BTN_COVER_COLOR,
			BTN_LAUNCH, BTN_SET_URL, BTN_CANCEL ];
	}
	else if (CurrentMenu == MENU_COLOR) {
		if (MenuColor == MENU_COLOR_COVER) {
			MenuText = "Select colour for book cover:";
			Buttons = ColorListButtons(CoverColors);
		}
		else if (MenuColor == MENU_COLOR_TITLE) {
			MenuText = "Select colour for book title text:";
			Buttons = ColorListButtons(TitleColors);
		}
	}
	llDialog(AvId, "\n" + MenuText, Buttons, MenuChannel);
}
list ColorListButtons(list ColorList) {
	list Buttons = [];
	integer L = llGetListLength(ColorList);
	integer P;
	for (P = 0; P < L; P++) {
		string ColorLine = llList2String(ColorList, P);
		string ColorName = llList2String(llCSV2List(ColorLine), 0);
		Buttons += ColorName;
	}
	Buttons += BTN_BACK;
	Buttons = llList2List(Buttons, -3, -1) + llList2List(Buttons, -6, -4)
		+ llList2List(Buttons, -9, -7) + llList2List(Buttons, -12, -10);
	return Buttons;
}
// Check that we have a valid URL to display, return FALSE if not
integer CheckUrl(key CheckAvId) {
	if (Url == "") {
		llDialog(CheckAvId, "\nSorry, no URL stored", [ "OK" ], -819223);
		return FALSE;
	}
	return TRUE;
}
ProcessMenu(string Input) {
	llListenRemove(MenuListener);
	if (CurrentMenu == MENU_MAIN) {
		if (Input == BTN_LAUNCH) {
			llLoadURL(AvId, "Load bookmarked URL?", Url);
		}
		else if (Input == BTN_SET_URL) {
			ShowTextBox("Enter URL or blank to cancel:", MENU_SET_URL);
		}
		else if (Input == BTN_SET_TITLE) {
			ShowTextBox("Enter title or blank to cancel:", MENU_SET_TITLE);
		}
		else if (Input == BTN_COVER_COLOR) {
			MenuColor = MENU_COLOR_COVER;
			ShowMenu(MENU_COLOR);
		}
		else if (Input == BTN_TITLE_COLOR) {
			MenuColor = MENU_COLOR_TITLE;
			ShowMenu(MENU_COLOR);
		}
		// No need to do anything for BTN_CANCEL
	}
	else if (CurrentMenu == MENU_COLOR) {
		if (Input == BTN_BACK) {
			ShowMenu(MENU_MAIN);
			return;
		}
		if (MenuColor == MENU_COLOR_COVER) {
			CoverColor = (vector)GetColorFromName(CoverColors, Input);
			SetCoverColor();
		}
		else if (MenuColor == MENU_COLOR_TITLE) {
			TitleColor = GetColorFromName(TitleColors, Input);
			DisplayTitle();
		}
		SaveData();
	}
}
string GetColorFromName(list ColorList, string Button) {
	integer L = llGetListLength(ColorList);
	integer P;
	for (P = 0; P < L; P++) {
		string ColorLine = llList2String(ColorList, P);
		string ColorName = llList2String(llCSV2List(ColorLine), 0);
		if (ColorName == Button) {
			string ColorValue = llList2String(llCSV2List(ColorLine), 1);
			return ColorValue;
		}
	}
	return "";
}
ShowTextBox(string Text, integer WhichMenu) {
	CurrentMenu = WhichMenu;
	TextboxChannel = -10000 - (integer)llFrand(1000000);
	TextboxListener = llListen(TextboxChannel, "", AvId, "");
	llTextBox(AvId, "\n" + Text, TextboxChannel);
}
ProcessTextBox(string Input) {
	llListenRemove(TextboxListener);
	if (Input != "") {	// ignore empty string, which cancels operation
		if (CurrentMenu == MENU_SET_URL) {
			Url = Input;
			SaveData();
			SendToWebBrowser();
		}
		else if (CurrentMenu == MENU_SET_TITLE) {
			Title = Input;
			SaveData();
			DisplayTitle();
		}
	}
}
// Save variable data to prim text, which is picked up by ML and used to save that data in ML save files
SaveData() {
	string Data = llDumpList2String([ Url, Title, CoverColor, TitleColor ], "^");
	llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_SET, Data, NULL_KEY);
}
// Change color of colorable cover faces
SetCoverColor() {
	list Params = [];
	integer P = llGetListLength(ColorFaces);
	for (; P; P--) {
		integer Face = llList2Integer(ColorFaces, P - 1);
		Params += [ PRIM_COLOR, Face, CoverColor, 1.0 ];
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	// Set config defaults
	TitleFaces = [];
	TitleRepeats = [];
	TitleRotations = [];
	TitlePosXs = [];
	TitlePosYs = [];
	TitleFontNames = [];
	TitleFontSizes = [];
	TitleLineHeights = [];
	TitleMaxWidths = [];
	MenuFaces = [];
	MenuRegionsStartS = [];
	MenuRegionsEndS = [];
	MenuRegionsStartT = [];
	MenuRegionsEndT = [];
	ColorFaces = [];
	CoverColors = [];
	TitleColor = "Black";
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
					if (Name == "title") {
						// Format is: Title = <face>, <repeats x>, <repeats y>, <rotation>, <pos x>, <pos y>, <font name>, <font size>, <font color>
						list Params = llCSV2List(Value);
						if (llGetListLength(Params) == 10) {
							TitleFaces += (integer)llList2String(Params, 0);
							float RepeatX = (float)llList2String(Params, 1);
							float RepeatY = (float)llList2String(Params, 2);
							TitleRepeats += <RepeatX, RepeatY, 0.0>;
							TitleRotations += (float)llList2String(Params, 3);
							TitlePosXs += (integer)llList2String(Params, 4);
							TitlePosYs += (integer)llList2String(Params, 5);
							TitleFontNames += llList2String(Params, 6);
							TitleFontSizes += (integer)llList2String(Params, 7);
							TitleLineHeights += (integer)llList2String(Params, 8);
							TitleMaxWidths += (integer)llList2String(Params, 9);
						}
						else {
							llOwnerSay("Invalid Title entry in config file: " + Value);
						}
					}
					else if (Name == "menu") {
						// Format is: Menu = <face>, <from x>, <to x>, <from y>, <to y>
						list Params = llCSV2List(Value);
						if (llGetListLength(Params) == 5) {
							MenuFaces += (integer)llList2String(Params, 0);
							MenuRegionsStartS += (float)llList2String(Params, 1);
							MenuRegionsEndS += (float)llList2String(Params, 2);
							MenuRegionsStartT += (float)llList2String(Params, 3);
							MenuRegionsEndT += (float)llList2String(Params, 4);
						}
						else {
							llOwnerSay("Invalid Menu entry in config file: " + Value);
						}
					}
					else if (Name == "webbrowserstring") BrowserString = llToLower(Value);
					else if (Name == "titlecolor") TitleColor = Value;
					else if (Name == "colorfaces") {
						list FaceStrings = llParseStringKeepNulls(Value, [ "," ], []);
						integer P = llGetListLength(FaceStrings);
						for (; P; P--) {
							ColorFaces += (integer)llList2String(FaceStrings, P - 1);
						}
					}
					else if (Name == "covercolorlist") CoverColors += Value;
					else if (Name == "titlecolorlist") TitleColors += Value;
					else llOwnerSay("Invalid keyword in config file: '" + OName + "'");
				}
				else {
					llOwnerSay("Invalid line in config file: " + Line);
				}
			}
		}
	}
	if (llGetListLength(CoverColors) > 22) {
		llOwnerSay("Too many colors in config file? (11 maximum)");
		return FALSE;
	}
	return TRUE;
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		if (!ReadConfig()) return;
		DisplayTitle();		// Title is blank, so this will set title textures to transparent
		RtfString = llList2CSV(MenuFaces);
		CoverColor = <1.0, 1.0, 1.0>; // default cover color is white ("gray" in menu because of texture)
		DataRequested = DataReceived = FALSE;
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_LOADING_COMPLETE && !DataRequested) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, RtfString, NULL_KEY);
			llSetTimerEvent(12.0 + llFrand(6.0));	// if we still haven't got our data by this time, request again
			DataRequested = TRUE;
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			// So we're not selected, and can process the click ourselves
			list TouchData = llParseStringKeepNulls(String, [ "|" ], []);	// Parse the data into a list of the four different parts
			integer TouchFace = (integer)llList2String(TouchData, 0);
			key TouchAv = Id;
			if (Selected) {	// If we're selected, we just report the click to the ML
				llMessageLinked(LINK_ROOT, LM_TOUCH_NORMAL, llList2CSV(llGetLinkNumber() + TouchData), TouchAv);
				return;
			}
			integer WhichMenu = llListFindList(MenuFaces, [ TouchFace ]);
			if (WhichMenu > -1) {
				// They've clicked on a face with a hamburger menu, but have they clicked on the hamburger region?
				float StartS = llList2Float(MenuRegionsStartS, WhichMenu);
				float EndS = llList2Float(MenuRegionsEndS, WhichMenu);
				float StartT = llList2Float(MenuRegionsStartT, WhichMenu);
				float EndT = llList2Float(MenuRegionsEndT, WhichMenu);
				vector TouchST = (vector)llList2String(TouchData, 4);
				// if they've clicked in the hamburger region
				if (TouchST.x >= StartS && TouchST.x <= EndS && TouchST.y >= StartT && TouchST.y <= EndT) {
					AvId = TouchAv;
					ShowMenu(MENU_MAIN);
					return;
				}
			}
			// At this point, they've either clicked in a non-menu region of a menu face, or an a non-menu face
			if (!CheckUrl(TouchAv)) return;
			SendToWebBrowser();			// they clicked on a face without a menu
		}
		else if (Number == LM_EXTRA_DATA_GET) {
			llSetTimerEvent(0.0);
			DataReceived = TRUE;
			integer NeedDisplayTitle = FALSE;
			list Elements = llParseStringKeepNulls(String, [ "^" ], []);
			integer ElementsCount = llGetListLength(Elements);
			Url = llList2String(Elements, 0);
			string NewTitle = llList2String(Elements, 1);
			if (NewTitle != Title) {
				Title = NewTitle;
				NeedDisplayTitle = TRUE;
			}
			if (ElementsCount > 2) {	// if there are >2 parameters, we have colour info (otherwise we use default colours)
				string NewCoverColor = llList2String(Elements, 2);
				if (NewCoverColor != "") {
					if (NewCoverColor == (string)ZERO_VECTOR || (vector)NewCoverColor != ZERO_VECTOR) {	// if it is actually a vector, even if it's zero (black)
						CoverColor = (vector)NewCoverColor;
					}
					else {	// otherwise it's presumably the name of a color
						CoverColor = (vector)GetColorFromName(CoverColors, NewCoverColor);
					}
					SetCoverColor();
				}
				string NewTitleColor = llList2String(Elements, 3);
				if (NewTitleColor != "" && NewTitleColor != TitleColor) {
					TitleColor = NewTitleColor;
					NeedDisplayTitle = TRUE;
				}
			}
			if (NeedDisplayTitle) DisplayTitle();
		}
		else if (Number == LM_SEAT_USER) {	// someone has logged in or out of the ML
			if (String == "") {	// this is actually the seat number they're logged into, but that has no relevance to us
				LoggedAvId = NULL_KEY;		// they logged out
			}
			else {
				LoggedAvId = Id;			// logged in
			}
		}
		else if (Number == LM_PRIM_SELECTED) {
			if ((integer)String == llGetLinkNumber()) {	// if it's our link number
				Selected = TRUE;
			}
		}
		else if (Number == LM_PRIM_DESELECTED) {
			if ((integer)String == llGetLinkNumber()) {	// if it's our link number
				Selected = FALSE;
			}
		}
	}
	dataserver(key Id, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		string sCommand = llList2String(Parts, 0);
		integer Command = (integer)sCommand;
		if (Command == LM_REGION_START) {
			DisplayTitle();
		}
	}	
	timer() {
		// In case the data message(s) didn't get through (in either direction), we keep asking until they do
		if (!DataReceived) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, RtfString, NULL_KEY);
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == AvId) {
			ProcessMenu(Message);
		}
		else if (Channel == TextboxChannel && Id == AvId) {
			ProcessTextBox(Message);
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			ReadConfig();
		}
	}
}
// Bookmark v1.0.2