#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <dbi>

#define PLUGIN_VERSION "1.1.0"
#define STEAM_BUFFER 64
#define ESCAPED_STEAM_BUFFER 130
#define QUERY_BUFFER 256
//#define CURDATEDEF date('now')

#undef REQUIRE_PLUGIN
#include <adminmenu>

public Plugin:myinfo = 
{
	name = "WatchList",
	author = "Dmustanger",
	description = "Sets players to a WatchList.",
	version = PLUGIN_VERSION,
	url = "http://thewickedclowns.net"
}

new Handle:Database = INVALID_HANDLE;
new Handle:hTopMenu = INVALID_HANDLE;
new Handle:CvarHostIp;
new Handle:CvarPort;
new Handle:WatchlistTimer = INVALID_HANDLE;
new Handle:CvarWatchlistAnnounceInterval = INVALID_HANDLE;
new Handle:CvarWatchlistSound = INVALID_HANDLE;
new Handle:CvarWatchlistLog = INVALID_HANDLE;
new targets[MAXPLAYERS];
new String:logFile[PLATFORM_MAX_PATH];
new String:ServerIp[50];
new String:ServerPort[25];
new WatchlistLog = 0;
new const String:WatchlistSound[] = "resource/warning.wav";
new bool:IsWatchlistSoundEnabled = false;

public OnPluginStart()
{
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/watchlist.log");
	CreateConVar("watchlist_version", PLUGIN_VERSION, "WatchList Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	if (!SQL_CheckConfig("default"))
	{
		SetFailState("databases.cfg is not filled out correctly.");
	}
	else
	{
		LoadTranslations("watchlist.phrases");
		LoadTranslations("common.phrases");
		CvarHostIp = FindConVar("hostip");
		CvarPort = FindConVar("hostport");
		RegAdminCmd("watchlist_add", Command_Watchlist_Add, ADMFLAG_KICK, "watchlist_add \"steam_id | #userid | name\" \"reason\"", "Adds a player to the watchlist.");
		RegAdminCmd("watchlist_remove", Command_Watchlist_Remove, ADMFLAG_KICK, "watchlist_remove \"steam_id | #userid | name\"", "Removes a player from the watchlist.");
		RegAdminCmd("watchlist_query", Command_Watchlist_Query, ADMFLAG_KICK, "watchlist_query", "Queries the Watchlist database and displays everyone in it to the console.");
		CvarWatchlistAnnounceInterval = CreateConVar("watchlist_announce_interval", "1.0",
				"Controls how often users on the watchlist \nwho are currently on the server are announced. \nThe time is specified in whole minutes (1.0...10.0).", FCVAR_NONE,	true, 1.0, true, 10.0);
		SQL_TConnect(GotDatabase, "watchlist");
		GetIpPort();
		WatchlistTimer = CreateTimer(60.0, ShowWatchlist, INVALID_HANDLE, TIMER_REPEAT);
		CvarWatchlistSound = CreateConVar("watchlist_sound_enabled", "0", "Plays a warning sound to admins when \na WatchList player is announced. \n1 to Enable. \n0 to Disable.");
		CvarWatchlistLog = CreateConVar("watchlist_logging_enabled", "0", "Enables logging. \n1 to Enable. \n2 for more debug logging. \n0 to Disable.");
		HookConVarChange(CvarWatchlistAnnounceInterval, WatchlistAnnounceChange);
		HookConVarChange(CvarWatchlistSound, WatchlistSoundChange);
		HookConVarChange(CvarWatchlistLog, WatchlistLogChange);
		AutoExecConfig(true, "watchlist");
	}
}

public OnMapStart()
{
	PrecacheSound(WatchlistSound, true);
	if (IsSoundPrecached(WatchlistSound))
	{
		if (WatchlistLog == 2)
		{
			LogToFile(logFile, "WatchlistSound %s has been precached.", WatchlistSound);
		}
	}
	else
	{
		if (WatchlistLog == 2)
		{
			LogToFile(logFile, "WatchlistSound %s has not been precached.", WatchlistSound);
		}
	}
}

public GetIpPort()
{
	decl String:ip[4];
	new longip = GetConVarInt(CvarHostIp);
	ip[0] = (longip >> 24) & 0x000000FF;
	ip[1] = (longip >> 16) & 0x000000FF;
	ip[2] = (longip >> 8) & 0x000000FF;
	ip[3] = longip & 0x000000FF;
	Format(ServerIp, sizeof(ServerIp), "%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]);
	GetConVarString(CvarPort, ServerPort, sizeof(ServerPort));
}

//===================================Hooks============================================================
public WatchlistAnnounceChange(Handle:cvar, const String:oldVal[], const String:newVal[]) 
{
	CloseHandle(WatchlistTimer);
	WatchlistTimer = CreateTimer(StringToInt(newVal) * 60.0, ShowWatchlist, INVALID_HANDLE, TIMER_REPEAT);	
}

public WatchlistSoundChange(Handle:cvar, const String:oldValue[], const String:newValue[]) 
{
	if (GetConVarBool(cvar))
	{
		IsWatchlistSoundEnabled = true;
	}
	else
	{
		IsWatchlistSoundEnabled = false;
	}
}

public WatchlistLogChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new WatchlistLogMode = StringToInt(newVal);
	if (WatchlistLogMode == 1)
	{
		WatchlistLog = 1;
	}
	else if (WatchlistLogMode == 2)
	{
		WatchlistLog = 2;
	}
	else
	{
		WatchlistLog = 0;
	}
} 

//===================================DATABASE============================================================
public GotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Query failed. Could not connect to the database: %s", error);
	}
	else 
	{
		Database = hndl;
		dbtable();
	}	
}

