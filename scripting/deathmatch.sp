#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <csgocolors>
#include <cstrike>
#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_VERSION 	"2.0.4c"
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
#define DMG_HEADSHOT (1 << 30)

// Native console variables
new Handle:mp_ct_default_primary;
new Handle:mp_t_default_primary;
new Handle:mp_ct_default_secondary;
new Handle:mp_t_default_secondary;
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
new Handle:cvar_dm_display_panel;
new Handle:cvar_dm_display_panel_damage;
new Handle:cvar_dm_headshot_only;
new Handle:cvar_dm_headshot_only_allow_world;
new Handle:cvar_dm_headshot_only_allow_knife;
new Handle:cvar_dm_headshot_only_allow_taser;
new Handle:cvar_dm_headshot_only_allow_nade;
new Handle:cvar_dm_remove_objectives;
new Handle:cvar_dm_respawning;
new Handle:cvar_dm_respawn_time;
new Handle:cvar_dm_gun_menu_mode;
new Handle:cvar_dm_los_spawning;
new Handle:cvar_dm_los_attempts;
new Handle:cvar_dm_spawn_distance;
new Handle:cvar_dm_spawn_time;
new Handle:cvar_dm_remove_weapons;
new Handle:cvar_dm_replenish_ammo;
new Handle:cvar_dm_replenish_clip;
new Handle:cvar_dm_replenish_grenade;
new Handle:cvar_dm_replenish_hegrenade;
new Handle:cvar_dm_replenish_grenade_kill;
new Handle:cvar_dm_hp_start;
new Handle:cvar_dm_hp_max;
new Handle:cvar_dm_hp_kill;
new Handle:cvar_dm_hp_hs;
new Handle:cvar_dm_hp_knife;
new Handle:cvar_dm_hp_nade;
new Handle:cvar_dm_hp_messages;
new Handle:cvar_dm_nade_messages;
new Handle:cvar_dm_armor;
new Handle:cvar_dm_armor_full;
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
new bool:displayPanel;
new bool:displayPanelDamage;
new bool:hsOnly;
new bool:hsOnly_AllowWorld;
new bool:hsOnly_AllowKnife;
new bool:hsOnly_AllowTaser;
new bool:hsOnly_AllowNade;
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
new bool:replenishClip;
new bool:replenishGrenade;
new bool:replenishHEGrenade;
new bool:replenishGrenadeKill;
new startHP;
new maxHP;
new HPPerKill;
new HPPerHeadshotKill;
new HPPerKnifeKill;
new HPPerNadeKill;
new bool:displayHPMessages;
new bool:displayGrenadeMessages;
new bool:roundEnded = false;
new defaultColor[4] = { 255, 255, 255, 255 };
new tColor[4] = { 255, 0, 0, 200 };
new ctColor[4] = { 0, 0, 255, 200 };
new spawnPointCount = 0;
new Float:spawnPositions[MAX_SPAWNS][3];
new Float:spawnAngles[MAX_SPAWNS][3];
new bool:spawnPointOccupied[MAX_SPAWNS] = {false, ...};
new Float:eyeOffset[3] = { 0.0, 0.0, 64.0 }; // CSGO offset.
new Float:spawnPointOffset[3] = { 0.0, 0.0, 20.0 };
new bool:inEditMode = false;
// Offsets
new ownerOffset;
new armorOffset;
new helmetOffset;
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
new bool:armorChest;
new bool:armorFull;
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
// Strings for HS Only
new String:g_sGrenade[32],
	String:g_sWeapon[32];
new g_iHealth, g_Armor;
// Static Offsets
static g_iWeapons_Clip1Offset;

