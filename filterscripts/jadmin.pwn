/*******************************************************************************
********************************************************************************
*****																	   *****
*****				     Jake's Admin System 4.0 					   	   *****
*****				    *Last Patched: 01/01/2018					       *****
*****					  A new chapter begins.							   *****
*****				     Originally coded on 2013.						   *****
*****																	   *****
********************************************************************************
********************************************************************************
--------------------------------------------------------------------------------
						
Changelog for JakAdmin 4.0:
	* Script Optimization.
	* Updated jadmin.inc (renamed from jadmin3)
	* Ban System tweaked:
		* Offline Banning now bans the IP. 
		* Added a Temporary Ban System (no effects on prev-ban database)
		* Added a command to check if a player is banned. (/checkban)
		* Added a command to ban/unban an IP. (/(un)banip)
	* Security Checks on User Account.
		* Prints out a log at the server console whenever a player fails to login/answer the security question.
		* Lists last 10 IPs who tries to breach into the user's account. (/checkbreach)
	* Level 5 admins:
		* Ability to create a user account without logging out. (/createaccount)
		* Ability to remove a user account. (/removeaccount)
		* Full control on offline user's account (/setaccount)
	* Server will now automatically kick tabbed out/idle players (/jsettings to disable)
		* Ability to list down tabbed players. (/tabbed)
		* Ability to list down AFK players. (/afk)
		* Updated jadmin, adding idle/tabbed checks (IsPlayerTabbed & IsPlayerIdle)
	* Removal of the Note System.
	* Removal of the Mega Jump System.
	* Removal of a few commands that is prone to being abused. 
	* Added LastOn over the user's data.
		* Added /laston command.
	* Re-added back the Lock Chat system. (/lockchat)
	* Higher Admins are now immune from being included on Over-All commands such as /setallskin etc. 
	* Added /rcons for Level 5+ 
	* Re-added back /hideme.
	* Added label for Admins. 
	* Added Join/Leave messages (/jsettings)
	* /god is now a Level 1 admin command.
	* Switched from dini to y_ini. 
	* Changed the color embedding theme from Orange to Green. 
	* You can now permanently mute players without setting a time. 
	* You can check the last 5 people who injured the player.
	* Added the /richlist command. 
	* Brought back the private message system.
	* Added an option to make /stats into dialog or server-client message. (See USE_DIALOG)
	* Converted the whole dialog script to Emmet's easyDialog. 
	* Added the Also-Known-As system. (See USE_AKA)
	* Tweaked the Anti-Spam (+ now includes Command Spams)
	* Admin's Status is now displayed on /stats. 
	* Fixed Advanced/Reverse Spectating. 
	* Added a command to check an offline statistics (/ostats)
	* Client-Messages & Color re-tweaked (+ including grammar fixes). 
	* You can now cage players as a punishment! (Level 2+ admins)
	* Fixed on /register. (crashes the server if the oldname PVar is null)
	* Enables to print out all the players typed command on the server console (See PRINT_CMD)
	* You are now required to use commas when placing coordinates on /gotoco.
	* Control over the RCON Panel (promoting/demoting someone without going IG, etc.)
	* Removal of the High-Ping Warning, player gets instantly kicked now for having a high ping. 
	* Removal of the VIP system, making JakAdmin a standalone script once again.

Note:
	* Check loadb function and removed the ALTER code if you don't need it.
	  It adds the column CHOCOLATE in the database for those old JakAdmin users (remove it if you aren't an old jakadmin user)
	  It also adds the USESKIN and SKIN column in the table (so the old user of JakAdmin won't need to delete the database)
	  
	 * JakAdmin3's folder on scriptfiles was renamed to JakAdmin (please be informed) 

Credits goes to:
	* Jake Hero         (Scripting JakAdmin)
	• Zeex 				(zcmd)
	• Y_Less 			(sscanf/YSI/whirlpool)
	• Lordzy 			(Second RCON Login)
	* Ultraz            (Suggestions)
	* denNorske         (Providing a temporary server-host)
	* Stinged			(RCON Command technique)
	* Emmet_			(easyDialog)
	• SA-MP Team
	• Others who helped me on beta testing.

-------------------------------------------------------------------------------*/

#include <a_samp>
native WP_Hash(buffer[], len, const str[]); // whirlpool by Y_Less
native IsValidVehicle(vehicleid);
#include <zcmd>
#include <sscanf2>
#include <streamer>
#include <YSI\y_ini>
#include <YSI\y_iterate> // foreach
#include <easyDialog> // Emmet_

#pragma dynamic 21016348

//============================================================================//
// Macros

#define function:%0(%1) forward %0(%1);\
		public %0(%1)

#define LevelCheck(%0,%1); \
		if(User[(%0)][accountAdmin] < %1 && !IsPlayerAdmin((%0)))\
			return format(st, 90, "* You must be level %d to use this command.", (%1)),\
				SendClientMessage((%0), COLOR_RED, st);

#define LoginCheck(%1) if(User[%1][accountLogged] == 0) return SendClientMessage(%1, COLOR_RED, "* You must be logged in to use this command.")

#define PRESSED(%0) (((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))

#define RCON:%0(%1)        forward rcon_%0(%1); public rcon_%0(%1)

#define abs(%1) 		   (((%1) < 0) ? (-(%1)) : ((%1)))

////////////////////////////////////////////////////////////////////////////////
// Colors

#define 				white 							"{FFFFFF}"
#define 				lightblue 						"{33CCFF}"
#define                 grey                            "{AFAFAF}"
#define                 orange                          "{FF8000}"
#define                 black                           "{2C2727}"
#define                 red                             "{FF0000}"
#define                 yellow                          "{FFFF00}"
#define                 green                           "{33CC33}"
#define                 blue                            "{0080FF}"
#define                 purple                          "{D526D9}"
#define                 pink                            "{FF80FF}"
#define                 brown                           "{A52A2A}"

#define 				COLOR_RED  						0xFF0000C8
#define 				COLOR_YELLOW 					0xFFFF00AA
#define 				COLOR_GREEN         			0x33CC33C8
#define 				COLOR_ORANGE        			0xFF8000C8
#define 				COLOR_WHITE         			0xFFFFFFFF
#define 				COLOR_PURPLE        			0xD526D9FF
#define 				COLOR_LIGHTGREEN    			0x00FF00FF
#define 				COLOR_PINK          			0xFF80FFFF
#define 				COLOR_LIGHTBLUE     			0x33CCFFAA
#define 				COLOR_GREY          			0xAFAFAFAA
#define 				COLOR_BLUE          			0x0080FFC8
#define 				COLOR_BROWN	 					0xA52A2AAA
#define 				COLOR_BLACK		    			0x2C2727AA
#define					COLOR_ADMIN						0x0BBD5FEFF

// All of the saved datas (exceptions for server configuration, goes to juser.db)
#define 				_DB_		        			"JakAdmin/juser.db"

// All of the logs (if it is enabled) goes here.
#define             	_LOG_                           "JakAdmin/Logs/"

// Range Ban list goes here. 
#define 				BANLIST         				"JakAdmin/cidr-banlist.txt"

// Current Version of the Script
#define                 VERSION                         "4.0"

// Spectate Modes
#define 				ADMIN_SPEC_TYPE_NONE 			0
#define 				ADMIN_SPEC_TYPE_PLAYER 			1
#define 				ADMIN_SPEC_TYPE_VEHICLE 		2

// Starting score for registered player.
#define                 STARTING_SCORE                  1
// Starting cash for registered player.
#define                 STARTING_CASH                   10000
// Max warnings for attempting to logged in RCON.
#define                 MAX_RCON_WARNINGS               3
// Time Limit before you can send another message
#define 				SPAM_TIMELIMIT					2  	// In seconds
// Maximum Notes an admin can drop to a specific player.
#define                 MAX_NOTES                       3
// Maximum Deployable Labels
#define                 MAX_DEPLOYABLE_LABEL            30
// Enables DIALOG in register/login/stats/everything, remove or comment otherwise to make it client-server message.
#define					USE_DIALOG
// Enables the 2nd RCON protection, remove or comment otherwise to disable.
#define                 USE_RCON_PROTECTION 
// Password for the 2nd RCON
#define 				RCON_PASSWORD        			"changeme"
// Enables the AKA system, remove or comment otherwise to disable.
#define					USE_AKA
// Enables the command printing/logging on the server console, remove or comment to disable.
#define					PRINT_CMD

// Maximum Reports
#define                 MAX_REPORTS                     100

////////////////////////////////////////////////////////////////////////////////
// Enums

enum ReportInfo
{
	bool:reportTaken,
	reporterID,
	reportedID,
	reportReason[64],
	reportTime[32],
	reportAccepted
};

enum ServerData
{
	TabTime,
	AFKTime,
	ReadPMs,
	JoinMsg,
	RegisterOption,
	LoginWarn,
	SecureWarn,
	SaveLogs,
	AutoLogin,
	ReadCmds,
	ReadCmd, // Type 0 - Default (OLD), 1 - Spectate Players
	MaxPing,
	AntiSwear,
	AntiName,
	AntiAd,
	AntiSpam,
	LockChat,
	AdminRank1[32],
	AdminRank2[32],
	AdminRank3[32],
	AdminRank4[32],
	AdminRank5[32]
};

enum PlayerInfo
{
    accountID,
	accountGod,
    accountChocolate,
	accountLastOn[32],
    accountName[24],
    accountIP[20],
    accountQuestion[92],
    accountAnswer[129],
    accountPassword[129],
    accountMarker,
    accountUseSkin,
    accountSkin,
    accountAdmin,
    accountAdminEx,
    accountTemporary,
    accountKills,
    accountDeaths,
    accountLogged,
	WarnLog,
	accountDate[64],
	accountWarn,
	accountMuted,
	accountMuteSec,
	accountCMuted,
	accountCMuteSec,
	accountJail,
	accountJailSec,
	accountTabbed,
	accountAFK,
	Float:accountAFKPos[3],
	SpecID,
	SpecType,
	pCar,
	accountCage,
	accountCageObject,
	accountGame[3],
	accountGameEx,
	accountDuty,
	SpamTime,
	accountPM,
	accountHide,
	Text3D:accountLabel
};

enum LabelInfo
{
	labelTaken,
	Text3D:label3D,
	Float:labelX,
	Float:labelY,
	Float:labelZ,
	labelInterior,
	labelVW
};

// Arrays

new VehicleNames[212][] = {
	{"Landstalker"},{"Bravura"},{"Buffalo"},{"Linerunner"},{"Perrenial"},{"Sentinel"},{"Dumper"},
	{"Firetruck"},{"Trashmaster"},{"Stretch"},{"Manana"},{"Infernus"},{"Voodoo"},{"Pony"},{"Mule"},
	{"Cheetah"},{"Ambulance"},{"Leviathan"},{"Moonbeam"},{"Esperanto"},{"Taxi"},{"Washington"},
	{"Bobcat"},{"Mr Whoopee"},{"BF Injection"},{"Hunter"},{"Premier"},{"Enforcer"},{"Securicar"},
	{"Banshee"},{"Predator"},{"Bus"},{"Rhino"},{"Barracks"},{"Hotknife"},{"Trailer 1"},{"Previon"},
	{"Coach"},{"Cabbie"},{"Stallion"},{"Rumpo"},{"RC Bandit"},{"Romero"},{"Packer"},{"Monster"},
	{"Admiral"},{"Squalo"},{"Seasparrow"},{"Pizzaboy"},{"Tram"},{"Trailer 2"},{"Turismo"},
	{"Speeder"},{"Reefer"},{"Tropic"},{"Flatbed"},{"Yankee"},{"Caddy"},{"Solair"},{"Berkley's RC Van"},
	{"Skimmer"},{"PCJ-600"},{"Faggio"},{"Freeway"},{"RC Baron"},{"RC Raider"},{"Glendale"},{"Oceanic"},
	{"Sanchez"},{"Sparrow"},{"Patriot"},{"Quad"},{"Coastguard"},{"Dinghy"},{"Hermes"},{"Sabre"},
	{"Rustler"},{"ZR-350"},{"Walton"},{"Regina"},{"Comet"},{"BMX"},{"Burrito"},{"Camper"},{"Marquis"},
	{"Baggage"},{"Dozer"},{"Maverick"},{"News Chopper"},{"Rancher"},{"FBI Rancher"},{"Virgo"},{"Greenwood"},
	{"Jetmax"},{"Hotring"},{"Sandking"},{"Blista Compact"},{"Police Maverick"},{"Boxville"},{"Benson"},
	{"Mesa"},{"RC Goblin"},{"Hotring Racer A"},{"Hotring Racer B"},{"Bloodring Banger"},{"Rancher"},
	{"Super GT"},{"Elegant"},{"Journey"},{"Bike"},{"Mountain Bike"},{"Beagle"},{"Cropdust"},{"Stunt"},
	{"Tanker"}, {"Roadtrain"},{"Nebula"},{"Majestic"},{"Buccaneer"},{"Shamal"},{"Hydra"},{"FCR-900"},
	{"NRG-500"},{"HPV1000"},{"Cement Truck"},{"Tow Truck"},{"Fortune"},{"Cadrona"},{"FBI Truck"},
	{"Willard"},{"Forklift"},{"Tractor"},{"Combine"},{"Feltzer"},{"Remington"},{"Slamvan"},
	{"Blade"},{"Freight"},{"Streak"},{"Vortex"},{"Vincent"},{"Bullet"},{"Clover"},{"Sadler"},
	{"Firetruck LA"},{"Hustler"},{"Intruder"},{"Primo"},{"Cargobob"},{"Tampa"},{"Sunrise"},{"Merit"},
	{"Utility"},{"Nevada"},{"Yosemite"},{"Windsor"},{"Monster A"},{"Monster B"},{"Uranus"},{"Jester"},
	{"Sultan"},{"Stratum"},{"Elegy"},{"Raindance"},{"RC Tiger"},{"Flash"},{"Tahoma"},{"Savanna"},
	{"Bandito"},{"Freight Flat"},{"Streak Carriage"},{"Kart"},{"Mower"},{"Duneride"},{"Sweeper"},
	{"Broadway"},{"Tornado"},{"AT-400"},{"DFT-30"},{"Huntley"},{"Stafford"},{"BF-400"},{"Newsvan"},
	{"Tug"},{"Trailer 3"},{"Emperor"},{"Wayfarer"},{"Euros"},{"Hotdog"},{"Club"},{"Freight Carriage"},
	{"Trailer 3"},{"Andromada"},{"Dodo"},{"RC Cam"},{"Launch"},{"Police Car (LSPD)"},{"Police Car (SFPD)"},
	{"Police Car (LVPD)"},{"Police Ranger"},{"Picador"},{"S.W.A.T. Van"},{"Alpha"},{"Phoenix"},{"Glendale"},
	{"Sadler"},{"Luggage Trailer A"},{"Luggage Trailer B"},{"Stair Trailer"},{"Boxville"},{"Farm Plow"},
	{"Utility Trailer"}
};

new rInfo[MAX_PLAYERS][ReportInfo];
new User[MAX_PLAYERS][PlayerInfo];
new ServerInfo[ServerData];
new lInfo[MAX_DEPLOYABLE_LABEL][LabelInfo];

new
	DamagedPlayer[MAX_PLAYERS][5][24], 
	DamagedStamp[MAX_PLAYERS][5], DamagedWeapon[MAX_PLAYERS][5], BadNames[100][100], BadNameCount = 0, ForbiddenWords[100][100], ForbiddenWordCount = 0,
    VoteKickReason[64], VoteKickTarget = INVALID_PLAYER_ID, VoteKickHappening = 0, bool:HasAlreadyVoted[MAX_PLAYERS char], MaxVKICK = 2, 
	KickTime = 60, svotes = 0, avotes = 0, VoteTimer
;

// Variables

new DB:Database, new_Warn[MAX_PLAYERS];

#if defined USE_RCON_PROTECTION
	// OPRL is included in the script if the RCON Protection is turned on.
	#include <OPRL>
	new bool:_RCON[MAX_PLAYERS];
	new _RCONwarn[MAX_PLAYERS];
#endif

stock st[90];

new SpecInt[MAX_PLAYERS][2], Float:SpecPos[MAX_PLAYERS][4];

//============================================================================//

public OnFilterScriptInit()
{
	new day, month, year, hour, sec, mins, result = GetTickCount();

	getdate(year, month, day);
	gettime(hour, mins, sec);
	
	format(VoteKickReason, sizeof(VoteKickReason), "None");
	VoteKickHappening = 0;
	avotes = 0;
	svotes = 0;
	VoteKickTarget = INVALID_PLAYER_ID;
	KillTimer(VoteTimer);
	
	//////////////////////
	
	foreach(new i : Player)
		HasAlreadyVoted{i} = false;
	
	for(new i; i < MAX_REPORTS; i++)
		ResetReport(i);
	
	// Checks the JakAdmin and logs folder if exist, otherwise sends a print message.
	checkfolder();

	print("\n");

	// Loads juser.db
	loadb();
	Config();

	// Ping Timer (if set to true)
	SetTimer("PingCheck", 1000, true);
	// Punishment Timer Handler
	SetTimer("PunishmentHandle", 1000, true);
	// GamePlay
	SetTimer("GamePlay", 1000, true);

	foreach(new i : Player)
		OnPlayerConnect(i);
		
	print("----------------------------------------------------------------");
	printf("\nJake's Admin System %s (January 2018 release)", VERSION);
	printf("[JakAdmin] Date: %02i/%02i/%02i | Time: %02d:%02d:%02d", day, month, year, hour, mins, sec);	
	printf("[Benchmark] Loaded in: %i ms", (GetTickCount() - result));
	print("Filterscript Executed...\n");
	print("----------------------------------------------------------------\n");
	return 1;
}

public OnFilterScriptExit()
{
	new day, month, year, hour, sec, mins, result = GetTickCount();
	getdate(year, month, day);
	gettime(hour, mins, sec);
	
	// Closing juser.db
	closedb();
	
	for(new c; c < MAX_REPORTS; c++)
	{
	    ResetReport(c);
	}
	
	foreach(new i : Player)
	{
	    if(IsValidVehicle(User[i][pCar]))
	    {
	        DestroyVehicle(User[i][pCar]);
	    }
	    OnPlayerDisconnect(i, 1);
		User[i][accountLogged] = 0;
	}
	
	print("----------------------------------------------------------------");
	printf("\nJake's Admin System %s (January 2018 release)", VERSION);
	printf("[JakAdmin] Date: %02i/%02i/%02i | Time: %02d:%02d:%02d", day, month, year, hour, mins, sec);	
	printf("[Benchmark] Unloaded in: %i ms", (GetTickCount() - result));
	print("Filterscript Unloaded...\n");
	print("----------------------------------------------------------------\n");
	return 1;
}

function:IsSeatAvailable(vehicleid, seat)
{
	new carmodel = GetVehicleModel(vehicleid);

	new OneSeatVehicles[38] =
	{
	    425, 430, 432, 441, 446, 448, 452, 453,
		454, 464, 465, 472, 473, 476, 481, 484,
		485, 486, 493, 501, 509, 510, 519, 520,
		530, 531, 532, 539, 553, 564, 568, 571,
		572, 574, 583, 592, 594, 595
	};

	for(new i = 0; i < sizeof(OneSeatVehicles); i++)
	{
	    if(carmodel == OneSeatVehicles[i])
			return 0;
	}
	
	foreach(new i : Player)
	{
	    if(GetPlayerVehicleID(i) == vehicleid && GetPlayerVehicleSeat(i) == seat)
			return 0;
	}
	return 1;
}

function:EndVoteKick(playerid)
{
	new
		string[128]
	;

	if(svotes > avotes) 
	{
	    format(string, sizeof(string), "* The time has run out! Votes for yes: %i | Votes for no: %i", svotes, avotes);
	    SendClientMessageToAll(COLOR_ORANGE, string);
		format(string, sizeof(string), "* %s is kicked for %s.", pName(VoteKickTarget), VoteKickReason);
		SendClientMessageToAll(COLOR_RED, string);
		KickDelay(VoteKickTarget);
	}
	else
	{
	    format(string, sizeof(string), "* The time has run out! Votes for yes: %i | Votes for no: %i", svotes, avotes); 
	    SendClientMessageToAll(COLOR_ORANGE, string); 
		format(string, sizeof(string), "* Failed to get %s kicked, They stay in the server.", pName(VoteKickTarget));
		SendClientMessageToAll(COLOR_RED, string);
	}
	
	if(svotes == 0 && avotes == 0)
	{
	    SendClientMessageToAll(COLOR_RED, "* The time has run out, and nobody has voted!");
		format(string, sizeof(string), "* Failed to get %s kicked, They stay in the server.", pName(VoteKickTarget));
		SendClientMessageToAll(COLOR_RED, string);
	}

	format(VoteKickReason, sizeof(VoteKickReason), "None");
	VoteKickHappening = 0;
	avotes = 0;
	svotes = 0;
	VoteKickTarget = INVALID_PLAYER_ID;
	KillTimer(VoteTimer);
	//////////////////////
	foreach(new i : Player)
	{
		HasAlreadyVoted{i} = false;
	}
	return 1;
}

function:PunishmentHandle()
{
	new string[128];

	foreach(new i : Player)
	{
		if(User[i][accountJail])
		{
		    if(User[i][accountJailSec] >= 1)
		    {
		        User[i][accountJailSec] --;
		    }
	        else if(User[i][accountJailSec] == 0)
	        {
	            User[i][accountJail] = 0;
	            format(string, sizeof(string), "** %s has served their admin-jail time.", pName(i));
				SendClientMessageToAll(COLOR_ADMIN, string);
				SpawnPlayer(i);
	        }
		}
		if(User[i][accountMuted])
		{
		    if(User[i][accountMuteSec] >= 1)
		    {
		        User[i][accountMuteSec] --;
		    }
	        else if(User[i][accountMuteSec] == 0)
	        {
	            User[i][accountMuted] = 0;
	            format(string, sizeof(string), "** %s has served their mute punishment.", pName(i));
				SendClientMessageToAll(COLOR_ADMIN, string);
	        }
		}
		if(User[i][accountCMuted])
		{
		    if(User[i][accountCMuteSec] >= 1)
		    {
		        User[i][accountCMuteSec] --;
		    }
	        else if(User[i][accountCMuteSec] == 0)
	        {
	            User[i][accountCMuted] = 0;
	            format(string, sizeof(string), "** %s has served their command-mute punishment.", pName(i));
				SendClientMessageToAll(COLOR_ADMIN, string);
	        }
		}
	}
	return 1;
}

function:PingCheck()
{
	new string[128];
	
    foreach(new i : Player)
	{
		GetPlayerPos(i, User[i][accountAFKPos][0], User[i][accountAFKPos][1], User[i][accountAFKPos][2]);
	
		if(GetPlayerState(i) >= 1 && GetPlayerState(i) <= 3)
		{
			if(IsPlayerInRangeOfPoint(i, 2.0, User[i][accountAFKPos][0], User[i][accountAFKPos][1], User[i][accountAFKPos][2])) 
			{
				if(++User[i][accountAFK] >= ServerInfo[AFKTime] && ServerInfo[AFKTime]) 
				{
					format(string, sizeof(string), "** %s was kicked from the server. (Reason: Idle for %d seconds)", pName(i), User[i][accountAFK]);
					SendClientMessageToAll(COLOR_ADMIN, string);
					format(string, sizeof(string), "* You have been kicked from the server. (Idle for %d seconds)", User[i][accountAFK]);
					SendClientMessage(i, -1, string);
					return KickDelay(i);
				}
			}
		
			User[i][accountTabbed] ++;
			if(ServerInfo[TabTime] && User[i][accountTabbed] >= ServerInfo[TabTime])
			{
				format(string, sizeof(string), "** %s was kicked from the server. (Reason: Alt-Tabbed for %d seconds)", pName(i), User[i][accountTabbed]);
				SendClientMessageToAll(COLOR_ADMIN, string);
				format(string, sizeof(string), "* You have been kicked from the server. (Alt-Tabbing for %d seconds)", User[i][accountTabbed]);
				SendClientMessage(i, -1, string);
				return KickDelay(i);
			}
		}
	  
		if(User[i][accountGod])
		{
            SetPlayerHealth(i, 100000);
		}

	    if(GetPlayerPing(i) > ServerInfo[MaxPing] && ServerInfo[MaxPing])
		{
			format(string, sizeof(string), "** %s was kicked from the server (Reason: High Ping [%d/%d])", pName(i), GetPlayerPing(i), ServerInfo[MaxPing]);
			SendClientMessageToAll(COLOR_ADMIN, string);
			return KickDelay(i);
		}
	}
	return 1;
}

function:GamePlay()
{
	foreach(new playerid : Player)
	{
		if(User[playerid][accountLogged] == 1)
		{
			User[playerid][accountGame][0] += 1;
			if(User[playerid][accountGame][0] == 60)
			{
		        User[playerid][accountGame][0] = 0;
		        User[playerid][accountGame][1] += 1;
		        if(User[playerid][accountGame][1] >= 59 && User[playerid][accountGame][0] == 0)
		        {
		            User[playerid][accountGame][1] = 0;
		            User[playerid][accountGame][2] += 1;
		        }
			}
		}
	}
	return 1;
}

public OnPlayerConnect(playerid)
{
	new temp_ban, bQuery[128], reason[128], admin[24], when[32], DBResult:jResult, Query[128], DBResult: Result, fIP[20];
    static string[128];
	string[0] = 0;
    
	if(ServerInfo[AntiName])
	{
		for(new s = 0; s < BadNameCount; s++)
		{
  			if(!strcmp(BadNames[s], pName(playerid), true))
  			{
			    format(string, sizeof string, "** %s was kicked from the server. (Forbidden Name)", pName(playerid));
			    SendClientMessageToAll(COLOR_RED, string);
			    print(string);
			    SaveLog("kicklog.txt", string);
			    return KickDelay(playerid);
			}
	    }
	}

	for(new x; x < _: PlayerInfo; ++x ) User[playerid][PlayerInfo: x] = 0;
	User[playerid][SpecID] = INVALID_PLAYER_ID;
	User[playerid][accountSkin] = -1;
	
	for(new i; i < 5; i++)
	{
		DamagedStamp[playerid][i] = 0;
		format(DamagedPlayer[playerid][i], 24, "");
	}
		
	#if defined USE_RCON_PROTECTION
		_RCON[playerid] = false;
		_RCONwarn[playerid] = 0;
	#endif

	User[playerid][accountMarker] = false;
	User[playerid][accountDuty] = 0;
	User[playerid][SpamTime] = 0;
	User[playerid][accountTemporary] = false;
	User[playerid][accountAdminEx] = 0;
	User[playerid][accountGameEx] = gettime();
	User[playerid][accountPM] = 1;
	DestroyDynamic3DTextLabel(User[playerid][accountLabel]);

	User[playerid][accountGod] = 0;
	
    GetPlayerName(playerid, User[playerid][accountName], MAX_PLAYER_NAME);
	GetPlayerIp(playerid, User[playerid][accountIP], 20);

	new_Warn[playerid] = 0;

	LoadAKA(playerid);
	////////////////////////////////////////////////////////////////////////////
	new ip_month, ip_day, ip_year, ip_hour, ip_minute, ip_second;
	getdate(ip_year, ip_month, ip_day);
	gettime(ip_hour, ip_minute, ip_second);
	format(bQuery, sizeof(bQuery), "SELECT * FROM `ips` WHERE `username` = '%s' AND `ip` = '%s'", DB_Escape(pName(playerid)), DB_Escape(User[playerid][accountIP]));
	jResult = db_query(Database, bQuery);
	if(!db_num_rows(jResult))
	{
		format(bQuery, sizeof(bQuery), "INSERT INTO `ips` (`username`, `ip`, `date`, `time`) VALUES('%s', '%s', '%02d-%02d-%d', '%02d:%02d:%02d')", DB_Escape(pName(playerid)), DB_Escape(User[playerid][accountIP]), ip_month, ip_day, ip_year, ip_hour, ip_minute, ip_second);
		db_query(Database, bQuery);
	}
	else
	{
        format(bQuery, sizeof(bQuery), "DELETE FROM `ips` WHERE `ip` = '%s'", DB_Escape(User[playerid][accountIP]));
	    db_query(Database, bQuery);
		format(bQuery, sizeof(bQuery), "INSERT INTO `ips` (`username`, `ip`, `date`, `time`) VALUES('%s', '%s', '%02d-%02d-%d', '%02d:%02d:%02d')", DB_Escape(pName(playerid)), DB_Escape(User[playerid][accountIP]), ip_month, ip_day, ip_year, ip_hour, ip_minute, ip_second);
		db_query(Database, bQuery);
	}
	////////////////////////////////////////////////////////////////////////////
	format(bQuery, sizeof(bQuery), "SELECT * FROM `bans` WHERE `username` = '%s'", DB_Escape(pName(playerid)));
	jResult = db_query(Database, bQuery);

	if(db_num_rows(jResult) && CheckBan(User[playerid][accountIP]))
	{  
		SetPVarInt(playerid, "ban_id", db_get_field_assoc_int(jResult, "banid"));
	    db_get_field_assoc(jResult, "banby", admin, sizeof(admin));
	    db_get_field_assoc(jResult, "banreason", reason, 128);
	    db_get_field_assoc(jResult, "banwhen", when, sizeof(when));
		temp_ban = db_get_field_assoc_int(jResult, "temporary_ban");
		
		if(gettime() > temp_ban && temp_ban != 340703845)
		{
			UnbanAccountEx(playerid);
		}
		else
		{
			for(new i; i < 100; i++) 
			{
				SendClientMessage(playerid, -1, " ");
			}
			ShowBan(playerid, GetPVarInt(playerid, "ban_id"), admin, reason, when, temp_ban);
			KickDelay(playerid);
		}
		return db_free_result(jResult), 1;
	}
	else if(db_num_rows(jResult) && !CheckBan(User[playerid][accountIP]))
	{
	    SetPVarInt(playerid, "ban_id", db_get_field_assoc_int(jResult, "banid"));
	    db_get_field_assoc(jResult, "banby", admin, sizeof(admin));
	    db_get_field_assoc(jResult, "banreason", reason, 128);
	    db_get_field_assoc(jResult, "banwhen", when, sizeof(when));
		temp_ban = db_get_field_assoc_int(jResult, "temporary_ban");
		
		if(gettime() > temp_ban && temp_ban != 340703845)
		{
			UnbanAccountEx(playerid);
		}
		else
		{
			for(new i; i < 100; i++) 
			{
				SendClientMessage(playerid, -1, " ");
			}
			ShowBan(playerid, GetPVarInt(playerid, "ban_id"), admin, reason, when, temp_ban);
			KickDelay(playerid);
		}
		return db_free_result(jResult), 1;
	}
	else if(!db_num_rows(jResult) && CheckBan(User[playerid][accountIP]))
	{
		for(new i; i < 100; i++) 
		{	
			SendClientMessage(playerid, -1, " ");
		}
		SendClientMessage(playerid, COLOR_RED, "* Your IP address is banned from the server.");
	    BanAccount(playerid, "JakAdmin", "IP Banned");

		KickDelay(playerid);
		return db_free_result(jResult), 1;
	}
	if(ServerInfo[JoinMsg])
	{
		format(string, sizeof(string), "[Join] %s (ID: %d) has joined the server.", pName(playerid), playerid);
		SendClientMessageToAll(COLOR_GREY, string);
	}
	////////////////////////////////////////////////////////////////////////////
	if(ServerInfo[AutoLogin])
	{
	    format(Query, sizeof(Query), "SELECT `password`, `question`, `answer`, `IP` FROM `users` WHERE `username` = '%s'", DB_Escape(User[playerid][accountName]));
	    Result = db_query(Database, Query);
	}
	else
	{
	    format(Query, sizeof(Query), "SELECT `password`, `question`, `answer` FROM `users` WHERE `username` = '%s'", DB_Escape(User[playerid][accountName]));
	    Result = db_query(Database, Query);
	}
	////////////////////////////////////////////////////////////////////////////
    if(db_num_rows(Result))
    {
        db_get_field_assoc(Result, "password", User[playerid][accountPassword], 129);
    	db_get_field_assoc(Result, "question", User[playerid][accountQuestion], 92);
    	db_get_field_assoc(Result, "answer", User[playerid][accountAnswer], 129);
        
        if(ServerInfo[AutoLogin])
        {
        	db_get_field_assoc(Result, "IP", fIP, 20);
			if(strcmp(fIP, User[playerid][accountIP], true) == 0)
	        {
	            SendClientMessage(playerid, -1, "You have been auto logged in.");
	            LoginPlayer(playerid);
	        }
			else
			{
			    #if defined USE_DIALOG
			        if(!strcmp(User[playerid][accountQuestion], "none", true))
						Dialog_Show(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, ""green"Login", "Welcome back to the server!\nYour account exists in our database.\nPlease insert your account's password below to login.", "Login", "Quit");
			        else
        				Dialog_Show(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, ""green"Login", "Welcome back to the server!\nYour account exists in our database.\nPlease insert your account's password below to login.\n\nPress Forget button if you have forgotten your account's password", "Login", "Forget");
				#else
				    SendClientMessage(playerid, COLOR_ORANGE, "LOGIN: /login [password] to login to your account.");
				#endif
			}
        }
        else
        {
			#if defined USE_DIALOG
				if(!strcmp(User[playerid][accountQuestion], "none", true))
					Dialog_Show(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, ""green"Login", "Welcome back to the server!\nYour account exists in our database.\nPlease insert your account's password below to login.", "Login", "Quit");
				else
					Dialog_Show(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, ""green"Login", "Welcome back to the server!\nYour account exists in our database.\nPlease insert your account's password below to login.\n\nPress Forget button if you have forgotten your account's password", "Login", "Forget");
			#else
				SendClientMessage(playerid, COLOR_ORANGE, "LOGIN: /login [password] to login to your account.");
			#endif
		}
	}
    else
    {
        #if defined USE_DIALOG
			if(ServerInfo[RegisterOption])
				Dialog_Show(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, ""green"Register", "Welcome to the Server!\nYour account doesn't exist in our database, Please insert your password below.\n\n"red"* You can skip the server account registration by pressing SKIP.", "Register", "Skip");
			else
				Dialog_Show(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, ""green"Register", "Welcome to the Server!\nYour account doesn't exist in our database, Please insert your password below.", "Register", "Quit");
		#else
			if(ServerInfo[RegisterOption])
				SendClientMessage(playerid, COLOR_RED, "* You may skip the server account-registration.");
				SendClientMessage(playerid, COLOR_ORANGE, "REGISTER: /register [password] to register your account.");
			else
				SendClientMessage(playerid, COLOR_ORANGE, "REGISTER: /register [password] to register your account.");
		#endif
	}
	db_free_result(Result);
	////////////////////////////////////////////////////////////////////////////
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	new string[128], reasonstr[24];

	if(User[playerid][accountCage])
		DestroyPlayerObject(playerid, User[playerid][accountCageObject]);
	
	if(User[playerid][accountTemporary])
	{
	    User[playerid][accountAdmin] = User[playerid][accountAdminEx];
	    User[playerid][accountAdminEx] = 0;
	    User[playerid][accountTemporary] = false;
	}

	for(new c; c < MAX_REPORTS; c++)
	{
	    if(rInfo[c][reportTaken])
	    {
	        if(rInfo[c][reporterID] == playerid || rInfo[c][reportedID] == playerid)
	        {
				ResetReport(c);
	        }
	    }
	}

	for(new x=0; x<MAX_PLAYERS; x++)
	    if(GetPlayerState(x) == PLAYER_STATE_SPECTATING && User[x][SpecID] == playerid)
   		   	AdvanceSpectate(x);

	if(ServerInfo[JoinMsg])
	{
		switch(reason)
		{
			case 0: reasonstr = "Crashed";
			case 1: reasonstr = "Left";
			case 2: reasonstr = "Kicked/Banned";
		}
		format(string, sizeof(string), "[%s] %s (ID: %d) quit the server.", reasonstr, pName(playerid), playerid);
		SendClientMessageToAll(COLOR_GREY, string);
	}	
			
    if(IsValidVehicle(User[playerid][pCar])) 
		EraseVeh(User[playerid][pCar]);

    //Saves the statistics to the .db.
	SaveData(playerid);

	if(VoteKickHappening && VoteKickTarget == playerid)
	{
		format(string, sizeof(string), "** %s has left the server while they are being voted for a kick.", pName(playerid));
		SendClientMessageToAll(COLOR_ADMIN, string); 
		//////////////////////
		format(VoteKickReason, sizeof(VoteKickReason), "None");
		VoteKickHappening = 0;
		avotes = 0;
		svotes = 0;
		VoteKickTarget = INVALID_PLAYER_ID;
		KillTimer(VoteTimer);
		//////////////////////
		foreach(new i : Player)
		{
			HasAlreadyVoted{i} = false;
		}
	}

	User[playerid][accountGameEx] = 0;
	return 1;
}

public OnPlayerUpdate(playerid)
{
	if(User[playerid][accountTabbed] >= 1)
	{
		User[playerid][accountTabbed] = 0;
	}
	
	User[playerid][accountAFK] = 0;
	return 1;
}

public OnPlayerSpawn(playerid)
{
	// Label Deploy
	if(User[playerid][accountAdmin] > 0)
		User[playerid][accountLabel] = CreateDynamic3DTextLabel(GetAdminRank(User[playerid][accountAdmin]), 0xFF0000FF, 0, 0, 0.30, 25, playerid, .testlos = 1);
	// Cage Check
	if(User[playerid][accountCage])
	{
		CageNikka(playerid);
		SendClientMessage(playerid, COLOR_ADMIN, "* Cage deployed, You are previously placed in a cage by an admin.");		
	}
	// Jail Check
    if(User[playerid][accountJail])
    {
		SetTimerEx("JailPlayer", 2000, 0, "d", playerid);
		SendClientMessage(playerid, COLOR_RED, "* You are previously jailed by an admin, You'll serve your sentence.");
		SendClientMessage(playerid, COLOR_ADMIN, "Placing back in the cell...");
	}
	// Saved Skin
	if(User[playerid][accountUseSkin] && User[playerid][accountAdmin])
		SetPlayerSkin(playerid, User[playerid][accountSkin]);
	return 1;
}

function:JailPlayer(playerid)
{
	static string[92];
	string[0] = 0;

	SetPlayerPos(playerid, 197.6661, 173.8179, 1003.0234);
	SetPlayerInterior(playerid, 3);
	SetCameraBehindPlayer(playerid);

    format(string, sizeof(string), "You have been placed in jail for %d seconds.", User[playerid][accountJailSec]);
    SendClientMessage(playerid, COLOR_RED, string);
    return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float: amount, weaponid, bodypart)
{
	if(issuerid != INVALID_PLAYER_ID)
	{
		DamagedWeapon[playerid][4] = DamagedWeapon[playerid][3];
		DamagedWeapon[playerid][3] = DamagedWeapon[playerid][2];
		DamagedWeapon[playerid][2] = DamagedWeapon[playerid][1];
		DamagedWeapon[playerid][1] = DamagedWeapon[playerid][0];
		DamagedWeapon[playerid][0] = weaponid;
	
		DamagedStamp[playerid][4] = DamagedStamp[playerid][3];
		DamagedStamp[playerid][3] = DamagedStamp[playerid][2];
		DamagedStamp[playerid][2] = DamagedStamp[playerid][1];
		DamagedStamp[playerid][1] = DamagedStamp[playerid][0];
		DamagedStamp[playerid][0] = gettime();
	
		format(DamagedPlayer[playerid][4], 24, DamagedPlayer[playerid][3]);
		format(DamagedPlayer[playerid][3], 24, DamagedPlayer[playerid][2]);
		format(DamagedPlayer[playerid][2], 24, DamagedPlayer[playerid][1]);
		format(DamagedPlayer[playerid][1], 24, DamagedPlayer[playerid][0]);
		format(DamagedPlayer[playerid][0], 24, pName(issuerid));
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	for(new x=0; x<MAX_PLAYERS; x++)
	    if(GetPlayerState(x) == PLAYER_STATE_SPECTATING && User[x][SpecID] == playerid)
   		   	AdvanceSpectate(x);

	User[playerid][accountDeaths] ++;
	if(killerid != INVALID_PLAYER_ID)
	{
		User[killerid][accountKills] ++;
	}
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	foreach(new i : Player)
	{
        if(vehicleid == User[i][pCar])
		{
		    EraseVeh(vehicleid);
        }
	}
	return 1;
}

public OnPlayerText(playerid, text[])
{
	new string[128];

	User[playerid][accountAFK] = 0;
	
	if(ServerInfo[LockChat] && User[playerid][accountAdmin] < 1)
		return SendClientMessage(playerid, COLOR_RED, "* Chat has been disabled by an admin."), 0;
	
	if(ServerInfo[AntiAd] && User[playerid][accountAdmin] < 3)
	{
		if(IsAdvertisement(text))
		{
			format(string, sizeof(string), "Warning: Player %s(ID: %d) may be server advertising: '%s'.", pName(playerid), playerid, text);
			SendAdmin(COLOR_RED, string);
			return 0;
		}
	}

	if(User[playerid][accountMuted])
	{
		if(User[playerid][accountMuteSec] > 0)
		{
			format(string, sizeof(string), "You are muted, You can talk in %d seconds.", User[playerid][accountMuteSec]);
			SendClientMessage(playerid, COLOR_ORANGE, string);
		}
		else if(User[playerid][accountMuteSec] == -1) SendClientMessage(playerid, COLOR_ORANGE, "You are permanently muted from talking.");
		return 0;
	}
	
	if(ServerInfo[AntiSpam])
	{
		if((!User[playerid][accountAdmin] && !IsPlayerAdmin(playerid)))
		{
			if((GetTickCount() - User[playerid][SpamTime]) < (1000*SPAM_TIMELIMIT))
			{
				format(string, sizeof(string), "* You have to wait for %d seconds before you can send another chat/command.", SPAM_TIMELIMIT);
				SendClientMessage(playerid, COLOR_RED, string);
				return 0;
			}
		}
		User[playerid][SpamTime] = GetTickCount();
	}
	
	if(text[0] == '#' && User[playerid][accountAdmin] >= 1)
	{
		format(string, sizeof( string ), "[AdminChat]"white" %s %s: %s", GetAdminRank(User[playerid][accountAdmin]), pName(playerid), text[1]);
		SendAdmin(0x9ACD32AA, string);
		printf("[AdminChat] %s %s: %s", GetAdminRank(User[playerid][accountAdmin]), pName(playerid), text[1]);

		SaveLog("adminchat.txt", string);
		return 0;
	}
	if(text[0] == '@' && User[playerid][accountAdmin] >= 4)
	{
		format(string, sizeof( string ), "[LAChat]"white" %s %s: %s", GetAdminRank(User[playerid][accountAdmin]), pName(playerid), text[1]);
		foreach(new i : Player) if(User[i][accountAdmin] >= 4)
		{
			SendClientMessage(i, 0xFFD700FF, string);
		}
		printf("[LAChat] %s %s: %s", GetAdminRank(User[playerid][accountAdmin]), pName(playerid), text[1]);
		SaveLog("hachat.txt", string);
		return 0;
	}
	
	if(ServerInfo[AntiSwear])
	{
		for(new s = 0; s < ForbiddenWordCount; s++)
	    {
			new pos;
			while((pos = strfind(text,ForbiddenWords[s],true)) != -1) for(new i = pos, j = pos + strlen(ForbiddenWords[s]); i < j; i++) text[i] = '*';
		}
	}
	return 1;
}

public OnRconCommand(cmd[])
{
	// Credits to Stinged
	new command[32], pos;
	while (cmd[pos] > ' ')
	{
		command[pos] = cmd[pos];
		pos++;
	}
	format(command, sizeof (command), "rcon_%s", command);
	while (cmd[pos] == ' ')
		pos++;

	if (!cmd[pos]) return CallLocalFunction(command, "s", "\1");
	return CallLocalFunction(command, "s", cmd[pos]);
}

//============================================================================//
// RCON Commands

RCON:jcmds(params[])
{
	print("\nJakAdmin RCON Panel Commands:");
	print("USAGE in game: /rcon [cmds] [parameters]");
	print("USAGE in panel: [cmds] [parameters]");
	print("* a (admin chat) la (head admin chat) jconfig");
	print("* message (msg) set(temp)level aka removeacc fakecmd reloadcfg\n");
	return 1;
}

RCON:jconfig(params[])
{
	Config();
	return 1;
}

RCON:reloadcfg(params[])
{
	SendAdmin(COLOR_YELLOW, "[CFG] Someone from the panel has reload the cfgs files for JakAdmin.");
	checkfolder();
	print("[CFG] Someone from the panel has reload the cgs files for JakAdmin.");
	return 1;
}

RCON:message(params[])
{
	new string[128],id, text[128];

	if(sscanf(params, "us[128]", id, text)) 
		return print("USAGE: /rcon message [playerid] [text]"), 1;
		
	if(id == INVALID_PLAYER_ID) 
		return  print("ERROR: Player not connected."), 1;
		
	format(string, sizeof(string), "* Message from RCON: %s", text);
	SendClientMessage(id, COLOR_LIGHTBLUE, string);
	printf("* Message sent to %s: %s", pName(id), text);
	return 1;
} 

RCON:msg(params[]) return rcon_message(params);

RCON:fakecmd(params[])
{
	new id, cmdtext[128];

	if(sscanf(params, "us[128]", id, cmdtext)) 
		return print("USAGE: /rcon fakecmd [playerid] [command]"), 1;
		
	if(id == INVALID_PLAYER_ID) 
		return  print("ERROR: Player not connected."), 1;
		
	if(strfind(params, "/", false) != -1)
	{
        CallRemoteFunction("OnPlayerCommandText", "is", id, cmdtext);
	    printf("Fake command sent to %s with %s", pName(id), cmdtext);
	}
	else print("ERROR: Add '/' before putting the command name to avoid the command unknown error.");
	return 1;
} 

RCON:a(params[])
{
	new string[128];

	if(isnull(params))
		return print("USAGE: /rcon a [text]"), 1;
	
	format(string, sizeof(string), "[AdminChat]"white" RCON: %s", params);
	SendAdmin(COLOR_YELLOW, string);
	printf("[AdminChat] RCON: %s", params);
	SaveLog("adminchat.txt", string);
	return 1;
}

RCON:la(params[])
{
	new string[128];

	if(isnull(params))
		return print("USAGE: /rcon la [text]"), 1;
		
	format(string, sizeof(string), "[LAChat]"white" RCON: %s", params);
	foreach(new i : Player) if(User[i][accountAdmin] >= 4)
	{
		SendClientMessage(i, 0xFFD700FF, string);
	}
	
	printf("[LAChat] RCON: %s", params);
	SaveLog("hachat.txt", string);
	return 1;
}

RCON:removeaccount(params[])
{
	new name[24], DBResult:result, query[128];
	
	if(sscanf(params, "s[24]", name))
		return print("USAGE: /rcon removeaccount [name]"), 1;

	new id = ReturnUser(name);
	
	if(IsPlayerConnected(id))
		return printf("ERROR: '%s' is in game. (PlayerID: %d)", id), 1;
	
	format(query, sizeof(query), "SELECT * FROM `users` WHERE `username` = '%s'", DB_Escape(name));
	result = db_query(Database, query);
	
	if(db_num_rows(result))
	{
		format(query, sizeof(query), "DELETE FROM `users` WHERE `username` = '%s'", DB_Escape(name));
		db_query(Database, query);

		printf("[Removed] You have removed the account: '%s'", name);
		printf("[ACCOUNT] Someone from the panel has removed '%s's account' (/removeaccount)", name);
	}
	else
	{
	    printf("ERROR: '%s' doesn't exist.", name);
	}
	db_free_result(result);		
	return 1;
}

#if defined USE_AKA
RCON:aka(params[])
{
    new id, query[92], pAka[128*10], DBResult:result;
	
	if(sscanf(params, "u", id))
		return print("USAGE: /rcon aka [playerid]"), 1;
	
	if(id == INVALID_PLAYER_ID)
		return print("ERROR: Player not connected."), 1;
		
    format(query, sizeof(query), "SELECT * FROM `aka` WHERE `ip` = '%s'", User[id][accountIP]);
    result = db_query(Database, query);
	
	if(db_num_rows(result))
	{
		db_get_field_assoc(result, "name", pAka, sizeof(pAka));		
		
		printf("[AKA] %s's other aliases... (%s)", pName(id), User[id][accountIP]);
		printf("[AKA] %s", pAka);
	} 
	else
	{
		printf("ERROR: IP (%s) isn't found on the database.", User[id][accountIP]);
	}
	db_free_result(result);
    return 1;
}
#endif

RCON:settemplevel(params[])
{
	new string[128], id, level;

	if(sscanf(params, "ud", id, level)) 
		return print("USAGE: /rcon settemplevel [playerid] [level]"), 1;
		
	if(id == INVALID_PLAYER_ID) 
		return print("ERROR: Player not connected."), 1;
		
	if(level < 0 || level > 5) 
		return print("ERROR: Levels shouldn't go below zero and shouldn't go above five."), 1;
		
	if(level == User[id][accountAdmin]) 
		return print("ERROR: Player is already in that level."), 1;
		
	if(!User[id][accountLogged]) 
		return print("ERROR: Player not logged in."), 1;

    if(User[id][accountAdmin] < level)
    {
        format(string, sizeof(string), "You have been temporarily-promoted to level %d by someone from the panel.", level);
		SendClientMessage(id, COLOR_YELLOW, string);
		printf("[Promoted] You have temporarily-promoted %s to level %d.", pName(id), level);
		format(string, sizeof(string), "You will be promoted back to your old level which is (%d) once you logout.", User[id][accountAdmin]);
		SendClientMessage(id, COLOR_GREEN, string);
    }
    else if(User[id][accountAdmin] > level)
    {
        format(string, sizeof(string), "You have been temporarily-demoted to level %d by someone from the panel.", level);
		SendClientMessage(id, COLOR_YELLOW, string);
		printf("[Demoted] You have temporarily-demoted %s to level %d.", pName(id), level);
		format(string, sizeof(string), "You will be promoted back to your old level which is (%d) once you logout.", User[id][accountAdmin]);
		SendClientMessage(id, COLOR_GREEN, string);
     }

	User[id][accountTemporary] = true;
	User[id][accountAdminEx] = User[id][accountAdmin];
    User[id][accountAdmin] = level;

	format(string, sizeof string, "Someone from the panel has set %s's administrative level to %d", pName(id), level);
	SaveLog("account.txt", string);

	SaveData(id); //Saving the whole data
	return 1;
}

RCON:setlevel(params[])
{
	new id, level, string[128];

    if(sscanf(params, "ud", id, level))
        return print("USAGE: /rcon setlevel [playerid] [level]"), 1;

	if(id == INVALID_PLAYER_ID) 
		return print("ERROR: Player not connected."), 1;
		
	if(level < 0 || level > 5) 
		return print("ERROR: Levels shouldn't go below zero and shouldn't go above five."), 1;
		
	if(level == User[id][accountAdmin]) 
		return print("ERROR: Player is already in that level."), 1;
	
	if(!User[id][accountLogged]) 
		return print("ERROR: Player not logged in."), 1;

    if(User[id][accountAdmin] < level)
    {
        format(string, sizeof(string), "You have been promoted to level %d by someone from the panel.", level);
		SendClientMessage(id, COLOR_YELLOW, string);
		printf("[Promoted] You have promoted %s to level %d.", pName(id), level);
    }
    else if(User[id][accountAdmin] > level)
    {
        format(string, sizeof(string), "You have been demoted to level %d by someone from the panel.", level);
		SendClientMessage(id, COLOR_YELLOW, string);
		printf("[Demoted] You have demoted %s to level %d.", pName(id), level);
    }

	if(User[id][accountTemporary])
	{
	   print("NOTE: The effect of /settemplevel has been removed since you used /setlevel on this player.");
	}
	
	User[id][accountTemporary] = false;
	User[id][accountAdminEx] = 0;
    User[id][accountAdmin] = level;

	format(string, sizeof string, "Someone in the panel has set %s's administrative level to %d", pName(id), level);
	SaveLog("account.txt", string);

	SaveData(id); //Saving the whole data
    return 1;
}	

//============================================================================//

public OnPlayerCommandReceived(playerid, cmdtext[])
{
	new string[128];

	User[playerid][accountAFK] = 0;
	
	#if defined PRINT_CMD
		printf("[cmd] %s typed: %s", pName(playerid), cmdtext);
	#endif 
	
	if(ServerInfo[AntiSpam])
	{
		if((!User[playerid][accountAdmin] && !IsPlayerAdmin(playerid)))
		{
			if((GetTickCount() - User[playerid][SpamTime]) < SPAM_TIMELIMIT)
			{
				format(string, sizeof(string), "* You have to wait for %d seconds before you can send another chat/command.", SPAM_TIMELIMIT);
				SendClientMessage(playerid, COLOR_RED, string);
				return 0;
			}
		}
		User[playerid][SpamTime] = GetTickCount();
	}	
	
	if(ServerInfo[ReadCmds])
	{
	    if(!ServerInfo[ReadCmd])
	    {
		    if(strfind(cmdtext, "cpass", true) == -1 || strfind(cmdtext, "register", true) == -1 || strfind(cmdtext, "login", true) == -1 || strfind(cmdtext, "setpass", true) == -1)
			{
			    format(string, sizeof(string), "* %s used cmd:"white" %s", pName(playerid), cmdtext);
			    foreach(new i : Player)
			    {
			        if(User[i][accountAdmin] >= 1 && User[i][accountAdmin] > User[playerid][accountAdmin] && i != playerid)
			        {
			            SendClientMessage(i, COLOR_GREEN, string);
			        }
			    }
			}
		}
		else
		{
			foreach(new x : Player)
			{
				if(GetPlayerState(x) == PLAYER_STATE_SPECTATING && User[x][SpecID] == playerid && User[x][SpecType] == ADMIN_SPEC_TYPE_PLAYER)
				{
			    	if(strfind(cmdtext, "cpass", true) == -1 || strfind(cmdtext, "register", true) == -1 || strfind(cmdtext, "login", true) == -1 || strfind(cmdtext, "setpass", true) == -1)
					{
						format(string, sizeof(string), "* %s used cmd:"white" %s", pName(playerid), cmdtext);
						SendClientMessage(x, COLOR_GREEN, string);
					}
				}
			}
		}
	}

	if(ServerInfo[AntiAd])
	{
		if(IsAdvertisement(cmdtext))
		{
			format(string, sizeof(string), "Warning: Player %s(ID: %d) may be server advertising: '%s'.", pName(playerid), playerid, cmdtext);
			SendAdmin(COLOR_RED, string);
			return 0;
		}
	}

	if(User[playerid][accountCMuted])
	{
		if(User[playerid][accountCMuteSec] > 0)
		{
			format(string, sizeof(string), "You are muted from using the commands, You can use commands in %d seconds.", User[playerid][accountCMuteSec]);
			SendClientMessage(playerid, COLOR_ORANGE, string);
	    }
		else if(User[playerid][accountCMuteSec] == -1) SendClientMessage(playerid, COLOR_ORANGE, "You are permanently muted from using commands.");
		return 0;
	}
    return 1;
}

//============================================================================//
//							Administrative Level 1-5                          //
//============================================================================//

CMD:hideme(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);
	
	switch(User[playerid][accountHide])
	{
		case false:
		{
			SendClientMessage(playerid, -1, "You are now "green"hidden"white" from the admins list.");
			User[playerid][accountHide] = true;
		}
		case true:
		{
			SendClientMessage(playerid, -1, "You are "red"visible"white" again in the admins list.");
			User[playerid][accountHide] = false;
		}
	}
	return 1;
}

CMD:jacmds(playerid, params[])
{
	static string[128 * 15], cb[64];
	string[0] = 0;
	cb[0] = 0;
	
	LoginCheck(playerid);
	LevelCheck(playerid, 1);
	
	if(User[playerid][accountAdmin] >= 1)
	{
	    format(cb, sizeof(cb), ""lightblue"-> %s\n", ServerInfo[AdminRank1]);
		strcat(string, cb);
		strcat(string, ""white"");
		strcat(string, "* /announce /kick /asay /settime /setweather /goto /ip /spawn /gotoco /flip /warn /remwarn /addnos\n");
		strcat(string, "* /repair (/reports /handlereport /denyreport /endreport /reporttalk) /aduty /weaps\n");
		strcat(string, "* /votekicktime /endvotekick /setwanted /setdlevel /entercar /saveskin /useskin /checkdamage\n");
		strcat(string, "* /tabbed /afk /richlist (/o)aka /god /hideme /laston /ostats\n");
		strcat(string, "*** {D0AEEB}Admin Chat: {FFD700}#"white" (Usage; #Hi I am JaKe)\n\n");
	}
	if(User[playerid][accountAdmin] >= 2)
	{
	    format(cb, sizeof(cb), ""lightblue"-> %s\n", ServerInfo[AdminRank2]);
		strcat(string, cb);
		strcat(string, ""white"");
		strcat(string, "* /disarm /explode /setinterior /setworld /heal /armour /clearchat /setskin /mute /unmute\n");
		strcat(string, "* /akill /spec /car /carcolor /eject /setvhealth /givecar /muted /jailed (/un)jail\n");
		strcat(string, "* /aweapons /jetpack /carpjob /addlabel /destroylabel /gotolabel /radiusrespawn (/rr)\n");
		strcat(string, "* /respawncar /ips /checkbreach (/un)cage /caged\n\n");
	}
	if(User[playerid][accountAdmin] >= 3)
	{
	    format(cb, sizeof(cb), ""lightblue"-> %s\n", ServerInfo[AdminRank3]);
		strcat(string, cb);
		strcat(string, ""white"");
		strcat(string, "* /setmoney /setscore /setcolor /slap /cname /(un)banip /giveweapon (/un)freeze /getall /bankrupt\n");
		strcat(string, "* /teleplayer /destroycar /sethealth /setfstyle /healall /armourall /force /checkban\n");
		strcat(string, "* /write /get /oban, /forbidword, /crash, /setvotekicklimit /hidemarker /setchocolate\n");
		strcat(string, "* /jconfig\n\n");
	}
	if(User[playerid][accountAdmin] >= 4)
	{
	    format(cb, sizeof(cb), ""lightblue"-> %s\n", ServerInfo[AdminRank4]);
		strcat(string, cb);
		strcat(string, ""white"");
		strcat(string, "* /saveallstats /cleardwindow /respawncars /setallweather /setalltime /giveallweapon\n");
		strcat(string, "* /giveallcash /giveallscore /kickall /disarmall /ejectall /mutecmd /unmutecmd\n");
		strcat(string, "* /setallskin /fakedeath /cmdmuted /lockchat /giveallchocolate /reloadcfg\n");
		strcat(string, "* /gmx /setonline /jsettings /setpass\n");
		strcat(string, "*** {D0AEEB}Lead Admin Chat: {FFD700}@"white" (Usage; @What's up losers?!)\n\n");
	}
	if(User[playerid][accountAdmin] >= 5 || IsPlayerAdmin(playerid))
	{
	    format(cb, sizeof(cb), ""lightblue"-> %s\n", ServerInfo[AdminRank5]);
		strcat(string, cb);
		strcat(string, ""white"");
		strcat(string, "* /set(temp)level /fakechat /fakecmd /makemegodadmin (/create/remove/set)account /rcons");
	}
	
	Dialog_Show(playerid, DIALOG_BEGIN, DIALOG_STYLE_MSGBOX, ""grey"Admin Commands", string, "Close", "");
	return 1;
}

//============================================================================//
//							Administrative Level One                          //
//============================================================================//

CMD:ostats(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);
	
	new name[24];
	if(sscanf(params, "s[24]", name))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /ostats [name]");
		
	Offline_ShowStatistics(playerid, name);
	return 1;
}

CMD:laston(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	new query[128], accountname[24], DBResult:result, laston[32], id;

	if(sscanf(params, "s[24]", accountname))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /laston [account name]");

	id = ReturnUser(accountname);
	if(IsPlayerConnected(id))
	{
		format(query, sizeof(query), "** %s was last seen "green"today. "white"They are "green"online "white"in the server "red"right now.", pName(id));
		SendClientMessage(playerid, -1, query);
	}
	else
	{
		format(query, sizeof(query), "SELECT `laston` FROM `users` WHERE `username` = '%s'", DB_Escape(accountname));
		result = db_query(Database, query);
		if(db_num_rows(result))
		{
			db_get_field_assoc(result, "laston", laston, 32);
			format(query, sizeof(query), "** %s was last seen on "red"%s"white".", accountname, laston);
			SendClientMessage(playerid, -1, query);
		}
		else
		{
			format(query, sizeof(query), "* '%s' isn't found in the database." ,accountname);
			SendClientMessage(playerid, COLOR_RED, query);
		}
		db_free_result(result);
	}
	return 1;
}

CMD:god(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 1);
	
	switch(User[playerid][accountGod])
	{
		case false:
		{
			//Removal of the weapons has been made.
			SendClientMessage(playerid, COLOR_GREEN, "God Mode On!");
			User[playerid][accountGod] = true;
		}
		case true:
		{
			User[playerid][accountGod] = false;
			SendClientMessage(playerid, COLOR_RED, "God Mode Off!");
			SetPlayerHealth(playerid, 100.0);
		}
	}
	return 1;
}

#if defined USE_AKA
CMD:oaka(playerid, params[])
{
    new ip[20], query[92], pAka[128*10], string[128 * 10], DBResult:result;

    LoginCheck(playerid);
	LevelCheck(playerid, 1);
	
	if(sscanf(params, "s[20]", ip))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /oaka [IP]");

    format(query, sizeof(query), "SELECT * FROM `aka` WHERE `ip` = '%s'", ip);
    result = db_query(Database, query);
	
	if(db_num_rows(result))
	{
		db_get_field_assoc(result, "name", pAka, sizeof(pAka));		
		
		format(string, sizeof(string), "Aliases under the IP of %s...", ip);
		SendClientMessage(playerid, -1, string);
		format(string, sizeof(string), "%s", pAka);
		SendClientMessage(playerid, COLOR_YELLOW, string);		
	}  
	else
	{
		format(string, sizeof(string), "IP (%s) isn't found on the database.", ip);
		SendClientMessage(playerid, COLOR_RED, string);
	}
	db_free_result(result);
    return 1;
}

CMD:aka(playerid, params[])
{
    new id, query[92], pAka[128*10], string[128 * 10], DBResult:result;

    LoginCheck(playerid);
	LevelCheck(playerid, 1);
	
	if(sscanf(params, "u", id))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /aka [playerid]");
	
	if(id == INVALID_PLAYER_ID)
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

	if(User[playerid][accountAdmin] < User[id][accountAdmin] && id != playerid)
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
    format(query, sizeof(query), "SELECT * FROM `aka` WHERE `ip` = '%s'", User[id][accountIP]);
    result = db_query(Database, query);
	
	if(db_num_rows(result))
	{
		db_get_field_assoc(result, "name", pAka, sizeof(pAka));		
		
		format(string, sizeof(string), "%s's other aliases... (%s)", pName(id), User[id][accountIP]);
		SendClientMessage(playerid, -1, string);
		format(string, sizeof(string), "%s", pAka);
		SendClientMessage(playerid, COLOR_YELLOW, string);		
	} 
	else
	{
		format(string, sizeof(string), "IP (%s) isn't found on the database.", User[id][accountIP]);
		SendClientMessage(playerid, COLOR_RED, string);
	}
	db_free_result(result);
    return 1;
}
#endif

CMD:richlist(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 1);
	
	new array[MAX_PLAYERS][2];
	new count;
	new string[128];
	
	foreach(new i : Player)
	{
		array[count][0] = GetPlayerMoney(i);
		array[count][1] = i;
		count++;
	}

	QuickSort_Pair(array, true, 0, count);

	SendClientMessage(playerid, COLOR_YELLOW, "* Top 5 richest players:");
	for (new i, j = ((count > 5) ? (5) : (count)); i < j; i++)
	{
		format(string, sizeof (string), "%i. %s[%i] - $%i", (i + 1), pName(array[i][1]), array[i][1], array[i][0]);
		SendClientMessage(playerid, -1, string);
	}
	return 1;
}

CMD:afk(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 1);
	
	new string[128];

	SendClientMessage(playerid, COLOR_RED, "* Idle Players:");
	foreach(new i : Player)
	{
		if(User[i][accountAFK] > 0)
		{
			format(string, sizeof(string), "* %s (ID: %d) - %d seconds", pName(i), i, User[i][accountAFK]);
			SendClientMessage(playerid, -1, string);
		}
	}
	return 1;
}

CMD:tabbed(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 1);
	
	new string[128];

	SendClientMessage(playerid, COLOR_RED, "* Tabbed Players:");
	foreach(new i : Player)
	{
		if(User[i][accountTabbed] > 0)
		{
			format(string, sizeof(string), "* %s (ID: %d) - %d seconds", pName(i), i, User[i][accountTabbed]);
			SendClientMessage(playerid, -1, string);
		}
	}
	return 1;
}

CMD:checkdamage(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 1);
	
	new string[128], wName[32], userid;

	if(sscanf(params, "u", userid))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /checkdamage [playerid]");

	if(userid == INVALID_PLAYER_ID)
	    return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

	format(string, sizeof(string), "* Last 5 Players that Damaged %s:", pName(userid));
	SendClientMessage(playerid, COLOR_YELLOW, string);
	for(new i; i < 5; i++)
	{
		if(!isnull(DamagedPlayer[userid][i]))
		{
			GetWeaponName(DamagedWeapon[userid][i], wName, sizeof(wName));
			format(string, sizeof(string), "[%d] %s damaged the player with weapon %s. (%d seconds ago)", i + 1, DamagedPlayer[userid][i], wName, gettime()-DamagedStamp[userid][i]);
			SendClientMessage(playerid, COLOR_GREEN, string);		
		}
		else 
		{
			format(string, sizeof(string), "[%d] No one damaged them yet on this slot.", i + 1);
			SendClientMessage(playerid, COLOR_GREEN, string);
		}
	}
	return 1;
}

CMD:saveskin(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 1);

	new string[128], SkinID;

	if(sscanf(params, "d", SkinID))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /saveskin [skinid]");

	if(SkinID < 0 || SkinID == 74 || SkinID > 311)
	    return SendClientMessage(playerid, COLOR_RED, "* Invalid SkinID");

	User[playerid][accountSkin] = SkinID;
	SaveData(playerid);

 	format(string, sizeof(string), "You have successfully saved skinID %d", SkinID);
 	SendClientMessage(playerid, -1, string);
	SendClientMessage(playerid, COLOR_YELLOW, "Type: /useskin to use this skin when you spawn (use the same cmd to stop using saved-skin)");
	return 1;
}

CMD:useskin(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 1);

	if(User[playerid][accountSkin] == -1)
	    return SendClientMessage(playerid, COLOR_RED, "* You do not have any saved skin.");

	switch(User[playerid][accountUseSkin])
	{
	    case false:
	    {
			User[playerid][accountUseSkin] = true;
			SetPlayerSkin(playerid, User[playerid][accountSkin]);
			SendClientMessage(playerid, COLOR_GREEN, "Your favorite skin is now in use.");
		}
		case true:
		{
			User[playerid][accountUseSkin] = false;
			SendClientMessage(playerid, COLOR_RED, "Your favorite skin will be no longer in use upon spawning.");
		}
	}
	SaveData(playerid);
	return 1;
}
	
CMD:votekicktime(playerid, params[])
{
	new string[128], second;

	LoginCheck(playerid);
	LevelCheck(playerid, 1);

    if(sscanf(params, "i", second))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /setvotekicklimit [limit(30/300)]");

    if(second < 30 || second > 300)
        return SendClientMessage(playerid, COLOR_RED, "* The kick-time must be above 30 seconds, but below 300!");

    if(second == KickTime)
    {
	    format(string, sizeof(string), "* The vote-kick time is already %i seconds!", second);
	    return SendClientMessage(playerid, COLOR_RED, string);
    }

    format(string, sizeof(string), "* Admin %s (ID: %d) has changed the Vote-Kick Time to %d.", pName(playerid), playerid, second);
    SendClientMessageToAll(COLOR_ADMIN, string);
	SaveLog("votekick.txt", string);
    KickTime = second;
	return 1;
}

CMD:entercar(playerid, params[])
{
	new string[128], id;

	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	if(sscanf(params, "d", id))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /entercar [vehicleid]");

	if(id < 1 || !IsValidVehicle(id) || id > MAX_VEHICLES)
		return SendClientMessage(playerid, COLOR_RED, "* Invalid vehicleID.");
		
	if(!IsSeatAvailable(id, 0))
		return SendClientMessage(playerid, COLOR_RED, "* That seat is occupied.");

	PutPlayerInVehicle(playerid, id, 0);
	format(string, sizeof(string), "* You have teleported and is now a driver of vehicle ID %d.", id);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:setwanted(playerid, params[])
{
	new string[128], id, level;

	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	if(sscanf(params, "ui", id, level))
	    return SendClientMessage(playerid, COLOR_RED, "USAGE: /setwanted [playerid] [level(0-6)]");
	    
	if(id == INVALID_PLAYER_ID)
	    return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

	if(level < 0 || level > 6)
	    return SendClientMessage(playerid, COLOR_RED, "* Invalid wanted level.");

	if(User[playerid][accountAdmin] < User[id][accountAdmin])
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	format(string, sizeof(string), "* Admin %s has set your wanted level to %d.", pName(playerid), level);
	SendClientMessage(id, COLOR_YELLOW, string);
	format(string, sizeof(string), "* You have set %s's wanted level to %d.", pName(id), level);
	SendClientMessage(playerid, COLOR_YELLOW, string);
	SetPlayerWantedLevel(id, level);
	return 1;
}

CMD:setdlevel(playerid, params[])
{
	new string[128], id, level;

	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	if(sscanf(params, "ui", id, level))
	    return SendClientMessage(playerid, COLOR_RED, "USAGE: /setdlevel [playerid] [level(0-50,000)]");

	if(id == INVALID_PLAYER_ID)
	    return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

	if(level < 0 || level > 50000)
	    return SendClientMessage(playerid, COLOR_RED, "* Invalid drunk level.");

	if(User[playerid][accountAdmin] < User[id][accountAdmin])
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	format(string, sizeof(string), "* Admin %s has set your drunk level to %d.", pName(playerid), level);
	SendClientMessage(id, COLOR_YELLOW, string);
	format(string, sizeof(string), "* You have set %s's drunk level to %d.", pName(id), level);
	SendClientMessage(playerid, COLOR_YELLOW, string);
	SetPlayerDrunkLevel(id, level);
	return 1;
}

CMD:endvotekick(playerid, params[])
{
	new string[128], reason[38];
	
	LoginCheck(playerid);
	LevelCheck(playerid, 1);
	
    if(!VoteKickHappening)
        return SendClientMessage(playerid, COLOR_RED, "* There is no vote-kick happening at this time.");

    if(sscanf(params, "s[38]", reason))
        return SendClientMessage(playerid, COLOR_RED, "USAGE: /endvotekick [reason]");

	format(string, sizeof(string), "* Admin %s has ended the vote-kick against %s reason: (%s)", pName(playerid), pName(VoteKickTarget), reason);
	SendClientMessageToAll(COLOR_ADMIN, string); 
	SaveLog("votekick.txt", string);
	
	format(VoteKickReason, sizeof(VoteKickReason), "None");
	VoteKickHappening = 0;
	avotes = 0;
	svotes = 0;
	VoteKickTarget = INVALID_PLAYER_ID;
	KillTimer(VoteTimer);
	//////////////////////
	foreach(new i : Player)
	{
		HasAlreadyVoted{i} = false;
	}
	return 1;
}

CMD:weaps(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

    new id, Count, x, string[128], WeapName[24], slot, weap, ammo;
	if(sscanf(params, "u", id))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /weaps [playerid]");
		
	if(id == INVALID_PLAYER_ID)
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	format(string, sizeof(string), "%s's Weapons...", pName(id));
	SendClientMessage(playerid, COLOR_WHITE, string);
	for(slot = 0; slot < 14; slot++)
	{
		GetPlayerWeaponData(id, slot, weap, ammo);
		if(ammo != 0 && weap != 0)
		Count++;
	}
	if(Count < 1) return SendClientMessage(playerid, COLOR_RED, "Players has no equipped weapons!");
	if(Count >= 1)
	{
		for (slot = 0; slot < 14; slot++)
		{
			GetPlayerWeaponData(id, slot, weap, ammo);
			if(ammo != 0 && weap != 0)
			{
				GetWeaponName(weap, WeapName, sizeof(WeapName));
				if(ammo == 65535 || ammo == 1)
				format(string, sizeof(string), "%s%s (1)",string, WeapName);
				else format(string, sizeof(string), "%s%s (%d)", string, WeapName, ammo);
				x++;
				if(x >= 5)
				{
 					SendClientMessage(playerid, COLOR_YELLOW, string);
 					x = 0;
					format(string, sizeof(string), "");
				}
				else format(string, sizeof(string), "%s,  ", string);
			}
		}
		if(x <= 4 && x > 0)
		{
			string[strlen(string)-3] = '.';
			SendClientMessage(playerid, COLOR_YELLOW, string);
		}
	}
	return 1;
}

CMD:aduty(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	new string[92];

	switch(User[playerid][accountDuty])
	{
	    case 0:
	    {
            SetPlayerArmour(playerid, 100000);
            SetPlayerHealth(playerid, 100000);
	        User[playerid][accountDuty] = 1;
	        format(string, sizeof(string), "* Admin %s goes Admin-Duty", pName(playerid));
	        SendClientMessageToAll(COLOR_ADMIN, string);
	    }
	    case 1:
	    {
			User[playerid][accountDuty] = 0;
            SetPlayerHealth(playerid, 100);
            SetPlayerArmour(playerid, 100);
			format(string, sizeof(string), "* Admin %s goes off Admin-Duty", pName(playerid));
			SendClientMessageToAll(COLOR_ADMIN, string);
	    }
	}
	return 1;
}

CMD:reports(playerid, params[])
{
	// /reports has been reworked too (01/22/17)

	LoginCheck(playerid);
	LevelCheck(playerid, 1);
	
	new string[1042 * 5], string2[150], count;
	
	strcat(string, ""red"*** Report Send by the Players ***\n\n");
	strcat(string, ""grey"");
	
	for(new i = 1; i< MAX_REPORTS; i++)
	{
	    if(rInfo[i][reportTaken])
	    {
			if(IsPlayerConnected(rInfo[i][reportAccepted]))
			{
		    	format(string2, sizeof(string2), "[ReportID %d] %s(%d) reported %s(%d) for %s (submitted: %s) - handled by %s\n", i, pName(rInfo[i][reporterID]), rInfo[i][reporterID], pName(rInfo[i][reportedID]), rInfo[i][reportedID], rInfo[i][reportReason], rInfo[i][reportTime], pName(rInfo[i][reportAccepted]));
			}
			else if(rInfo[i][reportAccepted] == INVALID_PLAYER_ID)
			{
		    	format(string2, sizeof(string2), "[ReportID %d] %s(%d) reported %s(%d) for %s (submitted: %s) - handled by no one\n", i, pName(rInfo[i][reporterID]), rInfo[i][reporterID], pName(rInfo[i][reportedID]), rInfo[i][reportedID], rInfo[i][reportReason], rInfo[i][reportTime]);
			}
			strcat(string, string2);
			count++;
		}
	}
	
	if(count < 1) strcat(string, "There are no reports at the moment.");
	
	Dialog_Show(playerid, DIALOG_BEGIN, DIALOG_STYLE_MSGBOX, ""red"Reports", string, "Close", "");
	return 1;
}

CMD:handlereport(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);
	
	new reportid;
	if(sscanf(params, "d", reportid))
	    return SendClientMessage(playerid, COLOR_RED, "USAGE: /handlereport [reportid]");
	    
	if(reportid < 1 || !rInfo[reportid][reportTaken] || reportid >= MAX_REPORTS)
	    return SendClientMessage(playerid, COLOR_RED, "** Invalid reportID specified.");

	if(rInfo[reportid][reportAccepted] == playerid)
	    return SendClientMessage(playerid, COLOR_RED, "** Report is already being handle by you.");

	if(rInfo[reportid][reportAccepted] != INVALID_PLAYER_ID)
	    return SendClientMessage(playerid, COLOR_RED, "** Report is already being handle by another admin.");

	HandleReport(playerid, reportid);
	return 1;
}

CMD:denyreport(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	new reportid, reason[128];
	if(sscanf(params, "ds[128]", reportid))
	    return SendClientMessage(playerid, COLOR_RED, "USAGE: /denyreport [reportid]");

	if(reportid < 1 || !rInfo[reportid][reportTaken] || reportid >= MAX_REPORTS)
	    return SendClientMessage(playerid, COLOR_RED, "** Invalid reportID specified.");

	if(rInfo[reportid][reportAccepted] != INVALID_PLAYER_ID)
	    return SendClientMessage(playerid, COLOR_RED, "** Report is already being handle by another admin.");

	DenyReport(playerid, reportid, reason);
	return 1;
}

CMD:endreport(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	new reason[128];
	if(sscanf(params, "s[128]", reason))
	    return SendClientMessage(playerid, COLOR_RED, "USAGE: /endreport [reason]");

	for(new i; i < MAX_REPORTS; i++)
	{
	    if(rInfo[i][reportTaken] && rInfo[i][reportAccepted] == playerid)
	    {
			EndReport(playerid, i, reason);
			return 1;
		}
	}
	SendClientMessage(playerid, -1, "* You aren't handling any reports.");
	return 1;
}

CMD:repair(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	if(IsPlayerInAnyVehicle(playerid))
	{
	    new VehicleID = GetPlayerVehicleID(playerid);
		RepairVehicle(VehicleID);
		GameTextForPlayer(playerid, "~w~~n~~n~~n~~n~~n~~n~Vehicle ~g~Repaired!", 3000, 3);
  		SetVehicleHealth(VehicleID, 1000.0);
	}
	else
		SendClientMessage(playerid, COLOR_RED, "* You must be inside of the vehicle to use this command.");
	return 1;
}

CMD:addnos(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	if(IsPlayerInAnyVehicle(playerid))
	{
        switch(GetVehicleModel(GetPlayerVehicleID(playerid)))
		{
			case 448,461,462,463,468,471,509,510,521,522,523,581,586,449: SendClientMessage(playerid, COLOR_RED, "* You cannot add nos to this vehicle.");
		}
        AddVehicleComponent(GetPlayerVehicleID(playerid), 1010);
		PlayerPlaySound(playerid, 1133, 0.0, 0.0, 0.0);
	}
	else
		SendClientMessage(playerid, COLOR_RED, "* You must be inside of the vehicle to use this command.");
	return 1;
}

CMD:warn(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	new string[128], id, reason[128], rank[3];

    if(sscanf(params, "uS(No Reason)[128]", id, reason))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /warn [playerid] [reason]");
		
	if(id == INVALID_PLAYER_ID)
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

    if(id == playerid)
		return SendClientMessage(playerid, COLOR_RED, "* You cannot warn yourself.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin])
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	User[id][accountWarn] += 1;
	switch(User[id][accountWarn])
	{
		case 1: rank = "st";
		case 2: rank = "nd";
		case 3: rank = "rd";
		default: rank = "th";
	}

	format(string, sizeof(string), "[WARNED] %s has been warned by %s for the %d%s time for %s.", pName(id), pName(playerid), User[id][accountWarn], rank, reason);
	SendClientMessageToAll(COLOR_ADMIN, string);
	return 1;
}

CMD:remwarn(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	new string[128], id, rank[3];

    if(sscanf(params, "u", id))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /remwarn [playerid]");

	if(id == INVALID_PLAYER_ID)
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

    if(id == playerid)
		return SendClientMessage(playerid, COLOR_RED, "* You cannot remove warn yourself.");

	if(User[playerid][accountAdmin] < User[id][accountAdmin])
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	if(User[id][accountWarn] == 0)
		return SendClientMessage(playerid, COLOR_RED, "* Player has no warnings.");

	switch(User[id][accountWarn])
	{
		case 1: rank = "st";
		case 2: rank = "nd";
		case 3: rank = "rd";
		default: rank = "th";
	}
	
	format(string, sizeof(string), "[REMWARN] %s %d%s warning has been removed by %s.", pName(id), User[id][accountWarn], rank, pName(playerid));
	SendClientMessageToAll(COLOR_ADMIN, string);
	
	User[id][accountWarn] -= 1;
	return 1;
}

CMD:flip(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

    new id, string[128], Float:angle;

    if(!sscanf(params, "u", id))
    {
		if(id == INVALID_PLAYER_ID)
			return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
			
		if(User[playerid][accountAdmin] < User[id][accountAdmin])
			return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		if(!IsPlayerInAnyVehicle(id)) return SendClientMessage(playerid, COLOR_RED, "* Player not in a vehicle.");
		GetVehicleZAngle(GetPlayerVehicleID(id), angle);
		SetVehicleZAngle(GetPlayerVehicleID(id), angle);
		
		format(string, sizeof(string), "You have flipped Player %s's vehicle.", pName(id));
		SendClientMessage(playerid, COLOR_GREEN, string);
		format(string, sizeof(string), "Admin %s has flipped your vehicle.", pName(playerid));
		SendClientMessage(id, COLOR_GREEN, string);
    }
    else
    {
		if(!IsPlayerInAnyVehicle(playerid))
			return SendClientMessage(playerid, COLOR_RED, "* You must be in a vehicle to use /flip.");
			
        GetVehicleZAngle(GetPlayerVehicleID(playerid), angle);
        SetVehicleZAngle(GetPlayerVehicleID(playerid), angle);
		SendClientMessage(playerid, COLOR_YELLOW, "Vehicle Flipped!");
		SendClientMessage(playerid, -1, "Want to flip player's vehicle? Just do "green"/flip [playerid]");
    }
	return 1;
}

CMD:gotoco(playerid, params[])
{
    LoginCheck(playerid);
    LevelCheck(playerid, 1);

	new Float: Pos[3], string[128];
    if(sscanf(params, "p<,>fff", Pos[0], Pos[1], Pos[2]))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /gotoco [x] [y] [z]");

    if(IsPlayerInAnyVehicle(playerid)) SetVehiclePos(GetPlayerVehicleID(playerid), Pos[0], Pos[1], Pos[2]);
    else SetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);

	format(string, sizeof string, "You have teleported to Coordinates %.1f %.1f %.1f", Pos[0], Pos[1], Pos[2]);
	SendClientMessage(playerid, COLOR_YELLOW, string);
	return 1;
}

CMD:ip(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	new
	    id,
	    string[120]
	;
	if(sscanf(params, "u", id))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /ip [playerid]");
		
	if(id == INVALID_PLAYER_ID)
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

	format(string, 120, "> %s's IP: %s <", pName(id), getIP(id));
	SendClientMessage(playerid, COLOR_YELLOW, string);
	return 1;
}

CMD:spawn(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	new
	    string[128],
	    id
	;

    if(sscanf(params, "u", id))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /spawn [playerid]");
		
	if(id == INVALID_PLAYER_ID)
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin])
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
    SetPlayerPos(id, 0.0, 0.0, 0.0);
    SpawnPlayer(id);
    format(string, sizeof(string), "You have respawned Player %s.", pName(id));
    SendClientMessage(playerid, -1, string);
    format(string, sizeof(string), "Admin %s has respawned you.", pName(playerid));
    SendClientMessage(id, COLOR_YELLOW, string);
	return 1;
}

CMD:goto(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	new
		id,
		string[128],
		Float:x,
		Float:y,
		Float:z
	;
	if(sscanf(params, "u", id))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /goto [playerid]");
		
	if(id == INVALID_PLAYER_ID)
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

	GetPlayerPos(id, x, y, z);
	SetPlayerInterior(playerid, GetPlayerInterior(id));
	SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(id));
	if(GetPlayerState(playerid) == 2)
	{
		SetVehiclePos(GetPlayerVehicleID(playerid), x+3, y, z);
		LinkVehicleToInterior(GetPlayerVehicleID(playerid), GetPlayerInterior(id));
		SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), GetPlayerVirtualWorld(id));
	}
	else SetPlayerPos(playerid, x+2, y, z);
	format(string, sizeof(string), "You have been teleported to Player %s.", pName(id));
	SendClientMessage(playerid, COLOR_GREEN, string);
	format(string, sizeof(string), "Admin %s has teleported to your location.", pName(playerid));
	SendClientMessage(id, COLOR_GREEN, string);
	return 1;
}

CMD:setweather(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	new string[128], id, weather;

	if(sscanf(params, "ui", id, weather))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /setweather [playerid] [0/45]");

	if(id == INVALID_PLAYER_ID)
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin])
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
	if(weather < 0 || weather > 45) return SendClientMessage(playerid, COLOR_RED, "* Invalid Weather ID. (0/45)");
	SetPlayerWeather(id, weather);
	format(string, sizeof(string), "You have set %s's weather to weatherID %d", pName(id), weather);
	SendClientMessage(playerid, COLOR_YELLOW, string);
	format(string, sizeof(string), "Admin %s has your weather to weatherID %d", pName(playerid), weather);
	SendClientMessage(id, COLOR_YELLOW, string);
	return 1;
}

CMD:settime(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	new string[128], id, time;

	if(sscanf(params, "ui", id, time))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /settime [playerid] [0/23]");

	if(id == INVALID_PLAYER_ID)
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

	if(User[playerid][accountAdmin] < User[id][accountAdmin])
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	if(time < 0 || time > 23) return SendClientMessage(playerid, COLOR_RED, "* Invalid Time. (0/23)");
	SetPlayerTime(id, time, 0);
	format(string, sizeof(string), "You have set %s's screen time to %d:00", pName(id), time);
	SendClientMessage(id, COLOR_YELLOW, string);
	format(string, sizeof(string), "Admin %s has set your screen time to %d:00", pName(playerid), time);
	SendClientMessage(id, COLOR_YELLOW, string);
	return 1;
}

CMD:announce(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);
	if(isnull(params)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /announce [message to all]");
	GameTextForAll(params, 4000, 3);
	return 1;
}

CMD:kick(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

    new string[128], id, reason[128];
	
	if(sscanf(params, "uS(Not specified)[128]", id, reason)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /kick [playerid] [reason(Default: N/A)]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
    format(string, sizeof(string), "ADMIN: %s has been kicked from the server by %s (Reason: %s)", pName(id), pName(playerid), reason);
	SendClientMessageToAll(COLOR_ADMIN, string);
	print(string);
	SaveLog("kicklog.txt", string);
	
	KickDelay(id);
	return 1;
}

CMD:asay(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 1);

	new string[128];

    if(isnull(params)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /asay [message as asay]");

	format(string, sizeof(string), "** Admin %s: %s", pName(playerid), params);
    SendClientMessageToAll(COLOR_ADMIN, string);
	return 1;
}

//============================================================================//
//						  	Administrative Level Two                          //
//============================================================================//

CMD:caged(playerid, params[])
{
	new string[92], count = 0;

	SendClientMessage(playerid, -1, "** "green"Caged Players "white"**");
	foreach(new i : Player)
	{
		if(User[i][accountCage])
		{
			format(string, sizeof(string), "(%d) %s", i, pName(i));
			SendClientMessage(playerid, -1, string);
			count++;
		}
	}
	
	if(!count) 
		SendClientMessage(playerid, -1, "No caged players at the moment.");
	return 1;
}

CMD:cage(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);
	
	new id, string[92];
	
	if(sscanf(params, "u", id))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /cage [playerid]");
	
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");	

	if(User[id][accountCage])
		return SendClientMessage(playerid, COLOR_RED, "* Player is already caged!");
		
	TogglePlayerControllable(id, false);
	SetTimerEx("CageNikka", 1000, false, "d", id);
	
	format(string, sizeof(string), "ADMIN: %s was caged by %s.", pName(id), pName(playerid));
	SendClientMessageToAll(COLOR_ADMIN, string);
	format(string, sizeof(string), "* You have been caged by %s.", pName(playerid));
	SendClientMessage(id, COLOR_RED, string);
	format(string, sizeof(string), "* You caged %s.", pName(id));
	SendClientMessage(playerid, -1, string);
	
	User[id][accountCage] = 1;
	return 1;
}

function:CageNikka(playerid)
{
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	User[playerid][accountCageObject] = CreatePlayerObject(playerid, 18856, x, y, z, 0.0, 0.0, 0.0);
	TogglePlayerControllable(playerid, true);
}

CMD:uncage(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);
	
	new id, string[92];
	
	if(sscanf(params, "u", id))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /uncage [playerid]");
	
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");	
	
	if(!User[id][accountCage])
		return SendClientMessage(playerid, COLOR_RED, "* Player is not caged!");
	
	DestroyPlayerObject(id, User[id][accountCageObject]);
	
	format(string, sizeof(string), "ADMIN: %s was uncaged by %s.", pName(id), pName(playerid));
	SendClientMessageToAll(COLOR_ADMIN, string);
	format(string, sizeof(string), "* You have been uncaged by %s.", pName(playerid));
	SendClientMessage(id, COLOR_GREEN, string);
	format(string, sizeof(string), "* You uncaged %s.", pName(id));
	SendClientMessage(playerid, -1, string);
	
	User[id][accountCage] = 0;
	SaveData(id);
	return 1;
}

CMD:checkbreach(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new query[128], accountname[24], DBResult:result, ip[20], date[12], type, time[12];

	if(sscanf(params, "s[24]", accountname))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /checkbreach [account name]");

	format(query, sizeof(query), "SELECT * FROM `breach` WHERE `username` = '%s' ORDER BY `ip` DESC LIMIT 10", DB_Escape(accountname));
	result = db_query(Database, query);
	if(db_num_rows(result))
	{
		SendClientMessage(playerid, COLOR_GREEN, "••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••");
		format(query, sizeof(query), "Last (10) IPs who attempted to breach into %s's account.", accountname);
		SendClientMessage(playerid, -1, query);

		for (new i = 0; i < db_num_rows(result); i ++)
		{
			db_get_field_assoc(result, "ip", ip, sizeof(ip));
			type = db_get_field_assoc_int(result, "type");
			db_get_field_assoc(result, "date", date, sizeof(date));
			db_get_field_assoc(result, "time", time, sizeof(time));

			format(query, sizeof(query), "IP: %s on %s %s. (Attempted to login using: %s)", ip, date, time, (type) ? ("Password") : ("Security Question"));
			SendClientMessage(playerid, COLOR_YELLOW, query);
	        db_next_row(result);
	  	}
	  	
		SendClientMessage(playerid, COLOR_GREEN, "••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••");
	}
	else
	{
	    format(query, sizeof(query), "* '%s' isn't found in the database." ,accountname);
	    SendClientMessage(playerid, COLOR_RED, query);
	}
	db_free_result(result);
	return 1;
}

CMD:ips(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new query[128], accountname[24], DBResult:result, ip[20], date[12], time[12];

	if(sscanf(params, "s[24]", accountname))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /ips [account name]");

	format(query, sizeof(query), "SELECT * FROM `ips` WHERE `username` = '%s' ORDER BY `ip` DESC LIMIT 10", DB_Escape(accountname));
	result = db_query(Database, query);
	if(db_num_rows(result))
	{
		SendClientMessage(playerid, COLOR_GREEN, "••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••");
		format(query, sizeof(query), "%s's last (10) IP used in the server.", accountname);
		SendClientMessage(playerid, -1, query);

		for (new i = 0; i < db_num_rows(result); i ++)
		{
			db_get_field_assoc(result, "ip", ip, sizeof(ip));
			db_get_field_assoc(result, "date", date, sizeof(date));
			db_get_field_assoc(result, "time", time, sizeof(time));

			format(query, sizeof(query), "Player connected with the IP %s on %s %s.", ip, date, time);
			SendClientMessage(playerid, COLOR_YELLOW, query);
	        db_next_row(result);
	  	}
	  	
		SendClientMessage(playerid, COLOR_GREEN, "••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••");
	}
	else
	{
	    format(query, sizeof(query), "* '%s' isn't found in the database." ,accountname);
	    SendClientMessage(playerid, COLOR_RED, query);
	}
	db_free_result(result);
	return 1;
}

CMD:respawncar(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new string[92], carid;
	
	if(sscanf(params, "d", carid))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /respawncar [vehicleid]");

	if(carid < 1 || !IsValidVehicle(carid) || carid > MAX_VEHICLES)
		return SendClientMessage(playerid, COLOR_RED, "* Invalid vehicleID.");

	SetVehicleToRespawn(carid);
	format(string, sizeof(string), "You have respawned vehicle ID %d.", carid);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:radiusrespawn(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new string[92], Float:range, numcars;
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);

	if(sscanf(params, "f", range))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /radiusrespawn [range]");

	for(new i = 1; i < MAX_VEHICLES; i++)
	{
		if(IsValidVehicle(i) && GetVehicleDistanceFromPoint(i, x, y, z) <= range && !VehicleOccupied(i))
		{
			SetVehicleToRespawn(i);
			numcars++;
		}
	}

	if(!numcars)
		return SendClientMessage(playerid, COLOR_RED, "No cars respawned.");

	format(string, sizeof(string), "** Admin %s has made a car respawn on their radius %dm", pName(playerid), floatround(range));
	SendClientMessageToAll(COLOR_ADMIN, string);
	format(string, sizeof(string), "You have respawned %d cars within %d meters.", numcars, floatround(range));
	SendClientMessage(playerid, -1, string);
	return 1;
}
CMD:rr(playerid, params[]) return cmd_radiusrespawn(playerid, params);

CMD:addlabel(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new id = -1, string[128], color, text[128], distance, seethrough;

	if(sscanf(params, "ddds[128]", color, distance, seethrough, text))
	{
		SendClientMessage(playerid, COLOR_RED, "USAGE: /addlabel [colorID] [distance(10>50)] [seethrough(0-ON/1-OFF)] [text]");
	    SendClientMessage(playerid, -1, "Available ColorIDs: 1 - White, 2 - {FF0000}Red{FFFFFF}, 3 - {FFFF00}Yellow{FFFFFF}, 4 - {33AA33}Green{FFFFFF}, 5 - {FF8000}Orange{FFFFFF},");
	    SendClientMessage(playerid, -1, "Available ColorIDs: 6 - {D526D9}Purple{FFFFFF}, 7 - {FF80FF}Pink{FFFFFF}, 8 - {33CCFF}Lightblue{FFFFFF},");
	    SendClientMessage(playerid, -1, "Available ColorIDs: 9 - {0080FF}Blue{FFFFFF}, 10 - {00FF00}Lightgreen");
		return 1;
	}

	if(distance < 10 || distance > 50)
	    return SendClientMessage(playerid, COLOR_RED, "* Invalid distance.");

	if(seethrough < 0 || seethrough > 1)
	    return SendClientMessage(playerid, COLOR_RED, "* Invalid see-through value.");

	switch(color)
	{
		case 1: // White
		{
			id = Deploy_Label(playerid, 0xFFFFFFFF, text, distance, seethrough);
			if(id == -1) return SendClientMessage(playerid, COLOR_RED, "* Unable to deploy more labels, possibly reached the ("#MAX_DEPLOYABLE_LABEL") limit.");
			format(string, sizeof(string), "* You have deployed label ID %d, color white (distance: %d | seethrough: %d)", id + 1, distance, seethrough);
			SendClientMessage(playerid, -1, string);
		}
		case 2: // Red
		{
			id = Deploy_Label(playerid, 0xFF0000FF, text, distance, seethrough);
			if(id == -1) return SendClientMessage(playerid, COLOR_RED, "* Unable to deploy more labels, possibly reached the ("#MAX_DEPLOYABLE_LABEL") limit.");
			format(string, sizeof(string), "* You have deployed label ID %d, color red (distance: %d | seethrough: %d)", id + 1, distance, seethrough);
			SendClientMessage(playerid, COLOR_RED, string);
		}
		case 3: // Yellow
		{
			id = Deploy_Label(playerid, 0xFFFF00FF, text, distance, seethrough);
			if(id == -1) return SendClientMessage(playerid, COLOR_RED, "* Unable to deploy more labels, possibly reached the ("#MAX_DEPLOYABLE_LABEL") limit.");
			format(string, sizeof(string), "* You have deployed label ID %d, color yellow (distance: %d | seethrough: %d)", id + 1, distance, seethrough);
			SendClientMessage(playerid, COLOR_YELLOW, string);
		}
		case 4: // Green
		{
			id = Deploy_Label(playerid, 0x33AA33FF, text, distance, seethrough);
			if(id == -1) return SendClientMessage(playerid, COLOR_RED, "* Unable to deploy more labels, possibly reached the ("#MAX_DEPLOYABLE_LABEL") limit.");
			format(string, sizeof(string), "* You have deployed label ID %d, color yellow (distance: %d | seethrough: %d)", id + 1, distance, seethrough);
			SendClientMessage(playerid, COLOR_GREEN, string);
		}
		case 5: // Orange
		{
			id = Deploy_Label(playerid, 0xFF8000FF, text, distance, seethrough);
			if(id == -1) return SendClientMessage(playerid, COLOR_RED, "* Unable to deploy more labels, possibly reached the ("#MAX_DEPLOYABLE_LABEL") limit.");
			format(string, sizeof(string), "* You have deployed label ID %d, color orange (distance: %d | seethrough: %d)", id + 1, distance, seethrough);
			SendClientMessage(playerid, COLOR_ORANGE, string);
		}
		case 6: // Purple
		{
			id = Deploy_Label(playerid, 0xD526D9FF, text, distance, seethrough);
			if(id == -1) return SendClientMessage(playerid, COLOR_RED, "* Unable to deploy more labels, possibly reached the ("#MAX_DEPLOYABLE_LABEL") limit.");
			format(string, sizeof(string), "* You have deployed label ID %d, color purple (distance: %d | seethrough: %d)", id + 1, distance, seethrough);
			SendClientMessage(playerid, COLOR_PURPLE, string);
		}
		case 7: // Pink
		{
			id = Deploy_Label(playerid, 0xFF80FFFF, text, distance, seethrough);
			if(id == -1) return SendClientMessage(playerid, COLOR_RED, "* Unable to deploy more labels, possibly reached the ("#MAX_DEPLOYABLE_LABEL") limit.");
			format(string, sizeof(string), "* You have deployed label ID %d, color pink (distance: %d | seethrough: %d)", id + 1, distance, seethrough);
			SendClientMessage(playerid, COLOR_PINK, string);
		}
		case 8: // Lightblue
		{
			id = Deploy_Label(playerid, 0x33CCFFFF, text, distance, seethrough);
			if(id == -1) return SendClientMessage(playerid, COLOR_RED, "* Unable to deploy more labels, possibly reached the ("#MAX_DEPLOYABLE_LABEL") limit.");
			format(string, sizeof(string), "* You have deployed label ID %d, color lightblue (distance: %d | seethrough: %d)", id + 1, distance, seethrough);
			SendClientMessage(playerid, COLOR_LIGHTBLUE, string);
		}
		case 9: // Blue
		{
			id = Deploy_Label(playerid, 0x0080FFFF, text, distance, seethrough);
			if(id == -1) return SendClientMessage(playerid, COLOR_RED, "* Unable to deploy more labels, possibly reached the ("#MAX_DEPLOYABLE_LABEL") limit.");
			format(string, sizeof(string), "* You have deployed label ID %d, color blue (distance: %d | seethrough: %d)", id + 1, distance, seethrough);
			SendClientMessage(playerid, COLOR_BLUE, string);
		}
		case 10: // Lightgreen
		{
			id = Deploy_Label(playerid, 0x00FF00FF, text, distance, seethrough);
			if(id == -1) return SendClientMessage(playerid, COLOR_RED, "* Unable to deploy more labels, possibly reached the ("#MAX_DEPLOYABLE_LABEL") limit.");
			format(string, sizeof(string), "* You have deployed label ID %d, color lightgreen (distance: %d | seethrough: %d)", id + 1, distance, seethrough);
			SendClientMessage(playerid, COLOR_LIGHTGREEN, string);
		}
		default: SendClientMessage(playerid, COLOR_RED, "* Invalid colorID specified.");
	}
	return 1;
}

CMD:gotolabel(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new id, string[92];

	if(sscanf(params, "d", id))
	    return SendClientMessage(playerid, COLOR_RED, "USAGE: /gotolabel [labelID]");

	if(id < 1 || !lInfo[id-1][labelTaken] || id > MAX_DEPLOYABLE_LABEL+1)
	    return SendClientMessage(playerid, COLOR_RED, "* Invalid labelID specified.");

	format(string, sizeof(string), "* You have teleported to label ID %d.", id);
	SendClientMessage(playerid, -1, string);

	SetPlayerInterior(playerid, lInfo[id-1][labelInterior]);
	SetPlayerVirtualWorld(playerid, lInfo[id-1][labelVW]);
	SetPlayerPos(playerid, lInfo[id-1][labelX], lInfo[id-1][labelY], lInfo[id-1][labelZ]);
	return 1;
}

CMD:destroylabel(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new id, string[92];

	if(sscanf(params, "d", id))
	    return SendClientMessage(playerid, COLOR_RED, "USAGE: /destroylabel [labelID]");

	if(id < 1 || !lInfo[id-1][labelTaken] || id > MAX_DEPLOYABLE_LABEL+1)
	    return SendClientMessage(playerid, COLOR_RED, "* Invalid labelID specified.");

	format(string, sizeof(string), "* You have destroyed label ID %d.", id);
	SendClientMessage(playerid, -1, string);
	lInfo[id-1][labelX] = 0;
	lInfo[id-1][labelY] = 0;
	lInfo[id-1][labelZ] = 0;
	lInfo[id-1][labelTaken] = false;
	DestroyDynamic3DTextLabel(lInfo[id-1][label3D]);
	return 1;
}

CMD:jetpack(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new id, string[92];

    if(!sscanf(params, "u", id))
    {
		if(id == INVALID_PLAYER_ID) 
			return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
			
		if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
			return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
			
        SetPlayerSpecialAction(id, SPECIAL_ACTION_USEJETPACK);
		
		if(id != playerid)
		{
			format(string, sizeof(string), "[Jetpack] %s has given %s a jetpack.", pName(playerid), pName(id));
			SendAdmin(COLOR_ADMIN, string);
			format(string, sizeof(string), "You have given Player %s(ID:%d) a jetpack.", pName(id), id);
			SendClientMessage(playerid, COLOR_YELLOW, string);
			format(string, sizeof(string), "Admin %s(ID:%d) has given you a jetpack.", pName(playerid), playerid);
			SendClientMessage(id, COLOR_YELLOW, string);
		}
		else
		{
			format(string, sizeof(string), "[Jetpack] %s has given themself a jetpack.", pName(playerid));
			SendAdmin(COLOR_ADMIN, string);
			SendClientMessage(playerid, COLOR_YELLOW, "Jetpack Spawned!");
		}
    }
    else
    {
		format(string, sizeof(string), "[Jetpack] %s has given themself a jetpack.", pName(playerid));
		SendAdmin(COLOR_ADMIN, string);
		
		SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
		SendClientMessage(playerid, COLOR_YELLOW, "Jetpack Spawned!");
		SendClientMessage(playerid, -1, "Want to give player a jetpack? Just do "green"/jetpack [playerid]");
    }
	return 1;
}

CMD:aweapons(playerid, params[])
{
    LoginCheck(playerid);
    LevelCheck(playerid, 2);

    GivePlayerWeapon(playerid, 24, 99999);
    GivePlayerWeapon(playerid, 26, 99999);
    GivePlayerWeapon(playerid, 29, 99999);
    GivePlayerWeapon(playerid, 31, 99999);
    GivePlayerWeapon(playerid, 33, 99999);
    GivePlayerWeapon(playerid, 38, 99999);
    GivePlayerWeapon(playerid, 9, 1);
    
    SendClientMessage(playerid, COLOR_YELLOW, "Admin weapons received!");
    return 1;
}

CMD:muted(playerid, params[])
{
	new string[92], count = 0;

	SendClientMessage(playerid, -1, "** "green"Muted Players "white"**");
	
	foreach(new i : Player)
	{
		if(User[i][accountMuted])
		{
			if(User[i][accountMuteSec] > 0)
				format(string, sizeof(string), "(%d) %s - (%d)", i, pName(i), User[i][accountMuteSec]);
			else if(User[i][accountMuteSec] == -1)
				format(string, sizeof(string), "(%d) %s - (Permanent)", i, pName(i));
				
			SendClientMessage(playerid, -1, string);
			count++;
		}
	}
	
	if(!count) 
		SendClientMessage(playerid, -1, "No muted players at the moment.");
	return 1;
}

CMD:jailed(playerid, params[])
{
	new string[92], count = 0;

	SendClientMessage(playerid, -1, "** "green"Jailed Players "white"**");
	
	foreach(new i : Player)
	{
		if(User[i][accountJail])
		{
			format(string, sizeof(string), "(%d) %s - (%d)", i, pName(i), User[i][accountJailSec]);
			SendClientMessage(playerid, -1, string);
			count++;
		}
	}
	
	if(!count)  
		SendClientMessage(playerid, -1, "No jailed players at the moment.");
	return 1;
}

CMD:setvhealth(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new
		string[128],
	    id,
		hp
	;

	if(sscanf(params, "ud", id, hp)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /setvhealth [playerid] [health]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
	new Float:hp2 = float(hp);
	
	if(!IsPlayerInAnyVehicle(id)) return SendClientMessage(playerid, COLOR_RED, "* Player must be inside of a vehicle!");
	SetVehicleHealth(GetPlayerVehicleID(id), hp2);
	
	format(string, sizeof(string), "You have set %s's vehicle health to %d", pName(id), floatround(hp2));
	SendClientMessage(playerid, COLOR_YELLOW, string);
	format(string, sizeof(string), "Admin %s has set your vehicle health to %d", pName(playerid), floatround(hp2));
	SendClientMessage(id, COLOR_YELLOW, string);
	return 1;
}

CMD:eject(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new string[128], id;

    if(sscanf(params, "u", id)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /eject [playerid]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
	if(!IsPlayerInAnyVehicle(id)) 
		return SendClientMessage(playerid, COLOR_RED, "* Player must be inside of the vehicle.");
		
	RemovePlayerFromVehicle(id);
	format(string, sizeof(string), "You have ejected %s from their vehicle", pName(id));
	SendClientMessage(playerid, COLOR_YELLOW, string);
	format(string, sizeof(string), "Admin %s has ejected you from your vehicle.", pName(playerid));
	SendClientMessage(id, COLOR_YELLOW, string);
	return 1;
}

CMD:carpjob(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new
		string[128],
		id,
		pjob
	;
	if(sscanf(params, "ui", id, pjob)) 
		return SendClientMessage(playerid, COLOR_RED, "* /carpjob [playerid] [paintjob(0-3)]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
	if(!IsPlayerInAnyVehicle(id)) 
		return SendClientMessage(playerid, COLOR_RED, "* Player must be inside of a vehicle.");
		
	if(pjob < 0 || pjob > 3) 
		return SendClientMessage(playerid, COLOR_RED, "* Invalid Paintjob ID.");

	format(string, sizeof(string), "You have changed the paintjob of %s's %s to '%d'", pName(id), VehicleNames[GetVehicleModel(GetPlayerVehicleID(id))-400], pjob);
	SendClientMessage(playerid, COLOR_GREEN, string);
	format(string, sizeof(string), "Admin %s has changed the paintjob of your %s to '%d'", pName(playerid), VehicleNames[GetVehicleModel(GetPlayerVehicleID(id))-400], pjob);
	SendClientMessage(id, COLOR_YELLOW, string);
	ChangeVehiclePaintjob(GetPlayerVehicleID(id), pjob);
	return 1;
}

CMD:carcolor(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new
		string[128],
		id,
		col1,
		col2
	;
	if(sscanf(params, "uiI(255)", id, col1, col2)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /carcolor [playerid] [colour1] [colour2(optional)]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
	if(!IsPlayerInAnyVehicle(id)) 
		return SendClientMessage(playerid, COLOR_RED, "* Player must be inside of a vehicle.");

	if(col2==255) col2=random(256);

	format(string, sizeof(string), "You have changed the color of %s's %s to '%d,%d'", pName(id), VehicleNames[GetVehicleModel(GetPlayerVehicleID(id))-400], col1, col2);
	SendClientMessage(playerid, COLOR_GREEN, string);
	format(string, sizeof(string), "Admin %s has changed the color of your %s to '%d,%d'", pName(playerid), VehicleNames[GetVehicleModel(GetPlayerVehicleID(id))-400], col1, col2);
	SendClientMessage(id, COLOR_YELLOW, string);
	ChangeVehicleColor(GetPlayerVehicleID(id), col1, col2);
	return 1;
}

CMD:cc(playerid, params[]) return cmd_carcolor(playerid, params);

CMD:givecar(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

    new string[128],
		vID[32],
		id,
		vVW,
		vINT,
		vid,
		Float:x,
		Float:y,
		Float:z,
		Float:ang,
		vehicle,
		col1,
		col2
	;
	if(sscanf(params, "us[32]I(255)I(255)", id, vID, col1, col2)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /givecar [playerid] [vehicleid(or name)] [color1(optional)] [color2(optional)]");

	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
    if(isnumeric(vID)) vid = strval(vID);
    else vid = GetVehicleModelIDFromName(vID);
	GetPlayerPos(id, x, y, z);
    GetPlayerFacingAngle(id, ang);
	
	if(vid < 400 || vid > 611) 
		return SendClientMessage(playerid, COLOR_RED, "* Invalid Vehicle Model ID!");
		
	if(IsPlayerInAnyVehicle(id)) 
		return SendClientMessage(playerid, COLOR_RED, "* Player already have a vehicle.");

	if(col1==255) col1=random(256);
	if(col2==255) col2=random(256);

	if(IsValidVehicle(User[playerid][pCar]) && !IsPlayerAdmin(id))
	EraseVeh(User[id][pCar]);

	vehicle = CreateVehicle(vid, x, y, z, 0, -1, -1, 0);
    vVW = GetPlayerVirtualWorld(id);
    vINT = GetPlayerInterior(id);
    SetVehicleVirtualWorld(vehicle, vVW);
    LinkVehicleToInterior(vehicle, vINT);
    PutPlayerInVehicle(id, vehicle, 0);
	User[id][pCar] = vehicle;
	format(string, sizeof(string), "Admin %s(%d) has given you a %s(%i)", pName(playerid), playerid, VehicleNames[vid - 400], vid);
	SendClientMessage(id, COLOR_YELLOW, string);
	format(string, sizeof(string), "You have given %s(%d) a %s(%i)", pName(id), id, VehicleNames[vid - 400], vid);
	SendClientMessage(playerid, COLOR_YELLOW, string);
	return 1;
}

CMD:car(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);
	
	new carID[50], car, colour1, colour2, string[128];
	if(sscanf(params, "s[50]I(255)I(255)", carID, colour1, colour2)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /car [VehicleID(Name)] [Color1(Optional)] [Color2(Optional)]");
		
	if(!isnumeric(carID)) car = GetVehicleModelIDFromName(carID);
	else car = strval(carID);
	
	if(car < 400 || car > 611) 
		return SendClientMessage(playerid, COLOR_RED, "* Invalid Vehicle Model ID!");

	if(colour1==255) colour1=random(256);
	if(colour2==255) colour2=random(256);

	if(IsValidVehicle(User[playerid][pCar]) && !IsPlayerAdmin(playerid))
	EraseVeh(User[playerid][pCar]);
	new VehicleID;
	new Float:X, Float:Y, Float:Z;
	new Float:Angle, int1;
	GetPlayerPos(playerid, X, Y, Z);
	GetPlayerFacingAngle(playerid, Angle);
	int1 = GetPlayerInterior(playerid);
	VehicleID = CreateVehicle(car, X+3,Y,Z, Angle, colour1, colour2, -1);
	LinkVehicleToInterior(VehicleID, int1);
	SetVehicleVirtualWorld(VehicleID, GetPlayerVirtualWorld(playerid));
	User[playerid][pCar] = VehicleID;
	format(string, sizeof(string), "You have spawned a %s (Model: %d) with color %d,%d", VehicleNames[car-400], car, colour1, colour2);
	SendClientMessage(playerid, COLOR_LIGHTBLUE, string);
	return 1;
}

CMD:spec(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new string[128], specplayerid, option[32];

	if(sscanf(params, "s[32]", option))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /spec [playerid(OFF)]");
		
	if(!strcmp(option, "off", true))
	{
	    if(User[playerid][SpecType] != ADMIN_SPEC_TYPE_NONE)
		{
			StopSpectate(playerid);
			SetTimerEx("PosAfterSpec", 1000, 0, "d", playerid);
			SendClientMessage(playerid, COLOR_LIGHTBLUE, "No longer spectating.");
		}
		else return SendClientMessage(playerid, COLOR_RED, "* You are not spectating anyone.");
	    return 1;
	}

	specplayerid = ReturnUser(option);
	
	if(!IsPlayerConnected(specplayerid))
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[specplayerid][accountAdmin])
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
	if(specplayerid == playerid)
		return SendClientMessage(playerid, COLOR_RED, "* You cannot spectate yourself.");
		
	if(GetPlayerState(specplayerid) == PLAYER_STATE_SPECTATING)
		return SendClientMessage(playerid, COLOR_RED, "* Player is spectating someone.");
		
	if(GetPlayerState(specplayerid) != 1 && GetPlayerState(specplayerid) != 2 && GetPlayerState(specplayerid) != 3)
		return SendClientMessage(playerid, COLOR_RED, "* Player not spawned.");
		
	GetPlayerPos(playerid, SpecPos[playerid][0], SpecPos[playerid][1], SpecPos[playerid][2]);
	GetPlayerFacingAngle(playerid, SpecPos[playerid][3]);
	SpecInt[playerid][0] = GetPlayerInterior(playerid);
	SpecInt[playerid][1] = GetPlayerVirtualWorld(playerid);
	StartSpectate(playerid, specplayerid);
	format(string, sizeof(string), "Now Spectating: %s (ID: %d)", pName(specplayerid), specplayerid);
	SendClientMessage(playerid, COLOR_LIGHTBLUE, string);
	SendClientMessage(playerid, -1, "Press SHIFT for Advance Spectating and SPACE for backward spectating.");
	return 1;
}

CMD:specoff(playerid, params[])
	return SendClientMessage(playerid, -1, "Command has been separated and combined to /spec (/spec off)");

CMD:akill(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new string[128], reason[128], id;

    if(sscanf(params, "uS(No Reason)[128]", id, reason)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /akill [playerid] [reason(Default: None)]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	if(User[id][accountGod] == 1)
	{
	    User[id][accountGod] = 0;
	}

    SetPlayerHealth(id, 0.0);
    format(string, sizeof(string), "ADMIN: %s was killed by %s (Reason: %s)", pName(id), pName(playerid), reason);
    SendClientMessageToAll(COLOR_ADMIN, string);
	return 1;
}

CMD:jail(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);
	
	new id, sec, reason[128], string[128];
	
	if(sscanf(params, "uiS(None)[128]", id, sec, reason)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /jail [playerid] [seconds] [reason]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
	if(sec < 30) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot jail lower than 30 seconds.");
	
	if(User[id][accountJail]) 
		return SendClientMessage(playerid, COLOR_RED, "* Player already jailed.");
		
	if(id == playerid) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on yourself.");

	SetCameraBehindPlayer(id);
	SetPlayerPos(id, 197.6661, 173.8179, 1003.0234);
	SetPlayerInterior(id, 3);

	format(string, sizeof(string), "ADMIN: %s was jailed for %d seconds by %s (Reason: %s)", pName(id), sec, pName(playerid), reason);
	SendClientMessageToAll(COLOR_ADMIN, string);
	format(string, sizeof(string), "You have been jailed by %s for %d seconds [%s].", pName(playerid), sec, reason);
	SendClientMessage(id, -1, string);

	format(string, sizeof(string), "%s has been jailed by %s (%d seconds, reason %s)", pName(id), pName(playerid), sec, reason);
	SaveLog("jail.txt", string);

	User[id][accountJail] = 1;
	User[id][accountJailSec] = sec;
	return 1;
}

CMD:unjail(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new id, reason[128], string[128];
	
	if(sscanf(params, "uS(None)[128]", id, reason)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /unjail [playerid] [reason]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
	if(!User[id][accountJail]) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not in jailed.");
		
	if(id == playerid) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on yourself.");

	format(string, sizeof(string), "ADMIN: %s was released from the jail by %s for %s", pName(id), pName(playerid), reason);
	SendClientMessageToAll(COLOR_ADMIN, string);
	format(string, sizeof(string), "You have been released from jail by %s.", pName(playerid));
	SendClientMessage(id, COLOR_GREEN, string);

	format(string, sizeof(string), "%s has been unjailed by %s for %s", pName(id), pName(playerid), reason);
	SaveLog("jail.txt", string);

	User[id][accountJail] = 0;
	User[id][accountJailSec] = 0;
	SpawnPlayer(id);
	return 1;
}

CMD:mute(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);
	
	new id, sec, reason[128], string[128];
	
	if(sscanf(params, "uD(-1)S(None)[128]", id, sec, reason)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /mute [playerid] [seconds(optional for permanent)] [reason(optional)]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
	if(sec < 30 && sec != -1) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot mute lower than 30 seconds.");
		
	if(User[id][accountMuted]) 
		return SendClientMessage(playerid,COLOR_RED, "* Player already muted.");
		
	if(id == playerid) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on yourself.");

	if(sec != -1)
	{
		format(string, sizeof(string), "ADMIN: %s was muted for %d seconds by %s (Reason: %s)", pName(id), sec, pName(playerid), reason);
		SendClientMessageToAll(COLOR_ADMIN, string);
		format(string, sizeof(string), "You have been muted by %s for %d seconds [%s].", pName(playerid), sec, reason);
		SendClientMessage(id, -1, string);
		
		format(string, sizeof(string), "%s has been muted by %s (%d seconds, reason %s)", pName(id), pName(playerid), sec, reason);
		SaveLog("mute.txt", string);
	}
	else
	{
		format(string, sizeof(string), "ADMIN: %s was muted permanently by %s (Reason: %s)", pName(id), pName(playerid), reason);
		SendClientMessageToAll(COLOR_ADMIN, string);
		format(string, sizeof(string), "You have been muted permanently by %s. [%s].", pName(playerid), reason);
		SendClientMessage(id, -1, string);
		
		format(string, sizeof(string), "%s has been muted by %s (reason %s)", pName(id), pName(playerid), reason);
		SaveLog("mute.txt", string);	
	}
	
	User[id][accountMuted] = 1;
	User[id][accountMuteSec] = sec;
	return 1;
}

CMD:unmute(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);
	
	new id, reason[128], string[128];
	
	if(sscanf(params, "uS(None)[128]", id, reason)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /unmute [playerid] [reason]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	if(!User[id][accountMuted]) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not muted.");
		
	if(id == playerid) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on yourself.");

	format(string, sizeof(string), "ADMIN: %s was unmuted by %s for %s", pName(id), pName(playerid), reason);
	SendClientMessageToAll(COLOR_ADMIN, string);
	format(string, sizeof(string), "You have been unmuted by %s.", pName(playerid));
	SendClientMessage(id, -1, string);

	format(string, sizeof(string), "%s has been unmuted by %s", pName(id), pName(playerid));
	SaveLog("mute.txt", string);

	User[id][accountMuted] = 0;
	User[id][accountMuteSec] = 0;
	return 1;
}

CMD:setskin(playerid, params[])
{
	new string[128], id, skin;

	LoginCheck(playerid);
	LevelCheck(playerid, 2);
	
	if(sscanf(params, "ui", id, skin)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /setskin [playerid] [skin(0-311)]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
	if(skin < 0 || skin == 74 || skin > 311) return SendClientMessage(playerid, COLOR_RED, "* Invalid skinID.");

	format(string, sizeof(string), "You have set "green"%s's "white"skinID to "grey"%d", pName(id), skin);
	SendClientMessage(playerid, -1, string);

    format(string, sizeof(string), "Admin "green"%s "white"has set your skinID to "grey"%d", pName(playerid), skin);
	SendClientMessage(id, -1, string);

    SetPlayerSkin(id, skin);
	return 1;
}

CMD:clearchat(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new string[128];

	for(new i=0; i<100; i++)
	{
		SendClientMessageToAll(-1, " ");
	}
	
    format(string, sizeof string, "Chat was cleared by %s.", pName(playerid));
    SendClientMessageToAll(COLOR_ADMIN, string);
	return 1;
}

CMD:heal(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new id, string[92];

    if(sscanf(params, "u", id)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /heal [playerid]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

    SetPlayerHealth(id, 100.0);
    format(string, sizeof(string), "You have healed %s.", pName(id));
    SendClientMessage(playerid, COLOR_YELLOW, string);
    format(string, sizeof(string), "Admin %s has healed you.", pName(playerid));
    SendClientMessage(id, COLOR_YELLOW, string);
	return 1;
}

CMD:armour(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new id, string[128];

    if(sscanf(params, "u", id)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /armour [playerid]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

    SetPlayerArmour(id, 100.0);
    format(string, sizeof(string), "You have given %s an armour.", pName(id));
    SendClientMessage(playerid, COLOR_YELLOW, string);
    format(string, sizeof(string), "Admin %s has given you a full armour.", pName(playerid));
    SendClientMessage(id, COLOR_YELLOW, string);
	return 1;
}

CMD:setinterior(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new string[128], id, interior;

	if(sscanf(params, "ui", id, interior)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /setinterior [playerid] [interior]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
	SetPlayerInterior(id, interior);
	format(string, sizeof(string), "Admin %s has set your interior to %d.", pName(playerid), interior);
	SendClientMessage(id, COLOR_ORANGE, string);
	format(string, sizeof(string), "You have set Player %s's interior to %d.", pName(id), interior);
	SendClientMessage(playerid, COLOR_ORANGE, string);
	return 1;
}

CMD:setworld(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new
		string[128],
		id,
		vw
	;

	if(sscanf(params, "ui", id, vw)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /setworld [playerid] [virtual world]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
	SetPlayerVirtualWorld(id, vw);
	format(string, sizeof(string), "Admin %s has set your virtual world to %d.", pName(playerid), vw);
	SendClientMessage(id, COLOR_ORANGE, string);
	format(string, sizeof(string), "You have set %s's virtual world to %d.", pName(id), vw);
	SendClientMessage(playerid, COLOR_ORANGE, string);
	return 1;
}

CMD:explode(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new string[128], id, Float:x, Float:y, Float:z, reason[128];

	if(sscanf(params, "uS(Not specified)[128]", id, reason)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /explode [playerid] [reason(Default: N/A)]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	GetPlayerPos(id, x, y, z);
	format(string, sizeof(string), "ADMIN: %s has been exploded by %s (Reason: %s)", pName(id), pName(playerid), reason);
	SendClientMessageToAll(COLOR_ADMIN, string);
	SaveLog("explode.txt", string);
	CreateExplosionForPlayer(id, x, y, z, 7, 1.00);
	return 1;
}

CMD:disarm(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 2);

	new string[92], id;

	if(sscanf(params, "u", id)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /disarm [playerid]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
    ResetPlayerWeapons(id);
    format(string, sizeof(string), "You have removed %s's guns.", pName(id));
    SendClientMessage(playerid, COLOR_YELLOW, string);
    format(string, sizeof(string), "Admin %s has removed your guns.", pName(playerid));
    SendClientMessage(id, COLOR_YELLOW, string);
	return 1;
}

//============================================================================//
//						  Administrative Level Three                          //
//============================================================================//

CMD:jconfig(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 3);
	
	Config(1, playerid);
	return 1;
}

CMD:setchocolate(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 3);

    new id, string[128], amount;
    
	if(sscanf(params, "ud", id, amount))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /setchocolate [playerid] [amount(cannot be below zero)]");

	if(id == INVALID_PLAYER_ID)
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

	if(User[playerid][accountAdmin] < User[id][accountAdmin])
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	format(string, sizeof(string), "Your chocolate has been set from %d to %d by %s.", User[id][accountChocolate], amount, pName(playerid));
	SendClientMessage(id, COLOR_YELLOW, string);
	format(string, sizeof(string), "You set %s's chocolate from %d to %d..", pName(id), User[id][accountChocolate], amount);
	SendClientMessage(playerid, -1, string);
	
	User[id][accountChocolate] = amount;
	SaveData(id);
	return 1;
}

CMD:hidemarker(playerid, params[])
{
	new string[92];

	LoginCheck(playerid);
	LevelCheck(playerid, 3);

	switch(User[playerid][accountMarker])
	{
	    case false:
	    {
	        format(string, sizeof(string), "* %s has their marker hidden.", pName(playerid));
	        SendAdmin(COLOR_ADMIN, string);
	        User[playerid][accountMarker] = true;
	        SetPlayerColor(playerid, RemoveAlpha(GetPlayerColor(playerid)));
	    }
	    case true:
	    {
	        format(string, sizeof(string), "* %s has their marker visible again.", pName(playerid));
	        SendAdmin(COLOR_ADMIN, string);
	        User[playerid][accountMarker] = false;
	        SetPlayerColor(playerid, AddAlpha(GetPlayerColor(playerid)));
	    }
	}
	return 1;
}

CMD:setvotekicklimit(playerid, params[])
{
	new string[128], limit;

	LoginCheck(playerid);
	LevelCheck(playerid, 3);

    if(sscanf(params, "i", limit))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /setvotekicklimit [limit(3-10)]");
		
    if(limit > 3 && limit < 10)
        return SendClientMessage(playerid, COLOR_RED, "* The kick-limit must be above 1, but below 10!");
		
    if(limit == MaxVKICK)
    {
	    format(string, sizeof(string), "* The vote-kick limit is already %i!", limit);
	    return SendClientMessage(playerid, COLOR_RED, string);
    }

    format(string, sizeof(string), "* Admin %s has changed the required votes for vote-kick to %d.", pName(playerid), limit);
    SendClientMessageToAll(COLOR_ADMIN, string); 
	SaveLog("votekick.txt", string);
    MaxVKICK = limit; 
	return 1;
}

CMD:forbidword(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new string[128], File:BLfile;

	if(isnull(params))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /forbidword [word]");

	BLfile = fopen("JakAdmin/ForbiddenWords.cfg", io_append);
	format(string, sizeof(string), "%s\r\n", params);
	fwrite(BLfile, string);
	fclose(BLfile);

	format(string, sizeof(string), "Admin %s has added the word %s to the forbidden word list", pName(playerid), params);
	SendAdmin(COLOR_ADMIN, string);

	UpdateForbidden();
	return 1;
}

CMD:forbidname(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new string[128], File:BLfile;

	if(isnull(params))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /forbidname [nickname]");

	if(strlen(params) < 3 || strlen(params) > 20)
	    return SendClientMessage(playerid, COLOR_RED, "USAGE: /forbidname [nickname]");

	BLfile = fopen("JakAdmin/ForbiddenNames.cfg", io_append);
	format(string, sizeof(string), "%s\r\n", params);
	fwrite(BLfile, string);
	fclose(BLfile);

	format(string, sizeof(string), "Admin %s has added the name %s to the forbidden name list", pName(playerid), params);
	SendAdmin(COLOR_ADMIN, string);

	UpdateForbidden();
	return 1;
}

CMD:get(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 3);

    new id, string[92], Float:x, Float:y, Float:z;
	
	if(sscanf(params, "u", id)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /get [playerid]");

	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(id == playerid) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot teleport yourself to yourself.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	GetPlayerPos(playerid, x, y, z);
	SetPlayerInterior(id, GetPlayerInterior(playerid));
	SetPlayerVirtualWorld(id, GetPlayerVirtualWorld(playerid));

	if(GetPlayerState(id) == 2)
	{
		new VehicleID = GetPlayerVehicleID(id);
		SetVehiclePos(VehicleID, x+3, y, z);
		LinkVehicleToInterior(VehicleID, GetPlayerInterior(playerid));
		SetVehicleVirtualWorld(GetPlayerVehicleID(id), GetPlayerVirtualWorld(playerid));
	}
	else SetPlayerPos(id, x+2, y, z);

	format(string, sizeof(string), "You have been teleported to Admin %s position.", pName(playerid));
	SendClientMessage(id, COLOR_YELLOW, string);
	format(string, sizeof(string), "You have teleported %s to your position.", pName(id));
	SendClientMessage(playerid, COLOR_YELLOW, string);
	return 1;
}

CMD:crash(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new id, string[92];

	if(sscanf(params, "u", id))
	    return SendClientMessage(playerid, COLOR_RED, "USAGE: /crash [playerid]");

	if(id == INVALID_PLAYER_ID)
	    return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

	if(User[playerid][accountAdmin] < User[id][accountAdmin] && id != playerid)
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	format(string, sizeof(string), "You crashed %s's game.", pName(id));
	SendClientMessage(playerid, -1, string);
	format(string, sizeof(string), "Admin %s has crashed your game.", pName(playerid));
	SendClientMessage(id, COLOR_YELLOW, string);

	GameTextForPlayer(id, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 1000, 0);
	GameTextForPlayer(id, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 2000, 1);
	GameTextForPlayer(id, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 3000, 2);
	GameTextForPlayer(id, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 4000, 3);
	GameTextForPlayer(id, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 5000, 4);
	GameTextForPlayer(id, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 6000, 5);
	GameTextForPlayer(id, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 7000, 6);
	return 1;
}

CMD:write(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new Colour;
	
	if(sscanf(params, "is[128]", Colour, params))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /write [color] [text]") &&
		SendClientMessage(playerid, COLOR_GREY, "Colors: [0]Black, [1]White, [2]Red, [3]Orange, [4]Yellow, [5]Green, [6]Blue, [7]Purple, [8]Brown, [9]Pink");

	switch(Colour)
	{
		case 0: SendClientMessageToAll(COLOR_BLACK, params);
		case 1: SendClientMessageToAll(COLOR_WHITE, params);
		case 2: SendClientMessageToAll(COLOR_RED, params); 
		case 3: SendClientMessageToAll(COLOR_ORANGE, params);
		case 4: SendClientMessageToAll(COLOR_YELLOW, params);
		case 5: SendClientMessageToAll(COLOR_GREEN, params);
		case 6: SendClientMessageToAll(COLOR_BLUE, params); 
		case 7: SendClientMessageToAll(COLOR_PURPLE, params);
		case 8: SendClientMessageToAll(COLOR_BROWN, params);
		case 9: SendClientMessageToAll(COLOR_PINK, params);
		default: SendClientMessage(playerid, COLOR_GREY, "Colors: [0]Black, [1]White, [2]Red, [3]Orange, [4]Yellow, [5]Green, [6]Blue, [7]Purple, [8]Brown, [9]Pink");
	}
	return 1;
}

CMD:force(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new string[128], id;

    if(sscanf(params, "u", id)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /force [playerid]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	format(string, sizeof(string), "You have forced %s to goto class selection.", pName(id));
	SendClientMessage(playerid, COLOR_YELLOW, string);

	format(string, sizeof(string), "Admin %s forced you to goto class selection.", pName(playerid));
	SendClientMessage(id, COLOR_YELLOW, string);

	SetPlayerHealth(id, 0.0);
	ForceClassSelection(id);
	return 1;
}

CMD:healall(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new string[128];

	foreach(new i : Player)
	{
        if(i != playerid && User[playerid][accountAdmin] > User[i][accountAdmin])
        {
			SetPlayerHealth(i, 100.0);
        }
    }
    format(string, sizeof(string), "ADMIN: Admin %s has healed all players.", pName(playerid));
    SendClientMessageToAll(COLOR_ADMIN, string);
	return 1;
}

CMD:setfstyle(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new string[128], id, fstyle, style[32];

    if(sscanf(params, "ui", id, fstyle)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /setfstyle [playerid] [styles]") &&
		SendClientMessage(playerid, COLOR_GREY, "Styles: [0]Normal, [1]Boxing, [2]Kungfu, [3]Kneehead, [4]Grabkick, [5]Elbow");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	if(fstyle > 5) 
		return SendClientMessage(playerid, COLOR_RED, "* Inavlid Fighting Style.");

	switch(fstyle)
	{
	    case 0:
	    {
	        SetPlayerFightingStyle(id, 4);
	        style = "Normal";
	    }
	    case 1:
	    {
	        SetPlayerFightingStyle(id, 5);
	        style = "Boxing";
	    }
	    case 2:
	    {
	        SetPlayerFightingStyle(id, 6);
	        style = "Kung Fu";
	    }
	    case 3:
	    {
	        SetPlayerFightingStyle(id, 7);
	        style = "Kneehead";
	    }
	    case 4:
	    {
	        SetPlayerFightingStyle(id, 15);
	        style = "Grabkick";
	    }
	    case 5:
	    {
	        SetPlayerFightingStyle(id, 16);
	        style = "Elbow";
	    }
	}
	format(string, sizeof(string), "You have set %s(ID:%d) fighting style to '%s'", pName(id), id, style);
	SendClientMessage(playerid, COLOR_YELLOW, string);
	format(string, sizeof(string), "Admin %s(ID:%d) has set your fighting style to '%s'", pName(playerid), playerid, style);
	SendClientMessage(id, COLOR_YELLOW, string);
	return 1;
}

CMD:sethealth(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new string[128], id, hp;

    if(sscanf(params, "ud", id, hp)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /sethealth [playerid] [heatlh]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	SetPlayerHealth(id, hp);
	
	format(string, sizeof(string), "You have set %s's health to %d", pName(id), hp);
	SendClientMessage(playerid, COLOR_YELLOW, string);
	format(string, sizeof(string), "Admin %s has set your health to %d", pName(playerid), hp);
	SendClientMessage(id, COLOR_YELLOW, string);
	return 1;
}

CMD:setarmour(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new string[128], id, armour;

    if(sscanf(params, "ud", id, armour)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /setarmour [playerid] [armour]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	SetPlayerArmour(id, armour);
	
	format(string, sizeof(string), "You have set %s's armour to %d", pName(id), armour);
	SendClientMessage(playerid, COLOR_YELLOW, string);
	format(string, sizeof(string), "Admin %s has set your armour to %d", pName(playerid), armour);
	SendClientMessage(id, COLOR_YELLOW, string);
	return 1;
}

CMD:destroycar(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 3);
	DelVehicle(GetPlayerVehicleID(playerid));
	return 1;
}

CMD:teleplayer(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new string[128],id, id2, Float:x, Float:y, Float:z;
	
	if(sscanf(params, "uu", id, id2)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /teleplayer [playerid] to [playerid2]");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
	if(User[playerid][accountAdmin] < User[id2][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(id2 == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(id == playerid && id2 == playerid) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot teleport yourself to yourself!");

	GetPlayerPos(id2, x, y, z);
	format(string, sizeof(string), "You have teleported %s to %s.", pName(id), pName(id2));
	SendClientMessage(playerid, COLOR_YELLOW, string);
	format(string, sizeof(string), "You have been teleported to %s by Admin %s.", pName(id2), pName(playerid));
	SendClientMessage(id, COLOR_YELLOW, string);
	format(string, sizeof(string), "Admin %s has teleported %s to you", pName(playerid), pName(id));
	SendClientMessage(id2, COLOR_YELLOW, string);
	SetPlayerInterior(id, GetPlayerInterior(id2));
	SetPlayerVirtualWorld(id, GetPlayerVirtualWorld(id2));
	if(GetPlayerState(id) == 2)
	{
		SetVehiclePos(GetPlayerVehicleID(id), x+3, y, z);
		LinkVehicleToInterior(GetPlayerVehicleID(id), GetPlayerInterior(id2));
		SetVehicleVirtualWorld(GetPlayerVehicleID(id), GetPlayerVirtualWorld(id2));
	}
	else SetPlayerPos(id, x+2, y, z);
	return 1;
}

CMD:armourall(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new string[128];
	
	foreach(new i : Player)
	{
        if(i != playerid && User[playerid][accountAdmin] > User[i][accountAdmin])
        {
		    SetPlayerArmour(i, 100.0);
        }
    }
	
    format(string, sizeof(string), "ADMIN: Admin %s has given everyone an armour.", pName(playerid));
    SendClientMessageToAll(COLOR_ADMIN, string);
	return 1;
}

CMD:bankrupt(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 3);

    new id, string[128];

	if(sscanf(params, "u", id)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /bankrupt [playerid]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	ResetPlayerMoney(id);
	format(string, sizeof(string), "Admin %s has taken all your cash in-hand.", pName(playerid));
	SendClientMessage(id, COLOR_YELLOW, string);
	format(string, sizeof(string), "You have taken all the money in hand of %s.", pName(id));
	SendClientMessage(playerid, COLOR_YELLOW, string);
	return 1;
}

CMD:getall(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new Float:x, Float:y, Float:z, string[128];

	GetPlayerPos(playerid, x, y, z);
	foreach(new i : Player)
	{
        if(i != playerid && User[playerid][accountAdmin] > User[i][accountAdmin])
        {
			PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
			SetPlayerPos(i, x+(playerid/4)+1, y+(playerid/4), z);
			SetPlayerInterior(i, GetPlayerInterior(playerid));
			SetPlayerVirtualWorld(i, GetPlayerVirtualWorld(playerid));
		}
	}

	format(string, sizeof(string), "ADMIN: Admin %s has teleported everyone to their position.", pName(playerid));
	SendClientMessageToAll(COLOR_ADMIN, string);
	return 1;
}

CMD:freeze(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new string[128], id, reason[128];

	if(sscanf(params, "uS(No Reason)[128]", id, reason)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /freeze [playerid] [reason]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(id == playerid) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot freeze yourself.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	TogglePlayerControllable(id, false);

	format(string, sizeof(string), "You have frozen %s. (Reason: %s)", pName(id), reason);
	SendClientMessage(playerid, COLOR_YELLOW, string);
	format(string, sizeof(string), "Admin %s has frozen you (Reason: %s)", pName(playerid), reason);
	SendClientMessage(id, COLOR_YELLOW, string);
	return 1;
}

CMD:unfreeze(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new string[128], id;

	if(sscanf(params, "u", id)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /unfreeze [playerid]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(id == playerid) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot unfreeze yourself.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin])
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	TogglePlayerControllable(id, true);

	format(string, sizeof(string), "You have unfrozen %s.", pName(id));
	SendClientMessage(playerid, COLOR_YELLOW, string);
	format(string, sizeof(string), "Admin %s has unfrozen you.", pName(playerid));
	SendClientMessage(id, COLOR_YELLOW, string);
	return 1;
}

CMD:giveweapon(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new id, ammo, wID[32], weap, WeapName[32], string[128];

	if(sscanf(params, "us[32]i", id, wID, ammo)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /giveweapon [playerid] [weaponid(or weapon name)] [ammo]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(ammo <= 0 || ammo > 99999) ammo = 500;
	if(!isnumeric(wID)) weap = GetWeaponIDFromName(wID);
	else weap = strval(wID);
	
	if(!IsValidWeapon(weap)) 
		return SendClientMessage(playerid, COLOR_RED, "* Invalid Weapon ID.");
	GetWeaponName(weap, WeapName, 32);
	
	format(string, sizeof(string), "You gave a %s(%d) with %d rounds of ammunation to %s.", WeapName, weap, ammo, pName(id));
	SendClientMessage(playerid, COLOR_YELLOW, string);
	format(string,sizeof(string),"Admin %s has given you a %s(%d) with %d rounds of ammunation.", pName(playerid), WeapName, weap, ammo);
	SendClientMessage(id, COLOR_YELLOW, string);
	GivePlayerWeapon(id, weap, ammo);
	return 1;
}

CMD:unban(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 3);
	
    new Account[24];
	
	if(sscanf(params, "s[24]", Account)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /unban [account name]");

	UnbanAccount(playerid, Account);
	return 1;
}

CMD:checkban(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 3);
	
	new query[128], DBResult:result, name[24], admin[24], reason[128], when[32], banid, bandays;
	
	if(sscanf(params, "s[24]", name))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /checkban [name]");
	
	format(query, sizeof(query), "SELECT * FROM `bans` WHERE `username` = '%s'", DB_Escape(name));
	result = db_query(Database, query);
	
	if(db_num_rows(result))
	{  
		banid = db_get_field_assoc_int(result, "banid");
	    db_get_field_assoc(result, "banby", admin, sizeof(admin));
	    db_get_field_assoc(result, "banreason", reason, sizeof(reason));
	    db_get_field_assoc(result, "banwhen", when, sizeof(when));
		bandays = db_get_field_assoc_int(result, "temporary_ban");
		
		SendClientMessage(playerid, -1, "___________________________________________________");
		format(query, sizeof(query), "Name: %s (BanID: %d)", name, banid);
		SendClientMessage(playerid, COLOR_RED, query);
		format(query, sizeof(query), "Issued By: %s", admin);
		SendClientMessage(playerid, COLOR_RED, query);
		format(query, sizeof(query), "Reason: %s", reason);
		SendClientMessage(playerid, COLOR_RED, query);
		format(query, sizeof(query), "Issued On: %s", when);
		SendClientMessage(playerid, COLOR_RED, query);
		if(bandays == 340703845) // Forever 
		{
			format(query, sizeof(query), "Expires In: Never");
		}
		else
		{
			new datestring[32];
			datestring = ConvertTimestamp(bandays, 4);
			format(query, sizeof(query), "Expires In: %s", datestring);
		}
		SendClientMessage(playerid, COLOR_RED, query);
		SendClientMessage(playerid, -1, "___________________________________________________");
	}
	else
	{
		format(query, sizeof(query), "* '%s' is not banned.", name);
		SendClientMessage(playerid, COLOR_RED, query);
	}
	db_free_result(result);
	return 1;
}

CMD:banip(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 3);	
	
	new string[128], ip[24];
	
	if(sscanf(params, "s[24]", ip))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /banip [IP address]");
		
	if(IsValidIP(ip))
		return SendClientMessage(playerid, COLOR_RED, "* You have not placed a proper IP format.");
		
	if(CheckBan(ip))
		return SendClientMessage(playerid, COLOR_RED, "* IP is already banned.");
		
	AddBan(ip);
	format(string, sizeof(string), "[BanIP] %s has banned IP %s.", pName(playerid), ip);
	SendAdmin(COLOR_ADMIN, string);
	return 1;
}

CMD:unbanip(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 3);	
	
	new string[128], ip[24];
	
	if(sscanf(params, "s[24]", ip))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /unbanip [IP address]");
		
	if(IsValidIP(ip))
		return SendClientMessage(playerid, COLOR_RED, "* You have not placed a proper IP format.");
		
	if(!CheckBan(ip))
		return SendClientMessage(playerid, COLOR_RED, "* IP is not banned.");
		
	RemoveBan(ip);
	format(string, sizeof(string), "[BanIP] %s has removed IP %s from the ban list.", pName(playerid), ip);
	SendAdmin(COLOR_ADMIN, string);
	return 1;
}

CMD:ban(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 3);

    new string[128], id, reason[128], when[64], ban_hr, ban_min, ban_sec, ban_month, ban_days, ban_years, days, finaldays;

	gettime(ban_hr, ban_min, ban_sec);
	getdate(ban_years, ban_month, ban_days);

    if(sscanf(params, "uS(No Reason)[128]", id, reason, days)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /ban [playerid] [reason(Default: No Reason)] [days(0 for permanent)]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(id == playerid) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command to yourself.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	format(when, sizeof(when), "%02d/%02d/%d %02d:%02d:%02d", ban_month, ban_days, ban_years, ban_hr, ban_min, ban_sec);

	if(days < 1)
	{
		format(string, sizeof(string), "ADMIN: %s was permanently-banned from the server by %s (Reason: %s)", pName(id), pName(playerid), reason);
		SendClientMessageToAll(COLOR_ADMIN, string);
		printf(string);
		SaveLog("banlog.txt", string);
		
		format(string, sizeof(string), "You have permanently-banned %s for %s.", pName(id), reason);
		SendClientMessage(playerid, COLOR_YELLOW, string);
		format(string, sizeof(string), "You have been permanently-banned by %s (Reason: %s)", pName(playerid), reason);
		SendClientMessage(id, COLOR_YELLOW, string);
		BanAccount(id, pName(playerid), reason);    
	}
	else
	{
		format(string, sizeof(string), "ADMIN: %s was banned for %d day(s) from the server by %s (Reason: %s)", pName(id), days, pName(playerid), reason);
		SendClientMessageToAll(COLOR_ADMIN, string);
		printf(string);
		SaveLog("banlog.txt", string);
		
		format(string, sizeof(string), "You have banned %s for %d day(s) for %s.", pName(id), days, reason);
		SendClientMessage(playerid, COLOR_YELLOW, string);
		format(string, sizeof(string), "You have been banned for %d day(s) by %s (Reason: %s)", pName(playerid), days, reason);
		SendClientMessage(id, COLOR_YELLOW, string);
		BanAccount(id, pName(playerid), reason, days);    	
	}
	
	for(new i; i < 100; i++) SendClientMessage(playerid, -1, " ");
	
	finaldays = (gettime() + 60*60*24*days);
	if(!days) finaldays = 340703845;
	
	ShowBan(id, GetPVarInt(id, "ban_id"), pName(playerid), reason, when, finaldays);
	KickDelay(id);
	return 1;
}

CMD:oban(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 3);

    new id, string[128], name[24], reason[128], Query[128], admin, ip[20], DBResult:Result, ban_hr, ban_min, ban_sec, ban_month, ban_days, ban_years, day;

	gettime(ban_hr, ban_min, ban_sec);
	getdate(ban_years, ban_month, ban_days);

    if(sscanf(params, "s[24]s[128]d", name, reason, day)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /oban [name in the data] [reason] [days(0 for permanent)]");
		
	id = ReturnUser(name);
	if(IsPlayerConnected(id))
	{
		format(string, sizeof(string), "* %s is in game, use /ban %d instead.", name, id);
		return SendClientMessage(playerid, COLOR_RED, string);
	}
	
    format(Query, sizeof(Query), "SELECT * FROM `users` WHERE `username` = '%s'", DB_Escape(name));
    Result = db_query(Database, Query);
    if(db_num_rows(Result))
    {
        admin = db_get_field_assoc_int(Result, "admin");
        db_get_field_assoc(Result, "IP", ip, 20);

		if(User[playerid][accountAdmin] < admin)
		{
			SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on high ranking admin.");

			format(string, sizeof(string), "%s has attempted to offline ban %s but failed for %s", pName(playerid), name, reason);
			SaveLog("admin.txt", string);
			return 1;
		}
		
		BanAccountEx(name, ip, pName(playerid), reason, day);

		if(day < 1)
		{
			format(string, sizeof(string), "ADMIN: %s was offline banned-permanently by %s (Reason: %s)", name, pName(playerid), reason);
		}
		else 
		{
			format(string, sizeof(string), "ADMIN: %s was offline banned for %d day(s) by %s (Reason: %s)", name, day, pName(playerid), reason);
		}
		SendAdmin(COLOR_ADMIN, string);
	    printf(string);
    	SaveLog("banlog.txt", string);
	}
	else
	{
		format(string, sizeof(string), "* There is no '%s' in the server database.", name);
	    SendClientMessage(playerid, COLOR_RED, string);
	}
    db_free_result(Result);
	return 1;
}

CMD:cname(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new string[128], id, result = 0, newname[24];

	if(sscanf(params, "us[24]", id, newname)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /cname [playerid] [new name]");
		
	if(strlen(newname) < 3 || strlen(newname) > 20) 
		return SendClientMessage(playerid, COLOR_RED, "* Invalid Name Length.");
	
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
	if((result = CheckAccount(newname)) != 0)
	{
	    format(string, sizeof(string), "* This name is already taken (#UserID %d)", result);
	    SendClientMessage(playerid, COLOR_RED, string);
	    return 1;
	}
	
	if(!User[id][accountLogged]) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not logged in.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	format(string, sizeof string, "Admin %s has set %s's name to %s", pName(playerid), pName(id), newname);
	SaveLog("account.txt", string);

	format(string, sizeof(string), "You have set %s's name to %s.", pName(id), newname); SendClientMessage(playerid, COLOR_YELLOW, string);
	format(string, sizeof(string), "Admin %s has set your name to %s.", pName(playerid), newname); SendClientMessage(id, COLOR_YELLOW, string);
	SetPlayerName(id, newname);

	SendClientMessage(id, -1, "You have been logged out from your current account, Reconnecting to the server...");
	
	format(string, sizeof(string), "UPDATE `users` SET `username` = '%s' WHERE `userid` = %d", DB_Escape(newname), User[id][accountID]);
	db_query(Database, string);
	return 1;
}

CMD:slap(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 3);

    new Float:x, Float:y, Float:z, Float:health, string[128], id, reason[128];

    if(sscanf(params, "uS(Not specified)[128]", id, reason)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /slap [playerid] [reason(Default: N/A)]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
	GetPlayerPos(id, x, y, z);
    GetPlayerHealth(id, health);
    SetPlayerHealth(id, health-25);
	SetPlayerPos(id, x, y, z+5);
    PlayerPlaySound(playerid, 1190, 0.0, 0.0, 0.0);
    PlayerPlaySound(id, 1190, 0.0, 0.0, 0.0);
	
	format(string, sizeof(string), "ADMIN: %s has been slapped by %s (Reason: %s)", pName(id), pName(playerid), reason);
	SendClientMessageToAll(COLOR_ADMIN, string);
	return 1;
}

CMD:setcolor(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 3);
	
	new id;
	if(sscanf(params, "u", id)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /setcolor [playerid]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	SetPVarInt(playerid, "_Colors_", id);

	Dialog_Show(playerid, DIALOG_COLORS, DIALOG_STYLE_LIST, ""green"Colors", ""black"Black\n"white"White\n"red"Red\n"green"Orange\n"yellow"Yellow\n"green"Green\n"blue"Blue\n"purple"Purple\n"brown"Brown\n"pink"Pink", "Set", "Cancel");
	return 1;
}

CMD:setmoney(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new id, string[128], amount;

    if(sscanf(params, "ui", id, amount)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /setmoney [playerid] [cash]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	ResetPlayerMoney(id);
	GivePlayerMoney(id, amount);
	format(string, sizeof(string), "You have set %s's cash to $%i.", pName(id), amount);
	SendClientMessage(playerid, COLOR_YELLOW, string);
	format(string, sizeof(string), "Admin %s has set your cash to $%i.", pName(playerid), amount);
	SendClientMessage(id, COLOR_YELLOW, string);
	
	format(string, sizeof string, "Admin %s has set %s's cash to $%i", pName(playerid), pName(id), amount);
	SaveLog("set.txt", string);
	return 1;
}

CMD:setscore(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 3);

	new id, string[128], amount;

    if(sscanf(params, "ui", id, amount)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /setscore [playerid] [score]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	SetPlayerScore(id, amount);
	format(string, sizeof(string), "You have set %s's score to %i.", pName(id), amount);
	SendClientMessage(playerid, COLOR_YELLOW, string);
	format(string, sizeof(string), "Admin %s has set your score to %i.", pName(playerid), amount);
	SendClientMessage(id, COLOR_YELLOW, string);

	format(string, sizeof string, "Admin %s has set %s's score to %i", pName(playerid), pName(id), amount);
	SaveLog("set.txt", string);
	return 1;
}

//============================================================================//
//						   Administrative Level Four                          //
//============================================================================//

CMD:lockchat(playerid, params[])
{
	new string[92];

    LoginCheck(playerid);
	LevelCheck(playerid, 4);
	
	switch(ServerInfo[LockChat])
	{
		case false:
		{
			format(string, sizeof(string), "* Admin %s has locked the chat.", pName(playerid));
			SendClientMessageToAll(COLOR_ADMIN, string);
			print(string);
			ServerInfo[LockChat] = true;
		}
		case true:
		{
			format(string, sizeof(string), "* Admin %s has unlocked the chat.", pName(playerid));
			SendClientMessageToAll(COLOR_ADMIN, string);
			print(string);
			ServerInfo[LockChat] = false;
		}
	}
	SaveConfig();
	return 1;
}

CMD:reloadcfg(playerid, params[])
{
	new string[92];

    LoginCheck(playerid);
	LevelCheck(playerid, 4);
	
	format(string, sizeof(string), "[CFG] %s has reload the cfgs files for JakAdmin.", pName(playerid));
	SendAdmin(COLOR_ADMIN, string);
	
	checkfolder();
	
	printf("[CFG] %s has reload the cgs files for JakAdmin.", pName(playerid));
	return 1;
}

CMD:setpass(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 4);

	new NewPass[24], AccountName[24], string[128], Buf[129], Query[300], DBResult:Result;
	
    if(sscanf(params, "s[24]s[24]", AccountName, NewPass))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /setpass [account name] [new pass]");
		
    if(strlen(NewPass) < 4 || strlen(NewPass) > 20)
        return SendClientMessage(playerid, COLOR_RED, "* New password length shouldn't go below four and shouldn't go below twenty.");

    WP_Hash(Buf, 129, NewPass);

    format(Query, sizeof(Query), "SELECT `userid` FROM `users` WHERE `username` = '%s'", DB_Escape(AccountName));
    Result = db_query(Database, Query);

    if(db_num_rows(Result))
    {
        format(Query, sizeof(Query), "UPDATE `users` SET `password` = '%s' WHERE `username` = '%s'", DB_Escape(Buf), DB_Escape(AccountName));
		db_query(Database, Query);

		format(string, sizeof string, "Admin %s has changed %s's password to %s.", pName(playerid), AccountName, NewPass);
		SaveLog("account.txt", string);
		format(string, sizeof string, "PASSWORD: Admin %s has changed %s's password.", pName(playerid), AccountName);
		SendAdmin(COLOR_GREEN, string);

		format(string, sizeof(string), "You have changed %s's password to %s.", AccountName, NewPass);
		SendClientMessage(playerid, COLOR_YELLOW, string);
	}
	else
	{
	    format(string, sizeof(string), "* Account: %s doesn't exist.", AccountName);
 		SendClientMessage(playerid, COLOR_RED, string);
	}
    db_free_result(Result);
	return 1;
}

CMD:jsettings(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 4);

	ShowSettings(playerid);
	return 1;
}

CMD:setonline(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 4);
	
	new id, hours, minutes, seconds, string[128];
	
	if(sscanf(params, "uddd", id, hours, minutes, seconds))
	    return SendClientMessage(playerid, COLOR_RED, "USAGE: /setonline [playerid] [hour] [minutes] [seconds]");
	    
	if(id == INVALID_PLAYER_ID)
	    return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

	if(User[playerid][accountAdmin] < User[id][accountAdmin])
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

	if(hours < 0)
	    return SendClientMessage(playerid, COLOR_RED, "* You cannot set the hours lower than zero.");

	if(minutes < 0 || minutes > 59)
	    return SendClientMessage(playerid, COLOR_RED, "* You cannot set the minutes lower than zero and more than fifty nine.");

	if(seconds < 0 || seconds > 59)
	    return SendClientMessage(playerid, COLOR_RED, "* You cannot set the seconds lower than zero and more than fifty nine.");

	format(string, sizeof(string), "* Your total time has been set from %02d:%02d:%02d to %02d:%02d:%02d by %s.", User[id][accountGame][2], User[id][accountGame][1], User[id][accountGame][0], hours, minutes, seconds, pName(playerid));
	SendClientMessage(id, COLOR_YELLOW, string);
	format(string, sizeof(string), "* You have set %s's total time to %02d:%02d:%02d.", pName(id), hours, minutes, seconds);
	SendClientMessage(playerid, -1, string);

	User[id][accountGame][2] = hours;
	User[id][accountGame][1] = minutes;
	User[id][accountGame][0] = seconds;
	
	SaveData(id);
	return 1;
}

CMD:gmx(playerid, params[])
{
	new string[128], time;

	LoginCheck(playerid);
	LevelCheck(playerid, 4);

	if(sscanf(params, "I(0)", time)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /gmx [Restart Timer(optional)") &&
		SendClientMessage(playerid, -1, "Note: You can leave the parameter for a fast restart, no timers.");

	if(time < 10 && time !=0) 
		return SendClientMessage(playerid, COLOR_RED, "* Restart Time shouldn't go below ten.");

	if(time >= 10)
	{
	    format(string, sizeof(string), "Admin %s has initiated a server restart, Estimated Time of Restart: %d.", pName(playerid), time);
	    SendClientMessageToAll(COLOR_ADMIN, string);
	    SetTimer("RestartTimer", 1000*time, false);
	}
	else
	{
	    format(string, sizeof(string), "Admin %s has restarted the server.", pName(playerid), playerid);
	    SendClientMessageToAll(COLOR_ADMIN, string);
	    SendRconCommand("gmx");
	}
	return 1;
}

function:RestartTimer()
{
	SendClientMessageToAll(COLOR_YELLOW, "Restart Time has been reached, Restarting the server now.");
	return SendRconCommand("gmx");
}

CMD:fakedeath(playerid, params[])
{
	new string[128], id, killerid, weapid;

	LoginCheck(playerid);
	LevelCheck(playerid, 4);

	if(sscanf(params, "uui", killerid, id, weapid)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /fakedeath [killer] [victim] [weapon]");
		
	if(killerid == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* KillerID not connected.");
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* VictimID not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
	if(User[playerid][accountAdmin] < User[killerid][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
	if(id == playerid && killerid == playerid) 
		return SendClientMessage(playerid, COLOR_RED, "* You can't be KillerID and VictimID at the same time.");
	if(!IsValidWeapon(weapid)) 
		return SendClientMessage(playerid, COLOR_RED, "* Invalid Weapon ID.");

	SendDeathMessage(killerid, id, weapid);
	
	format(string, sizeof(string), "Fake Death Sent. [ Victim: %s(%d) | Suspect: %s(%d) | WeaponID: %i ]", pName(id), id, pName(killerid), killerid, weapid);
	SendClientMessage(playerid, COLOR_YELLOW, string);
	return 1;
}

CMD:setallskin(playerid, params[])
{
	new string[92], skin;

	LoginCheck(playerid);
	LevelCheck(playerid, 4);

	if(sscanf(params, "i", skin)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /setallskin [skin(0-311)]");
		
	if(skin < 0 || skin == 74 || skin > 311) 
		return SendClientMessage(playerid, COLOR_RED, "* Invalid skinID.");

	foreach(new i : Player)
	{
		if(i != playerid && User[playerid][accountAdmin] > User[i][accountAdmin])
		{
			SetPlayerSkin(i, skin);
		}
	}

	format(string, sizeof(string), "ADMIN: Admin %s has set everyones skin to %d.", pName(playerid), skin);
	SendClientMessageToAll(COLOR_ADMIN, string);
	return 1;
}

CMD:cmdmuted(playerid, params[])
{
	new string[128], count = 0;

	SendClientMessage(playerid, -1, "** "green"Command Muted Players "white"**");
	foreach(new i : Player)
	{
	    if(User[i][accountLogged] == 1)
	    {
	        if(User[i][accountCMuted] == 1)
	        {
	            format(string, sizeof(string), "(%d) %s - Seconds left %d", i, pName(i), User[i][accountCMuteSec]);
	            SendClientMessage(playerid, COLOR_LIGHTBLUE, string);
	            count++;
	        }
	    }
	}
	if(count == 0) return SendClientMessage(playerid, -1, "No command muted players at the server.");
	return 1;
}

CMD:mutecmd(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 4);
	
	new id, sec, reason[128], string[128];
	
	if(sscanf(params, "uD(-1)S(None)[128]", id, sec, reason)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /mutecmd [playerid] [seconds(optional for permanent)] [reason(optional)]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
	if(sec < 30 && sec != -1) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot mute lower than 30 seconds.");
		
	if(User[id][accountCMuted]) 
		return SendClientMessage(playerid, COLOR_RED, "* Player already muted from using the commands.");
		
	if(id == playerid) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on yourself.");
	
	if(sec != -1)
	{
		format(string, sizeof(string), "ADMIN: %s was muted from using commands for %d seconds by %s (Reason: %s)", pName(id), sec, pName(playerid), reason);
		SendClientMessageToAll(COLOR_ADMIN, string);
		format(string, sizeof(string), "You have been muted from using commands for %d seconds by %s (Reason: %s)", sec, pName(playerid), reason);
		SendClientMessage(id, -1, string);

		format(string, sizeof(string), "%s has been muted from using commands by %s (%d seconds, reason %s)", pName(id), pName(playerid), sec, reason);
		SaveLog("mute.txt", string);
	}
	else
	{
		format(string, sizeof(string), "ADMIN: %s was permanently muted from using commands by %s (Reason: %s)", pName(id), pName(playerid), reason);
		SendClientMessageToAll(COLOR_ADMIN, string);
		format(string, sizeof(string), "You have been muted permanently from using commands by %s (Reason: %s).", pName(playerid), reason);
		SendClientMessage(id, -1, string);

		format(string, sizeof(string), "%s has been muted from using commands by %s (reason %s)", pName(id), pName(playerid), reason);
		SaveLog("mute.txt", string);	
	}
	
	User[id][accountCMuted] = 1;
	User[id][accountCMuteSec] = sec;
	return 1;
}

CMD:unmutecmd(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 4);
	
	new id, reason[128], string[128];
	
	if(sscanf(params, "uS(None)[128]", id, reason)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /unmutecmd [playerid] [reason]");
		
	if(id == INVALID_PLAYER_ID) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
		
	if(User[playerid][accountAdmin] < User[id][accountAdmin]) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");
		
	if(!User[id][accountCMuted]) 
		return SendClientMessage(playerid, COLOR_RED, "* Player not muted from using the commands.");
		
	if(id == playerid) 
		return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on yourself.");

	format(string, sizeof(string), "ADMIN: %s was unmuted from using commands by %s for %s", pName(id), pName(playerid), reason);
	SendClientMessageToAll(COLOR_ADMIN, string);
	format(string, sizeof(string), "You have been unmuted from using commands by %s.", pName(playerid));
	SendClientMessage(id, COLOR_GREEN, string);

	format(string, sizeof(string), "%s has been unmuted from using commands by %s", pName(id), pName(playerid));
	SaveLog("mute.txt", string);

	User[id][accountCMuted] = 0;
	User[id][accountCMuteSec] = 0;
	return 1;
}

CMD:giveallchocolate(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 4);

	new string[128], amount;

	if(sscanf(params, "d", amount))
	    return SendClientMessage(playerid, COLOR_RED, "USAGE: /giveallchocolate [amount]");

	if(amount < 1)
	    return SendClientMessage(playerid, COLOR_RED, "* Invalid amount.");

	foreach(new i : Player)
	{
        if(i != playerid && User[playerid][accountAdmin] > User[i][accountAdmin])
        {
			User[i][accountChocolate] += amount;
		}
	}

	format(string, sizeof(string), "** Admin %s has given everyone %d chocolate(s).", pName(playerid), amount);
	SendClientMessageToAll(COLOR_ADMIN, string);
	printf(string);
	return 1;
}

CMD:kickall(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 4);

	new string[92];

	foreach(new i : Player)
	{
        if(i != playerid && User[playerid][accountAdmin] > User[i][accountAdmin])
        {
		    KickDelay(i);
		}
	}

	format(string, sizeof(string), "** Admin %s has kicked all players.", pName(playerid));
	SendClientMessageToAll(COLOR_YELLOW, string);
	printf(string);

	SaveLog("kicklog.txt", string);
	return 1;
}

CMD:disarmall(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 4);

    new string[92];

	foreach(new i : Player)
	{
		if(i != playerid && User[playerid][accountAdmin] > User[i][accountAdmin])
		{
			ResetPlayerWeapons(i);
		}
	}
	format(string, sizeof(string), "** Admin %s has removed everyones weapon.", pName(playerid));
	SendClientMessageToAll(COLOR_ADMIN, string);
	return 1;
}

CMD:giveallscore(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 4);

	new id, string[128];
	
	if(sscanf(params, "i", id)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /giveallscore [score]");
	
	foreach(new i : Player)
	{
        if(i != playerid && User[playerid][accountAdmin] > User[i][accountAdmin])
        {
			PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
			SetPlayerScore(i, GetPlayerScore(i) + id);
		}
	}

	format(string, sizeof(string), "** Admin %s has given everyone a score of %d", pName(playerid), id);
	SendClientMessageToAll(COLOR_ADMIN, string);
	return 1;
}

CMD:giveallcash(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 4);

	new id, string[128];
	
	if(sscanf(params, "i", id)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /giveallcash [money]");
		
	foreach(new i : Player)
	{
        if(i != playerid && User[playerid][accountAdmin] > User[i][accountAdmin])
        {
			PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
			GivePlayerMoney(i, id);
		}
	}

	format(string, sizeof(string), "* Admin %s has given everyone a $%d.", pName(playerid), id);
	SendClientMessageToAll(COLOR_ADMIN, string);
	return 1;
}

CMD:setalltime(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 4);

	new id, string[128];

	if(sscanf(params, "i", id)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /setalltime [time(0-23)]");
		
	if(id < 0 || id > 23) 
		return SendClientMessage(playerid, COLOR_RED, "* Invalid Time Hour (0-23).");
		
	foreach(new i : Player)
	{
		if(i != playerid && User[playerid][accountAdmin] > User[i][accountAdmin])
		{
			PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
			SetPlayerTime(i, id, 0);
		}
	}

	format(string, sizeof(string), "** Admin %s has set everyones time to %d:00.", pName(playerid), id);
	SendClientMessageToAll(COLOR_ADMIN, string);
	return 1;
}

CMD:setallweather(playerid, params[])
{
    LoginCheck(playerid);
	LevelCheck(playerid, 4);

	new id, string[128];
	
	if(sscanf(params, "i", id)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /setallweather [weather(0-45)]");
		
	if(id < 0 || id > 45) 
		return SendClientMessage(playerid, COLOR_RED, "* Invalid Weather ID! (0-45)");
		
	foreach(new i : Player)
	{
		if(i != playerid && User[playerid][accountAdmin] > User[i][accountAdmin])
		{
			PlayerPlaySound(i, 1057, 0.0, 0.0, 0.0);
			SetPlayerWeather(i, id);
		}
	}
	
	format(string, sizeof(string), "** Admin %s has set everyones weather to %d", pName(playerid), id);
	SendClientMessageToAll(COLOR_ADMIN, string);
	return 1;
}

CMD:respawncars(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 4);

	new string[92];
	
	format(string, sizeof(string), "** Admin %s has respawned all unoccupied vehicles.", pName(playerid));
	SendClientMessageToAll(COLOR_ADMIN, string);
	
	SendClientMessage(playerid, COLOR_GREEN, "You have successfully Respawned all Vehicles!");
	GameTextForAll("~n~~n~~n~~n~~n~~n~~r~Vehicles ~g~Respawned!", 3000, 3);
	
	for(new cars=0; cars<MAX_VEHICLES; cars++)
	{
	    if(!VehicleOccupied(cars))
	    {
            SetVehicleToRespawn(cars);
        }
	}
	return 1;
}

CMD:cleardwindow(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 4);

	new string[92];

    format(string, sizeof(string), "** Admin %s has cleared the Death Window!", pName(playerid));
    SendClientMessageToAll(COLOR_ADMIN, string);
	for(new i = 0; i < 20; i++) SendDeathMessage(6000, 5005, 255);
	return 1;
}

CMD:saveallstats(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 4);

	new string[128];

    format(string, sizeof string, "** Admin %s has saved all player's stats.", pName(playerid));
	SendClientMessageToAll(COLOR_ADMIN, string);
	
	foreach(new i : Player)
	{
		SaveData(i);
	}

	format(string, sizeof string, "Admin %s has  saved all player's stats.", pName(playerid));
	SaveLog("account.txt", string);
	return 1;
}

CMD:giveallweapon(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 4);

	new ammo, wID[32], weap, WeapName[32], string[128];
	
	if(sscanf(params, "s[32]i", wID, ammo)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /giveallweapon [weaponid(or name)] [ammo]");

	if(ammo <= 0 || ammo > 99999) ammo = 500;
	if(!isnumeric(wID)) weap = GetWeaponIDFromName(wID);
	else weap = strval(wID);
	
	if(!IsValidWeapon(weap)) 
		return SendClientMessage(playerid, COLOR_RED, "* Invalid Weapon ID");
		
	GetWeaponName(weap, WeapName, 32);
   	foreach(new i : Player)
	{
		if(i != playerid && User[playerid][accountAdmin] > User[i][accountAdmin])
		{
			GivePlayerWeapon(i, weap, ammo);
			format(string, sizeof string, "~g~%s for all!", WeapName);
			GameTextForPlayer(i, string, 2500, 3);
		}
	}
	
	format(string,sizeof(string), "** Admin %s has given everyone a %s(%d).", pName(playerid), WeapName, weap);
	SendClientMessageToAll(COLOR_ADMIN, string);
	return 1;
}

//============================================================================//
//						   Administrative Level Five                          //
//============================================================================//

CMD:rcons(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 5);

	static string[128 * 10];
	string[0] = 0;
	new count = 0;
	
	foreach(new i : Player)
	{
	    if(IsPlayerAdmin(i))
	    {
			format(string, sizeof(string), "%s"white"(%d) %s - (%s)\n", string, i, pName(i), User[i][accountIP]);
			count++;
	    }
	}
	
	if(!count)
		return SendClientMessage(playerid, -1, "No RCON admins online at the server.");
		
	Dialog_Show(playerid, DIALOG_BEGIN, DIALOG_STYLE_MSGBOX, "RCONs", string, "CLOSE", "");
	return 1;
}

CMD:createaccount(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 5);
	
	new name[24], password[20], hash[129], DBResult:result, query[128 * 3];
    //Time = Hours, Time2 = Minutes, Time3 = Seconds
    new time, time2, time3;
    gettime(time, time2, time3);
    new date, date2, date3;
    //Date = Month, Date2 = Day, Date3 = Year
    getdate(date3, date, date2);
	
	if(sscanf(params, "s[24]s[20]", name, password))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /createaccount [name] [password]");
		
	if(strlen(name) < 5 || strlen(name) > 20)
		return SendClientMessage(playerid, COLOR_RED, "* Account Name's length must be more than five but can't be above twenty.");

	if(strlen(password) < 4 || strlen(password) > 20)
		return SendClientMessage(playerid, COLOR_RED, "* Password length must be more than four but can't be above twenty.");

	format(query, sizeof(query), "SELECT * FROM `users` WHERE `username` = '%s'", DB_Escape(name));
	result = db_query(Database, query);
	
	if(!db_num_rows(result))
	{
		WP_Hash(hash, sizeof(hash), password);	

		format(query, sizeof(query),
			"INSERT INTO `users` (`username`, `IP`, `joindate`, `password`, `score`, `money`) VALUES ('%s', '255.255.255.255', '%02d/%02d/%d %02d:%02d:%02d', '%s', %d, %d)",\
				DB_Escape(name),
				date, date2, date3, time, time2, time3,
				DB_Escape(hash),
				STARTING_SCORE,
				STARTING_CASH
		);
		db_query(Database, query);

		format(query, sizeof(query), "* You have successfully created an account under the name '%s' with password '%s'", name, password);
		SendClientMessage(playerid, COLOR_GREEN, query);
		
		printf("[ACCOUNT] %s (IP: %s) has created a new account name '%s' (/createaccount)", pName(playerid), User[playerid][accountIP], name);
	}
	else
	{
	    format(query, sizeof(query), "* '%s' is taken.", name);
	    SendClientMessage(playerid, COLOR_RED, query);
	}
	db_free_result(result);		
	return 1;
}

CMD:setaccount(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 5);
	
	new name[24], DBResult:result, query[128 * 3], type[32], optional[128];
	
	if(sscanf(params, "s[24]s[32]S()[128]", name, type, optional))
	{
		SendClientMessage(playerid, COLOR_RED, "USAGE: /setaccount [name] [type] (optional)");
		SendClientMessage(playerid, COLOR_YELLOW, "Types: Admin, Name");		
		return 1;
	}

	new id = ReturnUser(name);
	
	format(query, sizeof(query), "SELECT * FROM `users` WHERE `username` = '%s'", DB_Escape(name));
	result = db_query(Database, query);
	
	if(db_num_rows(result))
	{
		if(!strcmp(type, "admin", true))
		{
			new level;
			if(sscanf(optional, "d", level))
				return SendClientMessage(playerid, COLOR_RED, "USAGE: /setaccount [name] admin [0-5]");
				
			if(level < 0 || level > 5)
				return SendClientMessage(playerid, COLOR_RED, "* Admin Level can't be below zero and can't be above five.");

			if(IsPlayerConnected(id))
			{
				format(query, sizeof(query), "* '%s' is in game, use /setlevel %d instead.", name, id);
				return SendClientMessage(playerid, COLOR_RED, query);
			}				
				
			format(query, sizeof(query), "UPDATE `users` SET `admin` = %d WHERE `username` = '%s'", level, DB_Escape(name));
			db_query(Database, query);
			
			format(query, sizeof(query), "* You have set %s's Admin level to %d. (/setaccount)", name, level);
			SendClientMessage(playerid, COLOR_GREEN, query);
		
			printf("[ACCOUNT] %s (IP: %s) has set %s's admin level to %d. (/setaccount)", pName(playerid), User[playerid][accountIP], name, level);	
		}
		else if(!strcmp(type, "name", true))
		{
			new str[24];
			if(sscanf(optional, "s[24]", str))
				return SendClientMessage(playerid, COLOR_RED, "USAGE: /setaccount [name] name [new name]");
				
			if(strlen(str) < 5 || strlen(str) > 20)
				return SendClientMessage(playerid, COLOR_RED, "* Name Length can't be below five and can't be above twenty.");

			if(IsPlayerConnected(id))
			{
				format(query, sizeof(query), "* '%s' is in game, use /setname %d instead.", name, id);
				return SendClientMessage(playerid, COLOR_RED, query);
			}				
				
			format(query, sizeof(query), "UPDATE `users` SET `username` = '%s' WHERE `username` = '%s'", DB_Escape(str), DB_Escape(name));
			db_query(Database, query);
			
			format(query, sizeof(query), "* You have set %s's name to %s. (/setaccount)", name, str);
			SendClientMessage(playerid, COLOR_GREEN, query);
		
			printf("[ACCOUNT] %s (IP: %s) has set %s's name to %s. (/setaccount)", pName(playerid), User[playerid][accountIP], name, str);	
		}
		else
		{
			SendClientMessage(playerid, COLOR_RED, "* Invalid type.");
		}
	}
	else
	{
	    format(query, sizeof(query), "* '%s' doesn't exist.", name);
	    SendClientMessage(playerid, COLOR_RED, query);
	}
	db_free_result(result);		
	return 1;
}

CMD:makemegodadmin(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) 
		return SendClientMessage(playerid, COLOR_RED, "* Only RCON can use this command.");

	User[playerid][accountAdmin] = 5;
	SendClientMessage(playerid, COLOR_ADMIN, "You have set your administrative rank to level 5.");
	return 1;
}

CMD:removeaccount(playerid, params[])
{
	LoginCheck(playerid);
    LevelCheck(playerid, 5);

    new
		Account[MAX_PLAYER_NAME],
		Reason[100],
		string[128]
	;
    if(sscanf(params, "s[24]s[100]", Account, Reason)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /removeacc [account name] [reason]");
		
    if(DataExist(Account))
	{
	    if(!strcmp(pName(playerid), Account, false))
			return SendClientMessage(playerid, COLOR_RED, "* You cannot delete your own account!");

		foreach(new i : Player)
		{
		    if(strcmp(Account, pName(i), true) == 0)
		    {
		        SendClientMessage(playerid, COLOR_RED, "* Player is online, fail to delete the account.");
		        return 1;
		    }
		}

		new Query[128];
	    format(Query, sizeof(Query), "DELETE FROM `users` WHERE `username` = '%s'", Account);
		db_query(Database, Query);

		format(string, sizeof(string), "Admin %s(ID: %d) has deleted %s's account [Reason: %s]", pName(playerid), playerid, Account, Reason);
		SendClientMessageToAll(COLOR_YELLOW, string);
		SaveLog("account.txt", string);

		format(string, sizeof(string), "You have deleted %s's account [Reason: %s]", Account, Reason);
		SendClientMessage(playerid, COLOR_YELLOW, string);
	}
	else
	{
	    SendClientMessage(playerid, COLOR_RED, "* Account does not exist in the database!");
	}
    return 1;
}

CMD:fakecmd(playerid, params[])
{
	new string[128], id, cmdtext[128];

	LoginCheck(playerid);
	LevelCheck(playerid, 5);

	if(sscanf(params, "us[128]", id, cmdtext)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /fakecmd [playerid] [command]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
	if(strfind(params, "/", false) != -1)
	{
        CallRemoteFunction("OnPlayerCommandText", "is", id, cmdtext);
	    format(string, sizeof(string), "Fake command sent to %s with %s", pName(id), cmdtext);
	    SendClientMessage(playerid, COLOR_YELLOW, string);
	}
	else return SendClientMessage(playerid, COLOR_RED, "* Add '/' before putting the command name to avoid the command unknown error.");
	return 1;
} 

CMD:fakechat(playerid, params[])
{
	LoginCheck(playerid);
	LevelCheck(playerid, 5);

	new
		string[128],
		id,
		text[128]
	;

	if(sscanf(params, "us[128]", id, text)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /fakechat [playerid] [text]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
	format(string, sizeof(string), "You have faked chat %s with %s", pName(id), text);
    SendClientMessage(playerid, COLOR_YELLOW, string);
	SendPlayerMessageToAll(id, text);
	return 1;
}

CMD:settemplevel(playerid, params[])
{
	new string[128], id, level;

	LoginCheck(playerid);
 	LevelCheck(playerid, 5);

	if(sscanf(params, "ui", id, level)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /settemplevel [playerid] [level(0/5)]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
	if(level < 0 || level > 5) return SendClientMessage(playerid, COLOR_RED, "* Levels shouldn't go below zero and shouldn't go above five.");
	if(level == User[id][accountAdmin]) return SendClientMessage(playerid, COLOR_RED, "* Player is already in that level.");
	if(User[id][accountLogged] == 0) return SendClientMessage(playerid, COLOR_RED, "* Player not logged in.");

    if(User[id][accountAdmin] < level)
    {
        format(string, 128, "You have been temporarily-promoted to level %d by %s.", level, pName(playerid));
		SendClientMessage(id, COLOR_YELLOW, string);
		format(string, 128, "You have temporarily-promoted %s to level %d.", pName(id), level);
		SendClientMessage(playerid, COLOR_YELLOW, string);
		format(string, 128, "You will be promoted back to your old level which is (%d) once you logout.", User[id][accountAdmin]);
		SendClientMessage(id, COLOR_GREEN, string);
    }
    else if(User[id][accountAdmin] > level)
    {
        format(string, 128, "You have been temporarily-demoted to level %d by %s.", level, pName(playerid));
		SendClientMessage(id, COLOR_YELLOW, string);
		format(string, 128, "You have temporarily-demoted %s to level %d.", pName(id), level);
		SendClientMessage(playerid, COLOR_YELLOW, string);
		format(string, 128, "You will be promoted back to your old level which is (%d) once you logout.", User[id][accountAdmin]);
		SendClientMessage(id, COLOR_GREEN, string);
     }

	User[id][accountTemporary] = true;
	User[id][accountAdminEx] = User[id][accountAdmin];
    User[id][accountAdmin] = level;
	
	if(level > 0) 
	{
		if(!IsValidDynamic3DTextLabel(User[id][accountLabel])) 
			User[id][accountLabel] = CreateDynamic3DTextLabel("_", -1, 0, 0, 0.30, 25, id, .testlos = 1);	
	
		UpdateDynamic3DTextLabelText(User[id][accountLabel], 0xFF0000FF, GetAdminRank(level));
	} 
	else
	{
		DestroyDynamic3DTextLabel(User[id][accountLabel]);	
	}

	format(string, sizeof string, "Admin %s has set %s's administrative level to %d", pName(playerid), pName(id), level);
	SaveLog("account.txt", string);

	SaveData(id); //Saving the whole data
	return 1;
}

CMD:setlevel(playerid, params[])
{
	new string[128], id, level;

	LoginCheck(playerid);
 	LevelCheck(playerid, 5);

	if(sscanf(params, "ui", id, level)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /setlevel [playerid] [level(0/5)]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
	if(level < 0 || level > 5) return SendClientMessage(playerid, COLOR_RED, "* Levels shouldn't go below zero and shouldn't go above five.");
	if(level == User[id][accountAdmin]) return SendClientMessage(playerid, COLOR_RED, "* Player is already in that level.");
	if(User[id][accountLogged] == 0) return SendClientMessage(playerid, COLOR_RED, "* Player not logged in.");

    if(User[id][accountAdmin] < level)
    {
        format(string, 128, "You have been promoted to level %d by %s.", level, pName(playerid));
		SendClientMessage(id, COLOR_YELLOW, string);
		format(string, 128, "You have promoted %s to level %d.", pName(id), level);
		SendClientMessage(playerid, COLOR_YELLOW, string);
    }
    else if(User[id][accountAdmin] > level)
    {
        format(string, 128, "You have been demoted to level %d by %s.", level, pName(playerid));
		SendClientMessage(id, COLOR_YELLOW, string);
		format(string, 128, "You have demoted %s to level %d.", pName(id), level);
		SendClientMessage(playerid, COLOR_YELLOW, string);
    }

	if(User[id][accountTemporary])
	{
	    SendClientMessage(playerid, -1, "The effect of /settemplevel has been removed since you used /setlevel on this player.");
	}
	User[id][accountTemporary] = false;
	User[id][accountAdminEx] = 0;
    User[id][accountAdmin] = level;

	format(string, sizeof string, "Admin %s has set %s's administrative level to %d", pName(playerid), pName(id), level);
	SaveLog("account.txt", string);

	if(level > 0) 
	{
		if(!IsValidDynamic3DTextLabel(User[id][accountLabel])) 
			User[id][accountLabel] = CreateDynamic3DTextLabel("_", -1, 0, 0, 0.30, 25, id, .testlos = 1);	
	
		UpdateDynamic3DTextLabelText(User[id][accountLabel], 0xFF0000FF, GetAdminRank(level));
	} 
	else 
	{
		DestroyDynamic3DTextLabel(User[id][accountLabel]);	
	}

	SaveData(id); //Saving the whole data
	return 1;
}

//============================================================================//
//						   Administrative Level Zero                          //
//============================================================================//

CMD:id(playerid, params[])
{
	new name[MAX_PLAYER_NAME], string[128], count;
	
	if (sscanf(params, "s[24]", name))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /id [name]");

	foreach(new i : Player)
	{
		if(strfind(ReturnPlayerName(i), name, true) != -1)
		{
			format(string, sizeof (string), "%i. %s (ID: %d)", ++count, pName(i), i);
			SendClientMessage(playerid, COLOR_ADMIN, string);
		}
	}

	if(!count)
		return SendClientMessage(playerid, COLOR_RED, "** No match found.");
	return 1;
}

CMD:getid(playerid, params[]) return cmd_id(playerid, params);

CMD:admins(playerid, params[])
{
	new count = 0, count2 = 0;
	
	#if defined USE_DIALOG
	static string[128 * 10];
	string[0] = 0;
	
	foreach(new i : Player)
	{
	    if(User[i][accountLogged] && User[i][accountAdmin] >= 1)
	    {
			if(!User[i][accountHide])
			{
				count++;
				format(string, sizeof(string), "%s"white"(%d) %s - %s %s\n", string, i, pName(i), GetAdminRank(User[i][accountAdmin]), (User[i][accountDuty]) ? (""green"(ADMIN DUTY)") : (""red"(PLAYING)"));
			}
			else count2++;
	    }
	}
	
	if(!count)
		return SendClientMessage(playerid, -1, "No Admins online at the server.");
		
	Dialog_Show(playerid, DIALOG_BEGIN, DIALOG_STYLE_MSGBOX, "ADMINs", string, "CLOSE", "");
	#else
	static string[128];
	string[0] = 0;
	
	SendClientMessage(playerid, COLOR_GREEN, "Administrators Online:");
	foreach(new i : Player)
	{
	    if(User[i][accountLogged] && User[i][accountAdmin] >= 1)
	    {
			if(!User[i][accountHide])
			{
				format(string, sizeof(string), "(%d) %s - %s %s\n", i, pName(i), GetAdminRank(User[i][accountAdmin]), (User[i][accountDuty]) ? (""green"(ADMIN DUTY)") : (""red"(PLAYING)"));
				SendClientMessage(playerid, -1, string);
			}
			else count2++;
			count++;
	    }
	}
	
	if(!count)
		return SendClientMessage(playerid, -1, "No Admins online at the server.");
	#endif
	return 1;
}

CMD:jcredits(playerid, params[])
{
	SendClientMessage(playerid, COLOR_GREEN, "JaKe's Administration System "VERSION" Credits to:");
	SendClientMessage(playerid, -1, "Jake_Hero, Y_Less, Zeex, Zher0, Lordzy, denNorske, Emmet_");
	SendClientMessage(playerid, COLOR_YELLOW, "{FF80FF}MillyTheQueen{FFFF00}, NotDunn, Kizuna, YaBoiJeff (Sean), Pavintharan, Uberanwar");
	SendClientMessage(playerid, COLOR_YELLOW, "Ranveer, Samp_India, Ashirwad, Sonic, Adham, MaxFranky and others who helped us.");
	return 1;
}

CMD:savestats(playerid, params[])
{
	LoginCheck(playerid);

	if(!DataExist(pName(playerid))) return SendClientMessage(playerid, COLOR_RED, "* You do not have account.");

	SaveData(playerid);
	
	SendClientMessage(playerid, COLOR_GREEN, "ACCOUNT: Your account statistics has been saved manually.");
	return 1;
}

CMD:cquestion(playerid, params[])
{
	LoginCheck(playerid);

	static hashpass[129];
	hashpass[0] = 0;
	
	if(isnull(params))
	    return SendClientMessage(playerid, COLOR_YELLOW, "* Input your password first before changing the security question, /cquestion [password]");

	WP_Hash(hashpass, sizeof(hashpass), params);
    if(!strcmp(hashpass, User[playerid][accountPassword], false))
	{
	    SendClientMessage(playerid, COLOR_GREEN, "* You are the owner of this account, You may pass through.");
		Dialog_Show(playerid, DIALOG_QUESTION2, DIALOG_STYLE_INPUT, ""green"Security Question", ""grey"* Type in your new security question below;", "Set", "Cancel");
	}
	else
	{
	    format(hashpass, sizeof(hashpass), "* %s isn't the password.", params);
	    SendClientMessage(playerid, COLOR_YELLOW, hashpass);
	}
	return 1;
}

CMD:togpm(playerid, params[])
{
	switch(User[playerid][accountPM])
	{
		case false:
		{
			SendClientMessage(playerid, COLOR_GREEN, "* You have togged on your private messages (You can now receive /pm's)");
			User[playerid][accountPM] = 1;
		}
		case true:
		{
			SendClientMessage(playerid, COLOR_RED, "* You have togged off your private messages (You won't receive /pm's)");
			User[playerid][accountPM] = 0;
		}
	}
	SaveData(playerid);
	return 1;
}

CMD:pm(playerid, params[])
{
	LoginCheck(playerid);

	new string[128], message[128], id;

	if (!User[playerid][accountPM])
		return SendClientMessage(playerid, COLOR_RED, "* You have your PM togged.");
		
	if (sscanf(params, "us[128]", id, message))
	    return SendClientMessage(playerid, COLOR_RED, "USAGE: /pm [playerid] [text]");

	if (id == INVALID_PLAYER_ID)
	    return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
	    
	if (!User[id][accountPM])
		return SendClientMessage(playerid, COLOR_RED, "* That player has their PM togged.");

	PlayerPlaySound(playerid, 1085, 0.0, 0.0, 0.0);
	PlayerPlaySound(id, 1085, 0.0, 0.0, 0.0);
	
	format(string, sizeof(string), "* PM Sent to %s (ID: %d): %s", pName(id), id, message);
	SendClientMessage(playerid, 0x9ACD32AA, string);
	format(string, sizeof(string), "* PM From %s (ID: %d): %s", pName(playerid), playerid, message);
	SendClientMessage(id, 0x9ACD32AA, string);
	
	CallRemoteFunction("OnPlayerPrivMessage", "dds", playerid, id, message);

	if(ServerInfo[ReadPMs])
	{
		format(string, sizeof(string), "[PM] %s > %s: %s", pName(playerid), pName(id), message);
		printf("[PM] %s > %s: %s", pName(playerid), pName(id), message);
		foreach(new i : Player)
		{
			if(User[playerid][accountAdmin] > User[i][accountAdmin])
			{
				SendClientMessage(i, COLOR_GREEN, string);	
			}
		}
	}
	return 1;
}

CMD:givechocolate(playerid, params[])
{
	LoginCheck(playerid);

	new string[128], id, amount;
	
	if (sscanf(params, "ud", id, amount))
	    return SendClientMessage(playerid, COLOR_RED, "USAGE: /givechocolate [playerid] [amount]");

	if (id == INVALID_PLAYER_ID)
	    return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

	if (id == playerid)
	    return SendClientMessage(playerid, COLOR_RED, "* You cannot give yourself a Chocolate.");
	    
	if (amount < 1 || amount > User[playerid][accountChocolate])
	    return SendClientMessage(playerid, COLOR_RED, "* You cannot give below ZERO chocolates/or you don't have that much on you.");

	User[playerid][accountChocolate] -= amount;
	User[id][accountChocolate] += amount;

	format(string, sizeof(string), "* You have received %d chocolate bars from %s - You have now %d chocolate bars.", amount, pName(playerid), User[id][accountChocolate]);
	SendClientMessage(id, COLOR_GREEN, string);
	format(string, sizeof(string), "* You have given %d chocolate bars to %s - You have now %d chocolate bars.", amount, pName(id), User[playerid][accountChocolate]);
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:jcmds(playerid, params[])
{
	static string[1246];
	string[0] = 0;

	LoginCheck(playerid);

	strcat(string, ""green"");
	strcat(string, "Listing all available commands of JakAdmin 4.0\n\n");

	strcat(string, ""grey"");
	strcat(string, "/stats /cpass /register /login /report /admins /jcredits /savestats /cquestion\n");
	strcat(string, "/votekick (/yes /no) /givechocolate /pm /togpm /id (getid)");

	Dialog_Show(playerid, DIALOG_BEGIN, DIALOG_STYLE_MSGBOX, ""green"Player Commands", string, "Close", "");
	return 1;
}

CMD:yes(playerid, params[])
{
	static string[128];
	string[0] = 0;
	
	if(!VoteKickHappening)
		return SendClientMessage(playerid, COLOR_RED, "* There is no vote-kick happening right now.");
		
    if(HasAlreadyVoted{playerid}) 
        return SendClientMessage(playerid, COLOR_RED, "* You have already voted!");

	svotes++; 
	HasAlreadyVoted{playerid} = true;

    if(svotes < MaxVKICK) 
    {
		format(string, sizeof(string), "VOTEKICK: %s has voted YES on getting %s kicked for %s. (%d/%d)", pName(playerid), pName(VoteKickTarget), VoteKickReason, svotes, MaxVKICK);
		SendClientMessageToAll(COLOR_GREEN, string); 
		SaveLog("votekick.txt", string);
	}
	else if(svotes >= MaxVKICK)
	{
		format(string, sizeof(string), "VOTEKICK: The vote is a success and %s was kicked for %s.", pName(VoteKickTarget), VoteKickReason);
		SendClientMessageToAll(COLOR_ORANGE, string); 
		SaveLog("votekick.txt", string);

		KickDelay(VoteKickTarget);

		format(VoteKickReason, sizeof(VoteKickReason), "None");
		VoteKickHappening = 0;
		avotes = 0;
		svotes = 0;
		VoteKickTarget = INVALID_PLAYER_ID;
		KillTimer(VoteTimer);
		//////////////////////
		foreach(new i : Player)
		{
			HasAlreadyVoted{i} = false;
		}
	}
	return 1;
}

CMD:no(playerid, params[])
{
	static string[128];
	string[0] = 0;

	if(!VoteKickHappening)
		return SendClientMessage(playerid, COLOR_RED, "* There is no vote-kick happening right now.");

    if(HasAlreadyVoted{playerid})
        return SendClientMessage(playerid, COLOR_RED, "* You have already voted!");

	if(avotes < MaxVKICK)
	{
	    if(!avotes)
	        return SendClientMessage(playerid, COLOR_RED, "* There aren't any players voting 'YES' on this vote-kick!");

	    avotes++;
	    svotes--;
	    HasAlreadyVoted{playerid} = true;
		format(string, sizeof(string), "VOTEKICK: %s has voted NO on getting %s kicked for %s. (%d/%d)", pName(playerid), pName(VoteKickTarget), VoteKickReason, svotes, MaxVKICK);
		SendClientMessageToAll(COLOR_GREEN, string);
		SaveLog("votekick.txt", string);
	}
	else if (avotes >= MaxVKICK)
	{
		format(string, sizeof(string), "VOTEKICK: The vote is a FAILURE and %s stays.", pName(VoteKickTarget));
		SendClientMessageToAll(COLOR_ORANGE, string);
		SaveLog("votekick.txt", string);

		format(VoteKickReason, sizeof(VoteKickReason), "None");
		VoteKickHappening = 0;
		avotes = 0;
		svotes = 0;
		VoteKickTarget = INVALID_PLAYER_ID;
		KillTimer(VoteTimer);
		//////////////////////
		foreach(new i : Player)
		{
			HasAlreadyVoted{i} = false;
		}
	}
	return 1;
}

CMD:votekick(playerid, params[])
{
    new count = 0, id, string[133], reason[64];

	if(User[playerid][accountAdmin])
	    return SendClientMessage(playerid, COLOR_RED, "* You are an admin, you can use your powers!");

	if(GetPlayerPoolSize() < 3)
	    return SendClientMessage(playerid, COLOR_RED, "* There needs to be 2 other players to use this command.");

	if(VoteKickHappening)
	    return SendClientMessage(playerid, COLOR_RED, "* There is a vote already happening, please wait for it to end!");

	if(sscanf(params, "us[64]", id, reason))
	    return SendClientMessage(playerid, COLOR_RED, "USAGE: /votekick [playerid] [reason]");

	if(id == INVALID_PLAYER_ID)
	    return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

	if(id == playerid)
	    return SendClientMessage(playerid, COLOR_RED, "* You cannot vote kick yourself.");

	foreach(new i : Player) if(User[i][accountAdmin] >= 1)
	{
		count++;
	}
	
	if(count)
	{
		format(string, sizeof(string), "* There are %d admins online, Admins has been notified about your vote-kick.", count);
		SendClientMessage(playerid, -1, string);
		format(string, sizeof(string), "[VOTE-KICK] Player %s wants to vote kick %s (ID: %d) for %s.", pName(playerid), pName(id), reason);
		SendAdmin(COLOR_YELLOW, string);
		SaveLog("votekick.txt", string);
	}
	else 
	{
		format(string, sizeof(string), "[VOTEKICK] %s has started a vote on getting %s kicked (%s).", pName(playerid), pName(id), reason); 
		SendClientMessageToAll(COLOR_RED, string);
		SaveLog("votekick.txt", string);
		format(string, sizeof(string), "** /yes or /no to vote | Vote Kick Limit: %d | Results to be released in: %d seconds", MaxVKICK);
		SendClientMessageToAll(COLOR_YELLOW, string); 
		format(VoteKickReason, sizeof(VoteKickReason), reason);
		VoteKickTarget = id;
		VoteKickHappening = 1; 
		VoteTimer = SetTimer("EndVoteKick", KickTime*1000, false);
	}
	return 1;
}

CMD:report(playerid, params[])
{
	// Report has been re-worked on (01/27/17)

	new id, reason[128];

	if(User[playerid][accountAdmin] > 0)
	    return SendClientMessage(playerid, COLOR_RED, "* You are already an admin, No need to /report.");

	for(new c; c < MAX_REPORTS; c++)
	{
	    if(rInfo[c][reportTaken])
	    {
	        if(rInfo[c][reporterID] == playerid)
	        {
	            if(rInfo[c][reportAccepted] == INVALID_PLAYER_ID)
	            {
		            format(reason, sizeof(reason), "* You have already reported someone earlier (%s (%s) - RID %d), The report is not being handled by anyone yet.", pName(rInfo[c][reportedID]), rInfo[c][reportReason], c);
		            SendClientMessage(playerid, COLOR_YELLOW, reason);
		            SendClientMessage(playerid, -1, "* /closereport to close your report.");
				}
				else
				{
		            format(reason, sizeof(reason), "* You have already reported someone (%s (%s) - RID %d), The report is being handled by %s.", pName(rInfo[c][reportedID]), rInfo[c][reportReason], c, pName(rInfo[c][reportAccepted]));
		            SendClientMessage(playerid, COLOR_YELLOW, reason);
		            SendClientMessage(playerid, -1, "* Ask an admin to end your report if you wanted to end it.");
				}
				return 1;
	        }
	    }
	}
	
	if(sscanf(params, "us[128]", id, reason))
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /report [playerid] [reason]");
		
	if(strlen(reason) < 4 || strlen(reason) > 64)
		return SendClientMessage(playerid, COLOR_RED, "* Reason length shouldn't go lower than four and higher than sixty four.");
		
	if(id == INVALID_PLAYER_ID)
		return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

	if(id == playerid)
 		return SendClientMessage(playerid, COLOR_RED, "* You cannot report yourself.");
 		
	if(User[playerid][accountAdmin] < User[id][accountAdmin])
		return SendClientMessage(playerid, COLOR_RED, "* You cannot report an admin.");

	InsertReport(playerid, id, reason);
	return 1;
}

CMD:closereport(playerid, params[])
{
	static string[128];
	string[0] = 0;
	
	for(new c; c < MAX_REPORTS; c++)
	{
	    if(rInfo[c][reportTaken])
	    {
	        if(rInfo[c][reporterID] == playerid)
	        {
				if(rInfo[c][reportAccepted] != INVALID_PLAYER_ID)
				    return SendClientMessage(playerid, COLOR_RED, "** Your report is already being handled by an admin, too late to close it now.");
				    
				format(string, sizeof(string), "[Report] %s has decided to cancel their report against %s [Report ID: %d].", pName(playerid), pName(rInfo[c][reportedID]), c);
				SendAdmin(COLOR_GREEN, string);
				
				ResetReport(c);
				return 1;
	        }
	    }
	}
	SendClientMessage(playerid, -1, "* You aren't reporting someone.");
	return 1;
}

CMD:reporttalk(playerid, params[])
{
	static string[128];
	string[0] = 0;
	
	if(isnull(params))
	    return SendClientMessage(playerid, COLOR_RED, "USAGE: /reporttalk [message]");
	
	if(User[playerid][accountAdmin] >= 1)
	{
		for(new i; i < MAX_REPORTS; i++)
		{
		    if(rInfo[i][reportTaken] && rInfo[i][reporterID] == playerid && rInfo[i][reportAccepted] != INVALID_PLAYER_ID)
		    {
		        format(string, sizeof(string), "* To Admin %s: %s", pName(rInfo[i][reportAccepted]), params);
		        SendClientMessage(playerid, -1, string);
		        format(string, sizeof(string), "* %s said: %s", pName(playerid), params);
		        SendClientMessage(rInfo[i][reportAccepted], -1, string);
		        return 1;
		    }
		    if(rInfo[i][reportTaken] && rInfo[i][reportAccepted] == playerid)
		    {
		        format(string, sizeof(string), "* Talking to %s: %s", pName(rInfo[i][reporterID]), params);
		        SendClientMessage(playerid, -1, string);
		        format(string, sizeof(string), "* %s to you: %s", pName(playerid), params);
		        SendClientMessage(rInfo[i][reporterID], -1, string);
		        return 1;
		    }
		}
		SendClientMessage(playerid, -1, "* You aren't handling any report.");
	}
	else
	{
		for(new i; i < MAX_REPORTS; i++)
		{
		    if(rInfo[i][reportTaken] && rInfo[i][reporterID] == playerid && rInfo[i][reportAccepted] != INVALID_PLAYER_ID)
		    {
		        format(string, sizeof(string), "* To Admin %s: %s", pName(rInfo[i][reportAccepted]), params);
		        SendClientMessage(playerid, -1, string);
		        format(string, sizeof(string), "* %s said: %s", pName(playerid), params);
		        SendClientMessage(rInfo[i][reportAccepted], -1, string);
		        return 1;
		    }
		}
		SendClientMessage(playerid, -1, "* You haven't reported someone or the report isn't accepted by an admin yet.");
	}
	return 1;
}

CMD:register(playerid, params[])
{
	if(User[playerid][accountLogged] == 1) return SendClientMessage(playerid, COLOR_RED, "* You are logged in and registered already.");

	if(!DataExist(pName(playerid)))
	{
        new string[128], password[24], hashpass[129], oldname[24];

		if(sscanf(params, "s[24]", password)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /register [password]");
        if(!IsValidPassword(password)) return SendClientMessage(playerid, COLOR_RED, "* Invalid Password Symbols.");
        if(strlen(password) < 4 || strlen(password) > 20) return SendClientMessage(playerid, COLOR_RED, "* Password length shouldn't go below 4 and shouldn't go higher 20.");

		GetPVarString(playerid, "old_name", oldname, sizeof(oldname));
		if(!isnull(oldname))
		{
			SetPlayerName(playerid, oldname);
		    format(string, sizeof(string), "* Your name has been reverted back to %s since you registered.", pName(playerid));
		    SendClientMessage(playerid, -1, string);
		}

        WP_Hash(hashpass, 129, password);
		RegisterPlayer(playerid, hashpass);
	}
	else
	{
	    SendClientMessage(playerid, COLOR_RED, "* You already have an account, /login instead.");
	}
	return 1;
}

CMD:login(playerid, params[])
{
	if(User[playerid][accountLogged] == 1) return SendClientMessage(playerid, COLOR_RED, "* You are logged in already.");

	if(DataExist(pName(playerid)))
	{
		static string[900];
		string[0] = 0;
		new hashp[129], password[24];
		
		if(sscanf(params, "s[24]", password)) return SendClientMessage(playerid, COLOR_RED, "USAGE: /login [password]");

		if(strcmp(password, "forget", true) == 0)
		{
			if(strcmp(User[playerid][accountQuestion], "none", true) == 0)
			    return SendClientMessage(playerid, COLOR_RED, "* You haven't set a security question & answer on your account.");

		    format(string, sizeof(string), "You have forgotten your password? If that's the case, answer the question you set on your account and you'll access your account.\n\n%s\n\nAnswer?\nPress Quit if you are willing to quit.", User[playerid][accountQuestion]);
			Dialog_Show(playerid, DIALOG_FORGET, DIALOG_STYLE_INPUT, ""green"Security Question", string, "Answer", "Quit");
		    return 1;
		}

	    WP_Hash(hashp, 129, password);
	    if(!strcmp(hashp, User[playerid][accountPassword], false))
	    {
	        LoginPlayer(playerid);
	    }
	    else
	    {
	        User[playerid][WarnLog]++;

	        if(User[playerid][WarnLog] >= ServerInfo[LoginWarn])
	        {
				Dialog_Show(playerid, DIALOG_BEGIN, DIALOG_STYLE_MSGBOX, ""lightblue"Kicked", ""grey"You have been kicked from the server having too much wrong passwords!\nTry again, Reconnect (/q then join to the server again.)", "Close", "");
				KickDelay(playerid);
				return 1;
	        }

	        format(string, sizeof(string), "Invalid password! - %d out of %d Warning Log Tires.", User[playerid][WarnLog], ServerInfo[LoginWarn]);
	        SendClientMessage(playerid, COLOR_RED, string);
			SendClientMessage(playerid, -1, "LOGIN: Try again, /login [password].");
	    }
	}
	else
	{
	    SendClientMessage(playerid, COLOR_RED, "* You do not have an account, /register first.");
	}
	return 1;
}

CMD:cpass(playerid, params[])
{
    LoginCheck(playerid);

	new OldPass[24], NewPass[24], string[128];
	
    if(sscanf(params, "s[24]s[24]", OldPass, NewPass)) 
		return SendClientMessage(playerid, COLOR_RED, "USAGE: /cpass [old pass] [new pass]");
		
    if(strlen(NewPass) < 4 || strlen(NewPass) > 20)
        return SendClientMessage(playerid, COLOR_RED, "* New password length shouldn't go below four and shouldn't go below twenty.");

    new Query[300], DBResult:Result, Buf[129];
    WP_Hash(Buf, 129, OldPass);
    format(Query, 300, "SELECT `userid` FROM `users` WHERE `username` = '%s' AND `password` = '%s'", DB_Escape(User[playerid][accountName]), Buf);
    Result = db_query(Database, Query);

	format(string, sizeof string, "Player %s has changed their password.", pName(playerid));
	SaveLog("account.txt", string);

    if(db_num_rows(Result))
    {
        WP_Hash(Buf, 129, NewPass);
        format(User[playerid][accountPassword], 129, Buf);
        format(Query, 300, "UPDATE `users` SET `password` = '%s' WHERE `username` = '%s'", DB_Escape(Buf), DB_Escape(User[playerid][accountName]));
		db_query(Database, Query);

		format(string, 128, "Your password has been changed to '"green"%s"white"'", NewPass);
		SendClientMessage(playerid, -1, string);
	}
	else SendClientMessage(playerid, COLOR_RED, "* Old Password doesn't match on the current password!");
	db_free_result(Result);
	return 1;
}

CMD:stats(playerid, params[])
{
	LoginCheck(playerid);
	
	new id;
	if(!sscanf(params, "u", id))
	{
	    LevelCheck(playerid, 1);
	
		if(id == INVALID_PLAYER_ID)
			return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

		if(User[playerid][accountAdmin] < User[id][accountAdmin])
			return SendClientMessage(playerid, COLOR_RED, "* You cannot use this command on higher admin.");

		ShowStatistics(playerid, id);
	}
	else
	{
		ShowStatistics(playerid, playerid); //Show the statistics to yourself.
		if(User[playerid][accountAdmin]) SendClientMessage(playerid, COLOR_RED, "USAGE: /stats [playerid]");
	}
	return 1;
}

//                                                                            //
//============================================================================//

public OnPlayerStateChange(playerid, newstate, oldstate)
{
    new vehicleid = GetPlayerVehicleID(playerid);

	if(oldstate == PLAYER_STATE_DRIVER || oldstate == PLAYER_STATE_PASSENGER)
	{
		foreach(new x : Player)
		{
	    	if(GetPlayerState(x) == PLAYER_STATE_SPECTATING && User[x][SpecID] == playerid && User[x][SpecType] == ADMIN_SPEC_TYPE_VEHICLE)
			{
	        	TogglePlayerSpectating(x, 1);
		        PlayerSpectatePlayer(x, playerid);
	    	    User[x][SpecType] = ADMIN_SPEC_TYPE_PLAYER;
			}
		}
	}
	
	if(newstate == PLAYER_STATE_PASSENGER)
	{
		foreach(new x : Player)
		{
		    if(GetPlayerState(x) == PLAYER_STATE_SPECTATING && User[x][SpecID] == playerid)
			{
		        TogglePlayerSpectating(x, 1);
		        PlayerSpectateVehicle(x, vehicleid);
		        User[x][SpecType] = ADMIN_SPEC_TYPE_VEHICLE;
			}
		}
	}

	if(newstate == PLAYER_STATE_DRIVER)
	{
		foreach(new x : Player)
		{
		    if(GetPlayerState(x) == PLAYER_STATE_SPECTATING && User[x][SpecID] == playerid)
			{
		        TogglePlayerSpectating(x, 1);
		        PlayerSpectateVehicle(x, vehicleid);
		        User[x][SpecType] = ADMIN_SPEC_TYPE_VEHICLE;
			}
		}
		
		RepairVehicle(GetPlayerVehicleID(playerid));
		UpdateVehicleDamageStatus(GetPlayerVehicleID(playerid), 0, 0, 0, 0);
		SetVehicleHealth(GetPlayerVehicleID(playerid), Float:0x7F800000);
	}
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	if(!User[playerid][accountLogged])
	{
	    if(!ServerInfo[RegisterOption])
		{
			SendClientMessage(playerid, COLOR_RED, "* You need to login or register to spawn.");
		    return 0;
		}
		else
		{
		    if(!CheckAccount(pName(playerid)))
			{
				#if !defined USE_DIALOG
				    new string[128];
			        SetPVarString(playerid, "old_name", pName(playerid));
			        format(string, sizeof(string), "%s_%d", pName(playerid), (random(10000) + 1));
			        SetPlayerName(playerid, string);
			        format(string, sizeof(string), "* You have skipped the registration, resulting on your name to be set to %s.", pName(playerid));
			        SendClientMessage(playerid, COLOR_RED, string);
			        SendClientMessage(playerid, COLOR_GREEN, "* Signing-up your account will set your name back to normal.");
				#endif
		    	return 1;
			}
			else
			{
				SendClientMessage(playerid, COLOR_RED, "* You need to login to spawn.");
			    return 0;
			}
		}
	}
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	foreach(new x : Player)
	{
	    if(GetPlayerState(x) == PLAYER_STATE_SPECTATING && User[x][SpecID] == playerid && User[x][SpecType] == ADMIN_SPEC_TYPE_PLAYER)
   		{
   		    SetPlayerInterior(x,newinteriorid);
		}
	}
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING && User[playerid][SpecID] != INVALID_PLAYER_ID)
	{
		if(newkeys == KEY_JUMP) AdvanceSpectate(playerid);
		else if(newkeys == KEY_SPRINT) ReverseSpectate(playerid);
	}
	return 1;
}

#if defined USE_RCON_PROTECTION
	public OnPlayerRconLogin(playerid)
	{
		if(_RCON[playerid] == false)
		{
			SendClientMessage(playerid, COLOR_YELLOW, "* This server uses a second RCON protection to guard off against hackers.");
			Dialog_Show(playerid, DIALOG_RCON, DIALOG_STYLE_PASSWORD, ""green"2nd RCON Password", ""grey"The RCON password is protected by the server.\nPlease type the 2nd RCON Password to access the RCON.", "Access", "Kick");
		}
		return 1;
	}
#endif

//============================================================================//
Dialog:DIALOG_BEGIN(playerid, response, listitem, inputtext[]) 
{
	playerid = INVALID_PLAYER_ID;
	response = 0;
	listitem = 0;
	inputtext[0] = '\0';
}

#if defined USE_RCON_PROTECTION
Dialog:DIALOG_RCON(playerid, response, listitem, inputtext[])
{
	static string[128];
	string[0] = 0;
	
	if(!response)
	{
		format(string, sizeof(string), "** %s was kicked from the server (attempted login to RCON)", pName(playerid));
		SendClientMessageToAll(COLOR_RED, string);
		print(string);
		SaveLog("rcon.txt", string);
		return KickDelay(playerid);
	}
	else
	{
		if(!strcmp(RCON_PASSWORD, inputtext, true))
		{
			format(string, sizeof(string), "[RCON] %s (%s) logged into the RCON.", pName(playerid), User[playerid][accountIP]);
			SendAdmin(COLOR_RED, string);
			print(string);
			SaveLog("rcon.txt", string);
			
			_RCON[playerid] = true;
			
			GameTextForPlayer(playerid, "~n~~n~~n~~n~~n~~g~Authorized ~w~Access!~n~~y~Welcome Admin!", 3000, 3);
		}
		else
		{
			if(_RCONwarn[playerid] >= MAX_RCON_WARNINGS+1)
			{
				format(string, sizeof(string), "** %s was kicked from the server (attempted login to RCON)", pName(playerid));
				SendClientMessageToAll(COLOR_RED, string);
				print(string);
				SaveLog("kicklog.txt", string);
				KickDelay(playerid);
				return 1;
			}
			_RCONwarn[playerid] ++;
			format(string, sizeof(string), "You have been warned for incorrect RCON password login (Warnings: %i/%i)", _RCONwarn[playerid], MAX_RCON_WARNINGS);
			SendClientMessage(playerid, COLOR_RED, string);
			Dialog_Show(playerid, DIALOG_RCON, DIALOG_STYLE_PASSWORD, ""green"2nd RCON Password", ""grey"The RCON password is protected by the server.\nPlease type the 2nd RCON Password to access the RCON.", "Access", "Kick");
		}
	}
	return 1;
}
#endif
	    
Dialog:DIALOG_PUNISHMENT(playerid, response, listitem, inputtext[])
{
	static string[128]; 
	string[0] = 0;
	new id = GetPVarInt(playerid, "punish_clicked"), Float:x, Float:y, Float:z;
	if(response)
	{
		if(!strcmp(inputtext, "Report this player"))
		{
			if(User[playerid][accountAdmin] < 1)
			{
				if(User[playerid][accountAdmin] < User[id][accountAdmin])
					return SendClientMessage(playerid, COLOR_RED, "* You cannot report this player, they are an admin.");

				SetPVarInt(playerid, "punish_type", 7);
				Dialog_Show(playerid, DIALOG_REASON, DIALOG_STYLE_INPUT, "Report Reason", "What this player has violated?", "Report", "Cancel");
			}
			else SendClientMessage(playerid, COLOR_RED, "* You are an admin, you do not need this - dialog operation has been cancelled.");
		}
		if(!strcmp(inputtext, "Kick", true))
		{
			if(User[playerid][accountAdmin] >= 1)
			{
				if(User[playerid][accountAdmin] < User[id][accountAdmin])
					return SendClientMessage(playerid, COLOR_RED, "* You cannot kick this player, they are a higher admin.");

				SetPVarInt(playerid, "punish_type", 1);
				Dialog_Show(playerid, DIALOG_REASON, DIALOG_STYLE_INPUT, "Reason for Kick:", "Input the reason why this user should be kicked:", "Execute", "Cancel");
			}
			else SendClientMessage(playerid, COLOR_RED, "* You are no longer an admin therefore the dialog operation has been cancelled.");
		}
		if(!strcmp(inputtext, "Teleport to this player", true))
		{
			GetPlayerPos(id, x, y, z);
			SetPlayerInterior(playerid, GetPlayerInterior(id));
			SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(id));
			if(GetPlayerState(playerid) == 2)
			{
				SetVehiclePos(GetPlayerVehicleID(playerid), x+3, y, z);
				LinkVehicleToInterior(GetPlayerVehicleID(playerid), GetPlayerInterior(id));
				SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), GetPlayerVirtualWorld(id));
			}
			else SetPlayerPos(playerid, x+2, y, z);
			
			format(string, sizeof(string), "You have been teleported to Player %s.", pName(id));
			SendClientMessage(playerid, COLOR_GREEN, string);
			format(string, sizeof(string), "Admin %s has teleported to your location.", pName(playerid));
			SendClientMessage(id, COLOR_GREEN, string);
			DeletePVar(playerid, "punish_clicked");
		}
		if(!strcmp(inputtext, "Respawn", true))
		{
			if(User[playerid][accountAdmin] >= 1)
			{
				if(User[playerid][accountAdmin] < User[id][accountAdmin])
					return SendClientMessage(playerid, COLOR_RED, "* You cannot respawn this player, they are a higher admin.");

				SetPlayerPos(id, 0.0, 0.0, 0.0);
				SpawnPlayer(id);
				format(string, sizeof(string), "You have respawned Player %s.", pName(id));
				SendClientMessage(playerid, -1, string);
				format(string, sizeof(string), "Admin %s has respawned you.", pName(playerid));
				SendClientMessage(id, COLOR_YELLOW, string);
				DeletePVar(playerid, "punish_clicked");
			}
			else SendClientMessage(playerid, COLOR_RED, "* You are no longer an admin therefore the dialog operation has been cancelled.");
		}
		if(!strcmp(inputtext, "Warn", true))
		{
			if(User[playerid][accountAdmin] >= 1)
			{
				if(User[playerid][accountAdmin] < User[id][accountAdmin])
					return SendClientMessage(playerid, COLOR_RED, "* You cannot warn this player, they are a higher admin.");

				SetPVarInt(playerid, "punish_type", 2);
				Dialog_Show(playerid, DIALOG_REASON, DIALOG_STYLE_INPUT, "Reason for Warning:", "Input the reason why this user should be warned:", "Execute", "Cancel");
			}
			else SendClientMessage(playerid, COLOR_RED, "* You are no longer an admin therefore the dialog operation has been cancelled.");
		}
		if(!strcmp(inputtext, "Explode", true))
		{
			if(User[playerid][accountAdmin] >= 2)
			{
				if(User[playerid][accountAdmin] < User[id][accountAdmin])
					return SendClientMessage(playerid, COLOR_RED, "* You cannot explode this player, they are a higher admin.");

				SetPVarInt(playerid, "punish_type", 3);
				Dialog_Show(playerid, DIALOG_REASON, DIALOG_STYLE_INPUT, "Reason for Explode:", "Input the reason why this user should be exploded:", "Execute", "Cancel");
			}
			else SendClientMessage(playerid, COLOR_RED, "* You are no longer a level 2 admin therefore the dialog operation has been cancelled.");
		}
		if(!strcmp(inputtext, "Kill this player", true))
		{
			if(User[playerid][accountAdmin] >= 2)
			{
				if(User[playerid][accountAdmin] < User[id][accountAdmin])
					return SendClientMessage(playerid, COLOR_RED, "* You cannot admin-kill this player, they are a higher admin.");

				SetPVarInt(playerid, "punish_type", 4);
				Dialog_Show(playerid, DIALOG_REASON, DIALOG_STYLE_INPUT, "Reason for Kill:", "Input the reason why this user should be Admin-Killed:", "Execute", "Cancel");
			}
			else SendClientMessage(playerid, COLOR_RED, "* You are no longer a level 2 admin therefore the dialog operation has been cancelled.");
		}
		if(!strcmp(inputtext, "Spectate", true))
		{
			if(User[playerid][accountAdmin] >= 2)
			{
				if(User[playerid][accountAdmin] < User[id][accountAdmin])
					return SendClientMessage(playerid, COLOR_RED, "* You cannot spectate this player, they are a higher admin.");

				if(GetPlayerState(id) == PLAYER_STATE_SPECTATING && User[id][SpecID] != INVALID_PLAYER_ID)
					return SendClientMessage(playerid, COLOR_RED, "* Player is spectating someone.");
					
				if(GetPlayerState(id) != 1 && GetPlayerState(id) != 2 && GetPlayerState(id) != 3)
					return SendClientMessage(playerid, COLOR_RED, "* Player not spawned.");
					
				GetPlayerPos(playerid, SpecPos[playerid][0], SpecPos[playerid][1], SpecPos[playerid][2]);
				GetPlayerFacingAngle(playerid, SpecPos[playerid][3]);
				SpecInt[playerid][0] = GetPlayerInterior(playerid);
				SpecInt[playerid][1] = GetPlayerVirtualWorld(playerid);
				StartSpectate(playerid, id);
				format(string, sizeof(string), "Now Spectating: %s (ID: %d)", pName(id), id);
				SendClientMessage(playerid, COLOR_LIGHTBLUE, string);
				SendClientMessage(playerid, -1, "Press SHIFT for Advance Spectating and SPACE for backward spectating.");
				DeletePVar(playerid, "punish_clicked");
			}
			else SendClientMessage(playerid, COLOR_RED, "* You are no longer a level 2 admin therefore the dialog operation has been cancelled.");
		}
		if(!strcmp(inputtext, "Jetpack", true))
		{
			if(User[playerid][accountAdmin] >= 2)
			{
				if(User[playerid][accountAdmin] < User[id][accountAdmin])
					return SendClientMessage(playerid, COLOR_RED, "* You cannot give this player a jetpack, they are a higher admin.");

				SetPlayerSpecialAction(id, SPECIAL_ACTION_USEJETPACK);
				format(string, sizeof(string), "You have given Player %s(ID:%d) a jetpack.", pName(id), id);
				SendClientMessage(playerid, COLOR_YELLOW, string);
				format(string, sizeof(string), "Admin %s(ID:%d) has given you a jetpack.", pName(playerid), playerid);
				SendClientMessage(id, COLOR_YELLOW, string);
				DeletePVar(playerid, "punish_clicked");
			}
			else SendClientMessage(playerid, COLOR_RED, "* You are no longer a level 2 admin therefore the dialog operation has been cancelled.");
		}
		if(!strcmp(inputtext, "Slap", true))
		{
			if(User[playerid][accountAdmin] >= 3)
			{
				if(User[playerid][accountAdmin] < User[id][accountAdmin])
					return SendClientMessage(playerid, COLOR_RED, "* You cannot slap this player, they are a higher admin.");

				SetPVarInt(playerid, "punish_type", 5);
				Dialog_Show(playerid, DIALOG_REASON, DIALOG_STYLE_INPUT, "Reason for Slap:", "Input the reason why this user should be slapped:", "Execute", "Cancel");
			}
			else SendClientMessage(playerid, COLOR_RED, "* You are no longer a level 3 admin therefore the dialog operation has been cancelled.");
		}
		if(!strcmp(inputtext, "Smash the Hammer", true))
		{
			if(User[playerid][accountAdmin] >= 3)
			{
				if(User[playerid][accountAdmin] < User[id][accountAdmin])
					return SendClientMessage(playerid, COLOR_RED, "* You cannot ban this player, they are a higher admin.");

				SetPVarInt(playerid, "punish_type", 6);
				Dialog_Show(playerid, DIALOG_REASON, DIALOG_STYLE_INPUT, "Reason for Ban:", "Input the reason why this user should be banned:", "Execute", "Cancel");
			}
			else SendClientMessage(playerid, COLOR_RED, "* You are no longer a level 3 admin therefore the dialog operation has been cancelled.");
		}
		if(!strcmp(inputtext, "Teleport player to you", true))
		{
			if(User[playerid][accountAdmin] >= 3)
			{
				if(User[playerid][accountAdmin] < User[id][accountAdmin])
					return SendClientMessage(playerid, COLOR_RED, "* You cannot teleport this player to you, they are a higher admin.");

				GetPlayerPos(playerid, x, y, z);
				SetPlayerInterior(id, GetPlayerInterior(playerid));
				SetPlayerVirtualWorld(id, GetPlayerVirtualWorld(playerid));

				if(GetPlayerState(id) == 2)
				{
					new VehicleID = GetPlayerVehicleID(id);
					SetVehiclePos(VehicleID, x+3, y, z);
					LinkVehicleToInterior(VehicleID, GetPlayerInterior(playerid));
					SetVehicleVirtualWorld(GetPlayerVehicleID(id), GetPlayerVirtualWorld(playerid));
				}
				else SetPlayerPos(id, x+2, y, z);

				format(string, sizeof(string), "You have been teleported to Admin %s(ID:%d) location.", pName(playerid), playerid);
				SendClientMessage(id, COLOR_YELLOW, string);
				format(string, sizeof(string), "You have teleported %s(ID:%d) to your location.", pName(id), id);
				SendClientMessage(playerid, COLOR_YELLOW, string);

				DeletePVar(playerid, "punish_clicked");
			}
			else SendClientMessage(playerid, COLOR_RED, "* You are no longer a level 3 admin therefore the dialog operation has been cancelled.");
		}
		if(!strcmp(inputtext, "Crash their game", true))
		{
			if(User[playerid][accountAdmin] >= 3)
			{
				if(User[playerid][accountAdmin] < User[id][accountAdmin])
					return SendClientMessage(playerid, COLOR_RED, "* You cannot crash this player's game, they are a higher admin.");

				format(string, sizeof(string), "You crashed Player %s (ID: %d).", pName(id), id);
				SendClientMessage(playerid, -1, string);
				format(string, sizeof(string), "Admin %s has crashed your game.", pName(playerid));
				SendClientMessage(id, COLOR_YELLOW, string);

				GameTextForPlayer(id, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 1000, 0);
				GameTextForPlayer(id, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 2000, 1);
				GameTextForPlayer(id, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 3000, 2);
				GameTextForPlayer(id, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 4000, 3);
				GameTextForPlayer(id, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 5000, 4);
				GameTextForPlayer(id, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 6000, 5);
				GameTextForPlayer(id, "•¤¶§!$$%&'()*+,-./01~!@#$^&*()_-+={[}]:;'<,>.?/", 7000, 6);

				DeletePVar(playerid, "punish_clicked");
			}
			else SendClientMessage(playerid, COLOR_RED, "* You are no longer a level 3 admin therefore the dialog operation has been cancelled.");
		}
	}
	else
	{
		DeletePVar(playerid, "punish_clicked");
		DeletePVar(playerid, "punish_type");
	}
	return 1;
}

Dialog:DIALOG_REASON(playerid, response, listitem, inputtext[])
{
	static string[128];
	string[0] = 0;
	new type = GetPVarInt(playerid, "punish_type"), id = GetPVarInt(playerid, "punish_clicked");
	if(response)
	{
		if(!strlen(inputtext))
		{
			SendClientMessage(playerid, COLOR_RED, "Dialog operation cancelled, No input were typed in the field.");
			return 1;
		}
	
		switch(type)
		{
			case 1: // Kick
			{
				if(!IsPlayerConnected(id))
					return SendClientMessage(playerid, COLOR_RED, "* Player is no longer in game.");
			
				format(string, sizeof(string), "ADMIN: %s was kicked from the server by %s (Reason: %s)", pName(id), pName(playerid), inputtext);
				SendClientMessageToAll(COLOR_RED, string);
				SaveLog("kicklog.txt", string);
				KickDelay(id);
				DeletePVar(playerid, "punish_clicked");
				DeletePVar(playerid, "punish_type");
			}
			case 2: // Warn
			{
				if(!IsPlayerConnected(id))
					return SendClientMessage(playerid, COLOR_RED, "* Player is no longer in game.");

				User[id][accountWarn] += 1;
				format(string, sizeof(string), "Admin %s(%d) warned %s(%d) for %s (Warnings: %d)", pName(playerid), playerid, pName(id), id, inputtext, User[id][accountWarn]);
				SendClientMessageToAll(COLOR_YELLOW, string);
			}
			case 3: // Explode
			{
				if(!IsPlayerConnected(id))
					return SendClientMessage(playerid, COLOR_RED, "* Player is no longer in game.");

				new Float:x, Float:y, Float:z;
				GetPlayerPos(id, x, y, z);
				format(string, sizeof(string), "ADMIN: %s was exploded by %s (Reason: %s)", pName(id), pName(playerid), inputtext);
				SendClientMessageToAll(COLOR_RED, string);
				SaveLog("explode.txt", string);
				CreateExplosionForPlayer(id, x, y, z, 7, 1.00);
			}
			case 4: // Admin-Kill
			{
				if(!IsPlayerConnected(id))
					return SendClientMessage(playerid, COLOR_RED, "* Player is no longer in game.");

				SetPlayerHealth(id, 0.0);
				format(string, sizeof(string), "ADMIN: %s was killed by %s. (Reason: %s)", pName(id), pName(playerid), inputtext);
				SendClientMessageToAll(COLOR_RED, string);
			}
			case 5: // Slap
			{
				if(!IsPlayerConnected(id))
					return SendClientMessage(playerid, COLOR_RED, "* Player is no longer in game.");

				new Float:x, Float:y, Float:z, Float:health;
				GetPlayerPos(id, x, y, z);
				GetPlayerHealth(id, health);
				SetPlayerHealth(id, health-25);
				SetPlayerPos(id, x, y, z+5);
				PlayerPlaySound(playerid, 1190, 0.0, 0.0, 0.0);
				PlayerPlaySound(id, 1190, 0.0, 0.0, 0.0);
				format(string, sizeof(string), "ADMIN: %s was slapped by %s. (Reason: %s)", pName(id), pName(playerid), inputtext);
				SendClientMessageToAll(COLOR_GREY, string);
			}
			case 6: // Smash the Hammer
			{
				if(!IsPlayerConnected(id))
					return SendClientMessage(playerid, COLOR_RED, "* Player is no longer in game.");

				new when[128], ban_hr, ban_min, ban_sec, ban_month, ban_days, ban_years;
				gettime(ban_hr, ban_min, ban_sec);
				getdate(ban_years, ban_month, ban_days);
				format(when, 128, "%02d/%02d/%d %02d:%02d:%02d", ban_month, ban_days, ban_years, ban_hr, ban_min, ban_sec);
				format(string, sizeof(string), "ADMIN: %s was banned by %s (Reason: %s)", pName(id), pName(playerid), inputtext);
				SendClientMessageToAll(COLOR_GREY, string);
				printf(string);
				SaveLog("banlog.txt", string);
				format(string, sizeof(string), "You have banned %s(%d) for %s.", pName(id), id, inputtext);
				SendClientMessage(playerid, COLOR_YELLOW, string);
				format(string, sizeof(string), "You have been banned by Admin %s(%d) (Reason: %s)", pName(playerid), playerid, inputtext);
				SendClientMessage(id, COLOR_YELLOW, string);
				BanAccount(id, pName(playerid), inputtext);
				for(new i; i < 100; i++) SendClientMessage(playerid, -1, " ");
				ShowBan(id, GetPVarInt(id, "ban_id"), pName(playerid), inputtext, when);
				KickDelay(id);
			}
			case 7: // Report this player
			{
				if(!IsPlayerConnected(id))
					return SendClientMessage(playerid, COLOR_RED, "* Player is no longer in game.");

				InsertReport(playerid, id, inputtext);
			}
		}
	}
	else
	{
		DeletePVar(playerid, "punish_clicked");
		DeletePVar(playerid, "punish_type");
	}
	return 1;
}

Dialog:DIALOG_AFK(playerid, response, listitem, inputtext[])
{
	static string[128];
	string[0] = 0;
	
	if(response)
	{
		if(!strlen(inputtext))
			return Dialog_Show(playerid, DIALOG_AFK, DIALOG_STYLE_INPUT, "Idle Seconds", "Place in the maximum time the player can idle to. (0 to disable)", "Set", "Back");

		if(!isnumeric(inputtext))
			return Dialog_Show(playerid, DIALOG_AFK, DIALOG_STYLE_INPUT, "Idle Seconds", "Place in the maximum time the player can idle to. (0 to disable)", "Set", "Back");

		if(strval(inputtext) < 0)
			return Dialog_Show(playerid, DIALOG_AFK, DIALOG_STYLE_INPUT, "Idle Seconds", "Place in the maximum time the player can idle to. (0 to disable)", "Set", "Back");

		ServerInfo[AFKTime] = strval(inputtext);
		SaveConfig();

		format(string, sizeof(string), "* Admin %s has set the Time Limit for Idled Players to (%d).", pName(playerid), ServerInfo[AFKTime]);
		SendAdmin(COLOR_YELLOW, string);
	}
	else ShowSettings(playerid);
	return 1;
}

Dialog:DIALOG_TABBED(playerid, response, listitem, inputtext[])
{
	static string[128];
	string[0] = 0;
	
	if(response)
	{
		if(!strlen(inputtext))
			return Dialog_Show(playerid, DIALOG_TABBED, DIALOG_STYLE_INPUT, "Tabbed Seconds", "Place in the maximum time the player can alt-tab to. (0 to disable)", "Set", "Back");

		if(!isnumeric(inputtext))
			return Dialog_Show(playerid, DIALOG_TABBED, DIALOG_STYLE_INPUT, "Tabbed Seconds", "Place in the maximum time the player can alt-tab to. (0 to disable)", "Set", "Back");

		if(strval(inputtext) < 0)
			return Dialog_Show(playerid, DIALOG_TABBED, DIALOG_STYLE_INPUT, "Tabbed Seconds", "Place in the maximum time the player can alt-tab to. (0 to disable)", "Set", "Back");

		ServerInfo[TabTime] = strval(inputtext);
		SaveConfig();

		format(string, sizeof(string), "* Admin %s has set the Time Limit for Alt-Tabbed Players to (%d).", pName(playerid), ServerInfo[TabTime]);
		SendAdmin(COLOR_YELLOW, string);
	}
	else ShowSettings(playerid);
	return 1;
}

Dialog:DIALOG_PING(playerid, response, listitem, inputtext[])
{
	static string[128];
	string[0] = 0;
	
	if(response)
	{
		if(!strlen(inputtext))
			return Dialog_Show(playerid, DIALOG_PING, DIALOG_STYLE_INPUT, "Maximum Ping", "Place in the maximum ping in the server (E.G.; 1000);\n* Once player reached this ping, they will get warned first then kick.\n\n* To disable the Ping Kicker, simply place 0.", "Set", "Back");

		if(!isnumeric(inputtext))
			return Dialog_Show(playerid, DIALOG_PING, DIALOG_STYLE_INPUT, "Maximum Ping", "Place in the maximum ping in the server (E.G.; 1000);\n* Once player reached this ping, they will get warned first then kick.\n\n* To disable the Ping Kicker, simply place 0.", "Set", "Back");

		if(strval(inputtext) < 0)
			return Dialog_Show(playerid, DIALOG_PING, DIALOG_STYLE_INPUT, "Maximum Ping", "Place in the maximum ping in the server (E.G.; 1000);\n* Once player reached this ping, they will get warned first then kick.\n\n* To disable the Ping Kicker, simply place 0.", "Set", "Back");

		ServerInfo[MaxPing] = strval(inputtext);
		SaveConfig();

		format(string, sizeof(string), "* Admin %s has set the Maximum Ping to (%d).", pName(playerid), ServerInfo[MaxPing]);
		SendAdmin(COLOR_YELLOW, string);
	}
	else ShowSettings(playerid);
	return 1;
}

Dialog:DIALOG_LOG_TRIES(playerid, response, listitem, inputtext[])
{
	static string[128];
	string[0] = 0;
	
	if(response)
	{
		if(!strlen(inputtext))
			return Dialog_Show(playerid, DIALOG_LOG_TRIES, DIALOG_STYLE_INPUT, "Login Tries", "Place in the amount of maximum login tries;\n\n* Once player reached this amount of tries, They will get kicked.", "Set", "Back");

		if(!isnumeric(inputtext))
			return Dialog_Show(playerid, DIALOG_LOG_TRIES, DIALOG_STYLE_INPUT, "Login Tries", "Place in the amount of maximum login tries;\n\n* Once player reached this amount of tries, They will get kicked.", "Set", "Back");

		if(strval(inputtext) < 1)
			return Dialog_Show(playerid, DIALOG_LOG_TRIES, DIALOG_STYLE_INPUT, "Login Tries", "Place in the amount of maximum login tries;\n\n* Once player reached this amount of tries, They will get kicked.", "Set", "Back");

		ServerInfo[LoginWarn] = strval(inputtext);
		SaveConfig();

		format(string, sizeof(string), "* Admin %s has set the Maximum Login Tries to (%d).", pName(playerid), ServerInfo[LoginWarn]);
		SendAdmin(COLOR_YELLOW, string);
	}
	else ShowSettings(playerid);
	return 1;
}

Dialog:DIALOG_SEC_TRIES(playerid, response, listitem, inputtext[])
{
	static string[128];
	string[0] = 0;
	
	if(response)
	{
		if(!strlen(inputtext))
			return Dialog_Show(playerid, DIALOG_SEC_TRIES, DIALOG_STYLE_INPUT, "Secure Tries", "Place in the amount of maximum security question tries;\n\n* Once player reached this amount of tries, They will get kicked.", "Set", "Back");

		if(!isnumeric(inputtext))
			return Dialog_Show(playerid, DIALOG_SEC_TRIES, DIALOG_STYLE_INPUT, "Secure Tries", "Place in the amount of maximum security question tries;\n\n* Once player reached this amount of tries, They will get kicked.", "Set", "Back");

		if(strval(inputtext) < 1)
			return Dialog_Show(playerid, DIALOG_SEC_TRIES, DIALOG_STYLE_INPUT, "Secure Tries", "Place in the amount of maximum security question tries;\n\n* Once player reached this amount of tries, They will get kicked.", "Set", "Back");

		ServerInfo[SecureWarn] = strval(inputtext);
		SaveConfig();

		format(string, sizeof(string), "* Admin %s has set the Maximum Security Question Tries to (%d).", pName(playerid), ServerInfo[SecureWarn]);
		SendAdmin(COLOR_YELLOW, string);
	}
	else ShowSettings(playerid);
	return 1;
}

Dialog:DIALOG_RANKS(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		switch(listitem)
		{
			case 0: Dialog_Show(playerid, DIALOG_EDIT_ADMIN_1, DIALOG_STYLE_INPUT, "Editing; Admin Rank 1", "You are now editing Admin Rank #1;\n\n* Type in the new rank name for admin level 1.", "Set", "Back");
			case 1: Dialog_Show(playerid, DIALOG_EDIT_ADMIN_2, DIALOG_STYLE_INPUT, "Editing; Admin Rank 2", "You are now editing Admin Rank #2;\n\n* Type in the new rank name for admin level 2.", "Set", "Back");
			case 2: Dialog_Show(playerid, DIALOG_EDIT_ADMIN_3, DIALOG_STYLE_INPUT, "Editing; Admin Rank 3", "You are now editing Admin Rank #3;\n\n* Type in the new rank name for admin level 3.", "Set", "Back");
			case 3: Dialog_Show(playerid, DIALOG_EDIT_ADMIN_4, DIALOG_STYLE_INPUT, "Editing; Admin Rank 4", "You are now editing Admin Rank #4;\n\n* Type in the new rank name for admin level 4.", "Set", "Back");
			case 4: Dialog_Show(playerid, DIALOG_EDIT_ADMIN_5, DIALOG_STYLE_INPUT, "Editing; Admin Rank 5", "You are now editing Admin Rank #5;\n\n* Type in the new rank name for admin level 5.", "Set", "Back");
		}
	}
	else ShowSettings(playerid);
	return 1;
}

Dialog:DIALOG_EDIT_ADMIN_1(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		if(!strlen(inputtext))
			return Dialog_Show(playerid, DIALOG_EDIT_ADMIN_1, DIALOG_STYLE_INPUT, "Editing; Admin Rank 1", "You are now editing Admin Rank #1;\n\n* Type in the new rank name for admin level 1.", "Set", "Back");

		if(strlen(inputtext) > 63)
			return Dialog_Show(playerid, DIALOG_EDIT_ADMIN_1, DIALOG_STYLE_INPUT, "Editing; Admin Rank 1", "You are now editing Admin Rank #1;\n\n* Type in the new rank name for admin level 1.", "Set", "Back");

		format(ServerInfo[AdminRank1], 32, inputtext);
		SaveConfig();
		ShowRanks(playerid);
	}
	else ShowRanks(playerid);
	return 1;
}

Dialog:DIALOG_EDIT_ADMIN_2(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		if(!strlen(inputtext))
			return Dialog_Show(playerid, DIALOG_EDIT_ADMIN_2, DIALOG_STYLE_INPUT, "Editing; Admin Rank 2", "You are now editing Admin Rank #2;\n\n* Type in the new rank name for admin level 2.", "Set", "Back");

		if(strlen(inputtext) > 63)
			return Dialog_Show(playerid, DIALOG_EDIT_ADMIN_2, DIALOG_STYLE_INPUT, "Editing; Admin Rank 2", "You are now editing Admin Rank #2;\n\n* Type in the new rank name for admin level 2.", "Set", "Back");

		format(ServerInfo[AdminRank2], 32, inputtext);
		SaveConfig();
		ShowRanks(playerid);
	}
	else ShowRanks(playerid);
	return 1;
}

Dialog:DIALOG_EDIT_ADMIN_3(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		if(!strlen(inputtext))
			return Dialog_Show(playerid, DIALOG_EDIT_ADMIN_3, DIALOG_STYLE_INPUT, "Editing; Admin Rank 3", "You are now editing Admin Rank #3;\n\n* Type in the new rank name for admin level 3.", "Set", "Back");

		if(strlen(inputtext) > 63)
			return Dialog_Show(playerid, DIALOG_EDIT_ADMIN_3, DIALOG_STYLE_INPUT, "Editing; Admin Rank 3", "You are now editing Admin Rank #3;\n\n* Type in the new rank name for admin level 3.", "Set", "Back");

		format(ServerInfo[AdminRank3], 32, inputtext);
		SaveConfig();
		ShowRanks(playerid);
	}
	else ShowRanks(playerid);
	return 1;
}

Dialog:DIALOG_EDIT_ADMIN_4(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		if(!strlen(inputtext))
			return Dialog_Show(playerid, DIALOG_EDIT_ADMIN_4, DIALOG_STYLE_INPUT, "Editing; Admin Rank 4", "You are now editing Admin Rank #4;\n\n* Type in the new rank name for admin level 4.", "Set", "Back");

		if(strlen(inputtext) > 63)
			return Dialog_Show(playerid, DIALOG_EDIT_ADMIN_4, DIALOG_STYLE_INPUT, "Editing; Admin Rank 4", "You are now editing Admin Rank #4;\n\n* Type in the new rank name for admin level 4.", "Set", "Back");

		format(ServerInfo[AdminRank4], 32, inputtext);
		SaveConfig();
		ShowRanks(playerid);
	}
	else ShowRanks(playerid);
	return 1;
}

Dialog:DIALOG_EDIT_ADMIN_5(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		if(!strlen(inputtext))
			return Dialog_Show(playerid, DIALOG_EDIT_ADMIN_5, DIALOG_STYLE_INPUT, "Editing; Admin Rank 5", "You are now editing Admin Rank #5;\n\n* Type in the new rank name for admin level 5.", "Set", "Back");

		if(strlen(inputtext) > 63)
			return Dialog_Show(playerid, DIALOG_EDIT_ADMIN_5, DIALOG_STYLE_INPUT, "Editing; Admin Rank 5", "You are now editing Admin Rank #5;\n\n* Type in the new rank name for admin level 5.", "Set", "Back");

		format(ServerInfo[AdminRank5], 32, inputtext);
		SaveConfig();
		ShowRanks(playerid);
	}
	else ShowRanks(playerid);
	return 1;
}

Dialog:DIALOG_SETTINGS(playerid, response, listitem, inputtext[])
{
	static string[128];
	string[0] = 0;
	
	if(response)
	{
		switch(listitem)
		{
			case 0: // Save Log
			{
				switch(ServerInfo[SaveLogs])
				{
					case 0:
					{
						format(string, sizeof(string), "* Admin %s has enable the Save Log Files feature (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[SaveLogs] = 1;
						SaveConfig();
					}
					case 1:
					{
						format(string, sizeof(string), "* Admin %s has disable the Save Log Files feature (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[SaveLogs] = 0;
						SaveConfig();
					}
				}
				ShowSettings(playerid);
			}
			case 1: // Login Tries
			{
				Dialog_Show(playerid, DIALOG_LOG_TRIES, DIALOG_STYLE_INPUT, "Login Tries", "Place in the amount of maximum login tries;\n\n* Once player reached this amount of tries, They will get kicked.", "Set", "Back");
			}
			case 2: // Secure Tries
			{
				Dialog_Show(playerid, DIALOG_SEC_TRIES, DIALOG_STYLE_INPUT, "Secure Tries", "Place in the amount of maximum security question tries;\n\n* Once player reached this amount of tries, They will get kicked.", "Set", "Back");
			}
			case 3: // AutoLogin
			{
				switch(ServerInfo[AutoLogin])
				{
					case 0:
					{
						format(string, sizeof(string), "* Admin %s has enable the Auto Login feature (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[AutoLogin] = 1;
						SaveConfig();
					}
					case 1:
					{
						format(string, sizeof(string), "* Admin %s has disable the Auto Login feature (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[AutoLogin] = 0;
						SaveConfig();
					}
				}
				ShowSettings(playerid);
			}
			case 4: // Read Commands
			{
				switch(ServerInfo[ReadCmds])
				{
					case 0:
					{
						format(string, sizeof(string), "* Admin %s has enable the Read Player Commands feature (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[ReadCmds] = 1;
						SaveConfig();
					}
					case 1:
					{
						format(string, sizeof(string), "* Admin %s has disable the Read Player Commands feature (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[ReadCmds] = 0;
						SaveConfig();
					}
				}
				ShowSettings(playerid);
			}
			case 5: // Ping Kicker
			{
				Dialog_Show(playerid, DIALOG_PING, DIALOG_STYLE_INPUT, "Maximum Ping", "Place in the maximum ping in the server (E.G.; 1000);\n* Once player reached this ping, they will get warned first then kick.\n\n* To disable the Ping Kicker, simply place 0.", "Set", "Back");
			}
			case 6: // Anti Swear
			{
				switch(ServerInfo[AntiSwear])
				{
					case 0:
					{
						format(string, sizeof(string), "* Admin %s has enable the Anti-Swearing feature (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[AntiSwear] = 1;
						SaveConfig();
					}
					case 1:
					{
						format(string, sizeof(string), "* Admin %s has disable the Anti-Swearing feature (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[AntiSwear] = 0;
						SaveConfig();
					}
				}
				ShowSettings(playerid);
			}
			case 7: // Anti Name
			{
				switch(ServerInfo[AntiName])
				{
					case 0:
					{
						format(string, sizeof(string), "* Admin %s has enable the Anti-Name feature (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[AntiName] = 1;
						SaveConfig();
					}
					case 1:
					{
						format(string, sizeof(string), "* Admin %s has disable the Anti-Name feature (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[AntiName] = 0;
						SaveConfig();
					}
				}
				ShowSettings(playerid);
			}
			case 8: // Anti Ad
			{
				switch(ServerInfo[AntiAd])
				{
					case 0:
					{
						format(string, sizeof(string), "* Admin %s has enable the Anti-Advertisement feature (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[AntiAd] = 1;
						SaveConfig();
					}
					case 1:
					{
						format(string, sizeof(string), "* Admin %s has disable the Anti-Advertisement feature (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[AntiAd] = 0;
						SaveConfig();
					}
				}
				ShowSettings(playerid);
			}
			case 9: // Anti Spam
			{
				switch(ServerInfo[AntiSpam])
				{
					case 0:
					{
						format(string, sizeof(string), "* Admin %s has enable the Anti-Spam feature (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[AntiSpam] = 1;
						SaveConfig();
					}
					case 1:
					{
						format(string, sizeof(string), "* Admin %s has disable the Anti-Spam feature (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[AntiSpam] = 0;
						SaveConfig();
					}
				}
				ShowSettings(playerid);
			}
			case 10: // Read Command Type
			{
				switch(ServerInfo[ReadCmd])
				{
					case 0:
					{
						format(string, sizeof(string), "* Admin %s has switched to the Spectate Mode Command Reading (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[ReadCmd] = 1;
						SaveConfig();
					}
					case 1:
					{
						format(string, sizeof(string), "* Admin %s has switched to the Normal Mode Command Reading (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[ReadCmd] = 0;
						SaveConfig();
					}
				}
				ShowSettings(playerid);
			}
			case 11: // Register Optional
			{
				switch(ServerInfo[RegisterOption])
				{
					case 0:
					{
						format(string, sizeof(string), "* Admin %s has allow the Player's to skip the Registration. (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[RegisterOption] = 1;
						SaveConfig();
					}
					case 1:
					{
						format(string, sizeof(string), "* Admin %s has no-longer allow the Player's to skip the Registration (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[RegisterOption] = 0;
						SaveConfig();
					}
				}
				ShowSettings(playerid);
			}
			case 12: // Tabbed Kicker
			{
				Dialog_Show(playerid, DIALOG_TABBED, DIALOG_STYLE_INPUT, "Tabbed Seconds", "Place in the maximum time the player can alt-tab to. (0 to disable)", "Set", "Back");
			}
			case 13: // AFK Kicker
			{
				Dialog_Show(playerid, DIALOG_AFK, DIALOG_STYLE_INPUT, "Idle Seconds", "Place in the maximum time the player can idle to. (0 to disable)", "Set", "Back");
			}
			case 14: // Read PMs
			{
				switch(ServerInfo[ReadPMs])
				{
					case 0:
					{
						format(string, sizeof(string), "* Admin %s has enabled the Reading Private Messages feature (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[ReadPMs] = 1;
						SaveConfig();
					}
					case 1:
					{
						format(string, sizeof(string), "* Admin %s has disabled the Reading Private Messages feature (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[ReadPMs] = 0;
						SaveConfig();
					}
				}
				ShowSettings(playerid);
			}
			case 15: // Join/Left Messages
			{
				switch(ServerInfo[JoinMsg])
				{
					case 0:
					{
						format(string, sizeof(string), "* Admin %s has enabled the Join/Leave Messages (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[JoinMsg] = 1;
						SaveConfig();
					}
					case 1:
					{
						format(string, sizeof(string), "* Admin %s has disabled the Join/Leave Messages (/jsettings)", pName(playerid));
						SendAdmin(COLOR_YELLOW, string);
						ServerInfo[JoinMsg] = 0;
						SaveConfig();
					}
				}
				ShowSettings(playerid);
			}
			case 16: // Ranks
			{
				ShowRanks(playerid);
			}
		}
	}
	return 1;
}

Dialog:DIALOG_WOULDYOU(playerid, response, listitem, inputtext[])
{
	if(response)
		Dialog_Show(playerid, DIALOG_QUESTION, DIALOG_STYLE_INPUT, ""green"Security Question", "You can use the Security Question incase you forgot your password.\n\n* Type in your security question below;", "Setup", "");
	else
		SendClientMessage(playerid, COLOR_RED, "* You decided not to set a security question on your account.");
	return 1;
}

Dialog:DIALOG_QUESTION(playerid, response, listitem, inputtext[])
{
	if(!response)
		Dialog_Show(playerid, DIALOG_QUESTION, DIALOG_STYLE_INPUT, ""green"Security Question", "You can use the Security Question incase you forgot your password.\n\n* Type in your security question below;", "Setup", "");
	else
	{
		if(strlen(inputtext) < 6 || strlen(inputtext) > 90)
			return Dialog_Show(playerid, DIALOG_QUESTION, DIALOG_STYLE_INPUT, ""green"Security Question", "You can use the Security Question incase you forgot your password.\n\n* Type in your security question below;", "Setup", "");

		if(strcmp(inputtext, "none", true) == 0)
			return Dialog_Show(playerid, DIALOG_QUESTION, DIALOG_STYLE_INPUT, ""green"Security Question", "You can use the Security Question incase you forgot your password.\n\n* Type in your security question below;", "Setup", "");

		format(User[playerid][accountQuestion], 92, "%s", inputtext);
		SaveData(playerid);
		
		Dialog_Show(playerid, DIALOG_ANSWER, DIALOG_STYLE_INPUT, ""green"Security Answer", "You have setup the Security Question, Now setup your security answer.\n\n* Type in your security answer below:", "Setup", "");
	}
	return 1;
}

Dialog:DIALOG_ANSWER(playerid, response, listitem, inputtext[])
{
	if(!response)
		Dialog_Show(playerid, DIALOG_ANSWER, DIALOG_STYLE_INPUT, ""green"Security Answer", "You have setup the Security Question, Now setup your security answer.\n\n* Type in your security answer below:", "Setup", "");
	else
	{
		if(strlen(inputtext) < 2 || strlen(inputtext) > 90)
			return Dialog_Show(playerid, DIALOG_ANSWER, DIALOG_STYLE_INPUT, ""green"Security Answer", "You have setup the Security Question, Now setup your security answer.\n\n* Type in your security answer below:", "Setup", "");

		new hashanswer[129];
		WP_Hash(hashanswer, 129, inputtext);
		format(User[playerid][accountAnswer], 129, "%s", hashanswer);
		
		SendClientMessage(playerid, COLOR_YELLOW, "* You have successfully set your Security Question & Answer, Use the forget feature when you forgot your password.");
		SaveData(playerid);
	}
	return 1;
}

Dialog:DIALOG_QUESTION2(playerid, response, listitem, inputtext[])
{
	if(response)
	{
		if(strlen(inputtext) < 6 || strlen(inputtext) > 90)
			return Dialog_Show(playerid, DIALOG_QUESTION2, DIALOG_STYLE_INPUT, ""green"Security Question", "* Type in your new security question below;", "Set", "Cancel");

		format(User[playerid][accountQuestion], 92, "%s", inputtext);
		SaveData(playerid);

		Dialog_Show(playerid, DIALOG_ANSWER2, DIALOG_STYLE_INPUT, ""green"Security Answer", "* Type in your security answer below:", "Set", "Back");
	}
	return 1;
}

Dialog:DIALOG_ANSWER2(playerid, response, listitem, inputtext[])
{
	if(!response)
		Dialog_Show(playerid, DIALOG_QUESTION2, DIALOG_STYLE_INPUT, ""green"Security Question", "* Type in your new security question below;", "Set", "Cancel");
	else
	{
		if(strlen(inputtext) < 2 || strlen(inputtext) > 90)
			return Dialog_Show(playerid, DIALOG_ANSWER2, DIALOG_STYLE_INPUT, ""green"Security Answer", "* Type in your security answer below:", "Set", "Back");

		new hashanswer[129];
		WP_Hash(hashanswer, 129, inputtext);
		format(User[playerid][accountAnswer], 129, "%s", hashanswer);

		SendClientMessage(playerid, COLOR_YELLOW, "* You have successfully set your new Security Question & Answer.");
		SaveData(playerid);
	}
	return 1;
}

Dialog:DIALOG_REGISTER(playerid, response, listitem, inputtext[])
{
	new hashpass[129];

	if(response)
	{
		if(!IsValidPassword(inputtext))
			return Dialog_Show(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, ""green"Register", "Welcome to the Server!\nYour account doesn't exist in our database, Please insert your password below.\n\n"red"ERROR: Invalid Password Symbols.", "Register", "Quit");

		if (strlen(inputtext) < 4 || strlen(inputtext) > 20)
			return Dialog_Show(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, ""green"Register", "Welcome to the Server!\nYour account doesn't exist in our database, Please insert your password below.\n\n"red"ERROR: Password length shouldn't go below 4 and shouldn't go higher 20.", "Register", "Quit");
		
		WP_Hash(hashpass, 129, inputtext);

		RegisterPlayer(playerid, hashpass);
	}
	else
	{
		if(ServerInfo[RegisterOption])
		{
			SetPVarString(playerid, "old_name", pName(playerid));
			format(hashpass, sizeof(hashpass), "%s_%d", pName(playerid), (random(10000) + 1));
			SetPlayerName(playerid, hashpass);
			format(hashpass, sizeof(hashpass), "* You have skipped the registration, resulting on your name to be set to %s.", pName(playerid));
			SendClientMessage(playerid, COLOR_RED, hashpass);
			SendClientMessage(playerid, COLOR_GREEN, "* Signing-up your account will set your name back to normal.");
		}
		else
			KickDelay(playerid);
	}
	return 1;
}

Dialog:DIALOG_LOGIN(playerid, response, listitem, inputtext[])
{
	new hashp[129];
	static string[900];
	string[0] = 0;
	if(response)
	{
		WP_Hash(hashp, 129, inputtext);
		if(!strcmp(hashp, User[playerid][accountPassword], false))
		{
			LoginPlayer(playerid);
		}
		else
		{
			User[playerid][WarnLog]++;
		
			if(User[playerid][WarnLog] >= ServerInfo[LoginWarn])
			{
				////////////////////////////////////////////////////////////////////////////
				new DBResult:jResult, ip_month, ip_day, ip_year, ip_hour, ip_minute, ip_second;
				getdate(ip_year, ip_month, ip_day);
				gettime(ip_hour, ip_minute, ip_second);
				format(string, sizeof(string), "SELECT * FROM `breach` WHERE `username` = '%s' AND `ip` = '%s'", DB_Escape(pName(playerid)), DB_Escape(User[playerid][accountIP]));
				jResult = db_query(Database, string);
				if(!db_num_rows(jResult))
				{
					format(string, sizeof(string), "INSERT INTO `breach` (`username`, `ip`, `type`, `date`, `time`) VALUES('%s', '%s', 1, '%02d-%02d-%d', '%02d:%02d:%02d')", DB_Escape(pName(playerid)), DB_Escape(User[playerid][accountIP]), ip_month, ip_day, ip_year, ip_hour, ip_minute, ip_second);
					db_query(Database, string);
				}
				else
				{
					format(string, sizeof(string), "DELETE FROM `breach` WHERE `ip` = '%s'", DB_Escape(User[playerid][accountIP]));
					db_query(Database, string);
					format(string, sizeof(string), "INSERT INTO `breach` (`username`, `ip`, `type`, `date`, `time`) VALUES('%s', '%s', 1, '%02d-%02d-%d', '%02d:%02d:%02d')", DB_Escape(pName(playerid)), DB_Escape(User[playerid][accountIP]), ip_month, ip_day, ip_year, ip_hour, ip_minute, ip_second);
					db_query(Database, string);
				}
				db_free_result(jResult);
				////////////////////////////////////////////////////////////////////////////
				Dialog_Show(playerid, DIALOG_BEGIN, DIALOG_STYLE_MSGBOX, ""lightblue"Kicked", ""grey"You have been kicked from the server.", "Close", "");
				return KickDelay(playerid);
			}

			if(!strcmp(User[playerid][accountQuestion], "none", true))
			{
				format(string, sizeof(string), "Welcome back to the server!\nYour account exists in our database.\nPlease insert your account's password below to login.\n\n"red"* Wrong password (%d/%d)", User[playerid][WarnLog], ServerInfo[LoginWarn]);			     
				Dialog_Show(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, ""green"Login", string, "Login", "Quit");			
			}
			else
			{
				format(string, sizeof(string), "Welcome back to the server!\nYour account exists in our database.\nPlease insert your account's password below to login.\n\nPress Forget button if you have forgotten your account's password\n\n"red"* Wrong password (%d/%d)", User[playerid][WarnLog], ServerInfo[LoginWarn]);			     
				Dialog_Show(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, ""green"Login", string, "Login", "Forget");			
			}
			printf("[LOGIN ATTEMPT] %s (IP: %s) tries to login to their account with the password '%s' (attempts: %d)", pName(playerid), User[playerid][accountIP], inputtext, (ServerInfo[LoginWarn]-User[playerid][WarnLog]));
		}
	}
	else
	{
		if(strcmp(User[playerid][accountQuestion], "none", true) == 0)
		{
			KickDelay(playerid);
		}
		else
		{
			format(string, sizeof(string), "You have forgotten your password? If that's the case, answer the question you set on your account and you'll access your account.\n\n%s\n\nAnswer?\nPress Quit if you are willing to quit.", User[playerid][accountQuestion]);
			Dialog_Show(playerid, DIALOG_FORGET, DIALOG_STYLE_INPUT, ""green"Security Question", string, "Answer", "Quit");

			printf("[LOGIN ATTEMPT] %s (IP: %s) uses the 'Forgot Password' option for their account.", pName(playerid), User[playerid][accountIP]);
		}
	}
	return 1;
}

Dialog:DIALOG_FORGET(playerid, response, listitem, inputtext[])
{
	if(!response)
	{
		KickDelay(playerid);
	}
	else
	{
		new hashanswer[129];
		WP_Hash(hashanswer, 129, inputtext);
	
		if(strcmp(User[playerid][accountAnswer], hashanswer, true) == 0)
		{
			LoginPlayer(playerid);
			SendClientMessage(playerid, -1, "Access granted.");
			printf("[LOGIN SUCCESSFUL] %s (IP: %s) has successfully logged in to their account from using Forget Password option.", pName(playerid), User[playerid][accountIP]);
		}
		else
		{
			static string[900];
			string[0] = 0;

			User[playerid][WarnLog]++;

			if(User[playerid][WarnLog] >= ServerInfo[SecureWarn])
			{
				////////////////////////////////////////////////////////////////////////////
				new DBResult:jResult, ip_month, ip_day, ip_year, ip_hour, ip_minute, ip_second;
				getdate(ip_year, ip_month, ip_day);
				gettime(ip_hour, ip_minute, ip_second);
				format(string, sizeof(string), "SELECT * FROM `breach` WHERE `username` = '%s' AND `ip` = '%s'", DB_Escape(pName(playerid)), DB_Escape(User[playerid][accountIP]));
				jResult = db_query(Database, string);
				if(!db_num_rows(jResult))
				{
					format(string, sizeof(string), "INSERT INTO `breach` (`username`, `ip`, `type`, `date`, `time`) VALUES('%s', '%s', 2, '%02d-%02d-%d', '%02d:%02d:%02d')", DB_Escape(pName(playerid)), DB_Escape(User[playerid][accountIP]), ip_month, ip_day, ip_year, ip_hour, ip_minute, ip_second);
					db_query(Database, string);
				}
				else
				{
					format(string, sizeof(string), "DELETE FROM `breach` WHERE `ip` = '%s'", DB_Escape(User[playerid][accountIP]));
					db_query(Database, string);
					format(string, sizeof(string), "INSERT INTO `breach` (`username`, `ip`, `type`, `date`, `time`) VALUES('%s', '%s', 2, '%02d-%02d-%d', '%02d:%02d:%02d')", DB_Escape(pName(playerid)), DB_Escape(User[playerid][accountIP]), ip_month, ip_day, ip_year, ip_hour, ip_minute, ip_second);
					db_query(Database, string);
				}
				db_free_result(jResult);
				////////////////////////////////////////////////////////////////////////////
				Dialog_Show(playerid, DIALOG_BEGIN, DIALOG_STYLE_MSGBOX, ""lightblue"Kicked", ""grey"You have been kicked from the server.", "Close", "");
				return KickDelay(playerid);
			}

			format(string, sizeof(string), ""grey"You have forgotten your password? If that's the case, answer the question you set on your account and you'll access your account.\n\n%s\n\nAnswer?\nPress Quit if you are willing to quit.\n\nERROR: Wrong Answer on the question.\n* %d/%d", User[playerid][accountQuestion], User[playerid][WarnLog], ServerInfo[SecureWarn]);
			Dialog_Show(playerid, DIALOG_FORGET, DIALOG_STYLE_INPUT, ""lightblue"Security Question", string, "Answer", "Quit");
			
			printf("[LOGIN SUCCESSFUL] %s (IP: %s) has answered the Security Question wrong. (attempts: %d)", pName(playerid), User[playerid][accountIP], (ServerInfo[SecureWarn]-User[playerid][WarnLog]));
		}
	}
	return 1;
}
		
Dialog:DIALOG_COLORS(playerid, response, listitem, inputtext[])
{
	static string[120];
	string[0] = 0;
	new id = GetPVarInt(playerid, "_Colors_");

	switch( response )
	{
		case 0:
		{
			DeletePVar(playerid, "_Colors_");
			SendClientMessage(playerid, -1, "Colour setting has been cancelled.");
		}
		case 1:
		{
			switch( listitem )
			{
				case 0:
				{
					format(string, sizeof(string), "Admin %s has set your name color to Black", pName(playerid));
					SendClientMessage(id, COLOR_YELLOW, string);
					format(string, sizeof(string), "Color Name for Player %s has been set.", pName(id));
					SendClientMessage(playerid, COLOR_YELLOW, string);
					SetPlayerColor(id, COLOR_BLACK);
					DeletePVar(playerid, "_Colors_");
				}
				case 1:
				{
					format(string, sizeof(string), "Admin %s has set your name color to White", pName(playerid));
					SendClientMessage(id, COLOR_YELLOW, string);
					format(string, sizeof(string), "Color Name for Player %s has been set.", pName(id));
					SendClientMessage(playerid, COLOR_YELLOW, string);
					SetPlayerColor(id, COLOR_WHITE);
					DeletePVar(playerid, "_Colors_");
				}
				case 2:
				{
					format(string, sizeof(string), "Admin %s has set your name color to Red", pName(playerid));
					SendClientMessage(id, COLOR_YELLOW, string);
					format(string, sizeof(string), "Color Name for Player %s has been set.", pName(id));
					SendClientMessage(playerid, COLOR_YELLOW, string);
					SetPlayerColor(id, COLOR_RED);
					DeletePVar(playerid, "_Colors_");
				}
				case 3:
				{
					format(string, sizeof(string), "Admin %s has set your name color to Orange", pName(playerid));
					SendClientMessage(id, COLOR_YELLOW, string);
					format(string, sizeof(string), "Color Name for Player %s has been set.", pName(id));
					SendClientMessage(playerid, COLOR_YELLOW, string);
					SetPlayerColor(id, COLOR_ORANGE);
					DeletePVar(playerid, "_Colors_");
				}
				case 4:
				{
					format(string, sizeof(string), "Admin %s has set your name color to Yellow", pName(playerid));
					SendClientMessage(id, COLOR_YELLOW, string);
					format(string, sizeof(string), "Color Name for Player %s has been set.", pName(id));
					SendClientMessage(playerid, COLOR_YELLOW, string);
					SetPlayerColor(id, COLOR_YELLOW);
					DeletePVar(playerid, "_Colors_");
				}
				case 5:
				{
					format(string, sizeof(string), "Admin %s has set your name color to Green", pName(playerid));
					SendClientMessage(id, COLOR_YELLOW, string);
					format(string, sizeof(string), "Color Name for Player %s has been set.", pName(id));
					SendClientMessage(playerid, COLOR_YELLOW, string);
					SetPlayerColor(id, COLOR_GREEN);
					DeletePVar(playerid, "_Colors_");
				}
				case 6:
				{
					format(string, sizeof(string), "Admin %s has set your name color to Blue", pName(playerid));
					SendClientMessage(id, COLOR_YELLOW, string);
					format(string, sizeof(string), "Color Name for Player %s has been set.", pName(id));
					SendClientMessage(playerid, COLOR_YELLOW, string);
					SetPlayerColor(id, COLOR_BLUE);
					DeletePVar(playerid, "_Colors_");
				}
				case 7:
				{
					format(string, sizeof(string), "Admin %s has set your name color to Purple", pName(playerid));
					SendClientMessage(id, COLOR_YELLOW, string);
					format(string, sizeof(string), "Color Name for Player %s has been set.", pName(id));
					SendClientMessage(playerid, COLOR_YELLOW, string);
					SetPlayerColor(id, COLOR_PURPLE);
					DeletePVar(playerid, "_Colors_");
				}
				case 8:
				{
					format(string, sizeof(string), "Admin %s has set your name color to Brown", pName(playerid));
					SendClientMessage(id, COLOR_YELLOW, string);
					format(string, sizeof(string), "Color Name for Player %s has been set.", pName(id));
					SendClientMessage(playerid, COLOR_YELLOW, string);
					SetPlayerColor(id, COLOR_BROWN);
					DeletePVar(playerid, "_Colors_");
				}
				case 9:
				{
					format(string, sizeof(string), "Admin %s has set your name color to Pink", pName(playerid));
					SendClientMessage(id, COLOR_YELLOW, string);
					format(string, sizeof(string), "Color Name for Player %s has been set.", pName(id));
					SendClientMessage(playerid, COLOR_YELLOW, string);
					SetPlayerColor(id, COLOR_PINK);
					DeletePVar(playerid, "_Colors_");
				}
			}
		}
	}
	return 1;
}
//============================================================================//

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	ExecuteClickManager(playerid, clickedplayerid);
	return 1;
}

//============================================================================//
//Stock and functions starts here.

stock ConvertTimestamp(timestamp, _form=0)
{
    new year=1970, day=0, month=0, hourt=0, mins=0, sec=0;

    new days_of_month[12] = { 31,28,31,30,31,30,31,31,30,31,30,31 };
    new names_of_month[12][10] = {"January","February","March","April","May","June","July","August","September","October","November","December"};
    new returnstring[32];

    while(timestamp>31622400){
        timestamp -= 31536000;
        if ( ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0) ) timestamp -= 86400;
        year++;
    }

    if ( ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0) )
        days_of_month[1] = 29;
    else
        days_of_month[1] = 28;


    while(timestamp>86400){
        timestamp -= 86400, day++;
        if(day==days_of_month[month]) day=0, month++;
    }

    while(timestamp>60){
        timestamp -= 60, mins++;
        if( mins == 60) mins=0, hourt++;
    }

    sec=timestamp;

    switch( _form ){
        case 1: format(returnstring, 31, "%02d/%02d/%d %02d:%02d:%02d", day+1, month+1, year, hourt, mins, sec);
        case 2: format(returnstring, 31, "%s %02d, %d, %02d:%02d:%02d", names_of_month[month],day+1,year, hourt, mins, sec);
        case 3: format(returnstring, 31, "%d %c%c%c %d, %02d:%02d", day+1,names_of_month[month][0],names_of_month[month][1],names_of_month[month][2], year,hourt,mins);
		case 4: format(returnstring, 31, "%s %02d, %d", names_of_month[month],day+1,year);
        default: format(returnstring, 31, "%02d.%02d.%d-%02d:%02d:%02d", day+1, month+1, year, hourt, mins, sec);
    }
    return returnstring;
}

stock ExecuteClickManager(playerid, clickedplayerid)
{
	new string[64], dialog_content[500];
	SetPVarInt(playerid, "punish_clicked", clickedplayerid);
	format(string, sizeof(string), "** Punishment: %s (ID: %d)", pName(clickedplayerid), clickedplayerid);
	
	if(User[playerid][accountAdmin] < 1) format(dialog_content, sizeof(dialog_content), "Report this player");
	if(User[playerid][accountAdmin] >= 1) format(dialog_content, sizeof(dialog_content), "IP: %s\nKick\nTeleport to this player\nRespawn", getIP(clickedplayerid));
	if(User[playerid][accountAdmin] >= 2) format(dialog_content, sizeof(dialog_content), "%s\nExplode\nKill this player\nSpectate\nJetpack", dialog_content);
	if(User[playerid][accountAdmin] >= 3) format(dialog_content, sizeof(dialog_content), "%s\nSlap\nSmash the Hammer\nTeleport player to you\nCrash their game", dialog_content);

	Dialog_Show(playerid, DIALOG_PUNISHMENT, DIALOG_STYLE_LIST, string, dialog_content, "Take Action", "Close");
	return 1;
}

stock pName(playerid)
{
	new GetName[24];
	GetPlayerName(playerid, GetName, 24);
	return GetName;
}

#if defined USE_AKA
function:LoadAKA(playerid)
{
	new query[128 * 10], string[128 * 10], pAka[128 * 10], DBResult:result;
    format(query, sizeof(query), "SELECT * FROM `aka` WHERE `ip` = '%s'", User[playerid][accountIP]);
    result = db_query(Database, query);
    if(!db_num_rows(result))
    {
        format(query, sizeof(query), "INSERT INTO `aka` ('ip', 'name') VALUES ('%s', '%s')", User[playerid][accountIP], pName(playerid));
        db_query(Database, query);			
	}
	else
	{
		db_get_field_assoc(result, "name", pAka, sizeof(pAka));
		format(string, sizeof(string), "%s, %s", pAka, pName(playerid));
		if(strfind(pAka, pName(playerid), true) == -1)
		{
			format(query, sizeof(query), "UPDATE `aka` SET `name` = '%s' WHERE `ip` = '%s'", string, User[playerid][accountIP]);
			db_query(Database, query); 
		}
	}
	db_free_result(result);
	return 1;
}
#endif

function:IsAdvertisement(szInput[])
{
	new
		iCount,
		iPeriod,
		iPos,
		iChar,
		iColon;

	while((iChar = szInput[iPos++])) {
		if('0' <= iChar <= '9') iCount++;
		else if(iChar == '.') iPeriod++;
		else if(iChar == ':') iColon++;
	}
	if(iCount >= 7 && iPeriod >= 3 && iColon >= 1) {
		return 1;
	}
	return 0;
}

function:Offline_ShowStatistics(playerid, name[])
{
	new query[128], DBResult:result, id;
	new hours, minutes, seconds, chocolate;
	new admin, kills, deaths, accountid, money, score, joinDate[64], lastOn[32];
	
	id = ReturnUser(name);
	if(IsPlayerConnected(id))
	{
		format(query, sizeof(query), "* '%s' is online, /stats %d.", pName(id), id);
		return SendClientMessage(playerid, COLOR_RED, query);
	}
	
	format(query, sizeof(query), "SELECT * FROM `users` WHERE `username` = '%s'", DB_Escape(name));
	result = db_query(Database, query);
	
	if(db_num_rows(result))
	{
		accountid = db_get_field_assoc_int(result, "userid");
		score = db_get_field_assoc_int(result, "score");
		money = db_get_field_assoc_int(result, "money");
		kills = db_get_field_assoc_int(result, "kills");
		deaths = db_get_field_assoc_int(result, "deaths");
		admin = db_get_field_assoc_int(result, "admin");
		db_get_field_assoc(result, "joindate", joinDate, sizeof(joinDate));
        hours = db_get_field_assoc_int(result, "hours");
        minutes = db_get_field_assoc_int(result, "minutes");
        seconds = db_get_field_assoc_int(result, "seconds");
		chocolate = db_get_field_assoc_int(result, "chocolate");
		db_get_field_assoc(result, "laston", lastOn, sizeof(lastOn));	
	
		new Float:ratio = (float(kills)/float(deaths));
		
		#if defined USE_DIALOG
			new string[1000], string2[128];
		
			strcat(string, ""white"");
			format(string2, sizeof(string2), "-> "green"User Name: "white"%s\n", name);
			strcat(string, string2);
			format(string2, sizeof(string2), "-> "green"User ID: "white"#%d\n", accountid);
			strcat(string, string2);
			format(string2, sizeof(string2), "-> "green"Register Date: "white"%s\n", joinDate);
			strcat(string, string2);
			format(string2, sizeof(string2), "-> "green"Total Playing Time: "white"%02d:%02d:%02d\n", hours, minutes, seconds);
			strcat(string, string2);
			format(string2, sizeof(string2), "-> "green"Admin Level: "white"(%d) %s\n", admin, GetAdminRank(admin));
			strcat(string, string2);
			format(string2, sizeof(string2), "-> "green"Chocolate Bars: "white"%d\n", chocolate);
			strcat(string, string2);
			format(string2, sizeof(string2), "-> "green"Score: "white"%d\n", score);
			strcat(string, string2);
			format(string2, sizeof(string2), "-> "green"Cash: "white"$%d\n", money);
			strcat(string, string2);
			format(string2, sizeof(string2), "-> "green"Kills: "white"%d\n", kills);
			strcat(string, string2);
			format(string2, sizeof(string2), "-> "green"Deaths: "white"%d\n", deaths);
			strcat(string, string2);
			format(string2, sizeof(string2), "-> "green"K/D (Ratio): "white"%.3f\n\n", ratio);
			strcat(string, string2);
			format(string2, sizeof(string2), ""grey"%s was last seen on "red"%s"grey".", name, lastOn);
			strcat(string, string2);

			format(string2, sizeof(string2), ""green"%s", name);
			Dialog_Show(playerid, DIALOG_BEGIN, DIALOG_STYLE_MSGBOX, string2, string, "Close", "");
		#else
			new string[128];
			SendClientMessage(playerid, COLOR_GREEN, "_________________________________________________________________________________");
			SendClientMessage(playerid, -1, "User's Statistics...");
			format(string, sizeof(string), "%s - UserID: %d | Registration Date: %s | Total Time: %02d:%02d:%02d", name, accountid, joinDate, hours, minutes, seconds);
			SendClientMessage(playerid, COLOR_GREEN, string);
			format(string, sizeof(string), "Admin Level: (%d) %s | Chocolates: %d | Score: %d | Cash: $%d | Kills: %d | Deaths: %d | K/D: %.3f", admin, GetAdminRank(admin), chocolate, score, money, kills, deaths, ratio);
			SendClientMessage(playerid, COLOR_GREEN, string);
			format(string, sizeof(string), "%s was last seen on "red"%s"grey".", name, lastOn);
			SendClientMessage(playerid, COLOR_GREY, string);
			SendClientMessage(playerid, COLOR_GREEN, "_________________________________________________________________________________");
		#endif
	}
	else 
	{
		format(query, sizeof(query), "* '%s' is not found in the player's database.", name);
		SendClientMessage(playerid, COLOR_RED, query);
	}
	db_free_result(result);
	return 1;
}

function:ShowStatistics(playerid, playerid2)
{
	if(playerid2 == INVALID_PLAYER_ID) return 1; //Do not proceed.

	new temp, hours, minutes, seconds;
	temp = (gettime()-User[playerid2][accountGameEx]) % 3600;
	hours = (gettime() - User[playerid2][accountGameEx] - temp) / 3600;
	minutes = (temp - (temp % 60)) / 60;
	seconds = temp % 60;
	new Float:ratio = (float(User[playerid2][accountKills])/float(User[playerid2][accountDeaths]));
	
	#if defined USE_DIALOG
		new string[1000], string2[128];
	
		strcat(string, ""white"");
		format(string2, sizeof(string2), "-> "green"User Name: "white"%s (ID: %d)\n", pName(playerid2), playerid2);
		strcat(string, string2);
		format(string2, sizeof(string2), "-> "green"User ID: "white"#%d\n", User[playerid2][accountID]);
		strcat(string, string2);
		format(string2, sizeof(string2), "-> "green"Register Date: "white"%s\n", User[playerid2][accountDate]);
		strcat(string, string2);
		format(string2, sizeof(string2), "-> "green"Online Time: "white"%02d:%02d:%02d\n", hours, minutes, seconds);
		strcat(string, string2);
		format(string2, sizeof(string2), "-> "green"Total Playing Time: "white"%02d:%02d:%02d\n", User[playerid2][accountGame][2], User[playerid2][accountGame][1], User[playerid2][accountGame][0]);
		strcat(string, string2);
		format(string2, sizeof(string2), "-> "green"Admin Level: "white"(%d) %s\n", User[playerid2][accountAdmin], GetAdminRank(User[playerid2][accountAdmin]));
		strcat(string, string2);
		format(string2, sizeof(string2), "-> "green"Chocolate Bars: "white"%d\n", User[playerid2][accountChocolate]);
		strcat(string, string2);
		format(string2, sizeof(string2), "-> "green"Score: "white"%d\n", GetPlayerScore(playerid2));
		strcat(string, string2);
		format(string2, sizeof(string2), "-> "green"Cash: "white"$%d\n", GetPlayerMoney(playerid2));
		strcat(string, string2);
		format(string2, sizeof(string2), "-> "green"Kills: "white"%d\n", User[playerid2][accountKills]);
		strcat(string, string2);
		format(string2, sizeof(string2), "-> "green"Deaths: "white"%d\n", User[playerid2][accountDeaths]);
		strcat(string, string2);
		format(string2, sizeof(string2), "-> "green"K/D (Ratio): "white"%.3f\n", ratio);
		strcat(string, string2);

		format(string2, sizeof(string2), ""lightblue"%s", pName(playerid2));
		Dialog_Show(playerid, DIALOG_BEGIN, DIALOG_STYLE_MSGBOX, string2, string, "Close", "");
	#else
		new string[128];
		SendClientMessage(playerid, COLOR_GREEN, "_________________________________________________________________________________");
		SendClientMessage(playerid, -1, "User's Statistics...");
		format(string, sizeof(string), "%s (ID: %d) - UserID: %d | Registration Date: %s | Online Time: %02d:%02d:%02d", pName(playerid2), playerid2, User[playerid2][accountID], User[playerid2][accountDate], hours, minutes, seconds);
		SendClientMessage(playerid, COLOR_GREEN, string);
		format(string, sizeof(string), "Admin Level: (%d) %s | Chocolates: %d | Score: %d | Cash: $%d | Kills: %d | Deaths: %d | K/D: %.3f", User[playerid2][accountAdmin], GetAdminRank(User[playerid2][accountAdmin]), User[playerid2][accountChocolate], GetPlayerScore(playerid2), GetPlayerMoney(playerid2), User[playerid2][accountKills], User[playerid2][accountDeaths], ratio);
		SendClientMessage(playerid, COLOR_GREEN, string);
		format(string, sizeof(string), "Total Time: %02d:%02d:%02d", User[playerid2][accountGame][2], User[playerid2][accountGame][1], User[playerid2][accountGame][0]);
		SendClientMessage(playerid, COLOR_GREEN, string);
		SendClientMessage(playerid, COLOR_GREEN, "_________________________________________________________________________________");
	#endif
	return 1;
}

function:KickMe(playerid) return Kick(playerid);
stock KickDelay(playerid) return SetTimerEx("KickMe", 800, false, "d", playerid);

stock ReturnUser(text[], playerid = INVALID_PLAYER_ID)
{
	new pos = 0;
	while (text[pos] < 0x21)
	{
		if (text[pos] == 0) return INVALID_PLAYER_ID;
		pos++;
	}

	new userid = INVALID_PLAYER_ID;
	if (isnumeric(text[pos]))
	{
		userid = strval(text[pos]);
		if (userid >=0 && userid < MAX_PLAYERS)
		{
			if(!IsPlayerConnected(userid))
			userid = INVALID_PLAYER_ID;
			else return userid;
		}
	}

	new len = strlen(text[pos]);
	new count = 0;
	new pname[MAX_PLAYER_NAME];

	for (new i = 0; i < MAX_PLAYERS; i++)
	{
		if (IsPlayerConnected(i))
		{
			GetPlayerName(i, pname, sizeof (pname));
			if (strcmp(pname, text[pos], true, len) == 0)
			{
				if (len == strlen(pname)) return i;
				else
				{
					count++;
					userid = i;
				}
			}
		}
	}

	if (count != 1)
	{
		if (playerid != INVALID_PLAYER_ID)
		{
			if (count) SendClientMessage(playerid, COLOR_WHITE, "Enter the full name of the user.");
			else SendClientMessage(playerid, COLOR_GREY, "No results found for the specified phrase.");
		}
		userid = INVALID_PLAYER_ID;
	}
	return userid;
}

stock Deploy_Label(playerid, color, label[], Float:distance, seethrough)
{
	new string[160];
	for(new i; i < MAX_DEPLOYABLE_LABEL; i++) if(!lInfo[i][label3D])
	{
		GetPlayerPos(playerid, lInfo[i][labelX], lInfo[i][labelY], lInfo[i][labelZ]);
		lInfo[i][labelInterior] = GetPlayerInterior(playerid);
		lInfo[i][labelVW] = GetPlayerVirtualWorld(playerid);
		lInfo[i][labelTaken] = true;
	    format(string, sizeof(string), "{FFFFFF}(Label ID %d)\n{%06x}%s", i + 1, color >>> 8, label);
		lInfo[i][label3D] = CreateDynamic3DTextLabel(string, color, lInfo[i][labelX], lInfo[i][labelY], lInfo[i][labelZ], distance, .testlos = seethrough, .worldid = lInfo[i][labelVW], .interiorid = lInfo[i][labelInterior]);
		return i;
	}
	return -1;
}

stock loadb()
{
	new string[128 * 10];

    Database = db_open(_DB_);
    
    // Users Table
    strcat(string, "CREATE TABLE IF NOT EXISTS `users` ");
    strcat(string, "(");
	strcat(string, "`userid` INTEGER PRIMARY KEY AUTOINCREMENT, `username` STRING, `IP` STRING, `joindate` STRING, `password` STRING, `admin` INTEGER DEFAULT 0, ");
    strcat(string, "`kills` INTEGER DEFAULT 0, `deaths` INTEGER DEFAULT 0, `score` INTEGER DEFAULT 0, `money` INTEGER DEFAULT 0, `warn` INTEGER DEFAULT 0, ");
    strcat(string, "`mute` INTEGER DEFAULT 0, `mutesec` INTEGER DEFAULT 0, `cmute` INTEGER DEFAULT 0, `cmutesec` INTEGER DEFAULT 0, `jail` INTEGER DEFAULT 0, `jailsec` INTEGER DEFAULT 0, ");
    strcat(string, "`hours` INTEGER DEFAULT 0, `minutes` INTEGER DEFAULT 0, `seconds` INTEGER DEFAULT 0, `question` STRING DEFAULT 'none', `answer` STRING DEFAULT 'none'");
	strcat(string, ")");
	db_query(Database, string);
	// Adding more column without deleting the table for old users of JakAdmin - COLUMN: chocolate, useskin (INTEGER DEFAULT 0) skin (INTEGER DEFAULT: -1)
	db_query(Database, "ALTER TABLE `users` ADD COLUMN `chocolate` INTEGER DEFAULT 0");
	db_query(Database, "ALTER TABLE `users` ADD COLUMN `skin` INTEGER DEFAULT -1");
	db_query(Database, "ALTER TABLE `users` ADD COLUMN `useskin` INTEGER DEFAULT 0");
	db_query(Database, "ALTER TABLE `users` ADD COLUMN `togpm` INTEGER DEFAULT 1");
	db_query(Database, "ALTER TABLE `users` ADD COLUMN `cage` INTEGER DEFAULT 0");
	db_query(Database, "ALTER TABLE `users` ADD COLUMN `laston` STRING DEFAULT '01.01.1970 00:00:00'");
	// Remove this code if you already have the column CHOCOLATE, USESKIN, SKIN in your database to prevent having a SQL error "duplicate" thing

	// Bans Table
	db_query(Database, "CREATE TABLE IF NOT EXISTS `bans` (`banid` INTEGER PRIMARY KEY AUTOINCREMENT, `username` STRING, `ip` STRING, `banby` STRING, `banreason` STRING, `banwhen` STRING)");
	db_query(Database, "ALTER TABLE `bans` ADD COLUMN `temporary_ban` INTEGER DEFAULT 0");
	
	// Notes System
	db_query(Database, "CREATE TABLE IF NOT EXISTS `notes` (`noteid` INTEGER PRIMARY KEY AUTOINCREMENT, `username` STRING, `admin` STRING, `note` STRING, `date` STRING)");

	// IP System
	db_query(Database, "CREATE TABLE IF NOT EXISTS `ips` (`username` STRING, `ip` STRING, `date` STRING, `time` STRING)");

	// Breach System
	db_query(Database, "CREATE TABLE IF NOT EXISTS `breach` (`username` STRING, `ip` STRING, `type` INTEGER, `date` STRING, `time` STRING)");

	// AKA System
	#if defined USE_AKA
		db_query(Database, "CREATE TABLE IF NOT EXISTS `aka` (`ip` STRING, `name` STRING)");
	#endif
	return 1;
}

stock closedb() return db_close(Database);

stock CheckAccount(name[])
{
	new query[128], DBResult:result, id;
	format(query, sizeof(query), "SELECT `userid` FROM `users` WHERE `username` = '%s'", DB_Escape(name));
	result = db_query(Database, query);

	if(db_num_rows(result))
	{
	    id = db_get_field_assoc_int(result, "userid");
	}
	db_free_result(result);
	return id;
}

function:SaveData(playerid)
{
	new l_day, l_month, l_year, l_hour, l_minute, l_second;
    static Query[128 * 15];
	Query[0] = 0;
	
	getdate(l_year, l_month, l_day);
	gettime(l_hour, l_minute, l_second);
	
	format(User[playerid][accountLastOn], 32, "%02d.%02d.%d %02d:%02d:%02d", l_month, l_day, l_year, l_hour, l_minute, l_second);

	if(User[playerid][accountLogged])
	{
		format(Query, sizeof(Query), "UPDATE `users` SET `IP` = '%s', `admin` = %d, `kills` = %d, `deaths` = %d, `score` = %d, `money` = %d, `warn` = %d, `mute` = %d, `mutesec` = %d, `cmute` = %d, `cmutesec` = %d, `jail` = %d, `jailsec` = %d, `hours` = %d, `minutes` = %d, `seconds` = %d, `question` = '%s', `answer` = '%s', `chocolate` = %d, `skin` = %d, `useskin` = %d, `togpm` = %d, `cage` = %d, `laston` = '%s' WHERE `username` = '%s'",
				DB_Escape(User[playerid][accountIP]),
				User[playerid][accountAdmin],
				User[playerid][accountKills],
				User[playerid][accountDeaths],
				GetPlayerScore(playerid),
				GetPlayerMoney(playerid),
				User[playerid][accountWarn],
				User[playerid][accountMuted],
				User[playerid][accountMuteSec],
				User[playerid][accountCMuted],
				User[playerid][accountCMuteSec],
				User[playerid][accountJail],
				User[playerid][accountJailSec],
				User[playerid][accountGame][2],
				User[playerid][accountGame][1],
				User[playerid][accountGame][0],
				DB_Escape(User[playerid][accountQuestion]),
				DB_Escape(User[playerid][accountAnswer]),
				User[playerid][accountChocolate],
				User[playerid][accountSkin],
				User[playerid][accountUseSkin],
				User[playerid][accountPM],
				User[playerid][accountCage],
				DB_Escape(User[playerid][accountLastOn]),
				DB_Escape(User[playerid][accountName])
		);

	    db_query(Database, Query);
	}
	return 1;
}

stock getIP(playerid)
{
	new twerp[20];
	GetPlayerIp(playerid, twerp, 20);
	return twerp;
}

stock GetWeaponIDFromName(WeaponName[])
{
	if(strfind("molotov", WeaponName, true) != -1) return 18;
	for(new i = 0; i <= 46; i++)
	{
		switch(i)
		{
			case 0,19,20,21,44,45: continue;
			default:
			{
				new name[32]; GetWeaponName(i,name,32);
				if(strfind(name,WeaponName,true) != -1) return i;
			}
		}
	}
	return -1;
}

function:RegisterPlayer(playerid, password[])
{
    SetPlayerScore(playerid, STARTING_SCORE);
    GivePlayerMoney(playerid, STARTING_CASH);

    //Time = Hours, Time2 = Minutes, Time3 = Seconds
    new time, time2, time3;
    gettime(time, time2, time3);
    new date, date2, date3;
    //Date = Month, Date2 = Day, Date3 = Year
    getdate(date3, date, date2);

    format(User[playerid][accountDate], 64, "%02d/%02d/%d %02d:%02d:%02d", date, date2, date3, time, time2, time3);

    format(User[playerid][accountQuestion], 129, "none");
    format(User[playerid][accountAnswer], 129, "none");

	static query[128 * 3];
	query[0] = 0;

    format(query, sizeof(query), "INSERT INTO `users` (`username`, `IP`, `joindate`, `password`) VALUES ('%s', '%s', '%s', '%s')", DB_Escape(pName(playerid)), DB_Escape(User[playerid][accountIP]), DB_Escape(User[playerid][accountDate]), DB_Escape(password));
	db_query(Database, query);

	User[playerid][accountLogged] = true;

	PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);

    new DBResult: result;
    result = db_query(Database, "SELECT last_insert_rowid()");
    User[playerid][accountID] = db_get_field_int(result);
    db_free_result(result);

	SendClientMessage(playerid, COLOR_GREEN, "You have successfully registered from the server.");

	Dialog_Show(playerid, DIALOG_WOULDYOU, DIALOG_STYLE_MSGBOX, "Would you like to...", "Would you like us to set your account a security question?\n\n* This can be used to recover your account in-case you have forgotten your password.", "Yes", "No");
	return 1;
}

function:LoginPlayer(playerid)
{
    new Query[900], DBResult:Result;
	static string[900];
	string[0] = 0;
	
    format(Query, sizeof(Query), "SELECT * FROM `users` WHERE `username` = '%s'", DB_Escape(pName(playerid)));
    Result = db_query(Database, Query);
    if(db_num_rows(Result))
    {
        User[playerid][accountID] = db_get_field_assoc_int(Result, "userid");

        SetPlayerScore(playerid, db_get_field_assoc_int(Result, "score"));
        GivePlayerMoney(playerid, db_get_field_assoc_int(Result, "money"));

        User[playerid][accountKills] = db_get_field_assoc_int(Result, "kills");
        User[playerid][accountDeaths] = db_get_field_assoc_int(Result, "deaths");
        User[playerid][accountAdmin] = db_get_field_assoc_int(Result, "admin");
		db_get_field_assoc(Result, "joindate", User[playerid][accountDate], 64);

        User[playerid][accountWarn] = db_get_field_assoc_int(Result, "warn");
        User[playerid][accountMuted] = db_get_field_assoc_int(Result, "mute");
        User[playerid][accountMuteSec] = db_get_field_assoc_int(Result, "mutesec");
        User[playerid][accountCMuted] = db_get_field_assoc_int(Result, "cmute");
        User[playerid][accountCMuteSec] = db_get_field_assoc_int(Result, "cmutesec");
        User[playerid][accountJail] = db_get_field_assoc_int(Result, "jail");
        User[playerid][accountJailSec] = db_get_field_assoc_int(Result, "jailsec");
        User[playerid][accountGame][2] = db_get_field_assoc_int(Result, "hours");
        User[playerid][accountGame][1] = db_get_field_assoc_int(Result, "minutes");
        User[playerid][accountGame][0] = db_get_field_assoc_int(Result, "seconds");
        User[playerid][accountChocolate] = db_get_field_assoc_int(Result, "chocolate");
        User[playerid][accountSkin] = db_get_field_assoc_int(Result, "skin");
        User[playerid][accountUseSkin] = db_get_field_assoc_int(Result, "useskin");
        User[playerid][accountPM] = db_get_field_assoc_int(Result, "togpm");
        User[playerid][accountCage] = db_get_field_assoc_int(Result, "cage");
		
		db_get_field_assoc(Result, "laston", User[playerid][accountLastOn], 32);

		User[playerid][accountLogged] = true;

		if(User[playerid][accountMuted] == 1)
		{
		    format(string, sizeof(string), "** You have been muted from using the chat for %d seconds, You are muted the last time you logged out.", User[playerid][accountMuteSec]);
		    SendClientMessage(playerid, COLOR_RED, string);
		}
		if(User[playerid][accountCMuted] == 1)
		{
		    format(string, sizeof(string), "** You have been muted from using the commands for %d seconds, You are muted the last time you logged out.", User[playerid][accountCMuteSec]);
		    SendClientMessage(playerid, COLOR_RED, string);
		}

		SendClientMessage(playerid, COLOR_YELLOW, "SERVER: You have successfully logged in to the server.");
		if(User[playerid][accountAdmin] >= 1)
		{
		    format(string, sizeof(string), "* You have logged in the server as %s.", GetAdminRank(User[playerid][accountAdmin]));
		    SendClientMessage(playerid, -1, string);
		}
		
		format(string, sizeof(string), "Welcome Back, %s!\nYou have logged in to the server, your last login was %s.\n\n"white"Admin Level: "green"(%d)\n\n"white"Score: %d\nCash: $%d\n\n"grey"You may close this dialouge.", pName(playerid), User[playerid][accountLastOn], User[playerid][accountAdmin], GetPlayerScore(playerid), GetPlayerMoney(playerid));
		Dialog_Show(playerid, DIALOG_BEGIN, DIALOG_STYLE_MSGBOX, ""lightblue"Welcome Back!", string, "Close", ""); 

		PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
    }
	db_free_result(Result);
    return 1;
}

function:IsValidPassword( const password[ ] )
{
    for( new i = 0; password[ i ] != EOS; ++i )
    {
        switch( password[ i ] )
        {
            case '0'..'9', 'A'..'Z', 'a'..'z': continue;
            default: return 0;
        }
    }
    return 1;
}

stock DB_Escape(text[])
{
    new
        ret[80* 2],
        ch,
        i,
        j;
    while ((ch = text[i++]) && j < sizeof (ret))
    {
        if (ch == '\'')
        {
            if (j < sizeof (ret) - 2)
            {
                ret[j++] = '\'';
                ret[j++] = '\'';
            }
        }
        else if (j < sizeof (ret))
        {
            ret[j++] = ch;
        }
        else
        {
            j++;
        }
    }
    ret[sizeof (ret) - 1] = '\0';
    return ret;
}

stock CheckBan(ip[])
{
	new string[20];
    new File: file = fopen("JakAdmin/ban.ini", io_read);
	while(fread(file, string))
	{
	    if (strcmp(ip, string, true, strlen(ip)) == 0)
	    {
	        fclose(file);
	        return 1;
	    }
	}
	fclose(file);
	return 0;
}

stock AddBan(ip[])
{
	if (!CheckBan(ip))
	{
		new File: file = fopen("JakAdmin/ban.ini", io_append);
		new string[300];
		format(string, sizeof(string), "\r\n%s", ip);
	 	fwrite(file, string);
	 	fclose(file);
		return 1;
	}
	return 0;
}

stock RemoveBan(ip[])
{
    if (CheckBan(ip))
	{
	    new string[20];
		new File: file = fopen("JakAdmin/ban.ini", io_read);
		new File: file2 = fopen("JakAdmin/tempBan.ini", io_append);
		while(fread(file, string))
		{
			if (strcmp(ip, string, true, strlen(ip)) != 0 && strcmp("\r\n", string) != 0)
		    {
				fwrite(file2, string);
			}
		}
		fclose(file);
		fclose(file2);
		file = fopen("JakAdmin/ban.ini", io_write);
		file2 = fopen("JakAdmin/tempBan.ini", io_read);
		while(fread(file2, string))
		{
			fwrite(file, string);
		}
		fclose(file);
		fclose(file2);
		fremove("JakAdmin/tempBan.ini");
		return 1;
    }
	return 0;
}

stock ShowBan(playerid, banid = -1, admin[] = "JakAdmin", reason[] = "69 Sex", when[] = "01/01/1970 00:00:00", days = 36135)
{
	new string[256], string2[1500];

	for(new i=0; i<100; i++)
	{
	    SendClientMessage(playerid, -1, " ");
	}

    format(string, 256, "* You are banned by %s for the following reasons:", admin);
	SendClientMessage(playerid, COLOR_RED, string);
	format(string, 256, "(( %s ))", reason);
	SendClientMessage(playerid, -1, string);
	format(string, 256, "* IP Address: [%s] - Banned Since: [%s]", User[playerid][accountIP], when);
	SendClientMessage(playerid, -1, string);
	
	strcat(string2, ""grey"");
	strcat(string2, "You are banned from this server.:\n\n");
	format(string, 256, ""white"Ban ID: "red"#%d\n", banid);
	strcat(string2, string);
	format(string, 256, ""white"Name: "red"%s\n", pName(playerid));
	strcat(string2, string);
	format(string, 256, ""white"Banned By: "red"%s\n", admin);
	strcat(string2, string);
	format(string, 256, ""white"Reason: "red"%s\n", reason);
	strcat(string2, string);
	format(string, 256, ""white"IP: "red"%s\n", User[playerid][accountIP]);
	strcat(string2, string);
	format(string, 256, ""white"Banned since: "red"%s\n", when);
	strcat(string2, string);
	if(days == 36135 || days == 340703845)
	{
		format(string, 256, ""white"Expires in: "red"Never\n\n");
		strcat(string2, string);	
	}
	else
	{
		new datestring[32];
		datestring = ConvertTimestamp(days, 4);
		format(string, 256, ""white"Expires in: "red"%s\n\n", datestring);
		strcat(string2, string);		
	}
	strcat(string2, ""grey"");
	strcat(string2, "If you think this is an error or a false ban, submit a ban appeal on forums.\n");
	strcat(string2, "Press F8 to take a quick-screenshot of your ban details.");

	Dialog_Show(playerid, DIALOG_BEGIN, DIALOG_STYLE_MSGBOX, ""red"You are banned from this server.", string2, "Close", "");
	return 1;
}

stock UnbanAccountEx(playerid)
{
    new string[128], DBResult:Result, Query[129], fIP[30];
	
    format(Query, sizeof(Query), "SELECT * FROM `bans` WHERE `username` = '%s'", pName(playerid));
	Result = db_query(Database, Query);

	if(db_num_rows(Result))
	{
    	db_get_field_assoc(Result, "ip", fIP, 30);
		RemoveBan(fIP);

        format(Query, sizeof(Query), "DELETE FROM `bans` WHERE `username` = '%s'", DB_Escape(pName(playerid)));
	    db_query(Database, Query);

		format(string, sizeof string, "** %s temporary-ban has expired.", pName(playerid));
		SendAdmin(COLOR_GREEN, string);
		print(string);
		SaveLog("banlog.txt", string);

		OnPlayerConnect(playerid); 
		SendClientMessage(playerid, COLOR_GREEN, "Your temporary ban has expired.");
	}
	db_free_result(Result);
	return 1;
}

stock UnbanAccount(playerid, name[])
{
    new string[128], DBResult:Result, Query[129], fIP[30];
    format(Query, sizeof(Query), "SELECT * FROM `bans` WHERE `username` = '%s'", name);
	Result = db_query(Database, Query);

	if(db_num_rows(Result))
	{
    	db_get_field_assoc(Result, "ip", fIP, 30);
		RemoveBan(fIP);

        format(Query, sizeof(Query), "DELETE FROM `bans` WHERE `username` = '%s'", DB_Escape(name));
	    db_query(Database, Query);

		format(string, sizeof string, "ADMIN: %s (IP: %s) was unbanned by %s.", name, fIP, pName(playerid));
		SendAdmin(COLOR_GREEN, string);
		print(string);
		SaveLog("banlog.txt", string);
	}
	else
	{
		format(string, sizeof(string), "* Account: %s is not in the database.", name);
	    SendClientMessage(playerid, COLOR_RED, string);
	}
	db_free_result(Result);
	return 1;
}

stock BanAccountEx(name[], ip[], admin[] = "Anticheat", reason[] = "None", days = 36135)
{
	new Query[500], ban_hr, ban_min, ban_sec, ban_month, ban_days, ban_years, when[32], daysFinal;
	daysFinal = gettime() + 60*60*24*days;
	if(!days) daysFinal = 340703845;
	
	gettime(ban_hr, ban_min, ban_sec);
	getdate(ban_years, ban_month, ban_days);

	format(when, sizeof(when), "%02d/%02d/%d %02d:%02d:%02d", ban_month, ban_days, ban_years, ban_hr, ban_min, ban_sec);

	AddBan(ip);
	
	format(Query, sizeof(Query), "INSERT INTO `bans` (`username`, `ip`, `banby`, `banreason`, `banwhen`, `temporary_ban`) VALUES ('%s', '%s', '%s', '%s', '%s', %d)", DB_Escape(name), DB_Escape(ip), DB_Escape(admin), DB_Escape(reason), DB_Escape(when), daysFinal);
	db_query(Database, Query);
	return 1;
}

stock BanAccount(playerid, admin[] = "Anticheat", reason[] = "None", days = 36135)
{
	new Query[500], DBResult:result, ban_hr, ban_min, ban_sec, ban_month, ban_days, ban_years, when[32], daysFinal;
	daysFinal = gettime() + 60*60*24*days;
	if(!days) daysFinal = 340703845;
	
	gettime(ban_hr, ban_min, ban_sec);
	getdate(ban_years, ban_month, ban_days);

	format(when, sizeof(when), "%02d/%02d/%d %02d:%02d:%02d", ban_month, ban_days, ban_years, ban_hr, ban_min, ban_sec);

	AddBan(User[playerid][accountIP]);

	format(Query, sizeof(Query), "INSERT INTO `bans` (`username`, `ip`, `banby`, `banreason`, `banwhen`, `temporary_ban`) VALUES ('%s', '%s', '%s', '%s', '%s', %d)", DB_Escape(pName(playerid)), DB_Escape(User[playerid][accountIP]), DB_Escape(admin), DB_Escape(reason), DB_Escape(when), daysFinal);
	db_query(Database, Query);

    result = db_query(Database, "SELECT last_insert_rowid()");
    SetPVarInt(playerid, "ban_id", db_get_field_int(result));
    db_free_result(result);
	return 1;
}

function:IsValidWeapon(weaponid)
{
    if (weaponid > 0 && weaponid < 19 || weaponid > 21 && weaponid < 47) return 1;
    return 0;
}

function:SaveLog(filename[], text[])
{
	if(!ServerInfo[SaveLogs])
	    return 0;

	new string[256];

	if(!fexist(_LOG_))
	{
	    printf("[JakAdmin] Unable to overwrite '%s' at the '%s', '%s' missing.", filename, _LOG_, _LOG_);
	    print("No logs has been saved to your server database.");
	    
	    format(string, sizeof string, "JakAdmin has attempted to overwrite '%s' at the '%s' which is missing.", filename, _LOG_);
	    SendAdmin(COLOR_RED, string);
	    return SendAdmin(-1, "No logs has been saved to the server database, Check the console for further solution.");
	}
	
	new File:file, filepath[128];

	new year, month, day;
	new hour, minute, second;

	getdate(year, month, day);
	gettime(hour, minute, second);
	format(filepath, sizeof(filepath), ""_LOG_"%s", filename);
	file = fopen(filepath, io_append);
	format(string, sizeof(string),"[%02d/%02d/%02d | %02d:%02d:%02d] %s\r\n", month, day, year, hour, minute, second, text);
	fwrite(file, string);
	fclose(file);
	return 1;
}

stock VehicleOccupied(vehicleid)
{
	foreach(new i : Player) if(IsPlayerInVehicle(i, vehicleid))
    {
        return 1;
    }
    return 0;
}

stock DataExist(name[])
{
	new Buffer[180],
		Entry,
		DBResult:Result
	;

	format(Buffer, sizeof(Buffer), "SELECT `userid` FROM `users` WHERE `username` = '%s'", name);
	Result = db_query(Database, Buffer);

	if(db_num_rows(Result))
	{
		Entry = 1;
		db_free_result(Result);
	}
	else Entry = 0;
	return Entry;
}

stock SendAdmin(color, string[])
{
	foreach(new i : Player) if(User[i][accountAdmin] > 0)
	{
		SendClientMessage(i, color, string);
	}
	return 1;
}

stock StartSpectate(playerid, specplayerid)
{
	SetPlayerInterior(playerid, GetPlayerInterior(specplayerid));
	TogglePlayerSpectating(playerid, 1);

	if(IsPlayerInAnyVehicle(specplayerid))
	{
		PlayerSpectateVehicle(playerid, GetPlayerVehicleID(specplayerid));
		User[playerid][SpecID] = specplayerid;
		User[playerid][SpecType] = ADMIN_SPEC_TYPE_VEHICLE;
	}
	else
	{
		PlayerSpectatePlayer(playerid, specplayerid);
		User[playerid][SpecID] = specplayerid;
		User[playerid][SpecType] = ADMIN_SPEC_TYPE_PLAYER;
	}
	return 1;
}

stock StopSpectate(playerid)
{
	TogglePlayerSpectating(playerid, 0);
	User[playerid][SpecID] = INVALID_PLAYER_ID;
	User[playerid][SpecType] = ADMIN_SPEC_TYPE_NONE;
	GameTextForPlayer(playerid,"~n~~n~~n~~w~Spectate mode ended",1000,3);
	return 1;
}

stock AdvanceSpectate(playerid)
{
	if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING && User[playerid][SpecID] != INVALID_PLAYER_ID)
	{
		for(new id = User[playerid][SpecID] + 1, j = GetPlayerPoolSize(); id <= j; id++) 
		{
			if(playerid == id) continue;
			
			if(GetPlayerState(id) == PLAYER_STATE_SPECTATING && User[id][SpecID] != INVALID_PLAYER_ID || (GetPlayerState(id) != 1 && GetPlayerState(id) != 2 && GetPlayerState(id) != 3))
			{
				continue;
			}
			else
			{
				if(IsPlayerConnected(id)) 
				{
					StartSpectate(playerid, id);
					break;

				} 
				else 
				{
					continue;
				}
			}
		}	
	}
	return 1;
}

stock ReverseSpectate(playerid)
{
	if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING && User[playerid][SpecID] != INVALID_PLAYER_ID)
	{
		for(new id = User[playerid][SpecID] - 1; id >= 0; id-- )
		{
			if(playerid == id) continue;

			if(GetPlayerState(id) == PLAYER_STATE_SPECTATING && User[id][SpecID] != INVALID_PLAYER_ID || (GetPlayerState(id) != 1 && GetPlayerState(id) != 2 && GetPlayerState(id) != 3))
			{
				continue;
			}
			else
			{
				if(IsPlayerConnected(id)) 
				{
					StartSpectate(playerid, id);
					break;

				} 
				else 
				{
					continue;
				}
			}
		}	
	}
	return 1;
}

stock GetVehicleModelIDFromName(vname[])
{
	for(new i = 0; i < 211; i++)
	{
		if ( strfind(VehicleNames[i], vname, true) != -1 )
		return i + 400;
	}
	return -1;
}

function:EraseVeh(vehicleid)
{
    foreach(new i : Player) if(IsPlayerInVehicle(i, vehicleid))
	{
        new Float:X, Float:Y, Float:Z;
		RemovePlayerFromVehicle(i);
		GetPlayerPos(i, X, Y, Z);
		SetPlayerPos(i, X, Y+3, Z);
	}
    SetTimerEx("VehRes", 1500, 0, "i", vehicleid);
}

function:DelVehicle(vehicleid)
{
    foreach(new players : Player) if(IsPlayerInVehicle(players, vehicleid))
    {
        new Float:X, Float:Y, Float:Z;
		GetPlayerPos(players, X, Y, Z);
		SetPlayerPos(players, X, Y, Z+2);
		SetVehicleToRespawn(vehicleid);
    }
    SetTimerEx("VehRes", 3000, 0, "d", vehicleid);
    return 1;
}

stock Config(form = 0, playerid = INVALID_PLAYER_ID)
{
	new string[128];

	if(!form)
	{
		print("\n****************************************************************");
		print("Jake's Admin System 4.0 Configuration...");
		printf("Registration Optional: %s | SaveLogs: %s | AutoLogin: %s | ReadCmd: %s", (ServerInfo[RegisterOption]) ? ("Yes") : ("No"), (ServerInfo[SaveLogs]) ? ("Yes") : ("No"), (ServerInfo[AutoLogin]) ? ("Yes") : ("No"), (ServerInfo[ReadCmds]) ? ("Yes") : ("No"));
		printf("ReadCmdMode: %s | LogTires: %d | SecurityQuesTires: %d", (ServerInfo[ReadCmd]) ? ("Spectate") : ("Normal"), ServerInfo[LoginWarn], ServerInfo[SecureWarn]);
		printf("AntiName: %s | AntiAd: %s | AntiSpam: %s | ReadPM: %s", (ServerInfo[AntiName]) ? ("Yes") : ("No"), (ServerInfo[AntiAd]) ? ("Yes") : ("No"), (ServerInfo[AntiSpam]) ? ("Yes") : ("No"), (ServerInfo[ReadPMs]) ? ("Yes") : ("No"));
		printf("AntiSwear: %s | TabKick: %d | IdleKick: %d", (ServerInfo[AntiSwear]) ? ("Yes") : ("No"), ServerInfo[TabTime], ServerInfo[AFKTime]);		
		printf("Admin: (1) %s, (2) %s, (3) %s, (4) %s, (5) %s", ServerInfo[AdminRank1], ServerInfo[AdminRank2], ServerInfo[AdminRank3], ServerInfo[AdminRank4], ServerInfo[AdminRank5]);
		print("****************************************************************");
	}
	else
	{
		SendClientMessage(playerid, -1, "________________________________________________________________");
		SendClientMessage(playerid, -1, " ");
		SendClientMessage(playerid, COLOR_GREEN, "JakAdmin Configurations...");
		format(string, sizeof(string), "Registration Optional: %s | SaveLogs: %s | AutoLogin: %s | ReadCmd: %s", (ServerInfo[RegisterOption]) ? ("Yes") : ("No"), (ServerInfo[SaveLogs]) ? ("Yes") : ("No"), (ServerInfo[AutoLogin]) ? ("Yes") : ("No"), (ServerInfo[ReadCmds]) ? ("Yes") : ("No"));
		SendClientMessage(playerid, COLOR_LIGHTBLUE, string);
		format(string, sizeof(string), "ReadCmdMode: %s | LogTires: %d | SecurityQuesTires: %d", (ServerInfo[ReadCmd]) ? ("Spectate") : ("Normal"), ServerInfo[LoginWarn], ServerInfo[SecureWarn]);
		SendClientMessage(playerid, COLOR_LIGHTBLUE, string);
		format(string, sizeof(string), "AntiName: %s | AntiAd: %s | AntiSpam: %s | ReadPM: %s", (ServerInfo[AntiName]) ? ("Yes") : ("No"), (ServerInfo[AntiAd]) ? ("Yes") : ("No"), (ServerInfo[AntiSpam]) ? ("Yes") : ("No"), (ServerInfo[ReadPMs]) ? ("Yes") : ("No"));
		SendClientMessage(playerid, COLOR_LIGHTBLUE, string);
		format(string, sizeof(string), "AntiSwear: %s | TabKick: %d | IdleKick: %d", (ServerInfo[AntiSwear]) ? ("Yes") : ("No"), ServerInfo[TabTime], ServerInfo[AFKTime]);
		SendClientMessage(playerid, COLOR_LIGHTBLUE, string);
		if(User[playerid][accountAdmin] >= 4)
		{
			format(string, sizeof(string), "Admin: (1) %s, (2) %s, (3) %s, (4) %s, (5) %s", ServerInfo[AdminRank1], ServerInfo[AdminRank2], ServerInfo[AdminRank3], ServerInfo[AdminRank4], ServerInfo[AdminRank5]);
			SendClientMessage(playerid, COLOR_ORANGE, string);
		}
		SendClientMessage(playerid, -1, "________________________________________________________________");
	}
	return 1;
}

function:VehRes(vehicleid)
{
    DestroyVehicle(vehicleid);
}

function:checkfolder()
{
	if(!fexist("JakAdmin/"))
	{
		print("\n[JakAdmin] JakAdmin folder doesn't exist in scriptfiles, JakAdmin won't start.");
		print("Solution: Create the folder JakAdmin on the scriptfiles.");
		return print("Continusly using the script with the missing file will not save the target script objective.\n");
	}
	if(!fexist("JakAdmin/Logs/"))
	{
		print("\n[JakAdmin] Logs folder doesn't exist in JakAdmin folder, JakAdmin won't start.");
		print("Solution: Create the folder Logs on the JakAdmin folder.");
		return print("Continusly using the script with the missing file will not save the target script objective.\n");
	}
	////////////////////////////////////////////////////////////////////////////

	if(!fexist("JakAdmin/config.ini"))
	{
		print("\n[JakAdmin] config.ini doesn't exist, JakAdmin has created it for you.");
		print("[JakAdmin] config.ini has the default values setted on it, modify it your own.\n");

		new INI:file = INI_Open("JakAdmin/config.ini");
		/////
		INI_WriteInt(file, "RegisterOption", 0);
		ServerInfo[RegisterOption] = 0;
		/////
		INI_WriteInt(file, "SaveLog", 1);
		ServerInfo[SaveLogs] = 1;
		/////
		INI_WriteInt(file, "LoginWarn", 3);
		ServerInfo[LoginWarn] = 3;
		/////
		INI_WriteInt(file, "SecureWarn", 3);
		ServerInfo[SecureWarn] = 3;
		/////
		INI_WriteInt(file, "AutoLogin", 0);
		ServerInfo[AutoLogin] = 0;
		/////
		INI_WriteInt(file, "ReadCmds", 1);
		ServerInfo[ReadCmds] = 1;
		/////
		INI_WriteInt(file, "ReadCmd", 0);
		ServerInfo[ReadCmd] = 0;
		/////
		INI_WriteInt(file, "MaxPing", 0);
		ServerInfo[MaxPing] = 0;
		/////
		INI_WriteInt(file, "AntiSwear", 1);
		ServerInfo[AntiSwear] = 1;
		/////
		INI_WriteInt(file, "AntiName", 1);
		ServerInfo[AntiName] = 1;
		/////
		INI_WriteInt(file, "AntiAd", 1);
		ServerInfo[AntiAd] = 1;
		/////
		INI_WriteInt(file, "AntiSpam", 0);
		ServerInfo[AntiSpam] = 0;
		/////
		INI_WriteInt(file, "TabTime", 0);
		ServerInfo[TabTime] = 0;
		/////
		INI_WriteInt(file, "AFKTime", 0);
		ServerInfo[AFKTime] = 0;
		/////
		INI_WriteInt(file, "ReadPMs", 1);
		ServerInfo[ReadPMs] = 1;
		/////
		INI_WriteInt(file, "LockChat", 0);
		ServerInfo[LockChat] = 0;
		/////
		INI_WriteInt(file, "JoinMsg", 1);
		ServerInfo[JoinMsg] = 1;
		/////
	    format(ServerInfo[AdminRank1], 32, "Moderator");
		INI_WriteString(file, "AdminRank1", ServerInfo[AdminRank1]);
	    format(ServerInfo[AdminRank2], 32, "Admin");
		INI_WriteString(file, "AdminRank2", ServerInfo[AdminRank2]);
	    format(ServerInfo[AdminRank3], 32, "Head Admin");
		INI_WriteString(file, "AdminRank3", ServerInfo[AdminRank3]);
	    format(ServerInfo[AdminRank4], 32, "Lead Admin");
		INI_WriteString(file, "AdminRank4", ServerInfo[AdminRank4]);
	    format(ServerInfo[AdminRank5], 32, "Owner");
		INI_WriteString(file, "AdminRank5", ServerInfo[AdminRank5]);
		INI_Close(file);
	}
	else if(fexist("JakAdmin/config.ini"))
	{
		INI_ParseFile("JakAdmin/config.ini", "LoadData");
	}

	LoadBadNames();
	LoadAntiSwear();
	return 1;
}

function:LoadData(name[], value[])
{
	INI_Int("RegisterOption", ServerInfo[RegisterOption]);
	INI_Int("SaveLog", ServerInfo[SaveLogs]);
	INI_Int("LoginWarn", ServerInfo[LoginWarn]);
	INI_Int("SecureWarn", ServerInfo[SecureWarn]);
	INI_Int("AutoLogin", ServerInfo[AutoLogin]);
	INI_Int("ReadCmds", ServerInfo[ReadCmds]);
	INI_Int("ReadCmd", ServerInfo[ReadCmd]);
	INI_Int("MaxPing", ServerInfo[MaxPing]);
	INI_Int("AntiSwear", ServerInfo[AntiSwear]);
	INI_Int("AntiName", ServerInfo[AntiName]);
	INI_Int("AntiAd", ServerInfo[AntiAd]);
	INI_Int("AntiSpam", ServerInfo[AntiSpam]);
	INI_Int("TabTime", ServerInfo[TabTime]);
	INI_Int("AFKTime", ServerInfo[AFKTime]);
	INI_Int("ReadPMs", ServerInfo[ReadPMs]);
	INI_Int("LockChat", ServerInfo[LockChat]);
	INI_Int("JoinMsg", ServerInfo[JoinMsg]);
	/////
	INI_String("AdminRank1", ServerInfo[AdminRank1], 32);
	INI_String("AdminRank2", ServerInfo[AdminRank2], 32);
	INI_String("AdminRank3", ServerInfo[AdminRank3], 32);
	INI_String("AdminRank4", ServerInfo[AdminRank4], 32);
	INI_String("AdminRank5", ServerInfo[AdminRank5], 32);
	return 1;
}
	
stock LoadBadNames()
{
	new File:file, string[100];

	if(fexist("JakAdmin/ForbiddenNames.cfg"))
	{
		if((file = fopen("JakAdmin/ForbiddenNames.cfg",io_read)))
		{
			while(fread(file, string))
			{
			    for(new i = 0, j = strlen(string); i < j; i++) if(string[i] == '\n' || string[i] == '\r') string[i] = '\0';
	            BadNames[BadNameCount] = string;
	            BadNameCount++;
			}
			fclose(file);
		}
	}
	else
	{
		print("\n[JakAdmin] ForbiddenNames.cfg doesn't exist, JakAdmin has created it for you.\n");
	    fcreate("JakAdmin/ForbiddenNames.cfg");
	}
	return 1;
}

stock fcreate(filename[]) 
{ 
	if(fexist(filename)) 
		return 0; 
		
	new File:file = fopen(filename, io_write); 
	return fclose(file); 
}  

stock LoadAntiSwear()
{
	new File:file, string[100];
	if(fexist("JakAdmin/ForbiddenWords.cfg"))
	{
		if((file = fopen("JakAdmin/ForbiddenWords.cfg",io_read)))
		{
			while(fread(file, string))
			{
			    for(new i = 0, j = strlen(string); i < j; i++) if(string[i] == '\n' || string[i] == '\r') string[i] = '\0';
	            ForbiddenWords[ForbiddenWordCount] = string;
	            ForbiddenWordCount++;
			}
			fclose(file);
		}
	}
	else
	{
		print("\n[JakAdmin] ForbiddenWords.cfg doesn't exist, JakAdmin has created it for you.\n");
	    fcreate("JakAdmin/ForbiddenWords.cfg");
	}
	return 1;
}

function:ShowRanks(playerid)
{
	new string[128], combine[128 * 10];
	
	strcat(combine, "Rank\tName\n");

	format(string, sizeof(string), "Admin Rank #1\t"green"%s\n", ServerInfo[AdminRank1]);
	strcat(combine, string);
	format(string, sizeof(string), "Admin Rank #2\t"red"%s\n", ServerInfo[AdminRank2]);
	strcat(combine, string);
	format(string, sizeof(string), "Admin Rank #3\t"green"%s\n", ServerInfo[AdminRank3]);
	strcat(combine, string);
	format(string, sizeof(string), "Admin Rank #4\t"red"%s\n", ServerInfo[AdminRank4]);
	strcat(combine, string);
	format(string, sizeof(string), "Admin Rank #5\t"green"%s\n", ServerInfo[AdminRank5]);
	strcat(combine, string);

	Dialog_Show(playerid, DIALOG_RANKS, DIALOG_STYLE_TABLIST_HEADERS, "Ranks Configuration", combine, "Edit", "Back");
	return 1;
}

function:ShowSettings(playerid)
{
	static string[128], combine[128 * 11];
	string[0] = 0;
	combine[0] = 0;
	
	strcat(combine, "Name\tStatus\tInfo\n");
	
	format(string, sizeof(string), "Save Log Files\t%s\tSaves a log files on the scriptfiles (tracks every admin's move)\n", (ServerInfo[SaveLogs] == 1) ? (""green"ON"white"") : (""red"OFF"white""));
	strcat(combine, string);
	format(string, sizeof(string), "Maximum Login Tries\t"grey"%d\tMaximum Login Warning before they get kicked\n", ServerInfo[LoginWarn]);
	strcat(combine, string);
	format(string, sizeof(string), "Maximum Security Tries\t"grey"%d\tMaximum Security Question Warning before they get kicked\n", ServerInfo[SecureWarn]);
	strcat(combine, string);
	format(string, sizeof(string), "Auto Login\t%s\tAuto Login's Player upon Connecting "red"(Risky)\n", (ServerInfo[AutoLogin] == 1) ? (""green"ON"white"") : (""red"OFF"white""));
	strcat(combine, string);
	format(string, sizeof(string), "Read Player Commands\t%s\tTracks every player's typed command except for /cpass\n", (ServerInfo[ReadCmds] == 1) ? (""green"ON"white"") : (""red"OFF"white""));
	strcat(combine, string);
	format(string, sizeof(string), "Ping Kicker\t"grey"%d"white"\tKicks the player when reached the maximum ping (0 to disable)\n", ServerInfo[MaxPing]);
	strcat(combine, string);
	format(string, sizeof(string), "Anti Swearing\t%s\tPrevents player's from swearing if it's on\n", (ServerInfo[AntiSwear] == 1) ? (""green"ON"white"") : (""red"OFF"white""));
	strcat(combine, string);
	format(string, sizeof(string), "Anti Name\t%s\tKick's player who is in the forbidden name's list\n", (ServerInfo[AntiName] == 1) ? (""green"ON"white"") : (""red"OFF"white""));
	strcat(combine, string);
	format(string, sizeof(string), "Anti Advertisement\t%s\tPrevent player from server advertising (e.g. 127.0.0.1:7777)\n", (ServerInfo[AntiAd] == 1) ? (""green"ON"white"") : (""red"OFF"white""));
	strcat(combine, string);
	format(string, sizeof(string), "Anti Spam\t%s\tPrevent player from spamming (e.g. make me admin plz!)\n", (ServerInfo[AntiSpam] == 1) ? (""green"ON"white"") : (""red"OFF"white""));
	strcat(combine, string);
	format(string, sizeof(string), "Read Command Type\t%s\tChanges the Read Command type\n", (ServerInfo[ReadCmd] == 1) ? (""green"Spectate"white"") : (""green"Normal"white""));
	strcat(combine, string);
	format(string, sizeof(string), "Register Optional\t%s\tMakes the registration in the server optional\n", (ServerInfo[RegisterOption] == 1) ? (""green"Yes"white"") : (""red"No"white""));
	strcat(combine, string);
	format(string, sizeof(string), "Tabbed Kicker\t%d\tKicks tabbed players (set to 0 to disable)\n", ServerInfo[TabTime]);
	strcat(combine, string);
	format(string, sizeof(string), "Idle Kicker\t%d\tKicks idled players (set to 0 to disable)\n", ServerInfo[AFKTime]);
	strcat(combine, string);
	format(string, sizeof(string), "Read PMs\t%s\tAbility to read private messages globally.\n", (ServerInfo[ReadPMs] == 1) ? (""green"Yes"white"") : (""red"No"white""));
	strcat(combine, string);
	format(string, sizeof(string), "Join/Leave Messages\t%s\tSelf Explanatory.\n", (ServerInfo[JoinMsg] == 1) ? (""green"ON"white"") : (""red"OFF"white""));
	strcat(combine, string);
	strcat(combine, "Ranks\t"grey"5"white"\tEdit the Admin Ranks here!");
	Dialog_Show(playerid, DIALOG_SETTINGS, DIALOG_STYLE_TABLIST_HEADERS, "JakAdmin Configuration", combine, "Edit", "Cancel");
	return 1;
}

stock GetAdminRank(level)
{
	new name[64];

	switch(level)
	{
	    case 1: format(name, 64, ServerInfo[AdminRank1]);
	    case 2: format(name, 64, ServerInfo[AdminRank2]);
	    case 3: format(name, 64, ServerInfo[AdminRank3]);
	    case 4: format(name, 64, ServerInfo[AdminRank4]);
	    case 5: format(name, 64, ServerInfo[AdminRank5]);
	    default: format(name, 64, "Player");
	}
	return name;
}

function:SaveConfig()
{
	new INI:file = INI_Open("JakAdmin/config.ini");
	INI_WriteInt(file, "RegisterOption", ServerInfo[RegisterOption]);
	INI_WriteInt(file, "SaveLog", ServerInfo[SaveLogs]);
	INI_WriteInt(file, "LoginWarn", ServerInfo[LoginWarn]);
	INI_WriteInt(file, "SecureWarn", ServerInfo[SecureWarn]);
	INI_WriteInt(file, "AutoLogin", ServerInfo[AutoLogin]);
	INI_WriteInt(file, "ReadCmds", ServerInfo[ReadCmds]);
	INI_WriteInt(file, "ReadCmd", ServerInfo[ReadCmd]);
	INI_WriteInt(file, "MaxPing", ServerInfo[MaxPing]);
	INI_WriteInt(file, "AntiSwear", ServerInfo[AntiSwear]);
	INI_WriteInt(file, "AntiName", ServerInfo[AntiName]);
	INI_WriteInt(file, "AntiAd", ServerInfo[AntiAd]);
	INI_WriteInt(file, "AntiSpam", ServerInfo[AntiSpam]);
	INI_WriteInt(file, "TabTime", ServerInfo[TabTime]);
	INI_WriteInt(file, "AFKTime", ServerInfo[AFKTime]);
	INI_WriteInt(file, "ReadPMs", ServerInfo[ReadPMs]);
	INI_WriteInt(file, "LockChat", ServerInfo[LockChat]);
	INI_WriteInt(file, "JoinMsg", ServerInfo[JoinMsg]);
	INI_WriteString(file, "AdminRank1", ServerInfo[AdminRank1]);
	INI_WriteString(file, "AdminRank2", ServerInfo[AdminRank2]);
	INI_WriteString(file, "AdminRank3", ServerInfo[AdminRank3]);
	INI_WriteString(file, "AdminRank4", ServerInfo[AdminRank4]);
	INI_WriteString(file, "AdminRank5", ServerInfo[AdminRank5]);
	INI_Close(file);
	return 1;
}

function:UpdateForbidden()
{
	new File:file2, string[100];

	if((file2 = fopen("JakAdmin/ForbiddenNames.cfg",io_read)))
	{
		while(fread(file2,string))
		{
		    for(new i = 0, j = strlen(string); i < j; i++) if(string[i] == '\n' || string[i] == '\r') string[i] = '\0';
            BadNames[BadNameCount] = string;
            BadNameCount++;
		}
		fclose(file2);
		printf("\n-> %d forbidden names loaded from JakAdmin", BadNameCount);
	}

	if((file2 = fopen("JakAdmin/ForbiddenWords.cfg",io_read)))
	{
		while(fread(file2,string))
		{
		    for(new i = 0, j = strlen(string); i < j; i++) if(string[i] == '\n' || string[i] == '\r') string[i] = '\0';
            ForbiddenWords[ForbiddenWordCount] = string;
            ForbiddenWordCount++;
		}
		fclose(file2);
		printf("-> %d forbidden words loaded from JakAdmin", ForbiddenWordCount);
	}
	return 1;
}

function:PosAfterSpec(playerid)
{
	SetPlayerPos(playerid, SpecPos[playerid][0], SpecPos[playerid][1], SpecPos[playerid][2]);
	SetPlayerFacingAngle(playerid, SpecPos[playerid][3]);
	SetPlayerInterior(playerid, SpecInt[playerid][0]);
	SetPlayerVirtualWorld(playerid, SpecInt[playerid][1]);
}

// Report System coded by jake elite (01/22/17)
function:InsertReport(playerid, targetid, reason[])
{
	new nextid = -1, string[128], r_hr, r_min, r_sec, r_m, r_d, r_y;

	for(new i = 1; i < MAX_REPORTS; i++) // loops through MAX_REPORTs (exception for zero) to find the next unoccupied ID.
	{
	    if(rInfo[i][reportTaken] == false)
	    {
	        nextid = i;
	        break;
	    }
	}
	
	if(nextid < 1) // failed to send the report to admins
	{
	    SendClientMessage(playerid, COLOR_RED, "** We cannot process your report at this moment, Please report again later.");
	    SendClientMessage(playerid, -1, "** If you still can't /report after 2-4 minutes, File in a report on forum instead.");
	}
	else
	{
		getdate(r_y, r_m, r_d);
		gettime(r_hr, r_min, r_sec);
		
		rInfo[nextid][reportTaken] = true;
		format(rInfo[nextid][reportTime], 32, "%02d-%02d-%d %02d:%02d:%02d", r_m, r_d, r_y, r_hr, r_min, r_sec);
		rInfo[nextid][reporterID] = playerid;
		rInfo[nextid][reportedID] = targetid;
		format(rInfo[nextid][reportReason], 64, reason);
		rInfo[nextid][reportAccepted] = INVALID_PLAYER_ID;

		format(string, sizeof(string), "[Report] %s(%d) has reported %s(%d) for %s [ReportID: %d]", pName(playerid), playerid, pName(targetid), targetid, reason, nextid);
		SendAdmin(COLOR_LIGHTBLUE, string);
		print(string);
		SaveLog("report.txt", string);

		foreach(new i : Player)
		{
		    if(User[i][accountLogged] && User[i][accountAdmin] > 0)
		    {
				GameTextForPlayer(i, "New Report", 1000, 1);
				PlayerPlaySound(i, 1085, 0.0, 0.0, 0.0);
			}
		}

		format(string, sizeof(string), "Your complaint against %s (%s) has been sent to admins, Your report is ID %d.", pName(targetid), reason, nextid);
		SendClientMessage(playerid, COLOR_YELLOW, string);
	}
	return 1;
}

function:HandleReport(playerid, reportid)
{
	new string[128];

	if(User[playerid][accountAdmin] > 0)
	{
	    if(rInfo[reportid][reportTaken] && rInfo[reportid][reportAccepted] == INVALID_PLAYER_ID)
	    {
	        format(string, sizeof(string), "* %s is now handling your report against %s (%s)", pName(playerid), pName(rInfo[reportid][reportedID]), rInfo[reportid][reportReason]);
	        SendClientMessage(rInfo[reportid][reporterID], COLOR_YELLOW, string);
	        SendClientMessage(rInfo[reportid][reporterID], -1, "* Use /reporttalk to talk to an admin handling your report.");

			format(string, sizeof(string), "[Report] %s is now handling the report of %s against %s [Report ID: %d]", pName(playerid), pName(rInfo[reportid][reporterID]), pName(rInfo[reportid][reportedID]), reportid);
			SendAdmin(COLOR_GREEN, string);
			print(string);
			SaveLog("report.txt", string);

			rInfo[reportid][reportAccepted] = playerid;
	    }
	}
	return 1;
}

function:DenyReport(playerid, reportid, reason[])
{
	new string[128];

	if(User[playerid][accountAdmin] > 0)
	{
	    if(rInfo[reportid][reportTaken] && rInfo[reportid][reportAccepted] == INVALID_PLAYER_ID)
	    {
	        format(string, sizeof(string), "* %s marked your report as invalid against %s (%s)", pName(playerid), pName(rInfo[reportid][reportedID]), rInfo[reportid][reportReason]);
	        SendClientMessage(rInfo[reportid][reporterID], COLOR_YELLOW, string);
	        format(string, sizeof(string), "* Admin %s: %s", pName(playerid), reason);
	        SendClientMessage(rInfo[reportid][reporterID], -1, string);

			format(string, sizeof(string), "[Report] Report against %s by %s has been marked invalid by %s [Report ID: %d]", pName(rInfo[reportid][reportedID]), pName(rInfo[reportid][reporterID]), pName(playerid), reportid);
			SendAdmin(COLOR_GREEN, string);
			print(string);
			SaveLog("report.txt", string);

			ResetReport(reportid);
	    }
	}
	return 1;
}

function:EndReport(playerid, reportid, reason[])
{
	new string[128];

	if(User[playerid][accountAdmin] >= 1)
	{
	    if(rInfo[reportid][reportTaken] && rInfo[reportid][reportAccepted] == playerid)
	    {
	        format(string, sizeof(string), "* %s has closed your report against %s (%s)", pName(playerid), pName(rInfo[reportid][reportedID]), rInfo[reportid][reportReason]);
	        SendClientMessage(rInfo[reportid][reporterID], COLOR_YELLOW, string);
	        format(string, sizeof(string), "* Admin %s: %s", pName(playerid), reason);
	        SendClientMessage(rInfo[reportid][reporterID], -1, string);

			format(string, sizeof(string), "[Report] Report against %s by %s has been closed by %s [Report ID: %d]", pName(rInfo[reportid][reportedID]), pName(rInfo[reportid][reporterID]), pName(playerid), reportid);
			SendAdmin(COLOR_GREEN, string);
			print(string);
			SaveLog("report.txt", string);

			ResetReport(reportid);
	    }
	}
	return 1;
}

function:ResetReport(reportid)
{
	new string[128];

	if(rInfo[reportid][reportTaken])
	{
	    if(IsPlayerConnected(rInfo[reportid][reportAccepted]) && rInfo[reportid][reportAccepted] != INVALID_PLAYER_ID)
	    {
	        format(string, sizeof(string), "* Report ID %d being handled by you has been closed automatically.", reportid);
	        SendClientMessage(rInfo[reportid][reportAccepted], -1, string);
	    }
	
		rInfo[reportid][reportTaken] = false;
		format(rInfo[reportid][reportTime], 32, "");
		rInfo[reportid][reporterID] = INVALID_PLAYER_ID;
		rInfo[reportid][reportedID] = INVALID_PLAYER_ID;
		format(rInfo[reportid][reportReason], 64, "");
		rInfo[reportid][reportAccepted] = INVALID_PLAYER_ID;
	}
	return 1;
}

stock RemoveAlpha(color) {
    return (color & ~0xFF);
}

stock AddAlpha(color)
{
    new newcolor = color - (color & 0x000000FF) + 0xFF;
    return newcolor;
}

stock IsValidIP(ip[])
{
    new a;
	for (new i = 0; i < strlen(ip); i++)
	{
		if (ip[i] == '.')
		{
		    a++;
		}
	}
	if (a != 3)
	{
	    return 1;
	}
	return 0;
}

stock QuickSort_Pair(array[][2], bool:desc, left, right)
{
	#define PAIR_FIST (0)
	#define PAIR_SECOND (1)

	new
		tempLeft = left,
		tempRight = right,
		pivot = array[(left + right) / 2][PAIR_FIST],
		tempVar
	;

	while (tempLeft <= tempRight)
	{
	    if (desc)
	    {
			while (array[tempLeft][PAIR_FIST] > pivot)
				tempLeft++;

			while (array[tempRight][PAIR_FIST] < pivot)
				tempRight--;
		}
	    else
	    {
			while (array[tempLeft][PAIR_FIST] < pivot)
				tempLeft++;

			while (array[tempRight][PAIR_FIST] > pivot)
				tempRight--;
		}

		if (tempLeft <= tempRight)
		{
			tempVar = array[tempLeft][PAIR_FIST];
		 	array[tempLeft][PAIR_FIST] = array[tempRight][PAIR_FIST];
		 	array[tempRight][PAIR_FIST] = tempVar;

			tempVar = array[tempLeft][PAIR_SECOND];
			array[tempLeft][PAIR_SECOND] = array[tempRight][PAIR_SECOND];
			array[tempRight][PAIR_SECOND] = tempVar;

			tempLeft++;
			tempRight--;
		}
	}

	if (left < tempRight)
		QuickSort_Pair(array, desc, left, tempRight);

	if (tempLeft < right)
		QuickSort_Pair(array, desc, tempLeft, right);

	#undef PAIR_FIST
	#undef PAIR_SECOND
}

/////////////////////////////// INCLUDE SUPPORT ////////////////////////////////
// DO NOT REMOVE

function:check_playerafk(playerid)
{
	SetPVarInt(playerid, "account_afk", User[playerid][accountAFK]);
	return 1;
}

function:check_playertabbed(playerid)
{
	SetPVarInt(playerid, "account_tabbed", User[playerid][accountTabbed]);
	return 1;
}

function:check_playingtime(playerid)
{
	SetPVarInt(playerid, "account_hour", User[playerid][accountGame][2]);
	SetPVarInt(playerid, "account_minute", User[playerid][accountGame][1]);
	SetPVarInt(playerid, "account_second", User[playerid][accountGame][0]);
	return 1;
}

function:set_playingtime(playerid, hour, minute, second)
{
	User[playerid][accountGame][2] = hour;
	User[playerid][accountGame][1] = minute;
	User[playerid][accountGame][0] = second;
	return 1;
}

function:check_chocolate(playerid)
{
	// Checks the chocolate bar the player has.
	return User[playerid][accountChocolate];
}

function:set_chocolate(playerid, amount)
{
	// Sets the chocolate bar the player has.
	User[playerid][accountChocolate] = amount;
	return 1;
}

function:save_player(playerid)
{
	return SaveData(playerid);
}

function:check_admin(playerid)
{
	// Checks the admin level of the player
	return User[playerid][accountAdmin];
}

function:set_admin(playerid, level)
{
	// Sets the admin level of the player
	User[playerid][accountAdmin] = level;
	return 1;
}

function:check_login(playerid)
{
	// Checks if the player is logged in or not
	return User[playerid][accountLogged];
}

function:set_log(playerid, toggle)
{
	// Sets the accountLogged to toggle
	if(toggle == 0)
	{
	    User[playerid][accountLogged] = 0;
	}
	else if(toggle >= 1)
	{
	    User[playerid][accountLogged] = 1;
	}
	return 1;
}

function:check_mute(playerid)
{
	// Check if the player is muted or not
	return User[playerid][accountMuted];
}

function:check_mutesec(playerid)
{
	// Check the player's mute seconds if there is any
	return User[playerid][accountMuteSec];
}

function:check_cmute(playerid)
{
	// Check if the player is muted or not
	return User[playerid][accountCMuted];
}

function:check_cmutesec(playerid)
{
	// Check the player's mute seconds if there is any
	return User[playerid][accountCMuteSec];
}

function:set_mute(playerid, toggle)
{
	// Set the player's mute status
	User[playerid][accountMuted] = toggle;
	return 1;
}

function:set_mutesec(playerid, sec)
{
	// Set the player's mute seconds
	User[playerid][accountMuteSec] = sec;
	return 1;
}

function:set_cmute(playerid, toggle)
{
	// Set the player's command mute status
	User[playerid][accountCMuted] = toggle;
	return 1;
}

function:set_cmutesec(playerid, sec)
{
	// Set the player's command mute seconds
	User[playerid][accountCMuteSec] = sec;
	return 1;
}

function:check_jail(playerid)
{
	// Check the player's jail status
	return User[playerid][accountJail];
}

function:check_jailsec(playerid)
{
	// Check the player's jail seconds if there is any
	return User[playerid][accountJailSec];
}

function:set_jail(playerid, toggle)
{
	// Set the player's jail status
	User[playerid][accountJail] = toggle;
	return 1;
}

function:set_jailsec(playerid, sec)
{
	// Set the player's jail seconds
	User[playerid][accountJailSec] = sec;
	return 1;
}

function:check_id(playerid)
{
	return User[playerid][accountID];
}

function:check_warn(playerid)
{
	// Check how many warns do the player got
	return User[playerid][accountWarn];
}

function:set_warn(playerid, warn)
{
	// Sets how many warns to the player
	User[playerid][accountWarn] = warn;
	return 1;
}

function:check_kills(playerid)
{
	// Check how many kills do the player got
	return User[playerid][accountKills];
}

function:set_kill(playerid, kill)
{
	// Sets how many kills to the player
	User[playerid][accountKills] = kill;
	return 1;
}

function:check_deaths(playerid)
{
	// Check how many deaths do the player got
	return User[playerid][accountDeaths];
}

function:set_death(playerid, death)
{
	// Sets how many deaths to the player
	User[playerid][accountDeaths] = death;
	return 1;
}

/*******************************************************************************
 *          End of the Script -  JakAdmin4.0 (c),  2017              		   *
 ******************************************************************************/
