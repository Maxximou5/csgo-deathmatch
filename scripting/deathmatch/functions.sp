void State_Update()
{
    State_Validate();
    if (g_cvDM_enabled.BoolValue)
        State_EnableDM();
    else
        State_DisableDM();
}

void State_Validate()
{
    if (g_cvDM_respawn_time.FloatValue < 0.0) g_cvDM_respawn_time.FloatValue = 0.0;
    if (g_cvDM_gun_menu_mode.IntValue < 1) g_cvDM_gun_menu_mode.IntValue = 1;
    if (g_cvDM_gun_menu_mode.IntValue > 6) g_cvDM_gun_menu_mode.IntValue = 6;
    if (g_cvDM_spawn_los.IntValue < 0) g_cvDM_spawn_los.IntValue = 0;
    if (g_cvDM_spawn_los_attempts.IntValue < 0) g_cvDM_spawn_los_attempts.IntValue = 0;
    if (g_cvDM_spawn_distance.FloatValue < 0.0) g_cvDM_spawn_distance.FloatValue = 0.0;
    if (g_cvDM_spawn_distance_attempts.IntValue < 0) g_cvDM_spawn_distance_attempts.IntValue = 0;
    if (g_cvDM_spawn_protection_time.FloatValue < 0.0) g_cvDM_spawn_protection_time.FloatValue = 0.0;
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
    if (g_cvDM_armor.IntValue < 0) g_cvDM_armor.IntValue = 0;
    if (g_cvDM_nades_incendiary.IntValue < 0) g_cvDM_nades_incendiary.IntValue = 0;
    if (g_cvDM_nades_molotov.IntValue < 0) g_cvDM_nades_molotov.IntValue = 0;
    if (g_cvDM_nades_decoy.IntValue < 0) g_cvDM_nades_decoy.IntValue = 0;
    if (g_cvDM_nades_flashbang.IntValue < 0) g_cvDM_nades_flashbang.IntValue = 0;
    if (g_cvDM_nades_he.IntValue < 0) g_cvDM_nades_he.IntValue = 0;
    if (g_cvDM_nades_smoke.IntValue < 0) g_cvDM_nades_smoke.IntValue = 0;
    if (g_cvDM_nades_tactical.IntValue < 0) g_cvDM_nades_tactical.IntValue = 0;
}

void State_EnableDM()
{
    State_ResetDM();

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;
        Client_ResetClientSettings(i);
        g_bInfoMessage[i] = false;
        g_bWelcomeMessage[i] = false;
    }

    if (g_cvDM_gun_menu_mode.IntValue != 6)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i))
                continue;
            if (!IsFakeClient(i))
                CancelClientMenu(i);
            if (g_cvDM_gun_menu_mode.IntValue >= 4)
                SetClientGunModeSettings(i);
        }
    }

    Spawns_RespawnAll();
}

void State_ResetDM()
{
    g_bInEditMode = false;
    State_SetObjectives(g_cvDM_remove_objectives.BoolValue ? "Disable" : "Enable");
    State_SetBuyZones(g_cvDM_remove_buyzones.BoolValue ? "Disable" : "Enable");
    State_SetGrenade();
    State_SetHealthshot();
    State_SetArmor();
    if (g_cvDM_nade_messages.BoolValue)
        State_SetGrenadeRadio();
    if (g_cvDM_remove_cash.BoolValue)
        State_SetNoCash();
    if (g_cvDM_remove_chickens.BoolValue)
        State_SetNoChickens();
    if (g_cvDM_remove_spawn_weapons.BoolValue)
        State_SetNoSpawnWeapons();
    if (g_cvDM_remove_dropped_weapons.BoolValue)
        State_SetNoDropWeapons();
    if (g_cvDM_remove_objectives.BoolValue)
        State_SetNoC4();
    if (g_cvDM_free_for_all.BoolValue)
        State_SetFFA();
    else
        State_RestoreFFA();
    if (!g_cvDM_spawn_default.BoolValue && g_cvDM_respawn_valve.BoolValue)
        State_SetSpawnPoints();
}

void State_DisableDM()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;
        Timer_DisableSpawnProtection(null, i);
        OnClientDisconnect(i);
        CancelClientMenu(i);
    }
    State_RestoreC4();
    State_RestoreCash();
    State_RestoreArmor();
    State_RestoreGrenade();
    State_RestoreHealthshot();
    State_RestoreDropWeapons();
    State_RestoreSpawnPoints();
    State_RestoreSpawnWeapons();
    State_RestoreGrenadeRadio();
    State_SetBuyZones("Enable");
    State_SetObjectives("Enable");
}

