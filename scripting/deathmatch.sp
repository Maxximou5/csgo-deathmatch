#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <csgocolors>
#include <cstrike>
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required

#define PLUGIN_VERSION          "2.0.7a"
#define PLUGIN_NAME             "[CS:GO] Deathmatch"
#define PLUGIN_AUTHOR           "Maxximou5"
#define PLUGIN_DESCRIPTION      "Enables deathmatch style gameplay (respawning, gun selection, spawn protection, etc)."
#define PLUGIN_URL              "https://github.com/Maxximou5/csgo-deathmatch/"
#define UPDATE_URL              "http://www.maxximou5.com/sourcemod/deathmatch/update.txt"

public Plugin myinfo =
{
    name                        = PLUGIN_NAME,
    author                      = PLUGIN_AUTHOR,
    description                 = PLUGIN_DESCRIPTION,
    version                     = PLUGIN_VERSION,
    url                         = PLUGIN_URL
}

/* Defined Variables */
#define MAX_SPAWNS 200
#define HIDEHUD_RADAR 1 << 12
#define DMG_HEADSHOT (1 << 30)

/* Native Console Variables */
Handle mp_ct_default_primary;
Handle mp_t_default_primary;
Handle mp_ct_default_secondary;
Handle mp_t_default_secondary;
Handle mp_startmoney;
Handle mp_playercashawards;
Handle mp_teamcashawards;
Handle mp_friendlyfire;
Handle mp_autokick;
Handle mp_tkpunish;
Handle mp_teammates_are_enemies;
Handle ff_damage_reduction_bullets;
Handle ff_damage_reduction_grenade;
Handle ff_damage_reduction_other;
Handle ammo_grenade_limit_default;
Handle ammo_grenade_limit_flashbang;
Handle ammo_grenade_limit_total;

/* Native Backup Variables */
int backup_mp_startmoney;
int backup_mp_playercashawards;
int backup_mp_teamcashawards;
int backup_mp_friendlyfire;
int backup_mp_autokick;
int backup_mp_tkpunish;
int backup_mp_teammates_are_enemies;
int backup_ammo_grenade_limit_default;
int backup_ammo_grenade_limit_flashbang;
int backup_ammo_grenade_limit_total;
float backup_ff_damage_reduction_bullets;
float backup_ff_damage_reduction_grenade;
float backup_ff_damage_reduction_other;

/* Console variables */
ConVar cvar_dm_enabled;
ConVar cvar_dm_valvedm;
ConVar cvar_dm_welcomemsg;
ConVar cvar_dm_free_for_all;
ConVar cvar_dm_hide_radar;
ConVar cvar_dm_display_panel;
ConVar cvar_dm_display_panel_damage;
ConVar cvar_dm_sounds_bodyshots;
ConVar cvar_dm_sounds_headshots;
ConVar cvar_dm_headshot_only;
ConVar cvar_dm_headshot_only_allow_world;
ConVar cvar_dm_headshot_only_allow_knife;
ConVar cvar_dm_headshot_only_allow_taser;
ConVar cvar_dm_headshot_only_allow_nade;
ConVar cvar_dm_remove_objectives;
ConVar cvar_dm_respawning;
ConVar cvar_dm_respawn_time;
ConVar cvar_dm_gun_menu_mode;
ConVar cvar_dm_los_spawning;
ConVar cvar_dm_los_attempts;
ConVar cvar_dm_spawn_distance;
ConVar cvar_dm_spawn_time;
ConVar cvar_dm_no_knife_damage;
ConVar cvar_dm_remove_weapons;
ConVar cvar_dm_replenish_ammo;
ConVar cvar_dm_replenish_clip;
ConVar cvar_dm_replenish_reserve;
ConVar cvar_dm_replenish_grenade;
ConVar cvar_dm_replenish_hegrenade;
ConVar cvar_dm_replenish_grenade_kill;
ConVar cvar_dm_hp_start;
ConVar cvar_dm_hp_max;
ConVar cvar_dm_hp_kill;
ConVar cvar_dm_hp_hs;
ConVar cvar_dm_hp_knife;
ConVar cvar_dm_hp_nade;
ConVar cvar_dm_hp_messages;
ConVar cvar_dm_ap_max;
ConVar cvar_dm_ap_kill;
ConVar cvar_dm_ap_hs;
ConVar cvar_dm_ap_knife;
ConVar cvar_dm_ap_nade;
ConVar cvar_dm_ap_messages;
ConVar cvar_dm_nade_messages;
ConVar cvar_dm_armor;
ConVar cvar_dm_armor_full;
ConVar cvar_dm_zeus;
ConVar cvar_dm_nades_incendiary;
ConVar cvar_dm_nades_molotov;
ConVar cvar_dm_nades_decoy;
ConVar cvar_dm_nades_flashbang;
ConVar cvar_dm_nades_he;
ConVar cvar_dm_nades_smoke;

/* Plugin Variables */
bool enabled = false;
bool valveDM;
bool welcomemsg;
bool ffa;
bool hideradar;
bool displayPanel;
bool displayPanelDamage;
bool bdSounds;
bool hsSounds;
bool hsOnly;
bool hsOnly_AllowWorld;
bool hsOnly_AllowKnife;
bool hsOnly_AllowTaser;
bool hsOnly_AllowNade;
bool removeObjectives;

/* Weapon Variables */
bool noKnifeDamage;
bool removeWeapons;
bool replenishAmmo;
bool replenishClip;
bool replenishReserve;
bool replenishGrenade;
bool replenishHEGrenade;
bool replenishGrenadeKill;
bool displayHPMessages;
bool displayAPMessages;
bool displayGrenadeMessages;
bool roundEnded = false;
int gunMenuMode;

/* Health Variables */
int startHP;
int maxHP;
int HPPerKill;
int HPPerHeadshotKill;
int HPPerKnifeKill;
int HPPerNadeKill;

/* Armor Variables */
int maxAP;
int APPerKill;
int APPerHeadshotKill;
int APPerKnifeKill;
int APPerNadeKill;

/* Player Color Variables */
int defaultColor[4] = { 255, 255, 255, 255 };
int tColor[4] = { 255, 0, 0, 200 };
int ctColor[4] = { 0, 0, 255, 200 };

/* Respawn Variables */
float spawnDistanceFromEnemies;
float spawnProtectionTime;
float respawnTime;
bool respawning;
bool lineOfSightSpawning;
int lineOfSightAttempts;
int spawnPointCount = 0;
bool inEditMode = false;
bool spawnPointOccupied[MAX_SPAWNS] = {false, ...};
float spawnPositions[MAX_SPAWNS][3];
float spawnAngles[MAX_SPAWNS][3];
float eyeOffset[3] = { 0.0, 0.0, 64.0 }; /* CSGO offset. */
float spawnPointOffset[3] = { 0.0, 0.0, 20.0 };

/* Offsets */
int ownerOffset;
int healthOffset;
int armorOffset;
int helmetOffset;
int ammoTypeOffset;
int ammoOffset;
int ragdollOffset;

/* Weapon Info */
Handle primaryWeaponsAvailable;
Handle secondaryWeaponsAvailable;
Handle weaponMenuNames;
Handle weaponLimits;
Handle weaponCounts;
StringMap weaponSkipMap;

/* Grenade/Misc Options */
bool armorChest;
bool armorFull;
bool zeus;
int molotov;
int incendiary;
int decoy;
int flashbang;
int he;
int smoke;

/* Menus */
Handle optionsMenu1 = INVALID_HANDLE;
Handle optionsMenu2 = INVALID_HANDLE;
Handle primaryMenus[MAXPLAYERS + 1];
Handle secondaryMenus[MAXPLAYERS + 1];
Handle damageDisplay[MAXPLAYERS+1];

/* Player settings */
int lastEditorSpawnPoint[MAXPLAYERS + 1] = { -1, ... };
char primaryWeapon[MAXPLAYERS + 1][24];
char secondaryWeapon[MAXPLAYERS + 1][24];
int infoMessageCount[MAXPLAYERS + 1] = { 2, ... };
bool firstWeaponSelection[MAXPLAYERS + 1] = { true, ... };
bool weaponsGivenThisRound[MAXPLAYERS + 1] = { false, ... };
bool newWeaponsSelected[MAXPLAYERS + 1] = { false, ... };
bool rememberChoice[MAXPLAYERS + 1] = { false, ... };
bool playerMoved[MAXPLAYERS + 1] = { false, ... };

/* Player Glow Sprite */
int glowSprite;

/* Spawn stats */
int numberOfPlayerSpawns = 0;
int losSearchAttempts = 0;
int losSearchSuccesses = 0;
int losSearchFailures = 0;
int distanceSearchAttempts = 0;
int distanceSearchSuccesses = 0;
int distanceSearchFailures = 0;
int spawnPointSearchFailures = 0;

/* Static Offsets */
static int g_iWeapons_Clip1Offset;

