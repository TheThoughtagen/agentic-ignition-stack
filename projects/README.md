# Ignition project source

Create or import each development project under this directory so the local gateway can see it through the Docker bind mount:

```text
projects/
└── <project-name>/
    ├── project.json
    ├── ignition/
    ├── com.inductiveautomation.perspective/
    └── com.inductiveautomation.webdev/
```

Set `IGNITION_PROJECT=<project-name>` in `.env`. From the project root, run the Claude plugin's `/ignition-scada:init-testing` and `/ignition-scada:init-e2e` commands, then commit the generated source files.
