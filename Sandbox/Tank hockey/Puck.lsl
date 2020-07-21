// Tank hockey puck v0.8

// v0.8 - now rezzed by server, and no longer creates own children
// v0.7 - reworked passing of generation (using osMessageObject() instead of start parameter)
// v0.6 - bug fix (start parameter)
// v0.5 - added splitting on detection of shell
// v0.4 - added vertical stability, prevent puck from rolling indefinitely

string CONFIG_NOTECARD = "Puck config";

integer TH_CHAT_CHANNEL = -3920100;

float PI_BY_FOUR = 0.785;	// approximate :)
float MINIMUM_SIZE = 0.02;	// puck will not shrink below this size

integer SCRIPT_PIN = 4444;

key ServerUuid;

list DustParticles;
string DustParticleTexture;
list FlameParticles;
string FlameParticleTexture;
list SmokeParticles;
string SmokeParticleTexture;
integer Emitting = FALSE;

key MyId;
string sMyId;
vector MyPos;
vector CurrentVelocity;
integer PrimCount;
integer StartParam;
integer Generation;		// 0 is original, 1 is child, 2 is grandchild etc
integer NewGeneration;	// generation to be handed down to child prim
integer TouchToDestroy;

vector StartPos;
vector CentrePos;
float PhysDelay;
vector PitchSize;
float CentrePush;		// factor of force applied to push towards centre
float NeutralArea;		// proportion of pitch which has no tendency towards centre
float ShrinkBy;
float Buoyancy;
key InitialSound;

