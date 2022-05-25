// TODO: make sure that whole system resets in region restart (game stops, crowns detach, hunt objects reset, etc)

// Treasure hunt server v1.2

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

string CONFIG_NOTECARD = "Treasure hunt config";

integer SETTEXT_STRING_LIMIT = 254;

// Link message number, sent by ML main script
integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_REGION_START = -405533; // region restart
integer LM_RESERVED_TOUCH_FACE = -44088510;

integer TREAS_START_GAME = -861461200;
integer TREAS_END_GAME = -861461201;

integer UTIL_MENU_INIT			= -21044301;
integer UTIL_MENU_ADD 			= -21044302;
integer UTIL_MENU_SETVALUE		= -21044303;
integer UTIL_MENU_START 		= -21044304;
integer UTIL_MENU_RESPONSE		= -21044305;
integer UTIL_MENU_PERSIST		= -21044306;
integer UTIL_MENU_CLOSEOPTION	= -21044307;

integer UTIL_TEXTBOX_CALL		= -21044500;
integer UTIL_TEXTBOX_RESPONSE	= -21044501;

string MESSAGE_IDENTIFIER = "&RMQ&";
integer MESSAGE_ID_LENGTH = 4; // 1 less than actual length (0 start!)

key OwnerId = NULL_KEY;
key MenuUserId = NULL_KEY;

string BTN_START_GAME = "New game";
string BTN_END_GAME = "End game";
string BTN_MESSAGE = "Winner text";

// Config card data
string AttachmentClickDesc = "object";
string AttachmentName = "";
integer AttachmentPoint = ATTACH_HEAD;
integer FaceGetObject = 0;
integer FaceMenu = 1;

integer GameInProgress = FALSE;
list Players = []; // Avatars in this game
string PrevWinnerName = "";
string WinnerMessage = "";

key RootUuid = NULL_KEY;
string ClickFacesCSV;

