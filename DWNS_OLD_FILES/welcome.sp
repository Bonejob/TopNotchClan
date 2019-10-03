#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "4-1-2012"
//#define Welcome_Sound "vo/demoman_dominationdemoman04.wav"
#define Success "vo/announcer_success.wav"
#define Failure "vo/announcer_failure.wav"

new bool:jointeam[MAXPLAYERS + 1] = { false };
new Handle:g_Database;

public Plugin:myinfo = 
{
	name = "Donator Welcome Message",
	author = "DWN",
	description = "Welcomes Donators",
	version = PLUGIN_VERSION,
	url = "http://www.topnotchclan.com"
};

public OnPluginStart()
{
	// Create the rest of the cvar's
	CreateConVar("sm_welcomemsg_version", PLUGIN_VERSION, "Welcome Donators Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_active", Command_Admins, "Displays active donators");
	HookEvent("player_spawn", Event_Player_Spawn, EventHookMode_Post);
	Database_Init();
}

public OnMapStart()
{
	//PrecacheSound(Welcome_Sound, true);
	PrecacheSound(Success, true);
	PrecacheSound(Failure, true);
}


public OnClientPostAdminCheck(client) 
{
	//EmitSoundToClient(client, Welcome_Sound);
	jointeam[client] = false;
}

public Action:Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsFakeClient(client) && IsPlayerAlive(client) && !jointeam[client])
	{
		CreateTimer(4.0, Timer_ChatMessageDelayed, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		jointeam[client] = true;
	}
	return Plugin_Continue;
}


public Action:Timer_ChatMessageDelayed(Handle:timer, any:userID)
{
	new	client = GetClientOfUserId(userID);
	if (DatabaseIntact() && client > 0 && IsClientInGame(client))
	{
		decl String:query[600], String:SteamID[32], String:SteamID_ESC[96];
		GetClientAuthString(client, SteamID, sizeof(SteamID));
		SQL_EscapeString(g_Database, SteamID, SteamID_ESC, sizeof(SteamID_ESC));
		
		Format(query, sizeof(query), "SELECT `vb_user`.`userid` as userid, (SELECT `expirydate` FROM `vb_subscriptionlog` WHERE userid=`vb_user`.`userid` AND status=1 AND expirydate > %i ORDER BY subscriptionid DESC LIMIT 1) AS expiry, (SELECT `subscriptionid` FROM `vb_subscriptionlog` WHERE userid=`vb_user`.`userid` AND status=1 AND expirydate > %i ORDER BY subscriptionid DESC LIMIT 1) as subscriptionid FROM `vb_user` LEFT JOIN `vb_userfield` ON `vb_user`.`userid`=`vb_userfield`.`userid` WHERE `vb_userfield`.`field6`='%s'", GetTime(), GetTime(), SteamID_ESC);
		SQL_TQuery(g_Database, CB_ChatMessage, query, userID);
	}
	else
	{
		if (client > 0 && IsClientConnected(client)) 
		{
			decl String:ChatMsg[300], String:ClientName[32];
			new Team = GetClientTeam(client);
			GetClientName(client, ClientName, sizeof(ClientName));
			Format(ChatMsg, 300, "\x05-----------------------------------------------\n\x01Welcome \x03%s!\n\x01Thank you for your contribution to the servers!\n\x05-----------------------------------------------", ClientName);
			
			if(IsClientInGame(client))
				if(Team == GetClientTeam(client))
					SayText2(client, ChatMsg);
		}	
	}
}


