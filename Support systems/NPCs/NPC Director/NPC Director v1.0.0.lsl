// NPC director v1.0.0

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

float TIMER_PERIOD = 0.5;
integer NAN_INT = -389101471;
float WAYPOINT_RADIUS = 1.0;
integer WAYP_CHAT_CHANNEL = -131941965;
integer NO_INSTRUCTION = -5817290;
string ADMIN_MENU_TITLE = "Admin";
string WAYPOINTS_MENU_TITLE = "Waypoints";
string APPEARANCE_MENU_TITLE = "NPCs";
string APPEARANCE_CARD_SUFFIX = ".npc";
integer APPEARANCE_CARD_SUFFIX_LENGTH = 4;
string ATTACHMENT_NAME = "NPC Director attachment"; // name without version, etc

integer NPC_CHAT_CHANNEL = -28719011;

// Objects lister
integer MOL_CHANNEL = -381910033;

// Delegated deletion stuff
integer LM_DELEGATE_DELETION = -7044001;
integer LM_DELETE_RECEIVED = -7044002;

// Waypoint server commands
integer WS_REQUEST_LIST = -1751820700;
integer WS_GIVE_LIST = -1751820701;

// Behaviour cards
list Behaviours = [];
integer BEH_CARDNAME = 0;
integer BEH_NPC_ID = 1;            // UUID of NPC
integer BEH_ATTACHMENT_ID = 2;  // UUID of NPC's attachment
integer BEH_PROGRAM_COUNTER = 3;    // pointer to current instruction row; named after its equivalent in CPU architecture, etc
integer BEH_USER_ID = 4;        // UUID of user detected by NPC
integer BEH_REMEMBER_AV = 5;    // remember detected avatar? (TRUE/FALSE)
integer BEH_CLICK = 6;            // respond to clicks on NPC? (TRUE/FALSE)
integer BEH_DEBUG = 7;            // is debug on?
integer BEH_OBJECT_NAME = 8;    // name of object to sit/touch
integer BEH_STRIDE = 9;
integer BehavioursLength = 0;

list Events = [];
integer EV_BEHAVIOUR = 0;         // pointer to Behaviours table
integer EV_EVENTCODE = 1;
integer EV_CUSTOM_NAME = 2;        // only used for custom events
integer EV_INSTRUCTION_PTR = 3;
integer EV_STRIDE = 4;
integer EventsLength = 0;

// Event constants
integer E_START = 730000;
integer E_SENSOR = 730001;
integer E_CLICK = 730002;
integer E_CUSTOM = 740000;

// Event names and constant values: [ name, value ]
list EventNames = [];

// Internal "programs" for behaviour
list Instructions = [];
integer INST_BEHAVIOUR = 0;        // pointer to Behaviours table
integer INST_SOURCE_LINE = 1;    // original line number in notecard
integer INST_INSTRUCTION = 2;    // integer instruction code
integer INST_PARAMETERS = 3;    // pointer to parameters table
integer INST_STRIDE = 4;
integer ProgramsLength = 0;

// Internal instruction parameters
list Parameters = [];        // mixed, free format depending on instructions

// Instruction codes (internal)
integer I_CREATE = 1;
integer I_DELETE = 2;
integer I_WAIT = 10;
integer I_USER_WAIT = 12;
integer I_WALK = 20;
integer I_RUN = 21;
integer I_FLY = 22;
integer I_TELEPORT = 23;
integer I_SAY = 30;
integer I_SHOUT = 31;
integer I_WHISPER = 32;
integer I_USER_SAY = 33;
integer I_ANIMATION_START = 40;
integer I_ANIMATION_STOP = 41;
integer I_PRINT = 50;
integer I_SIT = 60;
integer I_STAND = 61;
integer I_TOUCH = 70;
integer I_JUMP = 80;
integer I_SENSOR_ONCE = 100;
integer I_SENSOR_REPEAT = 101;
integer I_SENSOR_STOP = 102;
integer I_SENSOR_REMEMBER = 103;
integer I_CLICK = 104;
integer I_CLEAR_USER = 105;
integer I_MENU = 107;
integer I_DEBUG = 109;
integer I_FACE = 110;
integer I_HOVER = 120;
integer I_SOUND = 130;
integer I_STOP = 900;

// Destination codes
integer DEST_REGION = 1;
integer DEST_LOCAL = 2;
integer DEST_USER = 3;
integer DEST_VARIABLE = 4;
integer DEST_WAYPOINT = 5;

// Variables
list Variables = [];
integer VAR_BEHAVIOUR = 0; // Keep BehaviourPtr and Name adjacent
integer VAR_NAME = 1;
integer VAR_VALUE = 2;
integer VAR_STRIDE = 3;

// Triggers
list Triggers = [];
integer TRI_BEHAVIOUR = 0;        // pointer to behaviours
integer TRI_TYPE = 1;            // (integer) see constant values below
integer TRI_INSTRUCTION = 2;    // originating instruction
integer TRI_DATA = 3;            // trigger parameters
integer TRI_STRIDE = 4;
// Trigger constants
integer TRI_TYPE_CREATE = 1;
integer TRI_TYPE_WAYPOINT = 2;
integer TRI_TYPE_WAIT = 3;
integer TRI_TYPE_USER_WAIT = 4;

// List of MLOs (objects created by Composer instances)
list ComposerObjects = [];

// List of waypoints
list Waypoints = [];
integer WP_UUID = 0;
integer WP_NAME = 1;
integer WP_STRIDE = 2;
integer WaypointsCount = 0; // count of number of rows

// LM constants for Utils script
integer UTIL_MENU_INIT        = -21044301;
integer UTIL_MENU_ADD         = -21044302;
integer UTIL_MENU_SETVALUE    = -21044303;
integer UTIL_MENU_START     = -21044304;
integer UTIL_MENU_RESPONSE    = -21044305;
integer UTIL_MENU_PERSIST    = -21044306;
integer UTIL_MENU_CLOSEOPTION    = -21044307;
integer UTIL_TEXTBOX_CALL    = -21044500;
integer UTIL_TEXTBOX_RESPONSE    = -21044501;

// Remembered avatars (applies to all behaviours)
list RememberedAvatars = [];    // format is [ <Av UUID> ]

// Animations
list Animations = [];    // [ NPC Id, Animation ]

// NPCs whose attachments need initial handshaking
list HelloWait = []; // [ BehaviourPtr ]
integer HelloWaitCount = 0;

list MenuCallBacks = [];
integer MCB_BEHAVIOUR = 0;
integer MCB_LABEL = 1;
integer MCB_EVENT = 2;
integer MCB_STRIDE = 3;

// Variables to construct I_MENU command
string BuildMenuTitle;
string BuildMenuDescription;
list BuildMenuButtonLabels;
list BuildMenuButtonEvents;

integer CurrentBehaviourPtr = -1; // Used while compiling cards

integer UsesWaypoints = FALSE; // TRUE of one or more behaviours uses waypoints

integer ActiveEvents = FALSE; // TRUE while events are processing

key OwnerId = NULL_KEY;

integer CurrentState; // booting/running/stopped
integer STATE_BOOTING = 1; // initialising
integer STATE_READY = 2; // ready to be starting
integer STATE_RUNNING = 3; // behaviours are being interpreted
integer STATE_STOPPED = 4; // system has been stopped
integer STATE_ERRORS = 5; // error(s) in behaviour card(s)

