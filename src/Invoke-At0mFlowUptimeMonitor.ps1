<#
.SYNOPSIS
Checks HTTP or HTTPS endpoints and prints a clear local uptime report.

.EXAMPLE
./src/Invoke-At0mFlowUptimeMonitor.ps1 -Uri https://example.com/

.EXAMPLE
./src/Invoke-At0mFlowUptimeMonitor.ps1 -ConfigPath ./examples/endpoints.example.json

.EXAMPLE
./src/Invoke-At0mFlowUptimeMonitor.ps1 -Uri https://example.com/ -Count 0 -IntervalSeconds 60
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost',
    '',
    Justification = 'Host messages confirm local report files written during interactive use.'
)]
[CmdletBinding(DefaultParameterSetName = 'Uri')]
param(
    [Parameter(Mandatory, Position = 0, ParameterSetName = 'Uri')]
    [Alias('Url')]
    [uri[]] $Uri,

    [Parameter(Mandatory, ParameterSetName = 'Config')]
    [ValidateNotNullOrEmpty()]
    [string] $ConfigPath,

    [Parameter(ParameterSetName = 'Uri')]
    [ValidateSet('GET', 'HEAD')]
    [string] $Method = 'GET',

    [Parameter(ParameterSetName = 'Uri')]
    [ValidateRange(100, 599)]
    [int[]] $ExpectedStatusCode = @(200),

    [Parameter(ParameterSetName = 'Uri')]
    [string] $ContainsText,

    [ValidateRange(1, 300)]
    [int] $TimeoutSeconds = 10,

    [ValidateRange(0, 100000)]
    [int] $Count = 1,

    [ValidateRange(1, 86400)]
    [int] $IntervalSeconds = 60,

    [ValidateSet('Console', 'Object', 'Json', 'Csv')]
    [string] $Format = 'Console',

    [string] $OutputPath,

    [switch] $FailOnDown
)

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $PSScriptRoot 'At0mFlow.UptimeMonitor/At0mFlow.UptimeMonitor.psd1'

try {
    Import-Module $modulePath -Force

    if (($Count -ne 1) -and ($Format -ne 'Console')) {
        throw 'Repeated monitoring is supported with Console format only.'
    }

    if (($Format -in @('Console', 'Object')) -and -not [string]::IsNullOrWhiteSpace($OutputPath)) {
        throw 'OutputPath is supported with Json and Csv formats only.'
    }

    $checkParameters = @{
        TimeoutSeconds = $TimeoutSeconds
    }
    if ($PSCmdlet.ParameterSetName -eq 'Config') {
        $checkParameters.ConfigPath = $ConfigPath
    }
    else {
        $checkParameters.Uri = $Uri
        $checkParameters.Method = $Method
        $checkParameters.ExpectedStatusCode = $ExpectedStatusCode
        if (-not [string]::IsNullOrWhiteSpace($ContainsText)) {
            $checkParameters.ContainsText = $ContainsText
        }
    }

    $iteration = 0
    $observedDownEndpoint = $false

    do {
        $iteration++
        $report = Invoke-At0mFlowUptimeCheck @checkParameters
        $observedDownEndpoint = $observedDownEndpoint -or (-not $report.AllUp)

        switch ($Format) {
            'Console' {
                Write-At0mFlowUptimeReport -Report $report -NoBanner:($iteration -gt 1)
            }
            'Object' {
                $report
            }
            'Json' {
                $content = $report | ConvertTo-Json -Depth 6
                if ([string]::IsNullOrWhiteSpace($OutputPath)) {
                    $content
                }
                else {
                    $content | Set-Content -LiteralPath $OutputPath -Encoding UTF8
                    Write-Host "Wrote JSON report to $OutputPath"
                }
            }
            'Csv' {
                $content = $report.Results |
                    Select-Object Name, Uri, Status, IsUp, StatusCode, ResponseTimeMs, Method, CheckedAtUtc, Error |
                    ConvertTo-Csv -NoTypeInformation
                if ([string]::IsNullOrWhiteSpace($OutputPath)) {
                    $content
                }
                else {
                    $content | Set-Content -LiteralPath $OutputPath -Encoding UTF8
                    Write-Host "Wrote CSV report to $OutputPath"
                }
            }
        }

        $shouldRepeat = ($Count -eq 0) -or ($iteration -lt $Count)
        if ($shouldRepeat) {
            Start-Sleep -Seconds $IntervalSeconds
        }
    }
    while ($shouldRepeat)

    if ($FailOnDown.IsPresent -and $observedDownEndpoint) {
        exit 1
    }

    exit 0
}
catch {
    Write-Error $_
    exit 2
}
