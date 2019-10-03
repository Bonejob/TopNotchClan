/************************************************************************
*************************************************************************
Simple SourceMod Plugins
Description:
	Included file for core plugin in the Simple SourceMod Plugins project
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
$Id: simple-plugins.inc 74 2009-08-28 22:06:28Z antithasys $
$Author: antithasys $
$Revision: 74 $
$Date: 2009-08-28 17:06:28 -0500 (Fri, 28 Aug 2009) $
$LastChangedBy: antithasys $
$LastChangedDate: 2009-08-28 17:06:28 -0500 (Fri, 28 Aug 2009) $
$URL: http://projects.mygsn.net/svn/simple-plugins/trunk/simple-plugins/addons/sourcemod/scripting/include/simple-plugins.inc $
$Copyright: (c) Simple SourceMod Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/

#if defined _simpleplugin_included
  #endinput
#endif

#define _simpleplugin_included

#define CORE_INC_VERSION "1.0.$Revision: 74 $"

#pragma semicolon 1
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#undef AUTOLOAD_EXTENSIONS
#tryinclude <cstrike>
#tryinclude <tf2>
#tryinclude <tf2_stocks>
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

enum e_SupportedMods
{
	GameType_Unknown,
	GameType_CSS,
	GameType_DOD,
	GameType_TF,
	GameType_INS
};

enum e_Teams
{
	Unknown,
	Spectator,
	Team1,
	Team2
};

new g_aCurrentTeams[e_Teams];
new e_SupportedMods:g_CurrentMod;
new String:g_sGameName[e_SupportedMods][24] = {"Unknown", "Counter Strike", "Day Of Defeat", "Team Fortress 2", "Insurgency"};

public SharedPlugin:_pl_simpleplugin = 
{
	name = "simple-plugins",
	file = "simple-plugins.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public _pl_simpleplugin_SetNTVOptional()
{
	MarkNativeAsOptional("SM_MovePlayer");
	MarkNativeAsOptional("SM_SetForcedTeam");
	MarkNativeAsOptional("SM_GetForcedTeam");
	MarkNativeAsOptional("SM_ClearForcedTeam");
	MarkNativeAsOptional("SM_GetForcedPlayer");
	MarkNativeAsOptional("SM_AssignBuddy");
	MarkNativeAsOptional("SM_SearchBuddy");
	MarkNativeAsOptional("SM_LockBuddy");
	MarkNativeAsOptional("SM_IsBuddyLocked");
	MarkNativeAsOptional("SM_ClearBuddy");
	MarkNativeAsOptional("SM_IsValidAdmin");
	MarkNativeAsOptional("SM_IsValidTeam");
}
#endif

/**********************************************************************
 * When a player has to moved
 *
 * @param 		plugin		Plugin that initiated the move
 * @param 		client		The client index of the player that was moved
 * @param 		team		The team index the player was moved to
 * @noreturn		
 **********************************************************************/
forward SM_OnPlayerMoved(Handle:plugin, client, team);

/**********************************************************************
 * Move a player to the supplied team
 *
 * @param 		client		The client index of the player to be moved
 * @param 		team		The team to move the player to
 * @noreturn
 * @error					Invalid client or team index
 **********************************************************************/
native SM_MovePlayer(client, team);

/**********************************************************************
 * Move a player to the supplied team
 *
 * @param 		client		The client index of the player to set
 * @param 		team		The team to move the to set
 * @param 		override	Whether or not to override another plugin
 * @return					True if successful, false if not
 * @error					Invalid client or team index
 **********************************************************************/
native SM_SetForcedTeam(client, team, bool:override = false);

/**********************************************************************
 * Gets the client's forced team index
 *
 * @param 		client		The client index of the player to check
 * @param 		plugin		Optional: The plugin handle of the plugin
							that set the team
 * @return					The team index of the forced team
							Zero if no forced team
 * @error					Invalid client index
 **********************************************************************/
native SM_GetForcedTeam(client, &Handle:plugin = INVALID_HANDLE);

/**********************************************************************
 * Clears a client's forced team
 *
 * @param 		client		The client index of the player to check
 * @return					True if successful, false if not
 * @error					Invalid client index
 **********************************************************************/
native SM_ClearForcedTeam(client);

