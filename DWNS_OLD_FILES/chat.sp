/************************************************************************
*************************************************************************
Bonus Round Immunity
Description:
	Gives admins immunity during the bonus round
*************************************************************************
*************************************************************************
This plugin is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or any later version.

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************
File Information
$Id: bonusroundimmunity.sp 51 2009-03-29 23:44:52Z Antithasys $
$Author: Antithasys $
$Revision: 51 $
$Date: 2009-03-29 16:44:52 -0700 (Sun, 29 Mar 2009) $
$LastChangedBy: Antithasys $
$LastChangedDate: 2009-03-29 16:44:52 -0700 (Sun, 29 Mar 2009) $
$URL: http://www.mytf2.com/svn/simple-plugins/trunk/bonusroundimmunity/addons/sourcemod/scripting/bonusroundimmunity.sp $
$Copyright: (c) Simple SourceMod Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/
 
#pragma semicolon 1
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <clientprefs>

#define PLUGIN_VERSION "1.2.$Revision: 51 $"

enum e_Cookies
{
	bEnabled,
};

new Handle:bri_charadminflag = INVALID_HANDLE;
new Handle:bri_enabled = INVALID_HANDLE;
new Handle:bri_cookie_enabled = INVALID_HANDLE;
new Handle:bri_cookie_color = INVALID_HANDLE;
new Handle:bri_cookie_mode = INVALID_HANDLE;
new bool:g_bIsPlayerAdmin[MAXPLAYERS + 1];
new bool:g_bIsPlayerImmune[MAXPLAYERS + 1];
new bool:EnableColors[MAXPLAYERS + 1];
new bool:g_bLoadedLate = false;
new bool:g_bIsEnabled = true;
new String:g_sCharAdminFlag[32];
new g_aClientCookies[MAXPLAYERS + 1][e_Cookies];

public Plugin:myinfo =
{
	name = "Bonus Round Immunity",
	author = "Simple SourceMod Plugins",
	description = "Gives admins immunity during bonus round",
	version = PLUGIN_VERSION,
	url = "http://projects.mytf2.com"
}

bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLoadedLate = late;
	return true;
}

public OnPluginStart()
{
	CreateConVar("brimmunity_version", PLUGIN_VERSION, "Bonus Round Immunity", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	bri_enabled = CreateConVar("bri_enabled", "1", "Enable/Disable Admin immunity during bonus round.");
	
	HookConVarChange(bri_enabled, EnabledChanged);
	
	RegConsoleCmd("say", HandleSay);
	RegConsoleCmd("say_team", HandleSayTeam);
	
	bri_cookie_enabled = RegClientCookie("bri_client_enabled", "Enable/Disable your immunity during the bonus round.", CookieAccess_Public);
	
}

public OnAllPluginsLoaded()
{
	//something
}

public OnLibraryRemoved(const String:name[])
{
	//something
}

public OnClientPostAdminCheck(client)
{
	if (IsValidAdmin(client, g_sCharAdminFlag))
		g_bIsPlayerAdmin[client] = true;
	else
		g_bIsPlayerAdmin[client] = false;
}

public OnClientCookiesCached(client)
{
	decl String:sEnabled[2];
	GetClientCookie(client, bri_cookie_enabled, sEnabled, sizeof(sEnabled));
	g_aClientCookies[client][bEnabled] = StringToInt(sEnabled);
}

public OnClientDisconnect(client)
{
	CleanUp(client);
}

public CookieMenu_TopMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		//don't think we need to do anything
	}
	else
	{
		new Handle:hMenu = CreateMenu(Menu_CookieSettings);
		SetMenuTitle(hMenu, "Enable/Disable Colored Chat");
		if (g_aClientCookies[client][bEnabled])
		{
			AddMenuItem(hMenu, "enable", "Enabled/Disable (Enabled)");
		}
		else
		{
			AddMenuItem(hMenu, "enable", "Enabled/Disable (Disabled)");
		}
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	}
}

public Menu_CookieSettings(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select) 
	{
		new String:sSelection[24];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "enable", false))
		{
			new Handle:hMenu = CreateMenu(Menu_CookieSettingsEnable);
			SetMenuTitle(hMenu, "Enable/Disable Colored Chat");
			
			if (g_aClientCookies[client][bEnabled])
			{
				AddMenuItem(hMenu, "enable", "Enable (Set)");
				AddMenuItem(hMenu, "disable", "Disable");
			}
			else
			{
				AddMenuItem(hMenu, "enable", "Enabled");
				AddMenuItem(hMenu, "disable", "Disable (Set)");
			}
			
			SetMenuExitBackButton(hMenu, true);
			DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			ShowCookieMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Menu_CookieSettingsEnable(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select) 
	{
		new String:sSelection[24];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "enable", false))
		{
			SetClientCookie(client, bri_cookie_enabled, "1");
			g_aClientCookies[client][bEnabled] = 1;
			PrintToChat(client, "[SM] Colored Chat is ENABLED");
		}
		else
		{
			SetClientCookie(client, bri_cookie_enabled, "0");
			g_aClientCookies[client][bEnabled] = 0;
			PrintToChat(client, "[SM] Colored Chat is DISABLED");
		}
	}
	else if (action == MenuAction_Cancel) 
	{
		if (param2 == MenuCancel_ExitBack)
		{
			ShowCookieMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

stock CleanUp(iClient)
{
	g_bIsPlayerAdmin[iClient] = false;
	DisableImmunity(iClient);
}

public Action:HandleSay(client, args)
{
	if (!client)  /* stopps if console */
		return Plugin_Handled;
		
	new AdminId:id = GetUserAdmin(client); 
	
	if (id == INVALID_ADMIN_ID) /* stopps if not an admin*/
		return Plugin_Handled;

	//Declare:
	decl String:Arg[255], String:ChatMsg[255], String:ClientName[32];

	//Initialize:
	GetClientName(client, ClientName, sizeof(ClientName));
	GetCmdArgString(Arg, sizeof(Arg));

	//Clean:
	StripQuotes(Arg);
	TrimString(Arg);

	//Preconcieved Commands:
	if(Arg[0] == '/' || Arg[0] == '!' || Arg[0] == '@')
		return Plugin_Continue;

	//Format:
	Format(ChatMsg, 255, "\x03%s \x01:  \x03%s", ClientName, Arg);

	//Print:
	for(new X = 1; X <= MaxClients; X++)
		if(IsClientConnected(X))
			if(IsPlayerAlive(client) == IsPlayerAlive(X))
				SayText2(X, ChatMsg);

	g_bIsPlayerImmune[iClient] = true;
}

