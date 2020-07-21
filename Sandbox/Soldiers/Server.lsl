// Server

// Notes on dead lists:
//
// The string list of dead NPCs consists of the first 5 characters of dead NPCs' UUIDs, each followed by "|".
// For example, "99fda|a2a41|4767a|" is a list of three partial UUIDs.
// The reasons we do this are: (1) We don't need the full UUID, just enough of it to be pretty sure of
// uniqueness - we'd need half a million NPCs before we had an even chance of a duplicate. (2) We can squeeze them all
// into a single 1024-char-max string for messaging (1024 / 6 > 170 potential casualties). (3) That's cheaper and faster
// to transmit than using a list. We separate each with "|" so that UUID fragments are separated from each another.
//
integer CHAT_CHANNEL = 29904047;		// chat channel for death notices, etc

float RemoveTime = 10.0;		// time in seconds before dead NPCs are deleted (0.0 for no deletion)
// Parallel lists (cheaper than strided lists)
list DeadList;		// list of dead NPCs' UUIDS
list DeadTimes;		// list of times recorded (llGetTime)
string DeadString;	// string version of DeadList, with partial UUIDs separated by "|"

// SetDeadString creates a string of deads to transmist to the weapons
// We only rebuild the deadstring when it's been nulled. See notes above
SetDeadString() {
	if (DeadString == "") {
		integer P = llGetListLength(DeadList);
		while(P--) {
			string sID = (string)llList2Key(DeadList, P);
			DeadString += llGetSubString(sID, 0, 4) + "|";
		}
	}
}
// Null the deadstring to force rebuilding - use this when the list has changed
DeadListChanged() {
	DeadString = "";
}
// NotInList() - returns true if NPC is not in dead list
integer NotInList(key Id) {
	return (llListFindList(DeadList, [ Id ]) == -1);
}
// Entry state - one-off initial processing
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		state Normal;
	}
}
// Normal running state
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llListen(CHAT_CHANNEL, "", NULL_KEY, "");
		if (RemoveTime > 0.0) llSetTimerEvent(2.0);
	}
	listen(integer Channel, string Name, key Id, string Message)
	{
		string MessageType = llGetSubString(Message, 0, 0);		// first character of message is the type
		if (MessageType == "R") {		// it's a request for the dead-list
			SetDeadString();
			llRegionSayTo(Id, CHAT_CHANNEL, "L" + DeadString);
		}
		else if (MessageType == "D") {		// it's a death announcement
			key DeadUuid = (key)llGetSubString(Message, 1, -1);
			if (NotInList(DeadUuid)) {
				DeadList += DeadUuid;
				DeadTimes += llGetTime();
				DeadListChanged();
			}
		}
	}
	timer() {
		// remove dead NPCs whose time has expired
		float CutOff = llGetTime() - RemoveTime;		// time before which NPCs are removed
		// entries are stored oldest first
		while(llList2Float(DeadTimes, 0) < CutOff && llGetListLength(DeadList) > 0) {	// compare time NPC dies against cut-off time
			osNpcRemove(llList2Key(DeadList, 0));
			DeadList = llDeleteSubList(DeadList, 0, 0);		// delete first entry
			DeadTimes = llDeleteSubList(DeadTimes, 0, 0);
			DeadListChanged();
		}
	}
}
// Server