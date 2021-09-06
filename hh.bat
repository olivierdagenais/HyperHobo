@echo off

REM See https://stackoverflow.com/a/11995662/98903 for how this works...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: HyperHobo _must_ be run elevated, because that's how the Hyper-V PowerShell modules work.
    echo Please run CMD or PowerShell as an administrator and try again.
    exit /b 1
)

PowerShell -ExecutionPolicy Unrestricted -File HyperHobo.ps1 %*
