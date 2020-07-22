// NPC behaviour v0.2

string WAYPOINT_NAME = "waypoint";	// keep this lower case (actual names are case insensitive)
string BEHAVIOUR_CARD_ID = "NPCBE";	// Behaviour card ID string
string SPEECH_CENTER_OBJECT = "Speech center";
float SPEECH_CENTER_VOLUME = 0.8;

float WAYPOINT_RADIUS = 1.0;
float TIMER_PERIOD = 0.5;

// Delegated deletion stuff
integer LM_DELEGATE_DELETION = -7044001;
integer LM_DELETE_RECEIVED = -7044002;

// Internal "programs" for behaviour
list Programs;
integer PRO_BEHAVIOUR = 0;		// pointer to Behaviours table
integer PRO_SOURCE_LINE = 1;	// original line number in notecard
integer PRO_INSTRUCTION = 2;
integer PRO_PARAMETERS = 3;
integer PRO_STRIDE = 4;
integer ProgramsLength;

// Instruction constants (internal)
integer I_WAIT = 1;
integer I_WALK = 20;
integer I_RUN = 21;
integer I_FLY = 22;
integer I_SAY = 30;
integer I_SHOUT = 31;
integer I_WHISPER = 32;
integer I_SOUND = 35;
integer I_ANIMATION_START = 40;
integer I_ANIMATION_STOP = 50;
integer I_SIT = 60;
integer I_STAND = 61;
integer I_TOUCH = 70;
integer I_LABEL = 80;
integer I_GOTO = 90;
integer I_EOF = 100;

// Labels
list Labels;
integer LAB_BEHAVIOUR = 0;		// pointer to Behaviours table
integer LAB_LABEL = 1;
integer LAB_PROGRAMCOUNTER = 2;

// Triggers
list Triggers;
integer TRI_NPC_ID = 0;
integer TRI_TYPE = 1;			// (integer) see constant values
integer TRI_INSTRUCTION = 2;	// originating instruction
integer TRI_DATA = 3;			// trigger parameters
integer TRI_STRIDE = 4;

integer TRI_TYPE_WAYPOINT = 1;
integer TRI_TYPE_WAIT = 2;

// Behaviour cards
list Behaviours;
integer BEH_CARDNAME = 0;
integer BEH_NPC_ID = 1;
integer BEH_PROGRAM_START = 2;	// pointer to Programs table
integer BEH_PROGRAM_COUNTER = 3;	// pointer to current instruction row
integer BEH_STRIDE = 4;
integer BehavioursLength;

// Waypoints
list Waypoints;
integer WAY_WAYNAME = 0;
integer WAY_LINKNUM = 1;		// negative for disambiguation in llListFindList
integer WAY_POS = 2;		// region coords
integer WAY_STRIDE = 3;
integer WaypointsLength;

// Animations
list Animations;	// [ NPC Id, Animation, Volume ]

// Sounds
list Sounds;		// CSV strings containing [ NPC Id, Sound UUID ]

integer PrimCount;
vector RootPos;
rotation RootRot;
integer WasSitting = FALSE;		// was an NPC sitting the last time we checked?

