// Malleable linkset v1.21.13

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
// Additional documentation about ML, ML Linkset limits http://wiki.rezmela.org/doku.php/ml-limits?s[]=primsource

// v1.21.13 refactor to use object's UUID instead of link number for internal tables
// v1.21.12 add HideOptions to ML config
// v1.21.11 get region size on every initialisation
// v1.21.10 fix bug with AOC object size
// v1.21.9 expose queue and batch sizes in ML Config
// v1.21.8 improved comms for object rezzing
// v1.21.7 split object data in dynamic and static
// v1.21.6 further initialization improvements
// v1.21.5 changed cataloguer startup
// v1.21.4 bug fixing
// v1.21.3 further improvements in startup handshaking
// v1.21.2 introduce Initialize in both on_rez and state_entry
// v1.21.1 reduce memory usage when idle
// v1.21.0 fixed various bugs (stickpoints, SizeFactor in saves, resize resetting rotations, etc)
// v1.20 ignore deleted child apps during save; fix synch issues with save; StickPoint rotations; process catalog in default state
// v1.19 fix "1m cube layout objects" bug
// v1.18 fix SizeFactor in new objects
// v1.17 bug fixes
// v1.16 apps within apps
// v1.15 implement RegionSnap for Apps (linked & detached); add MaxAvatars
// v1.14 stored rotations bug; CopyRotation added
// v1.13 use better parsing of config file (to allow = signs in value); dummy move on region restart
// v1.12 implement LM_MOVED_ROTATED (sent to MLO when it's moved or rotated)
// v1.11 make TerrainChange default to FALSE
// v1.10 fix bug in "rotate" function (90° fix related)
// v1.9 improvements to "phantom" (ie physics=none) processing
// v1.8 compensate for 90 degree rotation in placement
// v1.7 add "phantom" processing
// v1.6 bug in config file changing
// v1.5 make PrimSource mandatory
// v1.4 add "advanced menu" option; new error handler; encrypted limits
// v1.3 fixed placing objects on root prim
// v1.2 fixed "Can't find LO entry to get StickPoints" spurious errora
// v1.1 fix bug with objects count; save modules data in save file
// v1.0 make selection glow of linked objects configurable

// Psuedo-constants
integer DEBUGGER = -391867620;
float TIMER_FREQUENCY = 0.5;    // Frequency of timer ticks
integer TIMEOUT_CHECK_FREQUENCY = 25;    // How many ticks between selection timeout checks (25 @ 0.2 = 5 secs)
string ADMINS_NOTECARD = "Admins";    // Name of notecard containing administrator names
string CONFIG_NOTECARD = "ML config";
integer COMMS_CHANNEL = -77101084;
vector HIDDEN_PRIM_SIZE = <0.01, 0.01, 0.01>;    // size of hidden prims
string SOUND_PICK = "74fe1909-8033-4476-9930-17a26e3077ba";            // names or UUIDs of sounds for prim movement
string SOUND_PLACE = "96639f6f-8394-421e-a640-9b8d820aa677";
float SOUND_VOLUME = 0.9;        // volume of sound (0-1)
integer SAVE_FILE_VERSION = 3;        // current version of save file format
string SFM_NAME = "&SceneFileManager&";	// Name of SFM prim
integer ON_REZ_PARAMETER = 10884726;
vector VEC_NAN = <-99.0,99.0,-99.0>;    // nonsense value to indicate "not a number" for vectors
rotation ROT_NAN = <1.0, 2.0, 3.0, 4.0>; // ditto for rotations
rotation MAP_NUDGE_ROT =  <0.0, 0.00, 0.707107, 0.707107>; // llEuler2Rot(<0, 0, 90> * DEG_TO_RAD) - adjustment for nudge directions in maps
float TIDY_STEP = 45.0;	// Distance between scans in Tidy function. Range is 96, so this is small enough to cover each scan area (Pythagorean theorem)
vector DUMMY_OFFSET = <0.01, 0.01, 0.01>;	// object is shifted by this amount by a dummy move
string LIMITS_KEY = "H6f4p5T";	// used for decrypting limits data

integer SHORT_CLICK = 1;
integer LONG_CLICK = 2;

rotation InitialRot;	// the rotation world objects are given when first created

// Linked message constants. We use the integer portion of LMs as commands, because it's much
// cheaper to compare integers than strings, and strings and keys are more useful for data.
integer LM_PRIM_SELECTED = -405500;        // A prim has been selected (sent to other scripts)
integer LM_PRIM_DESELECTED = -405501;    // A prim has been deselected
integer LM_EXECUTE_COMMAND = -405502;    // Execute command (from other script)
integer LM_CARD_AVAILABLE = -405505;
integer LM_CARD_VALUE = -405506;
integer LM_CARD_RESET = -405507;
integer LM_OUTSOURCE_COMMAND = -405510;
integer LM_SCOREBOARD = -405512;
integer LM_REMOTE_UNLINK = -405515;            // received from child prim that wants to unlink itself
integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_RANDOM_CREATE = -405518;
integer LM_RANDOM_VALUES = -405519;
integer LM_SEAT_USER = -405520;
integer LM_EXTERNAL_LOGIN = -405521;
integer LM_EXTERNAL_LOGOUT = -405522;
integer LM_EXTERNAL_DESELECT = -405523;	// if we receive this, we deselect the object
integer LM_LOADING_COMPLETE = -405530;
integer LM_AUTOHIDE_SET  = -405532; // from communicator: hide/unhide commands
integer LM_RESET = -405535;
integer LM_TASK_COMPLETE = -405536;
integer LM_APP_BACKUP_REQUEST = -405538;
integer LM_APP_BACKUP_SEND = -405539;
integer LM_APP_RESTORE = -405542;
integer LM_HUD_STATUS = -405543;
integer LM_NUDGE_STATUS = -405544;
integer LM_LOCKED = -405545;
integer LM_PUBLIC_DATA = -405546;
integer LM_CAMERA_JUMP_MODE = -405547;
integer LM_OBJECTS_COUNT = -405548;
integer LM_FAILURE = -405549;
integer LM_WRITE_CONFIG = -405550;
integer LM_CHANGE_CONFIG = -405551;
integer LM_MOVED_ROTATED = -405560;
integer LM_CHILD_READY = -405561;	// sent by child app to parent when ready
integer LM_UNLINK_QUEUE = -405562;

integer LM_TOUCH_NORMAL    = -66168300;
integer LM_TOUCH_ALTERNATE = -66168301;

integer LM_RESERVED_TOUCH_FACE = -44088510;		// Reserved Touch Face (RTF)

// Save file manager linked messages
integer SFM_LOAD = -3310421;
integer SFM_SAVE = -3310422;
integer SFM_DELETE = -3310423;
integer SFM_BACKUP = -3310424;
integer SFM_DELETE_ALL = -3310427;

// Cataloguer's messages
integer CT_REQUEST_DATA	= -83328400;
integer CT_CATALOG			= -83328401;
integer CT_START			= -83328402;
integer CT_MODULES			= -83328407;
integer CT_READY			= -83328408;


// Librarian commands
integer LIB_REZ_OBJECTS 	= -879189120;
integer LIB_INITIALIZE 	= -879189122;
integer LIB_REZZED			= -879189123;

// World object commands
integer WO_MOVE = 3000;
integer WO_ROTATE = 3001;
integer WO_MOVE_ROTATE = 3002;
integer WO_DELETE = 3003;
integer WO_INITIALISE = 3004;
integer WO_SELECT = 3005;
integer WO_DESELECT = 3006;
integer WO_RESIZE = 3009;
integer WO_INITIALISE_SENT = -37818090;

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
integer IC_CHANGE = 1022;

// Cursor commands
integer CUR_SCAN = -771038110;
integer CUR_RESULTS = -771038111;

// Environment commands
integer ENV_SET_VALUE = -79301901;
integer ENV_STORE_VALUE = -79301902;

// Automatic Object Creation (AOC) messages - for scripts to be able to create ML objects
integer AOC_CREATE = 101442800;

// HUD server commands
integer HUD_API_LOGOUT = -47206001;

// HUD attachment constants
string HUDA_CAMERA_SET = "cset";
string HUDA_JUMP_SET = "jset";
string HUDA_TELEPORT = "tele";
list HUDAttachPoints = [
	ATTACH_HUD_BOTTOM,
	ATTACH_HUD_BOTTOM_LEFT,
	ATTACH_HUD_BOTTOM_RIGHT,
	ATTACH_HUD_CENTER_1,
	ATTACH_HUD_CENTER_2,
	ATTACH_HUD_TOP_CENTER,
	ATTACH_HUD_TOP_LEFT,
	ATTACH_HUD_TOP_RIGHT ];

// Modules data rec'd from Cataloguer
list ModulesList;
integer MOD_LIB_KEY = 0;
integer MOD_NAME = 1;
//integer MOD_STRIDE = 2;

// ObjectsStatic - objects' data needed at all times
list ObjectsStatic;
integer OBS_NAME = 0;
integer OBS_REFERENCE = 1;
integer OBS_CAMERA_POS = 2;
integer OBS_CAMERA_ALT_POS = 3;
integer OBS_CAMERA_FOCUS = 4;
integer OBS_JUMP_POS = 5;
integer OBS_JUMP_LOOKAT = 6;
integer OBS_PHANTOM = 7;
integer OBS_AUTOHIDE 		= 8;
integer OBS_STRIDE = 9;
integer ObjectsLibraryCount;	// number of objects in library (static and dynamic have same count when dynamic is loaded)

// ObjectsDynamic - objects' data only required while signed in
list ObjectsDynamic;
integer OBD_REFERENCE		= 0;		// Always first
integer OBD_DETACHED 		= 1;	
integer OBD_SOURCE_B64 		= 2;
integer OBD_SIZEFACTOR 		= 3;
integer OBD_OFFSET_POS	 	= 4;
integer OBD_OFFSET_ROT 		= 5;
integer OBD_SITTABLE		= 6;
integer OBD_DO_ROTATION 	= 7;
integer OBD_DO_BINORMAL 	= 8;
integer OBD_COPY_ROTATION	= 9;
integer OBD_CENTER 		= 10;
integer OBD_ADJUST_HEIGHT	= 11;
integer OBD_DUMMY_MOVE 		= 12;
integer OBD_RESIZABLE 		= 13;
integer OBD_FLOATING 		= 14;
integer OBD_IS_APP 		= 15;
integer OBD_STICKPOINT_B64	= 16;
integer OBD_SNAP_GRID 		= 17;
integer OBD_REGION_SNAP 	= 18;
integer OBD_COMMS_TYPE		= 19;
integer OBD_STRIDE 		= 20;

// Which objects use which modules
list ObjectModules = [];
integer OBM_NAME		= 0;
integer OBM_LIBKEY		= 1;

// List of prim names of autohide objects
list AutoHides = [];

// Selections - record of which prims are currently selected and by whom
// Strided list consisting of [ key <Av ID>, key <object UUID>, integer <inserted time> ]
// Av ID must be unique
list Selections = [];
integer SEL_AVID = 0;        // positions of fields in strided list
integer SEL_OBJECT_ID = 1;    // UUID of object
integer SEL_ICON_ID = 2;	// Icon ID (maps only)
integer SEL_OBD_PTR = 3;	// Pointer to detached objects table or linked objects table (depending on mode)
integer SEL_STRIDE = 4;     // list stride length

// Linked objects (ie app objects)
list LinkedObjects = [];
integer LO_OBJECT_ID = 0;
integer LO_CP_POSITION = 1;        // CP stands for Contact Point, the place on another prim that was clicked to position it
integer LO_CP_NORMAL = 2;
integer LO_CP_BINORMAL = 3;
integer LO_ORIG_SIZE = 4;		// Keep these size elements in this order
integer LO_ACTUAL_SIZE = 5;	//
integer LO_SIZE_FACTOR = 6;	//
integer LO_EXTRA_DATA = 7;
integer LO_STRIDE = 8;

// Detached objects (either Map objects or non-linked app objects)
list DetachedObjects = [];
integer DO_OBJECT_ID = 0;
integer DO_ICON_ID = 1;
integer DO_LIB_PTR = 2;
integer DO_SIZE_FACTOR = 3;
integer DO_EXTRA_DATA = 4;
integer DO_APP_DATA = 5;
integer DO_STRIDE = 6;

// Table of [ UUID, LinkNum ] for all prims
list UuidLinks = [];
integer UuidLinksInvalid = TRUE; // TRUE when the table needs to be updated

list IconsWaiting;	// [ <object basename>, <WO UUID> ]

// List of objects about to be created
list NewObjects = [];
integer NOB_AVID 				= 0;
integer NOB_OBJECTNAME 		= 1;
integer NOB_TYPE 				= 2;
integer NOB_BUTTON 			= 3;        // only used for "create" buttons
integer NOB_POS 				= 4;
integer NOB_ROT 				= 5;
integer NOB_TOUCH_POS			= 6;
integer NOB_TOUCH_FACE			= 7;
integer NOB_TOUCH_ST			= 8;
integer NOB_CP_POS 			= 9;
integer NOB_CP_NORMAL 			= 10;
integer NOB_CP_BINORMAL 		= 11;
integer NOB_PRIM_ID 			= 12;        // only used for "Rearrange"
integer NOB_EXTRA_DATA 		= 13;
integer NOB_ORIG_SIZE 			= 14;
integer NOB_ACTUAL_SIZE 		= 15;
integer NOB_SIZE_FACTOR 		= 16;
integer NOB_TARGET_UUID 		= 17;
integer NOB_STRIDE 			= 18;

integer NOB_TYPE_CREATE_READY = 1;        // Enum values for type
integer NOB_TYPE_CREATE_REZZING = 2;
integer NOB_TYPE_CLONE = 3;
integer NOB_TYPE_GROUP = 4;
integer NOB_TYPE_AOC = 5;

integer ObjectsToLoad;	// a count of the number of objects still to be created when loading from notecard
integer LoadStaticObjectsOnly; // when TRUE, we're only loading static data for objects

key UserId;	// user who is signed in

// A list of UUIDs of prims that have been manually created (ie using the create option
// rather than loading from notecard), which will need to be "awakened" after linking by sending
// them the "loading complete" LM.
list Awakeners;
integer AwakenTicks;    // How long before we inform them

// Reserved Touch Face data. This is a feature whereby a client script can specify that one or more faces
// on its parent prim are not to have touches processed normally, but instead the client script is informed
// of the click so it can process it. Typically used for things like hamburger menus.
list ReservedTouchFaces = [];
//integer RTF_UUID = 0; // memo for reference
//integer RTF_FACE = 1;	
integer RTF_STRIDE = 2;

// Stored rotations data.
// When the user rotates an object, the result is stored here. If the user then creates another object of the
// same name on a surface with the same normal, the stored rotation is used instead of the one calculated by the
// normal/binormal data from the surface.
list StoredRotations = [];
integer STO_USER = 0;
integer STO_OBJECT = 1;
integer STO_NORMAL = 2;
integer STO_ROTATION = 3;
integer STO_STRIDE = 4;

// The Activation Queue is a list of objects that have been created (eg through loading a scene
// via notecard) and which need to be sent messages to tell them that their scripts can start communicating with
// us. We could send a single message to LINK_SET, but that runs the risk of our being swamped by link message events,
// so we process the queue in chunks defined by ACTIVATION_BATCH_SIZE.
// There are similarities here with the Awakeners queue, but that is not for loading from notecard.
// The format of this table is [ UUID, CommsType ]
integer ACTIVATION_BATCH_SIZE = 10;
list ActivationQueue = [];
integer ActivationQueueSize = 0;
integer ACT_STRIDE = 2; // stride length of table

// Number of objects waiting to be unlinked during "clear" process
integer UnlinksToDo = 0;

// Queue of objects (UUIDs) to be linked
list LinksToDo = [];

// Queue of app data loaded from save file, which needs to be sent out to the apps as they load
list SendAppData;	// format: [ ObjectName, Position, AppData ] (detached objects only)

// "Memory" feature retains size factor until change of creation object (ie they click on another object)
string MemorySizeObject;
float MemorySizeFactor;

vector RegionSize;
integer DebugMode = FALSE;
string DebugId = "????";
integer CameraJumpMode;

integer RandomCreate;	// Is randomize switched on?
float RandomResize;
integer RandomRotate;

integer WriteConfig;
list NewConfig;

// Stuff for saving app data within parent app/map save files
key ParentId = NULL_KEY;	// The UUID of our rezzing app/map (important that it's initialised here)
integer ParentInformed = FALSE; // Have we sent the CHILD_READY message already?
string AppBackupSaveName;
integer AppBackupsWaiting;
integer AppBackupsTimeout;
string AppRestoreData;

list ChildQueue = [];	// List of child apps that have sent LM_CHILD_READY but not WO_INITIALISE (yet)
integer WaitingForCataloguer = TRUE;

integer Initialized = FALSE; // Has Initialize() main processing been executed?

integer NextTimeOutCheck;
integer LoadingScene;		// TRUE while a scene is being loaded from notecard
integer LoadingWithParent = FALSE; // TRUE if we're loading a scene on behalf of a parent
integer LoadingCompleteTicks = 0;
integer NextPrimId;        // the next prim id to use (allocated sequentially)
integer ObjectsRezzing;     // counter of the number of library rez calls awaiting replies
integer ObjectsCount;	// number of objects in scene
integer LogoutTicks = 0;
key OwnerId;
key OurUuid;
integer CommsChannelListener;
integer CommandChatListener;
float NudgeDistance; // the current nudge distance (can be changed by user)

// Config file data
string ScoreboardChannel;
string MailboxChannel;
integer CommandChatChannel;
integer AdvancedMenu;
string HideOptions;
string ErrorEmail;
integer ViewOnly;
float DefaultNudgeDistance;
float NudgeFactor;
integer IsMap;				// TRUE if it's a Map
string BoardPrimName;
integer BoardFace;
string CursorPrimName;
vector CursorSize;
float CursorAlpha;
float CursorHeight;	// distance above the object
vector WorldSize;
vector WorldOrigin;
vector RezPosition;
vector BoardOffset;
float ScalingFactor;
vector IconHoverTextColour;
float IconHoverTextAlpha;
float IconSelectGlow;
vector IconSelectParticleColour;
integer Locked;
integer DummyMoveSet;
float LinkedSelectGlow;
integer LinkBatchSize; // size of link batch used during load of scene
integer UnlinkBatchSize; // size of unlink batch used in Clear() processing
integer RezBatchSize; // max size of batch of objects to be rezzed (used by librarian)

// "Public" data
integer EnvironmentalChange;	// if TRUE, user can change the environment
float DefaultSeaLevel;
float DefaultLandLevel;
string CheckboxOn;
string CheckboxOff;
integer TerrainChange;	// if FALSE, user can't alter terrain
vector ModuleSize;
vector ModulePosNormal;
vector ModulePosHidden;
integer MaxAvatars;

// Limits
integer ObjectsLimit;
float SizeLimit;
float DistanceLimit;

// Data for environment stuff
list EnvironmentValues;

integer BoardLinkNum;	// link number of control board
vector BoardPrimPos;
rotation BoardPrimRot;
vector BoardPrimSize;
vector BoardPrimHalfSize;
integer CursorLinkNum;
integer CursorInUse;

// Tidy function
vector TidyPos;
list TidyDone;
integer TidyMoveOn;
integer TidyCount;

