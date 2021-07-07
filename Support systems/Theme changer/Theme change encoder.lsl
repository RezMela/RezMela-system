// Theme change encoder v1.0.0

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
integer NOT_A_SIDE = -123210;

float NAN_FLOAT = -918273.0;
vector NAN_VECTOR = <-918273.0, -918273.0, -918273.0>;

// TextureData layout (duplicate of texture changer entries)
integer TEX_OBJECT = 0;
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

integer CardErrorCount;

key AvId;

integer ProcessCard(string CardName) {
	string ThemeName = "";
	string ThemeImage = "";
	list TextureAliases = [];
	integer Invalid = FALSE;
	// Duplicate of texture changer script's data
	list TextureData = [];
	// End duplicate
	integer TDPtr = -1; // point to row number (not element) of TextureData
	string CurrentObject = "";
	integer CurrentSide = NOT_A_SIDE;
	string CurrentTexture = TEXTURE_BLANK;
	list Lines = llParseStringKeepNulls(osGetNotecard(CardName), [ "\n" ], []);
	integer LineCount = llGetListLength(Lines);
	integer LineNumber;
	for(LineNumber = 0; LineNumber < LineCount; LineNumber++) {
		string Line = llStringTrim(llList2String(Lines, LineNumber), STRING_TRIM);
		string LineLower = llToLower(Line);
		integer Comment = llSubStringIndex(Line, "//");
		if (Comment != 0) {    // Not a complete comment line
			if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);    // strip from comments characters onwards
			if (llStringTrim(Line, STRING_TRIM) != "") {    // if there's something left after comments are removed
				if (llGetSubString(LineLower, 0, 5) == "#name ") {
					ThemeName = llStringTrim(llGetSubString(Line, 6, -1), STRING_TRIM);
					if (ThemeName == "") {
						Invalid = CardError(CardName, LineNumber, Line, "Missing name");
					}
				}
				else if (llGetSubString(LineLower, 0, 6) == "#image ") {
					ThemeImage = llStringTrim(llGetSubString(Line, 7, -1), STRING_TRIM);
					if (!osIsUUID(ThemeImage)) {
						Invalid = CardError(CardName, LineNumber, Line, "Invalid UUID");
					}
				}
				else if (llGetSubString(LineLower, 0, 8) == "#texture ") {
					string RHS = llGetSubString(Line, 9, -1); // <name> <value string>
					// If might be tempting to use llParseString2List() to break this line down, but bear in mind the value might
					// itself contain spaces (it might be a CSV with spaces for readability)
					integer P = llSubStringIndex(RHS, " ");
					if (P > -1) {
						string TextureName = llStringTrim(llGetSubString(RHS, 0, P - 1), STRING_TRIM); // part before space
						string TextureValue = llStringTrim(llGetSubString(RHS, P + 1, -1), STRING_TRIM); // part after space
						TextureAliases += [ TextureName, TextureValue ];
						if (TextureName == "") {
							Invalid = CardError(CardName, LineNumber, Line, "Missing name/value");
						}
						else {
							// To save a lot of effort for the user, let's validate the UUID(s) even though we don't use them here
							list Uuids = llCSV2List(TextureValue);
							integer Len = llGetListLength(Uuids);
							integer I;
							for (I = 0; I < Len; I++) {
								string TextureUuid = llList2String(Uuids, I);
								if (!osIsUUID(TextureUuid)) {
									Invalid = CardError(CardName, LineNumber, Line, "Invalid value: " + TextureUuid);
								}
							}
						}
					}
					else {
						Invalid = CardError(CardName, LineNumber, Line, "Malformed #Texture entry");
					}
				}
				else if (llGetSubString(Line, 0, 0) == "[" && llGetSubString(Line, -1, -1) == "]") { // If it's in the format [<object name>]
					CurrentObject = llStringTrim(llGetSubString(Line, 1, -2), STRING_TRIM);
					CurrentSide = NOT_A_SIDE;
				}
				else {
					// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
					list L = llParseStringKeepNulls(Line, [ "=" ], [ ]);    // Separate LHS and RHS of assignment
					if (llGetListLength(L) == 2) {    // so there is a "X = Y" kind of syntax
						string OName = llStringTrim(llList2String(L, 0), STRING_TRIM);        // original parameter name
						string Name = llToLower(OName);        // lower-case version for case-independent parsing
						string Value = llStringTrim(llList2String(L, 1), STRING_TRIM);
						if (CurrentObject == "") {
							Invalid = CardError(CardName, LineNumber, Line, "Data without preceding objectname definition");
						}
						else {
							if (CurrentObject == "") {
								Invalid = CardError(CardName, LineNumber, Line, "Data without specified Object");
							}
							else {
								if (Name == "side") {
									integer ThisSide;
									if (llToLower(Value) == "all") {
										ThisSide = ALL_SIDES;
									}
									else {
										ThisSide = (integer)Value;
										if (ThisSide == 0 && Value != "0") { // casts to 0 but is not actually zero
											Invalid = CardError(CardName, LineNumber, Line, "Invalid Side value");
										}
									}
									if (ThisSide != CurrentSide) {
										TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_DIFFUSE, [ CurrentTexture ]);
										TextureData += DefaultTextureData(CurrentObject, ThisSide, CurrentTexture);
										TDPtr++;
									}
									CurrentSide = ThisSide;
								}
								else if (Name == "texture" || Name == "diffuse") {
									CurrentTexture = ParseTexture(Value, TextureAliases, CardName, LineNumber, Line);
									TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_DIFFUSE, [ CurrentTexture ]);
								}
								else {
									if (CurrentSide == NOT_A_SIDE) {
										Invalid = CardError(CardName, LineNumber, Line, "No side specified");
									}
									if (Name == "texture" || Name == "diffuse") {
										CurrentTexture = ParseTexture(Value, TextureAliases, CardName, LineNumber, Line);
										TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_DIFFUSE, [ CurrentTexture ]);
									}
									else if (Name == "normal") {
										string NormalTexture = ParseTexture(Value, TextureAliases, CardName, LineNumber, Line);
										TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_NORMAL, [ NormalTexture ]);
									}
									else if (Name == "specular") {
										string SpecularTexture = ParseTexture(Value, TextureAliases, CardName, LineNumber, Line);
										TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_SPECULAR, [ SpecularTexture ]);
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
											TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_REPEATS, [ <(float)llList2String(Rep, 0), (float)llList2String(Rep, 1), 0.0> ]);
										}
										else {
											Invalid = CardError(CardName, LineNumber, Line, "Invalid repeats value");
										}
									}
									else if (Name == "offsets") {
										list Rep = llCSV2List(Value);
										if (llGetListLength(Rep) == 2) {
											TextureData = ReplaceTextureEntry(TextureData, TDPtr, TEX_OFFSETS, [ <(float)llList2String(Rep, 0), (float)llList2String(Rep, 1), 0.0> ]);
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
					}
					else {
						Invalid = CardError(CardName, LineNumber, Line, "Invalid line format");
					}
				}
			}
		}
	}
	if (ThemeName == "") {
		llOwnerSay("Missing theme name");
		Invalid = TRUE;
	}
	if (ThemeImage == "") {
		llOwnerSay("Missing theme image");
		Invalid = TRUE;
	}
	if (Invalid) {
		llOwnerSay("Card " + CardName + " ignored!");
	}
	else {
		string CodedTextureData = ThemeName + "\n" + ThemeImage + "\n" + Encode(llDumpList2String(TextureData, "|"));
		string ObjectCardName = GetBasename(CardName) + "." + EXT_OBJECT;
		osMakeNotecard(ObjectCardName, CodedTextureData);
		llOwnerSay("Created encoded card: " + ObjectCardName);
	}
	return (!Invalid);
}
// Report error - returns True to make one-line assignation + report
integer CardError(string CardName, integer LineNumber, string Line, string Message) {
	if (CardErrorCount++ <= 10) { // suppress >10 error messages (they can knock-on and get verbose)
		llOwnerSay("Error:\n" + Line + "\n*** Error on line " + (string)LineNumber + " of " + CardName + ": " + Message);
	}
	return TRUE;
}
integer ProcessCards() {
	CardErrorCount = 0;
	integer N = llGetInventoryNumber(INVENTORY_NOTECARD);
	while(N-- > 0 && CardErrorCount == 0) {
		string CardName = llGetInventoryName(INVENTORY_NOTECARD, N);
		string Extension = GetExtension(CardName);
		if (Extension == EXT_SOURCE) {
			llOwnerSay("Processing source file: " + CardName);
			if (!ProcessCard(CardName)) return FALSE;
		}
	}
	return TRUE;
}
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
// Create default entry for given set number and side
list DefaultTextureData(string ObjectName, integer Side, string Texture) {
	return [
		ObjectName,
		Side,
		Texture, // Diffuse texture
		NULL_KEY, // Normal map
		NULL_KEY, // Specular map
		<1.0, 1.0, 1.0>, // Specular color
		51,				// Specular glossiness
		0,				// Specular environment
		NAN_VECTOR, // Repeats
		NAN_VECTOR,	// Offsets
		NAN_FLOAT,	// Rotation (radians)
		<1.0, 1.0, 1.0>,	// Color
		1.0				// Alpha
			];
}
// Allows textures to be specified by UUID or by #Texture alias
string ParseTexture(string Value, list TextureAliases, string CardName, integer LineNumber, string Line) {
	list Entries = llCSV2List(Value);
	integer Len = llGetListLength(Entries);
	integer E;
	list NewEntries = [];
	for (E = 0; E < Len; E++) {
		string Entry = llStringTrim(llList2String(Entries, E), STRING_TRIM);
		if (osIsUUID(Entry)) {
			NewEntries += Entry;
		}
		else { // if it's not a UUID, maybe it's an alias
			integer P = llListFindList(TextureAliases, [ Entry ]);
			if (P == -1) {
				CardError(CardName, LineNumber, Line, "Invalid texture UUID");
				// Really, we should pass back the Invalid boolean value, but messy to do in LSL and not really worth it
				return "";
			}
			NewEntries += llCSV2List(llList2String(TextureAliases, P + 1)); // Alias might contain multiple texture UUIDs
		}
	}
	return llList2CSV(NewEntries); // return all UUIDs, unwrapped
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
		if (ProcessCards()) {
			llOwnerSay("Finished");
		}
		else {
			llOwnerSay("Aborted");
		}
	}
}
// Theme change encoder v1.0.0