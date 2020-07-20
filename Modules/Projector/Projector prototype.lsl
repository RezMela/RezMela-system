// projector prototype

string CONFIG_NOTECARD = "Text display config";
integer HAMBURGER_FACE = 0;
integer TEXT_FACE = 5;

string NEWLINE_SUBSTITUTE = "%NEWLINE%";	// what to put in place of "\n" in save notecards
string PRIM_DRAWING_DELIMITER = "|";			// delimiter character for prim-drawing commands

integer Debug = FALSE;

integer CanvasWidth;   		// width of the canvas [pixels]
integer CanvasHeight;    	// height of the canvas [pixels]
integer MarginHorizontal;	// size of left and right margins (individually) [pixels]
integer MarginVertical;		// size of top and bottom margins (individually) [pixels]

integer MaxFontSize;	// the largest font size that will be used
string FontName;
string ForeColor;
string BackColor;
float LineSpacing;

list Fonts;
list ForeColors;
list BackColors;

string DefaultText;		// displayed when no other text exists
integer DefaultTextFontSize;

string CurrentText;
integer FontSize;

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
integer MENU_FONT = 4;

integer MenuColor;
integer MENU_FORE_COLOR = 1;
integer MENU_BACK_COLOR = 2;

string BTN_SET_TEXT = "Set text";
string BTN_FORE_COLOR = "Text color";
string BTN_BACK_COLOR = "Background";
string BTN_FONT = "Font";
string BTN_CANCEL = "Cancel";
string BTN_BACK = "<< Back";

integer TextboxChannel;
integer TextboxListener;

// Link messaage number, sent by ML main script
integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_RESERVED_TOUCH_FACE = -44088510;

