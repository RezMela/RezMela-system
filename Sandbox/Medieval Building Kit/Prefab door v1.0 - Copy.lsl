// Prefab door v1.0

string CONFIG_FILE = "Door config";

// Link message numbers, sent/rec'd by ML main script
integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_MOVED_ROTATED = -405560;
integer LM_PRIM_SELECTED = -405500;		// A prim has been selected
integer LM_PRIM_DESELECTED = -405501;	// A prim has been deselected
integer LM_RESERVED_TOUCH_FACE = -44088510;        // Reserved Touch Face (RTF)
integer LM_TOUCH_NORMAL	= -66168300;

integer HUD_API_LOGIN = -47206000;
integer HUD_API_LOGOUT = -47206001;

list ClickFaces = [ 0, 1, 2, 3 ];	// All sides of the cottage door

integer DataRequested = FALSE;
integer DataReceived = FALSE;

rotation ClosedRot = ZERO_ROTATION;
rotation OpenRot = ZERO_ROTATION;
rotation ClosedToOpen = ZERO_ROTATION;

integer IsOpen = FALSE;
integer Selected = FALSE;

CalculateOpenRot() {
	OpenRot = ClosedRot * ClosedToOpen;
}
SetRotation() {
	if (IsOpen) {
		llSetLocalRot(OpenRot);
	}
	else {
		llSetLocalRot(ClosedRot);
	}
}

default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		ClosedToOpen = llEuler2Rot((vector)osGetNotecard(CONFIG_FILE) * DEG_TO_RAD);
		ClosedRot = llGetLocalRot();
		CalculateOpenRot();
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_LOADING_COMPLETE && !DataRequested) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, llList2CSV(ClickFaces), NULL_KEY);
			llSetTimerEvent(6.0 + llFrand(2.0));
			DataRequested = TRUE;
		}
		else if (Number == LM_EXTRA_DATA_GET) {
			llSetTimerEvent(0.0);
			DataReceived = TRUE;
			ClosedRot = (rotation)String;
			CalculateOpenRot();			
			SetRotation();
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			key TouchAv = Id;
			if (Selected) {	// If we're selected, we just report the click to the ML
				list TouchData = llParseStringKeepNulls(String, [ "|" ], []);	// Parse the data into a list of the four different parts				
				llMessageLinked(LINK_ROOT, LM_TOUCH_NORMAL, llList2CSV(llGetLinkNumber() + TouchData), TouchAv);
				return;
			}
			IsOpen = !IsOpen;
			SetRotation();
			if (IsOpen) llSetTimerEvent(10.0); // delay for auto close of door
		}
		else if (Number == LM_PRIM_SELECTED) {
			if ((integer)String == llGetLinkNumber()) {	// if it's our link number
				Selected = TRUE;
			}
		}
		else if (Number == LM_PRIM_DESELECTED) {
			if ((integer)String == llGetLinkNumber()) {	// if it's our link number
				Selected = FALSE;
			}
		}		
		else if (Number == LM_MOVED_ROTATED) {
			ClosedRot = llGetLocalRot();
			CalculateOpenRot();
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_SET, (string)ClosedRot, NULL_KEY);    // store data in ML
		}
	}
	timer() {
		if (!DataReceived) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, llList2CSV(ClickFaces), NULL_KEY);
		}
		else {
			if (IsOpen) {
				IsOpen = FALSE;
				SetRotation();
				llSetTimerEvent(0.0);
			}
		}
	}
}
// Prefab door v1.0