stock DisableImmunity(iClient)
{
	g_bIsPlayerImmune[iClient] = false;
}

stock bool:IsValidAdmin(iClient, const String:flags[])
{
	if (!IsClientConnected(iClient))
		return false;
	new ibFlags = ReadFlagString(flags);
	if ((GetUserFlagBits(iClient) & ibFlags) == ibFlags) 
	{
		return true;
	}
	if (GetUserFlagBits(iClient) & ADMFLAG_ROOT) 
	{
		return true;
	}
	return false;
}

public EnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0) 
	{
		UnRegConsoleCmd("say", HandleSay);
		UnRegConsoleCmd("say_team", HandleSayTeam);
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (g_bIsPlayerAdmin[i] && g_bIsPlayerImmune[i]) 
			{
				DisableImmunity(i);
			}
		}
		g_bIsEnabled = false;
	} 
	else 
	{
		RegConsoleCmd("say", HandleSay);
		RegConsoleCmd("say_team", HandleSayTeam);
		g_bIsEnabled = true;
	}
}

SayText2(to, const String:message[]) {
	new Handle:hBf = StartMessageOne("SayText2", to);
	
	if (hBf != INVALID_HANDLE) {
		BfWriteByte(hBf,   to);
		BfWriteByte(hBf,   true);
		BfWriteString(hBf, message);
		
		EndMessage();
	}
}
