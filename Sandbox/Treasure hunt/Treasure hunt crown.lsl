
integer CHAT_CHANNEL = -19308880;

list Collected;
integer Remaining;
integer PrimCount;

string GetLinkDesc(integer LinkNum) {
	return llList2String(llGetLinkPrimitiveParams(LinkNum, [ PRIM_DESC ]), 0);
}
default
{
	on_rez(integer Start) { llResetScript(); }
	state_entry() {
		llListen(CHAT_CHANNEL, "", NULL_KEY, "");
		Collected = [];
		Remaining = 0;
		PrimCount = llGetNumberOfPrims();
		integer P;
		for(P = 2; P <= PrimCount; P++) {
			string Desc = GetLinkDesc(P);
			if (Desc == "gem") {	// if it's a child prim with a description of "gem", it's a jewel
				Remaining++;		// count how many there are
				llSetLinkAlpha(P, 0.0, ALL_SIDES);	// make invisible
				llSetLinkPrimitiveParamsFast(P, [ PRIM_GLOW, ALL_SIDES, 0.0 ]);
			}
		}
	}
	listen(integer Channel, string FromName, key Id, string Text) {
		if (llListFindList(Collected, [ Text ]) > -1) return;		// ignore if they already have it
		integer Found = FALSE;
		integer P;
		for(P = 2; P <= PrimCount && !Found; P++) {
			string Name = llGetLinkName(P);
			if (Name == Text) {
				Collected += Text;
				llSetLinkAlpha(P, 1.0, ALL_SIDES);
				llSetLinkPrimitiveParamsFast(P, [ PRIM_GLOW, ALL_SIDES, 0.1 ]);
				Remaining--;
				osMessageObject(Id, "G");
				Found = TRUE;
			}
		}
		if (!Remaining) {
			llOwnerSay("You have all the jewels!");
		}
	}
}