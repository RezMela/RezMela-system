
vector HOME = <219.2, 70, 21>;
float DELAY = 1.0;
integer Ptr;
integer Count;
float MARGIN = 10;
float GAP = 1.0;
float START_Y = 24.0;
float X;
float Y;

list Objects = [
	"BAECaiman",
	"Black4by4",
	"RMSF,1",
	"achouse",
	"apineforest",
	"avatarpicker",
	"batscoreserver",
	"blackbae",
	"blacktank",
	"bradleytank",
	"bus",
	"c_largefence",
	"c_thickforest",
	"c_twistyroad",
	"concrete_barrier",
	"cylindrical_cone",
	"czechog",
	"goalpost",
	"helicopter2",
	"howitzer",
	"ind5_coolingtower",
	"ind5_hall1",
	"ind5_hall3",
	"ind5_tank_beton",
	"militaryscoreb",
	"mine",
	"nutritiongame",
	"oztrees",
	"park",
	"puck",
	"racefinish",
	"racestart",
	"sandbags",
	"whitehowitzer"
		];

MoveTo(vector NewPos) {
	list Params = [];
	integer Jumps = (integer)(llVecDist(llGetPos(), NewPos) / 10.0) + 1;
	while(Jumps--) {
		Params += [ PRIM_POSITION, NewPos ];
	}
	llSetLinkPrimitiveParamsFast(1, Params);
}

default {
	state_entry() {
		HOME=llGetPos();
		llSetStatus(STATUS_RETURN_AT_EDGE, TRUE);
		X = MARGIN;
		Y = START_Y;
		Ptr = 0;
		Count = llGetInventoryNumber(INVENTORY_OBJECT);
		llOwnerSay("Time to rez: " + (string)llCeil(((float)Count * DELAY) / 60.0) + " mins");
		llSetTimerEvent(0.5);
	}
	timer() {
		llSetTimerEvent(0.0);
		if (Ptr > Count) {
			MoveTo(HOME);
			llOwnerSay("Done!");
			return;
		}
		string Name = llGetInventoryName(INVENTORY_OBJECT, Ptr);
		if (llListFindList(Objects, [ Name ]) == -1) {
			llOwnerSay(Name + " ignored");
			llSetTimerEvent(DELAY);
			Ptr++;
			return;
		}
		vector Pos = <X, Y, 23>;
		llOwnerSay(Name + " at " + (string)Pos);
		MoveTo(Pos);
		llRezObject(Name, Pos, ZERO_VECTOR, ZERO_ROTATION, 1);
		Ptr++;
		X += GAP;
		if (X > 256 - MARGIN) {
			X = MARGIN;
			Y += GAP;
		}
		llSetTimerEvent(DELAY);
	}
}