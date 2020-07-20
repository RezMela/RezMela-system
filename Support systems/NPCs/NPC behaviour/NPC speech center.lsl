// NPC Speech center v0.1

float TIMER = 0.5;
float TIMER_EVENTS_TO_DIE = 20;

key ParentId = NULL_KEY;
key NpcId;
integer TimerEvents;
vector NpcPos;
vector PrevNpcPos;

MoveToNpc() {
	list NpcDetails = llGetObjectDetails(NpcId, [ OBJECT_POS ]);
	vector NpcPos = llList2Vector(NpcDetails, 0);
	NpcPos.z += 1.0;	// crudely position near mouth
	if (PrevNpcPos == ZERO_VECTOR || llVecDist(NpcPos, PrevNpcPos) > 2.0) {
		MoveTo(NpcPos);
		PrevNpcPos = NpcPos;
	}
}
MoveTo(vector NewPos) {
	list Params = [];
	integer Jumps = (integer)(llVecDist(llGetPos(), NewPos) / 10.0) + 1;
	while(Jumps--) {
		Params += [ PRIM_POSITION, NewPos ];
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
}
default {
	on_rez(integer Param) {
		llSetTimerEvent(0.0);
		if (Param) {	 // if rezzed procedurally
			llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);	// set invisible
			ParentId = osGetRezzingObject();
			osMessageObject(ParentId, "SCR");		// Speech Centre Ready
			llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEMP_ON_REZ, TRUE, PRIM_PHANTOM, TRUE ]);	// set to temp object, phantom
		}
	}
	dataserver(key SourceId, string Data) {
		if (SourceId == ParentId) {
			// Get data sent by behaviour script
			list Parts = llCSV2List(Data);
			NpcId = (key)llList2String(Parts, 0);
			string SoundId = llList2String(Parts, 1);
			float Volume = (float)llList2String(Parts, 2);
			PrevNpcPos = ZERO_VECTOR;
			// Move to NPC
			MoveToNpc();
			llPlaySound(SoundId, Volume);
			TimerEvents = 0;
			llSetTimerEvent(TIMER);
		}
	}
	timer() {
		MoveToNpc();
		if (TimerEvents++ > TIMER_EVENTS_TO_DIE) {
			llDie();
		}
		// Timer repeats in case this didn't work
	}
}
// NPC Speech center v0.1