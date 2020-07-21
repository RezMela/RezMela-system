// Landmine v0.2

// Tweakable constants
float SENSOR_RANGE = 6.0;		// Detection radius for detonation
float SENSOR_FREQUENCY = 3.0;	// Period between sensor sweeps (seconds)
//
integer CHAT_CHANNEL = 29904047;
string ExplosionSound;			// sound for explosion (taken from inventory name)
string ExplosionTexture;		// Texture for explosion
list ExplosionParticleParams;	// params for llParticleSystem for explosion

list TargetIds;
list KnownObjects;
string DAMAGE_NOTECARD = "Remove this to reset";	// name of notecard created when damaged, removal of which resets to undamaged

integer NpcSearch;		// Boolean, switches between searching for NPCs and objects

default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		ExplosionSound = llGetInventoryName(INVENTORY_SOUND, 0);
		ExplosionTexture = llGetInventoryName(INVENTORY_TEXTURE, 0);
		ExplosionParticleParams = [
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
			PSYS_SRC_TEXTURE, ExplosionTexture,	// Explosion cloud texture
			PSYS_PART_START_ALPHA, 0.6,
			PSYS_PART_END_ALPHA, 0.0
				];
		state Arm;
	}
}
state Arm {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		// Scan for known object
		KnownObjects = [];
		llSensor("", NULL_KEY, SCRIPTED, SENSOR_RANGE, PI);
	}
	sensor(integer Count) {
		while(Count--) {
			key DetectedKey = llDetectedKey(Count);
			KnownObjects += DetectedKey;
		}
		state Wait;
	}
	no_sensor()	{
		state Wait;
	}
}
state Wait {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		NpcSearch = FALSE;
		llSetTimerEvent(SENSOR_FREQUENCY);
	}
	timer() {
		// Toogle between searching for NPC and for object
		integer SearchType = OS_NPC;
		if (NpcSearch = !NpcSearch) SearchType = SCRIPTED;
		llSensor("", NULL_KEY, SearchType, SENSOR_RANGE, PI);
	}
	sensor(integer Count) {
		TargetIds = [];
		while(Count--) {
			key TargetId = llDetectedKey(Count);
			if (osIsNpc(TargetId)) {
				llOwnerSay("here");
				// If it's an NPC, add it to targets
				TargetIds += TargetId;
			}
			else {
				// if it's an object, check if it's a known one
				if (llListFindList(KnownObjects, [ TargetId ]) == -1) {		// if it's unknown
					// add it to targets
					TargetIds += TargetId;
				}
			}
		}
		if (llGetListLength(TargetIds)) state Detonate;
	}
}
state Detonate {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llTriggerSound(ExplosionSound, 1.0);
		llParticleSystem(ExplosionParticleParams);
		integer Count = llGetListLength(TargetIds);
		while(Count--) {
			key TargetId = llList2Key(TargetIds, Count);
			if (osIsNpc(TargetId)) {
				// for NPCs, we use the chat channel so that the attachments can pick up their owner's messages
				llRegionSay(CHAT_CHANNEL, "D" + (string)TargetId);		// announce that NPC has been hit - the NPC's weapon should detect this, disable the NPC
			}
			else {
				// for objects, we send a direct message
				osMessageObject(TargetId, "D" + (string)TargetId);
			}
		}
		llSetTimerEvent(2.0);
		if (llGetInventoryType(DAMAGE_NOTECARD) == INVENTORY_NONE)
			osMakeNotecard(DAMAGE_NOTECARD, "");
	}
	timer() {
		state Dead;
	}
}
state Dead {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llParticleSystem([]);	// remove particles so it doesn't "explode" when re-rezzed
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY && llGetInventoryType(DAMAGE_NOTECARD) != INVENTORY_NOTECARD) {	// if the damage notecard has been deleted
			llResetScript();
		}
	}
}
// Landmine v0.2