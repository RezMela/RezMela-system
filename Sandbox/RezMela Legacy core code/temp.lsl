// RezMela controller v0.34
//
// v0.34 - retain floating position when floating object moved
// v0.33 - fix rotation issues with normals
// v0.32 - allow stretching of objects, cloning, etc
// v0.31 - various changes arising from beta testing
// v0.30 - bug fix (non-vertical rotations incorrect when loading saves)
// v0.29 - changes for updater HUD
// v0.28 - fix objects in saved scene losing manual rotation
// v0.27 - handle change of region position/rotation of board
// v0.26 - soft labels
// v0.25 - remember last resize value
// v0.24 - resizing (RMSF2 file format)
// v0.23 - manual move feature
// v0.22 - environment settings in save file
// v0.21 - blank preview pane on loading
// v0.20 - add info pages
// v0.19 - add in "dummy move"
// v0.18 - bug fixes from 0.17 (region restarts)
// v0.17 - add "OKCancel" check before clearing scene
// v0.16 - added nudge feature
// v0.15 - added code for updater full version
// v0.14 - bug fixes in checker
// v0.13 - integration of control board objects into single linkset
// v0.12 - add teleporter board
// v0.11 - add registration via object picker
// v0.10 - deselect icon when object picker used to get new object class; fix object rotation
// v0.9 - fixed forgetting picked object on icon selection
// v0.8 - fixed: after deleting an object, placing objects was bugged
// v0.7 - bug fix (moving objects)
// v0.6 - add object extra data
// v0.5 - add updater code
// v0.4 - world object can request icon UUID
// v0.3 - menu on a prim
// v0.2 - minor stability changes
//
float Version = 0.1;

string CONFIG_NOTECARD = "!RezMela controller config";

string SUFFIX_ICON = "I";
string SUFFIX_NOTECARD = "C";

integer OBJECT_PIN = 50200;
integer CHAT_CHANNEL = -94040100;
integer MOVE_INPUT_CHANNEL = -94040101;
integer ADMIN_MENU_CHANNEL = -94040102;
integer TEXT_DISPLAY = -77911300;

vector VERTICAL_NORMAL = <0.0, -1.0, 0.0>;
rotation InitialRot;	// the rotation world objects are given when first created

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
integer IC_UPDATE = 1021;	// this is really in the wrong group!
integer IC_CHANGE = 1022;

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

// Rezzor commands
integer RZ_PING = 2000;
integer RZ_CREATE = 2001;
integer RZ_MOVE  = 2002;
integer RZ_RESET = 2003;

// General commands
integer GE_VERSION = 9000;

// Link message commands
integer LM_FILE_CANCEL = 40500;
integer LM_FILE_SAVE_START = 40501;
integer LM_FILE_SAVE_DATA = 40502;
integer LM_FILE_SAVE_END = 40503;
integer LM_FILE_CLEAR_SCENE = 40504;
integer LM_FILE_LOAD_START = 40505;
integer LM_FILE_LOAD_DATA = 40506;
integer LM_FILE_LOAD_END = 40507;
integer LM_FILE_DELETE = 40508;
integer LM_RESET_EVERTHING = 40509;
integer LM_DELEGATED_CLICK = 40510;
integer LM_OBJECT_PICKER = 40511;
integer LM_INTEGRITY_CHECK = 40512;
integer LM_ENVIRONMENT = 40513;
integer LM_BOOTED = 40514;

// Menu commands and option
integer MENU_INIT = -30151400;
integer MENU_TITLE = -30151401;
integer MENU_DESCRIPTION = -30151402;
integer MENU_ACTIVATE = -30151404;
integer MENU_DIMENSIONS = -30151405;
integer MENU_CLEAR = -30151406;
integer MENU_OPTION = -30151407;
integer MENU_SORT = -30151408;
integer MENU_BUTTON = -30151409;
integer MENU_USER = -30151410;
integer MENU_RESPONSE = -30151411;
integer MENU_RESET = -30151412;
integer MENU_SIDES = -30151413;
integer MENU_CANCEL = -30151414;

integer PrimCount;
integer ButtonClearScene;
integer ButtonRemoveSelected;
integer ButtonCloneSelected;
integer ButtonRotateCN;    // clockwise normal
integer ButtonRotateAN;    // anticlockwise normal
integer ButtonRotateCF;    // clockwise fine
integer ButtonRotateAF;    // anticlockwise fine
integer ButtonFileLoad;
integer ButtonFileSave;
integer ButtonFileDelete;
integer ButtonHideHand;
integer PrimTexturePreview;
integer ButtonAdmin;
integer ButtonMove;
integer PrimRegisteredUser;
integer PrimTeleporter;
integer ButtonResizePlus;
integer ButtonResizeMinus;
integer ButtonResizeReset;
list NudgeButtons;

string RezzorName;
key RezzorId = NULL_KEY;
string HeartbeatMessage;
string BoardPrimName;
integer BoardFace;
integer BoardLinkNum;
vector BoardPrimPos;
rotation BoardPrimRot;
vector BoardPrimSize;
vector BoardPrimHalfSize;
float ScalingFactor;
float RotationStepNormal;
float RotationStepFine;
vector IconHoverTextColour;
float IconHoverTextAlpha;
float IconSelectGlow;
vector IconSelectParticleColour;
vector WorldObjectHoverTextColour;
float WorldObjectHoverTextAlpha;
integer MaxIconQueueSize;
vector RezzorParkPos;

rotation BoardUVRot;
vector RegionSize;
vector WorldSize;
vector WorldOrigin;
vector BoardSize;

list BoardTextures;
integer BoardTexturePtr;

// File handling
integer SceneFilesPrim;
key SceneFilesPrimId;
key FHAvId;
integer FHObjPtr;
integer FHType;
integer FHT_LOAD = 1;
integer FHT_SAVE = 2;
integer FHT_DELETE = 3;

list LoadQueue;            // list of objects to be loaded [ Name, Pos, Rot, Size, Changes, ExtraData ]
key SelectCreatedObject = NULL_KEY;	// Set to avatar's ID when creating an object to cause it to become selected by that avatar when created

// Admin menu
key AMAvId;
string InfoPageUrl;			// URL of info pages
key RegisteredId;

integer NextIconUniq;

string ObjectPickerSelection;    // Name of object selected by object picker

// Selections table - icons selected and by whom
list Selections;
integer SEL_WORLD_ID = 0;
integer SEL_ICON_ID = 1;
integer SEL_AV_ID = 2;
integer SEL_OBJ_PTR = 3;
integer SEL_STRIDE = 4;

string SelectedObjectParams;	// Parameters for currently selected object

list ObjectData;
integer OBJ_POS = 0;
integer OBJ_ROT = 1;	// Pos and Rot must be adjacent
integer OBJ_WORLD_ID = 2;
integer OBJ_ICON_ID = 3;
integer OBJ_NAME = 4;
integer OBJ_SIZE = 5;
integer OBJ_EXTRA_DATA = 6;
integer OBJ_CHANGES = 7;
integer OBJ_STRIDE = 8;
integer ObjectDataSize;

// Teleport return object
string TELEPORT_OBJECT_NAME = "Teleport return";

list TeleportedAvs; // [ AvId, Original Pos, Target Pos, Return object ID ]
integer TA_AV_ID = 0;
integer TA_ORIGIN_POS = 1;
integer TA_TARGET_POS = 2;
integer TA_OBJECT_ID = 3;
integer TA_STRIDE = 4;

// Resize stuff
list Resizables;	// Library objects and their resize increments: [ string ObjectName, float Increment ]
integer RESIZE_PLUS = 1;
integer RESIZE_MINUS = 2;
integer RESIZE_ABSOLUTE = 3;
integer RESIZE_RESET = 4;

// Archiver stuff
key ArchiverId;
integer ArchiveAction;
integer ARCHIVE_BACKUP = 1;
integer ARCHIVE_RESTORE = 2;
integer ARCHIVE_PURGE = 3;
list ArchiveFiles;

integer ARCH_BACKUP_START = 790400;
integer ARCH_BACKUP_FILES = 790401;
integer ARCH_BACKUP_END = 790402;
integer ARCH_RESTORE_START = 790410;
integer ARCH_RESTORE_FILES = 790411;
integer ARCH_RESTORE_END = 790412;
integer ARCH_PURGE = 790420;

integer TimerPurpose;
integer TP_FINISH = 1;
integer TP_REQUEST = 2;
integer TP_PURGED = 3;

float LastResize;	// Last resize value, used to apply to new objects. Reset when picker selection made

list IconUniqs;     // [ integer IconUniq, integer ObjPtr ]
integer IconUniqEntries;    // Number of entries (not items) in IconUniqs

list ObjectParameters;    // [ string Name, string Parameters ]

string EnvironmentDetails;	// String containing all environment data for current scene

integer OKCancelOption;
integer OKC_CLEAR_SCENE = 1;
string OKCancelDesc;
key OKCancelAvId;

integer FirstEverLoad;

