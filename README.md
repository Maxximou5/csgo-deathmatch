<p align="center">
	<a href="https://maxximous.com/">
		<img src="https://maxximous.com/static/img/logo-big.png" alt="csgo deathmatch plugin">
	</a>
	<br>
	<a href="https://github.com/Maxximou5/csgo-deathmatch/releases">
		<img src="https://img.shields.io/github/release/Maxximou5/csgo-deathmatch.svg?style=flat-square" alt="Version">
	</a>
	<a href="https://github.com/Maxximou5/csgo-deathmatch/stargazers">
		<img src="https://img.shields.io/github/stars/Maxximou5/csgo-deathmatch.svg?style=flat-square" alt="Stars">
	</a>
	<a href="https://github.com/Maxximou5/csgo-deathmatch/network">
		<img src="https://img.shields.io/github/forks/Maxximou5/csgo-deathmatch.svg?style=flat-square" alt="Forks">
	</a>
	<a href="https://github.com/Maxximou5/csgo-deathmatch/releases">
		<img src="https://img.shields.io/github/downloads/Maxximou5/csgo-deathmatch/total.svg?style=flat-square" alt="Downloads">
	</a>
	<a href="https://github.com/Maxximou5/csgo-deathmatch/issues">
		<img src="https://img.shields.io/github/issues/Maxximou5/csgo-deathmatch.svg?style=flat-square" alt="Issues">
	</a>
	<a href="https://travis-ci.org/Maxximou5/csgo-deathmatch">
		<img src="https://img.shields.io/travis/Maxximou5/csgo-deathmatch.svg?style=flat-square" alt="Build Status">
	</a>
</p>

#### [CS:GO] Deathmatch - Enables deathmatch style gameplay (respawning, gun selection, spawn protection, etc)

## Main Features
- Weapon Menu
- Loadout Style
- Free For All ***(FFA)***
- Multi-Configuration
- Client Preferences
- Workshop Map Support
- Spawn Editor Menu and Statistics
- Display Damage ***(Text/Panel/Popup)***
- Different Game Modes:
	- Headshot Only
	- Primary Weapons Only
	- Secondary Weapons Only
	- Tertiary Weapons Only
	- Random Weapons Only
