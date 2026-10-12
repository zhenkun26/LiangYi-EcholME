# LiangYi / EcholME — Delivery Status

Recorded: 2026-10-11, America/New_York.

## Current state — Round 1

- Authorization: Round 1 only; the user selected Option+Return and later authorized two P1 fixes, left/right Shift and mixed-composition regression tests, another review and a local commit. Round 2 requires new confirmation. No push, release, replacement installation or new dependency.
- Delivery: **IMPLEMENTED_AND_BUILT_WITH_RUNTIME_ACCEPTANCE_PENDING**. [Round 1 report](../round1/DELIVERY.md), [key contract](../round1/KEY_CONTRACT.md), and [manual installation/acceptance](../round1/MANUAL_ACCEPTANCE.md).
- Branch: `feat/round-1-composition`, based on the Round 0 closeout `92fb453`. The final increment hash is available in Git history and the delivery reply; no self-referential hash commit is needed.
- Implemented: copied/versioned candidate snapshots; English token composition; unified primary/raw/example commit; focus/mode/engine-reset invalidation; guarded Objective-C host calls; horizontal two-line rendering in the existing Squirrel Panel/View. P1 repair: a shared left/right Shift router, raw finalization before left-tap mode changes, verified right-tap schema replay, live engine-prefix ownership and reentrant focus/revision guards.
- Examples: ten hand-authored entries per direction, delayed 80 ms to exercise refresh. These are not dictionary coverage, real translation quality, cloud support or a measured latency result.
- Final repaired bundle: `.artifacts/builds/round1-shift-final-03/DerivedData/Build/Products/Debug/EcholME.app`, version **0.0.3**, macOS 14 deployment target, arm64 Debug/ad-hoc signed. The original 0.0.2 artifact/evidence remain historical.
- Final repaired verification: build/static signature/resource/link checks PASS; 60 shared policy/state/commit/layout checks PASS; 22 host-wrapper checks PASS; 12 mocked tooling guards PASS; 10 cycles / 60 original real librime checks PASS plus 57 Shift/mode checks using the production router, real pinned librime and a synthetic host. Both old engine conditions are established by negative controls. Normal (non-Swift) C probe compilation PASS. Tests use fresh LiangYi validation data/log roots. Production renderer previews remain synthetic, not real IMK screenshots.
- Follow-up source review: both original P1 findings RESOLVED_IN_SOURCE_AND_REGRESSION; no further P1/P2 found in the reviewed Shift repair and composition handoff paths. Source/artifact/check/installed-critical-file evidence is recorded in the `shift-*.json` files under `docs/round1/evidence/`. Actual IMK host acceptance remains separate.
- Warning: one inherited AppIntents metadata extraction warning; no compiler/linker warnings. macOS 14/Intel runtime, actual latency and universal crash freedom are unverified.
- Installed state: still the fixed Round 0 package, version **0.0.1**; critical files equal the retained fixed artifact. New Round 1 installation/Notes/Xcode/Terminal input acceptance is **NOT_RUN**. The initial-install hash manifest predates the Round 0 fix and is not the current installed-bundle comparator.
- GPL: inherited notices and dated modification record retained; new source/fixtures GPL-3.0-only; no added dependency/data. Complete corresponding-source/dependency/data distribution review remains an external release gate.
- Next: install and perform Round 1 real input acceptance with the user. Stop before Round 2; keep commits local. Preserve the historical Round 0 outcomes below.

## Round 0 closeout snapshot (historical)

