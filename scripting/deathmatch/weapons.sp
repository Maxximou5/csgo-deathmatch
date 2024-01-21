void LoadWeapons()
{
    g_iAmmoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");

    /* Create arrays to store available weapons loaded by config */
    g_aPrimaryWeaponsAvailable =  new ArrayList(24);
    g_aSecondaryWeaponsAvailable =  new ArrayList(10);

    /* Create stringmap to store weapon limits, counts, and teams */
    g_smWeaponLimits = new StringMap();
    g_smWeaponCounts = new StringMap();
    g_smWeaponSkinsTeam = new StringMap();

    /* Create trie to store menu names for weapons */
    BuildWeaponMenuNames();
}

void SetClientGunSettings(int client, char[] primary, char[] secondary)
{
    strcopy(g_sPrimaryWeapon[client], sizeof(g_sPrimaryWeapon[]), primary);
    strcopy(g_sSecondaryWeapon[client], sizeof(g_sSecondaryWeapon[]), secondary);
}

void SetClientGunModeSettings(int client)
{
    switch (g_cvDM_gun_menu_mode.IntValue)
    {
        case 1:
        {
            if (IsFakeClient(client))
                SetClientGunSettings(client, "random", "random");
        }
        case 2:
        {
            if (IsFakeClient(client))
                SetClientGunSettings(client, "random", "none");
        }
        case 3:
        {
            if (IsFakeClient(client))
                SetClientGunSettings(client, "none", "random");
        }
        case 4:
        {
            if (IsFakeClient(client))
                SetClientGunSettings(client, "none", "none");
        }
        case 5:
        {
            SetClientGunSettings(client, "random", "random");
            if (!IsFakeClient(client))
            {
                SetClientCookie(client, g_hWeapon_Primary_Cookie, "random");
                SetClientCookie(client, g_hWeapon_Secondary_Cookie, "random");
            }
        }
        case 6:
        {
            if (IsFakeClient(client))
            {
                SetClientGunSettings(client, "random", "random");
                g_bRememberChoice[client] = true;
            }
        }
    }
}

void BuildWeaponMenuNames()
{
    g_smWeaponMenuNames = new StringMap();
    /* Primary weapons */
    g_smWeaponMenuNames.SetString("weapon_ak47", "AK-47");
    g_smWeaponMenuNames.SetString("weapon_m4a1", "M4A4");
    g_smWeaponMenuNames.SetString("weapon_m4a1_silencer", "M4A1-S");
    g_smWeaponMenuNames.SetString("weapon_sg556", "SG 553");
    g_smWeaponMenuNames.SetString("weapon_aug", "AUG");
    g_smWeaponMenuNames.SetString("weapon_galilar", "Galil AR");
    g_smWeaponMenuNames.SetString("weapon_famas", "FAMAS");
    g_smWeaponMenuNames.SetString("weapon_awp", "AWP");
    g_smWeaponMenuNames.SetString("weapon_ssg08", "SSG 08");
    g_smWeaponMenuNames.SetString("weapon_g3sg1", "G3SG1");
    g_smWeaponMenuNames.SetString("weapon_scar20", "SCAR-20");
    g_smWeaponMenuNames.SetString("weapon_m249", "M249");
    g_smWeaponMenuNames.SetString("weapon_negev", "Negev");
    g_smWeaponMenuNames.SetString("weapon_nova", "Nova");
    g_smWeaponMenuNames.SetString("weapon_xm1014", "XM1014");
    g_smWeaponMenuNames.SetString("weapon_sawedoff", "Sawed-Off");
    g_smWeaponMenuNames.SetString("weapon_mag7", "MAG-7");
    g_smWeaponMenuNames.SetString("weapon_mac10", "MAC-10");
    g_smWeaponMenuNames.SetString("weapon_mp9", "MP9");
    g_smWeaponMenuNames.SetString("weapon_mp7", "MP7");
    g_smWeaponMenuNames.SetString("weapon_mp5sd", "MP5-SD");
    g_smWeaponMenuNames.SetString("weapon_ump45", "UMP-45");
    g_smWeaponMenuNames.SetString("weapon_p90", "P90");
    g_smWeaponMenuNames.SetString("weapon_bizon", "PP-Bizon");
    /* Secondary weapons */
    g_smWeaponMenuNames.SetString("weapon_glock", "Glock-18");
    g_smWeaponMenuNames.SetString("weapon_p250", "P250");
    g_smWeaponMenuNames.SetString("weapon_cz75a", "CZ75-A");
    g_smWeaponMenuNames.SetString("weapon_usp_silencer", "USP-S");
    g_smWeaponMenuNames.SetString("weapon_fiveseven", "Five-SeveN");
    g_smWeaponMenuNames.SetString("weapon_deagle", "Desert Eagle");
    g_smWeaponMenuNames.SetString("weapon_revolver", "R8");
    g_smWeaponMenuNames.SetString("weapon_elite", "Dual Berettas");
    g_smWeaponMenuNames.SetString("weapon_tec9", "Tec-9");
    g_smWeaponMenuNames.SetString("weapon_hkp2000", "P2000");
    /* Random */
    g_smWeaponMenuNames.SetString("random", "Random");
}

