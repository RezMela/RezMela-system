
// Drop into object - will remove moveable prim script and itself
// Very crude script!

default {
	on_rez(integer s) { llResetScript(); }
	state_entry() {
		integer l = llGetInventoryNumber(INVENTORY_SCRIPT);
		integer i;
		for (i = 0; i < l; i++) {
			string n = llGetInventoryName(INVENTORY_SCRIPT, i);
			if (llGetSubString(llToLower(n), 0, 12) == "moveable prim" &&
				n != llGetScriptName()) {
				llRemoveInventory(n);
			}
		}
		llRemoveInventory(llGetScriptName());
	}
}