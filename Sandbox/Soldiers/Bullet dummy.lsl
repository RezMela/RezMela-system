// Bullet dummy

MultiDie() { while(TRUE==TRUE) { llDie(); } }		// loop, deleting bullet, until dead
default {
	on_rez(integer Param)	{
		if (Param) {		// Param is non-zero when the bullet is rezzed by the weapon using llRezObject()
			llSetBuoyancy(1.0);		// prevent bullet from dropping to the ground - bullet travels perfectly straight
			llSetStatus(STATUS_PHANTOM, TRUE);				// phantom
			llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE]);		// make bullet temp-on-rez
			llSetStatus(STATUS_DIE_AT_EDGE, TRUE);				// die if bullet reaches the region edge
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
		MultiDie();
	}
	land_collision_start(vector Pos) {
		MultiDie();
	}
	timer() 	{
		MultiDie();
	}
}
// Bullet dummy