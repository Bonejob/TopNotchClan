#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#pragma semicolon 1

#define MELEE		(1<<0)
#define CRITS		(1<<1)

#define PLUGIN_VERSION "3.2"

new passes,
	starts,
	Handle:g_cvar_tf_avoidteammates = INVALID_HANDLE,
	g_mode,
	bool:g_bAvoidSetting = false;
	

public Plugin:myinfo =
{
	name = "Waiting For Players Mayhem",
	author = "GOERGE, DWN",
	description = "Melee, Weapons and Crits during Waiting for Players",
	version = PLUGIN_VERSION,
	url = "http://www.topnotchclan.com"
};

public OnPluginStart()
{
	CreateConVar("sm_pregamemayhem_ver", PLUGIN_VERSION, "Pregame Mayhem Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED);
	SetCommandFlags("sv_alltalk", GetCommandFlags("sv_alltalk") & ~FCVAR_NOTIFY);
	SetCommandFlags("mp_teams_unbalance_limit", GetCommandFlags("mp_teams_unbalance_limit") & ~FCVAR_NOTIFY);
	SetCommandFlags("mp_friendlyfire", GetCommandFlags("mp_friendlyfire") & ~FCVAR_NOTIFY);
	SetCommandFlags("sv_tags", GetCommandFlags("sv_tags") & ~FCVAR_NOTIFY);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	HookEvent("teamplay_round_start", Event_Roundstart, EventHookMode_PostNoCopy);
	g_cvar_tf_avoidteammates = FindConVar("tf_avoidteammates");
	SetCommandFlags("g_cvar_tf_avoidteammates", GetCommandFlags("g_cvar_tf_avoidteammates") & ~FCVAR_NOTIFY);
	HookConVarChange(g_cvar_tf_avoidteammates, ConVarSettingsChanged);
}

public OnMapStart()
{
	g_bAvoidSetting = false;
	starts = 0;
	PrecacheSound("vo/announcer_begins_5sec.wav");
	PrecacheSound("vo/announcer_begins_4sec.wav");
	PrecacheSound("vo/announcer_begins_3sec.wav");
	PrecacheSound("vo/announcer_begins_2sec.wav");
	PrecacheSound("vo/announcer_begins_1sec.wav");
	PrecacheSound("vo/announcer_am_gamestarting05.wav");
}

public Event_Roundstart(Handle:event,const String:name[],bool:dontBroadcast)
{
	if ( !starts) {
		g_mode = 0;
		switch(GetRandomInt(0,3))
		{
			case 0:
			{
				g_mode |=MELEE;
			}
			case 1:
			{
				g_mode |=CRITS;
				g_mode |=MELEE;
			}
			case 2:
			{
				g_mode |=CRITS;
			}
		}
		g_bAvoidSetting = false;
		SetConVarBool(g_cvar_tf_avoidteammates, g_bAvoidSetting);
		ServerCommand("mp_teams_unbalance_limit 3");
		ServerCommand("mp_friendlyfire 1");
		ServerCommand("sv_alltalk 1");
		PrintToChatAll("\x04Waiting For Players Mayhem Round Starting!");
		CreateTimer(10.0, Display_Ad, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(52.5, StartLoopingTimer, _, TIMER_FLAG_NO_MAPCHANGE);
		//StripAllToMelee();
		DisableResupply();
	}
	if (starts == 1){
		g_bAvoidSetting = true;
		SetConVarBool(g_cvar_tf_avoidteammates, g_bAvoidSetting);
		ServerCommand("mp_friendlyfire 0");
		ServerCommand("sv_alltalk 0");
		ServerCommand("mp_teams_unbalance_limit 1");
		CreateTimer(0.1, Timer_RemoveCond, _, TIMER_FLAG_NO_MAPCHANGE);
		EnableResupply();
		PrintToChatAll("\x04GAME STARTING! Waiting For Players Mayhem Ending!");
	}
	starts++;
}

/*
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (starts <= 1 && g_mode & CRITS)
	{
		result = true;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
*/

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	if (starts > 1)
		return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, Timer_Respawn, client);
}

