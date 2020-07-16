// ML environment v1.1

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

// v1.1 - new error handler
// v1.0 - version change only
// v0.9 - bug fix (see ML v0.151)
// v0.8 - terrain height/land level wasn't being saved
// v0.7 - better formatting for data sent to ML (use | not \n)
// v0.6 - bug fix (sun position not saving) - improved handling of presets
// v0.5 - tone down the wind
// v0.4 - wait for ML to send us default data
// v0.3 - take default water and sea level heights from config
// v0.2 - fix default water height

integer ENV_RESET = -79301900;
integer ENV_SET_VALUE = -79301901;
integer ENV_STORE_VALUE = -79301902;
integer ENV_STATUS = -79301903;
integer ENV_DONE = -79301904;

integer LM_HUD_STATUS = -405543;
integer LM_PUBLIC_DATA = -405546;

integer EnvironmentalChange;
integer SettingsChanged;
float WaterLevel;
float LandLevel;
float OldLandLevel;
float SunHour;
float WindStrength;
float WindDirection;

float DefaultSeaLevel;
float DefaultLandLevel;

list SunPosValues;

SetEnvironment() {
    if (SettingsChanged) {
        osSetRegionWaterHeight(WaterLevel);
        if (SunHour >= 0.0)
            osSetRegionSunSettings(FALSE, TRUE, SunHour);
        else
            osSetRegionSunSettings(FALSE, FALSE, 0.0);
        osSetWindParam("ConfigurableWind", "avgStrength", WindStrength);
        osSetWindParam("ConfigurableWind", "varStrength", 0.0);
        osSetWindParam("ConfigurableWind", "avgDirection", WindDirection);
        osSetWindParam("ConfigurableWind", "varDirection", 0.0);
    }
    else {
        // Set all settings to defaults
        SunHour = -1.0;
        WaterLevel = DefaultSeaLevel;
        WindStrength = 0.5;
        WindDirection = 0.0;
        osSetRegionWaterHeight(20.0);
        osSetRegionSunSettings(FALSE, FALSE, 0.0);
        DefaultWind();
    }
    llSetTimerEvent(1.0);    // Trigger the sending of the data back to the ML
}
DefaultWind() {
    // Note that ConfigurableWind's random variations don't seem to be working. I don't know why. JFH
    osSetWindParam("ConfigurableWind", "avgStrength", 5.0);
    osSetWindParam("ConfigurableWind", "avgDirection", 0.0);
    osSetWindParam("ConfigurableWind", "varStrength", 5.0);
    osSetWindParam("ConfigurableWind", "varDirection", 360.0);
    osSetWindParam("ConfigurableWind", "rateChange", 1.0);
}
SetSunHour(string Param) {
    float Hour = -1.0;
    if (llSubStringIndex(Param, ".") > -1) {    // If we're passed a number
        Hour = (float)Param;    // just use the number
    }
    else {    // If it's not a number, it's probably a value name (eg "Noon")
        integer Ptr = llListFindList(SunPosValues, [ Param ]);
        if (Ptr > -1) Hour = llList2Float(SunPosValues, Ptr + 1);
    }
    if (Hour > -1.0) SettingsChanged = TRUE;
    SunHour = Hour;
    SetEnvironment();
}
SetTerrainHeight(string Param, integer ReportCompletion) {
    vector MyPos = llGetPos();
    if (Param == "reset") LandLevel = DefaultLandLevel;
    else if (Param == "+") LandLevel++;
    else if (Param == "-") LandLevel--;
    else LandLevel = (float)Param;    // absolute value
    if (LandLevel < 0.0) LandLevel = 0.0;
    else if (LandLevel > MyPos.z) LandLevel = MyPos.z;
    if (OldLandLevel != LandLevel) {
        // Currently only works for whole region
        vector RegionSize = osGetRegionSize();
        integer MaxX = (integer)RegionSize.x;
        integer MaxY = (integer)RegionSize.y;
        integer X;
        integer Y;
        for (X = 0; X < MaxX; X++) {
            for (Y = 0; Y < MaxY; Y++) {
                osSetTerrainHeight(X, Y, LandLevel);
            }
        }
        osTerrainFlush();
        OldLandLevel = LandLevel;
    }
    if (ReportCompletion) llMessageLinked(LINK_ROOT, ENV_DONE, "land", NULL_KEY);
}
ResetAll() {
    SettingsChanged = FALSE;
    SetEnvironment();
    SetTerrainHeight("reset", FALSE);
}

