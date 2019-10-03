#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define TEAM_RED 2
#define TEAM_BLUE 3

public Plugin:myinfo = 
{
	name = "PreGame Score Tracker",
	author = "Goerge",
	description = "Tracks Your Scores",
	version = "2.0",
	url = "http://www.fpsbanana.com"
};

new scores[MAXPLAYERS+1];
new roundstarts;
new g_Target			[MAXPLAYERS + 1];
new g_Ent				[MAXPLAYERS + 1];

public OnPluginStart()
{
	HookEvent("teamplay_round_start", hook_Start, EventHookMode_Post);
	HookEvent("player_death", hook_Death, EventHookMode_Post);
}

public OnClientConnected(client)
{
	scores[client] = 0;
}

public OnMapStart()
{
	roundstarts = 0;
}

public Action:hook_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	//get killer id
	new killer = GetEventInt(event, "attacker");
	new k_client = GetClientOfUserId(killer);

	//get dead guy id
	new victim = GetEventInt(event, "userid");
	new v_client = GetClientOfUserId(victim);
	
	// if suicide or world kill, do nothing
	if(k_client == v_client || !k_client)
		return Plugin_Handled;

	scores[k_client]++;
	
	return Plugin_Handled;
}


public Action:hook_Start(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if (roundstarts == 1)
	{
		CreateTimer(1.0, Timer_Scores, _, TIMER_FLAG_NO_MAPCHANGE);
	}


	roundstarts++;
	return Plugin_Handled; 
}

