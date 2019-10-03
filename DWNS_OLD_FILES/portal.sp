#pragma semicolon 1
#include <sourcemod>

#define MOTDPANEL_TYPE_TEXT 0 /**< Treat msg as plain text */
#define MOTDPANEL_TYPE_INDEX 1 /**< Msg is auto determined by the engine */
#define MOTDPANEL_TYPE_URL 2 /**< Treat msg as an URL link */
#define MOTDPANEL_TYPE_FILE 3 /**< Treat msg as a filename to be openned */
#define COLOR_DEFAULT 0x01
#define COLOR_TEAM 0x03
#define COLOR_GREEN 0x04

new Handle:RulesURL;

public Plugin:myinfo = {
	name = "M3Motd - MOTD / Display",
	author = "M3Studios, Inc.",
	description = "Let's users view the MOTD during game.",
	version = "0.2.3",
	url = "http://www.m3studiosinc.com/"
};

public OnPluginStart() {
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	RegAdminCmd("sm_portal", Command_ShowMOTD, ADMFLAG_KICK, "sm_motd <#userid|name>");
	RulesURL = CreateConVar("sm_portal_url","http://www.topnotchclan.com/server/portal.html","Set this to the URL of your MOTD/Rules.");
	LoadTranslations("common.phrases");
}

public Action:Command_ShowMOTD(client, args) {
	if (args != 1) {
		return Plugin_Handled;	
	}
	
	new String:Target[64];
	GetCmdArg(1, Target, sizeof(Target));
	
	new String:targetName[MAX_TARGET_LENGTH];
	new targetList[MAXPLAYERS], targetCount;
	new bool:tnIsMl;
	
	targetCount = ProcessTargetString(Target, client, targetList, sizeof(targetList), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), tnIsMl);

	if(targetCount == 0) {
		ReplyToTargetError(client, COMMAND_TARGET_NONE);
	} else {
		for (new i=0; i<targetCount; i++) {
			PerformMOTD(client, targetList[i]);
		}
	}
	
	return Plugin_Continue;
}

public Action:Command_Say(client, args) {
	decl String:text[192];
	if (GetCmdArgString(text, sizeof(text)) < 1) {
		return Plugin_Continue;
	}
	
	new startidx;
	if (text[strlen(text)-1] == '"') {
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	decl String:message[8];
	BreakString(text[startidx], message, sizeof(message));
	
	if (strcmp(message, "!portal", false) == 0 || strcmp(message, "!stillalive", false) == 0) {
		PerformMOTD(client, client);
	}
	
	return Plugin_Continue;	
}

public PerformMOTD(client, target) {
	if (client != target) {
	 	new String:clientName[32];
	 	new String:targetName[32];

		GetClientName(client, clientName, 31);		
		GetClientName(target, targetName, 31);
		
		PrintToChatAll("%c[PORTAL] %c%s %s %s %s",COLOR_GREEN,COLOR_DEFAULT,clientName,"just forced",targetName,"to listen to Still Alive!");
	}

	new String:MOTDURL[128];
	GetConVarString(RulesURL, MOTDURL, 127);
	
	ShowMOTDPanel(target, "Server Rules", MOTDURL, MOTDPANEL_TYPE_URL);
}