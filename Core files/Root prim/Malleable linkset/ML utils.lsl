// ML utils v1.1.0

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
// More detailed information about the HUD communicator script is available here http://wiki.rezmela.org/doku.php/hud-communicator-script

// v1.1.0 - add menu handling

integer UTIL_WAITING = -181774800;
integer UTIL_GO = -181774801;

integer UTIL_TIMER_SET = -181774802;
integer UTIL_TIMER_CANCEL = -181774803;
integer UTIL_TIMER_RETURN = -181774804;

integer UTIL_MENU_INIT			= -21044301;
integer UTIL_MENU_ADD 			= -21044302;
integer UTIL_MENU_SETVALUE		= -21044303;
integer UTIL_MENU_START 		= -21044304;
integer UTIL_MENU_RESPONSE		= -21044305;
integer UTIL_MENU_PERSIST		= -21044306;
integer UTIL_MENU_CLOSEOPTION	= -21044307;

integer UTIL_TEXTBOX_CALL		= -21044500;
integer UTIL_TEXTBOX_RESPONSE	= -21044501;

integer LM_RESET = -405535;

float TIMER_FAST = 0.5;
float TIMER_SLOW = 60.0;

integer MLReady = FALSE;
integer CommunicatorReady = FALSE;
integer CataloguerReady = FALSE;

list Timers = [];
integer TIM_TAG = 0;
integer TIM_DURATION = 1;
integer TIM_REMAINING = 2;
integer TIM_REPEAT = 3;
integer TIM_STRIDE = 4;

integer TimersCount = 0;

list Menus = [];
integer MENU_USER_ID = 0;
integer MENU_PRIM_UUID = 1;
integer MENU_SOURCE = 2; // source items (|-separated list)
integer MENU_PERSIST = 3;
integer MENU_CLOSE_MENU = 4;
integer MENU_CLOSE_OPTION = 5;
integer MENU_SOURCE_PTR	= 6;  // pointer to current menu sub-list within SourceList (needs to be next to page ptr!)
integer MENU_PAGE_PTR = 7; // pointer to current page within current menu (added to SourcePtr)
integer MENU_STACK = 8; // return stack, comprising pointers to SourceList for parent menus (|-separated list)
integer MENU_STRIDE = 9;

integer MenusCount = 0;

list Textboxes = [];
integer TBOX_USER_ID = 0;
integer TBOX_PRIM_UUID = 1;
integer TBOX_TAG = 2;
integer TBOX_STRIDE = 3;

integer TextboxesCount = 0;

// Standard button texts
string MENU_BUTTON_BACK = "< Back";
string MENU_BUTTON_PREV  = "<<";
string MENU_BUTTON_NEXT = ">>";
string MENU_BUTTON_CLOSE = "Close";

integer ListenChannel = -1; // we have a listener on all the time. it doesn't incur significant cost, and it's easier this way.
integer ListenerId = 0;

