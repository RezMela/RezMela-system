default {
	state_entry() {
		llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA);
	}
	run_time_permissions(integer Perms)	{
		if (Perms & PERMISSION_TRACK_CAMERA) {
			llSetTimerEvent(1.0);
		}
	}
	timer() {
		rotation R = llGetCameraRot();
		vector P = llGetCameraPos();
		vector V = llRot2Euler(R) * RAD_TO_DEG;
		integer X = (integer)V.x;
		integer Y = (integer)V.y;
		integer Z = (integer)V.z;
		llSetText((string)X + ", " + (string)Y + ", " + (string)Z +
			"\n" + (string)P
			, <1,1,1>, 1);
	}
}