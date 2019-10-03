// This code is released under the Gnu General Public License.
// http://en.wikipedia.org/wiki/GNU_General_Public_License

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define TF_TEAM_UNASSIGNED 0
#define TF_TEAM_SPECTATOR 1
#define TF_TEAM_RED 2
#define TF_TEAM_BLUE 3
#define MAX_PLAYERS 256

new Handle:NotifyTimers[MAXPLAYERS+1];
new Float:PlayerHasBeenSwapped[MAX_PLAYERS + 1];
new bool:PlayerHasWavedImmunity[MAX_PLAYERS + 1];

new g_noSpecTimeLimit;
new g_noReswapTimeLimit;
new Float:g_noSwapTimeLeft;
new Float:g_stopBeingPickyTime;
new Float:g_newPlayerImmunityTime;
new g_ownerOffset;
new g_maxClients;
new bool:g_noSwapHasSentry;
new Float:g_roundEndTime;
new bool:g_useRoundEndTime;
new Float:g_startedABTargetSearch;

public Plugin:myinfo = 
{
	name = "QAutobalancer",
	author = "[-Q-] Shana",
	description = "Autobalances the teams",
	version = "1.8",
	url = "www.theqclan.com"
}

public OnPluginStart()
{
	HookEvent("game_start", EventGameStart);
	HookEvent("player_activate", EventPlayerActivate);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("player_team", EventPlayerTeam, EventHookMode_Pre);
	HookEvent("teamplay_timer_time_added", EventTimerAddTime, EventHookMode_Post);
	HookEvent("teamplay_round_start", EventUpdateTimer, EventHookMode_Post);

	RegConsoleCmd("say", CommandCheckImmunity);
	RegConsoleCmd("say_team", CommandCheckImmunity);

	new Handle:handleNoSpecTimeLimit = CreateConVar("sm_autobalance_nospec_timelimit", "300", "The amount of time in seconds that this player cannot use spectate mode.");
	g_noSpecTimeLimit = GetConVarInt(handleNoSpecTimeLimit);

	new Handle:handleNoReswapTimeLimit = CreateConVar("sm_autobalance_noreswap_timelimit", "1800", "The amount of time in seconds of immunity from the autobalancer should another eligable player be present.");
	g_noReswapTimeLimit = GetConVarInt(handleNoReswapTimeLimit);

	new Handle:handleNoSwapTimeLeft = CreateConVar("sm_autobalance_noswap_timeleft", "60", "The amount of time in seconds before the end of a round where we stop swapping players.");
	g_noSwapTimeLeft = 0.0 + GetConVarInt(handleNoSwapTimeLeft);

	new Handle:handleNoSwapHasSentry = CreateConVar("sm_autobalance_noswap_hasSentry", "1", "If 1, we prefer not to swap people who have sentries up.");
	g_noSwapHasSentry = GetConVarBool(handleNoSwapHasSentry);

	new Handle:handleStopBeingPickyTime = CreateConVar("sm_autobalance_stop_being_picky", "60", "The amount of time that can elapse with uneven teams before we just grab the next non-donator");
	g_stopBeingPickyTime = 0.0 + GetConVarInt(handleStopBeingPickyTime);

	new Handle:handleNewPlayerImmunity = CreateConVar("sm_autobalance_new_player_immunity", "300", "The amount of time a new player is given before we consider him for autobalancing");
	g_newPlayerImmunityTime = 0.0 + GetConVarInt(handleNewPlayerImmunity);

	g_ownerOffset = FindSendPropInfo("CBaseObject", "m_hBuilder");
}

