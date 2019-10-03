/************************************************************************
* Bonus Round Immunity [TF2]
* Author(s): Antithasys (custom version by: retsam)
* File: bonusroundimmunity_dwn.sp
* Description: Gives admins/donors immunity during the bonus round.
*************************************************************************
* This is a custom private version of the bonus round immunity plugin.
* This plugin is NOT free to be distributed or used. If you are not part
* of -TN- gaming, you do not have permission to use this.
*************************************************************************
* Original core plugin found: http://projects.mygsn.net/svn/simple-plugins/trunk/bonusroundimmunity/addons/sourcemod/scripting/bonusroundimmunity.sp
* Author: Antithasys
* Copyright: (c) Simple SourceMod Plugins 2008-2009
*************************************************************************
*
* 1.4.0r - Added death hook to end effects earlier and possibly help prevent glitches.
*        - Removed unnecessary SetEntityRenderMode's.
*        - Moved few things around.
*
* 1.3.9r - Fixed issue of not getting client cookie color when the DisableColorNone cvar was enabled.
*        - Removed TIMER_FLAG_NO_MAPCHANGE flag from repeat timer. (In this case thats actually incorrect) 
*        
* 1.3.8r - Fixed color green erroring on buildings due to the previous edits.
*
* 1.3.7r - Fixed color defaulting to green when it was supposed to be team.
*        - Added new color for Opposing team. Now they can select the color of the enemy team if desired.
*
* 1.3.6r - Added cvar to disable color 'none'.
*        - Made it so if the disablenone cvar was enabled, the 'none' option is now removed from the menu. 
*        - Added checking client color cookie upon connect and changing them to default color if the disablenone cvar is enabled.
*        - Changed the default color setting to TEAM color.         
*
* 1.3.5r - Added advert cookie with popup panel for donors upon first spawn. Also, added reseting the advert cookie if user has "enabled" bri again.
*        - Added check in panel button selection for client prefs.
*        - Added a sound file for the panel menu advert.
*        - Added a playeralive check in spawn hook.
*        - Fixed pyros not switching to taunt wep if shotgun was equipped.
*        - Modified the length of the settings menus being displayed to 30 seconds instead of 25.       
*
* 1.3.4r - Added automatically switching donors weapons to a taunt weapon(if possible) when on the losing team of bonus round.
*        - Cvar added for taunt weapon switch as well.
*        
* 1.3.3r - Added few MaxClient checks for building related stuff to help filter out possible errors.
*        - Added a building sapper immunity cvar just in case you wanted to toggle this.
*        
* 1.3.2r - Possible fix for issue related to errors with rendermode on instanced scripted scene entities(wtf?). Added some checks to the timer.
*        - No longer applying collision to teleporters so teles can still be used. 
*        - Removed the setting of health back on round_start from default plugin. (I dont know what the purpose of this was)        
* 
* 1.3.1r - Added multiple selectable special effect client pref menu with many options.
*        - Added cvars for buildings immune and particle effects.
*        - Added spy sapper immunity to buildings.
*        - Edited some of the particle effects slightly.
*        - Added a bool to check powerplay effect to end it properly.        
*
* 1.3.0r - Fixed various missing checks.
*        - Fixed the client enable cookie not working.
*        - Recoded plugin to use optional client prefs. Now the plugin works with or without client prefs.
*        - Added special effect client pref option.
*        - Fixed all cookies to being enabled by default instead of disabled by default.
*        - Added buildings immunity to the plugin with cooresponding colors.
*        - Changed the client pref menu entry so only donors can access it. Put disabled menu entry and msg to non-donors attempting.
*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#undef REQUIRE_EXTENSIONS
#undef AUTOLOAD_EXTENSIONS
#include <clientprefs>
#define REQUIRE_EXTENSIONS
#define AUTOLOAD_EXTENSIONS

#define PLUGIN_VERSION "6-12-12"
#define SPECTATOR 1
#define TEAM_RED 2
#define TEAM_BLUE 3

#define ATTACH_NORMAL	0
#define ATTACH_HEAD		1

#define COLOR_TEAM 0
#define COLOR_BLACK 1
#define COLOR_RED 2
#define COLOR_BLUE 3
#define COLOR_GREEN 4
#define COLOR_RAINBOW 5
#define COLOR_OPTEAM 6
#define COLOR_NONE 7

#define PARTICLE_ESSENCE 0
#define PARTICLE_ELECTROSHIELD 1
#define PARTICLE_FLARETRAIL 2
#define PARTICLE_FIRESTARTER 3
#define PARTICLE_BUBBLETRAIL 4
#define PARTICLE_SPOOKED 5
#define PARTICLE_POWERPLAY 6
#define PARTICLE_GLOW 7
#define PARTICLE_NONE 8

//#define SOUND_PANEL "buttons/button9.wav"
#define SOUND_PANEL "buttons/blip1.wav"

enum e_Cookies
{
	bEnabled,
	iParticle,
	iColor,
};

enum e_ColorNames
{
	Green,
	Black,
	Red,
	Blue
};

enum e_ColorValues
{
	iRed,
	iGreen,
	iBlue
};

new Handle:Cvar_bri_charadminflag = INVALID_HANDLE;
new Handle:Cvar_bri_enabled = INVALID_HANDLE;
new Handle:Cvar_bri_effectsenabled = INVALID_HANDLE;
new Handle:Cvar_bri_buildingsimmune = INVALID_HANDLE;
new Handle:Cvar_bri_buildingsappimmune = INVALID_HANDLE;
new Handle:Cvar_bri_disablecolornone = INVALID_HANDLE;
new Handle:Cvar_bri_switchtauntwep = INVALID_HANDLE;
new Handle:bri_cookie_enabled = INVALID_HANDLE;
new Handle:bri_cookie_color = INVALID_HANDLE;
new Handle:bri_cookie_particle = INVALID_HANDLE;
new Handle:bri_cookie_advertshown = INVALID_HANDLE;
new Handle:g_hPlayerColorTimer[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new Handle:gCvar_mpBonusRoundTime = INVALID_HANDLE;

new bool:g_bIsPlayerAdmin[MAXPLAYERS + 1] = { false, ... };
new bool:g_bIsPlayerImmune[MAXPLAYERS + 1] = { false, ... };
new bool:g_bPlayerHasPowerplay[MAXPLAYERS + 1] = { false, ... };
new bool:g_bDonorAdvertShown[MAXPLAYERS + 1] = { false, ... };
new bool:g_bIsEnabled = true;
new bool:g_bRoundEnd = false;
new bool:g_bUseClientprefs;

new String:g_sCharAdminFlag[32];

new g_cvarEffectsEnabled;
new g_cvarBuildingSappImmune;
new g_cvarSwitchtauntWep;
new g_cvarBuildingsImmune;
new g_cvarDisableColorNone;
new g_iBuildingColors[2048];
new g_iAttachedParticle[MAXPLAYERS + 1][6];
new g_iPlayerCycleColor[MAXPLAYERS + 1] = { 0, ... };
new g_aClientCookies[MAXPLAYERS + 1][e_Cookies];
new g_iColors[e_ColorNames][e_ColorValues];
//new g_iClassMaxHealth[TFClassType] = {0, 125, 125, 200, 175, 150, 300, 175, 125, 125};

new Float:g_fBonusRoundTime = 0.0;


public Plugin:myinfo =
{
	name = "Bonus Round Immunity",
	author = "Antithasys (custom by: retsam)",
	description = "Gives admins immunity during bonus round",
	version = PLUGIN_VERSION,
	url = "http://projects.mytf2.com"
}

public OnPluginStart()
{
	CreateConVar("brimmunity_version", PLUGIN_VERSION, "Bonus Round Immunity", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar_bri_enabled = CreateConVar("bri_enabled", "1", "Enable/Disable Admin immunity during bonus round.");
	Cvar_bri_charadminflag = CreateConVar("bri_charadminflag", "a", "Admin flag to use for immunity (only one).  Must be a in char format.");
	Cvar_bri_effectsenabled = CreateConVar("bri_specialeffects", "1", "Enable/Disable the special effects during bonus round.");
	Cvar_bri_buildingsimmune = CreateConVar("bri_buildingsimmune", "1", "Enable/Disable donors buildings immunity/colors/collision during bonus round.");
	Cvar_bri_buildingsappimmune = CreateConVar("bri_buildingsappimmune", "1", "Enable/Disable donor buildings being immune to spy sappers. (this is separate from the buildingimmune cvar)");
	Cvar_bri_switchtauntwep = CreateConVar("bri_switchtauntwep", "1", "Enable/Disable auto switching losing team donors to their taunt weapons.");
	Cvar_bri_disablecolornone = CreateConVar("bri_disablecolornone", "0", "Enable disabling the color 'none' menu option. (This forces players to have a color)");
	
	HookConVarChange(Cvar_bri_enabled, EnabledChanged);
	HookConVarChange(Cvar_bri_effectsenabled, EnabledChanged);
	HookConVarChange(Cvar_bri_buildingsimmune, EnabledChanged);
	HookConVarChange(Cvar_bri_buildingsappimmune, EnabledChanged);
	HookConVarChange(Cvar_bri_switchtauntwep, EnabledChanged);
	HookConVarChange(Cvar_bri_disablecolornone, EnabledChanged);
	
	HookEvent("player_spawn", Hook_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Hook_PlayerDeath, EventHookMode_Post);
	HookEvent("teamplay_round_start", Hook_RoundStart, EventHookMode_Post);
	HookEvent("teamplay_round_win", Hook_RoundEnd, EventHookMode_Post);
	HookEvent("player_sapped_object", Hook_PlayerSappedObject, EventHookMode_Post);
	
	RegAdminCmd("sm_immunity", Command_Immunity, ADMFLAG_ROOT, "sm_immunity: Gives you immunity");

	LoadColors();
	
	gCvar_mpBonusRoundTime = FindConVar("mp_bonusroundtime");
	if (gCvar_mpBonusRoundTime == INVALID_HANDLE)
	{
		LogError("Could not locate cvar mp_bonusroundtime");
		SetFailState("Could not locate cvar mp_bonusroundtime");
	}
	else
	{
		HookConVarChange(gCvar_mpBonusRoundTime, BonusRoundTimeChanged);
	}
	
	AutoExecConfig(true, "plugin.bonusroundimmunity");
}

public OnAllPluginsLoaded()
{
	/**
	Now lets check for client prefs extension
	*/
	new String:sExtError[256];
	new iExtStatus = GetExtensionFileStatus("clientprefs.ext", sExtError, sizeof(sExtError));
	if (iExtStatus == -2)
	{
		LogAction(0, -1, "[BRI] Client Preferences extension was not found.");
		LogAction(0, -1, "[BRI] Plugin continued to load, but that feature will not be used.");
		g_bUseClientprefs = false;
	}
	if (iExtStatus == -1 || iExtStatus == 0)
	{
		LogAction(0, -1, "[BRI] Client Preferences extension is loaded with errors.");
		LogAction(0, -1, "[BRI] Status reported was [%s].", sExtError);
		LogAction(0, -1, "[BRI] Plugin continued to load, but that feature will not be used.");
		g_bUseClientprefs = false;
	}
	if (iExtStatus == 1)
	{
		LogAction(0, -1, "[BRI] Client Preferences extension is loaded, checking database.");
		if (!SQL_CheckConfig("clientprefs"))
		{
			LogAction(0, -1, "[BRI] No 'clientprefs' database found.  Check your database.cfg file.");
			LogAction(0, -1, "[BRI] Plugin continued to load, but Client Preferences will not be used.");
			g_bUseClientprefs = false;
		}
		else
		{
			LogAction(0, -1, "[BRI] Database config 'clientprefs' was found.");
			LogAction(0, -1, "[BRI] Plugin will use Client Preferences.");
			g_bUseClientprefs = true;
		}
		
		/**
		Deal with client cookies
		*/
		if(g_bUseClientprefs)
		{
			bri_cookie_enabled = RegClientCookie("bri_client_enabled", "Enable/Disable your immunity during the bonus round.", CookieAccess_Public);
			bri_cookie_color = RegClientCookie("bri_client_color", "Color to render when immune.", CookieAccess_Public);
			bri_cookie_particle = RegClientCookie("bri_client_particle", "Particle effect when immune.", CookieAccess_Public);
			bri_cookie_advertshown = RegClientCookie("bri_client_advertshown", "Advert panel shown.", CookieAccess_Public);
			SetCookieMenuItem(CookieMenu_TopMenu, bri_cookie_enabled, "Bonus Round Immunity");
		}
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("RegClientCookie");
	MarkNativeAsOptional("SetCookieMenuItem");
	MarkNativeAsOptional("SetClientCookie");
	MarkNativeAsOptional("GetClientCookie");
	MarkNativeAsOptional("ShowCookieMenu");

	return APLRes_Success;
}