void State_SetNoCash()
{
    g_cvMP_startmoney.SetInt(0);
    g_cvMP_playercashawards.SetInt(0);
    g_cvMP_teamcashawards.SetInt(0);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i)) continue;
        SetEntProp(i, Prop_Send, "m_iAccount", 0);
    }
}

void State_RestoreCash()
{
    g_cvMP_startmoney.SetInt(g_iBackup_mp_startmoney);
    g_cvMP_playercashawards.SetInt(g_iBackup_mp_playercashawards);
    g_cvMP_teamcashawards.SetInt(g_iBackup_mp_teamcashawards);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i)) continue;
        SetEntProp(i, Prop_Send, "m_iAccount", g_iBackup_mp_startmoney);
    }
}

void State_SetNoChickens()
{
    char chicken = -1;
    while ((chicken = FindEntityByClassname(chicken, "chicken")) != -1)
    if (IsValidEdict(chicken))
        RemoveEntity(chicken);
}

void State_SetGrenade()
{
    int maxGrenadesTotal =
        g_cvDM_nades_incendiary.IntValue +
        g_cvDM_nades_molotov.IntValue +
        g_cvDM_nades_decoy.IntValue +
        g_cvDM_nades_flashbang.IntValue +
        g_cvDM_nades_he.IntValue +
        g_cvDM_nades_smoke.IntValue +
        g_cvDM_nades_tactical.IntValue;
    int maxGrenadesSameType = 0;
    if (g_cvDM_nades_incendiary.IntValue > maxGrenadesSameType) maxGrenadesSameType = g_cvDM_nades_incendiary.IntValue;
    if (g_cvDM_nades_molotov.IntValue > maxGrenadesSameType) maxGrenadesSameType = g_cvDM_nades_molotov.IntValue;
    if (g_cvDM_nades_decoy.IntValue > maxGrenadesSameType) maxGrenadesSameType = g_cvDM_nades_decoy.IntValue;
    if (g_cvDM_nades_flashbang.IntValue > maxGrenadesSameType) maxGrenadesSameType = g_cvDM_nades_flashbang.IntValue;
    if (g_cvDM_nades_he.IntValue > maxGrenadesSameType) maxGrenadesSameType = g_cvDM_nades_he.IntValue;
    if (g_cvDM_nades_smoke.IntValue > maxGrenadesSameType) maxGrenadesSameType = g_cvDM_nades_smoke.IntValue;
    if (g_cvDM_nades_tactical.IntValue > maxGrenadesSameType) maxGrenadesSameType = g_cvDM_nades_tactical.IntValue;
    g_cvAmmo_grenade_limit_default.SetInt(maxGrenadesSameType);
    g_cvAmmo_grenade_limit_flashbang.SetInt(g_cvDM_nades_flashbang.IntValue);
    g_cvAmmo_grenade_limit_total.SetInt(maxGrenadesTotal);
}

void State_RestoreGrenade()
{
    g_cvAmmo_grenade_limit_default.SetInt(g_iBackup_ammo_grenade_limit_default);
    g_cvAmmo_grenade_limit_flashbang.SetInt(g_iBackup_ammo_grenade_limit_flashbang);
    g_cvAmmo_grenade_limit_total.SetInt(g_iBackup_ammo_grenade_limit_total);
}

void State_RestoreGrenadeRadio()
{
    g_cvSV_ignoregrenaderadio.SetInt(g_iBackup_sv_ignoregrenaderadio);
}

void State_SetGrenadeRadio()
{
    g_cvSV_ignoregrenaderadio.SetInt(1);
}

void State_RestoreHealthshot()
{
    g_cvHealthshot_health.SetInt(g_iBackup_healthshot_health);
    g_cvAmmo_item_limit_healthshot.SetInt(g_iBackup_ammo_item_limit_healthshot);
}

void State_SetHealthshot()
{
    g_cvHealthshot_health.SetInt(g_cvDM_healthshot_health.IntValue);
    g_cvAmmo_item_limit_healthshot.SetInt(g_cvDM_healthshot_total.IntValue);
}

void State_SetNoDropWeapons()
{
    g_cvMP_death_drop_c4.SetInt(0);
    g_cvMP_death_drop_defuser.SetInt(0);
    g_cvMP_death_drop_grenade.SetInt(0);
    g_cvMP_death_drop_gun.SetInt(0);
    g_cvMP_death_drop_taser.SetInt(0);
}

