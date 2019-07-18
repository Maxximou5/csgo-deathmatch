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
        g_tmAdminMenu.AddItem("dm_load", AdminMenu_Load, deathmatch_commands, "dm_load", ADMFLAG_SLAY);
        g_tmAdminMenu.AddItem("dm_spawn_menu", AdminMenu_Spawn, deathmatch_commands, "dm_spawn_menu", ADMFLAG_SLAY);
        g_tmAdminMenu.AddItem("dm_respawn_all", AdminMenu_Respawn, deathmatch_commands, "dm_respawn_all", ADMFLAG_SLAY);
        g_tmAdminMenu.AddItem("dm_stats", AdminMenu_Stats, deathmatch_commands, "dm_stats", ADMFLAG_SLAY);
        g_tmAdminMenu.AddItem("dm_stats_reset", AdminMenu_Reset, deathmatch_commands, "dm_stats_reset", ADMFLAG_SLAY);
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
        RespawnAll();
        CReplyToCommand(param, "%t %t", "Chat Tag", "All Player Respawn");
    }
}

public void AdminMenu_Stats(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    if (action == TopMenuAction_DisplayOption)
        Format(buffer, maxlength, "Display Spawn Statistics");
    else if (action == TopMenuAction_SelectOption)
        DisplaySpawnStats(param, false);
}

public void AdminMenu_Reset(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    if (action == TopMenuAction_DisplayOption)
        Format(buffer, maxlength, "Reset Spawn Statistics");
    else if (action == TopMenuAction_SelectOption)
    {
        ResetSpawnStats();
        CPrintToChat(param, "%t %t", "Chat Tag", "Spawn Stats Reset");
    }
}

void BuildWeaponsMenu(int client)
{
    Reset_Handle(g_hWeaponsMenus[client]);
    int allowSameWeapons = (g_bRememberChoice[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
    Menu menu = new Menu(Menu_Weapons);
    char title[100];
    Format(title, sizeof(title), "%T:", "Weapons Menu", client);
    menu.SetTitle(title);
    char itemtext[256];
    Format(itemtext, sizeof(itemtext), "%T", "New weapons", client);
    menu.AddItem("New", itemtext);
    Format(itemtext, sizeof(itemtext), "%T", "Same weapons", client);
    menu.AddItem("Same", itemtext, allowSameWeapons);
    Format(itemtext, sizeof(itemtext), "%T", "Random weapons", client);
    menu.AddItem("Random", itemtext);
    menu.ExitButton = false;
    g_hWeaponsMenus[client] = menu;
    DisplayMenu(g_hWeaponsMenus[client], client, MENU_TIME_FOREVER);
}

void BuildAvailableWeaponsMenu(int client, bool primary)
{
    Menu menu;
    if (primary)
    {
        Reset_Handle(g_hPrimaryMenus[client]);
        menu = new Menu(Menu_Primary);
        menu.SetTitle("Primary Weapon:");
    }
    else
    {
        Reset_Handle(g_hSecondaryMenus[client]);
        menu = new Menu(Menu_Secondary);
        menu.SetTitle("Secondary Weapon:");
    }

    ArrayList weapons;
    weapons = new ArrayList();
    weapons = (primary) ? g_aPrimaryWeaponsAvailable : g_aSecondaryWeaponsAvailable;

    char currentWeapon[24];
    currentWeapon = (primary) ? g_cPrimaryWeapon[client] : g_cSecondaryWeapon[client];

    for (int i = 0; i < weapons.Length; i++)
    {
        char weapon[24];
        weapons.GetString(i, weapon, sizeof(weapon));

        char weaponMenuName[24];
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
            if ((weaponLimit == -1) || (weaponCount < weaponLimit))
                menu.AddItem(weapon, weaponMenuName);
            else
            {
                char text[64];
                Format(text, sizeof(text), "%s (Limited)", weaponMenuName);
                menu.AddItem(weapon, text, ITEMDRAW_DISABLED);
            }
        }
    }
    menu.ExitBackButton = true;
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
        if (LoadConfigName(config))
            menu.AddItem(config, g_cLoadConfigName);
        else
            menu.AddItem(config, config, ITEMDRAW_DISABLED);
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
    menu.ExitBackButton = true;
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
        strcopy(g_cLoadConfigMenu, sizeof(g_cLoadConfigMenu), info);
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
                EnableEditorMode(param1);
                CreateTimer(1.0, RenderSpawnPoints, GetClientSerial(param1), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            }
            else
                DisableEditorMode(param1);
        }
        else if (StrEqual(info, "Nearest"))
        {
            int spawnPoint = GetNearestSpawn(param1);
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
        LoadTimeConfig(param1, g_cLoadConfigMenu, info);
    }
}

