// RezMela updater HUD v0.3

// TODO:
// - check no-mod perms for scripts
// - check that all necessary scripts and objects exist (same function?)
// - reset on change of region

// v0.3 - texture change-back; permissions check on foreign objects only; perms check not for next or for transfer

// Needs status messages during import
// make sure that all states have on_rez() to reset script in case of change of owner, etc

key RezzorId;
key OldRezzorId;
key ControllerId;
key OldControllerId;
key PickerId;
key OldPickerId;

key MAIN_TEXTURE = "87f3db72-827e-498a-ba51-5d0f2785ecdd";

integer OBJECT_PIN = 50200;

integer REZZOR_CHANNEL = -355210124;
integer CONTROLLER_CHANNEL = -94040100;
integer PICKER_CHANNEL = -209441200;
integer IMPORTER_CHANNEL = -81140900;

string CONFIG_NOTECARD = "RezMela updater config";
string IMPORTER_SCRIPT = "RezMela importer";
string PLATFORM_NAME = "RezMela importer platform";
string WO_SCRIPT_NAME = "RezMela WorldObject";
string ICON_SCRIPT_NAME = "RezMela Icon";

vector PLATFORM_REZ_OFFSET = <4.0, 0.0, -0.5>;
vector PLATFORM_REZ_ROTATION = <0.0, 0.0, 270.0>;	// Euler degrees

string ImporterScriptName;
string WorldObjectScriptName;
string IconScriptName;
string PlatformName;
key PlatformUuid;

integer RezzorListener;
integer ControllerListener;
integer PickerListener;
integer ImporterListener;

integer ConfigCentered;
integer ConfigVertical;
integer ConfigResizable;

string SUFFIX_ICON = "I";
string SUFFIX_NOTECARD = "C";
string SUFFIX_TEXTURE = "T";
string SUFFIX_WORLD_OBJECT = "W";

// Integration constants
integer RZ_PING = 2000;
integer RZ_UPDATE = 2004;
integer IC_UPDATE = 1021;
integer PI_UPDATE = 8400;
integer GE_DELETE = 9001;

integer DataReceived;	// bitfields
integer DR_NONE				= 0;
integer DR_WORLD_OBJECTS 	= 1;
integer DR_ICONS 			= 2;
integer DR_CONFIGS 			= 4;
integer DR_TEXTURES 			= 8;
integer DR_CATEGORIES		= 16;

string UploadNewObject;
integer IconType;
integer ICON_MINIATURE = 1;
integer ICON_FLAT = 2;

float ScalingFactor;
vector ObjectTotalSize;
integer PlatformHasUpdatedScript;

list Library;
integer LibraryCount;
list WorldObjects;
list Icons;
list ConfigCards;
list Textures;
list Categories;
list ObjectCats;

integer Phase;
integer PhasesInState;
integer SkipWizard;

key NewObjectId;
key NewIconId;

integer RestartNeeded;
integer InventoryChange;

vector COLOR_GREEN = <0.5, 1.0, 0.5>;
vector COLOR_YELLOW = <1.0, 1.0, 0.2>;
vector COLOR_RED = <1.0, 0.2, 0.2>;

string LIBRARY_LIST_NOTECARD = "RezMela library contents";

key OwnerId;
integer MenuChannel;
integer MenuListener;
integer TextboxChannel;
integer TextboxListener;

string ScriptName;

string CurrentObject;

list UploadWorldObjects;
list UploadIcons;
list UploadConfigs;
list UploadTextures;
list AllUploadFiles;

integer UploadWorldObjectsCount;
integer UploadIconsCount;
integer UploadConfigsCount;
integer UploadTexturesCount;
integer AllUploadsCount;
string UploadCategory;

integer TEXT_DISPLAY = -77911300;

string BUTTON_CLEAR = "Clear";
string BUTTON_RETRY = "Retry";
string BUTTON_CLOSE = "CLOSE";
string BUTTON_CATEGORY = "Category";
string BUTTON_DELETE = "Delete";
string BUTTON_LIST = "List";
string BUTTON_IMPORT = "New";
string BUTTON_UPDATE = "Update";
string BUTTON_DOWNLOAD = "Download";
string BUTTON_NEXT = "Next >";
string BUTTON_BACK = "< Back";
string BUTTON_CANCEL = "Cancel";
string BUTTON_GET_IMPORTER = "Get script";
string BUTTON_CENTERED = "Centered";
string BUTTON_VERTICAL = "Vertical";
string BUTTON_RESIZEABLE = "Resizable";
string BUTTON_FINISHED = "Finished";

string CurrentDialogText;
list CurrentDialogButtons;
integer CurrentDialogTime;

