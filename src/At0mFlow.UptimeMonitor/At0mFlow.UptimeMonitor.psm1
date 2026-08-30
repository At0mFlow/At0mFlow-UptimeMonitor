Set-StrictMode -Version 2.0

function Assert-At0mFlowHttpUri {
    param(
        [Parameter(Mandatory)]
        [uri] $Uri
    )

    if (-not $Uri.IsAbsoluteUri) {
        throw "Endpoint URI must be absolute: $Uri"
    }

    if ($Uri.Scheme -notin @('http', 'https')) {
        throw "Endpoint URI must use HTTP or HTTPS: $Uri"
    }

    if (-not [string]::IsNullOrWhiteSpace($Uri.UserInfo)) {
        throw 'Credentials embedded in endpoint URIs are not supported.'
    }
}

function Get-At0mFlowObjectProperty {
    param(
        [Parameter(Mandatory)]
        [psobject] $InputObject,

        [Parameter(Mandatory)]
        [string] $Name,

        $DefaultValue
    )

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $DefaultValue
    }

    return $property.Value
}

function Write-At0mFlowWordmark {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingWriteHost',
        '',
        Justification = 'The wordmark is intended for interactive console output.'
    )]
    [CmdletBinding()]
    param()

    $orbitLines = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Orbit.Console.txt'))
    $logoLines = @(
        '       #####> ########> ######> ###>   ###>#######>##>      ######> ##>    ##>'
        '      ##<--##>[--##<--]##<-####>####> ####|##<----]##|     ##<---##>##|    ##|'
        '      #######|   ##|   ##|##<##|##<####<##|#####>  ##|     ##|   ##|##| #> ##|'
        '      ##<--##|   ##|   ####<]##|##|[##<]##|##<--]  ##|     ##|   ##|##|###>##|'
        '      ##|  ##|   ##|   [######<]##| [-] ##|##|     #######>[######<][###<###<]'
        '      [-]  [-]   [-]    [-----] [-]     [-][-]     [------] [-----]  [--][--]'
    )
    $logoGlyphs = [ordered] @{
        '#' = [char] 0x2588
        '<' = [char] 0x2554
        '>' = [char] 0x2557
        '[' = [char] 0x255A
        ']' = [char] 0x255D
        '-' = [char] 0x2550
        '|' = [char] 0x2551
    }

    Write-Host ('=' * 98) -ForegroundColor DarkGray
    Write-Host ''
    foreach ($orbitLine in $orbitLines) {
        Write-Host $orbitLine -ForegroundColor Green
    }
    Write-Host ''
    foreach ($logoLine in $logoLines) {
        $renderedLogoLine = $logoLine
        foreach ($placeholder in $logoGlyphs.Keys) {
            $renderedLogoLine = $renderedLogoLine.Replace(
                $placeholder,
                [string] $logoGlyphs[$placeholder]
            )
        }
        Write-Host $renderedLogoLine -ForegroundColor Cyan
    }
    Write-Host ''
    Write-Host '                     PowerShell clarity.' -ForegroundColor White
    Write-Host '                      Orbit-level control.' -ForegroundColor White
    Write-Host ''
    Write-Host '                   ANALYSE | CLEAN | MIGRATE | MONITOR' -ForegroundColor Green
    Write-Host ''
    Write-Host '                         https://at0mflow.com' -ForegroundColor DarkCyan
    Write-Host ''
    Write-Host ('=' * 98) -ForegroundColor DarkGray
}

