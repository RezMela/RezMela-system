
/// OUTDATED! Use "Updater" instead

// Object updater
// Will only work with one control board/rezzor
integer BOARD_CHANNEL = -56;
integer REZZOR_CHANNEL = -355210124;

float TIMER = 3.0;

integer OBJECT_PIN = 50200;
integer RZ_UPDATE = 2004;

key BoardId;
key RezzorId;
integer WoCount = 0;
integer IconCount = 0;
list WoQueue;
string WoQueueTop;
list IconQueue;
string IconQueueTop;
integer Listener;

integer CheckInv() {
	string Text;
	WoQueue = [];
	IconQueue = [];
	list Objects = [];
	integer ObjectCount = llGetInventoryNumber(INVENTORY_OBJECT);
	if (!ObjectCount) {
		llSetText("Empty.\nAdd icons/world objects, then\nclick to update", <1, 1, 0.3>, 1.0);
		return FALSE;
	}
	else {
		Objects = [];
		WoCount = 0;
		IconCount = 0;
		integer P;
		for (P = 0; P < ObjectCount; P++) {
			string Name = llGetInventoryName(INVENTORY_OBJECT, P);
			Text += "\n" + Name;
			if (IsIcon(Name)) {
				IconQueue += Name;
				IconCount++;
			}
			else {
				WoQueue += Name;
				WoCount++;
			}
		}
		Text = "World objects: " + (string)WoCount + "\nIcons: " + (string)IconCount + ":" + Text;
		llSetText(Text, <1, 0.2, 0.2>, 1.0);
		return TRUE;
	}
}
integer IsIcon(string Name) {
	return (llGetSubString(Name, -1, -1) != "P");
}
SetTops() {
	if (llGetListLength(WoQueue))
		WoQueueTop = llList2String(WoQueue, 0);
	else
		WoQueueTop = "";
	if (llGetListLength(IconQueue))
		IconQueueTop = llList2String(IconQueue, 0);
	else
		IconQueueTop = "";
}
RequestWoUpdate() {
	if (RezzorId == NULL_KEY) { llOwnerSay("Can't find rezzor!"); return; }
	if (WoCount) osMessageObject(RezzorId, (string)RZ_UPDATE + "|" + WoQueueTop);
}
RequestIconUpdate() {
	if (IconCount) llRegionSay(BOARD_CHANNEL, "::" + IconQueueTop);
}
default {
	state_entry() {
		llAllowInventoryDrop(TRUE);
		llSetTimerEvent(TIMER);
		RezzorId = NULL_KEY;
	}
	touch_start(integer Count) {
		if (!CheckInv()) {
			llOwnerSay("Nothing to update");
			return;
		}
		SetTops();
		RequestWoUpdate();
		RequestIconUpdate();
	}
	dataserver(key Id, string Data) {
		if (Data == "control ready") {
			BoardId = Id;
			llGiveInventory(BoardId, IconQueueTop);
			llOwnerSay(IconQueueTop + " sent to control board");
			llRemoveInventory(IconQueueTop);
			IconQueue = llDeleteSubList(IconQueue, 0, 0);
			IconCount--;
			SetTops();
			if (IconQueueTop != "") {
				RequestIconUpdate();
			}
		}
		else if (Data == "rezzor ready") {
			if (RezzorId != Id) {
				llOwnerSay("Rezzor ID mismatch!");
				return;
			}
			llGiveInventory(RezzorId, WoQueueTop);
			llOwnerSay(WoQueueTop + " sent to rezzor");
			llRemoveInventory(WoQueueTop);
			WoQueue = llDeleteSubList(WoQueue, 0, 0);
			WoCount--;
			SetTops();
			if (WoQueueTop != "") {
				RequestWoUpdate();
			}			
		}
	}
	timer() {
		if (CheckInv())
			Listener = llListen(REZZOR_CHANNEL, "", NULL_KEY, "");
		else
			llListenRemove(Listener);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == REZZOR_CHANNEL && Message == "rezzor") {
			RezzorId = Id;
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			llSetTimerEvent(TIMER);
		}
	}
}
// Object updater