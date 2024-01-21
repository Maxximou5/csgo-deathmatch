#if defined _colorlib_included
    #endinput
#endif
#define _colorlib_included

#include <colorlib_map>
 
#define MAX_MESSAGE_LENGTH 512

#define SERVER_INDEX 0
#define NO_INDEX -1
#define NO_PLAYER -2

/* CL_Colors' properties */
bool _CL_proto_buff_support;
int _CL_buffer_index;
int _CL_buffer_size;
char _CL_buffer[MAX_MESSAGE_LENGTH];
char _CL_buffer_tag[MAX_MESSAGE_LENGTH];
bool _CL_skip_list[MAXPLAYERS + 1] = { false, ... };

/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags.
 *
 * @param client    Client index.
 * @param message   Message (formatting rules).
 * @return          No return
 * 
 * On error/Errors:   If the client is not connected an error will be thrown.
 */
stock void CPrintToChat(int client, const char[] message, any ...)
{
    SetGlobalTransTarget(client);

    VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 3);
    CFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size);
    PrintToChat(client, _CL_buffer);
}

/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags.
 *
 * @param client    Client index.
 * @param author    Author index whose color will be used for teamcolor tag.
 * @param message   Message (formatting rules).
 * @return          No return
 * 
 * On error/Errors: If the client or author are not connected an error will be thrown.
 */
stock void CPrintToChatEx(int client, int author, const char[] message, any ...)
{
    SetGlobalTransTarget(client);

    VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 4);
    CFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size);
    _CL_SendChatMessage(client, author, _CL_buffer);
}

/**
 * Prints a message to all clients in the chat area.
 * Supports color tags.
 *
 * @param client    Client index.
 * @param message   Message (formatting rules)
 * @return          No return
 */
stock void CPrintToChatAll(const char[] message, any ...)
{
    for (int i = 1; i <= MaxClients; ++i)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && !_CL_skip_list[i])
        {
            SetGlobalTransTarget(i);

            VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 2);
            CFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size);
            PrintToChat(i, _CL_buffer);
        }

        _CL_skip_list[i] = false;
    }
}

/**
 * Prints a message to all clients in the chat area.
 * Supports color tags.
 *
 * @param author    Author index whos color will be used for teamcolor tag.
 * @param message   Message (formatting rules).
 * @return          No return
 * 
 * On error/Errors: If the author is not connected an error will be thrown.
 */
stock void CPrintToChatAllEx(int author, const char[] message, any ...)
{
    for (int i = 1; i <= MaxClients; ++i)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && !_CL_skip_list[i])
        {
            SetGlobalTransTarget(i);

            VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 3);
            CFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size);
            _CL_SendChatMessage(i, author, _CL_buffer);
        }

        _CL_skip_list[i] = false;
    }
}

/**
 * Prints a message to all clients on a specific team.
 * Supports color tags.
 *
 * @param team      Team index.
 * @param message   Message (formatting rules).
 * @return          No return
 * 
 * On error/Errors:   If the client is not connected an error will be thrown.
 */
stock void CPrintToChatTeam(int team, const char[] message, any ...)
{
    for (int i = 1; i <= MaxClients; ++i)
    {
        if (IsClientInGame(i) &&
            !IsFakeClient(i) &&
            !_CL_skip_list[i] &&
            GetClientTeam(i) == team)
        {
            SetGlobalTransTarget(i);

            VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 3);
            CFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size);
            PrintToChat(i, _CL_buffer);
        }

        _CL_skip_list[i] = false;
    }
}

/**
 * Prints a message to all clients on a specific team.
 * Supports color tags.
 *
 * @param team      Team index.
 * @param author    Author index whos color will be used for teamcolor tag.
 * @param message   Message (formatting rules).
 * @return          No return
 * 
 * On error/Errors:   If the client is not connected an error will be thrown.
 */
stock void CPrintToChatTeamEx(int team, int author, const char[] message, any ...)
{
    for (int i = 1; i <= MaxClients; ++i)
    {
        if (IsClientInGame(i) &&
            !IsFakeClient(i) &&
            !_CL_skip_list[i] &&
            GetClientTeam(i) == team)
        {
            SetGlobalTransTarget(i);

            VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 4);
            CFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size);
            _CL_SendChatMessage(i, author, _CL_buffer);
        }

        _CL_skip_list[i] = false;
    }
}

