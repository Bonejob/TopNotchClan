/************************************************************************
* Waiting For Players Mayhem [TF2]
* Author(s): GOERGE, DWN. (edited by: retsam)
* File: pregamemayhem_dwn.sp
* Description: Melee, Weapons and Crits during Waiting for Players.
*************************************************************************
* 
* 3.6 - Removed #include sdktools as its part of tf2 stocks.
*     - Fixed first joined player not having stuff applied to him.
*     - Moved some stuff around.....
*     - Fixed/removed some weird client id stuff in the spawn hook.
*     - Fixed a GetRandomInt out of bounds issue in round_start where it was randomizing a number with no switch 'case'.     
*     - Added a global bool to check for pregame being active instead of using 'starts'.
*     - Added a client bool to check if player was colored already. (You dont need to recolorize the player every spawn)
*     - mp_waitingforplayers_time 60 is now hardcoded into the plugin.
*     - Fixed issue of rainbow timer handle not being closed on disconnects.
*     - Fixed issue in stripguns timer code so that its only removing slot4 for spies and not all classes as it has been.
*     - Removed unnesessary SetEntityRenderMode's.
*     - Commented out the stock IsValidClient check. This isnt really needed I dont think. Best and faster to just use client in game and alive checks.
*     - Added client = 0 and alive checks in spawn and death hooks.
*     - Updated color related code to match BRI. (colors were not matching what was in BRI)     
*     - Added check in Play_Sounds timer for passes > 0 so console doesnt produce a precache error.
*     - Now handling Hooking and Unhooking of spawn and death events in pregame code. (No point to keep them hooked if they are only used once per map change. Also ensures code isnt being run.)
*
*/    

#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <clientprefs>

#define PLUGIN_VERSION "3.6"

#define MELEE		(1<<0)
#define CRITS		(1<<1)
#define COLOR_TEAM 0
#define COLOR_BLACK 1
#define COLOR_RED 2
#define COLOR_BLUE 3
#define COLOR_GREEN 4
#define COLOR_RAINBOW 5
#define COLOR_OPTEAM 6
#define COLOR_NONE 7

enum e_ColorNames
{
	Green,
	Black,
	Red,
	Blue
};

enum e_Cookies
{
	iColor
};

enum e_ColorValues
{
	iRed,
	iGreen,
	iBlue
};

new Handle:g_hPlayerColorTimer[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new Handle:g_hTitties = INVALID_HANDLE;
new Handle:g_cvar_tf_avoidteammates = INVALID_HANDLE;
new Handle:bri_cookie_color = INVALID_HANDLE;

new g_iPlayerCycleColor[MAXPLAYERS + 1] = { 0, ... };
new g_aClientCookies[MAXPLAYERS + 1][e_Cookies];
new g_iColors[e_ColorNames][e_ColorValues];

new passes;
new starts;
new g_mode;

new bool:g_bAvoidSetting = false;
new bool:g_bPreGameActive = false;
new bool:g_bSetClientColor[MAXPLAYERS + 1] = { false, ... };

public Plugin:myinfo =
{
	name = "Waiting For Players Mayhem",
	author = "GOERGE, DWN",
	description = "Melee, Weapons and Crits during Waiting for Players.",
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
	decl String:sColor[2];
	GetClientCookie(client, bri_cookie_color, sColor, sizeof(sColor));
	//PrintToServer("%N's color cookie set to: %s", client, sColor);
	//PrintToChatAll("%N's color cookie set to: %s", client, sColor);
	if(StrEqual(sColor, "") || StrEqual(sColor, "7"))
	{ 
		//PrintToServer("%N's color being set to: RAINBOW", client);
		//PrintToChatAll("%N's color being set to: RAINBOW", client);
		g_aClientCookies[client][iColor] = COLOR_RAINBOW;
	}
	else
	{
		g_aClientCookies[client][iColor] = StringToInt(sColor);
	}
}

public OnClientPostAdminCheck(client)
{
	g_iPlayerCycleColor[client] = 0;
	g_bSetClientColor[client] = false;
}

public OnClientDisconnect(client)
{
	if(g_hPlayerColorTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hPlayerColorTimer[client]);
		g_hPlayerColorTimer[client] = INVALID_HANDLE;
	}
	
	g_iPlayerCycleColor[client] = 0;
	g_bSetClientColor[client] = false;
}

