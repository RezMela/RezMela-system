// Nutrition race v.02

// Name of finish line object
string FINISH_LINE_NAME = "Finish line";

// Starting lineup configuration
float LINEUP_MARGIN = 0.5;			// margin on left side of start line prim
float LINEUP_GAP = 2.0;				// gap between runners on lineup
float LINEUP_PROXIMITY = 2.0;		// how close runners should get before they're in position

// Chat channel
integer MALL_CHANNEL = -84403270;

// Parallel lists
list Racers;			// IDs of racers
list RacerPositions;	// start positions of racers
integer RacersCount;	// list length of above

integer CountdownCounter;	// 3-2-1 counter
string Gunshot;				// gunshot sound name (from inventory)
key FinishId;				// UUID of finish line
vector FinishPos;			// Position of finish line
string CrouchAnimation;		// crouch animation (from inventory)

vector MyPos;
vector MyScale;
rotation MyRot;

// Stop all NPCs from moving to target
StopAllNpcs() {
	integer Attempts = 5;
	while(Attempts--) {
		integer I;
		for(I = 0; I < RacersCount; I++) {
			key NpcId = llList2Key(Racers, I);
			osNpcStopMoveToTarget(NpcId);
		}
	}
}
// Stop all NPCs' crouch animation
StopAllNpcAnims() {
	integer I;
	for(I = 0; I < RacersCount; I++) {
		key NpcId = llList2Key(Racers, I);
		osNpcStopAnimation(NpcId, CrouchAnimation);
	}
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		CrouchAnimation = llGetInventoryName(INVENTORY_ANIMATION, 0);
		state Init;
	}
}
// Initialise race
// This state searches for the finish line, and only exits when it's found
state Init {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		CountdownCounter = 0;
		Gunshot = llGetInventoryName(INVENTORY_SOUND, 0);
		llSetTimerEvent(0.5);
	}
	timer() {
		llSensor(FINISH_LINE_NAME, NULL_KEY, SCRIPTED, 96.0, PI);
	}
	sensor(integer Count) {
		llSetTimerEvent(0.0);
		FinishId = llDetectedKey(0);
		state Standby;
	}
	no_sensor()	{
		if (!CountdownCounter) {
			llOwnerSay("Searching for finish line");
			CountdownCounter = 1;
			llSetTimerEvent(3.0);
		}
	}
}
// Waits for user to click, then scans for nearby NPCs, building up their table
state Standby {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		// Get object data
		MyPos = llGetPos();
		MyScale = llGetScale();
		MyRot = llGetRot();
		// Initialise tables
		Racers = [];
		RacerPositions = [];
		llShout(0, "Starting point ready. Bring your athletes here, and click to start the race!");
	}
	touch_start(integer Count) {
		llSensor("", NULL_KEY, OS_NPC, 96.0, PI);
	}
	sensor(integer Count) {
		llShout(0, "Getting ready to start race (click to cancel)");
		// Calculate starting positions for each racer
		// LHS is position of the left of the root prim
		vector LHS = MyPos - <1.4, -MyScale.y / 2.0, 0.0> * MyRot;
		while(Count--) {
			key NpcId = llDetectedKey(Count);
			vector StartPos = LHS - <0.0, LINEUP_MARGIN + (LINEUP_GAP* (float)Count), 0.0> * MyRot;
			Racers += NpcId;
			RacerPositions += StartPos;
		}
		RacersCount = llGetListLength(Racers);
		// We sort the races alphabetically to make their positions predictable. This is only to
		// stop them shuffling around and changing places if the race is restarted.
		Racers = llListSort(Racers, 1, TRUE);
		// Note that this breaks the parallelism with the positions list, but this doesn't matter.
		state Ready;
	}
}
// This state moves the NPCs into position, then turns them to face forwards
state Ready {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.5);
	}
	timer() {
		llSetTimerEvent(0.0);
		// Move NPCs into place, unless they're all
		integer StillMoving = FALSE;
		integer I;
		for(I = 0; I < RacersCount; I++) {
			key NpcId = llList2Key(Racers, I);
			vector StartPos = llList2Vector(RacerPositions, I);
			vector CurrentPos = osNpcGetPos(NpcId);
			if (llVecDist(StartPos, CurrentPos) > LINEUP_PROXIMITY) {
				integer Style = OS_NPC_NO_FLY;
				// The next line makes them randomly break into short runs, primarily to avoid
				// it being too obvious who's going to win
				if (llFrand(1.0) < 0.3) Style = Style | OS_NPC_RUNNING;
				osNpcMoveToTarget(NpcId, StartPos, Style);
				StillMoving = TRUE;
			}
		}
		// If any of them are not there yet, keep going
		if (StillMoving) {
			llSetTimerEvent(1.0 + llFrand(3.0));
			return;
		}
		// They're all at the finish line
		state Countdown;
	}
	touch_start(integer Count) {
		// if clicked, cancel race		
		llShout(0, "Race cancelled!");
		osMessageObject(FinishId, "reset");
		StopAllNpcs();
		state Standby;
	}
}
// This goes through the "ready, set, go" phases
state Countdown {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		// Tell finish line to get ready
		osMessageObject(FinishId, (string)RacersCount);
		// Load the sound into cache by playing extremely quietly
		llPlaySound(Gunshot, 0.001);
		CountdownCounter = 0;
		llSetTimerEvent(5.0);
	}
	timer()	{
		CountdownCounter++;
		if (CountdownCounter == 1) {
			llShout(0, "On your marks!");
			// turn racers to face the finish line
			integer I;
			for(I = 0; I < RacersCount; I++) {
				key NpcId = llList2Key(Racers, I);
				osNpcSetRot(NpcId, MyRot);
			}
		}
		else if (CountdownCounter == 2) {
			llShout(0, "Get set!");
			// make players crouch
			integer I;
			for(I = 0; I < RacersCount; I++) {
				key RacerId = llList2Key(Racers, I);
				osNpcPlayAnimation(RacerId, CrouchAnimation);
			}
		}
		else if (CountdownCounter == 3) {
			llPlaySound(Gunshot, 1.0);
			llShout(0, "GO!!!");
			llSetTimerEvent(0.0);
			state Race;
		}
	}
	touch_start(integer Count) {
		// if clicked, cancel race
		llShout(0, "Race cancelled!");
		StopAllNpcAnims();
		osMessageObject(FinishId, "reset");
		state Standby;
	}
}
state Race {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		// get position of finishing line
		FinishPos = llList2Vector(llGetObjectDetails(FinishId, [ OBJECT_POS ]), 0);
		// for each runner, stop their animation and make them run to the finish line
		integer I;
		for(I = 0; I < RacersCount; I++) {
			key NpcId = llList2Key(Racers, I);
			osNpcStopAnimation(NpcId, CrouchAnimation);
			osNpcMoveToTarget(NpcId, FinishPos, OS_NPC_NO_FLY | OS_NPC_RUNNING);
		}
	}
	dataserver(key QueryId, string Data) {
		// When finish line tells us, we reset (at end of race)
		if (Data == "reset") state Standby;
	}
	touch_start(integer Count) {
		// if clicked, cancel race		
		llShout(0, "Race cancelled!");
		StopAllNpcs();
		osMessageObject(FinishId, "reset");
		state Standby;
	}
}
// Nutrition race v.02