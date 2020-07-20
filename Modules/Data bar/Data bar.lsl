// Data bar v0.2

// RezMela world object, request for icon ID, etc
integer RWO_EXTRA_DATA_SET = 808399102;	// +ve for incoming, -ve for outgoing
integer RWO_INITIALISE = 808399110;	// +ve for data (sent repeateadly at startup), client sends -ve to disable. Icon ID is sent as key portion
integer WO_COMMAND = 3007;

// Commands for RezMela icon script
integer IC_COMMAND = 1020;
integer IC_MENU = 1021;

// Commands for label board icon
integer DBI_DISPLAY = -1925200;

key IconUuid;		// UUID of icon root prim

integer DataUpdated = FALSE;		// Has the data changed, so it needs to be stored as extra data?
string LastExtraData;				// The last extra data sent, so don't resend if it's the same
integer InitialiseReceived = FALSE;

integer Value = 100;
vector Color = <250, 250, 250>;

list Colors = [
	"Brown", <139, 69, 19>,
	"Gold", <255, 215, 0>,
	"Teal", <56, 142, 142>,
	"Black", <20, 20, 20>,
	"White", <250, 250, 250>,
	"Grey", <128, 128, 128>,
	"Yellow", <255, 255, 0>,
	"Cyan", <0, 255, 255>,
	"Magenta", <255, 0, 255>,
	"Red", <255, 0, 0>,
	"Blue", <0, 0, 255>,
	"Green", <0, 255, 0>
		];

integer MenuListener;
integer MenuChannel;
integer CurrentMenu;
integer MENU_COLOR = 1;
integer MENU_VALUE = 2;

key MenuAvId;

Display() {
	SetIconData();
	list Params = [];
//	llOwnerSay("Setting: " + (string)Color);	/// %%%%
	Params += [ PRIM_COLOR, ALL_SIDES, Color / 255.0, 1.0 ];
	float Slice = (float)Value / 100.0;
	if (Slice < 0.0001) Slice = 0.01;
	Params += [ PRIM_SLICE, <0.0, Slice, 0.0> ];
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
}
SetIconData() {
	MessageIcon(llList2CSV([
		DBI_DISPLAY,
		Color,
		Value
			]));
}
ShowMenu(integer Menu) {
	CurrentMenu = Menu;
	MenuChannel = -10000 - (integer)llFrand(10000000.0);
	string MenuText;
	list Buttons = [];
	if (CurrentMenu == MENU_COLOR) {
		MenuText = "\n\nSelect color:";
		Buttons = [];
		integer S;
		for (S = 0; S < 12; S++) {
			integer Ptr = S * 2;
			string ColorName = llList2String(Colors, Ptr);
			Buttons += ColorName;
		}
	}
	else if (CurrentMenu == MENU_VALUE) {
		MenuText = "Enter value (0 to 100):";
	}
	MenuListener = llListen(MenuChannel, "", MenuAvId, "");
	if (CurrentMenu == MENU_VALUE) {
		llTextBox(MenuAvId, MenuText, MenuChannel);
	}
	else {
		llDialog(MenuAvId, MenuText, Buttons, MenuChannel);
	}
}
ProcessMenu(string Data) {
	llListenRemove(MenuListener);
	if (CurrentMenu == MENU_COLOR) {
		integer Ptr = llListFindList(Colors, [ Data ]);
		if (Ptr == -1) {
			llOwnerSay("Can't find color: '" + Data + "'");
			return;
		}
		Color = llList2Vector(Colors, Ptr + 1);
		//llOwnerSay("Ptr " + (string)Ptr + " is " + llList2String(Colors, Ptr) + " (" + Data + ") so " + (string)Color);	/// %%%%
		DataUpdated = TRUE;
		ShowMenu(MENU_VALUE);		// take them to the value input menu
		return;
	}
	else if (CurrentMenu == MENU_VALUE) {
		integer I = (integer)Data;
		if (I < 0 || I > 100) {
			llRegionSayTo(MenuAvId, 0, "Value must be between 0 and 100 (inclusive)");
			ShowMenu(MENU_VALUE);
			return;
		}
		Value = I;
		DataUpdated = TRUE;
		Display();
		SetExtraData();
		return;
	}
	ShowMenu(CurrentMenu);
}
ProcessExtraData(string ExtraData) {
	if (ExtraData != "") {
		list L = llParseStringKeepNulls(ExtraData, [ "^" ], []);
		Color = (vector)llList2String(L, 0);
		Value = (integer)llList2String(L, 1);
		Display();
	}
}
SetExtraData() {
	if (!DataUpdated) return;
	string ExtraData = llDumpList2String([
		Color,
		Value
			], "^");
	if (ExtraData != LastExtraData) {
		llMessageLinked(LINK_SET, RWO_EXTRA_DATA_SET, ExtraData, NULL_KEY);
		LastExtraData = ExtraData;
	}
	DataUpdated = FALSE;
}
MessageIcon(string Text) {
	if (IconUuid != NULL_KEY && llKey2Name(IconUuid) != "") {
		osMessageObject(IconUuid, (string)IC_COMMAND + "|" + Text);
	}
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		IconUuid = NULL_KEY;
		InitialiseReceived = FALSE;
		llSetTimerEvent(1.0);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == RWO_INITIALISE && !InitialiseReceived) {
			llMessageLinked(LINK_SET, -RWO_INITIALISE, "", NULL_KEY);	// suppress further initialisation messages
			InitialiseReceived = TRUE;
			IconUuid = Id;
			ProcessExtraData(String);
			SetIconData();
		}
	}
	dataserver(key From, string Data) {
		list L = llCSV2List(Data);
		string Command = llList2String(L, 0);
		string Params = llStringTrim(llList2String(L, 1), STRING_TRIM);
		if (Command == "menu") {
			MenuAvId = (key)Params;
			ShowMenu(MENU_COLOR);
		}
	}
	listen(integer Channel, string Name, key Id, string Data) {
		if (Channel == MenuChannel && Id == MenuAvId) {
			ProcessMenu(Data);
		}
	}
	touch_start(integer Count) {
		MenuAvId = llDetectedKey(0);
		ShowMenu(MENU_COLOR);
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) llResetScript();
		if (Change & CHANGED_REGION_START) Display();
	}
}
// Data bar v0.2