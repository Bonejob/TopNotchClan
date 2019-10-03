#include <sourcemod>

#define PLUGIN_VERSION	"2.3"
#define TEAM_SPEC	1

//Globals
new Handle:g_specList[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
new Handle:g_CvarSpecLimit = INVALID_HANDLE;
new Handle:g_CvarPlayers = INVALID_HANDLE;


public Plugin:myinfo = 
{
	name = "Spectate Time",
	author = "TigerOx",
	description = "Kicks players if they stay in spectate past the set time",
	version = PLUGIN_VERSION,
}

public OnPluginStart()
{
	CreateConVar("sm_spectime", PLUGIN_VERSION, "Spectate Time Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CvarSpecLimit = CreateConVar("sm_spectimelimit", "800", "The maximum spectating time in seconds.", _, true, 15.0, true, 800.0);
	g_CvarPlayers = CreateConVar("sm_specplayerlimit", "30", "Minimum number of players required to start spectate kick. 0 to disable");
	
	HookEvent("player_team", OnPlayerTeam);
}

public OnClientConnected(client)
{
	if(client && !IsFakeClient(client))
		g_specList[client] = CreateTimer(GetConVarFloat(g_CvarSpecLimit),KickSpec,client);
}
	
public Action:OnPlayerTeam(Handle:event,const String:name[],bool:dontBroadcast)
{
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if( client && IsClientConnected(client) && !IsFakeClient(client) )
	{	//team the client changed to
		new team = GetEventInt(event, "team");
		
		//Check if they begin to spectate
		if( team == TEAM_SPEC)
		{
			if(g_specList[client] == INVALID_HANDLE)
				g_specList[client] = CreateTimer(GetConVarFloat(g_CvarSpecLimit),KickSpec,client);
		}
		else
		{
			if(g_specList[client] != INVALID_HANDLE)
			{
				KillTimer(g_specList[client])
				g_specList[client] = INVALID_HANDLE;
			}
		}	
	}
}

//Kick Spectator
public Action:KickSpec(Handle:timer, any:client)
{
	if(IsClientInGame(client) && GetClientTeam(client) < 2)
	{
		if(GetConVarInt(g_CvarPlayers) && (GetClientCount(true) >= GetConVarInt(g_CvarPlayers)))
		{
			if(GetUserAdmin(client) == INVALID_ADMIN_ID)
			{
				KickClient(client, "%s", "Spectating too long!");
				LogAction(client, -1, "%L was spectating too long, kicked!", client);
			}
			else if(!(GetAdminFlag(GetUserAdmin(client), Admin_Custom5, Access_Effective)))
			{
				KickClient(client, "%s", "Spectating too long!");
				LogAction(client, -1, "%L was spectating too long, kicked!", client);
			}
			g_specList[client] = INVALID_HANDLE;
		}
		else g_specList[client] = CreateTimer(GetConVarFloat(g_CvarSpecLimit),KickSpec,client);
	}
	else g_specList[client] = INVALID_HANDLE;
}

public OnClientDisconnect_Post(client)
{
	if( g_specList[client] != INVALID_HANDLE)
	{
		KillTimer(g_specList[client]);
		g_specList[client] = INVALID_HANDLE;
	}
}

