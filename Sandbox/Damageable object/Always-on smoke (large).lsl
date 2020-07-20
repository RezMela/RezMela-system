// Always-on smoke (large) v0.1


integer makehash(key id){   // this function is used to create a hash to test against the passed hash
	// 1. Take the first 4 letters from the key
	// 2. Convert them to an integer (via llBase64ToInteger)
	// 3. Return the integer
	integer num = llBase64ToInteger(llGetSubString((string)id,0,3));
	return num;
}
integer pseudo_random(string text, integer nonce, integer start, integer end)
{//(c)(cc-by) Strife Onizuka, http://creativecommons.org/licenses/by/2.5/
	return (integer)("0x"+llGetSubString(llMD5String(text, nonce), start, end));
}
string password;
integer pyroChannel;

particles_on() {
	llParticleSystem([
		PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
		PSYS_SRC_BURST_PART_COUNT,  2,
		PSYS_SRC_BURST_RATE,        0.2,
		PSYS_PART_MAX_AGE,          10.0,
		PSYS_SRC_BURST_RADIUS,      0.0,
		PSYS_SRC_ANGLE_BEGIN,       0.0,
		PSYS_SRC_ANGLE_END,         1.57,
		PSYS_SRC_BURST_SPEED_MIN,   0.2,
		PSYS_SRC_BURST_SPEED_MAX,   1.0,
		PSYS_SRC_TEXTURE,           "smoke",
		PSYS_PART_START_SCALE,      <2.0, 2.0, 2.0>,
		PSYS_PART_END_SCALE,        <4.0, 4.0, 4.0>,
        PSYS_PART_START_COLOR,      <0.4, 0.4, 0.4>,
        PSYS_PART_END_COLOR,        <0.6, 0.6, 0.6>,
		PSYS_PART_START_ALPHA,      0.800000,
		PSYS_PART_END_ALPHA,        0.000000,
		PSYS_SRC_ACCEL, <0.0, 0.0, 0.2>,		
		PSYS_PART_FLAGS,
		PSYS_PART_WIND_MASK |
		PSYS_PART_FOLLOW_VELOCITY_MASK |
		PSYS_PART_INTERP_COLOR_MASK |
		PSYS_PART_INTERP_SCALE_MASK
			]);
}

particles_off() {
	llParticleSystem([]);
}

default {

	state_entry(){
		particles_on();
	}
}
// Always-on smoke (large) v0.1