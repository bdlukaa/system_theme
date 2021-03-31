# Windows10Colors
Helper functions + example to get Windows 10 accent and window frame colors.

These colors are useful when you want to implement your own window caption or window frame painting logic.

## Motivation
Although Windows provides APIs to support custom window caption painting they sometimes don't work right
on Windows 10: e.g. `DrawThemeTextEx()` doesn't use the right text color for some title bar colors.

In other cases you maybe just want to colorize something according with the user-chosen accent color.

In previous versions there was no public API to obtain the accent color, only undocumented interfaces
(see e.g. https://www.quppa.net/blog/2013/01/02/retrieving-windows-8-theme-colours/).
Windows 10 does provide a public API to get the accent color, but it's only accessible through a WinRT
class, which needs quite some boilerplate if you're using vanilla C++.

However, some colors are *still* not accessible via a public API and have to be computed manually (e.g.
window caption text color).

## Usage
To use the `Windows10Colors` functions copy the source files into your project.

### Requirements
* Build time: Requires Windows 10 SDK.
  You can use the Windows 8.1 SDK, but you'll not be able to get the actual accent color on Windows 10
  systems.
* Run time: The real accent color can only be obtained on Windows 10.
  On older Windows versions (7, 8, 8.1) the "accent color" will be derived from the
  user-configured title bar color.
  If you don't want this behaviour you should choose different code paths or colors on earlier versions.
* Compiler: So far only tested with Visual Studio 2015 and above.

## Implementation Details
Uses a WinRT API (`Windows.UI.ViewManagement.UISettings3`) to obtain the accent color. However, since
not all information can be obtained via APIs (or I haven't found the way yet), some is obtained by
reading registry keys (e.g. whether the title bar is colored or white). Other values are derived from
previously obtained colors (e.g. window caption bar text color depends on window caption bar background),
or at least close matches are provided.
