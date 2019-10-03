/************************************************************************
*************************************************************************
Simple Team Manager
Description:
	Manges players and their team
	Admin menu integration
	Allows admins/donators to swap their teams (clears force)*
	Allows admins to move players to a team (forced\unforced)*
	Allows admins to scramble the teams*
		*Works with Simple Team Balancer (if installed)
*************************************************************************
*************************************************************************
This file is part of Simple SourceMod Plugins project.

This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************
File Information
$Id: simple-teammanager.sp 107 2009-09-20 23:29:04Z antithasys $
$Author: antithasys $
$Revision: 107 $
$Date: 2009-09-20 18:29:04 -0500 (Sun, 20 Sep 2009) $
$LastChangedBy: antithasys $
$LastChangedDate: 2009-09-20 18:29:04 -0500 (Sun, 20 Sep 2009) $
$URL: http://projects.mygsn.net/svn/simple-plugins/trunk/simple-plugins/addons/sourcemod/scripting/simple-teammanager.sp $
$Copyright: (c) Simple SourceMod Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/

#include <simple-plugins>
#include <gscramble>	/* TN Addition */

#define PLUGIN_VERSION "2.0.$Revision: 107 $"
#define VOTE_YES "##YES##"
#define VOTE_NO "##NO##"
#define Shame "vo/Announcer_am_lastmanforfeit03.mp3"	/* TN Addition */
//#define Shame "TopNotchClan/shame.mp3"	/* TN Addition */

enum PlayerData
{
	iNewTeam,
	bool:bQueue
};

new Handle:stm_enabled = INVALID_HANDLE;
new Handle:stm_logactivity = INVALID_HANDLE;
new Handle:stm_adminflag_swapteam = INVALID_HANDLE;
new Handle:stm_adminflag_moveplayer = INVALID_HANDLE;
new Handle:stm_adminflag_scramble = INVALID_HANDLE;
new Handle:stm_scrambledelay = INVALID_HANDLE;
new Handle:stm_voteenabled = INVALID_HANDLE;
new Handle:stm_votewin = INVALID_HANDLE;
new Handle:stm_votedelay = INVALID_HANDLE;
new Handle:stm_mp_bonusroundtime = INVALID_HANDLE;
new Handle:g_hAdminMenu = INVALID_HANDLE;
new Handle:g_hTimerPrepScramble = INVALID_HANDLE;
new Handle:g_hTimerClearScrambleForce = INVALID_HANDLE;

new g_aPlayers[MAXPLAYERS + 1][PlayerData];

new bool:g_bIsEnabled = true;
new bool:g_bVoteEnabled = true;
new bool:g_bLogActivity = true;
new bool:g_bScrambleRoundEnd = false;
new bool:g_bRateShame = true;	/* TN Addition */
new g_iVoteDelay, g_iLastVoteTime, g_iTimeLeft;
new Float:g_fScrambleDelay, Float:g_fVoteWin;

public Plugin:myinfo =
{
	name = "Simple Team Manager Custom",
	author = "Antithasys,DWN,Ben,Stealth",
	description = "Manages players and thier team.",
	version = PLUGIN_VERSION,
	url = "http://projects.mygsn.net"
};

