// Ground map search v0.1
integer MenuChannel;
key MenuAvId;
integer MenuListener;

integer GMC_SEARCH = -90152000;
integer GMC_MOVE_TO = -90152001;

string ApiKey; // "AIzaSyAmdGed6n7oOmU-HJEBm4wNvh4Mi_xlJPo"

key RequestId;

string SearchString;

list Results; 	// [ Address, Lat, Lon ]
integer RES_ADDRESS = 0;
integer RES_LAT = 1;
integer RES_LON = 2;
integer RES_STRIDE = 3;

string BTN_SEARCH_AGAIN = "Search again";
string BTN_CANCEL = "Cancel";

GetSearch(key AvId) {
	SearchString = "";
	MenuChannel = -1000 - (integer)llFrand(100000.0);
	MenuAvId = AvId;
	MenuListener = llListen(MenuChannel, "", MenuAvId, "");
	llTextBox(MenuAvId, "Enter place to search for:", MenuChannel);
}
string GetJsonExpressionSide(string Line, integer WhichSide) {
	list Sides = llParseStringKeepNulls(Line, [ " : " ], []);
	string Text = llStringTrim(llList2String(Sides, WhichSide), STRING_TRIM);
	if (llGetSubString(Text, -1, -1) == ",")
		Text = llGetSubString(Text, 0, -2);	// strip trailing comma
	if (llGetSubString(Text, 0, 0) == "\"" && llGetSubString(Text, -1, -1) == "\"") { 	// if surrounded by quotes
		Text = llGetSubString(Text, 1, -2);	// strip quotes
	}
	return Text;
}
// Takes a string in double quotes, and strips out the quotes. Validates the format.
// <Text> is the string with quotes; <Line> is the entire line for error reporting
string StripQuotes(string Text, string Line) {
	if (Text == "") {	// allow empty string for null value
		return("");
	}
	if (llGetSubString(Text, 0, 0) == "\"" && llGetSubString(Text, -1, -1) == "\"") { 	// if surrounded by quotes
		return(llGetSubString(Text, 1, -2));	// strip quotes
	}
	else {
		llOwnerSay("Invalid string literal (missing \"\"?): " + Line);
		return("");
	}
}
default {
	state_entry() {
	}
	link_message(integer Sender, integer Number, string String, key Id) {
		if (Number == GMC_SEARCH) {
			ApiKey = String;
			GetSearch(Id);
		}
	}
	listen(integer Channel, string Name, key Id, string Message) {
		if (Channel == MenuChannel && Id == MenuAvId) {
			llListenRemove(MenuChannel);
			if (SearchString == "") {	// it must be input textbox, not results
				if (Message == "") return;	// Nothing entered
				SearchString = Message;
				string Url = "https://maps.googleapis.com/maps/api/geocode/json?address=" + llEscapeURL(SearchString) + "&region=us&key=" + ApiKey;
				RequestId = llHTTPRequest(Url, [ HTTP_BODY_MAXLENGTH, 16384 ], "");
			}
			else {
				if (Message == BTN_SEARCH_AGAIN) {
					GetSearch(MenuAvId);
				}
				else if (Message == BTN_CANCEL) {
					return;
				}
				else {
					integer Res = (integer)Message - 1;
					integer Ptr = Res * RES_STRIDE;
					float Lat = llList2Float(Results, Ptr + RES_LAT);
					float Lon = llList2Float(Results, Ptr + RES_LON);
					llMessageLinked(LINK_SET, GMC_MOVE_TO, llList2CSV([ Lat, Lon ]), MenuAvId);
				}
			}
		}
	}
	http_response(key RId, integer Status, list Metadata, string Body) {
		if (RId != RequestId) return;
		list Lines = llParseString2List(Body, [ "\n" ], []);
		Results = [];
		integer ResultsCount = 0;
		string Address;
		float Lat;
		float Lon;
		integer Phase = 0;
		integer Len = llGetListLength(Lines);
		integer I;
		for (I = 0; I < Len; I++) {
			string Line = llStringTrim(llList2String(Lines, I), STRING_TRIM);
			string Lhs = GetJsonExpressionSide(Line, 0);
			if (Lhs == "formatted_address") {
				Address = GetJsonExpressionSide(Line, 1);
				Lat = Lon = 0.0;
				Phase = 1;
			}
			else if (Lhs == "location" && Phase == 1) {
				Phase = 2;
			}
			else if (Lhs == "lat" && Phase == 2) {
				Lat = (float)GetJsonExpressionSide(Line, 1);
				Phase = 3;
			}
			else if (Lhs == "lng" && Phase == 3) {
				Lon = (float)GetJsonExpressionSide(Line, 1);
				Results += [ Address, Lat, Lon ];
				ResultsCount++;
				Phase = 0;
			}
		}
		if (Results == []) {
			llDialog(MenuAvId, "No results for '" + SearchString + "'", [ "OK" ], 999999);
			return;
		}
		list Buttons;
		string Message = "\nSelect:\n\n";
		integer LastRes = ResultsCount;
		if (LastRes > 10) LastRes = 10;		// truncate to 10 results
		integer Res;
		for (Res = 0; Res < LastRes; Res++) {
			integer Ptr = Res * RES_STRIDE;
			string ResAddress = llList2String(Results, Ptr + RES_ADDRESS);
			integer Which = Res + 1;	// 1-n, not 0-n
			Buttons += Which;
			Message += (string)Which + ": " + ResAddress + "\n";
		}
		Buttons += [ BTN_SEARCH_AGAIN, BTN_CANCEL ];
		// next line from: http://lslwiki.net/lslwiki/wakka.php?wakka=llDialog
		for (I=0;I<llGetListLength(Buttons);I+=3) { Buttons = llListInsertList(llDeleteSubList(Buttons, -3, -1), llList2List(Buttons, -3, -1), I); }
		MenuListener = llListen(MenuChannel, "", MenuAvId, "");
		llDialog(MenuAvId, Message, Buttons, MenuChannel);
	}
}
// Ground map search v0.1