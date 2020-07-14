
integer NUMBER_OF_OBJECTS = 484;
string SCENE_FILE_NAME = "Auto";

list Colours = [
		"White", <1.0, 1.0, 1.0>,
		"Red", <1.0, 0.0, 0.0>,
		"Green", <0.0, 1.0, 0.0>,
		"Blue", <0.0, 0.0, 1.0>,
		"Yellow", <1.0, 1.0, 0.0>,
		"Cyan", <0.0, 1.0, 1.0>,
		"Magenta", <1.0, 0.0, 1.0>,
		"Orange", <1.0, 0.647, 0.0>,
		"Black", <0.0, 0.0, 0.0>,
		"Gray", <0.4, 0.4, 0.5>,
		"Off-white", <0.9, 0.9, 0.9>,
		"Gold", <1.0, 0.843, 0.0>,
		"Silver", <0.753, 0.753, 0.753>,
		"Purple", <0.502, 0.0, 0.502>,
		"Brown", <0.502, 0.251, 0.0>,
		"Khaki", <0.765, 0.690, 0.569>,
		"Cream", <1.0, 0.992, 0.816>,
		"Tan", <0.824, 0.706, 0.549>,
		"Olive", <0.502, 0.502, 0.0>,
		"Maroon", <0.502, 0.0, 0.0>,
		"Navy", <0.0, 0.0, 0.502>,
		"Aquamarine", <0.498, 1.0, 0.831>,
		"Turquoise", <0.0, 1.0, 0.937>,
		"Lime", <0.749, 1.0, 0.0>,
		"Teal", <0.0, 0.502, 0.502>,
		"Indigo", <0.435, 0.0, 1.0>,
		"Violet", <0.561, 0.0, 1.0>,
		"Fuchsia", <0.976, 0.518, 0.937>,
		"Ivory", <1.0, 1.0, 0.941>,
		"Plum", <0.557, 0.271, 0.522>
		];

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
	integer Colour = 0;
	float XPos = 2.0;
	float YPos = 0.0;
	float ZPos = 0.8;
	integer Object;
	for (Object = 0; Object < NUMBER_OF_OBJECTS; Object++) {
		XPos += 1.0;
		if (!(Object % 22)) {
			XPos = 2.0;
			ZPos += 1.0;
		}
		string ExtraData = llList2String(Colours, Colour * 2);
		Colour++;
		if (Colour >= 21) Colour = 0;
		Lines += [
			"{",
			"    Section: Linked",
			"    Name: Colorable block",
			"    InternalId: " + (string)(9 + Object),
			"    Pos: <" + (string)XPos + "," + (string)YPos + "," + (string)ZPos,
			"    Rot: <0.0,0.0,90.0>",
			"    Size: <1.00625,1.00625,1.0>",
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