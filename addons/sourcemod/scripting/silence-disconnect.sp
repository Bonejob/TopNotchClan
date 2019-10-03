#include <sourcemod>


public Plugin:myinfo =
{
    name = "Silence Disconnect",
    author = "jormangundr",
    description = "No need to tell people, people are leaving",
    version = "0.1",
    url = "http://www.topnotclan.org"
};

 

public void OnPluginStart() 
{
  HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public Action Event_PlayerDisconnect( Event event, const char[] name, bool dontBroadChast) {
  return Plugin_Handled;
}
