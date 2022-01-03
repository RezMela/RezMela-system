// ML reset button v1.0.1

integer COM_RESET = -8172620;    // for external reset (eg a "reset" button)

key AvId = NULL_KEY;
integer MenuChannel = 0;

default {
	on_rez(integer Param) { llResetScript(); }
	touch_start(integer N) {
		key TouchKey = llDetectedKey(0);
		if (TouchKey != llGetOwner()) return;
		MenuChannel = llFloor(-10000 - llFrand(-100000));
		AvId = TouchKey;
		llListen(MenuChannel, "", AvId, "");
		llDialog(AvId, "\nReset Composer?\n\nThis may cause issues if you have objects in a scene!", [ "RESET", "Cancel" ], MenuChannel);
	}
	listen(integer Channel, string Name, key Id, string Text) {
		if (Channel == MenuChannel && Id == AvId) {
			if (Text == "RESET") {
		        llOwnerSay("Resetting");
		        llMessageLinked(LINK_ROOT, COM_RESET, "", NULL_KEY);
				llDialog(AvId, "\nComposer has been reset.", [ "OK" ], -9999);
			}
		}
	}
}
// ML reset button v1.0.1