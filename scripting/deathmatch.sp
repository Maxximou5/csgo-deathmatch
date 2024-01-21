/**
 * [CS:GO] Deathmatch
 *
 *  Copyright (C) 2024 Maxximou5
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <cstrike>
#include <colorlib>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma newdecls required

#define PLUGIN_VERSION          "3.0.0"
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
//#define DEBUG
#define MAX_SPAWNS 200
#define HIDEHUD_RADAR 1 << 12
#define DMG_HEADSHOT (1 << 30)

/* Console variables */
ConVar g_cvDM_config_name;
ConVar g_cvDM_enabled;
ConVar g_cvDM_enable_valve_deathmatch;
ConVar g_cvDM_welcomemsg;
ConVar g_cvDM_infomsg;
ConVar g_cvDM_free_for_all;
ConVar g_cvDM_hide_radar;
ConVar g_cvDM_reset_score;
ConVar g_cvDM_display_killfeed;
ConVar g_cvDM_display_killfeed_player;
ConVar g_cvDM_display_killfeed_player_allow_client;
ConVar g_cvDM_display_damage_panel;
ConVar g_cvDM_display_damage_panel_allow_client;
ConVar g_cvDM_display_damage_popup;
ConVar g_cvDM_display_damage_popup_allow_client;
ConVar g_cvDM_display_damage_text;
ConVar g_cvDM_display_damage_text_allow_client;
ConVar g_cvDM_sounds_bell_hit;
ConVar g_cvDM_sounds_bell_hit_allow_client;
ConVar g_cvDM_sounds_bell_kill;
ConVar g_cvDM_sounds_bell_kill_allow_client;
ConVar g_cvDM_sounds_bell_headshot;
ConVar g_cvDM_sounds_bell_headshot_allow_client;
ConVar g_cvDM_sounds_deaths;
ConVar g_cvDM_sounds_deaths_allow_client;
ConVar g_cvDM_sounds_bodyshots;
ConVar g_cvDM_sounds_bodyshots_allow_client;
ConVar g_cvDM_sounds_headshots;
ConVar g_cvDM_sounds_headshots_allow_client;
ConVar g_cvDM_sounds_gunshots;
ConVar g_cvDM_sounds_gunshots_allow_client;
ConVar g_cvDM_sounds_gunshots_distance;
ConVar g_cvDM_headshot_only;
ConVar g_cvDM_headshot_only_allow_client;
ConVar g_cvDM_headshot_only_allow_world;
ConVar g_cvDM_headshot_only_allow_knife;
ConVar g_cvDM_headshot_only_allow_taser;
ConVar g_cvDM_headshot_only_allow_nade;
ConVar g_cvDM_respawn;
ConVar g_cvDM_respawn_time;
ConVar g_cvDM_respawn_valve;
ConVar g_cvDM_spawn_default;
ConVar g_cvDM_spawn_los;
ConVar g_cvDM_spawn_los_attempts;
ConVar g_cvDM_spawn_distance;
ConVar g_cvDM_spawn_distance_attempts;
ConVar g_cvDM_spawn_protection_time;
ConVar g_cvDM_remove_knife_damage;
ConVar g_cvDM_remove_blood_player;
ConVar g_cvDM_remove_blood_walls;
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
ConVar g_cvDM_hp_enable;
ConVar g_cvDM_hp_start;
ConVar g_cvDM_hp_max;
ConVar g_cvDM_hp_kill;
ConVar g_cvDM_hp_headshot;
ConVar g_cvDM_hp_knife;
ConVar g_cvDM_hp_nade;
ConVar g_cvDM_hp_messages;
ConVar g_cvDM_ap_enable;
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

