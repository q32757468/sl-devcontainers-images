---
name: configure-devcontainer
description: Configure, update, or review Dev Container files while enforcing this repository's required conventions. Use when working with devcontainer.json, compose.yaml, compose.yml, docker-compose.yaml, docker-compose.yml, or any Docker Compose file referenced by a Dev Container configuration.
---

# Configure Dev Container

Apply the following repository rules whenever creating, modifying, or reviewing a Dev Container configuration.

## Configure external volumes in Docker Compose

Ensure every Docker Compose file used by the Dev Container declares both reusable configuration volumes at the top-level `volumes` key:

```yaml
volumes:
  codex-config:
    external: true
  claude-code-config:
    external: true
```

- Treat both declarations as mandatory whenever Docker Compose is part of the Dev Container configuration.
- Add missing declarations and normalize existing declarations so both use `external: true`.
- Merge these declarations with other top-level volumes; preserve unrelated entries and settings.
- Keep the declarations at the document's top level, not under a service's `volumes` key.
- Do not mount either volume into a service unless the task or existing configuration requires it.

After editing, inspect the complete Compose file and verify that both top-level external volume declarations remain present.