public void OnPluginStart()
{
	/* Let's not waste our time here... */
	if(GetEngineVersion() != Engine_CSGO)
    {
        SetFailState("ERROR: This plugin is designed only for CS:GO.");
    }

	/* Load translations for multi-language */
	LoadTranslations("deathmatch.phrases");
	LoadTranslations("common.phrases");

	/* Create spawns directory if necessary. */
	char spawnsPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, spawnsPath, sizeof(spawnsPath), "configs/deathmatch/spawns");
	if (!DirExists(spawnsPath))
		CreateDirectory(spawnsPath, 711);

	/* Find Offsets */
	ownerOffset = FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity");
	healthOffset = FindSendPropInfo("CCSPlayerResource", "m_iHealth");
	armorOffset = FindSendPropInfo("CCSPlayer", "m_ArmorValue");
	helmetOffset = FindSendPropInfo("CCSPlayer", "m_bHasHelmet");
	ammoTypeOffset = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");
	ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	ragdollOffset = FindSendPropInfo("CCSPlayer", "m_hRagdoll");

	/* Create arrays to store available weapons loaded by config */
	primaryWeaponsAvailable = CreateArray(24);
	secondaryWeaponsAvailable = CreateArray(10);
	weaponSkipMap = new StringMap();

	/* Create trie to store menu names for weapons */
	BuildWeaponMenuNames();

	/* Create trie to store weapon limits and counts */
	weaponLimits = CreateTrie();
	weaponCounts = CreateTrie();

	/* Create Menus */
	optionsMenu1 = BuildOptionsMenu(true);
	optionsMenu2 = BuildOptionsMenu(false);

	/* Create Console Variables */
	CreateConVar("dm_m5_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvar_dm_enabled = CreateConVar("dm_enabled", "1", "Enable Deathmatch.");
	cvar_dm_valvedm = CreateConVar("dm_enable_valve_deathmatch", "0", "Enable compatibility for Valve's Deathmatch (game_type 1 & game_mode 2) or Custom (game_type 3 & game_mode 0).");
	cvar_dm_welcomemsg = CreateConVar("dm_welcomemsg", "1", "Display a message saying that your server is running Deathmatch.");
	cvar_dm_free_for_all = CreateConVar("dm_free_for_all", "0", "Free for all mode.");
	cvar_dm_hide_radar = CreateConVar("dm_hide_radar", "0", "Hides the radar from players.");
	cvar_dm_display_panel = CreateConVar("dm_display_panel", "0", "Display a panel showing health of the victim.");
	cvar_dm_display_panel_damage = CreateConVar("dm_display_panel_damage", "0", "Display a panel showing damage done to a player. Requires dm_display_panel set to 1.");
	cvar_dm_sounds_bodyshots = CreateConVar("dm_sounds_bodyshots", "1", "Enable the sounds of bodyshots.");
	cvar_dm_sounds_headshots = CreateConVar("dm_sounds_headshots", "1", "Enable the sounds of headshots.");
	cvar_dm_headshot_only = CreateConVar("dm_headshot_only", "0", "Headshot only mode.");
	cvar_dm_headshot_only_allow_world = CreateConVar("dm_headshot_only_allow_world", "0", "Enable world damage during headshot only mode.");
	cvar_dm_headshot_only_allow_knife = CreateConVar("dm_headshot_only_allow_knife", "0", "Enable knife damage during headshot only mode.");
	cvar_dm_headshot_only_allow_taser = CreateConVar("dm_headshot_only_allow_taser", "0", "Enable taser damage during headshot only mode.");
	cvar_dm_headshot_only_allow_nade = CreateConVar("dm_headshot_only_allow_nade", "0", "Enable grenade damage during headshot only mode.");
	cvar_dm_remove_objectives = CreateConVar("dm_remove_objectives", "1", "Remove objectives (disables bomb sites, and removes c4 and hostages).");
	cvar_dm_respawning = CreateConVar("dm_respawning", "1", "Enable respawning.");
	cvar_dm_respawn_time = CreateConVar("dm_respawn_time", "2.0", "Respawn time.");
	cvar_dm_gun_menu_mode = CreateConVar("dm_gun_menu_mode", "1", "Gun menu mode. 1) Enabled. 2) Primary weapons only. 3) Secondary weapons only. 4) Random weapons only. 5) Disabled.");
	cvar_dm_los_spawning = CreateConVar("dm_los_spawning", "1", "Enable line of sight spawning. If enabled, players will be spawned at a point where they cannot see enemies, and enemies cannot see them.");
	cvar_dm_los_attempts = CreateConVar("dm_los_attempts", "10", "Maximum number of attempts to find a suitable line of sight spawn point.");
	cvar_dm_spawn_distance = CreateConVar("dm_spawn_distance", "0.0", "Minimum distance from enemies at which a player can spawn.");
	cvar_dm_spawn_time = CreateConVar("dm_spawn_time", "1.0", "Spawn protection time.");
	cvar_dm_no_knife_damage = CreateConVar("dm_no_knife_damage", "0", "Knives do NO damage to players.");
	cvar_dm_remove_weapons = CreateConVar("dm_remove_weapons", "1", "Remove ground weapons.");
	cvar_dm_replenish_ammo = CreateConVar("dm_replenish_ammo", "1", "Replenish ammo on reload.");
	cvar_dm_replenish_clip = CreateConVar("dm_replenish_clip", "0", "Replenish ammo clip on kill.");
	cvar_dm_replenish_reserve = CreateConVar("dm_replenish_reserve", "0", "Replenish ammo reserve on kill.");
	cvar_dm_replenish_grenade = CreateConVar("dm_replenish_grenade", "0", "Unlimited player grenades.");
	cvar_dm_replenish_hegrenade = CreateConVar("dm_replenish_hegrenade", "0", "Unlimited hegrenades.");
	cvar_dm_replenish_grenade_kill = CreateConVar("dm_replenish_grenade_kill", "0", "Give players their grenade back on successful kill.");
	cvar_dm_hp_start = CreateConVar("dm_hp_start", "100", "Spawn Health Points (HP).");
	cvar_dm_hp_max = CreateConVar("dm_hp_max", "100", "Maximum Health Points (HP).");
	cvar_dm_hp_kill = CreateConVar("dm_hp_kill", "5", "Health Points (HP) per kill.");
	cvar_dm_hp_hs = CreateConVar("dm_hp_hs", "10", "Health Points (HP) per headshot kill.");
	cvar_dm_hp_knife = CreateConVar("dm_hp_knife", "50", "Health Points (HP) per knife kill.");
	cvar_dm_hp_nade = CreateConVar("dm_hp_nade", "30", "Health Points (HP) per nade kill.");
	cvar_dm_hp_messages = CreateConVar("dm_hp_messages", "1", "Display HP messages.");
	cvar_dm_ap_max = CreateConVar("dm_ap_max", "100", "Maximum Armor Points (AP).");
	cvar_dm_ap_kill = CreateConVar("dm_ap_kill", "5", "Armor Points (AP) per kill.");
	cvar_dm_ap_hs = CreateConVar("dm_ap_hs", "10", "Armor Points (AP) per headshot kill.");
	cvar_dm_ap_knife = CreateConVar("dm_ap_knife", "50", "Armor Points (AP) per knife kill.");
	cvar_dm_ap_nade = CreateConVar("dm_ap_nade", "30", "Armor Points (AP) per nade kill.");
	cvar_dm_ap_messages = CreateConVar("dm_ap_messages", "1", "Display AP messages.");
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

	/* Load DM Config */
	LoadConfig();

	/* Admin Commands */
	RegAdminCmd("dm_spawn_menu", Command_SpawnMenu, ADMFLAG_CHANGEMAP, "Opens the spawn point menu.");
	RegAdminCmd("dm_respawn_all", Command_RespawnAll, ADMFLAG_CHANGEMAP, "Respawns all players.");
	RegAdminCmd("dm_stats", Command_Stats, ADMFLAG_CHANGEMAP, "Displays spawn statistics.");
	RegAdminCmd("dm_reset_stats", Command_ResetStats, ADMFLAG_CHANGEMAP, "Resets spawn statistics.");

	/* Client Commands */
	char guns[32];
	Format(guns, sizeof(guns), "%t", "Guns Menu");
	RegConsoleCmd(guns, Command_Guns);

	/* Hook Console Variables */
	HookConVarChange(cvar_dm_enabled, Event_CvarChange);
	HookConVarChange(cvar_dm_valvedm, Event_CvarChange);
	HookConVarChange(cvar_dm_welcomemsg, Event_CvarChange);
	HookConVarChange(cvar_dm_free_for_all, Event_CvarChange);
	HookConVarChange(cvar_dm_hide_radar, Event_CvarChange);
	HookConVarChange(cvar_dm_display_panel, Event_CvarChange);
	HookConVarChange(cvar_dm_display_panel_damage, Event_CvarChange);
	HookConVarChange(cvar_dm_sounds_bodyshots, Event_CvarChange);
	HookConVarChange(cvar_dm_sounds_headshots, Event_CvarChange);
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
	HookConVarChange(cvar_dm_no_knife_damage, Event_CvarChange);
	HookConVarChange(cvar_dm_remove_weapons, Event_CvarChange);
	HookConVarChange(cvar_dm_replenish_ammo, Event_CvarChange);
	HookConVarChange(cvar_dm_replenish_clip, Event_CvarChange);
	HookConVarChange(cvar_dm_replenish_reserve, Event_CvarChange);
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
	HookConVarChange(cvar_dm_ap_max, Event_CvarChange);
	HookConVarChange(cvar_dm_ap_kill, Event_CvarChange);
	HookConVarChange(cvar_dm_ap_hs, Event_CvarChange);
	HookConVarChange(cvar_dm_ap_knife, Event_CvarChange);
	HookConVarChange(cvar_dm_ap_nade, Event_CvarChange);
	HookConVarChange(cvar_dm_ap_messages, Event_CvarChange);
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

	/* Listen For Client Commands */
	AddCommandListener(Event_Say, "say");
	AddCommandListener(Event_Say, "say_team");

	/* Hook Client Messages */
	HookUserMessage(GetUserMessageId("TextMsg"), Event_TextMsg, true);
	HookUserMessage(GetUserMessageId("HintText"), Event_HintText, true);
	HookUserMessage(GetUserMessageId("RadioText"), Event_RadioText, true);

	/* Hook Events */
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("round_prestart", Event_RoundPrestart, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("weapon_reload", Event_WeaponReload, EventHookMode_Post);
	HookEvent("hegrenade_detonate", Event_HegrenadeDetonate, EventHookMode_Post);
	HookEvent("smokegrenade_detonate", Event_SmokegrenadeDetonate, EventHookMode_Post);
	HookEvent("flashbang_detonate", Event_FlashbangDetonate, EventHookMode_Post);
	HookEvent("molotov_detonate", Event_MolotovDetonate, EventHookMode_Post);
	HookEvent("inferno_startburn", Event_InfernoStartburn, EventHookMode_Post);
	HookEvent("decoy_started", Event_DecoyStarted, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("bomb_pickup", Event_BombPickup);

	/* Hook Sound Events */
	AddNormalSoundHook(view_as<NormalSHook>(Event_Sound));

	/* Create Global Timers */
	CreateTimer(0.5, UpdateSpawnPointStatus, INVALID_HANDLE, TIMER_REPEAT);
	CreateTimer(1.0, RemoveGroundWeapons, INVALID_HANDLE, TIMER_REPEAT);

	/* Find Offsets */
	g_iWeapons_Clip1Offset = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");

	if (g_iWeapons_Clip1Offset == -1)
	{
		SetFailState("[DM] Error - Unable to get offset for CBaseCombatWeapon::m_iClip1");
	}

	healthOffset = FindSendPropInfo("CCSPlayer", "m_iHealth");

	if (healthOffset == -1)
	{
		SetFailState("[DM] Error - Unable to get offset for CCSPlayer::m_iHealth");
	}

	armorOffset = FindSendPropInfo("CCSPlayer", "m_ArmorValue");

	if (armorOffset == -1)
	{
		SetFailState("[DM] Error - Unable to get offset for CCSPlayer::m_ArmorValue");
	}

	/* SDK Hooks For Clients */
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}

	/* Updater */
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}

	/* Update and retrieve */
	RetrieveVariables();
	UpdateState();
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "updater")) Updater_RemovePlugin();
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		DisableSpawnProtection(INVALID_HANDLE, i);
	}
	SetBuyZones("Enable");
	SetObjectives("Enable");
	/* Cancel Menus */
	CancelMenu(optionsMenu1);
	CancelMenu(optionsMenu2);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (primaryMenus[i] != INVALID_HANDLE)
			CancelMenu(primaryMenus[i]);
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (secondaryMenus[i] != INVALID_HANDLE)
			CancelMenu(secondaryMenus[i]);
	}
	RestoreCashState();
	RestoreGrenadeState();
	DisableFFA();
}

