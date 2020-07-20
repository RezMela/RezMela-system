// Picture board v0.1

string CONFIG_NOTECARD = "Picture board config";

// RezMela world object, request for icon ID, etc
integer RWO_EXTRA_DATA_SET = 808399102;	// +ve for incoming, -ve for outgoing
integer RWO_INITIALISE = 808399110;	// +ve for data (sent repeateadly at startup), client sends -ve to disable. Icon ID is sent as key portion
integer WO_COMMAND = 3007;

// Commands for RezMela icon script
integer IC_COMMAND = 1020;
integer IC_MENU = 1021;

// Commands for label board icon
integer PBI_DISPLAY = -1924200;

key IconUuid;		// UUID of icon root prim
integer InitialiseReceived = FALSE;

integer DataUpdated = FALSE;		// Has the data changed, so it needs to be stored as extra data?
string LastExtraData;				// The last extra data sent, so don't resend if it's the same

list Sizes;		// [ Description, prim X, prim Z, texture X, texture Y ] ...
integer SIZ_DESCRIPTION = 0;
integer SIZ_PRIM_X = 1;
integer SIZ_PRIM_Z = 2;
integer SIZ_ICON_X = 3;
integer SIZ_ICON_Z = 4;
integer SIZ_TEXTURE_X = 5;
integer SIZ_TEXTURE_Y = 6;
integer SIZ_STRIDE = 7;

integer SizesCount;		// size in rows
string DefaultSize;
string CurrentSize;

float PrimX;
float PrimZ;
float IconX;
float IconZ;
integer TextureX;
integer TextureY;

integer MenuListener;
integer MenuChannel;

string Url = "";

integer CurrentMenu;
integer MENU_SIZE = 1;
integer MENU_URL = 2;

key MenuAvId;

