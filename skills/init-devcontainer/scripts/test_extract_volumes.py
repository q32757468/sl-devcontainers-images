from __future__ import annotations

import importlib.util
import json
import unittest
from pathlib import Path
from unittest.mock import patch


SCRIPT_PATH = Path(__file__).parent / "extract_volumes.py"


def load_script_module():
    spec = importlib.util.spec_from_file_location("extract_volumes", SCRIPT_PATH)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


extractor = load_script_module()


class ExtractVolumesTests(unittest.TestCase):
    def test_extract_volume_names_supports_cli_mount_objects_and_strings(self):
        configuration = {
            "mounts": [
                {"type": "bind", "source": "/host", "target": "/container"},
                {"type": "volume", "source": "cache"},
                "source=workspace-cache,target=/workspace-cache,type=volume",
                "source=cache,target=/other,type=volume",
            ]
        }

        self.assertEqual(
            extractor.extract_volume_names(configuration),
            ["cache", "workspace-cache"],
        )

    @patch.object(extractor.subprocess, "run")
    def test_read_merged_configuration_uses_temporary_image_config(self, run):
        run.return_value = extractor.subprocess.CompletedProcess(
            args=[],
            returncode=0,
            stdout=json.dumps(
                {"mergedConfiguration": {"mounts": [{"type": "volume", "source": "cache"}]}}
            ),
            stderr="",
        )

        configuration = extractor.read_merged_configuration(
            "example:latest",
            "npx",
            "@devcontainers/cli",
        )

        self.assertEqual(configuration["mounts"][0]["source"], "cache")
        command = run.call_args.args[0]
        self.assertEqual(
            command[:6],
            [
                "npx",
                "--yes",
                "--package",
                "@devcontainers/cli",
                "devcontainer",
                "read-configuration",
            ],
        )
        self.assertIn("--include-merged-configuration", command)
        self.assertIn("--log-format", command)
        config_path = Path(command[command.index("--config") + 1])
        self.assertFalse(config_path.exists())

    @patch.object(extractor.subprocess, "run")
    def test_read_merged_configuration_reports_cli_errors(self, run):
        run.return_value = extractor.subprocess.CompletedProcess(
            args=[], returncode=1, stdout="", stderr="Docker daemon unavailable"
        )

        with self.assertRaisesRegex(RuntimeError, "Docker daemon unavailable"):
            extractor.read_merged_configuration(
                "example:latest",
                "npx",
                "@devcontainers/cli",
            )


if __name__ == "__main__":
    unittest.main()
