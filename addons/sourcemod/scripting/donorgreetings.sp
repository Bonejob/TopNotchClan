/**
 * vim: set ts=4 :
 * =============================================================================
 * Custom Greetings Plugin
 * =============================================================================
 */

#pragma semicolon 1

#undef REQUIRE_PLUGIN

#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <adminmenu>
#include <clientprefs>

#define PLUGIN_VERSION "2.1.3"

public Plugin:myinfo =
{
	name = "[Any] Donor Greetings",
	author = "DarthNinja (modified by Stealth)",
	description = "Provides welcome messages for donors",
	version = PLUGIN_VERSION
};

new bool:bDebug = false;
new Handle:g_Database = INVALID_HANDLE;
new Handle:v_DefaultMessage = INVALID_HANDLE;
new Handle:v_Max = INVALID_HANDLE;
new Handle:v_AllowCustomColors = INVALID_HANDLE;
new Handle:v_BlockMessage = INVALID_HANDLE;
new Handle:g_hAdminMenu = INVALID_HANDLE;
new g_iAdminDisabled[MAXPLAYERS+1] = 0;


public OnPluginStart()
{
	CreateConVar("sm_greetings_version", PLUGIN_VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	v_DefaultMessage = CreateConVar("sm_greetings_default", "{default}has joined the game.", "Default welcome message. {N} expands to client name");
	v_Max = CreateConVar("sm_greetings_maxlength", "128", "The max length a player can use in an unformatted message", 0, true, 0.0, true, 128.0);
	v_AllowCustomColors = CreateConVar("sm_greetings_colors", "1", "If 1, players can use custom colors.  If 0, only the default message can use colors.", 0, true, 0.0, true, 1.0);
	v_BlockMessage = CreateConVar("sm_greetings_block", "1", "Block the game's 'Player has joined' message? 1/0", 0, true, 0.0, true, 1.0);	
	Connect();
	RegConsoleCmd("disablegreeting", CDisableGreeting, "Disable your greeting message");
	RegConsoleCmd("enablegreeting", CEnableGreeting, "Enable your greeting message");
	RegConsoleCmd("resetgreeting", CResetGreeting, "Reset your greeting message");
	RegConsoleCmd("setgreeting", CSetGreeting, "Set your greeting message");
	RegAdminCmd("sm_admin_disable_greeting", ADisableGreeting, ADMFLAG_GENERIC, "Disable a player's greeting message");
	RegAdminCmd("sm_admin_enable_greeting", AEnableGreeting, ADMFLAG_GENERIC, "Enable a player's greeting message");
	RegAdminCmd("sm_admin_reset_greeting", AResetGreeting, ADMFLAG_GENERIC, "Reset a player's greeting message");

	LoadTranslations("common.phrases");

	HookEvent("player_connect", BlockEvent, EventHookMode_Pre);
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public Action:BlockEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(v_BlockMessage))
	{
		return Plugin_Handled;
	}
		
	return Plugin_Continue;
}

public OnAllPluginsLoaded()
{
    if (GetExtensionFileStatus("clientprefs.ext") == 1)
    {
        SetCookieMenuItem(SettingsMenuHandler, 1, "Set a custom greeting");
        SetCookieMenuItem(SettingsMenuHandler, 2, "Reset your greeting to the default");
        SetCookieMenuItem(SettingsMenuHandler, 3, "Disable my greeting");
        SetCookieMenuItem(SettingsMenuHandler, 4, "Re-enable my greeting");
    }
}

