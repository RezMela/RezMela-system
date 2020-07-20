// Web-hosted texture v1.1.4

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

// v1.1.4 - use UUID-based comms (type 1)
// v1.1.3 - optimisation
// v1.1.2 - blank texture if unlinked
// v1.1.1 - fix projector not recognising touches on first rezzing
// v1.1.0 - fix type mismatch in list find (preventing menu from being accessed)
// v1.1 - autohide if projector type
// v1.0 - same as v0.11
// v0.11 - notecard mode
// v0.10 - multiple hamburger faces
// v0.9 - add multiple faces
// v0.8 - add show/hide hamburger face
// v0.7 - add HIRES attribute and aspect ratio awareness
// v0.6 - show URL in textbox
// v0.5 - add projection capabilities, introduce config card
// v0.4 - put RTF data in "extra data get", and make blank URL cancel URL input rather than blanking the prim
// v0.3 - use new method of data comms

string CONFIG_NOTECARD = "Web texture config";

integer NotecardMode;
key LoggedId = NULL_KEY;
key RootUuid = NULL_KEY;

list ClickFaces;    // faces to be clicked to prompt for image URL
list ImageFaces;    // faces to display URL
integer ImageFacesCount;

// Hamburger settings
string HamburgerTexture;		// UUID of hamburger, needed if AllSidesTexture is set
integer HamburgerHide;            // If TRUE, hamburger face hides on logout
integer HamburgerVisible;          // Is hamburger visible?
list HamburgerFaces;
integer HamburgerFacesCount;
integer ProjectorVisible = TRUE;

integer AllSidesTexture = FALSE; // If TRUE, use ALL_SIDES to set textures (then redisplay hamburgers)

// External Touch Handling messages
integer ETH_LOCK = -44912700;        // Send to central script to bypass touch handling
integer ETH_UNLOCK = -44912701;        // Send to central script to return to normal touch handling
integer ETH_TOUCHED = -44912702;    // Sent to external script to notify of touch
integer ETH_PROCESS = -44912703;    // Sent to central script to mimic touch

// Link message numbers, sent/rec'd by ML main script
integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_RESERVED_TOUCH_FACE = -44088510;        // Reserved Touch Face (RTF)

// ddw - 5/15/18
integer IM_HIRES = -33;                        // artibrarily assigned constants until we can create global ones
integer IM_MEDRES = -34;
integer IM_ASPECT_1x1 = -35;
integer IM_ASPECT_2x1 = -36;
integer IM_ASPECT_1x2 = -37;
integer IM_ASPECT_4x1 = -38;
integer IM_ASPECT_1x4 = -39;
integer IM_ASPECT_4x3 = -40;
integer IM_ASPECT_3x4 = -41;
integer IM_ASPECT_16x9 = -42;
integer IM_ASPECT_9x16 = -43;

integer HUD_API_LOGIN = -47206000;
integer HUD_API_LOGOUT = -47206001;

// ddw - 5/1/5/18
integer Max_pixels;                            // maximum pixel size of an axis
integer PX_height;                            // pixel size height
integer PX_width;                            // pixel size width
integer Resolution;                            // medium or hires

key AvId;
integer MenuChannel;
integer MenuListener;
integer DataRequested;
integer DataReceived;
string Url;

key DefaultTexture;
integer Projector;        // boolean
float LightIntensity;    // 0 to 1
float LightRadius;        // 0 to 20
float LightFalloff;    // 0 to 2
float ProjectorFOV; // 0 to 3
float ProjectorFocus; // -20 to 20
float ProjectorAmbiance; // 0 to 1    (rare/incorrect spelling inherited from LL)

string ConfigContents;