public OnPluginStart()
{
	// Load translations for multi-language
	LoadTranslations("deathmatch.phrases");
	LoadTranslations("common.phrases");
	// Create spawns directory if necessary.
	char spawnsPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, spawnsPath, sizeof(spawnsPath), "configs/deathmatch/spawns");
	if (!DirExists(spawnsPath))
		CreateDirectory(spawnsPath, 711);
	// Find offsets
	ownerOffset = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	armorOffset = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
	helmetOffset = FindSendPropOffs("CCSPlayer", "m_bHasHelmet");
	ammoTypeOffset = FindSendPropOffs("CBaseCombatWeapon", "m_iPrimaryAmmoType");
	ammoOffset = FindSendPropOffs("CCSPlayer", "m_iAmmo");
	ragdollOffset = FindSendPropOffs("CCSPlayer", "m_hRagdoll");
	// Create arrays to store available weapons loaded by config
	primaryWeaponsAvailable = CreateArray(24);
	secondaryWeaponsAvailable = CreateArray(10);
	// Create trie to store menu names for weapons
	BuildWeaponMenuNames();
	// Create trie to store weapon limits and counts
	weaponLimits = CreateTrie();
	weaponCounts = CreateTrie();
	// Create menus
	optionsMenu1 = BuildOptionsMenu(true);
	optionsMenu2 = BuildOptionsMenu(false);
	// Retrieve native console variables
	mp_ct_default_primary = FindConVar("mp_ct_default_primary");
	mp_t_default_primary = FindConVar("mp_t_default_primary");
	mp_ct_default_secondary = FindConVar("mp_ct_default_secondary");
	mp_t_default_secondary = FindConVar("mp_t_default_secondary");
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
	cvar_dm_display_panel = CreateConVar("dm_display_panel", "0", "Display a panel showing health of the victim.");
	cvar_dm_display_panel_damage = CreateConVar("dm_display_panel_damage", "0", "Display a panel showing damage done to a player.");
	cvar_dm_headshot_only = CreateConVar("dm_headshot_only", "0", "Headshot only mode.");
	cvar_dm_headshot_only_allow_world = CreateConVar("dm_headshot_only_allow_world", "0", "Enable world damage during headshot only mode.");
	cvar_dm_headshot_only_allow_knife = CreateConVar("dm_headshot_only_allow_knife", "0", "Enable knife damage during headshot only mode.");
	cvar_dm_headshot_only_allow_taser = CreateConVar("dm_headshot_only_allow_taser", "0", "Enable taser damage during headshot only mode.");
	cvar_dm_headshot_only_allow_nade = CreateConVar("dm_headshot_only_allow_nade", "0", "Enable grenade damage during headshot only mode.");
	cvar_dm_remove_objectives = CreateConVar("dm_remove_objectives", "1", "Remove objectives (disables bomb sites, and removes c4 and hostages).");
	cvar_dm_respawning = CreateConVar("dm_respawning", "1", "Enable respawning.");
	cvar_dm_respawn_time = CreateConVar("dm_respawn_time", "2.0", "Respawn time.");
	cvar_dm_gun_menu_mode = CreateConVar("dm_gun_menu_mode", "1", "Gun menu mode. 1) Enabled. 2) Pistol Only. 3) Random weapons every round. 4) Disabled.");
	cvar_dm_los_spawning = CreateConVar("dm_los_spawning", "1", "Enable line of sight spawning. If enabled, players will be spawned at a point where they cannot see enemies, and enemies cannot see them.");
	cvar_dm_los_attempts = CreateConVar("dm_los_attempts", "10", "Maximum number of attempts to find a suitable line of sight spawn point.");
	cvar_dm_spawn_distance = CreateConVar("dm_spawn_distance", "0.0", "Minimum distance from enemies at which a player can spawn.");
	cvar_dm_spawn_time = CreateConVar("dm_spawn_time", "1.0", "Spawn protection time.");
	cvar_dm_remove_weapons = CreateConVar("dm_remove_weapons", "1", "Remove ground weapons.");
	cvar_dm_replenish_ammo = CreateConVar("dm_replenish_ammo", "1", "Replenish ammo reserve.");
	cvar_dm_replenish_clip = CreateConVar("dm_replenish_clip", "1", "Replenish ammo clip.");
	cvar_dm_replenish_grenade = CreateConVar("dm_replenish_grenade", "0", "Unlimited player grenades.");
	cvar_dm_replenish_hegrenade = CreateConVar("dm_replenish_hegrenade", "0", "Unlimited hegrenades.");
	cvar_dm_replenish_grenade_kill = CreateConVar("dm_replenish_grenade_kill", "0", "Give players their grenade back on successful kill.");
	cvar_dm_hp_start = CreateConVar("dm_hp_start", "100", "Spawn HP.");
	cvar_dm_hp_max = CreateConVar("dm_hp_max", "100", "Maximum HP.");
	cvar_dm_hp_kill = CreateConVar("dm_hp_kill", "5", "HP per kill.");
	cvar_dm_hp_hs = CreateConVar("dm_hp_hs", "10", "HP per headshot kill.");
	cvar_dm_hp_knife = CreateConVar("dm_hp_knife", "50", "HP per knife kill.");
	cvar_dm_hp_nade = CreateConVar("dm_hp_nade", "30", "HP per nade kill.");
	cvar_dm_hp_messages = CreateConVar("dm_hp_messages", "1", "Display HP messages.");
	cvar_dm_nade_messages = CreateConVar("dm_nade_messages", "1", "Display grenade messages.");
	cvar_dm_armor = CreateConVar("dm_armor", "0", "Give players chest armor.");
	cvar_dm_armor_full = CreateConVar("dm_armor_full", "1", "Give players head and chest armor.");
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
	decl String:guns[32];
	Format(guns, sizeof(guns), "%t", "Guns Menu");
	RegConsoleCmd(guns, Command_Guns);
	// Event hooks
	HookConVarChange(cvar_dm_enabled, Event_CvarChange);
	HookConVarChange(cvar_dm_welcomemsg, Event_CvarChange);
	HookConVarChange(cvar_dm_free_for_all, Event_CvarChange);
	HookConVarChange(cvar_dm_display_panel, Event_CvarChange);
	HookConVarChange(cvar_dm_display_panel_damage, Event_CvarChange);
	HookConVarChange(cvar_dm_headshot_only, Event_CvarChange);
	HookConVarChange(cvar_dm_headshot_only_allow_world, Event_CvarChange);
	HookConVarChange(cvar_dm_headshot_only_allow_knife, Event_CvarChange);
	HookConVarChange(cvar_dm_headshot_only_allow_taser, Event_CvarChange);
	HookConVarChange(cvar_dm_headshot_only_allow_nade, Event_CvarChange);
	HookConVarChange(cvar_dm_remove_objectives, Event_CvarChange);
	HookConVarChange(cvar_dm_respawning, Event_CvarChange);
	HookConVarChange(cvar_dm_respawn_time, Event_CvarChange);
	HookConVarChange(cvar_dm_gun_menu_mode, Event_CvarChange);
	HookConVarChange(cvar_dm_los_spawning, Event_CvarChange);
	HookConVarChange(cvar_dm_los_attempts, Event_CvarChange);
	HookConVarChange(cvar_dm_spawn_distance, Event_CvarChange);
	HookConVarChange(cvar_dm_spawn_time, Event_CvarChange);
	HookConVarChange(cvar_dm_remove_weapons, Event_CvarChange);
	HookConVarChange(cvar_dm_replenish_ammo, Event_CvarChange);
	HookConVarChange(cvar_dm_replenish_clip, Event_CvarChange);
	HookConVarChange(cvar_dm_replenish_grenade, Event_CvarChange);
	HookConVarChange(cvar_dm_replenish_hegrenade, Event_CvarChange);
	HookConVarChange(cvar_dm_replenish_grenade_kill, Event_CvarChange);
	HookConVarChange(cvar_dm_hp_start, Event_CvarChange);
	HookConVarChange(cvar_dm_hp_max, Event_CvarChange);
	HookConVarChange(cvar_dm_hp_kill, Event_CvarChange);
	HookConVarChange(cvar_dm_hp_hs, Event_CvarChange);
	HookConVarChange(cvar_dm_hp_knife, Event_CvarChange);
	HookConVarChange(cvar_dm_hp_nade, Event_CvarChange);
	HookConVarChange(cvar_dm_hp_messages, Event_CvarChange);
	HookConVarChange(cvar_dm_nade_messages, Event_CvarChange);
	HookConVarChange(cvar_dm_armor, Event_CvarChange);
	HookConVarChange(cvar_dm_armor_full, Event_CvarChange);
	HookConVarChange(cvar_dm_zeus, Event_CvarChange);
	HookConVarChange(cvar_dm_nades_incendiary, Event_CvarChange);
	HookConVarChange(cvar_dm_nades_molotov, Event_CvarChange);
	HookConVarChange(cvar_dm_nades_decoy, Event_CvarChange);
	HookConVarChange(cvar_dm_nades_flashbang, Event_CvarChange);
	HookConVarChange(cvar_dm_nades_he, Event_CvarChange);
	HookConVarChange(cvar_dm_nades_smoke, Event_CvarChange);
	AddCommandListener(Event_Say, "say");
	AddCommandListener(Event_Say, "say_team");
	HookUserMessage(GetUserMessageId("TextMsg"), Event_TextMsg, true);
	HookUserMessage(GetUserMessageId("HintText"), Event_HintText, true);
	HookUserMessage(GetUserMessageId("RadioText"), Event_RadioText, true);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_hurt", EventPlayerHurt, EventHookMode_Pre);
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

	g_iWeapons_Clip1Offset = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");

	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}

	g_iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");

	if (g_iHealth == -1)
	{
		SetFailState("[DM] Error - Unable to get offset for CSSPlayer::m_iHealth");
	}

	g_Armor = FindSendPropOffs("CCSPlayer", "m_ArmorValue");

	if (g_Armor == -1)
	{
		SetFailState("[DM] Error - Unable to get offset for CSSPlayer::m_ArmorValue");
	}

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
		SetNoSpawnWeapons();
		if (ffa)
			EnableFFA();
	}
}

public OnClientPostAdminCheck(client)
{
	if (enabled)
	{
		if (welcomemsg)
		{
			CreateTimer(10.0, Timer_WelcomeMsg, GetClientUserId(client));
		}
		ResetClientSettings(client);
	}
}

public Action:Timer_WelcomeMsg(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		PrintHintText(client, "This server is running:\n <font color='#FF0000'>Deathmatch</font> Version <font color='#00FF00'>%s</font>", PLUGIN_VERSION);
		//CPrintToChat(client, "[\x04WELCOME\x01] This server is running \x04Deathmatch \x01v%s, PLUGIN_VERSION");
	}
	return Plugin_Stop;
}

public OnClientDisconnect(client)
{
	RemoveRagdoll(client);
}


