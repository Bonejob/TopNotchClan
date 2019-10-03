<?PHP
/**
 * Steam Community Group inviter
 * Written by Gachl
 * Updated to latest Steam API by Rincewind
 * Requirements: CURL
 * Version: 1.1 - 19.07.2010
 * Validation by Gachl
 * Please respect cc:by-nc-sa -> http://creativecommons.org/licenses/by-nc-sa/3.0/
 *
 * Donations via PayPal: daniel@codefreak.net
 * Thank you!
 */

// Configuration
$inviterUsername = "jacoburman1";		// Login username
$inviterPassword = "IVJ7MYIT";		// Login password
$inviterFriendID = "76561198009398661";		// Friend ID of inviter
$inviteToGroup   = "103582791429682515";	// Group ID
$debug           = false;


// Low level settings (don't touch that if you don't know what you're doing)
$steamAPIInvitationURL = "http://steamcommunity.com/actions/GroupInvite?type=groupInvite&inviter=%inviter%&invitee=%invitee%&group=%group%";
$steamAPILoginSubmitTo = "https://steamcommunity.com";
$steamAPILoginReferer  = "https://steamcommunity.com";
$steamAPILoginData     = Array(
						"action"			=>	"doLogin",
						"goto"				=>	"",
						"qs"				=>	"",
						"msg"				=>	"",
						"steamAccountName"	=>	$inviterUsername,
						"steamPassword"		=>	$inviterPassword);
$curlCookieSavePath    = "/tmp/cookie.txt";
$curlFollowLocation    = 0;

// Check for the required parameters
// URL: ?auth=STEAM_0:1:23456789
$authCode = CheckGetParameter("auth");
if ($authCode === false)
	die("No auth specified.");

// Validate Steam ID
$authCodeValidation = "/^STEAM_[0-9]:[0-9]:[0-9]*$/";
if (!preg_match($authCodeValidation, $authCode))
	die("Invalid auth format. Please use STEAM_X:Y:Z.");

// Generate and validate friend ID
$friendId = GetFriendID($authCode);
if ($friendId == "0")
	die("There was a problem converting '$authCode' to the community ID.");

// Setup CURL
$crl = curl_init();
curl_setopt($crl, CURLOPT_URL, $steamAPILoginSubmitTo);
curl_setopt($crl, CURLOPT_REFERER, $steamAPILoginReferer);
curl_setopt($crl, CURLOPT_COOKIEFILE, $curlCookieSavePath);
curl_setopt($crl, CURLOPT_COOKIEJAR, $curlCookieSavePath);
curl_setopt($crl, CURLOPT_FOLLOWLOCATION, $curlFollowLocation);
curl_setopt($crl, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($crl, CURLOPT_POST, 1);
curl_setopt($crl, CURLOPT_POSTFIELDS, $steamAPILoginData);

// Execute CURL
// Note: We don't really care about the answer of the login. Either it worked, or it didn't.
if ($debug)
	echo curl_exec($crl);
else
	curl_exec($crl);

if ($debug && (CheckGetParameter("debugStep2") !== "true"))
	die("Debug mode. <a href=\"?auth=$authCode&amp;debugStep2=true\">Continue</a>?");

// Setup invite url
$steamAPIInvitationURL = str_replace(Array("%inviter%", "%invitee%", "%group%"), Array($inviterFriendID, $friendId, $inviteToGroup), $steamAPIInvitationURL);
curl_setopt($crl, CURLOPT_URL, $steamAPIInvitationURL);
curl_setopt($crl, CURLOPT_POST, 0);

// Execure CURL
// Note: We could check if the Steam API answers with OK, or not. But I'm too lazy.
if ($debug)
	echo curl_exec($crl);
else
	curl_exec($crl);

// All done, user is now invited.

/**
 * Check _GET parameter
 */
function CheckGetParameter($paramName)
{
	if (!isset($_GET[$paramName]))
		return false;
	if (empty($_GET[$paramName]))
		return false;
	return $_GET[$paramName];
}

/**
 * Convert STEAM_X:Y:Z to a FriendID
 * Thanks to Seather -> http://forums.alliedmods.net/showpost.php?p=565979&postcount=16
 */
function GetFriendID($pszAuthID)
{
	$iServer = "0";
    $iAuthID = "0";
	
	$szAuthID = $pszAuthID;
	$szTmp = strtok($szAuthID, ":");
	
	while(($szTmp = strtok(":")) !== false)
    {
        $szTmp2 = strtok(":");
        if($szTmp2 !== false)
        {
            $iServer = $szTmp;
            $iAuthID = $szTmp2;
        }
    }

    if($iAuthID == "0")
        return "0";

    $i64friendID = bcmul($iAuthID, "2");
    $i64friendID = bcadd($i64friendID, bcadd("76561197960265728", $iServer)); 
	
	return $i64friendID;
}
?>