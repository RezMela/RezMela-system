// Use this to get Water jet config data. As changes are made, the equivalent config data is printed in chat.


// Handy's water control v1.3
//
// v1.3 - as v1.2, but PSYS_SRC_BURST_RATE now 0.02 - even better in SL (no point for OpenSim, I think, but changed anyway)
// v1.2 - changed PSYS_SRC_BURST_RATE from 0.0 to 0.05. I don't really understand why, but this makes the spray less stupidly dense on OpenSim, which is slightly understandable (throttling OS's exuberance, as it were,
//			although why the hell this should be different between SL and OS versions of Firestorm *and* Dolphin I have no idea). But not only that, it makes the spray fuller and more attractive on SL!

string SEPARATOR = "/" ;
string ID_STRING = "HWA" ;            // Handy water

string SPRAY_DESC_TAG = "*waterspray*" ;
string FLOW_DESC_TAG = "waterflow" ;
integer FlowDescTagLength ;

string NOTECARD_NAME = "Handy's water data" ;
string NotecardData ;

float ScriptVersion ;
string NOTECARD_README		= "Handy's water READ ME" ;
string SCRIPT_SPRAY_SETUP	= "Handy's water setup (spray)" ;
string SCRIPT_FLOW_SETUP	= "Handy's water setup (flow)" ;
string SCRIPT_WATER_SOUND_SETUP	= "Handy's water setup (sound)" ;
string SCRIPT_CONTROL     	= "Handy's water control" ;

string CreatorKeyPart = "15787b79-8ec1";

integer SpraySetupExists ;
integer MovingWaterSetupExists ;
integer SoundSetupExists ;

key OwnerID ;
integer SprayOn ;
integer FlowOn ;
integer SoundOn ;

integer Booted = FALSE ; 		// did the script boot up, or did it hang for lack of data?

list SprayParticleParams ;
list SprayPreRezParams ;

list TextureIDs ;
list SoundIDs ;

// Data for linked prims
// Spray list is just link numbers
list SprayLinkNums ;
integer SprayLinkCount ;
// Flow list is link number followed by face number
list FlowLinkData ;
integer FlowLinkCount ;

integer Products ;
integer SprayTexturePtr ;
vector SprayColourS ;
vector SprayColourE ;
float SprayAlpha ;
float SpraySize ;
integer SprayDensity ;
float SpraySpread ;        // Spread angle in degrees
float SprayHeight ;    //
integer SprayWind ;		// bool
float SprayLift ;
integer FlowDirection ;
integer FlowFramesX ;
integer FlowFramesY ;
integer FlowRate ;
integer SoundPtr ;
integer SoundVolume ;

// Bitwise values for products
integer PROD_SPRAY = 1 ;
integer PROD_FLOW = 2 ;
integer PROD_SOUND = 4 ;

// Bitwise flags for FlowDirection
integer D_ROTATES = 1 ;
integer D_FLIP = 2 ;

string CreatorHash ;

list CODE_CLEAR 	= [ "/", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "<", ">", ",", "-", "a", "b", "c", "d", "e", "f" ] ;		// use / separator in clear
list CODE_ENCRYPTED	= [ "<", ",", "e", "-", "8", "b", "a", "d", "c", "9", "f", ">", "5", "*", "6", "7", "0", "2", "1", "3", "4" ] ;		// but * in encrypted

integer PLUGIN_WATER_SPRAY_SEND_START	= 717000 ;
integer PLUGIN_WATER_SPRAY_SEND_STOP	= 717001 ;
integer PLUGIN_WATER_FLOW_SEND_START	= 717010 ;
integer PLUGIN_WATER_FLOW_SEND_STOP		= 717011 ;
integer PLUGIN_WATER_SOUND_SEND_START	= 717020 ;
integer PLUGIN_WATER_SOUND_SEND_STOP	= 717021 ;
integer PLUGIN_WATER_SOUND_SEND_VOLUME	= 717025 ;
integer PLUGIN_WATER_SOUND_RECV_VOLUME	= 717026 ;
integer PLUGIN_WATER_RECV_BOOTING		= 717050 ;
integer PLUGIN_WATER_RECV_BOOTED		= 717051 ;

