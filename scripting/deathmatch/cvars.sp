void LoadCvars()
{
    /* Create Console Variables */
    CreateConVar("dm_m5_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
    g_cvDM_config_name = CreateConVar("dm_config_name", "Default", "The configuration name that is currently loaded.");
    g_cvDM_enabled = CreateConVar("dm_enabled", "1", "Enable Deathmatch.");
    g_cvDM_enable_valve_deathmatch = CreateConVar("dm_enable_valve_deathmatch", "0", "Enable compatibility for Valve Deathmatch (game_type 1 & game_mode 2) or Custom (game_type 3 & game_mode 0).");
    g_cvDM_welcomemsg = CreateConVar("dm_welcomemsg", "1", "Display a message saying that your server is running Deathmatch.");
    g_cvDM_free_for_all = CreateConVar("dm_free_for_all", "0", "Free for all mode.");
    g_cvDM_hide_radar = CreateConVar("dm_hide_radar", "0", "Hides the radar from players.");
    g_cvDM_display_killfeed = CreateConVar("dm_display_killfeed", "1", "Enable kill feed to be displayed to all players.");
    g_cvDM_display_killfeed_player = CreateConVar("dm_display_killfeed_player", "0", "Enable to show kill feed to only the attacker and victim.");
    g_cvDM_display_damage_panel = CreateConVar("dm_display_damage_panel", "0", "Display a panel showing enemies health and the damage done to a player.");
    g_cvDM_display_damage_popup = CreateConVar("dm_display_damage_popup", "0", "Display text above the enemy showing damage done to an enemy.");
    g_cvDM_display_damage_text = CreateConVar("dm_display_damage_text", "0", "Display text in chat showing damage done to an enemy.");
    g_cvDM_sounds_bodyshots = CreateConVar("dm_sounds_bodyshots", "1", "Enable the sounds of bodyshots.");
    g_cvDM_sounds_headshots = CreateConVar("dm_sounds_headshots", "1", "Enable the sounds of headshots.");
    g_cvDM_headshot_only = CreateConVar("dm_headshot_only", "0", "Headshot only mode.");
    g_cvDM_headshot_only_allow_client = CreateConVar("dm_headshot_only_allow_client", "1", "Enable players to have their own personal headshot only mode.");
    g_cvDM_headshot_only_allow_world = CreateConVar("dm_headshot_only_allow_world", "0", "Enable world damage during headshot only mode.");
    g_cvDM_headshot_only_allow_knife = CreateConVar("dm_headshot_only_allow_knife", "0", "Enable knife damage during headshot only mode.");
    g_cvDM_headshot_only_allow_taser = CreateConVar("dm_headshot_only_allow_taser", "0", "Enable taser damage during headshot only mode.");
    g_cvDM_headshot_only_allow_nade = CreateConVar("dm_headshot_only_allow_nade", "0", "Enable grenade damage during headshot only mode.");
    g_cvDM_respawn = CreateConVar("dm_respawn", "1", "Enable respawning.");
    g_cvDM_respawn_time = CreateConVar("dm_respawn_time", "1.0", "Respawn time.");
    g_cvDM_respawn_valve = CreateConVar("dm_respawn_valve", "0", "Enable Valve Deathmatch respawning. This disables the plugin respawning method.");
    g_cvDM_spawn_default = CreateConVar("dm_spawn_default", "0", "Enable default map spawn points. Overrides Valve Deathmatch respawning.");
    g_cvDM_spawn_los = CreateConVar("dm_spawn_los", "1", "Enable line of sight spawning. If enabled, players will be spawned at a point where they cannot see enemies, and enemies cannot see them.");
    g_cvDM_spawn_los_attempts = CreateConVar("dm_spawn_los_attempts", "64", "Maximum number of attempts to find a suitable line of sight spawn point.");
    g_cvDM_spawn_distance = CreateConVar("dm_spawn_distance", "500000.0", "Minimum distance from enemies at which a player can spawn.");
    g_cvDM_spawn_distance_attempts = CreateConVar("dm_spawn_distance_attempts", "64", "Maximum number of attempts to find a suitable distance spawn point.");
    g_cvDM_spawn_protection_time = CreateConVar("dm_spawn_protection_time", "1.0", "Spawn protection time.");
    g_cvDM_remove_blood_player = CreateConVar("dm_remove_blood_player", "1", "Remove blood splatter from player.");
    g_cvDM_remove_blood_walls = CreateConVar("dm_remove_blood_walls", "1", "Remove blood splatter from walls.");
    g_cvDM_remove_cash = CreateConVar("dm_remove_cash", "1", "Remove client cash.");
    g_cvDM_remove_chickens = CreateConVar("dm_remove_chickens", "1", "Remove chickens from the map and from spawning.");
    g_cvDM_remove_buyzones = CreateConVar("dm_remove_buyzones", "1", "Remove buyzones from map.");
    g_cvDM_remove_objectives = CreateConVar("dm_remove_objectives", "1", "Remove objectives (disables bomb sites, and removes c4 and hostages).");
    g_cvDM_remove_ragdoll = CreateConVar("dm_remove_ragdoll", "1", "Remove ragdoll after a player dies.");
    g_cvDM_remove_ragdoll_time = CreateConVar("dm_remove_ragdoll_time", "1.0", "Amount of time before removing ragdoll.");
    g_cvDM_remove_knife_damage = CreateConVar("dm_remove_knife_damage", "0", "Remove damage from knife attacks.");
    g_cvDM_remove_spawn_weapons = CreateConVar("dm_remove_spawn_weapons", "1", "Remove spawned player's weapons.");
    g_cvDM_remove_ground_weapons = CreateConVar("dm_remove_ground_weapons", "1", "Remove ground weapons.");
    g_cvDM_remove_dropped_weapons = CreateConVar("dm_remove_dropped_weapons", "1", "Remove dropped weapons.");
    g_cvDM_replenish_ammo_empty = CreateConVar("dm_replenish_ammo_empty", "1", "Replenish ammo when weapon is empty.");
    g_cvDM_replenish_ammo_reload = CreateConVar("dm_replenish_ammo_reload", "0", "Replenish ammo on reload action.");
    g_cvDM_replenish_ammo_kill = CreateConVar("dm_replenish_ammo_kill", "1", "Replenish ammo on kill.");
    g_cvDM_replenish_ammo_type = CreateConVar("dm_replenish_ammo_type", "2", "Replenish type. 1) Clip only. 2) Reserve only. 3) Both.");
    g_cvDM_replenish_ammo_hs_kill = CreateConVar("dm_replenish_ammo_hs_kill", "0", "Replenish ammo  on headshot kill.");
    g_cvDM_replenish_ammo_hs_type = CreateConVar("dm_replenish_ammo_hs_type", "1", "Replenish type. 1) Clip only. 2) Reserve only. 3) Both.");
    g_cvDM_replenish_grenade = CreateConVar("dm_replenish_grenade", "0", "Unlimited player grenades.");
    g_cvDM_replenish_grenade_kill = CreateConVar("dm_replenish_grenade_kill", "0", "Give players their grenade back on successful kill.");
    g_cvDM_nade_messages = CreateConVar("dm_nade_messages", "1", "Disable grenade messages.");
    g_cvDM_cash_messages = CreateConVar("dm_cash_messages", "1", "Disable cash award messages.");
    g_cvDM_hp_start = CreateConVar("dm_hp_start", "100", "Spawn Health Points (HP).");
    g_cvDM_hp_max = CreateConVar("dm_hp_max", "100", "Maximum Health Points (HP).");
    g_cvDM_hp_kill = CreateConVar("dm_hp_kill", "5", "Health Points (HP) per kill.");
    g_cvDM_hp_headshot = CreateConVar("dm_hp_headshot", "10", "Health Points (HP) per headshot kill.");
    g_cvDM_hp_knife = CreateConVar("dm_hp_knife", "50", "Health Points (HP) per knife kill.");
    g_cvDM_hp_nade = CreateConVar("dm_hp_nade", "30", "Health Points (HP) per nade kill.");
    g_cvDM_hp_messages = CreateConVar("dm_hp_messages", "1", "Display HP messages.");
    g_cvDM_ap_max = CreateConVar("dm_ap_max", "100", "Maximum Armor Points (AP).");
    g_cvDM_ap_kill = CreateConVar("dm_ap_kill", "5", "Armor Points (AP) per kill.");
    g_cvDM_ap_headshot = CreateConVar("dm_ap_headshot", "10", "Armor Points (AP) per headshot kill.");
    g_cvDM_ap_knife = CreateConVar("dm_ap_knife", "50", "Armor Points (AP) per knife kill.");
    g_cvDM_ap_nade = CreateConVar("dm_ap_nade", "30", "Armor Points (AP) per nade kill.");
    g_cvDM_ap_messages = CreateConVar("dm_ap_messages", "1", "Display AP messages.");
    g_cvDM_gun_menu_mode = CreateConVar("dm_gun_menu_mode", "1", "Gun menu mode. 0) Disabled. 1) Enabled. 2) Primary weapons only. 3) Secondary weapons only. 4) Tertiary weapons only. 5) Random weapons only.");
    g_cvDM_loadout_style = CreateConVar("dm_loadout_style", "1", "When players can receive weapons. 1) On respawn. 2) Immediately.");
    g_cvDM_fast_equip = CreateConVar("dm_fast_equip", "0", "Enable fast weapon equipping.");
    g_cvDM_healthshot = CreateConVar("dm_healthshot", "0", "Allow players to use a healthshot.");
    g_cvDM_healthshot_health = CreateConVar("dm_healthshot_health", "50", "Total amount of health given when a healthshot is used.");
    g_cvDM_healthshot_total = CreateConVar("dm_healthshot_total", "4", "Total amount of healthshots a player may have at once.");
    g_cvDM_healthshot_spawn = CreateConVar("dm_healthshot_spawn", "0", "Give players a healthshot on spawn.");
    g_cvDM_healthshot_kill = CreateConVar("dm_healthshot_kill", "0", "Give players a healthshot after any kill.");
    g_cvDM_healthshot_kill_knife = CreateConVar("dm_healthshot_kill_knife", "0", "Give players a healthshot after a knife kill.");
    g_cvDM_zeus = CreateConVar("dm_zeus", "0", "Allow players to use a taser.");
    g_cvDM_zeus_spawn = CreateConVar("dm_zeus_spawn", "0", "Give players a taser on spawn.");
    g_cvDM_zeus_kill = CreateConVar("dm_zeus_kill", "0", "Give players a taser after any kill.");
    g_cvDM_zeus_kill_taser = CreateConVar("dm_zeus_kill_taser", "0", "Give players a taser after a taser kill.");
    g_cvDM_zeus_kill_knife = CreateConVar("dm_zeus_kill_knife", "0", "Give players a taser after a knife kill.");
    g_cvDM_nades_incendiary = CreateConVar("dm_nades_incendiary", "0", "Number of incendiary grenades to give each player.");
    g_cvDM_nades_molotov = CreateConVar("dm_nades_molotov", "0", "Number of molotov grenades to give each player.");
    g_cvDM_nades_decoy = CreateConVar("dm_nades_decoy", "0", "Number of decoy grenades to give each player.");
    g_cvDM_nades_flashbang = CreateConVar("dm_nades_flashbang", "0", "Number of flashbang grenades to give each player.");
    g_cvDM_nades_he = CreateConVar("dm_nades_he", "0", "Number of HE grenades to give each player.");
    g_cvDM_nades_smoke = CreateConVar("dm_nades_smoke", "0", "Number of smoke grenades to give each player.");
    g_cvDM_nades_tactical = CreateConVar("dm_nades_tactical", "0", "Number of tactical grenades to give each player.");
    g_cvDM_armor = CreateConVar("dm_armor", "2", "Give players armor. 0) Disable. 1) Chest. 2) Chest + Helmet.");
}

void LoadChangeHooks()
{
    /* Hook Console Variables */
    g_cvDM_enabled.AddChangeHook(Event_CvarChange);
    g_cvDM_config_name.AddChangeHook(Event_CvarChange);
    g_cvDM_enable_valve_deathmatch.AddChangeHook(Event_CvarChange);
    g_cvDM_welcomemsg.AddChangeHook(Event_CvarChange);
    g_cvDM_free_for_all.AddChangeHook(Event_CvarChange);
    g_cvDM_hide_radar.AddChangeHook(Event_CvarChange);
    g_cvDM_display_killfeed.AddChangeHook(Event_CvarChange);
    g_cvDM_display_killfeed_player.AddChangeHook(Event_CvarChange);
    g_cvDM_display_damage_panel.AddChangeHook(Event_CvarChange);
    g_cvDM_display_damage_popup.AddChangeHook(Event_CvarChange);
    g_cvDM_display_damage_text.AddChangeHook(Event_CvarChange);
    g_cvDM_sounds_bodyshots.AddChangeHook(Event_CvarChange);
    g_cvDM_sounds_headshots.AddChangeHook(Event_CvarChange);
    g_cvDM_headshot_only.AddChangeHook(Event_CvarChange);
    g_cvDM_headshot_only_allow_client.AddChangeHook(Event_CvarChange);
    g_cvDM_headshot_only_allow_world.AddChangeHook(Event_CvarChange);
    g_cvDM_headshot_only_allow_knife.AddChangeHook(Event_CvarChange);
    g_cvDM_headshot_only_allow_taser.AddChangeHook(Event_CvarChange);
    g_cvDM_headshot_only_allow_nade.AddChangeHook(Event_CvarChange);
    g_cvDM_respawn.AddChangeHook(Event_CvarChange);
    g_cvDM_respawn_valve.AddChangeHook(Event_CvarChange);
    g_cvDM_respawn_time.AddChangeHook(Event_CvarChange);
    g_cvDM_spawn_default.AddChangeHook(Event_CvarChange);
    g_cvDM_spawn_los.AddChangeHook(Event_CvarChange);
    g_cvDM_spawn_los_attempts.AddChangeHook(Event_CvarChange);
    g_cvDM_spawn_distance.AddChangeHook(Event_CvarChange);
    g_cvDM_spawn_protection_time.AddChangeHook(Event_CvarChange);
    g_cvDM_remove_knife_damage.AddChangeHook(Event_CvarChange);
    g_cvDM_remove_cash.AddChangeHook(Event_CvarChange);
    g_cvDM_remove_chickens.AddChangeHook(Event_CvarChange);
    g_cvDM_remove_buyzones.AddChangeHook(Event_CvarChange);
    g_cvDM_remove_objectives.AddChangeHook(Event_CvarChange);
    g_cvDM_remove_ragdoll.AddChangeHook(Event_CvarChange);
    g_cvDM_remove_ragdoll_time.AddChangeHook(Event_CvarChange);
    g_cvDM_remove_spawn_weapons.AddChangeHook(Event_CvarChange);
    g_cvDM_remove_ground_weapons.AddChangeHook(Event_CvarChange);
    g_cvDM_remove_dropped_weapons.AddChangeHook(Event_CvarChange);
    g_cvDM_replenish_ammo_empty.AddChangeHook(Event_CvarChange);
    g_cvDM_replenish_ammo_reload.AddChangeHook(Event_CvarChange);
    g_cvDM_replenish_ammo_kill.AddChangeHook(Event_CvarChange);
    g_cvDM_replenish_ammo_type.AddChangeHook(Event_CvarChange);
    g_cvDM_replenish_ammo_hs_kill.AddChangeHook(Event_CvarChange);
    g_cvDM_replenish_ammo_hs_type.AddChangeHook(Event_CvarChange);
    g_cvDM_replenish_grenade.AddChangeHook(Event_CvarChange);
    g_cvDM_replenish_grenade_kill.AddChangeHook(Event_CvarChange);
    g_cvDM_nade_messages.AddChangeHook(Event_CvarChange);
    g_cvDM_cash_messages.AddChangeHook(Event_CvarChange);
    g_cvDM_hp_start.AddChangeHook(Event_CvarChange);
    g_cvDM_hp_max.AddChangeHook(Event_CvarChange);
    g_cvDM_hp_kill.AddChangeHook(Event_CvarChange);
    g_cvDM_hp_headshot.AddChangeHook(Event_CvarChange);
    g_cvDM_hp_knife.AddChangeHook(Event_CvarChange);
    g_cvDM_hp_nade.AddChangeHook(Event_CvarChange);
    g_cvDM_hp_messages.AddChangeHook(Event_CvarChange);
    g_cvDM_ap_max.AddChangeHook(Event_CvarChange);
    g_cvDM_ap_kill.AddChangeHook(Event_CvarChange);
    g_cvDM_ap_headshot.AddChangeHook(Event_CvarChange);
    g_cvDM_ap_knife.AddChangeHook(Event_CvarChange);
    g_cvDM_ap_nade.AddChangeHook(Event_CvarChange);
    g_cvDM_ap_messages.AddChangeHook(Event_CvarChange);
    g_cvDM_gun_menu_mode.AddChangeHook(Event_CvarChange);
    g_cvDM_loadout_style.AddChangeHook(Event_CvarChange);
    g_cvDM_fast_equip.AddChangeHook(Event_CvarChange);
    g_cvDM_healthshot.AddChangeHook(Event_CvarChange);
    g_cvDM_healthshot_health.AddChangeHook(Event_CvarChange);
    g_cvDM_healthshot_spawn.AddChangeHook(Event_CvarChange);
    g_cvDM_healthshot_total.AddChangeHook(Event_CvarChange);
    g_cvDM_healthshot_kill.AddChangeHook(Event_CvarChange);
    g_cvDM_healthshot_kill_knife.AddChangeHook(Event_CvarChange);
    g_cvDM_zeus.AddChangeHook(Event_CvarChange);
    g_cvDM_zeus_spawn.AddChangeHook(Event_CvarChange);
    g_cvDM_zeus_kill.AddChangeHook(Event_CvarChange);
    g_cvDM_zeus_kill_taser.AddChangeHook(Event_CvarChange);
    g_cvDM_zeus_kill_knife.AddChangeHook(Event_CvarChange);
    g_cvDM_nades_incendiary.AddChangeHook(Event_CvarChange);
    g_cvDM_nades_molotov.AddChangeHook(Event_CvarChange);
    g_cvDM_nades_decoy.AddChangeHook(Event_CvarChange);
    g_cvDM_nades_flashbang.AddChangeHook(Event_CvarChange);
    g_cvDM_nades_he.AddChangeHook(Event_CvarChange);
    g_cvDM_nades_smoke.AddChangeHook(Event_CvarChange);
    g_cvDM_nades_tactical.AddChangeHook(Event_CvarChange);
    g_cvDM_armor.AddChangeHook(Event_CvarChange);
}

void RetrieveVariables()
{
    /* Retrieve Native Console Variables */
    g_cvMP_ct_default_primary = FindConVar("mp_ct_default_primary");
    g_cvMP_t_default_primary = FindConVar("mp_t_default_primary");
    g_cvMP_ct_default_secondary = FindConVar("mp_ct_default_secondary");
    g_cvMP_t_default_secondary = FindConVar("mp_t_default_secondary");
    g_cvMP_items_prohibited = FindConVar("mp_items_prohibited");
    g_cvMP_free_armor = FindConVar("mp_free_armor");
    g_cvMP_max_armor = FindConVar("mp_max_armor");
    g_cvMP_randomspawn = FindConVar("mp_randomspawn");
    g_cvMP_randomspawn_dist = FindConVar("mp_randomspawn_dist");
    g_cvMP_randomspawn_los = FindConVar("mp_randomspawn_los");
    g_cvMP_startmoney = FindConVar("mp_startmoney");
    g_cvMP_playercashawards = FindConVar("mp_playercashawards");
    g_cvMP_teamcashawards = FindConVar("mp_teamcashawards");
    g_cvMP_friendlyfire = FindConVar("mp_friendlyfire");
    g_cvMP_autokick = FindConVar("mp_autokick");
    g_cvMP_tkpunish = FindConVar("mp_tkpunish");
    g_cvMP_give_player_c4 = FindConVar("mp_give_player_c4");
    g_cvMP_death_drop_c4 = FindConVar("mp_death_drop_c4");
    g_cvMP_death_drop_defuser = FindConVar("mp_death_drop_defuser");
    g_cvMP_death_drop_grenade = FindConVar("mp_death_drop_grenade");
    g_cvMP_death_drop_gun = FindConVar("mp_death_drop_gun");
    g_cvMP_death_drop_taser = FindConVar("mp_death_drop_taser");
    g_cvMP_teammates_are_enemies = FindConVar("mp_teammates_are_enemies");
    g_cvFF_damage_reduction_bullets = FindConVar("ff_damage_reduction_bullets");
    g_cvFF_damage_reduction_grenade = FindConVar("ff_damage_reduction_grenade");
    g_cvFF_damage_reduction_other = FindConVar("ff_damage_reduction_other");
    g_cvSV_ignoregrenaderadio = FindConVar("sv_ignoregrenaderadio");
    g_cvAmmo_grenade_limit_default = FindConVar("ammo_grenade_limit_default");
    g_cvAmmo_grenade_limit_flashbang = FindConVar("ammo_grenade_limit_flashbang");
    g_cvAmmo_grenade_limit_total = FindConVar("ammo_grenade_limit_total");
    g_cvAmmo_item_limit_healthshot = FindConVar("ammo_item_limit_healthshot");
    g_cvHealthshot_health = FindConVar("healthshot_health");

    /* Retrieve Native Console Variable Values */
    g_cvMP_ct_default_primary.GetString(g_cBackup_mp_ct_default_primary, sizeof(g_cBackup_mp_ct_default_primary));
    g_cvMP_t_default_primary.GetString(g_cBackup_mp_t_default_primary, sizeof(g_cBackup_mp_t_default_primary));
    g_cvMP_ct_default_secondary.GetString(g_cBackup_mp_ct_default_secondary, sizeof(g_cBackup_mp_ct_default_secondary));
    g_cvMP_t_default_secondary.GetString(g_cBackup_mp_t_default_secondary, sizeof(g_cBackup_mp_t_default_secondary));
    g_cvMP_items_prohibited.GetString(g_cBackup_mp_items_prohibited, sizeof(g_cBackup_mp_items_prohibited));
    g_iBackup_free_armor = g_cvMP_free_armor.IntValue;
    g_iBackup_max_armor = g_cvMP_max_armor.IntValue;
    g_iBackup_mp_randomspawn = g_cvMP_randomspawn.IntValue;
    g_iBackup_mp_randomspawn_dist = g_cvMP_randomspawn_dist.IntValue;
    g_iBackup_mp_randomspawn_los = g_cvMP_randomspawn_los.IntValue;
    g_iBackup_mp_startmoney = g_cvMP_startmoney.IntValue;
    g_iBackup_mp_playercashawards = g_cvMP_playercashawards.IntValue;
    g_iBackup_mp_teamcashawards = g_cvMP_teamcashawards.IntValue;
    g_iBackup_mp_friendlyfire = g_cvMP_friendlyfire.IntValue;
    g_iBackup_mp_autokick = g_cvMP_autokick.IntValue;
    g_iBackup_mp_tkpunish = g_cvMP_tkpunish.IntValue;
    g_iBackup_mp_give_player_c4 = g_cvMP_give_player_c4.IntValue;
    g_iBackup_mp_death_drop_c4 = g_cvMP_death_drop_c4.IntValue;
    g_iBackup_mp_death_drop_defuser = g_cvMP_death_drop_defuser.IntValue;
    g_iBackup_mp_death_drop_grenade = g_cvMP_death_drop_grenade.IntValue;
    g_iBackup_mp_death_drop_gun = g_cvMP_death_drop_gun.IntValue;
    g_iBackup_mp_death_drop_taser = g_cvMP_death_drop_taser.IntValue;
    g_iBackup_mp_teammates_are_enemies = g_cvMP_teammates_are_enemies.IntValue;
    g_fBackup_ff_damage_reduction_bullets = g_cvFF_damage_reduction_bullets.FloatValue;
    g_fBackup_ff_damage_reduction_grenade = g_cvFF_damage_reduction_grenade.FloatValue;
    g_fBackup_ff_damage_reduction_other = g_cvFF_damage_reduction_other.FloatValue;
    g_iBackup_sv_ignoregrenaderadio = g_cvSV_ignoregrenaderadio.IntValue;
    g_iBackup_ammo_grenade_limit_default = g_cvAmmo_grenade_limit_default.IntValue;
    g_iBackup_ammo_grenade_limit_flashbang = g_cvAmmo_grenade_limit_flashbang.IntValue;
    g_iBackup_ammo_grenade_limit_total = g_cvAmmo_grenade_limit_total.IntValue;
    g_iBackup_ammo_item_limit_healthshot = g_cvAmmo_item_limit_healthshot.IntValue;
    g_iBackup_healthshot_health = g_cvHealthshot_health.IntValue;
}

void LoadCookies()
{
    /* Baked Cookies */
    g_hWeapon_Primary_Cookie = RegClientCookie("dm_weapon_primary", "Primary Weapon Selection", CookieAccess_Private);
    g_hWeapon_Secondary_Cookie = RegClientCookie("dm_weapon_secondary", "Secondary Weapon Selection", CookieAccess_Private);
    g_hWeapon_Remember_Cookie = RegClientCookie("dm_weapon_remember", "Remember Weapon Selection", CookieAccess_Private);
    g_hWeapon_First_Cookie = RegClientCookie("dm_weapon_first", "First Weapon Selection", CookieAccess_Private);
    g_hDamage_Panel_Cookie = RegClientCookie("dm_damage_panel", "Damage Panel", CookieAccess_Protected);
    g_hDamage_Popup_Cookie = RegClientCookie("dm_damage_popup", "Damage Popup", CookieAccess_Protected);
    g_hDamage_Text_Cookie = RegClientCookie("dm_damage_text", "Damage Text", CookieAccess_Protected);
    g_hKillFeed_Cookie = RegClientCookie("dm_killfeed", "Kill Feed", CookieAccess_Protected);
    g_hHSOnly_Cookie = RegClientCookie("dm_hsonly", "Headshot Only", CookieAccess_Protected);

    SetCookieMenu(g_hDamage_Panel_Cookie, CookieMenu_OnOff_Int, "Deathmatch Damage Panel", Cookiemenu_DisplayCallback);
    SetCookieMenu(g_hDamage_Popup_Cookie, CookieMenu_OnOff_Int, "Deathmatch Damage Popup", Cookiemenu_DisplayCallback);
    SetCookieMenu(g_hDamage_Text_Cookie, CookieMenu_OnOff_Int, "Deathmatch Damage Text", Cookiemenu_DisplayCallback);
    SetCookieMenu(g_hKillFeed_Cookie, CookieMenu_OnOff_Int, "Deathmatch Kill Feed", Cookiemenu_DisplayCallback);
    SetCookieMenu(g_hHSOnly_Cookie, CookieMenu_OnOff_Int, "Deathmatch Headshot Only", Cookiemenu_HSOnlyCallback);

    /* Late Load Cookies */
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i) && !IsFakeClient(i))
            OnClientCookiesCached(i);
    }
}