
// Weapon secondary
//
// Coding that's enduring, not suited to the state-changing design of the main weapon script.
// A kind of service provider for that script.
//
// 1. Detect when we've been hit (chat message from the bullet that hit our NPC) and inform main script to disable the weapon/AI via LM
// 2. On request from the main script, find nearest non-dead NPC of the correct faction
// 3. Communicates with the game server
//
// Constants

float SERVER_WAIT_TIME = 3.0;		// time to wait for a ping from an existing server before rezzing a new one (see also ping time in server script)

// Unique chat/LM channels
integer CHAT_CHANNEL = 29904047;		// chat channel for death notices, etc
integer STOP_PROCESSING = 810332400; 	// LM command to main script to halt all processing (when we're dead)
integer NEAREST_TARGET = 810332401;		// LM command for query and return of nearest NPC (negative for incoming request, positive for outgoing data)
integer SCRIPT_READY = 810332402;		// LM message to say that seconday script is ready

key NpcId;			// the UUID of our owner - that is, normally the NPC that's holding us
string  sNpcId;		// string version of the same
string Enemy;		// which faction do we target?
key ServerId;		// UUID of the server
key RezzerId;		// UUID of the rezzer that created our NPC
vector MyPos;		// location within region
string DeadList;	// See server code for description
string AnimationName;	// the name of the animation that will be triggered when we die
key GunSoundId;		// the UUID of the gunshot - passed to main script for triggering
key ShoutSoundId;	// the UUID of the noise our NPC will make when killed
string DyingAnimation;	// the name of the animation in inventory that will be played when our NPC is killed

