#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <updater>

#define PLUGIN_VERSION 	"2.0.0"
#define PLUGIN_NAME		"Deathmatch"
#define UPDATE_URL 		"http://www.maxximou5.com/sourcemod/deathmatch/update.txt"

public Plugin:myinfo =
{
	name 			= PLUGIN_NAME,
	author			= "Maxximou5",
	description		= "Enables deathmatch style gameplay (respawning, gun selection, spawn protection, etc).",
	version 		= PLUGIN_VERSION,
	url 			= "https://github.com/Maxximou5/csgo-deathmatch/"
};

enum Teams
{
	TeamNone,
	TeamSpectator,
	TeamT,
	TeamCT
};

enum Slots
{
	SlotPrimary,
	SlotSecondary,
	SlotKnife,
	SlotGrenade,
	SlotC4,
	SlotNone
};

#define MAX_SPAWNS 200
#define HIDEHUD_RADAR 1 << 12

// Native console variables
new Handle:mp_startmoney;
new Handle:mp_playercashawards;
new Handle:mp_teamcashawards;
new Handle:mp_friendlyfire;
new Handle:mp_autokick;
new Handle:mp_tkpunish;
new Handle:mp_teammates_are_enemies;
new Handle:ff_damage_reduction_bullets;
new Handle:ff_damage_reduction_grenade;
new Handle:ff_damage_reduction_other;
new Handle:ammo_grenade_limit_default;
new Handle:ammo_grenade_limit_flashbang;
new Handle:ammo_grenade_limit_total;
// Native backup variables
new backup_mp_startmoney;
new backup_mp_playercashawards;
new backup_mp_teamcashawards;
new backup_mp_friendlyfire;
new backup_mp_autokick;
new backup_mp_tkpunish;
new backup_mp_teammates_are_enemies;
new Float:backup_ff_damage_reduction_bullets;
new Float:backup_ff_damage_reduction_grenade;
new Float:backup_ff_damage_reduction_other;
new backup_ammo_grenade_limit_default;
new backup_ammo_grenade_limit_flashbang;
new backup_ammo_grenade_limit_total;
// Console variables
new Handle:cvar_dm_enabled;
new Handle:cvar_dm_welcomemsg;
new Handle:cvar_dm_free_for_all;
new Handle:cvar_dm_remove_objectives;
new Handle:cvar_dm_respawning;
new Handle:cvar_dm_respawn_time;
new Handle:cvar_dm_gun_menu_mode;
new Handle:cvar_dm_los_spawning;
new Handle:cvar_dm_los_attempts;
new Handle:cvar_dm_spawn_distance;
new Handle:cvar_dm_sp_time;
new Handle:cvar_dm_remove_weapons;
new Handle:cvar_dm_replenish_ammo;
new Handle:cvar_dm_replenish_grenade;
new Handle:cvar_dm_replenish_hegrenade;
new Handle:cvar_dm_hp_start;
new Handle:cvar_dm_hp_max;
new Handle:cvar_dm_hp_kill;
new Handle:cvar_dm_hp_hs;
new Handle:cvar_dm_hp_knife;
new Handle:cvar_dm_hp_messages;
new Handle:cvar_dm_nade_messages;
new Handle:cvar_dm_armour;
new Handle:cvar_dm_zeus;
new Handle:cvar_dm_nades_incendiary;
new Handle:cvar_dm_nades_molotov;
new Handle:cvar_dm_nades_decoy;
new Handle:cvar_dm_nades_flashbang;
new Handle:cvar_dm_nades_he;
new Handle:cvar_dm_nades_smoke;
// Variables
new bool:enabled = false;
new bool:welcomemsg;
new bool:ffa;
new bool:removeObjectives;
new bool:respawning;
new Float:respawnTime;
new gunMenuMode;
new bool:lineOfSightSpawning;
new lineOfSightAttempts;
new Float:spawnDistanceFromEnemies;
new Float:spawnProtectionTime;
new bool:removeWeapons;
new bool:replenishAmmo;
new bool:replenishGrenade;
new bool:replenishHEGrenade;
new startHP;
new maxHP;
new HPPerKill;
new HPPerHeadshotKill;
new HPPerKnifeKill;
new bool:displayHPMessages;
new bool:displayGrenadeMessages;
new bool:roundEnded = false;
new defaultColour[4] = { 255, 255, 255, 255 };
new tColour[4] = { 255, 0, 0, 200 };
new ctColour[4] = { 0, 0, 255, 200 };
new spawnPointCount = 0;
new Float:spawnPositions[MAX_SPAWNS][3];
new Float:spawnAngles[MAX_SPAWNS][3];
new bool:spawnPointOccupied[MAX_SPAWNS] = {false, ...};
new Float:eyeOffset[3] = { 0.0, 0.0, 64.0 }; // CSGO offset.
new Float:spawnPointOffset[3] = { 0.0, 0.0, 20.0 };
new bool:inEditMode = false;
// Offsets
new ownerOffset;
new armourOffset;
new helmetOffset;
new activeWeaponOffset;
new ammoTypeOffset;
new ammoOffset;
new ragdollOffset;
// Weapon info
new Handle:primaryWeaponsAvailable;
new Handle:secondaryWeaponsAvailable;
new Handle:weaponMenuNames;
new Handle:weaponLimits;
new Handle:weaponCounts;
// Grenade/Misc options
new bool:armour;
new bool:zeus;
new molotov;
new incendiary;
new decoy;
new flashbang;
new he;
new smoke;
// Menus
new Handle:optionsMenu1 = INVALID_HANDLE;
new Handle:optionsMenu2 = INVALID_HANDLE;
new Handle:primaryMenus[MAXPLAYERS + 1];
new Handle:secondaryMenus[MAXPLAYERS + 1];
// Player settings
new lastEditorSpawnPoint[MAXPLAYERS + 1] = { -1, ... };
new String:primaryWeapon[MAXPLAYERS + 1][24];
new String:secondaryWeapon[MAXPLAYERS + 1][24];
new infoMessageCount[MAXPLAYERS + 1] = { 3, ... };
new bool:firstWeaponSelection[MAXPLAYERS + 1] = { true, ... };
new bool:weaponsGivenThisRound[MAXPLAYERS + 1] = { false, ... };
new bool:newWeaponsSelected[MAXPLAYERS + 1] = { false, ... };
new bool:rememberChoice[MAXPLAYERS + 1] = { false, ... };
new bool:playerMoved[MAXPLAYERS + 1] = { false, ... };
// Content
new glowSprite;
// Spawn stats
new numberOfPlayerSpawns = 0;
new losSearchAttempts = 0;
new losSearchSuccesses = 0;
new losSearchFailures = 0;
new distanceSearchAttempts = 0;
new distanceSearchSuccesses = 0;
new distanceSearchFailures = 0;
new spawnPointSearchFailures = 0;

