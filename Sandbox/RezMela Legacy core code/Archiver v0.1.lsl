// RezMela archiver v0.1

string OBJECTS_LIST = "!Objects";

integer LINK_SAVEFILES = 2;	// Link number of save files prim

key RezzorId;
key ControllerId;
key PickerId;
key NotecardManagerId;

key OwnerId;
string ScriptName;

string UNICODE_CHECK = "✔";
string UNICODE_UNCHECK = "✘";

integer OBJECT_PIN = 50200;

integer TIMEOUT_SECONDS = 600;	// 10 mins

integer REZZOR_CHANNEL = -355210124;
integer CONTROLLER_CHANNEL = -94040100;
integer PICKER_CHANNEL = -209441200;
integer IMPORTER_CHANNEL = -81140900;

// Integration constants
integer ARCH_BACKUP_START = 790400;
integer ARCH_BACKUP_FILES = 790401;
integer ARCH_BACKUP_END = 790402;
integer ARCH_RESTORE_START = 790410;
integer ARCH_RESTORE_FILES = 790411;
integer ARCH_RESTORE_END = 790412;
integer ARCH_PURGE = 790420;
integer ARCH_INFO = 790430;

integer RZ_UPDATE = 2004;
integer IC_UPDATE = 1021;
integer PI_UPDATE = 8400;

string BUTTON_BACKUP = "Download";
string BUTTON_RESTORE = "Upload";
string BUTTON_PURGE = "Purge";
string BUTTON_CLEAR = "Clear me";
string BUTTON_SAVEFILES = "Save files";
string BUTTON_SAVE_BACKUP = "Backup";
string BUTTON_SAVE_RESTORE = "Restore";
string BUTTON_CLOSE = "Standby";
string BUTTON_OK = "OK";
string BUTTON_BACK = "<< Back";

integer CurrentMenu;
integer MENU_MAIN = 1;
integer MENU_SAVEFILES = 2;

integer RezzorListener;
integer ControllerListener;
integer PickerListener;
integer ImporterListener;

key ComponentId;
integer LastResponseTime;

integer MenuChannel;
integer MenuListener;

integer LibrarySize;
integer InvCount;
integer SaveFilesCountRemote;
integer SaveFilesCountLocal;

integer SaveFilesFunction;
integer SFF_BACKUP = 1;
integer SFF_RESTORE = 2;

list Errors;

integer DataProcessed;	// bitfields
integer DP_NONE				= 0;
integer DP_REZZOR			= 1;
integer DP_CONTROLLER		= 2;
integer DP_PICKER			= 4;

list NotecardToWrite;
list PickerList;	// A copy of the objects list (raw) from the picker during a restore, to merge and send back

vector COLOR_GREEN = <0.5, 1.0, 0.5>;
vector COLOR_YELLOW = <1.0, 1.0, 0.2>;
vector COLOR_RED = <1.0, 0.2, 0.2>;

