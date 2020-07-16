// C card editor v1.3

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

// v1.3 - fix rotations for 90° issue, add output menu
// v1.2 - add more fields

vector VEC_NAN = <-99.0,99.0,-99.0>;    // nonsense value to indicate "not a number" for vectors (must be consistent across scripts)
integer LIM_GENERATE = -17291001;

// Card data
string ObjectName;
string CardName;
string ShortDesc;
string LongDesc;
key ThumbnailId;
key PreviewId;
vector OffsetPos;
vector OffsetRot;
list StickPoints;
vector CameraPos;
vector CameraFocus;
vector JumpPos;
vector JumpLookAt;
string SnapGrid;
string RegionSnap;
integer IgnoreRotation;
integer IgnoreBinormal;
float SizeFactor;

integer CardExists;

rotation InitialRot;
key AvId;

integer MenuChannel;
integer MenuListener;
integer CurrentMenu;
integer MENU_MAIN = 1;
integer MENU_SHORTDESC = 2;
integer MENU_LONGDESC = 3;
integer MENU_THUMBNAIL = 4;
integer MENU_PREVIEW = 5;
integer MENU_TEXTURE_INV = 6;
integer MENU_ALERT = 7;
integer MENU_CONTACT_POINT = 8;
integer MENU_OUTPUT = 9;
integer MENU_STICKPOINT = 10;
integer MENU_CAMERA = 11;
integer MENU_JUMP = 12;
integer MENU_SNAPGRID = 13;
integer MENU_REGIONSNAP = 14;
integer MENU_ANGLES = 15;
integer MENU_SIZE_FACTOR = 16;

// Main menu
string BUT_OUTPUT = "OUTPUT >>";
string BUT_SHORTDESC = "Short desc";
string BUT_LONGDESC = "Long desc";
string BUT_CONTACT_POINT = "Contact pt";
string BUT_THUMBNAIL = "Thumbnail";
string BUT_PREVIEW = "Preview";
string BUT_STICKPOINT = "StickPoint";
string BUT_CAMERA = "Camera";
string BUT_JUMP = "Jump";
string BUT_SNAPGRID = "Snap to grid";
string BUT_REGIONSNAP = "Region snap";
string BUT_ANGLES = "Angles";
string BUT_SIZE_FACTOR = "Size factor";
// Output
string BUT_GENERATE = "Make card";
string BUT_PRINT = "Data in chat";
string BUT_DELETE = "Delete script";
// Generics
string BUT_OK = "OK";
string BUT_CANCEL = "Cancel";
string BUT_CLEAR = "Clear";
string BUT_CLOSE = "Close";
string BUT_DONE = "Done";
string BUT_BACK = "< Back";
// Angles menu
string BUT_IGNORE_ROTATION = "Ignore rot.";
string BUT_IGNORE_BINORMAL = "Ignore bin.";

string AlertText;
integer AlertMenu;

string WaitingForTextureDrop;
integer TouchMode;
integer TOUCHMODE_NORMAL = 0;
integer TOUCHMODE_CONTACT_POINT = 1;
integer TOUCHMODE_STICKPOINT = 2;

