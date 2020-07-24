//Secondary child
//Copyright (C) 2012 by Rameshsharma Ramloll

//This file is subject to the terms and conditions defined in
//file 'LICENSE.txt', which is part of this source code package.

integer     rezParameter;
integer     commChannel;
integer     modulus_divisor=1000;            
integer     Energy =0;
integer     Energy_threshold_for_selection = 2;
integer     Energy_threshold_for_deselection = 200;
float       Glow = 0;
string      person_who_clicked_down = "";
string      bar = "";
integer     I_am_selected = 0;
string      person_who_selected ="";
vector      last_detected_touch_pos;
vector      touched_normal_global;//up
vector      touched_binormal_global;
rotation     new_root_rotation;
list         link_positions = [];
list        link_rotations = [];

//MAIN FLAGS
string      root_mobility_flag = "DISABLE"; //To enable or disable the functionality whereby root can be moved
string         range_listening = "STANDARD"; //Flag REGION|STANDARD

integer scanLinkset(vector origin,rotation origin_rot)
{
    integer link_qty = llGetNumberOfPrims();
    integer link_index;
    vector link_pos;
    rotation link_rot;

    link_positions = [];
    link_rotations = [];
     
    //script made specifically for linksets, not for single prims
    if (link_qty > 1)
    {
        //link numbering in linksets starts with 1
        for (link_index=1; link_index <= link_qty; link_index++)
        {
            link_pos=(llList2Vector(llGetLinkPrimitiveParams(link_index,[PRIM_POSITION]),0)-origin)/origin_rot; //Gets local positions wrt root prim
            link_rot=llList2Rot(llGetLinkPrimitiveParams(link_index,[PRIM_ROTATION]),0)/origin_rot; //Gets local rotations wrt root prim
           
            link_positions += [link_pos];
            link_rotations += [link_rot];
        }
    }
    else
    {
        llOwnerSay("error: this script doesn't work for non-linked objects");
        return FALSE;
    }
 
    return TRUE;
}
    
reconstructObject(){
    integer link_qty = llGetNumberOfPrims();
    integer link_index;
    vector new_pos;
    rotation new_rot;
    
     if (link_qty > 1)
    {
        //link numbering in linksets starts with 1
        for (link_index=1; link_index <= link_qty; link_index++)
        {
            
            new_pos = llList2Vector(link_positions, link_index-1);
            new_rot = llList2Rot(link_rotations, link_index-1);
 
            if (link_index == LINK_ROOT)
            {
                llSetLinkPrimitiveParamsFast(LINK_ROOT,[PRIM_POSITION, last_detected_touch_pos]);//region coordinates- stmt works as expected
                llSetLinkPrimitiveParamsFast(LINK_ROOT,[PRIM_ROTATION, llRotBetween(<0,0,1>, touched_normal_global)]);//region coordinates - stmt works as expected
            }
            else
            {
                llSetLinkPrimitiveParamsFast(link_index, [PRIM_POSITION,new_pos]);//local coordinates w.r.t root prim, for child prims believe it or not, PRIM_POSITIONS IS LOCAL
                llSetLinkPrimitiveParamsFast(link_index, [PRIM_ROT_LOCAL,new_rot]);
            }
        }
    }
}

        
rotation RotBetween(vector start, vector end) //adjusts quaternion magnitude so (start * return == end)
{//Authors note: I have never had a use for this but it's good to know how to do it if I did.
  rotation rot = llRotBetween(start, end);
  if(llVecMag(start)!= 0){
    if(llVecMag(end)!= 0){
            float d = llSqrt(llVecMag(end) / llVecMag(start));
            return <rot.x * d, rot.y * d, rot.z * d, rot.s * d>;
    }
  }
 return rot;
}

