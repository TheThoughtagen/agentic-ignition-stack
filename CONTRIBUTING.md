# Contributing

## Development rules

- Make focused changes on a feature branch.
- Keep all secrets and generated gateway state out of Git.
- Pin and document any new runtime dependency.
- Add or update gateway and/or Playwright tests for behavior changes.
- Run `./scripts/test.sh` against a local development gateway before opening a pull request.

## Pull requests

Describe the user-visible change, its affected Ignition version, validation performed, and any required module or gateway setup. Do not include screenshots, logs, backups, or test fixtures containing production data.
