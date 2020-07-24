// Sun position v0.1

// Link message commands
integer LM_FILE_CANCEL = 40500;
integer LM_FILE_SAVE_START = 40501;
integer LM_FILE_SAVE_DATA = 40502;
integer LM_FILE_SAVE_END = 40503;
integer LM_FILE_CLEAR_SCENE = 40504;
integer LM_FILE_LOAD_START = 40505;
integer LM_FILE_LOAD_DATA = 40506;
integer LM_FILE_LOAD_END = 40507;
integer LM_FILE_DELETE = 40508;
integer LM_RESET_EVERTHING = 40509;
integer LM_DELEGATED_CLICK = 40510;



default {
	state_entry() {
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == LM_DELEGATED_CLICK) {
			list L = llParseStringKeepNulls(Message, [ "|" ], [ "" ]);
			string PrimName = llList2String(L, 0);
			if (llGetSubString(PrimName, 0, 3) == "sun ") {
				string PositionName = llGetSubString(PrimName, 4, -1);
				float Hour = 0.0;
				if (PositionName == "dawn") Hour = DAWN;
				else if (PositionName == "noon") Hour = NOON;
				else if (PositionName == "dusk") Hour = DUSK;
				else if (PositionName == "midnight") Hour = MIDNIGHT;
				osSetRegionSunSettings(FALSE, TRUE, Hour);
			}
		}
	}
}
// Sun position v0.1