// API linked messages (for comms between this script and applications
integer HUD_API_MAX = -4720600;	// Minimum value in this set (but negative)
integer HUD_API_LOGIN = -4720600;
integer HUD_API_LOGOUT = -4720601;
integer HUD_API_GET_METADATA = -4720602;
integer HUD_API_SET_METADATA = -4720603;
integer HUD_API_CREATE_WINDOW_BUTTONS = -4720604;
integer HUD_API_CREATE_WINDOW_LIST = -4720605;
integer HUD_API_CREATE_WINDOW_CUSTOM = -4720606;
integer HUD_API_CREATE_WINDOW_STATUS = -4720607;
integer HUD_API_CREATE_WINDOW_ALERT  = -4720608;
integer HUD_API_CREATE_WINDOW_IMAGETEXT  = -4720609;
integer HUD_API_DISPLAY_WINDOW = -4720620;
integer HUD_API_CLICK_BUTTON = -4720621;
integer HUD_API_CLICK_LIST = -4720622;
integer HUD_API_READY = -4720623;
integer HUD_API_BACK_BUTTON = -4720624;
integer HUD_API_DESTROY_WINDOW = -4720625;
integer HUD_API_MIN = -4720699;	// Maximum value in this set (but negative)

string HUD_API_SEPARATOR_1 = "|";
string HUD_API_SEPARATOR_2 = "^";

integer HudPrimLinkNum;

integer ToggleOn = FALSE;

key AvId;

