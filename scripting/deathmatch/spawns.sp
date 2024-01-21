void Spawns_RespawnAll()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i))
            continue;
        RequestFrame(Frame_RespawnAll, GetClientSerial(i));
    }
}

public Action Timer_Respawn(Handle timer, any serial)
{
    int client = GetClientFromSerial(serial);
    if (g_bRoundEnded || !IsValidClient(client, true) || GetClientTeam(client) <= CS_TEAM_SPECTATOR || IsPlayerAlive(client))
        return Plugin_Handled;

    g_bPlayerMoved[client] = false;
    g_iHealthshotCount[client] = 0;
    CS_RespawnPlayer(client);

    return Plugin_Handled;
}

void Spawns_EnableSpawnProtection(int client)
{
    int clientTeam = GetClientTeam(client);
    /* Disable damage */
    SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
    /* Set player color */
    if (clientTeam == CS_TEAM_T)
        Spawns_SetPlayerColor(client, g_iColorT);
    else if (clientTeam == CS_TEAM_CT)
        Spawns_SetPlayerColor(client, g_iColorCT);
    /* Create timer to remove spawn protection */
    CreateTimer(g_cvDM_spawn_protection_time.FloatValue, Timer_DisableSpawnProtection, GetClientSerial(client));
}

public Action Timer_DisableSpawnProtection(Handle timer, any serial)
{
    int client = GetClientFromSerial(serial);
    if (!IsValidClient(client, true) || GetClientTeam(client) <= CS_TEAM_SPECTATOR || !IsPlayerAlive(client))
        return Plugin_Handled;

    /* Enable damage */
    SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
    /* Set player color */
    Spawns_SetPlayerColor(client, g_iDefaultColor);

    return Plugin_Handled;
}

void Spawns_SetPlayerColor(int client, const int color[4])
{
    /* Set the player color to the specified variables */
    SetEntityRenderMode(client, (color[3] == 255) ? RENDER_NORMAL : RENDER_TRANSCOLOR);
    SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
}

void Spawns_EnableEditorMode(int client)
{
    /* Set client edit mode to false */
    g_bInEditModeClient[client] = true;
    if (IsPlayerAlive(client))
    {
        /* After checking client alive, set attributes for God mode */
        SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
        SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
        SetEntPropFloat(client, Prop_Data, "m_flGravity", 0.2);
        SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.5);
    }
    CPrintToChat(client, "%t %t", "Chat Tag", "Spawn Editor Enabled");
}

void Spawns_DisableEditorMode(int client)
{
    /* Set client edit mode to false */
    g_bInEditModeClient[client] = false;
    if (IsPlayerAlive(client))
    {
        /* After checking client alive, remove attributes for God mode */
        SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
        SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
        SetEntPropFloat(client, Prop_Data, "m_flGravity", 1.0);
        SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
    }
    CPrintToChat(client, "%t %t", "Chat Tag", "Spawn Editor Disabled");
}

public Action Timer_RenderSpawnPoints(Handle timer, any serial)
{
    if (!g_bInEditMode)
        return Plugin_Stop;

    int client = GetClientFromSerial(serial);
    if (!IsValidClient(client))
        return Plugin_Stop;

    for (int i = 0; i < g_iSpawnPointCount; i++)
        Spawns_DisplaySpawnPoint(client, g_fSpawnPositions[i], g_fSpawnAngles[i], 40.0);

    return Plugin_Continue;
}

void Spawns_DisplaySpawnPoint(int client, float position[3], float angles[3], float size)
{
    float direction[3];
    float spawnPosition[3];
    float spawnPointOffset[3] = {0.0, 0.0, 20.0}

    GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(direction, size/2);
    AddVectors(position, direction, direction);

    TE_SetupBeamRingPoint(position, 10.0, size, g_iBeamSprite, g_iHaloSprite, 0, 0, 1.0, 1.0, 0.0, g_iDefaultColor, 50, 0);
    TE_SendToClient(client);

    TE_SetupBeamPoints(position, direction, g_iBeamSprite, g_iHaloSprite, 0, 0, 1.0, 1.0, 1.0, 0, 0.0, g_iDefaultColor, 50);
    TE_SendToClient(client);

    AddVectors(position, spawnPointOffset, spawnPosition);
    TE_SetupGlowSprite(spawnPosition, g_iGlowSprite, 1.0, 0.5, 255);
    TE_SendToClient(client);
}

public int Spawns_GetNearestSpawn(int client)
{
    if (g_iSpawnPointCount == 0)
    {
        CPrintToChat(client, "%t %t", "Chat Tag", "Spawn Editor No Spawn");
        return -1;
    }

    float clientPosition[3];
    GetClientAbsOrigin(client, clientPosition);

    int nearestPoint = 0;
    float nearestPointDistance = GetVectorDistance(g_fSpawnPositions[0], clientPosition, true);

    for (int i = 1; i < g_iSpawnPointCount; i++)
    {
        float fDistance = GetVectorDistance(g_fSpawnPositions[i], clientPosition, true);
        if (fDistance < nearestPointDistance)
        {
            nearestPoint = i;
            nearestPointDistance = fDistance;
        }
    }
    return nearestPoint;
}