public CB_ChatMessage(Handle:owner, Handle:result, const String:error[], any:userID) 
{
	new client = GetClientOfUserId(userID);
	
	if(result == INVALID_HANDLE)
	{
		LogError("[SM] MYSQL ERROR (Welcome Announce - error: %s)", error);
	}
	
	if (client > 0 && IsClientConnected(client) && result != INVALID_HANDLE && SQL_HasResultSet(result) && SQL_GetRowCount(result) >= 1) 
	{
		SQL_FetchRow(result);
		decl String:ChatMsg[300], String:ClientName[32], String:Expiry_Date[64];
		new Team = GetClientTeam(client);
		GetClientName(client, ClientName, sizeof(ClientName));
		FormatTime(Expiry_Date, sizeof(Expiry_Date), "%A, %m/%d/%Y", SQL_FetchInt(result, 1));
		Format(ChatMsg, 300, "\x05-----------------------------------------------\n\x01Welcome \x03%s!\n\x01Thank you for your contribution to the servers!\nYour package expires on \x03%s\n\x05-----------------------------------------------", ClientName, Expiry_Date);
		
		if(IsClientInGame(client))
			if(Team == GetClientTeam(client))
				SayText2(client, ChatMsg);
	}
}
public CB_ExpiryMessage(Handle:owner, Handle:result, const String:error[], any:userID) 
{
	new client = GetClientOfUserId(userID);
	
	if(result == INVALID_HANDLE)
	{
		LogError("[SM] MYSQL ERROR (Welcome Announce - error: %s)", error);
	}
	
	if (client > 0 && IsClientConnected(client) && result != INVALID_HANDLE && SQL_HasResultSet(result) && SQL_GetRowCount(result) >= 1) 
	{
		SQL_FetchRow(result);
		decl Team;
		decl String:ChatMsg[300], String:Expiry_Date[64];
		Team = GetClientTeam(client);
		FormatTime(Expiry_Date, sizeof(Expiry_Date), "%A, %m/%d/%Y", SQL_FetchInt(result, 1));
		if (SQL_FetchInt(result, 2) != 5 && SQL_FetchInt(result, 2) != 6)
		{
			Format(ChatMsg, 300, "Your package expires on \x03%s", Expiry_Date);
		}
		else
		{
		Format(ChatMsg, 300, "Your package automatically reknews on \x03%s", Expiry_Date);
		}
		if(IsClientInGame(client))
			if(Team == GetClientTeam(client))
				SayText2(client, ChatMsg);
	}
}

public CB_Connect(Handle:owner, Handle:result, const String:error[], any:userID) 
{
	g_Database = result;
	if(g_Database == INVALID_HANDLE)
	{
		LogError("[Connect-Announce] Could not use database config, trying default.");
		SQL_TConnect(CB_Connect, "vbulletin", true);
	}

	if(g_Database != INVALID_HANDLE)
	{
		SQL_TQuery(g_Database, CB_ErrorOnly, "SET NAMES UTF8");  
		LogError("[Connect-Announce] Connected successfully.");
		return true;
	} 
	else 
	{
		LogError("[Connect-Announce] Connection Failed: %s", error);
		return false;
	}
}

public CB_ErrorOnly(Handle:owner, Handle:result, const String:error[], any:client)
{
	if(result == INVALID_HANDLE)
	{
		LogError("[Connect-Announce] MYSQL ERROR (error: %s)", error);
	}
}

