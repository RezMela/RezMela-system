
default {
	touch_start(integer Count) {
		while(Count--) {
			key Id = llDetectedKey(Count);
			osForceAttachToOtherAvatarFromInventory(Id, llGetInventoryName(INVENTORY_OBJECT, 0), ATTACH_LEAR);
		}
	}
}