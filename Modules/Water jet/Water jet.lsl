// Water jet v1.1

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

// v1.1 - restore particles after deselection

string CONFIG_NOTECARD = "Water jet config";
string PRIVATE_KEY = "wJu=2Ibn2Al-4hWx";

// From ML
integer LM_PRIM_DESELECTED = -405501;    // A prim has been deselected

float ORIGINAL_Z_HEIGHT = 0.5;	// original size of prim

// Particle params
float Alpha;
vector Color;
float Size;
float Age;
integer Density;
float MinSpeed;
float MaxSpeed;
float Angle;
key Texture;
key Sound;
float SoundVolume;

ReadConfig() {
	Alpha = 0.55;
	Color = <1.0, 1.0, 1.0>;
	Size = 0.8;
	Age = 5.75;
	Density = 40;
	MinSpeed = 9.025;
	MaxSpeed = 9.5;
	Angle = 0.061;
	Texture = "1b65c192-fa32-7489-f0a0-50e04ba13023";
	Sound = NULL_KEY;
	SoundVolume = 0.6;
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return;
	}
	string EncodedTexture = "";
	string EncodedSound = "";
	string ConfigContents = osGetNotecard(CONFIG_NOTECARD);	// Set config defaults
	list Lines = llParseStringKeepNulls(ConfigContents, [ "\n" ], []);
	integer LineCount = llGetListLength(Lines);
	integer I;
	for(I = 0; I < LineCount; I++) {
		string Line = llList2String(Lines, I);
		integer Comment = llSubStringIndex(Line, "//");
		if (Comment != 0) {    // Not a complete comment line
			if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);    // strip from comments characters onwards
			if (llStringTrim(Line, STRING_TRIM) != "") {    // if there's something left after comments are removed
				// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
				integer Equals = llSubStringIndex(Line, "=");
				if (Equals > -1) {    // so there is a "X = Y" kind of syntax
					string OName = llStringTrim(llGetSubString(Line, 0, Equals - 1), STRING_TRIM);        // original parameter name
					string Name = llToLower(OName);        // lower-case version for case-independent parsing
					string Value = llStringTrim(llGetSubString(Line, Equals + 1, -1), STRING_TRIM);
					// Interpret name/value pairs
					if (Name == "alpha") Alpha = (float)Value;
					else if (Name == "color") Color = (vector)Value;
					else if (Name == "size") Size = (float)Value;
					else if (Name == "age") Age = (float)Value;
					else if (Name == "density") Density = (integer)Value;
					else if (Name == "minspeed") MinSpeed = (float)Value;
					else if (Name == "maxspeed") MaxSpeed = (float)Value;
					else if (Name == "angle") Angle= (float)Value;
					else if (Name == "texture") EncodedTexture = (key)Value;
					else if (Name == "sound") EncodedSound = (key)Value;
					else if (Name == "soundvolume") SoundVolume = (float)Value;
					else llOwnerSay("Invalid keyword in config file: '" + OName + "'");
				}
				else {
					llOwnerSay("Invalid line in config file: " + Line);
				}
			}
		}
	}
	if (EncodedTexture != "") {
		// We have to use llXorBase64StringsCorrect because llXorBase64 isn't available in OpenSim
		string Key64 = llStringToBase64(PRIVATE_KEY);
		string Texture64 = llXorBase64StringsCorrect(EncodedTexture, Key64);
		Texture = llBase64ToString(Texture64);
	}
	if (EncodedSound != "") {
		// We have to use llXorBase64StringsCorrect because llXorBase64 isn't available in OpenSim
		string Key64 = llStringToBase64(PRIVATE_KEY);
		string Sound64 = llXorBase64StringsCorrect(EncodedSound, Key64);
		Sound = llBase64ToString(Sound64);
	}
}
MakeJet() {
	vector ObjectSize = llGetScale();
	float SizeFactor = ObjectSize.z / ORIGINAL_Z_HEIGHT;
	list ParticleParams = [
		PSYS_PART_FLAGS,
		PSYS_PART_INTERP_COLOR_MASK |
		PSYS_PART_INTERP_SCALE_MASK |
		PSYS_PART_EMISSIVE_MASK |
		PSYS_PART_FOLLOW_VELOCITY_MASK,
		PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
		PSYS_PART_START_ALPHA, Alpha,
		PSYS_PART_END_ALPHA, 0.0,
		PSYS_PART_START_COLOR, Color,
		PSYS_PART_END_COLOR, Color,
		PSYS_PART_START_SCALE, <0.1 * SizeFactor, 0.1 * SizeFactor, 0.0>,
		PSYS_PART_END_SCALE, <Size * SizeFactor, Size * SizeFactor, 0.0>,
		PSYS_PART_MAX_AGE, Age * SizeFactor,
		PSYS_SRC_ACCEL, <0.0, 0.0, -4.0 * SizeFactor>,
		PSYS_SRC_BURST_PART_COUNT, Density,
		PSYS_SRC_BURST_RADIUS, 0.0,
		PSYS_SRC_BURST_RATE, 0.02,		// see notes
		PSYS_SRC_BURST_SPEED_MIN, MinSpeed * SizeFactor,
		PSYS_SRC_BURST_SPEED_MAX, MaxSpeed * SizeFactor,
		PSYS_SRC_ANGLE_BEGIN, 0.0,
		PSYS_SRC_ANGLE_END, Angle,
		PSYS_SRC_TEXTURE, Texture
		];
	llParticleSystem(ParticleParams);
	// In an old post on SLUniverse (deleted when SLU switched to new forums), these steps
	// were recommended to ensure that the sound system was cleared out. It's always worked
	// in my experience, circumventing a viewer bug. -- JFH
	llSetSoundQueueing(FALSE);
	llAdjustSoundVolume(0.0);
	llStopSound();
	llSetSoundQueueing(FALSE);
	llAdjustSoundVolume(0.0);
	llStopSound();
	if (Sound != NULL_KEY) {
		// More viewer bug circumvention.
		// Without the llPlaySound lines, changing the volume after the sound has started
		// causes the sound to stop. -- JFH
		// See: http://opensimulator.org/mantis/view.php?id=7186
		llPlaySound(Sound, SoundVolume);
		llPlaySound(Sound, SoundVolume);
		llPlaySound(Sound, SoundVolume);
		llPlaySound(Sound, SoundVolume);
		llLoopSound(Sound, SoundVolume);
	}
}

default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		ReadConfig();
		MakeJet();
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			ReadConfig();
			MakeJet();
		}
		if (Change & CHANGED_SCALE) {
			MakeJet();
		}
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		// When this prim is selected, the ML generates a particle stream to connect the prim to the user's avatar.
		// This overrides the particles we're generating, so when they deselect our prim we need to restore the
		// water stream.
		if (Number == LM_PRIM_DESELECTED) {
			if ((integer)Text == llGetLinkNumber()) { // Text contains link number of deselected prim
				MakeJet();
			}
		}
	}
}

// Water jet v1.1