// PortaGlossa server v0.1

string NOTECARD_LANGUAGES = "Languages";
string NOTECARD_WORDS = "Words";
string NOTECARD_PHRASES = "Phrases";
string NOTECARD_ADMINS = "Admins";
string NOTECARD_SEPARATOR = "|";
string SEPARATOR_DATA = "|";
string SEPARATOR_WORD_ENTRY = "^";

//string KEYWORD_TYPE_LEARNING = "learningnoun";
//string KEYWORD_TYPE_MUTIPLE_CHOICE = "multiplechoice";
//string KEYWORD_TYPE_TYPING = "typingnoun";

integer SERVER_CHAT_CHANNEL = -109114602;

string COMMAND_AVATAR = "a";
string COMMAND_PHRASE = "p";
string COMMAND_WORD = "w";
string COMMAND_FILLER_WORDS = "f";
string COMMAND_SETUP = "s";

integer SORT_SOURCE = 1;
integer SORT_TARGET = 2;

list Admins;

list Languages;
integer LAN_CODE = 0;
integer LAN_NAME = 1;
integer LAN_STRIDE = 2;

list People;
integer PEO_UUID = 0;
integer PEO_QUESTIONS_ASKED = 1;
integer PEO_QUESTIONS_CORRECT = 2;
integer PEO_STRIDE = 3;

string LangCodeSource;
string LangCodeTarget;
string LangNameSource;
string LangNameTarget;

list SourcePhrases;
list TargetPhrases;
integer PHR_KEYWORD = 0;
integer PHR_PHRASE = 1;
integer PHR_STRIDE = 2;

list SourceWords;
list TargetWords;
integer WOR_KEYWORD = 0;
integer WOR_WORD_ENTRY = 1;
integer WOR_STRIDE = 2;

list ObjectIds;	// a basic list of all the client objects that have connected to us

key AvId;

integer MenuChannel;
integer SetupPhase;

integer FirstTime;

integer ActivityType;
integer ACTIVITY_TYPE_LEARNING = 1;
integer ACTIVITY_TYPE_MULTIPLE_CHOICE = 2;
integer ACTIVITY_TYPE_TYPING = 3;

