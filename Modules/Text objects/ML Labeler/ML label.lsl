// ML label v1.1.1
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
//
// v1.1.1 - blank prim-drawing textures when rezzed unlinked
// v1.1.0 - fix alpha in 0.9
// v1.0 - version and name change
// v0.11 - add hamburger hiding
// v0.10 - change aspect ratio to square (for clarity of text)
// v0.9 - use new method of touch reserving
// v0.8 - added support for transparent background colour
// v0.7 - fixed occasional timing issue
// v0.6 - added experimental fast load feature
// v0.5 - changed structure, use new method of obtaniing data
// v0.4 - added hamburger menu, many other features
// v0.3 - force refresh on region restart
// v0.2 - pick up text from PRIM_TEXT
//
// Place this in labellable prims (a subset of moveable prims)
//

string CONFIG_NOTECARD = "Labeler config";

float PRIM_SIZE_RATIO = 16.0;	// the aspect ratio of the physical prim

// External Touch Handling (ETH) messages - for scripts in child prims to be able to interpret their own touches
//integer ETH_LOCK = -44912700;        // Send to central script to bypass touch handling
//integer ETH_UNLOCK = -44912701;        // Send to central script to return to normal touch handling
//integer ETH_TOUCHED = -44912702;    // Sent to external script to notify of touch
//integer ETH_PROCESS = -44912703;    // Sent to central script to mimic touch

//integer HEIGHT_PIXELS = 128;    // this is the height of the canvas

string FontName;
integer FontSize;
string ForeColor;
string BackColor;
integer HamburgerHide;			// If TRUE, hamburger face hides on logout
integer HamburgerVisible;      	// Is hamburger visible?
integer HamburgerLineHeight;
integer HamburgerMargin;
integer HamburgerWidth;
integer HamburgerVerticalDistance;

list LabelFaces;	// [ integer FaceNum, string Flip ]

float HamburgerCornerX;
float HamburgerCornerY;

list ForeColors;
list BackColors;

integer HorizontalMargin;    // horizontal margin for text

string LabelText;
key TextureHamburgerOn;
key TextureHamburgerOff;

integer DataRequested;
integer DataReceived;

string RtfFaces;

// Menu stuff
integer MenuChannel;
integer MenuListener;
key AvId;
integer CurrentMenu;

integer MENU_MAIN = 1;
integer MENU_COLOR = 2;
integer MENU_SET_TEXT = 3;

integer MenuColor;
integer MENU_FORE_COLOR = 1;
integer MENU_BACK_COLOR = 2;

string BTN_SET_TEXT = "Set text";
string BTN_FORE_COLOR = "Text color";
string BTN_BACK_COLOR = "Background";
string BTN_CANCEL = "Cancel";
string BTN_BACK = "<< Back";

integer TextboxChannel;
integer TextboxListener;

// Link message number, sent by or to ML main script
integer LM_TOUCH_NORMAL	= -66168300;
integer LM_PRIM_DESELECTED = -405501;
integer LM_SET_LABEL = -405503;
integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_RESERVED_TOUCH_FACE = -44088510;

integer HUD_API_LOGIN = -47206000;
integer HUD_API_LOGOUT = -47206001;

