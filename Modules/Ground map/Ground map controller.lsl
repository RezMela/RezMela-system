// Ground map controller v1.1.0

// DEEPSEMAPHORE CONFIDENTIAL
// __
//
//  [2018] - [2028] DEEPSEMAPHORE LLC
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of DEEPSEMAPHORE LLC and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to DEEPSEMAPHORE LLC
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from DEEPSEMAPHORE LLC. For more information, or requests for code inspection,
// or modification, contact support@rezmela.com

// v1.1.0 - fix type mismatch error for OpenSim 0.9
// v1.0 - major version change
// v0.12 - integrate with ML (as single prim)
// v0.11 - add heartbeat, and request for world coordinates
// v0.10 - menu button relabelling
// v0.9 - integreation with search function
// v0.8 - changes to reflect worldobject v0.6
// v0.7 - bug fixing
// v0.6 - allow zoom enty in textbox
// v0.5 (forgot to reversion) - Extra data
// v0.5 - Changed region start behaviour
// v0.4 - API key stuff

// Static Maps API documentation: https://developers.google.com/maps/documentation/static-maps/intro?hl=en
// Google Places (search): https://developers.google.com/places/javascript/

// Static Maps API key: AIzaSyBo_U-CoKsPtJvgB8LU7qb22deGR4X7Mfk
// Search API key: AIzaSyAmdGed6n7oOmU-HJEBm4wNvh4Mi_xlJPo

integer MAP_WIDTH_PIXELS = 1024;
integer MAP_HEIGHT_PIXELS = 1024;

string PLACES_NOTECARD = "Places";
string CONFIG_NOTECARD = "Ground map config";

// Link messaage number, sent by ML main script
integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_RESERVED_TOUCH_FACE = -44088510;

integer HUD_API_LOGIN = -47206000;
integer HUD_API_LOGOUT = -47206001;

float TIMER_PERIOD = 1.6;	// This is about right, I think

integer MAP_CHAT_CHANNEL = -40101912;

integer LM_TILE_PARAMETERS = -451914200;
integer LM_TILE_DISPLAY = -451914201;
integer LM_MOVE_TO = -451914202;
integer LM_BOOKMARKS = -451914203;

// RezMela world object, request for icon ID, etc
integer RWO_EXTRA_DATA_SET = 808399102;	// +ve for incoming, -ve for outgoing
integer RWO_INITIALISE = 808399110;	// +ve for data (sent repeateadly at startup), client sends -ve to disable. Icon ID is sent as key portion
integer WO_COMMAND = 3007;

// Icon commands
integer GMI_MAP_PARAMETERS = -90151000;
integer GMI_MAP_DISPLAY = -90151001;

integer GMC_SEARCH = -90152000;
integer GMC_MOVE_TO = -90152001;

integer GMW_LOCATION = -90153000;

// Commands for RezMela icon script
integer IC_COMMAND = 1020;
integer IC_MENU = 1021;

key IconUuid;		// UUID of icon root object
integer InitialiseReceived = FALSE;

// Parallel
list TileLinkNums;
list TileXs;
list TileYs;
integer TileCount;

// Special prims
integer PrimArrowUp;
integer PrimArrowDown;
integer PrimArrowLeft;
integer PrimArrowRight;
integer PrimRefresh;
integer PrimMode;
integer PrimGoto;
integer PrimZoomIn;
integer PrimZoomOut;

integer PrimCount;

string CurrentUrl;

// Apps storage
integer DataRequested;
integer DataReceived;

// Maps storage
integer DataUpdated = FALSE;		// Has the data changed, so it needs to be stored as extra data?
string LastExtraData;				// The last extra data sent, so don't resend if it's the same

integer MapPositionSet = FALSE;
float Latitude;
float Longitude;
integer DefaultZoomLevel;
integer ZoomLevel;
integer Scale;
string LoadingTexture;
integer SinglePrim;
list MapFaces;
integer MapFacesCount;
string MapType;
string ApiKey;
string SearchApi;
integer IconZoomDifference;
string MAP_TYPE_STREET_MAP = "roadmap";
string MAP_TYPE_SATELLITE = "satellite";
string MAP_TYPE_HYBRID = "hybrid";
string MAP_TYPE_TERRAIN = "terrain";

