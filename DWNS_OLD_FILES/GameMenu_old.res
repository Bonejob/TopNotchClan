"GameMenu" [$WIN32]
{
	"1"
	{
		"label" "#GameUI_GameMenu_ResumeGame"
		"command" "ResumeGame"
		"OnlyInGame" "1"
	}
	"2"
	{
		"label" "#GameUI_GameMenu_Disconnect"
		"command" "Disconnect"
		"OnlyInGame" "1"
	}
	"3"
	{
		"label" "#GameUI_GameMenu_PlayerList"
		"command" "OpenPlayerListDialog"
		"OnlyInGame" "1"
	} 
	
	"4"
	{
		"label" "------------------------"
		"OnlyInGame" "1"
	}
	
	"5"
	{
		"label" "San Jose Servers"
	}
	"6"
	{
		"label" "Join (-TN-) 24/7 Badwater/Goldrush"
		"command" "engine connect badwater.topnotchclan.com"
	}
	"7"
	{
		"label" "Join (-TN-) Payload Rotation"
		"command" "engine connect payload.topnotchclan.com"
	}
	"8"
	{
		"label" "Join (-TN-) Rotation Server"
		"command" "engine connect rotation.topnotchclan.com"
	}
	"9"
	{
		"label" "Join (-TN-) 24/7 Dustbowl"
		"command" "engine connect dustbowl.topnotchclan.com"
	}
	"10"
	{
		"label" ""
		"command" ""
	}
	"11"
	{
		"label" "Seattle Servers"
	}
	"12"
	{
		"label" "Join (-TN-) Capture the Flag Rotation"
		"command" "engine connect ctf.topnotchclan.com"
	}
	"13"
	{
		"label" "Join (-TN-) King of the Hill Rotation"
		"command" "engine connect koth.topnotchclan.com"
	}
	"14"
	{
		"label" "Join (-TN-) No Random Crits Rotation"
		"command" "engine connect nocrit.topnotchclan.com"
	}
	"15"
	{
		"label" "Join (-TN-) Payload Race Rotation"
		"command" "engine connect plr.topnotchclan.com"
	}
	
	"16"
	{
		"label" "------------------------"
	}
	
	"17"
	{
		"label" "#GameUI_GameMenu_CharacterSetup"
		"command" "engine open_charinfo"
	}
	"18"
	{
		"label" "#GameUI_GameMenu_Achievements"
		"command" "OpenAchievementsDialog"
	}
	"19"
	{
		"label" "#GameUI_GameMenu_Options"
		"command" "OpenOptionsDialog"
	}
	
	"20"
	{
		"label" "------------------------"
	}
	
	"21"
	{
		"label" "#GameUI_GameMenu_FindServers" 
		"command" "OpenServerBrowser"
	} 
	"22"
	{
		"label" "#GameUI_GameMenu_CreateServer"
		"command" "OpenCreateMultiplayerGameDialog"
	}
	"23"
	{
		"label"	"#GameUI_LoadCommentary"
		"command" "OpenLoadSingleplayerCommentaryDialog"
	}
	"24"
	{
		"label" "#GameUI_Controller"
		"command" "OpenControllerDialog"
		"ConsoleOnly" "1"
	}
	
	"25"
	{
		"label" "------------------------"
	}
	
	"26"
	{
		"label" "#GameUI_ReportBug"
		"command" "engine bug"
	}
	"27"
	{
		"label" "#GameUI_GameMenu_Quit"
		"command" "Quit"
	}
}