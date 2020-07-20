// NPC nutrition v0.5

vector TEXT_COLOR = <1.0, 1.0, 1.0>;

integer MALL_CHANNEL = -84403270;
float CALORIES_MIN = 200.0;				// keep these values in sync with nutrition controller
float CALORIES_MAX = 1800.0;			// keep these values in sync with nutrition controller
float METER_SIZE_MAX = 1.0;
// Timer values for passive calorie burning
float TIMER = 10.0;				// frequency of timer (secs)
integer TIMED_NORMAL = 6;		// Amount of calories lost per TIMER seconds for each activity
integer TIMED_WALKING = 20;

key ObjectId;
key NpcId;
string NpcName;
key FoodServerId;
float FoodServerDistance;
integer StoredCalories;

list Charset_LeftRight      = ["   ","▏","▎","▍","▌","▋","▊","▉","█"];

string Bars( float Cur, integer Bars, list Charset ){
	// Input    = 0.0 to 1.0
	// Bars     = char length of progress bar
	// Charset  = [Blank,<Shades>,Solid];
	integer Shades = llGetListLength(Charset)-1;
	Cur *= Bars;
	integer Solids  = llFloor( Cur );
	integer Shade   = llRound( (Cur-Solids)*Shades );
	integer Blanks  = Bars - Solids - 1;
	string str;
	while( Solids-- >0 ) str += llList2String( Charset, -1 );
	if( Blanks >= 0 ) str += llList2String( Charset, Shade );
	while( Blanks-- >0 ) str += llList2String( Charset, 0 );
	return str;
}

// Send an FR message, a basic message indicating who we are and (if applicable) who clicked us
SendData(key ClickAvId) {
	string Data = "FR" + (string)NpcId + "|" + (string)NpcName + "|" + (string)ClickAvId;
	llRegionSayTo(FoodServerId, MALL_CHANNEL, Data);
}
// Handle the meter display stuff
Display(string SourceName, integer NewCalories) {
	float fCals = (float)StoredCalories;
	if (fCals < CALORIES_MIN) fCals = CALORIES_MIN;
	else if (fCals > CALORIES_MAX) fCals = CALORIES_MAX;
	float Level = (fCals - CALORIES_MIN)/(CALORIES_MAX - CALORIES_MIN);	// range 0-1
	string Text = "▕"+Bars( Level, 10, Charset_LeftRight )+"▏";
	llSetText( Text, <0,1,0>, 1.0 );	
	//Level = 0.252 + (Level / 2.04);    // range 0.25-0.75 roughly (adjustments for SL texturing imperfections)
	//llSetLinkPrimitiveParamsFast(MeterLinkNum, [ PRIM_TEXTURE, 1, MeterGraphic, <1.0, -0.5, 0.0>, <1.0, Level, 0.0>, 0.0 ]);
}
default {
	on_rez(integer start_param)	{ llResetScript(); }
	state_entry() {
		ObjectId = llGetKey();
		NpcId = llGetOwner();
		if (!osIsNpc(NpcId)) {
			llOwnerSay("Not an NPC - suspending");
			state Hang;
		}
		NpcName = llKey2Name(NpcId);
		// Find nearest food server
		FoodServerId = NULL_KEY;
		FoodServerDistance = 9999.0;
		llListen(MALL_CHANNEL, "", NULL_KEY, "");
		llRegionSay(MALL_CHANNEL, "PI");	// ping
		llSetTimerEvent(3.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MALL_CHANNEL && Message == "PO") {		// pong
			vector ServerPos = llList2Vector(llGetObjectDetails(Id, [ OBJECT_POS ]), 0);
			float ThisDistance = llVecDist(llGetPos(), ServerPos);
			if (ThisDistance < FoodServerDistance) {
				FoodServerDistance = ThisDistance;
				FoodServerId = Id;
			}
		}
	}
	timer() {
		if (FoodServerId == NULL_KEY) {
			llOwnerSay("Can't find food server - retrying");
			llRegionSay(MALL_CHANNEL, "PI");	// ping			
		}
		else {
			llSetTimerEvent(0.0);
			state Init;
		}
	}
}
state Init {
	on_rez(integer start_param)	{ llResetScript(); }
	state_entry() {
		// listen for the server
		llListen(MALL_CHANNEL, "", FoodServerId, "");
		// PING to find server and get our data
		SendData(NULL_KEY);
		llSetTimerEvent(30.0);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		string MessageType = llGetSubString(Message, 0, 1);
		if (MessageType == "FD") {		// initial setup data
			// format of data is "FD<stored calories>"
			StoredCalories = (integer)llGetSubString(Message, 2, -1);
			Display("", 0);		// initialise the meter
			state Normal;
		}
	}
	timer() {
		llOwnerSay("Lost contact with server during initialization - retrying");
		SendData(NULL_KEY);		
	}
}
state Normal {
	on_rez(integer start_param)	{ llResetScript(); }
	state_entry() {
		llSetTimerEvent(TIMER);
		llListen(MALL_CHANNEL, "", NULL_KEY, "");
	}
	touch_start(integer Total) {
		key AvId = llDetectedKey(0);
		// This may have been an instruction to eat a food item
		// So we tell the nutrition controller this, and let it
		// decide what to do
		SendData(AvId);
	}
	listen(integer Channel, string Name, key Id, string Message) {
		string MessageType = llGetSubString(Message, 0, 1);
		if (MessageType == "FD" && Id == FoodServerId) {		// we have data from the server
			// format of data is "FD<stored calories>|<food name>|<food calories>"
			list Parts = llParseStringKeepNulls(llGetSubString(Message, 2, -1), [ "|" ], []);
			StoredCalories = (integer)llList2String(Parts, 0);
			string SourceName = llList2String(Parts, 1);
			integer NewCalories = (integer)llList2String(Parts, 2);
			Display(SourceName, NewCalories);
		}
		else if (MessageType == "FE") {	 // we have data from an exerciser
			// "FE" format is "FE<NPC ID>|<exercise name>|<calories burned>"
			llRegionSayTo(FoodServerId, MALL_CHANNEL, Message);		// pass it on to server
		}
	}
	timer() {
		integer Cals = TIMED_NORMAL;
		integer Info = llGetAgentInfo(NpcId);
		if (Info & AGENT_WALKING) Cals = TIMED_WALKING;
		// "FE" format is "FE<NPC ID>|<exercise name>|<calories burned>"
		llRegionSayTo(FoodServerId, MALL_CHANNEL, "FE" + (string)NpcId + "|passive|" + (string)Cals);
	}
}
state Hang {
	on_rez(integer Param)	{ llResetScript(); }
	attach(key Attached) { llResetScript(); }
}
// NPC nutrition v0.5