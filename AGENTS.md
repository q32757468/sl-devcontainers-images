# AGENTS.md

## 安装依赖

```bash
pnpm install
```

## 编写本地 Feature

新增或修改本地 Feature 前，先查看 `src/universal/.devcontainer/local-features/utils/utils.sh` 并优先复用其中的公共函数：

```bash
source /usr/local/share/devcontainer-features/utils/utils.sh
```

## 构建

构建 `universal` Dev Container 镜像：

```bash
pnpm run build:universal
```

## 测试

启动 `universal` Dev Container、运行其中的测试脚本，并在结束后清理测试容器：

```bash
pnpm run test:universal
```

测试命令不会自动构建镜像。如果修改了 Dev Container 配置，请先重新构建，再运行测试，以确保测试使用最新的镜像：

```bash
pnpm run build:universal
pnpm run test:universal
```
