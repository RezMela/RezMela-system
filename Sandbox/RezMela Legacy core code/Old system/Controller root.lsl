//Controller Root
//Copyright(C) 2012 by Rameshsharma Ramloll
// This file is subject to the terms and conditions defined in
// file 'LICENSE.txt', which is part of this source code package.


list        accessMenu = ["Controls"];
list        snapshotsMenu = ["SCENE<<","SCENE>>","LOAD SCN","MORPH"];//"SaveSnap","Clear","MorphSnap" have been removed from list as they are no longer needed
list        optionsMenu = ["PUBLIC", "GROUP"];//"CHAN(-25)"
list        objectMainList=[];
list         Notecards = [];
integer BATTLE_SCORE_CHANNEL = -2884110;

integer     commChannel;
integer     channelDedicated2Dialog;
integer     DMKCONTROL = -56;
integer     DMK_SYNC_UI = -57;
integer     modulus_divisor=90000;//used in parameter passing, equivalent to number of possible objects that can be rezzed
integer     FEED_BACK_CHANNEL = 43;
integer     tape_channel=-15;

integer     detectedLinkNum;
string      detectedLinkName;
string      rezOrPositionMode;//this var also points to the name of a piece when mode is Rez
string      object_list = "";

integer     numUserInterfacePrims = 24;
integer     frameIndex = 0;
integer     rezParameter;

string      control_access="public";
integer     objectPinIndex = 0;
integer     snapshotIndex = 0;
integer     currentObjIndexCeil = 0;
integer        NotecardsCount = 0;
integer        notecardIndex = 0;

//Keeping track of the largest object_Pin_Index from a loaded file
integer current_largest_loaded_pinIndex = 0;

//Keep track of the number of objects rezzed
integer     totalNumberofObjectsRezzed = 0;

//Objects to rez from recording file
key         rQueryID;
integer     rLine;
string      rName;

//Objects to move from recording file after they are rezzed
key         mrQueryID;
integer     mrLine;
string      mrName;

//Snapshot  file input
//key         snapshotQueryId;
string      selectedSnapshotFile;


key         dialogID = NULL_KEY;
string      mainMenuMenuDlgMsg="ACCESS MENU \n -----------------";
string      snapshotsMenuDlgMsg="SNAPSHOT FILE SELECTION \n ----------------";
string      optionsDialogMsg="Set access controls.";
string      lastObjectRezzed;

// Center position of C&C (create and Control/Command) Board
vector         create_n_command_center;

//MAIN FLAGS
string      range_listening = "REGION"; //Flag REGION|STANDARD
integer     debug_Setup_Data = 0;
integer     PANTO_REZZOR_CHANNEL = -101;
integer     selectedObjectIndex;
string         feedback = "NONVERBOSE";


list order_buttons(list buttons)
{
	return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4)
		+ llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);

}

vector rgb2sl( vector rgb )
{
	return rgb / 255;        //Scale the RGB color down by 255
}

rotation RotBetween(vector start, vector end) //adjusts quaternion magnitude so (start * return == end)
{//Authors note: I have never had a use for this but it's good to know how to do it if I did.
	rotation rot = llRotBetween(start, end);
	if(llVecMag(start)!= 0)
	{
		if(llVecMag(end)!= 0)
		{
			float d = llSqrt(llVecMag(end) / llVecMag(start));
			return <rot.x * d, rot.y * d, rot.z * d, rot.s * d>;
		}
	}
	return rot;
}

setColorObjToRez(vector color){
	integer k = llGetNumberOfPrims();
	for (; k >= 0; --k)
	{
		if (llGetLinkName(k) == "objToRezIndicator")
		{
			llSetLinkColor(k,color,ALL_SIDES);
		}
	}
}

setTextureObjToRez(string objTexture){
	integer k = llGetNumberOfPrims();
	for (; k >= 0; --k)
	{
		if (llGetLinkName(k) == "objToRezIndicator")
		{
			llSetLinkTexture( k, objTexture, ALL_SIDES);
		}
	}
}

setTextureOnPrim(string objTexture, string primName){
	integer k = llGetNumberOfPrims();
	for (; k >= 0; --k)
	{
		if (llGetLinkName(k) == primName)
		{
			llSetLinkTexture( k, objTexture, ALL_SIDES);
		}
	}
}

