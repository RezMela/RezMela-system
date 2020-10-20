// Melacraft texture changer v1.0.0

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

string CONFIG_NOTECARD = "Texture changer config";
string EXT_SOURCE = "texsrc";
string EXT_OBJECT = "texobj";

integer TEX_GIVE_MENU = -949183040;

string PRIVATE_KEY = "j04&*091]]2cebU7%d_@#X3";

integer HamburgerHide;            // If TRUE, hamburger face hides on logout
integer HamburgerVisible;          // Is hamburger visible?
list HamburgerFaces;
integer HamburgerFacesCount;

integer CurrentSet;

list SetNames = [];

list TextureData = [];
integer TEX_SET_PTR = 0;
integer TEX_SIDE = 1;
integer TEX_DIFFUSE = 2;
integer TEX_NORMAL = 3;
integer TEX_SPECULAR = 4;
integer TEX_SPEC_COLOR = 5;
integer TEX_SPEC_GLOSS = 6;
integer TEX_SPEC_ENVIR = 7;
integer TEX_REPEATS = 8;
integer TEX_OFFSETS = 9;
integer TEX_ROTATION = 10;
integer TEX_COLOR = 11;
integer TEX_ALPHA = 12;
integer TEX_STRIDE = 13;

integer NumberOfSides = 0;

integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_RESERVED_TOUCH_FACE = -44088510;		// Reserved Touch Face (RTF)

integer HUD_API_LOGIN = -47206000;
integer HUD_API_LOGOUT = -47206001;

integer MENU_RESET 		= -291044301;
integer MENU_ADD 	 	= -291044302;
integer MENU_SETVALUE 	= -291044303;
integer MENU_START 		= -291044304;
integer MENU_RESPONSE	= -291044305;
integer MENU_TEXTBOX	= -291044306;

key RootUuid = NULL_KEY;

integer DataRequested;
integer DataReceived;

