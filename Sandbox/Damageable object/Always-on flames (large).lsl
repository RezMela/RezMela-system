// Always-on flames (large) v0.1
//
// Particle flames
//
float FLAME_SIZE = 2.2;
float EXPANSION_FACTOR = 2.2;	// how much the flames increase in size

string Texture = "9be56b03-4af8-4371-9a8f-32db1f7bb7c3";    // Handy's Tools "Abune 2" texture
list Particles;

SetParticles() {
	Particles = [
		PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
		PSYS_PART_MAX_AGE, 6.0,
		PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_INTERP_COLOR_MASK,
		PSYS_PART_START_ALPHA, 1.0,
		PSYS_PART_END_ALPHA, 0.0,
		PSYS_PART_START_SCALE,  <FLAME_SIZE, FLAME_SIZE, 0.0>,
		PSYS_PART_END_SCALE, <FLAME_SIZE * EXPANSION_FACTOR, FLAME_SIZE * EXPANSION_FACTOR, 0.0>,
		PSYS_PART_MAX_AGE, 2.5,
		PSYS_SRC_ACCEL, <0.0, 0.0, 0.2>,
		PSYS_SRC_BURST_PART_COUNT, 1,
		PSYS_SRC_BURST_RADIUS, 0.6,
		PSYS_SRC_BURST_RATE, 0.2,
		PSYS_SRC_BURST_SPEED_MIN, 0.3,
		PSYS_SRC_BURST_SPEED_MAX, 1.0,
		PSYS_SRC_ANGLE_BEGIN, 0.0,
		PSYS_SRC_ANGLE_END, 0.16,
		PSYS_SRC_TEXTURE, Texture
			];
}
default {
	on_rez(integer p) { llResetScript(); }
	state_entry() {
		SetParticles();
		llParticleSystem(Particles);
	}
}
// Always-on flames (large) v0.1