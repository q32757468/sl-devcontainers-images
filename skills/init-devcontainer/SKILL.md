---
name: init-devcontainer
description: Create a Compose-backed Dev Container for sl-universal-image with fixed config and cache volume names; never overwrite existing configs.
---

# Initialize Devcontainer

Create `.devcontainer/devcontainer.json` and `.devcontainer/docker-compose.yml` only when neither file exists. If either file exists, stop without changing it.

Use `<image>` = `sl-universal-image:latest` by default, or the image the user supplies. Derive the project name unless the user supplied one, then create `devcontainer.json` with exactly:

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

Do not inspect image metadata to discover volumes. Validate the JSON and confirm the Compose service, image, command, and exactly the `sl-config` and `sl-cache` named volume declarations. Do not create Docker volumes manually, add an `image` field to `devcontainer.json`, or overwrite either existing file.
