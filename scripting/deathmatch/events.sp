void HookMessages()
{
    /* Hook Client Messages */
    HookUserMessage(GetUserMessageId("TextMsg"), Event_TextMsg, true);
    HookUserMessage(GetUserMessageId("HintText"), Event_HintText, true);
    HookUserMessage(GetUserMessageId("RadioText"), Event_RadioText, true);
}

void HookEvents()
{
    /* Hook Events */
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
    HookEvent("round_prestart", Event_RoundPrestart, EventHookMode_PostNoCopy);
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
    HookEvent("weapon_fire_on_empty", Event_WeaponFireOnEmpty, EventHookMode_Post);
    HookEvent("hegrenade_detonate", Event_HegrenadeDetonate, EventHookMode_Post);
    HookEvent("smokegrenade_detonate", Event_SmokegrenadeDetonate, EventHookMode_Post);
    HookEvent("tagrenade_detonate", Event_TagrenadeDetonate, EventHookMode_Post);
    HookEvent("flashbang_detonate", Event_FlashbangDetonate, EventHookMode_Post);
    HookEvent("molotov_detonate", Event_MolotovDetonate, EventHookMode_Post);
    HookEvent("inferno_startburn", Event_InfernoStartburn, EventHookMode_Post);
    HookEvent("decoy_started", Event_DecoyStarted, EventHookMode_Post);
    HookEvent("bomb_dropped", Event_BombDropped, EventHookMode_Post);
    HookEvent("bomb_pickup", Event_BombPickup, EventHookMode_Post);
}

void HookTempEnts()
{
    AddTempEntHook("Blood Sprite", TE_OnWorldDecal);
    AddTempEntHook("Entity Decal", TE_OnWorldDecal);
    AddTempEntHook("EffectDispatch", TE_OnEffectDispatch);
    AddTempEntHook("World Decal", TE_OnWorldDecal);
    AddTempEntHook("Impact", TE_OnWorldDecal);
}

void HookSounds()
{
    /* Hook Sound Events */
    AddNormalSoundHook(view_as<NormalSHook>(Event_Sound));
}

public void Event_CvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    State_Validate();
    if (cvar == g_cvDM_enabled)
    {
        if (g_cvDM_enabled.BoolValue)
            State_EnableDM();
        else
            State_DisableDM();
    }
    else if (cvar == g_cvDM_remove_objectives)
    {
        char status[10];
        status = (g_cvDM_remove_objectives.BoolValue) ? "Disable" : "Enable";
        State_SetObjectives(status);
    }
    else if (cvar == g_cvDM_remove_buyzones)
    {
        char status[10];
        status = (g_cvDM_remove_buyzones.BoolValue) ? "Disable" : "Enable";
        State_SetBuyZones(status);
    }
    else if (cvar == g_cvDM_healthshot)
    {
        if (g_cvDM_healthshot.BoolValue)
            State_SetHealthshot();
        else
            State_RestoreHealthshot();
    }
    else if (cvar == g_cvDM_remove_cash)
    {
        if (g_cvDM_remove_cash.BoolValue)
            State_SetNoCash();
        else
            State_RestoreCash();
    }
    else if (cvar == g_cvDM_armor)
    {
        if (g_cvDM_armor.BoolValue)
            State_SetArmor();
        else
            State_RestoreArmor();
    }
    else if (cvar == g_cvDM_remove_chickens)
    {
        if (g_cvDM_remove_chickens.BoolValue)
            State_SetNoChickens();
    }
    else if (cvar == g_cvDM_remove_spawn_weapons)
    {
        if (g_cvDM_remove_spawn_weapons.BoolValue)
            State_SetNoSpawnWeapons();
        else
            State_RestoreSpawnWeapons();
    }
    else if (cvar == g_cvDM_remove_dropped_weapons)
    {
        if (g_cvDM_remove_dropped_weapons.BoolValue)
            State_SetNoDropWeapons();
        else
            State_RestoreDropWeapons();
    }
    else if (cvar == g_cvDM_remove_objectives)
    {
        if (g_cvDM_remove_objectives.BoolValue)
            State_SetNoC4();
        else
            State_RestoreC4();
    }
    else if (cvar == g_cvDM_free_for_all)
    {
        if (g_cvDM_free_for_all.BoolValue)
            State_EnableFFA();
        else
            State_DisableFFA();
    }
    else if (cvar == g_cvDM_gun_menu_mode)
    {
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
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        UpdateSpawnPoints();
        /* If the player joins spectator, close any open menu, and remove their ragdoll. */
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (client)
        {
            if (event.GetInt("team") > CS_TEAM_SPECTATOR)
            {
                if (g_cvDM_respawn.BoolValue)
                    CreateTimer(g_cvDM_respawn_time.FloatValue, Timer_Respawn, GetClientSerial(client));
            }
        }

        if (!event.GetBool("disconnect"))
            event.SetBool("silent", true);
    }
}