- Plan: **PLAN_APPROVED_AND_COMMITTED**, `041b643`.
- Upstream baseline: **IMPORTED_WITH_HISTORY**, `8b507af`, Squirrel `769ae426f33f500266101a88f694aab0d158e680`.
- Initial Round 0 delivery: `6e971c2`; [historical verification](../round0/VERIFICATION.md).
- Round 0: **DELIVERED_WITH_VERIFICATION_LIMITS; WAITING_FOR_ROUND_1_AUTHORIZATION**. The fixed baseline is installed and usable in the exercised Notes cases; this is not a full cross-host acceptance pass. Implementation baseline: `3975903`. The closeout is documentation/evidence only.
- The user authorized confined librime generated-file/database maintenance within LiangYi's independent data/log roots. The user moved the old app to Trash; the assistant installed the fixed app only after the destination was absent. No assistant deletion or overwrite occurred.
- The user authorized Round 0 closeout, superseding earlier per-case waiting checkpoints for the bounded remaining checks. No later round is automatically authorized.
- Future candidate layout: **horizontal candidates, primary text above the corresponding opposite-language subtitle in each column**. This is an approved later-round requirement; Round 0 retains the vertical Chinese-only baseline.
- Notes punctuation: digits and 31 symbol keys **PASS for exercised field results**; physical equals and repeated Chinese `=`, Space insertion **PASS_USER_REPORTED**. The user confirmed punctuation/equals panel closure and underline clearing; the historical CUA equals alias limitation persists.
- Format input: **7 ASCII literal-input checks PASS; 7 Chinese-mode behavior observations retained**. The assistant's R0-UAT-001/002 fault labels remain withdrawn: literal English preservation was not an agreed requirement in explicit Chinese mode. Format-step panel confirmation is unverified.
- Closeout Notes field checks: composition Backspace/recovery, committed-text arrows/Backspace, explicit-mode mixed input, empty/pending source-switch recovery, and real input after reload **PASS within their recorded scope**. Unicode paste passed only as paste. Same-app new-field check showed no text leak; old `ni hao` stayed once and was unchanged by Escape. Candidate-panel geometry/closure and marked ranges were not independently observed.
- Reload: installed app requested deployment; new log slice showed **3 tasks, 3 success, 0 failure**, zero warning/error/fatal lines. Host input afterward passed. A mode query returned no response once during metadata checks; after actual Notes field reactivation it returned `nascii`. No universal background-query guarantee is claimed.
- Round 1–6: **NOT_AUTHORIZED_TO_START**. No translation, new composer, cloud API or context auto-switching has been implemented.
- Git: local branch `feat/round-0-foundation`; repository-local `zhenkun26` author with verified GitHub ID-based noreply email; `upstream` used read-only; no `origin`, push, merge to main or release.

The complete durable plan is [PLAN.md](PLAN.md), decisions are in [DECISIONS.md](DECISIONS.md), and the final Round 0 report is [RUNTIME_ACCEPTANCE.md](../round0/RUNTIME_ACCEPTANCE.md). Case outcomes and manual carryovers are in [MANUAL_ACCEPTANCE.md](../round0/MANUAL_ACCEPTANCE.md). This closeout changes documentation/evidence only; no extra self-referential commit is required.

## Round 0 verified scope (historical)

