# LiangYi / EcholME — Delivery Status

Recorded: 2026-10-14, America/New_York.

## Current checkpoint — 0.0.8 installed; authorized source publication

- **PASS**: audited absent-target installation of 0.0.8, rechecked on
  2026-10-14. All 86 installed file hashes match the repaired artifact;
  identity/resources/arm64 dependency paths and strict ad-hoc signature pass.
  No deletion or existing-target replacement occurred. [Installation evidence](../round3/evidence/installed-008.json).
- The data/log roots exist, with 310 data files and 5 logs at recheck. Their
  digests differ from the earlier removal/pre-install snapshot over the elapsed
  period. The installer does not write these roots; no cause is inferred and
  no unchanged-content claim is made for the intervening activity.
- Registration, enabling/selection, activation and repaired real-input
  acceptance remain **NOT_RUN_BY_THIS_INSTALL_STEP**. No EcholME process was
  found at recheck. Earlier 0.0.7 physical passes do not validate 0.0.8 recovery.
- Publication is explicitly authorized: public `zhenkun26/LiangYi-EcholME`,
  created and verified public/empty before the first push. The target is the
  current `codex/round-3-context` source branch. Integration merge, binary
  release, tag and Round 4 are outside this task. Repository/remote verification
  follows creation and pushing; the final delivery reports the remote commit.
- **PASS, bounded**: 262 new-history text blobs checked for selected credential
  patterns, no matches; no tracked build/app outputs or blobs above 100 MiB.
  Inherited CI jobs are restricted to `rime/squirrel`. No cloud CI pass claimed.
- [Open-source references](REFERENCES.md) record actual Squirrel/librime reuse
  and Metasequoia, McBopomofo and Fcitx5 learning/comparison sources. Reference
  links were checked on 2026-10-14. This documentation update follows the
  0.0.8 build; the installed bundle retains its recorded build-time README.

## Previous checkpoint — 0.0.7 removal

- **PASS**: under the user's explicit one-time authorization, Computer Use
  moved only `~/Library/Input Methods/EcholME.app` (verified 0.0.7, all 86
  delivered hashes matched) to Trash through Finder. Finder now shows zero
  items in Input Methods, and the exact app path is absent.
- The old app had restarted as PID 63936 after the preceding quit checkpoint.
  Normal `--quit` succeeded before removal; two post-removal process checks
  found no EcholME process. No force termination or system-wide reload.
- **PASS**: all 309 data files and 3 log files retain the same path/content
  inventory digests before and after removal. No Trash emptying or input-source
  disabling occurred. The removal exception is consumed.
- **WAITING_FOR_CONFIRMATION**: 0.0.8 remains an uninstalled artifact. Stop
  before installation, Round 4 and pushing. [Exact record](../round3/evidence/removal-007.json).

## Previous installed acceptance — 0.0.7 (before removal)

- Authorization: finish all executable Round 3 acceptance before entering
  Round 4, as explicitly clarified by the user on 2026-10-13. Round 4 is
  conditionally authorized but **NOT_STARTED**. No push is authorized.
- Installation, registration and activation: **PASS** in separately confirmed
  checkpoints. The installed bundle matches all 86 delivered file hashes;
  version is 0.0.7. System Settings contains the input method, Hans is enabled
  and selected, Hant is disabled, and the installed process responded `nascii`.
  The initially absent process/no mode reply is retained as an activation
  observation, not silently rewritten as an immediate launch pass.
- Physical Notes checks: **PASS, user-reported** for horizontal two-line
  candidates with an English subtitle, `nihao` + Space producing one `你好`,
  raw Return, Esc/recovery, numeric `中国`, and English `hello` Return/Space/
  ready translated Option+Return. The user confirmed panel/underline closure.
- Computer Use letter events produced plain `nihao` plus Notes autocorrection
  despite Hans/nascii metadata. This is an unresolved automation-path
  difference, not a confirmed input-method defect or a substitute for physical
  evidence. The selected single-note AX snapshot did not corroborate the
  subsequent physical text; do not claim an independent field-text pass.
- Physical left/right Shift (empty, composing, hold, chord and overlap), both
  language handoffs, same/different explicit modes, and Off raw/literal input
  also **PASS, user-reported**. Context/settings, sensitive-field recovery,
  Off Tab/shortcuts, HUD geometry and cross-host checks remain pending.
  System Settings inspection confirmed the IME Accessibility switch is off;
  real nearby-text detection is **BLOCKED_PERMISSION**. The user opened the
  Input Context window, but Computer Use timed out selecting that app and the
  metadata probe could not access its focused element. Settings edits are
  unverified; no permission or rule was changed by the assistant.
  Source review found a transient Secure Event Input recovery issue and a
  metadata-only focus race; both are repaired in the separate 0.0.8 source
  build below. The installed 0.0.7 bundle has not been changed. See the
  [live acceptance ledger](../round3/MANUAL_ACCEPTANCE.md) and
  [structured observations](../round3/evidence/installed-acceptance-007.json).

## Round 3 repair — 0.0.8 (2026-10-13)

