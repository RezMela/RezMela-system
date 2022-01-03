// ML cataloguer v1.8.4

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

// v1.8.4 - improve behaviour for missing modules
// v1.8.3 - still more bug fixes
// v1.8.2 - more bug fixes
// v1.8.1 - bug fixes, etc
// v1.8.0 - unlinked modules; remove debug
// v1.7.7 - initialisation of objects data before request; some refactoring
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

integer MODULES_CHANNEL = -91823472; // listener channel for modules

// IOM (Inter-Object Message) constants
string IOM_STRING = "£ML-&"; // magic number for inter-object messages via osMessageObject

vector VEC_NAN = <-99.0,99.0,-99.0>;    // nonsense value to indicate "not a number" for vectors (must be consistent across scripts)

// My LMs
integer CT_REQUEST_DATA		= -83328400;
integer CT_CATALOG 			= -83328401;
integer CT_REZ_BATCH		= -83328402;
integer CT_REZ_OBJECTS		= -83328403;
integer CT_REZZED_IDS		= -83328404;
integer CT_ARRANGE_PRIMS	= -83328405;
integer CT_MODULES			= -83328407;
integer CT_WO_RECEIVED		= -83328408;

// Librarian's LMs
integer LIB_GET_DATA	= -879189100;
integer LIB_CATEGORIES 	= -879189101;
integer LIB_METADATA	= -879189102;
integer LIB_REZ_OBJECT 	= -879189120;

// Utils LMs
integer UTIL_WAITING = -181774800;
integer UTIL_GO = -181774801;
integer UTIL_TIMER_SET = -181774802;
integer UTIL_TIMER_CANCEL = -181774803;
integer UTIL_TIMER_RETURN = -181774804;

// ML main's LMs
integer LM_EXTERNAL_LOGIN = -405521;
integer LM_EXTERNAL_LOGOUT = -405522;
integer LM_RESET = -405535;
integer LM_PUBLIC_DATA = -405546;

// HUD Communicator's LMs
integer COM_LOGOUT = -8172621;

// Basic list of modules
list ModulesList;
integer MOD_PRIORITY = 0;
integer MOD_UUID = 1;
integer MOD_MODULE_ID = 2;
integer MOD_DESC = 3;
integer MOD_SER_CATEGORIES = 4;
integer MOD_SER_OBJECTS = 5;
integer MOD_STRIDE = 6;

list ObjectsData;
integer OBJ_NAME = 0;
integer OBJ_MODULE_ID = 8;
integer OBJ_DETACHED = 15;
// For positions of other fields, see end of ProcessObjectData()
integer OBJ_STRIDE = 34;
integer ObjectsCount = 0;	// number of rows

list ObjectsToRez = [];	// Queue of object names that need to be rezzed
list RezzedUuids = []; // Queue of object UUIDs that have been rezzed
integer RezBatchSize = 100; // Maximum size of a batch of rezzed objects

key OwnerId;

integer DataRequested = FALSE;

list ModuleIds = [];		// UUIDs of all modules
list WaitModules = [];	// UUIDs of modules we're waiting for data from
float WaitTimer;
integer DataChanged = FALSE;
string DataHash = ""; // Hash of ModulesList and ObjectsData

key AvId = NULL_KEY;