StartGame() {
	llOwnerSay("Starting game");
	GameInProgress = TRUE;
	Players = [];
	llMessageLinked(LINK_ALL_CHILDREN, TREAS_START_GAME, "", llGetKey());
	ShowStatus();
}
EndGame(key WinnerId) {
	string Message = "Game stopped";
	if (WinnerId != NULL_KEY) {
		string WinnerName = llKey2Name(WinnerId);
		Message = WinnerName + " has won the game!";
	}
	integer PlayerCount = llGetListLength(Players);
	integer P;
	for (P = 0; P < PlayerCount; P++) {
		key PlayerId = llList2Key(Players, P);
		llRegionSayTo(PlayerId, 0, Message);
		osMessageAttachments(PlayerId, MESSAGE_IDENTIFIER + "F", [ AttachmentPoint ], 0);
	}
	if ((WinnerId != NULL_KEY) && (WinnerMessage != "")) {
		llRegionSayTo(WinnerId, 0, WinnerMessage);
	}
	GameInProgress = FALSE;
	llMessageLinked(LINK_ALL_CHILDREN, TREAS_END_GAME, "", llGetKey());
	ShowStatus();
}
ShowStatus() {
	//vector Color = <0.9, 0.8, 0.1>;
	vector Color = <0.0745, 0.332, 0.535>;
	string Text = "";
	if (PrevWinnerName != "") { // Display previous winner name (if any) first time this function is called
		Text += PrevWinnerName + " won.\n";
		PrevWinnerName = ""; // don't show it again
	}
	if (GameInProgress) {
		Color = <0.1, 0.9, 0.1>;
		Text += "Game in progress.\nJoined:\n";
		if (Players == []) {
			Text += "None";
		}
		else {
			string PlayerNames = "";
			integer PlayerCount = llGetListLength(Players);
			integer P;
			for (P = 0; P < PlayerCount; P++) {
				key PlayerId = llList2Key(Players, P);
				string PlayerName = llKey2Name(PlayerId);
				PlayerNames += PlayerName + "\n";
			}
			string DraftText = Text + PlayerNames;
			if (llStringLength(DraftText) > SETTEXT_STRING_LIMIT) { // limit of llSetText string exceeded
				DraftText = Text + (string)PlayerCount + " players"; // give shortened version
			}
			Text = DraftText;
		}
	}
	else {
		Text += "No game running.";
	}
	llSetText(Text, Color, 1.0);
}
AddPlayer(key AvId) {
	if (AttachmentName == "") return; // ignore if config file invalid/missing
	osForceAttachToOtherAvatarFromInventory(AvId, AttachmentName, AttachmentPoint);
	Players += [ AvId ];
	ShowStatus();
}
ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return;
	}
	// Set defaults
	AttachmentClickDesc = "object";
	AttachmentName = "";
	AttachmentPoint = ATTACH_HEAD;
	FaceGetObject = 0;
	FaceMenu = 1;
	string ConfigContents = osGetNotecard(CONFIG_NOTECARD);	// Set config defaults
	list Lines = llParseStringKeepNulls(ConfigContents, [ "\n" ], []);
	integer LineCount = llGetListLength(Lines);
	integer I;
	for(I = 0; I < LineCount; I++) {
		string Line = llList2String(Lines, I);
		integer Comment = llSubStringIndex(Line, "//");
		if (Comment != 0) {    // Not a complete comment line
			if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);    // strip from comments characters onwards
			if (llStringTrim(Line, STRING_TRIM) != "") {    // if there's something left after comments are removed
				// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
				integer Equals = llSubStringIndex(Line, "=");
				if (Equals > -1) {    // so there is a "X = Y" kind of syntax
					string OName = llStringTrim(llGetSubString(Line, 0, Equals - 1), STRING_TRIM);        // original parameter name
					string Name = llToLower(OName);        // lower-case version for case-independent parsing
					string Value = llStringTrim(llGetSubString(Line, Equals + 1, -1), STRING_TRIM);
					// Interpret name/value pairs
					if (Name == "attachmentname") AttachmentName = StripQuotes(Value, Line);
					else if (Name == "attachmentclickdesc") AttachmentClickDesc = StripQuotes(Value, Line);
					else if (Name == "attachmentpoint") AttachmentPoint = (integer)Value;
					else if (Name == "facegetobject") FaceGetObject = (integer)Value;
					else if (Name == "facemenu") FaceMenu = (integer)Value;
					else llOwnerSay("Invalid keyword in config file: '" + OName + "'");
				}
				else {
					llOwnerSay("Invalid line in config file: " + Line);
				}
			}
		}
	}
	if (AttachmentName == "") {
		llOwnerSay("Attachment name missing from config card");
	}
	ClickFacesCSV = llList2CSV([ FaceGetObject, FaceMenu ]);
}
// Takes a string in double quotes, and strips out the quotes. Validates the format.
// <Text> is the string with quotes; <Line> is the entire line for error reporting
string StripQuotes(string Text, string Line) {
	if (Text == "") {    // allow empty string for null value
		return("");
	}
	if (llGetSubString(Text, 0, 0) == "\"" && llGetSubString(Text, -1, -1) == "\"") {     // if surrounded by quotes
		return(llGetSubString(Text, 1, -2));    // strip quotes
	}
	else {
		llOwnerSay("Invalid string literal (missing \"\"?): " + Line);
		return("");
	}
}
SendMenuCommand(integer Command, list Values) {
	string SendString = llDumpList2String(Values, "|");
	llMessageLinked(LINK_ROOT, Command, SendString, MenuUserId);
}
// Uses standard messaging protocol
MessageStandard(key Uuid, integer Command, list Params) {
	MessageObject(Uuid, llDumpList2String([ Command ] + Params, "|"));
}
// Wrapper for osMessageObject() that checks to see if target exists
MessageObject(key Uuid, string Text) {
	if (ObjectExists(Uuid)) {
		osMessageObject(Uuid, Text);
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		OwnerId = llGetOwner();
		ReadConfig();
		ShowStatus();
	}
	//	touch_start(integer Count) {
	//		// %%%%% need to use RTF
	//		while(Count--) {
	//			key AvId = llDetectedKey(Count);
	//			integer Face = llDetectedTouchFace(Count);
	//			if (Face == FaceGetObject) {
	//				if (GameInProgress) {
	//					AddPlayer(AvId);
	//				}
	//				else {
	//					llRegionSayTo(AvId, 0, "Sorry, no game currently in progress");
	//				}
	//			}
	//			else if (Face == FaceMenu && AvId == OwnerId) {
	//				MenuUserId = AvId;
	//				SendMenuCommand(UTIL_MENU_INIT, []);
	//				string StartStop = BTN_START_GAME;
	//				if (GameInProgress) StartStop = BTN_END_GAME;
	//				SendMenuCommand(UTIL_MENU_ADD, [	"!Main", "Select option", StartStop, BTN_MESSAGE ]);
	//				SendMenuCommand(UTIL_MENU_START, [ AvId ]);
	//			}
	//		}
	//	}
	link_message(integer Sender, integer Num, string Text, key Id) {
		if (Num == LM_RESERVED_TOUCH_FACE) {
			// The ML is telling us that someone clicked our reserved face. The string portion of the message contains a pipe-delimited
			// list of the following data: face, position, normal, binormal, ST, UV. User ID is in key part.
			list TouchData = llParseStringKeepNulls(Text, [ "|" ], []);    // Parse the data into a list of the four different parts
			integer TouchFace = (integer)llList2String(TouchData, 0);
			if (TouchFace == FaceGetObject) {
				if (GameInProgress) {
					AddPlayer(Id);
				}
				else {
					llRegionSayTo(Id, 0, "Sorry, no game currently in progress");
				}
			}
			else if (TouchFace == FaceMenu && Id == OwnerId) {
				MenuUserId = Id;
				SendMenuCommand(UTIL_MENU_INIT, []);
				string StartStop = BTN_START_GAME;
				if (GameInProgress) StartStop = BTN_END_GAME;
				SendMenuCommand(UTIL_MENU_ADD, [	"!Main", "Select option", StartStop, BTN_MESSAGE ]);
				SendMenuCommand(UTIL_MENU_START, [ Id ]);
			}			
		}
		else if (Num == LM_LOADING_COMPLETE) {
			MessageStandard(RootUuid, LM_EXTRA_DATA_GET, [ ClickFacesCSV ]);
		}
		else if (Num == UTIL_MENU_RESPONSE) {
			list Selected = llCSV2List(Text);
			//string SelectedMenu = llList2String(Selected, 0);
			string SelectedOption = llList2String(Selected, 1);
			if (SelectedOption == BTN_START_GAME) {
				StartGame();
			}
			else if (SelectedOption == BTN_END_GAME) {
				EndGame(NULL_KEY);
			}
			else if (SelectedOption == BTN_MESSAGE) {
				string Tag = "WM";
				string Message = "Enter message to send to winner:";
				llMessageLinked(LINK_ROOT, UTIL_TEXTBOX_CALL, Tag + "|" + Message, Id);
			}
		}
		else if (Num == UTIL_TEXTBOX_RESPONSE) {
			list L = llParseStringKeepNulls(Text, [ "|" ], []);
			string Tag = llList2String(L, 0);
			string Response = llList2String(L, 1);
			if (Tag == "WM") {
				WinnerMessage = Response;
			}
		}
	}
	dataserver(key From, string Data) {
		if (llGetSubString(Data, 0, MESSAGE_ID_LENGTH) == MESSAGE_IDENTIFIER) {
			Data = llGetSubString(Data, MESSAGE_ID_LENGTH + 1, -1); // discard id string
			string Command = llGetSubString(Data, 0, 0); // command is first character of Data
			string Params = llGetSubString(Data, 1, -1); // rest is parameters
			if (Command == "C") { // message from gem that's been clicked
				key AvId = (key)Params;
				if (!GameInProgress) { // no game currently running
					llRegionSayTo(AvId, 0, "There is no game in progress");
					return;
				}
				integer P = llListFindList(Players, [ AvId ]);
				if (P == -1) { // they're not in the list, so we've not given them an attachment this session
					llRegionSayTo(AvId, 0, "You're not in this game! Please click the " + AttachmentClickDesc + " to join.");
					return;
				}
				osMessageAttachments(AvId, MESSAGE_IDENTIFIER + "G" + (string)From, [ AttachmentPoint ], 0);
			}
			else if (Command == "W") {
				key WinnerId = (key)Params; // Param is winner's UUID
				PrevWinnerName = llKey2Name(WinnerId);
				EndGame(WinnerId);
			}
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) ReadConfig();
		if (Change & CHANGED_REGION_START) llResetScript();
		if (Change & CHANGED_LINK) {
			if (llGetLinkNumber() > 1) {
				RootUuid = llGetLinkKey(1);
			}
		}
	}
}
// Treasure hunt server v1.2