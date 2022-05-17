
// ML util textbox test. Put in child prim, with ML util in root prim
// Click this prim to get the textbox

integer UTIL_TEXTBOX_CALL		= -21044500;
integer UTIL_TEXTBOX_RESPONSE	= -21044501;

default {
	state_entry() {
	}
	touch_start(integer Count) {
		string Tag = "T" + (string)(llFloor(llFrand(100.0)) + 1);
		string Message = "Enter a value for tag: " + Tag;
		llMessageLinked(LINK_ROOT, UTIL_TEXTBOX_CALL, Tag + "|" + Message, llDetectedKey(0));
	}
	link_message(integer Sender, integer Num, string Text, key Id) {
		if (Num == UTIL_TEXTBOX_RESPONSE) {
			list L = llParseStringKeepNulls(Text, [ "|" ], []);
			string Tag = llList2String(L, 0);
			string Response = llList2String(L, 1);
			llRegionSayTo(Id, 0, "Response for tag '" + Tag + "' is: " + Response);
		}
	}
}