ShowMenu() {
	string Text = "\nREZMELA ARCHIVER\n\n";
	list Buttons = [];
	if (CurrentMenu == MENU_MAIN) {
		Text += ContentSizes();
		// Button row 2
		if (InvCount) Buttons += BUTTON_CLEAR; else Buttons += " ";
		Buttons += [ BUTTON_SAVEFILES, BUTTON_CLOSE ];

		// Button row 1
		if (LibrarySize) Buttons += BUTTON_BACKUP; else Buttons += " ";
		if (InvCount) Buttons += BUTTON_RESTORE; else Buttons += " ";
		if (LibrarySize) Buttons += BUTTON_PURGE; else Buttons += " ";

		Text += "\n\n";

		if (ButtonExists(Buttons, BUTTON_BACKUP)) Text += BUTTON_BACKUP + " - copy all items from library to archiver\n";
		if (ButtonExists(Buttons, BUTTON_RESTORE)) Text += BUTTON_RESTORE + " - copy all items from archiver to library\n";
		if (ButtonExists(Buttons, BUTTON_PURGE)) Text += BUTTON_PURGE + " - clear library\n";
		if (ButtonExists(Buttons, BUTTON_CLEAR)) Text += BUTTON_CLEAR + " - clear all items from archiver\n";
		if (ButtonExists(Buttons, BUTTON_CLOSE)) Text += BUTTON_CLOSE + " - set archiver to standby\n";
		if (ButtonExists(Buttons, BUTTON_SAVEFILES)) Text += BUTTON_SAVEFILES + " - backup/restore save files\n";
	}
	else if (CurrentMenu == MENU_SAVEFILES) {
		Text += "SAVE FILES MENU";
		Text += "\n\n";
		Text += "Saves in RezMela: " + (string)SaveFilesCountRemote;
		Text += "\nSaves in archiver: " + (string)SaveFilesCountLocal;
		Buttons += BUTTON_BACK;
		if (SaveFilesCountRemote) Buttons += BUTTON_SAVE_BACKUP; else Buttons += " ";
		if (SaveFilesCountLocal) Buttons += BUTTON_SAVE_RESTORE; else Buttons += " ";
	}
	MenuChannel = -10000 - (integer)llFrand(100000.0);
	MenuListener = llListen(MenuChannel, "", OwnerId, "");
	llDialog(OwnerId, Text, Buttons, MenuChannel);
}
// Return string describing sizes of archive/library
string ContentSizes() {
	return ContentSize("Library", LibrarySize) +
		"\n" +
		ContentSize("Archive", llGetInventoryNumber(INVENTORY_TEXTURE));	// the number of textures should indicate number of discrete objects
}
// Formatted size description string
string ContentSize(string Name, integer Size) {
	string Text = "";
	if (Size) {
		Text = Name + " contents: " + (string)Size + " object";
		if (Size > 1) Text += "s";
	}
	else {
		Text = Name + " empty";
	}
	return Text;
}
integer ButtonExists(list Buttons, string Button) {
	return (llListFindList(Buttons, [ Button ]) > -1);
}
// Find number of "objects" in inventory (actually textures, which is an easier indicator)
integer GetInventoryCount() {
	return llGetInventoryNumber(INVENTORY_TEXTURE);
}
// llGiveInventoryList() doesn't work in OpenSim when the target is a prim; this emulates that function
GiveInventoryList(key Uuid, list Objects) {
	integer Len = llGetListLength(Objects);
	integer O;
	for (O = 0; O < Len; O++) {
		string ObjectName = llList2String(Objects, O);
		if (llGetInventoryType(ObjectName) != INVENTORY_NONE)
			llGiveInventory(Uuid, ObjectName);
	}
}
// Remove all foreign files in contents
ClearContents() {
	DeleteFiles(ObjectNames("W"));
	DeleteFiles(ObjectNames("I"));
	DeleteFiles(ObjectNames("C"));
	DeleteFiles(ObjectNames("T"));
	DeleteFiles([ OBJECTS_LIST ]);
}
// Remove specified files from contents
DeleteFiles(list Filenames) {
	if (Filenames == []) return;
	integer Total = llGetListLength(Filenames);
	integer I;
	for (I = 0; I < Total; I++) {
		string Name = llList2String(Filenames, I);
		if (llGetInventoryType(Name) != INVENTORY_NONE) {
			llRemoveInventory(Name);
		}
	}
}
// Returns list of object names	with optional suffix appended to each
list ObjectNames(string Suffix) {
	list Objects = [];
	integer I;
	integer Total = llGetInventoryNumber(INVENTORY_TEXTURE);
	for (I = 0; I < Total; I++) {
		string Name = llGetInventoryName(INVENTORY_TEXTURE, I);
		Name = llGetSubString(Name, 0, -2);
		if (Suffix != "") Name += Suffix;
		Objects += Name;
	}
	return Objects;
}
// Here we're working on object lists as stored in the !Objects notecard.
// The purpose of this is to take a current list and merge it with a new one,
// returning a list which contains all elements of both lists. This is complicated
// by the issue of categories (for example, what if an object is in both lists under
// different categories?).
list MergeObjectLists(list CurrentDataRaw, list NewDataRaw) {
	list CurrentData = CookObjectsList(CurrentDataRaw);
	list NewData = CookObjectsList(NewDataRaw);
	// First we extract a list of the categories in the current data
	list CatList = [];
	integer Len = llGetListLength(CurrentData);
	integer P;
	for (P = 0; P < Len; P += 2) {
		string Cat = llList2String(CurrentData, P);
		Cat = llGetSubString(Cat, 1, -1);	// remove initial "!"
		if (llListFindList(CatList, [ Cat ]) == -1) CatList += Cat;
	}
	// Next we add any categories that are only in the new data
	Len = llGetListLength(NewData);
	for (P = 0; P < Len; P += 2) {
		string Cat = llList2String(NewData, P);
		Cat = llGetSubString(Cat, 1, -1);	// remove initial "!"
		if (llListFindList(CatList, [ Cat ]) == -1) CatList += Cat;
	}
	integer CatCount = llGetListLength(CatList);
	if (CatCount > 12) {
		// Log an error
		Errors += "Categories overflow: " + (string)CatCount + " exceeds limit of 12";
		// But we carry on anyway, nothing to be gained by stopping at this point
	}
	// Process new data, inserting into current data where necessary
	if (CurrentData == [ ]) {
		CurrentData = llList2List(NewData, 0, -1);		// if it's all new data, we can just copy it, no merging needed
	}
	else {
		Len = llGetListLength(NewData);
		integer C;
		for (C = 0; C < CatCount; C++) {
			string Cat = llList2String(CatList, C);
			// For each category, extract the objects within that category
			list AddObjects = [];
			integer InsertPoint = -1;
			for (P = 0; P < Len; P += 2) {
				string NewCat = llList2String(NewData, P + 0);
				NewCat = llGetSubString(NewCat, 1, -1);	// remove initial "!"
				string Object = llList2String(NewData, P + 1);
				if (NewCat == Cat) {
					if (llListFindList(CurrentData, [ "!" + NewCat, Object ]) == -1) {	// if objects isn't in current list
						AddObjects += [ "!" + NewCat, Object ];
						InsertPoint = P;
					}
				}
			}
			if (InsertPoint >= Len) {	// if we need to make room at the end, do so
				NewData += "";
				Len++;
			}
			if (AddObjects != []) {	// if there are objects to add into this category
				CurrentData = llListInsertList(CurrentData, AddObjects, InsertPoint);	// insert new cat/objects into category
			}
		}
	}
	return FormatObjectsList(CurrentData);
}
// Convert a "cooked" objects list into one that's suitable for writing to a notecard.
// Example input:
//	[ "!Vehicles", "car", "!Vehicles", "bus", "!Vehicles", "truck", "!Plants", "tree" ]
// Would give:
// [ "[Vehicles]", "car", "bus", "truck", "[Plants]", "tree" ]
//
// The "cooked" list is easier to manipulate, so we use that internally. The ! in front
// of category names disambiguates object/category name strings. 
list FormatObjectsList(list Data) {
	list Result = [];
	integer CatCount = 0;
	string CurrentCat;
	integer Len = llGetListLength(Data);
	integer P;
	for (P = 0; P < Len; P += 2) {
		string Cat = llList2String(Data, P);
		Cat = llGetSubString(Cat, 1, -1);	// remove initial "!"
		string Object = llList2String(Data, P + 1);
		if (Cat != CurrentCat) {
			Result += [ "", "[" + Cat + "]" ];
			CurrentCat = Cat;
			CatCount++;
		}
		Result += Object;
	}
	// If there are < 12 categories, fill up with default, empty categories
	for (P = CatCount; P < 12; P++) {
		Result += [ "", "[Category " + (string)(P + 1) + "]" ];	// add in an empty category with default name
	}
	Result += "";
	return Result;
}
// Convert notecard format (with category heads in "[]") to strided format (ie [ category, object ])
// Note that this will drop empty categories. This is actually useful, because merging might bring in new categories
// which will need empty "slots".
list CookObjectsList(list RawData) {
	list CookedData = [];
	string CatName = "";
	integer Len = llGetListLength(RawData);
	integer I;
	for (I = 0; I < Len; I++) {
		string Line = llList2String(RawData, I);
		Line = llStringTrim(Line, STRING_TRIM);
		if (Line != "") {
			if (llGetSubString(Line, 0, 0) == "[" && llGetSubString(Line, -1, -1) == "]") {		// if it's a category entry
				CatName = llGetSubString(Line, 1, -2);
			}
			else {
				string ObjectName = Line;
				if (CatName == "") {
					llOwnerSay("ERROR: List item not in category: '" + ObjectName + "'");
				}
				else {
					CookedData += [ "!" + CatName, ObjectName ];
				}
			}
		}
	}
	return CookedData;
}
// Set floating text
SetText(string Text, vector Color) {
	llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEXT, Text, Color, 1.0 ]);
}
// Returns true if we've heard from all the components of the system
integer AllPartsPresent() {
	return (RezzorId != NULL_KEY && ControllerId != NULL_KEY && PickerId != NULL_KEY);
}
// Wrapper for osMessageObject() that checks to see if control board exists
// Uses standard messaging protocol
MessageStandard(key Uuid, integer Command, list Params) {
	MessageObject(Uuid, llDumpList2String([ Command ] + Params, "|"));
}
MessageObject(key Uuid, string Message) {
	if (ObjectExists(Uuid)) {
		osMessageObject(Uuid, Message);
	}
	else {
		llOwnerSay("Missing object");
		SetText("Missing object", COLOR_RED);
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
default {
	state_entry() {
		llSetRemoteScriptAccessPin(OBJECT_PIN);
		OwnerId = llGetOwner();
		ScriptName = llGetScriptName();
		state Standby;
	}
}
// We're normally in an idle state so that we don't have to continually keep up-to-date with the
// contents/status of the other components (rezzor, control board etc).
state Standby {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		LibrarySize = 0;
		SetText("Standby - click for menu", COLOR_GREEN);
	}
	touch_start(integer Count) {
		if (llDetectedKey(0) == OwnerId) {
			state Booting ;
		}
	}
}
state Booting {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Searching for components ...", COLOR_YELLOW);
		SaveFilesCountLocal = -1;	// Until we know better
		RezzorId = ControllerId = PickerId = NULL_KEY;
		RezzorListener = llListen(REZZOR_CHANNEL, "", NULL_KEY, "");
		ControllerListener = llListen(CONTROLLER_CHANNEL, "", NULL_KEY, "");
		PickerListener = llListen(PICKER_CHANNEL, "", NULL_KEY, "");
		llSetTimerEvent(1.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (llGetOwnerKey(Id) != OwnerId) return;	// we ignore objects we don't own
		if (Channel == REZZOR_CHANNEL) {
			if (Id == RezzorId) return;		// ignore if no change
			if (RezzorId != NULL_KEY) llOwnerSay("Change of rezzor component detected");
			RezzorId = Id;
		}
		else if (Channel == CONTROLLER_CHANNEL) {
			if (Id == ControllerId) return;		// ignore if no change
			if (ControllerId != NULL_KEY) llOwnerSay("Change of control board component detected (i)");
			ControllerId = Id;
			list Parts = llParseStringKeepNulls(Message, [ "|" ], []);
			NotecardManagerId = (key)llList2String(Parts, 3);	// Controller sends us this info (among other things we don't need)
		}
		else if (Channel == PICKER_CHANNEL) {
			if (Id == PickerId) return;		// ignore if no change
			if (PickerId != NULL_KEY)  llOwnerSay("Change of control board component detected (ii)");
			PickerId = Id;
			LibrarySize = (integer)Message;
		}
	}
	timer() {
		if (RezzorId != NULL_KEY && ControllerId != NULL_KEY && PickerId != NULL_KEY) {
			llSetTimerEvent(0.0);
			CurrentMenu = MENU_MAIN;
			state Menu;
		}
		string Text = "Waiting for:";
		if (RezzorId == NULL_KEY) Text += "\n  Rezzor";
		if (ControllerId == NULL_KEY) Text += "\n  Control board";
		if (PickerId == NULL_KEY) Text += "\n  Library picker";
		SetText(Text, COLOR_YELLOW);
	}
	touch_start(integer Count) {
		if (llDetectedKey(0) == OwnerId) state Standby;
	}
}
state Menu {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		InvCount = GetInventoryCount();
		SetText("Ready\n\n" + ContentSizes(), COLOR_GREEN);
		ShowMenu();
		LastResponseTime = llGetUnixTime();
		MessageStandard(NotecardManagerId, ARCH_INFO, []);	// Request number of save files in RezMela
		llMessageLinked(LINK_SAVEFILES, ARCH_INFO, "", NULL_KEY);	// Request number of save files in archive
		llSetTimerEvent(5.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		llSetTimerEvent(0.0);
		if (Channel == MenuChannel && Id == OwnerId) {
			if (CurrentMenu == MENU_MAIN) {
				if (Message == BUTTON_CLOSE) {
					state Standby;
				}
				else if (Message == BUTTON_BACKUP) {
					state Backup;
				}
				else if (Message == BUTTON_RESTORE) {
					state Restore;
				}
				else if (Message == BUTTON_PURGE) {
					state Purge;
				}
				else if (Message == BUTTON_CLEAR) {
					SetText("Clearing archive ...", COLOR_YELLOW);
					ClearContents();
					state ReMenu;
				}
				else if (Message == BUTTON_SAVEFILES) {
					CurrentMenu = MENU_SAVEFILES;
					state ReMenu;
				}
			}
			else if (CurrentMenu == MENU_SAVEFILES) {
				if (Message == BUTTON_BACK) {
					CurrentMenu = MENU_MAIN;
					state ReMenu;
				}
				else if (Message == BUTTON_BACKUP) {
					SaveFilesFunction = SFF_BACKUP;
					state SaveFiles;
				}
				else if (Message == BUTTON_RESTORE) {
					SaveFilesFunction = SFF_RESTORE;
					state SaveFiles;
				}
			}
		}
	}
	timer() {
		// check periodically that all components are still in the region
		if (!ObjectExists(RezzorId) ||
			!ObjectExists(ControllerId) ||
			!ObjectExists(PickerId))
			state Booting;
		// Time out if idle
		if (llGetUnixTime() > LastResponseTime + TIMEOUT_SECONDS) state Standby;
	}
	dataserver(key From, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		integer Command = (integer)llList2String(Parts, 0);
		list Params = [];
		if (llGetListLength(Parts) > 1) Params = llList2List(Parts, 1, -1);
		if (From == NotecardManagerId && Command == ARCH_INFO) {
			// Notecard manager is returning the number of save files it has
			SaveFilesCountRemote = (integer)llList2String(Params, 0);
		}
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Sender == LINK_SAVEFILES) {
			if (Number == ARCH_INFO) {
				// The saves files archiver script is returning the number of save files it has
				SaveFilesCountLocal = (integer)Message;
			}
		}
	}
	touch_start(integer Count) {
		if (llDetectedKey(0) == OwnerId) state ReMenu;
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) state Standby;
	}
}
state ReMenu {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		state Menu;

	}
}
state Backup {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		Errors = [];
		DataProcessed = DP_NONE;
		NotecardToWrite = [];
		SetText("Receiving items ...", COLOR_YELLOW);
		MessageStandard(RezzorId, ARCH_BACKUP_START, []);		// requests list of world objects
	}
	dataserver(key From, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		integer Command = (integer)llList2String(Parts, 0);
		list Params = [];
		if (llGetListLength(Parts) > 1) Params = llList2List(Parts, 1, -1);
		if (From == RezzorId && Command == ARCH_BACKUP_FILES) {
			// Rezzor tells us list of files it's going to send, so we clear out our copies
			DeleteFiles(Params);
			ComponentId = RezzorId;
			llSetTimerEvent(2.0);
		}
		else if (From == ControllerId && Command == ARCH_BACKUP_FILES) {
			// Controller tells us list of files it's going to send, so we clear out our copies
			DeleteFiles(Params);
			ComponentId = ControllerId;
			llSetTimerEvent(2.0);
		}
		else if (From == PickerId && Command == ARCH_BACKUP_FILES) {
			// Picker tells us list of files it's going to send, so we clear out our copies
			DeleteFiles(Params);
			ComponentId = PickerId;
			llSetTimerEvent(2.0);
		}
		else if (From == RezzorId && Command == ARCH_BACKUP_END) {
			DataProcessed = DataProcessed | DP_REZZOR;
			MessageStandard(ControllerId, ARCH_BACKUP_START, []);		// request list of icons and config notecards
		}
		else if (From == ControllerId && Command == ARCH_BACKUP_END) {
			DataProcessed = DataProcessed | DP_CONTROLLER;
			MessageStandard(PickerId, ARCH_BACKUP_START,[]);		// request list of textures and categories
		}
		else if (From == PickerId && Command == ARCH_BACKUP_END) {
			DataProcessed = DataProcessed | DP_PICKER;
			// Now take the objects list data (which is appended to this message) and
			// merge it with any that we already have, combining objects into categories.
			string NewListString = llList2String(Params, 0);
			list NewDataRaw = llParseString2List(NewListString, [ "\n" ], [ ]);
			list CurrentDataRaw = [];
			if (llGetInventoryType(OBJECTS_LIST) == INVENTORY_NOTECARD) {
				CurrentDataRaw = llParseString2List(osGetNotecard(OBJECTS_LIST), [ "\n" ], [ ]);
			}
			NotecardToWrite = MergeObjectLists(CurrentDataRaw, NewDataRaw);
			llRemoveInventory(OBJECTS_LIST);
			// Objects list is rewritten in the timer. See there for explanation
			llSetTimerEvent(1.0);
		}
		string Text = "Receiving items ...\n-\n";
		Text += "\nWorld objects: "; if (DataProcessed & DP_REZZOR) Text += UNICODE_CHECK;
		Text += "\nConfig cards: "; if (DataProcessed & DP_CONTROLLER) Text += UNICODE_CHECK;
		Text += "\nIcons: "; if (DataProcessed & DP_CONTROLLER) Text += UNICODE_CHECK;
		Text += "\nTextures: "; if (DataProcessed & DP_PICKER) Text += UNICODE_CHECK;
		SetText(Text, COLOR_YELLOW);
	}
	timer() {
		llSetTimerEvent(0.0);
		if (ComponentId != NULL_KEY) {
			// An explanation here of why we send this message in a timer. The short answer is, I don't really know. However,
			// if we just send the message after deleting the files (ie in the places where the timer is now set), the
			// procedure hangs some of the time, as if the "archive end" message was not being received from the components. This only
			// happened when the archiver had contents, implying some kind of timing issue. This was so bad that it wasn't possible to
			// take a full backup. -- John
			MessageStandard(ComponentId, ARCH_BACKUP_FILES, []);
			ComponentId = NULL_KEY;
		}
		else if (NotecardToWrite != []) {
			// This timer event is a kind of dumping ground for workarounds for OpenSim bugs.
			// Our bug here is that deleting a notecard and rewriting it immediately sometimes causes the notecard to remain
			// in its initial state, as if nothing had happened. Putting the rewrite in a timer (ie in another sim frame) seems
			// to prevent this from happening. -- John
			osMakeNotecard(OBJECTS_LIST, NotecardToWrite);
			string SummaryText;
			if (Errors == []) {
				SummaryText = "Items downloaded OK";
				SetText("Items downloaded OK", COLOR_YELLOW);
			}
			else {
				SummaryText = "DOWNLOAD ERRORS:\n\n" + llDumpList2String(Errors, "\n");
				SetText("Download errors!", COLOR_RED);
			}
			llListen(MenuChannel, "", OwnerId, "");
			llDialog(OwnerId, "\n" + SummaryText, [ BUTTON_OK ], MenuChannel);
			return;
		}
		else {	// What on earth are we doing here?
			SetText("Sorry, internal processing error", COLOR_RED);		// yeah, great message
			return;
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == OwnerId) {
			if (Message == BUTTON_OK) {
				state Menu;
			}
		}
	}
	touch_start(integer Count) {
		if (DataProcessed == (DP_REZZOR | DP_CONTROLLER | DP_PICKER)) state Menu;
	}
	// Don't have a changed() event here if possible, otherwise you risk filling up the event queue during a backup
}
state Restore {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		Errors = [];
		DataProcessed = DP_NONE;
		NotecardToWrite = [];
		SetText("Sending items ...", COLOR_YELLOW);
		// Tell rezzor to get ready
		MessageStandard(RezzorId, ARCH_RESTORE_START, []);
	}
	dataserver(key From, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		integer Command = (integer)llList2String(Parts, 0);
		list Params = [];
		if (llGetListLength(Parts) > 1) Params = llList2List(Parts, 1, -1);
		if (From == RezzorId) {
			if (Command == ARCH_RESTORE_START) {	// This signal is a request for a files list
				MessageStandard(RezzorId, ARCH_RESTORE_FILES, ObjectNames("W"));
			}
			else if (Command == ARCH_RESTORE_FILES) {	// Request for the files themselves
				GiveInventoryList(RezzorId, ObjectNames("W"));
				MessageStandard(RezzorId, ARCH_RESTORE_END, []);
				DataProcessed = DataProcessed | DP_REZZOR;
				// Tell controller to get ready
				MessageStandard(ControllerId, ARCH_RESTORE_START, []);
			}
		}
		else if (From == ControllerId) {
			if (Command == ARCH_RESTORE_START) {	// This signal is a request for a files list
				MessageStandard(ControllerId, ARCH_RESTORE_FILES, ObjectNames("I") + ObjectNames("C"));
			}
			else if (Command == ARCH_RESTORE_FILES) {	// Request for the files themselves
				GiveInventoryList(ControllerId, ObjectNames("I"));
				GiveInventoryList(ControllerId, ObjectNames("C"));
				MessageStandard(ControllerId, ARCH_RESTORE_END, []);
				DataProcessed = DataProcessed | DP_CONTROLLER;
				// Tell picker to get ready
				MessageStandard(PickerId, ARCH_RESTORE_START, []);
			}
		}
		else if (From == PickerId) {
			if (Command == ARCH_RESTORE_START) {	// This signal is a request for a files list
				MessageStandard(PickerId, ARCH_RESTORE_FILES, ObjectNames("T"));
				string PickerListString = llList2String(Params, 0);
				PickerList = llParseString2List(PickerListString, [ "\n" ], [ ]);
			}
			else if (Command == ARCH_RESTORE_FILES) {	// Request for the files themselves
				GiveInventoryList(PickerId, ObjectNames("T"));
				// As part of ARCH_RESTORE_START, the picker sent us its current objects notecard. Now we read this
				// and merge it with our own objects list, and send the result back. If you're wondering why we do this
				// instead of sending our data and letting the picker do the merge, it's so that we don't have duplication
				// of the merge code. -- John
				list NewDataRaw;
				if (llGetInventoryType(OBJECTS_LIST) == INVENTORY_NOTECARD) {
					NewDataRaw = llParseString2List(osGetNotecard(OBJECTS_LIST), [ "\n" ], [ ]);
				}
				PickerList = MergeObjectLists(PickerList, NewDataRaw);
				string PickerListString = llDumpList2String(PickerList, "\n");
				MessageStandard(PickerId, ARCH_RESTORE_END, [ PickerListString ]);
				DataProcessed = DataProcessed | DP_PICKER;
			}
		}
		string Text = "Sending items ...\n-\n";
		Text += "\nWorld objects: "; if (DataProcessed & DP_REZZOR) Text += UNICODE_CHECK;
		Text += "\nConfig cards: "; if (DataProcessed & DP_CONTROLLER) Text += UNICODE_CHECK;
		Text += "\nIcons: "; if (DataProcessed & DP_CONTROLLER) Text += UNICODE_CHECK;
		Text += "\nTextures: "; if (DataProcessed & DP_PICKER) Text += UNICODE_CHECK;
		SetText(Text, COLOR_YELLOW);
		if (DataProcessed == (DP_REZZOR | DP_CONTROLLER | DP_PICKER)) {
			llListen(MenuChannel, "", OwnerId, "");
			SetText("Items uploaded OK", COLOR_YELLOW);
			llDialog(OwnerId, "\nUpload finished OK", [ BUTTON_OK ], MenuChannel);
			return;
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == OwnerId) {
			if (Message == BUTTON_OK) {
				state Booting;
			}
		}
	}
	touch_start(integer Count) {
		if (DataProcessed == (DP_REZZOR | DP_CONTROLLER | DP_PICKER)) state Menu;
	}
}
state Purge {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Purging library objects ...", COLOR_YELLOW);
		DataProcessed = DP_NONE;
		// Tell all components to purge their contents
		MessageStandard(RezzorId, ARCH_PURGE, []);
		MessageStandard(ControllerId, ARCH_PURGE, []);
		MessageStandard(PickerId, ARCH_PURGE, []);
	}
	dataserver(key From, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		integer Command = (integer)llList2String(Parts, 0);
		list Params = [];
		if (llGetListLength(Parts) > 1) Params = llList2List(Parts, 1, -1);
		if (Command == ARCH_PURGE) {
			if (From == RezzorId) {
				DataProcessed = DataProcessed | DP_REZZOR;
			}
			else if (From == ControllerId) {
				DataProcessed = DataProcessed | DP_CONTROLLER;
			}
			else if (From == PickerId) {
				DataProcessed = DataProcessed | DP_PICKER;
			}
			// Have we finished yet?
			if (DataProcessed == (DP_REZZOR | DP_CONTROLLER | DP_PICKER)) {	// If we've received message from everyone, we're done
				llListen(MenuChannel, "", OwnerId, "");
				llDialog(OwnerId, "\nLibrary objects purged", [ BUTTON_OK ], MenuChannel);
				return;
			}
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == OwnerId) {
			if (Message == BUTTON_OK) {
				state Booting;
			}
		}
	}
	touch_start(integer Count) {
		if (DataProcessed == (DP_REZZOR | DP_CONTROLLER | DP_PICKER)) state Menu;
	}
}
// This state deals with save-file notecards. The heavy lifting is done by the separate
// script in prim 2, which contains the backed-up notecards.
state SaveFiles {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		if (SaveFilesFunction == SFF_BACKUP) {
			SetText("Backing up save files", COLOR_YELLOW);
			llMessageLinked(LINK_SAVEFILES, ARCH_BACKUP_START, "", NotecardManagerId);
		}
		else if (SaveFilesFunction == SFF_RESTORE) {
			SetText("Restoring save files", COLOR_YELLOW);
			llMessageLinked(LINK_SAVEFILES, ARCH_RESTORE_START, "", NotecardManagerId);
		}
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Sender == LINK_SAVEFILES) {
			if (Number == ARCH_BACKUP_END || Number == ARCH_RESTORE_END) {
				llListen(MenuChannel, "", OwnerId, "");
				string S = "???";
				if (SaveFilesFunction == SFF_BACKUP) S = "Backup";
				else if (SaveFilesFunction == SFF_RESTORE) S = "Restore";
				llDialog(OwnerId, "\n" + S + " finished OK", [ BUTTON_OK ], MenuChannel);
				return;
			}
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == OwnerId) {
			if (Message == BUTTON_OK) {
				state Booting;
			}
		}
	}
	touch_start(integer Count) {
		state Menu;
	}
}
state Hang {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetText("Script suspended\n\nClick to restart", COLOR_RED);
	}
	touch_start(integer Count) {
		if (llDetectedKey(0) == OwnerId) llResetScript();
	}
}
// RezMela archiver v0.1