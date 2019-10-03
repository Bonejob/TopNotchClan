/************************************************************************
*************************************************************************
gScramble
Description:
	Included file for gScrabmle plugin
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
$Id: gscramble.inc 21 2009-07-29 00:47:22Z antithasys $
$Author: antithasys $
$Revision: 21 $
$Date: 2009-07-28 17:47:22 -0700 (Tue, 28 Jul 2009) $
$LastChangedBy: antithasys $
$LastChangedDate: 2009-07-28 17:47:22 -0700 (Tue, 28 Jul 2009) $
$URL: http://projects.mygsn.net/svn/simple-plugins/trunk/gScramble/addons/sourcemod/scripting/include/gscramble.inc $
$Copyright: (c) Simple SourceMod Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/

#if defined _gscramble_included
  #endinput
#endif

#define _gscramble_included

public SharedPlugin:_pl_gscramble = 
{
	name = "gscramble",
	file = "gscramble.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

public _pl_gscramble_SetNTVOptional()
{
	MarkNativeAsOptional("GS_IsBlocked");
}

/**
 * Checks if team swap on a client should be blocked
 *
 * @param client   Client index.
 * @param init	   Who is initiating the team swap. 0 for server, 1 for client. if client, then it gives them a warning message
 * @return         True if blocked, false if not.
 * @errors         Invalid client index. Bots are not supported
 */
native bool:GS_IsBlocked(client, init);