integer HamburgerHide;			// If TRUE, hamburger face hides on logout
integer HamburgerVisible;      	// Is hamburger visible?
list HamburgerFaces;
integer HamburgerFacesCount;

float TileSize;
float MoveDistance;
integer MOVE_DIRECTION_N = 1;
integer MOVE_DIRECTION_E = 2;
integer MOVE_DIRECTION_W = 3;
integer MOVE_DIRECTION_S = 4;

integer MenuListener;
integer MenuChannel;
integer TextboxChannel;		// we keep a separate channel for textbox input so we know which is which
key MenuAvId;

list Places;	// string CSVs: [ Name, Lat, Lon ]

float MERCATOR_RANGE = 256;
float pixelOriginX;
float pixelOriginY;
float pixelsPerLonDegree;
float pixelsPerLonRadian;

integer NeedDisplay = FALSE;

Display() {
	NeedDisplay = FALSE;
	SetIconMap();
	if (SinglePrim) {
		Render(Latitude, Longitude);
	}
	else { // Multi-prim map object
		integer T;
		for (T = 0; T < TileCount; T++) {
			integer LinkNum = llList2Integer(TileLinkNums, T);
			float TileX = llList2Float(TileXs, T);
			float TileY = llList2Float(TileYs, T);
			// Calculate distance in M to the centre of the tile
			float DistanceX = TileSize * TileX;
			float DistanceY = TileSize * TileY;

			list MercYX = fromLatLngToPoint(Latitude, Longitude);
			float MercY = llList2Float(MercYX, 0);
			float MercX = llList2Float(MercYX, 1);
			MercY -= DistanceY;
			MercX += DistanceX;
			list MercLL = fromPointToLatLng(MercY, MercX);
			float CentrePointLat = llList2Float(MercLL, 0);
			float CentrePointLon = llList2Float(MercLL, 1);
			llMessageLinked(LinkNum, LM_TILE_DISPLAY, llList2CSV([CentrePointLat, CentrePointLon]), NULL_KEY);
		}
	}
	SetExtraData();
}
// Display the map if it's single-prim (for multi-prim this is done by the tiles' scripts)
Render(float Latitude, float Longitude) {
	integer Ptr;
	for (Ptr = 0; Ptr < MapFacesCount; Ptr++) {
		integer Face = llList2Integer(MapFaces, Ptr);
		llSetTexture(LoadingTexture, Face);// "Loading" texture
	}
	CurrentUrl = "https://maps.googleapis.com/maps/api/staticmap?center=" +
		(string)Latitude + "," + (string)Longitude +
		"&zoom=" + (string)ZoomLevel +
		"&scale=" + (string)Scale +
		"&maptype=" + MapType +
		"&size=" + (string)MAP_WIDTH_PIXELS + "x" + (string)MAP_HEIGHT_PIXELS +
		"&key=" + ApiKey;
	string DynamicID="";
	string ContentType="image";
	//llOwnerSay(llGetObjectDesc() + ": " + CurrentUrl);
	string ExtraData = "";
	integer Disp = 2;
	integer Timer = 0;
	integer Alpha = 255;
	for (Ptr = 0; Ptr < MapFacesCount; Ptr++) {
		integer Face = llList2Integer(MapFaces, Ptr);
		osSetDynamicTextureURLBlendFace(DynamicID, ContentType, CurrentUrl, ExtraData, FALSE, Disp, Timer, Alpha, Face);
	}
}
// Set map faces to blank
Clear() {
	integer Ptr;	
	for (Ptr = 0; Ptr < MapFacesCount; Ptr++) {
		integer Face = llList2Integer(MapFaces, Ptr);
		llSetTexture(TEXTURE_BLANK, Face);
	}
}
TriggerDisplay() {
	NeedDisplay = TRUE;
	llSetTimerEvent(TIMER_PERIOD);
}
SetIconMap() {
	MessageIcon(llList2CSV([
		GMI_MAP_DISPLAY, Latitude, Longitude
			]));
}
Move(integer MoveDirection) {
	float MoveLatitude = 0.0;
	float MoveLongitude = 0.0;
	if (MoveDirection == MOVE_DIRECTION_N) {
		MoveLatitude = MoveDistance;
	}
	else if (MoveDirection == MOVE_DIRECTION_S) {
		MoveLatitude = -MoveDistance;
	}
	else if (MoveDirection == MOVE_DIRECTION_W) {
		MoveLongitude = -MoveDistance;
	}
	else if (MoveDirection == MOVE_DIRECTION_E) {
		MoveLongitude = MoveDistance;
	}
	list MercYX = fromLatLngToPoint(Latitude, Longitude);
	float MercY = llList2Float(MercYX, 0);
	float MercX = llList2Float(MercYX, 1);
	MercY -= MoveLatitude;
	MercX += MoveLongitude;
	list MercLL = fromPointToLatLng(MercY, MercX);
	Latitude = llList2Float(MercLL, 0);
	Longitude = llList2Float(MercLL, 1);
	DataUpdated = TRUE;
	TriggerDisplay();
}
ShowMenu() {
	MenuChannel = -10000 - (integer)llFrand(10000000.0);
	MenuListener = llListen(MenuChannel, "", MenuAvId, "");
	string ModeStreetMapButton = "Street map";
	string ModeSatelliteButton = "Satellite";
	if (MapType == MAP_TYPE_STREET_MAP)
		ModeStreetMapButton = " ";
	else
		ModeSatelliteButton = " ";
	llDialog(MenuAvId, "\n\nSelect option:", [
		"Close",
		"Zoom +",
		"Zoom -",
		"Move E",
		"Move W",
		"Move S",
		ModeStreetMapButton,
		ModeSatelliteButton,
		"Move N",
		"Search",
		"Coordinates",
		"Refresh"
			], MenuChannel);
}
ProcessMenuOption(string Message) {
	if (Message == "Close") {
		llListenRemove(MenuListener);
		MenuListener = 0;
		MenuAvId = NULL_KEY;
	}
	else if (Message == "Zoom +") {
		Zoom(TRUE);
	}
	else if (Message == "Zoom -") {
		Zoom(FALSE);
	}
	else if (Message == "Move N") {
		Move(MOVE_DIRECTION_N);
	}
	else if (Message == "Move E") {
		Move(MOVE_DIRECTION_E);
	}
	else if (Message == "Move W") {
		Move(MOVE_DIRECTION_W);
	}
	else if (Message == "Move S") {
		Move(MOVE_DIRECTION_S);
	}
	//			else if (Message == "Map mode") {
	//				SwapMapMode();
	//			}
	else if (Message == "Street map") {
		SetMapMode(MAP_TYPE_STREET_MAP);
	}
	else if (Message == "Satellite") {
		SetMapMode(MAP_TYPE_SATELLITE);
	}
	else if (Message == "Refresh") {
		Display();
	}
	else if (Message == "Search") {
		string SearchParams = llDumpList2String([ SearchApi, SinglePrim ], "|");
		llMessageLinked(LINK_THIS, GMC_SEARCH, SearchParams, MenuAvId);
		return;
	}
	else if (Message == "Coordinates") {
		GetCoordinates();
		return;
	}
	ShowMenu();
}
ProcessCoordinates(string Message) {
	list L = llParseStringKeepNulls(Message, [ "," ], []);
	integer Len = llGetListLength(L);
	if (Len < 2 || Len > 3) {
		llOwnerSay("Sorry, couldn't parse those coordinates");
		return;
	}
	Latitude = (float)llList2String(L, 0);
	Longitude = (float)llList2String(L, 1);
	if (Len > 2)
		ZoomLevel = (integer)llList2String(L, 2);
	else
		ZoomLevel = DefaultZoomLevel;
	DataUpdated = TRUE;
	Display();
}
SendParameters() {
	// Send to tiles
	llMessageLinked(LINK_SET, LM_TILE_PARAMETERS, llList2CSV([
		ZoomLevel,
		Scale,
		MapType,
		ApiKey
			]), NULL_KEY);
	// Send to icon
	MessageIcon(llList2CSV([
		GMI_MAP_PARAMETERS,
		ZoomLevel - IconZoomDifference,
		Scale,
		MapType,
		ApiKey
			]));
	SetExtraData();
}
GetPrims() {
	PrimCount = llGetNumberOfPrims();
	integer P;
	for (P = 2; P <= PrimCount; P++) {
		string PrimName = llGetLinkName(P);
		if (PrimName == "Arrow up") PrimArrowUp = P;
		else if (PrimName == "Arrow down") PrimArrowDown = P;
		else if (PrimName == "Arrow left") PrimArrowLeft = P;
		else if (PrimName == "Arrow right") PrimArrowRight = P;
		else if (PrimName == "Refresh") PrimRefresh = P;
		else if (PrimName == "Mode") PrimMode = P;
		else if (PrimName == "Goto") PrimGoto = P;
		else if (PrimName == "Zoom in") PrimZoomIn = P;
		else if (PrimName == "Zoom out") PrimZoomOut = P;
		else if (PrimName == "Tile") {
			string PrimDesc = llList2String(llGetLinkPrimitiveParams(P, [ PRIM_DESC ]), 0);
			list L = llCSV2List(PrimDesc);
			if (llGetListLength(L) != 2) {
				llOwnerSay("Malformed description in prim tile (link no. " + (string)P + "): " + PrimDesc);
				return;
			}
			TileLinkNums += P;
			TileXs += (float)llList2String(L, 0);
			TileYs += (float)llList2String(L, 1);
		}
	}
	TileCount = llGetListLength(TileLinkNums);
}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return;
	}
	// Set config defaults
	SinglePrim = FALSE;
	ApiKey = "ApiKeyUnknown";
	SearchApi = "ApiKeyUnknown";
	LoadingTexture = TEXTURE_BLANK;
	IconZoomDifference = 2;
	DefaultZoomLevel = 20;
	HamburgerHide = TRUE;
	HamburgerFaces = [];
	MapFaces = [];
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
					if (Name == "singleprim") SinglePrim = String2Bool(Value);
					else if (Name == "loadingtexture") LoadingTexture = StripQuotes(Value, Line);
					else if (Name == "apikey")	ApiKey = StripQuotes(Value, Line);
					else if (Name == "searchapikey")	SearchApi = StripQuotes(Value, Line);
					else if (Name == "defaultzoom") DefaultZoomLevel = (integer)Value;
					else if (Name == "iconzoom")	IconZoomDifference = (integer)Value;	// Map only
					else if (Name == "hidehamburger") HamburgerHide = String2Bool(Value);
					else if (Name == "hamburgerfaces") HamburgerFaces = CSV2IntegerList(Value);
					else if (Name == "mapfaces") MapFaces = CSV2IntegerList(Value);
					else llOwnerSay("Invalid keyword in config file: '" + OName + "'");
				}
				else {
					llOwnerSay("Invalid line in config file: " + Line);
				}
			}
		}
	}
	MapFacesCount = llGetListLength(MapFaces);
	HamburgerFacesCount = llGetListLength(HamburgerFaces);
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
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
// Set hamburger visibility
SetHamburgerVisibility(integer IsVisible) {
	if (!HamburgerHide) return;	// We don't hide the hamburger if this is set
	HamburgerVisible = IsVisible;
	float Alpha = 0.0;
	if (IsVisible) Alpha = 1.0;
	integer FacePtr;
	for (FacePtr = 0; FacePtr< HamburgerFacesCount; FacePtr++) {
		integer Face = llList2Integer(HamburgerFaces, FacePtr);
		llSetAlpha(Alpha, Face);
	}
}
ReadPlaces() {
	Latitude = 40.758889; Longitude = -73.985048;	// Times Square is default
	if (SinglePrim) return;	// no bookmarks in MLO mode
	if (llGetInventoryType(PLACES_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Can't find notecard '" + PLACES_NOTECARD + "'");
		return;
	}
	Places = llParseString2List(osGetNotecard(PLACES_NOTECARD), [ "\n" ], []);	// take whole CSV strings into list
	SendBookmarks();
}
SendBookmarks() {
	integer PlacesCount = llGetListLength(Places);
	if (PlacesCount) {
		//		GetPlace(0);
		list Names = [];
		integer Ptr;
		for(Ptr = 0; Ptr < PlacesCount; Ptr++) {
			Names += llList2String(llCSV2List(llList2String(Places, Ptr)), 0);
		}
		llMessageLinked(LINK_SET, LM_BOOKMARKS, llList2CSV(Names), NULL_KEY);
	}
}
GetPlace(integer Which) {
	list L = llCSV2List(llList2String(Places, Which));
	//llOwnerSay(llList2String(L, 0));
	Latitude = (float)llList2String(L, 1);
	Longitude = (float)llList2String(L, 2);
	ZoomAbsolute(DefaultZoomLevel);
}
MessageIcon(string Text) {
	if (IconUuid != NULL_KEY && llKey2Name(IconUuid) != "") {
		osMessageObject(IconUuid, (string)IC_COMMAND + "|" + Text);
	}
}
// Converts metres to degrees lon or lat (not both, ie no diagonals)
// This and GreatCircleKm() are based on a very old project, converted to LSL
float Metres2Degrees(integer IsLongitude, float Metres, float Latitude) {
	if (IsLongitude) {
		float Km1Deg = GreatCircleKm(Latitude, 0.0, Latitude, 1.0);    // km in 1 degree of arc
		float M1Deg = Km1Deg * 1000.0;	// m in 1 degree of arc
		return Metres / M1Deg;
	}
	else {		// latitude - constant distance
		return Metres / 111111.111111111;
	}
}
// Returns distance in km between two points on the Earth's surface
float GreatCircleKm(float Lat1, float Lon1, float Lat2, float Lon2) {
	// Based on great circle calculation here:
	// http://dotnet-snippets.com/snippet/calculate-distance-between-gps-coordinates/677
	float Circumference = 40000.0; // Earth's circumference at the equator in km
	//Calculate radians
	float Lat1R = Lat1 * DEG_TO_RAD;
	float Lon1R = Lon1 * DEG_TO_RAD;
	float Lat2R = Lat2 * DEG_TO_RAD;
	float Lon2R = Lon2 * DEG_TO_RAD;

	float LonDiff = llFabs(Lon1R - Lon2R);

	if (LonDiff > PI) {
		LonDiff = 2.0 * PI - LonDiff;
	}

	float Angle = llAcos(
		llSin(Lat2R) * llSin(Lat1R) +
		llCos(Lat2R) * llCos(Lat1R) * llCos(LonDiff)
			);
	float Distance = Circumference * Angle / (2.0 * PI);
	return Distance;
}

// http://blog.dotnetframework.org/2013/09/03/exceeding-the-maximum-size-for-google-static-maps/
MercatorInit() {
	pixelOriginX = MERCATOR_RANGE / 2;
	pixelOriginY = MERCATOR_RANGE / 2;
	pixelsPerLonDegree = MERCATOR_RANGE / 360;
	pixelsPerLonRadian = MERCATOR_RANGE / (TWO_PI);
}
list fromLatLngToPoint(float Lat, float Lon) {
	float PointX = 0.0;
	float PointY = 0.0;
	float originX = pixelOriginX;
	float originY = pixelOriginY;
	PointX = originX + (Lon * pixelsPerLonDegree);
	float sinY = llSin(Lat * DEG_TO_RAD);
	if (sinY < -0.9999) sinY = -0.9999;
	else if (sinY > 0.9999) sinY = 0.9999;
	PointY = originY + (0.5 * llLog((1.0 + sinY) / (1.0 - sinY)) * -pixelsPerLonRadian);
	return [ PointY, PointX ];
}
list fromPointToLatLng(float PointY, float PointX) {
	float Lat;
	float Lon;
	float originX = pixelOriginX;
	float originY = pixelOriginY;
	Lon  = (PointX - originX) / pixelsPerLonDegree;
	float latRadians = (PointY - originY) / -pixelsPerLonRadian;

	// var lat = radiansToDegrees(2 * Math.atan(Math.exp(latRadians)) – Math.PI / 2);
	Lat = RAD_TO_DEG * (2.0 * llAtan2(Exp(latRadians), 1) - PI_BY_TWO);
	return [ Lat, Lon ];
}
float Exp(float N) {
	return llPow(2.718281828459045, N);
}
list CSV2IntegerList(string String) {
	list StringsList = llCSV2List(String);
	list Output = [];
	integer Len = llGetListLength(StringsList);
	integer I;
	for (I = 0; I < Len; I++) {
		Output += (integer)llList2String(StringsList, I);
	}
	return Output;
}
ProcessExtraData(string ExtraData) {
	if (ExtraData != "") {
		list L = llParseStringKeepNulls(ExtraData, [ "^" ], []);
		Latitude = (float)llList2String(L, 0);
		Longitude = (float)llList2String(L, 1);
		ZoomLevel = (integer)llList2String(L, 2);
		MapType = llList2String(L, 3);
		SetZoomDetails();
	}
}
SetExtraData() {
	if (!DataUpdated) return;
	string ExtraData = llDumpList2String([
		Latitude,
		Longitude,
		ZoomLevel,
		MapType
			], "^");
	if (ExtraData != LastExtraData) {
		if (SinglePrim) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_SET, ExtraData, NULL_KEY);
		}
		else {
			llMessageLinked(LINK_SET, RWO_EXTRA_DATA_SET, ExtraData, NULL_KEY);
		}
		LastExtraData = ExtraData;
	}
	DataUpdated = FALSE;
}
GetCoordinates() {
	TextboxChannel = -10000 - (integer)llFrand(10000000.0);
	MenuListener = llListen(TextboxChannel, "", MenuAvId, "");
	llTextBox(MenuAvId, "Enter lat/lon decimal values separated by a comma. Optionally, add zoom level after a second comma.\nEg:  48.858,2.294,20", TextboxChannel);
}
ZoomAbsolute(integer ToZoom) {
	ZoomLevel = ToZoom;
	SetZoomDetails();
	SendParameters();
	TriggerDisplay();
}
Zoom(integer In) {
	if (In) {
		if (ZoomLevel == 21) {
			llOwnerSay("Already at maximum zoom level (21)");
			return;
		}
		ZoomAbsolute(ZoomLevel + 1);
	}
	else {
		if (ZoomLevel == 3) {
			llOwnerSay("Already at minimum zoom level (3)");
			return;
		}
		ZoomAbsolute(ZoomLevel - 1);
	}
	DataUpdated = TRUE;
}
SetZoomDetails() {
	integer AlternateZoom = 21 - ZoomLevel;		// 1, 2, 3, etc
	float Factor = llPow(2.0, (float)AlternateZoom);
	TileSize = 0.00030507 * Factor;
	MoveDistance = 0.0001 * Factor;
}
SwapMapMode() {
	if (MapType == MAP_TYPE_STREET_MAP)
		SetMapMode(MAP_TYPE_SATELLITE);
	else
		SetMapMode(MAP_TYPE_STREET_MAP);
}
SetMapMode(string Mode) {
	MapType = Mode;
	DataUpdated = TRUE;
	SendParameters();
	TriggerDisplay();
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		IconUuid = NULL_KEY;
		MapPositionSet = FALSE;
		InitialiseReceived = FALSE;
		ReadConfig();
		Clear();	// set map faces to blank
		MercatorInit();
		ReadPlaces();
		//SetZoomDetails();
		//Latitude = 53.770098; Longitude =  -0.365013;	// Centre of Salmon Grove/Ferens Ave junction
		// Others:
		// 53.233567, -0.538602 (Lincoln)
		// 51.477222, 0.0 (Greenwich)
		// -53.770098, -67.725 	(Tierra del Fuego - southern hemisphere, opposite to Hull)
		// -0.155987, -78.488516 (Quito, Ecuador - on the equator)
		// 69.350285, 88.198636 (Norilsk, Sibera - very northerly)
		MapPositionSet = TRUE;	// when latitude and longitude are populated
		Scale = 2;
		ZoomLevel = DefaultZoomLevel;
		MapType = MAP_TYPE_STREET_MAP;
		SetZoomDetails();
		DataUpdated = FALSE;
		NeedDisplay = FALSE;
		if (SinglePrim) state StartAppObject; else state MapObject;
	}
}
state StartAppObject {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		if (llGetLinkNumber() > 1) state AppObject;
		// If unlinked, we don't do anything until we're linked
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) {
			if (llGetLinkNumber() > 1) state AppObject;
		}
	}
}
state AppObject {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		SetHamburgerVisibility(TRUE);
		DataRequested = DataReceived = FALSE;
		llSetTimerEvent(TIMER_PERIOD);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_LOADING_COMPLETE && !DataRequested) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, llList2CSV(HamburgerFaces), NULL_KEY);
			DataRequested = TRUE;
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			// The ML is telling us that someone clicked our reserved face. The string portion of the message contains a pipe-delimited
			// list of the following data: face, position, normal, binormal, ST, UV
			if (HamburgerHide && !HamburgerVisible) return;
			list TouchData = llParseStringKeepNulls(String, [ "|" ], []);    // Parse the data into a list of the four different parts
			integer TouchFace = (integer)llList2String(TouchData, 0);
			if (llListFindList(HamburgerFaces, [  TouchFace ]) > -1) {	// if it's one of the click faces
				MenuAvId = Id;
				ShowMenu();	// show the menu
				return;
			}
		}
		else if (Number == LM_EXTRA_DATA_GET) {
			// We can stop the timer because we have our data, and we also must have sent ETH_LOCK (because the timer has kicked
			// in at least once).
			llSetTimerEvent(0.0);
			DataReceived = TRUE;
			ProcessExtraData(String);
			Display();
		}
		else if (Number == HUD_API_LOGIN) {
			SetHamburgerVisibility(TRUE);
		}
		else if (Number == HUD_API_LOGOUT) {
			SetHamburgerVisibility(FALSE);
		}
		else if (Number == GMC_MOVE_TO) {
			list L = llParseStringKeepNulls(String, [ "," ], []);
			Latitude = (float)llList2String(L, 0);
			Longitude = (float)llList2String(L, 1);
			ZoomAbsolute(DefaultZoomLevel);
			DataUpdated = TRUE;
			Display();
		}
	}
	// Uncomment this for unlinked testing
	//	touch_start(integer Count) {
	//		MenuAvId = llDetectedKey(0);
	//		ShowMenu();
	//	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == MenuAvId) {
			ProcessMenuOption(Message);
		}
		else if (Channel == TextboxChannel && Id == MenuAvId) {
			ProcessCoordinates(Message);
		}
	}
	timer() {
		if (!DataReceived) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, llList2CSV(HamburgerFaces), NULL_KEY);
		}		
		if (NeedDisplay) Display();
	}
}
state MapObject {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		GetPrims();
		llSetTimerEvent(TIMER_PERIOD);
	}
	touch_start(integer Count) {
		integer LinkNum = llDetectedLinkNumber(0);
		if (LinkNum == PrimArrowUp) {	// arrow up
			Move(MOVE_DIRECTION_N);
		}
		else if (LinkNum == PrimArrowDown) {	// arrow down
			Move(MOVE_DIRECTION_S);
		}
		else if (LinkNum == PrimArrowLeft) {	// arrow left
			Move(MOVE_DIRECTION_W);
		}
		else if (LinkNum == PrimArrowRight) {	// arrow right
			Move(MOVE_DIRECTION_E);
		}
		else if (LinkNum == PrimRefresh) {
			Display();
		}
		else if (LinkNum == PrimGoto) {
			MenuAvId = llDetectedKey(0);
			GetCoordinates();
		}
		else if (LinkNum == PrimMode) {	// centre part
			SwapMapMode();
		}
		else if (LinkNum == PrimZoomIn) {	// if we're keeping the zoom feature, store the link numbers
			Zoom(TRUE);
		}
		else if (LinkNum == PrimZoomOut) {
			Zoom(FALSE);
		}
		//		else llOwnerSay("Link number == " + (string)LinkNum);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == RWO_INITIALISE && !InitialiseReceived) {
			llMessageLinked(LINK_SET, -RWO_INITIALISE, "", NULL_KEY);	// suppress further initialisation messages
			InitialiseReceived = TRUE;
			ProcessExtraData(String);
			IconUuid = Id;
			SendParameters();
			Display();
		}
		else if (Number == -LM_BOOKMARKS) {
			if (String == "") {	// it's a request for the bookmark list
				SendBookmarks();
			}
			else {
				GetPlace((integer)String);
				TriggerDisplay();
			}
		}
		else if (Number == WO_COMMAND) {
			// we've receieved a command from the icon, via the RezMela worldobject layer
			list L = llCSV2List(String);
			string Command = llList2String(L, 0);
			string Params = llList2String(L, 1);
			if (Command == "menu") {
				MenuAvId = (key)Params;
				ShowMenu();
			}
		}
		else if (Number == GMC_MOVE_TO) {
			list L = llParseStringKeepNulls(String, [ "," ], []);
			Latitude = (float)llList2String(L, 0);
			Longitude = (float)llList2String(L, 1);
			ZoomAbsolute(DefaultZoomLevel);
			DataUpdated = TRUE;
			Display();
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == MenuAvId) {
			ProcessMenuOption(Message);
		}
		else if (Channel == TextboxChannel && Id == MenuAvId) {
			ProcessCoordinates(Message);
		}
	}
	dataserver(key From, string Data) {
		list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
		integer Command = llList2Integer(Parts, 0);
		list Params = llList2List(Parts, 1, -1);
		if (Command == GMW_LOCATION) {	// Message from "viewmap" Maps object
			// they pass us their region coordinates and we calculate their position on our map in lat/lon
			float X = (float)llList2String(Params, 0);
			float Y = (float)llList2String(Params, 1);
			vector MyPos = llGetPos();
			// Get my position in "Mercator" coordinates
			list MercYX = fromLatLngToPoint(Latitude, Longitude);
			float MercY = llList2Float(MercYX, 0);
			float MercX = llList2Float(MercYX, 1);
			// Get distances in in-world metres
			float DistanceX = X - MyPos.x;
			float DistanceY = Y - MyPos.y;
			// Calculate how many degrees correspond to 1m in-world
			float MetreInDegrees =  TileSize / 128.0;		// The tiles are 128m
			// Convert target distance to degrees ("Mercator")
			float DegDistanceX = DistanceX * MetreInDegrees;
			float DegDistanceY = DistanceY * MetreInDegrees;
			// Obtain "mercator" X,Y of target
			float TargetMercX = MercX + DegDistanceX;
			float TargetMercY = MercY - DegDistanceY;
			// Convert that to actual lat/lon
			list LatLon = fromPointToLatLng(TargetMercY, TargetMercX);
			float TargetLat = llList2Float(LatLon, 0);
			float TargetLon = llList2Float(LatLon, 1);
			// And send result
			osMessageObject(From, llDumpList2String([ GMW_LOCATION, TargetLat, TargetLon ], "|"));
		}
	}
	timer() {
		// Send to "viewmap" (a Maps object that gives a Street View image at the given position)
		llRegionSay(MAP_CHAT_CHANNEL, MapType);	// at this stage, the data is irrelevant as long as something is being broadcast
		if (NeedDisplay) Display();
	}
	changed(integer Change) {
		//		if (Change & CHANGED_REGION_START) {
		//			Display();
		//			SendBookmarks();
		//		}
		if (Change & CHANGED_LINK) llResetScript();
		if (Change & CHANGED_INVENTORY) {
			ReadPlaces();
			ReadConfig();
		}
	}
}
// Ground map controller v1.1.0