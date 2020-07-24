// RezMela notecard picker v0.4

string ADMINS_NOTECARD = "Admins";
string MENU_PRIM_NAME = "!notecard";        // name of button for menu
string CLEAR_PRIM_NAME = "!clear";            // button for clear

key OwnerId;
key MenuAvId;
integer MenuListener;
integer MenuChannel;
integer MenuPage;
integer MenuPageCount;
list CardsList;
integer CardsListSize;
integer MENU_PAGE_SIZE = 9;
string BUTTON_PREV = "<< Prev";
string BUTTON_NEXT = "Next >>";
string BUTTON_CANCEL = "Cancel";

integer MenuPrim;
integer ClearPrim;
integer ButtonsActive = TRUE;

// Copied from Controller Root and adapted
integer PANTO_REZZOR_CHANNEL = -101;
integer COMM_CHANNEL = -4000;
integer TAPE_CHANNEL = -15;
// End of copied code

MenuShow() {
    MenuListener = llListen(MenuChannel, "", MenuAvId, "");
    llSetTimerEvent(600.0);
    if (MenuPage >= MenuPageCount) MenuPage = MenuPageCount - 1;
    // Pointers to first and last entry on page
    integer P1 = MenuPage * MENU_PAGE_SIZE;
    integer P2 = P1 + MENU_PAGE_SIZE - 1;
    list Buttons = [];
    string MenuText = "\n";
    if (CardsListSize) {
        string PageText = "";
        if (MenuPageCount > 1)
            PageText = " (page " + (string)(MenuPage + 1) + " of " + (string)MenuPageCount + ")";
        MenuText += " Select card to load" + PageText + ":\n\n";
        integer I;
        integer WhichChoice = 1;
        for(I = P1; I <= P2 && I < CardsListSize; I++) {
            MenuText += "   " + (string)WhichChoice + ": " + llList2String(CardsList, I) + "\n";
            Buttons += (string)WhichChoice;
            WhichChoice++;
        }
        while(I <= P2) {
            Buttons += " ";
            I++;
        }
        if (P1 > 0) Buttons += BUTTON_PREV; else Buttons += " ";
        if (P2 < CardsListSize - 1) Buttons += BUTTON_NEXT; else Buttons += " ";
    }
    else {
        MenuText += "(Empty)";
    }
    Buttons += BUTTON_CANCEL;
    Buttons = llList2List(Buttons, -3, -1) + llList2List(Buttons, -6, -4) + llList2List(Buttons, -9, -7) + llList2List(Buttons, -12, -10);
    llDialog(MenuAvId, MenuText, Buttons, MenuChannel);
}
MenuInit(key AvId) {
    MenuAvId = AvId;
    MenuChannel = -1000 - (integer)llFrand(100000000.0);
    MenuListener = 0;
    LoadList();
}
MenuTerminate() {
    MenuAvId = NULL_KEY;
    if (MenuListener) llListenRemove(MenuListener);
    MenuListener = 0;
}
LoadList() {
    MenuPage = 0;
    CardsList = [];
    integer Len = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer I;
    for(I = 0; I < Len; I++) {
        string Name = llGetInventoryName(INVENTORY_NOTECARD, I);
        if (NotecardNameValid(Name)) CardsList += Name;
    }
    CardsListSize = llGetListLength(CardsList);
    MenuPageCount = ((CardsListSize - 1)/ MENU_PAGE_SIZE) + 1;
}
ClearScene() {
    llRegionSay(COMM_CHANNEL, "deleteAll");
    llRegionSay(PANTO_REZZOR_CHANNEL, "deleteAll");
    llRegionSay(TAPE_CHANNEL, "self_remove");
}
// Return FALSE if "Name" is not a loadable notecard
integer NotecardNameValid(string Name) {
    if (Name == ADMINS_NOTECARD) return FALSE;
    return TRUE;
}
// Return true if avatar is administrator
integer IsAdmin(key AvId) {
    if (AvId == OwnerId) return TRUE;
    string ThisName = llToUpper(llKey2Name(AvId));
    if (llGetInventoryType(ADMINS_NOTECARD) != INVENTORY_NOTECARD) return TRUE;    // if the notecard doesn't exist, allow it
    integer AdminsCount = osGetNumberOfNotecardLines(ADMINS_NOTECARD);
    while(AdminsCount--) {
        string Name = llToUpper(llStringTrim(osGetNotecardLine(ADMINS_NOTECARD, AdminsCount), STRING_TRIM));
        if (Name == ThisName) return TRUE;
    }
    return FALSE;
}
// Send message to all avatars
BroadcastMessage(string Text) {
    list AvIds = llGetAgentList(AGENT_LIST_REGION, []);
    integer AvsCount = llGetListLength(AvIds);
    integer A;
    for(A = 0; A < AvsCount; A++) {
        llRegionSayTo(llList2Key(AvIds, A), 0, Text);
    }
}
default {
    on_rez(integer Param) { llResetScript(); }
    state_entry() {
        OwnerId = llGetOwner();
        MenuPrim = ClearPrim = -1;
        integer PrimCount = llGetNumberOfPrims();
        integer P;
        for (P = 2; P <= PrimCount; P++) {
            if (llGetLinkName(P) == MENU_PRIM_NAME) MenuPrim = P;
            else if (llGetLinkName(P) == CLEAR_PRIM_NAME) ClearPrim = P;
        }
        if (MenuPrim == -1) {
            llOwnerSay("Can't find prim named '" + MENU_PRIM_NAME + "'");
        }
        if (ClearPrim == -1) {
            llOwnerSay("Can't find prim named '" + CLEAR_PRIM_NAME + "'");
        }
        ButtonsActive = TRUE;
    }
    touch_start(integer Count) {
        if (ButtonsActive) {
            while(Count--) {
                key AvId = llDetectedKey(Count);
                integer ClickPrim = llDetectedLinkNumber(Count);
                if (ClickPrim == MenuPrim) {    // they've clicked the "notecard" prim
                    MenuInit(AvId);
                    MenuShow();
                }
                else if (ClickPrim == ClearPrim) {
                    ClearScene();
                }
            }
        }
    }
    listen(integer Channel, string Name, key Id, string Message) {
        if (Channel == MenuChannel && Id == MenuAvId) {
            if (Message == BUTTON_PREV) {
                if (MenuPage > 0) MenuPage--;
                MenuShow();
            }
            else if (Message == BUTTON_NEXT) {
                if (MenuPage < (MenuPageCount -1)) MenuPage++;
                MenuShow();
            }
            else if (Message == BUTTON_CANCEL) {
                MenuTerminate();
            }
            else {
                integer C = (integer)Message;
                if (C) {
                    BroadcastMessage("Loading scene, please wait ...");
                    ClearScene();
                    llSleep(0.4);
                    integer CardPtr = (MenuPage * MENU_PAGE_SIZE) + C - 1;
                    string NotecardName = llList2String(CardsList, CardPtr);
                    integer Len = osGetNumberOfNotecardLines(NotecardName);
                    integer LineNum;
                    for (LineNum = 0; LineNum < Len; LineNum++) {
                        string Data =  osGetNotecardLine(NotecardName, LineNum);
                        if (Data != "") {
                            // Following code copied from Controller Root and edited to work here
                            list my_list = llParseString2List(Data,["%"],[""]);
                            vector placeItHere = (vector)llList2String(my_list,1)*llGetRot()+llGetPos();
                            rotation orientItSo = (rotation)llList2String(my_list,2)*llGetRot();
                            integer objectPinIndex = (integer) llList2String(my_list,3);
                            llRegionSay(PANTO_REZZOR_CHANNEL,(string) llList2String(my_list,0)+"%"+(string)((placeItHere-llGetPos())/llGetRot())+"%"+(string)(orientItSo/llGetRot())+"%"+(string)objectPinIndex);
                            // End of copied code
                            llSleep(0.35);    // delay to avoid overburdening the rezzer
                        }
                    }
                    MenuTerminate();
                    BroadcastMessage("Scene loaded.");
                    llRegionSay(PANTO_REZZOR_CHANNEL,"resetRezzor");
                    // Disable buttons for a short term to clear any touch events (in case they've been clicking)
                    ButtonsActive = FALSE;
                    llSetTimerEvent(0.4);
                }
            }
        }
    }
    timer() {
        llSetTimerEvent(0.0);
        ButtonsActive = TRUE;
    }
    changed(integer Change) {
        if (Change & CHANGED_LINK) llResetScript();
        if (Change & CHANGED_OWNER) llResetScript();
    }
}
// RezMela notecard picker v0.4