// PaintWin10Colors.cpp : Defines the entry point for the application.
//

#include "stdafx.h"
#include "PaintWin10Colors.h"

#include <objidl.h>
#include <gdiplus.h>

#include <memory>

#include "Windows10Colors.h"

#define MAX_LOADSTRING 100

// Global Variables:
HINSTANCE hInst;                                // current instance
WCHAR szTitle[MAX_LOADSTRING];                  // The title bar text
WCHAR szWindowClass[MAX_LOADSTRING];            // the main window class name
// Cached colors
windows10colors::AccentColor accents;
bool accents_valid = false;
windows10colors::FrameColors colors;
windows10colors::FrameColors colorsGlass;

static void UpdateWindows10Colors ()
{
    accents_valid = SUCCEEDED (windows10colors::GetAccentColor (accents));
    windows10colors::GetFrameColors (colors, windows10colors::fcDefault, windows10colors::DarkMode::Auto);
    windows10colors::GetFrameColors (colorsGlass, windows10colors::fcGlassEffect, windows10colors::DarkMode::Auto);
}

// Forward declarations of functions included in this code module:
ATOM                MyRegisterClass(HINSTANCE hInstance);
BOOL                InitInstance(HINSTANCE, int);
LRESULT CALLBACK    WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK    About(HWND, UINT, WPARAM, LPARAM);

int APIENTRY wWinMain(_In_ HINSTANCE hInstance,
                     _In_opt_ HINSTANCE hPrevInstance,
                     _In_ LPWSTR    lpCmdLine,
                     _In_ int       nCmdShow)
{
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);

    // Initialize global strings
    LoadStringW(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
    LoadStringW(hInstance, IDC_PAINTWIN10COLORS, szWindowClass, MAX_LOADSTRING);
    MyRegisterClass(hInstance);

    ULONG_PTR gdip_token;
    Gdiplus::GdiplusStartupInput  gdipsi;
    Gdiplus::GdiplusStartup (&gdip_token, &gdipsi, nullptr);

    // Perform application initialization:
    if (!InitInstance (hInstance, nCmdShow))
    {
        return FALSE;
    }

    HACCEL hAccelTable = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDC_PAINTWIN10COLORS));

    MSG msg;

    // Main message loop:
    while (GetMessage(&msg, nullptr, 0, 0))
    {
        if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    Gdiplus::GdiplusShutdown (gdip_token);

    return (int) msg.wParam;
}



//
//  FUNCTION: MyRegisterClass()
//
//  PURPOSE: Registers the window class.
//
ATOM MyRegisterClass(HINSTANCE hInstance)
{
    WNDCLASSEXW wcex;

    wcex.cbSize = sizeof(WNDCLASSEX);

    wcex.style          = CS_HREDRAW | CS_VREDRAW;
    wcex.lpfnWndProc    = WndProc;
    wcex.cbClsExtra     = 0;
    wcex.cbWndExtra     = 0;
    wcex.hInstance      = hInstance;
    wcex.hIcon          = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_PAINTWIN10COLORS));
    wcex.hCursor        = LoadCursor(nullptr, IDC_ARROW);
    wcex.hbrBackground  = (HBRUSH)(COLOR_WINDOW+1);
    wcex.lpszMenuName   = MAKEINTRESOURCEW(IDC_PAINTWIN10COLORS);
    wcex.lpszClassName  = szWindowClass;
    wcex.hIconSm        = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_SMALL));

    return RegisterClassExW(&wcex);
}

//
//   FUNCTION: InitInstance(HINSTANCE, int)
//
//   PURPOSE: Saves instance handle and creates main window
//
//   COMMENTS:
//
//        In this function, we save the instance handle in a global variable and
//        create and display the main program window.
//
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
   hInst = hInstance; // Store instance handle in our global variable

   HWND hWnd = CreateWindowW(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW,
      CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, nullptr, nullptr, hInstance, nullptr);

   if (!hWnd)
   {
      return FALSE;
   }

   CoInitializeEx (nullptr, COINIT_APARTMENTTHREADED);
   UpdateWindows10Colors ();

   ShowWindow(hWnd, nCmdShow);
   UpdateWindow(hWnd);

   return TRUE;
}

