// FX particles v0.1

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

float FLAME_SIZE_FACTOR = 11.0;
//float EXPANSION_FACTOR = 2.2;	// how much the flames increase in size
string CONFIG_NOTECARD = "FX config";
integer MENU_FACE = 1;	// the face they click to get the menu

integer EffectType;
integer EFFECT_TYPE_FLAME = 1;
integer EFFECT_TYPE_SMOKE = 2;

integer PresetPtr;
integer PresetCount;
list Textures;

list ParticleParams;
integer PP_TEXTURE_PTR			= 0;
integer PP_COLOR				= 1;
integer PP_ALPHA				= 2;
integer PP_START_SIZE_FACTOR	= 3;
integer PP_END_SIZE_FACTOR		= 4;
integer PP_AGE					= 5;
integer PP_ACCELERATION			= 6;
integer PP_PARTICLE_COUNT		= 7;
integer PP_MAX_SPEED			= 8;
integer PP_ANGLE				= 9;
integer PP_RAISE				= 10;
integer PP_STRIDE				= 11;

integer MenuChannel;
key MenuAvId;
integer MenuListener;
integer MenuTimeout;

integer IsVisible;
integer IsSelected;

// Link messaage number, sent by ML main script
integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_RESERVED_TOUCH_FACE = -44088510;

integer HUD_API_LOGIN = -47206000;
integer HUD_API_LOGOUT = -47206001;

integer LM_PRIM_SELECTED = -405500;        // A prim has been selected (sent to other scripts)
integer LM_PRIM_DESELECTED = -405501;    // A prim has been deselected

integer DataRequested;
integer DataReceived;