public SettingsMenuHandler(client, CookieMenuAction:action, any:selection, String:buffer[], maxlen)
{
    if (action == CookieMenuAction_SelectOption)
    {
		new String:text[64];
		if (selection == 1)
		{
			new Handle:menu = CreateMenu(Menu_Exit);
			SetMenuTitle(menu, "~ Setting a Greeting Message ~");
			AddMenuItem(menu, "", "Type /setgreeting in chat, followed by your message to set a greeting.", ITEMDRAW_DISABLED);
			AddMenuItem(menu, "", "You may use {N} in the message to insert your current name.", ITEMDRAW_DISABLED);
			Format(text, sizeof(text), "The maximum length of your message can be %i characters.", GetConVarInt(v_Max));
			AddMenuItem(menu, "", text, ITEMDRAW_DISABLED);
			if (GetConVarBool(v_AllowCustomColors))
			{
				AddMenuItem(menu, "", "Many colors are supported, here are a few:", ITEMDRAW_DISABLED);
				AddMenuItem(menu, "", "{green} will make any text after it GREEN", ITEMDRAW_DISABLED);
				AddMenuItem(menu, "", "{lightgreen} will make any text after it LIGHT GREEN", ITEMDRAW_DISABLED);
				AddMenuItem(menu, "", "{orange} will make any text after it ORANGE", ITEMDRAW_DISABLED);
				AddMenuItem(menu, "", "{gold} will make any text after it GOLD", ITEMDRAW_DISABLED);
				AddMenuItem(menu, "", "{default} will make any text after it the DEFAULT color.", ITEMDRAW_DISABLED);
			}
			SetMenuExitBackButton(menu, true);
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		}
		else if (selection == 2)
		{
			if (g_iAdminDisabled[client] == 1)
				CPrintToChat(client, "Your access to this command as been revoked.  You may only enable or disable the default greeting.");
			else
			{
				CPrintToChat(client, "Your greeting message has been reset to the default.");
				ClientResetGreeting(client);
			}
		}
		else if (selection == 3)
		{
			CPrintToChat(client, "Your greeting message has been disabled.");
			ClientDisableGreeting(client);
		}
		else if (selection == 4)
		{
			CPrintToChat(client, "Your greeting message has been re-enabled.");
			ClientEnableGreeting(client);
		}
	}
}

public Menu_Exit(Handle:menu, MenuAction:action, client, param2)
{
    if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		    ShowCookieMenu(client);
	}
	else if (action == MenuAction_End)
	    CloseHandle(menu);
}

public OnLibraryRemoved(const String:name[])
{
	if(StrEqual(name, "adminmenu"))
		g_hAdminMenu = INVALID_HANDLE;
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == g_hAdminMenu)
		return;	// We already did this
	g_hAdminMenu = topmenu;

	new TopMenuObject:TopMen = FindTopMenuCategory(g_hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
	if (TopMen != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(g_hAdminMenu, "sm_admin_disable_greeting", TopMenuObject_Item, AdminMenu_Disable, TopMen, "sm_admin_disable_greeting", ADMFLAG_GENERIC);
		AddToTopMenu(g_hAdminMenu, "sm_admin_enable_greeting", TopMenuObject_Item, AdminMenu_Enable, TopMen, "sm_admin_enable_greeting", ADMFLAG_GENERIC);
		AddToTopMenu(g_hAdminMenu, "sm_admin_reset_greeting", TopMenuObject_Item, AdminMenu_Reset, TopMen, "sm_admin_reset_greeting", ADMFLAG_GENERIC);
	}
}

public AdminMenu_Disable( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Greetings: Disable");
	else if( action == TopMenuAction_SelectOption)
		ShowPlayerMenu(client, 1);
}

public AdminMenu_Enable( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Greetings: Re-Enable");
	else if( action == TopMenuAction_SelectOption)
		ShowPlayerMenu(client, 2);
}

public AdminMenu_Reset( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Greetings: Reset");
	else if( action == TopMenuAction_SelectOption)
		ShowPlayerMenu(client, 3);
}

