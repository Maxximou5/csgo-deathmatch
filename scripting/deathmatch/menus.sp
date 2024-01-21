void LoadAdminMenu()
{
    TopMenu topmenu;
    if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
        OnAdminMenuReady(topmenu);
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "adminmenu", false))
        g_tmAdminMenu = null;
}

public void OnAdminMenuReady(Handle aTopMenu)
{
    TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

    if (g_tmoDMCommands == INVALID_TOPMENUOBJECT)
        OnAdminMenuCreated(topmenu);

    if (topmenu == g_tmAdminMenu)
        return;

    g_tmAdminMenu = topmenu;

    TopMenuObject deathmatch_commands = g_tmAdminMenu.FindCategory("DeathmatchCommands");

    if (deathmatch_commands != INVALID_TOPMENUOBJECT)
    {
        g_tmAdminMenu.AddItem("dm_load_menu", AdminMenu_Load, deathmatch_commands, "dm_load_menu", ADMFLAG_SLAY);
        g_tmAdminMenu.AddItem("dm_spawn_menu", AdminMenu_Spawn, deathmatch_commands, "dm_spawn_menu", ADMFLAG_SLAY);
        g_tmAdminMenu.AddItem("dm_spawn_stats", AdminMenu_SpawnStats, deathmatch_commands, "dm_spawn_stats", ADMFLAG_SLAY);
        g_tmAdminMenu.AddItem("dm_spawn_reset", AdminMenu_StatsReset, deathmatch_commands, "dm_spawn_reset", ADMFLAG_SLAY);
        g_tmAdminMenu.AddItem("dm_weapon_stats", AdminMenu_WeaponStats, deathmatch_commands, "dm_weapon_stats", ADMFLAG_SLAY);
        g_tmAdminMenu.AddItem("dm_respawn_all", AdminMenu_Respawn, deathmatch_commands, "dm_respawn_all", ADMFLAG_SLAY);
    }
}

public void OnAdminMenuCreated(Handle topmenu)
{
    /* Block us from being called twice */
    if (topmenu == g_tmAdminMenu && g_tmoDMCommands != INVALID_TOPMENUOBJECT)
        return;

    g_tmoDMCommands = AddToTopMenu(topmenu, "DeathmatchCommands", TopMenuObject_Category, Category_Deathmatch, INVALID_TOPMENUOBJECT);
}

public void Category_Deathmatch(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    if (action == TopMenuAction_DisplayTitle)
        Format(buffer, maxlength, "Deathmatch Commands:");
    else if (action == TopMenuAction_DisplayOption)
        Format(buffer, maxlength, "Deathmatch Commands");
}

public void AdminMenu_Load(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    if (action == TopMenuAction_DisplayOption)
        Format(buffer, maxlength, "Config Loader");
    else if (action == TopMenuAction_SelectOption)
        BuildConfigMenu(param);
}

public void AdminMenu_Spawn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    if (action == TopMenuAction_DisplayOption)
        Format(buffer, maxlength, "Spawn Editor");
    else if (action == TopMenuAction_SelectOption)
        BuildSpawnEditorMenu(param);
}

public void AdminMenu_Respawn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    if (action == TopMenuAction_DisplayOption)
        Format(buffer, maxlength, "Respawn All");
    else if (action == TopMenuAction_SelectOption)
    {
        Spawns_RespawnAll();
        CReplyToCommand(param, "%t %t", "Chat Tag", "All Player Respawn");
    }
}

public void AdminMenu_SpawnStats(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    if (action == TopMenuAction_DisplayOption)
        Format(buffer, maxlength, "Display Spawn Statistics");
    else if (action == TopMenuAction_SelectOption)
        DisplaySpawnStats(param, false);
}

public void AdminMenu_StatsReset(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    if (action == TopMenuAction_DisplayOption)
        Format(buffer, maxlength, "Reset Spawn Statistics");
    else if (action == TopMenuAction_SelectOption)
    {
        Spawns_ResetSpawnStats();
        CPrintToChat(param, "%t %t", "Chat Tag", "Spawn Stats Reset");
    }
}

