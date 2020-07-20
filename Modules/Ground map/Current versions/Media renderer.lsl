// Media renderer v0.1

integer MED_DISPLAY = -44184800;

default
{
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
	}
	link_message(integer Sender, integer Number, string Message, key Id) {
		if (Number == MED_DISPLAY) {
			if (Message == "") {
			}
			list Parts = llParseStringKeepNulls(Message, [ "|" ], []);
			
		}
	}
}
// Media renderer v0.1