CreateWindowButtons(string Name, string Parent, string Heading, integer Back, list Buttons) {
	SendHud(HUD_API_CREATE_WINDOW_BUTTONS, [ Name, Parent, Heading, Back ] + llDumpList2String(Buttons, HUD_API_SEPARATOR_2));
}
CreateWindowListPlain(string Name, string Parent, string Heading, integer Back, list Elements) {
	SendHud(HUD_API_CREATE_WINDOW_LIST, [ Name, Parent, Heading, Back, FALSE ] + llDumpList2String(Elements, HUD_API_SEPARATOR_2));
}
CreateWindowListThumbs(string Name, string Parent, string Heading, integer Back, list Elements) {
	SendHud(HUD_API_CREATE_WINDOW_LIST, [ Name, Parent, Heading, Back, TRUE ] + llDumpList2String(Elements, HUD_API_SEPARATOR_2));
}
CreateWindowImageText(string Name, string Parent, string Heading, integer Back, key TextureId, string Text) {
	SendHud(HUD_API_CREATE_WINDOW_IMAGETEXT, [ Name, Parent, Heading, Back ] + llDumpList2String([ TextureId, llStringToBase64(Text) ], HUD_API_SEPARATOR_2));
}
CreateWindowCustom(string Name, string Parent, string Heading, integer Back, list Blocks) {
	SendHud(HUD_API_CREATE_WINDOW_CUSTOM, [ Name, Parent, Heading, Back ] + llDumpList2String(Blocks, HUD_API_SEPARATOR_2));
}
CreateWindowStatus(string Name, string Heading, list Message) {
	SendHud(HUD_API_CREATE_WINDOW_STATUS, [ Name, Heading ] + llDumpList2String(Message, HUD_API_SEPARATOR_2));
}
CreateWindowAlert(string Name, string Heading, list Message, list Buttons) {
	SendHud(HUD_API_CREATE_WINDOW_ALERT, [ Name, Heading ] + llDumpList2String(Message, HUD_API_SEPARATOR_2) + llDumpList2String(Buttons, HUD_API_SEPARATOR_2));
}
DisplayWindow(string Name) {
	SendHud(HUD_API_DISPLAY_WINDOW, [ Name ]);
}
SendMetaData() {
	SendHud(HUD_API_SET_METADATA, [ "Testbed" ]);
}
SendHud(integer Command, list Parts) {
	integer LinkNum = HudPrimLinkNum;
	if (LinkNum == -1) LinkNum = LINK_SET;	// for clarity (LINK_SET actually is -1) - if we don't know which prim has the HUD we broadcast
	llMessageLinked(LinkNum, Command, llDumpList2String(Parts, HUD_API_SEPARATOR_1), AvId);
}
ShowUser() {
	string Text = "HUD Testbed\n⏹\n\n";
	string Name = "Nobody signed in";
	if (AvId != NULL_KEY) {
		Name = llKey2Name(AvId);
	}
	Text += Name;
	llSetText(Text, <1.0, 1.0, 1.0>, 1.0);
}
ObjectDetails(string Tag) {
	string Name = "odet";
	string Heading = "Object details";
	CreateWindowCustom(Name, "objects", Heading, TRUE, MakeCustomDisplay(Tag));
	DisplayWindow(Name);
}
list MakeCustomDisplay(string Tag) {
	return [
		"MoveTo 40, 150",
		"Text " + "Your object:",
		"MoveTo 40, 220",
		"Text " + Tag
			];
}
list NumberList(integer Count) {
	list Ret = [];
	integer I = 0;
	while(I++ < Count) {
		Ret += "Number " + (string)I + " of " + (string)Count +		// Description
			HUD_API_SEPARATOR_2 + "num" + (string)I;				// Tag
	}
	return Ret;
}
list ListObjects(integer Count) {
	list Ret = [];
	list Lines = llParseStringKeepNulls(osGetNotecard("HUD objects"), [ "\n" ], []);
	integer Len = llGetListLength(Lines);
	integer Ptr = 0;
	for (Ptr = 0; Ptr < Len && Count; Ptr++) {
		string Line = llList2String(Lines, Ptr);
		list Parts = llParseStringKeepNulls(Line, [ "|" ], []);
		if (llGetListLength(Parts) == 3) {
			string Tag = llList2String(Parts, 0);	// object name
			string Description = llList2String(Parts, 1);
			string Uuid = llList2String(Parts, 2);
			string RetLine = Uuid + HUD_API_SEPARATOR_2 + Description + HUD_API_SEPARATOR_2 + Tag;
			Ret += RetLine;
			Count--;
		}
	}
	return Ret;
}
ShowToggle() {
	if (ToggleOn) DisplayWindow("toggle1"); else DisplayWindow("toggle0");
}
default {
	on_rez(integer P) { llResetScript(); }
	state_entry() {
		HudPrimLinkNum = LINK_SET;	// Until we know better
		AvId = NULL_KEY;
		ShowUser();
	}
	link_message(integer Sender, integer Number, string Text, key Id) {
		if (Sender > 1) {	// messages from child prim
			if (Number >= HUD_API_MIN && Number <= HUD_API_MAX) {	// it's a HUD API message
				list Parts = llParseStringKeepNulls(Text, [ HUD_API_SEPARATOR_1 ], []);
				if (Number == HUD_API_CLICK_BUTTON) {
					string WindowName = llList2String(Parts, 0);
					string Tag = llList2String(Parts, 1);
					// Main menu
					if (WindowName == "main") {
						if (Tag == "Colors") DisplayWindow("colors");
						else if (Tag == "Musicians") DisplayWindow("musicians");
						else if (Tag == "Numbers") DisplayWindow("numbers");
						else if (Tag == "Trees") DisplayWindow("trees");
						else if (Tag == "Objects") DisplayWindow("objects");
						else if (Tag == "Alert") DisplayWindow("alert");
						else if (Tag == "Status") { DisplayWindow("status"); llSleep(5.0); DisplayWindow("main"); }
						else if (Tag == "Toggle") ShowToggle();
						else if (Tag == "ImageText") DisplayWindow("imagetext");
					}
					// Sub-menus
					else if (WindowName == "musicians") {
						if (Tag == "Performers") DisplayWindow("performers");
						else if (Tag == "Composers") DisplayWindow("composers");
					}
					else if (WindowName == "composers") {
						if (Tag == "Classical") DisplayWindow("compclass");
						else if (Tag == "Popular") DisplayWindow("comppop");
					}
					// Elementals
					else if (WindowName == "colors") {
						llRegionSayTo(Id, 0, "Your color is " + Tag);
					}
					else if (WindowName == "compclass") {
						llRegionSayTo(Id, 0, "Your Classical composer is " + Tag);
					}
					else if (WindowName == "comppop") {
						llRegionSayTo(Id, 0, "Your popular composer is " + Tag);
					}
					else if (WindowName == "numbers") {
						llRegionSayTo(Id, 0, "Your number is: " + Tag);
					}
					else if (WindowName == "trees") {
						llRegionSayTo(Id, 0, "Your tree is: " + Tag);
					}
					else if (WindowName == "objects") {
						llRegionSayTo(Id, 0, "Your object is: " + Tag);
						ObjectDetails(Tag);
					}
					else if (WindowName == "alert") {
						string Reply = "I'm sorry you didn't like the alert.";
						if (Tag == "Yes") Reply = "I'm glad you liked the alert!";
						llRegionSayTo(Id, 0, Reply);
						DisplayWindow("main");
					}
					else if (WindowName == "toggle0" || WindowName == "toggle1") {
						ToggleOn = !ToggleOn;
						ShowToggle();
					}
				}
				else if (Number == HUD_API_BACK_BUTTON) {
					string WindowName = llList2String(Parts, 0);
					//					if (WindowName == "colors") DisplayWindow("main");
					//					else if (WindowName == "musicians") DisplayWindow("main");
					//					else if (WindowName == "performers") DisplayWindow("musicians");
					//					else if (WindowName == "composers") DisplayWindow("musicians");
					//					else if (WindowName == "compclass") DisplayWindow("composers");
					//					else if (WindowName == "comppop") DisplayWindow("composers");
					//					else if (WindowName == "numbers") DisplayWindow("main");
					//					else if (WindowName == "trees") DisplayWindow("main");
					//					else if (WindowName == "objects") DisplayWindow("main");
					//					else if (WindowName == "odet") DisplayWindow("objects");
				}
				else if (Number == HUD_API_LOGIN) {
					HudPrimLinkNum = Sender;
					AvId = Id;
					ShowUser();
					SendHud(HUD_API_READY, []);		// Tell HUD we're ready
				}
				else if (Number == HUD_API_READY) {		// HUD is ready, so we send our first page
					CreateWindowButtons("main", "", "Main", FALSE, [ "Colors", "Musicians", "Numbers", "Trees", "Objects", "Alert", "Status", "Toggle", "ImageText" ]);
					CreateWindowButtons("colors", "main", "Colors", TRUE, [ "Red", "Blue", "White", "Green", "Yellow", "Purple", "Gray" ]);
					CreateWindowButtons("musicians", "main", "Musicians", TRUE, [ "Performers", "Composers" ]);
					CreateWindowButtons("performers", "musicians", "Performers", TRUE, [ "Dizzy Gillespie", "Astrud Gilberto", "BB King", "Andrés Segovia" ]);
					CreateWindowButtons("composers", "musicians", "Composers", TRUE, [ "Classical", "Popular" ]);
					CreateWindowButtons("compclass", "composers", "Classical", TRUE, [ "Brahms", "Mozart", "Grieg", "Handel", "Beethoven",
						"Liszt", "Haydn", "Tchaikovsky", "Strauss", "Bizet", "Debussy", "Delius" ]);
					CreateWindowButtons("comppop", "composers", "Popular", TRUE, [ "Berlin", "Porter", "Gershwin", "Rodgers" ]);
					CreateWindowListPlain("numbers", "main", "Numbers", TRUE, NumberList(20));
					CreateWindowListPlain("trees", "main", "Trees", TRUE, [ "Aspen", "", "Birch", "", "Elm", "", "Pine", "" ]);
					CreateWindowListThumbs("objects", "main", "Objects", TRUE, ListObjects(40));
					CreateWindowStatus("status", "Test of status", [ "This status will",  "be displayed", "for 5 seconds ..." ]);
					CreateWindowAlert("alert", "Test of alert OLD", [ "Do you like this?" ], [ "*Yes", "No" ]);
					CreateWindowAlert("alert", "Test of alert", [ "Do you like this?" ], [ "*Yes", "No" ]);// test that delete works
					CreateWindowButtons("toggle0", "main", "Toggling", TRUE, [ "Random ☐" ]);
					CreateWindowButtons("toggle1", "main", "Toggling", TRUE, [ "Random ☑" ]);
					CreateWindowImageText("imagetext", "main", "Grid texture", TRUE, "215477c7-5389-4091-95fa-e6da7ec4de3a", "This is a grid used for\naligning things. I made \nit myself in about\n2008 because I wasn't\nhappy with the others in \nSL at the time.");
					DisplayWindow("main");
				}
				else if (Number == HUD_API_GET_METADATA) {	// HUD server requesting our data
					HudPrimLinkNum = Sender;
					SendMetaData();
				}
				else if (Number == HUD_API_LOGOUT) {
					AvId = NULL_KEY;
					ShowUser();
				}
			}
		}
	}
}