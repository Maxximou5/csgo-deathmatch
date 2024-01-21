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
    /* Hook Temporary Entities */
    AddTempEntHook("Blood Sprite", TE_WorldDecal);
    AddTempEntHook("Entity Decal", TE_WorldDecal);
    AddTempEntHook("EffectDispatch", TE_EffectDispatch);
    AddTempEntHook("World Decal", TE_WorldDecal);
    AddTempEntHook("Impact", TE_WorldDecal);
    AddTempEntHook("Shotgun Shot", TE_ShotgunShot);
}

void HookSounds()
{
    /* Hook Sound Events */
    AddNormalSoundHook(Event_NormalSound);
    AddAmbientSoundHook(Event_AmbientSound);
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
        State_SetObjectives(g_cvDM_remove_objectives.BoolValue ? "Disable" : "Enable");
    }
    else if (cvar == g_cvDM_remove_buyzones)
    {
        State_SetBuyZones(g_cvDM_remove_buyzones.BoolValue ? "Disable" : "Enable");
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
            State_SetFFA();
        else
            State_RestoreFFA();
    }
    else if (cvar == g_cvDM_gun_menu_mode)
    {
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
    }
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        /* If the player joins spectator, close any open menu, and remove their ragdoll. */
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (!g_bRoundEnded && IsValidClient(client, true))
        {
            if (g_cvDM_respawn.BoolValue)
                CreateTimer(g_cvDM_respawn_time.FloatValue, Timer_Respawn, GetClientSerial(client));
        }

        if (!event.GetBool("disconnect"))
            event.SetBool("silent", true);
    }
    return Plugin_Continue;
}

