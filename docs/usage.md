# Usage

## Check one endpoint

```powershell
./src/Invoke-At0mFlowUptimeMonitor.ps1 -Uri https://example.com/
```

The default request is `GET`, the default expected status is `200`, and the
default timeout is 10 seconds.

## Expected status codes

```powershell
./src/Invoke-At0mFlowUptimeMonitor.ps1 `
    -Uri https://example.com/health `
    -ExpectedStatusCode 200, 204
```

Redirects are followed by the underlying .NET HTTP client. The reported status
is the final response status.

## Response text

```powershell
./src/Invoke-At0mFlowUptimeMonitor.ps1 `
    -Uri https://example.com/ `
    -ContainsText 'Example Domain'
```

Text matching is case-insensitive and requires a `GET` request.

## HEAD requests

```powershell
./src/Invoke-At0mFlowUptimeMonitor.ps1 `
    -Uri https://example.com/ `
    -Method HEAD
```

Use `HEAD` only when the target server supports it. A server may return a
different result for `HEAD` and `GET`.

## Configuration schema

The configuration file can be an array of endpoints or an object with an
`endpoints` array:

```json
{
  "endpoints": [
    {
      "name": "Public status page",
      "uri": "https://example.com/",
      "method": "GET",
      "expectedStatusCodes": [200],
      "containsText": "Example Domain",
      "timeoutSeconds": 10
    }
  ]
}
```

Fields:

| Field | Required | Default | Meaning |
| --- | --- | --- | --- |
| `uri` | Yes | None | Absolute HTTP or HTTPS endpoint. |
| `name` | No | Full URI | Friendly console label. |
| `method` | No | `GET` | `GET` or `HEAD`. |
| `expectedStatusCodes` | No | `[200]` | One or more accepted HTTP statuses. |
| `containsText` | No | None | Case-insensitive response text check for `GET`. |
| `timeoutSeconds` | No | Command default | Timeout from 1 to 300 seconds. |

Credentials embedded in URLs are rejected. Do not put tokens, passwords,
private headers or confidential internal addresses in a repository.

## Repeat monitoring

`-Count 0` runs until interrupted. A positive count runs that many checks.
Repeated monitoring supports console output only.

```powershell
./src/Invoke-At0mFlowUptimeMonitor.ps1 `
    -ConfigPath ./endpoints.json `
    -Count 0 `
    -IntervalSeconds 60
```

For unattended use, see [scheduling](scheduling.md).