public OnPluginStart()
{

	/**
	Need to create all of our console variables.
	*/
	CreateConVar("stm_version", PLUGIN_VERSION, "Simple Team Manager Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	stm_enabled = CreateConVar("stm_enabled", "1", "Enable or Disable Simple Team Manager", _, true, 0.0, true, 1.0);
	stm_logactivity = CreateConVar("stm_logactivity", "0", "Enable or Disable the disaplying of events in the log", _, true, 0.0, true, 1.0);
	stm_adminflag_swapteam = CreateConVar("stm_adminflag_swapteam", "a", "Admin flag to use for the swapteam command.  Must be a in char format.");
	stm_adminflag_moveplayer = CreateConVar("stm_adminflag_moveplayer", "c", "Admin flag to use for the moveplayer command.  Must be a in char format.");
	stm_adminflag_scramble = CreateConVar("stm_adminflag_scramble", "c", "Admin flag to use for the scrambleteam command.  Must be a in char format.");
	stm_scrambledelay = CreateConVar("stm_scrambledelay", "15", "Delay to scramble teams");
	stm_voteenabled = CreateConVar("stm_voteenabled", "1", "Enable or Disable voting to scramble the teams", _, true, 0.0, true, 1.0);
	stm_votewin = CreateConVar("stm_votewin", "0.45", "Win percentage vote must win by", _, true, 0.0, true, 1.0);
	stm_votedelay = CreateConVar("stm_votedelay", "600", "Delay before another vote can be cast");
	stm_mp_bonusroundtime = FindConVar("mp_bonusroundtime");

	
	/**
	Need deal with changes to the console variables after the plugin is loaded.
	We could not do this and just call the actual console variable each time we need it, but it's not efficent.
	*/
	HookConVarChange(stm_enabled, ConVarSettingsChanged);
	HookConVarChange(stm_logactivity, ConVarSettingsChanged);
	HookConVarChange(stm_scrambledelay, ConVarSettingsChanged);
	HookConVarChange(stm_voteenabled, ConVarSettingsChanged);
	HookConVarChange(stm_votewin, ConVarSettingsChanged);
	HookConVarChange(stm_votedelay, ConVarSettingsChanged);
	
	/* TN Addition */
	AddFileToDownloadsTable("sound/TopNotchClan/shame.mp3");
	
	/**
	Need to register the commands we are going to create and use.
	*/
	RegConsoleCmd("sm_swapteam", Command_SwapTeam, "sm_swapteam <[0]instant/[1]queued>: Swaps your team to the other team");
	RegConsoleCmd("sm_moveplayer", Command_MovePlayer, "sm_moveplayer <name/#userid> <team[number/name]> <[0]instant/[1]ondeath> <[0]unforced/[1]forced>: Moves a player to the specified team");
	RegConsoleCmd("sm_scrambleteams", Command_ScrambleTeams, "sm_scrambleteams: <[0]now/[1]roundend> <[0]dontrestart/[1]restartround> Scrambles the current teams");
	RegConsoleCmd("sm_votescramble", Command_VoteScramble, "sm_votescramble: Starts a vote to scramble the teams");
	
	/**
	Get game type and load the team numbers
	*/
	g_CurrentMod = GetCurrentMod();
	LoadCurrentTeams();
	
	/**
	Hook the game events
	*/
	LogAction(0, -1, "[STM] Hooking events for [%s].", g_sGameName[g_CurrentMod]);
	HookEvent("player_death", HookPlayerDeath, EventHookMode_Post);
	HookEvent("player_team", HookPlayerChangeTeam, EventHookMode_Post);
	switch (g_CurrentMod)
	{
		case GameType_TF:
		{
			HookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_Post);
		}
		case GameType_DOD:
		{
			HookEvent("dod_round_win", HookRoundEnd, EventHookMode_Post);
		}
		default:
		{
			HookEvent("round_end", HookRoundEnd, EventHookMode_PostNoCopy);
		}
	}
	
	/**
	Now we have to deal with the admin menu.  If the admin library is loaded call the function to add our items.
	*/
	new Handle:gTopMenu;
	if (LibraryExists("adminmenu") && ((gTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(gTopMenu);
	}
	
	/**
	Load translations and .cfg file
	*/
	LoadTranslations ("simpleteammanager.phrases");
	AutoExecConfig(true, "plugin.simpleteammanager");
	LogAction(0, -1, "[STM] Simple Team Manager is loaded.");
}

public OnAllPluginsLoaded()
{
	//something
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
	
		/**
		Looks like the admin menu was removed.  Set the global.
		*/
		g_hAdminMenu = INVALID_HANDLE;
	}
	else if (StrEqual(name, "simpleplugins"))
	{
		SetFailState("Required plugin Simple SourceMod Plugins Core was removed.");
	}
}

/* TN Addition */
public OnMapStart()
{
	PrecacheSound(Shame, true);
	g_bRateShame = true;
}

public OnConfigsExecuted()
{

	/**
	Once we loaded up all the console variables from the config file, lets now set all the global variables we will use.
	*/
	g_bIsEnabled = GetConVarBool(stm_enabled);
	g_bLogActivity = GetConVarBool(stm_logactivity);
	g_fScrambleDelay = GetConVarFloat(stm_scrambledelay);
	g_iVoteDelay = GetConVarInt(stm_votedelay);
	g_fVoteWin = GetConVarFloat(stm_votewin);
	g_iLastVoteTime = RoundFloat(GetEngineTime());
	g_bScrambleRoundEnd = false;
	g_hTimerClearScrambleForce = INVALID_HANDLE;
	
	/**
	Report enabled
	*/
	if (g_bIsEnabled)
	{
		LogAction(0, -1, "[STM] Simple Team Manager is ENABLED.");
	}
	else
	{
		LogAction(0, -1, "[STM] Simple Team Manager is DISABLED.");
	}	

	if (g_bLogActivity)
	{
		LogAction(0, -1, "[STM] Log Activity ENABLED.");
	}
	else
	{
		LogAction(0, -1, "[STM] Log Activity DISABLED.");
	}
}

/* COMMANDS */

public Action:Command_SwapTeam(client, args)
{

	/**
	Make sure we are enabled, if not bug out.
	*/
	if (!g_bIsEnabled)
	{
		return Plugin_Handled;
	}
	
	/**
	If this was ran from the console bug out.
	*/
	if (client == 0)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %T", "PlayerLevelCmd", LANG_SERVER);
		return Plugin_Handled;
	}
	
	/**
	Make sure the client is authorized to run this command.
	*/
	decl String:sFlags[5];
	GetConVarString(stm_adminflag_swapteam, sFlags, sizeof(sFlags));
	if (!SM_IsValidAdmin(client, sFlags))
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %T", "RestrictedCmd", LANG_SERVER);
		return Plugin_Handled;
	}
	
	/**
	TN Addition - Block !swapteam from donators after scramble
	*/
	if (GS_IsClientTeamChangeBlocked(client, 1))
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 You cannot swap teams after a scramble! FOR SHAME!");
		if (g_bRateShame) {
			EmitSoundToAll(Shame, _, _, _, _, 1.0);
			g_bRateShame = false;
			CreateTimer(300.0, Timer_PlaySound, TIMER_FLAG_NO_MAPCHANGE);
		}
		return Plugin_Handled;
	}
	
	/**
	Lets make sure the client is one a team we can swap.
	If he is we set the global array to the opposite team.
	*/
	new iTeam = GetClientTeam(client);
	if (iTeam == g_aCurrentTeams[Team1])
	{
		g_aPlayers[client][iNewTeam] = g_aCurrentTeams[Team2];
	}
	else  if (iTeam == g_aCurrentTeams[Team2])
	{
		g_aPlayers[client][iNewTeam] = g_aCurrentTeams[Team1];
	}
	else
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %T", "InValidTeam", LANG_SERVER);
		return Plugin_Handled;
	}
	
	/**
	Check to see if we have command arguments.
	*/
	if (GetCmdArgs())
	{
	
		/**
		We do, so lets get it and see if the client wants to be switched instantly or queued for death.
		*/
		decl String:sArg[5];
		GetCmdArg(1, sArg, sizeof(sArg));
		new iWantsQue = StringToInt(sArg);
		if (iWantsQue && !g_aPlayers[client][bQueue])
		{
		
			/**
			He wants the que and isn't already in it, set the global array.
			*/
			g_aPlayers[client][bQueue] = true;
			ReplyToCommand(client, "\x01\x04[STM]\x01 %T", "PlayerQueue", LANG_SERVER);
		}
		else if (!iWantsQue)
		{
		
			/**
			He wants to be switched right now, lets call the stock function.
			*/
			SM_MovePlayer(client, g_aPlayers[client][iNewTeam]);
		}
	}
	else
	{
		
		/**
		There are no command arguments so we build and display the swap menu.
		*/
		DisplaySwapModeMenu(client, client);
	}
	
	/**
	We are done, bug out.
	*/
	return Plugin_Handled;
}