public void OnConfigsExecuted()
{
	RetrieveVariables();
	UpdateState();
}

public void OnMapStart()
{
	/* Precache Sprite */
	glowSprite = PrecacheModel("sprites/glow01.vmt", true);

	InitialiseWeaponCounts();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
			ResetClientSettings(i);
	}
	LoadMapConfig();
	if (spawnPointCount > 0)
	{
		for (int i = 0; i < spawnPointCount; i++)
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

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientPostAdminCheck(int client)
{
	if (enabled)
	{
		ResetClientSettings(client);
	}
}

public void OnClientDisconnect(int client)
{
	RemoveRagdoll(client);
	SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}


stock bool IsValidClient(int client)
{
	if (!(0 < client <= MaxClients)) return false;
	if (!IsClientInGame(client)) return false;
	return true;
}

void ResetClientSettings(int client)
{
	lastEditorSpawnPoint[client] = -1;
	SetClientGunModeSettings(client);
	infoMessageCount[client] = 2;
	weaponsGivenThisRound[client] = false;
	newWeaponsSelected[client] = false;
	playerMoved[client] = false;
}

void SetClientGunModeSettings(int client)
{
	if (gunMenuMode != 4)
	{
		if(gunMenuMode <= 3 && !IsFakeClient(client))
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
			primaryWeapon[client] = "random";
			secondaryWeapon[client] = "none";
			firstWeaponSelection[client] = false;
			rememberChoice[client] = true;
		}
		else if (gunMenuMode == 3 && IsFakeClient(client))
		{
			primaryWeapon[client] = "none";
			secondaryWeapon[client] = "random";
			firstWeaponSelection[client] = false;
			rememberChoice[client] = true;
		}
	}
	else if (gunMenuMode == 4)
	{
		primaryWeapon[client] = "random";
		secondaryWeapon[client] = "random";
		firstWeaponSelection[client] = false;
		rememberChoice[client] = true;
	}
}

public void Event_CvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	UpdateState();
}

void LoadConfig()
{
	Handle keyValues = CreateKeyValues("Deathmatch Config");
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/deathmatch/deathmatch.ini");

	if (!FileToKeyValues(keyValues, path))
		SetFailState("The configuration file could not be read.");

	char key[25];
	char value[25];

	if (!KvJumpToKey(keyValues, "Options"))
		SetFailState("The configuration file is corrupt (\"Options\" section could not be found).");

	KvGetString(keyValues, "dm_enabled", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_enabled, value);

	KvGetString(keyValues, "dm_enable_valve_deathmatch", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_valvedm, value);

	KvGetString(keyValues, "dm_welcomemsg", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_welcomemsg, value);

	KvGetString(keyValues, "dm_free_for_all", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_free_for_all, value);

	KvGetString(keyValues, "dm_hide_radar", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_hide_radar, value);

	KvGetString(keyValues, "dm_display_panel", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_display_panel, value);

	KvGetString(keyValues, "dm_display_panel_damage", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_display_panel_damage, value);

	KvGetString(keyValues, "dm_sounds_bodyshots", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_sounds_bodyshots, value);

	KvGetString(keyValues, "dm_sounds_headshots", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_sounds_headshots, value);

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

	KvGetString(keyValues, "dm_no_knife_damage", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_no_knife_damage, value);

	KvGetString(keyValues, "dm_remove_weapons", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_remove_weapons, value);

	KvGetString(keyValues, "dm_replenish_ammo", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_replenish_ammo, value);

	KvGetString(keyValues, "dm_replenish_clip", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_replenish_clip, value);

	KvGetString(keyValues, "dm_replenish_reserve", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_replenish_reserve, value);

	KvGetString(keyValues, "dm_replenish_grenade", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_replenish_grenade, value);

	KvGetString(keyValues, "dm_replenish_hegrenade", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_replenish_hegrenade, value);

	KvGetString(keyValues, "dm_replenish_grenade_kill", value, sizeof(value), "no");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_replenish_grenade_kill, value);

	KvGetString(keyValues, "dm_display_grenade_messages", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_nade_messages, value);

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

	KvGetString(keyValues, "dm_player_ap_max", value, sizeof(value), "100");
	SetConVarString(cvar_dm_ap_max, value);

	KvGetString(keyValues, "dm_ap_per_kill", value, sizeof(value), "5");
	SetConVarString(cvar_dm_ap_kill, value);

	KvGetString(keyValues, "dm_ap_per_headshot_kill", value, sizeof(value), "10");
	SetConVarString(cvar_dm_ap_hs, value);

	KvGetString(keyValues, "dm_ap_per_knife_kill", value, sizeof(value), "50");
	SetConVarString(cvar_dm_ap_knife, value);

	KvGetString(keyValues, "dm_ap_per_nade_kill", value, sizeof(value), "30");
	SetConVarString(cvar_dm_ap_nade, value);

	KvGetString(keyValues, "dm_display_ap_messages", value, sizeof(value), "yes");
	value = (StrEqual(value, "yes")) ? "1" : "0";
	SetConVarString(cvar_dm_ap_messages, value);

	KvGoBack(keyValues);

	if (!KvJumpToKey(keyValues, "Weapons"))
		SetFailState("The configuration file is corrupt (\"Weapons\" section could not be found).");

	if (!KvJumpToKey(keyValues, "Primary"))
		SetFailState("The configuration file is corrupt (\"Primary\" section could not be found).");

	if (KvGotoFirstSubKey(keyValues, false))
	{
		do {
			KvGetSectionName(keyValues, key, sizeof(key));
			int limit = KvGetNum(keyValues, NULL_STRING, -1);
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
			int limit = KvGetNum(keyValues, NULL_STRING, -1);
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

	KvGoBack(keyValues);

	if (KvJumpToKey(keyValues, "TeamData") && KvGotoFirstSubKey(keyValues, false)) {
		do {
			KvGetSectionName(keyValues, key, sizeof(key));
			KvGetString(keyValues, NULL_STRING, value, sizeof(value), "");
			int team = 0;
			if (StrEqual(value, "CT", false))
			{
				team = CS_TEAM_CT;
			}
			else if (StrEqual(value, "T", false))
			{
				team = CS_TEAM_T;
			}
			weaponSkipMap.SetValue(key, team);
		} while (KvGotoNextKey(keyValues, false));
		KvGoBack(keyValues);
	}

	CloseHandle(keyValues);
}

void RetrieveVariables()
{
	/* Retrieve Native Console Variables */
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

	/* Retrieve Native Console Variable Values */
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
}

void UpdateState()
{
	int old_enabled = enabled;
	int old_gunMenuMode = gunMenuMode;

	enabled = GetConVarBool(cvar_dm_enabled);
	valveDM = GetConVarBool(cvar_dm_valvedm);
	welcomemsg = GetConVarBool(cvar_dm_welcomemsg);
	ffa = GetConVarBool(cvar_dm_free_for_all);
	hideradar = GetConVarBool(cvar_dm_hide_radar);
	displayPanel = GetConVarBool(cvar_dm_display_panel);
	displayPanelDamage = GetConVarBool(cvar_dm_display_panel_damage);
	bdSounds = GetConVarBool(cvar_dm_sounds_bodyshots);
	hsSounds = GetConVarBool(cvar_dm_sounds_headshots);
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
	noKnifeDamage = GetConVarBool(cvar_dm_no_knife_damage);
	removeWeapons = GetConVarBool(cvar_dm_remove_weapons);
	replenishAmmo = GetConVarBool(cvar_dm_replenish_ammo);
	replenishClip = GetConVarBool(cvar_dm_replenish_clip);
	replenishReserve = GetConVarBool(cvar_dm_replenish_reserve);
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
	maxAP = GetConVarInt(cvar_dm_ap_max);
	APPerKill = GetConVarInt(cvar_dm_ap_kill);
	APPerHeadshotKill = GetConVarInt(cvar_dm_ap_hs);
	APPerKnifeKill = GetConVarInt(cvar_dm_ap_knife);
	APPerNadeKill = GetConVarInt(cvar_dm_ap_nade);
	displayAPMessages = GetConVarBool(cvar_dm_ap_messages);
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
	if (gunMenuMode > 5) gunMenuMode = 5;
	if (lineOfSightAttempts < 0) lineOfSightAttempts = 0;
	if (spawnDistanceFromEnemies < 0.0) spawnDistanceFromEnemies = 0.0;
	if (spawnProtectionTime < 0.0) spawnProtectionTime = 0.0;
	if (startHP < 1) startHP = 1;
	if (maxHP < 1) maxHP = 1;
	if (HPPerKill < 0) HPPerKill = 0;
	if (HPPerHeadshotKill < 0) HPPerHeadshotKill = 0;
	if (HPPerKnifeKill < 0) HPPerKnifeKill = 0;
	if (HPPerNadeKill < 0) HPPerNadeKill = 0;
	if (maxAP < 0) maxAP = 0;
	if (APPerKill < 0) APPerKill = 0;
	if (APPerHeadshotKill < 0) APPerHeadshotKill = 0;
	if (APPerKnifeKill < 0) APPerKnifeKill = 0;
	if (APPerNadeKill < 0) APPerNadeKill = 0;
	if (incendiary < 0) incendiary = 0;
	if (molotov < 0) molotov = 0;
	if (decoy < 0) decoy = 0;
	if (flashbang < 0) flashbang = 0;
	if (he < 0) he = 0;
	if (smoke < 0) smoke = 0;

	if (enabled && !old_enabled)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i))
				ResetClientSettings(i);
		}
		RespawnAll();
		SetBuyZones("Disable");
		char status[10];
		status = (removeObjectives) ? "Disable" : "Enable";
		SetObjectives(status);
		SetCashState();
		SetNoSpawnWeapons();
	}
	else if (!enabled && old_enabled)
	{
		for (int i = 1; i <= MaxClients; i++)
			DisableSpawnProtection(INVALID_HANDLE, i);
		CancelMenu(optionsMenu1);
		CancelMenu(optionsMenu2);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (primaryMenus[i] != INVALID_HANDLE)
				CancelMenu(primaryMenus[i]);
		}
		for (int i = 1; i <= MaxClients; i++)
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
			if (gunMenuMode == 5)
			{
				for (int i = 1; i <= MaxClients; i++)
					CancelClientMenu(i);
			}
			/* Only if the plugin was enabled before the state update do we need to update the client's gun mode settings. If it was disabled before, then */
			/* the entire client settings (including gun mode settings) are reset above. */
			if (old_enabled)
			{
				for (int i = 1; i <= MaxClients; i++)
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

void SetNoSpawnWeapons()
{
	SetConVarString(mp_ct_default_primary, "");
	SetConVarString(mp_t_default_primary, "");
	SetConVarString(mp_ct_default_secondary, "");
	SetConVarString(mp_t_default_secondary, "");
}

void SetCashState()
{
	SetConVarInt(mp_startmoney, 0);
	SetConVarInt(mp_playercashawards, 0);
	SetConVarInt(mp_teamcashawards, 0);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
			SetEntProp(i, Prop_Send, "m_iAccount", 0);
	}
}