SetParticles() {
	integer PPPtr = PresetPtr * PP_STRIDE;

	// Get variable values from table
	integer TexturePtr 			= llList2Integer(ParticleParams, PPPtr + PP_TEXTURE_PTR);
	vector Color 				= llList2Vector(ParticleParams, PPPtr + PP_COLOR);
	float Alpha 				= llList2Float(ParticleParams, PPPtr + PP_ALPHA);
	float StartSize 			= llList2Float(ParticleParams, PPPtr + PP_START_SIZE_FACTOR);
	float EndSize				= llList2Float(ParticleParams, PPPtr + PP_END_SIZE_FACTOR);
	float Age 					= llList2Float(ParticleParams, PPPtr + PP_AGE);
	float Accel 				= llList2Float(ParticleParams, PPPtr + PP_ACCELERATION);
	integer ParticleCount 		= llList2Integer(ParticleParams, PPPtr + PP_PARTICLE_COUNT);
	float MaxSpeed 				= llList2Float(ParticleParams, PPPtr + PP_MAX_SPEED);;
	integer Angle 				= llList2Integer(ParticleParams, PPPtr + PP_ANGLE);;
	float Raise					= llList2Float(ParticleParams, PPPtr + PP_RAISE);;

	// Calculations
	vector ObjectSize = llGetScale();
	float ObjectSizeFactor = ObjectSize.x;

	float EndAngle = (float)Angle * DEG_TO_RAD;

	float MinSpeed = 0.0;
	if (EffectType == EFFECT_TYPE_SMOKE) MinSpeed = 0.1;

	string Texture;
	Texture  = llList2String(Textures, TexturePtr);
	integer WindFlag = 0;
	if (EffectType == EFFECT_TYPE_SMOKE) WindFlag = PSYS_PART_WIND_MASK;
	if (EffectType == EFFECT_TYPE_FLAME) Color = <1.0, 1.0, 1.0>;	// No added color for flames

	// Some parameters should scale with object size
	while ((StartSize * ObjectSizeFactor) > 4.0 || (EndSize * ObjectSizeFactor) > 4.0) {	// Max particle size is 4x4m
		ObjectSizeFactor *= 0.75;
	}
	StartSize *= ObjectSizeFactor;
	EndSize *= ObjectSizeFactor;
	Accel *= (ObjectSizeFactor * 0.08);
	MaxSpeed *= ObjectSizeFactor;
	Raise *= (ObjectSizeFactor * 0.2);

	list Particles = [
		PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
		PSYS_PART_MAX_AGE, 6.0,
		PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_INTERP_COLOR_MASK | WindFlag,
		PSYS_PART_START_ALPHA, Alpha,
		PSYS_PART_END_ALPHA, 0.0,
		PSYS_PART_START_COLOR, Color,
		PSYS_PART_END_COLOR, Color,
		PSYS_PART_START_SCALE,  <StartSize, StartSize, 0.0>,
		PSYS_PART_END_SCALE, <EndSize, EndSize, 0.0>,
		PSYS_PART_MAX_AGE, Age,
		PSYS_SRC_ACCEL, <0.0, 0.0, Accel>,
		PSYS_SRC_BURST_PART_COUNT, ParticleCount,
		PSYS_SRC_BURST_RADIUS, Raise,
		PSYS_SRC_BURST_RATE, 0.2,
		PSYS_SRC_BURST_SPEED_MIN, MinSpeed,
		PSYS_SRC_BURST_SPEED_MAX, MaxSpeed,
		PSYS_SRC_ANGLE_BEGIN, 0.0,
		PSYS_SRC_ANGLE_END, EndAngle,
		PSYS_SRC_TEXTURE, Texture
			];
		llParticleSystem(Particles);
}
Init() {
	llParticleSystem([]);
	// Determine type of FX
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		LogError("Missing card: " + CONFIG_NOTECARD);
		return;

	}
	string CardContents = llToLower(llStringTrim(osGetNotecard(CONFIG_NOTECARD), STRING_TRIM));
	if (CardContents == "flames") {
		EffectType = EFFECT_TYPE_FLAME;
	}
	else if (CardContents == "smoke") {
		EffectType = EFFECT_TYPE_SMOKE;
	}
	else {
		LogError("Invalid effect type: " + CardContents);
		return;
	}
	// List of appropriate textures (more than we need to ensure import of all in case
	// we change our minds
	if (EffectType == EFFECT_TYPE_FLAME) {
		Textures = [
			// Handy/Abune
			"72b4ff56-45ea-4cf9-93a5-20a69f3f6662",    //
			"9be56b03-4af8-4371-9a8f-32db1f7bb7c3", //
			"5b6f2793-4b52-4390-a841-094aef9935dc",
			"252158cf-4bcc-49f3-a8f7-26b220a543d4",
			"51db1287-1fba-4b6a-ac02-1a26aaa7400c",
			// Melino
			"cb1e0b22-bfff-4915-bafc-e5221173e90b",    // 1
			"207350fc-eb6f-49cc-b3d2-03a3ac41bd3c",
			"c0a32656-df25-4948-97fa-1680f493a9ff",
			"48e86ba6-cb79-4881-bf34-2d1805c03b63",
			"35423219-3c8f-43ac-b93f-4bc51d9fb1a0",

			"488cfd57-8010-4f9a-b318-75fc0064d85e",    // 6
			"2b37fb9e-20a2-41f6-b2f2-75e7f34c2ab2",
			"21e4803a-8c90-41f1-85ba-de676fcba7d8",
			"2a029352-2434-42f6-98d5-aab022c78d37",
			"3e124b1f-d304-4189-8ed1-ec3ba42f3c38",

			"100bfe1b-7e16-43e1-8891-b5c3f7bcd76c",
			"6943d667-38b1-4f58-afee-498ade5cca03",
			"0174b9dc-2bc2-4727-82bc-67b50fb776b9",
			"9c97fb27-54df-4f36-9716-2045e0f8824f",
			"b50a6e4b-ae2c-4f90-8144-bb5828b48e60",

			"d5b1c49d-6e5f-4bf2-b90f-5c951914f18a",
			"8bc9381f-1619-4dba-ad9f-321640c78055",
			"c058ae6d-32d5-4b9f-9306-d6daa860343f",
			"1e6ea72a-6eee-45e5-a131-78c8fa0e46db",
			"fc603e18-abae-4d68-a81f-60579e1d95e3"
				] ;
	}
	else if (EffectType == EFFECT_TYPE_SMOKE) {
		Textures = [
			// Abune
			"17fa9504-f5ea-4269-9994-d8dcd4494be3",        // Abune smoke 1
			"cf26959e-1459-4db9-aa5e-3724aca823bb",        // Abune smoke 2
			"a9449237-87d9-4c00-badf-12ced5f83aac",        // Abune smoke 3
			"c5f78229-0dbe-42bd-b856-66062d23e36c",        // Abune smoke 4
			"036f5832-966a-49b2-bc6e-6278ab05c329",        // Abune smoke 5
			"c2470052-f128-4a6f-afce-2cc5210eed88",        // Abune smoke 6
			// Melino
			"bad3f645-ea87-4d78-9b67-77508a9e78eb",        // Melino-smoke-1.1-512
			"e9687a03-6958-4a5e-a1e9-cbef2170bcbc",        // Melino-smoke-2.2-512
			"f90a1242-6f5a-4cb9-a07c-550c8cb84b88",
			"cbb848f7-2fa0-4e69-a032-fbad81f7cb0d",
			"abd574f9-fd0b-49bb-a690-7725262b80f9",

			"06407420-e76e-4a56-8ece-744c343056c0",        // 6
			"24d42f17-b92c-4314-9be8-89ad5155a143",
			"c886c709-98f6-4e0c-b003-3f90c2962986",
			"ad307b6b-469c-4854-aa7b-881660580f44",
			"34d9df93-f204-4618-bf02-7ce9af9fa132",

			"d2f7a3e1-adb7-4213-a344-8d0a1a4b37fa",        // 11
			"920642df-cff6-4c54-8ef5-a99c7d72d467",
			"3e923f5c-e21a-4713-b919-6e26ed27052f",
			"a26e7192-42b0-421e-9978-13e55263ecea",
			"03e26545-b807-45ff-a3b2-cbfaa69f1e0d"        // Melino-smoke-11.11-512
				];
	}
	// Set up variable particle parameters
	if (EffectType == EFFECT_TYPE_FLAME) {
		ParticleParams = [
			// tex	color			alpha	ssize	esize	age		accel	count	speed	angle	raise	preset#
			1, 		ZERO_VECTOR, 	1.0,	1.5, 	1.8, 	1.0, 	0.02, 	1, 		1.5, 	15,		1.5,	// 1
			0, 		ZERO_VECTOR, 	1.0,	2.0, 	2.1, 	1.5, 	0.01, 	2, 		1.5, 	10,		1.5,	// 2
			2, 		ZERO_VECTOR, 	1.0,	1.0, 	2.1, 	1.5, 	0.0, 	1, 		1.0, 	10,		1.5,	// 3
			3, 		ZERO_VECTOR, 	1.0,	1.5, 	2.1, 	1.5, 	0.0, 	1, 		0.6, 	15,		3.0,	// 4
			5, 		ZERO_VECTOR, 	1.0,	2.0, 	2.1, 	1.0, 	0.0, 	2, 		0.6, 	10,		4.0,	// 5
			6, 		ZERO_VECTOR, 	1.0,	2.0, 	2.1, 	1.0, 	0.0, 	2, 		1.5, 	10,		3.0,	// 6
			10,		ZERO_VECTOR, 	1.0,	2.0, 	2.1, 	1.0, 	0.0, 	2, 		1.5, 	10,		3.0,	// 7
			23, 	ZERO_VECTOR, 	1.0,	3.0, 	3.2, 	1.5, 	0.0, 	2, 		1.2, 	10,		3.5		// 8
				];
	}
	else if (EffectType == EFFECT_TYPE_SMOKE) {
		ParticleParams = [
			// tex	color				alpha	ssize	esize	age		accel	count	speed	angle	raise	preset#
			1, 		<0.5, 0.5, 0.5>, 	0.6,	1.5, 	4.5, 	5.0, 	0.2, 	2, 		2.5, 	10,		0.0,	// 1
			0, 		<0.1, 0.1, 0.1>, 	0.6,	1.5, 	4.5, 	4.0, 	0.4, 	2, 		2.5, 	10,		0.0,	// 2
			2, 		<0.8, 0.8, 0.8>, 	0.6,	1.5, 	4.5, 	4.0, 	0.2, 	2, 		2.5, 	10,		0.0,	// 3
			3, 		<0.5, 0.5, 0.5>, 	0.6,	1.5, 	4.5, 	4.0, 	0.2, 	2, 		2.5, 	10,		0.0,	// 4
			4, 		<0.8, 0.8, 0.8>, 	0.6,	1.5, 	4.5, 	4.0, 	0.2, 	2, 		2.5, 	10,		0.0,	// 5
			5, 		<0.6, 0.6, 0.6>, 	0.6,	1.0, 	6.0, 	4.0, 	0.2, 	2, 		3.5, 	10,		0.0,	// 6
			7, 		<0.5, 0.5, 0.5>, 	0.6,	1.5, 	4.5, 	4.0, 	0.2, 	2, 		2.5, 	10,		0.0,	// 7
			20,		<0.4, 0.4, 0.5>, 	0.6,	1.5, 	4.5, 	4.0, 	0.2, 	2, 		2.5, 	10,		0.0		// 8
				];
	}
	PresetCount = llGetListLength(ParticleParams) / PP_STRIDE;
}
SetVisibility(integer MakeVisible) {
	IsVisible = MakeVisible;
	if (IsVisible)
		llSetAlpha(1.0, ALL_SIDES);
	else
		llSetAlpha(0.0, ALL_SIDES);
}
ShowMenu(key AvId) {
	MenuAvId = AvId;
	StopListener();
	MenuChannel = 10000 - (integer)llFrand(1000000.0);
	MenuListener = llListen(MenuChannel, "", MenuAvId, "");
	string TypeDesc = "?";
	if (EffectType == EFFECT_TYPE_FLAME) {
		TypeDesc = "flame";
	}
	else if (EffectType == EFFECT_TYPE_SMOKE) {
		TypeDesc = "smoke";
	}
	list Buttons;
	integer I;
	for (I = 1; I <= PresetCount; I++) {
		Buttons += (string)I;
	}
	Buttons += "Done";
	Buttons = llList2List(Buttons, -3, -1) + llList2List(Buttons, -6, -4)
		+ llList2List(Buttons, -9, -7) + llList2List(Buttons, -12, -10);
	llDialog(MenuAvId, "\nSelect " + TypeDesc + " preset (currently " + (string)(PresetPtr + 1) + "):", Buttons, MenuChannel);
	llSetTimerEvent(10.0);
	MenuTimeout = 3600;	// we have to use a timeout counter because we share the timer event
}
StopListener()  {
	llListenRemove(MenuListener);
	MenuListener = 0;
	MenuTimeout = 0;
}
LogError(string Text) {
	llRegionSay(-7563234, Text);
}
default {
	on_rez(integer p) { llResetScript(); }
	state_entry() {
		Init();
		PresetPtr = 0;
		MenuListener = 0;
		SetParticles();
		SetVisibility(TRUE);
		DataRequested = DataReceived = FALSE;
		IsSelected = FALSE;
	}
	link_message(integer Sender, integer Number, string String, key Id)    {
		if (Number == LM_LOADING_COMPLETE && !DataRequested) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, (string)MENU_FACE, NULL_KEY);
			llSetTimerEvent(12.0 + llFrand(6.0));
			DataRequested = TRUE;
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			// The ML is telling us that someone clicked our reserved face. The string portion of the message contains a pipe-delimited
			// list of the following data: face, position, normal, binormal, ST, UV
			if (!IsVisible) return;	// if we're invisible, we don't give the menu
			list TouchData = llParseStringKeepNulls(String, [ "|" ], []);    // Parse the data into a list of the four different parts
			integer TouchFace = (integer)llList2String(TouchData, 0);
			if (TouchFace == MENU_FACE) {	// if it's one of the click faces
				ShowMenu(Id);	// show the menu
				return;
			}
		}
		else if (Number == LM_EXTRA_DATA_GET) {
			// We can stop the timer because we have our data, and we also must have sent ETH_LOCK (because the timer has kicked
			// in at least once).
			llSetTimerEvent(0.0);
			DataReceived = TRUE;
			if (String != "") {
				list Elements = llParseStringKeepNulls(String, [ "^" ], []);
				PresetPtr = (integer)llList2String(Elements, 0);
				SetParticles();
			}
		}
		else if (Number == HUD_API_LOGIN) {
			SetVisibility(TRUE);
		}
		else if (Number == HUD_API_LOGOUT) {
			SetVisibility(FALSE);
		}
		else if (Number == LM_PRIM_SELECTED) {
			integer LinkNum = (integer)String;
			if (LinkNum == llGetLinkNumber()) {	// If we're selected
				IsSelected = TRUE;	// remember this
			}
		}
		else if (Number == LM_PRIM_DESELECTED) {
			// Because our particles will have been overwritten by the
			// LM's selection particle stream (by the Moveable Prim script)
			// we need to reset out particles when we're deselected
			if (IsSelected) SetParticles();
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == MenuAvId) {
			if (Message == "Done") {
				StopListener();
				return;
			}
			integer Which = (integer)Message;
			if (Which > 0) {
				PresetPtr = --Which;
				SetParticles();
				ShowMenu(MenuAvId);
				// Store in ML
				llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_SET, (string)PresetPtr, NULL_KEY);
			}
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_SCALE) SetParticles();
	}
	timer() {
		if (!DataReceived) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, (string)MENU_FACE, NULL_KEY);
		}
		if (MenuTimeout > 0) {
			MenuTimeout--;
			if (MenuTimeout == 0) {
				StopListener();
			}
		}
		if (DataReceived && MenuTimeout == 0) llSetTimerEvent(0.0);	// no need for a timeout
	}
}
// FX particles v0.1