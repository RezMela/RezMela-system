// ML librarian v1.2.4

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

integer DEBUGGER = -391867620;
integer DebugMode = FALSE;

integer SCRIPT_PIN = -19318100;
string LIBRARY_NOTECARD = "!Objects";
string CONFIG_NOTECARD = "!Library config";
integer ON_REZ_PARAMETER = 10884726;
float TIMER_PERIOD = 0.5;

integer TEXT_FACE1 = 1;
integer TEXT_FACE2 = 3;

integer LIB_GET_DATA	= -879189100;
integer LIB_CATEGORIES	= -879189101;
integer LIB_METADATA	= -879189102;
integer LIB_REPORT	 	= -879189110;
integer LIB_DELETE_SCRIPT = -879189111;
integer LIB_REZ_OBJECTS 	= -879189120;
//integer LIB_ICON_INITIALISED = -879189121;
integer LIB_INITIALIZE 	= -879189122;
integer LIB_REZZED		= -879189123;
integer LIB_REZ_BATCH	= -879189124;

integer MODULE_STATUS = -119281700;

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
integer LM_LOCKED = -405545;
integer LM_PUBLIC_DATA = -405546;

string PRIM_DRAWING_DELIMITER = "|";			// delimiter character for prim-drawing commands

string ConfigData;

list ObjectsToRez = [];	// Queue of object names that need to be rezzed
list RezzedUuids = []; // Queue of object UUIDs that have been rezzed
integer ObjectsStillRezzing = 0; // Count of objects that have been rezzed but not yet fired object_rez

key AvId;
integer Enabled;
integer IsMap;
integer Locked;
string Description;

integer PrimCount;
integer MoveDisabled;	// should this module be prevented from moving to rez?
integer AtHome;
vector RezPosition;

// "Public" datra
vector ModulePosHidden;
integer RezBatchSize = 100; // Maximum size of a batch of rezzed objects

integer ReturnHomeTicks = 0;

key MouseDownAvId;
key MenuAvId;
integer MenuChannel;
integer MenuListener;

