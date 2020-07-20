// ML bookmark comms server v0.1

string PHP_URL = "http://handylow.com/php/";
string PHP_LOGIN_SCRIPT = "RecordObject.php";

string Url;
key AvId;
key UrlRequestId;
key LoginRequestId;

string GridId;

SendLoginData(integer IsLogin) {
	string pUid = "";
	string pUname = "";
	if (IsLogin) {
		pUid = (string)AvId;
		pUname = llKey2Name(AvId);
	}
	string PHPCall = PHP_URL + PHP_LOGIN_SCRIPT +
		"/?gid=" + GridId +
		"&oid=" + (string)llGetKey() +
		"&ouri=" + Url +
		"&uname=" + pUname +
		"&uid=" +pUid
		;
	LoginRequestId = llHTTPRequest(PHPCall, [], "");
}
SetText(string Text) {
	llSetText(Text, <1, 1, 1>, 1.0);
}
default {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		GridId = "KI";
		Url = "";
		state Idle;
	}
}
state Idle {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		if (Url != "") {
			llReleaseURL(Url);
			Url = "";
		}
		SetText("Idle");
		SendLoginData(FALSE);
	}
	http_response(key Id, integer Status, list Metadata, string Body) {
		if (Id == LoginRequestId) {
			llSetTimerEvent(0.0);
			llOwnerSay("Logout returns: " + Body);
		}
		else {
			llOwnerSay("Unknown HTTP message received while idle");
		}
	}	
	touch_start(integer Count) {
		AvId = llDetectedKey(0);
		state Open;
	}
}
state Open {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		SetText("Requesting URL ...");
		UrlRequestId = llRequestURL();
		llSetTimerEvent(0.0);
	}
	http_request(key Id, string Method, string Body) {
		llOwnerSay("http_request rec'd:\n" + Method + ": <" + Body + ">\nfrom: " + (string)Id + " [" + llKey2Name(Id) + "]");
		if (Id == UrlRequestId) {
			if (Method == URL_REQUEST_DENIED) {
				llOwnerSay("Error during URL request:\n" + Body);
			}
			else if (Method == URL_REQUEST_GRANTED) {
				Url = Body;
				SetText(Url);
				llOwnerSay("URL:\n" + Url);
				SendLoginData(TRUE);
				llSetTimerEvent(20.0);
			}
		}
		else if (Method == "GET") {
			llHTTPResponse(Id, 200, "GET method data:\n" + Body + "\n");
		}
		else {
			llOwnerSay("Unknown data received by server script: " + Method + "/" + Body);
		}
	}
	http_response(key Id, integer Status, list Metadata, string Body) {
		llOwnerSay("Response: " + (string)Status + "/" + llList2CSV(Metadata) + ": " + Body);
		if (Id == LoginRequestId) {
			llSetTimerEvent(0.0);
			llOwnerSay("Login returns: " + Body);
		}
	}
	touch_start(integer Count) {
		state Idle;
	}
	changed(integer Change) {
		// Same conditions as would log the user out of the ML cause us to go idle too
		if (Change & (CHANGED_REGION | CHANGED_REGION_START | CHANGED_TELEPORT))
			state Idle;
	}
	timer() {
		llSetTimerEvent(0.0);
		llOwnerSay("Login to web server timed out");
	}
}
// ML bookmark comms server v0.1