public bool:CalculateIsGoodChoice(client) {
	new Float:currentClientSpm;
	new currentClientTeam;

	new Float:redTeamMaxSpm;
	new Float:blueTeamMaxSpm;
	
	new Float:redTeamAvgSpm;
	new Float:blueTeamAvgSpm;

	new Float:currentTeamAvgSpm;

	new bool:isOnWinningTeam = false;
	new bool:isGoodChoice = false;

	new Float:mapTime = GetGameTime();

	if (g_maxClients == 0)
		g_maxClients = GetMaxClients();

	for (new i = 1; i < g_maxClients; i++) {
		if (IsClientInGame(i)) {
			new team = GetClientTeam(i);
			
			new Float:clientConnectionTime = GetClientTime(i);

			// Connection time is time connected to the server, which may be longer than this map's been played
			if (clientConnectionTime > mapTime)
				clientConnectionTime = mapTime;

			clientConnectionTime = clientConnectionTime / 60;

			new clientScore = TF2_GetPlayerResourceData(i, TFResource_TotalScore);
			new Float:clientSpm = clientScore / clientConnectionTime;

			if (IsPluginDebugging(INVALID_HANDLE)) {
				LogToFile("qautobalancer.log", "QAutoBalancer: Client %d: Score %d connection time %f, clientSpm of %f", i, clientScore, clientConnectionTime, clientSpm);
			}

			if (team == TF_TEAM_RED) 
				redTeamMaxSpm += clientSpm;

			if (team == TF_TEAM_BLUE) 
				blueTeamMaxSpm += clientSpm;

			if (i == client) {
				currentClientSpm = clientSpm;
				currentClientTeam = team;
			}
		}
	}

	blueTeamAvgSpm = blueTeamMaxSpm / GetTeamClientCount(TF_TEAM_BLUE);
	redTeamAvgSpm = redTeamMaxSpm / GetTeamClientCount(TF_TEAM_RED);

	// Is this player on the winning team?
	if (currentClientTeam == TF_TEAM_BLUE) {
		currentTeamAvgSpm = blueTeamAvgSpm;
		
		if (blueTeamAvgSpm > redTeamAvgSpm)
			isOnWinningTeam = true;
	}
	
	
	if (currentClientTeam == TF_TEAM_RED) {
		currentTeamAvgSpm = redTeamAvgSpm;
		
		if (redTeamAvgSpm > blueTeamAvgSpm)
			isOnWinningTeam = true;
	}
	

	// If this player is on the winning team and his average spm is higher than the team's spm,
	// he is a good one to swap
	
	if (isOnWinningTeam) {
		// Pick the high scorers from winning teams
		if (currentClientSpm > currentTeamAvgSpm)
			isGoodChoice = true;
	}
	else {
		// Pick the low scorers from loosing teams
		if (currentClientSpm <= currentTeamAvgSpm)
			isGoodChoice = true;
	}


	if (IsPluginDebugging(INVALID_HANDLE)) {
		LogToFile("qautobalancer.log", "QAutoBalancer: Blue team (3) avg score: %f, Red Team (2) avg score: %f, Client %d is on %d team, avg score: %f", blueTeamAvgSpm, redTeamAvgSpm, client, currentClientTeam, currentClientSpm);
	}


	return isGoodChoice;
	
}

public Action:CommandCheckImmunity(client, args) {

	if (!(GetUserFlagBits(client) & ADMFLAG_RESERVATION))
	{
		// This user is not an admin, igore
		return Plugin_Continue;	
	}	

	decl String:text[192];
	if (GetCmdArgString(text, sizeof(text)) < 1) {
		return Plugin_Continue;
	}

	new startidx;
	if (text[strlen(text)-1] == '"') {
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
    
	decl String:message[100];
	BreakString(text[startidx], message, sizeof(message));
    
	if ((strcmp(message, "disableswapimmunity", false) == 0)) {
		PrintToChat(client, "\x01\x03Autobalance immunity removed. Use 'enableswapimmunity' to re-add.");
		PlayerHasWavedImmunity[client] = true;
	}

	if ((strcmp(message, "enableswapimmunity", false) == 0)) {
		PrintToChat(client, "\x01\x03Autobalance immunity enabled. Use 'disableswapimmunity' to remove.");
		PlayerHasWavedImmunity[client] = false;
	}
    
	return Plugin_Continue;    
}


public Action:EventGameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsPluginDebugging(INVALID_HANDLE)) {
		LogToFile("qautobalancer.log", "QAutoBalancer: EventGameStart");
	}

	g_maxClients = GetMaxClients();
	g_startedABTargetSearch = 0.0;

	for (new i = 0; i < MAX_PLAYERS + 1; i++) {
		PlayerHasBeenSwapped[i] = 0.0;
		PlayerHasWavedImmunity[i] = false;
	}
}

public Action:EventPlayerActivate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	PlayerHasBeenSwapped[client] = 0.0;
	PlayerHasWavedImmunity[client] = false;

	return Plugin_Continue;
}


