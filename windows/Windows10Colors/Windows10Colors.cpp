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

#ifndef NOMINMAX
#define NOMINMAX
#endif // NOMINMAX
#include "Windows10Colors.h"

#include <comdef.h>
#include <Dwmapi.h>
#include <winnt.h>
#include <wrl.h>

#include <windows.ui.viewmanagement.h>

#include <algorithm>

#if defined(_MSC_VER)
#pragma comment(lib, "dwmapi.lib")
#pragma comment(lib, "ntdll.lib")
#endif

namespace windows10colors
{

    namespace WindowsUI = ABI::Windows::UI;
    using namespace Microsoft::WRL;

/// Helper macro to exit early in case of failure HRESULTs.
#define CHECKED(X)        \
    do                    \
    {                     \
        HRESULT hr = (X); \
        if (FAILED(hr))   \
            return hr;    \
    } while (false)

    namespace
    {
        extern "C" NTSYSAPI NTSTATUS NTAPI RtlVerifyVersionInfo(PRTL_OSVERSIONINFOEXW VersionInfo,
                                                                ULONG TypeMask,
                                                                ULONGLONG ConditionMask);

        /// IsWindows8OrGreater() implementation using RtlVerifyVersionInfo
        static bool IsWindows8OrGreater()
        {
            RTL_OSVERSIONINFOEXW version = {sizeof(RTL_OSVERSIONINFOEXW), 6, 2};
            ULONGLONG conditionMask = 0;
            VER_SET_CONDITION(conditionMask, VER_MAJORVERSION, VER_GREATER_EQUAL);
            VER_SET_CONDITION(conditionMask, VER_MINORVERSION, VER_GREATER_EQUAL);
            return RtlVerifyVersionInfo(&version, VER_MAJORVERSION | VER_MINORVERSION, conditionMask) == 0;
        }

        /// IsWindows10OrGreater() implementation using RtlVerifyVersionInfo
        static bool IsWindows10OrGreater()
        {
            RTL_OSVERSIONINFOEXW version = {sizeof(RTL_OSVERSIONINFOEXW), 10, 0};
            ULONGLONG conditionMask = 0;
            VER_SET_CONDITION(conditionMask, VER_MAJORVERSION, VER_GREATER_EQUAL);
            VER_SET_CONDITION(conditionMask, VER_MINORVERSION, VER_GREATER_EQUAL);
            return RtlVerifyVersionInfo(&version, VER_MAJORVERSION | VER_MINORVERSION, conditionMask) == 0;
        }

        static bool IsWindows10_1809OrGreater()
        {
            RTL_OSVERSIONINFOEXW version = {sizeof(RTL_OSVERSIONINFOEXW), 10, 0, 17763};
            ULONGLONG conditionMask = 0;
            VER_SET_CONDITION(conditionMask, VER_MAJORVERSION, VER_GREATER_EQUAL);
            VER_SET_CONDITION(conditionMask, VER_MINORVERSION, VER_GREATER_EQUAL);
            VER_SET_CONDITION(conditionMask, VER_BUILDNUMBER, VER_GREATER_EQUAL);
            return RtlVerifyVersionInfo(&version, VER_MAJORVERSION | VER_MINORVERSION | VER_BUILDNUMBER, conditionMask) == 0;
        }

        static bool IsWindows10_1903OrGreater()
        {
            RTL_OSVERSIONINFOEXW version = {sizeof(RTL_OSVERSIONINFOEXW), 10, 0, 18362};
            ULONGLONG conditionMask = 0;
            VER_SET_CONDITION(conditionMask, VER_MAJORVERSION, VER_GREATER_EQUAL);
            VER_SET_CONDITION(conditionMask, VER_MINORVERSION, VER_GREATER_EQUAL);
            VER_SET_CONDITION(conditionMask, VER_BUILDNUMBER, VER_GREATER_EQUAL);
            return RtlVerifyVersionInfo(&version, VER_MAJORVERSION | VER_MINORVERSION | VER_BUILDNUMBER, conditionMask) == 0;
        }

        /// Wrapper for the few WinRT functions we need to use
        class WinRT
        {
            bool modules_loaded = false;
            HMODULE winrt = 0;
            HMODULE winrt_string = 0;

