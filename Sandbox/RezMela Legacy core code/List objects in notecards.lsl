default {
	state_entry() {
		list Lines = [];
		integer NL = llGetInventoryNumber(INVENTORY_NOTECARD);
		integer N;
		for (N = 0; N < NL; N++) {
			string Notecard = llGetInventoryName(INVENTORY_NOTECARD, N);
			Lines += llParseString2List(osGetNotecard(Notecard), [ "\n" ], []);
		}
		list Objects = [];
		integer LN = llGetListLength(Lines);
		integer L;
		for (L = 0; L < LN; L++) {
			string Line = llList2String(Lines, L);
			list Parts = llParseStringKeepNulls(Line, [ "|" ], []);
			string Object = llList2String(Parts, 0);
			Object = "\"" + Object + "\",";
			if (llListFindList(Objects, [ Object ]) == -1) Objects += Object;
		}
		Objects = llListSort(Objects, 1, TRUE);
		string S = llDumpList2String(Objects, "\n");
		llOwnerSay("\n" + S);
	}
}