dbtable()
{
	decl String:dbtype[64];
	decl String:query[QUERY_BUFFER];
	SQL_ReadDriver(Database, dbtype, sizeof(dbtype));
	if(strcmp(dbtype, "sqlite", false) == 0)
	{
		//query = "CREATE TABLE IF NOT EXISTS watchlist (ingame INTEGER NOT NULL, steamid TEXT PRIMARY KEY ON CONFLICT REPLACE, serverip TEXT, serverport TEXT, reason TEXT NOT NULL, name TEXT, date TEXT NOT NULL);";
		query = "CREATE TABLE IF NOT EXISTS watchlist (ingame INTEGER NOT NULL, steamid TEXT PRIMARY KEY ON CONFLICT REPLACE, serverip TEXT, serverport TEXT, reason TEXT NOT NULL, name TEXT);";
	}
	else
	{
		//query = "CREATE TABLE IF NOT EXISTS watchlist (ingame INT NOT NULL, steamid VARCHAR(50) NOT NULL, serverip VARCHAR(40), serverport VARCHAR(20), reason TEXT NOT NULL, name VARCHAR(100), date DATE, PRIMARY KEY (steamid)) ENGINE = InnoDB;";
		query = "CREATE TABLE IF NOT EXISTS watchlist (ingame INT NOT NULL, steamid VARCHAR(50) NOT NULL, serverip VARCHAR(40), serverport VARCHAR(20), reason TEXT NOT NULL, name VARCHAR(100), PRIMARY KEY (steamid)) ENGINE = InnoDB;";
		//#undef CURDATEDEF	
		//#define CURDATEDEF CURDATE()
	}
	SQL_TQuery(Database, T_Generic, query);
}

public T_Generic(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		if (WatchlistLog == 2)
		{
			LogToFile(logFile, "Query Failed T_generic: %s", error);
		}
	}
}

//===================================ADMIN MENU============================================================
public OnAllPluginsLoaded() 
{
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);	
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu)
	{
		return;
	}
	hTopMenu = topmenu;
	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu, "watchlist_add", TopMenuObject_Item, MenuWatchlistAdd, player_commands, "watchlist_add");
		AddToTopMenu(hTopMenu, "watchlist_remove", TopMenuObject_Item, MenuWatchlistRemove, player_commands, "watchlist_remove");		 
	}
}

public MenuWatchlistAdd(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)	
	{
		Format(buffer, maxlength, "%T", "Watchlist_Add_Menu", param, param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		WatchlistAddTargetMenu(param);
	}
}

