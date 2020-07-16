
integer NUMBER_OF_OBJECTS = 50;
string SCENE_FILE_NAME = "Auto";

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
	float XPos = 2.0;
	float YPos = 0.0;
	integer Object;
	for (Object = 0; Object < NUMBER_OF_OBJECTS; Object++) {
		XPos += 1.0;
		if (!(Object % 50)) {
			XPos = 2.0;
			YPos += 1.0;
		}
		string ExtraData = (string)(Object + 1) + "^Noto Sans^96^Black^Yellow^0";
		Lines += [
			"{",
			"    Section: Linked",
			"    Name: World map",
			"    InternalId: " + (string)(9 + Object),
			"    Pos: <" + (string)XPos + "," + (string)YPos + ",0.703>",
			"    Rot: <0.0,0.0,90.0>",
			"    Size: <0.675,0.2,1.674>",
			"    SizeFactor: 0.5",
			"    CpPos: <0.584,-0.07,-0.133>",
			"    CpNormal: <0.0,0.0,1.0>",
			"    CpBinormal: <0.0,1.0,0.0>",
			"    ExtraData: " + llStringToBase64(ExtraData),
			"}",
			""
				];
	}
	Lines += "ignorehash";
	osMakeNotecard(SCENE_FILE_NAME, Lines);
	llOwnerSay("Scene file '" + SCENE_FILE_NAME + "' created (" + (string)NUMBER_OF_OBJECTS + " objects).");
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