function Test-At0mFlowEndpoint {
    <#
    .SYNOPSIS
    Checks one or more HTTP or HTTPS endpoints.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [Alias('Url')]
        [uri[]] $Uri,

        [string] $Name,

        [ValidateSet('GET', 'HEAD')]
        [string] $Method = 'GET',

        [ValidateRange(100, 599)]
        [int[]] $ExpectedStatusCode = @(200),

        [string] $ContainsText,

        [ValidateRange(1, 300)]
        [int] $TimeoutSeconds = 10
    )

    process {
        foreach ($endpointUri in $Uri) {
            Assert-At0mFlowHttpUri -Uri $endpointUri

            if (($Method -eq 'HEAD') -and -not [string]::IsNullOrWhiteSpace($ContainsText)) {
                throw 'ContainsText can be used with GET requests only.'
            }

            Add-Type -AssemblyName System.Net.Http -ErrorAction Stop

            $handler = [System.Net.Http.HttpClientHandler]::new()
            $client = [System.Net.Http.HttpClient]::new($handler)
            $client.Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)
            $response = $null
            $request = $null
            $stopwatch = [Diagnostics.Stopwatch]::StartNew()
            $checkedAtUtc = [DateTimeOffset]::UtcNow
            $statusCode = $null
            $contentMatched = $null
            $errorMessage = $null
            $isUp = $false

            try {
                $httpMethod = if ($Method -eq 'HEAD') {
                    [System.Net.Http.HttpMethod]::Head
                }
                else {
                    [System.Net.Http.HttpMethod]::Get
                }

                $request = [System.Net.Http.HttpRequestMessage]::new($httpMethod, $endpointUri)
                $request.Headers.UserAgent.ParseAdd('At0mFlow-UptimeMonitor/1.0')
                $response = $client.SendAsync($request).GetAwaiter().GetResult()
                $statusCode = [int] $response.StatusCode
                $isUp = $ExpectedStatusCode -contains $statusCode

                if (-not [string]::IsNullOrWhiteSpace($ContainsText)) {
                    $content = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                    $contentMatched = $content.IndexOf(
                        $ContainsText,
                        [StringComparison]::OrdinalIgnoreCase
                    ) -ge 0
                    $isUp = $isUp -and $contentMatched
                }

                if (-not ($ExpectedStatusCode -contains $statusCode)) {
                    $errorMessage = 'Expected status {0}; received {1}.' -f @(
                        ($ExpectedStatusCode -join ', '),
                        $statusCode
                    )
                }
                elseif ($contentMatched -eq $false) {
                    $errorMessage = 'The response did not contain the expected text.'
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
            }
            finally {
                $stopwatch.Stop()
                if ($null -ne $response) {
                    $response.Dispose()
                }
                if ($null -ne $request) {
                    $request.Dispose()
                }
                $client.Dispose()
                $handler.Dispose()
            }

            $displayName = if ([string]::IsNullOrWhiteSpace($Name)) {
                $endpointUri.AbsoluteUri
            }
            else {
                $Name
            }

            [pscustomobject] @{
                PSTypeName          = 'At0mFlow.UptimeMonitor.Result'
                Name                = $displayName
                Uri                 = $endpointUri.AbsoluteUri
                Status              = $(if ($isUp) { 'Up' } else { 'Down' })
                IsUp                = $isUp
                StatusCode          = $statusCode
                ExpectedStatusCodes = @($ExpectedStatusCode)
                ResponseTimeMs      = [Math]::Round($stopwatch.Elapsed.TotalMilliseconds, 1)
                Method              = $Method
                ContentMatched      = $contentMatched
                CheckedAtUtc        = $checkedAtUtc
                Error               = $errorMessage
            }
        }
    }
}

