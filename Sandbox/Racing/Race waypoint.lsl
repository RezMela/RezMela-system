// Race waypoint v0.3

// v0.3 - fixed bug in sensor type value looping

string CONFIG_NOTECARD = "Waypoint config";

integer CHAT_CHANNEL = -8300371400;

key StartObjectUuid;

list KnownObjects;

// Types of sensor (agent, scripted, etc)
list SensorTypes;
integer SensorTypePtr;
integer SensorTypesCount;

// Config details
float SensorRange;
integer UseCollisions;

ReadConfig() {
	// Set config defaults
	SensorRange = 0.0;
	UseCollisions = FALSE;
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
					else llOwnerSay("Invalid parameter name in '" + CONFIG_NOTECARD + "': " + OName);
				}
				else {
					llOwnerSay("Invalid line in '" + CONFIG_NOTECARD + "': " + Line);
				}
			}
		}
	}
}
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
Detected(key Uuid, integer Type) {
	if (StartObjectUuid == NULL_KEY) return;
	if (llListFindList(KnownObjects, [ Uuid ]) == -1) {
		string sType = "";
		if (Type & AGENT || Type & OS_NPC) sType = "A"; else sType = "V";
		osMessageObject(StartObjectUuid, "%" + llList2CSV([ Uuid, sType ]));
		KnownObjects += Uuid;
	}
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		ReadConfig();
		StartObjectUuid = NULL_KEY;
		KnownObjects = [];
		llSetTimerEvent(0.5);
	}
	dataserver(key QueryId, string Data) {
		if (llGetSubString(Data, 0, 0) == "@") {
			StartObjectUuid = QueryId;
			SensorTypes = llParseStringKeepNulls(llGetSubString(Data, 1, -1), [ "|" ], []);
			SensorTypesCount = llGetListLength(SensorTypes);
		}
		// any other message should come from known start line
		else if (QueryId == StartObjectUuid) {
			if (Data == "c") {	// clear list
				KnownObjects = [];
			}
		}
	}
	collision_start(integer Count) {
		if (UseCollisions) {
			while(Count--) {
				Detected(llDetectedKey(Count), llDetectedType(Count));
			}
		}
	}
	sensor(integer Count) {
		while(Count--) {
			Detected(llDetectedKey(Count), llDetectedType(Count));
		}
	}
	timer() {
		llRegionSay(CHAT_CHANNEL, "+");
		if (SensorRange > 0.0) {
			integer SensorType = llList2Integer(SensorTypes, SensorTypePtr++);
			if (SensorTypePtr >= SensorTypesCount) SensorTypePtr = 0;
			llSensor("", NULL_KEY, SensorType, SensorRange, PI);
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llResetScript();
	}	
}
// Race waypoint v0.3