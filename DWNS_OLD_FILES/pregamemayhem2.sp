#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#include <clientprefs>
#pragma semicolon 1

#define MELEE		(1<<0)
#define CRITS		(1<<1)
#define COLOR_GREEN 0
#define COLOR_BLACK 1
#define COLOR_RED 2
#define COLOR_BLUE 3
#define COLOR_TEAM 4
#define COLOR_RAINBOW 5
#define COLOR_NONE 6

enum e_ColorNames
{
	Green,
	Black,
	Red,
	Blue
};

enum e_Cookies
{
	iColor,
};

enum e_ColorValues
{
	iRed,
	iGreen,
	iBlue
};
new g_iPlayerCycleColor[MAXPLAYERS + 1] = { 0, ... };
new g_aClientCookies[MAXPLAYERS + 1][e_Cookies];
new g_iColors[e_ColorNames][e_ColorValues];


new Handle:g_hPlayerColorTimer[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new Handle:g_hTitties = INVALID_HANDLE;
#define PLUGIN_VERSION "3.5"

new passes,
	starts,
	Handle:g_cvar_tf_avoidteammates = INVALID_HANDLE,
	g_mode,
	bool:g_bAvoidSetting = false,
	Handle: bri_cookie_color = INVALID_HANDLE;
	

public Plugin:myinfo =
{
	name = "Waiting For Players Mayhem",
	author = "GOERGE, DWN",
	description = "Melee, Weapons and Crits during Waiting for Players",
	version = PLUGIN_VERSION,
	url = "http://www.topnotchclan.com"
};

stock LoadColors()
{
	g_iColors[Green][iRed] = 0;
	g_iColors[Green][iGreen] = 255;
	g_iColors[Green][iBlue] = 0;

	g_iColors[Black][iRed] = 10;
	g_iColors[Black][iGreen] = 10;
	g_iColors[Black][iBlue] = 0;
	
	g_iColors[Red][iRed] = 255;
	g_iColors[Red][iGreen] = 0;
	g_iColors[Red][iBlue] = 0;
	
	g_iColors[Blue][iRed] = 0;
	g_iColors[Blue][iGreen] = 0;
	g_iColors[Blue][iBlue] = 255;
}


public OnPluginStart()
{
	CreateConVar("sm_pregamemayhem_ver", PLUGIN_VERSION, "Pregame Mayhem Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED);
	SetCommandFlags("sv_alltalk", GetCommandFlags("sv_alltalk") & ~FCVAR_NOTIFY);
	SetCommandFlags("mp_teams_unbalance_limit", GetCommandFlags("mp_teams_unbalance_limit") & ~FCVAR_NOTIFY);
	SetCommandFlags("mp_friendlyfire", GetCommandFlags("mp_friendlyfire") & ~FCVAR_NOTIFY);
	SetCommandFlags("sv_tags", GetCommandFlags("sv_tags") & ~FCVAR_NOTIFY);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("teamplay_round_start", Event_Roundstart, EventHookMode_PostNoCopy);
	g_cvar_tf_avoidteammates = FindConVar("tf_avoidteammates");
	SetCommandFlags("g_cvar_tf_avoidteammates", GetCommandFlags("g_cvar_tf_avoidteammates") & ~FCVAR_NOTIFY);
	HookConVarChange(g_cvar_tf_avoidteammates, ConVarSettingsChanged);	
	bri_cookie_color = RegClientCookie("bri_client_color", "Color to render when immune.", CookieAccess_Public);
	g_hTitties = CreateConVar("pregame_color", "1", "WHO GETS COLORED\n0 = no COLOR\n1 = EVERYONE\n2 = JUST DONATORZ");
	LoadColors();
}

public OnClientCookiesCached(client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		decl String:sColor[2];
		GetClientCookie(client, bri_cookie_color, sColor, sizeof(sColor));
		if (StrEqual(sColor, ""))
		{
			g_aClientCookies[client][iColor] = 5;
		}
		else
		{
			new Color = StringToInt(sColor);
			if (Color == 6)
			{
				Color = 5;
			}
			g_aClientCookies[client][iColor] = Color;
		}
	}		
}

stock DisableColor(iClient)
{
	if (g_hPlayerColorTimer[iClient] != INVALID_HANDLE)
	{
		CloseHandle(g_hPlayerColorTimer[iClient]);
		g_hPlayerColorTimer[iClient] = INVALID_HANDLE;
	}
	if (IsClientInGame(iClient))
	{
		SetEntityRenderMode(iClient, RENDER_TRANSCOLOR);
		SetEntityRenderColor(iClient, 255, 255, 255, 255);
	}
	g_iPlayerCycleColor[iClient] = 0;
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
		for (new i=1;i<=MaxClients;i++)
		{
			SetColor(i);
		}
	}
	if (starts == 1){
		g_bAvoidSetting = true;
		SetConVarBool(g_cvar_tf_avoidteammates, g_bAvoidSetting);
		ServerCommand("mp_friendlyfire 0");
		ServerCommand("sv_alltalk 0");
		ServerCommand("mp_teams_unbalance_limit 1");
		//CreateTimer(0.1, Timer_RemoveCond, _, TIMER_FLAG_NO_MAPCHANGE);
		EnableResupply();
		PrintToChatAll("\x04GAME STARTING! Waiting For Players Mayhem Ending!");
		CreateTimer(0.5, Timer_Shutoff);
		CreateTimer(0.6, Timer_GiveGuns, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	starts++;
}

public Action:Timer_GiveGuns(Handle:timer) 
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
			TF2_RegeneratePlayer(i);
	}
	return Plugin_Handled;
}

