// RezMela environment v0.3

// v0.3 - changes arising from beta
// v0.2 - communicate with control board for save/restore settings

string WATER_PRIM_NAME = "waterlevel";
string SUN_PRIM_PREFIX = "sun ";
string SUN_PRIM_DAWN = "dawn";
string SUN_PRIM_NOON = "noon";
string SUN_PRIM_DUSK = "dusk";
string SUN_PRIM_MIDNIGHT = "midnight";
string WIND_PRIM_NAME = "wind";

// These seem wrong, but they work
// Source: https://www.kitely.com/forums/viewtopic.php?f=26&t=23 (Oren, so it must be right!)
float DAWN = 0.0;
float NOON = 6.0;
float DUSK = 12.0;
float MIDNIGHT = 18.0;

float WIND_STRENGTH_MULTIPLIER = 10.0;

// Link message commands for control board
integer LM_RESET_EVERTHING = 40509;
integer LM_DELEGATED_CLICK = 40510;
integer LM_ENVIRONMENT = 40513;

integer SunPrimPrefixLength;

// Values for various environmental elements
float SunHour;
float WaterLevel;
float WindStrength;
float UserWindDirection;		// 0 is north (as the users see it); direction refers to direction wind blowing (east wind blows west)
float OpenSimWindDirection;		// 0 is east (OpenSim's concept); direction is origin (east wind comes from east)

// Config values
float WaterMin;
float WaterMax;
float WaterDefault;

integer TextboxChannel;
integer TextboxListener;