// ValidTarget() - returns TRUE if the NPC is a valid target for us
integer ValidTarget(key Id) {
	if (IsNpcAlive(Id) && Enemy != "") {	// if the NPC is not in the deadlist, and we know who the enemy is
		string Name = llKey2Name(Id);
		string Forename = llGetSubString(Name, 0, llSubStringIndex(Name, " ") -1);	// extract potential target's forename
		if (Enemy == Forename) return TRUE;		// they're the enemy
	}
	return FALSE;	// they're not the enemy
}
// IsNpcAlive() - returns true if NPC is not in dead list
integer IsNpcAlive(key Id) {
	return (llSubStringIndex(DeadList, llGetSubString((string)Id, 0, 4)) == -1);
}
// BroadcastDeath - announce our death to the world
BroadcastDeath() {
	llRegionSay(CHAT_CHANNEL, "D" + sNpcId);						// broadcast dead NPC's UUID, picked up by other instances of this script
	llMessageLinked(LINK_THIS, STOP_PROCESSING, "", NULL_KEY);		// also inform the main script
}
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		NpcId = llGetOwner();	// get avatar UUID - if attached, the weapon must be
		sNpcId = (string)NpcId;
		AnimationName = llGetInventoryName(INVENTORY_ANIMATION, 0);		// the falling/dead animation, which we trigger in the NPC when killed
		ServerId = NULL_KEY;
		RezzerId = NULL_KEY;
		// Identify sounds in inventory.
		// The sound containing the string "gun" (case insensitive) is used for the gunshot; the other is used for *this* NPC's death cry (not target's)
		// We store the UUIDs rather than the names because it's cheaper.
		integer I = llGetInventoryNumber(INVENTORY_SOUND);
		while(I--) {
			string SoundName = llGetInventoryName(INVENTORY_SOUND, I);
			if (llSubStringIndex(llToUpper(SoundName), "GUN") > -1)		//
				GunSoundId = llGetInventoryKey(SoundName);		
			else
				ShoutSoundId = llGetInventoryKey(SoundName);
		}
		llTriggerSound(ShoutSoundId, 0.001);	// cache death-shout sound
		// Find dying animation
		I = llGetInventoryNumber(INVENTORY_ANIMATION);
		I = llFloor(llFrand((float)I));		// random integer 0 to I-1
		AnimationName = llGetInventoryName(INVENTORY_ANIMATION, I);
		if (osIsNpc(NpcId)) state GetData;
		// If the weapon's owned by a non-NPC, it'll stay idle in this state
	}
}
// GetData - communicate with rezzer to get enemy faction, and server to get dead list
state GetData {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llListen(CHAT_CHANNEL, "", NULL_KEY, "");
		llSetTimerEvent(0.5 + llFrand(2.0));		// start random timer for broadcast of "R" signal (random to avoid sudden heavy load), also give time for rezzer to initialise
	}
	timer() {
		llRegionSay(CHAT_CHANNEL, "R" + sNpcId);		// accounce our NPC's UUID (rezzer picks this up and replies with faction name, server replies with deadlist)
	}
	listen(integer Channel, string Name, key Id, string Message) {
		string MessageType = llGetSubString(Message, 0, 0);		// first character is type of message
		if (MessageType == "F") {		// it's our rezzer telling us which faction we target (F + faction name)
			RezzerId = Id;
			Enemy = llGetSubString(Message, 1, -1);
		}
		else if (MessageType == "L") {	// from the server, with deadlist data
			ServerId = Id;		// save its UUID and continue
			DeadList = llGetSubString(Message, 1, -1);
		}
		if (Enemy != "" && DeadList != "") {		// if we've got all the data we expect
			llSetTimerEvent(0.0);
			state Normal;		// go to normal processing
		}
	}
}
state Normal {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llSetTimerEvent(0.0);
		llListen(CHAT_CHANNEL, "", NULL_KEY, "");
		llMessageLinked(LINK_THIS, SCRIPT_READY, (string)GunSoundId, RezzerId);		// announce to main script that we're ready now
	}
	listen(integer Channel, string Name, key Id, string Message) {
		string MessageType = llGetSubString(Message, 0, 0);		// first character is type of message
		if (MessageType == "D") {		// it's a death announcement from a bullet
			string DeceasedId = llGetSubString(Message, 1, 36);
			if (DeceasedId == sNpcId) {	// we've been hit
				// send another "D" message just in case the server didn't get the one from the bullet
				BroadcastDeath();
				state Dead;
			}
			else {			// it's some other fellow - record their death
				if (IsNpcAlive(Id)) {	// if we've not already recorded them
					DeadList += llGetSubString(Message, 1, 5) + "|";	// add their partial UUID to the list
				}
			}
		}
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == -NEAREST_TARGET && Enemy != "") {		// request from main script for nearest target, so if we know who the enemy is ...
			llSensor("", NULL_KEY, OS_NPC, 512.0, PI);		// ... look for them
		}
	}
	sensor(integer Count) {
		vector MyPos = llGetPos();
		float NearestDistance = 100000.0;	// arbitrary high value
		key NearestId = NULL_KEY;
		vector NearestPos = ZERO_VECTOR;
		while(Count--) {
			key Id = llDetectedKey(Count);	// NPC's UUID
			if (ValidTarget(Id)) {
				vector Pos = llDetectedPos(Count);	// get other NPC's position
				float ThisDistance = llVecDist(MyPos, Pos);
				if (ThisDistance < NearestDistance) {	// nearest one so far
					NearestId = Id ;	// save data
					NearestPos = Pos;
					NearestDistance = ThisDistance;
				}
			}
		}
		// Send data to main script
		// We send a message even if there's nothing out there, so the main script at least gets a response
		llMessageLinked(LINK_THIS, NEAREST_TARGET, (string)NearestPos, NearestId);
	}
	no_sensor() {
		llMessageLinked(LINK_THIS, NEAREST_TARGET, "", NULL_KEY);		// null key means there's nothing out there
	}
}
// Inactive state
state Dead {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		llTriggerSound(ShoutSoundId, 1.0);
		osNpcStopMoveToTarget(NpcId);
		osNpcPlayAnimation(NpcId, AnimationName);		
		// NPCs have a tendency to keep moving - we try to stop the sliding-corpse syndrome here
		// The main script will also be trying to stop the NPC, but we can help out.
		MyPos = llGetPos();		// our position
		llSetTimerEvent(2.0);
	}
	timer() {
		// timer is used to detect if the NPC is still moving, and attempt to stop it if it is
		if (llVecDist(MyPos, llGetPos()) > 0.5) {	// the NPC is still moving
			osNpcStopMoveToTarget(NpcId);
			MyPos = llGetPos();
		}
		else {
			llSetTimerEvent(0.0);		// The corpse is stationary. Our work here is done.
		}
	}
}
// Weapon secondary