// We've received an "L" type IOM message from a module. Here, we record the data
ProcessModuleData(key ModuleKey, string Data) {
	// Extract the data segments from the incoming message
	list Segments = llParseStringKeepNulls(Data, [ "^" ], []); // they're separated by ^
	string ModuleId = llList2String(Segments, 0);
	integer ModulePriority = (integer)llList2String(Segments, 1);
	string ModuleDesc = llList2String(Segments, 2);
	string SerializedCategories = llList2String(Segments, 3);
	string SerializedObjects = llList2String(Segments, 4);
	DeleteModuleData(ModuleId); // delete any previous data for this module
	// Now add the module
	ModulesList += [ ModulePriority, ModuleKey, ModuleId, ModuleDesc, SerializedCategories, SerializedObjects ];
	ModulesList = llListSort(ModulesList, MOD_STRIDE, TRUE); // sort modules by priority
	// Now process the data for the objects
	list DataLines = llParseStringKeepNulls(Base64ToString("MD " + ModuleId, SerializedObjects), [ "|" ], []);
	// Data is in pairs, [ name, configdata ]
	integer Len = llGetListLength(DataLines);
	integer P;
	for (P = 0; P < Len; P += 2 ) {
		string ObjectName = llList2String(DataLines, P);
		string ObjectDataString = Base64ToString("OD " + ModuleId, llList2String(DataLines, P + 1));
		ProcessObjectData(ObjectName, ModuleId, ObjectDataString);
	}
}
SendData() {
	if (ModulesList == []) return; // If there are no modules at all, don't send anything
	string NewDataHash = ListHash(ModulesList + ObjectsData);
	if (NewDataHash == DataHash) { // if the modules list or object data hasn't changed
		return;
	}
	DataHash = NewDataHash;
	// First, send all library catalog data
	list SendModules = [];
	integer ModulesCount = llGetListLength(ModulesList); // data count, not no. of rows
	string CategoryData = "";
	integer P;	// general purpose pointer
	for (P = 0; P < ModulesCount; P += MOD_STRIDE) {
		string ModuleId = llList2String(ModulesList, P + MOD_MODULE_ID);
		string ModuleDesc = llList2String(ModulesList, P + MOD_DESC);
		string CatalogData = Base64ToString("SD " + ModuleId, llList2String(ModulesList, P + MOD_SER_CATEGORIES));
		CategoryData += CatalogData + "\n";
		SendModules += [ ModuleId, ModuleDesc ];
	}
	// Now send a list of modules
	llMessageLinked(LINK_ROOT, CT_MODULES, llDumpList2String(SendModules, "|"), NULL_KEY);
	// Next, send all objects data
	// Each object is on a separate line, and the elements are |-separated, in the order they're stored
	string ObjectsDataString = "";
	for (P = 0; P < ObjectsCount; P++) {
		integer Q = P * OBJ_STRIDE;
		list DataList = llList2List(ObjectsData, Q, Q + OBJ_STRIDE - 1);
		ObjectsDataString += llDumpList2String(DataList, "|") + "\n";
	}
	ObjectsDataString = llGetSubString(ObjectsDataString, 0, -2); // strip last "\n"
	string SendData = llStringToBase64(CategoryData) + "|" + llStringToBase64(ObjectsDataString);
	llMessageLinked(LINK_ROOT, CT_CATALOG, SendData, NULL_KEY);
	DataChanged = FALSE; // unless data changes from here on, no need to resend
}
// Initialise library data
ClearData() {
	ModulesList = [];
	ObjectsData = [];
	ObjectsCount = 0;
}
ProcessObjectData(string ObjectName, string ModuleId, string ObjectData) {
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
	integer DoBinormal = TRUE;	integer CopyRotation = FALSE;
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
	ObjectsData += [
		ObjectName, // 0
		CameraPos, // 1
		CameraAltPos,
		CameraFocus,
		JumpPos,
		JumpLookAt, // 5
		Phantom,
		AutoHide, // 7
		ModuleId, // 8
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
// Delete module and objects data for given module ID
// 
DeleteModuleData(string ModuleId) {
	list NewModulesList = [];
	integer ModulesSize = llGetListLength(ModulesList);
	integer ModulesPtr;
	for (ModulesPtr = 0; ModulesPtr < ModulesSize; ModulesPtr += MOD_STRIDE) {
		string ThisModuleId = llList2String(ModulesList, ModulesPtr + MOD_MODULE_ID);
		if (ThisModuleId != ModuleId) {
			NewModulesList += llList2List(ModulesList, ModulesPtr, ModulesPtr + MOD_STRIDE - 1);
		}
	}
	ModulesList = NewModulesList;
	DeleteModuleObjectsData(ModuleId); // we do this inside this block because most of the time there won't be existing data
}
// Remove all entries from ObjectsData for the given module ID
// We do this by creating a temporary list for the new ObjectsData and including
// all objects' data in that list that isn't for the specified module ID.
// This is much cleaner than deleting in situ - remember that deleting elements 
// while cycling through elements is a bad idea. Also, a repeated llListFindlist()
// is a bad idea because of efficiency concerns. So, old list -> new list, one 
// stride at a time! JFH
DeleteModuleObjectsData(string ModuleId) {
	list NewObjectsData = []; // This will replace ObjectsData
	integer Len = ObjectsCount * OBJ_STRIDE;
	integer P;
	for (P = 0; P < Len; P += OBJ_STRIDE) {
		string ThisModuleId = llList2String(ObjectsData, P + OBJ_MODULE_ID);
		if (ThisModuleId != ModuleId) { // If it's not for the module being cleared ...
			// ... include this data in the new list
			NewObjectsData += llList2List(ObjectsData, P, P + OBJ_STRIDE - 1);
		}
		else {
			// We're effectively deleting a row
			ObjectsCount--;
		}
	}
	ObjectsData = NewObjectsData;
}
RezObjects(string Data) {
	ObjectsToRez += llParseStringKeepNulls(Data, [ "|" ], []);
	// This LM only goes to the same script, to trigger a separate event for each batch
	// of objects being rezzed
	llMessageLinked(LINK_THIS, CT_REZ_BATCH, "", NULL_KEY);
}
RezObjectsFromQueue() {
	if (ObjectsToRez == []) return;
	integer RezCount = llGetListLength(ObjectsToRez);
	if (RezCount > RezBatchSize) RezCount = RezBatchSize;
	list ModObjects = [];
	list RezModules = [];
	integer C;
	for (C = 0; C < RezCount; C++) {
		string Name = llList2String(ObjectsToRez, C);
		string ModuleId = ObjectName2ModuleId(Name);
		if (llListFindList(RezModules, [ ModuleId ]) == -1) { // if we haven't recorded this module yet
			// add it in
			if (!ModuleExists(ModuleId)) { // If the module doesn't exist
				// Clear and log them out
				ObjectsToRez = [];
				LogoutUser("Module missing!");
				DeleteModuleData(ModuleId);
				SendData();
				return;
			}
			RezModules += [ ModuleId ];
		}
		ModObjects += [ ModuleId, Name ];
	}
	// RezData consists of strides [ <module id>, <name> ]
	integer RezModulesCount = llGetListLength(RezModules);
	integer ModObjectsLength= llGetListLength(ModObjects);
	integer M;
	for (M = 0; M < RezModulesCount; M++) {
		string ModuleId = llList2String(RezModules, M);
		key ModuleUuid = ModuleId2ModuleUuid(ModuleId);
		if (ModuleUuid == NULL_KEY) {
			llOwnerSay("Module missing or disabled: " + ModuleId + "!");
		}
		else {
			list SendObjects = [];
			list DetachedObjects = [];
			integer R;
			for (R = 0; R < ModObjectsLength; R += 2) {
				string ThisModuleId = llList2String(ModObjects, R);
				if (ThisModuleId == ModuleId) {
					string ObjectName = llList2String(ModObjects, R + 1);
					SendObjects += ObjectName;					
					integer P = llListFindList(ObjectsData, [ ObjectName ]);
					if (P == -1) { LogError("Can't find object for rez data"); return; }
					P -= OBJ_NAME; // position at start of stride
					integer Detached = llList2Integer(ObjectsData, P + OBJ_DETACHED);
					if (Detached) DetachedObjects += ObjectName;
				}
			}
			// If there are detached objects, we want to hear from the module(s) when their WorldObjects scripts have
			// loaded (WO_INITIALISE). So we tell the module which objects we need to hear about.
			if (DetachedObjects != []) SendIom(ModuleUuid, "W", llDumpList2String(DetachedObjects, "^"));
			SendIom(ModuleUuid, "Z", llDumpList2String(SendObjects, "^"));
		}
	}
	ObjectsToRez = llDeleteSubList(ObjectsToRez, 0, RezCount - 1);
	if (ObjectsToRez != []) {	// if there are still objects to rez
		// Request a callback from the ML Utils script
		llMessageLinked(LINK_THIS, UTIL_TIMER_SET, "rez|5|0", NULL_KEY); // tag "rez", duration 5, repeat FALSE
	}
}
// A librarian has sent us a list of ^-separated rezzed UUIDs, so we pass that on to the ML
SendRezzedObjects(string Data) {
	llMessageLinked(LINK_THIS, CT_REZZED_IDS, Data, NULL_KEY); // send list of UUIDs to the ML
}
// Wrapper for llBase64ToString that prevents ugly run-time errors when Base64 string is empty.
// Providing context helps with debugging when this happens.
string Base64ToString(string Context, string Data) {
	if (Data == "") {
		llOwnerSay("Empty data received: " + Context);
		return "";
	}
	return llBase64ToString(Data);
}
key ModuleId2ModuleUuid(string ModuleId) {
	integer Ptr = llListFindList(ModulesList, [ ModuleId ]);
	if (Ptr == -1) return NULL_KEY;
	Ptr -= MOD_MODULE_ID;
	return llList2Key(ModulesList, Ptr + MOD_UUID);
}
string ObjectName2ModuleId(string Name) {
	integer Ptr = llSubStringIndex(Name, ".");
	if (Ptr == -1) return "";
	return llGetSubString(Name, 0, Ptr - 1);
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
// Returns hash of passed list
string ListHash(list Data) {
	return llSHA1String((string)Data);
}
ConfigError(string ObjectName, string Text) {
	llOwnerSay("Error in config file for MLO '" + ObjectName + "':\n" + Text);
}
list PrimLinkTarget(integer LinkNum) {
	// we need this next check because invalid link numbers can cause huge problems with OpenSim (eg high CPU that
	// persists even after object is removed from simulator; 0 objects allowed in simulator, etc). To fix, load from an
	// OAR that doesn't have the object in, and restart simulator. This was a big problem in 0.8; its status in 0.9 is
	// not presently known.
	if (LinkNum <= 0) {
		LogError("Invalid link number encountered!");
		LinkNum = llGetNumberOfPrims();	// Set to highest link num
	}
	return [ PRIM_LINK_TARGET, LinkNum ];
}
string GetPrimName(key PrimId) {
	return llList2String(llGetObjectDetails(PrimId, [ OBJECT_NAME ]), 0);
}
WaitModulesAdd(key Id) {
	if (llListFindList(WaitModules, [ Id ]) == -1) WaitModules += Id;
}
WaitModulesDelete(key Id) {
	integer Ptr = llListFindList(WaitModules, [ Id ]);
	if (Ptr > -1) WaitModules = llDeleteSubList(WaitModules, Ptr, Ptr);
}
// Process public data sent by ML
ParsePublicData(string Data) {
	list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
	RezBatchSize = (integer)llList2String(Parts, 13);
}
// Wrapper for osMessageObject that checks object exists and uses IOM format
SendIom(key Destination, string Command, string Data) {
	if (ObjectExists(Destination)) {
		osMessageObject(Destination, EncodeIom(Command, Data));
	}
}
// Sign user out with an optional message
LogoutUser(string Text) {
	if (Text != "") MessageUser(Text);
	llMessageLinked(LINK_ROOT, COM_LOGOUT, "", NULL_KEY);
}
MessageUser(string Text) {
	if (AvId != NULL_KEY) { // If they're signed in
		llDialog(AvId, "\n" + Text, [ "OK" ], -8172911);
	}
}
// Check if module object exists in the region
integer ModuleExists(key ModuleId) {
	integer M = llListFindList(ModulesList, [ ModuleId ]);
	if (M == -1) return FALSE; // shouldn't happen
	M -= MOD_MODULE_ID; // position at start of stride
	key ModuleKey = llList2Key(ModulesList, M + MOD_UUID);
	return (ObjectExists(ModuleKey));
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
// Send discovery message (for other objects to know we're here)
SendDiscovery() {
	llRegionSay(MODULES_CHANNEL, "A");
}
// Encode standard inter-object message
string EncodeIom(string Command, string Data) {
	return IOM_STRING + "|" + Command + "|" + Data;
}
LogError(string Text) {
	llMessageLinked(LINK_ROOT, -7563234, Text, AvId);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		OwnerId = llGetOwner();
		AvId = NULL_KEY;
		ClearData();
		if (llGetNumberOfPrims() == 1) state Hang; // we're in a box or something
		llListen(MODULES_CHANNEL, "", NULL_KEY, "");
		SendDiscovery();
		WaitTimer = 1.0;
		llSetTimerEvent(WaitTimer); // Wait for responses from modules
	}
	listen(integer Channel, string Name, key Uuid, string Text) {
		if (Channel == MODULES_CHANNEL) {
			if (llGetOwnerKey(Uuid) != OwnerId) return; // if it has a different owner, ignore
			string Command = llGetSubString(Text, 0, 0); // command is first char of message
			if (Command == "M") { // if it's an enabled module
				// Add it to the list of modules we're waiting for data from
				WaitModulesAdd(Uuid);
				// Request its data
				SendIom(Uuid, "S", "");
				// Log them out if they're logged in, otherwise HUD menus will be out of date
				LogoutUser("New module detected");
				// SendData();				
			}
			else if (Command == "E") { // if it's a module that's just been enabled
				// We need to log them out (if they're logged in) because HUD menu has changed
				LogoutUser("Module enabled");
			}
			else if (Command == "D") { // if it's a disabled module
				WaitModulesDelete(Uuid);
				integer ModulesPtr = llListFindList(ModulesList, [ Uuid ]);
				if (ModulesPtr > -1) { // we had this one recorded
					ModulesPtr -= MOD_UUID; // position at start of stride
					string ModuleId = llList2String(ModulesList, ModulesPtr + MOD_MODULE_ID);
					DeleteModuleData(ModuleId);				
					// Log them out if they're logged in, otherwise HUD menus will be out of date
					LogoutUser("Module disabled");
					SendData(); // send the updated data to the ML
				}
			}
		}
	}
	dataserver(key From, string Text) {
		list Parts = llParseStringKeepNulls(Text, [ "|" ], []);
		if (llList2String(Parts, 0) == IOM_STRING) { // it's an IOM message
			string Command = llList2String(Parts, 1);
			string Data = llList2String(Parts, 2);
			if (Command == "L") { // module sending us its data
				WaitModulesDelete(From);
				ProcessModuleData(From, Data);
				SendData();
			}
			else if (Command == "U") { // module sending us rezzed object UUIDs
				SendRezzedObjects(Data); // send them to the ML
			}
			else if (Command == "W") { // module sending us WO_INITIALISE message
				llMessageLinked(LINK_THIS, CT_WO_RECEIVED, "", (key)Data);
			}
		}
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		if (Sender == 1) {	// Message from script in root prim
			if (Number == UTIL_GO) { // Message from ML telling us to start processing
			}
			else if (Number == LM_EXTERNAL_LOGIN) {
				AvId = Id;
			}
			else if (Number == LM_EXTERNAL_LOGOUT) {
				AvId = NULL_KEY;
			}
			else if (Number == CT_REQUEST_DATA) {
				DataHash = ""; // force send regardless of whether data has changed
				SendData();
			}
			else if (Number == CT_REZ_OBJECTS) {
				RezObjects(Text);
			}
			else if (Number == LM_RESET) {
				llResetScript();
			}
			else if (Number == LM_PUBLIC_DATA) {
				ParsePublicData(Text);
			}
			else if (Number == CT_REZ_BATCH) {
				RezObjectsFromQueue();
			}
			else if (Number == UTIL_TIMER_RETURN) {
				if (Text == "rez") { // the timer tag we set during RezObjectsFromQueue()
					// Rez the next batch
					RezObjectsFromQueue();
				}
			}
		}
	}
	timer() {
		if (WaitModules == []) {
			// We have all the modules' data, so we're ready to start talking to other scripts
			llMessageLinked(LINK_THIS, UTIL_WAITING, "A", NULL_KEY); // tell servicer that we're ready
			llSetTimerEvent(0.0);
			return;
		}
		else {
			// If we're still waiting for data, then maybe the system is under heavy load, so increase timer value
			// (eg lots of child apps being rezzed in a short time)
			if (WaitTimer < 30.0) {
				WaitTimer += llFrand(5.0);
			}
			llSetTimerEvent(WaitTimer);
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_OWNER) OwnerId = llGetOwner();
	}
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llResetScript();
		if (Change & CHANGED_LINK) llResetScript();
	}
}
// ML cataloguer v1.8.4