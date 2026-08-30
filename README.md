<p align="center">
  <img src="assets/at0mflow-uptime-monitor-banner.png" alt="At0mFlow Uptime Monitor, with the GitHub-themed Orbit mascot" width="860">
</p>

<p align="center">
  <a href="https://github.com/At0mFlow/At0mFlow-UptimeMonitor/actions/workflows/test.yml"><img alt="Tests" src="https://github.com/At0mFlow/At0mFlow-UptimeMonitor/actions/workflows/test.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="MIT licence" src="https://img.shields.io/badge/licence-MIT-2ea44f"></a>
  <a href="requirements.md"><img alt="PowerShell 5.1 and 7" src="https://img.shields.io/badge/PowerShell-5.1%20%7C%207-2671be"></a>
  <a href="https://at0mflow.com/"><img alt="Explore At0mFlow" src="https://img.shields.io/badge/explore-at0mflow.com-19a7ce"></a>
</p>

# At0mFlow Uptime Monitor

A small, local PowerShell uptime monitor for HTTP and HTTPS endpoints.

It checks status codes, response time and optional response text, then produces
readable console output, stable PowerShell objects, JSON or CSV. It can run once
for CI or repeat at a chosen interval for a lightweight terminal monitor.

This is a standalone open-source utility. It has no hosted service, telemetry,
account requirement or private At0mFlow application code.

## Quick start

```powershell
git clone https://github.com/At0mFlow/At0mFlow-UptimeMonitor.git
Set-Location ./At0mFlow-UptimeMonitor

./src/Invoke-At0mFlowUptimeMonitor.ps1 -Uri https://example.com/
```

Check several endpoints:

```powershell
./src/Invoke-At0mFlowUptimeMonitor.ps1 `
    -Uri https://example.com/, https://www.iana.org/
```

Fail a CI step when any endpoint is down:

```powershell
./src/Invoke-At0mFlowUptimeMonitor.ps1 `
    -Uri https://example.com/ `
    -FailOnDown
```

## What the output looks like

Interactive runs open with the full [Orbit console mascot](src/At0mFlow.UptimeMonitor/Orbit.Console.txt)
above the At0mFlow wordmark. The sample below starts at the wordmark.

```text
==================================================================================================

       █████╗ ████████╗ ██████╗ ███╗   ███╗███████╗██╗      ██████╗ ██╗    ██╗
      ██╔══██╗╚══██╔══╝██╔═████╗████╗ ████║██╔════╝██║     ██╔═══██╗██║    ██║
      ███████║   ██║   ██║██╔██║██╔████╔██║█████╗  ██║     ██║   ██║██║ █╗ ██║
      ██╔══██║   ██║   ████╔╝██║██║╚██╔╝██║██╔══╝  ██║     ██║   ██║██║███╗██║
      ██║  ██║   ██║   ╚██████╔╝██║ ╚═╝ ██║██║     ███████╗╚██████╔╝╚███╔███╔╝
      ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝

                     PowerShell clarity.
                      Orbit-level control.

                   ANALYSE | CLEAN | MIGRATE | MONITOR

                         https://at0mflow.com

==================================================================================================

At0mFlow Uptime Monitor
Checked 1 endpoint at 2026-08-26 02:00:00Z.
Summary: 1 up, 0 down.

[UP] Example home  HTTP 200  142.3 ms
  https://example.com/
```

Response times vary. See the checked-in
[illustrative output](examples/example-output.txt).

## Use a configuration file

Copy the synthetic example and change only the endpoints you want to check:

```powershell
Copy-Item ./examples/endpoints.example.json ./endpoints.json

./src/Invoke-At0mFlowUptimeMonitor.ps1 -ConfigPath ./endpoints.json
```

Each endpoint can set its own name, URI, request method, expected status codes,
timeout and optional text check. See [usage](docs/usage.md) for the schema.

Do not place passwords, tokens or credentials in the configuration file or URI.
Authenticated requests are intentionally outside this tool's scope.

## Keep monitoring

Run every 60 seconds until you stop the process:

```powershell
./src/Invoke-At0mFlowUptimeMonitor.ps1 `
    -ConfigPath ./endpoints.json `
    -Count 0 `
    -IntervalSeconds 60
```

Run exactly five checks:

```powershell
./src/Invoke-At0mFlowUptimeMonitor.ps1 `
    -Uri https://example.com/ `
    -Count 5 `
    -IntervalSeconds 30
```

Orbit and the At0mFlow wordmark are shown once per interactive run, not before every
interval.

## Structured output

```powershell
# Return a report object
./src/Invoke-At0mFlowUptimeMonitor.ps1 `
    -Uri https://example.com/ `
    -Format Object

# Save JSON
./src/Invoke-At0mFlowUptimeMonitor.ps1 `
    -ConfigPath ./endpoints.json `
    -Format Json `
    -OutputPath ./uptime-report.json

# Save endpoint rows as CSV
./src/Invoke-At0mFlowUptimeMonitor.ps1 `
    -ConfigPath ./endpoints.json `
    -Format Csv `
    -OutputPath ./uptime-report.csv
```

JSON, CSV and object output do not include the console wordmark, so they remain
safe for scripts and CI pipelines.

## Exit codes

| Code | Meaning |
| ---: | --- |
| `0` | The check completed, or `-FailOnDown` was not requested. |
| `1` | `-FailOnDown` was requested and at least one endpoint was down. |
| `2` | The command, configuration or request setup failed. |

## What this tool does, and what it does not

At0mFlow Uptime Monitor intentionally stays small:

- checks user-supplied HTTP and HTTPS endpoints;
- measures response time and validates expected status codes;
- optionally checks response text;
- supports local repeat monitoring and automation-friendly output.

It does not provide hosted probes, alert delivery, dashboards, historical
storage, authentication, incident management or service-level calculations.
It does not contact At0mFlow or upload results.

See [PUBLIC_BOUNDARY.md](PUBLIC_BOUNDARY.md) for the repository's disclosure
controls.

## Other public At0mFlow tools

- [At0mFlow PSAnalyzer](https://github.com/At0mFlow/At0mFlow-PSAnalyzer) turns
  PSScriptAnalyzer findings into readable console, object, JSON and CSV output.
- [At0mFlow Script Audit](https://github.com/At0mFlow/At0mFlow-ScriptAudit)
  collects custom PowerShell scripts and scheduled-task context into one
  reviewable folder tree.
- [At0mFlow RepoSync](https://github.com/At0mFlow/At0mFlow-RepoSync) safely
  commits and optionally pushes explicit paths from an existing Git working
  tree.

If you need to go beyond small command-line checks, [At0mFlow](https://at0mflow.com/)
helps teams understand, document, clean up, migrate and track PowerShell estates.

## Contributing

Issues and focused pull requests are welcome. Please read
[CONTRIBUTING.md](CONTRIBUTING.md) and use only synthetic endpoints in tests.

## Licence

MIT. See [LICENSE](LICENSE).

Built by [At0mFlow](https://at0mflow.com/) with a little help from Orbit.
