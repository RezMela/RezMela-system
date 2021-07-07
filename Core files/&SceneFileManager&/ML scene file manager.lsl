// ML scene file manager v1.3.3

// DEEPSEMAPHORE CONFIDENTIAL
// __
//
//  [2018] - [2028] DEEPSEMAPHORE LLC
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of DEEPSEMAPHORE LLC and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to DEEPSEMAPHORE LLC
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from DEEPSEMAPHORE LLC. For more information, or requests for code inspection,
// or modification, contact support@rezmela.com

// v1.3.3 - allow export of multi-card saves
// v1.3.2 - more efficient saving of large data
// v1.3.1 - add script PIN
// v1.3.0 - change method of sending lists
// v1.2 - changed logic for communicating "end of save" to communicator
// v1.1 - enhancements for apps-in-apps, check notecard size for every line
// v1.0 - version change only
// v0.9 - import/export added; get rid of spurious blank lines at end of data
// v0.8 - change how data is split across notecards (don't try to keep sections in a single card)
// v0.7 - fix bug affecting very large sections (which were not splitting correctly); reduce maximum size
// v0.6 - further work on apps in maps
// v0.5 - incremented version number to avoid confusion with misnamed script distributed in-world
// v0.4 - add dump of all save files for apps in maps
// v0.3 - split large files into multiples
// v0.2 - added deletion of saved scenes

// Note that notecard contents are sent/received as base 64 because contents are theoretically unknown
// and may cause parsing issues

integer MAX_CARD_SIZE = 60000;    // Maximum notecard size in bytes. Actually 64K, but we leave a margin

integer SCRIPT_PIN = -19318100;

integer SFM_LIST = -3310420;
integer SFM_LOAD = -3310421;
integer SFM_SAVE = -3310422;
integer SFM_DELETE = -3310423;
integer SFM_BACKUP = -3310424;
integer SFM_SAVE_COMPLETE = -3310425;
integer SFM_EXPORT = -3310426;
integer SFM_DELETE_ALL = -3310427;

string SFM_NAME = "&SceneFileManager&";    // Name of SFM prim (also in ML main script)

integer ModifyingContents = FALSE; // TRUE while we're making changes to contents