public Action Event_RoundPrestart(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        g_bRoundEnded = false;
    }
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        g_bRoundEnded = false;

        if (g_cvDM_remove_objectives.BoolValue)
            State_SetHostages();

        if (g_cvDM_remove_ground_weapons.BoolValue)
            RemoveGroundWeapons();

        if (g_bLoadedConfig)
            g_bLoadedConfig = false;
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
            LoadConfig(g_sLoadConfig);
            State_ResetDM();
        }
    }
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (IsValidClient(client, true) && GetClientTeam(client) > CS_TEAM_SPECTATOR)
        {
            if (!IsFakeClient(client))
            {
                /* Freshly Baked */
                ClientCookiesRefresh(client);
                /* Hide radar. */
                if (g_cvDM_free_for_all.BoolValue || g_cvDM_hide_radar.BoolValue)
                    RequestFrame(Frame_RemoveRadar, GetClientSerial(client));
                /* Display welcome message. */
                if (g_cvDM_welcomemsg.BoolValue && !g_bWelcomeMessage[client])
                {
                    char config[256];
                    g_cvDM_config_name.GetString(config, sizeof(config));
                    PrintHintText(client, "Welcome to Tarik.GG:\nDeathmatch\nMode: %s", config);
                    CPrintToChat(client, "%t Welcome to Tarik.GG {green}Deathmatch {default}with mode: {purple}%s", "Chat Tag", config);
                    g_bWelcomeMessage[client] = true;
                }
                /* Display help message. */
                if (g_cvDM_infomsg.BoolValue && !g_bInfoMessage[client])
                {
                    if (g_cvDM_gun_menu_mode.IntValue <= 3)
                        CPrintToChat(client, "%t %t", "Chat Tag", "Guns Menu");
                    CPrintToChat(client, "%t %t", "Chat Tag", "Settings Menu");
                    if (g_cvDM_headshot_only.BoolValue)
                        CPrintToChat(client, "%t %t", "Chat Tag", "Headshot Only Enabled");
                    g_bInfoMessage[client] = true;
                }
            }
            /* Teleport player to custom spawn point. */
            if (g_iSpawnPointCount > 0 && !g_cvDM_spawn_default.BoolValue)
            {
                Spawns_UpdateSpawnPoints();
                Spawns_MovePlayer(client);
            }
            /* Enable player spawn protection. */
            if (!g_bInEditModeClient[client] && g_cvDM_spawn_protection_time.FloatValue > 0.0)
                Spawns_EnableSpawnProtection(client);
            else if (g_bInEditModeClient[client])
                Spawns_EnableEditorMode(client)
            /* Set health. */
            if (g_cvDM_hp_start.IntValue != 100)
                SetEntityHealth(client, g_cvDM_hp_start.IntValue);
            /* Reset Client */
            Client_ResetClientSettings(client);
            /* Give armor. */
            Client_SetArmor(client);
            /* Strip C4 */
            if (g_cvDM_remove_objectives.BoolValue)
                Client_StripC4(client);
            /* Give weapons or build menu. */
            Client_GiveWeaponsOrBuildMenu(client);
            /* This allows sounds to start being transmitted again (e.g. footsteps). */
            g_bPlayerMoved[client] = true;
        }
    }
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        char weapon[32];
        event.GetString("weapon", weapon, sizeof(weapon));
        int victim = GetClientOfUserId(event.GetInt("userid"));
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        int assister = GetClientOfUserId(event.GetInt("assister"));
        bool knifed = (StrContains(weapon, "knife") != -1 || StrContains(weapon, "bayonet") != -1);
        bool tazed = strcmp(weapon, "taser") == 0;
        bool naded = strcmp(weapon, "hegrenade") == 0;
        bool decoy = strcmp(weapon, "decoy") == 0;
        bool inferno = strcmp(weapon, "inferno") == 0;
        bool tactical = strcmp(weapon, "tagrenade_projectile") == 0;
        bool headshot = event.GetBool("headshot");
        bool changed = false;

        /* Kill feed */
        if (g_cvDM_display_killfeed.BoolValue)
        {
            if (g_cvDM_display_killfeed_player.BoolValue)
            {
                event.BroadcastDisabled = true;

                if (IsValidClient(attacker, false))
                    event.FireToClient(attacker);
                if (IsValidClient(victim, false) && attacker != victim)
                    event.FireToClient(victim);
                if (IsValidClient(assister, false) && victim != assister)
                    event.FireToClient(assister);
            }
            else if (g_cvDM_display_killfeed_player_allow_client.BoolValue)
            {
                event.BroadcastDisabled = true;

                if (IsValidClient(attacker, false))
                    event.FireToClient(attacker);
                if (IsValidClient(victim, false) && attacker != victim)
                    event.FireToClient(victim);
                if (IsValidClient(assister, false) && victim != assister)
                    event.FireToClient(assister);

                for (int i = 1; i <= MaxClients; i++)
                {
                    if (!IsValidClient(i, false) || i == victim || i == attacker || i == assister)
                        continue;
                    if (!g_bKillFeed[i])
                        event.FireToClient(i);
                }
            }
        }
        else
            event.BroadcastDisabled = true;

        /* Check if attacker is alive and well */
        if (IsValidClient(attacker, false) && IsPlayerAlive(attacker))
        {
            /* Stop respawn sounds from playing. */
            StopSound(attacker, SNDCHAN_ITEM, "buttons/bell1.wav");
            RequestFrame(Frame_StopSound, GetClientSerial(attacker));

            /* Reward attacker with HP. */
            int attackerHP = GetClientHealth(attacker);
            int attackerAP = GetClientArmor(attacker);
            /* Reward the attacker with ammo. */
            if (g_cvDM_replenish_ammo_kill.BoolValue)
                RequestFrame(Frame_GiveAmmo, GetClientSerial(attacker));
            if (g_cvDM_replenish_ammo_hs_kill.BoolValue && headshot)
                RequestFrame(Frame_GiveAmmoHS, GetClientSerial(attacker));
            if (g_cvDM_hp_enable.BoolValue || g_cvDM_ap_enable.BoolValue)
            {
                if ((g_cvDM_hp_enable.BoolValue && g_cvDM_ap_enable.BoolValue) && attackerAP < g_cvDM_ap_max.IntValue && attackerHP < g_cvDM_hp_max.IntValue)
                {
                    if ((g_cvDM_hp_messages.BoolValue && g_cvDM_ap_messages.BoolValue))
                    {
                        if (knifed)
                            CPrintToChat(attacker, "%t {green}+%i HP{default} & {green}+%i AP{default} %t", "Chat Tag", g_cvDM_hp_knife.IntValue, g_cvDM_ap_knife.IntValue, "Knife Kill");
                        else if (headshot)
                            CPrintToChat(attacker, "%t {green}+%i HP{default} & {green}+%i AP{default} %t", "Chat Tag", g_cvDM_hp_headshot.IntValue, g_cvDM_ap_headshot.IntValue, "Headshot Kill");
                        else if (naded || decoy || inferno)
                            CPrintToChat(attacker, "%t {green}+%i HP{default} & {green}+%i AP{default} %t", "Chat Tag", g_cvDM_hp_nade.IntValue, g_cvDM_ap_nade.IntValue, "Nade Kill");
                        else
                            CPrintToChat(attacker, "%t {green}+%i HP{default} & {green}+%i AP{default} %t", "Chat Tag", g_cvDM_hp_kill.IntValue, g_cvDM_ap_kill.IntValue, "Kill");
                    }

                    SetEntProp(attacker, Prop_Send, "m_iHealth", AddHealthToPlayer(attackerHP, knifed, headshot, naded, decoy, inferno), 1);
                    SetEntProp(attacker, Prop_Send, "m_ArmorValue", AddArmorToPlayer(attackerAP, knifed, headshot, naded, decoy, inferno), 1);

                    changed = true;
                }
                else if (g_cvDM_hp_enable.BoolValue && !changed && attackerHP < g_cvDM_hp_max.IntValue)
                {
                    if (g_cvDM_hp_messages.BoolValue)
                    {
                        if (knifed)
                            CPrintToChat(attacker, "%t {green}+%i HP{default} %t", "Chat Tag", g_cvDM_hp_knife.IntValue, "Knife Kill");
                        else if (headshot)
                            CPrintToChat(attacker, "%t {green}+%i HP{default} %t", "Chat Tag", g_cvDM_hp_headshot.IntValue, "Headshot Kill");
                        else if (naded || decoy || inferno)
                            CPrintToChat(attacker, "%t {green}+%i HP{default} %t", "Chat Tag", g_cvDM_hp_nade.IntValue, "Nade Kill");
                        else
                            CPrintToChat(attacker, "%t {green}+%i HP{default} %t", "Chat Tag", g_cvDM_hp_kill.IntValue, "Kill");
                    }

                    SetEntProp(attacker, Prop_Send, "m_iHealth", AddHealthToPlayer(attackerHP, knifed, headshot, naded, decoy, inferno), 1);

                    changed = true;
                }
                else if (g_cvDM_ap_enable.BoolValue && !changed && attackerAP < g_cvDM_ap_max.IntValue)
                {
                    if (g_cvDM_ap_messages.BoolValue)
                    {
                        if (knifed)
                            CPrintToChat(attacker, "%t {green}+%i AP{default} %t", "Chat Tag", g_cvDM_ap_knife.IntValue, "Knife Kill");
                        else if (headshot)
                            CPrintToChat(attacker, "%t {green}+%i AP{default} %t", "Chat Tag", g_cvDM_ap_headshot.IntValue, "Headshot Kill");
                        else if (naded || decoy || inferno)
                            CPrintToChat(attacker, "%t {green}+%i AP{default} %t", "Chat Tag", g_cvDM_ap_nade.IntValue, "Nade Kill");
                        else
                            CPrintToChat(attacker, "%t {green}+%i AP{default} %t", "Chat Tag", g_cvDM_ap_kill.IntValue, "Kill");
                    }

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

            /* We rang the bell, let's not be annoying... */
            bool rung = false;

            /* Display the damage text done to players. */
            if (g_cvDM_display_damage_text.BoolValue || (g_cvDM_display_damage_text_allow_client.BoolValue && g_bDamageText[attacker]))
                CPrintToChat(attacker, "{default}[{darkred}KILL{default}] %t {red}%i{default} %t {purple}%N{default} %t.", "Display Damage Giver", g_iDamageDone[attacker][victim], "Display Damage Taker", victim, "Display Damage Hits", g_iDamageDoneHits[attacker][victim]);

            if (g_cvDM_sounds_bell_kill.BoolValue || (g_cvDM_sounds_bell_kill_allow_client.BoolValue && g_bBellKill[attacker]))
            {
                ClientCommand(attacker, "playgamesound training/bell_normal.wav");
                rung = true;
            }
            else if (!rung && headshot)
            {
                /* Yeah Todd, this is Liquid ring-a-ding-dinging. */
                if (g_cvDM_sounds_bell_headshot.BoolValue || (g_cvDM_sounds_bell_headshot_allow_client.BoolValue && g_bBellHeadshot[attacker]))
                    ClientCommand(attacker, "playgamesound training/bell_normal.wav");
            }
        }

        if (IsValidClient(victim, false) && victim != attacker)
        {
            /* Display the damage text done to players. */
            if (g_cvDM_display_damage_text.BoolValue || (g_cvDM_display_damage_text_allow_client.BoolValue && g_bDamageText[victim]))
            {
                int health = 0;
                if (IsValidClient(attacker, true))
                    health = GetClientHealth(attacker);
                if (g_iDamageDoneHits[victim][attacker] > 0)
                    CPrintToChat(victim, "{default}[{darkred}DEATH{default}] %t {red}%i{default} %t {purple}%N{default} %t. %t {green}%i{default}.", "Display Damage Giver", g_iDamageDone[victim][attacker], "Display Damage Taker", attacker, "Display Damage Hits", g_iDamageDoneHits[victim][attacker], "Display Health Remaining", health);
                else
                    CPrintToChat(victim, "{default}[{darkred}DEATH{default}] %t {purple}%N{default}.", "Display Damage None", attacker);
            }
        }

        /* Reset all damage and hits so stats do not overlap. */
        g_iDamageDone[attacker][victim] = 0;
        g_iDamageDoneHits[attacker][victim] = 0;
        g_iDamageDone[victim][attacker] = 0;
        g_iDamageDoneHits[victim][attacker] = 0;

        /* Remove and respawn victim. */
        Spawns_UpdateSpawnPoints();

        if (g_cvDM_respawn.BoolValue)
            CreateTimer(g_cvDM_respawn_time.FloatValue, Timer_Respawn, GetClientSerial(victim));
        if (g_cvDM_remove_ragdoll.BoolValue)
            CreateTimer(g_cvDM_remove_ragdoll_time.FloatValue, Timer_Ragdoll, GetClientSerial(victim));
    }
    return Plugin_Continue;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        int victim = GetClientOfUserId(event.GetInt("userid"));
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        int vhealth = GetClientHealth(victim);
        int dhealth = event.GetInt("dmg_health");
        int darmor = event.GetInt("dmg_armor");
        int health = event.GetInt("health");
        int armor = event.GetInt("armor");

        if (attacker && attacker != victim && victim != 0 && !IsFakeClient(attacker))
        {
            /* Tap the bell on a successful hit. */
            if (g_cvDM_sounds_bell_hit.BoolValue || (g_cvDM_sounds_bell_hit_allow_client.BoolValue && g_bBellHit[attacker]))
                ClientCommand(attacker, "playgamesound training/bell_normal.wav");

            if (g_cvDM_display_damage_text.BoolValue || (g_cvDM_display_damage_text_allow_client.BoolValue && g_bDamageText[attacker]))
            {
                if (health == 0)
                    dhealth += vhealth;

                g_iDamageDone[attacker][victim] += dhealth;
                g_iDamageDoneHits[attacker][victim]++;
            }

            if (g_cvDM_display_damage_popup.BoolValue || (g_cvDM_display_damage_popup_allow_client.BoolValue && g_bDamagePopup[attacker]))
            {
                int textsize;
                char sColor[16];
                char sSize[4];
                char sMsg[8];
                float position[3];
                float clientEye[3];
                float clientAngles[3];
                int entity = CreateEntityByName("point_worldtext");
                GetClientEyePosition(attacker, clientEye);
                GetClientEyeAngles(attacker, clientAngles);
                TR_TraceRayFilter(clientEye, clientAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterHitSelf, attacker);
                if (TR_DidHit(INVALID_HANDLE)) TR_GetEndPosition(position);

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

            if (g_cvDM_display_damage_text.BoolValue || (g_cvDM_display_damage_text_allow_client.BoolValue && g_bDamageText[attacker]))
            {
                if (health > 0)
                    CPrintToChat(attacker, "%t %t {red}%i{default} %t {purple}%N{default}. %t {green}%i{default}.", "Chat Tag", "Display Damage Giver", dhealth, "Display Damage Taker", victim, "Display Health Remaining", health);
                else if (health <= 0)
                    CPrintToChat(attacker, "%t %t {red}%i{default} %t {purple}%N{default}. %t {green}%i{default}. %t", "Chat Tag", "Display Damage Giver", dhealth, "Display Damage Taker", victim, "Display Health Remaining", health, "Display Kill Confirmed");
            }
        }

        if (g_cvDM_headshot_only.BoolValue || (g_cvDM_headshot_only_allow_client.BoolValue && g_bHSOnlyClient[attacker]))
        {
            char weapon[32];
            event.GetString("weapon", weapon, sizeof(weapon));

            if (!g_cvDM_headshot_only_allow_nade.BoolValue)
            {
                if (strcmp(weapon, "hegrenade", false) == 0)
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
                if (strcmp(weapon, "taser", false) == 0)
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
                if (strcmp(weapon, "knife", false) == 0)
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

/* Event check for bomb_drop, if enabled will remove bomb. */
public void Event_BombDropped(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_remove_objectives.BoolValue)
    {
        char entityName[24];
        int entity = GetClientOfUserId(event.GetInt("entindex"));
        GetEntityClassname(entity, entityName, sizeof(entityName));
        if (strcmp(entityName, "weapon_c4") == 0)
            RemoveEntity(entity);
    }
}

/* Event check for bomb_pickup, if enabled will remove bomb. */
public void Event_BombPickup(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_remove_objectives.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        Client_StripC4(client);
    }
}

/* Event check for weapon_fire, if enabled will look for weapon_taser.
* This is the best method to check for the use of the taser.
* If the result is true we can make sure to give a new one if requested. */
public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue)
    {
        char weapon[64];
        int client = GetClientOfUserId(event.GetInt("userid"));
        event.GetString("weapon", weapon, sizeof(weapon));
        if (strcmp(weapon, "weapon_taser") == 0)
            g_bPlayerHasZeus[client] = false;
    }
}

