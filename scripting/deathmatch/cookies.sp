// A better way to do cookies, thanks to Bijleveldje
// https://forums.alliedmods.net/showthread.php?t=309889

typedef CookiemenuCallback = function void(int client, bool selection, char[] title);

void Cookiemenu_DisplayCallback(int client, bool selection, char[] title)
{
    char buffer[64];

    if (strcmp(title, "Deathmatch Damage Panel") == 0)
    {
        g_bDamagePanel[client] = selection;
        Format(buffer, sizeof(buffer), "Damage Panel %s", g_bDamagePanel[client] ? "Enabled" : "Disabled");
    }
    else if (strcmp(title, "Deathmatch Damage Popup") == 0)
    {
        g_bDamagePopup[client] = selection;
        Format(buffer, sizeof(buffer), "Damage Popup %s", g_bDamagePopup[client] ? "Enabled" : "Disabled");
    }
    else if (strcmp(title, "Deathmatch Damage Text") == 0)
    {
        g_bDamageText[client] = selection;
        Format(buffer, sizeof(buffer), "Damage Text %s", g_bDamageText[client] ? "Enabled" : "Disabled");
    }
    else if (strcmp(title, "Deathmatch Filter Kill Feed") == 0)
    {
        g_bKillFeed[client] = selection;
        Format(buffer, sizeof(buffer), "Filter Kill Feed %s", g_bKillFeed[client] ? "Enabled" : "Disabled");
    }
    else if (strcmp(title, "Deathmatch Filter Death Sounds") == 0)
    {
        g_bSoundDeaths[client] = selection;
        Format(buffer, sizeof(buffer), "Filter Death Sounds %s", g_bSoundDeaths[client] ? "Enabled" : "Disabled");
    }
    else if (strcmp(title, "Deathmatch Filter Gun Shot Sounds") == 0)
    {
        g_bSoundGunShots[client] = selection;
        Format(buffer, sizeof(buffer), "Filter Gun Shot Sounds %s", g_bSoundGunShots[client] ? "Enabled" : "Disabled");
    }
    else if (strcmp(title, "Deathmatch Filter Body Shot Sounds") == 0)
    {
        g_bSoundBodyShots[client] = selection;
        Format(buffer, sizeof(buffer), "Filter Body Shot Sounds %s", g_bSoundBodyShots[client] ? "Enabled" : "Disabled");
    }
    else if (strcmp(title, "Deathmatch Filter Headshot Shot Sounds") == 0)
    {
        g_bSoundHSShots[client] = selection;
        Format(buffer, sizeof(buffer), "Filter Headshot Shot Sounds %s", g_bSoundHSShots[client] ? "Enabled" : "Disabled");
    }
    else if (strcmp(title, "Deathmatch Headshot Only") == 0)
    {
        g_bHSOnlyClient[client] = selection;
        Format(buffer, sizeof(buffer), "Headshot Only %s", g_bHSOnlyClient[client] ? "Enabled" : "Disabled");
    }
    else if (strcmp(title, "Deathmatch Bell Kill") == 0)
    {
        g_bBellKill[client] = selection;
        Format(buffer, sizeof(buffer), "Bell Kill %s", g_bBellKill[client] ? "Enabled" : "Disabled");
    }
    else if (strcmp(title, "Deathmatch Bell Hit") == 0)
    {
        g_bBellHit[client] = selection;
        Format(buffer, sizeof(buffer), "Bell Hit %s", g_bBellHit[client] ? "Enabled" : "Disabled");
    }
    else if (strcmp(title, "Deathmatch Bell Headshot") == 0)
    {
        g_bBellHeadshot[client] = selection;
        Format(buffer, sizeof(buffer), "Bell Headshot %s", g_bBellHeadshot[client] ? "Enabled" : "Disabled");
    }

    CPrintToChat(client, "%t %t", "Chat Tag", buffer);

    ShowCookieMenu(client);
}

public void SetCookieMenu(Handle cookie, CookieMenu type, const char[] display, CookiemenuCallback callback)
{
    DataPack pack = new DataPack();
    pack.WriteCell(view_as<int>(cookie));
    pack.WriteFunction(callback);
    pack.WriteString(display);

    switch (type)
    {
        case CookieMenu_YesNo, CookieMenu_YesNo_Int:
            SetCookieMenuItem(CookieHandler_YesNo, pack, display);
        case CookieMenu_OnOff, CookieMenu_OnOff_Int:
            SetCookieMenuItem(CookieHandler_OnOff, pack, display);
    }
}