/**********************************************************************
 * Gets a forced player on the wrong that is currently on the wrong team
 * This will only return a player if the calling plugin assigned the team
 *
 * @param 		team		The team index the player should be on
 * @return					The client index of the player
							Zero if no player found
 * @error					Invalid client index
 **********************************************************************/
native SM_GetForcedPlayer(team);

/**********************************************************************
 * Assign a players buddy
 *
 * @param 		client		The client index of the player to assign
 * @param 		player		The player index of the player to assign
 * @param 		override	Whether or not to override a player lock
 * @return					True if successful, false if not
 * @error					Invalid client or player index
 **********************************************************************/
native bool:SM_AssignBuddy(client, player, bool:override = false);

/**********************************************************************
 * Rturns the client's buddy
 *
 * @param 		client		The client index of the player to assign
 * @return					The client index of the player's buddy
							Zero if no buddy
 * @error					Invalid client index
 **********************************************************************/
native SM_GetClientBuddy(client);

/**********************************************************************
 * Set the buddy lock setting for a client
 *
 * @param 		client		The client index of the player to assign
 * @param 		setting		Setting to set, True or False
 * @return					True if successful, false if not
 * @error					Invalid client index
 **********************************************************************/
native bool:SM_LockBuddy(client, bool:setting);

/**********************************************************************
 * Returns the buddy lock setting for a client
 *
 * @param 		client		The client index of the player to assign
 * @return					True if locked, false if not
 * @error					Invalid client index
 **********************************************************************/
native bool:SM_IsBuddyLocked(client);

/**********************************************************************
 * Clear a players buddy
 *
 * @param 		client		The client index of the player to clear
 * @param 		override	Whether or not to override a player lock
 * @return					True if successful, false if not
 * @error					Invalid client index
 **********************************************************************/
native bool:SM_ClearBuddy(client, bool:override = false);

/**********************************************************************
 * Determine if the player has the supplied flags
 * ADMFLAG_ROOT will always return true
 *
 * @param 		client		The client index of the player to assign
 * @param 		flags		The char flag(s) to check against
 * @return					True if valid, false if not
 **********************************************************************/
native bool:SM_IsValidAdmin(client, const String:flags[]);


/**********************************************************************
 * Determine if the team is a valid team
 *
 * @param 		team		The team index to determine if valid for
							currently installed/supported mod
 * @return					True if valid, false if not
 **********************************************************************/
native bool:SM_IsValidTeam(team);


public e_SupportedMods:GetCurrentMod()
{
	new String:sGameType[64];
	GetGameFolderName(sGameType, sizeof(sGameType));
	
	if (StrEqual(sGameType, "cstrike", false))
	{
		return GameType_CSS;
	}
	if (StrEqual(sGameType, "dod", false))
	{
		return GameType_DOD;
	}
	if (StrEqual(sGameType, "tf", false))
	{
		return GameType_TF;
	}
	if (StrEqual(sGameType, "insurgency", false))
	{
		return GameType_INS;
	}
	return GameType_Unknown;
}

public LoadCurrentTeams()
{
	switch (g_CurrentMod)
	{
		case GameType_CSS:
		{
			g_aCurrentTeams[Unknown] = 0;
			g_aCurrentTeams[Spectator] = 1;
			g_aCurrentTeams[Team1] = 2;
			g_aCurrentTeams[Team2] = 3;
		}
		case GameType_DOD:
		{
			g_aCurrentTeams[Unknown] = 0;
			g_aCurrentTeams[Spectator] = 1;
			g_aCurrentTeams[Team1] = 2;
			g_aCurrentTeams[Team2] = 3;
		}
		case GameType_TF:
		{
			g_aCurrentTeams[Unknown] = 0;
			g_aCurrentTeams[Spectator] = 1;
			g_aCurrentTeams[Team1] = 2;
			g_aCurrentTeams[Team2] = 3;
		}
		case GameType_INS:
		{
			g_aCurrentTeams[Unknown] = 0;
			g_aCurrentTeams[Spectator] = 3;
			g_aCurrentTeams[Team1] = 1;
			g_aCurrentTeams[Team2] = 2;
		}
		case GameType_Unknown:
		{
			g_aCurrentTeams[Unknown] = 0;
			g_aCurrentTeams[Spectator] = 1;
			g_aCurrentTeams[Team1] = 2;
			g_aCurrentTeams[Team2] = 3;
		}
	}
}
