// HUD communicator v1.11.7

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

// v1.11.7 - replaced UUID by NULL_KEY to fix deleted scene not updating HUD
// v1.11.6 - send HUD server messages direct to prim
// v1.11.5 - add HideOptions
// v1.11.4 - disguise hard-coded dummy UUID
// v1.11.3 - static and dynamic object data separated
// v1.11.2 - take debug status from object description
// v1.11.1 - reduce memory usage when idle
// v1.11.0 - prevent duplicate SFM lists on save
// v1.10 - keep HUD locked until scene has finally saved
// v1.9 - handle LM_OBJECTS_COUNT even when idle
// v1.8 - better handling of modules errors
// v1.7 - bug fix (main menu after clone)
// v1.6 - many changes for apps in apps
// v1.5 - add "resizable" processing to suppress Resize button where necessary
// v1.4 - no changes (issued in error)
// v1.3 - fix bug in Climate setting
// v1.2 - object description in selection status; Advanced menu; new error handler
// v1.1 - add failure method
// v1.0 - processing for errors reported by cataloguer, fix deadlock when no modules
// v0.32 - support for new modules maintenance
// v0.31 - added bespoke back button
// v0.30 - more efficient fix for 0.29; version number SNAFU
// v0.29 - bug fix (see ML v0.151); add "terrainchange"
// v0.28 - add import/export of save files
// v0.27 - configurable nudge button labels
// v0.26 - jump mode
// v0.25 - camera control, logout button
// v0.24 - environment bug fixing
// v0.23 - clear random status on log in/out
// v0.22 - environment processing
// v0.21 - add debug feature
// v0.20 - better reporting of duplicates
// v0.19 - add display of nudge value when nudge menu first opened
// v0.18 - added camera pos and rot to nudge; added status line to nudge; changed save scene text
// v0.17 - added + and - distance to nudge menu
// v0.16 - added "nudge" menu, various other changes for Maps
// v0.15 - changed Random hotkey from CONTROL_UP to CONTROL_LEFT
// v0.14 - additional fields in object config card
// v0.13 - bug fix, add integrity check, some refactoring
// v0.12 - introduction of cataloguer to streamline library module handling
// v0.11 - add "autohide" feature
// v0.10 - selected object menu returns to last position; load scene warning
// v0.9 - bug fixes/improvements
// v0.8 - notes from MLO config cards
// v0.7 - distributed libraries
// v0.6 - added "random" toggle
// v0.5 - more bug fixes
// v0.4 - bug fixes & improvements
// v0.3 - add parent data
// v0.2 - fixed bugs

// This goes in the ML root prim, and communicates between the ML main scripts and the RezMela HUD

integer HUD_CHAT_GENERAL = -192801290;

string HUD_STRINGS = "HUD strings";
string MODULE_EDIT_LOCK = "Module lock";
string EN_DASH = "-";
integer DEBUGGER = -391867620;
string HUD_PRIM_NAME = "!Activator!";

integer COM_RESET = -8172620;    // for external reset (eg a "reset" button)

integer LM_PRIM_SELECTED = -405500;        // A prim has been selected
integer LM_PRIM_DESELECTED = -405501;    // A prim has been deselected
integer LM_EXECUTE_COMMAND = -405502;    // Execute command (from other script)
integer LM_OUTSOURCE_COMMAND = -405510;
integer LM_RANDOM_CREATE = -405518;
integer LM_RANDOM_VALUES = -405519;
integer LM_EXTERNAL_LOGIN = -405521;
integer LM_EXTERNAL_LOGOUT = -405522;
integer LM_EXTERNAL_DESELECT = -405523;
integer LM_LIBRARY = -405531;
integer LM_AUTOHIDE_SET  = -405532; // to ML: hide/unhide commands
integer LM_RESET = -405535;
integer LM_TASK_COMPLETE = -405536;
integer LM_HUD_STATUS = -405543;
integer LM_NUDGE_STATUS = -405544;
integer LM_PUBLIC_DATA = -405546;
integer LM_CAMERA_JUMP_MODE =  -405547;
integer LM_OBJECTS_COUNT = -405548;
integer LM_FAILURE = -405549;
integer LM_CHANGE_CONFIG = -405551;

// Scene file manager
integer SFM_EXPORT = -3310426;

// Environment commands
integer ENV_RESET = -79301900;
integer ENV_SET_VALUE = -79301901;
integer ENV_STORE_VALUE = -79301902;
integer ENV_STATUS = -79301903;
integer ENV_DONE = -79301904;

key AvId;
key MyUuid;
integer HudActive = FALSE;
integer DebugMode = FALSE;

// HUD API linked messages
integer HUD_API_MAX = -4720600;    // Minimum value in this set (but negative)
integer HUD_API_LOGIN = -47206000;
integer HUD_API_LOGOUT = -47206001;
integer HUD_API_GET_METADATA = -47206002;
integer HUD_API_SET_METADATA = -47206003;
integer HUD_API_CREATE_WINDOW_BUTTONS = -47206004;
integer HUD_API_CREATE_WINDOW_LIST = -47206005;
integer HUD_API_CREATE_WINDOW_CUSTOM = -47206006;
integer HUD_API_CREATE_WINDOW_STATUS = -47206007;
integer HUD_API_CREATE_WINDOW_ALERT  = -47206008;
integer HUD_API_CREATE_WINDOW_IMAGETEXT  = -47206009;
integer HUD_API_DISPLAY_WINDOW = -47206020;
integer HUD_API_CLICK_BUTTON = -47206021;
integer HUD_API_CLICK_LIST = -47206022;
integer HUD_API_READY = -47206023;
integer HUD_API_BACK_BUTTON = -47206024;
integer HUD_API_DESTROY_WINDOW = -47206025;
integer HUD_API_TAKE_CONTROL = -47206030;
integer HUD_API_TRACK_CAMERA = -47206031;
integer HUD_API_CURRENT_WINDOW = -47206040;
integer HUD_API_STATUS_LINE = -47206050;
integer HUD_API_CAMERA_JUMP_MODE = -47206051;
integer HUD_API_BESPOKE = -47206060;
integer HUD_API_RESET = -47206061;
integer HUD_API_MIN = -47206099;    // Maximum value in this set (but negative)

string HUD_API_SEPARATOR_1 = "|";
string HUD_API_SEPARATOR_2 = "^";

// Librarian linked messages
integer LIB_GET_DATA = -779189100;
integer LIB_REPORT         = -879189110;

// Save file manager linked messages
integer SFM_LIST = -3310420;
integer SFM_LOAD = -3310421;
integer SFM_SAVE = -3310422;
integer SFM_DELETE = -3310423;
integer SFM_SAVE_COMPLETE = -3310425;

// Cataloguer LMs
integer CT_REQUEST_DATA    = -83328400;
integer CT_CATALOG = -83328401;
integer CT_START = -83328402;
integer CT_ARRANGE_PRIMS = -83328405;
integer CT_ERRORS = -83328406;

// Error handler LMs
integer ERR_SET_USER = -188137420;
integer ERR_SET_EMAIL = -188137421;

list Categories;
integer CAT_NAMESTRING = 0;
integer CAT_PARENT = 1;    // -1 if top level, otherwise pointer to parent category
integer CAT_STRIDE = 2;
integer CategoriesCount;

list LibraryObjects;
integer OBJ_CATEGORY = 0;    // pointer to Categories table (row, not element)
integer OBJ_NAME = 1;
integer OBJ_STRIDE = 2;
integer LibraryObjectsCount;

// This is metadata for objects, in a separate table for efficiency during population
list MetaData;
integer MD_NAME = 0;    // Name prepended by "~" to make it searchable (avoid conflict with other strings)
integer MD_LIBKEY = 1;
integer MD_SHORTDESC = 2;
integer MD_LONGDESC64 = 3;
integer MD_THUMBNAIL = 4;
integer MD_PREVIEW = 5;
integer MD_RANDOM_ROTATE = 6;
integer MD_RANDOM_RESIZE = 7;
integer MD_DETACHED = 8;
integer MD_AUTOHIDE = 9;
integer MD_SOURCE64 = 10;
integer MD_RESIZABLE = 11;
integer MD_STRIDE = 12;

list SaveFiles;    // list of saved files

string DeleteSaveFile; // filename of a save about to be deleted

integer CategoryWindowsCreated = FALSE;
integer CurrentCategory;
string OldSaveString;
string OldObjectsHash;
integer MenuChannel;
integer MenuListener;

integer RandomButtonOn;
integer CreateModeOn;
integer IsObjectSelected;
string SelectedDesc;    // short description of selected object
integer SelectedResizable;    // is selected object resizable?
string WindowWhenSelected;    // the name of the active window when an object is selected
integer DisableCreateMenu;

string LoadSceneName;
integer LoadSceneCreateGroup;

integer NextCategoryRow = 0;    // global because LSL can't pass references to variables into functions

integer CameraTracking;
integer SceneObjectsCount = 0;

// Public data from ML
integer EnvironmentalChange = FALSE;    // Can user change environment settings?
integer AdvancedMenu = FALSE;
string CheckboxOn = "!";
string CheckboxOff = "?";
integer TerrainChange = FALSE;
list HideOptions = [];

key ParentId = NULL_KEY;

list HudStrings;
string BackButtonChar;

list CurrentInventory;
integer Importing;

string DEGREES_SYMBOL = "°";
//string NUDGE_N = "▲";
//string NUDGE_S = "▼";
//string NUDGE_W = "◀";
//string NUDGE_E = "▶";
//string NUDGE_U = "↥";
//string NUDGE_D = "↧";
//string NUDGE_DISTANCE_UP = "Amount +";
//string NUDGE_DISTANCE_DOWN = "Amount -";