public OnPluginStart()
{
	// Create spawns directory if necessary.
	decl String:spawnsPath[] = "addons/sourcemod/configs/deathmatch/spawns";
	if (!DirExists(spawnsPath))
		CreateDirectory(spawnsPath, 711);
	// Find offsets
	ownerOffset = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	armourOffset = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	helmetOffset = FindSendPropOffs("CCSPlayer", "m_bHasHelmet");
	activeWeaponOffset = FindSendPropOffs("CCSPlayer", "m_hActiveWeapon");
	ammoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");
	ammoOffset = FindSendPropOffs("CCSPlayer", "m_iAmmo");
	ragdollOffset = FindSendPropOffs("CCSPlayer", "m_hRagdoll");
	// Create arrays to store available weapons loaded by config
	primaryWeaponsAvailable = CreateArray(24);
	secondaryWeaponsAvailable = CreateArray(24);
	// Create trie to store menu names for weapons
	BuildWeaponMenuNames();
	// Create trie to store weapon limits and counts
	weaponLimits = CreateTrie();
	weaponCounts = CreateTrie();
	// Create menus
	optionsMenu1 = BuildOptionsMenu(true);
	optionsMenu2 = BuildOptionsMenu(false);
	// Retrieve native console variables
	mp_startmoney = FindConVar("mp_startmoney");
	mp_playercashawards = FindConVar("mp_playercashawards");
	mp_teamcashawards = FindConVar("mp_teamcashawards");
	mp_friendlyfire = FindConVar("mp_friendlyfire");
	mp_autokick = FindConVar("mp_autokick");
	mp_tkpunish = FindConVar("mp_tkpunish");
	mp_teammates_are_enemies = FindConVar("mp_teammates_are_enemies");
	ff_damage_reduction_bullets = FindConVar("ff_damage_reduction_bullets");
	ff_damage_reduction_grenade = FindConVar("ff_damage_reduction_grenade");
	ff_damage_reduction_other = FindConVar("ff_damage_reduction_other");
	ammo_grenade_limit_default = FindConVar("ammo_grenade_limit_default");
	ammo_grenade_limit_flashbang = FindConVar("ammo_grenade_limit_flashbang");
	ammo_grenade_limit_total = FindConVar("ammo_grenade_limit_total");
	// Retrieve native console variable values
	backup_mp_startmoney = GetConVarInt(mp_startmoney);
	backup_mp_playercashawards = GetConVarInt(mp_playercashawards);
	backup_mp_teamcashawards = GetConVarInt(mp_teamcashawards);
	backup_mp_friendlyfire = GetConVarInt(mp_friendlyfire);
	backup_mp_autokick = GetConVarInt(mp_autokick);
	backup_mp_tkpunish = GetConVarInt(mp_tkpunish);
	backup_mp_teammates_are_enemies = GetConVarInt(mp_teammates_are_enemies);
	backup_ff_damage_reduction_bullets = GetConVarFloat(ff_damage_reduction_bullets);
	backup_ff_damage_reduction_grenade = GetConVarFloat(ff_damage_reduction_grenade);
	backup_ff_damage_reduction_other = GetConVarFloat(ff_damage_reduction_other);
	backup_ammo_grenade_limit_default = GetConVarInt(ammo_grenade_limit_default);
	backup_ammo_grenade_limit_flashbang = GetConVarInt(ammo_grenade_limit_flashbang);
	backup_ammo_grenade_limit_total = GetConVarInt(ammo_grenade_limit_total);
	// Create console variables
	CreateConVar("dm_m5_version", PLUGIN_VERSION, "Deathmatch version.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvar_dm_enabled = CreateConVar("dm_enabled", "1", "Enable Deathmatch.");
	cvar_dm_welcomemsg = CreateConVar("dm_welcomemsg", "1", "Display a message saying that your server is running Deathmatch.");
	cvar_dm_free_for_all = CreateConVar("dm_free_for_all", "0", "Free for all mode.");
	cvar_dm_remove_objectives = CreateConVar("dm_remove_objectives", "1", "Remove objectives (disables bomb sites, and removes c4 and hostages).");
	cvar_dm_respawning = CreateConVar("dm_respawning", "1", "Enable respawning.");
	cvar_dm_respawn_time = CreateConVar("dm_respawn_time", "2.0", "Respawn time.");
	cvar_dm_gun_menu_mode = CreateConVar("dm_gun_menu_mode", "1", "Gun menu mode. 1) Enabled. 2) Disabled. 3) Random weapons every round.");
	cvar_dm_los_spawning = CreateConVar("dm_los_spawning", "1", "Enable line of sight spawning. If enabled, players will be spawned at a point where they cannot see enemies, and enemies cannot see them.");
	cvar_dm_los_attempts = CreateConVar("dm_los_attempts", "10", "Maximum number of attempts to find a suitable line of sight spawn point.");
	cvar_dm_spawn_distance = CreateConVar("dm_spawn_distance", "0.0", "Minimum distance from enemies at which a player can spawn.");
	cvar_dm_sp_time = CreateConVar("dm_sp_time", "1.0", "Spawn protection time.");
	cvar_dm_remove_weapons = CreateConVar("dm_remove_weapons", "1", "Remove ground weapons.");
	cvar_dm_replenish_ammo = CreateConVar("dm_replenish_ammo", "1", "Unlimited player ammo.");
	cvar_dm_replenish_grenade = CreateConVar("dm_replenish_grenade", "0", "Unlimited player grenades.");
	cvar_dm_replenish_hegrenade = CreateConVar("dm_replenish_hegrenade", "0", "Unlimited hegrenades.");
	cvar_dm_hp_start = CreateConVar("dm_hp_start", "100", "Spawn HP.");
	cvar_dm_hp_max = CreateConVar("dm_hp_max", "100", "Maximum HP.");
	cvar_dm_hp_kill = CreateConVar("dm_hp_kill", "5", "HP per kill.");
	cvar_dm_hp_hs = CreateConVar("dm_hp_hs", "10", "HP per headshot kill.");
	cvar_dm_hp_knife = CreateConVar("dm_hp_knife", "50", "HP per knife kill.");
	cvar_dm_hp_messages = CreateConVar("dm_hp_messages", "1", "Display HP messages.");
	cvar_dm_nade_messages = CreateConVar("dm_nade_messages", "1", "Display grenade messages.");
	cvar_dm_armour = CreateConVar("dm_armour", "1", "Give players armour.");
	cvar_dm_zeus = CreateConVar("dm_zeus", "0", "Give players a taser.");
	cvar_dm_nades_incendiary = CreateConVar("dm_nades_incendiary", "0", "Number of incendiary grenades to give each player.");
	cvar_dm_nades_molotov = CreateConVar("dm_nades_molotov", "0", "Number of molotov grenades to give each player.");
	cvar_dm_nades_decoy = CreateConVar("dm_nades_decoy", "0", "Number of decoy grenades to give each player.");
	cvar_dm_nades_flashbang = CreateConVar("dm_nades_flashbang", "0", "Number of flashbang grenades to give each player.");
	cvar_dm_nades_he = CreateConVar("dm_nades_he", "0", "Number of HE grenades to give each player.");
	cvar_dm_nades_smoke = CreateConVar("dm_nades_smoke", "0", "Number of smoke grenades to give each player.");
	LoadConfig();
	// Admin commands
	RegAdminCmd("dm_spawn_menu", Command_SpawnMenu, ADMFLAG_CHANGEMAP, "Opens the spawn point menu.");
	RegAdminCmd("dm_respawn_all", Command_RespawnAll, ADMFLAG_CHANGEMAP, "Respawns all players.");  
	RegAdminCmd("dm_stats", Command_Stats, ADMFLAG_CHANGEMAP, "Displays spawn statistics.");
	RegAdminCmd("dm_reset_stats", Command_ResetStats, ADMFLAG_CHANGEMAP, "Resets spawn statistics.");
	// Client Commands
	RegConsoleCmd("sm_guns", Command_Guns, "Opens the !guns menu");
	// Event hooks
	HookConVarChange(cvar_dm_enabled, Event_CvarChange);
	HookConVarChange(cvar_dm_welcomemsg, Event_CvarChange);
	HookConVarChange(cvar_dm_free_for_all, Event_CvarChange);
	HookConVarChange(cvar_dm_remove_objectives, Event_CvarChange);
	HookConVarChange(cvar_dm_respawning, Event_CvarChange);
	HookConVarChange(cvar_dm_respawn_time, Event_CvarChange);
	HookConVarChange(cvar_dm_gun_menu_mode, Event_CvarChange);
	HookConVarChange(cvar_dm_los_spawning, Event_CvarChange);
	HookConVarChange(cvar_dm_los_attempts, Event_CvarChange);
	HookConVarChange(cvar_dm_spawn_distance, Event_CvarChange);
	HookConVarChange(cvar_dm_sp_time, Event_CvarChange);
	HookConVarChange(cvar_dm_remove_weapons, Event_CvarChange);
	HookConVarChange(cvar_dm_replenish_ammo, Event_CvarChange);
	HookConVarChange(cvar_dm_replenish_grenade, Event_CvarChange);
	HookConVarChange(cvar_dm_replenish_hegrenade, Event_CvarChange);
	HookConVarChange(cvar_dm_hp_start, Event_CvarChange);
	HookConVarChange(cvar_dm_hp_max, Event_CvarChange);
	HookConVarChange(cvar_dm_hp_kill, Event_CvarChange);
	HookConVarChange(cvar_dm_hp_hs, Event_CvarChange);
	HookConVarChange(cvar_dm_hp_knife, Event_CvarChange);
	HookConVarChange(cvar_dm_hp_messages, Event_CvarChange);
	HookConVarChange(cvar_dm_nade_messages, Event_CvarChange);
	HookConVarChange(cvar_dm_armour, Event_CvarChange);
	HookConVarChange(cvar_dm_zeus, Event_CvarChange);
	HookConVarChange(cvar_dm_nades_incendiary, Event_CvarChange);
	HookConVarChange(cvar_dm_nades_molotov, Event_CvarChange);
	HookConVarChange(cvar_dm_nades_decoy, Event_CvarChange);
	HookConVarChange(cvar_dm_nades_flashbang, Event_CvarChange);
	HookConVarChange(cvar_dm_nades_he, Event_CvarChange);
	HookConVarChange(cvar_dm_nades_smoke, Event_CvarChange);
	RegConsoleCmd("joinclass", Event_JoinClass);
	AddCommandListener(Event_Say, "say");
	AddCommandListener(Event_Say, "say_team");
	HookUserMessage(GetUserMessageId("TextMsg"), Event_TextMsg, true);
	HookUserMessage(GetUserMessageId("HintText"), Event_HintText, true);
	HookUserMessage(GetUserMessageId("RadioText"), Event_RadioText, true);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_prestart", Event_RoundPrestart, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("hegrenade_detonate", Event_HegrenadeDetonate, EventHookMode_Post);
	HookEvent("smokegrenade_detonate", Event_SmokegrenadeDetonate, EventHookMode_Post);
	HookEvent("flashbang_detonate", Event_FlashbangDetonate, EventHookMode_Post);
	HookEvent("molotov_detonate", Event_MolotovDetonate, EventHookMode_Post);
	HookEvent("inferno_startburn", Event_InfernoStartburn, EventHookMode_Post);
	HookEvent("decoy_started", Event_DecoyStarted, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("bomb_pickup", Event_BombPickup);
	AddNormalSoundHook(Event_Sound);
	// Create timers
	CreateTimer(0.5, UpdateSpawnPointStatus, INVALID_HANDLE, TIMER_REPEAT);
	CreateTimer(10.0, RemoveGroundWeapons, INVALID_HANDLE, TIMER_REPEAT);
	CreateTimer(5.0, GiveAmmo, INVALID_HANDLE, TIMER_REPEAT);

	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryRemoved(const String:name[])
{
 if (StrEqual(name, "updater")) Updater_RemovePlugin();
}

public OnPluginEnd()
{
	for (new i = 1; i <= MaxClients; i++)
		DisableSpawnProtection(INVALID_HANDLE, i);
	SetBuyZones("Enable");
	SetObjectives("Enable");
	// Cancel menus
	CancelMenu(optionsMenu1);
	CancelMenu(optionsMenu2);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (primaryMenus[i] != INVALID_HANDLE)
			CancelMenu(primaryMenus[i]);
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (secondaryMenus[i] != INVALID_HANDLE)
			CancelMenu(secondaryMenus[i]);
	}
	RestoreCashState();
	RestoreGrenadeState();
	DisableFFA();
}

public OnConfigsExecuted()
{
	UpdateState();
}

public OnMapStart()
{
	// Precache content
	glowSprite = PrecacheModel("sprites/glow01.vmt", true);
	
	InitialiseWeaponCounts();
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
			ResetClientSettings(i);
	}
	LoadMapConfig();
	if (spawnPointCount > 0)
	{
		for (new i = 0; i < spawnPointCount; i++)
			spawnPointOccupied[i] = false;
	}
	if (enabled)
	{
		SetBuyZones("Disable");
		if (removeObjectives)
		{
			SetObjectives("Disable");
			RemoveHostages();
		}
		SetCashState();
		SetGrenadeState();
		if (ffa)
			EnableFFA();
	}
}

public OnClientPutInServer(clientIndex)
{
	if (enabled && welcomemsg)
	{
		if (GetConVarBool(cvar_dm_welcomemsg))
		{
			CreateTimer(10.0, Timer_WelcomeMsg, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
		}
		ResetClientSettings(clientIndex);
	}
}

public Action:Timer_WelcomeMsg(Handle:timer, any:userid)
{
	new clientIndex = GetClientOfUserId(userid);
	
	if (IsClientInGame(clientIndex))
	{
		PrintHintText(clientIndex, "This server is running Deathmatch Version 2.0.0");
		//PrintToChat(clientIndex, "[\x04WELCOME\x01] This server is running \x04Deathmatch \x01v2.0");
	}
	return Plugin_Stop;
}

public OnClientDisconnect(clientIndex)
{
	RemoveRagdoll(clientIndex);
}

ResetClientSettings(clientIndex)
{
	lastEditorSpawnPoint[clientIndex] = -1;
	SetClientGunModeSettings(clientIndex);
	infoMessageCount[clientIndex] = 3;
	weaponsGivenThisRound[clientIndex] = false;
	newWeaponsSelected[clientIndex] = false;
	playerMoved[clientIndex] = false;
}

SetClientGunModeSettings(clientIndex)
{
	if (!IsFakeClient(clientIndex))
	{
		if (gunMenuMode != 3)
		{
			primaryWeapon[clientIndex] = "none";
			secondaryWeapon[clientIndex] = "none";
			firstWeaponSelection[clientIndex] = true;
			rememberChoice[clientIndex] = false;
		}
		else
		{
			primaryWeapon[clientIndex] = "random";
			secondaryWeapon[clientIndex] = "random";
			firstWeaponSelection[clientIndex] = false;
			rememberChoice[clientIndex] = true;
		}
	}
	else
	{
		if (gunMenuMode != 2)
		{
			primaryWeapon[clientIndex] = "random";
			secondaryWeapon[clientIndex] = "random";
			firstWeaponSelection[clientIndex] = false;
			rememberChoice[clientIndex] = true;
		}
		else
		{
			primaryWeapon[clientIndex] = "none";
			secondaryWeapon[clientIndex] = "none";
			firstWeaponSelection[clientIndex] = true;
			rememberChoice[clientIndex] = false;
		}
	}
}

public Event_CvarChange(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	UpdateState();
}

LoadConfig()
{
	new Handle:keyValues = CreateKeyValues("Deathmatch Config");
	decl String:path[] = "addons/sourcemod/configs/deathmatch/deathmatch.ini";
	
	if (!FileToKeyValues(keyValues, path))
		SetFailState("The configuration file could not be read.");
	
	decl String:key[25];
	decl String:value[25];
	
	if (!KvJumpToKey(keyValues, "Options"))
		SetFailState("The configuration file is corrupt (\"Options\" section could not be found).");
	
	KvGetString(keyValues, "enabled", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_enabled, value);

	KvGetString(keyValues, "welcomemsg", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_welcomemsg, value);

	KvGetString(keyValues, "free_for_all", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_free_for_all, value);
	
	KvGetString(keyValues, "remove_objectives", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_remove_objectives, value);
	
	KvGetString(keyValues, "respawning", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_respawning, value);
	
	KvGetString(keyValues, "respawn_time", value, sizeof(value), "2.0");
	SetConVarString(cvar_dm_respawn_time, value);
	
	KvGetString(keyValues, "gun_menu_mode", value, sizeof(value), "1");
	SetConVarString(cvar_dm_gun_menu_mode, value);
	
	KvGetString(keyValues, "line_of_sight_spawning", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_los_spawning, value);
	
	KvGetString(keyValues, "line_of_sight_attempts", value, sizeof(value), "10");
	SetConVarString(cvar_dm_los_attempts, value);
	
	KvGetString(keyValues, "spawn_distance_from_enemies", value, sizeof(value), "0.0");
	SetConVarString(cvar_dm_spawn_distance, value);
	
	KvGetString(keyValues, "spawn_protection_time", value, sizeof(value), "1.0");
	SetConVarString(cvar_dm_sp_time, value);
	
	KvGetString(keyValues, "remove_weapons", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_remove_weapons, value);
	
	KvGetString(keyValues, "replenish_ammo", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_replenish_ammo, value);

	KvGetString(keyValues, "replenish_grenade", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_replenish_grenade, value);

	KvGetString(keyValues, "replenish_hegrenade", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_replenish_hegrenade, value);
	
	KvGetString(keyValues, "player_hp_start", value, sizeof(value), "100");
	SetConVarString(cvar_dm_hp_start, value);
	
	KvGetString(keyValues, "player_hp_max", value, sizeof(value), "100");
	SetConVarString(cvar_dm_hp_max, value);
	
	KvGetString(keyValues, "hp_per_kill", value, sizeof(value), "5");
	SetConVarString(cvar_dm_hp_kill, value);
	
	KvGetString(keyValues, "hp_per_headshot_kill", value, sizeof(value), "10");
	SetConVarString(cvar_dm_hp_hs, value);
	
	KvGetString(keyValues, "hp_per_knife_kill", value, sizeof(value), "50");
	SetConVarString(cvar_dm_hp_knife, value);
	
	KvGetString(keyValues, "display_hp_messages", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_hp_messages, value);
	
	KvGetString(keyValues, "display_grenade_messages", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_nade_messages, value);
	
	KvGoBack(keyValues);
	
	if (!KvJumpToKey(keyValues, "Weapons"))
		SetFailState("The configuration file is corrupt (\"Weapons\" section could not be found).");
	
	if (!KvJumpToKey(keyValues, "Primary"))
		SetFailState("The configuration file is corrupt (\"Primary\" section could not be found).");
	
	if (KvGotoFirstSubKey(keyValues, false))
	{
		do {
			KvGetSectionName(keyValues, key, sizeof(key));
			PushArrayString(primaryWeaponsAvailable, key);
			new limit = KvGetNum(keyValues, NULL_STRING, -1);
			SetTrieValue(weaponLimits, key, limit);
		} while (KvGotoNextKey(keyValues, false));
	}
	
	KvGoBack(keyValues);
	KvGoBack(keyValues);
	
	if (!KvJumpToKey(keyValues, "Secondary"))
		SetFailState("The configuration file is corrupt (\"Secondary\" section could not be found).");
		
	if (KvGotoFirstSubKey(keyValues, false))
	{
		do {
			KvGetSectionName(keyValues, key, sizeof(key));
			PushArrayString(secondaryWeaponsAvailable, key);
			new limit = KvGetNum(keyValues, NULL_STRING, -1);
			SetTrieValue(weaponLimits, key, limit);
		} while (KvGotoNextKey(keyValues, false));
	}
	
	KvGoBack(keyValues);
	KvGoBack(keyValues);
	
	if (!KvJumpToKey(keyValues, "Misc"))
		SetFailState("The configuration file is corrupt (\"Misc\" section could not be found).");
	
	KvGetString(keyValues, "armour", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_armour, value);
	
	KvGetString(keyValues, "zeus", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_zeus, value);
	
	KvGoBack(keyValues);
	
	if (!KvJumpToKey(keyValues, "Grenades"))
		SetFailState("The configuration file is corrupt (\"Grenades\" section could not be found).");
	
	KvGetString(keyValues, "incendiary", value, sizeof(value), "0");
	SetConVarString(cvar_dm_nades_incendiary, value);
	
	KvGetString(keyValues, "molotov", value, sizeof(value), "0");
	SetConVarString(cvar_dm_nades_incendiary, value);

	KvGetString(keyValues, "decoy", value, sizeof(value), "0");
	SetConVarString(cvar_dm_nades_decoy, value);
	
	KvGetString(keyValues, "flashbang", value, sizeof(value), "0");
	SetConVarString(cvar_dm_nades_flashbang, value);
	
	KvGetString(keyValues, "he", value, sizeof(value), "0");
	SetConVarString(cvar_dm_nades_he, value);
	
	KvGetString(keyValues, "smoke", value, sizeof(value), "0");
	SetConVarString(cvar_dm_nades_smoke, value);
	
	CloseHandle(keyValues);
}

UpdateState()
{
	new old_enabled = enabled;
	new old_gunMenuMode = gunMenuMode;
	
	enabled = GetConVarBool(cvar_dm_enabled);
	welcomemsg = GetConVarBool(cvar_dm_welcomemsg);
	ffa = GetConVarBool(cvar_dm_free_for_all);
	removeObjectives = GetConVarBool(cvar_dm_remove_objectives);
	respawning = GetConVarBool(cvar_dm_respawning);
	respawnTime = GetConVarFloat(cvar_dm_respawn_time);
	gunMenuMode = GetConVarInt(cvar_dm_gun_menu_mode);
	lineOfSightSpawning = GetConVarBool(cvar_dm_los_spawning);
	lineOfSightAttempts = GetConVarInt(cvar_dm_los_attempts);
	spawnDistanceFromEnemies = GetConVarFloat(cvar_dm_spawn_distance);
	spawnProtectionTime = GetConVarFloat(cvar_dm_sp_time);
	removeWeapons = GetConVarBool(cvar_dm_remove_weapons);
	replenishAmmo = GetConVarBool(cvar_dm_replenish_ammo);
	replenishGrenade = GetConVarBool(cvar_dm_replenish_grenade);
	replenishHEGrenade = GetConVarBool(cvar_dm_replenish_hegrenade);
	startHP = GetConVarInt(cvar_dm_hp_start);
	maxHP = GetConVarInt(cvar_dm_hp_max);
	HPPerKill = GetConVarInt(cvar_dm_hp_kill);
	HPPerHeadshotKill = GetConVarInt(cvar_dm_hp_hs);
	HPPerKnifeKill = GetConVarInt(cvar_dm_hp_knife);
	displayHPMessages = GetConVarBool(cvar_dm_hp_messages);
	displayGrenadeMessages = GetConVarBool(cvar_dm_nade_messages);
	armour = GetConVarBool(cvar_dm_armour);
	zeus = GetConVarBool(cvar_dm_zeus);
	incendiary = GetConVarInt(cvar_dm_nades_incendiary);
	molotov = GetConVarInt(cvar_dm_nades_molotov);
	decoy = GetConVarInt(cvar_dm_nades_decoy);
	flashbang = GetConVarInt(cvar_dm_nades_flashbang);
	he = GetConVarInt(cvar_dm_nades_he);
	smoke = GetConVarInt(cvar_dm_nades_smoke);
	
	if (respawnTime < 0.0) respawnTime = 0.0;
	if (gunMenuMode < 1) gunMenuMode = 1;
	if (gunMenuMode > 3) gunMenuMode = 3;
	if (lineOfSightAttempts < 0) lineOfSightAttempts = 0;
	if (spawnDistanceFromEnemies < 0.0) spawnDistanceFromEnemies = 0.0;
	if (spawnProtectionTime < 0.0) spawnProtectionTime = 0.0;
	if (startHP < 1) startHP = 1;
	if (maxHP < 1) maxHP = 1;
	if (HPPerKill < 0) HPPerKill = 0;
	if (HPPerHeadshotKill < 0) HPPerHeadshotKill = 0;
	if (HPPerKnifeKill < 0) HPPerKnifeKill = 0;
	if (incendiary < 0) incendiary = 0;
	if (molotov < 0) molotov = 0;
	if (decoy < 0) decoy = 0;
	if (flashbang < 0) flashbang = 0;
	if (he < 0) he = 0;
	if (smoke < 0) smoke = 0;
	
	
	if (enabled && !old_enabled)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i))
				ResetClientSettings(i);
		}
		RespawnAll();
		SetBuyZones("Disable");
		decl String:status[10];
		status = (removeObjectives) ? "Disable" : "Enable";
		SetObjectives(status);
		SetCashState();
	}
	else if (!enabled && old_enabled)
	{
		for (new i = 1; i <= MaxClients; i++)
			DisableSpawnProtection(INVALID_HANDLE, i);
		CancelMenu(optionsMenu1);
		CancelMenu(optionsMenu2);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (primaryMenus[i] != INVALID_HANDLE)
				CancelMenu(primaryMenus[i]);
		}
		for (new i = 1; i <= MaxClients; i++)
		{
			if (secondaryMenus[i] != INVALID_HANDLE)
				CancelMenu(secondaryMenus[i]);
		}
		SetBuyZones("Enable");
		SetObjectives("Enable");
		RestoreCashState();
		RestoreGrenadeState();
	}
	
	if (enabled)
	{
		if (gunMenuMode != old_gunMenuMode)
		{
			if (gunMenuMode != 1)
			{
				for (new i = 1; i <= MaxClients; i++)
					CancelClientMenu(i);
			}
			// Only if the plugin was enabled before the state update do we need to update the client's gun mode settings. If it was disabled before, then
			// the entire client settings (including gun mode settings) are reset above.
			if (old_enabled)
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientConnected(i))
						SetClientGunModeSettings(i);
				}
			}
		}
		if (removeObjectives)
			RemoveC4();
		SetGrenadeState();
		if (ffa)
			EnableFFA();
		else
			DisableFFA();
	}
}

