#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "4.17.13"

new bool:g_MapStarted;
new bool:g_HasJoinedTeam[MAXPLAYERS + 1];

new String:g_FillerSteamID[32];

new ClientTypes:g_ClientType[MAXPLAYERS + 1];

enum ClientTypes
{
	Client_Filler = 0,
	Client_FillerRejoined,
	Client_Commoner,
	Client_AlreadyHasPerks
}

public Plugin:myinfo = 
{
	name = "Server Filling Perks",
	author = "Geit",
	description = "Gives perks to people who help to fill a server.",
	version = PL_VERSION,
	url = "http://www.topnotchclan.com"
};

public OnPluginStart()
{
	CreateConVar("sm_fillperks_version", PL_VERSION, "Server Filling Perks Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("player_spawn", Event_Player_Spawn, EventHookMode_Post);
}

public OnMapStart()
{
	CreateTimer(15.0, Timer_MapStartDelayed, _, TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd()
{
	g_MapStarted = false;
}

public OnClientDisconnect(client)
{
	g_HasJoinedTeam[client] = false;
}

public OnClientDisconnect_Post(client)
{
	if(g_MapStarted == true)
	{
		new players = 0;
		for(new i=1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				players++;
			}
		}
		
		if(players == 0)
		{
			g_FillerSteamID = "";
		}
	}
	
	g_HasJoinedTeam[client] = false;
}

public OnClientPostAdminCheck(client)
{
	new players = 0;
	for(new i=1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			players++;
		}
	}
	
	new String:ClientSteamID[32];
	GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
	
	if (players <= 6 && strlen(g_FillerSteamID) == 0 && !IsFakeClient(client) && (GetUserAdmin(client) == INVALID_ADMIN_ID))
	{
		strcopy(g_FillerSteamID, sizeof(g_FillerSteamID), ClientSteamID);
		AddUserFlags(client, AdminFlag:Admin_Reservation);
		g_ClientType[client] = Client_Filler;
		decl String:Name[32];
		GetClientName(client, Name, sizeof(Name));
		decl String:sAuth[256];
		GetClientAuthString(client, sAuth, sizeof(sAuth));
		LogToFileEx("addons/sourcemod/logs/filler.log", "Added %s (%s) as donator.", Name,sAuth);
		LogToFileEx("addons/sourcemod/logs/filler.log", "Number of players: %i", players);
	}
	else if(strlen(g_FillerSteamID) != 0 && strcmp(g_FillerSteamID, ClientSteamID)  == 0)
	{
		AddUserFlags(client, AdminFlag:Admin_Reservation);
		g_ClientType[client] = Client_FillerRejoined;
	}
	else if(GetUserFlagBits(client) & ADMFLAG_RESERVATION)
	{
		g_ClientType[client] = Client_AlreadyHasPerks;
	}
	else
	{
		g_ClientType[client] = Client_Commoner;
	}
}

public Action:Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsFakeClient(client) && IsPlayerAlive(client) && !g_HasJoinedTeam[client])
	{
		CreateTimer(4.0, Timer_ChatMessageDelayed, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		g_HasJoinedTeam[client] = true;
	}
	return Plugin_Continue;
}

public Action:Timer_ChatMessageDelayed(Handle:timer, any:userID)
{
	new	client = GetClientOfUserId(userID);
	
	if(client == 0)
	return;


	decl String:UserName[32];
	GetClientName(client, UserName, sizeof(UserName));
	switch(g_ClientType[client])
	{
		case Client_Filler:
		{	
			if (GetUserAdmin(client) == INVALID_ADMIN_ID) {
				PrintToChat(client, "Hi there %s! You appear to one of the first players here! Stick around and you'll be granted free VIP for the day as the server fills!", UserName);
			}
			else
			{
				return;
			}
		}
		case Client_FillerRejoined:
		{
			PrintToChat(client, "Hey, Welcome back %s! Because you helped to fill this server, you've earned free VIP status till it empties. Enjoy your time on this Top Notch Clan server!", UserName);
			LogToFileEx("addons/sourcemod/logs/filler.log", "%s rejoined the server as a winner.", UserName);
		}
		case Client_Commoner:
		{
			PrintToChat(client, "Hi %s! Did you know: If you are the first person on a Top Notch Clan Server and help to fill it, you'll be granted free VIP for a day?", UserName);
		}
	}
}

public Action:Timer_MapStartDelayed(Handle:timer, any:none)
{
	g_MapStarted = true;
}