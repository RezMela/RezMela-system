
string HUD_MESSAGE_GET_VERSION = "V";

string Output;

GetVersions() {
	llOwnerSay("Looking for HUD versions ...");
	list AvatarList = osGetAvatarList();
	if (AvatarList == []) {
		llOwnerSay("No avatars in the region (apart from you)");
	}
	else {
		// format of AvatarList is [ UUID, Position, Name ]
		integer A;
		integer L = llGetListLength(AvatarList);
		for (A = 0; A < L; A += 3) {
			key AvId = llList2Key(AvatarList, A);
			osMessageAttachments(AvId, HUD_MESSAGE_GET_VERSION, [ ATTACH_HUD_TOP_LEFT ], 0);
		}
	}
	llSetTimerEvent(2.0);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Output = "\n\nHUD versions\n";
		if (llGetAttached()) GetVersions();
	}
	touch_start(integer Count) {
		GetVersions();
	}
	dataserver(key Id, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "/" ], []);
		if (llList2String(Parts, 0) != "HUDV") return;
		string Version = llList2String(Parts, 1);
		key AvId = llGetOwnerKey(Id);
		string AvName = llKey2Name(AvId);
		Output += "\n" + AvName + ": " + Version;
		llSetTimerEvent(2.0);
	}
	timer() {
		Output += "\n";
		llSetTimerEvent(0.0);
		llOwnerSay(Output);
		llOwnerSay("Done.");
		if (llGetAttached()) llRequestPermissions(llGetOwner(), PERMISSION_ATTACH );
	}
    run_time_permissions(integer Perms) {
        if (Perms & PERMISSION_ATTACH) llDetachFromAvatar( );
    }	
}