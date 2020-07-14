
list Keys;
integer KeysCount = 0;
integer Which = 0;

ShowTexture() {
	llSetTexture(llList2String(Keys, Which), 4);
}
Blank() {
	llSetTexture(TEXTURE_BLANK, ALL_SIDES);
}
default {
	on_rez(integer param) {
		Blank();
	}
	attach(key at) {
		Blank();
	}
	state_entry() {
		Blank();
		Keys = [];
		KeysCount = 0;
	}
	touch_start(integer n) {
		vector ST = llDetectedTouchST(0);
		if (ST.x < 0.5) Which--; else Which++;
		if (Which < 0) Which = KeysCount - 1;
		else if (Which == KeysCount) Which = 0;
		ShowTexture();
	}
	dataserver(key id, string data) {
		Keys = llCSV2List(data);
		KeysCount = llGetListLength(Keys);
		llOwnerSay("Received " + (string)KeysCount + " textures");
		Which = 0;
		ShowTexture();
	}
	changed(integer change) {
		if (change & (CHANGED_REGION | CHANGED_REGION_START)) Blank();
	}
}