stock bool:IsClientValid(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

ResetClientSettings(client)
{
	lastEditorSpawnPoint[client] = -1;
	SetClientGunModeSettings(client);
	infoMessageCount[client] = 3;
	weaponsGivenThisRound[client] = false;
	newWeaponsSelected[client] = false;
	playerMoved[client] = false;
}

SetClientGunModeSettings(client)
{
	if (gunMenuMode != 3)
	{
		if(gunMenuMode == 1 && IsClientValid(client) && !IsFakeClient(client))
		{
			if (StrEqual(primaryWeapon[client], "") || StrEqual(secondaryWeapon[client], ""))
			{
				primaryWeapon[client] = "none";
				secondaryWeapon[client] = "none";
			}
		}
		firstWeaponSelection[client] = true;
		rememberChoice[client] = false;
		if (gunMenuMode == 1 && IsFakeClient(client))
		{
			primaryWeapon[client] = "random";
			secondaryWeapon[client] = "random";
			firstWeaponSelection[client] = false;
			rememberChoice[client] = true;
		}
		else if (gunMenuMode == 2 && IsFakeClient(client))
		{
			primaryWeapon[client] = "none";
			secondaryWeapon[client] = "random";
			firstWeaponSelection[client] = false;
			rememberChoice[client] = true;
		}
	}
	else if (gunMenuMode == 3)
	{
		primaryWeapon[client] = "random";
		secondaryWeapon[client] = "random";
		firstWeaponSelection[client] = false;
		rememberChoice[client] = true;
	}
}

public Event_CvarChange(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	UpdateState();
}

LoadConfig()
{
	new Handle:keyValues = CreateKeyValues("Deathmatch Config");
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/deathmatch/deathmatch.ini");

	if (!FileToKeyValues(keyValues, path))
		SetFailState("The configuration file could not be read.");

	decl String:key[25];
	decl String:value[25];

	if (!KvJumpToKey(keyValues, "Options"))
		SetFailState("The configuration file is corrupt (\"Options\" section could not be found).");

	KvGetString(keyValues, "dm_enabled", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_enabled, value);

	KvGetString(keyValues, "dm_welcomemsg", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_welcomemsg, value);

	KvGetString(keyValues, "dm_free_for_all", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_free_for_all, value);

	KvGetString(keyValues, "dm_display_panel", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_display_panel, value);

	KvGetString(keyValues, "dm_display_panel_damage", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_display_panel_damage, value);

	KvGetString(keyValues, "dm_headshot_only", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_headshot_only, value);

	KvGetString(keyValues, "dm_headshot_only_allow_world", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_headshot_only_allow_world, value);

	KvGetString(keyValues, "dm_headshot_only_allow_knife", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_headshot_only_allow_knife, value);

	KvGetString(keyValues, "dm_headshot_only_allow_taser", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_headshot_only_allow_taser, value);

	KvGetString(keyValues, "dm_headshot_only_allow_nade", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_headshot_only_allow_nade, value);

	KvGetString(keyValues, "dm_remove_objectives", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_remove_objectives, value);

	KvGetString(keyValues, "dm_respawning", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_respawning, value);

	KvGetString(keyValues, "dm_respawn_time", value, sizeof(value), "2.0");
	SetConVarString(cvar_dm_respawn_time, value);

	KvGetString(keyValues, "dm_gun_menu_mode", value, sizeof(value), "1");
	SetConVarString(cvar_dm_gun_menu_mode, value);

	KvGetString(keyValues, "dm_line_of_sight_spawning", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_los_spawning, value);

	KvGetString(keyValues, "dm_line_of_sight_attempts", value, sizeof(value), "10");
	SetConVarString(cvar_dm_los_attempts, value);

	KvGetString(keyValues, "dm_spawn_distance_from_enemies", value, sizeof(value), "0.0");
	SetConVarString(cvar_dm_spawn_distance, value);

	KvGetString(keyValues, "dm_spawn_protection_time", value, sizeof(value), "1.0");
	SetConVarString(cvar_dm_spawn_time, value);

	KvGetString(keyValues, "dm_remove_weapons", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_remove_weapons, value);

	KvGetString(keyValues, "dm_replenish_ammo", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_replenish_ammo, value);

	KvGetString(keyValues, "dm_replenish_clip", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_replenish_clip, value);

	KvGetString(keyValues, "dm_replenish_grenade", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_replenish_grenade, value);

	KvGetString(keyValues, "dm_replenish_hegrenade", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_replenish_hegrenade, value);

	KvGetString(keyValues, "dm_replenish_grenade_kill", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_replenish_grenade_kill, value);

	KvGetString(keyValues, "dm_player_hp_start", value, sizeof(value), "100");
	SetConVarString(cvar_dm_hp_start, value);

	KvGetString(keyValues, "dm_player_hp_max", value, sizeof(value), "100");
	SetConVarString(cvar_dm_hp_max, value);

	KvGetString(keyValues, "dm_hp_per_kill", value, sizeof(value), "5");
	SetConVarString(cvar_dm_hp_kill, value);

	KvGetString(keyValues, "dm_hp_per_headshot_kill", value, sizeof(value), "10");
	SetConVarString(cvar_dm_hp_hs, value);

	KvGetString(keyValues, "dm_hp_per_knife_kill", value, sizeof(value), "50");
	SetConVarString(cvar_dm_hp_knife, value);

	KvGetString(keyValues, "dm_hp_per_nade_kill", value, sizeof(value), "30");
	SetConVarString(cvar_dm_hp_nade, value);

	KvGetString(keyValues, "dm_display_hp_messages", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_hp_messages, value);

	KvGetString(keyValues, "dm_display_grenade_messages", value, sizeof(value), "yes");
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
			new limit = KvGetNum(keyValues, NULL_STRING, -1);
			if(limit == 0) {continue;}
			PushArrayString(primaryWeaponsAvailable, key);
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
			new limit = KvGetNum(keyValues, NULL_STRING, -1);
			if(limit == 0) {continue;}
			PushArrayString(secondaryWeaponsAvailable, key);
			SetTrieValue(weaponLimits, key, limit);
		} while (KvGotoNextKey(keyValues, false));
	}

	KvGoBack(keyValues);
	KvGoBack(keyValues);

	if (!KvJumpToKey(keyValues, "Misc"))
		SetFailState("The configuration file is corrupt (\"Misc\" section could not be found).");

	KvGetString(keyValues, "armor (chest)", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_armor, value);

	KvGetString(keyValues, "armor (full)", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_armor_full, value);

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
	displayPanel = GetConVarBool(cvar_dm_display_panel);
	displayPanelDamage = GetConVarBool(cvar_dm_display_panel_damage);
	hsOnly = GetConVarBool(cvar_dm_headshot_only);
	hsOnly_AllowWorld = GetConVarBool(cvar_dm_headshot_only_allow_world);
	hsOnly_AllowKnife = GetConVarBool(cvar_dm_headshot_only_allow_knife);
	hsOnly_AllowTaser = GetConVarBool(cvar_dm_headshot_only_allow_taser);
	hsOnly_AllowNade = GetConVarBool(cvar_dm_headshot_only_allow_nade);
	removeObjectives = GetConVarBool(cvar_dm_remove_objectives);
	respawning = GetConVarBool(cvar_dm_respawning);
	respawnTime = GetConVarFloat(cvar_dm_respawn_time);
	gunMenuMode = GetConVarInt(cvar_dm_gun_menu_mode);
	lineOfSightSpawning = GetConVarBool(cvar_dm_los_spawning);
	lineOfSightAttempts = GetConVarInt(cvar_dm_los_attempts);
	spawnDistanceFromEnemies = GetConVarFloat(cvar_dm_spawn_distance);
	spawnProtectionTime = GetConVarFloat(cvar_dm_spawn_time);
	removeWeapons = GetConVarBool(cvar_dm_remove_weapons);
	replenishAmmo = GetConVarBool(cvar_dm_replenish_ammo);
	replenishClip = GetConVarBool(cvar_dm_replenish_clip);
	replenishGrenade = GetConVarBool(cvar_dm_replenish_grenade);
	replenishHEGrenade = GetConVarBool(cvar_dm_replenish_hegrenade);
	replenishGrenadeKill = GetConVarBool(cvar_dm_replenish_grenade_kill);
	startHP = GetConVarInt(cvar_dm_hp_start);
	maxHP = GetConVarInt(cvar_dm_hp_max);
	HPPerKill = GetConVarInt(cvar_dm_hp_kill);
	HPPerHeadshotKill = GetConVarInt(cvar_dm_hp_hs);
	HPPerKnifeKill = GetConVarInt(cvar_dm_hp_knife);
	HPPerNadeKill = GetConVarInt(cvar_dm_hp_nade);
	displayHPMessages = GetConVarBool(cvar_dm_hp_messages);
	displayGrenadeMessages = GetConVarBool(cvar_dm_nade_messages);
	armorChest = GetConVarBool(cvar_dm_armor);
	armorFull = GetConVarBool(cvar_dm_armor_full);
	zeus = GetConVarBool(cvar_dm_zeus);
	incendiary = GetConVarInt(cvar_dm_nades_incendiary);
	molotov = GetConVarInt(cvar_dm_nades_molotov);
	decoy = GetConVarInt(cvar_dm_nades_decoy);
	flashbang = GetConVarInt(cvar_dm_nades_flashbang);
	he = GetConVarInt(cvar_dm_nades_he);
	smoke = GetConVarInt(cvar_dm_nades_smoke);

	if (respawnTime < 0.0) respawnTime = 0.0;
	if (gunMenuMode < 1) gunMenuMode = 1;
	if (gunMenuMode > 4) gunMenuMode = 4;
	if (lineOfSightAttempts < 0) lineOfSightAttempts = 0;
	if (spawnDistanceFromEnemies < 0.0) spawnDistanceFromEnemies = 0.0;
	if (spawnProtectionTime < 0.0) spawnProtectionTime = 0.0;
	if (startHP < 1) startHP = 1;
	if (maxHP < 1) maxHP = 1;
	if (HPPerKill < 0) HPPerKill = 0;
	if (HPPerHeadshotKill < 0) HPPerHeadshotKill = 0;
	if (HPPerKnifeKill < 0) HPPerKnifeKill = 0;
	if (HPPerNadeKill < 0) HPPerNadeKill = 0;
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
		SetNoSpawnWeapons();
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
			if (gunMenuMode == 4)
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