ProcessTriggers() {
	list NewTriggers = [];
	integer Len = llGetListLength(Triggers);
	integer T;
	for (T = 0; T < Len ; T += TRI_STRIDE) {
		integer DeleteTrigger = FALSE;
		key NpcId = llList2Key(Triggers, T + TRI_NPC_ID);
		if (!osIsNpc(NpcId)) {
			// NPC has disappeared
			RemoveNpc(NpcId);
			DeleteTrigger = TRUE;
		}
		integer TriggerType = llList2Integer(Triggers, T + TRI_TYPE);
		if (TriggerType == TRI_TYPE_WAYPOINT) {
			vector WayPos = llList2Vector(Triggers, T + TRI_DATA);
			vector NpcPos = GetNpcPos(NpcId);
			// If NPC is close to target position, delete trigger
			if (llVecDist(NpcPos, WayPos) <= WAYPOINT_RADIUS) {
				DeleteTrigger = TRUE;
			}
			else {
				// They're still moving to the target, so re-issue movement command.
				// This helps after an avatar stand, and may have other positive effects
				// on robustsness
				integer Instruction = llList2Integer(Triggers, T + TRI_INSTRUCTION);
				osNpcMoveToTarget(NpcId, WayPos, GetMovementType(Instruction));
			}
		}
		else if (TriggerType == TRI_TYPE_WAIT) {
			integer WaitUntil = llList2Integer(Triggers, T + TRI_DATA);
			if (llGetUnixTime() >= WaitUntil) {
				DeleteTrigger = TRUE;
			}
		}
		if (!DeleteTrigger) NewTriggers += llList2List(Triggers, T, T + TRI_STRIDE - 1);
	}
	Triggers = NewTriggers;
}