Display() {
	llSetTexture(TEXTURE_BLANK, TEXT_FACE);
	// Background
	list Commands = [		// A list of drawing commands (strings) to be rendered
		"PenColor " + BackColor,	// set background colour
		"MoveTo 0,0",				// go to top left
		"FillRectangle " + (string)CanvasWidth + "," + (string)CanvasHeight
			];
	integer TextWidth = 0;		// the width of the text
	integer TextHeight = 0;		// the height of each line of text (including line spacing factor)
	integer TotalHeight = 0;	// total height of all text
	integer LineCount = 0;		// how many lines of text
	list Words = [];			// the words themselves
	// Uncomment this for testing longish text display
	// CurrentText = "With his instantly recognizable gravelly voice, Armstrong was also an influential singer, demonstrating great dexterity as an improviser, bending the lyrics and melody of a song for expressive purposes. He was also very skilled at scat singing. Armstrong is renowned for his charismatic stage presence and voice almost as much as for his trumpet playing, Armstrong's influence extends well beyond jazz, and by the end of his career in the 1960s, he was widely regarded as a profound influence on popular music in general. Armstrong was one of the first truly popular African-American entertainers to \"cross over\", whose skin color was secondary to his music in an America that was extremely racially divided at the time. He rarely publicly politicized his race, often to the dismay of fellow African Americans, but took a well-publicized stand for desegregation in the Little Rock crisis. His artistry and personality allowed him socially acceptable access to the upper echelons of American society which were highly restricted for black men of his era.";
	string DisplayText;
	if (CurrentText == "") {
		DisplayText = DefaultText;
		FontSize = DefaultTextFontSize;
	}
	else {
		DisplayText = CurrentText;
	}
	if (DisplayText != "") {
		// Format text for rendering
		if (FontSize == 0) {
			FontSize = MaxFontSize;	// if we've not calculated font size, we can start trying different fonts starting with the maximum allowed
		}
		integer Break = FALSE;
		do {
			if (Debug) llOwnerSay("Trying font size " + (string)FontSize);
			Words = llParseString2List(DisplayText, [ " ", "	" ], []);
			// Can we split the text into more lines?
			Words = TextWrap(Words, FontSize, CanvasWidth - (MarginHorizontal * 2), 0);
			if (Words == []) {
				FontSize--;
				if (FontSize == 0) return;
				if (Debug) llOwnerSay("Too wide, dropping to " + (string)FontSize);
			}
			else {
				string RenderText = Words2String(Words);
				vector RenderTextSize = osGetDrawStringSize("vector", RenderText, FontName, FontSize);
				vector SingleLineSize = osGetDrawStringSize("vector", DisplayText, FontName, FontSize);	// size if the text were all in a single line
				integer RawHeight = (integer)SingleLineSize.y;		// the height of the text in a single line
				TextWidth = (integer)RenderTextSize.x;
				LineCount = GetNumberOfLines(Words);	// Count the number of lines of text
				TextHeight = llFloor((float)RawHeight * LineSpacing);	// get the height of lines including the additional vertical space
				TotalHeight = (LineCount - 1) * TextHeight + RawHeight;		// calculate the total size this text would be (note fence-post calculation)
				if (TotalHeight > CanvasHeight - (MarginVertical * 2)) {	// if it's too high, drop the font size
					FontSize--;
					if (FontSize == 0) return;
					if (Debug) llOwnerSay("Too tall, dropping to " + (string)FontSize);
				}
				else {
					Break = TRUE;
				}
			}
		} while (!Break);
	}
	else {	// No text, just a blank canvas
		Words = [ ];
		LineCount = 0;
	}
	integer PosX = (CanvasWidth / 2) - (TextWidth / 2);	// offset starting position from the centre
	integer PosY = (CanvasHeight / 2) - ((integer)TotalHeight / 2);	//   point by half the text size on each axis
	// Set up the text rendering
	Commands += [
		"FontName " + FontName,
		"FontSize " + (string)FontSize,
		"PenColor " + ForeColor ]
			;
	// Add the text itself
	list Lines = FormatLines(Words);
	integer Line;
	for (Line = 0; Line < LineCount; Line++) {
		if (Debug) llOwnerSay("Drawing line " + (string)Line + ": " + llList2String(Lines, Line));
		Commands += [
			"MoveTo " + (string)PosX + "," + (string)(PosY + (Line * TextHeight)),
			"Text " + llList2String(Lines, Line)
				];
	}
	string ExtraParams = "width:" + (string)CanvasWidth + ",height:" + (string)CanvasHeight + ",altdatadelim:" + PRIM_DRAWING_DELIMITER;
	if (llGetSubString(BackColor, 0, 1) == "00") {	// if the background colour has 0 alpha (fully transparent)
		ExtraParams += ",alpha:0";	// add in the alpha command
	}
	// Render the image
	if (Debug) llOwnerSay("Rendering:\n" + llDumpList2String(Commands, "\n"));
	osSetDynamicTextureDataBlendFace("", "vector", llDumpList2String(Commands, PRIM_DRAWING_DELIMITER), ExtraParams, FALSE, 2, 0, 0, TEXT_FACE);
	key TextureId = llGetTexture(TEXT_FACE);
	float FOV = 1.5; // Values 0.00 - 3.00
	float Focus = 10.0; // Values -20.00 - 20.00
	float Ambiance = 0.0; // Values 0.00 - 1.00
	osSetProjectionParams(TRUE, TextureId, FOV, Focus, Ambiance);
}
list TextWrap(list Words, integer FontSize, integer Width, integer Recursion) {
	if (Recursion > 400) {
		llOwnerSay("WARNING: Recursion detected in text drawing!");
		return [];
	}
	list NewWords = [];
	integer WordsLen = llGetListLength(Words);
	if (WordsLen == 0 && Debug) llOwnerSay("Unexpected zero-length lest!!!");
	if (WordsLen == 0) return [];
	integer SplitPoint = 0;
	integer Break = FALSE;
	do {
		list LineWords = llList2List(Words, 0, SplitPoint);	// the words on this line
		vector Size = osGetDrawStringSize("vector", Words2String(LineWords), FontName, FontSize);
		//llOwnerSay("Wrap check: '" + llDumpList2String(LineWords, " ") + "' (" + (string)llFloor(Size.x) + ") against " + (string)Width);
		if ((integer)Size.x <= Width) {	// this will fit
			SplitPoint++;	// So try another word
			if (SplitPoint == WordsLen) {	// we've got to the end
				if (Debug) llOwnerSay("At the end of the text, we have " + llDumpList2String(Words, " "));
				NewWords = Words;
				Break = TRUE;
			}
		}
		else {
			// We've gone beyond the limit
			SplitPoint--;	// Because we've gone beyond the edge
			if (llGetListLength(LineWords) > 1) {	// if there's more than one word on this line
				NewWords = llList2List(LineWords, 0, SplitPoint);	// delete the last word (the one that made it overflow)
				if (Debug) llOwnerSay("Parsed line:        [" + llDumpList2String(NewWords, " ") + "]");
			}
			else {	// one word is too long for the line
				if (Debug) llOwnerSay("One word too long: " + llList2String(LineWords, 0));
				return [];
			}
			if (SplitPoint < WordsLen - 1) {	// there are still words to come
				SplitPoint++;
				if (Debug) llOwnerSay("Recursing for: " + llDumpList2String(llList2List(Words, SplitPoint, -1), " "));
				list NextPart = TextWrap(llList2List(Words, SplitPoint, -1), FontSize, Width, Recursion + 1);
				if (NextPart == []) {	// if text is too wide
					return [];			// return null to indicate this
				}
				// A note here about the use of "\n" to denote text wrapping. Originally this was because the text was rendered
				// as it was wrapped, newlines and all, to make multi-line text. But we weren't happy with the way OpenSim was
				// rendering text over multiple lines (vertical spacing was too small) so I changed it to the current line-by-line
				// rendering. So now "\n" only serves as an indicator of a line break, and could actually be anything.
				// It would even be possible to avoid inserting these indicators, and instead maintain a table of where in the list
				// of words line breaks should occur (ie a list of pointers), but since it's working this way now it's hard to justify
				// the extra time to refactor everything. -- JFH
				NewWords += [ "\n" ] + NextPart;
			}
			else {
				if (Debug) llOwnerSay("No more words");
			}
			Break = TRUE;
		}
	} while(!Break);
	return NewWords;
}
integer GetNumberOfLines(list Words) {
	integer LineCount = 1;	// Always at least one line
	integer P = llGetListLength(Words);
	while(P--) {
		if (llList2String(Words, P) == "\n") LineCount++;
	}
	return LineCount;
}
// Returns the words list, one per line
list FormatLines(list Words) {
	list Lines = [];
	string CurrentLine = "";
	integer WordCount = llGetListLength(Words);
	integer I;
	for(I = 0; I < WordCount; I++) {
		string Word = llList2String(Words, I);
		if (Word == "\n") {
			Lines += llGetSubString(CurrentLine, 0, -2);	// substring because we strip the final " "
			CurrentLine = "";
		}
		else {
			CurrentLine += Word + " ";
		}
	}
	Lines += CurrentLine;
	return Lines;
}
// "\n" will have been converted to " \n " (with spaces), so remedy that (more efficient as a string function than a list function)
string Words2String(list Words) {
	string Str = llDumpList2String(Words, " ");
	integer I;
	while ((I = llSubStringIndex(Str, " \n ")) > -1) {
		Str = llGetSubString(Str, 0, I - 1) + "\n" + llGetSubString(Str, I + 3, -1) ;
	}
	return Str;
}
string Sanitize(string Text) {
	string NewText = ReplaceString(Text, "|", "?");
	NewText = ReplaceString(NewText, "^", "?");
	NewText = ReplaceString(NewText, PRIM_DRAWING_DELIMITER, "?");
	return NewText;
}
string ReplaceString(string Text, string FromChar, string ToChar) {
	return llDumpList2String(llParseStringKeepNulls(Text, [ FromChar ], []), ToChar);	// based on http://wiki.secondlife.com/wiki/Combined_Library without SL LSL string hack
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
			BTN_FONT, BTN_FORE_COLOR, BTN_BACK_COLOR,
			BTN_SET_TEXT, BTN_CANCEL
				];
	}
	else if (CurrentMenu == MENU_FONT) {
		MenuText = "Select font for text:";
		Buttons = Fonts;
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
			ShowTextBox("Enter text:", MENU_SET_TEXT);
		}
		else if (Input == BTN_FONT) {
			ShowMenu(MENU_FONT);
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
	else if (CurrentMenu == MENU_FONT) {
		FontName = Input;
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
		FontSize = 0;	// we don't yet know the optimal font size
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
	if (CurrentText != DefaultText)	{ // We don't save the default text
		SaveText = ReplaceString(CurrentText, "\n", NEWLINE_SUBSTITUTE);
		SaveFontSize = FontSize;
	}
	string Data = llDumpList2String([ SaveText, FontName, SaveFontSize, ForeColor, BackColor ], "^");
	llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_SET, Data, NULL_KEY);
}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	ConfigContents = osGetNotecard(CONFIG_NOTECARD);	// Save it for detection of changes in changed()
	// Set config defaults
	CanvasWidth = 512;    // width of the canvas
	CanvasHeight = 512;    // height of the canvas
	float MarginHorizontalPercent = 20;
	float MarginVerticalPercent = 20;
	FontName = "Arial";        // Font attributes
	MaxFontSize = 128;
	float LineSpacingPercent = 10;
	DefaultText = "";
	DefaultTextFontSize = 0;
	ForeColor = "Black";
	BackColor = "White";
	Debug = FALSE;
	Fonts = [];
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
					if (Name == "canvaswidth") CanvasWidth = (integer)Value;
					else if (Name == "canvasheight") CanvasHeight = (integer)Value;
					else if (Name == "horizontalmargin") MarginHorizontalPercent = (float)Value;
					else if (Name == "verticalmargin") MarginVerticalPercent = (float)Value;
					else if (Name == "fontname") FontName = Value;
					else if (Name == "maxfontsize" && (integer)Value > 0) MaxFontSize = (integer)Value;
					else if (Name == "linespacing") LineSpacingPercent = (float)Value;
					else if (Name == "defaulttext") DefaultText = Value;
					else if (Name == "defaulttextfontsize") DefaultTextFontSize = (integer)Value;
					else if (Name == "forecolor") ForeColor = Value;
					else if (Name == "backcolor") BackColor = Value;
					else if (Name == "fontlist") Fonts += Value;
					else if (Name == "forecolorlist") ForeColors += Value;
					else if (Name == "backcolorlist") BackColors += Value;
					else if (Name == "debug" && llToUpper(Value) == "TRUE") Debug = TRUE;
					else llOwnerSay("Invalid keyword in config file: '" + OName + "'");
				}
				else {
					llOwnerSay("Invalid line in config file: " + Line);
				}
			}
		}
	}
	MarginHorizontal = llFloor((float)CanvasWidth * MarginHorizontalPercent / 100.0);
	MarginVertical = llFloor((float)CanvasHeight * MarginVerticalPercent / 100.0);
	LineSpacing = 1.0 + LineSpacingPercent / 100.0;
	return TRUE;
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetRemoteScriptAccessPin(8000);    // in case we need it
		ConfigContents = "";
		if (!ReadConfig()) state Hang;
		Display();
		//llSetTexture(TEXTURE_BLANK, TEXT_FACE);
		DataRequested = DataReceived = FALSE;
	}
	// Uncomment this event for standalone testing
	//	touch_start(integer Count) {
	//		llMessageLinked(LINK_THIS, LM_RESERVED_TOUCH_FACE, (string)HAMBURGER_FACE, llDetectedKey(0));
	//	}
	link_message(integer Sender, integer Number, string String, key Id)    {
		if (Number == LM_LOADING_COMPLETE && !DataRequested) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, (string)HAMBURGER_FACE, NULL_KEY);
			llSetTimerEvent(12.0 + llFrand(6.0));
			DataRequested = TRUE;
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			// The ML is telling us that someone clicked our reserved face. The string portion of the message contains a pipe-delimited
			// list of the following data: face, position, normal, binormal, ST, UV
			list TouchData = llParseStringKeepNulls(String, [ "|" ], []);	// Parse the data into a list of the four different parts
			integer TouchFace = (integer)llList2String(TouchData, 0);
			if (TouchFace == HAMBURGER_FACE) {
				AvId = Id;
				ShowMenu(MENU_MAIN);
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
				FontSize = (integer)llList2String(Elements, 2);
				ForeColor = llList2String(Elements, 3);
				BackColor  = llList2String(Elements, 4);
				CurrentText = ReplaceString(CurrentText, NEWLINE_SUBSTITUTE, "\n");
				Display();
			}
		}
	}
	touch_start(integer total_number)
	{
		if (llDetectedTouchFace(0) == HAMBURGER_FACE) {
			AvId = llDetectedKey(0);
			ShowMenu(MENU_MAIN);
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
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, (string)HAMBURGER_FACE, NULL_KEY);
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) Display();
		if (Change & CHANGED_INVENTORY) {
			string OldConfig = ConfigContents;
			ReadConfig();
			if (ConfigContents != OldConfig) Display();		// Redisplay if config file has changed
		}
	}
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
}
// ML text display v0.3