integer linkName2linkNumber(string primName){
	integer k = llGetNumberOfPrims();
	for (; k >= 0; --k)
	{
		if (llGetLinkName(k) == primName)
		{
			return k;
		}
	}
	return -1;
}

setTextonPrim(string message, string primName, vector color, float alpha){

	integer k = llGetNumberOfPrims();
	for (; k >= 0; --k)
	{
		if (llGetLinkName(k) == primName)
		{
			llSetLinkPrimitiveParams(k, [ PRIM_TEXT, message, color, alpha]);
		}
	}

}

setupListeners(integer c){
	llListen(c, "",NULL_KEY, "");
}


integer RandInt(integer lower, integer higher)
{
	integer Range = higher - lower;
	integer Result = llFloor(llFrand(Range + 1)) + lower;
	return Result;
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

GetNotecardsList() {
	Notecards = [];
	integer Count = llGetInventoryNumber(INVENTORY_NOTECARD);
	integer I;
	for(I = 0; I < Count; I++) {
		string Name = llGetInventoryName(INVENTORY_NOTECARD, I);
		Notecards += Name;
	}
	NotecardsCount = llGetListLength(Notecards);
	llOwnerSay(llDumpList2String(Notecards, "\n"));
}

// List notecards in chat
ListNotecards(key AvId) {
	GetNotecardsList();
	//Message(AvId, "Saves: \n" + llDumpList2String(Notecards, "\n"));
}

default {
	state_entry()
	{
		channelDedicated2Dialog = -1*RandInt(1499900,1500000);
		commChannel = -4000;
		llListen(channelDedicated2Dialog,"", "","");
		llListen(DMKCONTROL,"","","");
		llMessageLinked(linkName2linkNumber("Capture data on channel"), 0, (string)commChannel, "");
		setupListeners(commChannel);
		objectPinIndex = 0;
		snapshotIndex = 0;
		totalNumberofObjectsRezzed=0;
		llSetText("",<1,1,1>,1);
		llSay(DMK_SYNC_UI, "Synchronize_menu_control");
		//Finding center of create_n_command prim
		create_n_command_center= llList2Vector(llGetLinkPrimitiveParams(linkName2linkNumber("createCommand"), [PRIM_POSITION]),0);

	}

	touch_start(integer pos_detected)
	{
		integer i = 0;
		dialogID = llDetectedKey(0);

		//only relevant if menu system with linked prims is attached
		for(; i<pos_detected; ++i){
			detectedLinkNum = llDetectedLinkNumber(i);
			detectedLinkName = llGetLinkName(detectedLinkNum);
		}


		if (llSameGroup(llDetectedKey(0))||(llGetOwner()== llDetectedKey(0))||(control_access == "public")) {

			integer q = 0;
			integer objectManipulationChannel;
			string user_name = llDetectedName(0);
			objectManipulationChannel = -1*chr2int(user_name);
			if (detectedLinkName == "hidehand"){
				llRegionSay(PANTO_REZZOR_CHANNEL,"resetRezzor");
			}
			if (detectedLinkName == "clockwise"){
				if (range_listening == "STANDARD"){

					llSay(objectManipulationChannel, "OBJManip%"+user_name+"%clockwise_coarse");
				}
				else{

					llRegionSay(objectManipulationChannel, "OBJManip%"+user_name+"%clockwise_coarse");
				}
			}

			if (detectedLinkName == "anticlockwise"){
				if(range_listening == "STANDARD"){

					llSay(objectManipulationChannel, "OBJManip%"+user_name+"%anticlockwise_coarse");
				}
				else{

					llRegionSay(objectManipulationChannel, "OBJManip%"+user_name+"%anticlockwise_coarse");
				}
			}

			if (detectedLinkName == "clockwiseFine"){
				if (range_listening == "STANDARD"){

					llSay(objectManipulationChannel, "OBJManip%"+user_name+"%clockwise_fine");
				}
				else{

					llRegionSay(objectManipulationChannel, "OBJManip%"+user_name+"%clockwise_fine");
				}

			}

			if (detectedLinkName == "anticlockwiseFine"){
				if (range_listening == "STANDARD"){
					llSay(objectManipulationChannel, "OBJManip%"+user_name+"%anticlockwise_fine");
				}
				else{
					llRegionSay(objectManipulationChannel, "OBJManip%"+user_name+"%anticlockwise_fine");
				}
			}

			if (detectedLinkName == "clearscene"){
				if(range_listening == "STANDARD"){
					llSay(commChannel,"deleteAll");
					llSay(PANTO_REZZOR_CHANNEL,"deleteAll");
					llRegionSay(tape_channel,"self_remove");
					llSay(FEED_BACK_CHANNEL,"0");
					totalNumberofObjectsRezzed = 0;
				}
				else
				{
					llRegionSay(commChannel,"deleteAll");
					llRegionSay(PANTO_REZZOR_CHANNEL,"deleteAll");
					llRegionSay(tape_channel,"self_remove");
					llSay(FEED_BACK_CHANNEL,"0");
					totalNumberofObjectsRezzed = 0;
				}
				integer BATTLE_SCORE_CHANNEL = -2884110;
				llSay(BATTLE_SCORE_CHANNEL,"GAME_RESET");
				llResetScript();
			}

			if (detectedLinkName == "removeselected"){
				if(range_listening == "STANDARD"){
					llSay(commChannel,"deleteThis");
					llSay(PANTO_REZZOR_CHANNEL,"deleteThis");
					totalNumberofObjectsRezzed--;
				}
				else
				{
					llRegionSay(commChannel,"deleteThis");
					llRegionSay(PANTO_REZZOR_CHANNEL,"deleteThis");
					totalNumberofObjectsRezzed--;
				}
				rezOrPositionMode = lastObjectRezzed;//so that obj does not need to be reselected again and menu display is in sync

				if(range_listening == "STANDARD"){ //do not forget to also let rezzor know and get in sync
					llSay(PANTO_REZZOR_CHANNEL,"rezOrPositionMode"+"%"+rezOrPositionMode);
				} else {
						llRegionSay(PANTO_REZZOR_CHANNEL,"rezOrPositionMode"+"%"+rezOrPositionMode);
				}
				if (feedback == "VERBOSE") llOwnerSay("current mode remains:"+rezOrPositionMode);
			}

			if (detectedLinkName =="resetControl"){
				if(range_listening == "STANDARD"){
					llSay(PANTO_REZZOR_CHANNEL,"resetPantoRezzor");
					totalNumberofObjectsRezzed=0;
				}
				else{
					llRegionSay(PANTO_REZZOR_CHANNEL,"resetPantoRezzor");
					totalNumberofObjectsRezzed=0;
				}
				llResetScript();
			}

			if (detectedLinkName == "accessMenu"){
				llDialog(dialogID,mainMenuMenuDlgMsg,order_buttons(accessMenu),channelDedicated2Dialog);
			}
			if (detectedLinkName == "snapshots"){
				GetNotecardsList();
				selectedSnapshotFile = llList2String( Notecards, 0);
				llDialog(dialogID,"SELECTED SCENE FILE: "+selectedSnapshotFile,order_buttons(snapshotsMenu),channelDedicated2Dialog);
			}

		}

	}

	link_message(integer sender_num, integer num, string msg, key id)
	{
		if(rezOrPositionMode == "positionPiece"){
			if (feedback == "VERBOSE") llOwnerSay("position piece");
			list my_list = llParseString2List(msg,["%"],[""]);
			if(range_listening == "STANDARD"){
				llSay(commChannel,(string)llList2String(my_list,0)+"%"+(string)llList2String(my_list,1)+"%"+(string)llList2String(my_list,2)+"%"+(string)llList2String(my_list,3));
				//MOVE SELECTED OBJECT IN PANTO REF FRAME
				vector var1 = (vector)llList2String(my_list,1);
				rotation var2=(rotation)llList2String(my_list,3)*RotBetween(llRot2Up((rotation)llList2String(my_list,3)),(vector)llList2String(my_list,2));
				llSay(PANTO_REZZOR_CHANNEL, "masterMovePANTO"+"%"+(string)selectedObjectIndex+"%"+(string)((var1-llGetPos())/llGetRot())+"%"+(string)(var2/llGetRot()));
			}
			else
			{
				llRegionSay(commChannel,(string)llList2String(my_list,0)+"%"+(string)llList2String(my_list,1)+"%"+(string)llList2String(my_list,2)+"%"+(string)llList2String(my_list,3));
				//MOVE SELECTED OBJECT IN PANTO REF FRAME
				vector var1 = (vector)llList2String(my_list,1);
				rotation var2=(rotation)llList2String(my_list,3)*RotBetween(llRot2Up((rotation)llList2String(my_list,3)),(vector)llList2String(my_list,2));
				llRegionSay(PANTO_REZZOR_CHANNEL, "masterMovePANTO"+"%"+(string)selectedObjectIndex+"%"+(string)((var1-llGetPos())/llGetRot())+"%"+(string)(var2/llGetRot()));
			}
		}
		else if(rezOrPositionMode != ""){

			objectPinIndex = objectPinIndex+1;
			rezParameter = (-1*commChannel*modulus_divisor)+(currentObjIndexCeil+objectPinIndex);
			list my_list = llParseString2List(msg,["%"],[""]);
			//*string param1 = (string)(((vector)llList2String(my_list,1) - llGetPos()) / llGetRot()) ;
			//*string param2 =  (string)((vector)llList2String(my_list,2)/llGetRot());
			//*if (debug_Setup_Data == 1) llSay(0,rezOrPositionMode+"%"+param1+"%"+param2+"%"+ (string)objectPinIndex);
			vector var1 = (vector)llList2String(my_list,1);
			rotation var2=(rotation)llList2String(my_list,3)*RotBetween(llRot2Up((rotation)llList2String(my_list,3)),(vector)llList2String(my_list,2));
			//rotation var2 =  llGetRot()*RotBetween(llRot2Up(llGetRot()),(vector)llList2String(my_list,2)); (old code, rezzed obj was not parallel to floor surface)
			if ( llSubStringIndex(rezOrPositionMode, "c_") != -1){
				create_n_command_center= llList2Vector(llGetLinkPrimitiveParams(linkName2linkNumber("createCommand"), [PRIM_POSITION]),0);
				var1 = create_n_command_center;
			}
			//***llOwnerSay("create and command:"+(string)linkName2linkNumber("createCommand"));
			//***llOwnerSay((string)llList2Vector(llGetLinkPrimitiveParams(linkName2linkNumber("createCommand"), [PRIM_POSITION]),0));
			//***llRezAtRoot(rezOrPositionMode,create_n_command_center, <0.0, 0.0, 0.0>,var2, rezParameter);
			llRezAtRoot(rezOrPositionMode, var1, <0.0,0.0,0.0>, var2, rezParameter);

			totalNumberofObjectsRezzed = totalNumberofObjectsRezzed+1;
			if (feedback == "VERBOSE") llOwnerSay("Total Number of Objects Rezzed =" +(string)(currentObjIndexCeil+totalNumberofObjectsRezzed));
			llSay(FEED_BACK_CHANNEL,(string)(currentObjIndexCeil+totalNumberofObjectsRezzed));

			//Sending message to SceneRezzor relay describing position and orientation w.r.t root NOT world coords
			if(range_listening == "STANDARD"){
				llSay(PANTO_REZZOR_CHANNEL,rezOrPositionMode+"%"+(string)((var1-llGetPos())/llGetRot())+"%"+(string)(var2/llGetRot())+"%"+(string)(currentObjIndexCeil+objectPinIndex));
			}
			else{
				//llSay(0,"Rezzing: "+(string)rezOrPositionMode);
				llRegionSay(PANTO_REZZOR_CHANNEL,rezOrPositionMode+"%"+(string)((var1-llGetPos())/llGetRot())+"%"+(string)(var2/llGetRot())+"%"+(string)(currentObjIndexCeil+objectPinIndex));
			}
			lastObjectRezzed = rezOrPositionMode; //last object rezzed
		}
	}


	listen( integer channel, string name, key id, string message )
	{

		list received_list = llParseString2List(message,["%"],[""]);


		if(llList2String(received_list,0) == "objectGotPicked"){
			selectedObjectIndex = (integer)llList2String(received_list,1);
			if (feedback == "VERBOSE") llOwnerSay("object that got picked has index:" + (string)selectedObjectIndex);
			if(range_listening == "STANDARD"){
				llSay(PANTO_REZZOR_CHANNEL, "selectObjPANTO"+"%"+(string)selectedObjectIndex+"%"+(string)llList2String(received_list,2));
			}
		{
			llRegionSay(PANTO_REZZOR_CHANNEL, "selectObjPANTO"+"%"+(string)selectedObjectIndex+"%"+(string)llList2String(received_list,2));
		}
		}

		else if (channel == DMKCONTROL){ //This section couples the graphics menu system to the control station

			if (feedback == "VERBOSE") llOwnerSay(message);
			//objectSelectedName = message;
			rezOrPositionMode = message;

			if (message == "unselectAll"){
				if (feedback == "VERBOSE") llOwnerSay("unselecting all");
				if(range_listening == "STANDARD"){
					llSay(commChannel,"unselectAll");
					llSay(PANTO_REZZOR_CHANNEL,"unselectAll");
				}
				else
				{
					llRegionSay(commChannel,"unselectAll");
					llRegionSay(PANTO_REZZOR_CHANNEL,"unselectAll");
				}
			}
			//Notify sceneRezzor of current state of controlStation
			if(range_listening == "STANDARD"){
				llSay(PANTO_REZZOR_CHANNEL,"rezOrPositionMode"+"%"+rezOrPositionMode);
			} else {
					llRegionSay(PANTO_REZZOR_CHANNEL,"rezOrPositionMode"+"%"+rezOrPositionMode);
			}
		}
		else if(channel == channelDedicated2Dialog){



			//MAIN MENU SECTION - START
			if (message == "Snapshots"){
				llDialog(dialogID,snapshotsMenuDlgMsg+"\n"+"SELECTED SCENE FILE: "+selectedSnapshotFile,order_buttons(snapshotsMenu),channelDedicated2Dialog);
			}

			else if (message == "Controls"){
				llDialog(dialogID,optionsDialogMsg,order_buttons(optionsMenu),channelDedicated2Dialog);
			}
			//MAIN MENU SECTION - END

			//CONTROLS MENU - START
			if (message == "PUBLIC"){
				control_access = "public";
				llWhisper(0,"Anyone can now control the core Gameboard functions e.g. changing game, setting up, ...");
				llDialog(dialogID,optionsDialogMsg,order_buttons(optionsMenu),channelDedicated2Dialog);
			}
			else if (message == "GROUP"){
				control_access = "group";
				llWhisper(0,"Only avies sharing the same group as the one to which Gameboard is set can now control the core Gameboard functions e.g. changing game, setting up, ...");
				llDialog(dialogID,optionsDialogMsg,order_buttons(optionsMenu),channelDedicated2Dialog);
			}

			else if (message == "CHAN(-25)"){

				commChannel = -25;
				llListen(commChannel, "",NULL_KEY, "");
				if (feedback == "VERBOSE") llOwnerSay("Setting comm channel"+(string)commChannel);
			}
			//CONTROLS MENU - END


			//SNAPSHOTS MENU - START
			else if (message =="SCENE>>"){
				if(notecardIndex < llGetListLength(Notecards)-1) notecardIndex++;
				selectedSnapshotFile = llList2String( Notecards, notecardIndex);
				llOwnerSay(llList2String( Notecards, notecardIndex));
				llDialog(dialogID,"SELECTED SCENE FILE: "+selectedSnapshotFile,order_buttons(snapshotsMenu),channelDedicated2Dialog);////added on 4.9.2014
			}
			else if (message =="SCENE<<"){
				if(notecardIndex > 0) notecardIndex--;
				selectedSnapshotFile = llList2String( Notecards, notecardIndex);
				llOwnerSay(llList2String( Notecards, snapshotIndex));
				llDialog(dialogID,"SELECTED SCENE FILE: "+selectedSnapshotFile,order_buttons(snapshotsMenu),channelDedicated2Dialog);
			}
			else if (message == "LOAD SCN"){
				rName=selectedSnapshotFile;
				rLine=0;
				rQueryID = llGetNotecardLine( rName, rLine);
			}
			else if (message == "MORPH"){ //Keeping for the future
				mrName=selectedSnapshotFile;
				mrLine=0;
				mrQueryID = llGetNotecardLine( mrName, mrLine);
			}
			// else if (message == "SaveScene"){
			// if(range_listening == "STANDARD"){
			// llSay(commChannel,"recording"+"%"+(string)llGetPos()+"%"+(string)llGetRot());
			// }
			// else
			// {
			// llRegionSay(commChannel,"recording"+"%"+(string)llGetPos()+"%"+(string)llGetRot());
			// }
			// llDialog(dialogID,snapshotsMenuDlgMsg,order_buttons(snapshotsMenu),channelDedicated2Dialog);
			// }
			//SNAPSHOTS MENU - END


		}
		else {
			list my_list = llParseString2List(message,["%"],[""]);
			if (llList2String(my_list,1) == "unselectPieces"){
				rezOrPositionMode = "positionPiece";
				//Notify sceneRezzor of current state of controlStation
				if(range_listening == "STANDARD"){
					llSay(PANTO_REZZOR_CHANNEL,"rezOrPositionMode"+"%"+rezOrPositionMode);
				} else {
						llRegionSay(PANTO_REZZOR_CHANNEL,"rezOrPositionMode"+"%"+rezOrPositionMode);
				}
			}
			else if ((rezOrPositionMode != "positionPiece")&&(llList2String(received_list,0) != "recording")){
				if (feedback == "VERBOSE") llOwnerSay("Debug stmt received:" + rezOrPositionMode);
				objectPinIndex = objectPinIndex+1;
				rezParameter = (-1*commChannel*modulus_divisor)+(currentObjIndexCeil+objectPinIndex);
				//rezParameter = (-1*commChannel*modulus_divisor)+objectPinIndex;
				//*string param1 = (string)(((vector)llList2String(my_list,1) - llGetPos()) / llGetRot());
				//*string param2 =  (string)((vector)llList2String(my_list,2)/llGetRot());
				//*if (debug_Setup_Data == 1) llSay(0,rezOrPositionMode+"%"+param1+"%"+ param2+"%"+ (string)objectPinIndex);
				vector var1=(vector)llList2String(my_list,1);
				//Now aligning next object to rez with the last one clicked, replace llGetRot() by global rotation of last object clicked
				rotation var2=(rotation)llList2String(my_list,3)*RotBetween(llRot2Up((rotation)llList2String(my_list,3)),(vector)llList2String(my_list,2));
				llRezAtRoot(rezOrPositionMode,var1, <0.0, 0.0, 0.0>,var2, rezParameter);
				totalNumberofObjectsRezzed = totalNumberofObjectsRezzed+1;
				if (feedback == "VERBOSE") llOwnerSay("Total Number of Objects Rezzed =" + (string)(currentObjIndexCeil+totalNumberofObjectsRezzed));
				llSay(FEED_BACK_CHANNEL,(string)(currentObjIndexCeil+totalNumberofObjectsRezzed));
				if(range_listening == "STANDARD"){
					llSay(PANTO_REZZOR_CHANNEL,rezOrPositionMode+"%"+(string)((var1-llGetPos())/llGetRot())+"%"+(string)(var2/llGetRot())+"%"+(string)(currentObjIndexCeil+objectPinIndex));
				} else {
						llRegionSay(PANTO_REZZOR_CHANNEL,rezOrPositionMode+"%"+(string)((var1-llGetPos())/llGetRot())+"%"+(string)(var2/llGetRot())+"%"+(string)(currentObjIndexCeil+objectPinIndex));
				}
				lastObjectRezzed = rezOrPositionMode; //last object rezzed
			}
			else if (rezOrPositionMode == "positionPiece"){ //Testing for move onto moving secondary
				if (feedback == "VERBOSE") llOwnerSay("sending position data from controls");
				vector var1=(vector)llList2String(my_list,1);
				//Now aligning next object to rez with the last one clicked, replace llGetRot() by global rotation of last object clicked
				rotation var2=(rotation)llList2String(my_list,3)*RotBetween(llRot2Up((rotation)llList2String(my_list,3)),(vector)llList2String(my_list,2));
				//llSay(PANTO_REZZOR_CHANNEL,rezOrPositionMode+"%"+(string)((var1-llGetPos())/llGetRot())+"%"+(string)(var2/llGetRot()));
				if(range_listening == "STANDARD"){
					llSay(PANTO_REZZOR_CHANNEL, "masterMovePANTO"+"%"+(string)selectedObjectIndex+"%"+(string)((var1-llGetPos())/llGetRot())+"%"+(string)(var2/llGetRot()));
				} else {
						llRegionSay(PANTO_REZZOR_CHANNEL, "masterMovePANTO"+"%"+(string)selectedObjectIndex+"%"+(string)((var1-llGetPos())/llGetRot())+"%"+(string)(var2/llGetRot()));
				}
			}
		}
	}

	on_rez(integer param)
	{   // Triggered when the object is rezzed, like after the object has been sold from a vendor
		llResetScript();//By resetting the script on rez forces the listen to re-register.
		control_access = "public";
		//objectPinIndex = 0;
		snapshotIndex = 0;
	}

	changed(integer mask)
	{   // Triggered when the object containing this script changes owner.
		if(mask & CHANGED_OWNER)
		{
			llResetScript();
		}
		if (mask & CHANGED_INVENTORY)
		{
			llResetScript();
		}
	}

	dataserver(key query_id, string data) {
		//REZZING, Placing and orienting objects based on data read from file

		if (query_id == rQueryID) { //Frames- rezzing objects fresh
			if ((data != EOF)&&(data != "")) {    // not at the end of the notecard
				list my_list = llParseString2List(data,["%"],[""]);
				vector placeItHere = (vector)llList2String(my_list,1)*llGetRot()+llGetPos();
				rotation orientItSo = (rotation)llList2String(my_list,2)*llGetRot();
				integer objectPinIndex = (integer) llList2String(my_list,3);
				if (objectPinIndex > current_largest_loaded_pinIndex ) current_largest_loaded_pinIndex = objectPinIndex;
				integer commChannelAndDataAsRezParam = -(1*commChannel*modulus_divisor)+objectPinIndex;
				llRezAtRoot((string) llList2String(my_list,0), placeItHere, <0.0,0.0,0.0>,orientItSo, commChannelAndDataAsRezParam);
				if(range_listening == "STANDARD"){
					llSay(PANTO_REZZOR_CHANNEL,(string) llList2String(my_list,0)+"%"+(string)((placeItHere-llGetPos())/llGetRot())+"%"+(string)(orientItSo/llGetRot())+"%"+(string)objectPinIndex);
				} else {
						llRegionSay(PANTO_REZZOR_CHANNEL,(string) llList2String(my_list,0)+"%"+(string)((placeItHere-llGetPos())/llGetRot())+"%"+(string)(orientItSo/llGetRot())+"%"+(string)objectPinIndex);
				}
				++rLine;                // increase line count //PLEASE MAKE SURE THAT YOU DO NOT PRESS ENTER AFTER THE LAST LINE
				currentObjIndexCeil=current_largest_loaded_pinIndex;
				llSleep(0.25);
				rQueryID = llGetNotecardLine(rName, rLine);    // request next line
			} else {if (feedback == "VERBOSE") llOwnerSay("total number of objects Loaded = "+(string)currentObjIndexCeil);
				llSay(0,"All objects loaded for "+selectedSnapshotFile);
				llRegionSay(PANTO_REZZOR_CHANNEL,"resetRezzor");
				llSay(FEED_BACK_CHANNEL,(string)currentObjIndexCeil);}
		}
		//MORPHING scene of objects by moving are reorienting them based on data read from file
		else if (query_id == mrQueryID) { //moving objects
			if (data != EOF) {    // not at the end of the notecard
				list my_list = llParseString2List(data,["%"],[""]);
				vector placeItHere = (vector)llList2String(my_list,1)*llGetRot()+llGetPos();
				rotation orientItSo = (rotation)llList2String(my_list,2)*llGetRot();
				if(range_listening == "STANDARD"){
					llSay(commChannel, "masterMove"+"%"+(string)placeItHere+"%"+(string)orientItSo+"%"+llList2String(my_list,3));
				}
				else
				{
					llRegionSay(commChannel, "masterMove"+"%"+(string)placeItHere+"%"+(string)orientItSo+"%"+llList2String(my_list,3));
				}
				if(range_listening == "STANDARD"){
					llSay(PANTO_REZZOR_CHANNEL, "masterMovePANTO"+"%"+llList2String(my_list,3)+"%"+(string)((placeItHere-llGetPos())/llGetRot())+"%"+(string)(orientItSo/llGetRot()));
				} else {
						llRegionSay(PANTO_REZZOR_CHANNEL, "masterMovePANTO"+"%"+llList2String(my_list,3)+"%"+(string)((placeItHere-llGetPos())/llGetRot())+"%"+(string)(orientItSo/llGetRot()));
				}
				++mrLine;                // increase line count //PLEASE MAKE SURE THAT YOU DO NOT PRESS ENTER AFTER THE LAST LINE
				mrQueryID = llGetNotecardLine(mrName, mrLine);    // request next line
			} else {if (feedback == "VERBOSE") llOwnerSay("All move data loaded.");}
		}
	}
}
