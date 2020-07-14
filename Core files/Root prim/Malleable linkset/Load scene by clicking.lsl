
string SCENE = "S1";    // Name of scene or blank to just clear

integer LM_EXECUTE_COMMAND = -405502;

default {
	touch_start(integer n) {
		llMessageLinked(LINK_ROOT, LM_EXECUTE_COMMAND, "clear", llDetectedKey(0));
		if (SCENE != "")
			llMessageLinked(LINK_ROOT, LM_EXECUTE_COMMAND, "creategroup " + SCENE, llDetectedKey(0));
	}
}