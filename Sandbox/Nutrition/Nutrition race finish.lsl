// Nutrition race finish v0.2

float TIMEOUT = 60.0;		// Amount of time to wait before giving up on runners

// Chat channel
integer MALL_CHANNEL = -84403270;

// Link message integer value for scoreboard comms
integer LM_SCOREBOARD = -2901900;

integer RunnersCount;		// count of NPCs in race
list Winners;				// list of winners' names
integer WinnersCount;		// number of entries in winners list

key StartId;		// UUID of starting object

integer TapeLinkNum;	// link number of tape prim (which should have the name "tape")


// Make tape prim (in)visible
SetTape(integer Visible) {
	float Alpha = 0.0;
	if (Visible) Alpha = 1.0;
	llSetLinkAlpha(TapeLinkNum, Alpha, ALL_SIDES);
}
default
{
	state_entry() {
		// Find the tape prim
		TapeLinkNum = -1;
		integer C = llGetNumberOfPrims();
		do {
			if (llToUpper(llGetLinkName(C)) == "TAPE") TapeLinkNum = C;
		} while(C-- > 1);
		if (TapeLinkNum > -1) state Waiting;
		llOwnerSay("Can't find tape prim (ie prim named 'Tape') - disabled.");
	}
}
// Waiting state, until race begins
state Waiting {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llVolumeDetect(TRUE);
		SetTape(FALSE);
	}
	dataserver(key QueryId, string Data) {
		// Start line script triggers start of race by sending us a message
		// containing the number of entrants (runners)
		StartId = QueryId;
		RunnersCount = (integer)Data;
		state Running;		// message from race controller
	}
}
// Running state, active while race is being run
state Running {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		// Clear scoreboard
		llMessageLinked(LINK_SET, LM_SCOREBOARD, "", NULL_KEY);
		// Show tape
		SetTape(TRUE);
		WinnersCount = 0;
		Winners = [];
		llSetTimerEvent(TIMEOUT);
	}
	collision_start(integer Count) {
		integer I;
		for(I = 0; I < Count; I++) {
			key Id = llDetectedKey(I);
			// if it's an NPC
			if (osIsNpc(Id)) {
				if (WinnersCount == 0) SetTape(FALSE);	// hide tape for the first one
				if (WinnersCount < 3) {		// if in 1st three
					string Name = llDetectedName(I);
					if (llListFindList(Winners, [ Name ]) == -1) {	// if not already recorded
						Winners += Name;
						string Place;
						if (WinnersCount == 0) Place = "First";
						else if (WinnersCount == 1) Place = "Second";
						else if (WinnersCount == 2) Place = "Third";
						llShout(0, Place + " place: " + Name + "!");
						WinnersCount++;
					}
				}
			}
		}
		//llOwnerSay("winners: " + (string)WinnersCount + " of " + (string)RunnersCount);
		if (WinnersCount >= RunnersCount) state Finish;
	}
	dataserver(key QueryId, string Data) {
		// if start line sends us a reset, we abort the race
		if (Data == "reset") state Waiting;
	}
	timer() {
		// time out - we give up on those that haven't arrived yet
		// (presumably something went wrong)
		llSetTimerEvent(0.0);
		integer Missing = RunnersCount - WinnersCount;
		llShout(0, (string)Missing + " people didn't make it.");
		state Finish;
	}
}
state Finish {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		// Send list of winners to scoreboard
		llMessageLinked(LINK_SET, LM_SCOREBOARD, llList2CSV(Winners), NULL_KEY);
		llSetTimerEvent(0.0);
		llShout(0, llList2String(Winners, 0) + " is the winner!");
		// send reset to starting line
		osMessageObject(StartId, "reset");
		state Waiting;
	}

}
// Nutrition race finish v0.2