public int PanelSpawnStats(Menu menu, MenuAction action, int param1, int param2) {}

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
            else if (g_cvDM_gun_menu_mode.IntValue == 4)
            {
                g_cPrimaryWeapon[param1] = "none";
                g_cSecondaryWeapon[param1] = "none";
                GiveSavedWeapons(param1, false, false);
            }
        }
    }
}

public int Menu_Primary(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[24];
        menu.GetItem(param2, info, sizeof(info));
        int weaponCount;
        g_smWeaponCounts.GetValue(info, weaponCount);
        int weaponLimit;
        g_smWeaponLimits.GetValue(info, weaponLimit);

        if ((weaponLimit == -1) || (weaponCount < weaponLimit))
        {
            IncrementWeaponCount(info);
            DecrementWeaponCount(g_cPrimaryWeapon[param1]);
            g_cPrimaryWeapon[param1] = info;
            GiveSavedWeapons(param1, true, false);
            if (g_cvDM_gun_menu_mode.IntValue != 2)
                BuildAvailableWeaponsMenu(param1, false)
            else
            {
                DecrementWeaponCount(g_cSecondaryWeapon[param1]);
                g_cSecondaryWeapon[param1] = "none";
                GiveSavedWeapons(param1, false, true);
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
                BuildAvailableWeaponsMenu(param1, false);
            else
            {
                DecrementWeaponCount(g_cSecondaryWeapon[param1]);
                g_cSecondaryWeapon[param1] = "none";
                GiveSavedWeapons(param1, false, true);
                SetClientCookie(param1, g_hWeapon_First_Cookie, "0");
                g_bFirstWeaponSelection[param1] = false;
            }
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_Exit)
        {
            if (!(0 < param1 <= MaxClients) && IsClientInGame(param1))
            {
                DecrementWeaponCount(g_cPrimaryWeapon[param1]);
                g_cPrimaryWeapon[param1] = "none";
                GiveSavedWeapons(param1, true, false);
                if (g_cvDM_gun_menu_mode.IntValue != 2)
                    BuildAvailableWeaponsMenu(param1, false);
            }
        }
    }
}

public int Menu_Secondary(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[24];
        menu.GetItem(param2, info, sizeof(info));
        IncrementWeaponCount(info);
        DecrementWeaponCount(g_cSecondaryWeapon[param1]);
        g_cSecondaryWeapon[param1] = info;
        GiveSavedWeapons(param1, false, true);
        SetClientCookie(param1, g_hWeapon_First_Cookie, "0");
        g_bFirstWeaponSelection[param1] = false;
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_Exit)
        {
            if (!(0 < param1 <= MaxClients) && IsClientInGame(param1))
            {
                DecrementWeaponCount(g_cSecondaryWeapon[param1]);
                g_cSecondaryWeapon[param1] = "none";
                GiveSavedWeapons(param1, false, true);
                SetClientCookie(param1, g_hWeapon_First_Cookie, "0");
                g_bFirstWeaponSelection[param1] = false;
            }
        }
    }
}

void DisplaySpawnStats(int client, bool console)
{
    char text[64];
    if (console)
    {
        PrintToServer("////////////////////////////////////////////////////////////////");
        PrintToServer("Spawn Stats:");
        Format(text, sizeof(text), "- Number of player spawns: %i", g_iNumberOfPlayerSpawns);
        PrintToServer("%s", text);
        Format(text, sizeof(text), "- LoS search success rate: %.2f\%", (float(g_iLosSearchSuccesses) / float(g_iLosSearchAttempts)) * 100);
        PrintToServer("%s", text);
        Format(text, sizeof(text), "- LoS search failure rate: %.2f\%", (float(g_iLosSearchFailures) / float(g_iLosSearchAttempts)) * 100);
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
        Format(text, sizeof(text), "- LoS search success rate: %.2f\%", (float(g_iLosSearchSuccesses) / float(g_iLosSearchAttempts)) * 100);
        panel.DrawText(text);
        Format(text, sizeof(text), "- LoS search failure rate: %.2f\%", (float(g_iLosSearchFailures) / float(g_iLosSearchAttempts)) * 100);
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

void Reset_Handle(Handle handle)
{
    if (handle != null)
    {
        CancelMenu(handle);
        CloseHandle(handle);
        handle = null;
    }
}