/* Cookie Preferences */
ConVar g_cvDM_cookie_damage_panel;
ConVar g_cvDM_cookie_damage_popup;
ConVar g_cvDM_cookie_damage_text;
ConVar g_cvDM_cookie_killfeed;
ConVar g_cvDM_cookie_sounds_death;
ConVar g_cvDM_cookie_sounds_gunshots;
ConVar g_cvDM_cookie_sounds_bodyshots;
ConVar g_cvDM_cookie_sounds_headshots;
ConVar g_cvDM_cookie_headshot_only;
ConVar g_cvDM_cookie_bell_hit;
ConVar g_cvDM_cookie_bell_kill;
ConVar g_cvDM_cookie_bell_headshot;

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
char g_sBackup_mp_ct_default_primary[255];
char g_sBackup_mp_t_default_primary[255];
char g_sBackup_mp_ct_default_secondary[255];
char g_sBackup_mp_t_default_secondary[255];
char g_sBackup_mp_items_prohibited[255];
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
ArrayList g_aWeaponsList;
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
char g_sPrimaryWeapon[MAXPLAYERS+1][32];
char g_sSecondaryWeapon[MAXPLAYERS+1][32];
char g_sPrimaryWeaponPrevious[MAXPLAYERS+1][32];
char g_sSecondaryWeaponPrevious[MAXPLAYERS+1][32];
bool g_bInEditMode = false;
bool g_bInEditModeClient[MAXPLAYERS+1] = {false, ...};
bool g_bWeaponsGivenThisRound[MAXPLAYERS+1] = {false, ...};
bool g_bGiveFullLoadout[MAXPLAYERS+1] = {false, ...};
bool g_bRememberChoice[MAXPLAYERS+1] = {false, ...};
bool g_bWelcomeMessage[MAXPLAYERS+1] = {false, ... };
bool g_bInfoMessage[MAXPLAYERS+1] = {false, ... };
bool g_bPlayerMoved[MAXPLAYERS+1] = {false, ...};
bool g_bPlayerHasZeus[MAXPLAYERS+1] = {false, ...};
bool g_bDamagePanel[MAXPLAYERS+1] = {false, ...};
bool g_bDamagePopup[MAXPLAYERS+1] = {false, ...};
bool g_bDamageText[MAXPLAYERS+1] = {false, ...};
bool g_bKillFeed[MAXPLAYERS+1] = {false, ...};
bool g_bSoundDeaths[96] = {false, ...};
bool g_bSoundGunShots[96] = {false, ...};
bool g_bSoundBodyShots[96] = {false, ...};
bool g_bSoundHSShots[96] = {false, ...};
bool g_bHSOnlyClient[MAXPLAYERS+1] = {false, ...};
bool g_bBellHit[MAXPLAYERS+1] = {false, ...};
bool g_bBellKill[MAXPLAYERS+1] = {false, ...};
bool g_bBellHeadshot[MAXPLAYERS+1] = {false, ...};
int g_iHealthshotCount[MAXPLAYERS+1] = 0;
int g_iDamageDone[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_iDamageDoneHits[MAXPLAYERS + 1][MAXPLAYERS + 1];

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
char g_sLoadConfig[PLATFORM_MAX_PATH] = "";
char g_sLoadConfigMenu[32] = "";
char g_sLoadConfigName[32] = "";

/* Menus */
TopMenu g_tmAdminMenu = null;
TopMenuObject g_tmoDMCommands;

/* Baked Cookies */
Handle g_hWeapon_Primary_Cookie;
Handle g_hWeapon_Secondary_Cookie;
Handle g_hWeapon_Remember_Cookie;
Handle g_hDamage_Panel_Cookie;
Handle g_hDamage_Popup_Cookie;
Handle g_hDamage_Text_Cookie;
Handle g_hKillFeed_Cookie;
Handle g_hSoundDeath_Cookie;
Handle g_hSoundGunShots_Cookie;
Handle g_hSoundBodyShots_Cookie;
Handle g_hSoundHSShots_Cookie;
Handle g_hHSOnly_Cookie;
Handle g_hBellKill_Cookie;
Handle g_hBellHit_Cookie;
Handle g_hBellHeadshot_Cookie;

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
    HookMessages();
    HookEvents();
    HookTempEnts();
    HookSounds();
    LoadWeapons();
    LoadCvars();
    LoadConfig("deathmatch.ini");
    LoadConfigArray();
    LoadAdminMenu();
    LoadCommands();
    LoadChangeHooks();
    LoadCookies();

    /* SDK Hooks For Clients */
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i)) continue;
        OnClientPutInServer(i);
    }

    /* Update and Retrieve */
    RetrieveVariables();
    State_Update();
}