GoHome() {
	llSetBuoyancy(0.0);
	MoveTo(CentrePos);
	llSleep(2.0);
	llSetBuoyancy(Buoyancy);
}
MoveTo(vector NewPos) {
	list Params = [];
	integer Jumps = (integer)(llVecDist(llGetPos(), NewPos) / 10.0) + 1;
	while(Jumps--) {
		Params += [ PRIM_POSITION, NewPos ];
	}
	llSetLinkPrimitiveParamsFast(1, Params);
}
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Can't find notecard '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	// Set config defaults
	DustParticleTexture = "";
	FlameParticleTexture = "";
	SmokeParticleTexture = "";

	Buoyancy = 0.6;
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
					if (Name == "buoyancy") Buoyancy = (float)Value;
					else if (Name == "dusttexture") DustParticleTexture = StripQuotes(Value, Line);
					else if (Name == "flametexture") FlameParticleTexture = StripQuotes(Value, Line);
					else if (Name == "smoketexture") SmokeParticleTexture = StripQuotes(Value, Line);
					else llOwnerSay("Invalid parameter name in '" + CONFIG_NOTECARD + "': " + OName);
				}
				else {
					llOwnerSay("Invalid line in '" + CONFIG_NOTECARD + "': " + Line);
				}
			}
		}
	}
	return TRUE;
}
// Takes a string in double quotes, and strips out the quotes. Validates the format.
// <Text> is the string with quotes; <Line> is the entire line for error reporting
string StripQuotes(string Text, string Line) {
	if (Text == "") {	// allow empty string
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


// Shrink object according to supplied factor; also removes transparency
Shrink(float ShrinkFactor) {
	list WriteParams = [];
	integer P;
	for(P = 1; P <= PrimCount; P++) {
		list ReadParams = llGetLinkPrimitiveParams(P, [ PRIM_SIZE, PRIM_POS_LOCAL ]);
		vector Size = llList2Vector(ReadParams, 0);
		vector LocalPos = llList2Vector(ReadParams, 1);
		Size *= ShrinkFactor;
		if (Size.x < MINIMUM_SIZE) Size.x = MINIMUM_SIZE;
		if (Size.y < MINIMUM_SIZE) Size.y = MINIMUM_SIZE;
		if (Size.z < MINIMUM_SIZE) Size.z = MINIMUM_SIZE;
		WriteParams += [ PRIM_LINK_TARGET, P, PRIM_SIZE, Size ];
		if (P > 1) {
			LocalPos *= ShrinkFactor;
			WriteParams += [ PRIM_POS_LOCAL, LocalPos ];
		}
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, WriteParams);
}
// Removes transparency
MakeVisible() {
	integer P;
	for(P = 2; P <= PrimCount; P++) {
		llSetLinkAlpha(P, 1.0, ALL_SIDES);
	}
}
Die() {
	while(1 == 1) {
		llDie();
		llSleep(0.5);
	}
}
default {
	on_rez(integer Start) { llResetScript(); }
	state_entry() {
		llParticleSystem([]);
		llLinkParticleSystem(2, []);
		llSetRemoteScriptAccessPin(SCRIPT_PIN);
		if(llGetStartParameter() == 0) {
			llOwnerSay("Not rezzed by server, so in standby mode");
			llSetStatus(STATUS_PHYSICS, FALSE);
			llSetStatus(STATUS_PHANTOM, FALSE);
			return;
		}
		MyId = llGetKey();
		sMyId = (string)MyId;
		PrimCount = llGetNumberOfPrims();
		StartParam = llGetStartParameter();
		llSetTimerEvent(60.0);
	}
	dataserver(key Uuid, string Data) {
		if (llGetSubString(Data, 0, 0) == "G") {
			osMessageObject(Uuid, "G");				// ACK to the server
			ServerUuid = Uuid;
			list Parts = llCSV2List(llGetSubString(Data, 1, -1));
			Generation = llList2Integer(Parts, 0);
			StartPos = llList2Vector(Parts, 1);
			CentrePos = llList2Vector(Parts, 2);
			ShrinkBy = llList2Float(Parts, 3);
			PhysDelay  = llList2Float(Parts, 4);
			CentrePos = llList2Vector(Parts, 5);
			PitchSize = llList2Vector(Parts, 6);
			NeutralArea = llList2Float(Parts, 7);
			CentrePush = llList2Float(Parts, 8);
			InitialSound = llList2Key(Parts, 9);
			TouchToDestroy = llList2Integer(Parts, 10);
			state Setup;
		}
	}
	timer() {
		llOwnerSay("Did not receive initial data");
		llSetTimerEvent(0.0);
	}
}
state Setup {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		if (!ReadConfig()) return;
		vector DustColor = <1.0, 0.9, 0.6>;
		DustParticles = [
			PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
			PSYS_PART_MAX_AGE,2.0,
			PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_INTERP_COLOR_MASK,
			PSYS_PART_START_COLOR, DustColor,
			PSYS_PART_END_COLOR, DustColor,
			PSYS_PART_START_ALPHA, 0.2,
			PSYS_PART_END_ALPHA, 0.0,
			PSYS_PART_START_SCALE,  <2.0, 2.0, 0.0>,
			PSYS_PART_END_SCALE, <4.0, 4.0, 0.0>,
			PSYS_SRC_ANGLE_BEGIN, PI_BY_TWO,
			PSYS_SRC_ANGLE_END, PI_BY_TWO,
			PSYS_PART_MAX_AGE, 3.0,
			PSYS_SRC_BURST_RADIUS, 2.0,
			PSYS_SRC_BURST_PART_COUNT, 16,
			PSYS_SRC_BURST_RATE, 0.2,
			PSYS_SRC_ACCEL, <0.0, 0.0, -0.1>,
			PSYS_SRC_BURST_SPEED_MIN, 0.8,
			PSYS_SRC_BURST_SPEED_MAX, 1.4,
			PSYS_SRC_TEXTURE, DustParticleTexture
				];
		FlameParticles = [
			PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
			PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_INTERP_COLOR_MASK,
			PSYS_SRC_BURST_SPEED_MIN, 1.0,
			PSYS_SRC_BURST_SPEED_MAX, 3.0,
			PSYS_PART_START_SCALE, <1.0, 1.0, 0.0>,
			PSYS_PART_END_SCALE, <4.0, 4.0, 0.0>,
			PSYS_PART_MAX_AGE, 1.2,
			PSYS_SRC_MAX_AGE, 2.0,
			PSYS_SRC_BURST_RATE, 0.01,
			PSYS_SRC_BURST_PART_COUNT, 10,
			PSYS_SRC_TEXTURE, FlameParticleTexture,
			PSYS_PART_START_ALPHA, 0.6,
			PSYS_PART_END_ALPHA, 0.0
				];
		SmokeParticles = [
			PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
			PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_INTERP_COLOR_MASK,
			PSYS_SRC_BURST_SPEED_MIN, 1.0,
			PSYS_SRC_BURST_SPEED_MAX, 4.0,
			PSYS_PART_START_SCALE, <2.0, 2.0, 2.0>,
			PSYS_PART_END_SCALE, <4.0, 4.0, 0.0>,
			PSYS_PART_MAX_AGE, 1.2,
			PSYS_SRC_MAX_AGE, 2.0,
			PSYS_SRC_BURST_RATE, 0.01,
			PSYS_SRC_BURST_PART_COUNT, 10,
			PSYS_SRC_TEXTURE, SmokeParticleTexture,
			PSYS_PART_START_COLOR, <0.2, 0.2, 0.2>,
			PSYS_PART_END_COLOR, <0.8, 0.8, 0.8>,
			PSYS_PART_START_ALPHA, 0.6,
			PSYS_PART_END_ALPHA, 0.0
				];
		// go to position the server told us
		MoveTo(StartPos);
		// if we're a child generation, make us smaller
		if (Generation > 1) Shrink(ShrinkBy);
		// become visible
		MakeVisible();
		llSetStatus(STATUS_DIE_AT_EDGE, TRUE);
		if (PhysDelay > 0.0) llSleep(PhysDelay);
		llSetStatus(STATUS_PHANTOM, FALSE);
		llSetStatus(STATUS_PHYSICS, TRUE);
		llSetBuoyancy(Buoyancy);
		llTriggerSound(InitialSound, 1.0);
		state Normal;
	}
	changed(integer Change)	{
		if (Change & CHANGED_INVENTORY) llResetScript();	// allow for updating of object in object
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llParticleSystem([]);
		Emitting = FALSE;
		llSetTimerEvent(0.5);
	}
	collision(integer Count) {
		if (!Emitting) {
			llParticleSystem(DustParticles);
			Emitting = TRUE;
		}
	}
	touch_start(integer Count)	{
		if (TouchToDestroy) state Destroyed;
	}
	dataserver(key QueryId, string Data) {
		string FirstChar = llGetSubString(Data, 0, 0);
		if (FirstChar == "D" && llGetSubString(Data, 1, -1) == sMyId) state Destroyed;
		else if (FirstChar == "H") GoHome();
		else if (FirstChar == "X") Die();
	}
	timer() {
		MyPos = llGetPos();
		float GroundHeight = llGround(ZERO_VECTOR);
		if (MyPos.z < GroundHeight - 1.0) {
			llSetStatus(STATUS_PHYSICS, FALSE);
			MyPos.z = GroundHeight + 2.0;		// we assUme that the centre of the root prim is normally <2m above the ground
			llSetPos(MyPos);
			llSleep(0.5);
			llSetStatus(STATUS_PHYSICS, TRUE);
			vector Impulse;
			Impulse.x = llFrand(2.0) - 1.0;
			Impulse.y = llFrand(2.0) - 1.0;
			Impulse.z = 2.0;
			Impulse *= llGetMass();
			llApplyImpulse(Impulse, FALSE);	// give a slight push upwards and random sideways force
		}
		CurrentVelocity = llGetVel();
		if (CurrentVelocity == ZERO_VECTOR) {
			llParticleSystem([]);
			Emitting = FALSE;
		}
		vector Push = ZERO_VECTOR;
		vector ToCentre = MyPos - CentrePos;
		if (llFabs(ToCentre.x) > (PitchSize.x * NeutralArea)) Push.x = -ToCentre.x;
		if (llFabs(ToCentre.y) > (PitchSize.y * NeutralArea)) Push.y = -ToCentre.y;
		llSetForce(Push * CentrePush, FALSE);	// note that Push might be null, in which case force is removed
		vector EulerRot = llRot2Euler(llGetRot());
		if (llFabs(EulerRot.x) > PI_BY_FOUR || llFabs(EulerRot.y) > PI_BY_FOUR) {
			EulerRot.x = 0.0;
			EulerRot.y = 0.0;
			llSetRot(llEuler2Rot(EulerRot));
		}
	}
}
state Destroyed {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		osMessageObject(ServerUuid, "DP" + (string)MyPos);
		llSetTimerEvent(0.0);
		llSetStatus(STATUS_PHANTOM, TRUE);	// so we don't interfere with other objects
		llSetStatus(STATUS_PHYSICS, FALSE);
		llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);		// turn invisible
		MoveTo(MyPos);
		llParticleSystem(FlameParticles);
		llLinkParticleSystem(2, SmokeParticles);
		llSleep(1.0);
		Die();
	}
}
// Tank hockey puck v0.8