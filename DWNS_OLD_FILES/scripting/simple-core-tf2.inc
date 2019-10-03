/************************************************************************
*************************************************************************
Simple Plugins TF2 Core Include File
Description:
	Core Team Fortress 2 include file for the Simple Plugins project.
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
$Id: simple-core-tf2.inc 132 2010-01-25 03:30:42Z antithasys $
$Author: antithasys $
$Revision: 132 $
$Date: 2010-01-24 19:30:42 -0800 (Sun, 24 Jan 2010) $
$LastChangedBy: antithasys $
$LastChangedDate: 2010-01-24 19:30:42 -0800 (Sun, 24 Jan 2010) $
$URL: http://sm-simple-plugins.googlecode.com/svn/trunk/Simple%20Plugins%20Core/addons/sourcemod/scripting/include/simple-core-tf2.inc $
$Copyright: (c) Simple Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/
#if defined _simple_core_tf2_included
	#endinput
#endif

#define _simple_core_tf2_included

#tryinclude <tf2>
#tryinclude <tf2_stocks>

#define CORE_TF2_INC_VERSION "0.1.$Rev: 132 $"

//m_nPlayerCond Values
#define TF2_PLAYERCOND_SLOWED    		(1<<0)    //Zoomed / Arrow drawn / minigun spinning
#define TF2_PLAYERCOND_ZOOMED      	(1<<1)    //FOV change (sniper)
#define TF2_PLAYERCOND_DISGUISING			(1<<2)
#define TF2_PLAYERCOND_DISGUISED    	(1<<3)
#define TF2_PLAYERCOND_SPYCLOAK				(1<<4)
#define TF2_PLAYERCOND_UBERCHARGED	(1<<5)
#define TF2_PLAYERCOND_TELEGLOW 			(1<<6)
#define TF2_PLAYERCOND_TAUNT        	(1<<7)
#define TF2_PLAYERCOND_UBERFADING    (1<<8)
//#define TF2_PLAYERCOND_							(1<<9)
#define TF2_PLAYERCOND_PREPTELE       (1<<10)    //Player is teleporting
#define TF2_PLAYERCOND_KRITS        		(1<<11)    //Fired for krit uber and at end of round
//#define TF2_PLAYERCOND_							(1<<12)
#define TF2_PLAYERCOND_FEIGHDEATH    	(1<<13)    //Dmg reduction from dead ringer
#define TF2_PLAYERCOND_BONKD        	(1<<14)    //Atomic bonk
#define TF2_PLAYERCOND_DAZED        	(1<<15)    //When a player gets dazed (atomic bomb / airblasted / baseball bat)
#define TF2_PLAYERCOND_BUFFBANNER    (1<<16)    //Removed at resupply locker as well    
#define TF2_PLAYERCOND_CHARGE        (1<<17)    //Demoman charge
#define TF2_PLAYERCOND_HEADGAINED    (1<<18)    //Demoman decap - first only
#define TF2_PLAYERCOND_HEALING        (1<<19)    //Player is being healed
#define TF2_PLAYERCOND_ONFIREALERT    (1<<20)    //FIRE FIRE FIRE
#define TF2_PLAYERCOND_OVERHEALED    (1<<21)    //Player is overhealed 
#define TF2_PLAYERCOND_JARATE      		(1<<22)

enum TFGameType
{
	TFGameMode_Unknown,
	TFGameMode_CP,
	TFGameMode_CTF,
	TFGameMode_ARENA,
	TFGameMode_PL,
	TFGameMode_PLR,
	TFGameMode_KOTH
};

stock TF2_GetPlayerCond(client)
{
	return GetEntProp(client, Prop_Send, "m_nPlayerCond");
}

stock TF2_SetPlayerCond(client,playerCond)
{
	SetEntProp(client, Prop_Send, "m_nPlayerCond", playerCond);
}

stock TF2_GetNumHealers(client)
{
	return GetEntProp(client, Prop_Send, "m_nNumHealers");
}

stock bool:TF2_IsPlayerZoomed(client)
{
	new pcond = TF2_GetPlayerCond(client);
	return pcond >= 0 ? ((pcond & TF2_PLAYERCOND_ZOOMED) != 0) : false;
}

stock bool:TF2_IsPlayerHealing(client)
{
	new pcond = TF2_GetPlayerCond(client);
	return pcond >= 0 ? ((pcond & TF2_PLAYERCOND_HEALING) != 0) : false;
}

stock bool:TF2_IsPlayerOverHealing(client)
{
	new pcond = TF2_GetPlayerCond(client);
	return pcond >= 0 ? ((pcond & TF2_PLAYERCOND_OVERHEALED) != 0) : false;
}

stock bool:TF2_IsPlayerTaunt(client)
{
	new pcond = TF2_GetPlayerCond(client);
	return pcond >= 0 ? ((pcond & TF2_PLAYERCOND_TAUNT) != 0) : false;
}

stock bool:TF2_IsPlayerSlowed(client)
{
	new pcond = TF2_GetPlayerCond(client);
	return pcond >= 0 ? ((pcond & TF2_PLAYERCOND_SLOWED) != 0) : false;
}

stock bool:TF2_IsPlayerDisguised(client)
{
	new pcond = TF2_GetPlayerCond(client);
	return pcond >= 0 ? ((pcond & TF2_PLAYERCOND_DISGUISED) != 0) : false;
}

stock bool:TF2_IsPlayerChangingCloak(client)
{
	if(TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		if(GetGameTime() <= GetEntPropFloat(client, Prop_Send, "m_flInvisChangeCompleteTime"))
		{
			return true;
		}
	}
	return false;
}

stock bool:TF2_IsPlayerCloaked(client)
{
	new pcond = TF2_GetPlayerCond(client);
	return pcond >= 0 ? ((pcond & TF2_PLAYERCOND_SPYCLOAK) != 0) : false;
}

stock bool:TF2_IsPlayerFeignDeath(client)
{
	new pcond = TF2_GetPlayerCond(client);
	return pcond >= 0 ? ((pcond & TF2_PLAYERCOND_FEIGHDEATH) != 0) : false;
}

stock bool:TF2_IsPlayerBlur(client)
{
	new pcond = TF2_GetPlayerCond(client);
	return pcond >= 0 ? ((pcond & TF2_PLAYERCOND_BONKD) != 0) : false;
}

stock bool:TF2_IsPlayerChargeReleased(client)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
	{
		new String:classname[64];
		TF2_GetWeaponClass(index, classname, sizeof(classname));
		
		if( StrEqual(classname, "CWeaponMedigun") )
		{
			return bool:GetEntProp(index, Prop_Send, "m_bChargeRelease");
		}
	}		
	return false;
}

stock bool:TF2_IsPlayerUber(client)
{
	new pcond = TF2_GetPlayerCond(client);
	return pcond >= 0 ? ((pcond & (TF2_PLAYERCOND_UBERCHARGED | TF2_PLAYERCOND_KRITS)) != 0) : false;
}

stock bool:TF2_IsPlayerInvuln(client)
{
	new pcond = TF2_GetPlayerCond(client);
	return pcond >= 0 ? ((pcond & TF2_PLAYERCOND_UBERCHARGED) != 0) : false;
}

stock bool:TF2_IsPlayerCrits(client)
{
	new pcond = TF2_GetPlayerCond(client);
	return pcond >= 0 ? ((pcond & TF2_PLAYERCOND_KRITS) != 0) : false;
}

stock bool:TF2_IsPlayerOnFire(client)
{
	new pcond = TF2_GetPlayerCond(client);
	return pcond >= 0 ? ((pcond & TF2_PLAYERCOND_ONFIREALERT) != 0) : false;
}

stock TF2_SetPlayerCloak(client, bool:enabled)
{
	new playerCond = TF2_GetPlayerCond(client);
	if (enabled)
		TF2_SetPlayerCond(client, (playerCond | TF2_PLAYERCOND_SPYCLOAK));
	else
	TF2_SetPlayerCond(client, (playerCond & (~TF2_PLAYERCOND_SPYCLOAK)));
}

stock Float:TF2_GetClassSpeed(TFClassType:class)
{
	switch (class)
	{
		case TFClass_Scout:     return 400.0;
		case TFClass_Soldier:   return 240.0;
		case TFClass_DemoMan:   return 280.0;
		case TFClass_Medic:     return 320.0;
		case TFClass_Pyro:      return 300.0;
		case TFClass_Spy:       return 300.0;
		case TFClass_Engineer:  return 300.0;
		case TFClass_Sniper:    return 300.0;
		case TFClass_Heavy:     return 230.0;
	}
	return 0.0;
}

stock Float:TF2_GetPlayerClassSpeed(client)
{
	if (TF2_IsPlayerSlowed(client))
		return 80.0;
	else
	return TF2_GetClassSpeed(TF2_GetPlayerClass(client));
}

stock Float:TF2_GetPlayerSpeed(client)
{
	if(client > 0)
	{
		new Float:vec[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);
		return GetVectorLength(vec);
	}
	return 0.0;
}

stock Float:TF2_SetPlayerSpeed(client, Float:speed)
{
	if(client > 0)
	{
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", speed);
	}
}

stock Float:TF2_SetPlayerDefaultSpeed(client)
{
	if(client > 0)
	{
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", TF2_GetClassSpeed(TF2_GetPlayerClass(client)));
	}
}

stock TF2_GetPlayerDefaultHealth(client)
{
	if(client > 0)
	{
		return GetEntProp(client, Prop_Data, "m_iMaxHealth");
	}  
	return 100;
}

stock TF2_GetPlayerMaxHealth(client)
{
	if(client > 0)
	{	
		switch (TF2_GetPlayerClass(client))
		{
			case TFClass_Scout:			return 185;
			case TFClass_Soldier:		return 300;
			case TFClass_DemoMan:		return 260;
			case TFClass_Medic:			return 225;
			case TFClass_Pyro:			return 260;
			case TFClass_Spy:				return 185;
			case TFClass_Engineer:	return 185;
			case TFClass_Sniper:		return 185;
			case TFClass_Heavy:			return 450;
		}
	}
	return 100;
}

stock TF2_GetCurrentWeaponClass(client, String:name[], maxlength)
{
	if( client > 0 )
	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (index > 0)
			GetEntityNetClass(index, name, maxlength);
	}
}

stock TF2_GetWeaponClass(index, String:name[], maxlength)
{
	if (index > 0)
		GetEntityNetClass(index, name, maxlength);
}

stock TF2_GetWeaponEdictName(index, String:name[], maxlength)
{
	if (index > 0)
		GetEdictClassname(index, name, maxlength);
}

stock bool:TF2_CurrentWeaponEqual(client, String:name[])
{
	if( client > 0 )
	{
		new String:classname[64];
		TF2_GetCurrentWeaponClass(client, classname, 64);
		return StrEqual(classname, name);
	}
	return false;
}

stock TF2_GetCurrentWeapon(any:client)
{
	if( client > 0 )
	{
		new weaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		return weaponIndex;
	}
	return -1;
}

stock TF2_GetSlotAmmo(any:client, slot)
{
	if( client > 0 )
	{
		new offset = FindDataMapOffs(client, "m_iAmmo") + ((slot + 1) * 4);
		return GetEntData(client, offset, 4);
	}
	return -1;
}

stock TF2_GetSlotClip(any:client, slot, clip = 1)
{
	if( client > 0 )
	{
		new weaponIndex = GetPlayerWeaponSlot(client, slot);
		if( weaponIndex != -1 )
		{
			if (clip == 1)
			{
				return GetEntProp( weaponIndex, Prop_Send, "m_iClip1" );
			}
			else
			{
				return GetEntProp( weaponIndex, Prop_Send, "m_iClip2" );
			}
		}
	}
	return -1;
}

stock TF2_SetSlotAmmo(any:client, slot, ammo)
{
	if( client > 0 )
	{
		new offset = FindDataMapOffs(client, "m_iAmmo") + ((slot + 1) * 4);
		SetEntData(client, offset, ammo);
	}
}

stock TF2_GetSlotWeapon(any:client, slot)
{
	if( client > 0 && slot >= 0)
	{
		new weaponIndex = GetPlayerWeaponSlot(client, slot-1);
		return weaponIndex;
	}
	return -1;
}

stock DeletePlayerSlot(any:client, deleteSlot, afterSlot)
{
	if( IsClientInGame(client) && IsPlayerAlive(client) )
	{
		new weaponIndex = GetPlayerWeaponSlot(client, deleteSlot);
		if( weaponIndex != -1 )
		{
			RemovePlayerItem(client, weaponIndex);
			RemoveEdict(weaponIndex);
			TF2_RemoveWeaponSlot(client, deleteSlot);
			
			if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == -1)
			{
				ClientCommand(client, "slot%d", afterSlot);
			}
		}	
	}			
}

stock bool:TF2_IsAllowPlantSapper(client)
{
	if( client > 0 )
	{
		if(TF2_CurrentWeaponEqual(client, "CTFWeaponBuilder"))
		{
			new weaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (weaponIndex > 0)
			{
				if(GetEntProp(weaponIndex, Prop_Send, "m_iBuildState")==2)
				{
					return true;
				}
			}
		}
	}
	return false;
}

stock bool:TF2_EdictNameEqual(entity, String:name[])
{
	if( entity > 0 )
	{
		if(IsValidEdict(entity))
		{
			new String:edictName[64];
			GetEdictClassname(entity, edictName, sizeof(edictName)); 
			return StrEqual(edictName, name);
		}
	}
	return false;
}

stock TF2_GetPlayerUberLevel(client)
{
	new index = GetPlayerWeaponSlot(client, 1);
	
	if (index > 0)
	{
		new String:classname[64];
		TF2_GetWeaponClass(index, classname, sizeof(classname));
		
		if(StrEqual(classname, "CWeaponMedigun"))
		{
			return RoundFloat(GetEntPropFloat(index, Prop_Send, "m_flChargeLevel")*100);
		}
		
	}
	return 0;
}

stock TF2_SetPlayerUberLevel(client, uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
	{
		new String:classname[64];
		TF2_GetWeaponClass(index, classname, sizeof(classname));
		
		if(StrEqual(classname, "CWeaponMedigun"))
		{
			SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
		}
	}
}

stock TF2_GetHealingTarget(client)
{
	new String:classname[64];
	TF2_GetCurrentWeaponClass(client, classname, sizeof(classname));
	
	if(StrEqual(classname, "CWeaponMedigun"))
	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( GetEntProp(index, Prop_Send, "m_bHealing") == 1 )
		{
			return GetEntPropEnt(index, Prop_Send, "m_hHealingTarget");
		}
	}
	return -1;
}

stock bool:TF2_IsReadyFeignDeath(client)
{
	if(TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		return bool:GetEntProp(client, Prop_Send, "m_bFeignDeathReady");
	}
	return false;
}

stock TF2_GetPlayerCloakMeter(client)
{
	if(TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		return RoundFloat(GetEntPropFloat(client, Prop_Send, "m_flCloakMeter"));
	}
	return 100;
}

stock TF2_SetPlayerCloakMeter(client, cloakMeter)
{
	if(TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", cloakMeter*1.0);
	}
}

stock TF2_GetPlayerMetalAmount(client)
{
	return GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 4);
}

stock TF2_SetPlayerMetalAmount(client, metal)
{
	SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), metal, 4);  
}

stock TF2_GetPlayerSnipCharge(client)
{
	new index = GetPlayerWeaponSlot(client, 0);
	if (index > 0)
	{
		new String:classname[64];
		TF2_GetWeaponClass(index, classname, sizeof(classname));
		
		if(StrEqual(classname, "CTFSniperRifle"))
		{
			return RoundFloat(GetEntPropFloat(index, Prop_Send, "m_flChargedDamage") * 0.666);
		}
		
	}
	return 0;
}

stock TF2_SetPlayerSnipCharge(client, chargelevel)
{
	new index = GetPlayerWeaponSlot(client, 0);
	if (index > 0)
	{
		new String:classname[64];
		TF2_GetWeaponClass(index, classname, sizeof(classname));
		
		if(StrEqual(classname, "CTFSniperRifle"))
		{
			SetEntPropFloat(index, Prop_Send, "m_flChargedDamage", chargelevel * 1.5);
		}
	}
}

stock TF2_GetRandomClass() 
{
	return GetRandomInt(1, 9);
}

stock TF2_GetClassPlayers(team, cls) 
{
	new numPlayers = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientConnected(i))
		{
			if(GetClientTeam(i) == team && TF2_GetPlayerClass(i) == TFClassType:cls)
			{
				numPlayers++;
			}
		}
	}
	return numPlayers;
} 

stock bool:TF2_InSetup()
{
	new iTimerEnt = FindEntityByClassname(-1, "team_round_timer");
	if (iTimerEnt != -1)
	{
		if (!GetEntProp(iTimerEnt, Prop_Send, "m_nState"))
			return true;
	}
	return false;
}

stock bool:TF2_HasAmmo(client, weaponslot, bool:firing = false)
{
	new oAmmoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	new oClip1Offset = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	new oClip2Offset = FindSendPropInfo("CTFWeaponBase", "m_iClip2");
	
	new iReserveAmmo = GetEntData(client, oAmmoOffset + ((weaponslot + 1) * 4));
	new iClip1Ammo = GetEntData(GetPlayerWeaponSlot(client, weaponslot), oClip1Offset);
	new iClip2Ammo = GetEntData(GetPlayerWeaponSlot(client, weaponslot), oClip2Offset);
	new iTotalAmmo;
	if (firing)
	{
		iClip1Ammo -= 1;
	}
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Pyro:
		{
			iTotalAmmo = iReserveAmmo - 1;
		}
		case TFClass_Heavy:
		{
			iTotalAmmo = iReserveAmmo - 1;
		}
		case TFClass_Spy:
		{
			iTotalAmmo = iClip1Ammo + iClip2Ammo;
		}
		default:
		{
			iTotalAmmo = iClip1Ammo + iReserveAmmo;
		}
	}
	
	PrintToChatAll("Clip1 %i, Clip2 %i, Reserve %i, Total %i", iClip1Ammo, iClip2Ammo, iReserveAmmo, iTotalAmmo);
	return (iTotalAmmo > 0) ? true : false;
}

stock TFGameType:TF2_GetGameType()
{
	new String:mapName[256];
	GetCurrentMap(mapName, sizeof(mapName));
	if(StrContains( mapName, "arena_", false ) != -1)
	{
		return TFGameMode_ARENA;
	}
	else if(StrContains( mapName, "cp_", false ) != -1)
	{
		return TFGameMode_CP;
	}
	else if(StrContains( mapName, "ctf_", false ) != -1)
	{
		return TFGameMode_CTF;
	}
	else if(StrContains( mapName, "pl_", false ) != -1)
	{
		return TFGameMode_PL;
	}
	else if(StrContains( mapName, "plr_", false ) != -1)
	{
		return TFGameMode_PLR;
	}
	else if(StrContains( mapName, "koth_", false ) != -1)
	{
		return TFGameMode_KOTH;
	}
	return TFGameMode_Unknown;
}


stock TF2_GetPlayerDominations(client)
{
	new iOffset = FindSendPropInfo("CTFPlayerResource", "m_iActiveDominations"),
		ent = FindEntityByClassname(-1, "tf_player_manager");
	if (ent != -1)
		return GetEntData(ent, (iOffset + client*4), 4);	
	return 0;
}

stock TF2_GetTeamDominations(team)
{
	new iDominations;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team)
			iDominations += TF2_GetPlayerDominations(i);
	}
	return iDominations;
}

/**
* checks if a client is only class
* @param client		=	client index
* @param class		= 	player class
* Valid Classes:
* TFClass_Medic; TFClass_Engineer; TFClass_Sniper; TFClass_Spy; TFClass_Heavy
* TFClass_Scout; TFClass_Demoman; TFClass_Soldier; TFClass_Pyro
*/

