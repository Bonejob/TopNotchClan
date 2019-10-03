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
		"label" "Join (-TN-) 24/7 Badwater/Goldrush"
		"command" "engine connect badwater.topnotchclan.com"
	}
	"6"
	{
		"label" "Join (-TN-) Payload Rotation"
		"command" "engine connect payload.topnotchclan.com"
	}
	"7"
	{
		"label" "Join (-TN-) 24/7 2Fort/Turbine"
		"command" "engine connect turbine.topnotchclan.com"
	}
	"8"
	{
		"label" "Join (-TN-) 24/7 Dustbowl"
		"command" "engine connect dustbowl.topnotchclan.com"
	}
	
	"9"
	{
		"label" "------------------------"
	}
	
	"10"
	{
		"label" "#GameUI_GameMenu_CharacterSetup"
		"command" "engine open_charinfo"
	}
	"11"
	{
		"label" "#GameUI_GameMenu_Achievements"
		"command" "OpenAchievementsDialog"
	}
	"12"
	{
		"label" "#GameUI_GameMenu_Options"
		"command" "OpenOptionsDialog"
	}
	
	"13"
	{
		"label" "------------------------"
	}
	
	"14"
	{
		"label" "#GameUI_GameMenu_FindServers" 
		"command" "OpenServerBrowser"
	} 
	"15"
	{
		"label" "#GameUI_GameMenu_CreateServer"
		"command" "OpenCreateMultiplayerGameDialog"
	}
	"16"
	{
		"label"	"#GameUI_LoadCommentary"
		"command" "OpenLoadSingleplayerCommentaryDialog"
	}
	"17"
	{
		"label" "#GameUI_Controller"
		"command" "OpenControllerDialog"
		"ConsoleOnly" "1"
	}
	
	"18"
	{
		"label" "------------------------"
	}
	
	"19"
	{
		"label" "#GameUI_ReportBug"
		"command" "engine bug"
	}
	"20"
	{
		"label" "#GameUI_GameMenu_Quit"
		"command" "Quit"
	}
}