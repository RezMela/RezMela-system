// Moveable prim 1.1.1

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

// v1.1.1 - fix bug that left timer running (no need for a timer any more)
// v1.1.0 - take llGetNumberofPrims out of changed event
// v0.3 - add in "do not delete" feature

integer PrimCount;

integer MP_DO_NOT_DELETE 	= -818442500;
integer MP_DELETE_OBJECT	= -818442501;

integer DeleteWhenUnlinked;

default
{
	on_rez(integer Param) {
		llSetRemoteScriptAccessPin(8000);	// in case we need it
		PrimCount = llGetNumberOfPrims();
		DeleteWhenUnlinked = TRUE;
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number== MP_DO_NOT_DELETE){
			DeleteWhenUnlinked = FALSE;
		}
	}
	changed(integer Change)	{
		if (Change & CHANGED_LINK) {
			integer NewPrimCount = llGetNumberOfPrims();
			if (PrimCount > 1 && NewPrimCount == 1) { // we were linked and now we're not
				if (DeleteWhenUnlinked) {
					llDie();
					llSetTimerEvent(10.0 + llFrand(10.0));	// just in case there's a problem with llDie (again)
				}
				else {
					llMessageLinked(LINK_THIS, MP_DELETE_OBJECT, "", NULL_KEY);	// tell the client script to kill the object
				}
			}
			PrimCount = NewPrimCount;
		}
	}
	timer() {
		llDie();
	}
}
// Moveable prim 1.1.1