HandleMessage(key FromId, string Data) {
	if (llListFindList(ObjectIds, [ FromId ]) == -1) ObjectIds += FromId;	// record object's UUID
	list Parts = DataString2List(Data);
	string Command = llList2String(Parts, 0);
	list Params = llList2List(Parts, 1, -1);
	if (Command == COMMAND_SETUP) {
		SendMessage(FromId, COMMAND_SETUP, SetupData());
	}
	else if (Command == COMMAND_AVATAR) {
		key ThisAv = (key)llList2String(Params, 0);
		integer P = llListFindList(People, [ ThisAv ]);
		if (P > -1) {
			P -= PEO_UUID;	// position at stride start
		}
		else {	// new avatar
			People += [ ThisAv, 0, 0 ];
		}
		SendMessage(FromId, COMMAND_AVATAR, []);	// send releveant data about the avatar (nothing yet)
	}
	else if (Command == COMMAND_WORD) {
		integer SorT = (integer)llList2String(Params, 0);
		list KeyWords = llList2List(Params, 1, -1);	// rest of data is list of phrases
		integer KeyWordsPtr = llGetListLength(KeyWords);
		list FromWords;
		if (SorT == SORT_SOURCE) FromWords = SourceWords;
		else if (SorT == SORT_TARGET) FromWords = TargetWords;
		else { llOwnerSay("Invalid SorT code in word request: '" + (string)SorT + "'"); return; }
		while (KeyWordsPtr--) {
			string KeyWord = llList2String(KeyWords, KeyWordsPtr);
			list Answer = [ KeyWord + SEPARATOR_DATA + DataList2String(GetWords(FromWords, KeyWord)) ];
			SendMessage(FromId, COMMAND_WORD, Answer);
		}
	}
	else if (Command == COMMAND_PHRASE) {
		integer SorT = (integer)llList2String(Params, 0);
		list KeyWords = llList2List(Params, 1, -1);	// rest of data is list of phrases
		integer KeyWordsPtr = llGetListLength(KeyWords);
		list FromPhrases = [ "?DPL?" ];
		if (SorT == SORT_SOURCE) FromPhrases = SourcePhrases;
		else if (SorT == SORT_TARGET) FromPhrases = TargetPhrases;
		else { llOwnerSay("Invalid SorT code in phrase request: '" + (string)SorT + "'"); return; }
		while (KeyWordsPtr--) {
			string KeyWord = llList2String(KeyWords, KeyWordsPtr);
			list Answer = [ KeyWord + SEPARATOR_DATA + DataList2String(GetPhraseTranslations(FromPhrases, KeyWord)) ];
			SendMessage(FromId, COMMAND_PHRASE, Answer);
		}
	}
	else if (Command == COMMAND_FILLER_WORDS) {
		integer Count = (integer)llList2String(Params, 0);
		integer SorT = (integer)llList2String(Params, 1);
		string Filter = llList2String(Params, 2);
		list WordList = [ "?DWL?" ];
		if (SorT == SORT_SOURCE) WordList = SourceWords;
		else if (SorT == SORT_TARGET) WordList = TargetWords;
		else { llOwnerSay("Invalid SorT code in filler request: '" + (string)SorT + "'"); return; }
		list RandomWords = GetRandomWords(Count, WordList, Filter);
		SendMessage(FromId, COMMAND_FILLER_WORDS, RandomWords);
	}
}
list GetWords(list Words, string KeyWord) {
	integer P = llListFindList(Words, [ "*" + KeyWord ]);
	if (P == -1) return [ "???" ];
	P -= WOR_KEYWORD;
	string WordEntry = llList2String(Words, P + WOR_WORD_ENTRY);
	list WordParts = llParseString2List(WordEntry, [ SEPARATOR_WORD_ENTRY ], []);	// note we don't keep nulls, we ignore them
	return WordParts;
}
list GetPhraseTranslations(list Phrases, string KeyWord) {
	integer P = llListFindList(Phrases, [ "*" + KeyWord ]);
	if (P == -1) return [ "???" ];
	P -= PHR_KEYWORD;
	string PhraseString = llList2String(Phrases, P + PHR_PHRASE);
	return DataString2List(PhraseString);
}
list GetRandomWords(integer Count, list WordList, string Filter) {
	list Ret = [];
	string WordEntry = "?GRW?";
	integer Len = llGetListLength(WordList) / WOR_STRIDE;
	while(Count--) {
		integer Break = FALSE;
		while(!Break) {
			integer Ptr = (integer)llFrand((float)Len);
			WordEntry = llList2String(WordList, (Ptr * WOR_STRIDE) + WOR_WORD_ENTRY);
			list WordEntries = llParseStringKeepNulls(WordEntry, [ SEPARATOR_WORD_ENTRY], []);		// get different forms of word
			if (llListFindList(WordEntries, [ Filter ]) == -1) {	// if filter isn't in word list
				// so we need to pick one of the forms to pass back
				WordEntry = PickRandomElement(WordEntries);
				if (llStringTrim(WordEntry, STRING_TRIM) != "" &&	// not empty
					llListFindList(Ret, [ WordEntry ]) == -1) {		// not already in output list
					Ret += WordEntry;
					Break = TRUE;
				}
			}
		}
	}
    //llOwnerSay("GRW:" + (string)Count + "\n" + llList2CSV(WordList) + "\n" + Filter + "\n" + llList2CSV(Ret));	
	return Ret;
}
list LoadWordList(string LangCode) {
	list Ret = [];
	list Lines = llParseStringKeepNulls(osGetNotecard(NOTECARD_WORDS + "_" + LangCode), [ "\n" ], []);
	integer I = llGetListLength(Lines) - 1;
	while(I--) {
		string Line = llList2String(Lines, I);
		if (Line != "") {
			list Parts = llParseStringKeepNulls(Line, [ NOTECARD_SEPARATOR ], []);
			string KeyWord = llList2String(Parts, 0);
			list Words = llList2List(Parts, 1, -1);
			string WordString = llDumpList2String(Words, SEPARATOR_DATA);
			if (WordString == "") WordString = KeyWord;	// translation defaults to keyword (so we can do "green|" instead of "green|green" for English, and other cases
			Ret += [ "*" + KeyWord, WordString ];
		}
	}
	return Ret;
}
list LoadPhraseList(string LangCode) {
	list Ret = [];
	list Lines = llParseStringKeepNulls(osGetNotecard(NOTECARD_PHRASES + "_" + LangCode), [ "\n" ], []);
	integer I = llGetListLength(Lines) - 1;
	while(I--) {
		string Line = llList2String(Lines, I);
		if (Line != "") {
			list Parts = llParseStringKeepNulls(Line, [ NOTECARD_SEPARATOR ], []);
			string KeyWord = llList2String(Parts, 0);
			list Phrases = llList2List(Parts, 1, -1);
			string PhraseString = llDumpList2String(Phrases, SEPARATOR_DATA);
			Ret += [ "*" + KeyWord, PhraseString ];
		}
	}
	return Ret;
}
list ListLanguages() {
	// returns the 2nd element of each stride (http://wiki.secondlife.com/wiki/LlList2ListStrided)
	return llList2ListStrided(llDeleteSubList(Languages, 0, 0), 0, -1, LAN_STRIDE);
}
list SetupData() {
	return [ LangCodeSource, LangNameSource, LangCodeTarget, LangNameTarget, ActivityType ];
}
SendAllObjects(string Command, list Data) {
	integer O = llGetListLength(ObjectIds);
	while(O--) {
		key OId = llList2Key(ObjectIds, O);
		SendMessage(OId, Command, Data );
	}
}
ReadNotecards() {
	// Languages
	Languages = [];
	list Lines = llParseStringKeepNulls(osGetNotecard(NOTECARD_LANGUAGES), [ "\n" ], []);
	integer I = llGetListLength(Lines) - 1;
	while(I--) {
		string Line = llList2String(Lines, I);
		list Parts = llParseStringKeepNulls(Line, [ NOTECARD_SEPARATOR ], []);
		string LangCode = llList2String(Parts, 0);
		string LangName = llList2String(Parts, 1);
		Languages += [ LangCode, LangName ];
	}
	Admins = [ llKey2Name(llGetOwner()) ] + llParseStringKeepNulls(osGetNotecard(NOTECARD_ADMINS), [ "\n" ], []);
}
// Convert language name to language code
string LangName2LangCode(string LangName) {
	integer P = llListFindList(Languages, [ LangName ]);
	if (P == -1) { llOwnerSay("Can't find language '" + LangName + "!"); return "??"; }
	P -= LAN_NAME;	// position at start of stride
	return llList2String(Languages, P + LAN_CODE);
}
// Convert language code to language name
string LangCode2LangName(string LangCode) {
	integer P = llListFindList(Languages, [ LangCode ]);
	if (P == -1) { llOwnerSay("Can't find language code '" + LangCode + "!"); return "??"; }
	P -= LAN_CODE;	// position at start of stride
	return llList2String(Languages, P + LAN_NAME);
}
// Parses string to list
list DataString2List(string String) {
	return llParseStringKeepNulls(String, [ SEPARATOR_DATA ], []);
}
string DataList2String(list List) {
	return llDumpList2String(List, SEPARATOR_DATA);
}
// General routine for sending formatted message
SendMessage(key Uuid, string Command, list Parameters) {
	if (Uuid != NULL_KEY) {
		string ParamString = llDumpList2String(Command + Parameters, SEPARATOR_DATA);
		MessageObject(Uuid, ParamString);
	}
}
// Wrapper for osMessageObject() that checks to see if destination exists
MessageObject(key Uuid, string Text) {
	if (ObjectExists(Uuid)) {
		osMessageObject(Uuid, Text);
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
// return random element from list
string PickRandomElement(list List) {
	return llList2String(List, (integer)llFrand((float)llGetListLength(List)));
}
SetText(string Text) {
	llSetText(Text, <1.0, 1.0, 1.0>, 1.0);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		AvId = NULL_KEY;
		People = [];
		Languages = [];
		// for now, we load en->es as a default
		LangCodeSource = "en";
		LangCodeTarget = "es";
		FirstTime = TRUE;
		state LoadData;
	}
}
state LoadData {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		SetText("Loading data ...");
		ReadNotecards();
		LangNameSource = LangCode2LangName(LangCodeSource);
		SourceWords = LoadWordList(LangCodeSource);
		SourcePhrases = LoadPhraseList(LangCodeSource);
		TargetWords = LoadWordList(LangCodeTarget);
		LangNameTarget = LangCode2LangName(LangCodeTarget);
		TargetPhrases = LoadPhraseList(LangCodeTarget);
		SendAllObjects(COMMAND_SETUP, SetupData());
		FirstTime = FALSE;
		state Normal;
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		SetText(LangNameSource + " ⇒ " + LangNameTarget);
		llSetTimerEvent(1.0);
	}
	touch_start(integer Count) {
		key Id = llDetectedKey(0);
		if (llListFindList(Admins, [ llKey2Name(Id) ]) > -1) {
			SetupPhase = 1;
			AvId = Id;
			state Setup;
		}
	}
	dataserver(key Id, string Data) {
		HandleMessage(Id, Data);
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) state LoadData;
	}
	timer() {
		llRegionSay(SERVER_CHAT_CHANNEL, "H");
	}
}
state Setup {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		SetText("In setup with " + llKey2Name(AvId));
		MenuChannel = -10000 - (integer)llFrand(1000000);
		llListen(MenuChannel, "", AvId, "");
		if (SetupPhase == 1) {
			SourcePhrases = LoadPhraseList("en");	// for now, these questions are always asked in English
			string Question = llList2String(GetPhraseTranslations(SourcePhrases, "sourcelanguage"), 0);	// pick the 0th because we don't need variety here
			llDialog(AvId, "\n" + Question, ListLanguages(), MenuChannel);
		}
		else if (SetupPhase == 2) {
			string Question = llList2String(GetPhraseTranslations(SourcePhrases, "targetlanguage"), 0);	// pick the 0th because we don't need variety here
			llDialog(AvId, "\n" + Question, ListLanguages(), MenuChannel);
		}
		else if (SetupPhase == 3) {
			llDialog(AvId, "\n[English placeholder text]\n\nSelect activity type:", [ "Learning", "Multi-choice", "Typing" ], MenuChannel);
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == AvId) {
			if (SetupPhase == 1) {	// get source language
				LangNameSource = Message;
				LangCodeSource = LangName2LangCode(LangNameSource);
			}
			else if (SetupPhase == 2) {	// get target language
				LangNameTarget = Message;
				LangCodeTarget = LangName2LangCode(LangNameTarget);
			}
			else if (SetupPhase == 3) {	// activity type
				if (Message == "Learning") ActivityType = ACTIVITY_TYPE_LEARNING;
				else if (Message == "Multi-choice") ActivityType = ACTIVITY_TYPE_MULTIPLE_CHOICE;
				else if (Message == "Typing") ActivityType = ACTIVITY_TYPE_TYPING;
			}
			SetupPhase++;
			if (SetupPhase > 3) state LoadData;
			state ReSetup;
		}
	}
	dataserver(key Id, string Data) {
		HandleMessage(Id, Data);
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) state LoadData;
	}
	touch_start(integer Count) {
		AvId = llDetectedKey(0);
		state ReSetup;
	}
}
state ReSetup {
	on_rez(integer Param) { llResetScript(); }
	state_entry() { state Setup; }
}
// PortaGlossa server v0.1