- Fast Weapon Equip
- Kill Feed Minifer
- No Knife Damage ***(Guns Only)***
- Objective Removal ***(C4/Hostage)***
- Replenish ***(Ammo/Grenades/Healthshot/Taser)***
- Remove ***(Blood/Chickens/Weapons/Ragdolls/Bullet Holes)***
- Hide Radar and Award/Grenade Messages
- Kill Reward ***(HP/AP/Ammo/Grenades)***
- Line of Sight/Distance Spawning
- 3rd Party Knife Plugin Support
- Multi-Language Support
	- English Supported **()**
	- Spanish Supported **()**
	- French Supported **()**
	- Polish Supported **(<a href="https://forums.alliedmods.net/member.php?u=255924">szyma94</a>)**
	- Brazilian Supported **(<a href="https://forums.alliedmods.net/member.php?u=260574">Rbt</a> & [crashzk](https://github.com/crashzk))**
	- German Supported **(<a href="https://github.com/Shoxxo">Shoxxo</a>)**
	- Chinese Simplified Supported **(<a href="https://forums.alliedmods.net/member.php?u=64286">qiuhaian</a>)**
	- Japanese Supported **(<a href="https://github.com/k4tyxd">k4tyxd</a>)**
	
## Client Commands
**CVARS** | **Description** | **Commands** |
:--------: | -------- |  :--------: |
**sm_guns** | Open Weapons Menu | gun, !gun, /gun, guns, !guns, /guns, menu, !menu, /menu, weapon, !weapon, /weapon, weapons, !weapons, /weapons |
**sm_settings** | Open Deathmatch Settings Menu | settings, !settings, /settings |
**sm_headshot** | Client Toggle Headshot Mode |  hs, !hs, /hs, headshot, !headshot, /headshot | 

## Admin Commands
**Deathmatch:**
- **`dm_load`** - Loads the configuration file specified **`(configs/deathmatch/filename.ini)`**.
- **`dm_load_menu`** - Opens the Config Loader Menu.
- **`dm_spawn_menu`** - Opens the Spawn Editor Menu.
- **`dm_respawn_all`** - Respawns all players.
- **`dm_settings`** - Opens the Deathmatch Settings Menu.
- **`dm_stats`** - Displays spawn statistics.
- **`dm_stats_reset `** - Resets spawn statistics.

**Deathmatch Loader:**
- **`dm_reload`** - Reloads the loader configuration file.

## ConVars
**Deathmatch:**
- **`dm_config_name "Default"`** - The configuration name that is currently loaded.
- **`dm_enabled "1"`** - Enable Deathmatch.
- **`dm_enable_valve_deathmatch "0"`** - Enable compatibility for Valve Deathmatch **(game_type 1 & game_mode 2)** or **Custom (game_type 3 & game_mode 0)**.
- **`dm_welcomemsg "1"`**- Display a message saying that your server is running Deathmatch.
- **`dm_free_for_all "0"`** - Free for all mode.
- **`dm_hide_radar "0"`** - Hides the radar from players.
- **`dm_display_killfeed "1"`** - Enable kill feed to be displayed to all players.
- **`dm_display_killfeed_player "0"`** - Enable to show kill feed to only the attacker and victim.
- **`dm_display_damage_panel "0"`** - Display a panel showing enemies health and the damage done to a player.
- **`dm_display_damage_popup "0"`** - Display text above the enemy showing damage done to an enemy.
- **`dm_display_damage_text "0"`** - Display text in chat showing damage done to an enemy.
- **`dm_sounds_bodyshots "1"`** - Enable the sounds of bodyshots.
- **`dm_sounds_headshots "1"`** - Enable the sounds of headshots.
- **`dm_headshot_only "0"`** - Headshot only mode.
- **`dm_headshot_only_allow_client "1"`** - Enable players to have their own personal headshot only mode.
- **`dm_headshot_only_allow_world "0"`** - Enable world damage during headshot only mode.
- **`dm_headshot_only_allow_knife "0"`** - Enable knife damage during headshot only mode.
- **`dm_headshot_only_allow_taser "0"`** - Enable taser damage during headshot only mode.
- **`dm_headshot_only_allow_nade "0"`** - Enable grenade damage during headshot only mode.
- **`dm_respawn "1"`** - Enable respawning.
- **`dm_respawn_time "1.0"`** - Respawn time.
- **`dm_respawn_valve "0"`** - Enable Valve Deathmatch respawning. This disables the plugin respawning method.
- **`dm_spawn_default "0"`** - Enable default map spawn points. Overrides Valve Deathmatch respawning.
- **`dm_spawn_los "1"`** - Enable line of sight spawning. If enabled, players will be spawned at a point where they cannot see enemies, and enemies cannot see them.
- **`dm_spawn_los_attempts "64"`** - Maximum number of attempts to find a suitable line of sight spawn point.
- **`dm_spawn_distance "500000.0"`** - Minimum distance from enemies at which a player can spawn.
- **`dm_spawn_distance_attempts "64"`** - Maximum number of attempts to find a suitable distance spawn point.
- **`dm_spawn_protection_time "1.0"`** - Spawn protection time.
- **`dm_remove_blood_player "1"`** - Remove blood splatter from player.
- **`dm_remove_blood_walls "1"`** - Remove blood splatter from walls.
- **`dm_remove_cash "1"`** - Remove client cash.
- **`dm_remove_chickens "1"`** - Remove chickens from the map and from spawning.
- **`dm_remove_buyzones "1"`** - Remove buyzones from map.
- **`dm_remove_objectives "1"`** - Remove objectives **(Disables bomb sites, and removes c4 and hostages)**.
- **`dm_remove_ragdoll "1"`** - Remove ragdoll after a player dies.
- **`dm_remove_ragdoll_time "1.0"`** - Amount of time before removing ragdoll.
- **`dm_remove_knife_damage "0"`** - Remove damage from knife attacks.
- **`dm_remove_spawn_weapons "1"`** - Remove spawned player's weapons.
- **`dm_remove_ground_weapons "1"`** - Remove ground weapons.
- **`dm_remove_dropped_weapons "1"`** - Remove dropped weapons.
- **`dm_replenish_ammo_empty "1"`** - Replenish ammo when weapon is empty.
- **`dm_replenish_ammo_reload "0"`** - Replenish ammo on reload action.
- **`dm_replenish_ammo_kill "1"`** - Replenish ammo on kill.
- **`dm_replenish_ammo_type "2"`** - Replenish type. 1 = Clip only. 2 = Reserve only. 3 = Both.
- **`dm_replenish_ammo_hs_kill "0"`** - Replenish ammo  on headshot kill.
- **`dm_replenish_ammo_hs_type "1"`** - Replenish type. 1 = Clip only. 2 = Reserve only. 3 = Both.
- **`dm_replenish_grenade "0"`** - Unlimited player grenades.
- **`dm_replenish_grenade_kill "0"`** - Give players their grenade back on successful kill.
- **`dm_nade_messages "1"`** - Disable grenade messages.
- **`dm_cash_messages "1"`** - Disable cash award messages.
- **`dm_hp_start "100"`** - Spawn Health Points (HP).
- **`dm_hp_max "100"`** - Maximum Health Points (HP).
- **`dm_hp_kill "5"`** - Health Points (HP) per kill.
- **`dm_hp_headshot "10"`** - Health Points (HP) per headshot kill.
- **`dm_hp_knife "50"`** - Health Points (HP) per knife kill.
- **`dm_hp_nade "30"`** - Health Points (HP) per nade kill.
- **`dm_hp_messages "1"`** - Display HP messages.
- **`dm_ap_max "100"`** - Maximum Armor Points (AP).
- **`dm_ap_kill "5"`** - Armor Points (AP) per kill.
- **`dm_ap_headshot "10"`** - Armor Points (AP) per headshot kill.
- **`dm_ap_knife "50"`** - Armor Points (AP) per knife kill.
- **`dm_ap_nade "30"`** - Armor Points (AP) per nade kill.
- **`dm_ap_messages "1"`** - Display AP messages.
- **`dm_gun_menu_mode "1"`** - Gun menu mode. 0 = Disabled. 1 = Enabled. 2 = Primary weapons only. 3 = Secondary weapons only. 4 = Tertiary weapons only. 5 = Random weapons only.
- **`dm_loadout_style "1"`** - When players can receive weapons. 1 = On respawn. 2 = Immediately.
- **`dm_fast_equip "0"`** - Enable fast weapon equipping.
- **`dm_healthshot "0"`** - Allow players to use a healthshot.
- **`dm_healthshot_health "50"`** - Total amount of health given when a healthshot is used.
- **`dm_healthshot_total "4"`** - Total amount of healthshots a player may have at once.
- **`dm_healthshot_spawn "0"`** - Give players a healthshot on spawn.
- **`dm_healthshot_kill "0"`** - Give players a healthshot after any kill.
- **`dm_healthshot_kill_knife "0"`** - Give players a healthshot after a knife kill.
- **`dm_zeus "0"`** - Allow players to use a taser.
- **`dm_zeus_spawn "0"`** - Give players a taser on spawn.
- **`dm_zeus_kill "0"`** - Give players a taser after any kill.
- **`dm_zeus_kill_taser "0"`** - Give players a taser after a taser kill.
- **`dm_zeus_kill_knife "0"`** - Give players a taser after a knife kill.
- **`dm_nades_incendiary "0"`** - Number of incendiary grenades to give each player.
- **`dm_nades_molotov "0"`** - Number of molotov grenades to give each player.
- **`dm_nades_decoy "0"`** - Number of decoy grenades to give each player.
- **`dm_nades_flashbang "0"`** - Number of flashbang grenades to give each player.
- **`dm_nades_he "0"`** - Number of HE grenades to give each player.
- **`dm_nades_smoke "0"`** - Number of smoke grenades to give each player.
- **`dm_nades_tactical "0"`** - Number of tactical grenades to give each player.
- **`dm_armor "2"`** - Give players armor. 0 = Disable. 1 = Chest. 2 = Chest + Helmet.

**Deathmatch Loader:**
- **`dm_loader_enabled "1"`** - Enable/disable executing configs
- **`dm_loader_include_bots "1"`** - Enable/disable including bots when counting number of clients
- **`dm_loader_include_spec "1"`** - Enable/disable including spectators when counting number of clients

## Compatibility
This plugin is tested on the following **Sourcemod & Metamod** versions.
- <a href="https://www.sourcemod.net/downloads.php?branch=stable">Sourcemod 1.10+</a>
- <a href="https://www.sourcemm.net/downloads.php/?branch=stable">Metamod 1.11+</a>

## Requirements
None.

## Instructions
- Extract zip file and place files in the corresponding directories of **`/addons/sourcemod`**
- `/configs/deathmatch/deathmatch.ini`
- `/configs/deathmatch/deathmatch_*.ini`
- `/configs/deathmatch/config_loader.ini` ***(Necessary only for deathmatch loader)***
- `/configs/deathmatch/spawns/*.txt`
- `/plugins/deathmatch.smx`
- `/plugins/deathmatch_loader.smx`
- `/scripting/deathmatch.sp` ***(Necessary only for compiling)***
- `/scripting/deathmatch_loader.sp` ***(Necessary only for compiling)***

## Changelog
To view the most recent changelog visit the <a href="https://github.com/Maxximou5/csgo-deathmatch/blob/master/CHANGELOG.md">changelog</a> file.

## Download
Once installed, the plugin will update itself as long as you've done as described in the requirements section; otherwise, downloaded the latest release below.
Please download the latest **deathmatch.zip** file from <a href="https://github.com/Maxximou5/csgo-deathmatch/releases">my releases</a>.

## Bugs
If there are any bugs, please report them using the <a href="https://github.com/Maxximou5/csgo-deathmatch/issues">issues page</a>.

## Credits
A thank you to those who helped:
- <a href="https://forums.alliedmods.net/member.php?u=187003">Snip3rUK</a> - <a href="https://forums.alliedmods.net/showthread.php?t=189577">Original Plugin</a>
- <a href="https://forums.alliedmods.net/member.php?u=26021">Dr!fter</a> - General Code Support
- <a href="https://steamcommunity.com/id/DoomHammer69/">DoomHammer</a> - Debugging and Testing
- <a href="https://steamcommunity.com/id/int64shrandy/">int64 Shrandy</a> - Fixing Ammo
- <a href="https://forums.alliedmods.net/member.php?u=245683">splewis</a> - Weapon Skins Implementation
- <a href="https://steamcommunity.com/profiles/76561198098268870/">MAJOR</a> - Debugging and Testing
- <a href="http://steamcommunity.com/profiles/76561197975262643">Skyprah</a> - Debugging and Testing
- <a href="https://github.com/b3none">b3none</a> - Improvements
- <a href="https://github.com/Drixevel">Drixevel</a> - Improvements

## Donate
If you think I am doing a good job or you want to buy me a beer or feed my cat, please donate.
Thanks!

<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=VSHQ7J8HR95SG"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="csgo deathmatch plugin donate"/></a>
