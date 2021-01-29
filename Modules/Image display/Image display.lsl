// Image display v1.0.1

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

// Based on Web-hosted texture v1.1.4 and Local texture v1.0.2

// v1.0.1 - implement LM_REGION_START

string CONFIG_NOTECARD = "Image display config";

integer NotecardMode;
key LoggedId = NULL_KEY;
key RootUuid = NULL_KEY;

list ClickFaces;    // faces to be clicked to prompt for image URL

list ImageFaces;    // faces to display URL
integer IMG_FACE_NUMBER = 0;
integer IMG_ROTATION = 1;
integer IMG_REPEAT_X = 2;
integer IMG_REPEAT_Y = 3;
integer IMG_STRIDE = 4;

integer ImageFacesCount;

// Hamburger settings
string HamburgerTexture;        // UUID of hamburger, needed if AllSidesTexture is set
integer HamburgerHide;            // If TRUE, hamburger face hides on logout
integer HamburgerVisible;          // Is hamburger visible?
list HamburgerFaces;
integer HamburgerFacesCount;
integer ProjectorVisible = TRUE;

// Sizes (pixels) of image area
integer SizeX;
integer SizeY;

integer AllSidesTexture = FALSE; // If TRUE, use ALL_SIDES to set textures (then redisplay hamburgers). Repeats, rotation, etc as default

// External Touch Handling messages
integer ETH_LOCK = -44912700;        // Send to central script to bypass touch handling
integer ETH_UNLOCK = -44912701;        // Send to central script to return to normal touch handling
integer ETH_TOUCHED = -44912702;    // Sent to external script to notify of touch
integer ETH_PROCESS = -44912703;    // Sent to central script to mimic touch

// Link message numbers, sent/rec'd by ML main script
integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_REGION_START = -405533; // region restart
integer LM_RESERVED_TOUCH_FACE = -44088510;        // Reserved Touch Face (RTF)

integer HUD_API_LOGIN = -47206000;
integer HUD_API_LOGOUT = -47206001;

integer MENU_RESET         = -291044301;
integer MENU_ADD          = -291044302;
integer MENU_SETVALUE     = -291044303;
integer MENU_START         = -291044304;
integer MENU_RESPONSE    = -291044305;
integer MENU_TEXTBOX    = -291044306;

integer DataRequested;
integer DataReceived;