ProcessCards() {
	// To make list handling more efficient, we don't edit the behaviours list in-situ but create a new one
	// and then overwrite the original.
	list NewBehaviours = [];
	integer BehaviourPtr;
	for(BehaviourPtr = 0; BehaviourPtr < BehavioursLength; BehaviourPtr += BEH_STRIDE) {
		key NpcId = llList2Key(Behaviours, BehaviourPtr + BEH_NPC_ID);
		string CardName = llList2String(Behaviours, BehaviourPtr + BEH_CARDNAME);
		integer ProgramStart = llList2Integer(Behaviours, BehaviourPtr + BEH_PROGRAM_START);
		integer ProgramCounter = llList2Integer(Behaviours, BehaviourPtr + BEH_PROGRAM_COUNTER);
		if (ProgramCounter < 0) {	// -ve program counter means not started yet
			// No NPC yet, so read up to "start" line and create NPC
			NpcId = LoadCard(CardName, BehaviourPtr);
			if (NpcId != NULL_KEY) {	// if no errors
				// Pick up new program start (no longer 0, now has actual pointer)
				ProgramStart = llList2Integer(Behaviours, BehaviourPtr + BEH_PROGRAM_START);
				// Kick instructions off on line 0 (ie start)
				NewBehaviours += BehaviourLine(CardName, NpcId, ProgramStart, 0);
			}
		}
		else if (NpcId != NULL_KEY && llListFindList(Triggers, [ NpcId ]) == -1) {	// if NPC exists, and there is not a trigger waiting
			ProgramCounter = ProcessInstruction(BehaviourPtr, NpcId, ProgramCounter);
			if (ProgramCounter == -1) return;	// bad error
			NewBehaviours += BehaviourLine(CardName, NpcId, ProgramStart, ProgramCounter);
		}
		else {
			// NPC has a trigger waiting, so just copy line as is
			NewBehaviours += llList2List(Behaviours, BehaviourPtr, BehaviourPtr + BEH_STRIDE - 1);
		}
	}
	Behaviours = NewBehaviours;
	BehavioursLength = llGetListLength(Behaviours);
}
key LoadCard(string CardName, integer BehaviourPtr) {
	integer CardLength = osGetNumberOfNotecardLines(CardName);
	string NpcCard = "";
	string NpcName1 = "NPC";
	string NpcName2 = "Character";
	vector NpcPos = RootPos;
	integer C;
	for(C = 0; C < CardLength; C++) {
		string Line = GetNotecardLine(CardName, C);
		if (Line != "") {
			if (llToLower(Line) == "start") {
				// finished reading
				if (NpcCard == "") {
					ErrorMessage("'Card' command missing from card: '" + CardName + "'");
					return NULL_KEY;
				}
				integer Errors = PrecompileInstructions(BehaviourPtr, CardName, CardLength, C + 1);
				if (Errors == 0) {
					// If precompile went OK, create the NPC and return their UUID
					key NpcId = osNpcCreate(NpcName1, NpcName2, NpcPos, NpcCard, OS_NPC_NOT_OWNED);
					return NpcId;
				}
				else {
					// Errors in pre-complication
					ErrorMessage((string)Errors + " errors in card '" + CardName + "'");
					return NULL_KEY;
				}
			}
			// Process ini-style initial parameter
			list Parts = ParseIniStyleLine(Line);
			string Name = llToLower(llList2String(Parts, 0));
			string Value = llList2String(Parts, 1);
			if (Name == "card" && NpcCard == "") {
				NpcCard = StripQuotes(Value, Line);
			}
			else if (Name == "name") {
				list NameParts = llParseStringKeepNulls(StripQuotes(Value, Line), [ " " ], []);
				NpcName1 = llList2String(NameParts, 0);
				NpcName2 = llList2String(NameParts, 1);
			}
			else if (Name == "position") {
				NpcPos = ParsePos(Value, CardName, C);
			}
		}
	}
	ErrorMessage("'Start' command missing from card: '" + CardName + "'");
	return NULL_KEY;
}
// Reads through instructions in behaviour card, converting them into internal representation
// Returns number of errors found
integer PrecompileInstructions(integer BehaviourPtr, string CardName, integer CardLength, integer SourceLine) {
	integer Errors = 0;
	// get the pointer to the programs table to put in the behaviours table
	integer ProgramStart = llGetListLength(Programs);
	Behaviours = llListReplaceList(Behaviours, [ ProgramStart ], BehaviourPtr + BEH_PROGRAM_START, BehaviourPtr + BEH_PROGRAM_START);
	// There's always a label with a null name at the beginning
	AddInstruction(BehaviourPtr, SourceLine, I_LABEL, "");
	Labels += [  BehaviourPtr, "", 0];
	while(SourceLine < CardLength) {
		integer ProgramCounter = (llGetListLength(Programs) - ProgramStart) / PRO_STRIDE;
		string Line = GetNotecardLine(CardName, SourceLine);
		if (Line != "") {
			integer Space = llSubStringIndex(Line, " ");
			if (Space == -1) Space = 0;
			string Command = llToLower(llGetSubString(Line, 0, Space - 1));
			string Parameters = "";
			if (Space)
				Parameters = llGetSubString(Line, Space + 1, -1);
			if (Command == "walk") {
				vector Pos = ParsePos(Parameters, CardName, SourceLine);
				AddInstruction(BehaviourPtr, SourceLine, I_WALK, (string)Pos);
			}
			else if (Command == "run") {
				vector Pos = ParsePos(Parameters, CardName, SourceLine);
				AddInstruction(BehaviourPtr, SourceLine, I_RUN, (string)Pos);
			}
			else if (Command == "fly") {
				vector Pos = ParsePos(Parameters, CardName, SourceLine);
				AddInstruction(BehaviourPtr, SourceLine, I_FLY, (string)Pos);
			}
			else if (Command == "wait") {
				AddInstruction(BehaviourPtr, SourceLine, I_WAIT, Parameters);
			}
			else if (Command == "sit") {
				AddInstruction(BehaviourPtr, SourceLine, I_SIT, IStripQuotes(Parameters, CardName, SourceLine));
			}
			else if (Command == "click") {
				AddInstruction(BehaviourPtr, SourceLine, I_TOUCH, IStripQuotes(Parameters, CardName, SourceLine));
			}
			else if (Command == "stand") {
				AddInstruction(BehaviourPtr, SourceLine, I_STAND, "");
			}
			else if (Command == "animate") {
				AddInstruction(BehaviourPtr, SourceLine, I_ANIMATION_STOP, "");		// stop any previous animation
				if (Parameters != "") {		// if they've specified an animation, start it
					AddInstruction(BehaviourPtr, SourceLine, I_ANIMATION_START, IStripQuotes(Parameters, CardName, SourceLine));
				}
			}
			else if (Command == "animatestop") {
				AddInstruction(BehaviourPtr, SourceLine, I_ANIMATION_STOP, "");
			}
			else if (Command == "say") {
				AddInstruction(BehaviourPtr, SourceLine, I_SAY, IStripQuotes(Parameters, CardName, SourceLine));
			}
			else if (Command == "shout") {
				AddInstruction(BehaviourPtr, SourceLine, I_SHOUT, IStripQuotes(Parameters, CardName, SourceLine));
			}
			else if (Command == "whisper") {
				AddInstruction(BehaviourPtr, SourceLine, I_WHISPER, IStripQuotes(Parameters, CardName, SourceLine));
			}
			else if (Command == "sound") {
				AddInstruction(BehaviourPtr, SourceLine, I_SOUND, IStripQuotes(Parameters, CardName, SourceLine));
			}
			else if (Command == "label") {
				Labels += [ BehaviourPtr, Parameters, ProgramCounter ];
			}
			else if (Command == "loop") {
				AddInstruction(BehaviourPtr, SourceLine, I_GOTO, "");
			}
			else if (Command == "goto") {
				AddInstruction(BehaviourPtr, SourceLine, I_GOTO, Parameters);
			}
			else {
				ErrorMessage("Unknown command: '" + Command + "' in '" + CardName + "' at line " + SourceLine);
				Errors++;
			}
		}
		SourceLine++;
	}
	AddInstruction(BehaviourPtr, 0, I_EOF, "");
	ProgramsLength = llGetListLength(Programs);
	return Errors;
}
// Add an instruction to the internal programs table, return pointer to that instruction
integer AddInstruction(integer BehaviourPtr, integer SourceLine, integer Instruction, string Parameters) {
	integer Ptr = llGetListLength(Programs);
	Programs += [ BehaviourPtr, SourceLine, Instruction, Parameters ];
	return Ptr;
}
// Process a single internal instruction
integer ProcessInstruction(integer BehaviourPtr, key NpcId, integer ProgramCounter) {
	// Get program start (pointer to beginning of this behaviour's section of the programs table)
	integer ProgramStart = llList2Integer(Behaviours, BehaviourPtr + BEH_PROGRAM_START);
	string CardName = llList2String(Behaviours, BehaviourPtr + BEH_CARDNAME);
	integer Ptr = ProgramStart + (ProgramCounter * PRO_STRIDE);	// get pointer to programs table
	integer Instruction = llList2Integer(Programs, Ptr + PRO_INSTRUCTION);
	string Parameters = llList2String(Programs, Ptr + PRO_PARAMETERS);
	integer SourceLine = llList2Integer(Programs, Ptr + PRO_SOURCE_LINE);
	if (Instruction == I_WALK) {
		vector Pos = (vector)Parameters;
		osNpcMoveToTarget(NpcId, Pos, GetMovementType(Instruction));
		Triggers += [ NpcId, TRI_TYPE_WAYPOINT, Instruction, Pos ];
	}
	else if (Instruction == I_RUN) {
		vector Pos = (vector)Parameters;
		osNpcMoveToTarget(NpcId, Pos, GetMovementType(Instruction));
		Triggers += [ NpcId, TRI_TYPE_WAYPOINT, Instruction, Pos ];
	}
	else if (Instruction == I_FLY) {
		vector Pos = (vector)Parameters;
		osNpcMoveToTarget(NpcId, Pos, GetMovementType(Instruction));
		Triggers += [ NpcId, TRI_TYPE_WAYPOINT, Instruction, Pos ];
	}
	else if (Instruction == I_WAIT) {
		Triggers += [ NpcId, TRI_TYPE_WAIT, Instruction, llGetUnixTime() + (integer)Parameters ];
	}
	else if (Instruction == I_SIT) {
		Sit(NpcId, Parameters, CardName, SourceLine);
	}
	else if (Instruction == I_TOUCH) {
		Touch(NpcId, Parameters, CardName, SourceLine);
	}
	else if (Instruction == I_STAND) {
		osNpcStand(NpcId);
		//		vector NpcPos = GetNpcPos(NpcId);
		//		NpcPos += <0.1, 0.0, 1.0>;
		//		osNpcStopMoveToTarget(NpcId);
		//		osNpcMoveToTarget(NpcId, NpcPos, OS_NPC_NO_FLY );
		//		Triggers += [ NpcId, TRI_TYPE_WAIT, Instruction, llGetUnixTime() + 2 ];
	}
	else if (Instruction == I_ANIMATION_START) {
		string Animation = Parameters;
		osNpcPlayAnimation(NpcId, Animation);
		Animations += [ NpcId, Animation ];
	}
	else if (Instruction == I_ANIMATION_STOP) {
		string Animation = Parameters;
		// If there's a prior animation, stop it
		integer A = llListFindList(Animations, [ NpcId ]);
		if (A > -1) {
			string OldAnimation = llList2String(Animations, A + 1);
			osNpcStopAnimation(NpcId, OldAnimation);
		}
	}
	else if (Instruction == I_SAY) {
		osNpcSay(NpcId, Parameters);
	}
	else if (Instruction == I_SHOUT) {
		osNpcShout(NpcId, 0, Parameters);
	}
	else if (Instruction == I_WHISPER) {
		osNpcWhisper(NpcId, 0, Parameters);
	}
	else if (Instruction == I_SOUND) {
		CreateSoundObject(NpcId, Parameters, CardName, SourceLine);
	}
	else if (Instruction == I_LABEL) {
		// We don't need to do anything
	}
	else if (Instruction == I_GOTO) {
		ProgramCounter = GetLabel(BehaviourPtr, Parameters);
		if (ProgramCounter == -1) {
			SourceError("Invalid label: '" + Parameters + "'", CardName, SourceLine);
			return -1;
		}
	}
	else if (Instruction == I_EOF) {
		ProgramCounter = -1;	// so that incrementing will return us to line 0, the beginning
		// (giving us automatic looping)
	}
	else {
		SourceError("Unknown internal instruction: '" + Instruction + "'", CardName, SourceLine);
		return -1;
	}
	ProgramCounter++;
	return ProgramCounter;
}
// Given label details, returns program counter for that label
integer GetLabel(integer BehaviourPtr, string Label) {
	integer Ptr = llListFindList(Labels, [ BehaviourPtr, Label ]);
	if (Ptr == -1) return -1;		// failure
	integer ProgramCounter = llList2Integer(Labels, Ptr + LAB_PROGRAMCOUNTER);
	return ProgramCounter;
}
list ParseIniStyleLine(string Line) {
	integer Comment = llSubStringIndex(Line, "//");
	if (Comment != 0) {	// Not a complete comment line
		if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);	// strip from comments character onwards
		if (llStringTrim(Line, STRING_TRIM) != "") {
			// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
			list L = llParseStringKeepNulls(Line, [ "=" ], [ ]);
			if (llGetListLength(L) == 2) {	// so there is a "X = Y" kind of syntax
				// return trimmed versions of both elements
				return [ llStringTrim(llList2String(L, 0), STRING_TRIM), llStringTrim(llList2String(L, 1), STRING_TRIM) ];
			}
		}
	}
	return [];
}
GetBehaviourCards() {
	Behaviours = [];
	integer Count = llGetInventoryNumber(INVENTORY_NOTECARD);
	integer N;
	for(N = 0; N < Count; N++) {
		string NotecardName = llGetInventoryName(INVENTORY_NOTECARD, N);
		if (IsBehaviourCard(NotecardName)) {
			Behaviours += BehaviourLine(NotecardName, NULL_KEY, 0, -1);		// -1 program counter means "not started"
		}
	}
	BehavioursLength = llGetListLength(Behaviours);
}
// Basically a wrapper for adding a row to a behaviours table, to make it easier to deal with
// changes to the (currently rather volatile) table format in the future.
list BehaviourLine(string NotecardName, key NpcId, integer ProgramStart, integer ProgramCounter) {
	return [ NotecardName, NpcId, ProgramStart, ProgramCounter ];
}
// Set correct bit flags for walking, running, etc, suitable of osNpcMoveToTarget()
integer GetMovementType(integer Instruction) {
	if (Instruction == I_WALK) return (OS_NPC_NO_FLY);
	else if (Instruction == I_RUN) return (OS_NPC_RUNNING | OS_NPC_NO_FLY);
	else if (Instruction == I_FLY) return (OS_NPC_FLY | OS_NPC_LAND_AT_TARGET);
	else {
		ErrorMessage("Movement type not found: " + (string)Instruction);
		return OS_NPC_NO_FLY;
	}
}
// returns a region position from either a local vector position or a waypoint
vector ParsePos(string Value, string CardName, integer Counter) {
	if (IsValidVector(Value)) {
		vector LocalPos = (vector)Value;
		return (RootPos + (LocalPos * RootRot));		// return region pos
	}
	else {
		return (Waypoint2Pos(StripQuotes(Value, Value), CardName, Counter));
	}
}
vector GetNpcPos(key NpcId) {
	list NpcDetails = llGetObjectDetails(NpcId, [ OBJECT_POS ]);
	return llList2Vector(NpcDetails, 0);
}
// Given a waypoint name, returns its position (region coords)
vector Waypoint2Pos(string Waypoint, string CardName, integer Counter) {
	integer W = FindWaypoint(Waypoint, CardName, Counter);
	if (W == -1) return RootPos;	// failure
	vector WayPos = llList2Vector(Waypoints, W + WAY_POS);	// note that waypoint positions are in region coords
	return WayPos;
}
integer Waypoint2LinkNum(string Waypoint, string CardName, integer Counter) {
	integer W = FindWaypoint(Waypoint, CardName, Counter);
	if (W == -1) return -1; 		// failure
	W -= WAY_WAYNAME;
	integer LinkNum = -llList2Integer(Waypoints, W + WAY_LINKNUM);	// stored negative
	return LinkNum;
}
// returns point to waypoints table for given waypoint name
integer FindWaypoint(string Waypoint, string CardName, integer Counter) {
	integer W = llListFindList(Waypoints, [ Waypoint ]);
	if (W == -1) {
		ErrorMessage("Invalid waypoint: '" + Waypoint + "' in card '" + CardName + "', line " + (string)Counter);
		return -1;
	}
	W -= WAY_WAYNAME;	// return to start of row
	return W;
}
// Crude test for a string being a vector
// we can't just cast to a vector and test for ZERO_VECTOR, because it might actually need to be a zero vector
integer IsValidVector(string Str) {
	return (llGetSubString(Str, 0, 0) == "<" && llGetSubString(Str, -1, -1) == ">");
}
// Gets environmental info, returns TRUE if script should reboot due to changes
integer ProcessEnvironment() {
	vector NewRootPos = llGetRootPosition();
	rotation NewRootRot = llGetRootRotation();
	integer Return = FALSE;
	if (llVecDist(NewRootPos, RootPos) > 0.001 || NewRootRot != RootRot) Return = TRUE;	// we use VecDist because region restart causes pos to shift slightly
	RootPos = NewRootPos;
	RootRot = NewRootRot;
	return Return;
}
BuildPrimTable() {
	Waypoints = [];
	PrimCount = llGetNumberOfPrims();
	if (PrimCount > 1) {
		integer P;
		for(P = 1; P <= PrimCount; P++) {
			string Name = llGetLinkName(P);
			if (llToLower(Name) == WAYPOINT_NAME) {
				list L = llGetLinkPrimitiveParams(P, [ PRIM_DESC, PRIM_POS_LOCAL ]);
				string WayName = llList2String(L, 0);
				vector WayPos = llList2Vector(L, 1);
				if (P > 1) WayPos = RootPos + (WayPos * RootRot);	// get region pos for child prims
				Waypoints += [ WayName, -P, WayPos ];
			}
		}
	}
	WaypointsLength = llGetListLength(Waypoints);
}
integer IsBehaviourCard(string NotecardName) {
	list Parts = llCSV2List(osGetNotecardLine(NotecardName, 0));
	return (llGetListLength(Parts) == 2 && llList2String(Parts, 0) == BEHAVIOUR_CARD_ID);
}
// Start to play sound (part 1, gets sound id and rezzes speech centre object)
CreateSoundObject(key NpcId, string Sound, string CardName, integer SourceLine) {
	key SoundId = (key)Sound;
	if (SoundId == NULL_KEY) {	// if it's not a UUID
		integer FileType = llGetInventoryType(Sound);
		if (FileType != INVENTORY_SOUND) {
			SourceError("Invalid sound name/id: '" + Sound + "'", CardName, SourceLine);
			return;
		}
		SoundId = llGetInventoryKey(Sound);
	}
	Sounds += llList2CSV([ NpcId, SoundId, SPEECH_CENTER_VOLUME ]);
	llRezObject(SPEECH_CENTER_OBJECT, llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 1);
}
// Second part of playing sound
PlaySoundObject(key ObjectId) {
	if (llGetListLength(Sounds) == 0) {
		ErrorMessage("Orphan speech centre found.");
		return;
	}
	// We don't know which "sound" command triggered this object, but it doesn't matter, just pick the first entry
	string CSVData = llList2String(Sounds, 0);	// pick out CSV containing NPC UUID and sound UUID
	osMessageObject(ObjectId, CSVData);
	Sounds = llDeleteSubList(Sounds, 0, 0);	// delete from queue
}
// Seat NPC
Sit(key NpcId, string Place, string CardName, integer SourceLine) {
	key SitId = GetPrimKey(Place, NpcId);
	if (SitId == NULL_KEY) {
		SourceError("Can't find place to sit: '" + Place + "'", CardName, SourceLine);
		return;
	}
	osNpcSit(NpcId, SitId, OS_NPC_SIT_NOW);
}
// NPC touch
Touch(key NpcId, string Place, string CardName, integer SourceLine) {
	key TouchId = GetPrimKey(Place, NpcId);
	if (TouchId == NULL_KEY) {
		SourceError("Can't find prim to click: '" + Place + "'", CardName, SourceLine);
		return;
	}
	osNpcTouch(NpcId, TouchId, LINK_THIS);
}
key GetPrimKey(string PrimName, key NpcId) {
	key PrimKey = NULL_KEY;
	vector NpcPos = GetNpcPos(NpcId);
	float Nearest = 99999.0;
	integer P;
	for (P = 1; P <= PrimCount; P++) {
		if (llGetLinkName(P) == PrimName) {
			vector PrimPos = RootPos + (llList2Vector(llGetLinkPrimitiveParams(P, [ PRIM_POS_LOCAL ]), 0) * RootRot);
			float Dist = llVecDist(PrimPos, NpcPos);
			if (Dist < Nearest) {
				PrimKey = llGetLinkKey(P);
				Nearest = Dist;
			}
		}
	}
	return PrimKey;
}
// Removes all known NPCs
RemoveNpcs() {
	// create a temporary list to avoid updating a list while navigating it
	list Npcs = [];
	integer B;
	for(B = 0; B < BehavioursLength; B += BEH_STRIDE) {
		key NpcId = llList2Key(Behaviours, B + BEH_NPC_ID);
		Npcs += NpcId;
	}
	integer Count = llGetListLength(Npcs);
	while(Count--) {
		key NpcId = llList2Key(Npcs, Count);
		RemoveNpc(NpcId);
	}
}
// Given an NPC key, removes all related data
RemoveNpc(key NpcId) {
	if (osIsNpc(NpcId)) osNpcRemove(NpcId);
	integer B = llListFindList(Behaviours, [ NpcId ]);
	if (B > -1) {
		B -= BEH_NPC_ID;
		Behaviours = llDeleteSubList(Behaviours, B, B + BEH_STRIDE - 1);
		BehavioursLength -= BEH_STRIDE;
	}
	integer A = llListFindList(Animations, [ NpcId ]);
	if (A > -1) {
		Animations = llDeleteSubList(Animations, A, A + 1);
	}
}
// Report error message
ErrorMessage(string Text) {
	llOwnerSay(Text);
}
// Wrapper for osGetNotecardLine() that removes "//" comments
string GetNotecardLine(string CardName, integer LineNum) {
	string Line = llStringTrim(osGetNotecardLine(CardName, LineNum), STRING_TRIM);
	integer Comment = llSubStringIndex(Line, "//");
	if (Comment == -1) return Line;		// no comment
	if (Comment == 0) return "";	// the line begins with a comment
	// So there is a comment part, so get rid of it
	Line = llGetSubString(Line, 0, Comment - 1);	// strip from comments character onwards
	Line = llStringTrim(Line, STRING_TRIM_TAIL);	// and remove any spaces before "//"
	return Line;
}
// Modified version of classic StripQuotes(), error reporting tweaked for behaviour instructions
string IStripQuotes(string Text, string CardName, integer SourceLine) {
	if (Text == "") {	// allow empty string for null value
		return("");
	}
	if (llGetSubString(Text, 0, 0) == "\"" && llGetSubString(Text, -1, -1) == "\"") { 	// if surrounded by quotes
		return(llGetSubString(Text, 1, -2));	// strip quotes
	}
	else {
		SourceError("Invalid string literal", CardName, SourceLine);
		return("");
	}
}
string SourceError(string ErrorMessage, string CardName, integer SourceLine) {
	return ErrorMessage + " in card '" + CardName + "', line " + (string)SourceLine + ":\n" + osGetNotecardLine(CardName, SourceLine);
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
		ErrorMessage("Invalid string literal (missing \"\"?): " + Line);
		return("");
	}
}
// Returns TRUE if UUID is an player avatar or NPC
integer IsAvatar(key Uuid) {
	return (llGetAgentSize(Uuid) != ZERO_VECTOR);	
}
// Unsit any avatars sitting on prims
Unseat() {
	integer Break = FALSE;
	do {
		key Uuid = llGetLinkKey(llGetNumberOfPrims());
		if (IsAvatar(Uuid))
			llUnSit(Uuid);
		else
			Break = TRUE;
	} while(!Break);
	WasSitting = FALSE;
}
Die() {
	while(1 == 1) {
		llDie();
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
		Unseat();
		ProcessEnvironment();
		BuildPrimTable();
		GetBehaviourCards();
		Animations = [];
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
		llMessageLinked(LINK_ROOT, LM_DELEGATE_DELETION, "", NULL_KEY);		// World object delegates deletion to us
		llSetTimerEvent(TIMER_PERIOD);
	}
	touch_start(integer Count) {
		state Reboot;
	}
	timer() {
		if (ProcessEnvironment()) state Reboot;		// get environment info, reboot if necessary
		ProcessTriggers();
		ProcessCards();
	}
	dataserver(key ObjectId, string Data) {
		if (Data == "SCR") {	// Speech Centre Ready
			PlaySoundObject(ObjectId);
		}
	}
	link_message(integer Sender, integer Number, string Message, key Id)	{
		if (Number == LM_DELETE_RECEIVED) {	// message from rezmela world object
			RemoveNpcs();
			Die();
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) state Reboot;
		if (Change & CHANGED_LINK) {
			// Reboot if link change was not caused by avatar sitting or standing
			integer IsSitting = IsAvatar(llGetLinkKey(llGetNumberOfPrims()));
			if (!WasSitting && !IsSitting) state Reboot;
			WasSitting = IsSitting;
		}
		if (Change & CHANGED_REGION_START) state Reboot;
	}
}
// NPC behaviour v0.2