// Icon Root v0.3

// v0.3 - added object PIN, dataserver handling
// v0.2 - changed chat channel from 0 to non-zero


//Copyright (C) 2012 by Rameshsharma Ramloll
//This file is subject to the terms and conditions defined in
//file 'LICENSE.txt', which is part of this source code package.


integer OBJECT_PIN = 50200;
integer     selectMode = 0;
integer     commChannel;
integer SAVE_CHANNEL = -40290770;		// used in comms from icons to "save scene data"

integer     modulus_divisor=90000; //used to bypass parameter passing limitation in Second Life, equivalent to max. number of rezzable objects
integer     rewardCmdChannel = -69;//this channel listens for cmds that tells obj when to set ideal posn
integer     rewardPayoutChannel = -68;//this channel sends information to object that serves rewards
float         disturbance_threshold = 0.5;//this is the radius defining permissible desirable target region
//integer     gLine;
//string         gName;
string         whoPickedMe = "";
vector         initialPos;
integer     numPieces = 24;
integer     rezParameter;
integer     rotation_step_DEG = 45;
integer     rotation_step_DEG_fine=5;
//float         rezPositionAdjustment;
integer     objectPinIndex;
vector         parentGetPos;
rotation     parentGetRot;

// JFH additions
integer PrimCount;
float CurrentSizeFactor;

//--------- fading effect functions
float         alpha_increment = 0.01;
vector         ideal_posn = <0,0,0>;

integer     rotation_manipulation_channel;
integer     HUDListenerHandle;

//MAIN FLAGS
string         range_listening = "STANDARD"; //Flag REGION|STANDARD
//--------- Flags for enabling specific functionalities
string         reward_flag = "DISABLE"; //Enables reward mechanism

