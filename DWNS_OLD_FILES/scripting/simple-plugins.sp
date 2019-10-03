/************************************************************************
*************************************************************************
Simple Plugins
Description:
	Core plugin for Simple Plugins project
	This plugin is designed to manage a players team across multipule plugins
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
$Id: simple-plugins.sp 137 2010-04-12 22:23:25Z antithasys $
$Author: antithasys $
$Revision: 137 $
$Date: 2010-04-12 15:23:25 -0700 (Mon, 12 Apr 2010) $
$LastChangedBy: antithasys $
$LastChangedDate: 2010-04-12 15:23:25 -0700 (Mon, 12 Apr 2010) $
$URL: http://sm-simple-plugins.googlecode.com/svn/trunk/Simple%20Plugins%20Core/addons/sourcemod/scripting/simple-plugins.sp $
$Copyright: (c) Simple Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD

#define CORE_PLUGIN_VERSION "1.1.$Rev: 137 $"

#include <simple-plugins>

enum	e_PlayerStruct
{
	Handle:	hForcedTeamPlugin,
					iForcedTeam,
	Handle:	hForcedTeamTimer,
	Float:	fForcedTime,
					iBuddyPair,
	bool:		bBuddyLocked
};

new 	Handle:g_fwdPlayerMoved;
new 	Handle:g_fwdOnClientTeamForced;
new 	Handle:g_fwdOnClientTeamForceCleared;

new 	g_aPlayers[MAXPLAYERS + 1][e_PlayerStruct];

new 	bool:g_bTeamsSwitched = false;

/**
Setting our plugin information.
*/
public Plugin:myinfo =
{
	name = "Simple Plugins Core Plugin",
	author = "Simple Plugins",
	description = "Core plugin for Simple Plugins",
	version = CORE_PLUGIN_VERSION,
	url = "http://www.simple-plugins.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{

	/**
	Register natives for other plugins
	*/
	CreateNative("SM_MovePlayer", Native_SM_MovePlayer);
	CreateNative("SM_SetForcedTeam", Native_SM_SetForcedTeam);
	CreateNative("SM_GetForcedTeam", Native_SM_GetForcedTeam);
	CreateNative("SM_ClearForcedTeam", Native_SM_ClearForcedTeam);
	CreateNative("SM_ClearAllForcedTeams", Native_SM_ClearAllForcedTeams);
	CreateNative("SM_AssignBuddy", Native_SM_AssignBuddy);
	CreateNative("SM_GetClientBuddy", Native_SM_GetClientBuddy);
	CreateNative("SM_LockBuddy", Native_SM_LockBuddy);
	CreateNative("SM_IsBuddyLocked", Native_SM_IsBuddyLocked);
	CreateNative("SM_IsBuddyTeamed", Native_SM_IsBuddyTeamed);
	CreateNative("SM_ClearBuddy", Native_SM_ClearBuddy);
	RegPluginLibrary("simpleplugins");
	return APLRes_Success;
}

