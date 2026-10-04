# Agent instructions

This repository is the local Ignition 8.3 development stack. It works with [`ign`](https://github.com/TheThoughtagen/ignition-cli) and a sample project cloned from GitHub, not a project committed in this repo.

## Required workflow

1. Treat the commissioned clone under `projects/$IGNITION_PROJECT/` as the Ignition project source of truth. That directory is created by the Git module from [`agentic-ignition-example-project`](https://github.com/TheThoughtagen/agentic-ignition-example-project) and is gitignored here. Commit project changes in that sample repository.
2. Do not commit `.env`, runtime gateway data, API tokens, passwords, `.modl` files, test auth state, or browser reports.
3. Before changing an Ignition project, inspect its `project.json` and existing resource conventions.
4. When changing Jython code, update the adjacent `resource.json` version when required so the gateway reloads compiled modules after a project scan.
5. Run `ign lint projects/$IGNITION_PROJECT --strict -- --profile default` after project changes.
6. Run `./scripts/test.sh` after changes that affect gateway or Perspective behavior. That script uses `ign lint`, the Project Scan Endpoint, `ign testing run`, and the sample's Playwright suite. Do not claim a test passed if its scaffold or prerequisites are absent.
7. Do not access, mutate, or configure a production gateway.

## Testing

Use `/ignition:init-testing` in the sample repository to add the Jython framework and WebDev `testing/run` endpoint. Use `/ignition:init-e2e` from a Perspective project to add Playwright. Prefer `ign testing run --project $IGNITION_PROJECT` over curling the WebDev route directly. Gateway tests are the default; run UI tests when Perspective behavior changes.