ProcessCommand(string Command) {
	list my_list = llParseString2List(Command,["%"],[""]);
	string CommandPart1 = llList2String(my_list,0);
	string CommandPart2 = llList2String(my_list,1);

	if(CommandPart1 == "masterMove"){
		if(objectPinIndex == (integer)llList2String(my_list,3)){
			llSetPos((vector)llList2String(my_list,1));
			llSetRot((rotation)llList2String(my_list,2));
		}
	}

	if (CommandPart1 == "recording"){
		parentGetPos=(vector)llList2String(my_list,1);
		parentGetRot=(rotation)llList2String(my_list,2);
		string recordPos = (string)((llGetPos()-parentGetPos)/parentGetRot);
		string recordRot = (string)(llGetRot()/parentGetRot);
		llSay(SAVE_CHANNEL,llGetObjectName()+"%"+recordPos+"%"+recordRot+"%"+(string)objectPinIndex);
	}

	//If I am selected and I hear that whoever selected me is now clicking the board, I move to that spot
	if (selectMode == 1){

		if((CommandPart2 != "unselectPieces")){

			if (whoPickedMe == CommandPart1){
				llSetPos((vector)llList2String(my_list,1));
				//Now aligning next object to rez with the last one clicked, replace llGetRot() by global rotation of last object clicked
				rotation var2=(rotation)llList2String(my_list,3)*RotBetween(llRot2Up((rotation)llList2String(my_list,3)),(vector)llList2String(my_list,2));
				llSetRot(var2);
				// if(reward_flag == "ENABLE"){
				// //Determine reward if ideal_posn is set,when not set it is <0,0,0>
				// if (ideal_posn != <0,0,0>){
				// if (VecDist(llGetPos(),ideal_posn)<disturbance_threshold){
				// particles();//reward gfx effects
				// llSetTimerEvent(1);
				// if (range_listening == "STANDARD"){
				// llSay(rewardPayoutChannel,"whoPickedMe"+",Good Job");
				// }
				// else
				// {
				// llRegionSay(rewardPayoutChannel,"whoPickedMe"+",Good Job");
				// }
				// }
				// }
				// }
			}
		}
		if(CommandPart1 == "OBJManip"){

			if(whoPickedMe == CommandPart2){
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
	//If whoever picked me is now picking another game piece, I become unselected (unpicked)
	if (llList2String(my_list,1) == "unselectPieces"){
		if(llList2String(my_list,0)== whoPickedMe){
			llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
			llSetText("",<1,1,1>,1.0);
			llSetLinkPrimitiveParams( LINK_SET,[ PRIM_GLOW, ALL_SIDES, 0 ] ) ;
			whoPickedMe = "";
			selectMode = 0;
			llMessageLinked( LINK_ALL_OTHERS, 0,"release_object","" );//tell other linked objects that we have been unselected
		}
	}

	if (Command == "savePosition"){

		initialPos = llGetPos();
	}

	if (Command == "reset"){

		whoPickedMe = "";
		llSetAlpha(0.0,ALL_SIDES);
		llSetText("",<1,1,1>,1.0);
		selectMode = 0;
		llSetPos(initialPos);
	}

	if (Command == "deleteAll"){
		llDie();
	}

	if (Command == "unselectAll"){
		llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
		llSetText("",<1,1,1>,1.0);
		llSetLinkPrimitiveParams( LINK_SET,[ PRIM_GLOW, ALL_SIDES, 0 ] ) ;
		whoPickedMe = "";
		selectMode = 0;
		llMessageLinked( LINK_ALL_OTHERS, 0,"release_object","" );//tell other linked objects that we have been unselected
	}

	if (Command == "deleteThis"){
		if(selectMode == 1) llDie();
	}

	if (Command == "physics_on"){
		llSetStatus(STATUS_PHYSICS, TRUE); // Set the object physical
	}

	if (Command == "physics_off"){
		llSetStatus(STATUS_PHYSICS, FALSE); // Set the object physical
	}

	if (Command == "capture_ideal_posn"){
		ideal_posn = llGetPos();
	}

	if (Command == "find_total_score"){

	}
}
// Resize object
ReSize(float SizeFactor) {
    float ChangeFactor = SizeFactor / CurrentSizeFactor;
    list WriteParams = [];
    integer P;
    for(P = 1; P <= PrimCount; P++) {
        list ReadParams = llGetLinkPrimitiveParams(P, [ PRIM_SIZE, PRIM_POS_LOCAL ]);
        vector Size = llList2Vector(ReadParams, 0);
        vector LocalPos = llList2Vector(ReadParams, 1);
        Size *= ChangeFactor;
        WriteParams += [ PRIM_LINK_TARGET, P, PRIM_SIZE, Size ];
        if (P > 1) {
            LocalPos *= ChangeFactor;
            WriteParams += [ PRIM_POS_LOCAL, LocalPos ];
        }
    }
    llSetLinkPrimitiveParamsFast(LINK_THIS, WriteParams);
    CurrentSizeFactor = SizeFactor;
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

default {
	on_rez(integer param)
	{
		rezParameter=llGetStartParameter();
		commChannel = -1*(integer)rezParameter/modulus_divisor;
		objectPinIndex = rezParameter%modulus_divisor;
		setupListeners(commChannel);
		llSetAlpha(0.5,ALL_SIDES);
		llSetText("",<1,1,1>,1.0);
		llSetLinkPrimitiveParams( LINK_SET,[ PRIM_GLOW, ALL_SIDES, 0 ] ) ;
		initialPos=llGetPos();
		selectMode = 0;
	}

	state_entry()
	{   // Registers the listen to the owner of the object at the moment of the call.
		// This does not automatically update when the owner changes.
		llSetRemoteScriptAccessPin(OBJECT_PIN);
        PrimCount = llGetNumberOfPrims();
        CurrentSizeFactor = 1.0;		
		llSetText("",<1,1,1>,1.0);
		whoPickedMe = "";
		llSetAlpha(0.5,ALL_SIDES);
		llParticleSystem([]);
		selectMode = 0;
	}

	touch_start(integer i) {

		//If same person picks game piece again, then game piece is unselected,
		//If another person picks game piece, then game piece acquires label of new person.
		if (selectMode == 1){
			if (llDetectedName(0) == whoPickedMe) {
				whoPickedMe = "";
				llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
				llSetText("",<1,1,1>,1.0);
				selectMode = 0;
				llSetLinkPrimitiveParams( LINK_SET,[ PRIM_GLOW, ALL_SIDES, 0 ] ) ;
			}
			else{
				llSetColor(<1.0,1.0,.0>,ALL_SIDES);
				llSetLinkAlpha(LINK_SET, 0.5, ALL_SIDES);
				whoPickedMe = llDetectedName(0);
				llSetText(llDetectedName(0),<1,1,1>,1.0);
				if (range_listening == "STANDARD"){
					llSay(commChannel,llDetectedName(0)+"%"+"unselectPieces");
				}
				else
				{
					llRegionSay(commChannel,llDetectedName(0)+"%"+"unselectPieces");
				}
				selectMode = 1;
				llSetLinkPrimitiveParams( LINK_SET,[ PRIM_GLOW, ALL_SIDES, .3 ] ) ;
			}
		}
		else
		{
			llSetColor(<1.0,1.0,.0>,ALL_SIDES);
			llSetLinkAlpha(LINK_SET, 0.5, ALL_SIDES);
			whoPickedMe = llDetectedName(0);
			llSetText(llDetectedName(0),<1,1,1>,1.0);
			if (range_listening == "STANDARD"){
				llSay(commChannel,llDetectedName(0)+"%"+"unselectPieces");
			}
			else
			{
				llRegionSay(commChannel,llDetectedName(0)+"%"+"unselectPieces");
			}
			selectMode = 1;
			llSetLinkPrimitiveParams( LINK_SET,[ PRIM_GLOW, ALL_SIDES, .3 ] ) ;
		}
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
					llSetLinkPrimitiveParams( LINK_SET,[ PRIM_GLOW, ALL_SIDES, 0 ] ) ;
					//Echo message back to remaining objects ie Secondary Children
					llMessageLinked(LINK_ALL_CHILDREN, 0, doer+"%release_object","" );
					//Remove HUDListenerHandle
					llListenRemove(HUDListenerHandle);
				}
				else{
					llSetColor(<1.0,1.0,.0>,ALL_SIDES);
					//llSetLinkAlpha(LINK_SET, 0.5, ALL_SIDES);
					whoPickedMe = doer;
					llSetText(doer,<1,1,1>,1.0);
					if (range_listening == "STANDARD"){
						llSay(commChannel,doer+"%"+"unselectPieces");
						//Send information about object that got picked to base
						llSay(commChannel,"objectGotPicked"+"%"+(string)objectPinIndex+"%"+(string)whoPickedMe);
					}
					else
					{
						llRegionSay(commChannel,doer+"%"+"unselectPieces");
					}
					selectMode = 1;
					llSetLinkPrimitiveParams( LINK_SET,[ PRIM_GLOW, ALL_SIDES, .3 ] ) ;
					//Echo message back to remaining objects ie Secondary Children
					llMessageLinked(LINK_ALL_CHILDREN, 0, doer+"%pick_object","" );
					//Open listener to listen to rotation adjustment calls from HUD
					rotation_manipulation_channel = -1*chr2int(whoPickedMe);
					//HUDListenerHandle=llListen(rotation_manipulation_channel,"","",""); Disabling HUD control of object manipulation
				}
			}
			else
			{
				llSetColor(<1.0,1.0,.0>,ALL_SIDES);
				//llSetLinkAlpha(LINK_SET, 0.5, ALL_SIDES);
				whoPickedMe = doer;
				llSetText(doer,<1,1,1>,1.0);
				if (range_listening == "STANDARD"){
					llSay(commChannel,doer+"%"+"unselectPieces");
					//Send information about object that got picked to base
					llSay(commChannel,"objectGotPicked"+"%"+(string)objectPinIndex+"%"+(string)whoPickedMe);
				}
				else
				{
					llRegionSay(commChannel,doer+"%"+"unselectPieces");
				}
				selectMode = 1;
				llSetLinkPrimitiveParams( LINK_SET,[ PRIM_GLOW, ALL_SIDES, .3 ] ) ;
				//Echo message back to remaining objects ie Secondary Children
				llMessageLinked( LINK_ALL_CHILDREN, 0, doer+"%pick_object","" );
				//Open listener to listen to rotation adjustment calls from HUD
				rotation_manipulation_channel = -1*chr2int(whoPickedMe);
				HUDListenerHandle=llListen(rotation_manipulation_channel,"","","");
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
	}
	dataserver(key requested, string data) {
		ProcessCommand(data);
	}
	listen( integer channel, string name, key id, string message) {
		ProcessCommand(message);
	}
	timer(){
		llParticleSystem([]);
		llSetTimerEvent(0);
	}
}
