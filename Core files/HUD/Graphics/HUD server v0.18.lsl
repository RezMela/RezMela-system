// RezMela HUD server v0.18

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

// v0.18 - add floating text warning color
// v0.17 - hang when unlinked
// v0.16 - jump mode processing
// v0.15 - reduce heading font size if necessary
// v0.14 - camera mode processing
// v0.13 - add camera pos and rot data to click event; added status line processing
// v0.12 - incorrect version checking
// v0.11 - add API for closing HUD
// v0.10 - add API message for reporting current window
// v0.9 - new ImageText window type, + many more changes & more bug fixes
// v0.8 - bug fix
// v0.7 - changes to login comms
// v0.6 - Less severe integrity checking
// v0.5 - Better login handshaking
// v0.4 - Bug fixes
// v0.3 - Breadcrumbs, configurable physical size

// Current palette
// #EDFAFD - Glass
// #AED9DA - Chill
// #3DDAD7 - Californian coral
// #2A93D5 - Bondi blue
// #135589 - Marina

string HUD_MIN_VERSION = "0.22";
integer DebugMode = FALSE;

// API linked messages (for comms between this script and applications
integer HUD_API_MAX = -4720600;	// Minimum value in this set (but negative)
integer HUD_API_LOGIN = -47206000;
integer HUD_API_LOGOUT = -47206001;
integer HUD_API_GET_METADATA = -47206002;
integer HUD_API_SET_METADATA = -47206003;
integer HUD_API_CREATE_WINDOW_BUTTONS = -47206004;
integer HUD_API_CREATE_WINDOW_LIST = -47206005;
integer HUD_API_CREATE_WINDOW_CUSTOM = -47206006;
integer HUD_API_CREATE_WINDOW_STATUS = -47206007;
integer HUD_API_CREATE_WINDOW_ALERT  = -47206008;
integer HUD_API_CREATE_WINDOW_IMAGETEXT  = -47206009;
integer HUD_API_DISPLAY_WINDOW = -47206020;
integer HUD_API_CLICK_BUTTON = -47206021;
integer HUD_API_CLICK_LIST = -47206022;
integer HUD_API_READY = -47206023;
integer HUD_API_BACK_BUTTON = -47206024;
integer HUD_API_DESTROY_WINDOW = -47206025;
integer HUD_API_TAKE_CONTROL = -47206030;
integer HUD_API_TRACK_CAMERA = -47206031;
integer HUD_API_CURRENT_WINDOW = -47206040;
integer HUD_API_STATUS_LINE = -47206050;
integer HUD_API_CAMERA_JUMP_MODE = -47206051;
integer HUD_API_MIN = -47206099;	// Maximum value in this set (but negative)

string HUD_API_SEPARATOR_1 = "|";
string HUD_API_SEPARATOR_2 = "^";
string MESSAGE_SEPARATOR = "|";
string MESSAGE_SEPARATOR_2 = "^";

string PRIM_DRAWING_DELIMITER = "^";			// delimiter character for prim-drawing commands

// Codes for messages to attachment script
string HUD_MESSAGE_HELLO = "h";
string HUD_MESSAGE_ACTIVATE = "a";
string HUD_MESSAGE_CREATE_PAGE = "s";
string HUD_MESSAGE_DELETE_PAGE = "e";
string HUD_MESSAGE_DISPLAY_PAGE = "i";
string HUD_MESSAGE_DEACTIVATE = "d";
string HUD_MESSAGE_VERSIONFAIL = "v";
string HUD_MESSAGE_READY = "o";
string HUD_MESSAGE_TITLE = "t";
string HUD_MESSAGE_CLICK = "c";
string HUD_MESSAGE_PRIM_PARAMS = "p";
string HUD_MESSAGE_TAKE_CONTROL = "n";
string HUD_MESSAGE_TRACK_CAMERA = "m";
string HUD_MESSAGE_FLOATING_TEXT = "f";
string HUD_MESSAGE_CAMERA_JUMP_MODE = "C";

// Table of windows, with pointers to Pages table
list Windows = [];
integer WIN_NAME = 0;
integer WIN_NUMBER = 1;	// Held -ve
integer WIN_HEADING = 2;
integer WIN_BACKBUTTON = 3;
integer WIN_PARENT = 4;
integer WIN_TYPE = 5;
integer WIN_DATA = 6;
integer WIN_STRIDE = 7;

// Reserved names for windows
string WINDOW_NAME_MAIN = "main";
string WINDOW_NAME_DELETED = "*** Deleted window";

// Constants for WINDOW_TYPE
integer WINDOW_TYPE_NONE = 0;
integer WINDOW_TYPE_BUTTON = 1;
integer WINDOW_TYPE_LIST_PLAIN = 2;
integer WINDOW_TYPE_LIST_THUMBS = 3;
integer WINDOW_TYPE_MESSAGE = 4;
integer WINDOW_TYPE_ALERT = 5;
integer WINDOW_TYPE_CUSTOM = 6;
integer WINDOW_TYPE_IMAGETEXT = 7;

// Table of pages
list Pages = [];
integer PAGE_WINDOW = 0;	// pointer to windows table
integer PAGE_INDEX = 1;		// unique number for each page (held -ve)
integer PAGE_STRIDE = 2;

// Table of thumbnails
list Images;	//
integer IMG_PAGE_INDEX = 0;
integer IMG_UUID = 1;
integer IMG_TAG = 2;
integer IMG_STRIDE = 3;

// Table of clickable areas in current page
list Areas = [];
integer AREA_TYPE = 0;
integer AREA_PAGE_INDEX = 1;	// stored -ve
integer AREA_START_X = 2;
integer AREA_START_Y = 3;
integer AREA_END_X = 4;
integer AREA_END_Y = 5;
integer AREA_DATA = 6;
integer AREA_STRIDE = 7;

integer AREA_TYPE_TAG = 1;
integer AREA_TYPE_NAVIGATE = 2;

// Areas of prev and next page regions
integer PrevAreaY1;
integer PrevAreaY2;
integer NextAreaY1;
integer NextAreaY2;

integer NextWindowNumber;
integer NextPageIndex;

integer CurrentWindowNumber;	// Window numvber (as stored in table)
integer CurrentBackButton;	// does current page have a back button?
integer CurrentWindowType;
integer CurrentPageIndex;

string UuidLogo;		// UUIDs of textures on HUD root
string UuidMinMax;

integer StatusType;
integer ST_IDLE = 0;
integer ST_ACTIVATE = 1;
integer ST_LOGGING_IN = 2;
integer ST_RUNNING = 3;

integer IsClientReady;
integer IsHudReady;

string CONFIG_NOTECARD = "HUD config";

list HUDAttachPoints = [
	ATTACH_HUD_BOTTOM,
	ATTACH_HUD_BOTTOM_LEFT,
	ATTACH_HUD_BOTTOM_RIGHT,
	ATTACH_HUD_CENTER_1,
	ATTACH_HUD_CENTER_2,
	ATTACH_HUD_TOP_CENTER,
	ATTACH_HUD_TOP_LEFT,
	ATTACH_HUD_TOP_RIGHT ];

integer HUD_CHAT_GENERAL = -24473302;	// chat channel for general talk in region

key AvId;
key HudId;
key MyUuid;
integer MyLinkNum;

string ApplicationName;

integer TimerFrequency;
integer DoIntegrityCheck;

// Layout attributes
// Page - related to overall page
integer PageTextureSize;
integer PageWidth;
integer PageHeight;
string PageColor;
integer PageMiddleX;
// Heading - page heading
integer HeadingMarginX;
integer HeadingMarginY;
string HeadingFontName;
integer HeadingFontSize;
string HeadingColor;
// Back button - Unicode arrow for going back
integer BackButtonX;
integer BackButtonY;
string BackButtonFontName;
integer BackButtonFontSize;
string BackButtonColor;
string BackButtonChar;
// Breadcrumb - navigation trail
integer BreadMarginX;
integer BreadMarginY;
integer BreadGap;
string BreadFontName;
integer BreadFontSize;
string BreadColor;
string BreadSepChar;
// Button - buttons
integer ButtonSizeX;
integer ButtonSizeY;
integer ButtonMarginX;
integer ButtonMarginY;
integer ButtonGapX;
integer ButtonGapY;
string ButtonColor;
integer ButtonTextMarginX;
integer ButtonTextMarginY;
string ButtonTextFontName;
integer ButtonTextFontSize;
string ButtonTextColor;
// Lists
integer ListMarginX;
integer ListMarginY;
integer ListSizeY;
integer ListThumbSize;
integer ListGapY;
integer ListPrevNextSizeY;
integer ListPrevNextArrowX;
integer ListPrevNextArrowY;
string ListPrevNextBarColor;
string ListPrevNextArrowColor;
integer ListPrevMarginY;
integer ListNextMarginY;
list ListPrevCommands;
list ListNextCommands;
integer ListPrevNextWidth;
integer ListTextMarginX;
integer ListTextMarginY;
string ListTextFontName;
integer ListTextFontSize;
string ListTextColor;
integer ListBottomMargin;
// Status
integer StatusCenterY;
integer StatusMarginX;
integer StatusTextMaxHeight;
string StatusTextFontName;
integer StatusTextFontSize;
float StatusLineSpacing;
string StatusTextColor;
// Alert
integer AlertMarginX;
integer AlertTextCenterY;
integer AlertTextMaxHeight;
string AlertTextFontName;
integer AlertTextFontSize;
float AlertLineSpacing;
string AlertTextColor;
integer AlertButtonY;
integer AlertButtonSizeX;
integer AlertButtonSizeY;
integer AlertButtonGap;
integer AlertButtonTextMarginX;
string AlertButtonColorPrimary;
string AlertButtonColorSecondary;
string AlertButtonTextFontName;
integer AlertButtonTextFontSize;
string AlertButtonTextColor;
// Custom
string CustomTextFontName;
integer CustomTextFontSize;
string CustomTextColor;
// ImageText
integer ImageTextImageMarginX;
integer ImageTextImageMarginY;
integer ImageTextTextMarginX;
integer ImageTextTextCenterY;
integer ImageTextTextMaxHeight;
float ImageTextLineSpacing;
string ImageTextFontName;
integer ImageTextFontSize;
string ImageTextColor;
// Title bar
integer TitleCanvasSize;
string TitleForeColor;
string TitleBackColor;
string TitleFontName;
integer TitleFontSize;
integer TitleLeftMargin;
integer TitleTopMargin;
// Status line (called "float" line internally, "bottom line" in config).
// "Status" was already being used be the status type page
string FloatBackColor;
float FloatBackHeight;
string FloatTextColorNormal;
string FloatTextColorWarn;
float FloatTextPos;
// Splash prim
string SplashPrimTexture;
// Camera zoom factor (for automatic alternate camera position)
float CameraZoomFactor;

vector RootPrimSize;
vector PagePrimSize;

float PagePrimTopPos;
float PagePrimLeftPos;
vector ThumbScale;
vector ThumbFirstPos;
float Thumbgap;
vector ImageTextImageScale;	// the size of the image in an ImageText window
vector ImageTextImagePos;	// and its position

float PixelsPerMetre;

integer GotMetaData;

