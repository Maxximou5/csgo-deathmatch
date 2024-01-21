/**
 * [CS:GO] Deathmatch Loader
 *
 *  Copyright (C) 2020 Maxximous 'Maxximou5' Ambrosio
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

#include <sourcemod>
#include <colorlib>

#pragma newdecls required

#define PLUGIN_VERSION          "1.0.0"
#define PLUGIN_NAME             "[CS:GO] Deathmatch Loader"
#define PLUGIN_AUTHOR           "Maxximou5"
#define PLUGIN_DESCRIPTION      "Loads Deathmatch configuration files based on events or at specified times."
#define PLUGIN_URL              "https://github.com/Maxximou5/csgo-deathmatch-loader/"

public Plugin myinfo =
{
    name                        = PLUGIN_NAME,
    author                      = PLUGIN_AUTHOR,
    description                 = PLUGIN_DESCRIPTION,
    version                     = PLUGIN_VERSION,
    url                         = PLUGIN_URL
}

#define CLIENTS     0
#define ROUND       1
#define TIMELEFT    2
#define TOTAL       3

ConVar g_hEnabled;
ConVar g_hIncludeBots;
ConVar g_hIncludeSpec;

Handle g_hTimer = null;
Handle g_hTimers[TOTAL];

SMCParser g_hConfigParser;

StringMap g_smConfig[TOTAL];
StringMap g_smTypes;

int g_iRound;
bool g_bSection;
char g_sConfigFile[PLATFORM_MAX_PATH + 1];
char g_sMap[32];

public void OnPluginStart()
{
    /* Let's not waste our time here... */
    if (GetEngineVersion() != Engine_CSGO)
        SetFailState("ERROR: This plugin is designed only for CS:GO.");

    CreateConVar("dm_m5_loader_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
    g_hEnabled = CreateConVar("dm_loader_enabled", "1", "Enable/disable executing configs");
    g_hIncludeBots = CreateConVar("dm_loader_include_bots", "1", "Enable/disable including bots when counting number of clients");
    g_hIncludeSpec = CreateConVar("dm_loader_include_spec", "1", "Enable/disable including spectators when counting number of clients");

    RegAdminCmd("dm_reload", Command_ReloadDML, ADMFLAG_CONFIG, "Reloads the deathmatch loader config.");

    BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/deathmatch/config_loader.ini");
    g_hConfigParser = new SMCParser();
    SMC_SetReaders(g_hConfigParser, ReadConfig_NewSection, ReadConfig_KeyValue, ReadConfig_EndSection);

    g_smTypes = new StringMap();
    g_smTypes.SetValue("clients", CLIENTS);
    g_smTypes.SetValue("round", ROUND);
    g_smTypes.SetValue("timeleft", TIMELEFT);

    for (int i = 0; i < TOTAL; i++)
        g_smConfig[i] = new StringMap();

    HookEvent("game_start", Event_GameStart,  EventHookMode_PostNoCopy);
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void OnMapStart()
{
    g_iRound = 0;

    for (int i = 0; i < TOTAL; i++)
        g_hTimers[i] = null;

    GetCurrentMap(g_sMap, sizeof(g_sMap));
    ParseConfig();

    g_hTimer = null;
    g_hTimer = CreateTimer(60.0, Timer_ExecTimeleftConfig, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public void OnMapEnd()
{
    g_hTimer = null;
}

public void OnMapTimeLeftChanged()
{
    if (g_hTimer != null)
        delete g_hTimer;

    int iTimeleft;
    if (GetMapTimeLeft(iTimeleft) && iTimeleft > 0)
    {
        PrintToServer("Timeleft: %i", iTimeleft);
        g_hTimer = CreateTimer(60.0, Timer_ExecTimeleftConfig, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
    }
}

public void OnClientPutInServer(int client)
{
    ExecClientsConfig(0);
}

public void OnClientDisconnect(int client)
{
    ExecClientsConfig(-1);
}

public Action Command_ReloadDML(int client, int args)
{
    if (ParseConfig())
        ReplyToCommand(client, "[DML] - Configuration file has been reloaded.");
    else
        ReplyToCommand(client, "[DML] - Configuration file has failed to reload.");
    return Plugin_Handled;
}

public void Event_GameStart(Event event, const char[] name, bool dontBroadcast)
{
    g_iRound = 0;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_iRound++;

    if (!g_hEnabled.BoolValue)
        return;

    char sRound[4];
    IntToString(g_iRound, sRound, sizeof(sRound));
    ExecConfig(ROUND, sRound);
}

public Action Timer_ExecConfig(Handle timer, any data)
{
    if (!g_hEnabled.BoolValue)
        return Plugin_Handled;

    DataPack pack = view_as<DataPack>(data);
    pack.Reset();

    char sConfig[32];
    char sOption[32];
    int iType;
    iType = pack.ReadCell();
    pack.ReadString(sConfig, sizeof(sConfig));
    pack.ReadString(sOption, sizeof(sOption));

    ServerCommand("dm_load %s %s", sConfig, sOption);
    g_hTimers[iType] = null;

    return Plugin_Handled;
}

public Action Timer_ExecTimeleftConfig(Handle timer)
{
    if (!g_hEnabled.BoolValue)
    {
        g_hTimer = null;
        return Plugin_Stop;
    }

    int iTimeleft;
    if (!GetMapTimeLeft(iTimeleft) || iTimeleft < 0)
        return Plugin_Continue;

    PrintToServer("Timeleft: %i", iTimeleft);

    char sTimeleft[4];
    IntToString(iTimeleft / 60, sTimeleft, sizeof(sTimeleft));
    ExecConfig(TIMELEFT, sTimeleft);

    PrintToServer("Timeleft: %s", sTimeleft);

    return Plugin_Continue;
}

public SMCResult ReadConfig_EndSection(Handle smc) {}

public SMCResult ReadConfig_KeyValue(Handle smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
    if (!g_bSection || !key[0])
        return SMCParse_Continue;

    int iType;
    char sKeys[2][32];
    ExplodeString(key, ":", sKeys, sizeof(sKeys), sizeof(sKeys[]));
    if (!g_smTypes.GetValue(sKeys[0], iType))
        return SMCParse_Continue;

    g_smConfig[iType].SetString(sKeys[1], value);

    return SMCParse_Continue;
}

public SMCResult ReadConfig_NewSection(Handle smc, const char[] name, bool opt_quotes)
{
    g_bSection = StrEqual(name, "*") || strncmp(g_sMap, name, strlen(name), false) == 0;
}

void ExecClientsConfig(int client)
{
    if (!g_hEnabled.BoolValue)
        return;

    bool bIncludeBots = g_hIncludeBots.BoolValue;
    bool bIncludeSpec = g_hIncludeSpec.BoolValue;

    if (bIncludeBots && bIncludeSpec)
        client += GetClientCount();
    else
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i))
                continue;

            bool bBot  = IsFakeClient(i);
            bool bSpec = IsClientObserver(i);
            if ((!bBot && !bSpec) ||
                (bIncludeBots && bBot) ||
                (bIncludeSpec && bSpec))
                client++;
        }
    }

    char sClients[4];
    IntToString(client, sClients, sizeof(sClients));
    ExecConfig(CLIENTS, sClients);
}

