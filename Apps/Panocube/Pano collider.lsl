// Pano collider v1.0.1

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


// The description of the prim should contain a vector and a float, separated by
// ";" ("|" isn't available in object descriptions). The vector is the local position
// (relative to root) of the TP point, and the float is the scale of random +/-
// horizontal offsets (in metres), applied to both X and Y. The random part is to reduce the
// chance of collisions when >1 avatars use it.

// v1.0.1 - add script pin

integer SCRIPT_PIN = -19318100;

vector DestinationLocal;
float Random;

default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetRemoteScriptAccessPin(SCRIPT_PIN);
		list Parts = llParseStringKeepNulls(llGetObjectDesc(), [ ";" ], []);
		DestinationLocal = (vector)llList2String(Parts, 0);
		Random = (float)llList2String(Parts, 1);
	}
	collision_start(integer Count) {
		vector RootPos = llGetRootPosition();
		rotation RootRot = llGetRootRotation();
		vector DestinationRegion = RootPos + (DestinationLocal * RootRot);
		DestinationRegion.x += (llFrand(Random * 2.0) - Random);
		DestinationRegion.y += (llFrand(Random * 2.0) - Random);
		while (Count--) {
			key AvId = llDetectedKey(Count);
			osTeleportAgent(AvId, DestinationRegion, ZERO_VECTOR);
		}
	}
}
// Pano collider v1.0.1