SetCashState()
{
	SetConVarInt(mp_startmoney, 0);
	SetConVarInt(mp_playercashawards, 0);
	SetConVarInt(mp_teamcashawards, 0);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
			SetEntProp(i, Prop_Send, "m_iAccount", 0);
	}
}

RestoreCashState()
{
	SetConVarInt(mp_startmoney, backup_mp_startmoney);
	SetConVarInt(mp_playercashawards, backup_mp_playercashawards);
	SetConVarInt(mp_teamcashawards, backup_mp_teamcashawards);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
			SetEntProp(i, Prop_Send, "m_iAccount", backup_mp_startmoney);
	}
}

SetGrenadeState()
{
	new maxGrenadesSameType = 0;
	if (incendiary > maxGrenadesSameType) maxGrenadesSameType = incendiary;
	if (molotov > maxGrenadesSameType) maxGrenadesSameType = molotov;
	if (decoy > maxGrenadesSameType) maxGrenadesSameType = decoy;
	if (flashbang > maxGrenadesSameType) maxGrenadesSameType = flashbang;
	if (he > maxGrenadesSameType) maxGrenadesSameType = he;
	if (smoke > maxGrenadesSameType) maxGrenadesSameType = smoke;
	SetConVarInt(ammo_grenade_limit_default, maxGrenadesSameType);
	SetConVarInt(ammo_grenade_limit_flashbang, flashbang);
	SetConVarInt(ammo_grenade_limit_total, incendiary + decoy + flashbang + he + smoke);
}