// Handle click on control board (including buttons)
Click(key AvId, integer LinkNum, integer TouchFace, vector TouchPos, vector TouchST) {
	// For many functions, it's helpful to know if this user has an object selected
	// So to save duplication, we load selection data if appropriate
	key SelIconId = NULL_KEY;
	key SelWorldId = NULL_KEY;
	integer IsSelected = FALSE;
	integer SelPtr = llListFindList(Selections, [ AvId ]);
	integer ObjPtr = -1;
	IsSelected = (SelPtr > -1);
	if (IsSelected) {        // if they have an icon selected
		SelPtr -= SEL_AV_ID;    // position at start of stride
		SelIconId = llList2Key(Selections, SelPtr + SEL_ICON_ID);
		SelWorldId = llList2Key(Selections, SelPtr + SEL_WORLD_ID);
		ObjPtr = ObjectPtrFromIconId(SelIconId);
	}
	// Handle click on control board surface
	if (LinkNum == BoardLinkNum && TouchFace == BoardFace && RegisteredAv(AvId)) {
		vector WorldPos = BoardPos2WorldPos(TouchPos);
		if (IsSelected) {
			// An icon is selected, so we're moving it
			//
			// In trying to fix rotation issues, the next line (which was introduced in v0.10) has been reverted
			// 			rotation Rot = llList2Rot(ObjectData, ObjPtr + OBJ_ROT);
			// to this:
			rotation Rot = BoardPrimRot;
			MoveObject(ObjPtr, SelWorldId, SelIconId, WorldPos, Rot, VERTICAL_NORMAL);
		}
		else if (ObjectPickerSelection != "") {    // No icon selected, but the picker has an object
			// So we create a new object
			CreateObject(ObjectPickerSelection, WorldPos, InitialRot, 1.0, "", "");
		}
	}
	// Handle button clicks
	// 1. Buttons that don't care about selection
	else if (LinkNum == ButtonClearScene) {
		OKCancelOption = OKC_CLEAR_SCENE;
		OKCancelDesc = "Clear current scene";
		OKCancelAvId = AvId;
		state OKCancel;	// Ignore LSLEditor error message here
	}
	else if (LinkNum == ButtonHideHand) {
		ParkRezzor();
	}
	else if (LinkNum == PrimTexturePreview) {
		InfoPage(AvId);
	}
	else if (LinkNum == ButtonMove) {
		if (IsSelected) {
			llTextBox(AvId, "\nEnter new coordinates for selected object, or leave blank to cancel.\n\nEg:\n200,100\n64,32,22\n120 120", MOVE_INPUT_CHANNEL);
			llListen(MOVE_INPUT_CHANNEL, "", AvId, "");
		}
	}
	// 2. Buttons that only work with selections
	else if (IsSelected) {
		if (LinkNum == ButtonRotateCN) {
			RotateObject(ObjPtr, SelWorldId, SelIconId, -RotationStepNormal);
		}
		else if (LinkNum == ButtonRotateAN) {
			RotateObject(ObjPtr, SelWorldId, SelIconId, RotationStepNormal);
		}
		if (LinkNum == ButtonRotateCF) {
			RotateObject(ObjPtr, SelWorldId, SelIconId, -RotationStepFine);
		}
		else if (LinkNum == ButtonRotateAF) {
			RotateObject(ObjPtr, SelWorldId, SelIconId, RotationStepFine);
		}
		else if (LinkNum == ButtonResizeMinus) {
			Resize(RESIZE_MINUS, ObjPtr, SelWorldId, SelIconId, 0.0, TRUE);
		}
		else if (LinkNum == ButtonResizePlus) {
			Resize(RESIZE_PLUS, ObjPtr, SelWorldId, SelIconId, 0.0, TRUE);
		}
		else if (LinkNum == ButtonResizeReset) {
			Resize(RESIZE_RESET, ObjPtr, SelWorldId, SelIconId, 0.0, TRUE);
		}
		else if (LinkNum == ButtonRemoveSelected) {
			DeleteObject(ObjPtr, SelWorldId, SelIconId);
			// Remove selection
			DeSelectByPtr(SelPtr);
		}
		else if (LinkNum == ButtonCloneSelected) {
			CloneObject(ObjPtr, SelWorldId, SelIconId, AvId);
		}
		else if (llListFindList(NudgeButtons, [ LinkNum ]) > -1) {
			Nudge(AvId, LinkNum);
		}
		else {
			DelegateClick(AvId, LinkNum, TouchFace, TouchST);
		}
	}
	// 3. Buttons that only work when nothing is selected
	else {
		DelegateClick(AvId, LinkNum, TouchFace, TouchST);
	}
}
// Handle clicks that we don't know about - send them out as LMs for other scripts to have a go at
DelegateClick(key AvId, integer LinkNum, integer TouchFace, vector TouchST) {
	string PrimName = llGetLinkName(LinkNum);
	llMessageLinked(LINK_SET, LM_DELEGATED_CLICK, llDumpList2String([ PrimName, LinkNum, TouchFace, TouchST ], "|"), AvId);
}
//string XXX;
//DebugLog(string str) {
//	string S = llGetSubString(llGetTimestamp(), 11, 15);
//	XXX += llStringTrim("\n" + S + " " + str, STRING_TRIM_TAIL);
//	if (llStringLength(XXX) > 512) XXX = llGetSubString(XXX, -400, -1);
//	llSetText(XXX, <1, 0, 0>, 1);
//}
Change(key IconId, list Data, integer UpdateIcon, integer Remember) {
	// get parts of list (which has been converted from CSV and is thus made of strings)
	vector LocalPos = (vector)llList2String(Data, 0);
	rotation LocalRot = (rotation)llList2String(Data, 1);
	vector Size = (vector)llList2String(Data, 2);
	vector Color = (vector)llList2String(Data, 3);
	if (UpdateIcon) {	// if we need to tell the icon to change
		MessageStandard(IconId, IC_CHANGE, Data);
	}
	// convert from icon size to world object size
	LocalPos *= ScalingFactor;
	Size *= ScalingFactor;

	// send data to world object
	key WorldId = IconId2WorldId(IconId);
	MessageStandard(WorldId, WO_CHANGE, [ LocalPos, LocalRot, Size, Color ]);

	// Update objects table
	string ChangeDataString = llDumpList2String(Data, "^");
	integer OPtr = llListFindList(ObjectData, [ IconId ]) - OBJ_ICON_ID;	// Find pointer to start of objects table row
	ObjectData = llListReplaceList(ObjectData, [ ChangeDataString ], OPtr + OBJ_CHANGES, OPtr + OBJ_CHANGES);
}
MoveRotate(key IconId, list Data) {
	integer ObjPtr = ObjectPtrFromIconId(IconId);
	vector IconPos = (vector)llList2String(Data, 0);
	rotation IconRot = (rotation)llList2String(Data, 1);
	key WorldId = IconId2WorldId(IconId);
	vector WorldPos = BoardPos2WorldPos(IconPos);
	rotation WorldRot = IconRot2WorldRot(IconRot);
	MoveWorldObjectOnly(ObjPtr, WorldId, WorldPos, WorldRot);
}
key IconId2WorldId(key IconId) {
	integer P = llListFindList(ObjectData, [ IconId ]);
	P = P - OBJ_ICON_ID + OBJ_WORLD_ID;
	key WorldId = llList2Key(ObjectData, P);
	return WorldId;
}
// If object is below water level but is a floating object, lift it to water level
vector AdjustFloatingObjects(string Params, vector WorldPos) {
	if (IsParam(Params, "F")) {		// floating
		float WaterLevel = llWater(WorldPos- llGetPos());	// find water level at WorldPos
		if (WaterLevel > WorldPos.z) 	// if the water level is higher than the given position
			WorldPos.z = WaterLevel;	// set height of object to water level
	}
	return WorldPos;
}
// Handle avatar clicking on teleporter board
TeleporterClick(key AvId, vector TouchST) {
	vector OriginalPos = llList2Vector(llGetObjectDetails(AvId, [ OBJECT_POS ]), 0);
	vector TouchPos;
	TouchPos.x =  1.0 - TouchST.x;
	TouchPos.y =  1.0 - TouchST.y;
	vector TargetPos;
	TargetPos.x = WorldOrigin.x + (WorldSize.x * TouchPos.x);
	TargetPos.y = WorldOrigin.y + (WorldSize.y * TouchPos.y);
	TargetPos.z = llGround(ZERO_VECTOR - llGetPos() + TargetPos) + 2.0;		// add 2m to make sure they're not rezzed inside something
	vector LookAt = WorldOrigin + (WorldSize / 2.0);	// look at centre of world (although LookAt doesn't seem to work in OpenSim, avatar always faces north)
	osTeleportAgent(AvId, TargetPos, LookAt);
	integer P = llListFindList(TeleportedAvs, [ AvId ]);
	if (P > -1) {
		key ObjectId = llList2Key(TeleportedAvs, P + TA_OBJECT_ID);
		if (ObjectId != NULL_KEY) {
			// there's likely to be a return object already out there that we need to delete
			if (ObjectExists(ObjectId)) {	// if it does exist
				osMessageObject(ObjectId, "die");	// tell it to die
			}
		}
		TeleportedAvs = llDeleteSubList(TeleportedAvs, P, P + TA_STRIDE - 1);
	}
	TeleportedAvs += [ AvId, OriginalPos, TargetPos, NULL_KEY ];
	llRezObject(TELEPORT_OBJECT_NAME, llGetPos() + <0.0, 0.0, 0.9>, ZERO_VECTOR, ZERO_ROTATION, 1);
}
// Handle rezzing of unallocated teleporter return object
TeleportObject(key ObjectId, string Data) {
	if (Data == "init") {	// object has just rezzed and is phoning home - we send it the necessary data to do its job
		integer P = llListFindList(TeleportedAvs, [ NULL_KEY ]);	// find entry without object defined
		TeleportedAvs = llListReplaceList(TeleportedAvs, [ ObjectId ], P, P);
		P -= TA_OBJECT_ID;	// position at start of row
		key AvId = llList2Key(TeleportedAvs, P + TA_AV_ID);
		vector TargetPos = llList2Vector(TeleportedAvs, P + TA_TARGET_POS);
		vector OriginalPos = llList2Vector(TeleportedAvs, P + TA_ORIGIN_POS);
		// We could get the avatar's actual position and use that for targetpos - consider that as a possibilty
		TargetPos.z += 1.0;	// position over avatar's head (remember that targetpos is higher than it should be anyway)
		osMessageObject(ObjectId, llDumpList2String([ "start", AvId, TargetPos, OriginalPos ], "|"));
	}
}
// Create new icon (and, indirectly, world object)
CreateObject(string ObjectName, vector WorldPos, rotation WorldRot, float Size, string Changes, string ExtraData) {
	string IconName = ObjectName + SUFFIX_ICON;
	if (llGetInventoryType(IconName) != INVENTORY_OBJECT) {
		BroadcastMessage("Icon not found: " + IconName);
		return;
	}
	// First, we check that the icon queue is not full. In practice, this doesn't
	// really seem to be an issue, but I've left the code here in case.
	if (IconUniqEntries > MaxIconQueueSize) return;    // If it is, ignore the create

	if (OutsideBounds(WorldPos)) {
		BroadcastMessage("Can't position '" + ObjectName + "' - outside boundary");
		WorldPos = WorldOrigin + (WorldSize / 2.0);    // position in centre
	}
	string Params = GetParams(ObjectName);

	if (IsParam(Params, "C")) {
		WorldPos = WorldOrigin + WorldSize * 0.5;		// centre region
	}
	WorldPos = AdjustFloatingObjects(Params, WorldPos);
	vector IconPos = WorldPos2BoardPos(WorldPos);
	rotation IconRot = WorldRot2IconRot(WorldRot);

	integer Uniq = ++NextIconUniq;
	llRezObject(IconName, IconPos, ZERO_VECTOR, IconRot, Uniq );
	ObjectData += [ WorldPos, WorldRot, NULL_KEY, NULL_KEY, ObjectName, Size, ExtraData, Changes ];
	IconUniqs += [ Uniq, ObjectDataSize ];        // Icon's unique number, and pointer to objects table entry
	IconUniqEntries++;
	ObjectDataSize += OBJ_STRIDE;
}
// Move object to specified position
MoveObject(integer ObjPtr, key WorldId, key IconId, vector WorldPos, rotation PrimRot, vector Normal) {
	string ObjectName = llList2String(ObjectData, ObjPtr + OBJ_NAME);
	string Params = GetParams(ObjectName);
	//	if (IsParam(Params, "F")) {		// floating
	//		float WaterLevel = llWater(WorldPos- llGetPos());	// find water level at WorldPos
	//		if (WaterLevel > WorldPos.z) 	// if the water level is higher than the given position
	//			WorldPos.z = WaterLevel;	// set height of object to water level
	//	}
	WorldPos = AdjustFloatingObjects(Params, WorldPos);
	if (IsParam(Params, "V")) Normal = VERTICAL_NORMAL;
	if (IsParam(Params, "C")) WorldPos = WorldOrigin + WorldSize * 0.5;
	rotation IconRot = PrimRot * RotBetween(llRot2Up(PrimRot), Normal);
	rotation WorldRot = IconRot2WorldRot(IconRot);
	MoveIconOnly(IconId, WorldPos, WorldRot);
	MoveWorldObjectOnly(ObjPtr, WorldId, WorldPos, WorldRot);
}
MoveIconOnly(key IconId, vector WorldPos, rotation WorldRot) {
	rotation IconRot = WorldRot2IconRot(WorldRot);
	vector IconPos = WorldPos2BoardPos(WorldPos);
	MessageStandard(IconId, IC_MOVE_ROTATE, [ IconPos, IconRot ]);
}
MoveWorldObjectOnly(integer ObjPtr, key WorldId, vector WorldPos, rotation WorldRot) {
	ObjectData = llListReplaceList(ObjectData, [ WorldPos, WorldRot ], ObjPtr + OBJ_POS, ObjPtr + OBJ_ROT);
	MessageStandard(WorldId, WO_MOVE_ROTATE, [ WorldPos, WorldRot ]);
}
rotation NormalisedRot(string ObjectName, rotation TargetObjectRot, vector Normal) {
	string Params = GetParams(ObjectName);
	if (IsParam(Params, "V")) Normal = VERTICAL_NORMAL;
	//return RotBetween(llRot2Up(TargetObjectRot), Normal) / llGetRot();
	return TargetObjectRot * RotBetween(llRot2Up(TargetObjectRot), Normal);
}
rotation IconRot2WorldRot(rotation IconRot) {
	return IconRot / llGetRot();
}
rotation WorldRot2IconRot(rotation WorldRot) {
	return WorldRot * llGetRot();
}
// Delete icon and world object
DeleteObject(integer ObjPtr, key WorldId, key IconId) {
	MessageStandard(IconId, IC_DELETE, []);
	MessageStandard(WorldId, WO_DELETE, []);
	ObjectData = llDeleteSubList(ObjectData, ObjPtr, ObjPtr + OBJ_STRIDE -1);
	ObjectDataSize -= OBJ_STRIDE;
}
CloneObject(integer ObjPtr, key WorldId, key IconId, key AvId) {
	// As well as doing the creation of a new object ...
	// We need to enquire of the source icon its change data (a new IC_* command), and then in the
	// dataserver react to the reply by applying that change to the cloned object
	// As usual, it's going to be a bit messy. Good luck!
	string ObjectName = llList2String(ObjectData, ObjPtr + OBJ_NAME);
	vector WorldPos = llList2Vector(ObjectData, ObjPtr + OBJ_POS);
	rotation WorldRot = llList2Rot(ObjectData, ObjPtr + OBJ_ROT);
	float Size = llList2Float(ObjectData, ObjPtr + OBJ_SIZE);
	string Changes = llList2String(ObjectData, ObjPtr + OBJ_CHANGES);
	string ExtraData = llList2String(ObjectData, ObjPtr + OBJ_EXTRA_DATA);
	// Calculate position of clone
	if (WorldPos.y + 10.0 < WorldSize.y) 	// if there's room to the north
		WorldPos += <0.0, 10.0, 0.0>;		// have clone 10m north of original
	else
		WorldPos += <0.0, 0.0, 10.0>;		// otherwise, make it 10m above original
	CreateObject(ObjectName, WorldPos, WorldRot, Size, Changes, ExtraData);
	SelectCreatedObject = AvId;
}
// Returns TRUE if position is outside world boundary
integer OutsideBounds(vector WorldPos) {
	return (
		WorldPos.x > RegionSize.x || WorldPos.y > RegionSize.y ||
		WorldPos.x < 0.0 || WorldPos.y < 0.0 ||
		WorldPos.x < WorldOrigin.x || WorldPos.y < WorldOrigin.y
			);
}
// Convert region position of control board click to X,Y coordinates
vector BoardPos2WorldPos(vector BoardPos) {
	vector SurfacePos = (BoardPos - BoardPrimPos) / BoardPrimRot + BoardPrimHalfSize;
	vector Coord;
	Coord.x = SurfacePos.y;
	Coord.y = BoardPrimSize.x - SurfacePos.x;
	Coord.z = SurfacePos.z;
	Coord *= ScalingFactor;
	Coord += WorldOrigin;
	return Coord;
}
vector WorldPos2BoardPos(vector WorldPos) {
	vector Coord = WorldPos - WorldOrigin;
	Coord /= ScalingFactor;
	vector SurfacePos;
	SurfacePos.x = BoardPrimSize.x - Coord.y;
	SurfacePos.y = Coord.x;
	SurfacePos.z = Coord.z;
	//
	// These comments where here before the line adding to SurfacePos was commented out:
	//
	//	// The next line is because X/Y are calculated in one direction, Z in the other. I think.
	//	// I don't fully understand this at the moment, but this line fixes anomalous
	//	// behaviour affecting the precise height position of the icon. It seems that half the
	//	// board thickness ends up being subtracted rather than added (vice versa in the
	//	// final orientation), so we add the full thickness to compensate. -- John
	//
	// But this line was actually adding in an error when I was moving icons around - the
	// conversion from icon to world object position and back again resulted in a slightly higher
	// Z value (ie object height). Commenting this line out removed the problem, leading me to
	// wonder under what circumstances the error descripted in those comments actually occurred.
	//
	// SurfacePos += <0.0, 0.0, BoardPrimSize.z>;	// add in thickness of board prim
	vector BoardPos = BoardPrimPos + ((SurfacePos - BoardPrimHalfSize) * BoardPrimRot);
	return BoardPos;
}
// Return pointer to objects table, given icon ID
integer ObjectPtrFromIconId(key IconId) {
	integer Ptr = llListFindList(ObjectData, [ IconId ]);
	if (Ptr == -1) return -1;
	return (Ptr - OBJ_ICON_ID);
}
// Rotate object by specified amount (in addition to any current rotation)
RotateObject(integer ObjPtr, key WorldId, key IconId, float Degrees) {
	rotation Rot = llList2Rot(ObjectData, ObjPtr + OBJ_ROT);
	rotation AddRot = llEuler2Rot(<0.0, 0.0, Degrees> * DEG_TO_RAD);
	rotation NewWorldRot = AddRot * Rot;
	//rotation NewIconRot = NewWorldRot * RotBetween(llRot2Up(NewWorldRot), VERTICAL_NORMAL);
	rotation NewIconRot = WorldRot2IconRot(NewWorldRot);
	MessageStandard(IconId, IC_ROTATE, [ NewIconRot ]);
	MessageStandard(WorldId, WO_ROTATE, [ NewWorldRot ]);
	ObjectData = llListReplaceList(ObjectData, [ NewWorldRot ], ObjPtr + OBJ_ROT, ObjPtr + OBJ_ROT);
}
// Return TRUE if avatar is registered
integer RegisteredAv(key AvId) {
	return (AvId == RegisteredId);
}
// Delete all objects and icons
ClearScene() {
	SortObjects();
	integer Ptr;
	for(Ptr = 0; Ptr < ObjectDataSize; Ptr += OBJ_STRIDE) {
		key IconId = llList2Key(ObjectData, Ptr + OBJ_ICON_ID);
		key WorldId = llList2Key(ObjectData, Ptr + OBJ_WORLD_ID);
		MessageStandard(IconId, IC_DELETE, []);
		MessageStandard(WorldId, WO_DELETE, []);
	}
	ClearObjectsTable();
	IconUniqs = [];
	IconUniqEntries = 0;
	DeSelectAll();
	llMessageLinked(LINK_SET, LM_ENVIRONMENT, "reset", NULL_KEY);	// Tell environment to reset water, etc
}
ClearObjectsTable() {
	ObjectData = [];
	ObjectDataSize = 0;
}
Reset() {
	ClearScene();
	MessageRezzor(RZ_RESET, []);
}
// Nudge the object
Nudge(key AvId, integer ButtonLinkNum) {
	// Find the entry for this user in the selections table
	integer SelPtr = llListFindList(Selections, [ AvId ]);
	if (SelPtr > -1) {	// if this user has a selection
		SelPtr -= SEL_AV_ID;	// reposition at start of stride
		string ButtonDesc = llList2String(llGetObjectDetails(llGetLinkKey(ButtonLinkNum), [ OBJECT_DESC ]), 0);
		list L = llCSV2List(ButtonDesc);
		float X = (float)llList2String(L, 0);
		float Y = (float)llList2String(L, 1);
		vector MyPos = llGetPos();
		rotation MyRot = llGetRot();
		key IconId = llList2Key(Selections, SelPtr + SEL_ICON_ID);
		key WorldId = llList2Key(Selections, SelPtr + SEL_WORLD_ID);
		integer ObjPtr = llList2Integer(Selections, SelPtr + SEL_OBJ_PTR);
		vector WorldPos = llList2Vector(ObjectData, ObjPtr + OBJ_POS);
		float NudgeDistance = 1.0;	// Move in increments of 1m
		WorldPos += <X, Y, 0.0> * NudgeDistance;	// calculate new position
		vector IconPos = WorldPos2BoardPos(WorldPos);
		MessageStandard(IconId, IC_MOVE, [ IconPos ]);
		MessageStandard(WorldId, WO_MOVE, [ WorldPos ]);
		ObjectData = llListReplaceList(ObjectData, [ WorldPos ], ObjPtr + OBJ_POS, ObjPtr + OBJ_POS);
	}
}
// Sorts the objects table so that things happen in a systematic manner (ie N to S, then W to E)
SortObjects() {
	list Sorter = [];
	integer Ptr;
	for (Ptr = 0; Ptr < ObjectDataSize; Ptr += OBJ_STRIDE) {
		vector Pos = llList2Vector(ObjectData, Ptr + OBJ_POS);
		string SortKey = SortNumber(Pos.y) + SortNumber(Pos.x);
		Sorter += [ SortKey, Ptr ];
	}
	list NewObjectData = [];
	Sorter = llListSort(Sorter, 2, TRUE);
	integer Len = llGetListLength(Sorter);
	for (Ptr = 0; Ptr < Len; Ptr += 2) {
		integer ObjPtr = llList2Integer(Sorter, Ptr + 1);
		list Row = llList2List(ObjectData, ObjPtr, ObjPtr + OBJ_STRIDE - 1);
		NewObjectData += Row;
	}
	ObjectData = NewObjectData;
}
// Returns integer portion, padded with leading 0s to 4 chars
string SortNumber(float Number) {
	string Str = (string)llFloor(Number / 10.0);
	while(llStringLength(Str) < 4) { Str = "0" + Str; }
	return Str;
}
// Handles resizing of objects
// Bear in mind that "size" is not the actual size, it's the proportion of the original size. So a 10m object
// will be 15m if Size == 1.5.
Resize(integer Type, integer ObjPtr, key WorldId, key IconId, float AbsoluteSize, integer Remember) {
	string ObjectName = llList2String(ObjectData, ObjPtr + OBJ_NAME);
	integer Rp = llListFindList(Resizables, [ ObjectName ]);
	if (Rp == -1) return;	// if it's not a resizable object, ignore
	float Size = llList2Float(ObjectData, ObjPtr + OBJ_SIZE);
	if (Size == 0.0) {
		BroadcastMessage("Size reset to 1");
		Size = 1.0;
	}
	float ResizeIncrement = llList2Float(Resizables, Rp + 1);
	if (Type == RESIZE_PLUS) {
		Size = Size * (1.0 + ResizeIncrement);
	}
	else if (Type == RESIZE_MINUS) {
		Size = Size * (1.0 - ResizeIncrement);
	}
	else if (Type == RESIZE_RESET) {
		Size = 1.0;
	}
	else if (Type == RESIZE_ABSOLUTE) {
		Size = AbsoluteSize;
	}
	ObjectData = llListReplaceList(ObjectData, [ Size ], ObjPtr + OBJ_SIZE, ObjPtr + OBJ_SIZE);	// write new size back into table
	MessageStandard(WorldId, WO_RESIZE, [ Size ]);
	MessageStandard(IconId, IC_RESIZE, [ Size ]);
	if (Remember) LastResize = Size;
}
// Display or hide resize icons
SetResizeIcons(integer Show) {
	integer FACE = 0;
	vector COLOR = <1.0, 1.0, 1.0>;
	float Alpha = 0.0;
	if (Show) Alpha = 1.0;
	list Params = [];
	if (ButtonResizeMinus > 1) Params += [ PRIM_LINK_TARGET, ButtonResizeMinus, PRIM_COLOR, FACE, COLOR, Alpha ];
	if (ButtonResizePlus > 1) Params += [ PRIM_LINK_TARGET, ButtonResizePlus, PRIM_COLOR, FACE, COLOR, Alpha ];
	if (ButtonResizeReset > 1) Params += [ PRIM_LINK_TARGET, ButtonResizeReset, PRIM_COLOR, FACE, COLOR, Alpha ];
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
}
// --------- Functions for object selection
SelectByIconId(key IconId, key AvId) {
	DeselectByAvId(AvId);	// deselect anything already selected by this avatar
	// First, find the ObjectData entry
	integer ObjPtr = llListFindList(ObjectData, [ IconId ]);
	if (ObjPtr == -1) { BroadcastMessage("Can't find object to select"); return; }
	ObjPtr -= OBJ_ICON_ID;         // position at beginning of stride
	key WorldId = llList2Key(ObjectData, ObjPtr + OBJ_WORLD_ID);    // extract world ID from objects table
	Selections += [ WorldId, IconId, AvId, ObjPtr ];    // add entry to selections table
	MessageStandard(IconId, IC_SELECT, [ AvId ]);    // tell the icon it's been selected
	MessageStandard(WorldId, WO_SELECT, [ AvId ]);    // likewise for the world object
	vector Pos = llList2Vector(ObjectData, ObjPtr + OBJ_POS);    // find the world object's position
	string ObjectName = llList2String(ObjectData, ObjPtr + OBJ_NAME);
	MessageRezzor(RZ_MOVE, [ Pos ]);        // move rezzor to world object
	SelectedObjectParams = GetParams(ObjectName);
	if (llListFindList(Resizables, [ llList2String(ObjectData, ObjPtr + OBJ_NAME) ]) > -1) SetResizeIcons(TRUE);	// display resize icons if appropriate
}
key FindSelectedIconByAvId(key AvId) {
	integer SelPtr = llListFindList(Selections, [ AvId ]);
	SelPtr -= SEL_AV_ID;    // position at beginning of stride
	key SelIconId = llList2Key(Selections, SelPtr + SEL_ICON_ID);
	return SelIconId;
}
DeselectByAvId(key AvId) {
	integer SelPtr = llListFindList(Selections, [ AvId ]);
	if (SelPtr == -1) return;    // wasn't anything selected
	SelPtr -= SEL_AV_ID;    // position at beginning of stride
	DeSelectByPtr(SelPtr);
}
DeSelectByPtr(integer SelPtr) {
	key SelIconId = llList2Key(Selections, SelPtr + SEL_ICON_ID);
	key SelWorldId = llList2Key(Selections, SelPtr + SEL_WORLD_ID);
	MessageStandard(SelIconId, IC_DESELECT, []);
	MessageStandard(SelWorldId, WO_DESELECT, []);
	Selections = llDeleteSubList(Selections, SelPtr, SelPtr + SEL_STRIDE - 1);
	SetResizeIcons(FALSE);
}
DeSelectAll() {
	integer SelLen = llGetListLength(Selections);
	integer SelPtr;
	for(SelPtr = 0; SelPtr < SelLen; SelPtr += SEL_STRIDE) {
		DeSelectByPtr(SelPtr);
	}
	Selections = [];
	ParkRezzor();
	SetResizeIcons(FALSE);
}
ParkRezzor() {
	if (RezzorId == NULL_KEY) return;
	MessageRezzor(RZ_MOVE, [ RezzorParkPos ]);
}
// Check permissions of inventory object, notecard, etc
integer IsFullPerm(string Name) {
	return (PermsCheck(Name, MASK_BASE) && PermsCheck(Name, MASK_OWNER) && PermsCheck(Name, MASK_NEXT));
}
integer PermsCheck(string Name, integer Mask) {
	integer Perms = llGetInventoryPermMask(Name, Mask);
	return (Perms & PERM_COPY && Perms & PERM_MODIFY && Perms & PERM_TRANSFER);
}
// ----------- Configuration functions
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		BroadcastMessage("Can't find notecard '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	// Set config defaults
	RezzorName = "sceneRezzor";
	BoardPrimName = "Board";
	BoardFace = 0;
	BoardUVRot = ZERO_ROTATION;
	WorldSize = <256.0, 256.0, 0.0>;
	WorldOrigin = ZERO_VECTOR;
	BoardSize = <12.0, 12.0, 0.0>;
	IconSelectGlow = 0.3;
	IconSelectParticleColour = ZERO_VECTOR;        // NULL means avatar-specific colour
	IconHoverTextColour = <1.0, 1.0, 1.0>;
	IconHoverTextAlpha = 1.0;
	WorldObjectHoverTextColour = <1.0, 1.0, 1.0>;
	WorldObjectHoverTextAlpha = 1.0;
	RotationStepNormal = 45.0;
	RotationStepFine = 5.0;
	ScalingFactor = 40.0;
	MaxIconQueueSize = 20;
	InfoPageUrl = "";
	RezzorParkPos = <99999.0, 0.0, 0.0>;    // High value indicates default - see below
	float WaterMin = 10.0;
	float WaterMax = 40.0;
	float WaterDefault = 20.0;
	integer Lines = osGetNumberOfNotecardLines(CONFIG_NOTECARD);
	integer I;
	for(I = 0; I < Lines; I++) {
		string Line = osGetNotecardLine(CONFIG_NOTECARD, I);
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
					if (Name == "rezzorname") RezzorName = StripQuotes(Value, Line);
					else if (Name == "boardprimname") BoardPrimName = StripQuotes(Value, Line);
					else if (Name == "boardface") BoardFace = (integer)Value;
					else if (Name == "boarduvrot") BoardUVRot = String2Rot(Value);
					else if (Name == "boardsize") BoardSize = (vector)Value;
					else if (Name == "worldsize") WorldSize = (vector)Value;
					else if (Name == "worldorigin") WorldOrigin = (vector)Value;
					else if (Name == "scalingfactor") ScalingFactor = (float)Value;
					else if (Name == "iconselectglow") IconSelectGlow = (float)Value;
					else if (Name == "iconselectparticlecolor") IconSelectParticleColour = (vector)Value / 256.0;
					else if (Name == "iconhovertextcolor") IconHoverTextColour = (vector)Value;
					else if (Name == "iconhovertextalpha") IconHoverTextAlpha = (float)Value;
					else if (Name == "worldobjecthovertextcolor") WorldObjectHoverTextColour = (vector)Value;
					else if (Name == "worldobjecthovertextalpha") WorldObjectHoverTextAlpha = (float)Value;
					else if (Name == "rotationstepnormal") RotationStepNormal = (float)Value;
					else if (Name == "rotationstepfine") RotationStepFine = (float)Value;
					else if (Name == "maxiconqueuesize") MaxIconQueueSize = (integer)Value;
					else if (Name == "rezzorparkpos") RezzorParkPos = (vector)Value;
					else if (Name == "infopageurl") InfoPageUrl = StripQuotes(Value, Line);
					else if (Name == "watermin") WaterMin = (float)Value;
					else if (Name == "watermax") WaterMax = (float)Value;
					else if (Name == "waterdefault") WaterDefault = (float)Value;
					else llOwnerSay("Invalid keyword in config card: " + OName);
				}
				else {
					llOwnerSay("Invalid line in config card: " + Line);
				}
			}
		}
	}
	if (RezzorParkPos.x > 90000.0) RezzorParkPos = WorldOrigin;
	if (WorldSize.x > RegionSize.x || WorldSize.y > RegionSize.y) {
		//llOwnerSay("Warning: WorldSize in config exceeds actual region size - adjusting values");
		if (WorldSize.x > RegionSize.x) WorldSize.x = RegionSize.x;
		if (WorldSize.y > RegionSize.y) WorldSize.y = RegionSize.y;
	}
	llMessageLinked(LINK_SET, LM_ENVIRONMENT, llDumpList2String([ "config", WaterMin, WaterMax, WaterDefault ], "|"), NULL_KEY);
	return TRUE;
}
//
// Object parameter file routines
//
ReadParameterFiles() {
	ObjectParameters = [];
	Resizables = [];
	integer IconCount = llGetInventoryNumber(INVENTORY_OBJECT);
	integer I;
	for(I = 0; I < IconCount; I++) {
		string IconName = llGetInventoryName(INVENTORY_OBJECT, I);
		string BaseName = llGetSubString(IconName, 0, -2);
		string ParamFileName = BaseName + SUFFIX_NOTECARD;
		if (llGetInventoryType(ParamFileName) == INVENTORY_NOTECARD) {    // if the notecard exists
			ObjectParameters += [ BaseName, ParseParameterFile(BaseName, ParamFileName) ];
		}
	}
}
string ParseParameterFile(string BaseName, string ParamFileName) {
	string Params = "";
	integer Len = osGetNumberOfNotecardLines(ParamFileName);
	integer I;
	for(I = 0; I < Len; I++) {
		string Line = osGetNotecardLine(ParamFileName, I);
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
					if (Name == "center" || Name == "centre") {
						if (String2Bool(Value)) Params += "C";
					}
					else if (Name == "vertical") {
						if (String2Bool(Value)) Params += "V";
					}
					else if (Name == "adjustheight") {
						if (String2Bool(Value)) Params += "H";
					}
					else if (Name == "dummymove") {
						if (String2Bool(Value)) Params += "D";
					}
					else if (Name == "resize") {
						float Increment = (float)Value;
						Resizables += [ BaseName, Increment ];
					}
					else if (Name == "phantom") {
						if (String2Bool(Value)) Params += "P";
					}
					else if (Name == "floating") {
						if (String2Bool(Value)) Params += "F";
					}
					else if (Name == "modify") {
						if (String2Bool(Value)) Params += "M";
					}
					else BroadcastMessage("Invalid keyword in parameter file '" + ParamFileName + "': " + OName);
				}
				else {
					BroadcastMessage("Invalid line in parameter file '" + ParamFileName + "': " + Line);
				}
			}
		}
	}
	return Params;
}
// Given an object name, returns string of associated parameters
string GetParams(string ObjectName) {
	string Ret = "";
	integer P = llListFindList(ObjectParameters, [ ObjectName ]);
	if (P > -1) {
		Ret = llList2String(ObjectParameters, P + 1);
	}
	return Ret;
}
// Given object parameter string and expected value, tests if value is in string
integer IsParam(string Params, string Value) {
	return (llSubStringIndex(Params, Value) > -1);
}
//
// INI file format routines
//
//     Takes a string in double quotes, and strips out the quotes. Validates the format.
// <Text> is the string with quotes; <Line> is the entire line for error reporting
string StripQuotes(string Text, string Line) {
	if (Text == "") {    // allow empty string
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
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
// Convert Euler degrees (as string) to quaternion rotation
// Also handles string quaternion input
rotation String2Rot(string Value) {
	integer Parts = llGetListLength(llCSV2List(llGetSubString(Value, 1, -2)));    // count the number of parts
	if (Parts == 3) // vector
		return(llEuler2Rot((vector)Value * DEG_TO_RAD));
	else            // assume quaternion
		return((rotation)Value);
}
// Send message to rezzor to create object
RezzorCreate(string Name, vector Pos, rotation Rot, key IconId) {
	MessageRezzor(RZ_CREATE, [ Name, Pos, Rot, IconId ]);
}
// Send message to rezzor
MessageRezzor(integer Command, list  Params) {
	if (RezzorId == NULL_KEY) {
		BroadcastMessage("Rezzor object unknown");
		return;
	}
	if (ObjectExists(RezzorId)) {
		osMessageObject(RezzorId, (string)Command + "|" + llDumpList2String(Params, "|"));
	}
	else {
		BroadcastMessage("Rezzor object disappeared!?");
		RezzorId = NULL_KEY;
	}
}
// Wrapper for osMessageObject() that checks to see if control board exists
// Uses standard messaging protocol
MessageStandard(key Uuid, integer Command, list Params) {
	MessageObject(Uuid, llDumpList2String([ Command ] + Params, "|"));
}
// Wrapper for osMessageObject() that checks to see if control board exists
MessageObject(key Uuid, string Text) {
	if (ObjectExists(Uuid)) {
		osMessageObject(Uuid, Text);
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
// Find link numbers of key prims
integer GetLinkNumbers() {
	BoardLinkNum = -1;
	ButtonClearScene = -1;
	ButtonRemoveSelected = -1;
	ButtonCloneSelected = -1;
	ButtonRotateCN = -1;
	ButtonRotateAN = -1;
	ButtonRotateCF = -1;
	ButtonRotateAF = -1;
	ButtonFileLoad = -1;
	ButtonFileSave = -1;
	ButtonFileDelete = -1;
	ButtonHideHand = -1;
	PrimTexturePreview = -1;
	ButtonAdmin = -1;
	ButtonMove = -1;
	ButtonResizePlus = ButtonResizeMinus = ButtonResizeReset = -1;
	NudgeButtons = [];
	SceneFilesPrim = -1;
	PrimRegisteredUser = -1;
	PrimTeleporter = -1;
	integer P;
	for(P = 1; P <= PrimCount; P++) {
		string Name = llGetLinkName(P);
		if (Name == BoardPrimName) BoardLinkNum = P;
		else if (Name == "!clear") ButtonClearScene = P;
		else if (Name == "removeselected") ButtonRemoveSelected = P;
		else if (Name == "cloneselected") ButtonCloneSelected = P;
		else if (Name == "clockwise") ButtonRotateCN = P;
		else if (Name == "anticlockwise") ButtonRotateAN = P;
		else if (Name == "clockwiseFine") ButtonRotateCF = P;
		else if (Name == "anticlockwiseFine") ButtonRotateAF = P;
		else if (Name == "!notecard") ButtonFileLoad = P;
		else if (Name == "Capture data on chanel") ButtonFileSave = P;
		else if (Name == "!deletecard") ButtonFileDelete = P;
		else if (Name == "hidehand") ButtonHideHand = P;
		else if (Name == "Textures") PrimTexturePreview = P;
		else if (Name == "admin") ButtonAdmin = P;
		else if (Name == "move") ButtonMove = P;
		else if (Name == "scenefiles") SceneFilesPrim = P;
		else if (Name == "RegisteredUser") PrimRegisteredUser = P;
		else if (Name == "Teleporter") PrimTeleporter = P;
		else if (Name == "nudge") NudgeButtons += P;
		else if (Name == "size+") ButtonResizePlus = P;
		else if (Name == "size-") ButtonResizeMinus = P;
		else if (Name == "sizereset") ButtonResizeReset = P;
	}
	if (BoardLinkNum == -1) { llOwnerSay("Can't find board prim"); return FALSE; }
	if (SceneFilesPrim == -1) { llOwnerSay("Can't find scene files prim"); return FALSE; }
	if (PrimRegisteredUser == -1) { llOwnerSay("Can't find registered user display"); return FALSE; }
	SceneFilesPrimId = llGetLinkKey(SceneFilesPrim);
	return TRUE;
}
// Processes a load queue entry
ProcessLoadQueue() {
	if (llGetListLength(LoadQueue) == 0) return;    // nothing to load
	string ObjectName = llList2String(LoadQueue, 0);
	vector WorldPos = llList2Vector(LoadQueue, 1);
	rotation WorldRot = llList2Rot(LoadQueue, 2);
	float Size = llList2Float(LoadQueue, 3);
	string Changes = llList2String(LoadQueue, 4);
	string ExtraData = llList2String(LoadQueue, 5);
	CreateObject(ObjectName, WorldPos, WorldRot, Size, Changes, ExtraData);
	LoadQueue = llDeleteSubList(LoadQueue, 0, 5);
	if (llGetListLength(LoadQueue) == 0) {
		BroadcastMessage("Scene loaded.");
	}
}
// Save rotation and position of board
GetBoardPosRot() {
	list Params = llGetLinkPrimitiveParams(BoardLinkNum, [ PRIM_POSITION, PRIM_ROTATION, PRIM_SIZE ]);
	BoardPrimPos = llList2Vector(Params, 0);
	BoardPrimRot = llList2Rot(Params, 1);
}
// This function is from original by Ramesh
rotation RotBetween(vector start, vector end) //adjusts quaternion magnitude so (start * return == end)
{//Authors note: I have never had a use for this but it's good to know how to do it if I did.
	rotation rot = llRotBetween(start, end);
	if(llVecMag(start)!= 0)
	{
		if(llVecMag(end)!= 0)
		{
			float d = llSqrt(llVecMag(end) / llVecMag(start));
			return <rot.x * d, rot.y * d, rot.z * d, rot.s * d>;
		}
	}
	return rot;
}
// Send message to all avatars
BroadcastMessage(string Text) {
	list AvIds = llGetAgentList(AGENT_LIST_REGION, []);
	integer AvsCount = llGetListLength(AvIds);
	integer A;
	for(A = 0; A < AvsCount; A++) {
		llRegionSayTo(llList2Key(AvIds, A), 0, Text);
	}
}
ChangeBoardTexture(integer Reset) {
	if (Reset) BoardTexturePtr = 0; else BoardTexturePtr += 3;
	if (BoardTexturePtr >= llGetListLength(BoardTextures)) BoardTexturePtr = 0;
	list Params = llList2List(BoardTextures, BoardTexturePtr, BoardTexturePtr + 2);
	llSetLinkPrimitiveParamsFast(BoardLinkNum, [ PRIM_TEXTURE, BoardFace ] +  Params + [ 0.0 ]);
}
// Send command to menu
Menu(integer Command, string Text) {
	llMessageLinked(LINK_SET, Command, Text, NULL_KEY);
}
// Returns a list of all object names (including suffix)
list ListObjectsFull() {
	integer ObjectsCount = llGetInventoryNumber(INVENTORY_ALL);
	list Objects = [];
	integer O;
	for (O = 0; O < ObjectsCount; O++) {
		string Name = llGetInventoryName(INVENTORY_ALL, O);
		string Suffix = llGetSubString(Name, -1, -1);
		if (Suffix == SUFFIX_ICON || Suffix == SUFFIX_NOTECARD) {
			Objects += Name;
		}
	}
	return Objects;
}
// Returns a list of all icon basenames
list ListIcons() {
	integer Count = llGetInventoryNumber(INVENTORY_OBJECT);
	list Icons = [];
	integer I;
	for (I = 0; I < Count; I++) {
		string Name = llGetInventoryName(INVENTORY_OBJECT, I);
		if (llGetSubString(Name, -1, -1) == SUFFIX_ICON) {
			string BaseName = llGetSubString(Name, 0, -2);
			Icons += BaseName;
		}
	}
	return Icons;
}
// Returns a list of all config card basenames
list ListCards() {
	integer Count = llGetInventoryNumber(INVENTORY_NOTECARD);
	list Cards = [];
	integer C;
	for (C = 0; C < Count; C++) {
		string Name = llGetInventoryName(INVENTORY_NOTECARD, C);
		if (llGetSubString(Name, -1, -1) == SUFFIX_NOTECARD) {
			string BaseName = llGetSubString(Name, 0, -2);
			Cards += BaseName;
		}
	}
	return Cards;
}
// llGiveInventoryList() doesn't work in OpenSim when the target is a prim; this emulates that function
GiveInventoryList(key Uuid, list Objects) {
	integer Len = llGetListLength(Objects);
	integer O;
	for (O = 0; O < Len; O++) {
		string ObjectName = llList2String(Objects, O);
		llGiveInventory(Uuid, ObjectName);
	}
}
// Remove specified files from contents
DeleteFiles(list Filenames) {
	if (Filenames == []) return;
	integer Total = llGetListLength(Filenames);
	integer I;
	for (I = 0; I < Total; I++) {
		string Name = llList2String(Filenames, I);
		if (llGetInventoryType(Name) != INVENTORY_NONE) {
			llRemoveInventory(Name);
		}
	}
}
// Give link to information page
InfoPage(key AvId) {
	if (InfoPageUrl == "") {
		llDialog(AvId, "\nERROR: Info page URL not set (InfoPageUrl in config file)\n\nPlease report this to developers", [ "OK" ], -99992343);
		return;
	}
	if (ObjectPickerSelection == "") {
		llDialog(AvId, "\nNo object selected", [ "OK" ], -999912892);
		return;
	}
	integer P = llSubStringIndex(InfoPageUrl, "%s");
	if (P == -1) {
		BroadcastMessage("Info page URL does not contain '%s' - check configuration file");
		return;
	}
	string Url = "https://" + llGetSubString(InfoPageUrl, 0, P - 1) + ObjectPickerSelection + llGetSubString(InfoPageUrl, P + 2, -1);
	llLoadURL(AvId, "Show information page for this object", Url);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		BoardTextures = [
			// string texture, vector repeats, vector offsets
			"c1d3aaef-e42b-4e88-b165-2aee74a79e76", <1.0, 1.0, 0.0>, ZERO_VECTOR,
			"fbdaacee-7283-443f-9d27-d7beb5bfd716", <2.0, 2.0, 0.0>, <0.5, 0.5, 0.0>
				];
		FirstEverLoad = TRUE;
		state Bootup;
	}
}
state Bootup {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llMessageLinked(LINK_SET, LM_RESET_EVERTHING, "", NULL_KEY);    // tell other scripts to reset so resetting this script does everything
		llMessageLinked(LINK_SET, MENU_RESET, "", NULL_KEY);
		llSetRemoteScriptAccessPin(OBJECT_PIN);
		RegionSize = osGetRegionSize();
		ReadConfig();
		PrimCount = llGetNumberOfPrims();
		if (PrimCount == 1) return;        // dead script if unlinked
		if (!GetLinkNumbers()) return;
		GetBoardPosRot();	// Save rotation and position of board
		BoardPrimSize = llList2Vector(llGetLinkPrimitiveParams(BoardLinkNum, [ PRIM_SIZE ]), 0);	// find size of board prim
		BoardPrimHalfSize = BoardPrimSize / 2.0;    // Half scale, ie distance from origin to prim centre
		InitialRot = llEuler2Rot(<0.0, 0.0, 270.0> * DEG_TO_RAD);

		ReadParameterFiles();
		NextIconUniq = 100000;    // we keep this large so it doesn't have the same value as pointers to the ObjectData table
		HeartbeatMessage = (string)RZ_PING + "|" + RezzorName + "|" + (string)ScalingFactor + "|" + (string)SceneFilesPrimId;

		// Reset board texture to first one
		ChangeBoardTexture(TRUE);
		//
		ClearObjectsTable();
		DeSelectAll();
		TeleportedAvs = [];
		if (PrimTexturePreview > -1) {
			llSetLinkTexture(PrimTexturePreview, TEXTURE_TRANSPARENT, ALL_SIDES);
		}
		SetResizeIcons(FALSE);		// Hide resize icons
		LastResize = 1.0;		// Reset last resize
		SelectCreatedObject = NULL_KEY;		// Nobody's got an object ready to be selected
		llMessageLinked(LINK_SET, LM_BOOTED, "", NULL_KEY);
		if (FirstEverLoad) {
			llOwnerSay("Ready");
			FirstEverLoad = FALSE;
		}
		state Normal;
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Menu(MENU_CLEAR, "");		// in case menu left over
		llSetTimerEvent(2.0);        // exact value doesn't matter
		ProcessLoadQueue();
	}
	dataserver(key From, string Data) {
		// Handle teleporter objects separately
		if (llKey2Name(From) == TELEPORT_OBJECT_NAME) {
			TeleportObject(From, Data);
			return;
		}
		// All other incoming data
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		integer Command = llList2Integer(Parts, 0);
		list Params = llList2List(Parts, 1, -1);	// we could move to using this list instead of Parts below, slightly neater - JH
		if (Command == RZ_PING) {
			// rezzor acknowledges us
			// Commented out because it can get overly chatty when >1 rezzors exist
			if (RezzorId != NULL_KEY && RezzorId != From) {
				BroadcastMessage("Detected change of rezzor object");
			}
			RezzorId = From;
		}
		else if (Command == RZ_CREATE) {
			// We get a message back from the rezzor telling us the icon ID we sent it, plus the object UUID
			// that it created, which we need
			key IconId = llList2Key(Parts, 1);
			key WorldId = llList2Key(Parts, 2);
			if (IconId == NULL_KEY || (string)IconId == "") BroadcastMessage("Rezzor returned invalid icon ID");
			if (WorldId == NULL_KEY || (string)WorldId == "") BroadcastMessage("Rezzor returned invalid world ID");
			integer ObjPtr = llListFindList(ObjectData, [ IconId ]);
			if (ObjPtr == -1) {
				BroadcastMessage("Failed to find recently rezzed icon");
				return;
			}
			ObjPtr -= OBJ_ICON_ID;	// position at start of stride
			ObjectData = llListReplaceList(ObjectData, [ WorldId ], ObjPtr + OBJ_WORLD_ID, ObjPtr + OBJ_WORLD_ID);    // fill in object ID
			integer AdjustHeight = FALSE;
			string ObjectName = llList2String(ObjectData, ObjPtr + OBJ_NAME);
			float Size = llList2Float(ObjectData, ObjPtr + OBJ_SIZE);
			string ExtraData = llList2String(ObjectData, ObjPtr + OBJ_EXTRA_DATA);
			string Changes = llList2String(ObjectData, ObjPtr + OBJ_CHANGES);
			string ObjectParams = GetParams(ObjectName);
			if (IsParam(ObjectParams, "H")) AdjustHeight = TRUE;		// This is also included in Params, so it's redundant (but kept for backward compatibility)
			// send configuration world object data
			MessageStandard(WorldId, WO_INITIALISE, [ WorldObjectHoverTextColour, WorldObjectHoverTextAlpha, AdjustHeight, IconId, ExtraData, ObjectParams ]);
			if (IsParam(ObjectParams, "D")) {		// if dummy move needed
				// This is a workaround for an OpenSim bug whereby mesh objects rezzed with a non-zero
				// rotation have a physics envelope which doesn't match the rotation. This hack issues a
				// dummy move command to force the object to move itself (to the identical position), which seems
				// to make OpenSim update the physics to a correct rotation.
				vector Pos = llList2Vector(ObjectData, ObjPtr + OBJ_POS);    // find the world object's position
				MessageStandard(WorldId, WO_MOVE, [ Pos ]);		// tell the world object to do the move
			}
			if (Size > 0.0 && Size != 1.0) {	// if object needs resizing
				Resize(RESIZE_ABSOLUTE, ObjPtr, WorldId, IconId, Size, FALSE);
			}
			else if (LastResize > 0.0) {
				Resize(RESIZE_ABSOLUTE, ObjPtr, WorldId, IconId, LastResize, FALSE);
			}
			if (Changes != "") {
				list ChangesList = llParseStringKeepNulls(Changes, [ "^" ], []);
				Change(IconId, ChangesList, TRUE, FALSE);
			}
			if (SelectCreatedObject != NULL_KEY) {
				SelectByIconId(IconId, SelectCreatedObject);
				SelectCreatedObject = NULL_KEY;
			}
			ProcessLoadQueue();
		}
		else if (Command == IC_INITIALISE) {
			// A newly-rezzed icon has sent us its wake-up message
			key IconId = From;
			integer Uniq = llList2Integer(Parts, 1);
			// We need to find our icon in the objects table.
			// We do this by reference to the unique number the icon just passed us, which we in turn allocated and passed to it
			// when we created it.
			integer U = llListFindList(IconUniqs, [ Uniq ]); // Uniq should be much bigger than any Objects pointer
			if (U > -1) {
				integer ObjPtr = llList2Integer(IconUniqs, U + 1);
				IconUniqs = llDeleteSubList(IconUniqs, U, U + 1);    // we don't need this any more
				IconUniqEntries--;
				// Now get data from Objects table
				string Name = llList2String(ObjectData, ObjPtr + OBJ_NAME);
				vector WorldPos = llList2Vector(ObjectData, ObjPtr + OBJ_POS);
				rotation Rot = llList2Rot(ObjectData, ObjPtr + OBJ_ROT);
				string ObjectParams = GetParams(Name);
				// We pass the icon its configuration data and parameters
				MessageStandard(IconId, IC_INITIALISE, [ IconSelectGlow, IconSelectParticleColour, IconHoverTextColour, IconHoverTextAlpha, ObjectParams ]);
				// Now we have the icon id, we can send data to the rezzor to create in-world object
				RezzorCreate(Name, WorldPos, Rot, IconId);
				ObjectData = llListReplaceList(ObjectData, [ From ], ObjPtr + OBJ_ICON_ID, ObjPtr + OBJ_ICON_ID);    // fill in icon ID
				// The icon may not be in the correct place (max 10m rezzing distance), so tell it where to go
				vector IconPos = WorldPos2BoardPos(WorldPos);
				MessageStandard(IconId, IC_MOVE, [ IconPos ]);
			}
			else {
				BroadcastMessage("Icon initialise error: can't find table entry");
				MessageStandard(IconId, IC_DELETE, []);        // delete the icon
				//                DumpObjectsTable();
				return;
			}
		}
		else if (Command == IC_SHORT_CLICK) {
			// Short click on an icon, either to move an object or create one
			key IconId = From;
			//integer ObjPtr = ObjectPtrFromIconId(IconId);
			// Pick up data sent to us by the icon
			key AvId = llList2Key(Parts, 1);
			if (!RegisteredAv(AvId)) return;
			vector TouchPos = llList2Vector(Parts, 2);
			vector TouchNormal = llList2Vector(Parts, 3);
			vector TouchBinormal = llList2Vector(Parts, 4);
			rotation TouchIconRot = llList2Rot(Parts, 5);
			vector WorldPos = BoardPos2WorldPos(TouchPos);
			// Find out if this avatar has an object selected
			integer SelPtr = llListFindList(Selections, [ AvId ]);
			if (SelPtr > -1) {        // if they have a selection
				SelPtr -= SEL_AV_ID;    // position at beginning of slice
				key SelIconId = llList2Key(Selections, SelPtr + SEL_ICON_ID);
				if (SelIconId == IconId) return;    // they've short-clicked on the selected icon; no sensible thing to do with that
				key WorldId = llList2Key(Selections, SelPtr + SEL_WORLD_ID);
				integer SelObjPtr = llList2Integer(Selections, SelPtr + SEL_OBJ_PTR);
				string SelObjectName = llList2String(ObjectData, SelObjPtr + OBJ_NAME);
				//				rotation IconRot = NormalisedRot(SelObjectName, TouchIconRot, TouchNormal);
				//				rotation WorldRot = IconRot2WorldRot(IconRot);
				MoveObject(SelObjPtr, WorldId, SelIconId, WorldPos, TouchIconRot, TouchNormal);
			}
			else if (ObjectPickerSelection != "") {        // if an object is selected on the object picker
				rotation IconRot = NormalisedRot(ObjectPickerSelection, TouchIconRot, TouchNormal);
				rotation WorldRot = IconRot2WorldRot(IconRot);
				CreateObject(ObjectPickerSelection, WorldPos, WorldRot, 1.0, "", "");
			}
		}
		else if (Command == IC_LONG_CLICK) {
			// Message from icon telling us that a user has long-clicked it
			// We interpret this to mean a selection
			key IconId = From;
			key AvId = llList2Key(Parts, 1);
			if (!RegisteredAv(AvId)) return;
			// Find any other selection by same user
			key SelIconId = FindSelectedIconByAvId(AvId);
			if (SelIconId != NULL_KEY) {
				// the avatar already has something selected, so deselect it
				DeselectByAvId(AvId);
			}
			// if the selection is the same icon, they've deselected by long-clicking, so we don't need to do anything else
			if (SelIconId == IconId) return;
			// Now select the object
			SelectByIconId(IconId, AvId);
			// ObjectPickerSelection = "";        // Echo original method, which seemed to disable object picker when (after) something is selected
			// Above not necessary (checked with RR 29/10/15)
		}
		else if (Command == IC_CHANGE) {
			Change(From, Params, FALSE, TRUE);
		}
		else if (Command == IC_MOVE_ROTATE) {
			MoveRotate(From, Params);
		}
		else if (Command == GE_VERSION) {
			osMessageObject(From, "C" + (string)Version);
		}
		else if (Command == WO_EXTRA_DATA) {
			string ExtraData = llList2String(Parts, 1);
			integer O = llListFindList(ObjectData, [ From ]);
			if (O == -1) {
				BroadcastMessage("Can't find object to set extra data");
				return;
			}
			O -= OBJ_WORLD_ID;	// position at start of row
			ObjectData = llListReplaceList(ObjectData, [ ExtraData ], O + OBJ_EXTRA_DATA, O + OBJ_EXTRA_DATA);
		}
		else if (Command == IC_UPDATE) {
			string Action = llList2String(Parts, 1);
			list Objects = llList2List(Parts, 2, -1);
			if (Action == "list") {
				// requesting list of icons and config cards
				osMessageObject(From, llDumpList2String("I" + ListIcons(), "|"));
				osMessageObject(From, llDumpList2String("C" + ListCards(), "|"));
			}
			else if (Action == "download") {
				string Object = llList2String(Objects, 0);
				string ActionIcon = Object + SUFFIX_ICON;
				string ActionConfig = Object + SUFFIX_NOTECARD;
				if (llGetInventoryType(ActionIcon) == INVENTORY_OBJECT) {
					llGiveInventory(From, ActionIcon);
				}
				if (llGetInventoryType(ActionConfig) == INVENTORY_NOTECARD) {
					llGiveInventory(From, ActionConfig);
				}
			}
			else if (Action == "delete") {
				string Object = llList2String(Objects, 0);
				string ActionIcon = Object + SUFFIX_ICON;
				string ActionConfig = Object + SUFFIX_NOTECARD;
				if (llGetInventoryType(ActionIcon) == INVENTORY_OBJECT) {
					llRemoveInventory(ActionIcon);
				}
				if (llGetInventoryType(ActionConfig) == INVENTORY_NOTECARD) {
					llRemoveInventory(ActionConfig);
				}
			}
			else if (Action == "uploadI") {
				// it's a list of icons
				// So we remove them
				integer Len = llGetListLength(Objects);
				integer O;
				for (O = 0; O < Len; O++) {
					string Name = llList2String(Objects, O) + SUFFIX_ICON;
					if (llGetInventoryType(Name) == INVENTORY_OBJECT) llRemoveInventory(Name);
				}
				// Now tell updater we've finished
				osMessageObject(From, "I");
			}
			else if (Action == "uploadC") {
				// it's a list of config cards
				// So we remove them
				integer Len = llGetListLength(Objects);
				integer O;
				for (O = 0; O < Len; O++) {
					string Name = llList2String(Objects, O) + SUFFIX_NOTECARD;
					if (llGetInventoryType(Name) == INVENTORY_NOTECARD) llRemoveInventory(Name);
				}
				// Now tell updater we've finished
				osMessageObject(From, "C");
			}
		}
		else if (Command == ARCH_BACKUP_START) {
			if (llGetOwnerKey(From) != llGetOwner()) return;	// Only owner's archiver can talk to me
			ArchiverId = From;
			ArchiveAction = ARCHIVE_BACKUP;
			state Archive;
		}
		else if (Command == ARCH_RESTORE_START) {
			if (llGetOwnerKey(From) != llGetOwner()) return;	// Only owner's archiver can talk to me
			ArchiverId = From;
			ArchiveAction = ARCHIVE_RESTORE;
			state Archive;
		}
		else if (Command == ARCH_PURGE) {
			if (llGetOwnerKey(From) != llGetOwner()) return;	// Only owner's archiver can talk to me
			ArchiverId = From;
			ArchiveAction = ARCHIVE_PURGE;
			state Archive;
		}
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == LM_OBJECT_PICKER) {
			if (Message == "unselectAll") {
				ObjectPickerSelection = "";
				LastResize = 1.0;
				DeSelectAll();
			}
			else {
				// Handle click on library thumbnail
				string Object = Message;
				key ThisRegisteredId = Id;
				if (llGetSubString(Object, 0, 1) == "c_") Object = llGetSubString(Object, 2, -1);    // strip leading "c_" from legacy objects
				if (ThisRegisteredId != RegisteredId) {
					RegisteredId = ThisRegisteredId;
					llMessageLinked(PrimRegisteredUser, TEXT_DISPLAY, llKey2Name(RegisteredId), NULL_KEY);
				}
				ObjectPickerSelection = Object;
				LastResize = 1.0;
				DeSelectAll();
			}
		}
		else if (Number == -LM_ENVIRONMENT) {	// note that -ve is incoming, +ve outgoing
			EnvironmentDetails = Message;
		}
	}
	touch_start(integer Count) {
		while(Count--) {
			integer LinkNum = llDetectedLinkNumber(Count);
			key AvId = llDetectedKey(Count);
			// File handling needs its own state
			if (LinkNum == ButtonFileLoad) {
				FHAvId = AvId;
				FHType = FHT_LOAD;
				state FileHandling;
			}
			else if (LinkNum == ButtonFileSave) {
				FHAvId = AvId;
				FHType = FHT_SAVE;
				state FileHandling;
			}
			else if (LinkNum == ButtonFileDelete) {
				state Test;
			}
			else if (LinkNum == ButtonAdmin) {
				AMAvId = AvId;
				state AdminMenu;
			}
			else if (LinkNum == PrimTeleporter) {
				if (llDetectedTouchFace(Count) == 0) {
					TeleporterClick(
						llDetectedKey(Count),
						llDetectedTouchST(Count)
							);
				}
			}
			// All other clicks are handled by the Click() function
			Click(AvId, LinkNum, llDetectedTouchFace(Count), llDetectedTouchPos(Count), llDetectedTouchST(Count));
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MOVE_INPUT_CHANNEL) {
			key AvId = Id;
			list L = llParseString2List(Message, [ " ", "," ], []);
			integer Elements = llGetListLength(L);
			if (Elements < 2 || Elements > 3) return;
			integer IsSelected = FALSE;
			integer SelPtr = llListFindList(Selections, [ AvId ]);
			integer ObjPtr = -1;
			if (SelPtr == -1) return;    // nothing selected
			SelPtr -= SEL_AV_ID;    // position at start of stride
			key IconId = llList2Key(Selections, SelPtr + SEL_ICON_ID);
			key WorldId = llList2Key(Selections, SelPtr + SEL_WORLD_ID);
			ObjPtr = ObjectPtrFromIconId(IconId);
			vector NewPos;
			NewPos.x = llList2Float(L, 0);
			NewPos.y = llList2Float(L, 1);
			if (Elements == 2) {
				vector Offset = NewPos - llGetPos();
				NewPos.z = llGround(Offset);
			}
			rotation Rot = llList2Rot(ObjectData, ObjPtr + OBJ_ROT);
			MoveObject(ObjPtr, WorldId, IconId, NewPos, Rot, VERTICAL_NORMAL);
		}
	}
	timer() {
		llRegionSay(CHAT_CHANNEL, HeartbeatMessage);
		GetBoardPosRot(); // this would be in moving_end() if that event were working in OpenSim (which it's not)
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) state Bootup;
		if (Change & CHANGED_INVENTORY) {
			ReadConfig();
			ReadParameterFiles();
		}
	}
}
state FileHandling {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		if (FHType == FHT_SAVE) {
			SortObjects();
			FHObjPtr = 0;
			llMessageLinked(SceneFilesPrim, LM_FILE_SAVE_START, EnvironmentDetails, FHAvId);	// Environment details piggy-back onto start of save comms (other details could go here too, later)
		}
		else if (FHType == FHT_LOAD) {
			LoadQueue = [];
			llMessageLinked(SceneFilesPrim, LM_FILE_LOAD_START, "", FHAvId);
		}
		else if (FHType == FHT_DELETE) {
			llMessageLinked(SceneFilesPrim, LM_FILE_DELETE, "", FHAvId);
		}
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Sender == SceneFilesPrim) {
			if (Number == LM_FILE_CANCEL) {
				state Normal;
			}
			if (Number == LM_FILE_SAVE_DATA) {
				string Name = llList2String(ObjectData, FHObjPtr + OBJ_NAME);
				vector Pos = llList2Vector(ObjectData, FHObjPtr + OBJ_POS);
				rotation Rot = llList2Rot(ObjectData, FHObjPtr + OBJ_ROT);
				vector RotD = llRot2Euler(Rot) * RAD_TO_DEG;
				float Size = llList2Float(ObjectData, FHObjPtr + OBJ_SIZE);
				string Changes = llList2String(ObjectData, FHObjPtr + OBJ_CHANGES);
				string Spare = "";	// for future use
				string ExtraData = llList2String(ObjectData, FHObjPtr + OBJ_EXTRA_DATA);
				string Line = llDumpList2String([ Name, Pos, RotD, Size, Changes, Spare, ExtraData ], "|");
				llMessageLinked(SceneFilesPrim, LM_FILE_SAVE_DATA, Line, FHAvId);
				FHObjPtr += OBJ_STRIDE;
				if (FHObjPtr >= ObjectDataSize) {
					llMessageLinked(SceneFilesPrim, LM_FILE_SAVE_END, "", FHAvId);
					state Normal;
				}
			}
			else if (Number == LM_FILE_CLEAR_SCENE) {
				BroadcastMessage("Loading scene, please wait ...");
				// We clear the scene preparatory to a scene load
				ClearScene();
				// Next we request the first record of data
				llMessageLinked(SceneFilesPrim, LM_FILE_LOAD_DATA, "", FHAvId);
			}
			else if (Number == LM_FILE_LOAD_DATA) {
				LastResize = 1.0;
				list Parts = llParseStringKeepNulls(Message, [ "|" ], []);
				string FirstPart = llList2String(Parts, 0);
				if (llGetSubString(FirstPart, 0, 0) == "!") {		// notecard lines beginning with ! are special lines
					string Identifier = llGetSubString(FirstPart, 1, -1);
					if (Identifier == "environment") {
						EnvironmentDetails = llDumpList2String(llList2List(Parts, 1, -1), "|");		// repack remaining parts - the environment script sorts them out
						llMessageLinked(LINK_SET, LM_ENVIRONMENT, "set|" + EnvironmentDetails, NULL_KEY);	// pass the data to environment script for it to implement
					}
				}
				else {
					string ObjectName = FirstPart;
					vector WorldPos = llList2Vector(Parts, 1);
					vector RotD = llList2Vector(Parts, 2);
					float Size = (float)llList2String(Parts, 3);
					if (Size == 0.0) Size = 1.0;			// legacy notecards would not have this set
					string Changes = llList2String(Parts, 4);
					string Spare = llList2String(Parts, 5);	// for future use
					string ExtraData = llList2String(Parts, 6);
					rotation WorldRot = llEuler2Rot(RotD * DEG_TO_RAD);
					LoadQueue += [ ObjectName, WorldPos, WorldRot, Size, Changes, ExtraData ];
				}
				llMessageLinked(SceneFilesPrim, LM_FILE_LOAD_DATA, "", FHAvId);
			}
			else if (Number == LM_FILE_LOAD_END) {
				// Normal state will then create the objects/icons from the load queue
				state Normal;
			}

		}
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) state Bootup;
		if (Change & CHANGED_INVENTORY) state Bootup;
	}
}
state AdminMenu {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Menu(MENU_INIT, "");
		Menu(MENU_DIMENSIONS, "512, 512");
		Menu(MENU_TITLE, "ADMIN MENU");
		Menu(MENU_DESCRIPTION, "Select:");
		Menu(MENU_SIDES, "1");
		Menu(MENU_USER, (string)AMAvId);    // restrict menu to user who called it
		Menu(MENU_BUTTON, "Texture,S");        // "S" flag makes menu stick
		Menu(MENU_BUTTON, "Reset");
		Menu(MENU_BUTTON, "Check");
		Menu(MENU_OPTION, "xclosebutton");	// Have an X to close the menu
		Menu(MENU_ACTIVATE, "");
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == MENU_RESPONSE) {
			if (Message == "Close") {
				state Normal;
			}
			else if (Message == "Reset") {
				Reset();
			}
			else if (Message == "Texture") {
				ChangeBoardTexture(FALSE);
				return;        // return because it's a "stay" option (ie menu isn't removed)
			}
			else if (Message == "Check") {
				state IntegrityCheck;
			}
			state Normal;
		}
		else if (Number == MENU_CANCEL) {        // menu script reset or similar
			state Normal;
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) state Bootup;
		if (Change & CHANGED_INVENTORY) state Bootup;
	}
}
state ReloadAdminMenu {    state_entry() { state AdminMenu; }}
state OKCancel {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Menu(MENU_INIT, "");
		Menu(MENU_DIMENSIONS, "512, 512");
		Menu(MENU_TITLE, "CONFIRMATION");
		Menu(MENU_SIDES, "1");
		Menu(MENU_USER, (string)OKCancelAvId);    // restrict menu to user who called it
		Menu(MENU_BUTTON, OKCancelDesc);
		Menu(MENU_BUTTON, "Cancel");
		Menu(MENU_OPTION, "ButtonAlignLeft");
		Menu(MENU_ACTIVATE, "");
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == MENU_RESPONSE) {
			if (Message == "Cancel") {
				state Normal;
			}
			else if (Message == OKCancelDesc) {
				if (OKCancelOption == OKC_CLEAR_SCENE) ClearScene();
				state Normal;
			}
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) state Bootup;
		if (Change & CHANGED_INVENTORY) state Bootup;
	}
}
state IntegrityCheck {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		BroadcastMessage("Commencing integrity check ...");
		list OL = [];
		integer OC = llGetInventoryNumber(INVENTORY_OBJECT);
		integer O;
		for (O = 0; O < OC; O++) {
			string Name = llGetInventoryName(INVENTORY_OBJECT, O);
			if (llGetSubString(Name, -1, -1) == SUFFIX_ICON) {
				if (!IsFullPerm(Name)) {
					BroadcastMessage("WARNING: Icon not full-perm: " + Name);
				}
				string BaseName = llGetSubString(Name, 0, -2);		// strip suffix
				OL += BaseName;
			}
			else if (Name == TELEPORT_OBJECT_NAME) {
				// ignore
			}
			else {
				BroadcastMessage("WARNING: Non-icon object in control board: " + Name);
			}
		}
		integer NC = llGetInventoryNumber(INVENTORY_NOTECARD);
		integer N;
		for (N = 0; N < NC; N++) {
			string Name = llGetInventoryName(INVENTORY_NOTECARD, N);
			if (Name != CONFIG_NOTECARD) {
				if (llGetSubString(Name, -1, -1) == SUFFIX_NOTECARD) {
					if (!IsFullPerm(Name)) {
						BroadcastMessage("WARNING: Config notecard not full-perm: " + Name);
					}
				}
				else {
					BroadcastMessage("WARNING: Unknown notecard in control board: " + Name);
				}

			}
		}
		llMessageLinked(LINK_SET, LM_INTEGRITY_CHECK, llDumpList2String(OL, "|"), RezzorId);	// send list of icons to object picker
		state Normal;
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) state Bootup;
		if (Change & CHANGED_INVENTORY) state Bootup;
		if (Change & CHANGED_REGION_START) state Normal;
	}
}
state Archive {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		if (ArchiveAction == ARCHIVE_BACKUP) {
			// When we receive "backup", we send "backupfiles" with a list of our files and wait.
			// Archiver will delete its copies of those files and send "backupstart".
			ArchiveFiles = ListObjectsFull();
			MessageStandard(ArchiverId, ARCH_BACKUP_FILES, ArchiveFiles);
		}
		else if (ArchiveAction == ARCHIVE_RESTORE) {
			MessageStandard(ArchiverId, ARCH_RESTORE_START, []);	// Request list of files
		}
		else if (ArchiveAction == ARCHIVE_PURGE) {
			DeleteFiles(ListObjectsFull());
			TimerPurpose = TP_PURGED;
			llSetTimerEvent(0.5);
		}
	}
	dataserver(key From, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		integer Command = llList2Integer(Parts, 0);
		list Params = llList2List(Parts, 1, -1);
		if (From == ArchiverId) {
			if (Command == ARCH_BACKUP_FILES) {
				// Archiver is ready to receive backup, so send the files
				GiveInventoryList(From, ArchiveFiles);
				ArchiveFiles = [];
				// Send confirmation that that's all the files
				MessageStandard(ArchiverId, ARCH_BACKUP_END, []);
				// Return to normality
				TimerPurpose = TP_FINISH;
				llSetTimerEvent(0.5);
			}
			else if (Command == ARCH_RESTORE_FILES) {
				ArchiveFiles = llList2List(Params, 0, -1);
				DeleteFiles(ArchiveFiles);
				// Request files
				TimerPurpose = TP_REQUEST;
				llSetTimerEvent(0.5);
			}
			else if (Command == ARCH_RESTORE_END) {
				// Return to normality
				TimerPurpose = TP_FINISH;
				llSetTimerEvent(0.5);
			}
		}
	}
	timer() {
		// Once more, we're using a timer to circumvent OpenSim glitches by forcing processes into another sim frame
		llSetTimerEvent(0.0);
		if (TimerPurpose == TP_FINISH) {
			state Bootup;
		}
		else if (TimerPurpose == TP_REQUEST) {
			MessageStandard(ArchiverId, ARCH_RESTORE_FILES, []);
		}
		else if (TimerPurpose == TP_PURGED) {
			MessageStandard(ArchiverId, ARCH_PURGE, []);
			state Bootup;
		}
	}
}
state Test {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llOwnerSay("Running tests ...");
		LoadQueue = [];
		llMessageLinked(LINK_SET, MENU_RESPONSE, 
				}
	touch_start(integer total_number)
	{
		state Normal;
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Sender == SceneFilesPrim) {
			if (Number == LM_FILE_CANCEL) {
				state Normal;
			}
			if (Number == LM_FILE_SAVE_DATA) {
				string Name = llList2String(ObjectData, FHObjPtr + OBJ_NAME);
				vector Pos = llList2Vector(ObjectData, FHObjPtr + OBJ_POS);
				rotation Rot = llList2Rot(ObjectData, FHObjPtr + OBJ_ROT);
				vector RotD = llRot2Euler(Rot) * RAD_TO_DEG;
				float Size = llList2Float(ObjectData, FHObjPtr + OBJ_SIZE);
				string Changes = llList2String(ObjectData, FHObjPtr + OBJ_CHANGES);
				string Spare = "";	// for future use
				string ExtraData = llList2String(ObjectData, FHObjPtr + OBJ_EXTRA_DATA);
				string Line = llDumpList2String([ Name, Pos, RotD, Size, Changes, Spare, ExtraData ], "|");
				llMessageLinked(SceneFilesPrim, LM_FILE_SAVE_DATA, Line, FHAvId);
				FHObjPtr += OBJ_STRIDE;
				if (FHObjPtr >= ObjectDataSize) {
					llMessageLinked(SceneFilesPrim, LM_FILE_SAVE_END, "", FHAvId);
					state Normal;
				}
			}
			else if (Number == LM_FILE_CLEAR_SCENE) {
				BroadcastMessage("Loading scene, please wait ...");
				// We clear the scene preparatory to a scene load
				ClearScene();
				// Next we request the first record of data
				llMessageLinked(SceneFilesPrim, LM_FILE_LOAD_DATA, "", FHAvId);
			}
			else if (Number == LM_FILE_LOAD_DATA) {
				LastResize = 1.0;
				list Parts = llParseStringKeepNulls(Message, [ "|" ], []);
				string FirstPart = llList2String(Parts, 0);
				if (llGetSubString(FirstPart, 0, 0) == "!") {		// notecard lines beginning with ! are special lines
					string Identifier = llGetSubString(FirstPart, 1, -1);
					if (Identifier == "environment") {
						EnvironmentDetails = llDumpList2String(llList2List(Parts, 1, -1), "|");		// repack remaining parts - the environment script sorts them out
						llMessageLinked(LINK_SET, LM_ENVIRONMENT, "set|" + EnvironmentDetails, NULL_KEY);	// pass the data to environment script for it to implement
					}
				}
				else {
					string ObjectName = FirstPart;
					vector WorldPos = llList2Vector(Parts, 1);
					vector RotD = llList2Vector(Parts, 2);
					float Size = (float)llList2String(Parts, 3);
					if (Size == 0.0) Size = 1.0;			// legacy notecards would not have this set
					string Changes = llList2String(Parts, 4);
					string Spare = llList2String(Parts, 5);	// for future use
					string ExtraData = llList2String(Parts, 6);
					rotation WorldRot = llEuler2Rot(RotD * DEG_TO_RAD);
					LoadQueue += [ ObjectName, WorldPos, WorldRot, Size, Changes, ExtraData ];
				}
				llMessageLinked(SceneFilesPrim, LM_FILE_LOAD_DATA, "", FHAvId);
			}
			else if (Number == LM_FILE_LOAD_END) {
				// Normal state will then create the objects/icons from the load queue
				state Normal;
			}

		}
	}	
}
// RezMela controller v0.34