SetTexture() {
	list Params = [];
	integer Side;
	for (Side = 0; Side < NumberOfSides; Side++) {
		if (llListFindList(HamburgerFaces, [ Side ]) == -1) { // ignore hamburger faces
			integer Ptr = llListFindList(TextureData, [ CurrentSet, Side ]);
			if (Ptr == -1) Ptr = llListFindList(TextureData, [ CurrentSet, -1 ]); // Look for ALL_SIDES
			if (Ptr > -1) {
				Params += [
					PRIM_TEXTURE,
					Side,
					llList2Key(TextureData, Ptr + TEX_DIFFUSE),
					llList2Vector(TextureData, Ptr + TEX_REPEATS),
					llList2Vector(TextureData, Ptr + TEX_OFFSETS),
					llList2Float(TextureData, Ptr + TEX_ROTATION),
					PRIM_NORMAL,
					Side,
					llList2Key(TextureData, Ptr + TEX_NORMAL),
					llList2Vector(TextureData, Ptr + TEX_REPEATS),
					llList2Vector(TextureData, Ptr + TEX_OFFSETS),
					llList2Float(TextureData, Ptr + TEX_ROTATION),
					PRIM_SPECULAR,
					Side,
					llList2Key(TextureData, Ptr + TEX_SPECULAR),
					llList2Vector(TextureData, Ptr + TEX_REPEATS),
					llList2Vector(TextureData, Ptr + TEX_OFFSETS),
					llList2Float(TextureData, Ptr + TEX_ROTATION),
					llList2Vector(TextureData, Ptr + TEX_SPEC_COLOR),
					llList2Integer(TextureData, Ptr + TEX_SPEC_GLOSS),
					llList2Integer(TextureData, Ptr + TEX_SPEC_ENVIR),
					PRIM_COLOR,
					Side,
					llList2Vector(TextureData, Ptr + TEX_COLOR),
					llList2Float(TextureData, Ptr + TEX_ALPHA)
					];
			}
		}
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
}
LoadTextureSets() {
	string TextureFileName = GetTextureFileName();	// Find name of notecard
	if (TextureFileName == "") return;
	// Read card
	string CardContents = osGetNotecard(TextureFileName);
	list CardParts = llParseStringKeepNulls(CardContents, [ "^" ], []);
	string SetsString = Decode(llList2String(CardParts, 0));
	string TextureDataString = Decode(llList2String(CardParts, 1));
	//SetsString = llBase64ToString(SetsString);
	SetNames = llParseStringKeepNulls(SetsString, [ "|" ], []);
	list Data = llParseStringKeepNulls(TextureDataString, [ "|" ], []);
	TextureData = [];
	integer Len = llGetListLength(Data);
	integer P;
	for (P = 0; P < Len; P += TEX_STRIDE) {
		integer SetPtr = (integer)llList2String(Data, P + TEX_SET_PTR);
		integer Side = (integer)llList2String(Data, P + TEX_SIDE);
		key Diffuse = (key)llList2String(Data, P + TEX_DIFFUSE);
		key Normal = (key)llList2String(Data, P + TEX_NORMAL);
		key Specular = (key)llList2String(Data, P + TEX_SPECULAR);
		vector SpecColor = (vector)llList2String(Data, P + TEX_SPEC_COLOR);
		integer SpecGloss = (integer)llList2String(Data, P + TEX_SPEC_GLOSS);
		integer SpecEnvir = (integer)llList2String(Data, P + TEX_SPEC_ENVIR);
		vector Repeats = (vector)llList2String(Data, P + TEX_REPEATS);
		vector Offsets = (vector)llList2String(Data, P + TEX_OFFSETS);
		float Rotation  = (float)llList2String(Data, P + TEX_ROTATION);
		vector Color = (vector)llList2String(Data, P + TEX_COLOR);
		float Alpha = (float)llList2String(Data, P + TEX_ALPHA);
		TextureData += [ SetPtr, Side, Diffuse, Normal, Specular, SpecColor, SpecGloss, SpecEnvir, Repeats, Offsets, Rotation, Color, Alpha ];
	}
	SendMenuCommand(MENU_RESET, []);
	SendMenuCommand(MENU_ADD, [ "!Texture", "Select the texture you require" ] + SetNames);
}
string GetTextureFileName() {
	string TextureFileName = "";
	integer N = llGetInventoryNumber(INVENTORY_NOTECARD);
	while(N-- > 0) {
		string CardName = llGetInventoryName(INVENTORY_NOTECARD, N);
		string Extension = GetExtension(CardName);
		if (Extension == EXT_OBJECT) {
			if (TextureFileName == "") {
				TextureFileName = CardName;
			}
			else {
				llOwnerSay("Duplicate texture object file(s) found");
				return "";
			}
		}
		else if (Extension == EXT_SOURCE) {
			llOwnerSay("Warning: Source file found: '" + CardName + "'");
		}

	}
	return TextureFileName;
}
string Decode(string Text) {
	return llBase64ToString(llXorBase64StringsCorrect(Text, llStringToBase64(PRIVATE_KEY)));
}
string CurrentTextureName() {
	return llList2String(SetNames, CurrentSet);
}
string GetExtension(string CardName) {
	integer P = llSubStringIndex(CardName, ".");
	if (P == -1) return "";
	return llGetSubString(CardName, P + 1, -1);
}
string GetBasename(string CardName) {
	integer P = llSubStringIndex(CardName, ".");
	if (P == -1) return "";
	return llGetSubString(CardName, 0, P - 1);
}
ShowMenu(key AvId) {
	SendMenuCommand(MENU_START, [ AvId ]);
}
// Deal with LM_LOADING_COMPLETE messages, either by linked message or dataserver
ProcessLoadingComplete() {
	if (!DataRequested) {
		RootUuid = llGetLinkKey(1);
		MessageStandard(RootUuid, LM_EXTRA_DATA_GET, [ llList2CSV(HamburgerFaces) ]);
		llSetTimerEvent(12.0 + llFrand(6.0));
		DataRequested = TRUE;
	}
}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	string ConfigContents = osGetNotecard(CONFIG_NOTECARD);    // Save it for detection of changes in changed()
	// Set config defaults
	integer ReturnStatus = TRUE;
	HamburgerHide = TRUE;
	HamburgerFaces = [ ];
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
				list L = llParseStringKeepNulls(Line, [ "=" ], [ ]);    // Separate LHS and RHS of assignment
				if (llGetListLength(L) == 2) {    // so there is a "X = Y" kind of syntax
					string OName = llStringTrim(llList2String(L, 0), STRING_TRIM);        // original parameter name
					string Name = llToLower(OName);        // lower-case version for case-independent parsing
					string Value = llStringTrim(llList2String(L, 1), STRING_TRIM);
					// Interpret name/value pairs
					if (Name == "hamburgerfaces") HamburgerFaces = CSV2IntegerList(Value);
					else if (Name == "hidehamburger") HamburgerHide = String2Bool(Value);
					else {
						llOwnerSay("Invalid keyword in config file: '" + OName + "'");
						ReturnStatus = FALSE;
					}
				}
				else {
					llOwnerSay("Invalid line in config file: " + Line);
					ReturnStatus = FALSE;
				}
			}
		}
	}
	HamburgerFacesCount = llGetListLength(HamburgerFaces);
	return ReturnStatus;
}
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
list CSV2IntegerList(string String) {
	list StringsList = llCSV2List(String);
	list Output = [];
	integer Len = llGetListLength(StringsList);
	integer I;
	for (I = 0; I < Len; I++) {
		Output += (integer)llList2String(StringsList, I);
	}
	return Output;
}
// Set hamburger visibility
SetHamburgerVisibility(integer IsVisible) {
	if (!HamburgerHide) return;    // We don't hide the hamburger if this is set
	HamburgerVisible = IsVisible;
	float Alpha = 0.0;
	if (IsVisible) Alpha = 1.0;
	integer FacePtr;
	for (FacePtr = 0; FacePtr< HamburgerFacesCount; FacePtr++) {
		integer Face = llList2Integer(HamburgerFaces, FacePtr);
		llSetAlpha(Alpha, Face);
	}
}
SendMenuCommand(integer Command, list Values) {
	string SendString = llDumpList2String(Values, "|");
	llMessageLinked(LINK_ROOT, Command, SendString, NULL_KEY);
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
		if (!ReadConfig()) state Hang;
		NumberOfSides = llGetNumberOfSides();
		LoadTextureSets();
		DataRequested = DataReceived = FALSE;
		SetHamburgerVisibility(TRUE);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_LOADING_COMPLETE) {
			ProcessLoadingComplete();
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			if (!HamburgerVisible) return;
			LoadTextureSets();
			ShowMenu(Id);
		}
		else if (Number == HUD_API_LOGIN) {
			SetHamburgerVisibility(TRUE);
		}
		else if (Number == HUD_API_LOGOUT) {
			SetHamburgerVisibility(FALSE);
		}
		else if (Number == MENU_RESPONSE) {
			if (String == "") return;
			// String contains <menu name>,<texture name>
			list Parts = llCSV2List(String);
			string SetName = llList2String(Parts, 1);
			CurrentSet = llListFindList(SetNames, [ SetName ]); // use named texture
			SetTexture();
			MessageStandard(RootUuid, LM_EXTRA_DATA_SET, [ CurrentTextureName() ]);
		}
		else if (Number == TEX_GIVE_MENU) {
			ShowMenu(Id);
		}
	}
	dataserver(key Requested, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		string sCommand = llList2String(Parts, 0);
		integer Command = (integer)sCommand;
		list Params = llList2List(Parts, 1, -1);
		if (Command == LM_LOADING_COMPLETE) {
			ProcessLoadingComplete();
		}
		else if (Command == LM_EXTRA_DATA_SET) {
			llSetTimerEvent(0.0);
			string SaveData = llList2String(Params, 0);
			DataReceived = TRUE;	// we don't really need this because we can just stop the timer, but I'm leaving it in case we use the timer for something else later
			if (SaveData == "") return; // no data
			CurrentSet = llListFindList(SetNames, [ SaveData ]); // use named texture
			SetTexture();
		}
	}
	timer() {
		if (!DataReceived) {
			MessageStandard(RootUuid, LM_EXTRA_DATA_GET, [ llList2CSV(HamburgerFaces) ]);
		}
		else {
			llSetTimerEvent(0.0);
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			if (!ReadConfig()) state Hang;
			LoadTextureSets();
		}
	}
}
state Hang {
	on_rez(integer Param) {
		llResetScript();
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			llResetScript();
		}
	}
}
// Melacraft texture changer v1.0.0