// Given touch information, determine local position and rotation
// Uuid is object being positioned
PositionObjectOnFace(
	key AvId,
	string ObjectName,
	key TargetId,
	integer Detached,
	key ObjectId,
	key IconId,
	integer NobPtr,	// pointer to NewObjects where appropriate (otherwise -1)
	vector TouchPos,
	integer TouchFace,
	vector TouchST,
	vector CpPos,
	vector Normal,
	vector Binormal,
	float SizeFactor) {
	if (ObjectName == "") {
		if (IsMap) {
			ObjectName = llKey2Name(ObjectId);
		} else if (!Detached) {
			integer LinkNum = Uuid2LinkNum(ObjectId);
			if (LinkNum == -1) return;
			ObjectName = llGetLinkName(LinkNum);
		}
	}
	rotation SpecifiedRot = ZERO_ROTATION;
	rotation TargetLocalRot = ZERO_ROTATION;
	vector ObjectOffset = ZERO_VECTOR;
	integer DoRotation = TRUE;
	integer DoBinormal = TRUE;
	integer CopyRotation = FALSE;
	rotation StickPointRot = ROT_NAN;
	string BaseName = GetBaseName(ObjectName);
	string ObjectReference = GetObjectReference(BaseName);	// returns "" if no object in table
	if (ObjectReference == "") { LogError("No object in library to position " + ObjectName); return; }
	integer LibPtr = GetDynamicPointer(ObjectReference);	// get pointer to ObjectsDynamic
	if (LibPtr == -1) return; // should never happen
	if (!IsMap && TargetId != NULL_KEY) {
		integer TargetLink = Uuid2LinkNum(TargetId);
		if (TargetLink == -1) return;
		string TargetName = llGetLinkName(TargetLink);
		// Check to see if target object has a snap grid
		string TargetObjectReference = GetObjectReference(TargetName);
		if (TargetObjectReference != "") {	// Target is an object
			integer TargetLibPtr = GetDynamicPointer(TargetObjectReference);
			if (TargetLibPtr == -1) return; // should never happen
			list TargetParams = llGetLinkPrimitiveParams(TargetLink, [ PRIM_POS_LOCAL, PRIM_ROT_LOCAL, PRIM_SIZE ]);
			TargetLocalRot = llList2Rot(TargetParams, 1);
			//
			// StickPoints processing
			//
			string StickPoints64 = llList2String(ObjectsDynamic, TargetLibPtr + OBD_STICKPOINT_B64);
			list SPList = FindStickPoint(TargetId, StickPoints64, TouchPos, TouchST, TouchFace, Normal);	// Returns VEC_NAN if not found
			vector StickPoint = llList2Vector(SPList, 0);
			StickPointRot = llList2Rot(SPList, 1);
			if (StickPoint != VEC_NAN) {
				CpPos = StickPoint;
			}
			//
			// SnapGrid processing
			//
			if (StickPoint == VEC_NAN) {	// No StickPoint, so maybe there's a grid?
				vector SnapGrid = llList2Vector(ObjectsDynamic, TargetLibPtr + OBD_SNAP_GRID);
				if (SnapGrid != ZERO_VECTOR) {
					// The target object has a snap grid
					vector TargetPos = llList2Vector(TargetParams, 0);
					vector TargetSize = llList2Vector(TargetParams, 2);
					// Calculate clicked position relative to target object position and rotation
					vector SnappedClickPos = (CpPos - TargetPos) / TargetLocalRot;
					SnappedClickPos.x = SnapToGrid(SnappedClickPos.x, TargetSize.x, SnapGrid.x);
					SnappedClickPos.y = SnapToGrid(SnappedClickPos.y, TargetSize.y, SnapGrid.y);
					SnappedClickPos.z = SnapToGrid(SnappedClickPos.z, TargetSize.z, SnapGrid.z);
					// Convert click position back into pos/rot relative to root
					CpPos = TargetPos + (SnappedClickPos * TargetLocalRot);
				}
			}
		}
	}
	vector V = llList2Vector(ObjectsDynamic, LibPtr + OBD_OFFSET_POS); if (V != VEC_NAN) ObjectOffset = V;
	V = llList2Vector(ObjectsDynamic, LibPtr + OBD_OFFSET_ROT); if (V != VEC_NAN) SpecifiedRot = llEuler2Rot(V * DEG_TO_RAD);
	DoRotation = llList2Integer(ObjectsDynamic, LibPtr + OBD_DO_ROTATION);
	DoBinormal = llList2Integer(ObjectsDynamic, LibPtr + OBD_DO_BINORMAL);
	CopyRotation = llList2Integer(ObjectsDynamic, LibPtr + OBD_COPY_ROTATION);

	ObjectOffset *= SizeFactor;		// Adjust scale of offset according to changed size

	if (!IsMap) {	
		// If we're (a) ignoring rotation and/or
		// (b) ignoring binormal AND the target surface is (at least nearly) vertical
		// For maps, we do this inside MoveMapObject()
		if (!DoRotation || (!DoBinormal &&	llFabs(Normal.z) < 0.001)) {
			Binormal = <0.0, 0.0, 1.0>;	// set the binormal to vertical
		}
	}
	rotation BasicRot;
	if (!IsMap && !DoRotation)
		BasicRot = ZERO_ROTATION;
	else if (CopyRotation)
		BasicRot = TargetLocalRot;
	else
		BasicRot = llAxes2Rot(Binormal, Normal % Binormal, Normal);
	rotation ObjectRot = InitialRot * SpecifiedRot;
	ObjectRot *= BasicRot;
	vector ObjectPos;
	if (StickPointRot != ROT_NAN) {	// there is a stickpoint rotation, so apply it
		ObjectRot *=  (StickPointRot * TargetLocalRot);
		ObjectPos = CpPos + (ObjectOffset * BasicRot * StickPointRot * TargetLocalRot);
		ClearStoredRotation(AvId); // stored rotations don't work well with stickpoint rotations
	}
	else {	// no stickpoint rotation
		ObjectPos = CpPos + ObjectOffset * BasicRot;
	}
	if (DistanceExceeded(ObjectPos, TRUE)) return;
	// If there's a stored rotation for this object, use that instead
	integer S = llListFindList(StoredRotations, [ AvId, ObjectName ]);
	if (S > -1) {
		// Find the normal that applied to the previous instance of the object
		vector PreviousNormal = llList2Vector(StoredRotations, S + STO_NORMAL);
		if (llVecDist(PreviousNormal, Normal) < 0.01) {	// if this surface has the same normal (to within about 0.5°), we apply the stored rotation
			rotation PreviousRot = llList2Rot(StoredRotations, S + STO_ROTATION);
			if (ObjectRot != PreviousRot) {
				DoRotation = TRUE;	// if the rotations differ, we must change it
				ObjectRot = PreviousRot;
			}
		}
	}
	else {
		ClearStoredRotation(AvId);	// we might as well clear this now, since it can never be relevant
	}
	vector RegionSnap = llList2Vector(ObjectsDynamic, LibPtr + OBD_REGION_SNAP);
	if (IsMap) {
		string Ext = llGetSubString(ObjectName, -1, -1);
		if (Ext == "W") {
			vector WorldPos = BoardPos2WorldPos(TouchPos);
			integer Center = llList2Integer(ObjectsDynamic, LibPtr + OBD_CENTER);
			if (Center) WorldPos = WorldOrigin + WorldSize * 0.5;
			WorldPos += ObjectOffset * IconRot2WorldRot(BasicRot);
			integer DetPtr = llListFindList(DetachedObjects, [ ObjectId ]);
			if (DetPtr == -1) { LogError("Can't find map object for positioning"); return; }
			DetPtr -= DO_OBJECT_ID;
			if (RegionSnap != ZERO_VECTOR) {	// Snap to region grid
				WorldPos.x = SnapToRegionGrid(WorldPos.x, RegionSnap.x, WorldOrigin.x, WorldSize.x);
				WorldPos.y = SnapToRegionGrid(WorldPos.y, RegionSnap.y, WorldOrigin.y, WorldSize.y);
			}
			MoveMapObject(ObjectName, DetPtr, ObjectId, IconId, WorldPos, ObjectRot, Normal);
		}
	}
	else if (Detached) {
		// Convert local position to world position
		ObjectPos = llGetPos() + (ObjectPos * llGetRot());
		integer Center = llList2Integer(ObjectsDynamic, LibPtr + OBD_CENTER);
		if (Center) {
			ObjectPos = WorldOrigin + WorldSize * 0.5;
		}
		else if (RegionSnap != ZERO_VECTOR) {	// Snap to region grid		
			ObjectPos.x = SnapToRegionGrid(ObjectPos.x, RegionSnap.x, WorldOrigin.x, WorldSize.x);
			ObjectPos.y = SnapToRegionGrid(ObjectPos.y, RegionSnap.y, WorldOrigin.y, WorldSize.y);
		}				
		MessageStandard(ObjectId, WO_MOVE_ROTATE, [ ObjectPos, ObjectRot ]);
	}
	else {	// Linked object in App
		integer Center = llList2Integer(ObjectsDynamic, LibPtr + OBD_CENTER);
		if (Center) {
			ObjectPos = WorldOrigin + WorldSize * 0.5;
			ObjectPos = RegionPos2LocalPos(ObjectPos);				
		}
		else if (RegionSnap != ZERO_VECTOR) {	// Snap to region grid
			ObjectPos = LocalPos2RegionPos(ObjectPos);
			ObjectPos.x = SnapToRegionGrid(ObjectPos.x, RegionSnap.x, WorldOrigin.x, WorldSize.x);
			ObjectPos.y = SnapToRegionGrid(ObjectPos.y, RegionSnap.y, WorldOrigin.y, WorldSize.y);
			ObjectPos = RegionPos2LocalPos(ObjectPos);
		}
		MovePrim(ObjectId, ObjectPos, ObjectRot, TRUE);
		// Now we write the new contact point data to the appropriate table. During the create process,
		// this will be NewObjects, otherwise it will be LinkedObjects.
		if (NobPtr > -1) {	// If we've been passed a valid pointer, we need to modify NewObjects
			NewObjects = llListReplaceList(NewObjects, [ CpPos, Normal, Binormal ], NobPtr + NOB_CP_POS, NobPtr + NOB_CP_BINORMAL);
		}
		else {	// No NewObjects pointer, so presumably it's an existing object
			integer D = llListFindList(LinkedObjects, [ ObjectId ]);
			if (D == -1) { LogError("Can't find LO entry to update CP pos"); return; }
			D -= LO_OBJECT_ID;
			LinkedObjects = llListReplaceList(LinkedObjects, [ CpPos, Normal, Binormal ], D + LO_CP_POSITION, D + LO_CP_BINORMAL);
		}
	}
}
// Looks for a StickPoint based on click position and face number
// Returns [ position, rotation ]
list FindStickPoint(key TargetId, string StickPoints64, vector TouchPos, vector TouchST, integer TouchFace, vector Normal) {
	if (StickPoints64 == "") return [ VEC_NAN, ROT_NAN ];
	integer TargetLink = Uuid2LinkNum(TargetId);
	if (TargetLink == -1) return [ VEC_NAN, ROT_NAN ];
	rotation StickRot = ROT_NAN;	
	// Get region position and rotation
	list L = llGetLinkPrimitiveParams(TargetLink, [ PRIM_POSITION, PRIM_ROTATION ]);
	vector TargetPos = llList2Vector(L, 0);
	rotation TargetRot = llList2Rot(L, 1);
	// Find size factor of target
	integer LoPtr = llListFindList(LinkedObjects, [ TargetId ]);
	if (LoPtr == -1) return [ VEC_NAN, ROT_NAN ];	// Not a linked object, so no StickPoint
	LoPtr -= LO_OBJECT_ID;
	float TargetSizeFactor = llList2Float(LinkedObjects, LoPtr + LO_SIZE_FACTOR);
	// Unpack Stickpoints into lines
	string StickPointsRaw = llBase64ToString(StickPoints64);
	list StickPointLines = llParseStringKeepNulls(StickPointsRaw, [ "|" ], []);
	integer StickPointLinesCount = llGetListLength(StickPointLines);
	// Find lines for the face that was clicked
	vector NearestPos = VEC_NAN;
	float NearestDistance = 9999999.0;	// high value
	integer LineNum;
	for (LineNum = 0; LineNum < StickPointLinesCount; LineNum++) {
		string Line = llList2String(StickPointLines, LineNum);
		// Format of line is "<face>: <local position>[;<local rotation>]"
		L = llParseStringKeepNulls(Line, [ ":" ], []);
		integer Face = (integer)llList2String(L, 0);
		if (Face == TouchFace) {	// if it's for this face
			string RHS = llList2String(L, 1);
			vector StickLocal;
			rotation ThisStickRot = ROT_NAN;
			// Separate position and rotation (if any)
			if (llSubStringIndex(RHS, ";") > -1) {	// if there is a rotation component
				list Parts = llParseStringKeepNulls(RHS, [ ";" ], []);
				StickLocal = (vector)llList2String(Parts, 0);
				ThisStickRot = llEuler2Rot((vector)llList2String(Parts, 1) * DEG_TO_RAD);
			}
			else {
				StickLocal = (vector)RHS;
			}
			// Find region position of StickPoint
			StickLocal *= TargetSizeFactor;	// incorporate any resizing
			vector StickRegion = TargetPos + (StickLocal * TargetRot);
			// Looking for the closest
			float Distance = llVecDist(StickRegion, TouchPos);
			if (Distance < NearestDistance) {
				NearestDistance = Distance;
				NearestPos = StickRegion;
				StickRot = ThisStickRot;
			}
		}
	}
	vector StickPoint = VEC_NAN;
	if (NearestPos != VEC_NAN) {
		StickPoint = RegionPos2LocalPos(NearestPos);
	}
	return [ StickPoint, StickRot ];
}
float SnapToGrid(float ClickedPos, float TargetSize, float GridDivisions) {
	float SnappedPos = ClickedPos;
	if (GridDivisions > 0.0) {
		float NearestDistance = 99999.0;
		float GridSize = TargetSize / GridDivisions;
		float LinePos;
		float From = -(GridDivisions / 2.0) * GridSize;
		float To = (GridDivisions / 2.0) * GridSize + 0.001;	// See below
		for (LinePos = From; LinePos <= To; LinePos += GridSize) {
			float Distance = llFabs(ClickedPos - LinePos);
			if (Distance < NearestDistance) {
				NearestDistance = Distance;
				SnappedPos = LinePos;
			}
		}
	}
	return SnappedPos;
	// (Below)The 0.001 is a hack to work round situations whereby float inaccuracies caused the loop
	// to terminate on what should have been the penultimate pass, causing some placements to be one
	// division from the end instead of at the end
}
float SnapToRegionGrid(float ClickedPos, float GridSize, float WorldOriginAxis, float WorldOriginSize) {
	float SnappedPos = ClickedPos;
	if (GridSize > 0.0) {
		float NearestDistance = 99999.0;
		float LinePos;
		float To = WorldOriginAxis + WorldOriginSize - GridSize + 0.001;
		for (LinePos = WorldOriginAxis + GridSize; LinePos <= To; LinePos += GridSize) {
			float Distance = llFabs(ClickedPos - LinePos);
			if (Distance < NearestDistance) {
				NearestDistance = Distance;
				SnappedPos = LinePos;
			}
		}
	}
	return SnappedPos;
}
// Clone an object (initial processing)
Clone(key AvId) {
	integer SelPtr = llListFindList(Selections, [ AvId ]);
	if (SelPtr == -1) {
		Message(AvId, "Select an object first, then you can clone it");
		return;
	}
	SelPtr -= SEL_AVID;
	string ObjectName;
	string RezObjectName;
	string NewObjectsName;
	vector CpPos = VEC_NAN;
	vector CpNormal = VEC_NAN;
	vector CpBinormal = VEC_NAN;
	vector OriginalSize = VEC_NAN;
	vector ActualSize = VEC_NAN;
	float SizeFactor = 1.0;
	string ExtraData = "";
	vector Pos = ZERO_VECTOR;
	rotation Rot = ZERO_ROTATION;
	integer IsApp = FALSE;
	string AppData = "";
	if (IsMap) {
		key ObjectId = llList2Key(Selections, SelPtr + SEL_OBJECT_ID);
		list ObjectDetails = llGetObjectDetails(ObjectId, [ OBJECT_NAME, OBJECT_POS, OBJECT_ROT ]);
		ObjectName = llList2String(ObjectDetails, 0);
		Pos = llList2Vector(ObjectDetails, 1);
		Rot = llList2Rot(ObjectDetails, 2);
		string BaseName = GetBaseName(ObjectName);
		integer DetPtr = llList2Integer(Selections, SelPtr + SEL_OBD_PTR);
		SizeFactor = llList2Float(DetachedObjects, DetPtr + DO_SIZE_FACTOR);
		// Extra data not used in Maps
		if (IsMap) {
			IsApp = IsObjectAnAppByName(ObjectName);
			AppData = llList2String(DetachedObjects, DetPtr + DO_APP_DATA);
		}
		NewObjectsName = BaseName;
		RezObjectName = BaseName + "I";    // We rez the icon first
	}
	else {
		key SelectedUuid = llList2Key(Selections, SelPtr + SEL_OBJECT_ID);
		if (SelectedUuid == NULL_KEY) {
			LogError("Can't find selection to clone");
			return;
		}
		integer SelectedLinkNum = Uuid2LinkNum(SelectedUuid);
		if (SelectedLinkNum == -1) return;
		
		ObjectName = llGetLinkName(SelectedLinkNum);
		if (llListFindList(ObjectsStatic, [ ObjectName ]) == -1) {
			Message(AvId, "Can't clone this object");
			return;
		}
		// Find pos and rot of the original prim
		list Params = llGetLinkPrimitiveParams(SelectedLinkNum, [ PRIM_POS_LOCAL, PRIM_ROT_LOCAL ]);
		Pos = llList2Vector(Params, 0);
		Rot = llList2Rot(Params, 1);
		// Find additional data for original
		integer D = llListFindList(LinkedObjects, [ SelectedUuid ]);
		if (D > -1) {
			D -= LO_OBJECT_ID;
			CpPos = llList2Vector(LinkedObjects, D + LO_CP_POSITION);;
			CpNormal = llList2Vector(LinkedObjects, D + LO_CP_NORMAL);
			CpBinormal = llList2Vector(LinkedObjects, D + LO_CP_BINORMAL);
			OriginalSize = llList2Vector(LinkedObjects, D + LO_ORIG_SIZE);
			ActualSize = llList2Vector(LinkedObjects, D + LO_ACTUAL_SIZE);
			SizeFactor = llList2Float(LinkedObjects, D + LO_SIZE_FACTOR);
			ExtraData = llList2String(LinkedObjects, D + LO_EXTRA_DATA);
		}
		NewObjectsName = RezObjectName = ObjectName;
	}
	// Calculate position for clone
	Pos += CloneOffset() / llGetRot();     // calculate position above original prim
	NewObjects += [ AvId, NewObjectsName, NOB_TYPE_CLONE, NULL_KEY, 
		Pos, Rot, 
		VEC_NAN, -1, VEC_NAN, 
		CpPos, CpNormal, CpBinormal, 
		0, ExtraData, 
		OriginalSize, ActualSize, SizeFactor, 
		NULL_KEY ];
	RezObjects([ RezObjectName ]);    // Trigger creation of object
}
// Automatic object creation
AocCreate(key AvId, string Data) {
	list Elements = llParseStringKeepNulls(Data, [ "|" ], []);
	string ObjectName = llList2String(Elements, 0);
	vector PrimPos = (vector)llList2String(Elements, 1);
	rotation PrimRot = (rotation)llList2String(Elements, 2);
	string ExtraData = llList2String(Elements, 3);
	integer NewPrimId = 0;    // this gets allocated later
	vector OriginalSize = VEC_NAN;	// we don't know this yet
	vector ActualSize = VEC_NAN;	// nor this
	integer LibPtr = llListFindList(ObjectsStatic, [ ObjectName ]);
	if (LibPtr == -1) {
		LogError("Unknown object in AOC request: '" + ObjectName + "'");
		return;
	}
	NewObjects += [ AvId, ObjectName, NOB_TYPE_AOC, NULL_KEY,
		PrimPos, PrimRot,
		VEC_NAN, -1, VEC_NAN,
		VEC_NAN, VEC_NAN, VEC_NAN,
		NewPrimId, ExtraData, 
		OriginalSize, ActualSize, 1.0, NULL_KEY ];
	RezObjects([ ObjectName ]);    // Trigger creation of object
}
// Creates an object (initial processing)
CreateStart(key AvId, string ObjectName, key TargetUuid, key ButtonId) {
	if (!UpdateObjectsCountStatus()) return;
	DeselectByAvId(AvId);        // deselect any prim they might currently have selected
	if (ButtonId != NULL_KEY) {    // if they've clicked a button to get here
		Sound(SOUND_PICK);
		integer ButtonLinkNum = Uuid2LinkNum(ButtonId);
		if (ButtonLinkNum == -1) return;
		PrimGlow(ButtonLinkNum, TRUE);
	}
	// for now, pos and rot are zero. We'll get those when they click (in CreatePosition())
	NewObjects += [
		AvId,
		ObjectName,
		NOB_TYPE_CREATE_READY,
		ButtonId,
		ZERO_VECTOR,		// Pos
		ZERO_ROTATION,		// Rot
		VEC_NAN,			// Touch pos
		-1,					// Touch face
		VEC_NAN,			// Touch ST
		ZERO_VECTOR,		// CP Pos
		ZERO_VECTOR,		// CP Normal
		ZERO_VECTOR,		// CP Binormal
		0,					// Internal ID
		"",					// Extra data
		VEC_NAN, 		// Original size
		VEC_NAN,		// Actual size
		1.0,				// Size factor
		TargetUuid			// Uuid of prim clicked to position
			];        // create entry in creators table
}
// Get the position for the object we're about to create (based on click on target prim)
// and rez the object
CreatePosition(integer CreatePtr, key TargetUuid, vector TouchPos, integer TouchFace, vector TouchST, vector CpPos, vector CpNormal, vector CpBinormal) {
	// We're going a bit low-level into the table structure here
	// It's OK as long as TouchPos, TouchFace, CpPos, CpNormal and CPBinormal are adjacent in that sequence
	NewObjects = llListReplaceList(NewObjects, [ NOB_TYPE_CREATE_REZZING ], CreatePtr + NOB_TYPE, CreatePtr + NOB_TYPE);    // update type of record
	NewObjects = llListReplaceList(NewObjects, [ TouchPos, TouchFace, TouchST, CpPos, CpNormal, CpBinormal ], CreatePtr + NOB_TOUCH_POS, CreatePtr + NOB_CP_BINORMAL);
	NewObjects = llListReplaceList(NewObjects, [ TouchPos, TouchFace, TouchST, CpPos, CpNormal, CpBinormal ], CreatePtr + NOB_TOUCH_POS, CreatePtr + NOB_CP_BINORMAL);
	NewObjects = llListReplaceList(NewObjects, [ TargetUuid ], CreatePtr + NOB_TARGET_UUID, CreatePtr + NOB_TARGET_UUID);
	string ObjectName = llList2String(NewObjects, CreatePtr + NOB_OBJECTNAME);
	if (IsMap) {
		RezObjects([ ObjectName + "I" ]);	// we create the icon, first, and then the world object when the icon arrives
	}
	else {
		RezObjects([ ObjectName ]);
	}
}
// Create an object
RezObjects(list ObjectNames) {
	integer ObjectsLength = llGetListLength(ObjectNames);
	ObjectsRezzing += ObjectsLength;
	// Check we're not about to exceed objects count limit
	if (!UpdateObjectsCountStatus()) {
		while (ObjectsLength-- > 0) {
			DeleteFromNewObjects(llList2String(ObjectNames, ObjectsLength)); // Delete from NewObjects so other functions aren't waiting for it to appear
		}
		return;
	}
	// We have a list of object names, with possibly duplicates. We need to convert that into a list of unique
	// object names, each with a count of the number of occurrences in the first list.
	if (ObjectNames == []) return; // probably should never happen
	// First, sort the list so that duplicates are together
	ObjectNames = llListSort(ObjectNames, 1, TRUE);
	
	// Set up our output list
	list RezCommands = []; // [ ObjectName, Quantity ]

	// Loop through objects, adding to output list
	integer I;
	string SavedObject = llList2String(ObjectNames, 0);;
	integer Count = 0;
	for (I = 0; I < ObjectsLength; I++) {
		string ObjectName = llList2String(ObjectNames, I);
		// Validation of this object name
		string BaseName = GetBaseName(ObjectName);
		integer O = llListFindList(ObjectsStatic, [ BaseName ]);
		if (O == -1) {
			LogError("Object not in libraries: '" + BaseName + "'");
			NewObjects = [];	// so other functions aren't waiting for objects to appear
			return;
		}
		// Now the counting part
		if (ObjectName == SavedObject) {
			Count++;
		}
		else {
			RezCommands += [ SavedObject, (string)Count ];
			Count = 1;
			SavedObject = ObjectName;
		}
	}
	RezCommands += [ SavedObject, (string)Count ];
	integer RezCommandsLength  = llGetListLength(RezCommands);
	for (I = 0; I < RezCommandsLength; I += 2) {
		// The command we send to the libraries has data: "<ObjectName>|<Count>"
		string RezString = llList2String(RezCommands, I) + "|" + (string)llList2Integer(RezCommands, I + 1);
		llMessageLinked(LINK_SET, LIB_REZ_OBJECTS, RezString, NULL_KEY);
	}
	// We have to stop here because we need the return message to pick up the prim UUID. Then we need to
	// use the prim name in the creators list to identify whose prim it is. A great example of when event logic
	// can be a pain, or alternatively when the lack of dynamic event handlers is a shortcoming in LSL.
}
// We call this when:
// (a) WO: we get WO_INITIALISE from a detached object (via the librarian) 
//   OR
// (b) ML: we get LM_CHILD_READY from the child app's ML.
// These two calls can be in either sequence - it's asynch. If the object is not an app, we will
// only get message (a). 
MessageFromChild(integer FromWo, key ChildId) {
	if (DebugMode) Debug("Message from child [" + (string)FromWo + "] " + llKey2Name(ChildId));
	integer DoPtr = llListFindList(DetachedObjects, [ ChildId ]);
	integer ReadyToSendData = FALSE;
	if (FromWo) {	 // if the message is from the WO script
		CreateContinue(ChildId); // So log its arrival (and add to DetachedObjects)
		DoPtr = llListFindList(DetachedObjects, [ ChildId ]); // we now have a DO entry, so pick it up
		integer Q = llListFindList(ChildQueue, [ ChildId ]); // Is the child in the queue?
		if (Q > -1) { // Yes, it is
			ChildQueue = llDeleteSubList(ChildQueue, Q, Q); // remove from queue
			ReadyToSendData = TRUE;
		}
	} else {// it's from the child ML
		if (DoPtr == -1) { // The WO message hasn't arrived yet
			ChildQueue += ChildId; // So add the child to the queue.
		}
		else {	// we had WO, now we've got ML
			ReadyToSendData = TRUE;
		}
	}
	if (ReadyToSendData) {
		if (DoPtr == -1) { LogError("Can't find DO from child messages"); return; } // just in case
		DoPtr -= DO_OBJECT_ID;	// position at start of stride
		// So if there is stored data for this child, we send it
		string AppData = llList2String(DetachedObjects, DoPtr + DO_APP_DATA);
		if (AppData != "") {
			if (DebugMode) Debug("Sending " + (string)llStringLength(AppData) + " bytes of data to child");
			MessageStandard(ChildId, LM_APP_RESTORE, [ AppData ]);
		}	
	}
}
// Create an object (continuation after prim is rezzed). This may be after a "create" or a "clone".
CreateContinue(key ObjectId) {
	string ObjectName = llList2String(llGetObjectDetails(ObjectId, [ OBJECT_NAME ]), 0);    // get its name
	string BaseName = GetBaseName(ObjectName);
	string ObjectReference = GetObjectReference(BaseName);
	if (ObjectReference == "") {
		LogError("Can't continue with object creation for: '" + ObjectName + "'");
		return;
	}
	if (ObjectsDynamic == []) {
		LogError("Can't continue with creation - no dynamic objects entries");
		return;
	}
	integer StaticLibPtr = llListFindList(ObjectsStatic, [ BaseName ]);
	integer DynamicLibPtr = GetDynamicPointer(ObjectReference);
	if (StaticLibPtr == -1 || DynamicLibPtr == -1) { // should never happen
		LogError("Invalid pointer(s): " + (string)StaticLibPtr + "/" + (string)DynamicLibPtr);
		return;
	}
	integer Detached = llList2Integer(ObjectsDynamic, DynamicLibPtr + OBD_DETACHED);

	ObjectsRezzing--;

	integer NobPtr = FindNewObject(NULL_KEY, BaseName, NOB_TYPE_CREATE_REZZING);
	if (NobPtr == -1) NobPtr = FindNewObject(NULL_KEY, BaseName, NOB_TYPE_CLONE);
	if (NobPtr == -1) NobPtr = FindNewObject(NULL_KEY, BaseName, NOB_TYPE_GROUP);
	if (NobPtr == -1) NobPtr = FindNewObject(NULL_KEY, BaseName, NOB_TYPE_AOC);
	if (NobPtr == -1) {
		LogError("CreateContinue: can't find NewObjects entry for '" + BaseName  + "'");
		return;
	}
	key AvId = llList2Key(NewObjects, NobPtr + NOB_AVID);
	integer CType = llList2Integer(NewObjects, NobPtr + NOB_TYPE);
	integer PrimId = llList2Integer(NewObjects, NobPtr + NOB_PRIM_ID);
	vector Pos = llList2Vector(NewObjects, NobPtr + NOB_POS);
	rotation Rot = llList2Rot(NewObjects, NobPtr + NOB_ROT);
	string ExtraData = llList2String(NewObjects, NobPtr + NOB_EXTRA_DATA);
	vector OriginalSize = llList2Vector(NewObjects, NobPtr + NOB_ORIG_SIZE);
	vector ActualSize = llList2Vector(NewObjects, NobPtr + NOB_ACTUAL_SIZE);	
	vector TouchPos = llList2Vector(NewObjects, NobPtr + NOB_TOUCH_POS);
	integer TouchFace = llList2Integer(NewObjects, NobPtr + NOB_TOUCH_FACE);
	vector TouchST = llList2Vector(NewObjects, NobPtr + NOB_TOUCH_ST);
	vector CpPos = llList2Vector(NewObjects, NobPtr + NOB_CP_POS);;
	vector CpNormal = llList2Vector(NewObjects, NobPtr + NOB_CP_NORMAL);
	vector CpBinormal = llList2Vector(NewObjects, NobPtr + NOB_CP_BINORMAL);
	float SizeFactor = llList2Float(NewObjects, NobPtr + NOB_SIZE_FACTOR);
	key TargetUuid = llList2Key(NewObjects, NobPtr + NOB_TARGET_UUID);

	if (CType == NOB_TYPE_CREATE_REZZING || CType == NOB_TYPE_AOC) {
		SizeFactor = llList2Float(ObjectsDynamic, DynamicLibPtr + OBD_SIZEFACTOR);
	}
	if (IsMap) {
		CreateContMap(
			NobPtr,
			StaticLibPtr,
			DynamicLibPtr,
			ObjectId,
			ObjectName,
			TargetUuid,
			AvId,
			Pos,
			Rot,
			CType,
			ExtraData,
			TouchPos,
			TouchFace,
			TouchST,
			CpPos,
			CpNormal,
			CpBinormal,
			SizeFactor
				);
	}
	else {
		if (Detached) {
			CreateContDetached(
				NobPtr,
				StaticLibPtr,
				DynamicLibPtr,
				ObjectId,
				ObjectName,
				TargetUuid,
				AvId,
				Pos,
				Rot,
				CType,
				ExtraData,
				TouchPos,
				TouchFace,
				TouchST,
				CpPos,
				CpNormal,
				CpBinormal,
				SizeFactor
					);
		}
		else {
			CreateContLinked(
				NobPtr,
				StaticLibPtr,
				DynamicLibPtr,
				ObjectId,
				ObjectName,
				TargetUuid,
				AvId,
				CType,
				PrimId,
				ExtraData,
				OriginalSize,
				ActualSize,
				TouchPos,
				TouchFace,
				TouchST,
				CpPos,
				CpNormal,
				CpBinormal,
				SizeFactor
					);
		}
	}
	UpdateObjectsCountStatus();
}
CreateContMap(
	integer NobPtr,
	integer StaticLibPtr,
	integer DynamicLibPtr,
	key ObjectId,
	string ObjectName,
	key TargetUuid,
	key AvId,
	vector Pos,
	rotation Rot,
	integer CType,
	string ExtraData,
	vector TouchPos,
	integer TouchFace,
	vector TouchST,
	vector CpPos,
	vector CpNormal,
	vector CpBinormal,
	float SizeFactor) {
		// Remember, icon is created first, then this routine creates the WO
		// Set up a few variables for later
		string BaseName = GetBaseName(ObjectName);
		string Ext = llGetSubString(ObjectName, -1, -1);
		key WoUuid = NULL_KEY;
		key IconUuid = NULL_KEY;
		integer IsIcon;
		if (Ext == "W") {
			WoUuid = ObjectId;
			IsIcon = FALSE;
		}
		else if (Ext == "I") {
			IconUuid = ObjectId;
			IsIcon = TRUE;
		}
		else {
			LogError("Unknown map object: " + ObjectName);
			return;
		}
		integer IsWo = !IsIcon;
		// If it's a WO, it needs to find the UUID of its associated icon.
		// Note that it doesn't matter if there is more than one potential match - they're all instances of the same icon anyway
		if (IsWo) {
			// Pick up data from objects library
			integer IsApp = llList2Integer(ObjectsDynamic, DynamicLibPtr + OBD_IS_APP);
			// Relate WO back to its icon
			integer P = llListFindList(IconsWaiting, [ BaseName ]);
			if (P == -1) { LogError("Can't find waiting icon for " + BaseName); return; }
			IconUuid = llList2Key(IconsWaiting, P + 1);
			IconsWaiting = llDeleteSubList(IconsWaiting, P, P + 1);
			string AppData = "";
			if (IsApp) {
				// Format of SendAppData is name, position, data
				integer S = llListFindList(SendAppData, [ BaseName, Pos ]);
				if (S > -1) {
					AppData = llList2String(SendAppData, S + 2);
					SendAppData = llDeleteSubList(SendAppData, S, S + 2);
				}
			}
			DetachedObjects += [ WoUuid, IconUuid, DynamicLibPtr, SizeFactor, ExtraData, AppData ];
			ObjectsCount++;

			integer AdjustHeight = llList2Integer(ObjectsDynamic, DynamicLibPtr + OBD_ADJUST_HEIGHT);
			MessageStandard(ObjectId, WO_INITIALISE, [ ZERO_VECTOR, 0.0, AdjustHeight, IconUuid, ExtraData, "" ]);

		}
		if (CType == NOB_TYPE_CLONE || CType == NOB_TYPE_GROUP || CType == NOB_TYPE_AOC) {    // groups, clones and AOC are similar at this juncture
			if (IsWo) {
				NewObjects = llDeleteSubList(NewObjects, NobPtr, NobPtr + NOB_STRIDE - 1);    // remove from NewObjects list
				MoveIconOnly(IconUuid, Pos, Rot);
				MoveWorldObjectOnly(ObjectId, Pos, Rot);
				if (NewObjects == []) {
					FinishNewObjects();
				}
			}
		}
		else if (CType == NOB_TYPE_CREATE_REZZING) {
			if (IsWo) {
				NewObjects = llListReplaceList(NewObjects, [ NOB_TYPE_CREATE_READY ], NobPtr + NOB_TYPE, NobPtr + NOB_TYPE);    // update type of record
				PositionObjectOnFace(AvId, ObjectName, TargetUuid, TRUE, WoUuid, IconUuid, NobPtr, TouchPos, TouchFace, TouchST, CpPos, CpNormal, CpBinormal, SizeFactor) ;
				if (MemorySizeObject == ObjectName) SizeFactor = MemorySizeFactor;
				if (RandomCreate && RandomResize != 0.0) {
					SizeFactor =  RandomResizeFactor();
					MemorySizeObject = "";    // break the chain of same-named objects
				}
				NewObjects = llListReplaceList(NewObjects, [ SizeFactor ], NobPtr + NOB_SIZE_FACTOR, NobPtr + NOB_SIZE_FACTOR);
				if (RandomCreate && RandomRotate) {
					float Degrees = llFrand(360.0);
					rotation ObjectRot = llList2Rot(llGetObjectDetails(WoUuid, [ OBJECT_ROT ]), 0);
					rotation AddRot = llEuler2Rot(<0.0, 0.0, Degrees> * DEG_TO_RAD);
					rotation NewWorldRot = AddRot * ObjectRot;
					rotation NewIconRot = WorldRot2IconRot(NewWorldRot);
					MessageStandard(IconUuid, IC_ROTATE, [ NewIconRot ]);
					MessageStandard(WoUuid, WO_ROTATE, [ NewWorldRot ]);
				}
			}
		}
		// Handle stuff to do when the object and icon are rezzed
		if (IsWo) {
			if (SizeFactor != 1.0) {
				MessageStandard(IconUuid, IC_RESIZE, [ SizeFactor ]);
				MessageStandard(WoUuid, WO_RESIZE, [ SizeFactor ]);
			}
		}
		// if this is the icon, we need to trigger the creation of the world object
		if (IsIcon) {
			IconsWaiting += [ BaseName, ObjectId ];	// record the fact that we have an orphan icon
			RezObjects([ BaseName + "W" ]);	// Now create the world object
		}
		if (IsWo && CType == NOB_TYPE_CLONE) {
			SelectObject(AvId, IconUuid);    // select new object (clone only)
		}
	}
