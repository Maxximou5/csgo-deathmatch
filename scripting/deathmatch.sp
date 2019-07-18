#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <csgocolors>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma newdecls required

#define PLUGIN_VERSION          "3.0.0 ALPHA"
#define PLUGIN_NAME             "[CS:GO] Deathmatch"
#define PLUGIN_AUTHOR           "Maxximou5"
#define PLUGIN_DESCRIPTION      "Enables deathmatch style gameplay (respawning, gun selection, spawn protection, etc)."
#define PLUGIN_URL              "https://github.com/Maxximou5/csgo-deathmatch/"

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

/* Console variables */
ConVar g_cvDM_enabled;
ConVar g_cvDM_config_name;
ConVar g_cvDM_enable_valve_deathmatch;
ConVar g_cvDM_welcomemsg;
ConVar g_cvDM_free_for_all;
ConVar g_cvDM_hide_radar;
ConVar g_cvDM_display_killfeed;
ConVar g_cvDM_display_killfeed_player;
ConVar g_cvDM_display_damage_panel;
ConVar g_cvDM_display_damage_popup;
ConVar g_cvDM_display_damage_text;
ConVar g_cvDM_sounds_bodyshots;
ConVar g_cvDM_sounds_headshots;
ConVar g_cvDM_headshot_only;
ConVar g_cvDM_headshot_only_allow_client;
ConVar g_cvDM_headshot_only_allow_world;
ConVar g_cvDM_headshot_only_allow_knife;
ConVar g_cvDM_headshot_only_allow_taser;
ConVar g_cvDM_headshot_only_allow_nade;
ConVar g_cvDM_respawning;
ConVar g_cvDM_respawn_time;
ConVar g_cvDM_los_spawning;
ConVar g_cvDM_los_attempts;
ConVar g_cvDM_spawn_distance;
ConVar g_cvDM_spawn_protection_time;
ConVar g_cvDM_remove_knife_damage;
ConVar g_cvDM_remove_blood;
ConVar g_cvDM_remove_cash;
ConVar g_cvDM_remove_chickens;
ConVar g_cvDM_remove_buyzones;
ConVar g_cvDM_remove_objectives;
ConVar g_cvDM_remove_ragdoll;
ConVar g_cvDM_remove_ragdoll_time;
ConVar g_cvDM_remove_spawn_weapons;
ConVar g_cvDM_remove_ground_weapons;
ConVar g_cvDM_remove_dropped_weapons;
ConVar g_cvDM_replenish_ammo_empty;
ConVar g_cvDM_replenish_ammo_reload;
ConVar g_cvDM_replenish_ammo_kill;
ConVar g_cvDM_replenish_ammo_type;
ConVar g_cvDM_replenish_ammo_hs_kill;
ConVar g_cvDM_replenish_ammo_hs_type;
ConVar g_cvDM_replenish_grenade;
ConVar g_cvDM_replenish_grenade_kill;
ConVar g_cvDM_nade_messages;
ConVar g_cvDM_cash_messages;
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
ConVar g_cvDM_gun_menu_mode;
ConVar g_cvDM_loadout_style;
ConVar g_cvDM_fast_equip;
ConVar g_cvDM_healthshot;
ConVar g_cvDM_healthshot_health;
ConVar g_cvDM_healthshot_total;
ConVar g_cvDM_healthshot_spawn;
ConVar g_cvDM_healthshot_kill;
ConVar g_cvDM_healthshot_kill_knife;
ConVar g_cvDM_zeus;
ConVar g_cvDM_zeus_spawn;
ConVar g_cvDM_zeus_kill;
ConVar g_cvDM_zeus_kill_taser;
ConVar g_cvDM_zeus_kill_knife;
ConVar g_cvDM_nades_incendiary;
ConVar g_cvDM_nades_molotov;
ConVar g_cvDM_nades_decoy;
ConVar g_cvDM_nades_flashbang;
ConVar g_cvDM_nades_he;
ConVar g_cvDM_nades_smoke;
ConVar g_cvDM_nades_tactical;
ConVar g_cvDM_armor;

