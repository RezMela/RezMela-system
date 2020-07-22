// Howitzer shell v0.8

// Shell object must be set to physical

integer CHAT_CHANNEL = 29904047;
string PROJECTILE_SOUND = "projectile";		// Sound of projectile going through air (may be omitted)
string EXPLOSION_SOUND = "Explosion sound";		// sound for explosion

float BlastRadius;		// NPCs will be killed and buildings damaged inside this radius
float ArmingDistance;	// if the shell travels less than this (in m) it's a dud and doesn't explode
float Buoyancy;			// 0-1, where 0 is normal, 1 is completely buoyant

string ExplosionPrim;		// name of explosion prim (taken from inventory name)
string SmokeTexture;		// smoke trail texture (taken from inventory name)
vector StartPos;

integer Enabled = FALSE;	// TRUE if it's been rezzed from the gun (ie live ammo)

default {
	on_rez(integer Param)	{
		if (Param) {		// Param is non-zero when the shell is rezzed by the weapon using llRezObject()
			Enabled = TRUE;
			StartPos = llGetPos();
			SmokeTexture = llGetInventoryName(INVENTORY_TEXTURE, 0);
			// Leave smoke trail
			llParticleSystem([
				PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
				PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_INTERP_COLOR_MASK,
				PSYS_PART_MAX_AGE, 2.0,
				PSYS_PART_START_COLOR, <1.0, 1.0, 1.0>,
				PSYS_PART_END_COLOR, <0.5, 0.5, 0.5>,
				PSYS_PART_START_SCALE, <0.032, 0.032, 0.0>,
				PSYS_PART_END_SCALE, <1.0, 1.0, 0.0>,
				PSYS_SRC_BURST_RATE, 0.0,
				PSYS_SRC_BURST_PART_COUNT, 1,
				PSYS_SRC_TEXTURE, SmokeTexture,	// smoke texture (from Handy's Tools)
				PSYS_PART_START_ALPHA, 0.6,
				PSYS_PART_END_ALPHA, 0.0
					]) ;
			llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE]);		// make bullet temp-on-rez
			llSetStatus(STATUS_DIE_AT_EDGE, TRUE);				// die if bullet reaches the region edge
			ExplosionPrim = llGetInventoryName(INVENTORY_OBJECT, 0);
			if (llGetInventoryType(PROJECTILE_SOUND) == INVENTORY_SOUND)	// if the projectile sound exists
				llLoopSound(PROJECTILE_SOUND,1.0);		// whistling sound
			// set up defaults for tuning parameters
			BlastRadius = 20.0;
			ArmingDistance = 22.0;
			Buoyancy = 0.0;
			llSetTimerEvent(20.0);	// we're actually duplicating "temp on rez", just in case
		}
		else {
			// Make it easier for the bullet to be modified and taken back into inv by the developer (if this doesn't work, attach the bullet first and make non-physical)
			llOwnerSay("Shell rezzed manually, setting non-physical (remember to set physical before taking");
			llSetPrimitiveParams([PRIM_TEMP_ON_REZ, FALSE]);
			llSetStatus(STATUS_PHANTOM | STATUS_DIE_AT_EDGE | STATUS_PHYSICS, FALSE);
			llSetTimerEvent(0.0);
		}
	}
	dataserver(key Request, string Data) {
		// Handle message from weapon
		list Params = llCSV2List(Data);
		BlastRadius = llList2Float(Params, 0);
		ArmingDistance = llList2Float(Params, 1);
		Buoyancy = llList2Float(Params, 2);
		llSetBuoyancy(Buoyancy);
	}	
	collision_start(integer Count) {
		if (Enabled) state Explode;
	}
	land_collision_start(vector Pos) {
		if (Enabled) state Explode;
	}
	timer() 	{
		state Die;
	}
}
state Explode {
	state_entry() {
		// make prim small and invisible
		llSetStatus(STATUS_PHYSICS, FALSE);
		llSetScale(<0.02, 0.02, 0.02>);
		llSetAlpha(0.0, ALL_SIDES);
		llParticleSystem([]);
		float DistanceTravelled = llVecDist(StartPos, llGetPos());
		if (DistanceTravelled < ArmingDistance) state Die;		// it's a dud, so die without exploding
		// create explosion effect
		llStopSound();
		llTriggerSound(EXPLOSION_SOUND, 1.0);
		// Explosion sound is in explosion prim
		llRezObject(ExplosionPrim, llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 1);
		// search for nearby NPCs and damageable objects
		llSensor("", NULL_KEY, OS_NPC, BlastRadius, PI);
		llSensor("", NULL_KEY, SCRIPTED, BlastRadius, PI);
		llSetTimerEvent(5.0);
	}
	sensor(integer Count) {
		while(Count--) {
			key CollidedKey = llDetectedKey(Count);
			if (osIsNpc(CollidedKey)) {
				// for NPCs, we use the chat channel so that the attachments can pick up their owner's messages
				llRegionSay(CHAT_CHANNEL, "D" + (string)CollidedKey);		// announce that NPC has been hit - the NPC's weapon should detect this, disable the NPC
			}
			else {
				// for objects, we use osMessageObject to reduce the need for listeners
				osMessageObject(CollidedKey, "D" + (string)CollidedKey);
			}
		}
	}
	timer() {
		state Die;
	}

}
state Die {
	state_entry() {
		// llDie() sometimes doesn't work first time
		while(TRUE==TRUE) {
			llDie();
		}
	}
}
// Howitzer shell v0.8