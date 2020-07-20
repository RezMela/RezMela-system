// Basic NPC rezzer
// Click to rez an NPC, long-click to make notecard

string NPC_NAME1 = "Joe";
string NPC_NAME2 = "Public";

key ClickAvId;
key MenuAvId;
key NpcId;

default {
	on_rez(integer start_param)    { llResetScript(); }
	state_entry()    {
		state Normal;
	}
}
state Normal {
	on_rez(integer start_param)    { llResetScript(); }
	state_entry()    {
		llListen(-1234, "", NULL_KEY, "");
		llSetTimerEvent(0.0);
	}
	// touch and timer processing combines to implement short- and long-click handling
	touch_start(integer Total)    {
		ClickAvId = llDetectedKey(0);
		llSetTimerEvent(1.2);    // timer value gives long-click delay
	}
	touch_end(integer Total) {
		if (ClickAvId != NULL_KEY) {
			// short click
			llSetTimerEvent(0.0);
			state RezNPCs;
		}
	}
	timer() {
		if (ClickAvId != NULL_KEY) {
			// long click
			llSetTimerEvent(0.0);
			llDialog(ClickAvId, "", [ "900", "1000", "1100" ], -1234);
			string Name = llKey2Name(ClickAvId);
			llRegionSayTo(ClickAvId, 0, "Copying " + Name);
			MenuAvId = ClickAvId;
			ClickAvId = NULL_KEY;
		}
	}
	listen(integer C, string N, key K, string Size) {
		if (C == -1234 && K == MenuAvId) {
			string Notecard = "B/" + NPC_NAME1 + " " + NPC_NAME2 + "/" + Size ;
			if (Size == "1000") Notecard += "/1";
			if (llGetInventoryType(Notecard) == INVENTORY_NOTECARD) llRemoveInventory(Notecard);
			osAgentSaveAppearance(MenuAvId, Notecard);
			llRegionSayTo(MenuAvId, 0, "Copied " + llKey2Name(MenuAvId) + " to create: " + Notecard);
			llGiveInventory(MenuAvId, Notecard);
			MenuAvId = NULL_KEY;
		}
	}
}
// Rez an NPC
state RezNPCs {
	on_rez(integer start_param)    { llResetScript(); }
	state_entry()    {
		vector Pos = llGetPos();
		string Notecard = llGetInventoryName(INVENTORY_NOTECARD, 0);        // get notecard name
		NpcId = osNpcCreate(NPC_NAME1, NPC_NAME2, Pos + <0.0, 0.0, 1.0>, Notecard);
		state Normal;
	}
}
// Basic NPC rezzer