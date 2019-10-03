#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PL_VERSION "0.3"
#define CVAR_Enabled	0
#define NUM_CVARS	1


public Plugin:myinfo = 
{
	name = "Tournament Hack",
	author = "Geit",
	description = "Allows the use of tournament commands without requiring the tournament HUD",
	version = PL_VERSION,
	url = "http://gamingmasters.co.uk"
};

new Handle:g_cvars[NUM_CVARS] = INVALID_HANDLE;
new g_enabled;
new Handle:cvar;
new Handle:cvars;
//new bool:g_TimeHandle = false;
new bool:g_FirstRound = false;
new Handle:g_WaitTimer = INVALID_HANDLE;

public OnPluginStart()
{
	//if(GetConVarInt(FindConVar("hostport")) != 27018)
	//SetFailState("Failure: Not on port 27018");
	
	g_cvars[CVAR_Enabled] = CreateConVar("sm_th_Enabled", "1", "Enables Tournament Hacker");
	RegAdminCmd("sm_setclass", Command_SetClass, ADMFLAG_RESERVATION | ADMFLAG_CUSTOM1 | ADMFLAG_ROOT, "Sets your class");	
	cvars = FindConVar("mp_tournament");
	SetConVarFlags(cvars, GetConVarFlags(cvars) & ~(FCVAR_NOTIFY));
	
	cvar = FindConVar("mp_tournament_stopwatch");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	
	SetConVarInt(FindConVar("mp_tournament_stopwatch"), 0, true);
	SetConVarInt(FindConVar("tf_tournament_hide_domination_icons"), 0, true);
	SetConVarInt(FindConVar("mp_tournament"), 0, true);
	
	HookConVarChange(FindConVar("mp_restartgame"), OnConVarChange);
	HookConVarChange(g_cvars[CVAR_Enabled], OnConVarChange);
	
	HookEvent("arena_round_start", Event_arena_round_start);
	HookEvent("arena_win_panel", Event_arena_round_end);
	HookEvent("teamplay_round_start", Event_teamplay_round_start);
	HookEvent("teamplay_round_win", Event_teamplay_round_end);
	
	ServerCommand("tf_tournament_classlimit_scout -1");
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if (hCvar == FindConVar("mp_restartgame"))
	{
		DisableBB();
		PrintToChatAll("Disable tournament sincehcvar == mp_restartgame");
	}
	else if (hCvar == g_cvars[CVAR_Enabled])
	{
		g_enabled = StringToInt(newValue);
		PrintToChatAll("hcvar = 1 enabled");
		if (g_enabled == 1)
		{
			EnableBB();
			PrintToChatAll("Enable tournament");
			
		}
		else
		{
			DisableBB();
			PrintToChatAll("Not Enabled, turn off tournament");
		}
	}
}

public Action:Event_teamplay_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_FirstRound)
	{
		g_FirstRound = true;
		new Float:g_WaitTime = float(GetConVarInt(FindConVar("mp_waitingforplayers_time")));
		g_WaitTime += 2.0;
		g_WaitTimer = CreateTimer(g_WaitTime, EndOfWaiting);
		CloseHandle(g_WaitTimer);
		//g_TimeHandle = true;
		PrintToChatAll("Not first round, add 2 seconds to WFP and start end of waiting timer");
	} 
	else {
		EnableBB();
		//if (g_TimeHandle) {KillTimer(g_WaitTimer, false);}
		PrintToChatAll("Enable mp_tournament since its the first round");
	}
	
}

public Action:Event_arena_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_FirstRound){ g_FirstRound = true; } else {EnableBB();}
}

public Action:Event_arena_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	DisableBB();
}

public Action:Event_teamplay_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	DisableBB();
	PrintToChatAll("Disable mp_tournament for round end");
}

public OnMapStart(){
	DisableBB();
	g_FirstRound = false;
	PrintToChatAll("Map start: turn off tournament and first round false");
}

public Action:EndOfWaiting(Handle:timer, any:data) {
	//g_TimeHandle = false;
	SetConVarInt(FindConVar("mp_waitingforplayers_cancel"), 1, true);	
	PrintToChatAll("Cancel WFP");
	CreateTimer(2.0, DelayedEnable);
	PrintToChatAll("Respawn all players after enabling ");
	for(new i=1; i<=MaxClients; i++) {
		if(IsClientInGame(i) && IsPlayerAlive(i)) {
			TF2_RespawnPlayer(i);
		}
	}
}

public Action:DelayedEnable(Handle:timer, any:data) {
EnableBB();	
PrintToChatAll("Enable mp_tournament after delay timer");
}



DisableBB(){
	SetConVarInt(FindConVar("mp_tournament"), 0, true);
	PrintToChatAll("Disable mp_tournament");
}

EnableBB(){
	PrintToChatAll("Reached Enable Code but Still has to If");
	SetConVarInt(FindConVar("mp_tournament"), 1, true);
	PrintToChatAll("Enable mp_tournament if first round");
}

public Action:Command_SetClass(client, args)
{
	if (args < 1 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		ReplyToCommand(client, "Usage: sm_setclass <class>");
		return Plugin_Handled;
	}
 
	new String:classchosen[32];
	GetCmdArg(1, classchosen, sizeof(classchosen));
	if (IsClientInGame(client) && IsPlayerAlive(client)) {
	if (StrContains(classchosen, "scout", false) != -1) {TF2_SetPlayerClass(client, TFClassType:TFClass_Scout, true, true); TF2_RespawnPlayer(client);}
	else if (StrContains(classchosen, "soldier", false) != -1) {TF2_SetPlayerClass(client, TFClassType:TFClass_Soldier, true, true); TF2_RespawnPlayer(client);}
	else if (StrContains(classchosen, "pyro", false) != -1) {TF2_SetPlayerClass(client, TFClassType:TFClass_Pyro, true, true); TF2_RespawnPlayer(client);}
	else if (StrContains(classchosen, "engi", false) != -1) {TF2_SetPlayerClass(client, TFClassType:TFClass_Engineer, true, true); TF2_RespawnPlayer(client);}
	else if (StrContains(classchosen, "heavy", false) != -1) {TF2_SetPlayerClass(client, TFClassType:TFClass_Heavy, true, true); TF2_RespawnPlayer(client);}
	else if (StrContains(classchosen, "demo", false) != -1) {TF2_SetPlayerClass(client, TFClassType:TFClass_DemoMan, true, true); TF2_RespawnPlayer(client);}
	else if (StrContains(classchosen, "medic", false) != -1) {TF2_SetPlayerClass(client, TFClassType:TFClass_Medic, true, true); TF2_RespawnPlayer(client);}
	else if (StrContains(classchosen, "sniper", false) != -1) {TF2_SetPlayerClass(client, TFClassType:TFClass_Sniper, true, true); TF2_RespawnPlayer(client);}
	else if (StrContains(classchosen, "spy", false) != -1) {TF2_SetPlayerClass(client, TFClassType:TFClass_Spy, true, true); TF2_RespawnPlayer(client);}
	else {ReplyToCommand(client, "Invalid Class!");}
	} else {ReplyToCommand(client, "You Must be alive to use this command");}
	return Plugin_Handled;
}