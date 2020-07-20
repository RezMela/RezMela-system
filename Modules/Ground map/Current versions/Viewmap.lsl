// Viewmap v0.6

// v0.6 - get root rotation, not child prim rotation
// v0.4 - get root position, not child prim position

// Google API documentation:
// https://developers.google.com/maps/documentation/streetview/intro
// Previous method here:
// https://developers.google.com/maps/documentation/javascript/streetview

integer MAP_CHAT_CHANNEL = -40101912;

integer GMW_LOCATION = -90153000;

string CONFIG_NOTECARD = "Viewmap config";

vector CurrentPos;
rotation CurrentRot;

integer Fov;
integer Pitch;
string ApiKey;

list Faces;
list Angles;
integer FacesCount;

key GroundMapId;

float CurrentLat;
float CurrentLon;
integer Heading;

integer RegionAgentCount;	// number of avatars in the region
integer NeedRedisplay;	// Countdown in seconds to redisplay if >0

Debug(string Text) {
	llRegionSay(1234, Text);
}
Display() {
	Debug("Displaying " + (string)FacesCount + " views");
	integer P = FacesCount;
	llClearPrimMedia(ALL_SIDES);
	while(P--) {
		integer Face = llList2Integer(Faces, P);
		integer Angle = llList2Integer(Angles, P);
		integer FaceHeading = Heading + Angle;
		if (FaceHeading > 360) FaceHeading -= 360;
		string Url = BuildUrl(CurrentLat, CurrentLon, FaceHeading);
		list MediaParams = [
			PRIM_MEDIA_AUTO_PLAY, TRUE,
			PRIM_MEDIA_CURRENT_URL, Url,
			PRIM_MEDIA_HEIGHT_PIXELS, 640,
			PRIM_MEDIA_WIDTH_PIXELS, 640
				];
		llSetPrimMediaParams(Face, MediaParams);
		llSetPrimMediaParams(Face, MediaParams);
		Debug("Face " + (string)Face + "(" + (string)Angle + "°): " + Url);
	}
}
string BuildUrl(float Lat, float Lon, integer Head) {
	return "https://maps.googleapis.com/maps/api/streetview?size=640x640&location=" +
		(string)Lat + "," + (string)Lon +
		"&fov=" + (string)Fov + "&heading=" + (string)Head +
		"&pitch=" + (string)Pitch + "&key=" + ApiKey;
}
// Obtain integer heading (in degrees) from given rotation
integer Rot2Heading(rotation Rot) {
	vector Euler = llRot2Euler(Rot);
	return -(integer)(Euler.z * RAD_TO_DEG);
}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	integer IsOK = TRUE;
	// Set config defaults
	ApiKey = "ApiKeyUnknown";
	Fov = 90;
	Pitch = 0;
	Faces = [];
	Angles = [];
	FacesCount = 0;
	integer Lines = osGetNumberOfNotecardLines(CONFIG_NOTECARD);
	integer I;
	for(I = 0; I < Lines; I++) {
		string Line = osGetNotecardLine(CONFIG_NOTECARD, I);
		integer Comment = llSubStringIndex(Line, "//");
		if (Comment != 0) {	// Not a complete comment line
			if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);	// strip from comments characters onwards
			if (llStringTrim(Line, STRING_TRIM) != "") {	// if there's something left after comments are removed
				// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
				list L = llParseStringKeepNulls(Line, [ "=" ], [ ]);	// Separate LHS and RHS of assignment
				if (llGetListLength(L) == 2) {	// so there is a "X = Y" kind of syntax
					string OName = llStringTrim(llList2String(L, 0), STRING_TRIM);		// original parameter name
					string Name = llToLower(OName);		// lower-case version for case-independent parsing
					string Value = llStringTrim(llList2String(L, 1), STRING_TRIM);
					// Interpret name/value pairs
					if (Name == "apikey")	ApiKey = StripQuotes(Value, Line);
					else if (Name == "fov")	Fov = (integer)Value;
					else if (Name == "pitch") Pitch = (integer)Value;
					else if (Name == "face") {
						list FaceData = llCSV2List(Value);
						if (llGetListLength(FaceData) != 2) {
							llOwnerSay("Invalid \"face\" entry in config file: '" + Value + "' (should be <face#>,<angle>)");
							IsOK = FALSE;
						}
						else {
							integer Face = (integer)llList2String(FaceData, 0);
							integer Angle = (integer)llList2String(FaceData, 1);
							Faces += Face;
							Angles += Angle;
							FacesCount++;
						}
					}
					else {
						llOwnerSay("Invalid keyword in config file: '" + OName + "'");
						IsOK = FALSE;
					}
				}
				else {
					llOwnerSay("Invalid line in config file: " + Line);
					IsOK = FALSE;
				}
			}
		}
	}
	return IsOK;
}
// Takes a string in double quotes, and strips out the quotes. Validates the format.
// <Text> is the string with quotes; <Line> is the entire line for error reporting
string StripQuotes(string Text, string Line) {
	if (Text == "") {	// allow empty string for null value
		return("");
	}
	if (llGetSubString(Text, 0, 0) == "\"" && llGetSubString(Text, -1, -1) == "\"") { 	// if surrounded by quotes
		return(llGetSubString(Text, 1, -2));	// strip quotes
	}
	else {
		llOwnerSay("Invalid string literal (missing \"\"?): " + Line);
		return("");
	}
}

