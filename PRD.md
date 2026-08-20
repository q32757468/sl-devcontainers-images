# Universal Dev Container Feature 分层测试改造 PRD

## 1. 文档信息

- 状态：已实施
- 适用项目：`sl-devcontainers-images`
- 首期范围：`universal` 镜像及其本地 Dev Container Features
- 目标读者：项目维护者、Feature 开发者、CI 维护者

## 2. 背景

当前 `universal` 镜像的测试由 `pnpm run test:universal` 统一执行。该命令启动完整 Dev Container，并运行 `src/universal/test-project/test.sh` 中的所有断言。

现有方式能够验证最终镜像，但存在以下问题：

1. 所有测试集中在单个脚本中，Feature 与其测试之间缺少清晰归属。
2. 修改一个本地 Feature 后，仍需启动完整环境并执行全部测试。
3. Feature 开发过程中反复修改、构建和测试的反馈周期较长。
4. 无法通过统一命令选择单个 Feature，也不便于 CI 根据变更范围选择测试。
5. 部分 Feature 的功能缺少独立断言，现有测试覆盖情况不易识别。

需要注意，选择性执行测试断言并不等同于选择性构建：如果修改了 Feature 的安装逻辑，必须将修改后的 Feature 安装到新的测试环境中，测试结果才有效。因此，本次改造需要同时解决测试组织和最小化构建范围两个问题。

## 3. 目标

### 3.1 核心目标

1. 支持通过统一命令测试指定的单个本地 Feature。
2. 支持通过统一命令测试全部本地 Features。
3. 保留完整 `universal` 镜像的集成测试。
4. 将 Feature 测试与 Feature 源码建立清晰、可维护的对应关系。
5. 单 Feature 测试仅安装该 Feature 及其必要依赖，不构建完整 `universal` 镜像。
6. 测试失败时，输出明确的 Feature、测试项和失败原因，并返回非零退出码。
7. 为后续按变更范围选择 CI 测试提供稳定接口。

### 3.2 预期效果

- 修改 `rust` Feature 后，可通过 `pnpm test:feature rust` 获得快速反馈。
- 提交前可通过 `pnpm test:features` 测试所有本地 Features。
- 需要验证最终组合效果时，继续运行 `pnpm test:universal`。
- 新增 Feature 时，测试位置、依赖声明和运行方式有统一约定。

## 4. 非目标

本次首期改造不包含：

1. 发布本地 Features 到 OCI Registry。
2. 为外部 Features 建立完整兼容性测试矩阵。
3. 完全消除 Docker 镜像构建；安装脚本变更仍需要重新构建测试环境。
4. 修改 `universal` 镜像已有软件版本或安装行为。
5. 首期自动解析 Git diff 并选择测试；仅为该能力预留命令接口。
6. 使用常驻容器替代所有测试环境。容器复用可作为后续优化，但不能成为测试正确性的前提。

## 5. 用户场景

### 5.1 开发单个 Feature

开发者修改 `rust/install.sh` 后执行：

```bash
pnpm test:feature rust
```

系统应创建只包含 `rust` 及其必要依赖的测试环境，运行 `rust` 的测试，并清理临时容器。

### 5.2 测试所有本地 Features

开发者执行：

```bash
pnpm test:features
```

系统应依次或由 Dev Container CLI 调度全部本地 Feature 测试，并汇总结果。

### 5.3 验证完整镜像

开发者执行：

```bash
pnpm test:universal
```

系统应使用完整 `universal` 配置启动容器，执行基础镜像和 Feature 组合后的集成测试，并在结束后清理容器。

### 5.4 指定多个 Features

如实现成本可控，命令应支持一次指定多个 Feature：

```bash
pnpm test:feature rust uv
```

多个名称表示分别执行这些 Feature 的测试，而不是默认将它们组合进同一个场景。Feature 组合行为应由显式 scenario 定义。

## 6. 总体方案

采用两层测试模型：

