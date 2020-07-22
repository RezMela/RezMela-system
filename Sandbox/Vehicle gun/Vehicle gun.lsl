// Vehicle gun 0.7

// v0.7 - add ability for another script to trigger destruction via link message

// Tweakable constants
// Names of key prims
string UP_BUTTON = "Up button";
string DOWN_BUTTON = "Down button";
string FIRE_BUTTON = "Fire button";
string AUTO_BUTTON = "Auto button";

string CONFIG_NOTECARD = "Gun config";		// Name of notecard containing configuration data

// Button colours
vector FIRE_BUTTON_INACTIVE = <0.8, 0.7, 0.1>;
vector FIRE_BUTTON_ACTIVE = <0.1, 0.8, 0.1>;
vector AUTO_BUTTON_INACTIVE = <1.0, 1.0, 1.0>;
vector AUTO_BUTTON_ACTIVE = <1.0, 0.2, 0.1>;

integer LM_FIRE_COMMAND = 391081100;	// LM number sent out by vehicle script when they press CONTROL_UP (Page Up)
integer LM_DESTROYED = 58019400;	// LM sent when vehicle is destroyed (and sent negative when resurrected)
integer LM_FORCE_DESTROY = 58019401;	// LM another script can send to this script to trigger destruction

// Configuration data
string FireSound ;			// Name of sound made when gun fires
string Projectile;			// Name of projectile in inventory
vector BarrelNaturalRot;	// Euler rotation (in degrees) of barrel prim when pointing horizontally
vector BarrelTipPos;    // Offset of barrel tip (or slighly beyond that) from centre of barrel prim
string GunPrimName;		// Name of prim representing gun
integer Recoil;			// Boolean: do we recoil?
float MuzzleVelocity;	// Speed at which projectile is propelled (abritrary unit)
list DamageModel;		// Stride: [ <prim name>, <normal pos>, <normal rot>, <damaged pos>, <damaged rot> ] (rotations are Eulers)
float FireDelay;		// delay between subsequent firings
float BlastRadius;		// NPCs will be killed and buildings damaged inside this radius
float ArmingDistance;	// if the shell travels less than this (in m) it's a dud and doesn't explode
float Buoyancy;			// 0-1, where 0 is normal, 1 is completely buoyant
string ProjectileParams;

float PUSH_STEP = 2.0;				// distance in metres pushed back and forwards by each step
float RECOIL_DISTANCE = 2.0;		// distance in metres gun pushed back by recoil
float RECOIL_TURN = 0.1;			// maximum angle (in radians) gun rotated by recoil
float TRAVERSE_STEP_DEG = 4.0;		// amount of traversal step in degrees
float ELEVATE_STEP_DEG = 2.0;		// amount of elevation step in degrees

string DAMAGE_NOTECARD = "!Remove this to reset";	// name of notecard created when damaged, removal of which resets to undamaged
// End of tweakable constants

integer PrimCount;			// number of prims in object

// Link numbers of key prims
integer PrimUp;
integer PrimDown;
integer PrimFire;
integer PrimAuto;
integer PrimBarrel;

rotation rBarrelNaturalRot;	// quaternion equivalent of BarrelNaturalRot
vector BarrelLocalPos;		// position of barrel in local coordinates

integer FireButtonActive = FALSE;	// Fire button is active when TRUE, and gun can be fired
integer AutoMode = FALSE;			// Auto-fire mode when TRUE
string sMyId;