Display() {
	SetIconData();
	vector LocalPos = <0.0, 0.0, PrimZ / 2.0>;
	llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_POS_LOCAL, LocalPos, PRIM_SIZE, <PrimX, 0.001, PrimZ> ]);
	if (Url == "") {
		llSetTexture(TEXTURE_BLANK, ALL_SIDES);
		return;
	}
	string CommandList = "";
	CommandList = osMovePen(CommandList, 0, 0);
	CommandList = osDrawImage(CommandList, TextureX, TextureY, Url);
	string Dimensions = "width:" + (string)TextureX + ",height:" + (string)TextureY;
	osSetDynamicTextureData("", "vector", CommandList, Dimensions, 0);
	SetExtraData();
}
// Note this doesn't actually change the size, just sets the value; size is changed in Display()
SetSize(string SizeName) {
	integer Ptr = llListFindList(Sizes, [ SizeName ]);
	if (Ptr == -1) {
		llOwnerSay("Can't find size: '" + SizeName + "'");
		return;
	}
	CurrentSize = SizeName;
	PrimX = (float)llList2String(Sizes, Ptr + SIZ_PRIM_X);
	PrimZ = (float)llList2String(Sizes, Ptr + SIZ_PRIM_Z);
	IconX = (float)llList2String(Sizes, Ptr + SIZ_ICON_X);
	IconZ = (float)llList2String(Sizes, Ptr + SIZ_ICON_Z);
	TextureX = (integer)llList2String(Sizes, Ptr + SIZ_TEXTURE_X);
	TextureY = (integer)llList2String(Sizes, Ptr + SIZ_TEXTURE_Y);
}
SetIconData() {
	MessageIcon(llList2CSV([
		PBI_DISPLAY,
		IconX,
		IconZ,
		TextureX,
		TextureY,
		Url
			]));
}
ShowMenu(integer Menu) {
	CurrentMenu = Menu;
	MenuChannel = -10000 - (integer)llFrand(10000000.0);
	string MenuText;
	list Buttons = [];
	if (CurrentMenu == MENU_SIZE) {
		MenuText = "\n\nSelect size:";
		Buttons = [];
		integer S;
		for (S = 0; S < SizesCount; S++) {
			integer Ptr = S * SIZ_STRIDE;
			string SizeDesc = llList2String(Sizes, Ptr);
			Buttons += SizeDesc;
		}
	}
	else if (CurrentMenu == MENU_URL) {
		if (Url == "")
			MenuText = "Enter URL of picture:";
		else
			MenuText = "Enter URL of picture (or blank to leave unchanged):";
	}
	MenuListener = llListen(MenuChannel, "", MenuAvId, "");
	if (CurrentMenu == MENU_URL) {
		llTextBox(MenuAvId, MenuText, MenuChannel);
	}
	else {
		llDialog(MenuAvId, MenuText, Buttons, MenuChannel);
	}
}
ProcessMenu(string Data) {
	llListenRemove(MenuListener);
	if (CurrentMenu == MENU_SIZE) {
		integer Ptr = llListFindList(Sizes, [ Data ]);
		if (Ptr == -1) {
			llOwnerSay("Can't find size: '" + Data + "'");
			return;
		}
		SetSize(Data);
		DataUpdated = TRUE;
		ShowMenu(MENU_URL);		// take them to the URL input menu
		return;
	}
	else if (CurrentMenu == MENU_URL) {
		if (Data != "") Url = Data;
		DataUpdated = TRUE;
		Display();
		return;
	}
	ShowMenu(CurrentMenu);
}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	// Set config defaults
	Sizes = [];
	SizesCount = 0;
	DefaultSize = "";

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
					if (Name == "size")	{
						list Parts = llCSV2List(Value);
						if (llGetListLength(Parts) != 7) {
							llOwnerSay("Invalid value for size parameters: " + Value);
						}
						else {
							Sizes += Parts;
							SizesCount++;
						}
					}
					else if (Name == "defaultsize") {
						DefaultSize = Value;
					}
					else llOwnerSay("Invalid keyword in config file: '" + OName + "'");
				}
				else {
					llOwnerSay("Invalid line in config file: " + Line);
				}
			}
		}
	}
	if (Sizes == []) {
		llOwnerSay("No sizes specified in notecard");
		return FALSE;
	}
	if (DefaultSize == "") {
		llOwnerSay("No default size specified");
		return FALSE;
	}
	if (llListFindList(Sizes, [ DefaultSize ]) == -1) {
		llOwnerSay("Invalid default size in notecard: " + DefaultSize);
		return FALSE;
	}
	return TRUE;
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
ProcessExtraData(string ExtraData) {
	if (ExtraData != "") {
		list L = llParseStringKeepNulls(ExtraData, [ "^" ], []);
		CurrentSize = llList2String(L, 0);
		Url = llList2String(L, 1);
		SetSize(CurrentSize);
	}
	Display();
}
SetExtraData() {
	if (!DataUpdated) return;
	string ExtraData = llDumpList2String([
		CurrentSize,
		Url
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
		if (!ReadConfig()) return;
		SetSize(DefaultSize);
		Display();
		llSetTimerEvent(1.0);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == RWO_INITIALISE && !InitialiseReceived) {
			llMessageLinked(LINK_SET, -RWO_INITIALISE, "", NULL_KEY);	// suppress further initialisation messages
			InitialiseReceived = TRUE;
			ProcessExtraData(String);
			IconUuid = Id;
			Display();
		}
	}
	dataserver(key From, string Data) {
		list L = llCSV2List(Data);
		string Command = llList2String(L, 0);
		string Params = llStringTrim(llList2String(L, 1), STRING_TRIM);
		if (Command == "menu") {
			MenuAvId = (key)Params;
			ShowMenu(MENU_SIZE);
		}
	}
	listen(integer Channel, string Name, key Id, string Data) {
		if (Channel == MenuChannel && Id == MenuAvId) {
			ProcessMenu(Data);
		}
	}
	touch_start(integer Count) {
		MenuAvId = llDetectedKey(0);
		ShowMenu(MENU_SIZE);
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) llResetScript();
		if (Change & CHANGED_REGION_START) Display();
		if (Change & CHANGED_INVENTORY) ReadConfig();
	}
}
// Picture board v0.1