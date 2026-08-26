# Public repository boundary

At0mFlow Uptime Monitor is intentionally separate from the At0mFlow product.
This repository may contain only:

- the open HTTP and HTTPS endpoint checker in `src`;
- synthetic examples and tests;
- public documentation and repository configuration;
- approved At0mFlow brand assets.

It must not contain product code, prompts, scoring rules, cleanup or migration
logic, backend or API service code, application configuration, credentials,
customer data, database files or production assets.

## Network boundary

The tool makes outbound HTTP or HTTPS requests only to endpoints explicitly
provided through `-Uri` or a local configuration file. It has no telemetry,
hosted service, account system, webhook sender, secret store or At0mFlow API
client.

## Automated controls

`scripts/Test-PublicBoundary.ps1` checks the repository for:

- unexpected top-level paths;
- source types that do not belong in this PowerShell-only tool;
- common At0mFlow product paths and private configuration files;
- private keys and recognisable credential patterns;
- symbolic links that could point outside the repository;
- an `origin` remote other than `At0mFlow/At0mFlow-UptimeMonitor`.

The check runs in GitHub Actions and through the repository's pre-commit and
pre-push hooks after they are enabled:

```powershell
git config core.hooksPath .githooks
```

These controls reduce accidental disclosure risk, but they do not replace a
careful review of every staged change.
