// ML bookmark comms server v0.4

// v0.4 moved to new RG server
// v0.3 tighter control over initial states/region restarts/etc

string PHP_URL = "http://rezmela.net/extint/v1/";
string PHP_GET_ID_SCRIPT = "GetUserId.php";
string PHP_GET_BOOKMARKS_SCRIPT = "GetBookmarks.php";

key AvId;
string AvName;
string UserId;	// This is the ID from the PHP subsystem

key IdRequestId;
key BookmarksRequestId;

integer SelectedBookmark;
integer BooktrayLinkNum;
string BooktrayObjectName;
vector BooktrayPos;
rotation BooktrayRot;

list Bookmarks;
integer BO_DESCRIPTION = 0;
integer BO_URL = 1;
integer BO_TITLE_COLOR = 2;
integer BO_COVER_COLOR = 3;
integer BO_STRIDE = 4;
integer BookmarksCount;	// number of rows, not elements
integer BOOKMARK_MENU_MAX = 9;	// how many can be displayed at once

integer MenuChannel;
integer MenuListener;
list MenuBookmarks = [];		// pointers to bookmarks table

string Grid;

string BTN_CLOSE = "Close";
string BTN_CLEARALL = "Clear all";
string BTN_CLEAR = "Clear";
string BTN_CANCEL = "Cancel";
string BTN_CREATE = "Create";
string BTN_DELETE = "Delete";
string BTN_BACK = "< Back";

// Messages from ML telling us that someone has logged in/out of the ML
integer LM_SEAT_USER = -405520;

// Booktray-specific LMs
integer BOTR_MENU = -5519150700;

// Automatic Object Creation (AOC) messages - for scripts to be able to create ML objects
integer AOC_CREATE = 101442800;