ShowMenu() {
	string Text = "REZMELA UPDATER\n\n";
	list Buttons = [];
	integer InvCount = GetInventoryCount();
	if (InvCount) {
		Text += "The updater is not empty. Click '" + BUTTON_CLEAR + "' to remove, or '" + BUTTON_RETRY + "' to retry";
		Buttons = [ BUTTON_CLEAR, BUTTON_RETRY ];
	}
	else {
		// Bottom row
		if (InvCount) Buttons += BUTTON_CLEAR; else Buttons += " ";
		Buttons += [ " ", BUTTON_CLOSE ];
		// Middle row
		Buttons += [ BUTTON_CATEGORY, BUTTON_DELETE, BUTTON_LIST ];
		// Top row
		Buttons += [ BUTTON_IMPORT, BUTTON_UPDATE, BUTTON_DOWNLOAD ];
		if (ButtonExists(Buttons, BUTTON_IMPORT)) Text += BUTTON_IMPORT + " - add new object to library\n";
		if (ButtonExists(Buttons, BUTTON_UPDATE)) Text += BUTTON_UPDATE + " - upload new version of library object\n";
		if (ButtonExists(Buttons, BUTTON_DOWNLOAD)) Text += BUTTON_DOWNLOAD + " - get files from library\n";
		if (ButtonExists(Buttons, BUTTON_CATEGORY)) Text += BUTTON_CATEGORY + " - change category of library object\n";
		if (ButtonExists(Buttons, BUTTON_DELETE)) Text += BUTTON_DELETE + " - remove object from library\n";
		if (ButtonExists(Buttons, BUTTON_LIST)) Text += BUTTON_LIST + " - get list of objects in library\n";
		if (ButtonExists(Buttons, BUTTON_CLEAR)) Text += BUTTON_CLEAR + " - clear all files from contents\n";
		if (ButtonExists(Buttons, BUTTON_CLOSE)) Text += BUTTON_CLOSE + " - close this menu\n";
	}
	MenuChannel = -10000 - (integer)llFrand(100000.0);
	MenuListener = llListen(MenuChannel, "", OwnerId, "");
	llDialog(OwnerId, Text, Buttons, MenuChannel);
}
Dialog(string Text, list Buttons) {
	MenuListener = llListen(MenuChannel, "", OwnerId, "");
	llDialog(OwnerId, "\n" + Text, Buttons, MenuChannel);
	CurrentDialogTime = llGetUnixTime();
	CurrentDialogText = Text;
	CurrentDialogButtons = Buttons;
}
// redisplay menu
DialogTouch() {
	llDialog(OwnerId, "\n" + CurrentDialogText, CurrentDialogButtons, MenuChannel);
}
DialogOK(string Text) {
	llDialog(OwnerId, "\n" + Text, [ "OK" ], -9999);
}
integer ButtonExists(list Buttons, string Button) {
	return (llListFindList(Buttons, [ Button ]) > -1);
}
list OrderButtons(list Buttons) {
	return llList2List(Buttons, -3, -1) + llList2List(Buttons, -6, -4)
		+ llList2List(Buttons, -9, -7) + llList2List(Buttons, -12, -10);
}
RezPlatform() {
	PlatformHasUpdatedScript = FALSE;
	llRezObject(PlatformName, llGetPos() + (PLATFORM_REZ_OFFSET * llGetRot()), ZERO_VECTOR, llEuler2Rot(PLATFORM_REZ_ROTATION * DEG_TO_RAD), 1);
}
PlatformRezzed(key Uuid) {
	PlatformUuid = Uuid;
	llRemoteLoadScriptPin(PlatformUuid, ImporterScriptName, OBJECT_PIN, TRUE, 1);
	PlatformHasUpdatedScript = TRUE;
}
//integer CheckContents() {
//	SetText("Checking contents ...", COLOR_YELLOW);
//	string Errors = CheckNames();
//	if (Errors != "") {
//		ShowMessage("Errors in file name(s):\n" + Errors);
//		return FALSE;
//	}
//	// If we have no inventory (apart from this script), go to normal state
//	if (llGetInventoryNumber(INVENTORY_ALL) == 1) {
//		UploadStatus = US_EMPTY;
//		state Normal;
//	}
//	// We probably build up more data about the object inventory than we need, but leave it here in case it becomes useful later
//	list CheckErrors = [];
//	UploadWorldObjects = [];
//	UploadIcons = [];
//	UploadConfigs = [];
//	UploadTextures = [];
//	integer I = 0;
//	integer Total = llGetInventoryNumber(INVENTORY_ALL);
//	for (I = 0; I < Total; I++) {
//		string ThisName = llGetInventoryName(INVENTORY_ALL, I);
//		if (ThisName != ScriptName) {
//			string ThisSuffix = llGetSubString(ThisName, -1, -1);
//			integer InvType = llGetInventoryType(ThisName);
//			if		(ThisSuffix == SUFFIX_WORLD_OBJECT && InvType == INVENTORY_OBJECT) UploadWorldObjects += ThisName;
//			else if	(ThisSuffix == SUFFIX_ICON && InvType == INVENTORY_OBJECT) UploadIcons += ThisName;
//			else if	(ThisSuffix == SUFFIX_NOTECARD && InvType == INVENTORY_NOTECARD) UploadConfigs += ThisName;
//			else if	(ThisSuffix == SUFFIX_TEXTURE && InvType == INVENTORY_TEXTURE) UploadTextures += ThisName;
//			else CheckErrors += "- " + ThisName;
//		}
//	}
//	// Are there any invalid files?
//	if (CheckErrors != []) {
//		ShowMessage("Invalid file types:\n" + llDumpList2String(CheckErrors, "\n"));
//		return FALSE;
//	}
//	Errors = CheckPerms();
//	if (Errors != "") {
//		UploadStatus = US_ERRORS;
//		ShowMessage("Permissions error(s) in files:\n" + Errors);
//		return FALSE;
//	}
//	UploadWorldObjectsCount = llGetListLength(UploadWorldObjects);
//	UploadIconsCount = llGetListLength(UploadIcons);
//	UploadConfigsCount = llGetListLength(UploadConfigs);
//	UploadTexturesCount = llGetListLength(UploadTextures);
//	AllUploadFiles = UploadWorldObjects + UploadIcons + UploadConfigs + UploadTextures;
//	AllUploadsCount = llGetListLength(AllUploadFiles);
//
//	CheckErrors = [];
//	// But if it's not a complete, new set, then everything should exist
//	UploadNewObject = "";
//	for (I = 0; I < AllUploadsCount; I++) {
//		string ThisName = llList2String(AllUploadFiles, I);
//		string ThisBaseName = BaseName(ThisName);
//		if (llListFindList(Library, [ ThisBaseName ]) == -1) CheckErrors += ThisName;
//	}
//	if (CheckErrors != []) {
//		ShowMessage("Incomplete new set:\n" + llDumpList2String(CheckErrors, "\n"));
//		UploadStatus = US_WARNINGS;
//	}
//	else {
//		UploadStatus = US_OK;
//	}
//	state Normal;
//}

