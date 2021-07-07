
integer TOTAL = 500;

string drop_object;

vector my_pos;
vector my_scale;

integer counter;


default {
	on_rez(integer p) { llResetScript(); }
	state_entry() {
	}
	touch_start(integer total_number) {
		drop_object = llGetInventoryName(INVENTORY_OBJECT, 0);
		my_pos = llGetPos();
		my_scale = llGetScale();
		counter = 0;
		llMessageLinked(LINK_THIS, 12345, "", NULL_KEY);
	}
	link_message(integer sender_number, integer number, string message, key id) {
		if (number != 12345) return;
		float z = my_pos.z - (my_scale.z / 2.0) - 1.0;
			float x = my_pos.x + llFrand(20.0) - 10;
			float y = my_pos.y + llFrand(20.0) - 10;
			llRezObject(drop_object, <x, y, z>, ZERO_VECTOR, ZERO_ROTATION, 1);
		if (counter++ < TOTAL) llMessageLinked(LINK_THIS, 12345, "", NULL_KEY);
	}
	moving_end() {
		my_pos = llGetPos();
	}
	object_rez(key id) {
		osSetPrimitiveParams(id, [
			PRIM_TEMP_ON_REZ, TRUE,
			PRIM_PHANTOM, FALSE,
			PRIM_PHYSICS, TRUE
				]);
	}
}