public Action:Command_MovePlayer(client, args)
{
	
	/**
	Make sure we are enabled, if not bug out.
	*/
	if (!g_bIsEnabled)
	{
		return Plugin_Handled;
	}
	
	/**
	Make sure the client is authorized to run this command.
	*/
	decl String:sFlags[5];
	GetConVarString(stm_adminflag_moveplayer, sFlags, sizeof(sFlags));
	if (!SM_IsValidAdmin(client, sFlags))
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %T", "RestrictedCmd", LANG_SERVER);
		return Plugin_Handled;
	}
	
	/**
	Check to see if we have command arguments.
	*/
	new iCmdArgs = GetCmdArgs();
	if (iCmdArgs == 0)
	{
	
		/**
		We don't. Build the player menu, display it, and bug out.
		*/
		DisplayPlayerMenu(client);
		return Plugin_Handled;
	}
	
	/**
	Check the first argument
	If should be a players name or userid.
	*/
	decl String:sPlayer[64];
	GetCmdArg(1, sPlayer, sizeof(sPlayer));
	new iPlayerIndex = FindTarget(client, sPlayer, true, true);
	if (iPlayerIndex == -1 || !IsClientInGame(iPlayerIndex))
	{
	
		/**
		We don't know who this is. Build the player menu, display it, and bug out.
		*/
		DisplayPlayerMenu(client);
		return Plugin_Handled;
	}
	
	/**
	We have figured out the first argument, lets check the second.
	If should be the team the client wants to put the player on.
	*/
	if (iCmdArgs >= 2)
	{
	
		/**
		We have a command argument at least, lets see if we can identify the team.
		*/	
		decl String:sTeam[24];
		GetCmdArg(2, sTeam, sizeof(sTeam));

		new iTeam = StringToInt(sTeam);
		if (SM_IsValidTeam(iTeam))
		{
			
			/**
			It's a vaild team so lets set the global array to the new team.
			*/
			g_aPlayers[iPlayerIndex][iNewTeam] = iTeam;
		}
		else
		{
			
			/**
			It's not a vaild team so set the menu to display to the team menu.
			*/
			DisplayTeamMenu(client, iPlayerIndex);
			return Plugin_Handled;
		}
	}
	else
	{
		/**
		We were not given a team, display the team menu.
		*/
		DisplayTeamMenu(client, iPlayerIndex);
		return Plugin_Handled;	
	}
		
	/**
	Check to see if we were given any more command arguments and found a team.
	*/
	if (iCmdArgs < 3)
	{
	
		/**
		No more command arguments and found a team.
		Now lets check to see if the player is a spectator.  If he is there is no reason to ask if it's instant or on death... he can't die.
		*/
		if (!IsClientObserver(iPlayerIndex))
		{
	
			/**
			Not a spectator so display the swapmode menu.
			*/
			DisplaySwapModeMenu(client, iPlayerIndex);
		}
		else
		{
		
			/**
			The player is a spectator.
			We make sure the player is not set to switch on death, since a spec can't die.
			*/
			g_aPlayers[iPlayerIndex][bQueue] = false;
		}
	}
	
	/**
	We have figured out the second argument, lets check the third.
	If should be the how the client wants to move the player: instant/on death.
	*/
	if (iCmdArgs >= 3)
	{
	
		/**
		The client gave us a command argument, lets check it.
		*/
		decl String:sSwapMode[5];
		GetCmdArg(3, sSwapMode, sizeof(sSwapMode));
		new iWantsQue = StringToInt(sSwapMode);
		if (iWantsQue)
		{
			
			/**
			The client wants to que the player, set the global array.
			*/
			g_aPlayers[iPlayerIndex][bQueue] = true;
		}
		else
		{
		
			/**
			The client doesn't want to que the player, set the global array.
			*/
			g_aPlayers[iPlayerIndex][bQueue] = false;
		}
	}
	else
	{
		/**
		No swapmode argument, display the menu
		*/
		DisplaySwapModeMenu(client, iPlayerIndex);
	}

	if (iCmdArgs >= 4)
	{
	
		/**
		Since we are compiling for Simple Team Balancer, and given a 4th argument, lets check it.
		If should be the if the client wants to force the player to that team.
		*/
		decl String:sPlayerForced[5];
		GetCmdArg(4, sPlayerForced, sizeof(sPlayerForced));
		new iForceHim = StringToInt(sPlayerForced);
		if (iForceHim)
		{
		
			/**
			The client wants to force the player
			*/
			SM_SetForcedTeam(iPlayerIndex, g_aPlayers[iPlayerIndex][iNewTeam]);
		}
		else
		{
		
			/**
			The client doesn't want to force the player
			*/
			SM_ClearForcedTeam(iPlayerIndex);
		}
	}
	else
	{

	}

	/**
	We found and processed all the arguments.
	*/
	if (!IsPlayerAlive(iPlayerIndex))
	{
			
		/**
		The player is not alive or died during this process so we just move him.
		*/
		SM_MovePlayer(iPlayerIndex, g_aPlayers[iPlayerIndex][iNewTeam]);
	}
	else
	{
		if (!g_aPlayers[iPlayerIndex][bQueue])
		{
			
			/**
			The player is alive and is not set to be queued so we just move him.
			*/
			SM_MovePlayer(iPlayerIndex, g_aPlayers[iPlayerIndex][iNewTeam]);
		}
	}

	
	/**
	We are done, bug out.
	*/
	return Plugin_Handled;
}

