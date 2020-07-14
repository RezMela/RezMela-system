
string SCENE_FILE = "Auto";

integer LM_EXECUTE_COMMAND = -405502;    // Execute command (from other script)
integer LM_RESET = -405535;

integer SFM_LOAD = -3310421;

SetText(string Text) {
	llSetText(Text, <1.0, 1.0, 0.0>, 1.0);
}
SendCommandToML(string Command) {
	llMessageLinked(LINK_ROOT, LM_EXECUTE_COMMAND, Command, AvId);
}

integer Aborting;
integer ClearTries;
integer ClearChangesThings;

key AvId;

default {
	state_entry() {	
		state Idle;
	}
}
state Idle {
	state_entry() {
		SetText("Click to start testing");		
	}
	touch_start(integer n) {
		Aborting = FALSE;
		AvId = llDetectedKey(0);
		// Are there MLOs already?
		integer C = llGetNumberOfPrims();
		integer P;
		for (P = 2; P <= C; P++) {
			string Desc = llList2String(llGetLinkPrimitiveParams(P, [ PRIM_DESC ]), 0);
			if (llGetSubString(Desc, 0, 0) == "*") state Clear;
		}
		state Load;
	}
}
state Load {
	state_entry() {
		SetText("Loading scene ...");
		SendCommandToML("creategroup " + SCENE_FILE);
	}
	touch_start(integer n) {
		SetText("Aborting after this ...");
		Aborting = TRUE;
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		if (Number == LM_RESET) state Idle;
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) {
			llSetTimerEvent(30.0);
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		if (Aborting) state Idle;
		ClearTries = 0;
		state Clear;
	}
}
state Clear {
	state_entry() {
		ClearTries++;
		SetText("Clearing scene (" + (string)ClearTries + ") ...");
		SendCommandToML("clearall");
		ClearChangesThings = FALSE;
		llSetTimerEvent(20.0);
	}
	touch_start(integer n) {
		SetText("Aborting after this ...");
		Aborting = TRUE;
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		if (Number == LM_RESET) state Idle;
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) {
			ClearChangesThings = TRUE;
			llSetTimerEvent(5.0);
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		if (Aborting) state Idle;
		if (!ClearChangesThings) {
			state Load; // go around again
		}
		else {
			state ReClear;
		}
	}
}
state ReClear {
	state_entry() {
		state Clear;
	}
}