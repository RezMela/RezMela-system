// Race start v0.5

// v0.5 - fixed issue with multiple entrant types
// v0.4 - new scoreboard interface

string CONFIG_NOTECARD = "Race config";
integer CHAT_CHANNEL = -8300371400;
integer SCOREBOARD_CHAT_CHANNEL = -6447330;
list Ordinals = [ "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th", "10th" ];

list Racers;
integer RACERS_VEHICLE_ID = 0;
integer RACERS_AVATAR_ID = 1;
integer RACERS_NAME = 2;
integer RACERS_WAYPOINT = 3;
integer RACERS_STRIDE = 4;
integer RacersCount;

list Winners;	// [ Name, time ]
integer WinnersCount;
integer PlaceNum;

list Waypoints = [];
integer WaypointsCount;
integer WAYPOINT_FINISH = 9999;

list Scoreboards = [];
integer ScoreboardsCount;
integer SCOREBOARD_CLEAR = 1;
integer SCOREBOARD_ENTRANTS = 2;
integer SCOREBOARD_WINNERS = 3;

integer Listener;

integer StartTime;

// Types of sensor (agent, scripted, etc)
list SensorTypes;
integer SensorTypePtr;
integer SensorTypesCount;

// Config details
float SensorRange;
integer UseCollisions;
integer AllowAgents;
integer AllowNpcs;
integer AllowVehicles;
string RemoteOptions;
float TimeOut;		// seconds before timeout
float ListenTime;
string ScoreboardChannel;

string SoundFile;

integer PrimStartButton;
integer PrimResetButton;
list LightsGreen;
list LightsAmber;
list LightsRed;
integer LightPhase;
vector COLOR_RED = <1.0, 0.0, 0.0>;
vector COLOR_AMBER = <1.0, 0.8, 0.0>;
vector COLOR_GREEN = <0.0, 1.0, 0.0>;
list Positions;

