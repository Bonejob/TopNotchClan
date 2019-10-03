#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "2.0"

#pragma semicolon 1

new Roundstarts = 0;
new bool:Instaspawn = false;
#if !defined FCVAR_DEVELOPMENTONLY
#define FCVAR_DEVELOPMENTONLY   (1<<1)
#endif

public Plugin:myinfo =
{
	name = "TF2 fun round during waiting for players",
	author = "Ratty, DWN",
	description = "TF2 fun during waiting for players",
	version = PLUGIN_VERSION,
	url = "http://www.topnotchclan.com"
}

public OnPluginStart()
{
	CreateConVar("sm_pregamemayhem_ver", PLUGIN_VERSION, "Pregame Mayhem Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED);
	SetCommandFlags("sv_alltalk", GetCommandFlags("sv_alltalk") & ~FCVAR_NOTIFY);
	SetCommandFlags("mp_teams_unbalance_limit", GetCommandFlags("mp_teams_unbalance_limit") & ~FCVAR_NOTIFY);
	SetCommandFlags("mp_friendlyfire", GetCommandFlags("mp_friendlyfire") & ~FCVAR_NOTIFY);
	SetCommandFlags("sv_tags", GetCommandFlags("sv_tags") & ~FCVAR_NOTIFY);
	HookEvent("teamplay_round_start", Event_Roundstart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("teamplay_round_start", Event_RoundBegins);
	new flags, Handle:cvar = FindConVar("tf_avoidteammates");
	flags = GetConVarFlags(cvar);
	flags &= ~FCVAR_CHEAT|FCVAR_DEVELOPMENTONLY|FCVAR_NOTIFY;
	SetConVarFlags(cvar, flags);
}

public OnMapStart()
{
	Instaspawn = false;
	Roundstarts = 0;
}

public Action:Event_Roundstart(Handle:event,const String:name[],bool:dontBroadcast)
{
	
	if ( Roundstarts == 0 ) {
		Instaspawn = true;
		ServerCommand("mp_teams_unbalance_limit 2");
		ServerCommand("sm_meleemode_enable 1");
		ServerCommand("mp_friendlyfire 1");
		ServerCommand("sv_alltalk 1");
		ServerCommand("sm_cvar tf_avoidteammates 0");
		PrintToChatAll("\x04Waiting For Players Mayhem Initialized!");
	}

	if ( Roundstarts == 1 ) {
		Instaspawn = false;
		ServerCommand("mp_friendlyfire 0");
		ServerCommand("sv_alltalk 0");
		ServerCommand("sm_meleemode_enable 0");
		ServerCommand("sm_cvar tf_avoidteammates 1");
		ServerCommand("mp_restartgame 1");
		ServerCommand("mp_teams_unbalance_limit 1");
		ServerCommand("heartbeat");
		PrintToChatAll("\x04GAME STARTING! Waiting For Players Mayhem Disabled!");
	}
	
	Roundstarts++;
	
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, Timer_Respawn, client);
	return Plugin_Continue;
}

public Action:Timer_Respawn(Handle:timer, any:client) {
	if (Instaspawn && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client)) {
		if (!IsFakeClient(client))
			TF2_RespawnPlayer(client);
	}
}

public Action:Event_RoundBegins(Handle:event,const String:name[],bool:dontBroadcast) {
	CreateTimer(9.0, Display_Ad, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}	

public Action:Display_Ad(Handle:timer) {
	if (Roundstarts == 1) {
		PrintToChatAll("\x04--------------------------------------------");
		PrintToChatAll("\x04Waiting for Players Mayhem Round In Effect!");
		PrintToChatAll("\x04--------------------------------------------");

		return Plugin_Continue;
	}
	else {
		return Plugin_Stop;
	}
}