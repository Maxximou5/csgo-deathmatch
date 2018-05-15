#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <csgocolors>
#include <cstrike>
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required

#define PLUGIN_VERSION          "2.0.8"
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
Handle g_hMP_ct_default_primary;
Handle g_hMP_t_default_primary;
Handle g_hMP_ct_default_secondary;
Handle g_hMP_t_default_secondary;
Handle g_hMP_startmoney;
Handle g_hMP_playercashawards;
Handle g_hMP_teamcashawards;
Handle g_hMP_friendlyfire;
Handle g_hMP_autokick;
Handle g_hMP_tkpunish;
Handle g_hMP_teammates_are_enemies;
Handle g_hFF_damage_reduction_bullets;
Handle g_hFF_damage_reduction_grenade;
Handle g_hFF_damage_reduction_other;
Handle g_hAmmo_grenade_limit_default;
Handle g_hAmmo_grenade_limit_flashbang;
Handle g_hAmmo_grenade_limit_total;

/* Native Backup Variables */
int g_iBackup_mp_startmoney;
int g_iBackup_mp_playercashawards;
int g_iBackup_mp_teamcashawards;
int g_iBackup_mp_friendlyfire;
int g_iBackup_mp_autokick;
int g_iBackup_mp_tkpunish;
int g_iBackup_mp_teammates_are_enemies;
int g_iBackup_ammo_grenade_limit_default;
int g_iBackup_ammo_grenade_limit_flashbang;
int g_iBackup_ammo_grenade_limit_total;
float g_fBackup_ff_damage_reduction_bullets;
float g_fBackup_ff_damage_reduction_grenade;
float g_fBackup_ff_damage_reduction_other;

/* Baked Cookies */
Handle g_hWeapon_Primary_Cookie;
Handle g_hWeapon_Secondary_Cookie;
Handle g_hWeapon_Remember_Cookie;
Handle g_hWeapon_First_Cookie;

/* Console variables */
ConVar g_cvDM_enabled;
ConVar g_cvDM_valvedm;
ConVar g_cvDM_welcomemsg;
ConVar g_cvDM_free_for_all;
ConVar g_cvDM_hide_radar;
ConVar g_cvDM_display_panel;
ConVar g_cvDM_display_panel_damage;
ConVar g_cvDM_sounds_bodyshots;
ConVar g_cvDM_sounds_headshots;
ConVar g_cvDM_headshot_only;
ConVar g_cvDM_headshot_only_allow_client;
ConVar g_cvDM_headshot_only_allow_world;
ConVar g_cvDM_headshot_only_allow_knife;
ConVar g_cvDM_headshot_only_allow_taser;
ConVar g_cvDM_headshot_only_allow_nade;
ConVar g_cvDM_remove_objectives;
ConVar g_cvDM_respawning;
ConVar g_cvDM_respawn_time;
ConVar g_cvDM_gun_menu_mode;
ConVar g_cvDM_los_spawning;
ConVar g_cvDM_los_attempts;
ConVar g_cvDM_spawn_distance;
ConVar g_cvDM_spawn_time;
ConVar g_cvDM_no_knife_damage;
ConVar g_cvDM_remove_weapons;
ConVar g_cvDM_replenish_ammo;
ConVar g_cvDM_replenish_ammo_clip;
ConVar g_cvDM_replenish_ammo_reserve;
ConVar g_cvDM_replenish_grenade;
ConVar g_cvDM_replenish_hegrenade;
ConVar g_cvDM_replenish_grenade_kill;
ConVar g_cvDM_hp_start;
ConVar g_cvDM_hp_max;
ConVar g_cvDM_hp_kill;
ConVar g_cvDM_hp_headshot;
ConVar g_cvDM_hp_knife;
ConVar g_cvDM_hp_nade;
ConVar g_cvDM_hp_messages;
ConVar g_cvDM_ap_max;
ConVar g_cvDM_ap_kill;
ConVar g_cvDM_ap_headshot;
ConVar g_cvDM_ap_knife;
ConVar g_cvDM_ap_nade;
ConVar g_cvDM_ap_messages;
ConVar g_cvDM_nade_messages;
ConVar g_cvDM_cash_messages;
ConVar g_cvDM_armor;
ConVar g_cvDM_armor_full;
ConVar g_cvDM_zeus;
ConVar g_cvDM_nades_incendiary;
ConVar g_cvDM_nades_molotov;
ConVar g_cvDM_nades_decoy;
ConVar g_cvDM_nades_flashbang;
ConVar g_cvDM_nades_he;
ConVar g_cvDM_nades_smoke;
ConVar g_cvDM_nades_tactical;

/* Plugin Variables */
bool g_bHSOnlyClient[MAXPLAYERS + 1];
bool g_bRoundEnded = false;

/* Player Color Variables */
int g_iDefaultColor[4] = { 255, 255, 255, 255 };
int g_iColorT[4] = { 255, 0, 0, 200 };
int g_iColorCT[4] = { 0, 0, 255, 200 };

/* Respawn Variables */
int g_iSpawnPointCount = 0;
bool g_bInEditMode = false;
bool g_bSpawnPointOccupied[MAX_SPAWNS] = {false, ...};
float g_fSpawnPositions[MAX_SPAWNS][3];
float g_fSpawnAngles[MAX_SPAWNS][3];
float g_fEyeOffset[3] = { 0.0, 0.0, 64.0 }; /* CSGO offset. */
float g_fSpawnPointOffset[3] = { 0.0, 0.0, 20.0 };

/* Offsets */
int g_iOwnerOffset;
int g_iHealthOffset;
int g_iArmorOffset;
int g_iHelmetOffset;
int g_iAmmoTypeOffset;
int g_iAmmoOffset;
int g_iRagdollOffset;

/* Weapon Info */
Handle g_hPrimaryWeaponsAvailable;
Handle g_hSecondaryWeaponsAvailable;
Handle g_hWeaponMenuNames;
Handle g_hWeaponLimits;
Handle g_hWeaponCounts;
StringMap g_smWeaponTeams;

/* Menus */
Handle g_hPrimaryMenus[MAXPLAYERS + 1];
Handle g_hSecondaryMenus[MAXPLAYERS + 1];
Handle g_hDamageDisplay[MAXPLAYERS+1];

/* Player settings */
int g_iLastEditorSpawnPoint[MAXPLAYERS + 1] = { -1, ... };
char g_cPrimaryWeapon[MAXPLAYERS + 1][24];
char g_cSecondaryWeapon[MAXPLAYERS + 1][24];
int g_iInfoMessageCount[MAXPLAYERS + 1] = { 2, ... };
bool g_bFirstWeaponSelection[MAXPLAYERS + 1] = { true, ... };
bool g_bWeaponsGivenThisRound[MAXPLAYERS + 1] = { false, ... };
bool g_bRememberChoice[MAXPLAYERS + 1] = { false, ... };
bool g_bPlayerMoved[MAXPLAYERS + 1] = { false, ... };

/* Player Glow Sprite */
int g_iGlowSprite;

