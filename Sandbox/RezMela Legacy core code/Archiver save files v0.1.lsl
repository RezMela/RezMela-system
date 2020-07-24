// Archiver save files v0.1

// Integration constants
integer ARCH_BACKUP_START = 790400;
integer ARCH_BACKUP_FILES = 790401;
integer ARCH_BACKUP_END = 790402;
integer ARCH_RESTORE_START = 790410;
integer ARCH_RESTORE_FILES = 790411;
integer ARCH_RESTORE_END = 790412;
integer ARCH_PURGE = 790420;
integer ARCH_INFO = 790430;

key NotecardManagerId;	// UUID of notecard manager prim

// List all notecards in contents
list ListNotecards() {
	list Ret;
	integer Len = llGetInventoryNumber(INVENTORY_NOTECARD);
	integer I;
	for (I = 0; I < Len; I++) {
		Ret += llGetInventoryName(INVENTORY_NOTECARD, I);
	}
	return Ret;
}
// Delete all notecards in contents
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
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
default {
	state_entry() {
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Sender == 1) {	// If message from root (ie archiver main script)
			if (Number == ARCH_INFO) {	// Request for number of notecards
				llMessageLinked(LINK_ROOT, ARCH_INFO, (string)llGetInventoryNumber(INVENTORY_NOTECARD), NULL_KEY);
			}
			else if (Number == ARCH_BACKUP_START) {		// Start backup
				NotecardManagerId = Id;
				DeleteAllNotecards();			// We delete all notecards to make room
				MessageStandard(NotecardManagerId, ARCH_BACKUP_START, []);	// Tell archiver it's clear to start sending files
			}
			else if (Number == ARCH_RESTORE_START) {	// Start restore
				NotecardManagerId = Id;
				MessageStandard(NotecardManagerId, ARCH_RESTORE_START, [ ListNotecards() ]);	// Tell archiver the files we're sending so it can delete its copies
			}
		}
	}
	dataserver(key From, string Data) {
		if (From == NotecardManagerId) {
			list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
			integer Command = (integer)llList2String(Parts, 0);
			list Params = [];
			if (llGetListLength(Parts) > 1) Params = llList2List(Parts, 1, -1);
			if (Command == ARCH_BACKUP_END) {
				// notecard manager has finished sending us files, so we tell the
				// main archiver script that we're done here.
				llMessageLinked(LINK_ROOT, ARCH_BACKUP_END, "", NULL_KEY);
			}
			else if (Command == ARCH_RESTORE_FILES) {
				// notecard manager is ready to receive files, so we send them
				GiveInventoryList(NotecardManagerId, ListNotecards());
				llMessageLinked(LINK_ROOT, ARCH_RESTORE_END, "", NULL_KEY);
			}
		}
	}
}
// Archiver save files v0.1