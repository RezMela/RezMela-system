// List module contents for conversion

default {
	state_entry() {
		string ModuleId = "";
		string NotecardString = osGetNotecard("!Library config");
		list Lines = llParseStringKeepNulls(NotecardString, [ "\n" ], []);
		integer Len = llGetListLength(Lines);
		integer L;
		for (L = 0; L < Len; L++) {
			string Line = llList2String(Lines, L);
			list Parts = llParseStringKeepNulls(Line, [ "=" ], []);
			string Name = llStringTrim(llList2String(Parts, 0), STRING_TRIM);
			string Value = llStringTrim(llList2String(Parts, 1), STRING_TRIM);
			if (llToLower(Name) == "moduleid") ModuleId = Value;
		}
		if (ModuleId == "") {
			llOwnerSay("Can't find module ID in Library config card!");
		}
		else {
			NotecardString = osGetNotecard("!Objects");
			string Output = "";
			Lines = llParseStringKeepNulls(NotecardString, [ "\n" ], []);
			Len = llGetListLength(Lines);
			for (L = 0; L < Len; L++) {
				string Line = llList2String(Lines, L);
				Line = llStringTrim(Line, STRING_TRIM);
				if (Line != "" && llGetSubString(Line, 0, 0) != "[") {
					Output += Line + "|" + ModuleId + "\n";
				}
			}
			llOwnerSay("Paste into module conversion data:\n" + Output);
		}
		llRemoveInventory(llGetScriptName());
	}
}