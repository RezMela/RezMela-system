// RezMela updater v0.5

// v0.5 - handle empty system
// v0.4 - improve detection of new control board/rezzor; notify on upload
// v0.3 - add message display
// v0.2 - fix getting stuck if control board/rezzor removed during GetData

key RezzorId;
key OldRezzorId;
key ControllerId;
key OldControllerId;
key PickerId;
key OldPickerId;

key RAMESH_ID = "70907dc6-0885-4238-ab15-b7ea3b2f93eb";
list KnownIds = [ "70907dc6-0885-4238-ab15-b7ea3b2f93eb", "ced176eb-f9ee-4945-a1bc-8a7056a6574e" ];		// Ramesh, Handy

integer REZZOR_CHANNEL = -355210124;
integer CONTROLLER_CHANNEL = -94040100;
integer PICKER_CHANNEL = -209441200;
integer RezzorListener;
integer ControllerListener;
integer PickerListener;

string SUFFIX_ICON = "I";
string SUFFIX_NOTECARD = "C";
string SUFFIX_TEXTURE = "T";
string SUFFIX_WORLD_OBJECT = "W";

integer RZ_UPDATE = 2004;
integer IC_UPDATE = 1021;
integer PI_UPDATE = 8400;

integer DataReceived;	// bitfields
integer DR_NONE				= 0;
integer DR_WORLD_OBJECTS 	= 1;
integer DR_ICONS 			= 2;
integer DR_CONFIGS 			= 4;
integer DR_TEXTURES 			= 8;
integer DR_CATEGORIES		= 16;

list Library;
integer LibraryCount;
list WorldObjects;
list Icons;
list ConfigCards;
list Textures;
list Categories;
list ObjectCats;

integer RestartNeeded;
integer InventoryChange;

vector COLOR_GREEN = <0.5, 1.0, 0.5>;
vector COLOR_YELLOW = <1.0, 1.0, 0.2>;
vector COLOR_RED = <1.0, 0.2, 0.2>;

string LIBRARY_LIST_NOTECARD = "RezMela library contents";

key AvId;
integer MenuChannel;
integer MenuListener;
integer TextboxChannel;
integer TextboxListener;

string ScriptName;

string CurrentObject;
list FilesToGive;

list UploadWorldObjects;
list UploadIcons;
list UploadConfigs;
list UploadTextures;
list AllUploadFiles;

string UploadNewObject;		// if it's a new object, this is the name, otherwise blank
integer UploadWorldObjectsCount;
integer UploadIconsCount;
integer UploadConfigsCount;
integer UploadTexturesCount;
integer AllUploadsCount;
string UploadCategory;

integer UploadStatus;
integer US_NONE = 0;
integer US_OK = 1;
integer US_EMPTY = 2;
integer US_ERRORS = 3;
integer US_WARNINGS = 4;

integer TEXT_DISPLAY = -77911300;

