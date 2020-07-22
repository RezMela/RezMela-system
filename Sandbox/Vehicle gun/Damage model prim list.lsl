// lists prim pos/rot

string ObjectName;

string Vector2String(vector V) {
	return("<" + Float2String(V.x) + ", " + Float2String(V.y) + ", " + Float2String(V.z) + ">");
}
string Float2String(float F) {
	string S = (string)F;
	integer P = llSubStringIndex(S, ".");
	if (P > -1) {
		S = llGetSubString(S, 0, P + 3);
	}
	if (S == "0.000") S = "0.0";
	return(S);
}
Say(string Text) {
	llSetObjectName("");
	llOwnerSay("/me " + Text);
	llSetObjectName(ObjectName);
}
default {
	state_entry() {
		ObjectName = llGetObjectName();
		integer L = llGetNumberOfPrims();
		string Output;
		integer P;
		for(P = 2; P <= L; P++) {
			string Name = llGetLinkName(P);
			if (llSubStringIndex(Name, " button") == -1) {
				if (Name == "Primitive") llSetLinkPrimitiveParamsFast(P, [ PRIM_GLOW, 1.0 ]);
				vector Pos = llList2Vector(llGetLinkPrimitiveParams(P, [ PRIM_POS_LOCAL ]), 0);
				rotation rRot = llList2Rot(llGetLinkPrimitiveParams(P, [ PRIM_ROT_LOCAL ]), 0);
				vector Rot = llRot2Euler(rRot);
				Output += Name + ", " + Vector2String(Pos) + ", " + Vector2String(Rot) + "\n";
			}
		}
		llOwnerSay((string)L + " prims:\n" + Output );
	}
}