- Status: **SOURCE_REPAIR_BUILT_INSTALLED_ACCEPTANCE_PENDING**. A transient
  global Secure Event Input flag no longer becomes permanent AX secure-field
  evidence. Release triggers a bounded metadata-only review, with literal
  passthrough and translations disabled while waiting. Known AX secure fields
  stay protected. Stale focus results retain protection until field/source
  reactivation; no per-key retry loop. Missing/denied/timed-out metadata uses
  the existing fallback and does not establish that a field is non-sensitive.
- **PASS**: 166 policy, 100 capture/settings, 42 async, 79 core, 22 host-wrapper,
  12 tool-guard, 60 real-engine, 72 Shift/router and 136 dictionary checks;
  offscreen settings layout checks. **PASS**: arm64 Debug xcodebuild, macOS 14
  target, static resources/linkage and strict local signature. No compiler or
  linker warnings; one inherited AppIntents metadata warning.
- Independent source re-review: original recovery/focus findings resolved;
  no further confirmed P1/P2 in the bounded review. The reader/queue/policy
  tests do not execute full InputController/IMK recovery or real OS delivery.
- All 40 tested source inputs match; 42 engine/resource inputs match the
  exercised engine, and all 86 new bundle hashes are recorded. Installed
  0.0.7 still matches its original 86 hashes. No replacement, permission
  change, new dependency, manual deletion, push or Round 4 work.
- Artifact: `.artifacts/builds/round3-secure-recovery-008-20261013a/DerivedData/Build/Products/Debug/EcholME.app`.
  [Repair evidence](../round3/evidence/secure-input-recovery-008.json) and
  [delivery details](../round3/DELIVERY.md). Repaired installed acceptance is
  **NOT_RUN**. The complete executable Round 3 gate remains open.

## Round 3 source delivery snapshot (historical, 2026-10-12)

- Authorization: the user requested Round 2 closeout review and Round 3 implementation on 2026-10-12. Stop before Round 4. Keep commits local; no installation, registration, push, release or cloud calls in this increment.
- Scope: bounded local field/text evidence, deterministic direction priority, focus-scoped manual override, Auto/Chinese/English/Off controls, short mode HUD, basic app-rule settings and About/licenses.
- Round 2 closeout audit: **PASS** for 27 recorded source hashes, 86 retained 0.0.6 bundle hashes and strict signature, checked before Round 3 edits. Source audit found no blocking P1/P2 issue. The 0.0.4 installed-state wording is corrected; commit `323d902` had removed that app. **No installed EcholME bundle**; the 0.0.6 artifact remains retained and uninstalled.
- Round 3 delivery: **IMPLEMENTED_AND_BUILT_WITH_INSTALLED_ACCEPTANCE_PENDING**. Version **0.0.7**, branch `codex/round-3-context`; stop before Round 4. [Delivery](../round3/DELIVERY.md) and [exact evidence](../round3/evidence/verification.json).
- Verification: **PASS** — 104 context-policy, 86 capture/settings and 34 async queue checks; regressions 79 core, 22 host, 12 guards, 60 engine, 72 Shift/router and 136 dictionary checks. Offscreen settings preview passes (18 controls/8 labels). Final xcodebuild/static identity/resources/linkage/ad-hoc signature pass; no compiler/linker warnings, one inherited AppIntents metadata warning. Final independent review found no confirmed remaining P1/P2 issue.
- Final bundle: `.artifacts/builds/round3-context-final-007-20261012b/DerivedData/Build/Products/Debug/EcholME.app`. All 40 recorded source/test/tool hashes and 86 bundle hashes match. No live document read, permission prompt, new dependency, manual deletion or installation occurred in this increment.
- Acceptance boundary: Round 1/2 physical Shift, installed IMK input, multi-host behavior and visible candidate latency remain **NOT_RUN** for the repaired bundle. Round 3 implementation/build and synthetic/offscreen verification are separate from installed acceptance. Follow [the guided checks](../round3/MANUAL_ACCEPTANCE.md) only after the next installation confirmation.

## Round 2 closeout (historical)

