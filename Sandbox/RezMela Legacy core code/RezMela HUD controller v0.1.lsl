// RezMelka HUD controller v0.1

string MyVersion;

vector PosOpenConstant = <0.1, -0.02, -0.13>;
vector PosOpenSelected = <0.1, -0.02, -0.43>;
vector PosOpenList = <-0.04, -0.07, -0.28>;
vector PosOpenListBackground = <-0.02, -0.07,-0.28>;
vector PosOpenListPrev = <-0.05, 0.05, -0.05>;
vector PosOpenListNext = <-0.05, 0.0, -0.05>;
vector PosOpenListNavigate = <-0.05, -0.14, -0.05>;
vector PosOpenListClose = <-0.05, -0.204, 0.006>;
vector PosOpenThumbnails = <-0.05, 0.04, -0.1>;

vector SizeOpenRoot = <0.01, 0.16, 0.04>;
vector SizeOpenConstant = <0.025,0.2,0.3>;
vector SizeOpenSelected = <0.025,0.2,0.3>;
vector SizeOpenList = <0.025,0.3,0.6>;
vector SizeOpenListBackground = <0.01, 0.3, 0.6>;
vector SizeOpenListPrevNext = <0.02,0.05,0.025>;
vector SizeOpenListNavigate = <0.02, 0.14, 0.025>;
vector SizeOpenListClose = <0.02, 0.025, 0.025>;
vector SizeOpenThumbnail = <0.02, 0.05, 0.05>;

vector PosClosed = <0.01,0.0,0.0>;
vector SizeClosed = <0.001, 0.001, 0.001>;

integer ThumbnailsCount = 9;
float ThumbnailsGap = 0.056;
integer ListThumbFace = 4;

integer ListFace = 4;
string ListBackColor = "FF845955";
integer ListWidth = 512;
integer ListHeight = 1024;
integer ListTitleVerticalOffset = 20;
integer ListTitleLeftOffset = 40;
string ListTitleFontName = "Helvetica";
string ListTitlePenColor = "White";
integer ListTitleFontSize = 32;
string ListTextFontName = "Helvetica";
string ListTextPenColor = "White";
integer ListTextFontSize = 24;
integer ListTextLeftOffset = 130;
integer ListTextTopMargin = 168;
integer ListTextVerticalGap = 96;
integer ListTextVerticalOffset = 14;

integer HUD_CHAT_GENERAL = -95471602;	// chat channel for general talk in region
integer HUD_CHAT_SPECIFIC = -95471603;	// chat channel for comms from HUD to main object

vector COLOR_WHITE = <1.0, 1.0, 1.0>;
vector COLOR_DISABLED_THUMBNAIL = <0.6, 0.6, 0.6>;

integer ML_EXISTS_CHECK_FREQUENCY = 6;	// how many ticks between checks that ML exists

key MlId;
key RootTextureId;
key OwnerId;
integer Hidden;
integer IsObjectSelected;
integer CheckMlExists;
string HeartbeatString;

// Link numbers
integer LN_Constant;
integer LN_Selected;
integer LN_ListPanel;
integer LN_ListBackground;
integer LN_ListPrev;
integer LN_ListNext;
integer LN_ListNavigate;
integer LN_ListClose;
list LN_Thumbnails;

list CategoriesList;
integer CA_NAME = 0;
integer CA_FROM = 1;
integer CA_TO = 2;
integer CA_STRIDE = 3;
integer CategoriesCount;	// rows, not elements

list ObjectsList;
integer OL_NAME = 0;
integer OL_DESC = 1;
integer OL_TEXTURE = 2;
integer OL_STRIDE = 3;
integer ObjectsCount;	// rows, not elements

// Variables for display of category or object list
integer ListPtr;
integer SavedCategoryPtr;
integer SavedCategoryPagePtr;	// Page position (pointer to first item in current page)
integer SavedObjectPtr;
integer SavedObjectPagePtr;
integer OlReceived;

integer SelectionStatusCurrent;
integer SelectionStatusNew;
integer SS_NOTHING = 0;
integer SS_SELECTED = 1;
integer SS_NOT_SELECTED = 2;

