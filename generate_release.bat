@echo off
setlocal enabledelayedexpansion

set "RAW_VERSION=%~1"
if "%RAW_VERSION%"=="" set "RAW_VERSION=0.0.0"

echo %RAW_VERSION%| findstr /b "v" >nul 2>&1
if %errorlevel%==0 (
    set "VERSION=%RAW_VERSION%"
) else (
    set "VERSION=v%RAW_VERSION%"
)

set "ROOT_DIR=%~dp0"
rem Remove trailing backslash
if "%ROOT_DIR:~-1%"=="\" set "ROOT_DIR=%ROOT_DIR:~0,-1%"

set "RELEASE_DIR=%ROOT_DIR%\release-%VERSION%"
set "SRC_DIR=%RELEASE_DIR%\src"
set "ZIP_FILE=%RELEASE_DIR%\ShillenSilent-%VERSION%.zip"
set "SOURCE_ROOT=%ROOT_DIR%\src"

set "SCRIPT_FILE=%SOURCE_ROOT%\ShillenSilent.lua"
set "CORE_DIR=%SOURCE_ROOT%\ShillenSilent_core"
set "README_FILE=%ROOT_DIR%\README.md"

if exist "%RELEASE_DIR%" (
    echo Error: release directory already exists: %RELEASE_DIR% >&2
    exit /b 1
)

if not exist "%SOURCE_ROOT%\" (
    echo Error: missing source root directory: %SOURCE_ROOT% >&2
    exit /b 1
)

if not exist "%SCRIPT_FILE%" (
    echo Error: missing script file: %SCRIPT_FILE% >&2
    exit /b 1
)

if not exist "%CORE_DIR%\" (
    echo Error: missing core directory: %CORE_DIR% >&2
    exit /b 1
)

if not exist "%README_FILE%" (
    echo Error: missing README file: %README_FILE% >&2
    exit /b 1
)

where tar >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: required command not found: tar >&2
    exit /b 1
)

mkdir "%SRC_DIR%"
copy "%SCRIPT_FILE%" "%SRC_DIR%\" >nul
xcopy "%CORE_DIR%" "%SRC_DIR%\ShillenSilent_core\" /e /i /q >nul
copy "%README_FILE%" "%RELEASE_DIR%\" >nul

pushd "%RELEASE_DIR%"
tar -a -cf "ShillenSilent-%VERSION%.zip" "src" "README.md"
popd

echo Release created at: %RELEASE_DIR%
echo Release zip created at: %ZIP_FILE%

endlocal
