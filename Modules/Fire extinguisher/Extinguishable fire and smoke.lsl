// Extinguishable fire and smoke v0.1

string CONFIG_NOTECARD = "Fire/smoke config";

string TEXTURE_SMOKE1 = "3e2d6532-03ee-4248-89fb-72605360add5"; // Ramesh's smoke texture
string TEXTURE_SMOKE2 = "c2470052-f128-4a6f-afce-2cc5210eed88"; // Handy's Tools "Abune 6" smoke texture

// From config notecard
integer SmokeParticles;
integer FireTexture = FALSE;
string WaterObjectName;
float SensorRange;
float SensorFrequency;
integer SensorHits;

list ParticleParams;
list HitList;
integer HitCount;

ReadConfig() {
	// Set config defaults
	SmokeParticles = 0;
	SensorRange = 4.0;
	SensorFrequency = 2.0;
	SensorHits = 4;
	FireTexture = FALSE;
	WaterObjectName = "Water";
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Can't find notecard '" + CONFIG_NOTECARD + "'");
		return;
	}
	integer Lines = osGetNumberOfNotecardLines(CONFIG_NOTECARD);
	integer I;
	for(I = 0; I < Lines; I++) {
		string Line = osGetNotecardLine(CONFIG_NOTECARD, I);
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
					if (Name == "smokeparticles")	SmokeParticles = (integer)Value;
					else if (Name == "firetexture")	FireTexture = String2Bool(Value);
					else if (Name == "waterobject")	WaterObjectName = StripQuotes(Value, Line);
					else if (Name == "sensorrange")	SensorRange = (float)Value;
					else if (Name == "sensorfrequency")	SensorFrequency = (float)Value;
					else if (Name == "sensorhits")	SensorHits = (integer)Value;
					else llOwnerSay("Invalid parameter name in '" + CONFIG_NOTECARD + "': " + OName);
				}
				else {
					llOwnerSay("Invalid line in '" + CONFIG_NOTECARD + "': " + Line);
				}
			}
		}
	}
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
Setup() {
	if (SmokeParticles == 0) {
		ParticleParams = [];
	}
	else if (SmokeParticles == 1) {
		ParticleParams = [
			PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
			PSYS_PART_FLAGS, PSYS_PART_WIND_MASK | PSYS_PART_FOLLOW_VELOCITY_MASK | PSYS_PART_INTERP_COLOR_MASK | PSYS_PART_INTERP_SCALE_MASK,
			PSYS_SRC_BURST_PART_COUNT, 15,
			PSYS_SRC_BURST_RATE, 0.6,
			PSYS_PART_MAX_AGE, 15.0,
			PSYS_SRC_BURST_RADIUS, 0.0,
			PSYS_SRC_ANGLE_BEGIN, 0.0,
			PSYS_SRC_ANGLE_END, 1.57,
			PSYS_SRC_BURST_SPEED_MIN, 1.0,
			PSYS_SRC_BURST_SPEED_MAX, 2.0,
			PSYS_PART_END_SCALE, <4.0, 4.0, 4.0>,
			PSYS_PART_START_SCALE, <2.0, 2.0, 2.0>,
			PSYS_PART_END_COLOR, <1.0, 1.0, 1.0>,
			PSYS_PART_START_COLOR, <0.7, 0.7, 0.7>,
			PSYS_PART_END_ALPHA, 0.0,
			PSYS_PART_START_ALPHA, 0.5,
			PSYS_SRC_TEXTURE, TEXTURE_SMOKE1
				];
	}
	else if (SmokeParticles == 2) {
		ParticleParams = [
			PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
			PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_INTERP_COLOR_MASK,
			PSYS_PART_END_ALPHA, 0.0,
			PSYS_PART_END_COLOR, <0.8, 0.8, 0.8>,
			PSYS_PART_START_COLOR, <0.4, 0.4, 0.4>,
			PSYS_PART_START_SCALE,  <1.0, 1.0, 0.0>,
			PSYS_PART_END_SCALE, <4.0, 4.0, 0.0>,
			PSYS_PART_MAX_AGE, 7.0,
			PSYS_SRC_ACCEL, <0.0, 0.0, 0.6>,
			PSYS_SRC_BURST_PART_COUNT, 2,
			PSYS_SRC_BURST_RADIUS, 0.2,
			PSYS_SRC_BURST_RATE, 0.2,
			PSYS_SRC_BURST_SPEED_MIN, 0.1,
			PSYS_SRC_BURST_SPEED_MAX, 0.6,
			PSYS_SRC_ANGLE_BEGIN, 0.0,
			PSYS_SRC_ANGLE_END, 0.25,
			PSYS_SRC_TEXTURE, TEXTURE_SMOKE2
				];
	}
	if (FireTexture)
		llSetTextureAnim (ANIM_ON | LOOP, ALL_SIDES, 4, 4, 0.0, 0.0, 16.0);
	else
		llSetTextureAnim(FALSE, ALL_SIDES, 0, 0, 0.0, 0.0, 16.0);
}
ShowEffects(integer On) {
	if (On) {
		llParticleSystem(ParticleParams);
		llSensorRepeat(WaterObjectName, NULL_KEY, SCRIPTED, SensorRange, PI, SensorFrequency);
		if (FireTexture) {
			llSetAlpha(1.0, ALL_SIDES);
			llSetPrimitiveParams([ PRIM_SLICE, <0.0, 1.0, 0.0>]);
		}
	}
	else {
		llParticleSystem([]);
		llSensorRemove();
		if (FireTexture) {
			llSetAlpha(0.0, ALL_SIDES);
			llSetPrimitiveParams([ PRIM_SLICE, <0.0, 0.1, 0.0>]);
		}
	}
	HitList = [];
	HitCount = 0;
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		ReadConfig();
		Setup();
		ShowEffects(FALSE);
	}
	link_message(integer Sender, integer Num, string Str, key Id) {
		if (Num == -18007420) {
			ShowEffects((integer)Str);
		}
	}
	sensor(integer Count) {
		while(Count--) {
			key Uuid = llDetectedKey(Count);
			if (llListFindList(HitList, [ Uuid ]) == -1) {
				HitList += Uuid;
				HitCount++;
				if (HitCount >= SensorHits) {
					ShowEffects(FALSE);
				}
			}
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llResetScript();
	}
}
// Extinguishable fire and smoke v0.1