@echo off
cd /d %~dp0build\web

set PORT=3000

:check_port
set "OCCUPIED="
set "PID="

:: Find if the port is in use and get the PID
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :%PORT% ^| findstr LISTENING') do (
    set "OCCUPIED=1"
    set "PID=%%a"
)

if defined OCCUPIED (
    :: Check if the process name is node.exe
    tasklist /fi "pid eq %PID%" /nh | findstr /i "node.exe" >nul
    if not errorlevel 1 (
        :: Check if the process command line contains "Platforme" to verify it's our project
        powershell -NoProfile -Command "(Get-CimInstance Win32_Process -Filter 'ProcessId = %PID%').CommandLine" 2>nul | findstr /i "Platforme" >nul
        if not errorlevel 1 (
            echo Platform is already running on port %PORT%.
            start http://localhost:%PORT%
            exit /b 0
        ) else (
            :: Node.exe belongs to another project/application, try next port
            set /a PORT+=1
            goto check_port
        )
    ) else (
        :: Port occupied by another application, try next port
        set /a PORT+=1
        goto check_port
    )
)

echo Starting server on port %PORT%...
:: Wait 2 seconds asynchronously in the background before opening the browser
start /b cmd /c "timeout /t 2 >nul && start http://localhost:%PORT%"
npx serve -l %PORT% "%CD%"