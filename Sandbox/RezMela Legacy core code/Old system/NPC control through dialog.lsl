float DELAY = 0.5;   // Seconds between blinks; lower for more lag
float RANGE = 1.0;   // Meters away that we stop walking towards
float TAU = 1.0;     // Make smaller for more rushed following

//key NonPlayerChar = NULL_KEY;
// Avatar Follower script, by Dale Innis
// Do with this what you will, no rights reserved
// See https://wiki.secondlife.com/wiki/AvatarFollower for instructions and notes

float LIMIT = 60.0;   // Approximate limit (lower bound) of llMoveToTarget

integer lh = 0;

string targetName = "";
key targetKey = NULL_KEY;

integer dialog_channel;
integer dialog_listen_handle;

integer npc_control_handle;
integer NPC_CONTROL_CHANNEL = -72;
integer OUTFIT_CHANNEL = 11;

key ownerKey;

string who_selected_me_name ="";
key who_selected_me_key = NULL_KEY;

integer selected_state = 0;

key user_clicking;
list order_buttons(list buttons)
{
	return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4)
		+ llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}

init() {
	who_selected_me_name = "";
	who_selected_me_key = NULL_KEY;
	llSetText("", <1,1,1>,1);
	npc_control_handle=llListen(NPC_CONTROL_CHANNEL,"","","");
	ownerKey = llGetOwner();
	llSetTimerEvent(DELAY);
}

stopFollowing() {
	osNpcStopMoveToTarget(ownerKey);
	targetKey = NULL_KEY;
	targetName = "";
	followingMessage();	
}

selectOnlyMe(key Id){
	who_selected_me_key = Id;
	who_selected_me_name = llKey2Name(who_selected_me_key);
	selected_state  = 1;
	llSetText("["+ who_selected_me_name+"]",<1,1,1>,1);
	stopFollowing();
	llRegionSay(NPC_CONTROL_CHANNEL, who_selected_me_name+"%"+"Unselect_others");
}

findObject(string name){
	llSensor(name,NULL_KEY,PASSIVE | SCRIPTED,96.0,PI);  // This is just to get the key
}

startFollowingKey(key id) {
	targetKey = id;
	targetName = llKey2Name(id);
	llOwnerSay("Following ["+targetName+"]");
	followingMessage();
	keepFollowing();
}
keepFollowing() {
	list answer = llGetObjectDetails(targetKey,[OBJECT_POS]);
	if (llGetListLength(answer)==0) {	// if they've logged out or moved to a different region
		stopFollowing();
		return;
	}
	vector targetPos = llList2Vector(answer,0);
	float dist = llVecDist(targetPos,llGetPos());
	if (dist>RANGE) {

		if (dist>LIMIT) {
			targetPos = llGetPos() + LIMIT * llVecNorm( targetPos - llGetPos() ) ;
		}

		osNpcMoveToTarget(ownerKey, targetPos+<1,0,0>,OS_NPC_NO_FLY);

	}
}
followingMessage() {
	llRegionSay(-84403270, "FF" + (string)ownerKey + (string)targetKey);
}
checkSelected() {
	vector Size = llGetAgentSize(who_selected_me_key);
	if (Size == ZERO_VECTOR) {		// avatar not in region
		if (targetKey != NULL_KEY) stopFollowing();
		who_selected_me_key = NULL_KEY;
		who_selected_me_name = "";
	}
}
default {

	state_entry() {
		init();
	}

	on_rez(integer x) {
		llResetScript();
	}

	touch_start(integer num_detected){

		llResetTime();

	}

	touch_end(integer num_detected){
		user_clicking = llDetectedKey(0);
		//llOwnerSay("Was touched for more than 0.8 seconds");
		if ( llGetTime() > 0.8 ) {
			if((who_selected_me_name == "")||(who_selected_me_name == llDetectedName(0))){
				selectOnlyMe(llDetectedKey(0));

				dialog_channel= (integer)(llFrand(-10000000000.0) - 10000000000.0);
				dialog_listen_handle=llListen(dialog_channel, "", "", "");
				llDialog(user_clicking,"\nNon-player-character commands:\n",order_buttons(["Follow","Stop","Stand","Select","Unselect","Outfit"]),dialog_channel);
			}
			else if (llDetectedName(0)!= who_selected_me_name){
				llSay(0, "This NPC is currently controlled by "+who_selected_me_name);
			}
		}
		else {
			//llOwnerSay("Was clicked normally with a short touch");
			if(who_selected_me_name == ""){
				selectOnlyMe(llDetectedKey(0));
			}
			else if (llDetectedName(0)!= who_selected_me_name){
				llSay(0, "This NPC is currently controlled by "+who_selected_me_name);
			}

		}

	}

	listen( integer channel, string name, key id, string message )
	{
		key this_NPC_UUID = ownerKey;

		if (channel == dialog_channel){

			if (message == "Follow") {
				osNpcStand(this_NPC_UUID);
				startFollowingKey(who_selected_me_key);
			}
			else if (message == "Stop") {
				stopFollowing();
			}
			else if (message == "Stand") {
				stopFollowing();
				osNpcStand(this_NPC_UUID);
			}
			else if ((message == "Select")&&(selected_state != 1)) {
				selected_state  = 1;
				llSetText("["+ who_selected_me_name+"]",<1,1,1>,1);
				stopFollowing();
			}
			else if (message == "Unselect") {
				selected_state  = 0;
				who_selected_me_name = "";
				who_selected_me_key = NULL_KEY;
				llSetText("",<1,1,1>,1);
			}
			else if (message == "Outfit") {
				llRegionSay(OUTFIT_CHANNEL, "outfit_change"+"/"+who_selected_me_name+"/"+this_NPC_UUID);
			}
		}
		else if (channel == NPC_CONTROL_CHANNEL){
			list my_list = llParseString2List(message,["%"],[""]);
			//llOwnerSay("message 0: "+llList2String(my_list,0));
			//llOwnerSay("message 1: "+llList2String(my_list,1));
			if((llList2String(my_list,0) == who_selected_me_name)&&(llList2String(my_list,1) == "Unselect_others")){
				selected_state = 0;
				who_selected_me_name = "";
				who_selected_me_key = NULL_KEY;
				llSetText("",<1,1,1>,1);
			}
			if((llList2String(my_list,0) == who_selected_me_name)&&(selected_state == 1)){
				stopFollowing();
				osNpcSit(ownerKey,(key)llList2String(my_list,1), OS_NPC_SIT_NOW);
			}
		}
		llListenRemove(dialog_listen_handle);
	}


	no_sensor() {
		llOwnerSay("Did not find anyone named "+targetName);
	}

	sensor(integer n) {
		integer i;
		for (i=0; i<n; i++)
		{
			startFollowingKey(llDetectedKey(i));
		}
	}
	timer() {
		checkSelected();		// check to see if selecting avatar is still around
		if (targetKey != NULL_KEY) keepFollowing();
		if (llFrand(1.0) < 0.1) followingMessage();		// periodic messages to keep updated
	}

}