void RestoreCashState()
{
	SetConVarInt(mp_startmoney, backup_mp_startmoney);
	SetConVarInt(mp_playercashawards, backup_mp_playercashawards);
	SetConVarInt(mp_teamcashawards, backup_mp_teamcashawards);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
			SetEntProp(i, Prop_Send, "m_iAccount", backup_mp_startmoney);
	}
}

void SetGrenadeState()
{
	int maxGrenadesSameType = 0;
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

void RestoreGrenadeState()
{
	SetConVarInt(ammo_grenade_limit_default, backup_ammo_grenade_limit_default);
	SetConVarInt(ammo_grenade_limit_flashbang, backup_ammo_grenade_limit_flashbang);
	SetConVarInt(ammo_grenade_limit_total, backup_ammo_grenade_limit_total);
}

void EnableFFA()
{
	SetConVarInt(mp_teammates_are_enemies, 1);
	SetConVarInt(mp_friendlyfire, 1);
	SetConVarInt(mp_autokick, 0);
	SetConVarInt(mp_tkpunish, 0);
	SetConVarFloat(ff_damage_reduction_bullets, 1.0);
	SetConVarFloat(ff_damage_reduction_grenade, 1.0);
	SetConVarFloat(ff_damage_reduction_other, 1.0);
}

void DisableFFA()
{
	SetConVarInt(mp_teammates_are_enemies, backup_mp_teammates_are_enemies);
	SetConVarInt(mp_friendlyfire, backup_mp_friendlyfire);
	SetConVarInt(mp_autokick, backup_mp_autokick);
	SetConVarInt(mp_tkpunish, backup_mp_tkpunish);
	SetConVarFloat(ff_damage_reduction_bullets, backup_ff_damage_reduction_bullets);
	SetConVarFloat(ff_damage_reduction_grenade, backup_ff_damage_reduction_grenade);
	SetConVarFloat(ff_damage_reduction_other, backup_ff_damage_reduction_other);
}

void LoadMapConfig()
{
	char map[64];
	GetCurrentMap(map, sizeof(map));

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/deathmatch/spawns/%s.txt", map);

	spawnPointCount = 0;

	/* Open file */
	Handle file = OpenFile(path, "r");
	if (file == INVALID_HANDLE)
		return;
	/* Read file */
	char buffer[256];
	char parts[6][16];
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
	/* Close file */
	CloseHandle(file);
}

bool WriteMapConfig()
{
	char map[64];
	GetCurrentMap(map, sizeof(map));

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/deathmatch/spawns/%s.txt", map);

	/* Open file */
	Handle file = OpenFile(path, "w");
	if (file == INVALID_HANDLE)
	{
		LogError("Could not open spawn point file \"%s\" for writing.", path);
		return false;
	}
	/* Write spawn points */
	for (int i = 0; i < spawnPointCount; i++)
		WriteFileLine(file, "%f %f %f %f %f %f", spawnPositions[i][0], spawnPositions[i][1], spawnPositions[i][2], spawnAngles[i][0], spawnAngles[i][1], spawnAngles[i][2]);
	/* Close file */
	CloseHandle(file);
	return true;
}

public Action Event_Say(int client, const char[] command, int argc)
{
	static char menuTriggers[][] = { "gun", "!gun", "/gun", "guns", "!guns", "/guns", "menu", "!menu", "/menu", "weapon", "!weapon", "/weapon", "weapons", "!weapons", "/weapons" };

	if (enabled && IsValidClient(client) && (GetClientTeam(client) != CS_TEAM_SPECTATOR))
	{
		/* Retrieve and clean up text. */
		char text[24];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		TrimString(text);

		for(int i = 0; i < sizeof(menuTriggers); i++)
		{
			if (StrEqual(text, menuTriggers[i], false))
			{
				if (gunMenuMode == 1 || gunMenuMode == 2 || gunMenuMode == 3)
					DisplayOptionsMenu(client);
				else
					CPrintToChat(client, "[\x04DM\x01] %t", "Guns Disabled");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

void BuildWeaponMenuNames()
{
	weaponMenuNames = CreateTrie();
	/* Primary weapons */
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
	/* Secondary weapons */
	SetTrieString(weaponMenuNames, "weapon_glock", "Glock-18");
	SetTrieString(weaponMenuNames, "weapon_p250", "P250");
	SetTrieString(weaponMenuNames, "weapon_cz75a", "CZ75-A");
	SetTrieString(weaponMenuNames, "weapon_usp_silencer", "USP-S");
	SetTrieString(weaponMenuNames, "weapon_fiveseven", "Five-SeveN");
	SetTrieString(weaponMenuNames, "weapon_deagle", "Desert Eagle");
	SetTrieString(weaponMenuNames, "weapon_revolver", "R8");
	SetTrieString(weaponMenuNames, "weapon_elite", "Dual Berettas");
	SetTrieString(weaponMenuNames, "weapon_tec9", "Tec-9");
	SetTrieString(weaponMenuNames, "weapon_hkp2000", "P2000");
	/* Random */
	SetTrieString(weaponMenuNames, "random", "Random");
}

void InitialiseWeaponCounts()
{
	for (int i = 0; i < GetArraySize(primaryWeaponsAvailable); i++)
	{
		char weapon[24];
		GetArrayString(primaryWeaponsAvailable, i, weapon, sizeof(weapon));
		SetTrieValue(weaponCounts, weapon, 0);
	}
	for (int i = 0; i < GetArraySize(secondaryWeaponsAvailable); i++)
	{
		char weapon[24];
		GetArrayString(secondaryWeaponsAvailable, i, weapon, sizeof(weapon));
		SetTrieValue(weaponCounts, weapon, 0);
	}
}

void DisplayOptionsMenu(int client)
{
	if (!firstWeaponSelection[client])
		DisplayMenu(optionsMenu1, client, MENU_TIME_FOREVER);
	else
		DisplayMenu(optionsMenu2, client, MENU_TIME_FOREVER);
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	/* If the player joins spectator, close any open menu, and remove their ragdoll. */
	if ((client != 0) && (GetClientTeam(client) == CS_TEAM_SPECTATOR))
	{
		CancelClientMenu(client);
		RemoveRagdoll(client);
	}
	if (enabled && respawning)
		CreateTimer(respawnTime, Respawn, GetClientSerial(client));
}

public Action Event_RoundPrestart(Event event, const char[] name, bool dontBroadcast)
{
	roundEnded = false;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (enabled)
	{
		if (removeObjectives)
			RemoveHostages();
		if (removeWeapons)
			RemoveGroundWeapons(INVALID_HANDLE);
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	roundEnded = true;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (enabled)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (GetClientTeam(client) != CS_TEAM_SPECTATOR)
		{
			if (!IsFakeClient(client))
			{
				if (welcomemsg && infoMessageCount[client] > 0)
				{
					PrintHintText(client, "This server is running:\n <font color='#00FF00'>Deathmatch</font> v%s", PLUGIN_VERSION);
					CPrintToChat(client, "[\x04DM\x01] This server is running \x04Deathmatch \x01v%s", PLUGIN_VERSION);
				}
				/* Hide radar. */
				if (ffa || hideradar)
				{
					CreateTimer(0.0, RemoveRadar, GetClientSerial(client));
				}
				/* Display help message. */
				if ((gunMenuMode <= 3) && infoMessageCount[client] > 0)
				{
					CPrintToChat(client, "[\x04DM\x01] %t", "Guns Menu");
					infoMessageCount[client]--;
				}
				/* Display the panel for attacker information. */
				if (displayPanel)
				{
					damageDisplay[client] = CreateTimer(1.0, PanelDisplay, GetClientSerial(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			/* Teleport player to custom spawn point. */
			if (spawnPointCount > 0)
			{
				MovePlayer(client);
			}
			/* Enable player spawn protection. */
			if (spawnProtectionTime > 0.0)
			{
				EnableSpawnProtection(client);
			}
			/* Set health. */
			if (startHP != 100)
			{
				SetEntityHealth(client, startHP);
			}
			/* Give equipment */
			if (armorChest)
			{
				SetEntData(client, armorOffset, 100);
				SetEntData(client, helmetOffset, 0);
			}
			else if (armorFull)
			{
				SetEntData(client, armorOffset, 100);
				SetEntData(client, helmetOffset, 1);
			}
			else if (!armorFull || !armorChest)
			{
				SetEntData(client, armorOffset, 0);
				SetEntData(client, helmetOffset, 0);
			}
			/* Give weapons or display menu. */
			weaponsGivenThisRound[client] = false;
			RemoveClientWeapons(client);
			/* Give weapons selected from menu. */
			if (newWeaponsSelected[client])
			{
				GiveSavedWeapons(client, true, true);
				newWeaponsSelected[client] = false;
			}
			/* Give the remembered weapon choice. */
			else if (rememberChoice[client])
			{
				if (gunMenuMode == 1 || gunMenuMode == 4)
				{
					GiveSavedWeapons(client, true, true);
				}
				/* Give only primary weapons if remembered. */
				else if (gunMenuMode == 2)
				{
					GiveSavedWeapons(client, true, false)
				}
				/* Give only secondary weapons if remembered. */
				else if (gunMenuMode == 3)
				{
					GiveSavedWeapons(client, false, true);
				}
			}
			/* Display the gun menu to new users. */
			else if (IsValidClient(client) && !IsFakeClient(client))
			{
				/* All weapons menu. */
				if (gunMenuMode <= 3)
				{
					DisplayOptionsMenu(client);
				}
			}
			/* Remove C4. */
			if (removeObjectives)
			{
				StripC4(client);
			}
		}
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (enabled)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		int attackerIndex = GetClientOfUserId(event.GetInt("attacker"));
		char weapon[6];
		char hegrenade[16];
		char decoygrenade[16];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		GetEventString(event, "weapon", hegrenade, sizeof(hegrenade));
		GetEventString(event, "weapon", decoygrenade, sizeof(decoygrenade));

		bool validAttacker = (attackerIndex != 0) && IsPlayerAlive(attackerIndex);

		/* Reward the attacker with ammo. */
		if (validAttacker && (replenishClip || replenishReserve))
		{
			GiveAmmo(INVALID_HANDLE, attackerIndex);
		}

		/* Reward attacker with HP. */
		if (validAttacker)
		{
			bool knifed = StrEqual(weapon, "knife");
			bool nades = StrEqual(hegrenade, "hegrenade");
			bool decoys = StrEqual(decoygrenade, "decoy");
			bool headshot = GetEventBool(event, "headshot");

			if ((knifed && (HPPerKnifeKill > 0)) || (!knifed && (HPPerKill > 0)) || (headshot && (HPPerHeadshotKill > 0)) || (!headshot && (HPPerKill > 0)))
			{
				int attackerHP = GetClientHealth(attackerIndex);

				if (attackerHP < maxHP)
				{
					int addHP;
					if (knifed)
						addHP = HPPerKnifeKill;
					else if (headshot)
						addHP = HPPerHeadshotKill;
					else if (nades)
						addHP = HPPerNadeKill;
					else
						addHP = HPPerKill;
					int newHP = attackerHP + addHP;
					if (newHP > maxHP)
						newHP = maxHP;
					SetEntProp(attackerIndex, Prop_Send, "m_iHealth", newHP, 1);
				}

				if (displayHPMessages && !displayAPMessages)
				{
					if (knifed)
						CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 %t", HPPerKnifeKill, "HP Knife Kill");
					else if (headshot)
						CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 %t", HPPerHeadshotKill, "HP Headshot Kill");
					else if (nades)
						CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 %t", HPPerNadeKill, "HP Nade Kill");
					else
						CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 %t", HPPerKill, "HP Kill");
				}
			}

			/* Reward attacker with AP. */
			if ((knifed && (APPerKnifeKill > 0)) || (!knifed && (APPerKill > 0)) || (headshot && (APPerHeadshotKill > 0)) || (!headshot && (APPerKill > 0)))
			{
				int attackerAP = GetClientArmor(attackerIndex);

				if (attackerAP < maxAP)
				{
					int addAP;
					if (knifed)
						addAP = APPerKnifeKill;
					else if (headshot)
						addAP = APPerHeadshotKill;
					else if (nades)
						addAP = APPerNadeKill;
					else
						addAP = APPerKill;
					int newAP = attackerAP + addAP;
					if (newAP > maxAP)
						newAP = maxAP;
					SetEntProp(attackerIndex, Prop_Send, "m_ArmorValue", newAP, 1);
				}

				if (displayAPMessages && !displayHPMessages)
				{
					if (knifed)
						CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i AP\x01 %t", APPerKnifeKill, "AP Knife Kill");
					else if (headshot)
						CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i AP\x01 %t", APPerHeadshotKill, "AP Headshot Kill");
					else if (nades)
						CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i AP\x01 %t", APPerNadeKill, "AP Nade Kill");
					else
						CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i AP\x01 %t", APPerKill, "AP Kill");
				}
			}

			if (displayHPMessages && displayAPMessages)
			{
				if (knifed)
					CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 & \x04+%i AP\x01 %t", HPPerKnifeKill, APPerKnifeKill, "HP Knife Kill", "AP Knife Kill");
				else if (headshot)
					CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 & \x04+%i AP\x01 %t", HPPerHeadshotKill, APPerHeadshotKill, "HP Headshot Kill", "AP Headshot Kill");
				else if (nades)
					CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 & \x04+%i AP\x01 %t", HPPerNadeKill, APPerNadeKill, "HP Nade Kill", "AP Nade Kill");
				else
					CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 & \x04+%i AP\x01 %t", HPPerKill, APPerKill, "HP Kill", "AP Kill");
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

		if (respawning)
		{
			CreateTimer(respawnTime, Respawn, GetClientSerial(client));
		}
	}
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (displayPanel)
	{
		int victim = GetClientOfUserId(event.GetInt("userid"));
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		int health = event.GetInt("health");

		if (IsValidClient(attacker) && attacker != victim && victim != 0)
		{
			if (0 < health)
			{
				if (displayPanelDamage)
				{
					PrintHintText(attacker, "%t <font color='#FF0000'>%i</font> %t <font color='#00FF00'>%N</font>\n %t <font color='#00FF00'>%i</font>", "Panel Damage Giver", event.GetInt("dmg_health"), "Panel Damage Taker", victim, "Panel Health Remaining", health);
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
		int victim = GetClientOfUserId(event.GetInt("userid"));
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		int dhealth = event.GetInt("dmg_health");
		int darmor = event.GetInt("dmg_iArmor");
		int health = event.GetInt("health");
		int armor = event.GetInt("armor");
		char weapon[32];
		char grenade[16];
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
						SetEntData(victim, healthOffset, (health + dhealth), 4, true);
					}
					if (darmor > 0)
					{
						SetEntData(victim, armorOffset, (armor + darmor), 4, true);
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
						SetEntData(victim, healthOffset, (health + dhealth), 4, true);
					}
					if (darmor > 0)
					{
						SetEntData(victim, armorOffset, (armor + darmor), 4, true);
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
						SetEntData(victim, healthOffset, (health + dhealth), 4, true);
					}
					if (darmor > 0)
					{
						SetEntData(victim, armorOffset, (armor + darmor), 4, true);
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
					SetEntData(victim, healthOffset, (health + dhealth), 4, true);
				}
				if (darmor > 0)
				{
					SetEntData(victim, armorOffset, (armor + darmor), 4, true);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_WeaponReload(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (replenishAmmo)
	{
		GiveAmmo(INVALID_HANDLE, client);
	}
}

public Action Event_HegrenadeDetonate(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (replenishGrenade && !replenishHEGrenade)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_hegrenade");
		}
	}

	else if (replenishHEGrenade && !replenishGrenade)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_hegrenade");
		}
	}

	else if (replenishGrenade && replenishHEGrenade)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_hegrenade");
		}
	}

	return Plugin_Continue;
}

public Action Event_SmokegrenadeDetonate(Event event, const char[] name, bool dontBroadcast)
{
	if (!replenishGrenade)
	{
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (replenishGrenade)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_smokegrenade");
		}
	}

	return Plugin_Continue;
}

public Action Event_FlashbangDetonate(Event event, const char[] name, bool dontBroadcast)
{
	if (!replenishGrenade)
	{
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (replenishGrenade)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_flashbang");
		}
	}

	return Plugin_Continue;
}

public Action Event_DecoyStarted(Event event, const char[] name, bool dontBroadcast)
{
	if (!replenishGrenade)
	{
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (replenishGrenade)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_decoy");
		}
	}

	return Plugin_Continue;
}

public Action Event_MolotovDetonate(Event event, const char[] name, bool dontBroadcast)
{
	if (!replenishGrenade)
	{
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (replenishGrenade)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_molotov");
		}
	}

	return Plugin_Continue;
}

public Action Event_InfernoStartburn(Event event, const char[] name, bool dontBroadcast)
{
	if (!replenishGrenade)
	{
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (replenishGrenade)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_incgrenade");
		}
	}

	return Plugin_Continue;
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (noKnifeDamage)
	{
		char knife[32];
		GetClientWeapon(attacker, knife, sizeof(knife));
		if (StrEqual(knife, "weapon_knife") || StrEqual(knife, "weapon_bayonet"))
		{
			return Plugin_Handled;
		}
	}

	if (hsOnly)
	{
		char weapon[32];
		char grenade[32];
		GetEdictClassname(inflictor, grenade, sizeof(grenade));
		GetClientWeapon(attacker, weapon, sizeof(weapon));

		if (hitgroup == 1)
		{
			return Plugin_Continue;
		}
		else if (hsOnly_AllowKnife && (StrEqual(weapon, "weapon_knife") || StrEqual(weapon, "weapon_bayonet")))
		{
			return Plugin_Continue;
		}
		else if (hsOnly_AllowNade && (StrEqual(grenade, "hegrenade_projectile") || StrEqual(grenade, "decoy_projectile") || StrEqual(grenade, "molotov_projectile")))
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

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (noKnifeDamage)
	{
		if (IsValidClient(attacker))
		{
			char knife[32];
			GetClientWeapon(attacker, knife, sizeof(knife));
			if (StrEqual(knife, "weapon_knife") || StrEqual(knife, "weapon_bayonet"))
			{
				return Plugin_Handled;
			}
		}
	}

	if (hsOnly)
	{
		char grenade[32];
		char weapon[32];

		if (IsValidClient(victim))
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

			if (IsValidClient(attacker))
			{
				GetEdictClassname(inflictor, grenade, sizeof(grenade));
				GetClientWeapon(attacker, weapon, sizeof(weapon));

				if (damagetype & DMG_HEADSHOT)
				{
					return Plugin_Continue;
				}
				else
				{
					if (hsOnly_AllowKnife && (StrEqual(weapon, "weapon_knife") || StrEqual(weapon, "weapon_bayonet")))
					{
						return Plugin_Continue;
					}
					else if (hsOnly_AllowNade && (StrEqual(grenade, "hegrenade_projectile") || StrEqual(grenade, "decoy_projectile") || StrEqual(grenade, "molotov_projectile")))
					{
						return Plugin_Continue;
					}
					else if (hsOnly_AllowTaser && StrEqual(weapon, "weapon_taser"))
					{
						return Plugin_Continue;
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

	return Plugin_Continue;
}

public Action PanelDisplay(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		int aim = GetClientAimTarget(client, true);
		if (0 < aim)
		{
			PrintHintText(client, "%t %i", "Panel Health Remaining", GetClientHealth(aim));
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

public Action RemoveRadar(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial);
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Send, "m_iHideHUD", HIDEHUD_RADAR);
	}
}

public Action GiveAmmo(Handle timer, any client)
{
	if (enabled && (replenishAmmo || replenishReserve || replenishClip))
	{
		if (IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client))
		{
			RefillWeapons(INVALID_HANDLE, client);
			CreateTimer(0.3, RefillWeapons, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public Action RefillWeapons(Handle timer, any client)
{
	int weaponEntity;

	if(IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client))
	{
		if (replenishAmmo || (replenishClip && replenishReserve))
		{
			weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if (weaponEntity != -1)
				DoFullRefillAmmo(EntIndexToEntRef(weaponEntity), client);

			weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if (weaponEntity != -1)
				DoFullRefillAmmo(EntIndexToEntRef(weaponEntity), client);
		}
		else if (replenishClip)
		{
			weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if (weaponEntity != -1)
				DoClipRefillAmmo(EntIndexToEntRef(weaponEntity), client);

			weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if (weaponEntity != -1)
				DoClipRefillAmmo(EntIndexToEntRef(weaponEntity), client);
		}
		else if (replenishReserve)
		{
			weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if (weaponEntity != -1)
				DoResRefillAmmo(EntIndexToEntRef(weaponEntity), client);

			weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if (weaponEntity != -1)
				DoResRefillAmmo(EntIndexToEntRef(weaponEntity), client);
		}
	}
}

void DoClipRefillAmmo(int weaponRef, any client)
{
	int weaponEntity = EntRefToEntIndex(weaponRef);

	if (IsValidEdict(weaponEntity))
	{
		char weaponName[64];
		char clipSize;
		char maxAmmoCount;

		if (GetEntityClassname(weaponEntity, weaponName, sizeof(weaponName)))
		{
			clipSize = GetWeaponAmmoCount(weaponName, true);
			maxAmmoCount = GetWeaponAmmoCount(weaponName, false);
			switch (GetEntProp(weaponRef, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 60: clipSize = 20;
				case 61: clipSize = 12;
				case 63: clipSize = 12;
				case 64: clipSize = 8;
			}
		}

		SetEntData(client, ammoOffset, maxAmmoCount, true);
		SetEntData(weaponEntity, g_iWeapons_Clip1Offset, clipSize, 4, true);
	}
}

void DoResRefillAmmo(int weaponRef, any client)
{
	int weaponEntity = EntRefToEntIndex(weaponRef);

	if (IsValidEdict(weaponEntity))
	{
		char weaponName[64];
		char maxAmmoCount;
		int ammoType = GetEntData(weaponEntity, ammoTypeOffset);

		if (GetEntityClassname(weaponEntity, weaponName, sizeof(weaponName)))
		{
			maxAmmoCount = GetWeaponAmmoCount(weaponName, false);
			switch (GetEntProp(weaponRef, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 60: maxAmmoCount = 40;
				case 61: maxAmmoCount = 24;
				case 63: maxAmmoCount = 12;
				case 64: maxAmmoCount = 8;
			}
		}

		SetEntData(client, ammoOffset + (ammoType * 4), maxAmmoCount, true);
	}
}

void DoFullRefillAmmo(int weaponRef, any client)
{
	int weaponEntity = EntRefToEntIndex(weaponRef);

	if (IsValidEdict(weaponEntity))
	{
		char weaponName[35];
		char clipSize;
		char maxAmmoCount;
		int ammoType = GetEntData(weaponEntity, ammoTypeOffset);

		if (GetEntityClassname(weaponEntity, weaponName, sizeof(weaponName)))
		{
			clipSize = GetWeaponAmmoCount(weaponName, true);
			maxAmmoCount = GetWeaponAmmoCount(weaponName, false);
			switch (GetEntProp(weaponRef, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 60: { clipSize = 20;maxAmmoCount = 40; }
				case 61: { clipSize = 12;maxAmmoCount = 24; }
				case 63: { clipSize = 12;maxAmmoCount = 12; }
				case 64: { clipSize = 8;maxAmmoCount = 8; }
			}
		}

		SetEntData(client, ammoOffset + (ammoType * 4), maxAmmoCount, true);
		SetEntData(weaponEntity, g_iWeapons_Clip1Offset, clipSize, 4, true);
	}
}

stock int GetWeaponAmmoCount(char[] weaponName, bool currentClip)
{
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
	else if (StrEqual(weaponName,  "weapon_revolver"))
		return currentClip ? 8 : 8;
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

public void Event_BombPickup(Event event, const char[] name, bool dontBroadcast)
{
	if (enabled && removeObjectives)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		StripC4(client);
	}
}

public Action Respawn(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial);
	if (!roundEnded && IsValidClient(client) && (GetClientTeam(client) != CS_TEAM_SPECTATOR) && !IsPlayerAlive(client))
	{
		/* We set this here rather than in Event_PlayerSpawn to catch the spawn sounds which occur before Event_PlayerSpawn is called (even with EventHookMode_Pre). */
		playerMoved[client] = false;
		CS_RespawnPlayer(client);
	}
}

void RespawnAll()
{
	for (int i = 1; i <= MaxClients; i++)
		Respawn(INVALID_HANDLE, i);
}

Handle BuildOptionsMenu(bool sameWeaponsEnabled)
{
	int sameWeaponsStyle = (sameWeaponsEnabled) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
	Menu menu = CreateMenu(MenuHandler);
	menu.SetTitle("Weapon Menu:");
	SetMenuExitButton(menu, false);
	menu.AddItem("New", "New weapons");
	menu.AddItem("Same 1", "Same weapons", sameWeaponsStyle);
	menu.AddItem("Same All", "Same weapons every round", sameWeaponsStyle);
	menu.AddItem("Random 1", "Random weapons");
	menu.AddItem("Random All", "Random weapons every round");
	return menu;
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[24];
		GetMenuItem(menu, param2, info, sizeof(info));

		if (StrEqual(info, "New"))
		{
			if (weaponsGivenThisRound[param1])
				newWeaponsSelected[param1] = true;
			if (gunMenuMode == 1 || gunMenuMode == 2)
			{
				BuildDisplayWeaponMenu(param1, true);
			}
			else if (gunMenuMode == 3)
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
			if (gunMenuMode == 1 || gunMenuMode == 4)
			{
				GiveSavedWeapons(param1, true, true);
			}
			else if (gunMenuMode == 2)
			{
				GiveSavedWeapons(param1, true, false);
			}
			else if (gunMenuMode == 3)
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
			if (gunMenuMode == 1 || gunMenuMode == 4)
			{
				GiveSavedWeapons(param1, true, true);
			}
			else if (gunMenuMode == 2)
			{
				GiveSavedWeapons(param1, true, false);
			}
			else if (gunMenuMode == 3)
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
			if (gunMenuMode == 1 || gunMenuMode == 4)
			{
				primaryWeapon[param1] = "random";
				secondaryWeapon[param1] = "random";
				GiveSavedWeapons(param1, true, true);
			}
			else if (gunMenuMode == 2)
			{
				primaryWeapon[param1] = "random";
				secondaryWeapon[param1] = "none";
				GiveSavedWeapons(param1, true, false);
			}
			else if (gunMenuMode == 3)
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
			if (gunMenuMode == 1 || gunMenuMode == 4)
			{
				primaryWeapon[param1] = "random";
				secondaryWeapon[param1] = "random";
				GiveSavedWeapons(param1, true, true);
			}
			else if (gunMenuMode == 2)
			{
				primaryWeapon[param1] = "random";
				secondaryWeapon[param1] = "none";
				GiveSavedWeapons(param1, true, false);
			}
			else if (gunMenuMode == 3)
			{
				primaryWeapon[param1] = "none";
				secondaryWeapon[param1] = "random";
				GiveSavedWeapons(param1, false, true);
			}
			rememberChoice[param1] = true;
		}
	}
}

public int MenuPrimary(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[24];
		GetMenuItem(menu, param2, info, sizeof(info));
		IncrementWeaponCount(info);
		DecrementWeaponCount(primaryWeapon[param1]);
		primaryWeapon[param1] = info;
		GiveSavedWeapons(param1, true, false);
		if (gunMenuMode != 2) {
			BuildDisplayWeaponMenu(param1, false);
		} else {
			DecrementWeaponCount(secondaryWeapon[param1]);
			secondaryWeapon[param1] = "none";
			GiveSavedWeapons(param1, false, true);
			if (!IsPlayerAlive(param1))
				newWeaponsSelected[param1] = true;
			if (newWeaponsSelected[param1])
				CPrintToChat(param1, "[\x04DM\x01] %t", "Guns New Spawn");
			firstWeaponSelection[param1] = false;
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_Exit)
		{
			DecrementWeaponCount(primaryWeapon[param1]);
			primaryWeapon[param1] = "none";
			GiveSavedWeapons(param1, true, false);
			if (gunMenuMode != 2) {
				BuildDisplayWeaponMenu(param1, false);
			}
		}
	}
}

public int MenuSecondary(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[24];
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
					CPrintToChat(param1, "[\x04DM\x01] %t", "Guns New Spawn");
				firstWeaponSelection[param1] = false;
			}
		}
	}
}

public Action Command_Guns(int client, int args)
{
	if (enabled && (gunMenuMode <= 3))
		DisplayOptionsMenu(client);
	return Plugin_Handled;
}

void GiveSavedWeapons(int client, bool primary, bool secondary)
{
	if (!weaponsGivenThisRound[client] && IsPlayerAlive(client))
	{
		if (primary && !StrEqual(primaryWeapon[client], "none"))
		{
			if (StrEqual(primaryWeapon[client], "random"))
			{
				/* Select random menu item (excluding "Random" option) */
				int random = GetRandomInt(0, GetArraySize(primaryWeaponsAvailable) - 2);
				char randomWeapon[24];
				GetArrayString(primaryWeaponsAvailable, random, randomWeapon, sizeof(randomWeapon));
				GiveSkinnedWeapon(client, randomWeapon);
			}
			else
			{
				GiveSkinnedWeapon(client, primaryWeapon[client]);
			}
		}
		if (secondary)
		{
			if (!StrEqual(secondaryWeapon[client], "none"))
			{
				int entityIndex = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
				if (entityIndex != -1)
				{
					RemovePlayerItem(client, entityIndex);
					AcceptEntityInput(entityIndex, "Kill");
				}
				if (StrEqual(secondaryWeapon[client], "random"))
				{
					/* Select random menu item (excluding "Random" option) */
					int random = GetRandomInt(0, GetArraySize(secondaryWeaponsAvailable) - 2);
					char randomWeapon[24];
					GetArrayString(secondaryWeaponsAvailable, random, randomWeapon, sizeof(randomWeapon));
					GiveSkinnedWeapon(client, randomWeapon);
				}
				else
				{
					GiveSkinnedWeapon(client, secondaryWeapon[client]);
				}
				GivePlayerItem(client, "weapon_knife");
			}
			if (zeus)
				GivePlayerItem(client, "weapon_taser");
			if (incendiary > 0)
			{
				int clientTeam = GetClientTeam(client);
				for (int i = 0; i < incendiary; i++)
				{
					if (clientTeam == CS_TEAM_T)
						GivePlayerItem(client, "weapon_molotov");
					else
						GivePlayerItem(client, "weapon_incgrenade");
				}
			}
			for (int i = 0; i < decoy; i++)
				GivePlayerItem(client, "weapon_decoy");
			for (int i = 0; i < flashbang; i++)
				GivePlayerItem(client, "weapon_flashbang");
			for (int i = 0; i < he; i++)
				GivePlayerItem(client, "weapon_hegrenade");
			for (int i = 0; i < smoke; i++)
				GivePlayerItem(client, "weapon_smokegrenade");
			weaponsGivenThisRound[client] = true;
		}
	}
}

void RemoveClientWeapons(int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		FakeClientCommand(client, "use weapon_knife");
		for (int i = 0; i < 4; i++)
		{
			if (i == 2) continue; /* Keep knife. */
			int entityIndex;
			while ((entityIndex = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, entityIndex);
				AcceptEntityInput(entityIndex, "Kill");
			}
		}
	}
}

public Action RemoveGroundWeapons(Handle timer)
{
	if (enabled && removeWeapons)
	{
		int maxEntities = GetMaxEntities();
		char class[24];

		for (int i = MaxClients + 1; i < maxEntities; i++)
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

void SetBuyZones(const char[] status)
{
	int maxEntities = GetMaxEntities();
	char class[24];

	for (int i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "func_buyzone"))
				AcceptEntityInput(i, status);
		}
	}
}

void SetObjectives(const char[] status)
{
	int maxEntities = GetMaxEntities();
	char class[24];

	for (int i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "func_bomb_target") || StrEqual(class, "func_hostage_rescue"))
				AcceptEntityInput(i, status);
		}
	}
}

void RemoveC4()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (StripC4(i))
			break;
	}
}

bool StripC4(int client)
{
	if (IsClientInGame(client) && (GetClientTeam(client) == CS_TEAM_T) && IsPlayerAlive(client))
	{
		int c4Index = GetPlayerWeaponSlot(client, CS_SLOT_C4);
		if (c4Index != -1)
		{
			char weapon[24];
			GetClientWeapon(client, weapon, sizeof(weapon));
			/* If the player is holding C4, switch to the best weapon before removing it. */
			if (StrEqual(weapon, "weapon_c4"))
			{
				if (GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1)
					ClientCommand(client, "slot1");
				else if (GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != -1)
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

void RemoveHostages()
{
	int maxEntities = GetMaxEntities();
	char class[24];

	for (int i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if (StrEqual(class, "hostage_entity"))
				AcceptEntityInput(i, "Kill");
		}
	}
}

void EnableSpawnProtection(int client)
{
	int clientTeam = GetClientTeam(client);
	/* Disable damage */
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	/* Set player color */
	if (clientTeam == CS_TEAM_T)
		SetPlayerColor(client, tColor);
	else if (clientTeam == CS_TEAM_CT)
		SetPlayerColor(client, ctColor);
	/* Create timer to remove spawn protection */
	CreateTimer(spawnProtectionTime, DisableSpawnProtection, client);
}

public Action DisableSpawnProtection(Handle timer, any client)
{
	if (IsValidClient(client) && (GetClientTeam(client) != CS_TEAM_SPECTATOR) && IsPlayerAlive(client))
	{
		/* Enable damage */
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		/* Set player color */
		SetPlayerColor(client, defaultColor);
	}
}

void SetPlayerColor(int client, const int color[4])
{
	SetEntityRenderMode(client, (color[3] == 255) ? RENDER_NORMAL : RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
}

public Action Command_RespawnAll(int client, int args)
{
	RespawnAll();
	return Plugin_Handled;
}

Handle BuildSpawnEditorMenu()
{
	Menu menu = CreateMenu(MenuSpawnEditor);
	menu.SetTitle("Spawn Point Editor:");
	menu.ExitButton = true
	char editModeItem[24];
	Format(editModeItem, sizeof(editModeItem), "%s Edit Mode", (!inEditMode) ? "Enable" : "Disable");
	menu.AddItem("Edit", editModeItem);
	menu.AddItem("Nearest", "Teleport to nearest");
	menu.AddItem("Previous", "Teleport to previous");
	menu.AddItem("Next", "Teleport to next");
	menu.AddItem("Add", "Add position");
	menu.AddItem("Insert", "Insert position here");
	menu.AddItem("Delete", "Delete nearest");
	menu.AddItem("Delete All", "Delete all");
	menu.AddItem("Save", "Save Configuration");
	return menu;
}

public Action Command_SpawnMenu(int client, int args)
{
	DisplayMenu(BuildSpawnEditorMenu(), client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int MenuSpawnEditor(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[24];
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
			int spawnPoint = GetNearestSpawn(param1);
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
				int spawnPoint = lastEditorSpawnPoint[param1] - 1;
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
				int spawnPoint = lastEditorSpawnPoint[param1] + 1;
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
			int spawnPoint = GetNearestSpawn(param1);
			if (spawnPoint != -1)
			{
				DeleteSpawn(spawnPoint);
				CPrintToChat(param1, "[\x04DM\x01] %t #%i (%i total).", "Spawn Editor Deleted Spawn", spawnPoint + 1, spawnPointCount);
			}
		}
		else if (StrEqual(info, "Delete All"))
		{
			Handle panel = CreatePanel();
			SetPanelTitle(panel, "Delete all spawn points?");
			DrawPanelItem(panel, "Yes");
			DrawPanelItem(panel, "No");
			SendPanelToClient(panel, param1, PanelConfirmDeleteAllSpawns, MENU_TIME_FOREVER);
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

public int PanelConfirmDeleteAllSpawns(Menu menu, MenuAction action, int param1, int param2)
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

public Action RenderSpawnPoints(Handle timer)
{
	if (!inEditMode)
		return Plugin_Stop;

	for (int i = 0; i < spawnPointCount; i++)
	{
		float spawnPosition[3];
		AddVectors(spawnPositions[i], spawnPointOffset, spawnPosition);
		TE_SetupGlowSprite(spawnPosition, glowSprite, 1.0, 0.5, 255);
		TE_SendToAll();
	}
	return Plugin_Continue;
}

int GetNearestSpawn(int client)
{
	if (spawnPointCount == 0)
	{
		CPrintToChat(client, "[\x04DM\x01] %t", "Spawn Editor No Spawn");
		return -1;
	}

	float clientPosition[3];
	GetClientAbsOrigin(client, clientPosition);

	int nearestPoint = 0;
	float nearestPointDistance = GetVectorDistance(spawnPositions[0], clientPosition, true);

	for (int i = 1; i < spawnPointCount; i++)
	{
		float distance = GetVectorDistance(spawnPositions[i], clientPosition, true);
		if (distance < nearestPointDistance)
		{
			nearestPoint = i;
			nearestPointDistance = distance;
		}
	}
	return nearestPoint;
}

void AddSpawn(int client)
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

void InsertSpawn(int client)
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
		/* Move spawn points down the list to make room for insertion. */
		for (int i = spawnPointCount - 1; i >= lastEditorSpawnPoint[client]; i--)
		{
			spawnPositions[i + 1] = spawnPositions[i];
			spawnAngles[i + 1] = spawnAngles[i];
		}
		/* Insert new spawn point. */
		GetClientAbsOrigin(client, spawnPositions[lastEditorSpawnPoint[client]]);
		GetClientAbsAngles(client, spawnAngles[lastEditorSpawnPoint[client]]);
		spawnPointCount++;
		CPrintToChat(client, "[\x04DM\x01] %t #%i (%i total).", "Spawn Editor Spawn Inserted", lastEditorSpawnPoint[client] + 1, spawnPointCount);
	}
}

void DeleteSpawn(int spawnIndex)
{
	for (int i = spawnIndex; i < (spawnPointCount - 1); i++)
	{
		spawnPositions[i] = spawnPositions[i + 1];
		spawnAngles[i] = spawnAngles[i + 1];
	}
	spawnPointCount--;
}

/* Updates the occupation status of all spawn points. */
public Action UpdateSpawnPointStatus(Handle timer)
{
	if (enabled && (spawnPointCount > 0))
	{
		/* Retrieve player positions. */
		float playerPositions[MAXPLAYERS+1][3];
		int numberOfAlivePlayers = 0;

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && (GetClientTeam(i) != CS_TEAM_SPECTATOR) && IsPlayerAlive(i))
			{
				GetClientAbsOrigin(i, playerPositions[numberOfAlivePlayers]);
				numberOfAlivePlayers++;
			}
		}

		/* Check each spawn point for occupation by proximity to alive players */
		for (int i = 0; i < spawnPointCount; i++)
		{
			spawnPointOccupied[i] = false;
			for (int j = 0; j < numberOfAlivePlayers; j++)
			{
				float distance = GetVectorDistance(spawnPositions[i], playerPositions[j], true);
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

void MovePlayer(int client)
{
	numberOfPlayerSpawns++; /* Stats */

	int clientTeam = GetClientTeam(client);

	int spawnPoint;
	bool spawnPointFound = false;

	float enemyEyePositions[MAXPLAYERS+1][3];
	int numberOfEnemies = 0;

	/* Retrieve enemy positions if required by LoS/distance spawning (at eye level for LoS checking). */
	if (lineOfSightSpawning || (spawnDistanceFromEnemies > 0.0))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && (GetClientTeam(i) != CS_TEAM_SPECTATOR) && IsPlayerAlive(i))
			{
				bool enemy = (ffa || (GetClientTeam(i) != clientTeam));
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
		losSearchAttempts++; /* Stats */

		/* Try to find a suitable spawn point with a clear line of sight. */
		for (int i = 0; i < lineOfSightAttempts; i++)
		{
			spawnPoint = GetRandomInt(0, spawnPointCount - 1);

			if (spawnPointOccupied[spawnPoint])
				continue;

			if (spawnDistanceFromEnemies > 0.0)
			{
				if (!IsPointSuitableDistance(spawnPoint, enemyEyePositions, numberOfEnemies))
					continue;
			}

			float spawnPointEyePosition[3];
			AddVectors(spawnPositions[spawnPoint], eyeOffset, spawnPointEyePosition);

			bool hasClearLineOfSight = true;

			for (int j = 0; j < numberOfEnemies; j++)
			{
				Handle trace = TR_TraceRayFilterEx(spawnPointEyePosition, enemyEyePositions[j], MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilterPlayer);
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
		/* Stats */
		if (spawnPointFound)
			losSearchSuccesses++;
		else
			losSearchFailures++;
	}

	/* First fallback. Find a random unccupied spawn point at a suitable distance. */
	if (!spawnPointFound && (spawnDistanceFromEnemies > 0.0))
	{
		distanceSearchAttempts++; /* Stats */

		for (int i = 0; i < 100; i++)
		{
			spawnPoint = GetRandomInt(0, spawnPointCount - 1);
			if (spawnPointOccupied[spawnPoint])
				continue;

			if (!IsPointSuitableDistance(spawnPoint, enemyEyePositions, numberOfEnemies))
				continue;

			spawnPointFound = true;
			break;
		}
		/* Stats */
		if (spawnPointFound)
			distanceSearchSuccesses++;
		else
			distanceSearchFailures++;
	}

	/* Final fallback. Find a random unoccupied spawn point. */
	if (!spawnPointFound)
	{
		for (int i = 0; i < 100; i++)
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

	if (!spawnPointFound) spawnPointSearchFailures++; /* Stats */
}

bool IsPointSuitableDistance(int spawnPoint, float[][3] enemyEyePositions, int numberOfEnemies)
{
	for (int i = 0; i < numberOfEnemies; i++)
	{
		float distance = GetVectorDistance(spawnPositions[spawnPoint], enemyEyePositions[i], true);
		if (distance < spawnDistanceFromEnemies)
			return false;
	}
	return true;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	if ((entity > 0) && (entity <= MaxClients)) return false;
	return true;
}

public Action Command_Stats(int client, int args)
{
	DisplaySpawnStats(client);
	return Plugin_Handled;
}

public Action Command_ResetStats(int client, int args)
{
	ResetSpawnStats();
	CPrintToChat(client, "[\x04DM\x01] Spawn statistics have been reset.");
	return Plugin_Handled;
}

void ResetSpawnStats()
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

void DisplaySpawnStats(int client)
{
	char text[64];
	Handle panel = CreatePanel();
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
	SendPanelToClient(panel, client, PanelSpawnStats, MENU_TIME_FOREVER);
	CloseHandle(panel);
}

public int PanelSpawnStats(Menu menu, MenuAction action, int param1, int param2) { }

public Action Event_Sound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if (enabled)
	{
		if (spawnPointCount > 0)
		{
			int client;
			if ((entity > 0) && (entity <= MaxClients))
				client = entity;
			else
				client = GetEntDataEnt2(entity, ownerOffset);

			/* Block ammo pickup sounds. */
			if (StrContains(sample, "pickup") != -1)
				return Plugin_Stop;

			/* Block all sounds originating from players not yet moved. */
			if ((client > 0) && (client <= MaxClients) && !playerMoved[client])
				return Plugin_Stop;
		}
		if (ffa)
		{
			if (StrContains(sample, "friendlyfire") != -1)
				return Plugin_Stop;
		}
		if (!hsSounds)
		{
			if (StrContains(sample, "physics/flesh/flesh_bloody") != -1 || StrContains(sample, "player/bhit_helmet") != -1 || StrContains(sample, "player/headshot") != -1)
				return Plugin_Stop;
		}
		if (!bdSounds)
		{
			if (StrContains(sample, "physics/body") != -1 || StrContains(sample, "physics/flesh") != -1 || StrContains(sample, "player/kevlar") != -1)
				return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	if (enabled && respawning && !valveDM)
	{
		if ((reason == CSRoundEnd_CTWin) || (reason == CSRoundEnd_TerroristWin))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

void BuildDisplayWeaponMenu(int client, bool primary)
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

	Menu menu;
	if (primary)
	{
		menu = CreateMenu(MenuPrimary);
		menu.SetTitle("Primary Weapon:");
	}
	else
	{
		menu = CreateMenu(MenuSecondary);
		menu.SetTitle("Secondary Weapon:");
	}

	Handle weapons = (primary) ? primaryWeaponsAvailable : secondaryWeaponsAvailable;

	char currentWeapon[24];
	currentWeapon = (primary) ? primaryWeapon[client] : secondaryWeapon[client];

	for (int i = 0; i < GetArraySize(weapons); i++)
	{
		char weapon[24];
		GetArrayString(weapons, i, weapon, sizeof(weapon));

		char weaponMenuName[24];
		GetTrieString(weaponMenuNames, weapon, weaponMenuName, sizeof(weaponMenuName));

		int weaponCount;
		GetTrieValue(weaponCounts, weapon, weaponCount);

		int weaponLimit;
		GetTrieValue(weaponLimits, weapon, weaponLimit);

		/* If the client already has the weapon, then the limit does not apply. */
		if (StrEqual(currentWeapon, weapon))
		{
			menu.AddItem(weapon, weaponMenuName);
		}
		else
		{
			if ((weaponLimit == -1) || (weaponCount < weaponLimit))
			{
				menu.AddItem(weapon, weaponMenuName);
			}
			else
			{
				char text[64];
				Format(text, sizeof(text), "%s (Limited)", weaponMenuName);
				menu.AddItem(weapon, text, ITEMDRAW_DISABLED);
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

void IncrementWeaponCount(char[] weapon)
{
	int weaponCount;
	GetTrieValue(weaponCounts, weapon, weaponCount);
	SetTrieValue(weaponCounts, weapon, weaponCount + 1);
}

void DecrementWeaponCount(char[] weapon)
{
	if (!StrEqual(weapon, "none"))
	{
		int weaponCount;
		GetTrieValue(weaponCounts, weapon, weaponCount);
		SetTrieValue(weaponCounts, weapon, weaponCount - 1);
	}
}

public Action Event_TextMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (ffa)
	{
		char text[64];
		if (GetUserMessageType() == UM_Protobuf)
			PbReadString(msg, "params", text, sizeof(text), 0);
		else
			BfReadString(msg, text, sizeof(text));

		if (StrContains(text, "#SFUI_Notice_Killed_Teammate") != -1)
			return Plugin_Handled;

		if (StrContains(text, "#Cstrike_TitlesTXT_Game_teammate_attack") != -1)
			return Plugin_Handled;

		if (StrContains(text, "#Hint_try_not_to_injure_teammates") != -1)
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Event_HintText(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (ffa)
	{
		char text[64];
		if (GetUserMessageType() == UM_Protobuf)
			PbReadString(msg, "text", text, sizeof(text));
		else
			BfReadString(msg, text, sizeof(text));

		if (StrContains(text, "#SFUI_Notice_Hint_careful_around_teammates") != -1)
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Event_RadioText(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	static char grenadeTriggers[][] = {
		"#SFUI_TitlesTXT_Fire_in_the_hole",
		"#SFUI_TitlesTXT_Flashbang_in_the_hole",
		"#SFUI_TitlesTXT_Smoke_in_the_hole",
		"#SFUI_TitlesTXT_Decoy_in_the_hole",
		"#SFUI_TitlesTXT_Molotov_in_the_hole",
		"#SFUI_TitlesTXT_Incendiary_in_the_hole"
	};

	if (!displayGrenadeMessages)
	{
		char text[64];
		if (GetUserMessageType() == UM_Protobuf)
		{
			PbReadString(msg, "msg_name", text, sizeof(text));
			/* 0: name */
			/* 1: msg_name == #Game_radio_location ? location : translation phrase */
			/* 2: if msg_name == #Game_radio_location : translation phrase */
			if (StrContains(text, "#Game_radio_location") != -1)
				PbReadString(msg, "params", text, sizeof(text), 2);
			else
				PbReadString(msg, "params", text, sizeof(text), 1);
		}
		else
		{
			BfReadString(msg, text, sizeof(text));
			if (StrContains(text, "#Game_radio_location") != -1)
				BfReadString(msg, text, sizeof(text));
			BfReadString(msg, text, sizeof(text));
			BfReadString(msg, text, sizeof(text));
	}

		for (int i = 0; i < sizeof(grenadeTriggers); i++)
		{
			if (StrEqual(text, grenadeTriggers[i]))
				return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

void RemoveRagdoll(int client)
{
	if (IsValidEdict(client))
	{
		int ragdoll = GetEntDataEnt2(client, ragdollOffset);
		if (ragdoll != -1)
			AcceptEntityInput(ragdoll, "Kill");
	}
}

public int GetWeaponTeam(const char[] weapon)
{
	int team = 0;
	weaponSkipMap.GetValue(weapon, team);
	return team;
}

public void GiveSkinnedWeapon(int client, const char[] weapon)
{
	int playerTeam = GetEntProp(client, Prop_Data, "m_iTeamNum");
	int weaponTeam = GetWeaponTeam(weapon);
	if (weaponTeam > 0) {
		SetEntProp(client, Prop_Data, "m_iTeamNum", weaponTeam);
	}

	GivePlayerItem(client, weapon);
	SetEntProp(client, Prop_Data, "m_iTeamNum", playerTeam)
}