public OnPluginStart()
{
	
	CreateConVar("ssm_core_pl_ver", CORE_PLUGIN_VERSION, "Simple Plugins Core Plugin Version", CVAR_FLAGS);
	CreateConVar("ssm_core_inc_ver", CORE_INC_VERSION, "Simple Plugins Core Include Version", CVAR_FLAGS);
	CreateConVar("ssm_core_sm_ver", CORE_SM_INC_VERSION, "Simple Plugins Core SM Include Version", CVAR_FLAGS);
	CreateConVar("ssm_core_tf2_ver", CORE_TF2_INC_VERSION, "Simple Plugins Core TF2 Include Version", CVAR_FLAGS);
	CreateConVar("ssm_core_l4d_ver", CORE_L4D_INC_VERSION, "Simple Plugins Core L4D Include Version", CVAR_FLAGS);
	
	/**
	Get game type and load the team numbers
	*/
	g_CurrentMod = GetCurrentMod();
	LoadCurrentTeams();
	
	/**
	Hook some events to control forced players and check extensions
	*/
	LogMessage("[SPC] Hooking events for [%s].", g_sGameName[g_CurrentMod]);
	HookEvent("player_team", HookPlayerChangeTeam, EventHookMode_Pre);
	switch (g_CurrentMod)
	{
		case GameType_CSS:
		{
			HookEvent("round_start", HookRoundStart, EventHookMode_PostNoCopy);
			HookEvent("round_end", HookRoundEnd, EventHookMode_PostNoCopy);
			CheckExtStatus("game.cstrike.ext", true, true);
		}
		case GameType_TF:
		{
			HookEvent("teamplay_round_start", HookRoundStart, EventHookMode_PostNoCopy);
			HookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_PostNoCopy);
			HookUserMessage(GetUserMessageId("TextMsg"), UserMessageHook_Class, true);
			CheckExtStatus("game.tf2.ext", true, true);
		}
		case GameType_DOD:
		{
			HookEvent("dod_round_start", HookRoundStart, EventHookMode_PostNoCopy);
			HookEvent("dod_round_win", HookRoundEnd, EventHookMode_PostNoCopy);
		}
		case GameType_INS:
		{
			HookEvent("round_end", HookRoundEnd, EventHookMode_PostNoCopy);
		}
		default:
		{
			HookEvent("round_start", HookRoundStart, EventHookMode_PostNoCopy);
			HookEvent("round_end", HookRoundEnd, EventHookMode_PostNoCopy);
		}
	}
	
	/**
	Create console commands
	*/
	RegConsoleCmd("sm_buddy", Command_AddBalanceBuddy, "Add a balance buddy");
	RegConsoleCmd("sm_lockbuddy", Command_LockBuddy, "Locks your balance buddy selection");
	
	/**
	Load common translations
	*/
	LoadTranslations ("common.phrases");
	
	/**
	Create the global forward
	*/
	g_fwdPlayerMoved = CreateGlobalForward("SM_OnPlayerMoved", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_fwdOnClientTeamForced = CreateGlobalForward("SM_OnClientTeamForced", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Float);
	g_fwdOnClientTeamForceCleared = CreateGlobalForward("SM_OnClientTeamForceCleared", ET_Ignore, Param_Cell, Param_Cell);
}

public OnClientDisconnect(client)
{

	/**
	Cleanup clients/players buddy list
	*/
	if (!IsFakeClient(client))
	{
		SM_ClearBuddy(client, true);
		SM_LockBuddy(client, true);
	}
	SM_ClearForcedTeam(client);
}

public Action:Command_AddBalanceBuddy(client, args)
{
	if (client == 0)
	{
		SetGlobalTransTarget(client);
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	decl String:sPlayerUserId[24];
	GetCmdArg(1, sPlayerUserId, sizeof(sPlayerUserId));
	new iPlayer = GetClientOfUserId(StringToInt(sPlayerUserId));
	if (!iPlayer || !IsClientInGame(iPlayer) || client == iPlayer) 
	{
		if (client == iPlayer) 
		{
			SetGlobalTransTarget(client);
			PrintHintText(client, "%t", "SelectSelf");
		}
		ReplyToCommand(client, "[SM] Usage: buddy <userid>");
		DisplayPlayerMenu(client);
	} 
	else 
	{
		decl String:cName[128];
		decl String:bName[128];
		GetClientName(client, cName, sizeof(cName));
		GetClientName(iPlayer, bName, sizeof(bName));
		if (SM_IsBuddyLocked(iPlayer)) 
		{
			SetGlobalTransTarget(client);
			ReplyToCommand(client, "%t", "PlayerLockedBuddyMsg", bName);
			return Plugin_Handled;
		}
		SM_AssignBuddy(client, iPlayer);
		SetGlobalTransTarget(client);
		PrintHintText(client, "%t", "BuddyMsg", bName);
		SetGlobalTransTarget(iPlayer);
		PrintHintText(iPlayer, "%t", "BuddyMsg", cName);
	}
	return Plugin_Handled;	
}

public Action:Command_LockBuddy(client, args)
{
	if (client == 0) 
	{
		SetGlobalTransTarget(client);
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	if (SM_IsBuddyLocked(client)) 
	{
		SM_LockBuddy(client, false);
		SetGlobalTransTarget(client);
		PrintHintText(client, "%t", "BuddyLockMsgDisabled");
	} 
	else 
	{
		SM_LockBuddy(client, true);
		SetGlobalTransTarget(client);
		PrintHintText(client, "%t", "BuddyLockMsgEnabled");
	}
	return Plugin_Handled;
}

public HookRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	/**
	See if the teams have been switched
	*/
	if (g_bTeamsSwitched)
	{
		
		/**
		Switch the teams the players are forced to
		*/
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (g_aPlayers[i][iForcedTeam] != 0)
			{
				if (g_aPlayers[i][iForcedTeam] == g_aCurrentTeams[Team1])
				{
					g_aPlayers[i][iForcedTeam] = g_aCurrentTeams[Team2];
				}
				else
				{
					g_aPlayers[i][iForcedTeam] = g_aCurrentTeams[Team1];
				}
			}
		}
	}
}

public HookRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bTeamsSwitched = false;
}

public Action:HookPlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{

	/**
	Get our event variables
	*/
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new iTeam = GetEventInt(event, "team");
	
	/**
	See if the player is on the wrong team
	*/
	if (g_aPlayers[client][iForcedTeam] != 0 && g_aPlayers[client][iForcedTeam] != iTeam)
	{
	
		/**
		Move the player back to the forced team
		*/
		CreateTimer(1.0, Timer_ForcePlayerBack, client, TIMER_FLAG_NO_MAPCHANGE);
		
		/**
		If the event was going to be broadcasted, we refire it so it is not broadcasted and stop this one
		*/
		if (!dontBroadcast)
		{
			SetEventBroadcast(event, true);
		}
	}
	return Plugin_Continue;
}

public Action:UserMessageHook_Class(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new String:sMessage[120];
	BfReadString(bf, sMessage, sizeof(sMessage), true);
	if (StrContains(sMessage, "#TF_TeamsSwitched", false) != -1)
	{
		g_bTeamsSwitched = true;
	}
	return Plugin_Continue;
}

public Native_SM_MovePlayer(Handle:plugin, numParams)
{

	/**
	Get and check the client and team
	*/
	new client = GetNativeCell(1);
	new iTeam = GetNativeCell(2);
	new bool:bRespawn = GetNativeCell(3) ? true : false;
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client %d is not connected", client);
	}
	if (!IsClientInGame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client %d is not in the game", client);
	}
	if (iTeam != g_aCurrentTeams[Spectator] && iTeam != g_aCurrentTeams[Team1] && iTeam != g_aCurrentTeams[Team2])
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Invalid team %d", iTeam);
	}
	
	MovePlayer(client, iTeam);
	if (!IsClientObserver(client) && bRespawn)
	{
		RespawnPlayer(client);
	}
	
	new fResult;
	
	Call_StartForward(g_fwdPlayerMoved);
	Call_PushCell(plugin);
	Call_PushCell(client);
	Call_PushCell(iTeam);
	Call_Finish(fResult);
	
	if (fResult != SP_ERROR_NONE)
	{
		return ThrowNativeError(fResult, "Forward failed");
	}

	return fResult;
}

public Native_SM_SetForcedTeam(Handle:plugin, numParams)
{

	/**
	Get and check the client and team
	*/
	new client = GetNativeCell(1);
	new iTeam = GetNativeCell(2);
	new Float:fTime = Float:GetNativeCell(3);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client %d is not connected", client);
	}
	if (!IsClientInGame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client %d is not in the game", client);
	}
	if (iTeam != g_aCurrentTeams[Spectator] && iTeam != g_aCurrentTeams[Team1] && iTeam != g_aCurrentTeams[Team2] && iTeam != g_aCurrentTeams[Unknown])
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Invalid team %d", iTeam);
	}
	
	new bool:bOverRide = GetNativeCell(4) ? true : false;
	
	if (!bOverRide && g_aPlayers[client][hForcedTeamPlugin] != INVALID_HANDLE && plugin != g_aPlayers[client][hForcedTeamPlugin])
	{
		return false;
	}
	
	if (fTime < 1.0)
	{
		fTime = 1.0;
	}
	
	g_aPlayers[client][hForcedTeamPlugin] = plugin;
	g_aPlayers[client][iForcedTeam] = iTeam;
	g_aPlayers[client][fForcedTime] = fTime;
	ClearTimer(g_aPlayers[client][hForcedTeamTimer]);
	g_aPlayers[client][hForcedTeamTimer] = CreateTimer(fTime, Timer_ForcePlayerOver, client, TIMER_FLAG_NO_MAPCHANGE);
	if (iTeam != GetClientTeam(client))
	{
		MovePlayer(client, iTeam);
	}
	
	new fResult;
	Call_StartForward(g_fwdOnClientTeamForced);
	Call_PushCell(plugin);
	Call_PushCell(client);
	Call_PushCell(iTeam);
	Call_PushFloat(fTime);
	Call_Finish(fResult);
	if (fResult != SP_ERROR_NONE)
	{
		return ThrowNativeError(fResult, "Forward failed");
	}

	return true;
}