SetEnabledStatus(integer Status) {
	Enabled = Status;
	WriteConfig();
	ShowEnabledStatus();
	SendData();
}
GiveMenu(key ClickId) {
	MenuAvId = ClickId;
	MenuChannel = (integer)(-100000.0 - llFrand(900000.0));
	MenuListener = llListen(MenuChannel, "", MenuAvId, "");
	llDialog(MenuAvId, "\n\n" + Description + "\n\nEnter choice:", [ "Disable all", "Enable all", "Cancel" ], MenuChannel);
}
ShowDescription() {
	Description = llStringTrim(llGetSubString(llGetObjectName(), 5, -1), STRING_TRIM);	// Format is "&Lib: <description>"
	integer C = llSubStringIndex(Description, "~");	// look for version number (<description>~<version>)
	if (C > -1) {
		Description = llStringTrim(llGetSubString(Description, 0, C - 1), STRING_TRIM);	// remove version number part
	}
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
	osSetDynamicTextureDataBlendFace("", "vector", llDumpList2String(Commands, PRIM_DRAWING_DELIMITER), ExtraParams, FALSE, 2, 0, 255, TEXT_FACE1);
	key TextureId = llGetTexture(TEXT_FACE1);
	llSetTexture(TextureId, TEXT_FACE2);
}
ShowEnabledStatus() {
	vector Color = <1.0, 1.0, 1.0>;
	if (!Enabled) Color *= 0.8;
	llSetColor(Color, TEXT_FACE1);
	llSetColor(Color, TEXT_FACE2);
}
// Queue objects according to Text, which is of format "<ObjectName>|<Count".
// The queue is a simple list of object names (with duplicates for multiple of the same
// object) to avoid too much list manipulation, especially for short lists, the majority.
QueueObjectsToRez(string Text) {
	integer Separator = llSubStringIndex(Text, "|");
	string Name = llGetSubString(Text, 0, Separator - 1);
	if (llGetInventoryType(Name) != INVENTORY_OBJECT) return; // Not an object we have
	integer Count = (integer)llGetSubString(Text, Separator + 1, -1);
	while(Count--) {
		ObjectsToRez += Name;
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
	vector Pos = llGetPos() +  <0.0, 0.0, 10.0>;
	integer RezCount = llGetListLength(ObjectsToRez);
	if (RezCount > RezBatchSize) RezCount = RezBatchSize;
	integer C;
	for (C = 0; C < RezCount; C++) {
		string Name = llList2String(ObjectsToRez, C);
		llRezObject(Name, Pos, ZERO_VECTOR, ZERO_ROTATION, ON_REZ_PARAMETER);
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
ReportObject(string Name, key AvId) {
	if (llGetInventoryType(Name) == INVENTORY_OBJECT) {
		llRegionSayTo(AvId, 0, "<-- Contains '" + Name + "'");
	}
}
SendData() {
	// Send category data to cataloguer
	string NotecardData = "";
	if (Enabled) NotecardData = osGetNotecard(LIBRARY_NOTECARD);
	llMessageLinked(LINK_ROOT, LIB_CATEGORIES, NotecardData, NULL_KEY);
	// Send objects data to cataloguer
	list Objects = [];
	if (Enabled) {
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
					Objects += [ ObjectName, CCard ];
				}
			}
			// If/when we have object config cards, we can pick up their contents here
		}
	}
	if (DebugMode) Debug("Sending data for " + (string)(llGetListLength(Objects) / 2) + " objects");
	llMessageLinked(LINK_ROOT, LIB_METADATA, llDumpList2String(Objects, "|"), NULL_KEY);
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
// The usual stuff, but this one creates a notecard if non exists
ReadConfig() {
	// Set config defaults
	IsMap = FALSE;
	Enabled = TRUE;
	//
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		WriteConfig();
		return;	// it defaults to, er, defaults
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
					if (Name == "map")	IsMap = String2Bool(Value);
					else if (Name == "enabled")	Enabled= String2Bool(Value);
					else {
						LogError("Invalid entry in " + CONFIG_NOTECARD + ":\n" + Line);
					}
				}
			}
		}
	}
}
// Uses a delayed write to work round the OpenSim bug where a notecard delete immediately
// followed by a write leaves the original version there
WriteConfig() {
	llRemoveInventory(CONFIG_NOTECARD);
	ConfigData = "// Library module configuration\n" +
		"Map = " + Bool2String(IsMap) + "\n" +
		"Enabled = " + Bool2String(Enabled) + "\n";
	SetTimer();
}
// Process public data sent by ML
ParsePublicData(string Data) {
	list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
	ModulePosHidden = (vector)llList2String(Parts, 8);
	RezBatchSize = (integer)llList2String(Parts, 13);
}
DeleteOldVersions() {
	integer ScriptCount = llGetInventoryNumber(INVENTORY_SCRIPT);
	if (ScriptCount == 1) return;	// Only me
	string MyName = llGetScriptName();
	integer ScriptNum;
	for (ScriptNum = 0; ScriptNum < ScriptCount; ScriptNum++) {
		string OtherScript = llGetInventoryName(INVENTORY_SCRIPT, ScriptNum);
		if (OtherScript != MyName) llRemoveInventory(OtherScript);
	}
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
SetTimer() {
	if (RezzedUuids != [] || ObjectsToRez != [] || ObjectsStillRezzing > 0 || MouseDownAvId != NULL_KEY || ReturnHomeTicks > 0 || ConfigData != "") {
		llSetTimerEvent(TIMER_PERIOD);
	}
	else {
		llSetTimerEvent(0.0);
	}
}
Debug(string Text) {
	if (DebugMode) {
		llOwnerSay(Text);
		llRegionSay(DEBUGGER, Text);
	}
}
// Set debug mode according to root prim description
SetDebug() {
	string RootPrimDesc = llList2String(llGetLinkPrimitiveParams(LINK_ROOT, [ PRIM_DESC ]), 0);
	DebugMode = (RootPrimDesc == "debug");
}
LogError(string Text) {
	llMessageLinked(LINK_ROOT, -7563234, Text, AvId);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		if (llGetSubString(llGetObjectName(), 0, 5) != "&Lib: ") {
			LogError("Library script in non-module object");
			state Hang;
		}
		llSetRemoteScriptAccessPin(SCRIPT_PIN);
		SetDebug();
		//DeleteOldVersions();
		PrimCount = llGetNumberOfPrims();
		ShowDescription();
		if (PrimCount == 1) state Hang;
		MoveDisabled = FALSE;
		if (llGetInventoryType(LIBRARY_NOTECARD) != INVENTORY_NOTECARD) {
			LogError("Notecard missing: " + LIBRARY_NOTECARD);
		}
		MouseDownAvId = NULL_KEY;
		Locked = FALSE;
		ReadConfig();
		ShowEnabledStatus();
		Debug("Loaded");
		AvId = NULL_KEY;
		SetTimer();
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		if (Sender == 1) {	// Message from script in root prim
			if (Number == LIB_GET_DATA) {
				SendData();
			}
			else if (Number == LM_LOCKED) {
				Locked = (integer)Text;
			}
			else if (Number == LM_RESET) {
				llResetScript();
			}
			else if (Number == LIB_REZ_OBJECTS) {
				if (Enabled) QueueObjectsToRez(Text);
			}
			else if (Number == LM_PUBLIC_DATA) {
				ParsePublicData(Text);
			}
			else if (Number == LIB_INITIALIZE) {
				RezPosition = (vector)Text;
				if (IsMap) RezPosition = RegionPos2LocalPos(RezPosition);	// For maps, rez position is configured as region coords.
				AtHome = TRUE;
			}
			else if (Number == LIB_REPORT) {
				ReportObject(Text, Id);
			}
			else if (Number == LIB_DELETE_SCRIPT) {
				llRemoveInventory(llGetScriptName());
			}
		}
		else {	// Messages from non-root prims
			if (Number == HUD_API_LOGIN) {
				AvId = Id;
				ReadConfig();
			}
			else if (Number == HUD_API_LOGOUT) {
				AvId = NULL_KEY;
			}
			else if (Number == LIB_REZ_BATCH) {
				RezObjectsFromQueue();
			}
			else if (Number == MODULE_STATUS) {
				if (Text == "e") SetEnabledStatus(TRUE);
				else if (Text == "d") SetEnabledStatus(FALSE);
			}
			else if (Number == LIB_DELETE_SCRIPT) {
				llRemoveInventory(llGetScriptName());
			}
		}
	}
	dataserver(key From, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		integer Command = (integer)llList2String(Parts, 0);
		string ParamString = llDumpList2String(llList2List(Parts, 1, -1), "|");
		if (Command == WO_INITIALISE || (Command >= IC_RANGE_START && Command <= IC_RANGE_END)) {	// these commands are relayed to the ML
			llMessageLinked(LINK_ROOT, Command, ParamString, From);
		}
	}
	object_rez(key Id) {
		RezzedUuids += Id;
		ObjectsStillRezzing--;
		SetTimer();
	}
	touch_start(integer Count) {
		// They can short-click the text face to toggle enabled status, which also sends an
		// update to the ML, or long-click for a menu
		integer TouchFace = llDetectedTouchFace(0);
		if (!Locked && AvId == NULL_KEY && (TouchFace == TEXT_FACE1 || TouchFace == TEXT_FACE2)) {	// They can only do this if nobody's logged in, and the app isn't locked
			if (MouseDownAvId == NULL_KEY) {
				MouseDownAvId = llDetectedKey(0);
				SetTimer();
			}
		}
	}
	touch_end(integer Count) {
		if (llDetectedKey(0) == MouseDownAvId) {
			SetEnabledStatus(!Enabled);
			MouseDownAvId = NULL_KEY;
		}
	}
	timer() {
		if (RezzedUuids != [] && ObjectsToRez == []) {
			integer UuidsCount = llGetListLength(RezzedUuids);
			if (UuidsCount > RezBatchSize) UuidsCount = RezBatchSize;
			list SendUuids = llList2List(RezzedUuids, 0, UuidsCount - 1);
			RezzedUuids = llDeleteSubList(RezzedUuids, 0, UuidsCount - 1);
			string UuidsList = llDumpList2String(SendUuids, "|");
			llMessageLinked(LINK_ROOT, LIB_REZZED, UuidsList, NULL_KEY); // tell the ML about the object(s) we've rezzed
		}
		if (ObjectsToRez != [] && ObjectsStillRezzing == 0) {
			// There are still objects in the queue that have not yet been rezzed, and
			// all objects that have been rezzed have returned their object_rez events.
			llMessageLinked(LINK_THIS, LIB_REZ_BATCH, "", NULL_KEY); // rez the next batch
		}
		if (MouseDownAvId != NULL_KEY) {
			GiveMenu(MouseDownAvId);
			MouseDownAvId = NULL_KEY;
		}
		if (ConfigData != "") {
			osMakeNotecard(CONFIG_NOTECARD, ConfigData);
			ConfigData = "";
		}
		if (!AtHome) {
			ReturnHomeTicks--;
			if (ReturnHomeTicks == 0) {
				Move(RezPosition, ModulePosHidden);
				AtHome = TRUE;
			}
		}
		SetTimer();
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == MenuAvId) {
			if (Message == "Enable all") {
				llMessageLinked(LINK_SET, MODULE_STATUS, "e", Id);
			}
			else if (Message == "Disable all") {
				llMessageLinked(LINK_SET, MODULE_STATUS, "d", Id);
			}
			llListenRemove(MenuListener);
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) ShowDescription();
	}
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Debug("Hung!");
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) llResetScript();
	}
}
// ML librarian v1.2.4