public Action:Command_ScrambleTeams(client, args)
{

	/**
	Make sure we are enabled, if not bug out.
	*/
	if (!g_bIsEnabled)
	{
		return Plugin_Handled;
	}
	
	/**
	Make sure the client is authorized to run this command.
	*/
	decl String:sFlags[5];
	GetConVarString(stm_adminflag_scramble, sFlags, sizeof(sFlags));
	if (!SM_IsValidAdmin(client, sFlags))
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %T", "RestrictedCmd", LANG_SERVER);
		return Plugin_Handled;
	}
	
	/**
	Check if a scramble timer was already called, if so close it down.
	*/
	if (g_hTimerPrepScramble != INVALID_HANDLE)
	{
		CloseHandle(g_hTimerPrepScramble);
		g_hTimerPrepScramble = INVALID_HANDLE;
	}

	/**
	Check if we have any command arguments.
	If we don't we display the scramble menu and bug out.
	*/	
	new iCmdArgs = GetCmdArgs();
	if (iCmdArgs == 0)
	{
		DisplayScrambleMenu(client);
		return Plugin_Handled;
	}
	
	/**
	We have a command argument.
	It should be whether or not to scramble at round end.
	*/
	decl String:sRoundEnd[5];
	GetCmdArg(1, sRoundEnd, sizeof(sRoundEnd));
	if (StringToInt(sRoundEnd))
	{
		/**
		The client wants to scramble at round end so we set the global bool.
		*/
		g_bScrambleRoundEnd = true;
	}
	else
	{
		g_bScrambleRoundEnd = false;
	}
	
	/**
	Check for another command argument.
	It should be whether or not to restart the round.
	*/
	decl String:sRestartRound[5];
	new bool:bRestartRound = false;
	GetCmdArg(1, sRestartRound, sizeof(sRestartRound));
	if (StringToInt(sRestartRound))
	{
		bRestartRound = true;
	}
	
	/**
	Now we start the scramble timer.
	*/
	StartScrambleTimer(_, bRestartRound);
	
	
	/**
	We are done, bug out.
	*/
	return Plugin_Handled;
}

