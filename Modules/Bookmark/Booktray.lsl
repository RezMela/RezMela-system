// ML booktray v0.4

// v0.4 - streamlined loading some more
// v0.3 - various bug fixes to do with loading/reloading timing issues
// v0.2 - wait for loading to complete before locking

string CONFIG_NOTECARD = "Booktray config";

string BooktrayObjectName;
list MenuFaces;
list MenuRegionsStartS;
list MenuRegionsEndS;
list MenuRegionsStartT;
list MenuRegionsEndT;

// LMs to/from ML main script
integer LM_LOADING_COMPLETE = -405530;
integer LM_TOUCH_NORMAL	= -66168300;
integer LM_RESERVED_TOUCH_FACE = -44088510;

// Booktray-specific LMs
integer BOTR_MENU = -5519150700;

// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	// Set config defaults
	BooktrayObjectName = "";
	MenuFaces = [];
	MenuRegionsStartS = [];
	MenuRegionsEndS = [];
	MenuRegionsStartT = [];
	MenuRegionsEndT = [];
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
					if (Name == "objectname") {
						BooktrayObjectName = StripQuotes(Value, Line);
					}
					else if (Name == "menu") {
						// Format is: Menu = <face>, <from x>, <to x>, <from y>, <to y>
						list Params = llCSV2List(Value);
						if (llGetListLength(Params) == 5) {
							MenuFaces += (integer)llList2String(Params, 0);
							MenuRegionsStartS += (float)llList2String(Params, 1);
							MenuRegionsEndS += (float)llList2String(Params, 2);
							MenuRegionsStartT += (float)llList2String(Params, 3);
							MenuRegionsEndT += (float)llList2String(Params, 4);
						}
						else {
							llOwnerSay("Invalid Menu entry in config file: " + Value);
						}
					}
					else llOwnerSay("Invalid keyword in config file: '" + OName + "'");
				}
				else {
					llOwnerSay("Invalid line in config file: " + Line);
				}
			}
		}
	}
	if (BooktrayObjectName == "") {
		llOwnerSay("No object name in config file");
		return FALSE;
	}
	if (!llGetListLength(MenuFaces)) {
		llOwnerSay("No menu layout data");
		return FALSE;
	}
	return TRUE;
}
//     Takes a string in double quotes, and strips out the quotes. Validates the format.
// <Text> is the string with quotes; <Line> is the entire line for error reporting
string StripQuotes(string Text, string Line) {
	if (Text == "") {    // allow empty string
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
default {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		if (!ReadConfig()) return;
	}
	timer() {
		llSetTimerEvent(0.0);
		// Send message to touch handler telling it that we need to know about touch events
		if (llGetNumberOfPrims() > 1) llMessageLinked(LINK_ROOT, LM_RESERVED_TOUCH_FACE, llList2CSV(MenuFaces), NULL_KEY);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_RESERVED_TOUCH_FACE) {
			list TouchData = llParseStringKeepNulls(String, [ "|" ], []);	// Parse the data into a list of the four different parts
			integer TouchFace = (integer)llList2String(TouchData, 0);
			integer WhichMenu = llListFindList(MenuFaces, [ TouchFace ]);
			if (WhichMenu > -1) {
				// They've clicked on a face with a hamburger menu, but have they clicked on the hamburger region?
				float StartS = llList2Float(MenuRegionsStartS, WhichMenu);
				float EndS = llList2Float(MenuRegionsEndS, WhichMenu);
				float StartT = llList2Float(MenuRegionsStartT, WhichMenu);
				float EndT = llList2Float(MenuRegionsEndT, WhichMenu);
				vector TouchST = (vector)llList2String(TouchData, 4);
				// if they've clicked in the hamburger region
				if (TouchST.x >= StartS && TouchST.x <= EndS && TouchST.y >= StartT && TouchST.y <= EndT) {
					// tell the ML bookmark comms server to give the menu, etc
					String = BooktrayObjectName + "|" + String;
					llMessageLinked(LINK_ROOT, BOTR_MENU, String, Id);
					return;
				}
			}
			// Pass touch back to ML
			llMessageLinked(LINK_ROOT, LM_TOUCH_NORMAL, llList2CSV(llGetLinkNumber() + TouchData), Id);
		}
		else if (Number == LM_LOADING_COMPLETE) {	// ML has finished loading everything and is ready to receive commands
			if (String == "1") 	// we don't need to slow down loading because we've been individually created
				llSetTimerEvent(0.1);    // actually 0.5, but we can dream ...
			else
				llSetTimerEvent(4.0 + llFrand(6.0));
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llResetScript();
	}
}
// ML booktray v0.4