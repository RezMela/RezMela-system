// Damage linked smoke (Handy's)
//
// Smoke emitter, triggered by Object Damage script
//
float SMOKE_SIZE = 1.0;

string Texture = "c2470052-f128-4a6f-afce-2cc5210eed88";    // Handy's Tools "Abune 6" smoke texture
list Particles;

SetParticles() {
	Particles = [
		PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
		PSYS_PART_MAX_AGE,2.0,
		PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_INTERP_COLOR_MASK,
		PSYS_PART_START_ALPHA, 0.5,
		PSYS_PART_END_ALPHA, 0.0,
		PSYS_PART_START_SCALE,  <SMOKE_SIZE, SMOKE_SIZE, 0.0>,
		PSYS_PART_END_SCALE, <4.0, 4.0, 0.0>,
		PSYS_PART_MAX_AGE, 5.0,
		PSYS_SRC_ACCEL, <0.0, 0.0, 0.6>,
		PSYS_SRC_BURST_PART_COUNT, 2,
		PSYS_SRC_BURST_RADIUS, 0.2,
		PSYS_SRC_BURST_RATE, 0.2,
		PSYS_SRC_BURST_SPEED_MIN, 0.1,
		PSYS_SRC_BURST_SPEED_MAX, 0.4,
		PSYS_SRC_ANGLE_BEGIN, 0.0,
		PSYS_SRC_ANGLE_END, 0.3,
		PSYS_SRC_TEXTURE, Texture
			];
}
default {
	state_entry() {
		SetParticles();
		llParticleSystem([]);
	}
	link_message(integer sender, integer num, string str, key id) {
		if (num == -18007420) {
			if (str == "1")
				llParticleSystem(Particles);
			else
				llParticleSystem([]);
		}
	}
}
// Damage linked smoke (Handy's)