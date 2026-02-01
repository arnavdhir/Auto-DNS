@echo off
setlocal EnableDelayedExpansion

:: DNS Optimizer Debug Version - To diagnose network adapter detection issue

title DNS Optimizer - Debug Version

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
echo    DNS Optimizer - Debug Version
echo ========================================
echo.
echo This script will help diagnose why the network adapter isn't being detected.
echo.
echo NOTE: This script requires administrative privileges.
echo.

:: Show all network adapters first
echo Listing all network adapters:
echo.
powershell -command "Get-NetAdapter | Select-Object Name, InterfaceDescription, Status | Format-Table -AutoSize"
echo.

:: Show only active adapters
echo Listing active network adapters:
echo.
powershell -command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Select-Object Name, InterfaceDescription, Status | Format-Table -AutoSize"
echo.

:: Try to detect active adapter with different criteria
echo Attempting to detect active network adapter (method 1)...
for /f "tokens=*" %%a in ('powershell -command "Get-NetAdapter ^| Where-Object {$_.Status -eq 'Up'} ^| Select-Object -ExpandProperty Name" 2^>nul') do (
    set "adapter=%%a"
    echo Found adapter: %%a
    goto :adapter_found
)

:adapter_found
if not defined adapter (
    echo.
    echo Method 1 failed. Trying alternative method...
    echo.
    
    :: Alternative method - try different property
    for /f "tokens=*" %%b in ('powershell -command "Get-NetAdapter ^| Where-Object {$_.Status -eq 'Up' -and $_.InterfaceDescription -notmatch 'Loopback'} ^| Select-Object -ExpandProperty Name" 2^>nul') do (
        set "adapter=%%b"
        echo Found adapter: %%b
        goto :adapter_found_alt
    )
    
    :adapter_found_alt
    if not defined adapter (
        echo.
        echo Alternative method also failed.
        echo.
        echo Manual detection required:
        echo Please run this command in PowerShell as Administrator to see your adapter names:
        echo.
        echo Get-NetAdapter ^| Where-Object {$_.Status -eq 'Up'} ^| Select-Object Name
        echo.
        echo Then manually edit the batch file to use your actual adapter name.
        pause
        exit /b 1
    ) else (
        echo Using adapter: !adapter!
    )
) else (
    echo Using adapter: !adapter!
)

echo.
echo Active adapter detected: !adapter!
echo.
echo The original script should work with this adapter name.
echo Press any key to continue with normal operation...
pause

:: Continue with normal operation
echo.
echo Continuing with DNS testing...

:: Backup current DNS settings
echo Backing up current DNS settings...
powershell -command "Get-DnsClientServerAddress -InterfaceAlias '!adapter!' -AddressFamily IPv4 ^| Select-Object -ExpandProperty ServerAddresses" > "%TEMP%\dns_backup.txt" 2>nul
if !errorlevel! equ 0 (
    echo Backup saved to %TEMP%\dns_backup.txt
) else (
    echo Warning: Could not create DNS backup
)

:: Define DNS servers to test
set "dns_servers=8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1 9.9.9.9 149.112.112.112"

:: Get user's current ISP DNS
for /f "tokens=*" %%a in ('powershell -command "Get-DnsClientServerAddress -InterfaceAlias '!adapter!' -AddressFamily IPv4 ^| Select-Object -ExpandProperty ServerAddresses" 2^>nul') do (
    set "current_dns=%%a"
    if not "!current_dns!"=="dhcp" (
        if defined current_dns (
            set "dns_servers=!dns_servers! !current_dns!"
        )
    )
)

:: Domains to test for more accurate results
set "domains=www.google.com www.microsoft.com"

echo.
echo Testing DNS resolution speed for the following servers:
echo !dns_servers!
echo.

:: Initialize variables
set "fastest_time=999999"
set "fastest_server="
set "results="

