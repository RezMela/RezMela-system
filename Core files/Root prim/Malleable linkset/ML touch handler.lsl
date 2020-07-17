// ML touch handler 1.1.0

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

// v1.1.0 - update version, add copyright text
// v0.3 - remove old HUD stuff

integer LM_TOUCH_NORMAL	= -66168300;
integer LM_TOUCH_ALTERNATE = -66168301;
integer LM_TOUCH_SHUFFLE = -66168302;

// External Touch Handling messages - for scripts in child prims to be able to interpret their own short-click touches
integer ETH_LOCK = -44912700;		// Send to central script to bypass touch handling
integer ETH_UNLOCK = -44912701;		// Send to central script to return to normal touch handling
integer ETH_TOUCHED = -44912702;	// Sent to external script to notify of touch
integer ETH_PROCESS = -44912703;	// Sent to central script to mimic touch

list EthPrims;	// Prims with External Touch Handling (prim UUIDs)

// We also keep track of which prims are selected
integer LM_PRIM_SELECTED = -405500;        // A prim has been selected (sent to other scripts)
integer LM_PRIM_DESELECTED = -405501;    // A prim has been deselected

list SelectedPrims;	// Prim UUIDs, not link numbers

float TIMER_FREQUENCY = 0.5;    // Frequence of timer ticks

// Mouses down - record of which users currently have the moue button down
// Strided list consisting of [ key <Av ID>, integer <link number> ]
// Av ID must be unique
list MousesDown = [];
integer MD_AVID = 0;        // positions of fields in strided list
integer MD_LINKNUM = 1;        // if these positions change, make sure AddMouseDown() changes too
integer MD_PARAMS = 2;
integer MD_STRIDE = 3;        // list stride length

