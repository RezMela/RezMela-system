// RezMela HUD attachment v1.4.0

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

// v1.4.0 - HUD server now renders prim-drawing textures
// v1.3 - update for OpenSim 0.9.1
// v1.2 - don't use alt camera pos if none specified
// v1.1 - new error handler
// v1.0 - version change only
// v0.24 - add RegionSay message on loading (for HUD-giving feature of server)
// v0.23 - use ML for teleports; beep on alert status
// v0.22 - bug fixes, zoom further function
// v0.21 - camera/jump changes
// v0.20 - don't release camera when turning camera/jump mode off
// v0.19 - jump mode feature
// v0.18 - clear status on sign out; version number on status; camera control feature; config file added
// v0.17 - add camera angle feature
// v0.16 - clear virtual pages, etc on change of region
// v0.15 - clear hash table on change of region
// v0.14 - increased hash table max size; use new texture store feature
// v0.13 - fix position of floating text background
// v0.12 - add camera pos/rot to data sent with click; add status line (floating text)
// v0.11 - various bug fixes for recycling prims; "debug" in description switches debug mode on
// v0.10 - check for null thumbnail texture, and improve "invalid link number" behaviour
// v0.9 - bug fix in maximise
// v0.8 - bug fix in take controls
// v0.7 - add ability to display an image; take controls
// v0.6 - better transitions between panels
// v0.5 - bug fixes
// v0.4 - redesigned login protocol
// v0.3 - detect when ML disappears
// v0.2 - configurable sizes, etc

// TODO:
// - generic command that can be sent by the server and processed here as SetPrimitiveParams, so miscellanous modifications can be made on the fly

string MyVersion; // taken from name of this script
integer DebugMode = FALSE;
rotation NORTH_CORRECTION = <0.0, 0.0, -0.707107, 0.707107>; // Applied to camera Z rotation to make 0° north - calculated as llEuler2Rot(<0, 0, -90> * DEG_TO_RAD)
string CONFIG_NOTECARD = "HUD settings";
vector VEC_NAN = <-99.0,99.0,-99.0>;    // nonsense value to indicate "not a number" for vectors
integer CAMERA_JUMP_FACE = 4;
integer CAMERA_JUMP_BACK = 1;

integer HUD_CHANNEL = -84401050;

// HUDA messages (direct to/from HUD from other scripts)
string HUDA_CAMERA_SET = "cset";
string HUDA_JUMP_SET = "jset";
string HUDA_TELEPORT = "tele";

// HUDT messages (from HUD touch script)
//integer HUDT_SHORT_CLICK = -81833010;
//integer HUDT_LONG_CLICK = -81833011;

// HUD texture store constants
integer HTS_CHANNEL = -404165013;
string HTSC_REQUEST_DATA	= "r";
string HTSC_HEARTBEAT		= "h";
string HTSM_SEND_DATA		= "HTSs";	// Keep these at 4 chars
string HTSM_ADD_TEXTURES	= "HTSa";

list VirtualPages;
// 0 is "P"
integer VP_INDEX = 1;
integer VP_TEXTURE = 2;
integer VP_STRIDE = 3;
integer VirtualPagesCount;

// How the PagePrims and VirtualPages lists work is as follows:
// We create the illusion (for the sake of the HUD server) that we have an unlimited number of prims to display pages on.
// However, in reality that number is finite and so we recycle the oldest prims.
list PagePrims;
// 0 is "P"
integer PP_PAGE_INDEX = 1;		// -1 if prim not allocated to a page
integer PP_LINKNUM = 2;
integer PP_LAST_USED = 3;
integer PP_STRIDE = 4;
integer PagePrimsCount;

// Special prim link numbers
integer SplashPrim;	// Link number of splash prim
integer BackerPrim;	// Link number of backer prim
integer FloatBackPrim;
integer FloatTextPrim;
integer CameraJumpModePrim;
integer CameraResetPrim;
integer JumpBackPrim;

key SplashPrimTexture;

list ImagePrims;
integer IM_LINKNUM = 0;
integer IM_UUID = 1;
integer IM_TAG = 2;
integer IM_STRIDE = 3;
integer ImagePrimsCount;

list CurrentImages;	// [ link number, pos ] of current displayed images (eg) thumbnails
integer CI_LINKNUM = 0;
integer CI_POS = 1;
integer CI_SIZE = 2;
integer CI_STRIDE = 3;

list HashTable;
key TextureStore;
list HashQueue;
integer HashQueueMode;

integer CurrentPagePrim;	// pointer to PagePrims
integer CurrentPageLinkNum;

float TimerFrequency;
string UuidLogo;		// UUIDs of textures on HUD root
string UuidMinMax;

string MESSAGE_SEPARATOR = "|";
string MESSAGE_SEPARATOR_2 = "^";
string PRIM_DRAWING_DELIMITER = "^";			// delimiter character for prim-drawing commands

//integer HUD_CHAT_GENERAL = -24473302;	// chat channel for general talk in region

key ServerID;
key OwnerId;
integer Visible;	// Is the HUD invisible (ie not activated, invisible and unusable)?
integer Maximised; // Is the HUD maximised or minimised (only header showing)?
integer LoggedIn;	// Is the HUD signed in?
integer MaxListSize;
list LastPosList;
list LastRotList;
integer LastListSize;

string HUD_MESSAGE_HELLO = "h";
string HUD_MESSAGE_ACTIVATE = "a";
string HUD_MESSAGE_CREATE_PAGE = "s";
string HUD_MESSAGE_DELETE_PAGE = "e";
string HUD_MESSAGE_DISPLAY_PAGE = "i";
string HUD_MESSAGE_DEACTIVATE = "d";
string HUD_MESSAGE_VERSIONFAIL = "v";
string HUD_MESSAGE_READY = "o";
string HUD_MESSAGE_CLICK = "c";
string HUD_MESSAGE_PRIM_PARAMS = "p";
string HUD_MESSAGE_TAKE_CONTROL = "n";
string HUD_MESSAGE_TRACK_CAMERA = "m";
string HUD_MESSAGE_FLOATING_TEXT = "f";
string HUD_MESSAGE_CAMERA_JUMP_MODE = "C";
string HUD_MESSAGE_GET_VERSION = "V";

vector POS_STASH = <0.04, 0.0, 0.0>;	// local position of "stashed" prims, tucked out of the way
vector SIZE_TINY = <0.001, 0.001, 0.001>;
vector TITLE_PAGE_REPEATS = <-4.0, 0.125, 0.0>;
vector TITLE_PAGE_OFFSETS = <0.0, 0.45, 0.0>;
integer FACE_RENDER = 2;
integer FACE_TITLE = 4;
integer FACE_PAGE = 5;
integer FACE_IMAGE = 5;
float ALPHA_NORMAL = 1.0;
float ALPHA_TRANSPARENT = 0.0;
vector COLOR_WHITE = <1.0, 1.0, 1.0>;
rotation IMAGE_ROTATION = <-0.5, 0.5, -0.5, 0.5>;

vector CameraJumpModeButtonPosActive;
vector CameraJumpModeButtonPosIdle;
vector CameraJumpModeButtonSize;
string CameraJumpModeOnTexture;
string CameraJumpModeOffTexture;

vector CameraResetButtonPosActive;
vector CameraResetButtonPosIdle;
vector CameraResetButtonSize;
string CameraResetButtonTexture;

vector JumpBackButtonPosActive;
vector JumpBackButtonPosIdle;
vector JumpBackButtonSize;
string JumpBackButtonTexture;

string TitleText;
key TitleId;
vector BackerColor;
vector FloatBackColor;
float FloatBackHeight;
vector FloatBackPos;
vector FloatTextColorNormal;
vector FloatTextColorWarn;
vector FloatTextPos;

vector RootPrimSize;
vector PagePrimSize;
vector PagePrimPosCurrent;
vector PagePrimPosSwapped;
rotation PagePrimRot;

integer PageTextureSize;
integer PageWidth;
integer PageHeight;

vector PageRepeats;
vector PageOffsets;

integer SplashOn = FALSE;
integer VersionNumberSeen;
integer Controls;

float CameraZoomFactor;
integer CameraTracking;
integer CameraJumpMode;
integer CameraPositioned;
vector PreviousCameraFocus;
vector PreviousCameraPos;
integer CameraAlternate;
key JumpAppId;	// UUID of app that reported long-click to jump
integer UpdateFloatingText;

string AlertSound;

string FloatingText;

