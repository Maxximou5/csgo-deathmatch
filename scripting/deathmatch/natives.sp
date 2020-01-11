public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("deathmatch");

    CreateNative("Deathmatch_DisplayWeaponsMenu", Native_DisplayWeaponsMenu);
    CreateNative("Deathmatch_GiveSavedWeapons", Native_GiveSavedWeapons);
    CreateNative("Deathmatch_UpdateSetting_Primary", Native_UpdateSetting_Primary);
    CreateNative("Deathmatch_UpdateSetting_Secondary", Native_UpdateSetting_Secondary);

    return APLRes_Success;
}

public int Native_DisplayWeaponsMenu(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if (client < 1 || client > MaxClients || !IsClientInGame(client))
        ThrowNativeError(SP_ERROR_NATIVE, "Client is invalid.");

    if (g_cvDM_gun_menu_mode.IntValue != 1 && g_cvDM_gun_menu_mode.IntValue != 2 && g_cvDM_gun_menu_mode.IntValue != 3)
        ThrowNativeError(SP_ERROR_NATIVE, "Native is disabled.");

    BuildWeaponsMenu(client);
}

public int Native_GiveSavedWeapons(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if (client < 1 || client > MaxClients || !IsClientInGame(client))
        ThrowNativeError(SP_ERROR_NATIVE, "Client is invalid.");

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

public int Native_UpdateSetting_Primary(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if (client < 1 || client > MaxClients || !IsClientInGame(client))
        ThrowNativeError(SP_ERROR_NATIVE, "Client is invalid.");

    GetNativeString(2, g_cPrimaryWeapon[client], sizeof(g_cPrimaryWeapon[]));
}

public int Native_UpdateSetting_Secondary(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if (client < 1 || client > MaxClients || !IsClientInGame(client))
        ThrowNativeError(SP_ERROR_NATIVE, "Client is invalid.");

    GetNativeString(2, g_cSecondaryWeapon[client], sizeof(g_cSecondaryWeapon[]));
}