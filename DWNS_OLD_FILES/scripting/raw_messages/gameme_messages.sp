/**
 * gameME Plugin - Raw Messages Interface
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
 *
 *
 * This file demonstrates the access to the raw message
 * interface of gameME Stats. Documentation is available
 * at http://www.gameme.com/docs/api/rawmessages
 *  
 */

#pragma semicolon 1
#include <sourcemod>
#include <gameme>


// plugin information
#define GAMEME_MESSAGES_PLUGIN_VERSION "1.0"
public Plugin:myinfo = {
	name = "gameME Raw Message Plugin",
	author = "TTS Oetzel & Goerz GmbH",
	description = "gameME Plugin",
	version = GAMEME_MESSAGES_PLUGIN_VERSION,
	url = "http://www.gameme.com"
};


/* Example to define query contants to be able to distinct gameME Stats queries. The
 * payload is given as cell on query function call
 */
 
#define QUERY_TYPE_OTHER				0
#define QUERY_TYPE_ONCLIENTPUTINSERVER	1


public OnPluginStart() 
{
	LogToGame("gameME Raw Messages Plugin %s (http://www.gameme.com), copyright (c) 2007-2011 by TTS Oetzel & Goerz GmbH", GAMEME_MESSAGES_PLUGIN_VERSION);

	// QueryGameMEStatsTop10("top10", -1, QuerygameMEStatsTop10Callback);
}


public OnClientPutInServer(client)
{
	// example on how to retrieve data from gameME Stats if player put in server
	if (client > 0) {
		if (!IsFakeClient(client)) {
			// QueryGameMEStats("playerinfo", client, QuerygameMEStatsCallback, QUERY_TYPE_ONCLIENTPUTINSERVER);
			// QueryGameMEStatsNext("next", client, QuerygameMEStatsNextCallback);
		}
	}
}


public QuerygameMEStatsCallback(command, payload, client, const total_cell_values[], const Float: total_float_values[], const session_cell_values[], const Float: session_float_values[], const String: session_fav_weapon[], const global_cell_values[], const Float: global_float_values[], const String: country_code[])
{
	if ((client > 0) && (command == RAW_MESSAGE_CALLBACK_PLAYER)) {

		// total values
		new rank            = total_cell_values[0];	
		// new players         = total_cell_values[1];	
		new skill           = total_cell_values[2];	
		// new kills           = total_cell_values[3];	
		// new deaths          = total_cell_values[4];	
		// new suicides        = total_cell_values[5];
		// new headshots       = total_cell_values[6];
		// new connection_time = total_cell_values[7];
		// new kill_assists    = total_cell_values[8];
		// new kills_assisted  = total_cell_values[9];
		// new points_healed   = total_cell_values[10];
		// new flags_captured  = total_cell_values[11];
		// new Float: kpd      = total_float_values[0];
		// new Float: hpk      = total_float_values[1];
		// new Float: accuracy = total_float_values[2];

		// session values
		// new session_pos_change      = session_cell_values[0];
		// new session_skill_change    = session_cell_values[1];
		// new session_kills           = session_cell_values[2];
		// new session_deaths          = session_cell_values[3];
		// new session_suicides        = session_cell_values[4];
		// new session_headshots       = session_cell_values[5];
		// new session_time            = session_cell_values[6];
		// new session_kill_assists    = session_cell_values[7];
		// new session_kills_assisted  = session_cell_values[8];
		// new session_points_healed   = session_cell_values[9];
		// new session_flags_captured  = session_cell_values[10];
		// new Float: session_kpd      = session_float_values[0];
		// new Float: session_hpk 		= session_float_values[1];
		// new Float: session_accuracy = session_float_values[2];

		// global values
		// new global_rank       = global_cell_values[0];
		// new global_players    = global_cell_values[1];
		// new global_kills      = global_cell_values[2];
		// new global_deaths     = global_cell_values[3];
		// new global_headshots  = global_cell_values[4];
		// new Float: global_kpd = global_float_values[0];
		// new Float: global_hpk = global_float_values[1];

		// only write this message to gameserver log if client has connected
		if (payload == QUERY_TYPE_ONCLIENTPUTINSERVER) {
			LogToGame("Player %L is on rank %d with %d points", client, rank, skill);
		}
	}
}