/**
 * Prints a message to all admins with the given access flags.
 * Supports color tags.
 *
 * @param flags     Admin flags.
 * @param message   Message (formatting rules).
 * @return          No return
 * 
 * On error/Errors:   If the client is not connected an error will be thrown.
 */
stock void CPrintToChatAdmins(int flags, const char[] message, any ...)
{
    for (int i = 1; i <= MaxClients; ++i)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && !_CL_skip_list[i])
        {
            if (CheckCommandAccess(i, "colorlib_admin", flags, true))
            {
                SetGlobalTransTarget(i);

                VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 3);
                CFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size);
                PrintToChat(i, _CL_buffer);
            }
        }

        _CL_skip_list[i] = false;
    }
}

/**
 * Reples to a message in a command. A client index of 0 will use PrintToServer().
 * If the command was from the console, PrintToConsole() is used. If the command was from chat, C_PrintToChat() is used.
 * Supports color tags.
 *
 * @param client    Client index, or 0 for server.
 * @param message   Formatting rules.
 * @param ...       Variable number of format parameters.
 * @return          No return
 * 
 * On error/Errors:   If the client is not connected or invalid.
 */
stock void CReplyToCommand(int client, const char[] message, any ...)
{
    SetGlobalTransTarget(client);

    if (client == 0)
    {
        VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 3);
        CRemoveTags(_CL_buffer[_CL_buffer_index], _CL_buffer_size);
        PrintToServer(_CL_buffer[_CL_buffer_index]);
    }
    else if (GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
    {
        VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 3);
        CRemoveTags(_CL_buffer[_CL_buffer_index], _CL_buffer_size);
        PrintToConsole(client, _CL_buffer[_CL_buffer_index]);
    }
    else
    {
        VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 3);
        CFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size);
        PrintToChat(client, _CL_buffer);
    }
}

/**
 * Reples to a message in a command. A client index of 0 will use PrintToServer().
 * If the command was from the console, PrintToConsole() is used. If the command was from chat, C_PrintToChat() is used.
 * Supports color tags.
 *
 * @param client    Client index, or 0 for server.
 * @param author    Author index whose color will be used for teamcolor tag.
 * @param message   Formatting rules.
 * @param ...       Variable number of format parameters.
 * @return          No return
 * 
 * On error/Errors:   If the client is not connected or invalid.
 */
stock void CReplyToCommandEx(int client, int author, const char[] message, any ...)
{
    SetGlobalTransTarget(client);

    if (client == 0)
    {
        VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 4);
        CRemoveTags(_CL_buffer[_CL_buffer_index], _CL_buffer_size);
        PrintToServer(_CL_buffer[_CL_buffer_index]);
    }
    else if (GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
    {
        VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 4);
        CRemoveTags(_CL_buffer[_CL_buffer_index], _CL_buffer_size);
        PrintToConsole(client, _CL_buffer[_CL_buffer_index]);
    }
    else
    {
        VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 4);
        CFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size);
        _CL_SendChatMessage(client, author, _CL_buffer);
    }
}

/**
 * Displays usage of an admin command to users depending on the setting of the sm_show_activity cvar.
 * This version does not display a message to the originating client if used from chat triggers or menus. If manual replies are used for these cases, then this function will suffice. Otherwise, ShowActivity2() is slightly more useful.
 * Supports color tags.
 *
 * @param client    Client index, or 0 for server.
 * @param message   Formatting rules.
 * @param ...       Variable number of format parameters.
 * @return          No return
 * 
 * On error/Errors:   If the client is not connected or invalid.
 */
stock void CShowActivity(int client, const char[] message, any ...)
{
    SetGlobalTransTarget(client);

    VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 3);
    CFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size);
    ShowActivity(client, _CL_buffer[_CL_buffer_index]);
}

/**
 * Displays usage of an admin command to users depending on the setting of the sm_show_activity cvar. All users receive a message in their chat text, except for the originating client, who receives the message based on the current ReplySource.
 * Supports color tags.
 *
 * @param client    Client index, or 0 for server.
 * @param message   Formatting rules.
 * @param ...       Variable number of format parameters.
 * @return          No return
 * 
 * On error/Errors:   If the client is not connected or invalid.
 */
