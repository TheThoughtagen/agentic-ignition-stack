# Security policy

## Supported use

This starter is supported only for local or otherwise isolated development gateways. It is not a production deployment guide.

## Reporting a vulnerability

Do not open a public issue for a suspected security vulnerability or exposed secret. Contact the repository owner privately with:

- a description of the issue,
- reproduction steps or a minimal proof of concept,
- affected version or commit, and
- any proposed mitigation.

The repository owner should acknowledge the report within five business days and coordinate disclosure after a fix is available.

## Secret handling

Never commit `.env`, API tokens, passwords, gateway backups, runtime data, browser auth state, or downloaded module binaries. Immediately revoke and replace any credential that reaches a Git remote or issue tracker.