stock bool:TF2_IsClientOnlyClass(client, TFClassType:class)
{
	if (TFClassType:TF2_GetPlayerClass(client) != class)
		return false;
	new clientTeam = GetClientTeam(client);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == clientTeam && TFClassType:TF2_GetPlayerClass(i) == class)
			return false;
	}
	return true;
}

stock TF2_RemoveRagdolls()
{
	new iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "tf_ragdoll")) != -1)
		AcceptEntityInput(iEnt, "Kill");
}

stock bool:TF2_IsClientUberCharged(client)
{
	if (!IsPlayerAlive(client))
		return false;
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (class == TFClass_Medic)
	{			
		new entityIndex = GetPlayerWeaponSlot(client, 1);
		new Float:chargeLevel = GetEntPropFloat(entityIndex, Prop_Send, "m_flChargeLevel");
		if (chargeLevel >= 0.40)				
			return true;				
	}
	return false;
}

stock bool:TF2_IsClientUbered(client)
{
	if (GetEntProp(client, Prop_Send, "m_nPlayerCond") & 32)
		return true;
	return false;
}

/**
valid buildings:
obj_sentrygun
obj_dispenser
obj_teleporter
*/
stock bool:TF2_DoesClientHaveBuilding(client, const String:building[])
{
	new iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, building)) != -1)
	{
		if (GetEntDataEnt2(iEnt, FindSendPropInfo("CBaseObject", "m_hBuilder")) == client)
			return true;
	}
	return false;
}