public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.5, NotifyPlayerDeath, GetEventInt(event, "userid"));
}

public Action:EventPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventBool(event, "disconnect")) {
		return Plugin_Continue;
	}

	new userId = GetEventInt(event, "userid");
	new team = GetEventInt(event, "team");
	new client = GetClientOfUserId(userId);
	new oldTeam = GetEventInt(event, "oldteam");

	if ((oldTeam == TF_TEAM_SPECTATOR) || 
 	    (oldTeam == TF_TEAM_UNASSIGNED)) {
		// Don't throw people back onto unassigned or spec
		return Plugin_Continue;
	}

	if ((GetUserFlagBits(client) & ADMFLAG_RESERVATION) && 
	    (PlayerHasWavedImmunity[client] == false))
	{
		// This user is an admin, skip them
		return Plugin_Continue;	
	}

	if (team == TF_TEAM_SPECTATOR) {
		// Check to see if they are banned from going into spectate mode
		if ((PlayerHasBeenSwapped[client] > 0.0) && 
		    (PlayerHasBeenSwapped[client] > (GetGameTime() - g_noSpecTimeLimit))) {
			new Handle:pack;
			CreateDataTimer(0.1, ReswapClient, pack);
			WritePackCell(pack, client);
			WritePackCell(pack, oldTeam);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action:EventTimerAddTime(Handle:event, const String:name[], bool:dontBroadcast)
{
	new secondsAdded = GetEventInt(event, "seconds_added");

	g_roundEndTime += secondsAdded;

	if (IsPluginDebugging(INVALID_HANDLE)) {
		LogToFile("qautobalancer.log", "QAutoBalancer: Time added to clock: %d", secondsAdded);	
	}

	return Plugin_Continue;
}

public Action:EventUpdateTimer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new strClassName[64];
	new MaxEntities = GetEntityCount();
	new timeRemainingOffset = 0;
	new Float:timeRemaining = 0.0;

	for (new i=1;i <= MaxEntities; i++)
	{
		if (IsValidEntity(i))
		{
			GetEntityNetClass(i, String:strClassName, 64);
			if (strcmp(String:strClassName, "CTeamRoundTimer", true) == 0)
			{
				timeRemainingOffset = GetEntSendPropOffs(i, "m_flTimeRemaining");
				timeRemaining = 0.0 + GetEntDataFloat(i, timeRemainingOffset);
			}
		}
	}

	if (timeRemaining) {
		new Float:currentTime = GetGameTime();
		g_roundEndTime = currentTime + timeRemaining;
		g_useRoundEndTime = true;

		if (IsPluginDebugging(INVALID_HANDLE)) {
			LogToFile("qautobalancer.log", "QAutoBalancer: Round started at %f, ends in %f seconds", currentTime, timeRemaining);	
		}
	}
	else
		g_useRoundEndTime = false;

	// Adding a 1 second delay to querying the time, since otherwise we sometimes can ask the clock before
	// the round actually starts, when there's 0.0 seconds on the clock, which leads to an invalid round timer.
	CreateTimer(timeRemaining + 1.0, UpdateTimer);
	return Plugin_Continue;
}

public Action:NotifyDonatorInfo(Handle:timer, any:userid)
{	
	new client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client))
	{
		PrintToChat(client, "\x01\x03Donators are immune to the auto team balancer, and they can teamswap themselves as well. Say DONATE for more info!");
	}
	
	return Plugin_Continue;
}

