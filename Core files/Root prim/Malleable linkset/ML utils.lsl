// ML utils v1.0.0

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
// More detailed information about the HUD communicator script is available here http://wiki.rezmela.org/doku.php/hud-communicator-script

integer UTIL_WAITING = -181774800;
integer UTIL_GO = -181774801;
integer UTIL_TIMER_SET = -181774802;
integer UTIL_TIMER_CANCEL = -181774803;
integer UTIL_TIMER_RETURN = -181774804;

integer LM_RESET = -405535;

float TIMER_PERIOD = 0.5;

integer MLReady = FALSE;
integer CommunicatorReady = FALSE;
integer CataloguerReady = FALSE;

list Timers = [];
integer TIM_TAG = 0;
integer TIM_DURATION = 1;
integer TIM_REMAINING = 2;
integer TIM_REPEAT = 3;
integer TIM_STRIDE = 4;

integer TimersCount = 0;

Reset() {
	MLReady = FALSE;
	CommunicatorReady = FALSE;
	CataloguerReady = FALSE;
	Timers = [];
	TimersCount = 0;
}
default {
	on_rez(integer Param) {
		// We don't reset the script here, as pretty much all our other scripts do, because we don't want
		// to drop events. It's essential that this script is ready to receive events before it actually
		// gets any, otherwise the whole concept of the coordination is ruined.
		Reset();
	}
	state_entry() {
		Reset();
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		if (Sender == 1) {	// Message from script in root prim
			if (Number == UTIL_WAITING) {
				if (Text == "M") MLReady = TRUE;
				else if (Text == "O") CommunicatorReady = TRUE;
				else if (Text == "A") CataloguerReady = TRUE;
				if (MLReady && CommunicatorReady && CataloguerReady) {
					llMessageLinked(LINK_THIS, UTIL_GO, "", NULL_KEY);
				}
				return;
			}
		}
		// Messages from any prim
		if (Number == UTIL_TIMER_SET) {
			// Format of this command is: <tag>|<duration>|<repeat?>
			list Parts = llParseStringKeepNulls(Text, [ "|" ], []);
			string Tag = llList2String(Parts, 0);
			float Duration = (float)llList2String(Parts, 1);
			integer Repeat = (integer)llList2String(Parts, 2);
			integer P = llListFindList(Timers, [ Tag ]);
			if (P > -1) {
				Timers = llDeleteSubList(Timers, P, P + TIM_STRIDE - 1);
				TimersCount--;
			}
			Timers += [ Tag, Duration, Duration, Repeat ];
			TimersCount++;
			llSetTimerEvent(TIMER_PERIOD);
		}
		else if (Number == UTIL_TIMER_CANCEL) {
			// This command takes only the tag as a parameter
			string Tag = Text;
			integer P = llListFindList(Timers, [ Tag ]);
			if (P > -1) {
				Timers = llDeleteSubList(Timers, P, P + TIM_STRIDE - 1);
				TimersCount--;
			}
			// If the Timers table is now empty, the timer will be stopped in the next timer() event.
		}
		else if (Number == LM_RESET) {
			Reset();
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		integer T;
		for (T = 0; T < TimersCount; T++) {
			integer P = T * TIM_STRIDE;
			float Remaining = llList2Float(Timers, P + TIM_REMAINING);
			Remaining -= TIMER_PERIOD;
			if (Remaining > 0.0) {
				Timers = llListReplaceList(Timers, [ Remaining ], P + TIM_REMAINING, P + TIM_REMAINING);
			}
			else { // timer is due
				string Tag = llList2String(Timers, P + TIM_TAG);
				integer Repeat = llList2Integer(Timers, P + TIM_REPEAT);
				llMessageLinked(LINK_SET, UTIL_TIMER_RETURN, Tag, NULL_KEY);
				if (Repeat) { // timer repeats, so reset remaining time
					float Duration = llList2Float(Timers, P + TIM_DURATION);
					Timers = llListReplaceList(Timers, [ Duration ], P + TIM_REMAINING, P + TIM_REMAINING);
				}
				else { // timer has expired
					Timers = llDeleteSubList(Timers, P, P + TIM_STRIDE - 1);
					TimersCount--;
				}
			}
		}
		if (TimersCount > 0) llSetTimerEvent(TIMER_PERIOD);
	}
}
// ML utils v1.0.0