// Blue menu controller v1.0.3

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

// v1.0.3 - fixed spurious timeout on textbox; removed timeout message

// TODO:
// Add code for setting back, prev, next button texts
// Allow a title to be set?
// Allow menu desription to be changed
// Allow multiple close menu/option pairs
// Remove old menu if existing menu added again?

integer MENU_RANGE_S	= -291044300;
integer MENU_RESET 		= -291044301;
integer MENU_ADD 	 	= -291044302;
integer MENU_SETVALUE 	= -291044303;
integer MENU_START 		= -291044304;
integer MENU_RESPONSE	= -291044305;
integer MENU_TEXTBOX	= -291044306;
integer MENU_RANGE_E	= -291044399;

list SourceList = [];

integer SourcePtr = -1; // pointer to current menu sub-list within SourceList
integer PagePtr = 0; // pointer to current page within current menu (added to SourcePtr)
integer ListenChannel = -1;
integer SourceLength = 0;
integer ListenerId = 0;
list Stack = []; // return stack, comprising points to SourceList for parent menus
integer IsTextBox = FALSE;

key AvId = NULL_KEY;
integer LinkNum = LINK_THIS;

string ButtonBack;
string ButtonPrev;
string ButtonNext;
integer Persist;
string CloseMenu;
string CloseOption;

