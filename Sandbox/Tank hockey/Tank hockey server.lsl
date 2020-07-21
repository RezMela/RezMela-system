// Tank hockey server v0.4

// v0.4 - added rezzing of pucks
// v0.3 - changed to "other team" scoring
// v0.2 - removed "have" from "scored" message

string CONFIG_NOTECARD = "Tank hockey config";

integer TH_CHAT_CHANNEL = -3920100;
integer SCOREBOARD_CHAT_CHANNEL = -6447330;

key MyUuid;

integer ScoreIncrement;
float SplitDistance;	// how far (horizontally) from parent child objects should be
float SplitHeight;
integer MaxGeneration;
float PhysDelay;
vector CentrePos;
vector PitchSize;
float CentrePush;		// factor of force applied to push towards centre
float NeutralArea;		// proportion of pitch which has no tendency towards centre
float ShrinkFactor;		// eg 0.5 for children half-sized
integer TouchToDestroy;	// can you touch the puck to destroy it? (for testing)

list Scoreboards;
integer ScoreboardsCount;
string ScoreboardChannel;
integer ScoreboardListener;
integer ScoreboardUpdateCounter;
integer ScoreboardListenCounter;
string LastScoreboard;

key PuckSound;

string LastMessage;

vector RezPos;
integer StartParam;
string PuckObjectName;

list PuckList;
integer PUCK_UUID = 0;
integer PUCK_INITIALISED = 1;		// integer (bool) has puck been initialised?
integer PUCK_GENERATION = 2;		// integer
integer PUCK_STARTPOS = 3;			// vector
integer PUCK_STRIDE = 4;

// Parallel lists
list TeamNames;			// [ string TeamName ]
list TeamScores;		// [ integer TeamScore ]
list GoalUuids;			// [ key GoalUuid ]
integer TeamCount;

// Delegated deletion stuff
integer LM_DELEGATE_DELETION = -7044001;
integer LM_DELETE_RECEIVED = -7044002;

// rez a new puck (not a child puck)
CreateParentPuck() {
	CreatePuck();
	AddPuckToList(1, CentrePos);	// add generation 1 to list
}
CreateChildPucks(integer Generation, vector PuckPos) {
	vector ChildPos1 = PuckPos + <SplitDistance, SplitDistance, SplitHeight>;
	vector ChildPos2 = PuckPos + <-SplitDistance, -SplitDistance, SplitHeight>;
	CreatePuck();
	AddPuckToList(Generation, ChildPos1);
	CreatePuck();
	AddPuckToList(Generation, ChildPos2);
}
CreatePuck() {
	llRezObject(PuckObjectName, RezPos, ZERO_VECTOR, ZERO_ROTATION, 1);
}
AddPuckToList(integer Generation, vector StartPos) {
	PuckList += [ NULL_KEY, FALSE, Generation, StartPos ];
}
UpdatePucks() {
	integer Len = llGetListLength(PuckList);
	integer P;
	for (P = 0; P < Len; P += PUCK_STRIDE) {
		integer Initialised = llList2Integer(PuckList, P + PUCK_INITIALISED);
		if (!Initialised) {
			key PuckUuid = llList2Key(PuckList, P + PUCK_UUID);
			integer Generation = llList2Integer(PuckList, P + PUCK_GENERATION);
			vector StartPos = llList2Vector(PuckList, P + PUCK_STARTPOS);
			MessageObject(PuckUuid, "G" + PuckData(Generation, StartPos));
		}
	}
}
// build data to send to puck for given generation
string PuckData(integer Generation, vector StartPos) {
	return llList2CSV([
		Generation,
		StartPos,
		CentrePos,
		ShrinkFactor / (Generation - 1),	// ie ShrinkBy
		PhysDelay,
		CentrePos,
		PitchSize,
		NeutralArea,
		CentrePush,
		PuckSound,
		TouchToDestroy
			]);
}
ShowStats() {
	//	string Text = "";
	string ThisScoreboard = "";
	SendToScoreboards("DR");
	SendToScoreboards("DH" + "SCORES");
	//	Text += "Points remaining by team";
	integer TeamNum;
	for (TeamNum = 0; TeamNum < TeamCount; TeamNum++) {
		string TeamName = llList2String(TeamNames, TeamNum);
		integer Score = llList2Integer(TeamScores, TeamNum);
		string Description = TeamName + ": " + (string)Score;
		//		Text += "\n" + Description;
		if (TeamNum < 10) {
			SendToScoreboards("DL" + (string)TeamNum + "," + Description);
			ThisScoreboard += (string)TeamNum + "," + Description;
		}
	}
	if (ThisScoreboard != LastScoreboard) {
		SendToScoreboards("DD");
		LastScoreboard = ThisScoreboard;
	}
	//	llSetText(Text, <1.0, 0.0, 0.0>, 1.0);
}
// Send Text to all scoreboards
SendToScoreboards(string Text) {
	integer P;
	for (P = 0; P < ScoreboardsCount; P++) {
		MessageObject(llList2Key(Scoreboards, P), Text);
	}
}
// Wrapper for osMessageObject() that checks to see if object exists
MessageObject(key Uuid, string Text) {
	if (ObjectExists(Uuid)) {
		osMessageObject(Uuid, Text);
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
integer ReadConfig() {
	// Set config defaults
	ScoreboardChannel = "Hockey";
	ScoreIncrement = 1;
	SplitDistance = 5.0;
	SplitHeight = 3.0;
	CentrePos = ZERO_VECTOR;
	PitchSize = ZERO_VECTOR;
	NeutralArea = 0.5;
	CentrePush = 8.0;
	ShrinkFactor = 0.5;
	MaxGeneration = 3;
	PhysDelay = 0.0;
	TouchToDestroy = FALSE;
	//
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Can't find notecard '" + CONFIG_NOTECARD + "'");
		return FALSE;
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
					if (Name == "scoreboard")	ScoreboardChannel = StripQuotes(Value, Line);
					else if (Name == "scoreincrement") ScoreIncrement = (integer)Value;
					else if (Name == "center")	CentrePos = (vector)Value;
					else if (Name == "pitchsize") PitchSize = Vector2Dto3D(Value);
					else if (Name == "margin") NeutralArea = 1.0 - (float)Value;
					else if (Name == "centerpush") CentrePush = (float)Value;
					else if (Name == "shrinkfactor") ShrinkFactor = (float)Value;
					else if (Name == "splitdistance") SplitDistance = (float)Value;
					else if (Name == "splitheight") SplitHeight = (float)Value;
					else if (Name == "maxgeneration") MaxGeneration = (integer)Value;
					else if (Name == "physdelay") PhysDelay = (float)Value;
					else if (Name == "touchtodestroy") TouchToDestroy = String2Bool(Value);
					else llOwnerSay("Invalid parameter name in '" + CONFIG_NOTECARD + "': " + OName);
				}
				else {
					llOwnerSay("Invalid line in '" + CONFIG_NOTECARD + "': " + Line);
				}
			}
		}
	}
	if (CentrePos == ZERO_VECTOR) { llOwnerSay("ERROR: centre of pitch not specified"); return FALSE; }
	if (PitchSize == ZERO_VECTOR) { llOwnerSay("ERROR: pitch size not specified"); return FALSE; }
	return TRUE;
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
// convert (eg) string "123,456" to vector <123, 456, 0>
vector Vector2Dto3D(string Values) {
	vector Ret = ZERO_VECTOR;
	list L = llCSV2List(Values);
	Ret.x = llList2Float(L, 0);
	Ret.y = llList2Float(L, 1);
	return Ret;
}

