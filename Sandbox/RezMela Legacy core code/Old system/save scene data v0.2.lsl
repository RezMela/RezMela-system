//Compact function to put buttons in "correct" human-readable order

integer commChannel=-4000; //This is the default value that map icons will be listening on
integer SAVE_CHANNEL = -40290770;		// used in comms from icons to "save scene data"
integer textBoxChannel=-76;
integer list_length;
integer last_list_length;
list chatlines;

integer recordChn;
integer textBoxChn;
key clicker;

string filename;
 
list order_buttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4)
         + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}
 

default
{
    state_entry()
    {   // Create random channel within range [-1000000000,-2000000000]
        llPassTouches(FALSE);
        llSetText("", <1,1,1>,1);
        chatlines = [];
        textBoxChn=llListen(textBoxChannel,"","","");
    }
 
    touch_start(integer total_number)
    {
        clicker = llDetectedKey(0);
        chatlines = [];
        recordChn=llListen(SAVE_CHANNEL, "", "","");
        llSay(commChannel,"recording"+"%"+(string)llGetRootPosition()+"%"+(string)llGetRootRotation());
        llTextBox(clicker, "Enter scenario file name:", textBoxChannel);
    }
 
    link_message(integer sender_num, integer num, string msg, key id) 
    {
        llOwnerSay(msg);
        commChannel = (integer)msg;
    } 
    
    listen(integer _chan, string _name, key _id, string _message)
    {
        
        
        if (_chan == SAVE_CHANNEL){
            chatlines = [_message]+chatlines;
        }
        else if (_chan == textBoxChannel){
            filename = _message;
            llSay(0,"Saving "+filename);
            llSay(0,"Please wait.");
            //llOwnerSay("Captured this data:"+llDumpList2String(chatlines, "\n"));
            osMakeNotecard(filename,chatlines); //Makes the notecard.
            llGiveInventory(llGetLinkKey(1),filename); //Sends the notecard to root.
            llRemoveInventory(filename);
            llListenRemove(recordChn);
            chatlines = [];
            llSay(0,"The scene "+filename+ " has been saved.");
            
        }
        
    }
    
}