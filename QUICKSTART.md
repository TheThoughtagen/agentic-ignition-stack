# Agentic Ignition Stack — QUICKSTART

Run an Ignition 8.3 development gateway locally, keep the project in Git, and give an AI coding agent a safe feedback loop: lint locally, exercise the gateway, then validate the UI in a real browser.

> **This is a development stack.** Do not expose its gateway, API token, WebDev endpoints, or test credentials to the public internet. Production deployment, identity, secrets management, and network design are deliberately out of scope.

## What this starter provides

| Layer | Included tool | Why it is here |
| --- | --- | --- |
| Local gateway | Docker Compose + Ignition | A repeatable development environment |
| Gateway control | [`ign`](https://github.com/TheThoughtagen/ignition-cli) | Scriptable gateway operations, health checks, project work, and Docker rigs |
| AI gateway access | [`ignition-mcp`](https://github.com/WhiskeyHouse/ignition-mcp) | A scoped MCP interface to the Ignition 8.3 REST API |
| Agent domain knowledge | [`ignition-ide-plugins`](https://github.com/TheThoughtagen/ignition-ide-plugins) Claude Code plugin | Ignition API context, expressions, linting, and test scaffolds |
| Fast project reload | [Project Scan Endpoint](https://github.com/bw-design-group/ignition-project-scan-endpoint) | A REST endpoint that asks the gateway to rescan project files after an edit |
| Static quality gate | [`ignition-lint`](https://github.com/TheThoughtagen/ignition-lint) | Validates Jython, Perspective, bindings, tags, and project conventions before runtime |
| Gateway tests | Plugin-generated gateway test scaffold | Exercises scripts against the running development gateway |
| Browser tests | Plugin-generated Playwright scaffold | Validates Perspective behavior in Chromium against the running gateway |
| Optional Designer Git UX | [`ignition-git-module`](https://github.com/TheThoughtagen/ignition-git-module) | Lets Designer users work with the same repository without changing the default workflow |

The public repository should **reference or download released modules**; it should not commit `.modl` binaries, gateway backups, gateway databases, licences, API tokens, or `.env` files.

## Before you start

Install:

- Git
- Docker Desktop (Windows users: use the WSL 2 engine)
- Node.js LTS (needed for Playwright and Claude Code)
- Python 3.10+ plus `pip` or `uv` (for `ignition-lint` and `ignition-mcp`)
- [Claude Code](https://code.claude.com/docs/en/quickstart) or another coding agent
- An Ignition **8.3** development licence or trial gateway

Use an isolated local gateway. The API token and WebDev endpoints used by the tools below have powerful access and are not suitable for a shared or production gateway.

## 1. Create your repository from this starter

Create a public GitHub repository from this template, then clone it:

```bash
git clone https://github.com/<your-org>/agentic-ignition-stack.git
cd agentic-ignition-stack
cp .env.example .env
```

Recommended repository shape:

```text
.
├── docker-compose.yml                 # local gateway definition; version-pinned image
├── .env.example                       # variable names only, never credentials
├── gw-init/git.yaml                   # Git-module sample commissioning map
├── projects/                          # Git-tracked Ignition project source
│   └── <project-name>/
│       ├── ignition/                  # generated Jython test framework lives here
│       ├── com.inductiveautomation.webdev/  # generated testing/run endpoint
│       └── e2e/                       # generated Playwright scaffold
├── gateway/                           # ignored runtime state, except safe bootstrap files
├── modules/                           # ignored downloaded .modl release artifacts
├── scripts/
│   ├── bootstrap.sh                   # checks prerequisites and starts the gateway
│   ├── scan-project.sh                # calls the Project Scan Endpoint
│   └── test.sh                        # lint → gateway tests → Playwright
├── .mcp.json.example                  # no secrets; local MCP endpoint only
├── CLAUDE.md                          # project conventions and required checks for agents
└── QUICKSTART.md
```

### Non-negotiable `.gitignore` rules

Ignore at least:

```gitignore
.env
gateway/data/
gateway/logs/
gateway/db/
modules/*.modl
playwright-report/
test-results/
node_modules/
__pycache__/
```

Commit authored project assets, compose/configuration templates, scripts, tests, and documentation. Do not commit generated gateway state.

## 2. Bring up the development gateway

The starter pins `inductiveautomation/ignition:8.3.9` in `.env.example`; retain that explicit version until your team deliberately tests an upgrade. Do not rely on a floating `latest` tag. The Compose file should:

1. accept the Ignition EULA only through a local environment variable,
2. bind-mount `./projects` into the gateway project directory,
3. mount `./gw-init/git.yaml` so the Git module can commission its sample project,
4. keep the rest of the gateway state in an ignored local directory or named Docker volume,
5. publish the local gateway port only to the development machine, and
6. use a local-only development administrator password supplied via `.env`.

Start it:

```bash
docker compose up -d
docker compose logs -f ignition
```

Bootstrap creates a random local API token, stores the plaintext only in ignored `secrets/ignition-api-token`, registers its hash as an Ignition 8.3 config resource, and pre-seeds the required local automation permissions. No manual token creation is required.

Verify the gateway before proceeding:

```bash
ign doctor
```

`ign` uses the complete `name:key` API-token value for Ignition 8.3 `/data` routes. Store that value in `.env` or your operating system secret store—never in Git.

## 3. Install the project-update loop

Download the pinned release artifact for BW Design Group's **Project Scan Endpoint**, then install it through **Gateway → Config → Modules → Install or Upgrade a Module**:

```bash
./scripts/download-project-scan-module.sh
```

The binary is ignored by Git. Do not build or distribute the module from this starter unless you own the signing process.

Confirm the module is present:

```bash
curl --fail \
  -H "X-Ignition-API-Token: $(cat secrets/ignition-api-token)" \
  "http://127.0.0.1:8088/data/project-scan-endpoint/confirm-support"
```

After an agent or developer changes files under `projects/`, rescan them:

```bash
curl --fail --request POST \
  -H "X-Ignition-API-Token: $(cat secrets/ignition-api-token)" \
  "http://127.0.0.1:8088/data/project-scan-endpoint/scan?updateDesigners=true&forceUpdate=true"
```

Put this call behind `scripts/scan-project.sh`; the script must fail if required environment variables are missing and must never print the token.

## 4. Install the agent tooling

Install the static quality gate:

```bash
python -m pip install ignition-lint-toolkit
ignition-lint --project projects/example-project --profile default
```

Install the Claude Code plugin globally:

```bash
claude plugin add --from whiskeyhouse/ignition-nvim --path claude-code-plugin
```

For repository-local agent instructions and auto-lint hooks, use the plugin's reviewed templates from the root of each Ignition project (the directory containing `project.json`). Commit the generated source after review. The plugin's test scaffolds are project-local: gateway testing resources live in the Ignition project and Playwright lives at `<project>/e2e/`.

For gateway-aware AI work, run `ignition-mcp` locally and point the agent at the loopback MCP server. Example `.mcp.json` shape:

```json
{
  "mcpServers": {
    "ignition-mcp": {
      "type": "streamable-http",
      "url": "http://127.0.0.1:8007/mcp"
    }
  }
}
```

Keep gateway credentials in `ignition-mcp`'s ignored `.env`, not in `.mcp.json`. Begin with read-only tools. Add WebDev endpoints only when a workflow truly needs tag values, tag CRUD, historian access, alarms, or gateway-script execution.

## 5. Add the test scaffolds before features

Generate and commit the test scaffold before building application features:

1. Run the plugin's `init-testing` command in the repository root.
2. The gateway scaffold creates the Jython framework, test WebDev endpoints, and type stubs in the Ignition project. Configure it for the **local development gateway** and dedicated test data.
3. Configure Playwright with `baseURL` set to the local Perspective URL and test credentials supplied only at runtime.
4. Add one gateway smoke test and one browser test that proves a Perspective page loads.
5. Make `scripts/test.sh` run checks in this order:

```text
ignition-lint → project scan → gateway tests → Playwright
```

The gateway test layer catches behavior that static analysis cannot. Playwright catches Perspective/UI behavior that neither script tests nor the gateway API can see. Do not let an agent skip either layer when it changes related code.

## 6. Work in small, verifiable loops

A good agent request names the outcome, affected project area, constraints, and checks. For example:

> Add a Perspective view that shows the current mixer state. Reuse existing project conventions, do not change tags outside `Example/Dev`, run `ignition-lint`, rescan the project, run the gateway smoke test and the Playwright smoke test, then show the diff. Do not commit.

Each loop is:

```bash
# 1. Create a feature branch
git switch -c feature/mixer-status

# 2. Make a small change (Designer or agent)
# 3. Validate it
./scripts/test.sh

# 4. Review the source-of-truth change
git status
git diff

# 5. Commit only the reviewed project/test/configuration files
git add projects tests scripts
git commit -m "Add mixer status view"
git push -u origin feature/mixer-status
```

Use pull requests and require the lint and test workflow to pass before merging. Treat the Git repository—not a running gateway—as the source of truth.

## Git inside the Designer

When `GIT_MODULE_SOURCE` resolves to a local module artifact, bootstrap installs the [Ignition Git Module](https://github.com/TheThoughtagen/ignition-git-module). Build the current module source with `mvn clean package -DskipTests` and point `GIT_MODULE_SOURCE` at `git-build/target/Git-unsigned.modl`; older local artifacts may predate the Ignition 8.3 Gateway-route fix. Compose mounts [`gw-init/git.yaml`](gw-init/git.yaml), which maps the public [`agentic-ignition-example-project`](https://github.com/TheThoughtagen/agentic-ignition-example-project) `main` branch to the Ignition project `git-example-project`. On first module startup, it clones into the bind-mounted `projects/` directory; that runtime clone is ignored by this orchestration repository because it has its own Git history.

To configure another project, copy the YAML entry and change its repository URI, branch, project name, and user fields. `ignition_userName` must match the Designer/Gateway account that will perform Git operations. Never put a real password or token in `git.yaml`; use the module's runtime secret mechanism for private remotes.

Use the module only on a disposable local gateway until your team has documented who may commit, pull, switch branches, and resolve conflicts from Designer. Do not let the embedded `projects/example-project/` copy and the commissioned `projects/git-example-project/` clone act as competing sources for the same Ignition project name.

Verify the authenticated Gateway page and backing route with Playwright:

```bash
cd projects/example-project/e2e
npm install
IGNITION_URL=http://127.0.0.1:8088 \
  IGNITION_USER="$GATEWAY_ADMIN_USERNAME" \
  IGNITION_PASSWORD="$GATEWAY_ADMIN_PASSWORD" \
  npm run test:git-module
```

## Publish checklist

Before making the repository public:

- [ ] Replace every placeholder and pin the tested Ignition image, module releases, CLI, and Node/Python versions.
- [ ] Confirm `git grep -nEi '(password|token|secret|api[_-]?key)'` finds no real secret.
- [ ] Confirm no gateway data, backups, `.modl` artifacts, `node_modules`, or test reports are tracked.
- [ ] Add a licence, contribution guide, code of conduct, and security policy.
- [ ] Add a GitHub Actions workflow that runs lint and tests; use GitHub Secrets for test-only credentials.
- [ ] Run the full bootstrap from a clean clone on Windows/WSL and macOS or Linux.
- [ ] State clearly which Ignition versions and modules are supported.

## Reference documentation

- [Ignition Docker image](https://hub.docker.com/r/inductiveautomation/ignition)
- [Ignition 8.3 API collection](https://github.com/inductiveautomation/83-api)
- [`ign` CLI](https://github.com/TheThoughtagen/ignition-cli)
- [`ignition-mcp`](https://github.com/WhiskeyHouse/ignition-mcp)
- [Ignition Dev Tools / Claude Code plugin](https://github.com/TheThoughtagen/ignition-ide-plugins)
- [`ignition-lint`](https://github.com/TheThoughtagen/ignition-lint)
- [BW Project Scan Endpoint](https://github.com/bw-design-group/ignition-project-scan-endpoint)
