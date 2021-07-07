default {
	on_rez(integer Param) {
		llSetTextureAnim(
			ANIM_ON | SMOOTH | LOOP | PING_PONG,
			1,
			1, 1,
			-0.006,	0.006,
			0.002);
		if (Param == 10884726) llRemoveInventory(llGetScriptName());
	}
}