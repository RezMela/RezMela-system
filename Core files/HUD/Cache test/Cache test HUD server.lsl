
integer NUMBER_OF_PAGES = 30;

list Keys = [];

string GenAv = "";

key MakeTexture(string Text) {
	string Date = llGetSubString(llGetTimestamp(), 0, 9);
	string Time = llGetSubString(llGetTimestamp(), 11, 18) + " UTC";
	string CommandList = "";
	CommandList = osSetFontName(CommandList, "Arial");
	CommandList = osSetFontSize(CommandList, 24);
	CommandList = osSetPenColor(CommandList, "black");
	CommandList = osMovePen(CommandList, 20, 40);
	CommandList = osDrawText(CommandList, Text);
	CommandList = osMovePen(CommandList, 60, 120);
	CommandList = osDrawText(CommandList, Date);
	CommandList = osMovePen(CommandList, 60, 170);
	CommandList = osDrawText(CommandList, Time);
	CommandList = osMovePen(CommandList, 20, 250);
	CommandList = osDrawText(CommandList, "Generated: " + GenAv);
	osSetDynamicTextureDataBlendFace("", "vector",
		CommandList, "width:512,height:512",
		FALSE, 2, 0, 255, 5);
	return llGetTexture(5);
}

default {
	on_rez(integer p) {
		llResetScript();
	}
	state_entry() {
	}
	touch_start(integer n) {
		key AvId = llDetectedKey(0);
		if (llDetectedLinkNumber(0) == 2 || GenAv == "") {
			llSay(0, "Generating new textures ...");
			Keys = [];
			GenAv = llKey2Name(AvId);
			integer i;
			for (i = 0; i < NUMBER_OF_PAGES; i++) {
				key K = MakeTexture("Page " + (string)(i + 1) + " of " + (string)NUMBER_OF_PAGES);
				Keys += K;
			}
		}
		llSay(0, "Sending " + (string)NUMBER_OF_PAGES + " textures to " + llKey2Name(AvId) + " ...");
		osMessageAttachments(AvId, llList2CSV(Keys), [ ATTACH_HUD_TOP_RIGHT ], 0);
	}
}