void InitializeWeaponCounts()
{
    for (int i = 0; i < g_aPrimaryWeaponsAvailable.Length; i++)
    {
        char weapon[32];
        g_aPrimaryWeaponsAvailable.GetString(i, weapon, sizeof(weapon));
        g_smWeaponCounts.SetValue(weapon, 0);
    }
    for (int i = 0; i < g_aSecondaryWeaponsAvailable.Length; i++)
    {
        char weapon[32];
        g_aSecondaryWeaponsAvailable.GetString(i, weapon, sizeof(weapon));
        g_smWeaponCounts.SetValue(weapon, 0);
    }
}

void IncrementWeaponCount(const char[] weapon)
{
    if (strcmp(weapon, "none") == 0 || strcmp(weapon, "random") == 0)
        return
    else
    {
        int weaponCount;
        g_smWeaponCounts.GetValue(weapon, weaponCount);
        g_smWeaponCounts.SetValue(weapon, weaponCount + 1);
    }
}

void DecrementWeaponCount(const char[] weapon)
{
    if (strcmp(weapon, "none") == 0 || strcmp(weapon, "random") == 0)
        return
    else
    {
        int weaponCount;
        g_smWeaponCounts.GetValue(weapon, weaponCount);
        if (weaponCount > 0)
            g_smWeaponCounts.SetValue(weapon, weaponCount - 1);
    }
}

public int GetWeaponTeam(const char[] weapon)
{
    int team = 0;
    g_smWeaponSkinsTeam.GetValue(weapon, team);
    return team;
}

void GiveSkinnedWeapon(int client, const char[] weapon, bool primary, bool random = false)
{
    int playerTeam = GetEntProp(client, Prop_Data, "m_iTeamNum");
    int weaponTeam = GetWeaponTeam(weapon);
    bool playerVIP = CheckCommandAccess(client, "dm_access_weapons_awp", ADMFLAG_RESERVATION);
    bool awpCurrent = strcmp(weapon, "weapon_awp") == 0;
    bool awpPrevious = strcmp(g_sPrimaryWeaponPrevious[client], "weapon_awp") == 0;

    if (weaponTeam > 0)
        SetEntProp(client, Prop_Data, "m_iTeamNum", weaponTeam);

    GivePlayerItem(client, weapon);
    SetEntProp(client, Prop_Data, "m_iTeamNum", playerTeam);

    if (g_cvDM_fast_equip.BoolValue)
        RequestFrame(Frame_FastSwitch, GetClientSerial(client));

    if (!IsFakeClient(client))
    {
        if (primary)
        {
            if (!playerVIP && !awpCurrent)
                IncrementWeaponCount(weapon);
            if (!playerVIP && !awpPrevious)
                DecrementWeaponCount(weapon);
            if (!random)
                strcopy(g_sPrimaryWeapon[client], sizeof(g_sPrimaryWeapon[]), weapon);
        }
        else
        {
            IncrementWeaponCount(weapon);
            DecrementWeaponCount(weapon);
            if (!random)
                strcopy(g_sSecondaryWeapon[client], sizeof(g_sSecondaryWeapon[]), weapon);
        }
    }
}