public Action:Command_VoteScramble(client, args)
{

	/**
	Make sure we are enabled, if not bug out.
	*/
	if (!g_bVoteEnabled || !g_bIsEnabled)
	{
		return Plugin_Handled;
	}
	
	/**
	Make sure there is a vote in progress, if so bug out.
	*/
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %T", "VoteInProgress", LANG_SERVER);
		return Plugin_Handled;
	}
	
	/**
	Make sure enough time has passed since the last vote.
	*/
	new iVoteTime = RoundFloat(GetEngineTime());
	if (iVoteTime - g_iLastVoteTime <= g_iVoteDelay)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %T", "ScrambleTime", LANG_SERVER);
		return Plugin_Handled;
	}
	
	/**
	Enough time has passed so reset the global vote time to now.
	*/
	g_iLastVoteTime = iVoteTime;
	
	/**
	Build the vote menu and send it to everyone.
	*/
	new Handle:hMenu = CreateMenu(Menu_VoteScramble);
	SetMenuTitle(hMenu, "Scramble Teams?");
	AddMenuItem(hMenu, VOTE_YES, "Yes");
	AddMenuItem(hMenu, VOTE_NO, "No");
	SetMenuExitButton(hMenu, false);
	VoteMenuToAll(hMenu, 20);
	
	/**
	We are done, bug out.
	*/
	return Plugin_Handled;
}

/* HOOKED EVENTS */

public HookPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	/**
	Find out who died.
	*/
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	/**
	Find out how the client died.
	*/
	new String:sWeapon[64];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
	if (StrEqual(sWeapon, "world", false))
	{
		
		/**
		He died because he changed teams so cleanup and bug out.
		*/
		s_CleanUp(iClient);
		return;
	}
	
	/**
	Find out if this player was queued to change teams.
	*/
	if (g_aPlayers[iClient][bQueue])
	{
		/**
		Looks like he was, so call the stock function to move him.
		*/
		SM_MovePlayer(iClient, g_aPlayers[iClient][iNewTeam]);
	}
}

public HookPlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	/**
	Find out who changed teams.
	*/
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	/**
	If he was queued to switch teams we cleanup the variables.  The client did it themself.
	*/
	if (g_aPlayers[iClient][bQueue])
	{
		s_CleanUp(iClient);
	}
}

public HookRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{

	/**
	Get the amount of time left in the map.
	*/
	new iTimeLeft;
	GetMapTimeLeft(iTimeLeft);
	
	/**
	Check to see if we are supposed to scramble at the end of the round and that there is enough time left in the map.
	*/
	if (g_bScrambleRoundEnd && iTimeLeft >= 60)
	{
	
		/**
		Check to see if there is a scramble timer in action and if so close it down.
		*/
		if (g_hTimerPrepScramble != INVALID_HANDLE)
		{
			CloseHandle(g_hTimerPrepScramble);
			g_hTimerPrepScramble = INVALID_HANDLE;
		}
		
		/**
		Determine the round end chat time and run the scramble 1 second before it ends.
		*/
		new Float:fDelay = GetConVarFloat(stm_mp_bonusroundtime);
		fDelay -= 1.0;
		StartScrambleTimer(fDelay);
	}
}

public OnClientPostAdminCheck(client)
{

	/**
	Determine if the client has the flag to use the swapteam command.
	*/
	decl String:sFlags[5];
	GetConVarString(stm_adminflag_swapteam, sFlags, sizeof(sFlags));
	if (SM_IsValidAdmin(client, sFlags))
	{
		/**
		The client does so lets create a timer to run an advertise to tell him about it.
		*/
		CreateTimer (60.0, Timer_WelcomeAdvert, client);
	}
}

public OnClientDisconnect(client)
{

	/**
	Cleanup the clients variables.
	*/
	s_CleanUp(client);
}

public SM_OnPlayerMoved(Handle:plugin, client, team)
{

	/**
	Make sure we called the move function
	*/
	if (plugin != GetMyHandle())
	{
		if (g_bLogActivity)
		{
			LogAction(0, client, "[STM] Callback was not started with current plugin, bugging out.");
		}
		return;
	}

	decl String:sPlayerName[64];
	GetClientName(client, sPlayerName, sizeof(sPlayerName));

	PrintToChat(client, "\x01\x04[SM]\x01 %T", "PlayerSwitched", LANG_SERVER);
	
	s_CleanUp(client);
}

/* TIMER FUNCTIONS */

public Action:Timer_PrepTeamScramble(Handle:timer, any:data)
{
	new bool:bRestartRound = data;
	/**
	Call the scramble the teams stock function.
	*/
	PrepTeamScramble(bRestartRound);

	/**
	Reset the timer handle so we know the timer is done.
	*/
	g_hTimerPrepScramble = INVALID_HANDLE;
	
	/**
	We are done, bug out.
	*/
	return Plugin_Handled;
}

