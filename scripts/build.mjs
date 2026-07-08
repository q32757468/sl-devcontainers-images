import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { join, resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectDir = resolve(__dirname, "..");

const image = process.argv[2] || "universal";
const workspace = `src/${image}`;
const imageName = `sl-${image}-image`;

function run(cmd, args = []) {
  console.log(`\n$ ${cmd} ${args.join(" ")}`);
  const result = spawnSync(cmd, args, { cwd: projectDir, stdio: "inherit" });
  if (result.status !== 0) {
    console.error(`Command failed with exit code ${result.status}`);
    process.exit(result.status);
  }
}

const devcontainer = join(projectDir, "node_modules/.bin/devcontainer");

console.log(`(*) Building image '${imageName}'...`);
run(devcontainer, ["build", "--image-name", imageName, "--workspace-folder", workspace]);

console.log(`(*) Done.`);