/*
public OnLibraryAdded(const String:name[])
{
	PrintToChatAll("OnLibraryAdded is: %s", name);
	if(StrEqual(name, "clientprefs.ext"))
	{

	}
}

public OnLibraryRemoved(const String:name[])
{
	PrintToChatAll("OnLibraryRemoved is: %s", name);
	if(StrEqual(name, "clientprefs.ext"))
	{

	}
}
*/

public OnMapStart()
{
	g_bRoundEnd = false;

	PrecacheSound(SOUND_PANEL, true);
}

public OnConfigsExecuted()
{
	GetConVarString(Cvar_bri_charadminflag, g_sCharAdminFlag, sizeof(g_sCharAdminFlag));
	g_bIsEnabled = GetConVarBool(Cvar_bri_enabled);
	g_cvarEffectsEnabled = GetConVarInt(Cvar_bri_effectsenabled);
	g_cvarBuildingsImmune = GetConVarInt(Cvar_bri_buildingsimmune);
	g_cvarBuildingSappImmune = GetConVarInt(Cvar_bri_buildingsappimmune);
	g_cvarSwitchtauntWep = GetConVarInt(Cvar_bri_switchtauntwep);
	g_cvarDisableColorNone = GetConVarInt(Cvar_bri_disablecolornone);
	g_fBonusRoundTime = GetConVarFloat(gCvar_mpBonusRoundTime);
}

public OnClientPostAdminCheck(client)
{
	if(IsValidAdmin(client, g_sCharAdminFlag))
	{
		g_bIsPlayerAdmin[client] = true;
		
		if(!g_bUseClientprefs)
		{
			g_aClientCookies[client][iParticle] = PARTICLE_ESSENCE;
			g_aClientCookies[client][bEnabled] = GetConVarInt(Cvar_bri_enabled);
			g_aClientCookies[client][iColor] = COLOR_TEAM;
			g_bDonorAdvertShown[client] = true;
		}
	}
	else
	{
		g_bIsPlayerAdmin[client] = false;
	}
	
	g_bIsPlayerImmune[client] = false;
	g_bPlayerHasPowerplay[client] = false;
}

public OnClientCookiesCached(client)
{
	decl String:sEnabled[2], String:sColor[4], String:sParticle[2], String:sAdvert[2];
	GetClientCookie(client, bri_cookie_enabled, sEnabled, sizeof(sEnabled));
	GetClientCookie(client, bri_cookie_color, sColor, sizeof(sColor));
	GetClientCookie(client, bri_cookie_particle, sParticle, sizeof(sParticle));
	GetClientCookie(client, bri_cookie_advertshown, sAdvert, sizeof(sAdvert));
	g_aClientCookies[client][bEnabled] = !StringToInt(sEnabled);
	g_aClientCookies[client][iParticle] = StringToInt(sParticle);
	g_bDonorAdvertShown[client] = bool:StringToInt(sAdvert);
	
	if(g_cvarDisableColorNone)
	{ 
		//PrintToServer("%N's color cookie set to: %s", client, sColor);
		if(StrEqual(sColor, "7"))
		{
			//PrintToServer("%N's color cookie being reset!", client);
			SetClientCookie(client, bri_cookie_color, "0");
			g_aClientCookies[client][iColor] = COLOR_TEAM; 
		}
		else
		{
			g_aClientCookies[client][iColor] = StringToInt(sColor);
		}   
	}
	else
	{
		g_aClientCookies[client][iColor] = StringToInt(sColor);
	}
}

