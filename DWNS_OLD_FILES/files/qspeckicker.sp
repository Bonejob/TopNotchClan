// This code is released under the Gnu General Public License.
// http://en.wikipedia.org/wiki/GNU_General_Public_License

#include <sourcemod>
#include <sdktools>

#define TF_TEAM_UNASSIGNED 0
#define TF_TEAM_SPECTATOR 1
#define TF_TEAM_RED 2
#define TF_TEAM_BLUE 3
#define MAX_PLAYERS 256

new Handle:g_specTimers[MAXPLAYERS+1];

new Float:g_specKickerTimeLimit;

public Plugin:myinfo = 
{
	name = "QSpecKicker",
	author = "[-Q-] Shana",
	description = "Kicks people who idle in spectate mode",
	version = "1.0",
	url = "www.theqclan.com"
}

public OnPluginStart()
{
	HookEvent("player_activate", EventPlayerActivate);
	HookEvent("player_team", EventPlayerTeam, EventHookMode_Pre);

    	new Handle:handleSpecKickerTimeLimit = CreateConVar("sm_speck_kicker_timelimit", "300.0");
	g_specKickerTimeLimit = GetConVarFloat(handleSpecKickerTimeLimit);
}

public Action:EventPlayerActivate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	// Remove any old timers
	if (g_specTimers[client] != INVALID_HANDLE) {
		KillTimer(g_specTimers[client]);
		g_specTimers[client] = INVALID_HANDLE;
	}

	g_specTimers[client] = CreateTimer(g_specKickerTimeLimit, KickPlayerFromSpec, client);

	return Plugin_Continue;
}

public Action:EventPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{

	if (GetEventBool(event, "disconnect")) {
		return Plugin_Continue;
	}

	new userId = GetEventInt(event, "userid");
	new team = GetEventInt(event, "team");
	new client = GetClientOfUserId(userId);

	// Clear any old timers and start a new one
	if (g_specTimers[client] != INVALID_HANDLE) {
		KillTimer(g_specTimers[client]);
		g_specTimers[client] = INVALID_HANDLE;
	}


	if ((team == TF_TEAM_SPECTATOR) ||
	    (team == TF_TEAM_UNASSIGNED)) {
		// Start a new timer
		g_specTimers[client] = CreateTimer(g_specKickerTimeLimit, KickPlayerFromSpec, client);
	}

	return Plugin_Continue;	
}


public Action:KickPlayerFromSpec(Handle:timer, any:client)
{

	g_specTimers[client] = INVALID_HANDLE;

	if (!IsClientConnected(client))
		return Plugin_Continue;

	new team = GetClientTeam(client);

	if ((team != TF_TEAM_SPECTATOR) &&
	    (team != TF_TEAM_UNASSIGNED))
		return Plugin_Continue;

	KickClient(client, "Idled too long in spectator.");
	return Plugin_Continue;
}