public void AdminMenu_WeaponStats(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    if (action == TopMenuAction_DisplayOption)
        Format(buffer, maxlength, "Display Weapon Statistics");
    else if (action == TopMenuAction_SelectOption)
        DisplayWeaponStats(param, false);
}

void BuildWeaponsMenu(int client)
{
    int allowSameWeapons = (g_bRememberChoice[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
    Menu menu = new Menu(Menu_Weapons);
    char title[100];
    Format(title, sizeof(title), "%T:", "Weapons Menu", client);
    menu.SetTitle(title);
    char itemtext[256];
    Format(itemtext, sizeof(itemtext), "%T", "New Weapons", client);
    menu.AddItem("New", itemtext);
    Format(itemtext, sizeof(itemtext), "%T", "Same Weapons", client);
    menu.AddItem("Same", itemtext, allowSameWeapons);
    Format(itemtext, sizeof(itemtext), "%T", "Random Weapons", client);
    menu.AddItem("Random", itemtext);
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

void BuildAvailableWeaponsMenu(int client, bool primary)
{
    Menu menu;
    if (primary)
    {
        menu = new Menu(Menu_Primary);
        menu.SetTitle("Primary Weapon:");
        menu.ExitButton = true;
    }
    else
    {
        menu = new Menu(Menu_Secondary);
        menu.SetTitle("Secondary Weapon:");
        menu.ExitBackButton = true;
    }

    g_aWeaponsList = new ArrayList();
    g_aWeaponsList = (primary) ? g_aPrimaryWeaponsAvailable : g_aSecondaryWeaponsAvailable;

    char currentWeapon[32];
    currentWeapon = (primary) ? g_sPrimaryWeapon[client] : g_sSecondaryWeapon[client];

    for (int i = 0; i < g_aWeaponsList.Length; i++)
    {
        char text[64];
        char weapon[32];
        g_aWeaponsList.GetString(i, weapon, sizeof(weapon));

        char weaponMenuName[32];
        g_smWeaponMenuNames.GetString(weapon, weaponMenuName, sizeof(weaponMenuName));

        int weaponCount;
        g_smWeaponCounts.GetValue(weapon, weaponCount);

        int weaponLimit;
        g_smWeaponLimits.GetValue(weapon, weaponLimit);

        /* If the client already has the weapon, then the limit does not apply. */
        if (StrEqual(currentWeapon, weapon))
            menu.AddItem(weapon, weaponMenuName);
        else
        {
            if (StrEqual(weapon, "weapon_awp") && CheckCommandAccess(client, "dm_weapons_awp_override", ADMFLAG_CUSTOM5))
            {
                Format(text, sizeof(text), "%s (VIP)", weaponMenuName);
                menu.AddItem(weapon, text);
            }
            else if ((weaponLimit == -1) || (weaponCount < weaponLimit))
                menu.AddItem(weapon, weaponMenuName);
            else
            {
                Format(text, sizeof(text), "%s (Limited)", weaponMenuName);
                menu.AddItem(weapon, text, ITEMDRAW_DISABLED);
            }
        }
    }
    menu.AddItem("random", "Random");

    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_Weapons(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[24];
        menu.GetItem(param2, info, sizeof(info));
        SetClientCookie(param1, g_hWeapon_Remember_Cookie, "1");
        g_bRememberChoice[param1] = true;

        if (StrEqual(info, "New"))
        {
            if (g_cvDM_loadout_style.IntValue <= 1)
            {
                if (g_bWeaponsGivenThisRound[param1])
                    CPrintToChat(param1, "%t %t", "Chat Tag", "Guns New Spawn");
            }
            if (g_cvDM_gun_menu_mode.IntValue == 1 || g_cvDM_gun_menu_mode.IntValue == 2)
                BuildAvailableWeaponsMenu(param1, true);
            else if (g_cvDM_gun_menu_mode.IntValue == 3)
                BuildAvailableWeaponsMenu(param1, false);
        }
        else if (StrEqual(info, "Same"))
        {
            if (g_cvDM_loadout_style.IntValue <= 1)
            {
                if (g_bWeaponsGivenThisRound[param1])
                    CPrintToChat(param1, "%t %t", "Chat Tag", "Guns Same Spawn");
            }
            if (g_cvDM_gun_menu_mode.IntValue == 1 || g_cvDM_gun_menu_mode.IntValue == 5)
                GiveSavedWeapons(param1, true, true);
            else if (g_cvDM_gun_menu_mode.IntValue == 2)
                GiveSavedWeapons(param1, true, false);
            else if (g_cvDM_gun_menu_mode.IntValue == 3)
                GiveSavedWeapons(param1, false, true);
            else if (g_cvDM_gun_menu_mode.IntValue == 4)
                GiveSavedWeapons(param1, false, false);
        }
        else if (StrEqual(info, "Random"))
        {
            if (g_cvDM_loadout_style.IntValue <= 1)
            {
                if (g_bWeaponsGivenThisRound[param1])
                    CPrintToChat(param1, "%t %t", "Chat Tag", "Guns Random Spawn");
            }
            if (g_cvDM_gun_menu_mode.IntValue == 1 || g_cvDM_gun_menu_mode.IntValue == 5)
            {
                g_sPrimaryWeapon[param1] = "random";
                g_sSecondaryWeapon[param1] = "random";
                GiveSavedWeapons(param1, true, true);
            }
            else if (g_cvDM_gun_menu_mode.IntValue == 2)
            {
                g_sPrimaryWeapon[param1] = "random";
                g_sSecondaryWeapon[param1] = "none";
                GiveSavedWeapons(param1, true, false);
            }
            else if (g_cvDM_gun_menu_mode.IntValue == 3)
            {
                g_sPrimaryWeapon[param1] = "none";
                g_sSecondaryWeapon[param1] = "random";
                GiveSavedWeapons(param1, false, true);
            }
            else if (g_cvDM_gun_menu_mode.IntValue == 4)
            {
                g_sPrimaryWeapon[param1] = "none";
                g_sSecondaryWeapon[param1] = "none";
                GiveSavedWeapons(param1, false, false);
            }
        }
    }
}

public int Menu_Primary(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char weaponEntity[32];
        char weaponName[32];
        int weaponCount;
        int weaponLimit;

        menu.GetItem(param2, weaponEntity, sizeof(weaponEntity));
        g_smWeaponMenuNames.GetString(weaponEntity, weaponName, sizeof(weaponName));
        g_smWeaponCounts.GetValue(weaponEntity, weaponCount);
        g_smWeaponLimits.GetValue(weaponEntity, weaponLimit);
        strcopy(g_sPrimaryWeapon[param1], sizeof(g_sPrimaryWeapon[]), weaponEntity);
        g_bGiveFullLoadout[param1] = true;

        if (g_cvDM_gun_menu_mode.IntValue != 2)
            BuildAvailableWeaponsMenu(param1, false)
        else
            GiveSavedWeapons(param1, true, false);

        CPrintToChat(param1, "%t %t %s", "Chat Tag", "Primary Selection", weaponName);
    }
    else if (action == MenuAction_Cancel)
    {
        if (IsClientInGame(param1) && param2 == MenuCancel_Exit)
        {
            g_sPrimaryWeapon[param1] = "none";
            g_bGiveFullLoadout[param1] = true;
            if (g_cvDM_gun_menu_mode.IntValue != 2)
                BuildAvailableWeaponsMenu(param1, false)
            else
                GiveSavedWeapons(param1, true, false);

            CPrintToChat(param1, "%t %t None", "Chat Tag", "Primary Selection");
        }
    }
}

public int Menu_Secondary(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char weaponEntity[32];
        char weaponName[32];
        int weaponCount;
        int weaponLimit;

        menu.GetItem(param2, weaponEntity, sizeof(weaponEntity));
        g_smWeaponMenuNames.GetString(weaponEntity, weaponName, sizeof(weaponName));
        g_smWeaponCounts.GetValue(weaponEntity, weaponCount);
        g_smWeaponLimits.GetValue(weaponEntity, weaponLimit);
        strcopy(g_sSecondaryWeapon[param1], sizeof(g_sSecondaryWeapon[]), weaponEntity);

        if (g_cvDM_gun_menu_mode.IntValue == 2)
            BuildAvailableWeaponsMenu(param1, true)
        else
        {
            if (g_bGiveFullLoadout[param1])
                GiveSavedWeapons(param1, true, true);
            else
                GiveSavedWeapons(param1, false, true);

            CPrintToChat(param1, "%t %t %s", "Chat Tag", "Secondary Selection", weaponName);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (IsClientInGame(param1) && param2 == MenuCancel_ExitBack)
            BuildAvailableWeaponsMenu(param1, true)

        if (IsClientInGame(param1) && param2 == MenuCancel_Exit)
        {
            g_sSecondaryWeapon[param1] = "none";
            if (g_cvDM_gun_menu_mode.IntValue == 2)
                BuildAvailableWeaponsMenu(param1, true)
            else
            {
                if (g_bGiveFullLoadout[param1])
                    GiveSavedWeapons(param1, true, true);
                else
                    GiveSavedWeapons(param1, false, true);

                CPrintToChat(param1, "%t %t None", "Chat Tag", "Secondary Selection");
            }
        }
    }
}

void BuildConfigMenu(int client)
{
    char config[32];
    GetDeathmatchConfigs();
    Menu menu = new Menu(Menu_ConfigMenu);
    menu.SetTitle("Config Loader");
    menu.AddItem("deathmatch.ini", "Default");
    for (int i = 0; i < g_aConfigNames.Length; i++)
    {
        g_aConfigNames.GetString(i, config, sizeof(config));
        if (StrContains(config, "config_loader.ini", false) == -1)
        {
            if (LoadConfigName(config))
                menu.AddItem(config, g_sLoadConfigName);
            else
                menu.AddItem(config, config, ITEMDRAW_DISABLED);
        }
    }
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void BuildConfigTimeMenu(int client)
{
    Menu menu = new Menu(Menu_ConfigTime);
    menu.SetTitle("Load Config:");
    menu.AddItem("respawn", "Respawn Players");
    menu.AddItem("restart", "Restart Round");
    menu.AddItem("nextround", "Next Round");
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void BuildSpawnEditorMenu(int client)
{
    Menu menu = new Menu(Menu_SpawnEditor);
    char title[100];
    Format(title, sizeof(title), "%T:", "Spawn Editor Menu", client);
    menu.SetTitle(title);
    char itemtext[256];
    Format(itemtext, sizeof(itemtext), "Spawn Editor Menu %s", (!g_bInEditMode) ? "Enable" : "Disable");
    Format(itemtext, sizeof(itemtext), "%T", itemtext, client);
    menu.AddItem("Edit", itemtext);
    Format(itemtext, sizeof(itemtext), "%T", "Spawn Editor Menu Nearest", client);
    menu.AddItem("Nearest", itemtext);
    Format(itemtext, sizeof(itemtext), "%T", "Spawn Editor Menu Previous", client);
    menu.AddItem("Previous", itemtext);
    Format(itemtext, sizeof(itemtext), "%T", "Spawn Editor Menu Next", client);
    menu.AddItem("Next", itemtext);
    Format(itemtext, sizeof(itemtext), "%T", "Spawn Editor Menu Add", client);
    menu.AddItem("Add", itemtext);
    Format(itemtext, sizeof(itemtext), "%T", "Spawn Editor Menu Insert", client);
    menu.AddItem("Insert", itemtext);
    Format(itemtext, sizeof(itemtext), "%T", "Spawn Editor Menu Delete", client);
    menu.AddItem("Delete", itemtext);
    Format(itemtext, sizeof(itemtext), "%T", "Spawn Editor Menu Delete All", client);
    menu.AddItem("Delete All", itemtext);
    Format(itemtext, sizeof(itemtext), "%T", "Spawn Editor Menu Save", client);
    menu.AddItem("Save", itemtext);
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_ConfigMenu(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
        delete menu;
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_ExitBack && g_tmAdminMenu)
            g_tmAdminMenu.Display(param1, TopMenuPosition_LastCategory);
    }
    else if (action == MenuAction_Select)
    {
        char info[PLATFORM_MAX_PATH];
        menu.GetItem(param2, info, sizeof(info));
        BuildConfigTimeMenu(param1);
        strcopy(g_sLoadConfigMenu, sizeof(g_sLoadConfigMenu), info);
    }
}

public int Menu_SpawnEditor(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
        delete menu;
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_ExitBack && g_tmAdminMenu)
            g_tmAdminMenu.Display(param1, TopMenuPosition_LastCategory);
    }
    else if (action == MenuAction_Select)
    {
        char info[24];
        menu.GetItem(param2, info, sizeof(info));

        if (StrEqual(info, "Edit"))
        {
            g_bInEditMode = !g_bInEditMode;
            if (g_bInEditMode)
            {
                Spawns_EnableEditorMode(param1);
                CreateTimer(1.0, Timer_RenderSpawnPoints, GetClientSerial(param1), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            }
            else
                Spawns_DisableEditorMode(param1);
        }
        else if (StrEqual(info, "Nearest"))
        {
            int spawnPoint = Spawns_GetNearestSpawn(param1);
            if (spawnPoint != -1)
            {
                TeleportEntity(param1, g_fSpawnPositions[spawnPoint], g_fSpawnAngles[spawnPoint], NULL_VECTOR);
                g_iLastEditorSpawnPoint[param1] = spawnPoint;
                CPrintToChat(param1, "%t %t #%i (%i total).", "Chat Tag", "Spawn Editor Teleported", spawnPoint + 1, g_iSpawnPointCount);
            }
        }
        else if (StrEqual(info, "Previous"))
        {
            if (g_iSpawnPointCount == 0)
                CPrintToChat(param1, "%t %t", "Chat Tag", "Spawn Editor No Spawn");
            else
            {
                int spawnPoint = g_iLastEditorSpawnPoint[param1] - 1;
                if (spawnPoint < 0)
                    spawnPoint = g_iSpawnPointCount - 1;

                TeleportEntity(param1, g_fSpawnPositions[spawnPoint], g_fSpawnAngles[spawnPoint], NULL_VECTOR);
                g_iLastEditorSpawnPoint[param1] = spawnPoint;
                CPrintToChat(param1, "%t %t #%i (%i total).", "Chat Tag", "Spawn Editor Teleported", spawnPoint + 1, g_iSpawnPointCount);
            }
        }
        else if (StrEqual(info, "Next"))
        {
            if (g_iSpawnPointCount == 0)
                CPrintToChat(param1, "%t %t", "Chat Tag", "Spawn Editor No Spawn");
            else
            {
                int spawnPoint = g_iLastEditorSpawnPoint[param1] + 1;
                if (spawnPoint >= g_iSpawnPointCount)
                    spawnPoint = 0;

                TeleportEntity(param1, g_fSpawnPositions[spawnPoint], g_fSpawnAngles[spawnPoint], NULL_VECTOR);
                g_iLastEditorSpawnPoint[param1] = spawnPoint;
                CPrintToChat(param1, "%t %t #%i (%i total).", "Chat Tag", "Spawn Editor Teleported", spawnPoint + 1, g_iSpawnPointCount);
            }
        }
        else if (StrEqual(info, "Add"))
        {
            Spawns_AddSpawn(param1);
        }
        else if (StrEqual(info, "Insert"))
        {
            Spawns_InsertSpawn(param1);
        }
        else if (StrEqual(info, "Delete"))
        {
            int spawnPoint = Spawns_GetNearestSpawn(param1);
            if (spawnPoint != -1)
            {
                Spawns_DeleteSpawn(spawnPoint);
                CPrintToChat(param1, "%t %t #%i (%i total).", "Chat Tag", "Spawn Editor Deleted Spawn", spawnPoint + 1, g_iSpawnPointCount);
            }
        }
        else if (StrEqual(info, "Delete All"))
        {
            Panel panel = new Panel();
            panel.SetTitle("Delete all spawn points?");
            panel.DrawItem("Yes");
            panel.DrawItem("No");
            panel.Send(param1, PanelConfirmDeleteAllSpawns, MENU_TIME_FOREVER);
            delete panel;
        }
        else if (StrEqual(info, "Save"))
        {
            if (WriteMapConfig())
                CPrintToChat(param1, "%t %t", "Chat Tag", "Spawn Editor Config Saved");
            else
                CPrintToChat(param1, "%t %t", "Chat Tag", "Spawn Editor Config Not Saved");
        }
        if (!StrEqual(info, "Delete All"))
            BuildSpawnEditorMenu(param1);
    }
}

public int PanelConfirmDeleteAllSpawns(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        if (param2 == 1)
        {
            g_iSpawnPointCount = 0;
            CPrintToChat(param1, "%t %t", "Chat Tag", "Spawn Editor Deleted All");
        }
        BuildSpawnEditorMenu(param1);
    }
}

public int Menu_ConfigTime(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
        delete menu;
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_ExitBack && g_tmAdminMenu)
            g_tmAdminMenu.Display(param1, TopMenuPosition_LastCategory);
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        LoadTimeConfig(param1, g_sLoadConfigMenu, info);
    }
}