// Process normal touch
NormalTouch(key AvId, integer LinkNum, string Parameters) {
	key PrimUuid = GetPrimUuid(LinkNum);
	if (EthLocked(PrimUuid) && !IsSelected(PrimUuid))
		llMessageLinked(LinkNum, ETH_TOUCHED, Parameters, AvId);
	else
		llMessageLinked(LINK_THIS, LM_TOUCH_NORMAL, llList2CSV([ LinkNum ] + Parameters), AvId);
}
// Process alternate touch
AlternateTouch(key AvId, integer LinkNum) {
	llMessageLinked(LINK_THIS, LM_TOUCH_ALTERNATE, (string)LinkNum, AvId);
}
// Add entry to MouseDown table
AddMouseDown(key AvId, integer LinkNum, string Params) {
	integer Ptr = FindMouseDownById(AvId) ;    // check if they're already in the list
	if (Ptr > -1) DeleteMouseDownByPtr(Ptr);        // if they're already recorded for some reason, remove entry
	MousesDown += [ AvId, LinkNum, Params ];
}
// Delete entry from MouseDown table - by avatar ID, and by pointer to table
DeleteMouseDownById(key AvId) {
	DeleteMouseDownByPtr(llListFindList(MousesDown, [ AvId ]));
}
DeleteMouseDownByPtr(integer Ptr) {
	MousesDown = llDeleteSubList(MousesDown, Ptr, Ptr + MD_STRIDE - 1);
}
integer FindMouseDownById(key AvId) {
	return llListFindList(MousesDown, [ AvId ]);
}
// Reference function of the same name on the main ML script - this is a copy, de-genericised
ShuffleLinkNums(integer MinLinkNum, integer Difference) {
	integer Length = llGetListLength(MousesDown);
	integer P;
	for(P = 0; P < Length; P += MD_STRIDE) {
		integer LinkNumberPtr = P + MD_LINKNUM;
		integer LinkNum = llList2Integer(MousesDown, LinkNumberPtr);    // get current value
		if (LinkNum >= MinLinkNum) {
			LinkNum += Difference;
			MousesDown = llListReplaceList(MousesDown, [ LinkNum ], LinkNumberPtr, LinkNumberPtr);    // replace link number in table (in situ)
		}
	}
}
// Is prim ETH-locked?
integer EthLocked(key PrimUuid) {
	return (llListFindList(EthPrims, [ PrimUuid ]) > -1);
}
// Is prim selected?
integer IsSelected(key PrimUuid) {
	return (llListFindList(SelectedPrims, [ PrimUuid ]) > -1);
}
// Returns UUID of prim
key GetPrimUuid(integer LinkNum) {
	return llGetLinkKey(LinkNum);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		MousesDown = [];
	}
	touch_start(integer Count) {
		while(Count--) {
			integer LinkNum = llDetectedLinkNumber(Count);
			key AvId = llDetectedKey(Count);
			string Params = llList2CSV([
				llDetectedTouchFace(Count),
				llDetectedTouchPos(Count),
				llDetectedTouchNormal(Count),
				llDetectedTouchBinormal(Count),
				llDetectedTouchST(Count),
				llDetectedTouchUV(Count)
					]);
			AddMouseDown(AvId, LinkNum, Params);
			llSetTimerEvent(TIMER_FREQUENCY);
		}
	}
	touch_end(integer Count) {
		while(Count--) {
			key AvId = llDetectedKey(Count);
			integer LinkNum = llDetectedLinkNumber(Count);
			integer MPtr = FindMouseDownById(AvId);
			// If there's no record of the mouse-down event, ignore the mouse-up
			// This is normal if they've done a long-click, or if they moused down
			// on a different object, land, sky etc.
			if (MPtr == -1) return;
			if (llList2Integer(MousesDown, MPtr + MD_LINKNUM) != LinkNum) {     // if it's a different prim than the mousedown,
				DeleteMouseDownByPtr(MPtr);        // just ignore the whole click (down and up)
				return;
			}
			string sParams = llList2String(MousesDown, MPtr + MD_PARAMS);
			NormalTouch(AvId, LinkNum, sParams);
			// Remove the entry from MousesDown list
			DeleteMouseDownByPtr(MPtr);
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		integer MousesDownCount = llGetListLength(MousesDown);
		if (MousesDownCount) {    // if we have waiting mousedowns
			integer MPtr;        // pointer to strides in MousesDown table
			for(MPtr = 0; MPtr < MousesDownCount ; MPtr += MD_STRIDE) {
				key AvId = llList2Key(MousesDown, MPtr + MD_AVID);
				integer LinkNum = llList2Integer(MousesDown, MPtr + MD_LINKNUM);
				AlternateTouch(AvId, LinkNum);
			}
			MousesDown = [];	// we can clear it because we've processed all the entries
		}
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_TOUCH_SHUFFLE) {
			list L = llCSV2List(String);
			ShuffleLinkNums(llList2Integer(L, 0), llList2Integer(L, 1));
		}
		else if (Number == ETH_LOCK) {
			key PrimUuid = GetPrimUuid(Sender);
			if (llListFindList(EthPrims, [ PrimUuid ]) == -1) {	// if it's not already in the list
				EthPrims += PrimUuid;	// add it
			}
		}
		else if (Number == ETH_UNLOCK) {
			key PrimUuid = GetPrimUuid(Sender);
			integer P = llListFindList(EthPrims, [ PrimUuid ]);
			if (P > -1) EthPrims = llDeleteSubList(EthPrims, P, P);
		}
		else if (Number == ETH_PROCESS) {
			integer Type = (integer)String;	/// %%%%
		}
		else if (Number == LM_PRIM_SELECTED) {
			integer LinkNum = (integer)String;	// ML main script passes us link number in string portion
			key PrimUuid = GetPrimUuid(LinkNum);
			if (llListFindList(SelectedPrims, [ PrimUuid ]) == -1) SelectedPrims += PrimUuid;
		}
		else if (Number == LM_PRIM_DESELECTED) {
			integer LinkNum = (integer)String;	// ML main script passes us link number in string portion
			key PrimUuid = GetPrimUuid(LinkNum);
			integer P = llListFindList(SelectedPrims, [ PrimUuid ]);
			if (P > -1) SelectedPrims = llDeleteSubList(SelectedPrims, P, P);
		}
	}
}
// ML touch handler 1.1.0