| 层级 | 目的 | 构建范围 | 建议命令 |
| --- | --- | --- | --- |
| Feature 测试 | 快速验证单个 Feature 的安装结果和行为 | Feature 及必要依赖 | `pnpm test:feature <name>` |
| Universal 集成测试 | 验证最终镜像、安装顺序、生命周期和 Feature 交互 | 完整 `universal` 镜像 | `pnpm test:universal` |

Feature 测试优先使用 Dev Container CLI 内置的 `devcontainer features test`，以复用其 Feature 构建、场景配置、选择性执行和容器清理能力。

## 7. 目录结构

建议将可独立测试的 Feature 集合调整为 Dev Container CLI 兼容的镜像目录结构：

```text
.
├── scripts/
│   ├── build.mjs
│   ├── test.mjs
│   └── test-feature.mjs
└── src/
    └── universal/
        ├── .devcontainer/
        │   ├── Dockerfile
        │   ├── devcontainer.json
        │   └── features/
        │       ├── src/
        │       │   ├── test-base/  # 仅供测试场景使用，不进入 Universal
        │       │   ├── utils/
        │       │   ├── rust/
        │       │   └── ...
        │       └── test/
        │           ├── utils/
        │           ├── rust/
        │           │   ├── rust.sh
        │           │   └── scenarios.json
        │           └── ...
        └── test-project/
            ├── test.sh
            └── test-utils.sh
```

说明：

1. `.devcontainer/features/src/<feature>` 存放 Feature 实现。
2. `.devcontainer/features/test/<feature>` 存放对应 Feature 的测试。
3. 测试不直接放入 Feature 源码目录，避免测试文件影响 Feature 打包内容和构建缓存。
4. `src/universal/.devcontainer/devcontainer.json` 引用 `./features/src` 下的本地 Features。
5. `src/universal/test-project` 保留，只负责完整镜像的基础及集成测试。
6. `test-base` 是内部测试 fixture，由运行脚本排除，不作为可选择或生产使用的 Feature。

Feature 项目保留在 `.devcontainer` 内，避免扩大现有 Docker build context，同时满足 Dev Container CLI 对 `src` 与 `test` 镜像结构的约定。

## 8. 命令接口

### 8.1 package.json

预期增加以下脚本：

```json
{
  "scripts": {
    "build:universal": "node scripts/build.mjs universal",
    "test:feature": "node scripts/test-feature.mjs",
    "test:features": "node scripts/test-feature.mjs --all",
    "test:universal": "node scripts/test.mjs universal"
  }
}
```

### 8.2 单 Feature 测试

```bash
pnpm test:feature rust
```

要求：

1. 至少接受一个 Feature 名称。
2. 未指定名称时输出帮助信息并返回非零退出码。
3. 指定不存在的 Feature 时，在构建前失败，并输出可用 Feature 列表。
4. 退出码透传 Dev Container CLI 的测试结果。
5. 保留完整的构建和测试日志。

### 8.3 多 Feature 测试

```bash
pnpm test:feature rust uv pnpm
```

要求：

1. 支持空格分隔的 Feature 名称。
2. 失败时明确指出失败的 Feature。
3. 是否在首个失败后停止可由实现阶段决定；默认建议执行完已选择项后汇总失败结果。

### 8.4 全量 Feature 测试

```bash
pnpm test:features
```

要求：

1. 自动发现 `features/src` 下的 Features。
2. 排除以下划线开头的内部目录。
3. 每个需要发布或使用的 Feature 必须有对应测试；缺失测试时应失败，而不是静默跳过。

### 8.5 Universal 集成测试

现有命令保持兼容：

```bash
pnpm test:universal
```

首期不改变其“启动完整环境、执行测试、清理容器”的语义。

## 9. Feature 测试约定

### 9.1 测试脚本

每个 Feature 至少提供：

```text
src/universal/.devcontainer/features/test/<feature>/<scenario>.sh
```

基本要求：