RestoreGrenadeState()
{
	SetConVarInt(ammo_grenade_limit_default, backup_ammo_grenade_limit_default);
	SetConVarInt(ammo_grenade_limit_flashbang, backup_ammo_grenade_limit_flashbang);
	SetConVarInt(ammo_grenade_limit_total, backup_ammo_grenade_limit_total);
}

EnableFFA()
{
	SetConVarInt(mp_teammates_are_enemies, 1);
	SetConVarInt(mp_friendlyfire, 1);
	SetConVarInt(mp_autokick, 0);
	SetConVarInt(mp_tkpunish, 0);
	SetConVarFloat(ff_damage_reduction_bullets, 1.0);
	SetConVarFloat(ff_damage_reduction_grenade, 1.0);
	SetConVarFloat(ff_damage_reduction_other, 1.0);
}

DisableFFA()
{
	SetConVarInt(mp_teammates_are_enemies, backup_mp_teammates_are_enemies);
	SetConVarInt(mp_friendlyfire, backup_mp_friendlyfire);
	SetConVarInt(mp_autokick, backup_mp_autokick);
	SetConVarInt(mp_tkpunish, backup_mp_tkpunish);
	SetConVarFloat(ff_damage_reduction_bullets, backup_ff_damage_reduction_bullets);
	SetConVarFloat(ff_damage_reduction_grenade, backup_ff_damage_reduction_grenade);
	SetConVarFloat(ff_damage_reduction_other, backup_ff_damage_reduction_other);
}

LoadMapConfig()
{
	decl String:map[64];
	GetCurrentMap(map, sizeof(map));
	
	decl String:path[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "addons/sourcemod/configs/deathmatch/spawns/%s.txt", map);
	
	spawnPointCount = 0;
	
	// Open file
	new Handle:file = OpenFile(path, "r");
	if (file == INVALID_HANDLE)
		return;
	// Read file
	decl String:buffer[256];
	decl String:parts[6][16];
	while (!IsEndOfFile(file) && ReadFileLine(file, buffer, sizeof(buffer)))
	{
		ExplodeString(buffer, " ", parts, 6, 16);
		spawnPositions[spawnPointCount][0] = StringToFloat(parts[0]);
		spawnPositions[spawnPointCount][1] = StringToFloat(parts[1]);
		spawnPositions[spawnPointCount][2] = StringToFloat(parts[2]);
		spawnAngles[spawnPointCount][0] = StringToFloat(parts[3]);
		spawnAngles[spawnPointCount][1] = StringToFloat(parts[4]);
		spawnAngles[spawnPointCount][2] = StringToFloat(parts[5]);
		spawnPointCount++;
	}
	// Close file
	CloseHandle(file);
}

bool:WriteMapConfig()
{
	decl String:map[64];
	GetCurrentMap(map, sizeof(map));
	
	decl String:path[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "addons/sourcemod/configs/deathmatch/spawns/%s.txt", map);
	
	// Open file
	new Handle:file = OpenFile(path, "w");
	if (file == INVALID_HANDLE)
	{
		LogError("Could not open spawn point file \"%s\" for writing.", path);
		return false;
	}
	// Write spawn points
	for (new i = 0; i < spawnPointCount; i++)
		WriteFileLine(file, "%f %f %f %f %f %f", spawnPositions[i][0], spawnPositions[i][1], spawnPositions[i][2], spawnAngles[i][0], spawnAngles[i][1], spawnAngles[i][2]);
	// Close file
	CloseHandle(file);
	return true;
}

