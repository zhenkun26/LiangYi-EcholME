# 两仪 / EcholME

A macOS input method derived from [Squirrel](https://github.com/rime/squirrel), powered by [librime](https://github.com/rime/librime). The intended experience pairs Chinese candidates with English subtitles, and English candidates with Chinese subtitles. **Round 1 adds horizontal two-line candidates and example subtitles in both directions. These are ten deterministic examples per direction, not a real translation dictionary or API.**

Minimum deployment target: macOS 14. Swift is the main frontend language. The English product spelling is **EcholME**. This is an independent derivative, not an official Squirrel release.

## English

### Project records

- [Approved full plan](docs/project/PLAN.md): reuse, changes, new modules, rounds, risks, acceptance, and GPL distribution work.
- [Delivery status](docs/project/STATUS.md) and [Round 1 delivery](docs/round1/DELIVERY.md): distinguish implementation, build, installation and actual input.
- [Round 1 key contract](docs/round1/KEY_CONTRACT.md) and [installation/acceptance steps](docs/round1/MANUAL_ACCEPTANCE.md).
- [Runtime acceptance](docs/round0/RUNTIME_ACCEPTANCE.md) and [manual installation/input checks](docs/round0/MANUAL_ACCEPTANCE.md): follow these before enabling an earlier development artifact.
- [Decisions](docs/project/DECISIONS.md) and [Round 0 foundation](docs/round0/FOUNDATION.md): identity, architecture, safe commands, and limitations.
- [Upstream provenance](UPSTREAM.md), [changes](CHANGES_FROM_UPSTREAM.md), and [third-party notices](THIRD_PARTY_NOTICES.md).

### Architecture

```mermaid
flowchart LR
    Host[Host application] <--> IMK[InputMethodKit controller]
    IMK <--> Rime[librime session]
    Rime --> State[Versioned candidate snapshots]
    IMK <--> State
    State --> Panel[Horizontal two-line Squirrel Panel/View]
    Panel --> IMK
    IMK --> Coordinator[Commit coordinator and guarded host adapter]
    Coordinator --> Host
    Examples[Deterministic examples] --> State
    Translation[Future dictionary or isolated API service] -. future rounds .-> State
```

The Squirrel internal module/class names remain to limit divergence. App identity, input sources, notifications, data and logs are independent. Chinese Space/digits keep engine selection/recognizers; English Space commits a token plus one space, and digits extend the token. Return commits raw composition without newline; empty Return belongs to the host. Esc cancels. **Option+Return** submits a ready example only when it matches the verified full commit scope. Tab/Command finalize raw then pass to the host.

Tap Left Shift alone to switch Chinese/English. The input menu's Example translations toggle disables examples and restores direct ASCII passthrough; its state is per controller. Unknown words show `—`; pending results show `…`. No automatic context detection or cloud API is implemented. See the full key contract before testing English punctuation, email/URL/code or Chinese recognizers.

### Build and install

Use full Xcode with the macOS SDK and Python 3. The reviewed build entry point remains `tools/round0.py`; see [Round 1 delivery](docs/round1/DELIVERY.md) for commands, evidence and environment. `python3 -B tools/check_round1.py` runs isolated state/host/layout checks without installing or accessing Rime databases. Its optional `--engine-bundle` uses fresh approved LiangYi validation directories. Do not run the inherited Makefile install/clean/package targets or `action-build.sh` / `action-install.sh` for EcholME: they contain destructive replacement or dynamic dependency operations.

The first-install destination is `~/Library/Input Methods/EcholME.app`. Registration, enabling, selection, and actual input are separate checks. The installer refuses an existing destination; it does not delete, move, or replace an earlier installation. A stale macOS input-source cache may require the user to log out and back in.

Independent paths:

| Purpose | Location |
| --- | --- |
| Input method | `~/Library/Input Methods/EcholME.app` |
| Rime configuration and user dictionary | `~/Library/Application Support/LiangYi/Rime` |
| Logs | `~/Library/Logs/LiangYi` |
| Input-source IDs | `io.github.zhenkun26.inputmethod.EcholME.Hans` / `.Hant` |

The baseline uses Luna Pinyin Simplified, with Stroke as an auxiliary dependency. The traditional input-source entry is an inherited registration mode, not a separately validated traditional-Chinese product. Existing Squirrel configuration is not migrated.

### Permissions, diagnostics, and recovery

Basic IMK input does not require a new Accessibility grant. The optional standalone capability probe reports TIS state and AX role/range capabilities; it never reads document text or requests permission. AX permission for the probe does not establish permission for the IME itself. Development signing is ad hoc; the app is not sandboxed or notarized. The inherited updater is disabled.

The current [installation and acceptance guide](docs/round1/MANUAL_ACCEPTANCE.md) lists pending real-input checks; the [Round 0 record](docs/round0/VERIFICATION.md) preserves historical baseline troubleshooting. A compiled bundle does not by itself prove macOS 14 compatibility, Intel runtime support, coexistence with a running Squirrel, or correct input in every host.

To stop using this development build, select ABC or another working input source, then remove EcholME from the enabled list in System Settings > Keyboard > Text Input. No automated file-removal command is supplied under this project's no-deletion policy. Any removal of the bundle or user data is left to the user, and user dictionaries should be preserved.

### License and contributions

The inherited Squirrel license is [GNU GPL version 3](LICENSE.txt). Original authors and notices are retained; [the original README](docs/upstream/README.squirrel.md) preserves upstream acknowledgments. Dependencies and data keep their own grants. Before any external binary distribution, prepare the exact corresponding source, build scripts, notices, and dependency materials described in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md); a link to upstream alone is not a complete release procedure.

