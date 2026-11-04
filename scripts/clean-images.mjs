import { spawnSync } from "node:child_process";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectDir = resolve(__dirname, "..");

function runDocker(args, options = {}) {
  return spawnSync("docker", args, {
    cwd: projectDir,
    encoding: "utf8",
    ...options,
  });
}

const listResult = runDocker([
  "image",
  "ls",
  "--filter",
  "reference=vsc-*",
  "--format",
  "{{.Repository}}:{{.Tag}}",
]);

if (listResult.error || listResult.status !== 0) {
  console.error(
    `Failed to list Docker images: ${listResult.error?.message ?? listResult.stderr.trim()}`
  );
  process.exitCode = 1;
} else {
  const images = listResult.stdout.trim().split(/\s+/).filter(Boolean);

  if (images.length === 0) {
    console.log("(*) No vsc-* images found.");
  } else {
    console.log(`(*) Removing ${images.length} vsc-* image(s)...`);
    console.log(`\n$ docker image rm ${images.join(" ")}`);

    const removeResult = runDocker(["image", "rm", ...images], {
      stdio: "inherit",
    });

    if (removeResult.error) {
      console.error(`Failed to remove Docker images: ${removeResult.error.message}`);
      process.exitCode = 1;
    } else if (removeResult.status !== 0) {
      console.error(`Docker image removal failed with exit code ${removeResult.status}.`);
      process.exitCode = removeResult.status ?? 1;
    }
  }
}
