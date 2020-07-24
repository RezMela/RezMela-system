// Give HUD v0.1
default {
	touch_start(integer Count) {
		while(Count--) {
			llGiveInventory(llDetectedKey(Count), llGetInventoryName(INVENTORY_OBJECT, 0));
		}
	}
}
// Give HUD v0.1