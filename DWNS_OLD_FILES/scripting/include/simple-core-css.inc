/************************************************************************
*************************************************************************
Simple Plugins L4D Core Include File
Description:
	Core Left 4 Dead 1/2 include file for the Simple Plugins project.
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
$Id: simple-core-css.inc 132 2010-01-25 03:30:42Z antithasys $
$Author: antithasys $
$Revision: 132 $
$Date: 2010-01-24 19:30:42 -0800 (Sun, 24 Jan 2010) $
$LastChangedBy: antithasys $
$LastChangedDate: 2010-01-24 19:30:42 -0800 (Sun, 24 Jan 2010) $
$URL: http://sm-simple-plugins.googlecode.com/svn/trunk/Simple%20Plugins%20Core/addons/sourcemod/scripting/include/simple-core-css.inc $
$Copyright: (c) Simple Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/
#if defined _simple_core_css_included
	#endinput
#endif

#define _simple_core_css_included

#tryinclude <cstrike>

#define CORE_CSS_INC_VERSION "0.1.$Rev: 132 $"

enum e_CSSGameType
{
	CSSGameMode_Unknown,

};

stock e_CSSGameType:CSS_GetGameType()
{	
	new Handle:hGameMode = FindConVar("mp_gamemode");
	new String:sGameMode[32];
	GetConVarString(hGameMode, sGameMode, sizeof(sGameMode));
	
	if (StrEqual(sGameMode, "coop", false))
	{
		return L4DGameMode_Coop;
	}
	else if (StrEqual(sGameMode, "versus", false))
	{
		return L4DGameMode_Versus;
	}
	
	return CSSGameMode_Unknown;
}