public Action Event_RoundPrestart(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        g_bRoundEnded = false;
        UpdateSpawnPoints();
    }
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        if (g_cvDM_remove_objectives.BoolValue)
            State_SetHostages();

        if (g_cvDM_remove_ground_weapons.BoolValue)
            RemoveGroundWeapons();

        if (g_bLoadedConfig)
            g_bLoadedConfig = false;

        UpdateSpawnPoints();
    }
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        g_bRoundEnded = true;
        if (g_bLoadConfig)
        {
            g_bLoadedConfig = true;
            LoadConfig(g_cLoadConfig);
        }

        UpdateSpawnPoints();
    }
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (client && GetClientTeam(client) > CS_TEAM_SPECTATOR)
        {
            if (!IsFakeClient(client))
            {
                if (g_cvDM_welcomemsg.BoolValue && !g_bInfoMessage[client])
                {
                    char config[256];
                    g_cvDM_config_name.GetString(config, sizeof(config));
                    PrintHintText(client, "This server is running:\nDeathmatch v%s\nMode: %s", PLUGIN_VERSION, config);
                    CPrintToChat(client, "%t This server is running {green}Deathmatch {default}v%s with mode: {purple}%s", "Chat Tag", PLUGIN_VERSION, config);
                }
                /* Hide radar. */
                if (g_cvDM_free_for_all.BoolValue || g_cvDM_hide_radar.BoolValue)
                    RequestFrame(Frame_RemoveRadar, GetClientSerial(client));
                /* Display help message. */
                if (!g_bInfoMessage[client])
                {
                    if (g_cvDM_gun_menu_mode.IntValue <= 3)
                        CPrintToChat(client, "%t %t", "Chat Tag", "Guns Menu");

                    CPrintToChat(client, "%t %t", "Chat Tag", "Settings Menu");

                    if (g_cvDM_headshot_only.BoolValue)
                        CPrintToChat(client, "%t %t", "Chat Tag", "HS Only");

                    g_bInfoMessage[client] = true;
                }
                char cRemember[24];
                GetClientCookie(client, g_hWeapon_Remember_Cookie, cRemember, sizeof(cRemember));
                g_bRememberChoice[client] = view_as<bool>(StringToInt(cRemember));
            }
            /* Teleport player to custom spawn point. */
            if (g_iSpawnPointCount > 0 && !g_cvDM_spawn_default.BoolValue)
            {
                UpdateSpawnPoints();
                MovePlayer(client);
            }
            /* Enable player spawn protection. */
            if (!g_bInEditModeClient[client] && g_cvDM_spawn_protection_time.FloatValue > 0.0)
                EnableSpawnProtection(client);
            else if (g_bInEditModeClient[client])
                EnableEditorMode(client)
            /* Set health. */
            if (g_cvDM_hp_start.IntValue != 100)
                SetEntityHealth(client, g_cvDM_hp_start.IntValue);
            /* Give armor. */
            switch (g_cvDM_armor.IntValue)
            {
                case 0:
                {
                    SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
                    SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
                }
                case 1:
                {
                    SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
                    SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
                }
                case 2:
                {
                    SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
                    SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
                }
            }
            g_bWeaponsGivenThisRound[client] = false;
            g_bGiveFullLoadout[client] = false;
             /* Remove weapons. */
            RemoveClientWeapons(client);
            if (g_cvDM_remove_objectives.BoolValue)
                Client_StripC4(client);
            /* Give weapons or display menu. */
            if (g_bRememberChoice[client] || IsFakeClient(client))
            {
                /* Give normal loadout if remembered. */
                if (g_cvDM_gun_menu_mode.IntValue == 1 || g_cvDM_gun_menu_mode.IntValue == 5)
                    GiveSavedWeapons(client, true, true);
                /* Give only primary weapons if remembered. */
                else if (g_cvDM_gun_menu_mode.IntValue == 2)
                    GiveSavedWeapons(client, true, false)
                /* Give only secondary weapons if remembered. */
                else if (g_cvDM_gun_menu_mode.IntValue == 3)
                    GiveSavedWeapons(client, false, true);
                /* Give only knife weapons if remembered. */
                else if (g_cvDM_gun_menu_mode.IntValue == 4)
                    GiveSavedWeapons(client, false, false);
            }
            /* Display the gun menu to new users. */
            else if (!IsFakeClient(client))
            {
                /* All weapons menu. */
                if (g_cvDM_gun_menu_mode.IntValue <= 3)
                    BuildWeaponsMenu(client);
            }
        }
    }
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        int victim = GetClientOfUserId(event.GetInt("userid"));
        int attacker = GetClientOfUserId(event.GetInt("attacker"));

        char weapon[32];
        event.GetString("weapon", weapon, sizeof(weapon));

        bool tazed = StrEqual(weapon, "taser");
        bool knifed = (StrContains(weapon, "knife") != -1 || StrContains(weapon, "bayonet") != -1);
        bool naded = StrEqual(weapon, "hegrenade");
        bool decoy = StrEqual(weapon, "decoy");
        bool inferno = StrEqual(weapon, "inferno");
        bool tactical = StrEqual(weapon, "tagrenade_projectile");
        bool headshot = event.GetBool("headshot");
        bool bchanged = false;

        /* Kill feed */
        if (g_cvDM_display_killfeed.BoolValue)
        {
            if (g_cvDM_display_killfeed_player.BoolValue)
            {
                event.BroadcastDisabled = true;

                if (attacker)
                {
                    char cACookie[24];
                    GetClientCookie(attacker, g_hKillFeed_Cookie, cACookie, sizeof(cACookie));
                    g_bKillFeed[attacker] = view_as<bool>(StringToInt(cACookie));
                }
                if (victim)
                {
                    char cVCookie[24];
                    GetClientCookie(victim, g_hKillFeed_Cookie, cVCookie, sizeof(cVCookie));
                    g_bKillFeed[victim] = view_as<bool>(StringToInt(cVCookie));
                }
                if (attacker && g_bKillFeed[attacker] && !IsFakeClient(attacker))
                    event.FireToClient(attacker);

                if (victim && g_bKillFeed[victim] && attacker != victim && !IsFakeClient(victim))
                    event.FireToClient(victim);
            }
        }
        else
            event.BroadcastDisabled = true;

        /* Reward attacker with HP. */
        if (attacker && IsPlayerAlive(attacker))
        {
            int attackerHP = GetClientHealth(attacker);
            int attackerAP = GetClientArmor(attacker);

            /* Reward the attacker with ammo. */
            if (g_cvDM_replenish_ammo_kill.BoolValue)
                RequestFrame(Frame_GiveAmmo, GetClientSerial(attacker));
            if (g_cvDM_replenish_ammo_hs_kill.BoolValue && headshot)
                RequestFrame(Frame_GiveAmmoHS, GetClientSerial(attacker));

            if (g_cvDM_hp_messages.BoolValue || g_cvDM_ap_messages.BoolValue)
            {
                if ((g_cvDM_hp_messages.BoolValue && g_cvDM_ap_messages.BoolValue) && attackerAP < g_cvDM_ap_max.IntValue && attackerHP < g_cvDM_hp_max.IntValue)
                {
                    if (knifed)
                        CPrintToChat(attacker, "%t \x04+%i HP\x01 & \x04+%i AP\x01 %t", "Chat Tag", g_cvDM_hp_knife.IntValue, g_cvDM_ap_knife.IntValue, "Knife Kill");
                    else if (headshot)
                        CPrintToChat(attacker, "%t \x04+%i HP\x01 & \x04+%i AP\x01 %t", "Chat Tag", g_cvDM_hp_headshot.IntValue, g_cvDM_ap_headshot.IntValue, "Headshot Kill");
                    else if (naded || decoy || inferno)
                        CPrintToChat(attacker, "%t \x04+%i HP\x01 & \x04+%i AP\x01 %t", "Chat Tag", g_cvDM_hp_nade.IntValue, g_cvDM_ap_nade.IntValue, "Nade Kill");
                    else
                        CPrintToChat(attacker, "%t \x04+%i HP\x01 & \x04+%i AP\x01 %t", "Chat Tag", g_cvDM_hp_kill.IntValue, g_cvDM_ap_kill.IntValue, "Kill");

                    SetEntProp(attacker, Prop_Send, "m_iHealth", AddHealthToPlayer(attackerHP, knifed, headshot, naded, decoy, inferno), 1);
                    SetEntProp(attacker, Prop_Send, "m_ArmorValue", AddArmorToPlayer(attackerAP, knifed, headshot, naded, decoy, inferno), 1);

                    bchanged = true;
                }
                else if (g_cvDM_hp_messages.BoolValue && !bchanged && attackerHP < g_cvDM_hp_max.IntValue)
                {
                    if (knifed)
                        CPrintToChat(attacker, "%t \x04+%i HP\x01 %t", "Chat Tag", g_cvDM_hp_knife.IntValue, "Knife Kill");
                    else if (headshot)
                        CPrintToChat(attacker, "%t \x04+%i HP\x01 %t", "Chat Tag", g_cvDM_hp_headshot.IntValue, "Headshot Kill");
                    else if (naded || decoy || inferno)
                        CPrintToChat(attacker, "%t \x04+%i HP\x01 %t", "Chat Tag", g_cvDM_hp_nade.IntValue, "Nade Kill");
                    else
                        CPrintToChat(attacker, "%t \x04+%i HP\x01 %t", "Chat Tag", g_cvDM_hp_kill.IntValue, "Kill");

                    SetEntProp(attacker, Prop_Send, "m_iHealth", AddHealthToPlayer(attackerHP, knifed, headshot, naded, decoy, inferno), 1);

                    bchanged = true;
                }
                else if (g_cvDM_ap_messages.BoolValue && !bchanged && attackerAP < g_cvDM_ap_max.IntValue)
                {
                    if (knifed)
                        CPrintToChat(attacker, "%t \x04+%i AP\x01 %t", "Chat Tag", g_cvDM_ap_knife.IntValue, "Knife Kill");
                    else if (headshot)
                        CPrintToChat(attacker, "%t \x04+%i AP\x01 %t", "Chat Tag", g_cvDM_ap_headshot.IntValue, "Headshot Kill");
                    else if (naded || decoy || inferno)
                        CPrintToChat(attacker, "%t \x04+%i AP\x01 %t", "Chat Tag", g_cvDM_ap_nade.IntValue, "Nade Kill");
                    else
                        CPrintToChat(attacker, "%t \x04+%i AP\x01 %t", "Chat Tag", g_cvDM_ap_kill.IntValue, "Kill");

                    SetEntProp(attacker, Prop_Send, "m_ArmorValue", AddArmorToPlayer(attackerAP, knifed, headshot, naded, decoy, inferno), 1);
                }
            }
            /* Reward taser for kill. */
            if (g_cvDM_zeus.BoolValue && (g_cvDM_zeus_kill.BoolValue || (g_cvDM_zeus_kill_knife.BoolValue && knifed) || (g_cvDM_zeus_kill_taser.BoolValue && tazed)))
                RequestFrame(Frame_GiveTaser, GetClientSerial(attacker));
            /* Reward healthshot for kill. */
            if (g_cvDM_healthshot.BoolValue && (g_cvDM_healthshot_kill.BoolValue || (g_cvDM_healthshot_kill_knife.BoolValue && knifed)))
                RequestFrame(Frame_GiveHealthshot, GetClientSerial(attacker));
            /* Replenish grenades. */
            if (g_cvDM_replenish_grenade_kill.BoolValue)
            {
                if (naded)
                    GivePlayerItem(attacker, "weapon_hegrenade");
                if (inferno)
                {
                    int clientTeam = GetClientTeam(attacker);
                    if (clientTeam == CS_TEAM_CT)
                        GivePlayerItem(attacker, "weapon_incgrenade");
                    else if (clientTeam == CS_TEAM_T)
                        GivePlayerItem(attacker, "weapon_molotov");
                }
                if (decoy)
                    GivePlayerItem(attacker, "weapon_decoy");
                if (tactical)
                    GivePlayerItem(attacker, "weapon_tagrenade");
            }
        }
        /* Remove and respawn victim. */
        UpdateSpawnPoints();
        if (g_cvDM_respawn.BoolValue)
            CreateTimer(g_cvDM_respawn_time.FloatValue, Timer_Respawn, GetClientSerial(victim));
        if (g_cvDM_remove_ragdoll.BoolValue)
            CreateTimer(g_cvDM_remove_ragdoll_time.FloatValue, Timer_Ragdoll, GetClientSerial(victim));
    }
    return Plugin_Continue;
}