public QuerygameMEStatsTop10Callback(command, payload, const top10_cell_values[], const Float: top10_float_values[], const String: player1[], const String: player2[], const String: player3[], const String: player4[], const String: player5[], const String: player6[], const String: player7[], const String: player8[], const String: player9[], const String: player10[])
{
	if ((command == RAW_MESSAGE_CALLBACK_TOP10)) {

		if (top10_cell_values[0] == -1) {
			LogToGame("-----------------------------------------------------------");
			LogToGame("No Players ranked");
			LogToGame("-----------------------------------------------------------");
		} else {
			LogToGame("-----------------------------------------------------------");
			LogToGame("Current Top10-Players");
			for (new i = 0; (i < 10); i++) {
				if (top10_cell_values[(i * 2)] > 0) {
					new rank = top10_cell_values[(i * 2)];
					new skill = top10_cell_values[((i * 2) + 1)];
					// new Float: kpd = top10_float_values[(i * 2)];
					// new Float: hpk = top10_float_values[((i * 2) + 1)];

					new String: name[32];
					switch (i) {
						case 0:
							strcopy(name, 32, player1);
						case 1:
							strcopy(name, 32, player2);
						case 2:
							strcopy(name, 32, player3);
						case 3:
							strcopy(name, 32, player4);
						case 4:
							strcopy(name, 32, player5);
						case 5:
							strcopy(name, 32, player6);
						case 6:
							strcopy(name, 32, player7);
						case 7:
							strcopy(name, 32, player8);
						case 8:
							strcopy(name, 32, player9);
						case 9:
							strcopy(name, 32, player10);
					}

					LogToGame("%02d  %d  %s", rank, skill, name);
				}
			}
			LogToGame("-----------------------------------------------------------");
		}
	}
}


public QuerygameMEStatsNextCallback(command, payload, client, const next_cell_values[], const Float: next_float_values[], const String: player1[], const String: player2[], const String: player3[], const String: player4[], const String: player5[], const String: player6[], const String: player7[], const String: player8[], const String: player9[], const String: player10[])
{
	if ((client > 0) && (command == RAW_MESSAGE_CALLBACK_NEXT)) {

		if (next_cell_values[0] == -1) {
			LogToGame("-----------------------------------------------------------");
			LogToGame("No next players available");
			LogToGame("-----------------------------------------------------------");
		} else {
			LogToGame("-----------------------------------------------------------");
			LogToGame("Next players for %L", client);

			new prev_skill = -1;
			for (new i = 0; (i < 10); i++) {
				if (next_cell_values[(i * 2)] > 0) {
					new rank = next_cell_values[(i * 2)];
					new skill = next_cell_values[((i * 2) + 1)];
					// new Float: kpd = next_float_values[(i * 2)];
					// new Float: hpk = next_float_values[((i * 2) + 1)];

					new String: name[32];
					switch (i) {
						case 0:
							strcopy(name, 32, player1);
						case 1:
							strcopy(name, 32, player2);
						case 2:
							strcopy(name, 32, player3);
						case 3:
							strcopy(name, 32, player4);
						case 4:
							strcopy(name, 32, player5);
						case 5:
							strcopy(name, 32, player6);
						case 6:
							strcopy(name, 32, player7);
						case 7:
							strcopy(name, 32, player8);
						case 8:
							strcopy(name, 32, player9);
						case 9:
							strcopy(name, 32, player10);
					}

					new diff  = -1;
					if (prev_skill > -1) {
						diff  = skill - prev_skill;
					}

					if (i == 0) {
						LogToGame("%02d  %d  -  %s", rank, skill, name);
					} else {
						LogToGame("%02d  %d  +%04d  %s", rank, skill, diff, name);
					}
					prev_skill = skill;
				}
			}
			LogToGame("-----------------------------------------------------------");
		}
	}
}


// helper function to format timestamps
format_time(timestamp, String: formatted_time[192]) {
	Format(formatted_time, 192, "%dd %02d:%02d:%02dh", timestamp / 86400, timestamp / 3600 % 24, timestamp / 60 % 60, timestamp % 60);
}


