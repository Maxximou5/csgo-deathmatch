<p align="center">
	<a href="https://maxximou5.com/"><img src="https://maxximou5.com/static/img/banners/csgo-deathmatch.png" alt="CS:GO Deathmatch Sourcemod Plugin"></a><br>
    <a href="https://github.com/Maxximou5/csgo-deathmatch/releases"><img src="https://img.shields.io/github/release/Maxximou5/csgo-deathmatch.svg?style=flat-square" alt="Version"></a>
    <a href="https://github.com/Maxximou5/csgo-deathmatch/stargazers"><img src="https://img.shields.io/github/stars/Maxximou5/csgo-deathmatch.svg?style=flat-square" alt="Stars"></a>
    <a href="https://github.com/Maxximou5/csgo-deathmatch/network"><img src="https://img.shields.io/github/forks/Maxximou5/csgo-deathmatch.svg?style=flat-square" alt="Forks"></a>
    <a href="https://raw.githubusercontent.com/Maxximou5/csgo-deathmatch/master/LICENSE"><img src="https://img.shields.io/badge/license-GPLv3-blue.svg?style=flat-square" alt="License"></a>
	<a href="https://github.com/Maxximou5/csgo-deathmatch/issues"><img src="https://img.shields.io/github/issues/Maxximou5/csgo-deathmatch.svg?style=flat-square" alt="Issues"></a>
</p>

#### **[CS:GO] Deathmatch** - Enables deathmatch style gameplay (respawning, gun selection, spawn protection, etc).

### Main Features

- Weapon Menu
- Loadout Style
- Free For All (FFA)
- Multi-Configuration
- Client Preferences
- Workshop Map Support
- Spawn Editor Menu and Statistics
- Display Damage (Text/Panel/Popup)
- Different Game Modes:
	- Headshot Only
	- Primary Weapons Only
	- Secondary Weapons Only
	- Tertiary Weapons Only
	- Random Weapons Only
- Fast Weapon Equip
- Kill Feed Minifer
- No Knife Damage (Guns Only)
- Objective Removal (C4/Hostage)
- Replenish (Ammo/Grenades/Healthshot/Taser)
- Remove (Blood/Chickens/Weapons/Ragdolls/Bullet Holes)
- Hide Radar and Award/Grenade Messages
- Kill Reward (HP/AP/Ammo/Grenades)
- Line of Sight/Distance Spawning
- 3rd Party Knife Plugin Support
- Multi-Language Support
	- English Supported
	- Spanish Supported
	- French Supported
	- Polish Supported
	- Brazilian Supported
	- German Supported
	- Chinese Supported
	- Japanese Supported

### Client Commands

	Open weapons menu:
	- gun, !gun, /gun, guns, !guns, /guns, menu, !menu, /menu, weapon, !weapon, /weapon, weapons, !weapons, /weapons
	Open deathmatch settings menu:
	- settings, !settings, /settings
	Client toggle headshot mode:
	- hs, !hs, /hs, headshot, !headshot, /headshot

### Admin Commands

	Deathmatch:
	dm_load - Loads the configuration file specified (configs/deathmatch/filename.ini).
	dm_load_menu - Opens the Config Loader Menu.
	dm_spawn_menu - Opens the Spawn Editor Menu.
	dm_respawn_all - Respawns all players.
	dm_settings - Opens the Deathmatch Settings Menu.
	dm_spawn_stats - Displays spawn statistics.
	dm_spawn_reset - Resets spawn statistics.
	dm_weapon_stats - Displays weapon statistics.

