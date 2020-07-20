// Exercise controller v0.3.1

// Object should have the number of calories per CALORIE_PERIOD as its description

// Tunable constants
vector SIT_POSITION = <1.0, 0.0, 1.0>;
rotation SIT_ROTATION = ZERO_ROTATION;
float CALORIE_PERIOD = 10.0;	// period between calories being deducted
integer DEFAULT_CALORIES = 50;

//
integer MALL_CHANNEL = -84403270;

string Animation;
key NpcId;
string MyName;
integer Calories;

default {
	state_entry() {
		llSitTarget(SIT_POSITION, SIT_ROTATION);	// adjust as necessary
		// Animation is first in inventory
		Animation = llGetInventoryName(INVENTORY_ANIMATION, 0);
		MyName = llGetObjectName();
		Calories = (integer)llGetObjectDesc();
		if (!Calories) Calories = DEFAULT_CALORIES;		// have a default value just in case
		// Unsit just in case
		key StillOn = llAvatarOnSitTarget();
		if (StillOn != NULL_KEY) llUnSit(StillOn);
		state Normal;
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
	}
	changed(integer Change)	{
		if (Change & CHANGED_INVENTORY) llResetScript();
		if (Change & CHANGED_LINK) {
			key ThisAvId = llAvatarOnSitTarget();
			if (ThisAvId != NULL_KEY) {
				// Avatar is sitting
				NpcId = ThisAvId;
				llRequestPermissions(NpcId, PERMISSION_TRIGGER_ANIMATION);
			}
			else {
				// Avatar is not sitting
				if (NpcId != NULL_KEY) {		// they must have stood up
					llStopAnimation(Animation);
					llSetTimerEvent(0.0);
					NpcId = NULL_KEY;
				}
			}
		}
	}
	timer() {
		// We send an FE message to the NPC, which is picked up by their attachment
		// FE is "food exercise", format is FE<NPC ID>|<exercise name>|<calories>
		llRegionSayTo(NpcId, MALL_CHANNEL, "FE" + (string)NpcId + "|" + MyName + "|" + (string)Calories);
	}
	run_time_permissions(integer Perms)	{
		if (Perms & PERMISSION_TRIGGER_ANIMATION) {
			llStopAnimation("sit");
			llStartAnimation(Animation);
			llSetTimerEvent(CALORIE_PERIOD);
		}
	}
}
// Exercise controller v0.3.1