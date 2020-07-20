
key reqid;

default {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {

	}
	touch_start(integer Count) {
		llOwnerSay("Sending request");
		string Name = llKey2Name(llDetectedKey(0));
		Name = llEscapeURL(Name);
		string Url = "http://www.google.com";
		string Call = "http://handylow.com/php/RecordUrl.php?gid=KI&uname=" + Name + "&url=" + Url;
		reqid = llHTTPRequest(Call, [ HTTP_METHOD, "GET" ], "");
	}
	http_response(key Id, integer Status, list Metadata, string Body) {
//		if (Id == reqid)
//			llOwnerSay("Back from send script [" + (string)Status + "/" + llList2CSV(Metadata) + "] : \n" + Body);
	}
}