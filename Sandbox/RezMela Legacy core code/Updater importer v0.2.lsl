// Updater importer v0.2

// v0.2 - unlinked platform should retain 1x1 texture when resized; other changes from beta

// NOTE that platform should NOT have this script in it when stored inside the HUD.
// However, the platform MUST have the remote script PIN set, so to make a new platform you
// can drop this script in and then delete it.

string CONFIG_NOTECARD = "RezMela updater config";
string PLATFORM_NAME = "RezMela importer platform";

integer OBJECT_PIN = 50200;

integer IMPORTER_CHANNEL = -81140900;

float CurrentSizeFactor;
integer PrimCount;

key OwnerId;
key UpdaterHudUuid;
key RootPrimUuid;

// Resize object
ReSize(float SizeFactor) {
	PrimCount = llGetNumberOfPrims();	// this will have changed since the script started
	float ChangeFactor = SizeFactor / CurrentSizeFactor;
	list WriteParams = [];
	integer FirstLinkNum = 1;
	if (PrimCount == 1) FirstLinkNum = 0;	// if unlinked, link number is 0
	integer P;
	for(P = FirstLinkNum; P <= PrimCount; P++) {
		list ReadParams = llGetLinkPrimitiveParams(P, [ PRIM_SIZE, PRIM_POS_LOCAL ]);
		vector Size = llList2Vector(ReadParams, 0);
		vector LocalPos = llList2Vector(ReadParams, 1);
		Size *= ChangeFactor;
		WriteParams += [ PRIM_LINK_TARGET, P, PRIM_SIZE, Size ];
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
// Returns estimate of size of object (X and Y axes only)
vector GetSize() {
	vector TotalSize = ZERO_VECTOR;
	PrimCount = llGetNumberOfPrims();	// this may have changed since the script started
	integer FirstLinkNum = 1;
	if (PrimCount == 1) FirstLinkNum = 0;	// if unlinked, link number is 0
	integer P;
	for(P = FirstLinkNum; P <= PrimCount; P++) {
		list ReadParams = llGetLinkPrimitiveParams(P, [ PRIM_SIZE, PRIM_POS_LOCAL, PRIM_ROT_LOCAL ]);
		vector Size = llList2Vector(ReadParams, 0);
		vector LocalPos = llList2Vector(ReadParams, 1);
		rotation LocalRot = llList2Rot(ReadParams, 2);
		// We could be ambitious here and calculate overall impact on size of each prim based on its
		// size and distance from the centre of the root prim (accounting for rotation) but for now
		// let's just find the biggest prim, accounting for rotation
		vector ThisSize = Size * LocalRot;
		ThisSize.x = llFabs(ThisSize.x);	// dimensions might be negative after rotation
		ThisSize.y = llFabs(ThisSize.y);
		if (ThisSize.x > TotalSize.x) TotalSize.x = ThisSize.x;
		if (ThisSize.y > TotalSize.y) TotalSize.y = ThisSize.y;
	}
	return TotalSize;
}
//	Is StrippedName the first part of FullName?
integer NameCompare(string FullName, string StrippedName) {
	return (llGetSubString(FullName, 0, llStringLength(StrippedName) - 1) == StrippedName);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		if (llGetInventoryType(CONFIG_NOTECARD) == INVENTORY_NOTECARD) state Hang;		// suspend if we're in the HUD
		llSetRemoteScriptAccessPin(OBJECT_PIN);
		OwnerId = llGetOwner();
		UpdaterHudUuid = NULL_KEY;
		PrimCount = llGetNumberOfPrims();
		CurrentSizeFactor = 1.0;
		if (NameCompare(llGetObjectName(), PLATFORM_NAME)) state Platform;
		state ActualObject;	// it's either a world object or icon, either with or without dummy root prim
	}
}
state ActualObject {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llRegionSay(IMPORTER_CHANNEL, "hello," + (string)GetSize());
	}
	dataserver(key From, string Data) {
		if (UpdaterHudUuid == NULL_KEY) UpdaterHudUuid = From;
		if (From == UpdaterHudUuid) {
			list Parts = llCSV2List(Data);
			string Command = llList2String(Parts, 0);
			if (Command == "link") {
				RootPrimUuid = (key)llList2String(Parts, 1);
				osForceCreateLink(RootPrimUuid, FALSE);
				osMessageObject(UpdaterHudUuid, "linked");
			}
			else if (Command == "resize") {	// parameter is scaling factor
				float ScalingFactor = (float)llList2String(Parts, 1);
				ReSize(1.0 / ScalingFactor);
				osMessageObject(UpdaterHudUuid, "resized");
			}
			else if (Command == "scrub") {
				llLinkParticleSystem(LINK_SET, []);		// kill all effects
				list ScrubParams = [
					PRIM_GLOW, ALL_SIDES, 0.0,
					PRIM_POINT_LIGHT, FALSE, ZERO_VECTOR, 0.0, 0.0, 0.0,
					PRIM_FULLBRIGHT, ALL_SIDES, FALSE,
					PRIM_TEXT, "", ZERO_VECTOR, 0.0
					];
				list AllParams = [];
				integer P;
				PrimCount = llGetNumberOfPrims();
				for (P  = 2; P <= PrimCount; P++) {
					AllParams += [ PRIM_LINK_TARGET, P ] + ScrubParams;
				}
				llSetLinkPrimitiveParamsFast(LINK_THIS, AllParams);
				osMessageObject(UpdaterHudUuid, "scrubbed");
			}
			else if (Command == "rename") {
				string NewName = llList2String(Parts, 1);
				list Params = [ PRIM_NAME, NewName ];
				llSetLinkPrimitiveParamsFast(LINK_ROOT, Params);
				osMessageObject(UpdaterHudUuid, "renamed");
			}
			else if (Command == "shrinkroot") {
				list Params = [
					PRIM_SIZE, <0.1, 0.1, 0.01>,
					PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 0.0,	// set alpha to 0%
					PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0	// remove platform texture
						];
				llSetLinkPrimitiveParamsFast(LINK_ROOT, Params);
				osMessageObject(UpdaterHudUuid, "shrunkroot");
			}
			else if (Command == "remove") {
				osMessageObject(UpdaterHudUuid, "removed");
				llRemoveInventory(llGetScriptName());
			}
			else {
				llDialog(llGetOwner(), "Unknown command received by importer (1): '" + Command + "'", [ "OK" ], -99999327);
			}
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llResetScript();
	}
}
// This state is for when the script is in a platform, which may also be a single flat icon prim
state Platform {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		// Find position of prim or ground beneath platform, and move to it
		vector Pos = llGetPos();
		list L = llCastRay(Pos, Pos - <0.0, 0.0, 10.0>,
			[ RC_REJECT_TYPES, RC_REJECT_AGENTS, RC_MAX_HITS, 1 ]);
		Pos = llList2Vector(L, 1);
		llSetPos(Pos);
		llRegionSay(IMPORTER_CHANNEL, "ready");
	}
	dataserver(key From, string Data) {
		if (UpdaterHudUuid == NULL_KEY) UpdaterHudUuid = From;
		if (From == UpdaterHudUuid) {
			list Parts = llCSV2List(Data);
			string Command = llList2String(Parts, 0);
			if (Command == "delete") {
				llDie();
			}
			else if (Command == "resize") {		// parameter is size
				vector NewSize = (vector)llList2String(Parts, 1);
				llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_SIZE, NewSize,
					PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 90.0 * DEG_TO_RAD	// remove platform texture
						]);
				osMessageObject(UpdaterHudUuid, "resized");
			}
			else if (Command == "rename") {
				string NewName = llList2String(Parts, 1);
				llSetLinkPrimitiveParamsFast(1, [ PRIM_NAME, NewName ]);
				osMessageObject(UpdaterHudUuid, "renamed");
			}
			else if (Command == "remove") {
				osMessageObject(UpdaterHudUuid, "removed");
				llRemoveInventory(llGetScriptName());
			}
			else {
				llDialog(llGetOwner(), "Unknown command received by importer (2): '" + Command + "'", [ "OK" ], -99999327);
			}
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llResetScript();
		if (Change & CHANGED_SCALE) {	// if it's changed size
			llScaleTexture(1.0, 1.0, ALL_SIDES);	// make sure repeats are still 1,1 (texture has cross in centre)
		}
		if (Change & CHANGED_LINK) {
			if (llGetNumberOfPrims() > 1) {	// the platform has become a root prim, and our job is over
				llRemoveInventory(llGetScriptName());
			}
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
// Updater importer v0.2