# Agentic Ignition Stack

A public, development-only starter for Git-native Ignition 8.3 work with Docker Compose, [`ign`](https://github.com/TheThoughtagen/ignition-cli), [`ignition-mcp`](https://github.com/WhiskeyHouse/ignition-mcp), the bundled [Ignition Claude Code plugin](plugins/ignition), BW Design Group's [Project Scan Endpoint](https://github.com/bw-design-group/ignition-project-scan-endpoint), gateway Jython tests, and Playwright Perspective tests.

## Start here

Read [QUICKSTART.md](QUICKSTART.md). It covers prerequisites, commissioning, the project scan loop, agent setup, testing, security boundaries, and the optional Designer Git module.

## Fast path

```bash
cp .env.example .env
# Edit .env: choose a tested Ignition image and unique local credentials.
./scripts/bootstrap.sh
```

Bootstrap generates and registers a random Ignition 8.3 API token, grants its local automation security level, stages the pinned BW Project Scan module, downloads the latest [Ignition Git module](https://github.com/WhiskeyHouse/ignition-git-module/releases/latest) release `.modl`, uploads/accepts/installs both, and restarts the Gateway. The mounted [`gw-init/git.yaml`](gw-init/git.yaml) commissions the public [`agentic-ignition-example-project`](https://github.com/TheThoughtagen/agentic-ignition-example-project) as `example-project` under `projects/`. Bootstrap then registers an `ign` profile against the generated token and runs `ign doctor`. Generated credentials, config resources, module files, and the runtime clone remain ignored by this repository.

The Compose configuration enables unsigned modules only for this local development gateway. To deploy another module later:

```bash
./scripts/install-module.sh /path/to/module.modl
docker compose --env-file .env restart ignition
```

Install the Claude Code plugin:

```bash
claude plugin marketplace add TheThoughtagen/agentic-ignition-stack
claude plugin install ignition@agentic-ignition-stack
```

From that project, run:

```text
/ignition:init-testing
/ignition:init-e2e
```

The sample that tests and the demo run against is the Git-module clone of [`agentic-ignition-example-project`](https://github.com/TheThoughtagen/agentic-ignition-example-project), not a second project committed in this repository. After bootstrap it lives at `projects/example-project/` and is gitignored because it has its own history. Commit generated test source in that sample repository. Use `/ignition:init-testing` and `/ignition:init-e2e` when adding another project.

Ignition 8.3.9 will not load a mixed leaf-and-children script library (`testing/resource.json` with `"files": []`, or `starter/code.py` next to `starter/__tests__`), and Playwright needs a Perspective view mapped at `/`. Those assets belong in the sample repository.

## Validation

After exporting the local gateway variables from `.env` into your shell:

```bash
set -a; . ./.env; set +a
./scripts/test.sh
```

With the generic work-order sample, validation runs `ign lint` → forced project scan → seven Gateway-native work-order checks → the sample's Playwright suite. The standalone `ign testing run` command remains available for other projects, but this demo does not use the older nested scaffold that could report zero tests as success. A nonzero test result blocks the command. For local setup and CI details, see [the work-order demo guide](demo/WORK-ORDER-DEMO.md). To validate the Git module's authenticated Gateway page and `/data/git/projects` route independently:

```bash
IGNITION_URL=http://127.0.0.1:8088 \
  IGNITION_USER="$GATEWAY_ADMIN_USERNAME" \
  IGNITION_PASSWORD="$GATEWAY_ADMIN_PASSWORD" \
  ./scripts/run-git-module-ui-test.sh
```

## Record the walkthrough

The checked-in VHS tape records the running Gateway, commissioned Git project, bundled Claude plugin installation, and Playwright validation without displaying credentials or tokens:

```bash
go install github.com/charmbracelet/vhs@v0.11.0
VHS_BIN="$(go env GOPATH)/bin/vhs" ./scripts/record-demo.sh
```

The recorder is pinned to VHS 0.11.0 because VHS 0.12.0 currently exits successfully without rendering its output files.

Generated MP4 and GIF files are written under ignored `artifacts/` so they can be reviewed before being attached to an email or published.

## Repository rules

- Git-tracked stack files plus the commissioned sample repository are the sources of truth; the running gateway is a disposable development target.
- Pin every runtime/tool version before release.
- Never commit a gateway backup, runtime data, `.modl` artifact, token, password, or test account.
- Never point this stack at a production gateway.
- See [SECURITY.md](SECURITY.md) before reporting a vulnerability.

## Licence

Licensed under [Apache-2.0](LICENSE).
