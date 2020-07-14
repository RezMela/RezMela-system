// ML object shrinker for icons

// Shrinks the object to 1/40th of its size, and self-deletes script

default {
	state_entry() {
		float Factor = 0.025;	// 1/40
		integer Start = 0;
		integer Stop = 1;
		integer PrimCount = llGetNumberOfPrims();
		if (PrimCount > 1) {
			Start = 1;
			Stop = PrimCount + 1;
		}
		list Params = [];
		integer LinkNum;
		for (LinkNum = Start; LinkNum < Stop; LinkNum++) {
			list P = llGetLinkPrimitiveParams(LinkNum, [ PRIM_SIZE, PRIM_POS_LOCAL ]);
			vector Size = llList2Vector(P, 0);
			vector Pos = llList2Vector(P, 1);
			Size *= Factor;
			Pos *= Factor;
			Params += [ PRIM_LINK_TARGET, LinkNum, PRIM_SIZE, Size, PRIM_POS_LOCAL, Pos ];
		}
		llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
		llRemoveInventory(llGetScriptName());
	}
}
