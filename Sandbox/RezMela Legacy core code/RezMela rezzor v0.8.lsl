// RezMela rezzor v0.8

// v0.8 - various issues arising from beta
// v0.7 - changes for updater HUD
// v0.6 - strip version number for rezzor object name checks
// v0.5 - add  new updater
// v0.4 - change object suffix from "P" to "W"
// v0.3 - add integrity check
// v0.2 - add updater code

float Version = 0.1;

string SUFFIX_WORLD_OBJECT = "W";

integer OBJECT_PIN = 50200;

integer CHAT_CHANNEL = -94040100;
integer UPDATE_CHANNEL = -355210124;
integer ChatListener;
key UpdaterId;

float POSITION_IDENTIFICATION_TOLERANCE = 0.1;

key ControlBoardId;
string MyName;			// object name without version suffix
vector RegionSize;

// Rezzor commands
integer RZ_PING = 2000;
integer RZ_CREATE = 2001;
integer RZ_MOVE  = 2002;
integer RZ_RESET = 2003;
integer RZ_UPDATE = 2004;
integer RZ_INTEGRITY_CHECK = 2005;

// World object commands
integer WO_MOVE = 3000;
integer WO_ROTATE = 3001;
integer WO_MOVE_ROTATE = 3002;
integer WO_DELETE = 3003;
integer WO_INITIALISE = 3004;
integer WO_SELECT = 3005;
integer WO_DESELECT = 3006;

// Icon commands
integer IC_MOVE = 1000;
integer IC_ROTATE = 1001;
integer IC_MOVE_ROTATE = 1002;
integer IC_RESIZE = 1003;
integer IC_SELECT = 1004;
integer IC_DESELECT = 1005;
integer IC_INITIALISE = 1006;
integer IC_DELETE = 1007;
integer IC_SHORT_CLICK = 1008;
integer IC_LONG_CLICK = 1009;

// General commands
integer GE_VERSION = 9000;

// Only used for integrity check
key ObjectPickerId;

integer ObjectUniq;
list Queue;		// [ Unique integer, Icon UUID ]

integer ResetPhase;
list ResetTargets;
float RESET_STEP = 50.0;

key ArchiverId;
integer ArchiveAction;
integer ARCHIVE_BACKUP = 1;
integer ARCHIVE_RESTORE = 2;
integer ARCHIVE_PURGE = 3;
list ArchiveFiles;

integer ARCH_BACKUP_START = 790400;
integer ARCH_BACKUP_FILES = 790401;
integer ARCH_BACKUP_END = 790402;
integer ARCH_RESTORE_START = 790410;
integer ARCH_RESTORE_FILES = 790411;
integer ARCH_RESTORE_END = 790412;
integer ARCH_PURGE = 790420;

integer TimerPurpose;
integer TP_FINISH = 1;
integer TP_REQUEST = 2;
integer TP_PURGED = 3;

