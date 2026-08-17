import { spawnSync } from "node:child_process";
import { join, resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectDir = resolve(__dirname, "..");

const image = process.argv[2] || "universal";
const workspace = `src/${image}`;
const idLabel = `test-container=${image}`;
const devcontainer = join(projectDir, "node_modules/.bin/devcontainer");
const testCommand =
  'if [ -f "test-project/test.sh" ]; then cd test-project && exec bash test.sh; else echo "test-project/test.sh not found" >&2; exit 1; fi';

function execute(cmd, args = [], options = {}) {
  return spawnSync(cmd, args, { ...options, cwd: projectDir });
}

function commandError(label, result) {
  const exitCode = result.error ? 1 : result.status ?? 1;
  const detail = result.error
    ? `failed to start: ${result.error.message}`
    : result.signal
      ? `terminated by signal ${result.signal}`
      : `failed with exit code ${exitCode}`;
  const error = new Error(`${label} ${detail}`);
  error.exitCode = exitCode;
  return error;
}

function assertSuccess(label, result) {
  if (result.error || result.status !== 0) {
    throw commandError(label, result);
  }
}

function run(cmd, args = []) {
  console.log(`\n$ ${cmd} ${args.join(" ")}`);
  const result = execute(cmd, args, { stdio: "inherit" });
  assertSuccess(`Command '${cmd}'`, result);
  return result;
}

function cleanupContainers() {
  try {
    const result = execute(
      "docker",
      ["container", "ls", "-a", "-f", `label=${idLabel}`, "-q"],
      { encoding: "utf8" }
    );
    assertSuccess("Listing test containers", result);

    const containerIds = result.stdout?.trim().split(/\s+/).filter(Boolean) ?? [];

    if (containerIds.length > 0) {
      const removeResult = execute("docker", ["rm", "-f", ...containerIds], {
        stdio: "inherit",
      });
      assertSuccess("Removing test containers", removeResult);
    }

    return true;
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    return false;
  }
}

let exitCode = 0;

try {
  // Clean up any previous test container
  console.log(`(*) Cleaning up previous containers...`);
  if (!cleanupContainers()) {
    throw new Error("Could not clean up previous test containers.");
  }

  // Start the container
  console.log(`(*) Starting container...`);
  run(devcontainer, ["up", "--id-label", idLabel, "--workspace-folder", workspace]);

  // Run tests
  console.log(`(*) Running tests...`);
  run(devcontainer, [
    "exec",
    "--workspace-folder",
    workspace,
    "--id-label",
    idLabel,
    "/bin/sh",
    "-c",
    testCommand,
  ]);
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  exitCode = typeof error?.exitCode === "number" ? error.exitCode : 1;
} finally {
  // Always clean up, including when startup or tests fail.
  console.log(`(*) Cleaning up container...`);
  if (!cleanupContainers() && exitCode === 0) {
    exitCode = 1;
  }
}

console.log(`(*) Done.`);
process.exitCode = exitCode;
