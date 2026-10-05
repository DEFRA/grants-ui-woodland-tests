# grants-ui-woodland-tests

CDP runner for the Woodland Management Plan journey tests, which live in `grants-config-woodland`.

## Language

**Woodland Management Plan**
The woodland grant journey under test, commonly abbreviated as WMP.
_Avoid_: Woodland grant when the specific plan journey matters, Forest plan

**Journey test**
An end-to-end browser test that exercises the grant application flow.
_Avoid_: Unit test, Smoke test, Performance test

**Application journey**
The full eligible WMP application path from sign-in through confirmation.
_Avoid_: Scenario when the whole user journey is meant, Script

**Application lifecycle**
The post-submission path through amend, offer sent, and withdrawn states.
_Avoid_: Browser lifecycle, Test lifecycle, Deployment lifecycle

**GAS**
The Grants Application Service used for submission and lifecycle state.
_Avoid_: Grants UI Backend, Config API, Playwright helper

**Accessibility check**
An axe-core WCAG 2.x A/AA check run on a journey page.
_Avoid_: Visual test, Smoke check, Lint

**Defra ID**
The OIDC identity provider used to authenticate test users.
_Avoid_: Test login, Local account, Browser session

**CRN**
Customer Reference Number: the Defra ID identifier for an individual user.
_Avoid_: SBI, User ID, Account number

**GAS schema**
The GAS JSON schema at `configurations/woodland/gas/gas.json` in `grants-config-woodland`, fetched with the journey tests and used to validate a submitted application's `answers` payload shape.
_Avoid_: GAS response, Submission payload (when the schema file itself is meant)

**Config release**
A tagged release of `grants-config-woodland` (e.g. `1.40.9`). The journey tests and the journey config ship together in it, and each run fetches the latest one unless `WOODLAND_TAG` pins one.
_Avoid_: Test version, Test image tag, grants-ui version
