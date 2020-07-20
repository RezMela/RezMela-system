// Audio source v0.1

// See here for YouTube parameters: http://www.javascriptkit.com/dhtmltutors/youtube-api-lightbox2.shtml

string CONFIG_NOTECARD = "Audiosource config";

string Url;
integer Face;

integer RegionAgentCount;	// number of avatars in the region

Play() {
	llClearPrimMedia(ALL_SIDES);
	list MediaParams = [
		PRIM_MEDIA_AUTO_PLAY, TRUE,
		PRIM_MEDIA_CURRENT_URL, Url,
		PRIM_MEDIA_HEIGHT_PIXELS, 64,
		PRIM_MEDIA_WIDTH_PIXELS, 64
			];
	llSetPrimMediaParams(Face, MediaParams);
	llSetPrimMediaParams(Face, MediaParams);
}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
// Non-standard - this one needs to read lines like "url = blah=3" and extract "url" and "blah=3" as lhs and rhs
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	integer IsOK = TRUE;
	// Set config defaults
	Face= 0;
	integer Lines = osGetNumberOfNotecardLines(CONFIG_NOTECARD);
	integer I;
	for(I = 0; I < Lines; I++) {
		string Line = osGetNotecardLine(CONFIG_NOTECARD, I);
		integer Comment = llSubStringIndex(Line, "//");
		if (Comment != 0) {	// Not a complete comment line
			if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);	// strip from comments characters onwards
			if (llStringTrim(Line, STRING_TRIM) != "") {	// if there's something left after comments are removed
				// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
				integer E = llSubStringIndex(Line, "=");

				if (E > -1) {	// so there is a "X = Y" kind of syntax
					string OName = llStringTrim(llGetSubString(Line, 0, E - 1), STRING_TRIM);		// original parameter name
					string Name = llToLower(OName);		// lower-case version for case-independent parsing
					string Value = llStringTrim(llGetSubString(Line, E + 1, -1), STRING_TRIM);
					// Interpret name/value pairs
					if (Name == "url") Url = Value;
					else if (Name == "face") Face = (integer)Value;
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
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		state Boot;
	}
}
state Boot {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llClearPrimMedia(ALL_SIDES);
		if (ReadConfig()) {
			state Normal;
		}
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		RegionAgentCount = llGetRegionAgentCount();
		llSetTimerEvent(5.0);
		Play();
	}
	timer() {
		integer Rac = llGetRegionAgentCount();
		if (Rac > RegionAgentCount) {	// if someone has entered the region
			Play();
		}
		RegionAgentCount = Rac;
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			state Boot;
		}
		if (Change & CHANGED_REGION_START) {
			Play();
		}
	}
}
// Audio source v0.1