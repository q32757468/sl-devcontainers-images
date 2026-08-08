import { spawnSync } from "node:child_process";
import { join, resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectDir = resolve(__dirname, "..");

const image = process.argv[2] || "universal";
const workspace = `src/${image}`;
const idLabel = `test-container=${image}`;

function run(cmd, args = []) {
  console.log(`\n$ ${cmd} ${args.join(" ")}`);
  const result = spawnSync(cmd, args, { cwd: projectDir, stdio: "inherit" });
  if (result.status !== 0) {
    console.error(`Command failed with exit code ${result.status}`);
    process.exit(result.status);
  }
}

function cleanupContainers() {
  const result = spawnSync(
    "docker",
    ["container", "ls", "-f", `label=${idLabel}`, "-q"],
    { cwd: projectDir, encoding: "utf8" }
  );
  const containerIds = result.stdout?.trim().split(/\s+/).filter(Boolean) ?? [];

  if (containerIds.length > 0) {
    spawnSync("docker", ["rm", "-f", ...containerIds], {
      cwd: projectDir,
      stdio: "inherit",
    });
  }
}

const devcontainer = join(projectDir, "node_modules/.bin/devcontainer");

// Clean up any previous test container
console.log(`(*) Cleaning up previous containers...`);
cleanupContainers();

// Start the container
console.log(`(*) Starting container...`);
run(devcontainer, ["up", "--id-label", idLabel, "--workspace-folder", workspace]);

// Run tests
console.log(`(*) Running tests...`);
const testCommand =
  `set -e; if [ -f "test-project/test.sh" ]; then cd test-project; if [ "$(id -u)" = "0" ]; then chmod +x test.sh; else sudo chmod +x test.sh; fi; ./test.sh; else echo "test-project/test.sh not found"; exit 1; fi`;

const execResult = spawnSync(
  devcontainer,
  ["exec", "--workspace-folder", workspace, "--id-label", idLabel, "/bin/sh", "-c", testCommand],
  { cwd: projectDir, stdio: "inherit" }
);

// Clean up
console.log(`(*) Cleaning up container...`);
cleanupContainers();

console.log(`(*) Done.`);

if (execResult.status !== 0) {
  process.exit(execResult.status);
}
