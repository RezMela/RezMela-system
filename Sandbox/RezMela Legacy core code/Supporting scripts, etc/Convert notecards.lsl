
// Return FALSE if "Name" is not a loadable notecard
integer NotecardNameValid(string Name) {
	string LineOne = osGetNotecardLine(Name, 0);
	return (llGetSubString(LineOne, 0, 3) == "RMSF");
}

default {
	on_rez(integer Param) {
		llResetScript();
	}
	state_entry() {
		llSay(0, "Click to convert notecards");
	}
	touch_start(integer total_number) {
		integer Num = llGetInventoryNumber(INVENTORY_NOTECARD);
		integer I;
		for(I = 0; I < Num; I++) {
			string Name = llGetInventoryName(INVENTORY_NOTECARD, I);
			if (NotecardNameValid(Name)) {
				llSay(0, Name + " already converted");
			}
			else {
				llSay(0, "Converting " + Name + " ...");
				list Records = [ "RMSF,1" ];
				integer Len = osGetNumberOfNotecardLines(Name);
				integer LineNum;
				for (LineNum = 0; LineNum < Len; LineNum++) {
					string Data =  osGetNotecardLine(Name, LineNum);
					if (llStringTrim(Data, STRING_TRIM) != "") {
						list L = llParseStringKeepNulls(Data, [ "%" ], []);
						if (llGetListLength(L) != 4) {
							llSay(0, "Invalid line: " + Data);
						}
						string OName = llList2String(L, 0);
						if (llGetSubString(OName, 0, 1) == "c_") OName = llGetSubString(OName, 2, -1);
						vector Pos = llList2Vector(L, 1);
						rotation Rot = llList2Rot(L, 2);
						// ignore PIN
						Pos = Pos + <6, 6, 0>;
						Pos *= 40.0;
						Pos.z += 21.0;	// land height
						vector vRot = llRot2Euler(Rot) * RAD_TO_DEG;
						Records += llDumpList2String([ OName, Pos, vRot ], "|");
					}
				}
				llRemoveInventory(Name);
				osMakeNotecard(Name, Records);
				llSay(0, "done");
			}
		}
	}
}