#pragma semicolon 1
#include <sourcemod>

new Handle:g_url;

public Plugin:myinfo = {
	name = "M3Motd - MOTD / Rules Display",
	author = "M3Studios, DWN",
	description = "Let's users view the MOTD during game.",
	version = "1.0",
	url = "http://www.m3studiosinc.com/"
};

public OnPluginStart() {
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	RegAdminCmd("sm_test", Command_ShowMOTD, ADMFLAG_KICK, "sm_test <#userid|name>");
	g_url = CreateConVar("sm_mp3url", "http://www.topnotchclan.com/server/rick.html", "The url of the mp3.");
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
	
	if (strcmp(message, "!test", false) == 0 || strcmp(message, "!test2", false) == 0) {
		PerformMOTD(client, client);
	}
	
	return Plugin_Continue;	
}

public PerformMOTD(client, target) {
	
	decl String:filename[32];
	GetCmdArgString(filename, sizeof(filename));
	new String:url[192] = "http://your-domain.com/script_that_generates_appropriate_html.php?filename=";
	StrCat(url, sizeof(url), filename);
	
	new Handle:Kv = CreateKeyValues("data");
	KvSetString(Kv, "title", ":D");
	KvSetString(Kv, "type", "2");
	KvSetString(Kv, "msg", url);
	ShowVGUIPanel(target, "info", Kv, false); // The false as the last arg means the user doesn't actually see the window itself
	CloseHandle(Kv);

}