void State_RestoreDropWeapons()
{
    g_cvMP_death_drop_c4.SetInt(g_iBackup_mp_death_drop_c4);
    g_cvMP_death_drop_defuser.SetInt(g_iBackup_mp_death_drop_defuser);
    g_cvMP_death_drop_grenade.SetInt(g_iBackup_mp_death_drop_grenade);
    g_cvMP_death_drop_gun.SetInt(g_iBackup_mp_death_drop_gun);
    g_cvMP_death_drop_taser.SetInt(g_iBackup_mp_death_drop_taser);
}

void State_SetArmor()
{
    g_cvMP_free_armor.SetInt(0);
    g_cvMP_max_armor.SetInt(g_cvDM_armor.IntValue);
}

void State_RestoreArmor()
{
    g_cvMP_free_armor.SetInt(g_iBackup_free_armor);
    g_cvMP_max_armor.SetInt(g_iBackup_max_armor);
}

void State_SetSpawnPoints()
{
    g_cvMP_randomspawn.SetInt(1);
    g_cvMP_randomspawn_dist.SetInt(1);
    g_cvMP_randomspawn_los.SetInt(1);
}

void State_RestoreSpawnPoints()
{
    g_cvMP_randomspawn.SetInt(g_iBackup_mp_randomspawn);
    g_cvMP_randomspawn_dist.SetInt(g_iBackup_mp_randomspawn_dist);
    g_cvMP_randomspawn_los.SetInt(g_iBackup_mp_randomspawn_los);
}

void State_SetNoSpawnWeapons()
{
    g_cvMP_ct_default_primary.SetString("");
    g_cvMP_t_default_primary.SetString("");
    g_cvMP_ct_default_secondary.SetString("");
    g_cvMP_t_default_secondary.SetString("");
    g_cvMP_items_prohibited.SetString("");
}

void State_RestoreSpawnWeapons()
{
    g_cvMP_ct_default_primary.SetString(g_sBackup_mp_ct_default_primary);
    g_cvMP_t_default_primary.SetString(g_sBackup_mp_t_default_primary);
    g_cvMP_ct_default_secondary.SetString(g_sBackup_mp_ct_default_secondary);
    g_cvMP_t_default_secondary.SetString(g_sBackup_mp_t_default_secondary);
    g_cvMP_items_prohibited.SetString(g_sBackup_mp_items_prohibited);
}

void State_SetFFA()
{
    g_cvMP_teammates_are_enemies.SetInt(1);
    g_cvMP_friendlyfire.SetInt(1);
    g_cvMP_autokick.SetInt(0);
    g_cvMP_tkpunish.SetInt(0);
    g_cvFF_damage_reduction_bullets.SetFloat(1.0);
    g_cvFF_damage_reduction_grenade.SetFloat(1.0);
    g_cvFF_damage_reduction_other.SetFloat(1.0);
}

void State_RestoreFFA()
{
    g_cvMP_teammates_are_enemies.SetInt(g_iBackup_mp_teammates_are_enemies);
    g_cvMP_friendlyfire.SetInt(g_iBackup_mp_friendlyfire);
    g_cvMP_autokick.SetInt(g_iBackup_mp_autokick);
    g_cvMP_tkpunish.SetInt(g_iBackup_mp_tkpunish);
    g_cvFF_damage_reduction_bullets.SetFloat(g_fBackup_ff_damage_reduction_bullets);
    g_cvFF_damage_reduction_grenade.SetFloat(g_fBackup_ff_damage_reduction_grenade);
    g_cvFF_damage_reduction_other.SetFloat(g_fBackup_ff_damage_reduction_other);
}

void State_SetBuyZones(const char[] status)
{
    int MaxEntities = GetMaxEntities();
    char class[24];

    for (int i = MaxClients + 1; i < MaxEntities; i++)
    {
        if (!IsValidEdict(i)) continue;
        GetEdictClassname(i, class, sizeof(class));
        if (strcmp(class, "func_buyzone") == 0)
            AcceptEntityInput(i, status);
    }
}

void State_SetObjectives(const char[] status)
{
    int MaxEntities = GetMaxEntities();
    char class[24];

    for (int i = MaxClients + 1; i < MaxEntities; i++)
    {
        if (!IsValidEdict(i)) continue;
        GetEdictClassname(i, class, sizeof(class));
        if (strcmp(class, "func_bomb_target") == 0 || strcmp(class, "func_hostage_rescue") == 0)
            AcceptEntityInput(i, status);
    }
}

