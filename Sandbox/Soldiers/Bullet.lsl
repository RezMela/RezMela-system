// Bullet processing

integer CHAT_CHANNEL = 29904047 ;		//

MultiDie() { while(TRUE==TRUE) { llDie(); } }		// loop, deleting bullet, until dead
default {
	on_rez(integer Param)	{
		if (Param) {		// Param is non-zero when the bullet is rezzed by the weapon using llRezObject()
			llSetBuoyancy(1.0);		// prevent bullet from dropping to the ground - bullet travels perfectly straight
			llSetStatus(STATUS_PHANTOM, TRUE);				// phantom
			llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE]);		// make bullet temp-on-rez
			llSetStatus(STATUS_DIE_AT_EDGE, TRUE);				// die if bullet reaches the region edge
			// Leave smoke trail
			llParticleSystem([
				PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_SRC_PATTERN_DROP | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_INTERP_COLOR_MASK,
				PSYS_PART_MAX_AGE, 2.0,
				PSYS_PART_START_COLOR, <1.0, 1.0, 1.0>,
				PSYS_PART_END_COLOR, <0.5, 0.5, 0.5>,
				PSYS_PART_START_SCALE, <0.032, 0.032, 0.0>,
				PSYS_PART_END_SCALE, <1.0, 1.0, 0.0>,
				PSYS_SRC_BURST_RATE, 0.0,
				PSYS_SRC_BURST_PART_COUNT, 1,
				PSYS_SRC_TEXTURE, "17fa9504-f5ea-4269-9994-d8dcd4494be3",	// smoke texture (from Handy's Tools)
				PSYS_PART_START_ALPHA, 0.6,
				PSYS_PART_END_ALPHA, 0.0
					]) ;
			llSetTimerEvent(10.0);	// Bullet will die if it hits something. In case it doesn't, die after 10 seconds anyway. Note that bullet should be temp-on-rez anyway and have die-at-edge set.
		}
		else {
			// Make it easier for the bullet to be modified and taken back into inv by the developer (if this doesn't work, attach the bullet first and make non-physical)
			llOwnerSay("Bullet rezzed manually, setting non-physical (remember to set physical before taking");
			llSetPrimitiveParams([PRIM_TEMP_ON_REZ, FALSE]);
			llSetStatus(STATUS_PHANTOM | STATUS_DIE_AT_EDGE | STATUS_PHYSICS, FALSE);
		}
	}
	collision_start(integer Count) {
		key CollidedKey = llDetectedKey(0);
		if (osIsNpc(CollidedKey)) {		// we hit an NPC (rather than a real av, or an object)
			llRegionSay(CHAT_CHANNEL, "D" + (string)CollidedKey);		// announce that NPC has been hit - the NPC's weapon should detect this, disable the NPC
		}
		MultiDie();
	}
	land_collision_start(vector Pos) {
		MultiDie();
	}
	timer() 	{
		MultiDie();
	}
}
// Bullet processing