ShowMenu() {
	integer InvCount = llGetInventoryNumber(INVENTORY_ALL) - 1;	// - 1 because of this script
	string Text = "REZMELA UPDATER\n\n";
	list Buttons = [];
	// Bottom row
	if (InvCount) Buttons += "Clear"; else Buttons += " ";
	Buttons += " ";
	Buttons += "CLOSE";
	// Middle row
	if (!InvCount) Buttons += "Category"; else Buttons += " ";
	if (!InvCount) Buttons +=  "Delete"; else Buttons += " ";
	Buttons += " ";
	// Top row
	Buttons += "List";
	if (InvCount && UploadStatus == US_OK) Buttons += "Upload"; else Buttons += " ";
	if (!InvCount) Buttons += "Download"; else Buttons += " ";
	if (ButtonExists(Buttons, "List")) Text += "List - get list of objects in library\n";
	if (ButtonExists(Buttons, "Upload")) Text += "Upload - copy files in contents into library\n";
	if (ButtonExists(Buttons, "Download")) Text += "Download - get files from library\n";
	if (ButtonExists(Buttons, "Category")) Text += "Category - Change category of library object\n";
	if (ButtonExists(Buttons, "Delete")) Text += "Delete - Remove object from library\n";
	if (ButtonExists(Buttons, "Clear")) Text += "Clear - Remove all files from contents\n";
	Text += "CLOSE - Close this menu";
	MenuListener = llListen(MenuChannel, "", AvId, "");
	llDialog(AvId, Text, Buttons, MenuChannel);
}
integer ButtonExists(list Buttons, string Button) {
	return (llListFindList(Buttons, [ Button ]) > -1);
}
list OrderButtons(list Buttons) {
	return llList2List(Buttons, -3, -1) + llList2List(Buttons, -6, -4)
		+ llList2List(Buttons, -9, -7) + llList2List(Buttons, -12, -10);
}
string DisplayContents() {
	return "\n-\n" + llDumpList2String(ListContents(), "\n");
}
list ListContents() {
	list Ret = [];
	integer I = 0;
	integer Total = llGetInventoryNumber(INVENTORY_ALL);
	for (I = 0; I < Total; I++) {
		string Name = llGetInventoryName(INVENTORY_ALL, I);
		if (Name != ScriptName) Ret += Name;
	}
	return Ret;
}
// Remove all files in contents
ClearContents() {
	ScriptName = llGetScriptName();
	list ToClear = [];
	integer I = 0;
	integer Total = llGetInventoryNumber(INVENTORY_ALL);
	for (I = 0; I < Total; I++) {
		string Name = llGetInventoryName(INVENTORY_ALL, I);
		if (Name != ScriptName) ToClear += Name;
	}
	Total = llGetListLength(ToClear);
	for (I = 0; I < Total; I++) {
		string Name = llList2String(ToClear, I);
		llRemoveInventory(Name);
	}
}
list StripSuffices(list Input) {
	list Output;
	integer Count = llGetListLength(Input);
	integer I;
	for (I = 0; I < Count; I++) {
		string Element = llList2String(Input, I);
		Output += BaseName(Element);
	}
	return Output;
}
// Returns errors if found, null if OK
string CheckPerms() {
	string Errors = "";
	integer OK = TRUE;
	integer I = 0;
	integer Total = llGetInventoryNumber(INVENTORY_ALL);
	for (I = 0; I < Total; I++) {
		string Name = llGetInventoryName(INVENTORY_ALL, I);
		if (Name != ScriptName) {
			if (!IsFullPerm(Name)) {
				Errors += "- " + Name + "\n";
			}
		}
	}
	return Errors;
}
// Check permissions of inventory object, notecard, etc
integer IsFullPerm(string Name) {
	return (PermsCheck(Name, MASK_BASE) && PermsCheck(Name, MASK_OWNER) && PermsCheck(Name, MASK_NEXT));
}
integer PermsCheck(string Name, integer Mask) {
	integer Perms = llGetInventoryPermMask(Name, Mask);
	return (Perms & PERM_COPY && Perms & PERM_MODIFY && Perms & PERM_TRANSFER);
}
// Returns errors if found, null if OK
string CheckNames() {
	string Errors = "";
	integer I = 0;
	integer Total = llGetInventoryNumber(INVENTORY_ALL);
	for (I = 0; I < Total; I++) {
		string Name = llGetInventoryName(INVENTORY_ALL, I);
		if (Name != ScriptName) {
			integer VE = FALSE;
			integer WL = llStringLength(Name);
			integer J;
			for (J = 0; J < WL; J++) {
				string Char = llGetSubString(Name, J, J);
				if (llSubStringIndex("| ,\"'", Char) > -1) VE = TRUE;
			}
			if (VE) {
				Errors += "- Invalid character(s) in: " + Name + "\n";
			}
			if (llStringLength(Name) > 24) {
				Errors += "- Name too long: " + Name + "\n";
			}
		}
	}
	return Errors;
}
SetStatus() {
	vector Color = COLOR_RED;
	string StatusText = "Internal error!";
	if (UploadStatus == US_OK) {
		Color = COLOR_GREEN;
		StatusText = "Ready";
	}
	else if (UploadStatus == US_EMPTY) {
		Color = COLOR_YELLOW;
		StatusText = "Empty";
	}
	else if (UploadStatus == US_WARNINGS) {
		Color = COLOR_YELLOW;
		StatusText = "Warnings: see board";
	}
	else if (UploadStatus == US_ERRORS) {
		Color = COLOR_RED;
		StatusText = "Errors: see board";
	}
	else {
		StatusText = "Unknown status";
	}
	SetText(StatusText + DisplayContents(), Color);
}

