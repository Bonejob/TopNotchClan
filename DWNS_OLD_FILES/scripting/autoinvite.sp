/**
 * Plugin written by Gachl and Rincewind
 * Please report all bugs and requests to Rincewind on
 * http://forums.alliedmods.net
 * Thank you.
 */
 
 /* Plugin Base Definitions */
 #define PLUGIN_VERSION	"1.0"
 #define PLUGIN_AUTHOR	"Rincewind & Gachl"
 #define PLUGIN_NAME	"Auto Group Invite"
 #define PLUGIN_URL		"http://bloodisgood.org"
 #define PLUGIN_DESCR	"Automatically invite players to a group"

 /* Includes */
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <socket>

/* ConVar Handles */
new Handle:cEnable;		// Enable or disable the plugin
new Handle:cKey;		// Registration Key

/* ConVar Variables */
new bool:bEnable;
new iKey;

/* Vars */

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCR,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public OnPluginStart()
{
	// Create ConVars
	CreateConVar("sm_autoinvite_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY);
	cEnable =	CreateConVar("sm_autoinvite_enable", "1", "Enable or disable the plugin");
	cKey = CreateConVar("sm_autoinvite_key", "0", "Registration key. Obtain one at http://codefreak.net/~daniel/inviter");
	RegConsoleCmd("sm_invite", Command_Invite, "Invites you into our steam group");
	// Create Commands
	RegAdminCmd("sm_autoinvite_reload", CmdReload, ADMFLAG_ROOT);
	
	LoadConVars();
}

public OnConfigsExecuted()
{
	LoadConVars();
}

LoadConVars()
{
	bEnable =	GetConVarBool(cEnable);
	iKey =		GetConVarInt(cKey);
}

public Action:CmdReload(hClient, iArgs)
{
	LoadConVars();
	ReplyToCommand(hClient, "The plugin reloaded successfully.");
}

/* Plugin Logic */
public Action:Command_Invite(hClient, const String:sAuth[])
{
	if (bEnable)
	{
		new Handle:hSocket = SocketCreate(SOCKET_TCP, OnSocketError);
		SocketSetArg(hSocket, hClient);
		SocketConnect(hSocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "topnotchclan.com", 80);
	}
	return Plugin_Handled;
}

public OnSocketConnected(Handle:socket, any:hClient) {
	decl String:sRequestStr[256];
	decl String:sAuth[256];
	GetClientAuthString(hClient, sAuth, sizeof(sAuth));
	Format(sRequestStr, sizeof(sRequestStr), "GET /server/inviter.php?key=%i&auth=%s HTTP/1.0\r\nHost: topnotchclan.com\r\nConnection: close\r\n\r\n", iKey, sAuth);
	SocketSend(socket, sRequestStr);
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:nothing) {
	PrintToServer("Auto Invite Error: %s", receiveData);
}

public OnSocketDisconnected(Handle:socket, any:hFile) {
	CloseHandle(socket);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:nothing) {
	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

