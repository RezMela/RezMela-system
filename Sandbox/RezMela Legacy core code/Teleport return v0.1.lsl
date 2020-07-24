// Teleport return v0.1

string TELEPORT_OBJECT_NAME = "Teleport return";	// also used in controller code

key ControlBoardId;
key AvId;
string AvName;
vector TargetPos;
vector OriginalPos;

integer Sitting = FALSE;
integer ManuallyRezzed = FALSE;

integer PrimCount;

// Variables to implement deletion by reset from control board
float Version = 0.1;
integer GE_VERSION = 9000;
integer WO_DELETE = 3003;

Visibility(integer Visible) {
	float Alpha = 0.0;
	if (Visible) Alpha = 1.0;
	llSetAlpha(Alpha, ALL_SIDES);
}
MoveTo(vector NewPos) {
	llSetRegionPos(NewPos);
}
Die() {
	llDie();
	llDie();
	llDie();
}
SetText() {
	string Text = llGetObjectDesc();
	if (Text == "") {
		Text = AvName;
	}
	else {
		integer P = llSubStringIndex(Text, "%a");
		if (P > -1) Text = llGetSubString(Text, 0, P - 1) + AvName + llGetSubString(Text, P + 2, -1);	// substitute avatar name for %a
	}
	llSetText(Text, <1.0, 1.0, 1.0>, 1.0);
}
default {
	on_rez(integer Param) {
		if (llGetObjectName() != TELEPORT_OBJECT_NAME) {
			llOwnerSay("This object must be named '" + TELEPORT_OBJECT_NAME + "'!");
			return;
		}
		llSetText("", ZERO_VECTOR, 0.0);
		ControlBoardId = osGetRezzingObject();
		if (ControlBoardId == NULL_KEY) {
			llOwnerSay("Manually rezzed - inactive");
			ManuallyRezzed = TRUE;
			Visibility(TRUE);
			return;
		}
		ManuallyRezzed = FALSE;
		llSitTarget(<0.0, 0.0, -0.1>, ZERO_ROTATION);	// make this a sittable prim
		Visibility(FALSE);		// invisible until we're in position
		osMessageObject(ControlBoardId, "init");	// phone home, tell them we're ready to receive data
		llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_PHANTOM, TRUE ]);	 // we need to be phantom (we already should be, but just in case)
		PrimCount = llGetNumberOfPrims();
		Sitting = FALSE;
		llSetTimerEvent(5.0);
	}
	dataserver(key Request, string Data) {
		if (ManuallyRezzed) return;		// don't respond to anything
		// Data arrived from control board telling us what we need to know
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		string Command = llList2String(Parts, 0);
		if (Command == "start") {
			AvId = (key)llList2String(Parts, 1);
			TargetPos = (vector)llList2String(Parts, 2);
			OriginalPos = (vector)llList2String(Parts, 3);
			MoveTo(TargetPos);		// go to the position in-world
			AvName = llKey2Name(AvId);
			SetText();
			llSetClickAction(CLICK_ACTION_SIT);
			Visibility(TRUE);		// become visible
		}
		else if (Command == "die") {
			Die();
		}
		// Commands to implement reset from control board
		else if ((integer)Command == GE_VERSION) {
			osMessageObject(Request, "W" + (string)Version);
		}
		else if ((integer)Command == WO_DELETE) {
			Die();
		}
	}
	changed(integer Change) {
		if (ManuallyRezzed) return;		// don't respond to anything
		if (Change & CHANGED_LINK) {
			key SitAv = llAvatarOnSitTarget();
			if (SitAv != NULL_KEY) {
				// new avatar sitting
				if (SitAv != AvId) {
					llUnSit(SitAv);
					llDialog(SitAv, "Sorry, this is for " + AvName + " only", [ "OK" ], -999999);
					return;
				}
				Sitting = TRUE;
				MoveTo(OriginalPos);
				llUnSit(AvId);
			}
			else if (Sitting) {
				// avatar has stood up
				Die();
			}
		}
		if (Change & CHANGED_REGION_START) Die();
	}
	timer() {
		if (llGetAgentSize(AvId) == ZERO_VECTOR) Die();		// if they've logged out or tp'd out of region, die
	}
}
// Teleport return v0.1