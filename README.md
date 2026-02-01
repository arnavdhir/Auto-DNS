# DNS Optimizer

A Windows batch script that automatically tests DNS resolution speed for popular DNS providers and configures your network adapter to use the fastest one.

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

1. Download the `dns_optimizer_auto.bat` file
3. Right-click on the file and select "Run as administrator"
4. The script will automatically detect your active network adapter
5. It will test DNS resolution speed for all configured DNS servers across multiple domains
6. After identifying the fastest DNS server, it will ask for confirmation before updating your settings
7. If confirmed, it will update your DNS settings, flush the DNS cache, and verify the change
8. A connectivity test will be performed to ensure everything is working properly

## What the Script Does

1. **Detects Network Adapter**: Finds your active Wi-Fi or Ethernet adapter
2. **Tests DNS Speed**: Uses PowerShell to measure response times for each DNS server across multiple domains (www.google.com, www.microsoft.com, www.github.com, www.stackoverflow.com, www.cloudflare.com)
3. **Multi-Attempt Testing**: Performs 3 attempts per domain to get more accurate average response times
4. **Calculates Averages**: Computes average response time and success rate for each DNS server
5. **Identifies Fastest Server**: Compares average response times and success rates to select the optimal DNS server
6. **Backs Up Current Settings**: Saves your current DNS configuration before making changes
7. **Updates DNS Settings**: Configures your network adapter to use the fastest DNS server (with fallback methods)
8. **Flushes DNS Cache**: Clears the DNS cache to ensure changes take effect immediately
9. **Verifies Changes**: Confirms that the DNS settings were updated successfully with multiple verification attempts
10. **Performs Connectivity Test**: Tests internet connectivity after changes

## Safety Features

- Requires administrative privileges to prevent unauthorized changes
- Asks for confirmation before updating DNS settings
- Creates a backup of your original DNS settings
- Attempts to restore original settings if the update fails
- Uses multiple verification attempts to ensure changes are applied
- Includes fallback methods if primary DNS update method fails
- Ignores erroneous high response times that might be caused by timeouts

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

## Customization

To add additional DNS servers to test, edit the `dns_servers` variable in the batch file and add IP addresses separated by spaces.

## License

This project is free to use and distribute.