integer ListMode;
integer LMO_OFF = 0;
integer LMO_CATEGORIES = 1;
integer LMO_OBJECTS = 2;

string CatFilterName;
integer CatFilterStart;
integer CatFilterEnd;


integer EnabledThumbnail; 	// which thumbnail prim is currently in a creation cycle (-1 if none)

// LM codes for PDDS (Prim-Drawing Dumb Slave)
integer PDDS_FACE = -190190400;
integer PDDS_WIDTH = -190190401;
integer PDDS_HEIGHT = -190190402;
integer PDDS_DRAW = -190190403;

HandleTouch(integer LinkNum, float TouchX, float TouchY) {
	//llOwnerSay("X == " + (string)TouchX + "   Y == " + (string)TouchY);
	if (LinkNum == LINK_ROOT) {
		Hidden = !Hidden;
		HidePanels();
	}
	else if (LinkNum == LN_Constant) {
		if (TouchY < 0.16) { // create region
			ListPtr = 0;
			if (IsCategorized()) {
				DisplayCategoryList(TRUE);
			}
			else {
				DisplayObjectList(FALSE);
			}
		}
		else if (TouchY >= 0.33 && TouchY < 0.5) {	// delete / rearrange
			if (TouchX < 0.5) {
				MessageMl("deletecard");	//ie delete
			}
			else {
				MessageMl("load");	// ie rearrange
			}
		}
		else if (TouchY >= 0.5 && TouchY < 0.66) {	// save / load
			if (TouchX < 0.5) {
				MessageMl("save");
			}
			else {
				MessageMl("creategroup");	// ie load
			}
		}
		else if (TouchY >= 0.66 && TouchY < 0.83) {	// list / clear
			if (TouchX < 0.5) {
				MessageMl("list");
			}
			else {
				MessageMl("clearall");
			}
		}
	}
	else if (LinkNum == LN_Selected) {
		HideListPanel(FALSE);
		if (TouchX < 0.5) {		// LHS
			if (TouchY > 0.825) {	// Top row
				MessageMl("remove");
			}
			else if (TouchY > 0.66) {	// Middle row
				MessageMl("resize -25");
			}
			else if (TouchY > 0.5) {	// Bottom row
				MessageMl("rotate -45");
			}
		}
		else {					// RHS
			if (TouchY > 0.825) {	// Top row
				MessageMl("clone");
			}
			else if (TouchY > 0.66) {	// Middle row
				MessageMl("resize +25");
			}
			else if (TouchY > 0.5) {	// Bottom row
				MessageMl("rotate +45");
			}
		}
	}
	else if (LinkNum == LN_ListClose) {
		HideListPanel(TRUE);
	}
	else if (LinkNum == LN_ListPrev) {
		ListPtr -= ThumbnailsCount;
		if (ListPtr < 0) ListPtr = 0;
		if (ListMode == LMO_OBJECTS && CatFilterName != "") {
			if (ListPtr < CatFilterStart) ListPtr = CatFilterStart;
		}
		EndCreationCycle();
		DisplayList(TRUE);
	}
	else if (LinkNum == LN_ListNext) {
		ListPtr += ThumbnailsCount;
		if (LastListPtr() > ListCount()) ListPtr = ListCount() - ThumbnailsCount;
		if (ListMode == LMO_OBJECTS && CatFilterName != "") {
			if (ListPtr > CatFilterEnd - ThumbnailsCount + 1) ListPtr = CatFilterEnd - ThumbnailsCount + 1;
		}
		EndCreationCycle();
		DisplayList(TRUE);
	}
	else if (LinkNum == LN_ListNavigate) {
		ListPtr = 0;
		DisplayCategoryList(TRUE);
	}
	else if (LinkNum == LN_ListPanel || LinkNum == LN_ListBackground) {	// not sure if it would ever be the background, but still ...
		// So they're clicking on an list description. We need to find out which category or object it is.
		// Find height of click in pixels
		integer PixelTouch = (integer)((float)ListHeight * (1.0 - TouchY));
		// Remove top margin
		PixelTouch -= ListTextTopMargin;
		if (PixelTouch < 0) return;	// above first element
		// Divide by height of elements to get pointer to visible element
		integer Which = PixelTouch / ListTextVerticalGap;
		if (ListMode == LMO_OBJECTS) EnableThumbnail(Which);
		// Factor in page start to get pointer to objects list
		integer Ptr = Which + ListPtr;
		// So now Ptr points to the row (not element) of the selected category or object
		if (ListMode == LMO_CATEGORIES) {
			// Save position for later repositioning
			SavedCategoryPtr = Ptr;
			SavedCategoryPagePtr = ListPtr;
			// Expand by stride size
			Ptr *= CA_STRIDE;
			CatFilterName = llList2String(CategoriesList, Ptr + CA_NAME);
			CatFilterStart = llList2Integer(CategoriesList, Ptr + CA_FROM);
			CatFilterEnd = llList2Integer(CategoriesList, Ptr + CA_TO);
			;
			// Now we have the category, open the objects list
			ListMode = LMO_OBJECTS;
			ListPtr = CatFilterStart;
			DisplayObjectList(TRUE);
		}
		else if (ListMode == LMO_OBJECTS) {
			// Save position for later repositioning
			SavedObjectPtr = Ptr;
			SavedObjectPagePtr = ListPtr;
			// Expand by stride size
			Ptr *= OL_STRIDE;
			string ObjectName = llList2String(ObjectsList, Ptr + OL_NAME);
			MessageMl("create " + ObjectName);
		}
	}
	else {
		// it might be an object thumbnail
		integer P = -1;
		integer T;
		for (T = 0; T < ThumbnailsCount; T++) {
			if (LinkNum == llList2Integer(LN_Thumbnails, T)) P = T;
		}
		if (P == -1) return;	// not a thumbnail, so must be an inactive prim
		EnableThumbnail(P);
		integer Ptr = (P + ListPtr) * OL_STRIDE;	// pointer to objects table
		string ObjectName = llList2String(ObjectsList, Ptr + OL_NAME);
		MessageMl("create " + ObjectName);
	}
}
HidePanels() {
	list Params = [];
	vector RootTextureOffset = ZERO_VECTOR;
	if (Hidden) {
		HideListPanel(FALSE);
		Params += SetPrimParams(LN_Constant, PosClosed, SizeClosed);
		if (IsObjectSelected)
			Params += SetPrimParams(LN_Selected, PosClosed, SizeClosed);
		RootTextureOffset.y = 0.75;
	}
	else {
		Params += SetPrimParams(LN_Constant, PosOpenConstant, SizeOpenConstant);
		if (IsObjectSelected)
			Params += SetPrimParams(LN_Selected, PosOpenSelected, SizeOpenSelected);
		RootTextureOffset.y = 0.25;
	}
	Params += [ PRIM_LINK_TARGET, 1, PRIM_TEXTURE, 4, RootTextureId, <1.0, 0.5, 0.0>, RootTextureOffset, 0.0 ];
	ChangePrims(Params);
}
// Grey out all but given thumbnail, or -1 to make all white
EnableThumbnail(integer Which) {
	list Params = [];
	integer T;
	for (T = 0; T <ThumbnailsCount; T++) {
		integer LinkNum = llList2Integer(LN_Thumbnails, T);
		vector Color = COLOR_WHITE;
		if (Which > -1 && Which != T) Color = COLOR_DISABLED_THUMBNAIL;
		Params += [ PRIM_LINK_TARGET, LinkNum, PRIM_COLOR, ListThumbFace, Color, 1.0 ];
	}
	llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
}
// Make sure they're still not in creation mode (ie a selected "create" object)
EndCreationCycle() {
	MessageMl("nocreate");
	EnableThumbnail(-1);
}
list SetPrimParams(integer LinkNum, vector Pos, vector Size) {
	list Params = [ PRIM_LINK_TARGET, LinkNum ];
	if (Pos != ZERO_VECTOR) Params += [ PRIM_POS_LOCAL, Pos ];
	vector NearSize = Size * 1.01;
	Params += [ PRIM_SIZE, NearSize ];
	Params += [ PRIM_SIZE, Size ];
	return Params;
}
ChangePrims(list PrimParams) {
	llSetLinkPrimitiveParamsFast(LINK_THIS, PrimParams);
}
// Take category/object data in notecard format and populate categories and objects lists
ParseObjectsList(string Data) {
	list Lines = llParseString2List(Data, [ "\n" ], []);
	ObjectsList = [];
	integer ObjPtr = 0;
	CategoriesList = [];
	string SaveCategory = "";
	integer CatStart = 0;
	integer CatEnd;
	integer LineCount = llGetListLength(Lines);
	integer L;
	for (L = 0; L < LineCount; L++) {
		string Line = llStringTrim(llList2String(Lines, L), STRING_TRIM);
		if (Line != "") {
			if (llGetSubString(Line, 0, 0) == "[") {
				string CatName = llGetSubString(Line, 1, -2);
				if (SaveCategory != "") {
					CategoriesList += [ SaveCategory, CatStart, CatEnd ];
					CatStart = CatEnd = -1;
				}
				SaveCategory = CatName;
			}
			else {
				if (CatStart == -1) CatStart = ObjPtr;
				CatEnd = ObjPtr;
				ObjectsList += llParseString2List(Line, [ "|" ], []);
				ObjPtr++;
			}
		}
	}
	if (SaveCategory != "") {	// final category
		CategoriesList += [ SaveCategory, CatStart, CatEnd ];
	}
	ObjectsCount = llGetListLength(ObjectsList) / OL_STRIDE;
	OlReceived = TRUE;
	CategoriesCount = llGetListLength(CategoriesList) / CA_STRIDE;
	CatFilterName = "";
	CatFilterStart = 0;
	CatFilterEnd = ObjectsCount;
	//	integer X;
	//	for (X = 0; X < ObjectsCount; X++) {
	//		llOwnerSay((string)X + " " + llList2String(ObjectsList, X * OL_STRIDE));
	//	}
	//	for (X = 0; X < CategoriesCount; X++) {
	//		integer P = X * CA_STRIDE;
	//		llOwnerSay(llList2String(CategoriesList, P) + " " + (string)llList2Integer(CategoriesList, P + 1) + " " + (string)llList2Integer(CategoriesList, P + 2));
	//	}
}
integer GetLinkNumbers() {
	LN_Constant = LN_Selected = LN_ListPanel = LN_ListBackground = LN_ListPrev = LN_ListNext = LN_ListNavigate = LN_ListClose = -1;
	LN_Thumbnails = [];
	integer T;
	for (T = 0; T < ThumbnailsCount; T++) {
		LN_Thumbnails += -1;
	}
	integer PrimCount = llGetNumberOfPrims();
	integer P;
	for (P = 2; P <= PrimCount; P++) {
		string PrimName = llGetLinkName(P);
		if (PrimName == "constant") LN_Constant = P;
		else if (PrimName == "selected") LN_Selected = P;
		else if (PrimName == "listpanel") LN_ListPanel = P;
		else if (PrimName == "listbackground") LN_ListBackground = P;
		else if (PrimName == "list-") LN_ListPrev = P;
		else if (PrimName == "list+") LN_ListNext = P;
		else if (PrimName == "listnav") LN_ListNavigate = P;
		else if (PrimName == "listx") LN_ListClose = P;
		else if (llGetSubString(PrimName, 0, 1) == "th") {
			integer Which = (integer)llGetSubString(PrimName, 2, -1);
			LN_Thumbnails = llListReplaceList(LN_Thumbnails, [ P ], Which, Which);
		}
		vector Pos = llList2Vector(llGetLinkPrimitiveParams(P, [ PRIM_POS_LOCAL ]), 0);
		vector Size = llList2Vector(llGetLinkPrimitiveParams(P, [ PRIM_SIZE ]), 0);
		//llOwnerSay(PrimName + " pos " + (string)Pos);
		//llOwnerSay(PrimName + " size " + (string)Size);
	}
	if (CheckMissing([LN_Constant, LN_Selected, LN_ListPanel, LN_ListBackground, LN_ListPrev, LN_ListNext, LN_ListNavigate, LN_ListClose ] + LN_Thumbnails)) {
		return FALSE;
	}
	return TRUE;
}
integer CheckMissing(list LinkNums) {
	integer Len = llGetListLength(LinkNums);
	integer T;
	for (T = 0; T < Len; T++) {
		if (llList2Integer(LinkNums, T) == -1) {
			llOwnerSay("Prim missing (code " + (string)T + ")");
			return TRUE;
		}
	}
	return FALSE;
}
// Display whichever list we have up at the moment
DisplayList(integer Force) {
	if (ListMode == LMO_CATEGORIES) {
		DisplayCategoryList(Force);
	}
	else if (ListMode == LMO_OBJECTS) {
		DisplayObjectList(Force);
	}
}
// Return the number of entries in the current list, whichever type it is
integer ListCount() {
	if (ListMode == LMO_OBJECTS) return ObjectsCount;
	else if (ListMode == LMO_CATEGORIES) return CategoriesCount;
	else return -1;
}
DisplayCategoryList(integer Force) {
	if (ListMode != LMO_OBJECTS || Force) {
		list Params = ShowListPanel();
		ListMode = LMO_CATEGORIES;
		Params += ShowListNavigate(FALSE);
		Params += HideThumbnails(); // Hide the thumbnails, we don't use them for categories
		// Set up prim-drawing for list
		string CommandList = InitListDrawing("Categories");
		integer L = ListPtr;
		integer T;
		for (T = 0; T < ThumbnailsCount; T++) {
			if (L < CategoriesCount) {
				string CatDesc = llList2String(CategoriesList, (L * CA_STRIDE) + CA_NAME);
				CommandList = osMovePen(CommandList, ListTextLeftOffset, ListTextTopMargin + (ListTextVerticalGap * T) + ListTextVerticalOffset);
				CommandList = osDrawText(CommandList, CatDesc);
			}
			L++;
		}
		Params += ListPrevNextParams();
		llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
		llMessageLinked(LN_ListPanel, PDDS_DRAW, CommandList, NULL_KEY);	// Tell PDDS to draw the stuff we set up
	}
}
DisplayObjectList(integer Force) {
	if (ListMode != LMO_OBJECTS || Force) {
		list Params = ShowListPanel();
		ListMode = LMO_OBJECTS;
		EnableThumbnail(-1);
		// Set up prim-drawing for list
		string CommandList = InitListDrawing("Objects");
		vector Pos = PosOpenThumbnails;
		integer Ol = ListPtr;
		integer T;
		for (T = 0; T < ThumbnailsCount; T++) {
			integer LinkNum = llList2Integer(LN_Thumbnails, T);
			Params += [ PRIM_LINK_TARGET, LinkNum ];
			if (Ol < ObjectsCount && Ol <= CatFilterEnd) {
				string ListText = llList2String(ObjectsList, (Ol * OL_STRIDE) + OL_DESC);
				key OlTexture = llList2Key(ObjectsList, (Ol * OL_STRIDE) + OL_TEXTURE);
				Params += [
					PRIM_COLOR, ListThumbFace, COLOR_WHITE, 1.0,
					PRIM_TEXTURE, ListThumbFace, OlTexture, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
						];
				//				integer LinePos = ListTextTopMargin + (ListTextVerticalGap * T);
				//				CommandList = osDrawLine(CommandList, 0, LinePos, ListTextWidth, LinePos);
				CommandList = osMovePen(CommandList, ListTextLeftOffset, ListTextTopMargin + (ListTextVerticalGap * T) + ListTextVerticalOffset);
				CommandList = osDrawText(CommandList, ListText);
			}
			else {
				Params += [
					PRIM_COLOR, ListThumbFace, COLOR_WHITE, 0.0,
					PRIM_TEXTURE, ListThumbFace, TEXTURE_BLANK, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
						];
			}
			Params += [ PRIM_SIZE, SizeOpenThumbnail, PRIM_POS_LOCAL, Pos ];
			Pos.z -= ThumbnailsGap;
			Ol++;
		}
		Params += ListPrevNextParams();
		Params += ShowListNavigate(IsCategorized());
		llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
		llMessageLinked(LN_ListPanel, PDDS_DRAW, CommandList, NULL_KEY);	// Tell PDDS to draw the stuff we set up
	}
}
// Calculate the position in the objects/categories list of the last item on the list panel
integer LastListPtr() {
	return ListPtr + ThumbnailsCount - 1;
}
// Show or hide list navigation button
list ShowListNavigate(integer Show) {
	if (Show)
		return SetPrimParams(LN_ListNavigate, PosOpenListNavigate, SizeOpenListNavigate);
	else
		return SetPrimParams(LN_ListNavigate, PosClosed, SizeClosed);
}
// Set up next/previous arrows according to current position in list
list ListPrevNextParams() {
	vector PrevPos = PosOpenListPrev;
	vector NextPos = PosOpenListNext;
	if (ListBeginning()) PrevPos.x += 0.1;		// hide previous button if we're already on the first page
	if (ListEnd()) NextPos.x += 0.1;	// hide next button if we're at the end of the list
	return [
		PRIM_LINK_TARGET, LN_ListPrev, PRIM_POS_LOCAL, PrevPos,
		PRIM_LINK_TARGET, LN_ListNext, PRIM_POS_LOCAL, NextPos
			];
}
// Returns true if we're at the first page of the list
integer ListBeginning() {
	if (!OlReceived) return FALSE;	// Put button in front if rezzed in-world
	if (ListPtr == 0) return TRUE;
	if (ListMode == LMO_OBJECTS && CatFilterName != "" && ListPtr == CatFilterStart) return TRUE;
	return FALSE;
}
// Returns true if we're at the last page of the list
integer ListEnd() {
	if (!OlReceived) return FALSE;	// Put button in front if rezzed in-world
	if (LastListPtr() >= ListCount() - 1) return TRUE;
	if (ListMode == LMO_OBJECTS && CatFilterName != "" && LastListPtr() >= CatFilterEnd) return TRUE;
	return FALSE;
}
list ShowListPanel() {
	if (ListMode == LMO_OFF) {	// set up list panel if it's not currently in use
		return
			SetPrimParams(LN_ListPanel, PosOpenList, SizeOpenList) +
			SetPrimParams(LN_ListBackground, PosOpenListBackground, SizeOpenListBackground) +
			SetPrimParams(LN_ListPrev, PosOpenListPrev, SizeOpenListPrevNext) +
			SetPrimParams(LN_ListNext, PosOpenListNext, SizeOpenListPrevNext) +
			SetPrimParams(LN_ListClose, PosOpenListClose, SizeOpenListClose);
	}
	else {
		return [];
	}
}
// Sets up commands for prim drawing for lists, and also initialises PDDS slave script with its parameters
string InitListDrawing(string Title) {
	string CommandList = "";
	CommandList = osSetPenColor(CommandList, ListBackColor);
	CommandList = osDrawFilledRectangle(CommandList, ListWidth, ListHeight);
	CommandList = osSetPenColor(CommandList, "White");
	//		CommandList = osSetPenSize(CommandList, 1);  	// pen size for lines
	// Tell PDDS (prim-drawing dumb slave) about format of surface
	llMessageLinked(LN_ListPanel, PDDS_FACE, (string)ListFace, NULL_KEY);
	llMessageLinked(LN_ListPanel, PDDS_WIDTH, (string)ListWidth, NULL_KEY);
	llMessageLinked(LN_ListPanel, PDDS_HEIGHT, (string)ListHeight, NULL_KEY);
	// Font data for title
	CommandList = osSetFontName(CommandList, ListTitleFontName);
	CommandList = osSetFontSize(CommandList, ListTitleFontSize);
	CommandList = osSetPenColor(CommandList, ListTitlePenColor);
	// Draw title
	CommandList = osMovePen(CommandList, ListTitleLeftOffset, ListTitleVerticalOffset);
	CommandList = osDrawText(CommandList, Title);
	// Font data for text
	CommandList = osSetFontName(CommandList, ListTextFontName);
	CommandList = osSetFontSize(CommandList, ListTextFontSize);
	CommandList = osSetPenColor(CommandList, ListTextPenColor);
	return CommandList;
}
// Hide thumbnails from list panel (eg for categories, which don't use thumbnail images
list HideThumbnails() {
	list Params = [];
	integer T;
	for (T = 0; T < ThumbnailsCount; T++) {
		integer LinkNum = llList2Integer(LN_Thumbnails, T);
		Params += [ PRIM_LINK_TARGET, LinkNum, PRIM_SIZE, SizeClosed, PRIM_POS_LOCAL, PosClosed ];
	}
	return Params;
}
HideListPanel(integer Force) {
	if (ListMode == LMO_OBJECTS || ListMode == LMO_CATEGORIES || Force) {
		EndCreationCycle();
		ListMode = LMO_OFF;
		list Params =
			SetPrimParams(LN_ListPanel, PosClosed, SizeClosed) +
			SetPrimParams(LN_ListBackground, PosClosed, SizeClosed) +
			SetPrimParams(LN_ListPrev, PosClosed, SizeClosed) +
			SetPrimParams(LN_ListNext, PosClosed, SizeClosed) +
			SetPrimParams(LN_ListNavigate, PosClosed, SizeClosed) +
			SetPrimParams(LN_ListClose, PosClosed, SizeClosed)
				;
		integer T;
		for (T = 0; T < ThumbnailsCount; T++) {
			integer LinkNum = llList2Integer(LN_Thumbnails, T);
			Params += [ PRIM_LINK_TARGET, LinkNum, PRIM_SIZE, SizeClosed, PRIM_POS_LOCAL, PosClosed ];
		}
		llSetLinkPrimitiveParamsFast(LINK_THIS, Params);
	}
}
// Just for editing convenience, open all the things
OpenEverything() {
	ChangePrims(
		SetPrimParams(1, ZERO_VECTOR, SizeOpenRoot) +
		SetPrimParams(LN_Constant, PosOpenConstant, SizeOpenConstant) +
		SetPrimParams(LN_Selected, PosOpenSelected, SizeOpenSelected)
			);
	DisplayObjectList(FALSE);
}
CloseEverything() {
	// For convenience, we don't shrink root
	ChangePrims(
		SetPrimParams(LN_Constant, PosClosed, SizeClosed) +
		SetPrimParams(LN_Selected, PosClosed, SizeClosed)
			);
	HideListPanel(TRUE);
}
SetTransparency(integer IsTransparent) {
	float Alpha = 1.0;
	if (IsTransparent) Alpha = 0.0;
	llSetLinkAlpha(LINK_SET, Alpha, ALL_SIDES);
}
// Returns TRUE if we have categories
integer IsCategorized() {
	return CategoriesCount;
}
// Send message to main ML
MessageMl(string Text) {
	//	MessageObject(MlId, Text);
	// we have to use listeners because of the threat level on osMessageObject()
	// https://www.kitely.com/forums/viewtopic.php?f=26&t=3965&p=21889#p21889
	llRegionSayTo(MlId, HUD_CHAT_SPECIFIC, Text);
}
// Wrapper for osMessageObject() that checks to see if destination exists
MessageObject(key Uuid, string Text) {
	if (ObjectExists(Uuid)) {
		osMessageObject(Uuid, Text);
	}
}
// Return true if specified prim/object exists in same region (not so reliable for avatars)
integer ObjectExists(key Uuid) {
	return (llGetObjectDetails(Uuid, [ OBJECT_POS ]) != []) ;
}
string GetVersion() {
	string S = llGetScriptName();
	integer P = llStringLength(S);
	while (--P && llGetSubString(S, P, P) != " ") {}
	P++;
	if (llGetSubString(S, P, P) == "v") P++;
	S = llGetSubString(S, P, -1);
	if ((float)S == 0.0) llOwnerSay("WARNING: cannot find version number of HUD controller script!");
	return S;
}
default {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		OwnerId = llGetOwner();
		MyVersion = GetVersion();
		if (llGetNumberOfPrims() == 1) return;	// Stop doing anything if unlinked
		if (!GetLinkNumbers()) return;
		RootTextureId = llGetTexture(4);
		if (!llGetAttached()) {
			llOwnerSay("HUD rezzed in-world!");
			OpenEverything();
			SetTransparency(FALSE);
			Hidden = FALSE;		// this variable has two meanings - here, it's for when we're rezzed in-world and testing
			return;
		}
		state Standby;
	}
	touch_start(integer N) {
		// this is just for when we're rezzed in-world and checking that hide/reveal is all working
		if (Hidden = !Hidden) {
			OpenEverything();
		}
		else {
			CloseEverything();
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) llResetScript();
	}
}
state Standby {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		SetTransparency(TRUE);
		SelectionStatusCurrent = SelectionStatusNew = SS_NOTHING;
		IsObjectSelected = FALSE;
		ListMode = LMO_OFF;
		ChangePrims(
			SetPrimParams(1, ZERO_VECTOR, SizeClosed) +
			SetPrimParams(LN_Constant, PosClosed, SizeClosed) +
			SetPrimParams(LN_Selected, PosClosed, SizeClosed)
				);
		HideListPanel(TRUE);
		OlReceived = FALSE;
		HeartbeatString = "H" + "|" + (string)OwnerId + "|" + MyVersion;
		llSetTimerEvent(1.0);
	}
	timer() {
		llRegionSay(HUD_CHAT_GENERAL, HeartbeatString);
	}
	dataserver(key Id, string Data) {
		if (Data == "a") {
			MlId = Id;
			state Normal;
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) llResetScript();
	}
}
state Normal {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		ChangePrims(
			SetPrimParams(1, ZERO_VECTOR, SizeOpenRoot) +
			SetPrimParams(LN_Constant, PosOpenConstant, SizeOpenConstant)
				);
		SetTransparency(FALSE);
		Hidden = FALSE;
		HidePanels();	// Non-minimized
		EndCreationCycle();	// just in case
		ListPtr = 0;	// reset pointer to objects list
		SavedCategoryPtr = SavedObjectPtr = SavedCategoryPagePtr = SavedObjectPagePtr = -1;
		CheckMlExists = ML_EXISTS_CHECK_FREQUENCY;
		llSetTimerEvent(0.5);
	}
	touch_start(integer Count) {
		integer LinkNum = llDetectedLinkNumber(0);
		vector TouchST = llDetectedTouchST(0);
		HandleTouch(LinkNum, TouchST.x, TouchST.y);
	}
	dataserver(key Id, string Data) {
		if (Data == "a") {	// this shouldn't happen, since we're already activated
			state ReloadNormal;	// but we'll act as if we weren't
		}
		else if (Data == "d") {	// deactivated
			state Standby;
		}
		else if (Data == "sy") { // selected yes
			SelectionStatusNew = SS_SELECTED;
			IsObjectSelected = TRUE;
		}
		else if (Data == "sn") { // selected no (deselected)
			SelectionStatusNew = SS_NOT_SELECTED;
			IsObjectSelected = FALSE;
		}
		else if (llGetSubString(Data, 0, 0) == "o") {	// objects list - string starting with "o"
			ParseObjectsList(llGetSubString(Data, 1, -1));
		}
	}
	timer() {
		// We have to defer the changing of the appearance, because we can get streams of
		// selection/deselection messages as a side-effect of operations such as clearing the board
		// (the ML script uses selection internally as well as externally).
		if (SelectionStatusNew != SelectionStatusCurrent) {
			SelectionStatusCurrent = SelectionStatusNew;
			if (SelectionStatusCurrent == SS_SELECTED) {
				HideListPanel(FALSE);
				ChangePrims(SetPrimParams(LN_Selected, PosOpenSelected, SizeOpenSelected));
			}
			else if (SelectionStatusCurrent == SS_NOT_SELECTED) {
				ChangePrims(SetPrimParams(LN_Selected, PosClosed, SizeClosed));
			}
		}
		// If we don't have the object list yet, request it.
		// This is in the timer to make sure the HUD server is ready to receive it
		if (!OlReceived) MessageMl("o");		// request object list
		// Check if ML object is still there
		if (!CheckMlExists--) {
			if (!ObjectExists(MlId)) state Standby;
			CheckMlExists = ML_EXISTS_CHECK_FREQUENCY;
		}
	}
	changed(integer Change) {
		if (Change & CHANGED_LINK) llResetScript();
		if (Change & CHANGED_REGION) state Standby;
	}
}
state ReloadNormal {
	on_rez(integer S) { llResetScript(); }
	state_entry() {
		state Normal;
	}
}
// RezMelka HUD controller v0.1