
integer HEIGHT_PIXELS = 128;	// this is the height of the canvas
string FONT_NAME = "Arial";		// Font attributes
integer FONT_SIZE = 24;
string TEXT_COLOR = "Black";
integer HorizontalMargin = 10;	// minimum horizontal margin for text

string Desc;

SetText(string Text) {
	//			llOwnerSay("CenterX=" + (string)CenterX + ", TextSize.x=" + (string)TextSize.x + ", PosX=" + (string)PosX);
	string TextColor = TEXT_COLOR;
	// If the text is too long, it causes problems with the renderer
	// Build up the rendering data
	string CommandList = "";
	CommandList = osSetFontName(CommandList, FONT_NAME);
	CommandList = osSetFontSize(CommandList, FONT_SIZE);
	CommandList = osSetPenColor(CommandList, TextColor);
	CommandList = osMovePen(CommandList, 10,10);
	CommandList = osDrawText(CommandList, Text);
	// Render the text
	string Dimensions = "width:" + (string)256 + ",height:" + (string)64;
	osSetDynamicTextureData("", "vector", CommandList, Dimensions, 0);
}

default {
	state_entry() {
		llSetTimerEvent(5.0);
	}
	timer() {
		string NDesc = llGetObjectDesc();
		if (NDesc != Desc) {
			Desc = NDesc;
			list L = llCSV2List(Desc);
			string T = llList2String(L, 0);
			SetText(T);
		}
	}
	changed(integer Change)	{
		if (Change & CHANGED_REGION_START) Desc = "";
	}
}