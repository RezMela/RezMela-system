// RezMela icon v0.6

// v0.6 performance of timer code improved
// v0.5 allow stretching/colouring of objects
// v0.4 bug fix
// v0.3 general delete option added, resize has support for >10m movements (version not issued), changes for updater HUD
// v0.2 changes to allow world object to communicate with icon

float Version = 0.6;

float TIMER_LONG_CLICK = 0.5;	// Time of long click
float TIMER_TICK_MIN = 0.5;		// General timer - must be at least as long as TIMER_LONG_CLICK (I think???)
float TIMER_TICK_MAX = 5.0;

string UPDATER_CONFIG_NOTECARD = "RezMela updater config";

integer OBJECT_PIN = 50200;

integer PrimCount;
float CurrentSizeFactor;
key WorldObjectId;

// Configuration data sent by control board
vector HoverTextColour;
float HoverTextAlpha;
float SelectGlow;
vector SelectParticleColour;

string ObjectParams; 	// Object parameters based on config card
integer MonitorChanges = FALSE;	// Are we modifiable? In which case watch our prim parameters
vector SavedPos;
rotation SavedRot;
integer FirstCheckChangePosRot = TRUE;
integer FirstCheckMove = TRUE;

key ControlBoardId = NULL_KEY;	// we need to set the value explicitly because OpenSim

integer TimerSettled = FALSE;	// TRUE if timer has maxed out (faster check than the actual float values)
float TimerTick;

// Selection
key SelectAvId;

// Mousing
key MouseDownAvId;

// Icon commands
integer IC_MOVE = 1000;
integer IC_ROTATE = 1001;
integer IC_MOVE_ROTATE = 1002;
integer IC_RESIZE = 1003;
integer IC_SELECT = 1004;
integer IC_DESELECT = 1005;
integer IC_INITIALISE = 1006;
integer IC_DELETE = 1007;
integer IC_SHORT_CLICK = 1008;
integer IC_LONG_CLICK = 1009;
integer IC_COMMAND = 1020;
integer IC_UPDATE = 1021;
integer IC_CHANGE = 1022;
integer IC_CHANGED_SIZE = 1023;
integer IC_CHANGED_COLOR = 1024;

// World object commands
integer WO_COMMAND = 3007;

// General commands
integer GE_VERSION = 9000;
integer GE_DELETE = 9001;

