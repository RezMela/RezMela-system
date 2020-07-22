
default {
	state_entry()	{
		state Reset;
	}
}
state Reset {
	state_entry()	{
		llSetTimerEvent(0.0);
		llSetPrimitiveParams([PRIM_TEMP_ON_REZ, FALSE]);
		llSetStatus(STATUS_PHANTOM | STATUS_DIE_AT_EDGE | STATUS_PHYSICS, FALSE);
		llOwnerSay("Reset at " + (string)llGetPos());
		vector Home = <127, 125, 23>;
		while(llVecDist(Home, llGetPos()) > 0.5) {
			llSetPos(Home);
		}
		llSetRot(ZERO_ROTATION);
		state Go;
	}
}
state Go {
	state_entry()	{
		llOwnerSay("Ready");
	}
	touch_start(integer T) {
		llSetStatus(STATUS_DIE_AT_EDGE, TRUE);				// die if bullet reaches the region edge
		llSetStatus(STATUS_PHYSICS, TRUE);
		llApplyImpulse(<0, 1, 3>, TRUE);
		llSetTimerEvent(0.5);
	}
	collision_start(integer Count) {
		state Reset;
	}
	land_collision_start(vector Pos) {
		state Reset;
	}
	timer() {
		vector Vel = llGetVel();
		rotation rVel = llEuler2Rot(Vel);
		llRotLookAt(rVel, 1.0, 1.0);
	}
}