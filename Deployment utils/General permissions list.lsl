// General permissions list v1.0

// Drop into any object to list contents' perms

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

string ThisScriptName;

CheckContents() {
	list Objects = [];
	list Notecards = [];
	list Scripts = [];
	list Others = [];
	list Summary = [ "Perms:" ];
	integer Len;
	integer P;
	Len = llGetInventoryNumber(INVENTORY_ALL);
	for (P = 0; P < Len; P++) {
		string Name = llGetInventoryName(INVENTORY_ALL, P);
		integer Type = llGetInventoryType(Name);
		if (Type == INVENTORY_OBJECT) {
			Objects += GetPerms(Name, "O");
		}
		else if (Type == INVENTORY_NOTECARD) {
			Notecards += GetPerms(Name, "N");
		}
		else if (Type == INVENTORY_SCRIPT) {
			if (Name != ThisScriptName) {
				Scripts += GetPerms(Name, "S");
			}
		}
		else {
			Others += GetPerms(Name, "O");
		}
	}
	Summary += Scripts + Objects + Notecards + Others;
	string Output = llDumpList2String(Summary, "\n");
	if (llStringLength(Output) < 1024) {
		llOwnerSay(Output);
	}
	else { // too long to say at once
		Len = llGetListLength(Summary);
		for (P = 0; P < Len; P++) {
			string Line = llList2String(Summary, P);
			llOwnerSay(Line);
		}
	}
	if (llSubStringIndex(Output, "!") > -1) {
		llOwnerSay("There were warnings.");
	}
}
string GetPerms(string Name, string ItemType) {
	string Perms = "";
	if (CheckInvPerm(MASK_NEXT, Name, PERM_COPY)) Perms += "C"; else Perms += "c";
	if (CheckInvPerm(MASK_NEXT, Name, PERM_MODIFY)) Perms += "M"; else Perms += "m";
	if (CheckInvPerm(MASK_NEXT, Name, PERM_TRANSFER)) Perms += "T"; else Perms += "t";
	if (ItemType == "S" && llSubStringIndex(Perms, "M") > -1) Perms += "!";	// warn if modifiable script
	if (llSubStringIndex(Perms, "T") > -1) Perms += "!"; // warn if anything transferrable
	if (CheckInvPerm(MASK_EVERYONE, Name, PERM_COPY)) Perms += " Everyone copy!";
	if (CheckInvPerm(MASK_EVERYONE, Name, PERM_MODIFY)) Perms += " Everyone modify!";
	if (CheckInvPerm(MASK_EVERYONE, Name, PERM_TRANSFER)) Perms += " Everyone transfer!";
	if (CheckInvPerm(MASK_GROUP, Name, PERM_COPY)) Perms += " Group copy!";
	if (CheckInvPerm(MASK_GROUP, Name, PERM_MODIFY)) Perms += " Group modify!";
	if (CheckInvPerm(MASK_GROUP, Name, PERM_TRANSFER)) Perms += " Group transfer!";
	return Name + " (" + ItemType + "): " + Perms;
}
integer CheckInvPerm(integer CheckMask, string Name, integer Perm) {
	integer Mask = llGetInventoryPermMask(Name, CheckMask) ;
	return (Mask & Perm);
}
Say(string Text) {
	string N = llGetObjectName();
	llSetObjectName("");
	llOwnerSay("/me     " + Text);
	llSetObjectName(N);
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		ThisScriptName = llGetScriptName();
		CheckContents();
		llRemoveInventory(ThisScriptName);
	}
}
// General permissions list v1.0