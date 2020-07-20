
integer Visible = TRUE;

SetPrims() {
	list Params;
	integer L = llGetNumberOfPrims();
	integer P;
	for(P = 2; P <= L; P++) {
		string Name = llGetLinkName(P);
		if (Name == "Waypoint") {
			Params += [ PRIM_LINK_TARGET, P, PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE ];
			float Alpha = 0.0;
			if (Visible) Alpha = 1.0;
			llSetLinkAlpha(P, Alpha, ALL_SIDES);
		}
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
}

default {
	state_entry() {
		Visible = TRUE;
		SetPrims();
	}
	touch_start(integer Count) {
		Visible = !Visible;
		SetPrims();
	}
}