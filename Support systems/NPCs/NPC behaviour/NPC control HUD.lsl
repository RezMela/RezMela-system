// NPC control HUD v0.2

float TURN_DEGREES = 0.8;	// turn by (degrees)

key UserId;
key NpcId;

integer CameraPerms;

integer CurrentlyWalkingBackwards;
integer CurrentTurn;
integer CurrentWalk;
rotation TurnRot;
rotation Rot180;
vector CurrentPos;
rotation CurrentRot;

integer WalkDirection;
integer WALK_NONE = 0;
integer WALK_FORWARDS = 1;
integer WALK_BACKWARDS = -1;

integer TurnDirection;
integer TURN_NONE = 0;
integer TURN_LEFT = -1;
integer TURN_RIGHT = 1;

ControlNpc() {
	//llOwnerSay("Walk: " + (string)WalkDirection + ", Turn: " + (string)TurnDirection);
	list Dets = llGetObjectDetails(NpcId, [ OBJECT_POS, OBJECT_ROT ]);
	CurrentPos = llList2Vector(Dets, 0);
	CurrentRot = llList2Rot(Dets, 1);	// we get the rot each time in case the NPC is deflected by other forces
	if (CurrentlyWalkingBackwards && WalkDirection != WALK_BACKWARDS) {	// we were walking backwards, but now we're not so turn forward again
		osNpcSetRot(NpcId, CurrentRot * Rot180);	// turn 180�
		CurrentlyWalkingBackwards = FALSE;
		return; 	// give rotation time to happen, so no more movements this iteration
	}
	else if (!CurrentlyWalkingBackwards && WalkDirection == WALK_BACKWARDS) {	// we've started walking backwards, so turn around
		osNpcSetRot(NpcId, CurrentRot * Rot180);	// turn 180�
		CurrentlyWalkingBackwards = TRUE;
		return; 	// give rotation time to happen, so no more movements this iteration
	}
	// Process turn first, then walk (because turning affects walk direction)
	if (TurnDirection != TURN_NONE) {
		rotation NewRot;
		if (TurnDirection == TURN_RIGHT) {
			NewRot = CurrentRot / TurnRot;
			if (CurrentTurn != TURN_RIGHT)
				osNpcPlayAnimation(NpcId, "turnright");	// if they've started to turn, start the animation
		}
		else {
			NewRot = CurrentRot * TurnRot;
			if (CurrentTurn != TURN_LEFT)
				osNpcPlayAnimation(NpcId, "turnleft");
		}
		osNpcSetRot(NpcId, NewRot);
	}
	else if (CurrentTurn != TURN_NONE) {	// they were turning, now they're not
		if (CurrentTurn == TURN_RIGHT) osNpcStopAnimation(NpcId, "turnright");	// stop turning animation
		else osNpcStopAnimation(NpcId, "turnleft");
	}
	CurrentTurn = TurnDirection;
	// Now process walking
	if (CurrentWalk == WALK_NONE && WalkDirection == WALK_FORWARDS) {	// if they've just started walking forwards
		// put the camera behind the NPC
		vector FocusPos = CurrentPos + <2.0, 0.0, 0.0> * CurrentRot;
		vector CameraPos = CurrentPos + <-1.2, 0.0, 1.5> * CurrentRot;
		if (CameraPerms) llSetCameraParams([
			CAMERA_ACTIVE, TRUE,
			CAMERA_FOCUS_LAG, 2.0,
			CAMERA_POSITION_LAG, 2.0,
			CAMERA_POSITION, CameraPos,
			CAMERA_POSITION_LOCKED, TRUE,
			CAMERA_FOCUS, FocusPos,
			CAMERA_FOCUS_LOCKED, TRUE
				]);
	}
	if (WalkDirection != WALK_NONE) {
		vector Target = CurrentPos + <4.0, 0.0, 0.0> * CurrentRot;
		osNpcMoveToTarget(NpcId, Target, OS_NPC_NO_FLY);
	}
	CurrentWalk = WalkDirection;
}
Stop() {
	osNpcStopMoveToTarget(NpcId);
	WalkDirection = WALK_NONE;
	TurnDirection = TURN_NONE;
	CurrentWalk = WALK_NONE;
	if (CurrentTurn == TURN_RIGHT) osNpcStopAnimation(NpcId, "turnright");
	else if (CurrentTurn == TURN_LEFT) osNpcStopAnimation(NpcId, "turnleft");
	CurrentTurn = TURN_NONE;
	if (CurrentlyWalkingBackwards)
		osNpcSetRot(NpcId, CurrentRot * Rot180);
	CurrentlyWalkingBackwards = FALSE;
}
Click(vector TouchPoint) {
	WalkDirection = WALK_NONE;
	TurnDirection = TURN_NONE;
	// X and Y have standard axes (0 to 1), origin bottom left
	float X = TouchPoint.x;
	float Y = TouchPoint.y;
	// Divide area diagonally both ways and test for each diagonal half, combined to get quarters
	integer BottomOrRight = (X > Y);
	integer BottomOrLeft = (X + Y < 1.0);
	integer Top = (!BottomOrRight && !BottomOrLeft);
	integer Bottom = (BottomOrRight && BottomOrLeft);
	integer Left = (BottomOrLeft && !BottomOrRight);
	integer Right = (!BottomOrLeft && BottomOrRight);
	if (Bottom)
		WalkDirection = WALK_BACKWARDS;
	else if (Top)
		WalkDirection = WALK_FORWARDS;
	else if (Left)
		TurnDirection = TURN_LEFT;
	else if (Right)
		TurnDirection = TURN_RIGHT;
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Rot180 = llEuler2Rot(<0.0, 0.0, 180.0> * DEG_TO_RAD);
		TurnRot = llEuler2Rot(<0.0, 0.0, TURN_DEGREES>);
		NpcId = NULL_KEY;
		UserId = llGetOwner();
		CameraPerms = FALSE;
		llSensorRepeat("", NULL_KEY, OS_NPC, 500.0, PI, 2.0) ;
		llRequestPermissions(UserId, PERMISSION_CONTROL_CAMERA);
	}
	touch_start(integer Count) {
		if (NpcId == NULL_KEY) {
			llOwnerSay("Can't find an NPC nearby");
			return;
		}
		vector TouchST = llDetectedTouchST(0);
		Click(TouchST);
		ControlNpc();	// respond immediately, then on a timer
		llSetTimerEvent(0.5);
	}
	touch_end(integer Count) {
		llSetTimerEvent(0.0);
		Stop();
	}
	run_time_permissions(integer Perms) {
		if (Perms & PERMISSION_CONTROL_CAMERA) {
			CameraPerms = TRUE;
		}
	}
	sensor(integer Count) {
		NpcId = llDetectedKey(0);
	}
	no_sensor()	{
		NpcId = NULL_KEY;
	}
	timer() {
		ControlNpc();
	}
	changed(integer Change) {
		if (Change & CHANGED_OWNER) UserId = llGetOwner();
	}
}
// NPC control HUD v0.2