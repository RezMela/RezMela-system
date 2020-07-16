// ML save file converter v0.1

list Notecards;
integer NotecardPtr;

string WriteNotecardName;
list WriteNotecardData;

integer SAVE_FILE_VERSION = 2;		// current version of save file format
string S_VEC_NAN = "<-99.0,99.0,-99.0>";	// string version of nonsense value to indicate "not a number" for vectors

list Convert(string NotecardName) {
	list Ret = [];
	list HeaderData = llCSV2List(osGetNotecardLine(NotecardName, 0));        // get the header info
	integer NextPrimId = (integer)llList2String(HeaderData, 0);		// next sequential prim is
	float DefaultTestMax = (float)llList2String(HeaderData, 1);		// maximum distance for target testing
	integer ThisVersion = (integer)llList2String(HeaderData, 2);

	Ret += llList2CSV([ NextPrimId, NiceFloat(DefaultTestMax), SAVE_FILE_VERSION ]);	// New file header

	integer Lines = osGetNumberOfNotecardLines(NotecardName);
	integer I;
	for(I = 1; I < Lines; I++) {        // we start on line 1 because of header
		string Line = osGetNotecardLine(NotecardName, I);
		if (llStringTrim(Line, STRING_TRIM) != "") {
			list Fields = llParseStringKeepNulls(Line, [ "|" ], []);
			string sPrimId = llList2String(Fields, 0);
			vector PrimPos = (vector)llList2String(Fields, 1);
			rotation PrimRot = (rotation)llList2String(Fields, 2);
			vector PrimSize = (vector)llList2String(Fields, 3);
			string Text = llList2String(Fields, 4);
			string PrimName = llList2String(Fields, 5);
			string TextureData =  llList2String(Fields, 6);	// if non-blank, we have a card texture and its params, or the URL of a web texture
			Ret += llDumpList2String([
				sPrimId, NiceVector(PrimPos), NiceRotation(PrimRot), NiceVector(PrimSize),
				"1.0", S_VEC_NAN, S_VEC_NAN, S_VEC_NAN,
				Text, PrimName, TextureData
					], "|");
		}
	}
	return Ret;
}
string NiceVector(vector V) {
	return ("<" + NiceFloat(V.x) + "," + NiceFloat(V.y) + "," + NiceFloat(V.z) + ">") ;
}
string NiceRotation(rotation R) {
	return ("<" + NiceFloat(R.x) + "," + NiceFloat(R.y) + "," + NiceFloat(R.z) + "," + NiceFloat(R.s) + ">") ;
}
string NiceFloat(float F) {
	float X = 0.0001;
	if (F < 0.0) X = -X;
	string S = (string)(F + X) ;
	integer P = llSubStringIndex(S, ".") ;
	S = llGetSubString(S, 0, P + 3) ;
	while(llGetSubString(S, -1, -1) == "0" && llGetSubString(S, -2, -2) != ".")
		S = llGetSubString(S, 0, -2) ;
	return(S) ;
}
list GetNotecardNames() {
	list Ret = [];
	integer L = llGetInventoryNumber(INVENTORY_NOTECARD);
	integer I;
	for (I = 0; I < L; I++) {
		Ret += llGetInventoryName(INVENTORY_NOTECARD, I);
	}
	return Ret;
}

default {
	state_entry() {
		llOwnerSay("ML save file format conversion to version 2\n");
		Notecards = GetNotecardNames();
		NotecardPtr = 0;
		llSetTimerEvent(0.5);
	}
	timer() {
		llSetTimerEvent(0.0);
		// Do we have one waiting to be written?
		if (WriteNotecardName != "") {
			osMakeNotecard(WriteNotecardName, WriteNotecardData);
			llOwnerSay("Converted " + (string)llGetListLength(WriteNotecardData) + " lines\n");
			WriteNotecardName = "";
			WriteNotecardData = [];
			llSetTimerEvent(0.5);
			return;
		}
		if (NotecardPtr >= llGetListLength(Notecards)) {
			llOwnerSay("Finished - update script removed.");
			llRemoveInventory(llGetScriptName());
			return;
		}
		string NotecardName = llList2String(Notecards, NotecardPtr);
		llOwnerSay("Checking: [" + NotecardName + "]");
		list HeaderData = llCSV2List(osGetNotecardLine(NotecardName, 0));        // get the header info
		if (llGetListLength(HeaderData) > 1) {
			integer ThisVersion = (integer)llList2String(HeaderData, 2);
			if (ThisVersion < SAVE_FILE_VERSION) {
				WriteNotecardName = NotecardName;
				WriteNotecardData = Convert(NotecardName);
				llRemoveInventory(NotecardName);
				// Will be written in next event.
				// Remember, we have to do it in separate events (ie sim frames) because of a bug in OpenSim
				// whereby removing a notecard and writing a new version in the same event causes the notecard
				// to retain its original contents.
			}
			else if (ThisVersion > SAVE_FILE_VERSION) {
				llOwnerSay("File is higher version than me!\n");
			}
			else {
				llOwnerSay("Up to date\n");
			}
		}
		else {
			llOwnerSay("Not a save file\n");
		}
		NotecardPtr++;
		llSetTimerEvent(0.5);
	}
}
// ML save file converter v0.1