ShowMenu() {
	RemoveListener();
	MenuChannel = -10000 - (integer)llFrand(1000000);
	if (!llGetListLength(Bookmarks)) {
		Alert("No bookmarks waiting");
		return;
	}
	string MenuText = "Bookmarks: \n";
	BookmarksCount = llGetListLength(Bookmarks) / BO_STRIDE;
	integer Start = BookmarksCount - BOOKMARK_MENU_MAX;
	if (Start < 0) Start = 0;
	integer LineNum = 0;
	list Buttons = [];
	MenuBookmarks = [];
	integer P;
	for (P = Start; P < BookmarksCount; P++) {
		MenuBookmarks += P;
		string VisLineNum = (string)(LineNum + 1);
		integer B = P * BO_STRIDE;	// pointer to bookmarks table
		MenuText +=  VisLineNum + ": " + DescribeBookmark(B) + "\n";
		Buttons += VisLineNum ;
		LineNum++ ;
	}
	// Pad to width of 3 buttons
	while(LineNum % 3) {
		Buttons += " ";
		LineNum++;
	}
	// Rearrange for silly LSL button order
	Buttons = llList2List(Buttons, 6, 8) + llList2List(Buttons, 3, 5) + llList2List(Buttons, 0, 2);
	MenuText += "\nSelect:";
	Buttons = [ BTN_CLOSE, " ", BTN_CLEARALL ] + Buttons;
	MenuListener = llListen(MenuChannel, "", AvId, "");
	Dialog(MenuText, Buttons, MenuChannel);
}
Alert(string Text) {
	Dialog(Text, [ "OK" ], MenuChannel);
}
Dialog(string Text, list Buttons, integer MenuChannel) {
	Text = "\nCHROME EXTENSION BOOKMARKS\n\nYour user id is: " + UserId + "\n\n" + Text + "\n\n";
	llDialog(AvId, Text, Buttons, MenuChannel);
}
CreateBookmarkObject(integer BookmarksPtr) {
	integer B = BookmarksPtr * BO_STRIDE;	// pointer to bookmarks table
	string Desc = llList2String(Bookmarks, B + BO_DESCRIPTION);
	string Url = llList2String(Bookmarks, B + BO_URL);
	string BookmarkColorCover = llList2String(Bookmarks, B + BO_COVER_COLOR);
	string BookmarkColorTitle = llList2String(Bookmarks, B + BO_TITLE_COLOR);

	// This is the only way to multiple all the components of a pair of vectors. It's ugly.
	vector OffsetV = ZERO_VECTOR;
	OffsetV.z += 0.2 + llFrand(0.2);
	OffsetV.y += -0.05 + llFrand(0.1);
	vector ObjectPos = BooktrayPos + (OffsetV * BooktrayRot);	// Use those offsets to calculate the actual position
	rotation ObjectRot = BooktrayRot;
	string ObjectParams = llDumpList2String([ Url, Desc, BookmarkColorCover, BookmarkColorTitle ], "^");
	llMessageLinked(LINK_SET, AOC_CREATE, llDumpList2String([ BooktrayObjectName, ObjectPos, ObjectRot, ObjectParams ], "|"), AvId);
}
string DescribeBookmark(integer Ptr) {
	string Desc = llList2String(Bookmarks, Ptr + BO_DESCRIPTION);
	string Url = llList2String(Bookmarks, Ptr + BO_URL);
	return Desc + " [" + UrlSummary(Url) + "]";
}
RemoveBookmark(integer Ptr) {
	integer B = Ptr * BO_STRIDE;	// pointer to bookmarks table
	Bookmarks = llDeleteSubList(Bookmarks, B, B + BO_STRIDE - 1);
	BookmarksCount--;
}
string UrlSummary(string Url) {
	string Summ = Url;
	if (llGetSubString(Summ, 0, 6) == "http://") Summ = llGetSubString(Summ, 7, -1);
	if (llGetSubString(Summ, 0, 7) == "https://") Summ = llGetSubString(Summ, 8, -1);
	if (llGetSubString(Summ, 0, 3) == "www.") Summ = llGetSubString(Summ, 4, -1);
	integer P = llSubStringIndex(Summ, "/");
	if (P > -1) {
		Summ = llGetSubString(Summ, 0, P - 1);
	}
	return Summ;
}
RemoveListener() {
	if (MenuListener) {
		llListenRemove(MenuListener);
		MenuListener = 0;
	}
}
RequestBookmarks() {
	string PHPCall = PHP_URL + PHP_GET_BOOKMARKS_SCRIPT +
		"/?uid=" + UserId
			;
	BookmarksRequestId = llHTTPRequest(PHPCall, [], "");
}
ProcessBookmarks(list BookmarkLines) {
	integer L = llGetListLength(BookmarkLines);
	integer P;
	for (P = 0; P < L; P++) {
		string Line = llStringTrim(llList2String(BookmarkLines, P), STRING_TRIM);
		if (Line != "" && Line != "EOF") {
			//llOwnerSay("Bookmark: " + llList2String(BookmarkLines, P));
			list Parts = llParseStringKeepNulls(Line, [ "|" ], []);
			string Url = llList2String(Parts, 1);
			string Description = llList2String(Parts, 2);
			string TitleColor = llList2String(Parts, 3);
			string CoverColor = llList2String(Parts, 4);
			Bookmarks  += [
				Description,
				Url,
				TitleColor,
				CoverColor
					];
			BookmarksCount++;
		}
	}
}
RequestUserId() {
	string PHPCall = PHP_URL + PHP_GET_ID_SCRIPT +
		"/?grid=" + llEscapeURL(Grid) +
		"&uname=" + llEscapeURL(AvName);
	;
	IdRequestId = llHTTPRequest(PHPCall, [], "");
}
default {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		BookmarksCount = 0;
		Grid = "RG";	// this really should be in the main ML script's config file and passed to us on initialisation
		state Idle;
	}
}
state Idle {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_SEAT_USER) {	// someone has logged in or out of the ML
			if (String != "") {	// this is actually the seat number they're logged into, but that has no relevance to us
				AvId = Id;			// logged in
				state GetUserId;
			}
		}
	}
}
state GetUserId {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		AvName = llKey2Name(AvId);
		RequestUserId();
		llSetTimerEvent(30.0);
	}
	http_response(key Id, integer Status, list Metadata, string Body) {
		//	llOwnerSay("Response: " + (string)Status + "/" + llList2CSV(Metadata) + ": " + Body);
		if (Id == IdRequestId) {
			if (Status == 200) {
				llSetTimerEvent(0.0);
				UserId = llStringTrim(Body, STRING_TRIM);
				state Running;
			}
			else {	// Error return status - try again
				llSetTimerEvent(30.0);
				llSleep(1.0);
				RequestUserId();
			}
		}
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == LM_SEAT_USER) {	// someone has logged in or out of the ML
			// Presumably, they logged out/relogged as soon as they logged in, which is why we're still processing the login here
			if (String == "") {	// this is actually the seat number they're logged into, but that has no relevance to us
				state Idle;
			}
			else {
				AvId = Id;			// logged in
				state ReGetUserId;		// restart login process with new ID
			}
		}
	}
	timer() {
		llSetTimerEvent(0.0);
		llOwnerSay("Web server access timed out");
		state Idle;
	}
}
state ReGetUserId { state_entry() { state GetUserId; }}
state Running {
	on_rez(integer start_param) { llResetScript(); }
	state_entry() {
		RemoveListener();
	}
	http_response(key Id, integer Status, list Metadata, string Body) {
		//	llOwnerSay("Response: " + (string)Status + "/" + llList2CSV(Metadata) + ": " + Body);
		if (Id == BookmarksRequestId) {
			if (Status == 200) {
				if (Body != "") {
					list BookmarkLines = llParseString2List(Body, [ "\n" ], []);
					ProcessBookmarks(BookmarkLines);
				}
				ShowMenu();
			}
			else {
				// Ignore non-zero returns. They seem to happen sometimes
				//llOwnerSay("Bookmarks request returned status " + (string)Status + ":\n" + Body);
			}
		}
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == BOTR_MENU) {
			BooktrayLinkNum = Sender;
			list Parts = llParseStringKeepNulls(String, [ "|" ], []);
			BooktrayObjectName = llList2String(Parts, 0);
			Parts = llGetLinkPrimitiveParams(Sender, [ PRIM_POS_LOCAL, PRIM_ROT_LOCAL ]);
			BooktrayPos = llList2Vector(Parts, 0);
			BooktrayRot = llList2Rot(Parts, 1);
			RequestBookmarks();
		}
		else if (Number == LM_SEAT_USER) {	// someone has logged in or out of the ML
			if (String == "") {	// if they logged out
				state Idle;
			}
			else {
				if (Id != AvId) {
					AvId = Id;			// someone else logged in
					state GetUserId;
				}
			}
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (MenuChannel && Channel == MenuChannel && Id == AvId) {
			if (Message == BTN_CLOSE) {
				RemoveListener();
			}
			else if (Message == BTN_CANCEL) {
				ShowMenu();
			}
			else if (Message == BTN_BACK) {
				ShowMenu();
			}
			else if (Message == BTN_CLEARALL) {
				llDialog(AvId,
					"\nWarning: This will remove all bookmarks that are waiting to be processed.\n\nClick '" + BTN_CLEAR + "' to continue",
					[ BTN_CLEAR, BTN_CANCEL ], MenuChannel);
			}
			else if (Message == BTN_CLEAR) {	// clear all, after warning
				Bookmarks = [];
				BookmarksCount = 0;
				Alert("Bookmark(s) cleared");
			}
			else if (Message == BTN_CREATE) {
				CreateBookmarkObject(SelectedBookmark);
				RemoveBookmark(SelectedBookmark);
				ShowMenu();
			}
			else if (Message == BTN_DELETE) {
				RemoveBookmark(SelectedBookmark);
				ShowMenu();
			}
			else if ((integer)Message) {	// if it's a numeric response
				SelectedBookmark = (integer)Message - 1;
				integer B = SelectedBookmark * BO_STRIDE;	// pointer to bookmarks table
				string Text = "\n" +DescribeBookmark(B) + "\n" +
					"\nSelect '" + BTN_CREATE + "' to create bookmark object, or '" + BTN_DELETE + "' to remove this entry.\n";
				list Buttons = [ BTN_BACK, BTN_CREATE, BTN_DELETE ];
				llDialog(AvId, Text, Buttons, MenuChannel);
			}
		}
	}
}
// ML bookmark comms server v0.4