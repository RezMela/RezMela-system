// Tank hockey goal v0.8

// v0.8 - changed to allow server to reposition/delete pucks after goal
// v0.7 - added name display
// v0.6 - added "click to name" for team name
// v0.5 - updated server ping
// v0.4 - added server comms

integer TH_CHAT_CHANNEL = -3920100;

integer LM_SET_LABEL = -405503;

integer PrimCount;
integer PrimName;		// link number of name display prim
list FlashOn;
list FlashOff;
integer IsFlashOn;
string CurrentDisplayName;	// currently-displayed name

// Display name
integer HEIGHT_PIXELS = 128;	// this is the height of the canvas
string FONT_NAME = "Arial";		// Font attributes
integer FONT_SIZE = 64;
string TEXT_COLOR = "Black";

key PuckUuid;

ProcessTeam() {
	string TeamName = llGetObjectDesc();
	if (TeamName != "") {
		llRegionSay(TH_CHAT_CHANNEL, "G" + TeamName);		// ping server
	}
	if (TeamName != CurrentDisplayName && PrimName > -1) {
		llMessageLinked(PrimName, LM_SET_LABEL, TeamName, NULL_KEY); // pass text out to labeller script
		CurrentDisplayName = TeamName;
	}
}
// if team name is not set, then set it
ClickSetTeamName(string TeamName) {
	if (llGetObjectDesc() == "") {
		llSetObjectDesc(TeamName);
	}
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		CurrentDisplayName = "";
		FlashOn = [];
		FlashOff = [];
		PrimCount = llGetNumberOfPrims();
		PrimName = -1;
		integer P;
		for (P = 2; P <= PrimCount; P++) {
			string UName = llToUpper(llGetLinkName(P));
			if (UName == "POST") {
				FlashOn += [ PRIM_LINK_TARGET, P, PRIM_COLOR, ALL_SIDES, <1.0, 0.8, 0.1>, 1.0, PRIM_GLOW, ALL_SIDES, 0.6 ];
				FlashOff += [ PRIM_LINK_TARGET, P, PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.0, PRIM_GLOW, ALL_SIDES, 0.0 ];
			}
			else if (UName == "NAME") {
				PrimName = P;	
			}
		}
		state Normal;
	}
	changed(integer Change)	{
		if (Change & CHANGED_LINK) llResetScript();
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(2.0);
		llSetLinkPrimitiveParamsFast(LINK_THIS, FlashOff);
	}
	collision_start(integer Count) {
		if (llGetObjectDesc() == "debug") llShout(0, "collision!");
		while(Count--) {
			key Uuid = llDetectedKey(Count);
			if (llGetAgentSize(Uuid) == ZERO_VECTOR) {	// if it's not an avatar
				Uuid = llList2Key(llGetObjectDetails(Uuid, [ OBJECT_ROOT ]), 0); // we ensure that it's the root prim key that we get
				string UName = llToUpper(llKey2Name(Uuid));
				if (llSubStringIndex(UName, "PUCK") > -1) {		// if it has "puck" in its name (case insensitive)
					PuckUuid = Uuid;
					state Goal;
				}
			}
		}
	}
	touch_start(integer Count) {
		ClickSetTeamName(llDetectedName(0));
	}
	timer() {
		ProcessTeam();
	}
	changed(integer Change)	{
		if (Change & CHANGED_LINK) llResetScript();
	}
}
state Goal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llRegionSay(TH_CHAT_CHANNEL, "S" + llGetObjectDesc());		// report goal score
		llSetLinkPrimitiveParamsFast(LINK_THIS, FlashOn);
		if (llGetInventoryNumber(INVENTORY_SOUND)) llTriggerSound(llGetInventoryName(INVENTORY_SOUND, 0), 1.0);
		llSetTimerEvent(0.5);
		IsFlashOn = TRUE;
	}
	timer()	{
		if (IsFlashOn = !IsFlashOn) {
			llSetLinkPrimitiveParamsFast(LINK_THIS, FlashOn);
			ProcessTeam();
		}
		else {
			llSetLinkPrimitiveParamsFast(LINK_THIS, FlashOff);
		}
	}
	touch_start(integer Count) {
		//ClickSetTeamName(llDetectedName(0));		// commented out v0.8 - not necessary?!
		llSetTimerEvent(0.0);
		llRegionSay(TH_CHAT_CHANNEL, "R");		// tell server to reset the pucks
		state Normal;
	}
	changed(integer Change)	{
		if (Change & CHANGED_LINK) llResetScript();
	}
}
// Tank hockey goal v0.8