stock void CShowActivity2(int client, const char[] tag, const char[] message, any ...)
{
    SetGlobalTransTarget(client);

    strcopy(_CL_buffer_tag, sizeof(_CL_buffer_tag), tag);
    CFormat(_CL_buffer_tag, sizeof(_CL_buffer_tag));

    VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 4);
    CFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size);

    ShowActivity2(client, _CL_buffer_tag, _CL_buffer);
}

/**
 * Same as ShowActivity(), except the tag parameter is used instead of "[SM] " (note that you must supply any spacing).
 * Supports color tags.
 *
 * @param client    Client index, or 0 for server.
 * @param message   Formatting rules.
 * @param ...       Variable number of format parameters.
 * @return          No return
 * 
 * On error/Errors:   If the client is not connected or invalid.
 */
stock void CShowActivityEx(int client, const char[] tag, const char[] message, any ...)
{
    SetGlobalTransTarget(client);

    strcopy(_CL_buffer_tag, sizeof(_CL_buffer_tag), tag);
    CFormat(_CL_buffer_tag, sizeof(_CL_buffer_tag));

    VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 4);
    CFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size);

    ShowActivityEx(client, _CL_buffer_tag, _CL_buffer);
}

/**
 * Replaces PrintToServer.
 * Removes color tags.
 *
 * @param message   Formatting rules.
 * @param ...       Variable number of format parameters.
 * @return          No return
 */
stock void CPrintToServer(const char[] message, any ...)
{
    VFormat(_CL_buffer[_CL_buffer_index], _CL_buffer_size, message, 2);
    CRemoveTags(_CL_buffer[_CL_buffer_index], _CL_buffer_size);
    PrintToServer(_CL_buffer[_CL_buffer_index]);
}

/**
 * Gets a clients name that is safe to use with Color Lib.
 *
 * @param client    Client index.
 * @param name      Buffer to store the clients name.
 * @param maxlength The size of the buffer.
 * @return          No return
 */
stock void CGetClientName(int client, char[] name, int maxlength, bool remove = true)
{
    GetClientName(client, name, maxlength);
    if (remove)
    {
        CRemoveTags(name, maxlength);
    }
    else
    {
        CEscapeTags(name, maxlength);
    }
}

/**
 * Removes color tags from the string.
 * E.g. "{default}Hello {red}World" -> "Hello World".
 *
 * @param message   String.
 * @param maxlength Size of the message buffer.
 * @return          No return
 */
stock void CRemoveTags(char[] message, int maxlength)
{
    int index = 0;
    for (int i = 0; i < maxlength; ++i)
    {
        if (message[i] == 0x00)
        {
            break;
        }

        if (message[i] == '{')
        {
            ++i;
            while (message[i] != '}')
            {
                ++i;
            }
        }
        else if (message[i] == '\\')
        {
            ++i;
            if (message[i] == '{')
            {
                message[index] = '{';
            }
            else
            {
                message[index] = '\\';
                --i;
            }

            ++index;
        }
        else
        {
            message[index] = message[i];
            ++index;
        }
    }

    message[index] = 0x00;
}

/**
 * Removes colors escape codes from the string.
 * E.g. "\x01Hello \x02World" -> "Hello World".
 *
 * @param message   String.
 * @param maxlength Size of the message buffer.
 * @return          No return
 */
stock void CRemoveColors(char[] message, int maxlength)
{
    int index = 0;
    for (int i = 0; i < maxlength; ++i)
    {
        if (message[i] == 0x00)
        {
            break;
        }

        if (message[i] >= 0x01 && message[i] <= 0x10)
        {
            ++i;
        }

        message[index] = message[i];
        ++index;
    }

    message[index] = 0x00;
}

/**
 * Escapes colors escape codes from the string.
 * E.g. "{red}Hello {blue}World" -> "\{red}Hello \{blue}World".
 * This means they shal be ignored by CFormat, useful for sanitising player
 * names for printing.
 *
 * @param message   String.
 * @param maxlength Size of the message buffer.
 * @return          No return
 */