void Spawns_AddSpawn(int client)
{
    if (g_iSpawnPointCount >= MAX_SPAWNS)
    {
        CPrintToChat(client, "%t %t", "Chat Tag", "Spawn Editor Spawn Not Added");
        return;
    }
    GetClientAbsOrigin(client, g_fSpawnPositions[g_iSpawnPointCount]);
    GetClientAbsAngles(client, g_fSpawnAngles[g_iSpawnPointCount]);
    g_iSpawnPointCount++;
    CPrintToChat(client, "%t %t", "Chat Tag", "Spawn Editor Spawn Added", g_iSpawnPointCount, g_iSpawnPointCount);
}

void Spawns_InsertSpawn(int client)
{
    if (g_iSpawnPointCount >= MAX_SPAWNS)
    {
        CPrintToChat(client, "%t %t", "Chat Tag", "Spawn Editor Spawn Not Added");
        return;
    }

    if (g_iSpawnPointCount == 0)
        Spawns_AddSpawn(client);
    else
    {
        /* Move spawn points down the list to make room for insertion */
        for (int i = g_iSpawnPointCount - 1; i >= g_iLastEditorSpawnPoint[client]; i--)
        {
            g_fSpawnPositions[i + 1] = g_fSpawnPositions[i];
            g_fSpawnAngles[i + 1] = g_fSpawnAngles[i];
        }
        /* Insert new spawn point */
        GetClientAbsOrigin(client, g_fSpawnPositions[g_iLastEditorSpawnPoint[client]]);
        GetClientAbsAngles(client, g_fSpawnAngles[g_iLastEditorSpawnPoint[client]]);
        g_iSpawnPointCount++;
        CPrintToChat(client, "%t %t #%i (%i total).", "Chat Tag", "Spawn Editor Spawn Inserted", g_iLastEditorSpawnPoint[client] + 1, g_iSpawnPointCount);
    }
}

void Spawns_DeleteSpawn(int spawnIndex)
{
    for (int i = spawnIndex; i < g_iSpawnPointCount - 1; i++)
    {
        g_fSpawnPositions[i] = g_fSpawnPositions[i + 1];
        g_fSpawnAngles[i] = g_fSpawnAngles[i + 1];
    }
    g_iSpawnPointCount--;
}

/* Updates the occupation status of all spawn points */
void Spawns_UpdateSpawnPoints()
{
    if (g_cvDM_enabled.BoolValue && g_iSpawnPointCount > 0)
    {
        /* Retrieve player positions */
        float playerPositions[MAXPLAYERS+1][3];
        int numberOfAlivePlayers = 0;

        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || GetClientTeam(i) <= CS_TEAM_SPECTATOR || !IsPlayerAlive(i))
                continue;
            GetClientAbsOrigin(i, playerPositions[numberOfAlivePlayers]);
            numberOfAlivePlayers++;
        }

        /* Check each spawn point for occupation by proximity to alive players */
        for (int i = 0; i < g_iSpawnPointCount; i++)
        {
            g_bSpawnPointOccupied[i] = false;
            for (int j = 0; j < numberOfAlivePlayers; j++)
            {
                float fDistance = GetVectorDistance(g_fSpawnPositions[i], playerPositions[j], true);
                if (fDistance > 10000.0)
                    continue;
                g_bSpawnPointOccupied[i] = true;
                break;
            }
        }
    }
}