:: Test each DNS server
for %%s in (!dns_servers!) do (
    echo Testing DNS server %%s...
    set "total_time=0"
    set "success_count=0"
    set "attempt_count=0"
    
    :: Test multiple domains for more accurate results
    for %%d in (!domains!) do (
        set /a attempt_count+=1
        echo.  Testing %%d...
        
        :: Measure DNS resolution time using PowerShell
        for /f "tokens=*" %%t in ('powershell -command "try { $result = Measure-Command {Resolve-DnsName '%%d' -Server %%s -QuickTimeout -ErrorAction Stop}; [math]::Round($result.TotalMilliseconds) } catch { '0' }" 2^>nul') do (
            set "time=%%t"
            set "time=!time: =!"
            
            :: Check if the command returned a valid positive number
            if defined time (
                for /f "delims=0123456789." %%i in ("!time!") do (
                    set "isNumeric=0"
                    goto :after_numeric_check
                )
                set "isNumeric=1"
                :after_numeric_check
                
                if !isNumeric! equ 1 (
                    if !time! gtr 0 (
                        if !time! lss 5000 (  :: Ignore extremely high values that might be errors
                            set /a total_time=!total_time! + !time!
                            set /a success_count+=1
                        )
                    )
                )
            )
        )
        timeout /t 1 /nobreak >nul
    )
    
    :: Calculate average response time for this server
    if !success_count! gtr 0 (
        if !success_count! gtr 0 (
            set /a avg_time=!total_time! / !success_count!
            echo Server %%s average response: !avg_time! ms (!success_count!/!attempt_count! successful)
            set "results=!results! %%s:!avg_time!ms(!success_count!/!attempt_count!)"
            
            :: Check if this is the fastest average time so far
            if !avg_time! lss !fastest_time! (
                set "fastest_time=!avg_time!"
                set "fastest_server=%%s"
            )
        )
    ) else (
        echo Server %%s had no successful responses
        set "results=!results! %%s:Failed(0/!attempt_count!)"
    )
)

echo.
echo Test Results:
echo !results!
echo.

:: Check if we found a fastest server
if not defined fastest_server (
    echo Error: None of the DNS servers responded successfully. Please check your internet connection.
    echo Restoring original DNS settings...
    powershell -command "Set-DnsClientServerAddress -InterfaceAlias '!adapter!' -ResetServerAddresses" 2>nul
    if !errorlevel! equ 0 (
        echo Original DNS settings restored.
    ) else (
        echo Failed to restore original DNS settings automatically.
        echo You may need to manually restore using: netsh interface ip set dns "!adapter!" dhcp
    )
    pause
    exit /b 1
)

echo Fastest DNS server found: !fastest_server! (!fastest_time! ms average)
echo.

:: Ask for confirmation before updating DNS settings
set /p confirm="Do you want to update your DNS settings to use !fastest_server! as primary DNS? (Y/N): "
if /i not "!confirm!"=="Y" (
    echo DNS settings update cancelled.
    echo Original DNS settings preserved.
    pause
    exit /b 0
)

:: Update DNS settings using PowerShell (primary method)
echo Updating DNS settings for adapter "!adapter!"...
powershell -command "Set-DnsClientServerAddress -InterfaceAlias '!adapter!' -ServerAddresses '!fastest_server!'" 2>nul

:: Check if PowerShell method succeeded
if !errorlevel! neq 0 (
    echo PowerShell method failed, trying netsh as fallback...
    netsh interface ip set dns "!adapter!" static !fastest_server! primary >nul 2>&1
    if !errorlevel! neq 0 (
        echo Both methods failed to update DNS settings.
        echo Please check your network adapter name and permissions.
        pause
        exit /b 1
    )
)

:: Flush DNS cache to ensure changes take effect immediately
echo Flushing DNS cache...
ipconfig /flushdns >nul 2>&1

:: Verify the change with multiple attempts
echo Verifying DNS settings update...
set "verification_attempts=0"
set "max_verification_attempts=3"
set "verified=false"

:verify_loop
set /a verification_attempts+=1
for /f "tokens=*" %%a in ('powershell -command "Get-DnsClientServerAddress -InterfaceAlias '!adapter!' -AddressFamily IPv4 ^| Select-Object -ExpandProperty ServerAddresses" 2^>nul') do (
    set "new_dns=%%a"
)

if "!new_dns!"=="!fastest_server!" (
    set "verified=true"
    goto :verification_complete
)

if !verification_attempts! lss !max_verification_attempts! (
    echo Attempt !verification_attempts! of !max_verification_attempts!: DNS settings not yet verified, waiting 3 seconds...
    timeout /t 3 /nobreak >nul
    goto :verify_loop
)

:verification_complete
if "!verified!"=="true" (
    echo.
    echo Success! DNS settings updated successfully.
    echo New DNS server: !new_dns!
    echo Average response time: !fastest_time! ms
    echo.
    echo Your internet connection should now use the faster DNS server.
    echo Running connectivity test...
    ping -n 2 www.google.com >nul 2>&1
    if !errorlevel! equ 0 (
        echo Connectivity test: OK
    ) else (
        echo Connectivity test: May need a moment to take full effect
    )
) else (
    echo.
    echo Warning: DNS settings may not have updated correctly.
    echo Current DNS server: !new_dns!
    echo Expected DNS server: !fastest_server!
    echo.
    echo Please restart your computer to ensure changes take effect.
)

echo.
echo To restore original DNS settings, you can:
echo 1. Use the backup file at %TEMP%\dns_backup.txt
echo 2. Or run this command in an elevated command prompt:
echo    netsh interface ip set dns "!adapter!" dhcp
echo.

echo.
echo Press any key to exit...
pause >nul