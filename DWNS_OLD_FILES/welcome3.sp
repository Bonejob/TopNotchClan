#pragma semicolon 1

#include <sourcemod>
#define PLUGIN_VERSION "2.0"

new Roundstarts;

public Plugin:myinfo = 
{
	name = "Donator Welcome Message",
	author = "DWN",
	description = "Welcomes Donators",
	version = PLUGIN_VERSION,
	url = "http://www.topnotchclan.com"
};
public OnPluginStart()
{
	// Create the rest of the cvar's
	CreateConVar("sm_welcomemsg_version", PLUGIN_VERSION, "Welcome Donators Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_active", Command_Admins, "Displays active donators");
	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Pre);
}
public OnClientPostAdminCheck(client) 
{
	if ( Roundstarts > 1 ){
		ChatMessageDelayed(client);
	}
}

public Action:Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	if ( Roundstarts++ ==1 ){
		for (new i=1; i<=MaxClients; i++) {
			if (IsClientConnected(i) && IsClientInGame(i)) {
				ChatMessageMayhem(i);
			}
		}
	}	
}

ChatMessageMayhem(client)
{
	new AdminId:id = GetUserAdmin(client);
	if (id != INVALID_ADMIN_ID) {
		CreateTimer(70.0, ChatMessageCB, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

ChatMessageDelayed(client)
{
	new AdminId:id = GetUserAdmin(client);
	if (id != INVALID_ADMIN_ID) {
		CreateTimer(10.0, ChatMessageCB, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:ChatMessageCB(Handle:timer, any:userID) {
	new client = GetClientOfUserId(userID);
	if (client != 0 && IsClientConnected(client)) {
		
		decl Team;
		decl String:ChatMsg[300], String:ClientName[32];
		Team = GetClientTeam(client);
		GetClientName(client, ClientName, sizeof(ClientName));
		Format(ChatMsg, 300, "\x05-----------------------------------------------\n\x01Welcome \x03%s!\n\x01Thank you for your contribution to the servers!\n\x05-----------------------------------------------", ClientName);
		
		if(IsClientInGame(client))
			if(Team == GetClientTeam(client))
				SayText2(client, ChatMsg);
	}
}

public Action:Command_Admins(client, args)
{
	new AdminId:id = GetUserAdmin(client);
	if (id != INVALID_ADMIN_ID)
	{
	PrintToChat(client, "\x05-------------------------------------");
	PrintToChat(client, "\x04Your Package Is Currently \x03Active\x04");
	PrintToChat(client, "\x05-------------------------------------");
	}
	else{
	PrintToChat(client, "\x05-----------------------------------------------");
	PrintToChat(client, "\x04It does not look like you are a donator.\nIf you are, please visit our forums for assistance.\nYou can also donate on our site, TopNotchClan.com!");
	PrintToChat(client, "\x05-----------------------------------------------");
	}

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