            typedef HRESULT(STDAPICALLTYPE *pfnWindowsCreateStringReference)(
                PCWSTR sourceString, UINT32 length, HSTRING_HEADER *hstringHeader, HSTRING *string);
            pfnWindowsCreateStringReference pWindowsCreateStringReference = nullptr;
            typedef HRESULT(WINAPI *pfnRoActivateInstance)(HSTRING activatableClassId, IInspectable **instance);
            pfnRoActivateInstance pRoActivateInstance = nullptr;

        protected:
            WinRT()
            {
            }
            ~WinRT()
            {
                if (winrt)
                    FreeLibrary(winrt);
                if (winrt_string)
                    FreeLibrary(winrt);
            }

            static WinRT instance;

            /// Load DLLs
            bool init()
            {
                if (!modules_loaded)
                {
                    modules_loaded = true;
                    winrt = LoadLibraryW(L"api-ms-win-core-winrt-l1-1-0.dll");
                    if (winrt)
                    {
                        pRoActivateInstance = reinterpret_cast<pfnRoActivateInstance>(
                            GetProcAddress(winrt, "RoActivateInstance"));
                    }
                    winrt_string = LoadLibraryW(L"api-ms-win-core-winrt-string-l1-1-0.dll");
                    if (winrt_string)
                    {
                        pWindowsCreateStringReference = reinterpret_cast<pfnWindowsCreateStringReference>(
                            GetProcAddress(winrt_string, "WindowsCreateStringReference"));
                    }
                }
                return winrt && winrt_string;
            }

            /// Wrap WindowsCreateStringReference
            inline HRESULT WindowsCreateStringReferenceImpl(PCWSTR sourceString, UINT32 length, HSTRING_HEADER *hstringHeader, HSTRING *string)
            {
                if (!init() || !pWindowsCreateStringReference)
                    return E_NOTIMPL;
                return pWindowsCreateStringReference(sourceString, length, hstringHeader, string);
            }
            /// Wrap RoActivateInstance
            inline HRESULT RoActivateInstanceImpl(HSTRING activatableClassId, IInspectable **instance)
            {
                if (!init() || !pRoActivateInstance)
                    return E_NOTIMPL;
                return pRoActivateInstance(activatableClassId, instance);
            }

        public:
            /// Dynamically loaded WindowsCreateStringReference, if available
            static HRESULT WindowsCreateStringReference(PCWSTR sourceString, UINT32 length, HSTRING_HEADER *hstringHeader, HSTRING *string)
            {
                return instance.WindowsCreateStringReferenceImpl(sourceString, length, hstringHeader, string);
            }
            /// Dynamically loaded RoActivateInstance, if available
            static HRESULT RoActivateInstance(HSTRING activatableClassId, IInspectable **newInstance)
            {
                return instance.RoActivateInstanceImpl(activatableClassId, newInstance);
            }
        };

        WinRT WinRT::instance;

        /// Wrapper class for WinRT string reference
        class HStringRef
        {
            HSTRING hstr;
            HSTRING_HEADER str_header;

        public:
            HStringRef() : hstr(nullptr) {}
            // String ref doesn't need dtor

            template <size_t N>
            HRESULT Set(const wchar_t (&str)[N])
            {
                return WinRT::WindowsCreateStringReference(str, N - 1, &str_header, &hstr);
            }

            operator HSTRING() const { return hstr; }
        };

        /// Call RoActivateInstance and query an interface
        template <typename IF>
        static HRESULT ActivateInstance(HSTRING classId, ComPtr<IF> &instance)
        {
            ComPtr<IInspectable> inspectable;
            CHECKED(WinRT::RoActivateInstance(classId, &inspectable));
            return inspectable.As(&instance);
        }

        // RAII-ish wrapper for HKEYs
        class HKEYWrapper
        {
            HKEY key;
            void Close()
            {
                if (key)
                {
                    RegCloseKey(key);
                    key = NULL;
                }
            }

        public:
            HKEYWrapper() : key(NULL) {}
            ~HKEYWrapper() { Close(); }

