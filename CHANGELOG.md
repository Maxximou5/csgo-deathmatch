v2.0.4a:
- Fixed: Translation file, incorrect color syntax due to new include.
- Added: Polish translation thanks to szyma94

v2.0.4:
- Fixed: Random weapons not parsing from the deathmatch.ini
- Fixed: Error: Line 1051, deathmatch.sp::Event_Say()
- Fixed: Error: Line 1730, deathmatch.sp::RefillWeapons()
- Fixed: Display panel not being shown despite being set yes in deathmatch.ini file.
- Fixed: Spawn location glitches on maps.
- Added: New spawn locations for new maps.
- Added: Armor (chest) & Armor (full)
- Added: dm_replenish_grenade_kill (Give players their grenade back on successful grenade kill.)

v2.0.3:
- Changed the way ammo replenish works (thanks to int64 Shrandy)
- Added new cvars:
	- dm_replenish_ammo & dm_replenish_clip
	- dm_display_panel & dm_display_panel_damage
- Added new display panel for damage info
- Added Multi-Lanugage support
	- English Supported
	- Spanish Supported
	- French Supported
- Added csgocolors (need csgocolors.inc for compiling)
- Fixed blood splatter issue when turning hsonly off & on
- Fixed bots not having or not equiping guns
- Fixed timer message (client index 0)

v2.0.2c:
- Fixed an issue with same all not remembering it's job

v2.0.2b:
- Added Pistol only mode, available through gun_menu_mode
- Fixed issue with welcome message
- Fixed issue with bots and weapons (hopefully)
- Fixed issue with gun menu being available to admins when it shouldn't

v2.0.2a:
- Fixed issue with spawning with wrong weapon or no knife
- Fixed Headshot Only mode displaying blood on body shots
- Fixed minor issues that went unnoticed
- Added support for 3rd party knife plugins
- A thank you to klexen & Kryptos

v2.0.2:
- Added Headshot Only mode
	- Allow world kills
	- Allow knife kills
	- Allow taser kills
	- Allow grenade kills
- Added HP for grenade kills
- Fixed Native "IsClientInGame" reported: Client index 0 is invalid
- Fixed Native "SetEntProp" reported: Entity 1 (1) is invalid
- A thank you too versatile_bfg again

v2.0.1:
- Added spawn points for maps de_cbble & de_overpass
- Changed plugin to allow load without updater dependency
- A thank you too versatile_bfg

v2.0.0:
- Initial Public Release