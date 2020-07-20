// Mailbox v0.2

// v0.2 - added reset on rez

string CONFIG_NOTECARD = "Mailbox config";

string BUTTON_PREV = "<< Prev";
string BUTTON_NEXT = "Next >>";
string BUTTON_DONE = "Done";

integer MAILBOX_CHAT_CHANNEL = -6447600;
integer MenuChannel;

string Channel;

key MenuUser;
integer MenuListener;
integer MenuPage;
integer MenuPageCount;
integer MenuTimeOutCounter;
list CardsList;
integer CardsListSize;
integer MENU_PAGE_SIZE = 9;

MenuInit(key AvId) {
	MenuPage = 0;
	MenuUser = AvId;
	CardsList = [];
	integer Len = llGetInventoryNumber(INVENTORY_NOTECARD);
	integer I;
	for(I = 0; I < Len; I++) {
		string Name = llGetInventoryName(INVENTORY_NOTECARD, I);
		if (Name != CONFIG_NOTECARD) {
			CardsList += Name;
		}
	}
	CardsListSize = llGetListLength(CardsList);
	MenuPageCount = ((CardsListSize - 1)/ MENU_PAGE_SIZE) + 1;
}
ShowMenu() {
	if (MenuPage >= MenuPageCount) MenuPage = MenuPageCount - 1;
	// Pointers to first and last entry on page
	integer P1 = MenuPage * MENU_PAGE_SIZE;
	integer P2 = P1 + MENU_PAGE_SIZE - 1;
	list Buttons = [];
	string MenuText = "\n";
	if (CardsListSize) {
		if (MenuPageCount > 1)
			MenuText += "Page " + (string)(MenuPage + 1) + " of " + (string)MenuPageCount;
		MenuText += " Select:\n\n";
		integer I;
		integer WhichChoice = 1;
		for(I = P1; I <= P2 && I < CardsListSize; I++) {
			MenuText += "   " + (string)WhichChoice + ": " + llList2String(CardsList, I) + "\n";
			Buttons += (string)WhichChoice;
			WhichChoice++;
		}
		while(I <= P2) {
			Buttons += " ";
			I++;
		}
		if (P1 > 0) Buttons += BUTTON_PREV; else Buttons += " ";
		if (P2 < CardsListSize - 1) Buttons += BUTTON_NEXT; else Buttons += " ";
	}
	else {
		MenuText += "(Empty)";
	}
	Buttons += BUTTON_DONE;
	Buttons = llList2List(Buttons, -3, -1) + llList2List(Buttons, -6, -4) + llList2List(Buttons, -9, -7) + llList2List(Buttons, -12, -10);
	MenuListener = llListen(MenuChannel, "", MenuUser, "");
	llDialog(MenuUser, MenuText, Buttons, MenuChannel);
	MenuTimeOutCounter = 60;
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
Clear() {
	integer Count = llGetInventoryNumber(INVENTORY_NOTECARD);
	list L = [];
	integer I;
	for(I = 0; I < Count ; I++) {
		string Name = llGetInventoryName(INVENTORY_NOTECARD, I);
		if (Name != CONFIG_NOTECARD) {
			L += Name;
		}
	}
	Count = llGetListLength(L);
	while(Count--) {
		llRemoveInventory(llList2String(L, 0));
	}
}
default {
	state_entry() {
		MenuChannel = -1000 - (integer)llFrand(100000);
		ReadConfig();
		state Normal;
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }	
	state_entry() {
		llSetTimerEvent(1.0);
	}
	dataserver(key QueryId, string Data) {
		if (Data == "C") {		// display clear & reset
			Clear();
			llResetScript();
		}
		else if (llGetSubString(Data, 0, 0) == "M") {	// if 1st char is M
			string Message = llGetSubString(Data, 1, -1);		// rest of string is message
			list Mail = llParseStringKeepNulls(Message, [ "|" ], []);
			string NotecardName = llList2String(Mail, 0);
			list Lines = llList2List(Mail, 1, -1);
			if (llGetInventoryType(NotecardName) == INVENTORY_NOTECARD) llRemoveInventory(NotecardName);	// remove notecard if it already exists
			osMakeNotecard(NotecardName, Lines);
		}
	}
	touch_start(integer Count) {
		MenuInit(llDetectedKey(0));
		ShowMenu();
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == MenuUser) {
			if (Message == BUTTON_DONE) {
				llListenRemove(MenuListener);
				MenuListener = 0;
				return;
			}
			else if (Message == BUTTON_PREV) {
				if (MenuPage > 0) MenuPage--;
			}
			else if (Message == BUTTON_NEXT) {
				if (MenuPage < (MenuPageCount -1)) MenuPage++;
			}
			else {
				integer C = (integer)Message;
				if (C) {
					integer CardPtr = (MenuPage * MENU_PAGE_SIZE) + C - 1;
					string NotecardName = llList2String(CardsList, CardPtr);
					llGiveInventory(MenuUser, NotecardName);
					llRemoveInventory(NotecardName);
					//llOwnerSay("is: " + NotecardName + " (" + (string)CardPtr + ")");
					return;
				}
			}
			ShowMenu();
		}
	}
	timer() {
		llRegionSay(MAILBOX_CHAT_CHANNEL, "M" + Channel);
		if (MenuListener && MenuTimeOutCounter-- < 0) {
			llListenRemove(MenuListener);
			MenuListener = 0;
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) ReadConfig();
	}
}
// Mailbox v0.2