/* Native Console Variables */
ConVar g_cvMP_ct_default_primary;
ConVar g_cvMP_t_default_primary;
ConVar g_cvMP_ct_default_secondary;
ConVar g_cvMP_t_default_secondary;
ConVar g_cvMP_items_prohibited;
ConVar g_cvMP_free_armor;
ConVar g_cvMP_max_armor;
ConVar g_cvMP_randomspawn;
ConVar g_cvMP_randomspawn_dist;
ConVar g_cvMP_randomspawn_los;
ConVar g_cvMP_startmoney;
ConVar g_cvMP_playercashawards;
ConVar g_cvMP_teamcashawards;
ConVar g_cvMP_friendlyfire;
ConVar g_cvMP_autokick;
ConVar g_cvMP_tkpunish;
ConVar g_cvMP_give_player_c4;
ConVar g_cvMP_death_drop_c4;
ConVar g_cvMP_death_drop_defuser;
ConVar g_cvMP_death_drop_grenade;
ConVar g_cvMP_death_drop_gun;
ConVar g_cvMP_death_drop_taser;
ConVar g_cvMP_teammates_are_enemies;
ConVar g_cvFF_damage_reduction_bullets;
ConVar g_cvFF_damage_reduction_grenade;
ConVar g_cvFF_damage_reduction_other;
ConVar g_cvSV_ignoregrenaderadio;
ConVar g_cvAmmo_grenade_limit_default;
ConVar g_cvAmmo_grenade_limit_flashbang;
ConVar g_cvAmmo_grenade_limit_total;
ConVar g_cvAmmo_item_limit_healthshot;
ConVar g_cvHealthshot_health;

/* Native Backup Variables */
char g_cBackup_mp_ct_default_primary[255];
char g_cBackup_mp_t_default_primary[255];
char g_cBackup_mp_ct_default_secondary[255];
char g_cBackup_mp_t_default_secondary[255];
char g_cBackup_mp_items_prohibited[255];
int g_iBackup_free_armor;
int g_iBackup_max_armor;
int g_iBackup_mp_randomspawn;
int g_iBackup_mp_randomspawn_dist;
int g_iBackup_mp_randomspawn_los;
int g_iBackup_mp_startmoney;
int g_iBackup_mp_playercashawards;
int g_iBackup_mp_teamcashawards;
int g_iBackup_mp_friendlyfire;
int g_iBackup_mp_autokick;
int g_iBackup_mp_tkpunish;
int g_iBackup_mp_give_player_c4;
int g_iBackup_mp_death_drop_c4;
int g_iBackup_mp_death_drop_defuser;
int g_iBackup_mp_death_drop_grenade;
int g_iBackup_mp_death_drop_gun;
int g_iBackup_mp_death_drop_taser;
int g_iBackup_mp_teammates_are_enemies;
int g_iBackup_ammo_grenade_limit_default;
int g_iBackup_ammo_grenade_limit_flashbang;
int g_iBackup_ammo_grenade_limit_total;
int g_iBackup_ammo_item_limit_healthshot;
int g_iBackup_healthshot_health;
int g_iBackup_sv_ignoregrenaderadio;
float g_fBackup_ff_damage_reduction_bullets;
float g_fBackup_ff_damage_reduction_grenade;
float g_fBackup_ff_damage_reduction_other;

/* Weapon Info */
ArrayList g_aPrimaryWeaponsAvailable;
ArrayList g_aSecondaryWeaponsAvailable;
ArrayList g_aConfigNames;
StringMap g_smWeaponMenuNames;
StringMap g_smWeaponLimits;
StringMap g_smWeaponCounts;
StringMap g_smWeaponSkinsTeam;

/* Ammo Offset */
int g_iAmmoOffset;