integer HandleHudMessage(key Id, string Data) {
	Debug("Rec'd from HUD: " + Data);
	list Parts = ParseMessage(Data);
	string Command = llList2String(Parts, 0);
	list Params = llList2List(Parts, 1, -1);
	if (Command == HUD_MESSAGE_CLICK) {
		integer NumberOfParams = llGetListLength(Params);
		if (NumberOfParams == 4) {	// 4 params means click by X,Y
			float X = (float)llList2String(Params, 0);
			float Y = (float)llList2String(Params, 1);
			vector CameraPos = (vector)llList2String(Params, 2);
			rotation CameraRot = (rotation)llList2String(Params, 3);
			HandleClickXY(X, Y, CameraPos, CameraRot);
		}
		else if (NumberOfParams == 3) {	// 3 params means click by tag
			string Tag = llList2String(Params, 0);
			// Commented out because not currently used, although the data is there
			//			vector CameraPos = (vector)llList2String(Params, 1);
			//			rotation CameraRot (rotation)llList2String(Params, 2);
			HandleClickThumb(Tag);
		}
	}
	else if (Command == HUD_MESSAGE_READY) {
		// we've got a "ready" message from the HUD, and we're ready, so we send a "ready" message to the client application
		IsHudReady = TRUE;
		if (IsClientReady) {
			SendApiMessage(HUD_API_READY, [], AvId);
			StatusType = ST_RUNNING;
		}
		ShowStatus();
	}
	else if (Command == HUD_MESSAGE_DEACTIVATE) {	// we've been told by the HUD to terminate the session
		HudId = NULL_KEY;	// prevent DisconnectUser() from trying to shut down the HUD
		DisconnectUser();
		return FALSE;
	}
	else if (Command == HUD_MESSAGE_CAMERA_JUMP_MODE) {
		string CameraJumpMode = llList2String(Params, 0);
		llMessageLinked(LINK_ROOT, HUD_API_CAMERA_JUMP_MODE, CameraJumpMode, AvId);
	}
	else if (Command == HUD_MESSAGE_TAKE_CONTROL) {		// they've pressed a key that we're controlling
		SendApiMessage(HUD_API_TAKE_CONTROL, Params, Id);
	}
	return TRUE;
}
// Handle click on current page via coordinates
HandleClickXY(float RawX, float RawY, vector CameraPos, rotation CameraRot) {
	// Convert fractions to pixels
	integer ClickX = (integer)(RawX * (float)PageWidth);
	integer ClickY = (integer)((1.0 - RawY) * (float)PageHeight);
	// If there's a back button, did they click that?
	integer BackButtonXEnd = BackButtonX + TextWidth(BackButtonChar, BackButtonFontName, BackButtonFontSize);
	integer BackButtonYEnd = BackButtonY + TextHeight(BackButtonChar, BackButtonFontName, BackButtonFontSize);
	if (CurrentBackButton) {
		if (ClickX >= BackButtonX && ClickX <= BackButtonXEnd &&
			ClickY >= BackButtonY && ClickY <= BackButtonYEnd) {
				// So they've clicked on a back button.
				// First we see if the current window has a parent and if so, navigate there automatically
				integer WinPtr = llListFindList(Windows, [ -CurrentWindowNumber ]);	// find on window number (held -ve)
				WinPtr -= WIN_NUMBER;	// position at beginning of stride
				string ParentName = DecodeParent(llList2String(Windows, WinPtr + WIN_PARENT));
				if (ParentName != "") {	// If the current window has a parent
					DisplayWindow(ParentName);	// Navigate to the parent
				}
				else {	// Current window has no parent, so pass the back-button event back to the API
					SendApiMessage(HUD_API_BACK_BUTTON, [ CurrentWindowName() ], AvId);
				}
				return;
			}
	}
	if (CurrentWindowType == WINDOW_TYPE_LIST_PLAIN || CurrentWindowType == WINDOW_TYPE_LIST_THUMBS) {
		if (ClickY >= PrevAreaY1 && ClickY <= PrevAreaY2) {
			integer PrevPage = GetPrevPage(CurrentWindowNumber, CurrentPageIndex);
			if (PrevPage > -1) {
				DisplayPage(PrevPage);
				return;
			}
		}
		else if (ClickY >= NextAreaY1 && ClickY <= NextAreaY2) {
			integer NextPage = GetNextPage(CurrentWindowNumber, CurrentPageIndex);
			if (NextPage > -1) {
				DisplayPage(NextPage);
				return;
			}
		}
	}
	// Find which area occupies those pixels
	integer Len = llGetListLength(Areas);
	integer A = llListFindList(Areas, [ -CurrentPageIndex ]);	// position at start of current page's areas
	if (A > -1) {
		A -= AREA_PAGE_INDEX;
		for (; A < Len && llList2Integer(Areas, A + AREA_PAGE_INDEX) == -CurrentPageIndex; A += AREA_STRIDE) { // while we're in this page's block
			integer StartX = llList2Integer(Areas, A + AREA_START_X);
			integer StartY = llList2Integer(Areas, A + AREA_START_Y);
			integer EndX = llList2Integer(Areas, A + AREA_END_X);
			integer EndY = llList2Integer(Areas, A + AREA_END_Y);
			if (ClickX >= StartX && ClickX <= EndX && ClickY >= StartY && ClickY <= EndY) {
				integer AreaType = llList2Integer(Areas, A + AREA_TYPE);
				if (AreaType == AREA_TYPE_TAG) {
					string Tag = llList2String(Areas, A + AREA_DATA);
					SendApiMessage(HUD_API_CLICK_BUTTON, [ CurrentWindowName(), Tag, CameraPos, CameraRot ], AvId);
				}
				else if (AreaType == AREA_TYPE_NAVIGATE) {
					string WindowName = llList2String(Areas, A + AREA_DATA);
					DisplayWindow(WindowName);
				}
				return;
			}
		}
	}
}
HandleClickThumb(string Tag) {
	SendApiMessage(HUD_API_CLICK_BUTTON, [ CurrentWindowName(), Tag ], AvId);
}
// Send a message to the application layer
SendApiMessage(integer Command, list Data, key Id) {
	string DataString = llDumpList2String(Data, MESSAGE_SEPARATOR);
	Debug("Send API: " + (string)Command + "/" + DataString);
	llMessageLinked(LINK_SET, Command, DataString, Id);
}
// Receive a message from the application layer. Returns false if errors
HandleApiMessage(integer Command, string Data, key Id, integer Activated) {
	Debug("Rec'd from API: " + (string)Command + " " + llGetSubString(Data, 0, 30));
	list Parts = llParseStringKeepNulls(Data, [ HUD_API_SEPARATOR_1 ], []);
	if (Command == HUD_API_SET_METADATA) {
		ApplicationName = llList2String(Parts, 0);
		MessageHud(HUD_MESSAGE_TITLE, [ ApplicationName ]);
		GotMetaData = TRUE;
	}
	else if (Command == HUD_API_READY) {
		if (IsHudReady) {
			StatusType = ST_RUNNING;
			SendApiMessage(HUD_API_READY, [], AvId);
		}
		ShowStatus();
	}
	else if (Activated) {
		if (Command == HUD_API_CREATE_WINDOW_BUTTONS) {
			CreateWindowButtons(Parts);
		}
		else if (Command == HUD_API_CREATE_WINDOW_LIST) {
			CreateWindowList(Parts);
		}
		else if (Command == HUD_API_CREATE_WINDOW_STATUS) {
			CreateWindowStatus(Parts);
		}
		else if (Command == HUD_API_CREATE_WINDOW_ALERT) {
			CreateWindowAlert(Parts);
		}
		else if (Command == HUD_API_CREATE_WINDOW_CUSTOM) {
			CreateWindowCustom(Parts);
		}
		else if (Command == HUD_API_CREATE_WINDOW_IMAGETEXT) {
			CreateWindowImageText(Parts);
		}
		else if (Command == HUD_API_DISPLAY_WINDOW) {
			string WindowName = llList2String(Parts, 0);
			DisplayWindow(WindowName);
		}
		else if (Command == HUD_API_DESTROY_WINDOW) {
			string WindowName = llList2String(Parts, 0);
			DestroyWindow(WindowName);
		}
		else if (Command == HUD_API_TAKE_CONTROL) {
			MessageHud(HUD_MESSAGE_TAKE_CONTROL, [ llDumpList2String(Parts, "|") ]);
		}
		else if (Command == HUD_API_TRACK_CAMERA) {
			MessageHud(HUD_MESSAGE_TRACK_CAMERA, [ llList2String(Parts, 0)	 ]);
		}
		else if (Command == HUD_API_STATUS_LINE) {
			MessageHud(HUD_MESSAGE_FLOATING_TEXT, [ llList2String(Parts, 0)	 ]);
		}		
		else if (Command == HUD_API_LOGOUT) {
			DisconnectUser();
			ShowStatus();
			state Idle;
		}
	}
}
CreateWindowButtons(list Parts) {
	string WindowName = llList2String(Parts, 0);
	string Parent = llList2String(Parts, 1);
	string WindowHeading = llList2String(Parts, 2);
	integer BackButton = (integer)llList2String(Parts, 3);
	string ButtonString = llList2String(Parts, 4);
	integer WindowNumber = CreateWindow(WindowName, Parent, WindowHeading, BackButton, WINDOW_TYPE_BUTTON);	// Create the window
	integer PageIndex = GetNextPageIndex();
	CreatePage(PageIndex, WindowNumber, MakeButtons(WindowNumber, llParseStringKeepNulls(ButtonString, [ HUD_API_SEPARATOR_2 ], [] ), PageIndex));
}
CreateWindowList(list Parts) {
	string WindowName = llList2String(Parts, 0);
	string Parent = llList2String(Parts, 1);
	string WindowHeading = llList2String(Parts, 2);
	integer BackButton = (integer)llList2String(Parts, 3);
	integer Thumbs = (integer)llList2String(Parts, 4);
	string ListString = llList2String(Parts, 5);
	integer WindowType = WINDOW_TYPE_LIST_PLAIN;
	if (Thumbs) WindowType = WINDOW_TYPE_LIST_THUMBS;
	integer WindowNumber = CreateWindow(WindowName, Parent, WindowHeading, BackButton, WindowType);	// Create the window
	list Elements = llParseStringKeepNulls(ListString, [ HUD_API_SEPARATOR_2 ], []);
	integer ListLength = llGetListLength(Elements);
	integer ElementsStride = 2;
	integer LinesPerPage = ListLinesPerPage();
	if (Thumbs) {
		ListLength /= 3;	// because three elements per line
		ElementsStride = 3;
	}
	else {
		ListLength /= 2;	// because two elements per line
		ElementsStride = 2;
	}
	integer NumberOfPages = (ListLength - 1) / LinesPerPage + 1;
	//llOwnerSay(WindowName + ": " + (string)ListLength + " lines on " + (string)NumberOfPages + " pages with " + (string)LinesPerPage + " lines per page");
	integer PageNumber;
	for (PageNumber = 0; PageNumber < NumberOfPages; PageNumber++) {
		// Calculate points to first and last element in the page
		integer PageStart = PageNumber * LinesPerPage * ElementsStride;
		integer PageEnd = PageStart + LinesPerPage * ElementsStride - 1;
		//
		list Lines = llList2List(Elements, PageStart, PageEnd);
		integer Prev = (PageNumber > 0);
		integer Next = (PageNumber < NumberOfPages - 1);
		integer PageIndex = GetNextPageIndex();
		CreatePage(PageIndex, WindowNumber, MakeList(WindowNumber, Thumbs, Lines, Prev, Next, PageIndex));
	}
}
CreateWindowCustom(list Parts) {
	string WindowName = llList2String(Parts, 0);
	string Parent = llList2String(Parts, 1);
	string WindowHeading = llList2String(Parts, 2);
	integer BackButton = (integer)llList2String(Parts, 3);
	string BlockString = llList2String(Parts, 4);
	integer WindowNumber = CreateWindow(WindowName, Parent, WindowHeading, BackButton, WINDOW_TYPE_CUSTOM);	// Create the window
	integer PageIndex = GetNextPageIndex();
	CreatePage(PageIndex, WindowNumber, MakeCustom(WindowNumber, llParseStringKeepNulls(BlockString, [ HUD_API_SEPARATOR_2 ], [] ), PageIndex));
}
CreateWindowStatus(list Parts) {
	string WindowName = llList2String(Parts, 0);
	string WindowHeading = llList2String(Parts, 1);
	string MessageText = llList2String(Parts, 2);
	integer WindowNumber = CreateWindow(WindowName, "", WindowHeading, FALSE, WINDOW_TYPE_MESSAGE);	// Create the window
	integer PageIndex = GetNextPageIndex();
	CreatePage(PageIndex, WindowNumber,
		MakeStatus(WindowNumber, llParseStringKeepNulls(MessageText, [ HUD_API_SEPARATOR_2 ], [] ), PageIndex)
			);
}
CreateWindowAlert(list Parts) {
	string WindowName = llList2String(Parts, 0);
	string WindowHeading = llList2String(Parts, 1);
	string MessageText = llList2String(Parts, 2);
	string ButtonString = llList2String(Parts, 3);
	integer WindowNumber = CreateWindow(WindowName, "", WindowHeading, FALSE, WINDOW_TYPE_ALERT);	// Create the window
	integer PageIndex = GetNextPageIndex();
	CreatePage(PageIndex, WindowNumber,
		MakeAlert(WindowNumber, llParseStringKeepNulls(MessageText, [ HUD_API_SEPARATOR_2 ], [] ), llParseStringKeepNulls(ButtonString, [ HUD_API_SEPARATOR_2 ], [] ), PageIndex)
			);
}
CreateWindowImageText(list Parts) {
	string WindowName = llList2String(Parts, 0);
	string Parent = llList2String(Parts, 1);
	string WindowHeading = llList2String(Parts, 2);
	integer BackButton = (integer)llList2String(Parts, 3);
	list Params = llParseStringKeepNulls(llList2String(Parts, 4), [ HUD_API_SEPARATOR_2 ], []);
	key TextureId = (key)llList2String(Params, 0);
	string Text = llBase64ToString(llList2String(Params, 1));
	integer WindowNumber = CreateWindow(WindowName, Parent, WindowHeading, BackButton, WINDOW_TYPE_IMAGETEXT);	// Create the window
	integer PageIndex = GetNextPageIndex();
	CreatePage(PageIndex, WindowNumber,
		MakeImageText(WindowNumber, TextureId, Text, PageIndex)
			);
}
list MakeButtons(integer WindowNumber, list Buttons, integer PageIndex) {
	// Common elements - background, heading, back button
	list Commands = MakeCommonElements(WindowNumber, PageIndex);
	//
	// Create buttons
	//
	integer ButtonsCount = llGetListLength(Buttons);
	integer Row = 0;
	integer Col = 0;
	integer CursorX = ButtonMarginX;
	integer CursorY = ButtonMarginY;
	integer ButtonPtr;
	// We need some calculations for text size
	integer Break = FALSE;
	integer UseButtonTextFontSize = ButtonTextFontSize;
	float AvailableTextSpace = (float)(ButtonSizeX - (ButtonTextMarginX * 2));	// how much width is available for button text
	// Find the largest font size (starting with the config size) that the text will fit in
	while(!Break) {
		Break = TRUE;
		for (ButtonPtr = 0; ButtonPtr < ButtonsCount; ButtonPtr++) {
			string ButtonText = llList2String(Buttons, ButtonPtr);
			if (TextWidth(ButtonText, ButtonTextFontName, UseButtonTextFontSize) > AvailableTextSpace) {
				Break = FALSE;
				UseButtonTextFontSize--;
			}
		}
	}
	// And we want all our buttons to have the same Y height for text in the button itself, regardless of the text height
	string AllButtons = llDumpList2String(Buttons, "");
	integer HalfTextHeight = TextHeight("Hg" + AllButtons, ButtonTextFontName, UseButtonTextFontSize) / 2; // Use "Hg" as a kind of max-height character with a descender
	for (ButtonPtr = 0; ButtonPtr < ButtonsCount; ButtonPtr++) {
		string ButtonText = llList2String(Buttons, ButtonPtr);
		// Calculate area of button
		integer X1 = ButtonMarginX + (ButtonNettX() * Col);		// Beginning coordinates of button (top left)
		integer Y1 = ButtonMarginY + (ButtonNettY() * Row);
		integer X2 = X1 + ButtonSizeX;		// End coordinates of button (bottom right)
		integer Y2 = Y1 + ButtonSizeY;
		integer Xm = X1 + ButtonSizeX / 2;	// Coordinates of button center
		integer Ym = Y1 + ButtonSizeY / 2;
		// Calculate text position
		integer HalfTextWidth = TextWidth(ButtonText, ButtonTextFontName, UseButtonTextFontSize) / 2;
		integer TX = Xm - HalfTextWidth;
		integer TY = Ym - HalfTextHeight;
		Commands += [
			// Button background
			"MoveTo " + (string)X1 + "," + (string)Y1,
			"PenColor " + ButtonColor,
			"FillRectangle " + (string)ButtonSizeX + "," + (string)ButtonSizeY,
			// Button text
			"MoveTo " + (string)TX + "," + (string)TY,
			"PenColor " + ButtonTextColor,
			"FontName " + ButtonTextFontName,
			"FontSize " + UseButtonTextFontSize,
			"Text " + ButtonText
				];
		// Now we store the coordinates of the button so we can later relate clicks back to buttons
		Areas += [
			AREA_TYPE_TAG, -PageIndex, X1, Y1, X2, Y2, ButtonText
				];
		Col++;
		if ((ButtonMarginX + (ButtonNettX() * Col) + ButtonSizeX) > (PageWidth - ButtonMarginX)) {	// If it won't fit this row
			Row++;		// add CRLF (so to speak)
			Col = 0;
		}
	}
	return Commands;
}
list MakeList(integer WindowNumber, integer Thumbs, list Lines, integer Prev, integer Next, integer PageIndex) {
	// Common elements - background, heading, back button
	list Commands = MakeCommonElements(WindowNumber, PageIndex);
	integer ElementsCount = llGetListLength(Lines);
	integer LinesCount = ElementsCount;
	integer Stride;
	if (Thumbs) {
		LinesCount /= 3;	// uuid, desc, tag
		Stride = 3;
	}
	else {
		LinesCount /= 2;	// desc, tag
		Stride = 2;
	}
	integer LineNumber;
	// We need some calculations for text size
	integer UseListTextFontSize = ListTextFontSize;
	float AvailableTextSpace = (float)(PageWidth - (ListMarginX * 2) -	// how much width is available for text
		(Thumbs * (ListThumbSize + ListTextMarginX)));	// including thumbnail if relevant
	// Find the largest font size (starting with the config size) that the text will fit in
	integer Ptr;
	integer Break = FALSE;
	while(!Break) {
		Break = TRUE;
		for (Ptr = 0; Ptr < ElementsCount; Ptr += Stride) {
			string Text = LongForm(llList2String(Lines, Ptr + 1));
			if (TextWidth(Text, ListTextFontName, UseListTextFontSize) > AvailableTextSpace) {
				Break = FALSE;
				UseListTextFontSize--;
			}
		}
	}
	for (LineNumber = 0; LineNumber < LinesCount; LineNumber++) {
		Ptr = LineNumber * Stride;	// beginning of stride
		string Uuid = "";
		string Text;
		string Tag;
		if (Thumbs) {
			Uuid = llList2String(Lines, Ptr);
			Text = llList2String(Lines, Ptr + 1);
			Tag = llList2String(Lines, Ptr + 2);
		}
		else {
			Text = llList2String(Lines, Ptr);
			Tag = llList2String(Lines, Ptr + 1);
		}
		Text = LongForm(Text);
		if (Tag == "") Tag = Text;	// Tag can be left blank by the client, in which case it takes the value of the item text
		// Coordinates of text
		integer TextX = ListMarginX;
		if (Thumbs) TextX += (ListThumbSize + ListTextMarginX);
		integer LineY = ListMarginY + (LineNumber * (ListSizeY + ListGapY));
		integer TextY = LineY + ListTextMarginY;
		Commands += [
			"MoveTo " + (string)TextX + "," + (string)TextY,
			"PenColor " + ListTextColor,
			"FontName " + ListTextFontName,
			"FontSize " + UseListTextFontSize,
			"Text " + Text
				];
		// Images
		if (Thumbs) {
			Images += [
				PageIndex,
				Uuid,
				Tag
					];
		}
		// Now the area
		integer AX1 = 0;	// give them the whole width of the page as a clickable area (ignore margins)
		integer AX2 = PageWidth;
		integer AY1 = ListMarginY + (LineNumber * (ListSizeY + ListGapY));	// less generous vertically, to reduce risk of clicking on wrong item
		integer AY2 = AY1 + ListSizeY;
		Areas += [
			AREA_TYPE_TAG, -PageIndex, AX1, AY1, AX2, AY2, Tag
				];
	}
	if (Prev) Commands += ListPrevCommands;
	if (Next) Commands += ListNextCommands;
	return Commands;
}
list MakeStatus(integer WindowNumber, list MessageText, integer PageIndex) {
	// Common elements - background, heading, no back button
	list Commands = MakeCommonElements(WindowNumber, PageIndex);
	Commands += MakeText(MessageText, StatusMarginX, StatusCenterY, StatusTextFontName, StatusTextFontSize, StatusTextColor, StatusLineSpacing, StatusTextMaxHeight);
	return Commands;
}
list MakeAlert(integer WindowNumber, list MessageText, list Buttons, integer PageIndex) {
	// Common elements - background, heading, no back button
	list Commands = MakeCommonElements(WindowNumber, PageIndex);
	// Text portion
	Commands += MakeText(MessageText, AlertMarginX, AlertTextCenterY, AlertTextFontName, AlertTextFontSize, AlertTextColor, AlertLineSpacing, AlertTextMaxHeight);
	// And now the buttons
	integer NumberOfButtons = llGetListLength(Buttons);
	integer SizeX = AlertButtonSizeX;
	// Do we need to shrink the buttons?
	integer AvailableWidth = PageWidth - (AlertMarginX * 2);
	while((SizeX * NumberOfButtons) + (AlertButtonGap * (NumberOfButtons - 1)) > AvailableWidth) {
		SizeX--;
	}
	// Do we need to reduce the button text font size?
	integer AvailableButtonTextWidth = SizeX - (AlertButtonTextMarginX * 2);
	integer FontSize = AlertButtonTextFontSize;
	integer Ptr;
	list ButtonTextSizeXs;
	integer ButtonTextSizeY;
	integer Break = FALSE;
	do {
		Break = TRUE;
		ButtonTextSizeXs = [];
		ButtonTextSizeY = 1;
		for (Ptr = 0; Ptr < NumberOfButtons; Ptr++) {
			string Text = llList2String(Buttons, Ptr);
			if (llGetSubString(Text, 0, 0) == "*") Text = llGetSubString(Text, 1, -1);	// strip out initial "*" if present
			vector TextSizeXY = osGetDrawStringSize("vector", Text, AlertButtonTextFontName, FontSize);
			integer TextSizeX = (integer)TextSizeXY.x;
			integer TextSizeY = (integer)TextSizeXY.y;
			if (TextSizeY > ButtonTextSizeY) ButtonTextSizeY = TextSizeY;	// we're finding the tallest button text for use later
			ButtonTextSizeXs += TextSizeX;		// store this for later when we draw the button text
			if (TextSizeX > AvailableButtonTextWidth) Break = FALSE;	// if text won't fit on line, we reduce font size and try again
		}
		if (!Break) FontSize--;
	} while (!Break);
	// Now we calculate the Y positions of the buttons
	integer DivX = AvailableWidth / NumberOfButtons;		// divide the width into areas
	list PosXs = [];
	for (Ptr = 0; Ptr < NumberOfButtons; Ptr++) {
		PosXs += AlertMarginX + (DivX / 2) + (DivX * Ptr);
	}
	integer TextY = AlertButtonY + (AlertButtonSizeY / 2) - (ButtonTextSizeY / 2);		// Find vertical position of text
	// Finally, we can draw the buttons and their text
	for (Ptr = 0; Ptr < NumberOfButtons; Ptr++) {
		string Text = llList2String(Buttons, Ptr);
		integer TextSizeX = llList2Integer(ButtonTextSizeXs, Ptr);
		string Color = AlertButtonColorSecondary;
		if (llGetSubString(Text, 0, 0) == "*") {
			Text = llGetSubString(Text, 1, -1);	// strip out initial "*" if present
			Color = AlertButtonColorPrimary;	// and use primary button colour
		}
		integer PosX = llList2Integer(PosXs, Ptr);
		integer StartX = PosX - (SizeX / 2);	// PosX is centre of button; we need the left edge
		integer TextX = PosX - (TextSizeX / 2);	// Text is centred
		Commands += [
			// Button background
			"MoveTo " + (string)StartX + "," + (string)AlertButtonY,
			"PenColor " + Color,
			"FillRectangle " + (string)SizeX + "," + (string)AlertButtonSizeY,
			// Button text
			"MoveTo " + (string)TextX + "," + (string)TextY,
			"PenColor " + AlertButtonTextColor,
			"FontName " + AlertButtonTextFontName,
			"FontSize " + FontSize,
			"Text " + Text
				];
		Areas += [
			AREA_TYPE_TAG, -PageIndex, StartX, AlertButtonY, StartX + SizeX - 1, AlertButtonY + AlertButtonSizeY - 1, Text
				];
	}
	return Commands;
}
list MakeCustom(integer WindowNumber, list Blocks, integer PageIndex) {
	// Common elements - background, heading, back button
	list Commands = MakeCommonElements(WindowNumber, PageIndex);
	//
	// Create commands
	//
	Commands += [
		"PenColor " + CustomTextColor,
		"FontName " + CustomTextFontName,
		"FontSize " + CustomTextFontSize
			];
	integer BlocksCount = llGetListLength(Blocks);
	integer BlockPtr;
	for (BlockPtr = 0; BlockPtr < BlocksCount; BlockPtr++) {
		string Block = llList2String(Blocks, BlockPtr);
		Commands += Block;
	}
	return Commands;
}
list MakeImageText(integer WindowNumber, key TextureId, string Text, integer PageIndex) {
	// Common elements - background, heading, back button
	list Commands = MakeCommonElements(WindowNumber, PageIndex);
	list Lines = llParseStringKeepNulls(Text, [ "\\n" ], []);
	Commands += MakeText(Lines, ImageTextTextMarginX, ImageTextTextCenterY, ImageTextFontName, ImageTextFontSize, ImageTextColor, ImageTextLineSpacing, ImageTextTextMaxHeight);
	Images += [
		PageIndex,
		TextureId,
		""	// empty tag because ImageText window isn't interactive
			];
	return Commands;
}
// Called after config file read, calculate command to draw next & previous arrows on lists
MakePrevNext() {
	integer ArrowMarginY = (ListPrevNextSizeY - ListPrevNextArrowY) / 2;
	// Up arrow: 1, 2, 3 points are top, bottom left, bottom right
	integer X1 = PageMiddleX;
	integer X2 = PageMiddleX - (ListPrevNextArrowX / 2);
	integer X3 = PageMiddleX + (ListPrevNextArrowX / 2);
	integer PY1 = ListPrevMarginY + ArrowMarginY;
	integer PY2 = PY1 + ListPrevNextArrowY;
	integer PY3 = PY2;
	// Down arrow: 1, 2, 3 points are bottom, top left, top right
	integer NY1 = ListNextMarginY + ArrowMarginY + ListPrevNextArrowY;
	integer NY2 = NY1 - ListPrevNextArrowY;
	integer NY3 = NY2;
	ListPrevCommands =  [
		"PenSize 1",
		"PenColor " + ListPrevNextBarColor,	// set background colour
		"MoveTo " + (string)ListMarginX + "," + (string)ListPrevMarginY,				// go to top left
		"FillRectangle " + (string)ListPrevNextWidth + "," + (string)ListPrevNextSizeY,
		"PenColor " + ListPrevNextArrowColor,
		"FillPolygon " + llList2CSV([ X1, PY1, X2, PY2, X3, PY3 ])
			];
	ListNextCommands =  [
		"PenSize 1",
		"PenColor " + ListPrevNextBarColor,	// set background colour
		"MoveTo " + (string)ListMarginX + "," + (string)ListNextMarginY,				// go to top left
		"FillRectangle " + (string)ListPrevNextWidth + "," + (string)ListPrevNextSizeY,
		"PenColor " + ListPrevNextArrowColor,
		"FillPolygon " + llList2CSV([ X1, NY1, X2, NY2, X3, NY3 ])
			];
	PrevAreaY1 = ListPrevMarginY;
	PrevAreaY2 = PrevAreaY1 + ListPrevNextSizeY;
	NextAreaY1 = ListNextMarginY;
	NextAreaY2 = NextAreaY1 + ListPrevNextSizeY;
}
list MakeText(list Lines, integer MarginX, integer CenterY, string FontName, integer FontSize, string Color, float LineSpacing, integer MaxHeight) {
	integer LineCount = llGetListLength(Lines);
	list Commands = [
		"PenColor " + Color,
		"FontName " + FontName
			];
	integer AvailableLineWidth = PageWidth - (MarginX * 2);
	integer PageCenterY = PageWidth / 2;
	if (LineCount) {
		integer LineNum;
		// First, figure out the font size - if it won't fit horizontally or vertically, reduce the fontsize
		integer ThisTextHeight;
		integer MaxTextSizeX;
		string AllText = llDumpList2String(Lines, " ");
		integer Break = FALSE;
		do {
			Break = TRUE;
			// First, check the vertical
			ThisTextHeight = llFloor((float)TextHeight("H" + AllText, FontName, FontSize) * LineSpacing);	// get the height of lines including the additional vertical space
			///vector AllTextSize = osGetDrawStringSize("vector", "H" + AllText, FontName, FontSize);	// size if the text were all in a single line (add the H to make sure it's the full height)
			///TextHeight = llFloor(AllTextSize.y * LineSpacing);	// get the height of lines including the additional vertical space
			MaxTextSizeX = 1;
			if (ThisTextHeight * LineCount > MaxHeight) {
				Break = FALSE;
			}
			else {
				// Now check the horizontal on each line
				for (LineNum = 0; LineNum < LineCount; LineNum++) {
					string Line = llList2String(Lines, LineNum);
					integer TextSizeX = TextWidth(Line, FontName, FontSize);
					if (TextSizeX > MaxTextSizeX) MaxTextSizeX = TextSizeX;
					if (TextSizeX > AvailableLineWidth) Break = FALSE;	// if text won't fit on line, we reduce font size and try again
				}
			}
			if (!Break) FontSize--;	// reduce font size and try again
			if (FontSize == 0) return [];	// should never happen
		} while (!Break);
		Commands +=	"FontSize " + (string)FontSize;
		// Now actually draw the text
		integer PosX = PageCenterY - (MaxTextSizeX / 2);
		integer PosY = CenterY - (ThisTextHeight * (LineCount / 2));
		for (LineNum = 0; LineNum < LineCount; LineNum++) {
			string Line = llList2String(Lines, LineNum);
			Commands += [
				"MoveTo " + (string)PosX + "," + (string)PosY,
				"Text " + Line
					];
			PosY += ThisTextHeight;
		}
	}
	return Commands;
}
list MakeCommonElements(integer WindowNumber, integer PageIndex) {
	integer WinPtr = llListFindList(Windows, [ -WindowNumber ]);	// find on window number (held -ve)
	if (WinPtr == -1) { ShowError("Can't find window to make elements: " + (string)WindowNumber);  DebugDump(); return []; }
	WinPtr -= WIN_NUMBER;	// position at beginning of stride
	string Heading = llGetSubString(llList2String(Windows, WinPtr + WIN_HEADING), 1, -1);	// substring because we store heading with ~ prefix for finding on name
	Heading = LongForm(Heading);	// strip out any {shortname} section
	string WindowName = llList2String(Windows, WinPtr + WIN_NAME);
	string Parent = DecodeParent(llList2String(Windows, WinPtr + WIN_PARENT));
	integer BackButton = llList2Integer(Windows, WinPtr + WIN_BACKBUTTON);
	// Draw background
	list Commands = [
		"PenColor " + PageColor,	// set background colour
		"MoveTo 0,0",				// go to top left
		"FillRectangle " + (string)PageWidth + "," + (string)PageHeight
			];
	// Draw heading
	integer UseFontSize = HeadingFontSize;
	integer HeadingSpace = PageWidth - HeadingMarginX;
	while (TextWidth(Heading, HeadingFontName, UseFontSize) > HeadingSpace && UseFontSize > 1) UseFontSize--;
	Commands += [
		"MoveTo " + (string)HeadingMarginX + "," + (string)HeadingMarginY,
		"PenColor " + HeadingColor,
		"FontName " + HeadingFontName,
		"FontSize " + (string)UseFontSize,
		"Text " + Heading
			];
	// Back button
	if (BackButton) {
		Commands += [
			"MoveTo " + (string)BackButtonX + "," + (string)BackButtonY,
			"PenColor " + BackButtonColor,
			"FontName " + BackButtonFontName,
			"FontSize " + (string)BackButtonFontSize,
			"Text " + BackButtonChar
				];
	}
	// Breadcrumb trail
	if (Parent != "") {
		// Build up two parallel lists of crumbs:
		list BreadcrumbWindows = [];		// one with window names (for navigation later)
		list BreadcrumbHeadings = [];		// and one with the headings of the windows (for display)
		integer RecursionDetector = 0;
		string ChildWindowName = WindowName;
		string NextParent = Parent;
		do {
			// Find parent window's data
			integer ParentPtr = llListFindList(Windows, [ NextParent ]);
			if (ParentPtr == -1) { ShowError("Can't find parent for window: " + ChildWindowName + " (" + NextParent + ")");  DebugDump(); return []; }
			ParentPtr -= WIN_NAME;
			integer ParentNumber = -llList2Integer(Windows, ParentPtr + WIN_NUMBER);	// reverse sign because held -ve
			string ParentHeading = llGetSubString(llList2String(Windows, ParentPtr + WIN_HEADING), 1, -1) ;	// substring because we store heading with ~ prefix for finding on name
			ParentHeading = ShortForm(ParentHeading);	// use {short form} if available
			// Record parent heading and window number (add to beginning of each list)
			BreadcrumbHeadings = ParentHeading + BreadcrumbHeadings;
			BreadcrumbWindows = NextParent + BreadcrumbWindows ;
			//llOwnerSay("Window: " + NextParent + ", heading: " + ParentHeading);///%%%
			// Move onto grandparent
			ChildWindowName = NextParent;
			NextParent = DecodeParent(llList2String(Windows, ParentPtr + WIN_PARENT));
			if (++RecursionDetector > 50) { ShowError("Recursion in child/parent window relationship: " + ChildWindowName);  DebugDump(); return []; }
		} while(NextParent != "");
		integer CrumbsCount = llGetListLength(BreadcrumbWindows);
		// Make breadcrumb trail on the page
		// First, we need to find the font size that will fit all breadcrumbs on the page
		integer FontSize = BreadFontSize;
		integer AvailableCrumbSpace = PageWidth - (BreadMarginX * 2);
		integer CrumbHeight;
		integer Break = FALSE;
		do {
			string AllCrumbHeadings = llDumpList2String(BreadcrumbHeadings, "");
			integer CrumbWidth = TextWidth(AllCrumbHeadings, BreadFontName, FontSize) + (BreadGap * (CrumbsCount - 1));
			CrumbHeight = TextHeight(AllCrumbHeadings, BreadFontName, FontSize);
			if (CrumbWidth > AvailableCrumbSpace) {
				FontSize--;
			}
			else {
				Break = TRUE;
			}

		} while (!Break && (FontSize >= 2));
		// Find approximate width of separator character
		// We use H because this is likely to be a Unicode character, and they don't calculate properly
		integer SepWidth = TextWidth(BreadSepChar, BreadFontName, FontSize);
		Commands += [
			"PenColor " + BreadColor,
			"FontName " + BreadFontName,
			"FontSize " + (string)FontSize
				];
		integer X = BreadMarginX;
		integer Ptr;
		for (Ptr = 0; Ptr < CrumbsCount; Ptr++) {
			string CrumbHeading = llList2String(BreadcrumbHeadings, Ptr);
			Commands += [
				"MoveTo " + (string)X + "," + (string)BreadMarginY,
				"Text " + CrumbHeading
					];
			integer CrumbWidth = TextWidth(CrumbHeading, BreadFontName, FontSize);
			if (Ptr < CrumbsCount - 1) {	// if it's not the last one
				integer SepX = X + CrumbWidth + (BreadGap / 2) - (SepWidth / 2);
				Commands += [
					"MoveTo " + (string)SepX + "," + (string)BreadMarginY,
					"Text " + BreadSepChar
						];
			}
			// Create clickable area
			string TargetWindowName = llList2String(BreadcrumbWindows, Ptr);
			integer EndY = BreadMarginY + TextHeight(CrumbHeading, BreadFontName, FontSize);
			Areas += [
				AREA_TYPE_NAVIGATE, -PageIndex, X, BreadMarginY, X + CrumbWidth, EndY, TargetWindowName
					];
			// Get ready for next element
			X +=  CrumbWidth + BreadGap;	// move the cursor to the right by the width of the text + the gap
		}
	}
	return Commands;
}
integer ButtonNettX() {
	return ButtonSizeX + ButtonGapX;
}
integer ButtonNettY() {
	return ButtonSizeY + ButtonGapY;
}
integer ListLinesPerPage() {
	integer SpaceAvailable =
		PageHeight // overall height of page
			- ListMarginY // less top margin
		- ListBottomMargin - ListPrevNextSizeY // less bottom margin
		;
	integer LineHeight = ListSizeY + ListGapY;	// height of each line including space below
	return SpaceAvailable / LineHeight;
}
integer TextWidth(string Text, string FontName, integer FontSize) {
	vector Size = osGetDrawStringSize("vector", Text, FontName, FontSize);
	return (integer)Size.x;
}
integer TextHeight(string Text, string FontName, integer FontSize) {
	vector Size = osGetDrawStringSize("vector", Text, FontName, FontSize);
	return (integer)Size.y;
}
// Long form and short form refer to parts of the string "long form {short form}"
string LongForm(string Text) {
	return GetForm(Text, TRUE);
}
string ShortForm(string Text) {
	return GetForm(Text, FALSE);
}
string GetForm(string Text, integer Long) {
	integer P1 = llSubStringIndex(Text, "{");
	if (P1 > -1) {
		integer P2 = llSubStringIndex(Text, "}");
		if (P2 > P1) {
			if (Long)
				Text = llStringTrim(llGetSubString(Text, 0, P1 - 1), STRING_TRIM);
			else
				Text = llStringTrim(llGetSubString(Text, P1 + 1, P2 - 1), STRING_TRIM);
		}
	}
	return Text;
}
// Parent windows are held in the windows table prepended by & for disambiguation
string DecodeParent(string ParentString) {
	if (ParentString  == "&") return "";
	return llGetSubString(ParentString, 1, -1);
}
// Create a new page
CreatePage(integer PageIndex, integer Window, list Commands) {
	Pages += [ Window, -PageIndex ];
	string ExtraParams = "width:" + (string)PageTextureSize + ",height:" + (string)PageTextureSize + ",altdatadelim:" + PRIM_DRAWING_DELIMITER;
	MessageHud(HUD_MESSAGE_CREATE_PAGE, [ PageIndex, ExtraParams, llDumpList2String(Commands, PRIM_DRAWING_DELIMITER) ]);
	return;
}
integer DisplayWindow(string WindowName) {
	integer WinPtr = llListFindList(Windows, [ WindowName ]);
	if (WinPtr == -1) { ShowError("Can't find window to display: '" + WindowName + "'");  DebugDump(); return FALSE; }
	WinPtr -= WIN_NAME;
	CurrentWindowNumber = -llList2Integer(Windows, WinPtr + WIN_NUMBER);	// reverse sign because held -ve
	CurrentBackButton = llList2Integer(Windows, WinPtr + WIN_BACKBUTTON);
	CurrentWindowType = llList2Integer(Windows, WinPtr + WIN_TYPE);
	// get the index of the first page for this window
	integer PagePtr = llListFindList(Pages, [ CurrentWindowNumber ]);
	if (PagePtr == -1) { ShowError("Can't find page to display on window #" + (string)CurrentWindowNumber + ": '" + WindowName + "'"); DebugDump(); return FALSE; }
	PagePtr -= PAGE_WINDOW;	// position at start of stride
	integer PageIndex = -1 * llList2Integer(Pages, PagePtr + PAGE_INDEX);
	// Display on HUD
	DisplayPage(PageIndex);
	// Report currentwindow through API
	SendApiMessage(HUD_API_CURRENT_WINDOW, [ WindowName ], AvId);
	return IntegrityCheck();
}
DisplayPage(integer PageIndex) {
	CurrentPageIndex = PageIndex;
	// Images
	list ImageTiles = [];
	if (CurrentWindowType == WINDOW_TYPE_LIST_THUMBS) {
		integer T = llListFindList(Images, [ PageIndex ]);
		if (T > -1) {
			integer Which = 0;	// which thumbnail on this page? [0-<n>]
			while(llList2Integer(Images, T + IMG_PAGE_INDEX) == PageIndex) {
				string Uuid = llList2String(Images, T + IMG_UUID);
				string Tag = llList2String(Images, T + IMG_TAG);
				vector Pos = ThumbnailPos(Which);
				ImageTiles += [ Uuid, Tag, Pos, ThumbScale ];
				Which++;
				T += IMG_STRIDE;
			}
		}
	}
	else if (CurrentWindowType == WINDOW_TYPE_IMAGETEXT) {
		integer T = llListFindList(Images, [ PageIndex ]);
		if (T > -1) {
			string Uuid = llList2String(Images, T + IMG_UUID);
			string Tag = llList2String(Images, T + IMG_TAG);
			ImageTiles += [ Uuid, Tag, ImageTextImagePos, ImageTextImageScale ];
		}
	}
	string ImageString = llDumpList2String(ImageTiles, MESSAGE_SEPARATOR_2);
	// Display on HUD
	MessageHud(HUD_MESSAGE_DISPLAY_PAGE, [ PageIndex, ImageString ]);
}
integer GetPrevPage(integer WindowNumber, integer PageIndex) {
	integer P = llListFindList(Pages, [ WindowNumber, -(PageIndex - 1) ]);
	if (P == -1) return -1;
	return PageIndex - 1;
}
integer GetNextPage(integer WindowNumber, integer PageIndex) {
	integer P = llListFindList(Pages, [ WindowNumber, -(PageIndex + 1) ]);
	if (P == -1) return -1;
	return PageIndex + 1;
}
// Calculates local position of a thumbnail prim
vector ThumbnailPos(integer Which) {
	vector Pos = ThumbFirstPos;
	Pos.z -= Thumbgap * (float)Which;
	return Pos;
}
ImageCalculations() {
	// Bear in mind that a HUD item at rotation zero has X going front to back, Y going right to left and Z going bottom to top.
	// I have no clue why LL picked such an odd combination of axes. Here, we try to use sensible names to imagine the HUD as
	// seen by the user.
	PagePrimTopPos = -RootPrimSize.z / 2.0;
	PagePrimLeftPos = PagePrimSize.x / 2.0;
	// Thumbnails
	ThumbFirstPos = ZERO_VECTOR;
	ThumbFirstPos.x = -0.1;	// in front of page prim
	ThumbFirstPos.y = PagePrimLeftPos - Pixels2Metres(ListMarginX) - (Pixels2Metres(ListThumbSize) / 2.0);
	ThumbFirstPos.z = PagePrimTopPos - Pixels2Metres(ListMarginY) - (Pixels2Metres(ListThumbSize) / 2.0);
	Thumbgap = Pixels2Metres(ListThumbSize) + Pixels2Metres(ListGapY);
	float T = Pixels2Metres(ListThumbSize);
	ThumbScale = <T, T, 0.1>;
	// ImageText image
	integer ITImageSizePixels = PageWidth - (ImageTextImageMarginX * 2);
	float ITSizeMetres = Pixels2Metres(ITImageSizePixels);
	ImageTextImageScale = <ITSizeMetres, ITSizeMetres, 0.1>;
	ImageTextImagePos = <
		-0.1,		// in front of page prim
		PagePrimLeftPos - Pixels2Metres(ImageTextImageMarginX) - (Pixels2Metres(ITImageSizePixels) / 2.0),
		PagePrimTopPos - Pixels2Metres(ImageTextImageMarginY) - (Pixels2Metres(ITImageSizePixels) / 2.0)
			>;
}
float Pixels2Metres(integer Pixels) {
	return (float)Pixels / PixelsPerMetre ;
}
// Creates table entries for a window. Returns window number
integer CreateWindow(string WindowName, string Parent, string WindowHeading, integer BackButton, integer WindowType) {
	// Is name already in use?
	integer WinPtr = llListFindList(Windows, [ WindowName ]);
	if (WinPtr > -1) {	// window already exists with this name, so destroy it
		DestroyWindow(WindowName);
	}
	integer WindowNumber = NextWindowNumber++;
	Windows += [
		WindowName,					// name
		-WindowNumber,				// unique # for window, held -ve
		"~" + WindowHeading,		// heading
		BackButton,					// has back button?
		"&" + Parent,						// name of parent window
		WindowType,					// type
		""							// data
			];
	return WindowNumber;
}
string CurrentWindowName() {
	if (CurrentWindowNumber == -1) return "";
	integer WinPtr = llListFindList(Windows, [ -CurrentWindowNumber ]);	// find on window number (held -ve)
	WinPtr -= WIN_NUMBER;	// position at beginning of stride
	return llList2String(Windows, WinPtr + WIN_NAME);
}
integer GetNextPageIndex() {
	return NextPageIndex++;
}
// Destroy a window and its pages
DestroyWindow(string WindowName) {
	integer WinPtr = llListFindList(Windows, [ WindowName ]);
	if (WinPtr == -1) { ShowError("Can't find window to destroy: " + (string)WinPtr); return; }
	WinPtr -= WIN_NAME;	// position at start of stride
	integer WindowNumber = -llList2Integer(Windows, WinPtr + WIN_NUMBER);	// held -ve
	Windows = llDeleteSubList(Windows, WinPtr, WinPtr + WIN_STRIDE - 1);
	integer Break = FALSE;
	do {
		integer PagePtr = llListFindList(Pages, [ WindowNumber ]);
		if (PagePtr > -1) {
			PagePtr -= PAGE_WINDOW;
			integer PageIndex = -1 * llList2Integer(Pages, PagePtr + PAGE_INDEX);
			Pages = llDeleteSubList(Pages, PagePtr, PagePtr + PAGE_STRIDE - 1);
			MessageHud(HUD_MESSAGE_DELETE_PAGE, [ PageIndex ]);
			// Destroy associated area (not the most efficient code, but it'll do for now)
			integer Break2 = FALSE;
			do {
				integer A = llListFindList(Areas, [ -PageIndex ]);
				if (A > -1) {
					A -= AREA_PAGE_INDEX;	// position at start of stride
					Areas = llDeleteSubList(Areas, A, A + AREA_STRIDE - 1);
				}
				else {
					Break2 = TRUE;
				}
			} while(!Break2);
			// Likewise for images
			Break2 = FALSE;
			do {
				integer T = llListFindList(Images, [ PageIndex ]);
				if (T > -1)
					Images = llDeleteSubList(Images, T, T + IMG_STRIDE - 1);
				else
					Break2 = TRUE;
			} while(!Break2);
		}
		else {
			Break = TRUE;
		}
	} while(!Break);
}
integer UserNotHere() {
	return (llGetAgentSize(AvId) == ZERO_VECTOR);	// this is a legitimate way of checking!
}
ClearData() {
	Windows = [];
	Pages = [];
	Areas = [];
	Images = [];
	NextWindowNumber = 1;
	NextPageIndex = 1;
	CurrentWindowNumber = -1;
	CurrentBackButton = FALSE;
	CurrentPageIndex = -1;
}
DisconnectUser() {
	SendApiMessage(HUD_API_LOGOUT, [], AvId);
	// deactivate their HUD
	if (HudId != NULL_KEY)
		MessageHud(HUD_MESSAGE_DEACTIVATE, []);
	ClearData();
}
// Data to be sent to HUD attachement script
list SetActivateData() {
	return [
		TimerFrequency,
		ApplicationName,
		TitleCanvasSize,
		TitleForeColor, TitleBackColor,
		TitleFontName,
		TitleFontSize,
		TitleLeftMargin,
		TitleTopMargin,
		RootPrimSize,
		PagePrimSize,
		PageTextureSize,
		PageWidth,
		PageHeight,
		CameraZoomFactor,
		UuidLogo,
		UuidMinMax,
		PageColor,
		SplashPrimTexture,
		FloatBackColor,
		FloatBackHeight,
		FloatTextColorNormal,
		FloatTextPos,
		FloatTextColorWarn
			];
}
HandleLinkMessage(integer Sender, integer Command, string Data, key Id, integer Activated) {
	if (Sender == 1 && Command >= HUD_API_MIN && Command <= HUD_API_MAX) {
		IsClientReady = TRUE;
		HandleApiMessage(Command, Data, Id, Activated);
	}
}
ShowStatus() {
	string Text = "";
	if (StatusType != ST_IDLE) {
		if (StatusType == ST_ACTIVATE) Text += "ACTIVATING\n";
		if (!IsClientReady) Text += "Waiting for client ...\n";
		if (!IsHudReady) Text += "Waiting for HUD ...\n";
		if (AvId != NULL_KEY) Text += llKey2Name(AvId);
	}
	llSetText(Text, <0.6, 0.6, 1.0>, 1.0);
}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	integer ReturnStatus = TRUE;
	// Set config defaults
	TimerFrequency = 1000;
	DoIntegrityCheck = TRUE;
	TitleCanvasSize = 1024;
	TitleForeColor = "Black";
	TitleBackColor = "White";
	TitleFontName = "Noto Sans";
	TitleFontSize = 60;
	TitleLeftMargin = 0;
	TitleTopMargin = 0;
	float WidthM = 0.2;
	float HeightM = 0.4;
	PagePrimSize = <0.16, 0.32, 0.002>;
	PageTextureSize = 1024;
	PageWidth = 512;
	PageHeight = 1024;
	PageColor = "FFEDFAFD";
	SplashPrimTexture = TEXTURE_BLANK;
	HeadingMarginX = 10;
	HeadingMarginY = 10;
	HeadingFontName = "Noto Sans";
	HeadingFontSize = 24;
	HeadingColor = "FF2A93D5";
	BreadMarginX = 20;
	BreadMarginY = 120;
	BreadGap = 30;
	BreadFontName = "Noto Sans";
	BreadFontSize = 20;
	BreadColor = "FF2A93D5";
	BreadSepChar = "➡";
	BackButtonChar = "<";
	BackButtonX = 10;
	BackButtonY = 10;
	BackButtonFontName = "Noto Sans";
	BackButtonFontSize = 24;
	BackButtonColor = "FF2A93D5";
	ButtonSizeX = 180;
	ButtonSizeY = 96;
	ButtonMarginX = 10;
	ButtonMarginY = 10;
	ButtonGapX = 20;
	ButtonGapY = 10;
	ButtonColor = "FF2A93D5";
	ButtonTextMarginX = 10;
	ButtonTextMarginY = 10;
	ButtonTextFontName = "Noto Sans";
	ButtonTextFontSize = 18;
	ButtonTextColor = "FFEDFAFD";
	ListMarginX = 20;
	ListMarginY = 130;
	ListSizeY = 60;
	ListThumbSize = 60;
	ListGapY = 10;
	ListPrevNextSizeY = 20;
	ListPrevNextArrowX = 15;
	ListPrevNextArrowY = 10;
	ListPrevNextArrowColor = "FFEDFAFD";
	ListPrevNextBarColor = "FF2A93D5";
	ListPrevMarginY = 120;
	ListTextMarginX = 10;
	ListTextMarginY = 10;
	ListTextFontName = "Noto Sans";
	ListTextFontSize = 18;
	ListTextColor = "FF2A93D5";
	ListBottomMargin = 10;
	StatusCenterY = 512;
	StatusMarginX = 12;
	StatusTextMaxHeight = 300;
	StatusTextFontName = "Noto Sans";
	StatusTextFontSize = 28;
	float StatusLineSpacingPercent = 10.0;
	StatusTextColor = "FF2A93D5";
	AlertMarginX = 12;
	AlertTextCenterY = 512;
	AlertTextMaxHeight = 200;
	AlertTextFontName = "Noto Sans";
	AlertTextFontSize = 36;
	float AlertLineSpacingPercent = 10.0;
	AlertTextColor = "FF2A93D5";
	AlertButtonY = 700;
	AlertButtonSizeX = 140;
	AlertButtonSizeY = 96;
	AlertButtonGap = 24;
	AlertButtonColorPrimary = "FF135589";
	AlertButtonColorSecondary = "FF2A93D5";
	AlertButtonTextMarginX = 15;
	AlertButtonTextFontName = "Noto Sans";
	AlertButtonTextFontSize = 36;
	AlertButtonTextColor = "FFEDFAFD";
	CustomTextFontName = "Noto Sans";
	CustomTextFontSize = 18;
	CustomTextColor = "FF2A93D5";
	ImageTextImageMarginX = 12;
	ImageTextImageMarginY = 12;
	ImageTextTextMarginX = 12;
	ImageTextTextCenterY = 600;
	ImageTextTextMaxHeight = 300;
	float ImageTextLineSpacingPercent = 10.0;
	ImageTextFontName = "Noto Sans";
	ImageTextFontSize = 28;
	ImageTextColor = "FFEDFAFD";
	FloatBackColor = "FF135589";
	FloatBackHeight = 0.03;
	FloatTextColorNormal = "FFEDFAFD";
	FloatTextColorWarn = "FFFFDD33";
	FloatTextPos = 0.018;
	CameraZoomFactor = 0.2;
	// Read the card
	string Section = "none";
	list Lines = llParseStringKeepNulls(osGetNotecard(CONFIG_NOTECARD), [ "\n" ], []);
	integer LineCount = llGetListLength(Lines);
	integer I;
	for(I = 0; I < LineCount; I++) {
		string Line = llList2String(Lines, I);
		integer Comment = llSubStringIndex(Line, "//");
		if (Comment != 0) {    // Not a complete comment line
			if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);    // strip from comments characters onwards
			Line = llStringTrim(Line, STRING_TRIM);		// get rid of leading and trailing spaces
			if (Line != "") {    // if there's something left after comments are removed
				// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
				list L = llParseStringKeepNulls(Line, [ "=" ], [ ]);    // Separate LHS and RHS of assignment
				if (llGetSubString(Line, 0, 0) == "[" && llGetSubString(Line, -1, -1) == "]") {		// if it's in the format "[Section]"
					Section = llToLower(llGetSubString(Line, 1, -2));
				}
				else if (llGetListLength(L) == 2) {    // so there is a "X = Y" kind of syntax
					string OName = llStringTrim(llList2String(L, 0), STRING_TRIM);        // original parameter name
					string Name = llToLower(OName);        // lower-case version for case-independent parsing
					string Value = llStringTrim(llList2String(L, 1), STRING_TRIM);
					// Interpret name/value pairs
					integer Valid = TRUE;
					if (Section == "general") {
						if (Name == "timerfrequency") TimerFrequency = (integer)Value;
						else if (Name == "splashprim") SplashPrimTexture = Value;
						else if (Name == "logo") UuidLogo = Value;
						else if (Name == "minmax") UuidMinMax = Value;
						else if (Name == "integritycheck") DoIntegrityCheck = (integer)Value;
						else if (Name == "backgroundcolor") PageColor = Value;
						else if (Name == "hudtitle") ApplicationName = StripQuotes(Value, Line);
						else Valid = FALSE;
					}
					else if (Section == "sizes") {
						if (Name == "widthm") WidthM = (float)Value;
						else if (Name == "heightm") HeightM = (float)Value;
						//		else if (Name == "widthpx") PageWidth = (integer)Value;
						//		else if (Name == "heightpx") PageHeight = (integer)Value;
						else if (Name == "texturesize") PageTextureSize = (integer)Value;
						else Valid = FALSE;
					}
					else if (Section == "heading") {
						if (Name == "marginx") HeadingMarginX = (integer)Value;
						else if (Name == "marginy") HeadingMarginY = (integer)Value;
						else if (Name == "fontname") HeadingFontName = Value;
						else if (Name == "fontsize") HeadingFontSize = (integer)Value;
						else if (Name == "color") HeadingColor = Value;
						else Valid = FALSE;
					}
					else if (Section == "backbutton") {
						if (Name == "char") BackButtonChar = Value;
						else if (Name == "x") BackButtonX = (integer)Value;
						else if (Name == "y") BackButtonY = (integer)Value;
						else if (Name == "fontname") BackButtonFontName = Value;
						else if (Name == "fontsize") BackButtonFontSize = (integer)Value;
						else if (Name == "color") BackButtonColor = Value;
						else Valid = FALSE;
					}
					else if (Section == "breadcrumb") {
						if (Name == "marginx") BreadMarginX = (integer)Value;
						else if (Name == "marginy") BreadMarginY = (integer)Value;
						else if (Name == "gap") BreadGap = (integer)Value;
						else if (Name == "fontname") BreadFontName = Value;
						else if (Name == "fontsize") BreadFontSize = (integer)Value;
						else if (Name == "color") BreadColor = Value;
						else if (Name == "sepchar") BreadSepChar = Value;
						else Valid = FALSE;
					}
					else if (Section == "button") {
						if (Name == "sizex") ButtonSizeX = (integer)Value;
						else if (Name == "sizey") ButtonSizeY = (integer)Value;
						else if (Name == "marginx") ButtonMarginX = (integer)Value;
						else if (Name == "marginy") ButtonMarginY = (integer)Value;
						else if (Name == "gapx") ButtonGapX = (integer)Value;
						else if (Name == "gapy") ButtonGapY = (integer)Value;
						else if (Name == "color") ButtonColor = Value;
						else if (Name == "textmarginx") ButtonTextMarginX = (integer)Value;
						else if (Name == "textmarginy") ButtonTextMarginY = (integer)Value;
						else if (Name == "textfontname") ButtonTextFontName = Value;
						else if (Name == "textfontsize") ButtonTextFontSize = (integer)Value;
						else if (Name == "textcolor") ButtonTextColor = Value;
						else Valid = FALSE;
					}
					else if (Section == "list") {
						if (Name == "marginx") ListMarginX = (integer)Value;
						else if (Name == "marginy") ListMarginY = (integer)Value;
						else if (Name == "sizey") ListSizeY = (integer)Value;
						else if (Name == "thumbsize") ListThumbSize = (integer)Value;
						else if (Name == "gapy") ListGapY = (integer)Value;
						else if (Name == "prevnextsizey") ListPrevNextSizeY = (integer)Value;
						else if (Name == "prevnextarrowx") ListPrevNextArrowX = (integer)Value;
						else if (Name == "prevnextarrowy") ListPrevNextArrowY = (integer)Value;
						else if (Name == "prevnextbarcolor") ListPrevNextBarColor = Value;
						else if (Name == "prevnextarrowcolor") ListPrevNextArrowColor = Value;
						else if (Name == "prevmarginy") ListPrevMarginY = (integer)Value;
						else if (Name == "textmarginx") ListTextMarginX = (integer)Value;
						else if (Name == "textmarginy") ListTextMarginY = (integer)Value;
						else if (Name == "textfontname") ListTextFontName = Value;
						else if (Name == "textfontsize") ListTextFontSize = (integer)Value;
						else if (Name == "textcolor") ListTextColor = Value;
						else if (Name == "bottommargin") ListBottomMargin = (integer)Value;
						else Valid = FALSE;
					}
					else if (Section == "status") {
						if (Name == "centery") StatusCenterY = (integer)Value;
						else if (Name == "marginx") StatusMarginX = (integer)Value;
						else if (Name == "textmaxheight") StatusTextMaxHeight = (integer)Value;
						else if (Name == "textfontname") StatusTextFontName = Value;
						else if (Name == "textfontsize") StatusTextFontSize = (integer)Value;
						else if (Name == "linespacing") StatusLineSpacingPercent = (float)Value;
						else if (Name == "textcolor") StatusTextColor = Value;
						else Valid = FALSE;
					}
					else if (Section == "alert") {
						if (Name == "marginx") AlertMarginX = (integer)Value;
						else if (Name == "textcentery") AlertTextCenterY = (integer)Value;
						else if (Name == "textmaxheight") AlertTextMaxHeight = (integer)Value;
						else if (Name == "textfontname") AlertTextFontName = Value;
						else if (Name == "textfontsize") AlertTextFontSize = (integer)Value;
						else if (Name == "linespacing") AlertLineSpacingPercent = (float)Value;
						else if (Name == "textcolor") AlertTextColor = Value;
						else if (Name == "buttony") AlertButtonY = (integer)Value;
						else if (Name == "buttonsizex") AlertButtonSizeX = (integer)Value;
						else if (Name == "buttonsizey") AlertButtonSizeY = (integer)Value;
						else if (Name == "buttongap") AlertButtonGap = (integer)Value;
						else if (Name == "buttontextmarginx") AlertButtonTextMarginX = (integer)Value;
						else if (Name == "buttoncolorprimary") AlertButtonColorPrimary = Value;
						else if (Name == "buttoncolorsecondary") AlertButtonColorSecondary = Value;
						else if (Name == "buttontextfontname") AlertButtonTextFontName = Value;
						else if (Name == "buttontextfontsize") AlertButtonTextFontSize = (integer)Value;
						else if (Name == "buttontextcolor") AlertButtonTextColor = Value;
						else Valid = FALSE;
					}
					else if (Section == "custom") {
						if (Name == "textfontname") CustomTextFontName = Value;
						else if (Name == "textfontsize") CustomTextFontSize = (integer)Value;
						else if (Name == "textcolor") CustomTextColor = Value;
						else Valid = FALSE;
					}
					else if (Section == "imagetext") {
						if (Name == "imagemarginx") ImageTextImageMarginX = (integer)Value;
						else if (Name == "imagemarginy") ImageTextImageMarginY = (integer)Value;
						else if (Name == "textmarginx") ImageTextTextMarginX = (integer)Value;
						else if (Name == "textcentery") ImageTextTextCenterY = (integer)Value;
						else if (Name == "textmaxheight") ImageTextTextMaxHeight = (integer)Value;
						else if (Name == "linespacing") ImageTextLineSpacingPercent = (float)Value;
						else if (Name == "textfontname") ImageTextFontName = Value;
						else if (Name == "textfontsize") ImageTextFontSize = (integer)Value;
						else if (Name == "textcolor") ImageTextColor = Value;
						else Valid = FALSE;
					}
					else if (Section == "title") {
						if (Name == "canvassize") TitleCanvasSize = (integer)Value;
						else if (Name == "forecolor") TitleForeColor = Value;
						else if (Name == "backcolor") TitleBackColor = Value;
						else if (Name == "fontname") TitleFontName = Value;
						else if (Name == "fontsize") TitleFontSize = (integer)Value;
						else if (Name == "leftmargin") TitleLeftMargin = (integer)Value;
						else if (Name == "topmargin") TitleTopMargin = (integer)Value;
						else Valid = FALSE;
					}
					else if (Section == "bottomtext") {
						if (Name == "floatbackcolor") FloatBackColor = Value;
						else if (Name == "floatbackheight") FloatBackHeight = (float)Value;
						else if (Name == "floattextcolor") FloatTextColorNormal = Value;
						else if (Name == "floattextcolorwarning") FloatTextColorWarn= Value;
						else if (Name == "floattextpos") FloatTextPos = (float)Value;
						else Valid = FALSE;
					}
					else if (Section == "camerajump") {
						if (Name == "camerazoomfactor") CameraZoomFactor = (float)Value;
						else Valid = FALSE;
					}
					else {
						llOwnerSay("Invalid section in config file: '" + Section + "'");
						ReturnStatus = FALSE;
					}
					if (!Valid) {
						llOwnerSay("Invalid keyword in config file: '" + OName + "' in section: " + Section);
						ReturnStatus = FALSE;
					}
				}
				else {
					llOwnerSay("Invalid line in config file: " + Line);
				}
			}
		}
	}
	// Calculations
	RootPrimSize = <0.001, WidthM, WidthM / 8.0>;
	PagePrimSize = <WidthM, HeightM, 0.001>;
	float AspectRatio = WidthM / HeightM;
	PageHeight = PageTextureSize;
	PageWidth = (integer)(PageTextureSize * AspectRatio);
	PixelsPerMetre = (float)PageWidth / PagePrimSize.x;
	PageMiddleX = PageWidth / 2;
	ListPrevNextWidth = PageWidth - (ListMarginX * 2);
	ListNextMarginY = PageHeight - ListBottomMargin - ListPrevNextSizeY;
	StatusLineSpacing = 1.0 + StatusLineSpacingPercent / 100.0;
	AlertLineSpacing = 1.0 + AlertLineSpacingPercent / 100.0;
	ImageTextLineSpacing = 1.0 + ImageTextLineSpacingPercent / 100.0;
	MakePrevNext();
	ImageCalculations();
	return TRUE;
}
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
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
integer VersionCheck(string Base, string Actual) {
	integer P = llSubStringIndex(Base, ".");
	if (P == -1) return FALSE;
	integer BaseMajor = (integer)llGetSubString(Base, 0, P - 1);
	integer BaseMinor = (integer)llGetSubString(Base, P + 1, -1);
	P = llSubStringIndex(Actual, ".");
	if (P == -1) return FALSE;
	integer ActualMajor = (integer)llGetSubString(Actual, 0, P - 1);
	integer ActualMinor = (integer)llGetSubString(Actual, P + 1, -1);
	if (BaseMajor > ActualMajor) return FALSE;
	if (BaseMajor < ActualMajor) return TRUE;
	// so major version is the same
	if (BaseMinor > ActualMinor) return FALSE;
	return TRUE;
}
// General routine for sending a message to the HUD
MessageHud(string Command, list Parameters) {
	if (HudId != NULL_KEY) {
		string ParamString = llDumpList2String(Command + Parameters, HUD_API_SEPARATOR_1);
		Debug("Sending to HUD: " + llGetSubString(ParamString, 0, 20));
		MessageObject(HudId, ParamString);
	}
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
// Messages come in a standard format: command followed by a list of parameters, all separated by MESSAGE_SEPARATOR
// We pass everything back as a list, the 0th element of which is the command and the rest the parameters
list ParseMessage(string Data) {
	return llParseStringKeepNulls(Data, [ MESSAGE_SEPARATOR ], []);
}
// Converts list into string, putting a type character in front of each list item (eg i456 for integer 456)
string DumpList2TypedString(list List, string Separator) {
	list Output = [];
	integer Len = llGetListLength(List);
	integer I;
	for (I = 0; I < Len; I++) {
		integer EntryType = llGetListEntryType(List, I);
		string TypeCode = "?";
		if (EntryType == TYPE_STRING) TypeCode = "s";
		else if (EntryType == TYPE_INTEGER) TypeCode = "i";
		else if (EntryType == TYPE_FLOAT) TypeCode = "f";
		else if (EntryType == TYPE_VECTOR) TypeCode = "v";
		else if (EntryType == TYPE_ROTATION) TypeCode = "r";
		else if (EntryType == TYPE_KEY) TypeCode = "k";
		else { llOwnerSay("invalid list type: " + (string)EntryType); return ""; }
		Output += TypeCode + llList2String(List, I);
	}
	return llDumpList2String(Output, Separator);
}
ShowError(string Text) {
	Text = "\nERROR!\n\n" + Text;
	if (AvId == NULL_KEY)
		llShout(0, Text);
	else
		llDialog(AvId, Text, [ "OK" ], -9999999);
}
integer IntegrityCheck() {
	if (!DoIntegrityCheck) return TRUE;
	integer Errors = FALSE;
	integer Count = llGetListLength(Windows);
	integer I;
	for (I = 0; I < Count; I += WIN_STRIDE) {
		integer WindowNumber = -llList2Integer(Windows, I + WIN_NUMBER);	// held -ve
		string WindowName = llList2String(Windows, I + WIN_NAME);
		if (WindowNumber < 1) {
			llOwnerSay("Invalid window number: " + (string)WindowNumber);
			Errors = TRUE;
		}
		integer P = llListFindList(Pages, [ WindowNumber ]);
		if (P == -1) {
			llOwnerSay("Window #" + (string)WindowNumber + " (" + WindowName + ") has no pages");
			Errors = TRUE;
		}
		string ParentName = DecodeParent(llList2String(Windows, I + WIN_PARENT));
		if (ParentName != "") {
			P = llListFindList(Windows, [ ParentName ]);
			if (P == -1) {
				llOwnerSay("Window #" + (string)WindowNumber + " (" + WindowName + ") has invalid parent name: '" + ParentName + "'");
				Errors = TRUE;
			}
		}
	}
	Count = llGetListLength(Pages);
	for (I = 0; I < Count; I += PAGE_STRIDE) {	// lazy, but unimportant in context
		integer WindowNumber = llList2Integer(Pages, I + PAGE_WINDOW);
		integer PageIndex = -llList2Integer(Pages, I + PAGE_INDEX);	// held -ve
		if (PageIndex < 1) {
			llOwnerSay("Invalid page index: " + (string)PageIndex);
			Errors = TRUE;
		}
		integer W = llListFindList(Windows, [ -WindowNumber ]);	// held -ve
		if (W == -1) {
			llOwnerSay("Orphan page for non-existent window #" + (string)WindowNumber + " [" + (string)PageIndex + "]");
			Errors = TRUE;
		}
	}
	Count = llGetListLength(Areas);
	for (I = 0; I < Count; I += AREA_STRIDE) {
		integer AreaType = llList2Integer(Areas, I + AREA_TYPE);
		if (AreaType == AREA_TYPE_TAG) {
			string Tag = llList2String(Areas, I + AREA_DATA);
			if (Tag == "") {
				llOwnerSay("Empty tag on area");
				Errors = TRUE;
			}
		}
		else if (AreaType == AREA_TYPE_NAVIGATE) {
			string NavWindowName = llList2String(Areas, I + AREA_DATA);
			integer W = llListFindList(Windows, [ NavWindowName ]);
			if (W == -1) {
				llOwnerSay("Invalid navigate window name for area: '" + NavWindowName + "'");
				Errors = TRUE;
			}
		}
		else {
			llOwnerSay("Invalid area type: " + (string)AreaType + " (data = '" + llList2String(Areas, I + AREA_DATA) + "')");
			Errors = TRUE;
		}
		integer PageIndex = -llList2Integer(Areas, I + AREA_PAGE_INDEX);	// held -ve
		if (llListFindList(Pages, [ -PageIndex ]) == -1) {
			llOwnerSay("Orphan area for non-existent page index: " + (string)PageIndex);
			Errors = TRUE;
		}
	}
	Count = llGetListLength(Images);
	for (I = 0; I < Count; I += IMG_STRIDE) {
		integer PageIndex = llList2Integer(Images, I + IMG_PAGE_INDEX);
		if (llListFindList(Pages, [ -PageIndex ]) == -1) {
			llOwnerSay("Orphan thumbnail for non-existent page index: " + (string)PageIndex);
			Errors = TRUE;
		}
	}
	if (Errors) {
		DebugDump();
		return FALSE;
	}
	return TRUE;
}
Debug(string Text) {
	if (DebugMode) llOwnerSay(Text);
}
DebugDump() {
	llOwnerSay("Start dump ----------------------------------------------------------");
	string All;
	string D = "Windows (N|-W):\n";
	integer Count = llGetListLength(Windows);
	integer I;
	for (I = 0; I < Count; I += WIN_STRIDE) {
		D += (string)I + ": " + llDumpList2String(llList2List(Windows, I, I + WIN_STRIDE - 1), "|") + "\n";
	}
	llOwnerSay("Debug:\n" + D);
	All += D;
	D = "Pages (W|-P):\n";
	Count = llGetListLength(Pages);
	for (I = 0; I < Count; I += PAGE_STRIDE) {	// lazy, but unimportant in context
		D += llDumpList2String(llList2List(Pages, I, I + PAGE_STRIDE - 1), "|") + "\n";
	}
	llOwnerSay(D);
	All += D;
	D = "Areas:\n";
	Count = llGetListLength(Areas);
	for (I = 0; I < Count; I += AREA_STRIDE) {
		D += llDumpList2String(llList2List(Areas, I, I + AREA_STRIDE - 1), "|") + "\n";
	}
	llOwnerSay(D);
	All += D;
	D = "Images:\n" ;
	Count = llGetListLength(Images);
	for (I = 0; I < Count; I += IMG_STRIDE) {
		D += (string)I + ": " + llDumpList2String(llList2List(Images, I, I + IMG_STRIDE - 1), " ") + "\n";
	}
	llOwnerSay(D);
	llOwnerSay("End dump ------------------------------------------------------------");
	//osMakeNotecard("Debug dump", All);
}
default {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		MyUuid = llGetKey();
		if (!ReadConfig()) state Hang;
		if (llGetNumberOfPrims() == 1) state Hang;
		ApplicationName = "";
		GotMetaData = FALSE;
		state Idle;
	}
}
state Idle {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		Debug("Idle");
		ClearData();
		MyLinkNum = llGetLinkNumber();
		llSetTimerEvent(0.0);
		AvId = HudId = NULL_KEY;
		if (!GotMetaData) llSetTimerEvent(2.0);
		StatusType = ST_IDLE;
		ShowStatus();
	}
	touch_start(integer Count) {
		key TouchId = llDetectedKey(0);
		if (llGetLinkNumber() < 2) {
			llDialog(TouchId, "\nIncorrectly linked!", [ "OK" ], -999);
			return;
		}
		AvId = TouchId;
		StatusType = ST_ACTIVATE;
		ShowStatus();
		state ActivateHud;
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		HandleLinkMessage(Sender, Number, Text, Id, FALSE);
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			if (!ReadConfig()) state Hang;
		}
		if (Change & CHANGED_LINK) MyLinkNum = llGetLinkNumber();
	}
	timer() {
		if (!GotMetaData) {
			SendApiMessage(HUD_API_GET_METADATA, [], NULL_KEY);
		}
		else {
			llSetTimerEvent(0.0);
		}
	}
}
state ActivateHud {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		Debug("Activating");
		if (!ReadConfig()) {
			llOwnerSay("Invalid config");
			state Hang;
		}
		HudId = NULL_KEY;
		IsHudReady = FALSE;
		IsClientReady = FALSE;
		osMessageAttachments(AvId, HUD_MESSAGE_HELLO, HUDAttachPoints, 0);
		llSetTimerEvent(3.0);
	}
	dataserver(key Id, string Data) {
		if (Id == MyUuid) return;	// we never listen to our own messages
		Debug("Rec'd data: " + Data);
		list Parts = ParseMessage(Data);
		string Command = llList2String(Parts, 0);
		list Params = llList2List(Parts, 1, -1);
		if (Command == HUD_MESSAGE_HELLO) {
			key ThisAvId = llGetOwnerKey(Id);
			string ThisHudVersion = llList2String(Params, 0);
			if (ThisAvId == AvId) {
				Debug("Received message from " + llKey2Name(AvId));
				// if it's from the user we're trying to contact
				// This means they have the HUD attached but deactivated
				// Check the HUD's version
				if (!VersionCheck(HUD_MIN_VERSION, ThisHudVersion)) {	// if minimum version is greater than this HUD's version
					llOwnerSay(llList2CSV([ HUD_MIN_VERSION, ThisHudVersion]));///%%%
					MessageObject(Id, HUD_MESSAGE_VERSIONFAIL);	// Tell HUD to detach itself
					llDialog(AvId, "Your RezMela HUD seems to be out-of-date.\n\nPlease obtain a new one from the HUD giver.", [ "OK" ], -198238912);
					state Idle;
				}
				llSetTimerEvent(0.0);
				HudId = Id;
				state Normal;
			}
		}
	}
	timer() {
		// We waited for a HUD reply that didn't appear in the timeframe,
		// meaning the user doesn't have a HUD attached
		// Is the user in the region?
		if (UserNotHere()) state Idle;
		// They exist and are in the region
		llDialog(AvId, "\nYou don't seem to have a RezMela HUD.\n\nPlease obtain one from the HUD giver.", [ "OK" ], -198238912);
		state Idle;
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		HandleLinkMessage(Sender, Number, Text, Id, FALSE);
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			if (!ReadConfig()) state Hang;
		}
		if (Change & CHANGED_LINK) MyLinkNum = llGetLinkNumber();
	}
}
state Normal {
	on_rez(integer S) {
		state ResetAfterRez;
	}
	state_entry() {
		Debug("Normal processing");
		MessageHud(HUD_MESSAGE_ACTIVATE,  SetActivateData());
		SendApiMessage(HUD_API_LOGIN, [], AvId);
		StatusType = ST_LOGGING_IN;
		ShowStatus();
		llSetTimerEvent(4.0);
	}
	dataserver(key Id, string Data) {
		if (Id == MyUuid) return;	// we never listen to our own messages
		if (!HandleHudMessage(Id, Data)) state Idle;
	}
	touch_start(integer Count) {
		if (IsClientReady && IsHudReady) {
			while(Count--) {
				key TouchKey = llDetectedKey(Count);
				if (TouchKey == AvId) {
					DisconnectUser();
					state Idle;
				}
				else {
					// Someone else has clicked us
					llRegionSayTo(TouchKey, 0, "Already in use by " + llKey2Name(AvId));
					//					DisconnectUser();
					//					AvId = TouchKey;
					//					state ActivateHud;
				}
			}
		}
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		HandleLinkMessage(Sender, Number, Text, Id, TRUE);
	}
	timer() {
		if (UserNotHere()) {
			DisconnectUser();
			state Idle;
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			if (!ReadConfig()) state Hang;
		}
		if (Change & CHANGED_LINK) MyLinkNum = llGetLinkNumber();
	}
}
state ResetAfterRez {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(2.0);
	}
	timer() {
		llSetTimerEvent(0.0);
		DisconnectUser();
		state Idle;
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			if (!ReadConfig()) state Hang;
		}
		if (Change & CHANGED_LINK) MyLinkNum = llGetLinkNumber();
	}
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
	changed(integer Change) { llResetScript(); }
}
// RezMela HUD server v0.18