            operator HKEY const() { return key; }
            HKEY *operator&() { return &key; }
        };
    }

    static inline RGBA MakeRGBA(uint8_t R, uint8_t G, uint8_t B, uint8_t A)
    {
        return RGB(R, G, B) | (A << 24);
    }

    static inline RGBA MakeOpaque(RGBA base)
    {
        return base | 0xff000000;
    }

    static inline uint8_t GetAValue(RGBA rgba)
    {
        return (rgba >> 24) & 0xff;
    }

    static RGBA BlendRGBA(RGBA a, RGBA b, float f)
    {
        float a_factor = 1.f - f;
        float b_factor = f;
        BYTE alpha_a = GetAValue(a);
        BYTE alpha_b = GetAValue(b);
        return MakeRGBA(static_cast<int>(GetRValue(a) * a_factor + GetRValue(b) * b_factor),
                        static_cast<int>(GetGValue(a) * a_factor + GetGValue(b) * b_factor),
                        static_cast<int>(GetBValue(a) * a_factor + GetBValue(b) * b_factor),
                        static_cast<int>(alpha_a * a_factor + alpha_b * b_factor));
    }

    static inline RGBA ToRGBA(WindowsUI::Color color)
    {
        return MakeRGBA(color.R, color.G, color.B, color.A);
    }

    static HRESULT GetAccentColor_win10(AccentColor &color)
    {
        HStringRef classId;
        CHECKED(classId.Set(L"Windows.UI.ViewManagement.UISettings"));
        ComPtr<WindowsUI::ViewManagement::IUISettings> settings;
        CHECKED(ActivateInstance(classId, settings));

#if !defined(____x_ABI_CWindows_CUI_CViewManagement_CIUISettings3_INTERFACE_DEFINED__)
#pragma message("WARNING: Windows 10 SDK not present. GetWindows10AccentColor() will always fail at run time.")
        return E_NOTIMPL;
#else
        ComPtr<WindowsUI::ViewManagement::IUISettings3> settings3;
        CHECKED(settings.As(&settings3));
        if (!settings3)
            return E_FAIL;

        WindowsUI::Color ui_color;
        CHECKED(settings3->GetColorValue(WindowsUI::ViewManagement::UIColorType_AccentDark3, &ui_color));
        color.darkest = ToRGBA(ui_color);
        CHECKED(settings3->GetColorValue(WindowsUI::ViewManagement::UIColorType_AccentDark2, &ui_color));
        color.darker = ToRGBA(ui_color);
        CHECKED(settings3->GetColorValue(WindowsUI::ViewManagement::UIColorType_AccentDark1, &ui_color));
        color.dark = ToRGBA(ui_color);
        CHECKED(settings3->GetColorValue(WindowsUI::ViewManagement::UIColorType_Accent, &ui_color));
        color.accent = ToRGBA(ui_color);
        CHECKED(settings3->GetColorValue(WindowsUI::ViewManagement::UIColorType_AccentLight1, &ui_color));
        color.light = ToRGBA(ui_color);
        CHECKED(settings3->GetColorValue(WindowsUI::ViewManagement::UIColorType_AccentLight2, &ui_color));
        color.lighter = ToRGBA(ui_color);
        CHECKED(settings3->GetColorValue(WindowsUI::ViewManagement::UIColorType_AccentLight3, &ui_color));
        color.lightest = ToRGBA(ui_color);

        return S_OK;
#endif
    }

    template <typename T>
    static LONG QueryFromDWORD(HKEY key, const wchar_t *value, T &dest)
    {
        DWORD v = 0;
        DWORD dataSize = sizeof(v);
        LONG result = RegGetValueW(key, nullptr, value, RRF_RT_REG_DWORD, nullptr, &v, &dataSize);
        if (result == ERROR_SUCCESS)
        {
            dest = static_cast<T>(v);
        }
        return result;
    }

    struct DwmColors
    {
        RGBA ColorizationColor;
        int ColorizationColorBalance;
        bool haveAccentColor;
        RGBA AccentColor;
    };

