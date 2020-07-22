// Howitzer v0.7

// Tweakable constants
// Names of key prims
string LEFT_BUTTON = "Left button";
string RIGHT_BUTTON = "Right button";
string FORWARD_BUTTON = "Forward button";
string BACK_BUTTON = "Back button";
string UP_BUTTON = "Up button";
string DOWN_BUTTON = "Down button";
string FIRE_BUTTON = "Fire button";
string AUTO_BUTTON = "Auto button";
string BARREL_PRIM = "Barrel";

string FireSound ;
string SHELL_OBJECT = "Howitzer shell";		// Name of shell object in inventory
float SHELL_VELOCITY = 10.0;
integer SHELL_ARM_DISTANCE = 5;

float FIRE_DELAY = 3.0;		// delay between subsequent firings
// Button colours
vector FIRE_BUTTON_INACTIVE = <0.8, 0.7, 0.1>;
vector FIRE_BUTTON_ACTIVE = <0.1, 0.8, 0.1>;
vector AUTO_BUTTON_INACTIVE = <1.0, 1.0, 1.0>;
vector AUTO_BUTTON_ACTIVE = <1.0, 0.2, 0.1>;

vector BARREL_NATURAL_ROT = <72.5, 0.0, 0.0>;	// Euler rotation (in degrees) of barrel prim when pointing horizontally
vector BARREL_TIP_POS = <0.0189, 2.342, -4.70>;    // Offset of barrel tip (or slighly beyond that) from centre of barrel prim
vector BARREL_DAMAGED_POS = <-0.039,0.113,0.829>;
vector BARREL_DAMAGED_ROT = <1.572,-0.0518,-0.704>;
vector BARREL_DEFAULT_POS = <0.0, -0.127, 0.829>;	// Pos for reset from damage (not normally used)
vector BARREL_DEFAULT_ROT = <1.71, 0.0, 0.0>;		// Euler rot for reset from damage (not normally used)

float PUSH_STEP = 2.0;				// distance in metres pushed back and forwards by each step
float RECOIL_DISTANCE = 2.0;		// distance in metres gun pushed back by recoil
float RECOIL_TURN = 0.1;			// maximum angle (in radians) gun rotated by recoil
float TRAVERSE_STEP_DEG = 4.0;		// amount of traversal step in degrees
float ELEVATE_STEP_DEG = 2.0;		// amount of elevation step in degrees

string DAMAGE_NOTECARD = "Remove this to reset";	// name of notecard created when damaged, removal of which resets to undamaged
// End of tweakable constants

// Link numbers of key prims
integer PrimCount;
integer PrimLeft;
integer PrimRight;
integer PrimForward;
integer PrimBack;
integer PrimUp;
integer PrimDown;
integer PrimFire;
integer PrimAuto;
integer PrimBarrel;