string Load(string Name) {
	string Contents = "";
	list CardNames = GetAllCards(Name);
	integer  Len = llGetListLength(CardNames);
	integer C;
	for (C = 0; C < Len; C++) {
		string CardName = llList2String(CardNames, C);
		Contents += osGetNotecard(CardName);
	}
	return Contents;
}
Save(string Name, string Contents) {
	integer Chars = llStringLength(Contents);
	if (Chars > MAX_CARD_SIZE) {
		integer CardNum = 1;
		integer CardStart = 0;
		list CardLines = [];
		integer CardSize = 0;
		list Lines = llParseStringKeepNulls(Contents, [ "\n" ], []);
		integer Len = llGetListLength(Lines);
		integer L;
		for (L = 0; L < Len; L++) {
			string Line = llList2String(Lines, L);
			CardSize += (llStringLength(Line) + 1);    // +1 because of \n that will be appended during write
			//            if (L % 10 == 0 || L == Len -1) {    // Every 10 lines, and at the end, check the card size
			CardLines = llList2List(Lines, CardStart, L);
			if (CardSize > MAX_CARD_SIZE) {
				WriteNumberedCard(Name, CardNum, CardLines);
				CardStart = L + 1;
				CardNum++;
				CardLines = [];
				CardSize = 0;
			}
			//            }
		}
		WriteNumberedCard(Name, CardNum, CardLines);
	}
	else {
		osMakeNotecard(Name, Contents);
	}
	llMessageLinked(LINK_ROOT, SFM_SAVE_COMPLETE, "", NULL_KEY);
}
integer IsNumberedCard(string Name) {
	if (CardExists(Name)) return 0;
	else if (CardExists(GetNumberedCardName(Name, 1))) return 1;
	else return -1;    // shouldn't happen
}
WriteNumberedCard(string CardName, integer CardNum, list CardLines) {
	osMakeNotecard(GetNumberedCardName(CardName, CardNum), CardLines);
}
string GetNumberedCardName(string Name, integer CardNum) {
	string S = (string)CardNum;
	if (CardNum < 10) S = "00" + S;
	else if (CardNum < 100) S = "0" + S;
	return Name + "_" + S;
}
// List all notecard names with a given root.
// Note that it will list both numbered and non-numbered (bear in mind that
// a save can take given card from one to the other or vice-vera if it crosses
// the max size threshold)
list GetAllCards(string RootName) {
	list CardNames = [];
	if (CardExists(RootName)) CardNames += RootName;    // single-volume is easy
	integer N = 1;
	while (N > 0) {
		string Name = GetNumberedCardName(RootName, N);
		if (CardExists(Name)) {
			CardNames += Name;
			N++;
		}
		else {
			N = 0;    // break the loop
		}
	}
	return CardNames;
}
Delete(string Name) {
	list CardNames = GetAllCards(Name);
	integer  Len = llGetListLength(CardNames);
	integer C;
	for (C = 0; C < Len; C++) {
		string CardName = llList2String(CardNames, C);
		llRemoveInventory(CardName);
	}
}
DeleteAll() {
	integer Len = llGetInventoryNumber(INVENTORY_NOTECARD);
	list Cards = [];
	integer C;
	for (C = 0; C < Len; C++) {
		Cards += llGetInventoryName(INVENTORY_NOTECARD, C);
	}
	for (C = 0; C < Len; C++) {
		llRemoveInventory(llList2String(Cards, C));
	}
}
// Dumps all files, serialized to Base64 strings, and sends to ML as a single Base64
// The reason for the two levels of base64 is (a) to avoid characters in the save messing with
// the format, and (b) the same at a higher level (with the name). Plus we save memory,
// of course, but we would only need one level for that.
Backup() {
	string Dump = "";
	integer SeparatorNeeded = FALSE;
	integer Num = llGetInventoryNumber(INVENTORY_NOTECARD);
	integer Ptr;
	for (Ptr = 0; Ptr < Num; Ptr++) {
		if (SeparatorNeeded) Dump += "^";
		string Name = llGetInventoryName(INVENTORY_NOTECARD, Ptr);
		if (!IsPreset(Name)) {
			string Data64 = llStringToBase64(osGetNotecard(Name));
			Dump += Name + "|" + Data64;
			SeparatorNeeded = TRUE;
		}
	}
	llMessageLinked(LINK_ROOT, SFM_BACKUP, Dump, NULL_KEY);
	Dump = "";
}
integer IsPreset(string Name) {
	return (llGetSubString(Name, 0, 0) == "_");
}
Export(key UserId, string Filename) {
	if (llGetInventoryType(Filename) == INVENTORY_NOTECARD) {
		llGiveInventory(UserId, Filename);
	}
	else {
		list ActualNames = [];
		// Maybe it's the base name of a multi-card save
		string ActualName;
		integer Part = 1;
		// Remember, = assignations return the value of the assignation, so can be tested on
		while((ActualName = MultiCardName(Filename, Part)) != "") {
			ActualNames += ActualName;
			Part++;
		}
		if (ActualNames != []) {
			llGiveInventoryList(UserId, "RezMex: " + Filename, ActualNames);
		}
		else {
			llRegionSayTo(UserId, 0, "Can't find save file: '" + Filename + "'");
		}
	}
}
// Returns name of given part of save, or null if no such notecard
string MultiCardName(string BaseName, integer PartNumber) {
	string Filename = GetNumberedCardName(BaseName, PartNumber);
	if (llGetInventoryType(Filename) == INVENTORY_NOTECARD)
		return Filename;
	else
		return "";
}
List() {
	list NotecardNames =  [];
	integer Num = llGetInventoryNumber(INVENTORY_NOTECARD);
	integer Ptr;
	for (Ptr = 0; Ptr < Num; Ptr++) {
		string Name = llGetInventoryName(INVENTORY_NOTECARD, Ptr);
		if (llGetSubString(Name, -4, -4) == "_") {    // If it's a numbered card
			if (llGetSubString(Name, -3, -1) == "001") {    // Only pick the first
				Name = llGetSubString(Name, 0, -5);        // and strip off the extension
			}
			else {
				Name = "";    // Ignore numbers > 1
			}
		}
		if (Name != "") NotecardNames += Name;
	}
	llMessageLinked(1, SFM_LIST, llDumpList2String(NotecardNames, "|"), NULL_KEY);
}
integer TableSize(list Table) {
	return llStringLength(llDumpList2String(Table, "\n"));
}
integer CardExists(string Name) {
	return (llGetInventoryType(Name) == INVENTORY_NOTECARD);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		llSetRemoteScriptAccessPin(SCRIPT_PIN);
		if (llGetObjectName() != SFM_NAME) {
			llOwnerSay("WARNING: SFM prim name should be '" + SFM_NAME + "'!");
		}
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Sender == 1) {    // Only process linked messages from root prim
			if (Number == SFM_LIST) {
				List();
			}
			else if (Number == SFM_LOAD) {
				// Load message has <name>|<meta1>|<meta2|<...>
				// Meta here means metadata that the client application has request we pass back to it along with the notecard.
				// In this way, the client can persist data between the request and the receipt.
				list Parts = llParseStringKeepNulls(String, [ "|" ], []);
				string NotecardName = llList2String(Parts, 0);
				list Meta = [ NotecardName ];    // First item of metadata is always notecard name
				if (llGetListLength(Parts) > 1) Meta += llList2List(Parts, 1, -1);
				// Now get the data and the meta sent to us, and pass it back (we also pass back the Id)
				Parts = llStringToBase64(Load(NotecardName)) + Meta;
				llMessageLinked(1, SFM_LOAD, llDumpList2String(Parts, "|"), Id);
			}
			else if (Number == SFM_SAVE) {
				list Parts = llParseStringKeepNulls(String, [ "|" ], []);
				Save(llList2String(Parts, 0), llBase64ToString(llList2String(Parts, 1)));
				List();
			}
			else if (Number == SFM_DELETE) {
				Delete(String);
				if (Id == NULL_KEY) {
					List();
				}
			}
			else if (Number == SFM_DELETE_ALL) {
				DeleteAll();
				List();
			}
			else if (Number == SFM_BACKUP) {
				Backup();
			}
			else if (Number == SFM_EXPORT) {    // this comes from the HUD communicator
				Export(Id, String);
			}
		}
	}
}
// ML scene file manager v1.3.3