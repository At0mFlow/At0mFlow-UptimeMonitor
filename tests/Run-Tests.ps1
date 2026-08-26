[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$script:FailureCount = 0

function Assert-That {
    param(
        [Parameter(Mandatory)]
        [bool] $Condition,

        [Parameter(Mandatory)]
        [string] $Message
    )

    if ($Condition) {
        Write-Host "PASS: $Message" -ForegroundColor Green
    }
    else {
        $script:FailureCount++
        Write-Host "FAIL: $Message" -ForegroundColor Red
    }
}

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path $repositoryRoot 'src/At0mFlow.UptimeMonitor/At0mFlow.UptimeMonitor.psd1'
$entryPoint = Join-Path $repositoryRoot 'src/Invoke-At0mFlowUptimeMonitor.ps1'
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ('At0mFlow-UptimeMonitor-Tests-' + [guid]::NewGuid())
$serverProcess = $null

try {
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null

    $manifest = Test-ModuleManifest -Path $modulePath
    Assert-That ($manifest.Version.ToString() -eq '1.0.0') 'The module manifest is valid.'

    Import-Module $modulePath -Force

    $portProbe = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
    $portProbe.Start()
    $port = ([Net.IPEndPoint] $portProbe.LocalEndpoint).Port
    $portProbe.Stop()

    'healthy service' | Set-Content -LiteralPath (Join-Path $temporaryRoot 'healthy.txt') -Encoding UTF8
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($null -eq $pythonCommand) {
        $pythonCommand = Get-Command python3 -ErrorAction Stop
    }

    $startProcessParameters = @{
        FilePath         = $pythonCommand.Source
        ArgumentList     = @(
            '-m',
            'http.server',
            $port,
            '--bind',
            '127.0.0.1',
            '--directory',
            $temporaryRoot
        )
        PassThru         = $true
        WorkingDirectory = $temporaryRoot
    }
    if ($env:OS -eq 'Windows_NT') {
        $startProcessParameters.WindowStyle = 'Hidden'
    }
    $serverProcess = Start-Process @startProcessParameters

    $serverReady = $false
    for ($attempt = 1; $attempt -le 50; $attempt++) {
        $readyResult = Test-At0mFlowEndpoint `
            -Uri "http://127.0.0.1:$port/healthy.txt" `
            -TimeoutSeconds 1
        if ($readyResult.IsUp) {
            $serverReady = $true
            break
        }
        Start-Sleep -Milliseconds 100
    }
    Assert-That $serverReady 'The synthetic local HTTP server starts.'
    if (-not $serverReady) {
        throw 'The synthetic local HTTP server did not start.'
    }

    $healthyUri = [uri] "http://127.0.0.1:$port/healthy.txt"

    $healthyResult = Test-At0mFlowEndpoint `
        -Uri $healthyUri `
        -Name 'Synthetic healthy endpoint' `
        -ContainsText 'healthy service'
    Assert-That $healthyResult.IsUp 'A matching HTTP 200 endpoint is up.'
    Assert-That ($healthyResult.StatusCode -eq 200) 'The HTTP status code is recorded.'
    Assert-That ($healthyResult.ResponseTimeMs -ge 0) 'Response time is recorded.'
    Assert-That ($healthyResult.ContentMatched -eq $true) 'Expected response text is checked.'

    $unexpectedResult = Test-At0mFlowEndpoint `
        -Uri $healthyUri `
        -ExpectedStatusCode 201
    Assert-That (-not $unexpectedResult.IsUp) 'An unexpected status marks the endpoint down.'
    Assert-That ($unexpectedResult.Error -match 'Expected status 201') 'A status mismatch has a readable reason.'

    $headResult = Test-At0mFlowEndpoint `
        -Uri $healthyUri `
        -Method HEAD `
        -ExpectedStatusCode 200
    Assert-That $headResult.IsUp 'HEAD requests are supported.'

    $configurationPath = Join-Path $temporaryRoot 'endpoints.json'
    @"
{
  "endpoints": [
    {
      "name": "Synthetic healthy",
      "uri": "$healthyUri",
      "expectedStatusCodes": [200],
      "containsText": "healthy service"
    },
    {
      "name": "Synthetic HEAD",
      "uri": "$healthyUri",
      "method": "HEAD",
      "expectedStatusCodes": [200]
    }
  ]
}
"@ | Set-Content -LiteralPath $configurationPath -Encoding UTF8

    $report = Invoke-At0mFlowUptimeCheck -ConfigPath $configurationPath
    Assert-That ($report.TargetCount -eq 2) 'Configuration files can define multiple endpoints.'
    Assert-That ($report.UpCount -eq 2) 'Per-endpoint expected status codes are applied.'
    Assert-That $report.AllUp 'The report summary identifies an all-up result.'

    $jsonText = & $entryPoint -Uri $healthyUri -Format Json | Out-String
    $jsonExitCode = $LASTEXITCODE
    $jsonReport = $jsonText | ConvertFrom-Json
    Assert-That ($jsonExitCode -eq 0) 'JSON output exits successfully.'
    Assert-That ($jsonReport.TargetCount -eq 1) 'JSON output contains the report summary.'
    Assert-That ($jsonReport.Results.Count -eq 1) 'JSON output contains endpoint results.'

    $consoleText = & $entryPoint -Uri $healthyUri -Format Console 6>&1 | Out-String
    $block = [string] [char] 0x2588
    $topLeftLogoFragment = (
        '       ' +
        (($block * 5) -join '') + [char] 0x2557 + ' ' +
        (($block * 8) -join '') + [char] 0x2557 + ' ' +
        (($block * 6) -join '') + [char] 0x2557
    )
    Assert-That $consoleText.Contains($topLeftLogoFragment) 'Console output renders the At0mFlow block wordmark.'
    Assert-That ($consoleText -match 'PowerShell clarity\.') 'Console output includes the At0mFlow wordmark.'
    Assert-That ($consoleText -match 'At0mFlow Uptime Monitor') 'Console output identifies the tool.'
    Assert-That ($consoleText -match '\[UP\]') 'Console output shows endpoint status.'

    & $entryPoint `
        -Uri $healthyUri `
        -ExpectedStatusCode 201 `
        -Format Object `
        -FailOnDown | Out-Null
    Assert-That ($LASTEXITCODE -eq 1) 'FailOnDown returns exit code 1 for a down endpoint.'

    $embeddedCredentialRejected = $false
    try {
        Test-At0mFlowEndpoint -Uri 'https://user:password@example.com/' | Out-Null
    }
    catch {
        $embeddedCredentialRejected = $true
    }
    Assert-That $embeddedCredentialRejected 'Credentials embedded in endpoint URIs are rejected.'
}
finally {
    if (($null -ne $serverProcess) -and (-not $serverProcess.HasExited)) {
        $serverProcess.Kill()
        $serverProcess.WaitForExit()
    }

    $resolvedTemporaryRoot = [IO.Path]::GetFullPath($temporaryRoot)
    $resolvedSystemTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if ($resolvedTemporaryRoot.StartsWith($resolvedSystemTemp, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolvedTemporaryRoot) -like 'At0mFlow-UptimeMonitor-Tests-*' -and
        (Test-Path -LiteralPath $resolvedTemporaryRoot)) {
        Remove-Item -LiteralPath $resolvedTemporaryRoot -Recurse -Force
    }
}

if ($script:FailureCount -gt 0) {
    throw "$script:FailureCount test assertion(s) failed."
}

Write-Host 'All tests passed.' -ForegroundColor Cyan
exit 0