static Gdiplus::Color RGBAtoGdiplus (DWORD c)
{
    return Gdiplus::Color ((c >> 24) & 0xff, GetRValue (c), GetGValue (c), GetBValue (c));
}

static void DrawFramedRect (Gdiplus::Graphics& g, const Gdiplus::Rect& r, Gdiplus::Pen* pen, Gdiplus::Brush* fill)
{
    g.DrawRectangle (pen, r);
    Gdiplus::Rect inner (r);
    inner.Inflate (-1, -1);
    inner.Width++;
    inner.Height++;
    g.FillRectangle (fill, inner);
}

static RECT PaintAccentColors (HDC dc, int x, int y)
{
    if (!accents_valid)
    {
        return RECT{ x, y, x+1, y+1 };
    }

    using namespace Gdiplus;

    static const int blockWidth = 24;
    static const int blockHeight = 24;
    static const int blockSpacing = 12;

    Graphics g (dc);
    Pen framepen (Color (128, 128, 128));
    
    Rect r (x, y, blockWidth, blockHeight);
    {
        SolidBrush fill (RGBAtoGdiplus (accents.lightest));
        DrawFramedRect (g, r, &framepen, &fill);
    }
    r.Offset (0, blockHeight + blockSpacing);
    {
        SolidBrush fill (RGBAtoGdiplus (accents.lighter));
        DrawFramedRect (g, r, &framepen, &fill);
    }
    r.Offset (0, blockHeight + blockSpacing);
    {
        SolidBrush fill (RGBAtoGdiplus (accents.light));
        DrawFramedRect (g, r, &framepen, &fill);
    }
    r.Offset (0, blockHeight + blockSpacing);
    {
        SolidBrush fill (RGBAtoGdiplus (accents.accent));
        DrawFramedRect (g, r, &framepen, &fill);
    }
    r.Offset (0, blockHeight + blockSpacing);
    {
        SolidBrush fill (RGBAtoGdiplus (accents.dark));
        DrawFramedRect (g, r, &framepen, &fill);
    }
    r.Offset (0, blockHeight + blockSpacing);
    {
        SolidBrush fill (RGBAtoGdiplus (accents.darker));
        DrawFramedRect (g, r, &framepen, &fill);
    }
    r.Offset (0, blockHeight + blockSpacing);
    {
        SolidBrush fill (RGBAtoGdiplus (accents.darkest));
        DrawFramedRect (g, r, &framepen, &fill);
    }

    return RECT{ x, y, x + blockWidth - 1, y + blockHeight * 7 + blockSpacing * 6 - 1 };
}

static RECT PaintMockWindow (HDC dc, int x, int y,
                             const wchar_t* caption,
                             DWORD captionBG, DWORD captionText, DWORD frame,
                             DWORD fill = 0)
{
    using namespace Gdiplus;

    static const int width = 200;
    static const int height = 200;
    static const int captionHeight = 24;
    static const int blurInset = 8;
    static const int blurRadius = 20;

    Bitmap dropShadow (width + 2 * blurRadius, height + 2 * blurRadius, PixelFormat32bppARGB);
    {
        std::unique_ptr<Graphics> dropShadowGraphics (Graphics::FromImage (&dropShadow));
        Color shadowColor;
        shadowColor.SetFromCOLORREF (GetSysColor (COLOR_WINDOWTEXT));
        SolidBrush brush (shadowColor);
        Rect solidRect (blurRadius + blurInset, blurRadius + blurInset, width - 2*blurInset, height - 2*blurInset);
        dropShadowGraphics->FillRectangle (&brush, solidRect);
    }
    {
        BlurParams blurParams = { blurRadius, false };
        Blur blur;
        blur.SetParameters (&blurParams);
        dropShadow.ApplyEffect (&blur, nullptr);
    }

    Graphics g (dc);
    g.DrawImage (&dropShadow, x, y);
    {
        Rect frameRect = { x + blurRadius, y + blurRadius, width, height };
        Color windowColor;
        if (fill != 0)
            windowColor = RGBAtoGdiplus (fill);
        else
            windowColor.SetFromCOLORREF (GetSysColor (COLOR_WINDOW));
        SolidBrush fillBrush (windowColor);
        g.FillRectangle (&fillBrush, frameRect);
        Pen pen (RGBAtoGdiplus (frame));
        g.DrawRectangle (&pen, frameRect);
    }

    SolidBrush captionBrush (RGBAtoGdiplus (captionBG));
    Rect captionRect (x + blurRadius + 1, y + blurRadius + 1, width - 2, captionHeight);
    g.FillRectangle (&captionBrush, captionRect.X, captionRect.Y, captionRect.Width+1, captionRect.Height+1);

    NONCLIENTMETRICS ncm = { sizeof (NONCLIENTMETRICS) };
    SystemParametersInfo (SPI_GETNONCLIENTMETRICS, sizeof(NONCLIENTMETRICS), &ncm, 0);
    Font captionFont (dc, &ncm.lfCaptionFont);
    RectF captionRect_f (captionRect.X, captionRect.Y, captionRect.Width, captionRect.Height);
    StringFormat stringFmt;
    stringFmt.SetAlignment (StringAlignmentNear);
    stringFmt.SetLineAlignment (StringAlignmentCenter);
    SolidBrush textBrush (RGBAtoGdiplus (captionText));
    g.DrawString (caption, -1, &captionFont, captionRect_f, &stringFmt, &textBrush);

    return RECT{ x, y, x + width + 2*blurRadius - 1, y + height + 2*blurRadius - 1 };
}

