/************************************************************************
*************************************************************************
Simple Plugins
Description:
	Included file for core plugin in the Simple Plugins project
*************************************************************************
*************************************************************************
This file is part of Simple Plugins project.

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
$Id: simple-plugins.inc 132 2010-01-25 03:30:42Z antithasys $
$Author: antithasys $
$Revision: 132 $
$Date: 2010-01-24 19:30:42 -0800 (Sun, 24 Jan 2010) $
$LastChangedBy: antithasys $
$LastChangedDate: 2010-01-24 19:30:42 -0800 (Sun, 24 Jan 2010) $
$URL: http://sm-simple-plugins.googlecode.com/svn/trunk/Simple%20Plugins%20Core/addons/sourcemod/scripting/include/simple-plugins.inc $
$Copyright: (c) Simple Plugins 2008-2009$
*************************************************************************
*************************************************************************/

#if defined _simpleplugin_included
  #endinput
#endif
#define _simpleplugin_included

#define CORE_INC_VERSION "1.1.$Rev: 132 $"

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#undef AUTOLOAD_EXTENSIONS
#include <simple-core-sm>
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

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
	MarkNativeAsOptional("SM_ClearAllForcedTeams");
	MarkNativeAsOptional("SM_AssignBuddy");
	MarkNativeAsOptional("SM_LockBuddy");
	MarkNativeAsOptional("SM_IsBuddyLocked");
	MarkNativeAsOptional("SM_IsBuddyTeamed");
	MarkNativeAsOptional("SM_ClearBuddy");
}
#endif

/**********************************************************************
 * When a player has to moved
 *
 * @param 		plugin		Plugin that initiated the move
 * @param 		client		The client index of the player that was moved
 * @param 		oldteam	The team index the player was on
 * @param 		newteam	The team index the player was moved to
 * @noreturn		
 **********************************************************************/
forward SM_OnPlayerMoved(Handle:plugin, client, oldteam, newteam);

/**********************************************************************
 * When a player has to moved
 *
 * @param 		plugin		Plugin that initiated the force
 * @param 		client		The client index of the player
 * @param 		team		The team index the player was forced to
 * @param 		time			The amount of time (seconds) the player was forced
 * @noreturn		
 **********************************************************************/
forward SM_OnClientTeamForced(Handle:plugin, client, team, Float:time);

/**********************************************************************
 * When a player has to moved
 *
 * @param 		plugin		Plugin that initiated the clear
 * @param 		client		The client index of the player
 * @noreturn		
 **********************************************************************/
forward SM_OnClientTeamForceCleared(Handle:plugin, client);

/**********************************************************************
 * Move a player to the supplied team
 *
 * @param 		client		The client index of the player to be moved
 * @param 		team		The team to move the player to
 * @param 		respawn	Repsawn the player
 * @noreturn
 * @error							Invalid client or team index
 **********************************************************************/
native SM_MovePlayer(client, team, bool:respawn = true);

/**********************************************************************
 * Move a player to the supplied team
 *
 * @param 		client		The client index of the player to set
 * @param 		team		The team to move the to set
 * @param 		time			The seconds to force the players team
 * @param 		override	Whether or not to override another plugin
 * @return						True if successful, false if not
 * @error							Invalid client or team index
 **********************************************************************/
native bool:SM_SetForcedTeam(client, team, Float:time, bool:override = false);

/**********************************************************************
 * Gets the client's forced team index
 *
 * @param 		client		The client index of the player to check
 * @param 		plugin		Optional: The plugin handle of the plugin
										that set the team
 * @return						The team index of the forced team
										Zero if no forced team
 * @error							Invalid client index
 **********************************************************************/
native SM_GetForcedTeam(client, &Handle:plugin = INVALID_HANDLE);

/**********************************************************************
 * Clears a client's forced team
 *
 * @param 		client		The client index of the player to check
 * @param 		override	Whether or not to override another plugin
 * @return						True if successful, false if not
 * @error							Invalid client index
 **********************************************************************/
native SM_ClearForcedTeam(client, bool:override = false);

/**********************************************************************
 * Clears a client's forced team
 *
 * @return						True if successful, false if not
 * @error							Invalid client index
 **********************************************************************/
native SM_ClearAllForcedTeams();

/**********************************************************************
 * Assign a players buddy
 *
 * @param 		client		The client index of the player to assign
 * @param 		player		The player index of the player to assign
 * @param 		override	Whether or not to override a player lock
 * @return						True if successful, false if not
 * @error							Invalid client or player index
 **********************************************************************/
native bool:SM_AssignBuddy(client, player, bool:override = false);

/**********************************************************************
 * Rturns the client's buddy
 *
 * @param 		client		The client index of the player to assign
 * @return						The client index of the player's buddy
										Zero if no buddy
 * @error							Invalid client index
 **********************************************************************/
native SM_GetClientBuddy(client);

/**********************************************************************
 * Set the buddy lock setting for a client
 *
 * @param 		client		The client index of the player to assign
 * @param 		setting		Setting to set, True or False
 * @return						True if successful, false if not
 * @error							Invalid client index
 **********************************************************************/
native bool:SM_LockBuddy(client, bool:setting);

/**********************************************************************
 * Returns the buddy lock setting for a client
 *
 * @param 		client		The client index of the player to assign
 * @return						True if locked, false if not
 * @error							Invalid client index
 **********************************************************************/
native bool:SM_IsBuddyLocked(client);

/**********************************************************************
 * Returns if the client is on the same team as his buddy
 *
 * @param 		client		The client index of the player to check
 * @return						True if on same team, false if not or no buddy assigned
 * @error							Invalid client index
 **********************************************************************/
native bool:SM_IsBuddyTeamed(client);

/**********************************************************************
 * Clear a players buddy
 *
 * @param 		client		The client index of the player to clear
 * @param 		override	Whether or not to override a player lock
 * @return						True if successful, false if not
 * @error							Invalid client index
 **********************************************************************/
native bool:SM_ClearBuddy(client, bool:override = false);
