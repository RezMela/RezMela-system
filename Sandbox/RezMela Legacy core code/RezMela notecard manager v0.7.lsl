// RezMela notecard manager v0.7

// v0.7 - allow stretching of objects, etc
// v0.6 - integration with archiver
// v0.5 - change for "RMSF,2" format (extra fields)
// v0.4 - store environment details
// v0.3 - new close button menu feature
// v0.2 - use menu-on-a-prim

integer CURRENT_FORMAT_VERSION = 2;	// Change this when "RMSF" version number changes

float TIME_OUT = 1200.0;

integer LM_FILE_CANCEL = 40500;
integer LM_FILE_SAVE_START = 40501;
integer LM_FILE_SAVE_DATA = 40502;
integer LM_FILE_SAVE_END = 40503;
integer LM_FILE_CLEAR_SCENE = 40504;
integer LM_FILE_LOAD_START = 40505;
integer LM_FILE_LOAD_DATA = 40506;
integer LM_FILE_LOAD_END = 40507;
integer LM_FILE_DELETE = 40508;
integer LM_RESET_EVERTHING = 40509;

integer MENU_INIT = -30151400;
integer MENU_TITLE = -30151401;
integer MENU_DESCRIPTION = -30151402;
integer MENU_ACTIVATE = -30151404;
integer MENU_DIMENSIONS = -30151405;
integer MENU_CLEAR = -30151406;
integer MENU_OPTION = -30151407;
integer MENU_SORT = -30151408;
integer MENU_BUTTON = -30151409;
integer MENU_USER = -30151410;
integer MENU_RESPONSE = -30151411;
integer MENU_RESET = -30151412;
integer MENU_SIDES = -30151413;
integer MENU_CANCEL = -30151414;

// Archiver API constants
integer ARCH_BACKUP_START = 790400;
integer ARCH_BACKUP_FILES = 790401;
integer ARCH_BACKUP_END = 790402;
integer ARCH_RESTORE_START = 790410;
integer ARCH_RESTORE_FILES = 790411;
integer ARCH_RESTORE_END = 790412;
integer ARCH_PURGE = 790420;
integer ARCH_INFO = 790430;

key ArchiverId;

key OwnerId;
key MenuAvId;
integer Function;
integer MF_NONE = 0;
integer MF_LOAD = 1;		// enum constants for Function
integer MF_DELETE = 2;
integer MF_SAVE = 3;
integer DialogListener;
integer MenuChannel;
string BUTTON_CANCEL = "[ Close ]";

list Records;
integer RecordsSize;
integer RecordsPtr;

string EnvironmentDetails;	// String containing all environment data for current scene

// Copied from Controller Root and adapted
integer PANTO_REZZOR_CHANNEL = -101;
integer COMM_CHANNEL = -4000;
integer TAPE_CHANNEL = -15;
// End of copied code

