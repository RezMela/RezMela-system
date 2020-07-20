// NPC server v1.3.0

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

// v1.3.0 - detect users in region and delete NPCs if none
// v1.2 - take MaxAvatars from ML public data
// v1.1 - send attachment to NPC

//integer NPC_SERVER_CHANNEL = -84271920;

integer NPC_CONTROL_CHANNEL = -72; // Can't change this for a more unique number without changing all seats

integer NPC_DESELECT = -6192910; // Link message for "deselect all" for this user

integer LM_RESET = -405535;    // Reset message from ML
integer LM_PUBLIC_DATA = -405546; // Public data from ML

float TIMER_BUSY = 2.0;    // Timer when following or loading NPCs
float TIMER_IDLE_ALONE = 15.0; // Timer when idle (no users in region)
float TIMER_IDLE_NOT_ALONE = 60.0; // Timer when idle (users in region)

float FOLLOW_LIMIT = 60.0;   // Approximate limit (lower bound) of llMoveToTarget
float FOLLOW_RANGE = 1.0;   // Meters away that we stop walking towards a point

// Table of NPCs currently active
list NpcTable = [];
integer NPC_ID                 = 0; // UUID of NPC (keep this as first field)
integer NPC_CREATOR_ID        = 1;
integer NPC_ATTACHMENT_ID    = 2;
integer NPC_SELECTED_ID        = 3;
integer NPC_SEPARATOR        = 4; // "F" to make it easy to search on user IDs
integer NPC_FOLLOWED_ID        = 5;
integer NPC_SEAT_ID            = 6;	// UUID of object NPC is sitting on, or NULL_KEY if not sitting
integer NPC_STRIDE            = 7;
integer NpcTableCount = 0;

// List of NPCs we've not heard back from
list WaitingNpcs;    // [ NpcId, CreatorId ]
integer WaitingTicks;    // How many ticks until we check for one?
integer WAITING_TICKS = 4;

// Table of menus controlling NPCs
list MenuUsers = [];
integer MNU_USER_ID            = 0; // Keep these together in this order
integer MNU_NPC_ID            = 1; // ^^^^^
integer MNU_STRIDE            = 2;
integer MenuUsersCount = 0;

// Table of users being followed
list Followeds = [];    // Format is [ UserId, Position, Rotation ]

// Table of NPCs catching up with their moved creator objects
list CatchUps = [];
integer CAT_NPC_ID            = 0;
integer CAT_TARGET_POS         = 1;
integer CAT_TARGET_ROT        = 2;
integer CAT_STRIDE             = 3;
integer CatchUpsCount = 0;

integer MenuListener = 0;
integer MenuChannel;
integer MenuTime = 0;

integer FollowingCount = 0;
integer MaxAvatars = 100;

integer AreUsersInRegion = TRUE;
integer NpcsOnVacation = 0; // Number of NPCs who are temporarily deleted (because no users in region)

integer ShowText;

