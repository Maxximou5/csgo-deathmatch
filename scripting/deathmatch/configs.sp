void LoadConfigArray()
{
    g_aConfigNames = new ArrayList(16);
}

void LoadTimeConfig(int client, char[] config, char[] option)
{
    if (StrEqual(option, "respawn", false))
    {
        if (LoadConfig(config))
            RespawnAll();
        else
            CReplyToCommand(client, "%t The configuration file: %s could not be read.", "Chat Tag", config);
    }
    else if (StrEqual(option, "restart", false))
    {
        if (LoadConfig(config))
            ServerCommand("mp_restartgame 1");
        else
            CReplyToCommand(client, "%t The configuration file: %s could not be read.", "Chat Tag", config);
    }
    else if (StrEqual(option, "nextround", false))
    {
        g_bLoadConfig = true;
        strcopy(g_cLoadConfig, sizeof(g_cLoadConfig), config);
    }
}

bool LoadConfig(char[] config)
{
    KeyValues kv = new KeyValues("Deathmatch Config");
    char path[PLATFORM_MAX_PATH];
    char buffer[PLATFORM_MAX_PATH];
    Format(buffer, sizeof(buffer), "configs/deathmatch/%s", config);
    BuildPath(Path_SM, path, sizeof(path), buffer);

    if (!kv.ImportFromFile(path))
    {
        LogError("[DM] The configuration file: %s could not be read.", path);
        return false;
    }

    if (!kv.JumpToKey("Config"))
    {
        LogError("[DM] The configuration file: %s has the following error:", path);
        LogError("[DM] The configuration file is corrupt \"Config\" section could not be found).");
        return false;
    }

    char key[25];
    char value[25];

    kv.GetString("dm_config_name", value, sizeof(value), "Default");
    g_cvDM_config_name.SetString(value);

    kv.GoBack();

    if (!kv.JumpToKey("Options"))
    {
        LogError("[DM] The configuration file: %s has the following error:", path);
        LogError("[DM] The configuration file is corrupt \"Options\" section could not be found).");
        return false;
    }

    kv.GetString("dm_enabled", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_enabled.SetString(value);

    kv.GetString("dm_enable_valve_deathmatch", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_enable_valve_deathmatch.SetString(value);

    kv.GetString("dm_welcomemsg", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_welcomemsg.SetString(value);

    kv.GetString("dm_free_for_all", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_free_for_all.SetString(value);

    kv.GetString("dm_hide_radar", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_hide_radar.SetString(value);

    kv.GetString("dm_display_killfeed", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_display_killfeed.SetString(value);

    kv.GetString("dm_display_killfeed_player", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_display_killfeed_player.SetString(value);

    kv.GetString("dm_display_damage_panel", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_display_damage_panel.SetString(value);

    kv.GetString("dm_display_damage_popup", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_display_damage_popup.SetString(value);

    kv.GetString("dm_display_damage_text", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_display_damage_text.SetString(value);

    kv.GetString("dm_sounds_bodyshots", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_sounds_bodyshots.SetString(value);

    kv.GetString("dm_sounds_headshots", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_sounds_headshots.SetString(value);

    kv.GetString("dm_headshot_only", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_headshot_only.SetString(value);

    kv.GetString("dm_headshot_only_allow_client", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_headshot_only_allow_client.SetString(value);

    kv.GetString("dm_headshot_only_allow_world", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_headshot_only_allow_world.SetString(value);

    kv.GetString("dm_headshot_only_allow_knife", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_headshot_only_allow_knife.SetString(value);

    kv.GetString("dm_headshot_only_allow_taser", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_headshot_only_allow_taser.SetString(value);

    kv.GetString("dm_headshot_only_allow_nade", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_headshot_only_allow_nade.SetString(value);

    kv.GetString("dm_remove_objectives", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_remove_objectives.SetString(value);

    kv.GetString("dm_respawn", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_respawn.SetString(value);

    kv.GetString("dm_respawn_time", value, sizeof(value), "2.0");
    g_cvDM_respawn_time.SetString(value);

    kv.GetString("dm_respawn_valve", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_respawn_valve.SetString(value);

    kv.GetString("dm_spawn_los", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_spawn_los.SetString(value);

    kv.GetString("dm_spawn_los_attempts", value, sizeof(value), "10");
    g_cvDM_spawn_los_attempts.SetString(value);

    kv.GetString("dm_spawn_distance", value, sizeof(value), "0.0");
    g_cvDM_spawn_distance.SetString(value);

    kv.GetString("dm_spawn_distance_attempts", value, sizeof(value), "10");
    g_cvDM_spawn_distance_attempts.SetString(value);

    kv.GetString("dm_spawn_protection_time", value, sizeof(value), "1.0");
    g_cvDM_spawn_protection_time.SetString(value);

    kv.GetString("dm_remove_blood", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_remove_blood.SetString(value);

    kv.GetString("dm_remove_cash", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_remove_cash.SetString(value);

    kv.GetString("dm_remove_chickens", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_remove_chickens.SetString(value);

    kv.GetString("dm_remove_ragdoll", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_remove_ragdoll.SetString(value);

    kv.GetString("dm_remove_ragdoll_time", value, sizeof(value), "1.0");
    g_cvDM_remove_ragdoll_time.SetString(value);

    kv.GetString("dm_remove_knife_damage", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_remove_knife_damage.SetString(value);

    kv.GetString("dm_remove_spawn_weapons", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_remove_spawn_weapons.SetString(value);

    kv.GetString("dm_remove_ground_weapons", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_remove_ground_weapons.SetString(value);

    kv.GetString("dm_remove_dropped_weapons", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_remove_dropped_weapons.SetString(value);

    kv.GetString("dm_replenish_ammo_empty", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_replenish_ammo_empty.SetString(value);

    kv.GetString("dm_replenish_ammo_reload", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_replenish_ammo_reload.SetString(value);

    kv.GetString("dm_replenish_ammo_kill", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_replenish_ammo_kill.SetString(value);

    kv.GetString("dm_replenish_ammo_type", value, sizeof(value), "2");
    g_cvDM_replenish_ammo_type.SetString(value);

    kv.GetString("dm_replenish_ammo_hs_kill", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_replenish_ammo_hs_kill.SetString(value);

    kv.GetString("dm_replenish_ammo_hs_type", value, sizeof(value), "1");
    g_cvDM_replenish_ammo_hs_type.SetString(value);

    kv.GetString("dm_replenish_grenade", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_replenish_grenade.SetString(value);

    kv.GetString("dm_replenish_grenade_kill", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_replenish_grenade_kill.SetString(value);

    kv.GetString("dm_nade_messages", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_nade_messages.SetString(value);

    kv.GetString("dm_cash_messages", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_cash_messages.SetString(value);

    kv.GetString("dm_hp_start", value, sizeof(value), "100");
    g_cvDM_hp_start.SetString(value);

    kv.GetString("dm_hp_max", value, sizeof(value), "100");
    g_cvDM_hp_max.SetString(value);

    kv.GetString("dm_hp_kill", value, sizeof(value), "5");
    g_cvDM_hp_kill.SetString(value);

    kv.GetString("dm_hp_headshot", value, sizeof(value), "10");
    g_cvDM_hp_headshot.SetString(value);

    kv.GetString("dm_hp_knife", value, sizeof(value), "50");
    g_cvDM_hp_knife.SetString(value);

    kv.GetString("dm_hp_nade", value, sizeof(value), "30");
    g_cvDM_hp_nade.SetString(value);

    kv.GetString("dm_hp_messages", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_hp_messages.SetString(value);

    kv.GetString("dm_ap_max", value, sizeof(value), "100");
    g_cvDM_ap_max.SetString(value);

    kv.GetString("dm_ap_kill", value, sizeof(value), "5");
    g_cvDM_ap_kill.SetString(value);

    kv.GetString("dm_ap_headshot", value, sizeof(value), "10");
    g_cvDM_ap_headshot.SetString(value);

    kv.GetString("dm_ap_knife", value, sizeof(value), "50");
    g_cvDM_ap_knife.SetString(value);

    kv.GetString("dm_ap_nade", value, sizeof(value), "30");
    g_cvDM_ap_nade.SetString(value);

    kv.GetString("dm_ap_messages", value, sizeof(value), "yes");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_ap_messages.SetString(value);

    kv.GoBack();

    if (!kv.JumpToKey("Equipment"))
    {
        LogError("[DM] The configuration file: %s has the following error:", path);
        LogError("[DM] The configuration file is corrupt \"Weapons\" section could not be found).");
        return false;
    }

    if (!kv.JumpToKey("Loadout"))
    {
        LogError("[DM] The configuration file: %s has the following error:", path);
        LogError("[DM] The configuration file is corrupt \"Loadout\" section could not be found).");
        return false;
    }

    kv.GetString("dm_gun_menu_mode", value, sizeof(value), "1");
    g_cvDM_gun_menu_mode.SetString(value);

    kv.GetString("dm_loadout_style", value, sizeof(value), "1");
    g_cvDM_loadout_style.SetString(value);

    kv.GetString("dm_fast_equip", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_fast_equip.SetString(value);

    kv.GoBack();

    if (!kv.JumpToKey("Primary"))
    {
        LogError("[DM] The configuration file: %s has the following error:", path);
        LogError("[DM] The configuration file is corrupt \"Primary\" section could not be found).");
        return false;
    }

    if (kv.GotoFirstSubKey(false))
    {
        g_smWeaponLimits.Clear();
        g_aPrimaryWeaponsAvailable.Clear();
        do {
            kv.GetSectionName(key, sizeof(key));
            int limit = kv.GetNum(NULL_STRING, -1);
            if (limit == 0) {continue;}
            g_aPrimaryWeaponsAvailable.PushString(key);
            g_smWeaponLimits.SetValue(key, limit);
        } while (kv.GotoNextKey(false));
        g_aPrimaryWeaponsAvailable.PushString("random");
        g_smWeaponLimits.SetValue("random", -1);
    }

    kv.GoBack();
    kv.GoBack();

    if (!kv.JumpToKey("Secondary"))
    {
        LogError("[DM] The configuration file: %s has the following error:", path);
        LogError("[DM] The configuration file is corrupt \"Secondary\" section could not be found).");
        return false;
    }

    if (kv.GotoFirstSubKey(false))
    {
        g_aSecondaryWeaponsAvailable.Clear();
        do {
            kv.GetSectionName(key, sizeof(key));
            int limit = kv.GetNum(NULL_STRING, -1);
            if (limit == 0) {continue;}
            g_aSecondaryWeaponsAvailable.PushString(key);
            g_smWeaponLimits.SetValue(key, limit);
        } while (kv.GotoNextKey(false));
        g_aSecondaryWeaponsAvailable.PushString("random");
        g_smWeaponLimits.SetValue("random", -1);
    }

    kv.GoBack();
    kv.GoBack();

    if (!kv.JumpToKey("Tertiary"))
    {
        LogError("[DM] The configuration file: %s has the following error:", path);
        LogError("[DM] The configuration file is corrupt \"Tertiary\" section could not be found).");
        return false;
    }

    kv.GetString("dm_zeus", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_zeus.SetString(value);

    kv.GetString("dm_zeus_spawn", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_zeus_spawn.SetString(value);

    kv.GetString("dm_zeus_kill", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_zeus_kill.SetString(value);

    kv.GetString("dm_zeus_kill_taser", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_zeus_kill_taser.SetString(value);

    kv.GetString("dm_zeus_kill_knife", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_zeus_kill_knife.SetString(value);

    kv.GoBack();

    if (!kv.JumpToKey("Grenades"))
    {
        LogError("[DM] The configuration file: %s has the following error:", path);
        LogError("[DM] The configuration file is corrupt \"Grenades\" section could not be found).");
        return false;
    }

    kv.GetString("dm_nades_incendiary", value, sizeof(value), "0");
    g_cvDM_nades_incendiary.SetString(value);

    kv.GetString("dm_nades_molotov", value, sizeof(value), "0");
    g_cvDM_nades_molotov.SetString(value);

    kv.GetString("dm_nades_decoy", value, sizeof(value), "0");
    g_cvDM_nades_decoy.SetString(value);

    kv.GetString("dm_nades_flashbang", value, sizeof(value), "0");
    g_cvDM_nades_flashbang.SetString(value);

    kv.GetString("dm_nades_he", value, sizeof(value), "0");
    g_cvDM_nades_he.SetString(value);

    kv.GetString("dm_nades_smoke", value, sizeof(value), "0");
    g_cvDM_nades_smoke.SetString(value);

    kv.GetString("dm_nades_tactical", value, sizeof(value), "0");
    g_cvDM_nades_tactical.SetString(value);

    kv.GoBack();

    if (!kv.JumpToKey("Utilities"))
    {
        LogError("[DM] The configuration file: %s has the following error:", path);
        LogError("[DM] The configuration file is corrupt \"Utilities\" section could not be found).");
        return false;
    }

    kv.GetString("dm_healthshot", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_healthshot.SetString(value);

    kv.GetString("dm_healthshot_health", value, sizeof(value), "50");
    g_cvDM_healthshot_health.SetString(value);

    kv.GetString("dm_healthshot_total", value, sizeof(value), "4");
    g_cvDM_healthshot_total.SetString(value);

    kv.GetString("dm_healthshot_spawn", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_healthshot_spawn.SetString(value);

    kv.GetString("dm_healthshot_kill", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_healthshot_kill.SetString(value);

    kv.GetString("dm_healthshot_kill_knife", value, sizeof(value), "no");
    value = (StrEqual(value, "yes")) ? "1" : "0";
    g_cvDM_healthshot_kill_knife.SetString(value);

    kv.GoBack();

    if (!kv.JumpToKey("Armor"))
    {
        LogError("[DM] The configuration file: %s has the following error:", path);
        LogError("[DM] The configuration file is corrupt \"Armor\" section could not be found).");
        return false;
    }

    kv.GetString("dm_armor", value, sizeof(value), "2");
    g_cvDM_armor.SetString(value);

    kv.GoBack();

    if (!kv.JumpToKey("TeamSkins"))
    {
        LogError("[DM] The configuration file: %s has the following error:", path);
        LogError("[DM] The configuration file is corrupt \"TeamSkins\" section could not be found).");
        return false;
    }

    if (kv.GotoFirstSubKey(false))
    {
        do {
            kv.GetSectionName(key, sizeof(key));
            kv.GetString(NULL_STRING, value, sizeof(value), "");
            int team = 0;
            if (StrEqual(value, "CT", false))
                team = CS_TEAM_CT;
            else if (StrEqual(value, "T", false))
                team = CS_TEAM_T;
            g_smWeaponSkinsTeam.SetValue(key, team);
        } while (kv.GotoNextKey(false));
        kv.GoBack();
    }

    InitialiseWeaponCounts();
    g_cvDM_config_name.GetString(buffer, sizeof(buffer));
    CPrintToChatAll("%t Successfully loaded {purple}%s", "Chat Tag", buffer);

    delete kv;
    return true;
}

bool LoadConfigName(char[] config)
{
    KeyValues kv = new KeyValues("Deathmatch Config");
    char path[PLATFORM_MAX_PATH];
    char buffer[PLATFORM_MAX_PATH];
    Format(buffer, sizeof(buffer), "configs/deathmatch/%s", config);
    BuildPath(Path_SM, path, sizeof(path), buffer);

    if (!kv.ImportFromFile(path))
    {
        LogError("[DM] The configuration file: %s could not be read.", path);
        return false;
    }

    if (!kv.JumpToKey("Config"))
    {
        LogError("[DM] The configuration file: %s has the following error:", path);
        LogError("[DM] The configuration file is corrupt \"Config\" section could not be found).");
        return false;
    }

    char value[25];
    kv.GetString("dm_config_name", value, sizeof(value), "FAILURE");
    strcopy(g_cLoadConfigName, sizeof(g_cLoadConfigName), value);

    delete kv;
    return true;

}

bool LoadMapConfig()
{
    char path[PLATFORM_MAX_PATH];
    char workshopID[PLATFORM_MAX_PATH];
    char map[PLATFORM_MAX_PATH];
    char workshop[PLATFORM_MAX_PATH];
    GetCurrentMap(map, PLATFORM_MAX_PATH);

    BuildPath(Path_SM, path, sizeof(path), "configs/deathmatch/spawns");

    if (!DirExists(path))
    {
        if (!CreateDirectory(path, 511))
        {
            LogError("[DM] Failed to create directory %s", path);
            return false;
        }
    }

    BuildPath(Path_SM, path, sizeof(path), "configs/deathmatch/spawns/workshop");

    if (!DirExists(path))
    {
        if (!CreateDirectory(path, 511))
        {
            LogError("[DM] Failed to create directory %s", path);
            return false;
        }
    }

    if (StrContains(map, "workshop", false) != -1)
    {
        GetCurrentWorkshopMap(workshop, PLATFORM_MAX_PATH, workshopID, sizeof(workshopID) - 1);
        BuildPath(Path_SM, path, sizeof(path), "configs/deathmatch/spawns/workshop/%s", workshopID);
        if (!DirExists(path))
        {
            if (!CreateDirectory(path, 511))
            {
                LogError("[DM] Failed to create directory %s", path);
                return false;
            }
        }
        BuildPath(Path_SM, path, sizeof(path), "configs/deathmatch/spawns/workshop/%s/%s.txt", workshopID, workshop);
    }
    else
        BuildPath(Path_SM, path, sizeof(path), "configs/deathmatch/spawns/%s.txt", map);


    g_iSpawnPointCount = 0;

    /* Open file */
    File file = OpenFile(path, "r");
    if (file != null)
    {
        /* Read file */
        char buffer[255];
        char parts[6][16];
        int empty[1];
        /* Check to see if the file is empty. */
        if (file.Read(empty, 1, 4) < 1)
        {
            LogToGame("******************************************************");
            LogToGame("[DM] Falling back to Valve Spawns!");
            LogToGame("[DM] File: %s is empty.", path);
            LogToGame("[DM] To stop this message, add spawn points.");
            LogToGame("[DM] It is safe to ignore these messages.");
            LogToGame("******************************************************");
            return false;
        }
        else
            file.Seek(0, SEEK_SET);
        /* If the file isn't empty, find spawns. */
        while (!file.EndOfFile() && file.ReadLine(buffer, sizeof(buffer)))
        {
            TrimString(buffer);
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
    else
    {
        OpenFile(path, "w");
        LogToGame("******************************************************");
        LogToGame("[DM] Falling back to Valve Spawns!");
        LogToGame("[DM] File: %s doesn't exist.", path);
        LogToGame("[DM] Creating the file now...");
        LogToGame("[DM] It is safe to ignore these messages.");
        LogToGame("******************************************************");
        return false;
    }
    /* Close file */
    delete file;
    return true;
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
        LogError("[DM] Could not open spawn point file \"%s\" for writing.", path);
        return false;
    }
    /* Write spawn points */
    for (int i = 0; i < g_iSpawnPointCount; i++)
        file.WriteLine("%f %f %f %f %f %f", g_fSpawnPositions[i][0], g_fSpawnPositions[i][1], g_fSpawnPositions[i][2], g_fSpawnAngles[i][0], g_fSpawnAngles[i][1], g_fSpawnAngles[i][2]);
    /* Close file */
    delete file;
    return true;
}

void GetCurrentWorkshopMap(char[] map, int mapbuffer, char[] workshopID, int workshopbuffer)
{
    char currentmap[128]
    char currentmapbuffer[2][64]

    GetCurrentMap(currentmap, 127)
    ReplaceString(currentmap, sizeof(currentmap), "workshop/", "", false)
    ExplodeString(currentmap, "/", currentmapbuffer, 2, 63)

    strcopy(map, mapbuffer, currentmapbuffer[1])
    strcopy(workshopID, workshopbuffer, currentmapbuffer[0])
}

void GetDeathmatchConfigs()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/deathmatch");

    DirectoryListing dir = OpenDirectory(path);
    if (dir != null)
    {
        FileType type;
        char filename[32];
        g_aConfigNames.Clear();

        while (ReadDirEntry(dir, filename, sizeof(filename), type))
        {
            if (type != FileType_File)
                continue;

            if (!StrEqual(filename[strlen(filename) - 4], ".ini"))
                continue;

            if (!StrEqual(filename, "deathmatch.ini"))
                g_aConfigNames.PushString(filename);
        }

        delete dir;
    }
    else
        LogError("[DM] Could not open dir \"%s\" for reading.", path);
}