public Action:Event_Say(clientIndex, const String:command[], arg)
{
	static String:menuTriggers[][] = { "gun", "!gun", "/gun", "guns", "!guns", "/guns", "menu", "!menu", "/menu", "weapon", "!weapon", "/weapon", "weapons", "!weapons", "/weapons" };
	
	if (enabled && (clientIndex != 0) && (Teams:GetClientTeam(clientIndex) > TeamSpectator))
	{
		// Retrieve and clean up text.
		decl String:text[24];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		TrimString(text);
	
		for(new i = 0; i < sizeof(menuTriggers); i++)
		{
			if (StrEqual(text, menuTriggers[i], false))
			{
				if (gunMenuMode == 1)
					DisplayOptionsMenu(clientIndex);
				else
					PrintToChat(clientIndex, "[\x04DM\x01] The gun menu is disabled.");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

BuildWeaponMenuNames()
{
	weaponMenuNames = CreateTrie();
	// Primary weapons
	SetTrieString(weaponMenuNames, "weapon_ak47", "AK-47");
	SetTrieString(weaponMenuNames, "weapon_m4a1", "M4A1");
	SetTrieString(weaponMenuNames, "weapon_m4a1_silencer", "M4A1-S");
	SetTrieString(weaponMenuNames, "weapon_sg556", "SG 553");
	SetTrieString(weaponMenuNames, "weapon_aug", "AUG");
	SetTrieString(weaponMenuNames, "weapon_galilar", "Galil AR");
	SetTrieString(weaponMenuNames, "weapon_famas", "FAMAS");
	SetTrieString(weaponMenuNames, "weapon_awp", "AWP");
	SetTrieString(weaponMenuNames, "weapon_ssg08", "SSG 08");
	SetTrieString(weaponMenuNames, "weapon_g3sg1", "G3SG1");
	SetTrieString(weaponMenuNames, "weapon_scar20", "SCAR-20");
	SetTrieString(weaponMenuNames, "weapon_m249", "M249");
	SetTrieString(weaponMenuNames, "weapon_negev", "Negev");
	SetTrieString(weaponMenuNames, "weapon_nova", "Nova");
	SetTrieString(weaponMenuNames, "weapon_xm1014", "XM1014");
	SetTrieString(weaponMenuNames, "weapon_sawedoff", "Sawed-Off");
	SetTrieString(weaponMenuNames, "weapon_mag7", "MAG-7");
	SetTrieString(weaponMenuNames, "weapon_mac10", "MAC-10");
	SetTrieString(weaponMenuNames, "weapon_mp9", "MP9");
	SetTrieString(weaponMenuNames, "weapon_mp7", "MP7");
	SetTrieString(weaponMenuNames, "weapon_ump45", "UMP-45");
	SetTrieString(weaponMenuNames, "weapon_p90", "P90");
	SetTrieString(weaponMenuNames, "weapon_bizon", "PP-Bizon");
	// Secondary weapons
	SetTrieString(weaponMenuNames, "weapon_glock", "Glock-18");
	SetTrieString(weaponMenuNames, "weapon_p250", "P250");
	SetTrieString(weaponMenuNames, "weapon_cz75a", "CZ75-A");
	SetTrieString(weaponMenuNames, "weapon_usp_silencer", "USP-S");
	SetTrieString(weaponMenuNames, "weapon_fiveseven", "Five-SeveN");
	SetTrieString(weaponMenuNames, "weapon_deagle", "Desert Eagle");
	SetTrieString(weaponMenuNames, "weapon_elite", "Dual Berettas");
	SetTrieString(weaponMenuNames, "weapon_tec9", "Tec-9");
	SetTrieString(weaponMenuNames, "weapon_hkp2000", "P2000");
	// Random
	SetTrieString(weaponMenuNames, "random", "Random");
}

InitialiseWeaponCounts()
{
	for (new i = 0; i < GetArraySize(primaryWeaponsAvailable); i++)
	{
		decl String:weapon[24];
		GetArrayString(primaryWeaponsAvailable, i, weapon, sizeof(weapon));
		SetTrieValue(weaponCounts, weapon, 0);
	}
	for (new i = 0; i < GetArraySize(secondaryWeaponsAvailable); i++)
	{
		decl String:weapon[24];
		GetArrayString(secondaryWeaponsAvailable, i, weapon, sizeof(weapon));
		SetTrieValue(weaponCounts, weapon, 0);
	}
}

DisplayOptionsMenu(clientIndex)
{
	if (!firstWeaponSelection[clientIndex])
		DisplayMenu(optionsMenu1, clientIndex, MENU_TIME_FOREVER);
	else
		DisplayMenu(optionsMenu2, clientIndex, MENU_TIME_FOREVER);
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// If the player joins spectator, close any open menu, and remove their ragdoll.
	if ((clientIndex != 0) && (Teams:GetClientTeam(clientIndex) == TeamSpectator))
	{
		CancelClientMenu(clientIndex);
		RemoveRagdoll(clientIndex);
	}
}

public Action:Event_JoinClass(clientIndex, args)
{
	if (enabled && respawning)
		CreateTimer(respawnTime, Respawn, clientIndex);
}

public Action:Event_RoundPrestart(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundEnded = false;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (enabled)
	{
		if (removeObjectives)
			RemoveHostages();
		if (removeWeapons)
			RemoveGroundWeapons(INVALID_HANDLE);
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundEnded = true;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (enabled)
	{
		new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
	
		if (Teams:GetClientTeam(clientIndex) > TeamSpectator)
		{
			// Hide radar.
			if (ffa)
				CreateTimer(0.0, RemoveRadar, clientIndex);
			// Display help message.
			if ((gunMenuMode == 1) && infoMessageCount[clientIndex] > 0)
			{
				PrintToChat(clientIndex, "[\x04DM\x01] Type \x04guns \x01to open the weapons menu.");
				infoMessageCount[clientIndex]--;
			}
			// Teleport player to custom spawn point.
			if (spawnPointCount > 0)
				MovePlayer(clientIndex);
			// Enable player spawn protection.
			if (spawnProtectionTime > 0.0)
				EnableSpawnProtection(clientIndex);
			// Set health.
			if (startHP != 100)
				SetEntityHealth(clientIndex, startHP);
			// Give equipment
			if (armour)
			{
				SetEntData(clientIndex, armourOffset, 100);
				SetEntData(clientIndex, helmetOffset, 1);
			}
			else
			{
				SetEntData(clientIndex, armourOffset, 0);
				SetEntData(clientIndex, helmetOffset, 0);
			}
			// Give weapons or display menu.
			weaponsGivenThisRound[clientIndex] = false;
			RemoveWeapons(clientIndex);
			if (newWeaponsSelected[clientIndex])
			{
				GiveSavedWeapons(clientIndex, true, true);
				newWeaponsSelected[clientIndex] = false;
			}
			else if (rememberChoice[clientIndex])
			{
				GiveSavedWeapons(clientIndex, true, true);
			}
			else
			{
				if (gunMenuMode == 1)
					DisplayOptionsMenu(clientIndex);
			}
			// Remove C4.
			if (removeObjectives)
				StripC4(clientIndex);
		}
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (enabled)
	{
		new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
		new attackerIndex = GetClientOfUserId(GetEventInt(event, "attacker"));
		decl String:attackerWeapon[6];
		GetEventString(event, "weapon", attackerWeapon, sizeof(attackerWeapon));
		
		// Reward attacker with HP.
		if ((attackerIndex != 0) && IsPlayerAlive(attackerIndex))
		{
			new bool:knifed = StrEqual(attackerWeapon, "knife");
			new bool:headshot = GetEventBool(event, "headshot");
			
			if ((knifed && (HPPerKnifeKill > 0)) || (!headshot && (HPPerKill > 0)) || (headshot && (HPPerHeadshotKill > 0)))
			{
				new attackerHP = GetClientHealth(attackerIndex);
				
				if (attackerHP < maxHP)
				{
					new addHP;
					if (knifed)
						addHP = HPPerKnifeKill;
					else if (headshot)
						addHP = HPPerHeadshotKill;
					else
						addHP = HPPerKill;
					new newHP = attackerHP + addHP;
					if (newHP > maxHP)
						newHP = maxHP;
					SetEntProp(attackerIndex, Prop_Send, "m_iHealth", newHP, 1);
				}
				
				if (displayHPMessages)
				{
					if (knifed)
						PrintToChat(attackerIndex, "[\x04DM\x01] \x04+%iHP\x01 for killing an enemy (knife).", HPPerKnifeKill);
					else if (headshot)
						PrintToChat(attackerIndex, "[\x04DM\x01] \x04+%iHP\x01 for killing an enemy (headshot).", HPPerHeadshotKill);
					else
						PrintToChat(attackerIndex, "[\x04DM\x01] \x04+%iHP\x01 for killing an enemy.", HPPerKill);
				}
			}
		}
		// Correct the attacker's score if this was a teamkill.
		/* if (ffa)
		{
			if ((attackerIndex != 0) && (clientIndex != attackerIndex) && (GetClientTeam(clientIndex) == GetClientTeam(attackerIndex)))
				SetEntProp(attackerIndex, Prop_Data, "m_iFrags", GetClientFrags(attackerIndex) + 2);
		} */
		// Respawn player.
		if (respawning)
			CreateTimer(respawnTime, Respawn, clientIndex);
	}
}

public Action:RemoveRadar(Handle:timer, any:clientIndex)
{
	SetEntProp(clientIndex, Prop_Send, "m_iHideHUD", HIDEHUD_RADAR);
}

public Action:Event_HegrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));   
	
	if (replenishGrenade && !replenishHEGrenade)
	{
		if (IsClientInGame(clientIndex) && IsPlayerAlive(clientIndex))
		{
			GivePlayerItem(clientIndex, "weapon_hegrenade");
		}
	}

	else if (replenishHEGrenade && !replenishGrenade)
	{
		if (IsClientInGame(clientIndex) && IsPlayerAlive(clientIndex))
		{
			GivePlayerItem(clientIndex, "weapon_hegrenade");
		}
	}

	else if (replenishGrenade && replenishHEGrenade)
	{
		if (IsClientInGame(clientIndex) && IsPlayerAlive(clientIndex))
		{
			GivePlayerItem(clientIndex, "weapon_hegrenade");
		}
	}

	return Plugin_Continue;
}

public Action:Event_SmokegrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!replenishGrenade)
	{
		return Plugin_Continue;
	}

	new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));   
	
	if (replenishGrenade)
	{
		if (IsClientInGame(clientIndex) && IsPlayerAlive(clientIndex))
		{
			GivePlayerItem(clientIndex, "weapon_smokegrenade");
		}
	}

	return Plugin_Continue;
}

public Action:Event_FlashbangDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!replenishGrenade)
	{
		return Plugin_Continue;
	}

	new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));   
	
	if (replenishGrenade)
	{
		if (IsClientInGame(clientIndex) && IsPlayerAlive(clientIndex))
		{
			GivePlayerItem(clientIndex, "weapon_flashbang");
		}
	}

	return Plugin_Continue;
}

public Action:Event_DecoyStarted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!replenishGrenade)
	{
		return Plugin_Continue;
	}

	new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));   
	
	if (replenishGrenade)
	{
		if (IsClientInGame(clientIndex) && IsPlayerAlive(clientIndex))
		{
			GivePlayerItem(clientIndex, "weapon_decoy");
		}
	}

	return Plugin_Continue;
}

public Action:Event_MolotovDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!replenishGrenade)
	{
		return Plugin_Continue;
	}

	new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));   
	
	if (replenishGrenade)
	{
		if (IsClientInGame(clientIndex) && IsPlayerAlive(clientIndex))
		{
			GivePlayerItem(clientIndex, "weapon_molotov");
		}
	}

	return Plugin_Continue;
}

public Action:Event_InfernoStartburn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!replenishGrenade)
	{
		return Plugin_Continue;
	}

	new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));   
	
	if (replenishGrenade)
	{
		if (IsClientInGame(clientIndex) && IsPlayerAlive(clientIndex))
		{
			GivePlayerItem(clientIndex, "weapon_incgrenade");
		}
	}

	return Plugin_Continue;
}

public Action:GiveAmmo(Handle:timer)
{
	static ammoCounts[] = { 0, 35, 90, 90, 40, 200, 30, 120, 32, 100, 52, 100, 24, 100, 100, 1, 1, 1 };
	
	if (enabled && replenishAmmo)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!roundEnded && IsClientInGame(i) && (Teams:GetClientTeam(i) > TeamSpectator) && IsPlayerAlive(i))
			{
				new activeWeapon = GetEntDataEnt2(i, activeWeaponOffset);
				if (activeWeapon != -1)
				{
					new primary = GetPlayerWeaponSlot(i, _:SlotPrimary);
					new secondary = GetPlayerWeaponSlot(i, _:SlotSecondary);
					if ((activeWeapon != primary) && (activeWeapon != secondary))
						continue;
					
					new ammoType = GetEntData(activeWeapon, ammoTypeOffset);
					if (ammoType != -1)
						SetEntData(i, ammoOffset + (ammoType * 4), ammoCounts[ammoType], 4, true);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Event_BombPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (enabled && removeObjectives)
	{
		new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
		StripC4(clientIndex);
	}
}

public Action:Respawn(Handle:timer, any:clientIndex)
{
	if (!roundEnded && IsClientInGame(clientIndex) && (Teams:GetClientTeam(clientIndex) > TeamSpectator) && !IsPlayerAlive(clientIndex))
	{
		// We set this here rather than in Event_PlayerSpawn to catch the spawn sounds which occur before Event_PlayerSpawn is called (even with EventHookMode_Pre).
		playerMoved[clientIndex] = false;
		CS_RespawnPlayer(clientIndex);
	}
}

RespawnAll()
{
	for (new i = 1; i <= MaxClients; i++)
		Respawn(INVALID_HANDLE, i);
}

Handle:BuildOptionsMenu(bool:sameWeaponsEnabled)
{
	new sameWeaponsStyle = (sameWeaponsEnabled) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
	new Handle:menu = CreateMenu(Menu_Options);
	SetMenuTitle(menu, "Weapon Menu:");
	SetMenuExitButton(menu, false);
	AddMenuItem(menu, "New", "New weapons");
	AddMenuItem(menu, "Same 1", "Same weapons", sameWeaponsStyle);
	AddMenuItem(menu, "Same All", "Same weapons every round", sameWeaponsStyle);
	AddMenuItem(menu, "Random 1", "Random weapons");
	AddMenuItem(menu, "Random All", "Random weapons every round");
	return menu;
}

public Menu_Options(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[24];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "New"))
		{
			if (weaponsGivenThisRound[param1])
				newWeaponsSelected[param1] = true;
			BuildDisplayWeaponMenu(param1, true);
			rememberChoice[param1] = false;
		}
		else if (StrEqual(info, "Same 1"))
		{
			if (weaponsGivenThisRound[param1])
			{
				newWeaponsSelected[param1] = true;
				PrintToChat(param1, "[\x04DM\x01] You will be given the same weapons on next spawn.");
			}
			GiveSavedWeapons(param1, true, true);
			rememberChoice[param1] = false;
		}
		else if (StrEqual(info, "Same All"))
		{
			if (weaponsGivenThisRound[param1])
				PrintToChat(param1, "[\x04DM\x01] You will be given the same weapons starting on next spawn.");
			GiveSavedWeapons(param1, true, true);
			rememberChoice[param1] = true;
		}
		else if (StrEqual(info, "Random 1"))
		{
			if (weaponsGivenThisRound[param1])
			{
				newWeaponsSelected[param1] = true;
				PrintToChat(param1, "[\x04DM\x01] You will receive random weapons on next spawn.");
			}
			primaryWeapon[param1] = "random";
			secondaryWeapon[param1] = "random";
			GiveSavedWeapons(param1, true, true);
			rememberChoice[param1] = false;
		}
		else if (StrEqual(info, "Random All"))
		{
			if (weaponsGivenThisRound[param1])
				PrintToChat(param1, "[\x04DM\x01] You will receive random weapons starting on next spawn.");
			primaryWeapon[param1] = "random";
			secondaryWeapon[param1] = "random";
			GiveSavedWeapons(param1, true, true);
			rememberChoice[param1] = true;
		}
	}
}

