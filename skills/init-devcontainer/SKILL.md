---
name: init-devcontainer
description: Create a Compose-backed Dev Container for sl-universal-image, optionally tailored to a supported environment such as Tauri; preserve existing configs.
---

# Initialize Devcontainer

Create `.devcontainer/devcontainer.json` and `.devcontainer/docker-compose.yml` only when neither file exists. If either file exists, stop without changing it.

Use `<image>` = `sl-universal-image:latest` by default, or the image the user supplies. Derive the project name unless the user supplied one. Derive `<workspace-folder-name>` from the local workspace folder basename.

Select the configuration variant from the environment the user explicitly requests:

- If the user does not specify an environment, use the general configuration.
- If the user specifies `tauri` (case-insensitive), use the Tauri configuration.
- If the user requests another special environment, ask what configuration it requires instead of treating it as Tauri.

## General configuration

Create `devcontainer.json` with exactly:

```json
{
  "name": "<project-name>",
  "dockerComposeFile": "docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
  "mounts": [
    "source=${localWorkspaceFolder},target=/workspaces/${localWorkspaceFolderBasename},type=bind,consistency=cached"
  ]
}
```

Create `docker-compose.yml` with the two shared volumes using their fixed names:

```yaml
services:
  app:
    image: <image>
    command: sleep infinity

volumes:
  sl-config:
    name: sl-config
  sl-cache:
    name: sl-cache
```

## Tauri configuration

Start with the general configuration, then add this property to `devcontainer.json`:

```json
{
  "postCreateCommand": "sudo chown -R \"$(id -u):$(id -g)\" \"${containerWorkspaceFolder}/node_modules\""
}
```

Merge these additions into `docker-compose.yml`:

```yaml
services:
  app:
    volumes:
      - node_modules:/workspaces/<workspace-folder-name>/node_modules

volumes:
  node_modules:
```

Create project-level VS Code settings at `.vscode/settings.json` to disable automatic forwarding of the Tauri development port:

```json
{
  "remote.portsAttributes": {
    "1420": {
      "onAutoForward": "ignore"
    }
  }
}
```

If the file exists, merge this setting while preserving other settings and comments.
