
// ML util menus test. Put in child prim, with ML util in root prim
// Click this prim to get the menu

integer UTIL_MENU_INIT			= -21044301;
integer UTIL_MENU_ADD 			= -21044302;
integer UTIL_MENU_SETVALUE		= -21044303;
integer UTIL_MENU_START 		= -21044304;
integer UTIL_MENU_RESPONSE		= -21044305;
integer UTIL_MENU_PERSIST		= -21044306;
integer UTIL_MENU_CLOSEOPTION	= -21044307;

key AvId = NULL_KEY;

SendMenuCommand(integer Command, list Values) {
	string SendString = llDumpList2String(Values, "|");
	llMessageLinked(LINK_ROOT, Command, SendString, AvId);
}
default {
	state_entry() {
	}
	touch_start(integer Count) {
		AvId = llDetectedKey(0);
		SendMenuCommand(UTIL_MENU_INIT, []);
		SendMenuCommand(UTIL_MENU_ADD, [	"!Main", "Text for ML utils menu processing", "*Colours", "*Artists", "*Numbers" ]);
		SendMenuCommand(UTIL_MENU_ADD, [ "!Colours", "Here are some colours", "Red", "Blue", "Green", "Yellow", "Pink", "Coffee", "*" ]);
		SendMenuCommand(UTIL_MENU_ADD, [ "!Artists", "Artists to choose from", "Kahlo", "Constable", "Titian", "*" ]);
		list Numbers = [ "!Numbers", "Here are some numbers you can choose from at your leisure" ];
		integer Limit = 30;
		integer N;
		for (N = 0; N < Limit; N++) {
			Numbers += (string)(N + 1);
		}
		Numbers += "*";
		SendMenuCommand(UTIL_MENU_ADD, Numbers);
		// Peristence stuff
		SendMenuCommand(UTIL_MENU_PERSIST, [ FALSE ]); // change to TRUE to test persistence
		//SendMenuCommand(UTIL_MENU_CLOSEOPTION, [ "Colours|Red" ]); // uncomment to make Red close the menu
		// Call the menu itself
		SendMenuCommand(UTIL_MENU_START, []);
	}
	link_message(integer Sender, integer Num, string Text, key Id) {
		if (Num == UTIL_MENU_RESPONSE) {
			list Selected = llCSV2List(Text);
			string SelectedMenu = llList2String(Selected, 0);
			string SelectedOption = llList2String(Selected, 1);
			llRegionSayTo(Id, 0, "From '" + SelectedMenu + "': " + SelectedOption);
		}
	}
}