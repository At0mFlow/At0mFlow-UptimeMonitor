# Contributing

Small, focused improvements are welcome.

1. Fork the repository and create a branch.
2. Keep the monitor independent of the At0mFlow product and its private code.
3. Use only synthetic endpoints and fixtures in tests.
4. Install Python 3 for the isolated local HTTP test fixture.
5. Run `./tests/Run-Tests.ps1`.
6. Analyse `./src` with PSScriptAnalyzer errors and warnings enabled.
7. Open a pull request explaining the behaviour change.

Please do not submit product code, credentials, private endpoints, customer
data, AI prompts, scoring systems, migration logic or other confidential
material.
