// App Deployment Post-check v1.0

// Drop into App (must be logged in as RezMela Apps)

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
//

key APP_CREATOR = "2627e425-6fbc-4e82-9699-7ed2a650d82e";

integer L_READY = -40192300;
integer L_CHECK  = -40192301;
integer L_RESULTS = -40192302;
integer L_NEXT_CHILD = -40192303;

// From ML
integer LM_RESET = -405535;

float TIMER_SECONDS = 6.0;

string INDENT = "    ";
integer SCRIPT_PIN = -19318100;

integer PrimCount;
integer LinkNum;

string ThisScriptName = "";
string ThisPrimName = "";
integer ThisLinkNum = 0;
integer FoundErrors = 0;
integer FoundWarnings = 0;
list Output = [];
list ChildPrims = []; // link numbers

CheckAppObjectPerms() {
	list Bads = [];
	list ObjectDetails = llGetObjectDetails(llGetKey(), [ OBJECT_GROUP, OBJECT_CREATOR ]);
	key GroupId = llList2Key(ObjectDetails, 0);
	key CreatorId = llList2Key(ObjectDetails, 1);
	if (CreatorId != APP_CREATOR) {
		Bads += INDENT + "App object has wrong creator!";
	}
	//	if (GroupId != NULL_KEY) {
	//		Bads += INDENT + "Object has group set";
	//	}
	if (CheckObjPerm(MASK_NEXT, PERM_TRANSFER)) Bads += INDENT + "Object is transferrable";
	if (CheckObjPerm(MASK_EVERYONE, PERM_COPY)) Bads += INDENT + "Everyone can copy";
	if (CheckObjPerm(MASK_EVERYONE, PERM_MODIFY)) Bads += INDENT + "Everyone can modify";
	if (CheckObjPerm(MASK_EVERYONE, PERM_TRANSFER)) Bads += INDENT + "Everyone can transfer";
	if (CheckObjPerm(MASK_GROUP, PERM_COPY)) Bads += INDENT + "Group can copy";
	if (CheckObjPerm(MASK_GROUP, PERM_MODIFY)) Bads += INDENT + "Group can modify";
	if (CheckObjPerm(MASK_GROUP, PERM_TRANSFER)) Bads += INDENT + "Group can transfer";
	if (Bads != []) {
		Output += [ "*** App object perms errors:", Bads ];
		FoundErrors++;
	}
}
CheckRootContents() {
	// Check for existence of mandatory items
	// Find script names and check for existence (empty if missing)
	list KnownScripts = [];
	KnownScripts += FindScript("!Malleable linkset", TRUE);
	KnownScripts += FindScript("!ML cataloguer", TRUE);
	KnownScripts += FindScript("!ML HUD communicator", TRUE);
	KnownScripts += FindScript("Error handler", TRUE);
	KnownScripts += FindScript("ML environment", TRUE);
	KnownScripts += FindScript("ML touch handler", TRUE);
	// Look for additional scripts
	AdditionalScripts(KnownScripts);
	// Now check notecards
	CheckNotecardExists("ML config");
	CheckNotecardExists("Modules");
	// Check for other strange contents
	CheckAnomalousContents();
	CheckAllCopiable();
	// ML config must be copy-only (mCt)
	if (CheckInvPerm(MASK_NEXT, "ML config", PERM_MODIFY) || CheckInvPerm(MASK_NEXT, "ML config", PERM_TRANSFER)) {
		Output += "*** Invalid perms for 'ML config'";
		FoundErrors++;
	}
}
// We're a child prim, so do those checks
ChildCheck() {
	if (FindScript("HUD server", FALSE) != "") {
		ActivatorCheck();
	}	
	if (llGetSubString(ThisPrimName, 0, 4) == "&Lib:") {
		ModuleCheck();
	}
	CheckContentsPerms();
	CheckAllCopiable();
	if (Output != []) {
		// Indent for readability
		integer Len = llGetListLength(Output);
		integer I;
		for (I = 0; I < Len; I++) {
			string Line = llList2String(Output, I);
			Line = INDENT + Line;
			Output = llListReplaceList(Output, [ Line ], I, I);
		}
		// Add heading
		Output = [ "", ThisPrimName + " (" + (string)ThisLinkNum + "):", "" ] + Output;
	}
}
// Check that object and all contents are copiable
CheckAllCopiable() {
	if (!CheckObjPerm(MASK_NEXT, PERM_COPY)) {
		Output += "*** No copy perms";
		FoundErrors++;
	}
	integer Count = llGetInventoryNumber(INVENTORY_ALL);
	integer I;
	for (I = 0; I < Count; I++) {
		string Name = llGetInventoryName(INVENTORY_ALL, I);
		if (!CheckInvPerm(MASK_NEXT, Name, PERM_COPY)) {
			Output += "*** No copy perms for: " + Name;
			FoundErrors++;
		}
	}
}
ActivatorCheck() {
	integer Count = llGetInventoryNumber(INVENTORY_OBJECT);
	if (Count != 1) {
		Output += "*** Incorrect number of objects in HUD prim!";
		FoundErrors++;
		return;
	}
	string HudName = llGetInventoryName(INVENTORY_OBJECT, 0);
	Output += "HUD object name seems to be " + HudName;
	list BadPerms = [];
	if (CheckInvPerm(MASK_NEXT, HudName, PERM_MODIFY)) BadPerms += "modify";
	if (!CheckInvPerm(MASK_NEXT, HudName, PERM_TRANSFER)) BadPerms += "no-transfer";
	if (!CheckInvPerm(MASK_NEXT, HudName, PERM_COPY)) BadPerms += "no-copy";
	if (BadPerms != []) {
		Output += "*** Bad perms on HUD object: " + llList2CSV(BadPerms);
		FoundErrors++;
	}
}
ModuleCheck() {
	// No objects in a module should have transfer perms
	list BadPerms = [];	
	integer Count = llGetInventoryNumber(INVENTORY_OBJECT);
	integer I;
	for (I = 0; I < Count; I++) {
		string Name = llGetInventoryName(INVENTORY_OBJECT, I);
		if (CheckInvPerm(MASK_NEXT, Name, PERM_TRANSFER)) BadPerms += INDENT + Name;
	}
	if (BadPerms != []) {
		Output += [ "*** Module objects with transfer perms!:" ] + BadPerms;
		FoundErrors += llGetListLength(BadPerms);
	}
}
CheckContentsPerms() {
	// Scripts
	integer Count = llGetInventoryNumber(INVENTORY_SCRIPT);
	integer I;
	for (I = 0; I < Count; I++) {
		string Name = llGetInventoryName(INVENTORY_SCRIPT, I);
		if (Name != ThisScriptName) {
			CheckScriptPerms(Name);
		}
	}
	// Everything else
	Count = llGetInventoryNumber(INVENTORY_ALL);
	for (I = 0; I < Count; I++) {
		string Name = llGetInventoryName(INVENTORY_ALL, I);
		integer Type = llGetInventoryType(Name);
		if (Type != INVENTORY_SCRIPT) {
			ListPerms(Name);
		}
	}
}
// Just outputs perms, doesn't validate them
ListPerms(string Name) {
	string Perms = "";
	if (CheckInvPerm(MASK_NEXT, Name, PERM_COPY)) Perms += "C"; else Perms += "c";
	if (CheckInvPerm(MASK_NEXT, Name, PERM_MODIFY)) Perms += "M"; else Perms += "m";
	if (CheckInvPerm(MASK_NEXT, Name, PERM_TRANSFER)) Perms += "T"; else Perms += "t";
	Output += Name + ": " + Perms;
}
CheckScriptPerms(string Name) {
	if (CheckInvPerm(MASK_EVERYONE, Name, PERM_COPY)) {
		Output += "*** Anyone can copy script: " + Name;
		FoundErrors++;
	}
	if (CheckInvPerm(MASK_EVERYONE, Name, PERM_MODIFY)) {
		Output += "*** Anyone can modify script: " + Name;
		FoundErrors++;
	}
	if (CheckInvPerm(MASK_GROUP, Name, PERM_COPY)) {
		Output += "*** Group can copy script: " + Name;
		FoundErrors++;
	}
	if (CheckInvPerm(MASK_GROUP, Name, PERM_MODIFY)) {
		Output += "*** Group can modify script: " + Name;
		FoundErrors++;
	}
	list BadPerms = [];
	if (CheckInvPerm(MASK_NEXT, Name, PERM_MODIFY)) BadPerms += "modify";
	if (CheckInvPerm(MASK_NEXT, Name, PERM_TRANSFER)) BadPerms += "transfer";
	if (!CheckInvPerm(MASK_NEXT, Name, PERM_COPY)) BadPerms += "no-copy";
	if (BadPerms != []) {
		string PermsText = llDumpList2String(BadPerms, "/");
		string ErrorText = "*** Script '" + Name + "' has bad perms: " + PermsText;
		Output += ErrorText;
		FoundErrors++;
	}
}
string FindScript(string PartialName, integer ReportMissing) {
	string FoundName = "";
	integer Len = llStringLength(PartialName);
	integer Count = llGetInventoryNumber(INVENTORY_SCRIPT);
	integer Found = 0;
	integer S;
	for (S = 0; S < Count; S++) {
		string Name = llGetInventoryName(INVENTORY_SCRIPT, S);
		if (llGetSubString(Name, 0, Len - 1) == PartialName) {
			FoundName = Name;
			Found++;
		}
	}
	if (ReportMissing) {
		if (Found == 0) {
			Output += "*** Missing script! [" + PartialName + "]";
			FoundErrors++;
		}
		else if (Found > 1) {
			Output += "*** Duplicate scripts! [" + PartialName + "]";
			FoundName = "";
			FoundErrors++;
		}
	}
	return FoundName;
}
AdditionalScripts(list KnownScripts) {
	integer Count = llGetInventoryNumber(INVENTORY_SCRIPT);
	integer S;
	for (S = 0; S < Count; S++) {
		string Name = llGetInventoryName(INVENTORY_SCRIPT, S);
		if (Name != ThisScriptName && llListFindList(KnownScripts, [ Name ]) == -1) {
			Output += "*** Warning: unknown script '" + Name + "'!";
			FoundWarnings++;
		}
	}
}
CheckNotecardExists(string Name) {
	if (!InventoryExists(INVENTORY_NOTECARD, Name)) {
		Output += "*** Missing notecard: '" + Name + "'";
		FoundErrors++;
	}
}
CheckAnomalousContents() {
	if (llGetInventoryNumber(INVENTORY_NOTECARD) > 3) {
		Output += "*** Warning: unknown notecard(s)?";
		FoundWarnings++;
	}
	if (llGetInventoryNumber(INVENTORY_OBJECT) > 0) {
		Output += "*** Warning: unknown object(s)?";
		FoundWarnings++;
	}
	if (llGetInventoryNumber(INVENTORY_TEXTURE) > 0) {
		Output += "*** Warning: unknown texture(s)?";
		FoundWarnings++;
	}
	if (llGetInventoryNumber(INVENTORY_ANIMATION) > 0) {
		Output += "*** Warning: unknown animation(s)?";
		FoundWarnings++;
	}
	if (llGetInventoryNumber(INVENTORY_GESTURE) > 0) {
		Output += "*** Warning: unknown gesture(s)?";
		FoundWarnings++;
	}
	if (llGetInventoryNumber(INVENTORY_BODYPART) > 0) {
		Output += "*** Warning: unknown body parts(s)?";
		FoundWarnings++;
	}
	if (llGetInventoryNumber(INVENTORY_CLOTHING) > 0) {
		Output += "*** Warning: unknown clothing?";
		FoundWarnings++;
	}
	if (llGetInventoryNumber(INVENTORY_LANDMARK) > 0) {
		Output += "*** Warning: unknown landmark(s)?";
		FoundWarnings++;
	}
}
integer CheckInvPerm(integer CheckMask, string Name, integer Perm) {
	integer Mask = llGetInventoryPermMask(Name, CheckMask) ;
	return (Mask & Perm);
}
integer CheckObjPerm(integer CheckMask, integer Perm) {
	integer Mask = llGetObjectPermMask(CheckMask);
	return (Mask & Perm);
}
integer InventoryExists(integer Type, string Name) {
	return (llGetInventoryType(Name) == Type);
}
integer IsModule(string Name) {
	return (llGetSubString(Name, 0, 5) == "&Lib: ");
}
default {
	on_rez(integer P) { llResetScript(); }
	state_entry() {
		ThisScriptName = llGetScriptName();
		ThisPrimName = llGetObjectName();
		ThisLinkNum = llGetLinkNumber();
		// If we're in a child prim, phone home and wait for instructions
		if (ThisLinkNum > 1) {
			llMessageLinked(LINK_ROOT, L_READY, "", NULL_KEY);
			return;
		}
		// We're in the root prim (the App itself
		Output = [ "", "App: " + ThisPrimName + ":", "" ];

		llOwnerSay("Examining ...");
		CheckAppObjectPerms();
		CheckRootContents();
		CheckContentsPerms();
		if (FoundErrors > 0) {
			llOwnerSay("Errors found, check abandoned");
			llOwnerSay(llDumpList2String(Output, "\n"));
			llRemoveInventory(ThisScriptName);
			return;
		}
		if (FoundWarnings > 0) {
			llOwnerSay("Warnings found:");
			llOwnerSay(llDumpList2String(Output, "\n"));
		}
		PrimCount = llGetNumberOfPrims();
		LinkNum = 2;
		llMessageLinked(LINK_THIS, L_NEXT_CHILD, "", NULL_KEY);
		llSetTimerEvent(TIMER_SECONDS);
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		if (ThisLinkNum == 1) {	// If we're root
			if (Sender > 1) {
				if (Number == L_READY) { // Child prim sent us message to say it's ready
					llSetTimerEvent(TIMER_SECONDS);
					llMessageLinked(Sender, L_CHECK, "", NULL_KEY); // Reply, telling it to report back
				}
				else if (Number == L_RESULTS) {
					llSetTimerEvent(TIMER_SECONDS);
					integer P = llListFindList(ChildPrims, [ Sender ]);
					if (P == -1) { llOwnerSay("Weird problem #1!!!"); return; }
					ChildPrims = llDeleteSubList(ChildPrims, P, P);
					list ChildOutput = llParseStringKeepNulls(Text, [ "|" ], []);
					// 1st line is summary
					string SummaryString = llList2String(ChildOutput, 0);
					ChildOutput = llDeleteSubList(ChildOutput, 0, 0);
					list SummaryList = llCSV2List(SummaryString);
					integer ChildErrors = (integer)llList2String(SummaryList, 0);
					integer ChildWarnings = (integer)llList2String(SummaryList, 1);
					FoundErrors += ChildErrors;
					FoundWarnings += ChildWarnings;
					if (llGetListLength(ChildOutput) > 1) {	// if it's 1, it's only a blank line
						Output += ChildOutput;
					}
				}
			}
			else { // sender is root
				if (Number == L_NEXT_CHILD) { // Message from ourself to check child prim
					ChildPrims += LinkNum;
					key LinkKey = llGetLinkKey(LinkNum);
					llOwnerSay("Checking prim " + (string)LinkNum + " of " + (string)PrimCount + " (" + llGetLinkName(LinkNum) + ") ...");
					llRemoteLoadScriptPin(LinkKey, ThisScriptName, SCRIPT_PIN, TRUE, 1);
					if (LinkNum < PrimCount) {
						LinkNum++;
						llMessageLinked(LINK_THIS, L_NEXT_CHILD, "", NULL_KEY);
					}
					llSetTimerEvent(TIMER_SECONDS);
				}
			}
		}
		else { // we're a child prim
			if (Number == L_CHECK) {	// root instance tells us to report back
				ChildCheck();
				string Summary = llList2CSV([ FoundErrors, FoundWarnings ]);
				string OutputString = llDumpList2String(Output, "|");
				llMessageLinked(LINK_ROOT, L_RESULTS, Summary + "|" + OutputString, NULL_KEY);
				llRemoveInventory(ThisScriptName);
			}
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		if (llGetListLength(ChildPrims) > 0) {
			Output += [ "", "Unable to check these prims:" ] ;
			integer Count = llGetListLength(ChildPrims);
			integer I;
			for (I = 0; I < Count; I++) {
				integer LinkNum = llList2Integer(ChildPrims, I);
				string Name = llGetLinkName(LinkNum);
				Output += INDENT + Name + " (" + (string)LinkNum + ")";
			}
		}
		Output = [ (string)FoundErrors + " errors, " + (string)FoundWarnings + " warnings." ] + Output;
		llOwnerSay("Done.");
		string Timestamp = llGetTimestamp();
		string OutputNotecard = "Results for " + ThisPrimName + " at " + llGetSubString(Timestamp, 0, 9) + " " + llGetSubString(Timestamp, 11, 18);
		osMakeNotecard(OutputNotecard, Output);
		llGiveInventory(llGetOwner(), OutputNotecard);
		llMessageLinked(LINK_SET, LM_RESET, "", NULL_KEY); // reset whole ML
		llRemoveInventory(OutputNotecard);
		llRemoveInventory(ThisScriptName);
	}
}