float DELAY = 0.5;   // Seconds between blinks; lower for more lag
float RANGE = 1.0;   // Meters away that we stop walking towards
float TAU = 1.0;     // Make smaller for more rushed following
integer follow_flag = 0;
//key NonPlayerChar = NULL_KEY;
// Avatar Follower script, by Dale Innis
// Do with this what you will, no rights reserved
// See https://wiki.secondlife.com/wiki/AvatarFollower for instructions and notes

float LIMIT = 60.0;   // Approximate limit (lower bound) of llMoveToTarget

integer lh = 0;

string targetName = "";
key targetKey = NULL_KEY;
integer announced = FALSE;

integer dialog_channel;
integer dialog_listen_handle;

integer npc_control_handle;
integer NPC_CONTROL_CHANNEL = -72;

string who_selected_me ="";
integer selected_state = 0;


list order_buttons(list buttons)
{
	return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4)
		+ llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}

init() {

	follow_flag = 0;
	llSetText("Not following", <1,1,1>,1);
	npc_control_handle=llListen(NPC_CONTROL_CHANNEL,"","","");
}

stopFollowing() {

	llSetTimerEvent(0.0);
	llOwnerSay("No longer following.");
	osNpcStopMoveToTarget(llGetOwner());
}

startFollowingName(string name) {
	targetName = name;
	llSensor(targetName,NULL_KEY,AGENT_BY_LEGACY_NAME,96.0,PI);  // This is just to get the key
	llSetText("Following "+(string)targetName, <1,1,1>,1);
}

findObject(string name){
	llSensor(name,NULL_KEY,PASSIVE | SCRIPTED,96.0,PI);  // This is just to get the key
}

startFollowingKey(key id) {
	targetKey = id;
	llOwnerSay("Now following "+targetName);
	keepFollowing();
	llSetTimerEvent(DELAY);
}

keepFollowing() {


	list answer = llGetObjectDetails(targetKey,[OBJECT_POS]);
	if (llGetListLength(answer)==0) {
		if (!announced) llOwnerSay(targetName+" seems to be out of range.  Waiting for return...");
		announced = TRUE;
	} else {
			announced = FALSE;
		vector targetPos = llList2Vector(answer,0);
		float dist = llVecDist(targetPos,llGetPos());
		if (dist>RANGE) {

			if (dist>LIMIT) {
				targetPos = llGetPos() + LIMIT * llVecNorm( targetPos - llGetPos() ) ;
			}

			osNpcMoveToTarget(llGetOwner(), targetPos+<1,0,0>,OS_NPC_NO_FLY);


		}
	}
}

default {

	state_entry() {
		init();

	}

	on_rez(integer x) {
		llResetScript();   // Why not?
	}

	touch_start(integer num_detected){
		dialog_channel= (integer)(llFrand(-10000000000.0) - 10000000000.0);
		dialog_listen_handle=llListen(dialog_channel, "", "", "");

		llDialog(llDetectedKey(0),"\nI am waiting for your instructions.\n Choose option to let me know what to do.\n",order_buttons(["Follow","Stop","Stand","Select","Unselect","Remove"]),dialog_channel);
		who_selected_me = llDetectedName(0);
		llRegionSay(NPC_CONTROL_CHANNEL, who_selected_me+"%"+"Unselect_others");
	}

	listen( integer channel, string name, key id, string message )
	{
		key this_NPC_UUID = llGetOwner();

		if (channel == dialog_channel){
			//llSay(0, message);

			if (message == "Follow") {
				targetName = who_selected_me;
				startFollowingName(targetName);
				llSetText("Following "+who_selected_me,<1,1,1>,1);
				llListenRemove(dialog_channel);
			}
			else if (message == "Stop") {
				stopFollowing();
				llSetText("Not Following",<1,1,1>,1);
				llListenRemove(dialog_channel);
			}
			else if (message == "Sit_Chair") {

				;llListenRemove(dialog_channel);
			}
			else if (message == "Sit_Wh_Chair") {
				findObject("wheel chair");
				;llListenRemove(dialog_channel);
			}
			else if (message == "Sit_gurney") {
				findObject("gurney");
				;llListenRemove(dialog_channel);
			}
			else if (message == "Sit_Pas_Seat"){
				findObject("passenger_seat");
				;llListenRemove(dialog_channel);
			}
			else if (message == "Lay_Bed"){
				findObject("bed");
				;llListenRemove(dialog_channel);
			}
			else if (message == "Stand") {
				osNpcStand(this_NPC_UUID);
				llListenRemove(dialog_channel);
			}
			else if (message == "Select") {
				selected_state  = 1;
				llSetText("Selected by "+ who_selected_me,<1,1,1>,1);
			}
			else if (message == "Unselect") {
				selected_state  = 0;
				llSetText("Released by "+ who_selected_me,<1,1,1>,1);
			}
			else if (message == "Remove"){
				osNpcRemove(this_NPC_UUID);
			}
		}
		else if (channel == NPC_CONTROL_CHANNEL){
			list my_list = llParseString2List(message,["%"],[""]);
			//llOwnerSay("message 0: "+llList2String(my_list,0));
			//llOwnerSay("message 1: "+llList2String(my_list,1));
			if((llList2String(my_list,0) == who_selected_me)&&(llList2String(my_list,1) == "Unselect_others")){
				selected_state = 0;
				llSetText("Released by "+ who_selected_me,<1,1,1>,1);
			}
			if((llList2String(my_list,0) == who_selected_me)&&(selected_state == 1)){
				osNpcSit(llGetOwner(),(key)llList2String(my_list,1), OS_NPC_SIT_NOW);
			}
		}
	}
	//No longer using sensors now, safely ignore this at the moment
	no_sensor() {
		llOwnerSay("Did not find anyone named "+targetName);
	}

	sensor(integer n) {
		integer i;
		for (i=0; i<n; i++)
		{

			llOwnerSay("sensor data:"+(string)llDetectedName(i));
			llOwnerSay("sensor data:"+(string)llDetectedKey(i));
			if ((string)llDetectedName(i) == "chair"){
				osNpcSay(llGetOwner(),"Yahoo! chair found!");
				osNpcSit(llGetOwner(),llDetectedKey(i), OS_NPC_SIT_NOW);
			}
			if ((string)llDetectedName(i) == "bed"){
				osNpcSay(llGetOwner(),"Yahoo! bed found!");
				osNpcSit(llGetOwner(),llDetectedKey(i), OS_NPC_SIT_NOW);
			}
			if ((string)llDetectedName(i) == "passenger_seat"){
				osNpcSay(llGetOwner(),"Yahoo! I am sitting in a police car!");
				osNpcSit(llGetOwner(),llDetectedKey(i), OS_NPC_SIT_NOW);
			}
			if ((string)llDetectedName(i) == "police_carP"){
				osNpcSay(llGetOwner(),"Yahoo! I am sitting in a police car!");
				osNpcSit(llGetOwner(),llDetectedKey(i), OS_NPC_SIT_NOW);
			}
			startFollowingKey(llDetectedKey(i));
			//key thisKey = llDetectedKey(0);
			//string thisEntity = llDetectedName(0);
		}
	}

	timer() {
		keepFollowing();
	}

	attach(key id) {
		//NonPlayerChar=id;
		//osNpcSay(llGetOwner(), "My UUID is"+(string)id);
	}

}