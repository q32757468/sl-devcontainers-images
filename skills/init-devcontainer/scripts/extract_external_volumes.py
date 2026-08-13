#!/usr/bin/env python3
"""Extract named volume mounts from a Dev Container image metadata label."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any, Iterable


DEFAULT_IMAGE = "sl-universal-image:latest"


def load_metadata(image: str, metadata_json: str | None, metadata_file: Path | None) -> Any:
    if metadata_json is not None:
        raw_metadata = metadata_json
    elif metadata_file is not None:
        raw_metadata = metadata_file.read_text(encoding="utf-8")
    else:
        result = subprocess.run(
            [
                "docker",
                "image",
                "inspect",
                image,
                "--format",
                '{{ index .Config.Labels "devcontainer.metadata" }}',
            ],
            check=False,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            message = result.stderr.strip() or f"docker image inspect exited with {result.returncode}"
            raise RuntimeError(message)
        raw_metadata = result.stdout

    raw_metadata = raw_metadata.strip()
    if not raw_metadata or raw_metadata == "<no value>":
        raise ValueError(f"image {image!r} has no devcontainer.metadata label")

    try:
        return json.loads(raw_metadata)
    except json.JSONDecodeError as error:
        raise ValueError(f"devcontainer.metadata is not valid JSON: {error}") from error


def iter_mount_specs(metadata: Any) -> Iterable[Any]:
    if isinstance(metadata, list):
        for item in metadata:
            yield from iter_mount_specs(item)
        return

    if not isinstance(metadata, dict):
        return

    mounts = metadata.get("mounts", [])
    if isinstance(mounts, list):
        yield from mounts
    elif isinstance(mounts, (dict, str)):
        yield mounts


def volume_name(mount: Any) -> str | None:
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


def extract_volume_names(metadata: Any) -> list[str]:
    names = {name for mount in iter_mount_specs(metadata) if (name := volume_name(mount))}
    return sorted(names)


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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Print a Compose volumes block for named volume mounts in devcontainer.metadata."
    )
    parser.add_argument("image", nargs="?", default=DEFAULT_IMAGE, help="Image to inspect (default: %(default)s)")
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--metadata-json", help="Use this metadata JSON instead of inspecting Docker.")
    source.add_argument("--metadata-file", type=Path, help="Read metadata JSON from this file instead of inspecting Docker.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        metadata = load_metadata(args.image, args.metadata_json, args.metadata_file)
        print(render_volumes(extract_volume_names(metadata)))
    except (OSError, RuntimeError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
