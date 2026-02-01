# Auto-DNS Project Documentation

## Project Overview

Auto-DNS is a Windows batch script project that automatically tests DNS resolution speed for popular DNS providers and configures your network adapter to use the fastest one. The project consists of a main batch file (`dns_optimizer.bat`) and documentation (`README.md`).

The script addresses the common need to optimize internet browsing speed by selecting the fastest DNS server available to the user. It tests multiple DNS providers including Google, Cloudflare, Quad9, and the user's current ISP DNS to determine which provides the best response times.

## Features

- Tests DNS resolution speed for popular DNS providers (Google, Cloudflare, Quad9) and your current ISP DNS
- Measures response times using PowerShell's `Resolve-DnsName` with `-QuickTimeout` and `Measure-Command`
- Uses multi-domain testing (5 domains) with multiple attempts per domain for more accurate results
- Identifies the fastest DNS server based on average response time and success rate
- Updates your Wi-Fi or Ethernet adapter DNS settings using PowerShell with netsh fallback
- Includes comprehensive error handling and user feedback
- Creates a backup of your original DNS settings
- Flushes DNS cache after changes to ensure immediate effect
- Verifies changes with multiple attempts to confirm successful update

## Supported DNS Providers

The script tests the following DNS providers:
- **Google DNS**: 8.8.8.8, 8.8.4.4
- **Cloudflare DNS**: 1.1.1.1, 1.0.0.1
- **Quad9 DNS**: 9.9.9.9, 149.112.112.112
- **Your ISP's DNS**: Automatically detected and included in tests

## Prerequisites

- Windows 8 or later (PowerShell 4.0+ required)
- Administrative privileges (script must be run as Administrator)

## How to Use

1. Download the `dns_optimizer.bat` file
2. Right-click on the file and select "Run as administrator"
3. The script will automatically detect your active network adapter
4. It will test DNS resolution speed for all configured DNS servers across multiple domains
5. After identifying the fastest DNS server, it will ask for confirmation before updating your settings
6. If confirmed, it will update your DNS settings, flush the DNS cache, and verify the change
7. A connectivity test will be performed to ensure everything is working properly

## Technical Implementation

The script uses a combination of batch commands and PowerShell to achieve its functionality:

1. **Adapter Detection**: Uses PowerShell's `Get-NetAdapter` to find active network adapters
2. **DNS Testing**: Uses PowerShell's `Resolve-DnsName` with `Measure-Command` to measure response times
3. **DNS Update**: Uses PowerShell's `Set-DnsClientServerAddress` with netsh fallback
4. **Verification**: Checks that DNS settings were updated successfully

The script handles complex PowerShell commands by creating temporary PowerShell script files, executing them, and reading the results from temporary text files to avoid escaping issues.

## Building and Running

The project is a standalone batch file that doesn't require compilation. Simply run the `dns_optimizer.bat` file as Administrator.

## Development Conventions

- The script uses delayed variable expansion (`EnableDelayedExpansion`) for proper variable handling in loops
- PowerShell commands are executed through temporary script files to avoid escaping issues
- Comprehensive error handling is implemented throughout the script
- The script creates backups of original DNS settings before making changes
- Multiple verification attempts are made to ensure changes take effect

## Files

- `dns_optimizer.bat`: The main DNS optimizer script
- `README.md`: Documentation for the project
- `dns_debug.bat`: Debug version of the script for troubleshooting adapter detection issues

## Troubleshooting

### Common Issues

- **Script won't run**: Make sure you're running as Administrator
- **No adapters detected**: Ensure you have an active network connection
- **DNS update failed**: Check that your network adapter supports DNS updates
- **High response times**: Network conditions or temporary server issues may affect results

### Restoring Original DNS Settings

If you need to restore your original DNS settings, you can:

1. Look for the backup file at `%TEMP%\dns_backup.txt`
2. Manually configure your DNS settings through Windows Network Settings
3. Use the Windows command: `netsh interface ip set dns "Your Adapter Name" dhcp`
4. Restart your computer to ensure all changes take effect