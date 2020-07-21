
integer NUMBER_OF_OBJECTS = 144;
string SCENE_FILE_NAME = "AAA";

CreateScene() {
	list Lines = [
		"{",
		"    Section: General",
		"    Version: 3",
		"    SavedBy: " + llGetScriptName(),
		"    NextID: 10",
		"    Objects: " + (string)NUMBER_OF_OBJECTS,
		"}",
		""
		];
	integer Sentences = osGetNumberOfNotecardLines("Sentences");
	float XPos = 2.0;
	float ZPos = 4.0;
	integer Object;
	for (Object = 0; Object < NUMBER_OF_OBJECTS; Object++) {
		XPos += 2.0;
		if (!(Object % 12)) {
			XPos = 2.0;
			ZPos += 2.0;
		}
		string Text = osGetNotecardLine("Sentences", (integer)llFrand(Sentences));
		string ExtraData = Text + "^Noto Sans^96^Black^White^0";
		Lines += [
			"{",
			"    Section: Linked",
			"    Name: Text display C",
			"    InternalId: " + (string)(9 + Object),
			"    Pos: <" + (string)XPos + ",0.0," + (string)ZPos + ">",
			"    Rot: <0.0,0.0,0.0>",
			"    Size: <2.0, 0.02, 2.0>",
			"    SizeFactor: 1.0",
			"    CpPos: <0.584,-0.07,-0.133>",
			"    CpNormal: <0.0,0.0,1.0>",
			"    CpBinormal: <0.0,1.0,0.0>",
			"    ExtraData: " + llStringToBase64(ExtraData),
			"}",
			""
				];
	}
	osMakeNotecard(SCENE_FILE_NAME, Lines);
	llOwnerSay("Scene file '" + SCENE_FILE_NAME + "' created.");
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llOwnerSay("Click to create scene file");
	}
	touch_start(integer Count) {
		if (llGetInventoryType(SCENE_FILE_NAME) == INVENTORY_NOTECARD) llRemoveInventory(SCENE_FILE_NAME);
		CreateScene();
	}
}
