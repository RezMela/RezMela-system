
integer IsOn;

Display() {
	vector Repeats = <0.5, 0.5, 0.0>;
	vector Offsets = <0.0, 0.25 + (0.5 * (float)IsOn), 0.0>;
	llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEXTURE, ALL_SIDES, "ffdc555a-e2c1-486e-b574-de564b4d1122", Repeats, Offsets, 0.0 ]);
	llSetObjectDesc((string)IsOn);
}
default {
	on_rez(integer P) { llResetScript(); }		
	state_entry() {
		IsOn = FALSE;
		Display();
	}
	touch_start(integer Count) {
		IsOn = !IsOn;
		Display();
	}
}