int AddHealthToPlayer(int attackerHP, bool knifed, bool headshot, bool naded, bool decoy, bool inferno)
{
    int addHP;

    if (knifed)
        addHP = g_cvDM_hp_knife.IntValue;
    else if (headshot)
        addHP = g_cvDM_hp_headshot.IntValue;
    else if (naded || decoy || inferno)
        addHP = g_cvDM_hp_nade.IntValue;
    else
        addHP = g_cvDM_hp_kill.IntValue;

    int newHP = attackerHP + addHP;

    if (newHP > g_cvDM_hp_max.IntValue)
        newHP = g_cvDM_hp_max.IntValue;

    return newHP;
}

int AddArmorToPlayer(int attackerAP, bool knifed, bool headshot, bool naded, bool decoy, bool inferno)
{
    int addAP;

    if (knifed)
        addAP = g_cvDM_ap_knife.IntValue;
    else if (headshot)
        addAP = g_cvDM_ap_headshot.IntValue;
    else if (naded || decoy || inferno)
        addAP = g_cvDM_ap_nade.IntValue;
    else
        addAP = g_cvDM_ap_kill.IntValue;

    int newAP = attackerAP + addAP;

    if (newAP > g_cvDM_ap_max.IntValue)
        newAP = g_cvDM_ap_max.IntValue;

    return newAP;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        int victim = GetClientOfUserId(event.GetInt("userid"));
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        int dhealth = event.GetInt("dmg_health");
        int darmor = event.GetInt("dmg_armor");
        int health = event.GetInt("health");
        int armor = event.GetInt("armor");

        if (attacker && attacker != victim && victim != 0 && !IsFakeClient(attacker))
        {
            char cCookie[24];
            GetClientCookie(attacker, g_hDamage_Panel_Cookie, cCookie, sizeof(cCookie));
            g_bDamagePanel[attacker] = view_as<bool>(StringToInt(cCookie));
            GetClientCookie(attacker, g_hDamage_Popup_Cookie, cCookie, sizeof(cCookie));
            g_bDamagePopup[attacker] = view_as<bool>(StringToInt(cCookie));
            GetClientCookie(attacker, g_hDamage_Text_Cookie, cCookie, sizeof(cCookie));
            g_bDamageText[attacker] = view_as<bool>(StringToInt(cCookie));

            if (g_cvDM_display_damage_panel.BoolValue && g_bDamagePanel[attacker])
            {
                if (health > 0)
                    PrintHintText(attacker, "%t %i %t %N\n%t %i", "Display Damage Giver", dhealth, "Display Damage Taker", victim, "Display Health Remaining", health);
                else if (health <= 0)
                    PrintHintText(attacker, "%t %i %t %N\n%t %i\n%t", "Display Damage Giver", dhealth, "Display Damage Taker", victim, "Display Health Remaining", health, "Display Kill Confirmed");
            }

            if (g_cvDM_display_damage_popup.BoolValue && g_bDamagePopup[attacker])
            {
                int textsize;
                char sColor[16];
                char sSize[4];
                char sMsg[8];
                float position[3];
                float clientEye[3];
                float clientAngles[3];
                GetClientEyePosition(attacker, clientEye);
                GetClientEyeAngles(attacker, clientAngles);
                TR_TraceRayFilter(clientEye, clientAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterHitSelf, attacker);
                if (TR_DidHit(INVALID_HANDLE))
                    TR_GetEndPosition(position);
                int entity = CreateEntityByName("point_worldtext");

                if (entity != -1)
                {
                    if (dhealth >= 65)
                    {
                        textsize = GetRandomInt(19, 23);
                        IntToString(textsize, sSize, sizeof(sSize));
                        Format(sColor, sizeof(sColor), "255 0 0");
                    }
                    if (dhealth <= 64)
                    {
                        textsize = GetRandomInt(14, 18);
                        IntToString(textsize, sSize, sizeof(sSize));
                        Format(sColor, sizeof(sColor), "255 255 0");
                    }
                    if (dhealth <= 25)
                    {
                        textsize = GetRandomInt(10, 13);
                        IntToString(textsize, sSize, sizeof(sSize));
                        Format(sColor, sizeof(sColor), "255 255 255");
                    }
                    IntToString(dhealth, sMsg, sizeof(sMsg));
                    DispatchKeyValue(entity, "message", sMsg);
                    DispatchKeyValue(entity, "textsize", sSize);
                    DispatchKeyValue(entity, "color", sColor);
                    SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", attacker);
                    SetEntFlags(entity);
                    SDKHook(entity, SDKHook_SetTransmit, Hook_OnSetTransmit);
                    TeleportEntity(entity, position, clientAngles, NULL_VECTOR);
                    CreateTimer(0.5, Timer_KillText, EntIndexToEntRef(entity));
                }
            }

            if (g_cvDM_display_damage_text.BoolValue && g_bDamageText[attacker])
            {
                if (health > 0)
                    CPrintToChat(attacker, "%t {red}%i{default} %t {purple}%N{default}. %t {green}%i{default}.", "Display Damage Giver", dhealth, "Display Damage Taker", victim, "Display Health Remaining", health);
                else if (health <= 0)
                    CPrintToChat(attacker, "%t {red}%i{default} %t {purple}%N{default}. %t {green}%i{default}. %t", "Display Damage Giver", dhealth, "Display Damage Taker", victim, "Display Health Remaining", health, "Display Kill Confirmed");
            }
        }

        if (g_cvDM_headshot_only.BoolValue || ((attacker && g_bHSOnlyClient[attacker]) && g_cvDM_headshot_only_allow_client.BoolValue))
        {
            char weapon[32];
            event.GetString("weapon", weapon, sizeof(weapon));

            if (!g_cvDM_headshot_only_allow_nade.BoolValue)
            {
                if (StrEqual(weapon, "hegrenade", false))
                {
                    if (attacker != victim && victim != 0)
                    {
                        if (dhealth > 0)
                            SetEntProp(victim, Prop_Send, "m_iHealth", (health + dhealth));

                        if (darmor > 0)
                            SetEntProp(victim, Prop_Send, "m_ArmorValue", (armor + darmor));

                    }
                }
            }

            if (!g_cvDM_headshot_only_allow_taser.BoolValue)
            {
                if (StrEqual(weapon, "taser", false))
                {
                    if (attacker != victim && victim != 0)
                    {
                        if (dhealth > 0)
                            SetEntProp(victim, Prop_Send, "m_iHealth", (health + dhealth));

                        if (darmor > 0)
                            SetEntProp(victim, Prop_Send, "m_ArmorValue", (armor + darmor));
                    }
                }
            }

            if (!g_cvDM_headshot_only_allow_knife.BoolValue)
            {
                if (StrEqual(weapon, "knife", false))
                {
                    if (attacker != victim && victim != 0)
                    {
                        if (dhealth > 0)
                            SetEntProp(victim, Prop_Send, "m_iHealth", (health + dhealth));

                        if (darmor > 0)
                            SetEntProp(victim, Prop_Send, "m_ArmorValue", (armor + darmor));
                    }
                }
            }

            if (!g_cvDM_headshot_only_allow_world.BoolValue)
            {
                if (attacker == 0 && victim != 0)
                {
                    if (dhealth > 0)
                        SetEntProp(victim, Prop_Send, "m_iHealth", (health + dhealth));

                    if (darmor > 0)
                        SetEntProp(victim, Prop_Send, "m_ArmorValue", (armor + darmor));
                }
            }
        }
    }
    return Plugin_Continue;
}


