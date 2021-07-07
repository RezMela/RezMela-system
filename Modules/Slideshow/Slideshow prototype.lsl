

integer CurrentSlide = 0;
integer LastSlide = 0;

Display() {
	llSetTexture(llGetInventoryName(INVENTORY_TEXTURE, CurrentSlide), 1);
	if (CurrentSlide > 0) {
		llSetLinkTexture(osGetLinkNumber("pre1"), llGetInventoryName(INVENTORY_TEXTURE, CurrentSlide - 1), 1);
	}
	if (CurrentSlide < LastSlide) {
		llSetLinkTexture(osGetLinkNumber("pre2"), llGetInventoryName(INVENTORY_TEXTURE, CurrentSlide + 1), 1);
	}
}

default {
	on_rez(integer Param) {
		llResetScript();
	}
	state_entry() {
		CurrentSlide = 0;
		LastSlide = llGetInventoryNumber(INVENTORY_TEXTURE) - 1;
		llSetLinkTexture(osGetLinkNumber("pre3"), llGetInventoryName(INVENTORY_TEXTURE, 0), 1);
		llSetLinkTexture(osGetLinkNumber("pre4"), llGetInventoryName(INVENTORY_TEXTURE, LastSlide), 1);
		Display();
	}
	touch_start(integer Count) {
		string PrimName = llGetLinkName(llDetectedLinkNumber(0));
		if (PrimName == "begin") {
			CurrentSlide = 0;
			Display();
		}
		else if (PrimName == "end") {
			CurrentSlide = LastSlide;
			Display();
		}
		else if (PrimName == "prev") {
			CurrentSlide--;
			if (CurrentSlide < 0) CurrentSlide = 0;
			Display();

		}
		else if (PrimName == "next") {
			CurrentSlide++;
			if (CurrentSlide > LastSlide) CurrentSlide = LastSlide;
			Display();
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llResetScript();
	}
}