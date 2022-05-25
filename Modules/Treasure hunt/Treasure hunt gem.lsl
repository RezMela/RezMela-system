// Treasure hunt gem v1.2

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

// v1.2 basically, a rewrite

integer TREAS_START_GAME = -861461200;
integer TREAS_END_GAME = -861461201;

string MESSAGE_IDENTIFIER = "&RMQ&";
integer MESSAGE_ID_LENGTH = 4; // 1 less than actual length (0 start!)

key CrownGiverId = NULL_KEY;

vector OriginalSize;
integer IsVisible = TRUE;
integer GameInProgress = FALSE;

SetVisible(integer Visible) {
	float Alpha = 1.0;
	vector NewSize = OriginalSize;
	if (!Visible) {
		Alpha = 0.0;
		NewSize = <0.001, 0.001, 0.001>;
	}
	llSetScale(NewSize);
	llSetAlpha(Alpha, ALL_SIDES);
	IsVisible = Visible;
}
// Format and send osMessageObject message
SendMessage(key Uuid, string Command, string Parameters) {
	MessageObject(Uuid, MESSAGE_IDENTIFIER + Command + Parameters);
}
// Wrapper for osMessageObject() that checks to see if destination exists
MessageObject(key Uuid, string Text) {
	if (ObjectExists(Uuid)) {
		osMessageObject(Uuid, Text);
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
default {
	on_rez(integer Start) {
		llResetScript();
	}
	state_entry() {
		OriginalSize = llGetScale();
		SetVisible(TRUE);
		llPassTouches(TRUE);
	}
	touch_start(integer Count) {
		if (!IsVisible) return;
		key AvId = llDetectedKey(0);
		if (GameInProgress) {
			if (CrownGiverId == NULL_KEY) {
				llOwnerSay("ERROR - Can't find crown giver!");
				return;
			}
			SendMessage(CrownGiverId, "C", (string)AvId);	// message to crown giver saying we've been clicked
		}
		// Next part removed because it was triggered by someone selecting or deselecting this object in the ML.
		// So, if there's no game in progress, nothing happens here.
		//		else {
		//			llRegionSayTo(AvId, 0, "Sorry, no game currently in progress");
		//		}
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == TREAS_START_GAME) {
			CrownGiverId = Id;
			SetVisible(TRUE);
			GameInProgress = TRUE;
		}
		else if (Number == TREAS_END_GAME) {
			SetVisible(TRUE);
			GameInProgress = FALSE;
		}
	}
	dataserver(key From, string Data) {
		if (llGetSubString(Data, 0, MESSAGE_ID_LENGTH) == MESSAGE_IDENTIFIER) {
			Data = llGetSubString(Data, MESSAGE_ID_LENGTH + 1, -1); // discard id string
			string Command = llGetSubString(Data, 0, 0); // command is first character of Data
			string Params = llGetSubString(Data, 1, -1); // rest is parameters
			if (Command == "D") { // message from crown to tell us to go invisible
				if (llGetNumberOfPrims() > 1) {
					SetVisible(FALSE);
				}

			}
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) {
			SetVisible(TRUE);
			GameInProgress = FALSE;
		}
	}
}
// Treasure hunt gem v1.2