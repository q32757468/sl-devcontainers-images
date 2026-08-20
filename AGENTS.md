# AGENTS.md

## 安装依赖

```bash
pnpm install
```

## 编写本地 Feature

本地 Feature 位于 `src/universal/.devcontainer/features/src/`。新增或修改本地 Feature 前，先查看 `src/universal/.devcontainer/features/src/utils/utils.sh` 并优先复用其中的公共函数：

```bash
source /usr/local/share/devcontainer-features/utils/utils.sh
```

## 构建

构建 `universal` Dev Container 镜像：

```bash
pnpm run build:universal
```

## 测试

只测试指定的本地 Feature：

```bash
pnpm test:feature <feature>
```

测试全部本地 Features：

```bash
pnpm test:features
```

Feature 测试位于 `src/universal/.devcontainer/features/test/<feature>/`。新增或修改 Feature 时，应同步维护对应的 scenario 和断言脚本。

启动完整 `universal` Dev Container 并运行集成测试：

```bash
pnpm run test:universal
```

日常开发优先运行对应的 Feature 测试；提交前再运行完整 Feature 测试和 `universal` 集成测试。