Display() {
	//BlankDisplay();
	integer F;
	if (NotecardMode) Url = ReadUrlNoteCard();
	if (Url == "") {
		if (AllSidesTexture) {
			llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEXTURE, ALL_SIDES, DefaultTexture, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0 ]);
			ApplyHamburgerTexture();
		}
		else {
			list Params = [];
			for (F = 0; F < ImageFacesCount; F++) {
				Params += [ PRIM_TEXTURE, llList2Integer(ImageFaces, F), DefaultTexture, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0 ];
			}
			llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
		}
		if (Projector) {
			osSetProjectionParams(Projector, DefaultTexture, ProjectorFOV, ProjectorFocus, ProjectorAmbiance);
		}
	}
	else {
		string CommandList = "";
		CommandList = osMovePen(CommandList, 0, 0);
		CommandList = osDrawImage(CommandList, PX_width, PX_height, Url); // Image size
		integer FirstImageFace = llList2Integer(ImageFaces, 0);
		// these can use osSetDynamicTextureDataFace with OpenSim 0.9 (not implemented in current 0.8)
		//osSetDynamicTextureDataBlendFace("", "vector", CommandList,
		//	"width:" + (string)PX_width + ",height:" + (string)PX_height, FALSE, 2, 0, 255, FirstImageFace);
		osSetDynamicTextureDataFace("", "vector", CommandList,
			"width:" + (string)PX_width + ",height:" + (string)PX_height, 0, FirstImageFace);
		key TextureId = llGetTexture(FirstImageFace);
		if (AllSidesTexture) {
			llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEXTURE, ALL_SIDES, TextureId, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0 ]);
			ApplyHamburgerTexture();
		}
		else {
			list Params = [];
			for (F = 1; F < ImageFacesCount; F++) {
				Params += [ PRIM_TEXTURE, llList2Integer(ImageFaces, F), TextureId, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0 ];
			}
			llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
			if (Projector) {
				osSetProjectionParams(TRUE, TextureId, ProjectorFOV, ProjectorFocus, ProjectorAmbiance);
			}
		}
	}
}
BlankDisplay() {
	if (AllSidesTexture) {
		llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0 ]);
		ApplyHamburgerTexture();
	}
	else {
		list Params = [];
		integer F;
		for (F = 0; F < ImageFacesCount; F++) {
			Params += [ PRIM_TEXTURE, llList2Integer(ImageFaces, F), TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0 ];
		}
		llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
	}
	if (Projector) {
		osSetProjectionParams(FALSE, TEXTURE_BLANK, ProjectorFOV, ProjectorFocus, ProjectorAmbiance);
	}
}
// Texture hamburger faces
ApplyHamburgerTexture() {
	list Params = [];
	integer FacePtr;
	for (FacePtr = 0; FacePtr< HamburgerFacesCount; FacePtr++) {
		Params += [ PRIM_TEXTURE, llList2Integer(HamburgerFaces, FacePtr), HamburgerTexture, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0 ];
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
}
string ReadUrlNoteCard() {
	integer CardNum = llGetInventoryNumber(INVENTORY_NOTECARD);
	if (CardNum < 2) {
		return "";
	}
	string NotecardName = llGetInventoryName(INVENTORY_NOTECARD, 0);
	if (NotecardName == CONFIG_NOTECARD) NotecardName = llGetInventoryName(INVENTORY_NOTECARD, 1);
	return osGetNotecard(NotecardName);
}
GiveDialog(key Uuid) {
	if (MenuListener) llListenRemove(MenuListener);
	AvId = Uuid;
	MenuListener = llListen(MenuChannel, "", AvId, "");
	string Desc = "\nEnter URL to display or blank to cancel";
	if (Url != "") Desc = "\nCurrent URL is " + Url + "\n" + Desc;
	llTextBox(AvId, Desc, MenuChannel);
	llSetTimerEvent(120.0);
}
RemoveListener() {
	llListenRemove(MenuListener);
	MenuListener = 0;
	llSetTimerEvent(0.0);
}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	ConfigContents = osGetNotecard(CONFIG_NOTECARD);    // Save it for detection of changes in changed()
	// Set config defaults
	NotecardMode = FALSE;
	DefaultTexture = TEXTURE_BLANK;
	ClickFaces = [ 1 ];    // face to be clicked to prompt for image URL
	ImageFaces = [ 3 ];    // face to display URL
	Projector = FALSE;
	LightIntensity = 1.0;
	LightRadius = 6.0;
	LightFalloff = 0.0;
	ProjectorFOV = 1.5;
	ProjectorFocus = 10.0;
	ProjectorAmbiance = 0.0;
	HamburgerTexture = TEXTURE_BLANK;
	HamburgerHide = TRUE;
	HamburgerFaces = [ 2 ];
	AllSidesTexture = FALSE;

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
					else if (Name == "notecardmode") NotecardMode = String2Bool(Value);
					else if (Name == "clickfaces") ClickFaces = CSV2IntegerList(Value);
					else if (Name == "imagefaces") ImageFaces = CSV2IntegerList(Value);
					else if (Name == "hamburgertexture") HamburgerTexture = Value;
					else if (Name == "hamburgerfaces") HamburgerFaces = CSV2IntegerList(Value);
					else if (Name == "hidehamburger") HamburgerHide = String2Bool(Value);
					else if (Name == "allsidestexture") AllSidesTexture = String2Bool(Value);
					else if (Name == "lightintensity") LightIntensity = (float)Value;
					else if (Name == "lightradius") LightRadius = (float)Value;
					else if (Name == "lightfalloff") LightFalloff = (float)Value;
					else if (Name == "projector") Projector = String2Bool(Value);
					else if (Name == "projectorfov") ProjectorFOV = (float)Value;
					else if (Name == "projectorfocus") ProjectorFocus = (float)Value;
					else if (Name == "resolution") {
						integer tmp = (integer) Value;
						if (tmp == 1024) SetResolution(IM_HIRES);
						else SetResolution(IM_MEDRES);
					}
					else if (Name == "aspectratio") {
						string val = (string) Value;
						if (val == "1:1") SetAspect(IM_ASPECT_1x1);
						else if (val == "1:2") SetAspect(IM_ASPECT_1x2);
						else if (val == "1:4") SetAspect(IM_ASPECT_1x4);
						else if (val == "2:1") SetAspect(IM_ASPECT_2x1);
						else if (val == "4:1") SetAspect(IM_ASPECT_4x1);
						else if (val == "4x3") SetAspect(IM_ASPECT_4x3);
						else if (val == "3x4") SetAspect(IM_ASPECT_3x4);
						else if (val == "16:9") SetAspect(IM_ASPECT_16x9);
						else if (val == "9:16") SetAspect(IM_ASPECT_9x16);
						else SetAspect(IM_ASPECT_1x1);
					}
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
// set aspect ratio for subsequent image loads - ddw - 05/15/18
SetAspect(integer aspect)
{
	if (aspect == IM_ASPECT_1x1) { PX_width = Max_pixels; PX_height = Max_pixels; }
	else if (aspect == IM_ASPECT_1x2) { PX_width = Max_pixels / 2; PX_height = Max_pixels; }
	else if (aspect == IM_ASPECT_2x1) { PX_width = Max_pixels; PX_height = Max_pixels / 2; }
	else if (aspect == IM_ASPECT_4x1) { PX_width = Max_pixels; PX_height = Max_pixels / 4; }
	else if (aspect == IM_ASPECT_1x4) { PX_width = Max_pixels / 4; PX_height = Max_pixels; }
	else if (aspect == IM_ASPECT_4x3) {
		PX_width = Max_pixels; PX_height = (integer) ((float)Max_pixels * .75);
	}
	else if (aspect == IM_ASPECT_3x4) {
		PX_width = (integer) ((float)Max_pixels * .75); PX_height = Max_pixels;
	}
	else if (aspect == IM_ASPECT_16x9) {
		PX_width = Max_pixels;
		PX_height = Max_pixels;
	}
	else if (aspect == IM_ASPECT_9x16) {
		PX_width = Max_pixels;
		PX_height = Max_pixels;
	}
	else { PX_width = Max_pixels; PX_height = Max_pixels; }
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
// Set projector visibility
SetProjectorVisibility(integer IsVisible) {
	if (!Projector) return;	// we're not a projector
	float Alpha = 0.0;
	if (IsVisible) Alpha = 1.0;
	llSetAlpha(Alpha, ALL_SIDES);
	ProjectorVisible = IsVisible;

}
// set resolution for subsequent image loads - ddw - 05/15/18
SetResolution(integer res)
{
	if (res == IM_HIRES) {
		Resolution = IM_HIRES;
		Max_pixels = 1024;
		return;
	}
	// otherwise default to medium res
	Resolution = IM_MEDRES;
	Max_pixels = 512;
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
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetRemoteScriptAccessPin(8000);    // in case we need it
		Url = "";
		SetResolution(IM_MEDRES);
		SetAspect(IM_ASPECT_1x1);
		if (!ReadConfig()) state Hang;
		SetHamburgerVisibility(!NotecardMode);
		SetProjectorVisibility(TRUE);
		if (llGetNumberOfPrims() == 1) {
			BlankDisplay();
		}
		MenuChannel = -1000 - (integer)llFrand(100000000.0);
		DataRequested = DataReceived = FALSE;
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_LOADING_COMPLETE) {
			ProcessLoadingComplete();
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			//list TouchData = llParseStringKeepNulls(String, [ "|" ], []);
			//integer TouchFace = (integer)llList2String(TouchData, 0);
			if ((HamburgerHide && !HamburgerVisible) || NotecardMode) return;
			if (Projector && !ProjectorVisible) return; // Not interactive unless user signed into App
			GiveDialog(Id);        // Id is UUID of user that touched
		}
		else if (Number == IM_HIRES) {      // change resolution - ddw - 05/16/18
			SetResolution(IM_HIRES);
			Display();
		}
		else if (Number == IM_MEDRES) {
			SetResolution(IM_MEDRES);
			Display();
		}
		else if (Number == HUD_API_LOGIN) {
			LoggedId = Id;
			if (!NotecardMode) SetHamburgerVisibility(TRUE);
			SetProjectorVisibility(TRUE);
		}
		else if (Number == HUD_API_LOGOUT) {
			LoggedId = NULL_KEY;
			if (!NotecardMode) SetHamburgerVisibility(FALSE);
			SetProjectorVisibility(FALSE);
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
			DataReceived = TRUE;
			Url = llList2String(Params, 0);
			if (Url != "") {
				Display();
			}
			else {
				BlankDisplay();
			}
		}
	}
	listen(integer Channel, string Name, key Uuid, string Message) {
		RemoveListener();
		if (Message != "") {
			Url = llStringTrim(Message, STRING_TRIM);
			Display();
			MessageStandard(RootUuid, LM_EXTRA_DATA_SET, [ Url ]);
		}
	}
	timer() {
		if (MenuListener) RemoveListener();
		if (!DataReceived) {
			MessageStandard(RootUuid, LM_EXTRA_DATA_GET, [ llList2CSV(ClickFaces) ]);
		}
		else {
			llSetTimerEvent(0.0);
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) Display();
		if (Change & CHANGED_INVENTORY) {
			string OldConfig = ConfigContents;
			ReadConfig();
			if (NotecardMode) {
				HamburgerVisible = FALSE;    // Notecardmode might have changed
				Display();    // Notecard might have changed
			}
			else if (ConfigContents != OldConfig) {
				Display();        // Redisplay if config file has changed
			}
		}
	}
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
	changed(integer Change) { llResetScript(); }
}
// Web-hosted texture v1.1.4