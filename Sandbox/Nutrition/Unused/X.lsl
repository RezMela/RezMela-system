// Food controller v0.1
// Linked message constants. We use the integer portion of LMs as commands, because it's much
// cheaper to compare integers than strings, and strings and keys are more useful for data.
integer LM_PRIM_SELECTED = -405500;		// A prim has been selected (sent to other scripts)
integer LM_PRIM_DESELECTED = -405501;	// A prim has been deselected
integer LM_EXECUTE_COMMAND = -405502;	// Execute command (from other script)

integer MALL_CHANNEL = -84403270;

// List of selected prims that are food items
// Strided - format is [ LinkNum, AvId ]
list Selections;
integer ListenerHandle;

// is it a food item?
integer IsFood(integer LinkNum) {
	return (llGetSubString(llGetLinkName(LinkNum), 0, 1) == "+F");
}
// format of food data is "<name>|<calorific value>"
string GetFoodData(integer LinkNum) {
	string Name = llGetLinkName(LinkNum);
	// format of name is "+F <name>/<calories>"
	// eg "+F banana/90"
	Name = llStringTrim(llGetSubString(Name, 2, -1), STRING_TRIM);
	list Parts = llParseStringKeepNulls(Name, [ "/" ], []);
	Name = llList2String(Parts, 0);
	string Calories = llList2String(Parts, 1);
	return Name + "|" + Calories;
}
// Create listener if needed, kill it if not
SetListener() {
	if (llGetListLength(Selections)) {
		if (!ListenerHandle)
			ListenerHandle = llListen(MALL_CHANNEL, "", NULL_KEY, "");
	}
	else {
		llListenRemove(ListenerHandle);
		ListenerHandle = 0;
	}
}
AddSelection(integer LinkNum, key AvId) {
	Selections += [ LinkNum, AvId ];
}
DeleteSelection(integer Ptr) {
	Selections = llDeleteSubList(Selections, Ptr, Ptr + 1);
}
default {
	state_entry() {
		state Normal;
	}
}
state Normal {
	on_rez(integer start_param)	{ llResetScript(); }
	state_entry()	{
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
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
		SetListener();
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MALL_CHANNEL) {
			// format of incoming message is "FE<av uuid>|<npc attachment uuid>"
			if (llGetSubString(Message, 0, 1) == "FE") {		// it's notification of a click on NPC
				key AvId = llGetSubString(Message, 2, 37);
				key NpcObjectId = llGetSubString(Message, 39, -1);
				integer Ptr = llListFindList(Selections, [ AvId ]);
				if (Ptr > -1) {	// if it's an avatar that's selected food
					integer LinkNum = llList2Integer(Selections, Ptr - 1);
					// format of outgoing message is "+FC<food data>"
					llMessageLinked(LINK_THIS, LM_EXECUTE_COMMAND, "hide", AvId);
					llRegionSayTo(NpcObjectId, MALL_CHANNEL, "FC" + GetFoodData(LinkNum));
					DeleteSelection(Ptr);
				}
			}
		}
	}
}
// Food controller v0.1