public Action:NotifyPlayerDeath(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Continue;
	}

	new Float:currentTime = GetGameTime();
	new team = GetClientTeam(client);
	new strClassName[64];
	new MaxEntities = GetEntityCount();
	new bool:hasSentry = false;
	new red = GetTeamClientCount(TF_TEAM_RED);
	new blue = GetTeamClientCount(TF_TEAM_BLUE);
	new bool:ignoreNewPlayerImmunity = false;
	new bool:stopBeingPicky = false;

	if (g_maxClients == 0)
		g_maxClients = GetMaxClients();

	if ((GetUserFlagBits(client) & ADMFLAG_RESERVATION) && 
	    (PlayerHasWavedImmunity[client] == false))
	{

		if (IsPluginDebugging(INVALID_HANDLE)) {
			LogToFile("qautobalancer.log", "QAutoBalancer: Player %d is an admin, skipping.", client);	
		}

		// This user is an admin, skip them
		return Plugin_Continue;	
	}

	new difference = red - blue;
	new swapteam = TF_TEAM_RED;

	if (difference < 0)
	{
		// make sure difference is a positive number and swapteam contains the team with more players
		difference = blue - red;
		swapteam = TF_TEAM_BLUE;
	}

	if (difference < 2)
	{
		// teams are balanced - we only swap if one team has two or more extra players
		g_startedABTargetSearch = 0.0;
		return Plugin_Continue;
	}

	// For Qosis, if the teams are imbalanced by more than 2 players, don't try to be perfect, just grab someone.
	if (difference > 2) {
		if (IsPluginDebugging(INVALID_HANDLE)) {
			LogToFile("qautobalancer.log", "QAutoBalancer: We are imbalanced by %d, which is more than 2, so not being picky.", difference);	
		}

		stopBeingPicky = true;
	}

	// This is the first time we've become unbalanced, remember it so we know when to give up being picky
	if (g_startedABTargetSearch == 0.0) {

		if (IsPluginDebugging(INVALID_HANDLE)) {
			LogToFile("qautobalancer.log", "QAutoBalancer: Setting start of search time to %f", currentTime);	
		}

		g_startedABTargetSearch = currentTime;
	}

	if (team != swapteam) {	
		// this player is on the undermanned team, don't swap
		return Plugin_Continue;
	}

	new Float:timeElapsed = g_roundEndTime - currentTime;

	// Make sure to have the sanity check of TimeElapsed >= 0, to prevent invalid timers from stalling the autobalancer
	if (g_useRoundEndTime && (timeElapsed >= 0) && (timeElapsed < g_noSwapTimeLeft)) {

		// Round is ending, don't swap	
		if (IsPluginDebugging(INVALID_HANDLE)) {
			LogToFile("qautobalancer.log", "QAutoBalancer: The round is ending, don't swap client %d", client);	
		}

		return Plugin_Continue;
	}

	if (IsPluginDebugging(INVALID_HANDLE)) {
		LogToFile("qautobalancer.log", "QAutobalancer: Comparing times to see if we have exceeded length of search. Start time was %f, now is %f, length is %f", g_startedABTargetSearch, currentTime, g_stopBeingPickyTime);
	}

	// If too much time has passed and we still haven't swapped anyone over, don't care about immunities
	if (	(stopBeingPicky == false) &&
		(g_startedABTargetSearch != 0.0) && 
		((g_stopBeingPickyTime + g_startedABTargetSearch) < currentTime)
	) {
		stopBeingPicky = true;

		if (IsPluginDebugging(INVALID_HANDLE)) {
			LogToFile("qautobalancer.log", "QAutoBalancer: Time has exceeded length we tolerate for unbalanced teams (started %f, now is %f)", g_startedABTargetSearch, currentTime);	
		}
	}

	// Only check for immunities if we have the time. If too much time has passed, we don't care who we swap.
	if (stopBeingPicky == false) {

		if (currentTime < (g_newPlayerImmunityTime * 2)) {

			if (IsPluginDebugging(INVALID_HANDLE)) {
				LogToFile("qautobalancer.log", "QAutoBalancer: Round is too new to use new player immunity time checks");	
			}

			ignoreNewPlayerImmunity = true;
		}

		// For the next two immunity checks we want to see if there's anybody else on this team who is immune
		new bool:foundNotImmunePerson = false;
		for (new i = 1; !foundNotImmunePerson && (i < g_maxClients); i++) {
			if (    (i != client) &&							// Don't check our current victim, we're looking for someone else
				IsClientInGame(i) && 							// Is this client in game
				(GetClientTeam(i) == team) && 					// They must be on the overstocked team
				(					
					ignoreNewPlayerImmunity || 					// Is this a new game or
					(GetClientTime(i) >= g_newPlayerImmunityTime)		// has this player been playing long enough to get a feel for their abilities
				) &&
				(
					!(GetUserFlagBits(client) & ADMFLAG_RESERVATION) || 	// This player is not an admin
					(PlayerHasWavedImmunity[client] == true)			// Or they removed their admin immunity
				) &&
				(	(PlayerHasBeenSwapped[i] == 0.0) ||				// This player was not swapped previously
					(PlayerHasBeenSwapped[i] <= (currentTime - g_noReswapTimeLimit)) // This player's immunity has worn off
				)
			) {

				hasSentry = false;

				// Don't swap engies with a sentry still up
				if (g_noSwapHasSentry) 
				{	
					for (new j=1;j <= MaxEntities; j++)
					{
						if (IsValidEntity(j))
						{
							if (strcmp(String:strClassName, "CObjectSentrygun", true) == 0)
							{
								if (GetEntDataEnt2(j, g_ownerOffset) == client)
								{
									hasSentry = true;
								}
							}
						}
					}
				}

				if (hasSentry == false) {
					foundNotImmunePerson = true;
	
					if (IsPluginDebugging(INVALID_HANDLE)) {
						LogToFile("qautobalancer.log", "QAutoBalancer: Found another non-immune player on this team, %d", i);	
					}
				}
			}
				
			if (IsPluginDebugging(INVALID_HANDLE)) {
				if (i == client)
					LogToFile("qautobalancer.log", "QAutoBalancer: This is the same client.");
				else if (!IsClientInGame(i))
					LogToFile("qautobalancer.log", "QAutoBalancer: This client is not in game", client);
				else if (GetClientTeam(i) != team)
					LogToFile("qautobalancer.log", "QAutoBalancer: Client %d is not on team %d", client, team);
				else if (!ignoreNewPlayerImmunity && (GetClientTime(i) < g_newPlayerImmunityTime))
					LogToFile("qautobalancer.log", "QAutoBalancer: This player is too new (%f need %f)", GetClientTime(i), g_newPlayerImmunityTime);
				else if ((GetUserFlagBits(client) & ADMFLAG_RESERVATION) && (PlayerHasWavedImmunity[client] == false))
					LogToFile("qautobalancer.log", "QAutoBalancer: Client %d is an admin and has not waved immunity", client);
				else if ((PlayerHasBeenSwapped[i] != 0.0) && (PlayerHasBeenSwapped[i] > (currentTime - g_noReswapTimeLimit)))
					LogToFile("qautobalancer.log", "QAutoBalancer: Client %d has been recently swapped.", client);
				else if (hasSentry)
					LogToFile("qautobalancer.log", "QAutoBalancer: Client %d has sentry up", client);	
			}

		}
	
		// Only check for sentries or immune times if we have someone else who is eligable
		if (foundNotImmunePerson) {

			// Is this player too new to get a good reading?
			if (!ignoreNewPlayerImmunity && (GetClientTime(client) < g_newPlayerImmunityTime)) {
				if (IsPluginDebugging(INVALID_HANDLE)) {
					LogToFile("qautobalancer.log", "QAutoBalancer: Player %d is too new to get a good reading (connected %f, game time is %f, need %f)", client, GetClientTime(client), currentTime, g_newPlayerImmunityTime);	
				}

  				return Plugin_Continue;
			}

			// Is this player already the autobalancer's bitch? If they've been swapped recently, don't swap them again
			if ((PlayerHasBeenSwapped[client] != 0.0) && (PlayerHasBeenSwapped[client] > (currentTime - g_noReswapTimeLimit))) {


				if (IsPluginDebugging(INVALID_HANDLE)) {
					LogToFile("qautobalancer.log", "QAutoBalancer: Player %d has already been swapped recently at %f, skipping", client, PlayerHasBeenSwapped[client]);	
				}

  				return Plugin_Continue;
			}	

			hasSentry = false;

			// Don't swap engies with a sentry still up
			if (g_noSwapHasSentry) 
			{	
				for (new i=1;i <= MaxEntities; i++)
				{
					if (IsValidEntity(i))
					{
						if (strcmp(String:strClassName, "CObjectSentrygun", true) == 0)
						{
							if (GetEntDataEnt2(i, g_ownerOffset) == client)
							{
								hasSentry = true;
							}
						}
					}
				}

				if (hasSentry) {

					if (IsPluginDebugging(INVALID_HANDLE)) {
						LogToFile("qautobalancer.log", "QAutoBalancer: Player %d has sentry up, skipping", client);	
					}

					return Plugin_Continue;
				}
			}

			// Is this player a good choice to move over?
			if (CalculateIsGoodChoice(client) == false) {


				if (IsPluginDebugging(INVALID_HANDLE)) {
					LogToFile("qautobalancer.log", "QAutoBalancer: Player %d is not a good choice, skipping", client);	
				}

				return Plugin_Continue;
			}


			if (IsPluginDebugging(INVALID_HANDLE)) {
				LogToFile("qautobalancer.log", "QAutoBalancer: Player %d is a good choice", client);	
			}
			
		}
		else if (IsPluginDebugging(INVALID_HANDLE)) {
			LogToFile("qautobalancer.log", "QAutoBalancer: Did not find another immune person", client);	
		}

	}

	// User is on the team with extra players - swap them	
	decl String:teamName[10];
	decl String:clientName[64];

	GetClientName(client, clientName, sizeof(clientName));

	if (team == TF_TEAM_RED) {
		ChangeClientTeam(client, TF_TEAM_BLUE);
		teamName = "blue";
	}
	else {
		ChangeClientTeam(client, TF_TEAM_RED);
		teamName = "red";
	}

	PrintToChatAll("%s has been swapped to the %s team to balance the teams.", clientName, teamName);
	PrintToChat(client, "\x01\x04You have been swapped to balance the teams.");
	NotifyTimers[client] = CreateTimer(30.0, NotifyDonatorInfo, GetClientUserId(client));

	PlayerHasBeenSwapped[client] = currentTime;

	if (IsPluginDebugging(INVALID_HANDLE)) {
		LogToFile("qautobalancer.log", "QAutoBalancer: Swapped player %d. Time elapsed since start of search: %f", client, currentTime - g_startedABTargetSearch);	
	}

	// We've done one swap - if that evened us out, reset our picky timer. Otherwise keep track of it.
	if ((difference - 2) <= 0) {
		g_startedABTargetSearch = 0.0;
		if (IsPluginDebugging(INVALID_HANDLE)) {	
			LogToFile("qautobalancer.log", "QAutoBalancer: Teams are now balanced, resetting time.");
		}
	}

	return Plugin_Continue;
}

