// ML always zero rot v1.2.0

integer LM_MOVED_ROTATED = -405560;

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

// v1.2.0 - fix timing issue
// v1.1 - use local rotation, not region rotation

SetRot() {
	llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_ROT_LOCAL, ZERO_ROTATION ]);
}
default {
	on_rez(integer Start) {
		SetRot();
	}
	state_entry() {
		SetRot();
	}
	link_message(integer Sender, integer Num, string Str, key Id) {
		if (Sender == 1 && Num == LM_MOVED_ROTATED) {
			SetRot();
		}
	}
}
// ML always zero rot v1.2.0