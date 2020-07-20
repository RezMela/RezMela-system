// Battle scoring server v0.6

// v0.6 - fixed broadcast message
// v0.5 - added scoreboard comms

string OBJECTS_NOTECARD = "Object names";
string CONFIG_NOTECARD = "Battle config";
integer DEFAULT_SCORE = 10;

list Scoreboards;
integer ScoreboardsCount;
string ScoreboardChannel;
integer ScoreboardListener;
integer ScoreboardUpdateCounter;
integer ScoreboardListenCounter;
string LastScoreboard;

integer BATTLE_SCORE_CHANNEL = -2884110;
integer SCOREBOARD_CHAT_CHANNEL = -6447330;

list TeamNames;			// [ TeamName ]
integer TeamCount;
list Objects;			// [ ObjectName, Score, TeamPtr ]
list Undamaged;			// [ UUID, Score, TeamPtr ]
list Destroyed;			// [ UUID, Score, TeamPtr ]

string LastMessage;

ShowStats() {
	string Text = "";
	string ThisScoreboard = "";
	SendToScoreboards("DR");
	SendToScoreboards("DH" + "POINTS REMAINING");
	Text += "Points remaining by team";
	integer TeamNum;
	for (TeamNum = 0; TeamNum < TeamCount; TeamNum++) {
		string TeamName = llList2String(TeamNames, TeamNum);
		integer UndamagedScore = GetScore(Undamaged, TeamNum);
		integer DestroyedScore = GetScore(Destroyed, TeamNum);
		integer TotalScore = UndamagedScore + DestroyedScore;
		string Description = TeamName + ": " + (string)UndamagedScore+ "/" + (string)TotalScore;
		Text += "\n" + Description;
		if (TeamNum < 10) {
			SendToScoreboards("DL" + (string)TeamNum + "," + Description);
			ThisScoreboard += (string)TeamNum + "," + Description;
		}
	}
	if (ThisScoreboard != LastScoreboard) {
		SendToScoreboards("DD");
		LastScoreboard = ThisScoreboard;
	}
	llSetText(Text, <1.0, 0.0, 0.0>, 1.0);
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
NotifyHit(string ObjectName, integer TeamPtr, integer Score) {
	string TeamName = llList2String(TeamNames, TeamPtr);
	integer UndamagedScore = GetScore(Undamaged, TeamPtr);
	integer DestroyedScore = GetScore(Destroyed, TeamPtr);
	integer TotalScore = UndamagedScore + DestroyedScore;
	BroadcastMessage(TeamName + " team lost " + (string)Score + " points (" + (string)UndamagedScore + " remaining)");
}
//Return total score for team from undamaged or destroyed list
integer GetScore(list List, integer TeamPtr) {
	integer TotScore = 0;
	list RetList = [];
	integer Len = llGetListLength(List);
	integer I;
	for(I = 0; I < Len; I += 3) {
		integer ThisTeam = llList2Integer(List, I + 2);
		if (ThisTeam == TeamPtr) {
			integer ThisScore = llList2Integer(List, I + 1);
			TotScore += ThisScore;
		}
	}
	return TotScore;
}
integer ReadObjectsNotecard() {
	integer CurrentTeamPtr = -1;
	TeamNames = [];
	Objects = [];
	Undamaged = [];
	Destroyed = [];
	if (llGetInventoryType(OBJECTS_NOTECARD) != INVENTORY_NOTECARD) {	// if notecard doesn't exist
		NotecardError("Can't open notecard '" + OBJECTS_NOTECARD + "'", -1);
		return FALSE;
	}
	integer Lines = osGetNumberOfNotecardLines(OBJECTS_NOTECARD);
	integer LineNum;
	for(LineNum = 0; LineNum < Lines; LineNum++) {
		string Line = llStringTrim(osGetNotecardLine(OBJECTS_NOTECARD, LineNum), STRING_TRIM);
		integer Comment = llSubStringIndex(Line, "//");
		if (Comment != 0) {	// Not a complete comment line
			if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);	// strip from comments characters onwards
			if (llStringTrim(Line, STRING_TRIM) != "") {	// if there's something left after comments are removed
				if (llGetSubString(Line, 0, 0) == "*") {	// Team name lines start with *
					CurrentTeamPtr++;
					string TeamName = llGetSubString(Line, 1, -1);
					TeamNames += TeamName;
				}
				else {
					if (CurrentTeamPtr < 0) {
						NotecardError("Missing team name", LineNum);
						return FALSE;
					}
					else {
						integer X = llListFindList(Objects, [ Line ]);
						if (X > -1) {
							NotecardError("Duplicate object name '" + Line + "'", LineNum);
						}
						else {
							// Finally, a valid object line
							list ObjectData = llCSV2List(Line);
							string ObjectName = llList2String(ObjectData, 0);
							integer Score = DEFAULT_SCORE;
							if (llGetListLength(ObjectData) > 1) Score = (integer)llList2String(ObjectData, 1);
							Objects += [ ObjectName, Score, CurrentTeamPtr ];
						}
					}
				}
			}
		}
	}
	TeamCount = llGetListLength(TeamNames);
	return TRUE;
}
NotecardError(string Text, integer LineNum) {
	if (LineNum >= 0) {
		Text = "Error in line " + (string)(LineNum + 1) + ": " + Text;
	}
	else {
		Text = "Error: " + Text;
	}
	llOwnerSay(Text);
}
list DeleteRow(list List, key Uuid) {
	integer P = llListFindList(List, [ Uuid ]);
	if (P > -1)
		return llDeleteSubList(List, P, P + 2);
	else
		return List;
}
list AddRow(list List, key Uuid, integer Score, integer TeamPtr) {
	list RetList = List;
	// if it already exists, delete it
	integer P = llListFindList(RetList, [ Uuid ]);
	if (P > -1) {
		RetList = DeleteRow(RetList, Uuid);
	}
	// Add new row
	RetList += [ Uuid, Score, TeamPtr ];
	return RetList;
}
ReadConfig() {
	// Set config defaults
	ScoreboardChannel = "Battle";
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
					if (Name == "scoreboard")	ScoreboardChannel = StripQuotes(Value, Line);
					else llOwnerSay("Invalid parameter name in '" + CONFIG_NOTECARD + "': " + OName);
				}
				else {
					llOwnerSay("Invalid line in '" + CONFIG_NOTECARD + "': " + Line);
				}
			}
		}
	}
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
		ReadObjectsNotecard();
		ReadConfig();
		Scoreboards = [];
		ScoreboardsCount = 0;
		ScoreboardListen();
		llSetTimerEvent(1.0);
		llListen(BATTLE_SCORE_CHANNEL, "", NULL_KEY, "");
		ScoreboardUpdateCounter = 0;

	}
	listen(integer Channel, string Name, key Uuid, string Message) {
		if (Channel == BATTLE_SCORE_CHANNEL) {
			integer P = llListFindList(Objects, [ Name ]);
			if (P == -1) {
				llOwnerSay("Unknown object name: '" + Name + "' ignored");
				return;
			}
			integer Score = llList2Integer(Objects, P + 1);
			integer TeamPtr = llList2Integer(Objects, P + 2);
			integer IsDestroyed = (integer)Message;		// Message is 1 if destroyed, 0 if not
			if (IsDestroyed) {
				Undamaged = DeleteRow(Undamaged, Uuid);
				Destroyed = AddRow(Destroyed, Uuid, Score, TeamPtr);
				NotifyHit(Name, TeamPtr, Score);	// tell avatars about hit
			}
			else {
				Destroyed = DeleteRow(Destroyed, Uuid);
				Undamaged = AddRow(Undamaged, Uuid, Score, TeamPtr);
			}
			ScoreboardUpdateCounter = 4;
		}
		else if (Channel == SCOREBOARD_CHAT_CHANNEL) {
			if (Message == "S" + ScoreboardChannel) {	// handshaking message from scoreboard is "S<channel>"
				if (llListFindList(Scoreboards, [ Uuid ]) == -1) {
					osMessageObject(Uuid, "DC");
					Scoreboards += Uuid;
					ScoreboardsCount++;
					ScoreboardUpdateCounter = 2;
				}
			}
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
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			llResetScript();
		}
	}
}
// Battle scoring server v0.6