public Action:Timer_Shutoff(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		DisableColor(i);
	}
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

public Action:Timer_Respawn(Handle:timer, any:client) 
{
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

public Action:Timer_StripGuns(Handle:timer, any:client)
{
	if (!IsValidClient(client)) {
		return;
	}
	new TFClassType:playerClass = TF2_GetPlayerClass(client);
	if(playerClass == TFClass_Pyro)
	{
		TF2_RemoveWeaponSlot(client, 0);
		new tauntwep = GetPlayerWeaponSlot(client, 1);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", tauntwep);
	}
	TF2_RemoveWeaponSlot(client, 4);
}

public Action:Timer_StripToMelee(Handle:timer, any:id)
{
	new client;
	if ((client = GetClientOfUserId(id)))
	{
		StripToMelee(client);
	}
	if(starts <= 1 && g_mode & CRITS && IsClientInGame(client) && IsPlayerAlive(client)) 
	{
		TF2_AddCondition(client, TFCond_Buffed, 100.0);
	}
	return Plugin_Handled;
}

/*
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
}*/

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {

	if (starts > 1) {
		return;
	}

	new id, client;
	id = GetEventInt(event, "userid");
	client = GetClientOfUserId(id);
	
	if (!(g_mode & CRITS))
	{
		SetColor(client);
	}
	if (g_mode & MELEE)
	{
		CreateTimer(0.1, Timer_StripToMelee, id, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	CreateTimer(0.1, Timer_StripGuns, client, TIMER_FLAG_NO_MAPCHANGE);
}

stock SetColor(iClient)
{
	if (!IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
	new iWHO = GetConVarInt(g_hTitties);
	switch (iWHO)
	{
		case 0:
		{
			return;
		}
		case 1:
		{
			// NOTHING
		}
		case 2:
		{
			if (GetUserAdmin(iClient) == INVALID_ADMIN_ID)
			{
				return;
			}
		}
	}
	SetEntityRenderMode(iClient, RENDER_TRANSCOLOR);
	switch (g_aClientCookies[iClient][iColor])
	{
	case COLOR_TEAM:
		{
			new iTeam = GetClientTeam(iClient);
			SetEntityRenderColor(iClient, g_iColors[e_ColorNames:iTeam][iRed], g_iColors[e_ColorNames:iTeam][iGreen], g_iColors[e_ColorNames:iTeam][iBlue], 255);
		}
	case COLOR_RAINBOW:
		{
			if (g_hPlayerColorTimer[iClient] != INVALID_HANDLE)
			{
				CloseHandle(g_hPlayerColorTimer[iClient]);
				g_hPlayerColorTimer[iClient] = INVALID_HANDLE;
			}
			g_hPlayerColorTimer[iClient] = CreateTimer(0.2, Timer_ChangeColor, iClient, TIMER_REPEAT);
		}
	case COLOR_NONE:
		{
			if (g_hPlayerColorTimer[iClient] != INVALID_HANDLE)
			{
				CloseHandle(g_hPlayerColorTimer[iClient]);
				g_hPlayerColorTimer[iClient] = INVALID_HANDLE;
			}
			g_hPlayerColorTimer[iClient] = CreateTimer(0.2, Timer_ChangeColor, iClient, TIMER_REPEAT);
		}
	default:
		{
			SetEntityRenderColor(iClient, g_iColors[e_ColorNames:g_aClientCookies[iClient][iColor]][iRed], g_iColors[e_ColorNames:g_aClientCookies[iClient][iColor]][iGreen], g_iColors[e_ColorNames:g_aClientCookies[iClient][iColor]][iBlue], 255);
		}
	}	

}

public Action:Timer_ChangeColor(Handle:timer, any:client)
{
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}

	if (g_iPlayerCycleColor[client]++ == 3)
	{
		g_iPlayerCycleColor[client] = 0;
	}

	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, g_iColors[g_iPlayerCycleColor[client]][iRed], g_iColors[g_iPlayerCycleColor[client]][iGreen], g_iColors[g_iPlayerCycleColor[client]][iBlue], 255);
	return Plugin_Continue;
}

/*
StripAllToMelee() {
	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
		StripToMelee(i);
}
*/

StripToMelee(client) {
	if (starts <= 1 && (g_mode & MELEE) && IsClientInGame(client) && IsPlayerAlive(client)) {
		for (new i = 0; i <= 5; i++)
			if (i != 2)
				TF2_RemoveWeaponSlot(client, i);
		new tauntwep = GetPlayerWeaponSlot(client, 2);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", tauntwep);
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