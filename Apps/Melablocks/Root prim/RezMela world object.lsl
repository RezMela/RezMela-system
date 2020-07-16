// RezMela world object v1.0

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

// v1.0 send linked message on initialisation
// v0.12 fix bug where script would loop trying to send RWO_DATA to non-existant client script even if there was no data (and hence no client script)
// v0.11 allow stretching/colouring of objects
// v0.10 changes arising from beta
// v0.9 changes to work with updater HUD
// v0.8 resizer function
// v0.7 broadcast selection/deselection as LM for other scripts
// v0.6 new method of communicating with client script at startup
// v0.5 only send extra data after it's received
// v0.4 continuation of extra data
// v0.3 add object extra data
// v0.2 Allow request of icon UUID

float Version = 0.1;

string UPDATER_CONFIG_NOTECARD = "RezMela updater config";

key RezzorId;
key ControlBoardId;
key IconId = NULL_KEY;
vector RootScale;
integer PrimCount;
float CurrentSizeFactor;

// Configuration data sent by control board
vector HoverTextColour;
float HoverTextAlpha;
integer AdjustHeight;
string ExtraData;
string ObjectParams;

integer ManuallyRezzed;
integer InitialiseMuted = FALSE;

// Selection
integer IsSelected;
key SelectAvId;

integer OBJECT_PIN = 50200;

// World object commands
integer WO_MOVE = 3000;
integer WO_ROTATE = 3001;
integer WO_MOVE_ROTATE = 3002;
integer WO_DELETE = 3003;
integer WO_INITIALISE = 3004;
integer WO_SELECT = 3005;
integer WO_DESELECT = 3006;
integer WO_COMMAND = 3007;
integer WO_EXTRA_DATA = 3008;
integer WO_RESIZE = 3009;
integer WO_CHANGE = 3010;
integer WO_INITIALISE_SENT = -37818090;

// General commands
integer GE_VERSION = 9000;
integer GE_DELETE = 9001;

// Delegated deletion stuff
integer LM_DELEGATE_DELETION = -7044001;        // received from another script that wants to handle deletion
integer LM_DELETE_RECEIVED = -7044002;            // inform other scripts that they should handle deletion now
integer DelegateDeletion = FALSE;

integer RWO_EXTRA_DATA_SET = 808399102;    // +ve for incoming, -ve for outgoing
integer RWO_ICON_UUID = 808399100;    // +ve for request, -ve for reply    [ deprecated, only used by label board? ]
integer RWO_INITIALISE = 808399110;    // +ve for data (sent repeateadly at startup), client sends -ve to disable. Icon ID is sent as key portion, ExtraData as string

