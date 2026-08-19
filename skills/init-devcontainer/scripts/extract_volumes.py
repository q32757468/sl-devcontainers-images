#!/usr/bin/env python3
"""Extract named volume mounts through the Dev Container CLI."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Iterable


DEFAULT_IMAGE = "sl-universal-image:latest"
DEFAULT_NPX = "npx"
DEFAULT_DEVCONTAINER_PACKAGE = "@devcontainers/cli"


def volume_name(mount: Any) -> str | None:
    """Return the source name when a mount is a named volume."""

    if isinstance(mount, dict):
        mount_type = mount.get("type")
        source = mount.get("source")
    elif isinstance(mount, str):
        fields: dict[str, str] = {}
        for field in mount.split(","):
            key, separator, value = field.partition("=")
            if separator:
                fields[key.strip().lower()] = value.strip()
        mount_type = fields.get("type")
        source = fields.get("source")
    else:
        return None

    if str(mount_type).lower() != "volume" or source is None:
        return None

    source = str(source).strip()
    return source or None


def yaml_key(value: str) -> str:
    if value and all(character.isalnum() or character in "._-" for character in value):
        return value
    return json.dumps(value, ensure_ascii=False)


def render_volumes(names: Iterable[str]) -> str:
    names = list(names)
    if not names:
        return "volumes: {}"

    lines = ["volumes:"]
    for name in names:
        lines.extend([f"  {yaml_key(name)}:", "    external: true"])
    return "\n".join(lines)


def read_merged_configuration(
    image: str,
    npx_path: str,
    devcontainer_package: str,
    docker_path: str | None = None,
) -> dict[str, Any]:
    """Read the image metadata merged by ``devcontainer read-configuration``."""

    with tempfile.TemporaryDirectory(prefix="devcontainer-volume-extractor-") as directory:
        config_path = Path(directory) / "devcontainer.json"
        config_path.write_text(
            json.dumps({"image": image}, ensure_ascii=False),
            encoding="utf-8",
        )

        try:
            command = [
                npx_path,
                "--yes",
                "--package",
                devcontainer_package,
                "devcontainer",
                "read-configuration",
                "--config",
                str(config_path),
                "--include-merged-configuration",
                "--log-format",
                "json",
            ]
            if docker_path:
                command.extend(["--docker-path", docker_path])

            result = subprocess.run(
                command,
                check=False,
                capture_output=True,
                text=True,
            )
        except OSError as error:
            raise RuntimeError(f"failed to start {npx_path!r}: {error}") from error

    if result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip()
        if not message:
            message = f"npx devcontainer read-configuration exited with {result.returncode}"
        raise RuntimeError(message)

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise ValueError(f"devcontainer CLI returned invalid JSON: {error}") from error

    configuration = payload.get("mergedConfiguration")
    if not isinstance(configuration, dict):
        raise ValueError("devcontainer CLI output has no mergedConfiguration object")
    return configuration


def extract_volume_names(configuration: dict[str, Any]) -> list[str]:
    """Return unique named volume sources from a merged configuration."""

    mounts = configuration.get("mounts", [])
    if not isinstance(mounts, list):
        return []

    return sorted({name for mount in mounts if (name := volume_name(mount))})


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Print a Compose volumes block using devcontainer image metadata."
    )
    parser.add_argument(
        "image",
        nargs="?",
        default=DEFAULT_IMAGE,
        help="Image to inspect (default: %(default)s)",
    )
    parser.add_argument(
        "--npx-path",
        default=DEFAULT_NPX,
        help="npx executable (default: %(default)s)",
    )
    parser.add_argument(
        "--devcontainer-package",
        default=DEFAULT_DEVCONTAINER_PACKAGE,
        help="Dev Container CLI package passed to npx (default: %(default)s)",
    )
    parser.add_argument(
        "--docker-path",
        help="Container engine CLI passed to devcontainer (for example: docker or podman)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        configuration = read_merged_configuration(
            args.image,
            args.npx_path,
            args.devcontainer_package,
            args.docker_path,
        )
        print(render_volumes(extract_volume_names(configuration)))
    except (OSError, RuntimeError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