1. 使用 Bash 执行。
2. 任一关键断言失败时最终返回非零退出码。
3. 测试输出包含稳定、可检索的测试名称。
4. 不依赖宿主机已有认证信息或用户私有配置。
5. 不访问非必要的外部服务；能够离线验证的行为优先离线验证。
6. 创建的临时文件和进程应在测试结束时清理。
7. 测试脚本不得修改 Feature 源码或宿主工作区状态。

### 9.2 公共测试工具

Feature 测试使用 Dev Container CLI 提供的 `dev-container-features-test-lib`，统一复用 `check` 与 `reportResults` 等函数。Universal 集成测试继续使用 `src/universal/test-project/test-utils.sh`；两类测试的运行环境和关注层级不同，首期不再额外维护一份 `_lib` 副本。

### 9.3 测试隔离

每个 Feature 测试应在独立容器中运行，除非多个 Feature 的组合是该场景明确要验证的内容。不得依赖之前某个测试容器遗留的安装结果。

## 10. Feature 依赖和测试场景

当前多个本地 Feature 依赖 `utils` 提供的：

```bash
source /usr/local/share/devcontainer-features/utils/utils.sh
```

此外，`pnpm`、`codex`、`claude-code` 和 `agent-skills` 等 Feature 还依赖 Node.js 或 pnpm。单 Feature 测试必须显式安装其必要依赖。

建议初步依赖关系如下，最终以实现和测试结果为准：

| Feature | 最小测试依赖 |
| --- | --- |
| `utils` | 无 |
| `patch-node` | `utils`，外部 Node Feature |
| `patch-python` | `utils`，外部 Python Feature |
| `uv` | 无或系统 Python，按断言确定 |
| `rust` | `utils` |
| `pnpm` | `utils`，外部 Node Feature |
| `agent-skills` | `utils`、外部 Node Feature、`pnpm` |
| `claude-code` | `utils`、外部 Node Feature、`pnpm` |
| `codex` | `utils`、外部 Node Feature、`pnpm` |

复杂依赖和 Feature 组合使用 `scenarios.json` 描述。例如：

```json
{
  "rust": {
    "image": "ubuntu:noble",
    "features": {
      "./src/utils": {},
      "./src/rust": {}
    }
  }
}
```

实现时需要确认 Dev Container CLI 对本地 Feature 相对路径的解析方式，并使用其支持的 scenario 格式。

`installsAfter` 只表示安装顺序，不应被视为自动安装依赖。确实无法独立工作的 Feature 应评估是否需要通过 `dependsOn` 声明硬依赖。

## 11. 初始测试拆分建议

将当前 `src/universal/test-project/test.sh` 中的断言按以下方式迁移或保留：

| 测试内容 | Feature 测试归属 | Universal 是否保留 |
| --- | --- | --- |
| 非 root 用户、locale、timezone、sudo、bash | 基础/全局场景 | 是 |
| 系统软件包 | 基础/全局场景 | 是 |
| Node、npm、nvm、版本数量和默认版本 | 外部 Node 集成或 `patch-node` scenario | 是，保留精简冒烟测试 |
| npm 镜像配置 | `patch-node` | 否或仅冒烟检查 |
| Python、pip、Python 版本 | 外部 Python 集成或 `patch-python` scenario | 是，保留精简冒烟测试 |
| pip 镜像配置 | `patch-python` | 否或仅冒烟检查 |
| pnpm 命令和 registry | `pnpm` | 是，仅检查命令可用 |
| uv 命令和创建虚拟环境 | `uv` | 是，仅检查命令可用 |
| Rust 工具、组件、toolchain、Cargo 配置 | `rust` | 是，保留核心命令冒烟测试 |
| Codex 命令、配置目录和生命周期脚本 | `codex` | 是，验证最终生命周期效果 |
| Claude Code 命令、设置和 skills 链接 | `claude-code` | 是，验证最终生命周期效果 |
| agent-browser 命令和离线页面 | `agent-skills` | 是或保留简化检查 |

原则：

- Feature 测试负责详细验证该 Feature 的安装产物和配置。
- Universal 测试负责验证最终组合仍然可用，不重复所有详细断言。

## 12. 缓存与性能要求