SetStatus(string Type) {
    if (Type == "wind")
        HudStatus("Speed: " + NiceFloat(WindStrength) + "        Direction: " + WindDegrees2Direction(WindDirection));
    else if (Type == "water")
        HudStatus("Sea level: " + (string)llRound(WaterLevel) + "m");
    else if (Type == "land")
        HudStatus("Land level: " + (string)llRound(LandLevel) + "m");
}
string WindDegrees2Direction(float Degrees) {
    if (Degrees == 0.0)            return("W");
    else if (Degrees == 45.0)     return("SW");
    else if (Degrees == 90.0)     return("S");
    else if (Degrees == 135.0)     return("SE");
    else if (Degrees == 180.0)     return("E");
    else if (Degrees == 225.0)     return("NE");
    else if (Degrees == 270.0)     return("N");
    else if (Degrees == 315.0)     return("NW");
    else return("??");
}
float WindDirection2Degrees(string Direction) {
    if (Direction == "N")        return(270.0);
    else if (Direction == "NW")    return(315.0);
    else if (Direction == "W")    return(0.0);
    else if (Direction == "SW")    return(45.0);
    else if (Direction == "S")    return(90.0);
    else if (Direction == "SE")    return(135.0);
    else if (Direction == "E")    return(180.0);
    else if (Direction == "NE")    return(225.0);
    else return(0.0);
}
// Process public data sent by ML
ParsePublicData(string Data) {
    list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
    EnvironmentalChange = (integer)llList2String(Parts, 0);
    DefaultSeaLevel = (float)llList2String(Parts, 1);
    DefaultLandLevel = (float)llList2String(Parts, 2);
}
// Send data to HUD's status bar
HudStatus(string Text) {
    llMessageLinked(LINK_SET, LM_HUD_STATUS, Text, NULL_KEY);
}
SetSunValues() {
    // The values below are the result of experimentation. It doesn't seem linear, but I've
    // gone for characteristics attractive for each setting, based on the default viewer
    // experience. JFH
    SunPosValues = [
        "Dawn", 22.4,
        "Morning", 1.0,
        "Noon", 6.0,
        "Afternoon", 11.0,
        "Dusk", 15.0,
        "Night", 18.0,
        "Reset", -1.0
            ];
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
LogError(string Text) {
    llMessageLinked(LINK_ROOT, -7563234, Text, NULL_KEY);
}
default {
    on_rez(integer Param) { llResetScript(); }
    state_entry() {
        SetSunValues();
    }
    link_message(integer Sender, integer Number, string String, key Id) {
        if (Sender == 1) {    // We only accept commands from the root prim
            if (Number == LM_PUBLIC_DATA) {
                ParsePublicData(String);
                if (!EnvironmentalChange) return;    // Environment isn't enabled for this App/Map
                LandLevel = DefaultLandLevel;
                OldLandLevel = LandLevel;
                SetEnvironment();
                state Normal;
            }
        }
    }
}
state Normal {
    on_rez(integer Param) { llResetScript(); }
    state_entry() {
        ResetAll();
    }
    link_message(integer Sender, integer Number, string String, key Id) {
        if (Sender == 1) {    // We only accept commands from the root prim
            if (Number == LM_PUBLIC_DATA) {
                ParsePublicData(String);
                SetEnvironment();
            }
            else if (Number == ENV_RESET) {
                SettingsChanged = FALSE;
                SetEnvironment();
                SetTerrainHeight("reset", TRUE);
            }
            else if (Number == ENV_SET_VALUE) {
                list Parts = llCSV2List(String);
                string Name = llList2String(Parts, 0);
                string Value = llList2String(Parts, 1);
                integer Quiet = (integer)llList2String(Parts, 2);    // Suppress status messages?
                integer Menu = (integer)llList2String(Parts, 3);    // Is the command coming from the HUD menu?
                if (Name == "waterlevel") {
                    if (Value == "+") {
                        if (++WaterLevel > 60.0) WaterLevel = 60.0;    // arbitrary max to stop craziness
                    }
                    else if (Value == "-") {
                        if (--WaterLevel < 0.0) WaterLevel = 0.0;
                    }
                    else if (Value == "reset") {
                        WaterLevel = 20.0;
                    }
                    else {
                        WaterLevel = (float)Value;
                    }
                    if (!Quiet) SetStatus("water");
                }
                else if (Name == "terrainheight") {
                    SetTerrainHeight(Value, Menu);
                    if (!Quiet) SetStatus("land");
                }
                else if (Name == "sunhour") {
                    SetSunHour(Value);
                }
                else if (Name == "windstrength") {
                    if (Value == "+") {
                        WindStrength += 0.5;
                        if (WindStrength > 60.0) WindStrength = 30.0;    // arbitrary max to stop craziness
                    }
                    else if (Value == "-") {
                        WindStrength -= 0.5;
                        if (WindStrength < 0.0) WindStrength = 0.0;
                    }
                    else if (Value == "reset") {
                        WindStrength = 0.5;
                        WindDirection = 0.0;
                    }
                    if (!Quiet) SetStatus("wind");    // set HUD status
                }
                else if (Name == "winddirection") {
                    WindDirection = WindDirection2Degrees(Value);
                    if (!Quiet) SetStatus("wind");    // set HUD status
                }
                else if (Name == "resetall") {
                    ResetAll();
                }
                else {
                    LogError("Invalid environment command: " + String);
                }
                SettingsChanged = TRUE;
                SetEnvironment();
            }
            else if (Number == ENV_STATUS) {
                SetStatus(String);
            }
        }
    }
    timer() {
        llSetTimerEvent(0.0);
        // Send our data back to the ML, nicely formatted for when it saves a scene
        list Entries = [];    // If unchanged, we don't even need an entry in the scene file
        if (SettingsChanged) {
            Entries += "    WaterLevel: " + NiceFloat(WaterLevel);
            Entries += "    TerrainHeight: " + NiceFloat(LandLevel);
            if (SunHour >= 0.0) {
                string SunHourDesc = NiceFloat(SunHour);
                // But if we have a name for it (eg "Noon"), save the name instead
                integer Ptr = llListFindList(SunPosValues, [ SunHour ]);
                if (Ptr > -1) SunHourDesc = llList2String(SunPosValues, Ptr - 1);
                Entries += "    SunHour: " + SunHourDesc;
            }
            Entries += "    WindStrength: " + NiceFloat(WindStrength);
            Entries += "    WindDirection: " + NiceFloat(WindDirection);
        }
        llMessageLinked(LINK_ROOT, ENV_STORE_VALUE, llDumpList2String(Entries, "|"), NULL_KEY);
    }
}
state Hang {
    on_rez(integer Param) { llResetScript(); }
    changed(integer Change) {
        if (Change & CHANGED_INVENTORY) llResetScript();
    }
}
// ML environment v1.1