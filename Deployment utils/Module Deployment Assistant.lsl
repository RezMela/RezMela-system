// Module deployment assistant v1.0

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

// TODO: Allow modules with extra scripts/objects/etc

integer SCRIPT_PIN = -19318100; // PIN for modules
integer TRIGGER = -28193871;
integer CHILD_READY = -28193872;
integer GET_CONTENTS = -28193873;
integer MENU_CHANNEL = -19737984;
string LIBRARY_CONFIG = "!Library config";
string OBJECTS_CARD = "!Objects";
string TEMPLATE_MODULE = "~~Template module";
vector REZ_POSITION = <0.6, 0.0, 0.275>;
float REZ_GAP = 0.05;

integer MP_DO_NOT_DELETE 	= -818442500;

string ThisScriptName = "";
string ModuleName = "";
key ModuleId = NULL_KEY;
vector ModulePos;

// Create
integer NotecardNum;
integer NotecardsCount;
string NotecardName;
list NotecardContents;
list CurrentText = [];

key MenuUser = NULL_KEY;
integer MenuListener = 0;

SetText(list Text, integer Append) {
	if (Append) Text = CurrentText + Text;
	llSetText(llDumpList2String(Text, "\n"), <0.8, 0.8, 0.2> , 1.0);
	CurrentText = Text;
}
integer InventoryExists(integer Type, string Name) {
	return (llGetInventoryType(Name) == Type);
}
integer IsEmpty() {
	if (InventoryExists(INVENTORY_NOTECARD, LIBRARY_CONFIG)) return FALSE;
	if (InventoryExists(INVENTORY_NOTECARD, OBJECTS_CARD)) return FALSE;
	if (llGetInventoryNumber(INVENTORY_OBJECT) != 1) return FALSE;
	if (llGetInventoryNumber(INVENTORY_NOTECARD) > 0) return FALSE;
	return TRUE;
}
Clear() {
	list Deletes = [];
	integer Len = llGetInventoryNumber(INVENTORY_ALL);
	integer I;
	for (I = 0; I < Len; I++) {
		string Name = llGetInventoryName(INVENTORY_ALL, I);
		if (Name != TEMPLATE_MODULE && Name != ThisScriptName) {
			Deletes += Name;
		}
	}
	Len = llGetListLength(Deletes);
	for (I = 0; I < Len; I++) {
		string Name = llList2String(Deletes, I);
		llRemoveInventory(Name);
	}
}
integer GetNotecard() {
	if (NotecardNum == NotecardsCount) return FALSE;
	NotecardName = llGetInventoryName(INVENTORY_NOTECARD, NotecardNum);
	NotecardContents = llParseStringKeepNulls(osGetNotecard(NotecardName), [ "\n" ], []);
	llRemoveInventory(NotecardName);
	return TRUE;
}
// Strips out main part of name, appends tilde, today's date and "R" for "release"
string SetModuleName(string Name) {
	if (!IsModule(Name)) {
		SetText([ "Not a module!" ], FALSE);
		osForceBreakLink(2);
		llResetScript();
	}
	integer MainNameEnd = llSubStringIndex(Name, "~");
	if (MainNameEnd > -1) MainNameEnd--;	// whether "~" is found or not, should work
	string MainName = llGetSubString(Name, 0, MainNameEnd);
	string Date = llGetSubString(llGetTimestamp(), 0, 9);
	return MainName + "~" + Date + "R";
}
integer IsModule(string Name) {
	return (llGetSubString(Name, 0, 5) == "&Lib: ");
}
Say(key UserId, string Text) {
	string S = llGetObjectName();
	llSetObjectName("");
	llRegionSayTo(UserId, 0, "/me " + Text);
	llSetObjectName(S);
}
default {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		ThisScriptName = llGetScriptName();
		if (llGetNumberOfPrims() > 1) {	// we're part of a linkset
			if (llGetLinkNumber() == 1) { // we're root
				SetText([ "Linked prim(s) detected!", "Stopped" ], FALSE);
				state Hang;
			}
			else {
				state Child; // maybe we're in child mode (ie inside module)
			}
		}
		llSetRemoteScriptAccessPin(SCRIPT_PIN);
		llAllowInventoryDrop(TRUE);
		state Idle;
	}
}
state Idle {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		if (!IsEmpty()) {
			SetText([ "Items exists in contents!", "Stopped." ], FALSE);
			state Hang;
		}
		SetText([ "Ready", "-", "Drop module into contents" ], FALSE);
	}
	changed(integer Change) {
		if (Change & (CHANGED_INVENTORY | CHANGED_ALLOWED_DROP)) {
			SetText([ "Inspecting module ..." ], FALSE);
			// Find a module in our inventory
			integer Count;
			integer Len = llGetInventoryNumber(INVENTORY_OBJECT);
			integer P;
			for (P = 0; P < Len; P++) {
				string ObjectName = llGetInventoryName(INVENTORY_OBJECT, P);
				if (llGetSubString(ObjectName, 0, 5) == "&Lib: ") {
					ModuleName = ObjectName;
					Count++;
				}
			}
			if (Count > 1) {
				SetText([ "More than one module in inventory!", "Stopped." ], FALSE);
				state Hang;
			}
			if (Count == 1) state RezOldModule;
			// If we transfer this object, this event gets triggered for some reason when the
			// recipient rezzes their copy. So if there's no module, just restart this state.
			state Idle;
		}
	}
}
state RezOldModule {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		SetText([ "Rezzing old module ..." ], FALSE);
		llRezObject(ModuleName, llGetPos() + <0.0, 0.0, 0.5>, ZERO_VECTOR, ZERO_ROTATION, 0);
	}
	object_rez(key Id) {
		SetText([ "Linking old module ..." ], FALSE);
		llRemoveInventory(ModuleName); // we're finished with the old one in contents
		ModuleId = Id;
		osForceCreateLink(ModuleId, TRUE);
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) {
			if (llGetNumberOfPrims() == 2) {
				SetText([ "Checking old module ..." ], FALSE);
				llRemoteLoadScriptPin(ModuleId, ThisScriptName, SCRIPT_PIN, TRUE, 7);
				llSetTimerEvent(5.0);
			}
			else if (llGetNumberOfPrims() == 1) { // must have unlinked bad module
				osSetPrimitiveParams(ModuleId, [ PRIM_POSITION, llGetPos() + <0.0, 0.5, -0.2 + llFrand(0.8)> ]);
				SetText([ "Timeout waiting for module!", "Has pre-check been run?", "Stopped." ], FALSE);
				state Hang;
			}
		}
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Sender == 2 && Number == CHILD_READY) {
			llSetTimerEvent(0.0);
			state GetOldModuleContents;
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		osForceBreakLink(2);
	}
}
state GetOldModuleContents {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		SetText([ "Getting old module contents ..." ], FALSE);
		llMessageLinked(2, GET_CONTENTS, "", NULL_KEY);
		// Now wait for the same message back to confirm that the child instance has finished
		// sending the module contents to us.
		llSetTimerEvent(60.0);
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llSetTimerEvent(10.0);
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Sender == 2 && Number == GET_CONTENTS) {
			// Now we're finished with the old module. We can unlink it, and it will kill
			// itself when that happens
			llSetTimerEvent(0.0);
			osForceBreakLink(2);
			state CreateModule;
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		SetText([ "Timeout trying to get module contents!", "Stopped." ], FALSE);
		state Hang;
	}
}
state CreateModule {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		SetText([ "Creating new module ..." ], FALSE);
		llSetTimerEvent(0.0);
		llRezObject(TEMPLATE_MODULE, llGetPos() + <0.0, 0.0, 0.5>, ZERO_VECTOR, ZERO_ROTATION, 0);
	}
	object_rez(key Id) {
		ModuleId = Id;
		osForceCreateLink(ModuleId, TRUE);
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) {
			ModuleName = SetModuleName(ModuleName);
			state RecreateNotecards;
		}
	}
}
state RecreateNotecards {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		NotecardsCount = llGetInventoryNumber(INVENTORY_NOTECARD);
		NotecardNum = 0;
		if (!GetNotecard()) state Duplicate;
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			osMakeNotecard(NotecardName, NotecardContents);
			NotecardNum++;
			if (!GetNotecard()) state Duplicate;
		}
	}
}
state Duplicate {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		llSetLinkPrimitiveParamsFast(2, [ PRIM_NAME, "&Lib: Change_this", PRIM_DESC, "" ]);
		// Copy all non-script contents (apart from template module) to new module
		integer Count = llGetInventoryNumber(INVENTORY_ALL);
		integer P;
		for (P = 0; P < Count; P++) {
			string Name = llGetInventoryName(INVENTORY_ALL, P);
			integer NotScript = (llGetInventoryType(Name) != INVENTORY_SCRIPT);
			if (NotScript && Name != TEMPLATE_MODULE) {
				llGiveInventory(ModuleId, Name);
			}
		}
		// Scripts
		Count = llGetInventoryNumber(INVENTORY_SCRIPT);
		for (P = 0; P < Count; P++) {
			string ScriptName = llGetInventoryName(INVENTORY_SCRIPT, P);
			if (ScriptName != ThisScriptName) {
				llRemoteLoadScriptPin(ModuleId, ScriptName, SCRIPT_PIN, TRUE, 0);
			}
		}
		llSetLinkPrimitiveParamsFast(2, [ PRIM_NAME, ModuleName, PRIM_DESC, "Created by RezMela" ]);
		state FindPlace;
	}
}
state FindPlace {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		SetText([ "Positioning new module ..." ], FALSE);
		llSensor("", NULL_KEY, SCRIPTED, 2.0, PI);
	}
	sensor(integer Count) {
		ModulePos = llGetPos() + REZ_POSITION;	// default
		integer Found = FALSE;
		integer P;
		float Z = ModulePos.z;
		for (P = 0; P < Count; P++) {
			vector Pos = llDetectedPos(P);
			if (IsModule(llDetectedName(P)) &&
				llFabs(ModulePos.x - Pos.x) < 0.01 && llFabs(ModulePos.y - Pos.y) < 0.01) {
					Found = TRUE;
					if (Pos.z > Z) {
						Z = Pos.z;
					}
				}
		}
		if (Found) {
			ModulePos.z = Z + REZ_GAP;
		}
		state PositionDelete;
	}
	no_sensor() {
		ModulePos = llGetPos() + REZ_POSITION;
		state PositionDelete;
	}
}
state PositionDelete {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		ModulePos -= llGetPos(); // convert to local pos
		llSetLinkPrimitiveParamsFast(2, [ PRIM_POS_LOCAL, ModulePos ]);
		osForceBreakLink(2);
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) {
			Clear();
			llSay(0, "Finished! Module created:\n    " + ModuleName);
			state Idle;
		}
	}
}
state Child {
	// In this mode, we're assumed to be inside a module, and we wait for the command to send our
	// contents back to the main instance in the root prim
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		SetText([ "Ready to send" ], FALSE);
		llMessageLinked(1, CHILD_READY, "", NULL_KEY);
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Sender == 1 && Number == GET_CONTENTS) {
			SetText([ "Sending contents ..." ], FALSE);
			key RootId = llGetLinkKey(1);
			// Copy all non-script contents (apart from template module) to new module
			integer Count = llGetInventoryNumber(INVENTORY_ALL);
			integer P;
			for (P = 0; P < Count; P++) {
				string Name = llGetInventoryName(INVENTORY_ALL, P);
				integer NotScript = (llGetInventoryType(Name) != INVENTORY_SCRIPT);
				if (NotScript && Name != TEMPLATE_MODULE) {
					llGiveInventory(RootId, Name);
				}
			}
			// Scripts (except for this script and librarian)
			Count = llGetInventoryNumber(INVENTORY_SCRIPT);
			for (P = 0; P < Count; P++) {
				string ScriptName = llGetInventoryName(INVENTORY_SCRIPT, P);
				integer IsLibrarian = (llSubStringIndex(llToLower(ScriptName), "librarian") > -1);
				// We don't copy ourself, of course, and also we don't copy the librarian script because
				// the template module in the root prim should be pre-loaded with the latest librarian
				// with the correct creatorship and (no-mod) permissions
				if (ScriptName != ThisScriptName && !IsLibrarian) {
					llRemoteLoadScriptPin(RootId, ScriptName, SCRIPT_PIN, TRUE, 0);
				}
			}
			SetText([ "Done" ], FALSE);
			llMessageLinked(1, GET_CONTENTS, "", NULL_KEY); // Send confirmation that we've finished
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) {
			if (llGetNumberOfPrims() == 1) {
				// When the main instance has received its stuff, it will unlink this prim. We need to die.
				llDie();
			}
			else {
				llShout(0, "Unexpected changed link detected in " + ThisScriptName);
				state Hang;
			}
		}
	}
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		SetText([ "-", "Click to restart" ], TRUE);
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			// if they've dropped object(s) in the contents, delete them
			list Deletes = [];
			integer Count = llGetInventoryNumber(INVENTORY_OBJECT);
			if (Count > 1) {
				integer I;
				for (I = 0; I < Count; I++) {
					string Name = llGetInventoryName(INVENTORY_OBJECT, I);
					if (Name != TEMPLATE_MODULE) {
						Deletes += Name;
					}
				}
				Count = llGetListLength(Deletes);
				for (I = 0; I < Count; I++) {
					string Name = llGetInventoryName(INVENTORY_OBJECT, I);
					llRemoveInventory(Name);
				}
				SetText([ "Removed object(s): " + llList2CSV(Deletes) ], FALSE);
				state ReHang;
			}
		}
	}
	touch_start(integer Count) { llResetScript(); }
}
state ReHang {
	on_rez(integer Param) { llResetScript(); }
	state_entry() { state Hang; }
}
// Module deployment assistant v1.0