// Nutrition LM controller v0.5

// v0.5 - added delay to updating NPC outfit (to avoid update while following)

// Format of following info:
// llRegionSay(-84403270, "FF" + (string)llGetOwner() + (string)targetKey);

integer CALORIES_MIN = 200;				// keep these values in sync with NPC nutrition
integer CALORIES_MAX = 1800;			// keep these values in sync with NPC nutrition

// Linked message constants. We use the integer portion of LMs as commands, because it's much
// cheaper to compare integers than strings, and strings and keys are more useful for data.
integer LM_PRIM_SELECTED = -405500;		// A prim has been selected (sent to other scripts)
integer LM_PRIM_DESELECTED = -405501;	// A prim has been deselected
integer LM_EXECUTE_COMMAND = -405502;	// Execute command (from other script)

integer MALL_CHANNEL = -84403270;

// List of selected prims that are food items
// Strided - format is [ LinkNum, AvId ]
list Selections;

// List of NPCs
list Npcs;
integer NPC_ID = 0;
integer NPC_NAME = 1;
integer NPC_CALORIES = 2;
integer NPC_NOTECARD = 3;	// current notecard
integer NPC_STRIDE = 4;

// List of NPCs who are following avatars
// NPCs who are following should not have outfit changes until they
// stop following (since those changes would replace the attachment that is doing
// the following and cause them to stop)
// List contains only NPC UUIDs
list Followers;

// List of NPCs with pending outfit updates
// Strided - format is [ NpcId, Notecard ]
list OutfitChanges;

// List of NPC body notecards
list NpcBodies;
integer NB_NAME = 0;
integer NB_CALORIES = 1;
integer NB_DEFAULT = 2;
integer NB_NOTECARD = 3;
integer NB_STRIDE = 4;
integer NpcBodyCount;

