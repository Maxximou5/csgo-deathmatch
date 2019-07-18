// A better way to do cookies, thanks to Bijleveldje
// https://forums.alliedmods.net/showthread.php?t=309889

typedef CookiemenuCallback = function void(int client, bool selection, char[] title);

void Cookiemenu_DisplayCallback(int client, bool selection, char[] title) {}

void Cookiemenu_HSOnlyCallback(int client, bool selection, char[] title)
{
    Client_SetHSOnly(client);
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

static void CookieHandler_YesNo(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
    Menu menu = new Menu(MenuHandler_CookieMenu);

    DataPack pack = view_as<DataPack>(info);
    pack.Reset();

    char sTitle[64];
    pack.ReadCell();
    pack.ReadFunction();
    pack.ReadString(sTitle, sizeof(sTitle));

    menu.SetTitle(sTitle);

    pack.Reset();
    char sPack[64];
    IntToString(view_as<int>(pack), sPack, sizeof(sPack));

    menu.AddItem(sPack, "Yes");
    menu.AddItem(sPack, "No");

    menu.ExitButton = true;
    menu.Display(client, 10);
}

static void CookieHandler_OnOff(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
    Menu menu = new Menu(MenuHandler_CookieMenu);

    DataPack pack = view_as<DataPack>(info);
    pack.Reset();

    char sTitle[64];
    pack.ReadCell();
    pack.ReadFunction();
    pack.ReadString(sTitle, sizeof(sTitle));

    menu.SetTitle(sTitle);

    pack.Reset();
    char sPack[64];
    IntToString(view_as<int>(pack), sPack, sizeof(sPack));

    menu.AddItem(sPack, "On");
    menu.AddItem(sPack, "Off");
    menu.ExitButton = true;
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
        char sTitle[64];
        pack.ReadFunction();
        pack.ReadString(sTitle, sizeof(sTitle));
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
        Call_PushString(sTitle);
        int result;
        Call_Finish(result);
    }

    if (action == MenuAction_End)
        delete menu;
}