HandleTouch(integer LinkNum, float TouchX, float TouchY) {
	if (LinkNum == CameraJumpModePrim) {
		integer OldCameraJumpMode = CameraJumpMode;
		CameraJumpMode = !CameraJumpMode;
		CameraJumpShow();
		// If we're logged in, the ML needs to know we're in camera mode so it can
		// disable other single-click processing
		if (LoggedIn) MessageServer(HUD_MESSAGE_CAMERA_JUMP_MODE, [ CameraJumpMode ]);
		//if (OldCameraJumpMode && !CameraJumpMode) ReleaseCamera();
	}
	else if (LinkNum == CameraResetPrim) {
		ReleaseCamera();
	}
	else if (LinkNum == JumpBackPrim) {
		if (!LastListSize) return;	// there is no last place to go back to
		// See this article (and the comments):
		// https://starflowerbracken.wordpress.com/2013/10/10/lookat-vector-with-osteleportagent-osteleportowner/#comment-198
		vector LastPos = llList2Vector(LastPosList, -1);
		rotation LastRot = llList2Rot(LastRotList, -1);
		LastPosList = llDeleteSubList(LastPosList, -1, -1);
		LastRotList = llDeleteSubList(LastRotList, -1, -1);
		LastListSize--;
		vector LastRotE = llRot2Euler(LastRot);
		float Angle = LastRotE.z;	// Rotational angle in radians
		vector LastLookAt = <llCos(Angle), llSin(Angle), 0.0>;
		Jump(LastPos, LastLookAt, FALSE);
		CameraJumpShow();
	}
	// The following processing is for clicks on the main HUD area
	if (!Visible) return;	// Ignore clicks if we're hidden
	if (!LoggedIn) return;	// Don't do anything else if we're logged out
	// Get camera data (these will be zero if perms not yet granted)
	vector CameraPos = ZERO_VECTOR;
	rotation CameraRot = ZERO_ROTATION;
	if (CameraTracking) {
		CameraPos = llGetCameraPos();
		CameraRot = llGetCameraRot();
	}
	if (LinkNum == CurrentPageLinkNum) {
		// a click on the current page
		MessageServer(HUD_MESSAGE_CLICK, [ TouchX, TouchY, CameraPos, CameraRot ]);
		return;
	}
	else if (LinkNum == LINK_ROOT) {
		VisibleStatus(TRUE, !Maximised);	// toggle maximised/minimised status
		SetFloatingText();	// Display or hide floating text depending on visibility
		return;
	}
	// Is it an image?
	integer Ptr = llListFindList(ImagePrims, [ LinkNum ]);
	if (Ptr > -1) {	// it's a thumbnail
		Ptr -= IM_LINKNUM;	// position at start of stride
		string Tag = llList2String(ImagePrims, Ptr + IM_TAG);
		if (Tag != "") {
			MessageServer(HUD_MESSAGE_CLICK, [ Tag, CameraPos, CameraRot ]);
		}
	}
}
HandleServerMessage(string Command, list Parts) {
	//Debug("From server: " + Command + ": " + llGetSubString(llDumpList2String(Parts, "|"), 0, 20));
	if (Command == HUD_MESSAGE_CREATE_PAGE) {
		CreatePage(Parts);
	}
	else if (Command == HUD_MESSAGE_DISPLAY_PAGE) {
		if (!VersionNumberSeen) {
			FloatingText = GetHudVersion();
			VersionNumberSeen = TRUE;
		}
		else {
			FloatingText = "";
		}
		SetFloatingText();
		integer PageIndex = (integer)llList2String(Parts, 0);
		string Thumbstring = llList2String(Parts, 1);
		DisplayPage(PageIndex, Thumbstring);
		Splash(FALSE); // remove splash screen if it's up
	}
	else if (Command == HUD_MESSAGE_DELETE_PAGE) {
		integer PageIndex = (integer)llList2String(Parts, 0);
		DestroyPage(PageIndex);
	}
	else if (Command == HUD_MESSAGE_PRIM_PARAMS) {
		integer LinkNum = (integer)llList2String(Parts, 0);
		list PrimParams = llList2List(Parts, 1, -1);
		llSetLinkPrimitiveParamsFast(LinkNum, PrimParams);
	}
	else if (Command == HUD_MESSAGE_TAKE_CONTROL) {
		Controls = (integer)llList2String(Parts, 0);
		if (Controls)
			TakeControls();
		else
			llReleaseControls();
	}
	else if (Command == HUD_MESSAGE_TRACK_CAMERA) {
		CameraTracking = (integer)llList2String(Parts, 0);
	}
	else if (Command == HUD_MESSAGE_FLOATING_TEXT) {
		FloatingText = llList2String(Parts, 0);
		SetFloatingText();
	}
	else if (Command == HUD_MESSAGE_VERSIONFAIL) {
		llDetachFromAvatar();
		return;
	}
}
CreatePage(list Parts) {
	integer PageIndex = (integer)llList2String(Parts, 0);
	DestroyPage(PageIndex);		// if the page already exists, destroy it
	string TextureId = llList2String(Parts, 1);
	integer LinkNum = InitPage(PageIndex);
	VirtualPages += [ "P", PageIndex, NULL_KEY ];
	VirtualPagesCount++;
	RenderTexture(PageIndex, LinkNum, FACE_PAGE, TextureId);
	Debug("Created page: " + (string)PageIndex);
}
DestroyPage(integer PageIndex) {
	integer Ptr = llListFindList(VirtualPages, [ "P", PageIndex ]);
	if (Ptr > -1) DestroyPageByPtr(Ptr, PageIndex);
}
DestroyPageByPtr(integer Ptr, integer PageIndex) {
	VirtualPages = llDeleteSubList(VirtualPages, Ptr, Ptr + VP_STRIDE -1);
	VirtualPagesCount--;
	integer Break = FALSE;
	do {
		Ptr = llListFindList(PagePrims, [ "P" + PageIndex ]);
		if (Ptr > -1) {
			PagePrims = llListReplaceList(PagePrims, [ -1 ], Ptr + PP_PAGE_INDEX, Ptr + PP_PAGE_INDEX);
		}
		else {
			Break = TRUE;
		}
	} while (!Break);
	Debug("Destroyed page: " + (string)PageIndex);
}
// Display a page's data. Returns link number to prim
integer InitPage(integer PageIndex) {
	Debug("Init page: " + (string)PageIndex);
	// hide current prim if there is one
	integer PrimPtr = llListFindList(PagePrims, [ "P", PageIndex ]);
	integer LinkNum = -9999;
	if (PrimPtr == -1) {
		// We haven't set up this page yet.
		// So, first find a spare prim
		PrimPtr = llListFindList(PagePrims, [ "P", -1 ]);
		if (PrimPtr == -1) {
			// So we've run out of physical prims and need to recycle the oldest one
			PrimPtr = GetOldestPrim();
		}
		LinkNum = llList2Integer(PagePrims, PrimPtr + PP_LINKNUM);
		// Update the prims table with the index and timestamp
		PagePrims = llListReplaceList(PagePrims,
			[ "P", PageIndex, LinkNum, llGetTime() ],
			PrimPtr, PrimPtr + PP_STRIDE - 1);
	}
	else {
		LinkNum = llList2Integer(PagePrims, PrimPtr + PP_LINKNUM);
	}
	return LinkNum;
}
DisplayPage(integer PageIndex, string ImagesString) {
	integer VirtualPtr = llListFindList(VirtualPages, [ "P", PageIndex ]);
	if (VirtualPtr == -1) { ShowError("Can't find page to display: " + (string)VirtualPtr); DebugDump(); return; }
	string TextureId = llList2String(VirtualPages, VirtualPtr + VP_TEXTURE);
	integer ApplyTexture = FALSE;
	integer PrimPtr = llListFindList(PagePrims, [ "P", PageIndex ]);
	if (PrimPtr == -1) {
		PrimPtr = GetOldestPrim();
		PagePrims = llListReplaceList(PagePrims, [ PageIndex ], PrimPtr + PP_PAGE_INDEX, PrimPtr + PP_PAGE_INDEX);	// set recyled prim to point to this virtual page
		ApplyTexture = TRUE;
	}
	integer LinkNum = llList2Integer(PagePrims, PrimPtr + PP_LINKNUM);
	list PrimParams = [];
	integer OldLinkNum = CurrentPageLinkNum;
	CurrentPagePrim = PrimPtr;
	CurrentPageLinkNum = LinkNum;

	if (OldLinkNum > -1 && OldLinkNum != CurrentPageLinkNum) {	// if there was a page currently displayed (and it's not the same prim)
		PrimParams += HidePage(OldLinkNum);
	}

	PrimParams += PrimLinkTarget("DisplayPage", LinkNum) + PrimSize(PagePrimSize) + PrimPosRot(PagePrimPosCurrent, PagePrimRot) + PrimColor(FACE_PAGE, COLOR_WHITE, ALPHA_NORMAL);
	if (ApplyTexture) {
		PrimParams += PrimTexture(FACE_PAGE, TextureId, PageRepeats, PageOffsets, 0.0);
	}

	if (ImagesString != "") {
		list TL = llParseStringKeepNulls(ImagesString, [ MESSAGE_SEPARATOR_2 ], []);
		integer Tlc = llGetListLength(TL);
		integer T;
		for (T = 0; T < Tlc; T += 4) {
			string Uuid = llList2String(TL, T);
			string Tag = llList2String(TL, T + 1);
			vector Pos = (vector)llList2String(TL, T + 2);
			vector Size = (vector)llList2String(TL, T + 3);
			PrimParams += SetImagePrim(Uuid, Pos, Size, Tag);
		}
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, PrimParams);
	PagePrims = llListReplaceList(PagePrims, [ llGetTime() ], PrimPtr + PP_LAST_USED, PrimPtr + PP_LAST_USED); 	// Update "last used" time to make this page recently used
	Debug("Displayed page: " + (string)PageIndex + " linknum: " + (string)LinkNum);
}
// Hide a page and its elements (returns Prim Params list segment)
list HidePage(integer LinkNum) {
	list PrimParams = PrimLinkTarget("HidePageP", LinkNum) + PrimSize(PagePrimSize) + PrimPosRot(PagePrimPosSwapped, PagePrimRot);
	integer CiLen = llGetListLength(CurrentImages) / CI_STRIDE;
	integer T;
	for (T = 0; T < CiLen; T++) {
		integer IPtr = T * CI_STRIDE;	// point to beginning of stride
		integer ImageLinkNum = llList2Integer(CurrentImages, IPtr + CI_LINKNUM);
		PrimParams += PrimLinkTarget("HidePageI", ImageLinkNum) + PrimSize(SIZE_TINY) + PrimPosRot(POS_STASH, PagePrimRot);
	}
	CurrentImages = [];
	return PrimParams;
}
// Allocate, position and texture a thumbnail - returns prim parameters
list SetImagePrim(string Uuid, vector Pos, vector Size, string Tag) {
	if (Uuid == (string)NULL_KEY || Uuid == "") return [];
	integer LinkNum;
	integer Ptr = llListFindList(ImagePrims, [ Uuid ]);
	if (Ptr > -1) {		// we already have this texture on a prim
		Ptr -= IM_UUID; // position at stride start
	}
	else {
		Ptr = llListFindList(ImagePrims, [ NULL_KEY ]);	// look for unused thumbnail
		if (Ptr > -1) {
			Ptr -= IM_UUID; // position at stride start
		}
		else {
			Ptr = 0;	// pick the first (oldest) one
		}
	}
	//	llOwnerSay("M" + (string)M + " Ptr: " + (string)Ptr + ", LinkNum: " + (string)LinkNum + ", List: " + llList2CSV(ImagePrims));
	LinkNum = llList2Integer(ImagePrims, Ptr + IM_LINKNUM);
	// To keep the newest at the end of list, delete the old entry and add a new one
	ImagePrims = llDeleteSubList(ImagePrims, Ptr, Ptr + IM_STRIDE - 1);
	ImagePrims += [ LinkNum, Uuid, Tag ];
	CurrentImages += [ LinkNum, Pos, Size ];
	// Position prim
	return PrimLinkTarget("SetImagePrim", LinkNum) +
		PrimTexture(FACE_IMAGE, Uuid, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0) +
		PrimSize(Size) +
		PrimPosRot(Pos, IMAGE_ROTATION) +
		PrimColor(FACE_IMAGE, COLOR_WHITE, ALPHA_NORMAL);
}
// Returns index for the prim that's not been used the longest
integer GetOldestPrim() {
	float OldestTime = llGetTime();
	integer OldestPrim = -1;
	integer PrimPtr;
	integer Len = PagePrimsCount * PP_STRIDE;
	for (PrimPtr = 0; PrimPtr < Len; PrimPtr += PP_STRIDE) {
		float LastUsed = llList2Float(PagePrims, PrimPtr + PP_LAST_USED);
		if (LastUsed < OldestTime && PrimPtr != CurrentPagePrim) {
			OldestTime = LastUsed;
			OldestPrim = PrimPtr;
		}
	}
	if (OldestPrim == -1) PrimPtr = 0;	// Just in case nothing matched for some reason,
	return OldestPrim;
}
// Totally hide the HUD by making it invisible and small, or reverse this by displaying it normal sized
VisibleStatus(integer pVisible, integer pMaximised) {
	Visible = pVisible;
	Maximised = pMaximised;
	vector RootSize = SIZE_TINY;
	float Alpha = ALPHA_NORMAL;
	if (!Visible) Alpha = ALPHA_TRANSPARENT;
	list PrimParams = PrimLinkTarget("VisibleStatus 1", 1);
	integer AllVisible = (Visible && Maximised);	// Is the main part of the HUD visible?
	// Root appearance
	if (!Visible) {
		PrimParams +=
			PrimSize(SIZE_TINY) +
			PrimColor(ALL_SIDES, COLOR_WHITE, ALPHA_TRANSPARENT);	// set root prim details
	}
	else {
		PrimParams +=
			PrimSize(RootPrimSize) +
			PrimColor(ALL_SIDES, COLOR_WHITE, ALPHA_NORMAL);	// set root prim details
	}
	if (Visible) {
		float Rot = 0.0;
		if (!Maximised) Rot = PI;	// Set min/max arrow direction
		PrimParams += PrimTexture(6, UuidMinMax, <1.0, 1.0, 0.0>, ZERO_VECTOR, Rot);
	}
	// Camera mode prim
	CameraJumpShow();
	// Hide all page prims
	integer P;
	for (P = 0; P < PagePrimsCount; P++) {
		integer Q = P * PP_STRIDE;
		integer LinkNum = llList2Integer(PagePrims, Q + PP_LINKNUM);
		vector Pos = POS_STASH;
		vector Size = SIZE_TINY;
		if (AllVisible) {
			Pos = PagePrimPosSwapped;
			Size = PagePrimSize;
		}
		PrimParams += PrimLinkTarget("VisibleStatus 2", LinkNum) + PrimPosRot(Pos, PagePrimRot) + PrimSize(Size) + PrimColor(ALL_SIDES, COLOR_WHITE, ALPHA_TRANSPARENT);
	}
	// Show current page prim
	if (AllVisible && CurrentPageLinkNum > 0) {
		PrimParams += PrimLinkTarget("VisibleStatus 3", CurrentPageLinkNum) + PrimPosRot(PagePrimPosCurrent, PagePrimRot) + PrimSize(PagePrimSize) + PrimColor(FACE_PAGE, COLOR_WHITE, ALPHA_NORMAL);
	}
	// Hide all image prims
	for (P = 0; P < ImagePrimsCount ; P++) {
		integer Q = P * IM_STRIDE;
		integer LinkNum = llList2Integer(ImagePrims, Q + IM_LINKNUM);
		PrimParams += PrimLinkTarget("VisibleStatus 4", LinkNum) + PrimColor(ALL_SIDES, COLOR_WHITE, ALPHA_TRANSPARENT) + PrimPosRot(POS_STASH, PagePrimRot) + PrimSize(SIZE_TINY);
	}
	// If maximised, show current thumbnails
	if (AllVisible) {
		integer CiLen = llGetListLength(CurrentImages) / CI_STRIDE;
		for (P = 0; P < CiLen; P++) {
			integer Q = P * CI_STRIDE;
			integer LinkNum = llList2Integer(CurrentImages, Q + CI_LINKNUM);
			vector Pos = llList2Vector(CurrentImages, Q + CI_POS);
			vector Size = llList2Vector(CurrentImages, Q + CI_SIZE);
			PrimParams += PrimLinkTarget("VisibleStatus 5", LinkNum) + PrimPosRot(Pos, PagePrimRot) + PrimSize(Size) + PrimColor(FACE_IMAGE, COLOR_WHITE, Alpha);
		}
	}
	// We always hide the splash prim if not actually being displayed
	if (!SplashOn) {
		PrimParams += PrimLinkTarget("VisibleStatus 6", SplashPrim) + PrimPosRot(POS_STASH, PagePrimRot) + PrimSize(SIZE_TINY) + PrimColor(ALL_SIDES, COLOR_WHITE, ALPHA_TRANSPARENT);
	}
	// Backer prim
	if (AllVisible) {
		PrimParams +=
			PrimLinkTarget("VisibleStatus 7", BackerPrim) +
			PrimPosRot(PagePrimPosCurrent + <0.1, 0.0, 0.0>, PagePrimRot) +
			PrimSize(PagePrimSize) +
			PrimColor(ALL_SIDES, BackerColor, ALPHA_NORMAL);
	}
	else {
		PrimParams +=
			PrimLinkTarget("VisibleStatus 8", BackerPrim) +
			PrimPosRot(POS_STASH, PagePrimRot) +
			PrimSize(SIZE_TINY) +
			PrimColor(ALL_SIDES, COLOR_WHITE, ALPHA_TRANSPARENT);
	}
	// Status background and text prims
	if (AllVisible) {
		PrimParams +=
			PrimLinkTarget("VisibleStatus 9", FloatBackPrim) +
			PrimPosRot(FloatBackPos, PagePrimRot) +
			PrimSize(<PagePrimSize.x, FloatBackHeight, 0.01>) +
			PrimColor(ALL_SIDES, FloatBackColor, ALPHA_NORMAL);
		PrimParams +=
			PrimLinkTarget("VisibleStatus 12", FloatTextPrim) +
			PrimPosRot(FloatTextPos, PagePrimRot);
		// text prim is invisible
	}
	else {
		PrimParams +=
			PrimLinkTarget("VisibleStatus 11", FloatBackPrim) +
			PrimPosRot(POS_STASH, PagePrimRot) +
			PrimSize(SIZE_TINY) +
			PrimColor(ALL_SIDES, COLOR_WHITE, ALPHA_TRANSPARENT);
		PrimParams +=
			PrimLinkTarget("VisibleStatus 12", FloatTextPrim) +
			PrimPosRot(POS_STASH, PagePrimRot) +
			PrimSize(SIZE_TINY) +
			PrimColor(ALL_SIDES, COLOR_WHITE, ALPHA_TRANSPARENT);
	}
	llSetLinkPrimitiveParamsFast(LINK_ROOT, PrimParams);
}
// Set of routines for setting prim parameters in a central way (easy to implement anti-tweening, etc, hacks)
list PrimLinkTarget(string DebugInfo, integer LinkNum) {
	// we need this next check because invalid link numbers can cause huge problems with OpenSim.exe (eg high CPU that
	// persists even after object is removed from simulator; 0 objects allowed in simulator, etc). To fix, load from an
	// OAR that doesn't have the object in, and restart simulator.
	if (LinkNum <= 0) {
		LogError("Invalid link number encountered!\nInfo: " + DebugInfo);
		LinkNum = llGetNumberOfPrims();	// Set to highest link num
	}
	return [ PRIM_LINK_TARGET, LinkNum ];
}
list PrimPosRot(vector LocalPos, rotation LocalRot) {
	vector HackPos1 = LocalPos;
	vector HackPos2 = LocalPos;
	rotation HackRot = LocalRot * <0.01, 0.01, 0.01, 0.01>;	// a little wiggle helps thumbnails to become visible
	HackPos1.x += 9.0;	// pushing the prim away from the viewer and back again seems to help too
	HackPos2.x += 18.0;
	return [ PRIM_ROT_LOCAL, HackRot, PRIM_ROT_LOCAL, LocalRot, PRIM_POS_LOCAL, HackPos1, PRIM_POS_LOCAL, HackPos2, PRIM_POS_LOCAL, HackPos1, PRIM_POS_LOCAL, LocalPos ];
}
list PrimSize(vector Size) {
	vector HackSize = Size * 200.0;	// not sure if this makes any difference
	return [ PRIM_SIZE, HackSize, PRIM_SIZE, Size ];
}
list PrimColor(integer Face, vector Color, float Alpha) {
	return [ PRIM_COLOR, Face, Color, Alpha ];
}
list PrimTexture(integer Face, string TextureId, vector Repeats, vector Offsets, float Rot) {
	return [ PRIM_TEXTURE, Face, TextureId, Repeats, Offsets, Rot ];
}
TakeControls() {
	llTakeControls(Controls, TRUE, FALSE);
}
integer GetLinkNumbers() {
	list PrimParams = [];
	PagePrims = [];
	ImagePrims = [];
	BackerPrim = -1;
	SplashPrim = -1;
	FloatBackPrim = -1;
	FloatTextPrim = -1;
	CameraJumpModePrim = -1;
	CameraResetPrim = -1;
	JumpBackPrim = -1;
	integer PrimCount = llGetNumberOfPrims();
	integer LinkNum;
	for (LinkNum = 2; LinkNum <= PrimCount; LinkNum++) {
		string PrimName = llGetLinkName(LinkNum);
		if (PrimName == "page") {
			PagePrims += [ "P", -1, LinkNum, 0 ];
			PagePrimsCount++;
			// While we're here, set the texture repeats and offsets
			PrimParams += PrimLinkTarget("GetLinkNumbers", LinkNum) + PrimTexture(FACE_PAGE, TEXTURE_BLANK, PageRepeats, PageOffsets, 0.0);
		}
		else if (PrimName == "image") {
			ImagePrims += [ LinkNum, NULL_KEY, "" ];
		}
		else if (PrimName == "splash") {
			SplashPrim = LinkNum;
		}
		else if (PrimName == "backer") {
			BackerPrim = LinkNum;
		}
		else if (PrimName == "floatback") {
			FloatBackPrim = LinkNum;
		}
		else if (PrimName == "floattext") {
			FloatTextPrim = LinkNum;
		}
		else if (PrimName == "camerajumpmode") {
			CameraJumpModePrim = LinkNum;
		}
		else if (PrimName == "camerareset") {
			CameraResetPrim = LinkNum;
		}
		else if (PrimName == "jumpback") {
			JumpBackPrim = LinkNum;
		}
	}
	PagePrimsCount = llGetListLength(PagePrims) / PP_STRIDE;
	ImagePrimsCount = llGetListLength(ImagePrims) / IM_STRIDE;
	if (!PagePrimsCount) { llOwnerSay("No page prims detected"); return FALSE;	}
	if (!ImagePrimsCount) { llOwnerSay("No image prims detected"); return FALSE; }
	if (SplashPrim == -1)  { llOwnerSay("No splash prim detected"); return FALSE; }
	if (BackerPrim == -1)  { llOwnerSay("No backer prim detected"); return FALSE; }
	if (FloatBackPrim == -1)  { llOwnerSay("No status line background prim detected"); return FALSE; }
	if (FloatTextPrim == -1)  { llOwnerSay("No status line text prim detected"); return FALSE; }
	if (CameraJumpModePrim == -1)  { llOwnerSay("No camera/jump mode prim detected"); return FALSE; }
	if (CameraResetPrim == -1)  { llOwnerSay("No camerea reset prim detected"); return FALSE; }
	if (JumpBackPrim == -1)  { llOwnerSay("No jump back prim detected"); return FALSE; }
	if (PrimParams != []) llSetLinkPrimitiveParamsFast(LINK_THIS, PrimParams);
	return TRUE;
}
// reverse of DumpList2TypedString() in server code
list ParseTypedString2List(string TypedString, string Separator) {
	list Input = llParseStringKeepNulls(TypedString, [ Separator ], []);
	list Output = [];
	integer Len = llGetListLength(Input);
	integer I;
	for (I = 0; I < Len; I++) {
		string Str = llList2String(Input, I);
		string EntryType = llGetSubString(Str, 0, 0);
		string Data = llGetSubString(Str, 1, -1);
		if (EntryType == "s") Output += Str;
		else if (EntryType == "i") Output += (integer)Str;
		else if (EntryType == "f") Output += (float)Str;
		else if (EntryType == "v") Output += (vector)Str;
		else if (EntryType == "r") Output += (rotation)Str;
		else if (EntryType == "k") Output += (key)Str;
		else { llOwnerSay("Invalid entry type in list: " + EntryType); return []; }
	}
	return Output;
}
ProcessHashQueue() {
	if (HashQueueMode) {
		if (HashQueueMode == 1) {
			HashQueueMode = 2;	// so we'll send the queue next time, unless new data arrives
		}
		else {
			MessageObject(TextureStore, HTSM_ADD_TEXTURES + llDumpList2String(HashQueue, "|"));
			HashQueue = [];
			HashQueueMode = 0;
		}
	}
}
HandleCameraSet(list Params) {
	if (CameraJumpMode) {
		vector CameraPos = llList2Vector(Params, 0);
		vector CameraFocus = llList2Vector(Params, 1);
		vector CameraAltPos = llList2Vector(Params, 2);
		// LinkNum is #3 (-1 if detached object)

		if (CameraFocus == PreviousCameraFocus) {	// if they've clicked the same object
			if (CameraAlternate) {	// we're on the alternate view, so switch back to the default view
				CameraAlternate = FALSE;
			}
			else if (CameraAltPos != VEC_NAN){	// it's not currently the alternate view, so switch to alternate view if there is one
				CameraPos = CameraAltPos;
				CameraAlternate = TRUE;
			}
		}
		else {
			// It's a different object, so reset
			CameraAlternate = FALSE;
		}
		SetCamera(CameraPos, CameraFocus);
		CameraJumpShow();
		PreviousCameraFocus = CameraFocus;
		PreviousCameraPos = CameraPos;
	}
}
HandleJumpSet(key AppId, list Params) {
	JumpAppId = AppId;
	if (CameraJumpMode) {
		vector JumpPos = llList2Vector(Params, 0);
		vector JumpLookAt = llList2Vector(Params, 1);
		Jump(JumpPos, JumpLookAt, TRUE);
		CameraJumpShow();
	}
}
// Position camera
SetCamera(vector CameraPos, vector CameraFocus) {
	CameraPositioned = TRUE;
	llClearCameraParams();
	llSetCameraParams([
		CAMERA_ACTIVE, TRUE,
		CAMERA_POSITION_LAG, 2.0,
		CAMERA_POSITION, CameraPos,
		CAMERA_POSITION_LOCKED, TRUE,
		CAMERA_FOCUS, CameraFocus,
		CAMERA_FOCUS_LOCKED, TRUE
		]);
}
ReleaseCamera() {
	if (CameraPositioned) {
		llClearCameraParams();	// release camera
		CameraPositioned = FALSE;
		PreviousCameraFocus = VEC_NAN;
		CameraJumpShow();
	}
}
// Jump
Jump(vector Pos, vector LookAt, integer SavePosition) {
	if (Pos == VEC_NAN)	return; // if there's no data, ignore
	if (LookAt == VEC_NAN) LookAt = Pos;
	// Save avatar position/rotation
	if (SavePosition) {
		LastPosList += llGetPos();
		LastRotList += llGetRot();
		LastListSize++;
		if (LastListSize > MaxListSize) {
			LastPosList = llDeleteSubList(LastPosList, 0, 0);
			LastRotList = llDeleteSubList(LastRotList, 0, 0);
			LastListSize--;
		}
	}
	ReleaseCamera();
	// Tell server to jump
	string Params = llDumpList2String([
		HUDA_TELEPORT,
		OwnerId,
		Pos,
		LookAt
		], "|");
	MessageObject(JumpAppId, Params);
}
CameraJumpSetup() {
	vector PosMode = CameraJumpModeButtonPosIdle;
	vector PosReset = CameraResetButtonPosIdle;
	vector PosBack = JumpBackButtonPosIdle;
	if (LoggedIn) {
		PosMode = CameraJumpModeButtonPosActive;
		PosReset = CameraResetButtonPosActive;
		PosBack = JumpBackButtonPosActive;
	}
	list PrimParams =
		// Mode button
		PrimLinkTarget("CameraModeSetup1", CameraJumpModePrim) +
		PrimPosRot(PosMode, ZERO_ROTATION) +
		PrimSize(CameraJumpModeButtonSize) +
		// Reset button
		PrimLinkTarget("CameraModeSetup2", CameraResetPrim) +
		PrimPosRot(PosReset, ZERO_ROTATION) +
		PrimSize(CameraResetButtonSize) +
		PrimTexture(CAMERA_JUMP_FACE, CameraResetButtonTexture, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0) +
		// Back button
		PrimLinkTarget("CameraModeSetup3", JumpBackPrim) +
		PrimPosRot(PosBack, ZERO_ROTATION) +
		PrimSize(JumpBackButtonSize) +
		PrimTexture(CAMERA_JUMP_FACE, JumpBackButtonTexture, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0);
	// Do it
	llSetLinkPrimitiveParamsFast(LINK_THIS, PrimParams);
	// Set button visibilities
	CameraJumpShow();
}
CameraJumpShow() {
	// Modal camera/jump button
	string CameraJumpModeTexture = CameraJumpModeOffTexture;
	string CameraJumpModeAltTexture = CameraJumpModeOnTexture;
	if (CameraJumpMode) {
		CameraJumpModeTexture = CameraJumpModeOnTexture;
		CameraJumpModeAltTexture = CameraJumpModeOffTexture;
	}
	list PrimParams =
		PrimLinkTarget("CameraModeShow1", CameraJumpModePrim) +
		PrimTexture(CAMERA_JUMP_FACE, CameraJumpModeTexture, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0) +
		PrimTexture(CAMERA_JUMP_BACK, CameraJumpModeAltTexture, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0);
	// Camera reset button
	float Alpha = ALPHA_TRANSPARENT;
	if (CameraPositioned) Alpha = ALPHA_NORMAL;
	PrimParams +=
		PrimLinkTarget("CameraModeShow2", CameraResetPrim) +
		PrimColor(CAMERA_JUMP_FACE, COLOR_WHITE, Alpha);
	// Jump back button
	Alpha = ALPHA_TRANSPARENT;
	if (LastListSize) Alpha = ALPHA_NORMAL;
	PrimParams +=
		PrimLinkTarget("CameraModeShow3", JumpBackPrim) +
		PrimColor(CAMERA_JUMP_FACE, COLOR_WHITE, Alpha);
	// Do it
	llSetLinkPrimitiveParamsFast(LINK_THIS, PrimParams);
}
// Send message to HUD server
MessageServer(string Command, list Params) {
	string ParamString = llDumpList2String(Command + Params, MESSAGE_SEPARATOR);
	Debug("Send to server: " + Command + "/" + ParamString);
	MessageObject(ServerID, ParamString);
}
// Wrapper for osMessageObject() that checks to see if destination exists
MessageObject(key Uuid, string Text) {
	if (ObjectExists(Uuid)) {
		osMessageObject(Uuid, Text);
	}
}
// Messages come in a standard format: command followed by a list of parameters, all separated by MESSAGE_SEPARATOR
// We pass everything back as a list, the 0th element of which is the command and the rest the parameters
list ParseMessage(string Data) {
	return llParseStringKeepNulls(Data, [ MESSAGE_SEPARATOR ], []);
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
// Return true if object has been rezzed in-world (
integer NotWorn() {
	return (!llGetAttached());
}
SetTitle() {
	RenderTexture(-1, 1, FACE_TITLE, TitleId);
	// Set other textures on root
	list PrimParams = [];
	PrimParams += PrimTexture(7, UuidLogo, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0);	// Logo on header
	PrimParams += PrimTexture(6, UuidMinMax, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0);	// Min/max arrow
	// Color the backer prim
	PrimParams += PrimLinkTarget("SetTitle", BackerPrim) + PrimColor(ALL_SIDES, BackerColor, ALPHA_NORMAL);
	llSetLinkPrimitiveParamsFast(LINK_ROOT, PrimParams);
}
RenderTexture(integer PageIndex, integer LinkNum, integer Face, string TextureId) {
	llSetLinkTexture(LinkNum, TextureId, Face);
	vector Repeats = <1.0, 1.0, 0.0>;
	vector Offsets = ZERO_VECTOR;
	// If this is a page, update the VirtualPages table with the texture id
	if (PageIndex > -1) {
		integer Ptr = llListFindList(VirtualPages, [ "P", PageIndex ]);
		if (Ptr == -1) { ShowError("Can't find page to update texture"); return; }
		VirtualPages = llListReplaceList(VirtualPages, [ TextureId ], Ptr + VP_TEXTURE, Ptr + VP_TEXTURE);
		Repeats = PageRepeats;
		Offsets = PageOffsets;
	}
	else if (LinkNum == 1 && Face == FACE_TITLE) {	// it's the HUD title
		Repeats = TITLE_PAGE_REPEATS;
		Offsets = TITLE_PAGE_OFFSETS;
	}
	list PrimParams = PrimLinkTarget("RenderTexture", LinkNum) + PrimTexture(Face, TextureId, Repeats, Offsets, 0.0);
	llSetLinkPrimitiveParamsFast(LINK_THIS, PrimParams);
}
// Get data from activation message sent by HUD server
GetActivateData(list Parts) {
	TimerFrequency = 	(float)		llList2String(Parts, 	1) / 1000.0;	// convert ms to seconds
	TitleText = 					llList2String(Parts, 	2);
	TitleId = 			(key)		llList2String(Parts, 	3);
	RootPrimSize = 		(vector)	llList2String(Parts, 	4);
	PagePrimSize = 		(vector)	llList2String(Parts, 	5);
	PageTextureSize = 	(integer)	llList2String(Parts, 	6);
	PageWidth = 		(integer)	llList2String(Parts, 	7);
	PageHeight = 		(integer)	llList2String(Parts, 	8);
	CameraZoomFactor = 	(float)		llList2String(Parts, 	9);
	UuidLogo = 						llList2String(Parts, 	10);
	UuidMinMax = 					llList2String(Parts, 	11);
	string BackerColorString = 		llList2String(Parts, 	12);
	SplashPrimTexture = 			llList2String(Parts, 	13);
	string FBC = 					llList2String(Parts, 	14);
	FloatBackHeight = 	(float)		llList2String(Parts, 	15);
	string FTCN =					llList2String(Parts, 	16);
	float FTPz = 		(float)		llList2String(Parts, 	17);
	string FTCW =  					llList2String(Parts, 	18);
	// Calculations
	float PageWidthProportion = (float)PageWidth / (float)PageTextureSize;
	PageRepeats = <PageWidthProportion, 1.0, 0.0>;
	PageOffsets = <0.5 + (PageWidthProportion / 2.0), 1.0, 0.0>;
	vector FACE_PAGE_OFFSETS = <0.75, 0.0, 0.0>;

	PagePrimPosCurrent = <0.0, 0.0, -(RootPrimSize.z / 2.0) - (PagePrimSize.y / 2.0)>;	// calculate local pos of page prims according to prim sizes
	PagePrimPosSwapped = PagePrimPosCurrent + <0.3, 0.0, 0.0>;	// Swapped is behind current (hidden)
	PagePrimRot = llEuler2Rot(<0, 90, 270> * DEG_TO_RAD);	// Hardwired because it doesn't make sense to rotate this in config (so many dependencies on this design!)
	BackerColor = HexColor2RGB(BackerColorString );
	// Position backing and generator prim for floating text status line (bottom line)
	FloatBackPos = PagePrimPosCurrent;
	FloatBackPos.z -= (PagePrimSize.y / 2.0) + (FloatBackHeight / 2.0);
	FloatTextPos = FloatBackPos;
	FloatTextPos.z -= FTPz;
	// Convert floating text colors to RGB
	FloatBackColor = HexColor2RGB(FBC);
	FloatTextColorNormal = HexColor2RGB(FTCN);
	FloatTextColorWarn = HexColor2RGB(FTCW);
}
vector HexColor2RGB(string AARRGGBB) {
	float RR = (float)Hex2Int(llGetSubString(AARRGGBB, 2, 3)) / 256.0;
	float GG = (float)Hex2Int(llGetSubString(AARRGGBB, 4, 5)) / 256.0;
	float BB = (float)Hex2Int(llGetSubString(AARRGGBB, 6, 7)) / 256.0;
	return <RR, GG, BB>;
}
integer Hex2Int(string Hex) {
	return (integer)( "0x" + llGetSubString(Hex, 0, 7)  );
}
SetFloatingText() {
	if (!Maximised) {
		llSetLinkPrimitiveParamsFast(FloatTextPrim, [ PRIM_TEXT, "", ZERO_VECTOR, 0.0 ]);
		return;
	}
	UpdateFloatingText = FALSE;
	string Text = FloatingText;
	vector Color = FloatTextColorNormal;
	// if the text begins with "!", remove that char, colour the text with the warning colour and sound the alert
	if (llGetSubString(Text, 0, 0) == "!") {
		if (AlertSound != "") llPlaySound(AlertSound, 0.7);
		Text = llGetSubString(Text, 1, -1);
		Color = FloatTextColorWarn;
	}
	if (Text != "") {
		integer VariablePtr = llSubStringIndex(Text, "$");	// if the text contains a $ sign, it indicates a single-letter variable
		if (VariablePtr > -1) {
			string Variable = llGetSubString(Text, VariablePtr + 1, VariablePtr + 1);	// get the actual variable
			string Value = "?";
			if (Variable == "C") {
				vector CameraRotV = llRot2Euler(llGetCameraRot() * NORTH_CORRECTION) * RAD_TO_DEG;
				Value = (string)(-llRound(CameraRotV.z));
				UpdateFloatingText = TRUE;
			}
			Text = llGetSubString(Text, 0, VariablePtr - 1) + Value + llGetSubString(Text, VariablePtr + 2, -1);	// substitute value for variable in text
		}
	}
	llSetLinkPrimitiveParamsFast(FloatTextPrim, [ PRIM_TEXT, Text, Color, 1.0 ]);
}
ClearData() {
	Debug("Clear data");
	// Clear VirtualPages table
	VirtualPages = [];
	VirtualPagesCount = 0;
	// Reset data in PagePrims table
	integer Len = PagePrimsCount * PP_STRIDE;
	integer PrimPtr;
	for (PrimPtr = 0; PrimPtr < Len; PrimPtr += PP_STRIDE) {
		integer PageIndex = llList2Integer(PagePrims, PrimPtr + PP_PAGE_INDEX);
		if (PageIndex > -1) {
			integer LinkNum = llList2Integer(PagePrims, PrimPtr + PP_LINKNUM);
			PagePrims = llListReplaceList(PagePrims,
				[ "P", -1, LinkNum, 0 ],
				PrimPtr, PrimPtr + PP_STRIDE - 1);
		}
	}
	// Clear images
	list NewImages = [];
	integer Thumb;
	for (Thumb = 0; Thumb < ImagePrimsCount; Thumb++) {
		integer Ptr = Thumb * IM_STRIDE;
		integer LinkNum = llList2Integer(ImagePrims, Ptr + IM_LINKNUM);
		NewImages += [ LinkNum, NULL_KEY, "" ];
	}
	ImagePrims = NewImages;
	CurrentPagePrim = -1;
	CurrentPageLinkNum = -1;
}
ReadConfig() {
	// Set config defaults
	CameraJumpModeButtonPosActive = <0.2, -0.154, 0.0>;
	CameraJumpModeButtonPosIdle = <0.2, 0.11, 0.0>;
	CameraJumpModeButtonSize = <0.0325, 0.0325, 0.0325>;
	CameraJumpModeOnTexture = TEXTURE_DEFAULT;
	CameraJumpModeOffTexture = TEXTURE_BLANK;

	CameraResetButtonPosActive = <0.2, -0.154, -0.038>;
	CameraResetButtonPosIdle = <0.2, 0.11, -0.038>;
	CameraResetButtonSize = <0.0325, 0.0325, 0.0325>;
	CameraResetButtonTexture = TEXTURE_BLANK;

	JumpBackButtonPosActive = <0.2, -0.154, -0.076>;
	JumpBackButtonPosIdle = <0.2, 0.11, -0.076>;
	JumpBackButtonSize = <0.0325, 0.0325, 0.0325>;
	JumpBackButtonTexture = TEXTURE_BLANK;

	MaxListSize = 1;
	//
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		//LogError("Can't find notecard '" + CONFIG_NOTECARD + "'");
		llOwnerSay("Can't find notecard '" + CONFIG_NOTECARD + "' - execution suspended");
		state Hang;
	}
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
					if (Name == "camerajumpmodebuttonposactive")	CameraJumpModeButtonPosActive = (vector)Value;
					else if (Name == "camerajumpmodebuttonposidle")	CameraJumpModeButtonPosIdle = (vector)Value;
					else if (Name == "camerajumpmodebuttonsize")	CameraJumpModeButtonSize = (vector)Value;
					else if (Name == "camerajumpmodeontexture")		CameraJumpModeOnTexture = Value;
					else if (Name == "camerajumpmodeofftexture")	CameraJumpModeOffTexture = Value;
					else if (Name == "cameraresetbuttonposactive")	CameraResetButtonPosActive = (vector)Value;
					else if (Name == "cameraresetbuttonposidle")	CameraResetButtonPosIdle = (vector)Value;
					else if (Name == "cameraresetbuttonsize")		CameraResetButtonSize = (vector)Value;
					else if (Name == "cameraresetbuttontexture")	CameraResetButtonTexture = Value;
					else if (Name == "jumpbackbuttonposactive")		JumpBackButtonPosActive = (vector)Value;
					else if (Name == "jumpbackbuttonposidle")		JumpBackButtonPosIdle = (vector)Value;
					else if (Name == "jumpbackbuttonsize")			JumpBackButtonSize = (vector)Value;
					else if (Name == "jumpbackbuttontexture")		JumpBackButtonTexture = Value;
					else if (Name == "maxlistsize")					MaxListSize = (integer)Value;
					else {
						LogError("Invalid entry in " + CONFIG_NOTECARD + ":\n" + Line);
					}
				}
			}
		}
	}
}
Splash(integer On) {
	if (On == SplashOn) return;	// no change
	SplashOn = On;
	vector SplashPrimSize = PagePrimSize;
	SplashPrimSize.y += RootPrimSize.z;
	SplashPrimSize *= 1.1;
	vector SplashPrimPos = PagePrimPosCurrent;
	SplashPrimPos.z += (RootPrimSize.z / 2.0);
	SplashPrimPos.x -= 0.5;
	vector Scale = SIZE_TINY;
	vector Pos = POS_STASH;
	float Alpha = ALPHA_TRANSPARENT;
	if (On) {
		Scale = SplashPrimSize;
		Pos = SplashPrimPos;
		Alpha = ALPHA_NORMAL;
	}
	list PrimParams =
		PrimLinkTarget("Splash", SplashPrim) +
		PrimTexture(ALL_SIDES, SplashPrimTexture, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0) +
		PrimPosRot(Pos, PagePrimRot) +
		PrimSize(Scale) +
		PrimColor(ALL_SIDES, COLOR_WHITE, Alpha);
	llSetLinkPrimitiveParamsFast(LINK_THIS, PrimParams);
}
RegionChange() {
	Debug("Clearing hash data on region change");
	HashTable = [];
	HashQueue = [];
	HashQueueMode = 0;
	TextureStore = NULL_KEY;
	LastPosList = [];
	LastListSize = 0;
	ClearData();
}
string GetHudVersion() {
	string Name = llGetObjectName();
	string VersionString = llGetSubString(Name, llSubStringIndex(Name, "~") + 1, -1);	// Find part of object name following ~ character
	return("RezMela HUD version " + VersionString);
}
// Set debug mode according to root prim description
SetDebug() {
	DebugMode = (llGetObjectDesc() == "debug");
}
string GetVersion() {
	string S = llGetScriptName();
	integer P = llStringLength(S);
	//	while (--P && llGetSubString(S, P, P) != " ") {}
	integer Loop = TRUE;
    while (Loop) {
        Loop = FALSE;
        P--; 
        if (P > 0 && llGetSubString(S, P, P) != " ") Loop = TRUE;
    }	
	P++;
	if (llGetSubString(S, P, P) == "v") P++;
	S = llGetSubString(S, P, -1);
	if ((float)S == 0.0) llOwnerSay("WARNING: cannot find version number of HUD attachment script!");
	return S;
}
SendVersion(key Id) {
	MessageObject(Id, llDumpList2String( [
		"HUDV",
		GetVersion()
		], "/"));
}
ShowError(string Text) {
	llDialog(OwnerId, "\nERROR!\n\n" + Text, [ "OK" ], -9999999);
}
Debug(string Text) {
	if (DebugMode) llOwnerSay(Text);
}
DebugDump() {
	llOwnerSay("Start dump ----------------------------------------------------------");
	string D = "VirtualPages (" + (string)VirtualPagesCount + "):\n";
	integer I;
	for (I = 0; I < llGetListLength(VirtualPages); I += VP_STRIDE) {	// lazy, but unimportant in context
		D += llDumpList2String(llList2List(VirtualPages, I, I + VP_STRIDE - 1), "|") + "\n";
	}
	llOwnerSay("Debug:\n" + D);
	D = "PagePrims (" + (string)PagePrimsCount + "):\n";
	for (I = 0; I < llGetListLength(PagePrims); I += PP_STRIDE) {
		if (llList2Integer(PagePrims, I + PP_PAGE_INDEX) > -1) {	// ignore spares
			D += llDumpList2String(llList2List(PagePrims, I, I + PP_STRIDE - 1), "|") + "\n";
		}
	}
	llOwnerSay(D);
	D = "ImagePrims (" + (string)ImagePrimsCount + "):\n" ;
	for (I = 0; I < llGetListLength(ImagePrims); I += IM_STRIDE) {
		D += (string)I + ": " + llDumpList2String(llList2List(ImagePrims, I, I + IM_STRIDE - 1), " ") + "\n";
	}
	llOwnerSay(D);
	llOwnerSay("End dump ------------------------------------------------------------");
}
LogError(string Text) {
	llMessageLinked(LINK_ROOT, -7563234, Text, OwnerId);
}
default {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		Debug("Script starting");
		LoggedIn = FALSE;
		OwnerId = llGetOwner();
		MyVersion = GetVersion();
		ServerID = NULL_KEY;
		TextureStore = NULL_KEY;
		JumpAppId = NULL_KEY;
		PreviousCameraFocus = PreviousCameraPos = VEC_NAN;
		CameraAlternate = FALSE;
		HashTable = [];
		TitleText = "";
		SplashPrimTexture = TEXTURE_BLANK;
		AlertSound = "";
		if (llGetInventoryNumber(INVENTORY_SOUND) > 0)
			AlertSound = llGetInventoryName(INVENTORY_SOUND, 0);
		HashQueueMode = 0;
		//DebugMode = TRUE;
		if (llGetNumberOfPrims() == 1) return;	// Stop doing anything if unlinked
		if (!GetLinkNumbers()) return;
		if (NotWorn()) state Maintenance;
		CameraJumpMode = FALSE;
		CameraJumpSetup();
		LastPosList = [];
		LastListSize = 0;
		TimerFrequency = 1.0;	// default, might be overwritten when activation data rec'd
		ClearData(); // Still not sure if this should be done when activated, but if so be careful that the client application knows this and resends all page data (and needs much testing) JFH
		llRequestPermissions(OwnerId, PERMISSION_TAKE_CONTROLS | PERMISSION_CONTROL_CAMERA | PERMISSION_TRACK_CAMERA);
	}
	run_time_permissions(integer Perms) {
		//if (Perms & PERMISSION_CONTROL_CAMERA)
		state Standby;
	}
}
state Standby {
	on_rez(integer S) {
		Debug("on_rez Standby");
		if (NotWorn()) llResetScript();
	}
	state_entry() {
		SetDebug();
		Debug("Standby state");
		ReadConfig();
		llRegionSay(HUD_CHANNEL, "R");	// "ready" signal for HUD server
		LoggedIn = FALSE;
		SplashOn = FALSE;
		ServerID = NULL_KEY;
		VisibleStatus(FALSE, FALSE);
		llReleaseControls();
		VersionNumberSeen = FALSE;
		FloatingText = "";
		ReleaseCamera();
		CameraJumpMode = FALSE;
		CameraJumpSetup();
		SetFloatingText();
		Controls = 0;
	}
	touch_start(integer Count) {
		integer LinkNum = llDetectedLinkNumber(0);
		HandleTouch(LinkNum, 0.0, 0.0);
	}
	dataserver(key Id, string Data) {
		list Parts = ParseMessage(Data);
		string Command = llList2String(Parts, 0);
		list Params = llList2List(Parts, 1, -1);
		if (Command == HUD_MESSAGE_HELLO) {		// HUD server establishing contact
			ServerID = Id;
			state Normal;
		}
		else if (Command == HUDA_CAMERA_SET) {	// message direct from ML to set camera
			HandleCameraSet(Params);
		}
		else if (Command == HUDA_JUMP_SET) {	// message direct from ML to jump
			HandleJumpSet(Id, Params);
		}
		else if (Command == HUD_MESSAGE_GET_VERSION) {
			SendVersion(Id);
		}
	}
	attach(key Attached) {
		llResetScript();
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) llResetScript();
		if (Change & CHANGED_OWNER) llResetScript();
		if (Change & CHANGED_REGION) {
			RegionChange();
			state ReStandby;
		}
		if (Change & CHANGED_INVENTORY) ReadConfig();
	}
}
state ReStandby { state_entry() { state Standby; } }
state Normal {
	on_rez(integer S) {
		Debug("on_rez Normal");
		if (NotWorn()) llResetScript();
		state Standby;
	}
	state_entry() {
		SetDebug();
		Debug("Normal state");
		LoggedIn = TRUE;
		llRegionSay(HTS_CHANNEL, HTSC_REQUEST_DATA);	// Requeset cache data from the Texture Store
		// When they log in, turn off camera mode. Otherwise, we'd have to communicate the camera mode to
		// the ML as part of the login process - possible, but a pain (bear in mind the timing of the login
		// process). Note ref# 18391077
		//ReleaseCamera();
		CameraJumpMode = FALSE;
		CameraJumpSetup();
		CurrentImages = [];
		CameraTracking = FALSE;
		UpdateFloatingText = FALSE;
		// At this stage, we have received a hello message from the server, meaning that our owner has clicked
		// on the activate button for that application. We have the UUID of that server in ServerID.
		MessageServer(HUD_MESSAGE_HELLO, [ MyVersion ]);	// say hello back, giving our version
		llSetTimerEvent(TimerFrequency);
	}
	touch_start(integer Count) {
		integer LinkNum = llDetectedLinkNumber(0);
		vector TouchST = llDetectedTouchST(0);
		//		if (LinkNum == 1 && llDetectedTouchFace(0) == 7 && llGetOwner() == (key)"7abfded3-4df7-420e-bed6-37f8eb2c9fd0") {	// John clicked on logo %%%
		//			DebugDump();
		//			return;
		//		}
		HandleTouch(LinkNum, TouchST.x, TouchST.y);
	}
	dataserver(key Id, string Data) {
		list Parts = ParseMessage(Data);
		string Command = llList2String(Parts, 0);
		list Params = llList2List(Parts, 1, -1);
		if (Id == ServerID) {
			if (Command == HUD_MESSAGE_ACTIVATE) {
				GetActivateData(Parts);	// extract data from message
				Splash(TRUE);
				VisibleStatus(TRUE, TRUE);
				SetTitle();
				MessageServer(HUD_MESSAGE_READY, []);
			}
			else if (Command == HUD_MESSAGE_DEACTIVATE) {
				ProcessHashQueue();
				ProcessHashQueue();	// call it twice to make sure it sends the data
				state Standby;
			}
			else if (Command == HUD_MESSAGE_HELLO) {	// "hello" from a current server - shouldn't happen, but respond accordingly
				state ReloadNormal;
			}
			else if (Command == HUD_MESSAGE_GET_VERSION) {
				SendVersion(Id);
			}
			// Handle all other messages
			HandleServerMessage(Command, Params);
		}
		else if (Command == HUD_MESSAGE_HELLO) {	// "hello" from a server other than the current one, so we switch
			MessageServer(HUD_MESSAGE_DEACTIVATE, []);
			ServerID = Id;
			state ReloadNormal;
		}
		else if (Command == HUDA_CAMERA_SET) {	// message direct from ML to set camera
			HandleCameraSet(Params);
		}
		else if (Command == HUDA_JUMP_SET) {	// message direct from ML to jump
			HandleJumpSet(Id, Params);
		}
		else if (llGetSubString(Data, 0, 3) == HTSM_SEND_DATA) {
			Data = llGetSubString(Data, 4, -1);
			list NewHash = llParseStringKeepNulls(Data, [ "|" ], []);
			if (llGetListLength(NewHash) > llGetListLength(HashTable)) HashTable = NewHash;	// we only store their data if it's sufficient (ie not a newly-rezzed store)
			TextureStore = Id;
		}
	}
	timer() {
		if (!ObjectExists(ServerID)) state Standby;
		if (UpdateFloatingText) SetFloatingText();
		ProcessHashQueue();
	}
	attach(key Attached) {
		llResetScript();
	}
	run_time_permissions(integer Perms) {
		if (Perms & PERMISSION_TAKE_CONTROLS) {
			TakeControls();
		}
	}
	control(key Id, integer Level, integer Edge) {
		integer Start = Level & Edge;
		if (Start) {
			MessageServer(HUD_MESSAGE_TAKE_CONTROL, [ Start ]);		}
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) llResetScript();
		if (Change & CHANGED_OWNER) llResetScript();
		if (Change & CHANGED_REGION) {
			RegionChange();
			state ReStandby;
		}
		if (Change & CHANGED_INVENTORY) ReadConfig();
	}
}
state ReloadNormal {
	on_rez(integer S) {
		if (NotWorn()) llResetScript();
	}
	state_entry() {
		state Normal;
	}
}
// This state is for the HUD being rezzed in-world for working on it
state Maintenance {
	on_rez(integer S) {
		llResetScript();
	}
	state_entry() {
		llOwnerSay("HUD rezzed in-world (" + (string)PagePrimsCount + " pages, " + (string)ImagePrimsCount + " images)");
		SetDebug();
		VisibleStatus(TRUE, TRUE);	// Make sure I'm not invisible
		// Arrange prims for easy editing
		RootPrimSize = <0.001, 0.2, 0.025>;	// default root prim size because we're not getting it from the server (because we're not connected to it)
		list PrimParams = [];
		PrimParams += PrimLinkTarget("Maintenance 1", 1) + PrimSize(RootPrimSize) + PrimTexture(ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0);
		vector LocalPos = <0.02, 0.0, 0.0>;
		rotation LocalRot = llEuler2Rot(<0.0, 90.0, 270.0> * DEG_TO_RAD);
		integer Page;
		for (Page = 0; Page < PagePrimsCount; Page++) {
			integer P = Page * PP_STRIDE;
			integer LinkNum = llList2Integer(PagePrims, P + PP_LINKNUM);
			PrimParams += PrimLinkTarget("Maintenance 2", LinkNum) + [
				PRIM_POS_LOCAL, LocalPos,
				PRIM_SIZE, <0.02, 0.02, 0.01>,
				PRIM_ROT_LOCAL, LocalRot,
				PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.0,
				PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
					];
			LocalPos.x += 0.012;
			if (Page % 4 == 3) LocalPos.x += 0.008;	// group in 4s
			if (Page % 16 == 15) LocalPos.x += 0.008;	// group in 16s
		}
		LocalPos = <0.02, 0.04, 0.0>;
		integer Image;
		for (Image = 0; Image < ImagePrimsCount; Image++) {
			integer Ptr = Image * IM_STRIDE;
			integer LinkNum = llList2Integer(ImagePrims, Ptr + IM_LINKNUM);
			PrimParams += PrimLinkTarget("Maintenance 3", LinkNum) + [
				PRIM_POS_LOCAL, LocalPos,
				PRIM_SIZE, <0.02, 0.02, 0.01>,
				PRIM_ROT_LOCAL, LocalRot,
				PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.0,
				PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
					];
			LocalPos.x += 0.012;
			if (Image % 4 == 3) LocalPos.x += 0.008;	// group in 4s
		}
		PrimParams += PrimLinkTarget("Maintenance 4", SplashPrim) + [
			PRIM_POS_LOCAL, <0.02, -0.04, 0.0>,
			PRIM_SIZE, <0.02, 0.02, 0.01>,
			PRIM_ROT_LOCAL, LocalRot,
			PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.0,
			PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
				];
		PrimParams += PrimLinkTarget("Maintenance 5", BackerPrim) + [
			PRIM_POS_LOCAL, <0.032, -0.04, 0.0>,
			PRIM_SIZE, <0.02, 0.02, 0.01>,
			PRIM_ROT_LOCAL, LocalRot,
			PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.0,
			PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
				];
		PrimParams += PrimLinkTarget("Maintenance 6", CameraJumpModePrim) + [
			PRIM_POS_LOCAL, <0.02, -0.08, 0.0>,
			PRIM_SIZE, <0.02, 0.02, 0.01>,
			PRIM_ROT_LOCAL, LocalRot,
			PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.0,
			PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
				];
		PrimParams += PrimLinkTarget("Maintenance 8", CameraResetPrim) + [
			PRIM_POS_LOCAL, <0.032, -0.08, 0.0>,
			PRIM_SIZE, <0.02, 0.02, 0.01>,
			PRIM_ROT_LOCAL, LocalRot,
			PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.0,
			PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
				];
		PrimParams += PrimLinkTarget("Maintenance 9", JumpBackPrim) + [
			PRIM_POS_LOCAL, <0.044, -0.08, 0.0>,
			PRIM_SIZE, <0.02, 0.02, 0.01>,
			PRIM_ROT_LOCAL, LocalRot,
			PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.0,
			PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
				];
		llSetLinkPrimitiveParamsFast(LINK_THIS, PrimParams);
	}
	attach(key Attached) {
		if (Attached == NULL_KEY) ReleaseCamera();
		llResetScript();
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) llResetScript();
	}
}
state Hang { on_rez(integer S) { llResetScript(); } state_entry() { }}
// RezMela HUD attachment v1.4.0