stock void CEscapeTags(char[] message, int maxlength)
{
    int index = 0;
    for (int i = 0; i < maxlength; ++i)
    {
        if (message[i] == 0x00)
        {
            break;
        }

        if (message[i] == '{')
        {
            message[index] = '\\';
            ++index;
            message[index] = '{';
            ++index;
        }
        else if (message[i] == '\\')
        {
            ++i;
            if (message[i] == '{')
            {
                message[index] = '\\';
                ++index;
                message[index] = '{';
            }
            else
            {
                message[index] = '\\';
                --i;
            }

            ++index;
        }
        else
        {
            message[index] = message[i];
            ++index;
        }
    }

    message[index] = 0x00;
}

/**
 * This function should only be used right in front of
 * C_PrintToChatAll or C_PrintToChatAllEx and it tells
 * to those funcions to skip specified client when printing
 * message to all clients. After message is printed client will
 * no more be skipped.
 * 
 * @param client    Client index
 * @return          No return
 */
stock void CSkipNextClient(int client)
{
    if (client < 1 || client > MaxClients)
        ThrowError("Invalid client index %d", client);

    _CL_skip_list[client] = true;
}

/**
 * Initialises the _CL_buffer for color formatting
 *
 * @param message   String.
 * @return          First free index in the array
 */
stock int CPreFormat(char[] message)
{
    int index = 0;
    // If CS:GO set invisible precolor
    if (GetEngineVersion() == Engine_CSGO)
    {
        message[0] = ' ';
        ++index;
    }

    message[index] = 0x01;
    ++index;

    return index;
}

/**
 * Replaces color tags in a string with color codes
 *
 * @param message   String.
 * @param maxlength Size of the message buffer.
 * @return          Client index that can be used for SayText2 author index
 * 
 * On error/Errors: If there is more then one team color is used an error will be thrown.
 */
stock void CFormat(char[] message, int maxlength)
{
    int index = 0;
    for (int i = 0; i < maxlength; ++i)
    {
        if (message[i] == 0x00)
        {
            break;
        }

        if (message[i] == '{')
        {
            ++i;
            int length = 0;
            char cc = view_as<char>(_CL_ColorMap(message[i], length));
            if (cc)
            {
                message[index] = cc;
                i += length;
            }
            else
            {
                message[index] = '{';
            }

            /* we need to unpeek the increment for skipping over all of the
             * color tag + so we dont skip a char for a bad tag */
            --i;
            ++index;
        }
        else if (message[i] == '\\')
        {
            ++i;
            if (message[i] == '{')
            {
                message[index] = '{';
            }
            else
            {
                message[index] = '\\';
                --i;
            }

            ++index;
        }
        else
        {
            message[index] = message[i];
            ++index;
        }
    }

    message[index] = 0x00;
}

/**
 * Sends a SayText2 usermessage to a client
 *
 * @param message   Client index
 * @param author    Author index
 * @param message   Message
 * @return          No return.
 */
stock void CSayText2(int client, int author, const char[] message)
{
    if (_CL_proto_buff_support)
    {
        Protobuf pbMessage = view_as<Protobuf>(StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
        pbMessage.SetInt("ent_idx", author);
        pbMessage.SetBool("chat", true);
        pbMessage.SetString("msg_name", message);
        pbMessage.AddString("params", "");
        pbMessage.AddString("params", "");
        pbMessage.AddString("params", "");
        pbMessage.AddString("params", "");
    }
    else
    {
        Handle hMessage = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
        BfWriteByte(hMessage, author);
        BfWriteByte(hMessage, true);
        BfWriteString(hMessage, message);
    }

    EndMessage();
}

/**
 * Sends a message to a client.
 *
 * @param message   Client index
 * @param author    Author index
 * @param message   Message
 * @return          No return.
 */
stock void _CL_SendChatMessage(int client, int author, char[] message)
{
    if (author)
    {
        CSayText2(client, author, message);
    }
    else
    {
        PrintToChat(client, message);
    }
}

/* BADNESS BELOW THIS LINE DO NOT EDIT */

public void OnPluginStart()
{
    _CL_proto_buff_support = (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available) && (GetUserMessageType() == UM_Protobuf);
    _CL_buffer_index = CPreFormat(_CL_buffer);
    _CL_buffer_size = sizeof(_CL_buffer) - _CL_buffer_index;
    _CL_OnPluginStart();
}

#define OnPluginStart _CL_OnPluginStart
