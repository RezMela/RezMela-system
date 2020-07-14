// ML cataloguer v1.7.6

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

// v1.7.6 - use UUIDs instead of link numbers; add "CommsType" to C card
// v1.7.5 - improved comms for rezzing objects
// v1.7.4 - split objects data into static and dynamic
// v1.7.3 - added robustness to startup handshaking, more debugging info
// v1.7.2 - wait for CT_START before processing
// v1.7.1 - rewrite waiting queue (WaitModules) handling
// v1.7.0 - send catalogue when requested; reduce memory usage; add debug feature
// v1.6 - improve checking of modules notecard
// v1.5 - send catalogue at start rather by request
// v1.4 - add "CopyRotation", "Resizable"
// v1.3 - make "Phantom" default to True
// v1.2 - new error handler
// v1.1 - pass libraries data to ML
// v1.0 - detect duplicate modules
// v0.22 - add longer jump behaviour for module positioning >10m
// v0.21 - new module organisation
// v0.20 - implement StickPoints
// v0.19 - add alternative camera position
// v0.18 - add jump-to-sit
// v0.17 - add "IgnoreRotation" and "IgnoreBinormal"
// v0.16 - add jump pos & lookat
// v0.15 - add camera pos & focus
// v0.14 - higher timeout for library module responses
// v0.13 - snap to region grid
// v0.12 - improve parsing of "name = value" syntax
// v0.11 - snap to grid
// v0.10 - "apps in maps" stuff
// v0.9 - allow more time for modules to start up, module sort order by config
// v0.8 - reverse order of modules (bottom to top instead of top to bottom) when calculating category sequence
// v0.7 - allow for Map object data to be processed
// v0.6 - changed to broadcast method for rezzing objects (was losing track of link numbers during loading of large scenes)
// v0.5 - added reset
// v0.4 - add more data to config card
// v0.3 - bug fix
// v0.2 - fixed startup timing problem

integer DEBUGGER = -391867620;
integer DebugMode = FALSE;
string DebugId = "????";

string MODULES_NOTECARD = "Modules";

vector VEC_NAN = <-99.0,99.0,-99.0>;    // nonsense value to indicate "not a number" for vectors (must be consistent across scripts)

// My LMs
integer CT_REQUEST_DATA		= -83328400;
integer CT_CATALOG 			= -83328401;
integer CT_START			= -83328402;
integer CT_REZZED_ID		= -83328404;
integer CT_ARRANGE_PRIMS	= -83328405;
integer CT_ERRORS			= -83328406;
integer CT_MODULES			= -83328407;
integer CT_READY			= -83328408;

// Librarian's LMs
integer LIB_GET_DATA	= -879189100;
integer LIB_CATEGORIES 	= -879189101;
integer LIB_METADATA	= -879189102;
integer LIB_REZ_OBJECT 	= -879189120;

// ML main's LMs
integer LM_EXTERNAL_LOGIN = -405521;
integer LM_EXTERNAL_LOGOUT = -405522;
integer LM_RESET = -405535;
integer LM_PUBLIC_DATA = -405546;

// Basic list of modules from notecard
list Modules;

list CatalogErrors;

string CurrentNotecard;

list Libraries;
integer LB_INDEX = 0;	// held -ve so we can find on link number
integer LB_MODULE_ID = 1;
integer LB_NAME = 2;
integer LB_CATALOG = 3;
integer LB_STRIDE = 4;
integer LibrariesCount = 0;

list Objects;
integer OBJ_NAME = 0;
// Static data is from 0 to 5
integer OBJ_LIBINDEX 		= 7;	// sort key value for library
// For positions of other fields, see end of ProcessObjectData()
integer OBJ_STRIDE 			= 34;
integer ObjectsCount = 0;	// number of rows

list ModuleIds = [];		// UUIDs of all modules
list WaitModules = [];	// UUIDs of modules we're waiting for data from
integer Retries = 0;	// have we retried contacting the libraries?
integer LibDataReceived = FALSE;	// Have we received all data?

// "Public" data
vector ModuleSize;
vector ModulePosNormal;
vector ModulePosHidden;

integer DataRequested = FALSE;

key AvId;