static void CookieHandler_YesNo(int client, CookieMenuAction action, DataPack pack, char[] buffer, int maxlen)
{
    Menu menu = new Menu(MenuHandler_CookieMenu);

    char sTitle[64];
    char sCookie[24];
    char sStatus[10];

    pack.Reset();
    Handle cookie = view_as<Handle>(pack.ReadCell());
    pack.ReadFunction();
    pack.ReadString(sTitle, sizeof(sTitle));

    GetClientCookie(client, cookie, sCookie, sizeof(sCookie));
    sStatus = view_as<bool>(StringToInt(sCookie)) ? "Enabled" : "Disabled";

    menu.SetTitle("%s [%s]", sTitle, sStatus);

    pack.Reset();
    char sPack[64];
    IntToString(view_as<int>(pack), sPack, sizeof(sPack));

    menu.AddItem(sPack, "Yes");
    menu.AddItem(sPack, "No");
    menu.ExitBackButton = true;
    menu.Display(client, 10);
}

static void CookieHandler_OnOff(int client, CookieMenuAction action, DataPack pack, char[] buffer, int maxlen)
{
    Menu menu = new Menu(MenuHandler_CookieMenu);

    char sTitle[64];
    char sCookie[24];
    char sStatus[10];

    pack.Reset();
    Handle cookie = view_as<Handle>(pack.ReadCell());
    pack.ReadFunction();
    pack.ReadString(sTitle, sizeof(sTitle));

    GetClientCookie(client, cookie, sCookie, sizeof(sCookie));
    sStatus = view_as<bool>(StringToInt(sCookie)) ? "Enabled" : "Disabled";

    menu.SetTitle("%s [%s]", sTitle, sStatus);

    pack.Reset();
    char sPack[64];
    IntToString(view_as<int>(pack), sPack, sizeof(sPack));

    menu.AddItem(sPack, "On");
    menu.AddItem(sPack, "Off");
    menu.ExitBackButton = true;
    menu.Display(client, 10);
}

static int MenuHandler_CookieMenu(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[64];
        menu.GetItem(param2, info, sizeof(info));
        DataPack pack = view_as<DataPack>(StringToInt(info));
        pack.Reset();
        pack.ReadCell();
        char title[64];
        pack.ReadFunction();
        pack.ReadString(title, sizeof(title));
        pack.Reset();
        Handle cookie = view_as<Handle>(pack.ReadCell());

        switch (param2)
        {
            case 0:
                SetClientCookie(param1, cookie, "1");
            case 1:
                SetClientCookie(param1, cookie, "0");
        }

        Call_StartFunction(null, pack.ReadFunction());
        Call_PushCell(param1);
        Call_PushCell(view_as<bool>(!param2));
        Call_PushString(title);
        int result;
        Call_Finish(result);
    }

    if (action == MenuAction_Cancel && IsValidClient(param1, false))
        ShowCookieMenu(param1);

    if (action == MenuAction_End)
        delete menu;
}

