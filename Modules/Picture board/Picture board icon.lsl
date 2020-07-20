// Picture board icon v0.1

// Commands for RezMela icon script
integer IC_COMMAND = 1020;
integer IC_MENU = 1021;

// Commands for label board icon
integer PBI_DISPLAY = -1924200;

key WorldObjectUuid;
integer WO_COMMAND = 3007;

integer ThisPrim;
integer PrimMenu;
vector MenuPrimScale;
vector MenuPrimPos;

string Url;

float IconX;
float IconZ;
integer TextureX;
integer TextureY;

Display() {
	// Calculate the prim size to accomodate the canvas
	vector ThisPrimScale = llGetScale();
	ThisPrimScale.y = IconX;	// it is actually the Y of the prim, but we use X in the name to correspond with world object
	ThisPrimScale.z = IconZ;
	// Resize prim on Y axis
	list Params = [ PRIM_SIZE, ThisPrimScale ];
	// Position menu prim
	if (PrimMenu > -1) {
		vector ThisPrimPos = llGetLocalPos();
		MenuPrimPos.x = ThisPrimPos.x - ((ThisPrimScale.z - MenuPrimScale.y) / 2.0);	// up/down
		MenuPrimPos.y = ThisPrimPos.y + ((ThisPrimScale.y - MenuPrimScale.x) / 2.0);	// left/right
		//		llOwnerSay("\nThisPrimScale: " + (string)ThisPrimScale +
		//			"\nThisPrimPos: " + (string)ThisPrimPos +
		//			"\nMenuPrimScale: " + (string)MenuPrimScale +
		//			"\nMenuPrimPos: " + (string)MenuPrimPos
		//			);
		
		Params += [
			PRIM_LINK_TARGET, PrimMenu,
			PRIM_POS_LOCAL, MenuPrimPos,
			PRIM_POS_LOCAL, MenuPrimPos
				];
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
	if (Url == "") {
		llSetTexture(TEXTURE_BLANK, ALL_SIDES);
		return;
	}	
	string CommandList = "";
	CommandList = osMovePen(CommandList, 0, 0);
	CommandList = osDrawImage(CommandList, TextureX, TextureY, Url);
	string Dimensions = "width:" + (string)TextureX + ",height:" + (string)TextureY;
	osSetDynamicTextureData("", "vector", CommandList, Dimensions, 0);
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
	list L = llGetLinkPrimitiveParams(PrimMenu, [ PRIM_SIZE, PRIM_POS_LOCAL ]);
	MenuPrimScale = llList2Vector(L, 0);
	MenuPrimPos = llList2Vector(L, 1);
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
			if (Command == PBI_DISPLAY) {
				IconX = (float)llList2String(Parts, 1);
				IconZ = (float)llList2String(Parts, 2);
				TextureX = (integer)llList2String(Parts, 3);
				TextureY = (integer)llList2String(Parts, 4);
				Url = llList2String(Parts, 5);
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
// Picture board icon v0.1