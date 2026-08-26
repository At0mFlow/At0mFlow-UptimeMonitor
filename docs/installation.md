# Installation

## 1. Check PowerShell

```powershell
$PSVersionTable.PSVersion
```

Use Windows PowerShell 5.1 or PowerShell 7.4 or newer.

## 2. Clone the repository

```powershell
git clone https://github.com/At0mFlow/At0mFlow-UptimeMonitor.git
Set-Location ./At0mFlow-UptimeMonitor
```

No module installation or At0mFlow account is required.

## 3. Run a check

```powershell
./src/Invoke-At0mFlowUptimeMonitor.ps1 -Uri https://example.com/
```

If a local execution policy prevents the script from running, review your
organisation's policy before changing anything. Do not bypass a managed policy
without approval.

## Optional module import

The repository also contains a standard PowerShell module:

```powershell
Import-Module ./src/At0mFlow.UptimeMonitor/At0mFlow.UptimeMonitor.psd1

Invoke-At0mFlowUptimeCheck -Uri https://example.com/ |
    Write-At0mFlowUptimeReport
```
