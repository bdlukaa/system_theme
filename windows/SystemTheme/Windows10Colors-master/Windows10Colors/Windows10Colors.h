/*
This library is licensed under the zlib license.

Copyright (C) 2016-2018 Frank Richter

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
claim that you wrote the original software. If you use this software
in a product, an acknowledgment in the product documentation would be
appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.

Original source:
https://github.com/res2k/Windows10Colors

*/
#ifndef __WINDOWS10COLORS_H__
#define __WINDOWS10COLORS_H__

/**\file
 * Functions to obtain Windows 10 accent colors and colors used to paint window frames.
 */

#include <Windows.h>

namespace windows10colors
{
    static const HRESULT S_ACCENT_COLOR_GUESSED = MAKE_HRESULT (0, 0x457, 0xC);

    /**
     * RGBA color. Red is in the LSB, Alpha in the MSB.
     * You can use GetRValue() et al to access individual components.
     */
    typedef DWORD RGBA;

    /// Accent color shades
    struct AccentColor
    {
        /// Base accent color
        RGBA accent;
        /// Darkest shade.
        RGBA darkest;
        /// Darker shade.
        RGBA darker;
        /// Dark shade.
        RGBA dark;
        /// Light shade.
        RGBA light;
        /// Lighter shade.
        RGBA lighter;
        /// Lightest shade.
        RGBA lightest;
    };

    /**
     * Return current accent color.
     * \remarks On platforms other than Windows 10 tries to guess an appropriate
     *   color. Returns \c S_ACCENT_COLOR_GUESSED in that case.
     */
    extern HRESULT GetAccentColor (AccentColor& color);

    /// Colors for Windows 10 frame painting.
    struct FrameColors
    {
        /// Color of text for active captions.
        RGBA activeCaptionText;
        /// Background color of active captions.
        RGBA activeCaptionBG;
        /**
         * Frame color of active windows.
         * \remarks Usually the frame is drawn by DWM.
         */
        RGBA activeFrame;
        /// Color of text for inactive captions.
        RGBA inactiveCaptionText;
        /// Background color of inactive captions.
        RGBA inactiveCaptionBG;
        /**
        * Frame color of inactive windows.
        * \remarks Usually the frame is drawn by DWM.
        */
        RGBA inactiveFrame;
    };

    /// Frame color options
    enum FrameColorOption
    {
        /// Default frame colors
        fcDefault = 0,
        /**
         * Whether to compute colors for a window with an enabled "sheet of glass" effect.
         * This is the case if blur behind was enabled for a window with a valid opaque
         * client area (i.e. only positive margins passed to DwmExtendFrameIntoClientArea).
         * The resulting colors will emulate a "composed" appearance.
         */
        fcGlassEffect = 1,
        /**
         * Always compute title bar colors as if they were colored.
         * Otherwise uses current system setting.
         */
        fcTitleBarsColored = 2
    };

    /// Dark mode colors selections
    enum struct DarkMode
    {
        /**
         * Choose dark mode depending on Windows version:
         * User on Windows 1903 and newer, Light otherwise.
         */
        Auto,
        /// Use user setting for Dark Mode
        User,
        /// Use light mode
        Light,
        /// Use dark mode
        Dark
    };

    /**
     * Get colors used to paint window frames.
     * \param color Receives frame color values.
     * \param options Frame color options. Combination of FrameColorOption values.
     * \param darkMode Whether to use Dark Mode colors. Note: Defaults to "Light"
     *   as the applications would need to account for this in various places.
     *   If you're application is dark-mode aware you can use "Auto" or an appropriate
     *   explicit setting.
     * \remarks On platforms other than Windows 10 tries to guess appropriate
     *   colors. Returns \c S_ACCENT_COLOR_GUESSED in that case.
     */
    extern HRESULT GetFrameColors (FrameColors& color, unsigned int options = fcDefault,
                                   DarkMode darkMode = DarkMode::Light);

    /**
     * Returns whether some color is 'dark' for the purpose of finding a contrasting
     * color - e.g. given some background color, use the 'dark' property to choose
     * an appropriate text (foreground) color.
     * Formula matches the one in https://docs.microsoft.com/en-us/windows/uwp/design/style/color
     */
    static inline bool IsColorDark (RGBA color)
    {
      return (GetRValue (color) * 2 + GetGValue (color) * 5 + GetBValue (color)) <= 1024;
    }

    /// Determines whether "Dark Mode" is enabled
    extern HRESULT GetDarkModeEnabled (bool& darkMode);
} // namespace windows10colors

#endif // __WINDOWS10COLORS_H__