// Find number of files in inventory, excluding system files
integer GetInventoryCount() {
	return llGetListLength(ForeignFiles());
}
// Remove all foreign files in contents
ClearContents() {
	list ToClear = ForeignFiles();
	integer Total = llGetListLength(ToClear);
	integer I;
	for (I = 0; I < Total; I++) {
		string Name = llList2String(ToClear, I);
		llRemoveInventory(Name);
	}
}
// Give all foreign files in contents
GiveContents() {
	llGiveInventoryList(OwnerId, "RezMela files (" + CurrentObject + ")", ForeignFiles());
}
// Returns list of all files in contents that are not part of the application
list ForeignFiles() {
	ScriptName = llGetScriptName();
	list Files = [];
	integer I;
	integer Total = llGetInventoryNumber(INVENTORY_ALL);
	for (I = 0; I < Total; I++) {
		string Name = llGetInventoryName(INVENTORY_ALL, I);
		if (Name != ScriptName &&
			Name != CONFIG_NOTECARD &&
				Name != PlatformName &&	// LSLEditor indents weirdly sometimes
					Name != ImporterScriptName &&
						Name != IconScriptName &&
							Name != WorldObjectScriptName)
								Files += Name;
	}
	return Files;
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
//	Is StrippedName the first part of FullName?
integer NameCompare(string FullName, string StrippedName) {
	return (llGetSubString(FullName, 0, llStringLength(StrippedName) - 1) == StrippedName);
}
// Returns errors if found, null if OK
string CheckPerms() {
	list ToCheck = ForeignFiles();
	string Errors = "";
	integer I = 0;
	integer Total = llGetListLength(ToCheck);
	for (I = 0; I < Total; I++) {
		string Name = llList2String(ToCheck, I);
		if (!PermsOK(Name)) {
			Errors += "- " + Name + "\n";
		}
	}
	return Errors;
}
// Check permissions of inventory object, notecard, etc
integer PermsOK(string Name) {
	//return (PermsCheck(Name, MASK_BASE) && PermsCheck(Name, MASK_OWNER) && PermsCheck(Name, MASK_NEXT));
	return (PermsCheck(Name, MASK_BASE) && PermsCheck(Name, MASK_OWNER));
}
integer PermsCheck(string Name, integer Mask) {
	integer Perms = llGetInventoryPermMask(Name, Mask);
	//return (Perms & PERM_COPY && Perms & PERM_MODIFY && Perms & PERM_TRANSFER);
	return (Perms & PERM_COPY && Perms & PERM_MODIFY);
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
// Set text on child prim
SetText(string Text, vector Color) {
	llSetLinkPrimitiveParamsFast(2, [ PRIM_TEXT, Text, Color, 1.0 ]);
}
ShowMessage(string Text) {
	llDialog(OwnerId, "\n" + Text, [ "OK" ], -1010101);
}
MessageOwner(string Text) {
	llOwnerSay(Text);
}
string Bool2Str(integer Bool) {
	if (Bool) return "TRUE"; else return "FALSE";
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
		SetText("Missing object", COLOR_RED);
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
// delete platform if it exists
DeletePlatform() {
	if (PlatformUuid != NULL_KEY) {
		MessageObject(PlatformUuid, "delete");
		PlatformUuid = NULL_KEY;
	}
}
// Returns dialog text for given option
string ConfigText(string ButtonName, integer Value, string Explanation) {
	string sValue = "off";
	if (Value) sValue = "ON";
	return ButtonName + " (" + sValue + ") - " + Explanation;
}
integer FindInventoryNames() {
	ImporterScriptName = "";
	PlatformName = "";
	WorldObjectScriptName = "";
	IconScriptName = "";
	integer N = llGetInventoryNumber(INVENTORY_ALL);
	integer I;
	for (I = 0; I < N; I++) {
		string Name = llGetInventoryName(INVENTORY_ALL, I);
		integer Type = llGetInventoryType(Name);
		if (Type == INVENTORY_SCRIPT && NameCompare(Name, IMPORTER_SCRIPT)) ImporterScriptName = Name;
		else if (Type == INVENTORY_OBJECT && NameCompare(Name, PLATFORM_NAME)) PlatformName = Name;
		else if (Type == INVENTORY_SCRIPT && NameCompare(Name, WO_SCRIPT_NAME)) WorldObjectScriptName = Name;
		else if (Type == INVENTORY_SCRIPT && NameCompare(Name, ICON_SCRIPT_NAME)) IconScriptName = Name;
	}
	if (ImporterScriptName == "") {
		DialogOK("ERROR! Can't find importer script");
		return FALSE;
	}
	if (PlatformName == "") {
		DialogOK("ERROR! Can't find platform object");
		return FALSE;
	}
	if (WorldObjectScriptName == "") {
		DialogOK("ERROR! Can't find World Object script");
		return FALSE;
	}
	if (IconScriptName == "") {
		DialogOK("ERROR! Can't find icon script");
		return FALSE;
	}
	return TRUE;
}
default {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		llSetRemoteScriptAccessPin(OBJECT_PIN);
		llAllowInventoryDrop(TRUE);
		OwnerId = llGetOwner();
		ScriptName = llGetScriptName();
		if (!FindInventoryNames()) state Hang;
		state Identify;
	}
}
state Identify {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Identifying objects ...", COLOR_YELLOW);
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
				llOwnerSay("New rezzor object detected");
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
				llOwnerSay("New controller detected");
			}
			ControllerId = Id;
			list L = llParseStringKeepNulls(Message, [ "|" ], []);
			ScalingFactor = (float)llList2String(L, 2);
			if (ScalingFactor < 0.001) {
				DialogOK("Scaling factor unknown (old version of RezMela controller script?)");
				state Hang;
			}
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
				llOwnerSay("New picker detected");
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
	state_entry() {
		SetText("Reloading data ...", COLOR_YELLOW);
		// This is to circumvent timing problems with object inventory, and/or comms, and may not actually be necessary.
		// So much has changed since this delay was introduced.
		llSetTimerEvent(3.0);
	}
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
				SetText("Invalid icon/card update type!", COLOR_RED);
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
				SetText("Invalid texture/category update type!", COLOR_RED);
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
		if (Errors == "" ) state Normal;
		SetText("Error(s) in RezMela system", COLOR_RED);
		ShowMessage("ERROR(S) IN REZMELA SYSTEM:\n" + Errors + "\nPlease resolve these before updating.\nClick HUD to check again");
	}
	touch_start(integer Count) {
		state GetData;
	}
}
state Normal {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Ready", COLOR_GREEN);
		llSetTimerEvent(0.0);
		InventoryChange = FALSE;
		llSetTimerEvent(2.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == OwnerId) {
			llSetTimerEvent(0.0);		// in case of state change
			if (Message == BUTTON_CLOSE) {
				return;
			}
			else if (Message == BUTTON_LIST) {
				state ListObjects;
			}
			else if (Message == BUTTON_DOWNLOAD) {
				state Download;
			}
			else if (Message == BUTTON_IMPORT) {
				state Import;
			}
			else if (Message == BUTTON_UPDATE) {
				state Update;
			}
			else if (Message == BUTTON_DELETE) {
				state Delete;
			}
			else if (Message == BUTTON_CLEAR) {
				ClearContents();
			}
			else if (Message == BUTTON_RETRY) {
				ShowMenu();
			}
			else if (Message == BUTTON_CATEGORY) {
				state Category;
			}
			llSetTimerEvent(2.0);
		}
	}
	touch_start(integer Count) {
		ShowMenu();
	}
	timer() {
		llSetTimerEvent(0.0);
		if (InventoryChange) {
			ScriptName = llGetScriptName();
			state ReNormal;
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
		if (Change & CHANGED_TEXTURE) {
			key Tex = llGetTexture(4);
			if (Tex != MAIN_TEXTURE) {
				llOwnerSay("Texture change detected - reverting ...");
				llSleep(2.0);
				llSetTexture(MAIN_TEXTURE, 4);
			}
		}
	}
}
state ReNormal { state_entry() { state Normal; }}
state ListObjects {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
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
		llGiveInventory(OwnerId, LIBRARY_LIST_NOTECARD);
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
		llSetTimerEvent(0.0);
		CurrentObject = "";
		Phase = 0;
		TextboxChannel = -10000 - (integer)llFrand(100000.0);
		TextboxListener =  llListen(TextboxChannel, "", OwnerId, "");
		llTextBox(OwnerId, "\nEnter name of object to download\n(without suffix), or blank to cancel", TextboxChannel);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == TextboxChannel) {
			llSetTimerEvent(0.0);
			CurrentObject = Message;
			if (Message == "") state Normal;
			if (llListFindList(Library, [ CurrentObject ]) == -1) {
				llDialog(OwnerId, "\nObject '" + CurrentObject + "' is not in library", [ "OK" ], -9999);
				state Normal;
			}
			SetText("Downloading files ...", COLOR_YELLOW);
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
		if (Phase == 0) { // files have stopped coming in
			GiveContents();
			Phase = 1;	// so next time we take the else path
			llSetTimerEvent(2.0);	// delay to make sure files are offered before deletion
			// Note: it seems to be sufficient to do this, even if user doesn't accept straight away. My understanding
			// is that the objects are actually transferred to the user's inventory when offered, and deleted if the offer
			// is declined. So the delay is just to give time for the transfer to happen (we have no better way of of knowing
			// when that happens). -- Handy
		}
		else {	// files have been offered, now time to delete them
			ClearContents();
			// And we're done here
			state Normal;
		}
	}
	touch_start(integer Count) {
		state ReDownload;
	}
}
state ReDownload { state_entry() { state Download; }}
state Category {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		CurrentObject = "";
		TextboxChannel = -10000 - (integer)llFrand(100000.0);
		TextboxListener =  llListen(TextboxChannel, "", OwnerId, "");
		llTextBox(OwnerId, "\nCHANGE CATEGORY\n\nEnter name of the object whose category you wish to change (without suffix), or blank to cancel", TextboxChannel);
		llSetTimerEvent(60.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == TextboxChannel) {
			llSetTimerEvent(0.0);
			CurrentObject = llStringTrim(Message, STRING_TRIM);
			if (CurrentObject == "") state Normal;
			if (llListFindList(Library, [ CurrentObject ]) == -1) {
				llDialog(OwnerId, "\nObject '" + CurrentObject + "' is not in library", [ "OK" ], -9999);
				state Normal;
			}

			MenuListener = llListen(MenuChannel, "", OwnerId, "");
			llDialog(OwnerId, "\nSelect new category\nfor '" + CurrentObject + "':", OrderButtons(Categories), MenuChannel);
			llSetTimerEvent(60.0);
		}
		else if (Channel == MenuChannel) {
			string NewCategory = Message;
			llSetTimerEvent(0.0);
			if (llListFindList(Categories, [ NewCategory ]) == -1) llShout(0, "Invalid category!");	// this shouldn't happen
			SendCommand(PickerId, PI_UPDATE, "category", [ CurrentObject, NewCategory ]);
			if (RestartNeeded) state Identify;
			llDialog(OwnerId, "\nCategory for object '" + CurrentObject + "'\nchanged to: " + NewCategory
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
		llDialog(OwnerId, "\nCategory change timed out", [ "OK" ], -9999);
		state Normal;
	}
	touch_start(integer Count) {
		state ReCategory;
	}
}
state ReCategory { state_entry() { state Category; }}
state Delete {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Deleting an object", COLOR_YELLOW);
		llSetTimerEvent(0.0);
		CurrentObject = "";
		TextboxChannel = -10000 - (integer)llFrand(100000.0);
		TextboxListener =  llListen(TextboxChannel, "", OwnerId, "");
		llTextBox(OwnerId, "\nEnter name of object to \ndelete from library\n(without suffix),\nor blank to cancel", TextboxChannel);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == TextboxChannel) {
			SetText("Deleting ...", COLOR_YELLOW);
			CurrentObject = Message;
			if (Message == "") state Normal;
			if (llListFindList(Library, [ CurrentObject ]) == -1) {
				llDialog(OwnerId, "\nObject '" + CurrentObject + "' is not in library", [ "OK" ], -9999);
				state Normal;
			}
			SendCommand(RezzorId, RZ_UPDATE, "delete", [ CurrentObject ]);
			SendCommand(ControllerId, IC_UPDATE, "delete", [ CurrentObject ]);
			SendCommand(PickerId, PI_UPDATE, "delete", [ CurrentObject ]);
			if (RestartNeeded) state Identify;
			llDialog(OwnerId, "\nObject deleted from library", [ "OK" ], -9999);
			state Reload;
		}
	}
	touch_start(integer Count) {
		state ReDelete;
	}
}
state ReDelete{ state_entry() { state Delete; }}
state Import {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Adding a new object", COLOR_YELLOW);
		PlatformUuid = NULL_KEY;
		// Set initial defaults
		ConfigCentered = FALSE;
		ConfigVertical = FALSE;
		ConfigResizable = FALSE;
		Dialog("Would you like assistance building your World Object?\n\nAnswer 'No' if you already have the complete, packaged world object, icon and texture", [ "Yes", "No", "Cancel" ]);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel) {
			llSetTimerEvent(0.0);
			if (Message == "Cancel") {
				DialogOK("Canceled");
				state Normal;
			}
			else if (Message == "No") {
				SkipWizard = TRUE;
				state ImportGetName;
			}
			else if (Message == "Yes") {
				SkipWizard = FALSE;
				state ImportGetName;
			}
		}
	}
	touch_start(integer Count) {
		DialogTouch();
	}
}
state ImportGetName {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		llListen(MenuChannel, "", OwnerId, "");
		llTextBox(OwnerId, "\n\nEnter name for new object, or leave blank to cancel.\n\nNote that case is significant.", MenuChannel);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel) {
			if (Message == "") state Import;	// cancel if name empty
			if (llListFindList(Library, [ Message ]) != -1) {	// it exists already
				llListen(-11911, "", OwnerId, "");	// we use a separate channel purely so they can have an object called "OK"
				llDialog(OwnerId, "Object '" + Message + "' already exists in library", [ "OK" ], -11911);
				return;
			}
			UploadNewObject = Message;
			Phase = 0;
			if (SkipWizard) state ImportDropObjects;
			state ImportGetWorldObject;
		}
		else if  (Channel == -11911) {
			state ReImportGetName;
		}
	}
	touch_start(integer Count) {
		state Import;
	}
}
state ReImportGetName { state_entry() { state ImportGetName; } }
state ImportGetWorldObject {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Creating world object", COLOR_YELLOW);
		if (Phase == 0) {
			Dialog("Click '" + BUTTON_NEXT + "' to rez a platform in front of you. This will be where you will rez your original object.", [ BUTTON_CANCEL, BUTTON_BACK, BUTTON_NEXT ]);
		}
		else if (Phase == 1) {
			Dialog("Rez your original object onto the platform, adjust its position/rotation as necessary and click '" + BUTTON_NEXT + "'.", [ BUTTON_CANCEL, BUTTON_BACK, BUTTON_NEXT ]);
		}
		else if (Phase == 2) {
			Dialog("Drop the script named '" + ImporterScriptName + "' into your object.\n\nIf you don't have a copy of the script, click '" + BUTTON_GET_IMPORTER + "' to get one.",
				[ BUTTON_GET_IMPORTER, BUTTON_CANCEL, BUTTON_BACK ]);
			ImporterListener = llListen(IMPORTER_CHANNEL, "", NULL_KEY, "");
		}
		PhasesInState = 3;

	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel) {
			llSetTimerEvent(0.0);
			if (Message == BUTTON_CANCEL) {
				DialogOK("Import canceled");
				DeletePlatform();	// delete platform if it exists
				if (ImporterListener) {
					llListenRemove(ImporterListener);
				}
				state Normal;
			}
			else if (Message == BUTTON_NEXT) {
				if (Phase == 0) {
					RezPlatform();
					return;
				}
				Phase++;
			}
			else if (Message == BUTTON_BACK) {
				Phase--;
				if (Phase == 0) DeletePlatform();	// delete platform if it exists
				if (Phase < 0) state ImportGetName;
			}
			else if (Message == BUTTON_GET_IMPORTER) {
				llGiveInventory(OwnerId, ImporterScriptName);
				Dialog("Accept inventory offer and click 'OK'", [ "OK" ]);
				return;
			}
			state ReImportGetWorldObject;
		}
		else if (Channel == IMPORTER_CHANNEL) {
			if (llGetOwnerKey(Id) == OwnerId) {		// if it belongs to the same user
				list Parts = llCSV2List(Message);
				if (llList2String(Parts, 0) == "hello") {
					ObjectTotalSize = (vector)llList2String(Parts, 1);
					NewObjectId = Id;
					// tell importer script to link to root object
					MessageObject(NewObjectId, "link," + (string)PlatformUuid);
					// script replies with osMessageObject, so processing continues in dataserver()
				}
			}
		}
	}
	dataserver(key From, string Data) {
		if (From == NewObjectId) {
			if (Data == "linked") {	// importer script telling us that it's linked to root object
				state ImportWorldObjectFinalise;
			}
		}
	}
	object_rez(key Uuid) {
		PlatformRezzed(Uuid);
		Phase++;
		state ReImportGetWorldObject;
	}
	touch_start(integer Count) {
		DialogTouch();
	}
}
state ReImportGetWorldObject { state_entry() { state ImportGetWorldObject; } }
state ImportWorldObjectFinalise {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		MessageObject(NewObjectId, "rename," + UploadNewObject + "W");
	}
	dataserver(key From, string Data) {
		if (From == NewObjectId) {
			if (Data == "renamed") {	// response after "rename" command
				MessageObject(NewObjectId, "shrinkroot");		// make root prim small and invisible
			}
			else if (Data == "shrunkroot") {	// response after "shrinkroot" command
				MessageObject(NewObjectId, "remove");		// tell importer script to remove itself
			}
			else if (Data == "removed") {	// response after "remove" command
				llRemoteLoadScriptPin(PlatformUuid, WorldObjectScriptName, OBJECT_PIN, TRUE, 1);
				NewObjectId = PlatformUuid;	// root prim has changed, and it's this that's important now
				state ImportIconStart;
			}
		}
	}
}
state ImportIconStart {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Creating icon", COLOR_YELLOW);
		Phase = 0;
		Dialog("The World Object is complete.\n\n" +
			"How would you like to create an icon for your object?\n\n" +
			"Miniature - create a small version of the original object\n\n" +
			"Flat - add a texture to a flat object\n\n" +
			"Skip - already have a complete, packaged icon"
				, [
					BUTTON_CANCEL, BUTTON_BACK, " ",
			"Miniature", "Flat", "Skip"
				]);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel) {
			if (Message == BUTTON_CANCEL) {
				DialogOK("Import canceled");
				state Normal;
			}
			else if (Message == BUTTON_BACK) {
				state ImportGetWorldObject;
			}
			else if (Message == "Miniature") {
				IconType = ICON_MINIATURE;
				state ImportGetMiniatureIcon;
			}
			else if (Message == "Flat") {
				IconType = ICON_FLAT;
				state ImportGetFlatIcon;
			}
			else if (Message == "Skip") {
				state ImportDropObjects;
			}
		}
	}
	touch_start(integer Count) {
		DialogTouch();
	}
}
state ImportGetMiniatureIcon {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		Dialog("Your world object is ready.\n\nTake a COPY of it and click '" + BUTTON_NEXT + "'", [ BUTTON_CANCEL, BUTTON_BACK, BUTTON_NEXT ]);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel) {
			llSetTimerEvent(0.0);
			if (Message == BUTTON_CANCEL) {
				DialogOK("Import canceled");
				if (ImporterListener) {
					llListenRemove(ImporterListener);
				}
				state Normal;
			}
			else if (Message == BUTTON_NEXT) {
				MessageObject(NewObjectId, (string)GE_DELETE);	// tell world object script to delete itself
				NewIconId = NewObjectId;	// the world object is being converted into an icon
				ImporterListener = llListen(IMPORTER_CHANNEL, "", NewIconId, "");
				llRemoteLoadScriptPin(NewIconId, ImporterScriptName, OBJECT_PIN, TRUE, 1);	// load importer script
			}
			else if (Message == BUTTON_BACK) {
				state ImportIconStart;
			}
		}
		else if (Channel == IMPORTER_CHANNEL) {	// must be from our new icon because of listen filter
			list Parts = llCSV2List(Message);
			if (llList2String(Parts, 0) == "hello") {
				// script replies with osMessageObject, so processing continues in dataserver()
				MessageObject(NewIconId, "rename," + UploadNewObject + "I");
			}
		}
	}
	dataserver(key From, string Data) {
		if (From == NewIconId) {
			if (Data == "renamed") {	// response after "rename" command
				MessageObject(NewIconId, "resize," + (string)ScalingFactor);
			}
			else if (Data == "resized") {	// response after "resize" command
				MessageObject(NewIconId, "remove");		// tell importer script to remove itself
			}
			else if (Data == "removed") {	// response after "remove" command
				llRemoteLoadScriptPin(PlatformUuid, IconScriptName, OBJECT_PIN, TRUE, 1);
				state ImportIconFinished;
			}
		}
	}
	touch_start(integer Count) {
		DialogTouch();
	}
}
state ImportGetFlatIcon {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		PhasesInState = 3;
		if (Phase == 0) {
			Dialog("Your world object is ready.\n\nTAKE it into inventory and click '" + BUTTON_NEXT + "'", [ BUTTON_CANCEL, BUTTON_BACK, BUTTON_NEXT ]);
		}
		else if (Phase == 1) {
			Dialog("Click '" + BUTTON_NEXT + "' to rez a flat icon prim in front of you.", [ BUTTON_CANCEL, BUTTON_BACK, BUTTON_NEXT ]);
		}
		else if (Phase == 2) {
			Dialog("Add your flat icon texture to the icon\nand click '" + BUTTON_NEXT + "'.", [ BUTTON_CANCEL, BUTTON_BACK, BUTTON_NEXT ]);
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel) {
			llSetTimerEvent(0.0);
			if (Message == BUTTON_CANCEL) {
				DialogOK("Import canceled");
				DeletePlatform();	// delete platform if it exists
				state Normal;
			}
			else if (Message == BUTTON_NEXT) {
				if (Phase == 1) {
					RezPlatform();
					return;
				}
				Phase++;
				if (Phase == PhasesInState) state ImportIconFinished;
			}
			else if (Message == BUTTON_BACK) {
				Phase--;
				if (Phase == 1) DeletePlatform();	// delete platform if it exists
				if (Phase < 0) state ImportIconStart;
			}
			state ReImportGetFlatIcon;
		}
		else if (Channel == IMPORTER_CHANNEL) {	// must be from our new icon because of listen filter
			list Parts = llCSV2List(Message);
			if (llList2String(Parts, 0) == "ready") {
				vector IconSize = ObjectTotalSize / ScalingFactor;
				IconSize.z = 0.001;
				MessageObject(NewIconId, "resize," + (string)IconSize);
				// processing continues in dataserver
			}
		}
	}
	dataserver(key From, string Data) {
		if (From == NewIconId) {
			if (Data == "resized") {	// importer script telling us that it's linked to root object
				MessageObject(NewIconId, "rename," + UploadNewObject + "I");
			}
			else if (Data == "renamed") {
				MessageObject(NewIconId, "remove");		// tell importer script to remove itself
			}
			else if (Data == "removed") {	// response after "remove" command
				llRemoteLoadScriptPin(NewIconId, IconScriptName, OBJECT_PIN, TRUE, 1);
				Phase++;
				state ReImportGetFlatIcon;
			}
		}
	}
	object_rez(key Uuid) {
		PlatformRezzed(Uuid);
		NewIconId = Uuid;
		llSetTimerEvent(1.0);
		// give time for listen event from "hello" from old version of importer to be flushed
	}
	timer() {
		llSetTimerEvent(0.0);
		ImporterListener = llListen(IMPORTER_CHANNEL, "", NewIconId, "");
		llRemoteLoadScriptPin(NewIconId, ImporterScriptName, OBJECT_PIN, TRUE, 1);	// load importer script
	}
	touch_start(integer Count) {
		DialogTouch();
	}
}
state ReImportGetFlatIcon { state_entry() { state ImportGetFlatIcon; } }
state ImportIconFinished {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		Dialog("The icon is complete. Take it into your inventory and click '" + BUTTON_NEXT + "'.", [ BUTTON_CANCEL, BUTTON_BACK, BUTTON_NEXT ]);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel) {
			if (Message == BUTTON_CANCEL) {
				DialogOK("Import canceled");
				state Normal;
			}
			else if (Message == BUTTON_NEXT) {
				state ImportConfig;
			}
			else if (Message == BUTTON_BACK) {
				state ImportIconStart;
			}
		}
	}
	touch_start(integer Count) {
		DialogTouch();
	}
}
state ImportConfig {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Getting configuration details", COLOR_YELLOW);
		string Text = "Select any of these options, or '" + BUTTON_NEXT + "' to continue.\n\n" +
			ConfigText(BUTTON_CENTERED, ConfigCentered, "created in region center") + "\n" +
			ConfigText(BUTTON_VERTICAL, ConfigVertical, "created vertical regardless of surface") +  "\n" +
			ConfigText(BUTTON_RESIZEABLE, ConfigResizable, "can be resized")
				;
		Dialog(Text, [
			BUTTON_CANCEL, BUTTON_BACK, BUTTON_NEXT,
			BUTTON_CENTERED, BUTTON_VERTICAL, BUTTON_RESIZEABLE
				]);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel) {
			if (Message == BUTTON_CANCEL) {
				DialogOK("Import canceled");
				state Normal;
			}
			else if (Message == BUTTON_NEXT) {
				state ImportConfigEnd;
			}
			else if (Message == BUTTON_BACK) {
				state ImportIconStart;
			}
			else if (Message == BUTTON_CENTERED) {
				ConfigCentered = !ConfigCentered;
			}
			else if (Message == BUTTON_VERTICAL) {
				ConfigVertical = !ConfigVertical;
			}
			else if (Message == BUTTON_RESIZEABLE) {
				ConfigResizable = !ConfigResizable;
			}
			state ReImportConfig;
		}
	}
	touch_start(integer Count) {
		DialogTouch();
	}
}
state ImportConfigEnd {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		list Contents = [
			"//Configuration for object '" + UploadNewObject + "'",
			"// Created: " + llGetSubString(llGetTimestamp(), 0, 9) + " by " + llKey2Name(OwnerId) ];
		Contents += "Center = " + Bool2Str(ConfigCentered);
		Contents += "Vertical = " + Bool2Str(ConfigVertical);
		if (ConfigResizable) Contents += "Resize = 0.2";
		Contents += "AdjustHeight = FALSE";
		Contents += "DummyMove = FALSE";
		osMakeNotecard(UploadNewObject + "C", Contents);
		state ImportDropObjects;
	}
}
state ReImportConfig { state_entry() { state ImportConfig; } }
state ImportDropObjects {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Drop files here", COLOR_YELLOW);
		// Are there any invalid files?
		string Errors = CheckPerms();
		if (Errors != "") {
			SetText("Permissions errors", COLOR_RED);
			ShowMessage("Permissions error(s) in files:\n" + Errors);
			return;
		}		integer GotW = (llGetInventoryType(UploadNewObject + "W") == INVENTORY_OBJECT);
		integer GotI = (llGetInventoryType(UploadNewObject + "I") == INVENTORY_OBJECT);
		integer GotT = (llGetInventoryType(UploadNewObject + "T") == INVENTORY_TEXTURE);
		integer GotC = (llGetInventoryType(UploadNewObject + "C") == INVENTORY_NOTECARD);
		if (GotW && GotI && GotT && GotC) state ImportCategory;
		string Text = "Now drop (Ctrl+drag) the following files into the HUD:\n";
		if (!GotW) Text += "\n" + UploadNewObject + "W - World Object";
		if (!GotI) Text += "\n" + UploadNewObject + "I - Icon";
		if (!GotT) Text += "\n" + UploadNewObject + "T - Preview/thumbnail texture";
		if (!GotC) Text += "\n" + UploadNewObject + "C - Configuration notecard";
		Dialog(Text, [ BUTTON_CANCEL, BUTTON_BACK ]);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel) {
			if (Message == BUTTON_CANCEL) {
				DialogOK("Import canceled");
				state Normal;
			}
			else if (Message == BUTTON_BACK) {
				state ImportConfig;
			}
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) state ReImportDropObjects;
	}
	touch_start(integer Count) {
		DialogTouch();
	}
}
state ReImportDropObjects { state_entry() { state ImportDropObjects; } }
state ImportCategory {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Getting category ...", COLOR_YELLOW);
		Dialog("Select category for new object:", OrderButtons(Categories));
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel) {
			llSetTimerEvent(0.0);
			UploadCategory = Message;

			if (llListFindList(Categories, [ UploadCategory ]) == -1) Dialog("Invalid category!", [ "OK" ]);	// this shouldn't happen
			state ImportConfirm;
		}
	}
}
state ImportConfirm {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Confirming upload ...", COLOR_YELLOW);
		// get data ready for upload
		UploadWorldObjects = [ UploadNewObject + "W" ];
		UploadIcons = [ UploadNewObject + "I" ];
		UploadConfigs = [ UploadNewObject + "C" ];
		UploadTextures = [ UploadNewObject + "T" ];
		Dialog("Press '" + BUTTON_NEXT + "' to import your files", [ BUTTON_CANCEL, BUTTON_BACK, BUTTON_NEXT ]);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel) {
			if (Message == BUTTON_CANCEL) {
				DialogOK("Import canceled");
				state Normal;
			}
			else if (Message == BUTTON_NEXT) {
				state UploadCopy;
			}
			else if (Message == BUTTON_BACK) {
				state ImportCategory;
			}
		}
	}
}
state Update {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		Dialog("Drop files into HUD (Ctrl+drag) to upload them to the RezMela system.\n\nOnly use this for updates to files that already exist; for new files use '" + BUTTON_IMPORT + "'.", [ BUTTON_FINISHED ]);
		SetText("Drop files here", COLOR_YELLOW);
		llSetTimerEvent(0.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel) {
			if (Message == BUTTON_FINISHED) {
				state Normal;
			}
			else if (Message == BUTTON_CLEAR) {
				// this is a bit of a crude method, but it will do for now
				ClearContents();
				state Normal;
			}
			else if (Message == BUTTON_RETRY ) {
				llSetTimerEvent(0.5);	// trigger timer to retry
			}
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			SetText("Processing files ...", COLOR_YELLOW);
			llSetTimerEvent(2.0);	// we use a timer in case several files arrive triggering multiple changed() events
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		// Files have stopped arriving, so process them
		list Errors = [];
		UploadWorldObjects = [];
		UploadIcons = [];
		UploadConfigs = [];
		UploadTextures = [];
		list ToClear = ForeignFiles();
		integer Total = llGetListLength(ToClear);
		integer I;
		for (I = 0; I < Total; I++) {
			string Name = llList2String(ToClear, I);
			integer FileType = llGetInventoryType(Name);
			integer NameLen = llStringLength(Name);
			string ObjectName = llGetSubString(Name, 0, NameLen - 2);
			if (llListFindList(WorldObjects, [ ObjectName ]) == -1) {
				Errors += "Object does not exist in RezMela system: '" + ObjectName + "'";
			}
			else {
				string Suffix = llGetSubString(Name, NameLen - 1, NameLen - 1);
				if (Suffix == "W" && FileType == INVENTORY_OBJECT) UploadWorldObjects += Name;
				else if (Suffix == "I" && FileType == INVENTORY_OBJECT) UploadIcons += Name;
				else if (Suffix == "C" && FileType == INVENTORY_NOTECARD) UploadConfigs += Name;
				else if (Suffix == "T" && FileType == INVENTORY_TEXTURE) UploadTextures += Name;
				else Errors += "Invalid file type: " + Name;
			}
		}
		if (Errors != []) {
			integer ErrorCount = llGetListLength(Errors);
			SetText((string)ErrorCount + " error(s)", COLOR_RED);
			Dialog("Errors:\n\n" + llDumpList2String(Errors, "\n"), [ BUTTON_CLEAR, BUTTON_RETRY ]);
			return;
		}
		state UploadCopy;
	}
	touch_start(integer Count) {
		DialogTouch();
	}
}
state UploadCopy {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Uploading files...", COLOR_YELLOW);
		// We don't need more validation here because the checks earlier should be sufficient. This should be non-interactive.
		llSetTimerEvent(0.0);
		UploadWorldObjectsCount = llGetListLength(UploadWorldObjects);
		UploadIconsCount = llGetListLength(UploadIcons);
		UploadConfigsCount = llGetListLength(UploadConfigs);
		UploadTexturesCount = llGetListLength(UploadTextures);
		AllUploadFiles = UploadWorldObjects + UploadIcons + UploadConfigs + UploadTextures;
		AllUploadsCount = llGetListLength(AllUploadFiles);
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
		llDialog(OwnerId, "\nUpload complete", [ "OK" ], MenuChannel);
		SetText("Upload complete", COLOR_GREEN);
		state Normal;
	}
}
state Hang {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		llOwnerSay("Script suspended");
	}
	touch_start(integer Count) {
		llResetScript();
	}
}
// RezMela updater HUD v0.3