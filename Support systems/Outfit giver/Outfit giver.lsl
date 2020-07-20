// Outfit giver v0.5

// v0.5 - delegated deletion
// v0.4 - store outfit name in the description
// v0.3 - fix to NPC rotation
// v0.2 - bug fixes

vector NPC_REZ_OFFSET = <0.0, 0.0, 2.5>;	// relative position where NPC is rezzed

// Delegated deletion stuff
integer LM_DELEGATE_DELETION = -7044001;
integer LM_DELETE_RECEIVED = -7044002;

key RezzedNpc = NULL_KEY;

string OUTFIT_CARD_NAME = "Outfit";
integer MENU_CHANNEL = -24789110;
integer MenuListen;
string OldOutfitName;
key OwnerId;
integer DialogTimeout = 0;

RezNpc() {
	if (RezzedNpc != NULL_KEY) {
		osNpcRemove(RezzedNpc);
		RezzedNpc = NULL_KEY;
	}
	if (llGetInventoryType(OUTFIT_CARD_NAME) == INVENTORY_NOTECARD) {
		string OutfitName = GetOutfitName();
		if (OutfitName != "") {
			RezzedNpc = osNpcCreate("Outfit:", OutfitName, llGetPos() + NPC_REZ_OFFSET, OUTFIT_CARD_NAME);
			osNpcSetRot(RezzedNpc, llGetRot());
		}
	}
}
string GetOutfitName() {
	return llGetObjectDesc();
}
SetOutfitName(string OutfitName) {
	llSetObjectDesc(llStringTrim(OutfitName, STRING_TRIM));
	OldOutfitName = OutfitName;
}
Die() {
	while(1 == 1) {
		llDie();
	}
}
default {
	on_rez(integer Start) {
		RezzedNpc = NULL_KEY;
		RezNpc();
	}
	state_entry() {
		OwnerId = llGetOwner();
		RezzedNpc = NULL_KEY;
		RezNpc();
		DialogTimeout = 0;
		llSetTimerEvent(2.0);
	}
	touch_start(integer Count) {
		while(Count--) {
			key AvId = llDetectedKey(Count);
			if (AvId == OwnerId) {
				SetOutfitName("");
				osAgentSaveAppearance(AvId, OUTFIT_CARD_NAME);
				MenuListen = llListen(MENU_CHANNEL, "", AvId, "");
				llTextBox(AvId, "Enter name for outfit folder:", MENU_CHANNEL);
				DialogTimeout = llGetUnixTime() + 60;
			}
			else {
				string OutfitName = GetOutfitName();
				if (OutfitName == "") {
					llSetText("Sorry, not working", <1.0, 0.1, 0.1>, 1.0);
					llSleep(2.0);
					llSetText("", ZERO_VECTOR, 0.0);
				}
				else {
					llSetText("Giving items, please wait ...", <1.0, 0.2, 0.1>, 1.0);
					list ItemList;
					integer ItemCount = llGetInventoryNumber(INVENTORY_ALL);
					integer I;
					for(I = 0; I < ItemCount; I++) {
						string ItemName = llGetInventoryName(INVENTORY_ALL, I);
						integer ItemType = llGetInventoryType(ItemName);
						if (ItemType != INVENTORY_SCRIPT && ItemType != INVENTORY_NOTECARD) {
							ItemList += ItemName;
						}
					}
					llGiveInventoryList(AvId, OutfitName, ItemList);
					llSetText("Done", <0.2, 1.0, 0.1>, 1.0);
					llSleep(2.0);
					llSetText("", ZERO_VECTOR, 0.0);
				}
			}
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MENU_CHANNEL && Id == OwnerId) {
			DialogTimeout = 0;
			SetOutfitName(Message);
			string OutfitName = GetOutfitName();
			if (OutfitName == "") {
				llOwnerSay("Outfit name empty - disabled");
			}
			else {
				RezNpc();
				llDialog(Id, "Outfit saved as '" + OutfitName + "'", [ "OK" ], -9999999);	// dummy channel
				llListenRemove(MenuListen);
				MenuListen = 0;
			}
		}
	}
	timer() {
		llMessageLinked(LINK_SET, LM_DELEGATE_DELETION, "", NULL_KEY);
		string OutfitName = GetOutfitName();
		if (OutfitName != OldOutfitName) {
			OldOutfitName = OutfitName;
			RezNpc();
		}
		if (DialogTimeout) {
			if (llGetUnixTime() > DialogTimeout) {
				llDialog(OwnerId, "Timeout - outfit not saved", [ "OK" ], -9999999);	// dummy channel
				DialogTimeout = 0;
			}
		}
	}
	link_message(integer Sender, integer Number, string Message, key Id)	{
		if (Number == LM_DELETE_RECEIVED) {
			if (RezzedNpc != NULL_KEY) osNpcRemove(RezzedNpc);
			Die();
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_OWNER) llResetScript();
		if (Change & CHANGED_REGION_START) {
			RezzedNpc = NULL_KEY;
			RezNpc();
		}
		if (Change & CHANGED_INVENTORY) RezNpc();
	}
}
// Outfit giver v0.5