---
name: init-devcontainer
description: Create a Compose-backed Dev Container with metadata-derived external volumes; default image sl-universal-image, never overwrite existing configs.
---

# Initialize Devcontainer

Create `.devcontainer/devcontainer.json` and `.devcontainer/docker-compose.yml` only when neither file exists. If either file exists, stop without changing it.

Use `<image>` = `sl-universal-image:latest` by default, or the image the user supplies.

1. Run the bundled extractor:

   ```bash
   python3 <skill-directory>/scripts/extract_volumes.py <image>
   ```

   Use its output as the Compose `volumes` block. It invokes `npx --yes --package @devcontainers/cli devcontainer read-configuration` with a temporary image-only configuration, keeps only named `type=volume` mounts, and marks each as `external: true`. `npx` reuses the project's local package when available and downloads it otherwise; the latter requires npm network access. If it fails, do not create partial files. Use `--docker-path podman` when the backend is Podman-compatible.

2. Derive the project name unless the user supplied one, then create `devcontainer.json` with exactly:

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

3. Create `docker-compose.yml` with the extractor output in place of `<volumes-block>`:

   ```yaml
   services:
     app:
       image: <image>
       command: sleep infinity

   <volumes-block>
   ```

Validate the JSON and confirm the Compose service, image, command, and external volume block. Do not create the external Docker volumes, add an `image` field to `devcontainer.json`, or overwrite either existing file.
