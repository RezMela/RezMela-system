
integer MENU_RANGE_S	= -291044300;
integer MENU_RESET 		= -291044301;
integer MENU_ADD 	 	= -291044302;
integer MENU_SETVALUE 	= -291044303;
integer MENU_START 		= -291044304;
integer MENU_RESPONSE	= -291044305;
integer MENU_TEXTBOX	= -291044306;
integer MENU_RANGE_E	= -291044399;

SendMenuCommand(integer Command, list Values) {
	string SendString = llDumpList2String(Values, "|");
	llMessageLinked(LINK_THIS, Command, SendString, NULL_KEY);
}
default {
	state_entry() {
		llSetTimerEvent(1.0);
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llResetScript();
	}
	timer() {
		llSetTimerEvent(0.0);
		SendMenuCommand(MENU_RESET, []);
		SendMenuCommand(MENU_ADD, [	"!Main", "You can find things out here", "*Colours", "*Artists", "*Numbers" ]);
		SendMenuCommand(MENU_ADD, [ "!Colours", "Here are some colours", "Red", "Blue", "Green", "Yellow", "Pink", "Coffee", "*" ]);
		SendMenuCommand(MENU_ADD, [ "!Artists", "Artists to choose from", "Kahlo", "Constable", "Titian", "*" ]);
		list Numbers = [ "!Numbers", "Here are some numbers you can choose from at your leisure" ];
		integer Count = 30;
		integer N;
		for (N = 0; N < Count; N++) {
			Numbers += (string)(N + 1);
		}
		Numbers += "*";
		SendMenuCommand(MENU_ADD, Numbers);
		llOwnerSay("Menu initialised");
	}
	touch_start(integer Count) {
		SendMenuCommand(MENU_START, [ llDetectedKey(0) ]);
	}
	link_message(integer Sender, integer Num, string Text, key Id) {
		if (Num == MENU_RESPONSE) {
			list Selected = llCSV2List(Text);
			string SelectedMenu = llList2String(Selected, 0);
			string SelectedOption = llList2String(Selected, 1);
			llOwnerSay(SelectedMenu + ": " + SelectedOption);
		}
	}
}