WatchlistAddTargetMenu(client) 
{
	new Handle:menu = CreateMenu(MenuWatchlistAddTarget);
	decl String:title[100];
	Format(title, sizeof(title), "%T", "Watchlist_Add_Menu", client, client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	AddTargetsToMenu(menu, client, false, false);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuWatchlistAddTarget (Handle:menu, MenuAction:action, param1, param2) 
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32], String:name[MAX_NAME_LENGTH];
		new userid, target;
		GetMenuItem(menu, param2, info, sizeof(info), _, name, sizeof(name));
		userid = StringToInt(info);
		if ((target = GetClientOfUserId(userid)) == 0 || !CanUserTarget(param1, target))
		{
			ReplyToTargetError(param1, COMMAND_TARGET_NOT_IN_GAME);
		}
		else
		{
			targets[param1] = target;
			WatchlistReasonMenu(param1);
		}
	}
}

WatchlistReasonMenu(client) 
{
	new Handle:menu = CreateMenu(WatchlistAddReasonMenu);
	decl String:title[100];
	Format(title, sizeof(title), "%T", "Watchlist_Add_Menu", client, client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);	
	AddMenuItem(menu, "Aimbot", "Aimbot");
	AddMenuItem(menu, "Speedhack", "Speedhack");
	AddMenuItem(menu, "Spinbot", "Spinbot");
	AddMenuItem(menu, "Team Killing", "Team Killing");
	AddMenuItem(menu, "Mic Spam", "Mic Spam");
	AddMenuItem(menu, "Breaking server rules", "Breaking server rules");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public WatchlistAddReasonMenu (Handle:menu, MenuAction:action, param1, param2) 
{	
	if (action == MenuAction_End)
	{		
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:reason[QUERY_BUFFER];
		decl String:reason_name[QUERY_BUFFER];
		decl String:steam[STEAM_BUFFER];
		decl String:d_steam[ESCAPED_STEAM_BUFFER];
		decl String:query[QUERY_BUFFER];
		decl String:S_client[25];
		decl String:S_target[25];
		new target = targets[param1];
		GetClientAuthString(target, steam, sizeof(steam));
		GetMenuItem(menu, param2, reason, sizeof(reason), _, reason_name, sizeof(reason_name));
		SQL_EscapeString(Database, steam, d_steam, sizeof(d_steam));
		Format(query, sizeof(query), "SELECT * FROM watchlist WHERE steamid = '%s'", d_steam);
		IntToString(param1, S_client, sizeof(S_client));
		IntToString(target, S_target, sizeof(S_target));
		new Handle:CheckWatchlistAddReasonMenu = CreateDataPack();
		WritePackString(CheckWatchlistAddReasonMenu, S_client);
		WritePackString(CheckWatchlistAddReasonMenu, S_target);
		WritePackString(CheckWatchlistAddReasonMenu, d_steam);
		WritePackString(CheckWatchlistAddReasonMenu, reason);
		SQL_TQuery(Database, T_CommandWatchlistAdd, query, CheckWatchlistAddReasonMenu);
	}	
}

public MenuWatchlistRemove(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Watchlist_Remove_Menu", param, param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		FindWatchlistTargetsMenu(param);
	}
}

FindWatchlistTargetsMenu(client) 
{
	decl String:query[QUERY_BUFFER];
	Format(query, sizeof(query), "SELECT * FROM watchlist");
	SQL_TQuery(Database, WatchlistRemoveTargetMenu, query, client);
}

public WatchlistRemoveTargetMenu(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		if (WatchlistLog == 2)
		{
			LogToFile(logFile, "Query Failed WatchlistRemoveTargetMenu: %s", error);
		}
	}
	else
	{
		new Handle:menu = CreateMenu(MenuWatchlistRemoveTarget);
		decl String:title[100];
		Format(title, sizeof(title), "%T", "Watchlist_Remove_Menu", data, data);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		new bool:noClients = true;
		while (SQL_FetchRow(hndl))
		{
			decl String:target[ESCAPED_STEAM_BUFFER];
			decl String:name[MAX_NAME_LENGTH];
			SQL_FetchString(hndl, 5, name, sizeof(name));
			SQL_FetchString(hndl, 1, target, sizeof(target));
			AddMenuItem(menu, target, name);
			if (noClients)
			{
				noClients = false;
			}
		}
		if (noClients)
		{
			decl String:text[QUERY_BUFFER];
			Format(text, sizeof(text), "%T", "Watchlist_Query_Empty", data);
			AddMenuItem(menu, "noClients", text);
		}
		DisplayMenu(menu, data, MENU_TIME_FOREVER);		
	}
}