void ClientCookiesRefresh(int client)
{
    if (!IsFakeClient(client))
    {
        char sBuffer[24];
        char sDPanel[24];
        char sDPopup[24];
        char sDText[24];
        char sKillFeed[24];
        char sHSOnly[24];
        char sSoundDeath[24];
        char sSoundGunShots[24];
        char sSoundBodyShots[24];
        char sSoundHSShots[24];
        char sBellHit[24];
        char sBellKill[24];
        char sBellHeadshot[24];

        GetClientCookie(client, g_hDamage_Panel_Cookie, sDPanel, sizeof(sDPanel));
        GetClientCookie(client, g_hDamage_Popup_Cookie, sDPopup, sizeof(sDPopup));
        GetClientCookie(client, g_hDamage_Text_Cookie, sDText, sizeof(sDText));
        GetClientCookie(client, g_hKillFeed_Cookie, sKillFeed, sizeof(sKillFeed));
        GetClientCookie(client, g_hSoundDeath_Cookie, sSoundDeath, sizeof(sSoundDeath));
        GetClientCookie(client, g_hSoundGunShots_Cookie, sSoundGunShots, sizeof(sSoundGunShots));
        GetClientCookie(client, g_hSoundBodyShots_Cookie, sSoundBodyShots, sizeof(sSoundBodyShots));
        GetClientCookie(client, g_hSoundHSShots_Cookie, sSoundHSShots, sizeof(sSoundHSShots));
        GetClientCookie(client, g_hHSOnly_Cookie, sHSOnly, sizeof(sHSOnly));
        GetClientCookie(client, g_hBellHit_Cookie, sBellKill, sizeof(sBellKill));
        GetClientCookie(client, g_hBellKill_Cookie, sBellHit, sizeof(sBellHit));
        GetClientCookie(client, g_hBellHeadshot_Cookie, sBellHeadshot, sizeof(sBellHeadshot));

        if (strcmp(sDPanel, "") == 0)
        {
            g_bDamagePanel[client] = g_cvDM_cookie_damage_panel.BoolValue;
            IntToString(g_cvDM_cookie_damage_panel.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hDamage_Panel_Cookie, sBuffer);
        }
        else
            g_bDamagePanel[client] = view_as<bool>(StringToInt(sDPanel));

        if (strcmp(sDPopup, "") == 0)
        {
            g_bDamagePopup[client] = g_cvDM_cookie_damage_popup.BoolValue;
            IntToString(g_cvDM_cookie_damage_popup.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hDamage_Popup_Cookie, sBuffer);
        }
        else
            g_bDamagePopup[client] = view_as<bool>(StringToInt(sDPopup));

        if (strcmp(sDText, "") == 0)
        {
            g_bDamageText[client] = g_cvDM_cookie_damage_text.BoolValue;
            IntToString(g_cvDM_cookie_damage_text.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hDamage_Text_Cookie, sBuffer);
        }
        else
            g_bDamageText[client] = view_as<bool>(StringToInt(sDText));

        if (strcmp(sKillFeed, "") == 0)
        {
            g_bKillFeed[client] = g_cvDM_cookie_killfeed.BoolValue;
            IntToString(g_cvDM_cookie_killfeed.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hKillFeed_Cookie, sBuffer);
        }
        else
            g_bKillFeed[client] = view_as<bool>(StringToInt(sKillFeed));

        if (strcmp(sSoundDeath, "") == 0)
        {
            g_bSoundDeaths[client] = g_cvDM_cookie_sounds_death.BoolValue;
            IntToString(g_cvDM_cookie_sounds_death.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hSoundDeath_Cookie, sBuffer);
        }
        else
            g_bSoundDeaths[client] = view_as<bool>(StringToInt(sSoundDeath));

        if (strcmp(sSoundGunShots, "") == 0)
        {
            g_bSoundGunShots[client] = g_cvDM_cookie_sounds_gunshots.BoolValue;
            IntToString(g_cvDM_cookie_sounds_gunshots.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hSoundGunShots_Cookie, sBuffer);
        }
        else
            g_bSoundGunShots[client] = view_as<bool>(StringToInt(sSoundGunShots));

        if (strcmp(sSoundBodyShots, "") == 0)
        {
            g_bSoundBodyShots[client] = g_cvDM_cookie_sounds_bodyshots.BoolValue;
            IntToString(g_cvDM_cookie_sounds_bodyshots.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hSoundBodyShots_Cookie, sBuffer);
        }
        else
            g_bSoundBodyShots[client] = view_as<bool>(StringToInt(sSoundBodyShots));

        if (strcmp(sSoundHSShots, "") == 0)
        {
            g_bSoundHSShots[client] = g_cvDM_cookie_sounds_headshots.BoolValue;
            IntToString(g_cvDM_cookie_sounds_headshots.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hSoundHSShots_Cookie, sBuffer);
        }
        else
            g_bSoundHSShots[client] = view_as<bool>(StringToInt(sSoundHSShots));

        if (strcmp(sHSOnly, "") == 0)
        {
            g_bHSOnlyClient[client] = g_cvDM_cookie_headshot_only.BoolValue;
            IntToString(g_cvDM_cookie_headshot_only.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hHSOnly_Cookie, sBuffer);
        }
        else
            g_bHSOnlyClient[client] = view_as<bool>(StringToInt(sHSOnly));

        if (strcmp(sBellHit, "") == 0)
        {
            g_bBellHit[client] = g_cvDM_cookie_bell_hit.BoolValue;
            IntToString(g_cvDM_cookie_bell_hit.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hBellHit_Cookie, sBuffer);
        }
        else
            g_bBellHit[client] = view_as<bool>(StringToInt(sHSOnly));

        if (strcmp(sBellKill, "") == 0)
        {
            g_bBellKill[client] = g_cvDM_cookie_bell_kill.BoolValue;
            IntToString(g_cvDM_cookie_bell_kill.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hBellKill_Cookie, sBuffer);
        }
        else
            g_bBellKill[client] = view_as<bool>(StringToInt(sHSOnly));

        if (strcmp(sBellHeadshot, "") == 0)
        {
            g_bBellHeadshot[client] = g_cvDM_cookie_bell_headshot.BoolValue;
            IntToString(g_cvDM_cookie_bell_headshot.IntValue, sBuffer, sizeof(sBuffer));
            SetClientCookie(client, g_hBellHeadshot_Cookie, sBuffer);
        }
        else
            g_bBellHeadshot[client] = view_as<bool>(StringToInt(sHSOnly));
    }
}