default
{
    state_entry()
    {
        llSetText("",<1,1,1>,1);
    }

    touch_start(integer total_number)
    {
        //llSetAlpha(0.8, ALL_SIDES);
        integer i = 0;
        Energy = 0;
        Glow = 0;
        llSetTimerEvent(0.1);   
        person_who_clicked_down = llDetectedName(0); 
        if(root_mobility_flag == "ENABLE"){
            if (person_who_clicked_down == person_who_selected){
                last_detected_touch_pos = llDetectedTouchPos(i);
                touched_normal_global=-1*llDetectedTouchNormal(i);//makes sure that the z direction of movable root object points into surface
                if (llDetectedName(i) == person_who_clicked_down) {
                     //Move movable root object to this position
                    scanLinkset( llDetectedTouchPos(i) ,llRotBetween(<0,0,1>, touched_normal_global));
                    reconstructObject();
                }
            }
        }
        
    }
        
    touch_end(integer total_number){
        
        llSetAlpha(1, ALL_SIDES);
        if (Energy < Energy_threshold_for_selection)llSetTimerEvent(0);
        
        
        integer i = 0;
        for(; i<total_number; ++i){
            if (llDetectedName(0) != person_who_selected){ //otherwise clicking on the same object will move it, causing it to drift
                if (range_listening == "STANDARD"){
                    llSay(commChannel, llDetectedName(i)+"%"+(string)llDetectedTouchPos(i)+"%"+(string)llDetectedTouchNormal(i)+"%"+(string)llGetRootRotation());
                }
                else
                {
                    llRegionSay(commChannel, llDetectedName(i)+"%"+(string)llDetectedTouchPos(i)+"%"+(string)llDetectedTouchNormal(i)+"%"+(string)llGetRootRotation());
                }
            }
            else{
               
            }
        }
        
        bar = "";
        llSetText(bar,<1,1,1>,1);//clear bar before displaying name
    }
    
    link_message(integer sender_num, integer num, string msg, key id)
    {
        //Receiving link messages from object handle
        if (msg == "release_object"){
            //llSay(0,"I am unselected!");
            I_am_selected = 0;
            person_who_selected = "";
        }
        
    }
    on_rez(integer param)
    {   
        //llResetScript();//By resetting the script on rez forces the listen to re-register.
        llSetTimerEvent(0);
        rezParameter=llGetStartParameter();
        commChannel = -1*(integer)rezParameter/modulus_divisor;
    }
    
    timer(){
        Energy++;
        if (Energy == Energy_threshold_for_selection) {
            llSetText("",<1,1,1>,1);//clear bar before displaying name
            //Send message to root prim about who selected after specific delay 
            llMessageLinked( LINK_ALL_OTHERS, 0,person_who_clicked_down+"%pick_object"        ,"" ); 
            I_am_selected = 1;
            person_who_selected = person_who_clicked_down;
        }
        
        if ((Energy > Energy_threshold_for_selection)&&(I_am_selected == 0)) {
            //If I have been previously selected by a person and then indirectly unselected because same person clicked on another, need to stop timer
            llSetTimerEvent(0);
        }
        
        if (Energy < Energy_threshold_for_selection){
            //Display energy growing on object being selected
            //bar = bar + "████";
            bar = "";
            llSetText(bar,<0.3,1,0.3>,1);
            if (Glow < 0.2) {
                Glow=Glow+0.01;
                llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_GLOW,ALL_SIDES,Glow]);
            }
        }
        if (Energy > Energy_threshold_for_deselection){
            //deselect object if no one has interacted with it for a significant period of time
            //llSay(0,"Deselection level reached");
            if (I_am_selected == 1){
                llMessageLinked( LINK_ALL_OTHERS, 0,person_who_clicked_down+"%pick_object"        ,"" ); 
                person_who_selected = "";
            }
            Energy = 0;
            Glow = 0;
            bar = "";
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_GLOW,ALL_SIDES,Glow]);
            llSetText(bar,<1,1,1>,1);//clear bar before displaying name
            llSetTimerEvent(0);
        }
    } 
}