public MenuWatchlistRemoveTarget(Handle:menu, MenuAction:action, param1, param2) 
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:target[ESCAPED_STEAM_BUFFER];
		decl String:junk[QUERY_BUFFER];
		GetMenuItem(menu, param2, target, sizeof(target), _, junk, sizeof(junk));
		if (strcmp(target, "noClients", true) == 0) 
		{
			return;
		}
		else
		{
			WatchlistRemove(param1, target);
		}
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hTopMenu = INVALID_HANDLE;
	}
}

//===================================PRINTING TO ADMINS============================================================
public PrintToAdmins(String:text[])
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientTimingOut(i))
		{
			if ((GetUserFlagBits(i) == ADMFLAG_KICK) || (GetUserFlagBits(i) == ADMFLAG_ROOT))
			{
				PrintToChat(i, "%s", text);
				if (IsWatchlistSoundEnabled)
				{
					if (IsSoundPrecached(WatchlistSound))
					{
						EmitSoundToClient(i, WatchlistSound);
					}
				}
			}
		}	
	}
}

//===================================CHECKING CLIENTS============================================================
public OnClientPostAdminCheck(client)
{
	if (!IsFakeClient(client))
	{
		if ((GetUserFlagBits(client) != ADMFLAG_GENERIC) || (GetUserFlagBits(client) != ADMFLAG_ROOT))
		{
			decl String:steam[STEAM_BUFFER];
			decl String:d_steam[ESCAPED_STEAM_BUFFER];
			decl String:query[QUERY_BUFFER];
			GetClientAuthString(client, steam, sizeof(steam));
			SQL_EscapeString(Database, steam, d_steam, sizeof(d_steam));
			Format(query, sizeof(query), "SELECT * FROM watchlist WHERE steamid = '%s'", d_steam);
			SQL_TQuery(Database, T_CheckUser, query, client);
		}
	}
}

public T_CheckUser(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		if (WatchlistLog == 2)
		{
			LogToFile(logFile, "Query Failed T_CheckUser: %s", error);
		}
	}
	else
	{
		if (SQL_FetchRow(hndl))
		{
			if (IsClientInGame(data) && !IsClientTimingOut(data) && !IsClientInKickQueue(data))
			{
				decl String:d_ServerIp[100];
				decl String:d_ServerPort[50];
				decl String:name[MAX_NAME_LENGTH];
				decl String:d_name[100];	
				decl String:steam[STEAM_BUFFER];
				decl String:d_steam[ESCAPED_STEAM_BUFFER];
				decl String:reason[512];
				decl String:query[QUERY_BUFFER];
				decl String:text[QUERY_BUFFER];		
				SQL_EscapeString(Database, ServerIp, d_ServerIp, sizeof(d_ServerIp));
				SQL_EscapeString(Database, ServerPort, d_ServerPort, sizeof(d_ServerPort));
				GetClientName(data, name, sizeof(name));
				SQL_EscapeString(Database, name, d_name, sizeof(d_name));
				GetClientAuthString(data, steam, sizeof(steam));
				SQL_EscapeString(Database, steam, d_steam, sizeof(d_steam));
				SQL_FetchString(hndl, 4, reason, sizeof(reason));
				//Format(query, sizeof(query), "UPDATE watchlist SET ingame = %i, serverip = '%s', serverport = '%s', name = '%s', date = 'CURDATEDEF' WHERE steamid = '%s'", data, d_ServerIp, d_ServerPort, d_name, d_steam);
				Format(query, sizeof(query), "UPDATE watchlist SET ingame = %i, serverip = '%s', serverport = '%s', name = '%s' WHERE steamid = '%s'", data, d_ServerIp, d_ServerPort, d_name, d_steam);
				SQL_TQuery(Database, T_Generic, query);
				Format(text, sizeof(text), "%T", "Watchlist_Player_Join", LANG_SERVER, name, d_steam, reason);
				PrintToAdmins(text);
				if (WatchlistLog >= 1)
				{
					LogToFile(logFile, text);
				}
			}
		}
	}
}