public Action:Timer_ScrambleTheTeams(Handle:timer, any:data)
{
	new iPlayers[MAXPLAYERS + 1];
	new iCount, i, bool:bTeam, bool:bRestartRound = data;

	/**
	Get all the client index numbers of valid players
	*/
	for(i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) // && !IsFakeClient(i))
		{
			iPlayers[iCount++] = i;
		}
	}
	
	/**
	Randomly sort the players
	*/
	SortIntegers(iPlayers, iCount, Sort_Random);
	
	/**
	Loop through all the players and assign each one to a team, alternating each time
	*/
	for(i = 0; i < iCount; i++)
	{
		if (!bRestartRound)
		{
			/**
			We didn't want to restart the round, so we move them to spec 1 at a time.
			*/
			SM_MovePlayer(iPlayers[i], g_aCurrentTeams[Spectator]);
		}
		SM_MovePlayer(iPlayers[i], bTeam ? g_aCurrentTeams[Team2] : g_aCurrentTeams[Team1]);
		SM_SetForcedTeam(iPlayers[i], bTeam ? g_aCurrentTeams[Team2] : g_aCurrentTeams[Team1], true);
		bTeam = !bTeam;
    }
	
	/**
	Reset this variable since we completed a scramble
	*/
	g_bScrambleRoundEnd = false;
	
	if (g_hTimerClearScrambleForce != INVALID_HANDLE)
	{
		CloseHandle(g_hTimerClearScrambleForce);
		g_hTimerClearScrambleForce = INVALID_HANDLE;
	}
	
	g_hTimerClearScrambleForce = CreateTimer(300.0, Timer_ClearScrambleForce, _, TIMER_FLAG_NO_MAPCHANGE);
	
	ServerCommand("mp_timelimit %i", g_iTimeLeft / 60);
	
	/**
	We are done, bug out.
	*/
	return Plugin_Handled;
}

public Action:Timer_ClearScrambleForce(Handle:timer, any:data)
{
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) // && !IsFakeClient(i))
		{
			SM_ClearForcedTeam(i);
			PrintToChat(i, "\x01\x04[SM]\x01 Your forced team status has been cleared");
		}
	}
	
	g_hTimerClearScrambleForce = INVALID_HANDLE;
	
	/**
	We are done, bug out.
	*/
	return Plugin_Handled;
}

public Action:Timer_WelcomeAdvert(Handle:timer, any:client)
{

	/**
	Lets make sure the client is connected and actually in the game.
	*/
	if (IsClientConnected(client) && IsClientInGame(client))
	{
	
		/**
		We are good to go so lets tell him about the swapteam command.
		*/
		PrintToChat (client, "\x01\x04[STM]\x01 %T", "SwapTeamMsg", LANG_SERVER);
	}
	
	/**
	We are done, bug out.
	*/
	return Plugin_Handled;
}

/* TN Addition */
public Action:Timer_PlaySound(Handle:timer, any:client)
{
	g_bRateShame = true;
	return Plugin_Handled;
}

/* STOCK FUNCTIONS */

stock s_CleanUp(iClient)
{

	/**
	Reset all the client variables
	*/
	g_aPlayers[iClient][bQueue] = false;
	g_aPlayers[iClient][iNewTeam] = 0;
}

stock StartScrambleTimer(Float:fdelay = 0.0, bool:bRestartRound = false)
{
	if (fdelay == 0.0)
	{
		fdelay = g_fScrambleDelay;
	}
	if (g_hTimerPrepScramble != INVALID_HANDLE)
	{
		CloseHandle(g_hTimerPrepScramble);
		g_hTimerPrepScramble = INVALID_HANDLE;
	}
	PrintCenterTextAll("%T", "Scramble", LANG_SERVER);
	g_hTimerPrepScramble = CreateTimer(fdelay, Timer_PrepTeamScramble, bRestartRound, TIMER_FLAG_NO_MAPCHANGE);
}

stock PrepTeamScramble(bool:bRestartRound = false)
{
	new iPlayers[MAXPLAYERS + 1];
	new iCount;
	
	GetMapTimeLeft(g_iTimeLeft);
	
	if (bRestartRound)
	{

		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			// && !IsFakeClient(i))
			{
				iPlayers[iCount++] = i;
				SM_ClearForcedTeam(i);
				SM_ClearBuddy(i);
				SM_MovePlayer(i, g_aCurrentTeams[Spectator]);
			}
		}
	}
	else
	{
		//Can't move them all to spec at the same time
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			// && !IsFakeClient(i))
			{
				iPlayers[iCount++] = i;
				SM_ClearForcedTeam(i);
				SM_ClearBuddy(i);
				//SM_MovePlayer(i, g_aCurrentTeams[Spectator]);
			}
		}
	}
	CreateTimer(4.0, Timer_ScrambleTheTeams, bRestartRound, TIMER_FLAG_NO_MAPCHANGE);
}

/* CONSOLE VARIABLE CHANGE EVENT */

public ConVarSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == stm_enabled) {
		if (StringToInt(newValue) == 0) {
			g_bIsEnabled = false;
			LogAction(0, -1, "[STM] Simple Team Manager is loaded and disabled.");
		} else {
			g_bIsEnabled = true;
			LogAction(0, -1, "[STM] Simple Team Manager is loaded and enabled.");
		}
	} 
	else if (convar == stm_logactivity) {
		if (StringToInt(newValue) == 0) {
			g_bLogActivity = false;
			LogAction(0, -1, "[STM] Log Activity DISABLED.");
		} else {
			g_bLogActivity = true;
			LogAction(0, -1, "[STM] Log Activity ENABLED.");
		}
	}
	else if (convar == stm_scrambledelay)
		g_fScrambleDelay = StringToFloat(newValue);
	else if (convar == stm_votewin)
		g_fVoteWin = StringToFloat(newValue);
	else if (convar == stm_votedelay)
		g_iVoteDelay = StringToInt(newValue);
	else if (convar == stm_voteenabled) {
		if (StringToInt(newValue) == 0)
			g_bVoteEnabled = false;
		else
			g_bVoteEnabled = true;
	}
}

/* MENU CODE */

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == g_hAdminMenu)
		return;
	g_hAdminMenu = topmenu;
	new TopMenuObject:player_commands = FindTopMenuCategory(g_hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
	new TopMenuObject:server_commands = FindTopMenuCategory(g_hAdminMenu, ADMINMENU_SERVERCOMMANDS);
 	if (player_commands == INVALID_TOPMENUOBJECT)
		return;
		
	AddToTopMenu(g_hAdminMenu, 
		"moveplayer",
		TopMenuObject_Item,
		AdminMenu_MovePlayer,
		player_commands,
		"moveplayer",
		ADMFLAG_BAN);
		
	AddToTopMenu(g_hAdminMenu,
		"scrambleteams",
		TopMenuObject_Item,
		AdminMenu_Scrambleteams,
		server_commands,
		"scrambleteams",
		ADMFLAG_BAN);
}
 
public AdminMenu_MovePlayer(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Move Player");
	else if (action == TopMenuAction_SelectOption){
		DisplayPlayerMenu(param);
	}
}

public AdminMenu_Scrambleteams(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "Scramble Teams");
	else if (action == TopMenuAction_SelectOption) {
		DisplayScrambleMenu(param);
	}
}

public Menu_SelectPlayer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		new String:sSelection[64];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		DisplayTeamMenu(param1, GetClientOfUserId(StringToInt(sSelection)));
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE && GetUserFlagBits(param1) & ADMFLAG_BAN)
			DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
	} else if (action == MenuAction_End)
		CloseHandle(menu);
	return;
}

public Menu_SelectTeam(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		new iTeam;
		new String:sSelection[64];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		decl String:sIndex[64];
		if (SplitString(sSelection, "A", sIndex, sizeof(sIndex)) != -1)
			iTeam = g_aCurrentTeams[Team1];
		else if (SplitString(sSelection, "B", sIndex, sizeof(sIndex)) != -1)
			iTeam = g_aCurrentTeams[Team2];
		else {
			SplitString(sSelection, "C", sIndex, sizeof(sIndex));
			iTeam = g_aCurrentTeams[Spectator];
		}
		new iTarget = StringToInt(sIndex);
		g_aPlayers[iTarget][iNewTeam] = iTeam;
		DisplaySwapModeMenu(param1, iTarget);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE && GetUserFlagBits(param1) & ADMFLAG_BAN)
			DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
	} else if (action == MenuAction_End)
		CloseHandle(menu);
	return;
}

public Menu_SwapMode(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
		new String:sSelection[64];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		decl String:sIndex[64];
		
		if (SplitString(sSelection, "A", sIndex, sizeof(sIndex)) == -1)
		{
			SplitString(sSelection, "B", sIndex, sizeof(sIndex));
		}
		
		new iTarget = StringToInt(sIndex);
		
		if (StrContains(sSelection, "A", true) != -1)
		{
			g_aPlayers[iTarget][bQueue] = false;
		}
		else if (StrContains(sSelection, "B", true) != -1)
		{
			g_aPlayers[iTarget][bQueue] = true;
		}
		
		if (param1 == iTarget && !g_aPlayers[iTarget][bQueue])
		{
			SM_MovePlayer(iTarget, g_aPlayers[iTarget][iNewTeam]);
		}
		else
		{
			DisplayForceModeMenu(param1, iTarget);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE && GetUserFlagBits(param1) & ADMFLAG_BAN) 
		{
			DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	return;
}

public Menu_ForceMode(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:sSelection[64];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		decl String:sIndex[64];
		if (SplitString(sSelection, "A", sIndex, sizeof(sIndex)) == -1)
		{
			SplitString(sSelection, "B", sIndex, sizeof(sIndex));
		}
		new iTarget = StringToInt(sIndex);
		if (StrContains(sSelection, "A", true) != -1)
		{
			SM_ClearForcedTeam(iTarget);
		}
		else if (StrContains(sSelection, "B", true) != -1)
		{
			SM_SetForcedTeam(iTarget, g_aPlayers[iTarget][iNewTeam], true);
		}
		if (!g_aPlayers[iTarget][bQueue])
		{
			SM_MovePlayer(iTarget, g_aPlayers[iTarget][iNewTeam]);
		}
	} 
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE && GetUserFlagBits(param1) & ADMFLAG_BAN)
		{
			DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	} 
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	return;
}

