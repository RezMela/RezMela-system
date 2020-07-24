// RezMela object picker v0.14

// v0.14 - changed login (registering) method
// v0.13 - changes arising from beta testing 5/16
// v0.12 - handle empty system
// v0.11 - experimental delay in notecard write during update
// v0.10 - soft labels for categories
// v0.9 - fix incorrect error message
// v0.8 - add check that category notecard is written
// v0.7 - add support for updater
// v0.6 - bug fixes in checker
// v0.5 - changes for linking object picker into control board
// v0.4 - added registration feature
// v0.3 - fixed bug with duplicate icons showing after notecard change
// v0.2 - fixed bug with page/arrow keys on thumbnails

string OBJECTS_LIST = "!Objects";

integer PICKER_CHANNEL = -209441200;

integer UI_LABEL_SET_TEXT = -844710300;
integer UI_LABEL_REQUEST_TEXT = -844710301;

string SUFFIX_TEXTURE = "T";

// Commands
integer PI_UPDATE = 8400;

list Objects;
integer OBJ_NAME = 0;			// (string) name of object
integer OBJ_CATEGORY = 1;		// (string) category
integer OBJ_TEXTURE_ID = 2;		// (key) UUID of texture
integer OBJ_STRIDE = 3;
integer ObjectsCount;	// length of list

list Categories;

list PrimCategories;		// [ (integer)LinkNum, -(integer)CategoryPointer ] (note negative so finds can work)
integer PrimCount;

list PrimThumbnails;

list TextureUuids;	// list of texture UUIDs for pre-rezzing
integer TextureCount;	// count of textures

integer UpdateDue;
integer UploadReady;
integer PreRezPtr;
list PRE_REZ_SIDES = [ 0, 2, 3, 4, 5 ];
integer PRE_REZ_SIDE_COUNT = 5;

list NotecardToWrite;		// contents of !Objects notecard to be written

string Category;		// current category
list CatObjects;		// list of object names in current category
list CatTextures;		// (parallel) list of textures
integer CatObjectCount;
integer ThumbPageStart;
integer THUMBNAILS_PER_PAGE = 20;
integer THUMBNAIL_PRIM_SIDE = 1;

integer PrimPagePrev;
integer PrimPageNext;

key RegisteredId;
key UpdaterUuid;

// fields used for integrity checking only
key RezzorId;
list IconList;
integer RZ_INTEGRITY_CHECK = 2005;	// rezzor dataserver message

// Link messages for control board comms
integer LM_DELEGATED_CLICK = 40510;
integer LM_OBJECT_PICKER = 40511;
integer LM_INTEGRITY_CHECK = 40512;
integer LM_BOOTED = 40514;
integer LM_REGISTER_AV = 40515;

// Archiver stuff
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
integer TP_NOTECARD = 4;