### 12.1 构建缓存

1. 保留 BuildKit 缓存，不主动执行无缓存构建。
2. 不在普通测试流程中执行 Docker 全局清理。
3. Feature 测试仅改变对应 Feature 或 scenario 时，应尽可能复用基础镜像和依赖层。
4. 测试脚本修改不应导致 Feature 安装内容发生变化或触发无必要的 Feature 重新打包。

### 12.2 容器生命周期

默认行为应保证测试隔离：

1. 测试开始前处理同一测试产生的残留容器。
2. 测试结束后清理容器，包括失败路径。
3. 不删除用户手动创建且没有测试专用标签的容器。

可在后续版本增加 `--preserve-test-containers` 或 `--reuse` 调试选项，但必须显式启用，不作为默认行为。

### 12.3 性能基线

实施前应记录以下基线：

- 完整 `pnpm test:universal` 的冷缓存耗时。
- 完整 `pnpm test:universal` 的热缓存耗时。
- 修改单个 Feature 后的构建和测试耗时。

实施后至少记录：

- `pnpm test:feature rust` 的冷、热缓存耗时。
- `pnpm test:features` 的总耗时。
- `pnpm test:universal` 的耗时和改造前差异。

首期不设置绝对秒数指标；验收时要求单 Feature 热缓存测试显著快于完整 Universal 测试，并记录实际数据。

## 13. 错误处理与输出

命令输出至少应包含：

1. 当前测试的 Feature 名称。
2. 使用的基础镜像或 scenario 名称。
3. 构建阶段与断言执行阶段的区分。
4. 失败的测试脚本和退出码。
5. 全量测试结束时的成功、失败和跳过数量。

示例：

```text
(*) Testing feature 'rust'...
(*) Scenario: rust
✅ rustc
✅ cargo
❌ cargo-config

Failed features: rust
```

不得吞掉 Dev Container CLI 或 Docker 的原始错误输出。

## 14. CI 策略

### 14.1 首期

1. Pull Request 至少运行 `pnpm test:features`。
2. Pull Request 或合并前运行 `pnpm test:universal`。
3. 两层测试任一失败均阻止合并。

### 14.2 后续优化

根据 Git diff 选择测试：

- 修改 `features/src/rust/**` 或 `features/test/rust/**`：运行 `rust` 及显式依赖它的场景。
- 修改公共 `utils`：运行所有依赖 `utils` 的 Features。
- 修改 `Dockerfile`、`devcontainer.json`、公共测试工具或构建脚本：运行全部 Feature 测试和 Universal 集成测试。
- 修改文档：可跳过容器测试。

无论选择性测试是否启用，主分支定时任务应定期执行全量 Feature 和 Universal 测试，以发现基础镜像、外部 Feature 或上游工具更新带来的问题。

## 15. 兼容性要求

1. `pnpm run build:universal` 保持可用。
2. `pnpm run test:universal` 保持可用，且默认仍执行完整集成测试。
3. `devcontainer.json` 使用本地 Feature 的行为和安装顺序保持不变。
4. Feature 目录迁移后，镜像内 `/usr/local/share/devcontainer-features/...` 的运行时路径保持不变。
5. 不更改当前容器远程用户、UID/GID、挂载卷、软件版本和 registry 配置。
6. Linux 为首要支持平台；不得引入依赖 GNU 特有宿主命令且 macOS 明确不可用的包装逻辑，除非文档注明限制。

## 16. 迁移计划

### 阶段一：建立测试框架

1. 创建 Feature 测试目录结构。
2. 增加 `scripts/test-feature.mjs` 和 package scripts。
3. 建立公共测试工具。
4. 先迁移一个依赖简单的 Feature，例如 `uv`，验证完整链路。

### 阶段二：迁移全部本地 Features

1. 逐个迁移现有断言。
2. 为 `patch-node`、`patch-python`、`pnpm` 补充 registry 配置测试。
3. 为 `claude-code`、`codex` 补充安装和生命周期测试。
4. 为依赖其他 Features 的测试建立 scenarios。