/* Event check for weapon_fire_on_empty,
* if enabled we issue a reload if that method is enabled. */
public Action Event_WeaponFireOnEmpty(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_ammo_empty.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        RequestFrame(Frame_GiveAmmo, GetClientSerial(client));
    }
}

/*  Event check for hegrenade_detonate,
* if enabled we issue a reload if that method is enabled. */
public Action Event_HegrenadeDetonate(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (IsValidClient(client, false) && IsPlayerAlive(client))
            GivePlayerItem(client, "weapon_hegrenade");
    }

    return Plugin_Continue;
}

/*  Event check for smokegrenade_detonate,
* if enabled we issue a reload if that method is enabled. */
public Action Event_SmokegrenadeDetonate(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (IsValidClient(client, false) && IsPlayerAlive(client))
            GivePlayerItem(client, "weapon_smokegrenade");
    }

    return Plugin_Continue;
}

/*  Event check for tagrenade_detonate,
* if enabled we issue a reload if that method is enabled. */
public Action Event_TagrenadeDetonate(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (IsValidClient(client, false) && IsPlayerAlive(client))
            GivePlayerItem(client, "weapon_tagrenade");
    }

    return Plugin_Continue;
}

/*  Event check for flashbang_detonate,
* if enabled we issue a reload if that method is enabled. */
public Action Event_FlashbangDetonate(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (IsValidClient(client, false) && IsPlayerAlive(client))
            GivePlayerItem(client, "weapon_flashbang");
    }

    return Plugin_Continue;
}

