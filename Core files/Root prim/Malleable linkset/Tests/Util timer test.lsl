// Tests timer feature of ML util. Put in child prim, with ML util in root.

integer UTIL_TIMER_SET = -181774802;
integer UTIL_TIMER_CANCEL = -181774803;
integer UTIL_TIMER_RETURN = -181774804;

string ReqTag = "";
float ReqTime = 0.0;
float ReqPeriod = 0.0;
integer Replied;
integer ReqRepeat = FALSE;

list Results = [];

ShowText() {
	if (llGetListLength(Results) > 10) Results = llList2List(Results, -10, -1);
	string Text = "Timer test\n\n";
	integer Len = llGetListLength(Results);
	integer I;
	for (I = 0; I < Len; I++) {
		Text += llList2String(Results, I) + "\n";
	}
	llSetText(Text, <1,0,0>, 1.0);
}

default
{
	state_entry()
	{
		Results = [];
		Replied = TRUE; // force first time
		ReqPeriod = 0.0;
		ShowText();
		ReqTag = "timtest" + (string)llFloor(llFrand(10000.0));
		llSetTimerEvent(60.0);
	}
	timer() {
		if (!Replied) {
			Results += "*** MISSED!";
			ShowText();
		}
		ReqPeriod = 5 + (integer)llFrand(30.0);
		ReqTime = llGetTime();
		ReqRepeat = FALSE;
		Replied = FALSE;
		llMessageLinked(LINK_ROOT, UTIL_TIMER_SET,
			ReqTag + "|" + (string)ReqPeriod + "|" + (string)ReqRepeat,
			NULL_KEY);
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		if (Number == UTIL_TIMER_RETURN && Text == ReqTag) {
			float Elapsed = llGetTime() - ReqTime; // how long this took
			float Diff = Elapsed - ReqPeriod; // how much out it was
			string Entry = (string)llFloor(ReqPeriod) + ": " + llGetSubString((string)Diff, 0, 2);
			Results += Entry;
			Replied = TRUE;
			ShowText();
		}
	}
}