CreateContDetached(
	integer NobPtr,
	integer StaticLibPtr,
	integer DynamicLibPtr,
	key ObjectId,
	string ObjectName,
	key TargetUuid,
	key AvId,
	vector Pos,
	rotation Rot,
	integer CType,
	string ExtraData,
	vector TouchPos,
	integer TouchFace,
	vector TouchST,
	vector CpPos,
	vector CpNormal,
	vector CpBinormal,
	float SizeFactor) {
		if (CType == NOB_TYPE_CLONE || CType == NOB_TYPE_GROUP || CType == NOB_TYPE_AOC) {    // groups, clones and AOC are similar at this juncture
			MessageStandard(ObjectId, WO_MOVE_ROTATE, [ Pos, Rot ]);
			NewObjects = llDeleteSubList(NewObjects, NobPtr, NobPtr + NOB_STRIDE - 1);    // remove from NewObjects list
			if (NewObjects == []) {
				FinishNewObjects();
			}
		}
		else if (CType == NOB_TYPE_CREATE_REZZING) {
			PositionObjectOnFace(AvId, ObjectName, TargetUuid, TRUE, ObjectId, NULL_KEY, NobPtr, TouchPos, TouchFace, TouchST, CpPos, CpNormal, CpBinormal, SizeFactor) ;
			NewObjects = llListReplaceList(NewObjects, [ NOB_TYPE_CREATE_READY ], NobPtr + NOB_TYPE, NobPtr + NOB_TYPE);    // update type of record
			// TODO: random rot/size
		}
		// size factor
		if (SizeFactor != 1.0) {
			MessageStandard(ObjectId, WO_RESIZE, [ SizeFactor ]);
		}
		string AppData = "";
		integer IsApp = llList2Integer(ObjectsDynamic, DynamicLibPtr + OBD_IS_APP);
		if (IsApp) {
			// Format of SendAppData is name, position, data
			integer S = llListFindList(SendAppData, [ ObjectName, Pos ]);
			if (S > -1) {
				AppData = llList2String(SendAppData, S + 2);
				SendAppData = llDeleteSubList(SendAppData, S, S + 2);
			}
		}		
		DetachedObjects += [ ObjectId, NULL_KEY, DynamicLibPtr, SizeFactor, ExtraData, AppData ];
		ObjectsCount++;
	}
CreateContLinked(
	integer NobPtr,
	integer StaticLibPtr,
	integer DynamicLibPtr,
	key ObjectId,
	string ObjectName,
	key TargetUuid,
	key AvId,
	integer CType,
	integer PrimId,
	string ExtraData,
	vector OriginalSize,
	vector ActualSize,
	vector TouchPos,
	integer TouchFace,
	vector TouchST,
	vector CpPos,
	vector CpNormal,
	vector CpBinormal,
	float SizeFactor) {
		// First, link the prim into our linkset as a child
		osForceCreateLink(ObjectId, TRUE);
		UuidLinksInvalid = TRUE;
		SetTimer();
		integer NewLinkNum = 2; // The newly-linked prim will have a link number of 2 because that's how SL/OS works
		
		// Now, because our processing has been broken into parts by the event logic, and now all we have to
		// go on is the UUID of the prim that was rezzed, we need to do some detective work to relate this back to
		// the original creators data. In essence, we see what the prim name is and use that to lookup the entry in the
		// NewObjects table.
		list Params = [];
		integer FinishLoad = FALSE;

		// Now we move the prim into position and tidy up.
		if (CType == NOB_TYPE_CLONE || CType == NOB_TYPE_GROUP || CType == NOB_TYPE_AOC) {    // groups, clones and AOC are similar at this juncture
			vector Pos = llList2Vector(NewObjects, NobPtr + NOB_POS);
			rotation Rot = llList2Rot(NewObjects, NobPtr + NOB_ROT);
			MovePrim(ObjectId, Pos, Rot, FALSE);        // move into position
			NewObjects = llDeleteSubList(NewObjects, NobPtr, NobPtr + NOB_STRIDE - 1);    // remove from NewObjects list
			if (NewObjects == []) {
				FinishLoad = TRUE;
			}
			if (CType == NOB_TYPE_CLONE || CType == NOB_TYPE_AOC) {	// groups get a single awaken for the whole linSetPrimId(kset
				Awakeners += ObjectId;    // add this prim into awakeners list
				AwakenTicks = 2;
				SetTimer();
			}
		}
		else if (CType == NOB_TYPE_CREATE_REZZING) {
			PositionObjectOnFace(AvId, ObjectName, TargetUuid, FALSE, ObjectId, NULL_KEY, NobPtr, TouchPos, TouchFace, TouchST, CpPos, CpNormal, CpBinormal, SizeFactor) ;
			NewObjects = llListReplaceList(NewObjects, [ NOB_TYPE_CREATE_READY ], NobPtr + NOB_TYPE, NobPtr + NOB_TYPE);    // update type of record
			// CpPos maybe have changed in PositionObjectOnFace() due to grid-snapping, so read it back
			CpPos = llList2Vector(NewObjects, NobPtr + NOB_CP_POS);
			Awakeners += ObjectId;    // add this prim into awakeners list
			AwakenTicks = 2;
			SetTimer();
		}
		if (OriginalSize == VEC_NAN) {
			OriginalSize = llList2Vector(llGetLinkPrimitiveParams(NewLinkNum, [ PRIM_SIZE ]), 0);
			SizeFactor = llList2Float(ObjectsDynamic, DynamicLibPtr + OBD_SIZEFACTOR);
		}
		if (ActualSize == VEC_NAN) {
			ActualSize = OriginalSize * SizeFactor;
		}
		if (!SizeExceeded(ActualSize)) {
			Params += [ PRIM_SIZE, ActualSize ];
		}
		integer NewPrimId = 0;
		// If it's a group, re-use the old prim ID (from the save file) if it's been
		// set in NewObjects further back - ie, if a prim with that ID no longer exists.
		// Bear in mind that PrimID is 0 in NewObjects if it's already in use
		// In case you're wondering "what's this prim ID for?": it's to keep track of which prims
		// move/change during a "Rearrange" operation. In other words, a relationship between 
		// equivalent prims in two or more different save files. I'd like to give it another name
		// some time so it's not confused with the prim's UUID. -- JFH
		if (CType == NOB_TYPE_GROUP) NewPrimId = PrimId;
		if (!NewPrimId) NewPrimId = NextPrimId++;
		SetPrimId(NewLinkNum, NewPrimId);        // allocate the next Id for the new prim
		if (Params != []) llSetLinkPrimitiveParamsFast(NewLinkNum, Params);
		
		LinkedObjects += [ ObjectId, CpPos, CpNormal, CpBinormal, OriginalSize, ActualSize, SizeFactor, ExtraData ];    // add to LinkedObjects table
		ObjectsCount++;
		if (CType == NOB_TYPE_CREATE_REZZING) {
			if (MemorySizeObject == ObjectName) {
				float OrigFactor = MemorySizeFactor;
				float Factor = MemorySizeFactor;
				if (RandomCreate) Factor *= RandomResizeFactor();
				ResizeLinkedObject(AvId, ObjectId, TargetUuid, Factor);
				// The next line is a bit of a hack. ResizeLinkedObject() saves the factor to MemorySizeFactor, but this can
				// have the effect of causing the size to "drift" - eg, a prim becomes resized small and all subsequent
				// prims have similarly small sizes. So we retain the size factor by restoring it here.
				MemorySizeFactor = OrigFactor;
			}
			else {
				if (RandomCreate) {
					ResizeLinkedObject(AvId, ObjectId, TargetUuid, RandomResizeFactor());
				}
				MemorySizeObject = "";    // break the chain of same-named objects
			}
			if (RandomCreate && RandomRotate) {
				RotateLinkedObject(AvId, ObjectId, (integer)llFrand(360.0));
			}
		}
		if (CType == NOB_TYPE_GROUP) {
			integer CommsType = llList2Integer(ObjectsDynamic, DynamicLibPtr + OBD_COMMS_TYPE);
			ActivationQueue += [ ObjectId, CommsType ];
			ActivationQueueSize++;
			SetTimer();
		}
		if (CType == NOB_TYPE_CLONE) {
			SelectObject(AvId, ObjectId);    // select new prim (clone only)
		}
		else if (CType == NOB_TYPE_AOC) {
			DeselectByAvId(AvId);        // If it's AOC, we select it after deselecting anything else (because we can't predict current state)
			SelectObject(AvId, ObjectId);    // select new prim
		}
		// Also, set "phantom" state if necessary (map objects' needs here currently undetermined)
		integer Phantom = llList2Integer(ObjectsStatic, StaticLibPtr + OBS_PHANTOM);

		if (Phantom) {
			llSetLinkPrimitiveParamsFast(NewLinkNum, [ PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE ]);
		}
		
		//		Sound(SOUND_PLACE);	// make a sound when an object is placed?
		if (FinishLoad) FinishNewObjects();	// Finish loading scene
	}
