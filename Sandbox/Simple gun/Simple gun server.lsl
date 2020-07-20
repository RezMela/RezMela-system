// Simple gun server v0.2

integer SIMPLE_GUN_CHANNEL = -93304424900;
string CONFIG_NOTECARD = "Simple gun server config";

integer PlayerDeathTime;	// time before player character death expires
integer NpcDeathTime;	// time before NPC death expires
string DeathAnimation;

list AnimatedAvatars = [];	// [ integer TimeAnimated, boolean IsNpc, key Uuid ]
integer AA_TIME = 0;
integer AA_IS_NPC = 1;
integer AA_UUID = 2;
integer AA_STRIDE = 3;

ReadNotecard() {
	// Set defaults
	PlayerDeathTime = 10000000;		// if not specified, death is effectively unlimited duration
	NpcDeathTime = 10000000;
	DeathAnimation = llGetInventoryName(INVENTORY_ANIMATION, 0);
	// Read card
	integer Lines = osGetNumberOfNotecardLines(CONFIG_NOTECARD);
	integer I;
	for(I = 0; I < Lines; I++) {
		string Line = osGetNotecardLine(CONFIG_NOTECARD, I);
		integer Comment = llSubStringIndex(Line, "//");
		if (Comment != 0) {	// Not a complete comment line
			if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);	// strip from comments character onwards
			if (llStringTrim(Line, STRING_TRIM) != "") {
				// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
				list L = llParseStringKeepNulls(Line, [ "=" ], [ ]);
				if (llGetListLength(L) == 2) {	// so there is a "X = Y" kind of syntax
					string OName = llStringTrim(llList2String(L, 0), STRING_TRIM);		// original parameter name
					string Name = llToLower(OName);		// lower-case version for case-independent parsing
					string Value = llStringTrim(llList2String(L, 1), STRING_TRIM);
					// Interpret name/value pairs
					if (Name == "playerdeathtime") PlayerDeathTime = (integer)Value;
					else if (Name == "npcdeathtime") NpcDeathTime = (integer)Value;
					else if (Name == "deathanimation") DeathAnimation = StripQuotes(Value, Line);
					else {
						llOwnerSay("Invalid line in '" + CONFIG_NOTECARD + "': " + Line);
					}
				}
			}
		}
	}
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
	on_rez(integer Param) {
		llResetScript();
	}
	state_entry() {
		ReadNotecard();
		llListen(SIMPLE_GUN_CHANNEL, "", NULL_KEY, "");
		llSetTimerEvent(2.0);	// this can be changed without affecting the timer logic, but <1 second is needless
	}
	listen(integer Channel, string Name, key FromId, string Text) {
		if (Channel == SIMPLE_GUN_CHANNEL) {
			key TargetUuid = (key)Text;
			integer IsNpc = osIsNpc(TargetUuid);
			if (DeathAnimation != "") {
				if (IsNpc) {
					osNpcPlayAnimation(TargetUuid , DeathAnimation);
				}
				else {
					osAvatarPlayAnimation(TargetUuid , DeathAnimation);
				}
			}
			AnimatedAvatars += [ llGetUnixTime(), IsNpc, TargetUuid ];	// store details so we can stop animating them later
		}
	}
	timer() {
		integer CutoffTime;
		integer Len = llGetListLength(AnimatedAvatars);
		if (Len) {
			list NewAnimatedAvatars = [];
			integer I;
			for(I = 0; I < Len; I += AA_STRIDE) {
				integer Time = llList2Integer(AnimatedAvatars, I + AA_TIME);
				integer IsNpc = llList2Integer(AnimatedAvatars, I + AA_IS_NPC);
				if (IsNpc)
					CutoffTime = llGetUnixTime() - NpcDeathTime;
				else
					CutoffTime = llGetUnixTime() - PlayerDeathTime;
				if (Time < CutoffTime) {	// animation expired
					key Uuid = llList2Key(AnimatedAvatars, I + AA_UUID);
					if (llKey2Name(Uuid) != "") {	// if they're still in the region
						if (IsNpc)
							osNpcStopAnimation(Uuid, DeathAnimation);
						else
							osAvatarStopAnimation(Uuid, DeathAnimation);
					}
				}
				else {	// animation not expired, carry table entry forwards
					NewAnimatedAvatars += llList2List(AnimatedAvatars, I, I + AA_STRIDE - 1);
				}
			}
			AnimatedAvatars = NewAnimatedAvatars;
		}
	}
	changed(integer Change)	{
		if (Change & (CHANGED_OWNER | CHANGED_INVENTORY) )
			llResetScript();
	}
}
// Simple gun server v0.2