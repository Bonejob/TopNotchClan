/* 
	Extra Cash
		Adds 16000 to every player on spawn 
		
*/


#include <sourcemod>

#define VERSION "0.2"
#define ADMIN_LEVEL ADMFLAG_RESERVATION

new g_iAccount = -1;
new Handle:Switch;
new Handle:Cash;
new g_iStarts;

public Plugin:myinfo = 
{
	name = "Extra Cash",
	author = "Peoples Army",
	description = "Adds Extra Cash On Each Spawn",
	version = VERSION,
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	Switch = CreateConVar("extra_Cash_on","1","1 turns plugin on 0 is off",FCVAR_NOTIFY);
	Cash = CreateConVar("extra_cash_amount","16000","Sets Amount OF Money Given On Spawn",FCVAR_NOTIFY);
	HookEvent("player_spawn" , Spawn);
	HookEvent("round_start", Event_Round_Start, EventHookMode_PostNoCopy);
}

public OnMapStart()
{
	g_iStarts = 0;
}

public Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_iStarts <= 2)
	{
		g_iStarts++;
	}
}

public Spawn(Handle: event , const String: name[] , bool: dontBroadcast)
{
	if (g_iStarts >=1)
	{
		new clientID = GetEventInt(event,"userid");
		new client = GetClientOfUserId(clientID);
		if(GetConVarInt(Switch))
		{
			if (GetUserFlagBits(client) & ADMIN_LEVEL)
			{
				SetMoney(client,GetConVarInt(Cash));
			}
		}
	}
}

public SetMoney(client, amount)
{
	if (g_iAccount != -1)
	{
		SetEntData(client, g_iAccount, amount);
	}	
}