public OnConfigsExecuted()
{
	ServerCommand("sm_cvar mp_waitingforplayers_time 60.0");
}

public OnMapStart()
{
	g_bAvoidSetting = false;
	g_bPreGameActive = false;
	starts = 0;
	g_mode = 0;
	PrecacheSound("vo/announcer_begins_5sec.wav");
	PrecacheSound("vo/announcer_begins_4sec.wav");
	PrecacheSound("vo/announcer_begins_3sec.wav");
	PrecacheSound("vo/announcer_begins_2sec.wav");
	PrecacheSound("vo/announcer_begins_1sec.wav");
	PrecacheSound("vo/announcer_am_gamestarting05.wav");
}

public OnMapEnd()
{
	if(g_bPreGameActive)
	{
		UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
		UnhookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	}
}

public Event_Roundstart(Handle:event,const String:name[],bool:dontBroadcast)
{
	//PrintToChatAll("Event_RoundStart: Triggered!");
	//PrintToServer("Event_RoundStart: Triggered!");
	if(!starts)
	{
		g_bPreGameActive = true;
		HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
		HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
		
		g_mode = 0;
		switch(GetRandomInt(0,2))
		{
		case 0:
			{
				g_mode |=MELEE;
				//PrintToChatAll("PreMode case 0: Melee only!");
			}
		case 1:
			{
				g_mode |=CRITS;
				g_mode |=MELEE;
				//PrintToChatAll("PreMode case 1: Melee & Crits!");
			}
		case 2:
			{
				g_mode |=CRITS;
				//PrintToChatAll("PreMode case 2: Crits & weapons!");
			}
		}
		
		g_bAvoidSetting = false;
		SetConVarBool(g_cvar_tf_avoidteammates, g_bAvoidSetting);
		ServerCommand("mp_teams_unbalance_limit 4");
		ServerCommand("mp_friendlyfire 1");
		ServerCommand("sv_alltalk 1");
		PrintToChatAll("\x04Waiting For Players Mayhem Round Starting!");
		CreateTimer(10.0, Display_Ad, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(52.5, StartLoopingTimer, _, TIMER_FLAG_NO_MAPCHANGE);
		//StripAllToMelee();
		DisableResupply();
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i) || !IsPlayerAlive(i))
			{
				continue;
			}
			
			SetColor(i);
			GivePlayerBuffs(i);
		}
	}
	
	if(starts == 1)
	{
		g_bPreGameActive = false;
		UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
		UnhookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
		
		g_bAvoidSetting = true;
		SetConVarBool(g_cvar_tf_avoidteammates, g_bAvoidSetting);
		ServerCommand("mp_friendlyfire 0");
		ServerCommand("sv_alltalk 0");
		ServerCommand("mp_teams_unbalance_limit 1");
		//CreateTimer(0.1, Timer_RemoveCond, _, TIMER_FLAG_NO_MAPCHANGE);
		EnableResupply();
		PrintToChatAll("\x04GAME STARTING! Waiting For Players Mayhem Ending!");
		//CreateTimer(0.5, Timer_Shutoff, _, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.6, Timer_ClearPlayers, _, TIMER_FLAG_NO_MAPCHANGE);
		ServerCommand("heartbeat");
	}
	
	starts++;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bPreGameActive)
	return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client < 1 || !IsPlayerAlive(client))
	return;
	
	if(!g_bSetClientColor[client])
	{
		SetColor(client);
	}
	
	GivePlayerBuffs(client);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bPreGameActive)
	return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client < 1)
	return;

	CreateTimer(0.1, Timer_RespawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_ClearPlayers(Handle:timer) 
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		
		DisableColor(i);
		if(IsPlayerAlive(i))
		{
			TF2_RegeneratePlayer(i);
		}
	}
}

/*
public Action:Timer_Shutoff(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		
		DisableColor(i);
	}
}
*/

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

public Action:Timer_RespawnPlayer(Handle:timer, any:client) 
{
	if(!IsClientInGame(client))
	return;

	if(g_bPreGameActive)
	{
		TF2_RespawnPlayer(client);
	}
}

