integer LM = -2812798278;

string Notecard = "Modules";

list Modules;

default {
	state_entry() {
		if (llGetNumberOfPrims() == 1) return;	// unlinked
		llOwnerSay("Ignore error messages!");
		if (llGetInventoryType(Notecard) == INVENTORY_NOTECARD) llRemoveInventory(Notecard);
		Modules = [];
		integer PrimCount = llGetNumberOfPrims();
		integer P;
		for (P = 2; P <= PrimCount; P++) {
			string Name = llGetLinkName(P);
			if (llGetSubString(Name, 0, 5) == "&Lib: ") {
				integer C = llSubStringIndex(Name, "~");
				if (C > -1) C--;
				Name = llStringTrim(llGetSubString(Name, 6, C), STRING_TRIM);
				Modules += Name;
			}
		}
		Modules = llListSort(Modules, 1, TRUE);
		llMessageLinked(LINK_THIS, LM, "", NULL_KEY);
	}
	link_message(integer Sender, integer Number, string Text, key Id)	{
		if (Number == LM) {
			osMakeNotecard(Notecard, Modules);
			llRemoveInventory(llGetScriptName());
		}
	}
}