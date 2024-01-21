//
// This file was generated with color_gen.py and should not be used outside of colorlib.inc
//
// Do not edit! Regenerate this file with color_gen.py (see https://github.com/c0rp3n/colorlib-gen)
//

#if defined _colorlib_map_included
    #endinput
#endif
#define _colorlib_map_included

enum CL_Color
{
    CL_Color_Default = 0x01,
    CL_Color_Prefix = 0x04,
    CL_Color_Reply2cmd = 0x01,
    CL_Color_Showactivity = 0x01,
    CL_Color_Error = 0x07,
    CL_Color_Highlight = 0x10,
    CL_Color_Player = 0x09,
    CL_Color_Settings = 0x02,
    CL_Color_Command = 0x02,
    CL_Color_Team_0 = 0x08,
    CL_Color_Team_1 = 0x09,
    CL_Color_Team_2 = 0x11,
    CL_Color_Teamcolor = 0x03,
    CL_Color_Red = 0x07,
    CL_Color_Lightred = 0x0F,
    CL_Color_Darkred = 0x02,
    CL_Color_Bluegrey = 0x0A,
    CL_Color_Blue = 0x0B,
    CL_Color_Darkblue = 0x0C,
    CL_Color_Purple = 0x03,
    CL_Color_Orchid = 0x0E,
    CL_Color_Orange = 0x10,
    CL_Color_Yellow = 0x09,
    CL_Color_Gold = 0x10,
    CL_Color_Lightgreen = 0x05,
    CL_Color_Green = 0x04,
    CL_Color_Lime = 0x06,
    CL_Color_Grey = 0x08,
    CL_Color_Grey2 = 0x0D,
    CL_Color_Engine_1 = 0x01,
    CL_Color_Engine_2 = 0x02,
    CL_Color_Engine_3 = 0x03,
    CL_Color_Engine_4 = 0x04,
    CL_Color_Engine_5 = 0x05,
    CL_Color_Engine_6 = 0x06,
    CL_Color_Engine_7 = 0x07,
    CL_Color_Engine_8 = 0x08,
    CL_Color_Engine_9 = 0x09,
    CL_Color_Engine_10 = 0x0A,
    CL_Color_Engine_11 = 0x0B,
    CL_Color_Engine_12 = 0x0C,
    CL_Color_Engine_13 = 0x0D,
    CL_Color_Engine_14 = 0x0E,
    CL_Color_Engine_15 = 0x0F,
    CL_Color_Engine_16 = 0x10,
};