public void Event_BombDropped(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_remove_objectives.BoolValue)
    {
        char entityName[24];
        int entity = GetClientOfUserId(event.GetInt("entindex"));
        GetEntityClassname(entity, entityName, sizeof(entityName));
        if (StrEqual(entityName, "weapon_c4"))
            RemoveEntity(entity);
    }
}

public void Event_BombPickup(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_remove_objectives.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        Client_StripC4(client);
    }
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        char weapon[64];
        event.GetString("weapon", weapon, sizeof(weapon));
        if (StrEqual(weapon, "weapon_taser"))
            g_bPlayerHasZeus[client] = false;
    }
}

public Action Event_WeaponFireOnEmpty(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_ammo_empty.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        RequestFrame(Frame_GiveAmmo, GetClientSerial(client));
    }
}

public Action Event_HegrenadeDetonate(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (client && IsPlayerAlive(client))
            GivePlayerItem(client, "weapon_hegrenade");
    }

    return Plugin_Continue;
}

public Action Event_SmokegrenadeDetonate(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (client && IsPlayerAlive(client))
            GivePlayerItem(client, "weapon_smokegrenade");
    }

    return Plugin_Continue;
}

public Action Event_TagrenadeDetonate(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (client && IsPlayerAlive(client))
            GivePlayerItem(client, "weapon_tagrenade");
    }

    return Plugin_Continue;
}

