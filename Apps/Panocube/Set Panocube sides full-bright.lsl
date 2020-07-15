
// Note that MOAP surfaces are hardcoded, and pano prim name, but not link number

integer PanoPrim = -1;

list MoapFaces = [ 2, 3, 4, 5, 6, 7 ];

SetFullBright(integer LinkNum, integer Face, integer IsFullBright) {
	llSetLinkPrimitiveParamsFast(LinkNum, [ PRIM_FULLBRIGHT, Face, IsFullBright ]);
}

default {
	state_entry() {
		integer P;
		for (P = 2; P < llGetNumberOfPrims(); P++) {
			if (llGetLinkName(P) == "pano") PanoPrim = P;
		}
		if (P == -1) {
			llOwnerSay("Can't find pano prim");
			state Die;
		}
		SetFullBright(LINK_SET, ALL_SIDES, FALSE);		
		integer F;
		for (F = 0; F < llGetListLength(MoapFaces); F++) {
			integer S = llList2Integer(MoapFaces, F);
			SetFullBright(PanoPrim, S, TRUE);
		}
		state Die;
	}
}
state Die {
	state_entry() {
		llRemoveInventory(llGetScriptName());
	}
}