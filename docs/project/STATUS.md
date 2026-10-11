# LiangYi / EcholME — Delivery Status

Recorded: 2026-10-11, America/New_York.

## Current state

- Plan: **PLAN_APPROVED_AND_COMMITTED**, `041b643`.
- Upstream baseline: **IMPORTED_WITH_HISTORY**, `8b507af`, Squirrel `769ae426f33f500266101a88f694aab0d158e680`.
- Round 0: **CODE_AND_LOCAL_INSTALL_DELIVERED; RUNTIME_ACCEPTANCE_BLOCKED**. This is not a full Round 0 acceptance pass.
- Round 1–6: **NOT_AUTHORIZED_TO_START**. No translation, new composer, cloud API or context auto-switching has been implemented.
- Git: local branch `feat/round-0-foundation`; repository-local `zhenkun26` author with verified GitHub ID-based noreply email; read-only `upstream` remote; no `origin`, push, merge to main or release.

The complete durable plan is [PLAN.md](PLAN.md), decisions are in [DECISIONS.md](DECISIONS.md), and the detailed delivery record is [VERIFICATION.md](../round0/VERIFICATION.md). The implementation delivery is the commit containing this status update; no extra self-referential commit is required.

## Verified scope

| Check | Result | Evidence / limit |
| --- | --- | --- |
| Approved plan and Git ordering | PASS | Plan committed before source import and implementation. |
| Dependency/data preparation | PASS | Fixed sources, sizes, SHA-256, licenses/AUTHORS and prepared-input inventory. |
| Final-source Debug build | PASS | `round0-repro`, Xcode 26.6, macOS 26.5, arm64, deployment target 14.0. |
| Warnings | PASS with listed tool warning | No Swift/compiler/linker warning; one AppIntents metadata extraction warning. |
| Static identity/resources/links/signature | PASS | Final and installed app verification; excluded updater/plugins/installer. |
| CLI / guard tests | PASS | Five CLI cases; 12 pure-memory guard tests; no IME runtime startup. |
| First installation | PASS | `~/Library/Input Methods/EcholME.app`; existing-target retry refused without file changes. |
| Registration | PASS | OSStatus 0; two TIS modes visible and select-capable. |
| Final system state | PASS (inspection) | Both EcholME modes disabled/unselected; no running EcholME and no LiangYi user-data directory. Inherited initial auto-enable was corrected and explicitly undone. |
| Notes AX capabilities | PASS (metadata only) | Caret bounds available in observed field, AXLanguage absent, subrole/sensitivity unknown; no document text read. |
| Xcode editor / Terminal capability | NOT_RUN / BLOCKED | Editor focus not established; Terminal denied by Computer Use safety policy. |
| Actual Chinese input / IMK / reload / coexistence | BLOCKED | Absolute no-deletion rule conflicts with engine-managed compiled-file removal during deployment. |
| macOS 14 / Intel runtime | NOT_RUN | Deployment target and runtime support are separate. |
| GPL external-distribution readiness | NOT_RUN | Provenance/notices recorded; complete corresponding-source and dependency/data review remain release gates. |

## Material limitations and next gate

The installed app's metadata was corrected in place and re-signed after initial registration exposed the inherited default-enabled Hans mode. It matches the corrected `round0-final` copy across 84 files. `round0-repro` separately verifies a fresh build of the final source. See the detailed evidence for this distinction and retained earlier failed builds.

A narrow user decision is required before the remaining Round 0 runtime acceptance: whether to allow librime's normal generated-file/database maintenance inside the independent LiangYi data/log directories. Do not delete files manually, alter Squirrel data, bypass the rule with a different directory, or rewrite the engine to evade the boundary. Terminal's UI tool restriction remains independent of that decision.

Stop here for user review. Do not begin Round 1, push, publicly distribute, or claim full Round 0 acceptance from the completed build/install checks.
