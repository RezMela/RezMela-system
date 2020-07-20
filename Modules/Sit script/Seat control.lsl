// Seat control v1.3.0

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

// v1.3.0 - stop "sit" animation
// v1.2 - added "Invisible" and "ClickMenu" options
// v1.1 - fix bug with position/rotation being retained between sits (despite move/rotation)
// v1.0 - fix menu text; send "Click for menu" message

string CONFIG_NOTECARD = "Seat config";

integer NPC_CONTROL_CHANNEL = -72;

integer LM_EXTRA_DATA_SET = -405516;
integer LM_EXTRA_DATA_GET = -405517;
integer LM_LOADING_COMPLETE = -405530;
integer LM_RESERVED_TOUCH_FACE = -44088510;

integer HUD_API_LOGIN = -47206000;
integer HUD_API_LOGOUT = -47206001;

// Moveable prim messages
integer MP_DO_NOT_DELETE 	= -818442500;
integer MP_DELETE_OBJECT	= -818442501;

vector SitTargetPosition;
rotation SitTargetRotation;
integer FirstSit;
vector DefaultPosition;
rotation DefaultRotation;

integer Invisible = FALSE;
integer ClickMenu = TRUE;

list Animations;
integer ANIM_NAME = 0;
integer ANIM_DESC = 1;
integer ANIM_POS = 2;
integer ANIM_ROT = 3;
integer ANIM_STRIDE = 4;
integer AnimationsCount;

string ConfigContents;

// Menu stuff
integer MenuChannel;
integer MenuListener;
key MenuAvId;
integer MenuButtonsPtr;
integer ANIMS_PER_PAGE = 8;
integer CurrentMenu;
integer MENU_MAIN = 1;
integer MENU_ADJUST = 2;

float ADJUST_AMOUNT = 0.04;

string BUT_CLOSE = "Close";
string BUT_PREV = "< Previous";
string BUT_NEXT = "Next >";
string BUT_ADJUST = "[ ADJUST ]";
string BUT_ADJ_LEFT = "Left";
string BUT_ADJ_RIGHT = "Right";
string BUT_ADJ_FORWARD = "Forward";
string BUT_ADJ_BACK = "Back";
string BUT_ADJ_UP = "Up";
string BUT_ADJ_DOWN = "Down";
string BUT_ADJ_DONE = "< Main menu";

key SeatedAvId;
integer SeatedIsNpc;
string CurrentAnimName;
string CurrentAnimDesc;
integer AnimationPtr;

integer MLLinkedUs;
key StopNpcId;

integer AvatarType;
integer AV_TYPE_ANY = 0;
integer AV_TYPE_NPC = 1;
integer AV_TYPE_AGENT = 2;

