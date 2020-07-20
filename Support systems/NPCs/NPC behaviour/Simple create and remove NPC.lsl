
key NpcId = NULL_KEY;

default {
	touch_start(integer c) {
		if (NpcId != NULL_KEY)
			osNpcRemove(NpcId) ;
		else
			NpcId = osNpcCreate("Control", "Test", llGetPos() + <3.0, 0.0, 1.0> + <llFrand(1.0), llFrand(1.0), 0.0>, llGetInventoryName(INVENTORY_NOTECARD, 0), OS_NPC_NOT_OWNED);
	}
}