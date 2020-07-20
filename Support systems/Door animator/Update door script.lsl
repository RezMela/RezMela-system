
// Place this new door script in root prim, then add this script

string SCRIPT_NAME = "Door animator"; 	// change this as necessary
integer REMOTE_PIN = 1978123;

default {
	state_entry() {
		integer P = llGetNumberOfPrims();
		while(P-- > 1) {
			string Desc = llList2String(llGetLinkPrimitiveParams(P, [ PRIM_DESC ]), 0);
			if (llGetSubString(Desc, 0, 1) == "@D") {
				llOwnerSay("Updating: " + llGetLinkName(P));
				key PrimId = llGetLinkKey(P);
				llRemoteLoadScriptPin(PrimId, SCRIPT_NAME, REMOTE_PIN, TRUE, 0);
			}
		}
		llOwnerSay("Done!");
	}
}