Display() {
	list Params = [];
	integer PS = ThumbPageStart;
	integer PE = PS + THUMBNAILS_PER_PAGE;
	integer P;
	integer ThumbNum = 0;
	for(P = PS; P < PE; P++) {
		integer ThumbLinkNum = llList2Integer(PrimThumbnails, ThumbNum);
		if (P < CatObjectCount) {	// in range
			string Name = llList2String(CatObjects, P);
			key Texture = llList2Key(CatTextures, P);
			Params += [
				PRIM_LINK_TARGET, ThumbLinkNum,
				PRIM_COLOR, THUMBNAIL_PRIM_SIDE, <1.0, 1.0, 1.0>, 1.0,
				PRIM_TEXTURE, THUMBNAIL_PRIM_SIDE, Texture, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0,
				PRIM_DESC, Name + "," + (string)Texture		// store data in description for simplicity
					];
		}
		else {			// beyond end of objects for category, so hide buttons
			Params += [
				PRIM_LINK_TARGET, ThumbLinkNum,
				PRIM_COLOR, THUMBNAIL_PRIM_SIDE, <1.0, 1.0, 1.0>, 0.0,
				PRIM_TEXTURE, THUMBNAIL_PRIM_SIDE, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0,
				PRIM_DESC, ""
					];
		}
		ThumbNum++;
	}
	// Prev page button
	Params += [ PRIM_LINK_TARGET, PrimPagePrev, PRIM_COLOR, THUMBNAIL_PRIM_SIDE, <1.0, 1.0, 1.0> ];
	if (IsPrevThumbPage()) Params += 1.0; else Params += 0.0;
	// Next page button
	Params += [ PRIM_LINK_TARGET, PrimPageNext, PRIM_COLOR, THUMBNAIL_PRIM_SIDE, <1.0, 1.0, 1.0> ];
	if (IsNextThumbPage()) Params += 1.0; else Params += 0.0;
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
}
// Return TRUE if there is a previous page of thumbnails
integer IsPrevThumbPage() {
	return (ThumbPageStart > 0);
}
// Return TRUE if there is a next page of thumbnails
integer IsNextThumbPage() {
	return (CatObjectCount >= (ThumbPageStart + THUMBNAILS_PER_PAGE));
}
Select(string ObjectName, key Texture) {
	llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEXTURE, THUMBNAIL_PRIM_SIDE, Texture, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0 ]);
	llMessageLinked(LINK_ROOT, LM_OBJECT_PICKER, ObjectName, RegisteredId);
}
OpenCategory(integer CategoryPointer) {
	Category = llList2String(Categories, CategoryPointer);
	CatObjects = [];
	CatTextures = [];
	ThumbPageStart = 0;
	integer O;
	for (O = 0; O < ObjectsCount; O += OBJ_STRIDE) {
		string ThisCategory = llList2String(Objects, O + OBJ_CATEGORY);
		if (ThisCategory == Category) {
			string Name = llList2String(Objects, O + OBJ_NAME);
			key Texture = llList2Key(Objects, O + OBJ_TEXTURE_ID);
			CatObjects += Name;
			CatTextures += Texture;
		}
	}
	CatObjectCount = llGetListLength(CatObjects);
	Display();
	if (CatObjectCount) {
		Select(llList2String(CatObjects, 0), llList2Key(CatTextures, 0));	// select first object in category
	}
	else {	// No objects in category - set preview texture to transparent
		llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEXTURE, THUMBNAIL_PRIM_SIDE, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0 ]);
	}
}
CategoryRename(string OldName, string NewName) {
	list Lines = llParseStringKeepNulls(osGetNotecard(OBJECTS_LIST), [ "\n" ], []);
	integer Len = llGetListLength(Lines);
	Len = llGetListLength(Lines);
	integer P;
	for (P = 0; P < Len; P++) {
		string Line = llStringTrim(llList2String(Lines, P), STRING_TRIM);
		if (Line == "[" + OldName + "]") {
			Line = "[" + NewName + "]";
			Lines = llListReplaceList(Lines, [ Line ], P, P);
		}
	}
	llRemoveInventory(OBJECTS_LIST);
	NotecardToWrite = llList2List(Lines, 0, -1);	// will be written in the timer event
}
TurnPage(integer Direction) {
	ThumbPageStart += (THUMBNAILS_PER_PAGE * Direction);
	Display();
}
integer GetPrims() {
	PrimCount = llGetNumberOfPrims();
	if (PrimCount == 1) return FALSE;	// unlinked, so hang
	PrimPagePrev = PrimPageNext = -1;
	// Set up empty thumbnails list
	PrimThumbnails = [];
	integer T = THUMBNAILS_PER_PAGE;
	while(T--) PrimThumbnails += [ -1 ];
	PrimCategories = [];
	integer P;
	for(P = 1; P <= PrimCount; P++) {
		string Name = llGetLinkName(P);
		if (llGetSubString(Name, 0, 7) == "Display ") {
			integer Which = (integer)llGetSubString(Name, 8, -1) - 1;
			PrimThumbnails = llListReplaceList(PrimThumbnails, [ P ], Which, Which);
			//llSetLinkAlpha(P, 0.0, ALL_SIDES);
		}
		else if (llGetSubString(Name, 0, 0) == "@") {
			integer C = (integer)llGetSubString(Name, 1, -1);
			if (C <= 0) {
				llOwnerSay("*** ERROR in category button name: '" + Name + "'");
			}
			else {
				integer CategoryPointer = C - 1;		// -1 because prims start with 1, list with 0
				PrimCategories += [ P, -CategoryPointer ];
			}
		}
		else if (Name == "Page -") {
			PrimPagePrev = P;
		}
		else if (Name == "Page +") {
			PrimPageNext = P;
		}
	}
	// Check that all thumbnail prims are there
	for (T = 0 ; T < THUMBNAILS_PER_PAGE; T++) {
		if (llList2Integer(PrimThumbnails, T) == -1) {
			llOwnerSay("ERROR: Missing thumbnail prim(s): " + (string)(T + 1));
			return FALSE;
		}
	}
	if (PrimPageNext == -1 || PrimPagePrev == -1) {
		llOwnerSay("Can't find page button(s)");
		return FALSE;
	}
	return TRUE;
}
SetCategory(string ObjectName, string NewCategory) {
	list Lines = llParseString2List(osGetNotecard(OBJECTS_LIST), [ "\n" ], []); // don't use KeepNulls - we want to lose the blank lines
	integer Len = llGetListLength(Lines);
	// First, get rid of current entry
	integer P = llListFindList(Lines, [ ObjectName ]);
	if (P > -1) Lines = llDeleteSubList(Lines, P, P);	// remove old entry
	if (NewCategory != "") {	// if there is a new category (otherwise, we're just deleting)
		// Find the new category
		P = llListFindList(Lines, [ "[" + NewCategory + "]" ]);
		if (P == -1) {
			llShout(0, "Category missing from list: '" + NewCategory + "'");
			return;
		}
		// Insert the object into the appropriate place
		integer InsertPoint = -1;
		integer Q;
		for (Q = P + 1; Q < Len; Q++) {
			if (InsertPoint == -1 && llGetSubString(llList2String(Lines, Q), 0, 0) == "[") {
				InsertPoint = Q;
			}
		}
		if (InsertPoint == -1) {	// if we're inserting into the last category
			Lines += ObjectName;	// we actually append the object
		}
		else {	// otherwise, we insert it before the subsequent category (ie at the end of the specified category)
			Lines = llListInsertList(Lines, [ ObjectName ], InsertPoint);
		}
	}
	// Add blank lines for readability, copying into write buffer
	NotecardToWrite = [];
	Len = llGetListLength(Lines);
	for (P = 0; P < Len; P++) {
		string Line = llList2String(Lines, P);
		if (llGetSubString(Line, 0, 0) == "[") NotecardToWrite += "";
		NotecardToWrite += Line;
	}
	NotecardToWrite += "";
	llRemoveInventory(OBJECTS_LIST); // will be written in the timer event
}
// Send LMs to category labels specifiying their texts
SetLabels() {
	integer N = llGetListLength(PrimCategories);
	integer I;
	for (I = 0; I < N; I += 2) {
		integer LinkNum = llList2Integer(PrimCategories, I);
		integer CategoryPointer = -llList2Integer(PrimCategories, I + 1);
		string CatName = llList2String(Categories, CategoryPointer);
		llMessageLinked(LinkNum, UI_LABEL_SET_TEXT, CatName, NULL_KEY);
	}
}
integer GetNotecard() {
	if (llGetInventoryType(OBJECTS_LIST) != INVENTORY_NOTECARD) {
		llOwnerSay("ERROR: Can't find notecard: '" + OBJECTS_LIST + "'");
		return FALSE;
	}
	Objects = [];
	Categories = [];
	string CatName = "";
	string N = osGetNotecard(OBJECTS_LIST);
	list L = llParseString2List(N, [ "\n" ], [ ]);
	integer Len = llGetListLength(L);
	integer I;
	for (I = 0; I < Len; I++) {
		string Line = llList2String(L, I);
		Line = llStringTrim(Line, STRING_TRIM);
		if (Line != "") {
			if (llGetSubString(Line, 0, 0) == "[" && llGetSubString(Line, -1, -1) == "]") {		// if it's a category entry
				CatName = llGetSubString(Line, 1, -2);
				Categories += CatName;
			}
			else {
				if (CatName == "") {
					llOwnerSay("ERROR: List item not in category: '" + Line + "'");
					return FALSE;
				}
				Objects += [ Line, CatName, NULL_KEY ];		// we don't know the texture key yet
			}
		}
	}
	ObjectsCount = llGetListLength(Objects);
	return TRUE;
}
// Read textures data
GetTextures() {
	TextureCount = llGetInventoryNumber(INVENTORY_TEXTURE);
	integer T;
	// First, we set all texture UUIDs to null
	integer O;
	for (O = 0; O < ObjectsCount; O += OBJ_STRIDE) {
		Objects = llListReplaceList(Objects, [ NULL_KEY ], O + OBJ_TEXTURE_ID, O + OBJ_TEXTURE_ID);
	}
	TextureUuids = [];	// this is a separate list for pre-rezzing - clear that too
	// Next, we cycle through the textures in inventory
	for(T = 0; T < TextureCount; T++) {
		string TextureName = llGetInventoryName(INVENTORY_TEXTURE, T);
		if (llGetSubString(TextureName, -1, -1) != SUFFIX_TEXTURE) {
			llOwnerSay("WARNING: texture lacks 'T' at end of name: '" + TextureName + "'");
			TextureName += SUFFIX_TEXTURE;
		}
		key Uuid = llGetInventoryKey(TextureName);
		string BaseName = llGetSubString(TextureName, 0, -2);
		TextureUuids += Uuid;		// add it into the pre-rezzing textures list
		// Check that an entry exists for this texture in the Objects list
		integer Ptr = llListFindList(Objects, [ BaseName ]);
		if (Ptr == -1) {
			llOwnerSay("WARNING: texture not in list: '" + TextureName + "'");
		}
		// Fill in UUID (may be referenced multiple times in objects list)
		for (O = 0; O < ObjectsCount; O += OBJ_STRIDE) {
			string ThisName = llList2String(Objects, O + OBJ_NAME);
			if (ThisName == BaseName) {
				Objects = llListReplaceList(Objects, [ Uuid ], O + OBJ_TEXTURE_ID, O + OBJ_TEXTURE_ID);	// Update UUID in list
			}
		}
	}
	TextureCount = llGetListLength(TextureUuids);
	// Next, we check that each object entry has had its UUID filled in above
	for (O = 0; O < ObjectsCount; O += OBJ_STRIDE) {
		string ThisName = llList2String(Objects, O + OBJ_NAME);
		key Uuid = llList2Key(Objects, O + OBJ_TEXTURE_ID);
		if (Uuid == NULL_KEY) {
			llOwnerSay("WARNING: object in list doesn't have a texture: '" + ThisName + "'");
		}
	}

}
PreRez() {
	list Params = [];
	integer S;
	for(S = 0; S < PRE_REZ_SIDE_COUNT; S++) {
		Params += [ PRIM_TEXTURE, llList2Integer(PRE_REZ_SIDES, S), llList2String(TextureUuids, PreRezPtr), <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0 ];
		if (++PreRezPtr == TextureCount) PreRezPtr = 0;
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
}
// Check permissions of inventory object, notecard, etc
integer IsFullPerm(string Name) {
	return (PermsCheck(Name, MASK_BASE) && PermsCheck(Name, MASK_OWNER) && PermsCheck(Name, MASK_NEXT));
}
integer PermsCheck(string Name, integer Mask) {
	integer Perms = llGetInventoryPermMask(Name, Mask);
	return (Perms & PERM_COPY && Perms & PERM_MODIFY && Perms & PERM_TRANSFER);
}
// Returns a list of all textures (including suffix)
list ListObjectsFull() {
	integer ObjectsCount = llGetInventoryNumber(INVENTORY_TEXTURE);
	list Objects = [];
	integer O;
	for (O = 0; O < ObjectsCount; O++) {
		string Name = llGetInventoryName(INVENTORY_TEXTURE, O);
		if (llGetSubString(Name, -1, -1) == SUFFIX_TEXTURE) {
			Objects += Name;
		}
	}
	return Objects;
}
// Returns a list of all textures
list ListTextures() {
	integer Count = llGetInventoryNumber(INVENTORY_TEXTURE);
	list Textures = [];
	integer T;
	for (T = 0; T < Count; T++) {
		string Name = llGetInventoryName(INVENTORY_TEXTURE, T);
		if (llGetSubString(Name, -1, -1) == SUFFIX_TEXTURE) {
			string BaseName = llGetSubString(Name, 0, -2);
			Textures += BaseName;
		}
	}
	return Textures;
}
// Return list of categories and objects in them
// Format is [ Cat1, Cat2, [...] ], "", [ Obj1, CatPtr1, Obj2, CatPtr2 [...]
list ListCategories() {
	list RetObjects = [];
	integer O;
	for (O = 0; O < ObjectsCount; O += OBJ_STRIDE) {
		string CatName = llList2String(Objects, O + OBJ_CATEGORY);
		string Object = llList2String(Objects, O + OBJ_NAME);
		integer Ptr = llListFindList(Categories, [ CatName ]);
		RetObjects += [ Object, Ptr ];
	}
	return Categories + "" + RetObjects;
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
// Wrapper for osMessageObject() that checks to see if control board exists
// Uses standard messaging protocol
MessageStandard(key Uuid, integer Command, list Params) {
	MessageObject(Uuid, llDumpList2String([ Command ] + Params, "|"));
}
// Wrapper for osMessageObject() that checks to see if control board exists
MessageObject(key Uuid, string Text) {
	if (ObjectExists(Uuid)) {
		osMessageObject(Uuid, Text);
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
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
default {
	on_rez(integer Start) { llResetScript(); }
	state_entry() {
		state Bootup;
	}
}
state Bootup {
	on_rez(integer Start) { llResetScript(); }
	state_entry() {
		if (!GetPrims()) return;
		if (!GetNotecard()) return;
		GetTextures();
		SetLabels();
		ThumbPageStart = 0;
		state Normal;
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llResetScript();
		if (Change & CHANGED_LINK) llResetScript();
	}
}
state Normal {
	on_rez(integer Start) { llResetScript(); }
	state_entry() {
		RegisteredId = NULL_KEY;
		OpenCategory(0); // default category is the first
		UpdateDue = -1;
		PreRezPtr = 0;
		UploadReady = FALSE;
		llSetTimerEvent(1.0);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_BOOTED) {
			OpenCategory(0); // default category is the first
		}
		else if (Number == LM_DELEGATED_CLICK) {
			if (Id == RegisteredId && Id != NULL_KEY) {		// only allow registered (logged in) av to use the thumbnails and categories, etc
				// It's a click on a prim that's been reported to us by the control board script in the root prim.
				// So if it's one that we deal with, we need to pick that up and process it.
				list L = llParseStringKeepNulls(String, [ "|" ], [ "" ]);
				string PrimName = llList2String(L, 0);
				integer LinkNum = (integer)llList2String(L, 1);
				// Check thumbnails
				integer P = llListFindList(PrimThumbnails, [ LinkNum ]);
				if (P > -1) {
					RegisteredId = Id;
					string Desc = llList2String(llGetLinkPrimitiveParams(LinkNum, [ PRIM_DESC ]), 0);
					list Parts = llCSV2List(Desc);
					string ObjectName = llList2String(Parts, 0);
					key Texture = llList2Key(Parts, 1);
					Select(ObjectName, Texture);
					return;
				}
				// Check category buttons
				P = llListFindList(PrimCategories, [ LinkNum ]);
				if (P > -1) {
					integer CategoryPointer = -llList2Integer(PrimCategories, P + 1);
					OpenCategory(CategoryPointer);
					return;
				}
				// Check page forward/back buttons
				if (LinkNum == PrimPagePrev && IsPrevThumbPage()) TurnPage(-1);
				else if (LinkNum == PrimPageNext && IsNextThumbPage()) TurnPage(1);
			}
		}
		else if (Number == LM_REGISTER_AV) {
			RegisteredId = Id;
		}
		else if (Number == LM_INTEGRITY_CHECK) {
			IconList = llParseStringKeepNulls(String, [ "|" ], []);
			RezzorId = Id;
			state IntegrityCheck;
		}
		else if (Number == UI_LABEL_REQUEST_TEXT) {
			// A button has requested its text
			integer LinkNum = Sender;
			integer P = llListFindList(PrimCategories, [ LinkNum ]);		// find child prim number in list of category button prims
			if (P > -1) {	// if it's one of them, process it
				integer CategoryPointer = -llList2Integer(PrimCategories, P + 1);
				string CatName = llList2String(Categories, CategoryPointer);
				llMessageLinked(LinkNum, UI_LABEL_SET_TEXT, CatName, NULL_KEY);	// send back its label
			}
		}
	}
	dataserver(key From, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		integer Command = llList2Integer(Parts, 0);
		if (Command == PI_UPDATE) {
			// It's a message from the updater
			UpdaterUuid = From;
			string Action = llList2String(Parts, 1);
			list Objects = llList2List(Parts, 2, -1);
			if (Action == "list") {
				osMessageObject(From, llDumpList2String("T" + ListTextures(), "|"));
				osMessageObject(From, llDumpList2String("A" + ListCategories(), "|"));
			}
			else if (Action == "download") {
				string Object = llList2String(Objects, 0);
				string ActionTexture = Object + SUFFIX_TEXTURE;
				if (llGetInventoryType(ActionTexture) == INVENTORY_TEXTURE) {
					llGiveInventory(From, ActionTexture);
				}
			}
			else if (Action == "delete") {
				string Object = llList2String(Objects, 0);
				string ActionTexture = Object + SUFFIX_TEXTURE;
				if (llGetInventoryType(ActionTexture) == INVENTORY_TEXTURE) {
					llRemoveInventory(ActionTexture);
				}
				SetCategory(Object, "");	// delete object from categories
				state Bootup;
			}
			else if (Action == "upload") {
				integer Len = llGetListLength(Objects);
				integer O;
				for (O = 0; O < Len; O++) {
					string Name = llList2String(Objects, O) + SUFFIX_TEXTURE;
					if (llGetInventoryType(Name) == INVENTORY_TEXTURE) llRemoveInventory(Name);
				}
				// Now tell updater they're clear to send the updated objects
				UploadReady = TRUE;
				llSetTimerEvent(1.5);
			}
			else if (Action == "categoryset") {
				// updater setting the category for an object
				string ObjectName = llList2String(Objects, 0);
				string NewCategory = llList2String(Objects, 1);
				SetCategory(ObjectName, NewCategory);
				return;
			}
			else if (Action == "categoryrename") {
				string OldCategory = llList2String(Objects, 0);
				string NewCategory = llList2String(Objects, 1);
				CategoryRename(OldCategory, NewCategory);
				return;
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
	}
	timer() {
		llRegionSay(PICKER_CHANNEL, (string)TextureCount);	// we're actually giving out the number of library objects

		// This next part is to do with the opensim bug whereby deleting a notecard and writing a new one occasionally results
		// in the original notecard remaining. This workround (currently unproven in June 2016) involves moving the writing
		// part of the operation into the timer so it's executed in a different sim frame than the deletion.
		// I'm optimistic that this works, but still not 100% sure  -- John
		if (NotecardToWrite != []) {
			osMakeNotecard(OBJECTS_LIST, NotecardToWrite);
			NotecardToWrite = [];
			state Bootup;
		}
		if (UploadReady) {
			UploadReady = FALSE;
			osMessageObject(UpdaterUuid, "");	// tell updater they can send us the new version of the texture
		}
		if (UpdateDue > 0) UpdateDue--;
		else if (UpdateDue == 0) {
			state Bootup;
		}
		PreRez();
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY && !UploadReady) {	// we ignore inventory change if it's us that's caused it during the upload
			// We use a timer so that if someone drops a lot of textures into this prim, it's only read in
			// when it's finished (ie when this event stops firing)
			UpdateDue = 2;
		}
		if (Change & CHANGED_LINK) state Bootup;
	}
}
state IntegrityCheck {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		// First, process list of icons we received from the control board
		list Errs = [];
		integer IC = llGetListLength(IconList);
		integer I;
		for (I = 0; I < IC; I++) {
			string IconName = llList2String(IconList, I);	// this is actually the basename, without the I suffix
			if (llListFindList(Objects, [ IconName ]) == -1) {
				Errs += IconName;
			}
		}
		if (Errs != []) {
			llOwnerSay("WARNING:\nIcons without picture/category:\n" + llDumpList2String(Errs, "\n"));
		}
		// Next, check objects against icons to detect any missing icons
		Errs = [];
		integer O;
		for (O = 0; O < ObjectsCount; O += OBJ_STRIDE) {
			string Name = llList2String(Objects, O + OBJ_NAME);
			if (llListFindList(IconList, [ Name ]) == -1) {
				Errs += Name;
			}
		}
		if (Errs != []) {
			llOwnerSay("WARNING:\nMissing icons for objects:\n" + llDumpList2String(Errs, "\n"));
		}
		IconList = [];	// clear to save memory
		// Now we check that all categories in the objects table have corresponding buttons
		Errs = [];
		string CurrentCat = "";
		for (O = 0; O < ObjectsCount; O += OBJ_STRIDE) {
			string CatName = llList2String(Objects, O + OBJ_CATEGORY);
			if (CatName != CurrentCat) {	// only do this once when category changes
				CurrentCat = CatName;
				if (llListFindList(PrimCategories, [ CatName ]) == -1)
					Errs += CatName;
			}
		}
		if (Errs != []) {
			llOwnerSay("WARNING:\nCategories without buttons:\n" + llDumpList2String(Errs, "\n"));
		}
		Errs = [];
		// Now we check the textures
		integer TC = llGetInventoryNumber(INVENTORY_TEXTURE);
		integer T;
		for (T = 0; T < TC; T++) {
			string Name = llGetInventoryName(INVENTORY_TEXTURE, T);
			if (llGetSubString(Name, -1, -1) == SUFFIX_TEXTURE) {
				if (!IsFullPerm(Name)) {
					Errs += Name;
				}
			}
			else {
				llOwnerSay("WARNING: Unknown texture in preview prim: " + Name);
			}
			if (Errs != []) {
				llOwnerSay("WARNING:\nTextures not full-perm:\n" + llDumpList2String(Errs, "\n"));
			}
		}
		osMessageObject(RezzorId, (string)RZ_INTEGRITY_CHECK);		// request list of objects from rezzor
		llSetTimerEvent(5.0);	// timeout in case rezzor doesn't respond
	}
	dataserver(key From, string Data) {
		if (From == RezzorId) {	// reply from rezzor, giving us a list of the objects
			llSetTimerEvent(0.0);
			list WorldObjects = llParseStringKeepNulls(Data, [ "|" ], []);
			// First, check that we have all those objects
			list Errs = [];
			integer WC = llGetListLength(WorldObjects);
			integer W;
			for (W = 0; W < WC; W++) {
				string Name = llList2String(WorldObjects, W);	// this is actually the basename, without the W suffix
				if (llListFindList(Objects, [ Name ]) == -1) {
					Errs += Name;
				}
			}
			if (Errs != []) {
				llOwnerSay("WARNING:\nWorld Objects in rezzor without picture/category:\n" + llDumpList2String(Errs, "\n"));
			}
			// Next, check that all our objects are in rezzor
			Errs = [];
			integer O;
			for (O = 0; O < ObjectsCount; O += OBJ_STRIDE) {
				string Name = llList2String(Objects, O + OBJ_NAME);
				if (llListFindList(WorldObjects, [ Name ]) == -1) {
					Errs += Name;
				}
			}
			if (Errs != []) {
				llOwnerSay("WARNING:\nObjects in list but not in rezzor:\n" + llDumpList2String(Errs, "\n"));
			}
			llOwnerSay("Integrity check complete");
			state Normal;
		}
		// All other incoming data
	}
	timer() {
		llOwnerSay("ERROR: no response from rezzor!");
		llSetTimerEvent(0.0);
		state Normal;
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
			MessageStandard(ArchiverId, ARCH_RESTORE_START, [ osGetNotecard(OBJECTS_LIST) ]);	// Request list of files, sending the objects list as we do so
		}
		else if (ArchiveAction == ARCHIVE_PURGE) {
			DeleteFiles(ListObjectsFull() + OBJECTS_LIST);
			TimerPurpose = TP_PURGED;
			llSetTimerEvent(0.5);
		}		
	}
	dataserver(key From, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		integer Command = llList2Integer(Parts, 0);
		list Params = [];
		if (llGetListLength(Parts) > 1) Params = llList2List(Parts, 1, -1);
		if (From == ArchiverId) {
			if (Command == ARCH_BACKUP_FILES) {
				// Archiver is ready to receive backup, so send the files
				GiveInventoryList(From, ArchiveFiles);
				ArchiveFiles = [];
				// Send confirmation that that's all the files, together with our copy of the objects list
				string ObjectsListString = "";
				if (llGetInventoryType(OBJECTS_LIST) == INVENTORY_NOTECARD)
					ObjectsListString = osGetNotecard(OBJECTS_LIST);
				MessageStandard(ArchiverId, ARCH_BACKUP_END, [ ObjectsListString ]);
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
				// The archiver sends us the merged objects list to write to notecard
				string UpdatedObjectList = llList2String(Params, 0);
				NotecardToWrite = llParseStringKeepNulls(UpdatedObjectList, [ "\n" ], []);
				if (llGetInventoryType(OBJECTS_LIST) == INVENTORY_NOTECARD)
					llRemoveInventory(OBJECTS_LIST);	// Remove old notecard
				// Write to notecard
				TimerPurpose = TP_NOTECARD;
				llSetTimerEvent(0.5);
			}			
		}
	}
	timer() {
		// Once more, we're using a timer to circumvent OpenSim glitches by forcing processes into another sim frame
		llSetTimerEvent(0.0);
		if (TimerPurpose == TP_FINISH) {
			state Bootup;
		}
		else if (TimerPurpose == TP_REQUEST) {
			MessageStandard(ArchiverId, ARCH_RESTORE_FILES, []);
		}
		else if (TimerPurpose == TP_PURGED) {
			osMakeNotecard(OBJECTS_LIST, llDumpList2String([
				"",
				"[Category 1]",
				"",
				"[Category 2]",
				"",
				"[Category 3]",
				"",
				"[Category 4]",
				"",
				"[Category 5]",
				"",
				"[Category 6]",
				"",
				"[Category 7]",
				"",
				"[Category 8]",
				"",
				"[Category 9]",
				"",
				"[Category 10]",
				"",
				"[Category 11]",
				"",
				"[Category 12]",
				""
				], "\n"));
			MessageStandard(ArchiverId, ARCH_PURGE, []);
			state Bootup;
		}
		else if (TimerPurpose == TP_NOTECARD) {
			osMakeNotecard(OBJECTS_LIST, NotecardToWrite);
			NotecardToWrite = [];
			state Bootup;			
		}
	}
}
// RezMela object picker v0.14