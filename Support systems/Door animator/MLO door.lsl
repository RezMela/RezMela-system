// MLO door v1.0

// DEEPSEMAPHORE CONFIDENTIAL
// __
//
//  [2018] - [2028] DEEPSEMAPHORE LLC
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of DEEPSEMAPHORE LLC and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to DEEPSEMAPHORE LLC
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from DEEPSEMAPHORE LLC. For more information, or requests for code inspection,
// or modification, contact support@rezmela.com

// This script enables an MLO to act as an animated door. MLO must have hinge
// end as centre of rotation. Door config card should have a vector on line 1 that
// represents the degree of movement in degrees - eg <0, 0, 270> for a 90-degree
// rotation. Line 2 contains the speed of TargetOmega movement, eg 90.

string CONFIG_FILE = "Door config";

// Link message numbers, sent/rec'd by ML main script
integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_MOVED_ROTATED = -405560;
integer LM_PRIM_SELECTED = -405500;        // A prim has been selected
integer LM_PRIM_DESELECTED = -405501;    // A prim has been deselected
integer LM_RESERVED_TOUCH_FACE = -44088510;        // Reserved Touch Face (RTF)
integer LM_TOUCH_NORMAL    = -66168300;

//integer HUD_API_LOGIN = -47206000;
//integer HUD_API_LOGOUT = -47206001;

list ClickFaces = [ 0, 1, 2, 3 ];    // All sides of the cottage door

integer DataRequested = FALSE;
integer DataReceived = FALSE;

rotation ClosedRot = ZERO_ROTATION;
rotation OpenRot = ZERO_ROTATION;
rotation ClosedToOpen = ZERO_ROTATION;
float Speed = 0.0;

integer Moving = FALSE;
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
		llTargetOmega(ZERO_VECTOR, 0.0, 0.0) ;
		if (llGetInventoryType(CONFIG_FILE) != INVENTORY_NOTECARD) {
			llOwnerSay("Missing config card: '" + CONFIG_FILE + "'");
			state Hang;
		}
		list NotecardLines = llParseStringKeepNulls(osGetNotecard(CONFIG_FILE), [ "\n" ], []);
		vector ClosedToOpenEulerDeg = (vector)llList2String(NotecardLines, 0);
		Speed = (float)llList2String(NotecardLines, 1) * DEG_TO_RAD;
		ClosedToOpen = llEuler2Rot(ClosedToOpenEulerDeg * DEG_TO_RAD);
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
			if (Selected) {    // If we're selected, we just report the click to the ML
				list TouchData = llParseStringKeepNulls(String, [ "|" ], []);    // Parse the data into a list of the four different parts
				llMessageLinked(LINK_ROOT, LM_TOUCH_NORMAL, llList2CSV(llGetLinkNumber() + TouchData), TouchAv);
				return;
			}
			if (!Moving) { // ignore clicks while door is in motion
				if (IsOpen) {    // we're open, so closing
					llTargetOmega(<0.0, 0.0, 1.0>, Speed, 1.0);
					IsOpen = FALSE;
				}
				else {            // we're closed, so opening
					llTargetOmega(<0.0, 0.0, 1.0>, -Speed, 1.0);
					IsOpen = TRUE;
				}
				Moving = TRUE;
				llSetTimerEvent(1.0) ;
			}
		}
		else if (Number == LM_PRIM_SELECTED) {
			if ((integer)String == llGetLinkNumber()) {    // if it's our link number
				Selected = TRUE;
			}
		}
		else if (Number == LM_PRIM_DESELECTED) {
			if ((integer)String == llGetLinkNumber()) {    // if it's our link number
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
		else if (Moving) {
			llSetTimerEvent(0.0);
			llTargetOmega(ZERO_VECTOR, 0.0, 0.0);
			SetRotation();
			Moving = FALSE;
			if (IsOpen) llSetTimerEvent(10.0); // delay for auto close of door
		}
		else {	// auto-close
			llTargetOmega(<0.0, 0.0, 1.0>, Speed, 1.0);
			IsOpen = FALSE;
			Moving = TRUE;
			llSetTimerEvent(1.0);
		}
	}
	collision_start(integer Count) {
		if (!IsOpen && !Moving) {
			// open immediately on collision (no TargetOmega)
			IsOpen = TRUE;
			SetRotation();
			llSetTimerEvent(10.0); // delay for auto close of door
		}
    }   	
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llResetScript();
	}
}
// MLO door v1.0