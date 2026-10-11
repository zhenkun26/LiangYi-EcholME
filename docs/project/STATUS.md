# LiangYi / EcholME — Delivery Status

Recorded: 2026-10-11, America/New_York.

## Current state

- Plan: **PLAN_APPROVED_AND_COMMITTED**, `041b643`.
- Upstream baseline: **IMPORTED_WITH_HISTORY**, `8b507af`, Squirrel `769ae426f33f500266101a88f694aab0d158e680`.
- Initial Round 0 delivery: `6e971c2`; [historical verification](../round0/VERIFICATION.md).
- Round 0 follow-up: **AUTOMATED_RUNTIME_CHECKS_DELIVERED; FIXED_INSTALL_AND_HOST_UAT_PENDING**. This is not a full Round 0 acceptance pass.
- The user authorized confined librime generated-file/database maintenance within LiangYi's independent data/log roots. No manual deletion or existing-bundle replacement was performed.
- Round 1–6: **NOT_AUTHORIZED_TO_START**. No translation, new composer, cloud API or context auto-switching has been implemented.
- Git: local branch `feat/round-0-foundation`; repository-local `zhenkun26` author with verified GitHub ID-based noreply email; `upstream` used read-only; no `origin`, push, merge to main or release.

The complete durable plan is [PLAN.md](PLAN.md), decisions are in [DECISIONS.md](DECISIONS.md), and the current detailed report is [RUNTIME_ACCEPTANCE.md](../round0/RUNTIME_ACCEPTANCE.md). The follow-up implementation delivery is the commit containing this status update; no extra self-referential commit is required.

## Verified scope

| Check | Result | Evidence / limit |
| --- | --- | --- |
| Approved plan, Git, dependency/data preparation | PASS | Fixed source/artifact/data manifests, licenses and retained upstream history; initial evidence preserved. |
| First actual installed runtime | FAIL; fixed source built | `URL.path()` percent-encoded spaces, producing data in `Application%20Support/LiangYi`. Process stopped; incident files retained, not deleted/migrated. |
| Fixed-source Debug build | PASS | `round0-path-fix`, Xcode 26.6, macOS 26.5, arm64, deployment target 14.0. |
| Warnings | PASS with listed tool warning | No Swift/compiler/linker warning; one AppIntents metadata extraction warning. Runtime warning counts are separately disclosed. |
| Fixed static identity/resources/links/signature | PASS | Static verification rerun after runtime. |
| Fixed runtime startup/deployment and idle reload | PASS (maintenance only) | Both passes: two schemas, three successful tasks, zero failed tasks; correct decoded LiangYi paths. No host-input claim. |
| Real librime synthetic checks | PASS (engine only) | 10 cycles / 30 checks: candidates/Space, numeric choice, Esc, no second unread commit or residual composition. No IMK/UI client. |
| CLI / guard tests | PASS | Initial five CLI cases remain historical evidence; 12 guard tests rerun; standalone C probe compiled with warnings-as-errors. |
| Fixed installation | MANUAL_ACTION_REQUIRED | Existing-target refusal preserved. Installed initial binary is unchanged and unfixed; do not enable it. User replacement steps provided. |
| Final system state | PASS (inspection) | Both EcholME modes disabled/unselected; no running EcholME; active source remains Apple Simplified Pinyin. |
| Protected paths and incident preservation | PASS (snapshots) | Inspected Squirrel paths remain absent; installed app and accidental encoded-path data unchanged after fixed checks. Not a system-wide trace. |
| Notes AX capabilities | PASS (initial metadata only) | Caret bounds available in observed field, AXLanguage absent, subrole/sensitivity unknown; not IMK evidence. |
| Notes/Xcode/Terminal real input | NOT_RUN / BLOCKED_TOOL_POLICY | No safe synthetic field established; Terminal denied by Computer Use. Manual steps supplied. |
| Concurrent Squirrel coexistence | NOT_RUN | No Squirrel runtime available; static identity/path isolation only. |
| macOS 14 / Intel runtime | NOT_RUN | Deployment target and runtime support are separate. |
| GPL external-distribution readiness | NOT_RUN | Provenance/notices recorded; complete corresponding-source and dependency/data review remain release gates. |

## Material limitations and next gate

The installed initial app must be replaced by the user before real input tests. Under the existing-target/no-deletion rule, the assistant built and exercised the fixed candidate in its build directory without registering/selecting it or replacing the old installation. Both remain preserved and are explicitly distinguished in the report.

The accidental `~/Library/Application%20Support/LiangYi/` directory contains only this run's generated/configuration data in the recorded inventory. It remains on disk as incident evidence; optional removal is left to the user and must not affect its parent or other contents.

[MANUAL_ACCEPTANCE.md](../round0/MANUAL_ACCEPTANCE.md) gives precise replacement, registration, Notes/Xcode/Terminal, focus/caret, reload and cleanup-of-test-state steps. No actual IMK input or source-switch acceptance is claimed from standalone engine tests. Stop here for user review; do not begin Round 1, push, publicly distribute, or claim full Round 0 acceptance.
