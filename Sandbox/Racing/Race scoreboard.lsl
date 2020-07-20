// Race scoreboard v0.1

// Scoreboard prim should be square

// Link Message integer value for messages from finish line script


string FontName = "Arial";
integer FontSize = 24;
integer TOTAL_ROWS = 10;
integer ROW_HEADING = 24;
integer ROW_START = 82;		// beginning of data rows (excl heading)
integer ROW_HEIGHT = 36;

string Heading;
list Lines;

integer CHAT_CHANNEL = -8300371400;

Clear() {
	ResetData();
	llSetTexture(TEXTURE_BLANK, ALL_SIDES);
}
ResetData() {
	Heading = "";
	Lines = [];
}
Display() {
	string CommandList = "";
	CommandList = osSetFontName(CommandList, FontName);
	CommandList = osSetFontSize(CommandList, FontSize);
	CommandList = osSetPenColor(CommandList, "Black");

	CommandList = osMovePen(CommandList, 84, ROW_HEADING);
	CommandList = osDrawText(CommandList, Heading);
	
	integer Sequence = 0;
	integer Ptr;
	for(Ptr = 0; Ptr < TOTAL_ROWS; Ptr++) {
		integer Row = ROW_START + (ROW_HEIGHT * Ptr);
		Sequence++;
		CommandList = osMovePen(CommandList, 46, Row);
		CommandList = osDrawText(CommandList, llList2String(Lines, Ptr));
	}
	osSetDynamicTextureData("", "vector", CommandList, "width:512,height:512", 0 );
}
default
{
	state_entry() {
		state Normal;
	}
}
state Normal {
	state_entry() {
		// Clear display
		Clear();
		llSetTimerEvent(1.0);
	}
	dataserver(key QueryId, string Data) {
		if (Data == "DC") {		// display clear & reset
			Clear();
		}
		else if (Data == "DR") {		// reset data ready for new
			ResetData();
		}		
		else if (llGetSubString(Data, 0, 1) == "DH") {		// set heading
			Heading = llGetSubString(Data, 2, -1);
		}
		else if (llGetSubString(Data, 0, 1) == "DL") {	// Line
			list Parts = llCSV2List(llGetSubString(Data, 2, -1));
			integer Row = (integer)llList2String(Parts, 0);
			string Line = llList2String(Parts, 1);
			Lines = llListReplaceList(Lines, [ Line ], Row, Row);
		}
		else if (Data == "DD") {		// display
			Display();
		}
	}
	timer() {
		llRegionSay(CHAT_CHANNEL, "S");
	}
}
// Race scoreboard v0.1