No push or release is authorized by the current Round 1 request. Inherited upstream CI/release jobs are guarded against running in a derived repository. Each later round requires user confirmation.

## 简体中文

两仪是基于 [Squirrel（鼠须管）](https://github.com/rime/squirrel) 和 [librime](https://github.com/rime/librime) 的独立 macOS 输入法衍生项目，英文名为 **EcholME**。目标体验为中文候选下显示英文、英文候选下显示中文。**Round 1 增加横向双行候选及双向示例副标题，每个方向只有 10 条确定性示例，尚未接入真实词典或 API。** 最低部署目标为 macOS 14，前端以 Swift 为主；本项目不是 Squirrel 官方发行版。

### 项目记录与架构

- [完整计划](docs/project/PLAN.md)：复用、改造、新增模块、各轮交付、风险、验收及 GPL 分发事项。
- [交付状态](docs/project/STATUS.md)与[Round 1 交付](docs/round1/DELIVERY.md)：分别报告代码、构建、安装和实际输入。
- [Round 1 按键约定](docs/round1/KEY_CONTRACT.md)与[安装／验收步骤](docs/round1/MANUAL_ACCEPTANCE.md)。
- [运行验收](docs/round0/RUNTIME_ACCEPTANCE.md)与[手动安装／输入检查](docs/round0/MANUAL_ACCEPTANCE.md)：启用旧开发包前先按此核对和更新。
- [技术决策](docs/project/DECISIONS.md)与[本轮基础说明](docs/round0/FOUNDATION.md)：身份、架构、操作命令和限制。
- [上游来源](UPSTREAM.md)、[改动说明](CHANGES_FROM_UPSTREAM.md)与[第三方声明](THIRD_PARTY_NOTICES.md)。

当前链路为宿主应用 → InputMethodKit → librime／英文词组合 → 带版本的候选快照 → 横向双行 Squirrel Panel/View → 统一上屏协调器。内部保留 Squirrel 模块及类名，应用身份、输入源、通知、数据和日志均独立。

中文空格／数字保留引擎选词及识别规则；英文空格提交词及一个空格，数字继续输入。组合中的回车提交原始字母而不换行，空组合回车交给宿主；Esc 取消。**Option+Return** 仅上屏已显示、已就绪且通过完整范围检查的示例译文。Tab／Command 先提交原文再交给宿主。

单独轻按左 Shift 切换中英文。“Example translations” 菜单开关关闭示例时恢复英文直通，其状态仅属于当前控制器。未命中显示 `—`，等待中显示 `…`。自动环境识别与云 API 尚未实现；邮箱、网址、代码和中文识别规则应按完整按键约定验收。

### 构建与安装

需要完整 Xcode、macOS SDK 和 Python 3。已审查的构建入口仍是 `tools/round0.py`，具体命令、环境与证据见 [Round 1 交付](docs/round1/DELIVERY.md)。`python3 -B tools/check_round1.py` 运行独立的状态、宿主适配器和布局检查，不安装输入法，也不访问 Rime 数据库；可选 `--engine-bundle` 使用两仪目录下独立的新验收数据目录。不要使用继承的 Makefile install/clean/package 或 `action-build.sh`、`action-install.sh`，其中包含删除替换或动态依赖操作。

首次安装目标为 `~/Library/Input Methods/EcholME.app`。注册、启用、选中与实际输入分别验收。目标存在时安装器会停止，不删除、移动或覆盖旧安装；系统输入源缓存未刷新时可能需要用户注销后重新登录。

Rime 配置和用户词库位于 `~/Library/Application Support/LiangYi/Rime`，日志位于 `~/Library/Logs/LiangYi`。输入源为 `io.github.zhenkun26.inputmethod.EcholME.Hans` / `.Hant`。本轮使用朙月拼音简化字，笔画作为辅助依赖；繁体输入源入口是继承的注册模式，并不表示已完成独立繁体验收。不会迁移现有 Squirrel 配置。

### 权限、诊断与恢复

基础 IMK 输入不需要新增辅助功能授权。可选的独立能力探针仅报告 TIS 状态、AX 角色及范围能力，不读取文档内容，也不主动请求权限；探针拥有权限不等于输入法拥有权限。开发包使用本地 ad-hoc 签名，未开启沙盒，未公证，继承的自动更新功能已关闭。

当前[安装／验收指南](docs/round1/MANUAL_ACCEPTANCE.md)列出实际输入的待验收项，[Round 0 记录](docs/round0/VERIFICATION.md)保留历史基线的故障排查。编译成功不等于已验证 macOS 14、Intel、与运行中的 Squirrel 共存或所有宿主应用的输入。

如需停用，先切换到 ABC 等可用输入源，再从“系统设置 > 键盘 > 文本输入”移除两仪。遵循本项目不删除文件的约定，不提供自动删除脚本；应用包和用户数据的删除由用户自行决定，并应保留用户词库。

### 许可证与贡献

继承的 Squirrel 许可证为 [GNU GPL 第 3 版](LICENSE.txt)。保留上游作者及声明，[原始 README](docs/upstream/README.squirrel.md)保存完整致谢。依赖和数据分别适用各自许可证。首次对外分发二进制前，必须按[第三方声明](THIRD_PARTY_NOTICES.md)准备对应的完整源码、构建脚本、声明和依赖材料，不能仅以一个上游链接代替发布流程。

本次 Round 1 请求未授权推送或发布。继承的上游 CI/发布任务已限制为仅在上游仓库执行。后续每轮均须用户确认后开始。
