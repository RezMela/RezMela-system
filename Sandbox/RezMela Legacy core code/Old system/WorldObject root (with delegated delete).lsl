//WorldObjectRoot
//Copyright (C) 2012 by Rameshsharma Ramloll
//This file is subject to the terms and conditions defined in
//file 'LICENSE.txt', which is part of this source code package.


integer     selectMode = 0;
integer     commChannel;
integer     modulus_divisor=90000; //used to bypass parameter passing limitation in Second Life, equivalent to max. number of rezzable objects
integer     rewardCmdChannel = -69;//this channel listens for cmds that tells obj when to set ideal posn
integer     rewardPayoutChannel = -68;//this channel sends information to object that serves rewards
float         disturbance_threshold = 0.5;//this is the radius defining permissible desirable target region
integer     gLine;
string         gName;
string         whoPickedMe = "";
vector         initialPos;
integer     numPieces = 24;
integer     rezParameter;
integer     rotation_step_DEG = 45;
integer     rotation_step_DEG_fine=5;
float         rezPositionAdjustment;
integer     objectPinIndex;
vector         parentGetPos;
rotation     parentGetRot;

// Delegated deletion stuff
integer LM_DELEGATE_DELETION = -7044001;		// received from another script that wants to handle deletion
integer LM_DELETE_RECEIVED = -7044002;			// inform other scripts that they should handle deletion now
integer DelegateDeletion = FALSE;

//--------- fading effect functions
float         alpha_increment = 0.01;
vector         ideal_posn = <0,0,0>;

integer     rotation_manipulation_channel;
integer     HUDListenerHandle;

//MAIN FLAGS
string         range_listening = "REGION"; //Flag REGION|STANDARD
//--------- Flags for enabling specific functionalities
string         reward_flag = "DISABLE"; //Enables reward mechanism

nrFadeAlpha(float start_point, float end_point, float speed)
{
	start_point = nrFloatCheck(start_point);
	end_point = nrFloatCheck(end_point);
	speed = nrFloatCheck(speed);
	if(start_point!=end_point)
	{
		if(start_point<end_point)
		{
			do
			{
				start_point = nrFloatCheck((start_point+speed));
				integer link_num = 1;
				for (;link_num <= llGetNumberOfPrims();link_num++){
					llSetLinkAlpha(link_num, start_point, ALL_SIDES);
				}
			}while(start_point<end_point);
		}
		else
		{
			do
			{
				start_point = nrFloatCheck((start_point-speed));
				integer link_num = 1;
				for (;link_num <= llGetNumberOfPrims();link_num++){
					llSetLinkAlpha(link_num, start_point, ALL_SIDES);
				}
			}while(start_point>end_point);
		}
	}
}

float nrFloatCheck(float src)
{
	if(src<=0)
	{
		return 0.0;
	}
	else if(src>=1)
	{
		return 1.0;
	}
	return src;
}

nrSetGlow(integer link_num, float glow, integer sides)
{
	llSetLinkPrimitiveParamsFast(link_num, [PRIM_GLOW,sides,glow]);
}

integer find_prim_rank(string name)
{
	integer i = llGetNumberOfPrims();
	for (; i >= 0; --i)
	{
		if (llGetLinkName(i) == name)
		{
			return i;
		}
	}
	return FALSE;
}
//---------------fading effect

vector rgb2sl( vector rgb )
{
	return rgb / 255;        //Scale the RGB color down by 255
}


rotation RotBetween(vector start, vector end)//adjusts quaternion magnitude so (start * return == end)

{//Authors note: I have never had a use for this but it's good to know how to do it if I did.
	rotation rot = llRotBetween(start, end);
	float d = start * start;
	if(d)//true if non-zero
		if((d = llPow(end * end / d, 0.25)))


			return <rot.x * d, rot.y * d, rot.z * d, rot.s * d>;
	return rot;
}//Strife Onizuka

setupListeners(integer c){
	llListen(c, "",NULL_KEY,"");
	//llListen(c+ctrlChan,"",NULL_KEY,"");
	//llListen(rewardCmdChannel,"",NULL_KEY,""); optional reward channel disabled for optimization reasons
}

//Vector maths functions used in reward calculations
float VecMag(vector v) {
	return llSqrt(v.x*v.x + v.y*v.y + v.z*v.z);
}

