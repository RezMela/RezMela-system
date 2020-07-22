// Howitzer explosion v0.3

// v0.3 is identical to v0.2 except it sets itself non-temporary if manually rezzed (I kept forgetting)

// Place in a phantom, temporary prim inside the howitzer shell
// Include an explosion sound (name doesn't matter)


default {
	on_rez(integer Param) {
		if (Param) {
			string Texture = llGetInventoryName(INVENTORY_TEXTURE, 0);
			llParticleSystem([
				PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
				PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_INTERP_COLOR_MASK,
				PSYS_SRC_BURST_SPEED_MIN, 2.0,
				PSYS_SRC_BURST_SPEED_MAX, 3.0,
				PSYS_PART_START_SCALE, <1.0, 1.0, 0.0>,
				PSYS_PART_END_SCALE, <4.0, 4.0, 0.0>,
				PSYS_PART_MAX_AGE, 1.2,
				PSYS_SRC_MAX_AGE, 0.3,
				PSYS_SRC_BURST_RATE, 0.01,
				PSYS_SRC_BURST_PART_COUNT, 10,
				PSYS_SRC_TEXTURE, Texture,	// Explosion cloud texture
				PSYS_PART_START_ALPHA, 0.6,
				PSYS_PART_END_ALPHA, 0.0
				]);
			string Sound = llGetInventoryName(INVENTORY_SOUND, 0);
			llPlaySound(Sound, 1.0);
			llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE]);
			llSetStatus(STATUS_PHANTOM, TRUE);
			llSetTimerEvent(3.0);
		}
		else {
			llSetPrimitiveParams([PRIM_TEMP_ON_REZ, FALSE]);
		}
	}
	timer() {
		while(TRUE==TRUE) {
			llDie();
		}
	}
}
// Howitzer explosion v0.3