rotation BarrelNaturalRot;	// quaternion equivalent of BARREL_NATURAL_ROT
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
	rotation BarrelRot = BarrelNaturalRot * BarrelLocalRot * MyRot;
	// find the position of the tip of the barrel
	vector WeaponPos = MyPos + (BarrelLocalPos * MyRot) + (BARREL_TIP_POS * BarrelLocalRot * MyRot );
	// calculate vector for motion of shell
	vector FireVector = llRot2Up(BarrelRot) * SHELL_VELOCITY ;
	// create moving shell
	llRezObject(SHELL_OBJECT, WeaponPos, FireVector, BarrelRot, (string)SHELL_ARM_DISTANCE);	// create shell and propel
	// "bang"
	llTriggerSound(FireSound, 1.0);
	if (!AutoMode) Recoil();	// make gun move in reaction to shot
}
// Push - move forwards or backwards - by Steps
Push(integer Steps) {
	llSetPos(llGetPos() + <0.0, PUSH_STEP * (float)Steps, 0.0> * llGetRot());
}
// Traverse - ie move horizontally - by Steps
Traverse(integer Steps) {
	rotation RootRot = llGetRot();
	rotation TravRot = llEuler2Rot(<0.0, 0.0, TRAVERSE_STEP_DEG * DEG_TO_RAD * (float)Steps>);
	RootRot = TravRot * RootRot;
	llSetRot(RootRot);
}
// Backwards movement and rotation of gun in Newtonian reaction to shell fire
Recoil() {
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
	vector vBR = llRot2Euler(BarrelRot);
	if (vBR.x < 1.25 && Steps < 0) return;		 	// prevent lowering the gun below about horizontal
	else if (vBR.x > 1.75 && Steps > 0) return;		// prevent raising the gun so high the breech is buried
	// limits OK, so calculate change in angle
	rotation ElevRot = llEuler2Rot(<ELEVATE_STEP_DEG * DEG_TO_RAD * (float)Steps, 0.0, 0.0>);
	// apply change to current angle
	BarrelRot = ElevRot * BarrelRot;
	// set new angle
	llSetLinkPrimitiveParamsFast(PrimBarrel, [ PRIM_ROT_LOCAL, BarrelRot ]);
}
// Set fire button active or inactive
FireButton(integer IsActive) {
	vector Color = FIRE_BUTTON_INACTIVE;
	if (IsActive) Color = FIRE_BUTTON_ACTIVE;
	llSetLinkColor(PrimFire, Color, ALL_SIDES);
	FireButtonActive = IsActive;
}
// Set auto button active or inactive
AutoButton() {
	vector Color = AUTO_BUTTON_INACTIVE;
	if (AutoMode) Color = AUTO_BUTTON_ACTIVE;
	llSetLinkColor(PrimAuto, Color, ALL_SIDES);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		state Bootup;
	}
}
state Bootup {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		sMyId = (string)llGetKey();
		PrimCount = llGetNumberOfPrims();
		if (PrimCount < 5) state Hang;
		PrimLeft = PrimRight = PrimForward = PrimBack = PrimUp = PrimDown = PrimFire = PrimAuto = PrimBarrel = -1;
		integer I;
		for(I = 1; I <= PrimCount; I++) {
			string Name = llGetLinkName(I);
			if (Name == LEFT_BUTTON) PrimLeft = I;
			else if (Name == RIGHT_BUTTON) PrimRight = I;
			else if (Name == FORWARD_BUTTON) PrimForward = I;
			else if (Name == BACK_BUTTON) PrimBack = I;
			else if (Name == UP_BUTTON) PrimUp = I;
			else if (Name == DOWN_BUTTON) PrimDown = I;
			else if (Name == FIRE_BUTTON) PrimFire = I;
			else if (Name == AUTO_BUTTON) PrimAuto = I;
			else if (Name == BARREL_PRIM) PrimBarrel = I;
		}
		// Check that essential prims are found (eg no check for auto so it's not mandatory)
		if (PrimLeft == -1 || PrimRight == -1 || PrimForward == -1 || PrimBack == -1 || PrimUp == -1 || PrimDown == -1 || PrimBarrel == -1) {
			llOwnerSay("Can't find named prim(s)");
			state Hang;
		}
		// set non-damaged state
		llSetLinkPrimitiveParamsFast(PrimBarrel, [
			PRIM_POS_LOCAL, BARREL_DEFAULT_POS,
			PRIM_ROT_LOCAL, llEuler2Rot(BARREL_DEFAULT_ROT),
			PRIM_POINT_LIGHT, FALSE, ZERO_VECTOR, 0.0, 0.0, 0.0
				]);
		llMessageLinked(LINK_SET, -18007420, "0", NULL_KEY);

		BarrelLocalPos = llList2Vector(llGetLinkPrimitiveParams(PrimBarrel, [ PRIM_POS_LOCAL ]), 0);
		BarrelNaturalRot = llEuler2Rot(BARREL_NATURAL_ROT);
		FireSound = llGetInventoryName(INVENTORY_SOUND, 0);
		state Normal;
	}
}
state Normal {
	on_rez(integer Param) { state Bootup; }
	state_entry() {
		// enable fire button
		FireButton(TRUE);
		// disable auto mode
		AutoMode = FALSE;
		AutoButton();
	}
	touch_end(integer Count) {
		// find which prim has been clicked
		integer TouchPrim = llDetectedLinkNumber(0);

		// test against stored link numbers to interpret click according to the button clicked
		if (TouchPrim == PrimLeft) {
			Traverse(-1);
		}
		else if (TouchPrim == PrimRight) {
			Traverse(1);
		}
		else if (TouchPrim == PrimForward) {
			Push(1);
		}
		else if (TouchPrim == PrimBack) {
			Push(-1);
		}
		else if (TouchPrim == PrimDown) {
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
				llSetTimerEvent(FIRE_DELAY);
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
				llSetTimerEvent(FIRE_DELAY);
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
	dataserver(key QueryId, string Data) {
		if (llGetSubString(Data, 0, 0) == "D" && llGetSubString(Data, 1, -1) == sMyId) state Destroyed;
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) state Reboot;	// if it's relinked, reboot to pick up new link numbers
	}
}
state Destroyed {
	on_rez(integer Param) { state Bootup; }
	state_entry() {
		if (llGetInventoryType(DAMAGE_NOTECARD) == INVENTORY_NONE)
			osMakeNotecard(DAMAGE_NOTECARD, "");
		llSetLinkPrimitiveParamsFast(PrimBarrel, [
			PRIM_POS_LOCAL, BARREL_DAMAGED_POS,
			PRIM_ROT_LOCAL, llEuler2Rot(BARREL_DAMAGED_ROT),
			PRIM_POINT_LIGHT, TRUE, <1.0, 0.8, 0.2>, 1.0, 8.0, 0.7
				]);
		llMessageLinked(LINK_SET, -18007420, "1", NULL_KEY);
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY && llGetInventoryType(DAMAGE_NOTECARD) != INVENTORY_NOTECARD) {	// if the damage notecard has been deleted
			state Bootup;
		}
	}
}
state Hang {
	on_rez(integer Param) { state Bootup; }
	changed(integer Change) {
		if (Change & CHANGED_LINK) state Bootup ;
	}
}
// Howitzer v0.7