// ML text display v0.13

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

// v0.13 - doesn't handle long words very well
// v0.12 - multiple hamburger faces, notecard mode, bug fixes
// v0.11 - process hard returns; text formatting mostly rewritten
// v0.10 - allow for multiple image/click faces; allow hamburger suppression to be disabled
// v0.9 - change 'set text' to 'enter text'
// v0.8 - add show/hide hamburger on login
// v0.7 - add config options for centering vertically and horizontally
// v0.6 - add font size menu
// v0.5 - say text in chat when textbox displayed
// v0.4 - add projection capabilities, expose more variables for config card
// v0.3 - put RTF data in "extra data get"
// v0.2 - added support for transparent backgrounds

string CONFIG_NOTECARD = "Text display config";

list ClickFaces;
list ImageFaces;
integer ImageFacesCount;

// Hamburger settings
integer HamburgerHide;			// If TRUE, hamburger face hides on logout
integer HamburgerVisible;      	// Is hamburger visible?
list HamburgerFaces;
integer HamburgerFacesCount;

string SAVE_NEWLINE = "%NEWLINE%";    // what to put in place of "\n" in save notecards
string FORMAT_NEWLINE = "|";
string PRIM_DRAWING_DELIMITER = "|";            // delimiter character for prim-drawing commands

integer Debug = FALSE;

integer NotecardMode;

integer CanvasWidth;           // width of the canvas [pixels]
integer CanvasHeight;        // height of the canvas [pixels]
integer MarginHorizontal;    // size of left and right margins (individually) [pixels]
integer MarginVertical;        // size of top and bottom margins (individually) [pixels]
integer CenterVertical;        // boolean
integer CenterHorizontal;

integer MaxFontSize;    // the largest font size that will be used
string FontName;
string ForeColor;
string BackColor;
float LineSpacing;

list FontNames;
list FontSizes;
list ForeColors;
list BackColors;
integer ManualFontSize;

integer Projector;        // boolean
float LightIntensity;    // 0 to 1
float LightRadius;        // 0 to 20
float LightFalloff;    // 0 to 2
float ProjectorFOV; // 0 to 3
float ProjectorFocus; // -20 to 20
float ProjectorAmbiance; // 0 to 1    (rare/incorrect spelling inherited from LL)

string DefaultText;        // displayed when no other text exists
integer DefaultTextFontSize;

string CurrentText;
integer CurrentFontSize;

integer DataRequested;
integer DataReceived;

string ConfigContents;

// Menu stuff
integer MenuChannel;
integer MenuListener;
key AvId;
integer CurrentMenu;

integer MENU_MAIN = 1;
integer MENU_COLOR = 2;
integer MENU_SET_TEXT = 3;
integer MENU_FONTNAME = 4;
integer MENU_FONTSIZE = 5;

integer MenuColor;
integer MENU_FORE_COLOR = 1;
integer MENU_BACK_COLOR = 2;

string BTN_SET_TEXT = "Enter text";
string BTN_FORE_COLOR = "Text color";
string BTN_BACK_COLOR = "Background";
string BTN_FONTNAME = "Font name";
string BTN_FONTSIZE = "Font size";
string BTN_AUTO_FONTSIZE = "Auto";
string BTN_CANCEL = "Cancel";
string BTN_BACK = "<< Back";

integer TextboxChannel;
integer TextboxListener;

// Link messaage number, sent by ML main script
integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_RESERVED_TOUCH_FACE = -44088510;

integer HUD_API_LOGIN = -47206000;
integer HUD_API_LOGOUT = -47206001;