public OnClientDisconnect(client)
{
	if(g_hPlayerColorTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hPlayerColorTimer[client]);
		g_hPlayerColorTimer[client] = INVALID_HANDLE;
	}

	g_bIsPlayerAdmin[client] = false;
	g_bPlayerHasPowerplay[client] = false;
	g_bIsPlayerImmune[client] = false;
	g_iPlayerCycleColor[client] = 0;
}

public Action:Command_Immunity(client, args)
{
	if(client < 1 || !IsClientInGame(client) || !IsPlayerAlive(client))
	return Plugin_Handled;

	if(g_bIsPlayerImmune[client])
	{
		DisableImmunity(client);
		CreateTimer(0.1, Timer_DeleteParticles, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		EnableImmunity(client);
		if(g_cvarBuildingsImmune)
		{
			SetBuildingsImmune("obj_*");
		}

		if(g_aClientCookies[client][iParticle] != PARTICLE_NONE)
		{
			AttachPlayerParticles(client);
		}
	}
	
	return Plugin_Handled;
}

public Hook_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bRoundEnd = false;

	if(!g_bIsEnabled)
	return;

	for(new x = 1; x <= MaxClients; x++) 
	{
		if(!IsClientInGame(x))
		{
			continue;
		}
		
		if(g_bIsPlayerImmune[x])
		{
			DisableImmunity(x);
			if(g_cvarEffectsEnabled)
			{
				CreateTimer(0.1, Timer_DeleteParticles, x, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Hook_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bIsEnabled)
	return;

	g_bRoundEnd = true;

	new winnerTeam = GetEventInt(event, "team");

	for(new x = 1; x <= MaxClients; x++)
	{
		if(!IsClientInGame(x) || !IsPlayerAlive(x))
		{
			continue;
		}
		
		if(!g_bIsPlayerAdmin[x] || !g_aClientCookies[x][bEnabled])
		{
			continue;
		}
		
		EnableImmunity(x);
		
		if(g_cvarSwitchtauntWep)
		{
			if(GetClientTeam(x) != winnerTeam)
			{
				SwitchTauntWeapon(x);    
			}
		}
		
		if(g_cvarEffectsEnabled && g_aClientCookies[x][iParticle] != PARTICLE_NONE)
		{
			AttachPlayerParticles(x);
		}
	}

	if(g_cvarBuildingsImmune)
	{
		SetBuildingsImmune("obj_*");
	}
}

public Hook_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bIsEnabled)
	return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client < 1 || !IsPlayerAlive(client) || !g_bIsPlayerAdmin[client])
	return;

	if(!g_bDonorAdvertShown[client])
	{
		CreateTimer(0.5, Timer_DonorCookieAdvert, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	if(!g_bRoundEnd)
	return;

	if(g_aClientCookies[client][bEnabled] && !g_bIsPlayerImmune[client])
	{
		EnableImmunity(client);
	}
}

public Hook_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bIsEnabled)
	return;
	
	new deathflags = GetEventInt(event, "death_flags");
	if(deathflags & TF_DEATHFLAG_DEADRINGER)
	return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client < 1 || !g_bIsPlayerAdmin[client])
	return;
	
	if(g_bIsPlayerImmune[client])
	{
		//DisableImmunity(client);
		CreateTimer(FloatSub(g_fBonusRoundTime, 1.0), Timer_DisableEffects, client, TIMER_FLAG_NO_MAPCHANGE);
		if(g_cvarEffectsEnabled)
		{
			CreateTimer(0.05, Timer_DeleteParticles, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Hook_PlayerSappedObject(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bRoundEnd || !g_cvarBuildingSappImmune)
	return;

	new owner = GetClientOfUserId(GetEventInt(event, "ownerid"));
	//new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	//PrintToChatAll("Current sapped owner is: %N", owner);
	if(owner < 1 || owner > MaxClients)
	return;

	if(g_bIsPlayerAdmin[owner])
	{
		new sapper = -1;
		new ibuilton, iowner;
		while ((sapper = FindEntityByClassname(sapper, "obj_attachment_sapper")) != -1)
		{
			//ibuilton == GetEntPropEnt(sapper, Prop_Send, "m_hBuiltOnEntity");
			ibuilton = GetEntDataEnt2(sapper, FindSendPropOffs("CObjectSapper","m_hBuiltOnEntity"));
			//PrintToChatAll("iBuilton is: %d", ibuilton);
			if(ibuilton < 1)
			break;
			
			iowner = GetEntPropEnt(ibuilton, Prop_Send, "m_hBuilder");
			//PrintToChatAll("iOwner is: %N", iowner);
			if(iowner < 1 || iowner > MaxClients)
			break;

			if(iowner == owner)
			{
				AcceptEntityInput(sapper, "kill");
			}
			
			//SetVariantInt(9999);  //alternate ways to kill sappers
			//AcceptEntityInput(sapper, "RemoveHealth");
		}
	}
	else
	{
		//PrintToChatAll("Buildings owner is not admin!");
	}
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
		SetMenuTitle(hMenu, "Options (Current Setting)");
		if(g_bIsPlayerAdmin[client])
		{
			if (g_aClientCookies[client][bEnabled])
			{
				AddMenuItem(hMenu, "enable", "Enabled/Disable (Enabled)");
			}
			else
			{
				AddMenuItem(hMenu, "enable", "Enabled/Disable (Disabled)");
			}
			if (g_aClientCookies[client][iParticle] != PARTICLE_NONE)
			{
				AddMenuItem(hMenu, "particle", "Special Effect (Enabled)");
			}
			else
			{
				AddMenuItem(hMenu, "particle", "Special Effect (Disabled)");
			}
			switch (g_aClientCookies[client][iColor])
			{
			case COLOR_TEAM:
				{
					AddMenuItem(hMenu, "color", "Color (Team)");
				}
			case COLOR_BLACK:
				{
					AddMenuItem(hMenu, "color", "Color (Black)");
				}
			case COLOR_RED:
				{
					AddMenuItem(hMenu, "color", "Color (Red)");
				}
			case COLOR_BLUE:
				{
					AddMenuItem(hMenu, "color", "Color (Blue)");
				}
			case COLOR_GREEN:
				{
					AddMenuItem(hMenu, "color", "Color (Green)");
				}
			case COLOR_RAINBOW:
				{
					AddMenuItem(hMenu, "color", "Color (Rainbow)");
				}
			case COLOR_OPTEAM:
				{
					AddMenuItem(hMenu, "color", "Color (Opposing Team)");
				}
			case COLOR_NONE:
				{
					AddMenuItem(hMenu, "color", "Color (None)");
				}
			}
		}
		else
		{
			AddMenuItem(hMenu, "enable", "This menu requires donor access flags", ITEMDRAW_DISABLED);
			PrintToChat(client, "[SM] Sorry, only donors may access the bonus round immunity menu.");
		}
		
		SetMenuExitBackButton(hMenu, true);
		DisplayMenu(hMenu, client, 30);
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
			SetMenuTitle(hMenu, "Enable/Disable Round End Immunity");
			
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
			DisplayMenu(hMenu, client, 30);
		}
		else if (StrEqual(sSelection, "particle", false))
		{
			new Handle:hMenu = CreateMenu(Menu_CookieParticleSettings);
			SetMenuTitle(hMenu, "Select Special Effect");
			
			switch(g_aClientCookies[client][iParticle])
			{
			case PARTICLE_ESSENCE:
				{
					AddMenuItem(hMenu, "Essence", "Essence (Set)");
					AddMenuItem(hMenu, "ElectroShield", "ElectroShield");
					AddMenuItem(hMenu, "Flaretrail", "Flaretrail");
					AddMenuItem(hMenu, "Firestarter", "Firestarter");
					AddMenuItem(hMenu, "Bubbletrail", "Bubbletrail");
					AddMenuItem(hMenu, "Spooked", "Spooked");
					AddMenuItem(hMenu, "Powerplay", "Powerplay");
					AddMenuItem(hMenu, "Glow", "Glow");
					AddMenuItem(hMenu, "None", "None");
				}
			case PARTICLE_ELECTROSHIELD:
				{
					AddMenuItem(hMenu, "Essence", "Essence");
					AddMenuItem(hMenu, "ElectroShield", "ElectroShield (Set)");
					AddMenuItem(hMenu, "Flaretrail", "Flaretrail");
					AddMenuItem(hMenu, "Firestarter", "Firestarter");
					AddMenuItem(hMenu, "Bubbletrail", "Bubbletrail");
					AddMenuItem(hMenu, "Spooked", "Spooked");
					AddMenuItem(hMenu, "Powerplay", "Powerplay");
					AddMenuItem(hMenu, "Glow", "Glow");
					AddMenuItem(hMenu, "None", "None");
				}
			case PARTICLE_FLARETRAIL:
				{
					AddMenuItem(hMenu, "Essence", "Essence");
					AddMenuItem(hMenu, "ElectroShield", "ElectroShield");
					AddMenuItem(hMenu, "Flaretrail", "Flaretrail (Set)");
					AddMenuItem(hMenu, "Firestarter", "Firestarter");
					AddMenuItem(hMenu, "Bubbletrail", "Bubbletrail");
					AddMenuItem(hMenu, "Spooked", "Spooked");
					AddMenuItem(hMenu, "Powerplay", "Powerplay");
					AddMenuItem(hMenu, "Glow", "Glow");
					AddMenuItem(hMenu, "None", "None");
				}
			case PARTICLE_FIRESTARTER:
				{
					AddMenuItem(hMenu, "Essence", "Essence");
					AddMenuItem(hMenu, "ElectroShield", "ElectroShield");
					AddMenuItem(hMenu, "Flaretrail", "Flaretrail");
					AddMenuItem(hMenu, "Firestarter", "Firestarter (Set)");
					AddMenuItem(hMenu, "Bubbletrail", "Bubbletrail");
					AddMenuItem(hMenu, "Spooked", "Spooked");
					AddMenuItem(hMenu, "Powerplay", "Powerplay");
					AddMenuItem(hMenu, "Glow", "Glow");
					AddMenuItem(hMenu, "None", "None");
				}
			case PARTICLE_BUBBLETRAIL:
				{
					AddMenuItem(hMenu, "Essence", "Essence");
					AddMenuItem(hMenu, "ElectroShield", "ElectroShield");
					AddMenuItem(hMenu, "Flaretrail", "Flaretrail");
					AddMenuItem(hMenu, "Firestarter", "Firestarter");
					AddMenuItem(hMenu, "Bubbletrail", "Bubbletrail (Set)");
					AddMenuItem(hMenu, "Spooked", "Spooked");
					AddMenuItem(hMenu, "Powerplay", "Powerplay");
					AddMenuItem(hMenu, "Glow", "Glow");
					AddMenuItem(hMenu, "None", "None");
				}
			case PARTICLE_SPOOKED:
				{
					AddMenuItem(hMenu, "Essence", "Essence");
					AddMenuItem(hMenu, "ElectroShield", "ElectroShield");
					AddMenuItem(hMenu, "Flaretrail", "Flaretrail");
					AddMenuItem(hMenu, "Firestarter", "Firestarter");
					AddMenuItem(hMenu, "Bubbletrail", "Bubbletrail");
					AddMenuItem(hMenu, "Spooked", "Spooked (Set)");
					AddMenuItem(hMenu, "Powerplay", "Powerplay");
					AddMenuItem(hMenu, "Glow", "Glow");
					AddMenuItem(hMenu, "None", "None");
				}
			case PARTICLE_POWERPLAY:
				{
					AddMenuItem(hMenu, "Essence", "Essence");
					AddMenuItem(hMenu, "ElectroShield", "ElectroShield");
					AddMenuItem(hMenu, "Flaretrail", "Flaretrail");
					AddMenuItem(hMenu, "Firestarter", "Firestarter");
					AddMenuItem(hMenu, "Bubbletrail", "Bubbletrail");
					AddMenuItem(hMenu, "Spooked", "Spooked");
					AddMenuItem(hMenu, "Powerplay", "Powerplay (Set)");
					AddMenuItem(hMenu, "Glow", "Glow");
					AddMenuItem(hMenu, "None", "None");
				}
			case PARTICLE_GLOW:
				{
					AddMenuItem(hMenu, "Essence", "Essence");
					AddMenuItem(hMenu, "ElectroShield", "ElectroShield");
					AddMenuItem(hMenu, "Flaretrail", "Flaretrail");
					AddMenuItem(hMenu, "Firestarter", "Firestarter");
					AddMenuItem(hMenu, "Bubbletrail", "Bubbletrail");
					AddMenuItem(hMenu, "Spooked", "Spooked");
					AddMenuItem(hMenu, "Powerplay", "Powerplay");
					AddMenuItem(hMenu, "Glow", "Glow (Set)");
					AddMenuItem(hMenu, "None", "None");
				}
			case PARTICLE_NONE:
				{
					AddMenuItem(hMenu, "Essence", "Essence");
					AddMenuItem(hMenu, "ElectroShield", "ElectroShield");
					AddMenuItem(hMenu, "Flaretrail", "Flaretrail");
					AddMenuItem(hMenu, "Firestarter", "Firestarter");
					AddMenuItem(hMenu, "Bubbletrail", "Bubbletrail");
					AddMenuItem(hMenu, "Spooked", "Spooked");
					AddMenuItem(hMenu, "Powerplay", "Powerplay");
					AddMenuItem(hMenu, "Glow", "Glow");
					AddMenuItem(hMenu, "None", "None (Set)");
				}
			}
			
			SetMenuExitBackButton(hMenu, true);
			DisplayMenu(hMenu, client, 30);
		}
		else
		{
			new Handle:hMenu = CreateMenu(Menu_CookieSettingsColors);
			SetMenuTitle(hMenu, "Select Immunity Color");
			switch (g_aClientCookies[client][iColor])
			{
			case COLOR_TEAM:
				{
					AddMenuItem(hMenu, "Team", "Team Color (Set)");
					AddMenuItem(hMenu, "Black", "Black");
					AddMenuItem(hMenu, "Red", "Red");
					AddMenuItem(hMenu, "Blue", "Blue");
					AddMenuItem(hMenu, "Green", "Green");
					AddMenuItem(hMenu, "Rain", "Rainbow");
					AddMenuItem(hMenu, "OpTeam", "Opposing Team");
					if(!g_cvarDisableColorNone)
					{
						AddMenuItem(hMenu, "None", "None");
					}
				}
			case COLOR_BLACK:
				{
					AddMenuItem(hMenu, "Team", "Team Color");
					AddMenuItem(hMenu, "Black", "Black (Set)");
					AddMenuItem(hMenu, "Red", "Red");
					AddMenuItem(hMenu, "Blue", "Blue");
					AddMenuItem(hMenu, "Green", "Green");
					AddMenuItem(hMenu, "Rain", "Rainbow");
					AddMenuItem(hMenu, "OpTeam", "Opposing Team");
					if(!g_cvarDisableColorNone)
					{
						AddMenuItem(hMenu, "None", "None");
					}
				}
			case COLOR_RED:
				{
					AddMenuItem(hMenu, "Team", "Team Color");
					AddMenuItem(hMenu, "Black", "Black");
					AddMenuItem(hMenu, "Red", "Red (Set)");
					AddMenuItem(hMenu, "Blue", "Blue");
					AddMenuItem(hMenu, "Green", "Green");
					AddMenuItem(hMenu, "Rain", "Rainbow");
					AddMenuItem(hMenu, "OpTeam", "Opposing Team");
					if(!g_cvarDisableColorNone)
					{
						AddMenuItem(hMenu, "None", "None");
					}
				}
			case COLOR_BLUE:
				{
					AddMenuItem(hMenu, "Team", "Team Color");
					AddMenuItem(hMenu, "Black", "Black");
					AddMenuItem(hMenu, "Red", "Red");
					AddMenuItem(hMenu, "Blue", "Blue (Set)");
					AddMenuItem(hMenu, "Green", "Green");
					AddMenuItem(hMenu, "Rain", "Rainbow");
					AddMenuItem(hMenu, "OpTeam", "Opposing Team");
					if(!g_cvarDisableColorNone)
					{
						AddMenuItem(hMenu, "None", "None");
					}
				}
			case COLOR_GREEN:
				{
					AddMenuItem(hMenu, "Team", "Team Color");
					AddMenuItem(hMenu, "Black", "Black");
					AddMenuItem(hMenu, "Red", "Red");
					AddMenuItem(hMenu, "Blue", "Blue");
					AddMenuItem(hMenu, "Green", "Green (Set)");
					AddMenuItem(hMenu, "Rain", "Rainbow");
					AddMenuItem(hMenu, "OpTeam", "Opposing Team");
					if(!g_cvarDisableColorNone)
					{
						AddMenuItem(hMenu, "None", "None");
					}
				}
			case COLOR_RAINBOW:
				{
					AddMenuItem(hMenu, "Team", "Team Color");
					AddMenuItem(hMenu, "Black", "Black");
					AddMenuItem(hMenu, "Red", "Red");
					AddMenuItem(hMenu, "Blue", "Blue");
					AddMenuItem(hMenu, "Green", "Green");
					AddMenuItem(hMenu, "Rain", "Rainbow (Set)");
					AddMenuItem(hMenu, "OpTeam", "Opposing Team");
					if(!g_cvarDisableColorNone)
					{
						AddMenuItem(hMenu, "None", "None");
					}
				}
			case COLOR_OPTEAM:
				{
					AddMenuItem(hMenu, "Team", "Team Color");
					AddMenuItem(hMenu, "Black", "Black");
					AddMenuItem(hMenu, "Red", "Red");
					AddMenuItem(hMenu, "Blue", "Blue");
					AddMenuItem(hMenu, "Green", "Green");
					AddMenuItem(hMenu, "Rain", "Rainbow");
					AddMenuItem(hMenu, "OpTeam", "Opposing Team (Set)");
					if(!g_cvarDisableColorNone)
					{
						AddMenuItem(hMenu, "None", "None");
					}
				}
			case COLOR_NONE:
				{
					AddMenuItem(hMenu, "Team", "Team Color");
					AddMenuItem(hMenu, "Black", "Black");
					AddMenuItem(hMenu, "Red", "Red");
					AddMenuItem(hMenu, "Blue", "Blue");
					AddMenuItem(hMenu, "Green", "Green");
					AddMenuItem(hMenu, "Rain", "Rainbow");
					AddMenuItem(hMenu, "OpTeam", "Opposing Team");
					if(!g_cvarDisableColorNone)
					{
						AddMenuItem(hMenu, "None", "None (Set)");
					}
					else
					{
						AddMenuItem(hMenu, "None", "None (Set) [disabled]", ITEMDRAW_DISABLED);
					}
				}
			}
			SetMenuExitBackButton(hMenu, true);
			DisplayMenu(hMenu, client, 30);
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
			SetClientCookie(client, bri_cookie_enabled, "0");
			SetClientCookie(client, bri_cookie_advertshown, "0");
			g_bDonorAdvertShown[client] = false;
			g_aClientCookies[client][bEnabled] = 1;
			PrintToChat(client, "[SM] Bonus Round Immunity is ENABLED");
		}
		else
		{
			SetClientCookie(client, bri_cookie_enabled, "1");
			g_aClientCookies[client][bEnabled] = 0;
			PrintToChat(client, "[SM] Bonus Round Immunity is DISABLED");
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

public Menu_CookieParticleSettings(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select) 
	{
		new String:sSelection[24];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "Essence", false))
		{
			SetClientCookie(client, bri_cookie_particle, "0");
			g_aClientCookies[client][iParticle] = PARTICLE_ESSENCE;
			PrintToChat(client, "[SM] Immunity effect set to ESSENCE");
		}
		else if (StrEqual(sSelection, "ElectroShield", false))
		{
			SetClientCookie(client, bri_cookie_particle, "1");
			g_aClientCookies[client][iParticle] = PARTICLE_ELECTROSHIELD;
			PrintToChat(client, "[SM] Immunity effect set to ELECTROSHIELD");
		}
		else if (StrEqual(sSelection, "Flaretrail", false))
		{
			SetClientCookie(client, bri_cookie_particle, "2");
			g_aClientCookies[client][iParticle] = PARTICLE_FLARETRAIL;
			PrintToChat(client, "[SM] Immunity effect set to FLARETRAIL");
		}
		else if (StrEqual(sSelection, "Firestarter", false))
		{
			SetClientCookie(client, bri_cookie_particle, "3");
			g_aClientCookies[client][iParticle] = PARTICLE_FIRESTARTER;
			PrintToChat(client, "[SM] Immunity effect set to FIRESTARTER");
		}
		else if (StrEqual(sSelection, "Bubbletrail", false))
		{
			SetClientCookie(client, bri_cookie_particle, "4");
			g_aClientCookies[client][iParticle] = PARTICLE_BUBBLETRAIL;
			PrintToChat(client, "[SM] Immunity effect set to BUBBLETRAIL");
		}
		else if (StrEqual(sSelection, "Spooked", false))
		{
			SetClientCookie(client, bri_cookie_particle, "5");
			g_aClientCookies[client][iParticle] = PARTICLE_SPOOKED;
			PrintToChat(client, "[SM] Immunity effect set to SPOOKED");
		}
		else if (StrEqual(sSelection, "Powerplay", false))
		{
			SetClientCookie(client, bri_cookie_particle, "6");
			g_aClientCookies[client][iParticle] = PARTICLE_POWERPLAY;
			PrintToChat(client, "[SM] Immunity effect set to POWERPLAY");
		}
		else if (StrEqual(sSelection, "Glow", false))
		{
			SetClientCookie(client, bri_cookie_particle, "7");
			g_aClientCookies[client][iParticle] = PARTICLE_GLOW;
			PrintToChat(client, "[SM] Immunity effect set to GLOW");
		}
		else if (StrEqual(sSelection, "None", false))
		{
			SetClientCookie(client, bri_cookie_particle, "8");
			g_aClientCookies[client][iParticle] = PARTICLE_NONE;
			PrintToChat(client, "[SM] Immunity effect set to NONE");
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

public Menu_CookieSettingsColors(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	if (action == MenuAction_Select) 
	{
		new String:sSelection[24];
		GetMenuItem(menu, param2, sSelection, sizeof(sSelection));
		if (StrEqual(sSelection, "Team", false))
		{
			SetClientCookie(client, bri_cookie_color, "0");
			g_aClientCookies[client][iColor] = COLOR_TEAM;
			PrintToChat(client, "[SM] Immunity color set to TEAM COLOR");
		}
		else if (StrEqual(sSelection, "Black", false))
		{
			SetClientCookie(client, bri_cookie_color, "1");
			g_aClientCookies[client][iColor] = COLOR_BLACK;
			PrintToChat(client, "[SM] Immunity color set to BLACK");
		}
		else if (StrEqual(sSelection, "Red", false))
		{
			SetClientCookie(client, bri_cookie_color, "2");
			g_aClientCookies[client][iColor] = COLOR_RED;
			PrintToChat(client, "[SM] Immunity color set to RED");
		}
		else if (StrEqual(sSelection, "Blue", false))
		{
			SetClientCookie(client, bri_cookie_color, "3");
			g_aClientCookies[client][iColor] = COLOR_BLUE;
			PrintToChat(client, "[SM] Immunity color set to BLUE");
		}
		else if (StrEqual(sSelection, "Green", false))
		{
			SetClientCookie(client, bri_cookie_color, "4");
			g_aClientCookies[client][iColor] = COLOR_GREEN;
			PrintToChat(client, "[SM] Immunity color set to GREEN");
		}
		else if (StrEqual(sSelection, "Rain", false))
		{
			SetClientCookie(client, bri_cookie_color, "5");
			g_aClientCookies[client][iColor] = COLOR_RAINBOW;
			PrintToChat(client, "[SM] Immunity color set to RAINBOW");
		}
		else if (StrEqual(sSelection, "OpTeam", false))
		{
			SetClientCookie(client, bri_cookie_color, "6");
			g_aClientCookies[client][iColor] = COLOR_OPTEAM;
			PrintToChat(client, "[SM] Immunity color set to OPPOSING TEAM");
		}
		else if (StrEqual(sSelection, "None", false))
		{
			SetClientCookie(client, bri_cookie_color, "7");
			g_aClientCookies[client][iColor] = COLOR_NONE;
			PrintToChat(client, "[SM] Immunity color set to NONE");
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

public Action:Timer_ChangeColor(Handle:timer, any:client)
{
	if(g_iPlayerCycleColor[client]++ == 3)
	{
		g_iPlayerCycleColor[client] = 0;
	}
	//SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, g_iColors[g_iPlayerCycleColor[client]][iRed], g_iColors[g_iPlayerCycleColor[client]][iGreen], g_iColors[g_iPlayerCycleColor[client]][iBlue], 255);
	
	return Plugin_Continue;
}

public Action:Timer_ChangeColorBuilding(Handle:timer, any:obj)
{
	if(!g_bRoundEnd)
	return Plugin_Stop;

	if(obj > 0 && IsValidEntity(obj))
	{
		//new client = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
		if(g_iBuildingColors[obj]++ == 3)
		{
			g_iBuildingColors[obj] = 0;
		}
		
		SetEntityRenderColor(obj, g_iColors[g_iBuildingColors[obj]][iRed], g_iColors[g_iBuildingColors[obj]][iGreen], g_iColors[g_iBuildingColors[obj]][iBlue], 255);
	}
	else
	{
		//PrintToChatAll("\x01ChangeColorBuilding Timer Killed!");
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:Timer_DonorCookieAdvert(Handle:timer, any:client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
	return;

	EmitSoundToClient(client, SOUND_PANEL);

	new Handle:panel = CreatePanel();
	
	SetPanelTitle(panel, "(-TN-) Donator Settings Info");
	DrawPanelText(panel, "-----------------------------------");
	DrawPanelText(panel, "> Donors are able to pick their own,");
	DrawPanelText(panel, "bonus round colors and special effects!");
	DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	DrawPanelText(panel, "> Commands to customize settings:");
	DrawPanelText(panel, "CHAT: !settings or /settings");
	DrawPanelText(panel, "CONSOLE: sm_settings");
	DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	DrawPanelItem(panel, "Customize settings now");
	DrawPanelItem(panel, " ", ITEMDRAW_SPACER);
	DrawPanelItem(panel, " ", ITEMDRAW_SPACER);
	DrawPanelItem(panel, " ", ITEMDRAW_SPACER);
	DrawPanelText(panel, "-----------------------------------");
	DrawPanelText(panel, "(Note: This menu will not be shown again)");
	DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	DrawPanelItem(panel, "Exit Menu");
	SendPanelToClient(panel, client, PanelHandler, MENU_TIME_FOREVER);
	
	CloseHandle(panel);
	
	return;
}

public PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 1) //Client saw the menu and decided to configure the settings.
		{
			if(g_bUseClientprefs)
			{
				FakeClientCommand(param1, "sm_settings");
				g_bDonorAdvertShown[param1] = true;
				SetClientCookie(param1, bri_cookie_advertshown, "1");
			}
			else
			{
				PrintToChat(param1, "[SM] Sorry, it looks like we arent connected to the database. You are not able to edit any settings at this time.");
				g_bDonorAdvertShown[param1] = true;
			}
		}
		else if(param2 == 5) //Client saw the menu but decided to exit it. Still marking cookie as shown.
		{
			if(g_bUseClientprefs)
			{
				SetClientCookie(param1, bri_cookie_advertshown, "1");
				g_bDonorAdvertShown[param1] = true;
			}
			else
			{
				g_bDonorAdvertShown[param1] = true;
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 < 0) //Menu could not be drawn, shown, was overridden by another menu, or client disconnected. Do not mark cookie as shown.
		{
			return;
		} 
	}
}

stock EnableImmunity(client)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	
	switch(g_aClientCookies[client][iColor])
	{
	case COLOR_TEAM:
		{
			new iTeam = GetClientTeam(client);
			SetEntityRenderColor(client, g_iColors[e_ColorNames:iTeam][iRed], g_iColors[e_ColorNames:iTeam][iGreen], g_iColors[e_ColorNames:iTeam][iBlue], 255);
		}
	case COLOR_OPTEAM:
		{
			new iTeam;
			if(GetClientTeam(client) == 2)
			{
				iTeam = 3;
			}
			else
			{
				iTeam = 2;
			}
			SetEntityRenderColor(client, g_iColors[e_ColorNames:iTeam][iRed], g_iColors[e_ColorNames:iTeam][iGreen], g_iColors[e_ColorNames:iTeam][iBlue], 255);
		}
	case COLOR_RAINBOW:
		{
			if(g_hPlayerColorTimer[client] != INVALID_HANDLE)
			{
				CloseHandle(g_hPlayerColorTimer[client]);
				g_hPlayerColorTimer[client] = INVALID_HANDLE;
			}
			g_hPlayerColorTimer[client] = CreateTimer(0.2, Timer_ChangeColor, client, TIMER_REPEAT);
		}
	case COLOR_NONE:
		{
			//We dont have to set a color
		}
	case COLOR_GREEN:
		{
			SetEntityRenderColor(client, g_iColors[Green][iRed], g_iColors[Green][iGreen], g_iColors[Green][iBlue], 255);
		}
	default:
		{
			SetEntityRenderColor(client, g_iColors[e_ColorNames:g_aClientCookies[client][iColor]][iRed], g_iColors[e_ColorNames:g_aClientCookies[client][iColor]][iGreen], g_iColors[e_ColorNames:g_aClientCookies[client][iColor]][iBlue], 255);
		}
	}
	SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
	g_bIsPlayerImmune[client] = true;
}

stock DisableImmunity(client)
{
	if(g_hPlayerColorTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hPlayerColorTimer[client]);
		g_hPlayerColorTimer[client] = INVALID_HANDLE;
	}

	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	//new TFClassType:PlayerClass = TF2_GetPlayerClass(client);
	//new iMaxHealth = g_iClassMaxHealth[PlayerClass];
	//SetEntityHealth(client, iMaxHealth);
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);

	if(g_bPlayerHasPowerplay[client])
	{
		TF2_SetPlayerPowerPlay(client, false);
		TF2_RemoveCondition(client, TFCond_Ubercharged);
		g_bPlayerHasPowerplay[client] = false;
	}

	g_iPlayerCycleColor[client] = 0;
	g_bIsPlayerImmune[client] = false;
}

stock AttachPlayerParticles(client)
{
	//PrintToChatAll("ClientCookieParticle is: %i", g_aClientCookies[client][iParticle]);
	switch(g_aClientCookies[client][iParticle])
	{
	case PARTICLE_ESSENCE:
		{
			AttachDonorParticle(client, "player_dripsred", 0.0, ATTACH_HEAD, 0);
			AttachDonorParticle(client, "player_drips_blue", 0.0, ATTACH_HEAD, 1);
			AttachDonorParticle(client, "coin_large_blue", 10.0, ATTACH_NORMAL, 2);
			AttachDonorParticle(client, "coin_large_blue", 10.0, ATTACH_NORMAL, 3);
			AttachDonorParticle(client, "medicgun_beam_attrib_muzzle", 0.0, ATTACH_HEAD, 4);
			AttachDonorParticle(client, "ghost_glow", 15.0, ATTACH_NORMAL, 5);
		}
	case PARTICLE_ELECTROSHIELD:
		{
			AttachDonorParticle(client, "critgun_weaponmodel_blu", 5.0, ATTACH_NORMAL, 0);
			AttachDonorParticle(client, "crutgun_firstperson", 40.0, ATTACH_NORMAL, 1);
			AttachDonorParticle(client, "crutgun_firstperson", 40.0, ATTACH_NORMAL, 2);
			AttachDonorParticle(client, "crutgun_firstperson", 40.0, ATTACH_NORMAL, 3);
			AttachDonorParticle(client, "crutgun_firstperson", 40.0, ATTACH_NORMAL, 4);
			AttachDonorParticle(client, "crutgun_firstperson", 40.0, ATTACH_NORMAL, 5);
		}
	case PARTICLE_FLARETRAIL:
		{
			AttachDonorParticle(client, "flaregun_trail_crit_red", 15.0, ATTACH_NORMAL, 0);
			AttachDonorParticle(client, "flaregun_trail_crit_red", 15.0, ATTACH_NORMAL, 1);
			AttachDonorParticle(client, "flaregun_trail_crit_blue", 15.0, ATTACH_NORMAL, 2);
			AttachDonorParticle(client, "flaregun_trail_crit_blue", 15.0, ATTACH_NORMAL, 3);
		}
	case PARTICLE_FIRESTARTER:
		{
			AttachDonorParticle(client, "buildingdamage_fire3", 0.0, ATTACH_HEAD, 0);
			AttachDonorParticle(client, "tpdamage_4", 10.0, ATTACH_NORMAL, 1);
			AttachDonorParticle(client, "burningplayer_red", 10.0, ATTACH_NORMAL, 2);
			AttachDonorParticle(client, "burningplayer_red", 10.0, ATTACH_NORMAL, 3);
			AttachDonorParticle(client, "critical_rocket_red", 10.0, ATTACH_NORMAL, 4);
		}
	case PARTICLE_BUBBLETRAIL:
		{
			AttachDonorParticle(client, "rockettrail_waterbubbles", 5.0, ATTACH_NORMAL, 0);
			AttachDonorParticle(client, "rockettrail_waterbubbles", 5.0, ATTACH_NORMAL, 1);
			AttachDonorParticle(client, "env_rain_splashring", 5.0, ATTACH_NORMAL, 2);
			AttachDonorParticle(client, "env_rain_splashripple", 5.0, ATTACH_NORMAL, 3);
			AttachDonorParticle(client, "env_rain_splashripple", 5.0, ATTACH_NORMAL, 4);
		}
	case PARTICLE_SPOOKED:
		{
			AttachDonorParticle(client, "ghost_glow", 30.0, ATTACH_NORMAL, 0);
			AttachDonorParticle(client, "yikes_fx", 0.0, ATTACH_HEAD, 1);
			AttachDonorParticle(client, "ghost_appearation", 0.0, ATTACH_NORMAL, 2);
		}
	case PARTICLE_POWERPLAY:
		{	
			if (TF2_GetPlayerClass(client) == TF2_GetClass("medic"))
			{
				TF2_AddCondition(client, TFCond_Ubercharged, FloatSub(g_fBonusRoundTime, 1.0));
			}
			else {
				TF2_SetPlayerPowerPlay(client, true);
			}
			//TF2_SetPlayerPowerPlay(client, true);
			g_bPlayerHasPowerplay[client] = true;
		}
	case PARTICLE_GLOW:
		{
			new team = GetClientTeam(client);
			if(team == 2)
			{
				AttachDonorParticle(client, "player_glowred", 5.0, ATTACH_NORMAL, 0);
				AttachDonorParticle(client, "player_glowred", 5.0, ATTACH_NORMAL, 1);
				AttachDonorParticle(client, "soldierbuff_red_volume", -5.0, ATTACH_NORMAL, 2);
				AttachDonorParticle(client, "soldierbuff_red_volume", -5.0, ATTACH_NORMAL, 3);
				AttachDonorParticle(client, "soldierbuff_red_volume", -5.0, ATTACH_NORMAL, 4);
			}
			else
			{
				AttachDonorParticle(client, "player_glowblue", 5.0, ATTACH_NORMAL, 0);
				AttachDonorParticle(client, "player_glowblue", 5.0, ATTACH_NORMAL, 1);
				AttachDonorParticle(client, "soldierbuff_blue_volume", -5.0, ATTACH_NORMAL, 2);
				AttachDonorParticle(client, "soldierbuff_blue_volume", -5.0, ATTACH_NORMAL, 3);
				AttachDonorParticle(client, "soldierbuff_blue_volume", -5.0, ATTACH_NORMAL, 4);
			}
		}
	case PARTICLE_NONE:
		{
	
		}
	}
}

stock LoadColors()
{
	g_iColors[Green][iRed] = 0;
	g_iColors[Green][iGreen] = 255;
	g_iColors[Green][iBlue] = 0;

	g_iColors[Black][iRed] = 10;
	g_iColors[Black][iGreen] = 10;
	g_iColors[Black][iBlue] = 0;
	
	g_iColors[Red][iRed] = 255;
	g_iColors[Red][iGreen] = 0;
	g_iColors[Red][iBlue] = 0;
	
	g_iColors[Blue][iRed] = 0;
	g_iColors[Blue][iGreen] = 0;
	g_iColors[Blue][iBlue] = 255;
}

stock SetBuildingsImmune(const String:building[])
{
	new obj = -1;
	while ((obj = FindEntityByClassname(obj, building)) != -1)
	{
		new String:sBuildingName[32];
		GetEdictClassname(obj, sBuildingName, sizeof(sBuildingName)); 
		//PrintToChatAll("Building is a: %s", sBuildingName);
		
		new iOwner = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
		if(iOwner < 1 || iOwner > MaxClients)
		break;
		
		if(g_bIsPlayerAdmin[iOwner] && g_aClientCookies[iOwner][bEnabled])
		{
			//decl Float:fObjPos[3];
			//GetEntPropVector(obj, Prop_Send, "m_vecOrigin", fObjPos);
			
			SetEntProp(obj, Prop_Data, "m_takedamage", 0, 1);
			if(!StrEqual(sBuildingName, "obj_teleporter", false))
			{
				//PrintToChatAll("Object is not a teleport, set collision.");
				SetEntProp(obj, Prop_Data, "m_CollisionGroup", 1);
			}
			
			SetEntityRenderMode(obj, RENDER_TRANSCOLOR);
			switch(g_aClientCookies[iOwner][iColor])
			{
			case COLOR_TEAM:
				{
					new iTeam = GetClientTeam(iOwner);
					SetEntityRenderColor(obj, g_iColors[e_ColorNames:iTeam][iRed], g_iColors[e_ColorNames:iTeam][iGreen], g_iColors[e_ColorNames:iTeam][iBlue], 255);
				}
			case COLOR_OPTEAM:
				{
					new iTeam;
					if(GetClientTeam(iOwner) == 2)
					{
						iTeam = 3;
					}
					else
					{
						iTeam = 2;
					}
					
					SetEntityRenderColor(obj, g_iColors[e_ColorNames:iTeam][iRed], g_iColors[e_ColorNames:iTeam][iGreen], g_iColors[e_ColorNames:iTeam][iBlue], 255);
				}
			case COLOR_RAINBOW:
				{
					g_iBuildingColors[obj] = 0;
					CreateTimer(0.2, Timer_ChangeColorBuilding, obj, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			case COLOR_GREEN:
				{
					SetEntityRenderColor(obj, g_iColors[Green][iRed], g_iColors[Green][iGreen], g_iColors[Green][iBlue], 255);
				}
			case COLOR_NONE:
				{
					//We dont have to set a color
				}
			default:
				{
					SetEntityRenderColor(obj, g_iColors[e_ColorNames:g_aClientCookies[iOwner][iColor]][iRed], g_iColors[e_ColorNames:g_aClientCookies[iOwner][iColor]][iGreen], g_iColors[e_ColorNames:g_aClientCookies[iOwner][iColor]][iBlue], 255);
				}
			}
		}
	}
}

stock SwitchTauntWeapon(client)
{
	if(client < 1 || !IsClientInGame(client))
	return;

	new TFClassType:class = TF2_GetPlayerClass(client);
	switch(class)
	{
	case 1: // Scout
		{
			new tauntwep = GetPlayerWeaponSlot(client, 2);
			if(IsValidEntity(tauntwep))
			{
				if(GetEntProp(tauntwep, Prop_Send, "m_iItemDefinitionIndex") == 44) //sandman
				{
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", tauntwep);
				}
			}   
		}
	case 2: // Sniper
		{
			new tauntwep = GetPlayerWeaponSlot(client, 0);
			if(IsValidEntity(tauntwep))
			{
				if(GetEntProp(tauntwep, Prop_Send, "m_iItemDefinitionIndex") == 56) //huntsman
				{
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", tauntwep);
				}
			}
		}
	case 3: // Soldier
		{
			new tauntwep = GetPlayerWeaponSlot(client, 2);
			if(IsValidEntity(tauntwep))
			{
				if(GetEntProp(tauntwep, Prop_Send, "m_iItemDefinitionIndex") == 128) //equalizer
				{
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", tauntwep);
				}
			} 
		}
	case 4: // Demoman
		{
			new tauntwep = GetPlayerWeaponSlot(client, 2);
			if(IsValidEntity(tauntwep))
			{
				if(GetEntProp(tauntwep, Prop_Send, "m_iItemDefinitionIndex") == 132) //eyelander
				{
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", tauntwep);
				}
			} 
		}
	case 5: // Medic
		{
			new tauntwep = GetPlayerWeaponSlot(client, 2);
			if(IsValidEntity(tauntwep))
			{
				if(GetEntProp(tauntwep, Prop_Send, "m_iItemDefinitionIndex") == 37) //ubersaw
				{
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", tauntwep);
				}
			}
		}
	case 6: // Heavy
		{
			new tauntwep = GetPlayerWeaponSlot(client, 2);
			if(IsValidEntity(tauntwep))
			{
				if(GetEntProp(tauntwep, Prop_Send, "m_iItemDefinitionIndex") == 5) //fists
				{
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", tauntwep);
				}
			}
		}
	case 7:// Pyro
		{
			new tauntwep = GetPlayerWeaponSlot(client, 1);
			if(IsValidEntity(tauntwep))
			{
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", tauntwep);
			}
		}
	case 8: // Spy
		{
			new tauntwep = GetPlayerWeaponSlot(client, 2);
			if(IsValidEntity(tauntwep))
			{
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", tauntwep);
			}
		}
	case 9: // Engineer
		{
			new tauntwep = GetPlayerWeaponSlot(client, 0);
			new tauntwep2 = GetPlayerWeaponSlot(client, 2);
			
			if(IsValidEntity(tauntwep))
			{
				if(GetEntProp(tauntwep, Prop_Send, "m_iItemDefinitionIndex") == 141) //frontier justice
				{
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", tauntwep);
				}
				else if(IsValidEntity(tauntwep2))
				{
					if(GetEntProp(tauntwep2, Prop_Send, "m_iItemDefinitionIndex") == 142) //gunslinger
					{
						SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", tauntwep2);
					}
				}
			}
		}
	}
}

stock AttachDonorParticle(ent, String:particleType[], Float: Zpos, attach=ATTACH_NORMAL, arrayIndex)
{	
	new particle = CreateEntityByName("info_particle_system");

	new String:tName[128];
	if(IsValidEntity(particle))
	{
		new Float:pos[3]; 
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		
		//move the particle up or down
		pos[2] = pos[2] + Zpos;
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);

		DispatchKeyValue(particle, "targetname", "particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		if(attach == ATTACH_HEAD)
		{
			SetVariantString("head");
			AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		}
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");

		g_iAttachedParticle[ent][arrayIndex] = particle;
	}
}

public Action:Timer_DisableEffects(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
	return;
	
	DisableImmunity(client);
}

public Action:Timer_DeleteParticles(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
	return;

	new particle;
	for(new i = 0; i < 6; i++)
	{
		particle = g_iAttachedParticle[client][i];
		if(IsValidEntity(particle))
		{
			new String:classname[256];
			GetEdictClassname(particle, classname, sizeof(classname));
			if (StrEqual(classname, "info_particle_system", false))
			{
				//PrintToChatAll("Particle deleted! %s",classname);
				AcceptEntityInput(particle, "kill");
			}
		}
	}
}

stock bool:IsValidAdmin(client, const String:flags[])
{
	if (!IsClientConnected(client))
	return false;
	
	new ibFlags = ReadFlagString(flags);
	if(!StrEqual(flags, ""))
	{
		if ((GetUserFlagBits(client) & ibFlags) == ibFlags) 
		{
			return true;
		}
	}
	if (GetUserFlagBits(client) & ADMFLAG_ROOT) 
	{
		return true;
	}
	
	return false;
}

public EnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Cvar_bri_enabled)
	{
		if (StringToInt(newValue) == 0) 
		{
			UnhookEvent("player_spawn", Hook_PlayerSpawn, EventHookMode_Post);
			UnhookEvent("player_death", Hook_PlayerDeath, EventHookMode_Post);
			UnhookEvent("teamplay_round_start", Hook_RoundStart, EventHookMode_Post);
			UnhookEvent("teamplay_round_win", Hook_RoundEnd, EventHookMode_Post);
			UnhookEvent("player_sapped_object", Hook_PlayerSappedObject, EventHookMode_Post);
			for (new x = 1; x <= MaxClients; x++) 
			{
				if (g_bIsPlayerAdmin[x] && g_bIsPlayerImmune[x]) 
				{
					DisableImmunity(x);
					CreateTimer(0.1, Timer_DeleteParticles, x, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			g_bIsEnabled = false;
		} 
		else 
		{
			HookEvent("player_spawn", Hook_PlayerSpawn, EventHookMode_Post);
			HookEvent("player_death", Hook_PlayerDeath, EventHookMode_Post);
			HookEvent("teamplay_round_start", Hook_RoundStart, EventHookMode_Post);
			HookEvent("teamplay_round_win", Hook_RoundEnd, EventHookMode_Post);
			HookEvent("player_sapped_object", Hook_PlayerSappedObject, EventHookMode_Post);
			g_bIsEnabled = true;
		}
	}
	else if(convar == Cvar_bri_effectsenabled)
	{
		g_cvarEffectsEnabled = StringToInt(newValue);
	}
	else if(convar == Cvar_bri_buildingsimmune)
	{
		g_cvarBuildingsImmune = StringToInt(newValue);
	}
	else if(convar == Cvar_bri_buildingsappimmune)
	{
		g_cvarBuildingSappImmune = StringToInt(newValue);
	}
	else if(convar == Cvar_bri_switchtauntwep)
	{
		g_cvarSwitchtauntWep = StringToInt(newValue);
	}
	else if(convar == Cvar_bri_disablecolornone)
	{
		g_cvarDisableColorNone = StringToInt(newValue);
	}
}

public BonusRoundTimeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fBonusRoundTime = StringToFloat(newValue);
}

