@echo off
setlocal

:: Get the current day of the week (1=Monday, 7=Sunday) using PowerShell
for /f %%a in ('powershell -command "Get-Date -Format dddd"') do set dayOfWeek=%%a

:: Define the wallpaper path
set "wallpaperDir=C:\Users\a\Pictures\schedule"
set wallpaperFiles=sunday.png monday.png tuesday.png wednesday.png thursday.png friday.png saturday.png

:: Convert the day of the week to lowercase for matching
set dayOfWeek=%dayOfWeek:~0,3%

:: Set the wallpaper file based on the day of the week
if /i "%dayOfWeek%"=="mon" set wallpaperFile=monday.png
if /i "%dayOfWeek%"=="tue" set wallpaperFile=tuesday.png
if /i "%dayOfWeek%"=="wed" set wallpaperFile=wednesday.png
if /i "%dayOfWeek%"=="thu" set wallpaperFile=thursday.png
if /i "%dayOfWeek%"=="fri" set wallpaperFile=friday.png
if /i "%dayOfWeek%"=="sat" set wallpaperFile=saturday.png
if /i "%dayOfWeek%"=="sun" set wallpaperFile=sunday.png

:: Set the wallpaper
set "wallpaperPath=%wallpaperDir%\%wallpaperFile%"
reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%wallpaperPath%" /f
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters

:: Optional: Display a message
echo Wallpaper set to: %wallpaperPath%

endlocal
