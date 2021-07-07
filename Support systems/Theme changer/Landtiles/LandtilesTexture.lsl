// LandTilesTexture v1.0.0

list TextureSets = [];


ReadNotecard() {
}
ClearData() {
}
ShowOnOffState(integer IsOn) {
	llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_FULLBRIGHT, 0, IsOn ]);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		state Off;		
	}
}
state Off {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		ShowOnOffState(FALSE);
		ClearData();
	}
	touch_start(integer x) { /// %%%
		state On;
	}
}
state On {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		ReadNotecard();
		ShowOnOffState(TRUE);
	}
	touch_start(integer x) { /// %%%
		state Off;
	}
}
// LandTilesTexture v1.0.0