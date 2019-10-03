#include <sourcemod>
#pragma semicolon 1

public Plugin:myinfo = {
	name = "TN REBOOTER",
	author = "Goerge, DWN",
	description = "Reboots My Server",
	version = "10/27/11",
	url = "http://www.topnotchclan.com"
};

new g_iUptime;
new g_iChecks;

public OnPluginStart()
{
	CreateTimer(60.0, theTimer, _, TIMER_REPEAT);
}

public Action:theTimer(Handle:timer)
{
	if (g_iUptime > 18000 && CurrentClientCount() <= 1 && 3 <= getHour() <= 6)
	{
		g_iChecks++;
	}
	if (g_iChecks > 4)
	{
		LogToFileEx("addons/sourcemod/logs/reboot.log", "REBOOTING SERVER SINCE ITS EMPTY");
		LogToFileEx("addons/sourcemod/logs/reboot.log", "%d", g_iUptime);
		LogToFileEx("addons/sourcemod/logs/reboot.log", "%d", getHour());
		LogToFileEx("addons/sourcemod/logs/reboot.log", "%d", CurrentClientCount());
		ServerCommand("quit");
	}
	if (6 <= getHour() <= 7 && g_iUptime > 259200)
	{
		LogToFileEx("addons/sourcemod/logs/reboot.log", "REBOOTING SERVER SINCE ITS BEEN 3 DAYS");
		LogToFileEx("addons/sourcemod/logs/reboot.log", "%d", g_iUptime);
		LogToFileEx("addons/sourcemod/logs/reboot.log", "%d", getHour());
		LogToFileEx("addons/sourcemod/logs/reboot.log", "%d", CurrentClientCount());
		CreateTimer(5.0, ad, _, TIMER_REPEAT);
	}
	if (CurrentClientCount() >= 2)
	{
		g_iChecks = 0;
	}
	g_iUptime += 60;
	return Plugin_Continue;
}

public Action:ad(Handle:timer)
{
	static countdown = 30;
	if (countdown -= 5)
	{
		PrintToChatAll("\x01\x04THE SERVER WILL BE RESTARTING IN \x01%d SECONDS\x04 FOR ITS DAILY RESTART, PLEASE REJOIN AFTER DISCONNECT", countdown);
		return Plugin_Continue;
	}
	else
		ServerCommand("quit");
	return Plugin_Handled;
}

stock getHour()
{
	decl String:szHour[3] = "";

	FormatTime (szHour, sizeof (szHour), "%H");
	return StringToInt (szHour);
}

stock CurrentClientCount(bool:bots = false)
{
	new iCount;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (bots)
			{
				iCount++;
			}
			else if (!IsFakeClient(i))
			{
				iCount++;
			}
		}
	}
	return iCount;
}