ShowPlayerMenu(client, handler)
{
	new Handle:menu = INVALID_HANDLE;
	switch (handler)
	{
		case 1:
			menu = CreateMenu(HandleMenuDisable);
		case 2:
			menu = CreateMenu(HandleMenuEnable);
		case 3:
			menu = CreateMenu(HandleMenuReset);
	}
	SetMenuTitle(menu, "Choose Player:");
	SetMenuExitBackButton(menu, true);
	AddTargetsToMenu(menu, client, true, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

//To bad we have to clone this code for just one line...  WELP
public HandleMenuDisable(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE)
			DisplayTopMenu(g_hAdminMenu, client, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select)
	{
		decl String:UserID[32];
		GetMenuItem(menu, param2, UserID, sizeof(UserID));
		new iTarget = GetClientOfUserId(StringToInt(UserID));
		if (iTarget == 0)
			CPrintToChat(client, "{green}[SM]{default} Selected player is no longer available.");
		else if (!CanUserTarget(client, iTarget))
			CPrintToChat(client, "{green}[SM]{default} Unable to target this player.");
		else
			AdminDisableGreeting(client, iTarget);

		if (IsClientInGame(client) && !IsClientInKickQueue(client))
			ShowPlayerMenu(client, 1);	// show selection menu again
	}
}

public HandleMenuEnable(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE)
			DisplayTopMenu(g_hAdminMenu, client, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select)
	{
		decl String:UserID[32];
		GetMenuItem(menu, param2, UserID, sizeof(UserID));
		new iTarget = GetClientOfUserId(StringToInt(UserID));
		if (iTarget == 0)
			CPrintToChat(client, "{green}[SM]{default} Selcted player is no longer available.");
		else if (!CanUserTarget(client, iTarget))
			CPrintToChat(client, "{green}[SM]{default} Unable to target this player.");
		else
			AdminEnableGreeting(client, iTarget);

		if (IsClientInGame(client) && !IsClientInKickQueue(client))
			ShowPlayerMenu(client, 2);	// show selection menu again
	}
}

public HandleMenuReset(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE)
			DisplayTopMenu(g_hAdminMenu, client, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select)
	{
		decl String:UserID[32];
		GetMenuItem(menu, param2, UserID, sizeof(UserID));
		new iTarget = GetClientOfUserId(StringToInt(UserID));
		if (iTarget == 0)
			CPrintToChat(client, "{green}[SM]{default} Selcted player is no longer available.");
		else if (!CanUserTarget(client, iTarget))
			CPrintToChat(client, "{green}[SM]{default} Unable to target this player.");
		else
			AdminResetGreeting(client, iTarget);

		if (IsClientInGame(client) && !IsClientInKickQueue(client))
			ShowPlayerMenu(client, 3);	// show selection menu again
	}
}

public Action:CDisableGreeting(client, args)
{
	ClientDisableGreeting(client);
	return Plugin_Handled;
}

public Action:CEnableGreeting(client, args)
{
	ClientEnableGreeting(client);
	return Plugin_Handled;
}

public Action:CResetGreeting(client, args)
{
	if (g_iAdminDisabled[client] == 1)
	{
		ReplyToCommand(client, "Your access to this command as been revoked.  You may only enable or disable the default greeting.");
		return Plugin_Handled;
	}
	ClientResetGreeting(client);
	return Plugin_Handled;
}

public Action:CSetGreeting(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: setgreeting <your greeting>\nUse {N} where you want your name to show up.");
		return Plugin_Handled;
	}
	if (g_iAdminDisabled[client] == 1)
	{
		ReplyToCommand(client, "Your access to this command as been revoked.  You may only enable or disable the default greeting.");
		return Plugin_Handled;
	}
	decl String:message[128];
	GetCmdArgString(message, sizeof(message));
	if (ReplaceString(message, sizeof(message), "{N}", "{N}", false) > 1)
	{
		ReplyToCommand(client, "You may only use your name once in your greeting!");
		return Plugin_Handled;
	}
	if (strlen(message) > GetConVarInt(v_Max))
	{
		ReplyToCommand(client, "Your message is too long!  The maximum length is %i characters.  Please try again.", GetConVarInt(v_Max));
		return Plugin_Handled;
	}
	ClientSetGreeting(client, message, sizeof(message));
	return Plugin_Handled;
}

