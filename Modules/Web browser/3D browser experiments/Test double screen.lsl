

integer PageWidth;
integer PageHeight;
string Url1;
string Url2;
integer Face1;
integer Face2;

Display(integer Face, string Url) {
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
	on_rez(integer p) { llResetScript(); }
	state_entry() {
		PageWidth = 910;
		PageHeight = 512;
		Face1 = 1;
		Face2 = 2;
		Url1 = "https://www.reddit.com/";
		Url2 = "";
		Display(Face1, Url1);
		llClearPrimMedia(Face2);
		llOwnerSay("Ready - click toolbar to reset");
		llSetTimerEvent(1.0);
	}
	timer() {
		string NewUrl1 = llList2String(llGetPrimMediaParams(Face1, [ PRIM_MEDIA_CURRENT_URL ]), 0);
		if (NewUrl1 != Url1) {
			//			llClearPrimMedia(Face1);
			//			llClearPrimMedia(Face2);
			llOwnerSay("LHS navigation detected: " + NewUrl1);
			Display(Face1, Url1);
			Url2 = NewUrl1;
			Display(Face2, Url2);
			return;
		}
		string NewUrl2 = llList2String(llGetPrimMediaParams(Face2, [ PRIM_MEDIA_CURRENT_URL ]), 0);
		if (NewUrl2 != Url2) {
			llOwnerSay("RHS navigation detected: " + NewUrl2);
			if (Url1 != Url2) {
				Url1 = Url2;
				Display(Face1, Url1);
			}
		}
	}
	touch_start(integer n) {
		llResetScript();
	}
}
