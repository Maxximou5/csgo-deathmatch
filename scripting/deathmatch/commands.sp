void LoadCommands()
{
    /* Admin Commands */
    RegAdminCmd("dm_load", Command_ConfigLoad, ADMFLAG_CHANGEMAP, "Loads the configuration file specified (configs/deathmatch/filename.ini).");
    RegAdminCmd("dm_load_menu", Command_ConfigLoadMenu, ADMFLAG_CHANGEMAP, "Opens the Config Loader Menu.");
    RegAdminCmd("dm_spawn_menu", Command_SpawnMenu, ADMFLAG_CHANGEMAP, "Opens the Spawn Editor Menu.");
    RegAdminCmd("dm_respawn_all", Command_RespawnAll, ADMFLAG_CHANGEMAP, "Respawns all players.");
    RegAdminCmd("dm_settings", Command_SettingsMenu, ADMFLAG_CHANGEMAP, "Opens the Deathmatch Settings Menu.");
    RegAdminCmd("dm_stats", Command_Stats, ADMFLAG_CHANGEMAP, "Displays spawn statistics.");
    RegAdminCmd("dm_stats_reset", Command_StatsReset, ADMFLAG_CHANGEMAP, "Resets spawn statistics.");
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

        if (StrEqual(option, "respawn", false))
            LoadTimeConfig(client, config, option);
        else if (StrEqual(option, "restart", false))
            LoadTimeConfig(client, config, option);
        else if (StrEqual(option, "nextround", false))
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

public Action Command_RespawnAll(int client, int args)
{
    if (client == 0)
    {
        RespawnAll();
        CReplyToCommand(client, "%t %t", "Chat Tag", "All Player Respawn");
        return Plugin_Handled;
    }

    RespawnAll();
    CPrintToChat(client, "%t %t", "Chat Tag", "All Player Respawn");
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


public Action Command_Stats(int client, int args)
{
    if (client == 0)
    {
        DisplaySpawnStats(client, true);
        return Plugin_Handled;
    }

    DisplaySpawnStats(client, false);
    return Plugin_Handled;
}

public Action Command_StatsReset(int client, int args)
{
    if (client == 0)
    {
        ResetSpawnStats();
        CReplyToCommand(client, "%t %t", "Chat Tag", "Spawn Stats Reset");
        return Plugin_Handled;
    }

    ResetSpawnStats();
    CPrintToChat(client, "%t %t", "Chat Tag", "Spawn Stats Reset");
    return Plugin_Handled;
}