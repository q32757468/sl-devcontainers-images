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

## 持久化卷

- `sl-config` 挂载到 `~/.sl-config`，保存用户配置。
- `sl-cache` 挂载到 `~/.sl-cache`，保存可复用缓存。
- 新增持久化目录时，按用途归入其中一类，并使用 `utils.sh` 的公共函数将原生路径链接到对应卷目录；不要为同一卷增加重复 mount。

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
