// Ground map v0.1

// API documentation: https://developers.google.com/maps/documentation/static-maps/intro?hl=en

integer MAP_FACE = 0;	// which face of prim to use
integer MAP_WIDTH_PIXELS = 1024;
integer MAP_HEIGHT_PIXELS = 1024;
integer PAGE_WIDTH_PIXELS = 1024;
integer PAGE_HEIGHT_PIXELS = 1024;

float MOVE_AMOUNT = 0.0001;

float Latitude;
float Longitude;
integer ZoomLevel;
integer Scale;
string MapType;
string MAP_TYPE_STREET_MAP = "roadmap";
string MAP_TYPE_SATELLITE = "satellite";
string MAP_TYPE_HYBRID = "hybrid";
string MAP_TYPE_TERRAIN = "terrain";

string CurrentUrl;

DisplayMap() {
	llSetTexture("3fb09f05-ac5f-41ae-ba4a-00ce8014426c", ALL_SIDES);
	// http://maps.google.com/maps?z=12&t=m&q=loc:38.9419+-78.3020
	//CurrentUrl = "http://maps.google.com/maps?z=" + (string)ZoomLevel + "&t=" + MapType + "&q=loc:" + (string)Latitude + "+" + (string)Longitude;

	// http://stackoverflow.com/questions/18582066/how-to-calculate-zoom-url-parameter-at-the-google-maps-preview-new-version-gm
	//CurrentUrl = "https://www.google.co.uk/maps/place/@" + (string)Latitude + "," + (string)Longitude + "," + (string)ZoomLevel + "z";
	// Experimentation gives:
	//https://www.google.co.uk/maps/@52.525971,-1.36228,20z
	// CurrentUrl = "https://www.google.co.uk/maps/@" + (string)Latitude + "," + (string)Longitude + "," + ZoomLevel + "z";
	// https://maps.googleapis.com/maps/api/staticmap?center=New%20Rochelle,NY&zoom=15&size=640x640
	CurrentUrl = "https://maps.googleapis.com/maps/api/staticmap?center=" +
		(string)Latitude + "," + (string)Longitude +
		"&zoom=" + (string)ZoomLevel +
		"&scale=" + (string)Scale +
		"&maptype=" + MapType +
		"&size=" + (string)MAP_WIDTH_PIXELS + "x" + (string)MAP_HEIGHT_PIXELS;
	llOwnerSay("URL:\n" + CurrentUrl);
        string CommandList = "";
        CommandList = osMovePen(CommandList, 0, 0);
        CommandList = osDrawImage(CommandList, PAGE_WIDTH_PIXELS, PAGE_HEIGHT_PIXELS, CurrentUrl);
        osSetDynamicTextureData("", "vector", CommandList, "width:" + (string)PAGE_WIDTH_PIXELS + ",height:" + (string)PAGE_HEIGHT_PIXELS, 0);	
	//	integer Status = llSetPrimMediaParams(MAP_FACE, [
	//		PRIM_MEDIA_AUTO_PLAY, FALSE,
	//		PRIM_MEDIA_AUTO_SCALE, FALSE,
	//		PRIM_MEDIA_AUTO_ZOOM, FALSE,
	//		PRIM_MEDIA_WIDTH_PIXELS, PAGE_WIDTH_PIXELS,
	//		PRIM_MEDIA_HEIGHT_PIXELS, PAGE_HEIGHT_PIXELS,
	//		PRIM_MEDIA_CURRENT_URL, CurrentUrl
	//			]);
	//	if (Status) {
	//		llOwnerSay("WARNING: llSetPrimMediaParams() returned status " + (string)Status);
	//	}
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
        Latitude = 53.7703;
        Longitude =  -0.3651;
		ZoomLevel = 19;
        Scale = 2;	
		MapType = MAP_TYPE_STREET_MAP;
		DisplayMap();
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) llResetScript();
	}
	touch_start(integer Count) {
		integer LinkNum = llDetectedLinkNumber(0);
		if (LinkNum == 4) {	// arrow up
			Latitude += MOVE_AMOUNT;
			DisplayMap();
		}
		else if (LinkNum == 3) {	// arrow down
			Latitude -= MOVE_AMOUNT;
			DisplayMap();
		}
		else if (LinkNum == 6) {	// arrow left
			Longitude -= MOVE_AMOUNT;
			DisplayMap();
		}
		else if (LinkNum == 5) {	// arrow right
			Longitude += MOVE_AMOUNT;
			DisplayMap();
		}
		else if (LinkNum == 2) {	// centre part
			if (MapType == MAP_TYPE_STREET_MAP) MapType = MAP_TYPE_SATELLITE;
			else MapType = MAP_TYPE_STREET_MAP;
			DisplayMap();			
		}
//		else llOwnerSay("Link number == " + (string)LinkNum);
	}
}

// Ground map v0.1