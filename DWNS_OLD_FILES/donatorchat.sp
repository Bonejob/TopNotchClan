//Include:
#include <sourcemod>

//Terminate:
#pragma semicolon 1
#define PLUGIN_VERSION "2.1"

//Information:
public Plugin:myinfo = 
{

	//Initialize:
	name = "Donator Chat",
	author = "Pinkfairie,DWN",
	description = "Colored Say Chat for Donators",
	version = PLUGIN_VERSION,
	url = "www.topnotchclan.com"
};


public OnPluginStart()
{

	//Commands:
	RegConsoleCmd("say", HandleSay);
	RegConsoleCmd("say_team", HandleSayTeam);
	
}

//Handle Say:
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
	Format(ChatMsg, 255, "\x03%s\x01: \x06%s", ClientName, Arg);

	//Print:
	for(new X = 1; X <= MaxClients; X++)
		if(IsClientConnected(X))
			if(IsPlayerAlive(client) == IsPlayerAlive(X))
				SayText2(X, ChatMsg);

	//Return:
	return Plugin_Handled;
}

//Handle Say:
public Action:HandleSayTeam(client, args)
{
	if (!client)
		return Plugin_Handled;
		
	new AdminId:id = GetUserAdmin(client);
	if (id == INVALID_ADMIN_ID)
		return Plugin_Handled;

	//Declare:
	decl Team;
	decl String:Arg[255], String:ChatMsg[255], String:ClientName[32];

	//Initialize:
	Team = GetClientTeam(client);
	GetClientName(client, ClientName, sizeof(ClientName));
	GetCmdArgString(Arg, sizeof(Arg));

	//Clean:
	StripQuotes(Arg);
	TrimString(Arg);

	//Preconcieved Commands:
	if(Arg[0] == '/' || Arg[0] == '!' || Arg[0] == '@')
		return Plugin_Continue;

	//Format:
	Format(ChatMsg, 255, "\x01(TEAM) \x03%s\x01: \x06%s", ClientName, Arg);

	//Print:
	for(new X = 1; X <= MaxClients; X++)
		if(IsClientConnected(X))
			if(Team == GetClientTeam(X))
				SayText2(X, ChatMsg);

	//Return:
	return Plugin_Handled;
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