// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1                  // Force strict semicolon mode.

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>
#include <colors>

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
// ---- Plugin-related constants ---------------------------------------------------
#define PLUGIN_NAME              "[TF2] Wearables for everyone!"
#define PLUGIN_AUTHOR            "Damizean"
#define PLUGIN_VERSION           "1.0.0"
#define PLUGIN_CONTACT           "elgigantedeyeso@gmail.com"
#define CVAR_FLAGS               FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

// ---- Wearables management -------------------------------------------------------
#define MAX_OBJECTS              128
#define MAX_LENGTH               256

// *********************************************************************************
// VARIABLES
// *********************************************************************************

// ---- Menu handle ----------------------------------------------------------------
new Handle:WearablesMenu = INVALID_HANDLE;

// ---- Player tracking ------------------------------------------------------------
new PlayerWearable[MAXPLAYERS+1];
new PlayerWearableEntity[MAXPLAYERS+1];

// ---- SDK calls ------------------------------------------------------------------
new Handle:hGameConf;
new Handle:hEquipWearable;
new Handle:hRemoveWearable;

// ---- Object pool variables ------------------------------------------------------
new WearableCount = 0;
new String:WearableName[MAX_OBJECTS][MAX_LENGTH];
new String:WearableModel[MAX_OBJECTS][MAX_LENGTH];
new WearableFlags[MAX_OBJECTS];

// ---- Others ---------------------------------------------------------------------
new Handle:Cvar_AdminOnly = INVALID_HANDLE;
new Handle:Cvar_Announce  = INVALID_HANDLE;
new MessageCount;

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_NAME,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

// *********************************************************************************
// METHODS
// *********************************************************************************

// =====[ BASIC PLUGIN MANAGEMENT ]========================================

// ------------------------------------------------------------------------
// OnPluginStart()
// ------------------------------------------------------------------------
public OnPluginStart()
{    
    // Create plugin cvars
    CreateConVar("sm_tf2_wearables_version", PLUGIN_VERSION, PLUGIN_NAME, CVAR_FLAGS);
    Cvar_AdminOnly = CreateConVar("sm_tf2_wearables_adminonly", "0", "Only administrators can use wearables", CVAR_FLAGS);
    Cvar_Announce  = CreateConVar("sm_tf2_wearables_announce",  "1", "Announces usage and tips about wearables", CVAR_FLAGS);
    
    // Register console commands
    RegConsoleCmd("sm_tf2_wearables", Cmd_WearableMenu, "Shows the wearables menu");
	RegConsoleCmd("sm_wear", Cmd_Wearables, "Gives wearable.");
    
    // Load game config file
    hGameConf = LoadGameConfigFile("TF2_Wearables");
    
    // Prepare SDK call for Equip Wearable
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"EquipWearable");
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    hEquipWearable = EndPrepSDKCall();
    
    // Prepare SDK call for Remove Wearable
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"RemoveWearable");
    PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
    hRemoveWearable = EndPrepSDKCall();    
    
    // Hook the proper events    
    HookEvent("player_spawn",       Event_AttachWearable,   EventHookMode_Pre);
    HookEvent("player_changeclass", Event_DeattachWearable, EventHookMode_Pre);
    HookEvent("player_death",       Event_DeattachWearable, EventHookMode_Pre);
    
    // Load translations for this plugin
    LoadTranslations("TF2_Wearables.Messages");
    LoadTranslations("TF2_Wearables.Items");
    
    // Execute configs.
    AutoExecConfig(true, "TF2_Wearables");
    
    // Create announcement timer.
    CreateTimer(600.0, Timer_Announce, _, TIMER_REPEAT);
}

// ------------------------------------------------------------------------
// OnMapStart()
// ------------------------------------------------------------------------
public OnMapStart()
{
    // Reset player's Wearables
    for (new i=1; i<=MaxClients; i++)
    {
        PlayerWearable[i] = -1;
        PlayerWearableEntity[i] = -1;
    }
    
    // Reparse and re-build the wearables menu
    ParseWearablesList();
    WearablesMenu = BuildWearableListMenu();    
}

// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
public OnMapEnd()
{
    // Destroy disguises menu
    if (WearablesMenu != INVALID_HANDLE) { CloseHandle(WearablesMenu); WearablesMenu = INVALID_HANDLE; }
}

// ------------------------------------------------------------------------
// OnClientPutInServer()
// ------------------------------------------------------------------------
public OnClientPutInServer(Client)
{
    // Greet player and show information about plugin.
    CreateTimer(30.0, Timer_Welcome, Client, TIMER_FLAG_NO_MAPCHANGE);
}

// ------------------------------------------------------------------------
// Event_AttachWearable()
// ------------------------------------------------------------------------
public Event_AttachWearable(Handle:hEvent, String:StrName[], bool:bDontBroadcast)
{
    // Retrieve client
    new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    
    // Attach
    AttachWearable(Client, PlayerWearable[Client]);
}

// ------------------------------------------------------------------------
// Event_DeattachWearable()
// ------------------------------------------------------------------------
public Event_DeattachWearable(Handle:hEvent, String:StrName[], bool:bDontBroadcast)
{
    // Retrieve client
    new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    
    // Deattach
    DeattachWearable(Client, 0);
}

// ------------------------------------------------------------------------
// OnClientDisconnect()
// ------------------------------------------------------------------------
public OnClientDisconnect(Client)
{
    DeattachWearable(Client, 1, 0);
}

// ------------------------------------------------------------------------
// AttachWearable
// ------------------------------------------------------------------------
AttachWearable(Client, Wearable)
{
    // Assert if the player is alive.
    if (!IsClientConnected(Client)) return;
    if (!IsClientInGame(Client))    return;
    if (!IsPlayerAlive(Client))     return;
    
    // Declarate variables
    new Entity;

    // Delete Wearables
    DeattachWearable(Client, 1);
    
    // If we just wanted to deattach, we're done.
    if (Wearable == -1) return;
    
    // Create wearable item and equip.
    Entity = CreateEntityByName("tf_wearable_item");
    if (!IsValidEntity(Entity)) return;

    SDKCall(hEquipWearable, Client, Entity);          // Equip the client with it.
    SetEntityModel(Entity, WearableModel[Wearable]);  // Set the correct model
    
    // Set Wearable
    PlayerWearable[Client] = Wearable;
    PlayerWearableEntity[Client] = Entity;
}

// ------------------------------------------------------------------------
// DeattachWearable
// ------------------------------------------------------------------------
DeattachWearable(Client, Reset, Check=1)
{
    new String:StrNetclass[32];

    // Assert if the player is alive.
    if (Check)
    {
        if (!IsClientConnected(Client)) return;
        if (!IsClientInGame(Client))    return;
        if (!IsPlayerAlive(Client))     return;
    }
    
    // Assert if there was a Wearable, to begin with.
    if (PlayerWearable[Client] == -1) return;
    
    // Destroy the Wearable entity
    if (IsValidEntity(PlayerWearableEntity[Client]))
    {
        // Retrieve net class and check if it's a wearable item.
        GetEntityNetClass(PlayerWearableEntity[Client], StrNetclass, sizeof(StrNetclass));
        if (StrEqual(StrNetclass, "CTFWearableItem"))
        {
            // If so, remove and destroy.
            SDKCall(hRemoveWearable, Client, PlayerWearableEntity[Client]);
            if (IsValidEntity(PlayerWearableEntity[Client])) RemoveEdict(PlayerWearableEntity[Client]);
        }
    }
    
    if (Reset) PlayerWearable[Client] = -1;
    PlayerWearableEntity[Client] = -1;
}

