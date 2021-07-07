default {
	on_rez(integer Param) {
		llSetTextureAnim(
			ANIM_ON | SMOOTH | LOOP | PING_PONG,
			0,
			1, 1,
			-0.012,	0.012,
			0.006);
		if (Param == 10884726) llRemoveInventory(llGetScriptName());
	}
}