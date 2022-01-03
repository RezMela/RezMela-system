
// Save file converter - convert save file to use new module format

string CONVERSION_DATA = "!Save file conversion data";

integer TRIGGER_READ = -18723470;
integer TRIGGER_WRITE = -18723471;

list Objects = [];

integer FileNum;
list Filenames;
integer FilesCount;

string WriteName = "";
list WriteData = [];

default {
	state_entry() {
		Objects = llParseStringKeepNulls(osGetNotecard(CONVERSION_DATA), [ "|", "\n" ], []);
		integer OL = llGetListLength(Objects);
		if (OL == 0) return;
		llOwnerSay("\nProcessing " + (string)(OL / 2) + " objects");
		Filenames = [];
		FilesCount = llGetInventoryNumber(INVENTORY_NOTECARD);
		integer N;
		for (N = 0; N < FilesCount; N++) {
			Filenames += llGetInventoryName(INVENTORY_NOTECARD, N);
		}
		FileNum = 0;
		llOwnerSay("\nConverting " + (string)FilesCount + " files ...\n");
		llMessageLinked(LINK_THIS, TRIGGER_READ, "", NULL_KEY);
	}
	link_message(integer sender_number, integer Number, string message, key id) {
		if (Number == TRIGGER_READ) {
			if (FileNum == FilesCount) {
				llOwnerSay("Done");
				llRemoveInventory(CONVERSION_DATA);
				llRemoveInventory(llGetScriptName());
				return;
			}
			integer Errors = FALSE;
			integer Changes = FALSE;
			string SaveFile = llList2String(Filenames, FileNum);
			list NewLines = [];
			if (SaveFile != CONVERSION_DATA) {
				llOwnerSay("Reading " + SaveFile + " ...");
				string NotecardString = osGetNotecard(SaveFile);
				list Lines = llParseStringKeepNulls(NotecardString, [ "\n" ], []);
				integer Len = llGetListLength(Lines);
				integer L;
				for (L = 0; L < Len; L++) {
					string Line = llList2String(Lines, L);
					if (llSubStringIndex(Line, "Name: ") > -1) {
						list Parts = llParseStringKeepNulls(Line, [ ":" ], []);
						string ObjectName = llStringTrim(llList2String(Parts, 1), STRING_TRIM);
						if (llSubStringIndex(ObjectName, ".") == -1) {
							integer P = llListFindList(Objects, [ ObjectName ]);
							if (P == -1) {
								llOwnerSay("Object not in conversion data: " + ObjectName);
								Errors = TRUE;
							}
							else {
								string ModuleId = llList2String(Objects, P + 1);
								string NewName = ModuleId + "." + ObjectName;
								Changes = TRUE;
								NewLines += "    Name: " + NewName;
							}
						}
					}
					else {
						NewLines += Line;
					}
				}
			}
			if (Errors) {
				llOwnerSay("Abandoning conversion");
				return;
			}
			FileNum++;
			if (Changes) {
				WriteName = SaveFile;
				WriteData = NewLines;
				llRemoveInventory(SaveFile);
				llMessageLinked(LINK_THIS, TRIGGER_WRITE, "", NULL_KEY);
			}
			else {
				llMessageLinked(LINK_THIS, TRIGGER_READ, "", NULL_KEY);
			}
		}
		else if (Number == TRIGGER_WRITE) {
			llOwnerSay("Writing " + WriteName + " ...");
			osMakeNotecard(WriteName, WriteData);
			llMessageLinked(LINK_THIS, TRIGGER_READ, "", NULL_KEY);
		}
	}
}