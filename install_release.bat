@echo off
setlocal EnableExtensions

set "SOURCE_DIR=%~dp0"
if "%SOURCE_DIR:~-1%"=="\" set "SOURCE_DIR=%SOURCE_DIR:~0,-1%"

set "DEST_DIR=%USERPROFILE%\Lexis\Grand Theft Auto V\scripts"
set "SRC_SCRIPT=%SOURCE_DIR%\ShillenSilent.lua"
set "SRC_CORE=%SOURCE_DIR%\ShillenSilent_core"

if not exist "%SRC_SCRIPT%" (
  echo Error: Missing source script: "%SRC_SCRIPT%"
  exit /b 1
)

if not exist "%SRC_CORE%\NUL" (
  echo Error: Missing source folder: "%SRC_CORE%"
  exit /b 1
)

if not exist "%DEST_DIR%\NUL" (
  mkdir "%DEST_DIR%" >nul 2>&1
  if errorlevel 1 (
    echo Error: Could not create destination folder: "%DEST_DIR%"
    exit /b 1
  )
)

copy /Y "%SRC_SCRIPT%" "%DEST_DIR%\ShillenSilent.lua" >nul
if errorlevel 1 (
  echo Error: Failed to copy script to "%DEST_DIR%"
  exit /b 1
)

robocopy "%SRC_CORE%" "%DEST_DIR%\ShillenSilent_core" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NC /NS /NP >nul
set "ROBO_EXIT=%ERRORLEVEL%"
if %ROBO_EXIT% GEQ 8 (
  echo Error: Failed to copy "ShillenSilent_core" to "%DEST_DIR%\ShillenSilent_core"
  exit /b %ROBO_EXIT%
)

echo Install complete.
echo Copied:
echo   - "%DEST_DIR%\ShillenSilent.lua"
echo   - "%DEST_DIR%\ShillenSilent_core"
exit /b 0