// These are mutually exclusive
string ImageUrl = "";
key ImageUuid = NULL_KEY;

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
    integer F;
    if (NotecardMode) ImageUrl = ReadUrlNoteCard();
    if (ImageUrl == "" && ImageUuid == NULL_KEY) { // Need default image (UUID from config file)
        if (AllSidesTexture) {
            llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEXTURE, ALL_SIDES, DefaultTexture, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0 ]);
            ApplyHamburgerTexture();
        }
        else {
            list Params = [];
            // Format of each face is [ Face#, Rotation ]
            for (F = 0; F < ImageFacesCount; F += IMG_STRIDE) {
                integer Face = (integer)llList2String(ImageFaces, F + IMG_FACE_NUMBER);
                float Rotation = llList2Float(ImageFaces, F + IMG_ROTATION);
                float RepeatX = llList2Float(ImageFaces, F + IMG_REPEAT_X);
                float RepeatY = llList2Float(ImageFaces, F + IMG_REPEAT_Y);
                Params += [ PRIM_TEXTURE, Face, DefaultTexture, <RepeatX, RepeatY, 0.0>, ZERO_VECTOR, Rotation ];
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
        key TextureId; // This will either be the entered UUID or the UUID of the first face after drawing an URL image
        if (ImageUrl != "") {
            // If the image is from an URL, draw the image on the first face and extract the UUID of that image
            CommandList = osDrawImage(CommandList, SizeX, SizeY, ImageUrl); // Image size
            integer FirstImageFace = llList2Integer(ImageFaces, IMG_FACE_NUMBER); // Offset IMG_ from 0
            osSetDynamicTextureDataFace("", "vector", CommandList,
                "width:" + (string)SizeX + ",height:" + (string)SizeY, 0, FirstImageFace);
            TextureId = llGetTexture(FirstImageFace);
        }
        else {
            // The image is a UUID, not an URL, so use the UUID directly
            TextureId = ImageUuid;
        }
        if (AllSidesTexture) {
            llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEXTURE, ALL_SIDES, TextureId, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0 ]);
            ApplyHamburgerTexture();
        }
        else {
            list Params = [];
            // Format of each face is [ Face#, Rotation ]
            for (F = 0; F < ImageFacesCount; F += IMG_STRIDE) {
                integer Face = (integer)llList2String(ImageFaces, F + IMG_FACE_NUMBER);
                float Rotation = llList2Float(ImageFaces, F + IMG_ROTATION);
                float RepeatX = llList2Float(ImageFaces, F + IMG_REPEAT_X);
                float RepeatY = llList2Float(ImageFaces, F + IMG_REPEAT_Y);
                Params += [ PRIM_TEXTURE, llList2Integer(ImageFaces, F), TextureId, <RepeatX, RepeatY, 0.0>, ZERO_VECTOR, Rotation ];
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
        for (F = 0; F < ImageFacesCount; F += IMG_STRIDE) {
            integer Face = (integer)llList2String(ImageFaces, F + IMG_FACE_NUMBER);
            Params += [ PRIM_TEXTURE, Face, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0 ];
        }
        llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
    }
    if (Projector) {
        osSetProjectionParams(FALSE, TEXTURE_BLANK, ProjectorFOV, ProjectorFocus, ProjectorAmbiance);
    }
}
// Take user-entered string and make it into an image
ParseImage(string Data, integer SaveData) {
    if (Data == "") {    // empty, so let Display() show the default
        ImageUrl = "";
        ImageUuid = NULL_KEY;
    }
    else if (llSubStringIndex(Data, "/") > -1) { // crude check to see if it's an image URL
        ImageUrl = Data;
        ImageUuid = NULL_KEY;
    }
    else {    // It's a UUID
        ImageUrl = "";
        ImageUuid = (key)Data;
    }
    Display();
    if (SaveData && Data != "") MessageStandard(RootUuid, LM_EXTRA_DATA_SET, [ Data ]);
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
GiveDialog(key AvId) {
    string Description = "Enter URL or UUID of texture and click \"Submit\".\n\nYou can copy the URL from a browser address bar, or you can find the UUID by right-clicking the texture in your inventory and selecting \"Copy Asset UUID\".\n\nLeave blank to cancel.";
    if (ImageUrl != "") Description += "\n\nCurrent URL is " + ImageUrl;
    else if (ImageUuid != NULL_KEY) Description += "\n\nCurrent UUID is " + (string)ImageUuid;
    SendMenuCommand(MENU_TEXTBOX,  [ AvId, Description ]);
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
    ImageFaces = [];    // empty image face data
    Projector = FALSE;
    LightIntensity = 1.0;
    LightRadius = 6.0;
    LightFalloff = 0.0;
    ProjectorFOV = 1.5;
    ProjectorFocus = 10.0;
    ProjectorAmbiance = 0.0;
    SizeX = SizeY = 1024;
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
                    else if (Name == "imageface") ImageFaces += GetImageFaceData(Value);
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
                    else if (Name == "dimensions") {
                        list Dims = CSV2IntegerList(Value);
                        SizeX = llList2Integer(Dims, 0);
                        SizeY = llList2Integer(Dims, 1);
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
// Turn string:
//         <Face#>, [<RotDeg>, [<RepeatX>, <RepeatY>]]
// into list:
//         [ <Face#>, <RotRad>, <RepeatX>, <RepeatY> ]
list GetImageFaceData(string Value) {
    list L = llCSV2List(Value);
    integer Face = (integer)llList2String(L, 0);
    float RotDeg = (float)llList2String(L, 1); // default to 0
    float RepeatX = (float)llList2String(L, 2);
    float RepeatY = (float)llList2String(L, 3);
    float RotRad = RotDeg * DEG_TO_RAD;
    if (RepeatX == 0.0) RepeatX = 1.0;
    if (RepeatY == 0.0) RepeatY = 1.0;
    return [ Face, RotRad, RepeatX, RepeatY ];
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
    if (!Projector) return;    // we're not a projector
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
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
    return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
default {
    on_rez(integer Param) { llResetScript(); }
    state_entry() {
        llSetRemoteScriptAccessPin(8000);    // in case we need it
        ImageUrl = "";
        ImageUuid = NULL_KEY;
        if (!ReadConfig()) state Hang;
        SetHamburgerVisibility(!NotecardMode);
        SetProjectorVisibility(TRUE);
        if (llGetNumberOfPrims() == 1) {
            BlankDisplay();
        }
        DataRequested = DataReceived = FALSE;
    }
    link_message(integer Sender, integer Number, string String, key Id) {
        if (Number == LM_LOADING_COMPLETE) {
            ProcessLoadingComplete();
        }
        else if (Number == LM_RESERVED_TOUCH_FACE) {
            if ((HamburgerHide && !HamburgerVisible) || NotecardMode) return;
            if (Projector && !ProjectorVisible) return; // Not interactive unless user signed into App
            GiveDialog(Id);        // Id is UUID of user that touched
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
        else if (Number == MENU_RESPONSE) {
            ParseImage(String, TRUE);
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
            string ImageData = llList2String(Params, 0);
            ParseImage(ImageData, FALSE);
        }
        else if (Command == LM_REGION_START) {
            Display();
        }
    }
    timer() {
        if (!DataReceived) {
            MessageStandard(RootUuid, LM_EXTRA_DATA_GET, [ llList2CSV(ClickFaces) ]);
        }
        else {
            llSetTimerEvent(0.0);
        }
    }
    changed(integer Change) {
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
// Image display v1.0.1