public int PanelSpawnStats(Menu menu, MenuAction action, int param1, int param2) {}

void DisplaySpawnStats(int client, bool console)
{
    char text[64];
    if (console)
    {
        PrintToServer("////////////////////////////////////////////////////////////////");
        PrintToServer("Spawn Stats:");
        PrintToServer("////////////////////////////////////////////////////////////////");
        Format(text, sizeof(text), "- Number of player spawns: %i", g_iNumberOfPlayerSpawns);
        PrintToServer("%s", text);
        Format(text, sizeof(text), "- LoS Attempts: %i", g_iLosSearchAttempts);
        PrintToServer("%s", text);
        Format(text, sizeof(text), "- LoS search success rate: %.2f\%", (float(g_iLosSearchSuccesses) / float(g_iLosSearchAttempts)) * 100);
        PrintToServer("%s", text);
        Format(text, sizeof(text), "- LoS search failure rate: %.2f\%", (float(g_iLosSearchFailures) / float(g_iLosSearchAttempts)) * 100);
        PrintToServer("%s", text);
        Format(text, sizeof(text), "- Distance Attempts: %i", g_iDistanceSearchAttempts);
        PrintToServer("%s", text);
        Format(text, sizeof(text), "- Distance search success rate: %.2f\%", (float(g_iDistanceSearchSuccesses) / float(g_iDistanceSearchAttempts)) * 100);
        PrintToServer("%s", text);
        Format(text, sizeof(text), "- Distance search failure rate: %.2f\%", (float(g_iDistanceSearchFailures) / float(g_iDistanceSearchAttempts)) * 100);
        PrintToServer("%s", text);
        Format(text, sizeof(text), "- Spawn point search failures: %i", g_iSpawnPointSearchFailures);
        PrintToServer("%s", text);
        PrintToServer("////////////////////////////////////////////////////////////////");
    }
    else
    {
        Panel panel = new Panel();
        panel.SetTitle("Spawn Stats:");
        Format(text, sizeof(text), "- Number of player spawns: %i", g_iNumberOfPlayerSpawns);
        panel.DrawText(text);
        Format(text, sizeof(text), "- LoS Attempts: %i", g_iLosSearchAttempts);
        panel.DrawText(text);
        Format(text, sizeof(text), "- LoS search success rate: %.2f\%", (float(g_iLosSearchSuccesses) / float(g_iLosSearchAttempts)) * 100);
        panel.DrawText(text);
        Format(text, sizeof(text), "- LoS search failure rate: %.2f\%", (float(g_iLosSearchFailures) / float(g_iLosSearchAttempts)) * 100);
        panel.DrawText(text);
        Format(text, sizeof(text), "- Distance Attempts: %i", g_iDistanceSearchAttempts);
        panel.DrawText(text);
        Format(text, sizeof(text), "- Distance search success rate: %.2f\%", (float(g_iDistanceSearchSuccesses) / float(g_iDistanceSearchAttempts)) * 100);
        panel.DrawText(text);
        Format(text, sizeof(text), "- Distance search failure rate: %.2f\%", (float(g_iDistanceSearchFailures) / float(g_iDistanceSearchAttempts)) * 100);
        panel.DrawText(text);
        Format(text, sizeof(text), "- Spawn point search failures: %i", g_iSpawnPointSearchFailures);
        panel.DrawText(text);
        panel.CurrentKey = GetMaxPageItems(panel.Style);
        panel.DrawItem("Exit", ITEMDRAW_CONTROL);
        panel.Send(client, PanelSpawnStats, MENU_TIME_FOREVER);
        delete panel;
    }
}