// Delete NewObjects entry based on object name
DeleteFromNewObjects(string ObjectName) {
	integer P = llListFindList(NewObjects, [ ObjectName ]);
	if (P > -1) {
		P -= NOB_OBJECTNAME;
		NewObjects = llDeleteSubList(NewObjects, P, P + NOB_STRIDE - 1);
	}
}
float RandomResizeFactor() {
	return 1.0 - RandomResize + llFrand(RandomResize * 2.0);
}
// Stop the create cycle
CancelCreation(key AvId) {
	integer NobPtr = FindNewObject(AvId, "", NOB_TYPE_CREATE_READY);
	if (NobPtr > -1) {
		NobPtr -= NOB_AVID;    // position to start of stride
		key ButtonId = llList2Key(NewObjects, NobPtr + NOB_BUTTON);
		if (ButtonId != NULL_KEY) {
			integer ButtonLinkNum = Uuid2LinkNum(ButtonId);
			if (ButtonLinkNum == -1) return;
			PrimGlow(ButtonLinkNum, FALSE);
		}
		NewObjects = llDeleteSubList(NewObjects, NobPtr, NobPtr + NOB_STRIDE - 1);
	}
}
// Find entry in NewObjects table according to criteria and return pointer to table
// Return -1 if no entry found
// Criteria (AvId, PrimName or CType) can be empty to match any value
integer FindNewObject(key AvId, string ObjectName, integer CType) {
	integer L = llGetListLength(NewObjects);
	integer P;
	for(P = 0; P < L; P += NOB_STRIDE) {
		integer OK = TRUE;
		if (AvId != NULL_KEY) {
			key ThisAvId = llList2Key(NewObjects, P + NOB_AVID);
			if (ThisAvId != AvId) OK = FALSE;
		}
		if (ObjectName != "") {
			string ThisObjectName = llList2String(NewObjects, P + NOB_OBJECTNAME);
			if (ThisObjectName != ObjectName) OK = FALSE;
		}
		if (CType) {
			integer ThisCType = llList2Integer(NewObjects, P + NOB_TYPE);
			if (ThisCType != CType) OK = FALSE;
		}
		if (OK) return P;
	}
	return -1;
}
// Use the UuidLinks table to obtain a link number from a given UUID. Since this table is very 
// volatile during the creation or loading of a scene, this function also serves as a housekeeper for that
// table, calling for it to be recreated if it proves to be out of date. Calling this function when the UUID is
// not in the table is perfectly valid and to be expected.
// While it would be possible to argue that the table could be maintained with a little less brute force, I
// would argue that the increased complexity would be harmful, and that the KISS principle should apply here.
//
// The UuidLinks table consists of strides of the format [ UUID, LinkNum ] for each prim in the linkset.
integer Uuid2LinkNum(key Uuid) {
	if (UuidLinksInvalid) return Uuid2LinkNumDirect(Uuid); // Can't use table
	if (Uuid == NULL_KEY) return -1;
	integer Ptr = llListFindList(UuidLinks, [ Uuid ]);
	if (Ptr == -1) { // if there's no entry for this UUID
		return Uuid2LinkNumDirect(Uuid);
	}
	integer LinkNum = llList2Integer(UuidLinks, Ptr + 1); // format of list is [ uuid, linknum ]
	if (llGetLinkKey(LinkNum) == Uuid) return LinkNum; // All is OK, and table is still valid
	// Here, table is no longer valid and has changed, so we need rebuild it
	return Uuid2LinkNumDirect(Uuid);
}
// Gets the UUID from the actual prims (used when UuidLinks table is out-of-date
integer Uuid2LinkNumDirect(key Uuid) {
	// if this function is being called, it means that the UuidLinks table is out-of-date
	UuidLinksInvalid = TRUE;
	// The table will be rebuilt in the timer. We set the timer directly rather than using
	// SetTimer() because this will be called a lot when loading a scene, so the more we can
	// save on CPU the better.
	llSetTimerEvent(TIMER_FREQUENCY);	
	integer PrimCount = llGetNumberOfPrims();
	integer LinkNum;
	for (LinkNum = 1; LinkNum <= PrimCount; LinkNum++) {
		if (llGetLinkKey(LinkNum) == Uuid) return LinkNum;
	}
	return -1; // Uuid doesn't actually exist
}
// Recreate UUIDs/link numbers table. Format is [ UUID, LinkNum ] for each prim in the linkset.
CreateUuidLinks() {
	UuidLinks = [];
	integer PrimCount = llGetNumberOfPrims();
	integer LinkNum;
	for (LinkNum = 1; LinkNum <= PrimCount; LinkNum++) {
		UuidLinks += [ llGetLinkKey(LinkNum), LinkNum ];
	}
	UuidLinksInvalid = FALSE;
}
// Remove an entry from the UUID/LinkNums table
RemoveUuid2Link(key ObjectId) {
	integer U = llListFindList(UuidLinks, [ ObjectId ]);
	if (U > -1) UuidLinks = llDeleteSubList(UuidLinks, U, U);
}
// Behaviour when rezzed
OnRez(integer Param) {
	SetDebug();
	if (UserId != NULL_KEY) Logout();
	string DebugText = "OnRez";
	if (Param == ON_REZ_PARAMETER) {	// if we've been rezzed by 	 App or Map module
		ParentId = llList2Key(llGetObjectDetails(osGetRezzingObject(), [ OBJECT_ROOT ]), 0);
		if (ParentId != NULL_KEY) {
			if (DebugMode) DebugText += "; parent is " + llGetSubString((string)ParentId, 0, 3);
		}
		else {
			DebugText += "; no parent";
		}
	}
	else {
		ParentId = NULL_KEY;
		DebugText += "; manually rezzed";
	}
	Debug(DebugText);
	OwnerId = llGetOwner();	
	WaitingForCataloguer = TRUE;
	llMessageLinked(LINK_THIS, CT_START, "", NULL_KEY); // Tell cataloguer to start processing
	OurUuid = llGetKey();	
}
// Get internal object reference from object name. Returns "" if object doesn't exist
string GetObjectReference(string ObjectName) {
	string ObjectReference = "";
	integer StaticPtr = llListFindList(ObjectsStatic, [ ObjectName ]);
	if (StaticPtr > -1) {
		ObjectReference = llList2String(ObjectsStatic, StaticPtr + OBS_REFERENCE);
	}
	return ObjectReference;
}
// Get pointer to Objects dynamic table row based on object reference (-1 if not found)
integer GetDynamicPointer(string ObjectReference) {
	integer Ptr = llListFindList(ObjectsDynamic, [ ObjectReference ]); // Reference is 1st field, so beginning of table row
	if (Ptr == -1) {
		LogError("Can't find dynamic objects entry"); 
	}
	return Ptr;
}
// Initial code, executed when script first starts, either from on_rez or state_entry.
// This is only for code that's needed in both events.
Initialize(integer OnRez) {
	SetDebug();
	// Values that need to be set each time it's rezzed/copied/etc
	RegionSize = osGetRegionSize();
	// Values that only need to be set once during the script's lifetime go below
	if (Initialized) {
		if (DebugMode) {
			string DebugText = "Re-execution of Initialize(), called from ";
			if (OnRez) DebugText += "on_rez"; else DebugText += "state_entry";
			if (ParentId != NULL_KEY) {
				DebugText += "; parent is " + llGetSubString((string)ParentId, 0, 3);
			}
			Debug(DebugText);
		}
	}
	else {
		if (DebugMode) {
			string DebugText = "Initialize() called from ";
			if (OnRez) DebugText += "on_rez"; else DebugText += "state_entry";
			if (ParentId != NULL_KEY) {
				DebugText += "; parent is " + llGetSubString((string)ParentId, 0, 3);
			}
			Debug(DebugText);
		}
		OwnerId = llGetOwner();	
		OurUuid = llGetKey();
		llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_GLOW, ALL_SIDES, 0.0 ]);
		llLinkParticleSystem(LINK_SET, []);
		SetPrimIds();
		AwakenTicks = 0;
		ObjectsToLoad = 0;
		ObjectsStatic = [];
		ObjectsDynamic = [];
		ObjectsLibraryCount = 0;
		AppBackupsWaiting = 0;
		SendAppData = [];
		AppRestoreData = "";
		RandomResize = 0.0;
		RandomRotate = FALSE;
		CameraJumpMode = FALSE;
		WriteConfig = FALSE;
		EnvironmentValues = [];
		ParentInformed = FALSE;
		UserId = NULL_KEY;
		ReadConfig();
		// Set the default rotation for new objects when created.
		// For Map objects, this is so that north on the map lines up with the control board,
		// a historic necessity inherited from the legacy version.
		// For linked objects, this was discovered to be a discrepancy which caused objects to
		// be rotated 90°. The precise cause is not known, but probably resides in either the
		// calculation for binormal alignment or in the binormal values themselves being reported
		// by OpenSim. Currently, time does not allow full investigation of this. - JFH 2019-05-15
		InitialRot = llEuler2Rot(<0.0, 0.0, 270.0> * DEG_TO_RAD);
		CommsChannelListener = 0;
		CommandChatListener = 0;
		NextTimeOutCheck = TIMEOUT_CHECK_FREQUENCY;
		ReadMapPrims();
		SetCursor(FALSE, NULL_KEY, ZERO_VECTOR);	// hide cursor
		LoadingScene = FALSE;
		Initialized = TRUE;
	}
	// This next line is for scripts who are in a state that lacks a changed() event, part of the
	// whole issue of hundreds of changed() events being fired during the loading of a saved scene.
	// Normally this message is sent when the loading is complete, but it can actually be difficult
	// for a script in a client object to tell whether it's linked because it's been loaded from a saved scene
	// (especially if that link happens really quickly, before the script can even start) or whether it's just
	// been rezzed as part of the rezzing of a complete ML. So we send this message anyway to tell such
	// scripts that they can continue.
	// We set this value and that triggers a LM to say that loading is done.
	LoadingCompleteTicks = 20;
	SetTimer();
	llMessageLinked(LINK_THIS, CT_START, "", NULL_KEY); // Tell cataloguer to start processing
	Debug("Ready");
}
// Return the offset to be applied to a cloned object to lift it away from its original
// Offset is in terms of region coordinates
vector CloneOffset() {
	if (IsMap)
		return(<llFrand(2.0) - 1.0, llFrand(2.0) - 1.0, 1.5>);
	else
		return(<llFrand(0.4) - 0.2, llFrand(0.4) - 0.2, 0.5>);
}
// Is the given object an App or not?
integer IsObjectAnAppByName(string ObjectName) {
	if (IsMap) ObjectName = GetBaseName(ObjectName);
	string ObjectReference = GetObjectReference(ObjectName);
	if (ObjectReference == "") {
		LogError("Can't get library entry for object '" + ObjectName + "'");
		return FALSE;
	}
	integer LibPtr = GetDynamicPointer(ObjectReference);
	if (LibPtr == -1) return FALSE; // should never happen
	return IsObjectAnAppByPtr(LibPtr);
}
integer IsObjectAnAppByPtr(integer LibPtr) {
	return llList2Integer(ObjectsDynamic, LibPtr + OBD_IS_APP);
}
MoveMapObject(string ObjectName, integer DetPtr, key WorldId, key IconId, vector WorldPos, rotation IconRot, vector Normal) {
	if (ObjectName == "") ObjectName = llList2String(llGetObjectDetails(WorldId, [ OBJECT_NAME ]), 0);
	string ObjectReference = GetObjectReference(GetBaseName(ObjectName));
	if (ObjectReference == "") { LogError("Can't find map object to move: " + ObjectName); return; }
	integer LibPtr = GetDynamicPointer(ObjectReference);
	if (LibPtr == -1) return; // should never happen
	integer DoRotation = llList2Integer(ObjectsDynamic, LibPtr + OBD_DO_ROTATION);
	integer Center = llList2Integer(ObjectsDynamic, LibPtr + OBD_CENTER);
	integer Floating = llList2Integer(ObjectsDynamic, LibPtr + OBD_FLOATING);
	integer DummyMove = llList2Integer(ObjectsDynamic, LibPtr + OBD_DUMMY_MOVE);
	if (Center) WorldPos = WorldOrigin + WorldSize * 0.5;
	if (Floating) WorldPos = AdjustFloatingObject(WorldPos);
	IconRot = IconRot * RotBetween(llRot2Up(IconRot), Normal);
	rotation WorldRot = IconRot2WorldRot(IconRot);
	MoveIconOnly(IconId, WorldPos, WorldRot);
	MoveWorldObjectOnly(WorldId, WorldPos, WorldRot);
	if (DummyMove) {
		// This is a workaround for an OpenSim bug whereby mesh objects rezzed with a non-zero
		// rotation have a physics envelope which doesn't match the rotation. This hack issues a
		// dummy move command to force the object to move itself (to the identical position), which seems
		// to make OpenSim update the physics to a correct rotation.
		MoveWorldObjectOnly(WorldId, WorldPos, WorldRot);
	}
	if (CursorInUse) SetCursor(TRUE, WorldId, WorldPos);
}
MoveIconOnly(key IconId, vector WorldPos, rotation WorldRot) {
	rotation IconRot = WorldRot2IconRot(WorldRot);
	vector IconPos = WorldPos2BoardPos(WorldPos);
	IconPos = CheckBoundariesRegion(IconPos);
	MessageStandard(IconId, IC_MOVE_ROTATE, [ IconPos, IconRot ]);
}
MoveWorldObjectOnly(key WorldId, vector WorldPos, rotation WorldRot) {
	WorldPos = CheckBoundariesRegion(WorldPos);
	MessageStandard(WorldId, WO_MOVE_ROTATE, [ WorldPos, WorldRot ]);
}
rotation IconRot2WorldRot(rotation IconRot) {
	//	return IconRot / llGetRot();
	//return IconRot / BoardPrimRot;
	return IconRot / BoardPrimRot * InitialRot;
}
rotation WorldRot2IconRot(rotation WorldRot) {
	//	return WorldRot * llGetRot();
	//return WorldRot * BoardPrimRot;
	return WorldRot / InitialRot *  BoardPrimRot;
}
// Actually move linked prim to specified local position and rotation
MovePrim(key ObjectId, vector Pos, rotation Rot, integer MakeSound) {
	integer LinkNum = Uuid2LinkNum(ObjectId);
	if (LinkNum == -1) return;
	Pos = CheckBoundariesLocal(Pos);
	vector CurrentPrimPos = llList2Vector(llGetLinkPrimitiveParams(LinkNum, [ PRIM_POS_LOCAL ]), 0);
	float MoveDistance = llVecDist(CurrentPrimPos, Pos);    // calculate distance prim will move
	integer Hops = (integer)(MoveDistance / 10.0) + 1;    // divide it into 10m hops
	list PrimParams = [];
	while(Hops--) {
		PrimParams += [ PRIM_POS_LOCAL, Pos ];
	}
	PrimParams += [ PRIM_ROT_LOCAL, Rot ];
	llSetLinkPrimitiveParamsFast(LinkNum, PrimParams);
	llMessageLinked(LinkNum, LM_MOVED_ROTATED, "", UserId);
	if (MakeSound) Sound(SOUND_PLACE);
}
// CheckBoundaries tests to see if the object is outside the region boundary, and positions it inside if it is
vector CheckBoundariesRegion(vector RegionPos) {
	if (RegionPos.x < 0.0) RegionPos.x = 0.0;
	if (RegionPos.x > RegionSize.x) RegionPos.x = RegionSize.x;
	if (RegionPos.y < 0.0) RegionPos.y = 0.0;
	if (RegionPos.y > RegionSize.y) RegionPos.y = RegionSize.y;
	return RegionPos;
}
vector CheckBoundariesLocal(vector LocalPos) {
	vector RootPos = llGetPos();
	rotation RootRot = llGetRot();
	vector RegionPos = RootPos + LocalPos * RootRot;
	RegionPos = CheckBoundariesRegion(RegionPos);
	return (RegionPos - RootPos) / RootRot;
}
// For a floating object, lift it to water level
vector AdjustFloatingObject(vector WorldPos) {
	float FloatWaterLevel = llWater(WorldPos- llGetPos());	// find water level at WorldPos
	if (FloatWaterLevel > WorldPos.z) 	// if the water level is higher than the given position
		WorldPos.z = FloatWaterLevel;	// set height of object to water level
	return WorldPos;
}
// This function is from original by Ramesh
rotation RotBetween(vector start, vector end) { //adjusts quaternion magnitude so (start * return == end)
	rotation rot = llRotBetween(start, end);
	if(llVecMag(start)!= 0)	{
		if(llVecMag(end)!= 0) {
			float d = llSqrt(llVecMag(end) / llVecMag(start));
			return <rot.x * d, rot.y * d, rot.z * d, rot.s * d>;
		}
	}
	return rot;
}
// Shows count of objects in scene on HUD (when appropriate)
integer UpdateObjectsCountStatus() {
	llMessageLinked(LINK_SET, LM_OBJECTS_COUNT, (string)ObjectsCount, UserId);
	if (ObjectsLimit == 0) return TRUE;	// no limit
	integer ReturnValue;
	string StatusMessage;
	if (ObjectsCount < ObjectsLimit) {
		StatusMessage = "Objects in scene: " + (string)ObjectsCount + "/" + (string)ObjectsLimit;
		ReturnValue = TRUE;
	}
	else {
		StatusMessage = "!Scene full (" + (string)ObjectsCount + " objects)";
		ReturnValue = FALSE;
	}
	llMessageLinked(LINK_SET, LM_HUD_STATUS, StatusMessage, UserId);	// $C expands to camera angle in HUD
	return ReturnValue;
}
StoreModules(string sData) {
	ModulesList = llParseStringKeepNulls(sData, [ "|" ], []);
}
// Takes all libraries' category data from the cataloguer and stores it
StoreCatalog(string sData) {
	ObjectsStatic = [];
	ObjectsDynamic = [];
	ObjectModules = [];
	AutoHides = [];
	integer NextReferenceInt = 0;
	// Data comes across as catalog data (base-64) and objects metadata (base-64) separated by "|"
	list Parts = llParseStringKeepNulls(sData, [ "|" ], []);	// extract
	sData = llBase64ToString(llList2String(Parts, 1));			// and convert
// Each object is on a separate line
	list ObjectData = llParseStringKeepNulls(sData, [ "\n" ], []);
	integer OCount = llGetListLength(ObjectData);
	integer P;
	for (P = 0; P < (OCount - 1); P++) {	// -1 because the last line is empty
		string Line = llList2String(ObjectData, P);
		list Data = llParseStringKeepNulls(Line, [ "|" ], []);
		// format of line is:
		//  Static:
		// 		ObjectName,
		//		CameraPos,
		//		CameraAltPos,
		//		CameraFocus,
		//		JumpPos,
		//		JumpLookAt,
		// Dynamic:
		// 		LibKey,
		//		ShortDesc,
		//		LongDescBase64,
		//		ThumbnailId,
		//		PreviewId,
		//		RandomRotate,
		//		RandomResize,
		//		Detached,
		//		AutoHide,
		//		Source64,
		//		SizeFactor,
		//		OffsetPos,
		//		OffsetRot,
		//		Sittable,
		//		DoRotation,
		//		DoBinormal,
		//		Center,
		//		AdjustHeight,
		//		DummyMove,
		//		Resize,
		//		Phantom,
		//		Floating,
		//		IsApp,
		//		SnapGrid,
		//		RegionSnap,
		//		CopyRotation
		//		CommsType
		string ObjectName = llList2String(Data, 0);
		string ObjectReference = "%O" + (string)NextReferenceInt++;
		if (llStringTrim(ObjectName, STRING_TRIM) == "") LogError("Warning: blank object name in StoreCatalog() function in ML");
		vector CameraPos = (vector)			llList2String(Data, 1);
		vector CameraAltPos = (vector)		llList2String(Data, 2);
		vector CameraFocus = (vector)		llList2String(Data, 3);
		vector JumpPos = (vector)			llList2String(Data, 4);
		vector JumpLookAt = (vector)		llList2String(Data, 5);
		integer Phantom = (integer)			llList2String(Data, 6);
		integer AutoHide = (integer) 		llList2String(Data, 7);
		ObjectsStatic += [
				ObjectName,
				ObjectReference,
				CameraPos,
				CameraAltPos,
				CameraFocus,
				JumpPos,
				JumpLookAt,
				Phantom,
				AutoHide
			];
		if (!LoadStaticObjectsOnly) {
			integer LibKey = (integer)			llList2String(Data, 8);
			// Not used by ML:
			// ShortDesc			9
			// LongDescBase64 		10
			// ThumbnailId 		11
			// PreviewId 			12
			// RandomRotate 		13
			// RandomResize 		14
			integer Detached = (integer)		llList2String(Data, 15);
			string SourceBase64 = 				llList2String(Data, 16);
			float SizeFactor = (float)			llList2String(Data, 17);
			vector OffsetPos = (vector)			llList2String(Data, 18);
			vector OffsetRot = (vector)			llList2String(Data, 19);
			integer Sittable = (integer)		llList2String(Data, 20);
			integer DoRotation = (integer)		llList2String(Data, 21);
			integer DoBinormal = (integer)		llList2String(Data, 22);
			integer Center = (integer)			llList2String(Data, 23);
			integer AdjustHeight = (integer)		llList2String(Data, 24);
			integer DummyMove = (integer)		llList2String(Data, 25);
			integer Resizable = (integer)		llList2String(Data, 26);
			integer Floating = (integer)		llList2String(Data, 27);
			integer IsApp = (integer)			llList2String(Data, 28);
			string StickPoint64 = 				llList2String(Data, 29);
			vector SnapGrid = (vector)			llList2String(Data, 30);
			vector RegionSnap = (vector)		llList2String(Data, 31);
			integer CopyRotation = (integer)		llList2String(Data, 32);
			integer CommsType = (integer)		llList2String(Data, 33);
			
			ObjectsDynamic += [
				ObjectReference,
				Detached,
				SourceBase64,
				SizeFactor,
				OffsetPos,
				OffsetRot,
				Sittable,
				DoRotation,
				DoBinormal,
				CopyRotation,
				Center,
				AdjustHeight,
				DummyMove,
				Resizable,
				Floating,
				IsApp,
				StickPoint64,
				SnapGrid,
				RegionSnap,
				CommsType
					];
			ObjectModules += [ ObjectName, LibKey ];
			if (AutoHide) AutoHides += ObjectName;
		}
	}
	ObjectsLibraryCount = llGetListLength(ObjectsStatic) / OBS_STRIDE;
	if (DebugMode) {
		string What = "dynamic";
		if (LoadStaticObjectsOnly) What = "static";
		Debug("Received " + (string)ObjectsLibraryCount + " objects' " + What + " data from cataloguer");
	}
	// If we're a child App, we now have all we need to start work. Tell this
	// to our parent.
	if (ParentId != NULL_KEY && !ParentInformed) {
		Debug("Sending CHILD_READY message to parent");
		MessageStandard(ParentId, LM_CHILD_READY, []);	
		ParentInformed = TRUE;
	}
}
// Convert region position of control board click to X,Y coordinates
vector BoardPos2WorldPos(vector BoardPos) {
	BoardPos -= BoardOffset * BoardPrimRot;
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
	vector BoardPos = BoardPrimPos + ((SurfacePos - BoardPrimHalfSize) * BoardPrimRot);
	BoardPos += (BoardOffset * BoardPrimRot);
	return BoardPos;
}
// Get internal ID from prim description, which should be "*<n>" where <n> is the internal ID
// Returns -1 if it's not an MLO prim
integer GetInternalId(integer LinkNum) {
	string PrimDesc = llList2String(llGetLinkPrimitiveParams(LinkNum, [ PRIM_DESC ]), 0);
	if (llGetSubString(PrimDesc, 0, 0) != "*") return -1;	// Not an MLO
	if (llSubStringIndex(PrimDesc, "/") > -1) {	//  Assist in identifying objects in old format; remove this in next version
		llOwnerSay("WARNING: offset data in description for object: " + llGetLinkName(LinkNum));
	}
	integer InternalId = (integer)llGetSubString(PrimDesc, 1, -1);
	return InternalId;
}
// Set the Id of the stated (moveable) prim
SetPrimId(integer LinkNum, integer Id) {
	if (GetInternalId(LinkNum) == -1) return;    // it's not a moveable prim
	string PrimDesc = "*" + (string)Id;
	llSetLinkPrimitiveParamsFast(LinkNum, [ PRIM_DESC, PrimDesc ]);
}
// Handle stuff received through comms chat channel from another ML
ProcessComms(key Id, string Text) {
	string Command = llGetSubString(Text, 0, 0);	// first character is command
	string Param = llGetSubString(Text, 1, -1);		// and the rest is data
	if (Command == "S") { 	// a user has selected something in some other ML
		key SelUserId = (key)Param;
		integer SelPtr = GetSelectionPtr(SelUserId);
		if (SelPtr > -1) {		//if they have an object selected in our ML
			DeselectByAvId(SelUserId);
		}
	}
}
Login(key LoginId) {
	if (LoginId == UserId) {
		llRegionSayTo(LoginId, 0, "You are already signed in!");
		return;
	}
	LoadStaticObjectsOnly = FALSE;
	SendPublicData();
	if (DummyMoveSet) MoveLinkset();
	UserId = LoginId;
	SetDebug();
	CameraJumpMode = FALSE;	// See note ref# 18391077 in HUD attachment script
	NudgeDistance = DefaultNudgeDistance; // Reset nudge distance
	if (IsMap) ReadMapPrims();
	llMessageLinked(LINK_SET, LM_SEAT_USER, "0", UserId);        // Tell other scripts that they've logged in
	llMessageLinked(LINK_ALL_CHILDREN, LIB_INITIALIZE, (string)RezPosition, UserId);	// Tell library modules where to rez objects
	ClearStoredRotation(UserId);	// in case it was left behind
	MemorySizeObject = "";    // break the chain of same-named objects
	if (IsMap) CommandChatListener = llListen(CommandChatChannel, "", UserId, "");
}
Logout() {
	// LoadStaticObjectsOnly = True;
	CancelCreation(UserId);  // cancel any creation they may have
	llMessageLinked(LINK_SET, LM_SEAT_USER, "", UserId);        // Tell other scripts that they've logged out
	ClearStoredRotation(UserId);
	UserId = NULL_KEY;
	RandomCreate = FALSE;
	if (CommandChatListener) llListenRemove(CommandChatListener);
	MemorySizeObject = "";    // break the chain of same-named objects
	ObjectsDynamic = []; // Free up memory
}
ReadMapPrims() {
	BoardLinkNum = -1;
	CursorLinkNum = -1;
	if (!IsMap) return;	// all these prims are only related to maps
	//Modules = [];
	//ModulesCount = 0;
	integer PrimCount = llGetNumberOfPrims();
	integer LinkNum;
	for (LinkNum = 2; LinkNum <= PrimCount; LinkNum++) {
		string PrimName = llGetLinkName(LinkNum);
		if (PrimName == BoardPrimName) {	// It's the control board
			BoardLinkNum = LinkNum;
			list Params = llGetLinkPrimitiveParams(BoardLinkNum, [ PRIM_POSITION, PRIM_ROTATION, PRIM_SIZE ]);
			BoardPrimPos = llList2Vector(Params, 0);
			BoardPrimRot = llList2Rot(Params, 1);
			BoardPrimSize = llList2Vector(Params, 2);
			BoardPrimHalfSize = BoardPrimSize / 2.0;    // Half scale, ie distance from origin to prim centre
			if (ScalingFactor == 0.0) ScalingFactor = WorldSize.x / BoardPrimSize.x;
		}
		//		else if (llGetSubString(PrimName, 0, 5) == "&Lib: ") {
		//			vector LocalPos = llList2Vector(llGetLinkPrimitiveParams(LinkNum, [ PRIM_POS_LOCAL ]), 0);
		//			Modules += [ LinkNum, LocalPos ];
		//			ModulesCount++;
		//		}
		else if (PrimName == CursorPrimName) {
			CursorLinkNum = LinkNum;
		}
	}
	if (BoardLinkNum == -1) {
		LogError("Control board missing");
		BoardLinkNum = -999;	// invalid value so we don't screw up the linkset later
		return;
	}
}
string GetBaseName(string ObjectName) {
	if (!IsMap) return ObjectName;
	string Last = llGetSubString(ObjectName, -1, -1);
	if (Last == "W" || Last == "I")
		return llGetSubString(ObjectName, 0, -2);
	else
		return ObjectName;
}
// Hide prim by making it small and moving it to root position
HidePrim(key AvId) {
	key ObjectId = GetSelectionUuid(AvId);
	if (ObjectId == NULL_KEY) {
		Message(AvId, "Select an object first, then you can hide it");
		return;
	}
	DeselectByAvId(AvId);
	integer LinkNum = Uuid2LinkNum(ObjectId);
	if (LinkNum == -1) return;
	llSetLinkPrimitiveParamsFast(LinkNum, [ PRIM_SIZE, HIDDEN_PRIM_SIZE ]);
	MovePrim(ObjectId, <0.0, 0.0, -10.0>, ZERO_ROTATION, FALSE);
	MovePrim(ObjectId, ZERO_VECTOR, ZERO_ROTATION, FALSE);
}
// Hack - dummy move to force physics shapes to be in line
MoveLinkset() {
	llSetPos(llGetPos());
}
// Remove object from scene (by "remove" function)
RemoveObject(key AvId) {
	integer P = llListFindList(Selections, [ AvId ]);
	if (P == -1) {
		Message(AvId, "Select an object first, then you can remove it");
		return;
	}
	P -= SEL_AVID;
	if (IsMap) {
		key ObjectId = llList2Key(Selections, P + SEL_OBJECT_ID);
		key IconId = llList2Key(Selections, P + SEL_ICON_ID);
		integer DPtr = llList2Integer(Selections, P + SEL_OBD_PTR);
		DeselectByAvId(AvId);
		DetachedObjects = llDeleteSubList(DetachedObjects, DPtr, DPtr + DO_STRIDE - 1);
		MessageStandard(IconId, IC_DELETE, []);
		DeleteDetachedObject(ObjectId);		
	}
	else {
		key SelectedUuid = llList2Key(Selections, P + SEL_OBJECT_ID);
		DeselectByAvId(AvId);
		UnlinkPrim(SelectedUuid);
	}
	ObjectsCount--;
	llMessageLinked(LINK_SET, LM_OBJECTS_COUNT, (string)ObjectsCount, UserId);
}
UnlinkPrim(key ObjectId) {
	// Look for this prim in the LinkedObjects table
	integer LOPtr = llListFindList(LinkedObjects, [ ObjectId ]);
	if (LOPtr > -1) {
		// there is an entry for it
		LOPtr -= LO_OBJECT_ID;    // position at start of stride
	}
	UnlinkPrimWithPtr(ObjectId, LOPtr);
}
// An overload, an overload; my kingdom for an overload capability in LSL ...
UnlinkPrimWithPtr(key ObjectId, integer LinkedObjectsPtr) {
	if (LinkedObjectsPtr > -1) {
		LinkedObjects = llDeleteSubList(LinkedObjects, LinkedObjectsPtr, LinkedObjectsPtr + LO_STRIDE - 1);
	}
	// Delete any entries for this link number from ReservedTouchFaces
	integer P;
	do {
		P = llListFindList(ReservedTouchFaces, [ ObjectId ]); // ObjectId is first column of table
		if (P > -1) {
			ReservedTouchFaces = llDeleteSubList(ReservedTouchFaces, P, P + RTF_STRIDE - 1);
		}
	} while(P > -1);
	// Perhaps we should also check (a) Awakeners and (b) Activation Queue, in case people delete objects
	// while (a) the ML has just been rezzed, or (b) while a saved scene is loading. Or is it not worth the extra
	// CPU load?
	// Now unlink the prim, which will self-delete
	integer LinkNum = Uuid2LinkNum(ObjectId);
	if (LinkNum == -1) return;
	osForceBreakLink(LinkNum);
	RemoveUuid2Link(ObjectId);
}
AutoHideSet(integer Hide) {
	float Alpha = 1.0;
	if (Hide) Alpha = 0.0;
	list PrimParams = [];
	integer LinkNum;
	integer Len = llGetListLength(LinkedObjects);
	integer LoPtr;
	for (LoPtr = 0; LoPtr < Len; LoPtr += LO_STRIDE) {
		key LoUuid = llList2Key(LinkedObjects, LoPtr + LO_OBJECT_ID);
		LinkNum = Uuid2LinkNum(LoUuid);
		if (LinkNum == -1) return;
		string PrimName = llGetLinkName(LinkNum);
		integer StaticLibPtr = llListFindList(ObjectsStatic, [ PrimName ]);
		if (StaticLibPtr > -1) {	// It's an actual library object
			integer AutoHide = llList2Integer(ObjectsStatic, StaticLibPtr + OBS_AUTOHIDE);
			if (AutoHide) {	// if this is an autohide object
				llSetLinkAlpha(LinkNum, Alpha, ALL_SIDES);	// I'd rather do it all in a single llSetLinkPrimitiveParamsFast call, but that needs the object's color data
				// Shrink or restore size of object
				vector Size;
				if (Hide) {
					Size = <0.001, 0.001, 0.001>;
				}
				else {
					Size = llList2Vector(LinkedObjects, LoPtr + LO_ACTUAL_SIZE);
				}
				PrimParams += [ PRIM_LINK_TARGET, LinkNum, PRIM_SIZE, Size ];
			}
		}
	}
	Len = llGetNumberOfPrims();
	for (LinkNum = 1; LinkNum <= Len; LinkNum++) {
		key K = llGetLinkKey(LinkNum);
		string Desc = llList2String(llGetObjectDetails(K, [ OBJECT_DESC ]), 0);
		if (Desc == "&hide") llSetLinkAlpha(LinkNum, Alpha, ALL_SIDES);
	}
	if (PrimParams != []) llSetLinkPrimitiveParamsFast(LINK_THIS, PrimParams);
}
// Remove objects (by "clear" function)
Clear() {
	Debug("Clearing scene");
	integer OLen = llGetListLength(LinkedObjects);
	integer DLen = llGetListLength(DetachedObjects);
	integer TotalObjectCount = (OLen / LO_STRIDE) + (DLen / DO_STRIDE);
	integer GiveFeedback = (TotalObjectCount > 5);	// if >5 objects, give feedback in chat
	integer P;
	Debug(" - detached objects");
	// Delete detached objects
	for (P = 0; P < DLen; P += DO_STRIDE) {
		key ObjectId = llList2Key(DetachedObjects, P + DO_OBJECT_ID);
		DeleteDetachedObject(ObjectId);
		if (IsMap) {
			key IconId = llList2Key(DetachedObjects, P + DO_ICON_ID);
			MessageStandard(IconId, IC_DELETE, []);
		}
	}
	DetachedObjects = [];
	// Delete linked objects
	Debug(" - linked objects");
	integer UnlinkedCount = OLen / LO_STRIDE;
	if (UnlinkedCount > 0) {	// If there are unlinked objects
		UnlinksToDo = UnlinkedCount;
		llMessageLinked(LINK_THIS, LM_UNLINK_QUEUE, "", NULL_KEY); // trigger call to UnlinkFromQueue()
	} else { // No unlinked objects, so finish
		ClearEnd();
	}
	UuidLinksInvalid = TRUE;
	SetTimer();
}
ClearEnd() {
	ObjectsCount = 0;
	MemorySizeObject = "";    // break the chain of same-named objects
	llMessageLinked(LINK_SET, LM_CARD_RESET, "", NULL_KEY);        // reset card decks
	Debug(" - orphans");
	RemoveOrphans();
	//if (GiveFeedback) llRegionSayTo(UserId, 0, "Done.");
	llMessageLinked(LINK_SET, LM_TASK_COMPLETE, "", UserId);
	llMessageLinked(LINK_SET, LM_OBJECTS_COUNT, (string)ObjectsCount, UserId);
	Debug(" - finished");
}
UnlinkFromQueue() {
// The reason we use a queue is so that we don't have a large number of unlinkings going on in a single event.
// It's not really a queue as such, more that we keep count of the number of objects to unlink and do a batch at
// a time from the bottom of the LinkedObjects table.
	if (DebugMode) Debug("Unlinking: " + (string)UnlinksToDo);
	if (UnlinksToDo > 0) {
		integer Count = UnlinksToDo;
		if (Count > UnlinkBatchSize) Count = UnlinkBatchSize;
		UnlinksToDo -= Count;
		while (Count--) {
			// Unlink first object in LinkedObjects
			key ObjectId = llList2Key(LinkedObjects, LO_OBJECT_ID);
			UnlinkPrimWithPtr(ObjectId, 0);
		}
	}
	if (UnlinksToDo > 0) {
		llMessageLinked(LINK_THIS, LM_UNLINK_QUEUE, "", NULL_KEY); // trigger call back here
	} else {
		// Nothing in unlink queue - we can finish
		ClearEnd();
	}
}
// Removes all moveable prims, to clear out ones that have been left behind, eg
// by a script reset. This should only ever be called when the scene is empty.
// It would be possible to make this more powerful and reference each prim against
// the LinkedObjects table, but that would incur more overhead. However, in that case it
// could be called at any time.
RemoveOrphans() {
	list Uuids = [];
	integer L = llGetNumberOfPrims();
	integer I;
	Debug(" - - finding orphans");
	for (I = 2; I <= L; I++) {
		string Desc = llList2String(llGetLinkPrimitiveParams(I, [ PRIM_DESC ]), 0);
		if (llGetSubString(Desc, 0, 0) == "*") {
			Uuids += llGetLinkKey(I);
		}
	}
	L = llGetListLength(Uuids);
	Debug(" - - unlinking " + (string)L + " orphans");
	for(I = 0; I < L; I++) {
		key Uuid = llList2Key(Uuids, I);
		integer LinkNum = Uuid2LinkNum(Uuid);
		if (LinkNum > -1) osForceBreakLink(LinkNum);
	}
	Debug(" - - finished orphans");
}
DeleteDetachedObject(key ObjectId) {
	MessageStandard(ObjectId, WO_MOVE_ROTATE, [ WorldOrigin + <0.0, 0.0, 500.0>, ZERO_ROTATION ]);
	MessageStandard(ObjectId, WO_DELETE, []);
}
// Rotate selected object
RotateSelectedObject(key AvId, string ArgumentString) {
	list Args = llParseStringKeepNulls(ArgumentString, [ " " ], []);
	integer Degrees = (integer)llList2String(Args, 0);
	integer SelPtr = llListFindList(Selections, [ AvId ]);
	if (SelPtr == -1) {
		Message(AvId, "Select an object first, then you can rotate it");
		return;
	}
	if (IsMap) {
		integer DPtr = llList2Integer(Selections, SelPtr + SEL_OBD_PTR);
		RotateMapObject(DPtr, Degrees);
	}
	else {
		key ObjectId = llList2Key(Selections, SelPtr + SEL_OBJECT_ID);
		RotateLinkedObject(AvId, ObjectId, Degrees);
	}
}
// Rotate object by specified amount (in addition to any current rotation)
RotateMapObject(integer DPtr, float Degrees) {
	key ObjectId = llList2Key(DetachedObjects, DPtr + DO_OBJECT_ID);
	key IconId = llList2Key(DetachedObjects, DPtr + DO_ICON_ID);
	rotation Rot = llList2Rot(llGetObjectDetails(ObjectId, [ OBJECT_ROT ]), 0);
	rotation AddRot = llEuler2Rot(<0.0, 0.0, Degrees> * DEG_TO_RAD);
	rotation NewWorldRot = AddRot * Rot;
	rotation NewIconRot = WorldRot2IconRot(NewWorldRot);
	MessageStandard(IconId, IC_ROTATE, [ NewIconRot ]);
	MessageStandard(ObjectId, WO_ROTATE, [ NewWorldRot ]);
}
// Rotate prim by link number
RotateLinkedObject(key AvId, key ObjectId, integer Degrees) {
	integer LinkNum = Uuid2LinkNum(ObjectId);
	if (LinkNum == -1) return;
	string ObjectName = llGetLinkName(LinkNum);
	string ObjectReference = GetObjectReference(ObjectName);
	if (ObjectReference == "") { LogError("No object in library to rotate"); return; }
	integer LibPtr = GetDynamicPointer(ObjectReference);
	if (LibPtr == -1) return; // should never happen
	integer DummyMove = llList2Integer(ObjectsDynamic, LibPtr + OBD_DUMMY_MOVE);
	vector OffsetRotV = llList2Vector(ObjectsDynamic, LibPtr + OBD_OFFSET_ROT);
	rotation OffsetRot = llEuler2Rot(OffsetRotV * DEG_TO_RAD);
	if (OffsetRotV == VEC_NAN) {	// it's not specified in the config card for this object
		OffsetRot = ZERO_ROTATION;	// no offset rotation
	}
	else {
		OffsetRot = InitialRot * OffsetRot; // apply 90° fix
	}
	rotation Change =  llEuler2Rot(<0.0, 0.0, -Degrees * DEG_TO_RAD>);    // note that degrees are negated
	rotation Rot = llList2Rot(llGetLinkPrimitiveParams(LinkNum, [ PRIM_ROT_LOCAL ]), 0);
	Change = Change / OffsetRot;        // remove native rotation
	rotation NewRot = Change * Rot;            // apply change
	NewRot = OffsetRot * NewRot;        // re-apply native rotation
	
	llSetLinkPrimitiveParamsFast(LinkNum, [ PRIM_ROT_LOCAL, NewRot ]);
	llMessageLinked(LinkNum, LM_MOVED_ROTATED, "", AvId);
	// Some mesh objects need a small dummy movement (and back to set things right again) in order
	// for the physics mesh to be rotated to follow. This is an old OpenSim bug (as of 0.81), and
	// as a workaround we have a "DummyMesh = True" parameter in the config file for the object,
	// which gets used here and in other places.
	// Unlike other dummy moves, simply repositioning in the same place isn't enough - it has to move
	// away and then back again.
	// Also, the two moves can't be done within a single llSetLinkPrimitiveParamsFast call, or it won't
	// work.
	if (DummyMove) {
		vector Pos = llList2Vector(llGetLinkPrimitiveParams(LinkNum, [ PRIM_POS_LOCAL ]), 0);
		vector DummyPos = Pos + DUMMY_OFFSET;
		llSetLinkPrimitiveParamsFast(LinkNum, [ PRIM_POS_LOCAL, DummyPos ]);
		llSetLinkPrimitiveParamsFast(LinkNum, [ PRIM_POS_LOCAL, Pos ]);
	}
	// Store rotation
	integer D = llListFindList(LinkedObjects, [ ObjectId ]);
	if (D > -1) {	// should never be false, but just in case ...
		D -= LO_OBJECT_ID;
		vector SurfaceNormal = llList2Vector(LinkedObjects, D + LO_CP_NORMAL);
		if (AvId != NULL_KEY) AddStoredRotation(AvId, ObjectName, SurfaceNormal, NewRot);
	}
}
// Given an avatar id and a command-line type argument, turns that into linknum and factor for the resize itself
ResizeObjectFrontEnd(key AvId, string Argument) {
	integer SelPtr = llListFindList(Selections, [ AvId ]);
	if (SelPtr == -1) {
		Message(AvId, "Select an object first, then you can resize it");
		return;
	}
	// Argument is an integer that represents a %age change (eg 25 for a change of 1.25)
	float Factor = 1.0 + ((float)Argument / 100.0);
	if (IsMap) {
		integer DetPtr = llList2Integer(Selections, SelPtr + SEL_OBD_PTR);
		ResizeMapObject(DetPtr, Factor);
	}
	else {
		key ObjectId = llList2Key(Selections, SelPtr + SEL_OBJECT_ID);
		ResizeLinkedObject(AvId, ObjectId, NULL_KEY, Factor);
	}
}
ResizeMapObject(integer DetPtr, float Factor) {
	key ObjectId = llList2Key(DetachedObjects, DetPtr + DO_OBJECT_ID);
	key IconId = llList2Key(DetachedObjects, DetPtr + DO_ICON_ID);
	string ObjectName = llList2String(llGetObjectDetails(ObjectId, [ OBJECT_NAME ]), 0);
	float CurrentSizeFactor = llList2Float(DetachedObjects, DetPtr + DO_SIZE_FACTOR);
	float NewSizeFactor = CurrentSizeFactor * Factor;
	MessageStandard(ObjectId, WO_RESIZE, [ NewSizeFactor ]);
	MessageStandard(IconId, IC_RESIZE, [ NewSizeFactor ]);
	DetachedObjects = llListReplaceList(DetachedObjects, [ NewSizeFactor ], DetPtr + DO_SIZE_FACTOR, DetPtr + DO_SIZE_FACTOR);
	MemorySizeObject = ObjectName;
	MemorySizeFactor = NewSizeFactor;
}
// Change size of an ML object according to the given factor
ResizeLinkedObject(key AvId, key ObjectId, key TargetUuid, float Factor) {
	integer LinkNum = Uuid2LinkNum(ObjectId);
	if (LinkNum == -1) return;
	string PrimName = llGetLinkName(LinkNum);
	vector PrimSize = llList2Vector(llGetLinkPrimitiveParams(LinkNum, [ PRIM_SIZE ]), 0);
	PrimSize *= Factor;
	if (SizeExceeded(PrimSize)) return;
	llSetLinkPrimitiveParamsFast(LinkNum, [ PRIM_SIZE, PrimSize ]);
	// Reposition for new size if the contact point is known. It should always be known except in
	// the case of legacy save files from prior to this feature. So we get the contact point (CP)
	// data from the table where it ought to be, then apply it to the prim position
	integer D = llListFindList(LinkedObjects, [ ObjectId ]);
	if (D > -1) {    // Otherwise, it's a new prim that's not been recorded yet (eg a clone)
		D -= LO_OBJECT_ID;
		vector CpPos = llList2Vector(LinkedObjects, D + LO_CP_POSITION);
		vector CpNormal = llList2Vector(LinkedObjects, D + LO_CP_NORMAL);
		vector CpBinormal = llList2Vector(LinkedObjects, D + LO_CP_BINORMAL);
		vector ActualSize = llList2Vector(LinkedObjects, D + LO_ACTUAL_SIZE);
		float PrimSizeFactor = llList2Float(LinkedObjects, D + LO_SIZE_FACTOR);    // this is the current factor relating to the prim's original size rather than previous size
		ActualSize *= Factor;
		PrimSizeFactor *= Factor;    // incorporate this change into historical size relationship
		// Update LinkedObjects table with new size and size factor
		LinkedObjects = llListReplaceList(LinkedObjects, [ ActualSize, PrimSizeFactor ], D + LO_ACTUAL_SIZE, D + LO_SIZE_FACTOR);
		if (CpPos != VEC_NAN) {
			PositionObjectOnFace(AvId, PrimName, TargetUuid, FALSE, ObjectId, NULL_KEY, -1, VEC_NAN, -1, VEC_NAN, CpPos, CpNormal, CpBinormal, PrimSizeFactor);
		}
		MemorySizeObject = PrimName;
		MemorySizeFactor = PrimSizeFactor;
	}
}
ProcessNudge(string Data) {
	integer SelPtr = llListFindList(Selections, [ UserId ]);
	if (SelPtr == -1) {
		LogError("Can't find selection to nudge");
		return;
	}
	list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
	string Command = llList2String(Parts, 0);
	//vector CameraPos = (vector)llList2String(Parts, 1);
	rotation CameraRot = (rotation)llList2String(Parts, 2);
	vector NudgeValue = ZERO_VECTOR;
	integer Cardinal = FALSE;
	if (Command == "+") 	  { AdjustNudgeFactor(TRUE); return; }
	else if (Command == "-") { AdjustNudgeFactor(FALSE); return; }
	else if (Command == "N") { NudgeValue.y += NudgeDistance; Cardinal = TRUE; }
	else if (Command == "S") { NudgeValue.y -= NudgeDistance; Cardinal = TRUE; }
	else if (Command == "E") { NudgeValue.x += NudgeDistance; Cardinal = TRUE; }
	else if (Command == "W") { NudgeValue.x -= NudgeDistance; Cardinal = TRUE; }
	else if (Command == "F") NudgeValue.x += NudgeDistance;
	else if (Command == "B") NudgeValue.x -= NudgeDistance;
	else if (Command == "R") NudgeValue.y -= NudgeDistance;
	else if (Command == "L") NudgeValue.y += NudgeDistance;
	else if (Command == "U") NudgeValue.z += NudgeDistance;
	else if (Command == "D") NudgeValue.z -= NudgeDistance;
	SelPtr -= SEL_AVID;
	if (IsMap) {
		integer DetPtr = llList2Integer(Selections, SelPtr + SEL_OBD_PTR);
		key WorldId = llList2Key(DetachedObjects, DetPtr + DO_OBJECT_ID);
		key IconId = llList2Key(DetachedObjects, DetPtr + DO_ICON_ID);
		list ObjectDetails = llGetObjectDetails(WorldId, [ OBJECT_POS, OBJECT_ROT ]);
		vector WorldPos = llList2Vector(ObjectDetails, 0);
		rotation WorldRot = llList2Rot(ObjectDetails, 1);
		WorldPos += NudgeValue * MAP_NUDGE_ROT;
		MoveIconOnly(IconId, WorldPos, WorldRot);
		MoveWorldObjectOnly(WorldId, WorldPos, WorldRot);
		if (CursorInUse) SetCursor(TRUE, WorldId, WorldPos);
	}
	else {
		key ObjectId = llList2Key(Selections, SelPtr + SEL_OBJECT_ID);
		integer LinkNum = Uuid2LinkNum(ObjectId);
		if (LinkNum == -1) return;
		integer LPtr = llList2Integer(Selections, SelPtr + SEL_OBD_PTR);
		vector CpPos = llList2Vector(LinkedObjects, LPtr + LO_CP_POSITION);
		list Params = llGetLinkPrimitiveParams(LinkNum, [ PRIM_POS_LOCAL, PRIM_ROT_LOCAL ]);
		vector LocalPos = llList2Vector(Params, 0);
		rotation LocalRot = llList2Rot(Params, 1);
		if (Cardinal) {
			LocalPos += NudgeValue;
			CpPos += NudgeValue;
		}
		else { // relative to user's camera
			vector CameraRotVector = llRot2Euler(CameraRot);
			rotation AdjustRot = llEuler2Rot(<0.0, 0.0, CameraRotVector.z> );
			AdjustRot = AdjustRot / llGetRot();
			LocalPos += NudgeValue * AdjustRot;
			if (DistanceExceeded(LocalPos, TRUE)) return;
			CpPos += NudgeValue * AdjustRot;
		}
		MovePrim(ObjectId, LocalPos, LocalRot, TRUE);
		LinkedObjects = llListReplaceList(LinkedObjects, [ CpPos ], LPtr + LO_CP_POSITION, LPtr + LO_CP_POSITION);
	}
}
AdjustNudgeFactor(integer Increase) {
	if (Increase)
		NudgeDistance *= NudgeFactor;
	else
		NudgeDistance *= (1.0 / NudgeFactor);
	if (NudgeDistance < 0.01) NudgeDistance = 0.01;
	else if (NudgeDistance > 10.0) NudgeDistance = 10.0;
	SendNudgeStatus();
	//if (UserId != NULL_KEY) llRegionSayTo(UserId, 0, "Nudge amount is " + NiceFloat(NudgeDistance) + "m");
}
// Send nudge data to HUD status line
SendNudgeStatus() {
	llMessageLinked(LINK_SET, LM_HUD_STATUS, "Amount: " + NiceFloat(NudgeDistance) + "m      Camera: $C°", UserId);	// $C expands to camera angle in HUD
}
// Return true if avatar is administrator
integer IsAdmin(key AvId) {
	if (AvId == OwnerId) return TRUE;
	string ThisName = llToUpper(llKey2Name(AvId));
	if (llGetInventoryType(ADMINS_NOTECARD) != INVENTORY_NOTECARD) return TRUE;    // if the notecard doesn't exist, allow it
	integer AdminsCount = osGetNumberOfNotecardLines(ADMINS_NOTECARD);
	while(AdminsCount--) {
		string Name = llToUpper(llStringTrim(osGetNotecardLine(ADMINS_NOTECARD, AdminsCount), STRING_TRIM));
		if (Name == ThisName) return TRUE;
	}
	return FALSE;
}
// Add entry/entries to Reserved Touch Faces data
ReserveTouch(key ObjectId, string Data) {
	list Faces = llCSV2List(Data);
	integer Ptr = llGetListLength(Faces);
	while(Ptr--) {
		integer Face = (integer)llList2String(Faces, Ptr);
		ReservedTouchFaces += [ ObjectId, Face ];		// we store Face as -ve to enable searching on link number
	}
}
// Serialise all object data to a Base64 string. If a name is specified, tell the Scene
// File Manager to save to notecard of that name.
string SaveData(string SaveName) {
	llMessageLinked(SfmLinkNum(), SFM_DELETE, SaveName, UserId);
	SetPrimIds();
	// Header data
	list Data = [
		"{",
		"    Section: General",
		"    Version: " + SAVE_FILE_VERSION,
		"    SavedBy: " + llKey2Name(UserId),
		"    NextID: " + (string)NextPrimId,
		"}"
			];
	// Environment section. This is put together by the environment script; we just dump it to the file
	if (EnvironmentValues != []) {
		Data += [ "{","    Section: Environment" ] + EnvironmentValues + [ "}" ];
	}
	// Modules section (list of all modules used for objects in this scene)
	Data += [ "", "{", "    Section: Modules" ] + ListModules() + [ "}" ];
	// Linked objects data
	integer Len = llGetListLength(LinkedObjects);
	integer O;
	for (O = 0; O < Len; O += LO_STRIDE) {
		Data += LinkedObjectSaveData(O);
	}
	// Detached objects data
	Len = llGetListLength(DetachedObjects);
	for (O = 0; O < Len; O += DO_STRIDE) {
		Data += DetachedObjectSaveData(O);
	}
	string SerializedData =  llStringToBase64(llDumpList2String(Data, "\n"));
	if (SaveName != "") {
		string SaveParams = SaveName + "|" + SerializedData;
		llMessageLinked(SfmLinkNum(), SFM_SAVE, SaveParams, UserId);
	}
	return SerializedData;
}
list ListModules() {
	list LibKeys = [];
	integer O;
	// Linked objects
	integer Len = llGetListLength(LinkedObjects);
	for (O = 0; O < Len; O += LO_STRIDE) {
		key ObjectId = llList2Key(LinkedObjects, O + LO_OBJECT_ID);
		integer LinkNum = Uuid2LinkNum(ObjectId);
		if (LinkNum == -1) return [];
		// Some bad naming here. LibKey is a unique integer identifier for each
		// library module, and has nothing to do with UUID keys. 
		integer LibKey = GetLibKey(llGetLinkName(LinkNum));
		if (llListFindList(LibKeys, [ LibKey ]) == -1) LibKeys += LibKey;
	}
	// Detached objects
	Len = llGetListLength(DetachedObjects);
	for (O = 0; O < Len; O += DO_STRIDE) {
		key Uuid = llList2Key(DetachedObjects, O + DO_OBJECT_ID);
		integer LibKey = GetLibKey(llKey2Name(Uuid));
		if (llListFindList(LibKeys, [ LibKey ]) == -1) LibKeys += LibKey;
	}
	list Data = [];	// return data
	Len = llGetListLength(LibKeys);
	for (O = 0; O < Len; O++) {
		integer LibKey = llList2Integer(LibKeys, O);
		integer P = llListFindList(ModulesList, [ LibKey ]);
		if (P > -1) {
			Data += "    Module: " + llList2String(ModulesList, P - MOD_LIB_KEY + MOD_NAME);
		}
	}
	return Data;
}
// Return libkey for object (ie pointer to the modules table)
integer GetLibKey(string ObjectName) {
	integer Ptr = llListFindList(ObjectModules, [ ObjectName ]);
	if (Ptr == -1) { LogError("Object missing from object modules list: " + ObjectName); return -1; }
	return llList2Integer(ObjectModules, Ptr + 1);
}
list LinkedObjectSaveData(integer LoPtr) {
	key ObjectId = llList2Key(LinkedObjects, LoPtr + LO_OBJECT_ID);
	integer LinkNum = Uuid2LinkNum(ObjectId);
	if (LinkNum == -1) return [];
	vector CpPos = llList2Vector(LinkedObjects, LoPtr + LO_CP_POSITION);
	vector CpNormal = llList2Vector(LinkedObjects, LoPtr + LO_CP_NORMAL);
	vector CpBinormal = llList2Vector(LinkedObjects, LoPtr + LO_CP_BINORMAL);
	string ExtraData = llList2String(LinkedObjects, LoPtr + LO_EXTRA_DATA);
	vector OriginalSize = llList2Vector(LinkedObjects, LoPtr + LO_ORIG_SIZE);
	vector ActualSize = llList2Vector(LinkedObjects, LoPtr + LO_ACTUAL_SIZE);
	float SizeFactor = llList2Float(LinkedObjects, LoPtr + LO_SIZE_FACTOR);
	
	integer InternalId = GetInternalId(LinkNum);
	if (InternalId == -1) {
		LogError("Invalid prim found during save: " + llGetLinkName(LinkNum));
		return [];
	}

	list PrimParams = llGetLinkPrimitiveParams(LinkNum, [ PRIM_NAME, PRIM_POS_LOCAL, PRIM_ROT_LOCAL, PRIM_SIZE ]);
	string ObjectName = llList2String(PrimParams, 0);
	vector Pos = llList2Vector(PrimParams, 1);
	rotation RotR = llList2Rot(PrimParams, 2);
	vector RotV = llRot2Euler(RotR) * RAD_TO_DEG;	

	// We use the AutoHides table because if we're a child App we don't have the library loaded.
	integer AutoHide = (llListFindList(AutoHides, [ ObjectName ]) > -1);
	if (AutoHide) {
		// We have to do it this way for autohide objects because they might be 
		// in a shrunk state at the time this is expected (when this is a child app
		// being backed up by the parent, and hence signed out).
		ActualSize = OriginalSize * SizeFactor;
	}
	else {
		ActualSize = llList2Vector(PrimParams, 3);
	}
	
	list Data = [
		"",
		"{",
		"    Section: Linked",
		"    Name: " + ObjectName,
		"    InternalId: " + (string)InternalId,
		"    Pos: " + NiceVector(Pos),
		"    Rot: " + NiceVector(RotV),
		"    OrigSize: " + NiceVector(OriginalSize),
		"    Size: " + NiceVector(ActualSize),
		"    SizeFactor: " + NiceFloat(SizeFactor),
		"    CpPos: " + NiceVector(CpPos),
		"    CpNormal: " + NiceVector(CpNormal),
		"    CpBinormal: " + NiceVector(CpBinormal)
			];
	if (ExtraData != "") Data += "    ExtraData: " + llStringToBase64(ExtraData);
	Data += "}";
	return Data;
}
list DetachedObjectSaveData(integer Ptr) {
	key ObjectId = llList2Key(DetachedObjects, Ptr + DO_OBJECT_ID);
	float SizeFactor = llList2Float(DetachedObjects, Ptr + DO_SIZE_FACTOR);
	string ExtraData = llList2String(DetachedObjects, Ptr + DO_EXTRA_DATA);
	list ObjectDetails = llGetObjectDetails(ObjectId, [ OBJECT_NAME, OBJECT_POS, OBJECT_ROT ]);
	string ObjectName = llList2String(ObjectDetails, 0);
	vector Pos = llList2Vector(ObjectDetails, 1);
	vector LocalPos = RegionPos2LocalPos(Pos);
	rotation RotR = llList2Rot(ObjectDetails, 2);
	vector RotV = llRot2Euler(RotR) * RAD_TO_DEG;
	if (IsMap) ObjectName = GetBaseName(ObjectName);	// the "W" suffix isn't needed in the save file
	list Data = [
		"",
		"{",
		"    Section: Detached",
		"    Name: " + ObjectName,
		"    Pos: " + NiceVector(LocalPos),
		"    Rot: " + NiceVector(RotV),
		"    SizeFactor: " + NiceFloat(SizeFactor)
			];
	if (ExtraData != "") Data += "    ExtraData: " + llStringToBase64(ExtraData);
	// Now the saved data of an app rezzed by a map
	if (IsObjectAnAppByName(ObjectName)) {
		string AppData = llList2String(DetachedObjects, Ptr + DO_APP_DATA);
		if (AppData != "") {
			integer ChunkSize = 120;	// String will be split into chunks of this size
			integer DataSize = llStringLength(AppData);
			integer ChunksCount = DataSize / ChunkSize + 1;
			integer C;
			for (C = 0; C < ChunksCount; C++) {
				integer From = C * ChunkSize;
				if (From < DataSize) {
					integer To = From + ChunkSize - 1;
					if (To >= DataSize) To = -1;
					string Chunk = llGetSubString(AppData, From, To);
					Data += "    Data: " + Chunk;
				}
			}
		}
	}
	Data += "}";
	return Data;
}
// Given hashed data from a parent app/map during a restore, we decode that and process it
// Format of data is scenes separated by ^
// Each scene is base64 encoded and contains <name>|<data> (empty name means currently loaded scene)
// <data> is further base64 encoded
RestoreAppData(string WholeData) {
//	llMessageLinked(SfmLinkNum(), SFM_DELETE_ALL, "", UserId);
	WholeData = llBase64ToString(WholeData);
	if (llGetSubString(WholeData, -1, -1) == "^") {
		// If there are no saved scenes, we get a separator at the end of the data string
		// that we don't want.
		WholeData = llGetSubString(WholeData, 0, -2);
	}
	list Scenes = llParseStringKeepNulls(WholeData, [ "^" ], []);	// each scene's data is separated by ^
	integer SceneCount = llGetListLength(Scenes);
	integer ScenePtr;
	for (ScenePtr = 0; ScenePtr < SceneCount; ScenePtr++) {
		string SceneEntry = llList2String(Scenes, ScenePtr);
		list Parts = llParseStringKeepNulls(SceneEntry, [ "|" ], []);
		string SceneName = llList2String(Parts, 0);
		string SceneData64 = llList2String(Parts, 1);
		if (SceneName == "") {	// if scene name if blank, it's a scene to be loaded
			string SceneData = llBase64ToString(SceneData64);
			list SceneDataList = llParseStringKeepNulls(SceneData, [ "\n" ], []);
			LoadData(UserId, SceneDataList, [ "", TRUE, TRUE ]);	// List is metadata: filename, creategroup, quiet
		}
		else {	// if scene name is not blank, it's a saved file that needs to be sent to the SFM
			string SaveParams = SceneName + "|" + SceneData64;
			llMessageLinked(SfmLinkNum(), SFM_SAVE, SaveParams, UserId);
		}
	}
}
// Get prim parameter values for the specified moveable prim
// returns null string if not a moveable prim
// Request SFM to load a notecard
RequestLoad(key AvId, string NotecardName, integer CreateGroup, integer Quiet) {
	list Parts = [ NotecardName, CreateGroup, Quiet ];
	llMessageLinked(SfmLinkNum(), SFM_LOAD, llDumpList2String(Parts, "|"), AvId);
}
// Get link number of Scene File Manager prim
integer SfmLinkNum() {
	integer LinkNum = osGetLinkNumber(SFM_NAME);
	if (LinkNum == -1) LinkNum = LINK_ALL_CHILDREN; // better than leaving it as -1`111111
	return LinkNum;
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
string NiceVector(vector V) {
	return ("<" + NiceFloat(V.x) + "," + NiceFloat(V.y) + "," + NiceFloat(V.z) + ">") ;
}
// Makes a nice string from a float - eg "0.1" instead of "0.100000", or "0.2" instead of "0.199999".
string NiceFloat(float F) {
	float X = 0.0001;
	if (F < 0.0) X = -X;
	string S = (string)(F + X);
	integer P = llSubStringIndex(S, ".");
	S = llGetSubString(S, 0, P + 3);
	while (llGetSubString(S, -1, -1) == "0" && llGetSubString(S, -2, -2) != ".")
		S = llGetSubString(S, 0, -2);
	return(S);
}
// Take data from notecard, etc and create objects accordingly
// AvId is avatar requesting load(not necessarily avatar(s) whose data it is)
integer LoadData(key AvId, list Data, list MetaData) {
	if (DebugMode) Debug("Loading scene (" + (string)llGetListLength(Data) + " lines)");
	string Filename = llList2String(MetaData, 0);
	integer CreateGroup = (integer)llList2String(MetaData, 1);
	integer Quiet = (integer)llList2String(MetaData, 2);
	MemorySizeObject = "";    // break the chain of same-named objects
	SendAppData = [];
	
	// Check the hash is valid
	Data = StripEndLines(Data);	// get rid of blank lines at the end of the card
	
	integer DataCount = llGetListLength(Data);
	
	// Scene files used to have a hash value at the end to detect tinkering, but that became an
	// issue because loaded and saved data had to match exactly to the byte.
	string FileHash = llList2String(Data, DataCount - 1);	// Get last line, where hash might be
	if (llGetSubString(FileHash, 0, 4) == "&CHK:" || FileHash == "ignorehash") {	// If the last line is hash data
		Data = llDeleteSubList(Data, -1, -1);	// delete the hash data
	}
	// Now we're sure we're going to load a scene
	LoadingWithParent = (Filename == ""); // If Filename is blank, we're loading on behalf of a parent app/mapp
	LoadingScene = TRUE;
	list ModulesNeeded = [];
	// Defaults for whole card
	integer ThisVersion = 0;
	// Declarations for object fields
	integer Detached;
	string ObjectName;
	string SavedBy;
	vector ObjectPos;
	rotation ObjectRot;
	vector OriginalSize;
	vector ActualSize;
	float SizeFactor;
	vector CPPos;
	vector CPNormal;
	vector CPBinormal;
	string ExtraData;
	integer InternalId;
	string AppData;
	// Initialise tables that store the objects' data
	list MakeLinkedObjects = [];
	list MakeDetachedObjects = [];
	integer ObjectsInFile = 0;
	// Now process the data
	integer DataPtr;
	string CurrentSection = "invalid";
	if (DebugMode) Debug("Parsing lines of notecard: " + (string)DataCount);	
	for (DataPtr = 0; DataPtr < DataCount; DataPtr++) {
		string Line = llStringTrim(llList2String(Data, DataPtr), STRING_TRIM);
		if (Line == "{") {
			CurrentSection = "";
		}
		else if (Line == "}") {
			if (CurrentSection == "linked") {
				if (DistanceExceeded(ObjectPos, TRUE)) { // Check distance limit
					llMessageLinked(LINK_SET, LM_FAILURE, "Distance limit exceeded", UserId);
					return FALSE;	
				}				
				if (SizeExceeded(ActualSize)) { // Check size limit
					llMessageLinked(LINK_SET, LM_FAILURE, "Size limit exceeded", UserId);
					return FALSE;		
				}				
				// If you change this list, change the vaue of LinkedStride below!
				MakeLinkedObjects += [
					ObjectName,
					ObjectPos,
					ObjectRot,
					OriginalSize,
					ActualSize,
					SizeFactor,
					CPPos,
					CPNormal,
					CPBinormal,
					ExtraData,
					InternalId
						];
				ObjectsInFile++;
			}
			else if (CurrentSection == "detached") {
				// Detached objects in Apps (but not Maps) have their position saved as local coordinates
				vector ActualPos;
				if (IsMap) 
					ActualPos = ObjectPos;
				else
					ActualPos = LocalPos2RegionPos(ObjectPos);
				if (DistanceExceeded(ActualPos, FALSE)) {  // Check distance limit
					llMessageLinked(LINK_SET, LM_FAILURE, "Distance limit exceeded", UserId);
					return FALSE;	
				}
				// If you change this list, change the value of DetachedStride below!
				MakeDetachedObjects += [
					ObjectName,
					ActualPos,
					ObjectRot,
					SizeFactor,
					ExtraData,
					AppData
						];
				ObjectsInFile++;
			}
			else if (CurrentSection == "modules" || CurrentSection == "general" || CurrentSection == "environment") {
				// Nothing to do here
			}
			else {
				LogError("Invalid section in save file '" + Filename + "' on line " + (integer)(DataPtr + 1));
				return FALSE;
			}
		}
		else if (Line == "") {
			// ignore empty lines
		}
		else {
			integer Colon = llSubStringIndex(Line, ":");
			if (Colon == -1) {
				Message(AvId, "Invalid save file: " + Filename);
			}
			string Name = llStringTrim(llToLower(llGetSubString(Line, 0, Colon - 1)), STRING_TRIM);
			string Value = llStringTrim(llGetSubString(Line, Colon + 1, -1), STRING_TRIM);
			// Process this entry
			if (CurrentSection == "") {	// we're on a new section
				if (Name == "section") {
					CurrentSection = llToLower(Value);
					// Now we know the section type, we can initialise it
					if (CurrentSection == "linked" || CurrentSection == "detached") {
						Detached = FALSE;
						// Initialise object fields with default values (for both linked & detached for simplicity)
						ObjectName = "";
						SavedBy = "";
						ObjectPos = ZERO_VECTOR;
						ObjectRot = ZERO_ROTATION;
						OriginalSize = VEC_NAN;
						ActualSize = VEC_NAN;
						SizeFactor = 1.0;
						CPPos = ZERO_VECTOR;
						CPNormal= ZERO_VECTOR;
						CPBinormal = ZERO_VECTOR;
						ExtraData = "";
						ObjectName = "";
						InternalId = 0;
						AppData = "";
					}
				}
			}
			else if (CurrentSection == "general") {
				if 		(Name == "version") 			ThisVersion = (integer)Value;
				else if	(Name == "nextid") 				NextPrimId = (integer)Value;
				else if	(Name == "savedby") 			SavedBy = Value;
				else if (Name == "objects")			; // no longer used
				else {
					LogError("Invalid definition in save file '" + Filename + "' on line " + (integer)(DataPtr + 1));
					return FALSE;
				}
			}
			else if (CurrentSection == "modules") {
				if (Name == "module") {
					ModulesNeeded += Value;
				}
			}
			else if (CurrentSection == "linked") {
				if 		(Name == "name")				ObjectName = Value;
				else if	(Name == "internalid") 		InternalId = (integer)Value;
				else if	(Name == "pos") 				ObjectPos = (vector)Value;
				else if	(Name == "rot") 				ObjectRot = llEuler2Rot((vector)Value * DEG_TO_RAD);
				else if	(Name == "origsize") 			OriginalSize = (vector)Value;
				else if	(Name == "size") 				ActualSize = (vector)Value;
				else if	(Name == "sizefactor") 		SizeFactor = (float)Value;
				else if	(Name == "cppos") 			CPPos = (vector)Value;
				else if	(Name == "cpnormal") 			CPNormal = (vector)Value;
				else if	(Name == "cpbinormal")			CPBinormal = (vector)Value;
				else if	(Name == "extradata")			ExtraData = llBase64ToString(Value);
				else {
					LogError("Invalid definition in save file '" + Filename + "' on line " + (integer)(DataPtr + 1));
					return FALSE;
				}
			}
			else if (CurrentSection == "detached") {
				if 		(Name == "name")				ObjectName = Value;
				else if	(Name == "pos") 				ObjectPos = (vector)Value;
				else if	(Name == "rot") 				ObjectRot = llEuler2Rot((vector)Value * DEG_TO_RAD);
				else if	(Name == "sizefactor") 		SizeFactor = (float)Value;
				else if	(Name == "extradata")			ExtraData = llBase64ToString(Value);
				else if	(Name == "data")				AppData += Value;
				else {
					LogError("Invalid definition in save file '" + Filename + "' on line " + (integer)(DataPtr + 1));
					return FALSE;
				}
			}
			else if (CurrentSection == "environment") {
				llMessageLinked(LINK_ROOT, ENV_SET_VALUE, llList2CSV([ Name, Value, TRUE, FALSE ]), UserId);
			}
			else {
				LogError("Invalid definition in save file '" + Filename + "' on line " + (integer)(DataPtr + 1));
			}
		}
	}
	// Check objects limit 
	if (ObjectsLimit > 0 && (ObjectsCount + ObjectsInFile) > ObjectsLimit) {
		Debug("Too many objects!");
		llMessageLinked(LINK_SET, LM_FAILURE, "Too many objects (" + (string)ObjectsInFile + ")", UserId);
		return FALSE;		
	}
	// Now we've built up the lists of objects, time to process it all
	if (ThisVersion != SAVE_FILE_VERSION && Filename != "") {	// Blank filename denotes load from saved App data (from parent Map), so no version
		Debug("Version conflict!");
		string Message = "Version conflict!\n\n"
			+ "got: " + (string)ThisVersion + "\nexpected: " + (string)SAVE_FILE_VERSION;
		llMessageLinked(LINK_SET, LM_FAILURE, Message, UserId);
		return FALSE;
	}
	// Check that we have all the modules needed
	list ModulesMissing = [];
	integer Len = llGetListLength(ModulesNeeded);
	integer M;
	for (M = 0; M < Len; M++) {
		string ModuleName = llList2String(ModulesNeeded, M);
		integer P = llListFindList(ModulesList, [ ModuleName ]);	// check that the needed module is in Modules table
		if (P == -1) ModulesMissing += ModuleName;
	}
	if (ModulesMissing != []) {
		Debug("Missing modules!");
		string Message = "This scene uses module(s)\nyou don't have:\n\n" + llDumpList2String(ModulesMissing, "\n");
		llMessageLinked(LINK_SET, LM_FAILURE, Message, UserId);
		return FALSE;
	}
	Debug("Finished parsing notecard");	
	list ObjectsToRez = [];
	integer LinkedCount = llGetListLength(MakeLinkedObjects);
	integer LinkedStride = 11;	// the number of columns per row of data
	if (!IsMap) {
		// First, we build a table of [ !Id, LinkNum ]
		// (we include the ! to make it searchable without ambiguity)
		list PrimId2LinkNum = GetPrimId2LinkNum();
		// 	Process those lists we just created and create the objects
		list Params = [];
		integer Lptr;
		for (Lptr = 0; Lptr < LinkedCount; Lptr += LinkedStride) {
			ObjectName = llList2String(MakeLinkedObjects, Lptr);
			ObjectPos = (vector)llList2String(MakeLinkedObjects, Lptr + 1);
			ObjectRot = (rotation)llList2String(MakeLinkedObjects, Lptr + 2);
			OriginalSize = (vector)llList2String(MakeLinkedObjects, Lptr + 3);
			ActualSize = (vector)llList2String(MakeLinkedObjects, Lptr + 4);
			SizeFactor = (float)llList2String(MakeLinkedObjects, Lptr + 5);
			CPPos = (vector)llList2String(MakeLinkedObjects, Lptr + 6);
			CPNormal= (vector)llList2String(MakeLinkedObjects, Lptr + 7);
			CPBinormal = (vector)llList2String(MakeLinkedObjects, Lptr + 8);
			ExtraData = llList2String(MakeLinkedObjects, Lptr + 9);
			
			InternalId = (integer)llList2String(MakeLinkedObjects, Lptr + 10);
			
			// We used to use "!WT" at the start of extra data (part of the PRIM_TEXT fudge), but we don't need that any more,
			// so we strip it out from save files that predate that change.
			if (llGetSubString(ExtraData, 0, 2) == "!WT") ExtraData = llGetSubString(ExtraData, 3, -1);

			if (CreateGroup) {
				integer NewPrimId = InternalId;        // this will be the prim id of the new prim, by default the same as in the save file
				integer P = llListFindList(PrimId2LinkNum, [ "!" + (string)InternalId ]);    // does the prim ID exist in the current model?
				if (P > -1) NewPrimId = 0;        // if it does, set it to 0 and we'll allocate a new one later
				NewObjects += [ AvId, ObjectName, NOB_TYPE_GROUP, NULL_KEY,
					ObjectPos, ObjectRot,
					VEC_NAN, -1, VEC_NAN, CPPos, CPNormal, CPBinormal,
					NewPrimId, ExtraData, OriginalSize, ActualSize, SizeFactor, NULL_KEY ];
				ObjectsToLoad++;
				ObjectsToRez += ObjectName;	// Trigger creation of object
			}
			else {
				integer P = llListFindList(PrimId2LinkNum, [ "!" + (string)InternalId ]);
				if (P > -1) {    // ie the prim still exists
					integer LinkNum = llList2Integer(PrimId2LinkNum, P + 1);
					if (!SizeExceeded(ActualSize)) {
						Params += PrimLinkTarget("ML", LinkNum) + [ PRIM_SIZE, ActualSize ];
					}
					key ObjectId = llGetLinkKey(LinkNum);
					MovePrim(ObjectId, ObjectPos, ObjectRot, FALSE);
				}
			}
		}
		if (llGetListLength(Params)) llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
	}
	Debug("Finished queuing linked objects");	
	integer DetachedCount = llGetListLength(MakeDetachedObjects);
	integer DetachedStride = 6;	// the number of columns per row of data
	integer DPtr;
	for (DPtr = 0; DPtr < DetachedCount; DPtr += DetachedStride) {
		ObjectName = llList2String(MakeDetachedObjects, DPtr);
		ObjectPos = llList2Vector(MakeDetachedObjects, DPtr + 1);
		ObjectRot = llList2Rot(MakeDetachedObjects, DPtr + 2);
		SizeFactor = llList2Float(MakeDetachedObjects, DPtr + 3);
		ExtraData = llList2String(MakeDetachedObjects, DPtr + 4);
		AppData = llList2String(MakeDetachedObjects, DPtr + 5);
		integer IsApp = IsObjectAnAppByName(ObjectName);
		if (IsApp && AppData != "") {
			SendAppData += [ ObjectName, ObjectPos, AppData ];
		}
		NewObjects += [ AvId, ObjectName, NOB_TYPE_GROUP, NULL_KEY,
			ObjectPos, ObjectRot,
			VEC_NAN, -1, VEC_NAN, // touch pos, face, ST
			ZERO_VECTOR, ZERO_VECTOR, ZERO_VECTOR, // CP pos, normal, binormal
			0, ExtraData, // Prim ID, extra data
			VEC_NAN, VEC_NAN, // orig size, actual size
			SizeFactor, 
			0 	// target link
			];
		// Trigger creation of object
		string RezError = "";
		if (IsMap) {
			ObjectsToRez += ObjectName + "I";
		}
		else {
			ObjectsToRez += ObjectName;
		}
	}
	Len = llGetListLength(ObjectsToRez);
	// Check that all objects exist
	list MissingObjects = [];
	integer R = 0;
	for (R = 0; R < Len; R++) {
		string RezObjectName = llList2String(ObjectsToRez, R);
		if (GetObjectReference(GetBaseName(RezObjectName)) == "") {
			MissingObjects += RezObjectName;
		}
	}
	if (MissingObjects != []) {
		Debug("Missing objects");
		string Message = "Missing objects:\n\n" + llDumpList2String(llList2List(MissingObjects, 0, 10), "\n");
		llMessageLinked(LINK_SET, LM_FAILURE, Message, UserId);
		NewObjects = [];
		return FALSE;
	}
	if (DebugMode) Debug("Rezzing " + (string)(DetachedCount / DetachedStride) + " linked + " + (string)(LinkedCount / LinkedStride) + " unlinked objects");
	// Rez all objects
	RezObjects(ObjectsToRez);
	if (IsMap) {
		if (DetachedCount == 0) {	// For Map saves without objects, we're finished
			if(!Quiet) Message(AvId, "'" + Filename + "' loaded.");
			llMessageLinked(LINK_SET, LM_TASK_COMPLETE, "", UserId);
		}
	}
	else {
		if(!Quiet) Message(AvId, "'" + Filename + "' loaded.");		// for maps, it happens in the CreateContinue event stuff
	}
	Debug("Scene loaded");
	// If there are no objects, release the HUD
	if (DetachedCount == 0 && LinkedCount == 0) {
		llMessageLinked(LINK_SET, LM_TASK_COMPLETE, "", UserId);
		LoadingScene = FALSE;
		return TRUE;
	}
	// If we're in "rearrange" mode, we've finished here
	else if (!CreateGroup) {
		llMessageLinked(LINK_SET, LM_TASK_COMPLETE, "", UserId);	// free up HUD
		LoadingScene = FALSE;
		return TRUE;
	}
	// If we're here, there are events to process.
	return TRUE;
}
// Called when all data has loaded.
FinishNewObjects() {
	if (LoadingScene) {	// if we've just finished loading a scene (incl. all events)
		// Any code to be executed at the end of a scene load can go here
		if (LoadingWithParent && UserId == NULL_KEY) AutoHideSet(TRUE);	
		LoadingScene = FALSE;
	}
	llMessageLinked(LINK_SET, LM_TASK_COMPLETE, "", UserId);
}
list PrimLinkTarget(string DebugInfo, integer LinkNum) {
	// we need this next check because invalid link numbers can cause huge problems with OpenSim.exe (eg high CPU that
	// persists even after object is removed from simulator; 0 objects allowed in simulator, etc). To fix, load from an
	// OAR that doesn't have the object in, and restart simulator.
	if (LinkNum <= 0) {
		LogError("Invalid link number encountered! Info: " + DebugInfo);
		LinkNum = llGetNumberOfPrims();	// Set to highest link num
	}
	return [ PRIM_LINK_TARGET, LinkNum ];
}
// Remove empty lines at the end of the data, due (I believe) to quirks of the dump/parse functions
list StripEndLines(list Data) {
	integer End = llGetListLength(Data) - 1;
	while (End > 0 && llStringTrim(llList2String(Data, End), STRING_TRIM) == "") End--;
	return llList2List(Data, 0, End);
}
vector RegionPos2LocalPos(vector RegionPos) {
	return (RegionPos - llGetRootPosition()) / llGetRootRotation();
}
vector LocalPos2RegionPos(vector LocalPos) {
	return (LocalPos * llGetRootRotation()) + llGetRootPosition();
}
// Build a table of [ !Id, LinkNum ]
// (we include the ! to make it searchable without ambiguity)
list GetPrimId2LinkNum() {
	list Ret = [];
	integer LinkNum = llGetNumberOfPrims();
	do {
		integer InternalId = GetInternalId(LinkNum);
		if (InternalId > 0) {    // it's a moveable prim with an internal ID set
			Ret += [ "!" + (string)InternalId, LinkNum ];
		}
	} while(--LinkNum > 1);
	return Ret;
}
TeleportToObject() {
	key AvId = UserId;
	vector TpPos;
	integer P = llListFindList(Selections, [ AvId ]);
	if (P == -1) {
		Message(AvId, "Select an object first, then you can teleport to it");
		return;
	}
	P -= SEL_AVID;
	key ObjectId = llList2Key(Selections, P + SEL_OBJECT_ID);
	if (IsMap) {
		TpPos = llList2Vector(llGetObjectDetails(ObjectId, [ OBJECT_POS ]), 0);
	}
	else {
		integer SelectedLinkNum = Uuid2LinkNum(ObjectId);
		if (SelectedLinkNum == -1) return;
		TpPos = llList2Vector(llGetLinkPrimitiveParams(SelectedLinkNum, [ PRIM_POSITION ]), 0);
	}
	vector LookAt = TpPos;
	TpPos.z += 10.0;
	osTeleportAgent(AvId, TpPos, TpPos);
}
ZoomToObject() {
}
// Sets the ID number of any moveable prims that don't have one
SetPrimIds() {
	// We do this in two passes.
	// First pass is to find the next prim id
	NextPrimId = 1;
	integer LinkNum = llGetNumberOfPrims();
	do {
		integer InternalId = GetInternalId(LinkNum);
		if (InternalId > 0) {    // if it's an MLO with an ID set
			if (InternalId >= NextPrimId) NextPrimId = InternalId + 1;    // keep NextPrimId higher than any current Id
		}
	} while(--LinkNum > 1);
	list UsedIds = [];
	// Second pass is to give Ids to those prims that don't have them (now we know where to start)
	// Also, we detect duplicates here and change them
	LinkNum = llGetNumberOfPrims();
	do {
		integer InternalId = GetInternalId(LinkNum);
		if (InternalId > -1) {    // if it's a moveable prim
			if (!InternalId || (llListFindList(UsedIds, [ InternalId ]) > -1)) { // if it doesn't have an Id, or the id's a duplicate
				InternalId = NextPrimId++;
				SetPrimId(LinkNum, InternalId);    // set the id to NextPrimId and increment
			}
			UsedIds += InternalId;
		}
	} while(LinkNum--);
}
ReadConfig() {
	if (WriteConfig) return;	// the config card has been deleted prior to rewriting
	// Set config defaults
	ScoreboardChannel = "ML";
	MailboxChannel = "M";
	CommandChatChannel = 51;
	AdvancedMenu = FALSE;
	HideOptions = "";
	ErrorEmail = "";
	ViewOnly = FALSE;
	DefaultNudgeDistance = 1.0;
	NudgeFactor = 1.25;
	IsMap = FALSE;
	BoardPrimName = "&cboard";
	BoardFace = 0;
	CursorPrimName = "&cursor";
	CursorSize = <3.0, 3.0, 22.0>;
	CursorAlpha = 1.0;
	CursorHeight = 10.0;
	WorldSize = RegionSize;
	WorldSize.z = 0.0;	// WorldSize has no Z dimension
	WorldOrigin = <0.0, 0.0, 21.0>;
	BoardOffset = ZERO_VECTOR;
	RezPosition = ZERO_VECTOR;
	ScalingFactor = 0.0;
	IconHoverTextColour = <1.0, 1.0, 1.0>;
	IconHoverTextAlpha = 1.0;
	IconSelectGlow = 0.3;
	LinkedSelectGlow = 0.04;
	IconSelectParticleColour = ZERO_VECTOR;        // NULL means avatar-specific colour
	Locked = FALSE;
	EnvironmentalChange = FALSE;
	TerrainChange = FALSE;
	DefaultSeaLevel = 20.0;
	DefaultLandLevel = 21.0;
	CheckboxOn = "☑";
	CheckboxOff = "☐";
	ModuleSize = <0.2, 0.2, 0.05>;
	ModulePosNormal = <0.0, 0.0, 4.0>;
	ModulePosHidden = <0.0, 0.0, 0.01>;
	MaxAvatars = 100;
	string EncodedLimits = "";
	DummyMoveSet = FALSE;
	LinkBatchSize = 20;
	UnlinkBatchSize = 20;
	RezBatchSize = 100;
	//
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		//LogError("Can't find notecard '" + CONFIG_NOTECARD + "'");
		llOwnerSay("Can't find notecard '" + CONFIG_NOTECARD + "' - execution suspended");
		state Hang;
	}
	integer IsOK = FALSE;
	integer Lines = osGetNumberOfNotecardLines(CONFIG_NOTECARD);
	integer I;
	for(I = 0; I < Lines; I++) {
		string Line = osGetNotecardLine(CONFIG_NOTECARD, I);
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
					if (Name == "scoreboard")    ScoreboardChannel = StripQuotes(Value, Line);
					else if (Name == "mailbox")    MailboxChannel = StripQuotes(Value, Line);
					else if (Name == "commandchatchannel") CommandChatChannel = (integer)Value;
					else if (Name == "advancedmenu")	AdvancedMenu = String2Bool(Value);
					else if (Name == "hideoptions") HideOptions = Value;
					else if (Name == "erroremail") ErrorEmail = Value;
					else if (Name == "viewonly")	ViewOnly = String2Bool(Value);
					else if (Name == "nudgedistance") DefaultNudgeDistance = (float)Value;
					else if (Name == "nudgefactor") NudgeFactor = (float)Value;
					else if (Name == "map")	IsMap = String2Bool(Value);
					else if (Name == "boardprimname")	BoardPrimName = StripQuotes(Value, Line);
					else if (Name == "boardface")	BoardFace = (integer)Value;
					else if (Name == "boardoffset") BoardOffset = (vector)Value;
					else if (Name == "cursorprimname")	CursorPrimName = StripQuotes(Value, Line);
					else if (Name == "cursorsize")	CursorSize = (vector)Value;
					else if (Name == "cursorheight") CursorHeight = (float)Value;
					else if (Name == "cursoralpha") CursorAlpha = (float)Value;
					else if (Name == "worldsize")	WorldSize = (vector)Value;
					else if (Name == "worldorigin")	WorldOrigin = (vector)Value;
					else if (Name == "rezposition")	RezPosition = (vector)Value;
					else if (Name == "scalingfactor") ScalingFactor = (float)Value;
					else if (Name == "iconselectglow") IconSelectGlow = (float)Value;
					else if (Name == "linkedselectglow") LinkedSelectGlow = (float)Value;
					else if (Name == "iconselectparticlecolor") IconSelectParticleColour = (vector)Value / 256.0;
					else if (Name == "iconhovertextcolor") IconHoverTextColour = (vector)Value;
					else if (Name == "iconhovertextalpha") IconHoverTextAlpha = (float)Value;
					else if (Name == "locked") Locked = String2Bool(Value);
					else if (Name == "environmentalchange") EnvironmentalChange = String2Bool(Value);
					else if (Name == "defaultsealevel") DefaultSeaLevel = (float)Value;
					else if (Name == "defaultlandlevel") DefaultLandLevel = (float)Value;
					else if (Name == "checkboxon") CheckboxOn = Value;
					else if (Name == "checkboxoff") CheckboxOff = Value;
					else if (Name == "terrainchange") TerrainChange = String2Bool(Value);
					else if (Name == "modulesize") ModuleSize = (vector)Value;
					else if (Name == "moduleposnormal") ModulePosNormal = (vector)Value;
					else if (Name == "moduleposhidden") ModulePosHidden = (vector)Value;
					else if (Name == "maxavatars") MaxAvatars = (integer)Value;
					else if (Name == "primsource") EncodedLimits = Value;
					else if (Name == "dummymove") DummyMoveSet = String2Bool(Value);
					else if (Name == "linkbatchsize") LinkBatchSize = (integer)Value;
					else if (Name == "unlinkbatchsize") UnlinkBatchSize = (integer)Value;
					else if (Name == "rezbatchsize") RezBatchSize = (integer)Value;
					else {
						LogError("Invalid entry in " + CONFIG_NOTECARD + ":\n" + Line);
					}
				}
			}
		}
	}
	if (ErrorEmail == "") llDialog(llGetOwner(), "\n\nWARNING\n\n'ErrorEmail' missing from ML config", [ "OK" ], -99999819);
	if (EncodedLimits == "") {
		llDialog(llGetOwner(), "\n\nERROR\n\n'PrimSource' missing from ML config", [ "OK" ], -99999819);
		state Hang;
	}
	NudgeDistance = DefaultNudgeDistance;
	// We have to use llXorBase64StringsCorrect because llXorBase64 isn't available in OpenSim
	string Decoded64 = llXorBase64StringsCorrect(EncodedLimits, llStringToBase64(LIMITS_KEY));
	string Decoded = llBase64ToString(Decoded64);
	list Parts = llParseStringKeepNulls(Decoded, [ "|" ], []);
	ObjectsLimit = (integer)llList2String(Parts, 0);
	SizeLimit = (float)llList2String(Parts, 1);
	DistanceLimit = (float)llList2String(Parts, 2);		
	llMessageLinked(LINK_SET, LM_LOCKED, (string)Locked, NULL_KEY);
	SendPublicData();
}
// Change a single entry in the config file. If Value is empty, the entry is deleted.
// If the Name line is not found, it is added.
// Do not call this function twice in the same event. Otherwise the card will be blanked.
ChangeConfig(string Name, string Value) {
	string LName = llToLower(Name);
	NewConfig = [];
	integer Found = FALSE;
	integer Lines = osGetNumberOfNotecardLines(CONFIG_NOTECARD);
	integer I;
	for(I = 0; I < Lines; I++) {
		string OrigLine = osGetNotecardLine(CONFIG_NOTECARD, I);
		string Line = OrigLine;
		integer Comment = llSubStringIndex(Line, "//");
		if (Comment != 0) {    // Not a complete comment line
			if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);    // strip from comments characters onwards
			if (llStringTrim(Line, STRING_TRIM) != "") {    // if there's something left after comments are removed
				// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
				list L = llParseStringKeepNulls(Line, [ "=" ], [ ]);    // Separate LHS and RHS of assignment
				if (llGetListLength(L) == 2) {    // so there is a "X = Y" kind of syntax
					string OName = llStringTrim(llList2String(L, 0), STRING_TRIM);        // original parameter name
					string ThisName = llToLower(OName);        // lower-case version for case-independent parsing
					if (ThisName == LName) {
						Found = TRUE;
						if (Value != "") {
							NewConfig += Name + " = " + Value;
						}
					}
					else {
						NewConfig += OrigLine;
					}
				}
				else {
					NewConfig += OrigLine;
				}
			}
			else {
				NewConfig += OrigLine;
			}
		}
		else {
			NewConfig += OrigLine;
		}
	}	
	if (!Found && Value != "") {
		NewConfig += Name + " = " + Value;
	}	
	llRemoveInventory(CONFIG_NOTECARD);
	// If we just write it back here, we're likely to encounter the OpenSim bug that causes the delete/write
	// to fail (leaving the notecard unchanged). We have to write in another event, so we use a LM.
	WriteConfig = TRUE;	// warning to ReadConfig() not to attempt to do its thing on changed event.
	llMessageLinked(LINK_THIS, LM_WRITE_CONFIG, "", NULL_KEY);
}
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
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
		LogError("Invalid string literal (missing \"\"?): " + Line);
		return("");
	}
}
ClearStoredRotation(key AvId) {
	integer P = llListFindList(StoredRotations, [ AvId ]);
	if (P > -1) {
		StoredRotations = llDeleteSubList(StoredRotations, P, P + STO_STRIDE - 1);
	}
}
AddStoredRotation(key AvId, string ObjectName, vector SurfaceNormal, rotation Rot) {
	if (LoadingScene) return;	// We don't store rotations while we're rezzing a scene
	ClearStoredRotation(AvId);
	StoredRotations += [ AvId, ObjectName, SurfaceNormal, Rot ];
}
// Breaks CLI command into parts and executes it. PrimUuid is null for non-prim commands,
// link number of button for button commands
ExecuteCommand(key AvId, string Text, key PrimUuid, integer IsLinkMessaged) {
	// commands are in the format (eg) "load filename", so separate on space
	integer Ptr = llSubStringIndex(Text, " ");
	string Command = llToLower(llStringTrim(llGetSubString(Text, 0, Ptr), STRING_TRIM));
	Debug("Executing command: " + Command);
	string Argument = "";
	if (Ptr > -1) Argument = llStringTrim(llGetSubString(Text, Ptr + 1, -1), STRING_TRIM);
	// Special case - if they've got a create cycle running and they click on the same
	// button, we want to turn the button off (ie end the cycle) but do nothing else
	if (PrimUuid != NULL_KEY && (Command == "create" || Command == "card")) {    // if it's a create or card button
		integer C = FindNewObject(AvId, "", NOB_TYPE_CREATE_READY);
		if (C > -1) {        // do we have a creation cycle currently open?
			key ButtonId = llList2Key(NewObjects, C + NOB_BUTTON);
			if (ButtonId == PrimUuid) {    // and is it the same button?
				// If so, cancel it. This is clicking on an active create button to turn it off
				CancelCreation(AvId);
				return;
			}
		}
	}
	// We cancel any create cycle anyway
	CancelCreation(AvId);
	// First, admin-only functions
	if (IsAdmin(AvId)) {
		if (Command == "load") {
			DeSelectAll();
			RequestLoad(AvId, Argument, FALSE, TRUE);
		}
		else if (Command == "save" && Argument != "") {
			DeSelectAll();
			CheckDetachedObjectsExist();
			AppBackupsWaiting = 0;
			integer DLen = llGetListLength(DetachedObjects);
			integer DPtr;
			for (DPtr = 0; DPtr < DLen; DPtr += DO_STRIDE) {
				integer LibPtr = llList2Integer(DetachedObjects, DPtr + DO_LIB_PTR);
				if (IsObjectAnAppByPtr(LibPtr)) {	// if the object is an app
					key AppId = llList2Key(DetachedObjects, DPtr + DO_OBJECT_ID);
					if (DebugMode) Debug("Requesting app data from " + llKey2Name(AppId));	// Test to save executing Key2Name unnecessarily
					MessageObject(AppId, (string)LM_APP_BACKUP_REQUEST); // Request data from app
					AppBackupsWaiting++;
				}
			}
			if (AppBackupsWaiting > 0) {
				AppBackupSaveName = Argument;
				AppBackupsTimeout = 30;
				SetTimer();
			}
			else {
				SaveData(Argument);
			}
		}
		else if (Command == "clearall") {
			Clear();
		}
	}
	// Now, non-admin (multi-user) functions
	if (Command == "clone") {
		Clone(AvId);
	}
	else if (Command == "hide") {
		HidePrim(AvId);
	}
	else if (Command == "deselect") {
		DeselectByAvId(AvId);
	}
	else if (Command == "remove") {
		RemoveObject(AvId);
	}
	else if (Command == "rotate") {
		RotateSelectedObject(AvId, Argument);
	}
	else if (Command == "resize") {
		ResizeObjectFrontEnd(AvId, Argument);
	}
	else if (Command == "nudge") {
		ProcessNudge(Argument);
	}
	else if (Command == "create") {
		CreateStart(AvId, Argument, NULL_KEY, PrimUuid);
	}
	else if (Command == "nocreate") {
		CancelCreation(AvId);    // end creation cycle
	}
	else if (Command == "card") {
		integer LinkNum = Uuid2LinkNum(PrimUuid);
		llMessageLinked(LinkNum, LM_CARD_AVAILABLE, Argument, AvId);        // the card deck prim will return a message if there are cards available
	}
	else if (Command == "creategroup" && Argument != "") {
		RequestLoad(AvId, Argument, TRUE, TRUE);
	}
	else if (Command == "clear") {
		Clear();
	}
	else if (Command == "tp") {
		TeleportToObject();
	}
	else if (Command == "zoom") {
		ZoomToObject();
	}
	// We don't outsource if the origin is already a link message, to prevent looping
	if (!IsLinkMessaged) {
		integer LinkNum = Uuid2LinkNum(PrimUuid);
		if (LinkNum == -1) return;
		llMessageLinked(
			LINK_SET,
			LM_OUTSOURCE_COMMAND,
			llList2CSV([ Command, 0, Argument, IsAdmin(AvId), LinkNum ]),
			AvId);
	}
	Debug("Execution complete");
}
// Send message to scripts in prims in awakeners list, telling them to start processing
AwakenScripts() {
	integer A = llGetListLength(Awakeners);
	while (A--) {
		key Uuid = llList2Key(Awakeners, A);
		integer LinkNum = Uuid2LinkNum(Uuid);
		if (LinkNum == -1) return;
		llMessageLinked(LinkNum, LM_LOADING_COMPLETE, "1", UserId);
	}
	Awakeners = [];
}
// Return TRUE if the prim is a moveable prim
integer IsMoveable(key PrimId) {
	integer LinkNum = Uuid2LinkNum(PrimId);
	if (LinkNum == -1) return FALSE;
	return (GetInternalId(LinkNum) > -1);
}
// Select a prim
SelectObject(key AvId, key SelId) {
	integer SelPtr = GetSelectionPtr(AvId);            // do we already have a selection for this user?
	if (SelPtr > -1) DeselectByPtr(SelPtr);        // deselect current selection (if any)
	llRegionSay(COMMS_CHANNEL, "S" + (string)AvId);		// tell all other MLs that this user is selecting an object
	Sound(SOUND_PICK);
	if (IsMap) {
		key IconId = SelId;
		llMessageLinked(LINK_SET, LM_PRIM_SELECTED, (string)IconId, AvId);
		// First, find the ObjectData entry
		integer DetPtr = llListFindList(DetachedObjects, [ IconId ]);
		if (DetPtr == -1) { LogError("Can't find detached object to select"); return; }
		DetPtr -= DO_ICON_ID;         // position at beginning of stride
		key WorldId = llList2Key(DetachedObjects, DetPtr + DO_OBJECT_ID);    // extract world ID from objects table
		Selections += [ AvId, WorldId, IconId, DetPtr ];    // add entry to selections table
		MessageStandard(IconId, IC_SELECT, [ AvId ]);    // tell the icon it's been selected
		MessageStandard(WorldId, WO_SELECT, [ AvId ]);    // likewise for the world object
		vector Pos = llList2Vector(llGetObjectDetails(WorldId, [ OBJECT_POS ]), 0);
		SetCursor(TRUE, WorldId, ZERO_VECTOR);
	}
	else {	// It's an App, not a Map
		// Note that it must be a linked object because detached objects in Apps can't be selected (so can't be cloned)
		integer LinkNum = Uuid2LinkNum(SelId);
		if (LinkNum == -1) return;
		llMessageLinked(LINK_SET, LM_PRIM_SELECTED, (string)LinkNum, AvId);
		Highlight(LinkNum, AvId);
		integer LOPtr  = llListFindList(LinkedObjects, [ SelId ]);
		if (LOPtr  == -1) { LogError("Can't find linked object to select"); return; }
		LOPtr -= LO_OBJECT_ID;
		Selections += [ AvId, SelId, NULL_KEY, LOPtr ];
		// Store rotation data for the selected prim
		string ObjectName = llGetLinkName(LinkNum);
		vector SurfaceNormal = llList2Vector(LinkedObjects, LOPtr + LO_CP_NORMAL);
		rotation Rot = llList2Rot(llGetLinkPrimitiveParams(LinkNum, [ PRIM_ROT_LOCAL ]), 0);
		AddStoredRotation(AvId, ObjectName, SurfaceNormal, Rot);
	}
	// If there isn't a comms listener, create one
	if (!CommsChannelListener) CommsChannelListener = llListen(COMMS_CHANNEL, "", NULL_KEY, "");
}
// Deselect on basis of Av UUID
DeselectByAvId(key AvId) {
	integer SelPtr = llListFindList(Selections, [ AvId ]);
	if (SelPtr == -1) return;    // wasn't anything selected
	SelPtr -= SEL_AVID;    // position at beginning of stride
	DeselectByPtr(SelPtr);
}
// Deselect currently selected prim
DeselectByPtr(integer Ptr) {
	if (IsMap) {
		key SelIconId = llList2Key(Selections, Ptr + SEL_ICON_ID);
		key SelWorldId = llList2Key(Selections, Ptr + SEL_OBJECT_ID);
		MessageStandard(SelIconId, IC_DESELECT, []);
		MessageStandard(SelWorldId, WO_DESELECT, []);
		Selections = llDeleteSubList(Selections, Ptr, Ptr + SEL_STRIDE - 1);
		llMessageLinked(LINK_SET, LM_PRIM_DESELECTED, (string)SelIconId, NULL_KEY);
		SetCursor(FALSE, NULL_KEY, ZERO_VECTOR);	// hide cursor
	}
	else {
		key SelectedUuid = llList2Key(Selections, Ptr + SEL_OBJECT_ID);
		integer SelectedLinkNum = Uuid2LinkNum(SelectedUuid);
		if (SelectedLinkNum == -1) return;
		key AvId = llList2Key(Selections, Ptr + SEL_AVID);
		Highlight(SelectedLinkNum, NULL_KEY);
		//llMessageLinked(LINK_SET, LM_PRIM_DESELECTED, (string)SelectedLinkNum, AvId);
		Selections = llDeleteSubList(Selections, Ptr, Ptr + SEL_STRIDE -1);
		// If nothing is selected now, we don't need the comms listener
		if (Selections == [] && !CommsChannelListener) {
			llListenRemove(CommsChannelListener);
			CommsChannelListener = 0;
		}
		llMessageLinked(LINK_SET, LM_PRIM_DESELECTED, (string)SelectedLinkNum, NULL_KEY);
	}
}
// Deselect all prims
DeSelectAll() {
	integer SelLength = llGetListLength(Selections);
	integer SPtr;
	for(SPtr = 0; SPtr < SelLength; SPtr += SEL_STRIDE) {
		DeselectByPtr(SPtr);
	}
}
// Returns selected object UUID, or NULL_KEY if nothing selected
key GetSelectionUuid(key AvId) {
	integer SelPtr = GetSelectionPtr(AvId);
	if (SelPtr > -1)
		return llList2Key(Selections, SelPtr + SEL_OBJECT_ID);
	else
		return NULL_KEY;
}
// Returns pointer to selection table, or -1 of nothing selected
integer GetSelectionPtr(key AvId) {
	return llListFindList(Selections, [ AvId ]);
}
// Finds a selection by object UUID
integer FindSelectionByUuid(key ObjectId) {
	integer Ptr = llListFindList(Selections, [ ObjectId ]);
	if (Ptr == -1) return -1;
	return (Ptr - SEL_OBJECT_ID);
}
key FindSelectedIconByAvId(key AvId) {
	integer SelPtr = llListFindList(Selections, [ AvId ]);
	SelPtr -= SEL_AVID;    // position at beginning of stride
	key SelIconId = llList2Key(Selections, SelPtr + SEL_ICON_ID);
	return SelIconId;
}
// Removes entries from DetachedObjects where actual object no longer exists
CheckDetachedObjectsExist() {
	// Beware of the old problem with deleting entries in a table you're
	// processing serially. We use a temporary table to circumvent that.
	list DeletedObjects = [];
	integer Len = llGetListLength(DetachedObjects);
	integer Ptr;
	for (Ptr = 0; Ptr < Len; Ptr += DO_STRIDE) {
		key ObjectId  = llList2Key(DetachedObjects, Ptr + DO_OBJECT_ID);
		if (!ObjectExists(ObjectId)) DeletedObjects += ObjectId;
	}
	Len = llGetListLength(DeletedObjects);
	for (Ptr = 0; Ptr < Len; Ptr++) {
		key ObjectId = llList2Key(DeletedObjects, Ptr);
		integer DPtr = llListFindList(DetachedObjects, [ ObjectId ]) - DO_OBJECT_ID;
		DetachedObjects = llDeleteSubList(DetachedObjects, DPtr, DPtr + DO_STRIDE - 1);
	}
}			
// Points the cursor at the referenced object. If RegionPos is ZERO_VECTOR, the cursor position
// is taken from the object's current data, otherwise RegionPos is used. This is so we can position
// the cursor after a move without having to wait for the world object to process the move command we
// send it.
SetCursor(integer Visible, key ObjectId, vector RegionPos) {
	if (CursorLinkNum == -1) return;	// Cursor is optional - if there is none, the link num will be -1
	vector LocalToPos;
	vector LocalFromPos = llList2Vector(llGetLinkPrimitiveParams(CursorLinkNum, [ PRIM_POS_LOCAL ]), 0);
	vector Size;
	float Alpha;
	if (!Visible) {		// this makes the cursor invisible
		Alpha = 0.0;	// invisible
		Size = <0.02, 0.02, 0.02>;
		LocalToPos = ZERO_VECTOR;	// cursor is hidden inside root prim
		CursorInUse = FALSE;
	}
	else {	// we need to point at the specified object or location
		Alpha = CursorAlpha;	// visible
		Size = CursorSize;
		if (RegionPos == ZERO_VECTOR) {
			if (ObjectId == NULL_KEY) { LogError("No data for cursor"); return; }
			RegionPos = llList2Vector(llGetObjectDetails(ObjectId, [ OBJECT_POS ]), 0);
		}
		if (ObjectId != NULL_KEY) RegionPos += <0.0, 0.0, (CursorSize.z / 2.0) + CursorHeight>;
		LocalToPos= RegionPos2LocalPos(RegionPos);
		CursorInUse = TRUE;
	}
	float MoveDistance = llVecDist(LocalFromPos, LocalToPos);    // calculate distance prim will move
	integer Hops = (integer)(MoveDistance / 10.0) + 1;    // divide it into 10m hops
	list PrimParams = [];
	while(Hops--) {
		PrimParams += [ PRIM_POS_LOCAL, LocalToPos ];
	}
	PrimParams += [ PRIM_SIZE, Size ];
	llSetLinkPrimitiveParamsFast(CursorLinkNum, PrimParams);
	llSetLinkAlpha(CursorLinkNum, Alpha, ALL_SIDES);	// we have to do this separately because using SetPrimitiveParams would override the colour
}
// Position the camera or jump
SetCameraJumpLinked(key ObjectId, integer ClickType, key AvId) {
	integer LinkNum = Uuid2LinkNum(ObjectId);
	if (LinkNum == -1) return;
	integer LoPtr = llListFindList(LinkedObjects, [ ObjectId ]);
	if (LoPtr == -1) return;	// Not a linked object, so feature doesn't apply
	LoPtr -= LO_OBJECT_ID;	// position at start of stride
	float SizeFactor = llList2Float(LinkedObjects, LoPtr + LO_SIZE_FACTOR);
	vector ObjectSize = llList2Vector(llGetLinkPrimitiveParams(LinkNum, [ PRIM_SIZE ]), 0);
	// Get actual object details
	vector MyPos = llGetPos();
	rotation MyRot = llGetRot();
	list L = llGetLinkPrimitiveParams(LinkNum, [ PRIM_POS_LOCAL, PRIM_ROT_LOCAL ]);
	vector LocalPos = llList2Vector(L, 0);
	rotation LocalRot = llList2Rot(L, 1);
	vector ObjectPos = MyPos + LocalPos * MyRot;
	rotation ObjectRot = LocalRot * MyRot;
	SetCameraJump(ObjectId, LinkNum, AvId, ClickType, ObjectPos, ObjectRot, ObjectSize, SizeFactor);
}
SetCameraJumpMap(key IconId, integer ClickType, key AvId) {
	integer DoPtr = llListFindList(DetachedObjects, [ IconId ]);
	if (DoPtr == -1) return;	// Not in our data, so ignore
	DoPtr -= DO_ICON_ID;
	key ObjectId = llList2Key(DetachedObjects, DoPtr + DO_OBJECT_ID);
	float SizeFactor = llList2Float(DetachedObjects, DoPtr + DO_SIZE_FACTOR);
	// Get actual object details
	list ObjectDetails = llGetObjectDetails(ObjectId, [ OBJECT_POS, OBJECT_ROT ]);
	vector ObjectPos = llList2Vector(ObjectDetails, 0);
	rotation ObjectRot = llList2Rot(ObjectDetails, 1);
	// Calculate approximate size of whole object
	list L = llGetBoundingBox(ObjectId);
	vector ObjectSize = llList2Vector(L, 1) - llList2Vector(L, 0);
	SetCameraJump(ObjectId, -1, AvId, ClickType, ObjectPos, ObjectRot, ObjectSize, SizeFactor);
}
SetCameraJump(key ObjectId, integer LinkNum, key AvId, integer ClickType, vector ObjectPos, rotation ObjectRot, vector ObjectSize, float SizeFactor) {
	// Get library data
	string ObjectName = llKey2Name(ObjectId);
	string BaseName = GetBaseName(ObjectName);
	integer LibPtr = llListFindList(ObjectsStatic, [ BaseName ]);
	if (LibPtr == -1) { LogError("Can't find library entry for camera/jump: " + BaseName); return; }
	list HudMessage = [];
	if (ClickType == SHORT_CLICK) {
		// Set camera
		vector CameraPos = llList2Vector(ObjectsStatic, LibPtr + OBS_CAMERA_POS);
		vector CameraAltPos = llList2Vector(ObjectsStatic, LibPtr + OBS_CAMERA_ALT_POS);
		vector CameraFocus = llList2Vector(ObjectsStatic, LibPtr + OBS_CAMERA_FOCUS);
		// Calculate camera position
		if (CameraPos == VEC_NAN) {	// if no CameraPos in C card
			// Calculate camera position as <DefaultDistance> away from object on a line connecting
			// the avatar to the object
			vector AvPos = llList2Vector(llGetObjectDetails(AvId, [ OBJECT_POS ]), 0);
			// Adjust avatar position so the line of sight is very roughly around eye
			// level (looks better when selection beam is there)
			AvPos.z += 1.0;
			// Find the distance the camera should be from the target object.
			// The magnitude of the object's size works quite well to position the camera, but if the
			// avatar is standing closer to the object than that, we'll see the back of the avatar and even
			// possibly have the camera underground. So if that's the case, use 3/4 of the avatar's distance
			// (with enough margin to prevent clipping with the avatar).
			float SizeDistance = llVecMag(ObjectSize);
			float AvDistance = llVecDist(AvPos, ObjectPos);
			float Distance = SizeDistance;
			if (SizeDistance > (AvDistance - 1.0)) {
				Distance = AvDistance * 0.75;
			}
			CameraPos = ObjectPos + Distance * (AvPos - ObjectPos) / llVecMag(AvPos - ObjectPos);
		}
		else {
			CameraPos *= SizeFactor; // Compensate for size changes
			CameraPos = ObjectPos + (CameraPos * ObjectRot);
		}
		// Calculate alternate camera position
		if (CameraAltPos != VEC_NAN) {
			CameraAltPos *= SizeFactor; // Compensate for size changes
			CameraAltPos = ObjectPos + (CameraAltPos * ObjectRot);
		}
		// Calculate camera focus point
		if (CameraFocus == VEC_NAN) {	// if no CameraFocus in C card
			CameraFocus = ObjectPos;
		}
		else {
			CameraFocus *= SizeFactor; // Compensate for size changes
			CameraFocus = ObjectPos + (CameraFocus * ObjectRot);
		}
		HudMessage = [
			HUDA_CAMERA_SET,
			CameraPos,
			CameraFocus,
			CameraAltPos,
			LinkNum
				];
	}
	else {
		// Is it sittable? If so, sit on it
		integer Sittable = llList2Integer(ObjectsStatic, LibPtr + OBD_SITTABLE);
		if (Sittable) {
			osForceOtherSit(AvId, ObjectId);
			return;
		}
		// Set jump
		vector JumpPos = llList2Vector(ObjectsStatic, LibPtr + OBS_JUMP_POS);
		vector JumpLookAt = llList2Vector(ObjectsStatic, LibPtr + OBS_JUMP_LOOKAT);
		if (JumpPos != VEC_NAN) {
			JumpPos *= SizeFactor; // Compensate for size changes
			JumpPos = ObjectPos + (JumpPos * ObjectRot); // convert local pos to region
			if (JumpLookAt != VEC_NAN) {
				JumpLookAt *= SizeFactor; // Compensate for size changes
				JumpLookAt *= ObjectRot; // Adjust for target object rotation
			}
		}
		HudMessage = [
			HUDA_JUMP_SET,
			JumpPos,
			JumpLookAt
				];
	}
	osMessageAttachments(AvId, llDumpList2String(HudMessage, "|"), HUDAttachPoints, 0);
}
TeleportUser(list Params) {
	key ThisUserId = (key)llList2String(Params, 0);
	vector Pos = (vector)llList2String(Params, 1);
	vector LookAt = (vector)llList2String(Params, 2);
	osTeleportAgent(ThisUserId, Pos, LookAt);
}
// All objects in scene set to physics:none if their "phantom" attribute is set
// Used, for example, after region restart (there are reports that this get unset)
SetAllPhantom() {
	list Params = [];
	integer PrimCount = llGetNumberOfPrims();
	integer LinkNum;
	for (LinkNum = 2; LinkNum <= PrimCount; LinkNum++) {
		string ObjectName = llGetLinkName(LinkNum);
		string ObjectDesc = llList2String(llGetObjectDetails(llGetLinkKey(LinkNum), [ OBJECT_DESC ]), 0);
		if (llGetSubString(ObjectDesc, 0, 0) == "*") {	// if it's a moveable prim (ie MLO)
			integer ObjPtr = llListFindList(ObjectsStatic, [ ObjectName ]);
			if (ObjPtr > -1) {
				integer Phantom = llList2Integer(ObjectsStatic, ObjPtr + OBS_PHANTOM);
				if (Phantom) {
					Params += [ PRIM_LINK_TARGET, LinkNum, PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE ];
				}
			}
		}
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
}
SetTimer() {
	// We set timer if any of these are true:
	// - The UuidLinks table needs to be recreated
	// - There are awakeners waiting
	// - We need to send "loading complete" messages after being rezzed
	// - There are outstanding activations in the queue
	// - We need to identify ourselves to a parent Map object
	// - A scene is being saved but there are still activations (loading complete) waiting
	// - We're an app that's been sent App data to restore, but we're waiting for the catalogue data
	if (UuidLinksInvalid || AwakenTicks || LoadingCompleteTicks || ActivationQueueSize || LinksToDo != [] || AppBackupsWaiting || AppRestoreData != "" || LogoutTicks || WaitingForCataloguer)
		llSetTimerEvent(TIMER_FREQUENCY);
	else
		llSetTimerEvent(0.0);
}
// Parses a prim name, extracting a menu prim name if it's a menu prim with the
// correct flag. If it's not a menu prim, or if the flags don't match, return null
// Menu prim names start with "!" and can optionally have "[<flags>]" after name
// (ie flags inside [])
//
//    Current flags are "L" to make the button require a long-click, and "S" to keep the
//    button selected (which is normally not the case for "L" type buttons or for card
//    decks).
//
string ParseMenuPrim(string PrimName, string NeedFlags) {
	if (llGetSubString(PrimName, 0, 0) != "!") return "";    // it's not a menu prim
	string RetPrimName = llGetSubString(PrimName, 1, -1);    // basic name extraction
	integer LongClickType = FALSE;
	integer P1 = llSubStringIndex(PrimName, "[");
	integer P2 = llSubStringIndex(PrimName, "]");
	if (P1 > -1 && P2 > -1 && P2 > P1) {        // we have a [] section
		string Flags = llGetSubString(PrimName, P1 + 1, P2 - 1);
		if (P2 == P1 + 1) Flags = "";    // special case: empty []
		//if (Flags == NeedFlags) {    // flags match (old version, for only one possible flag)
		if (llSubStringIndex(Flags, NeedFlags) > -1) {        // flags match
			RetPrimName = llGetSubString(PrimName, 1, P1 - 1);
		}
		else {
			RetPrimName = "";        // it's not what we're looking for, so return null
		}
	}
	return llStringTrim(RetPrimName, STRING_TRIM);
}
// Returns TRUE if given size is larger than permitted size (SizeLimit)
integer SizeExceeded(vector Size) {
	if (SizeLimit == 0.0) return FALSE;	// No limit set
	// If any axis exceeds the limit, return TRUE
	integer Exceeded = (Size.x > SizeLimit || Size.y > SizeLimit || Size.z > SizeLimit);
	if (Exceeded) {
		llMessageLinked(LINK_SET, LM_HUD_STATUS, "!Size limit (" + NiceFloat(SizeLimit) + "m) reached", UserId);
	}
	return Exceeded;
}
// Returns TRUE if given position would exceed distance limit from root
integer DistanceExceeded(vector Pos, integer IsLocal) {
	if (DistanceLimit == 0.0) return FALSE;	// No limit set
	if (!IsLocal) Pos = RegionPos2LocalPos(Pos);	// convert local to region pos if necessary
	// If any axis of the position exceeds the limit ...
	integer Exceeded = (llFabs(Pos.x) > DistanceLimit || llFabs(Pos.y) > DistanceLimit || llFabs(Pos.z) > DistanceLimit);
	if (Exceeded) {
		llMessageLinked(LINK_SET, LM_HUD_STATUS, "!Distance limit (" + NiceFloat(DistanceLimit) + "m) reached", UserId);
	}
	return Exceeded;
}
// Apply or remove highlighting effects
// If Avid is non-null, applies highlighting; otherwise removes it
Highlight(integer LinkNum, key AvId) {
	vector ParticleColor = <1.0, 1.0, 1.0>;
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
	PrimGlow(LinkNum, (AvId != NULL_KEY));
	llLinkParticleSystem(LinkNum, Particles);
}
PrimGlow(integer LinkNum, integer On) {
	float Intensity = 0.0;
	if (On) Intensity = LinkedSelectGlow;
	llSetLinkPrimitiveParamsFast(LinkNum, [ PRIM_GLOW, ALL_SIDES, Intensity ]);
}
// The nearest we can get in LSL to the public variables (or public gets) of a grown-up language.
// Any semi-static public data (eg config settings) can go here.
SendPublicData() {
	llMessageLinked(LINK_SET, LM_PUBLIC_DATA, llDumpList2String([
		EnvironmentalChange,	// 0
		DefaultSeaLevel,		// 1
		DefaultLandLevel,		// 2
		CheckboxOn,			// 3
		CheckboxOff,			// 4
		TerrainChange,		// 5
		ModuleSize,			// 6
		ModulePosNormal,		// 7
		ModulePosHidden,		// 8
		AdvancedMenu,			// 9
		ErrorEmail,			// 10
		MaxAvatars,			// 11
		ParentId,			// 12
		RezBatchSize,			// 13
		HideOptions			// 14
			], "|"), UserId);
}
Sound(string Name) {
	llTriggerSound(Name, SOUND_VOLUME);
}
// Set debug mode according to root prim description
SetDebug() {
	if (llGetObjectDesc() == "debug") {	
		DebugId = llGetSubString((string)llGetKey(), 0, 3);
		DebugMode = TRUE;
	}
}
Debug(string Text) {
	if (DebugMode) {
		llOwnerSay(DebugId + ": " + Text);
		llRegionSay(DEBUGGER, Text);
	}
}
Message(key AvId, string Text) {
	llRegionSayTo(AvId, 0, Text);
}
LogError(string Text) {
	llMessageLinked(LINK_ROOT, -7563234, Text, UserId);
}
default {
	on_rez(integer Param) {
		OnRez(Param);
		Initialize(TRUE);
	}
	state_entry() {
		Initialize(FALSE);
	}
	timer() {
		llSetTimerEvent(0.0);
		//llMessageLinked(LINK_ALL_CHILDREN, LM_SCOREBOARD, ScoreboardChannel, NULL_KEY);
		// Process LOADING_COMPLETE for when ML is rezzed/reset
		if (UuidLinksInvalid) CreateUuidLinks();
		if (LoadingCompleteTicks) {
			if (--LoadingCompleteTicks == 0)
				llMessageLinked(LINK_SET, LM_LOADING_COMPLETE, "", UserId);
		}
		if (WaitingForCataloguer) {
			llMessageLinked(LINK_THIS, CT_START, "", NULL_KEY); // Tell cataloguer to start processing
		}
		// If MLOs that have been rezzed are in the queue to be linked, process a batch from that queue
		if (LinksToDo != []) {
			if (DebugMode) Debug("Objects to be linked: " + (string)llGetListLength(LinksToDo));
			integer Count = llGetListLength(LinksToDo);
			if (Count > LinkBatchSize) Count = LinkBatchSize;
			integer I;
			for (I = 0; I < Count; I++) {
				key ObjectId = llList2Key(LinksToDo, I);
				CreateContinue(ObjectId);
			}
			LinksToDo = llDeleteSubList(LinksToDo, 0, Count - 1);
		}
		// Process LOADING_COMPLETE for Activation Queue (when scene is loaded from notecard)
		if (ActivationQueueSize) {
			integer Batch = ActivationQueueSize;
			if (Batch >= ACTIVATION_BATCH_SIZE) Batch = ACTIVATION_BATCH_SIZE;
			integer I;
			for (I = 0; I < Batch; I++) {
				integer P = I * ACT_STRIDE;
				key Uuid = llList2Key(ActivationQueue, P);
				integer CommsType = llList2Integer(ActivationQueue, P + 1);
				if (CommsType == 0) { // Type 0 (deprecated) uses link messages
					integer LinkNum = Uuid2LinkNum(Uuid);
					if (LinkNum == -1) return;				
					llMessageLinked(LinkNum, LM_LOADING_COMPLETE, "", UserId);
				} else {
					MessageStandard(Uuid, LM_LOADING_COMPLETE, [ UserId ]);
				}
			}
			ActivationQueueSize -= Batch;
			ObjectsToLoad -= Batch;
			if (ActivationQueueSize) { // if some are still remaining in queue
				ActivationQueue = llDeleteSubList(ActivationQueue, 0, (Batch * ACT_STRIDE) - 1);
			}
			else {
				ActivationQueue = [];
				if (!ObjectsToLoad && ParentId == NULL_KEY) Message(UserId, "Loaded.");	// Otherwise there are still prims queued to link up
			}
		}
		// Process LOADING_COMPLETE for newly-created ML objects
		if (AwakenTicks) {
			if (--AwakenTicks == 0) AwakenScripts();
		}
		// Process app backups timeout
		if (AppBackupsWaiting) {
			if (!--AppBackupsTimeout) {
				LogError("Timeout during backup of objects");
				llMessageLinked(LINK_SET, LM_TASK_COMPLETE, "", UserId);	// free up HUD
				AppBackupsWaiting = 0;
			}
		}
		if (AppRestoreData != "" && ObjectsLibraryCount > 0) {	// if we have app data waiting to restore, and the library is loaded
			Debug("Restoring data");
			RestoreAppData(AppRestoreData);	// Restore it all
			AppRestoreData = "";
			// A bit of a hack here. A lot of MLOs will assume on startup that the user is logged in (for example seats will not
			// have click action set to "sit", or touch enabled for menu). But since we introduced apps in apps, that's no longer
			// given. So to avoid changing all those MLOs, we pretend to be the HUD controller and send a logout message to all MLOs.
			LogoutTicks = 30;
		}
		if (LogoutTicks > 0) {
			if (--LogoutTicks == 0) {
				// To make interactive MLOs become interactive, we fake a logout. But only if nobody is actually logged in - after
				// all, there's been time for a user to sign in since we rezzed and initialised.
				if (UserId == NULL_KEY) {
					llMessageLinked(LINK_SET, HUD_API_LOGOUT, "", NULL_KEY);
				}
			}
		}
		SetTimer();
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		// Processing for normal clicks
		if (Number == LM_TOUCH_NORMAL) {
			list TouchData = llCSV2List(String);
			key AvId = Id;
			integer LinkNum = llList2Integer(TouchData, 0);
			integer TouchFace = llList2Integer(TouchData, 1);
			vector TouchPos = llList2Vector(TouchData, 2);
			vector CpNormal = llList2Vector(TouchData, 3);
			vector CpBinormal = llList2Vector(TouchData, 4);
			vector TouchST = llList2Vector(TouchData, 5);
			vector TouchUV = llList2Vector(TouchData, 6);
			key ObjectId = llGetLinkKey(LinkNum);
			if (CpNormal == TOUCH_INVALID_VECTOR) return;       // they've clicked on a prim edge - ignore
			if (IsMap) {
				if (LinkNum == CursorLinkNum) return;	// ignore clicks on cursor prim
				TouchPos += BoardOffset * BoardPrimRot;
			}
			else {
				// Convert normal and binormal into local vectors
				rotation RootRot = llGetRot();
				CpNormal /= RootRot;
				CpBinormal /= RootRot;
			}
			// If the clicked face has been reserved by a client script in that prim, send that script the data
			// so that it can process a normal click instead of us.
			if (Sender < 2) {	// if it's NOT from a child prim (RTF prims can tell us about clicks using this code, but we don't want to loop it
				// back to them
				integer RtfPtr = llListFindList(ReservedTouchFaces, [ ObjectId, TouchFace ]);
				if (RtfPtr > -1) {
					string RtfData = llDumpList2String([ TouchFace, TouchPos, CpNormal, CpBinormal, TouchST, TouchUV  ], "|");
					llMessageLinked(LinkNum, LM_RESERVED_TOUCH_FACE, RtfData, AvId);
					return;
				}
			}
			string PrimName = llGetLinkName(LinkNum);
			string MenuPrimName = ParseMenuPrim(PrimName, "");    // look for a menu prim name (short click type)
			// TouchPos is in region coords, but the position in local coords, so calculate local contact point
			vector CpPos = RegionPos2LocalPos(TouchPos);
			if (MenuPrimName != "") {        // is it a valid short-click menu name?
				// If they've clicked on a command prim, any current creation is cancelled
				ExecuteCommand(AvId, MenuPrimName, ObjectId, FALSE);
				return;
			}
			if (AvId != UserId || CameraJumpMode) {	// Maybe we need to position their camera or jump
				SetCameraJumpLinked(ObjectId, SHORT_CLICK, AvId);
				return;
			}

			//    Do they have a creation process waiting?
			integer CPtr = FindNewObject(AvId, "", NOB_TYPE_CREATE_READY);
			if (CPtr > -1) {        // they do
				CPtr -= NOB_AVID;
				if (IsMap) {
					if (LinkNum != BoardLinkNum || TouchFace != BoardFace) return;	// In map mode, you can only position objects on the control board
				}
				if (DistanceExceeded(TouchPos, FALSE)) return;		// they've clicked too far from the root
				// Log normals data and create prim
				CreatePosition(CPtr, ObjectId, TouchPos, TouchFace, TouchST, CpPos, CpNormal, CpBinormal);
			}
			else {    // no creation - it's a short-click for some other reason
				// Next, we check to see if they have an object selected.
				integer SPtr = llListFindList(Selections, [ AvId ]);
				if (SPtr > -1) {        // they have an object selected
					if (!IsMap) {
						key SelectedUuid = llList2Key(Selections, SPtr + SEL_OBJECT_ID);
						if (ObjectId == SelectedUuid) {    // if they've short-clicked on the selected prim ...
							DeselectByPtr(SPtr);        // ... just deselect that prim
						}
						else {        // they've short-clicked on a prim other than the selected one
							if (DistanceExceeded(TouchPos, FALSE)) return;		// they've clicked too far from the root
							integer D = llListFindList(LinkedObjects, [ SelectedUuid ]);
							if (D == -1) { LogError("Can't find prim data for placement"); return; }
							D -= LO_OBJECT_ID;
							float SizeFactor = llList2Float(LinkedObjects, D + LO_SIZE_FACTOR);
							PositionObjectOnFace(AvId, "", ObjectId, FALSE, SelectedUuid, NULL_KEY, -1, TouchPos, TouchFace, TouchST, CpPos, CpNormal, CpBinormal, SizeFactor);
						}
					}
					else {	// Click on control board for map with icon selected, so position the object
						key SelObjectId = llList2Key(Selections, SPtr + SEL_OBJECT_ID);
						key SelIconId = llList2Key(Selections, SPtr + SEL_ICON_ID);
						integer DPtr = llList2Integer(Selections, SPtr + SEL_OBD_PTR);
						float SizeFactor = llList2Float(DetachedObjects, DPtr + DO_SIZE_FACTOR);
						PositionObjectOnFace(AvId, "", ObjectId, FALSE, SelObjectId, SelIconId, -1, TouchPos, TouchFace, TouchST, CpPos, CpNormal, CpBinormal, SizeFactor);
					}
				}
				else {	// No object selected
				}
			}
		}
		// Processing for alternate clicks
		else if (Number == LM_TOUCH_ALTERNATE) {
			if (IsMap) return;	// long-clicking on linkset prims has no function in Map mode
			key AvId = Id;
			integer LinkNum = (integer)String;
			key ObjectId = llGetLinkKey(LinkNum);
			// Find the prim name that they're long-clicking
			string PrimName = llGetLinkName(LinkNum);
			// Perhaps it's a long-click menu button. Let's find out
			string MenuPrimName = ParseMenuPrim(PrimName, "L");
			if (MenuPrimName != "") {    // it is a long-click menu prim
				// Long clicks on menu prims now don't do anything.
				// If you want to reinstate the next line, copy the checking code for short-clicks (to see if they're logged in)
				//ExecuteCommand(AvId, MenuPrimName, ObjectId, FALSE);    // so execute the menu command
			}
			else {
				if (AvId != UserId || CameraJumpMode) {	// Maybe we need to position their camera or jump
					SetCameraJumpLinked(ObjectId, LONG_CLICK, AvId);
					return;
				}
				// Not a menu prim, so presumably it's a moveable object to be selected
				if (ViewOnly && UserId != AvId) return;	// if view-only is set and they're not signed in, we don't want them selecting prims
				// First, we check to see if they already have a prim selected.
				integer SPtr = llListFindList(Selections, [ AvId ]);
				if (SPtr > -1) {        // they already have a prim selected (maybe even the same one)
					key PrevSelectedUuid = llList2Key(Selections, SPtr + SEL_OBJECT_ID);
					if (PrevSelectedUuid != ObjectId)    // if it was a different prim ...
						DeselectByPtr(SPtr);        // .. deselect it and carry on selecting this one
				}
				// Next, we check to see if someone else already has this prim selected
				if (FindSelectionByUuid(ObjectId) > -1) return;        // and stop processing if so
				// Next, we do the selection
				if (IsMoveable(ObjectId)) {    // it's a moveable prim
					CancelCreation(AvId);    // Stop any creation cycle that's active for them
					SelectObject(AvId, ObjectId);
				}
			}
		}
		else if (Number == LM_RESERVED_TOUCH_FACE && Sender > 1) {
			key SenderId = llGetLinkKey(Sender);
			ReserveTouch(SenderId, String);
		}
		else if (Number == IC_INITIALISE) {
			// A newly-rezzed icon has sent us its wake-up message
			key IconId = Id;
			// We pass the icon its configuration data and parameters
			string ObjectParams = "";	///%% will need the flag here for modifiable objects
			MessageStandard(IconId, IC_INITIALISE, [ IconSelectGlow, IconSelectParticleColour, IconHoverTextColour, IconHoverTextAlpha, ObjectParams ]);
			CreateContinue(IconId);
		}
		else if (Number == IC_SHORT_CLICK) {
			// Short click on an icon, either to move an object or create one
			key TouchIconId = Id;
			// Pick up data sent to us by the icon
			list Params = llParseStringKeepNulls(String, [ "|" ], []);
			key AvId = llList2Key(Params, 0);
			//if (!RegisteredAv(AvId)) return;
			vector TouchPos = llList2Vector(Params, 1);
			vector TouchNormal = llList2Vector(Params, 2);
			vector TouchBinormal = llList2Vector(Params, 3);
			rotation IconRot = llList2Rot(Params, 4);
			integer TouchFace = -1;	// if Maps need the StickPoint feature, then we need to add this to the icon script
			vector TouchST = ZERO_VECTOR;
			vector WorldPos = BoardPos2WorldPos(TouchPos);
			vector CpPos = RegionPos2LocalPos(TouchPos);
			if (AvId != UserId || CameraJumpMode) {	// Maybe we need to position their camera or jump
				SetCameraJumpMap(TouchIconId, SHORT_CLICK, AvId);
				return;
			}
			// Find out if this avatar has an object selected
			integer SelPtr = llListFindList(Selections, [ AvId ]);
			if (SelPtr > -1) {        // if they have a selection
				SelPtr -= SEL_AVID;    // position at beginning of slice
				key SelIconId = llList2Key(Selections, SelPtr + SEL_ICON_ID);
				if (SelIconId == TouchIconId) {
					// they've short-clicked on the selected icon, so deselect
					DeselectByAvId(AvId);
					return;
				}
				key ObjectId = llList2Key(Selections, SelPtr + SEL_OBJECT_ID);
				integer DetPtr = llList2Integer(Selections, SelPtr + SEL_OBD_PTR);
				key IconId = llList2Key(Selections, SelPtr + SEL_ICON_ID);
				float SizeFactor = llList2Float(DetachedObjects, DetPtr + DO_SIZE_FACTOR);
				PositionObjectOnFace(AvId, "", TouchIconId, FALSE, ObjectId, IconId, -1, TouchPos, TouchFace, TouchST, CpPos, TouchNormal, TouchBinormal, SizeFactor);
			}
			else {
				integer NPtr = FindNewObject(AvId, "", NOB_TYPE_CREATE_READY); // do they have an object waiting for creation?
				if (NPtr > -1) {        // they do
					NPtr -= NOB_AVID;
					// Log normals data and create prim
					CreatePosition(NPtr, NULL_KEY, TouchPos, TouchFace, TouchST, CpPos, TouchNormal, TouchBinormal);
				}
				else {		// no object for creation, maybe they have an object selected to move?
					integer SPtr = llListFindList(Selections, [ AvId ]);
					if (SPtr > -1) {        // they have an object selected
						key ObjectId = llList2Key(Selections, SPtr + SEL_OBJECT_ID);
						key IconId = llList2Key(Selections, SPtr + SEL_ICON_ID);
						integer DPtr = llList2Integer(Selections, SPtr + SEL_OBD_PTR);
						float SizeFactor = llList2Float(DetachedObjects, DPtr + DO_SIZE_FACTOR);
						PositionObjectOnFace(AvId, "", TouchIconId, FALSE, ObjectId, IconId, -1, TouchPos, TouchFace, TouchST, CpPos, TouchNormal, TouchBinormal, SizeFactor);
					}
					else {
					}
				}
			}
		}
		else if (Number == IC_LONG_CLICK) {
			// Message from icon telling us that a user has long-clicked it
			// We interpret this to mean a selection
			key IconId = Id;
			list Params = llParseStringKeepNulls(String, [ "|" ], []);
			key AvId = llList2Key(Params, 0);
			if (AvId != UserId || CameraJumpMode) {	// Maybe we need to position their camera or jump
				SetCameraJumpMap(IconId, LONG_CLICK, AvId);
				return;
			}
			// Find any other selection by same user
			key SelIconId = FindSelectedIconByAvId(AvId);
			if (SelIconId != NULL_KEY) {
				// the avatar already has something selected, so deselect it
				DeselectByAvId(AvId);
			}
			CancelCreation(AvId);    // Stop any creation cycle that's active for them
			// if the selection is the same icon, they've deselected by long-clicking, so we don't need to do anything else
			if (SelIconId == IconId) return;
			// Now select the object
			SelectObject(AvId, IconId);
		}
		else if (Number == WO_INITIALISE) {
			// This LM comes from the librarian which sends it to us when it receives WO_INITIALISE as an osMessageObject
			// message from a detached object it's rezzed.
			MessageFromChild(TRUE, Id);
		}
		else if (Number == LM_EXTRA_DATA_GET && Sender > 1) {    // Request for extra data from another prim
			// if it's not in the list, we send blank data (could happen with orphan prims, eg if script is reset)
			string ExtraData = "";
			key SenderId = llGetLinkKey(Sender);
			integer D = llListFindList(LinkedObjects, [ SenderId ]);
			if (D > -1) {
				D -= LO_OBJECT_ID;
				ExtraData = llList2String(LinkedObjects, D + LO_EXTRA_DATA);
			}
			llMessageLinked(Sender, LM_EXTRA_DATA_GET, ExtraData, UserId);    // Send the extra data to that prim
			if (String != "") {	// if the string portion contains anything, it's reserved touch face data
				ReserveTouch(SenderId, String);
			}
		}
		else if (Number == LM_EXTRA_DATA_SET && Sender > 1) {    // Changed extra data from another prim
			key SenderId = llGetLinkKey(Sender);
			integer D = llListFindList(LinkedObjects, [ SenderId ]);	
			if (D == -1) { LogError("Can't set extra data"); return; }
			D -= LO_OBJECT_ID;
			// replace extra data in table
			LinkedObjects = llListReplaceList(LinkedObjects, [ String ], D + LO_EXTRA_DATA, D + LO_EXTRA_DATA);
		}
		else if (Number == LM_EXTERNAL_LOGIN) {
			Login(Id);
		}
		else if (Number == LM_EXTERNAL_LOGOUT) {
			Logout();
		}
		else if (Number == LM_AUTOHIDE_SET) {
			AutoHideSet((integer)String); // String is 0 or 1 to hide or unhide
		}
		else if (Number == CT_CATALOG) {
			StoreCatalog(String);
		}
		else if (Number == CT_MODULES) {
			StoreModules(String);
		}
		else if (Number == CT_READY) { // Cataloguer is ready
			WaitingForCataloguer = FALSE;
			if (ParentId != NULL_KEY) {
				// If we're a child App, we need to get all the catalog data. Non-child Apps do this when the user
				// signs in, but we need to do it automatically.
				LoadStaticObjectsOnly = FALSE;
			} else {
				LoadStaticObjectsOnly = TRUE;
			}
			Debug("Requesting catalog data");
			llMessageLinked(LINK_THIS, CT_REQUEST_DATA, "", NULL_KEY);
		}
		else if (Number == LM_EXTERNAL_DESELECT) {
			DeselectByAvId(Id);
		}
		else if (Number == LIB_REZZED) { // message from librarian giving UUIDs of rezzed objects
			// We don't actually do anything here for Map objects and icons, because they tell us when they're ready.
			if (IsMap) return;
			list Uuids = llParseStringKeepNulls(String, [ "|" ], []);
			integer UuidsCount = llGetListLength(Uuids);
			integer U;
			for (U = 0; U < UuidsCount; U++) {
				key Uuid = (key)llList2String(Uuids, U);
				// We don't do anything for detached objects, because they tell us when they're ready
				string ObjectName = llKey2Name(Uuid);
				// Look for an object of this name in the library
				string ObjectReference = GetObjectReference(ObjectName);
				if (ObjectReference != "") { // if it's the name of an object in the library
					// Is it a detached object?
					integer OPtr = GetDynamicPointer(ObjectReference);
					if (OPtr == -1) return; // should never happen
					integer Detached = llList2Integer(ObjectsDynamic, OPtr + OBD_DETACHED);
					if (!Detached) {
						LinksToDo += Uuid;
						SetTimer();
					}
				}
			}
			if (DebugMode) Debug("Rezzed queue now " + (string)llGetListLength(LinksToDo) + " linked objects");
		}
		else if (Number == LM_UNLINK_QUEUE) {
			UnlinkFromQueue();
		}
		else if (Number == LM_RANDOM_CREATE) {
			RandomCreate = (integer)String;
		}
		else if (Number == LM_RANDOM_VALUES) {
			list L = llParseStringKeepNulls(String, [ "|" ], []);
			RandomResize = (float)llList2String(L, 0);
			RandomRotate = (integer)llList2String(L, 1);
		}
		else if (Number == LM_REMOTE_UNLINK) {
			key AvId = Id;
			integer LinkNum = Sender;
			if ((integer)String) LinkNum = (integer)String;        // Link number in string can override actual link number (maybe this might be useful one day?)
			key SenderId = llGetLinkKey(LinkNum);
			SelectObject(AvId, SenderId);    // Select the prim
			RemoveObject(AvId);    // Unlink the prim
		}
		else if (Number == LM_EXECUTE_COMMAND) {
			ExecuteCommand(Id, String, NULL_KEY, TRUE);
		}
		else if (Number == AOC_CREATE) {
			CancelCreation(Id);        // if they have a create cycle going, break it
			AocCreate(Id, String);
		}
		else if (Number == ENV_STORE_VALUE) {
			EnvironmentValues = llParseStringKeepNulls(String, [ "|" ], []);
		}
		else if (Sender > 1 && Number == SFM_LOAD) {	// Scene file manager has sent us the notecard contents we requested in RequestLoad()
			list Parts = llParseStringKeepNulls(String, [ "|" ], []);
			string LoadFile = llBase64ToString(llList2String(Parts, 0));
			list Meta = llList2List(Parts, 1, -1);
			list NotecardLines = llParseStringKeepNulls(LoadFile, [ "\n" ], []);
			LoadData(Id, NotecardLines, Meta);
		}
		else if (Sender > 1 && Number == SFM_BACKUP) {	// We requested backup data from the SFM, and here it is
			// Format is <name1>|<data1>^<name2>|<data2^ ... (name1 is empty for the current state)
			string CurrentState = SaveData("");
			String = llStringToBase64("|" + CurrentState + "^" + String);	// Add in our current state
			MessageObject(ParentId, (string)LM_APP_BACKUP_SEND + "|" + String);
		}
		else if (Number == LM_CAMERA_JUMP_MODE) {
			CameraJumpMode = (integer)String;
		}
		else if (Number == LM_CARD_AVAILABLE) {        // someone has clicked the card deck, and the deck script has reported that it has cards available (and is now locked)
			// Id is avatar ID, string is name of card object
			key Uuid = llGetLinkKey(Sender);
			CreateStart(Id, String, Uuid, NULL_KEY);
		}
		else if (Number == LM_NUDGE_STATUS) {
			SendNudgeStatus();
		}
		else if (Number == LM_WRITE_CONFIG) {
		// A message from ourself to write the file
			osMakeNotecard(CONFIG_NOTECARD, NewConfig);
			NewConfig = [];
			WriteConfig = FALSE;
		}
		else if (Number == LM_CHANGE_CONFIG) {
		// Message from other script to change config file value
			list Parts = llParseStringKeepNulls(String, [ "|" ], []);
			string Name = llList2String(Parts, 0);
			string Value  = llList2String(Parts, 1);
			ChangeConfig(Name, Value);
		}
		else if (Number == LM_RESET) {
			Debug("Reset command received");
			if (UserId != NULL_KEY) llRegionSayTo(UserId, 0, "App reset");
			Logout();
			llResetScript();
		}
	}
	dataserver(key From, string Data) {
		// All other incoming data
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		string sCommand = llList2String(Parts, 0);
		integer Command = (integer)sCommand;
		list Params = llList2List(Parts, 1, -1);
		if (DebugMode) Debug("Rec'd command " + sCommand + " from " + llKey2Name(From));
		if (Command == LM_EXTRA_DATA_GET) {
			// if it's not in the list, we send blank data (could happen with orphan prims, eg if script is reset)
			string ExtraData = "";
			integer D = llListFindList(LinkedObjects, [ From ]);
			if (D > -1) {
				D -= LO_OBJECT_ID;
				ExtraData = llList2String(LinkedObjects, D + LO_EXTRA_DATA);
			}
			MessageStandard(From, LM_EXTRA_DATA_SET, [ ExtraData ]);
			string RTData = llList2String(Params, 0);
			if (RTData != "") {	// if the string portion contains anything, it's reserved touch face data
				ReserveTouch(From, RTData);
			}		
		}
		else if (Command == LM_EXTRA_DATA_SET) {
			string ExtraData = llList2String(Params, 0);
			integer D = llListFindList(LinkedObjects, [ From ]);	
			if (D == -1) { LogError("Can't set extra data"); return; }
			D -= LO_OBJECT_ID;
			// replace extra data in table
			LinkedObjects = llListReplaceList(LinkedObjects, [ ExtraData ], D + LO_EXTRA_DATA, D + LO_EXTRA_DATA);
}		
		else if (Command == LM_CHILD_READY) {
			// The child app's ML has loaded and sent us a message telling is it's ready
			MessageFromChild(FALSE, From);
		}
		else if (Command == LM_APP_BACKUP_REQUEST) { // Parent app/map is requesting our data
			llMessageLinked(SfmLinkNum(), SFM_BACKUP, "", UserId);	// So we request it from the Scene File Manager and await the reply
			ParentId = From;	// store the ID of the parent object
		}
		else if (Command == LM_APP_BACKUP_SEND) {	// Parent receiving data from an app
			if (DebugMode) Debug("Data received from " + llKey2Name(From) + ": " + (string)llStringLength(Data) + " bytes"); // Test to save executing Key2Name unnecessarily
			string DataSent = llList2String(Params, 0);
			integer DPtr = llListFindList(DetachedObjects, [ From ]);
			if (DPtr == -1) {
				LogError("Can't find detached object to store data: '" + llKey2Name(From) + "'");
				return;
			}
			DPtr -= DO_OBJECT_ID;	// Position at beginning of stride
			DetachedObjects = llListReplaceList(DetachedObjects, [ DataSent ], DPtr + DO_APP_DATA, DPtr + DO_APP_DATA);	// Replace app data into DO table
			AppBackupsWaiting--;
			if (!AppBackupsWaiting) {	// If we've processed all the apps' data
				SaveData(AppBackupSaveName);	// Write the notecard
			}
		}
		else if (Command == LM_APP_RESTORE) {	// App/Map sending us our data
			// But maybe we haven't got the catalogue data yet
			AppRestoreData = llList2String(Params, 0);
			if (DebugMode) Debug("Got " + (string)llStringLength(AppRestoreData) + " bytes of data");
			SetTimer();
		}
		else if (sCommand == HUDA_TELEPORT) {
			TeleportUser(Params);
		}
	}
	listen(integer Channel, string Name, key Id, string Text) {
		if (Channel == COMMS_CHANNEL && Id != OurUuid) {
			ProcessComms(Id, Text);
		}
		else if (Channel == CommandChatChannel && Id == UserId) {
			string Command = llToLower(llStringTrim(Text, STRING_TRIM));
			if (Command == "tidy") {
				if (CursorLinkNum == -1) {
					Message(UserId, "Can't tidy because cursor not available");
					return;
				}
				Clear();
				state Tidy;
			}
		}
	}
	changed(integer Change)    {
		if (Change & CHANGED_INVENTORY) ReadConfig();
		if (Change & CHANGED_REGION_START) {
			if (DummyMoveSet) MoveLinkset();
			RegionSize = osGetRegionSize(); // Region may have changed size
			SetAllPhantom();
		}
	}
}
state Tidy {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Message(UserId, "Tidying scene ...");
		TidyDone = [];
		TidyPos = WorldOrigin;
		TidyPos.x += TIDY_STEP;
		TidyPos.y += TIDY_STEP;
		TidyCount = 0;
		SetCursor(TRUE, NULL_KEY, TidyPos);
		llMessageLinked(CursorLinkNum, CUR_SCAN, "", NULL_KEY);
		llSetTimerEvent(0.5);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == CUR_RESULTS) {
			llSetTimerEvent(0.0);
			TidyMoveOn = TRUE;
			if (String != "") {
				list Uuids = llParseStringKeepNulls(String, [ "|" ], []);
				integer Count = llGetListLength(Uuids);
				while(Count--) {
					key Uuid = (key)llList2String(Uuids, Count);
					if (llListFindList(TidyDone, [ Uuid ]) == -1) {	// If we've not already looked here
						vector Pos = llList2Vector(llGetObjectDetails(Uuid, [ OBJECT_POS ]), 0);
							if (Pos.x >= WorldOrigin.x && Pos.x <= (WorldOrigin.x + WorldSize.x) &&
							Pos.y >= WorldOrigin.y && Pos.y <= (WorldOrigin.y + WorldSize.y)) { // if it's in our portion of the region
								string ObjectName = llKey2Name(Uuid);
								string Suffix = llGetSubString(ObjectName, -1, -1);
								integer DeleteSignal = 0;
								if (Suffix == "W") DeleteSignal = WO_DELETE; else if (Suffix == "I") DeleteSignal = IC_DELETE;
								if (DeleteSignal) {
									osMessageObject(Uuid, (string)DeleteSignal);
									TidyCount++;
								}
							}
						TidyDone += Uuid;
						TidyMoveOn = FALSE;	// we need to check again here in case there are >16 scripted objects
					}
				}
			}
			if (!TidyMoveOn) {
				llMessageLinked(CursorLinkNum, CUR_SCAN, "", NULL_KEY);
			}
			else {
				llSetTimerEvent(0.5);
			}
		}
	}
	touch_start(integer Count) {
		state FinishTidy;
	}
	timer() {
		if (TidyMoveOn) {	// We've processed all we can in this area
			TidyPos.x += TIDY_STEP;
			if (TidyPos.x > WorldOrigin.x + WorldSize.x) {
				TidyPos.x = WorldOrigin.x;
				TidyPos.y += TIDY_STEP;
				if (TidyPos.y > WorldOrigin.y + WorldSize.y) state FinishTidy;
			}
			SetCursor(TRUE, NULL_KEY, TidyPos);
			llMessageLinked(CursorLinkNum, CUR_SCAN, "", NULL_KEY);
		}
	}
}
state FinishTidy {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Message(UserId, "Finished.\n" + (string)llGetListLength(TidyDone) + " scripted object(s) found\n" + (string)TidyCount + " attempted removal(s)\nPLEASE SIGN OUT OF MAP NOW!");
		TidyDone = [];
		SetCursor(FALSE, NULL_KEY, ZERO_VECTOR);
		Logout();	// We have to log them out because returning to Normal state assumes nobody logged in
		state Normal;
	}
}
state Hang { 
	on_rez(integer Param) { llResetScript(); }
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llResetScript();
	}
}
// Malleable linkset v1.21.13