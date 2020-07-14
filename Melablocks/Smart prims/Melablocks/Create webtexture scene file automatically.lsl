
integer NUMBER_OF_OBJECTS = 484;
string SCENE_FILE_NAME = "Auto";

list Urls  = [
	"https://i.imgur.com/6FQjsUi.png",
	"https://i.imgur.com/Quxx9Dm.png",
	"https://i.imgur.com/yHHvpLQ.png"
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
	integer Url = 0;
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
		string ExtraData = llList2String(Urls, Url);
		Url++;
		if (Url >= 3) Url = 0;
		Lines += [
			"{",
			"    Section: Linked",
			"    Name: Web texture block",
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