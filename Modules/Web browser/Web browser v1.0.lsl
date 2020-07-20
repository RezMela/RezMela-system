// Web browser v1.0

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


// v1.0 - version and name change (from "WebStickie" and "Hotlink")
// v0.17 - save bookmarks to ML; limit on number of bookmarks; overwrite previous bookmarks with same URL
// v0.16 - MOAP toolbar config option
// v0.15 - bug fixes
// v0.14 - still more streamlining
// v0.13 - streamlined loading process
// v0.12 - new method of getting data (LMs rather than PRIM_TEXT)
// v0.11 - fixed default colour issue v0.10 - add colour settings for hotlinks
// v0.9 - automatic creation/positioning of hotlink
// v0.8 - bug-fixing URL loading
// v0.7 - fix initial URL loading behaviour
// v0.6 - save URL in prim text (for ML to save in savefiles)
// v0.5 - add function to load URL via linked message
// v0.4 - trim URL string from PRIM_MEDIA_CURRENT_URL (was intermittently getting rogue LFs a beginning?)
// v0.3a, aka v0.31 - use last bookmark as default instead of first
// v0.3 - ETH link messages not being received by root because we're not linked when they're being sent
// v0.2 - Clear media from button faces in Display() (shouldn't be necessary, but seems to be)

// Use to check actual page size: http://www.websitedimensions.com/pixel/


// Automatic Object Creation (AOC) messages - for scripts to be able to create ML objects
integer AOC_CREATE = 101442800;
// AOC data
string AocBookmarkName;	// Name of bookmark object
vector AocOffset;	// AOC object is placed at this offset, a factor of this object's scale (eg if browser is x=2m, then x=0.5 here will be 1m)
rotation AocRotation;	// Rotation applied to AOC object (in addition to our rotation)
vector AocRandom;	// Additional offset (with same rules) for random placement of AOC object to avoid multiples being in exactly the same place

// ML main script LMs
integer LM_REMOTE_UNLINK = -405515;
integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_TOUCH_NORMAL	= -66168300;
integer LM_RESERVED_TOUCH_FACE = -44088510;

integer HUD_API_LOGIN = -47206000;
integer HUD_API_LOGOUT = -47206001;

string CONFIG_NOTECARD = "Web browser config";
string BOOKMARKS_NOTECARD = "Bookmarks";
integer MAX_BOOKMARKS = 20;	// Maximum number of bookmarks

integer SLI_CLICK = -120214400;        // root component reporting click
integer SLI_NOTECARD = -120214401;

integer WST_LOAD_URL = -588137200;	// Instruction to us to load given URL

key LOADING_TEXTURE = "e7e5af7a-01e0-4956-a5e2-9755c6dbe87a";

// Parallel lists
list BookmarkUrls;
list BookmarkDescs;
integer BookmarksCount;
integer IsPrev;
integer IsNext;

string Url;
string PreviousUrl;
string SearchUrl;
integer PageWidth;
integer PageHeight;
float ResizeIncrement;
integer PrimMediaControls;
integer PrimMediaPermsControl;

// Faces
integer FACE_MEDIA = 1;
integer FACE_TOOLBAR = 2;
integer FACE_GRAB_BAR = 3;

integer TOOLBAR_ELEMENTS = 7;

// Toolbar texture
string TOOLBAR_TEXTURE = "2a3828ce-0541-4d41-94d3-7edcf751679a";
vector TOOLBAR_REPEATS = <0.875, 0.25, 0.0>;
vector TOOLBAR_OFFSET_1 = <-0.0675, 0.375, 0.0>;
vector TOOLBAR_OFFSET_2 = <-0.0675, 0.125, 0.0>;
float TOOLBAR_ROTATION = PI_BY_TWO;

// Bookmarks list constants
integer LIST_WIDTH = 1024;
integer LIST_HEIGHT = 512;
integer LIST_MARGIN_VERTICAL = 36;
integer LIST_MARGIN_HORIZONTAL = 80;
integer LIST_BUTTON_WIDTH = 750;
integer LIST_BUTTON_HEIGHT = 52;
integer LIST_PER_PAGE = 7;
integer LIST_TEXT_MARGIN = 6;
string LIST_FONT_NAME = "Arial";
integer LIST_FONT_SIZE = 28;
// Colours - see https://msdn.microsoft.com/en-us/library/aa358802.aspx (or you can use #rrggbbaa)
string LIST_FORECOLOUR = "White";
string LIST_BACKCOLOUR = "DarkSlateGray";