Reset() {
	SetSun(NOON);
	WaterLevel = WaterDefault;
	osSetRegionWaterHeight(WaterLevel);
	osSetWindParam("ConfigurableWind", "avgStrength", 0.0);
	osSetWindParam("ConfigurableWind", "avgDirection", 0.0);
	osSetWindParam("ConfigurableWind", "varStrength", 0.0);
	osSetWindParam("ConfigurableWind", "varDirection", 0.0);
	osSetWindParam("ConfigurableWind", "rateChange", 10.0);
}
SetSun(float Time) {
	SunHour = Time;
	CallSunFunctions();
}
// Based on Oren's code at https://www.kitely.com/forums/viewtopic.php?f=26&t=23
CallSunFunctions() {
	osSetEstateSunSettings(TRUE, SunHour);
	osSetRegionSunSettings(FALSE, TRUE, SunHour);
}
SetWind(vector TouchST) {
	vector Centre = <0.5, 0.5, 0.0>;
	WindStrength = llVecDist(Centre, TouchST);
	rotation rDirection = llRotBetween(Centre, llVecNorm(TouchST));
	vector vDirection = llRot2Euler(rDirection) * RAD_TO_DEG;

	vector ClickOffset = (TouchST - <0.5, 0.5, 0.0>) * 2.0;		// translate click into offset from prim centre
	WindStrength = llVecMag(ClickOffset) * WIND_STRENGTH_MULTIPLIER;
	vector Norm = llVecNorm(ClickOffset);
	Norm.z = 0.0;
	vector ClickRot = llRot2Euler(llRotBetween(<0,1,0>, ClickOffset)) * RAD_TO_DEG;
	float ClickDirection = ClickRot.z;	// 0 is top
	// For OpenSim, a wind angle of 0 blows in an easterly direction. For us, it's a more sensible northerly direction.
	// Also, OpenSim uses directions the wind blows from (which is correct in terms of, say, an easterly wind, which blows
	// from the east). However, we're concerned here (as users) with the direction the window is blowing in.
	if (ClickDirection < 0.0) {	// if on the right half of the dial (0 to -180 north to south)
		UserWindDirection = -ClickDirection;
		OpenSimWindDirection = ClickDirection + 90.0;
	}
	else {	// on the left half of the dial, it's 0 (north) -> 90 (west) -> 180 (south)
		OpenSimWindDirection = 360.0 - (270.0 - ClickDirection);	// adjusting both for from/to (360) and 0 being east (270)

		UserWindDirection = 360.0 - ClickDirection;
	}
	CallWindFunctions();
}
CallWindFunctions() {
	osSetWindParam("ConfigurableWind", "avgStrength", WindStrength);
	osSetWindParam("ConfigurableWind", "avgDirection", OpenSimWindDirection);
}
// Send current details to control board script (see ParseDetails below)
SendDetails() {
	llMessageLinked(LINK_SET, -LM_ENVIRONMENT, llDumpList2String([
		WaterLevel,
		SunHour,
		WindStrength,
		OpenSimWindDirection
			], "|"), NULL_KEY);
}
// Parse details from control board script, and implement (see SendDetails above)
ParseDetails(list Details) {
	// Parse
	WaterLevel = (float)llList2String(Details, 0);
	SunHour = (float)llList2String(Details, 1);
	WindStrength = (float)llList2String(Details, 2);
	OpenSimWindDirection = (float)llList2String(Details, 3);
	// Implement
	osSetRegionWaterHeight(WaterLevel);
	SetSun(SunHour);
	CallWindFunctions();
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		Reset();
		SunPrimPrefixLength = llStringLength(SUN_PRIM_PREFIX) - 1;
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == LM_DELEGATED_CLICK) {
			// Clicked on a prim - is it one of ours?
			list L = llParseStringKeepNulls(Message, [ "|" ], [ "" ]);
			string PrimName = llList2String(L, 0);
			key AvId = Id;
			string AvName = llKey2Name(AvId);
			if (PrimName == WATER_PRIM_NAME) {
				//				vector TouchST = (vector)llList2String(L, 3);
				//				WaterLevel = WaterMin + ((WaterMax - WaterMin) * TouchST.y);
				//				llOwnerSay(AvName + " sets water height to " + (string)llFloor(WaterLevel) + "m");
				//				osSetRegionWaterHeight(WaterLevel);
				//				SendDetails();		// Send current details to control board script
				llSetTimerEvent(6000.0);
				TextboxChannel = -10000 - (integer)llFrand(100000.0);
				TextboxListener =  llListen(TextboxChannel, "", AvId, "");
				llTextBox(AvId, "\nEnter water height in meters, or blank to cancel", TextboxChannel);
			}
			else if (PrimName == WIND_PRIM_NAME) {
				vector TouchST = (vector)llList2String(L, 3);
				SetWind(TouchST);
				llOwnerSay(AvName + " sets wind to speed " + (string)llFloor(WindStrength) + ", direction " + (string)llFloor(UserWindDirection) + "°");
				SendDetails();		// Send current details to control board script
			}
			else if (llGetSubString(PrimName, 0, SunPrimPrefixLength) == SUN_PRIM_PREFIX) {
				string PositionName = llGetSubString(PrimName, SunPrimPrefixLength + 1, -1);
				if (		PositionName == SUN_PRIM_DAWN) 		SetSun(DAWN);
				else if (	PositionName == SUN_PRIM_NOON)		SetSun(NOON);
				else if (	PositionName == SUN_PRIM_DUSK)		SetSun(DUSK);
				else if (	PositionName == SUN_PRIM_MIDNIGHT)	SetSun(MIDNIGHT);
				llOwnerSay(AvName + " sets sun position to " + PositionName);
				SendDetails();		// Send current details to control board script
			}
		}
		else if (Number == LM_ENVIRONMENT) {	// note that +ve is incoming, -ve is outgoing
			// a specific instruction for us from the control board script
			list L = llParseStringKeepNulls(Message, [ "|" ], [ "" ]);
			string Command = llList2String(L, 0);
			if (Command == "reset") {	// Clear scene
				Reset();
			}
			else if (Command == "config") {		// configuration values
				WaterMin = (float)llList2String(L, 1);
				WaterMax = (float)llList2String(L, 2);
				WaterDefault = (float)llList2String(L, 3);
			}
			else if (Command == "set") {
				ParseDetails(llList2List(L, 1, -1));	// Pass rest of list to parser
			}
		}
		else if (Number == LM_RESET_EVERTHING) {
			Reset();
		}
	}
	timer() {
		// textbox timed out
		llSetTimerEvent(0.0);
		llListenRemove(TextboxListener);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == TextboxChannel) {
			llSetTimerEvent(0.0);
			llListenRemove(TextboxListener);
			if (Message == "") return;	// empty input
			WaterLevel = (float)Message;
			llOwnerSay(llKey2Name(Id) + " sets water height to " + (string)llFloor(WaterLevel) + "m");
			osSetRegionWaterHeight(WaterLevel);
			SendDetails();		// Send current details to control board script
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION_START) {
			SetSun(SunHour);
			osSetRegionWaterHeight(WaterLevel);
			CallWindFunctions();
		}
	}
}
// RezMela environment v0.3