// ------------------------------------------------------------------------
// ParseWearablesList()
// ------------------------------------------------------------------------
ParseWearablesList()
{
    // Parse the objects list key values text to acquire all the possible
    // wearable items.
    new Handle:kvWearableList = CreateKeyValues("TF2_Wearables");
    new Handle:hStream = INVALID_HANDLE;
    new String:strLocation[256];
    new String:strDependances[256];
    new String:strLine[256];
    
    // Load the key files.
    BuildPath(Path_SM, strLocation, 256, "data/TF2_Wearables.txt");
    FileToKeyValues(kvWearableList, strLocation);

    // Check if the parsed values are correct
    if (!KvGotoFirstSubKey(kvWearableList)) { LogMessage("%t", "Error_CantOpenWearables", strLocation); return; }
    WearableCount = 0;
    
    // Iterate through all keys.
    do
    {
        // Retrieve section name, wich is pretty much the name of the wearable. Also, parse the model.
        KvGetSectionName(kvWearableList,       WearableName[WearableCount],  MAX_LENGTH);
        KvGetString(kvWearableList, "Model",   WearableModel[WearableCount], MAX_LENGTH);
        KvGetString(kvWearableList, "Special", strLine,            sizeof(strLine));
        WearableFlags[WearableCount] = StringToInt(strLine);
        
        // Check if model exists, so we can prevent crashes.
        if (!FileExists(WearableModel[WearableCount], true)) continue;
        
        // Retrieve dependances file and open if possible.
        Format(strDependances, sizeof(strDependances), "%s.dep", WearableModel[WearableCount]);
        if (FileExists(strDependances))
        {
            // Open stream, if possible
            hStream = OpenFile(strDependances, "r");
            if (hStream == INVALID_HANDLE) { LogMessage("%t", "Error_CantOpenDependances"); return; }
            
            while(!IsEndOfFile(hStream))
            {
                // Try to read line. If EOF has been hit, exit.
                ReadFileLine(hStream, strLine, sizeof(strLine));
                
                // Cleanup line
                new Length  = strlen(strLine);
                if (strLine[Length-1] == '\n') strLine[Length-1] = '\0';
                TrimString(strLine);
                
                // If file exists...
                if (!FileExists(strLine, true)) continue;
                
                // Precache depending on type, and add to download table
                if (StrContains(strLine, ".vmt", false) != -1)      PrecacheDecal(strLine, true);
                else if (StrContains(strLine, ".vtf", false) != -1) PrecacheDecal(strLine, true);
                else if (StrContains(strLine, ".mdl", false) != -1) PrecacheModel(strLine, true);
                AddFileToDownloadsTable(strLine);
            }
            
            // Close file
            CloseHandle(hStream);
        }
        PrecacheModel(WearableModel[WearableCount], true);
        
        // Go to next.
        WearableCount++;
    }
    while (KvGotoNextKey(kvWearableList));
    
    CloseHandle(kvWearableList);    
}

// ------------------------------------------------------------------------
// BuildWearableListMenu()
// ------------------------------------------------------------------------
Handle:BuildWearableListMenu()
{
    // Create the menu Handle
    new Handle:Menu = CreateMenu(Menu_SelectWearable, MenuAction_DisplayItem|MenuAction_Display);

    // Add all objects
    AddMenuItem(Menu, "sm_tf2_Wearables -1", "[Remove wearable]");
    for (new i=0; i<WearableCount; i++) 
    {
        if (WearableFlags[i]) continue;
        
        new String:strBuffer[64]; Format(strBuffer, sizeof(strBuffer), "sm_tf2_Wearables %i", i);
        AddMenuItem(Menu, strBuffer, WearableName[i]);
    }

    // Set the menu title
    SetMenuTitle(Menu, "Select wearable.");

    return Menu;
}

