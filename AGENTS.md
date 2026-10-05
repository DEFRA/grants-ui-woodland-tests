# Repository Guidelines

CDP Portal runner for the Woodland grant journey tests. **This repo contains no specs.** The Playwright tests live in `grants-config-woodland` under `test/grants-ui/`, next to the journey config they exercise, because the two change in lockstep. grants-ui's CI pipeline builds and runs them straight from that repo (`grants-ui/compose.tests.yml`, `tools/docker-compose-smoke-test.sh`); this repo does the same for CDP runs. To run the tests locally, run them from `grants-config-woodland`.

## How the tests are fetched

`scripts/fetch-tests.sh` runs first in `npm test`. (`.npmrc` sets `ignore-scripts=true`, so npm `pre*` hooks won't run; keep the fetch chained into the script.) It:

1. Resolves the latest `grants-config-woodland` tag from `https://api.github.com/repos/DEFRA/grants-config-woodland/tags` (`.[0].name`), the same lookup grants-ui uses. Set `WOODLAND_TAG` to pin a release instead.
2. Downloads the source tarball at that tag and extracts it into `.woodland-config/` (gitignored and dockerignored), replacing any previous copy.

On CDP, GitHub is only reachable via the egress proxy. The script passes `CDP_HTTPS_PROXY` (falling back to `CDP_HTTP_PROXY`) to its own `curl` calls only, without exporting `HTTP(S)_PROXY`, so the browser's route to grants-ui is unchanged. Without the proxy the tags lookup returns nothing and Playwright never runs, which shows up as `/app/playwright-report is not found` at the publish step.

The Playwright config sets `testDir` to `./.woodland-config/test/grants-ui/test/specs`. The spec reads the GAS schema by relative path (`configurations/woodland/gas/gas.json` in the same tarball), so the whole repo is extracted rather than just `test/grants-ui`.

The fetched code has no `node_modules` of its own. Its imports (`@playwright/test`, `@axe-core/playwright`, `ajv`, `mockserver-client`, `mongodb`) resolve up to **this** repo's `node_modules`. Playwright loads every spec file even when `grep` filters its tests out, so the `@ci`-only lifecycle spec's imports must still resolve here. Keep `package.json` dependencies in line with `grants-config-woodland/test/grants-ui/package.json`, and keep `@playwright/test` in line with the `mcr.microsoft.com/playwright` tag in the `Dockerfile`. Don't install deps inside `.woodland-config`: a second copy of `@playwright/test` breaks the runner.

To change a test, change it in `grants-config-woodland` and cut a release. This repo picks it up on its next run without being rebuilt.

```
scripts/fetch-tests.sh        # fetches grants-config-woodland at the latest tag
playwright.cdp.config.js      # CDP Portal config
bin/publish-tests.sh          # publishes the HTML report to S3 (CDP only)
.woodland-config/             # fetched at run time, not committed
```

## Tech Stack

- **Test framework**: Playwright (`@playwright/test`), JavaScript only, no TypeScript
- **Node version**: 24.15.0 (see `.nvmrc`)

## Commands

| Script | What it does |
|---|---|
| `npm test` | Fetch tests, run in CDP mode (requires `ENVIRONMENT` env var) |
| `npm run report:publish` | Push `playwright-report/` to S3 via `RESULTS_OUTPUT_S3_PATH` |

CDP base URL: `https://grants-ui.${ENVIRONMENT}.cdp-int.defra.cloud`.

This repo is **not** part of the grants-ui CI pipeline and has no local mode, so the CDP config is the only one.

## Domain Language

Use `CONTEXT.md` as the source of truth for woodland grant journey-test language.

## Developer Addenda

Developers can add their own `AGENTS.local.md`, which should be read as an addendum to this file. Keep it local to your machine and don't commit it.

## Entrypoint behaviour

`entrypoint.sh` follows the standard CDP test-suite pattern: it always runs `npm test` (no command is passed in), then publishes the report.

- If tests fail, a `FAILED` file is written and the process exits with code 1
- Report publishing via `npm run report:publish` always runs, and `RESULTS_OUTPUT_S3_PATH` must be set. The image is only for CDP

## Docker

The `Dockerfile` installs the AWS CLI and Playwright's Microsoft Edge (`msedge`) with system dependencies via the `mcr.microsoft.com/playwright` base image. Build for linux/amd64 on M1 Macs:

```sh
docker build . --platform=linux/amd64
```

## GitHub Actions

- `.github/workflows/check-pull-request.yml` — installs dependencies on PRs
- `.github/workflows/publish.yml` — builds and publishes the Docker image on merge to main

## Spec-authoring notes (to move to grants-config-woodland)

These notes cover writing the specs, which now live in `grants-config-woodland/test/grants-ui`. They are kept here until that repo's AGENTS.md takes them over. Paths below are relative to `test/grants-ui` in that repo.

#### Coding style

- **JavaScript only** — no TypeScript. Defra policy.
- **No assertions in page objects** — page objects encapsulate navigation and interaction only. Assertions belong in the spec.
- **Helper functions at the bottom of the file** — any file-scoped helper functions (e.g. `assertTaskStatuses`) must be declared after the `test.describe` block, not before.
- Keep specs named after the lifecycle or journey they cover, and keep helpers focused on authentication, backend setup, GAS, and accessibility.

#### Accessibility checks

Preserve the `analyzeAccessibility(page)` checks (from `test/utils/accessibility.js`) on journey pages.

#### GAS (Grant Application Service)

`grants-ui` submits applications to an external service called GAS. In CI, GAS is replaced by a **MockServer** instance, which is why tests that interact with GAS are tagged `@ci` only.

The `test/utils/gas.js` helper wraps `mockserver-client` and provides:

- `setDefaultStatusQuery404Response()` — catch-all 404 for status queries; called in `beforeEach`
- `setStatusQueryResponse(referenceNumber, gasStatus)` — mock a status query response
- `getApplicationSubmission(referenceNumber)` — retrieve the recorded POST request from MockServer for assertions
- `clearExpectation(expectationId)` — clean up; called in `afterEach` for all IDs accumulated during the test

**Env vars required:** `MOCKSERVER_HOST`, `MOCKSERVER_PORT`. These are set by the CI environment.

#### Authentication

All journey tests authenticate via the `Defra ID` OIDC provider used by `grants-ui`. In local running, CI, and the CDP Dev environment this is a stub (`fct-defra-id-stub`). In the CDP Test environment this is a real instance of Defra ID, which can be slower to respond and must be catered for. The `authenticateTo(page, path, crn)` helper in `test/utils/auth.js` handles the full flow:

1. Navigate to a protected URL → app redirects to stub login page
2. Fill in CRN + password and submit
3. Stub redirects back via OIDC to `/auth/sign-in-oidc`

Each spec must supply its own CRN so tests can run in parallel without sharing session state. There is no default — `crn` is required.
**Password:** hardcoded as `x` (the stub always accepts this password)

#### WMP journey pages (in order)

All pages are prefixed `/woodland/`:

| Path | Description |
|---|---|
| `/start` | Application start page |
| `/check-details` | Confirm applicant/org details |
| `/tasks` | Task list |
| `/eligibility-land-registered` | Land registered with RPA? |
| `/eligibility-management-control` | Management control for duration? |
| `/eligibility-tenant` | Tenant of a public body? |
| `/eligibility-grazing-rights` | Land with grazing rights? |
| `/eligibility-valid-wmp` | Existing valid WMPs? |
| `/eligibility-higher-tier` | Intend to apply for CSHT? |
| `/total-area-of-land-parcels` | Total area (ha) of land parcels |
| `/total-area-of-land-over-10-years-old` | Woodland over 10 years old (ha) |
| `/total-area-of-land-under-10-years-old` | Newly planted woodland under 10 years (ha) |
| `/centre-of-woodland` | Grid reference for centre of woodland |
| `/which-forestry-commission-team` | FC team advising |
| `/summary` | Check your answers |
| `/potential-funding` | Potential funding estimate |
| `/declaration` | Submit your application |
| `/confirmation` | Application received |

Conditional pages (not on happy path): `/eligibility-countersignature`, `/eligibility-tenant-obligations`, `/eligibility-wmp-agreement`, and three exit/terminal pages.
