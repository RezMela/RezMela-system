// RM -> ML converter

list WorldObjects;
list Icons;
list Textures;
list OldCards;
list NewCards;
integer Count;

default {
	on_rez(integer p) { llResetScript(); }
	state_entry() {
		llOwnerSay("Checking contents ...");
		integer Error = FALSE;
		WorldObjects = [];
		Icons = [];
		integer ObjectsCount = llGetInventoryNumber(INVENTORY_OBJECT);
		integer O;
		for (O = 0; O < ObjectsCount; O++) {
			string ObjectName = llGetInventoryName(INVENTORY_OBJECT, O);
			string Ext = llGetSubString(ObjectName, -1, -1);
			string Base = llGetSubString(ObjectName, 0, -2);
			if (Ext == "W") WorldObjects += Base;
			else if (Ext == "I") Icons += Base;
			else {
				llOwnerSay("Invalid object: " + ObjectName);
				Error = TRUE;
			}
		}
		integer WoCount = llGetListLength(WorldObjects);
		integer IcCount = llGetListLength(Icons);
		integer W;
		for (W = 0; W < WoCount; W++) {
			string Base = llList2String(WorldObjects, W);
			integer Ip = llListFindList(Icons, [ Base ]);
			if (Ip == -1) { llOwnerSay("WO " + Base + "W has no icon"); Error = TRUE; }
		}
		integer I;
		for (I = 0; I < IcCount; I++) {
			string Base = llList2String(Icons, I);
			integer Wp = llListFindList(WorldObjects, [ Base ]);
			if (Wp == -1) { llOwnerSay("Icon " + Base + "I has no WO"); Error = TRUE; }
		}
		WorldObjects = llListSort(WorldObjects, 1, TRUE);
		Icons = llListSort(Icons, 1, TRUE);
		if (llList2CSV(WorldObjects) != llList2CSV(Icons)) {
			llOwnerSay("WOs and Icons mismatch");
			Error = TRUE;
		}
		for (W = 0; W < WoCount; W++) {
			string Base = llList2String(WorldObjects, W);
			string TextureName = Base + "T";
			if (llGetInventoryType(TextureName) != INVENTORY_TEXTURE) {
				llOwnerSay("WO " + Base + "W has no texture");
				Error = TRUE;
			}
			else {
				key TK = llGetInventoryKey(TextureName);
				Textures += [ Base, TK ];
			}
		}
		for (W = 0; W < WoCount; W++) {
			string Base = llList2String(WorldObjects, W);
			string CardName = Base + "C";
			if (llGetInventoryType(CardName) == INVENTORY_NOTECARD) {
				string OldCard = osGetNotecard(CardName);
				OldCards += [ Base, OldCard ];
			}
			else {
				OldCards += [ Base, "// Configuration for object '" + Base + "'\n" ];
			}
		}
		if (Error) {
			llOwnerSay("Error(s) found, quitting");
			return;
		}
		Count = llGetListLength(WorldObjects);
		llOwnerSay("Contents OK (" + (string)Count + ") objects");
		state Convert;
	}
}
state Convert {
	on_rez(integer p) { llResetScript(); }
	state_entry() {
		llOwnerSay("Converting ...");
		integer N;
		NewCards = [];
		for (N = 0; N < Count; N++) {
			integer P = N * 2;
			string Base = llList2String(OldCards, P);
			string Contents = llList2String(OldCards, P + 1);
			integer T = llListFindList(Textures, [ Base  ]);
			if (T == -1) { llOwnerSay("Lost a texture! Object: " + Base); return; }
			string Texture = (string)llList2Key(Textures, T + 1);
			Contents +=
				"ShortDesc = \"" + Base + "\"\n" +
				"//LongDesc = \n" +
				"Thumbnail = " + Texture + "\n" +
				"//Preview = \n";
			NewCards += [ Base, Contents ];
		}
		state DeleteOld;
	}
}
state DeleteOld {
	on_rez(integer p) { llResetScript(); }
	state_entry() {
		llOwnerSay("Deleting textures and old cards ...");
		integer C = llGetInventoryNumber(INVENTORY_TEXTURE);
		while (C--) {
			string  Name = llGetInventoryName(INVENTORY_TEXTURE, 0);
			llRemoveInventory(Name);
		}
		C = llGetInventoryNumber(INVENTORY_NOTECARD);
		while (C--) {
			string  Name = llGetInventoryName(INVENTORY_NOTECARD, 0);
			llRemoveInventory(Name);
		}
		state WriteNew;
	}
}
state WriteNew {
	on_rez(integer p) { llResetScript(); }
	state_entry() {
		llOwnerSay("Writing new cards ...");
		string ObjectsCard = "[Converted]\n";
		integer N;
		for (N = 0; N < Count; N++) {
			integer P = N * 2;
			string Base = llList2String(NewCards, P);
			string Contents = llList2String(NewCards, P + 1);
			string CardName = Base + "C";
			osMakeNotecard(CardName, Contents);
			ObjectsCard += Base + "\n";
		}
		osMakeNotecard("!Objects", ObjectsCard);
		llOwnerSay("Done - converter script removed.");
		llRemoveInventory(llGetScriptName());
	}
}