/*  Event check for decoy_started,
* if enabled we issue a reload if that method is enabled. */
public Action Event_DecoyStarted(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (IsValidClient(client, false) && IsPlayerAlive(client))
            GivePlayerItem(client, "weapon_decoy");
    }

    return Plugin_Continue;
}

/*  Event check for molotov_detonate,
* if enabled we issue a reload if that method is enabled. */
public Action Event_MolotovDetonate(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (IsValidClient(client, false) && IsPlayerAlive(client))
            GivePlayerItem(client, "weapon_molotov");
    }

    return Plugin_Continue;
}

/*  Event check for inferno_startburn,
* if enabled we issue a reload if that method is enabled. */
public Action Event_InfernoStartburn(Event event, const char[] name, bool dontBroadcast)
{
    if (g_cvDM_enabled.BoolValue && g_cvDM_replenish_grenade.BoolValue)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        if (IsValidClient(client, false) && IsPlayerAlive(client))
            GivePlayerItem(client, "weapon_incgrenade");
    }

    return Plugin_Continue;
}

/* Event check for sound, this is important to block unnecessary
* or blocked sounds. This can also supposedly improve FPS... */
public Action Event_NormalSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &client, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
    if (g_cvDM_enabled.BoolValue)
    {
        bool validClient = false;
        if (IsValidClient(client, true))
            validClient = true;
        /* Block all sounds originating from players not yet moved. */
        if (validClient && !g_bPlayerMoved[client])
            return Plugin_Changed;

        /* Block ammo pickup sounds. */
        if (StrContains(sample, "pickup") != -1)
            return Plugin_Stop;

        if (StrContains(sample, "null") != -1)
            return Plugin_Stop;

        if (StrContains(sample, "respawn") != -1)
            return Plugin_Stop;

        if (g_cvDM_free_for_all.BoolValue)
        {
            if (StrContains(sample, "friendlyfire") != -1)
                return Plugin_Changed;
        }

        if (g_cvDM_sounds_deaths.BoolValue)
        {
            if (StrContains(sample, "death") != -1)
                return Plugin_Changed;
        }
        else if (validClient)
        {
            if ((g_cvDM_sounds_deaths_allow_client && g_bSoundDeaths[client]) && StrContains(sample, "death") != -1)
                return Plugin_Changed;
        }

        if (g_cvDM_sounds_bodyshots.BoolValue)
        {
            if (StrContains(sample, "physics/body") != -1 || StrContains(sample, "flesh") != -1 || StrContains(sample, "kevlar") != -1)
                return Plugin_Changed;
        }
        else if (validClient)
        {
            if ((g_cvDM_sounds_bodyshots_allow_client && g_bSoundBodyShots[client]) && StrContains(sample, "physics/body") != -1 || StrContains(sample, "flesh") != -1 || StrContains(sample, "kevlar") != -1)
                return Plugin_Changed;
        }

        if (g_cvDM_sounds_headshots.BoolValue)
        {
            if (StrContains(sample, "flesh_bloody") != -1 || StrContains(sample, "bhit_helmet") != -1 || StrContains(sample, "headshot") != -1)
                return Plugin_Changed;
        }
        else if (validClient)
        {
            if ((g_cvDM_sounds_headshots_allow_client && g_bSoundHSShots[client]) && StrContains(sample, "flesh_bloody") != -1 || StrContains(sample, "bhit_helmet") != -1 || StrContains(sample, "headshot") != -1)
                return Plugin_Changed;
        }
    }
    return Plugin_Continue;
}