/* Player Variables */
char g_cPrimaryWeapon[MAXPLAYERS+1][24];
char g_cSecondaryWeapon[MAXPLAYERS+1][24];
bool g_bInEditMode = false;
bool g_bInEditModeClient[MAXPLAYERS+1] = {false, ...};
bool g_bFirstWeaponSelection[MAXPLAYERS+1] = {true, ...};
bool g_bWeaponsGivenThisRound[MAXPLAYERS+1] = {false, ...};
bool g_bRememberChoice[MAXPLAYERS+1] = {false, ...};
bool g_bInfoMessage[MAXPLAYERS+1] = {false, ... };
bool g_bPlayerMoved[MAXPLAYERS+1] = {false, ...};
bool g_bPlayerHasZeus[MAXPLAYERS+1] = {false, ...};
bool g_bDamagePanel[MAXPLAYERS+1] = {true, ...};
bool g_bDamagePopup[MAXPLAYERS+1] = {true, ...};
bool g_bDamageText[MAXPLAYERS+1] = {true, ...};
bool g_bKillFeed[MAXPLAYERS+1] = {true, ...};
bool g_bHSOnlyClient[MAXPLAYERS+1] = {false, ...};
int g_iHealthshotCount[MAXPLAYERS+1] = 0;

/* Player Color Variables */
int g_iDefaultColor[4] = {255, 255, 255, 255};
int g_iColorT[4] = {255, 0, 0, 200};
int g_iColorCT[4] = {0, 0, 255, 200};

/* Respawn Variables */
int g_iSpawnPointCount = 0;
bool g_bSpawnPointOccupied[MAX_SPAWNS] = {false, ...};
float g_fSpawnPositions[MAX_SPAWNS][3];
float g_fSpawnAngles[MAX_SPAWNS][3];
float g_fEyeOffset[3] = {0.0, 0.0, 64.0};

/* Spawn Sprites */
int g_iGlowSprite = 0;
int g_iBeamSprite = 0;
int g_iHaloSprite = 0;

/* Spawn Variables */
int g_iNumberOfPlayerSpawns = 0;
int g_iLosSearchAttempts = 0;
int g_iLosSearchSuccesses = 0;
int g_iLosSearchFailures = 0;
int g_iDistanceSearchAttempts = 0;
int g_iDistanceSearchSuccesses = 0;
int g_iDistanceSearchFailures = 0;
int g_iSpawnPointSearchFailures = 0;
int g_iLastEditorSpawnPoint[MAXPLAYERS+1] = {-1, ...};

/* Config Variables */
bool g_bRoundEnded = false;
bool g_bLoadConfig = false;
bool g_bLoadedConfig = false;
char g_cLoadConfig[PLATFORM_MAX_PATH] = "";
char g_cLoadConfigMenu[32] = "";
char g_cLoadConfigName[32] = "";

/* Menus */
TopMenu g_tmAdminMenu = null;
TopMenuObject g_tmoDMCommands;
Handle g_hCookieMenus[MAXPLAYERS+1];
Handle g_hWeaponsMenus[MAXPLAYERS+1];
Handle g_hPrimaryMenus[MAXPLAYERS+1];
Handle g_hSecondaryMenus[MAXPLAYERS+1];

/* Baked Cookies */
Handle g_hWeapon_Primary_Cookie;
Handle g_hWeapon_Secondary_Cookie;
Handle g_hWeapon_Remember_Cookie;
Handle g_hWeapon_First_Cookie;
Handle g_hDamage_Panel_Cookie;
Handle g_hDamage_Popup_Cookie;
Handle g_hDamage_Text_Cookie;
Handle g_hKillFeed_Cookie;
Handle g_hHSOnly_Cookie;

#include "deathmatch/commands.sp"
#include "deathmatch/configs.sp"
#include "deathmatch/cookies.sp"
#include "deathmatch/cvars.sp"
#include "deathmatch/events.sp"
#include "deathmatch/frames.sp"
#include "deathmatch/functions.sp"
#include "deathmatch/menus.sp"
#include "deathmatch/natives.sp"
#include "deathmatch/spawns.sp"
#include "deathmatch/weapons.sp"