public Action:ADisableGreeting(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: sm_admin_disable_greeting <client>");
		return Plugin_Handled;
	}
	decl String:target[32];
	GetCmdArg(1, target, sizeof(target));
	new iTarget = FindTarget(client, target, true);
	AdminDisableGreeting(client, iTarget);
	return Plugin_Handled;
}

public Action:AEnableGreeting(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: sm_admin_enable_greeting <client>");
		return Plugin_Handled;
	}
	decl String:target[32];
	GetCmdArg(1, target, sizeof(target));
	new iTarget = FindTarget(client, target, true);
	AdminEnableGreeting(client, iTarget);
	return Plugin_Handled;
}

public Action:AResetGreeting(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: sm_admin_reset_greeting <client>");
		return Plugin_Handled;
	}
	decl String:target[32];
	GetCmdArg(1, target, sizeof(target));
	new iTarget = FindTarget(client, target, true);
	AdminResetGreeting(client, iTarget);
	return Plugin_Handled;
}

Connect()
{
	if (SQL_CheckConfig("greetings"))
		SQL_TConnect(Connected, "greetings");
	else
		SetFailState("Can't find 'greetings' entry in sourcemod/configs/databases.cfg!");
}

public Connected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{			
		LogError("Failed to connect! Error: %s", error);
		return;
	}
			
	LogMessage("Donor Greetings online and connected to database!");
	//SQL_TQuery(hndl, SQLErrorCheckCallback, "SET NAMES 'utf8'");
	SQL_CreateTables(hndl);

	g_Database = hndl;
}

