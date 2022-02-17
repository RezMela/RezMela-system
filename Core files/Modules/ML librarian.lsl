// ML librarian v1.3.7

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

// v1.3.7 - tolerate modules of >1 prim
// v1.3.6 - add suspend feature
// v1.3.5 - don't rename objects rezzed by other scripts
// v1.3.4 - tolerate objects being rezzed by other scripts (eg the "rez and delete" script)
// v1.3.3 - delay update processing when contents change
// v1.3.2 - fix cross-talk bug
// v1.3.1 - bug fixes, etc
// v1.3.0 - unlinked modules
// v1.2.5 - allow random element in new objects' rez position
// v1.2.4 - pick up batch size from "public data"
// v1.2.3 - improved comms for rezzing objects
// v1.2.2 - improve debugging, add script PIN, add LIB_DELETE_SCRIPT
// v1.2.1 - fix LogError; add debug feature
// v1.2.0 - OpenSim 0.9.1 change (alpha in osSetDynamicTextureDataBlendFace)
// v1.1 - tolerate other scripts and objects; message on object creation
// v0.19 - changed module positioning method
// v0.18 - changes faces for descriptions
// v0.17 - redraw description on region restart (for Kitely)
// v0.16 - reset when LM_RESET (reset from HUD) received
// v0.15 - bug fix (not showing description when unlinked)
// v0.14 - bug fix, improved previous versions deletion
// v0.13 - improve movement of module, allow for us in Apps
// v0.12 - fix glitch with positioning on reset scripts; display description on back of prim
// v0.11 - add processing for moving to rez position and back
// v0.10 - add "report" feature, and disable rezzing when the module is disabled; add "locked" processing; add long-click menu
// v0.9 - add behaviour for enabling/disabling the module
// v0.8 - use specific parameter to rezzed objects
// v0.7 - work with Map objects; suppress version # in description; use error logger
// v0.6 - don't give error when asked to rez an object we don't have (rezzing message is now broadcast to all modules)
// v0.5 - introduction of cataloguer script
// v0.4 - don't store texture UUID - it doesn't work properly due to OpenSim caching
// v0.3 - add metadata notecard processing
// v0.2 - add text on side

integer FACE_DESCRIPTION = 4;
integer FACE_IMAGE = 3;
integer FACE_BUTTON = 2;

integer MODULES_CHANNEL = -91823472; // listener channel for modules

// IOM (Inter-Object Message) constants
string IOM_STRING = "£ML-&"; // magic number for inter-object messages via osMessageObject

integer SCRIPT_PIN = -19318100;
string LIBRARY_NOTECARD = "!Objects";
string CONFIG_NOTECARD = "!Library config";
integer ON_REZ_PARAMETER = 10884726;
float TIMER_PERIOD = 0.5;

integer LIB_GET_DATA	= -879189100;
integer LIB_CATEGORIES	= -879189101;
integer LIB_METADATA	= -879189102;
integer LIB_REPORT	 	= -879189110;
integer LIB_DELETE_SCRIPT = -879189111;
integer LIB_REZ_OBJECTS 	= -879189120;
integer LIB_INITIALIZE 	= -879189122;
integer LIB_SUSPEND	= -879189123;
integer LIB_REZ_BATCH	= -879189124;

// HUD AP
integer HUD_API_LOGIN = -47206000;
integer HUD_API_LOGOUT = -47206001;

// Icon commands
integer IC_RANGE_START = 1000;	// messages in this range will be relayed to the ML as linked messages
integer IC_RANGE_END = 1050;
//integer IC_MOVE = 1000;
//integer IC_ROTATE = 1001;
//integer IC_MOVE_ROTATE = 1002;
//integer IC_RESIZE = 1003;
//integer IC_SELECT = 1004;
//integer IC_DESELECT = 1005;
//integer IC_INITIALISE = 1006;
//integer IC_DELETE = 1007;
//integer IC_SHORT_CLICK = 1008;
//integer IC_LONG_CLICK = 1009;
//integer IC_COMMAND = 1020;
//integer IC_UPDATE = 1021;
//integer IC_CHANGE = 1022;
//integer IC_CHANGED_SIZE = 1023;
//integer IC_CHANGED_COLOR = 1024;

