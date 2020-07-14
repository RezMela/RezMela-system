// Error handler v1.0

// DEEPSEMAPHORE CONFIDENTIAL
// __
//
//  [2018] - [2028] DEEPSEMAPHORE LLC
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of DEEPSEMAPHORE LLC and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to DEEPSEMAPHORE LLC
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from DEEPSEMAPHORE LLC. For more information, or requests for code inspection,
// or modification, contact support@rezmela.com

integer ERROR_CHANNEL = -7563234;

integer ERR_SET_USER = -188137420;
integer ERR_SET_EMAIL = -188137421;

key AvId;
key RootId;
string Email;

key LastId;
string LastText;

ProcessError(key Id, string Text) {
    if (Id == LastId && Text == LastText) return;
    key OwnerId = llGetOwner();
    LastId = Id;
    LastText = Text;
    key TargetUser = AvId;
    if (AvId == NULL_KEY) TargetUser = OwnerId;
    llDialog(TargetUser, "\nERROR\n\n" + Text + "\n", [ "OK" ], -17260776);
    string EmailText = Text + "\n\n";
    EmailText += EmailLine("Time", llGetTimestamp());
    EmailText += EmailLine("User", NameAndId(TargetUser));
    EmailText += EmailLine("Object", NameAndId(RootId));
    if (Id != RootId) { // It's a child prim
        EmailText += EmailLine("Prim", NameAndId(Id));
    }
    EmailText += EmailLine("Owner", NameAndId(OwnerId));
    EmailText += EmailLine("Region", llGetRegionName());
    EmailText += EmailLine("Grid", osGetGridName());
    EmailText += EmailLine("Pos", NiceVector(llList2Vector(llGetObjectDetails(RootId, [ OBJECT_POS ]) , 0)));
    list Emails = llCSV2List(Email);
    integer EmailsCount = llGetListLength(Emails);
    integer E;
    for (E = 0; E < EmailsCount; E++) {
        string Address = llList2String(Emails, E);
        llEmail(Address, "ERR: " + Text, EmailText);
    }
    llSetTimerEvent(3.0);
}
string EmailLine(string Name, string Value) {
    return Name + ": " + Value + "\n";
}
string NameAndId(key Id) {
    return llKey2Name(Id) + " [" + (string)Id + "]";    
}
integer SameObject(key Id) {
    if (Id == RootId) return TRUE;
    return (GetRootKey(Id) == RootId);
}
key GetRootKey(key Id) {
    return llList2Key(llGetObjectDetails(Id, [ OBJECT_ROOT ]), 0);    
}
string NiceVector(vector V) {
    return ("<" + NiceFloat(V.x) + "," + NiceFloat(V.y) + "," + NiceFloat(V.z) + ">") ;
}
// Makes a nice string from a float - eg "0.1" instead of "0.100000", or "0.2" instead of "0.199999".
string NiceFloat(float F) {
    float X = 0.0001;
    if (F < 0.0) X = -X;
    string S = (string)(F + X);
    integer P = llSubStringIndex(S, ".");
    S = llGetSubString(S, 0, P + 3);
    while (llGetSubString(S, -1, -1) == "0" && llGetSubString(S, -2, -2) != ".")
        S = llGetSubString(S, 0, -2);
    return(S);
}
default {
    on_rez(integer Param) { llResetScript(); }
    state_entry() {
        LastId = NULL_KEY;
        LastText = "";
        RootId = llGetKey();
        AvId = NULL_KEY;
        llListen(ERROR_CHANNEL, "", NULL_KEY, "");
    }
    listen(integer Channel, string Name, key Id, string Text) {
        if (SameObject(Id)) {
            ProcessError(Id, Text);
        }
    }
    link_message(integer Sender, integer Number, string Text, key Id) {
        if (Number == ERR_SET_USER) {
            AvId = Id;
        }
        else if (Number == ERR_SET_EMAIL) {
            Email = Text;
        }
        else if (Number == ERROR_CHANNEL) {
            ProcessError(llGetLinkKey(Sender), Text);
        }
    }
    timer() {
        llSetTimerEvent(0.0);
        LastId = NULL_KEY;
        LastText = "";
    }
}

// Error handler v1.0