public Menu_Primary(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[24];
		GetMenuItem(menu, param2, info, sizeof(info));
		IncrementWeaponCount(info);
		DecrementWeaponCount(primaryWeapon[param1]);
		primaryWeapon[param1] = info;
		GiveSavedWeapons(param1, true, false);
		BuildDisplayWeaponMenu(param1, false);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_Exit)
		{
			DecrementWeaponCount(primaryWeapon[param1]);
			primaryWeapon[param1] = "none";
			GiveSavedWeapons(param1, true, false);
			BuildDisplayWeaponMenu(param1, false);
		}
	}
}

public Menu_Secondary(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[24];
		GetMenuItem(menu, param2, info, sizeof(info));
		IncrementWeaponCount(info);
		DecrementWeaponCount(secondaryWeapon[param1]);
		secondaryWeapon[param1] = info;
		GiveSavedWeapons(param1, false, true);
		if (!IsPlayerAlive(param1))
			newWeaponsSelected[param1] = true;
		if (newWeaponsSelected[param1])
			PrintToChat(param1, "[\x04DM\x01] Your new weapons will be given to you on next spawn.");
		firstWeaponSelection[param1] = false;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_Exit)
		{
			if ((param1 > 0) && (param1 <= MaxClients) && IsClientInGame(param1))
			{
				DecrementWeaponCount(secondaryWeapon[param1]);
				secondaryWeapon[param1] = "none";
				GiveSavedWeapons(param1, false, true);
				if (!IsPlayerAlive(param1))
					newWeaponsSelected[param1] = true;
				if (newWeaponsSelected[param1])
					PrintToChat(param1, "[\x04DM\x01] Your new weapons will be given to you on next spawn.");
				firstWeaponSelection[param1] = false;
			}
		}
	}
}

public Action:Command_Guns(clientIndex, args)
{
	if (enabled)
		DisplayOptionsMenu(clientIndex);
}

GiveSavedWeapons(clientIndex, bool:primary, bool:secondary)
{
	if (!weaponsGivenThisRound[clientIndex] && IsPlayerAlive(clientIndex))
	{
		if (primary && !StrEqual(primaryWeapon[clientIndex], "none"))
		{
			if (StrEqual(primaryWeapon[clientIndex], "random"))
			{
				// Select random menu item (excluding "Random" option)
				new random = GetRandomInt(0, GetArraySize(primaryWeaponsAvailable) - 2);
				decl String:randomWeapon[24];
				GetArrayString(primaryWeaponsAvailable, random, randomWeapon, sizeof(randomWeapon));
				GivePlayerItem(clientIndex, randomWeapon);
			}
			else
				GivePlayerItem(clientIndex, primaryWeapon[clientIndex]);
		}
		if (secondary)
		{
			if (!StrEqual(secondaryWeapon[clientIndex], "none"))
			{
				// Strip knife, give pistol, and then give knife. This fixes the bug where pressing Q on spawn would switch to knife rather than pistol.
				new entityIndex = GetPlayerWeaponSlot(clientIndex, _:SlotKnife);
				if (entityIndex != -1)
				{
					RemovePlayerItem(clientIndex, entityIndex);
					AcceptEntityInput(entityIndex, "Kill");
				}
				if (StrEqual(secondaryWeapon[clientIndex], "random"))
				{

					// Select random menu item (excluding "Random" option)
					new random = GetRandomInt(0, GetArraySize(secondaryWeaponsAvailable) - 2);
					decl String:randomWeapon[24];
					GetArrayString(secondaryWeaponsAvailable, random, randomWeapon, sizeof(randomWeapon));
					GivePlayerItem(clientIndex, randomWeapon);
				}
				else
					GivePlayerItem(clientIndex, secondaryWeapon[clientIndex]);
				GivePlayerItem(clientIndex, "weapon_knife");
			}
			if (zeus)
				GivePlayerItem(clientIndex, "weapon_taser");
			if (incendiary > 0)
			{
				new Teams:clientTeam = Teams:GetClientTeam(clientIndex);
				for (new i = 0; i < incendiary; i++)
				{
					if (clientTeam == TeamT)
						GivePlayerItem(clientIndex, "weapon_molotov");
					else
						GivePlayerItem(clientIndex, "weapon_incgrenade");
				}
			}
			for (new i = 0; i < decoy; i++)
				GivePlayerItem(clientIndex, "weapon_decoy");
			for (new i = 0; i < flashbang; i++)
				GivePlayerItem(clientIndex, "weapon_flashbang");
			for (new i = 0; i < he; i++)
				GivePlayerItem(clientIndex, "weapon_hegrenade");
			for (new i = 0; i < smoke; i++)
				GivePlayerItem(clientIndex, "weapon_smokegrenade");
			weaponsGivenThisRound[clientIndex] = true;
		}
	}
}

RemoveWeapons(clientIndex)
{
	FakeClientCommand(clientIndex, "use weapon_knife");
	for (new i = 0; i < 4; i++)
	{
		if (i == 2) continue; // Keep knife.
		new entityIndex;
		while ((entityIndex = GetPlayerWeaponSlot(clientIndex, i)) != -1)
		{
			RemovePlayerItem(clientIndex, entityIndex);
			AcceptEntityInput(entityIndex, "Kill");
		}
	}
}

public Action:RemoveGroundWeapons(Handle:timer)
{
	if (enabled && removeWeapons)
	{
		new maxEntities = GetMaxEntities();
		decl String:class[24];
		
		for (new i = MaxClients + 1; i < maxEntities; i++)
		{
			if (IsValidEdict(i) && (GetEntDataEnt2(i, ownerOffset) == -1))
			{
				GetEdictClassname(i, class, sizeof(class));
				if ((StrContains(class, "weapon_") != -1) || (StrContains(class, "item_") != -1))
				{
					if (StrEqual(class, "weapon_c4"))
					{
						if (!removeObjectives)
							continue;
					}
					AcceptEntityInput(i, "Kill");
				}
			}
		}
	}
	return Plugin_Continue;
}

SetBuyZones(const String:status[])
{
	new maxEntities = GetMaxEntities();
	decl String:class[24];
	
	for (new i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "func_buyzone"))
				AcceptEntityInput(i, status);
		}
	}
}

SetObjectives(const String:status[])
{
	new maxEntities = GetMaxEntities();
	decl String:class[24];
	
	for (new i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "func_bomb_target") || StrEqual(class, "func_hostage_rescue"))
				AcceptEntityInput(i, status);
		}
	}
}

RemoveC4()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (StripC4(i))
			break;
	}
}

bool:StripC4(clientIndex)
{
	if (IsClientInGame(clientIndex) && (Teams:GetClientTeam(clientIndex) == TeamT) && IsPlayerAlive(clientIndex))
	{
		new c4Index = GetPlayerWeaponSlot(clientIndex, _:SlotC4);
		if (c4Index != -1)
		{
			decl String:weapon[24];
			GetClientWeapon(clientIndex, weapon, sizeof(weapon));
			// If the player is holding C4, switch to the best weapon before removing it.
			if (StrEqual(weapon, "weapon_c4"))
			{
				if (GetPlayerWeaponSlot(clientIndex, _:SlotPrimary) != -1)
					ClientCommand(clientIndex, "slot1");
				else if (GetPlayerWeaponSlot(clientIndex, _:SlotSecondary) != -1)
					ClientCommand(clientIndex, "slot2");
				else
					ClientCommand(clientIndex, "slot3");
				
			}
			RemovePlayerItem(clientIndex, c4Index);
			AcceptEntityInput(c4Index, "Kill");
			return true;
		}
	}
	return false;
}

RemoveHostages()
{
	new maxEntities = GetMaxEntities();
	decl String:class[24];
	
	for (new i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "hostage_entity"))
				AcceptEntityInput(i, "Kill");
		}
	}
}

EnableSpawnProtection(clientIndex)
{
	new Teams:clientTeam = Teams:GetClientTeam(clientIndex);
	// Disable damage
	SetEntProp(clientIndex, Prop_Data, "m_takedamage", 0, 1);
	// Set player colour
	if (clientTeam == TeamT)
		SetPlayerColour(clientIndex, tColour);
	else if (clientTeam == TeamCT)
		SetPlayerColour(clientIndex, ctColour);
	// Create timer to remove spawn protection
	CreateTimer(spawnProtectionTime, DisableSpawnProtection, clientIndex);
}

public Action:DisableSpawnProtection(Handle:Timer, any:clientIndex)
{
	if (IsClientInGame(clientIndex) && (Teams:GetClientTeam(clientIndex) > TeamSpectator) && IsPlayerAlive(clientIndex))
	{
		// Enable damage
		SetEntProp(clientIndex, Prop_Data, "m_takedamage", 2, 1);
		// Set player colour
		SetPlayerColour(clientIndex, defaultColour);
	}
}

SetPlayerColour(clientIndex, const colour[4])
{
	new RenderMode:mode = (colour[3] == 255) ? RENDER_NORMAL : RENDER_TRANSCOLOR;
	SetEntityRenderMode(clientIndex, mode);
	SetEntityRenderColor(clientIndex, colour[0], colour[1], colour[2], colour[3]);
}

public Action:Command_RespawnAll(clientIndex, args)
{
	RespawnAll();
	return Plugin_Handled;
}