public OnClientDisconnect(client)
{
	if (!IsFakeClient(client))
	{
		if ((GetUserFlagBits(client) != ADMFLAG_GENERIC) || (GetUserFlagBits(client) != ADMFLAG_ROOT))
		{
			decl String:name[MAX_NAME_LENGTH];
			decl String:steam[STEAM_BUFFER];
			decl String:d_steam[ESCAPED_STEAM_BUFFER];
			decl String:query[QUERY_BUFFER];
			GetClientName(client, name, sizeof(name));
			GetClientAuthString(client, steam, sizeof(steam));
			SQL_EscapeString(Database, steam, d_steam, sizeof(d_steam));
			//Format(query, sizeof(query), "UPDATE watchlist SET ingame = 0, serverip = '0.0.0.0', serverport = '00000', date = 'CURDATEDEF' WHERE steamid = '%s'", d_steam);
			Format(query, sizeof(query), "UPDATE watchlist SET ingame = 0, serverip = '0.0.0.0', serverport = '00000' WHERE steamid = '%s'", d_steam);
			SQL_TQuery(Database, T_Generic, query);
		}
	}
}

//===================================TIMER============================================================
public Action:ShowWatchlist(Handle:timer, Handle:pack)
{
	decl String:d_ServerIp[100];
	decl String:d_ServerPort[50];
	decl String:query[QUERY_BUFFER];
	SQL_EscapeString(Database, ServerIp, d_ServerIp, sizeof(d_ServerIp));
	SQL_EscapeString(Database, ServerPort, d_ServerPort, sizeof(d_ServerPort));
	Format(query, sizeof(query), "SELECT * FROM watchlist WHERE serverip = '%s' AND serverport = '%s' AND ingame > 0", d_ServerIp, d_ServerPort);
	SQL_TQuery(Database, T_ShowWatchlist, query);
}

public T_ShowWatchlist(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		if (WatchlistLog == 2)
		{
			LogToFile(logFile, "Query Failed T_ShowWatchlist: %s", error);
		}
	}
	else
	{
		while (SQL_FetchRow(hndl))
		{
			decl client;
			decl String:name[MAX_NAME_LENGTH];
			decl String:steam[STEAM_BUFFER];
			decl String:steamid[ESCAPED_STEAM_BUFFER];
			decl String:reason[QUERY_BUFFER];
			decl String:text[QUERY_BUFFER];
			client = SQL_FetchInt(hndl, 0);
			SQL_FetchString(hndl, 1, steamid, sizeof(steamid));
			GetClientAuthString(client, steam, sizeof(steam));
			if (StrEqual(steam, steamid, false))
			{
				GetClientName(client, name, sizeof(name));
				SQL_FetchString(hndl, 4, reason, sizeof(reason));
				Format(text, sizeof(text), "%T", "Watchlist_Timer_Announce", LANG_SERVER, name, steam, reason);
				PrintToAdmins(text);
				if (WatchlistLog == 2)
				{
					LogToFile(logFile, text);
				}
			}
			else
			{
				decl String:query[QUERY_BUFFER];
				Format(query, sizeof(query), "UPDATE watchlist SET ingame = 0, serverip = '0.0.0.0', serverport = '00000' WHERE steamid = '%s'", steamid);
				SQL_TQuery(Database, T_Generic, query);
			}
		}
	}
}

