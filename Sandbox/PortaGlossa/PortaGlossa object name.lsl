// PortaGlossa object name v0.1

string COMMAND_AVATAR = "a";
string COMMAND_PHRASE = "p";
string COMMAND_WORD = "w";
string COMMAND_FILLER_WORDS = "f";
string COMMAND_SETUP = "s";

string KEYWORD_WHAT_IS_OBJECT = "whatisobject";

key AvId;
key ServerId;

integer SetupDataReceived;

integer ActivityType;
integer ACTIVITY_TYPE_LEARNING = 1;
integer ACTIVITY_TYPE_MULTIPLE_CHOICE = 2;
integer ACTIVITY_TYPE_TYPING = 3;

string MyKeyWord;
string QuestionText;


HandleServerMessage(string Data) {
	list Parts = llParseStringKeepNulls(Data, [ SEPARATOR_DATA ], []);
	string Command = llList2String(Parts, 0);
	if (Command == COMMAND_SETUP) {
		LangCodeSource = llList2String(Parts, 1);
		LangNameSource = llList2String(Parts, 2);
		LangCodeTarget = llList2String(Parts, 3);
		LangNameTarget = llList2String(Parts, 4);
		ActivityType = (integer)llList2String(Parts, 5);
		SetupDataReceived = TRUE;
	}
	if (Command == COMMAND_AVATAR) {
		// we can get scores, etc from here when it's coded
		AvatarDataReceived = TRUE;
	}
}
default {
	state_entry() {
		AvId = NULL_KEY;
		ServerId = NULL_KEY;
		SetupDataReceived = FALSE;
		state Bootup;
	}
}
state Bootup {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		SetText("Finding server ...");
		llListen(SERVER_CHAT_CHANNEL, "", NULL_KEY, "");
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == SERVER_CHAT_CHANNEL && Message == "H") {
			ServerId = Id;
			SetText("Server found.");
			state Normal;
		}
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		RemoveShape();
		AvId = NULL_KEY;
		AvatarDataReceived = FALSE;
		if (!SetupDataReceived) MessageServer(COMMAND_SETUP, []);		
	}
}

// PortaGlossa object name v0.1