/* Event check for sound, this is important to block unnecessary
* or blocked sounds. This can also supposedly improve FPS... */
public Action Event_AmbientSound(char sample[PLATFORM_MAX_PATH], int& client, float& volume, int& level, int& pitch, float pos[3], int& flags, float& delay)
{
    if (g_cvDM_enabled.BoolValue)
    {
        bool validClient = false;
        if (IsValidClient(client, true))
            validClient = true;
        /* Block all sounds originating from players not yet moved. */
        if (validClient && !g_bPlayerMoved[client])
            return Plugin_Changed;

        /* Block ammo pickup sounds. */
        if (StrContains(sample, "pickup") != -1)
            return Plugin_Stop;

        if (StrContains(sample, "null") != -1)
            return Plugin_Stop;

        if (StrContains(sample, "respawn") != -1)
            return Plugin_Stop;

        if (g_cvDM_free_for_all.BoolValue)
        {
            if (StrContains(sample, "friendlyfire") != -1)
                return Plugin_Changed;
        }

        if (g_cvDM_sounds_deaths.BoolValue)
        {
            if (StrContains(sample, "death") != -1)
                return Plugin_Changed;
        }
        else if (validClient)
        {
            if ((g_cvDM_sounds_deaths_allow_client && g_bSoundDeaths[client]) && StrContains(sample, "death") != -1)
                return Plugin_Changed;
        }

        if (g_cvDM_sounds_bodyshots.BoolValue)
        {
            if (StrContains(sample, "physics/body") != -1 || StrContains(sample, "flesh") != -1 || StrContains(sample, "kevlar") != -1)
                return Plugin_Changed;
        }
        else if (validClient)
        {
            if ((g_cvDM_sounds_bodyshots_allow_client && g_bSoundBodyShots[client]) && StrContains(sample, "physics/body") != -1 || StrContains(sample, "flesh") != -1 || StrContains(sample, "kevlar") != -1)
                return Plugin_Changed;
        }

        if (g_cvDM_sounds_headshots.BoolValue)
        {
            if (StrContains(sample, "flesh_bloody") != -1 || StrContains(sample, "bhit_helmet") != -1 || StrContains(sample, "headshot") != -1)
                return Plugin_Changed;
        }
        else if (validClient)
        {
            if ((g_cvDM_sounds_headshots_allow_client && g_bSoundHSShots[client]) && StrContains(sample, "flesh_bloody") != -1 || StrContains(sample, "bhit_helmet") != -1 || StrContains(sample, "headshot") != -1)
                return Plugin_Changed;
        }
    }
    return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (g_cvDM_remove_chickens.BoolValue)
        if (strcmp(classname, "chicken") == 0)
            RemoveEntity(entity);
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
            "Player_Cash_Award_Bomb_Defused",
            "Player_Cash_Award_Bomb_Planted",
            "Player_Cash_Award_Damage_Hostage",
            "Player_Cash_Award_ExplainSuicide_EnemyGotCash",
            "Player_Cash_Award_ExplainSuicide_Spectators",
            "Player_Cash_Award_ExplainSuicide_TeammateGotCash",
            "Player_Cash_Award_ExplainSuicide_YouGotCash",
            "Player_Cash_Award_Get_Killed",
            "Player_Cash_Award_Interact_Hostage",
            "Player_Cash_Award_Kill_Hostage",
            "Player_Cash_Award_Kill_Teammate",
            "Player_Cash_Award_Killed_Enemy",
            "Player_Cash_Award_Killed_Enemy_Generic",
            "Player_Cash_Award_Killed_VIP",
            "Player_Cash_Award_Rescued_Hostage",
            "Player_Cash_Award_Respawn",
            "Team_Cash_Award_Bonus_Shorthanded",
            "Team_Cash_Award_CT_VIP_Escaped",
            "Team_Cash_Award_Custom",
            "Team_Cash_Award_Elim_Bomb",
            "Team_Cash_Award_Elim_Hostage",
            "Team_Cash_Award_Generic",
            "Team_Cash_Award_Hostage_Alive",
            "Team_Cash_Award_Hostage_Interaction",
            "Team_Cash_Award_Loser_Bonus",
            "Team_Cash_Award_Loser_Bonus_Neg",
            "Team_Cash_Award_Loser_Zero",
            "Team_Cash_Award_no_income",
            "Team_Cash_Award_no_income_suicide",
            "Team_Cash_Award_Planted_Bomb_But_Defused",
            "Team_Cash_Award_Rescued_Hostage",
            "Team_Cash_Award_Survive_GuardianMode_Wave",
            "Team_Cash_Award_T_VIP_Killed",
            "Team_Cash_Award_T_Win_Bomb",
            "Team_Cash_Award_Win_Defuse_Bomb",
            "Team_Cash_Award_Win_Hostage_Rescue",
            "Team_Cash_Award_Win_Hostages_Rescue",
            "Team_Cash_Award_Win_Time"
        };
        for (int i = 0; i < sizeof(cashTriggers); i++)
        {
            if (strcmp(text, cashTriggers[i]) == 0)
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
            if (strcmp(text, grenadeTriggers[i]) == 0)
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
        else if (g_cvDM_headshot_only_allow_nade.BoolValue && (strcmp(grenade, "hegrenade_projectile") == 0 || strcmp(grenade, "decoy_projectile") == 0 || strcmp(grenade, "molotov_projectile") == 0 || strcmp(grenade, "tagrenade_projectile") == 0))
            return Plugin_Continue;
        else if (g_cvDM_headshot_only_allow_taser.BoolValue && strcmp(weapon, "weapon_taser") == 0)
            return Plugin_Continue;
        else
            return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!g_cvDM_enabled.BoolValue || !IsValidClient(attacker, true))
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

            GetEdictClassname(inflictor, grenade, sizeof(grenade));
            GetClientWeapon(attacker, weapon, sizeof(weapon));

            if (damagetype & DMG_HEADSHOT)
                return Plugin_Continue;
            else
            {
                if (g_cvDM_headshot_only_allow_knife.BoolValue && (StrContains(weapon, "knife") != -1 || StrContains(weapon, "bayonet") != -1))
                    return Plugin_Continue;
                else if (g_cvDM_headshot_only_allow_nade.BoolValue && (strcmp(grenade, "hegrenade_projectile") == 0 || strcmp(grenade, "decoy_projectile") == 0 || strcmp(grenade, "molotov_projectile") == 0 || strcmp(grenade, "tagrenade_projectile") == 0))
                    return Plugin_Continue;
                else if (g_cvDM_headshot_only_allow_taser.BoolValue && strcmp(weapon, "weapon_taser") == 0)
                    return Plugin_Continue;
                else
                    return Plugin_Handled;
            }
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
    if (strcmp(weaponName, "weapon_healthshot") == 0 && !g_cvDM_healthshot.BoolValue)
    {
        RemovePlayerItem(client, weapon);
        RemoveEntity(weapon);
        ClientCommand(client, "lastinv");
        return Plugin_Continue
    }
    if (strcmp(weaponName, "weapon_taser") == 0 && !g_cvDM_zeus.BoolValue)
    {
        RemovePlayerItem(client, weapon);
        RemoveEntity(weapon);
        ClientCommand(client, "lastinv");
        return Plugin_Continue
    }
    if (strcmp(weaponName, "weapon_c4") == 0 && g_cvDM_remove_objectives.BoolValue)
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
    if (strcmp(weaponName, "weapon_healthshot") == 0 && !g_cvDM_healthshot.BoolValue)
        removeWeapon = true;
    else if (strcmp(weaponName, "weapon_taser") == 0 && !g_cvDM_zeus.BoolValue)
        removeWeapon = true;
    else if (strcmp(weaponName, "weapon_c4") == 0 && g_cvDM_remove_objectives.BoolValue)
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