/* Spawn stats */
int g_iNumberOfPlayerSpawns = 0;
int g_iLosSearchAttempts = 0;
int g_iLosSearchSuccesses = 0;
int g_iLosSearchFailures = 0;
int g_iDistanceSearchAttempts = 0;
int g_iDistanceSearchSuccesses = 0;
int g_iDistanceSearchFailures = 0;
int g_iSpawnPointSearchFailures = 0;

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
    g_iOwnerOffset = FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity");
    g_iHealthOffset = FindSendPropInfo("CCSPlayerResource", "m_iHealth");
    g_iArmorOffset = FindSendPropInfo("CCSPlayer", "m_ArmorValue");
    g_iHelmetOffset = FindSendPropInfo("CCSPlayer", "m_bHasHelmet");
    g_iAmmoTypeOffset = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");
    g_iAmmoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
    g_iRagdollOffset = FindSendPropInfo("CCSPlayer", "m_hRagdoll");

    /* Create arrays to store available weapons loaded by config */
    g_hPrimaryWeaponsAvailable = CreateArray(24);
    g_hSecondaryWeaponsAvailable = CreateArray(10);
    g_smWeaponTeams = new StringMap();

    /* Create trie to store menu names for weapons */
    BuildWeaponMenuNames();

    /* Create trie to store weapon limits and counts */
    g_hWeaponLimits = CreateTrie();
    g_hWeaponCounts = CreateTrie();

    /* Create Console Variables */
    CreateConVar("dm_m5_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
    g_cvDM_enabled = CreateConVar("dm_enabled", "1", "Enable Deathmatch.");
    g_cvDM_valvedm = CreateConVar("dm_enable_valve_deathmatch", "0", "Enable compatibility for Valve's Deathmatch (game_type 1 & game_mode 2) or Custom (game_type 3 & game_mode 0).");
    g_cvDM_welcomemsg = CreateConVar("dm_welcomemsg", "1", "Display a message saying that your server is running Deathmatch.");
    g_cvDM_free_for_all = CreateConVar("dm_free_for_all", "0", "Free for all mode.");
    g_cvDM_hide_radar = CreateConVar("dm_hide_radar", "0", "Hides the radar from players.");
    g_cvDM_display_panel = CreateConVar("dm_display_panel", "0", "Display a panel showing health of the victim.");
    g_cvDM_display_panel_damage = CreateConVar("dm_display_panel_damage", "0", "Display a panel showing damage done to a player. Requires dm_display_panel set to 1.");
    g_cvDM_sounds_bodyshots = CreateConVar("dm_sounds_bodyshots", "1", "Enable the sounds of bodyshots.");
    g_cvDM_sounds_headshots = CreateConVar("dm_sounds_headshots", "1", "Enable the sounds of headshots.");
    g_cvDM_headshot_only = CreateConVar("dm_headshot_only", "0", "Headshot only mode.");
    g_cvDM_headshot_only_allow_client = CreateConVar("dm_headshot_only_allow_client", "1", "Enable clients to have their own personal headshot only mode.");
    g_cvDM_headshot_only_allow_world = CreateConVar("dm_headshot_only_allow_world", "0", "Enable world damage during headshot only mode.");
    g_cvDM_headshot_only_allow_knife = CreateConVar("dm_headshot_only_allow_knife", "0", "Enable knife damage during headshot only mode.");
    g_cvDM_headshot_only_allow_taser = CreateConVar("dm_headshot_only_allow_taser", "0", "Enable taser damage during headshot only mode.");
    g_cvDM_headshot_only_allow_nade = CreateConVar("dm_headshot_only_allow_nade", "0", "Enable grenade damage during headshot only mode.");
    g_cvDM_remove_objectives = CreateConVar("dm_remove_objectives", "1", "Remove objectives (disables bomb sites, and removes c4 and hostages).");
    g_cvDM_respawning = CreateConVar("dm_respawning", "1", "Enable respawning.");
    g_cvDM_respawn_time = CreateConVar("dm_respawn_time", "2.0", "Respawn time.");
    g_cvDM_gun_menu_mode = CreateConVar("dm_gun_menu_mode", "1", "Gun menu mode. 1) Enabled. 2) Primary weapons only. 3) Secondary weapons only. 4) Random weapons only. 5) Disabled.");
    g_cvDM_los_spawning = CreateConVar("dm_los_spawning", "1", "Enable line of sight spawning. If enabled, players will be spawned at a point where they cannot see enemies, and enemies cannot see them.");
    g_cvDM_los_attempts = CreateConVar("dm_los_attempts", "10", "Maximum number of attempts to find a suitable line of sight spawn point.");
    g_cvDM_spawn_distance = CreateConVar("dm_spawn_distance", "0.0", "Minimum distance from enemies at which a player can spawn.");
    g_cvDM_spawn_time = CreateConVar("dm_spawn_time", "1.0", "Spawn protection time.");
    g_cvDM_no_knife_damage = CreateConVar("dm_no_knife_damage", "0", "Knives do NO damage to players.");
    g_cvDM_remove_weapons = CreateConVar("dm_remove_weapons", "1", "Remove ground weapons.");
    g_cvDM_replenish_ammo = CreateConVar("dm_replenish_ammo", "1", "Replenish ammo on reload.");
    g_cvDM_replenish_ammo_clip = CreateConVar("dm_replenish_ammo_clip", "0", "Replenish ammo clip on kill.");
    g_cvDM_replenish_ammo_reserve = CreateConVar("dm_replenish_ammo_reserve", "0", "Replenish ammo reserve on kill.");
    g_cvDM_replenish_grenade = CreateConVar("dm_replenish_grenade", "0", "Unlimited player grenades.");
    g_cvDM_replenish_hegrenade = CreateConVar("dm_replenish_hegrenade", "0", "Unlimited hegrenades.");
    g_cvDM_replenish_grenade_kill = CreateConVar("dm_replenish_grenade_kill", "0", "Give players their grenade back on successful kill.");
    g_cvDM_nade_messages = CreateConVar("dm_nade_messages", "1", "Disable grenade messages.");
    g_cvDM_cash_messages = CreateConVar("dm_cash_messages", "1", "Disable cash award messages.");
    g_cvDM_hp_start = CreateConVar("dm_hp_start", "100", "Spawn Health Points (HP).");
    g_cvDM_hp_max = CreateConVar("dm_hp_max", "100", "Maximum Health Points (HP).");
    g_cvDM_hp_kill = CreateConVar("dm_hp_kill", "5", "Health Points (HP) per kill.");
    g_cvDM_hp_headshot = CreateConVar("dm_hp_headshot", "10", "Health Points (HP) per headshot kill.");
    g_cvDM_hp_knife = CreateConVar("dm_hp_knife", "50", "Health Points (HP) per knife kill.");
    g_cvDM_hp_nade = CreateConVar("dm_hp_nade", "30", "Health Points (HP) per nade kill.");
    g_cvDM_hp_messages = CreateConVar("dm_hp_messages", "1", "Display HP messages.");
    g_cvDM_ap_max = CreateConVar("dm_ap_max", "100", "Maximum Armor Points (AP).");
    g_cvDM_ap_kill = CreateConVar("dm_ap_kill", "5", "Armor Points (AP) per kill.");
    g_cvDM_ap_headshot = CreateConVar("dm_ap_headshot", "10", "Armor Points (AP) per headshot kill.");
    g_cvDM_ap_knife = CreateConVar("dm_ap_knife", "50", "Armor Points (AP) per knife kill.");
    g_cvDM_ap_nade = CreateConVar("dm_ap_nade", "30", "Armor Points (AP) per nade kill.");
    g_cvDM_ap_messages = CreateConVar("dm_ap_messages", "1", "Display AP messages.");
    g_cvDM_armor = CreateConVar("dm_armor", "0", "Give players chest armor.");
    g_cvDM_armor_full = CreateConVar("dm_armor_full", "1", "Give players head and chest armor.");
    g_cvDM_zeus = CreateConVar("dm_zeus", "0", "Give players a taser.");
    g_cvDM_nades_incendiary = CreateConVar("dm_nades_incendiary", "0", "Number of incendiary grenades to give each player.");
    g_cvDM_nades_molotov = CreateConVar("dm_nades_molotov", "0", "Number of molotov grenades to give each player.");
    g_cvDM_nades_decoy = CreateConVar("dm_nades_decoy", "0", "Number of decoy grenades to give each player.");
    g_cvDM_nades_flashbang = CreateConVar("dm_nades_flashbang", "0", "Number of flashbang grenades to give each player.");
    g_cvDM_nades_he = CreateConVar("dm_nades_he", "0", "Number of HE grenades to give each player.");
    g_cvDM_nades_smoke = CreateConVar("dm_nades_smoke", "0", "Number of smoke grenades to give each player.");
    g_cvDM_nades_tactical = CreateConVar("dm_nades_tactical", "0", "Number of tactical grenades to give each player.");

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
    HookConVarChange(g_cvDM_enabled, Event_CvarChange);
    HookConVarChange(g_cvDM_valvedm, Event_CvarChange);
    HookConVarChange(g_cvDM_welcomemsg, Event_CvarChange);
    HookConVarChange(g_cvDM_free_for_all, Event_CvarChange);
    HookConVarChange(g_cvDM_hide_radar, Event_CvarChange);
    HookConVarChange(g_cvDM_display_panel, Event_CvarChange);
    HookConVarChange(g_cvDM_display_panel_damage, Event_CvarChange);
    HookConVarChange(g_cvDM_sounds_bodyshots, Event_CvarChange);
    HookConVarChange(g_cvDM_sounds_headshots, Event_CvarChange);
    HookConVarChange(g_cvDM_headshot_only, Event_CvarChange);
    HookConVarChange(g_cvDM_headshot_only_allow_client, Event_CvarChange);
    HookConVarChange(g_cvDM_headshot_only_allow_world, Event_CvarChange);
    HookConVarChange(g_cvDM_headshot_only_allow_knife, Event_CvarChange);
    HookConVarChange(g_cvDM_headshot_only_allow_taser, Event_CvarChange);
    HookConVarChange(g_cvDM_headshot_only_allow_nade, Event_CvarChange);
    HookConVarChange(g_cvDM_remove_objectives, Event_CvarChange);
    HookConVarChange(g_cvDM_respawning, Event_CvarChange);
    HookConVarChange(g_cvDM_respawn_time, Event_CvarChange);
    HookConVarChange(g_cvDM_gun_menu_mode, Event_CvarChange);
    HookConVarChange(g_cvDM_los_spawning, Event_CvarChange);
    HookConVarChange(g_cvDM_los_attempts, Event_CvarChange);
    HookConVarChange(g_cvDM_spawn_distance, Event_CvarChange);
    HookConVarChange(g_cvDM_spawn_time, Event_CvarChange);
    HookConVarChange(g_cvDM_no_knife_damage, Event_CvarChange);
    HookConVarChange(g_cvDM_remove_weapons, Event_CvarChange);
    HookConVarChange(g_cvDM_replenish_ammo, Event_CvarChange);
    HookConVarChange(g_cvDM_replenish_ammo_clip, Event_CvarChange);
    HookConVarChange(g_cvDM_replenish_ammo_reserve, Event_CvarChange);
    HookConVarChange(g_cvDM_replenish_grenade, Event_CvarChange);
    HookConVarChange(g_cvDM_replenish_hegrenade, Event_CvarChange);
    HookConVarChange(g_cvDM_replenish_grenade_kill, Event_CvarChange);
    HookConVarChange(g_cvDM_hp_start, Event_CvarChange);
    HookConVarChange(g_cvDM_hp_max, Event_CvarChange);
    HookConVarChange(g_cvDM_hp_kill, Event_CvarChange);
    HookConVarChange(g_cvDM_hp_headshot, Event_CvarChange);
    HookConVarChange(g_cvDM_hp_knife, Event_CvarChange);
    HookConVarChange(g_cvDM_hp_nade, Event_CvarChange);
    HookConVarChange(g_cvDM_hp_messages, Event_CvarChange);
    HookConVarChange(g_cvDM_ap_max, Event_CvarChange);
    HookConVarChange(g_cvDM_ap_kill, Event_CvarChange);
    HookConVarChange(g_cvDM_ap_headshot, Event_CvarChange);
    HookConVarChange(g_cvDM_ap_knife, Event_CvarChange);
    HookConVarChange(g_cvDM_ap_nade, Event_CvarChange);
    HookConVarChange(g_cvDM_ap_messages, Event_CvarChange);
    HookConVarChange(g_cvDM_nade_messages, Event_CvarChange);
    HookConVarChange(g_cvDM_cash_messages, Event_CvarChange);
    HookConVarChange(g_cvDM_armor, Event_CvarChange);
    HookConVarChange(g_cvDM_armor_full, Event_CvarChange);
    HookConVarChange(g_cvDM_zeus, Event_CvarChange);
    HookConVarChange(g_cvDM_nades_incendiary, Event_CvarChange);
    HookConVarChange(g_cvDM_nades_molotov, Event_CvarChange);
    HookConVarChange(g_cvDM_nades_decoy, Event_CvarChange);
    HookConVarChange(g_cvDM_nades_flashbang, Event_CvarChange);
    HookConVarChange(g_cvDM_nades_he, Event_CvarChange);
    HookConVarChange(g_cvDM_nades_smoke, Event_CvarChange);
    HookConVarChange(g_cvDM_nades_tactical, Event_CvarChange);

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
    HookEvent("weapon_fire_on_empty", Event_WeaponFireOnEmpty, EventHookMode_Post);
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

    /* Baked Cookies */
    g_hWeapon_Primary_Cookie = RegClientCookie("dm_weapon_primary", "Primary Weapon Selection", CookieAccess_Protected);
    g_hWeapon_Secondary_Cookie = RegClientCookie("dm_weapon_secondary", "Secondary Weapon Selection", CookieAccess_Protected);
    g_hWeapon_Remember_Cookie = RegClientCookie("dm_weapon_remember", "Remember Weapon Selection", CookieAccess_Protected);
    g_hWeapon_First_Cookie = RegClientCookie("dm_weapon_first", "First Weapon Selection", CookieAccess_Protected);

    /* Late Load Cookies */
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i) && IsValidClient(i) && !IsFakeClient(i))
        {
            OnClientCookiesCached(i);
        }
    }

    /* Find Offsets */
    g_iWeapons_Clip1Offset = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");

    if (g_iWeapons_Clip1Offset == -1)
    {
        SetFailState("[DM] Error - Unable to get offset for CBaseCombatWeapon::m_iClip1");
    }

    g_iHealthOffset = FindSendPropInfo("CCSPlayer", "m_iHealth");

    if (g_iHealthOffset == -1)
    {
        SetFailState("[DM] Error - Unable to get offset for CCSPlayer::m_iHealth");
    }

    g_iArmorOffset = FindSendPropInfo("CCSPlayer", "m_ArmorValue");

    if (g_iArmorOffset == -1)
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

public void OnClientCookiesCached(int client)
{
    char cPrimary[24];
    char cSecondary[24];
    char cRemember[24];
    char cFirst[24];
    GetClientCookie(client, g_hWeapon_Primary_Cookie, cPrimary, sizeof(cPrimary));
    GetClientCookie(client, g_hWeapon_Secondary_Cookie, cSecondary, sizeof(cSecondary));
    GetClientCookie(client, g_hWeapon_Remember_Cookie, cRemember, sizeof(cRemember));
    GetClientCookie(client, g_hWeapon_First_Cookie, cFirst, sizeof(cFirst));
    if (!StrEqual(cPrimary, ""))
        g_cPrimaryWeapon[client] = cPrimary;
    else g_cPrimaryWeapon[client] = "none";
    if (!StrEqual(cSecondary, ""))
        g_cSecondaryWeapon[client] = cSecondary;
    else g_cSecondaryWeapon[client] = "none";
    if (!StrEqual(cRemember, ""))
        g_bRememberChoice[client] = view_as<bool>(StringToInt(cRemember));
    else g_bRememberChoice[client] = false;
    if (!StrEqual(cFirst, ""))
        g_bFirstWeaponSelection[client] = view_as<bool>(StringToInt(cFirst));
    else g_bFirstWeaponSelection[client] = false;
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
    if (StrEqual(name, "updater"))
    {
        Updater_RemovePlugin();
    }
}

public void OnPluginEnd()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        DisableSpawnProtection(INVALID_HANDLE, i);
    }
    SetBuyZones("Enable");
    SetObjectives("Enable");
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_hPrimaryMenus[i] != INVALID_HANDLE)
            CancelMenu(g_hPrimaryMenus[i]);
    }
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_hSecondaryMenus[i] != INVALID_HANDLE)
            CancelMenu(g_hSecondaryMenus[i]);
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
    g_iGlowSprite = PrecacheModel("sprites/glow01.vmt", true);

    InitialiseWeaponCounts();
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i))
            ResetClientSettings(i);
    }
    LoadMapConfig();
    if (g_iSpawnPointCount > 0)
    {
        for (int i = 0; i < g_iSpawnPointCount; i++)
            g_bSpawnPointOccupied[i] = false;
    }
    if (g_cvDM_enabled.BoolValue)
    {
        SetBuyZones("Disable");
        if (g_cvDM_remove_objectives.BoolValue)
        {
            SetObjectives("Disable");
            RemoveHostages();
        }
        SetCashState();
        SetGrenadeState();
        SetNoSpawnWeapons();
        if (g_cvDM_free_for_all.BoolValue)
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
    if (g_cvDM_enabled.BoolValue)
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
    g_iLastEditorSpawnPoint[client] = -1;
    SetClientGunModeSettings(client);
    g_iInfoMessageCount[client] = 2;
    g_bWeaponsGivenThisRound[client] = false;
    g_bPlayerMoved[client] = false;
    g_bHSOnlyClient[client] = false;
}