SendData() {
	if (CatalogErrors != []) {
		Debug((string)llGetListLength(CatalogErrors) + " catalog errors, eg: " + llList2String(CatalogErrors, 0));
		llMessageLinked(LINK_THIS, CT_ERRORS, llDumpList2String(CatalogErrors, "\n"), AvId);
		return;
	}
	// First, send all library catalog data
	list SendModules = [];
	Libraries = llListSort(Libraries, LB_STRIDE, TRUE);
	string CategoryData = "";
	integer P;	// general purpose pointer
	for (P = 0; P < LibrariesCount; P++) {
		integer Q = P * LB_STRIDE;
		string Name = llList2String(Libraries, Q + LB_NAME);
		integer Index = llList2Integer(Libraries, Q + LB_INDEX);
		string CatalogEntry = llList2String(Libraries, Q + LB_CATALOG);
		CategoryData += CatalogEntry + "\n";
		SendModules += [ Index, Name ];
	}
	// Now send a list of modules with LibIndex for each
	llMessageLinked(LINK_ROOT, CT_MODULES, llDumpList2String(SendModules, "|"), NULL_KEY);
	// Next, send all objects data
	// Each object is on a separate line, and the elements are |-separated, in the order they're stored
	string ObjectsData = "";
	for (P = 0; P < ObjectsCount; P++) {
		integer Q = P * OBJ_STRIDE;
		list DataList = llList2List(Objects, Q, Q + OBJ_STRIDE - 1);
		ObjectsData += llDumpList2String(DataList, "|") + "\n";
	}
	string CatalogData = llStringToBase64(CategoryData) + "|" + llStringToBase64(ObjectsData);
	llMessageLinked(LINK_ROOT, CT_CATALOG, CatalogData, NULL_KEY);
	// Free up memory
	Libraries = [];
	LibrariesCount = 0;
	Objects = [];
	ObjectsCount = 0;
}
ProcessObjects(key ModuleId, string sData) {
	// First, find the library this is from
	integer LibPtr = llListFindList(Libraries, [ ModuleId ]);
	// If it doesn't exist, ignore (it's probably not in the Modules notecard)
	if (LibPtr == -1) return;
	LibPtr -= LB_MODULE_ID;	// position at start of stride
	integer LibIndex = llList2Integer(Libraries, LibPtr + LB_INDEX);
	// Now process the data
	list Data = llParseStringKeepNulls(sData, [ "|" ], []);
	// Data is in pairs, [ name, configdata ]
	integer Len = llGetListLength(Data);
	integer P;
	for (P = 0; P < Len; P += 2 ) {
		string ObjectName = llList2String(Data, P);
		string ObjectData = llBase64ToString(llList2String(Data, P + 1));
		ProcessObjectData(ObjectName, LibIndex, ObjectData);
	}
}
ProcessObjectData(string ObjectName, integer LibIndex, string ObjectData) {
	string ShortDesc = "";
	string LongDescBase64  = "";
	key ThumbnailId = TEXTURE_TRANSPARENT;
	key PreviewId = TEXTURE_TRANSPARENT;
	float RandomResize = 0.0;
	integer RandomRotate = FALSE;
	integer Detached = FALSE;
	integer AutoHide = FALSE;
	string Source64 = "";
	float SizeFactor = 1.0;
	vector OffsetPos = VEC_NAN;
	vector OffsetRot = VEC_NAN;
	vector CameraPos = VEC_NAN;
	vector CameraAltPos = VEC_NAN;
	vector CameraFocus = VEC_NAN;
	vector JumpPos = VEC_NAN;
	vector JumpLookAt = VEC_NAN;
	integer Sittable = FALSE;
	integer DoRotation = TRUE;
	integer DoBinormal = TRUE;
	integer CopyRotation = FALSE;
	integer Center = FALSE;
	integer AdjustHeight = FALSE;
	integer DummyMove = FALSE;
	string StickPointsRaw = "";
	vector SnapGrid = ZERO_VECTOR;
	vector RegionSnap = ZERO_VECTOR;
	integer Resizable = TRUE;
	integer Phantom = TRUE;
	integer Floating = FALSE;
	integer IsApp = FALSE;
	integer CommsType = 0;
	list Lines = llParseStringKeepNulls(ObjectData, [ "\n" ], []);
	integer LineCount = llGetListLength(Lines);
	integer I;
	for(I = 0; I < LineCount; I++) {
		string Line = llList2String(Lines, I);
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
					if (Name == "shortdesc") ShortDesc = StripQuotesMloConfig(ObjectName, Value, Line);
					else if (Name == "longdesc") LongDescBase64 = llStringToBase64(StripQuotesMloConfig(ObjectName, Value, Line));
					else if (Name == "preview") PreviewId = (key)Value;
					else if (Name == "thumbnail") ThumbnailId = (key)Value;
					else if (Name == "randomsize") RandomResize = (float)Value;
					else if (Name == "randomrot") RandomRotate = String2Bool(Value);
					else if (Name == "detached") Detached = String2Bool(Value);
					else if (Name == "autohide") AutoHide = String2Bool(Value);
					else if (Name == "source") Source64 = llStringToBase64(Value);
					else if (Name == "sizefactor") SizeFactor = (float)Value;
					else if (Name == "offsetpos") OffsetPos = (vector)Value;
					else if (Name == "offsetrot") OffsetRot = (vector)Value;
					else if (Name == "camerapos") CameraPos = (vector)Value;
					else if (Name == "cameraaltpos") CameraAltPos = (vector)Value;
					else if (Name == "camerafocus") CameraFocus = (vector)Value;
					else if (Name == "jumppos") JumpPos = (vector)Value;
					else if (Name == "jumplookat") JumpLookAt = (vector)Value;
					else if (Name == "sittable") Sittable = String2Bool(Value);
					else if (Name == "dorotation") DoRotation = String2Bool(Value);
					else if (Name == "ignorerotation") DoRotation = !String2Bool(Value);
					else if (Name == "dobinormal") DoBinormal = String2Bool(Value);
					else if (Name == "ignorebinormal") DoBinormal = !String2Bool(Value);
					else if (Name == "copyrotation") CopyRotation = String2Bool(Value);
					else if (Name == "center") Center = String2Bool(Value);
					else if (Name == "vertical") DoRotation = !String2Bool(Value);
					else if (Name == "adjustheight") AdjustHeight = String2Bool(Value);
					else if (Name == "dummymove") DummyMove = String2Bool(Value);
					else if (Name == "stickpoint") StickPointsRaw += Value + "|";
					else if (Name == "grid") SnapGrid = ParseSnapGrid(Value);
					else if (Name == "regionsnap") RegionSnap = ParseSnapGrid(Value);
					else if (Name == "resizable") Resizable = String2Bool(Value);
					else if (Name == "phantom") Phantom = String2Bool(Value);
					else if (Name == "floating") Floating = String2Bool(Value);
					else if (Name == "isapp") IsApp = String2Bool(Value);
					else if (Name == "commstype") CommsType = (integer)Value;
					else if (Name == "modify") { integer needsomethinghere = 1; }	// This is a keyword that was never used, but we retain it for compatibility
					else ConfigError(ObjectName, "Invalid keyword: '" + OName + "'");
				}
				else {
					ConfigError(ObjectName, "Invalid line: " + Line);
				}
			}
		}
	}
	string StickPoints64 = llStringToBase64(llGetSubString(StickPointsRaw, 0, -2)); // Ignore last character, which is |
	if (PreviewId == TEXTURE_TRANSPARENT) PreviewId = ThumbnailId;
	// Static data is kept loaded at all times by the ML. Dynamic data is only loaded when the user is signed in.
	Objects += [
		// Static data
		ObjectName, // 0
		CameraPos, // 1
		CameraAltPos,
		CameraFocus,
		JumpPos,
		JumpLookAt, // 5
		Phantom,
		AutoHide, // 7
		// Dynamic data
		LibIndex, // 8
		ShortDesc,
		LongDescBase64, // 10
		ThumbnailId,
		PreviewId,
		RandomRotate,
		RandomResize,
		Detached, // 15
		Source64,
		SizeFactor,
		OffsetPos,
		OffsetRot,
		Sittable, // 20
		DoRotation,
		DoBinormal,
		Center,
		AdjustHeight,
		DummyMove, // 25
		Resizable,
		Floating,
		IsApp,
		StickPoints64,
		SnapGrid, // 30
		RegionSnap,
		CopyRotation, // 32
		CommsType // 33
		// If you change this list, don't forget to ensure OBJ_STRIDE is correct (1 more than last column)!
			];
	ObjectsCount++;
}
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
// Based on standard StripQuotes(), just with bespoke error reporting
// Takes a string in double quotes, and strips out the quotes. Validates the format.
// <Text> is the string with quotes; <Line> is the entire line for error reporting
string StripQuotesMloConfig(string ObjectName, string Text, string Line) {
	if (Text == "" || Text == "\"\"") {    // allow null or "" for null value
		return("");
	}
	if (llGetSubString(Text, 0, 0) == "\"" && llGetSubString(Text, -1, -1) == "\"") {     // if surrounded by quotes
		return(llGetSubString(Text, 1, -2));    // strip quotes
	}
	else {
		ConfigError(ObjectName, "Invalid string literal (missing \"\"?): " + Line);
		return("");
	}
}
// Parses the "Grid = " value
vector ParseSnapGrid(string Value) {
	vector SnapGrid = ZERO_VECTOR;
	list L = llCSV2List(Value);
	integer Elements = llGetListLength(L);
	if (Elements > 0) {
		SnapGrid.x = llList2Float(L, 0);	// If only 1 element, set X and Y to that
		SnapGrid.y = llList2Float(L, 0);
		if (Elements > 1) {
			SnapGrid.y = llList2Float(L, 1);	// 2 elements give X and Y
			if (Elements > 2) {
				SnapGrid.z = llList2Float(L, 2);	// and 3 give X, Y and Z
			}
		}
	}
	return SnapGrid;
}
ConfigError(string ObjectName, string Text) {
	llOwnerSay("Error in config file for MLO '" + ObjectName + "':\n" + Text);
}
// Check all modules
ProcessModules() {
	CatalogErrors = [];
	if (llGetInventoryType(MODULES_NOTECARD) != INVENTORY_NOTECARD) {
		LogError("Notecard missing: '" + MODULES_NOTECARD + "'");
		state Hang;
	}
	integer P;	// generic pointer
	// Build list of modules from prim names
	list PrimModules = [];
	ModuleIds = [];
	integer PrimCount = llGetNumberOfPrims();
	for (P = 2; P <= PrimCount; P++) {
		string Name = ExtractModuleName(llGetLinkName(P));
		if (Name != "") {
			PrimModules += Name;
			ModuleIds += llGetLinkKey(P);
		}
	}
	// Build list of modules from notecard
	Modules = [];
	CurrentNotecard = osGetNotecard(MODULES_NOTECARD);
	list RawList = llParseStringKeepNulls(CurrentNotecard, [ "\n" ], []);	// read notecard into list
	integer RawLen = llGetListLength(RawList);
	for (P = 0; P < RawLen; P++) {
		string Line = llStringTrim(llList2String(RawList, P), STRING_TRIM);
		if (Line != "" && llGetSubString(Line, 0, 1) != "//") {
			if (llListFindList(Modules, [ Line ]) > -1) {
				CatalogErrors += "Duplicate module: '" + Line + "'";
			}
			// Check that module prim exists
			else if (llListFindList(PrimModules, [ Line ]) == -1) {
				CatalogErrors += "Module prim doesn't exist: '" + Line + "'";
			}
			else {
				Modules += Line;
			}
		}
	}
}
ProcessCatalogue(key PrimId, string Data) {
	// This comes before objects data, so we initialise the library here
	integer LibPtr = llListFindList(Libraries, [ PrimId ]);
	if (LibPtr > -1) {
		LibPtr -= LB_MODULE_ID;	// position at start of stride
		DeleteLibrary(LibPtr);	// Delete the library if it already exists (together with its objects)
	}
	// Find the associated module from the notecard list
	string ModuleName = ExtractModuleName(GetPrimName(PrimId));
	integer Ptr = llListFindList(Modules, [ ModuleName ]);
	// Ignore module if it's not in the notecard
	if (Ptr == -1) return;
	integer LibIndex = -100000 + Ptr;	// Position in notecard dictates sort key
	Libraries += [ LibIndex, PrimId, ModuleName, Data ];
	LibrariesCount++;
}
DeleteLibrary(integer LibPtr) {
	integer LibIndex = llList2Integer(Libraries, LibPtr + LB_INDEX);
	Libraries = llDeleteSubList(Libraries, LibPtr, LibPtr + LB_STRIDE - 1);
	LibrariesCount--;
	// We delete associated objects by writing to a new list (more efficient than changing the existing list)
	list NewObjects = [];
	integer O;
	for (O = 0; O < ObjectsCount; O++) {
		integer OP = O * OBJ_STRIDE;
		integer ObjectLibIndex = llList2Integer(Objects, OP + OBJ_LIBINDEX);
		if (ObjectLibIndex != LibIndex) {
			NewObjects += llList2List(Objects, OP, OP + OBJ_STRIDE - 1);
		}
	}
	Objects = NewObjects;
	ObjectsCount = llGetListLength(Objects) / OBJ_STRIDE;
}
// Request data from all libraries
GetLibraryData() {
	// Populate list of UUIDs we need to hear from. We store each UUID twice, because we expect two responses
	// from each librarian (category data and objects data).
	WaitModules = ModuleIds + ModuleIds;
	Debug("Getting data from " + (string)(llGetListLength(WaitModules) / 2) + " libraries");
	LibDataReceived = FALSE;
	llMessageLinked(LINK_ALL_CHILDREN, LIB_GET_DATA, "", NULL_KEY);
}
// If it's a library module prim, return its library name, otherwise blank
// Format is: &Lib: <library name>
string ExtractModuleName(string PrimName) {
	if (llGetSubString(PrimName, 0, 4) == "&Lib:") {
		string ModuleName = llGetSubString(PrimName, 5, -1);
		// Remove "~.*" (RE) to get rid of date/version/whatever on prim name
		integer TildePos = llSubStringIndex(ModuleName , "~");
		if (TildePos > -1) ModuleName = llGetSubString(ModuleName , 0, TildePos - 1);
		ModuleName = llStringTrim(ModuleName , STRING_TRIM);
		return ModuleName;
	}
	return "";
}
ArrangePrims(integer Visible) {
	vector HiddenSize = <0.001, 0.001, 0.001>;
	list ModulePrims = [];
	integer PrimCount = llGetNumberOfPrims();
	integer LinkNum;
	for (LinkNum = 2; LinkNum <= PrimCount; LinkNum++) {
		string ModuleName = ExtractModuleName(llGetLinkName(LinkNum));
		if (ModuleName != "") ModulePrims += [ LinkNum, ModuleName ];
	}
	integer ModulePrimsCount = llGetListLength(ModulePrims) / 2;
	integer NormalCounter = 0;
	integer OrphanCounter = 0;
	list PrimParams;
	integer P;
	for (P = 0; P < ModulePrimsCount; P++) {
		integer Q = P * 2;	// stride of 2
		LinkNum = llList2Integer(ModulePrims, Q);
		vector OldPos = llList2Vector(llGetLinkPrimitiveParams(LinkNum, [ PRIM_POS_LOCAL ]), 0);
		PrimParams += PrimLinkTarget("Cataloguer", LinkNum);	// Validate & set PRIM_LINK_TARGET
		PrimParams += [ PRIM_ROT_LOCAL, ZERO_ROTATION ];
		if (Visible) {
			string ModuleName = llList2String(ModulePrims, Q + 1);
			vector Pos;
			integer ModulePosition = llListFindList(Modules, [ ModuleName ]);
			if (ModulePosition > -1) {	// If it's in the Modules notecard
				// set is position vertically according to its place in the notecard
				Pos = ModulePosNormal + <0.0, 0.0, (float)NormalCounter++ * ModuleSize.z>;
			}
			else {	// If it's NOT in the Modules notecard
				// Position it to the side, in a separate stack
				Pos = ModulePosNormal + <-ModuleSize.x, 0.0, (float)OrphanCounter++ * ModuleSize.z>;
			}
			PrimParams += [ PRIM_SIZE, ModuleSize ];
			PrimParams += MoveParams(OldPos, Pos);
			llSetLinkAlpha(LinkNum, 1.0, ALL_SIDES);	// Can't use PrimParams because of colour
		}
		else {
			PrimParams += [ PRIM_SIZE, HiddenSize ];
			PrimParams += MoveParams(OldPos, ModulePosHidden);
			llSetLinkAlpha(LinkNum, 0.0, ALL_SIDES);
		}
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, PrimParams);
}
// Moves a linked prim from a to b
list MoveParams(vector From, vector To) {
	float MoveDistance = llVecDist(From, To);    // calculate distance prim will move
	integer Hops = (integer)(MoveDistance / 10.0) + 1;    // divide it into 10m hops
	list PrimParams = [];
	while(Hops--) {
		PrimParams += [ PRIM_POS_LOCAL, To ];
	}
	return PrimParams;
}
list PrimLinkTarget(string DebugInfo, integer LinkNum) {
	// we need this next check because invalid link numbers can cause huge problems with OpenSim (eg high CPU that
	// persists even after object is removed from simulator; 0 objects allowed in simulator, etc). To fix, load from an
	// OAR that doesn't have the object in, and restart simulator. This was a big problem in 0.8; its status in 0.9 is
	// not presently known.
	if (LinkNum <= 0) {
		LogError("Invalid link number encountered! Info: " + DebugInfo);
		LinkNum = llGetNumberOfPrims();	// Set to highest link num
	}
	return [ PRIM_LINK_TARGET, LinkNum ];
}
string GetPrimName(key PrimId) {
	return llList2String(llGetObjectDetails(PrimId, [ OBJECT_NAME ]), 0);
}
// Set retry timer, in case librarian script(s) haven't loaded.
// It's 25-30 seconds (to avoid simultaneous load when rezzing large number of child Apps)
SetRetryTimer() {
	llSetTimerEvent(25.0 + llFrand(5.0));
}
// Process public data sent by ML
ParsePublicData(string Data) {
	list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
	ModuleSize = (vector)llList2String(Parts, 6);
	ModulePosNormal = (vector)llList2String(Parts, 7);
	ModulePosHidden = (vector)llList2String(Parts, 8);
}
// After receiving a librarian message containing catalogue data or object metadata, we remove it
// from the queue (which for each module contains two entries, one for each type of data). The queue
// is a list of UUIDs. If the queue becomes empty, we send the data to the ML.
CheckSendData(integer LinkNum) {
	key SenderUuid = llGetLinkKey(LinkNum);
	integer P = llListFindList(WaitModules, [ SenderUuid ]);
	if (P > -1) {	// we ignore messages from modules we've already received data from
		WaitModules = llDeleteSubList(WaitModules, P, P);
		if (WaitModules == []) {
			LibDataReceived = TRUE;
			Debug("Sending catalog data");
			SendData();
			llSetTimerEvent(0.0);
		}
	}
}
Debug(string Text) {
	if (DebugMode) {
		llOwnerSay("Cat " + DebugId + ": " + Text);
		llRegionSay(DEBUGGER, "Cat: " + Text);
	}
}
// Set debug mode according to root prim description
SetDebug() {
	if (llGetObjectDesc() == "debug") {
		DebugId = llGetSubString((string)llGetKey(), 0, 3);
		DebugMode = TRUE;
	}
}
DebugDump() {
	integer P;
	string Output = "Libraries [" + (string)LibrariesCount + "]:\n";
	for (P = 0; P < LibrariesCount; P++) {
		integer Q = P * LB_STRIDE;
		integer LibIndex = llList2Integer(Libraries, Q + LB_INDEX);
		integer LibKey	= llList2Integer(Libraries, Q + LB_MODULE_ID);
		string Catalog = llList2String(Libraries, Q + LB_CATALOG);
		Catalog = llDumpList2String(llParseStringKeepNulls(Catalog, [ "\n" ], []), " ");	// turn \n into spaces
		Catalog = llGetSubString(Catalog, 0, 80);
		Output += llDumpList2String([ LibIndex, LibKey, Catalog ], " ") + "\n";
	}
	if (LibrariesCount != (llGetListLength(Libraries) / LB_STRIDE)) {
		Output += "Libraries count is wrong!";
	}
	llOwnerSay(Output);
	Output = "Objects [" + (string)ObjectsCount + "]:\n";
	for (P = 0; P < ObjectsCount; P++) {
		integer Q = P * OBJ_STRIDE;
		string ObjectName = llList2String(Objects, OBJ_NAME);
		integer LibIndex = llList2Integer(Objects, Q + OBJ_LIBINDEX);
		Output += llDumpList2String([ ObjectName, LibIndex ], " ") + "\n";
	}
	if (ObjectsCount != (llGetListLength(Objects) / OBJ_STRIDE)) {
		Output += "Objects count is wrong!";
	}
	llOwnerSay(Output);
}
LogError(string Text) {
	llMessageLinked(LINK_ROOT, -7563234, Text, AvId);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		if (llGetNumberOfPrims() == 1) state Hang; // we're in a box or something
		SetDebug();
		Debug("Loading ...");
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		if (Number == CT_START) { // Message from ML telling us to start processing
			state Normal;
		}
		else if (Number == LM_PUBLIC_DATA) {
			ParsePublicData(Text);
		}
		else if (Number == CT_REQUEST_DATA) {
			// If we get this here, it means that we've been reset after handshaking with other scripts. This
			// happens if the user manually resets scripts via the viewer menus. This is so slow that scripts
			// that have just been reset will handshake with scripts that have not yet been reset, causing
			// problems when the latter (eg this script) actually do get reset.
			DataRequested = TRUE;
			Debug("Received data request while waiting to start");
			state Normal;
		}
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Retries = 0;
		Libraries = [];
		LibrariesCount = 0;
		ProcessModules();
		Debug("Ready");
		llMessageLinked(LINK_THIS, CT_READY, "", NULL_KEY);	// Tell other scripts we're ready
		llSetTimerEvent(0.0);
		if (DataRequested) {	// see above
			GetLibraryData();
			SetRetryTimer(); // Set retry timer, in case librarian script(s) haven't loaded.
		}
	}
	timer() {
		if (!LibDataReceived) {
			if (Retries++ < 10) {
				Debug("Retrying ...");
				GetLibraryData();
				SetRetryTimer();
			}
			else {
				llSetTimerEvent(0.0);
				string ErrorText = "Unresponsive library module(s):";
				// Loop through modules that haven't responded, ignoring ones
				// we've already processed, and generate string of module
				// names to report the error.
				integer I;
				list Done = [];
				integer Len = llGetListLength(WaitModules);
				for (I = 0; I < Len; I++) {
					key Id = llList2Key(WaitModules, I);
					if (llListFindList(Done, [ Id ]) == -1) {
						Done += Id;
						ErrorText += "\n  " + llKey2Name(Id);
					}
				}
				Debug(ErrorText);
				LogError(ErrorText);
			}
		}
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		if (Sender == 1) {	// Message from script in root prim
			if (Number == LM_EXTERNAL_LOGIN) {
				AvId = Id;
			}
			else if (Number == LM_EXTERNAL_LOGOUT) {
				AvId = NULL_KEY;
			}
			else if (Number == CT_REQUEST_DATA) {
				Debug("Received data request");
				GetLibraryData();
				SetRetryTimer(); // Set retry timer, in case librarian script(s) haven't loaded.
			}
			else if (Number == CT_ARRANGE_PRIMS) {
				ArrangePrims((integer)Text);	// argument is 1 if modules are being edited
			}
			else if (Number == LM_RESET) {
				llResetScript();
			}
			else if (Number == LM_PUBLIC_DATA) {
				ParsePublicData(Text);
			}
			else if (Number == CT_START) {
				Debug("Encountered start while in normal mode - restarting");
				state ReNormal;
			}
		}
		else {	// Messages from child prims
			key PrimId = llGetLinkKey(Sender);
			if (Number == LIB_CATEGORIES) {	// Copy of "!Objects" notecard (objects in categories)
				if (DebugMode) Debug("Received Category data from " + llGetLinkName(Sender));
				ProcessCatalogue(PrimId, Text);
				SetRetryTimer();	// Timer may be cancelled in CheckSendData
				CheckSendData(Sender);	// If this is the last data we need, send it all to the ML
			}
			else if (Number == LIB_METADATA) {	// Data from C card (object metadata)
				if (DebugMode) Debug("Received objects metadata from " + llGetLinkName(Sender));
				ProcessObjects(PrimId, Text);
				SetRetryTimer();	// Timer may be cancelled in CheckSendData
				CheckSendData(Sender);	// If this is the last data we need, send it all to the ML
			}
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			// Has the Modules notecard changed?
			string NewNotecard = osGetNotecard(MODULES_NOTECARD);
			if (NewNotecard != CurrentNotecard) {
				// Modules list has changed; reacquire catalog data
				ProcessModules();
				state ReNormal;
			}
		}
	}
}
state ReNormal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() { state Normal; }
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Debug("Hung!");
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llResetScript();
		if (Change & CHANGED_LINK) llResetScript();
	}
}
// ML cataloguer v1.7.6