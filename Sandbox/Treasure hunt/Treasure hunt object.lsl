// Treasure hunt object v1.1

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

// v1.1 better comms with server
// v1.0 version change only
// v0.3 add passtouches
// v0.2 make work in linkset
// v0.21 Prevent Gem from being unlinked and destroyed

integer CHAT_CHANNEL = -19308880;

integer GEM_HIDE = -16726170;


key Avid;


default {
	on_rez(integer Start) {
		llResetScript();
	}
	state_entry() {
		llSetAlpha(1.0, ALL_SIDES);
		llPassTouches(TRUE);
	}
	touch_start(integer Count) {
		llSetAlpha(1.0, ALL_SIDES);
		Avid = llDetectedKey(0);
		llRegionSayTo(Avid, CHAT_CHANNEL, llGetObjectName());
	}
	dataserver(key From, string Data) {
		if (Data == "G") {
			if (llGetNumberOfPrims() > 1) {
				llMessageLinked(LINK_SET, GEM_HIDE, "", NULL_KEY);
			}

		}
	}

}
// Treasure hunt object v1.1