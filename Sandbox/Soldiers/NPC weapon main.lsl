// Weapon main
//
// Main AI and shooting code. Uses state changes to implement different behaviours.
//
//
//
// AI tuning

float DELAY_IDLE_MIN = 1.0;		// delay range for idle (equivalent to standing looking around between targets)
float DELAY_IDLE_MAX = 3.0;
float DELAY_AIM_MIN = 0.2;		// delay range for aiming (standing pointing gun but not firing yet)
float DELAY_AIM_MAX = 1.0;

float MAX_RANGE = 30.0;			// maximum range of weapon - NPC runs to get this close before firing
float RUN_DISTANCE = 20.0;		// the NPC will run this distance (m) maximum towards the target before rescanning (like blind, head-down running)
float RUN_MIN_TIME = 5.0;		// time range for running. NPC will stop whenever either run distance is reached or timer finishes, whichever happens first
float RUN_MAX_TIME = 10.0;		// note that NPC will not fire until the time is up, so it might be standing doing nothing if RUN_DISTANCE is too short or RUN_MAX_TIME too high (this could be improved)

// other constants
string BULLET = "Bullet";
string BULLET_DUMMY = "BulletDummy";
float BULLET_VELOCITY = 10.0;			// metres/second
vector WEAPON_OFFSET = <3.0, 0.0, 0.7>;		// where the bullet is rezzed relative to the avatar (+X is forward)

// Unique chat/LM channels
integer STOP_PROCESSING = 810332400; 	// LM command from secondary script to halt all processing (when we're dead)
integer NEAREST_TARGET = 810332401;		// LM command for query and return of nearest NPC (negative for outgoing request, positive for incoming data)
integer SCRIPT_READY = 810332402;		// LM message to say that seconday script is ready

string Anim_aim = "aim_r_bazooka";		// built-in aiming animation

key NpcId = NULL_KEY;		// the UUID of the NPC holding the weapon
key RezzerId = NULL_KEY;	// UUID of the rezzer that created our NPC
key TargetId = NULL_KEY;	// the UUID of the NPC we're targetting (or NULL_KEY for none)
vector TargetPos;			// position of target (absolute region coords)
rotation AngleToTarget;		// angle from us to target (absolute, ie relative to region origin)
vector MyPos;				// this NPC's position
key GunSoundId;				// the sound of the gun