//===================================COMMAND WATCHLIST ADD============================================================
public Action:Command_Watchlist_Add (client, args) 
{
	decl String:player_id[50];
	decl String:steam[STEAM_BUFFER];
	decl String:reason[QUERY_BUFFER];
	new target = -1;
	if (GetCmdArgs() < 2) 
	{
		ReplyToCommand(client, "USAGE: watchlist_add \"steam_id | #userid | name\" \"reason\"");
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, player_id, sizeof(player_id));
		if (StrContains(player_id, "STEAM_", false) != -1)
		{
			if (strlen(player_id) < 10)
			{
				ReplyToCommand(client, "USAGE: watchlist_add \"steam_id | #userid | name\" \"reason\"");
				return Plugin_Handled;
			}
			else
			{
				steam = player_id;
			}
		}
		else
		{
			target = FindTarget(client, player_id);
			if (target > 0)
			{
				GetClientAuthString(target, steam, sizeof(steam));
			}
			else
			{
				ReplyToTargetError(client, COMMAND_TARGET_NOT_IN_GAME);
				return Plugin_Handled;
			}
		}
		decl String:S_client[25];
		decl String:S_target[25];
		decl String:d_steam[ESCAPED_STEAM_BUFFER];
		decl String:query[QUERY_BUFFER];
		GetCmdArg(2, reason, sizeof(reason));
		SQL_EscapeString(Database, steam, d_steam, sizeof(d_steam));
		Format(query, sizeof(query), "SELECT * FROM watchlist WHERE steamid = '%s'", d_steam);
		IntToString(client, S_client, sizeof(S_client));
		IntToString(target, S_target, sizeof(S_target));
		new Handle:CheckWatchlistAddPack = CreateDataPack();
		WritePackString(CheckWatchlistAddPack, S_client);
		WritePackString(CheckWatchlistAddPack, S_target);
		WritePackString(CheckWatchlistAddPack, d_steam);
		WritePackString(CheckWatchlistAddPack, reason);
		SQL_TQuery(Database, T_CommandWatchlistAdd, query, CheckWatchlistAddPack);
		return Plugin_Handled;
	}
}

public T_CommandWatchlistAdd(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE) 
	{
		if (WatchlistLog == 2)
		{
			LogToFile(logFile, "Query Failed T_CommandWatchlistAdd: %s", error);
		}
	}
	else
	{
		decl String:S_client[25];
		decl String:S_target[25];
		decl String:d_steam[ESCAPED_STEAM_BUFFER];
		decl String:reason[QUERY_BUFFER];
		decl String:s_reason[QUERY_BUFFER];
		ResetPack(data);
		ReadPackString(data, S_client, sizeof(S_client));
		ReadPackString(data, S_target, sizeof(S_target));
		ReadPackString(data, d_steam, sizeof(d_steam));
		ReadPackString(data, reason, sizeof(reason));
		new client = StringToInt(S_client);
		new target = StringToInt(S_target);
		if (SQL_FetchRow(hndl))
		{
			decl String:text[QUERY_BUFFER];
			SQL_FetchString(hndl, 4, s_reason, sizeof(s_reason));
			Format(text, sizeof(text), "%T", "Watchlist_Add", client, d_steam, s_reason);
			if (client > 0)
			{
				PrintToChat(client, text);
			}
			else
			{
				ReplyToCommand(client, text);
			}
		}
		else
		{
			WatchlistAdd(client, target, d_steam, reason);
		}
	}
	CloseHandle(data);
}

WatchlistAdd(client, target, String:steam[], String:reason[]) 
{
	decl String:S_client[25];
	decl String:d_reason[512];
	decl String:query[512];
	SQL_EscapeString(Database, reason, d_reason, sizeof(d_reason));
	if (target > 0) 
	{
		decl String:d_ServerIp[100];
		decl String:d_ServerPort[50];
		decl String:player_name[MAX_NAME_LENGTH];
		decl String:d_player_name[101];
		SQL_EscapeString(Database, ServerIp, d_ServerIp, sizeof(d_ServerIp));
		SQL_EscapeString(Database, ServerPort, d_ServerPort, sizeof(d_ServerPort));
		GetClientName(target, player_name, sizeof(player_name));
		SQL_EscapeString(Database, player_name, d_player_name, sizeof(d_player_name));
		//Format(query, sizeof(query), "INSERT INTO watchlist (ingame, steamid, serverip, serverport, reason, name, date) VALUES (%i, '%s', '%s', '%s', '%s', '%s', 'CURDATEDEF')", target, steam, d_ServerIp, d_ServerPort, d_reason, d_player_name);
		Format(query, sizeof(query), "INSERT INTO watchlist (ingame, steamid, serverip, serverport, reason, name, date) VALUES (%i, '%s', '%s', '%s', '%s', '%s')", target, steam, d_ServerIp, d_ServerPort, d_reason, d_player_name);
	}
	else
	{
		//Format(query, sizeof(query), "INSERT INTO watchlist (ingame, steamid, reason, date) VALUES (%i, '%s', '%s', 'CURDATEDEF')", target, steam, d_reason);
		Format(query, sizeof(query), "INSERT INTO watchlist (ingame, steamid, reason, date) VALUES (%i, '%s', '%s')", target, steam, d_reason);								
	}
	IntToString(client, S_client, sizeof(S_client));
	new Handle:WatchlistAddPack = CreateDataPack();
	WritePackString(WatchlistAddPack, S_client);
	WritePackString(WatchlistAddPack, steam);
	WritePackString(WatchlistAddPack, d_reason);
	SQL_TQuery(Database, T_WatchlistAdd, query, WatchlistAddPack);
}		
	