void Spawns_MovePlayer(int client)
{
    g_iNumberOfPlayerSpawns++; /* Stats */

    int spawnPoint;
    int spawnLoSAttempts = g_cvDM_spawn_los_attempts.IntValue;
    int spawnDisAttempts = g_cvDM_spawn_distance_attempts.IntValue;
    float spawnMinDistance = g_cvDM_spawn_distance.FloatValue;
    bool spawnPointFound = false;

    /* Retrieve enemy positions if required by LoS/distance spawning (at eye level for LoS checking). */
    if (g_cvDM_spawn_los.BoolValue)
    {
        g_iLosSearchAttempts++; /* Stats */

        /* Try to find a suitable spawn point with a clear line of sight within distance. */
        for (int i = 0; i <= spawnLoSAttempts; i++)
        {
            #if defined DEBUG
            PrintToServer("LosAttempt = %i", i);
            #endif

            spawnPoint = GetRandomInt(0, g_iSpawnPointCount - 1);

            if (g_bSpawnPointOccupied[spawnPoint])
                continue;

            if (!Spawns_IsSuitableDistance(spawnPoint, client))
                continue;

            if (!Spawns_IsSuitableLineOfSight(spawnPoint, client))
                continue;

            #if defined DEBUG
            PrintToServer("Los SpawnPoint Found = %i", spawnPoint);
            #endif
            spawnPointFound = true;
            break;
        }
        /* Stats */
        if (spawnPointFound)
            g_iLosSearchSuccesses++;
        else
            g_iLosSearchFailures++;

        #if defined DEBUG
        if (spawnPointFound)
            PrintToServer("LoS and Distance | Found spawn point");
        else
            PrintToServer("LoS and Distance | Did not find spawn point");
        #endif
    }

    /* First fallback. Find a random unoccupied spawn point at a suitable distance. */
    if (!spawnPointFound)
    {
        g_iDistanceSearchAttempts++; /* Stats */

        if (spawnMinDistance < 0.0)
            spawnMinDistance = 0.0

        for (int i = 0; i <= spawnDisAttempts; i++)
        {
            #if defined DEBUG
            PrintToServer("DisAttempt = %i", i);
            #endif

            spawnPoint = GetRandomInt(0, g_iSpawnPointCount - 1);

            if (g_bSpawnPointOccupied[spawnPoint])
                continue;

            if (!Spawns_IsSuitableDistance(spawnPoint, client))
                continue;
            else
            {
                spawnPointFound = true;
                break;
            }
        }
        /* Stats */
        if (spawnPointFound)
            g_iDistanceSearchSuccesses++;
        else
            g_iDistanceSearchFailures++;

        #if defined DEBUG
        if (spawnPointFound)
            PrintToServer("Distance | Found spawn point");
        else
            PrintToServer("Distance | Did not find spawn point");
        #endif
    }

    /* Final fallback. Find a random unoccupied spawn point. */
    if (!spawnPointFound)
    {
        for (int i = 0; i <= MAX_SPAWNS; i++)
        {
            spawnPoint = GetRandomInt(0, g_iSpawnPointCount - 1);
            if (!g_bSpawnPointOccupied[spawnPoint])
            {
                spawnPointFound = true;
                break;
            }
        }

        #if defined DEBUG
        PrintToServer("Final Fallback | spawn point");
        #endif
    }

    if (spawnPointFound)
    {
        TeleportEntity(client, g_fSpawnPositions[spawnPoint], g_fSpawnAngles[spawnPoint], NULL_VECTOR);
        g_bSpawnPointOccupied[spawnPoint] = true;
    }
    else
        g_iSpawnPointSearchFailures++; /* Stats */
}

public bool Spawns_IsSuitableDistance(int spawnPoint, int client)
{
    bool freeForAll = g_cvDM_free_for_all.BoolValue;
    float enemyEyePositions[MAXPLAYERS+1][3];
    float spawnMinDistance = g_cvDM_spawn_distance.FloatValue;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) <= CS_TEAM_SPECTATOR || !IsPlayerAlive(i) || i == client)
            continue;

        if (freeForAll || GetClientTeam(i) != GetClientTeam(client))
            GetClientEyePosition(i, enemyEyePositions[i]);

        float fDistance = GetVectorDistance(g_fSpawnPositions[spawnPoint], enemyEyePositions[i], true);
        if (fDistance < spawnMinDistance)
            return false;
    }

    return true;
}

public bool Spawns_IsSuitableLineOfSight(int spawnPoint, int client)
{
    bool freeForAll = g_cvDM_free_for_all.BoolValue;
    bool hasClearLineOfSight = true;
    float enemyEyePositions[MAXPLAYERS+1][3];
    float spawnPointEyePosition[3];

    AddVectors(g_fSpawnPositions[spawnPoint], g_fEyeOffset, spawnPointEyePosition);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) <= CS_TEAM_SPECTATOR || !IsPlayerAlive(i) || i == client)
            continue;

        if (freeForAll || GetClientTeam(i) != GetClientTeam(client))
            GetClientEyePosition(i, enemyEyePositions[i]);

        Handle trace = TR_TraceRayFilterEx(spawnPointEyePosition, enemyEyePositions[i], MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, Spawns_TraceEntityFilterPlayer);

        if (!TR_DidHit(trace))
        {
            hasClearLineOfSight = false;
            delete trace;
            break;
        }
        delete trace;
    }

    if (hasClearLineOfSight)
        return true;
    else
        return false;
}

public bool Spawns_TraceEntityFilterPlayer(int entity, int contentsMask)
{
    if ((entity > 0) && (entity <= MaxClients)) return false;
    return true;
}

void Spawns_ResetSpawnStats()
{
    g_iNumberOfPlayerSpawns = 0;
    g_iLosSearchAttempts = 0;
    g_iLosSearchSuccesses = 0;
    g_iLosSearchFailures = 0;
    g_iDistanceSearchAttempts = 0;
    g_iDistanceSearchSuccesses = 0;
    g_iDistanceSearchFailures = 0;
    g_iSpawnPointSearchFailures = 0;
}