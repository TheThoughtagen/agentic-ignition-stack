# Agentic Ignition Stack

A public, development-only starter for Git-native Ignition 8.3 work with Docker Compose, [`ign`](https://github.com/TheThoughtagen/ignition-cli), [`ignition-mcp`](https://github.com/WhiskeyHouse/ignition-mcp), the [Ignition Claude Code plugin](https://github.com/TheThoughtagen/ignition-ide-plugins), BW Design Group's [Project Scan Endpoint](https://github.com/bw-design-group/ignition-project-scan-endpoint), gateway Jython tests, and Playwright Perspective tests.

## Start here

Read [QUICKSTART.md](QUICKSTART.md). It covers prerequisites, commissioning, the project scan loop, agent setup, testing, security boundaries, and the optional Designer Git module.

## Fast path

```bash
cp .env.example .env
# Edit .env: choose a tested Ignition image and unique local credentials.
./scripts/bootstrap.sh
```

Then complete gateway commissioning, create a least-privilege local API token, and create or import a project under `projects/<project-name>/`. Stage the pinned BW Design Group Project Scan Endpoint module, then install it in **Gateway → Config → Modules**:

```bash
# Stage a locally supplied release artifact (verified against the v1.0.0 SHA-256).
./scripts/stage-project-scan-module.sh ~/Downloads/Project-Scan-Endpoint.modl

# Or download the pinned upstream release instead.
./scripts/download-project-scan-module.sh
```

The setup stages the module at `modules/Project-Scan-Endpoint.modl`; it remains ignored by Git. Deploy it through the same Gateway API pipeline used by Whiskey House orchestration:

```bash
set -a; . ./.env; set +a
./scripts/install-module.sh modules/Project-Scan-Endpoint.modl
docker compose --env-file .env restart ignition
```

The Compose configuration enables unsigned modules only for this local development gateway. To add the optional Git module, stage its local build and use the same deployment path:

```bash
./scripts/stage-git-module.sh
./scripts/install-module.sh modules/Git-unsigned.modl
docker compose --env-file .env restart ignition
```

The script reads the module ID/version from its own `module.xml`, accepts required EULA/certificate records, uploads, and requests installation.

Install the Claude Code plugin:

```bash
claude plugin add --from whiskeyhouse/ignition-nvim --path claude-code-plugin
```

From that project, run:

```text
/ignition-scada:init-testing
/ignition-scada:init-e2e
```

The reference project at `projects/example-project/` already includes the generated gateway Jython/WebDev runner, a sample unit test, and the Perspective-aware Playwright scaffold. Run the commands above when adding another project. Commit their generated source, but not their credentials, browser state, or reports.

## Validation

After exporting the local gateway variables from `.env` into your shell:

```bash
set -a; . ./.env; set +a
./scripts/test.sh
```

The validation order is static lint → forced project scan → gateway Jython tests → Playwright. A nonzero test result blocks the command.

## Repository rules

- Git-tracked project files are the source of truth; the running gateway is a disposable development target.
- Pin every runtime/tool version before release.
- Never commit a gateway backup, runtime data, `.modl` artifact, token, password, or test account.
- Never point this stack at a production gateway.
- See [SECURITY.md](SECURITY.md) before reporting a vulnerability.

## Licence

Licensed under [Apache-2.0](LICENSE).
