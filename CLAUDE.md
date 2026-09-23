# Agent instructions

This repository targets a local, disposable Ignition development gateway.

## Required workflow

1. Treat files under `projects/` as the source of truth.
2. Do not commit `.env`, runtime gateway data, API tokens, passwords, `.modl` files, test auth state, or browser reports.
3. Before changing an Ignition project, inspect its `project.json` and existing resource conventions.
4. When changing Jython code, update the adjacent `resource.json` version when required so the gateway reloads compiled modules after a project scan.
5. Run `ignition-lint --project projects/$IGNITION_PROJECT --profile default` after project changes.
6. Run `./scripts/test.sh` after changes that affect gateway or Perspective behavior. Do not claim a test passed if its scaffold or prerequisites are absent.
7. Do not access, mutate, or configure a production gateway.

## Testing

Use `/ignition:init-testing` to add the Jython framework and WebDev `testing/run` endpoint. Use `/ignition:init-e2e` from a Perspective project to add Playwright. Gateway tests are the default; run UI tests when Perspective behavior changes.
