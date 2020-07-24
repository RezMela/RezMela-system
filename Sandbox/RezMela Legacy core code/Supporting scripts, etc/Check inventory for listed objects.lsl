list Objects = [
	"BAECaiman",
	"Black4by4",
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

default
{
	state_entry()
	{
		integer Len = llGetListLength(Objects);
		integer P;
		for(P = 0; P < Len; P++) {
			string Name = llList2String(Objects, P);
			Name = Name + "P";	// for objects only
			if (llGetInventoryType(Name) != INVENTORY_OBJECT) llOwnerSay("Missing: " + Name);
		}
	}
}