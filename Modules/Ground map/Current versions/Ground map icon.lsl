// Ground map icon v0.2

integer GMI_MAP_PARAMETERS = -90151000;
integer GMI_MAP_DISPLAY = -90151001;

integer IC_COMMAND = 1020;	// Commands coming to us via the RezMela icon script
integer IC_MENU = 1021;

key WorldObjectUuid;
integer WO_COMMAND = 3007;

integer MAP_FACE = 0;	// which face of prim to use
integer MAP_WIDTH_PIXELS = 1024;
integer MAP_HEIGHT_PIXELS = 1024;
integer PAGE_WIDTH_PIXELS = 1024;
integer PAGE_HEIGHT_PIXELS = 1024;

float Latitude;
float Longitude;
integer ZoomLevel;
integer Scale;
string MapType;
string ApiKey;
string CurrentUrl;

DisplayMap() {
	llSetTexture("296eff9c-ff7e-4f15-877d-84fe06c8c09d", ALL_SIDES);
	CurrentUrl = "https://maps.googleapis.com/maps/api/staticmap?center=" +
		(string)Latitude + "," + (string)Longitude +
		"&zoom=" + (string)ZoomLevel +
		"&scale=" + (string)Scale +
		"&maptype=" + MapType +
		"&size=" + (string)MAP_WIDTH_PIXELS + "x" + (string)MAP_HEIGHT_PIXELS +
		"&key=" + ApiKey;
	string  dynamicID="";
	string  contentType="image";
	integer refreshRate = 600;
	string URLTexture=osSetDynamicTextureURL(dynamicID, contentType ,CurrentUrl  , "", refreshRate );
}
MessageController(string Text) {
	if (WorldObjectUuid != NULL_KEY && llKey2Name(WorldObjectUuid) != "") {
		osMessageObject(WorldObjectUuid, (string)WO_COMMAND + "|" + Text);
	}
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		WorldObjectUuid = NULL_KEY;
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == IC_COMMAND) {
			WorldObjectUuid = Id;
			list Parts = llCSV2List(Message);
			integer Command = (integer)llList2String(Parts, 0);
			if (Command == GMI_MAP_PARAMETERS) {
				ZoomLevel = (integer)llList2String(Parts, 1);
				Scale = (integer)llList2String(Parts, 2);
				MapType = llList2String(Parts, 3);
				ApiKey = llList2String(Parts, 4);
			}
			else if (Command == GMI_MAP_DISPLAY) {
				Latitude = (float)llList2String(Parts, 1);
				Longitude = (float)llList2String(Parts, 2);
				DisplayMap();
			}
		}
		else if (Number == IC_MENU) {	// Someone has clicked on the menu icon
			string sAvId = (string)Id;
			MessageController(llList2CSV([
				"menu",
				sAvId
					]));
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) DisplayMap();
	}
}
// Ground map icon v0.2