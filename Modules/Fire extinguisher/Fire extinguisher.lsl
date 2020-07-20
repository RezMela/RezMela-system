// Fire extinguisher v0.3

// v0.3 - move into root prim and add avatar animation, remove threat-level commands

// NOTE!!!!
//
// 1. This script needs to be run by avatars without high threat level permissions
// 2. The "Water" object must be physical and temporary

string CONFIG_NOTECARD = "Extinguisher config";

string WaterObjectName;
float WaterObjectFrequency;
float WaterObjectVelocityMin;
float WaterObjectVelocityMax;
vector AttachDirection;
vector AttachPos;

integer PrimNozzle;	// link number of nozzle
key AvId;
string Animation;
integer IsAnimating;

integer IsOn;
key SoundKey;
key TextureKey;
list ParticleParams;
float VelocityRndFactor;
integer IsAttached = FALSE;

integer NotecardLength;
integer NotecardPtr;
key NotecardRequest;

Water(integer On) {
	if (On) {
		SetParticles(ParticleParams);
		llLoopSound(SoundKey, 0.6);
		llSetTimerEvent(WaterObjectFrequency);
	}
	else {
		SetParticles([]);
		llStopSound();
		llSetTimerEvent(0.0);
	}
	IsOn = On;
}
SetParticles(list ParticleParams) {
	if (PrimNozzle > -1) {
		llLinkParticleSystem(PrimNozzle, ParticleParams);
	}
	else {
		llOwnerSay("Nozzle prim not found");
	}
}
ConfigInit() {
	// Set config defaults
	WaterObjectName = "Water";
	WaterObjectFrequency = 1.0;
	WaterObjectVelocityMin = 6.0;
	WaterObjectVelocityMax = 8.0;
}
ConfigLine(string Line) {
	integer Comment = llSubStringIndex(Line, "//");
	if (Comment != 0) {	// Not a complete comment line
		if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);	// strip from comments characters onwards
		if (llStringTrim(Line, STRING_TRIM) != "") {	// if there's something left after comments are removed
			// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
			list L = llParseStringKeepNulls(Line, [ "=" ], [ ]);	// Separate LHS and RHS of assignment
			if (llGetListLength(L) == 2) {	// so there is a "X = Y" kind of syntax
				string OName = llStringTrim(llList2String(L, 0), STRING_TRIM);		// original parameter name
				string Name = llToLower(OName);		// lower-case version for case-independent parsing
				string Value = llStringTrim(llList2String(L, 1), STRING_TRIM);
				// Interpret name/value pairs
				if (Name == "waterobjectname")	WaterObjectName = StripQuotes(Value, Line);
				else if (Name == "waterobjectvelocitymin")	WaterObjectVelocityMin = (float)Value;
				else if (Name == "waterobjectvelocitymax") WaterObjectVelocityMax = (float)Value;
				else if (Name == "waterobjectfrequency") WaterObjectFrequency = (float)Value;
				else if (Name == "attachdirection") AttachDirection = (vector)Value;
				else if (Name == "attachposition") AttachPos = (vector)Value;
				else llOwnerSay("Invalid parameter name in '" + CONFIG_NOTECARD + "': " + OName);
			}
			else {
				llOwnerSay("Invalid line in '" + CONFIG_NOTECARD + "': " + Line);
			}
		}
	}
}
ConfigEnd() {
	// nothing currently here, but processing after notecard reading should go here
}
// Takes a string in double quotes, and strips out the quotes. Validates the format.
// <Text> is the string with quotes; <Line> is the entire line for error reporting
string StripQuotes(string Text, string Line) {
	if (Text == "") {	// allow empty string for null value
		return("");
	}
	if (llGetSubString(Text, 0, 0) == "\"" && llGetSubString(Text, -1, -1) == "\"") { 	// if surrounded by quotes
		return(llGetSubString(Text, 1, -2));	// strip quotes
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
ReadPrims() {
	PrimNozzle = -1;
	integer PrimCount = llGetNumberOfPrims();
	integer P;
	for (P = 1; P <= PrimCount; P++) {
		string Name = llGetLinkName(P);
		if (Name == "nozzle") PrimNozzle = P;
	}
	if (P == -1) llOwnerSay("WARNING! Can't find nozzle prim.");
}
default {
	on_rez(integer param) { llResetScript(); }
	state_entry() {
		IsAttached = llGetAttached();
		IsAnimating = FALSE;
		AvId = llGetOwner();
		ReadPrims();
		state Notecard;
	}
}
state Notecard {
	on_rez(integer param) { llResetScript(); }
	state_entry() {
		// we have to use the awful, ugly native LSL notecard stuff because
		// this script needs to be run by avatars without high threat level permissions
		NotecardLength = -1;
		NotecardRequest = llGetNumberOfNotecardLines(CONFIG_NOTECARD);
		ConfigInit();
	}
	dataserver(key From, string Data) {
		if (From == NotecardRequest) {
			if (NotecardLength == -1) {
				// we've got the number of lines, so start reading
				NotecardLength = (integer)Data;
				NotecardPtr = 0;
				NotecardRequest = llGetNotecardLine(CONFIG_NOTECARD, NotecardPtr);
			}
			else {
				ConfigLine(Data);
				NotecardPtr++;
				if (NotecardPtr > NotecardLength) {
					ConfigEnd();
					state Normal;
				}
				NotecardRequest = llGetNotecardLine(CONFIG_NOTECARD, NotecardPtr);
			}
		}
	}
}
state Normal {
	on_rez(integer param) { llResetScript(); }
	state_entry() {
		VelocityRndFactor = WaterObjectVelocityMax - WaterObjectVelocityMin;
		SoundKey = llGetInventoryKey(llGetInventoryName(INVENTORY_SOUND, 0));
		TextureKey = llGetInventoryKey(llGetInventoryName(INVENTORY_TEXTURE, 0));
		ParticleParams = [
			PSYS_PART_FLAGS, PSYS_PART_INTERP_COLOR_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_FOLLOW_VELOCITY_MASK,
			PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
			PSYS_PART_START_SCALE, <0.2, 0.2, 0.2>,
			PSYS_PART_END_SCALE, <6.0, 6.0, 6.0>,
			PSYS_PART_START_COLOR, <0.6, 0.85, 0.85>,
			PSYS_PART_END_COLOR, <1.0, 1.0, 1.0>,
			PSYS_PART_MAX_AGE, 4.0,
			PSYS_SRC_BURST_RATE, 0.01,
			PSYS_SRC_ACCEL, <0.0, 0.0, -8.3>,
			PSYS_SRC_BURST_PART_COUNT, 6,
			PSYS_SRC_BURST_SPEED_MIN, 15.0,
			PSYS_SRC_BURST_SPEED_MAX, 20.0,
			PSYS_SRC_INNERANGLE, 0.0,
			PSYS_SRC_OUTERANGLE, 0.1,
			PSYS_SRC_TEXTURE, TextureKey,
			PSYS_PART_START_ALPHA, 1.0,
			PSYS_PART_END_ALPHA, 0.0
				];
		Water(FALSE);
		if (IsAttached) {
			llRequestPermissions(AvId, PERMISSION_TRIGGER_ANIMATION);
			Animation = llGetInventoryName(INVENTORY_ANIMATION, 0);	// use animation from inventory
		}
	}
	timer() {
		vector Pos;
		float LinearVelocity = WaterObjectVelocityMin + llFrand(VelocityRndFactor);
		vector AngularVelocity;
		if (IsAttached) {
			rotation AvRot = llGetRootRotation();
			AngularVelocity = (AttachDirection * LinearVelocity) * AvRot;
			Pos = llGetPos() + (AttachPos * AvRot);
		}
		else {
			AngularVelocity =  <0.0, 0.0, LinearVelocity> * llGetRot();
			Pos = llGetPos();
		}
		llRezObject(WaterObjectName, Pos, AngularVelocity, ZERO_ROTATION, 4);
	}
	link_message(integer Sender, integer Num, string Str, key Id) {
		if (Num == 391081100) {
			Water(TRUE);
		}
		else if (Num == -391081100) {
			Water(FALSE);
		}
	}
	touch_start(integer Count)	{
		if (IsOn){
			Water(FALSE);
		}
		else {
			Water(TRUE);
		}
	}
	run_time_permissions(integer Perms)	{
		if (Perms & PERMISSION_TRIGGER_ANIMATION) {
			llStartAnimation(Animation);
			IsAnimating = TRUE;
		}
	}
	attach(key Attached) {
		IsAttached = (Attached != NULL_KEY);
		if (Attached == NULL_KEY && IsAnimating) {
			llStopAnimation(Animation);
			IsAnimating = FALSE;
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) state Notecard;
		if (Change & CHANGED_LINK) llResetScript();
	}
}
// Fire extinguisher v0.3