public void Frame_RespawnDead(any serial)
{
    int client = GetClientFromSerial(serial);
    if (!g_bRoundEnded && client && (GetClientTeam(client) > CS_TEAM_SPECTATOR) && !IsPlayerAlive(client))
    {
        UpdateSpawnPoints();
        g_bPlayerMoved[client] = false;
        CS_RespawnPlayer(client);
        CPrintToChat(client, "%t %t", "Chat Tag", "Player Respawn");
    }
}

public void Frame_RespawnAll(any serial)
{
    int client = GetClientFromSerial(serial);
    if (client && IsClientInGame(client) && (GetClientTeam(client) > CS_TEAM_SPECTATOR))
    {
        g_bPlayerMoved[client] = false;
        CS_RespawnPlayer(client);
        CPrintToChat(client, "%t %t", "Chat Tag", "Player Respawn");
    }
}

public void Frame_FastSwitch(any serial)
{
    int client = GetClientFromSerial(serial);
    if (client && IsClientInGame(client) && IsPlayerAlive(client))
    {
        char weapon[64];
        GetClientWeapon(client, weapon, sizeof(weapon));
        CSWeaponID weaponId = CS_AliasToWeaponID(weapon);

        int sequence = weaponId == CSWeapon_M4A1_SILENCER ? 1 : 0;
        SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime());
        int viewModel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");

        if (IsValidEntity(viewModel))
            SetEntProp(viewModel, Prop_Send, "m_nSequence", sequence);
    }
}

public void Frame_RemoveRadar(any serial)
{
    int client = GetClientFromSerial(serial);
    if (client && IsClientInGame(client) && IsPlayerAlive(client))
        SetEntProp(client, Prop_Send, "m_iHideHUD", HIDEHUD_RADAR);
}

public void Frame_GiveAmmo(any serial)
{
    int client = GetClientFromSerial(serial)
    if (client && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client))
    {
        int weaponEntity;
        switch (g_cvDM_replenish_ammo_type.IntValue)
        {
            case 1:
            {
                weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
                if (weaponEntity != -1)
                    Ammo_ClipRefill(EntIndexToEntRef(weaponEntity), client);

                weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
                if (weaponEntity != -1)
                    Ammo_ClipRefill(EntIndexToEntRef(weaponEntity), client);
            }
            case 2:
            {
                weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
                if (weaponEntity != -1)
                    Ammo_ResRefill(EntIndexToEntRef(weaponEntity), client);

                weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
                if (weaponEntity != -1)
                    Ammo_ResRefill(EntIndexToEntRef(weaponEntity), client);
            }
            case 3:
            {
                weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
                if (weaponEntity != -1)
                    Ammo_FullRefill(EntIndexToEntRef(weaponEntity), client);

                weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
                if (weaponEntity != -1)
                    Ammo_FullRefill(EntIndexToEntRef(weaponEntity), client);
            }
        }
    }
}

public void Frame_GiveAmmoHS(any serial)
{
    int client = GetClientFromSerial(serial)
    if (client && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client))
    {
        int weaponEntity;
        switch (g_cvDM_replenish_ammo_hs_type.IntValue)
        {
            case 1:
            {
                weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
                if (weaponEntity != -1)
                    Ammo_ClipRefill(EntIndexToEntRef(weaponEntity), client);

                weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
                if (weaponEntity != -1)
                    Ammo_ClipRefill(EntIndexToEntRef(weaponEntity), client);
            }
            case 2:
            {
                weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
                if (weaponEntity != -1)
                    Ammo_ResRefill(EntIndexToEntRef(weaponEntity), client);

                weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
                if (weaponEntity != -1)
                    Ammo_ResRefill(EntIndexToEntRef(weaponEntity), client);
            }
            case 3:
            {
                weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
                if (weaponEntity != -1)
                    Ammo_FullRefill(EntIndexToEntRef(weaponEntity), client);

                weaponEntity = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
                if (weaponEntity != -1)
                    Ammo_FullRefill(EntIndexToEntRef(weaponEntity), client);
            }
        }
    }
}
/* Healthshot requires a frame to be given correctly in all situations.*/
public void Frame_GiveHealthshot(any serial)
{
    if (g_cvDM_healthshot.BoolValue)
    {
        int client = GetClientFromSerial(serial)
        if (client && (g_iHealthshotCount[client] < g_cvDM_healthshot_total.IntValue) && !IsFakeClient(client) && IsPlayerAlive(client))
        {
            GivePlayerItem(client, "weapon_healthshot");
            g_iHealthshotCount[client] += 1;
        }
    }
}
/* Taser requires a frame to be given correctly in all situations. */
public void Frame_GiveTaser(any serial)
{
    if (g_cvDM_zeus.BoolValue)
    {
        int client = GetClientFromSerial(serial)
        if (client && IsClientInGame(client) && !g_bPlayerHasZeus[client] && !IsFakeClient(client) && IsPlayerAlive(client))
        {
            GivePlayerItem(client, "weapon_taser");
            g_bPlayerHasZeus[client] = true;
        }
    }
}