### ConVars

	Deathmatch:
	dm_config_name - (Default) "Default" - The configuration name that is currently loaded.
	dm_enabled - (Default) "1" - Enable Deathmatch.
	dm_enable_valve_deathmatch - (Default) "0" - Enable compatibility for Valve Deathmatch (game_type 1 & game_mode 2) or Custom (game_type 3 & game_mode 0).
	dm_welcomemsg - (Default) "1" - Display a message saying that your server is running Deathmatch.
	dm_free_for_all - (Default) "0" - Free for all mode.
	dm_hide_radar - (Default) "0" - Hides the radar from players.
	dm_display_killfeed - (Default) "1" - Enable kill feed to be displayed to all players.
	dm_display_killfeed_player - (Default) "0" - Enable to show kill feed to only the attacker and victim.
	dm_display_damage_panel - (Default) "0" - Display a panel showing enemies health and the damage done to a player.
	dm_display_damage_popup - (Default) "0" - Display text above the enemy showing damage done to an enemy.
	dm_display_damage_text - (Default) "0" - Display text in chat showing damage done to an enemy.
	dm_sounds_bodyshots - (Default) "1" - Enable the sounds of bodyshots.
	dm_sounds_headshots - (Default) "1" - Enable the sounds of headshots.
	dm_headshot_only - (Default) "0" - Headshot only mode.
	dm_headshot_only_allow_client - (Default) "1" - Enable players to have their own personal headshot only mode.
	dm_headshot_only_allow_world - (Default) "0" - Enable world damage during headshot only mode.
	dm_headshot_only_allow_knife - (Default) "0" - Enable knife damage during headshot only mode.
	dm_headshot_only_allow_taser - (Default) "0" - Enable taser damage during headshot only mode.
	dm_headshot_only_allow_nade - (Default) "0" - Enable grenade damage during headshot only mode.
	dm_respawn - (Default) "1" - Enable respawning.
	dm_respawn_time - (Default) "1.0" - Respawn time.
	dm_respawn_valve - (Default) "0" - Enable Valve Deathmatch respawning. This disables the plugin respawning method.
	dm_spawn_default - (Default) "0" - Enable default map spawn points. Overrides Valve Deathmatch respawning.
	dm_spawn_los - (Default) "1" - Enable line of sight spawning. If enabled, players will be spawned at a point where they cannot see enemies, and enemies cannot see them.
	dm_spawn_los_attempts - (Default) "64" - Maximum number of attempts to find a suitable line of sight spawn point.
	dm_spawn_distance - (Default) "500000.0" - Minimum distance from enemies at which a player can spawn.
	dm_spawn_distance_attempts - (Default) "64" - Maximum number of attempts to find a suitable distance spawn point.
	dm_spawn_protection_time - (Default) "1.0" - Spawn protection time.
	dm_remove_blood_player - (Default) "1" - Remove blood splatter from player.
	dm_remove_blood_walls - (Default) "1" - Remove blood splatter from walls.
	dm_remove_cash - (Default) "1" - Remove client cash.
	dm_remove_chickens - (Default) "1" - Remove chickens from the map and from spawning.
	dm_remove_buyzones - (Default) "1" - Remove buyzones from map.
	dm_remove_objectives - (Default) "1" - Remove objectives (disables bomb sites, and removes c4 and hostages).
	dm_remove_ragdoll - (Default) "1" - Remove ragdoll after a player dies.
	dm_remove_ragdoll_time - (Default) "1.0" - Amount of time before removing ragdoll.
	dm_remove_knife_damage - (Default) "0" - Remove damage from knife attacks.
	dm_remove_spawn_weapons - (Default) "1" - Remove spawned player's weapons.
	dm_remove_ground_weapons - (Default) "1" - Remove ground weapons.
	dm_remove_dropped_weapons - (Default) "1" - Remove dropped weapons.
	dm_replenish_ammo_empty - (Default) "1" - Replenish ammo when weapon is empty.
	dm_replenish_ammo_reload - (Default) "0" - Replenish ammo on reload action.
	dm_replenish_ammo_kill - (Default) "1" - Replenish ammo on kill.
	dm_replenish_ammo_type - (Default) "2" - Replenish type. 1) Clip only. 2) Reserve only. 3) Both.
	dm_replenish_ammo_hs_kill - (Default) "0" - Replenish ammo on headshot kill.
	dm_replenish_ammo_hs_type - (Default) "1" - Replenish type. 1) Clip only. 2) Reserve only. 3) Both.
	dm_replenish_grenade - (Default) "0" - Unlimited player grenades.
	dm_replenish_grenade_kill - (Default) "0" - Give players their grenade back on successful kill.
	dm_nade_messages - (Default) "1" - Disable grenade messages.
	dm_cash_messages - (Default) "1" - Disable cash award messages.
	dm_hp_start - (Default) "100" - Spawn Health Points (HP).
	dm_hp_max - (Default) "100" - Maximum Health Points (HP).
	dm_hp_kill - (Default) "5" - Health Points (HP) per kill.
	dm_hp_headshot - (Default) "10" - Health Points (HP) per headshot kill.
	dm_hp_knife - (Default) "50" - Health Points (HP) per knife kill.
	dm_hp_nade - (Default) "30" - Health Points (HP) per nade kill.
	dm_hp_messages - (Default) "1" - Display HP messages.
	dm_ap_max - (Default) "100" - Maximum Armor Points (AP).
	dm_ap_kill - (Default) "5" - Armor Points (AP) per kill.
	dm_ap_headshot - (Default) "10" - Armor Points (AP) per headshot kill.
	dm_ap_knife - (Default) "50" - Armor Points (AP) per knife kill.
	dm_ap_nade - (Default) "30" - Armor Points (AP) per nade kill.
	dm_ap_messages - (Default) "1" - Display AP messages.
	dm_gun_menu_mode - (Default) "1" - Gun menu mode. 0) Disabled. 1) Enabled. 2) Primary weapons only. 3) Secondary weapons only. 4) Tertiary weapons only. 5) Random weapons only.
	dm_loadout_style - (Default) "1" - When players can receive weapons. 1) On respawn. 2) Immediately.
	dm_fast_equip - (Default) "0" - Enable fast weapon equipping.
	dm_healthshot - (Default) "0" - Allow players to use a healthshot.
	dm_healthshot_health - (Default) "50" - Total amount of health given when a healthshot is used.
	dm_healthshot_total - (Default) "4" - Total amount of healthshots a player may have at once.
	dm_healthshot_spawn - (Default) "0" - Give players a healthshot on spawn.
	dm_healthshot_kill - (Default) "0" - Give players a healthshot after any kill.
	dm_healthshot_kill_knife - (Default) "0" - Give players a healthshot after a knife kill.
	dm_zeus - (Default) "0" - Allow players to use a taser.
	dm_zeus_spawn - (Default) "0" - Give players a taser on spawn.
	dm_zeus_kill - (Default) "0" - Give players a taser after any kill.
	dm_zeus_kill_taser - (Default) "0" - Give players a taser after a taser kill.
	dm_zeus_kill_knife - (Default) "0" - Give players a taser after a knife kill.
	dm_nades_incendiary - (Default) "0" - Number of incendiary grenades to give each player.
	dm_nades_molotov - (Default) "0" - Number of molotov grenades to give each player.
	dm_nades_decoy - (Default) "0" - Number of decoy grenades to give each player.
	dm_nades_flashbang - (Default) "0" - Number of flashbang grenades to give each player.
	dm_nades_he - (Default) "0" - Number of HE grenades to give each player.
	dm_nades_smoke - (Default) "0" - Number of smoke grenades to give each player.
	dm_nades_tactical - (Default) "0" - Number of tactical grenades to give each player.
	dm_armor - (Default) "2" - Give players armor. 0) Disable. 1) Chest. 2) Chest + Helmet.