public void OnPluginEnd()
{
    State_DisableDM()
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

    InitializeWeaponCounts();
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;
        Client_ResetClientSettings(i);
        g_bInfoMessage[i] = false;
        g_bWelcomeMessage[i] = false;
    }
    if (LoadMapConfig())
    {
        if (g_iSpawnPointCount > 0)
        {
            for (int i = 0; i < g_iSpawnPointCount; i++)
                g_bSpawnPointOccupied[i] = false;
        }
    }
    else if (!g_cvDM_spawn_default.BoolValue)
        State_SetSpawnPoints();

    State_Update();
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
    if (!IsFakeClient(client))
    {
        DecrementWeaponCount(g_sPrimaryWeapon[client]);
        DecrementWeaponCount(g_sSecondaryWeapon[client]);
    }

    SDKUnhook(client, SDKHook_TraceAttack, Hook_OnTraceAttack);
    SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
    SDKUnhook(client, SDKHook_WeaponEquip, Hook_OnWeaponEquip);
    SDKUnhook(client, SDKHook_WeaponSwitch, Hook_OnWeaponSwitch);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    static char menuTriggers[][] = {"gun", "!gun", "/gun", "guns", "!guns", "/guns", "menu", "!menu", "/menu", "weapon", "!weapon", "/weapon", "weapons", "!weapons", "/weapons"};
    static char settingsTriggers[][] = {"settings", "!settings", "/settings"};
    static char headshotTriggers[][] = {"hs", "!hs", "/hs", "headshot", "!headshot", "/headshot"};
    static char resetTriggers[][] = {"reset", "!reset", "/reset"};

    if (g_cvDM_enabled.BoolValue && IsValidClient(client, false) && GetClientTeam(client) > CS_TEAM_SPECTATOR)
    {
        for (int i = 0; i < sizeof(menuTriggers); i++)
        {
            if (strcmp(sArgs, menuTriggers[i], false) == 0)
            {
                if (g_cvDM_gun_menu_mode.IntValue == 1 || g_cvDM_gun_menu_mode.IntValue == 2 || g_cvDM_gun_menu_mode.IntValue == 3)
                    BuildWeaponsMenu(client);
                else
                    CPrintToChat(client, "%t %t", "Chat Tag", "Guns Menu Disabled");
                return Plugin_Stop;
            }
        }

        for (int i = 0; i < sizeof(settingsTriggers); i++)
        {
            if (strcmp(sArgs, settingsTriggers[i], false) == 0)
            {
                ShowCookieMenu(client);
                return Plugin_Stop;
            }
        }

        for (int i = 0; i < sizeof(headshotTriggers); i++)
        {
            if (strcmp(sArgs, headshotTriggers[i], false) == 0)
            {
                if (g_cvDM_headshot_only_allow_client.BoolValue)
                {
                    Client_ToggleHSOnly(client);
                    return Plugin_Stop;
                }
                else
                    CPrintToChat(client, "%t %t", "Chat Tag", "Headshot Only Disabled");

            }
        }

        for (int i = 0; i < sizeof(resetTriggers); i++)
        {
            if (strcmp(sArgs, resetTriggers[i], false) == 0)
            {
                if (g_cvDM_reset_score.BoolValue && CheckCommandAccess(client, "dm_access_reset", ADMFLAG_RESERVATION))
                {
                    Client_ResetScoreboard(client);
                    return Plugin_Stop;
                }
                else
                    CPrintToChat(client, "%t %t", "Chat Tag", "Reset Score Disabled");

            }
        }
    }
    return Plugin_Continue;
}