// World object commands
integer WO_INITIALISE = 3004;	// we only need to relay this one message type for WOs

// From ML
integer LM_RESET = -405535;
integer LM_PUBLIC_DATA = -405546;

string PRIM_DRAWING_DELIMITER = "|";			// delimiter character for prim-drawing commands

list ObjectsToRez = [];	// Queue of object names that need to be rezzed
list RezRequests = []; // [ <object name>, <App UUID> ] so we know which app requested what
list RezzedObjects = []; // [ <App UUID>, <object UUID> ] so we can tell the app(s) the rezzed UUIDs
list WOCallbackNames = []; // [ <<App UUID>, <object name> ] - apps that need to hear back when we get WO_INITIALISE
list WOCallbackUuids = []; // [ <<App UUID>, <object UUID> ] - apps that need to hear back when we get WO_INITIALISE
list WOObjects = []; // [ <object UUUD> ] - objects that have sent us WO_INITIALISE but the app hasn't requested it yet
integer ObjectsStillRezzing = 0; // Count of objects that have been 580 but not yet fired object_rez

integer ContentsChanged = FALSE; // Have the prim contents changed?

key ObjectKey;
key OwnerId;
integer Enabled;
integer IsMap;
string Description;
string ImageId;
string ModuleId = "";
string ModulePriority = "0";
integer Resolver = 0; // a large random number used in duplicates resolution

integer MoveDisabled;	// should this module be prevented from moving to rez?
integer AtHome;
vector RezPosition;
integer IsRezPositionRandom;
float RezPositionRandom;

integer RegionRestartTicks = 0;

// "Public" datra
vector ModulePosHidden;
integer RezBatchSize = 100; // Maximum size of a batch of rezzed objects

integer ReturnHomeTicks = 0;

