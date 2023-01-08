// NPC behaviour waypoint server v1.0.0

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

string MESSAGE_IDENTIFIER = "*WYPO*";
integer WAYP_CHAT_CHANNEL = -131941965;
float MAX_DELAY = 3.0;

integer WS_REQUEST_LIST = -1751820700;
integer WS_GIVE_LIST = -1751820701;

list Waypoints = [];

// Wrapper for osMessageObject
MessageObject(key Destination, list Message) {
    if (ObjectExists(Destination)) {
        osMessageObject(Destination, llDumpList2String(Message, "|"));
    }
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
    return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
default {
    on_rez(integer Param) { llResetScript(); }
    state_entry() {
    }
    link_message(integer Sender, integer Number, string Text, key Id) {
        if (Number == WS_REQUEST_LIST) {
            Waypoints = [];
            llRegionSay(WAYP_CHAT_CHANNEL, "W");
        }
    }
    dataserver(key Id, string Data) {
        if (llGetSubString(Data, 0, 5) == MESSAGE_IDENTIFIER) {
            string Name = llGetSubString(Data, 6, -1);
            Waypoints += [ Id, Name ];
            llSetTimerEvent(MAX_DELAY);
        }
    }
    timer() {
        llSetTimerEvent(0.0);
        llMessageLinked(LINK_THIS, WS_GIVE_LIST, llDumpList2String(Waypoints, "|"), NULL_KEY);
    }
}

// NPC behaviour waypoint server v1.0.0
