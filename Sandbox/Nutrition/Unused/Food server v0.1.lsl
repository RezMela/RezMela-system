// Food server v0.1

integer MALL_CHANNEL = -84403270;

default {
	state_entry()
	{
		state Normal;
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(1.0);
	}
	timer() {
		llRegionSay(MALL_CHANNEL, "FS");		// broadcast "FS" (Food Server)
	}
}
// Food server v0.1