// Page arrows
string ARROW_COLOUR = "Goldenrod";
integer ARROW_CENTREY = 256;
integer ARROW_CENTREXP = 40;
integer ARROW_CENTREXN = 874;
integer ARROW_HEIGHT = 80;
integer ARROW_WIDTH = 40;

integer RowHeight;
list PrevArrowXs = [];
list PrevArrowYs = [];
list NextArrowXs = [];
list NextArrowYs = [];
integer ListPtr;

key BrowserUser;	// the avatar interacting with this script
key AppUser;		// the avatar signed into the app

// Menu stuff
integer MenuChannel;
integer MenuListener;

integer CurrentMenu;
integer MENU_COLORS = 1;
integer MENU_COLOR_TITLE = 2;
integer MENU_COLOR_COVER = 3;

string BTN_COLOR_TITLE = "Title color";
string BTN_COLOR_COVER = "Cover color";
string BTN_CANCEL = "Cancel";
string BTN_DONE = "Done";
string BTN_BACK = "<< Back";

// Bookmark colors
string BookmarkColorTitle;
string BookmarkColorCover;
list CoverColors;	// Strings of names
list TitleColors; 	// Strings of names

integer DataRequested;
integer DataReceived;

string RtfFaces;

float CurrentSizeFactor;

Display() {
	llClearPrimMedia(FACE_MEDIA);
	llSetTexture(LOADING_TEXTURE, FACE_MEDIA);
	list PrimMediaParams =  [
		PRIM_MEDIA_AUTO_PLAY, TRUE,
		PRIM_MEDIA_AUTO_SCALE, FALSE,
		PRIM_MEDIA_AUTO_ZOOM, TRUE,
		PRIM_MEDIA_WIDTH_PIXELS, PageWidth,
		PRIM_MEDIA_HEIGHT_PIXELS, PageHeight,
		PRIM_MEDIA_CONTROLS, PrimMediaControls,
		PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_ANYONE,
		PRIM_MEDIA_PERMS_CONTROL, PrimMediaPermsControl,
		PRIM_MEDIA_CURRENT_URL, Url,
		PRIM_MEDIA_HOME_URL, Url
			];
	integer Status = llSetPrimMediaParams(FACE_MEDIA, PrimMediaParams);
	if (Status) { // STATUS_OK is not defined in OpenSim, but it's 0
		llOwnerSay("WARNING: llSetPrimMediaParams() returned status " + (string)Status);
	}
	ClearButtonsMedia();
}
LayoutCalculations() {
	RowHeight = LIST_BUTTON_HEIGHT + (LIST_TEXT_MARGIN * 2);
	// Arrow coords are: point, top, bottom
	PrevArrowXs = [
		ARROW_CENTREXP - ARROW_WIDTH / 2,
		ARROW_CENTREXP + ARROW_WIDTH / 2,
		ARROW_CENTREXP + ARROW_WIDTH / 2
			];
	PrevArrowYs = [
		ARROW_CENTREY,
		ARROW_CENTREY - ARROW_HEIGHT / 2,
		ARROW_CENTREY + ARROW_HEIGHT / 2
			];
	NextArrowXs = [
		ARROW_CENTREXN + ARROW_WIDTH / 2,
		ARROW_CENTREXN - ARROW_WIDTH / 2,
		ARROW_CENTREXN - ARROW_WIDTH / 2
			];
	NextArrowYs = [
		ARROW_CENTREY,
		ARROW_CENTREY - ARROW_HEIGHT / 2,
		ARROW_CENTREY + ARROW_HEIGHT / 2
			];
}
ShowMenu(integer Menu) {
	CurrentMenu = Menu;
	list Buttons;
	string MenuTitle;
	string MenuText;
	if (CurrentMenu == MENU_COLORS) {
		MenuTitle = "BOOKMARK COLORS";
		MenuText = "Current colors:\n\nTitle: " + BookmarkColorTitle + ", cover: " + BookmarkColorCover + "\n\nSelect option:";
		Buttons = [ BTN_COLOR_TITLE, BTN_COLOR_COVER, BTN_DONE ];
	}
	else if (CurrentMenu == MENU_COLOR_TITLE) {
		MenuText = "Select colour for book title text:";
		Buttons = ColorListButtons(TitleColors);
	}
	else if (CurrentMenu == MENU_COLOR_COVER) {
		MenuText = "Select colour for book cover:";
		Buttons = ColorListButtons(CoverColors);
	}
	SelectToolbar(2);
	MenuChannel = -30000 - (integer)llFrand(1000000);
	MenuListener = llListen(MenuChannel, "", BrowserUser, "");
	llDialog(BrowserUser, "\n" + MenuTitle + "\n\n" + MenuText, Buttons, MenuChannel);
}
// Return FALSE if cancelled at top level or processing finished
integer ProcessMenu(string Input) {
	llListenRemove(MenuListener);
	if (CurrentMenu == MENU_COLORS) {
		if (Input == BTN_DONE) {
			SelectToolbar(1);
			return FALSE;
		}
		else if (Input == BTN_COLOR_TITLE) {
			ShowMenu(MENU_COLOR_TITLE);
		}
		else if (Input == BTN_COLOR_COVER) {
			ShowMenu(MENU_COLOR_COVER);
		}
	}
	else if (CurrentMenu == MENU_COLOR_TITLE) {
		if (Input == BTN_BACK) {
			ShowMenu(MENU_COLORS);
		}
		else {
			BookmarkColorTitle = Input;
			SaveData();
			ShowMenu(MENU_COLORS);
		}
	}
	else if (CurrentMenu == MENU_COLOR_COVER) {
		if (Input == BTN_BACK) {
			ShowMenu(MENU_COLORS);
		}
		else {
			BookmarkColorCover = Input;
			SaveData();
			ShowMenu(MENU_COLORS);
		}
	}
	return TRUE;
}
list ColorListButtons(list ColorList) {
	list Buttons = [];
	integer L = llGetListLength(ColorList);
	integer P;
	for (P = 0; P < L; P++) {
		string ColorName = llList2String(ColorList, P);
		Buttons += ColorName;
	}
	Buttons += BTN_BACK;
	Buttons = llList2List(Buttons, -3, -1) + llList2List(Buttons, -6, -4)
		+ llList2List(Buttons, -9, -7) + llList2List(Buttons, -12, -10);
	return Buttons;
}
ShowBookmarks() {
	llClearPrimMedia(FACE_MEDIA);
	llSetTexture(LOADING_TEXTURE, FACE_MEDIA);
	string CommandList = "";
	CommandList = osSetFontName(CommandList, LIST_FONT_NAME);
	CommandList = osSetFontSize(CommandList, LIST_FONT_SIZE);
	integer I;
	integer LastLine = ListPtr + LIST_PER_PAGE - 1;
	integer Row;
	for(I = ListPtr; I <= LastLine && I < BookmarksCount; I++) {
		string Name = llList2String(BookmarkDescs, I);
		integer X = LIST_MARGIN_HORIZONTAL + 1;
		integer Y = LIST_MARGIN_VERTICAL + 1 + (Row * RowHeight);
		// Draw the button box
		CommandList = osSetPenColor(CommandList, LIST_BACKCOLOUR);
		CommandList = osMovePen(CommandList, X, Y);
		CommandList = osDrawFilledRectangle(CommandList, LIST_BUTTON_WIDTH, LIST_BUTTON_HEIGHT);
		// Draw the button text
		CommandList = osSetPenColor(CommandList, LIST_FORECOLOUR);
		CommandList = osMovePen(CommandList, X + LIST_TEXT_MARGIN, Y + LIST_TEXT_MARGIN);
		CommandList = osDrawText(CommandList, Name);

		Row++;
	}
	IsPrev = (ListPtr > 0);
	IsNext = (BookmarksCount > LastLine + 1);
	if (IsPrev) {
		CommandList = osSetPenColor(CommandList, ARROW_COLOUR);
		CommandList = osDrawFilledPolygon(CommandList, PrevArrowXs, PrevArrowYs);
	}
	if (IsNext) {
		CommandList = osSetPenColor(CommandList, ARROW_COLOUR);
		CommandList = osDrawFilledPolygon(CommandList, NextArrowXs, NextArrowYs);
	}
	// doing this twice seems to speed up texture download for some reason
	osSetDynamicTextureDataBlendFace("", "vector", CommandList, "width:" + (string)LIST_WIDTH + ",height:" + (string)LIST_HEIGHT, FALSE, 2, 0, 255, FACE_MEDIA);
	osSetDynamicTextureDataBlendFace("", "vector", CommandList, "width:" + (string)LIST_WIDTH + ",height:" + (string)LIST_HEIGHT, FALSE, 2, 0, 255, FACE_MEDIA);
}
integer ListClick(vector UV) {
	integer ClickX = (integer)((float)LIST_WIDTH * UV.x);
	integer ClickY = LIST_HEIGHT - (integer)((float)LIST_HEIGHT * UV.y);
	if (ClickX < LIST_MARGIN_HORIZONTAL) {
		if (IsPrev) {
			ListPtr -= LIST_PER_PAGE;
			if (ListPtr < 0) ListPtr = 0;
			ShowBookmarks();
		}
		return FALSE;
	}
	else if (ClickX > LIST_MARGIN_HORIZONTAL + LIST_BUTTON_WIDTH) {
		if (IsNext) {
			ListPtr += LIST_PER_PAGE;
			if (ListPtr > BookmarksCount - LIST_PER_PAGE) ListPtr = BookmarksCount - LIST_PER_PAGE;
			ShowBookmarks();
		}
		return FALSE;
	}
	integer ClickRow = (ClickY - LIST_MARGIN_VERTICAL) / RowHeight;
	integer Ptr = ListPtr + ClickRow;
	if (Ptr >= BookmarksCount) return FALSE;    // clicked empty area after last item
	Url = llList2String(BookmarkUrls, Ptr);
	string Desc = llList2String(BookmarkDescs, Ptr);
	//    llSay(0, Desc);
	SaveData();
	Display();
	return TRUE;
}
// Create a bookmark object
CreateBookmarkObject(key UserId, string Url, string Desc) {
	vector OurPos = llGetLocalPos();
	vector OurScale = llGetScale();
	rotation OurRot = llGetLocalRot();
	// This is the only way to multiple all the components of a pair of vectors. It's ugly.
	vector OffsetV = <AocOffset.x * OurScale.x, AocOffset.y * OurScale.y, AocOffset.z * OurScale.z> ;	// Calculate the offset according to the size of this prim
	vector RandV = <AocRandom.x * OurScale.x, AocRandom.y * OurScale.y, AocRandom.z * OurScale.z> * llFrand(1.0);	// Calculate the random addition to the offset
	vector ObjectPos = OurPos + ((OffsetV + RandV) * OurRot);	// Use those offsets to calculate the actual position
	rotation ObjectRot = OurRot * AocRotation;
	string ObjectParams = llDumpList2String([ Url, Desc, BookmarkColorCover, BookmarkColorTitle ], "^");
	llMessageLinked(LINK_SET, AOC_CREATE, llDumpList2String([ AocBookmarkName, ObjectPos, ObjectRot, ObjectParams ], "|"), UserId);
}
// Send command to menu
Menu(integer Command, string Text) {
	llMessageLinked(LINK_SET, Command, Text, NULL_KEY);
}
ParseBookmarksData(string Data) {
	BookmarkUrls = [];
	BookmarkDescs = [];
	BookmarksCount = 0;
	list Lines = llParseStringKeepNulls(Data, [ "\n" ], []);
	integer Len = llGetListLength(Lines);
	integer L;
	for (L = 0; L < Len; L++) {
		string Line = llStringTrim(llList2String(Lines, L), STRING_TRIM);
		if (Line != "") {
			list Parts = llParseStringKeepNulls(Line, [ "|" ], []);
			integer PartsCount = llGetListLength(Parts);
			if (PartsCount != 2) {
				llSay(0, "Bad bookmark format in line " + (string)(L + 1) + ": \n" + Line + "\nShould be description and URL, separated by \"|\".");
			}
			else {
				string Desc = llList2String(Parts, 0);
				string ThisUrl = llList2String(Parts, 1);
				string Error = ValidateDescription(Desc);
				if (Error == "") {
					BookmarkUrls += ThisUrl;
					BookmarkDescs += Desc;
					BookmarksCount++;
				}
				else {
					llSay(0, "Error in bookmarks line " + (string)(L + 1) + ": \n" + Line + "\n" + Error);
				}
			}
		}
	}
}
string ValidateDescription(string Desc) {
	if (llSubStringIndex(Desc, ";") > -1) {
		return "Description cannot contain \";\" character";
	}
	if (llSubStringIndex(Desc, "|") > -1) {
		return "Description cannot contain \"|\" character";
	}
	if (llStringLength(Desc) > 29) {    // arbitrary, but designed not to overflow menu
		return "Description too long";
	}
	return "";
}
SaveData() {
	string BookmarkUrls64 = llStringToBase64(llDumpList2String(BookmarkUrls, "|"));
	string BookmarkDescs64 = llStringToBase64(llDumpList2String(BookmarkDescs, "|"));
	string Data = llDumpList2String([ Url, BookmarkColorCover, BookmarkColorTitle, BookmarkUrls64, BookmarkDescs64 ], "^");
	llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_SET, Data, NULL_KEY);
	// Write data to prim text so that ML will save it in its save files
	if (Url != PreviousUrl) {
		llOwnerSay("Saved URL: " + Url);
		PreviousUrl = Url;
	}

}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	// Set config defaults
	PageWidth = 910;
	PageHeight = 512;
	string MoapToolbar = "none";
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
					if (Name == "searchurl") SearchUrl = StripQuotes(Value, Line);
					else if (Name == "pagewidth") PageWidth = (integer)Value;
					else if (Name == "pageheight") PageHeight = (integer)Value;
					else if (Name == "resize") ResizeIncrement = (float)Value;
					else if (Name == "aocbookmarkname") AocBookmarkName = StripQuotes(Value, Line);
					else if (Name == "aocoffset") AocOffset = (vector)Value;
					else if (Name == "aocrotation") AocRotation = llEuler2Rot((vector)Value * DEG_TO_RAD);
					else if (Name == "aocrandom") AocRandom = (vector)Value;
					else if (Name == "covercolorlist") CoverColors += Value;
					else if (Name == "titlecolorlist") TitleColors += Value;
					else if (Name == "moaptoolbar") MoapToolbar = StripQuotes(llToLower(Value), Line);
					else llOwnerSay("Invalid keyword in config file: '" + OName + "'");
				}
				else {
					llOwnerSay("Invalid line in config file: " + Line);
				}
			}
		}
		PrimMediaPermsControl = PRIM_MEDIA_PERM_ANYONE;
		PrimMediaControls = PRIM_MEDIA_CONTROLS_MINI;
		if (MoapToolbar == "none") {
			PrimMediaPermsControl = PRIM_MEDIA_PERM_NONE;
		}
		else if (MoapToolbar == "mini") {
			PrimMediaControls = PRIM_MEDIA_CONTROLS_MINI;
		}
		else if (MoapToolbar == "standard") {
			PrimMediaControls = PRIM_MEDIA_CONTROLS_STANDARD;
		}
		else {
			llOwnerSay("MOAPToolbar must be \"none\", \"mini\" or \"standard\"!");
			return FALSE;
		}
	}
	return TRUE;
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
AskDescription() {
	llTextBox(BrowserUser, "\n\nEnter description for bookmark (or blank to cancel)", MenuChannel);
}
AskUrl() {
	llTextBox(BrowserUser, "\n\nEnter URL (or blank to cancel)", MenuChannel);
}
SelectToolbar(integer Which) {
	vector Offset = TOOLBAR_OFFSET_1;
	if (Which == 2) Offset = TOOLBAR_OFFSET_2;
	llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEXTURE, FACE_TOOLBAR, TOOLBAR_TEXTURE, TOOLBAR_REPEATS, Offset, TOOLBAR_ROTATION ]);
}
Resize(float SizeFactor) {
	vector Size = llList2Vector(llGetLinkPrimitiveParams(LINK_THIS, [ PRIM_SIZE ]), 0);
	Size.x *= SizeFactor;
	Size.y *= SizeFactor;
	// Z is unchanged
	llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_SIZE, Size ]);
}
ClearButtonsMedia() {
	llClearPrimMedia(FACE_TOOLBAR);
	llClearPrimMedia(FACE_GRAB_BAR);
}
Login(key Id) {
	AppUser = Id;
}
Logout() {
	AppUser = NULL_KEY;
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llClearPrimMedia(ALL_SIDES);
		llSetTexture(TEXTURE_BLANK, FACE_MEDIA);
		llSetRemoteScriptAccessPin(8000);    // in case we need it
		CurrentSizeFactor = 1.0;
		if (!ReadConfig()) return;
		ParseBookmarksData(osGetNotecard(BOOKMARKS_NOTECARD));
		LayoutCalculations();
		ClearButtonsMedia();
		BookmarkColorCover = "Gray";
		BookmarkColorTitle = "Black";
		BrowserUser = NULL_KEY;
		AppUser = NULL_KEY;
		state Normal;
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		SelectToolbar(1);
		RtfFaces = llList2CSV([ FACE_TOOLBAR, FACE_MEDIA ]);
		DataRequested = DataReceived = FALSE;
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_LOADING_COMPLETE && !DataRequested) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, RtfFaces, NULL_KEY);
			llSetTimerEvent(12.0 + llFrand(6.0));
			DataRequested = TRUE;
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			list TouchData = llParseStringKeepNulls(String, [ "|" ], []);	// Parse the data into a list of the four different parts
			integer TouchFace = (integer)llList2String(TouchData, 0);
			vector TouchST = (vector)llList2String(TouchData, 4);
			BrowserUser = Id;
			if (TouchFace == FACE_GRAB_BAR) {
				// Pass touch back to the ML main script for deselection if appropriate
				llMessageLinked(LINK_ROOT, LM_TOUCH_NORMAL, llList2CSV(llGetLinkNumber() + TouchData), Id);
			}
			else if (TouchFace == FACE_TOOLBAR) {
				integer Which = llFloor(TouchST.y * (float)TOOLBAR_ELEMENTS);
				if (Which == 0) {
					Resize(1.0 + ResizeIncrement);
				}
				else if (Which == 1) {
					Resize(1.0 - ResizeIncrement);
				}
				else if (Which == 2) {
					state Bookmarks;
				}
				else if (Which == 3) {
					state Navigate;
				}
				else if (Which == 4) {
					Url = SearchUrl;
					SaveData();
					Display();
				}
				else if (Which == 5) {
					if (Id != AppUser) {
						llDialog(Id, "\n\nYou must be signed in to the App to create bookmarks.", [ "OK" ], -9999999);
						return;
					}
					state AddBookmark;
				}
				else if (Which == 6) {    // Colors
					state Menu;			// Currently only for setting bookmark colours, but can be extended for further menu-based activity
				}
				return;
			}
		}
		else if (Number == LM_EXTRA_DATA_GET) {
			// We can stop the timer because we have our data, and we also must have sent ETH_LOCK (because the timer has kicked
			// in at least once).
			llSetTimerEvent(0.0);
			AppUser = Id;
			integer NeedToWriteBookmarks = FALSE;
			DataReceived = TRUE;	// we don't really need this because we can just stop the timer, but I'm leaving it in case we use the timer for something else later
			if (String == "") {	// No data from ML
				Url = llList2String(BookmarkUrls, 0);	// Use first entry in bookmarks as default URL for new instances
			}
			else {	// ML sent us data
				list Parts = llParseStringKeepNulls(String, [ "^" ], []);
				Url = llList2String(Parts, 0);
				if (llGetListLength(Parts) > 1) {	// Allow for older versions (made with pre v0.10 script) which wouldn't have this data saved
					string NewBookmarkColorCover = llList2String(Parts, 1);
					string NewBookmarkColorTitle = llList2String(Parts, 2);
					if (NewBookmarkColorCover != "") BookmarkColorCover = NewBookmarkColorCover;
					if (NewBookmarkColorTitle != "") BookmarkColorTitle = NewBookmarkColorTitle;
					string BookmarkUrls64 = llBase64ToString(llList2String(Parts, 3));
					string BookmarkDescs64 = llBase64ToString(llList2String(Parts, 4));
					if (BookmarkUrls64 != "") {
						BookmarkUrls = llParseStringKeepNulls(BookmarkUrls64, [ "|" ], []);
						BookmarkDescs = llParseStringKeepNulls(BookmarkDescs64, [ "|" ], []);
						BookmarksCount = llGetListLength(BookmarkUrls);
						NeedToWriteBookmarks = TRUE;
					}

				}
			}
			PreviousUrl = Url;	// No need to save
			Display();
			if (NeedToWriteBookmarks) state WriteBookmarks;
		}
		else if (Number == HUD_API_LOGIN) {
			Login(Id);
		}
		else if (Number == HUD_API_LOGOUT) {
			Logout();
		}
		else if (Number == WST_LOAD_URL) {
			Url = String;
			PreviousUrl = Url;
			SaveData();
			Display();
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) {
			llResetScript();
		}
	}
	timer() {
		if (!DataReceived) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, RtfFaces, NULL_KEY);
		}
	}
}
state Bookmarks {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		SelectToolbar(2);
		ListPtr = 0;
		ShowBookmarks();
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_RESERVED_TOUCH_FACE) {
			if (Id != BrowserUser) return;    // ignore if not same user
			// The ML is telling us that someone clicked our reserved face. The string portion of the message contains a pipe-delimited
			// list of the following data: face, position, normal, binormal, ST, UV
			list TouchData = llParseStringKeepNulls(String, [ "|" ], []);	// Parse the data into a list of the four different parts
			integer TouchFace = (integer)llList2String(TouchData, 0);
			// Pass touch back to the ML main script for deselection if appropriate
			llMessageLinked(LINK_ROOT, LM_TOUCH_NORMAL, llList2CSV(llGetLinkNumber() + TouchData), Id);
			vector TouchUV = (vector)llList2String(TouchData, 5);
			if (TouchFace == FACE_MEDIA) {
				if (ListClick(TouchUV)) state Normal;
			}
			else if (TouchFace == FACE_TOOLBAR) {
				SaveData();
				Display();
				state Normal;
			}
			// At this point, they've clicked in a unused part, so we need to pass that back to the ML main script
			llMessageLinked(LINK_ROOT, LM_TOUCH_NORMAL, llList2CSV(llGetLinkNumber() + TouchData), Id);
		}
		else if (Number == HUD_API_LOGIN) {
			Login(Id);
		}
		else if (Number == HUD_API_LOGOUT) {
			Logout();
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) {
			llResetScript();
		}
	}
}
state AddBookmark {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		if (BookmarksCount >= MAX_BOOKMARKS) {
			llDialog(BrowserUser, "\n\nMaximum bookmarks (" + (string)MAX_BOOKMARKS + ") reached.", [ "OK" ], -9999999);
			state Normal;
		}
		SelectToolbar(2);
		MenuChannel = -30000 - (integer)llFrand(1000000);
		llListen(MenuChannel, "", BrowserUser, "");
		AskDescription();
		llSetTimerEvent(5.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == BrowserUser) {
			string Desc = llStringTrim(Message, STRING_TRIM);
			if (Desc == "") {
				state CancelAddBookmark;
			}
			string NewUrl = llList2String(llGetPrimMediaParams(FACE_MEDIA, [ PRIM_MEDIA_CURRENT_URL ]), 0);
			NewUrl = llStringTrim(NewUrl, STRING_TRIM);
			string AdditionalText = "";
			// If the URL has already been bookmarked, delete that bookmark
			integer Ptr = llListFindList(BookmarkUrls, [ NewUrl ]);
			if (Ptr > -1) {
				BookmarkUrls = llDeleteSubList(BookmarkUrls, Ptr, Ptr);
				BookmarkDescs = llDeleteSubList(BookmarkDescs, Ptr, Ptr);
				BookmarksCount--;
				AdditionalText = "\n\nThis overwrote an older bookmark for the same URL.";
			}
			BookmarkUrls += NewUrl;
			BookmarkDescs += Desc;
			BookmarksCount++;
			llDialog(BrowserUser, "\n\nBookmark created." + AdditionalText, [ "OK" ], -9999999);
			CreateBookmarkObject(BrowserUser, NewUrl, Desc);
			state WriteBookmarks;
		}
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_RESERVED_TOUCH_FACE) {
			if (Id != BrowserUser) return;    // ignore if not same user
			// The ML is telling us that someone clicked our reserved face. The string portion of the message contains a pipe-delimited
			// list of the following data: face, position, normal, binormal, ST, UV
			list TouchData = llParseStringKeepNulls(String, [ "|" ], []);	// Parse the data into a list of the four different parts
			integer TouchFace = (integer)llList2String(TouchData, 0);
			// Pass touch back to the ML main script for deselection if appropriate
			llMessageLinked(LINK_ROOT, LM_TOUCH_NORMAL, llList2CSV(llGetLinkNumber() + TouchData), Id);
			if (TouchFace == FACE_TOOLBAR) {
				SaveData();
				Display();
				state Normal;
			}
		}
		else if (Number == HUD_API_LOGIN) {
			Login(Id);
		}
		else if (Number == HUD_API_LOGOUT) {
			Logout();
			state CancelAddBookmark;
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) {
			llResetScript();
		}
	}
	timer() {
		if (llGetAgentSize(BrowserUser) == ZERO_VECTOR) state Normal;    // if they've left, return to normal state
	}
}
state CancelAddBookmark {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llDialog(BrowserUser, "\n\nBookmark creation canceled.", [ "OK" ], -9999999);
		state Normal;
	}
}
state Navigate {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		SelectToolbar(2);
		MenuChannel = -30000 - (integer)llFrand(1000000);
		llListen(MenuChannel, "", BrowserUser, "");
		AskUrl();
		llSetTimerEvent(5.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == BrowserUser) {
			string Desc = llStringTrim(Message, STRING_TRIM);
			if (Desc == "") {
				llDialog(BrowserUser, "\n\nNavigation canceled.", [ "OK" ], -9999999);
				state Normal;
			}
			Url = Message;
			SaveData();
			Display();
			state Normal;
		}
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_RESERVED_TOUCH_FACE) {
			if (Id != BrowserUser) return;    // ignore if not same user
			list TouchData = llParseStringKeepNulls(String, [ "|" ], []);	// Parse the data into a list of the four different parts
			integer TouchFace = (integer)llList2String(TouchData, 0);
			// Pass touch back to the ML main script for deselection if appropriate
			llMessageLinked(LINK_ROOT, LM_TOUCH_NORMAL, llList2CSV(llGetLinkNumber() + TouchData), Id);
			if (TouchFace == FACE_TOOLBAR) {
				SaveData();
				Display();
				state Normal;
			}
		}
		else if (Number == HUD_API_LOGIN) {
			Login(Id);
		}
		else if (Number == HUD_API_LOGOUT) {
			Logout();
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) {
			llResetScript();
		}
	}
	timer() {
		if (llGetAgentSize(BrowserUser) == ZERO_VECTOR) state Normal;    // if they've left, return to normal state
	}
}
// Might seem to be an overkill to have a state dedicated to this, but at the time of writing we're not sure why
// re-writing notecards sometimes doesn't work, and I thought I'd try having the deletion and rewriting in separate
// events (ie sim frames). JH (This seems to be the correct approach - JH, later)
state WriteBookmarks {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llRemoveInventory(BOOKMARKS_NOTECARD);
		llSetTimerEvent(0.5);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == HUD_API_LOGIN) {
			Login(Id);
		}
		else if (Number == HUD_API_LOGOUT) {
			Logout();
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		list Lines = [];
		integer I;
		for (I = 0; I < BookmarksCount; I++) {
			Lines += llList2String(BookmarkDescs, I) + "|" + llList2String(BookmarkUrls, I);
		}
		osMakeNotecard(BOOKMARKS_NOTECARD, Lines);
		ParseBookmarksData(osGetNotecard(BOOKMARKS_NOTECARD));    // re-read just in case
		state Normal;
	}
}
// Currently only for setting bookmark colours, but can be extended for further menu-based activity
// This has a lot in common with other states (Navigate, Bookmark), so perhaps these should be incorporated
// here. ShowMenu() and ProcessMenu() can be enhanced to included llTextBox() for those. JFH
state Menu {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		ShowMenu(MENU_COLORS);
		llSetTimerEvent(5.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == BrowserUser) {
			if (!ProcessMenu(Message)) state Normal;	// Return to normal state if cancelled at top level
		}
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_RESERVED_TOUCH_FACE) {
			if (Id != BrowserUser) return;    // ignore if not same user
			list TouchData = llParseStringKeepNulls(String, [ "|" ], []);	// Parse the data into a list of the four different parts
			integer TouchFace = (integer)llList2String(TouchData, 0);
			// Pass touch back to the ML main script for deselection if appropriate
			llMessageLinked(LINK_ROOT, LM_TOUCH_NORMAL, llList2CSV(llGetLinkNumber() + TouchData), Id);
			if (TouchFace == FACE_TOOLBAR) {
				SaveData();
				Display();
				state Normal;
			}
		}
		else if (Number == HUD_API_LOGIN) {
			Login(Id);
		}
		else if (Number == HUD_API_LOGOUT) {
			Logout();
		}

	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) {
			llResetScript();
		}
	}
	timer() {
		if (llGetAgentSize(BrowserUser) == ZERO_VECTOR) state Normal;    // if they've left, return to normal state
	}
}
state Die {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		// I don't remember why we don't die immediately, but there must be some good reason because
		// we (very deliberately) don't in the general ML child script.
		llSetTimerEvent(0.5);
	}
	timer() {
		llDie();
	}
}
// Web browser v1.0