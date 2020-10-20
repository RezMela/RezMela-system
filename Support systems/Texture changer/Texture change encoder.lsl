// Texture change encoder v1.0.0

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

string EXT_SOURCE = "texsrc";
string EXT_OBJECT = "texobj";

string PRIVATE_KEY = "j04&*091]]2cebU7%d_@#X3";

integer TEX_GIVE_MENU = -949183040;

integer NO_SIDE_DATA = -12901873;

// TextureData layout (duplicate of texture changer entries)
integer TEX_SET_PTR = 0;
integer TEX_SIDE = 1;
integer TEX_DIFFUSE = 2;
integer TEX_NORMAL = 3;
integer TEX_SPECULAR = 4;
integer TEX_SPEC_COLOR = 5;
integer TEX_SPEC_GLOSS = 6;
integer TEX_SPEC_ENVIR = 7;
integer TEX_REPEATS = 8;
integer TEX_OFFSETS = 9;
integer TEX_ROTATION = 10;
integer TEX_COLOR = 11;
integer TEX_ALPHA = 12;
integer TEX_STRIDE = 13;

list SourceCards = [];

key AvId;

integer ProcessCard(string CardName) {
	integer Invalid = FALSE;
	// Duplicate of texture changer script's data
	list SetNames = [];
	list TextureData = [];
	// End duplicate
	string SetName = "";
	integer SetPtr = -1;
	integer TDPtr = -1; // point to row number (not element) of TextureData
	integer CurrentSide = NO_SIDE_DATA;
	list Lines = llParseStringKeepNulls(osGetNotecard(CardName), [ "\n" ], []);
	integer LineCount = llGetListLength(Lines);
	integer LineNumber;
	for(LineNumber = 0; LineNumber < LineCount; LineNumber++) {
		string Line = llStringTrim(llList2String(Lines, LineNumber), STRING_TRIM);
		integer Comment = llSubStringIndex(Line, "//");
		if (Comment != 0) {    // Not a complete comment line
			if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);    // strip from comments characters onwards
			if (llStringTrim(Line, STRING_TRIM) != "") {    // if there's something left after comments are removed
				if (llGetSubString(Line, 0, 0) == "[" && llGetSubString(Line, -1, -1) == "]") { // If it's in the format [<setname>]
					SetName = llStringTrim(llGetSubString(Line, 1, -2), STRING_TRIM);
					if (llListFindList(SetNames, [ SetName ]) > -1) {
						llOwnerSay("Duplicate textures entry: " + Line);
						Invalid = TRUE;
					}
					SetNames += SetName;
					SetPtr++;
					CurrentSide = NO_SIDE_DATA;
				}
				else {
					// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
					list L = llParseStringKeepNulls(Line, [ "=" ], [ ]);    // Separate LHS and RHS of assignment
					if (llGetListLength(L) == 2) {    // so there is a "X = Y" kind of syntax
						string OName = llStringTrim(llList2String(L, 0), STRING_TRIM);        // original parameter name
						string Name = llToLower(OName);        // lower-case version for case-independent parsing
						string Value = llStringTrim(llList2String(L, 1), STRING_TRIM);
						if (SetName == "") {
							Invalid = CardError(CardName, LineNumber, Line, "Data without preceding name definition");
						}
						else {
							// Interpret name/value pairs
							if (Name == "side") {
								integer ThisSide;
								if (llToLower(Value) == "all")
									ThisSide = ALL_SIDES;
								else
									ThisSide = (integer)Value;
								if (ThisSide != CurrentSide) {
									TextureData += DefaultTextureData(SetPtr, ThisSide);
									TDPtr++;
								}
								CurrentSide = ThisSide;
							}
							else {
								if (CurrentSide == NO_SIDE_DATA) {
									Invalid = CardError(CardName, LineNumber, Line, "No Side declaration before parameter");
								}
								if (Name == "texture" || Name == "diffuse") {
									TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_DIFFUSE, [ (key)Value ]);
								}
								else if (Name == "normal") {
									TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_NORMAL, [ (key)Value ]);
								}
								else if (Name == "specular") {
									TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_SPECULAR, [ (key)Value ]);
								}
								else if (Name == "speccolor" || Name == "speccolour") {
									vector RGB = (vector)Value / 256.0;
									TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_SPEC_COLOR, [ RGB ]);
								}
								else if (Name == "specglossiness") {
									TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_SPEC_GLOSS, [ (integer)Value ]);
								}
								else if (Name == "specenvironment") {
									TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_SPEC_ENVIR, [ (integer)Value ]);
								}
								else if (Name == "repeats") {
									list Rep = llCSV2List(Value);
									if (llGetListLength(Rep) == 2) {
										TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_REPEATS, [ <(float)llList2String(Rep, 0), (float)llList2String(Rep, 0), 0.0> ]);
									}
									else {
										Invalid = CardError(CardName, LineNumber, Line, "Invalid repeats value");
									}
								}
								else if (Name == "offsets") {
									list Rep = llCSV2List(Value);
									if (llGetListLength(Rep) == 2) {
										TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_OFFSETS, [ <(float)llList2String(Rep, 0), (float)llList2String(Rep, 0), 0.0> ]);
									}
									else {
										Invalid = CardError(CardName, LineNumber, Line, "Invalid offsets value");
									}
								}
								else if (Name == "rotation") {
									float Rot = (float)Value * DEG_TO_RAD;
									TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_ROTATION, [ Rot ]);
								}
								else if (Name == "color" || Name == "colour") {
									vector RGB = (vector)Value / 256.0;
									TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_COLOR, [ RGB ]);
								}
								else if (Name == "alpha") {
									TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_ALPHA, [ (float)Value ]);
								}
								else {
									Invalid = CardError(CardName, LineNumber, Line, "Invalid keyword: '" + OName + "'");
								}
							}
						}
					}
					else {
						Invalid = CardError(CardName, LineNumber, Line, "Invalid line format");
					}
				}
			}
		}
	}
	if (Invalid) {
		llOwnerSay("Card " + CardName + " ignored!");
	}
	else {
		//DebugList(SetNames, TextureData);
		// Make encoded card
		string RawSets = llDumpList2String(SetNames, "|");
		string RawTextureData = llDumpList2String(TextureData, "|");
		string CodedSets = Encode(RawSets);
		string CodedTextureData = Encode(RawTextureData);
		string ObjectCardName = GetBasename(CardName) + "." + EXT_OBJECT;
		osMakeNotecard(ObjectCardName, CodedSets + "^" + CodedTextureData);
		llOwnerSay("Created encoded card: " + ObjectCardName);
	}
	return (!Invalid);
}
// Report error - returns True to make one-line assignation + report
integer CardError(string CardName, integer LineNumber, string Line, string Message) {
	llOwnerSay("Error:\n" + Line + "\n*** Error on line " + (string)LineNumber + " of " + CardName + ": " + Message);
	return TRUE;
}
string GetTextureSourceName() {
	string TextureFileName = "";
	integer N = llGetInventoryNumber(INVENTORY_NOTECARD);
	while(N-- > 0) {
		string CardName = llGetInventoryName(INVENTORY_NOTECARD, N);
		string Extension = GetExtension(CardName);
		if (Extension == EXT_SOURCE) {
			if (TextureFileName == "") {
				TextureFileName = CardName;
			}
			else {
				llOwnerSay("Duplicate texture source file(s) found!");
				return "";
			}
		}
	}
	return TextureFileName;
}
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
// Create default entry for given set number and side
list DefaultTextureData(integer SetPtr, integer Side) {
	return [ SetPtr,
		Side,
		TEXTURE_BLANK, // Diffuse texture
		NULL_KEY, // Normal map
		NULL_KEY, // Specular map
		<1.0, 1.0, 1.0>, // Specular color
		51,				// Specular glossiness
		0,				// Specular environment
		<1.0, 1.0, 0.0>, // Repeats
		ZERO_VECTOR,	// Offsets
		0.0,			// Rotation (radians)
		<1.0, 1.0, 1.0>,	// Color
		1.0				// Alpha
			];
}
list ReplaceTextureEntry(list TextureData, integer TDPtr, integer Offset, list NewValue) {
	Offset = (TDPtr * TEX_STRIDE) + Offset;
	return llListReplaceList(TextureData, NewValue, Offset, Offset);
}
string Encode(string Text) {
	return llXorBase64StringsCorrect(llStringToBase64(Text), llStringToBase64(PRIVATE_KEY));
}
string GetExtension(string CardName) {
	integer P = llSubStringIndex(CardName, ".");
	if (P == -1) return "";
	return llGetSubString(CardName, P + 1, -1);
}
string GetBasename(string CardName) {
	integer P = llSubStringIndex(CardName, ".");
	if (P == -1) return "";
	return llGetSubString(CardName, 0, P - 1);
}
//DebugList(list SetNames, list TextureData) {
//	llOwnerSay("Sets:\n" + llList2CSV(SetNames));
//	string Dump = "Data:\nSet	Side    Diffuse\n";
//	integer C;
//	for (C = 0; C < llGetListLength(TextureData); C += TEX_STRIDE) {
//		integer SetPtr = llList2Integer(TextureData, C + TEX_SET_PTR);
//		integer Side = llList2Integer(TextureData, C + TEX_SIDE);
//		key Uuid = llList2Key(TextureData, C + TEX_DIFFUSE);
//		Dump += llDumpList2String([ SetPtr, Side, Uuid ], "	") + "\n";
//	}
//	llOwnerSay(Dump);
//}
default {
	state_entry() {
	}
	touch_start(integer Count) {
		AvId = llDetectedKey(0);
		SourceCards = [];
		list ObjectCards = [];
		integer CardCount = llGetInventoryNumber(INVENTORY_NOTECARD);
		integer C;
		for (C = 0;  C < CardCount; C++) {
			string CardName = llGetInventoryName(INVENTORY_NOTECARD, C);
			string Extension = GetExtension(CardName);
			string Basename = GetBasename(CardName);
			if (Extension == EXT_OBJECT) ObjectCards += CardName;
			else if (Extension == EXT_SOURCE) SourceCards += CardName;
		}
		if (llGetListLength(ObjectCards) > 0) {
			llOwnerSay("Deleting old object cards: " + llList2CSV(ObjectCards));
			integer P = llGetListLength(ObjectCards);
			while (--P > -1) {
				llRemoveInventory(llList2String(ObjectCards, P));
			}
		}
		llSetTimerEvent(0.5);
	}
	timer() {
		llSetTimerEvent(0.0);
		string CardName = GetTextureSourceName();
		if (CardName != "") {
			llOwnerSay("Processing source file: " + CardName);
			if (ProcessCard(CardName)) {
				llMessageLinked(LINK_THIS, TEX_GIVE_MENU, "", AvId);	// Call texture changer menu
			}
		}
		else {
			llOwnerSay("Processing halted.");
		}
	}
}
// Texture change encoder v1.0.0