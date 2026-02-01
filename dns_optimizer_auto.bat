@echo off
setlocal EnableDelayedExpansion

:: Simple Automatic DNS Speed Tester - Finds and sets the fastest DNS server
:: Uses basic connectivity testing instead of complex timing

title Simple Automatic DNS Speed Tester

:: Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: This script requires administrative privileges.
    echo Please run as Administrator.
    pause
    exit /b 1
)

echo.
echo ========================================
echo    Simple Automatic DNS Speed Tester
echo ========================================
echo.
echo This script will test popular DNS servers and set the fastest one.
echo.

:: Detect active network adapter using netsh
for /f "tokens=3*" %%a in ('netsh interface show interface ^| findstr /R "^Enabled"') do (
    set "adapter=%%b"
    goto :adapter_found
)

:adapter_found
if not defined adapter (
    echo Error: Could not detect an active network adapter.
    echo Please manually specify your active network adapter name below.
    echo Available adapters:
    netsh interface show interface
    echo.
    set /p adapter="Enter your active network adapter name: "
    if "!adapter!"=="" (
        echo No adapter name provided.
        pause
        exit /b 1
    )
)

echo Active adapter detected: !adapter!

:: Show current DNS settings
echo.
echo Current DNS settings for !adapter!:
netsh interface ip show dns !adapter!

:: Define DNS servers to test
set dns_servers=8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 9.9.9.9 149.112.112.112 208.67.222.222 208.67.220.220

:: Test domains
set domains_to_test=www.google.com www.amazon.com www.github.com

echo.
echo Testing DNS servers: !dns_servers!
echo.

:: Initialize variables
set "fastest_server="
set "best_score=0"

:: Test each DNS server
for %%s in (!dns_servers!) do (
    echo Testing DNS server %%s...
    set "success_count=0"
    
    :: Test each domain with this DNS server
    for %%d in (!domains_to_test!) do (
        echo   Testing %%d via %%s...
        
        :: Use nslookup to test DNS resolution
        nslookup -timeout=5 %%d %%s >nul 2>&1
        if !errorlevel! equ 0 (
            set /a success_count+=1
            echo     Resolved successfully
        ) else (
            echo     Failed to resolve
        )
        
        timeout /t 1 /nobreak >nul
    )
    
    echo   Total successful resolutions: !success_count!/3
    echo.
    
    :: Check if this server had the most successes
    if !success_count! gtr !best_score! (
        set best_score=!success_count!
        set fastest_server=%%s
    )
)

echo.
if defined fastest_server (
    echo Best performing DNS server: !fastest_server! (!best_score!/3 successful resolutions)
    
    :: Ask for confirmation before updating DNS settings
    set /p confirm="Do you want to update your DNS settings to use !fastest_server!? (Y/N): "
    if /i "!confirm!"=="Y" (
        echo.
        echo Setting DNS server to !fastest_server!...
        netsh interface ip set dns "!adapter!" static !fastest_server! primary >nul
        if !errorlevel! equ 0 (
            echo.
            echo Success! DNS settings updated to !fastest_server!
            echo.
            
            echo Flushing DNS cache...
            ipconfig /flushdns >nul 2>&1
            
            echo.
            echo New DNS settings:
            netsh interface ip show dns "!adapter!"
        ) else (
            echo Error: Failed to update DNS settings.
        )
    ) else (
        echo DNS settings update cancelled.
    )
) else (
    echo Error: None of the DNS servers responded successfully. Please check your internet connection.
)

echo.
echo To restore automatic DNS settings, run:
echo netsh interface ip set dns "!adapter!" dhcp
echo.

echo Press any key to exit...
pause >nul