float VecDist(vector a, vector b) {
	return VecMag(a - b);
}

particles(){

	llParticleSystem([
		PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK|TRUE,
		PSYS_SRC_PATTERN, 4,
		PSYS_PART_START_ALPHA, 1.000000,
		PSYS_PART_END_ALPHA, 1.000000,
		PSYS_PART_START_COLOR, <1.000000, 1.000000, 1.000000>,
		PSYS_PART_END_COLOR, <1.000000, 1.000000, 1.000000>,
		PSYS_PART_START_SCALE, <0.2, 0.2, 0>,
		PSYS_PART_END_SCALE, <1.000000, 1.000000, 0.000000>,
		PSYS_PART_MAX_AGE, 2.000000,
		PSYS_SRC_MAX_AGE, 2.000000,
		PSYS_SRC_ACCEL, <0.000000, 0.000000, 0.000000>,
		PSYS_SRC_ANGLE_BEGIN, 0.000000,
		PSYS_SRC_ANGLE_END, 0.000000,
		PSYS_SRC_BURST_PART_COUNT, 1,
		PSYS_SRC_BURST_RATE, 1.000000,
		PSYS_SRC_BURST_RADIUS, 0.500000,
		PSYS_SRC_BURST_SPEED_MIN, 0.300000,
		PSYS_SRC_BURST_SPEED_MAX, 0.500000,
		PSYS_SRC_OMEGA, <0.000000, 0.000000, 0.500000>,
		PSYS_SRC_TARGET_KEY,(key)"",
		PSYS_SRC_TEXTURE, ""]);
}

fading_in(float alpha_inc){
	nrSetGlow(LINK_SET, 0.1, ALL_SIDES);
	nrFadeAlpha(0, 1.0, alpha_inc);
	nrSetGlow(LINK_SET, 0.0, ALL_SIDES);
}

fading_out(float alpha_inc){
	nrSetGlow(LINK_SET, 0.1, ALL_SIDES);
	nrFadeAlpha(1.0, 0.0, alpha_inc);
	nrSetGlow(LINK_SET, 0.0, ALL_SIDES);
}

string  charset = "0123456789abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ";
integer chr2int(string chr) { // convert unsigned charset to integer
	integer base = llStringLength(charset);
	integer i = -llStringLength(chr);
	integer j = 0;
	while(i)
		j = (j * base) + llSubStringIndex(charset, llGetSubString(chr, i, i++));
	return j;
}

warp(vector pos)
{
	list rules;
	integer num = llCeil(llVecDist(llGetPos(),pos)/10);
	while(num--)rules+=[PRIM_POSITION,pos];
	llSetPrimitiveParams(rules);
}

