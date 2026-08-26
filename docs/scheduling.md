# Scheduling checks

For scheduled checks, use `-FailOnDown` so the process returns exit code `1`
when an endpoint is unavailable.

## Windows Task Scheduler

Create a task through your normal administration process and use an action like:

```text
powershell.exe -NoProfile -File C:\Tools\At0mFlow-UptimeMonitor\src\Invoke-At0mFlowUptimeMonitor.ps1 -ConfigPath C:\Tools\At0mFlow-UptimeMonitor\endpoints.json -Format Json -OutputPath C:\Tools\At0mFlow-UptimeMonitor\uptime-report.json -FailOnDown
```

Run the task under an account that needs only read access to the tool and
configuration plus write access to the chosen output folder.

## cron on Linux

Example crontab entry for a check every five minutes:

```text
*/5 * * * * /usr/bin/pwsh -NoProfile -File /opt/at0mflow-uptime/src/Invoke-At0mFlowUptimeMonitor.ps1 -ConfigPath /opt/at0mflow-uptime/endpoints.json -Format Json -OutputPath /var/tmp/at0mflow-uptime.json -FailOnDown
```

Redirect or collect the exit code with the monitoring system already approved
for your environment. This project does not send alerts or results elsewhere.