InitMenu() {
	CurrentMenu = MENU_MAIN;
	MenuButtonsPtr = 0;
}
EndMenu() {
	if (MenuListener) {
		llListenRemove(MenuListener);
		MenuListener = 0;
	}
}
ShowMenu() {
	string MenuText;
	list Buttons;
	MenuChannel = -10000 - (integer)llFrand(1000000);
	MenuListener = llListen(MenuChannel, "", MenuAvId, "");
	if (CurrentMenu == MENU_MAIN) {
		MenuText = "Select animation or option.\n\nCurrent animation: " + CurrentAnimDesc;
		list Anims = [];
		integer Last = MenuButtonsPtr + ANIMS_PER_PAGE;
		if (Last >= AnimationsCount) Last = AnimationsCount;
		integer A;
		for (A = 0; A < Last; A++) {
			integer P = A * ANIM_STRIDE;
			string AnimDesc = llList2String(Animations, P + ANIM_DESC);
			AnimDesc = llGetSubString(AnimDesc, 1, -1);	// strip out initial "!"
			Anims += AnimDesc;
		}
		string PrevButton = " ";
		if (MenuButtonsPtr > 0) PrevButton = BUT_PREV;
		string NextButton = " ";
		if (MenuButtonsPtr < (AnimationsCount - ANIMS_PER_PAGE)) {
			NextButton = BUT_NEXT;
		}
		Buttons = Anims + [
			BUT_ADJUST, PrevButton, BUT_CLOSE, NextButton
				];
	}
	else if (CurrentMenu == MENU_ADJUST) {
		MenuText = "Select option:";
		Buttons = [
			BUT_ADJ_LEFT, BUT_ADJ_RIGHT, " ",
			BUT_ADJ_FORWARD, BUT_ADJ_BACK, " ",
			BUT_ADJ_UP, BUT_ADJ_DOWN, BUT_ADJ_DONE
				];
	}
	Buttons = llList2List(Buttons, -3, -1) + llList2List(Buttons, -6, -4)
		+ llList2List(Buttons, -9, -7) + llList2List(Buttons, -12, -10);
	llDialog(MenuAvId, "\n" + MenuText, Buttons, MenuChannel);
}
ProcessMenu(string Response) {
	llListenRemove(MenuListener);
	MenuListener = 0;
	if (CurrentMenu == MENU_MAIN) {
		if (Response == BUT_CLOSE) {
			EndMenu();
			return;
		}
		else if (Response == BUT_NEXT) {
			MenuButtonsPtr += ANIMS_PER_PAGE;
			if (MenuButtonsPtr > (AnimationsCount - ANIMS_PER_PAGE)) {
				MenuButtonsPtr = AnimationsCount - ANIMS_PER_PAGE;
			}
			if (MenuButtonsPtr < 0) MenuButtonsPtr = 0;
		}
		else if (Response == BUT_PREV) {
			MenuButtonsPtr -= ANIMS_PER_PAGE;
			if (MenuButtonsPtr < 0) MenuButtonsPtr = 0;
		}
		else if (Response == BUT_ADJUST) {
			CurrentMenu = MENU_ADJUST;
		}
		else {	// It's presumably an animation
			integer AnimPtr = llListFindList(Animations, [ "!" + Response ]);
			if (AnimPtr > -1) {
				AnimPtr -= ANIM_DESC;
				AnimPtr /= ANIM_STRIDE;
				StartAnimation(AnimPtr);
			}
		}
	}
	else if (CurrentMenu == MENU_ADJUST) {
		if (Response == BUT_ADJ_DONE) {
			CurrentMenu = MENU_MAIN;
		}
		else {	// if must be a direction
			MoveAvatar(FALSE, AdjustmentVector(Response), ZERO_ROTATION);
		}
	}
	ShowMenu();
}
vector AdjustmentVector(string ButtonText) {
	// Calculate adjustment needed
	vector Adjustment = ZERO_VECTOR;
	if (ButtonText == BUT_ADJ_LEFT)				Adjustment.y = ADJUST_AMOUNT;
	else if (ButtonText == BUT_ADJ_RIGHT)		Adjustment.y = -ADJUST_AMOUNT;
	else if (ButtonText == BUT_ADJ_FORWARD)		Adjustment.x = ADJUST_AMOUNT;
	else if (ButtonText == BUT_ADJ_BACK)		Adjustment.x = -ADJUST_AMOUNT;
	else if (ButtonText == BUT_ADJ_UP)			Adjustment.z = ADJUST_AMOUNT;
	else if (ButtonText == BUT_ADJ_DOWN)		Adjustment.z = -ADJUST_AMOUNT;
	return Adjustment;
}
MoveAvatar(integer Reset, vector AdjustPos, rotation AdjustRot) {
	integer AvLinkNum = GetAvatarLinkNum();
	vector Pos;
	rotation Rot;
	list PrimParams;
	if (Reset) {	// If Reset is set, we work from the original position
		Pos = DefaultPosition;
		Rot = DefaultRotation;
	}
	else {	// otherwise we work from the avatar's current position
		PrimParams = llGetLinkPrimitiveParams(AvLinkNum, [ PRIM_POS_LOCAL, PRIM_ROT_LOCAL ]);
		Pos = llList2Vector(PrimParams, 0);
		Rot = llList2Rot(PrimParams, 1);
	}
	PrimParams = [];
	if (Reset || AdjustPos != ZERO_VECTOR) {
		Pos += (AdjustPos * Rot);
		PrimParams += [ PRIM_POS_LOCAL, Pos ];
	}
	if (Reset || AdjustRot != ZERO_ROTATION) {
		Rot *= AdjustRot;
		PrimParams += [ PRIM_ROT_LOCAL, Rot ];
	}
	if (PrimParams != []) {
		llSetLinkPrimitiveParams(AvLinkNum, PrimParams);
	}
}
// Finds out which link number the avatar has. When an avatar sits, they are
// given a link number greater than the highest in the set - but we have to bear in mind
// other avatars also sitting, as well as possibly the link numbers changing as prims are
// linked/unlinked.
integer GetAvatarLinkNum() {
	integer AvLinkNum;
	if (llGetLinkNumber() == 0) {	// if we're unlinked (testing probably)
		AvLinkNum = 2;
	}
	else {
		AvLinkNum = llGetNumberOfPrims();
		while (llGetLinkKey(AvLinkNum) != SeatedAvId && AvLinkNum > 1) AvLinkNum--;
		if (AvLinkNum <= 1) {
			LogError("Can't find avatar for sit adjustment");
			state Hang;
		}
	}
	return AvLinkNum;
}
// Perform sitting-related activities
CheckSit() {
	key AvatarOnSitTarget = llAvatarOnSitTarget();
	if (AvatarOnSitTarget == NULL_KEY) {	// Nobody is sitting
		if (SeatedAvId != NULL_KEY) {	// Someone was sitting
			if (CurrentAnimName != "") {
				// Stop the animation and tidy up
				llStopAnimation(CurrentAnimName);
				if (osIsNpc(SeatedAvId)) {
					if (!(llGetAgentInfo(SeatedAvId) & AGENT_ON_OBJECT)) {		// if they're not sitting
						// we test sitting because osNpcMoveToTarget() throws a "Object reference
						// not set to an instance of an object" fatal error if they are sitting
						osNpcMoveToTarget(SeatedAvId, llGetPos(), OS_NPC_NO_FLY);
						StopNpcId = SeatedAvId;
						llSetTimerEvent(3.0);
					}
				}
			}
			SeatedAvId = NULL_KEY;
			FirstSit = TRUE;
			SetInvisible(FALSE); // make visible if necessary
			EndMenu();
		}
	}
	else {	// Someone is sitting
		if (SeatedAvId == NULL_KEY) { // Nobody was sitting
			SeatedAvId = AvatarOnSitTarget;
			SeatedIsNpc = osIsNpc(SeatedAvId);
			if (ClickMenu && !SeatedIsNpc) {
				llRegionSayTo(SeatedAvId, 0, "Click for menu");
			}
			llRequestPermissions(SeatedAvId, PERMISSION_TRIGGER_ANIMATION);
		}
		else if (SeatedAvId != AvatarOnSitTarget) { // Changed avatar?!
			// I don't think this is possible, but just in case ...
			if (CurrentAnimName != "") llStopAnimation(CurrentAnimName);
			EndMenu();
			SeatedAvId = AvatarOnSitTarget;
			llRequestPermissions(SeatedAvId, PERMISSION_TRIGGER_ANIMATION);
		}
		SetInvisible(TRUE); // make invisible if necessary
	}
}
HandlePerms(integer Perms) {
	if (SeatedAvId != NULL_KEY) {
		if (llAvatarOnSitTarget() == SeatedAvId) {
			if (Perms & PERMISSION_TRIGGER_ANIMATION) {
				StartAnimation(0);
				InitMenu();
			}
		}
	}
}
StartAnimation(integer pAnimationPtr) {
	// When they first sit, before any adjustments, we need to find their position. This is actually
	// the SitTarget position adjusted (by OpenSim) for the avatar height.
	if (FirstSit) {
		integer AvLinkNum = GetAvatarLinkNum();
		list PrimParams = llGetLinkPrimitiveParams(AvLinkNum, [ PRIM_POS_LOCAL, PRIM_ROT_LOCAL ]);
		DefaultPosition = llList2Vector(PrimParams, 0);
		DefaultRotation = llList2Rot(PrimParams, 1);
		llStopAnimation("sit"); // stop the default "sit" animation
		FirstSit = FALSE;
	}
	if (CurrentAnimName != "") llStopAnimation(CurrentAnimName);
	AnimationPtr = pAnimationPtr;
	integer TablePtr = AnimationPtr * ANIM_STRIDE;
	CurrentAnimName = llList2String(Animations, TablePtr + ANIM_NAME);
	CurrentAnimDesc = llGetSubString(llList2String(Animations, TablePtr + ANIM_DESC), 1, -1);
	vector Pos = (vector)llList2String(Animations, TablePtr + ANIM_POS);
	rotation Rot = (rotation)llList2String(Animations, TablePtr + ANIM_ROT);
	llStartAnimation(CurrentAnimName);
	MoveAvatar(TRUE, Pos, Rot);
}
// We read our config information from a notecard whose name is defined by CONFIG_NOTECARD.
integer ReadConfig() {
	if (llGetInventoryType(CONFIG_NOTECARD) != INVENTORY_NOTECARD) {
		llOwnerSay("Configuration notecard not found: '" + CONFIG_NOTECARD + "'");
		return FALSE;
	}
	ConfigContents = osGetNotecard(CONFIG_NOTECARD);    // Save it for detection of changes in changed()
	// Set config defaults
	SitTargetPosition = <0.0, 0.0, 0.1>;
	SitTargetRotation = ZERO_ROTATION;
	Animations = [];
	Invisible = FALSE;
	ClickMenu = TRUE;
	// Read card
	integer IsOK = TRUE;
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
				if (Equals >= 0) {
					string OName = llStringTrim(llGetSubString(Line, 0, Equals - 1), STRING_TRIM);        // original parameter name
					string Name = llToLower(OName);        // lower-case version for case-independent parsing
					string Value = llStringTrim(llGetSubString(Line, Equals + 1, -1), STRING_TRIM);
					// Interpret name/value pairs
					if (Name == "position") SitTargetPosition = (vector)Value;
					else if (Name == "rotation") SitTargetRotation = llEuler2Rot((vector)Value * DEG_TO_RAD);
					else if (Name == "avatartype") AvatarType = String2AvType(Value, Line);
					else if (Name == "invisible") Invisible = String2Bool(Value);
					else if (Name == "clickmenu") ClickMenu = String2Bool(Value);
					else if (Name == "animation") {
						// Format: Animation = <name>,<button label>
						list Parts = llCSV2List(Value);
						integer PartsCount = llGetListLength(Parts);
						if (PartsCount >= 2) {
							string AnimDesc = llStringTrim(llList2String(Parts, 0), STRING_TRIM);
							string AnimName = llStringTrim(llList2String(Parts, 1), STRING_TRIM);
							if (llGetInventoryType(AnimName) != INVENTORY_ANIMATION) {
								llOwnerSay("Missing animation file '" + AnimName + "'");
							}
							vector AnimPos = ZERO_VECTOR;
							rotation AnimRot = ZERO_ROTATION;
							if (PartsCount >= 3) AnimPos = (vector)llList2String(Parts, 2);
							if (PartsCount >= 4) AnimRot = llEuler2Rot((vector)llList2String(Parts, 3) * DEG_TO_RAD);
							Animations += [ AnimName, "!" + AnimDesc, AnimPos, AnimRot ];	// "!" for lookup uniqueness
						}
						else {
							llOwnerSay("Invalid animation entry: " + Value);
							IsOK = FALSE;
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
	if (Animations == []) {
		integer Count = llGetInventoryNumber(INVENTORY_ANIMATION);
		if (Count == 1) {
			string Name = llGetInventoryName(INVENTORY_ANIMATION, 0);
			Animations += [ Name, "!" + Name, ZERO_VECTOR, ZERO_ROTATION ];	// "!" for lookup uniqueness		
		}
		else {
			llOwnerSay("No animations specified");
			IsOK = FALSE;
		}
	}
	// Check for orphan animation files
	AnimationsCount = llGetListLength(Animations) / ANIM_STRIDE;
	integer AnimationInventoryCount = llGetInventoryNumber(INVENTORY_ANIMATION);
	integer A;
	for (A = 0; A < AnimationInventoryCount; A++) {
		string InventoryName = llGetInventoryName(INVENTORY_ANIMATION, A);
		if (llListFindList(Animations, [ InventoryName ]) == -1) {
			llOwnerSay("Animation not in notecard: '" + InventoryName + "'");
		}
	}
	if (SitTargetPosition == ZERO_VECTOR) SitTargetPosition = <0.0, 0.0, 0.0001>;	// ZERO_VECTOR is not a valid sit position
	llSitTarget(SitTargetPosition, SitTargetRotation);	// this isn't working when values are changed - have to reset the script
	// why, I have no idea -- JFH
	return IsOK;
}
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
integer String2AvType(string Value, string Line) {
	string Str = llToLower(Value);
	if (Str == "npc") return AV_TYPE_NPC;
	else if (Str == "agent") return AV_TYPE_AGENT;
	else if (Str == "any") return AV_TYPE_ANY;
	llOwnerSay("WARNING: Invalid avatar type (should be Any/NPC/Agent): " + Line);
	return AV_TYPE_ANY;
}
// If configured, makes the prim invisible while in use
SetInvisible(integer Invisibility) {
	if (Invisible) { // if we're configured to go invisible
		float Alpha = 1.0;
		if (Invisibility) Alpha = 0.0;
		llSetAlpha(Alpha, ALL_SIDES);
	}
}
// Set context menu and click action according to circumstances
SetContextMenu(integer Interactive) {
	if (Interactive) {
		if (AvatarType == AV_TYPE_NPC) {	// if it's NPC-only
			llSetClickAction(CLICK_ACTION_TOUCH);
		}
		else {	// either agent or NPC
			// so "sit" when unsat, or "touch" when sat upon
			if (SeatedAvId == NULL_KEY) {
				llSetClickAction(CLICK_ACTION_SIT);
			}
			else {
				llSetClickAction(CLICK_ACTION_TOUCH);
			}
		}
	}
	else {	// They're signed into the ML, so default behaviour
		llSetClickAction(CLICK_ACTION_TOUCH);
	}
}
LogError(string Text) {
	llRegionSay(-7563234, Text);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetRemoteScriptAccessPin(8000);    // in case we need it
		if (!ReadConfig()) state Hang;
		MLLinkedUs = FALSE;
		CurrentAnimName = "";
		MenuListener = 0;
		FirstSit = TRUE;
		// Tell moveable prim not to delete the object when we stand up (only
		// applies when the object is rezzed manually and then sat on, but it's
		// annoying enough to warrant a workaround
		llMessageLinked(LINK_THIS, MP_DO_NOT_DELETE, "", NULL_KEY);
		if (llGetStartParameter() == 0) {
			// Manually rezzed, presumably for testing
			state OurControl;
		}
		SetContextMenu(FALSE);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_LOADING_COMPLETE) {
			state MLControl;	// The ML deals with touch events, etc
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			if (!ReadConfig()) state Hang;
		}
	}
}
state MLControl {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		MLLinkedUs = TRUE;
		SetContextMenu(FALSE);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == HUD_API_LOGOUT) {
			state OurControl;
		}
		else if (Number == MP_DELETE_OBJECT) {
			llDie();
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			if (!ReadConfig()) state Hang;
		}
		else if (Change & CHANGED_LINK) {
			CheckSit();
			SetContextMenu(FALSE);
		}
	}
	run_time_permissions(integer Perms) {
		HandlePerms(Perms);
	}
}
state OurControl {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		SeatedAvId = llAvatarOnSitTarget();
		StopNpcId = NULL_KEY;
		SetContextMenu(TRUE);
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_LOADING_COMPLETE) {
			state MLControl;	// The ML deals with touch events, etc
		}
		else if (Number == HUD_API_LOGIN) {
			state MLControl;
		}
		else if (Number == MP_DELETE_OBJECT) {
			if (MLLinkedUs) llDie(); // Only die if we've been used by the ML
		}
	}
	touch_start(integer Num) {
		key TouchAvId = llDetectedKey(0);
		if (SeatedAvId != NULL_KEY) { // if someone's sitting
			if (ClickMenu) { // if click for menu is permitted
				if (SeatedIsNpc) {	// and it's an NPC
					MenuAvId = TouchAvId;
					ShowMenu();
				}
				else {	// non-NPC sitting
					if (TouchAvId == SeatedAvId) { // same as sitting avatar
						MenuAvId = SeatedAvId;
						ShowMenu();
					}
				}
			}
		}
		else { // nobody's sitting
			// Maybe they're trying to seat an NPC
			llRegionSay(NPC_CONTROL_CHANNEL, llKey2Name(TouchAvId) + "%" + (string)llGetLinkKey(llGetLinkNumber()));
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == MenuAvId) {
			ProcessMenu(Message);
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			if (!ReadConfig()) state Hang;
		}
		else if (Change & CHANGED_LINK) {
			CheckSit();
			SetContextMenu(TRUE);
		}
	}
	run_time_permissions(integer Perms) {
		HandlePerms(Perms);
	}
	timer(){
		llSetTimerEvent(0.0);
		if (StopNpcId != NULL_KEY) {
			osNpcStopMoveToTarget(StopNpcId);
			StopNpcId = NULL_KEY;
		}
	}
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) llResetScript();
	}
}
// Seat control v1.3.0