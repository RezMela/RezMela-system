// Object damage v0.3

// v0.3 - ignore blank lines in notecards

integer MIN_HITS_TO_DESTROY = 4;	// a random number between these values (inclusive) will be
integer MAX_HITS_TO_DESTROY = 6;	//  generated to determine how many hits before destruction
integer HitsLeft;

integer LM_DAMAGED = -18007420;		// link message sent to other scripts, "1" in string value denotes damage, "0" denotes normal

string BULLET_DUMMY = "BulletDummy";	// the name of the bullet dummy (ie the long, invisible bullet used in collision detection)

integer PrimCount;		// count of prims in object
integer MenuChannel;	// unique channel for menu dialog comms

string NOTECARD_NORMAL = "Normal data";		// the names of the three notecards
string NOTECARD_DAMAGE = "Damaged data";
string NOTECARD_SETUP = "Setup lock";

integer CHAT_CHANNEL = 29904047;

key OwnerId;		// Owner's UUID
key MyId;
string sMyId;
integer SavingDamaged;	// TRUE if we're about to save the damaged notecard, otherwise the normal notecard

// Return all prim parameter values, in a format suitable for SetPrimitiveParams
list GetObjectData() {
	list Ret = [];
	PrimCount = llGetNumberOfPrims();
	if (PrimCount == 1) {			// unlinked, only prim 0
		Ret = GetPrimData(0);
	}
	else {							// linkset, so cycle through prims
		integer P = PrimCount;
		do {
			Ret += GetPrimData(P);
		} while(--P);
	}
	return Ret;
}
// Get prim parameter values for the specified prim
list GetPrimData(integer LinkNum) {
	list Ret =  [
		PRIM_LINK_TARGET, LinkNum,		// select the prim
		PRIM_SIZE, llGetLinkPrimitiveParams(LinkNum, [ PRIM_SIZE ])
			];
	list Params = llGetLinkPrimitiveParams(LinkNum, [ PRIM_POINT_LIGHT ]);
	Ret += [ PRIM_POINT_LIGHT ] + Params;		// aka local light
	Ret += GetSides(LinkNum);		// get side-related data (side == face)
	if (LinkNum > 1) {	// get local pos and rot for non-root prims in a linkset
		Ret += [
			PRIM_POS_LOCAL, llGetLinkPrimitiveParams(LinkNum, [ PRIM_POS_LOCAL ]),
			PRIM_ROT_LOCAL, llGetLinkPrimitiveParams(LinkNum, [ PRIM_ROT_LOCAL ])
				];
	}
	return Ret;
}
// Get prim parameter values for side-related data such as colour
list GetSides(integer LinkNum) {
	list Ret = [];
	integer Sides = llGetLinkNumberOfSides(LinkNum);
	integer I;
	for (I = 0; I < Sides; I++) {		// loop through sides (faces) getting data
		list Params = llGetLinkPrimitiveParams(LinkNum, [ PRIM_COLOR, I ]);
		Ret += [ PRIM_COLOR, I ] + Params;		// colour includes alpha channel, necessary for transparency
		Params = llGetLinkPrimitiveParams(LinkNum, [ PRIM_GLOW, I ]);
		Ret += [ PRIM_GLOW, I ] + Params;
	}
	return Ret;
}
// Save named notecard with given data
SaveNotecard(string Name, list Data) {
	if (llGetInventoryType(Name) == INVENTORY_NOTECARD) {
		llRemoveInventory(Name);		// remove previous version
	}
	llSleep(0.5); // I hate doing this, but sometimes it seems to be necessary
				  // otherwise data is appended to previous card
	osMakeNotecard(Name, [ llGetObjectName() ] + Data);	// first line of notecard is object name,
														// just to make it easier to see which is which 
}
// Read named notecard and apply prim parameters therein
LoadNotecard(string Name) {
	list Params = [];
	integer Lines = osGetNumberOfNotecardLines(Name);
	integer I;
	for(I = 1; I < Lines; I++) {		// note we skip first line, which is memo only
		string Str = osGetNotecardLine(Name, I);
		if (llStringTrim(Str, STRING_TRIM) != "") {
			// We need to determine data type based on data. Fortunately, we only have
			// to deal with vectors, rotations, floats and integers.
			if (llGetSubString(Str, 0, 0) == "<") {		// vector or quaternion
				if (llGetListLength(llCSV2List(llGetSubString(Str, 1, -2))) == 3)	// 3 components, therefore vector
					Params += (vector)Str;
				else			// (rotations have four components)
					Params += (rotation)Str;
			}
			else if (llSubStringIndex(Str, ".") > -1) {		// contains dec point, must be float
				Params += (float)Str;
			}
			else {
				Params += (integer)Str;		// integer data type
			}
		}
	}
	llSetPrimitiveParams(Params);
}
// Broadcase link message
SendLinkMessage(integer IsDamaged) {
	llMessageLinked(LINK_SET, LM_DAMAGED, (string)IsDamaged, NULL_KEY);
}
// TRUE if named notecard exists
integer NotecardExists(string Name) {
	return (llGetInventoryType(Name) == INVENTORY_NOTECARD);
}
default{
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		MenuChannel = -10000 - (integer)llFrand(100000.0);		// random channel to avoid crosstalk
		OwnerId = llGetOwner();
		MyId = llGetKey();
		sMyId = (string)MyId;
		state Init;
	}
}
state Init {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		if (!NotecardExists(NOTECARD_SETUP)) state Setup;		// No setup lock notecard, so go into setup mode
		if (!NotecardExists(NOTECARD_NORMAL) || !NotecardExists(NOTECARD_DAMAGE)) state NewSetup;	// we don't have both data cards
		// Calculate number of hits it will take to destroy the building, between MIN_ and MAX_HITS_TO_DESTROY (inclusive)
		HitsLeft = MIN_HITS_TO_DESTROY + (integer)(llFrand(MAX_HITS_TO_DESTROY - MIN_HITS_TO_DESTROY + 1));
		state Normal;
	}
	changed(integer Change)	{
		if (Change & CHANGED_INVENTORY) llResetScript();
	}
}
// Normal mode, for undamaged building
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		LoadNotecard(NOTECARD_NORMAL);		// get the normal data and apply
		SendLinkMessage(FALSE);				// tell other scripts we're in normal mode
		llCollisionFilter(BULLET_DUMMY, NULL_KEY, TRUE);		// filter only the dummy bullet
	}
	collision_start(integer Total) {
		if (!--HitsLeft) state Destroyed;		// if we're out of hits, destroyed
	}
	dataserver(key QueryId, string Data) {
		if (llGetSubString(Data, 0, 0) == "D" && llGetSubString(Data, 1, -1) == sMyId) state Destroyed;
	}
	changed(integer Change)	{
		if (Change & CHANGED_INVENTORY) state Init;
	}
}
// Damaged mode
state Destroyed {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		LoadNotecard(NOTECARD_DAMAGE);		// load damaged data and spply
		SendLinkMessage(TRUE);				// tell other scripts we're in damaged mode
	}
	changed(integer Change)	{
		if (Change & CHANGED_INVENTORY) state Init;
	}
}
// This state forces entry into setup by deleting the lock file if it exists
state NewSetup {
	state_entry() {
		llRemoveInventory(NOTECARD_SETUP);
		state Setup;
	}
}
// Gives menu for setup
state Setup {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llListen(MenuChannel, "", OwnerId, "");
		llDialog(OwnerId, "\n\nSelect:", [
			"Set normal", "Set damaged", "Backup",
			"Normal", "Damaged", "Finished"
				], MenuChannel);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Message == "Finished") {
			if (NotecardExists(NOTECARD_NORMAL) && NotecardExists(NOTECARD_DAMAGE)) {
				osMakeNotecard(NOTECARD_SETUP, "");
				state Init;
			}
			else {
				llDialog(OwnerId, "\n\nCan't finish yet - both notecards needed", [ "OK" ], MenuChannel);
				return;
			}
		}
		else if (Message == "Set normal") {
			// save prim data to normal notecard
			// for set normal and damaged options, processing is deferred to "Save" option below
			SavingDamaged = FALSE;
			llDialog(OwnerId, "\n\nWrite data for NORMAL model?", [ "Save", "Cancel" ], MenuChannel);
			return;
		}
		else if (Message == "Set damaged") {
			// save prim data to damaged notecard
			SavingDamaged = TRUE;
			llDialog(OwnerId, "\n\nWrite data for DAMAGED model?", [ "Save", "Cancel" ], MenuChannel);
			return;
		}
		else if (Message == "Normal") {
			// set normal mode
			LoadNotecard(NOTECARD_NORMAL);
			SendLinkMessage(FALSE);
		}
		else if (Message == "Damaged") {
			// set damaged mode
			LoadNotecard(NOTECARD_DAMAGE);
			SendLinkMessage(TRUE);
		}
		else if (Message == "Backup") {
			// Pass both notecards to owner as backup
			llGiveInventory(OwnerId, NOTECARD_NORMAL);
			llGiveInventory(OwnerId, NOTECARD_DAMAGE);
		}
		else if (Message == "Save") {	// they confirmed the appropriate "set" option
			if (SavingDamaged)
				SaveNotecard(NOTECARD_DAMAGE, GetObjectData());
			else
				SaveNotecard(NOTECARD_NORMAL, GetObjectData());
		}
		state ReSetup;
	}
	touch_start(integer Total) {
		// owner can click for menu
		if (llDetectedKey(0) == OwnerId) state ReSetup;
	}
}
state ReSetup {	state_entry() { state Setup; }}
// Object damage v0.3