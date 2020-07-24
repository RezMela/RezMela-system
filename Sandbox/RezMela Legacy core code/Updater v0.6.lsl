// RezMela updater v0.6

// TODO:
// - check no-mod perms for scripts
// - check that all necessary scripts and objects exist (same function?)
// - reset on change of region

// v0.6 - various issues arising from beta
// v0.4 - get it working as a non-attached object
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

string UNICODE_CHECK = "✔";
string UNICODE_UNCHECK = "✘";

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

vector PLATFORM_REZ_OFFSET = <4.0, 0.0, 1.0>;
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
integer ConfigPhantom;
integer ConfigFloating;
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
integer DR_TEXTURES 		= 8;
integer DR_CATEGORIES		= 16;

integer IC_DELETE = 1007;

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

string CategoryToRename;

key NewObjectId;
key NewIconId;

integer RestartNeeded;
integer InventoryChange;

vector COLOR_GREEN = <0.5, 1.0, 0.5>;
vector COLOR_YELLOW = <1.0, 1.0, 0.2>;
vector COLOR_RED = <1.0, 0.2, 0.2>;

string LIBRARY_LIST_NOTECARD = "RezMela library contents";

list ValidUsers;
key OwnerId;
key UserId;
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
string BUTTON_UPDATE = "Upload";
string BUTTON_DOWNLOAD = "Download";
string BUTTON_NEXT = "Next >";
string BUTTON_BACK = "< Back";
string BUTTON_CANCEL = "Cancel";
string BUTTON_GET_IMPORTER = "Get script";
string BUTTON_CENTERED = "Centered";
string BUTTON_VERTICAL = "Vertical";
string BUTTON_RESIZEABLE = "Resizable";
string BUTTON_FLOATING = "Floating";
string BUTTON_PHANTOM = "Phantom";
string BUTTON_CAT_MOVE = "Move object";
string BUTTON_CAT_RENAME = "Rename";

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
		if (ButtonExists(Buttons, BUTTON_DOWNLOAD)) Text += BUTTON_DOWNLOAD + " - get items from library\n";
		if (ButtonExists(Buttons, BUTTON_CATEGORY)) Text += BUTTON_CATEGORY + " - category operations\n";
		if (ButtonExists(Buttons, BUTTON_DELETE)) Text += BUTTON_DELETE + " - remove object from library\n";
		if (ButtonExists(Buttons, BUTTON_LIST)) Text += BUTTON_LIST + " - get list of objects in library\n";
		if (ButtonExists(Buttons, BUTTON_CLEAR)) Text += BUTTON_CLEAR + " - clear all items from contents\n";
		if (ButtonExists(Buttons, BUTTON_CLOSE)) Text += BUTTON_CLOSE + " - close this menu\n";
	}
	MenuChannel = -10000 - (integer)llFrand(100000.0);
	MenuListener = llListen(MenuChannel, "", UserId, "");
	llDialog(UserId, Text, Buttons, MenuChannel);
}
Dialog(string Text, list Buttons) {
	MenuListener = llListen(MenuChannel, "", UserId, "");
	llDialog(UserId, "\n" + Text, Buttons, MenuChannel);
	CurrentDialogTime = llGetUnixTime();
	CurrentDialogText = Text;
	CurrentDialogButtons = Buttons;
}
// redisplay menu
DialogTouch() {
	llDialog(UserId, "\n" + CurrentDialogText, CurrentDialogButtons, MenuChannel);
}
DialogOK(string Text) {
	llDialog(UserId, "\n" + Text, [ "OK" ], -9999);
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
	// Find position and rotation of user
	list L = llGetObjectDetails(UserId, [ OBJECT_POS, OBJECT_ROT ]);
	vector UserPos = llList2Vector(L, 0);
	rotation UserRot = llList2Rot(L, 1);
	llRezObject(PlatformName, UserPos + (PLATFORM_REZ_OFFSET * UserRot), ZERO_VECTOR, llEuler2Rot(PLATFORM_REZ_ROTATION * DEG_TO_RAD), 1);
}
PlatformRezzed(key Uuid) {
	PlatformUuid = Uuid;
	llRemoteLoadScriptPin(PlatformUuid, ImporterScriptName, OBJECT_PIN, TRUE, 1);
	PlatformHasUpdatedScript = TRUE;
}
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
	llGiveInventoryList(UserId, "RezMela items (" + CurrentObject + ")", ForeignFiles());
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
// ----------- Configuration functions
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Can't find notecard '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	// Set config defaults
	ValidUsers = [];
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
					if (Name == "user") ValidUsers += Value;
					else llOwnerSay("Invalid keyword in config card: " + OName);
				}
				else {
					llOwnerSay("Invalid line in config card: " + Line);
				}
			}
		}
	}
	return TRUE;
}
// Set text on child prim
SetText(string Text, vector Color) {
	llSetLinkPrimitiveParamsFast(2, [ PRIM_TEXT, Text, Color, 1.0 ]);
}
ShowMessage(string Text) {
	llDialog(UserId, "\n" + Text, [ "OK" ], -1010101);
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
		llOwnerSay("Missing object!");
		RestartNeeded = TRUE;
	}
}
// Returns true if avatar is logged in and in the same region
integer AvatarIsHere(key Uuid) {
	return (llGetAgentSize(Uuid) != ZERO_VECTOR);
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
		MessageObject(PlatformUuid, "delete");			// for if it's got the importer script
		MessageObject(PlatformUuid, (string)IC_DELETE);	// for if it's got the icon scipt
		PlatformUuid = NULL_KEY;
	}
}
// Returns dialog text for given option
string ConfigText(string ButtonName, integer Value, string Explanation) {
	string sValue;
	if (Value) sValue = UNICODE_CHECK; else sValue = UNICODE_UNCHECK;
	return sValue + " " + ButtonName + ": " + Explanation;
}
// Check if user is permitted
integer UserValid(key Uuid) {
	if (Uuid == OwnerId) return TRUE;	// it's the owner
	if (llListFindList(ValidUsers, [ (string)Uuid ]) > -1) return TRUE;		// match on UUID
	else if (llListFindList(ValidUsers, [ llKey2Name(Uuid) ]) > -1) return TRUE;		// match on name
	return FALSE;	// matched on nothing
}
// Reset object textures
SetTextures() {
	llSetLinkPrimitiveParamsFast(LINK_THIS, [
		PRIM_TEXTURE, 0, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0,
		PRIM_TEXTURE, 1, MAIN_TEXTURE, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0,
		PRIM_TEXTURE, 2, MAIN_TEXTURE, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0,
		PRIM_TEXTURE, 3, MAIN_TEXTURE, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0,
		PRIM_TEXTURE, 4, MAIN_TEXTURE, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0,
		PRIM_TEXTURE, 5, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
			]);
}
// Returns true if category name is valid for a NEW category; gives error in chat if not
integer ValidCategoryName(string NewCategoryName) {
	if (llListFindList(Categories, [ NewCategoryName ]) >  -1) {
		llOwnerSay("Category already exists with that name");
		return FALSE;
	}
	string BadChars = "[]\n";
	integer L = llStringLength(BadChars);
	integer I;
	for (I = 0; I < L; I++) {
		string BadChar = llGetSubString(BadChars, I, I);
		if (llSubStringIndex(NewCategoryName, BadChar) > -1) {
			llOwnerSay("Invalid character in category name: '" + BadChar + "'");
			return FALSE;
		}
	}
	return TRUE;
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
		UserId = OwnerId;
		ScriptName = llGetScriptName();
		if (!FindInventoryNames()) {
			llOwnerSay("Invalid inventory contents");
			state Hang;
		}
		SetTextures();
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
					llOwnerSay("Rezzor confusion - click updater to reset");
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
					llOwnerSay("Controller confusion - click updater to reset");
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
					llOwnerSay("Picker confusion - click updater to reset");
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
				llOwnerSay("Invalid icon/card update type!");
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
				llOwnerSay("Invalid texture/category update type!");
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
		ShowMessage("ERROR(S) IN REZMELA SYSTEM:\n" + Errors + "\nPlease resolve these before updating.\nClick me to check again");
	}
	touch_start(integer Count) {
		state GetData;
	}
}
////////////////////////////////-------------------------------------------------------- Normal state--------------------------------------------------------------------////////////////////////////////////////
state Normal {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		if (!ReadConfig()) state Hang;
		SetText("Ready", COLOR_GREEN);
		llSetTimerEvent(0.0);
		InventoryChange = FALSE;
		llSetTimerEvent(2.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == UserId) {
			llSetTimerEvent(0.0);		// in case of state change
			if (Message == BUTTON_CLOSE) {
				UserId = NULL_KEY;
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
		OwnerId = llGetOwner();
		key DetectedUser = llDetectedKey(0);
		if (!UserValid(DetectedUser)) {
			llDialog(DetectedUser, "\nSorry, you are not authorised to use this object", [ "OK" ], -918219021);
			return;
		}
		if (UserId != NULL_KEY && DetectedUser != UserId) {		// someone else is using it
			string UserName = llKey2Name(UserId);
			if (UserName == "") UserName = "[unknown user]";
			llDialog(DetectedUser, "\n" + UserName + " is currently using this.", [ "OK" ], -9993243129);
			return;
		}
		UserId = DetectedUser;
		ShowMenu();
	}
	timer() {
		llSetTimerEvent(0.0);
		if (UserId != NULL_KEY) {								// if in use
			if (!AvatarIsHere(UserId)) UserId = NULL_KEY;		// check if user not here and if not, set as not in use
		}
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
			llOwnerSay("Texture change detected - reverting ...");
			llSleep(2.0);
			SetTextures();
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
		llGiveInventory(UserId, LIBRARY_LIST_NOTECARD);
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
		TextboxListener =  llListen(TextboxChannel, "", UserId, "");
		llTextBox(UserId, "\nEnter name of object to download\n(without suffix), or blank to cancel", TextboxChannel);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == TextboxChannel) {
			llSetTimerEvent(0.0);
			CurrentObject = Message;
			if (Message == "") state Normal;
			if (llListFindList(Library, [ CurrentObject ]) == -1) {
				llDialog(UserId, "\nObject '" + CurrentObject + "' is not in library", [ "OK" ], -9999);
				state Normal;
			}
			SetText("Downloading items ...", COLOR_YELLOW);
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
		SetText("Category menu", COLOR_YELLOW);
		string Text =
			"CATEGORY OPERATIONS\n\n" +
			"Select from:\n\n" +
			BUTTON_CAT_RENAME + " - rename a category\n" +
			BUTTON_CAT_MOVE + " - move library object to another category"
				;
		Dialog(Text, [ BUTTON_CANCEL, BUTTON_CAT_RENAME, BUTTON_CAT_MOVE ]);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel) {
			if (Message == BUTTON_CANCEL) {
				state Normal;
			}
			else if (Message == BUTTON_CAT_RENAME) {
				state RenameCategory;
			}
			else if (Message == BUTTON_CAT_MOVE) {
				state MoveCategory;
			}
		}
	}
	touch_start(integer Count) {
		DialogTouch();
	}
}
state RenameCategory {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		SetText("Renaming category", COLOR_YELLOW);
		Dialog("Select category to be renamed", OrderButtons(Categories));
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel) {
			CategoryToRename = Message;
			if (llListFindList(Categories, [ CategoryToRename ]) == -1) {
				Dialog("Invalid category!", [ "OK" ]);	// this shouldn't happen
				state Category;
			}
			TextboxChannel = -10000 - (integer)llFrand(100000.0);
			TextboxListener =  llListen(TextboxChannel, "", UserId, "");
			llTextBox(UserId, "\nRENAME CATEGORY\n\nEnter new name for category '" + CategoryToRename + "' or blank to cancel", TextboxChannel);
		}
		else if (Channel == TextboxChannel) {
			if (Message == "") state Category;
			string NewCategoryName = Message;
			if (!ValidCategoryName(NewCategoryName)) state Category;
			SendCommand(PickerId, PI_UPDATE, "categoryrename", [ CategoryToRename, NewCategoryName ]);
			llSetTimerEvent(1.0);	// trigger reloading, giving time for object picker script to do the same
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		state Reload;
	}
	touch_start(integer Count) {
		DialogTouch();
	}
}
state MoveCategory {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Moving object category", COLOR_YELLOW);
		llSetTimerEvent(0.0);
		CurrentObject = "";
		TextboxChannel = -10000 - (integer)llFrand(100000.0);
		TextboxListener =  llListen(TextboxChannel, "", UserId, "");
		llTextBox(UserId, "\nCHANGE CATEGORY\n\nEnter name of the object whose category you wish to change (without suffix), or blank to cancel", TextboxChannel);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == TextboxChannel) {
			llSetTimerEvent(0.0);
			CurrentObject = llStringTrim(Message, STRING_TRIM);
			if (CurrentObject == "") state Normal;
			if (llListFindList(Library, [ CurrentObject ]) == -1) {
				llDialog(UserId, "\nObject '" + CurrentObject + "' is not in library", [ "OK" ], -9999);
				state Category;
			}
			MenuListener = llListen(MenuChannel, "", UserId, "");
			llDialog(UserId, "\nSelect new category\nfor '" + CurrentObject + "':", OrderButtons(Categories), MenuChannel);
		}
		else if (Channel == MenuChannel) {
			string NewCategory = Message;
			llSetTimerEvent(0.0);
			if (llListFindList(Categories, [ NewCategory ]) == -1) llShout(0, "Invalid category!");	// this shouldn't happen
			SendCommand(PickerId, PI_UPDATE, "categoryset", [ CurrentObject, NewCategory ]);
			if (RestartNeeded) state Identify;
			llDialog(UserId, "\nCategory for object '" + CurrentObject + "'\nchanged to: " + NewCategory
				, [ "OK" ], -9999);
			llSetTimerEvent(1.0);	// trigger reloading, giving time for object picker script to do the same
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		state Reload;
	}
	touch_start(integer Count) {
		state Category;
	}
}
state Delete {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Deleting an object", COLOR_YELLOW);
		llSetTimerEvent(0.0);
		CurrentObject = "";
		TextboxChannel = -10000 - (integer)llFrand(100000.0);
		TextboxListener =  llListen(TextboxChannel, "", UserId, "");
		llTextBox(UserId, "\nEnter name of object to \ndelete from library\n(without suffix),\nor blank to cancel", TextboxChannel);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == TextboxChannel) {
			SetText("Deleting ...", COLOR_YELLOW);
			CurrentObject = Message;
			if (Message == "") state Normal;
			if (llListFindList(Library, [ CurrentObject ]) == -1) {
				llDialog(UserId, "\nObject '" + CurrentObject + "' is not in library", [ "OK" ], -9999);
				state Normal;
			}
			SendCommand(RezzorId, RZ_UPDATE, "delete", [ CurrentObject ]);
			SendCommand(ControllerId, IC_UPDATE, "delete", [ CurrentObject ]);
			SendCommand(PickerId, PI_UPDATE, "delete", [ CurrentObject ]);
			if (RestartNeeded) state Identify;
			llDialog(UserId, "\nObject deleted from library", [ "OK" ], -9999);
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
		ConfigPhantom = FALSE;
		ConfigFloating = FALSE;
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
		llListen(MenuChannel, "", UserId, "");
		llTextBox(UserId, "\n\nEnter name for new object, or leave blank to cancel.", MenuChannel);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel) {
			if (Message == "") state Import;	// cancel if name empty
			if (llListFindList(Library, [ Message ]) != -1) {	// it exists already
				llListen(-11911, "", UserId, "");	// we use a separate channel purely so they can have an object called "OK"
				llDialog(UserId, "Object '" + Message + "' already exists in library", [ "OK" ], -11911);
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
			Dialog("Rez your original object onto the platform, adjust its position/rotation as necessary and click '" + BUTTON_NEXT + "'." +
				"\n\nYou can move and resize the platform itself to make this easier."
					, [ BUTTON_CANCEL, BUTTON_BACK, BUTTON_NEXT ]);
		}
		else if (Phase == 2) {
			Dialog("Drop the script named '" + ImporterScriptName + "' into the contents of your object.\n\nIf you don't have a copy of the script, click '" + BUTTON_GET_IMPORTER + "' to get one.",
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
				llGiveInventory(UserId, ImporterScriptName);
				Dialog("Accept inventory offer and click 'OK'", [ "OK" ]);
				return;
			}
			state ReImportGetWorldObject;
		}
		else if (Channel == IMPORTER_CHANNEL) {
			if (llGetOwnerKey(Id) == UserId) {		// if it belongs to the same user
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
				state GetTexture;
			}
		}
	}
}
state GetTexture {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Creating texture", COLOR_YELLOW);
		Phase = 0;
		Dialog("The World Object is complete.\n\n" +
			"You will need a picture of your object to use as a thumbnail so you can select it from a list.\n\n" +
			"The picture should be square (512x512 is good) and named '" + UploadNewObject + "T'.\n\n"  +
			"Click '" + BUTTON_NEXT + "' when you have this in your inventory."
				, [
					BUTTON_CANCEL, BUTTON_BACK, BUTTON_NEXT
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
			else if (Message == BUTTON_NEXT) {
				state ImportIconStart;
			}
		}
	}
	touch_start(integer Count) {
		DialogTouch();
	}
}
state ImportIconStart {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Creating icon", COLOR_YELLOW);
		Phase = 0;
		Dialog(
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
				state GetTexture;
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
				state Normal;
			}
			else if (Message == BUTTON_NEXT) {
				// Test to check that icon still exists
				if (!ObjectExists(NewObjectId)) {
					llDialog(UserId, "\n*** Object has disappeared! ***\n\nCancelling operation because the world object is no longer in the region.", [ "OK" ], -999999);
					state Normal;
				}
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
				MessageObject(NewIconId, "scrub");
			}
			else if (Data == "scrubbed") {	// response after "scrub" command
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
		string Text = "Toggle any of these options:\n\n" +
			ConfigText(BUTTON_CENTERED, ConfigCentered, "created in region center") + "\n" +
			ConfigText(BUTTON_VERTICAL, ConfigVertical, "created vertical regardless of surface") +  "\n" +
			ConfigText(BUTTON_PHANTOM, ConfigPhantom, "phantom (no collision)") +  "\n" +
			ConfigText(BUTTON_FLOATING, ConfigFloating, "floats on water") +  "\n" +
			ConfigText(BUTTON_RESIZEABLE, ConfigResizable, "can be resized") + "\n" +
			"\nClick '" + BUTTON_NEXT + "' to continue.\n"
				;
		Dialog(Text, [
			BUTTON_CANCEL, BUTTON_BACK, BUTTON_NEXT,
			BUTTON_FLOATING, BUTTON_RESIZEABLE, " ",
			BUTTON_CENTERED, BUTTON_VERTICAL, BUTTON_PHANTOM
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
			else if (Message == BUTTON_PHANTOM) {
				ConfigPhantom = !ConfigPhantom;
			}
			else if (Message == BUTTON_FLOATING) {
				ConfigFloating = !ConfigFloating;
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
			"// Created: " + llGetSubString(llGetTimestamp(), 0, 9) + " by " + llKey2Name(UserId) ];
		Contents += "Center = " + Bool2Str(ConfigCentered);
		Contents += "Vertical = " + Bool2Str(ConfigVertical);
		if (ConfigResizable) Contents += "Resize = 0.2";
		Contents += "AdjustHeight = FALSE";
		Contents += "DummyMove = FALSE";
		Contents += "Phantom = " + Bool2Str(ConfigPhantom);
		Contents += "Floating = " + Bool2Str(ConfigFloating);
		osMakeNotecard(UploadNewObject + "C", Contents);
		state ImportDropObjects;
	}
}
state ReImportConfig { state_entry() { state ImportConfig; } }
state ImportDropObjects {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Drop items here", COLOR_YELLOW);
		// Are there any invalid files?
		string Errors = CheckPerms();
		if (Errors != "") {
			SetText("Permissions errors", COLOR_RED);
			ShowMessage("Permissions error(s) in items:\n" + Errors);
			return;
		}		integer GotW = (llGetInventoryType(UploadNewObject + "W") == INVENTORY_OBJECT);
		integer GotI = (llGetInventoryType(UploadNewObject + "I") == INVENTORY_OBJECT);
		integer GotT = (llGetInventoryType(UploadNewObject + "T") == INVENTORY_TEXTURE);
		integer GotC = (llGetInventoryType(UploadNewObject + "C") == INVENTORY_NOTECARD);
		if (GotW && GotI && GotT && GotC) state ImportCategory;
		string Text = "Now drop (Ctrl+drag) the following items into me:\n";
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
		Dialog("Press '" + BUTTON_NEXT + "' to import your items", [ BUTTON_CANCEL, BUTTON_BACK, BUTTON_NEXT ]);
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
		Dialog("Drop items into me (Ctrl+drag) to upload them to the RezMela system.\n\nOnly use this for updates to items that already exist; for new items use '" + BUTTON_IMPORT + "'.", [ BUTTON_CANCEL ]);
		SetText("Drop items here", COLOR_YELLOW);
		llSetTimerEvent(0.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel) {
			if (Message == BUTTON_CANCEL) {
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
			SetText("Processing items ...", COLOR_YELLOW);
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
				else Errors += "Invalid item type: " + Name;
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
		SetText("Uploading items...", COLOR_YELLOW);
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
		llDialog(UserId, "\nUpload complete", [ "OK" ], MenuChannel);
		SetText("Upload complete", COLOR_GREEN);
		state Reload;
	}
}
state Hang {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Errors", COLOR_RED);
		llOwnerSay("Script suspended");
	}
	touch_start(integer Count) {
		llResetScript();
	}
}
// RezMela updater v0.6