### 阶段三：精简集成测试

1. 保留基础系统检查。
2. 每个关键工具保留一个最终可用性冒烟检查。
3. 保留安装顺序、远程用户、挂载卷和生命周期相关检查。
4. 删除与 Feature 单元测试完全重复且不提供组合验证价值的断言。

### 阶段四：CI 优化

1. CI 同时接入 Feature 和 Universal 测试。
2. 记录耗时基线。
3. 后续增加基于变更范围的选择性测试矩阵。

## 17. 验收标准

完成首期改造必须满足：

1. `pnpm test:feature <有效名称>` 能独立测试指定 Feature。
2. `pnpm test:feature <无效名称>` 在构建前失败，并给出可用名称。
3. `pnpm test:features` 能测试所有本地 Features，并正确汇总结果。
4. 人为破坏任一 Feature 的核心安装结果时，其独立测试能够失败。
5. 单 Feature 测试不会无条件构建完整 `universal` 镜像。
6. `pnpm test:universal` 继续验证完整镜像并通过。
7. 测试成功和失败后均不遗留无标识的临时容器。
8. Feature 测试文件的修改不会改变发布或安装的 Feature 内容。
9. README 和 AGENTS.md 中的构建、全量测试及单 Feature 测试说明保持一致。
10. 记录改造前后的实际耗时，确认单 Feature 开发反馈周期得到明显缩短。

## 18. 风险与应对

### 18.1 Feature 依赖未显式声明

风险：Feature 在完整 Universal 镜像中正常，但独立测试因缺少 `utils`、Node 或 pnpm 而失败。

应对：先通过 scenario 显式构造最小依赖；确认属于运行所必需的硬依赖后，再评估 `dependsOn`。

### 18.2 目录迁移影响相对路径

风险：移动 Feature 后，`devcontainer.json`、安装脚本或生命周期脚本中的相对路径失效。

应对：分批迁移，每迁移一个 Feature 同时运行其独立测试和 Universal 集成测试。

### 18.3 单 Feature 测试与最终镜像环境不一致

风险：最小场景通过，但完整镜像因顺序或环境冲突失败。

应对：保留 Universal 集成测试；Feature 测试不能替代最终组合测试。

### 18.4 上游依赖导致测试不稳定

风险：外部 Feature、安装脚本或包管理器的最新版本变化导致结果波动。

应对：继续使用 lockfile；测试中避免不必要的联网行为；CI 保留完整日志；对可固定版本的测试依赖进行固定。

### 18.5 全量 Feature 测试仍然耗时

风险：所有独立 Feature 场景分别构建，首次冷缓存运行时间可能增加。

应对：本地开发默认运行指定 Feature；CI 使用矩阵并行执行；复用 BuildKit 缓存；完整 Feature 测试作为提交前或 CI 验证。

## 19. 实施决策与后续评审事项

1. 已决定将本地 Features 移动到 `src/universal/.devcontainer/features/src`，保持现有 Docker build context。
2. 单次指定多个 Features 时，是独立执行并汇总，还是组合为一个测试容器？本 PRD 建议独立执行。
3. 首期是否需要支持保留测试容器用于调试？
4. CI 首期是否立即接入，还是先仅提供本地命令？
5. Universal 集成测试在首期是否同步精简，还是待所有 Feature 测试稳定后再精简？本 PRD 建议后者。
6. Feature 硬依赖是否使用 `dependsOn`，还是全部仅在测试 scenario 中声明？
7. 是否需要为外部 Node、Python Features 建立单独的集成测试名称？

## 20. 后续可能需求

以下能力不纳入首期，但目录和命令设计应避免阻碍其实现：

- `pnpm test:changed`：根据 Git diff 自动选择 Features。
- 并行运行多个 Feature 测试。
- 按基础镜像建立兼容性矩阵。
- 保存或复用测试容器进行交互式调试。
- 输出 JUnit 或其他机器可读测试报告。
- 在 CI 中上传构建耗时、缓存命中情况和测试报告。