SQL_CreateTables(Handle:hndl)
{		
	new len = 0;
	decl String:query[1024];

	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS DonorGreetings (");
	len += Format(query[len], sizeof(query)-len, "id INTEGER PRIMARY KEY ASC, ");
	len += Format(query[len], sizeof(query)-len, "SteamID TEXT NOT NULL UNIQUE, ");
	len += Format(query[len], sizeof(query)-len, "Greeting TEXT NOT NULL, ");
	len += Format(query[len], sizeof(query)-len, "ClientDisabled INTEGER NOT NULL DEFAULT 0, ");
	len += Format(query[len], sizeof(query)-len, "AdminDisabled INTEGER NOT NULL DEFAULT 0);");
	if (bDebug)
	{	
		LogError(query);
	}
	SQL_TQuery(hndl, SQLErrorCheckCallback, query);
}

public OnClientPostAdminCheck(client)
{	
	if (IsFakeClient(client))
		return;

	new String:sName[255];
	
	if (!CheckCommandAccess(client, "greeting_override", ADMFLAG_RESERVATION))
	{
		GetClientName(client, sName, 64);
		CPrintToChatAll("{green}%s {default}has joined the game.", sName);
		return;
	}

	decl String:SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	decl String:query[512];
	Format(query, sizeof(query), "SELECT Greeting, ClientDisabled, AdminDisabled FROM DonorGreetings WHERE SteamID = '%s'; ", SteamID);
	if (bDebug)
		LogError(query);
	SQL_TQuery(g_Database, ProcessGreeting, query, GetClientUserId(client));
}

public ProcessGreeting(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (!StrEqual("", error))
	{
		LogError("SQL Error: %s", error);
		return;
	}
	new client = GetClientOfUserId(data);
	if (client == 0)
		return;
	decl String:DefaultMessage[128];
	GetConVarString(v_DefaultMessage, DefaultMessage, sizeof(DefaultMessage));
	if (!SQL_FetchRow(hndl))
	{
		// No message set
		PrintGreeting(client, DefaultMessage, sizeof(DefaultMessage), false);
		return;
	}
	//Result
	decl String:CustomMessage[128];
	SQL_FetchString(hndl, 0, CustomMessage, sizeof(CustomMessage));
	new iClientDisabled = SQL_FetchInt(hndl, 1);
	g_iAdminDisabled[client] = SQL_FetchInt(hndl, 2);

	if (iClientDisabled == 1)
		return;	//Client disabled their messages

	if (g_iAdminDisabled[client] == 1)
	{
		PrintGreeting(client, DefaultMessage, sizeof(DefaultMessage), false);	//Admin has disabled this player's messages
		return;
	}

	// Client's message isn't disabled
	TrimString(CustomMessage);
	if (StrEqual(CustomMessage, ""))
		PrintGreeting(client, DefaultMessage, sizeof(DefaultMessage), false);	//Message is blank
	else
	{
		PrintGreeting(client, CustomMessage, sizeof(CustomMessage), true);	//A message is set
	}
}

//	There are major problems that can happen if more then one {N} is attempted to be replaced.
//	This appears to be an issue in SM's core.  Just make sure the "message" string never has more then one {N} in it.
//	The string is checked when it is inserted, and ReplaceStringEx is used because it will only replace the first result.
PrintGreeting(client, String:message[], size, bool:bIsCustom)
{
	decl String:name[32];
	GetClientName(client, name, sizeof(name));
	decl String:WelcomeMsg[168];
	Format(WelcomeMsg, sizeof(WelcomeMsg), "{gold}[VIP] {green}%s {default}%s", (bIsCustom ? "" : name), message);
	ReplaceStringEx(WelcomeMsg, size, "{N}", name, -1, -1, false);	//will only replace one {N}
	CPrintToChatAll("%s", WelcomeMsg);
}

AdminDisableGreeting(client, iTarget)
{
	if (!CheckCommandAccess(iTarget, "greeting_override", ADMFLAG_RESERVATION))
	{
		ReplyToCommand(client, "%N doesn't have access to Greetings!", iTarget);
		return;
	}
	decl String:SteamID[32];
	GetClientAuthId(iTarget, AuthId_Steam2, SteamID, sizeof(SteamID));
	decl String:query[512];
	Format(query, sizeof(query), "UPDATE DonorGreetings SET AdminDisabled = '1' WHERE SteamID = '%s' AND Greeting IS NOT NULL AND Greeting != '' ; ", SteamID);	// If the player has no message set then the admin shouldn't be disabling it
	if (bDebug)
			LogError(query);
	SQL_TQuery(g_Database, ProcessGreeting, query);
	LogAction(client, iTarget, "%L disabled %L's Donor Greetings message", client, iTarget);
	ReplyToCommand(client, "%N's Donor Greetings message has been disabled.", iTarget);
	g_iAdminDisabled[iTarget] = 1;
}

AdminEnableGreeting(client, iTarget)
{
	if (!CheckCommandAccess(iTarget, "greeting_override", ADMFLAG_RESERVATION))
	{
		ReplyToCommand(client, "%N doesn't have access to Greetings!", iTarget);
		return;
	}
	decl String:SteamID[32];
	GetClientAuthId(iTarget, AuthId_Steam2, SteamID, sizeof(SteamID));
	decl String:query[512];
	Format(query, sizeof(query), "UPDATE DonorGreetings SET AdminDisabled = '0' WHERE SteamID = '%s' ; ", SteamID);
	if (bDebug)
			LogError(query);
	SQL_TQuery(g_Database, ProcessGreeting, query);
	LogAction(client, iTarget, "%L enabled %L's Donor Greetings message", client, iTarget);
	ReplyToCommand(client, "%N's Donor Greetings message has been re-enabled.", iTarget);
	g_iAdminDisabled[iTarget] = 0;
}

AdminResetGreeting(client, iTarget)
{
	if (!CheckCommandAccess(iTarget, "greeting_override", ADMFLAG_RESERVATION))
	{
		ReplyToCommand(client, "%N doesn't have access to Greetings!", iTarget);
		return;
	}
	decl String:SteamID[32];
	GetClientAuthId(iTarget, AuthId_Steam2, SteamID, sizeof(SteamID));
	decl String:query[512];
	Format(query, sizeof(query), "UPDATE DonorGreetings SET Greeting = '' WHERE SteamID = '%s' ; ", SteamID);	// Set a blank message
	if (bDebug)
			LogError(query);
	SQL_TQuery(g_Database, ProcessGreeting, query);
	LogAction(client, iTarget, "%L reset %L's Donor Greetings message", client, iTarget);
	ReplyToCommand(client, "%N's Donor Greetings message has been reset.", iTarget);
}

ClientDisableGreeting(client)
{
	if (!CheckCommandAccess(client, "greeting_override", ADMFLAG_RESERVATION))
	{
		ReplyToCommand(client, "[SM] You don't have access to this.");
		return;
	}
	decl String:SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	decl String:query[512];
	Format(query, sizeof(query), "INSERT OR REPLACE INTO DonorGreetings (SteamID, ClientDisabled) VALUES ('%s', '1')", SteamID);
	if (bDebug)
			LogError(query);
	SQL_TQuery(g_Database, ProcessGreeting, query);
	LogAction(client, client, "%L disabled their own Donor Greetings message", client);
	ReplyToCommand(client, "[SM] You disabled your Greeting Message,  To re-enable, type /enablegreeting");
}

ClientEnableGreeting(client)
{
	if (!CheckCommandAccess(client, "greeting_override", ADMFLAG_RESERVATION))
	{
		ReplyToCommand(client, "[SM] You don't have access to this.");
		return;
	}
	decl String:SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	decl String:query[512];
	Format(query, sizeof(query), "UPDATE DonorGreetings SET ClientDisabled = '0' WHERE SteamID = '%s' ; ", SteamID);	//Dont need to ON DUPLICATE KEY UPDATE here because the message default is enabled
	if (bDebug)
			LogError(query);
	SQL_TQuery(g_Database, ProcessGreeting, query);
	LogAction(client, client, "%L re-enabled their own Donor Greetings message", client);
	ReplyToCommand(client, "[SM] You re-enabled your Greeting Message,  To disable, type /disablegreeting");
}

ClientResetGreeting(client)
{
	if (!CheckCommandAccess(client, "greeting_override", ADMFLAG_RESERVATION))
	{
		ReplyToCommand(client, "[SM] You don't have access to this.");
		return;
	}
	decl String:SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	decl String:query[512];
	Format(query, sizeof(query), "UPDATE DonorGreetings SET Greeting = '' WHERE SteamID = '%s' ; ", SteamID);
	if (bDebug)
			LogError(query);
	SQL_TQuery(g_Database, ProcessGreeting, query);
	ReplyToCommand(client, "[SM] You reset your Greeting Message,  To set a new one, type /setgreeting <your message>");
}

ClientSetGreeting(client, String:message[], size)
{
	if (!CheckCommandAccess(client, "greeting_override", ADMFLAG_RESERVATION))
	{
		ReplyToCommand(client, "[SM] You don't have access to this.");
		return;
	}
	ReplaceString(message, size, "\%", "");
	decl String:SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	decl String:query[512];
	new String: buffer[384];
	SQL_EscapeString(g_Database, message, buffer, sizeof(buffer));
	Format(query, sizeof(query), "INSERT OR REPLACE INTO DonorGreetings (SteamID, Greeting) VALUES ('%s', '%s')", SteamID, buffer, buffer);
	if (bDebug)
			LogError(query);
	SQL_TQuery(g_Database, ProcessGreeting, query);

	decl String:name[32];
	GetClientName(client, name, sizeof(name));
	ReplaceStringEx(message, size, "{N}", name, -1, -1, false);	//will only replace one {N}
	ReplyToCommand(client, "\x01[SM] You set your Greeting Message to \"%s\x01\"", message);
}

public OnClientDisconnect(client)
{
	g_iAdminDisabled[client] = 0;
}

/* SQL Error Handler */
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (!StrEqual("", error))
	{
		LogError("SQL Error: %s", error);
	}
}
