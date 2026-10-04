# Ignition project source

Do not commit an Ignition project into this orchestration repository.

`./scripts/bootstrap.sh` installs the Git module and commissions [`agentic-ignition-example-project`](https://github.com/TheThoughtagen/agentic-ignition-example-project) from [`gw-init/git.yaml`](../gw-init/git.yaml) into `projects/$IGNITION_PROJECT/` (default `example-project`). That clone has its own Git history and is gitignored here.

Set `IGNITION_PROJECT` in `.env` to the same value as `ignition_projectName` in `git.yaml`. After bootstrap:

```bash
export IGNITION_TOKEN="$(tr -d '\r\n' < secrets/ignition-api-token)"
ign lint projects/$IGNITION_PROJECT --strict -- --profile default
ign testing run --project "$IGNITION_PROJECT"
```

Application changes belong in the sample repository, not in this stack. To add another project, copy the YAML entry in `gw-init/git.yaml` and update `IGNITION_PROJECT`.