public Action TE_EffectDispatch(const char[] te_name, const Players[], int numClients, float delay)
{
    if (!g_cvDM_remove_blood_player.BoolValue)
        return Plugin_Continue;

    int iEffectIndex = TE_ReadNum("m_iEffectName");
    int nHitBox = TE_ReadNum("m_nHitBox");
    char sEffectName[64];

    GetEffectName(iEffectIndex, sEffectName, sizeof(sEffectName));

    if (strcmp(sEffectName, "csblood") == 0 || strcmp(sEffectName, "Impact") == 0)
        return Plugin_Handled;

    if (strcmp(sEffectName, "ParticleEffect") == 0)
    {
        char sParticleEffectName[64];
        GetParticleEffectName(nHitBox, sParticleEffectName, sizeof(sParticleEffectName));
        if (strcmp(sParticleEffectName, "impact_helmet_headshot") == 0)
            return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action TE_WorldDecal(const char[] te_name, const Players[], int numClients, float delay)
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

/* This code was taken from csgo-multi-1v1 by splewis.
If this does not work as it should... Well, you know who
to bla(me)! - https://github.com/splewis/csgo-multi-1v1 */
public Action TE_ShotgunShot(const char[] te_name, const int[] players, int numClients, float delay)
{
    if (!g_cvDM_sounds_gunshots.BoolValue)
        return Plugin_Continue;

    int shooterIndex = TE_ReadNum("m_iPlayer") + 1;

    int[] newClients = new int[MaxClients];
    int newTotal = 0;

    for (int i = 0; i < numClients; i++)
    {
        int client = players[i];
        bool rebroadcast = true;

        if (!IsValidClient(client, true))
            rebroadcast = true;
        else
            rebroadcast = CanHear(shooterIndex, client);

        if (rebroadcast)
        {
            // This Client should be able to hear it.
            newClients[newTotal] = client;
            newTotal++;
        }
    }

    // No clients were excluded.
    if (newTotal == numClients)
        return Plugin_Continue;

    // All clients were excluded and there is no need to broadcast.
    if (newTotal == 0)
        return Plugin_Stop;

    // Re-broadcast to clients that still need it.
    float vTemp[3];
    TE_Start("Shotgun Shot");
    TE_ReadVector("m_vecOrigin", vTemp);
    TE_WriteVector("m_vecOrigin", vTemp);
    TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
    TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
    TE_WriteNum("m_weapon", TE_ReadNum("m_weapon"));
    TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
    TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
    TE_WriteNum("m_iPlayer", TE_ReadNum("m_iPlayer"));
    TE_WriteFloat("m_fInaccuracy", TE_ReadFloat("m_fInaccuracy"));
    TE_WriteFloat("m_fSpread", TE_ReadFloat("m_fSpread"));
    TE_Send(newClients, newTotal, delay);

    return Plugin_Stop;
}

public bool CanHear(int shooter, int client)
{
    if (!IsValidClient(shooter, true) || !IsValidClient(client, true) || shooter == client)
        return true;

    if (!g_cvDM_sounds_gunshots_allow_client.BoolValue || !g_bSoundGunShots[client])
        return true;

    char area1[128];
    char area2[128];

    GetEntPropString(shooter, Prop_Send, "m_szLastPlaceName", area1, sizeof(area1));
    GetEntPropString(client, Prop_Send, "m_szLastPlaceName", area2, sizeof(area2));

    // Block the transmisson.
    if (!StrEqual(area1, area2))
    {
        float shooterPos[3];
        float clientPos[3];
        GetClientAbsOrigin(shooter, shooterPos);
        GetClientAbsOrigin(client, clientPos);
        float distance = GetVectorDistance(shooterPos, clientPos);

        if (distance >= g_cvDM_sounds_gunshots_distance.FloatValue)
            return false;
    }

    // Transmit by default.
    return true;
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

stock int AddHealthToPlayer(int attackerHP, bool knifed, bool headshot, bool naded, bool decoy, bool inferno)
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

stock int AddArmorToPlayer(int attackerAP, bool knifed, bool headshot, bool naded, bool decoy, bool inferno)
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