Display() {
	// First blank the texture
	integer F;
	for (F = 0; F < ImageFacesCount; F++) {
		llSetTexture(TEXTURE_BLANK, llList2Integer(ImageFaces, F));
	}
	// Background
	list Commands = [        // A list of drawing commands (strings) to be rendered
		"PenColor " + BackColor,    // set background colour
		"MoveTo 0,0",                // go to top left
		"FillRectangle " + (string)CanvasWidth + "," + (string)CanvasHeight
			];
	integer TextWidth = 0;        // the width of the text
	integer TextHeight = 0;        // the height of each line of text (including line spacing factor)
	integer TotalHeight = 0;    // total height of all text
	integer LineCount = 0;        // how many lines of text
	list Words = [];            // the words themselves
	// Uncomment this for testing longish text display
	//CurrentText = "With his instantly recognizable gravelly voice, Armstrong was also an influential singer, demonstrating great dexterity as an improviser, bending the lyrics and melody of a song for expressive purposes. He was also very skilled at scat singing.\n\nArmstrong is renowned for his charismatic stage presence and voice almost as much as for his trumpet playing, Armstrong's influence extends well beyond jazz, and by the end of his career in the 1960s, he was widely regarded as a profound influence on popular music in general.\n\nArmstrong was one of the first truly popular African-American entertainers to \"cross over\", whose skin color was secondary to his music in an America that was extremely racially divided at the time. He rarely publicly politicized his race, often to the dismay of fellow African Americans, but took a well-publicized stand for desegregation in the Little Rock crisis. His artistry and personality allowed him socially acceptable access to the upper echelons of American society which were highly restricted for black men of his era.";
	string DisplayText;
	if (NotecardMode) {
		CurrentText = ReadTextNoteCard();
		CurrentFontSize = 0;	// force recalculation in case text has changed
	}
	if (CurrentText == "") {
		DisplayText = DefaultText;
		CurrentFontSize = DefaultTextFontSize;
	}
	else {
		DisplayText = CurrentText;
	}
	integer AvailableWidth = CanvasWidth - (MarginHorizontal * 2);
	integer AvailableHeight = CanvasHeight - (MarginVertical * 2);
	list Lines = [];
	// Format text for rendering
	if (ManualFontSize) {
		CurrentFontSize = ManualFontSize;
	}
	else if (CurrentFontSize == 0) {
		CurrentFontSize = MaxFontSize;    // if we've not calculated font size, we can start trying different fonts starting with the maximum allowed
	}
	// new code start
	DisplayText = ReplaceString(DisplayText, "\n", " " + FORMAT_NEWLINE + " ");
	Words = llParseString2List(DisplayText, [ " ", "    " ], []);
	integer WordCount = llGetListLength(Words);
	integer Break = FALSE;
	// Outer loop repeats if font size needs reduction because of vertical space
	do {
		integer TooWide = FALSE;
		Lines = [];
		string CurrentLine = "";
		TextWidth = 0;
		integer WordPtr;
		for (WordPtr = 0; WordPtr < WordCount; WordPtr++) {
			string Word = llList2String(Words, WordPtr);
			if (Word == FORMAT_NEWLINE) {
				Lines += CurrentLine;
				CurrentLine = "";
			}
			else {	// it's a real word
				// Try to add the word to the current line
				string PotentialLine;
				if (CurrentLine != "") PotentialLine = CurrentLine + " ";
				PotentialLine += Word;
				// Does it overflow?
				if (GetTextWidth(PotentialLine, FontName, CurrentFontSize) > AvailableWidth) {
					// Yes, so start a new line for this word
					if (CurrentLine != "") {
						if (GetTextWidth(CurrentLine, FontName, CurrentFontSize) > AvailableWidth) {
							TooWide = TRUE;
						}
						else {
							Lines += CurrentLine;
							CurrentLine = Word;
						}
					}
					else {	// We have a single word overflowing, so reduce font size
						TooWide = TRUE;
					}
				}
				else {
					// No, so use the potential line
					CurrentLine = PotentialLine;
				}
			}
			integer CurrentLineWidth = GetTextWidth(CurrentLine, FontName, CurrentFontSize);
			if (CurrentLineWidth > TextWidth) TextWidth = CurrentLineWidth;
		}
		if (!TooWide) {	// The text isn't too wide to fit, so check its height
			if (CurrentLine != "") Lines += CurrentLine;	// Last line of text will be here
			LineCount = llGetListLength(Lines);
			integer RawHeight = GetTextHeight("MHL8jy", FontName, CurrentFontSize);   // the height of tall text for this font size
			TextHeight = llFloor((float)RawHeight * LineSpacing);    // get the height of lines including the additional vertical space
			TotalHeight = (LineCount - 1) * TextHeight + RawHeight;        // calculate the total size this text would be (note fence-post calculation)
		}
		if (!ManualFontSize && (TooWide || TotalHeight > AvailableHeight)) {    // if it's too high, drop the font size
			CurrentFontSize--;
			if (CurrentFontSize == 7) return;
		}
		else {
			Break = TRUE;
		}
	}
	while (!Break);
	integer PosX;
	integer PosY;
	if (CenterHorizontal)
		PosX = (CanvasWidth / 2) - (TextWidth / 2);    // offset starting position from the centre
	else
		PosX = MarginHorizontal;
	if (CenterVertical)
		PosY = (CanvasHeight / 2) - ((integer)TotalHeight / 2);    //   point by half the text size on each axis
	else
		PosY = MarginVertical;
	// Set up the text rendering
	Commands += [
		"FontName " + FontName,
		"FontSize " + (string)CurrentFontSize,
		"PenColor " + ForeColor ]
			;
	// Add the text itself
	integer Line;
	for (Line = 0; Line < LineCount; Line++) {
		Commands += [
			"MoveTo " + (string)PosX + "," + (string)(PosY + (Line * TextHeight)),
			"Text " + llList2String(Lines, Line)
				];
	}
	string ExtraParams = "width:" + (string)CanvasWidth + ",height:" + (string)CanvasHeight + ",altdatadelim:" + PRIM_DRAWING_DELIMITER;
	if (llGetSubString(BackColor, 0, 1) == "00") {    // if the background colour has 0 alpha (fully transparent)
		ExtraParams += ",alpha:0";    // add in the alpha command
	}
	// Render the image
	if (Debug) llOwnerSay("Rendering:\n" + llDumpList2String(Commands, "\n"));
	integer FirstImageFace = llList2Integer(ImageFaces, 0);
	osSetDynamicTextureDataBlendFace("", "vector", llDumpList2String(Commands, PRIM_DRAWING_DELIMITER), ExtraParams, FALSE, 2, 0, 0, FirstImageFace);
	key TextureId = llGetTexture(FirstImageFace);
	for (F = 1; F < ImageFacesCount; F++) {
		llSetTexture(TextureId, llList2Integer(ImageFaces, F));
	}
	if (Projector) {
		osSetProjectionParams(TRUE, TextureId, ProjectorFOV, ProjectorFocus, ProjectorAmbiance);
	}
}
integer GetTextHeight(string Text, string FontName, integer FontSize) {
	vector Size = osGetDrawStringSize("vector", Text, FontName, FontSize);
	return (integer)Size.y;
}
integer GetTextWidth(string Text, string FontName, integer FontSize) {
	vector Size = osGetDrawStringSize("vector", Text, FontName, FontSize);
	return (integer)Size.x;
}
string Sanitize(string Text) {
	string NewText = ReplaceString(Text, "|", "?");
	NewText = ReplaceString(NewText, "^", "?");
	NewText = ReplaceString(NewText, PRIM_DRAWING_DELIMITER, "?");
	return NewText;
}
string ReplaceString(string Text, string FromChar, string ToChar) {
	return llDumpList2String(llParseStringKeepNulls(Text, [ FromChar ], []), ToChar);    // based on http://wiki.secondlife.com/wiki/Combined_Library without SL LSL string hack
}
string ReadTextNoteCard() {
	integer CardNum = llGetInventoryNumber(INVENTORY_NOTECARD);
	if (CardNum < 2) {
		return "ERROR\n\nMissing text notecard in notecard mode";
	}
	string NotecardName = llGetInventoryName(INVENTORY_NOTECARD, 0);
	if (NotecardName == CONFIG_NOTECARD) NotecardName = llGetInventoryName(INVENTORY_NOTECARD, 1);
	return osGetNotecard(NotecardName);
}
ShowMenu(integer WhichMenu) {
	CurrentMenu = WhichMenu;
	string MenuText;
	list Buttons;
	MenuChannel = -10000 - (integer)llFrand(1000000);
	MenuListener = llListen(MenuChannel, "", AvId, "");
	if (CurrentMenu == MENU_MAIN) {
		MenuText = "Select option:";
		Buttons = [
			BTN_FORE_COLOR, BTN_BACK_COLOR, BTN_CANCEL,
			BTN_SET_TEXT, BTN_FONTNAME, BTN_FONTSIZE
				];
	}
	else if (CurrentMenu == MENU_FONTNAME) {
		MenuText = "Select font for text:";
		Buttons = FontNames;
	}
	else if (CurrentMenu == MENU_FONTSIZE) {
		string Current = "Auto";
		if (ManualFontSize) Current = (string)ManualFontSize;
		MenuText = "Select font size for text (currently " + Current + "):";
		Buttons = FontSizeButtons(FontSizes);
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
			if (llStringTrim(CurrentText, STRING_TRIM) != "") llRegionSayTo(AvId, 0, "Current text:\n" + CurrentText);
			ShowTextBox("Enter text:", MENU_SET_TEXT);
		}
		else if (Input == BTN_FONTNAME) {
			ShowMenu(MENU_FONTNAME);
		}
		else if (Input == BTN_FONTSIZE) {
			ShowMenu(MENU_FONTSIZE);
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
	else if (CurrentMenu == MENU_FONTNAME) {
		FontName = Input;
		SaveData();
		Display();
	}
	else if (CurrentMenu == MENU_FONTSIZE) {
		if (Input == BTN_AUTO_FONTSIZE)
			ManualFontSize = 0;
		else
			ManualFontSize = (integer)Input;
		SaveData();
		Display();
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
		Display();
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
	if (CurrentMenu == MENU_SET_TEXT) {
		CurrentText = Sanitize(Input);
		CurrentFontSize = 0;    // we don't yet know the optimal font size
		Display();
		SaveData();
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
list FontSizeButtons(list FontSizeList) {
	list Buttons = BTN_AUTO_FONTSIZE + FontSizes;
	Buttons = llList2List(Buttons, -3, -1) + llList2List(Buttons, -6, -4)
		+ llList2List(Buttons, -9, -7) + llList2List(Buttons, -12, -10);
	return Buttons;
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
	string SaveText = "";
	integer SaveFontSize = 0;
	if (CurrentText != DefaultText)    { // We don't save the default text
		SaveText = ReplaceString(CurrentText, "\n", SAVE_NEWLINE);
		SaveFontSize = CurrentFontSize;
	}
	string Data = llDumpList2String([ SaveText, FontName, SaveFontSize, ForeColor, BackColor, ManualFontSize ], "^");
	llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_SET, Data, NULL_KEY);
}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	ConfigContents = osGetNotecard(CONFIG_NOTECARD);    // Save it for detection of changes in changed()
	// Set config defaults
	NotecardMode = FALSE;
	CanvasWidth = 512;    // width of the canvas
	CanvasHeight = 512;    // height of the canvas
	float MarginHorizontalPercent = 20;
	float MarginVerticalPercent = 20;
	CenterVertical = TRUE;
	CenterHorizontal = TRUE;
	FontName = "Arial";        // Font attributes
	MaxFontSize = 128;
	float LineSpacingPercent = 10;
	DefaultText = "";
	DefaultTextFontSize = 0;
	ForeColor = "Black";
	BackColor = "White";
	Debug = FALSE;
	ClickFaces = [ 1 ];
	ImageFaces = [ 3 ];    // face to display text
	HamburgerFaces = [ 2 ];
	HamburgerHide = TRUE;
	Projector = FALSE;
	LightIntensity = 1.0;
	LightRadius = 6.0;
	LightFalloff = 0.0;
	ProjectorFOV = 1.5;
	ProjectorFocus = 10.0;
	ProjectorAmbiance = 0.0;
	FontNames = [];
	FontSizes = [];
	ForeColors = [];
	BackColors = [];
	list Lines = llParseStringKeepNulls(ConfigContents, [ "\n" ], []);
	integer LineCount = llGetListLength(Lines);
	integer I;
	for(I = 0; I < LineCount; I++) {
		string Line = llList2String(Lines, I);
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
					if (Name == "notecardmode") NotecardMode = String2Bool(Value);
					else if (Name == "canvaswidth") CanvasWidth = (integer)Value;
					else if (Name == "canvasheight") CanvasHeight = (integer)Value;
					else if (Name == "horizontalmargin") MarginHorizontalPercent = (float)Value;
					else if (Name == "verticalmargin") MarginVerticalPercent = (float)Value;
					else if (Name == "centerhorizontal") CenterHorizontal = String2Bool(Value);
					else if (Name == "centervertical") CenterVertical = String2Bool(Value);
					else if (Name == "fontname") FontName = Value;
					else if (Name == "maxfontsize" && (integer)Value > 0) MaxFontSize = (integer)Value;
					else if (Name == "linespacing") LineSpacingPercent = (float)Value;
					else if (Name == "defaulttext") DefaultText = Value;
					else if (Name == "defaulttextfontsize") DefaultTextFontSize = (integer)Value;
					else if (Name == "forecolor") ForeColor = Value;
					else if (Name == "backcolor") BackColor = Value;
					else if (Name == "fontlist") FontNames += Value;
					else if (Name == "fontsize") FontSizes += Value;    // yes, as a string
					else if (Name == "forecolorlist") ForeColors += Value;
					else if (Name == "backcolorlist") BackColors += Value;
					else if (Name == "debug" && llToUpper(Value) == "TRUE") Debug = TRUE;
					else if (Name == "clickfaces") ClickFaces = llCSV2List(Value);
					else if (Name == "imagefaces") ImageFaces = llCSV2List(Value);
					else if (Name == "hamburgerfaces") HamburgerFaces = llCSV2List(Value);
					else if (Name == "hidehamburger") HamburgerHide = String2Bool(Value);
					else if (Name == "lightintensity") LightIntensity = (float)Value;
					else if (Name == "lightradius") LightRadius = (float)Value;
					else if (Name == "lightfalloff") LightFalloff = (float)Value;
					else if (Name == "projector") Projector = String2Bool(Value);
					else if (Name == "projectorfov") ProjectorFOV = (float)Value;
					else if (Name == "projectorfocus") ProjectorFocus = (float)Value;
					else if (Name == "projectorambiance" || Name == "projectorambience") ProjectorAmbiance = (float)Value;
					else llOwnerSay("Invalid keyword in config file: '" + OName + "'");
				}
				else {
					llOwnerSay("Invalid line in config file: " + Line);
				}
			}
		}
	}
	ImageFacesCount = llGetListLength(ImageFaces);
	HamburgerFacesCount = llGetListLength(HamburgerFaces);
	MarginHorizontal = llFloor((float)CanvasWidth * MarginHorizontalPercent / 100.0);
	MarginVertical = llFloor((float)CanvasHeight * MarginVerticalPercent / 100.0);
	LineSpacing = 1.0 + LineSpacingPercent / 100.0;
	llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_POINT_LIGHT, Projector, <1.0, 1.0, 1.0>, LightIntensity, LightRadius, LightFalloff ]);
	return TRUE;
}
// Set hamburger visibility
SetHamburgerVisibility(integer IsVisible) {
	if (!HamburgerHide) return;	// We don't hide the hamburger if this is set
	HamburgerVisible = IsVisible;
	float Alpha = 0.0;
	if (IsVisible) Alpha = 1.0;
	integer FacePtr;
	for (FacePtr = 0; FacePtr< HamburgerFacesCount; FacePtr++) {
		integer Face = llList2Integer(HamburgerFaces, FacePtr);
		llSetAlpha(Alpha, Face);
	}
}
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
LogError(string Text) {
	llRegionSay(-7563234, Text);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetRemoteScriptAccessPin(8000);    // in case we need it
		ConfigContents = "";
		CurrentText = "";
		if (!ReadConfig()) state Hang;
		ManualFontSize = 0;
		SetHamburgerVisibility(!NotecardMode);
		Display();
		DataRequested = DataReceived = FALSE;
	}
	// Uncomment this event for standalone testing
	//	touch_start(integer Count) {
	//		HamburgerVisible = TRUE;
	//		llMessageLinked(LINK_THIS, LM_RESERVED_TOUCH_FACE, (string)llList2Integer(ClickFaces, 0), llDetectedKey(0));
	//	}
	link_message(integer Sender, integer Number, string String, key Id)    {
		if (Number == LM_LOADING_COMPLETE && !DataRequested) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, llList2CSV(ClickFaces), NULL_KEY);
			llSetTimerEvent(12.0 + llFrand(6.0));
			AvId = Id;
			DataRequested = TRUE;
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			// The ML is telling us that someone clicked our reserved face. The string portion of the message contains a pipe-delimited
			// list of the following data: face, position, normal, binormal, ST, UV
			if ((HamburgerHide && !HamburgerVisible) || NotecardMode) return;
			list TouchData = llParseStringKeepNulls(String, [ "|" ], []);    // Parse the data into a list of the four different parts
			integer TouchFace = (integer)llList2String(TouchData, 0);
			if (llListFindList(ClickFaces, [  TouchFace ]) > -1) {	// if it's one of the click faces
				AvId = Id;
				ShowMenu(MENU_MAIN);	// show the menu
				return;
			}
		}
		else if (Number == LM_EXTRA_DATA_GET) {
			// We can stop the timer because we have our data, and we also must have sent ETH_LOCK (because the timer has kicked
			// in at least once).
			llSetTimerEvent(0.0);
			DataReceived = TRUE;
			if (String != "") {
				list Elements = llParseStringKeepNulls(String, [ "^" ], []);
				CurrentText = llList2String(Elements, 0);
				FontName = llList2String(Elements, 1);
				CurrentFontSize = (integer)llList2String(Elements, 2);
				ForeColor = llList2String(Elements, 3);
				BackColor  = llList2String(Elements, 4);
				ManualFontSize = (integer)llList2String(Elements, 5);
				CurrentText = ReplaceString(CurrentText, SAVE_NEWLINE, "\n");
				Display();
			}
		}
		else if (Number == HUD_API_LOGIN) {
			if (!NotecardMode) SetHamburgerVisibility(TRUE);
		}
		else if (Number == HUD_API_LOGOUT) {
			if (!NotecardMode) SetHamburgerVisibility(FALSE);
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
	timer() {
		if (!DataReceived) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, llList2CSV(ClickFaces), NULL_KEY);
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) Display();
		if (Change & CHANGED_INVENTORY) {
			string OldConfig = ConfigContents;
			ReadConfig();
			if (NotecardMode) {
				HamburgerVisible = FALSE;	// Notecardmode might have changed
				Display();	// Notecard might have changed
			}
			else if (ConfigContents != OldConfig) {
				Display();        // Redisplay if config file has changed
			}
		}
	}
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
}
// ML text display v0.13


//////////%%%%%%%%%%%%%%%%%%%%%%%%%%%