string LibraryErrorsText = "";

ShowCategories() {
    if (!CheckLibraryIntegrity()) return;
    DisplayWindow("makecats");
    MakeCreateWindows();
    CurrentCategory = -1;
    DisplayCreateWindow();
}
// Reference is in format "cat:<n>" where <n> is category number, or "obj:<name>" where <name> is object name
SelectFromReference(string Reference) {
    string RefType = llGetSubString(Reference, 0, 2);
    string Payload = llGetSubString(Reference, 4, -1);
    if (RefType == "cat") {
        CurrentCategory = (integer)Payload;
        DisplayCreateWindow();
    }
    else if (RefType == "obj") {
        CreateObject((integer)Payload);
    }
    else {
        llDialog(AvId, "Invalid reference type: " + RefType, [ "OK" ], -19202202);
    }
}
CreateObject(integer ObjectNum) {
    string ObjectReference = "obj:" + (string)ObjectNum;
    integer OP = ObjectNum * OBJ_STRIDE;
    integer Category = llList2Integer(LibraryObjects, OP + OBJ_CATEGORY);
    string ObjectName = llList2String(LibraryObjects, OP + OBJ_NAME);
    integer MP = llListFindList(MetaData, [ "~" + ObjectName ]);
    if (MP == -1) {
        llDialog(AvId, "Error in library!\nCan't find metadata for object: " + ObjectName, [ "OK" ], -99999);
        return;
    }
    MP -= MD_NAME;    // position at start of stride
    string ShortDesc = llList2String(MetaData, MP + MD_SHORTDESC);
    key ThumbnailId = llList2Key(MetaData, MP + MD_THUMBNAIL);
    key PreviewId = llList2Key(MetaData, MP + MD_PREVIEW);
    float RandomResize = llList2Float(MetaData, MP + MD_RANDOM_RESIZE);
    integer RandomRotate = llList2Integer(MetaData, MP + MD_RANDOM_ROTATE);
    string LongDesc = "Sorry, no description available";
    string tLongDesc = llBase64ToString(llList2String(MetaData, MP + MD_LONGDESC64));
    if (tLongDesc != "") LongDesc = tLongDesc;
    llMessageLinked(LINK_ROOT, LM_RANDOM_VALUES, llDumpList2String([ RandomResize, RandomRotate ], "|"), NULL_KEY);
    SendCommandToML("create " + ObjectName);
    CreateWindowImageText(ObjectReference, "cat:" + (string)Category, "Create " + ShortDesc, TRUE, PreviewId, LongDesc);
    DisplayWindow(ObjectReference);
    CreateModeOn = TRUE;
    TakeControls(TRUE);
}
BackCategory() {
    if (CurrentCategory == -1) { // if we're on the top level
        MainWindow();
        return;
    }
    integer Ptr = CurrentCategory * CAT_STRIDE;    // point to our row in the table
    integer ParentCat = llList2Integer(Categories, Ptr + CAT_PARENT);
    CurrentCategory = ParentCat;
    DisplayCreateWindow();
}
BackObject() {
    SendCommandToML("nocreate");
    DisplayCreateWindow();
}
DisplayCreateWindow() {
    DisplayWindow("cat:" + (string)CurrentCategory);
}
MakeCreateWindows() {
    if (CategoryWindowsCreated) return;    // prevent being run twice during same session
    CategoryWindowsCreated = TRUE;
    integer Cat;
    for (Cat = -1; Cat < CategoriesCount; Cat++) {
        string CategoryName = GetCategoryFullName(Cat);
        string Tag = "cat:" + (string)Cat;
        if (CategoryName == "") CategoryName = "Categories {Cat.}";
        integer ParentNum = GetCategoryParentNum(Cat);
        string ParentTag = "home";
        if (Cat > -1) ParentTag = "cat:" + (string)ParentNum;
        //llOwnerSay("Doing cat: " + Tag + " (" + CategoryName + ") - parent: " + ParentTag);///%%%
        list ListEntries = [];
        if (llListFindList(Categories, [ Cat ]) > -1) { // if sub-categories exist
            integer Sub;
            for (Sub = 0; Sub < CategoriesCount; Sub++) {
                integer SP = Sub * CAT_STRIDE;    // turn into pointer to element
                if (llList2Integer(Categories, SP + CAT_PARENT) == Cat) {
                    string SubCatFullName = GetCategoryFullName(Sub);
                    string SubCatEntry = TEXTURE_TRANSPARENT + HUD_API_SEPARATOR_2 + SubCatFullName + HUD_API_SEPARATOR_2 + "cat:" + (string)Sub;
                    ///%%%% using transparent texture until HUD allows duplicate textures (if we ever do that?)
                    //string SubCatEntry = FOLDER_ICON + HUD_API_SEPARATOR_2 + SubCatName + HUD_API_SEPARATOR_2 + "cat:" + (string)Sub;
                    ListEntries += SubCatEntry;
                }
            }
        }
        if (llListFindList(LibraryObjects, [ Cat ]) > -1) {    // if objects exist
            integer Obj;
            for (Obj = 0; Obj < LibraryObjectsCount; Obj++) {
                integer OP = Obj * OBJ_STRIDE;
                integer ObjectCat = llList2Integer(LibraryObjects, OP + OBJ_CATEGORY);
                if (ObjectCat == Cat) {
                    string ObjectName = llList2String(LibraryObjects, OP + OBJ_NAME);
                    integer MP = llListFindList(MetaData, [ "~" + ObjectName ]);
                    if (MP == -1) {
                        llDialog(AvId, "Error in library!\nCan't find metadata for object: " + ObjectName, [ "OK" ], -99999);
                        return;
                    }
                    MP -= MD_NAME;    // position at start of stride
                    string ShortDesc = llList2String(MetaData, MP + MD_SHORTDESC);
                    key ThumbnailId = llList2Key(MetaData, MP + MD_THUMBNAIL);
                    string ObjectEntry = (string)ThumbnailId + HUD_API_SEPARATOR_2 + ShortDesc + HUD_API_SEPARATOR_2 + "obj:" + (string)Obj;
                    ListEntries += ObjectEntry;
                }
            }
        }
        if (ListEntries != []) CreateWindowListThumbs(Tag, ParentTag, CategoryName, TRUE, ListEntries);
    }
}
integer CheckLibraryIntegrity() {
    integer IsOK = TRUE;
    // First, check that all objects have metadata and are unique
    list ObjectsFound = [];
    integer LLen = llGetListLength(LibraryObjects);
    integer MLen = llGetListLength(MetaData);
    if (LibraryObjectsCount * OBJ_STRIDE != LLen) {
        llOwnerSay("Library objects count incorrect!");
        IsOK = FALSE;
    }
    integer L;
    for (L = 0; L < LLen; L += OBJ_STRIDE) {
        string ObjectName = llList2String(LibraryObjects, L + OBJ_NAME);
        if (llListFindList(MetaData, [ "~" + ObjectName ]) == -1) {
            llOwnerSay("Missing metadata for object: '" + ObjectName + "'");
            IsOK = FALSE;
        }
        if (llListFindList(ObjectsFound, [ ObjectName ]) > -1) {
            llOwnerSay("Duplicate library entry for object: '" + ObjectName + "'");
            llMessageLinked(LINK_SET, LIB_REPORT, ObjectName, AvId);    // Tell all modules to report if they contain the object
            IsOK = FALSE;
        }
        ObjectsFound += ObjectName;
    }
    if (!IsOK) return FALSE;    // Don't go further if we have errors
    // Next check that all metadata has corresponding library objects  and is unique
    ObjectsFound = [];
    integer M;
    for (M = 0; M < MLen; M += MD_STRIDE) {
        string ObjectName = llGetSubString(llList2String(MetaData, M + MD_NAME), 1, -1);     // substr to remove "~"
        if (llListFindList(LibraryObjects, [ ObjectName ]) == -1) {
            llOwnerSay("Missing library entry for metadata: '" + ObjectName + "'");
            IsOK = FALSE;
        }
        if (llListFindList(ObjectsFound, [ ObjectName ]) > -1) {
            llOwnerSay("Duplicate metadata entry for object: '" + ObjectName + "'");
            IsOK = FALSE;
        }
        ObjectsFound += ObjectName;
    }
    if (IsOK && (LLen / OBJ_STRIDE != MLen / MD_STRIDE))    {
        llOwnerSay("Objects/Metadata length mismatch");
        IsOK = FALSE;
    }
    return IsOK;
}
string ResizeLabel(integer Bigger, integer Percent) {
    string Direction = EN_DASH;
    if (Bigger) Direction = "+";
    return Direction + (string)Percent + "%";
}
ResizeObject(string Label) {
    string Sign = llGetSubString(Label, 0, 0);
    integer ChangePercent = (integer)llGetSubString(Label, 1, -2);    // Numeric part without % symbol or preceding +/-
    if (Sign == EN_DASH) ChangePercent *= -1;    // we use en dash for negative symbol
    if (Label == "Random") ChangePercent = -10 + (integer)llFrand(20.0);        // between -10% and +10%
    SendCommandToML("resize " + (string)ChangePercent);
}
string RotateLabel(integer Clockwise, integer Degrees) {
    string Direction = EN_DASH;
    if (Clockwise) Direction = "+";
    return Direction + (string)Degrees + DEGREES_SYMBOL;
}
RotateObject(string Label) {
    string Sign = llGetSubString(Label, 0, 0);
    integer Degrees = (integer)llGetSubString(Label, 1, -2);    // Numeric part without % symbol or preceding +/-
    if (Sign == EN_DASH) Degrees *= -1;
    if (Label == "Random") Degrees = -180 + (integer)llFrand(360.0);    // between -180 and +180
    SendCommandToML("rotate " + (string)Degrees);
}
ProcessNudge(string Label, vector CameraPos, rotation CameraRot) {
    string Command = "?";
    string ButtonName = HudStringValue2Name(Label);
    // Button name is in the format "btnNudgeX" where "X" is the direction
    Command = llGetSubString(ButtonName, -1, -1); // Command is the last char of the button name
    SendCommandToML("nudge " + llDumpList2String([ Command, CameraPos, CameraRot ], "|"));
}
RemoveSelectedObject() {
    SendCommandToML("remove");
}
CloneSelectedObject () {
    SendCommandToML("clone");
}
TeleportToObject() {
    SendCommandToML("tp");
}
ZoomToObject() {
    SendCommandToML("zoom");
}
ClearScene() {
    DisplayWindow("clearingall");
    SendCommandToML("clearall");
    SetEnvironment("resetall");
}
Deselect() {
    SendCommandToML("deselect");
    // ML will echo back that page is deselected, triggering main menu
}
// Returns TRUE if the window name is one of the "selected" windows
// ie "selectedr" or "selectednr"
integer IsSelectedWindow(string WindowName) {
    return (llGetSubString(WindowName, 0, 7) == "selected");
}
StartLoad(string Name, integer CreateGroup) {
    DisplayWindow("loadscene");
    LoadSceneName = Name;
    LoadSceneCreateGroup = CreateGroup;
}
DoLoad() {
    CreateWindowStatus("loadingstatus", "Load", [ "Loading scene ..." ]);
    DisplayWindow("loadingstatus");
    if (LoadSceneCreateGroup)
        SendCommandToML("creategroup " + LoadSceneName);
    else
        SendCommandToML("load " + LoadSceneName);
}
Export(string Name) {
    llMessageLinked(LINK_ALL_CHILDREN, SFM_EXPORT, Name, AvId);
    MainWindow();
}
StartImport() {
    // Build up list of all items in inventory
    CurrentInventory = [];
    integer N = llGetInventoryNumber(INVENTORY_ALL);
    while (N--) {
        CurrentInventory += llGetInventoryName(INVENTORY_ALL, N);
    }
    CreateWindowAlert("import", "Import a scene", [
        "Use Ctrl and the left mouse",
        "button to drag the scene",
        "file(s) onto the App.",
        "",
        "When you see a red outline",
        "on the App, release the",
        "mouse button."
            ], [ "Cancel" ]);
    DisplayWindow("import");
    Importing = 1;
    llAllowInventoryDrop(TRUE);
}
DoImport() {
    llAllowInventoryDrop(FALSE);
    Importing = 2;
    // Loop through contents, looking for things that weren't here before
    list NewInventory = [];
    integer N = llGetInventoryNumber(INVENTORY_ALL);
    while (N--) {
        string Name = llGetInventoryName(INVENTORY_ALL, N);
        if (llListFindList(CurrentInventory, [ Name ]) == -1) {
            NewInventory += Name;
        }
    }
    // Inventory now contains list of new items
    key SfmKey = llGetLinkKey(SfmLinkNum());
    N = llGetListLength(NewInventory);
    while (N--) {
        string Name = llList2String(NewInventory, N);
        if (llGetInventoryType(Name) == INVENTORY_NOTECARD) {
            llGiveInventory(SfmKey, Name); // llGiveInventoryList not implemented in OpenSim
        } // else we ignore it - they've dropped in something that's not a notecard, so we just delete it
        llRemoveInventory(Name);
    }
    llSay(0, "Imported: " + llList2CSV(NewInventory)); // Have to use llSay because we don't know who dropped them
    Importing = 0;
    MainWindow();
    CurrentInventory = [];
    llMessageLinked(LINK_ALL_CHILDREN, SFM_LIST, "", NULL_KEY);
}
CancelImport() {
    llAllowInventoryDrop(FALSE);
    Importing = 0;
    MainWindow();
    CurrentInventory = [];
}
StartSave() {
    MenuListener = llListen(MenuChannel, "", AvId, "");
    llTextBox(AvId, "\n\nEnter a name for your scene or leave empty to cancel:\n", MenuChannel);
    CreateWindowAlert("savealert", "Saving scene", [
        "Enter a name for your scene",
        "in the blue dialog to the",
        "right of your screen.",
        "",
        "Leave the name blank to",
        "cancel the save.",
        "",
        "Click 'Retry' if the blue",
        "dialog is not there."
            ], [ "Retry" ]);
    CreateWindowStatus("savestatus", "Saving", [ "Saving scene ..." ]);
    DisplayWindow("savealert");
}
EndSave(string NotecardName) {
    if (NotecardName == "") {
        MainWindow();
        return;
    }
    if (!ValidNotecardName(NotecardName)) {
        CreateWindowStatus("invalidname", "Invalid name", [ "The name you have", "entered is not a", "valid name. Please", "try again." ]);
        DisplayWindow("invalidname");
        llSleep(5.0);
        StartSave();
        return;
    }
    DisplayWindow("savestatus");
    llListenRemove(MenuListener);
    SendCommandToML("save " + NotecardName);
}
DeleteSavePrompt(string NotecardName) {
    DeleteSaveFile = NotecardName;
    CreateWindowAlert("deleteprompt", "Delete saved scene", [ "Are you sure you want to", "delete the scene:", DeleteSaveFile ], [ "*Delete", "Cancel" ]);
    DisplayWindow("deleteprompt");
}
DeleteSave() {
    CreateWindowStatus("deletestatus", "Delete", [ "Scene deleted:", DeleteSaveFile ]);
    llMessageLinked(SfmLinkNum(), SFM_DELETE, DeleteSaveFile, NULL_KEY); // NULL_KEY needs to be sent so that Scene file management script updates displayed list of available scenes
    DisplayWindow("deletestatus");
    llSleep(5.0);
    DestroyWindow("deletestatus");
    MainWindow();
}
integer ValidNotecardName(string NotecardName) {
    if (NotecardName == "") return FALSE;
    if (llSubStringIndex(NotecardName, HUD_API_SEPARATOR_1) > -1) return FALSE;
    if (llSubStringIndex(NotecardName, HUD_API_SEPARATOR_2) > -1) return FALSE;
    // For underscores, we have different rules for child (app-in-app) apps. They shouldn't
    // be able to create presets (whose name begins with underscore), but non-child apps can.
    // Additionally, neither should allow underscores beyond the first character, since there's
    // the possibility it would interfere with multi-notecard saves (which have _001, _002, etc
    // appended)
    if (ParentId == NULL_KEY) {
        if (llSubStringIndex(NotecardName, "_") > 0) return FALSE;    // _ at beginning only
    }
    else {
        if (llSubStringIndex(NotecardName, "_") > -1) return FALSE;    // _ is invalid anywhere
    }
    return TRUE;
}
MainWindow() {
    if (ModuleLockExists()) {
        ModulesMode(TRUE);
        return;
    }
    // Home page
    MakeMainWindow();
    DisplayWindow("home");
    WindowWhenSelected = "home";
}
MakeMainWindow() {
    list HomeButtons = [ "File", "Create", "Clear" ];
    if (EnvironmentalChange) HomeButtons += "Climate";
    HomeButtons += [ "Settings", "Finish" ];
    if (AdvancedMenu) HomeButtons += "Advanced";
    CreateWindowButtons("home", "", "Home", FALSE, HomeButtons);
}
SelectedWindow() {
    if (SelectedResizable)
        DisplayWindow("selectedr");
    else
        DisplayWindow("selectednr");
}
SetRandom(integer On, integer Display) {
    RandomButtonOn = On;
    llMessageLinked(LINK_ROOT, LM_RANDOM_CREATE, (string)RandomButtonOn, AvId);
    if (Display) DisplaySettingsMenu();
}
SetAutoHide(integer Hide) {
    llMessageLinked(LINK_ROOT, LM_AUTOHIDE_SET, (string)Hide, NULL_KEY);
}
Reset() {
    HudStatus("");
    SendHud(HUD_API_RESET, []);
    llMessageLinked(LINK_SET, LM_RESET, "", NULL_KEY);
}
integer ReadObjectsList(string ObjectData) {
    integer OK = TRUE;
    list Lines = llParseStringKeepNulls(ObjectData, [ "\n" ], []);
    string Hash = llSHA1String(ObjectData);
    if (Hash == OldObjectsHash) return TRUE;    // nothing changed
    OldObjectsHash = Hash;
    integer ObjectCategory = -1;
    NextCategoryRow = 0;
    Categories = [];
    LibraryObjects = [];
    integer Len = llGetListLength(Lines);
    integer Ptr;
    for (Ptr = 0; (Ptr < Len && OK); Ptr++) {
        string Line = llStringTrim(llList2String(Lines, Ptr), STRING_TRIM);
        if (Line != "") {
            if (llGetSubString(Line, 0, 0) == "[" && llGetSubString(Line, -1, -1) == "]") {
                string CategoryPath = llStringTrim(llGetSubString(Line, 1, -2), STRING_TRIM);    // extract category string from [string]
                if (CategoryPath == "") OK = ObjectsListError("Empty category definition", Ptr, Line);
                list CategoryNodes = llParseStringKeepNulls(CategoryPath, [ "/" ], [ "" ]);    // convert "abc/def/ghi" to [ "abc", "def", "ghi" ]
                ObjectCategory = SetUpCategory(-1, CategoryNodes);
            }
            else {    // it's an object
                if (ObjectCategory == -1) {
                    OK = ObjectsListError("Object not in category section", Ptr, Line);
                }
                else {
                    list Parts = llParseStringKeepNulls(Line, [ "|" ], []);
                    if (llGetListLength(Parts) == 1) {
                        string ObjectName = llList2String(Parts, 0);
                        LibraryObjects += [ ObjectCategory, ObjectName ];
                    }
                    else {
                        OK = ObjectsListError("Can't parse line", Ptr, Line);
                    }
                }
            }
        }
    }
    LibraryObjectsCount = llGetListLength(LibraryObjects) / OBJ_STRIDE;
    if (CategoriesCount == 0 && LibraryObjectsCount == 0) {
        // If both of these are empty, we assume there are no modules active
        //        CreateWindowStatus("noobjects", "No Objects!", [ "There are no objects.", "", "Please check that", "modules are enabled."]);
        //        DisplayWindow("noobjects");
        //        llSleep(5.0);
        return FALSE;
    }
    if (CategoriesCount == 0) OK = ObjectsListError("No categories!", -1, "");
    if (LibraryObjectsCount == 0) OK = ObjectsListError("No objects!", -1, "");
    return OK;
}
// A recursive function that defines a path of hierarchical categories
integer SetUpCategory(integer Parent, list CategoryNodes) {
    integer NodeCount = llGetListLength(CategoryNodes);
    string TopCatName = llList2String(CategoryNodes, 0);
    // Check if the category already exists (same name + same parent node)
    integer FoundCategory = llListFindList(Categories, [ TopCatName, Parent ]);
    integer ThisRow;
    if (FoundCategory == -1) {    // it's not been defined before
        Categories += [ TopCatName, Parent ];
        CategoriesCount++;
        ThisRow = NextCategoryRow++;
    }
    else {
        ThisRow = FoundCategory / CAT_STRIDE;
    }
    integer CategoryNode;
    if (NodeCount > 1) {        // There are other categories below this one, so recurse
        CategoryNode = SetUpCategory(ThisRow, llList2List(CategoryNodes, 1, -1));
    }
    else {
        CategoryNode = ThisRow;    // it's the final one
    }
    return CategoryNode;
}
string GetCategoryLongName(integer CategoryNum) {
    return GetCategoryNamePart(CategoryNum, TRUE);
}
string GetCategoryShortName(integer CategoryNum) {
    return GetCategoryNamePart(CategoryNum, FALSE);
}
string GetCategoryNamePart(integer CategoryNum, integer Long) {
    string NameString = GetCategoryFullName(CategoryNum);
    integer P1 = llSubStringIndex(NameString, "{");
    if (P1 > -1) {
        integer P2 = llSubStringIndex(NameString, "}");
        if (P2 > P1) {
            if (Long)
                NameString = llStringTrim(llGetSubString(NameString, 0, P1 - 1), STRING_TRIM);
            else
                NameString = llStringTrim(llGetSubString(NameString, P1 + 1, P2 - 1), STRING_TRIM);
        }
    }
    return NameString;
}
string GetCategoryFullName(integer CategoryNum) {
    if (CategoryNum == -1) return "";        // no name for top level
    integer Ptr = CategoryNum * CAT_STRIDE;
    return llList2String(Categories, Ptr + CAT_NAMESTRING);
}
integer GetCategoryParentNum(integer CategoryNum) {
    if (CategoryNum == -1) return -1;        // no parent
    integer Ptr = CategoryNum * CAT_STRIDE;
    return llList2Integer(Categories, Ptr + CAT_PARENT);
}
integer IsCategoryRef(string WindowName) {
    return (llGetSubString(WindowName, 0, 3) == "cat:");
}
integer IsObjectRef(string WindowName) {
    return (llGetSubString(WindowName, 0, 3) == "obj:");
}
// Always returns false because it makes things easier in calling function
integer ObjectsListError(string Message, integer Ptr, string Line) {
    llOwnerSay("Objects list error on Line " + (string)Line + " - " + Message + ":\n" + Line);
    return FALSE;
}
// Parse and store object metadata sent by library cataloguer
ProcessObjectData(string Text) {
    MetaData = [];
    list Lines = llParseStringKeepNulls(Text, [ "\n" ], []);
    integer Size = llGetListLength(Lines);
    integer L;
    for (L = 0; L < Size; L++ ) {
        string Line = llList2String(Lines, L);
        if (Line != "") {
            list Data = llParseStringKeepNulls(Line, [ "|" ], []);
            // format of line is:
            // Static data
            //        ObjectName, // 0
            //        CameraPos, // 1
            //        CameraAltPos,
            //        CameraFocus,
            //        JumpPos,
            //        JumpLookAt, // 5
            //        Phantom,
            //        AutoHide, // 7
            // Dynamic data
            //        LibIndex, // 8
            //        ShortDesc,
            //        LongDescBase64, // 10
            //        ThumbnailId,
            //        PreviewId,
            //        RandomRotate,
            //        RandomResize,
            //        Detached, // 15
            //        Source64,
            //        SizeFactor,
            //        OffsetPos,
            //        OffsetRot,
            //        Sittable, // 20
            //        DoRotation,
            //        DoBinormal,
            //        Center,
            //        AdjustHeight,
            //        DummyMove, // 25
            //        Resizable,
            //        Floating,
            //        IsApp,
            //        StickPoints64,
            //        SnapGrid, // 30
            //        RegionSnap,
            //        CopyRotation // 32otation
            //

            // Static
            string ObjectName = llList2String(Data, 0);
            integer AutoHide = (integer)llList2String(Data, 7);
            // Dynamic
            string LibKey = llList2String(Data, 8);
            string ShortDesc = llList2String(Data, 9);
            string LongDescBase64 = llList2String(Data, 10);
            key ThumbnailId = (key)llList2String(Data, 11);
            key PreviewId = (key)llList2String(Data, 12);
            integer RandomRotate = (integer)llList2String(Data, 13);
            float RandomResize = (float)llList2String(Data, 14);
            integer Detached = (integer)llList2String(Data, 15);
            string SourceBase64 = llList2String(Data, 16);
            integer Resizable = (integer)llList2String(Data, 26);
            // A lot of the incoming fields aren't really used here, more the job of the main script.
            MetaData += [ "~" +
                ObjectName,
                LibKey,
                ShortDesc,
                LongDescBase64,
                ThumbnailId,
                PreviewId,
                RandomRotate,
                RandomResize,
                Detached,
                AutoHide,
                SourceBase64,
                Resizable
                    ];
        }
    }
}
// Certain strings evaluate TRUE, everything else is FALSE
integer String2Bool(string Text) {
    return(llListFindList([ "TRUE", "YES", "1" ], [ llToUpper(Text) ]) > -1);
}
DisplaySettingsMenu() {
    string RandomButton;
    if (RandomButtonOn)
        RandomButton = "Random " + CheckboxOn;
    else
        RandomButton = "Random " + CheckboxOff;
    list Buttons = [ RandomButton, "Reset" ];
    CreateWindowButtons("settings", "home", "Settings", TRUE, Buttons);
    DisplayWindow("settings");
}
DisplayAdvancedMenu() {
    string ClimateButton = "Climate ";
    if (EnvironmentalChange)
        ClimateButton += CheckboxOn;
    else
        ClimateButton += CheckboxOff;
    CreateWindowButtons("advanced", "home", "Advanced", TRUE, [ "Modules", ClimateButton ]);
    DisplayWindow("advanced");
}
ModulesMode(integer IsOn) {
    if (IsOn) {
        if (!ModuleLockExists()) {
            osMakeNotecard(MODULE_EDIT_LOCK, [ llKey2Name(llGetOwner()) ]);
        }
        CreateWindowAlert("modules", "Modules maintenance", [
            "Edit the module prims as needed,",
            "then click 'Done'."
                ], [ "Done" ]);
        DisplayWindow("modules");
        ArrangeModules();
    }
    else {
        if (ModuleLockExists()) llRemoveInventory(MODULE_EDIT_LOCK);
        DestroyWindow("modules");
        DisplaySettingsMenu();
        ArrangeModules();
    }
}
// Send module lock status to cataloguer for it to arrange the prims
ArrangeModules() {
    llMessageLinked(LINK_THIS, CT_ARRANGE_PRIMS, (string)ModuleLockExists(), AvId);
}
integer ModuleLockExists() {
    return (llGetInventoryType(MODULE_EDIT_LOCK) == INVENTORY_NOTECARD);
}
MakeSavesList(list NotecardNames) {
    if (!HudActive) return;    // we don't do anything if the HUD isn't active
    // Because the CreateWindowListPlain expects two entries per line, we need to add a dummy second entry to each line
    SaveFiles = [];
    integer NotecardsCount = llGetListLength(NotecardNames);
    // If there are no notecards, llParseStringKeepNulls (in the calling code) returns a single empty string. This is
    // equivalent to a null list for our purposes (and it used to return an empty list in OpenSim 0.8, but not in SL).
    if (NotecardsCount == 1 && llList2String(NotecardNames, 0) == "") {
        NotecardsCount = 0;
    }
    integer Ptr;
    for (Ptr = 0; Ptr < NotecardsCount; Ptr++) {
        SaveFiles += [ llList2String(NotecardNames, Ptr), "" ];        // list takes the form of pairs: name and tag. If the tag is empty (like here), the name is used.
    }
    string SaveString = llDumpList2String(SaveFiles, "|");
    if (SaveString != "" && SaveString == OldSaveString) return;    // nothing's changed, so do nothing
    OldSaveString = SaveString;
    CreateWindowListPlain("saveload", "saves", "Load saved scene", TRUE, SaveFiles);
    CreateWindowListPlain("saverearrange", "saves", "Rearrange scene", TRUE, SaveFiles);
    CreateWindowListPlain("savedelete", "saves", "Delete saved scene", TRUE, SaveFiles);
    CreateWindowListPlain("saveexport", "saves", "Export saved scene", TRUE, SaveFiles);
}
HandleFailure(string Text) {
    if (AvId == NULL_KEY) { // if no-one logged in, how to get the message to the user?
        llShout(0, Text); // crude but should work
    }
    else {
        CreateWindowAlert("failure", "ERROR", llParseStringKeepNulls(Text, [ "\n" ], []), [ "*OK"    ]);
        DisplayWindow("failure");
    }
}
SendCommandToML(string Command) {
    llMessageLinked(LINK_ROOT, LM_EXECUTE_COMMAND, Command, AvId);
}
TakeControls(integer On) {
    if (On)
        SendHud(HUD_API_TAKE_CONTROL, [ CONTROL_LEFT ]);    // We want to handle PgUp/E
    else
        SendHud(HUD_API_TAKE_CONTROL, [ 0 ]);    // relinquish any controls we have
}
RelinquishControls() {
    if (CreateModeOn) {    // If they were in create mode (ie had the object details window open)
        CreateModeOn = FALSE;    // then relinquish controls
        TakeControls(FALSE);
    }
}
LogIn(key Id) {
    AvId = Id;
    IsObjectSelected = FALSE;
    MenuChannel = -10000 - (integer)llFrand(100000.0);
    llMessageLinked(LINK_ROOT, LM_EXTERNAL_LOGIN, "", AvId);
    SetRandom(FALSE, FALSE);    // Turn off randomisation by default
    SetAutoHide(FALSE);
    llMessageLinked(LINK_ROOT, ERR_SET_USER, "", AvId);
}
LogOut() {
    Deselect();
    HudStatus("");
    SetRandom(FALSE, FALSE);    // Turn off randomisation
    llMessageLinked(LINK_ROOT, LM_EXTERNAL_LOGOUT, "", AvId);
    AvId = NULL_KEY;
    OldSaveString = "";
    OldObjectsHash = "";
    IsObjectSelected = FALSE;
    HudActive = FALSE;
    SetAutoHide(TRUE);
    llMessageLinked(LINK_ROOT, ERR_SET_USER, "", NULL_KEY);
}
integer ReadHudStrings() {
    BackButtonChar = "";
    HudStrings = [];
    if (llGetInventoryType(HUD_STRINGS) != INVENTORY_NOTECARD) {
        llOwnerSay("Missing \"HUD strings\" notecard");
        return FALSE;
    }
    integer Lines = osGetNumberOfNotecardLines(HUD_STRINGS);
    integer I;
    for(I = 0; I < Lines; I++) {
        string Line = osGetNotecardLine(HUD_STRINGS, I);
        integer Comment = llSubStringIndex(Line, "//");
        if (Comment != 0) {    // Not a complete comment line
            if (Comment > -1) Line = llGetSubString(Line, 0, Comment - 1);    // strip from comments characters onwards
            if (llStringTrim(Line, STRING_TRIM) != "") {    // if there's something left after comments are removed
                // Extract name and value from: <name>=<value>, stripping spaces and folding name to lower case
                list L = llParseStringKeepNulls(Line, [ "=" ], [ ]);    // Separate LHS and RHS of assignment
                if (llGetListLength(L) == 2) {    // so there is a "X = Y" kind of syntax
                    string Name = llStringTrim(llList2String(L, 0), STRING_TRIM);
                    string Value = llStringTrim(llList2String(L, 1), STRING_TRIM);
                    string LName = llToLower(Name);
                    // Interpret name/value pairs
                    if (LName == "backbuttonchar") {
                        BackButtonChar = Value;
                    }
                    else {
                        HudStrings += [ Name, "|" + Value ]; // the | prevents finding on the wrong column
                    }
                }
            }
        }
    }
    return TRUE;
}
string HudStringName2Value(string Name) {
    integer Ptr = llListFindList(HudStrings, [ Name ]);
    if (Ptr == -1) return Name;    // If it doesn't exist, show button name instead (shouldn't happen in a perfect world)
    string Value = llGetSubString(llList2String(HudStrings, Ptr + 1), 1, -1);    // Strip out |
    return Value;
}
string HudStringValue2Name(string Value) {
    integer Ptr = llListFindList(HudStrings, [ "|" + Value ]);
    if (Ptr == -1) { LogError("Unknown HUD string: " + Value); return "?"; }
    return llList2String(HudStrings, Ptr - 1);
}
string MenuEntry(string Option) {
    if (llListFindList(HideOptions, [ llToLower(Option) ]) == -1) {
        return Option;
    }
    else {
        return "";
    }
}
// Return button labels in correct sequence
list NudgeButtons() {
    return [
        HudStringName2Value("btnNudge+"),
        HudStringName2Value("btnNudge-"),
        HudStringName2Value("btnNudgeF"),
        HudStringName2Value("btnNudgeB"),
        HudStringName2Value("btnNudgeL"),
        HudStringName2Value("btnNudgeR"),
        HudStringName2Value("btnNudgeN"),
        HudStringName2Value("btnNudgeS"),
        HudStringName2Value("btnNudgeW"),
        HudStringName2Value("btnNudgeE"),
        HudStringName2Value("btnNudgeU"),
        HudStringName2Value("btnNudgeD")
            ];
}
SendBespokeData() {
    list Bespokes = [];
    if (BackButtonChar != "") Bespokes += [ "backbuttonchar", BackButtonChar ];
    SendHud(HUD_API_BESPOKE, Bespokes);
}
integer CheckPrims() {
    if (SfmLinkNum() == LINK_ALL_CHILDREN) {
        llOwnerSay("Scene file prim missing!");
        return FALSE;
    }
    return TRUE;
}
// Get link number of Scene File Manager prim
// Note there is a duplicate in the ML main script
integer SfmLinkNum() {
    // TODO: use osGetLinkNumber when it's available (OS 0.9)
    integer Num = llGetNumberOfPrims();
    integer P;
    for (P = 2; P <= Num; P++) {
        if (llGetLinkName(P) == "&SceneFileManager&") return P;
    }
    return LINK_ALL_CHILDREN;
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
// HUD API functions
CreateWindowButtons(string Name, string Parent, string Heading, integer Back, list Buttons) {
    Debug("Creating buttons window: " + Name);
    SendHud(HUD_API_CREATE_WINDOW_BUTTONS, [ Name, Parent, Heading, Back ] + llDumpList2String(Buttons, HUD_API_SEPARATOR_2));
}
CreateWindowListPlain(string Name, string Parent, string Heading, integer Back, list Elements) {
    Debug("Creating plain list window: " + Name);
    SendHud(HUD_API_CREATE_WINDOW_LIST, [ Name, Parent, Heading, Back, FALSE ] + llDumpList2String(Elements, HUD_API_SEPARATOR_2));
}
CreateWindowListThumbs(string Name, string Parent, string Heading, integer Back, list Elements) {
    Debug("Creating list thumbs window: " + Name);
    SendHud(HUD_API_CREATE_WINDOW_LIST, [ Name, Parent, Heading, Back, TRUE ] + llDumpList2String(Elements, HUD_API_SEPARATOR_2));
}
CreateWindowCustom(string Name, string Parent, string Heading, integer Back, list Blocks) {
    Debug("Creating custom window: " + Name);
    SendHud(HUD_API_CREATE_WINDOW_CUSTOM, [ Name, Parent, Heading, Back ] + llDumpList2String(Blocks, HUD_API_SEPARATOR_2));
}
CreateWindowStatus(string Name, string Heading, list Message) {
    Debug("Creating status window: " + Name);
    SendHud(HUD_API_CREATE_WINDOW_STATUS, [ Name, Heading ] + llDumpList2String(Message, HUD_API_SEPARATOR_2));
}
CreateWindowAlert(string Name, string Heading, list Message, list Buttons) {
    Debug("Creating alert window: " + Name);
    SendHud(HUD_API_CREATE_WINDOW_ALERT, [ Name, Heading ] + llDumpList2String(Message, HUD_API_SEPARATOR_2) + llDumpList2String(Buttons, HUD_API_SEPARATOR_2));
}
CreateWindowImageText(string Name, string Parent, string Heading, integer Back, key TextureId, string Text) {
    Debug("Creating imagetext window: " + Name);
    SendHud(HUD_API_CREATE_WINDOW_IMAGETEXT, [ Name, Parent, Heading, Back ] + llDumpList2String([ TextureId, llStringToBase64(Text) ], HUD_API_SEPARATOR_2));
}
DisplayWindow(string Name) {
    if (Name == "nudge") {
        Debug("Setting nudge distance status");
        llMessageLinked(LINK_ROOT, LM_NUDGE_STATUS, "", NULL_KEY);    // Tell the ML to send us the nudge distance status command so it appears when the menu is opened
        SendHud(HUD_API_TRACK_CAMERA, [ TRUE ]);
        CameraTracking = TRUE;
    }
    else if (CameraTracking){    // note that this won't take effect until they actually open a window (in-HUD navigation doesn't touch this)
        Debug("Ending camera tracking");
        SendHud(HUD_API_TRACK_CAMERA, [ FALSE ]);
        CameraTracking = FALSE;
    }
    Debug("Displaying window: " + Name);
    SendHud(HUD_API_DISPLAY_WINDOW, [ Name ]);
}
DestroyWindow(string Name) {
    Debug("Destroying window: " + Name);
    SendHud(HUD_API_DESTROY_WINDOW, [ Name ]);
}
// Handle click on logout button ("Finish")
LogOutButton() {
    LogOut();
    SendHud(HUD_API_LOGOUT, []);
    state Idle;
}
SendMetaData() {
    SendHud(HUD_API_SET_METADATA, [ "RezMela" ]);
}
SendHud(integer Command, list Parts) {
    integer HudLinkNum = osGetLinkNumber(HUD_PRIM_NAME);
    if (HudLinkNum == -1) {
        llOwnerSay("Can't find HUD prim (name is '" + HUD_PRIM_NAME + ")");
        HudLinkNum = LINK_ALL_CHILDREN;
    }
    llMessageLinked(HudLinkNum, Command, llDumpList2String(Parts, HUD_API_SEPARATOR_1), AvId);
}
// Send command and data to environment script
SetEnvironment(string Parameter) {
    llMessageLinked(LINK_ROOT, ENV_SET_VALUE, Parameter, AvId);
}
// Set environment HUD status
EnvironmentStatus(string Type) {
    llMessageLinked(LINK_ROOT, ENV_STATUS, Type, NULL_KEY);
}
// Process public data sent by ML
ParsePublicData(string Data) {
    list Parts = llParseStringKeepNulls(Data, [ "|" ], []);
    EnvironmentalChange = (integer)llList2String(Parts, 0);
    CheckboxOn = llList2String(Parts, 3);
    CheckboxOff = llList2String(Parts, 4);
    TerrainChange = (integer)llList2String(Parts, 5);
    AdvancedMenu = (integer)llList2String(Parts, 9);
    string ErrorEmail = llList2String(Parts, 10);
    ParentId = (key)llList2String(Parts, 12);
    string HideOptionsString = llList2String(Parts, 14);
    HideOptions = llCSV2List(HideOptionsString);
    llMessageLinked(LINK_ROOT, ERR_SET_EMAIL, ErrorEmail, NULL_KEY);
}
// Send data to HUD's status bar
HudStatus(string Text) {
    llMessageLinked(LINK_SET, LM_HUD_STATUS, Text, NULL_KEY);
}
MessageUser(string Text) {
    string Name = llGetObjectName();
    llSetObjectName("");
    llRegionSayTo(AvId, 0, Text);
    llSetObjectName(Name);
}
LogError(string Text) {
    llMessageLinked(LINK_ROOT, -7563234, Text, AvId);
}
Debug(string Text) {
    if (DebugMode) llOwnerSay("HCom: " + Text);
    llRegionSay(DEBUGGER, "HCom: " + Text);
}
// Set debug mode according to root prim description
SetDebug() {
    if (llGetObjectDesc() == "debug") {
        DebugMode = TRUE;
    }
}
DebugDump() {
    llOwnerSay("Categories:");
    integer Count = llGetListLength(Categories) / CAT_STRIDE;
    integer C;
    for (C = 0; C < Count; C++) {
        integer P = C * CAT_STRIDE;
        llOwnerSay((string)C + ": " + llList2CSV(llList2List(Categories, P, P + CAT_STRIDE - 1)));
    }
    llOwnerSay("Objects:");
    Count = llGetListLength(LibraryObjects) / OBJ_STRIDE;
    for (C = 0; C < Count; C++) {
        integer P = C * OBJ_STRIDE;
        llOwnerSay((string)C + ": " + llList2CSV(llList2List(LibraryObjects, P, P + OBJ_STRIDE - 1)));
    }
}
default {
    on_rez(integer S) { llResetScript(); }
    state_entry() {
        SetDebug();
        Debug("State entry");
        if (llGetNumberOfPrims() == 1) state Hang; // we're in a box or something
        MyUuid = llGetKey();
        AvId = NULL_KEY;
        SaveFiles = [];
        HudActive = FALSE;
        BackButtonChar = "";
        if (!ReadHudStrings()) state Hang;
        if (!CheckPrims()) state Hang;
        llSetText("", <0, 0, 0>, 0.0);
        llAllowInventoryDrop(FALSE);
        // Use a timer in case LM_PUBLIC_DATA arrived while processing this event
        llSetTimerEvent(0.5);
    }
    link_message(integer Sender, integer Number, string Text, key Id) {
        if (Number == LM_PUBLIC_DATA) {
            ParsePublicData(Text);
        }
        else if (Number == LM_OBJECTS_COUNT) {
            SceneObjectsCount = (integer)Text;    // # of objects in scene, from ML
        }
        else if (Number == COM_RESET) {
            Reset();
            llResetScript();
        }
    }
    timer() {
        llSetTimerEvent(0.0);
        state Idle;
    }
}
state Idle {
    on_rez(integer S) { llResetScript(); }
    state_entry() {
        Debug("Idle");
        llSetTimerEvent(0.0);
        // Free up memory while idle by clearing catalogue data
        Categories = [];
        LibraryObjects = [];
        LibraryObjectsCount = 0;
        CurrentInventory = [];
        // Other idle settings
        CategoryWindowsCreated = FALSE;
        CreateModeOn = FALSE;
        IsObjectSelected = FALSE;
        Importing = 0;
    }
    link_message(integer Sender, integer Number, string Text, key Id) {
        if (Number == HUD_API_LOGIN) {
            Debug("Login message rec'd from HUD server");
            SendBespokeData();
            AvId = Id;
            LogIn(AvId);
            state GetCatalogue;
        }
        else if (Number == HUD_API_GET_METADATA) {    // HUD server requesting our data
            SendMetaData();
        }
        else if (Number == LM_PUBLIC_DATA) {
            ParsePublicData(Text);
        }
        else if (Number == LM_OBJECTS_COUNT) {
            SceneObjectsCount = (integer)Text;    // # of objects in scene, from ML
        }
        else if (Number == COM_RESET) {
            Reset();
            llResetScript();
        }
    }
}
state GetCatalogue {
    on_rez(integer S) { llResetScript(); }
    state_entry() {
        Debug("Requesting data from cataloguer");
        llMessageLinked(LINK_THIS, CT_REQUEST_DATA, "", AvId); // Request object library data from Cataloguer
        DisableCreateMenu = FALSE;
        ArrangeModules();
    }
    link_message(integer Sender, integer Number, string Text, key Id) {
        if (Sender == 1) {
            if (Number == CT_CATALOG) {
                // Data comes across as catalog data (base-64) and objects metadata (base-64) separated by "|"
                list Parts = llParseStringKeepNulls(Text, [ "|" ], []);
                string CatalogData = llBase64ToString(llList2String(Parts, 0));
                string ObjectsData = llBase64ToString(llList2String(Parts, 1));
                if (DebugMode) Debug("Catalog rec'd (" + (string)llStringLength(CatalogData) + "+" + (string)llStringLength(ObjectsData) + " bytes)");
                if (!ReadObjectsList(CatalogData)) {    // If objects list fails to load, prevent use of Create
                    DisableCreateMenu = TRUE;
                    return;
                }
                ProcessObjectData(ObjectsData);
                state Active;
            }
            else if (Number == CT_ERRORS) {
                LibraryErrorsText = Text;
                state LibraryErrors;
            }
            else if (Number == LM_PUBLIC_DATA) {
                ParsePublicData(Text);
            }
            else if (Number == LM_OBJECTS_COUNT) {
                SceneObjectsCount = (integer)Text;    // # of objects in scene, from ML
            }
        }
        if (Number == COM_RESET) {
            Reset();
            llResetScript();
        }
    }
}
state Active {
    on_rez(integer S) { llResetScript(); }
    state_entry() {
        Debug("Active");
        SendHud(HUD_API_READY, []);        // Tell HUD we're ready
        llListen(HUD_CHAT_GENERAL, "", NULL_KEY, "");
        CameraTracking = FALSE;
        llSetTimerEvent(0.0);
    }
    link_message(integer Sender, integer Number, string Text, key Id) {
        //Debug("Received link message " + (string)Number + " from " + (string)Sender);
        llAllowInventoryDrop(FALSE); // Do this for every command to ensure it stays false however they quit the import
        if (Sender == 1) {    // Message from script in root prim
            // Prim selection/deselection. We handle messages from the main ML script telling us when the user selects/deselects prims.
            if (Number == LM_PRIM_SELECTED) {
                // If the module lock exists, prevent selection
                if (ModuleLockExists()) {
                    Deselect();
                    return;
                }
                Debug("Object selected");
                IsObjectSelected = TRUE;
                integer LinkNum = (integer)Text;
                string ObjectName = llGetLinkName(LinkNum);
                integer MPtr = llListFindList(MetaData, [ "~" + ObjectName ]);
                SelectedDesc = "[Unknown]";
                if (MPtr > -1) {
                    MPtr -= MD_NAME;
                    SelectedDesc = llList2String(MetaData, MPtr + MD_SHORTDESC);
                    SelectedResizable = (integer)llList2String(MetaData, MPtr + MD_RESIZABLE);
                }
                SelectedWindow();
            }
            else if (Number == LM_PRIM_DESELECTED) {
                Debug("Object deselected");
                IsObjectSelected = FALSE;
                DisplayWindow(WindowWhenSelected);
                HudStatus("");
            }
            else if (Number == LM_TASK_COMPLETE) {    // sent when loading or clearing a scene is complete
                Debug("Task complete");
                if (IsObjectSelected) {
                    SelectedWindow();
                }
                else {
                    MainWindow();
                }
            }
            else if (Number == LM_FAILURE) {
                Debug("Failure: " + Text);
                HandleFailure(Text);
            }
            else if (Number == LM_HUD_STATUS) {
                Debug("Setting status: " + Text);
                SendHud(HUD_API_STATUS_LINE, [ Text ]);
            }
            else if (Number == LM_PUBLIC_DATA) {
                Debug("Rec'd public data: " + Text);
                ParsePublicData(Text);
            }
            else if (Number == LM_OBJECTS_COUNT) {
                Debug("Rec'd objects count: " + Text);
                SceneObjectsCount = (integer)Text;    // # of objects in scene, from ML
            }
            else if (Number == ENV_DONE) {    // Environment script has finished processing
                Debug("Rec'd 'environment done': " + Text);
                if (Text == "land") DisplayWindow("landlevel");
            }
        }
        else {    // messages from child prim, possibly HUD server
            if (Number >= HUD_API_MIN && Number <= HUD_API_MAX) {    // it's a HUD API message
                list Parts = llParseStringKeepNulls(Text, [ HUD_API_SEPARATOR_1 ], []);
                if (Number == HUD_API_CLICK_BUTTON) {
                    string WindowName = llList2String(Parts, 0);
                    string Tag = llList2String(Parts, 1);
                    Debug("User clicked: " + Tag + " in window " + WindowName);
                    // Handle menus
                    // --- Home
                    if (WindowName == "home") {
                        RelinquishControls();
                        if (Tag == "File") DisplayWindow("saves");
                        else if (Tag == "Create" && !DisableCreateMenu) ShowCategories();
                        else if (Tag == "Clear") DisplayWindow("clearall");
                        else if (Tag == "Climate") DisplayWindow("environment");
                        else if (Tag == "Settings") DisplaySettingsMenu();
                        else if (Tag == "Advanced") DisplayAdvancedMenu();
                        else if (Tag == "Finish") LogOutButton();
                    }
                    // --- Selection menu
                    else if (IsSelectedWindow(WindowName)) {
                        RelinquishControls();
                        if (Tag == "Remove") RemoveSelectedObject();
                        else if (Tag == "Clone") CloneSelectedObject();
                        else if (Tag == "Teleport") TeleportToObject();
                        else if (Tag == "Zoom") ZoomToObject();
                        else if (Tag == "Resize") DisplayWindow("resize");
                        else if (Tag == "Rotate") DisplayWindow("rotate");
                        else if (Tag == "Nudge") DisplayWindow("nudge");
                    }
                    // --- Settings menus
                    else if (WindowName == "settings") {
                        if (llGetSubString(Tag, 0, 5) == "Random") SetRandom(!RandomButtonOn, TRUE);
                        else if (Tag == "Reset") {
                            CreateWindowAlert("resetconfirm", "Reset Scripts", [
                                "WARNING!",
                                "",
                                "This will reset all scripts in the",
                                "App. Any current scene data will be",
                                "lost, but saved scenes will not be",
                                "affected."
                                    ], [ "*OK", "Cancel" ]);
                            DisplayWindow("resetconfirm");
                        }
                    }
                    else if (WindowName == "advanced") {
                        if (Tag == "Modules") {
                            if (SceneObjectsCount == 0) {
                                ModulesMode(TRUE);
                            }
                            else {
                                CreateWindowAlert("moduleserror", "Modules Maintenance", [
                                    "You cannot use modules maintenance",
                                    "while there are objects in the current",
                                    "scene.",
                                    "",
                                    "Please clear the scene and try again."
                                        ], [ "*OK"    ]);
                                DisplayWindow("moduleserror");
                            }
                        }
                        else if (llGetSubString(Tag, 0, 6) == "Climate") {
                            EnvironmentalChange = !EnvironmentalChange;
                            string ConfigValue;
                            if (EnvironmentalChange) ConfigValue = "True"; else ConfigValue = "False";
                            // Tell ML to change the "ML config" value for Climate/EnvironmentalChange
                            llMessageLinked(LINK_THIS, LM_CHANGE_CONFIG, "EnvironmentalChange|" + ConfigValue, NULL_KEY);
                            MakeMainWindow();    // add/remove "Climate" button from main window
                            DisplayAdvancedMenu();
                        }
                    }
                    else if (WindowName == "resetconfirm") {
                        if (Tag == "OK") {
                            Reset();
                            LogOut();
                            llResetScript();
                        }
                        else {
                            DisplayWindow("settings");
                        }
                    }
                    else if (WindowName == "modules") {
                        if (Tag == "Done") {
                            ModulesMode(FALSE);
                            LogOut();
                            Reset();
                            llResetScript();
                        }
                    }
                    else if (WindowName == "moduleserror") {
                        MainWindow();
                    }
                    else if (WindowName == "failure") {
                        MainWindow();
                    }
                    // --- File menu
                    else if (WindowName == "saves") {
                        if (Tag == "Save") StartSave();
                        else if (Tag == "Load") DisplayWindow("saveload");
                        else if (Tag == "Rearrange") DisplayWindow("saverearrange");
                        else if (Tag == "Delete") DisplayWindow("savedelete");
                        else if (Tag == "Export") DisplayWindow("saveexport");
                        else if (Tag == "Import") StartImport();
                    }
                    // Selected item menus
                    else if (WindowName == "resize") {
                        ResizeObject(Tag);    // pass the button label to the function that does it
                    }
                    else if (WindowName == "rotate") {
                        RotateObject(Tag);    // pass the button label to the function that does it
                    }
                    else if (WindowName == "nudge") {
                        vector CameraPos = (vector)llList2String(Parts, 2);
                        rotation CameraRot = (rotation)llList2String(Parts, 3);
                        if (CameraPos == ZERO_VECTOR) {    // for some reason, no data, and we don't want to continue
                            LogError("No camera data for nudge");
                            return;
                        }
                        ProcessNudge(Tag, CameraPos, CameraRot);    // pass the button label to the function that does it
                    }
                    // Elementals
                    else if (WindowName == "saveload") {
                        StartLoad(Tag, TRUE);
                    }
                    else if (WindowName == "saverearrange") {
                        StartLoad(Tag, FALSE);
                    }
                    else if (WindowName == "savedelete") {
                        DeleteSavePrompt(Tag);
                    }
                    else if (WindowName == "savealert") {
                        // it must be a retry
                        StartSave();
                    }
                    else if (WindowName == "saveexport") {
                        Export(Tag);
                    }
                    else if (WindowName == "import") {
                        // Can only be "Cancel" button
                        CancelImport();
                    }
                    else if (WindowName == "clearall") { // "Are you sure?" when clearing scene
                        if (Tag == "Clear")
                            ClearScene();
                        else
                            MainWindow();
                    }
                    else if (WindowName == "deleteprompt") {    // "Are you sure?" when deleting save file
                        DestroyWindow("deleteprompt");    // almost definitely won't need it again (it contains the filename)
                        if (Tag == "Delete")
                            DeleteSave();
                        else
                            MainWindow();
                    }
                    else if (WindowName == "loadscene") {    // "Are you sure?" when loading a scene
                        if (Tag == "Load")
                            DoLoad();
                        else
                            DisplayWindow("saves");
                    }
                    else if (WindowName == "environment") {
                        if (Tag == "Sun time") {
                            DisplayWindow("sunposition");
                            EnvironmentStatus("sun");
                        }
                        else if (Tag == "Sea level") {
                            DisplayWindow("sealevel");
                            EnvironmentStatus("water");
                        }
                        else if (Tag == "Land level") {
                            DisplayWindow("landlevel");
                            EnvironmentStatus("land");
                        }
                        else if (Tag == "Wind") {
                            DisplayWindow("wind");
                            EnvironmentStatus("wind");
                        }
                        else if (Tag == "Reset") {
                            SetEnvironment("resetall");
                        }
                    }
                    else if (WindowName == "sunposition") {
                        SetEnvironment("sunhour," + Tag);
                    }
                    else if (WindowName == "sealevel") {
                        if (Tag == "+1m") SetEnvironment("waterlevel,+");
                        else if (Tag == "-1m") SetEnvironment("waterlevel,-");
                        else if (Tag == "Reset") SetEnvironment("waterlevel,reset");
                    }
                    else if (WindowName == "landlevel") {
                        // The 1 at the end of each CSV tells the env script that it's coming from the menu
                        if (Tag == "+1m") SetEnvironment("terrainheight,+,0,1");
                        else if (Tag == "-1m") SetEnvironment("terrainheight,-,0,1");
                        else if (Tag == "Reset") SetEnvironment("terrainheight,reset,0,1");
                        DisplayWindow("landchange");
                    }
                    else if (WindowName == "wind") {
                        if (llListFindList([ "N", "NE", "E", "SE", "S", "SW", "W", "NW" ], [ Tag ]) > -1)
                            SetEnvironment("winddirection," + Tag);
                        else if (Tag == "Strength+")    SetEnvironment("windstrength,+");
                        else if (Tag == "Strength-")    SetEnvironment("windstrength,-");
                        else if (Tag == "Reset")        SetEnvironment("windstrength,reset");
                    }
                    else if (IsCategoryRef(WindowName)) {
                        SelectFromReference(Tag);
                    }
                }
                else if (Number == HUD_API_CURRENT_WINDOW) {    // HUD server telling us which is the currently displayed window
                    string Window = llList2String(Parts, 0);
                    if (!IsObjectSelected) {    // If we don't have an MLO selected ...
                        if (!IsObjectRef(Window)) {    // ... and if it's not an object window (because of complications returning to that state) ...
                            WindowWhenSelected = Window;    // .. store the window so we can return to it after any selection
                        }
                    }
                    else {    // an MLO is selected
                        // and we're on the Selected menu
                        if (IsSelectedWindow(Window)) {
                            HudStatus(SelectedDesc + " selected");
                        }
                    }
                }
                else if (Number == HUD_API_BACK_BUTTON) {
                    string WindowName = llList2String(Parts, 0);
                    Debug("Back button on window " + WindowName);
                    if (IsCategoryRef(WindowName)) BackCategory();
                    else if (IsObjectRef(WindowName)) BackObject();
                    else {
                        // Just a normal back-button to parent window
                        if (IsSelectedWindow(WindowName)) {    // if they've clicked back button on selected menu
                            Deselect();
                        }
                        else if (WindowName == "resize" || WindowName == "rotate" || WindowName == "nudge") {
                            SelectedWindow();
                        }
                    }
                }
                else if (Number == HUD_API_READY) {        // HUD is ready, so we send our first page
                    Debug("API ready, so creating windows");
                    llMessageLinked(SfmLinkNum(), SFM_LIST, "", NULL_KEY);    // request list of saves from Scene File Manager
                    HudActive = TRUE;
                    // Dummy home menu (so that parent references to it don't cause issues)
                    // Actual home window buttons, etc are set elsewhere later
                    CreateWindowButtons("home", "", "Home", FALSE, [ "Finish" ]);
                    // Static pages
                    //
                    // File menu
                    CreateWindowButtons("saves", "home", "File", TRUE, [
                        MenuEntry("Load"),
                        MenuEntry("Save"),
                        MenuEntry("Rearrange"),
                        MenuEntry("Delete"),
                        MenuEntry("Import"),
                        MenuEntry("Export")
                            ]);
                    // Selected menu (with and without Resize)
                    CreateWindowButtons("selectedr", "", "Selected object", TRUE, [
                        MenuEntry("Remove"),
                        MenuEntry("Resize"),
                        MenuEntry("Rotate"),
                        MenuEntry("Nudge"),
                        MenuEntry("Clone")
                            ]);
                    CreateWindowButtons("selectednr", "", "Selected object", TRUE, [
                        MenuEntry("Remove"),
                        MenuEntry("Rotate"),
                        MenuEntry("Nudge"),
                        MenuEntry("Clone")
                            ]);
                    // Rotate menu
                    if (MenuEntry("Rotate") != "") {
                        CreateWindowButtons("rotate", "", "Rotate object", TRUE, [
                            RotateLabel(TRUE, 90), RotateLabel(FALSE, 90),
                            RotateLabel(TRUE, 45), RotateLabel(FALSE, 45),
                            RotateLabel(TRUE, 10), RotateLabel(FALSE, 10),
                            RotateLabel(TRUE, 1), RotateLabel(FALSE, 1),
                            MenuEntry("Random")
                                ]);
                    }
                    // Resize menu
                    if (MenuEntry("Resize") != "") {
                        CreateWindowButtons("resize", "", "Resize object", TRUE, [
                            ResizeLabel(TRUE, 100), ResizeLabel(FALSE, 50),
                            ResizeLabel(TRUE, 25), ResizeLabel(FALSE, 25),
                            ResizeLabel(TRUE, 10), ResizeLabel(FALSE, 10),
                            ResizeLabel(TRUE, 1), ResizeLabel(FALSE, 1),
                            MenuEntry("Random")
                                ]);
                    }
                    // Nudge menu
                    CreateWindowButtons("nudge", "", "Nudge object", TRUE, NudgeButtons());
                    //
                    // Frequently-used statuses and alerts
                    //
                    CreateWindowAlert("clearall", "Clear scene", [ "This will remove all", "objects from the", "scene. Are you sure?" ], [ "*Clear", "Cancel" ]);
                    CreateWindowAlert("loadscene", "Load scene", [ "Are you sure you want", "to load a scene?" ], [ "*Load", "Cancel" ]);
                    CreateWindowStatus("clearingall", "Clearing scene", [ "Please wait ..." ]);
                    CreateWindowStatus("makecats", "Loading objects", [ "Please wait ..." ]);
                    // We make the Climate menu regardelss of whether it's enabled, in case it becomes enabled mid-session
                    if (TerrainChange)
                        CreateWindowButtons("environment", "home", "Climate", TRUE, [ "Sun time", "Sea level", "Land level", "Wind", "Reset" ]);
                    else
                        CreateWindowButtons("environment", "home", "Climate", TRUE, [ "Sun time", "Sea level", "Wind", "Reset" ]);
                    CreateWindowButtons("sunposition", "environment", "Sun Time", TRUE, [ "Dawn", "Morning", "Noon", "Afternoon", "Dusk", "Night", "Reset" ]);
                    CreateWindowButtons("sealevel", "environment", "Sea Level", TRUE, [ "+1m", "-1m", "Reset" ]);
                    CreateWindowButtons("landlevel", "environment", "Land Level", TRUE, [ "+1m", "-1m", "Reset" ]);
                    CreateWindowStatus("landchange", "Changing land level", [ "Please wait ..." ]);
                    CreateWindowButtons("wind", "environment", "Wind", TRUE, [ "N", "NE", "E", "SE", "S", "SW", "W", "NW", "Strength+", "Strength-", "Reset" ]);
                    // Saves lists
                    SendCommandToML("deselect");    // Just in case they already have an object selected when they log in
                    MainWindow();
                }
                else if (Number == HUD_API_GET_METADATA) {    // HUD server requesting our data
                    Debug("Sending metadata to HUD server");
                    SendMetaData();
                }
                else if (Number == HUD_API_TAKE_CONTROL) {
                    SetRandom(!RandomButtonOn, FALSE);
                    string OnOff = "off";
                    if (RandomButtonOn) OnOff = "on";
                    MessageUser("Random is now " + OnOff);
                }
                else if (Number == HUD_API_CAMERA_JUMP_MODE) {
                    llMessageLinked(LINK_THIS, LM_CAMERA_JUMP_MODE, Text, Id);
                }
                else if (Number == HUD_API_LOGIN) {
                    Debug("Processing login");
                    AvId = Id;
                    LogIn(AvId);
                }
                else if (Number == HUD_API_LOGOUT) {
                    Debug("Processing logout");
                    LogOut();
                    state Idle;
                }
            }
            else {        // Not a message from the HUD
                if (HudActive) {    // only process if HUD is active
                    if (Number == SFM_LIST) {    // Scene File Manager is sending us a list of save files
                        Debug("Got list of save files from SFM");
                        MakeSavesList(llParseStringKeepNulls(Text, [ "|" ], []));    // make lists that need saved scene names
                    }
                    else if (Number == SFM_SAVE_COMPLETE) {
                        MessageUser("Scene saved.");
                        // This is the last thing done during a save, so we're no safe to return control to the user.
                        MainWindow();
                    }
                }
            }
        }
        if (Number == COM_RESET) {
            Reset();
            LogOut();
            llResetScript();
        }
    }
    changed(integer Change) {
        if (Change & (CHANGED_INVENTORY | CHANGED_ALLOWED_DROP)) {
            if (Importing == 1) {
                // We need to call DoImport(), but this event can fire multiple
                // times when the user drops in multiple notecards. So we use a
                // timer to delay the function call.
                llSetTimerEvent(1.0);
            }
            else if (Importing == 2) {
                // Ignore. This will be the imported notecards being deleted after transfer
                // to scene files prim
            }
            else {
                if (Change & CHANGED_INVENTORY) {
                    Debug("Detected changed inventory");
                    OldSaveString = "!";    // force rebuilding of saved list
                    OldObjectsHash = "";    // force rereading of objects list
                }
                else {
                    LogError("Unexpected inventory drop");
                    state Hang;

                }
            }
        }
    }
    listen(integer Channel, string Name, key Id, string String) {
        if (Id == MyUuid) return;    // we never listen to our own messages
        if (Channel == HUD_CHAT_GENERAL) {
            // The only message here that is relevant to us in this state is a disconnect for our user from another ML in the region
            // (meaning they were using us, but have moved on to that other ML)
            if (String == "D" + (string)AvId) LogOut();
        }
        else if (Channel == MenuChannel) {
            // it must be the name of a save file
            EndSave(String);
        }
    }
    timer() {
        // The only use of the timer is in the Import process
        llSetTimerEvent(0.0);
        DoImport();
    }
}
state LibraryErrors {
    on_rez(integer Param) { llResetScript(); }
    state_entry() {
        llOwnerSay("Errors in modules:\n" + LibraryErrorsText + "\n[Click App/Map to retry]");
    }
    touch_start(integer Count) {
        Reset();
        llResetScript();
    }
    changed(integer Change) {
        if (Change & CHANGED_INVENTORY) llResetScript();    // in case HUD strings file has been added
    }
    link_message(integer Sender, integer Number, string Text, key Id) {
        if (Number == COM_RESET) {
            Reset();
            llResetScript();
        }
    }
}
state Hang {
    on_rez(integer Param) { llResetScript(); }
    changed(integer Change) {
        if (Change & CHANGED_INVENTORY) llResetScript();    // in case HUD strings file has been added
    }
    link_message(integer Sender, integer Number, string Text, key Id) {
        if (Number == COM_RESET) {
            Reset();
            llResetScript();
        }
    }
}
// HUD communicator v1.11.7