stock bool:TF2_DoesClientHaveBuildings(client)
{
	new iMaxEntities = GetMaxEntities();
	new iOwnerOffset = FindSendPropInfo("CBaseObject", "m_hBuilder");
	for (new x = MaxClients + 1; x <= iMaxEntities; x++)
	{
		if (!IsValidEntity(x))
		{
			continue;
		}
		decl String:sNetClass[32];
		GetEntityNetClass(x, sNetClass, sizeof(sNetClass));
		if (strcmp(sNetClass, "CObjectSentrygun") == 0 
		|| strcmp(sNetClass, "CObjectTeleporter") == 0 
		|| strcmp(sNetClass, "CObjectDispenser") == 0) 
		{
			if (GetEntDataEnt2(x, iOwnerOffset) == client)
			{
				return true;
			}
		}
	}
	return false;
}

stock TF2_GetClientScore(client)
{	
	return TF2_GetPlayerResourceData(client, TFResource_TotalScore);
}

stock TF2_DestroyBuildings(client)
{
	new iMaxEntities = GetMaxEntities();
	new iOwnerOffset = OWNEROFFSET;
	for (new i = MaxClients + 1; i <= iMaxEntities; i++)
	{
		if (!IsValidEntity(i))
		{
			continue;
		}
		decl String:sNetClass[32];
		GetEntityNetClass(i, sNetClass, sizeof(sNetClass));
		if (strcmp(sNetClass, "CObjectSentrygun") == 0 
		|| strcmp(sNetClass, "CObjectTeleporter") == 0 
		|| strcmp(sNetClass, "CObjectDispenser") == 0)
		{
			if (GetEntDataEnt2(i, iOwnerOffset) == client)
			{
				SetVariantInt(9999);
				AcceptEntityInput(i, "RemoveHealth");
			}
		}
	}
}

stock TF2_SetTeamScore(team, score)
{
	new iEnt = FindEntityByClassname(-1, "tf_gamerules");
	if (iEnt != -1)
	{
		SetVariantInt(score-GetTeamScore(team));
		AcceptEntityInput(iEnt, team==2?"AddRedTeamScore":"AddBlueTeamScore");
	}
}

