# Agentic Ignition Stack

A public, development-only starter for Git-native Ignition 8.3 work with Docker Compose, [`ign`](https://github.com/TheThoughtagen/ignition-cli), [`ignition-mcp`](https://github.com/WhiskeyHouse/ignition-mcp), the bundled [Ignition Claude Code plugin](plugins/ignition-scada), BW Design Group's [Project Scan Endpoint](https://github.com/bw-design-group/ignition-project-scan-endpoint), gateway Jython tests, and Playwright Perspective tests.

## Start here

Read [QUICKSTART.md](QUICKSTART.md). It covers prerequisites, commissioning, the project scan loop, agent setup, testing, security boundaries, and the optional Designer Git module.

## Fast path

```bash
cp .env.example .env
# Edit .env: choose a tested Ignition image and unique local credentials.
./scripts/bootstrap.sh
```

Bootstrap generates and registers a random Ignition 8.3 API token, grants its local automation security level, stages the pinned BW Project Scan module, stages the local Git module when available, uploads/accepts/installs both, and restarts the Gateway. The mounted [`gw-init/git.yaml`](gw-init/git.yaml) commissions the public [`agentic-ignition-example-project`](https://github.com/TheThoughtagen/agentic-ignition-example-project) as `git-example-project`. Generated credentials, config resources, module files, and the runtime clone remain ignored by this repository.

The Compose configuration enables unsigned modules only for this local development gateway. To deploy another module later:

```bash
./scripts/install-module.sh /path/to/module.modl
docker compose --env-file .env restart ignition
```

Install the Claude Code plugin:

```bash
claude plugin marketplace add TheThoughtagen/agentic-ignition-stack
claude plugin install ignition-scada@agentic-ignition-stack
```

From that project, run:

```text
/ignition-scada:init-testing
/ignition-scada:init-e2e
```

The reference project at `projects/example-project/` already includes the generated gateway Jython/WebDev runner, a sample unit test, and the Perspective-aware Playwright scaffold. The same project is published separately and cloned by the Git module as `projects/git-example-project/`, allowing the module workflow to be exercised without writing Git metadata into the embedded reference project. Run the commands above when adding another project. Commit generated source to its owning repository, but not credentials, browser state, or reports.

## Validation

After exporting the local gateway variables from `.env` into your shell:

```bash
set -a; . ./.env; set +a
./scripts/test.sh
```

The validation order is static lint → forced project scan → gateway Jython tests → Playwright. A nonzero test result blocks the command. To validate the Git module's authenticated Gateway page and `/data/git/projects` route independently:

```bash
cd projects/example-project/e2e
IGNITION_URL=http://127.0.0.1:8088 \
  IGNITION_USER="$GATEWAY_ADMIN_USERNAME" \
  IGNITION_PASSWORD="$GATEWAY_ADMIN_PASSWORD" \
  npm run test:git-module
```

## Repository rules

- Git-tracked project files are the source of truth; the running gateway is a disposable development target.
- Pin every runtime/tool version before release.
- Never commit a gateway backup, runtime data, `.modl` artifact, token, password, or test account.
- Never point this stack at a production gateway.
- See [SECURITY.md](SECURITY.md) before reporting a vulnerability.

## Licence

Licensed under [Apache-2.0](LICENSE).