Handle:BuildSpawnEditorMenu()
{
	new Handle:menu = CreateMenu(Menu_SpawnEditor);
	SetMenuTitle(menu, "Spawn Point Editor:");
	SetMenuExitButton(menu, true);
	decl String:editModeItem[24];
	Format(editModeItem, sizeof(editModeItem), "%s Edit Mode", (!inEditMode) ? "Enable" : "Disable");
	AddMenuItem(menu, "Edit", editModeItem);
	AddMenuItem(menu, "Nearest", "Teleport to nearest");
	AddMenuItem(menu, "Previous", "Teleport to previous");
	AddMenuItem(menu, "Next", "Teleport to next");
	AddMenuItem(menu, "Add", "Add position");
	AddMenuItem(menu, "Insert", "Insert position here");
	AddMenuItem(menu, "Delete", "Delete nearest");
	AddMenuItem(menu, "Delete All", "Delete all");
	AddMenuItem(menu, "Save", "Save Configuration");
	return menu;
}

public Action:Command_SpawnMenu(clientIndex, args)
{
	DisplayMenu(BuildSpawnEditorMenu(), clientIndex, MENU_TIME_FOREVER);
}

public Menu_SpawnEditor(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[24];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if (StrEqual(info, "Edit"))
		{
			inEditMode = !inEditMode;
			if (inEditMode)
			{
				CreateTimer(1.0, RenderSpawnPoints, INVALID_HANDLE, TIMER_REPEAT);
				PrintToChat(param1, "[\x04DM\x01] Edit mode enabled.");
			}
			else
				PrintToChat(param1, "[\x04DM\x01] Edit mode disabled.");
		}
		else if (StrEqual(info, "Nearest"))
		{
			new spawnPoint = GetNearestSpawn(param1);
			if (spawnPoint != -1)
			{
				TeleportEntity(param1, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
				lastEditorSpawnPoint[param1] = spawnPoint;
				PrintToChat(param1, "[\x04DM\x01] Teleported to spawn point #%i (%i total).", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Previous"))
		{
			if (spawnPointCount == 0)
				PrintToChat(param1, "[\x04DM\x01] There are no spawn points.");
			else
			{
				new spawnPoint = lastEditorSpawnPoint[param1] - 1;
				if (spawnPoint < 0)
					spawnPoint = spawnPointCount - 1;
				TeleportEntity(param1, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
				lastEditorSpawnPoint[param1] = spawnPoint;
				PrintToChat(param1, "[\x04DM\x01] Teleported to spawn point #%i (%i total).", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Next"))
		{
			if (spawnPointCount == 0)
				PrintToChat(param1, "[\x04DM\x01] There are no spawn points.");
			else
			{
				new spawnPoint = lastEditorSpawnPoint[param1] + 1;
				if (spawnPoint >= spawnPointCount)
					spawnPoint = 0;
				TeleportEntity(param1, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
				lastEditorSpawnPoint[param1] = spawnPoint;
				PrintToChat(param1, "[\x04DM\x01] Teleported to spawn point #%i (%i total).", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Add"))
		{
			AddSpawn(param1);
		}
		else if (StrEqual(info, "Insert"))
		{
			InsertSpawn(param1);
		}
		else if (StrEqual(info, "Delete"))
		{
			new spawnPoint = GetNearestSpawn(param1);
			if (spawnPoint != -1)
			{
				DeleteSpawn(spawnPoint);
				PrintToChat(param1, "[\x04DM\x01] Deleted spawn point #%i (%i total).", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Delete All"))
		{
			new Handle:panel = CreatePanel();
			SetPanelTitle(panel, "Delete all spawn points?");
			DrawPanelItem(panel, "Yes");
			DrawPanelItem(panel, "No");
			SendPanelToClient(panel, param1, Panel_ConfirmDeleteAllSpawns, MENU_TIME_FOREVER);
			CloseHandle(panel);
		}
		else if (StrEqual(info, "Save"))
		{
			if (WriteMapConfig())
				PrintToChat(param1, "[\x04DM\x01] Configuration has been saved.");
			else
				PrintToChat(param1, "[\x04DM\x01] Configuration could not be saved.");
		}
		if (!StrEqual(info, "Delete All"))
			DisplayMenu(BuildSpawnEditorMenu(), param1, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

public Panel_ConfirmDeleteAllSpawns(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
		{
			spawnPointCount = 0;
			PrintToChat(param1, "[\x04DM\x01] All spawn points have been deleted.");
		}
		DisplayMenu(BuildSpawnEditorMenu(), param1, MENU_TIME_FOREVER);
	}
}

public Action:RenderSpawnPoints(Handle:timer)
{
	if (!inEditMode)
		return Plugin_Stop;
	
	for (new i = 0; i < spawnPointCount; i++)
	{
		decl Float:spawnPosition[3];
		AddVectors(spawnPositions[i], spawnPointOffset, spawnPosition);
		TE_SetupGlowSprite(spawnPosition, glowSprite, 1.0, 0.5, 255);
		TE_SendToAll();
	}
	return Plugin_Continue;
}

GetNearestSpawn(clientIndex)
{
	if (spawnPointCount == 0)
	{
		PrintToChat(clientIndex, "[\x04DM\x01] There are no spawn points.");
		return -1;
	}
	
	decl Float:clientPosition[3];
	GetClientAbsOrigin(clientIndex, clientPosition);
	
	new nearestPoint = 0;
	new Float:nearestPointDistance = GetVectorDistance(spawnPositions[0], clientPosition, true);
	
	for (new i = 1; i < spawnPointCount; i++)
	{
		new Float:distance = GetVectorDistance(spawnPositions[i], clientPosition, true);
		if (distance < nearestPointDistance)
		{
			nearestPoint = i;
			nearestPointDistance = distance;
		}
	}
	return nearestPoint;
}

AddSpawn(clientIndex)
{
	if (spawnPointCount >= MAX_SPAWNS)
	{
		PrintToChat(clientIndex, "[\x04DM\x01] Could not add spawn point (max limit reached).");
		return;
	}
	GetClientAbsOrigin(clientIndex, spawnPositions[spawnPointCount]);
	GetClientAbsAngles(clientIndex, spawnAngles[spawnPointCount]);
	spawnPointCount++;
	PrintToChat(clientIndex, "[\x04DM\x01] Added spawn point #%i (%i total).", spawnPointCount, spawnPointCount);
}

InsertSpawn(clientIndex)
{
	if (spawnPointCount >= MAX_SPAWNS)
	{
		PrintToChat(clientIndex, "[\x04DM\x01] Could not add spawn point (max limit reached).");
		return;
	}
	
	if (spawnPointCount == 0)
		AddSpawn(clientIndex);
	else
	{
		// Move spawn points down the list to make room for insertion.
		for (new i = spawnPointCount - 1; i >= lastEditorSpawnPoint[clientIndex]; i--)
		{
			spawnPositions[i + 1] = spawnPositions[i];
			spawnAngles[i + 1] = spawnAngles[i];
		}
		// Insert new spawn point.
		GetClientAbsOrigin(clientIndex, spawnPositions[lastEditorSpawnPoint[clientIndex]]);
		GetClientAbsAngles(clientIndex, spawnAngles[lastEditorSpawnPoint[clientIndex]]);
		spawnPointCount++;
		PrintToChat(clientIndex, "[\x04DM\x01] Inserted spawn point at #%i (%i total).", lastEditorSpawnPoint[clientIndex] + 1, spawnPointCount);
	}
}

DeleteSpawn(spawnIndex)
{
	for (new i = spawnIndex; i < (spawnPointCount - 1); i++)
	{
		spawnPositions[i] = spawnPositions[i + 1];
		spawnAngles[i] = spawnAngles[i + 1];
	}
	spawnPointCount--;
}

/**
 * Updates the occupation status of all spawn points.
 */
public Action:UpdateSpawnPointStatus(Handle:timer)
{
	if (enabled && (spawnPointCount > 0))
	{
		// Retrieve player positions.
		decl Float:playerPositions[MaxClients][3];
		new numberOfAlivePlayers = 0;
	
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && (Teams:GetClientTeam(i) > TeamSpectator) && IsPlayerAlive(i))
			{
				GetClientAbsOrigin(i, playerPositions[numberOfAlivePlayers]);
				numberOfAlivePlayers++;
			}
		}
	
		// Check each spawn point for occupation by proximity to alive players
		for (new i = 0; i < spawnPointCount; i++)
		{
			spawnPointOccupied[i] = false;
			for (new j = 0; j < numberOfAlivePlayers; j++)
			{
				new Float:distance = GetVectorDistance(spawnPositions[i], playerPositions[j], true);
				if (distance < 10000.0)
				{
					spawnPointOccupied[i] = true;
					break;
				}
			}
		}
	}
	return Plugin_Continue;
}

MovePlayer(clientIndex)
{
	numberOfPlayerSpawns++; // Stats
	
	new Teams:clientTeam = Teams:GetClientTeam(clientIndex);
	
	new spawnPoint;
	new bool:spawnPointFound = false;
	
	decl Float:enemyEyePositions[MaxClients][3];
	new numberOfEnemies = 0;
	
	// Retrieve enemy positions if required by LoS/distance spawning (at eye level for LoS checking).
	if (lineOfSightSpawning || (spawnDistanceFromEnemies > 0.0))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && (Teams:GetClientTeam(i) > TeamSpectator) && IsPlayerAlive(i))
			{
				new bool:enemy = (ffa || (Teams:GetClientTeam(i) != clientTeam));
				if (enemy)
				{
					GetClientEyePosition(i, enemyEyePositions[numberOfEnemies]);
					numberOfEnemies++;
				}
			}
		}
	}
	
	if (lineOfSightSpawning)
	{
		losSearchAttempts++; // Stats
		
		// Try to find a suitable spawn point with a clear line of sight.
		for (new i = 0; i < lineOfSightAttempts; i++)
		{
			spawnPoint = GetRandomInt(0, spawnPointCount - 1);
			
			if (spawnPointOccupied[spawnPoint])
				continue;
			
			if (spawnDistanceFromEnemies > 0.0)
			{
				if (!IsPointSuitableDistance(spawnPoint, enemyEyePositions, numberOfEnemies))
					continue;
			}
			
			decl Float:spawnPointEyePosition[3];
			AddVectors(spawnPositions[spawnPoint], eyeOffset, spawnPointEyePosition);
			
			new bool:hasClearLineOfSight = true;
			
			for (new j = 0; j < numberOfEnemies; j++)
			{
				new Handle:trace = TR_TraceRayFilterEx(spawnPointEyePosition, enemyEyePositions[j], MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilterPlayer);
				if (!TR_DidHit(trace))
				{
					hasClearLineOfSight = false;
					CloseHandle(trace);
					break;
				}
				CloseHandle(trace);
			}
			if (hasClearLineOfSight)
			{
				spawnPointFound = true;
				break;
			}
		}
		// Stats
		if (spawnPointFound)
			losSearchSuccesses++;
		else
			losSearchFailures++;
	}
	
	// First fallback. Find a random unccupied spawn point at a suitable distance.
	if (!spawnPointFound && (spawnDistanceFromEnemies > 0.0))
	{
		distanceSearchAttempts++; // Stats
		
		for (new i = 0; i < 50; i++)
		{
			spawnPoint = GetRandomInt(0, spawnPointCount - 1);
			if (spawnPointOccupied[spawnPoint])
				continue;
			
			if (!IsPointSuitableDistance(spawnPoint, enemyEyePositions, numberOfEnemies))
				continue;
			
			spawnPointFound = true;
			break;
		}
		// Stats
		if (spawnPointFound)
			distanceSearchSuccesses++;
		else
			distanceSearchFailures++;
	}
	
	// Final fallback. Find a random unoccupied spawn point.
	if (!spawnPointFound)
	{
		for (new i = 0; i < 100; i++)
		{
			spawnPoint = GetRandomInt(0, spawnPointCount - 1);
			if (!spawnPointOccupied[spawnPoint])
			{
				spawnPointFound = true;
				break;
			}
		}
	}
	
	if (spawnPointFound)
	{
		TeleportEntity(clientIndex, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
		spawnPointOccupied[spawnPoint] = true;
		playerMoved[clientIndex] = true;
	}
	
	if (!spawnPointFound) spawnPointSearchFailures++; // Stats
}

bool:IsPointSuitableDistance(spawnPoint, const Float:enemyEyePositions[][3], numberOfEnemies)
{
	for (new i = 0; i < numberOfEnemies; i++)
	{
		new Float:distance = GetVectorDistance(spawnPositions[spawnPoint], enemyEyePositions[i], true);
		if (distance < spawnDistanceFromEnemies)
			return false;
	}
	return true;
}

public bool:TraceEntityFilterPlayer(entityIndex, mask)
{
	if ((entityIndex > 0) && (entityIndex <= MaxClients)) return false;
	return true;
}

public Action:Command_Stats(clientIndex, args)
{
	DisplaySpawnStats(clientIndex);
}

public Action:Command_ResetStats(clientIndex, args)
{
	ResetSpawnStats();
	PrintToChat(clientIndex, "[\x04DM\x01] Spawn statistics have been reset.");
}

ResetSpawnStats()
{
	numberOfPlayerSpawns = 0;
	losSearchAttempts = 0;
	losSearchSuccesses = 0;
	losSearchFailures = 0;
	distanceSearchAttempts = 0;
	distanceSearchSuccesses = 0;
	distanceSearchFailures = 0;
	spawnPointSearchFailures = 0;
}

DisplaySpawnStats(clientIndex)
{
	decl String:text[64];
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Spawn Stats:");
	Format(text, sizeof(text), "Number of player spawns: %i", numberOfPlayerSpawns);
	DrawPanelText(panel, text);
	Format(text, sizeof(text), "LoS search success rate: %.2f\%", (float(losSearchSuccesses) / float(losSearchAttempts)) * 100);
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "LoS search failure rate: %.2f\%", (float(losSearchFailures) / float(losSearchAttempts)) * 100);
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Distance search success rate: %.2f\%", (float(distanceSearchSuccesses) / float(distanceSearchAttempts)) * 100);
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Distance search failure rate: %.2f\%", (float(distanceSearchFailures) / float(distanceSearchAttempts)) * 100);
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "Spawn point search failures: %i", spawnPointSearchFailures);
	DrawPanelItem(panel, text);
	SendPanelToClient(panel, clientIndex, Panel_SpawnStats, MENU_TIME_FOREVER);
	CloseHandle(panel);
}

public Panel_SpawnStats(Handle:menu, MenuAction:action, param1, param2) { }

public Action:Event_Sound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (enabled)
	{
		if (spawnPointCount > 0)
		{
			new clientIndex;
			if ((entity > 0) && (entity <= MaxClients))
				clientIndex = entity;
			else
				clientIndex = GetEntDataEnt2(entity, ownerOffset);
	
			// Block ammo pickup sounds.
			if (StrEqual(sample, "items/ammopickup.wav"))
				return Plugin_Stop;
	
			// Block all sounds originating from players not yet moved.
			if ((clientIndex > 0) && (clientIndex <= MaxClients) && !playerMoved[clientIndex])
				return Plugin_Stop;
		}
		if (ffa)
		{
			if (StrContains(sample, "friendlyfire") != -1)
				return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action:CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason)
{
	if (enabled && respawning)
	{
		if ((reason == CSRoundEnd_CTWin) || (reason == CSRoundEnd_TerroristWin))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

BuildDisplayWeaponMenu(clientIndex, bool:primary)
{
	if (primary)
	{
		if (primaryMenus[clientIndex] != INVALID_HANDLE)
		{
			CancelMenu(primaryMenus[clientIndex]);
			CloseHandle(primaryMenus[clientIndex]);
			primaryMenus[clientIndex] = INVALID_HANDLE;
		}
	}
	else
	{
		if (secondaryMenus[clientIndex] != INVALID_HANDLE)
		{
			CancelMenu(secondaryMenus[clientIndex]);
			CloseHandle(secondaryMenus[clientIndex]);
			secondaryMenus[clientIndex] = INVALID_HANDLE;
		}
	}
	
	new Handle:menu;
	if (primary)
	{
		menu = CreateMenu(Menu_Primary);
		SetMenuTitle(menu, "Primary Weapon:");
	}
	else
	{
		menu = CreateMenu(Menu_Secondary);
		SetMenuTitle(menu, "Secondary Weapon:");
	}
	
	new Handle:weapons = (primary) ? primaryWeaponsAvailable : secondaryWeaponsAvailable;
	
	decl String:currentWeapon[24];
	currentWeapon = (primary) ? primaryWeapon[clientIndex] : secondaryWeapon[clientIndex];
	
	for (new i = 0; i < GetArraySize(weapons); i++)
	{
		decl String:weapon[24];
		GetArrayString(weapons, i, weapon, sizeof(weapon));
		
		decl String:weaponMenuName[24];
		GetTrieString(weaponMenuNames, weapon, weaponMenuName, sizeof(weaponMenuName));
		
		new weaponCount;
		GetTrieValue(weaponCounts, weapon, weaponCount);
		
		new weaponLimit;
		GetTrieValue(weaponLimits, weapon, weaponLimit);
		
		// If the client already has the weapon, then the limit does not apply.
		if (StrEqual(currentWeapon, weapon))
		{
			AddMenuItem(menu, weapon, weaponMenuName);
		}
		else
		{
			if ((weaponLimit == -1) || (weaponCount < weaponLimit))
			{
				AddMenuItem(menu, weapon, weaponMenuName);
			}
			else
			{
				decl String:text[64];
				Format(text, sizeof(text), "%s (Limited)", weaponMenuName);
				AddMenuItem(menu, weapon, text, ITEMDRAW_DISABLED);
			}
		}
	}
	if (primary)
	{
		primaryMenus[clientIndex] = menu;
		DisplayMenu(primaryMenus[clientIndex], clientIndex, MENU_TIME_FOREVER);
	}
	else
	{
		secondaryMenus[clientIndex] = menu;
		DisplayMenu(secondaryMenus[clientIndex], clientIndex, MENU_TIME_FOREVER);
	}
}

IncrementWeaponCount(String:weapon[])
{
	new weaponCount;
	GetTrieValue(weaponCounts, weapon, weaponCount);
	SetTrieValue(weaponCounts, weapon, weaponCount + 1);
}

DecrementWeaponCount(String:weapon[])
{
	if (!StrEqual(weapon, "none"))
	{
		new weaponCount;
		GetTrieValue(weaponCounts, weapon, weaponCount);
		SetTrieValue(weaponCounts, weapon, weaponCount - 1);
	}
}

public Action:Event_TextMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (ffa)
	{
		decl String:text[64];
		if(GetUserMessageType() == UM_Protobuf)
			PbReadString(bf, "params", text, sizeof(text), 0);
		else
			BfReadString(bf, text, sizeof(text));
		
		if (StrContains(text, "#SFUI_Notice_Killed_Teammate") != -1)
			return Plugin_Handled;
		
		if (StrContains(text, "#Cstrike_TitlesTXT_Game_teammate_attack") != -1)
			return Plugin_Handled;
		
		if (StrContains(text, "#Hint_try_not_to_injure_teammates") != -1)
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Event_HintText(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (ffa)
	{
		decl String:text[64];
		if(GetUserMessageType() == UM_Protobuf)
			PbReadString(bf, "text", text, sizeof(text));
		else
			BfReadString(bf, text, sizeof(text));
	
		if (StrContains(text, "#SFUI_Notice_Hint_careful_around_teammates") != -1)
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Event_RadioText(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	static String:grenadeTriggers[][] = {
		"#SFUI_TitlesTXT_Fire_in_the_hole",
		"#SFUI_TitlesTXT_Flashbang_in_the_hole",
		"#SFUI_TitlesTXT_Smoke_in_the_hole",
		"#SFUI_TitlesTXT_Decoy_in_the_hole",
		"#SFUI_TitlesTXT_Molotov_in_the_hole",
		"#SFUI_TitlesTXT_Incendiary_in_the_hole"
	};
	
	if (!displayGrenadeMessages)
	{
		decl String:text[64];
		if(GetUserMessageType() == UM_Protobuf)
		{
			PbReadString(bf, "msg_name", text, sizeof(text));
			// 0: name
			// 1: msg_name == #Game_radio_location ? location : translation phrase
			// 2: if msg_name == #Game_radio_location : translation phrase
			if (StrContains(text, "#Game_radio_location") != -1)
				PbReadString(bf, "params", text, sizeof(text), 2);
			else
				PbReadString(bf, "params", text, sizeof(text), 1);
		}
		else
		{
			BfReadString(bf, text, sizeof(text));
			if (StrContains(text, "#Game_radio_location") != -1)
				BfReadString(bf, text, sizeof(text));
			BfReadString(bf, text, sizeof(text));
			BfReadString(bf, text, sizeof(text));
	}
		
		for (new i = 0; i < sizeof(grenadeTriggers); i++)
		{
			if (StrEqual(text, grenadeTriggers[i]))
				return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

RemoveRagdoll(clientIndex)
{
	if (IsValidEdict(clientIndex))
	{
		new ragdoll = GetEntDataEnt2(clientIndex, ragdollOffset);
		if (ragdoll != -1)
			AcceptEntityInput(ragdoll, "Kill");
	}
}