public T_WatchlistAdd(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
	decl String:text[QUERY_BUFFER];
	decl String:S_client[25];
	decl String:d_steam[ESCAPED_STEAM_BUFFER];
	decl String:d_reason[512];
	ResetPack(data);
	ReadPackString(data, S_client, sizeof(S_client));
	ReadPackString(data, d_steam, sizeof(d_steam));
	ReadPackString(data, d_reason, sizeof(d_reason));
	CloseHandle(data);
	new client = StringToInt(S_client);
	if (hndl == INVALID_HANDLE) 
	{
		Format(text, sizeof(text), "%T", "Watchlist_Add_Fail", client, d_steam);
		if (WatchlistLog >= 1)
		{
			LogToFile(logFile, text);
		}
		if (WatchlistLog == 2)
		{
			LogToFile(logFile, "Query Failed T_WatchlistAdd: %s", error);
		}			
	}
	else
	{
		Format(text, sizeof(text), "%T", "Watchlist_Add_Success", client, d_steam, d_reason);
		if (WatchlistLog >= 1)
		{
			LogToFile(logFile, text);
		}
	}
	if (client > 0)
	{
		PrintToChat(client, text);
	}
	else
	{
		ReplyToCommand(client, text);
	}
}

//===================================COMMAND WATCHLIST REMOVE============================================================
public Action:Command_Watchlist_Remove (client, args) 
{
	decl String:player_id[50];
	decl String:steam[STEAM_BUFFER];
	decl String:S_client[25];
	decl String:query[QUERY_BUFFER];
	decl String:d_steam[ESCAPED_STEAM_BUFFER];
	new target = -1;
	if (GetCmdArgs() < 1) 
	{
		ReplyToCommand(client, "USAGE: watchlist_remove \"steam_id | #userid | name\"");
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, player_id, sizeof(player_id));
		if (StrContains(player_id, "STEAM_", false) != -1)
		{
			if (strlen(player_id) < 10)
			{
				ReplyToCommand(client, "USAGE: watchlist_remove \"steam_id | #userid | name\"");
				return Plugin_Handled;
			}
			else
			{
				steam = player_id;
			}
		}
		else
		{
			target = FindTarget(client, player_id);
			if (target > 0)
			{
				GetClientAuthString(target, steam, sizeof(steam));
			}
			else
			{
				ReplyToTargetError(client, COMMAND_TARGET_NOT_IN_GAME);
				return Plugin_Handled;
			}
		}
		IntToString(client, S_client, sizeof(S_client));
		SQL_EscapeString(Database, steam, d_steam, sizeof(d_steam));
		Format(query, sizeof(query), "SELECT * FROM watchlist WHERE steamid = '%s'", d_steam);
		new Handle:CheckWatchlistRemovePack = CreateDataPack();
		WritePackString(CheckWatchlistRemovePack, S_client);
		WritePackString(CheckWatchlistRemovePack, d_steam);
		SQL_TQuery(Database, T_CommandWatchlistRemove, query, CheckWatchlistRemovePack);
		return Plugin_Handled;
	}
}

