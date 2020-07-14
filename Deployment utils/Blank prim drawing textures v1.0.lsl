
// Drop this into an App to blank out prim-drawing textures on the App itself

default {
	state_entry() {
		llOwnerSay("Blanking textures ...");
		integer PrimCount = llGetNumberOfPrims();
		integer P;
		integer F;
		// Activator prim
		integer Activator = -1;
		for (P = 1; P <= PrimCount; P++) {
			if (llGetLinkName(P) == "Activator") Activator = P;
		}
		if (Activator == -1) {
			llOwnerSay("ERROR! Can't find prim named 'Activator'");
		}
		else {
			// Activator prim has prim-drawing faces 1-4
			for (F = 1; F <= 4; F++) {
				llSetLinkTexture(Activator, TEXTURE_BLANK, F);
			}
		}
		// Modules
		for (P = 1; P <= PrimCount; P++) {
			string Name = llGetLinkName(P);
			if (llGetSubString(Name, 0, 5) == "&Lib: ") {
				llSetLinkTexture(P, TEXTURE_BLANK, 1);
				llSetLinkTexture(P, TEXTURE_BLANK, 3);
			}
		}
		llOwnerSay("Done.");
		llRemoveInventory(llGetScriptName());
	}
}