public onGameMEStatsRank(command, client, const String: message_prefix[], const total_cell_values[], const Float: total_float_values[], const session_cell_values[], const Float: session_float_values[], const String: session_fav_weapon[], const global_cell_values[], const Float: global_float_values[], const String: country_code[])
{
	if ((client > 0) && (command == RAW_MESSAGE_RANK)) {
		new time = 15;
		new need_handler = 0;
		
		// total values
		new rank            = total_cell_values[0];	
		new players         = total_cell_values[1];	
		new skill           = total_cell_values[2];	
		new kills           = total_cell_values[3];	
		new deaths          = total_cell_values[4];	
		// new suicides        = total_cell_values[5];
		new headshots       = total_cell_values[6];
		new connection_time = total_cell_values[7];
		// new kill_assists    = total_cell_values[8];
		// new kills_assisted  = total_cell_values[9];
		// new points_healed   = total_cell_values[10];
		// new flags_captured  = total_cell_values[11];
		new Float: kpd      = total_float_values[0];
		new Float: hpk      = total_float_values[1];
		new Float: accuracy = total_float_values[2];

		// session values
		new session_pos_change      = session_cell_values[0];
		new session_skill_change    = session_cell_values[1];
		new session_kills           = session_cell_values[2];
		new session_deaths          = session_cell_values[3];
		// new session_suicides        = session_cell_values[4];
		new session_headshots       = session_cell_values[5];
		new session_time            = session_cell_values[6];
		// new session_kill_assists    = session_cell_values[7];
		// new session_kills_assisted  = session_cell_values[8];
		// new session_points_healed   = session_cell_values[9];
		// new session_flags_captured  = session_cell_values[10];
		new Float: session_kpd      = session_float_values[0];
		new Float: session_hpk 		= session_float_values[1];
		new Float: session_accuracy = session_float_values[2];

		// global values
		new global_rank       = global_cell_values[0];
		new global_players    = global_cell_values[1];
		new global_kills      = global_cell_values[2];
		new global_deaths     = global_cell_values[3];
		new global_headshots  = global_cell_values[4];
		new Float: global_kpd = global_float_values[0];
		new Float: global_hpk = global_float_values[1];


		decl String: formatted_time[192];
		format_time(connection_time, formatted_time);
		decl String: formatted_session_time[192];
		format_time(session_time, formatted_session_time);
		
		new String: message[1024];
		if (rank < 1) {
			Format(message, 1024, "Not yet available");
		} else {
			// total
			decl String: total_message[512];
			Format(total_message, 512, "->1 - Total\\n   Position %d of %d\\n   %d Points\\n   %d:%d Frags (%.2f)\\n   %d (%.0f%%) Headshots\\n   %.0f%% Accuracy\\n   Time %s\\n\\n",
				rank, players, skill, kills, deaths, kpd, headshots, hpk * 100, accuracy * 100, formatted_time);
			strcopy(message[strlen(message)], 512, total_message);

			// session
			decl String: session_message[512];
			Format(session_message, 512, "->2 - Session\\n   %d Positions\\n   %d Points\\n   %d:%d Frags (%.2f)\\n   %d (%.0f%%) Headshots\\n   %.0f%% Accuracy\\n   %s\\n   Time %s\\n",
				session_pos_change, session_skill_change, session_kills, session_deaths, session_kpd, session_headshots, session_hpk * 100, session_accuracy * 100, session_fav_weapon, formatted_session_time);
			strcopy(message[strlen(message)], 512, session_message);

			// global
			if (global_rank < 1) {
				decl String: global_message[512];
				Format(global_message, 512, "%s", "->3 - Global\\n   Not yet available");
				strcopy(message[strlen(message)], 512, global_message);
			} else {
				decl String: global_message[512];
				Format(global_message, 512, "->3 - Global\\n   Position %d of %d\\n   %d Points\\n   %d:%d Frags (%.2f)\\n%   %d (%.0f%%) Headshots",
					global_rank, global_players, global_kills, global_deaths, global_kpd, global_headshots, global_hpk * 100);
				strcopy(message[strlen(message)], 512, global_message);
			}
		}

		if ((!IsFakeClient(client)) && (IsClientConnected(client)) && (IsClientInGame(client))) {
			DisplayGameMEStatsMenu(client, time, message, need_handler);			
		}
	}
}