public void OnPluginStart()
{
    /* Let's not waste our time here... */
    if (GetEngineVersion() != Engine_CSGO)
        SetFailState("ERROR: This plugin is designed only for CS:GO.");

    /* Load translations for multi-language */
    LoadTranslations("deathmatch.phrases");
    LoadTranslations("common.phrases");

    /* Load & Hook */
    LoadWeapons();
    LoadCvars();
    LoadConfig("deathmatch.ini");
    LoadConfigArray();
    LoadAdminMenu();
    LoadCommands();
    LoadChangeHooks();
    LoadCookies();
    HookMessages();
    HookEvents();
    HookTempEnts();
    HookSounds();

    /* SDK Hooks For Clients */
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
            OnClientPutInServer(i);
    }

    /* Update and Retrieve */
    RetrieveVariables();
    State_Update();
}

public void OnPluginEnd()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        Timer_DisableSpawnProtection(INVALID_HANDLE, i);
        OnClientDisconnect(i);
        if (g_hCookieMenus[i] != INVALID_HANDLE)
            CancelMenu(g_hCookieMenus[i])
        if (g_hWeaponsMenus[i] != INVALID_HANDLE)
            CancelMenu(g_hWeaponsMenus[i]);
        if (g_hPrimaryMenus[i] != INVALID_HANDLE)
            CancelMenu(g_hPrimaryMenus[i]);
        if (g_hSecondaryMenus[i] != INVALID_HANDLE)
            CancelMenu(g_hSecondaryMenus[i]);
    }
    State_SetBuyZones("Enable");
    State_SetObjectives("Enable");
    State_RestoreSpawnPoints();
    State_RestoreSpawnWeapons();
    State_RestoreCash();
    State_RestoreGrenade();
    State_DisableFFA();
}

public void OnConfigsExecuted()
{
    RetrieveVariables();
    State_Update();
}

public void OnMapStart()
{
    /* Precache Sprite */
    g_iGlowSprite = PrecacheModel("sprites/glow01.vmt", true);
    g_iBeamSprite = PrecacheModel("sprites/laserbeam.vmt", true);
    g_iHaloSprite = PrecacheModel("sprites/halo.vmt", true);

    InitialiseWeaponCounts();
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i))
            Client_ResetClientSettings(i);
    }
    if (LoadMapConfig())
    {
        if (g_iSpawnPointCount > 0)
        {
            for (int i = 0; i < g_iSpawnPointCount; i++)
                g_bSpawnPointOccupied[i] = false;
        }
    }
    else
        State_SetSpawnPoints();
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_TraceAttack, Hook_OnTraceAttack);
    SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
    SDKHook(client, SDKHook_WeaponEquip, Hook_OnWeaponEquip)
    SDKHook(client, SDKHook_WeaponSwitch, Hook_OnWeaponSwitch)
}

public void OnClientPostAdminCheck(int client)
{
    if (g_cvDM_enabled.BoolValue)
        Client_ResetClientSettings(client);
}

public void OnClientDisconnect(int client)
{
    SDKUnhook(client, SDKHook_TraceAttack, Hook_OnTraceAttack);
    SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
    SDKUnhook(client, SDKHook_WeaponEquip, Hook_OnWeaponEquip);
    SDKUnhook(client, SDKHook_WeaponSwitch, Hook_OnWeaponSwitch);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    static char menuTriggers[][] = {"gun", "!gun", "/gun", "guns", "!guns", "/guns", "menu", "!menu", "/menu", "weapon", "!weapon", "/weapon", "weapons", "!weapons", "/weapons"};
    static char hsOnlyTriggers[][] = {"hs", "!hs", "/hs", "headshot", "!headshot", "/headshot"};

    if (g_cvDM_enabled.BoolValue && client && IsClientInGame(client) && (GetClientTeam(client) > CS_TEAM_SPECTATOR))
    {
        if (StrEqual(sArgs, "settings", false))
        {
            ShowCookieMenu(client);
            return Plugin_Stop;
        }
        for (int i = 0; i < sizeof(menuTriggers); i++)
        {
            if (StrEqual(sArgs, menuTriggers[i], false))
            {
                if (g_cvDM_gun_menu_mode.IntValue == 1 || g_cvDM_gun_menu_mode.IntValue == 2 || g_cvDM_gun_menu_mode.IntValue == 3)
                    BuildWeaponsMenu(client);
                else
                    CPrintToChat(client, "%t %t", "Chat Tag", "Guns Disabled");
                return Plugin_Stop;
            }
        }
        if (g_cvDM_headshot_only_allow_client.BoolValue)
        {
            for (int i = 0; i < sizeof(hsOnlyTriggers); i++)
            {
                if (StrEqual(sArgs, hsOnlyTriggers[i], false))
                {
                    Client_ToggleHSOnly(client);
                    return Plugin_Stop;
                }
            }
        }
    }
    return Plugin_Continue;
}

