// RezMela water level v0.1

float DEFAULT_LEVEL = 20.0;
float MINIMUM_LEVEL = 10.0;
float MAXIMUM_LEVEL = 40.0;
string WATER_PRIM_NAME = "waterlevel";

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
		osSetRegionWaterHeight(DEFAULT_LEVEL);
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == LM_DELEGATED_CLICK) {
			list L = llParseStringKeepNulls(Message, [ "|" ], [ "" ]);
			string PrimName = llList2String(L, 0);
			if (PrimName == WATER_PRIM_NAME) {
				vector TouchST = (vector)llList2String(L, 3);
				key AvId = Id;
				float Level = MINIMUM_LEVEL + ((MAXIMUM_LEVEL - MINIMUM_LEVEL) * TouchST.y);
				llOwnerSay(llKey2Name(AvId) + " sets water height to " + (string)llFloor(Level) + "m");
				osSetRegionWaterHeight(Level);
			}
		}
		else if (Number == LM_RESET_EVERTHING) {
			osSetRegionWaterHeight(DEFAULT_LEVEL);
		}
	}
}
// RezMela water level v0.1