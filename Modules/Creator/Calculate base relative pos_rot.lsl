string BaseName = "X";

string NiceVector(vector V) {
	return ("<" + NiceFloat(V.x) + ", " + NiceFloat(V.y) + ", " + NiceFloat(V.z) + ">") ;
}
// Makes a nice string from a float - eg "0.1" instead of "0.100000", or "0.2" instead of "0.199999".
string NiceFloat(float F) {
	float X = 0.0001;
	if (F < 0.0) X = -X;
	string S = (string)(F + X);
	integer P = llSubStringIndex(S, ".");
	S = llGetSubString(S, 0, P + 3);
	while (llGetSubString(S, -1, -1) == "0" && llGetSubString(S, -2, -2) != ".")
		S = llGetSubString(S, 0, -2);
	return(S);
}

default {
	state_entry() {
		llSensor(BaseName, NULL_KEY, PASSIVE|SCRIPTED, 50.0, PI);
	}
	sensor(integer Count) {
		if (Count > 1) {
			llOwnerSay("Found " + (string)Count + " objects named '" + BaseName + "!");
			state Finish;
		}
		key BaseKey = llDetectedKey(0);
		list L = llGetObjectDetails(BaseKey, [ OBJECT_POS, OBJECT_ROT ]);
		vector BasePos = llList2Vector(L, 0);
		rotation BaseRot = llList2Rot(L, 1);
		vector MyPos = llGetPos();
		rotation MyRot = llGetRot();
		vector RelPos = MyPos - BasePos;
		rotation RelRot = MyRot / BaseRot;
		string MyName = llGetObjectName();
		vector RelRotV = llRot2Euler(RelRot) * RAD_TO_DEG;
		string Line = MyName + "|" + NiceVector(RelPos);
		if (RelRotV != ZERO_VECTOR) {
			Line += "|" + NiceVector(RelRotV);
		}
		llOwnerSay("Copy this:\n" + Line);
		state Finish;
	}
	no_sensor() {
		llOwnerSay("Object not found: " + BaseName);
		state Finish;
	}
}
state Finish {
	state_entry() {
		llOwnerSay("Script removed");
		llRemoveInventory(llGetScriptName());
	}
}