DumpInstructions() { // %%%
    integer P;
    llOwnerSay("Ptr: BehPtr | SourceLine | Instruction | ParamPtr");
    for (P = 0; P < llGetListLength(Instructions); P += INST_STRIDE) {
        llOwnerSay((string)P + ": " + llDumpList2String(llList2List(Instructions, P, P + INST_STRIDE - 1), " | "));

    }
}
// Initialise Start events for all behaviours
StartProcessing() {
    SetState(STATE_RUNNING);
    integer Behaviour;
    for (Behaviour = 0; Behaviour < BehavioursLength; Behaviour++) {
        integer BehaviourPtr = Behaviour * BEH_STRIDE;
        ProcessEvent(BehaviourPtr, E_START, "");
    }
    llSetTimerEvent(TIMER_PERIOD);
}
// Points program counters to beginnings of instructions for this event.
// EventName only used for custom events
ProcessEvent(integer BehaviourPtr, integer EventCode, string EventName) {
    integer EventPtr = llListFindList(Events, [ BehaviourPtr, EventCode, EventName ]);
    //    llOwnerSay("Instructions table: " + llList2CSV(Instructions));
    //    llOwnerSay("Events table: " + llList2CSV(Events));
    //    llOwnerSay("event ptr: " + (string)EventPtr + " after seach for " + llList2CSV([ BehaviourPtr, EventCode, EventName ]));
    if (EventPtr > -1) {
        integer InstructionPtr = llList2Integer(Events, EventPtr + EV_INSTRUCTION_PTR);
        Behaviours = llListReplaceList(Behaviours, [ InstructionPtr ], BehaviourPtr + BEH_PROGRAM_COUNTER, BehaviourPtr + BEH_PROGRAM_COUNTER);
    }
}
// Processes current instruction (pointed to by program counter) for each behaviour and increments program counter
ProcessInstructions() {
    ActiveEvents = FALSE; // until proven otherwise
    integer Behaviour;
    for (Behaviour = 0; Behaviour < BehavioursLength; Behaviour++) {
        integer BehaviourPtr = Behaviour * BEH_STRIDE;
        integer InstructionPtr = llList2Integer(Behaviours, BehaviourPtr + BEH_PROGRAM_COUNTER);
        if (InstructionPtr > -1 && !TriggersWaiting(BehaviourPtr) && !HelloWaiting(BehaviourPtr)) { // -1 means that processing has stopped for this behaviour/event
            ActiveEvents = TRUE;
            integer Instruction = llList2Integer(Instructions, InstructionPtr + INST_INSTRUCTION);
            integer ParamsPtr = llList2Integer(Instructions, InstructionPtr + INST_PARAMETERS);
            InstructionPtr = ProcessInstruction(BehaviourPtr, InstructionPtr, Instruction, ParamsPtr);
            Behaviours = llListReplaceList(Behaviours, [ InstructionPtr ], BehaviourPtr + BEH_PROGRAM_COUNTER, BehaviourPtr + BEH_PROGRAM_COUNTER);
        }
    }
}
// If a behaviour is idle, this can restart it
RestartProcessing() {
    ActiveEvents = TRUE;
    llSetTimerEvent(TIMER_PERIOD);
}
// Process a single instruction, returns updated program counter (ie pointer to instructions table for next instruction)
integer ProcessInstruction(integer BehaviourPtr, integer InstructionPtr, integer Instruction, integer ParamsPtr) {
    integer Debug = llList2Integer(Behaviours, BehaviourPtr + BEH_DEBUG);
    if (Debug && Instruction != I_STOP) { // I_STOP is an automatically-added instruction, so don't show it
        string CardName = llList2String(Behaviours, BehaviourPtr + BEH_CARDNAME);
        integer LineNum = llList2Integer(Instructions, InstructionPtr + INST_SOURCE_LINE);
        string SourceLine = " (card missing)";
        if (llGetInventoryType(CardName) == INVENTORY_NOTECARD) {
            SourceLine = osGetNotecardLine(CardName, LineNum);
        }
        llOwnerSay((string)(LineNum + 1) + ": " + SourceLine);
    }
    key NpcId = llList2Key(Behaviours, BehaviourPtr + BEH_NPC_ID);
    if (Instruction == I_CREATE) {
        list Parts = llList2List(Parameters, ParamsPtr, ParamsPtr + 2); // <first name>, <last name>, <appearance>
        vector Pos = llGetPos() + <0.0, 0.0, 2.0>; // create them above this object by default
        // if there's already an NPC, delete them and use their position
        if (NpcId != NULL_KEY) {
            Pos = osNpcGetPos(NpcId);
            osNpcRemove(NpcId);
        }
        string FirstName = llList2String(Parts, 0);
        string LastName = llList2String(Parts, 1);
        string Appearance = llList2String(Parts, 2);
        NpcId = osNpcCreate(FirstName, LastName, Pos, Appearance, OS_NPC_NOT_OWNED);
        Behaviours = llListReplaceList(Behaviours, [ NpcId ], BehaviourPtr + BEH_NPC_ID, BehaviourPtr + BEH_NPC_ID);
        HelloWait += [ BehaviourPtr ];
        HelloWaitCount++;
        Triggers += [ BehaviourPtr, TRI_TYPE_CREATE, Instruction, 0 ];
    }
    else if (Instruction == I_DELETE) {
        osNpcRemove(NpcId);
        Behaviours = llListReplaceList(Behaviours, [ NULL_KEY ], BehaviourPtr + BEH_NPC_ID, BehaviourPtr + BEH_NPC_ID);
    }
    else if (Instruction == I_STOP) { // end of event
        return -1; // halt processing
    }
    else if (Instruction == I_WAIT) {
        integer Seconds = llList2Integer(Parameters, ParamsPtr);
        Triggers += [ BehaviourPtr, TRI_TYPE_WAIT, Instruction, llGetUnixTime() + (integer)Seconds ];
    }
    else if (Instruction == I_USER_WAIT) {
        float Distance = llList2Float(Parameters, ParamsPtr);
        Triggers += [ BehaviourPtr, TRI_TYPE_USER_WAIT, Instruction, Distance ];
    }
    else if (Instruction == I_WALK || Instruction == I_RUN || Instruction == I_FLY) {
        list Params = llList2List(Parameters, ParamsPtr, ParamsPtr + 1);
        vector Pos = GetDestinationPos(BehaviourPtr, Params);
        if (Pos != ZERO_VECTOR) {
            osNpcMoveToTarget(NpcId, Pos, GetMovementType(Instruction));
            Triggers += [ BehaviourPtr, TRI_TYPE_WAYPOINT, Instruction, Pos ];
        }
    }
    else if (Instruction  == I_SAY) {
        string Text = llList2String(Parameters, ParamsPtr);
        Text = Expand(BehaviourPtr, Text);
        osNpcSay(NpcId, Text);
    }
    else if (Instruction  == I_SHOUT) {
        string Text = llList2String(Parameters, ParamsPtr);
        Text = Expand(BehaviourPtr, Text);
        osNpcShout(NpcId, 0, Text);
    }
    else if (Instruction  == I_WHISPER) {
        string Text = llList2String(Parameters, ParamsPtr);
        Text = Expand(BehaviourPtr, Text);
        osNpcWhisper(NpcId, 0, Text);
    }
    else if (Instruction  == I_USER_SAY) {
        string Text = llList2String(Parameters, ParamsPtr);
        key UserId = llList2Key(Behaviours, BehaviourPtr + BEH_USER_ID);
        Text = Expand(BehaviourPtr, Text);
        osNpcSayTo(NpcId, UserId, 0, Text);
    }
    else if (Instruction  == I_TELEPORT) {
        list Params = llList2List(Parameters, ParamsPtr, ParamsPtr + 1);
        vector Pos = GetDestinationPos(BehaviourPtr, Params);
        if (Pos != ZERO_VECTOR) {
            osTeleportAgent(NpcId, Pos, <0.0, 1.0, 0.0>); // LookAt faces north
        }
    }
    else if (Instruction  == I_ANIMATION_START) {
        string Animation = llList2String(Parameters, ParamsPtr);
        // If there's a prior animation, stop it
        integer A = llListFindList(Animations, [ NpcId ]);
        if (A > -1) {
            string OldAnimation = llList2String(Animations, A + 1);
            Animations = llDeleteSubList(Animations, A, A);
            osNpcStopAnimation(NpcId, OldAnimation);
        }
        if (Animation != "") { // if animation parameter is missing, silently fail
            osNpcPlayAnimation(NpcId, Animation);
            Animations += [ NpcId, Animation ];
        }
    }
    else if (Instruction  == I_ANIMATION_STOP) {
        integer A = llListFindList(Animations, [ NpcId ]);
        if (A > -1) {
            string OldAnimation = llList2String(Animations, A + 1);
            Animations = llDeleteSubList(Animations, A, A);
            osNpcStopAnimation(NpcId, OldAnimation);
        }
    }
    else if (Instruction == I_PRINT) {
        string Text = llList2String(Parameters, ParamsPtr);
        Text = Expand(BehaviourPtr, Text);
        llOwnerSay(Text);
    }
    else if (Instruction == I_SIT) {
        SendToNpc(BehaviourPtr, "SS", []); // stop any other sensors to avoid confusion between users and objects
        string ObjectName = llList2String(Parameters, ParamsPtr);
        ObjectName = StripQuotesTolerant(ObjectName);
        // Store object name in Behaviours table
        Behaviours = llListReplaceList(Behaviours, [ ObjectName ], BehaviourPtr + BEH_OBJECT_NAME, BehaviourPtr + BEH_OBJECT_NAME);
        // Tell NPC attachment to scan for nearby objects (processing continues when we get a reply)
        SendToNpc(BehaviourPtr,
            "SE",
            [ "S", ObjectName, NULL_KEY, ACTIVE | PASSIVE | SCRIPTED, 96.0, PI ] // "S" for "sit" tag, plus llSensor() arguments
                );
    }
    else if (Instruction == I_STAND) {
        osNpcStand(NpcId);
    }
    else if (Instruction == I_TOUCH) {
        SendToNpc(BehaviourPtr, "SS", []); // stop any other sensors to avoid confusion between users and objects
        string ObjectName = llList2String(Parameters, ParamsPtr);
        ObjectName = StripQuotesTolerant(ObjectName);
        // Store object name in Behaviours table
        Behaviours = llListReplaceList(Behaviours, [ ObjectName ], BehaviourPtr + BEH_OBJECT_NAME, BehaviourPtr + BEH_OBJECT_NAME);
        // Tell NPC attachment to scan for nearby objects (processing continues when we get a reply)
        SendToNpc(BehaviourPtr,
            "SE",
            [ "T", ObjectName, NULL_KEY, SCRIPTED, 96.0, PI ] // "T" for "touch" tag, plus llSensor() arguments
                );
    }
    else if (Instruction == I_JUMP) {
        string EventName = llList2String(Parameters, ParamsPtr);
        ProcessEvent(BehaviourPtr, E_CUSTOM, EventName);
        // ProcessEvent alters program counter (instructionptr), so we need to return the updated value
        integer E = llListFindList(Events, [ BehaviourPtr, E_CUSTOM, EventName ]);
        if (E == -1) { llOwnerSay("Can't find event for program counter: " + EventName); return -1; }
        InstructionPtr = llList2Integer(Events, E + EV_INSTRUCTION_PTR);
        return InstructionPtr;
    }
    else if (Instruction  == I_SENSOR_ONCE) {
        list Params = llList2List(Parameters, ParamsPtr, ParamsPtr + 5);
        SendToNpc(BehaviourPtr, "SE", Params);
    }
    else if (Instruction  == I_SENSOR_REPEAT) {
        list Params = llList2List(Parameters, ParamsPtr, ParamsPtr + 6);
        SendToNpc(BehaviourPtr, "SR", Params);
    }
    else if (Instruction  == I_SENSOR_STOP) {
        SendToNpc(BehaviourPtr, "SS", []);
    }
    else if (Instruction  == I_SENSOR_REMEMBER) {
        integer Remember = llList2Integer(Parameters, ParamsPtr);
        Behaviours = llListReplaceList(Behaviours, [ Remember ], BehaviourPtr + BEH_REMEMBER_AV, BehaviourPtr + BEH_REMEMBER_AV);
    }
    else if (Instruction  == I_CLICK) {
        integer Click = llList2Integer(Parameters, ParamsPtr);
        Behaviours = llListReplaceList(Behaviours, [ Click ], BehaviourPtr + BEH_CLICK, BehaviourPtr + BEH_CLICK);
    }
    else if (Instruction  == I_CLEAR_USER) {
        Behaviours = llListReplaceList(Behaviours, [ NULL_KEY ], BehaviourPtr + BEH_USER_ID, BehaviourPtr + BEH_USER_ID);
    }
    else if (Instruction  == I_MENU) {
        ProcessMenu(BehaviourPtr, InstructionPtr, ParamsPtr);
    }
    else if (Instruction  == I_DEBUG) {
        integer DebugOnOff = llList2Integer(Parameters, ParamsPtr);
        Behaviours = llListReplaceList(Behaviours, [ DebugOnOff ], BehaviourPtr + BEH_DEBUG, BehaviourPtr + BEH_DEBUG);
    }
    else if (Instruction  == I_FACE) {
        string FaceDirection = llList2String(Parameters, ParamsPtr);
        rotation Rot = GetFaceDirection(BehaviourPtr, FaceDirection);
        osNpcSetRot(NpcId, Rot);
    }
    else if (Instruction  == I_HOVER) {
        string Text = llList2String(Parameters, ParamsPtr);
        vector Color = llList2Vector(Parameters, ParamsPtr + 1);
        Text = Expand(BehaviourPtr, Text);
        SendToNpc(BehaviourPtr, "F", [ Text, Color, 1.0 ]);
    }
    else if (Instruction  == I_SOUND) {
        string Text = llList2String(Parameters, ParamsPtr);
        float Volume = llList2Float(Parameters, ParamsPtr + 1);
        SendToNpc(BehaviourPtr, "TS", [ Text, Volume ]);
    }
    else {
        llOwnerSay("Unknown internal instruction: " + (string)Instruction);
    }
    return InstructionPtr + INST_STRIDE; // program counter will point to next instruction in Instructions table
}
// Removes a variable
ClearVariable(integer BehaviourPtr, string Name) {
    integer V = llListFindList(Variables, [ BehaviourPtr, Name ]);
    if (V == -1) return;
    Variables = llDeleteSubList(Variables, V, V + VAR_STRIDE - 1);
}
// Adds a new variable - should be removed first
AddVariable(integer BehaviourPtr, string Name, string Value) {
    Variables += [ BehaviourPtr, llToLower(Name), Value ];
}
// Set variable - removes and adds a variable (ie replaces any prior value)
SetVariable(integer BehaviourPtr, string Name, string Value) {
    ClearVariable(BehaviourPtr, Name);
    AddVariable(BehaviourPtr, Name, Value);
}
// Get variable - returns value of named variable
string GetVariable(integer BehaviourPtr, string Name) {
    string LowerName = llToLower(Name);
    key UserId = llList2Key(Behaviours, BehaviourPtr + BEH_USER_ID);
    if (LowerName  == "username") {
        return llKey2Name(UserId);
    }
    else if (LowerName  == "userfirstname") {
        string UserName = llKey2Name(UserId);
        integer Space = llSubStringIndex(UserName, " ");
        return llGetSubString(UserName, 0, Space - 1);
    }
    else if (LowerName  == "usersecondname") {
        string UserName = llKey2Name(UserId);
        integer Space = llSubStringIndex(UserName, " ");
        return llGetSubString(UserName, Space + 1, -1);
    }
    integer V = llListFindList(Variables, [ BehaviourPtr, LowerName ]);
    if (V == -1) { llOwnerSay("Unknown variable: " + Name + "!"); return ""; }
    string Value = llList2String(Variables, V + VAR_VALUE);
    return Value;
}
ProcessTriggers() {
    if (Triggers == []) return; // fast return in most cases
    list NewTriggers = [];
    integer Len = llGetListLength(Triggers);
    integer T;
    for (T = 0; T < Len ; T += TRI_STRIDE) {
        integer BehaviourPtr = llList2Integer(Triggers, T + TRI_BEHAVIOUR);
        integer DeleteTrigger = FALSE;
        key NpcId = llList2Key(Behaviours, BehaviourPtr + BEH_NPC_ID);
        if (!osIsNpc(NpcId)) {
            // NPC has disappeared
            Behaviours = llListReplaceList(Behaviours, [ NULL_KEY ], BehaviourPtr + BEH_NPC_ID, BehaviourPtr + BEH_NPC_ID);
            Behaviours = llListReplaceList(Behaviours, [ -1 ], BehaviourPtr + BEH_PROGRAM_COUNTER, BehaviourPtr + BEH_PROGRAM_COUNTER);
            DeleteTrigger = TRUE;
        }
        integer TriggerType = llList2Integer(Triggers, T + TRI_TYPE);
        if (TriggerType == TRI_TYPE_WAYPOINT) {
            vector WayPos = llList2Vector(Triggers, T + TRI_DATA);
            vector NpcPos = osNpcGetPos(NpcId);
            // If NPC is close to target position, delete trigger
            if (llVecDist(NpcPos, WayPos) <= WAYPOINT_RADIUS) {
                DeleteTrigger = TRUE;
            }
            else {
                // They're still moving to the target, so re-issue movement command.
                // This helps after an avatar stand, and may have other positive effects
                // on robustsness
                integer Instruction = llList2Integer(Triggers, T + TRI_INSTRUCTION);
                osNpcMoveToTarget(NpcId, WayPos, GetMovementType(Instruction));
            }
        }
        else if (TriggerType == TRI_TYPE_WAIT) {
            integer WaitUntil = llList2Integer(Triggers, T + TRI_DATA);
            if (llGetUnixTime() >= WaitUntil) {
                DeleteTrigger = TRUE;
            }
        }
        else if (TriggerType == TRI_TYPE_USER_WAIT) {
            float Distance = llList2Float(Triggers, T + TRI_DATA);
            key UserId = llList2Key(Behaviours, BehaviourPtr + BEH_USER_ID);
            if (UserId == NULL_KEY) {
                DeleteTrigger = TRUE;
            }
            else {
                vector UserPos = llList2Vector(llGetObjectDetails(UserId, [ OBJECT_POS ]), 0);
                vector NpcPos = osNpcGetPos(NpcId);
                if (llVecDist(UserPos, NpcPos) < Distance) {
                    DeleteTrigger = TRUE;
                }
            }
        }
        if (!DeleteTrigger) NewTriggers += llList2List(Triggers, T, T + TRI_STRIDE - 1);
    }
    Triggers = NewTriggers;
}
ClearTriggers(integer BehaviourPtr) {
    if (Triggers == []) return; // fast return in most cases
    list NewTriggers = [];
    integer Len = llGetListLength(Triggers);
    integer T;
    for (T = 0; T < Len ; T += TRI_STRIDE) {
        integer ThisBehaviourPtr = llList2Integer(Triggers, T + TRI_BEHAVIOUR);
        if (ThisBehaviourPtr != BehaviourPtr) {
            NewTriggers += llList2List(Triggers, T, T + TRI_STRIDE - 1);
        }
    }
    Triggers = NewTriggers;
}
// Reduce tick count on all waiting hellos, and process if 0.
ProcessHellos() {
    if (HelloWait == []) return; // fast return in most cases
    // Format of HelloWait is [ BehaviourPtr ]
    integer H;
    for (H = 0; H < HelloWaitCount; H++) {
        integer BehaviourPtr = llList2Integer(HelloWait, H);
        SendHello(BehaviourPtr);
    }
}
// Send a hello message to a new NPC
SendHello(integer BehaviourPtr) {
    // The purpose of a queued hello message is:
    // 1. To delay sending commands to an NPC attachment before it's ready
    // 2. To discover the UUID of the attachment for more effecient comms
    // Hello messages are sent to the NPC itself as chat messages, but the reply
    // and subsequent comms use osMessageObject to the attachment.
    key NpcId = llList2Key(Behaviours, BehaviourPtr + BEH_NPC_ID);
    llRegionSayTo(NpcId, NPC_CHAT_CHANNEL, "H");
}
// Return TRUE if the given Behaviour has triggers waiting to be triggered
integer TriggersWaiting(integer BehaviourPtr) {
    // Quick and dirty for efficiency (I think)
    integer Len = llGetListLength(Triggers);
    integer L;
    for (L = 0; L < Len; L += TRI_STRIDE) {
        if (llList2Integer(Triggers, L + TRI_BEHAVIOUR) == BehaviourPtr) return TRUE;
    }
    return FALSE;
}
// Returns true if behaviour has an NPC who's not been sent a hello yet
integer HelloWaiting(integer BehaviourPtr) {
    if (HelloWaitCount == 0) return FALSE; // fast return in most cases
    key NpcId = llList2Key(Behaviours, BehaviourPtr + BEH_NPC_ID);
    if (NpcId == NULL_KEY) return FALSE; // No NPC yet, so keep processing
    integer P = llListFindList(HelloWait, [ "H", BehaviourPtr ]);
    if (P == -1) return FALSE; // no hello waiting
    return TRUE;
}
// Checks that all users are present in the region, and resets the Behavior if not.
// Returns number of users still present
integer CheckUsers() {
    integer UsersCount = 0;
    integer Behaviour;
    for (Behaviour = 0; Behaviour < BehavioursLength; Behaviour++) {
        integer BehaviourPtr = Behaviour * BEH_STRIDE;
        key UserId = llList2Key(Behaviours, BehaviourPtr + BEH_USER_ID);
        if (UserId != NULL_KEY) {
            if (AvatarExists(UserId)) {
                UsersCount++;
            }
            else {
                // The user has left the region, so reset the selected user and restart the behaviour script
                Behaviours = llListReplaceList(Behaviours, [ NULL_KEY ], BehaviourPtr + BEH_USER_ID, BehaviourPtr + BEH_USER_ID);
                ProcessEvent(BehaviourPtr, E_START, "");
            }
        }
    }
    return UsersCount;
}
integer LoadCards() {
    UsesWaypoints = FALSE;
    Behaviours = [];
    BehavioursLength = 0;
    Events = [];
    EventsLength = 0;
    Triggers = [];
    Instructions = [];
    Parameters = [];
    Variables = [];
    MenuCallBacks = [];
    HelloWait = [];
    ActiveEvents = FALSE;
    SetBuiltInEventNames();
    integer NotecardsCount = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer N;
    for (N = 0; N < NotecardsCount; N++) {
        string NotecardName = llGetInventoryName(INVENTORY_NOTECARD, N);
        if (llGetSubString(NotecardName, -4, -1) == ".beh") {
            if (LoadCard(NotecardName) == FALSE) {
                llOwnerSay("Load failed for " + NotecardName);
                return FALSE;
            }
        }
    }
    return TRUE;
}
integer LoadCard(string CardName) {
    // Add to Behaviours table
    CurrentBehaviourPtr    = llGetListLength(Behaviours); // this will be a pointer to the new entry
    Behaviours += [ CardName, NULL_KEY, NULL_KEY, -1, NULL_KEY, FALSE, FALSE, FALSE, "" ];
    BehavioursLength++;
    // Initialise menu data
    BuildMenuTitle = "";
    BuildMenuDescription = "";
    BuildMenuButtonLabels = [];
    BuildMenuButtonEvents = [];
    // Process notecard lines
    string CurrentEvent = "";
    integer CurrentEventPtr = -1;
    list Lines = llParseStringKeepNulls(osGetNotecard(CardName), [ "\n" ], []);
    integer Len = llGetListLength(Lines);
    integer LineNum;
    for (LineNum = 0; LineNum < Len; LineNum++) {
        string Line = llList2String(Lines, LineNum);
        integer Comments = llSubStringIndex(Line, "//");
        if (Comments > 0) {
            Line = llGetSubString(Line, 0, Comments - 1);
        }
        else if (Comments == 0) {
            Line = "";
        }
        Line = llStringTrim(Line, STRING_TRIM_TAIL);
        if (Line != "") {
            // Event definitions
            if (llGetSubString(Line, 0, 0) != " " && llGetSubString(Line, -1, -1) == ":") {
                // If we've been processing another event, add a "stop" command to that event's instructions
                string EventName = llToLower(llGetSubString(Line, 0, -2));
                if (CurrentEvent != "" && EventName != CurrentEvent) {
                    AddInstruction(CurrentBehaviourPtr, LineNum, I_STOP);
                }
                CurrentEvent = EventName;
                integer EventCode = GetEventCode(EventName);
                CurrentEventPtr = llGetListLength(Events); // pointer to new entry
                // Event name is blank in Events table for hardwired events, but for custom events contains
                // the actual event name.
                string FindName = "";
                if (EventCode == E_CUSTOM) FindName = EventName;
                integer Already = llListFindList(Events, [ CurrentBehaviourPtr, EventCode, FindName ]);
                if (Already > -1) {
                    CompilationError("Duplicate event definition", LineNum, Line);
                    return FALSE;
                }
                string CustomEventName = "";
                if (EventCode == E_CUSTOM) CustomEventName = EventName;
                Events += [ CurrentBehaviourPtr, EventCode, CustomEventName, llGetListLength(Instructions) ];
                EventsLength++;
            }
            // Instructions
            else {
                if (CurrentEvent == "") {
                    CompilationError("Instruction outside of event", LineNum, Line);
                    return FALSE;
                }
                // Parse instruction and parameters
                Line = llStringTrim(Line, STRING_TRIM_HEAD);
                integer Separator = llSubStringIndex(Line, " ");
                string InstructionSource = "";
                string ParamsSource = "";
                if (Separator > -1) {
                    InstructionSource = llToLower(llGetSubString(Line, 0, Separator - 1));
                    ParamsSource = llGetSubString(Line, Separator + 1, -1);
                }
                else {
                    InstructionSource = llToLower(Line);
                    ParamsSource = "";
                }
                integer Instruction = ParseInstruction(InstructionSource);
                if (Instruction == -1) { // -1 means invalid instruction
                    CompilationError("Unknown command '" + InstructionSource + "'", LineNum, Line);
                    return FALSE;
                }
                list Params = ParseParams(Instruction, ParamsSource, LineNum, Line);
                // The first element might be a magic number integer
                integer ParamCode = llList2Integer(Params, 0);
                // Was there an error in the parameters?
                if ( ParamCode == NAN_INT) return FALSE;
                // Add to instructions and parameters tables
                if (ParamCode != NO_INSTRUCTION) { // the instruction doesn't have a corresponding executable part
                    AddInstruction(CurrentBehaviourPtr, LineNum, Instruction);
                    Parameters += Params;
                }
            }
        }
    }
    // Add a final "stop" instruction
    AddInstruction(CurrentBehaviourPtr, LineNum, I_STOP);
    if (!PostCheckBehaviour(CardName, CurrentBehaviourPtr)) return FALSE;
    return TRUE;
}
// Performs checks on instructions, etc after a behaviour card has been parsed.
// Returns TRUE if all is well.
integer PostCheckBehaviour(string CardName, integer BehaviourPtr) {
    integer InstructionPtr = llListFindList(Instructions, [ BehaviourPtr ]);
    if (InstructionPtr == -1) {
        llOwnerSay("No instructions in card: " + CardName);
        return FALSE;
    }
    integer Len = llGetListLength(Instructions);
    // Loop for this behaviour value in the instructions table
    while (InstructionPtr < Len && llList2Integer(Instructions, InstructionPtr + INST_BEHAVIOUR) == BehaviourPtr) {
        if (!PostCheckInstruction(CardName, BehaviourPtr, InstructionPtr)) return FALSE;
        InstructionPtr += INST_STRIDE;
    }
    return TRUE;
}
// Check that a previously parsed instruction makes sense with all the instructions/events loaded
integer PostCheckInstruction(string CardName, integer BehaviourPtr, integer InstructionPtr) {
    integer Instruction = llList2Integer(Instructions, InstructionPtr + INST_INSTRUCTION);
    if (Instruction == I_JUMP) {
        integer ParamsPtr = llList2Integer(Instructions, InstructionPtr + INST_PARAMETERS);
        string EventName = llList2String(Parameters, ParamsPtr);
        if (!PostCheckEventExists(BehaviourPtr, E_CUSTOM, EventName)) {
            PostCheckFail("Section doesn't exist: \"" + EventName + ":\"", CardName, BehaviourPtr, InstructionPtr);
            return FALSE;
        }
    }
    else if (Instruction == I_SENSOR_ONCE || Instruction == I_SENSOR_REPEAT) {
        if (!PostCheckEventExists(BehaviourPtr, E_SENSOR, "")) {
            string EventName = GetEventName(E_SENSOR);
            PostCheckFail("Section doesn't exist: \"" + EventName + ":\"", CardName, BehaviourPtr, InstructionPtr);
            return FALSE;
        }
    }
    else if (Instruction == I_CLICK) {
        if (!PostCheckEventExists(BehaviourPtr, E_CLICK, "")) {
            string EventName = GetEventName(E_CLICK);
            PostCheckFail("Section doesn't exist: \"" + EventName + ":\"", CardName, BehaviourPtr, InstructionPtr);
            return FALSE;
        }
    }
    return TRUE;
}
integer PostCheckEventExists(integer BehaviourPtr, integer EventCode, string CustomEventName) {
    integer E = llListFindList(Events, [ BehaviourPtr, EventCode, CustomEventName ]);
    return (E != -1);
}
PostCheckFail(string ErrorMessage, string CardName, integer BehaviourPtr, integer InstructionPtr) {
    integer LineNum = llList2Integer(Instructions, InstructionPtr + INST_SOURCE_LINE);
    string SourceLine = osGetNotecardLine(CardName, LineNum);
    CompilationError(ErrorMessage, LineNum, SourceLine);
}
// Handle compilation errors in LoadCard()
CompilationError(string ErrorMessage, integer LineNum, string SourceLine) {
    llOwnerSay("Error in behavior card:\n" + (string)(LineNum + 1) + ": " + SourceLine + "\n*** " + ErrorMessage);
}
// Add an instruction to the Instructions table
AddInstruction(integer CurrentBehaviourPtr, integer LineNum, integer Instruction) {
    Instructions += [
        CurrentBehaviourPtr,
        LineNum,
        Instruction,
        llGetListLength(Parameters)
            ];
}
// Convert event name to internal code.
integer GetEventCode(string EventName) {
    integer EventCode;
    integer E = llListFindList(EventNames, [ EventName ]);
    if (E == -1) {
        EventCode = E_CUSTOM;
    }
    else {
        EventCode = llList2Integer(EventNames, E + 1);
    }
    return EventCode;
}
// Convert event code to event name (not for custom events)
string GetEventName(integer EventCode) {
    integer E = llListFindList(EventNames, [ EventCode ]);
    if (E == -1) {
        return "(none)";
    }
    else {
        string EventName = llList2String(EventNames, E - 1);
        // Capitalise the first letter (assUming that this is enough)
        EventName = llToUpper(llGetSubString(EventName, 0, 0)) + llGetSubString(EventName, 1, -1);
        return EventName;
    }
}
// Convert command string into internal integer token
integer ParseInstruction(string InstructionSource) {
    if (InstructionSource == "create") return I_CREATE;
    else if (InstructionSource == "delete") return I_DELETE;
    else if (InstructionSource == "wait") return I_WAIT;
    else if (InstructionSource == "userwait") return I_USER_WAIT;
    else if (InstructionSource == "walk") return I_WALK;
    else if (InstructionSource == "run") return I_RUN;
    else if (InstructionSource == "fly") return I_FLY;
    else if (InstructionSource == "say") return I_SAY;
    else if (InstructionSource == "shout") return I_SHOUT;
    else if (InstructionSource == "whisper") return I_WHISPER;
    else if (InstructionSource == "usersay") return I_USER_SAY;
    else if (InstructionSource == "teleport") return I_TELEPORT;
    else if (InstructionSource == "animation") return I_ANIMATION_START;
    else if (InstructionSource == "stopanimation") return I_ANIMATION_STOP;
    else if (InstructionSource == "print") return I_PRINT;
    else if (InstructionSource == "sit") return I_SIT;
    else if (InstructionSource == "stand") return I_STAND;
    else if (InstructionSource == "touch") return I_TOUCH;
    else if (InstructionSource == "jump") return I_JUMP;
    else if (InstructionSource == "sensoronce") return I_SENSOR_ONCE;
    else if (InstructionSource == "sensorrepeat") return I_SENSOR_REPEAT;
    else if (InstructionSource == "sensorstop") return I_SENSOR_STOP;
    else if (InstructionSource == "sensorremember") return I_SENSOR_REMEMBER;
    else if (InstructionSource == "click") return I_CLICK;
    else if (InstructionSource == "userclear") return I_CLEAR_USER;
    else if (InstructionSource == "menu") return I_MENU;
    else if (InstructionSource == "debug") return I_DEBUG;
    else if (InstructionSource == "face") return I_FACE;
    else if (InstructionSource == "hovertext") return I_HOVER;
    else if (InstructionSource == "sound") return I_SOUND;
    else return -1;
}
// Parse parameter string, returning list
list ParseParams(integer Instruction, string ParamsSource, integer LineNum, string SourceLine) {
    ParamsSource = llStringTrim(ParamsSource, STRING_TRIM);
    if (Instruction  == I_CREATE) {
        // format is [ <first name>, <last name>, <appearence card>
        list Parts = llParseStringKeepNulls(ParamsSource, [ " " ], []);
        if (llGetListLength(Parts) < 3) {
            CompilationError("Create needs: <first name> <last name> \"<appearance card>\"", LineNum, SourceLine);
            return [ NAN_INT ]; // cause error detection in calling function
        }
        string FirstName = llList2String(Parts, 0);
        string LastName = llList2String(Parts, 1);
        string Appearance = llDumpList2String(llList2List(Parts, 2, -1), " ");
        if (llGetListLength(Parts) < 3) {
            CompilationError("Create needs: <first name> <last name> \"<appearance card>\"", LineNum, SourceLine);
            return [ NAN_INT ]; // cause error detection in calling function
        }
        if (llGetSubString(Appearance, 0, 0) != "\"" || llGetSubString(Appearance, -1, -1) != "\"") {
            CompilationError("Appearance card name must be in \" quotes", LineNum, SourceLine);
            return [ NAN_INT ]; // cause error detection in calling function
        }
        Appearance = llGetSubString(Appearance, 1, -2); // strip quotes
        if (Appearance == "") { // they just had a pair of quotes, nothing between
            CompilationError("Appearance card name missing", LineNum, SourceLine);
            return [ NAN_INT ]; // cause error detection in calling function
        }
        if (llGetInventoryType(Appearance) != INVENTORY_NOTECARD) {
            Appearance += APPEARANCE_CARD_SUFFIX;
            if (llGetInventoryType(Appearance) != INVENTORY_NOTECARD) {
                CompilationError("Appearance notecard not found: '" + Appearance + "'", LineNum, SourceLine);
                return [ NAN_INT ];
            }
        }
        return [ FirstName, LastName, Appearance ];
    }
    else if (Instruction == I_DELETE) {
        return [];
    }
    else if (Instruction == I_WAIT) {
        integer Seconds = (integer)ParamsSource;
        if (Seconds <= 0 || Seconds > 3600) {
            CompilationError("Invalid number of seconds: '" + ParamsSource + "'", LineNum, SourceLine);
            return [ NAN_INT ]; // cause error detection in calling function
        }
        return [ Seconds ];
    }
    else if (Instruction == I_USER_WAIT) {
        float Distance = (float)ParamsSource;
        if (Distance <= 0.0 || Distance > 100.0) {
            CompilationError("Invalid distance: '" + ParamsSource + "'", LineNum, SourceLine);
            return [ NAN_INT ]; // cause error detection in calling function
        }
        return [ Distance ];
    }
    else if (Instruction == I_WALK || Instruction == I_RUN || Instruction == I_FLY) {
        return ParseDestination(ParamsSource, LineNum, SourceLine);
    }
    else if (Instruction == I_SAY || Instruction == I_SHOUT || Instruction == I_WHISPER || Instruction == I_USER_SAY) {
        if (ParamsSource == "") {
            CompilationError("Needs text", LineNum, SourceLine);
            return [ NAN_INT ]; // cause error detection in calling function
        }
        if (llGetSubString(ParamsSource, 0, 0) != "\"" || llGetSubString(ParamsSource, -1, -1) != "\"" || llStringLength(ParamsSource) < 3) {
            CompilationError("Text must be in \" quotes", LineNum, SourceLine);
            return [ NAN_INT ]; // cause error detection in calling function
        }
        string Text = llGetSubString(ParamsSource, 1, -2);
        return [ Text ]; // return text to say/shout/whisper
    }
    else if (Instruction == I_TELEPORT) {
        return ParseDestination(ParamsSource, LineNum, SourceLine);
    }
    else if (Instruction == I_ANIMATION_START) {
        string Animation = ParamsSource;
        if (Animation == "") {
            CompilationError("Needs name of animation", LineNum, SourceLine);
            return [ NAN_INT ]; // cause error detection in calling function
        }
        if (llGetSubString(Animation, 0, 0) != "\"" || llGetSubString(Animation, -1, -1) != "\"") {
            CompilationError("Animation name must be in \" quotes", LineNum, SourceLine);
            return [ NAN_INT ]; // cause error detection in calling function
        }
        Animation = llGetSubString(Animation, 1, -2); // strip quotes
        if (Animation == "") { // they just had a pair of quotes, nothing between
            CompilationError("Animation name missing", LineNum, SourceLine);
            return [ NAN_INT ]; // cause error detection in calling function
        }
        if (llGetInventoryType(Animation) != INVENTORY_ANIMATION) {
            CompilationError("Animation file not found: '" + Animation + "'", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        return [ Animation ];
    }
    else if (Instruction == I_ANIMATION_STOP) {
        string Animation = ParamsSource;
        return [];
    }
    else if (Instruction == I_PRINT) {
        if (ParamsSource == "") {
            CompilationError("Needs text", LineNum, SourceLine);
            return [ NAN_INT ]; // cause error detection in calling function
        }
        if (llGetSubString(ParamsSource, 0, 0) != "\"" || llGetSubString(ParamsSource, -1, -1) != "\"" || llStringLength(ParamsSource) < 3) {
            CompilationError("Text must be in \" quotes", LineNum, SourceLine);
            return [ NAN_INT ]; // cause error detection in calling function
        }
        string Text = llGetSubString(ParamsSource, 1, -2);
        return [ Text ];
    }
    else if (Instruction == I_SIT) {
        string ObjectName = ParamsSource;
        if (ObjectName != "") {
            if (llGetSubString(ParamsSource, 0, 0) != "\"" || llGetSubString(ParamsSource, -1, -1) != "\"" || llStringLength(ParamsSource) < 3) {
                CompilationError("Object name must be in \" quotes", LineNum, SourceLine);
                return [ NAN_INT ]; // cause error detection in calling function
            }
        }
        return [ ObjectName ];
    }
    else if (Instruction == I_STAND) {
        return [];
    }
    else if (Instruction == I_TOUCH) {
        string ObjectName = ParamsSource;
        if (ObjectName != "") {
            if (llGetSubString(ParamsSource, 0, 0) != "\"" || llGetSubString(ParamsSource, -1, -1) != "\"" || llStringLength(ParamsSource) < 3) {
                CompilationError("Object name must be in \" quotes", LineNum, SourceLine);
                return [ NAN_INT ]; // cause error detection in calling function
            }
        }
        return [ ObjectName ];
    }
    else if (Instruction == I_JUMP) {
        string EventName = llToLower(ParamsSource);
        return [ EventName ];
    }
    else if (Instruction == I_SENSOR_ONCE) {
        float Range = (float)ParamsSource;
        if (Range <= 0.0) {
            CompilationError("Invalid range value", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        return [ "U", "", NULL_KEY, AGENT, Range, PI ];
    }
    else if (Instruction == I_SENSOR_REPEAT) {
        float Range = (float)ParamsSource;
        if (Range <= 0.0) {
            CompilationError("Invalid range value", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        return [ "U", "", NULL_KEY, AGENT, Range, PI, 2.0 ];
    }
    else if (Instruction == I_SENSOR_STOP) {
        return [];
    }
    else if (Instruction == I_SENSOR_REMEMBER || Instruction == I_CLICK) { // same params for both
        string OnOff = llToLower(ParamsSource);
        integer Value = OnOff2Integer(OnOff);
        if (Value == -1) {
            CompilationError("Value not \"On\" or \"Off\"", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        return [ Value ];
    }
    else if (Instruction == I_CLEAR_USER) {
        return [];
    }
    else if (Instruction == I_MENU) {
        return ParseMenu(ParamsSource, LineNum, SourceLine);
    }
    else if (Instruction == I_DEBUG) {
        string OnOff = llToLower(ParamsSource);
        integer Value = OnOff2Integer(OnOff);
        if (Value == -1) {
            CompilationError("Value not \"On\" or \"Off\"", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        return [ Value ];
    }
    else if (Instruction == I_FACE) {
        string FaceParam = llToLower(ParamsSource);
        if (llToLower(FaceParam) == "user") {
            return [ "user" ];
        }
        if (llSubStringIndex(FaceParam, " ") > -1 || FaceParam  == "") {
            CompilationError("Value not \"User\" or number of degrees", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        if (
            FaceParam == "n" || FaceParam == "s" || FaceParam == "w" || FaceParam == "e" ||
            FaceParam == "ne" || FaceParam == "se" || FaceParam == "nw" || FaceParam == "sw"
                ) {
                    return [ FaceParam ];
                }
        // Assume it's degrees
        float Degrees = (float)FaceParam;
        if (Degrees > 360.0 || Degrees < 0.0) {
            CompilationError("Value not in range 0-360", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        return [ Degrees ];
    }
    else if (Instruction == I_HOVER) {
        return ParseHover(ParamsSource, LineNum, SourceLine);
    }
    else if (Instruction == I_SOUND) {
        return ParseSound(ParamsSource, LineNum, SourceLine);
    }
    else {
        return [];
    }
}
ProcessMenu(integer BehaviourPtr, integer InstructionPtr, integer ParamsPtr) {
    string Title = llList2String(Parameters, ParamsPtr);
    string Description = llList2String(Parameters, ParamsPtr + 1);
    string LabelsStr = llList2String(Parameters, ParamsPtr + 2);
    string EventsStr = llList2String(Parameters, ParamsPtr + 3);
    list Labels = llParseStringKeepNulls(LabelsStr, [ "|" ], []);
    list Events = llParseStringKeepNulls(EventsStr, [ "|" ], []);
    list Buttons = [];
    // Parse labels and events to create callback entries
    ClearMenuCallBacks(BehaviourPtr);
    integer Len = llGetListLength(Labels);
    integer I;
    for (I = 0; I < Len; I++) {
        string Label = llList2String(Labels, I);
        string Event = llList2String(Events, I);
        Buttons += Label;
        MenuCallBacks += [ BehaviourPtr, Label, Event ];
    }
    key UserId = llList2Key(Behaviours, BehaviourPtr + BEH_USER_ID);
    SendMenuCommandUser(UserId, UTIL_MENU_INIT, []);
    SendMenuCommandUser(UserId, UTIL_MENU_ADD, [ "!" + Title, Description ] + Buttons);
    SendMenuCommandUser(UserId, UTIL_MENU_START, []);
}
list ParseMenu(string ParamsSource, integer LineNum, string SourceLine) {
    list Return = [];
    integer Space = llSubStringIndex(ParamsSource, " ");
    string Command = "";
    string MenuParams = "";
    if (Space == -1) {
        Command = ParamsSource;
    }
    else {
        Command = llGetSubString(ParamsSource, 0, Space - 1);
        MenuParams = llStringTrim(llGetSubString(ParamsSource, Space + 1, -1), STRING_TRIM);
    }
    Command = llToLower(Command);
    if (Command == "init") {
        BuildMenuTitle = "";
        BuildMenuDescription = "";
        BuildMenuButtonLabels = [];
        BuildMenuButtonEvents = [];
        Return = [ NO_INSTRUCTION ];
    }
    else if (Command == "title") {
        BuildMenuTitle = StripQuotesTolerant(MenuParams);
        if (BuildMenuTitle == ADMIN_MENU_TITLE) {
            CompilationError("Title cannot be '" + ADMIN_MENU_TITLE + "'", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        if (!ValidString(BuildMenuTitle)) {
            CompilationError("Invalid character(s) in title", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        Return = [ NO_INSTRUCTION ];
    }
    else if (Command == "description") {
        BuildMenuDescription = StripQuotesTolerant(MenuParams);
        if (!ValidString(BuildMenuDescription)) {
            CompilationError("Invalid character(s) in description", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        Return = [ NO_INSTRUCTION ];
    }
    else if (Command == "button") {
        // format is: "<label>" <eventname>
        list Parts = llParseString2List(MenuParams, [ "\"" ], [ "" ]);
        if (llGetListLength(Parts) != 2) {
            CompilationError("Invalid Menu Button values", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        string Label = llStringTrim(llList2String(Parts, 0), STRING_TRIM);
        string EventName = llStringTrim(llList2String(Parts, 1), STRING_TRIM);
        if (Label == "" || EventName == "") {
            CompilationError("Invalid parameters", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        if (!ValidString(Label)) {
            CompilationError("Invalid character(s) in button label", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        BuildMenuButtonLabels += Label;
        BuildMenuButtonEvents += EventName;
        Return = [ NO_INSTRUCTION ];
    }
    else if (Command == "send") {
        if (BuildMenuTitle == "") {
            CompilationError("No menu title specified", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        if (BuildMenuButtonLabels == []) {
            CompilationError("No menu buttons specified", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        string LabelStr = llDumpList2String(BuildMenuButtonLabels, "|");
        string EventStr = llDumpList2String(BuildMenuButtonEvents, "|");
        Return = [ BuildMenuTitle, BuildMenuDescription,  LabelStr, EventStr ];
    }
    else {
        CompilationError("Invalid Menu command", LineNum, SourceLine);
        return [ NAN_INT ];
    }
    return Return;
}
// Resets the menu for this behaviour
ClearMenuCallBacks(integer BehaviourPtr) {
    list NewMenuCallBacks= [];
    integer Len = llGetListLength(MenuCallBacks);
    integer M;
    for (M = 0; M < Len; M += MCB_STRIDE) {
        integer ThisBehaviourPtr = llList2Integer(MenuCallBacks, M);
        if (ThisBehaviourPtr == -1) { // this is for a different behaviour
            NewMenuCallBacks += llList2List(MenuCallBacks, M, M + MCB_STRIDE - 1);
        }
    }
    MenuCallBacks = NewMenuCallBacks;
}
// Returns [ <text>, <color>, <alpha> ]
list ParseHover(string ParamsSource, integer LineNum, string SourceLine) {
    if (ParamsSource == "") return [ "", ZERO_VECTOR, 0.0 ]; // Clear text if no params
    if (llGetSubString(ParamsSource, 0, 0) != "\"") {
        CompilationError("Invalid HoverText command", LineNum, SourceLine);
        return [ NAN_INT ];
    }
    // Otherwise, format is: "<text>" [<colour>]
    list L = llParseString2List(ParamsSource, [ "\"" ], []);
    integer Len = llGetListLength(L);
    string Text = llList2String(L, 0);
    vector Color  = <1.0, 1.0, 1.0>; // default to white
    if (Len == 2) { // text and color
        Color = ParseHoverColor(llList2String(L, 1));
        if (Color.x < 0.0) { // hacky way of indicating an error
            CompilationError("Invalid HoverText color", LineNum, SourceLine);
            return [ NAN_INT ];
        }
    }
    return [ Text, Color, 1.0 ];
}
// Returns [ <uuid>, <volume> ]
list ParseSound(string ParamsSource, integer LineNum, string SourceLine) {
    if (llGetSubString(ParamsSource, 0, 0) != "\"") {
        CompilationError("Invalid Sound command", LineNum, SourceLine);
        return [ NAN_INT ];
    }
    // Otherwise, format is: "<name>" [<volume>]
    list L = llParseString2List(ParamsSource, [ "\"" ], []);
    integer Len = llGetListLength(L);
    string Name = llList2String(L, 0);
    if (llGetInventoryType(Name) != INVENTORY_SOUND) {
        CompilationError("Can't find sound file", LineNum, SourceLine);
        return [ NAN_INT ];
    }
    Name = llGetInventoryKey(Name); // convert from filename to UUID
    float Volume = 1.0; // default to 100%
    if (Len == 2) { // text and color
        Volume = (float)llList2String(L, 1);
        // Input is percent (0-100) output is 0-1)
        Volume /= 100;
    }
    return [ Name, Volume ];
}
// Returns <-1.0, 0.0, 0.0> if invalid
vector ParseHoverColor(string Param) {
    vector ReturnColor;
    Param = llToLower(llStringTrim(Param, STRING_TRIM)); // lower case, trimmed
    if (llGetSubString(Param, 0, 0) == "<") { // it's in "<r, g, b>" format
        ReturnColor = (vector)Param / 256.0; // convert 0-255 to 0-1
    }
    else { // assume it's a colour name
        if (Param == "white") ReturnColor = <1.0, 1.0, 1.0>;
        else if (Param == "black") ReturnColor = <0.0, 0.0, 0.0>;
        else if (Param == "red") ReturnColor = <1.0, 0.1, 0.1>;
        else if (Param == "green") ReturnColor = <0.1, 1.0, 0.1>;
        else if (Param == "blue") ReturnColor = <0.1, 0.1, 1.0>;
        else if (Param == "yellow") ReturnColor = <1.0, 1.0, 0.1>;
        else if (Param == "cyan") ReturnColor = <0.1, 1.0, 1.0>;
        else if (Param == "magenta") ReturnColor = <1.0, 0.1, 1.0>;
        else ReturnColor = <-1.0, 0.0, 0.0>;
    }
    return ReturnColor;
}
// Subsitutes variables in text
string Expand(integer BehaviourPtr, string Text) {
    if (llSubStringIndex(Text, "{") == -1) return Text; // No variables
    string Expanded = Text;
    while (llSubStringIndex(Expanded, "{") > -1) {
        integer P = llSubStringIndex(Expanded, "{");
        integer Q = SubStringIndex(Expanded, P + 1, "}");
        if (Q ==  -1) return Text; // no matching }, just return the lot
        string VariableName = llGetSubString(Expanded, P + 1, Q - 1);
        string Value = GetVariable(BehaviourPtr, VariableName);
        // Reassemble text
        string Part1 = "";
        string Part2 = "";
        if (P > 0) Part1 = llGetSubString(Expanded, 0, P - 1);
        if (Q < (llStringLength(Expanded) - 1)) Part2 = llGetSubString(Expanded, Q + 1, -1);
        Expanded =  Part1 + Value + Part2;
    }
    return Expanded;
}
// Allows searching for substring starting at a point in the string
integer SubStringIndex(string Text, integer From, string SubString) {
    if (From > 0) Text = llGetSubString(Text, From, -1); // remove part before from
    integer Index = llSubStringIndex(Text, SubString);
    if (Index > -1) Index += From; // compensate for missing part
    return Index;
}
SetBuiltInEventNames() {
    EventNames = [
        "start", E_START,
        "sensor", E_SENSOR,
        "click", E_CLICK
            ];
}
// Face direction could be "User" or direction in degrees (0-360), or cardinals (N, SW, etc)
rotation GetFaceDirection(integer BehaviourPtr, string FaceDirection) {
    rotation Rot = ZERO_ROTATION;
    FaceDirection = llToLower(FaceDirection);
    if (FaceDirection == "user") {
        key UserId = llList2Key(Behaviours, BehaviourPtr + BEH_USER_ID);
        if (UserId == NULL_KEY) {
            return ZERO_ROTATION;
        }
        key NpcId = llList2Key(Behaviours, BehaviourPtr + BEH_NPC_ID);
        vector UserPos = llList2Vector(llGetObjectDetails(UserId, [ OBJECT_POS ]), 0);
        vector NpcPos = llList2Vector(llGetObjectDetails(NpcId, [ OBJECT_POS ]), 0);
        // Based on https://www.virtualverse.one/forums/threads/kept-simple-rotate-object-towards-another-object.178/
        Rot = llRotBetween( <1.0, 0.0, 0.0>, llVecNorm(UserPos - NpcPos));
        return Rot;
    }
    // Is it a value in degrees?
    float Degrees = (float)FaceDirection;
    if (llGetSubString(FaceDirection, 0, 0) == "0" || Degrees != 0.0) {
        // It's degrees, nothing to do
    }
    else {
        // It's either a cardinal direction or invalid
        if (FaceDirection == "n") Degrees = 0.0;
        else if (FaceDirection == "s") Degrees = 180.0;
        else if (FaceDirection == "w") Degrees = 270.0;
        else if (FaceDirection == "e") Degrees = 90.0;
        else if (FaceDirection == "nw") Degrees = 315.0;
        else if (FaceDirection == "sw") Degrees = 225.0;
        else if (FaceDirection == "ne") Degrees = 45.0;
        else if (FaceDirection == "se") Degrees = 135.0;
        else {
            llOwnerSay("Invalid Face direction: " + FaceDirection);
            Degrees = 0.0;
        }
    }
    // In the real world (navigation, compasses, boats, planes, etc), north is 0 degrees and as
    // the degrees value increases it works clockwise (so 90 is east). This
    // is what we've been working with so far. But in OpenSim (and maths generally), 0 degrees is east
    // and increasing values work anticlockwise (counterclockwise).
    // So, let's reverse the direction first.
    Degrees = 360.0 - Degrees;
    // And below, we add a 90 degree rotation so 0 faces east, not north
    vector RotV = <0.0, 0.0, Degrees> * DEG_TO_RAD;
    Rot = llEuler2Rot(RotV) * llEuler2Rot((<0.0, 0.0, 90> * DEG_TO_RAD));
    return Rot;
}
// Destinations strings are in the format:
//     <region|local> <x> <y> <z>
// or: User <distance>
// or: <variablename>
list ParseDestination(string ParamsSource, integer LineNum, string SourceLine) {
    // Handle "User" type first (makes the other if statements easier)
    if (llToLower(llGetSubString(ParamsSource, 0, 3)) == "user") {
        float Distance = (float)llGetSubString(ParamsSource, 5, -1);
        if (Distance == 0.0) Distance = 2.0; // default to 2m
        return [ DEST_USER, Distance ];
    }
    else if (llToLower(llGetSubString(ParamsSource, 0, 7)) == "waypoint") {
        UsesWaypoints = TRUE; // we're using waypoints, so we'll need to get that data
        string WaypointName = llGetSubString(ParamsSource, 9, -1);
        WaypointName = StripQuotesTolerant(WaypointName);
        return [ DEST_WAYPOINT, WaypointName ];
    }
    integer Space = llSubStringIndex(ParamsSource, " ");
    if (Space > -1) { // if it has spaces, it's not a variable
        integer DestinationCode = GetDestinationCode(llGetSubString(ParamsSource, 0, Space -1));
        if (Space == -1 || DestinationCode == -1) {
            CompilationError("Invalid destination", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        // Now we have the region/local destination code, we parse the x, y and z coords
        string CoordsString = llGetSubString(ParamsSource, Space + 1, -1);
        list Coords = llParseStringKeepNulls(CoordsString, [ " " ], []);
        if (llGetListLength(Coords) != 3) {
            CompilationError("Invalid coordinates", LineNum, SourceLine);
            return [ NAN_INT ];
        }
        float X = (float)llList2String(Coords, 0);
        float Y = (float)llList2String(Coords, 1);
        float Z = (float)llList2String(Coords, 2);
        vector Pos = <X, Y, Z>;
        return [ DestinationCode, Pos ];
    }
    else { // no spaces, so maybe a variable
        string VarName = ParamsSource;
        return [ DEST_VARIABLE, VarName ];
    }
}
integer GetDestinationCode(string DestinationString) {
    DestinationString = llToLower(DestinationString);
    if (DestinationString == "region") return DEST_REGION;
    else if (DestinationString == "local") return DEST_LOCAL;
    else if (DestinationString == "waypoint") return DEST_WAYPOINT;
    else return -1;
}
// Returns zero vector if invalid
vector GetDestinationPos(integer BehaviourPtr, list Params) {
    integer DestinationCode = llList2Integer(Params, 0);
    vector Pos;
    if (DestinationCode == DEST_REGION) {
        Pos = llList2Vector(Params, 1);
    }
    else if (DestinationCode == DEST_LOCAL) {
        Pos = llList2Vector(Params, 1);
        Pos = llGetPos() + (Pos * llGetRot());
    }
    else if (DestinationCode == DEST_USER) {
        key UserId = llList2Key(Behaviours, BehaviourPtr + BEH_USER_ID);
        if (UserId == NULL_KEY) {
            llOwnerSay("Can't move to user because no user has been detected");
            key NpcId = llList2Key(Behaviours, BehaviourPtr + BEH_NPC_ID);
            return osNpcGetPos(NpcId); // use their own position, so they don't move
        }
        float Distance = llList2Float(Params, 1);
        list L = llGetObjectDetails(UserId, [ OBJECT_POS, OBJECT_ROT ]);
        vector UserPos = llList2Vector(L, 0);
        rotation UserRot = llList2Rot(L, 1);
        Pos  = UserPos + (<Distance, 0.0, 0.0> * UserRot); // <distance>meters in front of user
    }
    else if (DestinationCode == DEST_VARIABLE) { // not currently used
        string VarName = llList2String(Params, 1);
        integer V = llListFindList(Variables, [ BehaviourPtr, VarName ]);
        if (V == -1) { llOwnerSay("Variable doesn't exist: " + VarName); return ZERO_VECTOR; }
        string Value = llList2String(Variables, V + VAR_VALUE);
        Pos = (vector)Value; // will be zero vector if variable not set
    }
    else if (DestinationCode == DEST_WAYPOINT) {
        string WaypointName = llList2String(Params, 1);
        Pos = LocateWaypoint(BehaviourPtr, WaypointName);
    }
    return Pos;
}
// Finds the nearest waypoint with the given name
vector LocateWaypoint(integer BehaviourPtr, string WaypointName) {
    string WaypointNameLower = llToLower(WaypointName); // case-insensitive comparisons
    key NpcId = llList2Key(Behaviours, BehaviourPtr + BEH_NPC_ID);
    vector NpcPos = osNpcGetPos(NpcId);
    float NearestDistance = 99999.9;
    vector NearestPos = ZERO_VECTOR;
    key NearestId = NULL_KEY;
    integer R; // row number
    integer P; // pointer to start of stride in list
    for (R = 0; R < WaypointsCount; R++) {
        P = R * WP_STRIDE;
        key WaypointId = (key)llList2String(Waypoints, P + WP_UUID);
        if (WaypointName != "") {
            string ThisWaypointName = llList2String(Waypoints, P + WP_NAME);
            if (llToLower(ThisWaypointName) != WaypointNameLower) WaypointId = NULL_KEY;
        }
        if (WaypointId != NULL_KEY) { // if it's not been rejected by name check
            vector WaypointPos = GetObjectPos(WaypointId);
            float ThisDistance = llVecDist(WaypointPos, NpcPos);
            if (ThisDistance < NearestDistance) {
                NearestId = WaypointId;
                NearestPos = WaypointPos;
                NearestDistance = ThisDistance;
            }
        }
    }
    if (NearestId == NULL_KEY) {
        llOwnerSay("No waypoint found ('" + WaypointName + "')");
        return NpcPos;
    }
    return NearestPos;
}
// Takes list of objects sensed by the NPC attachment, and uses that in conjunction
// with the ComposerObjects list to find the nearest one.
SitOnNearestObject(key NpcId, integer BehaviourPtr, list SensorObjects) {
    string ObjectName = llList2String(Behaviours, BehaviourPtr + BEH_OBJECT_NAME);
    key NearestId = FindNearestObjectSensor(NpcId, ObjectName, TRUE, SensorObjects);
    if (NearestId != NULL_KEY) { // if we have found something that matches
        osNpcSit(NpcId, NearestId, OS_NPC_SIT_NOW);
    }
}
// Causes the NPC to touch the nearest object with the given name (blank name matches all)
TouchObject(key NpcId, integer BehaviourPtr, list SensorObjects) {
    string ObjectName = llList2String(Behaviours, BehaviourPtr + BEH_OBJECT_NAME);
    key NearestId = FindNearestObjectSensor(NpcId, ObjectName, FALSE, SensorObjects);
    if (NearestId != NULL_KEY) { // if we have found something that matches
        osNpcTouch(NpcId, NearestId, LINK_THIS);
    }
}
// Find the nearest object with the given name (all if blank). List of sensor results
// is included to be processed with the lists of objects from Composer instances.
key FindNearestObjectSensor(key NpcId, string ObjectName, integer SitOnly, list SensorObjects) {
    vector NpcPos = osNpcGetPos(NpcId);
    key NearestId = FindNearestObject(NpcPos, ObjectName, SitOnly, ComposerObjects + SensorObjects);
    return NearestId;
}
// This takes a list of object UUIDs and a position and finds the nearest object to that position
key FindNearestObject(vector Pos, string ObjectName, integer SitOnly, list Objects) {
    key NearestId = NULL_KEY;
    float NearestDistance = 99999.9;
    integer Len = llGetListLength(Objects);
    integer ObjPtr;
    for (ObjPtr = 0; ObjPtr < Len; ObjPtr++) {
        key ObjectId = (key)llList2String(Objects, ObjPtr);
        // First, determine if the name matches (or if no name is specified)
        integer NameMatch = FALSE;
        if (ObjectName == "") {
            NameMatch = TRUE; // no name specified, so everything matches
        }
        else {
            string ThisName = llKey2Name(ObjectId);
            if (ThisName == ObjectName) NameMatch = TRUE; // case must match (to save CPU here)
        }
        if (NameMatch) {
            integer Relevant = TRUE;
            if (SitOnly) {
                if (!IsSittable(ObjectId)) Relevant = FALSE;
            }
            if (Relevant) {
                vector ThisPos = GetObjectPos(ObjectId);
                float Distance = llVecDist(Pos, ThisPos);
                if (Distance < NearestDistance) {
                    NearestId = ObjectId;
                    NearestDistance = Distance;
                }
            }
        }
    }
    return NearestId;
}
integer IsSittable(key ObjectId) {
    integer Sittable = llList2Integer(osGetPrimitiveParams(ObjectId, [ PRIM_SIT_TARGET ]), 0);
    return Sittable;
}
vector GetObjectPos(key ObjectId) {
    list ObjectDetails = llGetObjectDetails(ObjectId, [ OBJECT_POS ]);
    return llList2Vector(ObjectDetails, 0);
}
RemoveAllNpcs() {
    integer Behaviour;
    for (Behaviour = 0; Behaviour < BehavioursLength; Behaviour++) {
        integer BehaviourPtr = Behaviour * BEH_STRIDE;
        key NpcId = llList2Key(Behaviours, BehaviourPtr + BEH_NPC_ID);
        if (NpcId != NULL_KEY) osNpcRemove(NpcId);
    }
}
ShowAdminMenu() {
    SendMenuCommandUser(OwnerId, UTIL_MENU_INIT, []);
    string Description = "NPC Director administration options:\n\n";
    list Buttons = [];
    if (CurrentState == STATE_READY || CurrentState == STATE_STOPPED) {
        Description += "Start - Start system\n";
        Buttons += "Start";
        Buttons += " ";
    }
    else if (CurrentState == STATE_RUNNING) {
        Description += "Restart - Start again\n";
        Description += "Stop - Stop system\n";
        Buttons += "Restart";
        Buttons += "Stop";
    }
    else if (CurrentState == STATE_ERRORS) {
        Description += "Restart - Start again\n";
        Buttons += "Restart";
    }
    else {
        return; // still booting, presumably
    }
    Description += WAYPOINTS_MENU_TITLE + " - Waypoints menu\n";
    Description += APPEARANCE_MENU_TITLE + " - Maintain NPCs\n";
    Description += "Done - Close menu";
    Buttons += " ";
    Buttons += "*" + WAYPOINTS_MENU_TITLE;
    Buttons += "*" + APPEARANCE_MENU_TITLE;
    Buttons += "Done";
    SendMenuCommandUser(OwnerId, UTIL_MENU_ADD, [ "!Admin", Description ] + Buttons );
    SendMenuCommandUser(OwnerId, UTIL_MENU_ADD, [ "!" + WAYPOINTS_MENU_TITLE, "Waypoints", "Show", "Hide", "*" ]);
    SendMenuCommandUser(OwnerId, UTIL_MENU_ADD, [ "!" + APPEARANCE_MENU_TITLE, "Maintain recorded NPCs", "List", "Create", "Delete", "*" ]);
    SendMenuCommandUser(OwnerId, UTIL_MENU_CLOSEOPTION, [ "Admin|Done" ]);
    SendMenuCommandUser(OwnerId, UTIL_MENU_START, []);
}
// Process option selected from admin menus - returns TRUE if restart needed
integer ProcessAdminMenu(string Menu, string Option) {
    if (Menu == ADMIN_MENU_TITLE) {
        if (Option == "Start") {
            return TRUE;
        }
        else if (Option == "Stop") {
            SetState(STATE_STOPPED);
            RemoveAllNpcs();
        }
        else if (Option == "Done") {
            state Restart;
        }
        else if (Option == "Restart") {
            RemoveAllNpcs();
            state Restart;
        }
    }
    else if (Menu == WAYPOINTS_MENU_TITLE) {
        if (Option == "Show") {
            llRegionSay(WAYP_CHAT_CHANNEL, "S");
        }
        else if (Option == "Hide") {
            llRegionSay(WAYP_CHAT_CHANNEL, "H");
        }
    }
    else if (Menu == APPEARANCE_MENU_TITLE) {
        if (Option == "List") {
            ListAppearances();
        }
        else if (Option == "Create") {
            CreateAppearance();
        }
    }
    else {
        llOwnerSay("Unknown Admin menu name: " + Menu + " (" + Option + ")");
    }
    return FALSE;
}
ProcessAdminTextbox(string Text) {
    list L = llParseStringKeepNulls(Text, [ "|" ], []);
    string Tag = llList2String(L, 0);
    string Response = llList2String(L, 1);
    if (Tag == "app") { // create NPC appearance notecard
        if (Response == "") {
            llDialog(OwnerId, "\nNPC create cancelled", [ "OK" ], -12879337);
            return;
        }
        if (!ValidString(Response)) {
            llDialog(OwnerId, "\nInvalid character(s) in NPC name", [ "OK" ], -12879337);
            return;
        }
        string AttachmentName = GetAttachmentName();
        if (AttachmentName == "") {
            llOwnerSay("*** ERROR: Attachment object not found!");
        }
        ///%%%%
        // Now we can create the NPC appearance notecard.
        // First, attach the attachment
        osForceAttachToOtherAvatarFromInventory(OwnerId, AttachmentName, ATTACH_BELLY);
        // Create the notecard
        osAgentSaveAppearance(OwnerId, Response + APPEARANCE_CARD_SUFFIX);
        // And detach the attachment
        llRegionSayTo(OwnerId, NPC_CHAT_CHANNEL, "D");
        llDialog(OwnerId, "\nNPC created: " + Response, [ "OK" ], -12879337);
    }
}
// List all NPC appearance notecards
ListAppearances() {
    string MyName = llGetObjectName();
    llSetObjectName("NPC");
    integer Count = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer N;
    for (N = 0; N < Count; N++) {
        string Name = llGetInventoryName(INVENTORY_NOTECARD, N);
        if (llGetSubString(Name, 0 - APPEARANCE_CARD_SUFFIX_LENGTH, -1) == APPEARANCE_CARD_SUFFIX) { //  if it ends in ".app"
            Name = llGetSubString(Name, 0, -1 - APPEARANCE_CARD_SUFFIX_LENGTH);
            llOwnerSay(Name);
        }
    }
    llSetObjectName(MyName);
}
// Start process of creating appearance
CreateAppearance() {
    string Tag = "app";
    string Message = "This will create an NPC file based on your current appearance.\nEnter name for NPC, or blank to cancel:";
    llMessageLinked(LINK_ROOT, UTIL_TEXTBOX_CALL, Tag + "|" + Message, llGetOwner());
}
// Returns the name of the attachment object
string GetAttachmentName() {
    integer AttachmentNameLength = llStringLength(ATTACHMENT_NAME);
    integer Count = llGetInventoryNumber(INVENTORY_OBJECT);
    integer N;
    for (N = 0; N < Count; N++) {
        string Name = llGetInventoryName(INVENTORY_OBJECT, N);
        if (llGetSubString(Name, 0, AttachmentNameLength - 1) == ATTACHMENT_NAME) {
            return Name;
        }
    }
    return "";
}
// Set and display the current state of the system
SetState(integer NewState) {
    CurrentState = NewState;
    if (CurrentState == STATE_BOOTING) {
        ShowText("Starting ...", <0.8, 0.8, 0.1>);
    }
    else if (CurrentState == STATE_READY) {
        ShowText("Ready", <0.9, 0.9, 0.1>);
    }
    else if (CurrentState == STATE_RUNNING) {
        ShowText("Active", <0.1, 0.9, 0.1>);
    }
    else if (CurrentState == STATE_STOPPED) {
        ShowText("Stopped", <0.9, 0.1, 0.1>);
    }
    else if (CurrentState == STATE_ERRORS) {
        ShowText("Errors", <0.9, 0.1, 0.1>);
    }
}
ShowText(string Text, vector Colour) {
    llSetText(Text, Colour, 1.0);
}
integer OnOff2Integer(string OnOff) {
    OnOff = llToLower(OnOff);
    if (OnOff == "on") return TRUE;
    else if (OnOff == "off") return FALSE;
    else return -1;
}
// Set correct bit flags for walking, running, etc, suitable for osNpcMoveToTarget()
integer GetMovementType(integer Instruction) {
    if (Instruction == I_WALK) return (OS_NPC_NO_FLY);
    else if (Instruction == I_RUN) return (OS_NPC_RUNNING | OS_NPC_NO_FLY);
    else if (Instruction == I_FLY) return (OS_NPC_FLY | OS_NPC_LAND_AT_TARGET);
    else {
        llOwnerSay("Movement type not found: " + (string)Instruction);
        return OS_NPC_NO_FLY;
    }
}
// Send message to NPC attachment in correct format
SendToNpc(integer BehaviourPtr, string Command, list Params) {
    key AttachmentId = llList2Key(Behaviours, BehaviourPtr + BEH_ATTACHMENT_ID);
    if (AttachmentId == NULL_KEY) return;
    list Message = [ "*NPCB*", Command ] + Params;
    MessageObject(AttachmentId, Message);
}
// Wrapper for osMessageObject
MessageObject(key Destination, list Message) {
    if (Destination == NULL_KEY) return; // let's be fault-tolerant here
    if (ObjectExists(Destination)) {
        osMessageObject(Destination, llDumpList2String(Message, "|"));
    }
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
    return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
// Return true if user/NPC exists (maybe better than version that uses OBJECT_POS)
integer AvatarExists(key AvatarId) {
    return (llGetAgentSize(AvatarId) != ZERO_VECTOR);
}
// Returns FALSE if string contains invalid characters
integer ValidString(string Str) {
    integer Len = llStringLength(Str);
    integer I;
    for (I = 0; I < Len; I++) {
        string Char = llGetSubString(Str, I, I);
        if (Char == "|") return FALSE;
    }
    return TRUE;
}
// Takes a string in double quotes, and strips out the quotes. Validates the format.
// <Text> is the string with quotes.
// This "tolerant" variation just returns an empty string for invalid or empty quoting
string StripQuotesTolerant(string Text) {
    if (Text == "") {    // allow empty string for null value
        return("");
    }
    if (llGetSubString(Text, 0, 0) == "\"" && llGetSubString(Text, -1, -1) == "\"") {     // if surrounded by quotes
        return(llGetSubString(Text, 1, -2));    // strip quotes
    }
    else {
        return("");
    }
}
// Variation of SendMenuCommand (in Utils script docs) that takes avatar ID as argument
SendMenuCommandUser(key AvId, integer Command, list Values) {
    string SendString = llDumpList2String(Values, "|");
    llMessageLinked(LINK_ROOT, Command, SendString, AvId);
}
default {
    on_rez(integer Param) {
        llResetScript();
    }
    state_entry() {
        //////%%%% for testing
        list avatars = llList2ListStrided(osGetAvatarList(), 0, -1, 3);
        integer i;
        for (i=0; i<llGetListLength(avatars); i++)
        {
            string target = llList2String(avatars, i);
            if (osIsNpc(target)) {
                osNpcRemove(target);
            }
        }
        /////
        OwnerId = llGetOwner();
        SetState(STATE_READY);
        state Standby;
    }
}
state Standby {
    on_rez(integer Param) {
        llResetScript();
    }
    state_entry() {
        SetState(STATE_STOPPED);
    }
    touch_start(integer Count) {
        key UserId = llDetectedKey(0);
        if (UserId != OwnerId) return; // only owner can access admin menu
        ShowAdminMenu();
    }
    link_message(integer Sender, integer Num, string Text, key Id) {
        if (Num == UTIL_MENU_RESPONSE) {
            list Selected = llCSV2List(Text);
            string SelectedMenu = llList2String(Selected, 0);
            string SelectedOption = llList2String(Selected, 1);
            if (SelectedMenu == ADMIN_MENU_TITLE || SelectedMenu == WAYPOINTS_MENU_TITLE || SelectedMenu == APPEARANCE_MENU_TITLE) { // it's the admin menu or sub-menu
                if (ProcessAdminMenu(SelectedMenu, SelectedOption)) state Restart;
            }

        }
        else if (Num == UTIL_TEXTBOX_RESPONSE) {
            ProcessAdminTextbox(Text);
        }
    }
}
state Process {
    on_rez(integer Param) {
        llResetScript();
    }
    state_entry() {
        SetState(STATE_BOOTING);
        if (!LoadCards()) {
            SetState(STATE_ERRORS);
            return;
        }
        ComposerObjects = [];
        llRegionSay(MOL_CHANNEL, "L");
        llMessageLinked(LINK_ROOT, LM_DELEGATE_DELETION, "", NULL_KEY);        // World object delegates deletion to us
        if (UsesWaypoints) {
            llOwnerSay("Loading waypoints ...");
            llMessageLinked(LINK_THIS, WS_REQUEST_LIST, "", NULL_KEY); // request list of waypoints (takes time)
        }
        else { // No waypoints, so we're ready to start
            StartProcessing();
        }
    }
    link_message(integer Sender, integer Num, string Text, key Id) {
        if (Num == WS_GIVE_LIST) {
            Waypoints = llParseStringKeepNulls(Text, [ "|" ], []);
            WaypointsCount = llGetListLength(Waypoints) / WP_STRIDE;
            llOwnerSay((string)WaypointsCount + " waypoint(s) found");
            StartProcessing();
        }
        else if (Num == UTIL_MENU_RESPONSE) {
            list Selected = llCSV2List(Text);
            string SelectedMenu = llList2String(Selected, 0);
            string SelectedOption = llList2String(Selected, 1);
            if (SelectedMenu == ADMIN_MENU_TITLE || SelectedMenu == WAYPOINTS_MENU_TITLE || SelectedMenu == APPEARANCE_MENU_TITLE) { // it's the admin menu or sub-menu
                if (ProcessAdminMenu(SelectedMenu, SelectedOption)) state Restart;
            }
            else { // it's a response from the Menu command
                // The ID should be the UUID of the user, so find the behaviour on that basis
                integer BehaviourPtr = llListFindList(Behaviours, [ Id ]) - BEH_USER_ID;
                if (BehaviourPtr < 0) {
                    llOwnerSay("Can't find behavior for menu response");
                    return;
                }
                // Now find the button they clicked
                integer ButtonPtr = llListFindList(MenuCallBacks, [ BehaviourPtr, SelectedOption ]);
                if (ButtonPtr < 0) {
                    llOwnerSay("Can't find button for menu response");
                    return;
                }
                string EventName = llList2String(MenuCallBacks, ButtonPtr + MCB_EVENT);
                ClearTriggers(BehaviourPtr);
                ProcessEvent(BehaviourPtr, E_CUSTOM, llToLower(EventName));
                RestartProcessing();
            }
        }
        else if (Num == UTIL_TEXTBOX_RESPONSE) {
            ProcessAdminTextbox(Text);
        }
    }
    dataserver(key SenderId, string Data) {
        if (llGetSubString(Data, 0, 5) == "*NPCB*") { // is it a command from the NPC subsystem?
            // Find associated behaviour for this NPC
            key AttachmentId = SenderId;
            key NpcId = llGetOwnerKey(AttachmentId);
            integer BehaviourPtr = llListFindList(Behaviours, [ NpcId ]);
            if (BehaviourPtr == -1) { llOwnerSay("Can't find NPC in data for H response"); return; }
            BehaviourPtr -= BEH_NPC_ID; // position at beginning of stride
            // Parse - format of messages is: *NPCB*|<command>|<data>
            list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
            string Command = llList2String(Parts, 1);
            list Params = [];
            if (llGetListLength(Parts) > 2) {
                Params = llList2List(Parts, 2, -1);
            }
            if (Command == "H") { // "Hello" back
                Behaviours = llListReplaceList(Behaviours, [ AttachmentId ], BehaviourPtr + BEH_ATTACHMENT_ID, BehaviourPtr + BEH_ATTACHMENT_ID);
                integer P = llListFindList(HelloWait, [ NpcId ]);
                if (P > -1) {
                    llOwnerSay("ERROR: Can't find NPC for callback: '" + (string)NpcId + "'");
                    return;
                }
                HelloWait = llDeleteSubList(HelloWait, P, P);
                HelloWaitCount--;
                ClearTriggers(BehaviourPtr);
            }
            else if (Command == "SE") { // Sensor results back from NPC attachment
                // Tag is first element; subsequent elements are sensor matches
                string SensorTag = llList2String(Params, 0);
                if (SensorTag == "U") { // Sensor was for users
                    key UserId = (key)llList2String(Params, 1);
                    if (UserId == "") return; // %%% do nothing if nothing detected
                    // Check if user has already been processed by a behaviour script, if "remember" is on
                    integer Remember = llList2Integer(Behaviours, BehaviourPtr + BEH_REMEMBER_AV);
                    if (Remember) {
                        if (llListFindList(RememberedAvatars, [ UserId ]) > -1) return;
                        RememberedAvatars += UserId;
                    }
                    SendToNpc(BehaviourPtr, "SS", []); // stop sensor because we have a match
                    Behaviours = llListReplaceList(Behaviours, [ UserId ], BehaviourPtr + BEH_USER_ID, BehaviourPtr + BEH_USER_ID);
                    ClearTriggers(BehaviourPtr);
                    ProcessEvent(BehaviourPtr, E_SENSOR, "");
                    RestartProcessing();
                }
                else if (SensorTag == "S") { // Sensor was for objects to sit on
                    list Objects = llList2List(Params, 1, -1);
                    SitOnNearestObject(NpcId, BehaviourPtr, Objects);
                }
                else if (SensorTag == "T") { // Sensor was for objects to touch
                    list Objects = llList2List(Params, 1, -1);
                    TouchObject(NpcId, BehaviourPtr, Objects);
                }
                else {
                    llOwnerSay("ERROR: Unknown sensor tag: '" + SensorTag + "'");
                    return;
                }
            }
            else if (Command == "T") {
                key CurrentUserId = llList2Key(Behaviours, BehaviourPtr + BEH_USER_ID);
                key UserId = (key)llList2String(Params, 0);
                if (CurrentUserId != NULL_KEY && UserId != CurrentUserId) return; // ignore if they're already responding to another user
                Behaviours = llListReplaceList(Behaviours, [ UserId ], BehaviourPtr + BEH_USER_ID, BehaviourPtr + BEH_USER_ID);
                ClearTriggers(BehaviourPtr);
                ProcessEvent(BehaviourPtr, E_CLICK, "");
                RestartProcessing();
            }
        }
        else if (llGetSubString(Data, 0, 4) == "*MOL*") { // It's a list from the ML (Composer) objects lister
            string ListStr = llGetSubString(Data, 5, -1);
            list Objects = llParseStringKeepNulls(ListStr, [ "|" ], []);
            integer Len = llGetListLength(Objects);
            integer I;
            for (I = 0; I < Len; I++) {
                key Uuid = (key)llList2String(Objects, I);
                if (llGetOwnerKey(Uuid) == OwnerId) ComposerObjects += Uuid; // only get MLOs from Composer with same owner
            }
        }
    }
    touch_start(integer Count) {
        key UserId = llDetectedKey(0);
        if (UserId != OwnerId) return; // only owner can access admin menu
        ShowAdminMenu();
    }
    changed(integer Change) {
        if (Change & CHANGED_REGION_START) {
            // All our NPCs will have disappeared, so set references to them to null
            integer Behaviour;
            for (Behaviour = 0; Behaviour < BehavioursLength; Behaviour++) {
                integer BehaviourPtr = Behaviour * BEH_STRIDE;
                key UserId = llList2Key(Behaviours, BehaviourPtr + BEH_USER_ID);
                if (UserId != NULL_KEY) {
                    Behaviours = llListReplaceList(Behaviours, [ NULL_KEY ], BehaviourPtr + BEH_USER_ID, BehaviourPtr + BEH_USER_ID);
                }
                ProcessEvent(BehaviourPtr, E_START, "");
            }
            llSetTimerEvent(0.0);
            if (CurrentState == STATE_RUNNING) { // if the NPCs were active when the region stopped ...
                state Restart; // ... restart them
            }
        }
        if (Change & CHANGED_OWNER) {
            OwnerId = llGetOwner();
        }
    }
    timer() {
        llSetTimerEvent(0.0);
        ProcessHellos();
        ProcessTriggers();
        integer UsersCount = CheckUsers();
        ProcessInstructions();
        if (ActiveEvents || Triggers != [] || UsersCount > 0) llSetTimerEvent(TIMER_PERIOD);
    }
}
state Restart {
    on_rez(integer Param) { llResetScript(); }
    state_entry() {
        state Process;
    }
}
// NPC director v1.0.0
