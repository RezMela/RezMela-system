// Theme changer v1.0.1

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

// v1.0.1 Unlinked modules; bug fixes

string CONFIG_NOTECARD = "Theme changer config";
string THEMES_NOTECARD = "Themes";
string EXT_SOURCE = "texsrc";
string EXT_OBJECT = "texobj";
string PRIM_DRAWING_DELIMITER = "|";	// delimiter character for prim-drawing commands
float TIMER_FREQUENCY = 1.0;
key TEXTURE_INACTIVE = "80762986-bfc5-4a2a-93a7-f2edf8620d8b"; // "Click here to activate"
key TEXTURE_LOADING = "1188b4d9-e9a3-470c-8d16-0041a7eacdbc"; // "Loading ..."
vector COLOR_WHITE = <1.0, 1.0, 1.0>;

// Object faces, hardcoded for efficiency (it's not like the model is going to change often)
integer FACE_BUTTON_SIDES = 1; // sides of buttons (invisible when inactive)
integer FACE_HEADING = 2;
integer FACE_LEFT_ARROW = 4;
integer FACE_RIGHT_ARROW = 7;
integer FACE_APPLY = 0;
integer FACE_PREVIEW = 3;
integer FACE_INVISIBLE = 6;

string PRIVATE_KEY = "j04&*091]]2cebU7%d_@#X3";

float NAN_FLOAT = -918273.0;
vector NAN_VECTOR = <-918273.0, -918273.0, -918273.0>;

list ThemeNames = []; // From config file

list ThemesData = [];
integer THEME_NAME = 0;
integer THEME_DESCRIPTION = 1;
integer THEME_IMAGE = 2;
integer THEME_DESC_UUID = 3;
integer THEME_CONTENTS = 4;
integer THEME_STRIDE = 5;

integer ThemesCount = 0; // number of rows

integer IsActive = FALSE;
integer TimeoutTicks = 0;

string ClickFacesCSV = "";

string CurrentThemeName;
string AppliedTheme; // name of theme that's applied (if any)

list TextureData = [];
integer TEX_OBJECT_NAME = 0; // name (in notecard) or ptr (in internal table)
integer TEX_SIDE = 1;
integer TEX_DIFFUSE = 2;
integer TEX_NORMAL = 3;
integer TEX_SPECULAR = 4;
integer TEX_SPEC_COLOR = 5;
integer TEX_SPEC_GLOSS = 6;
integer TEX_SPEC_ENVIR = 7;
integer TEX_REPEATS = 8; // repeats, offsets and rotation need to be consecutive
integer TEX_OFFSETS = 9;
integer TEX_ROTATION = 10;
integer TEX_COLOR = 11;
integer TEX_ALPHA = 12;
integer TEX_STRIDE = 13;

integer TextureDataCount = 0; // number of rows

list NewObjects = [];
integer IsNewObjects = FALSE;

integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_TASK_COMPLETE = -405536;
integer LM_ANNOUNCE_OBJECT = -405570;
integer LM_RESERVED_TOUCH_FACE = -44088510;		// Reserved Touch Face (RTF)

integer HUD_API_LOGIN = -47206000;
integer HUD_API_LOGOUT = -47206001;

key RootUuid = NULL_KEY;

integer DataRequested;
integer DataReceived;

