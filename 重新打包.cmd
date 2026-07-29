@echo off
title Rebuild GeminiAntigravitytools

echo ============================================
echo   Rebuild GeminiAntigravitytools.exe
echo ============================================
echo.

set "PYTHON=%USERPROFILE%\.workbuddy\binaries\python\versions\3.13.12\python.exe"
set "TARGET=%~dp0GeminiAntigravitytools.exe"

REM Auto-find .spec file (avoid hardcoding Chinese filename)
set "SPEC="
for %%f in ("%~dp0*.spec") do set "SPEC=%%f"

if not defined SPEC (
    echo [X] No .spec file found in: %~dp0
    pause
    exit /b 1
)

if not exist "%PYTHON%" (
    echo [X] Python not found: %PYTHON%
    pause
    exit /b 1
)

echo [1/3] Cleaning old build cache...
if exist "%~dp0build" rd /s /q "%~dp0build" >nul 2>&1
if exist "%~dp0dist"  rd /s /q "%~dp0dist" >nul 2>&1
echo [v] Cache cleaned.

echo.
echo [2/3] Compiling (please wait 1-2 minutes)...
echo     Spec: %SPEC%
"%PYTHON%" -m PyInstaller "%SPEC%" --clean --noconfirm

REM Auto-find built exe in dist folder
set "BUILT_EXE="
for %%f in ("%~dp0dist\*.exe") do set "BUILT_EXE=%%f"

if not defined BUILT_EXE (
    echo [X] Build failed! Check error messages above.
    pause
    exit /b 1
)

echo.
echo [3/3] Copying to target...
echo     Source: %BUILT_EXE%
echo     Target: %TARGET%
copy /Y "%BUILT_EXE%" "%TARGET%" >nul 2>&1

echo.
echo ============================================
echo  [v] Build complete!
echo  You can now run GeminiAntigravitytools.exe
echo ============================================
echo.
pause
exit /b 0
