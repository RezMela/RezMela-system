// Ground map tile v0.4

// v0.4 - decentralised region start behaviour

integer LM_PARAMETERS = -451914200;
integer LM_DISPLAY = -451914201;

integer MAP_FACE = 0;	// which face of prim to use
integer MAP_WIDTH_PIXELS = 1024;
integer MAP_HEIGHT_PIXELS = 1024;
integer PAGE_WIDTH_PIXELS = 1024;
integer PAGE_HEIGHT_PIXELS = 1024;

integer OBJECT_PIN = -3010442;

float Latitude;
float Longitude;
integer ZoomLevel;
integer Scale;
string MapType;
string CurrentUrl;
string ApiKey;

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
	//llOwnerSay(llGetObjectDesc() + ": " + CurrentUrl);
	string URLTexture=osSetDynamicTextureURL(dynamicID, contentType ,CurrentUrl  , "", refreshRate );
}
default
{
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetRemoteScriptAccessPin(OBJECT_PIN);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_PARAMETERS) {
			list L = llCSV2List(String);
			ZoomLevel = (integer)llList2String(L, 0);
			Scale = (integer)llList2String(L, 1);
			MapType = llList2String(L, 2);
			ApiKey = llList2String(L, 3);
		}
		else if (Number == LM_DISPLAY) {
			list L = llCSV2List(String);
			Latitude = (float)llList2String(L, 0);
			Longitude = (float)llList2String(L, 1);
			DisplayMap();
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) {
			DisplayMap();
		}
	}
}
// Ground map tile v0.5