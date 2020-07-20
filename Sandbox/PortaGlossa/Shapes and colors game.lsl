// Shapes and colors game v0.1

integer SERVER_CHAT_CHANNEL = -109114602;

string NOTECARD_COLORS = "Colors";
string NOTECARD_SHAPES = "Shapes";
string NOTECARD_SEPARATOR = "|";
string SEPARATOR_DATA = "|";

string COMMAND_AVATAR = "a";
string COMMAND_PHRASE = "p";
string COMMAND_WORD = "w";
string COMMAND_FILLER_WORDS = "f";
string COMMAND_SETUP = "s";

string KEYWORD_COLOR_QUESTION = "whatcoloristhis";
string KEYWORD_SHAPE_QUESTION = "whatshapeisthis";
string KEYWORD_ANSWER_INCORRECT = "incorrectanswer";
string KEYWORD_ANSWER_CORRECT = "correctanswer";
string KEYWORD_DEFAULT_TEXT = "defaulttext";
//string KEYWORD_TYPE_LEARNING = "learningnoun";
//string KEYWORD_TYPE_MUTIPLE_CHOICE = "multiplechoice";
//string KEYWORD_TYPE_TYPING = "typingnoun";

string BUTTON_OK = "✔";

integer NUMBER_OF_TURNS = 5;

integer SORT_SOURCE = 1;
integer SORT_TARGET = 2;

vector REZ_POS = <0.0, 0.0, 0.8>;

list Shapes;
integer SHA_LEVEL = 0;
integer SHA_KEYWORD = 1;
integer SHA_STRIDE = 2;
integer ShapesCount;

list Colors;
integer COL_LEVEL = 0;
integer COL_KEYWORD = 1;
integer COL_RGB = 2;
integer COL_STRIDE = 3;
integer ColorsCount;

key AvId;
key ServerId;

string LangCodeSource;
string LangNameSource;
string LangCodeTarget;
string LangNameTarget;

list ColorQuestions;
list ShapeQuestions;
list CorrectResponses;
list IncorrectResponses;

string CurrentShape;
integer CurrentShapePtr;
string CurrentShapeTranslated;
string CurrentColor;
integer CurrentColorPtr;
string CurrentColorTranslated;

integer ActivityType;
integer ACTIVITY_TYPE_LEARNING = 1;
integer ACTIVITY_TYPE_MULTIPLE_CHOICE = 2;
integer ACTIVITY_TYPE_TYPING = 3;

integer QuestionType;	// ie shape or color
string Question;
string AnswerKeyWord;
string AnswerWord;

integer ScoreTotal;
integer ScoreCorrect;