public Native_SM_GetForcedTeam(Handle:plugin, numParams)
{

	/**
	Get and check the client
	*/
	new client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client %d is not connected", client);
	}
	if (!IsClientInGame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client %d is not in the game", client);
	}
	
	/**
	Get and set the plugin if they want it
	*/
	new Handle:hPlugin = GetNativeCell(2);
	if (hPlugin != INVALID_HANDLE)
	{
		SetNativeCellRef(2, g_aPlayers[client][hForcedTeamPlugin]);
	}
	
	/**
	Return the forced team, this could be 0
	*/
	return g_aPlayers[client][iForcedTeam];
}

public Native_SM_ClearForcedTeam(Handle:plugin, numParams)
{

	/**
	Get and check the client and team
	*/
	new client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client %d is not connected", client);
	}
	
	g_aPlayers[client][hForcedTeamPlugin] = INVALID_HANDLE;
	g_aPlayers[client][iForcedTeam] = 0;
	g_aPlayers[client][fForcedTime] = 0.0;
	ClearTimer(g_aPlayers[client][hForcedTeamTimer]);
	
	new fResult;
	Call_StartForward(g_fwdOnClientTeamForceCleared);
	Call_PushCell(plugin);
	Call_PushCell(client);
	Call_Finish(fResult);
	
	if (fResult != SP_ERROR_NONE)
	{
		return ThrowNativeError(fResult, "Forward failed");
	}
	
	return true;
}

public Native_SM_ClearAllForcedTeams(Handle:plugin, numParams)
{
	for (new x = 1; x <= MaxClients; x++)
	{
		if (IsValidClient(x, false))
		{
			SM_ClearForcedTeam(x, true);
		}
	}
}

public Native_SM_AssignBuddy(Handle:plugin, numParams)
{

	/**
	Get and check the client and player
	*/
	new client = GetNativeCell(1);
	new iPlayer = GetNativeCell(2);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client %d is not connected", client);
	}
	if (!IsClientInGame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client %d is not in the game", client);
	}
	if (iPlayer < 0 || iPlayer > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Invalid player index (%d)", iPlayer);
	}
	if (!IsClientConnected(iPlayer))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Player %d is not connected", iPlayer);
	}
	if (!IsClientInGame(iPlayer))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Player %d is not in the game", client);
	}
	if (IsFakeClient(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Bots are not supported");
	}
	
	/**
	See if we can override his setting
	*/
	new bool:bOverRide = GetNativeCell(3) ? true : false;
	if (!bOverRide)
	{
	
		/**
		We can't override, so check if they are locked
		*/
		if (g_aPlayers[client][bBuddyLocked] || g_aPlayers[iPlayer][bBuddyLocked])
		{
		
			/**
			We detected at least 1 lock, so we bug out
			*/
			return false;
		}
	}
	
	/**
	Ready to set the buddies
	*/
	g_aPlayers[client][iBuddyPair] = iPlayer;
	g_aPlayers[iPlayer][iBuddyPair] = client;
	return true;
}

public Native_SM_GetClientBuddy(Handle:plugin, numParams)
{

	/**
	Get and check the client 
	*/
	new client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client %d is not connected", client);
	}
	if (!IsClientInGame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client %d is not in the game", client);
	}
	if (IsFakeClient(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Bots are not supported");
	}
	
	/**
	Return the players buddy, this could be 0
	*/
	return g_aPlayers[client][iBuddyPair];	
}

public Native_SM_LockBuddy(Handle:plugin, numParams)
{

	/**
	Get and check the client 
	*/
	new client = GetNativeCell(1);
	new bool:bSetting = GetNativeCell(2) ? true : false;
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client %d is not connected", client);
	}
	if (IsFakeClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Bots are not supported");
	}
	
	g_aPlayers[client][bBuddyLocked] = bSetting;
	return true;
}

public Native_SM_IsBuddyLocked(Handle:plugin, numParams)
{

	/**
	Get and check the client 
	*/
	new client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client %d is not connected", client);
	}
	if (!IsClientInGame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client %d is not in the game", client);
	}
	if (IsFakeClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Bots are not supported");
	}
	
	return g_aPlayers[client][bBuddyLocked];
}

