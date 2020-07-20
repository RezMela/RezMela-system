// Damage linked flame (original)
//
// Ramesh's animated fire texture, modified to be triggered by "object damage" script
//
default
{
    state_entry()                                   
    {    
        llTargetOmega(<0.0,0.0,1.0>*llGetRot(),0,0);
        llSetTextureAnim (ANIM_ON | LOOP, ALL_SIDES, 4, 4, 0, 0, 16.0);              
    }
    link_message(integer sender, integer num, string str, key id) {
        if (num == -18007420) {
            if ((integer)str)
                llSetAlpha(0.0, ALL_SIDES);
            else
                llSetAlpha(1.0, ALL_SIDES);
        }
    }
}
// Damage linked flame (original)