
key OwnerId;
list CastOptions;
vector LastPos;
rotation LastRot;
key LastId;

list Words = [
	"wall", "la pared",
	"chair", "la silla",
	"table", "la mesa",
	"lamp", "la lampara",
	"door", "la porta",
	"floor", "el suelo"
	];

default {
	state_entry() {
		llSetText("Loading ...", ZERO_VECTOR, 1.0);
		OwnerId = llGetOwner();
		CastOptions = [ RC_REJECT_TYPES, RC_REJECT_AGENTS | RC_REJECT_LAND, RC_MAX_HITS, 1 ];
		LastPos = <-123.45, 543.21, 987.65>;
		LastRot = <-123.45, 543.21, 987.65, -543.21>;
		LastId = NULL_KEY;
		llRequestPermissions(OwnerId, PERMISSION_TRACK_CAMERA);
	}
	run_time_permissions(integer Perms) {
		if (Perms & PERMISSION_TRACK_CAMERA) {
			llSetTimerEvent(2.0);
		}
	}
	timer() {
		vector CamPos = llGetCameraPos();
		rotation CamRot = llGetCameraRot();
		if (CamPos == LastPos && CamRot == LastRot) {
			return;
		}
		LastPos = CamPos;
		LastRot = CamRot;
		//CamPos += <2.0, 0.0, 0.0>  * CamRot;
		vector CastTarget = CamPos + (<10.0, 0.0, 0.0> * CamRot);
		list L = llCastRay(CamPos, CastTarget, CastOptions);
		if (llGetListLength(L) == 1) {
			llSetText("", ZERO_VECTOR, 0.0);
			LastId = NULL_KEY;
			return;
		}
		key TargetId = llList2Key(L, 0);
		if (TargetId == LastId) {
			return;
		}
		LastId = TargetId;
		string Name = llKey2Name(TargetId); 
		string Translation = "?";
		integer I = llListFindList(Words, [ Name ]);
		if (I > -1) {
			Translation = llList2String(Words, I + 1);
		}
		llSetText(Name + "\n-\n" + Translation, ZERO_VECTOR, 1.0);
	}
}