// Simple projectile v0.2

// We use a hollow sphere with twist of B: 180 E: 180 (ie a *convex* hollow), with the outer face transparent (only face 1 is visible)

float  BOUYANCY = 1.0;      // how buoyant is the bullet for physics
float  TIMEOUT  = 20.0;     // control timer to force bullet to die

key RezzingObjectUuid = NULL_KEY;

list ParticleParams;
list PreRezParams;

string DeathCry;
key OwnerKey;

SetParticles() {
	string BloodTexture = llGetInventoryName(INVENTORY_TEXTURE, 0);
	ParticleParams = [
		PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
		PSYS_SRC_MAX_AGE, 0.1,
		PSYS_PART_FLAGS,  PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_INTERP_COLOR_MASK | PSYS_PART_FOLLOW_VELOCITY_MASK,
		PSYS_PART_START_COLOR, <1.0, 1.0, 1.0>,
		PSYS_PART_END_COLOR,  <1.0, 1.0, 1.0>,
		PSYS_PART_START_SCALE, <0.4, 0.4, 0.0>,
		PSYS_PART_END_SCALE, <4.0, 4.0, 0.0>,
		PSYS_SRC_ACCEL, <0.0, 0.0, -4.0>,
		PSYS_SRC_BURST_RATE, 10.0,
		PSYS_SRC_BURST_PART_COUNT, 1,
		PSYS_PART_MAX_AGE, 1.0,
		PSYS_SRC_TEXTURE, BloodTexture,
		PSYS_PART_START_ALPHA, 1.0,
		PSYS_PART_END_ALPHA, 1.0
			] ;
	PreRezParams = [
		PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
		PSYS_PART_FLAGS, PSYS_PART_INTERP_COLOR_MASK,
		PSYS_PART_START_SCALE,  <0.032, 0.032, 0.0>,
		PSYS_PART_END_SCALE, <0.032, 0.032, 0.0>,
		PSYS_SRC_BURST_RATE, 5.0,
		PSYS_PART_MAX_AGE, 5.0,
		PSYS_SRC_BURST_PART_COUNT, 1,
		PSYS_SRC_TEXTURE, BloodTexture,
		PSYS_PART_START_ALPHA, 0.001,
		PSYS_PART_END_ALPHA, 0.0
			] ;
}
default {
	on_rez(integer Param) {
		if (Param == 0) {
			llSetTimerEvent(0.0);
			llSetStatus(STATUS_PHYSICS, FALSE);
			llSetPrimitiveParams([ PRIM_TEMP_ON_REZ, FALSE ]); // set bullet to be temp-on-rez to cleanup and not count against prim limits
			llParticleSystem([]);
			llSetAlpha(1.0, 1);
			llOwnerSay("Made non-physical - don't forget to set physical before taking");
			return;
		}
		// Time-critical initial processing
		RezzingObjectUuid = osGetRezzingObject();	// this has to be in on_rez according to http://opensimulator.org/wiki/OsGetRezzingObject
		if ( llGetStatus(STATUS_PHYSICS) == FALSE ) { // is the bullet a physics object?
			llSetStatus(STATUS_PHYSICS, TRUE); // if not, make it one
		}
		llSetStatus(STATUS_DIE_AT_EDGE, TRUE); // set bullet to die if it crosses a region edge
		llSetPrimitiveParams([PRIM_TEMP_ON_REZ,TRUE]); // set bullet to be temp-on-rez to cleanup and not count against prim limits
		llSetBuoyancy(BOUYANCY); // make bullet float so it flies
		// Less time-critical stuff (can happen anywhere in flight)
		SetParticles();
		llParticleSystem(PreRezParams);
		DeathCry = llGetInventoryName(INVENTORY_SOUND, 0);
		OwnerKey = llGetOwner();
		llSetTimerEvent(TIMEOUT); // start the timeout timer to try to force bullet to die too
	}
	collision_start(integer collisions) {
		if (RezzingObjectUuid != NULL_KEY) {	// if we've been rezzed by an object
			while(collisions--) {
				key Uuid = llDetectedKey(collisions); // get the key of what or who we hit
				if (Uuid != OwnerKey && llGetAgentSize(Uuid) != ZERO_VECTOR) {	// if it's an avatar and not the owner
					llParticleSystem(ParticleParams);						// blood splatter
					llTriggerSound(DeathCry, 1.0);
					osMessageObject(RezzingObjectUuid, "H" + (string)Uuid);
				}
			}
			state Die;
		}
	}
	land_collision_start( vector collisions) {
		if (RezzingObjectUuid != NULL_KEY) {
			state Die;
		}
	}
	changed(integer Change)	{
		if (Change & CHANGED_INVENTORY) llResetScript();
	}

}
state Die {
	state_entry() {
		llSetAlpha(0.0, 1);		// side 1 is the hollow of the sphere (side 0 is fully transparent)
		llSetTimerEvent(0.5);
	}
	timer() {
		while (TRUE == TRUE) {
			llDie();
		}
	}
}
// Simple projectile v0.2