Generate(integer WriteCard) {
	string sThumbnailId = (string)ThumbnailId;
	if (ThumbnailId == NULL_KEY) sThumbnailId = "";
	string sPreviewId = (string)PreviewId;
	if (PreviewId == NULL_KEY) sPreviewId = "";
	if (WriteCard) {
		if (LongDesc == "") LongDesc = ShortDesc;
		if (PreviewId == NULL_KEY) PreviewId = ThumbnailId;
		if (OffsetPos == VEC_NAN) OffsetPos = ZERO_VECTOR;
		if (OffsetRot == VEC_NAN) OffsetRot = ZERO_VECTOR;
	}
	list Data = [];
	if (WriteCard) Data += "// Configuration for " + ObjectName + " by " + llKey2Name(AvId);
	if (WriteCard || ShortDesc != "") Data += "ShortDesc = \"" + ShortDesc + "\"";
	if (WriteCard || LongDesc != "") Data += "LongDesc = \"" + LongDesc + "\"";
	if (WriteCard || sThumbnailId != "") Data += "Thumbnail = " + sThumbnailId;
	if (WriteCard || sPreviewId != "") Data += "Preview = " + sPreviewId;
	if (WriteCard || OffsetPos != VEC_NAN) Data += "OffsetPos = " + NiceVector(OffsetPos);
	if (OffsetRot != VEC_NAN) Data += "OffsetRot = " + NiceVector(OffsetRot);
	if (StickPoints != []) {
		integer Len = llGetListLength(StickPoints);
		integer S;
		for (S = 0; S < Len; S++) {
			string StickPoint = llList2String(StickPoints, S);
			Data += "StickPoint = " + StickPoint;
		}
	}
	if (CameraPos != VEC_NAN) {
		Data += [
			"CameraPos = " + NiceVector(CameraPos),
			"CameraFocus = " + NiceVector(CameraFocus)
				];
	}
	if (JumpPos != VEC_NAN) {
		Data += [
			"JumpPos = " + NiceVector(JumpPos),
			"JumpLookAt = " + NiceVector(JumpLookAt)
				];
	}
	if (SizeFactor > 0.0 && SizeFactor != 1.0) {
		Data += "SizeFactor = " + NiceFloat(SizeFactor);
	}
	if (SnapGrid != "") {
		Data += "Grid = " + SnapGrid;
	}
	if (RegionSnap != "") {
		Data += "RegionSnap = " + RegionSnap;
	}
	if (IgnoreRotation) {
		Data += "IgnoreRotation = True";
	}
	if (IgnoreBinormal) {
		Data += "IgnoreBinormal = True";
	}
	if (WriteCard) {
		osMakeNotecard(CardName, Data);
		llGiveInventory(AvId, CardName);
		llRemoveInventory(CardName);
	}
	else {
		llRegionSayTo(AvId, 0, "Data:\n" + llDumpList2String(Data, "\n"));
	}
}