string MakeObjectName(string ObjectName) {
	return ObjectName + SUFFIX_WORLD_OBJECT;
}
// Wrapper for osMessageObject() that checks to see if control board exists
MessageControl(integer Command, list Params) {
	if (ControlBoardId != NULL_KEY) {
		if (ObjectExists(ControlBoardId)) {
			osMessageObject(ControlBoardId, (string)Command + "|" + llDumpList2String(Params, "|"));
		}
		else {
			llOwnerSay("Can't find control board");
			ControlBoardId = NULL_KEY;
		}
	}
}
MoveTo(vector NewPos) {
	list Params = [];
	integer Jumps = (integer)(llVecDist(llGetPos(), NewPos) / 10.0) + 1;
	while(Jumps--) {
		Params += [ PRIM_POSITION, NewPos ];
	}
	llSetLinkPrimitiveParamsFast(1, Params);
}
ListenForControlBoard() {
	ChatListener = llListen(CHAT_CHANNEL, "", NULL_KEY, "");
}
// Returns a list of all object basenames
list ListObjects() {
	integer ObjectsCount = llGetInventoryNumber(INVENTORY_OBJECT);
	list Objects = [];
	integer O;
	for (O = 0; O < ObjectsCount; O++) {
		string Name = llGetInventoryName(INVENTORY_OBJECT, O);
		if (llGetSubString(Name, -1, -1) == SUFFIX_WORLD_OBJECT) {
			string BaseName = llGetSubString(Name, 0, -2);
			Objects += BaseName;
		}
	}
	return Objects;
}
// Returns a list of all object names (including suffix)
list ListObjectsFull() {
	integer ObjectsCount = llGetInventoryNumber(INVENTORY_OBJECT);
	list Objects = [];
	integer O;
	for (O = 0; O < ObjectsCount; O++) {
		string Name = llGetInventoryName(INVENTORY_OBJECT, O);
		if (llGetSubString(Name, -1, -1) == SUFFIX_WORLD_OBJECT) {
			Objects += Name;
		}
	}
	return Objects;
}
// llGiveInventoryList() doesn't work in OpenSim when the target is a prim; this emulates that function
GiveInventoryList(key Uuid, list Objects) {
	integer Len = llGetListLength(Objects);
	integer O;
	for (O = 0; O < Len; O++) {
		string ObjectName = llList2String(Objects, O);
		llGiveInventory(Uuid, ObjectName);
	}
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
CheckIntegrity() {
	integer ObjectsCount = llGetInventoryNumber(INVENTORY_OBJECT);
	list Objects = [];
	list Errs = [];
	integer O;
	for (O = 0; O < ObjectsCount; O++) {
		string Name = llGetInventoryName(INVENTORY_OBJECT, O);
		if (!IsFullPerm(Name)) {
			Errs += Name;
		}
		if (llGetSubString(Name, -1, -1) == SUFFIX_WORLD_OBJECT) {
			string BaseName = llGetSubString(Name, 0, -2);
			Objects += BaseName;
		}
		else {
			llOwnerSay("WARNING:\nObject in rezzor without correct suffix: " + Name);
		}
	}
	if (Errs != []) {
		llOwnerSay("WARNING:\nWorld Objects in rezzor with bad permissions:\n" + llDumpList2String(Errs, "\n"));
	}
	osMessageObject(ObjectPickerId, llDumpList2String(Objects, "|"));		// send list of object basenames to object picker for checking
}
// Check permissions of inventory object, notecard, etc
integer IsFullPerm(string Name) {
	return (PermsCheck(Name, MASK_BASE) && PermsCheck(Name, MASK_OWNER) && PermsCheck(Name, MASK_NEXT));
}
integer PermsCheck(string Name, integer Mask) {
	integer Perms = llGetInventoryPermMask(Name, Mask);
	return (Perms & PERM_COPY && Perms & PERM_MODIFY && Perms & PERM_TRANSFER);
}
// Strip version number from name
string StripVersion(string Name) {
	integer Phase = 0;
	// string v12.34
	// phase  433211
	integer C;
	for (C = llStringLength(Name) - 1; C; C--) {
		string Char = llGetSubString(Name, C, C);
		integer IsNumber = (Char == "0" || (integer)Char);
		integer IsDecimal = (Char == ".");
		integer IsV = (Char == "v" || Char == "V");
		integer IsSpace = (Char == " ");
		if (Phase == 0) {		// at end of name
			if (IsNumber)
				Phase = 1;
			else
				return Name;	// ends in non-version character
		}
		else if (Phase == 1) {	// currently on a subversion numeric
			if (!IsNumber) {		// but this is non-numeric
				if (IsDecimal)		// a dot is OK, move on to next phase
					Phase = 2;
				else
					return Name;	// not a dot, so not a version number
			}
			// else is subversion number, which is OK
		}
		else if (Phase == 2) {	// previous was decimal
			if (!IsNumber) return Name;		// anything but a number is not a valid version string
			Phase = 3; // on major version
		}
		else if (Phase == 3) {	// currently on major version
			if (!IsNumber) {	// if it's not a number, we need to process it
				if (IsV)	// it's the v
					Phase = 4;
				else
					return Name;		// it's not a version number because it doesn't have a v
			}
		}
		else {		// phase is 4 (the "v")
			if (!IsSpace) return Name;	// the v wasn't preceded by a space, so return whole name
			return llGetSubString(Name, 0, C - 1); 	// 	return string up to space
		}
	}
	llOwnerSay("Name version parsing error");
	return "CAN'T PARSE NAME";
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
		llOwnerSay("Missing object!");
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
	on_rez(integer Start) { llResetScript(); }
	state_entry() {
		state Bootup;
	}
}
state Bootup {
	on_rez(integer Start) { llResetScript(); }
	state_entry() {
		llSetRemoteScriptAccessPin(OBJECT_PIN);
		state Normal;
	}
}
state Normal {
	on_rez(integer Start) { llResetScript(); }
	state_entry() {
		MyName = StripVersion(llGetObjectName());
		RegionSize = osGetRegionSize();
		ListenForControlBoard();
		llSetTimerEvent(2.0);	// exact value doesn't matter
		UpdaterId = NULL_KEY;
	}
	dataserver(key From, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		integer Command = (integer)llList2String(Parts, 0);
		if (Command == RZ_PING) {
			string CName = llList2String(Parts, 1);		// get the rezzor name the control board is broadcasting to
			if (CName == MyName) {	// if it's this rezzor, then it's our control board
				ControlBoardId = From;
			}
		}
		else if (Command == RZ_CREATE) {
			string WorldName = llList2String(Parts, 1);
			vector WorldPos = llList2Vector(Parts, 2);
			rotation Rot = llList2Rot(Parts, 3);
			key IconId = llList2Key(Parts, 4);
			MoveTo(WorldPos);
			// Let's talk about this "Uniq" thing.
			// We have the usual problem encountered by rezzing scripts - that it's hard to tie
			// a call to llRezObject() to the object it created. And we need to know the relationship
			// between the two in order to match together the icon UUID (that the control board gave us)
			// with the UUID of the world object.
			// We don't need to know this information in this script, but the control board script does, so
			// we provide it. And we do that by passing a unique number through the start parameter to the world
			// object script. When that script kicks in, it sends us the same number back so we can relate it
			// to the llRezObject() data. It uses the WO_INITIALISE command to send the data, so see that code
			// for the rest of the process
			integer Uniq = ++ObjectUniq;	// get the next unique number
			llRezObject(MakeObjectName(WorldName), WorldPos, ZERO_VECTOR, Rot, Uniq);
			// Store the unique number and icon ID for later
			Queue += [ Uniq, IconId ];
		}
		else if (Command == RZ_MOVE) {
			vector Pos = llList2Vector(Parts, 1);
			MoveTo(Pos);
		}
		else if (Command == RZ_RESET) {
			vector ControlBoardPos = llList2Vector(llGetObjectDetails(From, [ OBJECT_POS ]), 0);
			MoveTo(ControlBoardPos);
			ResetPhase = 1;
			state Reset;
		}
		else if (Command == RZ_UPDATE) {
			string Action = llList2String(Parts, 1);
			list Objects = llList2List(Parts, 2, -1);
			if (Action == "list") {
				osMessageObject(From, llDumpList2String(ListObjects(), "|"));
			}
			else if (Action == "download") {
				string Object = llList2String(Objects, 0) + SUFFIX_WORLD_OBJECT;
				if (llGetInventoryType(Object) == INVENTORY_OBJECT) {
					llGiveInventory(From, Object);
				}
			}
			else if (Action == "delete") {
				string Object = llList2String(Objects, 0) + SUFFIX_WORLD_OBJECT;
				if (llGetInventoryType(Object) == INVENTORY_OBJECT) {
					llRemoveInventory(Object);
				}
			}
			else if (Action == "upload") {
				integer Len = llGetListLength(Objects);
				integer O;
				for (O = 0; O < Len; O++) {
					string Name = llList2String(Objects, O) + SUFFIX_WORLD_OBJECT;
					if (llGetInventoryType(Name) == INVENTORY_OBJECT) llRemoveInventory(Name);
				}
				// Now tell updater they're clear to send the updated objects
				osMessageObject(From, "");
			}
		}
		else if (Command == ARCH_BACKUP_START) {
			if (llGetOwnerKey(From) != llGetOwner()) return;	// Only owner's archiver can talk to me
			ArchiverId = From;
			ArchiveAction = ARCHIVE_BACKUP;
			state Archive;
		}
		else if (Command == ARCH_RESTORE_START) {
			if (llGetOwnerKey(From) != llGetOwner()) return;	// Only owner's archiver can talk to me
			ArchiverId = From;
			ArchiveAction = ARCHIVE_RESTORE;
			state Archive;
		}
		else if (Command == ARCH_PURGE) {
			if (llGetOwnerKey(From) != llGetOwner()) return;	// Only owner's archiver can talk to me
			ArchiverId = From;
			ArchiveAction = ARCHIVE_PURGE;
			state Archive;
		}
		else if (Command == RZ_INTEGRITY_CHECK) {
			ObjectPickerId = From;
			CheckIntegrity();
		}
		else if (Command == WO_INITIALISE) {
			key WorldId = From;
			// The world object script passes us the same unique number we passed it back in llRezObject().
			integer Uniq = llList2Integer(Parts, 1);
			// So we find it on the queue
			integer Q = llListFindList(Queue, [ Uniq ]);
			if (Q == -1) { llOwnerSay("Can't find queue entry"); return; }
			key IconId = llList2Key(Queue, Q + 1);
			// Now we pass the icon UUID and the world object UUID to the control board script, which needs
			// to know the relationship between those two ids.
			MessageControl(RZ_CREATE, [ IconId, From ]);
			Queue = llDeleteSubList(Queue, Q, Q + 1);
		}
		else if (Command == GE_VERSION) {
			osMessageObject(From, "R" + (string)Version);
		}
	}
	timer() {
		MyName = llGetObjectName();
		MessageControl(RZ_PING, [ MyName ]);
		if (ControlBoardId == NULL_KEY) ListenForControlBoard();	// control board has disappeared or been reset
		llRegionSay(UPDATE_CHANNEL, "rezzor");
	}
	listen(integer Channel, string Name, key Id, string Message) {
		// we know it's a control board from the listen message filter
		list Parts = llParseStringKeepNulls(Message, [ "|" ], []);
		integer Command = (integer)llList2String(Parts, 0);
		if (Command == RZ_PING) {
			string CName = llList2String(Parts, 1);		// get the rezzor name the control board is broadcasting to
			if (CName == MyName) {	// if it's this rezzor, then it's our control board
				ControlBoardId = Id;
				llListenRemove(ChatListener);
				llOwnerSay("Control board communication established");
				MessageControl(RZ_PING, [ MyName ]);	// Tell the control board who we are
			}
		}
	}
}
state Reset {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSensorRepeat("", NULL_KEY, SCRIPTED, RESET_STEP * 2.0, PI, 1.0);
		llRegionSayTo(llGetOwner(), 0, "Reset started");
		llSetTimerEvent(1.0);
		ResetTargets = [];
	}
	sensor(integer Count) {
		integer Sent = FALSE;
		while(Count--) {
			key Uuid = llDetectedKey(Count);
			if (llListFindList(ResetTargets, [ Uuid ]) == -1) {
				llSetTimerEvent(1.0);
				ResetTargets += Uuid;
				osMessageObject(Uuid, (string)GE_VERSION);
				Sent = TRUE;
			}
		}
		if (!Sent) llSetTimerEvent(0.2);
	}
	dataserver(key From, string Data) {
		llSetTimerEvent(1.0);
		string Type = llGetSubString(Data, 0, 0);
		integer DeleteSignal;
		if (Type == "W") DeleteSignal = WO_DELETE; else DeleteSignal = IC_DELETE;
		osMessageObject(From, (string)DeleteSignal);
	}
	no_sensor() {
		llSetTimerEvent(0.2);	// jump to next timer
	}
	timer() {
		llSetTimerEvent(0.0);
		if (ResetPhase == 1) {		// was at control board, now to go to start of region
			vector Pos = <RESET_STEP, RESET_STEP, 22>;
			Pos.z = llGround(Pos) + RESET_STEP;
			MoveTo(Pos);
			ResetPhase = 2;
		}
		else {
			vector Pos = llGetPos();
			Pos.x += RESET_STEP;
			if (Pos.x > RegionSize.x - RESET_STEP) {
				Pos.x = RESET_STEP;
				Pos.y += RESET_STEP;
				if (Pos.y > RegionSize.y - RESET_STEP) {
					llRegionSayTo(llGetOwner(), 0, "Reset finished");
					llSetTimerEvent(0.0);
					ResetTargets = [];
					state Normal;
				}
			}
			MoveTo(Pos);
		}
		llSensorRepeat("", NULL_KEY, SCRIPTED, RESET_STEP * 2.0, PI, 1.0);
		llSetTimerEvent(2.0);
	}
}
state Archive {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		if (ArchiveAction == ARCHIVE_BACKUP) {
			// When we receive "backup", we send "backupfiles" with a list of our files and wait.
			// Archiver will delete its copies of those files and send "backupstart".
			ArchiveFiles = ListObjectsFull();
			MessageStandard(ArchiverId, ARCH_BACKUP_FILES, ArchiveFiles);
		}
		else if (ArchiveAction == ARCHIVE_RESTORE) {
			MessageStandard(ArchiverId, ARCH_RESTORE_START, []);	// Request list of files
		}
		else if (ArchiveAction == ARCHIVE_PURGE) {
			DeleteFiles(ListObjectsFull());
			TimerPurpose = TP_PURGED;
			llSetTimerEvent(0.5);
		}
	}
	dataserver(key From, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		integer Command = llList2Integer(Parts, 0);
		list Params = llList2List(Parts, 1, -1);
		if (From == ArchiverId) {
			if (Command == ARCH_BACKUP_FILES) {
				// Archiver is ready to receive backup, so send the files
				GiveInventoryList(From, ArchiveFiles);
				ArchiveFiles = [];
				// Send confirmation that that's all the files
				MessageStandard(ArchiverId, ARCH_BACKUP_END, []);
				// Return to normality
				TimerPurpose = TP_FINISH;
				llSetTimerEvent(0.5);
			}
			else if (Command == ARCH_RESTORE_FILES) {
				ArchiveFiles = llList2List(Params, 0, -1);
				DeleteFiles(ArchiveFiles);
				// Request files
				TimerPurpose = TP_REQUEST;
				llSetTimerEvent(0.5);
			}
			else if (Command == ARCH_RESTORE_END) {
				// Return to normality
				TimerPurpose = TP_FINISH;
				llSetTimerEvent(0.5);
			}
		}
	}
	timer() {
		// Once more, we're using a timer to circumvent OpenSim glitches by forcing processes into another sim frame
		llSetTimerEvent(0.0);
		if (TimerPurpose == TP_FINISH) {
			state Normal;
		}
		else if (TimerPurpose == TP_REQUEST) {
			MessageStandard(ArchiverId, ARCH_RESTORE_FILES, []);
		}
		else if (TimerPurpose == TP_PURGED) {
			MessageStandard(ArchiverId, ARCH_PURGE, []);
			state Normal;
		}
	}
}
// RezMela rezzor v0.8