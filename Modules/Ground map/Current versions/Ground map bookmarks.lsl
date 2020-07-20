// Ground map bookmarks v0.2

// v0.2 - decentralised region start behaviour

integer LM_BOOKMARKS = -451914203;

list Places;

string FONT_NAME = "Arial";        // Font attributes
integer FONT_SIZE = 48;
string TEXT_COLOR = "Black";
string SHADING_COLOR = "LightGray";
integer BUTTON_HEIGHT = 128;
integer TOTAL_WIDTH = 512;
integer TOTAL_HEIGHT = 1024;
integer TEXT_INDENT_X = 10;
integer TEXT_INDENT_Y = 25;
integer BUTTON_COUNT = 8;

Display() {
	string CommandList = "";
	CommandList = osSetFontName(CommandList, FONT_NAME);
	CommandList = osSetFontSize(CommandList, FONT_SIZE);
	CommandList = osSetPenColor(CommandList, TEXT_COLOR);
	integer Len = llGetListLength(Places);
	integer Ptr;
	for (Ptr = 0; Ptr < BUTTON_COUNT; Ptr++) {
		if (Ptr %2) {
			CommandList = osMovePen(CommandList, 0,BUTTON_HEIGHT * Ptr);
			CommandList = osSetPenColor(CommandList, SHADING_COLOR);
			CommandList = osDrawFilledRectangle(CommandList, TOTAL_WIDTH, BUTTON_HEIGHT);
		}
		if (Ptr < Len) {
			CommandList = osMovePen(CommandList, TEXT_INDENT_X,(BUTTON_HEIGHT * Ptr) + TEXT_INDENT_Y);
			CommandList = osSetPenColor(CommandList, TEXT_COLOR);
			CommandList = osDrawText(CommandList, llList2String(Places, Ptr));
		}
	}
	// Render the text
	string Dimensions = "width:" + (string)TOTAL_WIDTH + ",height:" + (string)TOTAL_HEIGHT;
	osSetDynamicTextureData("", "vector", CommandList, Dimensions, 0);
}

default {
	on_rez(integer Param) {
		llResetScript();
	}
	state_entry() {
		llMessageLinked(LINK_SET, -LM_BOOKMARKS, "", NULL_KEY);
	}
	touch_start(integer Count) {
		vector V = llDetectedTouchST(0);
		key Whom = llDetectedKey(0);
		float Where = 1.0 - V.y;
        integer Which = llFloor(Where * (float)BUTTON_COUNT);
		llMessageLinked(LINK_SET, -LM_BOOKMARKS, (string)Which, Whom);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_BOOKMARKS) {
			Places = llCSV2List(String);
			Display();
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) {
			Display();
		}
	}	
}
// Ground map bookmarks v0.2