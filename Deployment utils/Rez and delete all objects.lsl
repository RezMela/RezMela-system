// Rez and delete all objects v1.1

float P = 5.0;
vector oldsize = ZERO_VECTOR;
integer count;
integer i;
list objects = [];
vector mypos;
key ownerid;
integer MENU_CHANNEL = -39208431;
string direction;

default
{
	state_entry() {
		ownerid = llGetOwner();
		llListen(MENU_CHANNEL, "", ownerid, "");
		llDialog(ownerid, "\n\nWhich way shall I rez the objects?", [ "Horizontal", "Vertical" ], MENU_CHANNEL);
	}
	listen(integer channel, string lname, key id, string message) {
		if (id != ownerid) return;
		if (message == "Horizontal") direction = "x"; else direction = "z";
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
	link_message(integer sender_number, integer number, string message, key id) {
		if (number == 12345)
		{
			string name = llList2String(objects, i);
			llOwnerSay(name);
			llRezObject(name, mypos + <0, 0, 1>, ZERO_VECTOR, ZERO_ROTATION, 0);
		}
	}
	object_rez(key id) {
		string name = llKey2Name(id);
		vector size = llList2Vector(osGetPrimitiveParams(id, [ PRIM_SIZE ]), 0);
		vector pos = mypos;
		if (direction == "x") {
			P += (oldsize.x / 2.0) + (size.x / 2.0) + 1.0;
			pos += <P, 0.0, (size.z / 2)>;
		}
		else {
			P += (oldsize.z / 2.0) + (size.z / 2.0) + 1.0;
			pos += <0.0, 0.0, P>;
		}
		integer c;
		for (c = 0; c < 50; c++) {
			osSetPrimitiveParams(id, [ PRIM_POSITION, pos ]);
		}
		vector npos = llList2Vector(osGetPrimitiveParams(id, [ PRIM_POSITION ]), 0);
		llRemoveInventory(name);
		oldsize = size;
		i++;
		if (i < count)
			llMessageLinked(LINK_THIS, 12345, "", NULL_KEY);
		else
			llRemoveInventory(llGetScriptName());
	}
}