# grants-ui-woodland-tests

Runner for the Woodland Management Plan grant journey tests on the CDP Portal.

The tests themselves live in [grants-config-woodland](https://github.com/DEFRA/grants-config-woodland) under `test/grants-ui`, alongside the journey config they exercise. This repo holds no specs: on every run it fetches the config repo at its latest release tag into `.woodland-config/` (gitignored) and runs the tests from there. This is the same tag grants-ui's CI uses. Set `WOODLAND_TAG` to pin a release, e.g. `WOODLAND_TAG=1.40.9 npm test`.

## What This Tests

This test suite provides journey testing coverage for:

- Woodland Management Plan grant application journeys served by [grants-ui](https://github.com/DEFRA/grants-ui)

## Technology Stack

- **Playwright** - Browser automation framework
- **Node.js 24+** - Runtime environment

## Prerequisites

- Node.js `>=24.15.0 <25.0.0` (check with `node --version`)
- npm (comes with Node.js)

## Running the Test Suite

The suite runs on the CDP Portal only. To run the journey tests locally, run them from grants-config-woodland.

### CDP Portal — playwright.cdp.config.js

```bash
npm test
```

- Runs against the CDP environment specified by the `ENVIRONMENT` env var
- Base URL pattern: `https://grants-ui.${ENVIRONMENT}.cdp-int.defra.cloud`
- Triggered via the CDP Portal under Test Suites
- Publishes an HTML report to S3
- Runs in Microsoft Edge (Playwright's `msedge` channel). The CDP Portal runner is Linux, so this is the Linux build of Edge rather than true Windows Edge — best endeavours coverage, not a substitute for testing on Windows Edge directly

## Project Structure

```
grants-ui-woodland-tests/
├── scripts/fetch-tests.sh      # Fetches the tests from grants-config-woodland
└── playwright.cdp.config.js    # CDP Portal config
```

## Writing Tests

Tests are written in [grants-config-woodland](https://github.com/DEFRA/grants-config-woodland) under `test/grants-ui/test/specs`. Change them there and cut a config release; this repo picks up the new release on its next run.

## Test Reports

The native Playwright HTML report is used. When running on CDP, the report is automatically published to S3 and made available in the portal.

## Troubleshooting

### Tests Won't Run

- Ensure you have the correct Node.js version: `node --version` should be `>=24.15.0 <25.0.0`
- Ensure the service under test is running and accessible at the configured base URL
- Run `npx playwright install msedge` if the browser is not installed

## Related Repositories

- [grants-config-woodland](https://github.com/DEFRA/grants-config-woodland) - Woodland config and the journey tests themselves
- [grants-ui](https://github.com/DEFRA/grants-ui) - The main grants application UI service

## Support

For questions or issues with this test suite, please contact the Grants Application Enablement (GAE) team.

## Licence

THIS INFORMATION IS LICENSED UNDER THE CONDITIONS OF THE OPEN GOVERNMENT LICENCE found at:

<http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3>

The following attribution statement MUST be cited in your products and applications when using this information.

> Contains public sector information licensed under the Open Government licence v3

### About the licence

The Open Government Licence (OGL) was developed by the Controller of Her Majesty's Stationery Office (HMSO) to enable
information providers in the public sector to license the use and re-use of their information under a common open
licence.

It is designed to encourage use and re-use of information freely and flexibly, with only a few conditions.