// Apply theme to whole linkset
ApplyThemeToLinkset() {
	if (AppliedTheme != "") {
		GetObjectParams();
		integer NumberOfPrims = llGetNumberOfPrims();
		list Uuids = [];
		integer LinkNum;
		for (LinkNum = 1; LinkNum <= NumberOfPrims; LinkNum++) {
			Uuids += llGetLinkKey(LinkNum);
		}
		ApplyTexture(Uuids);
	}
}
// Apply theme to new objects if appropriate
ProcessNewObjects() {
	if (AppliedTheme != "") {
		GetObjectParams();
		list Uuids = [];
		integer Len = llGetListLength(NewObjects);
		integer I;
		for (I = 0; I < Len; I++) {
			key Uuid = llList2Key(NewObjects, I);
			Uuids += Uuid;
		}
		ApplyTexture(Uuids);
	}
	NewObjects = [];
	IsNewObjects = FALSE;
}
// Gets missing texture data from MLO prims in current linkset
GetObjectParams() {
	string CurrentObjectName = "";
	integer LinkNum = 0;
	integer TexPtr;
	for (TexPtr = 0; TexPtr < TextureDataCount; TexPtr++) {
		integer T = TexPtr * TEX_STRIDE; // pointer to table
		string ObjectName = llList2String(TextureData, T + TEX_OBJECT_NAME);
		integer Side = llList2Integer(TextureData, T + TEX_SIDE);
		if (ObjectName != CurrentObjectName) {
			CurrentObjectName = ObjectName;
			// Try  to find an object of that name
			LinkNum = osGetLinkNumber(ObjectName);
		}
		if (LinkNum > -1) {
			integer Ptr = llListFindList(TextureData, [ ObjectName, Side ]);
			if (Ptr == -1) Ptr = llListFindList(TextureData, [ ObjectName, ALL_SIDES ]);
			if (Ptr > -1) {
				list CurrentParams = llGetLinkPrimitiveParams(LinkNum, [ PRIM_TEXTURE, Side ]);
				vector Repeats = llList2Vector(TextureData, Ptr + TEX_REPEATS);
				vector Offsets = llList2Vector(TextureData, Ptr + TEX_OFFSETS);
				float Rotation = llList2Float(TextureData, Ptr + TEX_ROTATION);
				// Pick up repeats, offset or rotation from the prim if they're not specified in theme data
				integer NewData = FALSE;
				if (Repeats == NAN_VECTOR) { Repeats = llList2Vector(CurrentParams, 1); NewData = TRUE; }
				if (Offsets == NAN_VECTOR) { Offsets = llList2Vector(CurrentParams, 2); NewData = TRUE; }
				if (Rotation == NAN_FLOAT) { Rotation = llList2Float(CurrentParams, 3); NewData = TRUE; }
				if (NewData) {
					// write data back to list
					TextureData = llListReplaceList(TextureData, [ Repeats, Offsets, Rotation ], Ptr + TEX_REPEATS, Ptr + TEX_ROTATION);
				}
			}
		}
	}
}
// Given list of UUIDs of MLOs, apply theme data as appropriate
ApplyTexture(list Uuids) {
	integer Len = llGetListLength(Uuids);
	integer U;
	for (U = 0; U < Len; U++) {
		key Uuid = llList2Key(Uuids, U);
		integer LinkNum = Uuid2LinkNum(Uuid); // I wish there were a more efficient way
		if (LinkNum > 0) { // object is linked (see function)
			list Params = [];
			string ObjectName = llGetLinkName(LinkNum);
			// Check if it's a themeable object
			integer Ptr = llListFindList(TextureData, [ ObjectName ]);
			if (Ptr > -1) { // It's in the data, so process it
				integer Sides = llGetLinkNumberOfSides(LinkNum);
				integer Side;
				for (Side = 0; Side < Sides; Side++) {
					Ptr = llListFindList(TextureData, [ ObjectName, Side ]);
					if (Ptr > -1) {
						key DiffuseTexture = GetTexture(llList2String(TextureData, Ptr + TEX_DIFFUSE));
						key NormalTexture = GetTexture(llList2String(TextureData, Ptr + TEX_NORMAL));
						key SpecularTexture = GetTexture(llList2String(TextureData, Ptr + TEX_SPECULAR));
						vector Repeats = llList2Vector(TextureData, Ptr + TEX_REPEATS);
						vector Offsets = llList2Vector(TextureData, Ptr + TEX_OFFSETS);
						float Rotation = llList2Float(TextureData, Ptr + TEX_ROTATION);
						Params += [
							PRIM_TEXTURE,
							Side,
							DiffuseTexture,
							Repeats,
							Offsets,
							Rotation,
							PRIM_NORMAL,
							Side,
							NormalTexture,
							Repeats,
							Offsets,
							Rotation,
							PRIM_SPECULAR,
							Side,
							SpecularTexture,
							Repeats,
							Offsets,
							Rotation,
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
				// We convert UUID to link number again, just in case it's changed due to scene loading, etc
				LinkNum = Uuid2LinkNum(Uuid);
				if (LinkNum > 0) { // object is still linked
					llSetLinkPrimitiveParamsFast(LinkNum, Params);
				}
			}
		}
	}
}
//// If input is a UUID, return that. If it's a CSV list, return one value at random
key GetTexture(string TextureEntry) {
	if (osIsUUID(TextureEntry)) return (key)TextureEntry; // 99% of the time
	list Textures = llCSV2List(TextureEntry);
	// More concise than I'd normally like, this returns a random element from Textures. Concise
	// for efficiency.
	return (key)llList2String(Textures, (integer)llFrand((float)llGetListLength(Textures)));
}
// Takes list of notecard basenames in ThemeNames and populates ThemesData with data from cards,
// or load current theme only when inactive.
integer LoadThemesData() {
	ThemesData = [];
	integer T;
	for (T = 0; T < ThemesCount; T++) {
		string ThemeName = llList2String(ThemeNames, T);
		string NotecardName = ThemeName + ".texobj";
		if (llGetInventoryType(NotecardName) != INVENTORY_NOTECARD) {
			llOwnerSay("Missing theme notecard: '" + NotecardName + "'");
			return FALSE;
		}
		string Contents = osGetNotecard(NotecardName);
		list Lines = llParseStringKeepNulls(Contents, [ "\n" ], []);
		string ThemeDesc = llList2String(Lines, 0);
		if (IsActive || (ThemeName == CurrentThemeName)) {
			key ThemeImageUuid = (key)llList2String(Lines, 1);
			string Data = llList2String(Lines, 2);
			ThemesData += [
				ThemeName,
				ThemeDesc,
				ThemeImageUuid,
				RenderName(ThemeDesc),
				Data
					];
			llSetTexture(ThemeImageUuid, FACE_INVISIBLE);
		}
	}
	return TRUE;
}
// Loads texture data for the current theme
LoadTheme() {
	integer ThemeNamesPtr = GetThemeNamesPtr(CurrentThemeName);
	integer ThemeDataPtr = GetThemesDataPtr(CurrentThemeName);
	string CardContents = llList2String(ThemesData, ThemeDataPtr + THEME_CONTENTS);
	string TextureDataString = Decode(CardContents);
	list Data = llParseStringKeepNulls(TextureDataString, [ "|" ], []);
	TextureData = [];
	TextureDataCount = 0;
	integer Len = llGetListLength(Data);
	integer P;
	for (P = 0; P < Len; P += TEX_STRIDE) {
		string ObjectName = llList2String(Data, P + TEX_OBJECT_NAME);
		integer Side = (integer)llList2String(Data, P + TEX_SIDE);
		string Diffuse = llList2String(Data, P + TEX_DIFFUSE);
		string Normal = llList2String(Data, P + TEX_NORMAL);
		string Specular = llList2String(Data, P + TEX_SPECULAR);
		vector SpecColor = (vector)llList2String(Data, P + TEX_SPEC_COLOR);
		integer SpecGloss = (integer)llList2String(Data, P + TEX_SPEC_GLOSS);
		integer SpecEnvir = (integer)llList2String(Data, P + TEX_SPEC_ENVIR);
		vector Repeats = (vector)llList2String(Data, P + TEX_REPEATS);
		vector Offsets = (vector)llList2String(Data, P + TEX_OFFSETS);
		float Rotation  = (float)llList2String(Data, P + TEX_ROTATION);
		vector Color = (vector)llList2String(Data, P + TEX_COLOR);
		float Alpha = (float)llList2String(Data, P + TEX_ALPHA);
		TextureData += [ ObjectName, Side, Diffuse, Normal, Specular, SpecColor, SpecGloss, SpecEnvir, Repeats, Offsets, Rotation, Color, Alpha ];
		TextureDataCount++;
	}
}
Display() {
	if (IsActive) {
		integer ThemeNamesPtr = GetThemeNamesPtr(CurrentThemeName);
		integer ThemeDataPtr = GetThemesDataPtr(CurrentThemeName);
		key ThemeImageUuid = llList2Key(ThemesData, ThemeDataPtr + THEME_IMAGE);
		key ThemeNameUuid = llList2Key(ThemesData, ThemeDataPtr + THEME_DESC_UUID);
		llSetTexture(ThemeNameUuid, FACE_HEADING);
		llSetTexture(ThemeImageUuid, FACE_PREVIEW);
		LoadTheme();
		llSetTexture(llList2Key(ThemesData, (GetThemeNamesPtr(NextTheme()) + THEME_DESC_UUID)), FACE_INVISIBLE);
		SetButtonsTransparency(1.0);
	}
	else {
		llSetTexture(TEXTURE_INACTIVE, FACE_PREVIEW);	// show "Click to activate" texture
		llSetTexture(TEXTURE_LOADING, FACE_INVISIBLE);	// preload "Loading ..." texture
		SetButtonsTransparency(0.0);
	}
}
// Set alpha of button faces to hide/show them
SetButtonsTransparency(float Alpha) {
	llSetLinkPrimitiveParamsFast(LINK_THIS, [
		PRIM_COLOR, FACE_BUTTON_SIDES, COLOR_WHITE, Alpha,
		PRIM_COLOR, FACE_HEADING, COLOR_WHITE, Alpha,
		PRIM_COLOR, FACE_LEFT_ARROW, COLOR_WHITE, Alpha,
		PRIM_COLOR, FACE_RIGHT_ARROW, COLOR_WHITE, Alpha,
		PRIM_COLOR, FACE_APPLY, COLOR_WHITE, Alpha
			]);
}
key RenderName(string Name) {
	integer CanvasWidth = 512;
	integer CanvasHeight = 512;
	string FontName = "Noto Sans";
	integer FontSize = 24;
	string TextColor = "FF135589";
	string BackColor = "FFEDFAFD";
	vector TextSize = osGetDrawStringSize("vector", Name, FontName, FontSize);
	integer TextHeight = (integer)TextSize.y;
	integer TextWidth = (integer)TextSize.x;
	integer PosX = (CanvasWidth / 2) - (TextWidth / 2);
	integer PosY = (CanvasHeight / 2) - (TextHeight / 2);
	list Commands = [
		"PenColor " + BackColor,
		"MoveTo 0,0",
		"FillRectangle " + (string)CanvasWidth + "," + (string)CanvasHeight,
		"FontName " + FontName,
		"FontSize " + (string)FontSize,
		"PenColor " + TextColor,
		"MoveTo " + (string)PosX + "," + (string)PosY,
		"Text " + Name
			];
	string ExtraParams = "width:" + (string)CanvasWidth + ",height:" + (string)CanvasHeight + ",altdatadelim:" + PRIM_DRAWING_DELIMITER;
	osSetDynamicTextureDataBlendFace("", "vector", llDumpList2String(Commands, PRIM_DRAWING_DELIMITER), ExtraParams, FALSE, 2, 0, 255, FACE_INVISIBLE);
	return llGetTexture(FACE_INVISIBLE);
}
string Decode(string Text) {
	return llBase64ToString(llXorBase64StringsCorrect(Text, llStringToBase64(PRIVATE_KEY)));
}
// Regrettably, I've had to make this more terse/unreadable than I'd like because it needs to be
// as efficient as possible. Returns link number of given prim UUID, or 0 if it's not found
integer Uuid2LinkNum(key Uuid) {
	integer LinkNum = llGetNumberOfPrims();
	while (llGetLinkKey(LinkNum) != Uuid && LinkNum > 0) LinkNum--;
	return LinkNum;
}
// Deal with LM_LOADING_COMPLETE messages, either by linked message or dataserver
ProcessLoadingComplete() {
	if (!DataRequested) {
		RootUuid = llGetLinkKey(1);
		MessageStandard(RootUuid, LM_EXTRA_DATA_GET, [ ClickFacesCSV ]);
		llMessageLinked(LINK_ROOT, LM_ANNOUNCE_OBJECT, "", NULL_KEY); // ask ML to tell us about new objects added
		llSetTimerEvent(12.0 + llFrand(6.0));
		DataRequested = TRUE;
	}
}
// Returns name of next theme
string NextTheme() {
	integer ThemeNamesPtr = GetThemeNamesPtr(CurrentThemeName);
	ThemeNamesPtr++;
	if (ThemeNamesPtr >= ThemesCount) ThemeNamesPtr = 0;
	return llList2String(ThemeNames, ThemeNamesPtr);
}
// Returns name of previous theme
string PreviousTheme() {
	integer ThemeNamesPtr = GetThemeNamesPtr(CurrentThemeName);
	ThemeNamesPtr--;
	if (ThemeNamesPtr < 0) ThemeNamesPtr = ThemesCount - 1;
	return llList2String(ThemeNames, ThemeNamesPtr);
}
// Given theme name, returns pointer to appropriate ThemeNames row
integer GetThemeNamesPtr(string ThemeName) {
	integer ThemeNamesPtr = llListFindList(ThemeNames, [ ThemeName ]);
	if (ThemeNamesPtr == -1) {
		llOwnerSay("Can't find theme: '" + ThemeName + "'");
		return 0;
	}
	return ThemeNamesPtr;
}
// Given theme name, returns pointer to appropriate ThemesData row
integer GetThemesDataPtr(string ThemeName) {
	integer ThemesDataPtr = llListFindList(ThemesData, [ ThemeName ]);
	if (ThemesDataPtr == -1) {
		llOwnerSay("Can't find theme: '" + ThemeName + "'");
		return 0;
	}
	ThemesDataPtr -= THEME_NAME; // position at beginning of stride
	return ThemesDataPtr;
}
// Called to reset user activity timeout
UserActivity() {
	TimeoutTicks = 0;
	llSetTimerEvent(TIMER_FREQUENCY);
}
// Show "Applying ... " part of buttons texture instead of "Apply" (or reverse)
ShowApplyingMessage(integer On) {
	key Texture = llGetTexture(FACE_APPLY);
	vector Repeats = <1.2, 0.5, 0.0>;
	vector Offsets = <0.0, 0.28, 0.0>;
	// During the time the theme is applied, the texture is shifted to reveal the "Applying ..." part
	if (On) {
		Repeats = <0.6, 0.25, 0.0>;
		Offsets = <0.22, 0.75, 0.0>;
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEXTURE, FACE_APPLY, Texture, Repeats, Offsets, PI ]); // PI is 180°
}
SetText(string Text) {
	llSetText(Text, <0.8, 0.8, 0.1>, 1.0);
}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	string ConfigContents = osGetNotecard(CONFIG_NOTECARD);    // Save it for detection of changes in changed()
	// Set config defaults
	ThemeNames = [];
	integer ReturnStatus = TRUE;
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
					if (Name == "theme") ThemeNames += Value;
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
	ThemesCount = llGetListLength(ThemeNames);
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
		ClickFacesCSV = llList2CSV([ FACE_LEFT_ARROW, FACE_RIGHT_ARROW, FACE_PREVIEW, FACE_APPLY ]); // clickable button faces
		if (!ReadConfig()) state Hang;
		CurrentThemeName = "";
		AppliedTheme = "";
		IsActive = FALSE;
		ShowApplyingMessage(FALSE);		
		Display();
		DataRequested = DataReceived = FALSE;
		SetText("Loading ...");
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_ANNOUNCE_OBJECT) { // new object added to scene
			NewObjects += [ Id ]; // add uuid of new object
			llSetTimerEvent(TIMER_FREQUENCY);
			TimeoutTicks = 0;
			IsNewObjects = TRUE;
		}
		else if (Number == LM_LOADING_COMPLETE) {
			ProcessLoadingComplete();
		}
		else if (Number == LM_TASK_COMPLETE) { // Loading of a scene has finished
			ApplyThemeToLinkset();
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			list TouchData = llParseStringKeepNulls(String, [ "|" ], []);    // Parse the data into a list of the four different parts
			integer TouchFace = (integer)llList2String(TouchData, 0);
			if (IsActive) {
				if (TouchFace == FACE_LEFT_ARROW) {
					CurrentThemeName = PreviousTheme();
					Display();
				}
				else if (TouchFace == FACE_RIGHT_ARROW) {
					CurrentThemeName = NextTheme();
					Display();
				}
				else if (TouchFace == FACE_APPLY) {
					ShowApplyingMessage(TRUE);
					AppliedTheme = CurrentThemeName;
					ApplyThemeToLinkset();
					llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_SET, AppliedTheme, NULL_KEY);
					ShowApplyingMessage(FALSE);
				}
				UserActivity();
			}
			else {
				if (TouchFace == FACE_PREVIEW) {
					llSetTexture(TEXTURE_LOADING, FACE_PREVIEW);
					IsActive = TRUE;
					if (!LoadThemesData()) state Hang;
					if (CurrentThemeName == "") { // no current theme yet
						CurrentThemeName = llList2String(ThemeNames, 0); // select first theme from list
					}
					Display();
					UserActivity();
				}
			}
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
			AppliedTheme = llList2String(Params, 0);
			if (AppliedTheme != "") {
				CurrentThemeName = AppliedTheme;
				LoadThemesData();
				LoadTheme();
				ApplyThemeToLinkset();
				Display();
			}
			DataReceived = TRUE;
			SetText("");			
		}
	}
	timer() {
		if (!DataReceived) {
			RootUuid = llGetLinkKey(1);
			MessageStandard(RootUuid, LM_EXTRA_DATA_GET, [ ClickFacesCSV ]);
		}
		else {
			if (IsActive && TimeoutTicks++ > 300) { // active, but left for >5 mins
				// Timer is up - deactivate
				IsActive = FALSE;
				llSetTimerEvent(0.0);
				Display();
			}
			if (IsNewObjects) {
				ProcessNewObjects();
				TimeoutTicks = 0;
			}
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			if (!ReadConfig()) state Hang;
			//if (IsActive) {
			if (!LoadThemesData()) state Hang;
			//}
		}
		if (Change & CHANGED_REGION_START) {
			LoadThemesData(); // force regeneration of dynamic textures
			Display();
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
// Theme changer v1.0.1