SetText(string Text, vector Color) {
	llSetText(Text, Color, 1.0);
}
ShowMessage(string Text) {
	llMessageLinked(LINK_SET, TEXT_DISPLAY, Text, NULL_KEY);
}
MessageAv(string Text) {
	llRegionSayTo(AvId, 0, Text);
}
// Returns true if we've heard from all the components of the system
integer AllPartsPresent() {
	return (RezzorId != NULL_KEY && ControllerId != NULL_KEY && PickerId != NULL_KEY);
}
// Send command and data to RezMela component - format is "|"-separated list
SendCommand(key Uuid, integer UpdateNumber, string Command, list Parameters) {
	MessageObject(Uuid, llDumpList2String([ UpdateNumber, Command ] + Parameters, "|"));
}
MessageObject(key Uuid, string Message) {
	if (ObjectExists(Uuid)) {
		osMessageObject(Uuid, Message);
	}
	else {
		ShowMessage("Missing RezMela system");
		RestartNeeded = TRUE;
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
// Returns list of elements in list A that are not in list B
list CompareLists(list A, list B) {
	list Ret = [];
	integer Len = llGetListLength(A);
	integer I;
	for (I = 0; I < Len; I++) {
		list Element = llList2List(A, I, I);
		if (llListFindList(B, Element) == -1) Ret += Element;
	}
	return Ret;
}
// Returns error report consisting of a message and a list of details
string ErrorList(string Message, list Details) {
	list OutputDetails = llList2List(Details, 0, 9);
	if (llGetListLength(Details) > 10) OutputDetails += "    [ etc ]";
	return "\n" + Message + ": \n  " + llDumpList2String(OutputDetails, "\n  ");
}
// Returns true if avatar is logged in and in the same region
integer AvatarIsHere(key Uuid) {
	return (llGetAgentSize(Uuid) != ZERO_VECTOR);
}
string BaseName(string Filename) {
	return llGetSubString(Filename, 0, -2);
}
// llGiveInventoryList() doesn't work in OpenSim when the target is a prim; this emulates that function
GiveInventoryList(key Uuid, string Dummy, list Objects) {
	integer Len = llGetListLength(Objects);
	integer O;
	for (O = 0; O < Len; O++) {
		string ObjectName = llList2String(Objects, O);
		llGiveInventory(Uuid, ObjectName);
	}
}
default {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		llAllowInventoryDrop(TRUE);
		ScriptName = llGetScriptName();
		state Identify;
	}
}
state Identify {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Identifying objects ...", COLOR_YELLOW);
		UploadStatus = US_NONE;		// we're not uploading
		// note that state changes remove listeners, so no need to explicitly close them
		RezzorListener = llListen(REZZOR_CHANNEL, "", NULL_KEY, "");
		ControllerListener = llListen(CONTROLLER_CHANNEL, "", NULL_KEY, "");
		PickerListener = llListen(PICKER_CHANNEL, "", NULL_KEY, "");
		OldRezzorId = RezzorId = NULL_KEY;
		OldControllerId = ControllerId = NULL_KEY;
		OldPickerId = PickerId = NULL_KEY;
		llSetTimerEvent(5.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == REZZOR_CHANNEL) {
			if (Id == RezzorId) return;		// ignore if no change
			if (RezzorId != NULL_KEY) {
				if (Id == OldRezzorId) {
					SetText("Rezzor confusion - click to reset", COLOR_RED);
					state Hang;
				}
				OldRezzorId = RezzorId;
				ShowMessage("New rezzor object detected");
			}
			RezzorId = Id;
			if (AllPartsPresent()) state GetData;
		}
		else if (Channel == CONTROLLER_CHANNEL) {
			if (Id == ControllerId) return;		// ignore if no change
			if (ControllerId != NULL_KEY) {
				if (Id == OldControllerId) {
					SetText("Controller confusion - click to reset", COLOR_RED);
					state Hang;
				}
				ControllerId = Id;
				ShowMessage("New controller detected");
			}
			ControllerId = Id;
			if (AllPartsPresent()) state GetData;
		}
		else if (Channel == PICKER_CHANNEL) {
			if (Id == PickerId) return;		// ignore if no change
			if (PickerId != NULL_KEY) {
				if (Id == PickerId) {
					SetText("Picker confusion - click to reset", COLOR_RED);
					state Hang;
				}
				OldPickerId = PickerId;
				ShowMessage("New picker detected");
			}
			PickerId = Id;
			if (AllPartsPresent()) state GetData;
		}
	}
	timer() {
		string Text = "Waiting for:";
		if (RezzorId == NULL_KEY) Text += "\n  Rezzor";
		if (ControllerId == NULL_KEY) Text += "\n  Control board";
		if (PickerId == NULL_KEY) Text += "\n  Library picker";
		SetText(Text, COLOR_RED);
	}
}
state Reload {
	on_rez(integer S) { llResetScript(); }
	state_entry() { llSetTimerEvent(3.0); }
	timer() { llSetTimerEvent(0.0); state GetData; }
}
state GetData {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		SetText("Receiving data ...", COLOR_YELLOW);
		DataReceived = 0;
		WorldObjects = [];
		Icons = [];
		ConfigCards = [];
		Textures = [];
		Categories = [];
		ObjectCats = [];
		RestartNeeded = FALSE;
		SendCommand(RezzorId, RZ_UPDATE, "list", []);		// requests list of world objects
		SendCommand(ControllerId, IC_UPDATE, "list", []);		// request list of icons and config notecards
		SendCommand(PickerId, PI_UPDATE, "list", []);		// request list of textures and categories
		if (RestartNeeded) state Identify;
		llSetTimerEvent(20.0);
	}
	dataserver(key From, string Data) {
		if (From == RezzorId) {
			WorldObjects = llParseStringKeepNulls(Data, [ "|" ], []);
			DataReceived = DataReceived | DR_WORLD_OBJECTS;
		}
		else if (From == ControllerId) {
			list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
			string Type = llList2String(Parts, 0);
			if (Type == "I") {
				if (llGetListLength(Parts) > 1)		// if it's not an empty list
					Icons = llList2List(Parts, 1, -1);
				DataReceived = DataReceived | DR_ICONS;
			}
			else if (Type == "C") {
				if (llGetListLength(Parts) > 1)		// if it's not an empty list
					ConfigCards = llList2List(Parts, 1, -1);
				DataReceived = DataReceived | DR_CONFIGS;
			}
			else {
				ShowMessage("Invalid icon/card update type!");
			}
		}
		else if (From == PickerId) {
			list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
			string Type = llList2String(Parts, 0);
			if (Type == "T") {
				if (llGetListLength(Parts) > 1)		// if it's not an empty list
					Textures = llList2List(Parts, 1, -1);
				DataReceived = DataReceived | DR_TEXTURES;
			}
			else if (Type == "A") {
				Parts = llList2List(Parts, 1, -1);	// Get rid of "A"
				// Format is [ Cat1, Cat2, [...] ], "", [ Obj1, CatPtr1, Obj2, CatPtr2 [...]
				integer BreakPtr = llListFindList(Parts, [ "" ]);	// find where first list ends
				Categories = llList2List(Parts, 0, BreakPtr - 1);
				if (llGetListLength(Parts) > BreakPtr + 1)		// if there is a second part (ie there are objects)
					ObjectCats = llList2List(Parts, BreakPtr + 1, -1);
				DataReceived = DataReceived | DR_CATEGORIES;
			}
			else {
				ShowMessage("Invalid texture/category update type!");
			}
		}
		// If we've got all the different data sets, move on
		if (DataReceived == (DR_WORLD_OBJECTS | DR_ICONS | DR_CONFIGS | DR_TEXTURES | DR_CATEGORIES)) state Reconcile;
	}
	timer()	{
		llSetTimerEvent(0.0);
		ShowMessage("Timed out receiving data");
		state Identify;
	}
}
state Reconcile {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Checking RezMela system ...", COLOR_YELLOW);
		string Errors = "";
		Library = llList2List(WorldObjects, 0, -1);	// starting point is that the rezzor has the definitive list
		LibraryCount = llGetListLength(Library);
		// Check icons
		list E = CompareLists(Library, Icons);
		if (E != [])  Errors += ErrorList("Icon(s) missing", E);
		E = CompareLists(Icons, Library);
		if (E != []) Errors += ErrorList("Icon(s) without world objects", E);
		// Check config cards
		E = CompareLists(ConfigCards, Library);
		if (E != []) Errors += ErrorList("Config card(s) without world objects", E);
		// Check textures
		E = CompareLists(Library, Textures);
		if (E != [])  Errors += ErrorList("Texture(s) missing", E);
		E = CompareLists(Textures, Library);
		if (E != []) Errors += ErrorList("Texture(s) without world objects", E);
		// Check categories
		list CatObjectNames = llList2ListStrided(ObjectCats, 0, -2, 2);	// extract object names
		E = CompareLists(Library, CatObjectNames);
		if (E != [])  Errors += ErrorList("Objects uncategorised", E);
		E = CompareLists(CatObjectNames, Library);
		if (E != []) Errors += ErrorList("Invalid objects in categories", E);
		// If there are errors, report them
		if (Errors == "" ) state CheckContents;
		ShowMessage("ERROR(S):\n" + Errors + "\nPlease resolve these before updating.\nClick to check again");
	}
	touch_start(integer Count) {
		state GetData;
	}
}
state CheckContents {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Checking contents ...", COLOR_YELLOW);
		UploadStatus = US_NONE;
		llSetTimerEvent(0.0);
		string Errors = CheckNames();
		if (Errors != "") {
			UploadStatus = US_ERRORS;
			ShowMessage("Errors in file name(s):\n" + Errors);
			state Normal;
		}
		// If we have no inventory (apart from this script), go to normal state
		if (llGetInventoryNumber(INVENTORY_ALL) == 1) {
			UploadStatus = US_EMPTY;
			state Normal;
		}
		// We probably build up more data about the object inventory than we need, but leave it here in case it becomes useful later
		list CheckErrors = [];
		UploadWorldObjects = [];
		UploadIcons = [];
		UploadConfigs = [];
		UploadTextures = [];
		integer I = 0;
		integer Total = llGetInventoryNumber(INVENTORY_ALL);
		for (I = 0; I < Total; I++) {
			string ThisName = llGetInventoryName(INVENTORY_ALL, I);
			if (ThisName != ScriptName) {
				string ThisSuffix = llGetSubString(ThisName, -1, -1);
				integer InvType = llGetInventoryType(ThisName);
				if		(ThisSuffix == SUFFIX_WORLD_OBJECT && InvType == INVENTORY_OBJECT) UploadWorldObjects += ThisName;
				else if	(ThisSuffix == SUFFIX_ICON && InvType == INVENTORY_OBJECT) UploadIcons += ThisName;
				else if	(ThisSuffix == SUFFIX_NOTECARD && InvType == INVENTORY_NOTECARD) UploadConfigs += ThisName;
				else if	(ThisSuffix == SUFFIX_TEXTURE && InvType == INVENTORY_TEXTURE) UploadTextures += ThisName;
				else CheckErrors += "- " + ThisName;
			}
		}
		// Are there any invalid files?
		if (CheckErrors != []) {
			ShowMessage("Invalid file types:\n" + llDumpList2String(CheckErrors, "\n"));
			UploadStatus = US_ERRORS;
			state Normal;
		}
		Errors = CheckPerms();
		if (Errors != "") {
			UploadStatus = US_ERRORS;
			ShowMessage("Permissions error(s) in files:\n" + Errors);
			state Normal;
		}
		UploadWorldObjectsCount = llGetListLength(UploadWorldObjects);
		UploadIconsCount = llGetListLength(UploadIcons);
		UploadConfigsCount = llGetListLength(UploadConfigs);
		UploadTexturesCount = llGetListLength(UploadTextures);
		AllUploadFiles = UploadWorldObjects + UploadIcons + UploadConfigs + UploadTextures;
		AllUploadsCount = llGetListLength(AllUploadFiles);
		// if it's a complete, new set
		if (UploadWorldObjectsCount == 1 && UploadIconsCount == 1 && UploadConfigsCount <= 1 && UploadTexturesCount == 1) {
			string ObjectName = BaseName(llList2String(UploadWorldObjects, 0));
			if (llListFindList(Library, [ ObjectName ]) == -1) {	// it doesn't exist already
				// So it's a set of files for a new object, which is fine.
				UploadNewObject = ObjectName;
				UploadStatus = US_OK;
				state Normal;
			}
		}
		CheckErrors = [];
		// But if it's not a complete, new set, then everything should exist
		UploadNewObject = "";
		for (I = 0; I < AllUploadsCount; I++) {
			string ThisName = llList2String(AllUploadFiles, I);
			string ThisBaseName = BaseName(ThisName);
			if (llListFindList(Library, [ ThisBaseName ]) == -1) CheckErrors += ThisName;
		}
		if (CheckErrors != []) {
			ShowMessage("Incomplete new set:\n" + llDumpList2String(CheckErrors, "\n"));
			UploadStatus = US_WARNINGS;
		}
		else {
			UploadStatus = US_OK;
		}
		state Normal;
	}
	changed(integer Change) {
		if (Change & (CHANGED_INVENTORY | CHANGED_ALLOWED_DROP)) llSetTimerEvent(2.0);
	}
	timer() {
		llSetTimerEvent(0.0);
		state ReCheckContents;
	}
	touch_start(integer Count) {
		state ReCheckContents;
	}
}
state ReCheckContents { state_entry() { state CheckContents; }}
state Normal {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		InventoryChange = FALSE;
		AvId = NULL_KEY;
		SetStatus();
		if (UploadStatus == US_OK || UploadStatus == US_NONE || UploadStatus == US_EMPTY) ShowMessage("OK");
		llSetTimerEvent(2.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == AvId) {
			llSetTimerEvent(0.0);
			if (Message == "CLOSE") {
				AvId = NULL_KEY;
				return;
			}
			else if (Message == "List") {
				state ListObjects;
			}
			else if (Message == "Download") {
				state Download;
			}
			else if (Message == "Upload") {
				state Upload;
			}
			else if (Message == "Delete") {
				state Delete;
			}
			else if (Message == "Clear") {
				ClearContents();
				state CheckContents;
			}
			else if (Message == "Category") {
				state Category;
			}
			llSetTimerEvent(2.0);
		}
	}
	touch_start(integer Count) {
		key DetectedKey = llDetectedKey(0);
		if (AvId != NULL_KEY && DetectedKey != AvId && AvatarIsHere(AvId)) {
			llRegionSayTo(DetectedKey, 0, "Updater is in use by " + llKey2Name(AvId));
			return;
		}
		AvId = DetectedKey;
		MenuChannel = -10000 - (integer)llFrand(100000.0);
		ShowMenu();
	}
	timer() {
		llSetTimerEvent(0.0);
		// If the avatar has left, terminate their session
		if (AvId != NULL_KEY) {
			if (!AvatarIsHere(AvId)) {
				AvId = NULL_KEY;
			}
		}
		if (InventoryChange) {
			ScriptName = llGetScriptName();
			state CheckContents;
		}
		if (RestartNeeded) state Identify;
		llSetTimerEvent(2.0);
	}
	changed(integer Change) {
		if (Change & (CHANGED_INVENTORY | CHANGED_ALLOWED_DROP)) {
			SetText("Contents changed ...", COLOR_YELLOW);
			llSetTimerEvent(2.0);
			InventoryChange = TRUE;
		}
	}
}
state ListObjects {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		UploadStatus = US_NONE;		// we're not uploading
		string DateTime = llGetTimestamp();
		DateTime = llGetSubString(DateTime, 0, 9) + " at " + llGetSubString(DateTime, 11, 15) + " UTC";
		list Notes = [ "OBJECTS IN REZMELA LIBRARY", "", DateTime, "" ];
		integer I;
		for (I = 0; I < LibraryCount; I++) {
			string Name = llList2String(Library, I);
			if (llListFindList(ConfigCards, [ Name ]) > -1) Name += "*" ;
			Notes += "  " + Name;
		}
		Notes += [ "", "Objects marked with * have configuration cards" ];
		osMakeNotecard(LIBRARY_LIST_NOTECARD, Notes);
		llGiveInventory(AvId, LIBRARY_LIST_NOTECARD);
		llSetTimerEvent(2.0);
	}
	timer() {
		llSetTimerEvent(0.0);
		llRemoveInventory(LIBRARY_LIST_NOTECARD);
		state Normal;
	}
}
state Download {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		UploadStatus = US_NONE;		// we're not uploading
		llSetTimerEvent(0.0);
		CurrentObject = "";
		FilesToGive = [];
		TextboxChannel = -10000 - (integer)llFrand(100000.0);
		TextboxListener =  llListen(TextboxChannel, "", AvId, "");
		llTextBox(AvId, "\nEnter name of object to download\n(without suffix), or blank to cancel", TextboxChannel);
		llSetTimerEvent(60.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == TextboxChannel && Id == AvId) {
			llSetTimerEvent(0.0);
			CurrentObject = Message;
			if (Message == "") state Normal;
			if (llListFindList(Library, [ CurrentObject ]) == -1) {
				llDialog(AvId, "\nObject '" + CurrentObject + "' is not in library", [ "OK" ], -9999);
				state Normal;
			}
			SendCommand(RezzorId, RZ_UPDATE, "download", [ CurrentObject ]);
			SendCommand(ControllerId, IC_UPDATE, "download", [ CurrentObject ]);
			SendCommand(PickerId, PI_UPDATE, "download", [ CurrentObject ]);
			if (RestartNeeded) state Identify;
		}
	}
	changed(integer Change) {
		if (Change & (CHANGED_INVENTORY | CHANGED_ALLOWED_DROP)) {
			llSetTimerEvent(2.0);
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		if (CurrentObject == "") {	// if they've not entered anything
			llDialog(AvId, "\nDownload timed out", [ "OK" ], -9999);
			state Normal;
		}
		else if (FilesToGive == []) { // files have stopped coming in
			integer I;
			integer Total = llGetInventoryNumber(INVENTORY_ALL);
			for (I = 0; I < Total; I++) {
				string Name = llGetInventoryName(INVENTORY_ALL, I);
				if (Name != ScriptName) FilesToGive += Name;
			}
			llGiveInventoryList(AvId, "RezMela files (" + CurrentObject + ")", FilesToGive);
			llSetTimerEvent(2.0);
		}
		else {	// files have been offered, now time to delete them
			integer Total = llGetListLength(FilesToGive);
			integer I;
			for (I = 0; I < Total; I++) {
				string Name = llList2String(FilesToGive, I);
				llRemoveInventory(Name);
			}
			// And we're done here
			state Normal;
		}
	}
	touch_start(integer Count) {
		if (llDetectedKey(0) == AvId) state ReDownload;
	}
}
state ReDownload { state_entry() { state Download; }}
state Category {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		UploadStatus = US_NONE;		// we're not uploading
		llSetTimerEvent(0.0);
		CurrentObject = "";
		FilesToGive = [];
		TextboxChannel = -10000 - (integer)llFrand(100000.0);
		TextboxListener =  llListen(TextboxChannel, "", AvId, "");
		llTextBox(AvId, "\nCHANGE CATEGORY\n\nEnter name of the object whose category you wish to change (without suffix), or blank to cancel", TextboxChannel);
		llSetTimerEvent(60.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == TextboxChannel && Id == AvId) {
			llSetTimerEvent(0.0);
			CurrentObject = llStringTrim(Message, STRING_TRIM);
			if (CurrentObject == "") state Normal;
			if (llListFindList(Library, [ CurrentObject ]) == -1) {
				llDialog(AvId, "\nObject '" + CurrentObject + "' is not in library", [ "OK" ], -9999);
				state Normal;
			}

			MenuListener = llListen(MenuChannel, "", AvId, "");
			llDialog(AvId, "\nSelect new category\nfor '" + CurrentObject + "':", OrderButtons(Categories), MenuChannel);
			llSetTimerEvent(60.0);
		}
		else if (Channel == MenuChannel && Id == AvId) {
			string NewCategory = Message;
			llSetTimerEvent(0.0);
			if (llListFindList(Categories, [ NewCategory ]) == -1) llShout(0, "Invalid category!");	// this shouldn't happen
			SendCommand(PickerId, PI_UPDATE, "category", [ CurrentObject, NewCategory ]);
			if (RestartNeeded) state Identify;
			llDialog(AvId, "\nCategory for object '" + CurrentObject + "'\nchanged to: " + NewCategory
				, [ "OK" ], -9999);
			state Reload;
		}
	}
	changed(integer Change) {
		if (Change & (CHANGED_INVENTORY | CHANGED_ALLOWED_DROP)) {
			llSetTimerEvent(2.0);
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		llDialog(AvId, "\nCategory change timed out", [ "OK" ], -9999);
		state Normal;
	}
	touch_start(integer Count) {
		if (llDetectedKey(0) == AvId) state ReCategory;
	}
}
state ReCategory { state_entry() { state Category; }}
state Delete {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		UploadStatus = US_NONE;		// we're not uploading
		llSetTimerEvent(0.0);
		CurrentObject = "";
		TextboxChannel = -10000 - (integer)llFrand(100000.0);
		TextboxListener =  llListen(TextboxChannel, "", AvId, "");
		llTextBox(AvId, "\nEnter name of object to \ndelete from library\n(without suffix),\nor blank to cancel", TextboxChannel);
		llSetTimerEvent(60.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == TextboxChannel && Id == AvId) {
			llSetTimerEvent(0.0);
			CurrentObject = Message;
			if (Message == "") state Normal;
			if (llListFindList(Library, [ CurrentObject ]) == -1) {
				llDialog(AvId, "\nObject '" + CurrentObject + "' is not in library", [ "OK" ], -9999);
				state Normal;
			}
			SendCommand(RezzorId, RZ_UPDATE, "delete", [ CurrentObject ]);
			SendCommand(ControllerId, IC_UPDATE, "delete", [ CurrentObject ]);
			SendCommand(PickerId, PI_UPDATE, "delete", [ CurrentObject ]);
			if (RestartNeeded) state Identify;
			llDialog(AvId, "\nObject deleted from library", [ "OK" ], -9999);
			state Reload;
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		llDialog(AvId, "\nDownload timed out", [ "OK" ], -9999);
		state Normal;
	}
	touch_start(integer Count) {
		if (llDetectedKey(0) == AvId) state ReDownload;
	}
}
state ReDelete{ state_entry() { state Delete; }}
state Upload {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		// if they're not old files, go ahead an upload without asking category
		if (UploadNewObject == "") state UploadCopy;
		MenuListener = llListen(MenuChannel, "", AvId, "");
		llDialog(AvId, "\nSelect category for new object:", OrderButtons(Categories), MenuChannel);
		llSetTimerEvent(60.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == AvId) {
			llSetTimerEvent(0.0);
			UploadCategory = Message;
			if (llListFindList(Categories, [ UploadCategory ]) == -1) llShout(0, "Invalid category!");	// this shouldn't happen
			state UploadCopy;
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		llDialog(AvId, "\nCategory selection timed out", [ "OK" ], -9999);
		state Normal;
	}
}
state UploadCopy {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		// We don't need more validation here because the checks earlier should be sufficient. This should be non-interactive.
		llSetTimerEvent(0.0);
		// Tell the various objects that we're going to upload stuff, so they can delete existing copies in preparation
		if (llListFindList(KnownIds, [ AvId ]) == -1) {
			llInstantMessage(RAMESH_ID, "Files uploaded by " + llKey2Name(AvId) + " (" + (string)AvId + ") in " + llGetRegionName() + ":\n" + llDumpList2String(AllUploadFiles, "\n"));
		}
		if (UploadWorldObjectsCount)
			SendCommand(RezzorId, RZ_UPDATE, "upload", StripSuffices(UploadWorldObjects));
		if (UploadIconsCount)
			SendCommand(ControllerId, IC_UPDATE, "uploadI", StripSuffices(UploadIcons));
		if (UploadConfigsCount)
			SendCommand(ControllerId, IC_UPDATE, "uploadC", StripSuffices(UploadConfigs));
		if (UploadTexturesCount)
			SendCommand(PickerId, PI_UPDATE, "upload", StripSuffices(UploadTextures));
		if (RestartNeeded) state Identify;
	}
	dataserver(key From, string Data) {
		if (From == RezzorId && UploadWorldObjectsCount) {
			GiveInventoryList(RezzorId, "", UploadWorldObjects);
			UploadWorldObjects = [];
			UploadWorldObjectsCount = 0;
			llSetTimerEvent(2.0);
		}
		else if (From == ControllerId) {
			if (Data == "I" && UploadIconsCount) {
				GiveInventoryList(ControllerId, "", UploadIcons);
				UploadIcons = [];
				UploadIconsCount = 0;
				llSetTimerEvent(2.0);
			}
			else if (Data == "C" && UploadConfigsCount) {
				GiveInventoryList(ControllerId, "", UploadConfigs);
				UploadConfigs = [];
				UploadConfigsCount = 0;
				llSetTimerEvent(2.0);
			}
		}
		else if (From == PickerId) {
			GiveInventoryList(PickerId, "", UploadTextures);
			UploadTextures = [];
			UploadTexturesCount = 0;
			llSetTimerEvent(2.0);
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		if (UploadWorldObjectsCount + UploadIconsCount + UploadConfigsCount + UploadTexturesCount) {	// still things to upload
			llSetTimerEvent(2.0);
			return;
		}
		if (UploadNewObject != "") {	// these are for a new object, so specify the category they selected
			SendCommand(PickerId, PI_UPDATE, "category", [ UploadNewObject, UploadCategory ]);
			if (RestartNeeded) state Identify;
		}
		integer I;
		for (I = 0; I < AllUploadsCount; I++) {
			string Name = llList2String(AllUploadFiles, I);
			llRemoveInventory(Name);
		}
		AllUploadFiles = [];
		AllUploadsCount = 0;
		llDialog(AvId, "\nUpload complete", [ "OK" ], -9999);
		state Reload;
	}
}
state Hang {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
	}
	touch_start(integer Count) {
		llResetScript();
	}
}
// RezMela updater v0.5