@{
    RootModule        = 'At0mFlow.UptimeMonitor.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'e8ef3ef7-b557-4bc5-8c7f-3a80f893339b'
    Author            = 'At0mFlow'
    CompanyName       = 'At0mFlow'
    Copyright         = 'Copyright (c) 2026 At0mFlow. Licensed under the MIT License.'
    Description       = 'A small, local PowerShell monitor for HTTP and HTTPS endpoints.'
    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Test-At0mFlowEndpoint'
        'Invoke-At0mFlowUptimeCheck'
        'Write-At0mFlowUptimeReport'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags = @(
                'PowerShell'
                'Uptime'
                'Monitoring'
                'HTTP'
                'HTTPS'
                'HealthCheck'
                'CI'
                'PSEdition_Desktop'
                'PSEdition_Core'
                'Windows'
                'Linux'
            )
            LicenseUri = 'https://github.com/At0mFlow/At0mFlow-UptimeMonitor/blob/main/LICENSE'
            ProjectUri = 'https://github.com/At0mFlow/At0mFlow-UptimeMonitor'
        }
    }
}