static void PaintContents (HDC dc, const RECT& r)
{
    RECT accentsRect = PaintAccentColors (dc, r.left + 16, r.top + 16);

    RECT activeRect = PaintMockWindow (dc, accentsRect.right + 16, accentsRect.top, L"Active caption",
                                       colors.activeCaptionBG, colors.activeCaptionText, colors.activeFrame);
    PaintMockWindow (dc, activeRect.right + 16, activeRect.top, L"Inactive caption",
                     colors.inactiveCaptionBG, colors.inactiveCaptionText, colors.inactiveFrame);
    PaintMockWindow (dc, activeRect.left, activeRect.bottom + 16, L"Active caption (glass)",
                     colorsGlass.activeCaptionBG, colorsGlass.activeCaptionText, colorsGlass.activeFrame,
                     colorsGlass.activeCaptionBG);
    PaintMockWindow (dc, activeRect.right + 16, activeRect.bottom + 16, L"Inactive caption (glass)",
                     colorsGlass.inactiveCaptionBG, colorsGlass.inactiveCaptionText, colorsGlass.inactiveFrame,
                     colorsGlass.inactiveCaptionBG);
}

//
//  FUNCTION: WndProc(HWND, UINT, WPARAM, LPARAM)
//
//  PURPOSE:  Processes messages for the main window.
//
//  WM_COMMAND  - process the application menu
//  WM_PAINT    - Paint the main window
//  WM_DESTROY  - post a quit message and return
//
//
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
    case WM_COMMAND:
        {
            int wmId = LOWORD(wParam);
            // Parse the menu selections:
            switch (wmId)
            {
            case IDM_ABOUT:
                DialogBox(hInst, MAKEINTRESOURCE(IDD_ABOUTBOX), hWnd, About);
                break;
            case IDM_EXIT:
                DestroyWindow(hWnd);
                break;
            default:
                return DefWindowProc(hWnd, message, wParam, lParam);
            }
        }
        break;
    case WM_PAINT:
        {
            RECT cr;
            GetClientRect (hWnd, &cr);
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hWnd, &ps);
            PaintContents (hdc, cr);
            EndPaint(hWnd, &ps);
        }
        break;
    case WM_DESTROY:
        PostQuitMessage(0);
        break;
    case WM_SETTINGCHANGE:
        UpdateWindows10Colors ();
        InvalidateRect (hWnd, nullptr, true);
        return DefWindowProc(hWnd, message, wParam, lParam);
    default:
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}

// Message handler for about box.
INT_PTR CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    UNREFERENCED_PARAMETER(lParam);
    switch (message)
    {
    case WM_INITDIALOG:
        return (INT_PTR)TRUE;

    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
        {
            EndDialog(hDlg, LOWORD(wParam));
            return (INT_PTR)TRUE;
        }
        break;
    }
    return (INT_PTR)FALSE;
}