public void OnClientCookiesCached(int client)
{
    if (!IsFakeClient(client))
    {
        char sBuffer[24];
        char sPrimary[32];
        char sSecondary[32];
        char sRemember[24];
        char sDPanel[24];
        char sDPopup[24];
        char sDText[24];
        char sKillFeed[24];
        char sHSOnly[24];
        char sSoundDeath[24];
        char sSoundGunShots[24];
        char sSoundBodyShots[24];
        char sSoundHSShots[24];
        char sBellKill[24];
        char sBellHit[24];
        char sBellHeadshot[24];

        GetClientCookie(client, g_hWeapon_Primary_Cookie, sPrimary, sizeof(sPrimary));
        GetClientCookie(client, g_hWeapon_Secondary_Cookie, sSecondary, sizeof(sSecondary));
        GetClientCookie(client, g_hWeapon_Remember_Cookie, sRemember, sizeof(sRemember));
        GetClientCookie(client, g_hDamage_Panel_Cookie, sDPanel, sizeof(sDPanel));
        GetClientCookie(client, g_hDamage_Popup_Cookie, sDPopup, sizeof(sDPopup));
        GetClientCookie(client, g_hDamage_Text_Cookie, sDText, sizeof(sDText));
        GetClientCookie(client, g_hKillFeed_Cookie, sKillFeed, sizeof(sKillFeed));
        GetClientCookie(client, g_hSoundDeath_Cookie, sSoundDeath, sizeof(sSoundDeath));
        GetClientCookie(client, g_hSoundGunShots_Cookie, sSoundGunShots, sizeof(sSoundGunShots));
        GetClientCookie(client, g_hSoundBodyShots_Cookie, sSoundBodyShots, sizeof(sSoundBodyShots));
        GetClientCookie(client, g_hSoundHSShots_Cookie, sSoundHSShots, sizeof(sSoundHSShots));
        GetClientCookie(client, g_hHSOnly_Cookie, sHSOnly, sizeof(sHSOnly));
        GetClientCookie(client, g_hBellHit_Cookie, sBellHit, sizeof(sBellHit));
        GetClientCookie(client, g_hBellKill_Cookie, sBellKill, sizeof(sBellKill));
        GetClientCookie(client, g_hBellHeadshot_Cookie, sBellHeadshot, sizeof(sBellHeadshot));

        if (strcmp(sPrimary, "") == 0)
        {
            g_sPrimaryWeapon[client] = "none";
            SetClientCookie(client, g_hWeapon_Primary_Cookie, "none");
        }
        else
            g_sPrimaryWeapon[client] = sPrimary;

        if (strcmp(sSecondary, "") == 0)
        {
            g_sSecondaryWeapon[client] = "none";
            SetClientCookie(client, g_hWeapon_Secondary_Cookie, "none");
        }
        else
            g_sSecondaryWeapon[client] = sSecondary;

        if (strcmp(sRemember, "") == 0)
        {
            g_bRememberChoice[client] = false;
            SetClientCookie(client, g_hWeapon_Remember_Cookie, "0");
        }
        else
            g_bRememberChoice[client] = view_as<bool>(StringToInt(sRemember));

        if (strcmp(sDPanel, "") == 0)
        {
            g_bDamagePanel[client] = g_cvDM_cookie_damage_panel.BoolValue;
            IntToString(g_cvDM_cookie_damage_panel.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hDamage_Panel_Cookie, sBuffer);
        }
        else
            g_bDamagePanel[client] = view_as<bool>(StringToInt(sDPanel));

        if (strcmp(sDPopup, "") == 0)
        {
            g_bDamagePopup[client] = g_cvDM_cookie_damage_popup.BoolValue;
            IntToString(g_cvDM_cookie_damage_popup.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hDamage_Popup_Cookie, sBuffer);
        }
        else
            g_bDamagePopup[client] = view_as<bool>(StringToInt(sDPopup));

        if (strcmp(sDText, "") == 0)
        {
            g_bDamageText[client] = g_cvDM_cookie_damage_text.BoolValue;
            IntToString(g_cvDM_cookie_damage_text.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hDamage_Text_Cookie, sBuffer);
        }
        else
            g_bDamageText[client] = view_as<bool>(StringToInt(sDText));

        if (strcmp(sKillFeed, "") == 0)
        {
            g_bKillFeed[client] = g_cvDM_cookie_killfeed.BoolValue;
            IntToString(g_cvDM_cookie_killfeed.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hKillFeed_Cookie, sBuffer);
        }
        else
            g_bKillFeed[client] = view_as<bool>(StringToInt(sKillFeed));

        if (strcmp(sSoundDeath, "") == 0)
        {
            g_bSoundDeaths[client] = g_cvDM_cookie_sounds_death.BoolValue;
            IntToString(g_cvDM_cookie_sounds_death.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hSoundDeath_Cookie, sBuffer);
        }
        else
            g_bSoundDeaths[client] = view_as<bool>(StringToInt(sSoundDeath));

        if (strcmp(sSoundGunShots, "") == 0)
        {
            g_bSoundGunShots[client] = g_cvDM_cookie_sounds_gunshots.BoolValue;
            IntToString(g_cvDM_cookie_sounds_gunshots.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hSoundGunShots_Cookie, sBuffer);
        }
        else
            g_bSoundGunShots[client] = view_as<bool>(StringToInt(sSoundGunShots));

        if (strcmp(sSoundBodyShots, "") == 0)
        {
            g_bSoundBodyShots[client] = g_cvDM_cookie_sounds_bodyshots.BoolValue;
            IntToString(g_cvDM_cookie_sounds_bodyshots.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hSoundBodyShots_Cookie, sBuffer);
        }
        else
            g_bSoundBodyShots[client] = view_as<bool>(StringToInt(sSoundBodyShots));

        if (strcmp(sSoundHSShots, "") == 0)
        {
            g_bSoundHSShots[client] = g_cvDM_cookie_sounds_headshots.BoolValue;
            IntToString(g_cvDM_cookie_sounds_headshots.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hSoundHSShots_Cookie, sBuffer);
        }
        else
            g_bSoundHSShots[client] = view_as<bool>(StringToInt(sSoundHSShots));

        if (strcmp(sHSOnly, "") == 0)
        {
            g_bHSOnlyClient[client] = g_cvDM_cookie_headshot_only.BoolValue;
            IntToString(g_cvDM_cookie_headshot_only.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hHSOnly_Cookie, sBuffer);
        }
        else
            g_bHSOnlyClient[client] = view_as<bool>(StringToInt(sHSOnly));

        if (strcmp(sBellHit, "") == 0)
        {
            g_bBellHit[client] = g_cvDM_cookie_bell_hit.BoolValue;
            IntToString(g_cvDM_cookie_bell_hit.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hBellHit_Cookie, sBuffer);
        }
        else
            g_bBellHit[client] = view_as<bool>(StringToInt(sBellHit));

        if (strcmp(sBellKill, "") == 0)
        {
            g_bBellKill[client] = g_cvDM_cookie_bell_kill.BoolValue;
            IntToString(g_cvDM_cookie_bell_kill.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hBellKill_Cookie, sBuffer);
        }
        else
            g_bBellKill[client] = view_as<bool>(StringToInt(sBellKill));

        if (strcmp(sBellHeadshot, "") == 0)
        {
            g_bBellHeadshot[client] = g_cvDM_cookie_bell_headshot.BoolValue;
            IntToString(g_cvDM_cookie_bell_headshot.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hBellHeadshot_Cookie, sBuffer);
        }
        else
            g_bBellHeadshot[client] = view_as<bool>(StringToInt(sBellHeadshot));
    }
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_respawn.BoolValue && !g_cvDM_enable_valve_deathmatch.BoolValue)
    {
        if ((reason == CSRoundEnd_CTWin) || (reason == CSRoundEnd_TerroristWin))
            return Plugin_Handled;
    }
    return Plugin_Continue;
}