// Check to see if users are in the region
CheckUsers() {
	if (NpcTableCount == 0) return; // No NPCs, so no need to do anything
	integer WereUsersInRegion = AreUsersInRegion;
	list Uuids = llGetAgentList(AGENT_LIST_REGION, []); // returns a list of avatar UUIDs, both NPC and non-NPC
	integer L = llGetListLength(Uuids);
	integer I;
	for (I = 0; I < L; I++) {
		if (!osIsNpc(llList2Key(Uuids, I))) { // if this avatar is not an NPC
			AreUsersInRegion = TRUE;
			if (!WereUsersInRegion)	UsersStateChange();
			return;
		}
	}
	AreUsersInRegion = FALSE;
	if (WereUsersInRegion) UsersStateChange();
}
// React to change in whether users are in region or not
// The reason for all this is that it's possible to create more NPCs
// than the region allows, making it impossible for a user to log into
// (or TP to) the region, effectively locking everyone out.
UsersStateChange() {
	if (AreUsersInRegion) {
		// There are users in the region, but there didn't used to be.
		// So we need to create all the NPCs.
		integer Index;
		for (Index = 0; Index < NpcTableCount; Index++) {
			integer NpcPtr = Index * NPC_STRIDE;
			key CreatorId = llList2Key(NpcTable, NpcPtr + NPC_CREATOR_ID);
			MessageObject(CreatorId, [ "*NPC*", "Q" ]);    // causes creator to make NPC avatar
		}
	}
	else {
		// There are no users in the region, but there used to be.
		// So we need to remove all the NPCs, but leave them in the table.
		integer Index;
		for (Index = 0; Index < NpcTableCount; Index++) {
			integer NpcPtr = Index * NPC_STRIDE;
			key NpcId = llList2Key(NpcTable, NpcPtr + NPC_ID);
			if (AvatarExists(NpcId)) osNpcRemove(NpcId);
			NpcsOnVacation++;
		}
	}
	SetTimer();
}
// Send menu dialog to user
ShowMenu(key UserId, key NpcId, integer NpcPtr) {
	key SelectedId = llList2Key(NpcTable, NpcPtr + NPC_SELECTED_ID);
	key FollowingAvId = llList2Key(NpcTable, NpcPtr + NPC_FOLLOWED_ID);
	// Set buttons
	string FollowButton = "Follow";
	if (FollowingAvId != NULL_KEY) FollowButton = "Unfollow";
	string StandButton = " ";
	if (IsSitting(NpcId)) StandButton = "Stand";
	string SelectButton = "Select";
	if (SelectedId != NULL_KEY) SelectButton = "Deselect";
	string ShowHideButton = "Show text";
	if (ShowText) ShowHideButton = "Hide text";
	llDialog(UserId, "\nNON PLAYER CHARACTER\n\nSelect option:", OrderButtons([ FollowButton, SelectButton, StandButton, ShowHideButton, "Remove" ]), MenuChannel);
}
// Menu option processing
ProcessMenuOption(key NpcId, integer NpcPtr, key UserId, key Button) {
	// If either the user or the NPC has disappeared, do nothing
	if (!AvatarExists(NpcId) || !AvatarExists(UserId)) return;
	// Process option
	if (Button == "Remove") {
		osNpcRemove(NpcId);
		RemoveNpcById(NpcId); // remove data
	}
	else if (Button == "Select") {
		SetSelected(NpcId, NpcPtr, UserId);
	}
	else if (Button == "Deselect") {
		SetSelected(NpcId, NpcPtr, NULL_KEY);
	}
	else if (Button == "Follow") {
		SetFollowing(NpcId, NpcPtr, TRUE, UserId);
	}
	else if (Button == "Unfollow") {
		SetFollowing(NpcId, NpcPtr, FALSE, UserId);
	}
	else if (Button == "Show text") {
		ShowText = TRUE;
		UpdateAllText();
	}
	else if (Button == "Hide text") {
		ShowText = FALSE;
		UpdateAllText();
	}
	else if (Button == "Stand") {
		SetSitting(NpcPtr, NpcId, NULL_KEY);
	}
}
// Change "selected" status
SetSelected(key NpcId, integer NpcPtr, key UserId) {
	if (UserId != NULL_KEY) { // if this is a select rather than a deselect
		DeselectByUser(UserId); // remove any selections for the same user
		llMessageLinked(LINK_SET, NPC_DESELECT, "", UserId); // and tell other NPC modules to do the same
	}
	// Set the selected status
	NpcTable = llListReplaceList(NpcTable, [ UserId ], NpcPtr + NPC_SELECTED_ID, NpcPtr + NPC_SELECTED_ID);
	SetText(NpcId, NpcPtr);
	DeleteCatchUp(NpcId);
}
// Remove any selection(s) for the given user
DeselectByUser(key UserId) {
	integer Index;
	for (Index = 0; Index < NpcTableCount; Index++) {
		integer NpcPtr = Index * NPC_STRIDE;
		integer SelectedPtr = NpcPtr + NPC_SELECTED_ID;    // pointer to "selected id" column
		key SelectedId = llList2Key(NpcTable, SelectedPtr);
		if (SelectedId == UserId) {
			NpcTable = llListReplaceList(NpcTable, [ NULL_KEY ], SelectedPtr, SelectedPtr);
			key NpcId = llList2Key(NpcTable, NpcPtr + NPC_ID);
			SetText(NpcId, NpcPtr);
		}
	}
}
// Change "following" status
SetFollowing(key NpcId, integer NpcPtr, integer IsFollowing, key UserId) {
	key FollowedId = NULL_KEY;
	if (IsFollowing) FollowedId = UserId;
	// Set the following status
	NpcTable = llListReplaceList(NpcTable, [ FollowedId ], NpcPtr + NPC_FOLLOWED_ID, NpcPtr + NPC_FOLLOWED_ID);
	if (IsFollowing) {
		FollowingCount++;
		// Store followed user's position
		integer F = llListFindList(Followeds, [ UserId ]);
		if (F == -1) Followeds += [ UserId, GetAvatarPos(UserId), GetAvatarRot(UserId) ];
		Following();
	}
	else {
		FollowingCount--;
		// Remove user from Followeds table if we're the last follower
		integer P = llListFindList(NpcTable, [ "F", UserId ]);
		if (P == -1) {
			integer F = llListFindList(Followeds, [ UserId ]);
			if (F > -1) Followeds = llDeleteSubList(Followeds, F, F + 2);
		}
		osNpcStopMoveToTarget(NpcId); // stop the NPC if it's moving
	}
	SetText(NpcId, NpcPtr);
	DeleteCatchUp(NpcId);
	SetTimer();
}
// Logic for NPCs following avatars
Following() {
	if (FollowingCount == 0) return;
	list NewFolloweds = [];    // Copy of Followed with new data to be written back at the end
	// Cycle through all NPCs
	integer Index;
	for (Index = 0; Index < NpcTableCount; Index++) {
		integer NpcPtr = Index * NPC_STRIDE;
		key FollowedId = llList2Key(NpcTable, NpcPtr + NPC_FOLLOWED_ID);
		if (FollowedId != NULL_KEY) { // If the NPC is following someone
			key NpcId = llList2Key(NpcTable, NpcPtr + NPC_ID);
			if (AvatarExists(FollowedId)) { // if the avatar hasn't disappeared
				// Find the followed avatar's previous position/rotation
				integer FPtr = llListFindList(Followeds, [ FollowedId ]);
				if (FPtr == -1) { LogError("NPC followed not found"); state Hang; }
				vector FollowedPos;
				rotation FollowedRot = llList2Rot(Followeds, FPtr + 2);
				// Have we added this followed avatar to the new copy of the table?
				integer NFPtr = llListFindList(NewFolloweds, [ FollowedId ]);
				if (NFPtr == -1) {
					// Save the position but not the rotation (see below)
					FollowedPos = GetAvatarPos(FollowedId);
					NewFolloweds += [ FollowedId, FollowedPos, FollowedRot ];
				}
				else {
					// Reuse the saved pos/rot to reduce calls to llGetObjectDetails
					FollowedPos = llList2Vector(NewFolloweds, FPtr + 1);
					FollowedRot = llList2Rot(NewFolloweds, FPtr + 2);
				}
				vector OldFollowedPos = llList2Vector(Followeds, FPtr + 1);
				if (llVecDist(FollowedPos, OldFollowedPos) > 3.0) { // If the avatar has moved significantly
					// We only get the rotation if they've moved, to allow the avatar to turn round
					// and face the NPCs behind them (necessary to interact without camera controls).
					// Ensure the distance margin in the test above is greater than the max distance the
					// NPC is normally positioned from the target!
					//
					// Get the latest rotation
					FollowedRot = GetAvatarRot(FollowedId);
					NewFolloweds = llListReplaceList(NewFolloweds, [ FollowedRot ], FPtr + 2, FPtr + 2);
				}
				// Find a position behind the avatar based on its last rotation since it moved significantly
				vector TargetPos = FollowedPos + (<-1.5, 0.0, 0.0> * FollowedRot);
				vector NpcPos = GetAvatarPos(NpcId);
				float Dist = llVecDist(TargetPos, NpcPos);
				if (Dist > FOLLOW_RANGE) {
					if (Dist > FOLLOW_LIMIT) {
						TargetPos = NpcPos + FOLLOW_LIMIT * llVecNorm(TargetPos - NpcPos ) ;
					}
					osNpcMoveToTarget(NpcId, TargetPos, OS_NPC_NO_FLY);
				}
			}
			else { // the avatar being followed has disappeared
				// So we set the NPC to "not following"
				SetFollowing(NpcId, NpcPtr, FALSE, FollowedId);
			}
		}
	}
	// Update the followed table
	Followeds = NewFolloweds;
}
// Handle sitting/standing
SetSitting(integer NpcPtr, key NpcId, key SitPrimId) {
	if (SitPrimId != NULL_KEY) {
		DeleteCatchUp(NpcId);
		if (ObjectExists(SitPrimId)) {
			osNpcSit(NpcId, SitPrimId, OS_NPC_SIT_NOW);
		}
	}
	else {
		osNpcStand(NpcId);
	}
	// Record UUID of sit object, or NULL_KEY if not sitting
	NpcTable = llListReplaceList(NpcTable, [ SitPrimId ], NpcPtr + NPC_SEAT_ID, NpcPtr + NPC_SEAT_ID);
}
// Update floating text for all NPCs
UpdateAllText() {
	integer Index;
	for (Index = 0; Index < NpcTableCount; Index++) {
		integer NpcPtr = Index * NPC_STRIDE;
		key NpcId = llList2Key(NpcTable, NpcPtr + NPC_ID);
		SetText(NpcId, NpcPtr);
	}
}
// Handle user selecting options on menu
MenuResponse(key UserId, string Button) {
	// Get NPC ID from menu users table
	integer MenuPtr = llListFindList(MenuUsers, [ UserId ]);
	if (MenuPtr == -1) return;
	MenuPtr -= MNU_USER_ID;
	key NpcId = llList2Key(MenuUsers, MenuPtr + MNU_NPC_ID);
	// We no longer need the listener for this user
	RemoveMenuForUser(UserId);
	SetListener();
	// Find the NPC table entry
	integer NpcPtr = llListFindList(NpcTable, [ NpcId ]);
	if (NpcPtr == -1) return;
	// Do whatever is necessary for this menu option
	ProcessMenuOption(NpcId, NpcPtr, UserId, Button);
}
// Process touch on NPC's attachment
HandleTouch(key AttachmentId, key UserId) {
	// Find table entry
	integer NpcPtr = llListFindList(NpcTable, [ AttachmentId ]);
	if (NpcPtr == -1) return;    // just ignore invalid attachment IDs
	NpcPtr -= NPC_ATTACHMENT_ID; // position at start of row
	key NpcId = llList2Key(NpcTable, NpcPtr + NPC_ID);
	// Override menus for same user or NPC
	RemoveMenuForUser(UserId);
	RemoveMenuForNpc(NpcId);
	// Add entry to menu users table
	MenuUsers += [ UserId, NpcId ];
	MenuUsersCount++;
	SetListener();
	ShowMenu(UserId, NpcId, NpcPtr);
	MenuTime = llGetUnixTime();
}
// Control channel message - see link_message for details
HandleControlChannel(string Data) {
	// Format of Data is potentially <User name>%<Clicked prim ID>
	integer P = llSubStringIndex(Data, "%");
	if (P < 3) return;
	string UserName = llGetSubString(Data, 0, P - 1);
	key SitPrimId = (key)llGetSubString(Data, P + 1, -1);
	if (SitPrimId == NULL_KEY) return;
	// Loop through NPCs table
	integer Index;
	for (Index = 0; Index < NpcTableCount; Index++) {
		integer NpcPtr = Index * NPC_STRIDE;{
			key SelectedId = llList2Key(NpcTable, NpcPtr + NPC_SELECTED_ID);
			if (SelectedId != NULL_KEY) {
				string SelectedName = llKey2Name(SelectedId);
				if (SelectedName == UserName) {
					key NpcId = llList2Key(NpcTable, NpcPtr + NPC_ID);
					SetSitting(NpcPtr, NpcId, SitPrimId);
					return;
				}
			}
		}
	}
}
RemoveMenuForUser(key UserId) {
	integer MenuPtr = llListFindList(MenuUsers, [ UserId ]);
	if (MenuPtr == -1) return;
	MenuPtr -= MNU_USER_ID;
	MenuUsers = llDeleteSubList(MenuUsers, MenuPtr, MenuPtr + MNU_STRIDE - 1);
	MenuUsersCount--;
}
RemoveMenuForNpc(key NpcId) {
	integer MenuPtr = llListFindList(MenuUsers, [ NpcId ]);
	if (MenuPtr == -1) return;
	MenuPtr -= MNU_NPC_ID;
	MenuUsers = llDeleteSubList(MenuUsers, MenuPtr, MenuPtr + MNU_STRIDE - 1);
	MenuUsersCount--;
}
list OrderButtons(list Buttons) {
	return llList2List(Buttons, -3, -1) + llList2List(Buttons, -6, -4)
		+ llList2List(Buttons, -9, -7) + llList2List(Buttons, -12, -10);
}
// Run or stop listener depending on whether it's needed
SetListener() {
	if (MenuUsers == []) { // nobody using menu
		if (MenuListener > 0) { // but a listener is still running
			llListenRemove(MenuListener);
			MenuListener = 0;
		}
	}
	else {
		if (MenuListener == 0) { // no listener, but we need one
			MenuListener = llListen(MenuChannel, "", NULL_KEY, "");
		}
	}
}
// Set floating text for NPC attachment and send (if NpcPtr is -ve, it's calculated)
SetText(key NpcId, integer NpcPtr) {
	if (NpcPtr < 0) {
		NpcPtr = llListFindList(NpcTable, [ NpcId ]) - NPC_ID;
	}
	key SelectedId = llList2Key(NpcTable, NpcPtr + NPC_SELECTED_ID);
	key FollowedId = llList2Key(NpcTable, NpcPtr + NPC_FOLLOWED_ID);
	string Text = "";
	if (ShowText) {
		if (SelectedId != NULL_KEY) {
			Text += "Selected by " + llKey2Name(SelectedId);
			if (FollowedId != NULL_KEY) Text += "\n-\n"; // vertical separator
		}
		if (FollowedId != NULL_KEY) Text += "Following " + llKey2Name(FollowedId);
	}
	if (llListFindList(CatchUps, [ NpcId ]) > -1) Text += "\nCatching up with creator object";
	SendToNpc(NpcPtr, "F", [ Text ]);
}
// Update NPCs table with newly-found attachment object UUID
UpdateAttachmentId(key NpcId, key AttachmentId) {
	integer NpcPtr = llListFindList(NpcTable, [ NpcId ]);
	if (NpcPtr == -1) return; // Ignore if it's been deleted
	// Update attachment ID
	integer NpcAttachmentPtr = NpcPtr + NPC_ATTACHMENT_ID; // pointer to table column
	NpcTable = llListReplaceList(NpcTable, [ AttachmentId ], NpcAttachmentPtr, NpcAttachmentPtr);
}
// Remove NPC from all data
RemoveNpcById(key NpcId) {
	if (AvatarExists(NpcId)) osNpcRemove(NpcId);
	integer NpcPtr = llListFindList(NpcTable, [ NpcId ]);
	RemoveNpcByPtr(NpcPtr);
	// Remove from menu users table (if there)
	RemoveMenuForNpc(NpcId);
	DeleteWaiting(NpcId);
	DeleteCatchUp(NpcId);
}
// Remove NPC from table by pointer
RemoveNpcByPtr(integer NpcPtr) {
	if (NpcPtr > -1) {
		NpcTable = llDeleteSubList(NpcTable, NpcPtr, NpcPtr + NPC_STRIDE - 1);
		NpcTableCount--;
	}
}
vector GetAvatarPos(key AvId) {
	return llList2Vector(llGetObjectDetails(AvId, [ OBJECT_POS ]), 0);
}
rotation GetAvatarRot(key AvId) {
	return llList2Rot(llGetObjectDetails(AvId, [ OBJECT_ROT ]), 0);
}
// Set timer value depending on what's happening
SetTimer() {
	if (FollowingCount > 0 || CatchUpsCount > 0 || WaitingNpcs != []) {
		llSetTimerEvent(TIMER_BUSY);
	}
	else {
		if (NpcTableCount > 0) {	// if there are NPCs
			if (AreUsersInRegion) {
				llSetTimerEvent(TIMER_IDLE_NOT_ALONE);
			}
			else {
				llSetTimerEvent(TIMER_IDLE_ALONE);
			}
		}
		else { // No NPCs, so no need for a timer
			llSetTimerEvent(0.0);
		}
	}
}
// Called periodically, removes data no longer needed, etc
Housekeeping() {
	if (NpcTableCount == 0) return;	// if we have no NPCs out there, don't do anything
	integer Index;
	// First, check if the region is full (in terms of number of avatars)
	integer ExcessAvatars = llGetRegionAgentCount() - MaxAvatars;
	if (ExcessAvatars > 0) { // we need to cull some NPCs
		list Avatars = llGetAgentList(AGENT_LIST_REGION, []);
		integer AvatarsCount = llGetListLength(Avatars);
		for (Index = 0; Index < AvatarsCount && ExcessAvatars > 0; Index++) {
			key AvatarId = llList2Key(Avatars, Index);
			if (osIsNpc(AvatarId)) {
				osNpcRemove(AvatarId);
				ExcessAvatars--;
			}
		}
	}
	// We use a separate table for orphans to avoid the mess of deleting items while
	// iterating through the same table.
	FollowingCount = 0;
	list Orphans = [];
	// NPCs table first
	for (Index = 0; Index < NpcTableCount; Index++) {
		integer NpcPtr = Index * NPC_STRIDE;
		key NpcId = llList2Key(NpcTable, NpcPtr + NPC_ID);
		// Has the NPC disappeared?
		if (!AvatarExists(NpcId) && NpcsOnVacation == 0) Orphans += NpcId;
		integer UpdateText = FALSE;
		// Has the Selected user disappeared?
		integer SelectedPtr = NpcPtr + NPC_SELECTED_ID;    // pointer to "selected id" column
		key SelectedId = llList2Key(NpcTable, SelectedPtr);
		if (SelectedId != NULL_KEY && !AvatarExists(SelectedId)) {
			NpcTable = llListReplaceList(NpcTable, [ NULL_KEY ], SelectedPtr, SelectedPtr);
			UpdateText = TRUE;
		}
		// Has the Following user disappeared?
		integer FollowingPtr = NpcPtr + NPC_FOLLOWED_ID; // pointer to "following id" column
		key FollowedId = llList2Key(NpcTable, FollowingPtr);
		if (FollowedId != NULL_KEY && !AvatarExists(FollowedId)) {
			NpcTable = llListReplaceList(NpcTable, [ NULL_KEY ], FollowingPtr, FollowingPtr);
			UpdateText = TRUE;
			FollowedId = NULL_KEY;
		}
		// Update following count
		if (FollowedId != NULL_KEY) FollowingCount++;
		// Has the NPC been kicked from their seat?
		if (NpcsOnVacation == 0) { // Don't do these checks if the NPCs have been temporarily deleted
			integer ShouldBeSitting = (llList2Key(NpcTable, NpcPtr + NPC_SEAT_ID) != NULL_KEY);
			integer IsSitting = ((llGetAgentInfo(NpcId) & AGENT_SITTING) == AGENT_SITTING);
			if (ShouldBeSitting && !IsSitting) { // they've been literally stood up
				// Stop any lingering  animations. This is because a chair that's been
				// deleted will not have chance to stop the avatar animation, leading to an
				// NPC that is stuck in some sitting animation or similar.
				StopAllAnimations(NpcId);
				// Reflect this in the NPCs table
				NpcTable = llListReplaceList(NpcTable, [ NULL_KEY ], NpcPtr + NPC_SEAT_ID, NpcPtr + NPC_SEAT_ID);
			}
		}
		// Has the creator object been moved?
		if (UpdateText) SetText(NpcId, NpcPtr);
	}
	// Remove orphan NPC data
	integer OrphansCount = llGetListLength(Orphans);
	for (Index = 0; Index < OrphansCount; Index++) {
		key NpcId = llList2Key(Orphans, Index);
		RemoveNpcById(NpcId);
	}
	// Make NPCs catch up with their creator objects (after a move)
	for (Index = 0; Index < CatchUpsCount; Index++) {
		integer CPtr = Index * CAT_STRIDE;
		key NpcId = llList2Key(CatchUps, CPtr + CAT_NPC_ID);
		vector TargetPos = llList2Vector(CatchUps, CPtr + CAT_TARGET_POS);
		rotation TargetRot = llList2Rot(CatchUps, CPtr + CAT_TARGET_ROT);
		// Although we do have the issue here of deleting elements while
		// serially processing the table, it will all turn out right in the
		// end (missed elements will be picked up next time around)
		CatchUp(NpcId, TargetPos, TargetRot);
	}
	// Menu Users table
	if (MenuUsers != []) {
		if (llGetUnixTime() > (MenuTime + 3600)) { // Menus have not been accessed in an hour
			// Assume that any entries in the menu users table are defunct. This avoids
			// undue growth from users accessing menu but not selecting options.
			MenuUsers = [];
			MenuUsersCount = 0;
		}
	}
	// If we've not heard back from any new NPC attachements, we need to resend the "Hello" message
	if (WaitingNpcs != []) {
		if (WaitingTicks-- == 0) {
			integer Len = llGetListLength(WaitingNpcs);
			integer I;
			for (I = 0; I < Len; I += 2) {
				key NpcId = llList2Key(WaitingNpcs, I);
				key CreatorId = llList2Key(WaitingNpcs, I + 1);
				HelloNpc(NpcId, CreatorId);
			}
			WaitingTicks = WAITING_TICKS;
		}
	}
	SetTimer();
}
// Move NPC towards target
CatchUp(key NpcId, vector TargetPos, rotation TargetRot) {
	vector NpcPos = GetAvatarPos(NpcId);
	if (llVecDist(NpcPos, TargetPos) < 0.5) { //they're close enough
		osNpcStopMoveToTarget(NpcId);
		StopAllAnimations(NpcId);
		DeleteCatchUp(NpcId);
		osNpcSetRot(NpcId, TargetRot);
	}
	else {
		integer MoveMethod = OS_NPC_NO_FLY;
		// Occasionally teleport to move around obstacles
		if (llFrand(1.0) < 0.1) {
			osNpcStopMoveToTarget(NpcId);
			osTeleportAgent(NpcId, TargetPos, ZERO_VECTOR);
		}
		else {
			osNpcMoveToTarget(NpcId, TargetPos, OS_NPC_NO_FLY);
		}
	}
	SetText(NpcId, -1);
}
// Delete a CatchUp entry
DeleteCatchUp(key NpcId) {
	integer C = llListFindList(CatchUps, [ NpcId ]);
	if (C > -1) {
		C -= CAT_NPC_ID;
		CatchUps = llDeleteSubList(CatchUps, C, C + CAT_STRIDE - 1);
		CatchUpsCount--;
	}
}
// Calculate roughly the place for the avatar hip
vector Creator2TargetPos(vector CreatorPos) {
	return (CreatorPos + <0.0, 0.0, 1.4>);
}
// Send stomach attachment a message requesting its data. This will be responded to by
// the attachment script with an "h" message
HelloNpc(key NpcId, key CreatorId) {
	list Message = [
		"*NPC*",
		"H",         // "Hello"
		CreatorId    // ie creation object
			];
	osMessageAttachments(NpcId, llDumpList2String(Message, "|"), [ ATTACH_BELLY ], 0);
}
DeleteWaiting(key NpcId)  {
	integer P = llListFindList(WaitingNpcs, [ NpcId ]);
	if (P > -1) WaitingNpcs = llDeleteSubList(WaitingNpcs, P, P + 1);
}
// Send message to NPC attachment in correct format
SendToNpc(integer NpcPtr, string Command, list Params) {
	key AttachmentId = llList2Key(NpcTable, NpcPtr + NPC_ATTACHMENT_ID);
	if (AttachmentId == NULL_KEY) return;
	list Message = [ "*NPC*", Command ] + Params;
	MessageObject(AttachmentId, Message);
}
// Wrapper for osMessageObject
MessageObject(key Destination, list Message) {
	if (Destination == NULL_KEY) return; // let's be fault-tolerant here
	if (ObjectExists(Destination)) {
		osMessageObject(Destination, llDumpList2String(Message, "|"));
	}
}
// Stops all animations
StopAllAnimations(key AvatarId) {
	list AnimationList = llGetAnimationList(AvatarId);
	integer I = llGetListLength(AnimationList);
	while (I--) {
		key Animation = llList2Key(AnimationList, I);
		osNpcStopAnimation(AvatarId, (string)Animation);
	}
}
// Return true if user/NPC exists
integer AvatarExists(key AvatarId) {
	return (AvatarId != NULL_KEY && llGetObjectDetails(AvatarId, [ OBJECT_POS ]) != []);
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
// Returns true if NPC is sitting on an object
integer IsSitting(key NpcId) {
	return (llGetAgentInfo(NpcId) & AGENT_SITTING);
}
// Process public data sent by ML
ParsePublicData(string Data) {
	list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
	MaxAvatars = (integer)llList2String(Parts, 11);
}
LogError(string Text) {
	llRegionSay(-7563234, Text);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		MenuChannel = (integer)(llFrand(-10000.0) - 1000000.0);
		ShowText = TRUE;
		llListen(NPC_CONTROL_CHANNEL, "", NULL_KEY, "");
		CheckUsers();
		SetTimer();
	}
	dataserver(key Id, string Data) {
		if (llGetSubString(Data, 0, 4) == "*NPC*") {
			// Format of messages is: *NPC*|<command>|<data>
			list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
			string Command = llList2String(Parts, 1);
			list Params = llList2List(Parts, 2, -1);
			if (Command == "Q") {        // Creator requesting permission to create an NPC
				if (llGetRegionAgentCount() <= MaxAvatars) { // check limit of number of avatars
					// Note that llGetRegionAgentCount can return an out-of-date number
					MessageObject(Id, [ "*NPC*", "Q" ]);    // grant permission to create
				}
			}
			else if (Command == "C") {    // "NPC created" message from NPC creation script
				// Collect our data
				key NpcId = (key)llList2String(Params, 0);    // UUID of NPC
				key CreatorId = Id;
				list CreatorDetails = llGetObjectDetails(CreatorId, [ OBJECT_POS, OBJECT_ROT ]);
				vector CreatorPos = llList2Vector(CreatorDetails, 0);
				rotation CreatorRot = llList2Rot(CreatorDetails, 1);
				vector TargetPos = Creator2TargetPos(CreatorPos);
				// The creator may already have registered an avatar with us. This is because NPCs are
				// not persistent over region restarts, so the creator spawns a new NPC on restart. In
				// that case, we need to forget about the old one. Also, this takes care of NPCs being
				// respawned when a user enters the region after the region not having any users.
				key SeatUuid = NULL_KEY;
				integer OldTablePtr = llListFindList(NpcTable, [ CreatorId ]);
				if (OldTablePtr > -1) {
					OldTablePtr -= NPC_CREATOR_ID;
					key OldNpcId = llList2Key(NpcTable, OldTablePtr + NPC_ID);
					SeatUuid = llList2Key(NpcTable, OldTablePtr + NPC_SEAT_ID);
					if (SeatUuid != NULL_KEY && ObjectExists(SeatUuid)) {
						osNpcSit(NpcId, SeatUuid, OS_NPC_SIT_NOW);
					}
					RemoveNpcById(OldNpcId);
				}
				// Now go ahead and add the NPC and creator
				integer NpcPtr = NpcTableCount++;
				NpcTable += [
					NpcId,
					CreatorId,
					NULL_KEY,    // attachment ID not yet known
					NULL_KEY,    // nobody selected NPC
					"F",            // separator for searches on user id
					NULL_KEY,    // NPC not following anyone
					SeatUuid        // NPC not sitting
						];
				HelloNpc(NpcId, CreatorId);    // Send "Hello" message to new NPC's attachment
				WaitingNpcs += [ NpcId, CreatorId ];
				WaitingTicks = WAITING_TICKS;
				AreUsersInRegion = TRUE;	// Force switch to false state in case there are no users when we create the NPC
				if (NpcsOnVacation > 0) NpcsOnVacation--;
				SetTimer();
			}
			else if (Command == "h") { // attachment script sent us a reply to our "Hello"
				key NpcId = (key)llList2String(Params, 0);
				UpdateAttachmentId(NpcId, Id);
				DeleteWaiting(NpcId);
			}
			else if (Command == "R") { // creator or attachment telling us to delete the NPC
				key NpcId = (key)llList2String(Params, 0);
				integer ActuallyRemove = (integer)llList2String(Params, 1);
				RemoveNpcById(NpcId);
			}
			else if (Command == "T") { // attachment telling us it's been touched
				key AvId = (key)llList2String(Params, 0);
				HandleTouch(Id, AvId);
			}
			else if (Command == "M") { // creator object has moved
				key NpcId = (key)llList2String(Params, 0);
				if (!AvatarExists(NpcId)) return;
				list CreatorDetails = llGetObjectDetails(Id, [ OBJECT_POS, OBJECT_ROT ]);
				vector CreatorPos = llList2Vector(CreatorDetails, 0);
				rotation TargetRot = llList2Rot(CreatorDetails, 1);
				vector TargetPos = Creator2TargetPos(CreatorPos);
				DeleteCatchUp(NpcId);
				CatchUps += [ NpcId, TargetPos, TargetRot ];
				CatchUpsCount++;
				CatchUp(NpcId, TargetPos, TargetRot);
				SetText(NpcId, -1);
				SetTimer();
			}
		}
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		if (Number == LM_PUBLIC_DATA) {
			ParsePublicData(Text);
		}
		else if (Number == LM_RESET) {
			llResetScript();
		}
		else if (Number == NPC_DESELECT) { // "deselect all for this user" from another NPC module
			if (Sender != llGetLinkNumber()) { // it's not one we've sent
				DeselectByUser(Id);
			}
		}
	}
	listen(integer Channel, string Name, key Id, string Text) {
		if (MenuListener > 0 && Channel == MenuChannel) {
			MenuResponse(Id, Text);
		}
		else if (Channel == NPC_CONTROL_CHANNEL) {
			// Seats use the legacy communication system. If there's ever a chance to update all the
			// seat objects' scripts, seize it.
			// The seat sends us the NAME (not key) of the user who selected an NPC, followed by
			// a % sign and the UUID of the prim that was clicked.
			// So the only way to process this is to search through the NPCs tsble and
			// decode all Selected Ids to find any matching names. I don't know why it was done
			// this way in the original NPCs design. -- JFH
			HandleControlChannel(Text);
		}
	}
	timer() {
		Following();    // Process following logic
		CheckUsers();	// Check to see if users are in the region
		Housekeeping();    // Keep our data tidy
	}
}
state Hang {
	on_rez(integer Param) { llResetScript(); }
}
// NPC server v1.3.0