// Stops avatar movement. Calls osNpcStopMoveToTarget() multiple times because it doesn't always seem to work at first.
StopMove() {
	integer P = 6;
	while(P--) osNpcStopMoveToTarget(NpcId);
}
// Entry state - one-off initial processing
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		NpcId = llGetOwner();	// get avatar UUID
		if (osIsNpc(NpcId)) state WaitSecondary ;		// only go to normal processing if we're owned (wielded) by an NPC
	}
}
// Wait until secondary script is ready for us
state WaitSecondary {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(10.0);
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == SCRIPT_READY) {
			GunSoundId = (key)Message;		// the UUID of the gunshot sound
			RezzerId = Id;				// the UUID of the rezzer that created this NPC
			state Idle;		// the secondary script has initialised and is ready to receive requests
		}
	}
	timer()	{
		llSetTimerEvent(0.0);
		llShout(0, "No response from secondary weapon script");
	}
}
// Idle state - a buffer state before the NPC starts looking for enemies
state Idle {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		StopMove();
		// reset targetting data
		TargetId = NULL_KEY;
		TargetPos = ZERO_VECTOR;
		AngleToTarget = ZERO_ROTATION;
		llSetTimerEvent(DELAY_IDLE_MIN + llFrand(DELAY_IDLE_MAX - DELAY_IDLE_MIN));		// random delay before search to reduce synchronicity and provide realism
	}
	timer() {
		state Search;
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == STOP_PROCESSING) state Dead; 	// we've been shot; terminate
	}
}
// Search state - acquires the nearest target
state Search {
	on_rez(integer Param) { llResetScript();	}
	state_entry() {
		llTriggerSound(GunSoundId, 0.001);	// silent gunshot to ensure sound is cached
		llMessageLinked(LINK_THIS, -NEAREST_TARGET, "", NULL_KEY);		// request nearest target data from secondary script (note -ve LM)
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == NEAREST_TARGET) {		// response from secondary script (note +ve LM)
			if (Id == NULL_KEY) {			// null ID indicates nothing there
				state TrackRezzer;
			}
			else {		// Message contains NPC UUID
				StopMove();		// just in case
				TargetId = Id;
				TargetPos = (vector)Message;
				MyPos = llGetPos();		// our position
				float Distance = llVecDist(MyPos, TargetPos);	// distance in m between us and potential target
				if (Distance < MAX_RANGE)	// if within range
					state Aim;				// aim and fire
				else
					state MoveCloser ;		// otherwise, get closer
			}
		}
		else if (Number == STOP_PROCESSING) {	// we've been shot; terminate
			state Dead;
		}
	}
}
// TrackRezzer - we don't have a target so run towards the rezzer
state TrackRezzer {
	on_rez(integer Param) { llResetScript();	}
	state_entry()	{
		MyPos = llGetPos();
		vector RezzerPos = llList2Vector(llGetObjectDetails(RezzerId, [ OBJECT_POS ]), 0);
		if (RezzerPos == ZERO_VECTOR) state Idle;		// looks like rezzer doesn't exist any more
		if (llVecDist(RezzerPos, MyPos) < 8.0) state Idle; 		// we're near enough
		RezzerPos.x += (llFrand(12.0) - 6.0);		// give them a random position to spread them out
		RezzerPos.y += (llFrand(12.0) - 6.0);		//llShout(0, "distance to " + (string)RezzerId + " is " + (string)llVecDist(RezzerPos, MyPos) + ", so going to rezzer at: " + (string)RezzerPos);
		osNpcMoveToTarget(NpcId, RezzerPos,  OS_NPC_NO_FLY | OS_NPC_RUNNING);
		llSetTimerEvent(4.0 + llFrand(6.0));
	}
	timer() {
		StopMove();
		state Idle;
	}
}
// MoveCloser when there's a target but they're out of range, we get closer to them
state MoveCloser {
	on_rez(integer Param) { llResetScript();	}
	state_entry()	{
		// Calculate point RUN_DISTANCE away, on the path towards TargetPos
		// This works by calculating the proportion that RUN_DISTANCE is of the total distance (eg 0.5
		// for halfway), then multiplying the target vector by that factor (relative to own position)
		vector MoveToPos = MyPos + (RUN_DISTANCE / llVecDist(TargetPos, MyPos)) * (TargetPos - MyPos);
		osNpcMoveToTarget(NpcId, MoveToPos,  OS_NPC_NO_FLY | OS_NPC_RUNNING);
		llSetTimerEvent(RUN_MIN_TIME + llFrand(RUN_MAX_TIME - RUN_MIN_TIME));	// run for a random time before searching again
	}
	timer() {
		StopMove();
		state Search;
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == STOP_PROCESSING) {	// we've been shot; terminate
			StopMove();
			state Dead;
		}
	}
}
state Aim {
	on_rez(integer Param) { llResetScript();	}
	state_entry()	{
		TargetPos = osNpcGetPos(TargetId);		// we already have a rough position, update this now
		if (TargetPos == ZERO_VECTOR) state Idle;	// the target must have disappeared
		osNpcPlayAnimation(NpcId, Anim_aim);	// Trigger aiming animation
		AngleToTarget = llRotBetween(<1.0, 0.0, 0.0>, llVecNorm(TargetPos - llGetPos()));	// Thanks to Chalice Yeo of SL for this (via SLUniverse)
		osNpcSetRot(NpcId, AngleToTarget);		// rotate NPC to face target
		llSetTimerEvent(DELAY_AIM_MIN + llFrand(DELAY_AIM_MAX - DELAY_AIM_MIN));	// random delay between NPC turning to face target and starting to fire
	}
	no_sensor() {
		// there is no target in range
		state TrackRezzer;
	}
	timer() {
		llSetTimerEvent(0.0);
		state Fire;
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == STOP_PROCESSING) {	// we've been shot; terminate
			StopMove();		// just in case
			osNpcStopAnimation(NpcId, Anim_aim);	// release aiming animation
			state Dead;
		}
	}
}
// MoveBack - when the NPCs get too close, it gets a little ridiculous, so this simulates backing off to give room to fire
state MoveBack {
	on_rez(integer Param) { llResetScript();	}
	state_entry() {
		TargetPos = osNpcGetPos(TargetId);		// we already have a rough position, update this now
		if (TargetPos == ZERO_VECTOR) state Idle;	// the target must have disappeared
		// move some way towards a point 10-30m away on each of X and Y axes
		float Xmove = 10.0 + llFrand(20.0);
		float Ymove = 10.0 + llFrand(20.0);
		// adjust the direction appropriately for the relative position of the target
		if (TargetPos.x > MyPos.x) Xmove = -Xmove;
		if (TargetPos.y > MyPos.y) Xmove = -Xmove;
		vector MoveToPos = MyPos;
		MoveToPos.x += Xmove;
		MoveToPos.y += Ymove;
		osNpcMoveToTarget(NpcId, MoveToPos,  OS_NPC_NO_FLY | OS_NPC_RUNNING);
		llSetTimerEvent(3.0 + llFrand(3.0));		// run for a random time 3-6 seconds)
	}
	timer() {
		StopMove();
		state Aim;
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == STOP_PROCESSING) {	// we've been shot; terminate
			StopMove();
			state Dead;
		}
	}
}
state Fire {
	on_rez(integer Param) { llResetScript();	}
	state_entry() {
		float DistanceToTarget = llVecDist(TargetPos, MyPos);	// distance to target in metres
		if (DistanceToTarget > 10.0) {	// if we're still a reasonable distance away,
			vector MoveToPos = MyPos + (3.0 / llVecDist(TargetPos, MyPos)) * (TargetPos - MyPos);
			osNpcMoveToTarget(NpcId, MoveToPos,  OS_NPC_NO_FLY);	// walk forward for a short distance, to try to get the NPC facing the right way when firing
			llSetTimerEvent(0.5);
		}
		else if (DistanceToTarget > 5.0) {		// if we're close, we shouldn't walk any closer, just fire
			llSetTimerEvent(0.1) ;
		}
		else {			// we're really too close for the firing to work, so move a random short distance away and re-aim
			state MoveBack;
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		TargetPos = osNpcGetPos(TargetId);
		vector MyPos = llGetPos();
		rotation MyRot = llGetRot();
		vector WeaponPos = MyPos + (WEAPON_OFFSET * MyRot);
		vector FireVector = llVecNorm(TargetPos - WeaponPos) * BULLET_VELOCITY;
		MyRot *= llEuler2Rot(<0, PI_BY_TWO, 0>); // now, straighten rotation for object we're about to rez
		llTriggerSound(GunSoundId, 1.0);	// sound gunshot
		llRezObject(BULLET, WeaponPos, FireVector, MyRot, 1);	// shoot the bullet
		llRezObject(BULLET_DUMMY, WeaponPos, FireVector, MyRot, 1);	// create dummy bullet and propel		
		StopMove();									// stop walking forward
		osNpcStopAnimation(NpcId, Anim_aim);		// stop aim animation
		state Idle; // return to waiting state
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == STOP_PROCESSING) {	// we've been shot; terminate
			StopMove();		// stop NPC from moving
			osNpcStopAnimation(NpcId, Anim_aim);	// release aiming animation
			state Dead;
		}
	}
}
// Dead state - the end of everything
state Dead {
	on_rez(integer Param) { llResetScript();	}
	state_entry()
	{
		StopMove();			// just in case
		llSetTimerEvent(0.0);
	}
}
// Weapon main