public Action:Timer_Respawn(Handle:timer, any:client) {
	if (starts <= 1 && IsClientInGame(client)) 
		TF2_RespawnPlayer(client);
}


public Action:Display_Ad(Handle:timer) {
	if (starts <= 1) {
		PrintToChatAll("\x04-----------------------------------------------");
		PrintToChatAll("\x04Waiting for Players Mayhem Round Is Active!");
		PrintToChatAll("\x04-----------------------------------------------");

		return Plugin_Continue;
	}
	else {
		return Plugin_Stop;
	}
}

public Action:StartLoopingTimer(Handle:timer)
{
	passes = 5;
	CreateTimer(1.0, Play_Sounds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

public Action:Play_Sounds(Handle:timer)
{
	decl String:filename[64];
	Format(filename, sizeof(filename), "vo/announcer_begins_%isec.wav", passes);
	EmitSoundToAll(filename);
	//PrintToChatAll(filename);
	if(passes-- <= 0)
	{
		CreateTimer(8.0, PlayStartSound);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:PlayStartSound(Handle:timer)
{
	EmitSoundToAll("vo/announcer_am_gamestarting05.wav");
	return Plugin_Handled;
}

public Action:Timer_StripToMelee(Handle:timer, any:client) {
	if (starts <= 1 && g_mode &MELEE) {
		StripToMelee(client);
	}
	if(starts <= 1 && g_mode & CRITS && IsClientInGame(client) && IsPlayerAlive(client)) {
		TF2_AddCond(client, 16);
	}
	return Plugin_Handled;
}

public Action:Timer_RemoveCond(Handle:timer) 
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if ((g_mode & CRITS) && IsClientInGame(i))
		{
			TF2_RemoveCond(i, 11);
		}
	}
	return Plugin_Handled;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if (starts > 1)
		return;
	CreateTimer(0.1, Timer_StripToMelee, GetClientOfUserId(GetEventInt(event, "userid")));
}

/*
StripAllToMelee() {
	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
		StripToMelee(i);
}
*/

StripToMelee(client) {
	if (starts <= 1 && g_mode & MELEE && IsClientInGame(client) && IsPlayerAlive(client)) {
		for (new i = 0; i <= 5; i++)
			if (i != 2)
				TF2_RemoveWeaponSlot(client, i);
		ClientCommand(client, "slot3");
	}
}

EnableResupply() {
	new iRegenerate = -1;
	while ((iRegenerate = FindEntityByClassname(iRegenerate, "func_regenerate")) != -1) {
		AcceptEntityInput(iRegenerate, "Enable");
	}
}

DisableResupply() {
	new iRegenerate = -1;
	while ((iRegenerate = FindEntityByClassname(iRegenerate, "func_regenerate")) != -1) {
		AcceptEntityInput(iRegenerate, "Disable");
	}
}

stock TF2_AddCond(client, cond) {
	new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
	if (!enabled) {
		SetConVarFlags(cvar, flags & ~(FCVAR_NOTIFY | FCVAR_REPLICATED));
		SetConVarBool(cvar, true);
	}
	FakeClientCommand(client, "addcond %i", cond);
	if (!enabled) {
		SetConVarBool(cvar, false);
		SetConVarFlags(cvar, flags);
	}
}

stock TF2_RemoveCond(client, cond) {
	new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
	if (!enabled) {
		SetConVarFlags(cvar, flags & ~(FCVAR_NOTIFY | FCVAR_REPLICATED));
		SetConVarBool(cvar, true);
	}
	FakeClientCommand(client, "removecond %i", cond);
	if (!enabled) {
		SetConVarBool(cvar, false);
		SetConVarFlags(cvar, flags);
	}
}

public ConVarSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_cvar_tf_avoidteammates)
	{
		SetConVarBool(g_cvar_tf_avoidteammates, g_bAvoidSetting);
	}
}

stock bool:IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	return false;
}