default {

	state_entry()
	{   // Registers the listen to the owner of the object at the moment of the call.
		// This does not automatically update when the owner changes.
		llSetText("",<1,1,1>,1.0);
		whoPickedMe = "";
		llSetAlpha(0.5,ALL_SIDES);
		llParticleSystem([]);
		selectMode = 0;
	}



	link_message(integer sender_num, integer num, string msg, key id)
	{
		//Receiving link messages from object handle

		list my_list = llParseString2List(msg,["%"],[""]);
		string manipulation = (string)llList2String(my_list,1);
		string doer = (string)llList2String(my_list,0);

		if(manipulation == "pick_object"){
			if (selectMode == 1){
				if (doer == whoPickedMe) {
					whoPickedMe = "";
					//llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
					llSetText("",<1,1,1>,1.0);
					selectMode = 0;
					//Echo message back to remaining objects ie Secondary Children
					llMessageLinked(LINK_ALL_CHILDREN, 0, doer+"%release_object","" );
					//Remove HUDListenerHandle
					// llListenRemove(HUDListenerHandle); disable HUD control for optimization
				}
				else{
					llSetColor(<1.0,1.0,.0>,ALL_SIDES);
					//llSetLinkAlpha(LINK_SET, 0.5, ALL_SIDES);
					whoPickedMe = doer;
					llSetText(doer,<1,1,1>,1.0);
					if (range_listening == "STANDARD"){
						llSay(commChannel,doer+"%"+"unselectPieces");
					}
					else
					{
						llRegionSay(commChannel,doer+"%"+"unselectPieces");
					}
					selectMode = 1;
					//Echo message back to remaining objects ie Secondary Children
					llMessageLinked(LINK_ALL_CHILDREN, 0, doer+"%pick_object","" );
					//Open listener to listen to rotation adjustment calls from HUD
					rotation_manipulation_channel = -1*chr2int(whoPickedMe);
					//HUDListenerHandle=llListen(rotation_manipulation_channel,"","",""); disable HUD control for optimization
				}
			}
			else
			{
				llSetColor(<1.0,1.0,1.0>,ALL_SIDES);
				//llSetLinkAlpha(LINK_SET, 0.5, ALL_SIDES);
				whoPickedMe = doer;
				llSetText(doer,<1,1,1>,1.0);
				if (range_listening == "STANDARD"){
					llSay(commChannel,doer+"%"+"unselectPieces");
				}
				else
				{
					llRegionSay(commChannel,doer+"%"+"unselectPieces");
				}
				selectMode = 1;
				//Echo message back to remaining objects ie Secondary Children
				llMessageLinked( LINK_ALL_CHILDREN, 0, doer+"%pick_object","" );
				//Open listener to listen to rotation adjustment calls from HUD
				rotation_manipulation_channel = -1*chr2int(whoPickedMe);
				// HUDListenerHandle=llListen(rotation_manipulation_channel,"","",""); disable HUD control for optimization
			}
		}
		//Template code follows if control is needed from user interface prims placed on object
		//message received in the form: doer%do_something
		//command to use in user interface prim llMessageLinked(LINK_ALL_CHILDREN, 0, doer+"%throw_projectile","" );
		if (doer == whoPickedMe) {
			if(manipulation == "do_something"){
				//do_something();
			}
		}
		if (num == LM_DELEGATE_DELETION) {	// if we receive this, it's notice that another script will take care of object deletion
			DelegateDeletion = TRUE;
		}
	}

	listen( integer channel, string name, key id, string message )
	{

		list my_list = llParseString2List(message,["%"],[""]);
		string doer= (string)llList2String(my_list,1);
		if(objectPinIndex==(integer)llList2String(my_list,2)){ //code to check obectPinIndex
			if(llList2String(my_list,0) == "selectPantMe"){

				llSay(0,doer+" just selected me at control.");
				llSetColor(<1.0,1.0,1.0>,ALL_SIDES);
				//llSetLinkAlpha(LINK_SET, 0.5, ALL_SIDES);
				whoPickedMe = doer;
				llSetText(doer,<1,1,1>,1.0);
				if (range_listening == "STANDARD"){
					llSay(commChannel,doer+"%"+"unselectPieces");
				}
				else
				{
					llRegionSay(commChannel,doer+"%"+"unselectPieces");
				}
				selectMode = 1;
				//Open listener to listen to rotation adjustment calls from HUD
				rotation_manipulation_channel = -1*chr2int(whoPickedMe);
				HUDListenerHandle=llListen(rotation_manipulation_channel,"","","");

			}
		} //code to check objectPinIndex

		if(llList2String(my_list,0) == "masterMove"){
			//llSetPos((vector)llList2String(my_list,1));
			if(objectPinIndex==(integer)llList2String(my_list,3)){
				//warp((vector)llList2String(my_list,1));
				llSetRegionPos((vector)llList2String(my_list,1));
				llSetRot((rotation)llList2String(my_list,2));
			}
		}

		if (llList2String(my_list,0) == "recording"){
			parentGetPos=(vector)llList2String(my_list,1);
			parentGetRot=(rotation)llList2String(my_list,2);
			string recordPos = (string)((llGetPos()-parentGetPos)/parentGetRot);
			string recordRot = (string)(llGetRot()/parentGetRot);
			llSay(0,llGetObjectName()+"%"+recordPos+"%"+recordRot+"%"+(string)objectPinIndex);
		}

		//If I am selected and I hear that whoever selected me is now clicking the board, I move to that spot
		if (selectMode == 1){

			if((llList2String(my_list,1) != "unselectPieces")){

				if (whoPickedMe == llList2String(my_list,0)){
					//llSetPos((vector)llList2String(my_list,1));
					warp((vector)llList2String(my_list,1));
					//Now aligning next object to rez with the last one clicked, replace llGetRot() by global rotation of last object clicked
					rotation var2=(rotation)llList2String(my_list,3)*RotBetween(llRot2Up((rotation)llList2String(my_list,3)),(vector)llList2String(my_list,2));
					llSetRot(var2);

				}
			}
			if(llList2String(my_list,0) == "OBJManip"){
				if(whoPickedMe == llList2String(my_list,1)){
					if(llList2String(my_list,2) == "clockwise_fine"){
						llSetLocalRot(llEuler2Rot(<0,0,-1*rotation_step_DEG_fine>*DEG_TO_RAD)*llGetLocalRot());
					}
					if(llList2String(my_list,2) == "anticlockwise_fine"){
						llSetLocalRot(llEuler2Rot(<0,0,rotation_step_DEG_fine>*DEG_TO_RAD)*llGetLocalRot());
					}
					if(llList2String(my_list,2) == "clockwise_coarse"){
						llSetLocalRot(llEuler2Rot(<0,0,-1*rotation_step_DEG>*DEG_TO_RAD)*llGetLocalRot());
					}
					if(llList2String(my_list,2) == "anticlockwise_coarse"){
						llSetLocalRot(llEuler2Rot(<0,0,rotation_step_DEG>*DEG_TO_RAD)*llGetLocalRot());
					}
				}
			}



		}
		//if (selectMode == 1)

		//If whoever picked me is now picking another game piece, I become unselected (unpicked)
		if (llList2String(my_list,1) == "unselectPieces"){
			if(llList2String(my_list,0)== whoPickedMe){
				// llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES); To prevent invisible parts of Rezzor Secondary objs from being visible
				llSetText("",<1,1,1>,1.0);
				whoPickedMe = "";
				selectMode = 0;
				llMessageLinked( LINK_ALL_OTHERS, 0,"release_object","" );//tell other linked objects that we have been unselected
			}
		}

		if (message == "savePosition"){

			initialPos = llGetPos();
		}

		if (message == "reset"){

			whoPickedMe = "";
			llSetAlpha(0.0,ALL_SIDES);
			llSetText("",<1,1,1>,1.0);
			selectMode = 0;
			llSetPos(initialPos);
		}

		if (message == "deleteAll"){
			state leave;
		}

		if (message == "unselectAll"){
			// llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);  To prevent invisible parts of Rezzor Secondary objs from being visible
			llSetText("",<1,1,1>,1.0);
			whoPickedMe = "";
			selectMode = 0;
			llMessageLinked( LINK_ALL_OTHERS, 0,"release_object","" );//tell other linked objects that we have been unselected
		}
		if (message == "deleteThis"){
			if(selectMode == 1) state leave;
		}

		if (message == "physics_on"){
			llSetStatus(STATUS_PHYSICS, TRUE); // Set the object physical
		}

		if (message == "physics_off"){
			llSetStatus(STATUS_PHYSICS, FALSE); // Set the object physical
		}

		if (message == "capture_ideal_posn"){
			ideal_posn = llGetPos();
		}

		if (message == "find_total_score"){

		}
	}

	timer(){
		// Following lines removed JH - the timer was never set before my changes
		//llParticleSystem([]);
		//llSetTimerEvent(0);
		
	}

	on_rez(integer param)
	{
		//llResetScript();//do NOT reset the script on rez forces the listen to re-register.
		rezParameter=llGetStartParameter();
		commChannel = -1*(integer)rezParameter/modulus_divisor;
		objectPinIndex = rezParameter%modulus_divisor;
		setupListeners(commChannel);
		llSetAlpha(0.5,ALL_SIDES);
		llSetText("",<1,1,1>,1.0);
		initialPos=llGetPos();
		selectMode = 0;
		llSetTimerEvent(1.0);
	}
}


state leave{
	state_entry(){
		// if deletion has been delegated, we inform other scripts that we've received
		// the instruction to delete, but we don't delete the object.
		if (DelegateDeletion) {
			llMessageLinked(LINK_SET, LM_DELETE_RECEIVED, "", NULL_KEY);
			return;
		}
		llDie(); //force a transition state to make sure all listeners are released
	}
}