void State_SetHostages()
{
    int MaxEntities = GetMaxEntities();
    char class[24];

    for (int i = MaxClients + 1; i < MaxEntities; i++)
    {
        if (!IsValidEdict(i)) continue;
        GetEdictClassname(i, class, sizeof(class));
        if (strcmp(class, "hostage_entity") == 0)
            RemoveEntity(i);
    }
}

void State_SetNoC4()
{
    g_cvMP_give_player_c4.SetInt(0);
}

void State_RestoreC4()
{
    g_cvMP_give_player_c4.SetInt(g_iBackup_mp_give_player_c4);
}

public bool Client_StripC4(int client)
{
    int entityIndex;
    char entityName[64];
    if ((entityIndex = GetPlayerWeaponSlot(client, CS_SLOT_C4)) != -1)
    {
        GetEntityClassname(entityIndex, entityName, sizeof(entityName));
        if (strcmp(entityName, "weapon_c4") == 0)
        {
            RemovePlayerItem(client, entityIndex);
            RemoveEntity(entityIndex);
            return true;
        }
    }

    return false;
}

void Client_SetArmor(int client)
{
    switch (g_cvDM_armor.IntValue)
    {
        case 0: /* Give no armor and no helmet */
        {
            SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
            SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
        }
        case 1: /* Give only armor but no helmet */
        {
            SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
            SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
        }
        case 2: /* Give both armor and helmet */
        {
            SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
            SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
        }
    }
}

void Client_GiveWeaponsOrBuildMenu(int client)
{
    if (g_bRememberChoice[client] || IsFakeClient(client))
    {
        switch (g_cvDM_gun_menu_mode.IntValue)
        {
            case 1: GiveSavedWeapons(client, true, true); /* Give normal loadout if remembered. */
            case 2: GiveSavedWeapons(client, true, false); /* Give only primary weapons if remembered. */
            case 3: GiveSavedWeapons(client, false, true); /* Give only secondary weapons if remembered. */
            case 4: GiveSavedWeapons(client, false, false); /* Give only knife weapons if remembered. */
            case 5: GiveSavedWeapons(client, true, true); /* Give normal loadout if remembered. */
        }
    }
    else if (!IsFakeClient(client))
    {
        /* Display the gun menu to new users. */
        if (g_cvDM_gun_menu_mode.IntValue <= 3)
            BuildWeaponsMenu(client);
    }
}

void Client_RemoveRagdoll(int client)
{
    if (IsValidEdict(client))
    {
        int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
        if (ragdoll != -1)
            RemoveEntity(ragdoll);
    }
}

void Client_ToggleHSOnly(int client)
{
    char buffer[64];
    char cHSOnly[16];
    g_bHSOnlyClient[client] = !g_bHSOnlyClient[client];
    Format(buffer, sizeof(buffer), "Headshot Only %s", g_bHSOnlyClient[client] ? "Enabled" : "Disabled");
    CPrintToChat(client, "%t %t", "Chat Tag", buffer);
    SetClientCookie(client, g_hHSOnly_Cookie, cHSOnly);
}

void Client_ResetClientSettings(int client)
{
    if (g_bInEditModeClient[client])
        Spawns_DisableEditorMode(client);
    g_iLastEditorSpawnPoint[client] = -1;
    SetClientGunModeSettings(client);
    g_bWeaponsGivenThisRound[client] = false;
    g_bGiveFullLoadout[client] = false;
    g_bPlayerMoved[client] = false;
    g_bPlayerHasZeus[client] = false;
    g_iHealthshotCount[client] = 0;
    if (!IsFakeClient(client))
    {
        g_sPrimaryWeaponPrevious[client] = "none";
        g_sSecondaryWeaponPrevious[client] = "none";
    }
    for (int i = 1; i <= MaxClients; i++)
    {
        g_iDamageDone[client][i] = 0;
        g_iDamageDoneHits[client][i] = 0;
    }
}

void Client_ResetScoreboard(int client)
{
    SetEntProp(client, Prop_Data, "m_iFrags", 0);
    SetEntProp(client, Prop_Data, "m_iDeaths", 0);
    CS_SetMVPCount(client, 0);
    CS_SetClientAssists(client, 0);
    CS_SetClientContributionScore(client, 0);
    CPrintToChat(client, "%t %t", "Chat Tag", "Reset Score");
}

bool IsValidClient(int client, bool bots = false)
{
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bots) || IsClientSourceTV(client) || IsClientReplay(client))
    {
        return false;
    }
    return true;
}