    /* Obtain DWM colors from Registry, via undocumented keys.
       Although there's also an API to get these, it's undocumented as well... */
    static HRESULT GetDwmColors(DwmColors &colors)
    {
        HRESULT hr;
        if (!IsWindows8OrGreater())
        {
            BOOL dwmEnabled;
            hr = DwmIsCompositionEnabled(&dwmEnabled);
            if (SUCCEEDED(hr) && !dwmEnabled)
                return E_FAIL;
        }

        HKEYWrapper keyDWM;
        LONG result = RegOpenKeyExW(HKEY_CURRENT_USER, L"SOFTWARE\\Microsoft\\Windows\\DWM", 0, KEY_READ, &keyDWM);
        if (result != ERROR_SUCCESS)
            return HRESULT_FROM_WIN32(result);

        hr = S_OK;
        DWORD c;
        result = QueryFromDWORD(keyDWM, L"ColorizationColor", c);
        if (result == ERROR_SUCCESS)
        {
            // Stored in the registry as BGRA
            colors.ColorizationColor =
                MakeRGBA((c >> 16) & 0xff, (c >> 8) & 0xff, c & 0xff, (c >> 24) & 0xff);
        }
        else
        {
            hr = HRESULT_FROM_WIN32(result);
        }
        result = QueryFromDWORD(keyDWM, L"ColorizationColorBalance", colors.ColorizationColorBalance);
        if (result != ERROR_SUCCESS)
            hr = HRESULT_FROM_WIN32(result);

        result = QueryFromDWORD(keyDWM, L"AccentColor", colors.AccentColor);
        colors.haveAccentColor = result == ERROR_SUCCESS;

        return hr;
    }

    static bool IsHighContrast()
    {
        HIGHCONTRAST hc = {sizeof(HIGHCONTRAST)};
        return SystemParametersInfo(SPI_GETHIGHCONTRAST, sizeof(HIGHCONTRAST), &hc, 0) && ((hc.dwFlags & HCF_HIGHCONTRASTON) != 0);
    }

    namespace
    {
        // HSV color space helper functions
        struct HSV
        {
            int H, S, V;
        };

        static HSV RGBtoHSV(RGBA color)
        {
            HSV result;

            // Compute color as HSV. Use range [0..0x8000]
            int R = (GetRValue(color) * 0x8000) / 255;
            int G = (GetGValue(color) * 0x8000) / 255;
            int B = (GetBValue(color) * 0x8000) / 255;
            int maxComp = std::max(R, std::max(G, B));
            int minComp = std::min(R, std::min(G, B));
            int minMaxDiff = maxComp - minComp;
            result.H = 0;
            if (minMaxDiff != 0)
            {
                if (maxComp == R)
                {
                    result.H = (((G - B) * 0x8000) / minMaxDiff);
                    if (result.H < 0)
                        result.H += (6 * 0x8000);
                }
                else if (maxComp == G)
                {
                    result.H = (((B - R) * 0x8000) / minMaxDiff) + (2 * 0x8000);
                }
                else
                {
                    result.H = (((R - G) * 0x8000) / minMaxDiff) + (4 * 0x8000);
                }
            }
            result.V = maxComp;
            result.S = result.V != 0 ? (minMaxDiff * 0x8000) / result.V : 0;
            return result;
        }

        static HSV Lighter(const HSV &prev, const HSV &base)
        {
            HSV result = prev;

            // Shade: 25% of V
            // If V >= 70%, reduce sat to 75% rel
            int Vstep = base.V / 4;

            result.V = std::min(prev.V + Vstep, 0x8000);
            result.S = (result.V >= 22937) ? ((prev.S * 192) >> 8) : prev.S;
            return result;
        }

        static HSV Darker(const HSV &prev, const HSV &base)
        {
            HSV result = prev;

            // Shade: 25% of V
            int Vstep = base.V / 4;

            result.V = std::max(prev.V - Vstep, 0);
            return result;
        }

