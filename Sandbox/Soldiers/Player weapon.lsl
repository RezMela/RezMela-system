// Player weapon v0.3
//
// v0.2 - add touch-to-detach
// v0.2 - introduce config file, expand for RPG (gun, not game)
//
// Example config card:
//
// HoldAnimation = "hold_r_handgun"		// holding gun in hand at hip level
// AimAnimation = "aim_r_handgun"		// aiming gun with both hands
// Sound = "Gunshot B"
// Velocity = 10.0						// projectile velocity in m/s
// Offset = <2.0, 0.0, 0.7>				// where the bullet is rezzed relative to the avatar (+X is forward)
// Projectile = "Bullet"				// two projectiles used
// Projectile = "BulletDummy"
//
// Those values are suggested values for the "player pistol" object, which at the time of writing
// was using the pre-config version of this script. So they're kind of untested memo values, based
// on the old hard-coded ones
//

string CONFIG_NOTECARD = "Gun config";		// Name of notecard containing configuration data

string AnimHoldWeapon;
string AnimAimWeapon;	// NB this should be a built-in SL animation that triggers syncing avatar rotation

key OwnerID;		// Owner (ie player)
vector MyPos;		// Avatar position
rotation MyRot;		// Avatar rotation
string CurrentAnimation;
integer PermsGranted;

float Velocity;			// metres/second
vector Offset;		// where the bullet is rezzed relative to the avatar (+X is forward)
string GunSound;		// gunfire sound
list Projectiles;		// list of objects (normally 1 or 2) that will be fired
integer ProjectilesCount;

// Config notecard variables
integer ConfigLine;
integer ConfigLength;
key ConfigReadId;

ProcessNotecardLine(string Line) {
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
				if (Name == "sound")	GunSound = StripQuotes(Value, Line);
				else if (Name == "aimanimation")	AnimAimWeapon = StripQuotes(Value, Line);
				else if (Name == "holdanimation")	AnimHoldWeapon = StripQuotes(Value, Line);
				else if (Name == "projectile") Projectiles += StripQuotes(Value, Line);
				else if (Name == "velocity") Velocity = (float)Value;
				else if (Name == "offset") Offset = (vector)Value;
				else llOwnerSay("Invalid parameter name in '" + CONFIG_NOTECARD + "': " + OName);
			}
			else {
				llOwnerSay("Invalid line in '" + CONFIG_NOTECARD + "': " + Line);
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
// Start animation (blank to stop current animation)
Animate(string Animation) {
	if (CurrentAnimation != "") llStopAnimation(CurrentAnimation);
	if (Animation != "") llStartAnimation(Animation);
	CurrentAnimation = Animation;
}
// Handle click on weapon by owner
Clicked() {
	Animate("");
	llDetachFromAvatar();
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		OwnerID = llGetOwner();
		if (llGetAttached()) state Init1;
	}
	attach(key Id) {
		if (Id == OwnerID) state Init1;
	}
}
// Weapon initialisation
state Init1 {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		PermsGranted = 0;
		llRequestPermissions(OwnerID, PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS | PERMISSION_ATTACH);
	}
	run_time_permissions(integer Perms)	{
		if (Perms & PERMISSION_TAKE_CONTROLS ) {
			llTakeControls(CONTROL_ML_LBUTTON, TRUE, FALSE); // control left mouse button
		}
		PermsGranted = PermsGranted | Perms;
		if (PermsGranted & (PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS | PERMISSION_ATTACH)) state Init2;
	}
}
// This uses old-fashioned SL-type event-based notecard reading because the user may not have permissions
// for the osNotecard* commands.
state Init2 {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Projectiles = [];
		AnimAimWeapon = AnimHoldWeapon = "";
		GunSound = "";
		ConfigLength = -1;	// until we know better
		ConfigReadId = llGetNumberOfNotecardLines(CONFIG_NOTECARD);
	}
	dataserver(key RequestId, string Data) {
		if (RequestId == ConfigReadId) {
			if (ConfigLength == -1) {	// we haven't received a length yet, so this must be it
				ConfigLength = (integer)Data;
				ConfigLine = -1;	// so we start with 0 after ++ below
			}
			else {	// it must be a notecard line
				ProcessNotecardLine(Data);
			}
			ConfigLine++;
			if (ConfigLine == ConfigLength) {		// we've reached the end of the notecard
				// Processing after reading notecard goes here
				ProjectilesCount = llGetListLength(Projectiles);
				// If no gun sound specified, and one sound exists in inventory, use that sound
				if (GunSound == "" && llGetInventoryNumber(INVENTORY_SOUND) == 1) {
					GunSound = llGetInventoryName(INVENTORY_SOUND, 0);
				}
				llOwnerSay("Weapon ready. Press M to aim.");
				state Holding;
			}
			ConfigReadId = llGetNotecardLine(CONFIG_NOTECARD, ConfigLine);
		}
	}
}
// State for holding weapon in hand - progress to aiming state by entering mouselook
state Holding {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Animate(AnimHoldWeapon);			// hold weapon in hand
		llSetTimerEvent(0.5);
	}
	timer() {
		integer AgentInfo = llGetAgentInfo(OwnerID);
		if (AgentInfo & AGENT_MOUSELOOK) {			// if in mouselook,
			state Aiming;							// go into aiming mode
		}
	}
	attach(key Id) {
		if (Id == NULL_KEY) Animate("");	// if detached, attempt to stop animation (usually doesn't work)
	}
	touch_start(integer Count) {
		if (llDetectedKey(0) == OwnerID) Clicked();
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llResetScript();
		if (Change & CHANGED_OWNER) llResetScript();
	}
}
state Aiming {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llTriggerSound(GunSound, 0.001);	// silent gunshot to ensure sound is cached (or does llPreloadSound() work these days?)
		Animate(AnimAimWeapon);
		llSetTimerEvent(0.5);
	}
	control(key Name, integer Levels, integer Edges) {
		integer ControlOn = Levels & Edges;
		if (ControlOn & CONTROL_ML_LBUTTON) {	// pressed mouse button
			Animate(AnimAimWeapon);		// we need this to fine-tune the avatar rotation (see "viewer-generated motions" here: http://wiki.secondlife.com/wiki/Internal_Animations)
			MyPos = llGetPos();	// avatar position
			MyRot = llGetRot(); // avatar rotation - llGetCameraRot() would be better, but needs permissions that result in dialog on OpenSim (see http://opensimulator.org/mantis/view.php?id=4788)
			vector WeaponPos = MyPos + (Offset * MyRot);		// calculate postion of weapon in region, based on weapon offset together with avatar postion/rotation
			vector FireVector = llRot2Fwd(MyRot) * Velocity; // bullet should travel forwards relative to avatar
			llTriggerSound(GunSound, 1.0);			// gunshot sound
			integer I;
			for(I = 0; I < ProjectilesCount; I++) {
				llRezObject(llList2String(Projectiles, I), WeaponPos, FireVector, MyRot, 1);	// create normal bullet and propel
			}
		}
	}
	timer() {
		integer AgentInfo = llGetAgentInfo(OwnerID);
		if (!(AgentInfo & AGENT_MOUSELOOK)) {		// if not in mouselook
			state Holding;							// revert to holding state
		}
	}
	attach(key Id) {
		if (Id == NULL_KEY) Animate("");	// if detached, attempt to stop animation (usually doesn't work)
	}
	touch_start(integer Count) {
		if (llDetectedKey(0) == OwnerID) Clicked();
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llResetScript();
		if (Change & CHANGED_OWNER) llResetScript();
	}
}
// Player weapon v0.3