void SetClientGunModeSettings(int client)
{
    switch (g_cvDM_gun_menu_mode.IntValue)
    {
        case 1:
        {
            if (IsFakeClient(client))
            {
                g_cPrimaryWeapon[client] = "random";
                g_cSecondaryWeapon[client] = "random";
                g_bFirstWeaponSelection[client] = false;
            }
        }
        case 2:
        {
            if (IsFakeClient(client))
            {
                g_cPrimaryWeapon[client] = "random";
                g_cSecondaryWeapon[client] = "none";
                g_bFirstWeaponSelection[client] = false;
            }
        }
        case 3:
        {
            if (IsFakeClient(client))
            {
                g_cPrimaryWeapon[client] = "none";
                g_cSecondaryWeapon[client] = "random";
                g_bFirstWeaponSelection[client] = false;
            }
        }
        case 4:
        {
            g_cPrimaryWeapon[client] = "random";
            g_cSecondaryWeapon[client] = "random";
            g_bFirstWeaponSelection[client] = false;
            if (!IsFakeClient(client))
            {
                SetClientCookie(client, g_hWeapon_Primary_Cookie, "random");
                SetClientCookie(client, g_hWeapon_Secondary_Cookie, "random");
                SetClientCookie(client, g_hWeapon_First_Cookie, "0");
            }
        }
        case 5:
        {
            if (IsFakeClient(client))
            {
                g_cPrimaryWeapon[client] = "random";
                g_cSecondaryWeapon[client] = "random";
                g_bFirstWeaponSelection[client] = false;
                g_bRememberChoice[client] = true;
            }
        }
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
    SetConVarString(g_cvDM_enabled, value);

    KvGetString(keyValues, "dm_enable_valve_deathmatch", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_valvedm, value);

    KvGetString(keyValues, "dm_welcomemsg", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_welcomemsg, value);

    KvGetString(keyValues, "dm_free_for_all", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_free_for_all, value);

    KvGetString(keyValues, "dm_hide_radar", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_hide_radar, value);

    KvGetString(keyValues, "dm_display_panel", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_display_panel, value);

    KvGetString(keyValues, "dm_display_panel_damage", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_display_panel_damage, value);

    KvGetString(keyValues, "dm_sounds_bodyshots", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_sounds_bodyshots, value);

    KvGetString(keyValues, "dm_sounds_headshots", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_sounds_headshots, value);

    KvGetString(keyValues, "dm_headshot_only", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_headshot_only, value);

    KvGetString(keyValues, "dm_headshot_only_allow_client", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_headshot_only_allow_client, value);

    KvGetString(keyValues, "dm_headshot_only_allow_world", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_headshot_only_allow_world, value);

    KvGetString(keyValues, "dm_headshot_only_allow_knife", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_headshot_only_allow_knife, value);

    KvGetString(keyValues, "dm_headshot_only_allow_taser", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_headshot_only_allow_taser, value);

    KvGetString(keyValues, "dm_headshot_only_allow_nade", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_headshot_only_allow_nade, value);

    KvGetString(keyValues, "dm_remove_objectives", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_remove_objectives, value);

    KvGetString(keyValues, "dm_respawning", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_respawning, value);

    KvGetString(keyValues, "dm_respawn_time", value, sizeof(value), "2.0");
    SetConVarString(g_cvDM_respawn_time, value);

    KvGetString(keyValues, "dm_gun_menu_mode", value, sizeof(value), "1");
    SetConVarString(g_cvDM_gun_menu_mode, value);

    KvGetString(keyValues, "dm_los_spawning", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_los_spawning, value);

    KvGetString(keyValues, "dm_los_attempts", value, sizeof(value), "10");
    SetConVarString(g_cvDM_los_attempts, value);

    KvGetString(keyValues, "dm_spawn_distance", value, sizeof(value), "0.0");
    SetConVarString(g_cvDM_spawn_distance, value);

    KvGetString(keyValues, "dm_spawn_time", value, sizeof(value), "1.0");
    SetConVarString(g_cvDM_spawn_time, value);

    KvGetString(keyValues, "dm_no_knife_damage", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_no_knife_damage, value);

    KvGetString(keyValues, "dm_remove_weapons", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_remove_weapons, value);

    KvGetString(keyValues, "dm_replenish_ammo", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_replenish_ammo, value);

    KvGetString(keyValues, "dm_replenish_ammo_clip", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_replenish_ammo_clip, value);

    KvGetString(keyValues, "dm_replenish_ammo_reserve", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_replenish_ammo_reserve, value);

    KvGetString(keyValues, "dm_replenish_grenade", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_replenish_grenade, value);

    KvGetString(keyValues, "dm_replenish_hegrenade", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_replenish_hegrenade, value);

    KvGetString(keyValues, "dm_replenish_grenade_kill", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_replenish_grenade_kill, value);

    KvGetString(keyValues, "dm_nade_messages", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_nade_messages, value);

    KvGetString(keyValues, "dm_cash_messages", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_cash_messages, value);

    KvGetString(keyValues, "dm_hp_start", value, sizeof(value), "100");
    SetConVarString(g_cvDM_hp_start, value);

    KvGetString(keyValues, "dm_hp_max", value, sizeof(value), "100");
    SetConVarString(g_cvDM_hp_max, value);

    KvGetString(keyValues, "dm_hp_kill", value, sizeof(value), "5");
    SetConVarString(g_cvDM_hp_kill, value);

    KvGetString(keyValues, "dm_hp_headshot", value, sizeof(value), "10");
    SetConVarString(g_cvDM_hp_headshot, value);

    KvGetString(keyValues, "dm_hp_knife", value, sizeof(value), "50");
    SetConVarString(g_cvDM_hp_knife, value);

    KvGetString(keyValues, "dm_hp_kill", value, sizeof(value), "30");
    SetConVarString(g_cvDM_hp_nade, value);

    KvGetString(keyValues, "dm_hp_messages", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_hp_messages, value);

    KvGetString(keyValues, "dm_ap_max", value, sizeof(value), "100");
    SetConVarString(g_cvDM_ap_max, value);

    KvGetString(keyValues, "dm_ap_kill", value, sizeof(value), "5");
    SetConVarString(g_cvDM_ap_kill, value);

    KvGetString(keyValues, "dm_ap_headshot", value, sizeof(value), "10");
    SetConVarString(g_cvDM_ap_headshot, value);

    KvGetString(keyValues, "dm_ap_knife", value, sizeof(value), "50");
    SetConVarString(g_cvDM_ap_knife, value);

    KvGetString(keyValues, "dm_ap_nade", value, sizeof(value), "30");
    SetConVarString(g_cvDM_ap_nade, value);

    KvGetString(keyValues, "dm_ap_messages", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_ap_messages, value);

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
            PushArrayString(g_hPrimaryWeaponsAvailable, key);
            SetTrieValue(g_hWeaponLimits, key, limit);
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
            PushArrayString(g_hSecondaryWeaponsAvailable, key);
            SetTrieValue(g_hWeaponLimits, key, limit);
        } while (KvGotoNextKey(keyValues, false));
    }

    KvGoBack(keyValues);
    KvGoBack(keyValues);

    if (!KvJumpToKey(keyValues, "Misc"))
        SetFailState("The configuration file is corrupt (\"Misc\" section could not be found).");

    KvGetString(keyValues, "armor (chest)", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_armor, value);

    KvGetString(keyValues, "armor (full)", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_armor_full, value);

    KvGetString(keyValues, "zeus", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    SetConVarString(g_cvDM_zeus, value);

    KvGoBack(keyValues);

    if (!KvJumpToKey(keyValues, "Grenades"))
        SetFailState("The configuration file is corrupt (\"Grenades\" section could not be found).");

    KvGetString(keyValues, "incendiary", value, sizeof(value), "0");
    SetConVarString(g_cvDM_nades_incendiary, value);

    KvGetString(keyValues, "molotov", value, sizeof(value), "0");
    SetConVarString(g_cvDM_nades_incendiary, value);

    KvGetString(keyValues, "decoy", value, sizeof(value), "0");
    SetConVarString(g_cvDM_nades_decoy, value);

    KvGetString(keyValues, "flashbang", value, sizeof(value), "0");
    SetConVarString(g_cvDM_nades_flashbang, value);

    KvGetString(keyValues, "he", value, sizeof(value), "0");
    SetConVarString(g_cvDM_nades_he, value);

    KvGetString(keyValues, "smoke", value, sizeof(value), "0");
    SetConVarString(g_cvDM_nades_smoke, value);

    KvGetString(keyValues, "tactical", value, sizeof(value), "0");
    SetConVarString(g_cvDM_nades_tactical, value);

    KvGoBack(keyValues);

    if (KvJumpToKey(keyValues, "TeamData") && KvGotoFirstSubKey(keyValues, false))
    {
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
            g_smWeaponTeams.SetValue(key, team);
        } while (KvGotoNextKey(keyValues, false));
        KvGoBack(keyValues);
    }

    CloseHandle(keyValues);
}

void RetrieveVariables()
{
    /* Retrieve Native Console Variables */
    g_hMP_ct_default_primary = FindConVar("mp_ct_default_primary");
    g_hMP_t_default_primary = FindConVar("mp_t_default_primary");
    g_hMP_ct_default_secondary = FindConVar("mp_ct_default_secondary");
    g_hMP_t_default_secondary = FindConVar("mp_t_default_secondary");
    g_hMP_startmoney = FindConVar("mp_startmoney");
    g_hMP_playercashawards = FindConVar("mp_playercashawards");
    g_hMP_teamcashawards = FindConVar("mp_teamcashawards");
    g_hMP_friendlyfire = FindConVar("mp_friendlyfire");
    g_hMP_autokick = FindConVar("mp_autokick");
    g_hMP_tkpunish = FindConVar("mp_tkpunish");
    g_hMP_teammates_are_enemies = FindConVar("mp_teammates_are_enemies");
    g_hFF_damage_reduction_bullets = FindConVar("ff_damage_reduction_bullets");
    g_hFF_damage_reduction_grenade = FindConVar("ff_damage_reduction_grenade");
    g_hFF_damage_reduction_other = FindConVar("ff_damage_reduction_other");
    g_hAmmo_grenade_limit_default = FindConVar("ammo_grenade_limit_default");
    g_hAmmo_grenade_limit_flashbang = FindConVar("ammo_grenade_limit_flashbang");
    g_hAmmo_grenade_limit_total = FindConVar("ammo_grenade_limit_total");

    /* Retrieve Native Console Variable Values */
    g_iBackup_mp_startmoney = GetConVarInt(g_hMP_startmoney);
    g_iBackup_mp_playercashawards = GetConVarInt(g_hMP_playercashawards);
    g_iBackup_mp_teamcashawards = GetConVarInt(g_hMP_teamcashawards);
    g_iBackup_mp_friendlyfire = GetConVarInt(g_hMP_friendlyfire);
    g_iBackup_mp_autokick = GetConVarInt(g_hMP_autokick);
    g_iBackup_mp_tkpunish = GetConVarInt(g_hMP_tkpunish);
    g_iBackup_mp_teammates_are_enemies = GetConVarInt(g_hMP_teammates_are_enemies);
    g_fBackup_ff_damage_reduction_bullets = GetConVarFloat(g_hFF_damage_reduction_bullets);
    g_fBackup_ff_damage_reduction_grenade = GetConVarFloat(g_hFF_damage_reduction_grenade);
    g_fBackup_ff_damage_reduction_other = GetConVarFloat(g_hFF_damage_reduction_other);
    g_iBackup_ammo_grenade_limit_default = GetConVarInt(g_hAmmo_grenade_limit_default);
    g_iBackup_ammo_grenade_limit_flashbang = GetConVarInt(g_hAmmo_grenade_limit_flashbang);
    g_iBackup_ammo_grenade_limit_total = GetConVarInt(g_hAmmo_grenade_limit_total);
}

void UpdateState()
{
    if (g_cvDM_respawn_time.FloatValue < 0.0) g_cvDM_respawn_time.FloatValue = 0.0;
    if (g_cvDM_gun_menu_mode.IntValue < 1) g_cvDM_gun_menu_mode.IntValue = 1;
    if (g_cvDM_gun_menu_mode.IntValue > 5) g_cvDM_gun_menu_mode.IntValue = 5;
    if (g_cvDM_los_attempts.IntValue < 0) g_cvDM_los_attempts.IntValue = 0;
    if (g_cvDM_spawn_distance.FloatValue < 0.0) g_cvDM_spawn_distance.FloatValue = 0.0;
    if (g_cvDM_spawn_time.FloatValue < 0.0) g_cvDM_spawn_time.FloatValue = 0.0;
    if (g_cvDM_hp_start.IntValue < 1) g_cvDM_hp_start.IntValue = 1;
    if (g_cvDM_hp_max.IntValue < 1) g_cvDM_hp_max.IntValue = 1;
    if (g_cvDM_hp_kill.IntValue < 0) g_cvDM_hp_kill.IntValue = 0;
    if (g_cvDM_hp_headshot.IntValue < 0) g_cvDM_hp_headshot.IntValue = 0;
    if (g_cvDM_hp_knife.IntValue < 0) g_cvDM_hp_knife.IntValue = 0;
    if (g_cvDM_hp_nade.IntValue < 0) g_cvDM_hp_nade.IntValue = 0;
    if (g_cvDM_ap_max.IntValue < 0) g_cvDM_ap_max.IntValue = 0;
    if (g_cvDM_ap_kill.IntValue < 0) g_cvDM_ap_kill.IntValue = 0;
    if (g_cvDM_ap_headshot.IntValue < 0) g_cvDM_ap_headshot.IntValue = 0;
    if (g_cvDM_ap_knife.IntValue < 0) g_cvDM_ap_knife.IntValue = 0;
    if (g_cvDM_ap_nade.IntValue < 0) g_cvDM_ap_nade.IntValue = 0;
    if (g_cvDM_nades_incendiary.IntValue < 0) g_cvDM_nades_incendiary.IntValue = 0;
    if (g_cvDM_nades_molotov.IntValue < 0) g_cvDM_nades_molotov.IntValue = 0;
    if (g_cvDM_nades_decoy.IntValue < 0) g_cvDM_nades_decoy.IntValue = 0;
    if (g_cvDM_nades_flashbang.IntValue < 0) g_cvDM_nades_flashbang.IntValue = 0;
    if (g_cvDM_nades_he.IntValue < 0) g_cvDM_nades_he.IntValue = 0;
    if (g_cvDM_nades_smoke.IntValue < 0) g_cvDM_nades_smoke.IntValue = 0;
    if (g_cvDM_nades_tactical.IntValue < 0) g_cvDM_nades_tactical.IntValue = 0;

    if (g_cvDM_enabled.BoolValue)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientConnected(i))
                ResetClientSettings(i);
        }
        RespawnAll();
        SetBuyZones("Disable");
        char status[10];
        status = (g_cvDM_remove_objectives.BoolValue) ? "Disable" : "Enable";
        SetObjectives(status);
        SetCashState();
        SetNoSpawnWeapons();
    }
    else if (!g_cvDM_enabled.BoolValue)
    {
        for (int i = 1; i <= MaxClients; i++)
            DisableSpawnProtection(INVALID_HANDLE, i);
        for (int i = 1; i <= MaxClients; i++)
        {
            if (g_hPrimaryMenus[i] != INVALID_HANDLE)
                CancelMenu(g_hPrimaryMenus[i]);
        }
        for (int i = 1; i <= MaxClients; i++)
        {
            if (g_hSecondaryMenus[i] != INVALID_HANDLE)
                CancelMenu(g_hSecondaryMenus[i]);
        }
        SetBuyZones("Enable");
        SetObjectives("Enable");
        RestoreCashState();
        RestoreGrenadeState();
    }

    if (g_cvDM_enabled.BoolValue)
    {
        if (g_cvDM_gun_menu_mode.IntValue)
        {
            if (g_cvDM_gun_menu_mode.IntValue == 5)
            {
                for (int i = 1; i <= MaxClients; i++)
                    CancelClientMenu(i);
            }
            /* Only if the plugin was enabled before the state update do we need to update the client's gun mode settings. If it was disabled before, then */
            /* the entire client settings (including gun mode settings) are reset above. */
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsClientConnected(i))
                    SetClientGunModeSettings(i);
            }
        }
        if (g_cvDM_remove_objectives.BoolValue)
            RemoveC4();
        SetGrenadeState();
        if (g_cvDM_free_for_all.BoolValue)
            EnableFFA();
        else
            DisableFFA();
    }
}

