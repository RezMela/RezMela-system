float   gVelocity   = 15.0;
float   gReloadTime = 0.30;
string  gShootSound = "gun";
string  gShootAnimation = "hold_R_bazooka";
string  gBullet = "bullet 1.0";
integer gPermFlags;
 
default
{
    state_entry()
    {
        //  sanity check
        if (llGetInventoryType(gBullet) != INVENTORY_OBJECT) {
            llOwnerSay("This needs a physical object called " + gBullet + " in it to work");
            return;
        }
        gPermFlags = PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS | PERMISSION_TRACK_CAMERA;
 
        if ( llGetAttached() )
            llRequestPermissions(llGetOwner(), gPermFlags);
    }
 
    attach(key id)
    {
        if (id){
            gPermFlags = PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS | PERMISSION_TRACK_CAMERA;
            llRequestPermissions(id, gPermFlags);
        }
        else
        {
            llStopAnimation(gShootAnimation);
            llReleaseControls();
        }
    }
 
    changed(integer change)
    {
        if (change & (CHANGED_OWNER | CHANGED_INVENTORY) )
            llResetScript();
    }
 
    run_time_permissions(integer perm)
    {
        //  ensure ALL required permissions have been granted
        if ( perm & PERMISSION_ATTACH )   {  
            llAttachToAvatar( ATTACH_RHAND );
            llRequestPermissions(llGetOwner(), gPermFlags);
        }     
        else     
            llOwnerSay( "Permission to attach denied" );
            
        if ( (perm & gPermFlags) == gPermFlags)
        {
            llTakeControls(CONTROL_ML_LBUTTON, TRUE, FALSE);
            llStartAnimation(gShootAnimation);
            llOwnerSay("Gun is ready. Enter mouselook and use left click to fire!");
        }
    }
 
    control(key id, integer held, integer change)
    {
        rotation Rot = llGetCameraRot();
        if ( held & change & CONTROL_ML_LBUTTON)
        {
            if (llGetInventoryType(gShootSound) == INVENTORY_SOUND)
                llPlaySound(gShootSound, 1.0);
 
            llRezAtRoot(gBullet, llGetCameraPos() + <1.5, 0.0, 0.0>*Rot, gVelocity*llRot2Fwd(Rot), Rot, 10);
            llSleep(gReloadTime);
        }
    }
    
    
    touch_start(integer num_detected) {
        llRequestPermissions(llDetectedKey(0), PERMISSION_ATTACH);
        
    }
 
    on_rez(integer rez)
    {
        if (!llGetAttached() )        //reset the script if it's not attached.
            llResetScript();      
    }
 
    
}