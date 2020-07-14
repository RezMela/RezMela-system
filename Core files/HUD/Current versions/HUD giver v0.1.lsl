// HUD giver v0.1
default {
	touch_start(integer Count) {
		key Av = (string)llDetectedKey(0);
		if (llGetInventoryNumber(INVENTORY_OBJECT) != 1) {
			llRegionSayTo(Av, 0, "Sorry, not set up properly - check that HUD is in contents");
			return;
		}
		string HUDObject = llGetInventoryName(INVENTORY_OBJECT, 0);
		osForceAttachToOtherAvatarFromInventory((string)Av, HUDObject, ATTACH_HUD_TOP_LEFT);
		llDialog(Av, "\n\nYou now have the RezMela HUD", [ "OK" ], -99999);	
	}
}
// HUD giver v0.1