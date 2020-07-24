//Rezzor Root
//Copyright(C) 2012 by Rameshsharma Ramloll
// This file is subject to the terms and conditions defined in
// file 'LICENSE.txt', which is part of this source code package.



list        objectMainList=[];

integer     commChannel;

integer     modulus_divisor=90000;//used in parameter passing, equivalent to number of possible objects that can be rezzed


string      rezOrPostionMode ="";//this var also points to the name of a piece when mode is Rez
string      object_list = "";


integer     rezParameter;

//string      control_access;
integer     objectPinIndex = 0;





//MAIN FLAGS
string      range_listening = "REGION"; //Flag REGION|STANDARD
integer     debug_Setup_Data = 0;
integer     SCENE_REZZOR_CHANNEL = -101;
vector      rezzor_origin;
rotation    rot_of_rezzor_at_origin;

//Scale flags
float new_scale = 40.0;

setupListener(integer c){

	llListen(c, "",NULL_KEY, "");
}


integer RandInt(integer lower, integer higher)
{
	integer Range = higher - lower;
	integer Result = llFloor(llFrand(Range + 1)) + lower;
	return Result;
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
	{

		//commChannel = -1*RandInt(5000,5100);
		commChannel = -4001;
		llListen(SCENE_REZZOR_CHANNEL,"","","");




		llSetText("",<1,1,1>,1);
		objectMainList = [];

		rezzor_origin = llGetPos();
		rot_of_rezzor_at_origin = llGetRot();
		rezOrPostionMode ="";

	}


	listen( integer channel, string name, key id, string message )
	{

		list received_list = llParseString2List(message,["%"],[""]);
		//llOwnerSay("Rezzor: "+(string)received_list);

		//Rezzor channel to rez objects anywhere on sim by bypassing limitations on rez command
		if(channel == SCENE_REZZOR_CHANNEL){

			if(message == "deleteAll"){
				if(range_listening == "STANDARD"){
					llSay(commChannel,"deleteAll");
				}else{
						llRegionSay(commChannel,"deleteAll");
				}
				llSetRegionPos(rezzor_origin);
				//warp(rezzor_origin);
				llSetRot(rot_of_rezzor_at_origin);
				llResetScript();
			}

			else if (message == "resetRezzor"){
				llSetRegionPos(rezzor_origin);
				llSetRot(rot_of_rezzor_at_origin);
			}
			else if(message == "unselectAll"){
				if(range_listening == "STANDARD"){
					llSay(commChannel,"unselectAll");
				}else{
						llRegionSay(commChannel,"unselectAll");
				}
			}
			else if((string) llList2String(received_list,0)== "resetPantoRezzor"){
				//warp(rezzor_origin);
				llSetRegionPos(rezzor_origin);
				llSetRot(rot_of_rezzor_at_origin);
				if(range_listening == "STANDARD"){
					llSay(commChannel,"deleteAll");
				}else{
						llRegionSay(commChannel,"deleteAll");
				}
				llResetScript();
			}
			else if((string) llList2String(received_list,0)== "selectObjPANTO"){
				integer objectPinIndex = (integer)llList2String(received_list,1);
				if(range_listening == "STANDARD"){

					llSay(commChannel,"selectPantMe"+"%"+(string)llList2String(received_list,2)+"%"+(string)objectPinIndex);
				}
				else
				{
					llRegionSay(commChannel,"selectPantMe"+"%"+(string)llList2String(received_list,2)+"%"+(string)objectPinIndex);
				}

			}
			else if((string) llList2String(received_list,0)== "deleteThis"){
				integer objectPinIndex = (integer)llList2String(received_list,1);
				if(range_listening == "STANDARD"){
					llSay(commChannel,"deleteThis");
				}
				else
				{
					llRegionSay(commChannel,"deleteThis");
				}
			}
			else if((string) llList2String(received_list,0)== "masterMovePANTO"){

				integer objectPinIndex = (integer)llList2String(received_list,1);
				vector placeItHere = (vector)llList2String(received_list,2);
				rotation orientItSo = (rotation)llList2String(received_list,3);
				vector rezzorOriginPos = rezzor_origin;
				rotation rezzorOriginRot = rot_of_rezzor_at_origin;
				placeItHere = new_scale*placeItHere;//trial
				placeItHere = (rezzorOriginPos+placeItHere)/rezzorOriginRot;
				orientItSo = orientItSo*rezzorOriginRot;
				if(range_listening == "STANDARD"){
					llSay(commChannel, "masterMove"+"%"+(string)placeItHere+"%"+(string)orientItSo+"%"+(string)objectPinIndex);
				}
				else{
					llRegionSay(commChannel, "masterMove"+"%"+(string)placeItHere+"%"+(string)orientItSo+"%"+(string)objectPinIndex);
				}
			}
			else if((string) llList2String(received_list,0)== "rezOrPositionMode"){
				rezOrPostionMode = (string) llList2String(received_list,1);

			}
			else if (rezOrPostionMode != "positionPiece"){
				string pantoObj = (string) llList2String(received_list,0)+"P";//P added inorder to have different names for Panto Objects
				vector pantoObjPos = (vector) llList2String(received_list,1);
				rotation pantoObjRot = (rotation) llList2String(received_list,2);
				pantoObjPos = new_scale*pantoObjPos;//trial
				objectPinIndex = (integer)llList2String(received_list,3);
				rezParameter = (-1*commChannel*modulus_divisor)+objectPinIndex;
				//warp((rezzor_origin+pantoObjPos*llGetRot()));
				vector objectToRezPosition = rezzor_origin+pantoObjPos*llGetRot();
				llSetRegionPos(objectToRezPosition);
				//llOwnerSay("Panto rezzing following obj:"+pantoObj);
				llRezAtRoot(pantoObj,objectToRezPosition, <0.0, 0.0, 0.0>,pantoObjRot*llGetRot(), rezParameter);
				//llRezAtRoot(pantoObj,(llGetPos()+pantoObjPos)/llGetRot(), <0.0, 0.0, 0.0>,pantoObjRot, rezParameter); only works if warp is not used
			}


		}
		//SCENE_REZZOR_CHANNEL CODE ENDS

	}

	on_rez(integer param)
	{   // Triggered when the object is rezzed, like after the object has been sold from a vendor
		llResetScript();//By resetting the script on rez forces the listen to re-register.

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


}