// Reads NPC body notecards into "Npcs" table (strided list)
// Notecard names are in the format: B/<NPC name>/<Calories (from)>/<Default?>
ReadNpcNotecards() {
	NpcBodies = [];
	integer N = llGetInventoryNumber(INVENTORY_NOTECARD);
	while(N--) {
		string NotecardName = llGetInventoryName(INVENTORY_NOTECARD, N);
		if (llGetSubString(NotecardName, 0, 1) == "B/") {		// it's a body notecard
			list Parts = llParseStringKeepNulls(NotecardName, [ "/" ], []);
			string NpcName = llList2String(Parts, 1);
			integer Calories = (integer)llList2String(Parts, 2);
			integer DefaultFlag = (integer)llList2String(Parts, 3);
			NpcBodies += [ NpcName, Calories, DefaultFlag, NotecardName ];
		}
	}
	NpcBodies = llListSort(NpcBodies, NPC_STRIDE, TRUE);	// sort into ascending name
	NpcBodyCount = llGetListLength(NpcBodies);
}
// Calculate initial calories level for NPC
integer GetInitialCalories(string NpcName) {
	integer CalsLow = -1;
	list Cals = [];
	integer P;
	// First we (a) build up a list of all the available calorie values (notecards) for this NPC
	// and (b) find out which is the default
	for(P = 0; P < NpcBodyCount; P += NB_STRIDE) {
		string ThisName = llList2String(NpcBodies, P + NB_NAME);
		if (ThisName == NpcName) {
			integer ThisCalories = llList2Integer(NpcBodies, P + NB_CALORIES);
			integer ThisDefault = llList2Integer(NpcBodies, P + NB_DEFAULT);
			if (ThisDefault) {
				CalsLow = ThisCalories;
			}
			Cals += ThisCalories;
		}
	}
	// Now we know the default, we need the next highest
	Cals = llListSort(Cals, 1, TRUE);	// sort by calorie values
	integer CalsHigh = CalsLow;			// assume it's actually the highest anyway
	P = llListFindList(Cals, [ CalsLow ]);	// but ...
	if ((P + 1) < llGetListLength(Cals)) {	// ... if there are higher ones ...
		CalsHigh = llList2Integer(Cals, P + 1);		// ... pick the next one
	}
	integer InitialCalories = CalsLow + ((CalsHigh - CalsLow) / 2);	// halfway twixt low and high
	return InitialCalories;
}
// Sets NPC appropriate to new weight
WeightChange(integer NpcPtr, integer CalorieChange, string Description, key NpcObjectId) {
	integer StoredCalories = llList2Integer(Npcs, NpcPtr + NPC_CALORIES);
	string NpcName = llList2String(Npcs, NpcPtr + NPC_NAME);
	key NpcId = llList2Key(Npcs, NpcPtr + NPC_ID);
	string CurrentNotecard = llList2String(Npcs, NpcPtr + NPC_NOTECARD);
	// Add or subtract calories
	if (CalorieChange != 0) {
		StoredCalories += CalorieChange;
		if (StoredCalories > CALORIES_MAX) StoredCalories = CALORIES_MAX;
		else if (StoredCalories < CALORIES_MIN) StoredCalories = CALORIES_MIN;
		Npcs = llListReplaceList(Npcs, [ StoredCalories ], NpcPtr + NPC_CALORIES, NpcPtr + NPC_CALORIES);	// update new stored calories
	}
	// Next, we calculate which body they should have
	string MatchingNotecard = "";
	integer BestMatch = -1;
	integer P;
	for(P = 0; P < NpcBodyCount; P += NB_STRIDE) {
		string ThisName = llList2String(NpcBodies, P + NB_NAME);
		if (ThisName == NpcName) {
			integer ThisCalories = llList2Integer(NpcBodies, P + NB_CALORIES);
			if (ThisCalories > BestMatch && ThisCalories <= StoredCalories) {
				BestMatch = ThisCalories;
				MatchingNotecard = llList2String(NpcBodies, P + NB_NOTECARD);
			}
		}
	}
	// Affect NPC movement speed
	// laying this out line-by-line for now
	integer IdealWeight = CALORIES_MIN + ((CALORIES_MAX - CALORIES_MIN) / 2);
	//	llOwnerSay("\n----------------------\nWeight = " + (string)StoredCalories);
	//	llOwnerSay("Ideal weight = " + (string)IdealWeight);
	float Variation = (float)llAbs(StoredCalories - IdealWeight);		// how many calories they area away from the ideal weight
	//	llOwnerSay("Variation = " + (string)Variation);
	Variation = Variation / (float)IdealWeight;			// make it a proportion of ideal weight (eg 25% over/underweight == 0.25)
	//	llOwnerSay("Proportion = " + (string)Variation);
	Variation *= 0.7;						// reduce the effect (this could be tuned)
	Variation = 1.0 - Variation;			// make the effect reduce the speed
	Variation += llFrand(0.1);		// add a little random variation
	//	llOwnerSay("setting " + llKey2Name(NpcId) + " to speed " + (string)Variation);
	osSetSpeed(NpcId, Variation);
	//	llOwnerSay("Setting: " + llKey2Name(NpcId) + " to  " + (string)Variation);
	if (MatchingNotecard == "") MatchingNotecard = CurrentNotecard;		// if there's no lower-valued notecard, keep the current one
	// Do we need a new body?
	if (MatchingNotecard != CurrentNotecard) {		// yes, it's a different notecard
		Npcs = llListReplaceList(Npcs, [ MatchingNotecard ], NpcPtr + NPC_NOTECARD, NpcPtr + NPC_NOTECARD);	// update notecard in NPCs table
		// add NPC to outfit change queue
		integer OP = llListFindList(OutfitChanges, [ NpcId ]);	// test if already in queue
		if (OP > -1) OutfitChanges = llDeleteSubList(OutfitChanges, OP, OP + 1);	// if so, delete previous entry
		OutfitChanges += [ NpcId, MatchingNotecard ];	// add this entry to queue
	}
	// format of data is "FD<stored calories>|<food name>|<food calories>"
	SendNpcMessage(NpcObjectId, "FD" + (string)StoredCalories + "|" + Description + "|" + (string)CalorieChange);
	UpdateOutfits();		// if NPC is not following, this will cause outfit change if necessary
}
UpdateOutfits() {
	list NewOutfitChanges = [];	// to avoid hassle with deleting from a list that's being processed, we rebuild the list each time
	integer Len = llGetListLength(OutfitChanges);
	integer P;
	for (P = 0; P < Len; P += 2) {
		key NpcId = llList2Key(OutfitChanges, P);
		string Notecard = llList2String(OutfitChanges, P + 1);
		if (llListFindList(Followers, [ NpcId ]) == -1) {	// if the NPC is not following
			//llOwnerSay("Loading NPC with: " + Notecard);
			osNpcLoadAppearance(NpcId, Notecard);		// change NPC appearance
		}
		else {		// NPC is following someone, so keep them in the queue
			NewOutfitChanges += [ NpcId, Notecard ];
		}
	}
	OutfitChanges = NewOutfitChanges;
}
// Return FALSE if NPC doesn't have notecard(s)
integer CheckNpcExists(key NpcId) {
	string NpcName = llKey2Name(NpcId);
	if (NpcName == "") {	// probably can't happen (otherwise we'd not be called)
		llOwnerSay("No NPC found with key: " + (string)NpcId);
		return FALSE;
	}
	integer Found = FALSE;
	integer P;
	for(P = 0; P < NpcBodyCount; P += NB_STRIDE) {
		string ThisName = llList2String(NpcBodies, P + NB_NAME);
		if (ThisName == NpcName) Found = TRUE;
	}
	if (Found) return TRUE;
	llOwnerSay("No notecards for NPC '" + NpcName + "'");
	return FALSE;
}
SendNpcMessage(key NpcId, string Message) {
	llRegionSayTo(NpcId, MALL_CHANNEL, Message);
}
// is prim a food item?
integer IsFood(integer LinkNum) {
	return (llGetSubString(llGetLinkName(LinkNum), 0, 1) == "+F");
}
// format of food data is  [ <food name>, <food calories> ]"
list GetFoodData(integer LinkNum) {
	string Name = llGetLinkName(LinkNum);
	// format of name is "+F <name>/<calories>"
	// eg "+F banana/90"
	Name = llStringTrim(llGetSubString(Name, 2, -1), STRING_TRIM);
	list Parts = llParseStringKeepNulls(Name, [ "/" ], []);
	Name = llList2String(Parts, 0);
	integer FoodCalories = (integer)llList2String(Parts, 1);
	return [ Name, FoodCalories ];
}
// Add an entry in the Selections table
AddSelection(integer LinkNum, key AvId) {
	Selections += [ LinkNum, AvId ];
}
// Delete an entry from the Selections table
DeleteSelection(integer Ptr) {
	Selections = llDeleteSubList(Selections, Ptr, Ptr + 1);
}
default {
	state_entry() {
		Npcs = [];
		state Init;
	}
}
state Init {
	on_rez(integer Param)	{ llResetScript(); }
	state_entry()	{
		ReadNpcNotecards();
		state Normal;
	}
}
state Normal {
	on_rez(integer start_param)	{ llResetScript(); }
	state_entry()	{
		llListen(MALL_CHANNEL, "", NULL_KEY, "");
		llSetTimerEvent(3.0);		// exact period is not important; 3s seems about right
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		// When the main LM script tells us a prim is selected or deselected, we update our Selections table
		if (Number == LM_PRIM_SELECTED) {
			integer LinkNum = (integer)Message;
			if (IsFood(LinkNum)) {
				AddSelection(LinkNum, Id);
			}
		}
		else if (Sender == LM_PRIM_DESELECTED) {
			integer LinkNum = (integer)Message;
			integer Ptr = llListFindList(Selections, [ LinkNum ]);
			if (Ptr > -1) DeleteSelection(Ptr);
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MALL_CHANNEL) {
			string MessageType = llGetSubString(Message, 0, 1);		// first two chars of message are its type
			if (MessageType == "FR") {
				// Extract data from message
				// format of incoming FR message is "FR<NPC id>|<NPC name>|<click Av ID>
				key NpcObjectId = Id;
				list Parts = llParseStringKeepNulls(llGetSubString(Message, 2, -1), [ "|" ], []);
				key NpcId = (key)llList2String(Parts, 0);
				string NpcName = llList2String(Parts, 1);
				key AvId = (key)llList2String(Parts, 2);
				if (!CheckNpcExists(NpcId)) return;	// check there are notecards for this NPC
				// try to find NPC in table
				integer CalorieChange = 0;
				string Description = "Initial";;
				// One of two possibilities here:
				// 1. We have a null AvId, meaning that the NPC is checking in for the first time
				//		You'd expect the NPC not to exist in the Npcs table
				// 2. We have a non-null nAvID, meaning that someone has fed the NPC
				//		You'd expect the NPC to exist previously in the Npcs table
				// But we must be tolerant of other states too.
				integer NpcPtr = llListFindList(Npcs, [ NpcId ]);
				if (NpcPtr == -1) {
					// doesn't exist - new NPC
					// So first, we add the NPC to the table
					NpcPtr = llGetListLength(Npcs);		// this is where it will be when we add it
					integer StoredCalories = GetInitialCalories(NpcName);
					Npcs += [ NpcId, NpcName, StoredCalories, "" ];
				}
				if (AvId != NULL_KEY) {		// an attempt to eat food
					// Find selected food item
					integer Ptr = llListFindList(Selections, [ AvId ]);
					if (Ptr > -1) {	// if it's an avatar that's selected food
						integer LinkNum = llList2Integer(Selections, Ptr - 1);
						llMessageLinked(LINK_THIS, LM_EXECUTE_COMMAND, "hide", AvId);
						list FoodParts = GetFoodData(LinkNum);
						Description = llList2String(FoodParts, 0);		// food name (we don't use this at the moment)
						CalorieChange = llList2Integer(FoodParts, 1);
						DeleteSelection(Ptr);
					}
					else {	// looks like an av clicked on the NPC, but didn't have food selected
						return;
					}
				}
				WeightChange(NpcPtr, CalorieChange, Description, NpcObjectId);
			}
			else if (MessageType == "FE") {
				// it's exercise (passed from exerciser to NPC attachment to us)
				list Parts = llParseStringKeepNulls(llGetSubString(Message, 2, -1), [ "|" ], []);
				key NpcId = (key)llList2String(Parts, 0);
				if (!CheckNpcExists(NpcId)) return;	// check there are notecards for this NPC
				string ExerciserName = llList2String(Parts, 1);
				integer CaloriesBurned = (integer)llList2String(Parts, 2);
				integer NpcPtr = llListFindList(Npcs, [ NpcId ]);
				if (NpcPtr > -1) {
					WeightChange(NpcPtr, -CaloriesBurned, ExerciserName, NpcId);
				}
			}
			else if (MessageType == "FF") {
				// it's a notification of following status
				// NPCs broadcast FF messages when following starts or stops, and periodically in-between
				key NpcId = llGetSubString(Message, 2, 37);
				key FollowingAvId = llGetSubString(Message, 38, 73);		// this will be null if they're not following
				integer FP = llListFindList(Followers, [ NpcId ]);
				if (FP > -1) {	// if they're in the followers list
					if (FollowingAvId == NULL_KEY) {	// but they're not following anyone
						Followers = llDeleteSubList(Followers, FP, FP);		// delete them from the list
					}
				}
				else {			// if they're not in the followers list
					if (FollowingAvId != NULL_KEY) {	// but they are following someone
						Followers += NpcId;		// add them to the list
					}
				}
			}
			else if (MessageType == "PI") {		// ping
				llRegionSayTo(Id, MALL_CHANNEL, "PO");	// pong
			}
		}
	}
	timer() {
		UpdateOutfits();		
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) state Init;
	}
}
// Nutrition LM controller v0.5