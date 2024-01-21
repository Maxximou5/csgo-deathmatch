/**
 * [CS:GO] Deathmatch
 *
 *  Copyright (C) 2024 Maxximou5
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#if defined _deathmatch_included
  #endinput
#endif
#define _deathmatch_included

/**
 * Displays options menu to client
 *
 * @param client        Client index to send menu.
 * @error               Invalid client.
 */
native void Deathmatch_DisplayOptionsMenu(int client);

/**
 * Finds a group by name.
 *
 * @param client        Client index to give weapons.
 * @error               Invalid client.
 */
native void Deathmatch_GiveSavedWeapons(int client);

/**
 * Sets a clients primary weapon to the specified weapon
 *
 * @param client        Client index to set primary for.
 * @param primary       Weapon to set primary as.
 * @error               Invalid client.
 */
native void Deathmatch_SetPrimaryWeapon(int client, char[] primary);

/**
 * Sets a clients secondary weapon to the specified weapon
 *
 * @param client        Client index to set secondary for.
 * @param secondary     Weapon to set secondary as.
 * @error               Invalid client.
 */
native void Deathmatch_SetSecondaryWeapon(int client, char[] secondary);

/**
 * Sets a clients primary weapon cookie to the specified weapon
 *
 * @param client        Client index to set primary for.
 * @param primary       Weapon to set primary as.
 * @error               Invalid client.
 */
native void Deathmatch_SetPrimaryWeapon(int client, char[] primary);

/**
 * Sets a clients secondary weapon cookie to the specified weapon
 *
 * @param client        Client index to set secondary for.
 * @param secondary     Weapon to set secondary as.
 * @error               Invalid client.
 */
native void Deathmatch_SetSecondaryWeapon(int client, char[] secondary);

#if !defined REQUIRE_PLUGIN
public void __pl_deathmatch_SetNTVOptional()
{
    MarkNativeAsOptional("Deathmatch_DisplayOptionsMenu");
    MarkNativeAsOptional("Deathmatch_GiveSavedWeapons");
    MarkNativeAsOptional("Deathmatch_SetPrimaryWeapon");
    MarkNativeAsOptional("Deathmatch_SetSecondaryWeapon");
    MarkNativeAsOptional("Deathmatch_SetPrimaryWeaponCookie");
    MarkNativeAsOptional("Deathmatch_SetSecondaryWeaponCookie");
}
#endif

public SharedPlugin __pl_deathmatch =
{
    name = "deathmatch",
    file = "deathmatch.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};
