
integer BACKGROUND_FACE = 0;
integer STORY_FACE = 1;
integer IMAGE_FACE = 3;
integer PREVIEW_FACE = 4;

integer TEXT_MARGIN_X = 10;
integer TEXT_MARGIN_Y = 12;
integer TEXT_HEIGHT = 64;
integer CANVAS_SIZE = 512;

list Titles;
list Characters;
list Descriptions;
list Times;
list Locations;
list Objects;
list FirstLines;
list PlotTwists;

string FontName;
integer FontSize;
string TextColour;
string BackColour;

Display() {
	llSetColor(<0.941, 1.0, 1.0>, STORY_FACE);
	llSetColor(<0.941, 1.0, 1.0>, IMAGE_FACE);
	llSetTexture(TEXTURE_BLANK, STORY_FACE);
	llSetTexture(TEXTURE_BLANK, IMAGE_FACE);
	string CommandList = "";

	// Background
	CommandList = osSetPenColor(CommandList, BackColour);
	CommandList = osMovePen(CommandList, 0, 0);
	CommandList = osDrawFilledRectangle(CommandList, CANVAS_SIZE, CANVAS_SIZE);

	CommandList += DrawFromList(Titles, 0);

	string Name = llList2String(Characters, 0);
	key ImageId = llList2Key(Characters, 1);
	CommandList += DrawText(Name, 1);

	CommandList += DrawFromList(Descriptions, 2);
	CommandList += DrawFromList(Times, 3);
	CommandList += DrawFromList(Locations, 4);
	CommandList += DrawFromList(Objects, 5);
	CommandList += DrawFromList(FirstLines, 6);
	CommandList += DrawFromList(PlotTwists, 7);

	string ExtraParams = "width:" + (string)CANVAS_SIZE + ",height:" + (string)CANVAS_SIZE;

	osSetDynamicTextureDataBlendFace("", "vector",
		CommandList, ExtraParams,
		FALSE, 2, 0, 0, PREVIEW_FACE);
	key TextureId = llGetTexture(PREVIEW_FACE);
	llSleep(3.0);
	llSetColor(<1.0, 1.0, 1.0>, STORY_FACE);
	llSetColor(<1.0, 1.0, 1.0>, IMAGE_FACE);
	llSetTexture(TextureId, STORY_FACE);
	llSetTexture(ImageId, IMAGE_FACE);
}
string DrawFromList(list List, integer Which) {
	string Text = llList2String(List, 0);
	return DrawText(Text, Which);
}
string DrawText(string Text, integer Which) {
	integer PosX = TEXT_MARGIN_X;
	integer TextHeight = CANVAS_SIZE / 8;
	integer PosY = (TextHeight * Which) + TEXT_MARGIN_Y;
	string CommandList = "";
	integer AvailableWidth = CANVAS_SIZE - (TEXT_MARGIN_X * 2);
	integer RenderFontSize = FontSize;
	while (TextWidth(Text, RenderFontSize) > AvailableWidth && FontSize > 8) {
		RenderFontSize--;
	}
	CommandList = osSetFontName(CommandList, FontName);
	CommandList = osSetFontSize(CommandList, RenderFontSize);
	CommandList = osSetPenColor(CommandList, TextColour);
	CommandList = osMovePen(CommandList, PosX, PosY);
	CommandList = osDrawText(CommandList, Text);
	return CommandList;
}
integer TextWidth(string Text, integer Size) {
	vector V = osGetDrawStringSize("vector", Text, FontName, Size);
	return ((integer)V.x);
}
Init() {
	FontName = "Noto Sans";
	FontSize = 19;
	TextColour = "steelblue";	// #4682b4
	BackColour = "azure"; // #f0ffff
	Titles = [];
	Characters = [];
	Descriptions = [];
	Times = [];
	Locations = [];
	Objects = [];
	FirstLines = [];
	PlotTwists = [];
}
integer GetData() {
	Characters = [];
	integer Len = llGetInventoryNumber(INVENTORY_TEXTURE);
	if (Len <= 2) {
		llOwnerSay("Not enough character images (" + (string)Len + ")!");
		return FALSE;
	}
	integer I;
	for (I = 0; I < Len; I++) {
		string Name = llGetInventoryName(INVENTORY_TEXTURE, I);
		key Image = llGetInventoryKey(Name);
		Characters += [ Name, Image ];
	}
	integer IsOK = TRUE;
	if ((Titles = ReadCard("#Titles")) == []) IsOK = FALSE;
	if ((Descriptions = ReadCard("#Descriptions")) == []) IsOK = FALSE;
	if ((Times = ReadCard("#Times")) == []) IsOK = FALSE;
	if ((Locations = ReadCard("#Locations")) == []) IsOK = FALSE;
	if ((Objects = ReadCard("#Objects")) == []) IsOK = FALSE;
	if ((FirstLines = ReadCard("#First lines")) == []) IsOK = FALSE;
	if ((PlotTwists = ReadCard("#Plot twists")) == []) IsOK = FALSE;
	if (!IsOK) return FALSE;
	Shuffle();
	return TRUE;
}
list ReadCard(string CardName) {
	if (llGetInventoryType(CardName) != INVENTORY_NOTECARD) {
		llOwnerSay("Notecard missing: '" + CardName + "'");
		return [];
	}
	string CardString = osGetNotecard(CardName);
	if (llSubStringIndex(CardString, ";") > -1) {
		llOwnerSay("Semicolon in notecard: '" + CardName + "'. Not a permitted character");
		return [];
	}
	list RawLines = llParseStringKeepNulls(CardString, [ "\n" ], []);
	list Lines = [];
	integer Len = llGetListLength(RawLines);
	integer L;
	for (L = 0; L < Len; L++) {
		string Line = llStringTrim(llList2String(RawLines, L), STRING_TRIM);
		if (Line != "") Lines += Line;
	}
	if (llGetListLength(Lines) <= 2) {
		llOwnerSay("Not enough lines in notecard '" + CardName + "'");
		return [];
	}
	return Lines;
}
Shuffle() {
	Titles = ShuffleList(Titles, 1);
	Characters = ShuffleList(Characters, 2);
	Descriptions = ShuffleList(Descriptions, 1);
	Times = ShuffleList(Times, 1);
	Locations = ShuffleList(Locations, 1);
	Objects = ShuffleList(Objects, 1);
	FirstLines = ShuffleList(FirstLines, 1);
	PlotTwists = ShuffleList(PlotTwists, 1);
}
list ShuffleList(list List, integer Stride) {
	string First = llList2String(List, 0);
	do {
		List = llListRandomize(List, Stride);
	} while (llList2String(List, 0) == First);
	return List;
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		state Normal;
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Init();
		if (!GetData()) state Hang;
		Display();
	}
	touch_start(integer x) {
		if (llDetectedTouchFace(0) == BACKGROUND_FACE) {
			vector ST = llDetectedTouchST(0);
			if (ST.x > 0.019 && ST.x < 0.2 && ST.y > 0.85 && ST.y < 0.913) {
				Shuffle();
			}
			else if (ST.x > 0.14 && ST.x < 0.319) {	// main column of buttons
				integer Which = (integer)((ST.y - 0.0777) / 0.0972);
				if (Which == 7) 		Titles = ShuffleList(Titles, 1);
				else if (Which == 6)	Characters = ShuffleList(Characters, 2);
				else if (Which == 5)	Descriptions = ShuffleList(Descriptions, 1);
				else if (Which == 4)	Times = ShuffleList(Times, 1);
				else if (Which == 3)	Locations = ShuffleList(Locations, 1);
				else if (Which == 2)	Objects = ShuffleList(Objects, 1);
				else if (Which == 1)	FirstLines = ShuffleList(FirstLines, 1);
				else if (Which == 0)	PlotTwists = ShuffleList(PlotTwists, 1);
			}
			Display();
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			if (!GetData()) state Hang;
		}
	}
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			if (GetData()) state Normal;
		}
	}
}