StartMenu() {
	SourcePtr = 0;
	PagePtr = 0;
	Stack = [];
	SourceLength = llGetListLength(SourceList);
	ShowMenu();
}
StartTextbox(string Text) {
	IsTextBox = TRUE;
	SetListener();
	llTextBox(AvId, "\n\n" + Text, ListenChannel);
}
ShowMenu() {
	RemoveListener();
	string MenuName = GetMenuName();
	string MenuText = llList2String(SourceList, SourcePtr + 1);
	string Message = "\n        " + llToUpper(MenuName) + "\n\n" + MenuText;
	list Options = [];
	integer SourceOptionsPtr = SourcePtr + 2; // pointer to start of options in source list
	integer P = SourceOptionsPtr;
	do {
		string Entry = llList2String(SourceList, P);
		if (Entry == "*") Entry = ButtonBack;
		else if (llGetSubString(Entry, 0, 0) == "*") {
			Entry = llGetSubString(Entry, 1, -1);
		}
		Options += Entry;
		P++;
	} while (llGetSubString(llList2String(SourceList, P), 0, 0) != "!" && P < SourceLength);
	integer CurrentMenuLength = llGetListLength(Options);
	if (CurrentMenuLength > 12) {
		string ThisBack = " ";
		if (llList2String(Options, -1) == ButtonBack) { // if last option on this menu is "back"
			// A special case: if the last option is "back" we put a back button on the bottom row, not at the end of options
			ThisBack = ButtonBack;
			Options = llList2List(Options, 0, -2);
		}
		integer PageCount = CurrentMenuLength / 9; // number of sub-pages for this menu
		if (PagePtr < 0) PagePtr = 0; // prevent underflow
		integer PageEnd = PagePtr + 8; // 3 rows of actual option (start at zero)
		if (PageEnd > CurrentMenuLength) { // prevent overflow
			PageEnd = CurrentMenuLength;
			PagePtr = PageEnd - 9;
		}
		string ThisPrev = " "; if (PagePtr > 0) ThisPrev = ButtonPrev;
		string ThisNext = " "; if (PageEnd < CurrentMenuLength) ThisNext = ButtonNext;
		Options = llList2List(Options, PagePtr, PageEnd) + [ ThisBack, ThisPrev, ThisNext ];

	}
	// Rearrange the buttons into LL's silly design
	Options = llList2List(Options, -3, -1) + llList2List(Options, -6, -4)
		+ llList2List(Options, -9, -7) + llList2List(Options, -12, -10);
	IsTextBox = FALSE;
	SetListener();
	llDialog(AvId, Message, Options, ListenChannel);
}
list ProcessSelection(integer Channel, key Id, string Text) {
	if (Channel != ListenChannel || Id != AvId) return [];
	RemoveListener();
	// Interpret special options
	if (Text == ButtonBack) {
		Text = "*"; // internal representation of back button
	}
	else if (Text == ButtonPrev) {
		PagePtr -= 9;
		ShowMenu();
		return [];
	}
	else if (Text == ButtonNext) {
		PagePtr += 9;
		ShowMenu();
		return [];
	}
	integer SelectedPtr = -1;
	integer P = SourcePtr + 2;
	string Entry = "";
	do {
		Entry = llList2String(SourceList, P);
		if (Entry == Text || Entry == "*" + Text) SelectedPtr = P;
		P++;
	} while (llGetSubString(llList2String(SourceList, P), 0, 0) != "!" && P < SourceLength);
	string SelectedEntry = llList2String(SourceList, SelectedPtr); // the source element they've clicked on
	if (SelectedPtr == -1) {
		llRegionSayTo(AvId, 0, "Error: can't find menu entry: " + Text + " [" + (string)SourcePtr + "]");
		return [];
	}
	if (SelectedEntry == "*") { // it's a "back" menu
		if (Stack == []) {
			llRegionSayTo(AvId, 0, "Error: no stack");
			return [];
		}
		// Pop one off the return stack
		SourcePtr = llList2Integer(Stack, -1);
		Stack = llDeleteSubList(Stack, -1, -1);
		ShowMenu();
		return [];
	}
	if (llGetSubString(SelectedEntry, 0, 0) == "*") { // it's a sub-menu
		string NewMenuEntry = "!" + llGetSubString(SelectedEntry, 1, -1); // text we're looking for
		for (P = 0; P < SourceLength; P++) {
			SelectedEntry = llList2String(SourceList, P);
			if (SelectedEntry == NewMenuEntry) {
				Stack += SourcePtr; // push current menu onto stack
				SourcePtr = P; // set new menu
				PagePtr = 0;
				ShowMenu();
				return [];
			}
		}
		llRegionSayTo(AvId, 0, "Error: can't find sub-menu: " + Text + " [" + (string)SourcePtr + "]");
		return [];
	}
	else { // atomic option
		return [ GetMenuName(), SelectedEntry ]; // pass back the option
	}
}
Reset() {
	ButtonBack = "< Back";
	ButtonPrev = "<<";
	ButtonNext = ">>";
	Persist = FALSE;
	SourceList = [];
	SourceLength = 0;
	CloseMenu = "";
	CloseOption = "";
}
SetListener() {
	RemoveListener();
	ListenChannel = -100000 - (integer)llFrand(10000);
	ListenerId = llListen(ListenChannel, "", AvId, "");
	llSetTimerEvent(300.0); // Remove listener after 5 mins of inactivity
}
RemoveListener() {
	llSetTimerEvent(0.0);
	if (ListenerId > 0) {
		llListenRemove(ListenerId);
		ListenerId = 0;
	}
}
string GetMenuName() {
	return llGetSubString(llList2String(SourceList, SourcePtr), 1, -1);
}
integer ParseBool(string Text) {
	return (llToLower(Text) == "true");
}
default {
	on_rez(integer Param) {
		Reset();
	}
	state_entry() {
		Reset();
	}
	link_message(integer Sender, integer Num, string Text, key Id) {
		if (Num > MENU_RANGE_S || Num < MENU_RANGE_E) return;
		if (Num == MENU_RESET) {
			Reset();
		}
		else if (Num == MENU_ADD) {
			SourceList += llParseStringKeepNulls(Text,  [ "|" ], []);
		}
		else if (Num == MENU_START) {
			if (Id == NULL_KEY) AvId = (key)Text; else AvId = Id;
			LinkNum = Sender;
			StartMenu();
		}
		else if (Num == MENU_TEXTBOX) {
			LinkNum = Sender;
			list Params = llParseStringKeepNulls(Text,  [ "|" ], []);
			AvId = (key)llList2String(Params, 0);
			string TextboxText = llList2String(Params, 1);
			StartTextbox(TextboxText);
		}
		else if (Num == MENU_SETVALUE) {
			list Lines = llParseStringKeepNulls(Text, [ "|" ], []);
			integer LinesCount = llGetListLength(Lines);
			integer L;
			for (L = 0; L < LinesCount; L++) {
				string Line = llList2String(Lines, L);
				integer Equals = llSubStringIndex(Line, "=");
				if (Equals == -1) {
					llOwnerSay("Invalid SETVALUE for: " + Line);
					return;
				}
				string Name = llToLower(llStringTrim(llGetSubString(Line, 0, Equals - 1), STRING_TRIM));
				string Value = llStringTrim(llGetSubString(Line, Equals + 1, -1), STRING_TRIM);
				if (Name == "persist") {
					Persist = ParseBool(Value);
				}
				else if (Name == "close") {
					list CloseValues = llCSV2List(Value);
					CloseMenu = llList2String(CloseValues, 0);
					CloseOption = llList2String(CloseValues, 1);
				}
				else {
					llOwnerSay("Invalid SETVALUE name: " + Name);
					return;
				}
			}
		}
	}
	listen(integer Channel, string Name, key Id, string Text) {
		if (IsTextBox) {
			llMessageLinked(LinkNum, MENU_RESPONSE, Text, AvId);
			RemoveListener();
			AvId = NULL_KEY;
		}
		else {
			if (Text == " ") {
				ShowMenu();
			}
			list Selected = ProcessSelection(Channel, Id, Text);
			if (Selected == []) return;
			string Menu = llList2String(Selected, 0);
			string Response = llList2String(Selected, 1);
			llMessageLinked(LinkNum, MENU_RESPONSE, Menu + "," + Response, AvId);
			if (Persist) {
				if (Menu == CloseMenu && Response == CloseOption) return;
				ShowMenu();
			}
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		RemoveListener();
		AvId = NULL_KEY;
	}
}
// Blue menu controller v1.0.3