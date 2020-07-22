// Howitzer damage flames v0.1
default {
	on_rez(integer start_param)	{
		llResetScript();	
	}
	state_entry() {
		llSetAlpha(0.0, ALL_SIDES);		// make invisible
		llSetTextureAnim (ANIM_ON | LOOP, ALL_SIDES, 4, 4, 0, 0, 16.0);
	}
	link_message(integer sender, integer num, string str, key id) {
		if (num == -18007420) {
			if ((integer)str)
				llSetAlpha(1.0, ALL_SIDES);
			else
				llSetAlpha(0.0, ALL_SIDES);
		}
	}
}
// Howitzer damage flames v0.1