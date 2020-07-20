// Nutrition race scoreboard v0.2

// Scoreboard prim should have aspect ratio of 2:1

// Link Message integer value for messages from finish line script
integer LM_SCOREBOARD = -2901900;

string FontName = "Arial";
integer FontSize = 24;

default
{
	state_entry() {
		state Normal;
	}
}
state Normal {
	state_entry() {
		// Clear display
		llSetTexture(TEXTURE_BLANK, ALL_SIDES);
	}
	link_message(integer From, integer Num, string Str, key Key) {
		if (Num == LM_SCOREBOARD) {
			if (Str == "") {
				// An empty string signals to clear display
				llSetTexture(TEXTURE_BLANK, ALL_SIDES);
			}
			else {
				// List winners
				list Winners = llParseStringKeepNulls(Str, [ "," ], []);
				string CommandList = "";
				CommandList = osSetFontName(CommandList, FontName);
				CommandList = osSetFontSize(CommandList, FontSize);

				CommandList = osSetPenColor(CommandList, "DarkOrange");

				CommandList = osMovePen(CommandList, 46, 10);
				CommandList = osDrawText(CommandList, "1:");
				CommandList = osMovePen(CommandList, 46, 44);
				CommandList = osDrawText(CommandList, "2:" );
				CommandList = osMovePen(CommandList, 46, 78);
				CommandList = osDrawText(CommandList, "3:");

				CommandList = osSetPenColor(CommandList, "MidnightBlue");

				CommandList = osMovePen(CommandList, 84, 10);
				CommandList = osDrawText(CommandList, llList2String(Winners, 0));
				CommandList = osMovePen(CommandList, 84, 44);
				if (llGetListLength(Winners) > 1)
					CommandList = osDrawText(CommandList, llList2String(Winners, 1));
				CommandList = osMovePen(CommandList, 84, 78);
				if (llGetListLength(Winners) > 2)
					CommandList = osDrawText(CommandList, llList2String(Winners, 2));
				
				osSetDynamicTextureData("", "vector", CommandList, "width:512,height:128", 0 );
			}
		}
	}
}
// Nutrition race scoreboard v0.2