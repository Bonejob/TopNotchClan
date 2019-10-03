#include <sourcemod>
#include <sdktools>

#define SUPPRESS_VERSION "1.1.0"

public Plugin:myinfo = 
{
	name = "Simple Message Suppression",
	author = "FlyingMongoose, psychonic",
	description = "Suppresses Different Messages",
	version = SUPPRESS_VERSION,
	url = "http://www.simple-plugins.com/"
}

new Handle:cvarBlockSpectateMessage;
new Handle:cvarBlockDisconnectMessage;
new Handle:cvarBlockConnectMessage;
new Handle:cvarAdminShowMessages;
new iSpecTeam = 1;


public OnPluginStart()
{
	CreateConVar("suppress_version", SUPPRESS_VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	cvarBlockSpectateMessage = CreateConVar("sm_blockspectatemessage", "1", "If enabled it blocks the join team message if an administrator joins spectator", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarBlockDisconnectMessage = CreateConVar("sm_blockdisconnectmessage", "1", "Blocks the disconnect message", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarBlockConnectMessage = CreateConVar("sm_blockconnectmessage", "1", "If enabled it blocks the player connection message.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarAdminShowMessages = CreateConVar("sm_adminshowmessages", "1", "Shows disconnect/connect/team join messages for admins only (if disconnect message is set to be blocked)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookEvent("player_team", ev_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_disconnect", ev_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_connect", ev_PlayerConnect, EventHookMode_Pre);
	
	new String:game_folder[64];
	GetGameFolderName(game_folder, sizeof(game_folder))
	
	if (StrContains(game_folder, "insurgency", false) != -1)
	{
		iSpecTeam = 3;
	}
	else
	{
		new String:game_description[64];
		GetGameDescription(game_description, sizeof(game_description), true);
		if (StrContains(game_description, "Insurgency", false) != -1)
		{
			iSpecTeam = 3;
		}
	}
	
	AutoExecConfig(true, "suppressmessage", "sourcemod");
}

public Action:ev_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvarBlockSpectateMessage))
	{
		if (!dontBroadcast && !GetEventBool(event, "silent"))
		{
			new iUserId = GetEventInt(event, "userid");
			new iClient = GetClientOfUserId(iUserId);
			new iTeam = GetEventInt(event, "team");
		
			if (iTeam == iSpecTeam && GetAdminFlag(GetUserAdmin(iClient), Admin_Kick))
			{
				new iOldTeam = GetEventInt(event, "oldteam");
				new bool:bDisconnect = GetEventBool(event, "disconnect");
				new bool:bAutoteam = GetEventBool(event, "autoteam");
				decl String:strName[50];
				GetEventString(event, "name", strName, sizeof(strName));
				
				if (iClient != 0)
				{
					if (GetConVarInt(cvarAdminShowMessages) == 1)
					{
						for (new i = 1; i <= MaxClients; i++)
						{
							if (IsClientConnected(i) && IsClientInGame(i) && (GetUserFlagBits(i) & ADMFLAG_KICK))
							{
								PrintToChat(i,"%N joined team Spectator.", iClient);
								PrintToConsole(i,"%N joined team Spectator.", iClient);
							}
						}
					}
				}
				
				new Handle:hEvent = CreateEvent("player_team");
				SetEventInt(hEvent, "userid", iUserId);
				SetEventInt(hEvent, "team", iTeam);
				SetEventInt(hEvent, "oldteam", iOldTeam);
				SetEventBool(hEvent, "disconnect", bDisconnect);
				SetEventBool(hEvent, "autoteam", bAutoteam);
				SetEventBool(hEvent, "silent", true);
				SetEventString(hEvent, "name", strName);
				
				FireEvent(hEvent, true);
				
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}
public Action:ev_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvarBlockConnectMessage))
	{
		if (!dontBroadcast)
		{
			decl String:strName[50];
			GetEventString(event, "name", strName, sizeof(strName));
			new iIndex = GetEventInt(event, "index");
			new iUserId = GetEventInt(event, "userid");
			new iClient = GetClientOfUserId(iUserId);
			decl String:strNetworkId[50];
			GetEventString(event, "networkid", strNetworkId, sizeof(strNetworkId));
			decl String:strAddress[50];
			GetEventString(event, "address", strAddress, sizeof(strAddress));
			
			if (iClient != 0)
			{
				if (GetConVarInt(cvarAdminShowMessages) == 1)
				{
					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && (GetUserFlagBits(i) & ADMFLAG_KICK))
						{
							PrintToChat(i,"%N has connected.", iClient);
							PrintToConsole(i,"%N has connected.", iClient);
						}
					}
				}
			}
			
			new Handle:hEvent = CreateEvent("player_connect");
			SetEventString(hEvent, "name", strName);
			SetEventInt(hEvent, "index", iIndex);
			SetEventInt(hEvent, "userid", iUserId);
			SetEventString(hEvent, "networkid", strNetworkId);
			SetEventString(hEvent, "address", strAddress);
			
			FireEvent(hEvent, true);
			
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
public Action:ev_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvarBlockDisconnectMessage))
	{		
		if (!dontBroadcast)
		{
			new iUserId = GetEventInt(event, "userid");
			new iClient = GetClientOfUserId(iUserId);
			decl String:strReason[50];
			GetEventString(event, "reason", strReason, sizeof(strReason));
			decl String:strName[50];
			GetEventString(event, "name", strName, sizeof(strName));
			decl String:strNetworkId[50];
			GetEventString(event, "networkid", strNetworkId, sizeof(strNetworkId));
			
			if (iClient != 0)
			{
				if (GetConVarInt(cvarAdminShowMessages) == 1)
				{
					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && (GetUserFlagBits(i) & ADMFLAG_KICK))
						{
							PrintToChat(i, "%N has left the server.", iClient);
							PrintToConsole(i, "Dropped %N from server (Disconnect by user.)", iClient);
						}
					}
				}
			}
			
			new Handle:hEvent = CreateEvent("player_disconnect");
			SetEventInt(hEvent, "userid", iUserId);
			SetEventString(hEvent, "reason", strReason);
			SetEventString(hEvent, "name", strName);
			SetEventString(hEvent, "networkid", strNetworkId);
			
			FireEvent(hEvent, true);
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}