integer SetupDataReceived;
integer AvatarDataReceived;
integer MenuChannel;

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
ReadNotecards() {
	// Colors
	Colors = [];
	ColorsCount = 0;
	list Lines = llParseStringKeepNulls(osGetNotecard(NOTECARD_COLORS), [ "\n" ], []);
	integer I = llGetListLength(Lines) - 1;
	while(I--) {
		string Line = llList2String(Lines, I);
		list Parts = llParseStringKeepNulls(Line, [ NOTECARD_SEPARATOR ], []);
		integer Level = (integer)llList2String(Parts, 0);
		string Keyword = llList2String(Parts, 1);
		vector Rgb = (vector)llList2String(Parts, 2);
		Colors += [ Level, Keyword, Rgb ];
		ColorsCount++;
	}
	// Shapes
	Shapes = [];
	ShapesCount = 0;
	Lines = llParseStringKeepNulls(osGetNotecard(NOTECARD_SHAPES), [ "\n" ], []);
	I = llGetListLength(Lines) - 1;
	while(I--) {
		string Line = llList2String(Lines, I);
		list Parts = llParseStringKeepNulls(Line, [ NOTECARD_SEPARATOR ], []);
		integer Level = (integer)llList2String(Parts, 0);
		string Keyword = llList2String(Parts, 1);
		if (llGetInventoryType(Keyword) != INVENTORY_OBJECT) {
			llOwnerSay("Warning: shape object missing: '" + Keyword + "'");
		}
		Shapes += [ Level, Keyword ];
		ShapesCount++;
	}
}
// return random element from list
string PickRandomElement(list List) {
	return llList2String(List, (integer)llFrand((float)llGetListLength(List)));
}
RemoveShape() {
	if (llGetNumberOfPrims() > 1) {
		llSetLinkPrimitiveParamsFast(2, [ PRIM_POS_LOCAL, <0.0, 0.0, -5.0> ]);
		osForceBreakLink(2);
	}
}
// General routine for sending a message to the server
MessageServer(string Command, list Parameters) {
	if (ServerId != NULL_KEY) {
		string ParamString = llDumpList2String(Command + Parameters, SEPARATOR_DATA);
		if (!MessageObject(ServerId, ParamString)) {		// server has disappeared
			state Bootup;
		}
	}
}
// Wrapper for osMessageObject() that checks to see if destination exists
integer MessageObject(key Uuid, string Text) {
	if (ObjectExists(Uuid)) {
		osMessageObject(Uuid, Text);
		return TRUE;
	}
	else {
		return FALSE;
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
SetText(string Text) {
	llSetText(Text, <1.0, 1.0, 1.0>, 1.0);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		AvId = NULL_KEY;
		ServerId = NULL_KEY;
		SetupDataReceived = FALSE;
		ReadNotecards();
		RemoveShape();
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
		SetText("Click me to play the Shapes & Colors game!\n[Placeholder text in English]");
		if (!SetupDataReceived) MessageServer(COMMAND_SETUP, []);
	}
	dataserver(key Id, string Data) {
		if (Id == ServerId) HandleServerMessage(Data);
	}
	touch_start(integer Count) {
		AvId = llDetectedKey(0);
		state GetAvInfo;
	}
}
state GetAvInfo {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		SetText("Connecting to server ...");
		MessageServer(COMMAND_AVATAR, [ AvId ]);
	}
	dataserver(key Id, string Data) {
		if (Id == ServerId) {
			HandleServerMessage(Data);
			if (AvatarDataReceived) state GetData;
		}
	}
}
state GetData {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		SetText("Getting data from server ...");
		ColorQuestions = [];
		ShapeQuestions = [];
		CorrectResponses = [];
		IncorrectResponses = [];
		MessageServer(COMMAND_PHRASE, [
			SORT_TARGET,
			KEYWORD_COLOR_QUESTION,
			KEYWORD_SHAPE_QUESTION,
			KEYWORD_ANSWER_CORRECT,
			KEYWORD_ANSWER_INCORRECT
				]);
	}
	dataserver(key Id, string Data) {
		if (Id == ServerId) {
			list Parts = llParseStringKeepNulls(Data, [ SEPARATOR_DATA ], []);
			string Command = llList2String(Parts, 0);
			if (Command == COMMAND_PHRASE) {
				string KeyWord = llList2String(Parts, 1);
				list Phrases = llList2List(Parts, 2, -1);
				if (KeyWord == KEYWORD_COLOR_QUESTION) {
					ColorQuestions = Phrases;
				}
				else if (KeyWord == KEYWORD_SHAPE_QUESTION) {
					ShapeQuestions = Phrases;
				}
				else if (KeyWord == KEYWORD_ANSWER_CORRECT) {
					CorrectResponses = Phrases;
				}
				else if (KeyWord == KEYWORD_ANSWER_INCORRECT) {
					IncorrectResponses = Phrases;
				}
				else {
					llOwnerSay("Unknown keyword from color/shape phrase query: '" + KeyWord + "'");
					return;
				}
				// Have we got everything?
				if (
					llGetListLength(ColorQuestions) && llGetListLength(ShapeQuestions) &&
						llGetListLength(CorrectResponses) && llGetListLength(IncorrectResponses)
							){
								state NewGame;
							}
			}
			else {
				HandleServerMessage(Data);
			}

		}
	}
}
state NewGame {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		SetText("Loading new game ...");
		ScoreTotal = 0;
		ScoreCorrect = 0;
		state Play;
	}
}
state Play {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		SetText(llKey2Name(AvId) + "\n" + LangNameSource + " ⇒ " + LangNameTarget + "\n\n" + (string)ScoreCorrect + "/" + (string)ScoreTotal);
		MenuChannel = -1000 - (integer)llFrand(100000);				
		if (ScoreTotal == NUMBER_OF_TURNS) state EndPlay;
		integer P = (integer)llFrand(ColorsCount);
		CurrentColorPtr = (integer)llFrand(ColorsCount) * COL_STRIDE;
		CurrentColor = llList2String(Colors, CurrentColorPtr + COL_KEYWORD);
		CurrentShapePtr = (integer)llFrand(ShapesCount) * SHA_STRIDE;
		CurrentShape = llList2String(Shapes, CurrentShapePtr + SHA_KEYWORD);
		QuestionType = (integer)llFrand(2.0) + 1;
		rotation Rot = llEuler2Rot(<270.0, 0.0, 0.0> * DEG_TO_RAD);
		llRezObject(CurrentShape, llGetPos() + (REZ_POS * llGetRot()), ZERO_VECTOR, Rot, 1);
		AnswerWord = CurrentColorTranslated = CurrentShapeTranslated = "";
	}
	object_rez(key Id) {
		osForceCreateLink(Id, TRUE);
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) {
			if (llGetNumberOfPrims() == 1) {
				// All done; next turn
				state RePlay;
			}
			else { // Shape prim is linked
				vector RGB = llList2Vector(Colors, CurrentColorPtr + COL_RGB) / 256.0;
				llSetLinkColor(2, RGB, ALL_SIDES);
				//llSetLinkPrimitiveParamsFast(2, [
				//	PRIM_OMEGA, <0.0, 0.0, 1.0>, 0.2, 1.0
				//		]);
				Question = "?QUESB?";
				AnswerKeyWord= "?AKW?";
				if (QuestionType == 1) {		// Color question
					Question = PickRandomElement(ColorQuestions);	// get the wording of the question
					AnswerKeyWord = CurrentColor;
				}
				else if (QuestionType == 2) {	// Shape question
					Question = PickRandomElement(ShapeQuestions);
					AnswerKeyWord = CurrentShape;
				}
				MessageServer(COMMAND_WORD, [ SORT_TARGET, AnswerKeyWord ]);
			}
		}
	}
	dataserver(key Id, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ SEPARATOR_DATA ], []);
		string Command = llList2String(Parts, 0);
		list Params = llList2List(Parts, 1, -1);
		list FillerWords;
		if (Command == COMMAND_WORD) {
			string KeyWord = llList2String(Params, 0);
			if (KeyWord == AnswerKeyWord && AnswerWord == "") {
				list PossibleTargetWords = llList2List(Params, 1, -1);
				AnswerWord = PickRandomElement(PossibleTargetWords);
				MessageServer(COMMAND_WORD, [ SORT_TARGET, CurrentColor ]);
			}
			else if (KeyWord == CurrentColor && CurrentColorTranslated == "") {
				CurrentColorTranslated = llList2String(Params, 1);	// these should be lists because of synonyms
				MessageServer(COMMAND_WORD, [ SORT_TARGET, CurrentShape ]);
			}
			else if (KeyWord == CurrentShape && CurrentShapeTranslated == "") {
				CurrentShapeTranslated = llList2String(Params, 1);	// these should be lists because of synonyms
				MessageServer(COMMAND_FILLER_WORDS, [ "6", SORT_TARGET, AnswerWord ]);	// get random words for the other buttons in a multi-choice
			}
		}
		else if (Command == COMMAND_FILLER_WORDS) {
			FillerWords = llList2List(Params, 1, -1);
			// We have everything we need to ask the question now.
			// Note that we're getting everything for every type of game, even stuff
			// we don't need. That's just to keep the menus in one place.
			if (ActivityType == ACTIVITY_TYPE_LEARNING) {
				llListen(MenuChannel, "", AvId, "");
				llDialog(AvId, "\n" + CurrentColorTranslated + "\n" + CurrentShapeTranslated, [ BUTTON_OK ], MenuChannel);
			}
			else if (ActivityType == ACTIVITY_TYPE_MULTIPLE_CHOICE) {
				list Buttons = AnswerWord + FillerWords;
				Buttons = llListRandomize(Buttons, 1);
				llListen(MenuChannel, "", AvId, "");
				llDialog(AvId, "\n" + Question, Buttons, MenuChannel);
			}
			else if (ActivityType == ACTIVITY_TYPE_TYPING) {
				llListen(MenuChannel, "", AvId, "");
				llTextBox(AvId, "\n" + Question, MenuChannel);
			}
			ScoreTotal++;
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == AvId) {
			Message = llStringTrim(Message, STRING_TRIM);
			string Text = "";
			if (Message == BUTTON_OK) {
				RemoveShape();
				return;
			}
			else if (llToLower(Message) == llToLower(AnswerWord)) {
				string Response = PickRandomElement(CorrectResponses);
				Text = "\n      😀\n" + Response;
				ScoreCorrect++;
			}
			else {
				string Response = PickRandomElement(IncorrectResponses);
				Text = "\n      🙁\n" + Response + "\n" + "     " + AnswerWord ;
			}
			llDialog(AvId, Text, [ BUTTON_OK ], MenuChannel);
		}
	}
	touch_start(integer Count) {
		if (llDetectedKey(0) == AvId) {
			state Normal;
		}
	}
}
state EndPlay {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		if (ActivityType == ACTIVITY_TYPE_LEARNING) state Normal;
		string Feedback = "???";
		if (ScoreCorrect == ScoreTotal) Feedback = "Perfect!";
		else if (ScoreCorrect == ScoreTotal - 1) Feedback = "So close!";
		else if (ScoreCorrect > (ScoreTotal / 2)) Feedback = "Very good!";
		else Feedback = "Keep trying!";
		string Text = "\n[Placeholder in English for score feedback.]\n\nYou have " + (string)ScoreCorrect + " correct out of " + (string)ScoreTotal + ".\n" + Feedback + "\n";
		llListen(MenuChannel, "", AvId, "");
		llDialog(AvId, Text, [ BUTTON_OK ], MenuChannel);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == AvId) {
			if (Message == BUTTON_OK) state Normal;
		}
	}
}
state RePlay {
	on_rez(integer Param) { llResetScript(); }
	state_entry() { state Play;	}
}
// Shapes and colors game v0.1