SetNoSpawnWeapons()
{
	SetConVarString(mp_ct_default_primary, "");
	SetConVarString(mp_t_default_primary, "");
	SetConVarString(mp_ct_default_secondary, "");
	SetConVarString(mp_t_default_secondary, "");
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

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/deathmatch/spawns/%s.txt", map);

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

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/deathmatch/spawns/%s.txt", map);

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

public Action:Event_Say(client, const String:command[], arg)
{
	static String:menuTriggers[][] = { "gun", "!gun", "/gun", "guns", "!guns", "/guns", "menu", "!menu", "/menu", "weapon", "!weapon", "/weapon", "weapons", "!weapons", "/weapons" };

	if (enabled && IsClientValid(client) && (Teams:GetClientTeam(client) > TeamSpectator))
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
				if (gunMenuMode == 1 || gunMenuMode == 2)
					DisplayOptionsMenu(client);
				else
					CPrintToChat(client, "[\x04DM\x01] %t", "Guns Disabled");
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

DisplayOptionsMenu(client)
{
	if (!firstWeaponSelection[client])
		DisplayMenu(optionsMenu1, client, MENU_TIME_FOREVER);
	else
		DisplayMenu(optionsMenu2, client, MENU_TIME_FOREVER);
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the player joins spectator, close any open menu, and remove their ragdoll.
	if ((client != 0) && (Teams:GetClientTeam(client) == TeamSpectator))
	{
		CancelClientMenu(client);
		RemoveRagdoll(client);
	}
	if (enabled && respawning)
		CreateTimer(respawnTime, Respawn, client);
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
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (Teams:GetClientTeam(client) > TeamSpectator)
		{
			// Hide radar.
			if (ffa)
			{
				CreateTimer(0.0, RemoveRadar, client);
			}
			// Display help message.
			if ((gunMenuMode == 1 || gunMenuMode == 2) && infoMessageCount[client] > 0)
			{
				CPrintToChat(client, "[\x04DM\x01] %t", "Guns Menu");
				infoMessageCount[client]--;
			}
			// Display the panel for attacker information.
			if (displayPanel)
			{
				CreateTimer(1.0, PanelDisplay, GetEventInt(event, "userid"), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			// Teleport player to custom spawn point.
			if (spawnPointCount > 0)
			{
				MovePlayer(client);
			}
			// Enable player spawn protection.
			if (spawnProtectionTime > 0.0)
			{
				EnableSpawnProtection(client);
			}
			// Set health.
			if (startHP != 100)
			{
				SetEntityHealth(client, startHP);
			}
			// Give equipment
			if (armorChest)
			{
				SetEntData(client, armorOffset, 100);
				SetEntData(client, helmetOffset, 0);
			}
			if (armorFull)
			{
				SetEntData(client, armorOffset, 100);
				SetEntData(client, helmetOffset, 1);
			}
			else
			{
				SetEntData(client, armorOffset, 0);
				SetEntData(client, helmetOffset, 0);
			}
			// Give weapons or display menu.
			weaponsGivenThisRound[client] = false;
			RemoveClientWeapons(client);
			// Give weapons selected from menu.
			if (newWeaponsSelected[client])
			{
				GiveSavedWeapons(client, true, true);
				newWeaponsSelected[client] = false;
			}
			// Give the remembered weapon choice.
			else if (rememberChoice[client])
			{
				if (gunMenuMode == 1 || gunMenuMode == 3)
				{
					GiveSavedWeapons(client, true, true);
				}
				// Give only pistols if remembered.
				else if (gunMenuMode == 2)
				{
					GiveSavedWeapons(client, false, true);
				}
			}
			// Display the gun menu to new users.
			else
			{
				// All weapons menu.
				if (gunMenuMode == 1)
				{
					DisplayOptionsMenu(client);
				}
				// Pistol only weapons menu.
				else if (gunMenuMode == 2)
				{
					DisplayOptionsMenu(client);
				}
			}
			// Remove C4.
			if (removeObjectives)
			{
				StripC4(client);
			}
		}
		if (hsOnly)
		{
			SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
		}
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (enabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new attackerIndex = GetClientOfUserId(GetEventInt(event, "attacker"));
		decl String:weapon[6];
		decl String:hegrenade[16];
		decl String:decoygrenade[16];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		GetEventString(event, "weapon", hegrenade, sizeof(hegrenade));
		GetEventString(event, "weapon", decoygrenade, sizeof(decoygrenade));

		new bool:validAttacker = (attackerIndex != 0) && IsPlayerAlive(attackerIndex);

		// Reward the attacker with ammo.
		if (validAttacker)
		{
			GiveAmmo(INVALID_HANDLE, attackerIndex);
		}

		// Reward attacker with HP.
		if (validAttacker)
		{
			new bool:knifed = StrEqual(weapon, "knife");
			new bool:nades = StrEqual(hegrenade, "hegrenade");
			new bool:decoys = StrEqual(decoygrenade, "decoy");
			new bool:headshot = GetEventBool(event, "headshot");

			if ((knifed && (HPPerKnifeKill > 0)) || (!knifed && (HPPerKill > 0)) || (headshot && (HPPerHeadshotKill > 0)) || (!headshot && (HPPerKill > 0)))
			{
				new attackerHP = GetClientHealth(attackerIndex);

				if (attackerHP < maxHP)
				{
					new addHP;
					if (knifed)
						addHP = HPPerKnifeKill;
					else if (headshot)
						addHP = HPPerHeadshotKill;
					else if (nades)
						addHP = HPPerNadeKill;
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
						CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%iHP\x01 %t", HPPerKnifeKill, "HP Knife Kill");
					else if (headshot)
						CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%iHP\x01 %t", HPPerHeadshotKill, "HP Headshot Kill");
					else if (nades)
						CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%iHP\x01 %t", HPPerNadeKill, "HP Nade Kill");
					else
						CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%iHP\x01 %t", HPPerKill, "HP Kill");
				}
			}

			if (replenishGrenadeKill)
			{
				if (IsClientInGame(attackerIndex) && IsPlayerAlive(attackerIndex))
				{
					if (nades)
						GivePlayerItem(attackerIndex, "weapon_hegrenade");
					if (decoys)
						GivePlayerItem(attackerIndex, "weapon_decoy");
				}
			}
		}
		// Correct the attacker's score if this was a teamkill.
		/* if (ffa)
		{
			if ((attackerIndex != 0) && (client != attackerIndex) && (GetClientTeam(client) == GetClientTeam(attackerIndex)))
				SetEntProp(attackerIndex, Prop_Data, "m_iFrags", GetClientFrags(attackerIndex) + 2);
		} */
		// Respawn player.
		if (respawning)
			CreateTimer(respawnTime, Respawn, client);
	}
}

public Action:EventPlayerHurt(Handle:event, const String:name[],bool:dontBroadcast)
{
	if (displayPanel)
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new health = GetEventInt(event, "health");

		if (attacker != victim && victim != 0)
		{
			if (0 < health)
			{
				if (displayPanelDamage)
				{
					PrintHintText(attacker, "%t <font color='#FF0000'>%i</font> %t <font color='#00FF00'>%N</font>\n %t <font color='#00FF00'>%i</font>", "Panel Damage Giver", GetEventInt(event, "dmg_health"), "Panel Damage Taker", victim, "Panel Health Remaining", health);
				}
				else
				{
					PrintHintText(attacker, "%t <font color='#FF0000'>%i</font>", "Panel Health Remaining", health);
				}
			}
			else
			{
				PrintHintText(attacker, "\n   %t", "Panel Kill Confirmed");
			}
		}
	}

	if (hsOnly)
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new dhealth = GetEventInt(event, "dmg_health");
		new darmor = GetEventInt(event, "dmg_armor");
		new health = GetEventInt(event, "health");
		new armor = GetEventInt(event, "armor");
		decl String:weapon[32];
		decl String:grenade[16];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		GetEventString(event, "weapon", grenade, sizeof(grenade));

		if (!hsOnly_AllowNade)
		{
			if (StrEqual(grenade, "hegrenade", false))
			{
				if (attacker != victim && victim != 0)
				{
					if (dhealth > 0)
					{
						SetEntData(victim, g_iHealth, (health + dhealth), 4, true);
					}
					if (darmor > 0)
					{
						SetEntData(victim, g_Armor, (armor + darmor), 4, true);
					}
				}
			}
		}

		if (!hsOnly_AllowTaser)
		{
			if (StrEqual(weapon, "taser", false))
			{
				if (attacker != victim && victim != 0)
				{
					if (dhealth > 0)
					{
						SetEntData(victim, g_iHealth, (health + dhealth), 4, true);
					}
					if (darmor > 0)
					{
						SetEntData(victim, g_Armor, (armor + darmor), 4, true);
					}
				}
			}
		}

		if (!hsOnly_AllowKnife)
		{
			if (StrEqual(weapon, "knife", false))
			{
				if (attacker != victim && victim != 0)
				{
					if (dhealth > 0)
					{
						SetEntData(victim, g_iHealth, (health + dhealth), 4, true);
					}
					if (darmor > 0)
					{
						SetEntData(victim, g_Armor, (armor + darmor), 4, true);
					}
				}
			}
		}

		if (!hsOnly_AllowWorld)
		{
			if (victim !=0 && attacker == 0)
			{
				if (dhealth > 0)
				{
					SetEntData(victim, g_iHealth, (health + dhealth), 4, true);
				}
				if (darmor > 0)
				{
					SetEntData(victim, g_Armor, (armor + darmor), 4, true);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_HegrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (replenishGrenade && !replenishHEGrenade)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_hegrenade");
		}
	}

	else if (replenishHEGrenade && !replenishGrenade)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_hegrenade");
		}
	}

	else if (replenishGrenade && replenishHEGrenade)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_hegrenade");
		}
	}

	return Plugin_Continue;
}

