#include <sourcemod>
#include "include/cbaseserver.inc"

enum KickType
{
	Kick_HighestPing,
	Kick_HighestTime,
	Kick_Random,	
};

new g_maxClients;
new sdkVersion;
new Handle:g_IpTrie;

public OnPluginStart()
{
	sdkVersion = GuessSDKVersion();
	g_IpTrie = CreateTrie();
}

public OnMapStart()
{
	g_maxClients = GetMaxClients();	
}

public OnClientPostAdminCheck(client)
{
	decl String:ip[32];
	GetClientIP(client, ip, sizeof(ip));
	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	
	new flags = GetUserFlagBits(client);
	
	if (flags & ADMFLAG_RESERVATION)
	{
		SetSteamForIp(ip, auth);
	}
}

public OnClientPreConnect(const String:name[], const String:pass[], const String:ip[], const String:authid[])
{
	if (GetClientCount(false) < g_maxClients)
	{
		return;	
	}

	new AdminId:admin
	
	if (sdkVersion < SOURCE_SDK_EPISODE2)
	{
		decl String:guessedSteamId[32];
		if (!GetSteamFromIP(ip, guessedSteamId, sizeof(guessedSteamId)))
		{
			return;
		}
		
		PrintToServer("PreConnect From %s (%s) matched to %s", ip, name, authid);

		admin = FindAdminByIdentity(AUTHMETHOD_STEAM, guessedSteamId);
		
		decl String:AdminPass[32];
		if (admin != INVALID_ADMIN_ID && GetAdminPassword(admin, AdminPass, sizeof(AdminPass)))
		{
			/* User has a password set */
			if (!StrEqual(AdminPass, pass))
			{
				return;	
			}	
		}
	}
	else
	{
		admin = FindAdminByIdentity(AUTHMETHOD_STEAM, authid);
	}
	
	if (admin == INVALID_ADMIN_ID)
	{
		return;
	}
	
	if (GetAdminFlag(admin, Admin_Reservation))
	{
		new target = SelectKickClient();
						
		if (target)
		{
			KickClientEx(target, "Slot Reserved");
		}
	}
}

SelectKickClient()
{
	new KickType:type = Kick_HighestPing;
	
	new Float:highestValue;
	new highestValueId;
	
	new Float:highestSpecValue;
	new highestSpecValueId;
	
	new bool:specFound;
	
	new Float:value;
	
	new maxclients = GetMaxClients();
	
	for (new i=1; i<=maxclients; i++)
	{	
		if (!IsClientConnected(i))
		{
			continue;
		}
	
		new flags = GetUserFlagBits(i);
		
		if (IsFakeClient(i) || flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION || CheckCommandAccess(i, "sm_reskick_immunity", ADMFLAG_RESERVATION, false))
		{
			continue;
		}
		
		value = 0.0;
			
		if (IsClientInGame(i))
		{
			if (type == Kick_HighestPing)
			{
				value = GetClientAvgLatency(i, NetFlow_Outgoing);
			}
			else if (type == Kick_HighestTime)
			{
				value = GetClientTime(i);
			}
			else
			{
				value = GetRandomFloat(0.0, 100.0);
			}

			if (IsClientObserver(i))
			{			
				specFound = true;
				
				if (value > highestSpecValue)
				{
					highestSpecValue = value;
					highestSpecValueId = i;
				}
			}
		}
		
		if (value >= highestValue)
		{
			highestValue = value;
			highestValueId = i;
		}
	}
	
	if (specFound)
	{
		return highestSpecValueId;
	}
	
	return highestValueId;
}

bool:GetSteamFromIP(const String:ip[], String:steam[], len)
{
	return GetTrieString(g_IpTrie, ip, steam, len);
}

bool:SetSteamForIp(const String:ip[], const String:steam[])
{
	return SetTrieString(g_IpTrie, ip, steam, true);
}