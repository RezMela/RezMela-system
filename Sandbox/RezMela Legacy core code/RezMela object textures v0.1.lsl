// NOTE: this script is no longer used (functionality is now in object picker)

// RezMela object textures v0.1

integer TP_LIST = -90194400;
integer TP_UPDATE = -90194401;

// This lists are always populated with inventory contents
list TextureNames;
list TextureUuids;
integer TextureCount;
integer UpdateDue;
integer PreRezPtr;
list PRE_REZ_SIDES = [ 0, 2, 3, 4, 5 ];
integer PRE_REZ_SIDE_COUNT = 5;

GetInventory() {
	TextureNames = [];
	TextureUuids = [];
	TextureCount = llGetInventoryNumber(INVENTORY_TEXTURE);
	integer I;
	for(I = 0; I < TextureCount; I++) {
		string Name = llGetInventoryName(INVENTORY_TEXTURE, I);
		TextureNames += Name;
		TextureUuids += llGetInventoryKey(Name);
	}
}
PreRez() {
	list Params = [];
	integer S;
	for(S = 0; S < PRE_REZ_SIDE_COUNT; S++) {
		Params += [ PRIM_TEXTURE, llList2Integer(PRE_REZ_SIDES, S), llList2String(TextureUuids, PreRezPtr), <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0 ];
		if (++PreRezPtr == TextureCount) PreRezPtr = 0;
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
}
default
{
	on_rez(integer Start) { llResetScript(); }
	state_entry() {
		UpdateDue = -1;
		GetInventory();
		PreRezPtr = 0;
		llSetTimerEvent(1.0);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Sender == LINK_ROOT) {
			if (Number == TP_LIST) {
				integer P;
				for(P = 0; P < TextureCount; P++) {
					llMessageLinked(LINK_ROOT, TP_LIST, llList2String(TextureNames, P), llList2Key(TextureUuids, P));
				}
			}
		}
		llMessageLinked(LINK_ROOT, TP_LIST, "", NULL_KEY);
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			// We use a timer so that if someone drops a lot of textures into this prim, this event
			// won't keep firing needlessly
			UpdateDue = 2;
		}
	}
	timer() {
		if (UpdateDue > 0) UpdateDue--;
		else if (UpdateDue == 0) {
			GetInventory();
			llMessageLinked(LINK_ROOT, TP_UPDATE, "", NULL_KEY);
			UpdateDue = -1;
		}
		PreRez();
	}
}
// RezMela object textures v0.1