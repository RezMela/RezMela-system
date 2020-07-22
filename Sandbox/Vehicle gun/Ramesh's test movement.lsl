integer force = 2000;
vector xyz_angles = <0,0,5>;
string current_operation;
integer current_force;

integer check_for_prim(string name)
{
    integer i = llGetNumberOfPrims();
    for (; i >= 0; --i)
    {
        if (llGetLinkName(i) == name)
        {
            return TRUE;
        }
    }
    return FALSE;
}

default
{
    state_entry()
    {
        llSetStatus(STATUS_DIE_AT_EDGE, TRUE);
        llSetStatus(STATUS_PHYSICS, FALSE);
        llSetBuoyancy(0.0);
        llSetTimerEvent(0.5);
    }
    touch_start(integer i)
    {
     
        
        integer detectedLinkNum = llDetectedLinkNumber(0);
        
        
        if (llGetLinkName(detectedLinkNum)== "stop"){
            llSetStatus(STATUS_PHYSICS, FALSE);
            llSetBuoyancy( 0.0 );
        }
        else if (llGetLinkName(detectedLinkNum)== "go"){  
            llSetStatus(STATUS_PHYSICS, TRUE);
            llSetBuoyancy( 0.2);
            llSetForce(<force,0,0>, TRUE); 
            current_force = force;
        }
        else if (llGetLinkName(detectedLinkNum)== "right"){  
            current_operation = "right";
            llSetForce(<0,0,0>, TRUE); 
            llSetTimerEvent(0.2);
        }
        else if (llGetLinkName(detectedLinkNum)== "left"){  
            current_operation = "left";
            llSetForce(<0,0,0>, TRUE); 
            llSetTimerEvent(0.2);
        }
        else if (llGetLinkName(detectedLinkNum)== "stopturn"){  
            current_operation = "";
            llSetTimerEvent(0);
        }
        else if (llGetLinkName(detectedLinkNum)== "reverse"){  
            llSetStatus(STATUS_PHYSICS, TRUE);
              llSetBuoyancy( 0.2 );
            llSetForce(<-force,0,0>, TRUE); 
            current_force = -force;
        }
    }
    
    touch_end(integer i){
      
    }
    
    timer(){
        if (current_operation == "right"){
            llSetRot(llGetRot()*llEuler2Rot(-1*xyz_angles*DEG_TO_RAD)); 
        }
        else if (current_operation == "left"){
            llSetRot(llGetRot()*llEuler2Rot(xyz_angles*DEG_TO_RAD)); 
        }
        llSetBuoyancy(0.0);
        llSetBuoyancy(1.0);
        //llSetForce(<current_force,0,0>, TRUE); 
    }
    
    
}