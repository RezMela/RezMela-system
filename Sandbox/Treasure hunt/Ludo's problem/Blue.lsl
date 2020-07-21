// Treasure hunt object v0.2

// v0.2 make work in linkset
// v0.21 Prevent Gem from being unlinked and destroyed

integer CHAT_CHANNEL = -19308880;


key Avid;


default {
    on_rez(integer Start) {
        llResetScript();
    }
    state_entry() {
        llSetAlpha(1.0, ALL_SIDES);
    }
    
    touch_start(integer Count) {
        llSetAlpha(1.0, ALL_SIDES);
        Avid = llDetectedKey(0);
        llRegionSayTo(Avid, CHAT_CHANNEL, llGetObjectName());
    }
    dataserver(key From, string Data) {
        if (Data == "G") {
            if (llGetNumberOfPrims() > 1) {
                // if it's part of a linkset, unlink, then destroy
                // send a message to the Found_me script
                llMessageLinked(LINK_ROOT, 0, "Found me!", NULL_KEY);
            }
           
        }
    }
   
}
// Treasure hunt object v0.21