ReadConfig() {
	// Set config defaults
	SensorTypes = [];
	SensorRange = 0.0;
	TimeOut = 300.0;		// seconds before timeout
	ListenTime = 5.0;
	UseCollisions = FALSE;
	AllowAgents = AllowNpcs = AllowVehicles = FALSE;
	ScoreboardChannel = "Race";
	//
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Can't find notecard '" + CONFIG_NOTECARD + "'");
		return;
	}
	integer Lines = osGetNumberOfNotecardLines(CONFIG_NOTECARD);
	integer I;
	for(I = 0; I < Lines; I++) {
		string Line = osGetNotecardLine(CONFIG_NOTECARD, I);
		integer Comment = llSubStringIndex(Line, "//");
		if (Comment != 0) {	// Not a complete comment line
			if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);	// strip from comments characters onwards
			if (llStringTrim(Line, STRING_TRIM) != "") {	// if there's something left after comments are removed
				// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
				list L = llParseStringKeepNulls(Line, [ "=" ], [ ]);	// Separate LHS and RHS of assignment
				if (llGetListLength(L) == 2) {	// so there is a "X = Y" kind of syntax
					string OName = llStringTrim(llList2String(L, 0), STRING_TRIM);		// original parameter name
					string Name = llToLower(OName);		// lower-case version for case-independent parsing
					string Value = llStringTrim(llList2String(L, 1), STRING_TRIM);
					// Interpret name/value pairs
					if (Name == "sensorrange")	SensorRange = (float)Value;
					else if (Name == "usecollisions")	UseCollisions = String2Bool(Value);
					else if (Name == "timeout")	TimeOut = (float)Value;
					else if (Name == "listentime")	ListenTime = (float)Value;
					else if (Name == "allowagents") AllowAgents = String2Bool(Value);
					else if (Name == "allownpcs") AllowNpcs = String2Bool(Value);
					else if (Name == "allowvehicles") AllowVehicles = String2Bool(Value);
					else if (Name == "scoreboard")	ScoreboardChannel = StripQuotes(Value, Line);
					else llOwnerSay("Invalid parameter name in '" + CONFIG_NOTECARD + "': " + OName);
				}
				else {
					llOwnerSay("Invalid line in '" + CONFIG_NOTECARD + "': " + Line);
				}
			}
		}
	}
	if (AllowAgents) SensorTypes += AGENT;
	if (AllowNpcs) SensorTypes += OS_NPC;
	if (AllowVehicles) SensorTypes += SCRIPTED;
	SensorTypesCount = llGetListLength(SensorTypes);
	RemoteOptions = llDumpList2String(SensorTypes, "|");
}
// Takes a string in double quotes, and strips out the quotes. Validates the format.
// <Text> is the string with quotes; <Line> is the entire line for error reporting
string StripQuotes(string Text, string Line) {
	if (Text == "") {	// allow empty string for null value
		return("");
	}
	if (llGetSubString(Text, 0, 0) == "\"" && llGetSubString(Text, -1, -1) == "\"") { 	// if surrounded by quotes
		return(llGetSubString(Text, 1, -2));	// strip quotes
	}
	else {
		llOwnerSay("Invalid string literal (missing \"\"?): " + Line);
		return("");
	}
}
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
SetLights(list LightsList, integer On, vector Color) {
	list Params = [];
	list SetTo;
	if (On)
		SetTo = [ PRIM_GLOW, ALL_SIDES, 0.5, PRIM_POINT_LIGHT, TRUE, Color, 1.0, 10.0, 0.6 ];
	else
		SetTo = [ PRIM_GLOW, ALL_SIDES, 0.0, PRIM_POINT_LIGHT, FALSE, ZERO_VECTOR, 0.0, 0.0, 0.0 ];
	integer Len = llGetListLength(LightsList);
	integer P;
	for(P = 0; P < Len; P++) {
		integer LinkNum = llList2Integer(LightsList, P);
		Params += [ PRIM_LINK_TARGET, LinkNum ] + SetTo;
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
}
integer FindPrims() {
	PrimStartButton = -1;
	PrimResetButton = -1;
	LightsGreen = [];
	LightsAmber = [];
	LightsRed = [];
	integer PrimCount = llGetNumberOfPrims();
	if (PrimCount < 2) return FALSE;	// check for unlinked
	integer P;
	for(P = 2; P <= PrimCount; P++) {
		string PrimName = llGetLinkName(P);
		if (PrimName == "start") PrimStartButton = P;
		else if (PrimName == "reset") PrimResetButton = P;
		else if (PrimName == "green") LightsGreen += P;
		else if (PrimName == "amber") LightsAmber += P;
		else if (PrimName == "red") LightsRed += P;
	}
	if (llGetListLength(LightsGreen) == 0) {
		llOwnerSay("Can't find green lights");
		return FALSE;
	}
	if (llGetListLength(LightsAmber) == 0) {
		llOwnerSay("Can't find amber lights");
		return FALSE;
	}
	if (llGetListLength(LightsRed) == 0) {
		llOwnerSay("Can't find red lights");
		return FALSE;
	}
	if (PrimStartButton == -1) {
		llOwnerSay("Can't find start button");
		return FALSE;
	}
	return TRUE;
}
SavePositions() {
	Positions = [];
	integer Len = llGetListLength(Racers);
	integer P;
	for(P = 0; P < Len; P += RACERS_STRIDE) {
		key Uuid = llList2Key(Racers, P + RACERS_VEHICLE_ID);
		if (Uuid == NULL_KEY) Uuid = llList2Key(Racers, P + RACERS_AVATAR_ID);
		vector Pos = GetPos(Uuid);
		Positions += Pos;
	}
}
integer CheckPositions() {
	integer Len = llGetListLength(Racers);
	integer P;
	integer Q = 0;
	for(P = 0; P < Len; P += RACERS_STRIDE) {
		key Uuid = llList2Key(Racers, P + RACERS_VEHICLE_ID);
		if (Uuid == NULL_KEY) Uuid = llList2Key(Racers, P + RACERS_AVATAR_ID);
		vector Pos = GetPos(Uuid);
		vector PrevPos = llList2Vector(Positions, Q++);
		if (llVecDist(Pos, PrevPos) > 1.0) return FALSE;
	}
	return TRUE;
}
CheckEntrants() {
	integer Len = llGetListLength(Racers);
	integer P;
	for(P = 0; P < Len; P += RACERS_STRIDE) {
		integer StillReady = TRUE;
		key VehicleId = llList2Key(Racers, P + RACERS_VEHICLE_ID);
		key AvatarId = llList2Key(Racers, P + RACERS_AVATAR_ID);
		// check if they've left the region
		if (llGetAgentSize(AvatarId) == ZERO_VECTOR) StillReady = FALSE;
		// check if they're sitting down or not as appropriate
		if (VehicleId != NULL_KEY) {	// if it's a vehicle
			if (!IsSitting(AvatarId)) StillReady = FALSE;
		}
		else
		{
			if (IsSitting(AvatarId)) StillReady = FALSE;
		}
		if (!StillReady) {
			string AvatarName = llList2String(Racers, P + RACERS_NAME);
			BroadcastMessage(AvatarName + " is out of the race!");
			Racers = llDeleteSubList(Racers, P, P + RACERS_STRIDE - 1);	// delete their entry
			UpdateScoreboards(SCOREBOARD_ENTRANTS);
			RacersCount--;
			// we leave at this point because it would be messy to recover loop position.
			return;
		}
	}
}
vector GetPos(key Uuid) {
	return llList2Vector(llGetObjectDetails(Uuid, [ OBJECT_POS ]), 0);
}
DetectedEntrant(key Uuid) {
	if (llGetAgentSize(Uuid) != ZERO_VECTOR ) {	// if it's an agent/NPC
		if (osIsNpc(Uuid)) {
			if (AllowNpcs) AddRacer(NULL_KEY, Uuid);
		}
		else {
			if (!IsSitting(Uuid)) {		// ignore seated agents because they're probably in a vehicle
				if (AllowAgents) AddRacer(NULL_KEY, Uuid);
			}
		}
	}
	else {
		if (AllowVehicles) {
			MessageObject(Uuid, "vehping");
		}
	}
}
// wrapper for osMessageObject() that checks to see if object exists
MessageObject(key Uuid, string Text) {
	if (ObjectExists(Uuid)) {
		osMessageObject(Uuid, Text);
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
AddRacer(key VehicleId, key AvatarId) {
	string AvatarName = llKey2Name(AvatarId);
	integer NewEntrant = TRUE;
	integer Ptr = llListFindList(Racers, [ VehicleId, AvatarId ]);
	if (Ptr > -1) {
		Racers = llDeleteSubList(Racers, Ptr, Ptr + RACERS_STRIDE - 1);		// delete if it already exists
		NewEntrant = FALSE;
	}
	Racers += [ VehicleId, AvatarId, AvatarName, -1 ];
	if (NewEntrant) {
		BroadcastMessage(AvatarName + " has entered the race!");
		RacersCount++;
		UpdateScoreboards(SCOREBOARD_ENTRANTS);
	}
}
// Delete racer by pointer to start of stride
DeleteRacer(integer Ptr) {
	Racers = llDeleteSubList(Racers, Ptr, Ptr + RACERS_STRIDE - 1);
	RacersCount--;
	UpdateScoreboards(SCOREBOARD_ENTRANTS);
}
UpdateWaypoint(integer Ptr, integer Waypoint) {
	Racers = llListReplaceList(Racers, [ Waypoint ], Ptr + RACERS_WAYPOINT, Ptr + RACERS_WAYPOINT); 	// update waypoint
}
integer IsSitting(key AvatarId) {
	return (llGetAgentInfo(AvatarId) & AGENT_ON_OBJECT);
}
UpdateScoreboards(integer Type) {
	if (Type == SCOREBOARD_CLEAR) {
		SendToScoreboards("DC");
		return;
	}
	SendToScoreboards("DR");
	if (Type == SCOREBOARD_ENTRANTS) {
		SendToScoreboards("DH" + "ENTRANTS");
		integer LineNum = 0;
		integer Len = llGetListLength(Racers);
		integer Ptr;
		for (Ptr = 0; Ptr < Len; Ptr += RACERS_STRIDE) {
			string Name = llList2String(Racers, Ptr + RACERS_NAME);
			SendToScoreboards("DL" + (string)LineNum++ + "," + Name);
		}
	}
	else if (Type == SCOREBOARD_WINNERS) {
		SendToScoreboards("DH" + "WINNERS");
		integer LineNum = 0;
		integer Len = llGetListLength(Winners);
		integer Ptr;
		for (Ptr = 0; Ptr < Len; Ptr += 2) {
			string Name = llList2String(Winners, Ptr);
			integer Time = llList2Integer(Winners, Ptr + 1);
			SendToScoreboards("DL" + (string)LineNum++ + "," + Name + " [" + (string)Time + "s]");
		}
	}
	SendToScoreboards("DD");
}
SendToWaypoints(string Text) {
	integer P;
	for (P = 0; P < WaypointsCount; P++) {
		MessageObject(llList2Key(Waypoints, P), Text);
	}
}
SendToScoreboards(string Text) {
	integer P;
	for (P = 0; P < ScoreboardsCount; P++) {
		MessageObject(llList2Key(Scoreboards, P), Text);
	}
}
BroadcastMessage(string Text) {
	list AvIds = llGetAgentList(AGENT_LIST_REGION, []);
	integer AvsCount = llGetListLength(AvIds);
	integer A;
	for(A = 0; A < AvsCount; A++) {
		llRegionSayTo(llList2Key(AvIds, A), 0, Text);
	}
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
		if (!FindPrims()) state Hang;
		ReadConfig();
		Waypoints = [];
		Scoreboards = [];
		SetLights(LightsGreen, TRUE, COLOR_GREEN);
		SetLights(LightsAmber, TRUE, COLOR_AMBER);
		SetLights(LightsRed, TRUE, COLOR_RED);
		llListen(CHAT_CHANNEL, "", NULL_KEY, "");
		llListen(SCOREBOARD_CHAT_CHANNEL, "", NULL_KEY, "");
		llSetTimerEvent(ListenTime);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == CHAT_CHANNEL && Message == "+") {
			if (llListFindList(Waypoints, [ Id ]) == -1)
				Waypoints += [ Name, Id ];	// we temporarily include the name for sorting
		}
		else if (Channel == SCOREBOARD_CHAT_CHANNEL && Message == "S" + ScoreboardChannel) {
			if (llListFindList(Scoreboards, [ Id ]) == -1)
				Scoreboards += Id;
		}
	}
	timer() {
		// if we haven't found any scoreboards or waypoints, keep waiting
		if (llGetListLength(Scoreboards) == 0 || llGetListLength(Waypoints) == 0) return;
		llSetTimerEvent(0.0);
		Waypoints = llListSort(Waypoints, 2, TRUE);	// sort by name ascending
		// Discard names now we don't need them (see http://lslwiki.net/lslwiki/wakka.php?wakka=llList2ListStrided for ugly hack)
		Waypoints = llList2ListStrided(llDeleteSubList(Waypoints, 0, 0), 0, -1, 2);
		WaypointsCount = llGetListLength(Waypoints);
		SendToWaypoints("@" + RemoteOptions);
		ScoreboardsCount = llGetListLength(Scoreboards);
		UpdateScoreboards(SCOREBOARD_CLEAR);
		state Waiting;
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) llResetScript();
		if (Change & CHANGED_INVENTORY) llResetScript();
	}
}
state Waiting {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		SoundFile = llGetInventoryName(INVENTORY_SOUND, 0);
		SetLights(LightsGreen, FALSE, COLOR_GREEN);
		SetLights(LightsAmber, FALSE, COLOR_AMBER);
		SetLights(LightsRed, TRUE, COLOR_RED);
		BroadcastMessage("Ready to race - line up and click 'START' when you're ready!");
		Racers = [];
		RacersCount = 0;
		SensorTypePtr = 0;
		llSetTimerEvent(1.0);
	}
	collision_start(integer Count) {
		if (UseCollisions) {
			while(Count--) {
				DetectedEntrant(llDetectedKey(Count));
			}
		}
	}
	sensor(integer Count) {
		while(Count--) {
			DetectedEntrant(llDetectedKey(Count));
		}
	}
	dataserver(key QueryId, string DData) {
		list Data = llCSV2List(DData);
		string Command = llList2String(Data, 0);
		list Params = llDeleteSubList(Data, 0, 0);
		// response from vehicle ping
		if (Command == "vehpong") {
			key DriverId = llList2Key(Params, 0);
			if (DriverId != NULL_KEY)
				AddRacer(QueryId, DriverId);
		}
	}
	touch_start(integer Count) {
		while(Count--) {
			integer LinkNum = llDetectedLinkNumber(Count);
			if (LinkNum == PrimStartButton) {
				if (llGetListLength(Racers) == 0) {
					llRegionSayTo(llDetectedKey(Count), 0, "Nobody has entered the race!");
				}
				else {
					state Start;
				}
			}
			else if (LinkNum == PrimResetButton && llDetectedKey(0) == llGetOwner()) {
				state Bootup;
			}
		}
	}
	timer() {
		if (SensorRange > 0.0) {
			integer SensorType = llList2Integer(SensorTypes, SensorTypePtr++);
			if (SensorTypePtr > SensorTypesCount) SensorTypePtr = 0;
			llSensor("", NULL_KEY, SensorType, SensorRange, PI);
		}
		CheckEntrants();				// remove anyone who's no longer in the region
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) state Bootup;
		if (Change & CHANGED_INVENTORY) state Bootup;
	}
}
state Start {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		UpdateScoreboards(SCOREBOARD_CLEAR);
		SavePositions();
		SetLights(LightsGreen, FALSE, COLOR_GREEN);
		SetLights(LightsAmber, FALSE, COLOR_AMBER);
		SetLights(LightsRed, TRUE, COLOR_RED);
		LightPhase = 0;
		llSetTimerEvent(1.2);
	}
	timer() {
		if (!CheckPositions()) {
			BroadcastMessage("Someone moved! Counting down again.");
			state ReStart;
		}
		CheckEntrants();				// remove anyone who's no longer in the region
		llPlaySound(SoundFile, 1.0);
		LightPhase++;
		if (LightPhase == 1) {	// red -> amber
			SetLights(LightsRed, FALSE, COLOR_RED);
			SetLights(LightsAmber, TRUE, COLOR_AMBER);
		}
		else if (LightPhase == 2) {	// amber -> green
			SetLights(LightsAmber, FALSE, COLOR_AMBER);
			SetLights(LightsGreen, TRUE, COLOR_GREEN);
			llSetTimerEvent(0.0);
			state Racing;
		}
	}
	touch_start(integer Count) {
		if (llDetectedLinkNumber(0) == PrimResetButton && llDetectedKey(0) == llGetOwner()) {
			state Bootup;
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) state Bootup;
		if (Change & CHANGED_INVENTORY) state Bootup;
	}
}
state ReStart {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		state Start;
	}
}
state Racing {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		BroadcastMessage("And they're off!");
		StartTime = llGetUnixTime();
		Winners = [];
		WinnersCount = 0;
		PlaceNum = 0;
		SendToWaypoints("c");
		llSetTimerEvent(TimeOut);
	}
	dataserver(key QueryId, string Data) {
		if (llGetSubString(Data, 0, 0) == "%") {
			llSetTimerEvent(TimeOut);
			list Detected = llCSV2List(llGetSubString(Data, 1, -1));
			key DetectedUuid = (key)llList2String(Detected, 0);
			string sType = llList2String(Detected, 1);	 // (A)vatar or (V)ehicle
			key VehicleId = NULL_KEY;
			key AvatarId = NULL_KEY;
			if (sType == "A") AvatarId = DetectedUuid;
			else VehicleId = DetectedUuid;
			integer Ptr = -1;
			if (VehicleId != NULL_KEY)
				Ptr = llListFindList(Racers, [ VehicleId ]);
			else
				Ptr = llListFindList(Racers, [ NULL_KEY, AvatarId ]);
			if (Ptr > -1) {
				integer CurrentWaypoint = llList2Integer(Racers, Ptr + RACERS_WAYPOINT);
				if (CurrentWaypoint != WAYPOINT_FINISH) {	// not previously finished the race (if they've finished, it's happened just now)
					integer WaypointNum = llListFindList(Waypoints, [ QueryId ]);
					string Name = llList2String(Racers, Ptr + RACERS_NAME);
					if (WaypointNum == -1) llOwnerSay("Can't find waypoint!");
					if (WaypointNum != CurrentWaypoint + 1) {
						BroadcastMessage(Name + " went the wrong way - disqualified!");
						DeleteRacer(Ptr);
						if (RacersCount == 0) {
							BroadcastMessage("Nobody left in the race.");
							state Finished;
						}
						if (WinnersCount == RacersCount) state Finished;
					}
					CurrentWaypoint++;
					if (CurrentWaypoint == (WaypointsCount - 1)) {	// they've reached the last waypoint (ie the finish line)
						CurrentWaypoint = WAYPOINT_FINISH;
						Winners += [ Name, llGetUnixTime() - StartTime ];
						BroadcastMessage("In " + llList2String(Ordinals, PlaceNum) + " place: " + Name + "!");
						WinnersCount++;
						PlaceNum++;
						UpdateScoreboards(SCOREBOARD_WINNERS);
						if (PlaceNum > 10) state Finished;
						if (WinnersCount == RacersCount) state Finished;
					}
					UpdateWaypoint(Ptr, CurrentWaypoint);
				}
			}
		}
	}
	touch_start(integer Count) {
		if (llDetectedLinkNumber(0) == PrimResetButton && llDetectedKey(0) == llGetOwner()) {
			state Bootup;
		}
	}
	timer() {
		BroadcastMessage("Race timed out.");
		state Finished;
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) state Bootup;
		if (Change & CHANGED_INVENTORY) state Bootup;
	}
}
state Finished {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		BroadcastMessage("Race over!");
		SetLights(LightsGreen, FALSE, COLOR_GREEN);
		SetLights(LightsAmber, FALSE, COLOR_AMBER);
		SetLights(LightsRed, FALSE, COLOR_RED);
		llSetTimerEvent(20.0);
	}
	timer() {
		state Waiting;
	}
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
	changed(integer Change) {
		if (Change & CHANGED_LINK) state Bootup;
		if (Change & CHANGED_INVENTORY) state Bootup;
	}
}
// Race start v0.5