CL_Color _CL_ColorMap(const char[] color, int& length)
{
    if (color[0] == 'e')
    {
        if (color[1] == 'n')
        {
            if (color[7] == '1')
            {
                if (color[8] == '}')
                {
                    length = 9;
                    return CL_Color_Engine_1;
                }
                else if (color[8] == '0')
                {
                    length = 10;
                    return CL_Color_Engine_10;
                }
                else if (color[8] == '1')
                {
                    length = 10;
                    return CL_Color_Engine_11;
                }
                else if (color[8] == '2')
                {
                    length = 10;
                    return CL_Color_Engine_12;
                }
                else if (color[8] == '3')
                {
                    length = 10;
                    return CL_Color_Engine_13;
                }
                else if (color[8] == '4')
                {
                    length = 10;
                    return CL_Color_Engine_14;
                }
                else if (color[8] == '5')
                {
                    length = 10;
                    return CL_Color_Engine_15;
                }
                else if (color[8] == '6')
                {
                    length = 10;
                    return CL_Color_Engine_16;
                }
            }
            else if (color[7] == '2')
            {
                length = 9;
                return CL_Color_Engine_2;
            }
            else if (color[7] == '3')
            {
                length = 9;
                return CL_Color_Engine_3;
            }
            else if (color[7] == '4')
            {
                length = 9;
                return CL_Color_Engine_4;
            }
            else if (color[7] == '5')
            {
                length = 9;
                return CL_Color_Engine_5;
            }
            else if (color[7] == '6')
            {
                length = 9;
                return CL_Color_Engine_6;
            }
            else if (color[7] == '7')
            {
                length = 9;
                return CL_Color_Engine_7;
            }
            else if (color[7] == '8')
            {
                length = 9;
                return CL_Color_Engine_8;
            }
            else if (color[7] == '9')
            {
                length = 9;
                return CL_Color_Engine_9;
            }
        }
        else if (color[1] == 'r')
        {
            length = 6;
            return CL_Color_Error;
        }
    }
    else if (color[0] == 't')
    {
        if (color[4] == ' ')
        {
            if (color[5] == '0')
            {
                length = 7;
                return CL_Color_Team_0;
            }
            else if (color[5] == '1')
            {
                length = 7;
                return CL_Color_Team_1;
            }
            else if (color[5] == '2')
            {
                length = 7;
                return CL_Color_Team_2;
            }
        }
        else if (color[4] == 'c')
        {
            length = 10;
            return CL_Color_Teamcolor;
        }
    }
    else if (color[0] == 'g')
    {
        if (color[1] == 'r')
        {
            if (color[3] == 'y')
            {
                if (color[4] == '}')
                {
                    length = 5;
                    return CL_Color_Grey;
                }
                else if (color[4] == '2')
                {
                    length = 6;
                    return CL_Color_Grey2;
                }
            }
            else if (color[3] == 'e')
            {
                length = 6;
                return CL_Color_Green;
            }
        }
        else if (color[1] == 'o')
        {
            length = 5;
            return CL_Color_Gold;
        }
    }
    else if (color[0] == 'd')
    {
        if (color[1] == 'a')
        {
            if (color[4] == 'r')
            {
                length = 8;
                return CL_Color_Darkred;
            }
            else if (color[4] == 'b')
            {
                length = 9;
                return CL_Color_Darkblue;
            }
        }
        else if (color[1] == 'e')
        {
            length = 8;
            return CL_Color_Default;
        }
    }
    else if (color[0] == 'p')
    {
        if (color[1] == 'r')
        {
            length = 7;
            return CL_Color_Prefix;
        }
        else if (color[1] == 'l')
        {
            length = 7;
            return CL_Color_Player;
        }
        else if (color[1] == 'u')
        {
            length = 7;
            return CL_Color_Purple;
        }
    }
    else if (color[0] == 'l')
    {
        if (color[2] == 'g')
        {
            if (color[5] == 'r')
            {
                length = 9;
                return CL_Color_Lightred;
            }
            else if (color[5] == 'g')
            {
                length = 11;
                return CL_Color_Lightgreen;
            }
        }
        else if (color[2] == 'm')
        {
            length = 5;
            return CL_Color_Lime;
        }
    }
    else if (color[0] == 'r')
    {
        if (color[2] == 'p')
        {
            length = 10;
            return CL_Color_Reply2cmd;
        }
        else if (color[2] == 'd')
        {
            length = 4;
            return CL_Color_Red;
        }
    }
    else if (color[0] == 's')
    {
        if (color[1] == 'h')
        {
            length = 13;
            return CL_Color_Showactivity;
        }
        else if (color[1] == 'e')
        {
            length = 9;
            return CL_Color_Settings;
        }
    }
    else if (color[0] == 'b')
    {
        if (color[4] == 'g')
        {
            length = 9;
            return CL_Color_Bluegrey;
        }
        else if (color[4] == '}')
        {
            length = 5;
            return CL_Color_Blue;
        }
    }
    else if (color[0] == 'o')
    {
        if (color[2] == 'c')
        {
            length = 7;
            return CL_Color_Orchid;
        }
        else if (color[2] == 'a')
        {
            length = 7;
            return CL_Color_Orange;
        }
    }
    else if (color[0] == 'h')
    {
        length = 10;
        return CL_Color_Highlight;
    }
    else if (color[0] == 'c')
    {
        length = 8;
        return CL_Color_Command;
    }
    else if (color[0] == 'y')
    {
        length = 7;
        return CL_Color_Yellow;
    }

    return view_as<CL_Color>(0x00);
}