BroadcastMessage(string Text) {
	if (Text == LastMessage) return;		// prevent duplicates
	LastMessage = Text;
	list AvIds = llGetAgentList(AGENT_LIST_REGION, []);
	integer AvsCount = llGetListLength(AvIds);
	integer A;
	for(A = 0; A < AvsCount; A++) {
		llRegionSayTo(llList2Key(AvIds, A), 0, Text);
	}
}
ScoreboardListen() {
	if (ScoreboardListener) {
		llListenRemove(ScoreboardListener);
		ScoreboardListener = 0;
	}
	ScoreboardListener = llListen(SCOREBOARD_CHAT_CHANNEL, "", NULL_KEY, "");
	ScoreboardListenCounter = 10;
}
DeleteAllPucks() {
	integer Len = llGetListLength(PuckList);
	integer P;
	for (P = 0; P < Len; P += PUCK_STRIDE) {
		key PuckUuid = llList2Key(PuckList, P + PUCK_UUID);
		MessageObject(PuckUuid, "X");		// send die signal to puck
	}
}
Die() {
	while(1 == 1) {
		llDie();
	}
}
default {
	on_rez(integer Param) {
		llResetScript();
	}
	state_entry(){
		state Normal;
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		StartParam = llGetStartParameter();
		MyUuid = llGetKey();
		RezPos = llGetPos() + <0.0, 0.0, 5.0>;
		if (!ReadConfig()) return;
		Scoreboards = [];
		ScoreboardsCount = 0;
		ScoreboardListen();
		TeamNames = [];
		TeamScores = [];
		GoalUuids = [];
		TeamCount = 0;
		llSetTimerEvent(1.0);
		llListen(TH_CHAT_CHANNEL, "", NULL_KEY, "");
		ScoreboardUpdateCounter = 0;
		PuckObjectName = llGetInventoryName(INVENTORY_OBJECT, 0);
		if (PuckObjectName == "") {
			llOwnerSay("Puck object missing from inventory");
			return;
		}
		PuckSound = llGetInventoryKey(llGetInventoryName(INVENTORY_SOUND, 0));
		if (StartParam) {	// if rezzed by control board
			CreateParentPuck();
		}
	}
	listen(integer Channel, string Name, key Uuid, string Message) {
		if (Channel == TH_CHAT_CHANNEL && Uuid != MyUuid) {
			string Command = llGetSubString(Message, 0, 0);
			string TeamName = llGetSubString(Message, 1, -1);
			if (Command == "G") { 		// ping from goal
				integer P = llListFindList(TeamNames, [ TeamName ]);
				if (P == -1) {
					TeamNames += TeamName;
					TeamScores += 0;
					GoalUuids += Uuid;
					TeamCount++;
					ScoreboardUpdateCounter = 4;
				}
			}
			else if (Command == "S") {		// goal scored
				if (TeamCount != 2) {
					llOwnerSay("Can't display score - teams found: " + (string)TeamCount);
					return;
				}
				integer TeamPtr = llListFindList(TeamNames, [ TeamName ]);
				integer OtherTeamPtr;
				if (TeamPtr  == 1) OtherTeamPtr = 0; else OtherTeamPtr = 1;
				string OtherTeamName = llList2String(TeamNames, OtherTeamPtr);
				BroadcastMessage(OtherTeamName + " scored!");
				integer Score = llList2Integer(TeamScores, OtherTeamPtr);
				Score += ScoreIncrement;
				TeamScores = llListReplaceList(TeamScores, [ Score ], OtherTeamPtr, OtherTeamPtr);
				ScoreboardUpdateCounter = 4;
			}
			else if (Command == "R") {		// goal reset
				// delete pucks and rez another
				DeleteAllPucks();
				CreateParentPuck();
			}
		}
		else if (Channel == SCOREBOARD_CHAT_CHANNEL) {
			if (Message == "S" + ScoreboardChannel) {	// handshaking message from scoreboard is "S<channel>"
				if (llListFindList(Scoreboards, [ Uuid ]) == -1) {
					MessageObject(Uuid, "DC");
					Scoreboards += Uuid;
					ScoreboardsCount++;
					ScoreboardUpdateCounter = 2;
				}
			}
		}
	}
	object_rez(key Uuid) {
		// find an empty slot (a record that's been added with null key because it's not known yet, but is now)
		integer P = llListFindList(PuckList, [ NULL_KEY ]);
		if (P == -1) {
			llOwnerSay("Can't find empty puck UUID in list!");
			return;
		}
		PuckList = llListReplaceList(PuckList, [ Uuid ], P, P);
	}
	dataserver(key Uuid, string Data) {
		string DataType = llGetSubString(Data, 0, 1);
		if (Data == "G") {		// ACK from child
			integer P = llListFindList(PuckList, [ Uuid ]);
			if (P == -1) {
				llOwnerSay("Response from unknown puck: '" + llKey2Name(Uuid) + "': " + (string)Uuid);
				return;
			}
			P -= PUCK_UUID;	// position at start of stride
			// set "initialised" field to TRUE because it's now initialised
			integer InitialisedPtr = P + PUCK_INITIALISED;
			PuckList = llListReplaceList(PuckList, [ TRUE ], InitialisedPtr, InitialisedPtr);
		}
		else if (DataType == "DP") {		// Child dies, data is "D"<pos>
			vector PuckPos = (vector)llGetSubString(Data, 2, -1);
			integer P = llListFindList(PuckList, [ Uuid ]);
			if (P == -1) {
				llOwnerSay("Death of unknown puck: '" + llKey2Name(Uuid) + "': " + (string)Uuid);
				return;
			}
			P -= PUCK_UUID;	// position at start of stride
			integer Generation = llList2Integer(PuckList, P + PUCK_GENERATION);
			PuckList = llDeleteSubList(PuckList, P, P + PUCK_STRIDE - 1);
			// create children
			if (Generation < MaxGeneration) {
				integer NewGeneration = Generation + 1;
				CreateChildPucks(NewGeneration, PuckPos);
			}
		}
	}
	touch_start(integer Count) {
		CreateParentPuck();
	}
	link_message(integer Sender, integer Number, string Message, key Id)	{
		if (Number == LM_DELETE_RECEIVED) {		// delete from control board
			// So delete all the pucks out there
			DeleteAllPucks();
			Die();
		}
	}
	timer() {
		if (--ScoreboardUpdateCounter <= 0) {
			ShowStats();
			ScoreboardUpdateCounter = 3;
		}
		ScoreboardListenCounter--;
		if (ScoreboardListenCounter == 7) {
			llListenRemove(ScoreboardListener);
			ScoreboardListener = 0;
		}
		else if (ScoreboardListenCounter == 0) {
			ScoreboardListen();	// resets ScoreboardListenCounter to 10
		}
		llMessageLinked(LINK_THIS, LM_DELEGATE_DELETION, "", NULL_KEY);
		UpdatePucks();
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			llResetScript();
		}
	}
}
// Tank hockey server v0.4