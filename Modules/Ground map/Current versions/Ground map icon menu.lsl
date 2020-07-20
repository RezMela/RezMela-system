// Ground map icon menu v0.1

integer IC_MENU = 1021;

default {
	touch_start(integer Count) {
		llMessageLinked(LINK_SET, IC_MENU, "", llDetectedKey(0));
	}
}
// Ground map icon menu v0.1