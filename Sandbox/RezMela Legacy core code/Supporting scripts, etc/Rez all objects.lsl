
vector HOME = <219.2, 70, 21>;
float DELAY = 1.0;
integer Ptr;
integer Count;
float MARGIN = 10;
float GAP = 1.0;
float X;
float Y;

MoveTo(vector NewPos) {
    list Params = [];
    integer Jumps = (integer)(llVecDist(llGetPos(), NewPos) / 10.0) + 1;
    while(Jumps--) {
        Params += [ PRIM_POSITION, NewPos ];
    }
    llSetLinkPrimitiveParamsFast(1, Params);
}

default {
    state_entry() {
        HOME=llGetPos();
        llSetStatus(STATUS_RETURN_AT_EDGE, TRUE);
        X = MARGIN;
        Y = MARGIN;
        Ptr = 0;
        Count = llGetInventoryNumber(INVENTORY_OBJECT);
        llOwnerSay("Time to rez: " + (string)llCeil(((float)Count * DELAY) / 60.0) + " mins");
        llSetTimerEvent(0.5);
    }
    timer() {
        llSetTimerEvent(0.0);
        string Name = llGetInventoryName(INVENTORY_OBJECT, Ptr);
        vector Pos = <X, Y, 23>;
        llOwnerSay(Name + " at " + (string)Pos);
        MoveTo(Pos);
        llRezObject(Name, Pos, ZERO_VECTOR, ZERO_ROTATION, 1);
        Ptr++;
        if (Ptr == Count) {
            MoveTo(HOME);
            integer I;
            for (I = 0; I < Count; I++) {
                Name = llGetInventoryName(INVENTORY_OBJECT, 0);
                llRemoveInventory(Name);
            }            
            llOwnerSay("Done!");
            return;
        }
        X += GAP;
        if (X > 256 - MARGIN) {
            X = MARGIN;
            Y += GAP;
        }
        llSetTimerEvent(DELAY);
    }
}