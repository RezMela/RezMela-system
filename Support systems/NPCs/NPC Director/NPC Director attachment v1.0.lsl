// NPC director attachment v1.0

// NOTE: Do not forget to detach and re-attach attachment object before creating NPC notecard when this script has been updated!

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

integer NPC_ATTACHMENT_PIN = -31998740;
integer NPC_CHAT_CHANNEL = -28719011;

integer Listener;

key NpcId; // NPC avatar
key BehaviourObjectId;    // Object that created avatar

string SensorTag = ""; // U=user S=sit

// Send message to NPC server in correct format
SendToBehaviourObject(string Command, list Params) {
    if (BehaviourObjectId == NULL_KEY) return;
    list Message = [ "*NPCB*", Command ] + Params;
    MessageObject(BehaviourObjectId, Message);
}
// Wrapper for osMessageObject
MessageObject(key Destination, list Message) {
    if (Destination == NULL_KEY) { LogError("Null destination in MessageObject"); return; }
    if (ObjectExists(Destination)) {
        osMessageObject(Destination, llDumpList2String(Message, "|"));
    }
}
SetVisible(integer Visible) {
    float Alpha = 0.0;
    if (Visible) Alpha = 1.0;
    llSetAlpha(Alpha, ALL_SIDES);
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
    return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
LogError(string Text) {
    llRegionSay(-7563234, Text);
}
default {
    on_rez(integer Param) { llResetScript(); }
    state_entry() {
        SetVisible(FALSE);
        NpcId = llGetOwner();
        BehaviourObjectId = NULL_KEY;
        llSetText("", ZERO_VECTOR, 0.0);
        if (llGetAttached() == 0) {
            SetVisible(TRUE);
            state Hang;    // don't do anything if not attached
        }
        // removed becasue it does need to be worn by a real avatar for creating NPC notecards
        //        if (!osIsNpc(llGetOwner())) {
        //            state Hang;    // or if worn by a real avatar
        //        }
        llSetRemoteScriptAccessPin(NPC_ATTACHMENT_PIN); // updating doesn't work for NPCs yet, but maybe one day?
        Listener = llListen(NPC_CHAT_CHANNEL, "", NULL_KEY, "");
    }
    listen(integer Channel, string Name, key Id, string Text) {
        if (Channel == NPC_CHAT_CHANNEL) {
            if (Text == "H") { // Hello from behaviour object
                SetVisible(FALSE);
                BehaviourObjectId = Id;
                SendToBehaviourObject("H", [ llGetKey() ]);    // "H" is "hello" back
                llListenRemove(Listener);
            }
        }
    }
    touch_start(integer Count) {
        key AvId = llDetectedKey(0);
        SendToBehaviourObject("T", [ AvId ]);
    }
    dataserver(key SenderId, string Data) {
        if (llGetSubString(Data, 0, 5) == "*NPCB*") { // is it a command from the NPC subsystem?
            // Format of messages is: *NPCB*|<command>|<data>
            list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
            string Command = llList2String(Parts, 1);
            list Params = llList2List(Parts, 2, -1);
            if (Command == "F") { // Floating text from server
                string Text = llList2String(Params, 0);
                vector Color = (vector)llList2String(Params, 1);
                float Alpha = (float)llList2String(Params, 2);
                llSetText(Text, Color, Alpha);
            }
            else if (Command == "SE") { // sensor (single)
                SensorTag = llList2String(Params, 0);
                string Name = llList2String(Params, 1);
                key SensorId = (key)llList2String(Params, 2);
                integer SensorType = (integer)llList2String(Params, 3);
                float Range = (float)llList2String(Params, 4);
                float Arc = (float)llList2String(Params, 5);
                llSensor(Name, SensorId, SensorType, Range, Arc);
            }
            else if (Command == "SR") { // sensor repeat
                SensorTag = llList2String(Params, 0);
                string Name = llList2String(Params, 1);
                key SensorId = (key)llList2String(Params, 2);
                integer SensorType = (integer)llList2String(Params, 3);
                float Range = (float)llList2String(Params, 4);
                float Arc = (float)llList2String(Params, 5);
                float Rate = (float)llList2String(Params, 6);
                llSensorRepeat(Name, SensorId, SensorType, Range, Arc, Rate);
            }
            else if (Command == "SS") { // sensor stop
                llSensorRemove();
                SensorTag = "";
            }
            else if (Command == "TS") { // trigger sound
                string SoundName = llList2String(Params, 0);
                float Volume = (float)llList2String(Params, 1);
                llTriggerSound(SoundName, Volume);
            }
            else if (Command == "D") { // Order to drop and die
                // This is done when creating NPC appearance notecards - the attachment is
                // temporarily attached to the user and then dropped and killed once done
                osForceDropAttachment();
                llDie(); //
            }            
        }
    }
    sensor(integer Count) {
        list Results = [ SensorTag ];
        while(Count--) {
            Results += llDetectedKey(Count);
        }
        SendToBehaviourObject("SE", Results); // "SE" is Sensor rEsults
    }
    no_sensor() {
        SendToBehaviourObject("SE", [ SensorTag ]); // "SE" is Sensor rEsults
    }
    // attach() event only seems to fire on detach. OpenSim is weird.
    //    attach(key Id) {
    //        SetVisible(Id == NULL_KEY); // set to invisible if worn, otherwise visible
    //    }
}
state Hang {
    on_rez(integer Param) { llResetScript(); }
}
// NPC director attachment v1.0
