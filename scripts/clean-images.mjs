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
    const containers = new Set();
    const runningContainers = new Set();
    let failed = false;

    for (const image of images) {
      for (const [state, options, destination] of [
        ["all", ["--all"], containers],
        ["running", [], runningContainers],
      ]) {
        const containerListResult = runDocker([
          "container",
          "ls",
          ...options,
          "--filter",
          `ancestor=${image}`,
          "--quiet",
        ]);

        if (containerListResult.error || containerListResult.status !== 0) {
          console.error(
            `Failed to list ${state} containers using ${image}: ${containerListResult.error?.message ?? containerListResult.stderr.trim()}`
          );
          process.exitCode = containerListResult.status ?? 1;
          failed = true;
          break;
        }

        for (const container of containerListResult.stdout.trim().split(/\s+/).filter(Boolean)) {
          destination.add(container);
        }
      }

      if (failed) break;
    }

    if (!failed && runningContainers.size > 0) {
      const runningContainerIds = [...runningContainers];
      console.log(`(*) Stopping ${runningContainerIds.length} running container(s)...`);
      console.log(`\n$ docker container stop --time 10 ${runningContainerIds.join(" ")}`);

      const stopContainersResult = runDocker(
        ["container", "stop", "--time", "10", ...runningContainerIds],
        { stdio: "inherit" }
      );

      if (stopContainersResult.error) {
        console.error(`Failed to stop Docker containers: ${stopContainersResult.error.message}`);
        process.exitCode = 1;
        failed = true;
      } else if (stopContainersResult.status !== 0) {
        console.error(`Docker container stop failed with exit code ${stopContainersResult.status}.`);
        process.exitCode = stopContainersResult.status ?? 1;
        failed = true;
      }
    }

    if (!failed && containers.size > 0) {
      const containerIds = [...containers];
      console.log(`(*) Removing ${containerIds.length} container(s) using vsc-* images...`);
      console.log(`\n$ docker container rm ${containerIds.join(" ")}`);

      const removeContainersResult = runDocker(["container", "rm", ...containerIds], {
        stdio: "inherit",
      });

      if (removeContainersResult.error) {
        console.error(`Failed to remove Docker containers: ${removeContainersResult.error.message}`);
        process.exitCode = 1;
        failed = true;
      } else if (removeContainersResult.status !== 0) {
        console.error(
          `Docker container removal failed with exit code ${removeContainersResult.status}.`
        );
        process.exitCode = removeContainersResult.status ?? 1;
        failed = true;
      }
    }

    if (!failed) {
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
}
