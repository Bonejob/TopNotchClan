/**
 * vim: set ts=4 :
 * =============================================================================
 * Top Scorers Plugin
 *  - Announces top scorers on the losing team
 * =============================================================================
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <morecolors>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "Top Scorers",
	author = "Stealth",
	description = "Announces top scorers on the losing team",
	version = PLUGIN_VERSION
};


// GLOBAL VARIABLES
new g_iStartingScore[MAXPLAYERS + 1];
new g_iScoreOffset;
 
public OnPluginStart()
{
	// Add console var for plugin version
 	CreateConVar("sm_top_scorers_version", PLUGIN_VERSION, "Plugin Version",
		FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED |
		FCVAR_NOTIFY | FCVAR_DONTRECORD);
 
	g_iScoreOffset = FindSendPropOffs("CTFPlayerResource", "m_iTotalScore");
 
	HookEventEx("teamplay_round_start", 	Event_RoundStart);
	HookEventEx("teamplay_win_panel", 		Event_WinPanel);
	
	RegConsoleCmd("mvp_test", Test_MVP);
}

GetPlayerScore(client)
{
	if (IsClientConnected(client))
	{
		new playerManager = FindEntityByClassname(-1, "tf_player_manager");
		if (playerManager == -1)
		{
			SetFailState("Could not find \"tf_player_manager\" entity");
		}
		else
		{
			return GetEntData(playerManager, g_iScoreOffset + (client * 4), 4);	
		}
	}
	
	return -1;
}
 
public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	g_iStartingScore[client] = 0;
	return true;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		g_iStartingScore[i] = GetPlayerScore(i);
	}
}

public Event_WinPanel(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iWinningTeam = GetEventInt(event, "winning_team");
	if (iWinningTeam == 2 || iWinningTeam == 3)
	{
		new iLosingTeam = iWinningTeam == 3 ? 2 : 3;		
		CreateTimer(0.1, Timer_DisplayResults, iLosingTeam);
	}
}

public Action:Timer_DisplayResults(Handle:timer, any:iLosingTeam)
{
	new iFinalScores[MaxClients][2];
	
	for (new i = 0; i < MaxClients; i++)
	{
		new client = i + 1;
		iFinalScores[i][0] = client;
		if (IsClientInGame(client) && GetClientTeam(client) == iLosingTeam)
		{		
			iFinalScores[i][1] = GetPlayerScore(client) - g_iStartingScore[client];
		}
		else
		{
			iFinalScores[i][1] = -1;
		}
	}
	
	SortCustom2D(iFinalScores, MaxClients, SortGreater);
	
	if (iLosingTeam == 2)
	{
		CPrintToChatAll("{gold}Best LOSERS {white}on {red}RED");
	}
	else
	{
		CPrintToChatAll("{gold}Best LOSERS {white}on {blue}BLU");
	}
		
	CPrintToChatAll("{azure}[{whitesmoke}#{azure}]{default}   (score)    (name)");
	
	decl String:sPlayerName[MAX_NAME_LENGTH];
	for (new i = 0; i < 3; i++)
	{
		if (iFinalScores[i][1] > 0)
		{			
			GetClientName(iFinalScores[i][0], sPlayerName, sizeof(sPlayerName));
			CPrintToChatAll("{azure}[{whitesmoke}%d{azure}]{default}       %d       %s", i+1, iFinalScores[i][1], sPlayerName);
		}
	}
}

public Action Test_MVP(int client, intargs)
{
	CreateTimer(0.1, Timer_DisplayResults, 2);
	CreateTimer(3.0, Timer_DisplayResults, 3);
}

public SortGreater(x[], y[], array[][], Handle:data)
{
	if (x[1] > y[1])
		return -1;
	else if (x[1] < y[1])
		return 1;
	return 0;
}
