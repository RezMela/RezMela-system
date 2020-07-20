
key AvId;
integer CameraLocked;

default {
	state_entry() {
		AvId = NULL_KEY;
		CameraLocked = FALSE;
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) {
			key Id = llAvatarOnSitTarget();
			if (Id == NULL_KEY) {
				if (AvId != NULL_KEY) {	// previous sitter
					llReleaseControls();
					AvId = NULL_KEY;
					CameraLocked = FALSE;
				}
			}
			else {
				AvId = Id;
				llRequestPermissions(AvId, PERMISSION_TRACK_CAMERA | PERMISSION_CONTROL_CAMERA | PERMISSION_TAKE_CONTROLS);
			}
		}
	}
	run_time_permissions(integer Perms) {
		if (PERMISSION_TAKE_CONTROLS & Perms) {
			llTakeControls(CONTROL_UP, TRUE, FALSE);
		}
		if (PERMISSION_CONTROL_CAMERA & Perms) {

		}
	}
	control(key id, integer level, integer edge) {
		integer start = level & edge;
		if (start) {
			vector MyPos = llGetPos();
			rotation MyRot = llGetRot();
			vector CameraPos = llGetCameraPos();
			rotation CameraRot = llGetCameraRot();
			vector CameraFocus = CameraPos + (<5.0, 0.0, 0.0> * CameraRot);
			llClearCameraParams();
			llSetCameraParams([
				CAMERA_ACTIVE, TRUE,
				CAMERA_POSITION_LAG, 2.0,
				CAMERA_POSITION, CameraPos,
				CAMERA_POSITION_LOCKED, TRUE,
				CAMERA_FOCUS, CameraFocus,
				CAMERA_FOCUS_LOCKED, TRUE
				]);
			llOwnerSay("Camera locked");
		}
	}
}