#if defined _cbaseserver_included
 #endinput
#endif
#define _cbaseserver_included

/**
 * @brief Called very early in the client connect process
 *
 * @param name			Client's name.
 * @param pass			Connection password (or the most recently used one).
 * @param ip			Client's IP address.
 * @param authid		Client's SteamId.  (This is before authentication so it is not guaranteed.)
 */
forward OnClientPreConnect(const String:name[], const String:pass[], const String:ip[], const String:authid[]);


/**
 * Do not edit below this line!
 */
public Extension:__ext_cbaseserver = 
{
	name = "CBaseServer tools",
	file = "cbaseserver.ext",
	autoload = 1,
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};

