// Drop into prim and it will list diffuse, normal and specular UUIDs and self-delete

default
{
	on_rez(integer start_param)
	{
		llResetScript();
	}
	state_entry()
	{
		llOwnerSay("Diffuse / Normal / Specular");
		integer sides = llGetNumberOfSides();
		integer side;
		for (side = 0; side < sides; side++) {
			key diffuse = llList2Key(llGetPrimitiveParams([ PRIM_TEXTURE, side ]), 0);
			key normal = llList2Key(llGetPrimitiveParams([ PRIM_NORMAL, side ]), 0);
			key specular = llList2Key(llGetPrimitiveParams([ PRIM_SPECULAR, side ]), 0);
			llOwnerSay((string)side + ": " + diffuse + " / " + normal + " / " + specular);
		}
		llRemoveInventory(llGetScriptName());
	}
}