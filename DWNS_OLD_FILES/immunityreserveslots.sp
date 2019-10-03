/**
 * ==================================================================================
 *  Immunity Reserve Slots Change Log
 * ==================================================================================
 * 
 *  0.1
 *  - Initial release.
 * 
 *  0.2
 *  - Added lowest time option to kick types.
 *  - Added cvars to control kick message for normal kick and immunity kick.
 *  - Small optimizations.
 * 
 * 0.3
 *  - Fixed some logging bugs.
 *  - Fixed a major bug in the immunity check and optimised regular check.
 *
 * 0.3.1
 *  - Fixed a very small bug in the logging code to do with detecting spectators.
 *
 * 0.3.2
 *  - Added option to only log who gets kicked.
 *
 * 0.3.3
 *  - Added cvar to control whether or not spectators get kicked first before other
 *    players or not (defaults to enabled).
 * ==================================================================================
 */

#include <sourcemod>
#include <cbaseserver>
#define PLUGIN_VERSION "0.3.3"

new Handle:cvar_KickType = INVALID_HANDLE;
new Handle:cvar_Spec = INVALID_HANDLE;
new Handle:cvar_Logging = INVALID_HANDLE;
new Handle:cvar_Immunity = INVALID_HANDLE;
new Handle:cvar_KickReasonImmunity = INVALID_HANDLE;
new Handle:cvar_KickReason = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Immunity Reserve Slots",
	author = "Jamster (original plugin by *pRED)",
	description = "Immunity based reserve slots for the CBaseServer Tools extension",
	version = PLUGIN_VERSION,
	url = "http: * www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_irs_version", PLUGIN_VERSION, "Immunity Reserve Slots version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_KickType = CreateConVar("sm_irs_kicktype", "2", "Who to kick when a valid player is found (0 - random, 1 - highest ping, 2 - highest time, 3 - lowest time)", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	cvar_KickReason = CreateConVar("sm_irs_kickreason", "Kick To Make Room For Donator", "Message to display when a client is kicked for a normal reserve slot", FCVAR_PLUGIN);
	cvar_KickReasonImmunity = CreateConVar("sm_irs_kickreason_immunity", "Server Full of Donators", "Message to display when a client is kicked for a reserve slot based on immunity", FCVAR_PLUGIN);
	cvar_Logging = CreateConVar("sm_irs_log", "0", "Enable logging (0 - disable, 1 - enable highly verbose logs, 2 - only log the disconnected and connecting users)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvar_Immunity = CreateConVar("sm_irs_immunity", "1", "Enable immunity check (0 - disable, 1 - res check THEN immunity check if server is full of res, 2 - allow players with immunity and no res to stay connected if their immunty is high enough)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvar_Spec = CreateConVar("sm_irs_kickspecfirst", "1", "When enabled spectators are always kicked first before anyone else (0 - disable, all players are taken into account for kicking, 1 - enable)", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	AutoExecConfig(true, "plugin.immunityreserveslots");
}

public OnClientPreConnect(const String:name[], const String:pass[], const String:ip[], const String:authid[])
{
	PrintToServer("%s %s %s %s", name, pass, ip, authid);
	
	if (GetClientCount(false) < MaxClients)
	{
		return;	
	}
	
	new KickType = GetConVarInt(cvar_KickType);
	new Logging = GetConVarInt(cvar_Logging);	
	new Immunity = GetConVarInt(cvar_Immunity);
	new SpecKick = GetConVarInt(cvar_Spec);
	new AdminId:admin = INVALID_ADMIN_ID;
	new String:AdminName[32];
	
	admin = FindAdminByIdentity(AUTHMETHOD_STEAM, authid);
	
	if (Logging == 1)
	{
		GetAdminUsername(admin, AdminName, sizeof(AdminName));
	}
	
	if (admin == INVALID_ADMIN_ID)
	{
		return;
	}
	
	if (GetAdminFlag(admin, Admin_Reservation))
	{
		new KickTarget = 0;		
		new Float:HighestValue;
		new HighestValueId;
		new bool:SpecFound;		
		new Float:HighestSpecValue;
		new HighestSpecValueId;		
		new Float:value;
		new PlayerIndex = 1;
		new ImmuneCount = 0;
		new LowestImmunityLevel = 101;
		new ConnectingPlayerImmunity = GetAdminImmunityLevel(admin);
		new bool:LowestValuePicked = false;
		new bool:LowestSpecValuePicked = false;
		
		if (Logging == 1)
		{
			LogMessage("===START===");
		}
		
		for (new i=1; i<=MaxClients; i++)
		{	
			if (!IsClientConnected(i))
			{
				ImmuneCount++;
				continue;
			}
			
			if (IsFakeClient(i))
			{
				ImmuneCount++;
				continue;
			}
			
			new String:PlayerAuth[32];
			GetClientAuthString(i, PlayerAuth, sizeof(PlayerAuth));
			new AdminId:PlayerAdmin = FindAdminByIdentity(AUTHMETHOD_STEAM, PlayerAuth)
			new PlayerImmunity = GetAdminImmunityLevel(PlayerAdmin);
			new flags = GetUserFlagBits(i);
			
			if (Logging == 1)
			{
				decl String:PlayerName[32];
				GetClientName(i, PlayerName, sizeof(PlayerName));
				if (IsClientInGame(i) && IsClientObserver(i))
				{
					LogMessage("%0d: %s immunity: %d -- [Spectator]", PlayerIndex, PlayerName, PlayerImmunity);
					PlayerIndex++;
				}
				else
				{
					LogMessage("%0d: %s immunity: %d", PlayerIndex, PlayerName, PlayerImmunity);
					PlayerIndex++;
				}
			}
			
			if (flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION)
			{
				if (Immunity && PlayerImmunity < LowestImmunityLevel)
				{
					LowestImmunityLevel = PlayerImmunity;
				}
				ImmuneCount++;
				continue;
			}
			
			// Hopefully this fixes the "revolving door" bug
			// edit: seems it does
			if (GetAdminFlag(PlayerAdmin, Admin_Reservation, Access_Effective) || GetAdminFlag(PlayerAdmin, Admin_Root, Access_Effective))
			{
				if (Immunity && PlayerImmunity < LowestImmunityLevel)
				{
					LowestImmunityLevel = PlayerImmunity;
				}
				ImmuneCount++;
				continue;
			}
			
			if (Immunity == 2 && PlayerImmunity > 0)
			{
				ImmuneCount++;
				continue;
			}
			
			value = 0.0;
				
			if (IsClientInGame(i))
			{
				switch (KickType)
				{
					case 0:
					value = GetRandomFloat(0.0, 100.0);
					case 1:
					value = GetClientAvgLatency(i, NetFlow_Outgoing);
					case 2:
					value = GetClientTime(i);
					case 3:
					value = GetClientTime(i);
				}
				
				if (KickType == 3 && !LowestValuePicked)
				{
					HighestValue = value;
					LowestValuePicked = true;
				}
				
				if (IsClientObserver(i) && SpecKick)
				{			
					SpecFound = true;
					
					if (KickType == 3 && !LowestSpecValuePicked)
					{
						HighestSpecValue = value;
						LowestSpecValuePicked = true;
					}
					
					if (KickType == 3 && value <= HighestSpecValue)
					{
						HighestSpecValue = value;
						HighestSpecValueId = i;
					}
					else if (KickType != 3 && value >= HighestSpecValue)
					{
						HighestSpecValue = value;
						HighestSpecValueId = i;
					}
				} 
				else if (KickType == 3 && value <= HighestValue)
				{
					HighestValue = value;
					HighestValueId = i;
				} 
				else if (KickType != 3 && value >= HighestValue)
				{
					HighestValue = value;
					HighestValueId = i;
				}
			}			
		}
		
		if (Logging == 1)
		{
			LogMessage("===========");
			LogMessage("Connecting player (%s) immunity: %d", AdminName, ConnectingPlayerImmunity);
			LogMessage("Lowest immunity: %d", LowestImmunityLevel);
			LogMessage("Immunity player count: %d", ImmuneCount);
			LogMessage("Max player count: %d", MaxClients);
			LogMessage("===========");
		}
			
		if (Immunity && ImmuneCount == MaxClients)
		{			
			if (Logging == 1)
			{
				LogMessage("Running extra immunity check");
			}
			
			for (new i=1; i<=MaxClients; i++)
			{
				if (!IsClientConnected(i))
				{
					continue;
				}
					
				if (IsFakeClient(i))
				{
					continue;
				}

				new String:PlayerAuth[32];
				GetClientAuthString(i, PlayerAuth, sizeof(PlayerAuth));
				new AdminId:PlayerAdmin = FindAdminByIdentity(AUTHMETHOD_STEAM, PlayerAuth)
				new PlayerImmunity = GetAdminImmunityLevel(PlayerAdmin);
				
				if (PlayerImmunity > LowestImmunityLevel)
				{
					continue;
				}
				
				if (PlayerImmunity >= ConnectingPlayerImmunity)
				{
					continue;
				}
				
				value = 0.0;
				
				if (IsClientInGame(i))
				{
					switch (KickType)
					{
						case 0:
						value = GetRandomFloat(0.0, 100.0);
						case 1:
						value = GetClientAvgLatency(i, NetFlow_Outgoing);
						case 2:
						value = GetClientTime(i);
						case 3:
						value = GetClientTime(i);
					}
					
					if (KickType == 3 && !LowestValuePicked)
					{
						HighestValue = value;
						LowestValuePicked = true;
					}
					
					if (IsClientObserver(i) && SpecKick)
					{			
						SpecFound = true;
						
						if (KickType == 3 && !LowestSpecValuePicked)
						{
							HighestSpecValue = value;
							LowestSpecValuePicked = true;
						}
						
						if (KickType == 3 && value <= HighestSpecValue)
						{
							HighestSpecValue = value;
							HighestSpecValueId = i;
						}
						else if (KickType != 3 && value >= HighestSpecValue)
						{
							HighestSpecValue = value;
							HighestSpecValueId = i;
						}
					} 
					else if (KickType == 3 && value <= HighestValue)
					{
						HighestValue = value;
						HighestValueId = i;
					} 
					else if (KickType != 3 && value >= HighestValue)
					{
						HighestValue = value;
						HighestValueId = i;
					}
				}
			}
		}	
	
		if (SpecFound)
		{
			KickTarget = HighestSpecValueId;
		} else {
			KickTarget = HighestValueId;
		}
						
		if (KickTarget)
		{
			decl String:KickName[32];
			decl String:KickAuthid[32];
			
			if (Logging)
			{
				GetClientName(KickTarget, KickName, sizeof(KickName));
				GetClientAuthString(KickTarget, KickAuthid, sizeof(KickAuthid));
			}
			
			if (ImmuneCount != MaxClients)
			{
				decl String:Reason[255];
				GetConVarString(cvar_KickReason, Reason, sizeof(Reason));
				KickClientEx(KickTarget, "%s", Reason);
				if (Logging == 1)
				{
					LogMessage("%s was kicked", KickName);
					LogMessage("====END====");
				}
				if (Logging == 2)
				{
					LogMessage("%s (%s) connected, %s (%s) was kicked", name, authid, KickName, KickAuthid);
				}
			} else {
				decl String:Reason[255];
				GetConVarString(cvar_KickReasonImmunity, Reason, sizeof(Reason));
				KickClientEx(KickTarget, "%s", Reason);
				if (Logging == 1)
				{
					LogMessage("%s was kicked (Low immunity)", KickName);
					LogMessage("====END====");
				}
				if (Logging == 2)
				{
					LogMessage("%s (%s) connected, %s (%s) was kicked", name, authid, KickName, KickAuthid)
				}
			}
		} 
		else 
		{
			if (Logging == 1)
			{
				LogMessage("No valid client found to kick");
				LogMessage("====END====");
			}
			return;
		}
	}
}