public Native_SM_IsBuddyTeamed(Handle:plugin, numParams)
{
	/**
	Get and check the client 
	*/
	new client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client %d is not connected", client);
	}
	if (!IsClientInGame(client))
	{
		return ThrowNativeError(SP_ERROR_INDEX, "Client %d is not in the game", client);
	}
	if (IsFakeClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Bots are not supported");
	}
	
	new iBuddy = g_aPlayers[client][iBuddyPair];
	
	if (iBuddy && (GetClientTeam(client) == GetClientTeam(iBuddy)))
	{
		return true;
	}
	
	return false;
}

public Native_SM_ClearBuddy(Handle:plugin, numParams)
{

	/**
	Get and check the client
	*/
	new client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client (%d) is not connected", client);
	}
	if (IsFakeClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Bots are not supported");
	}
	
	/**
	Get the clients buddy and see if we can override his setting
	*/
	new bool:bOverRide = GetNativeCell(2) ? true : false;
	new iPlayer = g_aPlayers[client][iBuddyPair];
	
	/**
	There is no buddy, we don't care about anything else so bug out
	*/
	if (iPlayer == 0)
	{
		return true;
	}
	
	/**
	We determined he had a buddy, check the override setting
	*/
	if (!bOverRide)
	{
	
		/**
		We can't override, so check if they are locked
		*/
		if (g_aPlayers[client][bBuddyLocked] || g_aPlayers[iPlayer][bBuddyLocked])
		{
		
			/**
			We detected at least 1 lock, so we bug out
			*/
			return false;
		}
	}
	
	/**
	Ready to clear the buddies
	*/
	g_aPlayers[client][iBuddyPair] = 0;
	g_aPlayers[iPlayer][iBuddyPair] = 0;
	return true;
}

public Action:Timer_ForcePlayerBack(Handle:timer, any:client)
{

	MovePlayer(client, g_aPlayers[client][iForcedTeam]);
	
	/**
	if (g_aPlayers[client][iForcedTeam] != g_aCurrentTeams[Spectator])
	{
		RespawnPlayer(client);
	}
	*/
	
	PrintToChat(client, "\x01\x04----------------------------------");
	PrintToChat(client, "\x01\x04You have been forced to this team.");
	PrintToChat(client, "\x01\x04----------------------------------");
	
	return Plugin_Handled;
}

public Action:Timer_ForcePlayerOver(Handle:timer, any:client)
{
	g_aPlayers[client][hForcedTeamPlugin] = INVALID_HANDLE;
	g_aPlayers[client][iForcedTeam] = 0;
	g_aPlayers[client][fForcedTime] = 0.0;
	g_aPlayers[client][hForcedTeamTimer] = INVALID_HANDLE;
	PrintToChat(client, "\x01\x04----------------------------------");
	PrintToChat(client, "\x01\x04You're forced team has been cleared.");
	PrintToChat(client, "\x01\x04----------------------------------");
	return Plugin_Handled;
}

stock DisplayPlayerMenu(client, time = MENU_TIME_FOREVER)
{
	new Handle:hMenu = CreateMenu(Menu_SelectPlayer);
	AddTargetsToMenu(hMenu, 0, true, false);
	SetMenuTitle(hMenu, "Select A Player:");
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, time);
}

public Menu_SelectPlayer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:sSelection[24];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		new buddy = GetClientOfUserId(StringToInt(sSelection));
		new client = param1;
		if (client == buddy) 
		{
			PrintHintText(client, "%t", "SelectSelf");
		}
		else if (!IsClientInGame(buddy)) 
		{
			PrintHintText(client, "%t", "BuddyGone");
		}
		else 
		{
			decl String:cName[128];
			decl String:bName[128];
			GetClientName(client, cName, sizeof(cName));
			GetClientName(buddy, bName, sizeof(bName));
			if (!SM_IsBuddyLocked(buddy)) 
			{
				SM_AssignBuddy(client, buddy);
				PrintHintText(client, "%t", "BuddyMsg", bName);
				PrintHintText(buddy, "%t", "BuddyMsg", cName);
			} 
			else
			{
				PrintHintText(client, "%t", "PlayerLockedBuddyMsg", bName);
			}
		}
	} 
	else if (action == MenuAction_End) 
	{
		CloseHandle(menu);
	}
}
