//This work is licensed under the Creative Commons Attribution-Noncommercial-No Derivative Works 3.0 United States License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/3.0/us/ or send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.



//Include:
#include <sourcemod>

//Terminate:
#pragma semicolon 1
#define PLUGIN_VERSION "1.0"
#define TEAM_RED 2
#define TEAM_BLUE 3
#define ADMIN_RIGHTS ADMFLAG_RESERVATION

//Information:
public Plugin:myinfo = 
{
	//Initialize:
	name = "Colored Chat",
	author = "DWN (goerge really) :p",
	description = "Colored Say For Donators",
	version = PLUGIN_VERSION,
	url = "www.topnotchclan.com"
};

public OnPluginStart()
{
	RegConsoleCmd("say", SayAll);
	RegConsoleCmd("say_team", SayTeam);
}

public Action:SayAll(client, args)
{

	if (!client)  /* stopps if console */
			return Plugin_Continue;
			
	new AdminId:id = GetUserAdmin(client); 
	
	if (id == INVALID_ADMIN_ID) /* stopps if not an admin*/
		return Plugin_Continue;
		
			
	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	// compensate for quotation marks
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
		
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	if (StrContains(text[startidx], "/color", false) == 0 || StrContains(text[startidx], "!color", false) == 0)
	{
		new String:playerName[32], String:action[255];
		decl String:message[192];
		strcopy(message, 192, text[startidx+7]);
		GetClientName(client,playerName,sizeof(playerName));
			
		Format(action, sizeof(action), "\x03%s\x01 :  \x05%s", playerName, message);
		
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (IsClientInGame(i) && !IsFakeClient(i)) 
			{
				SayText2One(i, client, action);
			}
		}
		SetCmdReplySource(old);
		return Plugin_Handled;
	}
	SetCmdReplySource(old);
	
	return Plugin_Continue;
}

public Action:SayTeam(client, args)
{

	if (!client)  /* stopps if console */
			return Plugin_Continue;
			
	new AdminId:id = GetUserAdmin(client); 
	
	if (id == INVALID_ADMIN_ID) /* stopps if not an admin*/
		return Plugin_Continue;
		
			
	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}
	
	// compensate for quotation marks
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
		
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	if (StrContains(text[startidx], "/color", false) == 0 || StrContains(text[startidx], "!color", false) == 0)
	{
		new String:playerName[32], String:action[255];
		decl String:message[192];
		strcopy(message, 192, text[startidx+7]);
		GetClientName(client,playerName,sizeof(playerName));	
		new speakerTeam = GetClientTeam(client);
			
		Format(action, sizeof(action), "\x01(TEAM) \x03%s\x01 :  \x05%s", playerName, message);
		
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == speakerTeam) 
			{
				SayText2One(i, client, action);
			}
		}
		SetCmdReplySource(old);
		return Plugin_Handled;
	}
	SetCmdReplySource(old);
	
	return Plugin_Continue;
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
/*
SayText2(to, const String:message[]) {
	new Handle:hBf = StartMessageOne("SayText2", to);
	
	if (hBf != INVALID_HANDLE) {
		BfWriteByte(hBf,   to);
		BfWriteByte(hBf,   true);
		BfWriteString(hBf, message);
		
		EndMessage();
	}
}*/