public OnClientPutInServer(client) {
	PlayerHasBeenSwapped[client] = 0.0;
}

public Action:ReswapClient(Handle:timer, Handle:pack)
{
	new client;
	new oldTeam;

	ResetPack(pack);
	client = ReadPackCell(pack);
	oldTeam = ReadPackCell(pack);

	if ((GetUserFlagBits(client) & ADMFLAG_RESERVATION) && 
	    (PlayerHasWavedImmunity[client] == false))
	{
		// This user is an admin, skip them
		return Plugin_Continue;	
	}

	PrintToChat(client, "\x01\x04----------------------------------------------");
	PrintToChat(client, "\x01\x04You cannot swap to spectator for %d seconds after being auto swapped.", g_noSpecTimeLimit);
	PrintToChat(client, "\x01\x04----------------------------------------------");
	ChangeClientTeam(client, oldTeam);

	return Plugin_Continue;
}

public Action:UpdateTimer(Handle:timer, any:client)
{
	new strClassName[64];
	new MaxEntities = GetEntityCount();
	new timeRemainingOffset = 0;
	new Float:timeRemaining = 0.0;

	for (new i=1;i <= MaxEntities; i++)
	{
		if (IsValidEntity(i))
		{
			GetEntityNetClass(i, String:strClassName, 64);
			if (strcmp(String:strClassName, "CTeamRoundTimer", true) == 0)
			{
				timeRemainingOffset = GetEntSendPropOffs(i, "m_flTimeRemaining");
				timeRemaining = 0.0 + GetEntDataFloat(i, timeRemainingOffset);
			}
		}
	}

	if (timeRemaining) {
		new Float:currentTime = GetGameTime();
		g_roundEndTime = currentTime + timeRemaining;
		g_useRoundEndTime = true;

		if (IsPluginDebugging(INVALID_HANDLE)) {
			LogToFile("qautobalancer.log", "QAutoBalancer: Round started at %f, ends in %f seconds", currentTime, timeRemaining);	
		}
	}
	else {
		g_useRoundEndTime = false;
	}
	
	return Plugin_Continue;
}