// Fire the weapon
Fire() {
	// Get our pos and rot
	vector MyPos = llGetPos();
	rotation MyRot = llGetRot();
	// find current barrel rotation
	rotation BarrelLocalRot = llList2Rot(llGetLinkPrimitiveParams(PrimBarrel, [ PRIM_ROT_LOCAL ]), 0);
	// compensate for natural rotation (angle of barrel model relative to 0) and rotation of object in region
	rotation BarrelRot = rBarrelNaturalRot * BarrelLocalRot * MyRot;
	// find the position of the tip of the barrel
	vector WeaponPos = MyPos + (BarrelLocalPos * MyRot) + (BarrelTipPos * BarrelLocalRot * MyRot );
	// calculate vector for motion of shell
	vector FireVector = llRot2Up(BarrelRot) * MuzzleVelocity;
	//llOwnerSay((string)(llRot2Euler(BarrelLocalRot) * RAD_TO_DEG));
	// create moving shell
	llRezObject(Projectile, WeaponPos, FireVector, BarrelRot, 1);	// create shell and propel
	// "bang"
	llTriggerSound(FireSound, 1.0);
	if (!AutoMode && Recoil) DoRecoil();	// make gun move in reaction to shot
}
// Backwards movement and rotation of gun in Newtonian reaction to shell fire
DoRecoil() {
	vector Pos = llGetPos() + <0.0, -RECOIL_DISTANCE, 0.0> * llGetRot();	// calculate move backwards
	rotation Rot = llGetRot();
	Rot *= llEuler2Rot(<0.0, 0.0, llFrand(RECOIL_TURN * 2) - RECOIL_TURN>);	// turn slightly at random on Z axis
	llSetPrimitiveParams([ PRIM_POSITION, Pos, PRIM_ROTATION, Rot ]);		// move and rotate the object
}
// Elevate - ie move vertically - by Steps
Elevate(integer Steps) {
	// find current rotation
	rotation BarrelRot = llList2Rot(llGetLinkPrimitiveParams(PrimBarrel, [ PRIM_ROT_LOCAL ]), 0);
	// check to see if we're at a limit
	vector vBR = llRot2Euler(BarrelRot) * RAD_TO_DEG ;
	// checks need to take account of two axes in Euler calculations. These figures are specifically for the howitzer; I
	// know it will be possible to somehow parameterise this and make it more general, but that will have to wait for another
	// day (if it ever happens).
	if (llFabs(vBR.x) < 0.1 && vBR.y > -76.0 && Steps < 0) return;		 	// prevent lowering the gun below about horizontal
	else if (llFabs(vBR.x) > 179.0 && vBR.y > -82.0 && Steps > 0) return;		// prevent raising the gun so high the breech is buried
	// limits OK, so calculate change in angle
	rotation ElevRot = llEuler2Rot(<ELEVATE_STEP_DEG * DEG_TO_RAD * (float)Steps, 0.0, 0.0>);
	// apply change to current angle
	BarrelRot = ElevRot * BarrelRot;
	// set new angle
	llSetLinkPrimitiveParamsFast(PrimBarrel, [ PRIM_ROT_LOCAL, BarrelRot ]);
}
// Set fire button active or inactive
FireButton(integer IsActive) {
	if (PrimFire == -1) return;
	vector Color = FIRE_BUTTON_INACTIVE;
	if (IsActive) Color = FIRE_BUTTON_ACTIVE;
	llSetLinkColor(PrimFire, Color, ALL_SIDES);
	FireButtonActive = IsActive;
}
// Set auto button active or inactive
AutoButton() {
	if (PrimAuto == -1) return;
	vector Color = AUTO_BUTTON_INACTIVE;
	if (AutoMode) Color = AUTO_BUTTON_ACTIVE;
	llSetLinkColor(PrimAuto, Color, ALL_SIDES);
}
// Using damage model data, damage or repair the object
// We could separate the conversion of the data into primitive
// params, and do that at the beginning, but it's just shifting
// the processing from one place to another (damage normally only
// occurs once).
DoDamageModel(integer IsDamaged) {
	list PrimParams = [];
	// show/hide control buttons
	float ButtonAlpha = 1.0;
	if (IsDamaged) ButtonAlpha = 0.0;
	integer Q = PrimCount;
	do {
		if (llListFindList([ PrimUp, PrimDown, PrimFire, PrimAuto ], [ Q ]) > -1) {
			llSetLinkAlpha(Q, ButtonAlpha, ALL_SIDES);
		}
	} while (--Q > 1);
	integer DMLength = llGetListLength(DamageModel);
	integer P;
	// Cycle through damage model entries
	for(P = 0; P < DMLength; P += 5) {
		// extract damage model data
		string PrimName = llList2String(DamageModel, P);
		vector Pos; vector Rot;
		if (IsDamaged) {	// pick appropriate pos/rot
			Pos = (vector)llList2String(DamageModel, P + 3);
			Rot = (vector)llList2String(DamageModel, P + 4);
		}
		else {
			Pos = (vector)llList2String(DamageModel, P + 1);
			Rot = (vector)llList2String(DamageModel, P + 2);
		}
		// find prim to modify
		Q = PrimCount;
		do {
			if (llGetLinkName(Q) == PrimName) {
				PrimParams += [ PRIM_LINK_TARGET, Q, PRIM_POS_LOCAL, Pos, PRIM_ROT_LOCAL, llEuler2Rot(Rot) ];
			}
		} while (--Q > 1);
	}
	// Add in point light (on root prim)
	PrimParams += [ PRIM_LINK_TARGET, 1, PRIM_POINT_LIGHT, IsDamaged, <1.0, 0.8, 0.2>, 1.0, 8.0, 0.7 ];
	llSetPrimitiveParams(PrimParams);
	if (IsDamaged && llGetInventoryType(DAMAGE_NOTECARD) == INVENTORY_NONE)
		osMakeNotecard(DAMAGE_NOTECARD, "");
	llMessageLinked(LINK_SET, -18007420, (string)IsDamaged, NULL_KEY);
}
ReadConfig() {
	// Default values
	GunPrimName = "";
	BarrelNaturalRot = ZERO_VECTOR;
	MuzzleVelocity = 10.0;
	ArmingDistance = 21;
	FireDelay = 3.0;
	Projectile = "";
	FireSound = "";
	Recoil = FALSE;
	DamageModel = [];
	//
	integer Lines = osGetNumberOfNotecardLines(CONFIG_NOTECARD);
	integer I;
	for(I = 0; I < Lines; I++) {
		string Line = osGetNotecardLine(CONFIG_NOTECARD, I);
		integer Comment = llSubStringIndex(Line, "//");
		if (Comment != 0) {	// Not a complete comment line
			if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);	// strip from comments character onwards
			// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
			list L = llParseStringKeepNulls(Line, [ "=" ], [ ]);
			if (llGetListLength(L) == 2) {	// so there is a "X = Y" kind of syntax
				string Name = llToLower(llStringTrim(llList2String(L, 0), STRING_TRIM));
				string Value = llStringTrim(llList2String(L, 1), STRING_TRIM);
				// Interpret name/value pairs
				if (Name == "gunprimname")	GunPrimName = StripQuotes(Value, Line);
				else if (Name == "projectile")	Projectile = StripQuotes(Value, Line);
				else if (Name == "muzzlevelocity")	MuzzleVelocity = (float)Value;
				else if (Name == "recoil")	Recoil = (llListFindList([ "true", "yes", "1" ], [ llToLower(Value) ]) > -1);
				else if (Name == "barrelnaturalrot")	BarrelNaturalRot = (vector)Value;
				else if (Name == "barreltippos") BarrelTipPos = (vector)Value;
				else if (Name == "damagemodel") DamageModel += llCSV2List(Value);
				else if (Name == "firesound") FireSound = StripQuotes(Value, Line);
				else if (Name == "firedelay") FireDelay = (float)Value;
				else if (Name == "blastradius") BlastRadius = (float)Value;
				else if (Name == "armingdistance") ArmingDistance = (float)Value;
				else if (Name == "buoyancy") Buoyancy = (float)Value;
			}
		}
	}
	// If only one sound, and not specified in config card, use that sound
	if (FireSound == "" && llGetInventoryNumber(INVENTORY_SOUND) == 1) FireSound = llGetInventoryName(INVENTORY_SOUND, 0);
	// Set up string to pass to projectile on rezzing
	ProjectileParams = llList2CSV([ BlastRadius, ArmingDistance, Buoyancy ]);
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
// Cycles through prims in the linkset, checking the prim names to see if
// they are notable prims, in which case their link numbers are recorded for
// direct reference. This must be called after any relinking, as well as when
// avatars/NPCs are seated or stand up.
// Returns FALSE if key prims are missing
integer GetLinkNumbers() {
	PrimUp = PrimDown = PrimFire = PrimAuto = PrimBarrel = -1;
	integer I;
	for(I = 1; I <= PrimCount; I++) {
		string Name = llGetLinkName(I);
		if (Name == UP_BUTTON) PrimUp = I;
		else if (Name == DOWN_BUTTON) PrimDown = I;
		else if (Name == FIRE_BUTTON) PrimFire = I;
		else if (Name == AUTO_BUTTON) PrimAuto = I;
		else if (Name == GunPrimName) PrimBarrel = I;
	}
	// Check that essential prims are found (eg no check for auto so it's not mandatory)
	if (GunPrimName != "" && PrimBarrel == -1) {
		llOwnerSay("Can't find named prim(s)");
		return FALSE;
	}
	return TRUE;
}
// Dummy default allowing state changes without script reset
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		state Bootup;
	}
}
// Bootup state initialises vehicle after rezzing or after (eg) change in linkage
state Bootup {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		sMyId = (string)llGetKey();
		PrimCount = llGetNumberOfPrims();
		if (PrimCount < 3) state Hang;		// safeguard for unlinked objects
		ReadConfig();
		if (!GetLinkNumbers()) state Hang;
		// set non-damaged state
		DoDamageModel(FALSE);
		// Get local position of barrel prim
		BarrelLocalPos = llList2Vector(llGetLinkPrimitiveParams(PrimBarrel, [ PRIM_POS_LOCAL ]), 0);
		// Calculate "natural rotation" of barrel prim - ie, local rotation of prim when gun firing horizontally straight ahead
		rBarrelNaturalRot = llEuler2Rot(BarrelNaturalRot * DEG_TO_RAD);
		state Normal;
	}
}
// Booted up and working state
state Normal {
	on_rez(integer Param) { state Bootup; }
	state_entry() {
		// enable fire button
		FireButton(TRUE);
		// disable auto mode
		AutoMode = FALSE;
		AutoButton();
		llMessageLinked(LINK_SET, -LM_DESTROYED, "", NULL_KEY);	// Vehicle is NOT destroyed
	}
	touch_end(integer Count) {
		// find which prim has been clicked
		integer TouchPrim = llDetectedLinkNumber(0);

		// test against stored link numbers to interpret click according to the button clicked
		if (TouchPrim == PrimDown) {
			Elevate(-1);
		}
		else if (TouchPrim == PrimUp) {
			Elevate(1);
		}
		else if (TouchPrim == PrimFire) {
			if (FireButtonActive && !AutoMode) {
				// disable fire button
				FireButton(FALSE);
				// fire the gun
				Fire();
				// delay for reloading
				llSetTimerEvent(FireDelay);
			}
		}
		else if (TouchPrim == PrimAuto) {
			if (FireButtonActive && !AutoMode) {		// button is ready, but auto is not engaged
				AutoMode = TRUE;
				// disable fire button
				FireButton(FALSE);
				// make auto button appear active
				AutoButton();
				Fire();
				llSetTimerEvent(FireDelay);
			}
			else if (AutoMode) {		// turn auto mode off
				AutoMode = FALSE;
				// make auto button appear inactive
				AutoButton();
				// enable fire button
				FireButton(TRUE);
				llSetTimerEvent(0.0);
			}
		}
	}
	timer() {
		if (AutoMode) {
			Fire();
		}
		else {		// re-enable fire button
			llSetTimerEvent(0.0);
			// re-enable fire button after reloading delay
			FireButton(TRUE);
		}
	}
	link_message(integer Sender, integer Number, string Str, key Id) {
		if (Number == LM_FIRE_COMMAND) {
			if (FireButtonActive) {
				// disable fire button
				FireButton(FALSE);
				// fire the gun
				Fire();
				// delay for reloading
				llSetTimerEvent(FireDelay);
			}
		}
		else if (Number == LM_FORCE_DESTROY) {
			state Destroyed;
		}
	}
	object_rez(key Uuid) {
		osMessageObject(Uuid, ProjectileParams);
	}
	dataserver(key QueryId, string Data) {
		if (llGetSubString(Data, 0, 0) == "D" && llGetSubString(Data, 1, -1) == sMyId) state Destroyed;
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) state Bootup;	// if it's relinked, reboot to pick up new link numbers
		if (Change & CHANGED_INVENTORY) state Bootup;	// pick up changed inventory contents
	}
}
// Object is destroyed
state Destroyed {
	on_rez(integer Param) { state Bootup; }
	state_entry() {
		llMessageLinked(LINK_SET, LM_DESTROYED, "", NULL_KEY);	// send message to other scripts so they know to act destroyed
		DoDamageModel(TRUE);	// Configure object to appear destroyed
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY && llGetInventoryType(DAMAGE_NOTECARD) != INVENTORY_NOTECARD) {	// if the damage notecard has been deleted
			state Bootup;
		}
	}
}
// General fail state
state Hang {
	on_rez(integer Param) { state Bootup; }
	changed(integer Change) {
		if (Change & CHANGED_LINK) state Bootup ;
	}
}
// Vehicle gun 0.7