void SetNoSpawnWeapons()
{
    SetConVarString(g_hMP_ct_default_primary, "");
    SetConVarString(g_hMP_t_default_primary, "");
    SetConVarString(g_hMP_ct_default_secondary, "");
    SetConVarString(g_hMP_t_default_secondary, "");
}

void SetCashState()
{
    SetConVarInt(g_hMP_startmoney, 0);
    SetConVarInt(g_hMP_playercashawards, 0);
    SetConVarInt(g_hMP_teamcashawards, 0);
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
            SetEntProp(i, Prop_Send, "m_iAccount", 0);
    }
}

void RestoreCashState()
{
    SetConVarInt(g_hMP_startmoney, g_iBackup_mp_startmoney);
    SetConVarInt(g_hMP_playercashawards, g_iBackup_mp_playercashawards);
    SetConVarInt(g_hMP_teamcashawards, g_iBackup_mp_teamcashawards);
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
            SetEntProp(i, Prop_Send, "m_iAccount", g_iBackup_mp_startmoney);
    }
}

void SetGrenadeState()
{
    int maxGrenadesSameType = 0;
    if (g_cvDM_nades_incendiary.IntValue > maxGrenadesSameType) maxGrenadesSameType = g_cvDM_nades_incendiary.IntValue;
    if (g_cvDM_nades_molotov.IntValue > maxGrenadesSameType) maxGrenadesSameType = g_cvDM_nades_molotov.IntValue;
    if (g_cvDM_nades_decoy.IntValue > maxGrenadesSameType) maxGrenadesSameType = g_cvDM_nades_decoy.IntValue;
    if (g_cvDM_nades_flashbang.IntValue > maxGrenadesSameType) maxGrenadesSameType = g_cvDM_nades_flashbang.IntValue;
    if (g_cvDM_nades_he.IntValue > maxGrenadesSameType) maxGrenadesSameType = g_cvDM_nades_he.IntValue;
    if (g_cvDM_nades_smoke.IntValue > maxGrenadesSameType) maxGrenadesSameType = g_cvDM_nades_smoke.IntValue;
    if (g_cvDM_nades_tactical.IntValue > maxGrenadesSameType) maxGrenadesSameType = g_cvDM_nades_tactical.IntValue;
    SetConVarInt(g_hAmmo_grenade_limit_default, maxGrenadesSameType);
    SetConVarInt(g_hAmmo_grenade_limit_flashbang, g_cvDM_nades_flashbang.IntValue);
    SetConVarInt(g_hAmmo_grenade_limit_total, 
        g_cvDM_nades_incendiary.IntValue + 
        g_cvDM_nades_molotov.IntValue + 
        g_cvDM_nades_decoy.IntValue + 
        g_cvDM_nades_flashbang.IntValue + 
        g_cvDM_nades_he.IntValue + 
        g_cvDM_nades_smoke.IntValue + 
        g_cvDM_nades_tactical.IntValue);
}

void RestoreGrenadeState()
{
    SetConVarInt(g_hAmmo_grenade_limit_default, g_iBackup_ammo_grenade_limit_default);
    SetConVarInt(g_hAmmo_grenade_limit_flashbang, g_iBackup_ammo_grenade_limit_flashbang);
    SetConVarInt(g_hAmmo_grenade_limit_total, g_iBackup_ammo_grenade_limit_total);
}

void EnableFFA()
{
    SetConVarInt(g_hMP_teammates_are_enemies, 1);
    SetConVarInt(g_hMP_friendlyfire, 1);
    SetConVarInt(g_hMP_autokick, 0);
    SetConVarInt(g_hMP_tkpunish, 0);
    SetConVarFloat(g_hFF_damage_reduction_bullets, 1.0);
    SetConVarFloat(g_hFF_damage_reduction_grenade, 1.0);
    SetConVarFloat(g_hFF_damage_reduction_other, 1.0);
}

void DisableFFA()
{
    SetConVarInt(g_hMP_teammates_are_enemies, g_iBackup_mp_teammates_are_enemies);
    SetConVarInt(g_hMP_friendlyfire, g_iBackup_mp_friendlyfire);
    SetConVarInt(g_hMP_autokick, g_iBackup_mp_autokick);
    SetConVarInt(g_hMP_tkpunish, g_iBackup_mp_tkpunish);
    SetConVarFloat(g_hFF_damage_reduction_bullets, g_fBackup_ff_damage_reduction_bullets);
    SetConVarFloat(g_hFF_damage_reduction_grenade, g_fBackup_ff_damage_reduction_grenade);
    SetConVarFloat(g_hFF_damage_reduction_other, g_fBackup_ff_damage_reduction_other);
}

void LoadMapConfig()
{
    char map[64];
    GetCurrentMap(map, sizeof(map));

    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/deathmatch/spawns/%s.txt", map);

    g_iSpawnPointCount = 0;

    /* Open file */
    File file = OpenFile(path, "r");
    if (file != null)
    {
        /* Read file */
        char buffer[256];
        char parts[6][16];
        while (!IsEndOfFile(file) && ReadFileLine(file, buffer, sizeof(buffer)))
        {
            ExplodeString(buffer, " ", parts, 6, 16);
            g_fSpawnPositions[g_iSpawnPointCount][0] = StringToFloat(parts[0]);
            g_fSpawnPositions[g_iSpawnPointCount][1] = StringToFloat(parts[1]);
            g_fSpawnPositions[g_iSpawnPointCount][2] = StringToFloat(parts[2]);
            g_fSpawnAngles[g_iSpawnPointCount][0] = StringToFloat(parts[3]);
            g_fSpawnAngles[g_iSpawnPointCount][1] = StringToFloat(parts[4]);
            g_fSpawnAngles[g_iSpawnPointCount][2] = StringToFloat(parts[5]);
            g_iSpawnPointCount++;
        }
    }
    /* Close file */
    delete file;
}

bool WriteMapConfig()
{
    char map[64];
    GetCurrentMap(map, sizeof(map));

    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/deathmatch/spawns/%s.txt", map);

    /* Open file */
    File file = OpenFile(path, "w");
    if (file == null)
    {
        LogError("Could not open spawn point file \"%s\" for writing.", path);
        return false;
    }
    /* Write spawn points */
    for (int i = 0; i < g_iSpawnPointCount; i++)
        WriteFileLine(file, "%f %f %f %f %f %f", g_fSpawnPositions[i][0], g_fSpawnPositions[i][1], g_fSpawnPositions[i][2], g_fSpawnAngles[i][0], g_fSpawnAngles[i][1], g_fSpawnAngles[i][2]);
    /* Close file */
    delete file;
    return true;
}

public Action Event_Say(int client, const char[] command, int argc)
{
    static char menuTriggers[][] = { "gun", "!gun", "/gun", "guns", "!guns", "/guns", "menu", "!menu", "/menu", "weapon", "!weapon", "/weapon", "weapons", "!weapons", "/weapons" };
    static char hsOnlyTriggers[][] = { "hs", "!hs", "/hs", "headshot", "!headshot", "/headshot" };

    if (g_cvDM_enabled.BoolValue && IsValidClient(client) && (GetClientTeam(client) != CS_TEAM_SPECTATOR))
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
                if (g_cvDM_gun_menu_mode.IntValue == 1 || g_cvDM_gun_menu_mode.IntValue == 2 || g_cvDM_gun_menu_mode.IntValue == 3)
                    DisplayOptionsMenu(client);
                else
                    CPrintToChat(client, "[\x04DM\x01] %t", "Guns Disabled");
                return Plugin_Handled;
            }
        }
        if (!g_cvDM_headshot_only.BoolValue && g_cvDM_headshot_only_allow_client.BoolValue)
        {
            for(int i = 0; i < sizeof(hsOnlyTriggers); i++)
            {
                if (StrEqual(text, hsOnlyTriggers[i], false))
                {
                    g_bHSOnlyClient[client] = !g_bHSOnlyClient[client]; 
                    CPrintToChat(client, "[\x04DM\x01] %t", "HS Only Client %s", g_bHSOnlyClient[client] ? "Enabled" : "Disabled");
                    return Plugin_Handled;
                }
            }
        }
    }
    return Plugin_Continue;
}

void BuildWeaponMenuNames()
{
    g_hWeaponMenuNames = CreateTrie();
    /* Primary weapons */
    SetTrieString(g_hWeaponMenuNames, "weapon_ak47", "AK-47");
    SetTrieString(g_hWeaponMenuNames, "weapon_m4a1", "M4A1");
    SetTrieString(g_hWeaponMenuNames, "weapon_m4a1_silencer", "M4A1-S");
    SetTrieString(g_hWeaponMenuNames, "weapon_sg556", "SG 553");
    SetTrieString(g_hWeaponMenuNames, "weapon_aug", "AUG");
    SetTrieString(g_hWeaponMenuNames, "weapon_galilar", "Galil AR");
    SetTrieString(g_hWeaponMenuNames, "weapon_famas", "FAMAS");
    SetTrieString(g_hWeaponMenuNames, "weapon_awp", "AWP");
    SetTrieString(g_hWeaponMenuNames, "weapon_ssg08", "SSG 08");
    SetTrieString(g_hWeaponMenuNames, "weapon_g3sg1", "G3SG1");
    SetTrieString(g_hWeaponMenuNames, "weapon_scar20", "SCAR-20");
    SetTrieString(g_hWeaponMenuNames, "weapon_m249", "M249");
    SetTrieString(g_hWeaponMenuNames, "weapon_negev", "Negev");
    SetTrieString(g_hWeaponMenuNames, "weapon_nova", "Nova");
    SetTrieString(g_hWeaponMenuNames, "weapon_xm1014", "XM1014");
    SetTrieString(g_hWeaponMenuNames, "weapon_sawedoff", "Sawed-Off");
    SetTrieString(g_hWeaponMenuNames, "weapon_mag7", "MAG-7");
    SetTrieString(g_hWeaponMenuNames, "weapon_mac10", "MAC-10");
    SetTrieString(g_hWeaponMenuNames, "weapon_mp9", "MP9");
    SetTrieString(g_hWeaponMenuNames, "weapon_mp7", "MP7");
    SetTrieString(g_hWeaponMenuNames, "weapon_ump45", "UMP-45");
    SetTrieString(g_hWeaponMenuNames, "weapon_p90", "P90");
    SetTrieString(g_hWeaponMenuNames, "weapon_bizon", "PP-Bizon");
    /* Secondary weapons */
    SetTrieString(g_hWeaponMenuNames, "weapon_glock", "Glock-18");
    SetTrieString(g_hWeaponMenuNames, "weapon_p250", "P250");
    SetTrieString(g_hWeaponMenuNames, "weapon_cz75a", "CZ75-A");
    SetTrieString(g_hWeaponMenuNames, "weapon_usp_silencer", "USP-S");
    SetTrieString(g_hWeaponMenuNames, "weapon_fiveseven", "Five-SeveN");
    SetTrieString(g_hWeaponMenuNames, "weapon_deagle", "Desert Eagle");
    SetTrieString(g_hWeaponMenuNames, "weapon_revolver", "R8");
    SetTrieString(g_hWeaponMenuNames, "weapon_elite", "Dual Berettas");
    SetTrieString(g_hWeaponMenuNames, "weapon_tec9", "Tec-9");
    SetTrieString(g_hWeaponMenuNames, "weapon_hkp2000", "P2000");
    /* Random */
    SetTrieString(g_hWeaponMenuNames, "random", "Random");
}