ShowMenu() {
	EndMenu();
	integer IsTextBox = FALSE;
	list Buttons = [];
	string Text = "\n\n\t\tREZMELA OBJECT CONFIG CARD EDITOR\n\n";
	if (CurrentMenu == MENU_MAIN) {
		Text += "Select data to change.\n\n\t! = missing (mandatory)\n\t* = missing (optional)";
		Buttons += ButtonText(BUT_SHORTDESC, (ShortDesc == ""), TRUE);
		Buttons += ButtonText(BUT_LONGDESC, (LongDesc == ""), FALSE);
		Buttons += ButtonText(BUT_CONTACT_POINT, (OffsetPos == VEC_NAN), TRUE);
		Buttons += ButtonText(BUT_THUMBNAIL, (ThumbnailId == NULL_KEY), TRUE);
		Buttons += ButtonText(BUT_PREVIEW, (PreviewId == NULL_KEY), FALSE);
		Buttons += ButtonText(BUT_STICKPOINT, (StickPoints == []), FALSE);
		Buttons += ButtonText(BUT_CAMERA, (CameraPos == VEC_NAN), FALSE);
		Buttons += ButtonText(BUT_JUMP, (JumpPos == VEC_NAN), FALSE);
		Buttons += ButtonText(BUT_SNAPGRID, (SnapGrid == ""), FALSE);
		Buttons += ButtonText(BUT_ANGLES, FALSE, FALSE);
		Buttons += ButtonText(BUT_SIZE_FACTOR, (SizeFactor == 0.0), FALSE);
		//Buttons += ButtonText(BUT_REGIONSNAP, (RegionSnap == ""), FALSE);
		Buttons += BUT_OUTPUT;
	}
	else if (CurrentMenu == MENU_ALERT) {
		Text += AlertText;
		Buttons = [ BUT_OK ];
	}
	else if (CurrentMenu == MENU_SHORTDESC) {
		IsTextBox = TRUE;
		Text += "Enter short description, which will be seen in the list of objects.";
	}
	else if (CurrentMenu == MENU_LONGDESC) {
		IsTextBox = TRUE;
		Text += "Enter long description, which will be seen in the preview window.";
	}
	else if (CurrentMenu == MENU_CONTACT_POINT) {
		Text += "Position/rotate object if necessary and click on contact point.";
		Buttons = [ BUT_CANCEL ];
		TouchMode = TOUCHMODE_CONTACT_POINT;
	}
	else if (CurrentMenu == MENU_THUMBNAIL) {
		if (TexturesExist()) return;
		key Id = TextureInInventory();
		if (Id == NULL_KEY) {
			Text += "Drop thumbnail texture into object contents.\n\n" +
				"Thumbnail textures are seen alongside the short description in the objects list.";
			Buttons = [ BUT_CANCEL ];
			WaitingForTextureDrop = BUT_THUMBNAIL;
		}
		else {
			ThumbnailId = Id;
		}
	}
	else if (CurrentMenu == MENU_PREVIEW) {
		if (TexturesExist()) return;
		key Id = TextureInInventory();
		if (Id == NULL_KEY) {
			Text += "Drop preview texture into object contents.\n\n" +
				"Preview textures are seen when the object is selected for creation. If none is " +
				"specified, the thumbnail texture is used instead.";
			Buttons = [ BUT_CANCEL ];
			WaitingForTextureDrop = BUT_THUMBNAIL;
		}
		else {
			ThumbnailId = Id;
		}
	}
	else if (CurrentMenu == MENU_TEXTURE_INV) {
		integer Count = llGetInventoryNumber(INVENTORY_TEXTURE);
		Text += "Found " + (string)Count + " texture(s) in object contents. These might interfere with " +
			"texture identification.\n\nRemove them?";
		Buttons = [ BUT_OK, BUT_CANCEL ];
	}
	else if (CurrentMenu == MENU_STICKPOINT) {
		Text += "StickPoints are places on the object where other objects will attach precisely. You can " +
			"have any number of Stickpoints.\n\nClick object to set each StickPoint, or '" + BUT_CLEAR + "' " +
			"to clear all StickPoints.\n\nWhen you're finished, click '" + BUT_CLOSE + "'.\n\n    StickPoints: " +
			(string)llGetListLength(StickPoints);

		Buttons = [ BUT_CLEAR, BUT_CLOSE ];
	}
	else if (CurrentMenu == MENU_CAMERA) {
		Text += "You can set the camera position for the HUD's \"zoom\" mode. Position your camera to " +
			"look at the object, and click " + BUT_OK + ".";
		Buttons = [ BUT_OK, BUT_CANCEL ];
	}
	else if (CurrentMenu == MENU_OUTPUT) {
		Text += "Click '" + BUT_GENERATE + "' to generate the C card and pass it to you, '" +
			BUT_PRINT + "' to print the data in chat, '" + BUT_DELETE + "' to delete this script, or '" +
			BUT_CLOSE + "' to close the menu so you can return later.";
		Buttons = [ BUT_GENERATE, BUT_PRINT, BUT_DELETE, BUT_CLOSE ];
	}
	else if (CurrentMenu == MENU_JUMP) {
		Text += "You can set the jump position, which is where the avatar will be teleported when they use " +
			"the HUD's \"jump\" mode.\n\nThis position is relative to the object.\n\n" +
			"Stand in the place where you would like the jump position to be, and click '" + BUT_OK + "' to " +
			"set the position.";
		Buttons = [ BUT_OK, BUT_CANCEL ];
	}
	else if (CurrentMenu == MENU_SNAPGRID) {
		Text += "\"Snap to grid\" specifies a layout on this object, so that other objects will be " +
			"positioned on it in a precise grid.\n\nEnter the number of grid squares for each axis, eg \"32,32\".";
		IsTextBox = TRUE;
	}
	else if (CurrentMenu == MENU_ANGLES) {
		string Rot = "✕"; if (IgnoreRotation) Rot = "✓";
		string Bin = "✕"; if (IgnoreBinormal) Bin = "✓";
		Text += "Options for angles:\n\n" +
			Rot + " Ignore rotation (overall rotation)\n" +
			Bin + " Ignore binormal (rotation against surface)";
		Buttons = [ BUT_BACK, BUT_IGNORE_ROTATION, BUT_IGNORE_BINORMAL ];
	}
	else if (CurrentMenu == MENU_SIZE_FACTOR) {
		Text += "This makes the object larger or smaller than its actual size.\n\n" +
			"Examples:\n" +
			"    0.5: Half actual size\n" +
			"    3: 3x actual size\n" +
			"    1: Normal size";
		IsTextBox = TRUE;
	}
	//	else if (CurrentMenu == MENU_REGIONSNAP) {
	//		Text += "\"Region snap\" allows you to have this object positioned precisely in a region - for example, land " +
	//			"tiles or other regular shapes that need to connect precisely together" etc etc etc
	//	}
	//	// Convert buttons into LSL's own stupid order
	Buttons = llList2List(Buttons, -3, -1) + llList2List(Buttons, -6, -4)
		+ llList2List(Buttons, -9, -7) + llList2List(Buttons, -12, -10);
	MenuListener = llListen(MenuChannel, "", AvId, "");
	if (IsTextBox) {
		Text += "\n\nLeave blank to cancel.\n";
		llTextBox(AvId, Text, MenuChannel);
	}
	else {
		Text += "\n";
		llDialog(AvId, Text, Buttons, MenuChannel);
	}
}
ProcessMenu(string Response) {
	if (CurrentMenu == MENU_MAIN) {
		// Strip off * or ! at front
		if (llGetSubString(Response, 0, 0) == "*" || llGetSubString(Response, 0, 0) == "!") Response = llGetSubString(Response, 1, -1);
		if (Response == BUT_SHORTDESC) {
			CurrentMenu = MENU_SHORTDESC;
		}
		else if (Response == BUT_LONGDESC) {
			CurrentMenu = MENU_LONGDESC;
		}
		else if (Response == BUT_CONTACT_POINT) {
			CurrentMenu = MENU_CONTACT_POINT;
		}
		else if (Response == BUT_THUMBNAIL) {
			CurrentMenu = MENU_THUMBNAIL;
		}
		else if (Response == BUT_PREVIEW) {
			CurrentMenu = MENU_PREVIEW;
		}
		else if (Response == BUT_STICKPOINT) {
			TouchMode = TOUCHMODE_STICKPOINT;
			CurrentMenu = MENU_STICKPOINT;
		}
		else if (Response == BUT_CAMERA) {
			llRequestPermissions(AvId, PERMISSION_TRACK_CAMERA);
			return; // so no menu
		}
		else if (Response == BUT_JUMP) {
			CurrentMenu = MENU_JUMP;
		}
		else if (Response == BUT_SNAPGRID) {
			CurrentMenu = MENU_SNAPGRID;
		}
		else if (Response == BUT_OUTPUT) {
			CurrentMenu = MENU_OUTPUT;
		}
		else if (Response == BUT_ANGLES) {
			CurrentMenu = MENU_ANGLES;
		}
		else if (Response == BUT_SIZE_FACTOR) {
			CurrentMenu = MENU_SIZE_FACTOR;
		}
	}
	else if (CurrentMenu == MENU_ALERT) {
		if (Response == BUT_OK) {
			// Return them to the menu prior to the alert
			CurrentMenu = AlertMenu;
		}
	}
	else if (CurrentMenu == MENU_SHORTDESC) {
		ShortDesc = Response;
		CurrentMenu = MENU_MAIN;
	}
	else if (CurrentMenu == MENU_LONGDESC) {
		LongDesc = Response;
		CurrentMenu = MENU_MAIN;
	}
	else if (CurrentMenu == MENU_CONTACT_POINT) {
		if (Response == BUT_CANCEL) CurrentMenu = MENU_MAIN;
	}
	else if (CurrentMenu == MENU_THUMBNAIL) {
		if (Response == BUT_CANCEL) CurrentMenu = MENU_MAIN;
	}
	else if (CurrentMenu == MENU_PREVIEW) {
		if (Response == BUT_CANCEL) CurrentMenu = MENU_MAIN;
	}
	else if (CurrentMenu == MENU_TEXTURE_INV) {
		if (Response == BUT_OK) {
			RemoveTextures();
			CurrentMenu = MENU_MAIN;
		}
		else if (Response == BUT_CANCEL) {
			return;	// finish wih no menu
		}
	}
	else if (CurrentMenu == MENU_STICKPOINT) {
		if (Response == BUT_CLEAR) {
			StickPoints = [];
		}
		else if (Response == BUT_CLOSE) {
			TouchMode = TOUCHMODE_NORMAL;
			CurrentMenu = MENU_MAIN;
		}
	}
	else if (CurrentMenu == MENU_CAMERA) {
		if (Response == BUT_CANCEL) {
			CameraPos = VEC_NAN;
			CameraFocus = VEC_NAN;
			CurrentMenu = MENU_MAIN;
		}
		else if (Response == BUT_OK) {
			rotation MyRot = llGetRot();
			CameraPos = llGetCameraPos();
			rotation CameraRot = llGetCameraRot();
			CameraPos -= llGetPos();
			CameraFocus = CameraPos + (<5.0, 0.0, 0.0> * CameraRot);
			CameraPos /= MyRot;
			CameraFocus /= MyRot;
			CurrentMenu = MENU_MAIN;
		}
	}
	else if (CurrentMenu == MENU_JUMP) {
		if (Response == BUT_OK) {
			rotation MyRot = llGetRot();
			list Parts = llGetObjectDetails(AvId, [ OBJECT_POS, OBJECT_ROT ]);
			JumpPos = llList2Vector(Parts, 0);
			rotation JumpRot = llList2Rot(Parts, 1);
			JumpPos -= llGetPos();
			JumpLookAt = JumpPos + (<5.0, 0.0, 0.0> * JumpRot);
			JumpPos /= MyRot;
			JumpLookAt /= MyRot;
			CurrentMenu = MENU_MAIN;
		}
		else if (Response == BUT_CANCEL) {
			CurrentMenu = MENU_MAIN;
		}
	}
	else if (CurrentMenu == MENU_SNAPGRID) {
		SnapGrid = Response;
		CurrentMenu = MENU_MAIN;
	}
	else if (CurrentMenu == MENU_ANGLES) {
		if (Response == BUT_BACK) {
			CurrentMenu = MENU_MAIN;
		}
		else if (Response == BUT_IGNORE_ROTATION) {
			IgnoreRotation = !IgnoreRotation;
		}
		else if (Response == BUT_IGNORE_BINORMAL) {
			IgnoreBinormal = !IgnoreBinormal;
		}
	}
	else if (CurrentMenu == MENU_SIZE_FACTOR) {
		if ((float)Response < 0.0) {
			AlertText = "Size Factor cannot be negative.";
			AlertMenu = MENU_SIZE_FACTOR;
			CurrentMenu = MENU_ALERT;
		}
		else {
			SizeFactor = (float)Response;
			CurrentMenu = MENU_MAIN;
		}
	}
	//	else if (CurrentMenu == MENU_REGIONSNAP) {
	//		 RegionSnap = Response;
	//	}
	else if (CurrentMenu == MENU_OUTPUT) {
		if (Response == BUT_GENERATE) {
			EndMenu();
			if (CardExists) llRemoveInventory(CardName);
			// Use link message to work round OpenSim bug: if you delete a notcard and
			// immediately create a new one, the card can revert to its previous state.
			// The solution is to have the delete and write in separate events.
			llMessageLinked(LINK_THIS, LIM_GENERATE, "", NULL_KEY);
		}
		else if (Response == BUT_PRINT) {
			Generate(FALSE);
		}
		else if (Response == BUT_DELETE) {
			string Text = "Script removed from contents.";
			llRegionSayTo(AvId, 0, Text);
			llPassTouches(TRUE);
			llRemoveInventory(llGetScriptName());
			return;
		}
		else if (Response == BUT_CLOSE) {
			EndMenu();
			return;
		}
	}
	ShowMenu();
}
string ButtonText(string Text, integer NullValue, integer Mandatory) {
	if (NullValue) {
		if (Mandatory) {
			Text = "!" + Text;
		}
		else {
			Text = "*" + Text;
		}
	}
	return Text;
}
EndMenu() {
	if (MenuListener > 0) {
		llListenRemove(MenuListener);
		MenuListener = 0;
	}
}
SetContactData(vector Normal, vector TouchPos) {
	//////////////if (Normal == TOUCH_INVALID_VECTOR) return;
	InitialRot = llEuler2Rot(<0.0, 0.0, 270.0> * DEG_TO_RAD);
	rotation VerticalNormal = llEuler2Rot(<0.0, 0.0, -90.0> * DEG_TO_RAD);
	rotation ObjectRot = llGetRot();
	llOwnerSay("final: " + (string)(llRot2Euler(ObjectRot) * RAD_TO_DEG));
	ObjectRot /= VerticalNormal;
	llOwnerSay("o1: " + (string)(llRot2Euler(ObjectRot) * RAD_TO_DEG));
	ObjectRot /= InitialRot;
	llOwnerSay("S: " + (string)(llRot2Euler(ObjectRot) * RAD_TO_DEG));

	//	Normal /= ObjectRot;
	//	TouchPos -= llGetPos();
	//	float Distance  = Normal * llGetRot() * TouchPos;
	//	//rotation Rot = llRotBetween(Normal, <0, 0, -1>);
	//	OffsetPos = Normal * Distance * ObjectRot;
	//	OffsetPos = <llFabs(OffsetPos.x), llFabs(OffsetPos.y), llFabs(OffsetPos.z)>;
	OffsetRot = llRot2Euler(ObjectRot) * RAD_TO_DEG;
}
integer ReadCard() {
	integer IsOK = TRUE;
	list Lines = llParseStringKeepNulls(osGetNotecard(CardName), [ "\n" ], []);
	integer LineCount = llGetListLength(Lines);
	integer I;
	for(I = 0; I < LineCount; I++) {
		string Line = llList2String(Lines, I);
		integer Comment = llSubStringIndex(Line, "//");
		if (Comment != 0) {    // Not a complete comment line
			if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);    // strip from comments characters onwards
			if (llStringTrim(Line, STRING_TRIM) != "") {    // if there's something left after comments are removed
				// Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
				integer Equals = llSubStringIndex(Line, "=");
				if (Equals > -1) {    // so there is a "X = Y" kind of syntax
					string OName = llStringTrim(llGetSubString(Line, 0, Equals - 1), STRING_TRIM);        // original parameter name
					string Name = llToLower(OName);        // lower-case version for case-independent parsing
					string Value = llStringTrim(llGetSubString(Line, Equals + 1, -1), STRING_TRIM);
					// Interpret name/value pairs
					if (Name == "shortdesc") ShortDesc = StripQuotes(Value, Line);
					else if (Name == "longdesc") LongDesc = StripQuotes(Value, Line);
					else if (Name == "preview") PreviewId = (key)Value;
					else if (Name == "thumbnail") ThumbnailId = (key)Value;
					else if (Name == "offsetpos") OffsetPos = (vector)Value;
					else if (Name == "offsetrot") OffsetRot = (vector)Value;
					else if (Name == "stickpoint") StickPoints += Value;
					else if (Name == "camerapos") CameraPos = (vector)Value;
					else if (Name == "camerapfocus") CameraFocus = (vector)Value;
					else if (Name == "jumppos") JumpPos = (vector)Value;
					else if (Name == "jumplookat") JumpLookAt = (vector)Value;
					else if (Name == "grid") SnapGrid = Value;
					else if (Name == "regionsnap") RegionSnap = Value;
					else if (Name == "ignorerotation") IgnoreRotation = String2Bool(Value);
					else if (Name == "ignorebinormal") IgnoreBinormal = String2Bool(Value);
					else if (Name == "sizefactor") SizeFactor = (float)Value;
					else {
						llOwnerSay("Invalid parameter in C card: " + Name);
					}
				}
				else {
					llOwnerSay("Invalid line in existing C card: " + Line);
					IsOK = FALSE;
				}
			}
		}
	}
	CurrentMenu = MENU_MAIN;
	return IsOK;
}
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
	return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
