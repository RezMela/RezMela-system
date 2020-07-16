// Set StickPoint v0.1

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

string NiceVector(vector V) {
	return ("<" + NiceFloat(V.x) + ", " + NiceFloat(V.y) + ", " + NiceFloat(V.z) + ">") ;
}
// Makes a nice string from a float - eg "0.1" instead of "0.100000", or "0.2" instead of "0.199999".
string NiceFloat(float F) {
	float X = 0.0001;
	if (F < 0.0) X = -X;
	string S = (string)(F + X);
	integer P = llSubStringIndex(S, ".");
	S = llGetSubString(S, 0, P + 3);
	while (llGetSubString(S, -1, -1) == "0" && llGetSubString(S, -2, -2) != ".")
		S = llGetSubString(S, 0, -2);
	return(S);
}

default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llOwnerSay("Click object to get StickPoint data. Script must be removed manually when you've finished.");
	}
	touch_start(integer Count) {
		integer Face = llDetectedTouchFace(0);
		vector RegionPos = llDetectedTouchPos(0);
		vector LocalPos = (RegionPos - llGetPos()) / llGetRot();
		llOwnerSay("Data to copy:\nStickPoint = " + (string)Face + ": " + NiceVector(LocalPos));
	}
}
// Set StickPoint v0.1