public Action:Timer_Scores(Handle:timer, any:pack)
{		
	new String:ChatMsg[255], String:redNames[256], String:bluNames[256], String:bluNamesList[MAXPLAYERS+1][64], String:redNamesList[MAXPLAYERS+1][64];
	new RedScore = 0, BluScore = 0, bluNums = 0, redNums = 0;

	// determines top score
	for(new i=1; i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_RED)
		{
			if (scores[i] > RedScore)
			{
				RedScore = scores[i];
			}
		}
		
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_BLUE)
		{
			if (scores[i] > BluScore)
			{
				BluScore = scores[i];
			}
		}			
	}
		
	// get all the clients who have the top scors
	for (new i=1; i<= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == TEAM_RED && scores[i] == RedScore)
			{
				CreateTimer(1.0, Timer_Log, GetClientUserId(i));
				GetClientName(i, redNamesList[redNums], 64);
				redNums++;
				CreateTimer(0.6, Timer_TeleRed, i,TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(0.8, Timer_TeleRed, i,TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(1.0, Timer_Particles, i, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(1.5, Timer_Trophy, i, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(3.7, Timer_Particles, i, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(4.2, Timer_Trophy, i, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(10.0, Timer_Delete, i, TIMER_FLAG_NO_MAPCHANGE);
			}
			
			if (GetClientTeam(i) == TEAM_BLUE && scores[i] == BluScore)
			{
				CreateTimer(1.0, Timer_Log, GetClientUserId(i));
				GetClientName(i, bluNamesList[bluNums], 64);
				bluNums++;
				CreateTimer(0.6, Timer_TeleBlu, i,TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(0.8, Timer_TeleBlu, i,TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(1.0, Timer_Particles, i, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(1.5, Timer_Trophy, i, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(3.7, Timer_Particles, i, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(4.2, Timer_Trophy, i, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(10.0, Timer_Delete, i, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	
	
	
	if (BluScore)
	{
		if (bluNums == 1)
		{
			ImplodeStrings(bluNamesList, bluNums, "", bluNames, sizeof(bluNames));
		}		
		else if (bluNums == 2)
		{
			Format(bluNamesList[bluNums-1], 64, "\x04and\x03 %s \x04both", bluNamesList[bluNums-1]);
			ImplodeStrings(bluNamesList, bluNums, " ", bluNames, sizeof(bluNames));
		}
		else if (bluNums > 2)
		{
			Format(bluNamesList[bluNums-1], 64, "\x04and\x03 %s \x04all", bluNamesList[bluNums-1]);
			ImplodeStrings(bluNamesList, bluNums, ", ", bluNames, sizeof(bluNames));
		}
	
		Format(ChatMsg, 255, "\x03%s \x04got the most teamkills with a score of \x03%d \x04on the blue team!", bluNames, BluScore);
		new bluGuy = 0;
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == TEAM_BLUE)
				bluGuy = i;
		}
		
		//Print:
		for (new X = 1; X <= MaxClients; X++)
		{
			if(IsClientInGame(X))
				if(!IsFakeClient(X))
					SayText2One(X, bluGuy, ChatMsg);
		}
	}
	else
		PrintToChatAll("\x04No one on blu got a kill!");
			
	if (RedScore)
	{	
		if (redNums == 1)
		{
			ImplodeStrings(redNamesList, redNums, "", redNames, sizeof(redNames));
		}		
		else if (redNums == 2)
		{
			Format(redNamesList[redNums-1], 64, "\x04and\x03 %s \x04both", redNamesList[redNums-1]);
			ImplodeStrings(redNamesList, redNums, " ", redNames, sizeof(redNames));
		}
		else if (redNums > 2)
		{
			Format(redNamesList[redNums-1], 64, "\x04and\x03 %s \x04all", redNamesList[redNums-1]);
			ImplodeStrings(redNamesList, redNums, ", ", redNames, sizeof(redNames));
		}
		//Format:
		Format(ChatMsg, 255, "\x03%s \x04got the most teamkills with a score of \x03%d \x04on the red team!", redNames, RedScore);
		new redGuy = 0;
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == TEAM_RED)
				redGuy = i;
		}
		
		//Print:
		for(new X = 1; X <= MaxClients; X++)
		{
			if(IsClientInGame(X))
				if(!IsFakeClient(X))
					SayText2One(X, redGuy, ChatMsg);
		}
	
	}
		else PrintToChatAll("\x04No one on red got a kill!");
	
	return Plugin_Handled;
}

public Action:Timer_Log(Handle:timer, any:id)
{
	new client = GetClientOfUserId(id);
	if (client)
	{
		LogToGame("\"%L\" triggered \"pregame_win\"", client);
	}
	return Plugin_Handled;
}


SayText2One(client, author, const String:message[]) {
    new Handle:buffer = StartMessageOne("SayText2", client);
    if (buffer != INVALID_HANDLE) {
        BfWriteByte(buffer, author);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}

public Action:Timer_Particles(Handle:timer, any:client)
{
	
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		
		AttachParticle(client, "mini_fireworks");

		
	}
	
	return Plugin_Handled;
}

public Action:Timer_TeleRed(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		
		AttachParticle(client, "teleportedin_red");

		
	}
	return Plugin_Handled;
}

public Action:Timer_TeleBlu(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		
		AttachParticle(client, "teleportedin_blue");

		
	}
	return Plugin_Handled;
}

public Action:Timer_Trophy(Handle:timer, any:client)
{
	
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		
		//AttachParticle(client, "bday_confetti_colors");
		AttachParticle(client, "achieved");
		
	}
	
	return Plugin_Handled;
}

public Action:Timer_Delete(Handle:timer, any:client)
{
	
	DeleteParticle(g_Ent[client]);
	g_Ent[client] = 0;
	g_Target[client] = 0;
	
}

AttachParticle(ent, String:particleType[])
{
	new particle = CreateEntityByName("info_particle_system");
	
	new String:tName[128];
	
	if (IsValidEdict(particle))
	{
		
		new Float:pos[3] ;
		
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 74;
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", ent);
		
		DispatchKeyValue(ent, "targetname", tName);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetVariantString("flag");
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		g_Ent[ent] = particle;
		g_Target[ent] = 1;
		
	}
	
}

DeleteParticle(any:particle)
{
    if (IsValidEntity(particle))
    {
		
        new String:classname[256];
        GetEdictClassname(particle, classname, sizeof(classname));
		
        if (StrEqual(classname, "info_particle_system", false))
        {
			
            RemoveEdict(particle);
			
        }
		
    }
	
}