        static RGBA HSVtoRGB(const HSV &color, unsigned int alpha)
        {
            int R, G, B;
            int chroma = (color.V * color.S) / 0x8000;
            int second = (chroma * (0x8000 - abs(int(color.H % (2 * 0x8000) - 0x8000)))) / 0x8000;
            switch (color.H / 0x8000)
            {
            case 0:
                R = chroma;
                G = second;
                B = 0;
                break;
            case 1:
                R = second;
                G = chroma;
                B = 0;
                break;
            case 2:
                R = 0;
                G = chroma;
                B = second;
                break;
            case 3:
                R = 0;
                G = second;
                B = chroma;
                break;
            case 4:
                R = second;
                G = 0;
                B = chroma;
                break;
            case 5:
                R = chroma;
                G = 0;
                B = second;
                break;
            }
            int minComp = color.V - chroma;
            return MakeRGBA(std::min(((R + minComp) * 255) / 0x8000, 255),
                            std::min(((G + minComp) * 255) / 0x8000, 255),
                            std::min(((B + minComp) * 255) / 0x8000, 255),
                            alpha);
        }
    }

    static void GenerateAccentColors(RGBA base, AccentColor &color)
    {
        color.accent = base;

        // Compute shades
        HSV colorHSV = RGBtoHSV(base);

        HSV light = Lighter(colorHSV, colorHSV);
        color.light = HSVtoRGB(light, GetAValue(base));
        light = Lighter(light, colorHSV);
        color.lighter = HSVtoRGB(light, GetAValue(base));
        light = Lighter(light, colorHSV);
        color.lightest = HSVtoRGB(light, GetAValue(base));

        HSV dark = Darker(colorHSV, colorHSV);
        color.dark = HSVtoRGB(dark, GetAValue(base));
        dark = Darker(dark, colorHSV);
        color.darker = HSVtoRGB(dark, GetAValue(base));
        dark = Darker(dark, colorHSV);
        color.darkest = HSVtoRGB(dark, GetAValue(base));
    }

    static HRESULT GetAccentColor_dwm(RGBA &color)
    {
        DwmColors dwmColor;
        CHECKED(GetDwmColors(dwmColor));

        // Compose color against background
        color =
            BlendRGBA(0xffffffff, MakeOpaque(dwmColor.ColorizationColor),
                      GetAValue(dwmColor.ColorizationColor) / 255.0f);
        return S_OK;
    }

    HRESULT GetAccentColor(AccentColor &color)
    {
        HRESULT hr;
        hr = GetAccentColor_win10(color);
        if (SUCCEEDED(hr))
            return hr;

        bool highContrast = IsHighContrast();
        if (!highContrast)
        {
            RGBA colorizationComposed;
            hr = GetAccentColor_dwm(colorizationComposed);
            if (SUCCEEDED(hr))
            {
                GenerateAccentColors(colorizationComposed, color);
                return S_ACCENT_COLOR_GUESSED;
            }
        }

        if (highContrast)
        {
            // Windows 10 High Contrast mode uses the same color for all shades
            color.accent =
                color.light =
                    color.lighter =
                        color.lightest =
                            color.dark =
                                color.darker =
                                    color.darkest = MakeOpaque(GetSysColor(COLOR_HIGHLIGHT));
        }
        else
        {
            GenerateAccentColors(MakeOpaque(GetSysColor(COLOR_ACTIVECAPTION)), color);
        }
        return S_ACCENT_COLOR_GUESSED;
    }

    static HRESULT GetSystemFrameColors(FrameColors &color)
    {
        color.activeCaptionBG = MakeOpaque(GetSysColor(COLOR_ACTIVECAPTION));
        color.activeCaptionText = MakeOpaque(GetSysColor(COLOR_CAPTIONTEXT));
        color.activeFrame = MakeOpaque(GetSysColor(COLOR_CAPTIONTEXT));
        color.inactiveCaptionBG = MakeOpaque(GetSysColor(COLOR_INACTIVECAPTION));
        RGBA rawInactiveCaptionText = MakeOpaque(GetSysColor(COLOR_INACTIVECAPTIONTEXT));
        color.inactiveFrame = MakeOpaque(GetSysColor(COLOR_INACTIVECAPTIONTEXT));
        color.inactiveCaptionText = BlendRGBA(rawInactiveCaptionText, color.inactiveCaptionBG, 0.6f);

        return S_OK;
    }

