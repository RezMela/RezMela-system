// Fire extinguisher water v0.1

// Note that object must be physical

integer MINIMUM_LIFETIME = 2;		// minimum lifetime in seconds, to avoid dying when colliding with rezzing object
integer BornTime;
integer IsActive = FALSE;

default {
	on_rez(integer Param) {
		if (Param) {
			BornTime = llGetUnixTime();
			llSetTimerEvent((float)Param);
			llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEMP_ON_REZ, TRUE ]);	// set to temp on rez
			llSetStatus(STATUS_DIE_AT_EDGE, TRUE);
			IsActive = TRUE;
		}
		else {
			llSetStatus(STATUS_PHYSICS, FALSE);
			llOwnerSay("Set to non-physical - remember to set physical before taking");
			llSetTimerEvent(0.0);
			IsActive = FALSE;
		}
	}
	collision_start(integer Count) {
		if (IsActive && llGetUnixTime() > BornTime + MINIMUM_LIFETIME) llDie();
	}
	timer() {
		llDie();
	}
}
// Fire extinguisher water v0.1