public int Menu_WeaponStats(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
        delete menu;
}

void DisplayWeaponStats(int client, bool console)
{
    char text[64];
    char weapon[32];
    char weaponMenuName[32];
    int weaponCount;
    int weaponLimit;

    if (console)
    {
        PrintToServer("////////////////////////////////////////////////////////////////");
        PrintToServer("Weapon Primary Stats:");
        PrintToServer("////////////////////////////////////////////////////////////////");
        for (int i = 0; i < g_aPrimaryWeaponsAvailable.Length; i++)
        {
            g_aPrimaryWeaponsAvailable.GetString(i, weapon, sizeof(weapon));
            g_smWeaponMenuNames.GetString(weapon, weaponMenuName, sizeof(weaponMenuName));
            g_smWeaponCounts.GetValue(weapon, weaponCount);
            g_smWeaponLimits.GetValue(weapon, weaponLimit);

            Format(text, sizeof(text), "%s | Count: %i | Limit: %i", weaponMenuName, weaponCount, weaponLimit);
            PrintToServer("%s", text);
        }
        PrintToServer("////////////////////////////////////////////////////////////////");
        PrintToServer("Weapon Secondary Stats:");
        for (int i = 0; i < g_aSecondaryWeaponsAvailable.Length; i++)
        {
            g_aSecondaryWeaponsAvailable.GetString(i, weapon, sizeof(weapon));
            g_smWeaponMenuNames.GetString(weapon, weaponMenuName, sizeof(weaponMenuName));
            g_smWeaponCounts.GetValue(weapon, weaponCount);
            g_smWeaponLimits.GetValue(weapon, weaponLimit);

            Format(text, sizeof(text), "%s | Count: %i | Limit: %i", weaponMenuName, weaponCount, weaponLimit);
            PrintToServer("%s", text);
        }
        PrintToServer("////////////////////////////////////////////////////////////////");
    }
    else
    {
        Menu menu = new Menu(Menu_WeaponStats);
        menu.SetTitle("Weapon Stats:");

        for (int i = 0; i < g_aPrimaryWeaponsAvailable.Length; i++)
        {
            g_aPrimaryWeaponsAvailable.GetString(i, weapon, sizeof(weapon));
            g_smWeaponMenuNames.GetString(weapon, weaponMenuName, sizeof(weaponMenuName));
            g_smWeaponCounts.GetValue(weapon, weaponCount);
            g_smWeaponLimits.GetValue(weapon, weaponLimit);

            Format(text, sizeof(text), "%s | Count: %i | Limit: %i", weaponMenuName, weaponCount, weaponLimit);
            menu.AddItem(weapon, text);
        }

        for (int i = 0; i < g_aSecondaryWeaponsAvailable.Length; i++)
        {
            g_aSecondaryWeaponsAvailable.GetString(i, weapon, sizeof(weapon));
            g_smWeaponMenuNames.GetString(weapon, weaponMenuName, sizeof(weaponMenuName));
            g_smWeaponCounts.GetValue(weapon, weaponCount);
            g_smWeaponLimits.GetValue(weapon, weaponLimit);

            Format(text, sizeof(text), "%s | Count: %i | Limit: %i", weaponMenuName, weaponCount, weaponLimit);
            menu.AddItem(weapon, text);
        }

        menu.ExitButton = true;
        menu.Display(client, MENU_TIME_FOREVER);
    }
}