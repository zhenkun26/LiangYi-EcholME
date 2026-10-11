# LiangYi / EcholME — Delivery Status

Recorded: 2026-10-11, America/New_York.

## Current state

- Plan: **PLAN_APPROVED_AND_COMMITTED**, `041b643`.
- Upstream baseline: **IMPORTED_WITH_HISTORY**, `8b507af`, Squirrel `769ae426f33f500266101a88f694aab0d158e680`.
- Initial Round 0 delivery: `6e971c2`; [historical verification](../round0/VERIFICATION.md).
- Round 0 follow-up: **FIXED_INSTALL_COMPLETE; NOTES_BASIC_INPUT_PASS; EXTENDED_HOST_UAT_PENDING**. This is not a full Round 0 acceptance pass. Implementation baseline: `3975903`.
- The user authorized confined librime generated-file/database maintenance within LiangYi's independent data/log roots. The user moved the old app to Trash; the assistant installed the fixed app only after the destination was absent. No assistant deletion or overwrite occurred.
- Guided acceptance proceeds one user-confirmed step at a time. The current step is complete; no next UI test is automatically authorized by this checkpoint.
- Future candidate layout: **horizontal candidates, primary text above the corresponding opposite-language subtitle in each column**. This is an approved later-round requirement; Round 0 retains the vertical Chinese-only baseline.
- Latest guided step: Notes digits and 31 symbol keys in Chinese/ASCII modes **PASS for exercised field results**; physical equals **BLOCKED_AUTOMATION_INPUT**, with user keyboard verification pending. Candidate closure/underline confirmation for this step remains pending. Hans / `nascii` was restored after the temporary ABC control. No implementation changed.
- Round 1–6: **NOT_AUTHORIZED_TO_START**. No translation, new composer, cloud API or context auto-switching has been implemented.
- Git: local branch `feat/round-0-foundation`; repository-local `zhenkun26` author with verified GitHub ID-based noreply email; `upstream` used read-only; no `origin`, push, merge to main or release.

The complete durable plan is [PLAN.md](PLAN.md), decisions are in [DECISIONS.md](DECISIONS.md), and the current detailed report is [RUNTIME_ACCEPTANCE.md](../round0/RUNTIME_ACCEPTANCE.md). Guided case outcomes and pending coverage are in [MANUAL_ACCEPTANCE.md](../round0/MANUAL_ACCEPTANCE.md). This checkpoint changes documentation only; no extra self-referential commit is required.

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
| Fixed installation / registration / activation | PASS | Absent-target installation and installed-bundle static verification passed; registration OSStatus 0; System Settings added 两仪; Hans selection confirmed independently; active session responded `nascii`. |
| Current system state | PASS (inspection) | Hans enabled/selected; Hant disabled/unselected; installed EcholME process running. Original source was Apple Simplified Pinyin; restoration is NOT_RUN. |
| Protected paths and incident preservation | PASS (historical snapshots) | Recorded automated-run isolation snapshots remain historical evidence; not a new system-wide trace or a claim that the old installation is still present. |
| Notes AX capabilities | PASS (initial metadata only) | Caret bounds available in observed field, AXLanguage absent, subrole/sensitivity unknown; not IMK evidence. |
| Notes basic real input | PASS (bounded cases) | Dedicated synthetic notes: Space, numeric selection, Esc/recovery, composing Return and empty-composition Return. CUA field observations and human candidate/closure confirmations are distinguished in the manual ledger. |
| Notes punctuation and symbols | PASS (bounded field results); equals BLOCKED_AUTOMATION_INPUT | Two modes, digits and 31 symbol keys; configured Chinese conversions, slash-code cancellation and input recovery. System ABC reproduced automated `equal` → `+` and quote transforms. Physical equals and panel/underline confirmation pending; [evidence](../round0/evidence/notes-punctuation-acceptance.json). |
| Remaining Notes extended behavior | NOT_RUN | Punctuation during pinyin composition, mixed/email/URL/code input, other symbol choices, Unicode input, editing, no-candidate Return, keypad Enter, caret placement, focus/source switching and input after reload remain pending. |
| Xcode / Terminal real input | NOT_RUN / BLOCKED_TOOL_POLICY | Xcode pending; Terminal remains user-operated because Computer Use previously denied access. |
| Concurrent Squirrel coexistence | NOT_RUN | No Squirrel runtime available; static identity/path isolation only. |
| macOS 14 / Intel runtime | NOT_RUN | Deployment target and runtime support are separate. |
| GPL external-distribution readiness | NOT_RUN | Provenance/notices recorded; complete corresponding-source and dependency/data review remain release gates. |

## Material limitations and next gate

The fixed app is now installed, registered and active. The previous replacement blocker is resolved by the user's Trash operation followed by absent-target installation. No input-method implementation changed during guided acceptance.

Candidate panels could not be read reliably through Computer Use; human confirmations establish candidate identity and closure for the earlier basic cases. Visual confirmation for the punctuation step remains pending. A finite passing Notes run does not establish all application compatibility, every special-character sequence, universal crash freedom or measured candidate latency. The physical equals key is unverified because the automated alias produced `+` even with system ABC. Remaining coverage must stay visible until separately exercised.

The accidental `~/Library/Application%20Support/LiangYi/` directory contains only this run's generated/configuration data in the recorded inventory. It remains on disk as incident evidence; optional removal is left to the user and must not affect its parent or other contents.

[MANUAL_ACCEPTANCE.md](../round0/MANUAL_ACCEPTANCE.md) preserves replacement instructions, guided results and remaining Notes/Xcode/Terminal, special-character, Return, focus/caret, reload and test-state restoration steps. Stop for the user's next-step confirmation; do not begin Round 1, push, publicly distribute, or claim full Round 0 acceptance.
