// Recreate notecards v1.0

// Drop notecards in and they will be replaced by identical versions created by object owner

key AvId;
integer NotecardNum;
integer NotecardsCount;
string NotecardName;
list NotecardContents;
SetText(string Text) {
	llSetText(Text, <1.0, 0.8, 0.0>, 1.0);
}
integer GetNotecard() {
	if (NotecardNum == NotecardsCount) return FALSE;
	NotecardName = llGetInventoryName(INVENTORY_NOTECARD, NotecardNum);
	NotecardContents = llParseStringKeepNulls(osGetNotecard(NotecardName), [ "\n" ], []);
	llRemoveInventory(NotecardName);
	return TRUE;
}
default {
	on_rez(integer param) { llResetScript(); }
	state_entry() {
		llAllowInventoryDrop(TRUE);
		state Idle;
	}
}
state Idle {
	on_rez(integer param) { llResetScript(); }
	state_entry() {
		AvId = NULL_KEY;
		SetText("Drop notecard(s) into contents");
	}
	changed(integer Change) {
		if (Change & (CHANGED_INVENTORY | CHANGED_ALLOWED_DROP)) {
			if (llGetInventoryNumber(INVENTORY_NOTECARD) > 0) {
				NotecardsCount = llGetInventoryNumber(INVENTORY_NOTECARD);
				SetText("Found " + (string)NotecardsCount + " notecards.\nClick to convert them.");
			}
			else {
				SetText("Drop notecard(s) into contents");
			}
		}
	}
	touch_start(integer Count) {
		if (llGetInventoryNumber(INVENTORY_NOTECARD) > 0) {
			AvId = llDetectedKey(0);
			state RecreateNotecards;
		}
	}
}
state RecreateNotecards {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		NotecardsCount = llGetInventoryNumber(INVENTORY_NOTECARD);
		SetText("Converting " + (string)NotecardsCount + " notecards ...");
		NotecardNum = 0;
		if (!GetNotecard()) state Finish;
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			osMakeNotecard(NotecardName, NotecardContents);
			NotecardNum++;
			if (!GetNotecard()) state Finish;
		}
	}
}
state Finish {
	on_rez(integer param) { llResetScript(); }
	state_entry() {
		list CardNames = [];
		integer I;
		for (I = 0; I < NotecardsCount; I++) {
			CardNames += llGetInventoryName(INVENTORY_NOTECARD, I);
		}
		string Timestamp = llGetTimestamp();
		string FolderName = llGetSubString(Timestamp, 0, 9) + " " + llGetSubString(Timestamp, 11, 18);
		llGiveInventoryList(AvId, "Converted notecards " + FolderName, CardNames);
		for (I = 0; I < NotecardsCount; I++) {
			llRemoveInventory(llGetInventoryName(INVENTORY_NOTECARD, 0));
		}
		state Idle;
	}
}