public onGameMEStatsPublicCommand(command, client, const String: message_prefix[], const total_cell_values[], const Float: total_float_values[], const session_cell_values[], const Float: session_float_values[], const String: session_fav_weapon[], const global_cell_values[], const Float: global_float_values[], const String: country_code[])
{
	new colored_messages = 1;
	new color_index = -1;

	if ((client > 0) && ((command == RAW_MESSAGE_PLACE) || (command == RAW_MESSAGE_KDEATH) || (command == RAW_MESSAGE_SESSION_DATA))) {

		// total values
		new rank            = total_cell_values[0];	
		new players         = total_cell_values[1];	
		new skill           = total_cell_values[2];	
		new kills           = total_cell_values[3];	
		new deaths          = total_cell_values[4];	
		// new suicides        = total_cell_values[5];
		new headshots       = total_cell_values[6];
		// new connection_time = total_cell_values[7];
		// new kill_assists    = total_cell_values[8];
		// new kills_assisted  = total_cell_values[9];
		// new points_healed   = total_cell_values[10];
		// new flags_captured  = total_cell_values[11];
		new Float: kpd      = total_float_values[0];
		new Float: hpk      = total_float_values[1];
		// new Float: accuracy = total_float_values[2];

		// session values
		// new session_pos_change      = session_cell_values[0];
		new session_skill_change    = session_cell_values[1];
		new session_kills           = session_cell_values[2];
		new session_deaths          = session_cell_values[3];
		// new session_suicides        = session_cell_values[4];
		new session_headshots       = session_cell_values[5];
		// new session_time            = session_cell_values[6];
		// new session_kill_assists    = session_cell_values[7];
		// new session_kills_assisted  = session_cell_values[8];
		// new session_points_healed   = session_cell_values[9];
		// new session_flags_captured  = session_cell_values[10];
		new Float: session_kpd      = session_float_values[0];
		new Float: session_hpk 		= session_float_values[1];
		// new Float: session_accuracy = session_float_values[2];

		// global values
		// new global_rank       = global_cell_values[0];
		// new global_players    = global_cell_values[1];
		// new global_kills      = global_cell_values[2];
		// new global_deaths     = global_cell_values[3];
		// new global_headshots  = global_cell_values[4];
		// new Float: global_kpd = global_float_values[0];
		// new Float: global_hpk = global_float_values[1];

		decl String: client_message[192];
		switch (command) {
			case RAW_MESSAGE_PLACE: 
				Format(client_message, 192, "%N is on rank %d of %d with %d points", client, rank, players, skill);
			case RAW_MESSAGE_KDEATH: 
				Format(client_message, 192, "%N has %d:%d (%.2f) kills with %d (%.2f) headshots", client, kills, deaths, kpd, headshots, hpk);
			case RAW_MESSAGE_SESSION_DATA:
				Format(client_message, 192, "%N has %d:%d (%.2f) kills, %d (%.2f) headshots, %d skill change", client, session_kills, session_deaths, session_kpd, session_headshots, session_hpk, session_skill_change);
		}
			

		if (colored_messages > 0) {
			color_index = gameMEStatsColorAllPlayers(client_message);
			if (color_index == -1) {
				color_index = client;
			}
		}

		decl String: message[192];
		if (strcmp(message_prefix, "") == 0) {
			Format(message, 192, "\x01%s", client_message);
		} else {
			Format(message, 192, "\x04%s\x01 %s", message_prefix, client_message);
		}

		// display message
		if ((!IsFakeClient(client)) && (IsClientConnected(client)) && (IsClientInGame(client))) {
			if (colored_messages > 0) {
				new Handle:hBf;
				hBf = StartMessageAll("SayText2");
				if (hBf != INVALID_HANDLE) {
					BfWriteByte(hBf, color_index); 
					BfWriteByte(hBf, 0); 
					BfWriteString(hBf, message);
					EndMessage();
				}
			} else {
				PrintToChatAll(message);
			}
		}
	}
}


