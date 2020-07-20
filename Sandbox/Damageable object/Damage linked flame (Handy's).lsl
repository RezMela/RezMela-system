// Damage linked flame (Handy's)
//
// Particle flames, triggered by object damage script
//
float FLAME_SIZE = 1.0;

string Texture = "9be56b03-4af8-4371-9a8f-32db1f7bb7c3";    // Handy's Tools "Abune 2" texture
list Particles;

SetParticles() {
    Particles = [
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
        PSYS_PART_MAX_AGE,2.0,
        PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_INTERP_COLOR_MASK,
        PSYS_PART_START_ALPHA, 1.0,
        PSYS_PART_END_ALPHA, 0.0,
        PSYS_PART_START_SCALE,  <FLAME_SIZE, FLAME_SIZE, 0.0>,
        PSYS_PART_END_SCALE, <FLAME_SIZE * 1.3, FLAME_SIZE * 1.3, 0.0>,
        PSYS_PART_MAX_AGE, 1.5,
        PSYS_SRC_ACCEL, <0.0, 0.0, 0.1>,
        PSYS_SRC_BURST_PART_COUNT, 2,
        PSYS_SRC_BURST_RADIUS, 0.6,
        PSYS_SRC_BURST_RATE, 0.2,
        PSYS_SRC_BURST_SPEED_MIN, 0.2,
        PSYS_SRC_BURST_SPEED_MAX, 0.4,
        PSYS_SRC_ANGLE_BEGIN, 0.0,
        PSYS_SRC_ANGLE_END, 0.1,
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
// Damage linked flame (Handy's)