void InitialiseWeaponCounts()
{
    for (int i = 0; i < GetArraySize(g_hPrimaryWeaponsAvailable); i++)
    {
        char weapon[24];
        GetArrayString(g_hPrimaryWeaponsAvailable, i, weapon, sizeof(weapon));
        SetTrieValue(g_hWeaponCounts, weapon, 0);
    }
    for (int i = 0; i < GetArraySize(g_hSecondaryWeaponsAvailable); i++)
    {
        char weapon[24];
        GetArrayString(g_hSecondaryWeaponsAvailable, i, weapon, sizeof(weapon));
        SetTrieValue(g_hWeaponCounts, weapon, 0);
    }
}

void DisplayOptionsMenu(int client)
{
    int allowSameWeapons = (g_bRememberChoice[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
    Menu menu = new Menu(MenuHandler);
    menu.SetTitle("Weapon Menu:");
    menu.AddItem("New", "New weapons");
    menu.AddItem("Same", "Same weapons", allowSameWeapons);
    menu.AddItem("Random", "Random weapons");
    menu.ExitBackButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
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
    if (g_cvDM_enabled.BoolValue && g_cvDM_respawning.BoolValue)
        CreateTimer(g_cvDM_respawn_time.FloatValue, Respawn, GetClientSerial(client));
}

public Action Event_RoundPrestart(Event event, const char[] name, bool dontBroadcast)
{
    g_bRoundEnded = false;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        if (g_cvDM_remove_objectives.BoolValue)
            RemoveHostages();
        if (g_cvDM_remove_weapons.BoolValue)
            RemoveGroundWeapons(INVALID_HANDLE);
    }
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    g_bRoundEnded = true;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (IsValidClient(client) && GetClientTeam(client) != CS_TEAM_SPECTATOR)
        {
            if (!IsFakeClient(client))
            {
                if (g_cvDM_welcomemsg.BoolValue && g_iInfoMessageCount[client] > 0)
                {
                    PrintHintText(client, "This server is running:\n <font color='#00FF00'>Deathmatch</font> v%s", PLUGIN_VERSION);
                    CPrintToChat(client, "[\x04DM\x01] This server is running \x04Deathmatch \x01v%s", PLUGIN_VERSION);
                    if (!g_cvDM_headshot_only.BoolValue)
                    {
                        CPrintToChat(client, "[\x04DM\x01] %t", "HS Hint");
                    }
                }
                /* Hide radar. */
                if (g_cvDM_free_for_all.BoolValue || g_cvDM_hide_radar.BoolValue)
                {
                    RequestFrame(Frame_RemoveRadar, GetClientSerial(client));
                }
                /* Display help message. */
                if ((g_cvDM_gun_menu_mode.IntValue <= 3) && g_iInfoMessageCount[client] > 0)
                {
                    CPrintToChat(client, "[\x04DM\x01] %t", "Guns Menu");
                    g_iInfoMessageCount[client]--;
                }
                /* Display the panel for attacker information. */
                if (g_cvDM_display_panel.BoolValue)
                {
                    g_hDamageDisplay[client] = CreateTimer(1.0, PanelDisplay, GetClientSerial(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                }
            }
            /* Teleport player to custom spawn point. */
            if (g_iSpawnPointCount > 0)
            {
                MovePlayer(client);
            }
            /* Enable player spawn protection. */
            if (g_cvDM_spawn_time.FloatValue > 0.0)
            {
                EnableSpawnProtection(client);
            }
            /* Set health. */
            if (g_cvDM_hp_start.IntValue != 100)
            {
                SetEntityHealth(client, g_cvDM_hp_start.IntValue);
            }
            /* Give equipment */
            if (g_cvDM_armor.BoolValue)
            {
                SetEntData(client, g_iArmorOffset, 100);
                SetEntData(client, g_iHelmetOffset, 0);
            }
            else if (g_cvDM_armor_full.BoolValue)
            {
                SetEntData(client, g_iArmorOffset, 100);
                SetEntData(client, g_iHelmetOffset, 1);
            }
            else if (!g_cvDM_armor_full.BoolValue || !g_cvDM_armor.BoolValue)
            {
                SetEntData(client, g_iArmorOffset, 0);
                SetEntData(client, g_iHelmetOffset, 0);
            }
            /* Give weapons or display menu. */
            g_bWeaponsGivenThisRound[client] = false;
            RemoveClientWeapons(client);
            if (!IsFakeClient(client))
            {
                char cRemember[24];
                GetClientCookie(client, g_hWeapon_Remember_Cookie, cRemember, sizeof(cRemember));
                g_bRememberChoice[client] = view_as<bool>(StringToInt(cRemember));
            }
            if (g_bRememberChoice[client] || IsFakeClient(client))
            {
                if (g_cvDM_gun_menu_mode.IntValue == 1 || g_cvDM_gun_menu_mode.IntValue == 4)
                {
                    GiveSavedWeapons(client, true, true);
                }
                /* Give only primary weapons if remembered. */
                else if (g_cvDM_gun_menu_mode.IntValue == 2)
                {
                    GiveSavedWeapons(client, true, false)
                }
                /* Give only secondary weapons if remembered. */
                else if (g_cvDM_gun_menu_mode.IntValue == 3)
                {
                    GiveSavedWeapons(client, false, true);
                }
            }
            /* Display the gun menu to new users. */
            else if (!IsFakeClient(client))
            {
                /* All weapons menu. */
                if (g_cvDM_gun_menu_mode.IntValue <= 3)
                {
                    DisplayOptionsMenu(client);
                }
            }
            /* Remove C4. */
            if (g_cvDM_remove_objectives.BoolValue)
            {
                StripC4(client);
            }
        }
    }
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
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
        if (validAttacker && (g_cvDM_replenish_ammo_clip.BoolValue || g_cvDM_replenish_ammo_reserve.BoolValue))
        {
            RequestFrame(Frame_GiveAmmo, GetClientSerial(attackerIndex));
        }

        /* Reward attacker with HP. */
        if (validAttacker)
        {
            bool knifed = StrEqual(weapon, "knife");
            bool nades = StrEqual(hegrenade, "hegrenade");
            bool decoys = StrEqual(decoygrenade, "decoy");
            bool headshot = GetEventBool(event, "headshot");

            if ((knifed && (g_cvDM_hp_knife.IntValue > 0)) || (!knifed && (g_cvDM_hp_kill.IntValue > 0)) || (headshot && (g_cvDM_hp_headshot.IntValue > 0)) || (!headshot && (g_cvDM_hp_kill.IntValue > 0)))
            {
                int attackerHP = GetClientHealth(attackerIndex);

                if (attackerHP < g_cvDM_hp_max.IntValue)
                {
                    int addHP;
                    if (knifed)
                        addHP = g_cvDM_hp_knife.IntValue;
                    else if (headshot)
                        addHP = g_cvDM_hp_headshot.IntValue;
                    else if (nades)
                        addHP = g_cvDM_hp_nade.IntValue;
                    else
                        addHP = g_cvDM_hp_kill.IntValue;
                    int newHP = attackerHP + addHP;
                    if (newHP > g_cvDM_hp_max.IntValue)
                        newHP = g_cvDM_hp_max.IntValue;
                    SetEntProp(attackerIndex, Prop_Send, "m_iHealth", newHP, 1);
                }

                if (g_cvDM_hp_messages.BoolValue && !g_cvDM_ap_messages.BoolValue)
                {
                    if(attackerHP < g_cvDM_hp_max.IntValue)
                    {
                        if (knifed)
                            CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 %t", g_cvDM_hp_knife.IntValue, "HP Knife Kill");
                        else if (headshot)
                            CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 %t", g_cvDM_hp_headshot.IntValue, "HP Headshot Kill");
                        else if (nades)
                            CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 %t", g_cvDM_hp_nade.IntValue, "HP Nade Kill");
                        else 
                            CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 %t", g_cvDM_hp_kill.IntValue, "HP Kill");
                    }
                }
            }

            /* Reward attacker with AP. */
            if ((knifed && (g_cvDM_ap_knife.IntValue > 0)) || (!knifed && (g_cvDM_ap_kill.IntValue > 0)) || (headshot && (g_cvDM_ap_headshot.IntValue > 0)) || (!headshot && (g_cvDM_ap_kill.IntValue > 0)))
            {
                int attackerAP = GetClientArmor(attackerIndex);

                if (attackerAP < g_cvDM_ap_max.IntValue)
                {
                    int addAP;
                    if (knifed)
                        addAP = g_cvDM_ap_knife.IntValue;
                    else if (headshot)
                        addAP = g_cvDM_ap_headshot.IntValue;
                    else if (nades)
                        addAP = g_cvDM_ap_nade.IntValue;
                    else
                        addAP = g_cvDM_ap_kill.IntValue;
                    int newAP = attackerAP + addAP;
                    if (newAP > g_cvDM_ap_max.IntValue)
                        newAP = g_cvDM_ap_max.IntValue;
                    SetEntProp(attackerIndex, Prop_Send, "m_ArmorValue", newAP, 1);
                }

                if (g_cvDM_ap_messages.BoolValue && !g_cvDM_hp_messages.BoolValue)
                {
                    if (attackerAP < g_cvDM_ap_max.IntValue)
                    {
                        if (knifed)
                            CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i AP\x01 %t", g_cvDM_ap_knife.IntValue, "AP Knife Kill");
                        else if (headshot)
                            CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i AP\x01 %t", g_cvDM_ap_headshot.IntValue, "AP Headshot Kill");
                        else if (nades)
                            CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i AP\x01 %t", g_cvDM_ap_nade.IntValue, "AP Nade Kill");
                        else
                            CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i AP\x01 %t", g_cvDM_ap_kill.IntValue, "AP Kill");
                    }
                }
            }

            if ((g_cvDM_hp_messages.BoolValue && g_cvDM_ap_messages.BoolValue))
            {
                int attackerAP = GetClientArmor(attackerIndex);
                int attackerHP = GetClientHealth(attackerIndex);
                bool bchanged = true;

                if (attackerAP < g_cvDM_ap_max.IntValue && attackerHP < g_cvDM_hp_max.IntValue)
                {
                    if (knifed)
                        CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 & \x04+%i AP\x01 %t", g_cvDM_hp_knife.IntValue, g_cvDM_ap_knife.IntValue, "HP Knife Kill", "AP Knife Kill");
                    else if (headshot)
                        CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 & \x04+%i AP\x01 %t", g_cvDM_hp_headshot.IntValue, g_cvDM_ap_headshot.IntValue, "HP Headshot Kill", "AP Headshot Kill");
                    else if (nades)
                        CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 & \x04+%i AP\x01 %t", g_cvDM_hp_nade.IntValue, g_cvDM_ap_nade.IntValue, "HP Nade Kill", "AP Nade Kill");
                    else
                        CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 & \x04+%i AP\x01 %t", g_cvDM_hp_kill.IntValue, g_cvDM_ap_kill.IntValue, "HP Kill", "AP Kill");

                    bchanged = false;
                }
                else if (bchanged && attackerHP < g_cvDM_hp_max.IntValue)
                {
                    if (knifed)
                        CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 %t", g_cvDM_hp_knife.IntValue, "HP Knife Kill");
                    else if (headshot)
                        CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 %t", g_cvDM_hp_headshot.IntValue, "HP Headshot Kill");
                    else if (nades)
                        CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 %t", g_cvDM_hp_nade.IntValue, "HP Nade Kill");
                    else 
                        CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i HP\x01 %t", g_cvDM_hp_kill.IntValue, "HP Kill");

                    bchanged = false;
                }
                else if (bchanged && attackerAP < g_cvDM_ap_max.IntValue)
                {
                    if (knifed)
                        CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i AP\x01 %t", g_cvDM_ap_knife.IntValue, "AP Knife Kill");
                    else if (headshot)
                        CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i AP\x01 %t", g_cvDM_ap_headshot.IntValue, "AP Headshot Kill");
                    else if (nades)
                        CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i AP\x01 %t", g_cvDM_ap_nade.IntValue, "AP Nade Kill");
                    else
                        CPrintToChat(attackerIndex, "[\x04DM\x01] \x04+%i AP\x01 %t", g_cvDM_ap_kill.IntValue, "AP Kill");
                }
            }

            if (g_cvDM_replenish_grenade.BoolValue)
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

        if (g_cvDM_respawning.BoolValue)
        {
            CreateTimer(g_cvDM_respawn_time.FloatValue, Respawn, GetClientSerial(client));
        }
    }
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_display_panel.BoolValue)
    {
        int victim = GetClientOfUserId(event.GetInt("userid"));
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        int health = event.GetInt("health");

        if (IsValidClient(attacker) && attacker != victim && victim != 0)
        {
            if (0 < health)
            {
                if (g_cvDM_display_panel_damage.BoolValue)
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

    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (g_cvDM_headshot_only.BoolValue || (g_bHSOnlyClient[attacker] && g_cvDM_headshot_only_allow_client.BoolValue))
    {
        int victim = GetClientOfUserId(event.GetInt("userid"));
        int dhealth = event.GetInt("dmg_health");
        int darmor = event.GetInt("dmg_iArmor");
        int health = event.GetInt("health");
        int armor = event.GetInt("armor");
        char weapon[32];
        char grenade[16];
        GetEventString(event, "weapon", weapon, sizeof(weapon));
        GetEventString(event, "weapon", grenade, sizeof(grenade));

        if (!g_cvDM_headshot_only_allow_nade.BoolValue)
        {
            if (StrEqual(grenade, "hegrenade", false))
            {
                if (attacker != victim && victim != 0)
                {
                    if (dhealth > 0)
                    {
                        SetEntData(victim, g_iHealthOffset, (health + dhealth), 4, true);
                    }
                    if (darmor > 0)
                    {
                        SetEntData(victim, g_iArmorOffset, (armor + darmor), 4, true);
                    }
                }
            }
        }

        if (!g_cvDM_headshot_only_allow_taser.BoolValue)
        {
            if (StrEqual(weapon, "taser", false))
            {
                if (attacker != victim && victim != 0)
                {
                    if (dhealth > 0)
                    {
                        SetEntData(victim, g_iHealthOffset, (health + dhealth), 4, true);
                    }
                    if (darmor > 0)
                    {
                        SetEntData(victim, g_iArmorOffset, (armor + darmor), 4, true);
                    }
                }
            }
        }

        if (!g_cvDM_headshot_only_allow_knife.BoolValue)
        {
            if (StrEqual(weapon, "knife", false))
            {
                if (attacker != victim && victim != 0)
                {
                    if (dhealth > 0)
                    {
                        SetEntData(victim, g_iHealthOffset, (health + dhealth), 4, true);
                    }
                    if (darmor > 0)
                    {
                        SetEntData(victim, g_iArmorOffset, (armor + darmor), 4, true);
                    }
                }
            }
        }

        if (!g_cvDM_headshot_only_allow_world.BoolValue)
        {
            if (victim !=0 && attacker == 0)
            {
                if (dhealth > 0)
                {
                    SetEntData(victim, g_iHealthOffset, (health + dhealth), 4, true);
                }
                if (darmor > 0)
                {
                    SetEntData(victim, g_iArmorOffset, (armor + darmor), 4, true);
                }
            }
        }
    }
    return Plugin_Continue;
}

public Action Event_WeaponFireOnEmpty(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (g_cvDM_replenish_ammo.BoolValue)
    {
        RequestFrame(Frame_GiveAmmo, GetClientSerial(client));
    }
}

public Action Event_HegrenadeDetonate(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_replenish_grenade.BoolValue || g_cvDM_replenish_hegrenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (IsValidClient(client) && IsPlayerAlive(client))
        {
            GivePlayerItem(client, "weapon_hegrenade");
        }
    }

    return Plugin_Continue;
}

public Action Event_SmokegrenadeDetonate(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (IsValidClient(client) && IsPlayerAlive(client))
        {
            GivePlayerItem(client, "weapon_smokegrenade");
        }
    }

    return Plugin_Continue;
}

public Action Event_FlashbangDetonate(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvDM_replenish_grenade.BoolValue)
    {
        return Plugin_Continue;
    }

    int client = GetClientOfUserId(event.GetInt("userid"));

    if (g_cvDM_replenish_grenade.BoolValue)
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
    if (g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));

        if (IsValidClient(client) && IsPlayerAlive(client))
        {
            GivePlayerItem(client, "weapon_decoy");
        }
    }

    return Plugin_Continue;
}