ShowPrimMenu() {
	llSetTimerEvent(0.0);	// if they had a save waiting, it's irrelevant now
	string Verb = "????";
	if (Function == MF_LOAD) Verb = "load";
	else if (Function == MF_DELETE) Verb = "delete";
	Menu(MENU_INIT, "");
	Menu(MENU_DIMENSIONS, "512, 512");
	Menu(MENU_TITLE, "REZMELA");
	Menu(MENU_DESCRIPTION, "Select scene to " + Verb + ":");
	Menu(MENU_SIDES, "1");
	Menu(MENU_SORT, "S");	// "smart sort"
	Menu(MENU_OPTION, "xclosebutton");
	integer Len = llGetInventoryNumber(INVENTORY_NOTECARD);
	integer I;
	for(I = 0; I < Len; I++) {
		string Name = llGetInventoryName(INVENTORY_NOTECARD, I);
		if (NotecardNameValid(Name)) Menu(MENU_BUTTON, Name);
	}
	Menu(MENU_ACTIVATE, "");
}
SaveDialog(key AvId) {
	MenuAvId = AvId;
	Function = MF_SAVE;
	DialogListener = llListen(MenuChannel, "", MenuAvId, "");
	llSetTimerEvent(600.0);
	string MenuText = "\nEnter name for saved scene:";
	llTextBox(MenuAvId, MenuText, MenuChannel);
}
DialogTerminate() {
	MenuAvId = NULL_KEY;
	if (DialogListener) llListenRemove(DialogListener);
	DialogListener = 0;
	Function = MF_NONE;
}
ClearScene() {
	llRegionSay(COMM_CHANNEL, "deleteAll");
	llRegionSay(PANTO_REZZOR_CHANNEL, "deleteAll");
	llRegionSay(TAPE_CHANNEL, "self_remove");
}
// Return FALSE if "Name" is not a loadable notecard
integer NotecardNameValid(string Name) {
	string LineOne = osGetNotecardLine(Name, 0);
	list Parts = llCSV2List(LineOne);
	string IdString = llList2String(Parts, 0);
	integer FormatVersion = (integer)llList2String(Parts, 1);
	return (IdString == "RMSF" && FormatVersion == CURRENT_FORMAT_VERSION);
}
// Send command to menu
Menu(integer Command, string Text) {
	llMessageLinked(LINK_SET, Command, Text, NULL_KEY);
}
list ListNotecards() {
	list Ret;
	integer Len = llGetInventoryNumber(INVENTORY_NOTECARD);
	integer I;
	for (I = 0; I < Len; I++) {
		Ret += llGetInventoryName(INVENTORY_NOTECARD, I);
	}
	return Ret;
}
DeleteAllNotecards() {
	integer Len = llGetInventoryNumber(INVENTORY_NOTECARD);
	while(Len--) {
		llRemoveInventory(llGetInventoryName(INVENTORY_NOTECARD, 0));
	}
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
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		OwnerId = llGetOwner();
		Function = MF_NONE;
		MenuChannel = -1000 - (integer)llFrand(100000000.0);
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Sender == LINK_ROOT) {
			if (Number == LM_FILE_SAVE_START) {
				EnvironmentDetails = Message;	// Environment details piggyback this data, using a spare slot
				// If more metadata needs to be stored, we could concatenate it onto environment data (use another separator between sections?)
				Records = [ "!environment|" + EnvironmentDetails ];	// EnvironmentDetails is itself a |-separated list of data
				llMessageLinked(LINK_ROOT, LM_FILE_SAVE_DATA, "", NULL_KEY);
			}
			else if (Number == LM_FILE_SAVE_DATA) {
				if (Message == "")		// Paranoid check
					llOwnerSay("WARNING: Empty data ignored in save");
				else
					Records += Message;
				llMessageLinked(LINK_ROOT, LM_FILE_SAVE_DATA, "", NULL_KEY);
			}
			else if (Number == LM_FILE_SAVE_END) {
				SaveDialog(Id);
			}
			else if (Number == LM_FILE_LOAD_START) {
				Function = MF_LOAD;
				ShowPrimMenu();
			}
			else if (Number == LM_FILE_LOAD_DATA) {
				if (RecordsPtr == RecordsSize) {	// no more data
					llMessageLinked(LINK_ROOT, LM_FILE_LOAD_END, "", Id);
					Function = MF_NONE;
					return;
				}
				llMessageLinked(LINK_ROOT, LM_FILE_LOAD_DATA, llList2String(Records, RecordsPtr), Id);
				RecordsPtr++;
			}
			else if (Number == LM_FILE_DELETE) {
				Function = MF_DELETE;
				ShowPrimMenu();
			}
			else if (Number == LM_RESET_EVERTHING) {
				llResetScript();
			}
			return;
		}
		//
		// Responses from non-root prims
		//
		// Response from menu system
		if (Number == MENU_RESPONSE && Function != MF_NONE) {
			string NotecardName = Message;
			if (Function == MF_LOAD) {
				Records = [];
				integer Len = osGetNumberOfNotecardLines(NotecardName);
				integer LineNum;
				for (LineNum = 1; LineNum < Len; LineNum++) {	// we start on the second line
					string Data =  osGetNotecardLine(NotecardName, LineNum);
					if (llStringTrim(Data, STRING_TRIM) != "") {
						Records += Data;
					}
				}
				RecordsSize = llGetListLength(Records);
				RecordsPtr = 0;
				llMessageLinked(LINK_ROOT, LM_FILE_CLEAR_SCENE, "", Id);
			}
			else if (Function == MF_DELETE) {
				llRemoveInventory(NotecardName);
				ShowPrimMenu();
			}
		}
		else if (Number == MENU_CANCEL) {		// X button, menu script reset or similar
			llMessageLinked(LINK_ROOT, LM_FILE_CANCEL, "", MenuAvId);
			llResetScript();
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == MenuAvId) {
			if (Function == MF_SAVE) {
				// return from llTextBox
				if (Message == "") {	// empty name
					llRegionSayTo(MenuAvId, 0, "Save cancelled");
					DialogTerminate();
					llMessageLinked(LINK_ROOT, LM_FILE_CANCEL, "", Id);
					return;
				}
				if (llGetInventoryType(Message) == INVENTORY_NOTECARD) llRemoveInventory(Message);
				if (llGetInventoryType(Message) != INVENTORY_NONE) {
					llRegionSayTo(MenuAvId, 0, "Invalid name - not saved");
					DialogTerminate();
					llMessageLinked(LINK_ROOT, LM_FILE_CANCEL, "", Id);
					return;
				}
				Records = [ "RMSF,2" ] + Records;
				osMakeNotecard(Message, Records);
				llRegionSayTo(MenuAvId, 0, "Scene saved as '" + Message + "'");
				DialogTerminate();
			}
		}
	}
	dataserver(key From, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		integer Command = (integer)llList2String(Parts, 0);
		list Params = [];
		if (llGetListLength(Parts) > 1) Params = llList2List(Parts, 1, -1);
		if (Command == ARCH_INFO) {
			ArchiverId = From;
			MessageStandard(ArchiverId, ARCH_INFO, [ llGetInventoryNumber(INVENTORY_NOTECARD) ]);
		}
		else if (Command == ARCH_BACKUP_START) {
			ArchiverId = From;
			GiveInventoryList(ArchiverId, ListNotecards());
			MessageStandard(ArchiverId, ARCH_BACKUP_END, []);
		}
		else if (Command == ARCH_RESTORE_START) {
			ArchiverId = From;
			DeleteAllNotecards();
			MessageStandard(ArchiverId, ARCH_RESTORE_FILES, []);
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		DialogTerminate();
		llMessageLinked(LINK_ROOT, LM_FILE_CANCEL, "", MenuAvId);
	}
	changed(integer Change) {
		if (Change & CHANGED_OWNER) llResetScript();
	}
}
// RezMela notecard manager v0.7