public Action:Display_Ad(Handle:timer)
{
	if(g_bPreGameActive)
	{
		PrintToChatAll("\x04-----------------------------------------------");
		PrintToChatAll("\x04Waiting for Players Mayhem Round Is Active!");
		PrintToChatAll("\x04-----------------------------------------------");
	}
	else
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:StartLoopingTimer(Handle:timer)
{
	passes = 5;
	CreateTimer(1.0, Play_Sounds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Play_Sounds(Handle:timer)
{
	if(passes > 0)
	{
		decl String:filename[64];
		Format(filename, sizeof(filename), "vo/announcer_begins_%isec.wav", passes);
		EmitSoundToAll(filename);
	}
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
}

public Action:Timer_StripGuns(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
	return;

	new TFClassType:class = TF2_GetPlayerClass(client);
	if(class == TFClass_Pyro)
	{
		TF2_RemoveWeaponSlot(client, 0);
		new weapon = GetPlayerWeaponSlot(client, 1);
		if(IsValidEntity(weapon))
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		}
	}
	else if(class == TFClass_Spy)
	{
		TF2_RemoveWeaponSlot(client, 4);
	}
}

public Action:Timer_StripToMelee(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
	return;

	StripToMelee(client);
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

stock DisableColor(iClient)
{
	if(g_hPlayerColorTimer[iClient] != INVALID_HANDLE)
	{
		CloseHandle(g_hPlayerColorTimer[iClient]);
		g_hPlayerColorTimer[iClient] = INVALID_HANDLE;
	}

	SetEntityRenderMode(iClient, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iClient, 255, 255, 255, 255);
	g_iPlayerCycleColor[iClient] = 0;
	g_bSetClientColor[iClient] = false;
}

stock SetColor(iClient)
{
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
			if(GetUserAdmin(iClient) == INVALID_ADMIN_ID)
			{
				return;
			}
		}
	}
	
	g_bSetClientColor[iClient] = true;
	SetEntityRenderMode(iClient, RENDER_TRANSCOLOR);
	switch (g_aClientCookies[iClient][iColor])
	{
	case COLOR_TEAM:
		{
			new iTeam = GetClientTeam(iClient);
			SetEntityRenderColor(iClient, g_iColors[e_ColorNames:iTeam][iRed], g_iColors[e_ColorNames:iTeam][iGreen], g_iColors[e_ColorNames:iTeam][iBlue], 255);
		}
	case COLOR_OPTEAM:
		{
			new iTeam;
			if(GetClientTeam(iClient) == 2)
			{
				iTeam = 3;
			}
			else
			{
				iTeam = 2;
			}
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
			//do nothing
		}
	case COLOR_GREEN:
		{
			SetEntityRenderColor(iClient, g_iColors[Green][iRed], g_iColors[Green][iGreen], g_iColors[Green][iBlue], 255);
		}
	default:
		{
			SetEntityRenderColor(iClient, g_iColors[e_ColorNames:g_aClientCookies[iClient][iColor]][iRed], g_iColors[e_ColorNames:g_aClientCookies[iClient][iColor]][iGreen], g_iColors[e_ColorNames:g_aClientCookies[iClient][iColor]][iBlue], 255);
		}
	}	
}

public Action:Timer_ChangeColor(Handle:timer, any:client)
{
	if(!IsPlayerAlive(client))
	return Plugin_Continue;

	if(g_iPlayerCycleColor[client]++ == 3)
	{
		g_iPlayerCycleColor[client] = 0;
	}

	//SetEntityRenderMode(client, RENDER_TRANSCOLOR);
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

StripToMelee(client)
{
  for (new i = 0; i <= 5; i++)
  {
    if(i != 2)
    {
      TF2_RemoveWeaponSlot(client, i);
    }
    
    new meleewep = GetPlayerWeaponSlot(client, 2);
    SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", meleewep);
	}
}

stock GivePlayerBuffs(client)
{
  if(g_mode & CRITS)
	{
    TF2_AddCondition(client, TFCond_Buffed, 100.0);
	}
	
  if(g_mode & MELEE)
	{
		CreateTimer(0.1, Timer_StripToMelee, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
    CreateTimer(0.1, Timer_StripGuns, client, TIMER_FLAG_NO_MAPCHANGE);
  }
}

EnableResupply()
{
	new iRegenerate = -1;
	while ((iRegenerate = FindEntityByClassname(iRegenerate, "func_regenerate")) != -1)
	{
		AcceptEntityInput(iRegenerate, "Enable");
	}
}

DisableResupply()
{
	new iRegenerate = -1;
	while ((iRegenerate = FindEntityByClassname(iRegenerate, "func_regenerate")) != -1)
	{
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

/*
stock bool:IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	
	return false;
}
*/