#pragma semicolon 1

/* Includes */
#include <sourcemod>
#include <tf2_stocks>

/* Defines */
#define PLUGIN_VERSION			"1.0"
#define PLUGIN_DESCRIPTION		"Counts Admins"
#define defPluginPrefix 		"\x04[Donor Counter]\x03"

/* Globals */

new bool:g_32Donors = true;
new g_iAdminCounter = 0;


/* My Info */
public Plugin:myinfo =
{
    name 		=		"Donor Counter",			
    author		=		"DontWannaName",
    description	=		 PLUGIN_DESCRIPTION,
    version		=		 PLUGIN_VERSION,
    url			=		"http://topnotchclan.com"
};


public OnPluginStart()
{
	CreateConVar("sm_donorcounter_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_count",		DisplayInformation,	ADMFLAG_RESERVATION,	"Display donor number.");
}


public OnClientPostAdminCheck(client)
{
	if (IsClientInGame(client) && AdminId:GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		g_iAdminCounter++;
		//PrintToChatAll("\x04Number of Donors:\x03 %i",g_iAdminCounter);
		//LogToFileEx("addons/sourcemod/logs/counter.log", "Current donators: %i", g_iAdminCounter);
	}
	
	if ((g_iAdminCounter == MaxClients) && g_32Donors == true)
	{
		//PrintToChatAll("\x04The server is currently full of donators!");
		LogToFileEx("addons/sourcemod/logs/counter.log", "There were %i donators on the server.", g_iAdminCounter);
		decl String:filename[64];
		Format(filename, sizeof(filename), "misc/happy_birthday.wav");
		EmitSoundToAll(filename);
		CreateTimer(300.0, Timer_Reset, _, TIMER_FLAG_NO_MAPCHANGE);
		g_32Donors = false;
	}
}

public Action:Timer_Reset(Handle:timer) 
{
	g_32Donors = true;
	return Plugin_Handled;
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client) && AdminId:GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		g_iAdminCounter--;
		//PrintToChatAll("\x04Number of Donors:\x03 %i",g_iAdminCounter);
	}
	
}

public OnMapStart()
{
	g_iAdminCounter = 0;
	g_32Donors = true;
	PrecacheSound("misc/happy_birthday.wav");
}

public OnMapEnd()
{
	g_iAdminCounter = 0;
	g_32Donors = true;
}

public Action:DisplayInformation(client, args)
{
	if(args >= 1){
		ReplyToCommand(client, "\x04Do not put a value after this command!");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "\x04There are \x03%i \x04Donators in the server right now.",g_iAdminCounter);
	return Plugin_Handled;
}