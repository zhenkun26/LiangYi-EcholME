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
- Notes punctuation: digits and 31 symbol keys **PASS for exercised field results**; physical equals and repeated Chinese `=`, Space insertion **PASS_USER_REPORTED**. The user confirmed punctuation/equals panel closure and underline clearing; the historical CUA equals alias limitation persists.
- Latest guided step: seven email/URL/code payloads in two modes, **12 literal passes / 2 Chinese-mode literal failures**. R0-UAT-001 (structured-email underscore) and R0-UAT-002 (code-like pinyin/punctuation conversion) remain open. Format-step panel confirmation is pending. Hans / `nascii` restored; recovery input PASS. No implementation changed.
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
| Notes punctuation and symbols | PASS (bounded field results and user confirmation) | Two modes, digits and 31 symbol keys; configured mappings, slash cancellation and recovery. Physical equals: ASCII repetition and Chinese individual/three committed equals passed by user report; panel/underline confirmed. Historical [automated evidence](../round0/evidence/notes-punctuation-acceptance.json) and [physical follow-up](../round0/evidence/notes-format-input-acceptance.json). |
| Notes email / URL / code-like input | 12 PASS; 2 FAIL_LITERAL_PRESERVATION | Seven payloads per mode: all seven ASCII controls passed; five Chinese cases passed. Structured-email `_` → `——` and code-like text → pinyin/Chinese punctuation remain unresolved. Notes auto-link labels preserved; format-step visual confirmation pending. |
| Remaining Notes extended behavior | NOT_RUN | Broader grammars and code operators, composition-time punctuation, mixed/Unicode input, other symbol choices, editing, no-candidate Return, keypad Enter, caret placement, focus/source switching and input after reload remain pending. |
| Xcode / Terminal real input | NOT_RUN / BLOCKED_TOOL_POLICY | Xcode pending; Terminal remains user-operated because Computer Use previously denied access. |
| Concurrent Squirrel coexistence | NOT_RUN | No Squirrel runtime available; static identity/path isolation only. |
| macOS 14 / Intel runtime | NOT_RUN | Deployment target and runtime support are separate. |
| GPL external-distribution readiness | NOT_RUN | Provenance/notices recorded; complete corresponding-source and dependency/data review remain release gates. |

## Material limitations and next gate

The fixed app is now installed, registered and active. The previous replacement blocker is resolved by the user's Trash operation followed by absent-target installation. No input-method implementation changed during guided acceptance.

Candidate panels could not be read reliably through Computer Use; human confirmations establish closure for basic input, punctuation and physical-equals cases. Visual confirmation for the format-input step remains pending. Physical equals acceptance is now verified by user report; the CUA alias still produced `+` even with system ABC and is not usable as an automated physical-equals check.

R0-UAT-001 and R0-UAT-002 are open literal-preservation failures in explicit Chinese mode, with passing ASCII controls. For the tested structured address and code-like text, ASCII mode preserves the payloads. No recognizer/mode-policy fix was implemented or implicitly approved. A finite Notes matrix does not establish blanket grammar coverage, other-host compatibility, universal crash freedom or measured latency.

The accidental `~/Library/Application%20Support/LiangYi/` directory contains only this run's generated/configuration data in the recorded inventory. It remains on disk as incident evidence; optional removal is left to the user and must not affect its parent or other contents.

[MANUAL_ACCEPTANCE.md](../round0/MANUAL_ACCEPTANCE.md) preserves replacement instructions, guided results and remaining Notes/Xcode/Terminal, special-character, Return, focus/caret, reload and test-state restoration steps. Stop for the user's next-step confirmation; do not begin Round 1, push, publicly distribute, or claim full Round 0 acceptance.
