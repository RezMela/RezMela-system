
string API_KEY = "TW5cyzzloNjidX_j-3lEDEcyNfcUxA3YQ1OOKoU0BBEX";
string GRANT_TYPE = "urn:ibm:params:oauth:grant-type:apikey";
string TOKEN_SERVICE_URL = "https://iam.cloud.ibm.com/identity/token";
string ASSISTANT_URL = "https://api.us-east.assistant.watson.cloud.ibm.com/instances/eb1695b8-b9f2-44d7-b228-09d877634aba/v2/assistants/9fdff7bd-de84-4468-bec6-e5fe6073cc2f/sessions";
string ASSISTANT_VERSION = "2020-09-24";

key TokenRequestId;
key SessionRequestId;
key QuestionRequestId = "";

string Token = "";
string SessionId = "";

integer Listener = 0;

key UserId = NULL_KEY;

SetStatus() {
	if (UserId != NULL_KEY) {
		llSetText("Talking with " + llKey2Name(UserId), <1.0, 1.0, 0.4>, 1.0);
		llSetColor(<0.4, 1.0, 0.4>, 0);
	}
	else {
		llSetText("Click to talk with Watson", <1.0, 1.0, 0.4>, 1.0);
		llSetColor(<1.0, 1.0, 0.4>, 0);
	}
}
GetBearerToken() {
	llSay(0, "Setting up, one moment ...");
	string RequestURL = TOKEN_SERVICE_URL + "?grant_type=" + GRANT_TYPE + "&apikey=" + API_KEY;
	TokenRequestId = llHTTPRequest(RequestURL, [
		HTTP_METHOD, "POST",
		HTTP_MIMETYPE, "application/x-www-form-urlencoded",
		HTTP_BODY_MAXLENGTH, 2048
			], "");
}
GetSessionId() {
	string BearerToken;
	BearerToken = "Bearer " + Token;
	SessionRequestId = llHTTPRequest(ASSISTANT_URL + "?version=" + ASSISTANT_VERSION, [
		HTTP_METHOD,"POST",
		HTTP_CUSTOM_HEADER,"Authorization", BearerToken,
		HTTP_MIMETYPE,"application/json",
		HTTP_BODY_MAXLENGTH,2048
			],  "");
}
string ParseTokenResponse(string Body) {
	list Parts = GrabJsonParts(Body);
	integer Ptr = llListFindList(Parts, [ "access_token" ]);
	if (Ptr > -1) {
		return llList2String(Parts, Ptr + 1);
	}
	else {
		llOwnerSay("Unable to parse token response: " + llGetSubString(Body, 0, 40));
		return "";
	}
}
string ParseSessionResponse(string Body) {
	list Parts = GrabJsonParts(Body);
	integer Ptr = llListFindList(Parts, [ "session_id" ]);
	if (Ptr > -1) {
		return llList2String(Parts, Ptr + 1);
	}
	else {
		llOwnerSay("Unable to parse session id response: " + llGetSubString(Body, 0, 40));
		return "";
	}
}
string ParseQuestionReply(string Body) {
	list Parts = GrabJsonParts(Body);
	integer Ptr = llListFindList(Parts, [ "text" ]);
	if (Ptr > -1) {
		return llList2String(Parts, Ptr + 2);	// + 2 because ... well, that's how the data is
	}
	else {
		llOwnerSay("Unable to parse question reply: " + llGetSubString(Body, 0, 40));
		return "";
	}
}
AskWatson(string Question) {
	string MessageBody = "{\"input\":{\"text\": \"" + Question + "\",\"options\":{\"return_context\":true}}}";
	string BearerToken;
	BearerToken = "Bearer " + Token;
	QuestionRequestId = llHTTPRequest(ASSISTANT_URL + "/" + SessionId + "/message/?version=" + ASSISTANT_VERSION, [
		HTTP_METHOD,"POST",
		HTTP_CUSTOM_HEADER,"Authorization", BearerToken,
		HTTP_MIMETYPE,"application/json",
		HTTP_BODY_MAXLENGTH,2048
			],  MessageBody);
}
// Very crude extraction of elements from JSON string
list GrabJsonParts(string JsonString) {
	return llParseString2List(JsonString, [ "{", "}", ":", "\"", "," ], []);
}
default
{
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		//GetBearerToken();
		SetStatus();
	}
	http_response(key RequestID, integer Status, list Metadata, string Body) {
		if (RequestID == TokenRequestId) { // Reply to token request
			Token = ParseTokenResponse(Body);
			if (Token == "") return; // Token request failed
			GetSessionId();
		}
		else if (RequestID == SessionRequestId) {
			SessionId = ParseSessionResponse(Body);
			if (SessionId == "") return; // Session ID request failed
			llSay(0, "I'm ready.");
			llSetTimerEvent(3300.0); // 55m
		}
		else if (RequestID = QuestionRequestId) {
			string Reply = ParseQuestionReply(Body);
			llSay(0, Reply);
		}
	}
	touch_start(integer Count) {
		key ClickId = llDetectedKey(0);
		if (ClickId == UserId) { // clicked to stop
			llListenRemove(Listener);
			Listener = 0;
			UserId = NULL_KEY;
		}
		else {
			if (Token == "") {
				GetBearerToken();
				return;
			}
			AskWatson("Hello");
			UserId = ClickId;
			if (Listener > 0) {
				llListenRemove(Listener);
				Listener = 0;
			}
			Listener = llListen(0, "", UserId, "");
		}
		SetStatus();
	}
	listen(integer Channel, string Name, key Id, string Text) {
		if (Channel == 0 && Id == UserId) {
			if (Token == "") GetBearerToken();
			AskWatson(Text);
		}
	}
	timer() {
		Token = "";
		UserId = NULL_KEY;
		if (Listener > 0) {
			llListenRemove(Listener);
			Listener = 0;
		}
		SetStatus();
		llSetTimerEvent(0.0);
	}
}