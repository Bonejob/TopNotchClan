#pragma semicolon 1
#include <sourcemod>

new Handle:g_url;

public Plugin:myinfo = {
	name = "Play Thriller",
	author = "DWN",
	description = "Let's users play thriller during the game.",
	version = "1.0",
	url = "http://www.topnotchclan.com/"
};

public OnPluginStart() {
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	RegAdminCmd("sm_forcethriller", Command_ShowMOTD, ADMFLAG_KICK, "sm_forcethriller <#userid|name>");
	g_url = CreateConVar("sm_thriller_url", "http://www.topnotchclan.com/server/thriller.html", "The url of the mp3.");
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
			CreateTimer(61.0, Thriller, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	return Plugin_Continue;
}

public Action:Thriller(Handle:timer, any:client) {
	
	PrintCenterText(client, "It's Close To Midnight and Something Evil's Lurking In the Dark...");
	PrintToChat(client, "\x06It's Close To Midnight and Something Evil's Lurking In the Dark...");
	return Plugin_Handled;
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
	
	decl String:message[32];
	BreakString(text[startidx], message, sizeof(message));
	
	if (strcmp(message, "!thriller", false) == 0 || strcmp(message, "thriller", false) == 0) {
		PerformMOTD(client, client);
		CreateTimer(61.0, Thriller, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;	
}

public PerformMOTD(client, target) {

	new String:url[128];
	
	new Handle:Kv = CreateKeyValues("data");
	GetConVarString(g_url, url, 127);
	KvSetString(Kv, "title", "Music");
	KvSetString(Kv, "type", "2");
	KvSetString(Kv, "msg", url);
	ShowVGUIPanel(target, "info", Kv, false);
	CloseHandle(Kv);
	
}