public Menu_VoteScramble(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_VoteEnd) {
		new winning_votes, total_votes;
		GetMenuVoteInfo(param2, winning_votes, total_votes);
		if (param1 == 0) {
			if (float(total_votes) / float(winning_votes) < g_fVoteWin) {
				PrintToChatAll("\x01\x04[SM]\x01 %T", "VoteScramble2", LANG_SERVER, winning_votes, total_votes);
				return;
			}
			PrintCenterTextAll("[SM] %T", "Scramble", LANG_SERVER);
			PrintToChatAll("\x01\x04[SM]\x01 %T", "VoteScramble1", LANG_SERVER, winning_votes, total_votes);
			StartScrambleTimer();
		}
		if (param1 == 1) {
			PrintToChatAll("\x01\x04[SM]\x01 %T", "VoteScramble2", LANG_SERVER, winning_votes, total_votes);
		}
	}
	if (action == MenuAction_End)
		CloseHandle(menu);
}

public Menu_ScrambleTeams(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		new String:sSelection[64];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "NOW", false))
			g_bScrambleRoundEnd = false;
		else
			g_bScrambleRoundEnd = true;
		DisplayScrambleMenu2(param1);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE && GetUserFlagBits(param1) & ADMFLAG_BAN)
			DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
	} else if (action == MenuAction_End)
		CloseHandle(menu);
	return;
}

public Menu_ScrambleTeams2(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		new String:sSelection[64];
		new bool:bRestartRound;
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "NO", false))
		{
			bRestartRound = false;
		}
		else
		{
			bRestartRound = true;
		}
		StartScrambleTimer(_, bRestartRound);
	} else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && g_hAdminMenu != INVALID_HANDLE && GetUserFlagBits(param1) & ADMFLAG_BAN)
			DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
	} else if (action == MenuAction_End)
		CloseHandle(menu);
	return;
}

stock DisplayScrambleMenu(iClient)
{
	new Handle:hMenu = CreateMenu(Menu_ScrambleTeams);
	SetMenuTitle(hMenu, "Select When to Scramble:");
	AddMenuItem(hMenu, "NOW", "Instantly");
	AddMenuItem(hMenu, "END", "At Round End");
	SetMenuExitBackButton(hMenu, false);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

stock DisplayScrambleMenu2(iClient)
{
	new Handle:hMenu = CreateMenu(Menu_ScrambleTeams2);
	SetMenuTitle(hMenu, "Select When to Scramble:");
	AddMenuItem(hMenu, "NO", "No Round Restart");
	AddMenuItem(hMenu, "YES", "Restart Round");
	SetMenuExitBackButton(hMenu, false);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

stock DisplaySwapModeMenu(iClient, iTarget)
{
	new Handle:hMenu = CreateMenu(Menu_SwapMode);
	decl String:optionA[64];
	decl String:optionB[64];
	Format(optionA, sizeof(optionA), "%iA", iTarget);
	Format(optionB, sizeof(optionB), "%iB", iTarget);
	SetMenuTitle(hMenu, "Select When to Swap:");
	AddMenuItem(hMenu, optionA, "Instantly (Kills)");
	if (!IsClientObserver(iTarget))
		AddMenuItem(hMenu, optionB, "Queue on next death");
	SetMenuExitBackButton(hMenu, false);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

stock DisplayForceModeMenu(iClient, iTarget)
{
	new Handle:hMenu = CreateMenu(Menu_ForceMode);
	decl String:optionA[64];
	decl String:optionB[64];
	Format(optionA, sizeof(optionA), "%iA", iTarget);
	Format(optionB, sizeof(optionB), "%iB", iTarget);
	SetMenuTitle(hMenu, "Select Force Mode:");
	AddMenuItem(hMenu, optionA, "UnForced");
	AddMenuItem(hMenu, optionB, "Forced");
	SetMenuExitBackButton(hMenu, false);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

stock DisplayTeamMenu(iClient, iTarget)
{
	new Handle:hMenu = CreateMenu(Menu_SelectTeam);
	decl String:optionA[64];
	decl String:optionB[64];
	decl String:optionC[64];
	Format(optionA, sizeof(optionA), "%iA", iTarget);
	Format(optionB, sizeof(optionB), "%iB", iTarget);
	Format(optionC, sizeof(optionC), "%iC", iTarget);
	SetMenuTitle(hMenu, "Select Team:");
	AddMenuItem(hMenu, optionA, "Team One");
	AddMenuItem(hMenu, optionB, "Team Two");
	AddMenuItem(hMenu, optionC, "Spectator");
	SetMenuExitBackButton(hMenu, false);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

stock DisplayPlayerMenu(iClient)
{
	new Handle:hMenu = CreateMenu(Menu_SelectPlayer);
	AddTargetsToMenu(hMenu, 0, true, false);
	SetMenuTitle(hMenu, "Select A Player:");
	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}
