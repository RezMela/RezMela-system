
// finds and replaces all occurences of strings in all notecards in object, one per line

string OLD_STRING = "RezMela_themed_trees";
//string OLD_STRING = "RezMela_Grasses";
string NEW_STRING = "RezMela_themed_plants";


integer TRIGGER_1 = -123892310;
integer TRIGGER_2 = -123892311;

string filename;
integer filenum;
integer filescount;
list newlines = [];

string strReplace(string str, string search, string replace) {
	return llDumpList2String(llParseStringKeepNulls(str, [search], []), replace);
}
default {
	on_rez(integer p) { llResetScript(); }
	state_entry() {
		filescount = llGetInventoryNumber(INVENTORY_NOTECARD);
		filenum = 0;
		llMessageLinked(LINK_THIS, TRIGGER_1, "", NULL_KEY);
	}
	link_message(integer sender_number, integer number, string message, key id) {
		if (number == TRIGGER_1) {
			filename = llGetInventoryName(INVENTORY_NOTECARD, filenum);
			llOwnerSay("Converting: " + filename);
			string contents = osGetNotecard(filename);
			list lines = llParseStringKeepNulls(contents, [ "\n" ], []);
			newlines = [];
			integer len = llGetListLength(lines);
			integer i;
			for (i = 0; i < len; i++) {
				string line = llList2String(lines, i);
				integer p = llSubStringIndex(line, OLD_STRING);
				if (p > -1) {
					line = strReplace(line, OLD_STRING, NEW_STRING);
				}
				newlines += line;
			}
			llRemoveInventory(filename);
			llSetTimerEvent(0.5);
			llMessageLinked(LINK_THIS, TRIGGER_2, "", NULL_KEY);
		}
		else if (number == TRIGGER_2) {
			osMakeNotecard(filename, newlines);
			llOwnerSay("    written " + (string)llGetListLength(newlines) + " lines to " + filename);
			filenum++;
			if (filenum == filescount) {
				llOwnerSay("Done.");
				llRemoveInventory(llGetScriptName());
				return;
			}
			llMessageLinked(LINK_THIS, TRIGGER_1, "", NULL_KEY);
		}
	}
}