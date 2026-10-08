# Work-order triage: local Agentic Ignition demo

**Local-only, simulated CMMS.** This demonstrates the integration and agent feedback loop; it does not connect to production assets. Ask which real API, asset model, priorities, database, and operator workflow should replace the stand-ins.

## Rehearsal (do before screen sharing)

From the stack root:

```bash
cp .env.example .env                 # only if .env does not already exist
# Edit .env: unique admin password and DEMO_DB_PASSWORD; confirm local-only 8.3.9 image.
./scripts/work-order-demo.sh up
# If the trial expires, reset ONLY this disposable development gateway's trial.
./scripts/work-order-demo.sh cli
./scripts/work-order-demo.sh test
```

The `up` command starts Ignition, PostgreSQL and a deterministic external work-order API under Compose; it installs development modules, creates an encrypted Ignition JDBC connection through its 8.3 API, and scans Git-tracked project files. The API and DB have no published host ports. Only the gateway listens on `127.0.0.1:8088`. The ignored `.env` and generated API token must not be displayed or committed. `npm ci` in `projects/example-project/e2e` reinstalls pinned browser dependencies after the commissioned sample is cloned; install Chromium with `npx playwright install chromium` if needed.

## 15-minute live walkthrough

1. **Frame the ask (1 min):** “A maintenance system reports a vibration-related work order. Operators need a visible triage state and we need evidence that the state came through a real gateway, external API, and SQL database.” The mock CMMS owns `WO-1042` (Mixer-7/high) and `WO-1043` (Pump-2/low).
2. **Show the three containers (1 min):** `docker compose ps`. In `docker-compose.yml`, point out private service DNS (`work-orders-api`, `postgres`), healthy dependencies, and the local-only gateway port.
3. **Show `ignition-cli` (2 min):** `./scripts/work-order-demo.sh cli` demonstrates gateway status and a healthy `work_order_demo` JDBC connection. `ign --profile agentic-ignition --json project list` is another useful read-only command. The CLI profile uses `IGNITION_TOKEN` from the ignored token file, not a displayed command-line token. Do **not** use `ign testing run` on this sample: the older nested test scaffold returns a false green on zero tests; the separate `work-order-tests` route enforces `total > 0`.
4. **Open Perspective (2 min):** [Local operator screen](http://127.0.0.1:8088/data/perspective/client/example-project/work-orders). Click **Triage WO-1042**. The Perspective event calls gateway Jython, which fetches the simulated CMMS HTTP API and upserts into PostgreSQL. Confirm `WO-1042 | Mixer-7 | Expedite` and the vibration summary. `./scripts/work-order-demo.sh db` confirms the persisted row. Refreshing the browser alone does not re-fetch; clicking is intentional.
5. **Make a small agent-authored change (4 min):** Open `projects/example-project/ignition/script-python/work_order_demo/code.py` and ask an agent to change the classification of `high` / `open` from `Expedite` to `Review urgently`, updating the expected results in `projects/example-project/ignition/script-python/work_order_tests/code.py` and `projects/example-project/e2e/tests/smoke/work-order.spec.ts` plus the view text expectation. Bump the adjacent Jython `resource.json` version; run `./scripts/work-order-demo.sh test`. Inspect the diff, then revert the change for the next rehearsal. No commit or production connection.
6. **Explain the gates (2 min):** `./scripts/work-order-demo.sh test` runs lint → forced project scan → **7 gateway-native checks** (pure rules + real CMMS HTTP + JDBC write/read) → **3 sample Playwright cases** (auth setup, Home smoke, and the triage interaction). Failures stop the shell command. WebDev `work-order-tests` and `work-order-demo` are intentionally unauthenticated only for this loopback-bound disposable gateway; never publish them.
7. **Show IDE tooling (2 min):** For `ignition-nvim`, run `cd projects/example-project && nvim ignition/script-python/work_order_demo/code.py`; open `com.inductiveautomation.perspective/views/Example/WorkOrders/view.json` too. `:IgnitionInfo` verifies the plugin; use LSP completion/hover for `system.*` in Jython, diagnostics from `ignition-lint`, and the `view.json` code action **Preview view (wireframe)** if installed. `:IgnitionListScripts` and `:IgnitionDecode` apply when editing JSON with embedded scripts. Installed via `{ 'TheThoughtagen/ignition-ide-plugins' }` in lazy.nvim. On this machine the plugin loaded headlessly; interactive LSP/preview behavior was not independently validated. For VS Code, `whiskeyhouse.ignition-dev-tools@0.1.1` activates only when the open workspace contains an Ignition `project.json`. The commissioned sample's manifest is `projects/example-project/project.json`; the stack root is not itself an Ignition project. Open `projects/example-project` (not the stack root), then use the Command Palette: **Ignition: Show Extension Info** and **Ignition: Debug LSP**. These report language-server connectivity and discovered projects. The language-server installation prompt appears only after activation.
8. **Discovery (1 min):** Ask for a real CMMS endpoint/auth contract, sample payload, asset ID mapping, SLAs, database preference and network boundary. Agree on a next slice and an acceptance test.

## Pull-request CI

[GitHub Actions validation](../.github/workflows/validate.yml) runs on pull requests and pushes to `main`. The Gateway + Playwright job starts a fresh Compose stack on an ephemeral Ubuntu runner, verifies the pinned Project Scan Endpoint download, installs browser dependencies, runs the same `./scripts/work-order-demo.sh test` gate (lint, scan, seven in-gateway checks, three sample Playwright cases), and verifies a CI-only Gateway login with a temporary user. It generates credentials per run and tears down the stack afterward. It provisions a signed Git module release to commission the separately versioned sample project. The demo requires Docker, an Ignition trial, the public module release, and Chromium downloads; a failing prerequisite fails the job rather than reporting a misleading zero-test pass. The stack's separate Git-module browser test is **not** part of this job; CI runs the sample's Home and work-order views plus its own CI login smoke.

## Honest boundaries and cleanup

- This is an isolated local simulation; it does **not** call real external systems or use production credentials. The Gateway is a disposable trial with a time limit. The sample includes a pre-existing nested `testing/run` framework that does not load nested modules on this gateway; the validated work-order suite is the flat `work-order-tests` route, not that scaffold.
- The separately versioned sample repository is the project source of truth; the stack owns Compose and CI. **Never import the sample project's ZIP onto this bind-mounted gateway:** overwrite import can delete local `e2e/`, type stubs and Jython source. Edit project files and invoke `./scripts/scan-project.sh` instead.
- To stop services without deleting data: `docker compose down`. Deliberate `down --volumes` destroys this local demo database and gateway state, including the JDBC configuration; do not run during a call.