// ------------------------------------------------------------------------
// Menu_SelectWearable()
// ------------------------------------------------------------------------
public Menu_SelectWearable(Handle:Menu, MenuAction:State, Param1, Param2)
{
    switch(State)
    {
        case MenuAction_Select:
        {
            // First, check if the player is a spy. If not, leave it alone.
            if (!IsClientConnected(Param1)) return 0;
            if (!IsClientInGame(Param1))    return 0;
            if (!IsPlayerAlive(Param1))     return 0;
            
            // Attach the selected Wearable.
            new String:strBuffer[64]; GetMenuItem(Menu, Param2, strBuffer, sizeof(strBuffer));
            FakeClientCommandEx(Param1, strBuffer);   
        }
        
        case MenuAction_DisplayItem:
        {
            // Get the display string, we'll use it as a translation phrase
            decl String:StrDisplay[64]; GetMenuItem(Menu, Param2, "", 0, _, StrDisplay, sizeof(StrDisplay));
            decl String:StrBuffer[255]; Format(StrBuffer, sizeof(StrBuffer), "%T", StrDisplay, Param1);
            return RedrawMenuItem(StrBuffer);
        }
        
        case MenuAction_Display: {
            // Retrieve panel
            new Handle:Panel = Handle:Param2;
             
            // Translate title
            decl String:StrTranslation[255];
            Format(StrTranslation, sizeof(StrTranslation), "%T", "Select wearable", Param1);
     
            // Set title.
            SetPanelTitle(Panel, StrTranslation);
        }
    }
    
    return 1;
}

// ------------------------------------------------------------------------
// Cmd_WearableMenu()
// ------------------------------------------------------------------------
public Action:Cmd_WearableMenu(Client, Args)
{
    // Not allowed if not ingame.
    if (Client == 0) return Plugin_Handled;
    
    // If admin only, check if can use wearables
    if (GetConVarBool(Cvar_AdminOnly) && GetUserAdmin(Client) == INVALID_ADMIN_ID) return Plugin_Handled;

    // If argument used, retrieve
    if (Args > 0)
    {
        // Retrieve argument
        new String:strArg[32]; GetCmdArg(1, strArg, sizeof(strArg));
        new Object = StringToInt(strArg);
        
        // Check if valid. If so, attach.
        if (Object >= -1 && Object < WearableCount) { AttachWearable(Client, Object); return Plugin_Handled; }
    }

    DisplayMenu(WearablesMenu, Client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Timer_Welcome
// ------------------------------------------------------------------------
public Action:Timer_Welcome(Handle:hTimer, any:Client)
{
    CPrintToChat(Client, "%t", "Welcome", PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    return Plugin_Stop;
}

// ------------------------------------------------------------------------
// Timer_Announce
// ------------------------------------------------------------------------
public Action:Timer_Announce(Handle:hTimer)
{
    if (GetConVarBool(Cvar_Announce))
    {
        switch(MessageCount)
        {
            case 0: CPrintToChatAll("%t", "Message 1");
            case 1: CPrintToChatAll("%t", "Message 2");
            case 2: CPrintToChatAll("%t", "Message 3");
        }
        MessageCount++;
        MessageCount %= 3;
    }
    
    return Plugin_Continue;
}

public Action:Cmd_Wearables(Client, Args)
{
    // Retrieve client
    new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    
    // Attach
    AttachWearable(Client, PlayerWearable[Client]);
}

AttachWearables(Client, Wearable)
{
    // Assert if the player is alive.
    if (!IsClientConnected(Client)) return;
    if (!IsClientInGame(Client))    return;
    if (!IsPlayerAlive(Client))     return;
    
    // Declarate variables
    new Entity;

    // Delete Wearables
    DeattachWearable(Client, 1);
    
    // If we just wanted to deattach, we're done.
    if (Wearable == -1) return;
    
    // Create wearable item and equip.
    Entity = CreateEntityByName("tf_wearable_item");
    if (!IsValidEntity(Entity)) return;

    SDKCall(hEquipWearable, Client, Entity);          // Equip the client with it.
    SetEntityModel(Entity, WearableModel[Wearable]);  // Set the correct model
    
    // Set Wearable
    PlayerWearable[Client] = Wearable;
    PlayerWearableEntity[Client] = Entity;
}