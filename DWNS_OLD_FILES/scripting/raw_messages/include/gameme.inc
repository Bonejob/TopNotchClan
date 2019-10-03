/**
 * gameME Plugin
 * http://www.gameme.com
 * Copyright (C) 2007-2011 TTS Oetzel & Goerz GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */


#if defined _gameme_included_
  #endinput
#endif
#define _gameme_included_


// raw message handling
#define RAW_MESSAGE_RANK				1
#define RAW_MESSAGE_PLACE				2
#define RAW_MESSAGE_KDEATH				3
#define RAW_MESSAGE_SESSION_DATA		4
#define RAW_MESSAGE_TOP10				5
#define RAW_MESSAGE_NEXT				6

// callbacks
#define RAW_MESSAGE_CALLBACK_PLAYER		101
#define RAW_MESSAGE_CALLBACK_TOP10		102
#define RAW_MESSAGE_CALLBACK_NEXT		103


forward onGameMEStatsRank(command, client, const String: message_prefix[], const total_cell_values[], const Float: total_float_values[], const session_cell_values[], const Float: session_float_values[], const String: session_fav_weapon[], const global_cell_values[], const Float: global_float_values[], const String: country_code[]);
forward onGameMEStatsPublicCommand(command, client, const String: message_prefix[], const total_cell_values[], const Float: total_float_values[], const session_cell_values[], const Float: session_float_values[], const String: session_fav_weapon[], const global_cell_values[], const Float: global_float_values[], const String: country_code[]);
forward onGameMEStatsTop10(command, client, const String: message_prefix[], const top10_cell_values[], const Float: top10_float_values[], const String: player1[], const String: player2[], const String: player3[], const String: player4[], const String: player5[], const String: player6[], const String: player7[], const String: player8[], const String: player9[], const String: player10[]);
forward onGameMEStatsNext(command, client, const String: message_prefix[], const next_cell_values[], const Float: next_float_values[], const String: player1[], const String: player2[], const String: player3[], const String: player4[], const String: player5[], const String: player6[], const String: player7[], const String: player8[], const String: player9[], const String: player10[]);


functag gameMEStatsCallback public(command, payload, client, const total_cell_values[], const Float: total_float_values[], const session_cell_values[], const Float: session_float_values[], const String: session_fav_weapon[], const global_cell_values[], const Float: global_float_values[], const String: country_code[]);

/**
 * Query gameME Stats data from a client
 * 
 * @param request		Request type (only 'playerinfo' available)
 * @param client		Client index.
 * @param func			Callback function.
 * @param payload		Payload to distinct queries.
 * @noreturn
 */
native QueryGameMEStats(String: request[], client, gameMEStatsCallback: callback, payload = 0);


functag gameMEStatsTop10Callback public(command, payload, const top10_cell_values[], const Float: top10_float_values[], const String: player1[], const String: player2[], const String: player3[], const String: player4[], const String: player5[], const String: player6[], const String: player7[], const String: player8[], const String: player9[], const String: player10[]);

/**
 * Query Top10 players from gameME Stats
 * 
 * @param request		Request type (currently only 'top10' available)
 * @param client		Client index.
 * @param func			Callback function.
 * @param payload		Payload to distinct queries.
 * @noreturn
 */
native QueryGameMEStatsTop10(String: request[], client, gameMEStatsTop10Callback: callback, payload = 0);


functag gameMEStatsNextCallback public(command, payload, client, const next_cell_values[], const Float: next_float_values[], const String: player1[], const String: player2[], const String: player3[], const String: player4[], const String: player5[], const String: player6[], const String: player7[], const String: player8[], const String: player9[], const String: player10[]);

/**
 * Query next players from gameME Stats for s specified client
 * 
 * @param request		Request type (currently only 'next' available)
 * @param client		Client index.
 * @param func			Callback function.
 * @param payload		Payload to distinct queries.
 * @noreturn
 */
native QueryGameMEStatsNext(String: request[], client, gameMEStatsNextCallback: callback, payload = 0);


functag gameMEStatsIntCallback public(command, payload, caller[MAXPLAYERS + 1], target[MAXPLAYERS + 1], const String: message_prefix[], const String: message[]);

/**
 * Query internal (preformatted) gameME Stats data
 * 
 * @param request		Request type.
 * @param client		Client index.
 * @param func			Callback function.
 * @param payload		Payload to distinct queries.
 * @noreturn
 */
native QueryIntGameMEStats(String: request[], client, gameMEStatsIntCallback: callback, payload = 0, limit = 0);


/**
 * Display internal gameME Stats menu.
 *
 * @param client    	The client index the menu is displayed to.
 * @param time    		How long should the menu be displayed.
 * @param message    	The menu message.
 * @param need_handler  Define, if a menu handler is needed.
 * @noreturn
 */
native DisplayGameMEStatsMenu(client, time, String: message[], need_handler); 


/**
 * Color all player names in a string
 *
 * @param message	String with player names.
 * @return        	The color index for the message
 */
native gameMEStatsColorAllPlayers(String: message[]); 


public SharedPlugin:__gameme = 
{
	name = "gameme",
	file = "gameme.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};