    // Returns whether title bars are colored with the accent color (Windows 10)
    static bool ColoredTitleBars()
    {
        // Key on Windows 10 version 1607
        {
            HKEYWrapper keyDWM;
            LONG result = RegOpenKeyExW(HKEY_CURRENT_USER, L"SOFTWARE\\Microsoft\\Windows\\DWM",
                                        0, KEY_READ, &keyDWM);
            if (result == ERROR_SUCCESS)
            {
                DWORD prevalenceFlag = 0;
                if (QueryFromDWORD(keyDWM, L"ColorPrevalence", prevalenceFlag) == ERROR_SUCCESS)
                    return prevalenceFlag != 0;
            }
        }
        // Key on Windows 10 version 1511. After 1607 this is the start/taskbar colorization only
        {
            HKEYWrapper keyPersonalize;
            LONG result = RegOpenKeyExW(HKEY_CURRENT_USER, L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
                                        0, KEY_READ, &keyPersonalize);
            if (result == ERROR_SUCCESS)
            {
                DWORD prevalenceFlag = 0;
                if (QueryFromDWORD(keyPersonalize, L"ColorPrevalence", prevalenceFlag) == ERROR_SUCCESS)
                    return prevalenceFlag != 0;
            }
        }
        return false;
    }

    // Only obtain accent color - doesn't compute shades if using fallback
    static HRESULT GetAccentColorOnly(RGBA &color)
    {
        AccentColor ac;
        HRESULT hr;
        hr = GetAccentColor_win10(ac);
        if (SUCCEEDED(hr))
        {
            color = ac.accent;
            return hr;
        }

        hr = GetAccentColor_dwm(color);
        if (SUCCEEDED(hr))
        {
            return S_ACCENT_COLOR_GUESSED;
        }

        color = GetSysColor(COLOR_ACTIVECAPTION);
        return S_ACCENT_COLOR_GUESSED;
    }

    static bool ResolveDarkMode(DarkMode darkMode)
    {
        bool isDarkMode;
        if (darkMode == DarkMode::Auto)
        {
            /* Although the Dark Mode Apps setting was introduced in Win10 1809,
             * only in 1903 the Explorer as a Win32 app started to consider it.
             * Go with that. */
            darkMode = IsWindows10_1903OrGreater() ? DarkMode::User : DarkMode::Light;
        }
        if (darkMode == DarkMode::User)
        {
            GetAppDarkModeEnabled(isDarkMode);
        }
        else
        {
            isDarkMode = darkMode == DarkMode::Dark;
        }
        return isDarkMode;
    }