public Action:Command_Admins(client, args)
{
	if (!client)
		return Plugin_Handled;
	new AdminId:id = GetUserAdmin(client),
		Handle:hMenu = CreateMenu(MenuCallback);
	decl String:sLine[255];
	SetMenuExitButton(hMenu, true);
	Format(sLine, sizeof(sLine), "(-TN-) Donator Status");
	if (id != INVALID_ADMIN_ID)
	{
		Format(sLine, sizeof(sLine), "%s\n \nYour VIP Package Is ACTIVE!", sLine); 
		AddMenuItem(hMenu, "1", "Check Expiration Date");
		AddMenuItem(hMenu, "2", "Bonus Round Settings");
		EmitSoundToClient(client, Success);
	}
	else
	{
		Format(sLine, sizeof(sLine), "%s\n \nIt does not look like you are a donator.\nIf you are, please visit our forums for assistance.\nPress 1 for info on how to donate.", sLine);
		AddMenuItem(hMenu, "3", "How To Donate");
		EmitSoundToClient(client, Failure);
	}
	SetMenuTitle(hMenu, sLine);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public MenuCallback(Handle:hMenu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new String:sSecltion[2], iSelection;
			GetMenuItem(hMenu, param2, sSecltion, sizeof(sSecltion));
			iSelection = StringToInt(sSecltion);
			switch (iSelection)
			{
				case 1:
				{
					if (DatabaseIntact())
					{
						decl String:query[800], String:SteamID[32], String:SteamID_ESC[96];
						GetClientAuthString(client, SteamID, sizeof(SteamID));
						SQL_EscapeString(g_Database, SteamID, SteamID_ESC, sizeof(SteamID_ESC));
						Format(query, sizeof(query), "SELECT `vb_user`.`userid` as userid, (SELECT `expirydate` FROM `vb_subscriptionlog` WHERE userid=`vb_user`.`userid` AND status=1 AND expirydate > %i ORDER BY subscriptionid DESC LIMIT 1) AS expiry, (SELECT `subscriptionid` FROM `vb_subscriptionlog` WHERE userid=`vb_user`.`userid` AND status=1 AND expirydate > %i ORDER BY subscriptionid DESC LIMIT 1) as subscriptionid FROM `vb_user` LEFT JOIN `vb_userfield` ON `vb_user`.`userid`=`vb_userfield`.`userid` WHERE `vb_userfield`.`field6`='%s'", GetTime(), GetTime(), SteamID_ESC);
						SQL_TQuery(g_Database, CB_ExpiryMessage, query, GetClientUserId(client));
					}
					else
					{
						PrintToChat(client, "We're sorry, but this server is not currently connected to the database");
					}
				}
				case 2:
				{
					FakeClientCommand(client, "sm_settings");
				}
				case 3:
				{
					ShowMOTDPanel(client, "PANEL_TITLE", "http://topnotchclan.com/showthread.php?813-How-To-Donate", MOTDPANEL_TYPE_URL);
				}
			}
		}		
	}
}

/*
public Action:Command_Admins(client, args)
{
	if (!client)
		return Plugin_Handled;
	
	new AdminId:id = GetUserAdmin(client);
	new Handle:panel = CreatePanel();
	
	SetPanelTitle(panel, "(-TN-) Donator Status");
	if (id != INVALID_ADMIN_ID)
	{
		DrawPanelText(panel, "Your VIP Package Is ACTIVE!");
		DrawPanelItem(panel, "Check Expiration Date");
		DrawPanelItem(panel, "VIP Settings");
		g_donator[client] = true;
	}
	else
	{
		DrawPanelText(panel, "It does not look like you are a donator.");
		DrawPanelText(panel, "If you are, please visit our forums for assistance.");
		DrawPanelText(panel, "Press 2 for info on how to donate.");
		DrawPanelItem(panel, "How To Donate");
	}
	DrawPanelItem(panel, "Exit Menu");
	SendPanelToClient(panel, client, PanelHandler, MENU_TIME_FOREVER);
	
	CloseHandle(panel);
	
	return Plugin_Handled;
}

//Dummy panel handler.
public PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 1) //Client saw the menu and decided to configure the settings.
		{
			if(g_donator[param1])
			{
				ShowMOTDPanel(param1, "PANEL_TITLE", "http://topnotchclan.com/showthread.php?t=829", MOTDPANEL_TYPE_URL);
			}
			else
			{
				ShowMOTDPanel(param1, "PANEL_TITLE", "http://www.topnotchclan.com/showthread.php?t=813", MOTDPANEL_TYPE_URL);
			}
		}
		else if(param2 == 2) //Client saw the menu but decided to exit it. Still marking cookie as shown.
		{
			if(g_donator[param1])
			{	
	        		FakeClientCommand(param1, "sm_settings");
			}
			else
			{
				return;
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 < 0) //Menu could not be drawn, shown, was overridden by another menu, or client disconnected. Do not mark cookie as shown.
		{
			return;
		} 
	}
}
*/

SayText2(to, const String:message[]) 
{
	new Handle:hBf = StartMessageOne("SayText2", to);
	
	if (hBf != INVALID_HANDLE) {
		BfWriteByte(hBf,   to);
		BfWriteByte(hBf,   true);
		BfWriteString(hBf, message);
		
		EndMessage();
	}
}

public DatabaseIntact()
{
	if(g_Database != INVALID_HANDLE)
	{
		return true;
	}
	return false;
}

stock Database_Init()
{
	SQL_TConnect(CB_Connect, "vbulletin");
}