// Drop into module to generate !Objects notecard (crude!)

string CardName = "!Objects";

default {
	state_entry() {
		if (llGetInventoryType(CardName) == INVENTORY_NOTECARD) {
			llRemoveInventory(CardName);
			llOwnerSay("Old " + CardName + " removed");
		}
		llSetTimerEvent(0.2);
	}
	timer() {
		llSetTimerEvent(0.0);
		list lines = [ "[Example category]" ];
		integer len = llGetInventoryNumber(INVENTORY_OBJECT);
		integer i;
		for (i = 0; i < len; i++) {
			lines += llGetInventoryName(INVENTORY_OBJECT, i);
		}
		osMakeNotecard(CardName, lines);
		llOwnerSay(CardName + " created");
		llRemoveInventory(llGetScriptName());
	}
}