void ExecConfig(int iType, const char[] sKey)
{
    char sValue[64];
    if (!g_smConfig[iType].GetString(sKey, sValue, sizeof(sValue)))
        return;

    char sValues[3][32];
    ExplodeString(sValue, ":", sValues, sizeof(sValues), sizeof(sValues[]));

    DataPack pack = new DataPack();
    pack.WriteCell(iType);
    pack.WriteString(sValues[1]);
    pack.WriteString(sValues[2]);
    g_hTimers[iType] = CreateTimer(StringToFloat(sValues[0]), Timer_ExecConfig, pack, TIMER_FLAG_NO_MAPCHANGE);
}

bool ParseConfig()
{
    if (FileExists(g_sConfigFile))
    {
        for (int i = 0; i < TOTAL; i++)
            g_smConfig[i].Clear();

        SMCError err = g_hConfigParser.ParseFile(g_sConfigFile);
        if (err != SMCError_Okay)
        {
            char sError[64];
            if (g_hConfigParser.GetErrorString(err, sError, sizeof(sError)))
                LogError("[DML] ERROR: %s", sError);
            else
                LogError("[DML] ERROR: Fatal parse error");
            return false;
        }
    }
    else
    {
        SetFailState("[DML] ERROR: %s file is missing or corrupt!", g_sConfigFile);
        return false;
    }
    return true;
}