public Action:Event_SmokegrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!replenishGrenade)
	{
		return Plugin_Continue;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (replenishGrenade)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_smokegrenade");
		}
	}

	return Plugin_Continue;
}

public Action:Event_FlashbangDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!replenishGrenade)
	{
		return Plugin_Continue;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (replenishGrenade)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_flashbang");
		}
	}

	return Plugin_Continue;
}

public Action:Event_DecoyStarted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!replenishGrenade)
	{
		return Plugin_Continue;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (replenishGrenade)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_decoy");
		}
	}

	return Plugin_Continue;
}

public Action:Event_MolotovDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!replenishGrenade)
	{
		return Plugin_Continue;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (replenishGrenade)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_molotov");
		}
	}

	return Plugin_Continue;
}

public Action:Event_InfernoStartburn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!replenishGrenade)
	{
		return Plugin_Continue;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (replenishGrenade)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_incgrenade");
		}
	}

	return Plugin_Continue;
}

public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (hsOnly)
	{
		decl String:weapon[32];
		decl String:grenade[32];
		GetEdictClassname(inflictor, grenade, sizeof(grenade));
		GetClientWeapon(attacker, weapon, sizeof(weapon));

		if (hitgroup == 1)
		{
			return Plugin_Continue;
		}
		else if (hsOnly_AllowKnife && StrEqual(weapon, "weapon_knife"))
		{
			return Plugin_Continue;
		}
		else if (hsOnly_AllowNade && StrEqual(grenade, "hegrenade_projectile"))
		{
			return Plugin_Continue;
		}
		else if (hsOnly_AllowTaser && StrEqual(weapon, "weapon_taser"))
		{
			return Plugin_Continue;
		}
		else
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (hsOnly)
	{
		if (IsClientValid(victim))
		{
			if (damagetype & DMG_FALL || attacker == 0)
			{
				if (hsOnly_AllowWorld)
				{
					return Plugin_Continue;
				}
				else
				{
					return Plugin_Handled;
				}
			}

			if (IsClientValid(attacker))
			{
				GetEdictClassname(inflictor, g_sGrenade, sizeof(g_sGrenade));
				GetClientWeapon(attacker, g_sWeapon, sizeof(g_sWeapon));

				if (damagetype & DMG_HEADSHOT)
				{

					return Plugin_Continue;
				}
				else
				{
					if (hsOnly_AllowKnife)
					{
						if (StrEqual(g_sWeapon, "weapon_knife"))
						{
							return Plugin_Continue;
						}
					}

					if (hsOnly_AllowNade)
					{
						if (StrEqual(g_sGrenade, "hegrenade_projectile") || StrEqual(g_sGrenade, "decoy_projectile") || StrEqual(g_sGrenade, "molotov_projectile"))
						{
							return Plugin_Continue;
						}
					}
					return Plugin_Handled;
				}
			}
			else
			{
				return Plugin_Handled;
			}
		}
		else
		{
			return Plugin_Handled;
		}
	}
	else
	{
		return Plugin_Continue;
	}
}

