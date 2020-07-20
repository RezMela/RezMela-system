
integer CAM_CONTROL = TRUE;

key UserId = NULL_KEY;
key NpcId = NULL_KEY;

integer Walking;
integer Turning;
integer WasWalking;

float TURN_DEGREES = 0.8;
rotation TurnRot;

Move() {
	if (Walking == 0 && WasWalking != 0) {	// stopped
		osNpcStopMoveToTarget(NpcId);
	}
	WasWalking = Walking;
	list Dets = llGetObjectDetails(NpcId, [ OBJECT_POS, OBJECT_ROT ]);
	vector Pos = llList2Vector(Dets, 0);
	rotation Rot = llList2Rot(Dets, 1);	// we get the rot each time in case the NPC is deflected by other forces
	if (Walking != 0) {
		vector Target = Pos + <4.0 * Walking, 0.0, 0.0> * Rot;
		osNpcMoveToTarget(NpcId, Target, OS_NPC_NO_FLY);
	}
	if (Turning != 0) {
		rotation NewRot;
		if (Turning > 0)
			NewRot = Rot / TurnRot;
		else
			NewRot = Rot * TurnRot;
		osNpcSetRot(NpcId, NewRot);
	}
}
StartCam() {
	llSetCameraParams([
		CAMERA_ACTIVE, TRUE,
		CAMERA_FOCUS_LAG, 2.0,
		CAMERA_POSITION_LAG, 2.0,
		CAMERA_FOCUS_LOCKED, TRUE,
		CAMERA_POSITION_LOCKED, TRUE
			]);
	UpdateCam();
}
UpdateCam() {
	if (CAM_CONTROL) {
		list Dets = llGetObjectDetails(NpcId, [ OBJECT_POS, OBJECT_ROT ]);
		vector Pos = llList2Vector(Dets, 0);
		rotation Rot = llList2Rot(Dets, 1);
		vector FocusPos = Pos + <2.0, 0.0, 0.0> * Rot;
		vector CameraPos = Pos + <-1.2, -0.8, 1.5> * Rot;
		llSetCameraParams([
			CAMERA_FOCUS, FocusPos,
			CAMERA_POSITION, CameraPos
				]);
	}
	else {
		llSetCameraParams([
			CAMERA_FOCUS, llGetPos() + <3.0, 0.0, 1.0>,
			CAMERA_POSITION, llGetPos() + <-10.0, 0.0, 15.0>
				]);
	}

}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		if (llAvatarOnSitTarget() != NULL_KEY) llUnSit(llAvatarOnSitTarget());
		UserId = NULL_KEY;
		NpcId = NULL_KEY;
		TurnRot = llEuler2Rot(<0.0, 0.0, TURN_DEGREES>);
		llSitTarget(<0.0, 0.0, 1.0>, ZERO_ROTATION);
		string Text = "";
		if (CAM_CONTROL) Text = "controlled"; else Text = "not controlled";
		llSetText("Camera is " + Text, <1,1,1>, 1);
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) {
			key NewUserId = llAvatarOnSitTarget();
			if (UserId == NULL_KEY && NewUserId != NULL_KEY) {		// sitting
				UserId = NewUserId;
				llRequestPermissions(UserId, PERMISSION_CONTROL_CAMERA | PERMISSION_TAKE_CONTROLS);
				llSensor("", NULL_KEY, OS_NPC, 500.0, PI) ;
				NpcId = osNpcCreate("Control", "Test", llGetPos() + <3.0, 0.0, 1.0> + <llFrand(1.0), llFrand(1.0), 0.0>, llGetInventoryName(INVENTORY_NOTECARD, 0), OS_NPC_NOT_OWNED);
			}
			else if (UserId != NULL_KEY && NewUserId == NULL_KEY) {		// standing up
				llSetCameraParams([ CAMERA_ACTIVE, FALSE ]);
				llReleaseControls();
				//llReleaseCamera();
				llSetTimerEvent(0.0);
				osNpcRemove(NpcId) ;
				llResetScript();	// sometimes gets stuck, this hack is to prevent that
			}
		}
	}
	run_time_permissions(integer Perms) {
		if (Perms & (PERMISSION_CONTROL_CAMERA | PERMISSION_TAKE_CONTROLS)) {
			// Ready to process now
			llSetTimerEvent(0.5);
			llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT, TRUE, FALSE);
			StartCam();
			WasWalking = 0;
		}
	}
	sensor(integer Count) {
		while(Count--) {
			key Detected = llDetectedKey(Count) ;
			if (Detected != NpcId) {
				llSay(0, "Removing " + llKey2Name(Detected)) ;
				osNpcRemove(Detected) ;
			}
		}
	}
	timer() {
		UpdateCam();
		Move();
	}
	control(key Id, integer Level, integer Edge) {
		integer Start = Level & Edge;
		integer End = ~Level & Edge;
		integer Held = Level & ~Edge;
		//integer Untouched = ~(Level | Edge);
		Walking = Turning = 0;
		if (Held & CONTROL_FWD & CONTROL_BACK) {	// just in case they jam both keys down
			Walking = 0;
		}
		else if (Held & CONTROL_FWD) {
			Walking = 1;
		}
		else if (Held & CONTROL_BACK) {
			Walking = -1;
		}
		if (Held & CONTROL_ROT_LEFT & CONTROL_ROT_RIGHT) {
			Turning = 0;
		}
		else if (Held & CONTROL_ROT_LEFT) {
			Turning = -1;
		}
		else if (Held & CONTROL_ROT_RIGHT) {
			Turning = 1;
		}
		if (Start) Move();		// react as soon as a key is pressed
	}
}