public onGameMEStatsTop10(command, client, const String: message_prefix[], const top10_cell_values[], const Float: top10_float_values[], const String: player1[], const String: player2[], const String: player3[], const String: player4[], const String: player5[], const String: player6[], const String: player7[], const String: player8[], const String: player9[], const String: player10[])
{
	if ((client > 0) && (command == RAW_MESSAGE_TOP10)) {
		new time = 15;
		new need_handler = 0;

		new String: message[1024];
		if (top10_cell_values[0] == -1) {
			Format(message, 1024, "->1 - Top Players\\n   Not yet available");
		} else {
			decl String: start_message[192];
			Format(start_message, 192, "->1 - Top Players\\n");
			strcopy(message[strlen(message)], 192, start_message);
	
			for (new i = 0; (i < 10); i++) {
				if (top10_cell_values[(i * 2)] > 0) {
					new rank = top10_cell_values[(i * 2)];
					new skill = top10_cell_values[((i * 2) + 1)];
					// new Float: kpd = top10_float_values[(i * 2)];
					// new Float: hpk = top10_float_values[((i * 2) + 1)];

					new String: name[32];
					switch (i) {
						case 0:
							strcopy(name, 32, player1);
						case 1:
							strcopy(name, 32, player2);
						case 2:
							strcopy(name, 32, player3);
						case 3:
							strcopy(name, 32, player4);
						case 4:
							strcopy(name, 32, player5);
						case 5:
							strcopy(name, 32, player6);
						case 6:
							strcopy(name, 32, player7);
						case 7:
							strcopy(name, 32, player8);
						case 8:
							strcopy(name, 32, player9);
						case 9:
							strcopy(name, 32, player10);
					}

					decl String: entry_message[192];
					Format(entry_message, 192, "   %02d  %d  %s\\n", rank, skill, name);
					strcopy(message[strlen(message)], 192, entry_message);
				}
			}
		}
		
		if ((!IsFakeClient(client)) && (IsClientConnected(client)) && (IsClientInGame(client))) {
			DisplayGameMEStatsMenu(client, time, message, need_handler);			
		}
	}
}


public onGameMEStatsNext(command, client, const String: message_prefix[], const next_cell_values[], const Float: next_float_values[], const String: player1[], const String: player2[], const String: player3[], const String: player4[], const String: player5[], const String: player6[], const String: player7[], const String: player8[], const String: player9[], const String: player10[])
{
	if ((client > 0) && (command == RAW_MESSAGE_NEXT)) {
		new time = 15;
		new need_handler = 0;

		new String: message[1024];
		if (next_cell_values[0] == -1) {
			Format(message, 1024, "->1 - Next Players\\n   Not yet available");
		} else {
			decl String: start_message[192];
			Format(start_message, 192, "->1 - Next Players\\n");
			strcopy(message[strlen(message)], 192, start_message);
	
			new prev_skill = -1;
			for (new i = 0; (i < 10); i++) {
				if (next_cell_values[(i * 2)] > 0) {
					new rank = next_cell_values[(i * 2)];
					new skill = next_cell_values[((i * 2) + 1)];
					// new Float: kpd = next_float_values[(i * 2)];
					// new Float: hpk = next_float_values[((i * 2) + 1)];

					new String: name[32];
					switch (i) {
						case 0:
							strcopy(name, 32, player1);
						case 1:
							strcopy(name, 32, player2);
						case 2:
							strcopy(name, 32, player3);
						case 3:
							strcopy(name, 32, player4);
						case 4:
							strcopy(name, 32, player5);
						case 5:
							strcopy(name, 32, player6);
						case 6:
							strcopy(name, 32, player7);
						case 7:
							strcopy(name, 32, player8);
						case 8:
							strcopy(name, 32, player9);
						case 9:
							strcopy(name, 32, player10);
					}

					new diff  = -1;
					if (prev_skill > -1) {
						diff  = skill - prev_skill;
					}

					decl String: entry_message[192];
					if (i == 0) {
						Format(entry_message, 192, "   %02d  %d       -      %s\\n", rank, skill, name);
						strcopy(message[strlen(message)], 192, entry_message);
					} else {
						Format(entry_message, 192, "   %02d  %d  +%04d  %s\\n", rank, skill, diff, name);
						strcopy(message[strlen(message)], 192, entry_message);
					}
					prev_skill = skill;

				}
			}
		}
		
		if ((!IsFakeClient(client)) && (IsClientConnected(client)) && (IsClientInGame(client))) {
			DisplayGameMEStatsMenu(client, time, message, need_handler);			
		}
	}
}