public Action:PanelDisplay(Handle:timer, any:client)
{
	new i = GetClientOfUserId(client);
	if (i && IsClientValid(i) && IsPlayerAlive(i))
	{
		new aim = GetClientAimTarget(i, true);
		if (0 < aim)
		{
			PrintHintText(i, "%t %i", GetClientHealth(aim), "Panel Health Remaining");
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

public Action:RemoveRadar(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Send, "m_iHideHUD", HIDEHUD_RADAR);
	}
}

public Action:GiveAmmo(Handle:timer, any:client)
{
	if (enabled && (replenishAmmo || replenishClip))
	{
		if (IsPlayerAlive(client) && IsClientValid(client) && !IsFakeClient(client))
		{
			RefillWeapons(INVALID_HANDLE, client);
			CreateTimer(0.3, RefillWeapons, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public Action:RefillWeapons(Handle:timer, any:client)
{
	decl weaponEntity;

	if(client != -1 && IsClientValid(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		if (replenishAmmo && replenishClip)
		{
			weaponEntity = GetPlayerWeaponSlot(client, _:SlotPrimary);
			if (weaponEntity != -1)
				DoFullRefillAmmo(EntIndexToEntRef(weaponEntity), client);

			weaponEntity = GetPlayerWeaponSlot(client, _:SlotSecondary);
			if (weaponEntity != -1)
				DoFullRefillAmmo(EntIndexToEntRef(weaponEntity), client);
		}
		else if (replenishAmmo)
		{
			weaponEntity = GetPlayerWeaponSlot(client, _:SlotPrimary);
			if (weaponEntity != -1)
				DoResRefillAmmo(EntIndexToEntRef(weaponEntity), client);

			weaponEntity = GetPlayerWeaponSlot(client, _:SlotSecondary);
			if (weaponEntity != -1)
				DoResRefillAmmo(EntIndexToEntRef(weaponEntity), client);
		}
		else if (replenishClip)
		{
			weaponEntity = GetPlayerWeaponSlot(client, _:SlotPrimary);
			if (weaponEntity != -1)
				DoClipRefillAmmo(EntIndexToEntRef(weaponEntity), client);

			weaponEntity = GetPlayerWeaponSlot(client, _:SlotSecondary);
			if (weaponEntity != -1)
				DoClipRefillAmmo(EntIndexToEntRef(weaponEntity), client);
		}
	}
}

DoClipRefillAmmo(weaponRef, any:client)
{
	new weaponEntity = EntRefToEntIndex(weaponRef);

	if (IsValidEdict(weaponEntity))
	{
		decl String:weaponName[35];
		GetEntityClassname(weaponEntity, weaponName, sizeof(weaponName));

		decl String:clipSize;
		decl String:maxAmmoCount;
		new ammoType = GetEntData(weaponEntity, ammoTypeOffset);

		// TODO: Not sure how to avoid this hack considering the game thinks the
		// cz is a weapon_p250 and both the m4a4 and m4a1 are weapon_m4a1.
		if (ammoType == 4 && StrEqual(weaponName, "weapon_m4a1"))
		{
			clipSize = 20;
		}
		else
		{
			clipSize = GetWeaponAmmoCount(weaponName, true);
			maxAmmoCount = GetWeaponAmmoCount(weaponName, false);
		}

		SetEntData(client, ammoOffset, maxAmmoCount, true);
		SetEntData(weaponEntity, g_iWeapons_Clip1Offset, clipSize, 4, true);
	}
}

DoResRefillAmmo(weaponRef, any:client)
{
	new weaponEntity = EntRefToEntIndex(weaponRef);

	if (IsValidEdict(weaponEntity))
	{
		decl String:weaponName[35];
		GetEntityClassname(weaponEntity, weaponName, sizeof(weaponName));

		decl String:maxAmmoCount;
		new ammoType = GetEntData(weaponEntity, ammoTypeOffset);

		// TODO: Not sure how to avoid this hack considering the game thinks the
		// cz is a weapon_p250 and both the m4a4 and m4a1 are weapon_m4a1.
		if (ammoType == 4 && StrEqual(weaponName, "weapon_m4a1"))
		{
			maxAmmoCount = 40;
		}
		else
		{
			maxAmmoCount = GetWeaponAmmoCount(weaponName, false);
		}

		SetEntData(client, ammoOffset + (ammoType * 4), maxAmmoCount, true);
	}
}

DoFullRefillAmmo(weaponRef, any:client)
{
	new weaponEntity = EntRefToEntIndex(weaponRef);

	if (IsValidEdict(weaponEntity))
	{
		decl String:weaponName[35];
		GetEntityClassname(weaponEntity, weaponName, sizeof(weaponName));

		decl String:clipSize;
		decl String:maxAmmoCount;
		new ammoType = GetEntData(weaponEntity, ammoTypeOffset);

		// TODO: Not sure how to avoid this hack considering the game thinks the
		// The m4a4 and m4a1 are weapon_m4a1.
		if (ammoType == 4 && StrEqual(weaponName, "weapon_m4a1"))
		{
			clipSize = 20;
			maxAmmoCount = 40;
		}
		else
		{
			clipSize = GetWeaponAmmoCount(weaponName, true);
			maxAmmoCount = GetWeaponAmmoCount(weaponName, false);
		}

		SetEntData(client, ammoOffset + (ammoType * 4), maxAmmoCount, true);
		SetEntData(weaponEntity, g_iWeapons_Clip1Offset, clipSize, 4, true);
	}
}

stock GetWeaponAmmoCount(String:weaponName[], bool:currentClip)
{
	// TODO: Data-drive this through deathmatch.ini.
	if (StrEqual(weaponName,  "weapon_ak47"))
		return currentClip ? 30 : 90;
	else if (StrEqual(weaponName,  "weapon_m4a1"))
		return currentClip ? 30 : 90;
	else if (StrEqual(weaponName,  "weapon_m4a1_silencer"))
		return currentClip ? 20 : 40;
	else if (StrEqual(weaponName,  "weapon_awp"))
		return currentClip ? 10 : 30;
	else if (StrEqual(weaponName,  "weapon_sg552"))
		return currentClip ? 30 : 90;
	else if (StrEqual(weaponName,  "weapon_aug"))
		return currentClip ? 30 : 90;
	else if (StrEqual(weaponName,  "weapon_p90"))
		return currentClip ? 50 : 100;
	else if (StrEqual(weaponName,  "weapon_galilar"))
		return currentClip ? 35 : 90;
	else if (StrEqual(weaponName,  "weapon_famas"))
		return currentClip ? 25 : 90;
	else if (StrEqual(weaponName,  "weapon_ssg08"))
		return currentClip ? 10 : 90;
	else if (StrEqual(weaponName,  "weapon_g3sg1"))
		return currentClip ? 20 : 90;
	else if (StrEqual(weaponName,  "weapon_scar20"))
		return currentClip ? 20 : 90;
	else if (StrEqual(weaponName,  "weapon_m249"))
		return currentClip ? 100 : 200;
	else if (StrEqual(weaponName,  "weapon_negev"))
		return currentClip ? 150 : 200;
	else if (StrEqual(weaponName,  "weapon_nova"))
		return currentClip ? 8 : 32;
	else if (StrEqual(weaponName,  "weapon_xm1014"))
		return currentClip ? 7 : 32;
	else if (StrEqual(weaponName,  "weapon_sawedoff"))
		return currentClip ? 7 : 32;
	else if (StrEqual(weaponName,  "weapon_mag7"))
		return currentClip ? 5 : 32;
	else if (StrEqual(weaponName,  "weapon_mac10"))
		return currentClip ? 30 : 100;
	else if (StrEqual(weaponName,  "weapon_mp9"))
		return currentClip ? 30 : 120;
	else if (StrEqual(weaponName,  "weapon_mp7"))
		return currentClip ? 30 : 120;
	else if (StrEqual(weaponName,  "weapon_ump45"))
		return currentClip ? 25 : 100;
	else if (StrEqual(weaponName,  "weapon_bizon"))
		return currentClip ? 64 : 120;
	else if (StrEqual(weaponName,  "weapon_glock"))
		return currentClip ? 20 : 120;
	else if (StrEqual(weaponName,  "weapon_fiveseven"))
		return currentClip ? 20 : 100;
	else if (StrEqual(weaponName,  "weapon_deagle"))
		return currentClip ? 7 : 35;
	else if (StrEqual(weaponName,  "weapon_hkp2000"))
		return currentClip ? 13 : 52;
	else if (StrEqual(weaponName,  "weapon_usp_silencer"))
		return currentClip ? 12 : 24;
	else if (StrEqual(weaponName,  "weapon_p250"))
		return currentClip ? 13 : 26;
	else if (StrEqual(weaponName,  "weapon_elite"))
		return currentClip ? 30 : 120;
	else if (StrEqual(weaponName,  "weapon_tec9"))
		return currentClip ? 24 : 120;
	else if (StrEqual(weaponName,  "weapon_cz75a"))
		return currentClip ? 12 : 12;
	return currentClip ? 30 : 90;
}

public Event_BombPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (enabled && removeObjectives)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		StripC4(client);
	}
}

public Action:Respawn(Handle:timer, any:client)
{
	if (!roundEnded && IsClientInGame(client) && (Teams:GetClientTeam(client) > TeamSpectator) && !IsPlayerAlive(client))
	{
		// We set this here rather than in Event_PlayerSpawn to catch the spawn sounds which occur before Event_PlayerSpawn is called (even with EventHookMode_Pre).
		playerMoved[client] = false;
		CS_RespawnPlayer(client);
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
			if (gunMenuMode == 1)
			{
				BuildDisplayWeaponMenu(param1, true);
			}
			else if (gunMenuMode == 2)
			{
				BuildDisplayWeaponMenu(param1, false);
			}
			rememberChoice[param1] = false;
		}
		else if (StrEqual(info, "Same 1"))
		{
			if (weaponsGivenThisRound[param1])
			{
				newWeaponsSelected[param1] = true;
				CPrintToChat(param1, "[\x04DM\x01] %t", "Guns Same Spawn");
			}
			if (gunMenuMode == 1 || gunMenuMode == 3)
			{
				GiveSavedWeapons(param1, true, true);
			}
			else if (gunMenuMode == 2)
			{
				GiveSavedWeapons(param1, false, true);
			}
			rememberChoice[param1] = false;
		}
		else if (StrEqual(info, "Same All"))
		{
			if (weaponsGivenThisRound[param1])
			{
				CPrintToChat(param1, "[\x04DM\x01] %t", "Guns Same Spawn");
			}
			if (gunMenuMode == 1 || gunMenuMode == 3)
			{
				GiveSavedWeapons(param1, true, true);
			}
			else if (gunMenuMode == 2)
			{
				GiveSavedWeapons(param1, false, true);
			}
			rememberChoice[param1] = true;
		}
		else if (StrEqual(info, "Random 1"))
		{
			if (weaponsGivenThisRound[param1])
			{
				newWeaponsSelected[param1] = true;
				CPrintToChat(param1, "[\x04DM\x01] %t", "Guns Random Spawn");
			}
			if (gunMenuMode == 1 || gunMenuMode == 3)
			{
				primaryWeapon[param1] = "random";
				secondaryWeapon[param1] = "random";
				GiveSavedWeapons(param1, true, true);
			}
			else if (gunMenuMode == 2)
			{
				primaryWeapon[param1] = "none";
				secondaryWeapon[param1] = "random";
				GiveSavedWeapons(param1, false, true);
			}
			rememberChoice[param1] = false;
		}
		else if (StrEqual(info, "Random All"))
		{
			if (weaponsGivenThisRound[param1])
			{
				CPrintToChat(param1, "[\x04DM\x01] %t", "Guns Random Spawn");
			}
			if (gunMenuMode == 1 || gunMenuMode == 3)
			{
				primaryWeapon[param1] = "random";
				secondaryWeapon[param1] = "random";
			}
			else if (gunMenuMode == 2)
			{
				primaryWeapon[param1] = "none";
				secondaryWeapon[param1] = "random";
			}
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
			CPrintToChat(param1, "[\x04DM\x01] %t", "Guns New Spawn");
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
					CPrintToChat(param1, "[\x04DM\x01] %t", "Guns Random Spawn");
				firstWeaponSelection[param1] = false;
			}
		}
	}
}

public Action:Command_Guns(client, args)
{
	if (enabled && gunMenuMode != 3 && gunMenuMode != 4)
		DisplayOptionsMenu(client);
}

GiveSavedWeapons(client, bool:primary, bool:secondary)
{
	if (!weaponsGivenThisRound[client] && IsPlayerAlive(client))
	{
		if (primary && !StrEqual(primaryWeapon[client], "none"))
		{
			if (StrEqual(primaryWeapon[client], "random"))
			{
				// Select random menu item (excluding "Random" option)
				new random = GetRandomInt(0, GetArraySize(primaryWeaponsAvailable) - 1);
				decl String:randomWeapon[24];
				GetArrayString(primaryWeaponsAvailable, random, randomWeapon, sizeof(randomWeapon));
				GivePlayerItem(client, randomWeapon);
			}
			else
			{
				GivePlayerItem(client, primaryWeapon[client]);
			}
		}
		if (secondary)
		{
			if (!StrEqual(secondaryWeapon[client], "none"))
			{
				if (StrEqual(secondaryWeapon[client], "random"))
				{
					// Select random menu item (excluding "Random" option)
					new random = GetRandomInt(0, GetArraySize(secondaryWeaponsAvailable) - 1);
					decl String:randomWeapon[24];
					GetArrayString(secondaryWeaponsAvailable, random, randomWeapon, sizeof(randomWeapon));
					GivePlayerItem(client, randomWeapon);
				}
				else
				{
					GivePlayerItem(client, secondaryWeapon[client]);
				}
			}
			if (zeus)
				GivePlayerItem(client, "weapon_taser");
			if (incendiary > 0)
			{
				new Teams:clientTeam = Teams:GetClientTeam(client);
				for (new i = 0; i < incendiary; i++)
				{
					if (clientTeam == TeamT)
						GivePlayerItem(client, "weapon_molotov");
					else
						GivePlayerItem(client, "weapon_incgrenade");
				}
			}
			for (new i = 0; i < decoy; i++)
				GivePlayerItem(client, "weapon_decoy");
			for (new i = 0; i < flashbang; i++)
				GivePlayerItem(client, "weapon_flashbang");
			for (new i = 0; i < he; i++)
				GivePlayerItem(client, "weapon_hegrenade");
			for (new i = 0; i < smoke; i++)
				GivePlayerItem(client, "weapon_smokegrenade");
			weaponsGivenThisRound[client] = true;
		}
	}
}

RemoveClientWeapons(client)
{
	if (IsClientValid(client) && IsPlayerAlive(client))
	{
		FakeClientCommand(client, "use weapon_knife");
		for (new i = 0; i < 4; i++)
		{
			if (i == 2) continue; // Keep knife.
			new entityIndex;
			while ((entityIndex = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, entityIndex);
				AcceptEntityInput(entityIndex, "Kill");
			}
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

bool:StripC4(client)
{
	if (IsClientInGame(client) && (Teams:GetClientTeam(client) == TeamT) && IsPlayerAlive(client))
	{
		new c4Index = GetPlayerWeaponSlot(client, _:SlotC4);
		if (c4Index != -1)
		{
			decl String:weapon[24];
			GetClientWeapon(client, weapon, sizeof(weapon));
			// If the player is holding C4, switch to the best weapon before removing it.
			if (StrEqual(weapon, "weapon_c4"))
			{
				if (GetPlayerWeaponSlot(client, _:SlotPrimary) != -1)
					ClientCommand(client, "slot1");
				else if (GetPlayerWeaponSlot(client, _:SlotSecondary) != -1)
					ClientCommand(client, "slot2");
				else
					ClientCommand(client, "slot3");

			}
			RemovePlayerItem(client, c4Index);
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

EnableSpawnProtection(client)
{
	new Teams:clientTeam = Teams:GetClientTeam(client);
	// Disable damage
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	// Set player color
	if (clientTeam == TeamT)
		SetPlayerColor(client, tColor);
	else if (clientTeam == TeamCT)
		SetPlayerColor(client, ctColor);
	// Create timer to remove spawn protection
	CreateTimer(spawnProtectionTime, DisableSpawnProtection, client);
}

public Action:DisableSpawnProtection(Handle:Timer, any:client)
{
	if (IsClientInGame(client) && (Teams:GetClientTeam(client) > TeamSpectator) && IsPlayerAlive(client))
	{
		// Enable damage
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		// Set player color
		SetPlayerColor(client, defaultColor);
	}
}

SetPlayerColor(client, const color[4])
{
	new RenderMode:mode = (color[3] == 255) ? RENDER_NORMAL : RENDER_TRANSCOLOR;
	SetEntityRenderMode(client, mode);
	SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
}

public Action:Command_RespawnAll(client, args)
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

public Action:Command_SpawnMenu(client, args)
{
	DisplayMenu(BuildSpawnEditorMenu(), client, MENU_TIME_FOREVER);
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
				CPrintToChat(param1, "[\x04DM\x01] %t", "Spawn Editor Enabled");
			}
			else
				CPrintToChat(param1, "[\x04DM\x01] %t", "Spawn Editor Disabled");
		}
		else if (StrEqual(info, "Nearest"))
		{
			new spawnPoint = GetNearestSpawn(param1);
			if (spawnPoint != -1)
			{
				TeleportEntity(param1, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
				lastEditorSpawnPoint[param1] = spawnPoint;
				CPrintToChat(param1, "[\x04DM\x01] %t #%i (%i total).", "Spawn Editor Teleported", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Previous"))
		{
			if (spawnPointCount == 0)
				CPrintToChat(param1, "[\x04DM\x01] %t", "Spawn Editor No Spawn");
			else
			{
				new spawnPoint = lastEditorSpawnPoint[param1] - 1;
				if (spawnPoint < 0)
					spawnPoint = spawnPointCount - 1;
				TeleportEntity(param1, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
				lastEditorSpawnPoint[param1] = spawnPoint;
				CPrintToChat(param1, "[\x04DM\x01] %t #%i (%i total).", "Spawn Editor Teleported", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Next"))
		{
			if (spawnPointCount == 0)
				CPrintToChat(param1, "[\x04DM\x01] %t", "Spawn Editor No Spawn");
			else
			{
				new spawnPoint = lastEditorSpawnPoint[param1] + 1;
				if (spawnPoint >= spawnPointCount)
					spawnPoint = 0;
				TeleportEntity(param1, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
				lastEditorSpawnPoint[param1] = spawnPoint;
				CPrintToChat(param1, "[\x04DM\x01] %t #%i (%i total).", "Spawn Editor Teleported", spawnPoint + 1, spawnPointCount);
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
				CPrintToChat(param1, "[\x04DM\x01] %t #%i (%i total).", "Spawn Editor Deleted Spawn", spawnPoint + 1, spawnPointCount);
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
				CPrintToChat(param1, "[\x04DM\x01] %t", "Spawn Editor Config Saved");
			else
				CPrintToChat(param1, "[\x04DM\x01] %t", "Spawn Editor Config Not Saved");
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
			CPrintToChat(param1, "[\x04DM\x01] %t", "Spawn Editor Deleted All");
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

GetNearestSpawn(client)
{
	if (spawnPointCount == 0)
	{
		CPrintToChat(client, "[\x04DM\x01] %t", "Spawn Editor No Spawn");
		return -1;
	}

	decl Float:clientPosition[3];
	GetClientAbsOrigin(client, clientPosition);

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

AddSpawn(client)
{
	if (spawnPointCount >= MAX_SPAWNS)
	{
		CPrintToChat(client, "[\x04DM\x01] %t", "Spawn Editor Spawn Not Added");
		return;
	}
	GetClientAbsOrigin(client, spawnPositions[spawnPointCount]);
	GetClientAbsAngles(client, spawnAngles[spawnPointCount]);
	spawnPointCount++;
	CPrintToChat(client, "[\x04DM\x01] %t", "Spawn Editor Spawn Added", spawnPointCount, spawnPointCount);
}

InsertSpawn(client)
{
	if (spawnPointCount >= MAX_SPAWNS)
	{
		CPrintToChat(client, "[\x04DM\x01] %t", "Spawn Editor Spawn Not Added");
		return;
	}

	if (spawnPointCount == 0)
		AddSpawn(client);
	else
	{
		// Move spawn points down the list to make room for insertion.
		for (new i = spawnPointCount - 1; i >= lastEditorSpawnPoint[client]; i--)
		{
			spawnPositions[i + 1] = spawnPositions[i];
			spawnAngles[i + 1] = spawnAngles[i];
		}
		// Insert new spawn point.
		GetClientAbsOrigin(client, spawnPositions[lastEditorSpawnPoint[client]]);
		GetClientAbsAngles(client, spawnAngles[lastEditorSpawnPoint[client]]);
		spawnPointCount++;
		CPrintToChat(client, "[\x04DM\x01] %t #%i (%i total).", "Spawn Editor Spawn Inserted", lastEditorSpawnPoint[client] + 1, spawnPointCount);
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

MovePlayer(client)
{
	numberOfPlayerSpawns++; // Stats

	new Teams:clientTeam = Teams:GetClientTeam(client);

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
		TeleportEntity(client, spawnPositions[spawnPoint], spawnAngles[spawnPoint], NULL_VECTOR);
		spawnPointOccupied[spawnPoint] = true;
		playerMoved[client] = true;
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

public Action:Command_Stats(client, args)
{
	DisplaySpawnStats(client);
}

public Action:Command_ResetStats(client, args)
{
	ResetSpawnStats();
	CPrintToChat(client, "[\x04DM\x01] Spawn statistics have been reset.");
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

DisplaySpawnStats(client)
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
	SendPanelToClient(panel, client, Panel_SpawnStats, MENU_TIME_FOREVER);
	CloseHandle(panel);
}

public Panel_SpawnStats(Handle:menu, MenuAction:action, param1, param2) { }

public Action:Event_Sound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (enabled)
	{
		if (spawnPointCount > 0)
		{
			new client;
			if ((entity > 0) && (entity <= MaxClients))
				client = entity;
			else
				client = GetEntDataEnt2(entity, ownerOffset);

			// Block ammo pickup sounds.
			if (StrEqual(sample, "items/ammopickup.wav"))
				return Plugin_Stop;

			// Block all sounds originating from players not yet moved.
			if ((client > 0) && (client <= MaxClients) && !playerMoved[client])
				return Plugin_Stop;
		}
		if (ffa)
		{
			if (StrContains(sample, "friendlyfire") != -1)
				return Plugin_Stop;
		}
		if (hsOnly)
		{
			if (StrEqual(sample, "physics/flesh/flesh_squishy_impact_hard1.wav"))
			if (StrEqual(sample, "physics/flesh/flesh_squishy_impact_hard2.wav"))
			if (StrEqual(sample, "physics/flesh/flesh_squishy_impact_hard3.wav"))
			if (StrEqual(sample, "physics/flesh/flesh_squishy_impact_hard4.wav"))
			if (StrEqual(sample, "physics/flesh/flesh_bloody_break.wav"))
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

BuildDisplayWeaponMenu(client, bool:primary)
{
	if (primary)
	{
		if (primaryMenus[client] != INVALID_HANDLE)
		{
			CancelMenu(primaryMenus[client]);
			CloseHandle(primaryMenus[client]);
			primaryMenus[client] = INVALID_HANDLE;
		}
	}
	else
	{
		if (secondaryMenus[client] != INVALID_HANDLE)
		{
			CancelMenu(secondaryMenus[client]);
			CloseHandle(secondaryMenus[client]);
			secondaryMenus[client] = INVALID_HANDLE;
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
	currentWeapon = (primary) ? primaryWeapon[client] : secondaryWeapon[client];

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
		primaryMenus[client] = menu;
		DisplayMenu(primaryMenus[client], client, MENU_TIME_FOREVER);
	}
	else
	{
		secondaryMenus[client] = menu;
		DisplayMenu(secondaryMenus[client], client, MENU_TIME_FOREVER);
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
		if (GetUserMessageType() == UM_Protobuf)
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
		if (GetUserMessageType() == UM_Protobuf)
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
		if (GetUserMessageType() == UM_Protobuf)
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

RemoveRagdoll(client)
{
	if (IsValidEdict(client))
	{
		new ragdoll = GetEntDataEnt2(client, ragdollOffset);
		if (ragdoll != -1)
			AcceptEntityInput(ragdoll, "Kill");
	}
}