| Check | Result | Evidence / limit |
| --- | --- | --- |
| Approved plan, Git, dependency/data preparation | PASS | Fixed source/artifact/data manifests, licenses and retained upstream history; initial evidence preserved. |
| First actual installed runtime | FAIL; fixed source built | `URL.path()` percent-encoded spaces, producing data in `Application%20Support/LiangYi`. Process stopped; incident files retained, not deleted/migrated. |
| Fixed-source Debug build | PASS | `round0-path-fix`, Xcode 26.6, macOS 26.5, arm64, deployment target 14.0. |
| Warnings | PASS with listed tool warning | No Swift/compiler/linker warning; one AppIntents metadata extraction warning. Runtime warning counts are separately disclosed. |
| Fixed static identity/resources/links/signature | PASS | Static verification rerun after runtime. |
| Fixed runtime startup/deployment and reload | PASS (bounded) | Historical startup/idle checks passed. Installed closeout reload independently completed three successful tasks; subsequent Notes Space, digit, Esc/recovery field checks passed. |
| Real librime synthetic checks | PASS (engine only) | 10 cycles / 30 checks: candidates/Space, numeric choice, Esc, no second unread commit or residual composition. No IMK/UI client. |
| CLI / guard tests | PASS with session-query limitation | Initial five CLI cases remain historical; 12 guards rerun at closeout. One mode query lacked a response; a reactivated Notes session responded `nascii`. Standalone C probe compilation is historical. |
| Fixed installation / registration / activation | PASS | Absent-target installation and installed-bundle static verification passed; registration OSStatus 0; System Settings added 两仪; Hans selection confirmed independently; active session responded `nascii`. |
| Current system state | PASS (inspection) | Hans enabled/selected; Hant disabled/unselected; installed EcholME process running. Original source was Apple Simplified Pinyin; restoration is NOT_RUN. |
| Protected paths and incident preservation | PASS (historical snapshots) | Recorded automated-run isolation snapshots remain historical evidence; not a new system-wide trace or a claim that the old installation is still present. |
| Notes AX capabilities | PASS (metadata only) | Refreshed at closeout: finite caret bounds; AXLanguage absent; subrole/sensitivity unknown. No text captured or TCC prompt. Not IMK-client evidence. |
| Notes basic real input | PASS (bounded cases) | Dedicated synthetic notes: Space, numeric selection, Esc/recovery, composing Return and empty-composition Return. CUA field observations and human candidate/closure confirmations are distinguished in the manual ledger. |
| Notes punctuation and symbols | PASS (bounded field results and user confirmation) | Two modes, digits and 31 symbol keys; configured mappings, slash cancellation and recovery. Physical equals: ASCII repetition and Chinese individual/three committed equals passed by user report; panel/underline confirmed. Historical [automated evidence](../round0/evidence/notes-punctuation-acceptance.json) and [physical follow-up](../round0/evidence/notes-format-input-acceptance.json). |
| Notes email / URL / code-like input | ASCII: 7 PASS; Chinese: 7 observations | ASCII preserved all seven payloads. Chinese-mode pinyin/punctuation/recognizer behavior is recorded without imposing an unapproved literal-input criterion. Former fault labels withdrawn; raw results retained. Notes auto-link labels preserved; format-step visual confirmation pending. |
| Notes closeout editing / mixed input / switch / reload | PASS within field scope | [Closeout cases](../round0/evidence/notes-closeout-acceptance.json). Same-app new field showed no leak; old-field finalization is an observation. Unicode is paste-only; switching used system ABC, not the original source. |
| Remaining Notes coverage | NOT_RUN | Broader grammars/operators, composition-time punctuation, other symbol choices, Tab/forward Delete, typed Unicode, no-candidate Return, keypad Enter, candidate geometry and cross-app focus remain unverified. |
| Xcode / Terminal real input | BLOCKED_NO_UI_SURFACE / BLOCKED_TOOL_POLICY | Xcode Computer Use timed out, inventory had zero windows, and metadata probe found no focused element. Terminal remains manual; no denial bypass. Neither host has an input pass. |
| Concurrent Squirrel coexistence | NOT_RUN | No Squirrel runtime available; static identity/path isolation only. |
| macOS 14 / Intel runtime | NOT_RUN | Deployment target and runtime support are separate. |
| GPL external-distribution readiness | NOT_RUN | Provenance/notices recorded; complete corresponding-source and dependency/data review remain release gates. |

## Round 0 material limitations and original next gate (historical)

The fixed app is installed, registered and active. The replacement blocker was resolved by the user's Trash operation followed by absent-target installation. No input-method implementation changed during guided acceptance or closeout; recorded fixed-build input hashes still match. Installed executable, Debug library and Info.plist match the fixed artifact.

Candidate panels could not be read reliably through Computer Use; human confirmations establish closure for basic input, punctuation and physical-equals cases. Visual confirmation for the format-input step remains pending. Physical equals acceptance is now verified by user report; the CUA alias still produced `+` even with system ABC and is not usable as an automated physical-equals check.

R0-UAT-001 and R0-UAT-002 are **WITHDRAWN_INVALID_CRITERION**. The assistant incorrectly required explicit Chinese mode to preserve English text literally. Pinyin and Chinese punctuation processing are part of the current mode behavior; the observed email/code results do not establish a defect under an unagreed contract. Raw observations remain available. ASCII literal-input checks passed. A finite Notes matrix does not establish blanket grammar coverage, other-host compatibility, universal crash freedom or measured latency.

The accidental `~/Library/Application%20Support/LiangYi/` directory contains only this run's generated/configuration data in the recorded inventory. It remains on disk as incident evidence; optional removal is left to the user and must not affect its parent or other contents.

[MANUAL_ACCEPTANCE.md](../round0/MANUAL_ACCEPTANCE.md) preserves replacement instructions, results and concrete remaining host/visual/Return/restoration steps. Current source is still Hans / `nascii`; the original Apple Simplified Pinyin restoration is NOT_RUN. The system input-menu surface was not exposed in the inspected Computer Use inventory, so the active source was not disabled and the IME was not quit. Installation, logs, synthetic fixtures and incident evidence remain intact.

Round 0 was closed as a bounded delivery with these disclosed verification limits. Its original next gate was explicit Round 1 confirmation; the user subsequently provided it, as recorded in the current state above. No push/public distribution or full-acceptance claim is authorized by either round.
