// Treasure hunt crown v1.1

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

string MESSAGE_IDENTIFIER = "&RMQ&";
integer MESSAGE_ID_LENGTH = 4; // 1 less than actual length (0 start!)

key CrownGiverId = NULL_KEY;
key OwnerId = NULL_KEY;
list Collected = [];
integer Remaining;
integer PrimCount;

// Format and send osMessageObject message
SendMessage(key Uuid, string Command, string Parameters) {
	MessageObject(Uuid, MESSAGE_IDENTIFIER + Command + Parameters);
}
// Wrapper for osMessageObject() that checks to see if destination exists
MessageObject(key Uuid, string Text) {
	if (ObjectExists(Uuid)) {
		osMessageObject(Uuid, Text);
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
string GetLinkDesc(integer LinkNum) {
	return llList2String(llGetLinkPrimitiveParams(LinkNum, [ PRIM_DESC ]), 0);
}
// Actual name is <module>.<object>, so the base name follows the dot/period/full stop
string CalculateBasename(string FullName) {
	integer DotPos = llSubStringIndex(FullName, ".");
	return llGetSubString(FullName, DotPos + 1, -1);
}
default {
	on_rez(integer Start) { llResetScript(); }
	state_entry() {
		OwnerId = llGetOwner();
		if (llGetAttached() != 0) { // if the crown is attached (as opposed to rezzed in-world)
			llRequestPermissions(OwnerId, PERMISSION_ATTACH); // get permission to detach
		}
		Collected = [];
		Remaining = 0;
		PrimCount = llGetNumberOfPrims();
		integer P;
		for(P = 2; P <= PrimCount; P++) {
			string Desc = GetLinkDesc(P);
			if (Desc == "gem") {	// if it's a child prim with a description of "gem", it's a jewel
				Remaining++;		// count how many there are
				llSetLinkAlpha(P, 0.0, ALL_SIDES);	// make invisible
				llSetLinkPrimitiveParamsFast(P, [ PRIM_GLOW, ALL_SIDES, 0.0 ]);
			}
		}
	}
	dataserver(key From, string Data) {
		if (llGetSubString(Data, 0, MESSAGE_ID_LENGTH) == MESSAGE_IDENTIFIER) {
			Data = llGetSubString(Data, MESSAGE_ID_LENGTH + 1, -1); // discard id string
			string Command = llGetSubString(Data, 0, 0); // command is first character of Data
			string Params = llGetSubString(Data, 1, -1); // rest is parameters
			if (Command == "G") { // message from giver that a gem has been clicked
				CrownGiverId = From;
				key GemId =  (key)Params; // giver sends us the gem object's UUID in the parameters
				string GemName = llKey2Name(GemId);
				GemName = CalculateBasename(GemName);
				if (llListFindList(Collected, [ GemName ]) > -1) return;		// ignore if they already have it
				integer Found = FALSE;
				integer P;
				for(P = 2; P <= PrimCount && !Found; P++) {
					string Name = llGetLinkName(P);
					if (Name == GemName) {
						Collected += GemName;
						llSetLinkAlpha(P, 1.0, ALL_SIDES);
						llSetLinkPrimitiveParamsFast(P, [ PRIM_GLOW, ALL_SIDES, 0.1 ]);
						Remaining--;
						SendMessage(GemId, "D", ""); // send "D" message to gem to tell it to go invisible
						Found = TRUE;

					}
				}
				if (Remaining == 0) {
					llOwnerSay("Congratulations, you have won!");
					SendMessage(CrownGiverId, "W", (string)llGetOwner()); // send "W" message to crown giver to end game
				}
			}
			else if (Command == "F") { // crown giver telling us the game has finished
				llDetachFromAvatar();
			}
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_REGION) {
				llDetachFromAvatar();
		}
	}
}
// Treasure hunt crown v1.1