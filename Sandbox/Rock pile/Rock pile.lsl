// Rock pile v0.4

// v0.4 - performance improvements

integer SCRIPT_PIN = 1030;

// Delegated deletion stuff
integer LM_DELEGATE_DELETION = -7044001;
integer LM_DELETE_RECEIVED = -7044002;

integer PrimCount;
list RockKeys;
integer RockCount;
string ScriptName;
integer LinkMessageCount;
float FloorHeight;
float RepositionHeight;
integer SetSoloParams = FALSE;

CopyScript() {
	llOwnerSay("Updating scripts ...");
	integer P;
	for(P = 2; P <= PrimCount; P++) {
		llOwnerSay("Doing '" + llGetLinkName(P) + "' (" + (string)(P - 1) + "/" + (string)(PrimCount - 1) + ")");
		key PrimKey = llGetLinkKey(P);
		llRemoteLoadScriptPin(PrimKey, ScriptName, SCRIPT_PIN, TRUE, 0);
	}
	llOwnerSay("Update finished.");
}
// wrapper for osMessageObject() that checks to see if object exists
MessageObject(key Uuid, string Text) {
	if (ObjectExists(Uuid)) {
		osMessageObject(Uuid, Text);
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
Die() {
	while(1 == 1) {
		llDie();
	}
}
default {
	on_rez(integer Param) {
		llSetRemoteScriptAccessPin(SCRIPT_PIN);
		PrimCount = llGetNumberOfPrims();
		ScriptName = llGetScriptName();
		// if this prim is unlinked, we don't change state
		if (PrimCount > 1) {
			if (llGetLinkNumber() == 1) {	// if we're the root prim
				// if we're manually started, all we do is copy this script into the rocks
				if (Param == 0) {
					CopyScript();	// if we're not rezzed by the control board, update scripts in child prims
				}
				else {	// if we're rezzed by the control board
					state Controller;
				}
			}
			else {
				if (Param) {
					state Rock;
				}
			}
		}
	}
	changed(integer Change)	{
		if (Change & CHANGED_LINK) llResetScript();
	}
}
// This state is only achieved by non-root prims (ie rocks) when rezzed from the control board
state Rock {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		// calculate the height we should maintain (to avoid the sinking underground bug of OpenSim)
		vector RootPos = llGetRootPosition();
		vector MyScale = llGetScale();
		FloorHeight = RootPos.z;
		RepositionHeight = FloorHeight + MyScale.z / 2.0;
		SetSoloParams = FALSE;
		llSetTimerEvent(3.0 + llFrand(4.0));
	}
	dataserver(key Id, string Data) {
		if (Data == "delete") Die();
	}
	timer() {
		if (llGetLinkNumber()) return;
		if (!SetSoloParams) {
			llSetStatus(STATUS_PHYSICS | STATUS_DIE_AT_EDGE, TRUE);
			SetSoloParams = TRUE;
		}
		vector MyPos = llGetPos();
		if (MyPos.z < FloorHeight) {
			MyPos.z = RepositionHeight;
			llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_POSITION, MyPos ]);
		}
	}
}
// This state is only achieved by the root prim when rezzed from the control board
state Controller {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		RockKeys = [];
		integer P;
		for(P = 2; P <= PrimCount; P++) {
			key PrimKey = llGetLinkKey(P);
			RockKeys += PrimKey;
		}
		RockCount = llGetListLength(RockKeys);
		llSetTimerEvent(4.0);
		LinkMessageCount = 0;
	}
	link_message(integer Sender, integer Number, string Message, key Id)	{
		if (Number == LM_DELETE_RECEIVED) {
			integer P;
			for(P = 0; P < RockCount; P++) {
				key RockKey = llList2Key(RockKeys, P);
				MessageObject(RockKey, "delete");
			}
			Die();
		}
	}
	timer() {
		llMessageLinked(LINK_THIS, LM_DELEGATE_DELETION, "", NULL_KEY);
		if (LinkMessageCount++ > 10) llSetTimerEvent(0.0);
		PrimCount = llGetNumberOfPrims();
		if (PrimCount > 1) {
			while(--PrimCount) osForceBreakLink(2);	// unlink all prims
		}

	}
}
// Rock pile v0.4