// Clear and initialise menus for given user, returning raw pointer to table
integer MenuInitialize(key AvId, key PrimId) {
	MenuClear(AvId);
	Menus += [
		AvId,
		PrimId, // UUID of prim we're communicating with
		"", // source list
		FALSE, // persist?
		"", // close menu
		"", // close option
		0, // source ptr
		0, // page ptr
		"" // stack list
			];
	MenusCount++;
	return (MenusCount -1) * MENU_STRIDE;
}
StartMenu(key AvId) {
	integer Ptr = GetMenuPtr(AvId); // get pointer to menus table for this user
	if (Ptr == -1) return; // something went wrong
	MenuUpdate(Ptr, MENU_SOURCE_PTR, [ 0 ]); // set source ptr to 0
	MenuUpdate(Ptr, MENU_PAGE_PTR, [ 0 ]); // set page ptr to 0
	MenuUpdate(Ptr, MENU_STACK, [ "" ]); // clear stack
	ShowMenu(AvId);
}
ShowMenu(key AvId) {
	integer MenusPtr = GetMenuPtr(AvId); // get pointer to menus table for this user
	if (MenusPtr == -1) return; // something went wrong
	// Get some data from the menus table
	list SourceList = PSV2List(llList2String(Menus, MenusPtr + MENU_SOURCE)); // find pipe-separated source list and convert to list
	integer SourceLength = llGetListLength(SourceList);
	integer SourcePtr = llList2Integer(Menus, MenusPtr + MENU_SOURCE_PTR); // find source pointer (pointer to current menu)
	integer PagePtr = llList2Integer(Menus, MenusPtr + MENU_PAGE_PTR); // find source pointer (pointer to current menu)
	// Get data from the source list
	string MenuName = llList2String(SourceList, SourcePtr);
	string MenuText = llList2String(SourceList, SourcePtr + 1);
	string Message = "\n        " + llToUpper(llGetSubString(MenuName, 1, -1)) + "\n\n" + MenuText;
	list Options = [];
	integer SourceOptionsPtr = SourcePtr + 2; // pointer to start of options in source list
	integer P = SourceOptionsPtr;
	do {
		string Entry = llList2String(SourceList, P);
		if (Entry == "*") Entry = MENU_BUTTON_BACK;
		else if (llGetSubString(Entry, 0, 0) == "*") {
			Entry = llGetSubString(Entry, 1, -1);
		}
		Options += Entry;
		P++;
	} while (llGetSubString(llList2String(SourceList, P), 0, 0) != "!" && P < SourceLength);
	integer CurrentMenuLength = llGetListLength(Options);
	if (CurrentMenuLength > 12) {
		string ThisBack = " ";
		if (llList2String(Options, -1) == MENU_BUTTON_BACK) { // if last option on this menu is "back"
			// A special case: if the last option is "back" we put a back button on the bottom row, not at the end of options
			ThisBack = MENU_BUTTON_BACK;
			Options = llList2List(Options, 0, -2);
		}
		integer PageCount = CurrentMenuLength / 9; // number of sub-pages for this menu
		if (PagePtr < 0) PagePtr = 0; // prevent underflow
		integer PageEnd = PagePtr + 8; // 3 rows of actual option (start at zero)
		if (PageEnd > CurrentMenuLength) { // prevent overflow
			PageEnd = CurrentMenuLength;
			PagePtr = PageEnd - 9;
		}
		string ThisPrev = " "; if (PagePtr > 0) ThisPrev = MENU_BUTTON_PREV;
		string ThisNext = " "; if (PageEnd < CurrentMenuLength) ThisNext = MENU_BUTTON_NEXT;
		Options = llList2List(Options, PagePtr, PageEnd) + [ ThisBack, ThisPrev, ThisNext ];

	}
	// Rearrange the buttons into LL's silly design
	Options = llList2List(Options, -3, -1) + llList2List(Options, -6, -4)
		+ llList2List(Options, -9, -7) + llList2List(Options, -12, -10);
	llDialog(AvId, Message, Options, ListenChannel);
}
// Returns raw pointer to menu list for given avatar UUID, or -1 if fail
integer GetMenuPtr(key AvId) {
	integer Ptr = llListFindList(Menus, [ AvId ]);
	if (Ptr == -1) {
		MessageAvatar(AvId, "Sorry, something has gone wrong. Can't find your pointer!"); // friendly message to potentially non-savvy user
		return -1;
	}
	return Ptr;
}
MenuClear(key AvId) {
	integer Ptr = llListFindList(Menus, [ AvId ]);
	if (Ptr == -1) return;
	Menus = llDeleteSubList(Menus, Ptr, Ptr + MENU_STRIDE - 1);
	MenusCount--;
}
list MenuProcessSelection(key AvId, string Text) {
	integer MenusPtr = GetMenuPtr(AvId); // get pointer to menus table for this user
	if (MenusPtr == -1) return []; // something went wrong
	// Get some data from the menus table
	list SourceList = PSV2List(llList2String(Menus, MenusPtr + MENU_SOURCE)); // find pipe-separated source list and convert to list
	integer SourceLength = llGetListLength(SourceList);
	integer SourcePtr = llList2Integer(Menus, MenusPtr + MENU_SOURCE_PTR); // find source pointer (pointer to current menu)
	integer PagePtr = llList2Integer(Menus, MenusPtr + MENU_PAGE_PTR); // find source pointer (pointer to current menu)
	list Stack = PSV2List(llList2String(Menus, MenusPtr + MENU_STACK)); // find pipe-separated stack and convert to list
	// Interpret special options
	if (Text == MENU_BUTTON_BACK) {
		Text = "*"; // internal representation of back button
	}
	else if (Text == MENU_BUTTON_PREV) {
		PagePtr -= 9;
		MenuUpdate(MenusPtr, MENU_PAGE_PTR, [ PagePtr ]); // update page ptr
		ShowMenu(AvId);
		return [];
	}
	else if (Text == MENU_BUTTON_NEXT) {
		PagePtr += 9;
		MenuUpdate(MenusPtr, MENU_PAGE_PTR, [ PagePtr ]); // update page ptr
		ShowMenu(AvId);
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
	if (SelectedPtr == -1) {
		llRegionSayTo(AvId, 0, "Error: can't find menu entry: " + Text + " [" + (string)SourcePtr + "]");
		return [];
	}
	string SelectedEntry = llList2String(SourceList, SelectedPtr); // the source element they've clicked on
	if (SelectedEntry == "*") { // it's a "back" menu
		if (Stack == []) {
			llRegionSayTo(AvId, 0, "Error: no stack");
			return [];
		}
		// Pop one off the return stack
		SourcePtr = llList2Integer(Stack, -1);
		Stack = llDeleteSubList(Stack, -1, -1);
		MenuUpdate(MenusPtr, MENU_SOURCE_PTR, [ SourcePtr ]); // update source ptr
		MenuUpdate(MenusPtr, MENU_PAGE_PTR, [ PagePtr ]); // update page ptr
		MenuUpdate(MenusPtr, MENU_STACK, [ Stack ]); // update stack
		ShowMenu(AvId);
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
				MenuUpdate(MenusPtr, MENU_SOURCE_PTR, [ SourcePtr ]); // update source ptr
				MenuUpdate(MenusPtr, MENU_PAGE_PTR, [ PagePtr ]); // update page ptr
				MenuUpdate(MenusPtr, MENU_STACK, [ Stack ]); // update stack
				ShowMenu(AvId);
				return [];
			}
		}
		llRegionSayTo(AvId, 0, "Error: can't find sub-menu: " + Text + " [" + (string)SourcePtr + "]");
		return [];
	}
	else { // atomic option
		return [ GetMenuName(SourceList, SourcePtr), SelectedEntry ]; // pass back the option
	}
}
// Set persistence state of menu (ie if menu stays up after the click an atomic option). Text is
// option value sent (boolean in string format)
MenuPersist(key AvId, string Text) {
	integer MenusPtr = GetMenuPtr(AvId); // get pointer to menus table for this user
	if (MenusPtr == -1) return; // something went wrong
	MenuUpdate(MenusPtr, MENU_PERSIST, [ (integer)Text ]);
}
// Set button to be used to close a persistent menu. Text is pipe-separated menu and option
MenuSetClose(key AvId, string Text) {
	integer MenusPtr = GetMenuPtr(AvId); // get pointer to menus table for this user
	if (MenusPtr == -1) return; // something went wrong
	list L = llParseStringKeepNulls(Text, [ "|" ], []);
	string CloseMenu = llList2String(L, 0);
	string CloseOption = llList2String(L, 1);
	MenuUpdate(MenusPtr, MENU_CLOSE_MENU, [ CloseMenu ]);
	MenuUpdate(MenusPtr, MENU_CLOSE_OPTION, [ CloseOption ]);
}
// Updates a single data item in the menu list
MenuUpdate(integer RowPtr, integer ColPtr, list Value) {
	Menus = llListReplaceList(Menus, Value, RowPtr + ColPtr, RowPtr + ColPtr); // set source ptr to 0
}
string GetMenuName(list SourceList, integer SourcePtr) {
	return llGetSubString(llList2String(SourceList, SourcePtr), 1, -1);
}
TextboxClear(key AvId) {
	integer Ptr = llListFindList(Textboxes, [ AvId ]);
	if (Ptr == -1) return;
	Textboxes = llDeleteSubList(Textboxes, Ptr, Ptr + TBOX_STRIDE - 1);
	TextboxesCount--;
}
TextboxStart(key AvId, key PrimUuid, string Tag, string Text) {
	TextboxClear(AvId);
	Textboxes += [
		AvId,
		PrimUuid,
		Tag
		];
	TextboxesCount++;
	llTextBox(AvId, "\n\n" + Text, ListenChannel);
}
TextboxResponse(key Id, string Data) {
	integer Ptr = llListFindList(Textboxes, [ Id ]);
	if (Ptr == -1) {
		llRegionSayTo(Id, 0, "Sorry, can't find your textbox!");
		return;
	}
	key PrimUuid = llList2Key(Textboxes, Ptr + TBOX_PRIM_UUID);
	string Tag = llList2String(Textboxes, Ptr + TBOX_TAG);
	integer LinkNum = Uuid2LinkNum(PrimUuid);
	llMessageLinked(LinkNum, UTIL_TEXTBOX_RESPONSE, Tag + "|" + Data, Id);
	TextboxClear(Id);
}
// Clears up any data for users no longer in region
Housekeeping() {
	integer Row;
	for (Row = 0; Row < MenusCount; Row++) {
		key AvId = llList2Key(Menus, Row + MENU_USER_ID);
		if (!AvatarExists(AvId)) {
			MenuClear(AvId);
		}
	}
	for (Row = 0; Row < TextboxesCount; Row++) {
		key AvId = llList2Key(Textboxes, Row + TBOX_USER_ID);
		if (!AvatarExists(AvId)) {
			TextboxClear(AvId);
		}
	}
}
ResetScript() {
	if (ListenerId > 0) llListenRemove(ListenerId);
	MLReady = FALSE;
	CommunicatorReady = FALSE;
	CataloguerReady = FALSE;
	Timers = [];
	TimersCount = 0;
	Menus = [];
	MenusCount = 0;
	// Despite folklore, listeners on specific channels don't really incur significant
	// cost. Here, we have one listener that runs all the time, for all users
	ListenChannel = -1000000 - (integer)llFrand(9000000.0);
	ListenerId = llListen(ListenChannel, "", NULL_KEY, "");
}
MessageAvatar(key AvId, string Text) {
	if (AvatarExists(AvId)) llRegionSayTo(AvId, 0, Text);
}
// Return true if user exists
integer AvatarExists(key AvId) {
	return (AvId != NULL_KEY && llGetObjectDetails(AvId, [ OBJECT_POS ]) != []);
}
list PSV2List(string Str) {
	return llParseStringKeepNulls(Str, [ "|" ], []);
}
string List2PSV(list List) {
	return llDumpList2String(List, "|");
}
// Regrettably, I've had to make this more terse/unreadable than I'd like because it needs to be
// as efficient as possible. Returns link number of given prim UUID, or 0 if it's not found
integer Uuid2LinkNum(key Uuid) {
	integer LinkNum = llGetNumberOfPrims();
	while (llGetLinkKey(LinkNum) != Uuid && LinkNum > 0) LinkNum--;
	return LinkNum;
}
default {
	on_rez(integer Param) {
		// We don't reset the script here, as pretty much all our other scripts do, because we don't want
		// to drop events. It's essential that this script is ready to receive events before it actually
		// gets any, otherwise the whole concept of the coordination is ruined.
		ResetScript();
	}
	state_entry() {
		ResetScript();
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		if (Sender == 1) {	// Message from script in root prim
			if (Number == UTIL_WAITING) {
				if (Text == "M") MLReady = TRUE;
				else if (Text == "O") CommunicatorReady = TRUE;
				else if (Text == "A") CataloguerReady = TRUE;
				if (MLReady && CommunicatorReady && CataloguerReady) {
					llMessageLinked(LINK_THIS, UTIL_GO, "", NULL_KEY);
				}
				return;
			}
		}
		/// TIMER STUFF ///
		// Messages from any prim
		if (Number == UTIL_TIMER_SET) {
			// Format of string portion of this command is: <tag>|<duration>|<repeat?>
			list Parts = llParseStringKeepNulls(Text, [ "|" ], []);
			string Tag = llList2String(Parts, 0);
			float Duration = (float)llList2String(Parts, 1);
			integer Repeat = (integer)llList2String(Parts, 2);
			integer P = llListFindList(Timers, [ Tag ]);
			if (P > -1) {
				Timers = llDeleteSubList(Timers, P, P + TIM_STRIDE - 1);
				TimersCount--;
			}
			Timers += [ Tag, Duration, Duration, Repeat ];
			TimersCount++;
			llSetTimerEvent(TIMER_FAST);
		}
		else if (Number == UTIL_TIMER_CANCEL) {
			// This command takes only the tag as a parameter
			string Tag = Text;
			integer P = llListFindList(Timers, [ Tag ]);
			if (P > -1) {
				Timers = llDeleteSubList(Timers, P, P + TIM_STRIDE - 1);
				TimersCount--;
			}
			// If the Timers table is now empty, the timer will be stopped in the next timer() event.
		}
		/// MENU STUFF ///
		else if (Number == UTIL_MENU_INIT) {
			TextboxClear(Id);
			MenuInitialize(Id, llGetLinkKey(Sender));
		}
		else if (Number == UTIL_MENU_ADD) {
			integer Ptr = llListFindList(Menus, [ Id ]);
			if (Ptr == -1) Ptr = MenuInitialize(Id, llGetLinkKey(Sender)); // if it's not there, add it
			string SourceString = llList2String(Menus, Ptr + MENU_SOURCE);
			// We store the source list as a "|"-delimited string because there's no proper way to serialise lists to strings in LSL
			if (SourceString != "") SourceString += "|"; // add separator if necessary
			SourceString += Text; // add in the new text
			Menus = llListReplaceList(Menus, [ SourceString ], Ptr + MENU_SOURCE, Ptr + MENU_SOURCE); // write it back to the table
		}
		else if (Number == UTIL_MENU_START) {
			Housekeeping();
			integer LinkNum = Sender;
			StartMenu(Id);
		}
		else if (Number == UTIL_MENU_PERSIST) {
			MenuPersist(Id, Text);
		}
		else if (Number == UTIL_MENU_CLOSEOPTION) {
			MenuSetClose(Id, Text);
		}
		else if (Number == UTIL_TEXTBOX_CALL) {
			MenuClear(Id);
			// Format of string is pipe-delimited [ tag, text  ]
			list L = llParseStringKeepNulls(Text, [ "|" ], []);
			string Tag = llList2String(L, 0);
			string TextboxText = llList2String(L, 1);
			TextboxStart(Id, llGetLinkKey(Sender), Tag, TextboxText);
		}
		else if (Number == LM_RESET) {
			ResetScript();
		}

	}
	listen(integer Channel, string Name, key Id, string Text) {
		if (Channel != ListenChannel) return; // should never happen
		if (llListFindList(Menus, [ Id ]) > -1) { // It's a menu response
			//		if (IsTextBox) {
			//			llMessageLinked(LinkNum, MENU_RESPONSE, Text, AvId);
			//			RemoveListener();
			//			AvId = NULL_KEY;
			//		}
			//		else {
			if (Text == " ") {
				ShowMenu(Id); // repeat menu if they've selected a blank button
				return;
			}
			list Selected = MenuProcessSelection(Id, Text);
			if (Selected == []) return;
			string Menu = llList2String(Selected, 0);
			string Response = llList2String(Selected, 1);
			integer MenusPtr = GetMenuPtr(Id); // get pointer to menus table for this user
			key PrimId = llList2Key(Menus, MenusPtr + MENU_PRIM_UUID);
			integer Persist = llList2Integer(Menus, MenusPtr + MENU_PERSIST);
			integer LinkNum = Uuid2LinkNum(PrimId);
			llMessageLinked(LinkNum, UTIL_MENU_RESPONSE, Menu + "," + Response, Id);
			if (Persist) {
				string CloseMenu = llList2String(Menus, MenusPtr + MENU_CLOSE_MENU);
				string CloseOption = llList2String(Menus, MenusPtr + MENU_CLOSE_OPTION);
				if (Menu == CloseMenu && Response == CloseOption) return;
				ShowMenu(Id);
			}
		}
		else if (llListFindList(Textboxes, [ Id ]) > -1) { // Maybe it's a textbox response
			TextboxResponse(Id, Text);
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		if (TimersCount > 0) {
			integer T;
			for (T = 0; T < TimersCount; T++) {
				integer P = T * TIM_STRIDE;
				float Remaining = llList2Float(Timers, P + TIM_REMAINING);
				Remaining -= TIMER_FAST;
				if (Remaining > 0.0) {
					Timers = llListReplaceList(Timers, [ Remaining ], P + TIM_REMAINING, P + TIM_REMAINING);
				}
				else { // timer is due
					string Tag = llList2String(Timers, P + TIM_TAG);
					integer Repeat = llList2Integer(Timers, P + TIM_REPEAT);
					llMessageLinked(LINK_SET, UTIL_TIMER_RETURN, Tag, NULL_KEY);
					if (Repeat) { // timer repeats, so reset remaining time
						float Duration = llList2Float(Timers, P + TIM_DURATION);
						Timers = llListReplaceList(Timers, [ Duration ], P + TIM_REMAINING, P + TIM_REMAINING);
					}
					else { // timer has expired
						Timers = llDeleteSubList(Timers, P, P + TIM_STRIDE - 1);
						TimersCount--;
					}
				}
			}
		}
		if (TimersCount > 0)
			llSetTimerEvent(TIMER_FAST);
		else
			llSetTimerEvent(TIMER_SLOW);
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) {
			ResetScript();
		}
	}
}
// ML utils v1.1.0