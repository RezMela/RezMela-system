// Test osNpcMoveToTarget()

float MIN_DISTANCE = 5.0;
float MAX_DISTANCE = 20.0;
vector Destination;
vector PrevDestination;
key NpcId;

float ErrorMax;
float ErrorTotal;
integer Count;

float Offset() {
	return (llFrand(MAX_DISTANCE  * 2.0) - MAX_DISTANCE);
}
vector GetNpcPos() {
	list NpcDetails = llGetObjectDetails(NpcId, [ OBJECT_POS ]);
	return llList2Vector(NpcDetails, 0);			
}
integer IsNpcWalking() {
	integer Info = llGetAgentInfo(NpcId);
	return (Info & AGENT_WALKING);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Destination = ZERO_VECTOR;
		ErrorMax = 0.0;
		ErrorTotal = 0.0;
		Count = 0;
		NpcId = osNpcCreate("osNpcMoveToTarget", "Test", llGetPos(), llGetInventoryName(INVENTORY_NOTECARD, 0), OS_NPC_NOT_OWNED);
		if (llGetNumberOfPrims() == 2) llSetTimerEvent(1.0);
	}
	timer() {
		if (!osIsNpc(NpcId)) {	// if NPC is removed
			llSetTimerEvent(0.0);	// just stop
		}
		if (Destination == ZERO_VECTOR) {
			Destination = llGetPos() + <Offset(), Offset(), 0.0>;
			vector LocalPos = Destination - llGetPos();
			llSetLinkPrimitiveParamsFast(2, [
				PRIM_POS_LOCAL, LocalPos,
				PRIM_POS_LOCAL, LocalPos,
				PRIM_POS_LOCAL, LocalPos,
				PRIM_POS_LOCAL, LocalPos
				]);
			osNpcMoveToTarget(NpcId, Destination, OS_NPC_NO_FLY);
		}
		else if (!IsNpcWalking()) {
			vector NpcPos = GetNpcPos();
			float Error = llVecDist(NpcPos, Destination);
			Count++;
			ErrorTotal += Error;
			if (Error > ErrorMax) ErrorMax = Error;
			Destination = ZERO_VECTOR;	// restart
		}
	}
	touch_start(integer C) {
		float Average = ErrorTotal / (float)Count;
		llOwnerSay("\nTrials: " + (string)Count + "\nAverage: " + (string)Average + "\nMax: " + (string)ErrorMax);
	}
}