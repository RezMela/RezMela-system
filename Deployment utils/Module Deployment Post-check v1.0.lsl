// Module Deployment Post-check v1.0

// Drop into module as RezMela Apps

// DEEPSEMAPHORE CONFIDENTIAL
// __
//
//  [2018] - [2028] DEEPSEMAPHORE LLC
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of DEEPSEMAPHORE LLC and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to DEEPSEMAPHORE LLC
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from DEEPSEMAPHORE LLC. For more information, or requests for code inspection,
// or modification, contact support@rezmela.com

integer SCRIPT_PIN = -19318100; // PIN for modules
integer MLO_PIN = 8000; // PIN for MLOs (objects in modules)

string LIBRARY_CONFIG = "!Library config";
string OBJECTS_CARD = "!Objects";

string ThisObjectName;
string ThisScriptName;
string LibrarianName = "";
key OwnerId;

key ParentObject = NULL_KEY;
list ChildObjects = [];
integer ChildCount;
integer MLOErrors = FALSE;

integer CheckModule() {
	list ObjectDetails = llGetObjectDetails(llGetKey(), [ OBJECT_CREATOR, OBJECT_GROUP ]);
	key CreatorId = llList2Key(ObjectDetails, 0);
	//	key GroupId = llList2Key(ObjectDetails, 1);
	if (CreatorId != OwnerId) {
		Say("*** Module has not been created by " + llKey2Name(OwnerId));
		return FALSE;
	}
	//	if (GroupId != NULL_KEY) {
	//		Say("*** Module has group set");
	//		return FALSE;
	//	}
	list Bads = [];
	string Indent = "        ";
	if (CheckObjPerm(MASK_NEXT, PERM_TRANSFER)) Bads += Indent + "Module has transfer perms";
	if (CheckObjPerm(MASK_EVERYONE, PERM_COPY)) Bads += Indent + "Everyone can copy";
	if (CheckObjPerm(MASK_EVERYONE, PERM_MODIFY)) Bads += Indent + "Everyone can modify";
	if (CheckObjPerm(MASK_EVERYONE, PERM_TRANSFER)) Bads += Indent + "Everyone can transfer";
	if (CheckObjPerm(MASK_GROUP, PERM_COPY)) Bads += Indent + "Group can copy";
	if (CheckObjPerm(MASK_GROUP, PERM_MODIFY)) Bads += Indent + "Group can modify";
	if (CheckObjPerm(MASK_GROUP, PERM_TRANSFER)) Bads += Indent + "Group can transfer";
	if (Bads != []) {
		Say("*** Module prim has unwanted permissions!\n" + llDumpList2String(Bads, "\n"));
		return FALSE;
	}
	return TRUE;
}
integer CheckContents() {
	list Summary = [];
	integer Len;
	integer P;
	LibrarianName = "";
	// Check for existence of mandatory items
	if (!InventoryExists(INVENTORY_NOTECARD, LIBRARY_CONFIG)) {
		Summary += "! Missing library config card";
	}
	if (!InventoryExists(INVENTORY_NOTECARD, OBJECTS_CARD)) {
		Summary += "! Missing library config card";
	}
	// Find name of librarian
	Len = llGetInventoryNumber(INVENTORY_SCRIPT);
	for (P = 0; P < Len ; P++) {
		string ScriptName = llGetInventoryName(INVENTORY_SCRIPT, P);
		if (ScriptName != ThisScriptName) {
			integer IsLibrarian = (llSubStringIndex(llToLower(ScriptName), "librarian") > -1);
			if (IsLibrarian) {
				if (LibrarianName == "") {
					LibrarianName = ScriptName;
				}
				else {
					Summary += "! Duplicate librarian scripts?!";
				}
			}
		}
	}
	list ObjectsCard = [];
	if (InventoryExists(INVENTORY_NOTECARD, OBJECTS_CARD)) {
		list Lines = llParseStringKeepNulls(osGetNotecard(OBJECTS_CARD), [ "\n" ], []);
		ObjectsCard = [];
		Len = llGetListLength(Lines);
		for (P = 0; P < Len; P++) {
			string Line = llStringTrim(llList2String(Lines, P), STRING_TRIM);
			if (Line != "" && llGetSubString(Line, 0, 0) != "[") { // ignore blank lines and categories
				ObjectsCard += Line;
			}
		}
	}
	integer ObjectsCount = 0;
	list MissingCCards = [];
	list OrphanCCards = [];
	list ObjectsNotInCard = [];
	list CardObjectsMissing = [];
	list ExtraNotecards = [];
	list ExtraScripts = [];
	list Unknowns = [];
	Len = llGetInventoryNumber(INVENTORY_ALL);
	for (P = 0; P < Len; P++) {
		string Name = llGetInventoryName(INVENTORY_ALL, P);
		integer Type = llGetInventoryType(Name);
		if (Type == INVENTORY_OBJECT) {
			ObjectsCount++;
			if (llListFindList(ObjectsCard, [ Name ]) > -1) {
				if (!InventoryExists(INVENTORY_NOTECARD, Name + "C")) {
					MissingCCards += Name;
				}
			}
			else {
				ObjectsNotInCard += Name;
			}
		}
		else if (Type == INVENTORY_NOTECARD) {
			if (Name != LIBRARY_CONFIG && Name != OBJECTS_CARD) {
				string Suffix = llGetSubString(Name, -1, -1);
				if (Suffix == "C") {
					string ObjectName = llGetSubString(Name, 0, -2);
					if (!InventoryExists(INVENTORY_OBJECT, ObjectName)) {
						OrphanCCards += Name;
					}
				}
				else { // Suffix != "C"
					ExtraNotecards += Name;
				}
			}
		}
		else if (Type == INVENTORY_SCRIPT) {
			if (Name != ThisScriptName && Name != LibrarianName) {
				ExtraScripts += Name;
			}
		}
		else {
			Unknowns += Name;
		}
	}
	// Check that all objects listed in objects notecard exist
	Len = llGetListLength(ObjectsCard);
	for (P = 0; P < Len; P++) {
		string ObjectName = llList2String(ObjectsCard, P);
		if (!InventoryExists(INVENTORY_OBJECT, ObjectName)) {
			CardObjectsMissing += ObjectName;
		}
	}
	// Summarise
	if (ObjectsCount == 0) {
		Summary += "! No objects!";
	}
	else {
		Summary += "Objects: " + (string)ObjectsCount;
	}
	if (MissingCCards != []) Summary += ExceptionsList("! Missing 'C' card(s)", MissingCCards);
	if (OrphanCCards != []) Summary += ExceptionsList("! Orphan 'C' card(s)", OrphanCCards);
	if (ObjectsNotInCard != []) Summary += ExceptionsList("Object(s) not in \"!Objects\" card", ObjectsNotInCard);
	if (CardObjectsMissing != []) Summary += ExceptionsList("! Object(s) in \"!Objects\" card that don't exist", CardObjectsMissing);
	if (ExtraNotecards != []) Summary += ExceptionsList("Notecard(s) that are not 'C' cards", ExtraNotecards);
	if (ExtraScripts != []) Summary += ExceptionsList("Unrecognised script(s)", ExtraScripts);
	if (Unknowns != []) Summary += ExceptionsList("Unknown item(s)", Unknowns);
	Say("Summary: \n\n" + llDumpList2String(Summary, "\n\n"));
	integer Errors = FALSE;
	// Error lines begin with "*** ERROR"
	Len = llGetListLength(Summary);
	for (P = 0; P < Len; P++) {
		string Line = llList2String(Summary, P);
		if (llGetSubString(Line, 0, 8) == "*** ERROR") Errors = TRUE;
	}
	return (!Errors);
}
string ExceptionsList(string Text, list Exceptions) {
	if (llGetSubString(Text, 0, 0) == "!") Text = "*** ERROR: " + llGetSubString(Text, 1, -1);
	return Text + ":\n    " + llList2CSV(Exceptions);
}
integer CheckInvPerms() {
	integer Errors = FALSE;
	list PermsList = [];
	list ObjectsList = [];
	integer Len = llGetInventoryNumber(INVENTORY_OBJECT);
	integer P;
	for (P = 0; P < Len; P++) {
		string ObjectName = llGetInventoryName(INVENTORY_OBJECT, P);
		if (BadInvPerms(ObjectName)) {
			Errors = TRUE;
		}
		string Perms = "";
		if (CheckInvPerm(MASK_NEXT, ObjectName, PERM_COPY)) Perms += "C"; else Perms += "c";
		if (CheckInvPerm(MASK_NEXT, ObjectName, PERM_MODIFY)) Perms += "M"; else Perms += "m";
		if (CheckInvPerm(MASK_NEXT, ObjectName, PERM_TRANSFER)) Perms += "T"; else Perms += "t";
		if (llListFindList(PermsList, [ Perms ]) == -1) PermsList += Perms;
		ObjectsList += Perms + ": " + ObjectName;
	}
	if (llGetListLength(PermsList) == 1) {
		Say("All objects are " + llList2String(PermsList, 0));
	}
	else {
		Say("Object perms: \n" + llDumpList2String(ObjectsList, "\n"));
	}
	return (!Errors);
}
integer BadInvPerms(string Name) {
	list Bads = [];
	string Indent = "        ";
	if (CheckInvPerm(MASK_NEXT, Name, PERM_TRANSFER)) Bads += Indent + "Transferrable";
	if (CheckInvPerm(MASK_EVERYONE, Name, PERM_COPY)) Bads += Indent + "Everyone can copy";
	if (CheckInvPerm(MASK_EVERYONE, Name, PERM_MODIFY)) Bads += Indent + "Everyone can modify";
	if (CheckInvPerm(MASK_EVERYONE, Name, PERM_TRANSFER)) Bads += Indent + "Everyone can transfer";
	if (CheckInvPerm(MASK_GROUP, Name, PERM_COPY)) Bads += Indent + "Group can copy";
	if (CheckInvPerm(MASK_GROUP, Name, PERM_MODIFY)) Bads += Indent + "Group can modify";
	if (CheckInvPerm(MASK_GROUP, Name, PERM_TRANSFER)) Bads += Indent + "Group can transfer";
	if (Bads != []) {
		Say("*** " + Name + " has unwanted permissions!\n" + llDumpList2String(Bads, "\n"));
		return TRUE;
	}
	return FALSE;
}
integer CheckInvPerm(integer CheckMask, string Name, integer Perm) {
	integer Mask = llGetInventoryPermMask(Name, CheckMask) ;
	return (Mask & Perm);
}
integer CheckObjPerm(integer CheckMask, integer Perm) {
	integer Mask = llGetObjectPermMask(CheckMask);
	return (Mask & Perm);
}
integer InventoryExists(integer Type, string Name) {
	return (llGetInventoryType(Name) == Type);
}
integer IsModule(string Name) {
	return (llGetSubString(Name, 0, 5) == "&Lib: ");
}
SetColor(vector RGB) {
	llSetColor(RGB, ALL_SIDES);
	llSetColor(<1.0, 1.0, 1.0>, 1);
	llSetColor(<1.0, 1.0, 1.0>, 3);
}
Say(string Text) {
	string N = llGetObjectName();
	llSetObjectName("");
	llOwnerSay("/me     " + Text);
	llSetObjectName(N);
}
default {
	on_rez(integer Param) {
		llResetScript();
	}
	state_entry() {
		OwnerId = llGetOwner();
		ThisObjectName = llGetObjectName();
		ThisScriptName = llGetScriptName();
		ParentObject = osGetRezzingObject();
		if (ParentObject != NULL_KEY) {
			state CheckMLO;
		}
		if (!IsModule(ThisObjectName)) {
			Say("Not a module name: " + ThisObjectName);
			state Hang;
		}
		if (llGetNumberOfPrims() != 1) {
			Say("Module must be unlinked");
			state Hang;
		}
		Say("\n\n" + ThisObjectName + "\n");
		llSetRemoteScriptAccessPin(SCRIPT_PIN);
		if (CheckModule()) {
			if (CheckContents()) {
				if (CheckInvPerms()) {
					state CheckAllMLOs;
				}
				else {
					llOwnerSay("Inventory permission errors");
				}
			}
			else {
				llOwnerSay("Contents errors");
			}
		}
		else {
			llOwnerSay("Errors in module");
		}
		Say("Check halted");
		SetColor(<0.9, 0.0, 0.0>);
		llRemoveInventory(llGetScriptName());
	}
}
state CheckAllMLOs {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		MLOErrors = FALSE;
		vector RezPos = llGetPos() + <0.0, 0.0, 5.0>;
		ChildObjects = [];
		ChildCount = llGetInventoryNumber(INVENTORY_OBJECT);
		integer P;
		for (P = 0; P < ChildCount; P++) {
			string Name = llGetInventoryName(INVENTORY_OBJECT, P);
			llRezObject(Name, RezPos, ZERO_VECTOR, ZERO_ROTATION, 45);
		}
		llSetTimerEvent(10.0);
	}
	object_rez(key Id) {
		ChildObjects += Id;
		osSetPrimitiveParams(Id, [ PRIM_TEMP_ON_REZ, TRUE ]);
		llRemoteLoadScriptPin(Id, ThisScriptName, MLO_PIN, TRUE, 45);
		llSetTimerEvent(10.0);
	}
	dataserver(key From, string Data) {
		integer P = llListFindList(ChildObjects, [ From ]);
		if (P == -1) {
			llOwnerSay("*** Can't find child object!");
			return;
		}
		ChildObjects = llDeleteSubList(ChildObjects, P, P);
		if (Data == "1") MLOErrors = TRUE;
		if (ChildObjects == [] && --ChildCount == 0) state Finish;
		llSetTimerEvent(10.0);
	}
	timer() {
		llSetTimerEvent(0.0);
		integer Count = llGetListLength(ChildObjects);
		list Names = [];
		integer C;
		for (C = 0; C < Count; C++) {
			key Id = llList2Key(ChildObjects, C);
			string Name = llKey2Name(Id);
			if (Name == "") Name = "[" + (string)Id + "]";
			Names += "    " + Name;
		}
		Say("*** " + (string)Count + " objects could not be checked: \n" + llDumpList2String(Names, "\n"));
		MLOErrors = TRUE;
		state Finish;
	}
}
state Finish {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		if (MLOErrors) {
			Say("*** Errors in object(s)");
			SetColor(<0.9, 0.0, 0.0>);
			llRemoveInventory(llGetScriptName());
			return;
		}
		SetColor(<0.0, 0.5, 1.0>);
		Say("Done.");
		if (llGetSubString(ThisObjectName, -1, -1) != "C") {
			ThisObjectName += "C";
			llSetObjectName(ThisObjectName);
		}
		llRemoveInventory(llGetScriptName());
	}
}
state CheckMLO {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		MLOErrors = FALSE;
		list ObjectData = llGetObjectDetails(llGetKey(), [ OBJECT_GROUP, OBJECT_CREATOR ]);
		key GroupId = llList2Key(ObjectData, 0);
		key CreatorId = llList2Key(ObjectData, 1);
		string Creator = llKey2Name(CreatorId);
		if (Creator == "") Creator = "[" + (string)CreatorId + "]";
		//		if (GroupId != NULL_KEY) {
		//			string Group = llKey2Name(GroupId);
		//			if (Group == "") Group = "[" + (string)GroupId + "]";
		//			llOwnerSay("*** Group is set!");
		//			MLOErrors = TRUE;
		//		}
		integer P;
		integer Len = llGetInventoryNumber(INVENTORY_SCRIPT);
		for (P = 0; P < Len ; P++) {
			string ScriptName = llGetInventoryName(INVENTORY_SCRIPT, P);
			if (ScriptName != ThisScriptName) {
				if (CheckInvPerm(MASK_NEXT, ScriptName, PERM_TRANSFER)) {
					llOwnerSay("*** Transferrable script: " + ScriptName);
					MLOErrors = TRUE;
				}
				if (CheckInvPerm(MASK_NEXT, ScriptName, PERM_MODIFY)) {
					llOwnerSay("*** Modifiable script: " + ScriptName);
					MLOErrors = TRUE;
				}
			}
		}
		osMessageObject(ParentObject, (string)MLOErrors);
		llDie();
	}
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
	changed(integer Change) { llResetScript(); }
	touch_start(integer Count) { llResetScript(); }
}
// Module Deployment Post-check v1.0