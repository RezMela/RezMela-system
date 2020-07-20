// ML projector v0.1

integer LM_LOADING_COMPLETE = -405530;			// The ML tells us that it has finished loading and can receive commands
integer LM_EXTRA_DATA_SET = -405516;			// Send our data to the ML for storage
integer LM_EXTRA_DATA_GET = -405517;			// Retrieve our data from the ML
integer LM_RESERVED_TOUCH_FACE = -44088510;		// Reserved Touch Faces - which face(s) we want to process clicks on, for example to call a menu

integer DataRequested;	// (Boolean) Have we requested our data from the ML yet?
integer DataReceived;	// (Boolean) Have we received our data from the ML yet?

integer RESERVED_FACE = 3;

integer Mode = 0;
integer MODE_NONE = 0;
	integer MODE_IMAGE = 1;
	integer MODE_

// This is just an example of how we might want to process data received
ProcessData() {
	llSetText(OurData + "\n\nClick blue surface to reset the time", <1.0, 1.0, 0.0>, 1.0);	// Display our data as floating text
}

default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		OurData = "";
		ProcessData();
		DataRequested = DataReceived = FALSE;	// We haven't requested or received any data yet
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_LOADING_COMPLETE) {
			//
			// The ML has finished loading, and can now send and receive commands and data.
			//
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, (string)RESERVED_FACE, NULL_KEY);
			// When loading a large scene from a save file, there can be hundreds of linked messages being sent between scripts like this
			// and the ML, in both directions. Sometimes these messages don't get through (probably the event queues being filled), so just
			// in case, after a delay we ask again if we've still not received our data. There is a random element to the delay so our
			// siblings are not all asking at the same time.
			llSetTimerEvent(12.0 + llFrand(6.0));
		}
		else if (Number == LM_EXTRA_DATA_GET) {
			// This is in response to the LM_EXTRA_DATA_GET that we sent in the timer event. The ML sends us our saved data (if any) in
			// the String portion. Even if there is no data stored, we'll still get this event.
			llSetTimerEvent(0.0);	// remove this if we're using the timer for other things too
			DataReceived = TRUE;	// we don't really need this because we can have stopped the timer, but it's here in case we use the timer for something else later
			// Our data is in String
			OurData = String;
			ProcessData();
		}
		else if (Number == LM_RESERVED_TOUCH_FACE) {
			// The ML is telling us that someone clicked our reserved face. The string portion of the message contains a pipe-delimited
			// list of the following data: face, position, normal, binormal, ST, UV
			key TouchAvId = Id;	// the UUID of the user who did the clicking
			list TouchData = llParseStringKeepNulls(String, [ "|" ], []);	// Parse the data into a list of the four different parts
			integer TouchFace = (integer)llList2String(TouchData, 0);
			vector TouchPos = (vector)llList2String(TouchData, 1);
			vector TouchNormal = (vector)llList2String(TouchData, 2);
			vector TouchBinormal = (vector)llList2String(TouchData, 3);
			vector TouchST = (vector)llList2String(TouchData, 4);
			vector TouchUV = (vector)llList2String(TouchData, 5);
			llDialog(TouchAvId, "You clicked a reserved face:\n" + String, [ "OK"], -99342001 );		// channel is just a random garbage channel
			// And, to illustrate the storage of data, we'll save the time that the face was clicked
			OurData = llGetTimestamp();
			ProcessData();
			// We can now store the new data in the ML, so that it will be retrieved by LM_EXTRA_DATA_GET if the scene is saved and reloaded later
			// (remember that we'll be a different instance of the script then, and so we won't have that stored data here).
			// BEWARE! Don't allow the pipe symbol ("|") to be stored in the data. That will mess up save files, and the ML doesn't do any
			// data sanitation on this.
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_SET, OurData, NULL_KEY);
		}
	}
	timer() {
		if (!DataReceived) {
			llMessageLinked(LINK_ROOT, LM_EXTRA_DATA_GET, (string)RESERVED_FACE, NULL_KEY);
		}
	}
}
// ML projector v0.1