// LMs for water spray
integer LM_HFO_START 		= -8023300 ;
integer LM_HFO_STOP			= -8023301 ;
// LMs for water flow
integer LM_HWA_START 		= -8023400 ;
integer LM_HWA_STOP			= -8023401 ;
integer LM_HWA_SET_TEXTURE	= -8023408 ;
integer LM_HWA_SET_ALPHA	= -8023409 ;
// LMs for water sound
integer LM_HWS_START 		= -8023500 ;
integer LM_HWS_STOP			= -8023501 ;
// LMs for general water stuff
integer LM_WAT_READ_DESC	= -8023600 ;

integer EXTERNAL_CHAT_SPRAY = -450192 ;

integer ReadData()		// returns FALSE if no data found in description
{
	list Params = ReadDescription() ;
	if (Params != [])
	{
		CreatorHash = llList2String(Params, 0) ;

		Products = (integer)llList2String(Params, 1) ;
		SprayTexturePtr = (integer)llList2String(Params, 2) ;
		SprayColourS = (vector)llList2String(Params, 3) ;
		SprayColourE = (vector)llList2String(Params, 4) ;
		SprayAlpha = (float)llList2String(Params, 5) ;
		SprayDensity = (integer)llList2String(Params, 6) ;
		SpraySize = (float)llList2String(Params, 7) ;
		SpraySpread = (float)llList2String(Params, 8) ;
		SprayHeight = (float)llList2String(Params, 9) ;
		SprayWind = (integer)llList2String(Params, 10) ;
		SprayLift = (float)llList2String(Params, 11) ;
		FlowDirection = (integer)llList2String(Params, 12) ;
		FlowRate = (integer)llList2String(Params, 13) ;
		FlowFramesX = (integer)llList2String(Params, 14) ;
		FlowFramesY = (integer)llList2String(Params, 15) ;
		SoundPtr = (integer)llList2String(Params, 16) ;
		SoundVolume = (integer)llList2String(Params, 17) ;

		CalculateParticleParams() ;
		SoundOn = (SoundPtr > -1) ;
		return(TRUE) ;
	}
	else
	{
		return(FALSE) ;
	}
}
GetLinkData()
{
	SprayLinkNums = [] ;
	FlowLinkData = [] ;
	integer PrimCount = llGetNumberOfPrims() ;
	integer P ;
	for (P = 1 ; P <= PrimCount ; P++)
	{
		// Spray link prims are easy
		string LDesc = llToLower(llList2String(llGetObjectDetails(llGetLinkKey(P), [ OBJECT_DESC ]), 0)) ;
		if (llSubStringIndex(LDesc, SPRAY_DESC_TAG) > -1)
			SprayLinkNums += P ;
		// Moving water tags may include face data ("*waterflow1,3,5*" will affect faces 1, 3 and 5)
		integer S  = llSubStringIndex(LDesc, "*" + FLOW_DESC_TAG) ;
		if (S > -1)
		{
			LDesc = llGetSubString(LDesc, S + FlowDescTagLength + 1, -1) ;	// pull out everything after the tag itself
			S = llSubStringIndex(LDesc, "*") ;		// find terminal *
			if (S > 0)								// if there's stuff between the tag and the terminal *
			{
				LDesc = llGetSubString(LDesc, 0, S - 1) ;	// so extract it
				FlowLinkData += [ P, (integer)LDesc ] ;
			}
			else
			{
				FlowLinkData += [ P, ALL_SIDES ] ;
			}
		}
	}
	// Tidy up zero-data cases and get the counts
	if (SprayLinkNums == []) SprayLinkNums += llGetLinkNumber() ;
	SprayLinkCount = llGetListLength(SprayLinkNums) ;
	if (FlowLinkData == []) FlowLinkData += [ llGetLinkNumber(), ALL_SIDES ] ;
	FlowLinkCount = llGetListLength(FlowLinkData) ;
}
SprayControl()
{
	if (Products & PROD_SPRAY)
	{
		if (SprayOn)
		{
			GetLinkData() ;		// we do this here so that we don't need to worry about relinking (as opposed to someone sitting) or resetting or anything
			SetSprayParticles(SprayParticleParams) ;
			llRegionSay(EXTERNAL_CHAT_SPRAY, "on") ;
		}
		else
		{
			GetLinkData() ;		// we do this here so that we don't need to worry about relinking (as opposed to someone sitting) or resetting or anything
			SetSprayParticles(SprayPreRezParams) ;
			llRegionSay(EXTERNAL_CHAT_SPRAY, "off") ;
		}
	}
	else
	{
		SetSprayParticles([]) ;
	}
}
MovingWaterControl()
{
	if ((Products & PROD_FLOW) && FlowOn)
	{
		integer AnimFlags ;
		if (FlowDirection & D_ROTATES)
			AnimFlags = ANIM_ON | SMOOTH | LOOP | ROTATE ;
		else
			AnimFlags = ANIM_ON | SMOOTH | LOOP ;
		float tRate = (float)FlowRate / 500.0 ;
		float Length ;
		if (FlowDirection & D_ROTATES) Length = TWO_PI ; else Length = (float)FlowFramesX ;
		if (FlowDirection & D_FLIP) tRate = -tRate ;
		SetTextureAnim(AnimFlags, Length, tRate) ;

	}
	else
	{
		SetTextureAnim(FALSE, 0.0, 0.0) ;
	}
}
SoundControl()
{
	if (Products & PROD_SOUND)
	{
		llSetSoundQueueing(FALSE);
		llAdjustSoundVolume(0.0);
		llStopSound();
		llSetSoundQueueing(FALSE);
		llAdjustSoundVolume(0.0);
		llStopSound();
		if (SoundOn && SoundVolume > 0)
		{
			if (llGetInventoryNumber(INVENTORY_SOUND) == 1)
				llLoopSound(llGetInventoryName(INVENTORY_SOUND, 0), (float)SoundVolume / 10.0) ;
			else
				llLoopSound(llList2String(SoundIDs, SoundPtr), (float)SoundVolume / 10.0) ;
		}
	}
	else
	{
		llStopSound() ;
	}
}
SetSprayParticles(list Params)
{
	integer P ;
	for (P = 0 ; P < SprayLinkCount ; P++)
	{
		integer LinkNum = llList2Integer(SprayLinkNums, P) ;
		llLinkParticleSystem(LinkNum, Params) ;
	}
}
SetTextureAnim(integer AnimFlags, float Length, float Rate)
{
	integer P ;
	for (P = 0 ; P < FlowLinkCount ; P += 2)
	{
		integer LinkNum = llList2Integer(FlowLinkData, P) ;
		integer Face = llList2Integer(FlowLinkData, P + 1) ;
		llSetLinkTextureAnim(LinkNum, AnimFlags, Face, FlowFramesX, FlowFramesY, 0.0, Length, Rate) ;
	}
}
string NiceVector(vector V) {
	return ("<" + NiceFloat(V.x) + ", " + NiceFloat(V.y) + ", " + NiceFloat(V.z) + ">") ;
}
string NiceRotation(rotation R) {
	return ("<" + NiceFloat(R.x) + "," + NiceFloat(R.y) + "," + NiceFloat(R.z) + "," + NiceFloat(R.s) + ">") ;
}
// Makes a nice string from a float - eg "0.1" instead of "0.100000", or "0.2" instead of "0.199999".
string NiceFloat(float F) {
	float X = 0.0001;
	if (F < 0.0) X = -X;
	string S = (string)(F + X);
	integer P = llSubStringIndex(S, ".");
	S = llGetSubString(S, 0, P + 3);
	while (llGetSubString(S, -1, -1) == "0" && llGetSubString(S, -2, -2) != ".")
		S = llGetSubString(S, 0, -2);
	return(S);
}
CalculateParticleParams()
{
	string ParamTexture = "" ;
	integer InvTextureCount = llGetInventoryNumber(INVENTORY_TEXTURE) ;
	if (InvTextureCount > 0)
	{
		integer I = 0 ;
		for ( ; I < InvTextureCount ; I++)
		{
			string Name = llGetInventoryName(INVENTORY_TEXTURE, I) ;
			if (llSubStringIndex(llToUpper(Name), "SPRAY") > -1) ParamTexture = Name ;
		}
	}
	if (ParamTexture == "") ParamTexture = llList2String(TextureIDs, SprayTexturePtr) ;
	float EndAngle = SpraySpread * DEG_TO_RAD ;
	integer WindFlag = 0 ;
	if (SprayWind) WindFlag = PSYS_PART_WIND_MASK ;

	vector EndColour = SprayColourE ;
	if (SprayColourE.x < 0.0) EndColour = SprayColourS ;

	string PRIVATE_KEY = "wJu=2Ibn2Al-4hWx";

			string Text64 = llStringToBase64(ParamTexture);
			string Key64 = llStringToBase64(PRIVATE_KEY);
			//llOwnerSay("Encoded:\n" + llXorBase64StringsCorrect(Text64, Key64));

	llOwnerSay("Params:\n" +
		"Alpha = " + NiceFloat(SprayAlpha) + "\n" +
		"Color = " + NiceVector(SprayColourS) + "\n" +
		"Size = " + NiceFloat(SpraySize * 2.0) + "\n" +
		"Age = " + NiceFloat(1.0 + SprayHeight * 0.5) + "\n" +
		"Density = " + (string)SprayDensity + "\n" +
		"MinSpeed = " + NiceFloat(SprayHeight * 0.95) + "\n" +
		"MaxSpeed = " + NiceFloat(SprayHeight) + "\n" +
		"Angle = " + NiceFloat(EndAngle) + "\n" +
		"Texture = " + llXorBase64StringsCorrect(Text64, Key64)		
		);
	SprayParticleParams = [
		PSYS_PART_FLAGS,
		PSYS_PART_INTERP_COLOR_MASK |
		PSYS_PART_INTERP_SCALE_MASK |
		PSYS_PART_EMISSIVE_MASK |
		PSYS_PART_FOLLOW_VELOCITY_MASK |
		WindFlag,
		PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
		PSYS_PART_START_ALPHA, SprayAlpha,
		PSYS_PART_END_ALPHA, 0.0,
		PSYS_PART_START_COLOR, SprayColourS,
		PSYS_PART_END_COLOR, EndColour,
		PSYS_PART_START_SCALE, <0.1, 0.1, 0.0>,
		PSYS_PART_END_SCALE, <SpraySize * 2.0, SpraySize * 2.0, 0.0>,
		PSYS_PART_MAX_AGE, 1.0 + SprayHeight * 0.5,
		PSYS_SRC_ACCEL, <0.0, 0.0, -4.0>,
		PSYS_SRC_BURST_PART_COUNT, SprayDensity,
		PSYS_SRC_BURST_RADIUS, SprayLift,
		PSYS_SRC_BURST_RATE, 0.02,		// see notes
		PSYS_SRC_BURST_SPEED_MIN, SprayHeight * 0.95,
		PSYS_SRC_BURST_SPEED_MAX, SprayHeight,
		PSYS_SRC_ANGLE_BEGIN, 0.0,
		PSYS_SRC_ANGLE_END, EndAngle,
		PSYS_SRC_TEXTURE, ParamTexture
			] ;
	SprayPreRezParams = [
		PSYS_PART_MAX_AGE, 2.0,
		PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
		PSYS_PART_FLAGS, PSYS_PART_INTERP_COLOR_MASK,
		PSYS_PART_START_SCALE,  <0.032, 0.032, 0.0>,
		PSYS_PART_END_SCALE, <0.032, 0.032, 0.0>,
		PSYS_SRC_BURST_RATE, 2.0,
		PSYS_SRC_BURST_PART_COUNT, 1,
		PSYS_SRC_TEXTURE, ParamTexture,
		PSYS_PART_START_ALPHA, 0.001,
		PSYS_PART_END_ALPHA, 0.0
			] ;
}
SetTextureUUID(string UUID)
{
	integer P ;
	for (P = 0 ; P < FlowLinkCount ; P += 2)
	{
		integer LinkNum = llList2Integer(FlowLinkData, P) ;
		integer Face = llList2Integer(FlowLinkData, P + 1) ;
		llSetLinkTexture(LinkNum, UUID, Face) ;
	}
}
SetTextureAlpha(string sAlpha)
{
	float fAlpha = 1 - ((float)sAlpha / 100.0) ;
	integer P ;
	for (P = 0 ; P < FlowLinkCount ; P += 2)
	{
		integer LinkNum = llList2Integer(FlowLinkData, P) ;
		integer Face = llList2Integer(FlowLinkData, P + 1) ;
		llSetLinkAlpha(LinkNum, fAlpha, Face) ;
	}
}
integer CheckAllowed(key ID)
{
	return(ID == OwnerID) ;
}
string GetCreatorHash()
{
	return(llGetSubString(llList2String(llGetObjectDetails(llGetKey(), [ OBJECT_CREATOR ]), 0), 3, 6))  ;
}
list ReadDescription()
{
	string Desc ;
	if (NotecardData != "")
		Desc = NotecardData ;
	else
		Desc = llGetObjectDesc() ;
	list Params = llParseStringKeepNulls(Desc, [ SEPARATOR ], []) ;
	if (llList2String(Params, 0) == ID_STRING)
	{
		string Str = Decode(llList2String(Params, 1)) ;
		return(llParseStringKeepNulls(Str, [ SEPARATOR ], [])) ;
	}
	else
	{
		return([]) ;
	}
}
list ExtractVersionNumber(string ScriptName)
{
	integer I ;
	integer L = llStringLength(ScriptName) ;
	for (I = L - 1 ; llGetSubString(ScriptName, I, I) != "v" && I > 0 ; I--) {}
	return [ llGetSubString(ScriptName, 0, I - 1), (float)llGetSubString(ScriptName, I + 1, -1) ] ;
}
integer ScriptCount(string RootName)		// given "script a", will count "script a v1.0", etc
{
	integer Count = 0 ;
	integer N = llGetInventoryNumber(INVENTORY_SCRIPT) ;
	integer S ;
	for (S = 0 ; S < N ; S++)
	{
		string Name = llGetInventoryName(INVENTORY_SCRIPT, S) ;
		if (llGetSubString(Name, 0, llStringLength(RootName) -1) == RootName)	Count++ ;
	}
	return(Count) ;
}
string Decode(string Encrypted)
{
	integer L = llStringLength(Encrypted) ;
	integer P ;
	string C ;
	string S = "" ;
	for (P = 0 ; P < L ; P++)
	{
		C = llGetSubString(Encrypted, P, P) ;
		integer Pos = llListFindList(CODE_ENCRYPTED, [ C ]) ;
		if (Pos > -1) C = llList2String(CODE_CLEAR, Pos) ;
		S += C ;
	}
	return(S) ;
}
string ShortFloat(float F)
{
	string S = (string)F ;
	integer P = llSubStringIndex(S, ".") ;
	S = llGetSubString(S, 0, P + 3) ;
	while(llGetSubString(S, -1, -1) == "0" && llGetSubString(S, -2, -2) != ".")
		S = llGetSubString(S, 0, -2) ;
	if (llGetSubString(S, 0, 1) == "0.") S = llGetSubString(S, 1, -1) ;
	return(S) ;
}
string ShortVector(vector V)
{
	return ("<" + ShortFloat(V.x) + "," + ShortFloat(V.y) + "," + ShortFloat(V.z) + ">") ;
}
default
{
	on_rez(integer Param)
	{
		llResetScript() ;
	}
	state_entry()
	{
		llSetRemoteScriptAccessPin(-407039) ;

		if (llGetInventoryType(NOTECARD_README) == INVENTORY_NOTECARD) state Hang ;
		string ScriptName = llGetScriptName() ;
		if (llGetSubString(ScriptName, 0, llStringLength(SCRIPT_CONTROL) -1) != SCRIPT_CONTROL)
		{
			llOwnerSay("Wrong script name: " + ScriptName) ;
			state Hang ;
		}
		list VersionDetails = ExtractVersionNumber(ScriptName) ;
		string ScriptNameStub = llList2String(VersionDetails, 0) ;
		ScriptVersion = llList2Float(VersionDetails, 1) ;
		if (ScriptVersion == 0.0) llOwnerSay("Cannot determine script version number") ;
		// Check for older versions of script
		if (llGetInventoryNumber(INVENTORY_SCRIPT) > 1)
		{
			integer ScriptsCount = llGetInventoryNumber(INVENTORY_SCRIPT) ;
			integer I ;
			for (I = 0 ; I < ScriptsCount ; I ++)
			{
				string N = llGetInventoryName(INVENTORY_SCRIPT, I) ;
				list L = ExtractVersionNumber(N) ;
				string NS = llList2String(L, 0) ;
				float V = llList2Float(L, 1) ;
				if (NS == ScriptNameStub)
				{
					if (V < ScriptVersion)
					{
						llRemoveInventory(N) ;
						llOwnerSay("Upgraded.") ;
						I-- ;
					}
				}
			}
		}
		if (ScriptCount(SCRIPT_CONTROL) != 1)
		{
			llOwnerSay("Too many '" + SCRIPT_CONTROL + "' scripts in prim contents!") ;
			state Hang ;
		}
		FlowDescTagLength = llStringLength(FLOW_DESC_TAG) ;
		TextureIDs = [
			"52ff69a0-a8de-44e5-b509-eceac1274f3b",	// natural (medium)
			"166ba400-a1d0-4e34-be16-718d807f1953", // natural large
			"ca46a543-fd87-4ea3-9070-de4215f29c2a",	// natural fine
			"440b297c-13f2-4acf-a130-716cd152489d", // natural extra large
			"36154bc6-0a30-4058-a2f1-4b682e5e4455",	// natural finest
			"28eca0da-15fa-490c-b838-0eb4a51edb6f", // plain large
			"9febff8d-c5b2-48c4-8509-4a656d1405fd", // plain medium
			"c0b1c75e-c257-408f-84ba-408a150aa8ae", // plain small
			NULL_KEY, // blobs
			"86180739-05a1-41f6-b46c-0dcb25567840", // softbrush large
			"57945d1b-963e-4d3a-acf1-9c04009543ef", // softbrush medium
			"c900497d-2410-45ca-9a90-6db9bccc1feb",	// softbrush small
			"32d6383b-5951-4186-b87a-81b25e3c5201", // clouds
			"8c1bfacb-db7c-410f-b3be-0d5d92470b9b", // mist
			"be038a2d-4457-4119-9f14-97ff1aeb03df", // cluster L
			"87583ee4-8506-4bd0-910e-41a047ead37d", // cluster S
			"a23e5b26-90a7-4149-8632-94b15df723d9", // lines
			"e47b77ad-5e74-4537-98c8-e4bc4ca0aa01", // long drops
			"a7c5bba7-538b-47c6-9a69-1fa7e0fae12c", // wave L (squiggle)
			"b0283457-c065-4324-96ba-bdbc042b3213",	// wave S
			"4b23c55f-4348-4c62-9b72-18752ec2df46", // bubbles
			"559011fa-c0f3-440d-941a-06667ecdfdac", // stars
			"6b08e779-0067-478c-8841-8ce37abd032f" // rainbow
				] ;
		SoundIDs = [
			// Ws
			"b6d3ee48-156b-42d7-a107-43f89853461c", // 1  Chadney water
			"d7b04c06-6738-41c9-97b3-a3775472a9bc", // 2  Filling bath
			"cc3baaab-d59c-46a9-96f3-17dd6123f55a", // 3  Film water sink
			"8002c897-8903-4d9a-aaee-3961fa29d4bd", // 4  Guysborough water
			"390d09ed-9f3e-4a49-90d4-646cbe83f206", // 5  Kolezan water stream
			"4bf731aa-c53c-41e9-bb77-5c02fc35d939", // 6  Pewits water
			"5e5181b8-52c4-4750-b7ec-1fdbb68f814d", // 7  Tiny pouring water
			"3ef6843a-c409-469c-a276-ead78802baae", // 8  Torrent water
			"ee8e514f-0c49-4d11-93e8-54e0abb6ac6d", // 9  Water pipe
			"2574e695-61f4-45ca-95b3-49c8cfcc7367", // 10 Water poured into jug
			"bb0b5750-f855-4b9a-996f-8dc775d5b338", // 11 Water sink
			// Fs
			"97d94b6d-a187-44bb-8073-5c652e5b0638",	// Heron sound
			"3dd229c0-668e-49e9-aa7b-7ac21903c6f5",	// stone waterfall
			"aaec4d5f-d4de-47af-93e0-dacba5c29d50",	// Attenborough
			"3c7f2952-baa6-419f-a793-3f0b44e35078",	// rippling water
			"f5769570-ddb0-493b-9159-60444d93cc84",	// water over rock
			"eafd86bd-1029-4ef3-9197-321730147cb8" 	// Saas Fee
				] ;
		state Bootup ;
	}
}
state Bootup
{
	on_rez(integer Param)
	{
		llResetScript() ;
	}
	state_entry()
	{
		NotecardData = "" ;
		llMessageLinked(LINK_SET, PLUGIN_WATER_RECV_BOOTING, "", NULL_KEY) ;
		if (llGetInventoryType(NOTECARD_NAME) == INVENTORY_NOTECARD)	// data is in notecard
		{
			llGetNotecardLine(NOTECARD_NAME, 0) ;
			return ;
		}
		if (!ReadData()) state Hang ;
		state Bootup2 ;
	}
	dataserver(key Requested, string Data)
	{
		NotecardData = llStringTrim(Data, STRING_TRIM) ;
		if (!ReadData())
		{
			llOwnerSay("Sorry, invalid notecard format") ;
			state Hang ;
		}
		state Bootup2 ;
	}
}
state Bootup2
{
	on_rez(integer Param)
	{
		state Bootup ;
	}
	state_entry()
	{
		if (CreatorHash != GetCreatorHash())		// differing creators
		{
			llOwnerSay("Invalid prim details!") ;
			state Hang ;
		}
		OwnerID = llGetOwner() ;
		GetLinkData() ;
		SpraySetupExists = MovingWaterSetupExists = SoundSetupExists = FALSE ;
		integer N = llGetInventoryNumber(INVENTORY_SCRIPT) ;
		integer S ;
		for (S = 0 ; S < N ; S++)
		{
			string Name = llGetInventoryName(INVENTORY_SCRIPT, S) ;
			if (llGetSubString(Name, 0, llStringLength(SCRIPT_SPRAY_SETUP) -1) == SCRIPT_SPRAY_SETUP) SpraySetupExists = TRUE ;
			else if (llGetSubString(Name, 0, llStringLength(SCRIPT_FLOW_SETUP) -1) == SCRIPT_FLOW_SETUP) MovingWaterSetupExists = TRUE ;
			else if (llGetSubString(Name, 0, llStringLength(SCRIPT_WATER_SOUND_SETUP) -1) == SCRIPT_WATER_SOUND_SETUP) SoundSetupExists = TRUE ;
		}
		SprayOn = FlowOn = TRUE ;
		llMessageLinked(LINK_SET, PLUGIN_WATER_RECV_BOOTED, "", NULL_KEY) ;
		Booted = TRUE ;
		//llOwnerSay("Memory (control): " + (string)llGetUsedMemory()) ;
		llSetMemoryLimit(55000) ;
		state Main ;
	}
}
state Main
{
	on_rez(integer Param)
	{
		state Bootup ;
	}
	state_entry()
	{
		llSetTimerEvent(0.0) ;
		GetLinkData() ;		// we do this here so that we don't need to worry about relinking (as opposed to someone sitting) or resetting or anything
		llMessageLinked(LINK_SET, PLUGIN_WATER_SOUND_RECV_VOLUME, (string)SoundVolume, NULL_KEY) ;
		SprayControl() ;
		MovingWaterControl() ;
		SoundControl() ;
		llSetTimerEvent(20.0) ;
	}
	timer()
	{
		llRegionSay(-407039, "Water") ;
	}
	link_message(integer Sender, integer Number, string Message, key ID)
	{
		// Remote control of fountain spray
		if (!SprayOn && (Number == LM_HFO_START || Number == PLUGIN_WATER_SPRAY_SEND_START))
		{
			SprayOn = TRUE ;
			SprayControl() ;
		}
		else if (SprayOn && (Number == LM_HFO_STOP || Number == PLUGIN_WATER_SPRAY_SEND_STOP))
		{
			SprayOn = FALSE ;
			SprayControl() ;
		}
		// Remote control of water flow
		else if (!FlowOn && (Number == LM_HWA_START  || Number == PLUGIN_WATER_FLOW_SEND_START))
		{
			FlowOn = TRUE ;
			MovingWaterControl() ;
		}
		else if (FlowOn && (Number == LM_HWA_STOP || Number == PLUGIN_WATER_FLOW_SEND_STOP))
		{
			FlowOn = FALSE ;
			MovingWaterControl() ;
		}
		// Remote control of water sound
		else if (!SoundOn && (Number == LM_HWS_START || Number == PLUGIN_WATER_SOUND_SEND_START))
		{
			if (SoundPtr > -1) SoundOn = TRUE ;
			SoundControl() ;
		}
		else if (SoundOn && (Number == LM_HWS_STOP || Number == PLUGIN_WATER_SOUND_SEND_STOP))
		{
			SoundOn = FALSE ;
			SoundControl() ;
		}
		else if (Number == PLUGIN_WATER_SOUND_SEND_VOLUME)
		{
			SoundVolume = (integer)Message ;
			SoundControl() ;
		}
		// Control from setup scripts
		else if (Number == LM_WAT_READ_DESC)
		{
			if (!ReadData()) state Hang ;
			state ReloadMain ;
		}
		else if (Number == LM_HWA_SET_TEXTURE)	SetTextureUUID(Message) ;
		else if (Number == LM_HWA_SET_ALPHA)	SetTextureAlpha(Message) ;
	}
	changed(integer Change)
	{
		if (Change & (CHANGED_OWNER | CHANGED_INVENTORY | CHANGED_LINK)) state Bootup ;
	}
}
state ReloadMain { state_entry() { state Main ; } }
state Hang
{
	on_rez(integer Param)
	{
		state Bootup ;
	}
	link_message(integer Sender, integer Number, string Message, key ID)
	{
		if (Number == LM_WAT_READ_DESC)
		{
			ReadData() ;
			if (Booted) state ReloadMain ; else state Bootup ;
		}
	}
	changed(integer Change)
	{
		if (Change & (CHANGED_OWNER | CHANGED_INVENTORY | CHANGED_LINK)) llResetScript() ;
	}
}
// Handy's water control v1.3