
vector RezPos = <-3, 0, 0>;	// relative position of 1st spawned browser
vector RezOffset = <0, 0, 2>;	// offset for subsequent spawned browsers

integer OBJECT_PIN = -487348743;

integer PageWidth;
integer PageHeight;
string Url;
integer Face;
list BrowserIds;
list BrowserUrls;
list WaitingUrls;
list WaitingChildren;
key ParentId;

Display() {
	llClearPrimMedia(Face);
	//llSetTexture(LOADING_TEXTURE, FACE_MEDIA);
	list PrimMediaParams =  [
		PRIM_MEDIA_AUTO_PLAY, TRUE,
		PRIM_MEDIA_AUTO_SCALE, FALSE,
		PRIM_MEDIA_AUTO_ZOOM, FALSE,
		PRIM_MEDIA_WIDTH_PIXELS, PageWidth,
		PRIM_MEDIA_HEIGHT_PIXELS, PageHeight,
		PRIM_MEDIA_CONTROLS, PRIM_MEDIA_CONTROLS_MINI,
		PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_ANYONE,
		PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_ANYONE,
		PRIM_MEDIA_CURRENT_URL, Url,
		PRIM_MEDIA_HOME_URL, Url
			];
	integer Status = llSetPrimMediaParams(Face, PrimMediaParams);
	if (Status) { // STATUS_OK is not defined in OpenSim, but it's 0
		llOwnerSay("WARNING: llSetPrimMediaParams() returned status " + (string)Status);
	}
}
default {
	on_rez(integer P) {
		llOwnerSay("rez default: " + (string)P);
		if (P == 0) {	// manually rezzed
			llOwnerSay("I'm manually rezzed");	///%%%
			llSetObjectDesc("");
			llResetScript();
		}
		else if (P == 1) {	// rezzed but no script update, so store parent, report in and and hang
			llOwnerSay("I'm a child awaiting an updated script");	///%%%
			ParentId = osGetRezzingObject();
			llSetObjectDesc((string)ParentId);
			state Hang;
		}
		else if (P == 2) {	// script update
			llOwnerSay("I'm a child who's received its script");
			ParentId = (key)llGetObjectDesc();
			state GetData;
		}
	}
	state_entry() {
		llOwnerSay("default state entry");
		Url = "https://en.wikipedia.org/wiki/Tilberi";
		state Normal;
	}
}
state Normal {
	on_rez(integer P) {	llResetScript();	}
	state_entry() {
		llSetRemoteScriptAccessPin(OBJECT_PIN);
		PageWidth = 910;
		PageHeight = 512;
		Face = 1;
		Display();
		BrowserIds = [];
		BrowserUrls = [];
		WaitingUrls = [];
		llSetTimerEvent(1.0);
	}
	timer() {
		string NewUrl = llList2String(llGetPrimMediaParams(Face, [ PRIM_MEDIA_CURRENT_URL ]), 0);
		if (NewUrl != Url) {
			llOwnerSay("Navigation detected: " + NewUrl);
			integer ChildCount = llGetListLength(BrowserIds);
			vector SpawnPos = llGetPos() + (RezPos + (RezOffset * ChildCount)) * llGetRot();
			string ObjectName = llGetInventoryName(INVENTORY_OBJECT, 0);
			llRezObject(ObjectName, SpawnPos, ZERO_VECTOR, llGetRot(), 1);
			WaitingUrls += Url;
			Url = NewUrl;
		}
	}
	object_rez(key Id) {
		llSleep(5.0);
		llOwnerSay("Sending script to child");
		llRemoteLoadScriptPin(Id, llGetScriptName(), OBJECT_PIN, TRUE, 2);
		llOwnerSay("Script sent");
		WaitingChildren += Id;
	}
	dataserver(key Id, string Data) {
		if (Data == "data") {
			if (llGetListLength(WaitingUrls) == 0) {
				llOwnerSay("No urls waiting!");
				return;
			}
			llOwnerSay("data request received from child");		///%%%
			// pop child url from waiting list (FIFO processing)
			string ChildUrl = llList2String(WaitingUrls, 0);	// get first url
			osMessageObject(Id, ChildUrl);
			llOwnerSay("data sent to child: " + (string)Id);		///%%%
			BrowserIds += Id;
			BrowserUrls += ChildUrl;
			WaitingUrls = llDeleteSubList(WaitingUrls, 0, 0);	// remove first entry
			// delete from waiting children queue
			integer W = llListFindList(WaitingChildren, [ Id ]);
			if (W == -1) {
				llOwnerSay("can't find waiting child!");
				return;
			}
			WaitingChildren = llDeleteSubList(WaitingChildren, W, W);
			llOwnerSay("deleted: " + (string)Id + " from " + llList2CSV(WaitingChildren));
		}
		else {
			llOwnerSay("Invalid data: '" + Data + "'");
		}
	}
	touch_start(integer n) {
		llResetScript();
	}
}
state GetData {
	// State to handle being spawned and getting data from parent
	on_rez(integer P) { llResetScript();	}
	state_entry() {
		osMessageObject(ParentId, "data");
		llOwnerSay("data requested by child");		///%%%
	}
	dataserver(key Id, string Data) {
		if (Id == ParentId) {
			Url = Data;
			llOwnerSay("data received");	///%%%
			state Normal;
		}
		else {
			llOwnerSay("Message from unknown source: " + llKey2Name(Id));
		}
	}
}
state Hang {
	on_rez(integer P) { llResetScript();	}
	state_entry() {
	}
}