SetTextures(string Text) {
	// Calculate size of rendered text, in pixels
	vector TextSize  = osGetDrawStringSize("vector", Text, FontName, FontSize);
	// Width of text + margins
	integer PixelWidth = (HorizontalMargin * 2) + (integer)TextSize.x;
	// Set the the overall size of the canvas
	integer CanvasSize = 1024;		// for simplicity, we always use 1024x1024
	// Get the centre of the canvas
	integer CenterX = CanvasSize / 2;
	integer CenterY = CanvasSize / 2;    // vertical centre

	// Calculate top-left as offsets from centre based on text size
	integer PosX = CenterX - ((integer)TextSize.x / 2);
	integer PosY = CenterY - ((integer)TextSize.y / 2);

	// If the text is too long, it causes problems with the renderer
	if (PixelWidth > 2048) {
		Text = "Text too long to display";    // so display error message instead
		PosX = HorizontalMargin;
		PixelWidth = 1024;
	}
	// If it's very narrow, make sure it doesn't look strange by keeping it to a minimum width
	if (PixelWidth < 64) PixelWidth = 64;
	// Calculate the severity of the prim slice to accommodate the text
	float TextSizeFactor = (float)PixelWidth / (float)CanvasSize;
	if (TextSizeFactor > 1.0) TextSizeFactor = 1.0;	// it's actually bigger, but just let it overflow (since > 100% doesn't make sense here)
	// Build up the rendering data
	string TextCommandList = TextCommands(Text, CanvasSize, PosX, PosY);
	string HamburgerCommandList = HamburgerCommands(CanvasSize, CenterX, CenterY, TextSizeFactor);
	string ExtraParams = MakeExtraParams(CanvasSize);
	// Render the textures.
	TextureHamburgerOff = RenderTexture(TextCommandList, ExtraParams);
	TextureHamburgerOn = RenderTexture(TextCommandList + HamburgerCommandList, ExtraParams);
	DisplayTextures();
	// Finally, slice the prim
	float SliceAmount = (1.0 - TextSizeFactor) * 0.5;
	if (SliceAmount > 0.47) SliceAmount = 0.47;		// Stop the slicing being too severe (making a very narrow prim)
	llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_SLICE, <1.0 - SliceAmount, SliceAmount, 0.0> ]);
}
string TextCommands(string Text, integer CanvasSize, integer PosX, integer PosY) {
	string CommandList = "";
	// Background
	CommandList = osSetPenColor(CommandList, BackColor);
	CommandList = osMovePen(CommandList, 0, 0);
	CommandList = osDrawFilledRectangle(CommandList, CanvasSize, CanvasSize);
	// Text
	if (Text != "") {
		CommandList = osSetFontName(CommandList, FontName);
		CommandList = osSetFontSize(CommandList, FontSize);
		CommandList = osSetPenColor(CommandList, ForeColor);
		CommandList = osMovePen(CommandList, PosX, PosY);
		CommandList = osDrawText(CommandList, Text);
	}
	return CommandList;
}
string HamburgerCommands(integer CanvasSize, integer CenterX, integer CenterY, float TextSizeFactor) {
	string CommandList = "";
	integer HamX = CenterX + llRound(CanvasSize * TextSizeFactor * 0.5) - HamburgerMargin - HamburgerWidth;
	integer HamY = CenterY - llRound(
		((float)CanvasSize / PRIM_SIZE_RATIO * 0.5)
			) + HamburgerMargin;
	CommandList = osSetPenColor(CommandList, ForeColor);
	integer Ln;
	for (Ln = 0; Ln < 3; Ln++) {
		CommandList = osMovePen(CommandList, HamX, HamY + (HamburgerVerticalDistance * Ln));
		CommandList = osDrawFilledRectangle(CommandList, HamburgerWidth, HamburgerLineHeight);
	}
	// Calculate ST coords of bottom left of hamburger
	// Note that X and Y are transposed because the texture is rotated 90°
	HamburgerCornerY = 1.0 - ((float)(HamX - HamburgerMargin) / (float)CanvasSize);
	integer HamBottom = HamburgerMargin + (HamburgerVerticalDistance * 2) + HamburgerLineHeight;    // pixel coordinates of bottom of hamburger (2 is distance between 3 bars)
	HamburgerCornerX = 0.75;
	return CommandList;
}
string MakeExtraParams(integer CanvasSize) {
	string ExtraParams = "width:" + (string)CanvasSize + ",height:" + (string)CanvasSize;
	if (llGetSubString(BackColor, 0, 1) == "00") {	// if the background colour has 0 alpha (fully transparent)
		ExtraParams += ",alpha:0";	// add in the alpha command
	}
	return ExtraParams;
}
key RenderTexture(string CommandList, string ExtraParams) {
	integer Face = llList2Integer(LabelFaces, 0);	// use only 1st face to render
	osSetDynamicTextureDataBlendFace("", "vector",
		CommandList, ExtraParams,
		FALSE, 2, 0, 255, Face);
	key TextureId = llGetTexture(Face);
	return TextureId;
}
DisplayTextures() {
	key TextureId = TextureHamburgerOff;
	if (HamburgerVisible) TextureId = TextureHamburgerOn;
	if (llGetNumberOfPrims() == 1) TextureId = TEXTURE_BLANK; // blank texture when unlinked
	list Params = [];
	integer L = llGetListLength(LabelFaces);
	integer I;
	for (I = 0; I < L; I += 2) {
		integer Face = llList2Integer(LabelFaces, I);
		string Flip = llList2String(LabelFaces, I + 1);
		float Angle = PI_BY_TWO;
		if (Flip == "n") Angle = -Angle;
		Params += [ PRIM_TEXTURE, Face, TextureId, <1.0, 0.0625, 0.0>, ZERO_VECTOR, Angle ];
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
}
// Set hamburger visibility
SetHamburgerVisibility(integer IsVisible) {
	HamburgerVisible = IsVisible;
	DisplayTextures();
}
ShowMenu(integer WhichMenu) {
	CurrentMenu = WhichMenu;
	string MenuText;
	list Buttons;
	MenuChannel = -10000 - (integer)llFrand(1000000);
	MenuListener = llListen(MenuChannel, "", AvId, "");
	if (CurrentMenu == MENU_MAIN) {
		MenuText = "Select option:";
		Buttons = [ BTN_SET_TEXT, BTN_FORE_COLOR, BTN_BACK_COLOR,
			BTN_CANCEL ];
	}
	else if (CurrentMenu == MENU_COLOR) {
		if (MenuColor == MENU_FORE_COLOR) {
			MenuText = "Select colour for text:";
			Buttons = ColorListButtons(ForeColors);
		}
		else if (MenuColor == MENU_BACK_COLOR) {
			MenuText = "Select colour for background:";
			Buttons = ColorListButtons(BackColors);
		}
	}
	llDialog(AvId, "\n" + MenuText, Buttons, MenuChannel);
}
ProcessMenu(string Input) {
	llListenRemove(MenuListener);
	if (CurrentMenu == MENU_MAIN) {
		if (Input == BTN_SET_TEXT) {
			ShowTextBox("Enter text or blank to cancel:", MENU_SET_TEXT);
		}
		else if (Input == BTN_FORE_COLOR) {
			MenuColor = MENU_FORE_COLOR;
			ShowMenu(MENU_COLOR);
		}
		else if (Input == BTN_BACK_COLOR) {
			MenuColor = MENU_BACK_COLOR;
			ShowMenu(MENU_COLOR);
		}
		// No need to do anything for BTN_CANCEL
	}
	else if (CurrentMenu == MENU_COLOR) {
		if (Input == BTN_BACK) {
			ShowMenu(MENU_MAIN);
			return;
		}
		if (MenuColor == MENU_FORE_COLOR) {
			ForeColor = GetColorFromButton(ForeColors, Input);
		}
		else if (MenuColor == MENU_BACK_COLOR) {
			BackColor = GetColorFromButton(BackColors, Input);
		}
		SaveData();
		SetTextures(LabelText);
	}
}
ShowTextBox(string Text, integer WhichMenu) {
	CurrentMenu = WhichMenu;
	TextboxChannel = -10000 - (integer)llFrand(1000000);
	TextboxListener = llListen(TextboxChannel, "", AvId, "");
	llTextBox(AvId, "\n" + Text, TextboxChannel);
}
ProcessTextBox(string Input) {
	llListenRemove(TextboxListener);
	if (Input != "") {    // ignore empty string, which cancels operation
		if (CurrentMenu == MENU_SET_TEXT) {
			LabelText = Input;
			SetTextures(LabelText);
			SaveData();
		}
	}
}
string GetColorFromButton(list ColorList, string Button) {
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
// Send data to ML for storage
SaveData() {
	string Data = llDumpList2String([ LabelText, FontName, FontSize, ForeColor, BackColor ], "^");
	llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_SET, Data, NULL_KEY);
}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	// Set config defaults
	FontName = "Arial";        // Font attributes
	FontSize = 64;
	ForeColor = "Black";
	BackColor = "White";
	HamburgerHide = TRUE;
	HamburgerLineHeight = 2;
	HamburgerMargin = 4;
	HamburgerWidth = 18;
	HamburgerVerticalDistance = 4;
	LabelFaces = [];
	ForeColors = [];
	BackColors = [];
	HorizontalMargin = -1;
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
					if (Name == "fontname") FontName = Value;
					else if (Name == "fontsize") FontSize = (integer)Value;
					else if (Name == "forecolor") ForeColor = Value;
					else if (Name == "backcolor") BackColor = Value;
					else if (Name == "horizontalmargin") HorizontalMargin = (integer)Value;
					else if (Name == "hidehamburger") HamburgerHide = String2Bool(Value);
					else if (Name == "hamburgerlineheight") HamburgerLineHeight = (integer)Value;
					else if (Name == "hamburgermargin") HamburgerMargin = (integer)Value;
					else if (Name == "hamburgerwidth") HamburgerWidth = (integer)Value;
					else if (Name == "hamburgerverticaldistance") HamburgerVerticalDistance = (integer)Value;
					else if (Name == "labelface") LabelFaces += ParseLabelFaceLine(Value);
					else if (Name == "forecolorlist") ForeColors += Value;
					else if (Name == "backcolorlist") BackColors += Value;
					else llOwnerSay("Invalid keyword in config file: '" + OName + "'");
				}
				else {
					llOwnerSay("Invalid line in config file: " + Line);
				}
			}
		}
	}
	if (LabelFaces == []) {
		llOwnerSay("No label faces specified");
		return FALSE;
	}
	if (HorizontalMargin == -1) HorizontalMargin = FontSize;
	return TRUE;
}
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
// Parse a "labelface" line from the config file
list ParseLabelFaceLine(string Value) {
	list L = llCSV2List(Value);
	integer Face = (integer)llList2String(L, 0);	// face number
	// Indicator for whether to flip the ST coordinates for that face. We'd use 0 and 1 except we want to be able
	// to search by integer for the face. So ... it's "y" and "n".
	string FlipSt = llStringTrim(llToLower(llList2String(L, 1)), STRING_TRIM);
	if (FlipSt != "y" && FlipSt != "n") {
		llOwnerSay("Warning: invalid flip value in config: " + Value);
		FlipSt = "n";
	}
	return [ Face, FlipSt ];
}
// Returns true if click is on a hamburger region
integer HamburgerTouch(integer Face, vector ST) {
	if (!HamburgerVisible) return FALSE;
	integer WhichFace = llListFindList(LabelFaces, [ Face ]);
	if (WhichFace > -1) {
		// They've clicked on a face with a hamburger menu, but have they clicked on the hamburger region?
		// if they've clicked in the hamburger region
		string FlipSt = llList2String(LabelFaces, WhichFace + 1);
		if (FlipSt == "n" && ST.x > HamburgerCornerX && ST.y < HamburgerCornerY) return TRUE;
		else if (FlipSt == "y" && (1.0 - ST.x) > HamburgerCornerX && (1.0 - ST.y) < HamburgerCornerY) return TRUE;
	}
	return FALSE;
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTexture(TEXTURE_BLANK, ALL_SIDES);
		TextureHamburgerOn = TextureHamburgerOff = TEXTURE_BLANK;
		llSetRemoteScriptAccessPin(8000);    // in case we need it
		if (!ReadConfig()) state Hang;
		DataRequested = DataReceived = FALSE;
		RtfFaces = llList2CSV(LabelFaces);
		LabelText = "";
		SetTextures(LabelText);
		SetHamburgerVisibility(TRUE);
	}
	link_message(integer Sender, integer Number, string String, key Id)    {
		if (Number == LM_LOADING_COMPLETE && !DataRequested) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, RtfFaces, NULL_KEY);
			llSetTimerEvent(12.0 + llFrand(6.0));
			DataRequested = TRUE;
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			// The ML is telling us that someone clicked our reserved face. The string portion of the message contains a pipe-delimited
			// list of the following data: face, position, normal, binormal, ST, UV
			list TouchData = llParseStringKeepNulls(String, [ "|" ], []);	// Parse the data into a list of the four different parts
			integer TouchFace = (integer)llList2String(TouchData, 0);
			vector TouchST = (vector)llList2String(TouchData, 4);
			key TouchAv = Id;
			if (HamburgerTouch(TouchFace, TouchST)) {
				AvId = TouchAv;
				ShowMenu(MENU_MAIN);
				return;
			}
			// At this point, they've clicked in a non-menu region of a menu face, so we need to pass that back to the ML main script
			llMessageLinked(LINK_ROOT, LM_TOUCH_NORMAL, llList2CSV(llGetLinkNumber() + TouchData), TouchAv);
		}
		else if (Number == LM_EXTRA_DATA_GET) {
			// We can stop the timer because we have our data, and we also must have sent ETH_LOCK (because the timer has kicked
			// in at least once).
			llSetTimerEvent(0.0);
			DataReceived = TRUE;	// not necessary because the timer stops, but left here in case we need the timer for something else too
			list Elements = llParseStringKeepNulls(String, [ "^" ], []);
			integer ElementsCount = llGetListLength(Elements);
			LabelText = llList2String(Elements, 0);
			if (ElementsCount > 1) {    // if there are >1 parameters, we have font/colour info (otherwise we use default font/colours)
				FontName = llList2String(Elements, 1);
				FontSize = (integer)llList2String(Elements, 2);
				ForeColor = llList2String(Elements, 3);
				BackColor  = llList2String(Elements, 4);
			}

			SetTextures(LabelText);
		}
		else if (Number == HUD_API_LOGIN) {
			SetHamburgerVisibility(TRUE);
		}
		else if (Number == HUD_API_LOGOUT) {
			SetHamburgerVisibility(FALSE);
		}
	}
	// Leaving this here for now (commented out) in case we need to use it later for debugging - this is code so we can test
	// hamburger detection as a standalone object. -- JFH
	//	touch_start(integer total_number)
	//	{
	//		vector TouchST = llDetectedTouchST(0);
	//		integer TouchFace = llDetectedTouchFace(0);
	//		llOwnerSay("Click : " + (string)TouchST.x + ", " + (string)TouchST.y);
	//		llOwnerSay("Corner: " + (string)HamburgerCornerX + ", " + (string)HamburgerCornerY);
	//		if (HamburgerTouch(TouchFace, TouchST))
	//			llOwnerSay("Yes"); else llOwnerSay("No");
	//		llOwnerSay("X:" + (string)(TouchST.x > HamburgerCornerX));
	//		llOwnerSay("Y:" + (string)(TouchST.y < HamburgerCornerY));
	//	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == AvId) {
			ProcessMenu(Message);
		}
		else if (Channel == TextboxChannel && Id == AvId) {
			ProcessTextBox(Message);
		}
	}
	timer() {
		if (!DataReceived) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, RtfFaces, NULL_KEY);
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) SetTextures(LabelText);
	}
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
}
// ML label v1.1.1