### Compatibility

This plugin is tested on the following Sourcemod & Metamod Versions.

- <a href="https://www.sourcemod.net/downloads.php">Sourcemod 1.10.0+</a>
- <a href="https://www.sourcemm.net/downloads.php">Metamod 1.11.0+</a>

### Requirements

- <a href="https://github.com/c0rp3n/colorlib-sm">ColorLib</a> (necessary only for compiling)

### Instructions

- Extract zip file and place files in the corresponding directories of **/addons/sourcemod**
- /configs/deathmatch/deathmatch.ini
- /configs/deathmatch/deathmatch_*.ini
- /configs/deathmatch/config_loader.ini (necessary only for deathmatch loader)
- /configs/deathmatch/spawns/*.txt
- /plugins/deathmatch.smx
- /scripting/deathmatch.sp (necessary only for compiling)

### Changelog

To view the most recent changelog visit the <a href="https://github.com/Maxximou5/csgo-deathmatch/blob/master/CHANGELOG.md">changelog</a> file.

### Download

Once installed, the plugin will update itself as long as you've done as described in the requirements section; otherwise, downloaded the latest release below.
Please download the latest **deathmatch.zip** file from <a href="https://github.com/Maxximou5/csgo-deathmatch/releases">releases</a>.

### Bugs

If there are any bugs, please report them using the <a href="https://github.com/Maxximou5/csgo-deathmatch/issues">issues page</a>.

### Credit

A thank you to those who helped:

- <a href="https://forums.alliedmods.net/member.php?u=187003">Snip3rUK</a> (<a href="https://forums.alliedmods.net/showthread.php?t=189577">Original Plugin</a>)
- <a href="https://forums.alliedmods.net/member.php?u=26021">Dr!fter</a> (General Code Support)
- <a href="https://steamcommunity.com/id/DoomHammer69/">DoomHammer</a> (Debugging and Testing)
- <a href="https://steamcommunity.com/id/int64shrandy/">int64 Shrandy</a> (Fixing Ammo)
- <a href="https://forums.alliedmods.net/member.php?u=255924">szyma94</a> (Polish Translation)
- <a href="https://forums.alliedmods.net/member.php?u=260574">Rbt</a> (Brazilian Translation)
- <a href="https://forums.alliedmods.net/member.php?u=245683">splewis</a> (Weapon Skins Implementation)
- <a href="https://github.com/Shoxxo">Shoxxo</a> (German Translation)
- <a href="https://steamcommunity.com/profiles/76561198098268870/">MAJOR</a> (Debugging and Testing)
- <a href="http://steamcommunity.com/profiles/76561197975262643">Skyprah</a> (Debugging and Testing)
- <a href="https://forums.alliedmods.net/member.php?u=64286">qiuhaian</a> (Chinese Simplified Translation)
- <a href="https://github.com/k4tyxd">k4tyxd</a> (Japanese Translation)
- <a href="https://github.com/b3none">b3none</a> (Improvements)
- <a href="https://github.com/Drixevel">Drixevel</a> (Improvements)
- <a href="https://github.com/HugoJF/">HugoJF</a> (Improvements)
- <a href="https://steamcommunity.com/id/Dmfrenzy/">UntitledSoldier</a> (Debugging and Testing)

### Donate

If you think I am doing a good job or you want to buy me a beer or feed my cat, please donate.
Thanks!

<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=VSHQ7J8HR95SG"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="csgo deathmatch plugin donate"/></a>

### Donators

People who have shown how much they have enjoyed this plugin:

- <a href="https://steamcommunity.com/id/Dmfrenzy/">UntitledSoldier</a> $80