// If textures exist in inventory, it will force the user into the "remove
// textures" dialog and return TRUE.
integer TexturesExist() {
	if (TextureInInventory() != NULL_KEY) {	// if there's a texture in inventory
		CurrentMenu = MENU_TEXTURE_INV;
		ShowMenu();
		return TRUE;
	}
	return FALSE;
}
// Returns UUID of texture in inventory, or null if none
key TextureInInventory() {
	if (llGetInventoryNumber(INVENTORY_TEXTURE) > 0) {
		string Name = llGetInventoryName(INVENTORY_TEXTURE, 0);
		return llGetInventoryKey(Name);
	}
	else { // no texture in inventory
		return NULL_KEY;
	}
}
// Remove all textures from inventory
RemoveTextures() {
	integer Count = llGetInventoryNumber(INVENTORY_TEXTURE);
	while(Count--) {
		llRemoveInventory(llGetInventoryName(INVENTORY_TEXTURE, Count));
	}
}
// Takes a string in double quotes, and strips out the quotes. Validates the format.
// <Text> is the string with quotes; <Line> is the entire line for error reporting
string StripQuotes(string Text, string Line) {
	if (Text == "") {    // allow empty string for null value
		return("");
	}
	if (llGetSubString(Text, 0, 0) == "\"" && llGetSubString(Text, -1, -1) == "\"") {     // if surrounded by quotes
		return(llGetSubString(Text, 1, -2));    // strip quotes
	}
	else {
		llOwnerSay("Invalid string literal (missing \"\"?): " + Line);
		return("");
	}
}
string NiceVector(vector V) {
	return ("<" + NiceFloat(V.x) + ", " + NiceFloat(V.y) + ", " + NiceFloat(V.z) + ">") ;
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
default {
	on_rez(integer Param) { llResetScript(); }
	state_entry() {
		WaitingForTextureDrop = "";
		TouchMode = TOUCHMODE_NORMAL;
		ObjectName = llGetObjectName();
		if (llGetSubString(ObjectName, -1, -1) == "W") ObjectName = llGetSubString(ObjectName, 0, -2);
		CardName = ObjectName + "C";

		llSetObjectDesc("*");

		// Initialise card data
		ThumbnailId = NULL_KEY;
		PreviewId = NULL_KEY;
		OffsetPos = VEC_NAN;
		OffsetRot = VEC_NAN;
		ShortDesc = "";
		LongDesc = "";
		StickPoints = [];
		CameraPos = VEC_NAN;
		CameraFocus = VEC_NAN;
		JumpPos = VEC_NAN;
		JumpLookAt = VEC_NAN;
		SnapGrid = "";
		RegionSnap = "";
		IgnoreRotation = FALSE;
		IgnoreBinormal = FALSE;
		SizeFactor = 0.0;

		CardExists = (llGetInventoryType(CardName) == INVENTORY_NOTECARD);
		if (CardExists) {
			if (!ReadCard()) {
				llSay(0, "The existing 'C' card contains errors.");
			}
		}
		AvId = llGetOwner();
		MenuChannel = -1000 - (integer)llFrand(999999999);
		llOwnerSay("Click for 'C' card editor menu");
		///%%%
			vector xNormal = llDetectedTouchNormal(0);
			vector xTouchPos = llDetectedTouchPos(0);
			SetContactData(xNormal, xTouchPos);
			llOwnerSay("Rot: " + NiceVector(OffsetRot)  + " should be <0.0, 90.0, 0.0> or <180.0, 0.0, 90.0>");
			return;
	}
	touch_start(integer total_number) {
			
		key TouchAvId = llDetectedKey(0);
		if (TouchMode == TOUCHMODE_NORMAL) {
			AvId = TouchAvId;
			CurrentMenu = MENU_MAIN;
			if (TexturesExist()) return;
			ShowMenu();
		}
		else if (TouchMode == TOUCHMODE_CONTACT_POINT && TouchAvId == AvId) {
			vector Normal = llDetectedTouchNormal(0);
			vector TouchPos = llDetectedTouchPos(0);
			SetContactData(Normal, TouchPos);
			TouchMode = TOUCHMODE_NORMAL;
			CurrentMenu = MENU_MAIN;
			ShowMenu();
		}
		else if (TouchMode == TOUCHMODE_STICKPOINT && TouchAvId == AvId) {
			integer Face = llDetectedTouchFace(0);
			vector RegionPos = llDetectedTouchPos(0);
			vector LocalPos = (RegionPos - llGetPos()) / llGetRot();
			StickPoints += (string)Face + ":" + NiceVector(LocalPos);
			ShowMenu();
		}
	}
	listen(integer Channel, string Name, key Id, string Text) {
		if (Channel == MenuChannel && Id == AvId) {
			ProcessMenu(Text);
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_INVENTORY) {
			if (WaitingForTextureDrop != "") {
				key Id = TextureInInventory();
				AlertText = "INVALID TEXTURE DROP!!!";
				if (WaitingForTextureDrop == BUT_THUMBNAIL) {
					AlertText = "Thumbnail texture copied and deleted from contents.";
					ThumbnailId = Id;
				}
				else if (WaitingForTextureDrop == BUT_PREVIEW) {
					AlertText = "Preview texture copied and deleted from contents.";
					PreviewId = Id;
				}
				RemoveTextures();
				WaitingForTextureDrop = "";
				AlertMenu = MENU_MAIN;
				CurrentMenu = MENU_ALERT;
				ShowMenu();
			}
		}
	}
	run_time_permissions(integer Perms) {
		if (Perms & PERMISSION_TRACK_CAMERA) {
			CurrentMenu = MENU_CAMERA;
			ShowMenu();
		}
	}
	link_message(integer Sender, integer Number, string Message, key Id)	{
		if (Number == LIM_GENERATE) {
			Generate(TRUE);
		}
	}
}
// C card editor v1.3