    static HRESULT GetAccentedFrameColors(FrameColors &color, unsigned int options, DarkMode darkMode)
    {
        bool isWin10 = IsWindows10OrGreater();
        bool glassEffect = (options & fcGlassEffect) != 0;
        bool useAccentColor = !isWin10 || ((options & fcTitleBarsColored) != 0) || (!glassEffect && ColoredTitleBars());

        DwmColors dwmColors;
        bool haveDwmColors = SUCCEEDED(GetDwmColors(dwmColors));

        RGBA accent;
        if (haveDwmColors && dwmColors.haveAccentColor)
        {
            /* Prefer AccentColor from registry, if present, as that typically matches the actual
             * title bar color */
            accent = dwmColors.AccentColor;
        }
        else
        {
            CHECKED(GetAccentColorOnly(accent));
        }

        bool isDarkMode = ResolveDarkMode(darkMode);
        if (useAccentColor)
        {
            color.activeCaptionBG = accent;
        }
        else
        {
            color.activeCaptionBG = isDarkMode ? 0xff000000 : 0xffffffff;
        }

        auto DefaultCaptionText =
            [](RGBA bg)
        {
            // Formula is documented here: https://docs.microsoft.com/en-us/windows/uwp/design/style/color
            bool textIsBright = IsColorDark(bg);
            return textIsBright ? 0xffffffff : 0xff000000; // Colors seem static
        };

        // Formula is documented here: https://docs.microsoft.com/en-us/windows/uwp/design/style/color
        color.activeCaptionText = DefaultCaptionText(color.activeCaptionBG);

        if (glassEffect)
        {
            color.activeFrame = color.activeCaptionBG;
        }
        else if (IsWindows10_1809OrGreater() && !useAccentColor)
        {
            /* After Windows 10, v1809 the frame color is controlled by the colored title bars option as well;
             * it's not based on the DWM ColorizationColor if colored title bars are off */
            color.activeFrame = 0xb2323232;
        }
        else
        {
            if (haveDwmColors)
            {
                const RGBA activeFrameBaseColor = 0xffd9d9d9;
                // Frame color is based on DWM colors, though those usually coincide or are based on the accent color
                if (dwmColors.ColorizationColorBalance >= 0)
                {
                    color.activeFrame = BlendRGBA(activeFrameBaseColor,
                                                  MakeOpaque(dwmColors.ColorizationColor),
                                                  dwmColors.ColorizationColorBalance * 0.01f);
                }
                else
                {
                    // Not sure, but matches observation
                    color.activeFrame = accent;
                }
            }
            else
            {
                // Fallback
                color.activeFrame = accent;
            }
        }

        color.inactiveCaptionBG = isDarkMode ? 0xff2b2b2b : 0xffffffff;
        RGBA rawInactiveCaptionText = DefaultCaptionText(color.inactiveCaptionBG);
        // inactive frame: Probably a 0.5 blend of 0xffaaaaaa and 0. Maybe 0xffaaaaaa is itself a blend.
        color.inactiveFrame = 0x7f565656;
        color.inactiveCaptionText = BlendRGBA(rawInactiveCaptionText, color.inactiveCaptionBG, isDarkMode ? 0.4f : 0.6f);
        // dark mode goal: 0xffaaaaaa

        return S_OK;
    }

    HRESULT GetFrameColors(FrameColors &color, unsigned int options, DarkMode darkMode)
    {
        // High contrast colors -> use GetSysColors
        bool use_sys_colors = IsHighContrast();

        if (!use_sys_colors)
        {
            HRESULT hr = GetAccentedFrameColors(color, options, darkMode);
            if (SUCCEEDED(hr))
                return hr;
        }

        return GetSystemFrameColors(color);
    }

    static HRESULT GetThemePersonalizeFlag(bool &resultFlag, const wchar_t *key)
    {
        HKEYWrapper keyPersonalize;
        LONG result = RegOpenKeyExW(HKEY_CURRENT_USER, L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize", 0, KEY_READ, &keyPersonalize);
        if (result != ERROR_SUCCESS)
            return HRESULT_FROM_WIN32(result);

        HRESULT hr = S_OK;
        DWORD flag;
        result = QueryFromDWORD(keyPersonalize, key, flag);
        if (result == ERROR_SUCCESS)
        {
            resultFlag = flag != 0;
        }
        else
        {
            hr = HRESULT_FROM_WIN32(result);
        }

        return hr;
    }

    HRESULT GetAppDarkModeEnabled(bool &darkMode)
    {
        bool appsLight = true; // Default: light mode
        HRESULT hr = GetThemePersonalizeFlag(appsLight, L"AppsUseLightTheme");
        darkMode = !appsLight;
        return hr;
    }

    HRESULT GetSysPartsDarkModeEnabled(bool &darkMode)
    {
        bool sysLight = true; // Default: light mode
        HRESULT hr = GetThemePersonalizeFlag(sysLight, L"SystemUsesLightTheme");
        darkMode = !sysLight;
        return hr;
    }

    HRESULT GetSysPartsMode(SysPartsMode &mode)
    {
        mode = SysPartsMode::Dark;

        bool themedSysParts = false;
        HRESULT hr = GetThemePersonalizeFlag(themedSysParts, L"ColorPrevalence");
        if (SUCCEEDED(hr) && themedSysParts)
        {
            mode = SysPartsMode::AccentColor;
            return hr;
        }

        bool sysDarkMode;
        hr = GetSysPartsDarkModeEnabled(sysDarkMode);
        if (SUCCEEDED(hr))
            mode = sysDarkMode ? SysPartsMode::Dark : SysPartsMode::Light;
        return hr;
    }

} // namespace windows10colors
