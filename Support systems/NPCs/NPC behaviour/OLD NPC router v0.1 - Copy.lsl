// NPC router v0.1

float WAYPOINT_RADIUS = 2.0;
float TIMER_PERIOD = 0.5;
integer CHECK_PRIMS_TICKS = 20;		// How many timer events between checking linked prims

// NPC data
list Npcs;			// [ UUID, Next Waypoint ]
integer NPC_ID = 0;
integer NPC_NEXT_WAYNUM = 1;	// keep waynum and waypos adjacent for llListReplaceList
integer NPC_NEXT_WAYPOS = 2;
integer NPC_STRIDE = 3;
integer NpcsLength;

// NPC cards info
list Notecards;
integer NextCard;
integer CardsCount;
integer PrimCount;

// Waypoints
list Waypoints;		// Sorted
integer WAY_WAYNUM = 0;
integer WAY_LINKNUM = 1;		// negative for disambiguation in llListFindList
integer WAY_POS = 2;		// region coords
integer WAY_STRIDE = 3;
integer WaypointsLength;

integer NextCheckPrim;

BuildPrimTable() {
	vector RootPos = llGetPos();
	Waypoints = [];
	PrimCount = llGetNumberOfPrims();
	if (PrimCount > 1) {
		integer P;
		for(P = 1; P <= PrimCount; P++) {
			list L = llGetLinkPrimitiveParams(P, [ PRIM_DESC, PRIM_POS_LOCAL ]);
			integer WayNum = llList2Integer(L, 0);
			vector WayPos = llList2Vector(L, 1);
			if (P > 1) WayPos += RootPos;	// get region pos for child prims
			if (WayNum) Waypoints += [ WayNum, -P, WayPos ];
		}
		Waypoints = llListSort(Waypoints, WAY_STRIDE, TRUE);
	}
	WaypointsLength = llGetListLength(Waypoints);
}
GetCards() {
	Notecards = [];
	NextCard = 0;
	CardsCount = llGetInventoryNumber(INVENTORY_NOTECARD);
	integer C;
	for(C = 0; C < CardsCount; C++) {
		Notecards += llGetInventoryName(INVENTORY_NOTECARD, C);
	}
}
string GetNextCard() {
	string CardName = llList2String(Notecards, NextCard);
	if (++NextCard == CardsCount) NextCard = 0;
	return CardName;
}
ProcessNpcs() {
	integer N;
	for (N = 0; N < NpcsLength; N += NPC_STRIDE) {
		key NpcId = llList2Key(Npcs, N + NPC_ID);
		if (!osIsNpc(NpcId)) {
			// NPC has disappeared
			Npcs = llDeleteSubList(Npcs, N, N + NPC_STRIDE - 1);
			NpcsLength -= NPC_STRIDE;
			N = 0;		// crude recovery of for loop
		}
		vector NextWayPos = llList2Vector(Npcs, N + NPC_NEXT_WAYPOS);
		list NpcDetails = llGetObjectDetails(NpcId, [ OBJECT_POS ]);
		vector NpcPos = llList2Vector(NpcDetails, 0);
		// If NPC is closer to target position, send them to the next waypoint
		if (llVecDist(NpcPos, NextWayPos) <= WAYPOINT_RADIUS) {
			integer WayNum = llList2Integer(Npcs, N + NPC_NEXT_WAYNUM);
			integer NextWayNum = GetNextWayNum(WayNum);
			NextWayPos = GetWayPos(NextWayNum);
			//llOwnerSay("sending " + llKey2Name(NpcId) + " to #" + (string)NextWayNum + " at " + (string)NextWayPos);
			Npcs = llListReplaceList(Npcs, [ NextWayNum, NextWayPos ], N + NPC_NEXT_WAYNUM, N + NPC_NEXT_WAYPOS);
			osNpcMoveToTarget(NpcId, NextWayPos, OS_NPC_NO_FLY );
		}
	}
}
CreateNpc() {
	if (PrimCount < 2) {
		llOwnerSay("Only one waypoint - cannot create NPC");
		return;
	}
	vector Pos = llGetPos();
	key NpcId = osNpcCreate("P.", "Destrian", Pos , GetNextCard(), OS_NPC_NOT_OWNED);
	AddNpc(NpcId, 1, Pos);		// add with destination as this waypoint, so they will get automatically directed to next waypoint
}
AddNpc(key NpcId, integer NextWayNum, vector NextWayPos) {
	Npcs += [ NpcId, NextWayNum, NextWayPos ];		// -1 for unknown next waypoint
	NpcsLength += NPC_STRIDE;
}
RemoveNpcs() {
	integer N;
	for (N = 0; N < NpcsLength; N += NPC_STRIDE) {
		key NpcId = llList2Key(Npcs, N + NPC_ID);
		if (osIsNpc(NpcId)) {
			osNpcRemove(NpcId);
		}
	}
}
integer LinkNum2WayNum(integer LinkNum) {
	integer P = llListFindList(Waypoints, [ -LinkNum ]);
	if (P == -1) {
		llOwnerSay("Can't find waypoint for link number " + (string)LinkNum);
		return -1;
	}
	integer WayNum = llList2Integer(Waypoints, P - 1);
	return WayNum;
}
integer GetNextWayNum(integer WayNum) {
	integer P = llListFindList(Waypoints, [ WayNum ]);
	P -= WAY_WAYNUM;	// beginning of stride
	P = P + WAY_STRIDE;	// beginning of next stride
	if (P >= WaypointsLength) P = 0;		// wrap back to beginning
	return llList2Integer(Waypoints, P + WAY_WAYNUM);
}
vector GetWayPos(integer WayNum) {
	integer P = llListFindList(Waypoints, [ WayNum ]);
	P -= WAY_WAYNUM;	// beginning of stride
	vector WayPos = llList2Vector(Waypoints, P + WAY_POS);
	return WayPos;
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		state Bootup;
	}
}
state Bootup {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		BuildPrimTable();
		GetCards();
		state Normal;
	}
}
state Reboot {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		RemoveNpcs();
		state Bootup;
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {		
		llSetTimerEvent(TIMER_PERIOD);
		Npcs = [];
		NpcsLength = 0;
		NextCheckPrim = CHECK_PRIMS_TICKS;
		CreateNpc();
	}
	touch_start(integer Count) {
		state Reboot;
	}
	timer() {
		ProcessNpcs();
		if (!NextCheckPrim--) {
			BuildPrimTable();
			NextCheckPrim = CHECK_PRIMS_TICKS;
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) state Reboot;
		if (Change & CHANGED_LINK) state Reboot;
	}
}
// NPC router v0.1