public T_CommandWatchlistRemove(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
	if (hndl == INVALID_HANDLE) 
	{
		if (WatchlistLog == 2)
		{
			LogToFile(logFile, "Query Failed T_CommandWatchlistRemove: %s", error);
		}
	}
	else
	{
		decl String:S_client[25];
		decl String:d_steam[ESCAPED_STEAM_BUFFER];
		ResetPack(data);
		ReadPackString(data, S_client, sizeof(S_client));
		ReadPackString(data, d_steam, sizeof(d_steam));
		new client = StringToInt(S_client);
		if (SQL_FetchRow(hndl))
		{
			WatchlistRemove(client, d_steam);
		}
		else
		{
			decl String:text[QUERY_BUFFER];
			Format(text, sizeof(text), "%T", "Watchlist_Remove", client, d_steam);
			if (client > 0)
			{
				PrintToChat(client, text);
			}
			else
			{
				ReplyToCommand(client, text);
			}
		}
	}
	CloseHandle(data);
}

WatchlistRemove(client, String:steam[]) 
{
	decl String:S_client[25];
	decl String:query[QUERY_BUFFER];
	Format(query, sizeof(query), "DELETE FROM watchlist WHERE steamid = '%s'", steam);	
	IntToString(client, S_client, sizeof(S_client));
	new Handle:WatchlistRemovePack = CreateDataPack();
	WritePackString(WatchlistRemovePack, S_client);
	WritePackString(WatchlistRemovePack, steam);
	SQL_TQuery(Database, T_WatchlistRemove, query, WatchlistRemovePack);
}

public T_WatchlistRemove(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
	decl String:text[QUERY_BUFFER];
	decl String:S_client[25];
	decl String:d_steam[ESCAPED_STEAM_BUFFER];
	ResetPack(data);
	ReadPackString(data, S_client, sizeof(S_client));
	ReadPackString(data, d_steam, sizeof(d_steam));
	CloseHandle(data);
	new client = StringToInt(S_client);
	if (hndl == INVALID_HANDLE) 
	{
		Format(text, sizeof(text), "%T", "Watchlist_Remove_Fail", client, d_steam);
		if (WatchlistLog >= 1)
		{
			LogToFile(logFile, text);
		}
		if (WatchlistLog == 2)
		{
			LogToFile(logFile, "Query Failed T_WatchlistRemove: %s", error);
		}
	}
	else 
	{
		Format(text, sizeof(text), "%T", "Watchlist_Remove_Success", client, d_steam);
		if (WatchlistLog >= 1)
		{
			LogToFile(logFile, text);
		}
	}
	if (client > 0)
	{
		PrintToChat(client, text);
	}
	else
	{
		ReplyToCommand(client, text);
	}
}

//===================================Command Watchlist Query============================================================
public Action:Command_Watchlist_Query (client, args)
{
	decl String:query[QUERY_BUFFER];
	Format(query, sizeof(query), "SELECT * FROM watchlist");
	SQL_TQuery(Database, T_WatchlistQuery, query, client);
}

public T_WatchlistQuery(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
	if (hndl == INVALID_HANDLE) 
	{
		if (WatchlistLog == 2)
		{
			LogToFile(logFile, "Query Failed T_WatchlistQuery: %s", error);
		}
	}
	else
	{
		decl String:text[QUERY_BUFFER];
		Format(text, sizeof(text), "%T", "Watchlist_Query_Header", data);
		new bool:nodata = true;
		PrintToConsole(data, text);
		while (SQL_FetchRow(hndl))
		{
			decl String:steamid[ESCAPED_STEAM_BUFFER];
			decl String:name[100];
			decl String:reason[512];
			//decl String:date[100];
			SQL_FetchString(hndl, 1, steamid, sizeof(steamid));
			SQL_FetchString(hndl, 5, name, sizeof(name));
			SQL_FetchString(hndl, 4, reason, sizeof(reason));
			//SQL_FetchString(hndl, 6, date, sizeof(date));
			//PrintToConsole(data, "%s, %s, %s, %s", steamid, name, reason, date);
			PrintToConsole(data, "%s, %s, %s, %s", steamid, name, reason);
			if (nodata)
			{
				nodata = false;
			}
		}
		if (nodata)
		{
			PrintToConsole(data, "%T", "Watchlist_Query_Empty", data);
		}
		PrintToConsole(data, text);
	}
}