public void OnClientCookiesCached(int client)
{
    char cPrimary[24];
    char cSecondary[24];
    char cRemember[24];
    char cFirst[24];
    char cDPanel[24];
    char cDPopup[24];
    char cDText[24];
    char cKillFeed[24];
    char cHSOnly[24];

    GetClientCookie(client, g_hWeapon_Primary_Cookie, cPrimary, sizeof(cPrimary));
    GetClientCookie(client, g_hWeapon_Secondary_Cookie, cSecondary, sizeof(cSecondary));
    GetClientCookie(client, g_hWeapon_Remember_Cookie, cRemember, sizeof(cRemember));
    GetClientCookie(client, g_hWeapon_First_Cookie, cFirst, sizeof(cFirst));
    GetClientCookie(client, g_hDamage_Panel_Cookie, cDPanel, sizeof(cDPanel));
    GetClientCookie(client, g_hDamage_Popup_Cookie, cDPopup, sizeof(cDPopup));
    GetClientCookie(client, g_hDamage_Text_Cookie, cDText, sizeof(cDText));
    GetClientCookie(client, g_hKillFeed_Cookie, cKillFeed, sizeof(cKillFeed));
    GetClientCookie(client, g_hHSOnly_Cookie, cHSOnly, sizeof(cHSOnly));

    if (!StrEqual(cPrimary, "")) g_cPrimaryWeapon[client] = cPrimary;
    else g_cPrimaryWeapon[client] = "none";
    if (!StrEqual(cSecondary, "")) g_cSecondaryWeapon[client] = cSecondary;
    else g_cSecondaryWeapon[client] = "none";
    if (!StrEqual(cRemember, "")) g_bRememberChoice[client] = view_as<bool>(StringToInt(cRemember));
    else g_bRememberChoice[client] = false;
    if (!StrEqual(cFirst, "")) g_bFirstWeaponSelection[client] = view_as<bool>(StringToInt(cFirst));
    else g_bFirstWeaponSelection[client] = false;
    if (!StrEqual(cDPanel, "")) g_bDamagePanel[client] = view_as<bool>(StringToInt(cDPanel));
    else g_bDamagePanel[client] = true;
    if (!StrEqual(cDPopup, ""))  g_bDamagePopup[client] = view_as<bool>(StringToInt(cDPopup));
    else g_bDamagePopup[client] = true;
    if (!StrEqual(cDText, "")) g_bDamageText[client] = view_as<bool>(StringToInt(cDText));
    else g_bDamageText[client] = true;
    if (!StrEqual(cKillFeed, "")) g_bKillFeed[client] = view_as<bool>(StringToInt(cKillFeed));
    else g_bKillFeed[client] = true;
    if (!StrEqual(cHSOnly, "")) g_bHSOnlyClient[client] = view_as<bool>(StringToInt(cHSOnly));
    else g_bHSOnlyClient[client] = false;
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_respawning.BoolValue && !g_cvDM_enable_valve_deathmatch.BoolValue)
    {
        if ((reason == CSRoundEnd_CTWin) || (reason == CSRoundEnd_TerroristWin))
            return Plugin_Handled;
    }
    return Plugin_Continue;
}