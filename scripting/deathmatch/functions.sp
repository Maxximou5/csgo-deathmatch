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
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i))
            Client_ResetClientSettings(i);
    }
    g_bInEditMode = false;
    RespawnDead();
    char status[10];
    status = (g_cvDM_remove_objectives.BoolValue) ? "Disable" : "Enable";
    State_SetObjectives(status);
    status = (g_cvDM_remove_buyzones.BoolValue) ? "Disable" : "Enable";
    State_SetBuyZones(status);
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
        State_EnableFFA();
    else
        State_DisableFFA();
    if (!g_cvDM_spawn_default.BoolValue && g_cvDM_respawn_valve.BoolValue)
        State_SetSpawnPoints();
    if (g_cvDM_gun_menu_mode.IntValue != 6)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (g_cvDM_gun_menu_mode.IntValue >= 4)
                CancelClientMenu(i);
            if (IsClientConnected(i))
                SetClientGunModeSettings(i);
        }
    }
}

void State_DisableDM()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        Timer_DisableSpawnProtection(INVALID_HANDLE, i);
        if (g_hCookieMenus[i] != INVALID_HANDLE)
            CancelMenu(g_hCookieMenus[i])
        if (g_hWeaponsMenus[i] != INVALID_HANDLE)
            CancelMenu(g_hWeaponsMenus[i]);
        if (g_hPrimaryMenus[i] != INVALID_HANDLE)
            CancelMenu(g_hPrimaryMenus[i]);
        if (g_hSecondaryMenus[i] != INVALID_HANDLE)
            CancelMenu(g_hSecondaryMenus[i]);
        CancelClientMenu(i);
    }
    State_SetBuyZones("Enable");
    State_SetObjectives("Enable");
    State_RestoreSpawnPoints();
    State_RestoreSpawnWeapons();
    State_RestoreDropWeapons();
    State_RestoreC4();
    State_RestoreCash();
    State_RestoreArmor();
    State_RestoreGrenade();
    State_RestoreHealthshot();
    State_RestoreGrenadeRadio();
}

void State_SetNoCash()
{
    g_cvMP_startmoney.SetInt(0);
    g_cvMP_playercashawards.SetInt(0);
    g_cvMP_teamcashawards.SetInt(0);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
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
        if (IsClientInGame(i))
            SetEntProp(i, Prop_Send, "m_iAccount", g_iBackup_mp_startmoney);
    }
}

void State_SetNoChickens()
{
    char chicken = -1;
    while ((chicken = FindEntityByClassname(chicken, "chicken")) != -1)
    if (IsValidEdict(chicken))
        AcceptEntityInput(chicken, "Kill");
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
    g_cvMP_free_armor.SetInt(g_cvDM_armor.IntValue);
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
    g_cvMP_ct_default_primary.SetString(g_cBackup_mp_ct_default_primary);
    g_cvMP_t_default_primary.SetString(g_cBackup_mp_t_default_primary);
    g_cvMP_ct_default_secondary.SetString(g_cBackup_mp_ct_default_secondary);
    g_cvMP_t_default_secondary.SetString(g_cBackup_mp_t_default_secondary);
    g_cvMP_items_prohibited.SetString(g_cBackup_mp_items_prohibited);
}

void State_EnableFFA()
{
    g_cvMP_teammates_are_enemies.SetInt(1);
    g_cvMP_friendlyfire.SetInt(1);
    g_cvMP_autokick.SetInt(0);
    g_cvMP_tkpunish.SetInt(0);
    g_cvFF_damage_reduction_bullets.SetFloat(1.0);
    g_cvFF_damage_reduction_grenade.SetFloat(1.0);
    g_cvFF_damage_reduction_other.SetFloat(1.0);
}

void State_DisableFFA()
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
        if (IsValidEdict(i))
        {
            GetEdictClassname(i, class, sizeof(class));
            if (StrEqual(class, "func_buyzone"))
                AcceptEntityInput(i, status);
        }
    }
}

void State_SetObjectives(const char[] status)
{
    int MaxEntities = GetMaxEntities();
    char class[24];

    for (int i = MaxClients + 1; i < MaxEntities; i++)
    {
        if (IsValidEdict(i))
        {
            GetEdictClassname(i, class, sizeof(class));
            if (StrEqual(class, "func_bomb_target") || StrEqual(class, "func_hostage_rescue"))
                AcceptEntityInput(i, status);
        }
    }
}

void State_SetHostages()
{
    int MaxEntities = GetMaxEntities();
    char class[24];

    for (int i = MaxClients + 1; i < MaxEntities; i++)
    {
        if (IsValidEdict(i))
        {
            GetEdictClassname(i, class, sizeof(class));
            if (StrEqual(class, "hostage_entity"))
                RemoveEntity(i);
        }
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

bool Client_StripC4(int client)
{
    if (client && IsPlayerAlive(client))
    {
        int entityIndex;
        char entityName[64];
        if ((entityIndex = GetPlayerWeaponSlot(client, CS_SLOT_C4)) != -1)
        {
            GetEntityClassname(entityIndex, entityName, sizeof(entityName));
            if (StrEqual(entityName, "weapon_c4"))
            {
                RemovePlayerItem(client, entityIndex);
                RemoveEntity(entityIndex);
                return true;
            }
        }
    }
    return false;
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

void Client_SetHSOnly(int client)
{
    char buffer[64];
    char cEnable[32];
    char cHSOnly[16];
    GetClientCookie(client, g_hHSOnly_Cookie, cHSOnly, sizeof(cHSOnly));
    g_bHSOnlyClient[client] = view_as<bool>(StringToInt(cHSOnly));
    cEnable = g_bHSOnlyClient[client] ? "Enabled" : "Disabled";
    cHSOnly =  g_bHSOnlyClient[client] ? "1" : "0";
    Format(buffer, sizeof(buffer), "HS Only Client %s", cEnable);
    CPrintToChat(client, "%t %t", "Chat Tag", buffer);
}

void Client_ToggleHSOnly(int client)
{
    g_bHSOnlyClient[client] = !g_bHSOnlyClient[client];
    char buffer[64];
    char cEnable[32];
    char cHSOnly[16];
    cEnable = g_bHSOnlyClient[client] ? "Enabled" : "Disabled";
    cHSOnly =  g_bHSOnlyClient[client] ? "1" : "0";
    Format(buffer, sizeof(buffer), "HS Only Client %s", cEnable);
    CPrintToChat(client, "%t %t", "Chat Tag", buffer);
    SetClientCookie(client, g_hHSOnly_Cookie, cHSOnly);
}

void Client_ResetClientSettings(int client)
{
    if (g_bInEditModeClient[client])
        DisableEditorMode(client);
    g_iLastEditorSpawnPoint[client] = -1;
    SetClientGunModeSettings(client);
    g_bInfoMessage[client] = false;
    g_bWeaponsGivenThisRound[client] = false;
    g_bPlayerMoved[client] = false;
    g_bPlayerHasZeus[client] = false;
    g_iHealthshotCount[client] = 0;
}