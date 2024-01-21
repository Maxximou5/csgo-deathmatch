void LoadCommands()
{
    /* Admin Commands */
    RegAdminCmd("dm_load", Command_ConfigLoad, ADMFLAG_CHANGEMAP, "Loads the configuration file specified (configs/deathmatch/filename.ini).");
    RegAdminCmd("dm_load_menu", Command_ConfigLoadMenu, ADMFLAG_CHANGEMAP, "Opens the Config Loader Menu.");
    RegAdminCmd("dm_spawn_menu", Command_SpawnMenu, ADMFLAG_CHANGEMAP, "Opens the Spawn Editor Menu.");
    RegAdminCmd("dm_spawn_list", Command_SpawnList, ADMFLAG_CHANGEMAP, "Displays the entire spawn list for the map.");
    RegAdminCmd("dm_spawn_stats", Command_SpawnStats, ADMFLAG_CHANGEMAP, "Displays spawn statistics.");
    RegAdminCmd("dm_spawn_reset", Command_SpawnReset, ADMFLAG_CHANGEMAP, "Resets spawn statistics.");
    RegAdminCmd("dm_respawn_all", Command_RespawnAll, ADMFLAG_CHANGEMAP, "Respawns all players.");
    RegAdminCmd("dm_settings", Command_SettingsMenu, ADMFLAG_CHANGEMAP, "Opens the Deathmatch Settings Menu.");
    RegAdminCmd("dm_weapon_stats", Command_WeaponStats, ADMFLAG_CHANGEMAP, "Displays weapon statistics.");
}

public Action Command_ConfigLoad(int client, int args)
{
    if (GetCmdArgs() < 2 || GetCmdArgs() > 2)
    {
        CReplyToCommand(client, "%t Usage: dm_load \"filename.ini\" [respawn|restart|nextround]", "Chat Tag");
        return Plugin_Handled;
    }
    else
    {
        char config[PLATFORM_MAX_PATH];
        char option[PLATFORM_MAX_PATH];

        GetCmdArg(1, config, sizeof(config));
        GetCmdArg(2, option, sizeof(option));

        StripQuotes(config);
        StripQuotes(option);

        if (strcmp(option, "respawn", false) == 0)
            LoadTimeConfig(client, config, option);
        else if (strcmp(option, "restart", false) == 0)
            LoadTimeConfig(client, config, option);
        else if (strcmp(option, "nextround", false) == 0)
            LoadTimeConfig(client, config, option);
        else
        {
            CReplyToCommand(client, "%t Option not recognized \"%s\"", "Chat Tag", option);
            CReplyToCommand(client, "%t Usage: dm_load \"filename.ini\" [respawn|restart|nextround]", "Chat Tag");
        }
    }
    return Plugin_Handled;
}

public Action Command_ConfigLoadMenu(int client, int args)
{
    if (client == 0)
    {
        CReplyToCommand(client, "%t %t", "Chat Tag", "Command is in-game only");
        return Plugin_Handled;
    }

    BuildConfigMenu(client);
    return Plugin_Handled;
}

public Action Command_SpawnMenu(int client, int args)
{
    if (client == 0)
    {
        CReplyToCommand(client, "%t %t", "Chat Tag", "Command is in-game only");
        return Plugin_Handled;
    }

    BuildSpawnEditorMenu(client);
    return Plugin_Handled;
}

public Action Command_SpawnList(int client, int args)
{
    for (int i = 0; i < g_iSpawnPointCount; i++)
    {
        PrintToServer("#%i | Location = %f %f %f | Direction = %f %f %f | Occupied = %s", i, g_fSpawnPositions[i][0], g_fSpawnPositions[i][1], g_fSpawnPositions[i][2], g_fSpawnAngles[i][0], g_fSpawnAngles[i][1], g_fSpawnAngles[i][2], g_bSpawnPointOccupied[i] ? "TRUE" : "FALSE");
    }
}

public Action Command_RespawnAll(int client, int args)
{
    if (client == 0)
        CReplyToCommand(client, "%t %t", "Chat Tag", "All Player Respawn");
    else
        CPrintToChat(client, "%t %t", "Chat Tag", "All Player Respawn");

    Spawns_RespawnAll();
    return Plugin_Handled;
}

public Action Command_SettingsMenu(int client, int args)
{
    if (client == 0)
    {
        CReplyToCommand(client, "%t %t", "Chat Tag", "Command is in-game only");
        return Plugin_Handled;
    }

    ShowCookieMenu(client);
    return Plugin_Handled;
}

public Action Command_SpawnStats(int client, int args)
{
    if (client == 0)
    {
        DisplaySpawnStats(client, true);
        return Plugin_Handled;
    }

    DisplaySpawnStats(client, false);
    return Plugin_Handled;
}

public Action Command_SpawnReset(int client, int args)
{
    if (client == 0)
    {
        Spawns_ResetSpawnStats();
        CReplyToCommand(client, "%t %t", "Chat Tag", "Spawn Stats Reset");
        return Plugin_Handled;
    }

    Spawns_ResetSpawnStats();
    CPrintToChat(client, "%t %t", "Chat Tag", "Spawn Stats Reset");
    return Plugin_Handled;
}

public Action Command_WeaponStats(int client, int args)
{

    if (client == 0)
    {
        DisplayWeaponStats(client, true);
        return Plugin_Handled;
    }

    DisplayWeaponStats(client, false);
    return Plugin_Handled;
}