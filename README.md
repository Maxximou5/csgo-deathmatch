### [CS:GO] Deathmatch (v2.0.0, 2014-08-16)
<a href="http://maxximou5.com/sourcemod"><img src="http://maxximou5.com/sourcemod/assests/img/deathmatch_csgo.png" alt="csgo deathmatch plugin" width="600" /></a>
===============

Enables deathmatch style gameplay (respawning, gun selection, spawn protection, etc).

### Main features

- Weapon Menu
- Free For All (FFA)
- Spawn Editor and Menu
- Unlimited Ammo & Grenades
- Kill Reward (HP/Ammo/Grenades)
- Line of Sight Spawning
- Auto Update Support

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
- dm_remove_objectives - (Default) 1 - Disables bomb sites, and removes c4 and hostages.
- dm_respawning - (Default) 1 - Enable respawning. - dm_respawn_time - 2.0 - Respawn time.
- dm_gun_menu_mode - (Default) 1 - 1) Enabled. 2) Disabled. 3) Random weapons every round.
- dm_los_spawning - (Default) 1 - Enable line of sight spawning.
- dm_los_attempts - (Default) 10 - Maximum attempts to find a suitable line of sight spawn point.
- dm_spawn_distance - (Default) 0 - Minimum distance from enemies at which a player can spawn.
- dm_sp_time - (Default) 1.0 - Spawn protection time.
- dm_remove_weapons - (Default) 1 - Remove ground weapons.
- dm_replenish_ammo - (Default) 1 - Unlimited player ammo
- dm_replenish_grenade - (Default) 0 - Unlimited player grenades.
- dm_replenish_hegrenade - (Default) 0 - Unlimited hegrenades.
- dm_hp_start - (Default) 100 - Spawn HP.
- dm_hp_max - (Default) 100 - Maximum HP
- dm_hp_kill - (Default) 5 - HP per kill
- dm_hp_hs - (Default) 10 - HP per headshot kill.
- dm_hp_knife - (Default) 50 - HP per knife kill.
- dm_hp_messages - (Default) 1 - Display HP messages.
- dm_nade_messages - (Default) 1 - Display grenade messages.
- dm_armour - (Default) 1 - Give players armour.
- dm_zeus - (Default) 0 - Give players a taser.
- dm_nades_incendiary - (Default) 0 - Number of incendiary grenades to give each player.
- dm_nades_molotov - (Default) 0 - Number of molotov grenades to give each player.
- dm_nades_decoy - (Default) 0 - Number of decoy grenades to give each player.
- dm_nades_flashbang - (Default) 0 - Number of flashbang grenades to give each player.
- dm_nades_he - (Default) 0 - Number of HE grenades to give each player.
- dm_nades_smoke - (Default) 0 - Number of smoke grenades to give each player.

### Compatibility

This plugin is tested on the following Sourcemod & Metamod Versions.

- Sourcemod 1.6.1+
- Metamod 1.10.0+

### Requirements

Your server must be running at least one of the following extensions:
- <a href="https://forums.alliedmods.net/showthread.php?t=152216">cURL</a>
- <a href="https://forums.alliedmods.net/showthread.php?t=67640">Socket</a>
- <a href="https://forums.alliedmods.net/forumdisplay.php?f=147">SteamTools (0.8.1+)</a>

Autoupdate Support requires <a href="https://forums.alliedmods.net/showthread.php?t=169095">updater</a> to be installed.

### Instructions

- Extract zip file and place files in the corresponding directories of **/addons/sourcemod**
- /configs/deathmatch/deathmatch.ini
- /configs/deathmatch/spawns/*.txt
- /plugins/deathmatch.smx
- /scripting/deathmatch.sp (necessary only for compiling)

### Download

Once installed, the plugin will update itself as long as you've done as described in the requirements section; otherwise, downloaded the latest release below.
Please download the latest **deathmatch.zip** file from <a href="https://github.com/Maxximou5/csgo-deathmatch/releases">my releases</a>.