function Invoke-At0mFlowUptimeCheck {
    <#
    .SYNOPSIS
    Checks endpoints supplied directly or through a JSON configuration file.
    #>
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
        [int] $TimeoutSeconds = 10
    )

    $results = New-Object 'System.Collections.Generic.List[object]'

    if ($PSCmdlet.ParameterSetName -eq 'Uri') {
        foreach ($endpointUri in $Uri) {
            $testParameters = @{
                Uri                = $endpointUri
                Method             = $Method
                ExpectedStatusCode = $ExpectedStatusCode
                TimeoutSeconds     = $TimeoutSeconds
            }
            if (-not [string]::IsNullOrWhiteSpace($ContainsText)) {
                $testParameters.ContainsText = $ContainsText
            }
            $results.Add((Test-At0mFlowEndpoint @testParameters))
        }
    }
    else {
        $resolvedConfigPath = (Resolve-Path -LiteralPath $ConfigPath -ErrorAction Stop).Path
        $configuration = Get-Content -LiteralPath $resolvedConfigPath -Raw | ConvertFrom-Json
        $endpointsProperty = $configuration.PSObject.Properties['endpoints']
        $configurationItems = if ($null -ne $endpointsProperty) {
            @($endpointsProperty.Value)
        }
        else {
            @($configuration)
        }

        if ($configurationItems.Count -eq 0) {
            throw 'The configuration file does not contain any endpoints.'
        }

        foreach ($configurationItem in $configurationItems) {
            $uriValue = Get-At0mFlowObjectProperty -InputObject $configurationItem -Name 'uri'
            if ([string]::IsNullOrWhiteSpace([string] $uriValue)) {
                throw 'Every configured endpoint must include a uri value.'
            }

            $configuredMethod = [string] (Get-At0mFlowObjectProperty `
                -InputObject $configurationItem `
                -Name 'method' `
                -DefaultValue 'GET')
            $configuredStatuses = @(
                Get-At0mFlowObjectProperty `
                    -InputObject $configurationItem `
                    -Name 'expectedStatusCodes' `
                    -DefaultValue @(200)
            )
            $configuredTimeout = [int] (Get-At0mFlowObjectProperty `
                -InputObject $configurationItem `
                -Name 'timeoutSeconds' `
                -DefaultValue $TimeoutSeconds)
            $configuredName = [string] (Get-At0mFlowObjectProperty `
                -InputObject $configurationItem `
                -Name 'name')
            $configuredText = [string] (Get-At0mFlowObjectProperty `
                -InputObject $configurationItem `
                -Name 'containsText')

            $testParameters = @{
                Uri                = [uri] $uriValue
                Method             = $configuredMethod.ToUpperInvariant()
                ExpectedStatusCode = [int[]] $configuredStatuses
                TimeoutSeconds     = $configuredTimeout
            }
            if (-not [string]::IsNullOrWhiteSpace($configuredName)) {
                $testParameters.Name = $configuredName
            }
            if (-not [string]::IsNullOrWhiteSpace($configuredText)) {
                $testParameters.ContainsText = $configuredText
            }
            $results.Add((Test-At0mFlowEndpoint @testParameters))
        }
    }

    $resultArray = $results.ToArray()
    $upCount = @($resultArray | Where-Object IsUp).Count
    $downCount = $resultArray.Count - $upCount

    [pscustomobject] @{
        PSTypeName  = 'At0mFlow.UptimeMonitor.Report'
        CheckedAtUtc = [DateTimeOffset]::UtcNow
        TargetCount = $resultArray.Count
        UpCount     = $upCount
        DownCount   = $downCount
        AllUp       = $downCount -eq 0
        Results     = $resultArray
    }
}

function Write-At0mFlowUptimeReport {
    <#
    .SYNOPSIS
    Writes an uptime report in a readable console format.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingWriteHost',
        '',
        Justification = 'This function exists specifically to render coloured console output.'
    )]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [psobject] $Report,

        [switch] $NoBanner
    )

    process {
        if (-not $NoBanner.IsPresent) {
            Write-At0mFlowWordmark
        }

        Write-Host ''
        Write-Host 'At0mFlow Uptime Monitor' -ForegroundColor Cyan
        Write-Host ('Checked {0} endpoint{1} at {2:u}.' -f @(
            $Report.TargetCount,
            $(if ($Report.TargetCount -eq 1) { '' } else { 's' }),
            [DateTime] $Report.CheckedAtUtc.UtcDateTime
        ))
        Write-Host ('Summary: {0} up, {1} down.' -f $Report.UpCount, $Report.DownCount)

        foreach ($result in $Report.Results) {
            $colour = if ($result.IsUp) { 'Green' } else { 'Red' }
            $statusCodeText = if ($null -eq $result.StatusCode) { '-' } else { $result.StatusCode }

            Write-Host ''
            Write-Host ('[{0}] {1}  HTTP {2}  {3} ms' -f @(
                $result.Status.ToUpperInvariant(),
                $result.Name,
                $statusCodeText,
                $result.ResponseTimeMs
            )) -ForegroundColor $colour
            Write-Host ('  {0}' -f $result.Uri) -ForegroundColor DarkGray
            if (-not [string]::IsNullOrWhiteSpace($result.Error)) {
                Write-Host ('  {0}' -f $result.Error) -ForegroundColor $colour
            }
        }

        Write-Host ''
    }
}

Export-ModuleMember -Function @(
    'Test-At0mFlowEndpoint'
    'Invoke-At0mFlowUptimeCheck'
    'Write-At0mFlowUptimeReport'
)
