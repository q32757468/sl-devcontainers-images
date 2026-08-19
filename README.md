# sl-devcontainers-images

用于构建和测试本地 Dev Container 基础镜像的项目。目前提供 `universal` 镜像，面向常见的软件开发和 AI Agent 工作流。

## 特性

- 基于 `ubuntu:noble`，默认时区为 `Asia/Shanghai`
- 通过 Dev Container Features 安装和配置：
  - Node.js 24，并额外安装 Node.js 22
  - Python（使用系统提供的 Python 3.12）
  - Rust stable、rust-analyzer、rustfmt、Clippy 和 `rust-src`
  - pnpm 和 uv
  - Claude Code、OpenAI Codex、agent-browser 及对应技能
- 配置 npm、pnpm、pip 和 Cargo 镜像，加快依赖下载
- 提供 VS Code 常用扩展配置
- 为 Cargo、Claude Code 和 Codex 配置持久化卷

## 环境要求

- Linux 或 macOS
- Docker，并启用 BuildKit
- Node.js 和 pnpm
- 可用的 Docker 网络环境

安装项目依赖：

```bash
pnpm install
```

构建和测试脚本依赖 [`@devcontainers/cli`](https://github.com/devcontainers/cli)。

## 快速开始

构建 `universal` 镜像：

```bash
pnpm run build:universal
```

该命令会读取 [`src/universal/.devcontainer/devcontainer.json`](src/universal/.devcontainer/devcontainer.json)，并生成名为 `sl-universal-image` 的本地镜像。

启动容器并运行完整测试：

```bash
pnpm run test:universal
```

测试脚本会自动清理同标签的旧容器，启动新容器，执行 [`src/universal/test-project/test.sh`](src/universal/test-project/test.sh)，最后清理测试容器。

## 项目结构

```text
.
├── scripts/
│   ├── build.mjs                 # 调用 Dev Container CLI 构建镜像
│   └── test.mjs                  # 启动容器并执行测试
├── src/
│   └── universal/
│       ├── .devcontainer/
│       │   ├── Dockerfile        # 基础镜像
│       │   ├── devcontainer.json # Features、用户和 VS Code 配置
│       │   └── local-features/   # 项目维护的本地 Features
│       └── test-project/         # 容器内测试脚本
└── skills/
    └── init-devcontainer/        # 初始化 Compose Dev Container 的 Codex Skill
```

## 添加或修改本地 Feature

本地 Feature 位于 `src/universal/.devcontainer/local-features/`。新增或修改 Feature 前，请先查看并复用公共函数：

```bash
source /usr/local/share/devcontainer-features/utils/utils.sh
```

公共函数包括以远程用户身份执行命令、获取远程用户 Home 目录，以及安装生命周期脚本。修改后重新构建并运行测试：

```bash
pnpm run build:universal
pnpm run test:universal
```

## 注意事项

- `devcontainer.json` 使用宿主机的 `LOGNAME` 作为容器用户，并将 UID/GID 配置为 `1000`；运行命令前请确认该环境变量和 Docker 用户配置符合预期。
- Claude Code 和 Codex 会挂载宿主机对应的配置目录；认证文件不会被写入 Git 仓库。
- 当前 npm、pnpm、pip 和 Cargo 使用的镜像地址写在对应的本地 Feature 中。如需更换，请同步更新 Feature 配置和相关测试。
- 测试依赖 Docker，且会删除带有 `test-container=universal` 标签的旧测试容器。
