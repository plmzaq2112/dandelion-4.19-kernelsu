@echo off
rem Flash a KernelSU boot image on Redmi 9A (dandelion, MT6765).
rem Requirements: adb + fastboot on PATH, unlocked bootloader.
rem Usage: flash.bat <boot.img>   (fastboot mode)
rem Verify after boot: adb shell uname -r  ->  4.19.325-dandelion-ksu
setlocal
set "IMG=%~1"
if "%IMG%"=="" set "IMG=%~dp0boot-4.19.325-dandelion-ksu.img"
if not exist "%IMG%" (
    echo ERROR: image not found: %IMG%
    exit /b 1
)

echo == reboot to bootloader ==
adb reboot bootloader
echo waiting for fastboot device...
:wait
timeout /t 1 /nobreak >nul
fastboot devices | findstr "." >nul
if errorlevel 1 goto wait

echo == flash boot ==
fastboot flash boot "%IMG%" || goto :err
fastboot reboot
echo.
echo After boot verify: adb shell uname -r   (expect 4.19.325-dandelion-ksu)
echo Rollback if needed: fastboot flash boot ^<stock boot.img^>
goto :eof
:err
echo FAILED - check device / image path.
exit /b 1