- Original authorization: Round 2 only on 2026-10-12. The later user request authorizes Round 3; this historical record does not grant installation, cloud work, pushing, or release.
- Delivery: **IMPLEMENTED_AND_BUILT_WITH_RUNTIME_ACCEPTANCE_PENDING**. [Round 2 report](../round2/DELIVERY.md) and [manual installation/acceptance](../round2/MANUAL_ACCEPTANCE.md).
- Branch: `feat/round-1-composition`, continued for this increment. The final hash is the delivery commit; no self-referential hash commit is needed.
- Dictionary: pinned MDBG CC-CEDICT export dated 2026-10-11T08:29:27Z, CC-BY-SA-4.0, 125,262 parsed entries. The derived index has 115,355 simplified keys (9,739 single-character and 105,616 multi-character), 33,030 English headwords, and 59,616 English phrases counted separately. Ranking uses the already vendored rime-essay scores at build time. This is not a reversal of one table into the other.
- Behavior: Chinese candidates show an English subtitle; English tokens show a Chinese subtitle. Option+Return still commits only a ready subtitle whose preview covers the whole composition. Misses show `—`. Lookup timeout or a missing index shows `!` and does not block primary commit. A timeout is not cached as a miss. The one-word English composer does not submit multiword phrases; an exact spaced primary can still resolve a stored phrase.
- Historical baseline bundle: `.artifacts/builds/round2-lexicon-20261012c/DerivedData/Build/Products/Debug/EcholME.app`, version **0.0.4**, macOS 14 deployment target, arm64 Debug/ad-hoc signed. The bundled index and NOTICE match the source tree.
- Verification on Apple M4, 16 GiB, macOS 26.5, Xcode 26.6, arm64: lexicon rebuild PASS; 136 dictionary/state/commit checks PASS; Round 1 regression 60 core, 22 host, 12 tool guards, real librime PASS, and 57 Shift checks PASS. In-process cold index load 474.8 ms. Warm lookup over 1,300 calls: minimum 0.0003 ms, P50 0.0010 ms, P95 0.0021 ms, maximum 0.048 ms. This is not the visible-panel 150 ms measurement.
- Warning: one inherited AppIntents metadata extraction warning; no compiler/linker warnings. macOS 14/Intel runtime and universal crash freedom are unverified.
- Installed state: **NO_INSTALLED_BUNDLE; WAITING_FOR_0.0.6_INSTALL_CONFIRMATION**. Under the user's explicit one-time exception on 2026-10-12, the assistant disabled the old source through System Settings, quit it, and moved only 0.0.4 `EcholME.app` to Trash. The user had reported intermittent left Shift failure on that version. **0.0.5** (`992d5ea`) was never installed. Earlier TextEdit checks remain limited to their recorded 0.0.4 cases.
- GPL: program sources remain GPL-3.0-only. The lexicon data remains CC-BY-SA-4.0 and is not relicensed. Complete corresponding-source distribution review remains an external release gate.
- Carryover: Notes, Xcode, and Terminal still need typed acceptance. Round 3 authorization does not turn these gaps into passes. Keep commits local. The TextEdit results and install record are in [manual acceptance](../round2/MANUAL_ACCEPTANCE.md).

## Round 2 follow-up — Shift and explicit primary language (historical)

- Scope: repair the reported Shift failure and make manual primary-language selection visible. No context detection, new translation backend, dependency, push, or later-round work.
- Source: missing-key-code repeat/release events retain the known Shift side; a subsequent typed key reconciles an omitted release; ambiguous overlap is consumed without toggling. The input-source menu now explicitly selects Chinese or English through the same guarded commit boundary. Same-language selection preserves composition; status labels are consistent on activation.
- Evidence: the new anonymous-repeat regression **FAILS on 0.0.5** and **PASSES after repair**. Current automated checks: **75 core, 22 host, 12 tool guards, 69 production-router/real-librime checks, 60 baseline engine checks, and 136 dictionary checks PASS**. Engine maintenance uses fresh confined LiangYi validation roots. Full results and source hashes are retained in [follow-up evidence](../round2/evidence/primary-language-repair.json).
- Artifact: **0.0.6**, `.artifacts/builds/shift-handoff-006-final-20261012/DerivedData/Build/Products/Debug/EcholME.app`. Final build/static verification **PASS**, no compiler/linker warning, one inherited AppIntents metadata warning. All 27 tested code inputs and 42 tested engine/resource files match the final build inputs/resources; all 86 final bundle file hashes are recorded in the evidence. The bundled bilingual README matches current source.
- Actual input: repaired installation, physical left/right Shift, menu clicks, and Notes `hello`/Chinese handoffs are **NOT_RUN**. Computer Use created a dedicated synthetic Notes fixture, but its standalone Shift call was rejected as modifier-only; no alternate event-injection method was used. This is a tool capability limit, not an application test failure.
- Old-bundle removal **PASS** under a subsequent explicit one-time user exception. Finder now shows an empty Input Methods folder; independent checks find no old app path, no EcholME PID, and system Simplified Pinyin selected. Before/after file inventory/content hashes match for all 236 regular data files and 7 log files. No Trash emptying, installation, or push occurred. The removal exception is consumed; **WAITING_FOR_INSTALL_CONFIRMATION**. Continue the [guided acceptance](../round2/MANUAL_ACCEPTANCE.md) one checkpoint at a time.
- Self-review: event normalization, both-side/overlap recovery, stale-focus boundaries, same-language idempotence, and test/production routing were reviewed. Automated coverage does not establish that the specific physical event sequence reported by the user is resolved; installation and user testing remain required.

## Round 1 snapshot (historical)

Round 1 remains **IMPLEMENTED_AND_BUILT_WITH_RUNTIME_ACCEPTANCE_PENDING**. Its repaired bundle is version 0.0.3. Source hashes matched the recorded repair, and a 2026-10-12 rerun passed 60 core, 22 host, 12 tool-guard, engine, and 57 Shift checks. Installed IMK acceptance was **NOT_RUN** and is still **NOT_RUN**. Details stay in [Round 1 delivery](../round1/DELIVERY.md). Those limits are not passes.

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
