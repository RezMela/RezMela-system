
float X = 5.0;
vector oldsize = ZERO_VECTOR;
integer count;
integer i;
list objects = [];
vector mypos;

default
{
	state_entry()
	{
		mypos = llGetPos();
		count = llGetInventoryNumber(INVENTORY_OBJECT);
		llOwnerSay("Rezzing " + (string)count + " objects:");
		for (i = 0; i < count; i++) {
			string name = llGetInventoryName(INVENTORY_OBJECT, i);
			objects += name;
		}
		i = 0;
		llMessageLinked(LINK_THIS, 12345, "", NULL_KEY);
	}
	link_message(integer sender_number, integer number, string message, key id)
	{
		if (number == 12345)
		{
			string name = llList2String(objects, i);
        	llOwnerSay(name);
			llRezObject(name, mypos + <0, 0, 1>, ZERO_VECTOR, ZERO_ROTATION, 0);
		}
	}
	object_rez(key id)
	{
		string name = llKey2Name(id);
		vector size = llList2Vector(osGetPrimitiveParams(id, [ PRIM_SIZE ]), 0);
		X += (oldsize.x / 2.0) + (size.x / 2.0) + 1.0;
		vector pos = mypos + <X, 0.0, (size.z / 2)>;
		integer z;
		for (z = 0; z < 50; z++) {
			osSetPrimitiveParams(id, [ PRIM_POSITION, pos ]);
		}
		llRemoveInventory(name);
		oldsize = size;
		i++;
		if (i < count)
			llMessageLinked(LINK_THIS, 12345, "", NULL_KEY);
		else
			llRemoveInventory(llGetScriptName());
	}
}