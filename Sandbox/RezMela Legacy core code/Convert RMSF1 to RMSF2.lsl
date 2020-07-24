// Convert RMSF1 to RMSF2

// Just drop in notecards prim

Convert(string CardName) {
	list OldLines = llParseStringKeepNulls(osGetNotecard(CardName), [ "\n" ], []);
	integer Len = llGetListLength(OldLines);
	string IdString = llList2String(OldLines, 0);
	if (IdString == "RMSF,1") {
		list NewLines = [ "RMSF,2" ];
		integer N;
		for (N = 1; N < Len; N++) {
			string Line = llList2String(OldLines, N);
			if (llGetSubString(Line, 0, 0) == "!") {
				NewLines += Line;
			}
			else {
				list Parts = llParseStringKeepNulls(Line, [ "|" ], []);
				if (llGetListLength(Parts) > 2) {
					Parts = llListInsertList(Parts, [ "", "", "" ], 3);
					NewLines += llDumpList2String(Parts, "|");
				}
			}
		}
		llRemoveInventory(CardName);
		osMakeNotecard(CardName, NewLines);
		llOwnerSay(CardName + " - converted OK");
	}
	else if (IdString == "RMSF,2") {
		llOwnerSay(CardName + " - already converted");
	}
	else {
		llOwnerSay(CardName + " - IGNORED!");
	}
}
default {
	on_rez(integer n) { llResetScript();}
	state_entry() {
		integer Total = llGetInventoryNumber(INVENTORY_NOTECARD);
		llOwnerSay("Checking " + (string)Total + " script(s)");
		integer N;
		list Cards = [];
		for(N = 0; N < Total; N++) {
			Cards += llGetInventoryName(INVENTORY_NOTECARD, N);
		}
		for(N = 0; N < Total; N++) {
			Convert(llList2String(Cards, N));
		}
		llOwnerSay("Completed - conversion script removed");
		llRemoveInventory(llGetScriptName());
	}
}