void GiveSavedWeapons(int client, bool primary, bool secondary)
{
    if (IsValidClient(client, true) && IsPlayerAlive(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR)
    {
        if (IsFakeClient(client))
            SetClientGunModeSettings(client);

        if (g_cvDM_loadout_style.IntValue >= 2)
            g_bWeaponsGivenThisRound[client] = false;

        if (!g_bWeaponsGivenThisRound[client])
        {
            RemoveClientWeapons(client);

            if (g_cvDM_gun_menu_mode.IntValue == 2 && strcmp(g_sPrimaryWeapon[client], "none") == 0)
                g_sPrimaryWeapon[client] = "random";

            if (primary && !StrEqual(g_sPrimaryWeapon[client], "none") && g_aPrimaryWeaponsAvailable.Length != 0)
            {
                int random = GetRandomInt(0, g_aPrimaryWeaponsAvailable.Length - 1);
                if (strcmp(g_sPrimaryWeapon[client], "random") == 0)
                {
                    /* Select random menu item (excluding "Random" option) */
                    char randomWeapon[32];
                    g_aPrimaryWeaponsAvailable.GetString(random, randomWeapon, sizeof(randomWeapon));
                    GiveSkinnedWeapon(client, randomWeapon, true, true);
                    if (!IsFakeClient(client))
                        SetClientCookie(client, g_hWeapon_Primary_Cookie, "random");
                }
                else
                {
                    bool weaponFound = false;
                    char weapon[32];
                    for (int i = 0; i < g_aPrimaryWeaponsAvailable.Length; i++)
                    {
                        g_aPrimaryWeaponsAvailable.GetString(i, weapon, sizeof(weapon));
                        if (StrEqual(g_sPrimaryWeapon[client], weapon))
                        {
                            weaponFound = true;
                            break;
                        }
                    }

                    if (weaponFound)
                    {
                        GiveSkinnedWeapon(client, g_sPrimaryWeapon[client], true);
                        if (!IsFakeClient(client))
                            SetClientCookie(client, g_hWeapon_Primary_Cookie, g_sPrimaryWeapon[client]);
                    }
                    else
                    {
                        char randomWeapon[32];
                        g_aPrimaryWeaponsAvailable.GetString(random, randomWeapon, sizeof(randomWeapon));
                        GiveSkinnedWeapon(client, randomWeapon, true, true);
                        if (!IsFakeClient(client))
                            SetClientCookie(client, g_hWeapon_Primary_Cookie, "random");
                    }
                }
            }
            if (secondary)
            {
                if (g_cvDM_gun_menu_mode.IntValue == 3 && strcmp(g_sSecondaryWeapon[client], "none") == 0)
                    g_sSecondaryWeapon[client] = "random";

                if (!StrEqual(g_sSecondaryWeapon[client], "none") && g_aSecondaryWeaponsAvailable.Length != 0)
                {
                    int random = GetRandomInt(0, g_aSecondaryWeaponsAvailable.Length - 1);
                    if (strcmp(g_sSecondaryWeapon[client], "random") == 0)
                    {
                        /* Select random menu item (excluding "Random" option) */
                        char randomWeapon[32];
                        g_aSecondaryWeaponsAvailable.GetString(random, randomWeapon, sizeof(randomWeapon));
                        GiveSkinnedWeapon(client, randomWeapon, false, true);
                        if (!IsFakeClient(client))
                            SetClientCookie(client, g_hWeapon_Secondary_Cookie, "random");
                    }
                    else
                    {
                        bool weaponFound = false;
                        char weapon[32];
                        for (int i = 0; i < g_aSecondaryWeaponsAvailable.Length; i++)
                        {
                            g_aSecondaryWeaponsAvailable.GetString(i, weapon, sizeof(weapon));
                            if (StrEqual(g_sSecondaryWeapon[client], weapon))
                            {
                                weaponFound = true;
                                break;
                            }
                        }

                        if (weaponFound)
                        {
                            GiveSkinnedWeapon(client, g_sSecondaryWeapon[client], false);
                            if (!IsFakeClient(client))
                                SetClientCookie(client, g_hWeapon_Secondary_Cookie, g_sSecondaryWeapon[client]);
                        }
                        else
                        {
                            char randomWeapon[32];
                            g_aSecondaryWeaponsAvailable.GetString(random, randomWeapon, sizeof(randomWeapon));
                            GiveSkinnedWeapon(client, randomWeapon, false, true);
                            if (!IsFakeClient(client))
                                SetClientCookie(client, g_hWeapon_Secondary_Cookie, "random");
                        }
                    }
                }
            }
            GivePlayerItem(client, "weapon_knife");
            int clientTeam = GetClientTeam(client);
            if (clientTeam == CS_TEAM_CT)
            {
                for (int i = 0; i < g_cvDM_nades_incendiary.IntValue; i++)
                    GivePlayerItem(client, "weapon_incgrenade");
            }
            else if (clientTeam == CS_TEAM_T)
            {
                for (int i = 0; i < g_cvDM_nades_molotov.IntValue; i++)
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
            if (g_cvDM_zeus.BoolValue && g_cvDM_zeus_spawn.BoolValue)
                RequestFrame(Frame_GiveTaser, GetClientSerial(client));
            if (g_cvDM_healthshot.BoolValue && g_cvDM_healthshot_spawn.BoolValue && (g_iHealthshotCount[client] < g_cvDM_healthshot_total.IntValue))
                RequestFrame(Frame_GiveHealthshot, GetClientSerial(client));
            if (g_cvDM_loadout_style.IntValue <= 1)
                g_bWeaponsGivenThisRound[client] = true;
            else if (g_cvDM_loadout_style.IntValue >= 2)
                g_bWeaponsGivenThisRound[client] = false;
            g_bRememberChoice[client] = true;
            if (!IsFakeClient(client))
            {
                int iPrimary = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
                int iSecondary = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);

                if (iPrimary != -1)
                        SDKHook(iPrimary, SDKHook_ReloadPost, Hook_OnReloadPost);

                if (iSecondary != -1)
                        SDKHook(iSecondary, SDKHook_ReloadPost, Hook_OnReloadPost);

                SetClientCookie(client, g_hWeapon_Remember_Cookie, "1");
            }
            PreviousClientWeapons(client);
        }
    }
}

public int GetWeaponAmmoCount(char[] weaponName, bool currentClip)
{
    if (strcmp(weaponName, "weapon_ak47") == 0)
        return currentClip ? 30 : 90;
    else if (strcmp(weaponName, "weapon_m4a1") == 0)
        return currentClip ? 30 : 90;
    else if (strcmp(weaponName, "weapon_m4a1_silencer") == 0)
        return currentClip ? 20 : 80;
    else if (strcmp(weaponName, "weapon_awp") == 0)
        return currentClip ? 10 : 30;
    else if (strcmp(weaponName, "weapon_sg552") == 0)
        return currentClip ? 30 : 90;
    else if (strcmp(weaponName, "weapon_aug") == 0)
        return currentClip ? 30 : 90;
    else if (strcmp(weaponName, "weapon_p90") == 0)
        return currentClip ? 50 : 100;
    else if (strcmp(weaponName, "weapon_galilar") == 0)
        return currentClip ? 35 : 90;
    else if (strcmp(weaponName, "weapon_famas") == 0)
        return currentClip ? 25 : 90;
    else if (strcmp(weaponName, "weapon_ssg08") == 0)
        return currentClip ? 10 : 90;
    else if (strcmp(weaponName, "weapon_g3sg1") == 0)
        return currentClip ? 20 : 90;
    else if (strcmp(weaponName, "weapon_scar20") == 0)
        return currentClip ? 20 : 90;
    else if (strcmp(weaponName, "weapon_m249") == 0)
        return currentClip ? 100 : 200;
    else if (strcmp(weaponName, "weapon_negev") == 0)
        return currentClip ? 150 : 200;
    else if (strcmp(weaponName, "weapon_nova") == 0)
        return currentClip ? 8 : 32;
    else if (strcmp(weaponName, "weapon_xm1014") == 0)
        return currentClip ? 7 : 32;
    else if (strcmp(weaponName, "weapon_sawedoff") == 0)
        return currentClip ? 7 : 32;
    else if (strcmp(weaponName, "weapon_mag7") == 0)
        return currentClip ? 5 : 32;
    else if (strcmp(weaponName, "weapon_mac10") == 0)
        return currentClip ? 30 : 100;
    else if (strcmp(weaponName, "weapon_mp9") == 0)
        return currentClip ? 30 : 120;
    else if (strcmp(weaponName, "weapon_mp7") == 0)
        return currentClip ? 30 : 120;
    else if (strcmp(weaponName, "weapon_mp5sd") == 0)
        return currentClip ? 30 : 120;
    else if (strcmp(weaponName, "weapon_ump45") == 0)
        return currentClip ? 25 : 100;
    else if (strcmp(weaponName, "weapon_bizon") == 0)
        return currentClip ? 64 : 120;
    else if (strcmp(weaponName, "weapon_glock") == 0)
        return currentClip ? 20 : 120;
    else if (strcmp(weaponName, "weapon_fiveseven") == 0)
        return currentClip ? 20 : 100;
    else if (strcmp(weaponName, "weapon_deagle") == 0)
        return currentClip ? 7 : 35;
    else if (strcmp(weaponName, "weapon_revolver") == 0)
        return currentClip ? 8 : 8;
    else if (strcmp(weaponName, "weapon_hkp2000") == 0)
        return currentClip ? 13 : 52;
    else if (strcmp(weaponName, "weapon_usp_silencer") == 0)
        return currentClip ? 12 : 24;
    else if (strcmp(weaponName, "weapon_p250") == 0)
        return currentClip ? 13 : 26;
    else if (strcmp(weaponName, "weapon_elite") == 0)
        return currentClip ? 30 : 120;
    else if (strcmp(weaponName, "weapon_tec9") == 0)
        return currentClip ? 24 : 120;
    else if (strcmp(weaponName, "weapon_cz75a") == 0)
        return currentClip ? 12 : 12;
    return currentClip ? 30 : 90;
}

void Ammo_ClipRefill(int weaponRef, any client)
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
                case 60: clipSize = 25;
                case 61: clipSize = 12;
                case 63: clipSize = 12;
                case 64: clipSize = 8;
            }
        }

        SetEntProp(client, Prop_Send, "m_iAmmo", maxAmmoCount);
        SetEntProp(weaponEntity, Prop_Send, "m_iClip1", clipSize);
    }
}