public Action Event_FlashbangDetonate(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (client && IsPlayerAlive(client))
            GivePlayerItem(client, "weapon_flashbang");
    }

    return Plugin_Continue;
}

public Action Event_DecoyStarted(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (client && IsPlayerAlive(client))
            GivePlayerItem(client, "weapon_decoy");
    }

    return Plugin_Continue;
}

public Action Event_MolotovDetonate(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (client && IsPlayerAlive(client))
            GivePlayerItem(client, "weapon_molotov");
    }

    return Plugin_Continue;
}

public Action Event_InfernoStartburn(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (client && IsPlayerAlive(client))
            GivePlayerItem(client, "weapon_incgrenade");
    }

    return Plugin_Continue;
}

public Action Event_Sound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
    if (g_cvDM_enabled.BoolValue)
    {
        int client;
        if ((entity > 0) && (entity <= MaxClients))
            client = entity;

        /* Block ammo pickup sounds. */
        if (StrContains(sample, "pickup") != -1)
            return Plugin_Stop;

        /* Block all sounds originating from players not yet moved. */
        if (client && !g_bPlayerMoved[client])
            return Plugin_Stop;

        if (g_cvDM_free_for_all.BoolValue)
        {
            if (StrContains(sample, "friendlyfire") != -1)
                return Plugin_Stop;
        }

        if (!g_cvDM_sounds_headshots.BoolValue)
        {
            if (StrContains(sample, "physics/flesh/flesh_bloody") != -1 || StrContains(sample, "player/bhit_helmet") != -1 || StrContains(sample, "player/headshot") != -1)
                return Plugin_Stop;
        }

        if (!g_cvDM_sounds_bodyshots.BoolValue)
        {
            if (StrContains(sample, "physics/body") != -1 || StrContains(sample, "physics/flesh") != -1 || StrContains(sample, "player/kevlar") != -1)
                return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (g_cvDM_remove_chickens.BoolValue)
        if (StrEqual(classname, "chicken"))
            AcceptEntityInput(entity, "kill");
}

public Action Event_TextMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if (g_cvDM_cash_messages.BoolValue)
    {
        char text[64];
        if (GetUserMessageType() == UM_Protobuf)
            PbReadString(msg, "params", text, sizeof(text), 0);
        else
            BfReadString(msg, text, sizeof(text));

        if (StrContains(text, "#Chat_SavePlayer_", false) != -1)
            return Plugin_Handled;

        static char cashTriggers[][] =
        {
            "#Team_Cash_Award_Win_Hostages_Rescue",
            "#Team_Cash_Award_Win_Defuse_Bomb",
            "#Team_Cash_Award_Win_Time",
            "#Team_Cash_Award_Elim_Bomb",
            "#Team_Cash_Award_Elim_Hostage",
            "#Team_Cash_Award_T_Win_Bomb",
            "#Player_Point_Award_Assist_Enemy_Plural",
            "#Player_Point_Award_Assist_Enemy",
            "#Player_Point_Award_Killed_Enemy_Plural",
            "#Player_Point_Award_Killed_Enemy",
            "#Player_Cash_Award_Kill_Hostage",
            "#Player_Cash_Award_Damage_Hostage",
            "#Player_Cash_Award_Get_Killed",
            "#Player_Cash_Award_Respawn",
            "#Player_Cash_Award_Interact_Hostage",
            "#Player_Cash_Award_Killed_Enemy",
            "#Player_Cash_Award_Rescued_Hostage",
            "#Player_Cash_Award_Bomb_Defused",
            "#Player_Cash_Award_Bomb_Planted",
            "#Player_Cash_Award_Killed_Enemy",
            "#Player_Cash_Award_Killed_Enemy_Generic",
            "#Player_Cash_Award_Killed_VIP",
            "#Player_Cash_Award_Kill_Teammate",
            "#Team_Cash_Award_Win_Hostage_Rescue",
            "#Team_Cash_Award_Loser_Bonus",
            "#Team_Cash_Award_Loser_Zero",
            "#Team_Cash_Award_Rescued_Hostage",
            "#Team_Cash_Award_Hostage_Interaction",
            "#Team_Cash_Award_Hostage_Alive",
            "#Team_Cash_Award_Planted_Bomb_But_Defused",
            "#Team_Cash_Award_CT_VIP_Escaped",
            "#Team_Cash_Award_T_VIP_Killed",
            "#Team_Cash_Award_no_income",
            "#Team_Cash_Award_Generic",
            "#Team_Cash_Award_Custom",
            "#Team_Cash_Award_no_income_suicide",
            "#Player_Cash_Award_ExplainSuicide_YouGotCash",
            "#Player_Cash_Award_ExplainSuicide_TeammateGotCash",
            "#Player_Cash_Award_ExplainSuicide_EnemyGotCash",
            "#Player_Cash_Award_ExplainSuicide_Spectators"
        };
        for (int i = 0; i < sizeof(cashTriggers); i++)
        {
            if (StrEqual(text, cashTriggers[i]))
                return Plugin_Handled;
        }
    }

    if (g_cvDM_free_for_all.BoolValue)
    {
        char text[64];
        if (GetUserMessageType() == UM_Protobuf)
            PbReadString(msg, "params", text, sizeof(text), 0);
        else
            BfReadString(msg, text, sizeof(text));

        if (StrContains(text, "#SFUI_Notice_Killed_Teammate") != -1)
            return Plugin_Handled;

        if (StrContains(text, "#Cstrike_TitlesTXT_Game_teammate_attack") != -1)
            return Plugin_Handled;

        if (StrContains(text, "#Hint_try_not_to_injure_teammates") != -1)
            return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action Event_HintText(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if (g_cvDM_free_for_all.BoolValue)
    {
        char text[64];
        if (GetUserMessageType() == UM_Protobuf)
            PbReadString(msg, "text", text, sizeof(text));
        else
            BfReadString(msg, text, sizeof(text));

        if (StrContains(text, "#SFUI_Notice_Hint_careful_around_teammates") != -1)
            return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action Event_RadioText(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    if (g_cvDM_nade_messages.BoolValue)
    {
        static char grenadeTriggers[][] =
        {
            "#SFUI_TitlesTXT_Fire_in_the_hole",
            "#SFUI_TitlesTXT_Flashbang_in_the_hole",
            "#SFUI_TitlesTXT_Smoke_in_the_hole",
            "#SFUI_TitlesTXT_Decoy_in_the_hole",
            "#SFUI_TitlesTXT_Molotov_in_the_hole",
            "#SFUI_TitlesTXT_Incendiary_in_the_hole"
        };

        char text[64];
        if (GetUserMessageType() == UM_Protobuf)
        {
            PbReadString(msg, "msg_name", text, sizeof(text));
            /* 0: name */
            /* 1: msg_name == #Game_radio_location ? location : translation phrase */
            /* 2: if msg_name == #Game_radio_location : translation phrase */
            if (StrContains(text, "#Game_radio_location") != -1)
                PbReadString(msg, "params", text, sizeof(text), 2);
            else
                PbReadString(msg, "params", text, sizeof(text), 1);
        }
        else
        {
            BfReadString(msg, text, sizeof(text));
            if (StrContains(text, "#Game_radio_location") != -1)
                BfReadString(msg, text, sizeof(text));
        }

        for (int i = 0; i < sizeof(grenadeTriggers); i++)
        {
            if (StrEqual(text, grenadeTriggers[i]))
                return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action Hook_OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    if (!g_cvDM_enabled.BoolValue || !(0 < attacker <= MaxClients) || !IsClientInGame(attacker))
        return Plugin_Continue;

    if (g_cvDM_remove_knife_damage.BoolValue)
    {
        char knife[32];
        GetClientWeapon(attacker, knife, sizeof(knife));
        if (StrContains(knife, "knife") != -1 || StrContains(knife, "bayonet") != -1)
            return Plugin_Handled;
    }

    if (g_cvDM_headshot_only.BoolValue || (g_cvDM_headshot_only_allow_client.BoolValue && g_bHSOnlyClient[attacker]))
    {
        char weapon[32];
        char grenade[32];
        GetEdictClassname(inflictor, grenade, sizeof(grenade));
        GetClientWeapon(attacker, weapon, sizeof(weapon));

        if (hitgroup == 1)
            return Plugin_Continue;
        else if (g_cvDM_headshot_only_allow_knife.BoolValue && (StrContains(weapon, "knife") != -1 || StrContains(weapon, "bayonet") != -1))
            return Plugin_Continue;
        else if (g_cvDM_headshot_only_allow_nade.BoolValue && (StrEqual(grenade, "hegrenade_projectile") || StrEqual(grenade, "decoy_projectile") || StrEqual(grenade, "molotov_projectile") || StrEqual(grenade, "tagrenade_projectile")))
            return Plugin_Continue;
        else if (g_cvDM_headshot_only_allow_taser.BoolValue && StrEqual(weapon, "weapon_taser"))
            return Plugin_Continue;
        else
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!g_cvDM_enabled.BoolValue || !(0 < attacker <= MaxClients) || !IsClientInGame(attacker))
        return Plugin_Continue;

    if (g_cvDM_remove_knife_damage.BoolValue)
    {
        char knife[32];
        GetClientWeapon(attacker, knife, sizeof(knife));
        if (StrContains(knife, "knife") != -1 || StrContains(knife, "bayonet") != -1)
            return Plugin_Handled;
    }

    if (g_cvDM_headshot_only.BoolValue || (g_cvDM_headshot_only_allow_client.BoolValue && g_bHSOnlyClient[attacker]))
    {
        char grenade[32];
        char weapon[32];

        if (victim)
        {
            if (damagetype & DMG_FALL || attacker == 0)
            {
                if (g_cvDM_headshot_only_allow_world.BoolValue)
                    return Plugin_Continue;
                else
                    return Plugin_Handled;
            }
            if (attacker && IsClientInGame(attacker))
            {
                GetEdictClassname(inflictor, grenade, sizeof(grenade));
                GetClientWeapon(attacker, weapon, sizeof(weapon));

                if (damagetype & DMG_HEADSHOT)
                    return Plugin_Continue;
                else
                {
                    if (g_cvDM_headshot_only_allow_knife.BoolValue && (StrContains(weapon, "knife") != -1 || StrContains(weapon, "bayonet") != -1))
                        return Plugin_Continue;
                    else if (g_cvDM_headshot_only_allow_nade.BoolValue && (StrEqual(grenade, "hegrenade_projectile") || StrEqual(grenade, "decoy_projectile") || StrEqual(grenade, "molotov_projectile") || StrEqual(grenade, "tagrenade_projectile")))
                        return Plugin_Continue;
                    else if (g_cvDM_headshot_only_allow_taser.BoolValue && StrEqual(weapon, "weapon_taser"))
                        return Plugin_Continue;
                    else
                        return Plugin_Handled;
                }
            }
            else
                return Plugin_Handled;
        }
        else
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

public void Hook_OnReloadPost(int weapon, bool bSuccessful)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_ammo_reload.BoolValue)
    {
        int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
        if (IsValidEntity(client))
            RequestFrame(Frame_GiveAmmo, GetClientSerial(client));
    }
}

public Action Hook_OnWeaponEquip(int client, int weapon)
{
    char weaponName[64];
    GetEntityClassname(weapon, weaponName, sizeof(weaponName));
    if (StrEqual(weaponName, "weapon_healthshot") && !g_cvDM_healthshot.BoolValue)
    {
        RemovePlayerItem(client, weapon);
        RemoveEntity(weapon);
        ClientCommand(client, "lastinv");
        return Plugin_Continue
    }
    if (StrEqual(weaponName, "weapon_taser") && !g_cvDM_zeus.BoolValue)
    {
        RemovePlayerItem(client, weapon);
        RemoveEntity(weapon);
        ClientCommand(client, "lastinv");
        return Plugin_Continue
    }
    if (StrEqual(weaponName, "weapon_c4") && g_cvDM_remove_objectives.BoolValue)
    {
        RemovePlayerItem(client, weapon);
        RemoveEntity(weapon);
        ClientCommand(client, "lastinv");
        return Plugin_Continue
    }
    return Plugin_Continue
}

public Action Hook_OnWeaponSwitch(int client, int weapon)
{
    bool removeWeapon = false;
    char weaponName[64];
    GetEntityClassname(weapon, weaponName, sizeof(weaponName));
    if (StrEqual(weaponName, "weapon_healthshot") && !g_cvDM_healthshot.BoolValue)
        removeWeapon = true;
    else if (StrEqual(weaponName, "weapon_taser") && !g_cvDM_zeus.BoolValue)
        removeWeapon = true;
    else if (StrEqual(weaponName, "weapon_c4") && g_cvDM_remove_objectives.BoolValue)
        removeWeapon = true;
    if (removeWeapon)
    {
        RemovePlayerItem(client, weapon);
        RemoveEntity(weapon);
        ClientCommand(client, "lastinv");
        return Plugin_Continue
    }
    return Plugin_Continue
}

public Action Hook_OnSetTransmit(int entity, int client)
{
    SetEntFlags(entity);
    int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    if (client == owner) return Plugin_Continue;
    else return Plugin_Stop;
}

public void SetEntFlags(int entity)
{
    if (GetEdictFlags(entity) & FL_EDICT_ALWAYS)
        SetEdictFlags(entity, (GetEdictFlags(entity) ^ FL_EDICT_ALWAYS));
}

public Action TE_OnEffectDispatch(const char[] te_name, const Players[], int numClients, float delay)
{
    if (!g_cvDM_remove_blood_player.BoolValue)
        return Plugin_Continue;

    int iEffectIndex = TE_ReadNum("m_iEffectName");
    int nHitBox = TE_ReadNum("m_nHitBox");
    char sEffectName[64];

    GetEffectName(iEffectIndex, sEffectName, sizeof(sEffectName));

    if (StrEqual(sEffectName, "csblood") || StrEqual(sEffectName, "Impact"))
        return Plugin_Handled;

    if (StrEqual(sEffectName, "ParticleEffect"))
    {
        char sParticleEffectName[64];
        GetParticleEffectName(nHitBox, sParticleEffectName, sizeof(sParticleEffectName));
        if(StrEqual(sParticleEffectName, "impact_helmet_headshot"))
            return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action TE_OnWorldDecal(const char[] te_name, const Players[], int numClients, float delay)
{
    if (!g_cvDM_remove_blood_walls.BoolValue)
        return Plugin_Continue;

    float vecOrigin[3];
    int nIndex = TE_ReadNum("m_nIndex");
    char sDecalName[64];

    TE_ReadVector("m_vecOrigin", vecOrigin);
    GetDecalName(nIndex, sDecalName, sizeof(sDecalName));

    if (StrContains(sDecalName, "decals/blood") == 0 && StrContains(sDecalName, "_subrect") != -1)
        return Plugin_Handled;

    return Plugin_Continue;
}

public bool TraceEntityFilterHitSelf(int entity, int contentsMask, any data)
{
    if (entity == data) return false;
    return true;
}

public Action Timer_Ragdoll(Handle timer, any serial)
{
    int client = GetClientFromSerial(serial);
    if (client) Client_RemoveRagdoll(client);
}

public Action Timer_KillText(Handle timer, int ref)
{
    int entity = EntRefToEntIndex(ref);
    if (entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity)) return;
    SDKUnhook(entity, SDKHook_SetTransmit, Hook_OnSetTransmit);
    RemoveEntity(entity);
}

stock int GetParticleEffectName(int index, char[] sEffectName, int maxlen)
{
    int table = INVALID_STRING_TABLE;

    if (table == INVALID_STRING_TABLE)
        table = FindStringTable("ParticleEffectNames");

    return ReadStringTable(table, index, sEffectName, maxlen);
}

stock int GetEffectName(int index, char[] sEffectName, int maxlen)
{
    int table = INVALID_STRING_TABLE;

    if (table == INVALID_STRING_TABLE)
        table = FindStringTable("EffectDispatch");

    return ReadStringTable(table, index, sEffectName, maxlen);
}

stock int GetDecalName(int index, char[] sDecalName, int maxlen)
{
    int table = INVALID_STRING_TABLE;

    if (table == INVALID_STRING_TABLE)
        table = FindStringTable("decalprecache");

    return ReadStringTable(table, index, sDecalName, maxlen);
}