ShowDetails() {
	integer CanvasWidth = 512;
	integer CanvasHeight = 512;
	string FontName = "Noto Sans";
	integer FontSize = 24;
	string TextColor = "FF111111";
	vector TextSize = osGetDrawStringSize("vector", Description, FontName, FontSize);
	integer TextHeight = (integer)TextSize.y;
	integer TextWidth = (integer)TextSize.x;
	integer PosX = (CanvasWidth / 2) - (TextWidth / 2);
	integer PosY = (CanvasHeight / 2) - (TextHeight / 2);
	list Commands = [
		"FontName " + FontName,
		"FontSize " + (string)FontSize,
		"PenColor " + TextColor,
		"MoveTo " + (string)PosX + "," + (string)PosY,
		"Text " + Description
			];
	string ExtraParams = "width:" + (string)CanvasWidth + ",height:" + (string)CanvasHeight + ",altdatadelim:" + PRIM_DRAWING_DELIMITER;
	osSetDynamicTextureDataBlendFace("", "vector", llDumpList2String(Commands, PRIM_DRAWING_DELIMITER), ExtraParams, FALSE, 2, 0, 255, FACE_DESCRIPTION);
	llSetTexture(ImageId, FACE_IMAGE);
}
// Queue objects specified by Text, which is a list of "|"-delimited object names
QueueObjectsToRez(key SendingUuid, string Text) {
	list ObjectsList = llParseStringKeepNulls(Text, [ "^" ], []);
	ObjectsToRez += ObjectsList; // add to queue of objects to be rezzed
	// Now record that this request asked for these objects
	integer Len = llGetListLength(ObjectsList);
	integer I;
	for (I = 0; I < Len; I++) {
		string ObjectName = llList2String(ObjectsList, I);
		RezRequests += [ ObjectName, SendingUuid ];
	}
	// This LM only goes to the same script, to trigger a separate event for each batch
	// of objects being rezzed
	llMessageLinked(LINK_THIS, LIB_REZ_BATCH, "", NULL_KEY);
}
RezObjectsFromQueue() {
	if (!MoveDisabled && AtHome) {	// If we're a map, and we're in our normal position, move to the rez position
		Move(ModulePosHidden, RezPosition);
		AtHome = FALSE;
		ReturnHomeTicks = 4;
		SetTimer();
	}
	vector InitialRezPos = llGetPos() + <0.0, 0.0, 10.0>;
	integer RezCount = llGetListLength(ObjectsToRez);
	if (RezCount > RezBatchSize) RezCount = RezBatchSize;
	integer C;
	for (C = 0; C < RezCount; C++) {
		string Name = llList2String(ObjectsToRez, C);
		integer Dot = llSubStringIndex(Name, ".");
		string Basename = llGetSubString(Name, Dot + 1, -1); // strip off preceding module id
		llRezObject(Basename, InitialRezPos, ZERO_VECTOR, ZERO_ROTATION, ON_REZ_PARAMETER);
	}
	ObjectsStillRezzing += RezCount;
	ObjectsToRez = llDeleteSubList(ObjectsToRez, 0, RezCount - 1);
	SetTimer();
}
Move(vector OldPos, vector NewPos) {
	if (MoveDisabled) return;
	list Params = [];
	integer Jumps = (integer)(llVecDist(OldPos, NewPos) / 10.0) + 1;
	while(Jumps--) {
		Params += [ PRIM_POS_LOCAL, NewPos ];
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
}
MoveObject(key Uuid, vector Pos) {
	vector OldPos = llList2Vector(osGetPrimitiveParams(Uuid, [ PRIM_POSITION ]), 0);
	list Params = [];
	integer Jumps = (integer)(llVecDist(OldPos, Pos) / 10.0) + 1;
	while(Jumps--) {
		Params += [ PRIM_POS_LOCAL, Pos ];
	}
	osSetPrimitiveParams(Uuid, Params);
}
ReportObject(string Name, key AvId) {
	if (llGetInventoryType(Name) == INVENTORY_OBJECT) {
		llRegionSayTo(AvId, 0, "<-- Contains '" + Name + "'");
	}
}
// Send data to cataloguer in App
SendData(key AppId) {
	// First, we need to prepend the module ID to all object names in the "!Objects" data
	list RawCategories = llParseStringKeepNulls(osGetNotecard(LIBRARY_NOTECARD), [ "\n" ], []);
	list CookedCategories = [];
	integer Len = llGetListLength(RawCategories);
	integer P;
	for (P = 0; P < Len; P++) {
		string Line = llStringTrim(llList2String(RawCategories, P), STRING_TRIM);
		if (Line != "") { // strip blank lines
			if (llGetSubString(Line, 0, 0) != "[") { // if it's not a category, it's an object
				Line = ModuleId + "." + Line; // add the module ID into the object name
			}
			CookedCategories += Line;
		}
	}
	string SerializedCategories = llStringToBase64(llDumpList2String(CookedCategories, "\n"));
	// Now we get all the C card data
	list Objects = [];
	integer Count = llGetInventoryNumber(INVENTORY_OBJECT);
	integer O;
	for (O = 0; O <Count; O++) {
		string Name = llGetInventoryName(INVENTORY_OBJECT, O);
		integer CreateEntry = TRUE;
		string ObjectName;
		if (IsMap) {
			string Ext = llGetSubString(Name, -1, -1);	// extract last char
			if (Ext == "W")
				ObjectName = llGetSubString(Name, 0, -2); // get base name
			else
				CreateEntry = FALSE;	// ignore icon objects
		}
		else {	// not map
			ObjectName = Name;
		}
		if (CreateEntry) {
			string CCard = ReadCCard(ObjectName);
			if (CCard != "") {	// if the C card exists
				Objects += [ ModuleId + "." + ObjectName, CCard ];
			}
		}
		// If/when we have object config cards, we can pick up their contents here
	}
	string SerializedObjects = llStringToBase64(llDumpList2String(Objects, "|"));
	SetPriority();
	string Data = ModuleId + "^" + ModulePriority + "^" + Description + "^" + SerializedCategories + "^" + SerializedObjects;
	SendIom(AppId, "L", Data);
}
// We have a list of rezzed object UUIDs, and the UUIDs of the Apps that requested them.
// Here, we're sending those object UUIDs to the Apps (and clearing that data from the queue)
SendUuidsToApps() {
	// Input:
	// RezzedObjects [ <App UUID>, <object UUID> ]
	//
	// John rants:
	// Because this is LSL, there is no elegant way to do this. We'll use an intermediate
	// list to store a list of Apps' UUIDs, then navigate through that and find data elements for
	// each App in turn. Horribly inefficient, but at least it's pretty unlikely there'll be more
	// than one App requesting at the same time ... except for nested Apps, which are currently on
	// the back-burner. At the moment, I just want to get this working and solid - if you can improve
	// on this code, I salute you and thank you.
	// Oh, and I'm not going to batch here, in the hope that batching upstream will throttle this
	// sufficiently. It should do.
	list AppsToSend = [];
	integer ObjectsLen = llGetListLength(RezzedObjects);
	// OK, let's get that intermediate list of Apps populated.
	integer I;
	for (I = 0; I < ObjectsLen; I += 2) {
		key AppUuid = llList2Key(RezzedObjects, I);
		if (llListFindList(AppsToSend, [ AppUuid ]) == -1) AppsToSend += AppUuid;
	}
	// Now AppsToSend contains a list of Apps that need to hear from us. Let's go through them
	// and find all their objects.
	integer AppsLen = llGetListLength(AppsToSend);
	for (I = 0; I < AppsLen; I++) {
		key AppUuid = llList2Key(AppsToSend, I);
		list SendObjects = [];
		integer J; // just like the days of 8-bit BASIC, eh?
		for (J = 0; J < ObjectsLen; J += 2) {
			key ThisAppUuid = llList2Key(RezzedObjects, J);
			if (ThisAppUuid == AppUuid) {
				key ObjectUuid = llList2Key(RezzedObjects, J + 1);
				SendObjects += ObjectUuid;
			}
		}
		// Now SendObjects contains a list of all objects we've rezzed that were requested
		// by this App. Time to send it back to the App.
		SendIom(AppUuid, "U", llDumpList2String(SendObjects, "^"));
	}
	// Now delete the queue.
	RezzedObjects = [];
}

// Sets priority based on our position and whether we're linked or not
SetPriority() {
	integer Priority = 0;
	vector Pos = llGetPos();
	Priority += ((integer)Pos.y * 1000);
	ModulePriority = (string)Priority;
}
// Returns empty string if no C card
string ReadCCard(string Name) {
	string NotecardName = Name + "C";
	string Ret = "";
	if (llGetInventoryType(NotecardName) == INVENTORY_NOTECARD) {
		Ret = llStringToBase64(osGetNotecard(NotecardName));
	}
	return Ret;
}
// The usual stuff - read config data from a notecard
integer ReadConfig() {
	// Set config defaults
	IsMap = FALSE;
	Enabled = TRUE;
	ModuleId = "";
	Description = "";
	ImageId = TEXTURE_BLANK;
	RezPosition = <0.0, 0.0, 10.0>;
	RezPositionRandom = 1.0;
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
					if (Name == "map")	IsMap = String2Bool(Value);
					else if (Name == "moduleid")	ModuleId = Value;
					else if (Name == "description")	Description = Value;
					else if (Name == "image")	ImageId = (key)Value;
					else if (Name == "rezposition") RezPosition = (vector)Value;
					else if (Name == "rezpositionrandom")	RezPositionRandom = (float)Value;
					else {
						llOwnerSay("Invalid entry in " + CONFIG_NOTECARD + ":\n" + Line);
					}
				}
			}
		}
	}
	if (RezPositionRandom > 2.5) RezPositionRandom = 2.5; // Throttle at 2.5 so it does't go out of 10m range when added to rez position
	IsRezPositionRandom = (RezPositionRandom != 0.0); // Store as int (bool) for efficiency
	if (ModuleId == "") {
		llOwnerSay("ModuleId entry missing from config card");
		return FALSE;
	}
	if (
		llSubStringIndex(ModuleId, "|") > -1 ||
		llSubStringIndex(ModuleId, "^") > -1 ||
		llSubStringIndex(ModuleId, ".") > -1
			) { // just in case!
				// this could be made more intelligent
				llOwnerSay("Invalid symbol in Module ID (use letters, numbers, dashes, underscore");
				return FALSE;
			}
	return TRUE;
}
integer CheckObjectsCard() {
	if (llGetInventoryType(LIBRARY_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Notecard missing: " + LIBRARY_NOTECARD);
		return FALSE;
	}
	return TRUE;
}
// Process public data sent by ML
// not currently used (since unlinked module), so default values used instead
ParsePublicData(string Data) {
	list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
	ModulePosHidden = (vector)llList2String(Parts, 8);
	RezBatchSize = (integer)llList2String(Parts, 13);
}
// Set our enabled status
SetEnabled(integer IsEnabled, integer SendEnabledMessage) {
	integer PrevEnabled = Enabled;
	Enabled = IsEnabled;
	if (Enabled) {
		llOffsetTexture(0.0, 0.375, FACE_BUTTON);
		if (!PrevEnabled && SendEnabledMessage) {	// if the module has been enabled from disabled state
			llRegionSay(MODULES_CHANNEL, "E" + ModuleId);
		}
		SendDiscovery();
	}
	else {
		llOffsetTexture(0.0, 0.125, FACE_BUTTON);
		llRegionSay(MODULES_CHANNEL, "D"); // broadcast our disabled status
	}
}
// Wrapper for osMessageObject that checks object exists and uses IOM format
SendIom(key Destination, string Command, string Data) {
	if (ObjectExists(Destination)) {
		osMessageObject(Destination, EncodeIom(Command, Data));
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
// Send discovery message (for other objects to know we're here)
SendDiscovery() {
	llRegionSay(MODULES_CHANNEL, "M" + ModuleId);
}
// Encode standard inter-object message
string EncodeIom(string Command, string Data) {
	return IOM_STRING + "|" + Command + "|" + Data;
}
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
string Bool2String(integer Boolean) {
	if (Boolean) return "True"; else return "False";
}
vector RegionPos2LocalPos(vector RegionPos) {
	return (RegionPos - llGetRootPosition()) / llGetRootRotation();
}
// Perform housekeeping duties on system restart
Housekeep() {
	// These should be empty, so just in case they're not, let's do that.
	WOCallbackNames = [];
	WOCallbackUuids = [];
	WOObjects = [];
}
SetTimer() {
	if (RezzedObjects != [] || ObjectsToRez != [] || ObjectsStillRezzing > 0 || ReturnHomeTicks > 0 || RegionRestartTicks > 0 || ContentsChanged) {
		llSetTimerEvent(TIMER_PERIOD);
	}
	else {
		llSetTimerEvent(0.0);
	}
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetRemoteScriptAccessPin(SCRIPT_PIN);
		OwnerId = llGetOwner();
		ObjectKey = llGetKey();
		Resolver = llFloor(llFrand(2000000000.0));
		MoveDisabled = FALSE;
		if (!ReadConfig()) state Hang;
		if (!CheckObjectsCard()) state Hang;
		ContentsChanged = FALSE;
		ObjectsToRez = [];
		RezRequests = [];
		RezzedObjects = [];
		SetPriority();
		ShowDetails();
		SetTimer();
		llListen(MODULES_CHANNEL, "", NULL_KEY, "");
		SendDiscovery();
		SetEnabled(TRUE, FALSE);
	}
	listen(integer Channel, string Name, key Id, string Text) {
		if (Channel == MODULES_CHANNEL && Enabled) {
			if (llGetOwnerKey(Id) != OwnerId) return; // if it has a different owner, ignore
			string Command = llGetSubString(Text, 0, 0); // command is first char of message
			if (Command == "M" && Id != ObjectKey) { // if it's a module, and not us
				string TheirModuleId = llGetSubString(Text, 1, -1); // get the other module's ID
				if (TheirModuleId == ModuleId) { // we have a duplicate
					SendIom(Id, "R", (string)Resolver);
				}
			}
			else if (Command == "A") { // message from an app
				SendData(Id); // reply with our data
			}
		}
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		if (Number == LIB_REZ_BATCH) {
			RezObjectsFromQueue();
		}
		// Almost everything that was in here prior to unlinked modules is now commented out below.
		// If it's not been referenced or reinstated (in a different form) in a while, just delete
		// the comments and we'll all pretend it never existed.  -- JFH, Feb 2022
		
		//		else if (Number == LIB_DELETE_SCRIPT) {
		//			llRemoveInventory(llGetScriptName());
		//		}
		//		if (Number == LIB_SUSPEND) { // message from deployment script telling is to be inert
		//			state Suspend;	// Not sure this even happens now
		//		}
		// We shouldn't be receiving most link messages now, since the module is unlinked. I'm not
		// deleting this code just in case, because time doesn't allow it at the moment. But next time
		// this is revisited, this can be cleared up. -- John 2021-11-11
		//		if (Sender == 1) {	// Message from script in root prim
		//			if (Number == LM_RESET) {
		//				llResetScript();
		//			}
		//			else if (Number == LM_PUBLIC_DATA) {
		//				ParsePublicData(Text);
		//			}
		//			else if (Number == LIB_INITIALIZE) {
		//				RezPosition = (vector)Text;
		//				if (IsMap) RezPosition = RegionPos2LocalPos(RezPosition);	// For maps, rez position is configured as region coords.
		//				AtHome = TRUE;
		//			}
		//			else if (Number == LIB_REPORT) {
		//				ReportObject(Text, Id);
		//			}
		//			else if (Number == LIB_DELETE_SCRIPT) {
		//				llRemoveInventory(llGetScriptName());
		//			}
		//		}
		//		else {	// Messages from non-root prims
		//			if (Number == HUD_API_LOGIN) {
		//				AvId = Id;
		//			}
		//			else if (Number == HUD_API_LOGOUT) {
		//				AvId = NULL_KEY;
		//			}
		//			else
	}
	dataserver(key From, string Text) {
		list Parts = llParseStringKeepNulls(Text, [ "|" ], []);
		if (llList2String(Parts, 0) == IOM_STRING) { // it's an IOM message
			if (!Enabled) return;
			string Command = llList2String(Parts, 1);
			string Data = llList2String(Parts, 2);
			if (Command == "S") { // app requesting our data
				SendData(From); // reply with our data
			}
			else if (Command == "R") { // resolve duplication (sent by another instance of the same module
				integer TheirResolver = (integer)Data;
				if (TheirResolver >= Resolver) { // if they have a higher resolver (or the same!)
					SetEnabled(FALSE, FALSE);
				}
				else {
					SendIom(From, "R", (string)Resolver); // tell them to disable
				}
			}
			else if (Command == "Z") { // rez objects
				if (Enabled) QueueObjectsToRez(From, Data);
			}
			else if (Command == "W") { // cataloguer wants to hear back when we get WO_INITIALISE
				list Names = llParseStringKeepNulls(Data, [ "^" ], []);
				integer NamesCount = llGetListLength(Names);
				integer I;
				for (I = 0; I < NamesCount; I++) {
					string Name = llList2String(Names, I);
					WOCallbackNames += [ From, Name ];
				}
			}
		}
		else {
			// Old format messages from detached objects. We don't use IOMs for this because that would mean replacing the
			// WorldObject and Icon scripts in a lot of legacy stuff.
			integer Command = (integer)llList2String(Parts, 0);
			string ParamString = llDumpList2String(llList2List(Parts, 1, -1), "|");
			if (Command == WO_INITIALISE) {
				// We need to inform the app that requested this object that its WO_INITIALISE message has arrived.
				integer P = llListFindList(WOCallbackUuids, [ From ]);
				if (P == -1) {
					// On rare occasions, the object has time to rez, start its WorldObject script and send us
					// WO_INITIALISE before our object_rez() event fires. So when that happens, we store this UUID
					// until that event occurs.
					WOObjects += From;
					return;
				}
				P -= 1; // position at start of stride
				key AppUuid = llList2Key(WOCallbackUuids, P);
				SendIom(AppUuid, "W", From);
				WOCallbackUuids = llDeleteSubList(WOCallbackUuids, P, P + 1);
			}
			else if (Command >= IC_RANGE_START && Command <= IC_RANGE_END) {	// these commands are relayed to the ML
				// Needs to be coded (when we reincarnate Maps)
				// SendIom(AppId, "I", Command + "^" + From + "^" + ParamString);
			}
		}
	}
	object_rez(key Id) {
		// RezRequests: [ <object name>, <App UUID> ] so we know which app requested what
		// RezzedObjects: [ <App UUID>, <object UUID> ] so we can tell the app(s) the rezzed UUIDs
		string ObjectName = llKey2Name(Id);
		ObjectName = ModuleId + "." + ObjectName;
		// Find pointer to request entry in ReqRequests for this object name
		integer RequestPtr = llListFindList(RezRequests, [ ObjectName ]);
		if (RequestPtr == -1) return; // If it's not there, then it's been rezzed by some other script, so ignore
		// Rename object
		osSetPrimitiveParams(Id, [ PRIM_NAME, ObjectName ]);
		// Before we do anything else, move the object to RezPos (+/- random)
		vector ActualPos = RezPosition;
		if (IsRezPositionRandom) {
			// If we're using random rez position, offset each axis by random amount in range specified
			ActualPos.x += llFrand(RezPositionRandom);
			ActualPos.y += llFrand(RezPositionRandom);
			ActualPos.z += llFrand(RezPositionRandom);
		}
		MoveObject(Id, ActualPos);
		// Get UUID of App that requested this object. Note that this might not be the actual instance
		// of this object that they requested, but (a) we have no way of tying llRezObject() calls to the
		// associated object_rez() event, and (b) it doesn't matter as long as it's the right object name.
		key RequestingAppUuid = llList2Key(RezRequests, RequestPtr + 1);
		// Delete the RezRequests entry
		RezRequests = llDeleteSubList(RezRequests, RequestPtr, RequestPtr + 1);
		// Add the data to the queue of rezzed UUIDs to be sent back to the app
		RezzedObjects += [ RequestingAppUuid, Id ];
		// Now, detached objects can't be processed until their WO script has sent us WO_INITIALISE. The
		// cataloguer provided us with a list of detached object names when it requested they be rezzed.
		// Now is a good time to convert the name to the actual UUID in a different table, so when we get that
		// message we know which app to inform.
		integer C = llListFindList(WOCallbackNames, [ ObjectName ]); // WOCallbackNames is [ <<App UUID>, <object name> ]
		if (C > -1) { // if this object is on that list
			C -= 1; // position at start of stride
			key AppUuid = llList2Key(WOCallbackNames, C);
			WOCallbackNames = llDeleteSubList(WOCallbackNames, C, C + 1); // delete from names list
			WOCallbackUuids += [ AppUuid, Id ]; // and add to UUIDs list
			// Now we need to check if we already received the WO_INITIALISE message from this object (an
			// unexpected and rare occurrence that occasionally happens).
			integer U = llListFindList(WOObjects, [ Id ]);
			if (U > -1) {
				SendIom(AppUuid, "W", Id);
				// I know we just added this, but I'm keeping this logic separate for now -- J
				WOCallbackUuids = llDeleteSubList(WOCallbackUuids, C, C + 1);
			}
		}
		ObjectsStillRezzing--;
		SetTimer();
	}
	touch_start(integer Count) {
		if (llDetectedTouchFace(0) == FACE_BUTTON && llDetectedKey(0) == OwnerId) {
			SetEnabled(!Enabled, TRUE);
		}
	}
	timer() {
		if (RezzedObjects != [] && ObjectsToRez == []) {
			SendUuidsToApps();
		}
		if (ObjectsToRez != [] && ObjectsStillRezzing == 0) {
			// There are still objects in the queue that have not yet been rezzed, and
			// all objects that have been rezzed have returned their object_rez events.
			llMessageLinked(LINK_THIS, LIB_REZ_BATCH, "", NULL_KEY); // rez the next batch
		}
		if (!AtHome) {
			ReturnHomeTicks--;
			if (ReturnHomeTicks == 0) {
				Move(RezPosition, ModulePosHidden);
				AtHome = TRUE;
			}
		}
		if (RegionRestartTicks > 0) {
			if (--RegionRestartTicks == 0) {
				ShowDetails();
			}
		}
		if (ContentsChanged) {
			if (!ReadConfig()) state Hang;
			if (!CheckObjectsCard()) state Hang;
			ShowDetails();
			ContentsChanged = FALSE;
		}
		SetTimer();
	}

	changed(integer Change) {
		if (Change & CHANGED_REGION_START) {
			Housekeep();
			RegionRestartTicks = 5 + (integer)llFrand(20.0); // delay ShowDetails call by 5-24 seconds
			SetTimer();
		}
		if (Change & CHANGED_INVENTORY) {
			// So we don't trigger processing (including dynamic texture creation) for each item in a multi-item
			// drop or deletion, we defer the processing of changed data using a timer.
			ContentsChanged = TRUE;
			SetTimer();
		}
		if (Change & CHANGED_LINK) SetPriority();
	}
}
state Suspend {
	on_rez(integer Param) { llResetScript(); }
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llResetScript();
	}
}
// ML librarian v1.3.7