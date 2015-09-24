### [CS:GO] Deathmatch (v2.0.4d, 2015-09-06)
<a href="http://www.maxximou5.com/"><img src="http://maxximou5.com/sourcemod/assests/img/deathmatch_csgo.png" alt="csgo deathmatch plugin" width="600" /></a>
===============

Enables deathmatch style gameplay (respawning, gun selection, spawn protection, etc).

### Main Features

- Weapon Menu
- Free For All (FFA)
- Display Panel for Damage
- Different Game Modes:
 - Headshot Only Mode
 - Pistol Only Mode
 - Random Weapons Mode
- Objective Removal (C4/Hostage)
- Spawn Editor and Menu
- Replenish Ammo & Clip
- Replenish Grenades
- Kill Reward (HP/Ammo/Grenades)
- Line of Sight Spawning
- 3rd Party Knife Plugin Support
- Auto-Update Support
- Multi-Lanugage Support
 - English Supported
 - Spanish Supported
 - French Supported
 - Polish Supported
 - Brazilian Supported

### Features to Add

- Integrated Stats (ELO)
- No Knife Damage (Guns Only)
- Team Selective Spawns

### Commands

- sm_guns - Opens the !guns menu
- dm_spawn_menu - Opens the spawn point menu.
- dm_respawn_all - Respawns all players.
- dm_stats - Displays spawn statistics.
- dm_reset_stats - Resets spawn statistics.

### ConVars

- dm_enabled - (Default) 1 - Enable deathmatch.
- dm_welcomemsg (Default) 1 - Display a message saying that your server is running Deathmatch.
- dm_free_for_all - (Default) 0 - Free for all mode.
- dm_display_panel - (Default) 0 - Display a panel showing health of the victim.
- dm_display_panel_damage - (Default) 0 - Display a panel showing damage done to a player.
- dm_headshot_only - (Default) 0 - Headshot Only mode.
- dm_headshot_only_allow_world - (Default) 0 - Enable world damage during headshot only mode.
- dm_headshot_only_allow_knife - (Default) 0 - Enable knife damage during headshot only mode.
- dm_headshot_only_allow_taser - (Default) 0 - Enable taser damage during headshot only mode.
- dm_headshot_only_allow_nade - (Default) 0 - Enable grenade damage during headshot only mode.
- dm_remove_objectives - (Default) 1 - Disables bomb sites, and removes c4 and hostages.
- dm_respawning - (Default) 1 - Enable respawning.
- dm_respawn_time - (Default) 2.0 - Respawn time.
- dm_gun_menu_mode - (Default) 1 - 1) Enabled. 2) Pistol only mode. 3) Random weapons every round. 4) Disabled.
- dm_los_spawning - (Default) 1 - Enable line of sight spawning.
- dm_los_attempts - (Default) 10 - Maximum attempts to find a suitable line of sight spawn point.
- dm_spawn_distance - (Default) 0 - Minimum distance from enemies at which a player can spawn.
- dm_sp_time - (Default) 1.0 - Spawn protection time.
- dm_remove_weapons - (Default) 1 - Remove ground weapons.
- dm_replenish_ammo - (Default) 1 - Replenish ammo reserve.
- dm_replenish_clip - (Default) 1 - Replenish ammo clip.
- dm_replenish_grenade - (Default) 0 - Unlimited player grenades.
- dm_replenish_hegrenade - (Default) 0 - Unlimited hegrenades.
- dm_replenish_grenade_kill (Default) 0 - Give players their grenade back on successful kill.
- dm_hp_start - (Default) 100 - Spawn HP.
- dm_hp_max - (Default) 100 - Maximum HP.
- dm_hp_kill - (Default) 5 - HP per kill.
- dm_hp_hs - (Default) 10 - HP per headshot kill.
- dm_hp_knife - (Default) 50 - HP per knife kill.
- dm_hp_nade - (Default) 30 - HP per nade kill.
- dm_hp_messages - (Default) 1 - Display HP messages.
- dm_nade_messages - (Default) 1 - Display grenade messages.
- dm_armor - (Default) 0 - Give players chest armor.
- dm_armor_full - (Default) 1 - Give players full armor.
- dm_zeus - (Default) 0 - Give players a taser.
- dm_nades_incendiary - (Default) 0 - Number of incendiary grenades to give each player.
- dm_nades_molotov - (Default) 0 - Number of molotov grenades to give each player.
- dm_nades_decoy - (Default) 0 - Number of decoy grenades to give each player.
- dm_nades_flashbang - (Default) 0 - Number of flashbang grenades to give each player.
- dm_nades_he - (Default) 0 - Number of HE grenades to give each player.
- dm_nades_smoke - (Default) 0 - Number of smoke grenades to give each player.

### Compatibility

This plugin is tested on the following Sourcemod & Metamod Versions.

- <a href="http://www.sourcemod.net/snapshots.php">Sourcemod 1.6.3+</a>
- <a href="http://www.sourcemm.net/snapshots">Metamod 1.10.4+</a>

### Requirements

Your server must be running at least **one** of the following extensions:
- <a href="https://forums.alliedmods.net/showthread.php?t=152216">cURL</a> (Recommended)
- <a href="https://forums.alliedmods.net/showthread.php?t=67640">Socket</a>
- <a href="https://forums.alliedmods.net/forumdisplay.php?f=147">SteamTools (0.8.1+)</a>

Auto-Update Support requires <a href="https://forums.alliedmods.net/showthread.php?t=169095">updater</a> to be installed.

### Instructions

- Extract zip file and place files in the corresponding directories of **/addons/sourcemod**
- /configs/deathmatch/deathmatch.ini
- /configs/deathmatch/spawns/*.txt
- /plugins/deathmatch.smx
- /scripting/deathmatch.sp (necessary only for compiling)

### Changelog

To view the most recent changelog visit the <a href="https://github.com/Maxximou5/csgo-deathmatch/blob/master/CHANGELOG.md">changelog</a> file.

### Download

Once installed, the plugin will update itself as long as you've done as described in the requirements section; otherwise, downloaded the latest release below.
Please download the latest **deathmatch.zip** file from <a href="https://github.com/Maxximou5/csgo-deathmatch/releases">my releases</a>.

### Bugs

If there are any bugs, please report them using the <a href="https://github.com/Maxximou5/csgo-deathmatch/issues">issues page</a>.

### Credit

A thank you to those who helped:

- <a href="https://forums.alliedmods.net/member.php?u=187003">Snip3rUK</a> (<a href="https://forums.alliedmods.net/showthread.php?t=189577">Original Plugin</a>)
- <a href="https://forums.alliedmods.net/member.php?u=26021">Dr!fter</a> (General Code Support)
- <a href="http://steamcommunity.com/id/DoomHammer69/">DoomHammer</a> (Debugging and Beta Testing)

### Donate

If you think I am doing a good job or you want to buy me a beer or feed my cat, please donate.
Thanks!

<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=VSHQ7J8HR95SG"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="csgo deathmatch plugin donate"/></a>
