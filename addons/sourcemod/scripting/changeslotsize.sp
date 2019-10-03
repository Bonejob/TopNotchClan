#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Change visible Slot size",
	author = "FeuerSturm",
	description = "Change visible Slot size depending on player count",
	version = "1.0",
	url = "http://community.dodsourceplugins.net"
}

#define PLAYERS 23
#define LOW_SLOTS 24
#define HIGH_SLOTS 32

new Handle:VisMaxPl = INVALID_HANDLE

public OnMapStart()
{
	VisMaxPl = FindConVar("sv_visiblemaxplayers")
	CheckSlots()
}

public OnClientPutInServer(client)
{
	CheckSlots()
}

public OnClientDisconnect_Post(client)
{
	CheckSlots()
}

public CheckSlots()
{
	new activeplayers = GetClientCount(false)
	if(activeplayers >= PLAYERS)
	{
		SetConVarInt(VisMaxPl, HIGH_SLOTS)
	}
	else
	{
		SetConVarInt(VisMaxPl, LOW_SLOTS)
	}
}
