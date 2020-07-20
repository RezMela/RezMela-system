// Data bar icon v0.1

// Commands for RezMela icon script
integer IC_COMMAND = 1020;
integer IC_MENU = 1021;

// Commands for data bar icon
integer DBI_DISPLAY = -1925200;

key WorldObjectUuid;
integer WO_COMMAND = 3007;

integer Value = 100;
vector Color = <250, 250, 250>;

integer ThisPrim;
integer PrimMenu;

Display() {
	list Params = [];
	Params += [ PRIM_COLOR, 2, Color / 255.0, 1.0 ];
	float Slice = (float)Value / 100.0;
	if (Slice < 0.0001) Slice = 0.01;
	Params += [ PRIM_SLICE, <0.0, Slice, 0.0> ];
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
}
ReadPrims() {
	ThisPrim = llGetLinkNumber();
	integer PrimCount = llGetNumberOfPrims();
	PrimMenu = -1;
	integer P;
	for (P = 2; P <= PrimCount; P++) {
		string Name = llGetLinkName(P);
		if (llToLower(Name) == "menu") PrimMenu = P;
	}
}
MessageWorldObject(string Text) {
	if (WorldObjectUuid != NULL_KEY && llKey2Name(WorldObjectUuid) != "") {
		osMessageObject(WorldObjectUuid, Text);		// no need to wrap it in WO_COMMAND because it goes directly to client prim
	}
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTexture(TEXTURE_BLANK, ALL_SIDES);
		ReadPrims();
		WorldObjectUuid = NULL_KEY;
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == IC_COMMAND) {
			WorldObjectUuid = Id;
			list Parts = llCSV2List(Message);
			integer Command = (integer)llList2String(Parts, 0);
			if (Command == DBI_DISPLAY) {
				Color = (vector)llList2String(Parts, 1);
				Value = (integer)llList2String(Parts, 2);
				Display();
			}
			else {
				llOwnerSay("Invalid icon command: " + (string)Command);
			}
		}
		else if (Number == IC_MENU) {	// Someone has clicked on the menu icon
			string sAvId = (string)Id;
			MessageWorldObject(llList2CSV([
				"menu",
				sAvId
					]));
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) llResetScript();
		if (Change & CHANGED_REGION_START) Display();
	}
}
// Data bar icon v0.1