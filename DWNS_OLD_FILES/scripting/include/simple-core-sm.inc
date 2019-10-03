/************************************************************************
*************************************************************************
Simple Plugins SourceMod Core Include File
Description:
	Core SourceMod include file for the Simple Plugins project.
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
$Id: simple-core-sm.inc 139 2010-04-12 23:15:37Z antithasys $
$Author: antithasys $
$Revision: 139 $
$Date: 2010-04-12 16:15:37 -0700 (Mon, 12 Apr 2010) $
$LastChangedBy: antithasys $
$LastChangedDate: 2010-04-12 16:15:37 -0700 (Mon, 12 Apr 2010) $
$URL: http://sm-simple-plugins.googlecode.com/svn/trunk/Simple%20Plugins%20Core/addons/sourcemod/scripting/include/simple-core-sm.inc $
$Copyright: (c) Simple Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/
#if defined _simple_core_sm_included
	#endinput
#endif
#define _simple_core_sm_included

#include <sdktools>
#tryinclude <simple-core-l4d>
#tryinclude <simple-core-css>
#tryinclude <simple-core-ins>
#tryinclude <simple-core-tf2>
#tryinclude <simple-core-css>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

#define CORE_SM_INC_VERSION "0.1.$Rev: 139 $"

#define IN  (0x0001 | 0x0010)
#define OUT (0x0002 | 0x0008)

enum e_SupportedMods
{
	GameType_Unknown,
	GameType_AOC,
	GameType_CSS,
	GameType_DOD,
	GameType_FF,
	GameType_HIDDEN,
	GameType_HL2DM,
	GameType_INS,
	GameType_L4D,
	GameType_L4D2,
	GameType_NEO,
	GameType_SGTLS,
	GameType_TF,
	GameType_DM,
	GameType_ZPS
};

enum e_Teams
{
	Unknown,
	Spectator,
	Team1,
	Team2
};

new g_aCurrentTeams[e_Teams];
new e_SupportedMods:g_CurrentMod;
new String:g_sGameName[e_SupportedMods][32] = {	"Unknown",
																							"Age of Chivalry",
																							"Counter Strike",
																							"Day Of Defeat",
																							"Fortress Forever",
																							"Hidden: Source",
																							"Half Life 2: Deathmatch",
																							"Insurgency",
																							"Left 4 Dead",
																							"Left 4 Dead 2",
																							"Neotokyo",
																							"Stargate TLS",
																							"Team Fortress 2",
																							"Dark Messiah",
																							"Zombie Panic: Source"
																						};

new g_FilteredEntity = -1;

stock bool:RemovePunctuation(String:input[], String:buffer[], maxlength)
{
	new len = strlen(input);
	new bool:found;
	for (new i=len-1; i >= 0; i--)
	{
		if (!IsCharAlpha(input[i]))
		{
			decl String:sBuffer[32];
			strcopy(sBuffer, sizeof(sBuffer), buffer);
			Format(buffer, maxlength, "%s%s", sBuffer, input[i]);
			input[i] = '\0';
			found = true;
		}
	}
	return found;
}

stock bool:IsValidClient(client, bool:nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
    { 
      return false; 
    } 
    return IsClientInGame(client); 
}

stock bool:IsValidAdmin(client, const String:flags[])
{
	new ibFlags = ReadFlagString(flags);
	if ((GetUserFlagBits(client) & ibFlags) == ibFlags)
	{
		return true;
	}
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	return false;
}

stock ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
	}
	timer = INVALID_HANDLE;
}

stock GetClientScore(client)
{
	switch (g_CurrentMod)
	{
		case GameType_TF:
		{
			return TF2_GetClientScore(client);
		}
		case GameType_DOD:
		{
			// something
		}
		default:
		{
			return 0;  //need to find basic frags
		}
	}
	
	return 0;
}

stock RestartRound()
{
	switch (g_CurrentMod)
	{
		default:
		{
			ServerCommand("mp_restartgame 1");
		}
	}
}

stock ResetGameScores(e_SupportedMods:mod)
{
	switch (mod)
	{
		default:
		{
			//something
		}
	}
}

stock MovePlayer(client, team)
{
	switch (g_CurrentMod)
	{
		case GameType_CSS:
		{
			CS_SwitchTeam(client, team);
		}
		default:
		{
			ChangeClientTeam(client, team);
		}
	}
}

stock RespawnPlayer(client)
{
	switch (g_CurrentMod)
	{
		case GameType_CSS:
		{
			CS_RespawnPlayer(client);
		}
		case GameType_TF:
		{
			TF2_RespawnPlayer(client);
		}
		case GameType_INS:
		{
			FakeClientCommand(client, "kill");
		}
		default:
		{
			//
		}
	}
}

stock bool:CheckExtStatus(const String:extension[], bool:required = false, bool:logerrors = true)
{
	decl String:sExtError[256];
	new iExtStatus = GetExtensionFileStatus(extension, sExtError, sizeof(sExtError));
	if (iExtStatus == -2)
	{
		if (logerrors)
		{
			LogMessage("%s extension was not found.", extension);
		}
		if (logerrors && required)
		{
			LogMessage("Plugin FAILED TO LOAD.");
			SetFailState("Required extension was not found.");
		}
		return false;
	}
	if (iExtStatus == -1 || iExtStatus == 0)
	{
		if (logerrors)
		{
			LogMessage("%s extension is loaded with errors.", extension);
			LogMessage("Status reported was [%s].", sExtError);
		}
		if (logerrors && required)
		{
			LogMessage("Plugin FAILED TO LOAD.");
			SetFailState("Required extension is loaded with errors.");
		}
		return false;
	}
	if (iExtStatus == 1)
	{
		LogMessage("%s extension is loaded.", extension);
	}
	return true;
}

stock bool:EdictEqual(ent, const String:name[])
{
	if (ent != -1 && IsValidEdict(ent))
	{
		new String:edictName[32];
		GetEdictClassname( ent, edictName, sizeof(edictName));
		return StrEqual(edictName, name);
	}
	return false;
}

stock bool:CanSeeTarget( any:origin, Float:pos[3], any:target, Float:targetPos[3], Float:range, bool:throughPlayer=true, bool:throughBuild=true)
{
	new Float:distance;
	
	distance = GetVectorDistanceMeter(pos, targetPos);
	if (distance >= range)
	{
		return false;
	}
	
	new Handle:TraceEx = INVALID_HANDLE;
	new hitEnt = -1;
	new Float:hitPos[3];
	g_FilteredEntity = origin;
	TraceEx = TR_TraceRayFilterEx(pos, targetPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter);
	hitEnt = TR_GetEntityIndex(TraceEx);
	TR_GetEndPosition(hitPos, TraceEx);
	if (GetVectorDistanceMeter( hitPos, targetPos) <= 1.0 )
	{
		if (throughPlayer)
		{
			new String:edictName[64];
			GetEdictClassname( hitEnt, edictName, sizeof(edictName)); 
			if(StrEqual(edictName, "player"))  
			{
				GetEntPropVector( hitEnt, Prop_Data, "m_vecAbsOrigin", pos);
				if (GetVectorDistanceMeter(pos, targetPos) > 1.0)
				{
					g_FilteredEntity = hitEnt;
					TraceEx = TR_TraceRayFilterEx( hitPos, targetPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter);
					hitEnt = TR_GetEntityIndex(TraceEx);
					TR_GetEndPosition(hitPos, TraceEx);
				}
				else
				{
					pos = targetPos;
				}
			}
		}		
		if (throughBuild)
		{
			new String:edictName[64];
			GetEdictClassname(hitEnt, edictName, sizeof(edictName)); 
			if (StrEqual(edictName, "obj_dispenser")
			|| StrEqual(edictName, "obj_sentrygun") 
			||	StrEqual(edictName, "obj_teleporter_entrance") 
			||	StrEqual(edictName, "obj_teleporter_exit")
			||	StrEqual(edictName, "obj_attachment_sapper")
			)
			{
				GetEntPropVector(hitEnt, Prop_Data, "m_vecAbsOrigin", pos);
				if (GetVectorDistanceMeter(pos, targetPos) > 1.0)
				{
					g_FilteredEntity = hitEnt;
					TraceEx = TR_TraceRayFilterEx( hitPos, targetPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter);
					hitEnt = TR_GetEntityIndex(TraceEx);
					TR_GetEndPosition(hitPos, TraceEx);
				}
				else
				{
					pos = targetPos;
				}
			}
		}		
	}
	if (GetVectorDistanceMeter(hitPos, targetPos) <= 1.0)
	{
		return true;
	}
	return false;
}

stock bool:IsEntLimitReached()
{
	new maxclients = GetMaxClients();
	new maxents = GetMaxEntities();
	new i, c = 0;
	for (i = maxclients; i <= maxents; i++)
	{
		if (IsValidEntity(i))
			c += 1;
	}
	if (c >= (maxents-16))
	{
		PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
		LogError("Entity limit is nearly reached: %d/%d", c, maxents);
		return true;
	}
	else
	return false;
}

public bool:TraceFilter(ent, contentMask)
{
	return (ent == g_FilteredEntity) ? false : true;
}

stock Float:UnitToMeter(Float:distance)
{
	return distance / 50.00;
}

stock Float:MeterToUnit(Float:distance)
{
	return distance * 50.00;
}

stock Float:GetVectorDistanceMeter(const Float:vec1[3], const Float:vec2[3], bool:squared=false) 
{
	return UnitToMeter( GetVectorDistance( vec1, vec2, squared ) );
}

stock PrePlayParticle(String:particlename[])
{
	if (IsValidEntity(0))
	{
		new particle = CreateEntityByName("info_particle_system");
		if (IsValidEdict(particle))
		{
			new String:tName[32];
			GetEntPropString(0, Prop_Data, "m_iName", tName, sizeof(tName));
			DispatchKeyValue(particle, "targetname", "tf2particle");
			DispatchKeyValue(particle, "parentname", tName);
			DispatchKeyValue(particle, "effect_name", particlename);
			DispatchSpawn(particle);
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent", 0, particle, 0);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
			CreateTimer(0.01, DeleteParticles, particle);
		}
	}
}

stock ShowParticle(String:particlename[], Float:time, Float:pos[3], Float:ang[3]=NULL_VECTOR)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
	else
	{
		LogError("ShowParticle: could not create info_particle_system");
	}	
}

stock any:ShowParticleEntity(ent, String:particleType[], Float:time, Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		new Float:pos[3];
		new Float:ang[3];
		new String:tName[32];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		AddVectors(pos, addPos, pos);
		GetEntPropVector(ent, Prop_Send, "m_angRotation", ang);
		AddVectors(ang, addAngle, ang);
		
		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		//AcceptEntityInput(particle, "SetParent", ent, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
	else
	{
		LogError("AttachParticle: could not create info_particle_system");
	}
	
	return particle;
}

stock AttachParticle(ent, String:particleType[], Float:time, Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		new Float:pos[3];
		new Float:ang[3];
		new String:tName[32];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		AddVectors(pos, addPos, pos);
		GetEntPropVector(ent, Prop_Send, "m_angRotation", ang);
		AddVectors(ang, addAngle, ang);
		
		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", ent, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
	else
	{
		LogError("AttachParticle: could not create info_particle_system");
	}
}

stock AttachParticleBone(ent, String:particleType[], String:attachBone[], Float:time, Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		new String:tName[32];
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", ent, ent, 0);
		SetVariantString(attachBone);
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		ActivateEntity(particle);
		
		TeleportEntity(particle, addPos, addAngle, NULL_VECTOR);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
}

stock any:AttachLoopParticle(ent, String:particleType[], Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		new Float:pos[3];
		new Float:ang[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		AddVectors(pos, addPos, pos);
		GetEntPropVector(ent, Prop_Send, "m_angRotation", ang);
		AddVectors(ang, addAngle, ang);
		
		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		new String:tName[32];
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", ent, ent, 0);
		//		SetVariantString(attachBone);
		//		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		ActivateEntity(particle);
		
		AcceptEntityInput(particle, "start");
	}
	return particle;
}

stock any:AttachLoopParticleBone(ent, String:particleType[], String:attachBone[], Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR)
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		new String:tName[32];
		GetEntPropString(ent, Prop_Data, "m_iName", tName, sizeof(tName));
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", ent, ent, 0);
		SetVariantString(attachBone);
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		ActivateEntity(particle);
		
		TeleportEntity(particle, addPos, addAngle, NULL_VECTOR);
		AcceptEntityInput(particle, "start");
	}
	return particle;
}

stock DeleteLoopParticle(any:particle, Float:delay = 0.0)
{
	if (particle != -1)
	{
		if (IsValidEdict(particle))
		{
			new String:classname[32];
			GetEdictClassname(particle, classname, sizeof(classname));
			if (StrEqual(classname, "info_particle_system", false))
			{
				ActivateEntity(particle);
				AcceptEntityInput(particle, "stop");
				CreateTimer(delay, DeleteParticles, particle);
			}
		}
	}
} 

public Action:DeleteParticles(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		new String:classname[32];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			RemoveEdict(particle);
		}
	}
}

public ScreenFade(client, red, green, blue, alpha, duration, type)
{
	new Handle:msg;
	
	msg = StartMessageOne("Fade", client);
	BfWriteShort(msg, 255);
	BfWriteShort(msg, duration);
	BfWriteShort(msg, type);
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

public Action:UnFade(Handle:timer, any:client)
{
	if (client)
	{
		if (IsClientInGame(client))
		{
			if (IsPlayerAlive(client))
			{
				ScreenFade(client, 0, 0, 0, 0, 2000, IN);
			}
		}
	}
}

stock StringToUpper(String:target[], String:source[])
{
	for (new i = 0; i < strlen(source); i++)
	{
		target[i] = CharToUpper(source[i]);		
	}
}

stock StringToLower(String:target[], String:source[])
{
	for (new i = 0; i < strlen(source); i++)
	{
		target[i] = CharToLower(source[i]);		
	}
}

stock FindRandomPlayer() 
{ 
	new client; 
	do 
	{ 
		client = GetRandomInt(1, MAXPLAYERS + 1); 
	} while (!IsValidClient(client)); 
	return client; 
}

stock e_SupportedMods:GetCurrentMod()
{
	new String:sGameType[64];
	GetGameFolderName(sGameType, sizeof(sGameType));
	
	if (StrEqual(sGameType, "aoc", false))
	{
		return GameType_AOC;
	}
	if (StrEqual(sGameType, "cstrike", false))
	{
		return GameType_CSS;
	}
	if (StrEqual(sGameType, "dod", false))
	{
		return GameType_DOD;
	}
	if (StrEqual(sGameType, "ff", false))
	{
		return GameType_FF;
	}
	if (StrEqual(sGameType, "hidden", false))
	{
		return GameType_HIDDEN;
	}
	if (StrEqual(sGameType, "hl2mp", false))
	{
		return GameType_FF;
	}
	if (StrEqual(sGameType, "insurgency", false) || StrEqual(sGameType, "ins", false))
	{
		return GameType_INS;
	}
	if (StrEqual(sGameType, "left4dead", false) || StrEqual(sGameType, "l4d", false))
	{
		return GameType_L4D;
	}
	if (StrEqual(sGameType, "left4dead2", false) || StrEqual(sGameType, "l4d2", false))
	{
		return GameType_L4D2;
	}
	if (StrEqual(sGameType, "nts", false))
	{
		return GameType_NEO;
	}
	if (StrEqual(sGameType, "sgtls", false))
	{
		return GameType_SGTLS;
	}
	if (StrEqual(sGameType, "tf", false))
	{
		return GameType_TF;
	}
	if (StrEqual(sGameType, "zps", false))
	{
		return GameType_ZPS;
	}
	if (StrEqual(sGameType, "mmdarkmessiah", false))
	{
		return GameType_DM;
	}
	LogMessage("Unknown Game Folder: %s", sGameType);
	return GameType_Unknown;
}

stock GetSmallerTeam()
{
	
	/**
	Get the count of players on each team
	*/
	new iCountT1 = GetTeamClientCount(g_aCurrentTeams[Team1]);
	new iCountT2 = GetTeamClientCount(g_aCurrentTeams[Team2]);
	
	/**
	Return the smaller team
	*/
	if (iCountT1 < iCountT2)
	{
		return g_aCurrentTeams[Team1];
	}
	else if (iCountT1 > iCountT2)
	{
		return g_aCurrentTeams[Team2];
	}
	return 0;
}

stock GetBiggerTeam()
{

	/**
	Get the count of players on each team
	*/
	new iCountT1 = GetTeamClientCount(g_aCurrentTeams[Team1]);
	new iCountT2 = GetTeamClientCount(g_aCurrentTeams[Team2]);
	
	/**
	Return the bigger team
	*/
	if (iCountT1 > iCountT2)
	{
		return g_aCurrentTeams[Team1];
	}
	else if (iCountT1 < iCountT2)
	{
		return g_aCurrentTeams[Team2];
	}
	return 0;
}

stock LoadCurrentTeams()
{
	switch (g_CurrentMod)
	{
		case GameType_INS:
		{
			g_aCurrentTeams[Unknown] = 0;
			g_aCurrentTeams[Spectator] = 3;
			g_aCurrentTeams[Team1] = 1;
			g_aCurrentTeams[Team2] = 2;
		}
		default:
		{
			g_aCurrentTeams[Unknown] = 0;
			g_aCurrentTeams[Spectator] = 1;
			g_aCurrentTeams[Team1] = 2;
			g_aCurrentTeams[Team2] = 3;
		}
	}
}
