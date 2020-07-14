// Melablocks water (no particles) v1.1.0

integer LM_LOADING_COMPLETE = -405530;

default {
	state_entry() {
		llParticleSystem([]);
		llSetTextureAnim(ANIM_ON | SMOOTH | LOOP, ALL_SIDES, 1, 1, 1.0, 1.0, 0.3);
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		if (Number == LM_LOADING_COMPLETE) llRemoveInventory(llGetScriptName());
	}
}