// Wrapper for osMessageObject() that checks to see if target exists
MessageGroundMap(string Text) {
	if (ObjectExists(GroundMapId)) {
		osMessageObject(GroundMapId, Text);
	}
	else {
		GroundMapId = NULL_KEY;
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		state Boot;
	}
}
state Boot {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Debug("Initialising (script: " +llGetScriptName() + ")");
		//ApiKey = "AIzaSyAyF_cAJKP9fS6ETVfcbPJ931AtlPI6U1w";	// John H
		llClearPrimMedia(ALL_SIDES);
		if (ReadConfig()) {
			state FindGroundMap;
		}
	}
}
state FindGroundMap {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Debug("Finding ground map");
		llListen(MAP_CHAT_CHANNEL, "", NULL_KEY, "");
	}
	listen(integer Channel, string Name, key Id, string Message) {
		GroundMapId = Id;
		Debug("Ground map found");
		state Normal;	// change of state closes listener
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			llResetScript();
		}
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		RegionAgentCount = llGetRegionAgentCount();
		llSetTimerEvent(1.0);
		CurrentPos = <-1, -1, -1>; // Force display
	}
	timer() {
		integer Rac = llGetRegionAgentCount();
		if (Rac > RegionAgentCount) {	// if someone has entered the region
			NeedRedisplay = 5;			// flag for redisplay
			Debug("Avatar has entered region - redisplaying soon");
		}
		RegionAgentCount = Rac;
		if (NeedRedisplay) {
			if (!--NeedRedisplay) Display();	// If NeedRedisplay reaches 0, redisplay
		}
		// vector Pos = llGetPos();
		vector Pos = llGetRootPosition();	// v0.4
		//rotation Rot = llGetRot();
		rotation Rot = llGetRootRotation();		// v0.6
		if (Pos != CurrentPos) {	// moved (and possibly rotated)
			Debug("Change of position detected");
			// Request our lat/lon from the ground map, based on our in-world position
			Debug("Requesting lat/lon for: " + llList2CSV([ Pos.x, Pos.y ]));

			MessageGroundMap(llDumpList2String([
				GMW_LOCATION, Pos.x, Pos.y
					], "|"));
			Heading = Rot2Heading(Rot);
			CurrentPos = Pos;
			CurrentRot = Rot;
		}
		else if (Rot != CurrentRot) { 	// not moved, just rotated
			Debug("Change of rotation detected");
			Heading = Rot2Heading(Rot);
			Display();
			CurrentRot = Rot;
		}
		if (GroundMapId == NULL_KEY) state FindGroundMap;	// If ground map has disappeared, reacquire it
	}
	dataserver(key From, string Data) {
		if (From == GroundMapId) {
			list Parts = llParseString2List(Data, [ "|" ], []);
			CurrentLat = (float)llList2String(Parts, 1);
			CurrentLon = (float)llList2String(Parts, 2);
			Debug("Received lat/lon: " + llList2CSV([ CurrentLat, CurrentLon ]));
			Heading = Rot2Heading(llGetRot());
			Display();
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			state Boot;
		}
		if (Change & CHANGED_REGION_START) {
			Display();
		}
	}
}
// Viewmap v0.6