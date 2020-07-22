
float ForceToApply = 2000.0;
float TurnAngle = 0.1;
rotation rTurnLeft;
rotation rTurnRight;

float Buoyancy = 0.99;

float ForceCurrent;
rotation TurnCurrent;

integer Physical;

integer PrimCount;
integer buttonForward;
integer buttonBackward;
integer buttonLeft;
integer buttonRight;
integer buttonStop;
integer buttonStopTurn;

SetPhysics() {
	if (ForceCurrent != 0.0) {
		if (!Physical) {
			llSetStatus(STATUS_PHYSICS, TRUE);
			Physical = TRUE;
		}
	}
	else {
		if (Physical) {
			llSetStatus(STATUS_PHYSICS, FALSE);
			Physical = FALSE;
		}
	}
	llSetForce(<ForceCurrent, 0.0, 0.0>, TRUE);
}
default {
	state_entry() {
		llSetStatus(STATUS_DIE_AT_EDGE, TRUE);
		llSetBuoyancy(Buoyancy);
		llSetForce(ZERO_VECTOR, TRUE);
		llSetStatus(STATUS_PHYSICS, FALSE);
		PrimCount = llGetNumberOfPrims();
		integer I;
		for(I = 2; I <= PrimCount; I++) {
			string N = llToLower(llGetLinkName(I));
			if (N == "go") buttonForward = I;
			else if (N == "reverse") buttonBackward = I;
			else if (N == "right") buttonRight = I;
			else if (N == "left") buttonLeft = I;
			else if (N == "stopturn") buttonStopTurn = I;
			else if (N == "stop") buttonStop = I;
		}
		ForceCurrent = 0.0;
		TurnCurrent = ZERO_ROTATION;
		Physical = FALSE;
		rTurnLeft = llEuler2Rot(<0.0, 0.0, TurnAngle>);
		rTurnRight = llEuler2Rot(<0.0, 0.0, -TurnAngle>);
		llSetTimerEvent(0.5);
	}
	touch_start(integer n) {
		integer LinkNum = llDetectedLinkNumber(0);
		if (LinkNum == buttonStop) {
			ForceCurrent = 0.0;
			SetPhysics();
		}
		else if (LinkNum == buttonForward) {
			ForceCurrent = ForceToApply;
			SetPhysics();
		}
		else if (LinkNum == buttonBackward) {
			ForceCurrent = -ForceToApply;
			SetPhysics();
		}
		else if (LinkNum == buttonLeft) {
			TurnCurrent = rTurnLeft;
		}
		else if (LinkNum == buttonRight) {
			TurnCurrent = rTurnRight;
		}
		if (LinkNum == buttonStopTurn) {
			TurnCurrent = ZERO_ROTATION;
			SetPhysics();
		}
	}
	timer() {
		if (TurnCurrent != ZERO_ROTATION) {
			llSetRot(llGetRot() * TurnCurrent);
		}
	}
}