// Simple gun v0.1

// Still some messy Myriad code, needs tidying some time (mostly done now)

integer SIMPLE_GUN_CHANNEL = -93304424900;

float   gVelocity   = 15.0;
float   gReloadTime = 0.30;
string  gShootSound = "gun";
string  gShootAnimation = "hold_r_handgun";
string  gBullet;

key OwnerKey;

default {
	state_entry() {
		state Bootup;
	}
}
state Bootup {
	on_rez(integer Param) {
		llResetScript();
	}
	state_entry() {
		gBullet = llGetInventoryName(INVENTORY_OBJECT, 0);
		OwnerKey = llGetOwner();
		if (llGetAttached()) state Normal;
		llOwnerSay("Not attached - disabled");
	}
}
state Normal {
	state_entry() {
		llOwnerSay("Gun is ready. Enter mouselook and use left click to fire!");
		llRequestPermissions(OwnerKey,
			PERMISSION_TAKE_CONTROLS |
			PERMISSION_TRIGGER_ANIMATION |
			PERMISSION_TRACK_CAMERA |
			PERMISSION_ATTACH
			);
	}
	dataserver(key Uuid, string Data) {
		if (llGetSubString(Data, 0, 0) == "H") {	// looks like a message from the projectile giving the UUID of an agent/NPC it hit
			key HitUuid = llGetSubString(Data, 1, -1);
			llRegionSay(SIMPLE_GUN_CHANNEL, (string)HitUuid);
		}
	}
	attach(key Id) {
		if (Id != NULL_KEY){
			state Bootup;
		}
		else {
			llStopAnimation(gShootAnimation);
			llReleaseControls();
		}
	}
	touch_start(integer Count) {
		if (llDetectedKey(0) == OwnerKey) {
			llStopAnimation(gShootAnimation);
			llReleaseControls();
			llDetachFromAvatar();			
		}
	}
	changed(integer Change)	{
		if (Change & (CHANGED_OWNER | CHANGED_INVENTORY) )
			llResetScript();
	}
	run_time_permissions(integer Perms) {
		if (Perms & PERMISSION_TAKE_CONTROLS) {
			llTakeControls(CONTROL_ML_LBUTTON, TRUE, FALSE);
		}
		if (Perms & PERMISSION_TRIGGER_ANIMATION) {
			llStartAnimation(gShootAnimation);
		}
	}
	control(key id, integer held, integer change) {
		rotation Rot = llGetCameraRot();
		if ( held & change & CONTROL_ML_LBUTTON)
		{
			if (llGetInventoryType(gShootSound) == INVENTORY_SOUND)
				llPlaySound(gShootSound, 1.0);
			llRezAtRoot(gBullet, llGetCameraPos() + <1.5, 0.0, 0.0>*Rot, gVelocity*llRot2Fwd(Rot), Rot, 10);
			llSleep(gReloadTime);
		}
	}
}
// Simple gun v0.1