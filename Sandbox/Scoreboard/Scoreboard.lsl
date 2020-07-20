// Race scoreboard v0.5

// Scoreboard prim should be square

// v0.5 - added redisplay on region restart
// v0.4 - added reset on rez
// v0.3 - duplicated osSetDynamicTextureData() call
// v0.2 - added channels

string CONFIG_NOTECARD = "Scoreboard config";
string Channel;

string FontName = "Arial";
integer FontSize = 24;
integer TOTAL_ROWS = 10;
integer ROW_HEADING = 24;
integer ROW_START = 82;		// beginning of data rows (excl heading)
integer ROW_HEIGHT = 36;

string Heading;
list Lines;

integer SCOREBOARD_CHAT_CHANNEL = -6447330;

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
	// doing this twice seems to speed up texture download for some reason
	osSetDynamicTextureData("", "vector", CommandList, "width:512,height:512", 0 );
	osSetDynamicTextureData("", "vector", CommandList, "width:512,height:512", 0 );
}
ReadConfig() {
	// Set config defaults
	Channel = "[None]";
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Can't find notecard '" + CONFIG_NOTECARD + "'");
		return;
	}
	integer Lines = osGetNumberOfNotecardLines(CONFIG_NOTECARD);
	integer I;
	for(I = 0; I < Lines; I++) {
		string Line = osGetNotecardLine(CONFIG_NOTECARD, I);
		integer Comment = llSubStringIndex(Line, "//");
		if (Comment != 0) {	// Not a complete comment line
			if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);	// strip from comments characters onwards
			if (llStringTrim(Line, STRING_TRIM) != "") {	// if there's something left after comments are removed
				// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
				list L = llParseStringKeepNulls(Line, [ "=" ], [ ]);	// Separate LHS and RHS of assignment
				if (llGetListLength(L) == 2) {	// so there is a "X = Y" kind of syntax
					string OName = llStringTrim(llList2String(L, 0), STRING_TRIM);		// original parameter name
					string Name = llToLower(OName);		// lower-case version for case-independent parsing
					string Value = llStringTrim(llList2String(L, 1), STRING_TRIM);
					// Interpret name/value pairs
					if (Name == "channel")	Channel = StripQuotes(Value, Line);
					else llOwnerSay("Invalid parameter name in '" + CONFIG_NOTECARD + "': " + OName);
				}
				else {
					llOwnerSay("Invalid line in '" + CONFIG_NOTECARD + "': " + Line);
				}
			}
		}
	}
}
// Takes a string in double quotes, and strips out the quotes. Validates the format.
// <Text> is the string with quotes; <Line> is the entire line for error reporting
string StripQuotes(string Text, string Line) {
	if (Text == "") {	// allow empty string for null value
		return("");
	}
	if (llGetSubString(Text, 0, 0) == "\"" && llGetSubString(Text, -1, -1) == "\"") { 	// if surrounded by quotes
		return(llGetSubString(Text, 1, -2));	// strip quotes
	}
	else {
		llOwnerSay("Invalid string literal (missing \"\"?): " + Line);
		return("");
	}
}
default
{
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		ReadConfig();
		state Normal;
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
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
		llRegionSay(SCOREBOARD_CHAT_CHANNEL, "S" + Channel);
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) ReadConfig();
		if (Change & CHANGED_REGION_START) Display();
	}	
}
// Race scoreboard v0.5