void Ammo_ResRefill(int weaponRef, any client)
{
    int weaponEntity = EntRefToEntIndex(weaponRef);
    if (IsValidEdict(weaponEntity))
    {
        char weaponName[64];
        char maxAmmoCount;
        int ammoType = GetEntProp(weaponEntity, Prop_Send, "m_iPrimaryAmmoType", 1) * 4;

        if (GetEntityClassname(weaponEntity, weaponName, sizeof(weaponName)))
        {
            maxAmmoCount = GetWeaponAmmoCount(weaponName, false);
            switch (GetEntProp(weaponRef, Prop_Send, "m_iItemDefinitionIndex"))
            {
                case 60: maxAmmoCount = 75;
                case 61: maxAmmoCount = 24;
                case 63: maxAmmoCount = 12;
                case 64: maxAmmoCount = 8;
            }
        }

        SetEntData(client, g_iAmmoOffset + ammoType, maxAmmoCount, true);
    }
}

void Ammo_FullRefill(int weaponRef, any client)
{
    int weaponEntity = EntRefToEntIndex(weaponRef);
    if (IsValidEdict(weaponEntity))
    {
        char weaponName[64];
        char clipSize;
        int maxAmmoCount;
        int ammoType = GetEntProp(weaponEntity, Prop_Send, "m_iPrimaryAmmoType", 1) * 4;

        if (GetEntityClassname(weaponEntity, weaponName, sizeof(weaponName)))
        {
            clipSize = GetWeaponAmmoCount(weaponName, true);
            maxAmmoCount = GetWeaponAmmoCount(weaponName, false);
            switch (GetEntProp(weaponRef, Prop_Send, "m_iItemDefinitionIndex"))
            {
                case 60: {clipSize = 25;maxAmmoCount = 75;}
                case 61: {clipSize = 12;maxAmmoCount = 24;}
                case 63: {clipSize = 12;maxAmmoCount = 12;}
                case 64: {clipSize = 8;maxAmmoCount = 8;}
            }
        }

        SetEntData(client, g_iAmmoOffset + ammoType, maxAmmoCount, true);
        SetEntProp(weaponEntity, Prop_Send, "m_iClip1", clipSize);
    }
}