// Seems like we're not using floating text on world objects?
//
//Select(key AvId) {
//    if (AvId == SelectAvId) return;    // no change
//    SelectAvId = AvId;
//    string HoverText = "";
//    if (SelectAvId != NULL_KEY) {
//        HoverText = llKey2Name(AvId);
//        if (HoverText == "") HoverText = "Unknown user";    // maybe they've logged out or TP'd away
//    }
//    llSetText(HoverText, HoverTextColour, HoverTextAlpha);
//}
MoveTo(vector NewPos) {
    list Params = [];
    integer Jumps = (integer)(llVecDist(llGetPos(), NewPos) / 10.0) + 1;
    while(Jumps--) {
        Params += [ PRIM_POSITION, NewPos ];
    }
    llSetLinkPrimitiveParamsFast(1, Params);
}
// Resize object
ReSize(float SizeFactor) {
    float ChangeFactor = SizeFactor / CurrentSizeFactor;
    list WriteParams = [];
    integer P;
    for(P = 1; P <= PrimCount; P++) {
        list ReadParams = llGetLinkPrimitiveParams(P, [ PRIM_SIZE, PRIM_POS_LOCAL ]);
        vector Size = llList2Vector(ReadParams, 0);
        vector LocalPos = llList2Vector(ReadParams, 1);
        Size *= ChangeFactor;
        WriteParams += [ PRIM_LINK_TARGET, P, PRIM_SIZE, Size ];
        if (P > 1) {    // for non-root prims
            vector NewPos = LocalPos * ChangeFactor;
            integer Jumps = llFloor(llVecDist(NewPos, LocalPos) / 10.0) + 1;    // number of 10m jumps
            while (Jumps--) {
                WriteParams += [ PRIM_POS_LOCAL, NewPos ];
            }
        }
    }
    llSetLinkPrimitiveParamsFast(LINK_THIS, WriteParams);
    CurrentSizeFactor = SizeFactor;
}
// Make physical change to child prim data
Change(list Data) {
    // get parts of list (which has been converted from CSV and is thus made of strings)
    vector LocalPos = (vector)llList2String(Data, 0);
    rotation LocalRot = (rotation)llList2String(Data, 1);
    vector Size = (vector)llList2String(Data, 2);
    vector Color = (vector)llList2String(Data, 3);
    
    vector OldLocalPos = llList2Vector(llGetLinkPrimitiveParams(2, [ PRIM_POS_LOCAL ]), 0);
    integer Steps = (integer)(llVecDist(LocalPos, OldLocalPos) / 10.0) + 1;    // How many 10m stages are there in the move?
    
    list PrimParams = [];
    while(Steps--) {
        PrimParams += [ PRIM_POS_LOCAL, LocalPos ];        // Add in as many moves (each max 10m) as necessary
    }
    PrimParams += [
        PRIM_ROT_LOCAL, LocalRot,
        PRIM_SIZE, Size,
        PRIM_COLOR, ALL_SIDES, Color, 1.0
        ];

    // Apply the changes
    llSetLinkPrimitiveParamsFast(2, PrimParams);
}
// Wrapper for osMessageObject() that checks to see if rezzor exists
MessageRezzor(integer Command, list Params) {
    if (ObjectExists(RezzorId)) {
        osMessageObject(RezzorId, (string)Command + "|" + llDumpList2String(Params, "|"));
    }
    else {
        llOwnerSay("Can't find rezzor");
    }
}
// Handles the deletion of the object
Die() {
    // If we've delegated obejct deletion to another script, tell that script that
    // it should do the deletion.
    if (DelegateDeletion) {
        llMessageLinked(LINK_SET, LM_DELETE_RECEIVED, "", NULL_KEY);
        return;
    }
    // We put the die in a loop because apparently sometimes it doesn't work the first time
    while(1 == 1) {        // OpenSim won't let us have "while(TRUE)"
        llDie();
        llSleep(0.2);
    }
}
// Adjust height of vehicle according to root prim thickness
vector GetAdjustedHeight(vector Pos) {
    return (Pos + <0.0, 0.0, RootScale.z / 2.0>);
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
    return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
default {
    on_rez(integer StartParam) {
        if (llGetInventoryType(UPDATER_CONFIG_NOTECARD) == INVENTORY_NOTECARD) state Hang;        // suspend if we're in the updater HUD
        if (StartParam) {
            ManuallyRezzed = FALSE;
            RezzorId = osGetRezzingObject();
            MessageRezzor(WO_INITIALISE, [ StartParam ]);
            llMessageLinked(LINK_SET, WO_INITIALISE_SENT, "", RezzorId);
            IconId = NULL_KEY;
            RootScale = llGetScale();
            PrimCount = llGetNumberOfPrims();
            CurrentSizeFactor = 1.0;
            InitialiseMuted = TRUE;    // keep quiet until we get WO_INITIALISE (containing extra data) from control board
        }
        else {
            ManuallyRezzed = TRUE;
        }
    }
    state_entry() {
        llSetRemoteScriptAccessPin(OBJECT_PIN);
        IconId = NULL_KEY;
        RootScale = llGetScale();
    }
    dataserver(key From, string Data) {
        list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
        integer Command = llList2Integer(Parts, 0);
        list Params = llList2List(Parts, 1, -1);
        if (Command == WO_INITIALISE) {
            ControlBoardId = From;
            HoverTextColour = (vector)llList2String(Parts, 1);
            HoverTextAlpha = (float)llList2String(Parts, 2);
            AdjustHeight = (integer)llList2String(Parts, 3);
            IconId = (key)llList2String(Parts, 4);
            ExtraData = llStringTrim(llList2String(Parts, 5), STRING_TRIM);
            ObjectParams = llList2String(Parts, 6);
            if (AdjustHeight) llSetPos(GetAdjustedHeight(llGetPos()));
            if (llSubStringIndex(ObjectParams, "P") > -1) llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_PHANTOM, TRUE ]);
            if (ExtraData != "") {
                // If there is extra data, it's safe to assume that there must have been a client script out there using the RWO system
                // to store it, and hence it must be there to receive it now.
                InitialiseMuted = FALSE;    // trigger outgoing initialisation messages
            }
            llSetTimerEvent(1.0);
        }
        else if (Command == WO_MOVE) {
            vector Pos = llList2Vector(Parts, 1);
            if (AdjustHeight) Pos = GetAdjustedHeight(Pos);
            MoveTo(Pos);
        }
        else if (Command == WO_ROTATE) {
            rotation Rot = llList2Rot(Parts, 1);
            llSetRot(Rot);
        }
        else if (Command == WO_MOVE_ROTATE) {
            vector Pos = llList2Vector(Parts, 1);
            rotation Rot = llList2Rot(Parts, 2);
            if (AdjustHeight) Pos = GetAdjustedHeight(Pos);
            MoveTo(Pos);
            llSetRot(Rot);
        }
        else if (Command == WO_SELECT) {
            SelectAvId = (key)llList2String(Parts, 1);
            llMessageLinked(LINK_SET, WO_SELECT, "", SelectAvId);
        }
        else if (Command == WO_DESELECT) {
            SelectAvId = NULL_KEY;
            llMessageLinked(LINK_SET, WO_DESELECT, "", NULL_KEY);
        }
        else if (Command == WO_DELETE) {
            Die();
        }
        else if (Command == WO_COMMAND) {
            // This causes a link message to be sent to any client script
            // Client scripts can't always communicate directly because they
            // may be in child prims with unknown UUIDs, etc.
            string Payload = llList2String(Parts, 1);
            llMessageLinked(LINK_SET, WO_COMMAND, Payload, From);
        }
        else if (Command == WO_RESIZE) {
            float ResizeValue = llList2Float(Parts, 1);
            ReSize(ResizeValue);
        }
        else if (Command == WO_CHANGE) {
            Change(Params);
        }
        else if (Command == GE_VERSION) {
            osMessageObject(From, "W" + (string)Version);
        }
        else if (Command == GE_DELETE) {
            llRemoveInventory(llGetScriptName());
        }
    }
    link_message(integer Sender, integer Number, string Message, key Id) {
        if (Number == LM_DELEGATE_DELETION) {    // if we receive this, it's notice that another script will take care of object deletion
            DelegateDeletion = TRUE;
        }
        else if (Number == RWO_ICON_UUID && IconId != NULL_KEY) {
            llMessageLinked(LINK_SET, -RWO_ICON_UUID, "", IconId);
        }
        else if (Number == RWO_EXTRA_DATA_SET) {
            ExtraData = Message;
            osMessageObject(ControlBoardId, (string)WO_EXTRA_DATA + "|" + ExtraData);
        }
        else if (Number == -RWO_INITIALISE) {
            InitialiseMuted = TRUE;
        }
    }
    timer() {
        if (!InitialiseMuted) {
            llMessageLinked(LINK_SET, RWO_INITIALISE, ExtraData, IconId);
        }
    }
}
state Hang {
    on_rez(integer Param) { llResetScript(); }
    state_entry() {
    }
    changed(integer Change) {
        if (Change & CHANGED_INVENTORY) llResetScript();
    }
}
// RezMela world object v1.0