//string XXX;
//DebugLog(string str) {
//	string S = llGetSubString(llGetTimestamp(), 11, 15);
//	XXX += llStringTrim("\n" + S + " " + str, STRING_TRIM_TAIL);
//	if (llStringLength(XXX) > 256) XXX = llGetSubString(XXX, -100, -1);
//	llSetText(XXX, <1, 0, 0>, 1);
//}
ResetCheckChanges() {
	FirstCheckChangePosRot = FirstCheckMove = TRUE;
	SavedPos = llGetPos();
	SavedRot = llGetRot();
}
CheckPosRot() {
	vector Pos = llGetPos();
	rotation Rot = llGetRot();
	if (Pos != SavedPos || Rot != SavedRot) {
		MessageControl(IC_MOVE_ROTATE, [ Pos, Rot ]);
		SavedPos = Pos;
		SavedRot = Rot;
		TimerTick = TIMER_TICK_MIN;
		TimerSettled = FALSE;
	}
}
// Respond to change in size or colour of monitored objects
ChangeColorSize() {
	list Params = llGetLinkPrimitiveParams(2, [ PRIM_POS_LOCAL, PRIM_ROT_LOCAL, PRIM_SIZE, PRIM_COLOR, 0 ]);
	vector PosLocal = llList2Vector(Params, 0);
	rotation RotLocal = llList2Rot(Params, 1);
	vector Size = llList2Vector(Params, 2);
	vector Color = llList2Vector(Params, 3);
	MessageControl(IC_CHANGE, [ PosLocal, RotLocal, Size, Color ]);
}
// Make physical change to child prim data
Change(list Data) {
	// get parts of list (which has been converted from CSV and is thus made of strings)
	vector Pos = (vector)llList2String(Data, 0);
	rotation Rot = (rotation)llList2String(Data, 1);
	vector Size = (vector)llList2String(Data, 2);
	vector Color = (vector)llList2String(Data, 3);

	vector OldPos = llList2Vector(llGetLinkPrimitiveParams(2, [ PRIM_POS_LOCAL ]), 0);
	integer Steps = (integer)(llVecDist(Pos, OldPos) / 10.0) + 1;	// How many 10m stages are there in the move?

	list PrimParams = [];
	while(Steps--) {
		PrimParams += [ PRIM_POS_LOCAL, Pos ];		// Add in as many moves (each max 10m) as necessary
	}
	PrimParams += [
		PRIM_ROT_LOCAL, Rot,
		PRIM_SIZE, Size,
		PRIM_COLOR, ALL_SIDES, Color, 1.0
			];

	// Apply the changes
	llSetLinkPrimitiveParamsFast(2, PrimParams);
}
// Handle short click
ShortClick(key AvId, list ClickData) {
	MessageControl(IC_SHORT_CLICK, [ AvId ] + ClickData);
}
// Handle long click
LongClick(key AvId) {
	MessageControl(IC_LONG_CLICK, [ AvId ]);
}
// Wrapper for osMessageObject() that checks to see if control board exists
MessageControl(integer Command, list Params) {
	if (ObjectExists(ControlBoardId)) {
		osMessageObject(ControlBoardId, (string)Command + "|" + llDumpList2String(Params, "|"));
	}
	else {
		llOwnerSay("Can't find control board");
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
// Select/deselect icon
Select(key AvId) {
	if (AvId == SelectAvId) return;	// no change
	SelectAvId = AvId;
	float Glow = 0.0;
	string HoverText = "";
	if (SelectAvId != NULL_KEY) {
		Glow = SelectGlow;
		HoverText = llKey2Name(AvId);
		if (HoverText == "") HoverText = "Unknown user";	// maybe they've logged out or TP'd away
	}
	llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_GLOW, ALL_SIDES, Glow ]) ;
	llSetText(HoverText, HoverTextColour, HoverTextAlpha);	// we can't merge this with llSetLinkPrimitiveParamsFast because that applies to all prims
	vector ParticleColor = GetColor(AvId);
	list Particles = [];
	if (AvId != NULL_KEY) {
		Particles = [
			PSYS_PART_FLAGS, PSYS_PART_TARGET_LINEAR_MASK | PSYS_PART_INTERP_COLOR_MASK | PSYS_PART_FOLLOW_VELOCITY_MASK | PSYS_PART_EMISSIVE_MASK,
			PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
			PSYS_SRC_TEXTURE, TEXTURE_BLANK,
			PSYS_SRC_TARGET_KEY, AvId,
			PSYS_SRC_BURST_PART_COUNT, 1,
			PSYS_PART_MAX_AGE, 2.0,
			PSYS_PART_START_ALPHA, 0.6,
			PSYS_PART_END_ALPHA, 0.0,
			PSYS_PART_START_SCALE, <0.06,0.1,0.0>,
			PSYS_PART_END_SCALE, <0.06, 0.1, 0.0>,
			PSYS_PART_START_COLOR, ParticleColor,
			PSYS_PART_END_COLOR, ParticleColor
				] ;
	}
	llParticleSystem(Particles);
}
vector GetColor(key Id) {
	if (SelectParticleColour != ZERO_VECTOR) return SelectParticleColour;
	vector Color;
	Color.x = GenerateColorPart(Id, 0);
	Color.y = GenerateColorPart(Id, 3);
	Color.z = GenerateColorPart(Id, 10);
	return Color;
}
float GenerateColorPart(key Id, integer Offset) {
	integer I = (integer)("0x" + llGetSubString((string)Id, Offset, Offset + 2));
	I = I & 0x7FFFFFFF;
	I = I %  255;
	return (float)I / 256.0;
}
// Resize object
ReSize(float SizeFactor) {
	float ChangeFactor = SizeFactor / CurrentSizeFactor;
	list WriteParams = [];
	integer P;
	for(P = 1; P <= PrimCount; P++) {
		integer LinkNum = P;
		if (PrimCount == 1) LinkNum = 0;	// if not a linkset, it's just 0 (for loop will execute once with P == 1)
		list ReadParams = llGetLinkPrimitiveParams(LinkNum, [ PRIM_SIZE, PRIM_POS_LOCAL ]);
		vector Size = llList2Vector(ReadParams, 0);
		vector LocalPos = llList2Vector(ReadParams, 1);
		Size *= ChangeFactor;
		WriteParams += [ PRIM_LINK_TARGET, LinkNum, PRIM_SIZE, Size ];
		if (P > 1) {	// for non-root prims
			vector NewPos = LocalPos * ChangeFactor;
			integer Jumps = llFloor(llVecDist(NewPos, LocalPos) / 10.0) + 1;	// number of 10m jumps
			while (Jumps--) {
				WriteParams += [ PRIM_POS_LOCAL, NewPos ];
			}
		}
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, WriteParams);
	CurrentSizeFactor = SizeFactor;
}
MoveTo(vector Pos) {
	list Params = [];
	integer Jumps = (integer)(llVecDist(llGetPos(), Pos) / 10.0) + 1;
	while(Jumps--) {
		Params += [ PRIM_POSITION, Pos ];
	}
	llSetLinkPrimitiveParamsFast(1, Params);
	// reset saved position so that we don't tell the control board we've moved (the board should already be aware of move)
	SavedPos = Pos;
}
SetRot(rotation Rot) {
	llSetRot(Rot);
	SavedRot = Rot;
}
// Given object parameter string and expected value, tests if value is in string
integer IsParam(string Params, string Value) {
	return (llSubStringIndex(Params, Value) > -1);
}
default {
	on_rez(integer Start) {
		if (llGetInventoryType(UPDATER_CONFIG_NOTECARD) == INVENTORY_NOTECARD) state Hang;		// suspend if we're in the updater HUD
		ControlBoardId = osGetRezzingObject();
		WorldObjectId = NULL_KEY;	// until we know otherwise
		llSetRemoteScriptAccessPin(OBJECT_PIN);
		if (ControlBoardId == NULL_KEY) return;		// manually rezzed
		// Default values for configuration data
		SelectGlow = 0.3;
		HoverTextColour = <1.0, 0.0, 0.0>;
		HoverTextAlpha = 1.0;
		ResetCheckChanges();
		MessageControl(IC_INITIALISE, [ Start ]);	// tell control panel we're awake, and our unique number
		PrimCount = llGetNumberOfPrims();
		CurrentSizeFactor = 1.0;
		MouseDownAvId = NULL_KEY;
		TimerTick = TIMER_TICK_MAX - llFrand(0.1);	// slightly random initially to prevent everything being in step
		llSetTimerEvent(TimerTick);
		TimerSettled = FALSE;
	}
	state_entry() {
		llSetRemoteScriptAccessPin(OBJECT_PIN);
	}
	touch_start(integer Count) {
		if (MouseDownAvId == NULL_KEY) {
			MouseDownAvId = llDetectedKey(0);
			llSetTimerEvent(TIMER_LONG_CLICK);
			TimerSettled = FALSE;
		}
	}
	touch_end(integer Count) {
		while(Count--) {
			if (llDetectedKey(Count) == MouseDownAvId) {
				llSetTimerEvent(TimerTick);
				TimerSettled = FALSE;
				ShortClick(MouseDownAvId, [ llDetectedTouchPos(Count), llDetectedTouchNormal(Count), llDetectedTouchBinormal(Count), llGetRot() ]);
				MouseDownAvId = NULL_KEY;
			}
		}
	}
	timer() {
		if (MouseDownAvId) {
			LongClick(MouseDownAvId);
			MouseDownAvId = NULL_KEY;
		}
		CheckPosRot();
		if (!TimerSettled) {
			if (TimerTick < TIMER_TICK_MAX) {
				TimerTick += 0.1;
				llSetTimerEvent(TimerTick);
			}
			else {
				TimerSettled = TRUE;
			}
		}
	}
	dataserver(key From, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		integer Command = llList2Integer(Parts, 0);
		list Params = llList2List(Parts, 1, -1);
		if (Command == IC_INITIALISE) {
			// This command sends us data from the controller
			SelectGlow = llList2Float(Params, 0);
			SelectParticleColour = llList2Vector(Params, 1);
			HoverTextColour = llList2Vector(Params, 2);
			HoverTextAlpha = llList2Float(Params, 3);
			ObjectParams = llList2String(Params, 4);
			MonitorChanges = IsParam(ObjectParams, "M");	// Are we a modifiable object?
			if (MonitorChanges && (PrimCount > 2)) {
				llOwnerSay("WARNING: modifiable object has >2 prims");
			}
		}
		else if (Command == IC_MOVE) {
			vector Pos = llList2Vector(Params, 0);
			MoveTo(Pos);
		}
		else if (Command == IC_ROTATE) {
			rotation Rot = llList2Rot(Params, 0);
			SetRot(Rot);
		}
		else if (Command == IC_MOVE_ROTATE) {
			vector Pos = llList2Vector(Params, 0);
			rotation Rot = llList2Rot(Params, 1);
			MoveTo(Pos);
			SetRot(Rot);
		}
		else if (Command == IC_MOVE_ROTATE) {
			Change(Parts);
		}
		else if (Command == IC_RESIZE) {
			float ResizeValue = llList2Float(Params, 0);
			ReSize(ResizeValue);
		}
		else if (Command == IC_CHANGE) {
			Change(Params);
		}
		else if (Command == IC_SELECT) {
			key AvId = llList2Key(Parts, 1);
			Select(AvId);
		}
		else if (Command == IC_DESELECT) {
			Select(NULL_KEY);
		}
		else if (Command == IC_DELETE) {
			llDie();
		}
		else if (Command == IC_COMMAND) {
			// This causes a link message to be sent to any client script
			// Client scripts can't always communicate directly because they
			// may be in child prims with unknown UUIDs, etc.
			string Payload = llList2String(Parts, 1);
			WorldObjectId = From;
			llMessageLinked(LINK_SET, IC_COMMAND, Payload, WorldObjectId);
		}
		else if (Command == GE_VERSION) {
			osMessageObject(From, "I" + (string)Version);
		}
		else if (Command == GE_DELETE) {
			llRemoveInventory(llGetScriptName());
		}
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == WO_COMMAND) {		// message to be sent to world object
			if (WorldObjectId != NULL_KEY) {
				// %%% not sure if this is necessary, because client icon script
				// can know the worldobject ID itself and bypass this script
				osMessageObject(WorldObjectId, String);
			}
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) ResetCheckChanges();
		if (MonitorChanges) {
			if ((Change & CHANGED_COLOR) || (Change & CHANGED_SCALE)) ChangeColorSize();
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
// RezMela icon v0.6