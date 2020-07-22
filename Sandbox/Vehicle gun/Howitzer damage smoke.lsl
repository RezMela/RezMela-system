// Howitzer damage smoke v0.1
Particles() {
	llParticleSystem([
		PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
		PSYS_SRC_BURST_PART_COUNT,  5,
		PSYS_SRC_BURST_RATE,        0.600000,
		PSYS_PART_MAX_AGE,          15.000000,
		PSYS_SRC_BURST_RADIUS,      0.000000,
		PSYS_SRC_ANGLE_BEGIN,       0.000000,
		PSYS_SRC_ANGLE_END,         1.570796,
		PSYS_SRC_BURST_SPEED_MIN,   1.000000,
		PSYS_SRC_BURST_SPEED_MAX,   2.000000,
		PSYS_SRC_TEXTURE,           "3e2d6532-03ee-4248-89fb-72605360add5",
		PSYS_PART_END_SCALE,        <4.00000, 4.00000, 4.00000>,
		PSYS_PART_START_SCALE,      <2.00000, 2.00000, 2.00000>,
		PSYS_PART_END_COLOR,        <1.00000, 1.00000, 1.00000>,
		PSYS_PART_START_COLOR,      <0.70588, 0.70588, 0.70588>,
		PSYS_PART_END_ALPHA,        0.000000,
		PSYS_PART_START_ALPHA,      0.500000,
		PSYS_PART_FLAGS,
		PSYS_PART_WIND_MASK |
		PSYS_PART_FOLLOW_VELOCITY_MASK |
		PSYS_PART_INTERP_COLOR_MASK |
		PSYS_PART_INTERP_SCALE_MASK
			]);
}
default {
	state_entry(){
		llParticleSystem([]);
	}
	link_message(integer sender, integer num, string str, key id) {
		if (num == -18007420) {
			if ((integer)str)
				Particles();
			else
				llParticleSystem([]);
		}
	}
}
// Howitzer damage smoke v0.1