void PreviousClientWeapons(int client)
{
    int entProp;
    int entityIndex;
    int weaponEntity;
    char weaponName[32];

    for (int i = 0; i < 4; i++)
    {
        if ((entityIndex = GetPlayerWeaponSlot(client, i)) != -1)
        {
            if (GetEntityClassname(entityIndex, weaponName, sizeof(weaponName)))
            {
                weaponEntity = EntIndexToEntRef(entityIndex);
                entProp = GetEntProp(weaponEntity, Prop_Send, "m_iItemDefinitionIndex");
                switch (entProp)
                {
                    case 60: strcopy(weaponName, sizeof(weaponName), "weapon_m4a1_silencer");
                    case 61: strcopy(weaponName, sizeof(weaponName), "weapon_usp_silencer");
                    case 63: strcopy(weaponName, sizeof(weaponName), "weapon_cz75a");
                    case 64: strcopy(weaponName, sizeof(weaponName), "weapon_revolver");
                }

                if (i == CS_SLOT_PRIMARY)
                    g_sPrimaryWeaponPrevious[client] = weaponName;
                else if (i == CS_SLOT_SECONDARY)
                    g_sSecondaryWeaponPrevious[client] = weaponName;
            }
        }
    }
}

void RemoveClientWeapons(int client)
{
    int entityIndex;

    for (int i = 0; i < 4; i++)
    {
        if ((entityIndex = GetPlayerWeaponSlot(client, i)) != -1)
        {
            RemovePlayerItem(client, entityIndex);
            RemoveEntity(entityIndex);
        }
    }
}

void RemoveGroundWeapons()
{
    int MaxEntities = GetMaxEntities();
    char class[24];

    for (int i = MaxClients + 1; i < MaxEntities; i++)
    {
        if (!IsValidEdict(i)) continue;

        if (HasEntProp(i, Prop_Send, "m_hOwnerEntity") && (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == -1))
        {
            GetEdictClassname(i, class, sizeof(class));
            if ((StrContains(class, "weapon_") != -1) || (StrContains(class, "item_") != -1))
            {
                if (strcmp(class, "weapon_c4") == 0)
                {
                    if (!g_cvDM_remove_objectives.BoolValue)
                        continue;
                }
                RemoveEntity(i);
            }
        }
    }
}