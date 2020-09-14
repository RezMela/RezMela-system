// Local texture v1.0.1

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

// v1.0.1 - add repeats data to image face

// Was: Melacraft texturable block v1.0.1


string CONFIG_NOTECARD = "Local texture config";

list ClickFaces;    // faces to be clicked to prompt for image URL

list ImageFaces;    // faces to display URL
integer IMG_FACE_NUMBER = 0;
integer IMG_ROTATION = 1;
integer IMG_REPEAT_X = 2;
integer IMG_REPEAT_Y = 3;
integer IMG_STRIDE = 4;

integer ImageFacesCount;

integer HamburgerHide;            // If TRUE, hamburger face hides on logout
integer HamburgerVisible;          // Is hamburger visible?
list HamburgerFaces;
integer HamburgerFacesCount;

integer ProjectorVisible = TRUE;
integer Projector;        // boolean
float LightIntensity;    // 0 to 1
float LightRadius;        // 0 to 20
float LightFalloff;    // 0 to 2
float ProjectorFOV; // 0 to 3
float ProjectorFocus; // -20 to 20
float ProjectorAmbiance; // 0 to 1    (rare/incorrect spelling inherited from LL)

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

key DefaultTexture;
key TextureId;

Display() {
	key UseTexture = TextureId;
	if (UseTexture == NULL_KEY) UseTexture = DefaultTexture;
	integer NumberOfSides = llGetNumberOfSides();
	list Params = [];
	integer F;
	// Format of each face is [ Face#, Rotation ]
	for (F = 0; F < ImageFacesCount; F += IMG_STRIDE) {
		integer Face = (integer)llList2String(ImageFaces, F + IMG_FACE_NUMBER);
		float Rotation = llList2Float(ImageFaces, F + IMG_ROTATION);
		float RepeatX = llList2Float(ImageFaces, F + IMG_REPEAT_X);
		float RepeatY = llList2Float(ImageFaces, F + IMG_REPEAT_Y);
		Params += [ PRIM_TEXTURE, Face, UseTexture, <RepeatX, RepeatY, 0.0>, ZERO_VECTOR, Rotation ];
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
	if (Projector) {
		osSetProjectionParams(Projector, UseTexture, ProjectorFOV, ProjectorFocus, ProjectorAmbiance);
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
	DefaultTexture = TEXTURE_BLANK;
	ClickFaces = [ 1 ];    // face to be clicked to prompt for image URL
	ImageFaces = [];    // [ face #, rotation ]  to display texture
	HamburgerHide = TRUE;
	HamburgerFaces = [ ];
	Projector = FALSE;
	LightIntensity = 1.0;
	LightRadius = 6.0;
	LightFalloff = 0.0;
	ProjectorFOV = 1.5;
	ProjectorFocus = 10.0;
	ProjectorAmbiance = 0.0;

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
					if (Name == "defaulttexture") DefaultTexture = (key)Value;
					else if (Name == "clickfaces") ClickFaces = CSV2IntegerList(Value);
					else if (Name == "imageface") ImageFaces += GetImageFaceData(Value);
					else if (Name == "hamburgerfaces") HamburgerFaces = CSV2IntegerList(Value);
					else if (Name == "hidehamburger") HamburgerHide = String2Bool(Value);
					else if (Name == "lightintensity") LightIntensity = (float)Value;
					else if (Name == "lightradius") LightRadius = (float)Value;
					else if (Name == "lightfalloff") LightFalloff = (float)Value;
					else if (Name == "projector") Projector = String2Bool(Value);
					else if (Name == "projectorfov") ProjectorFOV = (float)Value;
					else if (Name == "projectorfocus") ProjectorFocus = (float)Value;
					else if (Name == "projectorambiance" || Name == "projectorambience") ProjectorAmbiance = (float)Value;
					else llOwnerSay("Invalid keyword in config file: '" + OName + "'");
				}
				else {
					llOwnerSay("Invalid line in config file: " + Line);
				}
			}
		}
	}
	ImageFacesCount = llGetListLength(ImageFaces);
	HamburgerFacesCount = llGetListLength(HamburgerFaces);
	llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_POINT_LIGHT, Projector, <1.0, 1.0, 1.0>, LightIntensity, LightRadius, LightFalloff ]);
	return TRUE;
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
// Turn string <Face #>,<Rot Deg> into list [ <Face #>, <Rot Rad> ]
list GetImageFaceData(string Value) {
	list L = llCSV2List(Value);
	integer Face = (integer)llList2String(L, 0);
	float RotDeg = (float)llList2String(L, 1); // default to 0
	float TextureX = (float)llList2String(L, 2);
	float TextureY = (float)llList2String(L, 3);
	float RotRad = RotDeg * DEG_TO_RAD;
	if (TextureX == 0.0) TextureX = 1.0;
	if (TextureY == 0.0) TextureY = 1.0;
	return [ Face, RotRad, TextureX, TextureY ];
}
// Deal with LM_LOADING_COMPLETE messages, either by linked message or dataserver
ProcessLoadingComplete() {
	if (!DataRequested) {
		RootUuid = llGetLinkKey(1);
		MessageStandard(RootUuid, LM_EXTRA_DATA_GET, [ llList2CSV(ClickFaces) ]);
		llSetTimerEvent(12.0 + llFrand(6.0));
		DataRequested = TRUE;
	}
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
// Set projector visibility
SetProjectorVisibility(integer IsVisible) {
	if (!Projector) return;	// we're not a projector
	float Alpha = 0.0;
	if (IsVisible) Alpha = 1.0;
	llSetAlpha(Alpha, ALL_SIDES);
	ProjectorVisible = IsVisible;

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
		TextureId = NULL_KEY;
		ReadConfig();
		Display();
		DataRequested = DataReceived = FALSE;
		SetHamburgerVisibility(TRUE);
		SetProjectorVisibility(TRUE);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_LOADING_COMPLETE) {
			ProcessLoadingComplete();
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			if (HamburgerHide && !HamburgerVisible) return;
			if (Projector && !ProjectorVisible) return; // Not interactive unless user signed into App
			SendMenuCommand(MENU_TEXTBOX,  [ Id, "Enter UUID of texture and click \"Submit\".\n\nYou can find the UUID by right-clicking the texture in your inventory and selecting \"Copy Asset UUID\".\n\nLeave blank to cancel." ]);
		}
		else if (Number == HUD_API_LOGIN) {
			SetHamburgerVisibility(TRUE);
			SetProjectorVisibility(TRUE);
		}
		else if (Number == HUD_API_LOGOUT) {
			SetHamburgerVisibility(FALSE);
			SetProjectorVisibility(FALSE);
		}
		else if (Number == MENU_RESPONSE) {
			if (String == "") return;
			TextureId = (key)String;
			Display();
			MessageStandard(RootUuid, LM_EXTRA_DATA_SET, [ TextureId ]);
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
			TextureId = SaveData;
			Display();
		}
	}
	timer() {
		if (!DataReceived) {
			MessageStandard(RootUuid, LM_EXTRA_DATA_GET, [ TextureId ]);
		}
		else {
			llSetTimerEvent(0.0);
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			ReadConfig();
			Display();
		}
	}
}
// Local texture v1.0.1