public Action Event_MolotovDetonate(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));

        if (IsValidClient(client) && IsPlayerAlive(client))
        {
            GivePlayerItem(client, "weapon_molotov");
        }
    }

    return Plugin_Continue;
}

public Action Event_InfernoStartburn(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));

        if (IsValidClient(client) && IsPlayerAlive(client))
        {
            GivePlayerItem(client, "weapon_incgrenade");
        }
    }

    return Plugin_Continue;
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    if (g_cvDM_no_knife_damage.BoolValue)
    {
        char knife[32];
        GetClientWeapon(attacker, knife, sizeof(knife));
        if (StrEqual(knife, "weapon_knife") || StrEqual(knife, "weapon_bayonet"))
        {
            return Plugin_Handled;
        }
    }

    if (g_cvDM_headshot_only.BoolValue || (g_bHSOnlyClient[attacker] && g_cvDM_headshot_only_allow_client.BoolValue))
    {
        char weapon[32];
        char grenade[32];
        GetEdictClassname(inflictor, grenade, sizeof(grenade));
        GetClientWeapon(attacker, weapon, sizeof(weapon));

        if (hitgroup == 1)
        {
            return Plugin_Continue;
        }
        else if (g_cvDM_headshot_only_allow_knife.BoolValue && (StrEqual(weapon, "weapon_knife") || StrEqual(weapon, "weapon_bayonet")))
        {
            return Plugin_Continue;
        }
        else if (g_cvDM_headshot_only_allow_nade.BoolValue && (StrEqual(grenade, "hegrenade_projectile") || StrEqual(grenade, "decoy_projectile") || StrEqual(grenade, "molotov_projectile")))
        {
            return Plugin_Continue;
        }
        else if (g_cvDM_headshot_only_allow_taser.BoolValue && StrEqual(weapon, "weapon_taser"))
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
    if (g_cvDM_no_knife_damage.BoolValue)
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

    if (g_cvDM_headshot_only.BoolValue || (g_bHSOnlyClient[attacker] && g_cvDM_headshot_only_allow_client.BoolValue))
    {
        char grenade[32];
        char weapon[32];

        if (IsValidClient(victim))
        {
            if (damagetype & DMG_FALL || attacker == 0)
            {
                if (g_cvDM_headshot_only_allow_world.BoolValue)
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
                    if (g_cvDM_headshot_only_allow_knife.BoolValue && (StrEqual(weapon, "weapon_knife") || StrEqual(weapon, "weapon_bayonet")))
                    {
                        return Plugin_Continue;
                    }
                    else if (g_cvDM_headshot_only_allow_nade.BoolValue && (StrEqual(grenade, "hegrenade_projectile") || StrEqual(grenade, "decoy_projectile") || StrEqual(grenade, "molotov_projectile")))
                    {
                        return Plugin_Continue;
                    }
                    else if (g_cvDM_headshot_only_allow_taser.BoolValue && StrEqual(weapon, "weapon_taser"))
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

public void Frame_RemoveRadar(any serial)
{
    int client = GetClientFromSerial(serial);

    if (IsValidClient(client) && IsPlayerAlive(client))
    {
        SetEntProp(client, Prop_Send, "m_iHideHUD", HIDEHUD_RADAR);
    }
}

public void Frame_GiveAmmo(any serial)
{
    int client = GetClientFromSerial(serial);

    if (g_cvDM_enabled.BoolValue && (g_cvDM_replenish_ammo.BoolValue || g_cvDM_replenish_ammo_reserve.BoolValue || g_cvDM_replenish_ammo_clip.BoolValue))
    {
        if (IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client))
        {
            RequestFrame(Frame_RefillWeapons, GetClientSerial(client));
        }
    }
}

public void Frame_RefillWeapons(any serial)
{
    int client = GetClientFromSerial(serial);
    int weaponEntity;

    if(IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client))
    {
        if (g_cvDM_replenish_ammo.BoolValue || (g_cvDM_replenish_ammo_reserve.BoolValue && g_cvDM_replenish_ammo_clip.BoolValue))
        {
            weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
            if (weaponEntity != -1)
                DoFullRefillAmmo(EntIndexToEntRef(weaponEntity), client);

            weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
            if (weaponEntity != -1)
                DoFullRefillAmmo(EntIndexToEntRef(weaponEntity), client);
        }
        else if (g_cvDM_replenish_ammo_clip.BoolValue)
        {
            weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
            if (weaponEntity != -1)
                DoClipRefillAmmo(EntIndexToEntRef(weaponEntity), client);

            weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
            if (weaponEntity != -1)
                DoClipRefillAmmo(EntIndexToEntRef(weaponEntity), client);
        }
        else if (g_cvDM_replenish_ammo_reserve.BoolValue)
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

        SetEntData(client, g_iAmmoOffset, maxAmmoCount, true);
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
        int ammoType = GetEntData(weaponEntity, g_iAmmoTypeOffset);

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

        SetEntData(client, g_iAmmoOffset + (ammoType * 4), maxAmmoCount, true);
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
        int ammoType = GetEntData(weaponEntity, g_iAmmoTypeOffset);

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

        SetEntData(client, g_iAmmoOffset + (ammoType * 4), maxAmmoCount, true);
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
    if (g_cvDM_enabled.BoolValue && g_cvDM_remove_objectives.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        StripC4(client);
    }
}

public Action Respawn(Handle timer, any serial)
{
    int client = GetClientFromSerial(serial);
    if (!g_bRoundEnded && IsValidClient(client) && (GetClientTeam(client) != CS_TEAM_SPECTATOR) && !IsPlayerAlive(client))
    {
        /* We set this here rather than in Event_PlayerSpawn to catch the spawn sounds which occur before Event_PlayerSpawn is called (even with EventHookMode_Pre). */
        g_bPlayerMoved[client] = false;
        CS_RespawnPlayer(client);
    }
}

void RespawnAll()
{
    for (int i = 1; i <= MaxClients; i++)
        Respawn(INVALID_HANDLE, i);
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Select)
    {
        char info[24];
        GetMenuItem(menu, param2, info, sizeof(info));
        SetClientCookie(param1, g_hWeapon_Remember_Cookie, "1");
        g_bRememberChoice[param1] = true;

        if (StrEqual(info, "New"))
        {
            if (g_cvDM_gun_menu_mode.IntValue == 1 || g_cvDM_gun_menu_mode.IntValue == 2)
            {
                BuildDisplayWeaponMenu(param1, true);
            }
            else if (g_cvDM_gun_menu_mode.IntValue == 3)
            {
                BuildDisplayWeaponMenu(param1, false);
            }
        }
        else if (StrEqual(info, "Same"))
        {
            if (g_bWeaponsGivenThisRound[param1])
            {
                CPrintToChat(param1, "[\x04DM\x01] %t", "Guns Same Spawn");
            }
            if (g_cvDM_gun_menu_mode.IntValue == 1 || g_cvDM_gun_menu_mode.IntValue == 4)
            {
                GiveSavedWeapons(param1, true, true);
            }
            else if (g_cvDM_gun_menu_mode.IntValue == 2)
            {
                GiveSavedWeapons(param1, true, false);
            }
            else if (g_cvDM_gun_menu_mode.IntValue == 3)
            {
                GiveSavedWeapons(param1, false, true);
            }
        }
        else if (StrEqual(info, "Random"))
        {
            if (g_bWeaponsGivenThisRound[param1])
            {
                CPrintToChat(param1, "[\x04DM\x01] %t", "Guns Random Spawn");
            }
            if (g_cvDM_gun_menu_mode.IntValue == 1 || g_cvDM_gun_menu_mode.IntValue == 4)
            {
                g_cPrimaryWeapon[param1] = "random";
                g_cSecondaryWeapon[param1] = "random";
                GiveSavedWeapons(param1, true, true);
            }
            else if (g_cvDM_gun_menu_mode.IntValue == 2)
            {
                g_cPrimaryWeapon[param1] = "random";
                g_cSecondaryWeapon[param1] = "none";
                GiveSavedWeapons(param1, true, false);
            }
            else if (g_cvDM_gun_menu_mode.IntValue == 3)
            {
                g_cPrimaryWeapon[param1] = "none";
                g_cSecondaryWeapon[param1] = "random";
                GiveSavedWeapons(param1, false, true);
            }
        }
    }
}

public int MenuPrimary(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[24];
        GetMenuItem(menu, param2, info, sizeof(info));
        int weaponCount;
        GetTrieValue(g_hWeaponCounts, info, weaponCount);
        int weaponLimit;
        GetTrieValue(g_hWeaponLimits, info, weaponLimit);

        if ((weaponLimit == -1) || (weaponCount < weaponLimit))
        {
            IncrementWeaponCount(info);
            DecrementWeaponCount(g_cPrimaryWeapon[param1]);
            g_cPrimaryWeapon[param1] = info;
            GiveSavedWeapons(param1, true, false);
            if (g_cvDM_gun_menu_mode.IntValue != 2)
            {
                BuildDisplayWeaponMenu(param1, false);
            }
            else
            {
                DecrementWeaponCount(g_cSecondaryWeapon[param1]);
                g_cSecondaryWeapon[param1] = "none";
                GiveSavedWeapons(param1, false, true);
                CPrintToChat(param1, "[\x04DM\x01] %t", "Guns New Spawn");
                SetClientCookie(param1, g_hWeapon_First_Cookie, "0");
                g_bFirstWeaponSelection[param1] = false;
            }
        }
        else
        {
            DecrementWeaponCount(g_cPrimaryWeapon[param1]);
            g_cPrimaryWeapon[param1] = "none";
            GiveSavedWeapons(param1, true, false);
            if (g_cvDM_gun_menu_mode.IntValue != 2)
            {
                BuildDisplayWeaponMenu(param1, false);
            }
            else
            {
                DecrementWeaponCount(g_cSecondaryWeapon[param1]);
                g_cSecondaryWeapon[param1] = "none";
                GiveSavedWeapons(param1, false, true);
                CPrintToChat(param1, "[\x04DM\x01] %t", "Guns New Spawn");
                SetClientCookie(param1, g_hWeapon_First_Cookie, "0");
                g_bFirstWeaponSelection[param1] = false;
            }
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_Exit)
        {
            DecrementWeaponCount(g_cPrimaryWeapon[param1]);
            g_cPrimaryWeapon[param1] = "none";
            GiveSavedWeapons(param1, true, false);
            if (g_cvDM_gun_menu_mode.IntValue != 2)
            {
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
        DecrementWeaponCount(g_cSecondaryWeapon[param1]);
        g_cSecondaryWeapon[param1] = info;
        GiveSavedWeapons(param1, false, true);
        CPrintToChat(param1, "[\x04DM\x01] %t", "Guns New Spawn");
        SetClientCookie(param1, g_hWeapon_First_Cookie, "0");
        g_bFirstWeaponSelection[param1] = false;
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_Exit)
        {
            if ((param1 > 0) && (param1 <= MaxClients) && IsClientInGame(param1))
            {
                DecrementWeaponCount(g_cSecondaryWeapon[param1]);
                g_cSecondaryWeapon[param1] = "none";
                GiveSavedWeapons(param1, false, true);
                CPrintToChat(param1, "[\x04DM\x01] %t", "Guns New Spawn");
                SetClientCookie(param1, g_hWeapon_First_Cookie, "0");
                g_bFirstWeaponSelection[param1] = false;
            }
        }
    }
}

public Action Command_Guns(int client, int args)
{
    if (g_cvDM_enabled.BoolValue && (g_cvDM_gun_menu_mode.IntValue <= 3))
        DisplayOptionsMenu(client);
    return Plugin_Handled;
}

void GiveSavedWeapons(int client, bool primary, bool secondary)
{
    if (IsFakeClient(client))
    {
        SetClientGunModeSettings(client);
    }
    if (!g_bWeaponsGivenThisRound[client] && IsPlayerAlive(client))
    {
        if (primary && !StrEqual(g_cPrimaryWeapon[client], "none"))
        {
            if (StrEqual(g_cPrimaryWeapon[client], "random"))
            {
                /* Select random menu item (excluding "Random" option) */
                int random = GetRandomInt(0, GetArraySize(g_hPrimaryWeaponsAvailable) - 2);
                char randomWeapon[24];
                GetArrayString(g_hPrimaryWeaponsAvailable, random, randomWeapon, sizeof(randomWeapon));
                GiveSkinnedWeapon(client, randomWeapon);
                if (!IsFakeClient(client))
                    SetClientCookie(client, g_hWeapon_Primary_Cookie, "random");
            }
            else
            {
                GiveSkinnedWeapon(client, g_cPrimaryWeapon[client]);
                if (!IsFakeClient(client))
                    SetClientCookie(client, g_hWeapon_Primary_Cookie, g_cPrimaryWeapon[client]);
            }
        }
        if (secondary)
        {
            if (!StrEqual(g_cSecondaryWeapon[client], "none"))
            {
                int entityIndex = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
                if (entityIndex != -1)
                {
                    RemovePlayerItem(client, entityIndex);
                    AcceptEntityInput(entityIndex, "Kill");
                }
                if (StrEqual(g_cSecondaryWeapon[client], "random"))
                {
                    /* Select random menu item (excluding "Random" option) */
                    int random = GetRandomInt(0, GetArraySize(g_hSecondaryWeaponsAvailable) - 2);
                    char randomWeapon[24];
                    GetArrayString(g_hSecondaryWeaponsAvailable, random, randomWeapon, sizeof(randomWeapon));
                    GiveSkinnedWeapon(client, randomWeapon);
                    if (!IsFakeClient(client))
                        SetClientCookie(client, g_hWeapon_Secondary_Cookie, "random");
                }
                else
                {
                    GiveSkinnedWeapon(client, g_cSecondaryWeapon[client]);
                    if (!IsFakeClient(client))
                        SetClientCookie(client, g_hWeapon_Secondary_Cookie, g_cSecondaryWeapon[client]);
                }
                GivePlayerItem(client, "weapon_knife");
            }
            if (g_cvDM_zeus.BoolValue)
                GivePlayerItem(client, "weapon_taser");
            int clientTeam = GetClientTeam(client);
            for (int i = 0; i < g_cvDM_nades_incendiary.IntValue; i++)
            {
                if (clientTeam == CS_TEAM_CT)
                    GivePlayerItem(client, "weapon_incgrenade");
            }
            for (int i = 0; i < g_cvDM_nades_molotov.IntValue; i++)
            {
                if (clientTeam == CS_TEAM_T)
                    GivePlayerItem(client, "weapon_molotov");
            }
            for (int i = 0; i < g_cvDM_nades_decoy.IntValue; i++)
                GivePlayerItem(client, "weapon_decoy");
            for (int i = 0; i < g_cvDM_nades_flashbang.IntValue; i++)
                GivePlayerItem(client, "weapon_flashbang");
            for (int i = 0; i < g_cvDM_nades_he.IntValue; i++)
                GivePlayerItem(client, "weapon_hegrenade");
            for (int i = 0; i < g_cvDM_nades_smoke.IntValue; i++)
                GivePlayerItem(client, "weapon_smokegrenade");
            for (int i = 0; i < g_cvDM_nades_tactical.IntValue; i++)
                GivePlayerItem(client, "weapon_tagrenade");
            g_bWeaponsGivenThisRound[client] = true;
            g_bRememberChoice[client] = true;
            if (!IsFakeClient(client))
                SetClientCookie(client, g_hWeapon_Remember_Cookie, "1");
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
    if (g_cvDM_enabled.BoolValue && g_cvDM_remove_weapons.BoolValue)
    {
        int maxEntities = GetMaxEntities();
        char class[24];

        for (int i = MaxClients + 1; i < maxEntities; i++)
        {
            if (IsValidEdict(i) && (GetEntDataEnt2(i, g_iOwnerOffset) == -1))
            {
                GetEdictClassname(i, class, sizeof(class));
                if ((StrContains(class, "weapon_") != -1) || (StrContains(class, "item_") != -1))
                {
                    if (StrEqual(class, "weapon_c4"))
                    {
                        if (!g_cvDM_remove_objectives.BoolValue)
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
        SetPlayerColor(client, g_iColorT);
    else if (clientTeam == CS_TEAM_CT)
        SetPlayerColor(client, g_iColorCT);
    /* Create timer to remove spawn protection */
    CreateTimer(g_cvDM_spawn_time.FloatValue, DisableSpawnProtection, client);
}

public Action DisableSpawnProtection(Handle timer, any client)
{
    if (IsValidClient(client) && (GetClientTeam(client) != CS_TEAM_SPECTATOR) && IsPlayerAlive(client))
    {
        /* Enable damage */
        SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
        /* Set player color */
        SetPlayerColor(client, g_iDefaultColor);
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
    Format(editModeItem, sizeof(editModeItem), "%s Edit Mode", (!g_bInEditMode) ? "Enable" : "Disable");
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
            g_bInEditMode = !g_bInEditMode;
            if (g_bInEditMode)
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
                TeleportEntity(param1, g_fSpawnPositions[spawnPoint], g_fSpawnAngles[spawnPoint], NULL_VECTOR);
                g_iLastEditorSpawnPoint[param1] = spawnPoint;
                CPrintToChat(param1, "[\x04DM\x01] %t #%i (%i total).", "Spawn Editor Teleported", spawnPoint + 1, g_iSpawnPointCount);
            }
        }
        else if (StrEqual(info, "Previous"))
        {
            if (g_iSpawnPointCount == 0)
                CPrintToChat(param1, "[\x04DM\x01] %t", "Spawn Editor No Spawn");
            else
            {
                int spawnPoint = g_iLastEditorSpawnPoint[param1] - 1;
                if (spawnPoint < 0)
                    spawnPoint = g_iSpawnPointCount - 1;
                TeleportEntity(param1, g_fSpawnPositions[spawnPoint], g_fSpawnAngles[spawnPoint], NULL_VECTOR);
                g_iLastEditorSpawnPoint[param1] = spawnPoint;
                CPrintToChat(param1, "[\x04DM\x01] %t #%i (%i total).", "Spawn Editor Teleported", spawnPoint + 1, g_iSpawnPointCount);
            }
        }
        else if (StrEqual(info, "Next"))
        {
            if (g_iSpawnPointCount == 0)
                CPrintToChat(param1, "[\x04DM\x01] %t", "Spawn Editor No Spawn");
            else
            {
                int spawnPoint = g_iLastEditorSpawnPoint[param1] + 1;
                if (spawnPoint >= g_iSpawnPointCount)
                    spawnPoint = 0;
                TeleportEntity(param1, g_fSpawnPositions[spawnPoint], g_fSpawnAngles[spawnPoint], NULL_VECTOR);
                g_iLastEditorSpawnPoint[param1] = spawnPoint;
                CPrintToChat(param1, "[\x04DM\x01] %t #%i (%i total).", "Spawn Editor Teleported", spawnPoint + 1, g_iSpawnPointCount);
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
                CPrintToChat(param1, "[\x04DM\x01] %t #%i (%i total).", "Spawn Editor Deleted Spawn", spawnPoint + 1, g_iSpawnPointCount);
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
            g_iSpawnPointCount = 0;
            CPrintToChat(param1, "[\x04DM\x01] %t", "Spawn Editor Deleted All");
        }
        DisplayMenu(BuildSpawnEditorMenu(), param1, MENU_TIME_FOREVER);
    }
}

public Action RenderSpawnPoints(Handle timer)
{
    if (!g_bInEditMode)
        return Plugin_Stop;

    for (int i = 0; i < g_iSpawnPointCount; i++)
    {
        float spawnPosition[3];
        AddVectors(g_fSpawnPositions[i], g_fSpawnPointOffset, spawnPosition);
        TE_SetupGlowSprite(spawnPosition, g_iGlowSprite, 1.0, 0.5, 255);
        TE_SendToAll();
    }
    return Plugin_Continue;
}

int GetNearestSpawn(int client)
{
    if (g_iSpawnPointCount == 0)
    {
        CPrintToChat(client, "[\x04DM\x01] %t", "Spawn Editor No Spawn");
        return -1;
    }

    float clientPosition[3];
    GetClientAbsOrigin(client, clientPosition);

    int nearestPoint = 0;
    float nearestPointDistance = GetVectorDistance(g_fSpawnPositions[0], clientPosition, true);

    for (int i = 1; i < g_iSpawnPointCount; i++)
    {
        float distance = GetVectorDistance(g_fSpawnPositions[i], clientPosition, true);
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
    if (g_iSpawnPointCount >= MAX_SPAWNS)
    {
        CPrintToChat(client, "[\x04DM\x01] %t", "Spawn Editor Spawn Not Added");
        return;
    }
    GetClientAbsOrigin(client, g_fSpawnPositions[g_iSpawnPointCount]);
    GetClientAbsAngles(client, g_fSpawnAngles[g_iSpawnPointCount]);
    g_iSpawnPointCount++;
    CPrintToChat(client, "[\x04DM\x01] %t", "Spawn Editor Spawn Added", g_iSpawnPointCount, g_iSpawnPointCount);
}

void InsertSpawn(int client)
{
    if (g_iSpawnPointCount >= MAX_SPAWNS)
    {
        CPrintToChat(client, "[\x04DM\x01] %t", "Spawn Editor Spawn Not Added");
        return;
    }

    if (g_iSpawnPointCount == 0)
        AddSpawn(client);
    else
    {
        /* Move spawn points down the list to make room for insertion. */
        for (int i = g_iSpawnPointCount - 1; i >= g_iLastEditorSpawnPoint[client]; i--)
        {
            g_fSpawnPositions[i + 1] = g_fSpawnPositions[i];
            g_fSpawnAngles[i + 1] = g_fSpawnAngles[i];
        }
        /* Insert new spawn point. */
        GetClientAbsOrigin(client, g_fSpawnPositions[g_iLastEditorSpawnPoint[client]]);
        GetClientAbsAngles(client, g_fSpawnAngles[g_iLastEditorSpawnPoint[client]]);
        g_iSpawnPointCount++;
        CPrintToChat(client, "[\x04DM\x01] %t #%i (%i total).", "Spawn Editor Spawn Inserted", g_iLastEditorSpawnPoint[client] + 1, g_iSpawnPointCount);
    }
}

void DeleteSpawn(int spawnIndex)
{
    for (int i = spawnIndex; i < (g_iSpawnPointCount - 1); i++)
    {
        g_fSpawnPositions[i] = g_fSpawnPositions[i + 1];
        g_fSpawnAngles[i] = g_fSpawnAngles[i + 1];
    }
    g_iSpawnPointCount--;
}

/* Updates the occupation status of all spawn points. */
public Action UpdateSpawnPointStatus(Handle timer)
{
    if (g_cvDM_enabled.BoolValue && (g_iSpawnPointCount > 0))
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
        for (int i = 0; i < g_iSpawnPointCount; i++)
        {
            g_bSpawnPointOccupied[i] = false;
            for (int j = 0; j < numberOfAlivePlayers; j++)
            {
                float distance = GetVectorDistance(g_fSpawnPositions[i], playerPositions[j], true);
                if (distance < 10000.0)
                {
                    g_bSpawnPointOccupied[i] = true;
                    break;
                }
            }
        }
    }
    return Plugin_Continue;
}

void MovePlayer(int client)
{
    g_iNumberOfPlayerSpawns++; /* Stats */

    int clientTeam = GetClientTeam(client);

    int spawnPoint;
    bool spawnPointFound = false;

    float enemyEyePositions[MAXPLAYERS+1][3];
    int numberOfEnemies = 0;

    /* Retrieve enemy positions if required by LoS/distance spawning (at eye level for LoS checking). */
    if (g_cvDM_los_spawning.BoolValue || (g_cvDM_spawn_distance.FloatValue > 0.0))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && (GetClientTeam(i) != CS_TEAM_SPECTATOR) && IsPlayerAlive(i))
            {
                bool enemy = (g_cvDM_free_for_all.BoolValue || (GetClientTeam(i) != clientTeam));
                if (enemy)
                {
                    GetClientEyePosition(i, enemyEyePositions[numberOfEnemies]);
                    numberOfEnemies++;
                }
            }
        }
    }

    if (g_cvDM_los_spawning.BoolValue)
    {
        g_iLosSearchAttempts++; /* Stats */

        /* Try to find a suitable spawn point with a clear line of sight. */
        for (int i = 0; i < g_cvDM_los_attempts.IntValue; i++)
        {
            spawnPoint = GetRandomInt(0, g_iSpawnPointCount - 1);

            if (g_bSpawnPointOccupied[spawnPoint])
                continue;

            if (g_cvDM_spawn_distance.FloatValue > 0.0)
            {
                if (!IsPointSuitableDistance(spawnPoint, enemyEyePositions, numberOfEnemies))
                    continue;
            }

            float spawnPointEyePosition[3];
            AddVectors(g_fSpawnPositions[spawnPoint], g_fEyeOffset, spawnPointEyePosition);

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
            g_iLosSearchSuccesses++;
        else
            g_iLosSearchFailures++;
    }

    /* First fallback. Find a random unccupied spawn point at a suitable distance. */
    if (!spawnPointFound && (g_cvDM_spawn_distance.FloatValue > 0.0))
    {
        g_iDistanceSearchAttempts++; /* Stats */

        for (int i = 0; i < 100; i++)
        {
            spawnPoint = GetRandomInt(0, g_iSpawnPointCount - 1);
            if (g_bSpawnPointOccupied[spawnPoint])
                continue;

            if (!IsPointSuitableDistance(spawnPoint, enemyEyePositions, numberOfEnemies))
                continue;

            spawnPointFound = true;
            break;
        }
        /* Stats */
        if (spawnPointFound)
            g_iDistanceSearchSuccesses++;
        else
            g_iDistanceSearchFailures++;
    }

    /* Final fallback. Find a random unoccupied spawn point. */
    if (!spawnPointFound)
    {
        for (int i = 0; i < 100; i++)
        {
            spawnPoint = GetRandomInt(0, g_iSpawnPointCount - 1);
            if (!g_bSpawnPointOccupied[spawnPoint])
            {
                spawnPointFound = true;
                break;
            }
        }
    }

    if (spawnPointFound)
    {
        TeleportEntity(client, g_fSpawnPositions[spawnPoint], g_fSpawnAngles[spawnPoint], NULL_VECTOR);
        g_bSpawnPointOccupied[spawnPoint] = true;
        g_bPlayerMoved[client] = true;
    }

    if (!spawnPointFound) g_iSpawnPointSearchFailures++; /* Stats */
}

bool IsPointSuitableDistance(int spawnPoint, float[][3] enemyEyePositions, int numberOfEnemies)
{
    for (int i = 0; i < numberOfEnemies; i++)
    {
        float distance = GetVectorDistance(g_fSpawnPositions[spawnPoint], enemyEyePositions[i], true);
        if (distance < g_cvDM_spawn_distance.FloatValue)
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
    g_iNumberOfPlayerSpawns = 0;
    g_iLosSearchAttempts = 0;
    g_iLosSearchSuccesses = 0;
    g_iLosSearchFailures = 0;
    g_iDistanceSearchAttempts = 0;
    g_iDistanceSearchSuccesses = 0;
    g_iDistanceSearchFailures = 0;
    g_iSpawnPointSearchFailures = 0;
}

void DisplaySpawnStats(int client)
{
    char text[64];
    Handle panel = CreatePanel();
    SetPanelTitle(panel, "Spawn Stats:");
    Format(text, sizeof(text), "Number of player spawns: %i", g_iNumberOfPlayerSpawns);
    DrawPanelText(panel, text);
    Format(text, sizeof(text), "LoS search success rate: %.2f\%", (float(g_iLosSearchSuccesses) / float(g_iLosSearchAttempts)) * 100);
    DrawPanelItem(panel, text);
    Format(text, sizeof(text), "LoS search failure rate: %.2f\%", (float(g_iLosSearchFailures) / float(g_iLosSearchAttempts)) * 100);
    DrawPanelItem(panel, text);
    Format(text, sizeof(text), "Distance search success rate: %.2f\%", (float(g_iDistanceSearchSuccesses) / float(g_iDistanceSearchAttempts)) * 100);
    DrawPanelItem(panel, text);
    Format(text, sizeof(text), "Distance search failure rate: %.2f\%", (float(g_iDistanceSearchFailures) / float(g_iDistanceSearchAttempts)) * 100);
    DrawPanelItem(panel, text);
    Format(text, sizeof(text), "Spawn point search failures: %i", g_iSpawnPointSearchFailures);
    DrawPanelItem(panel, text);
    SendPanelToClient(panel, client, PanelSpawnStats, MENU_TIME_FOREVER);
    CloseHandle(panel);
}

public int PanelSpawnStats(Menu menu, MenuAction action, int param1, int param2) { }

public Action Event_Sound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
    if (g_cvDM_enabled.BoolValue)
    {
        if (g_iSpawnPointCount > 0)
        {
            int client;
            if ((entity > 0) && (entity <= MaxClients))
                client = entity;
            else
                client = GetEntDataEnt2(entity, g_iOwnerOffset);

            /* Block ammo pickup sounds. */
            if (StrContains(sample, "pickup") != -1)
                return Plugin_Stop;

            /* Block all sounds originating from players not yet moved. */
            if ((client > 0) && (client <= MaxClients) && !g_bPlayerMoved[client])
                return Plugin_Stop;
        }
        if (g_cvDM_free_for_all.BoolValue)
        {
            if (StrContains(sample, "friendlyfire") != -1)
                return Plugin_Stop;
        }
        if (!g_cvDM_sounds_headshots.BoolValue)
        {
            if (StrContains(sample, "physics/flesh/flesh_bloody") != -1 || StrContains(sample, "player/bhit_helmet") != -1 || StrContains(sample, "player/headshot") != -1)
                return Plugin_Stop;
        }
        if (!g_cvDM_sounds_bodyshots.BoolValue)
        {
            if (StrContains(sample, "physics/body") != -1 || StrContains(sample, "physics/flesh") != -1 || StrContains(sample, "player/kevlar") != -1)
                return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_respawning.BoolValue && !g_cvDM_valvedm.BoolValue)
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
        if (g_hPrimaryMenus[client] != INVALID_HANDLE)
        {
            CancelMenu(g_hPrimaryMenus[client]);
            CloseHandle(g_hPrimaryMenus[client]);
            g_hPrimaryMenus[client] = INVALID_HANDLE;
        }
    }
    else
    {
        if (g_hSecondaryMenus[client] != INVALID_HANDLE)
        {
            CancelMenu(g_hSecondaryMenus[client]);
            CloseHandle(g_hSecondaryMenus[client]);
            g_hSecondaryMenus[client] = INVALID_HANDLE;
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

    Handle weapons = (primary) ? g_hPrimaryWeaponsAvailable : g_hSecondaryWeaponsAvailable;

    char currentWeapon[24];
    currentWeapon = (primary) ? g_cPrimaryWeapon[client] : g_cSecondaryWeapon[client];

    for (int i = 0; i < GetArraySize(weapons); i++)
    {
        char weapon[24];
        GetArrayString(weapons, i, weapon, sizeof(weapon));

        char weaponMenuName[24];
        GetTrieString(g_hWeaponMenuNames, weapon, weaponMenuName, sizeof(weaponMenuName));

        int weaponCount;
        GetTrieValue(g_hWeaponCounts, weapon, weaponCount);

        int weaponLimit;
        GetTrieValue(g_hWeaponLimits, weapon, weaponLimit);

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
        g_hPrimaryMenus[client] = menu;
        DisplayMenu(g_hPrimaryMenus[client], client, MENU_TIME_FOREVER);
    }
    else
    {
        g_hSecondaryMenus[client] = menu;
        DisplayMenu(g_hSecondaryMenus[client], client, MENU_TIME_FOREVER);
    }
}

void IncrementWeaponCount(char[] weapon)
{
    int weaponCount;
    GetTrieValue(g_hWeaponCounts, weapon, weaponCount);
    SetTrieValue(g_hWeaponCounts, weapon, weaponCount + 1);
}

void DecrementWeaponCount(char[] weapon)
{
    if (!StrEqual(weapon, "none"))
    {
        int weaponCount;
        GetTrieValue(g_hWeaponCounts, weapon, weaponCount);
        SetTrieValue(g_hWeaponCounts, weapon, weaponCount - 1);
    }
}

public Action Event_TextMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if (g_cvDM_cash_messages.BoolValue)
    {
        char text[64];
        if (GetUserMessageType() == UM_Protobuf)
            PbReadString(msg, "params", text, sizeof(text), 0);
        else
            BfReadString(msg, text, sizeof(text));

        static char cashTriggers[][] = 
        {
            "#Player_Cash_Award_Killed_Enemy",
            "#Team_Cash_Award_Win_Hostages_Rescue",
            "#Team_Cash_Award_Win_Defuse_Bomb",
            "#Team_Cash_Award_Win_Time",
            "#Team_Cash_Award_Elim_Bomb",
            "#Team_Cash_Award_Elim_Hostage",
            "#Team_Cash_Award_T_Win_Bomb",
            "#Player_Point_Award_Assist_Enemy_Plural",
            "#Player_Point_Award_Assist_Enemy",
            "#Player_Point_Award_Killed_Enemy_Plural",
            "#Player_Point_Award_Killed_Enemy",
            "#Player_Cash_Award_Kill_Hostage",
            "#Player_Cash_Award_Damage_Hostage",
            "#Player_Cash_Award_Get_Killed",
            "#Player_Cash_Award_Respawn",
            "#Player_Cash_Award_Interact_Hostage",
            "#Player_Cash_Award_Killed_Enemy",
            "#Player_Cash_Award_Rescued_Hostage",
            "#Player_Cash_Award_Bomb_Defused",
            "#Player_Cash_Award_Bomb_Planted",
            "#Player_Cash_Award_Killed_Enemy_Generic",
            "#Player_Cash_Award_Killed_VIP",
            "#Player_Cash_Award_Kill_Teammate",
            "#Team_Cash_Award_Win_Hostage_Rescue",
            "#Team_Cash_Award_Loser_Bonus",
            "#Team_Cash_Award_Loser_Zero",
            "#Team_Cash_Award_Rescued_Hostage",
            "#Team_Cash_Award_Hostage_Interaction",
            "#Team_Cash_Award_Hostage_Alive",
            "#Team_Cash_Award_Planted_Bomb_But_Defused",
            "#Team_Cash_Award_CT_VIP_Escaped",
            "#Team_Cash_Award_T_VIP_Killed",
            "#Team_Cash_Award_no_income",
            "#Team_Cash_Award_Generic",
            "#Team_Cash_Award_Custom",
            "#Team_Cash_Award_no_income_suicide",
            "#Player_Cash_Award_ExplainSuicide_YouGotCash",
            "#Player_Cash_Award_ExplainSuicide_TeammateGotCash",
            "#Player_Cash_Award_ExplainSuicide_EnemyGotCash",
            "#Player_Cash_Award_ExplainSuicide_Spectators"
        };

        for (int i = 0; i < sizeof(cashTriggers); i++)
        {
            if (StrEqual(text, cashTriggers[i]))
                return Plugin_Handled;
        }
    }
    if (g_cvDM_free_for_all.BoolValue)
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
    if (g_cvDM_free_for_all.BoolValue)
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
    if (g_cvDM_nade_messages.BoolValue)
    {
        static char grenadeTriggers[][] = 
        {
            "#SFUI_TitlesTXT_Fire_in_the_hole",
            "#SFUI_TitlesTXT_Flashbang_in_the_hole",
            "#SFUI_TitlesTXT_Smoke_in_the_hole",
            "#SFUI_TitlesTXT_Decoy_in_the_hole",
            "#SFUI_TitlesTXT_Molotov_in_the_hole",
            "#SFUI_TitlesTXT_Incendiary_in_the_hole"
        };

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
        int ragdoll = GetEntDataEnt2(client, g_iRagdollOffset);
        if (ragdoll != -1)
            AcceptEntityInput(ragdoll, "Kill");
    }
}

public int GetWeaponTeam(const char[] weapon)
{
    int team = 0;
    g_smWeaponTeams.GetValue(weapon, team);
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
