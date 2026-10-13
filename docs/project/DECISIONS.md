# LiangYi / EcholME — Decision Register

Recorded: 2026-10-11, America/New_York.

This is the decision index for the approved [delivery plan](PLAN.md). An accepted direction is not a claim that its implementation or runtime acceptance has passed. Detailed ADRs may be added during the round that owns the decision.

## Accepted decisions

| ID | Decision | Status | Basis and consequence |
| --- | --- | --- | --- |
| ADR-001 | Derive the macOS frontend from Squirrel and retain librime. | ACCEPTED | User selected this route to avoid rebuilding the mature host and pinyin integration. |
| ADR-002 | Preserve the names 两仪 and EcholME; target macOS 14; use Swift primarily. | ACCEPTED | Explicit product/platform requirements. ObjC/C++ bridging is permitted where justified. |
| ADR-003 | First usable internal experience must support Chinese→English and English→Chinese. | ACCEPTED | Round 2 is the internal bidirectional milestone; Round 6 is the full v0.1 release candidate. |
| ADR-004 | Reuse and adapt Squirrel's native candidate panel first; use horizontal candidate columns with primary text above its matching translation. | ACCEPTED | User confirmed the two-line horizontal reference during Round 0 acceptance. Initial layout belongs to Round 1; real translations to Round 2. Do not add a second CandidateUI implementation in parallel. McBopomofo remains a reference unless a concrete replacement need is established. |
| ADR-005 | Keep translation and context services separate from host writes. | ACCEPTED | One commit coordinator owns host insertion; asynchronous results require explicit identity/version checks. |
| ADR-006 | Prefer field type and nearby text for automatic direction, with explicit rules and stable fallback. | ACCEPTED | Freeze direction per composition; learned preferences never override explicit rules. |
| ADR-007 | Provide local-only, local-first, and API-first translation policies. | ACCEPTED | API-first cannot block primary-text input. Service support requires protocol and live-verification evidence. |
| ADR-008 | Prepare for GPL-derived distribution throughout development. | ACCEPTED | Preserve upstream rights and provide corresponding-source materials before external binary distribution. Exact grant/SPDX and dependency/data inventory still require verification. |
| ADR-009 | Deliver sequentially and stop after each authorized round for confirmation. | ACCEPTED | Round 0 and Round 1 are delivered with recorded limits. Round 2 was authorized on 2026-10-12. Stop before Round 3; keep commits local. |
| ADR-010 | Honor no filesystem deletion and independent product storage. | ACCEPTED | Review scripts, stop on existing install targets, and never alter Squirrel user data or evade replacement restrictions. |

Runtime acceptance authorization update (2026-10-11): the user permits librime's normal generated-file/database maintenance only within `~/Library/Application Support/LiangYi/` and `~/Library/Logs/LiangYi/`. This supersedes the earlier engine-maintenance blocker for audited, confined operations. Manual deletion, Squirrel/other data changes and pushing remain outside scope. Round 1 was outside scope at that historical authorization; its later explicit authorization is recorded above. Historical verification below records the initial delivery; follow-up runtime results are recorded in [RUNTIME_ACCEPTANCE.md](../round0/RUNTIME_ACCEPTANCE.md).

## Round 0 decision updates

The planning baseline was committed as `041b643` and Squirrel source/history was imported in `8b507af`. Detailed reasoning is in [Round 0 foundation](../round0/FOUNDATION.md), with current measured outcomes in [runtime acceptance](../round0/RUNTIME_ACCEPTANCE.md). These statuses distinguish a selected design from a verified implementation.

| ID | Current decision | Status / remaining evidence |
| --- | --- | --- |
| ADR-011 | Squirrel `769ae426f33f500266101a88f694aab0d158e680`; inherited librime `33e78140250125871856cdc5b42ddc6a5fcd3cd4` / v1.17.0 and Sparkle `41847a58cdef7506b257591fcca6f9495df591d4` / 2.6.2 references; `dependencies.lock.json` and `data/schema-manifest.json` identify artifact/data inputs. | BUILD_VERIFIED on macOS 26.5/arm64; Sparkle excluded. Artifact/data/notice checks pass; complete distribution closure remains pending. |
| ADR-012 | Product identity root `io.github.zhenkun26.inputmethod.EcholME`; user install `~/Library/Input Methods/EcholME.app`; data `~/Library/Application Support/LiangYi/Rime/`; logs `~/Library/Logs/LiangYi/`; runtime updater disabled. | FIXED_INSTALL_REGISTER_SELECT_PASS; both bundled mode defaults false. User removed the initial app; fixed app installed at the absent target. Hans currently enabled/selected, Hant disabled. Real Squirrel coexistence remains unverified. |
| ADR-013 | IMK adapter owns host access; session state owns lifecycle; engine adapter owns librime; presentation tracks displayed identity; one commit coordinator writes to the host; translation consumes copied values. | IMPLEMENTED_IN_ROUND_1 with fixture translations. Automated state/host/layout/engine checks are separate from pending installed IMK acceptance. |
| ADR-014 | Use privacy-preserving capability probes and separate source, AX, and real IMK evidence. | Notes metadata/basic/punctuation and closeout field checks passed within scope; physical equals/punctuation closure user-confirmed. Format: 7 ASCII passes; 7 Chinese observations; false fault labels withdrawn. Closeout editing/mixed/switch/reload passed; Unicode paste-only and same-app focus observation. Panel/Return branches remain unverified. Xcode BLOCKED_NO_UI_SURFACE; Terminal BLOCKED_TOOL_POLICY. |
| ADR-015 | Isolate long cloud work in a service process; XPC is a proposed mechanism requiring lifecycle, signing, peer-authentication, and failure validation. | DESIGN_PROPOSED; no service implementation or validated platform result. Round 4 remains unauthorized. |
| ADR-016 | Review recursive tooling; absent-target user installation only; stop at existing target; no cleanup/deletion or system-wide reload; separate registration from selection and input. | ROUND_0_DELIVERED_WITH_LIMITS; confined maintenance authorized. Fixed startup/idle reload/30 engine checks historical PASS. Installed closeout reload: 3 success, 0 failure, followed by Notes input PASS. Static verification and 12 guards rerun; no input-source implementation changed. Other hosts/restoration remain unverified. No assistant deletion or push. |

Round 0 observed Return behavior is baseline evidence, not a final decision for future English/translation modes: the current `express_editor` submits raw unselected input on Return; an empty composition allows host handling. The user confirmed raw letters committed with the candidate window and underline cleared; a separate Notes fixture confirmed one Return creates one newline. ADR-017 still owns the complete later-round key contract.

Round 0 punctuation evidence preserves the inherited schema: Chinese punctuation mappings and symbol choices differ intentionally from ASCII passthrough, and `/1` is a recognized symbol code rather than a simple candidate-selection action. ASCII quote transforms were reproduced with system ABC in Notes. The CUA equals limitation was supplemented by user physical-keyboard confirmation: individual and three sequential Chinese commits preserve equals without extra spaces and clear the panel/underline. Repeating pending equals remains a paging action under the inherited binding. These observations do not approve a new key contract; ADR-017 still requires the full interaction table.

The user corrected the assistant's Notes format verdict: explicit Chinese mode must not be judged against an unapproved English literal-preservation requirement. R0-UAT-001/002 are withdrawn fault classifications; the original pinyin/punctuation/recognizer observations remain intact. All seven ASCII-mode literal checks passed. Define the relevant mode/context contract before assigning a defect verdict or proposing a fix; do not infer approval for heuristics, key-binding changes or automatic context switching. Notes auto-link markup must be distinguished from displayed text.

Round 0 closeout is authorized and delivered with verification limits. A same-app new-note transition retained one `ni hao` in the old note and none in the new note; Escape after returning did not change that text. A pending source switch to ABC finalized one `nihao`. These are distinct host paths; neither settles the future focus-loss contract. One metadata-stage mode query had no response; a reactivated Notes session responded `nascii`. Preserve observations without assigning speculative causes or universal guarantees. No new state/commit behavior is approved by these baseline results.

## Decisions and evidence still required

### Round 1 decisions now resolved

| ID | Decision | Evidence and remaining limit |
| --- | --- | --- |
| ADR-017 | Adopt the [key contract](../round1/KEY_CONTRACT.md). Option+Return is user-selected; Return commits raw composition without newline; empty Return belongs to host. Chinese numeric labels retain schema recognizers; English digits extend a token. Tab/Command finalize raw then pass through; Esc cancels. | Shared policy tests PASS. Chinese engine checks PASS. Real installed Notes/Xcode/Terminal key acceptance remains NOT_RUN for Round 1. |
| ADR-018 | Use immutable snapshots with session UUID, focus generation, composition revision and candidate index. Copy primary text, label, engine comment, explicit whole preview and example state separately. Subtitle arrival preserves identities/highlight/page. | Core/layout tests PASS. The existing Squirrel Panel/View is reused; no new UI dependency. Translated commit requires a ready displayed candidate, matching preview, and engine selection covering the whole preedit. Real panel focus/mouse/multiple-display acceptance remains NOT_RUN. |

Round 1 P1 follow-up (2026-10-11): the user authorized fixes, regressions,
re-review and a local commit on the same branch. Left Shift alone within 0.5 s
finalizes raw input once before switching in either direction. Right Shift
retains schema selection semantics; a frontend English token is finalized
before replay. Engine-owned inline ASCII stays in Rime, including right-tap
finalization. Both physical Shift streams are owned by the frontend so an
intercepted letter cannot look like a bare tap to Rime. Typing, overlapping
Shifts, another modifier, long holds, duplicate/orphan events and lifecycle
resets invalidate the gesture. Right replay retains Caps Lock. Focus generation
and composition revision are checked after host finalization before any mode
change/replay. See the updated key contract and delivery follow-up.

Evidence: 60 core checks, 22 host-wrapper checks, 12 tool guards, 60 original
engine checks and 57 production-router/real-librime/synthetic-host checks PASS.
The shared Swift router is used by the actual InputController and the tests;
the synthetic host adapter does not validate IMK IPC, marked ranges, the real
panel or physical keyboard event delivery. These remain NOT_RUN on the repaired
0.0.3 bundle. No dependency, dictionary, cloud feature or Round 2 work was added.

The commit coordinator reserves and invalidates state before any external marking or
insertion. The Objective-C host adapter checks selectors, uses NSNotFound for
replacement, and contains NSException; failed/uncertain inserts are not retried.
This does not impose a hard timeout on synchronous IMK IPC, catch native C++
crashes, or establish universal crash freedom. Focus deactivation commits raw
text into the bound old client; an unexpected different client discards old
state. Fixtures are ten hand-authored entries per direction, not licensed
dictionary coverage, model support or measured real translation latency.

### Primary-language switching follow-up (2026-10-12)

The user reported intermittent failure of a left Shift tap on installed 0.0.4
and authorized taking over the repair and Computer Use checks. This is bounded
input-mode maintenance, not authorization for context detection, cloud work,
or a push. The earlier `992d5ea` fix was not installed.

Keep the existing 0.5-second left/right contract. Version 0.0.6 extends gesture
handling to key-code-zero events using device/held-side evidence and recovers
from releases omitted before a typed key. Add explicit Chinese/English menu
selection as a visible alternative, using raw finalization and the existing
focus/revision checks. Reselecting the active language is idempotent. Mode
queries only report active controllers. Hardware event delivery and menu
callbacks require installed acceptance; synthetic tests cannot establish them.

### Round 2 decision now resolved

| ID | Decision | Evidence and remaining limit |
| --- | --- | --- |
| ADR-019 | Use the pinned MDBG CC-CEDICT export `cedict_1_0_ts_utf-8_mdbg.txt.gz`, dated 2026-10-11T08:29:27Z, under CC-BY-SA-4.0. Build one simplified-to-English subtitle index and a separate English headword/phrase index. Break English ties with the vendored rime-essay scores. Do not treat either index as the reverse of the other. | Index rebuild and 136 runtime checks PASS. Counts, checksums, and the frozen corpus are in `data/lexicon/`. In-process lookup latency is recorded. Installed panel acceptance and the visible 150 ms measurement remain NOT_RUN. |

The Chinese subtitle is one eligible gloss: a plain English word, otherwise a short phrase, otherwise a truncated definition. English headwords prefer the earlier CC-CEDICT sense and then the higher essay score. Phrases of two to four words are stored separately. Labeled surname, variant, abbreviation, archaic, slang, and bound-form senses are demoted or skipped. Regular English plurals and `-ing`/`-ed` forms fall back only when the surface word is absent. The displayed subtitle is exactly what Option+Return can commit, and only when the candidate preview covers the whole composition.

Known policy results, not defects in that contract: English `input` commits `投放` while `输入` displays `import`; `eat` commits `食用`; `time` commits `时候`; `chinese` commits `中国人` while `中文` displays `Chinese`. A miss (`—`) and a timeout (`!`) stay distinct. No cloud provider, context detector, or new code dependency was added.

### Remaining decisions and platform evidence

| ID | Question | Owner round | Exit requirement |
| --- | --- | --- | --- |
| ADR-011 | Which exact Squirrel revision, compatible librime revision, recursive dependencies, and toolchain form the baseline? | Round 0 | Record pinned versions, licenses, source provenance, and observed build compatibility. Planning snapshots do not decide this automatically. |
| ADR-012 | What are the final bundle/input-source identifiers, IMK connection, paths, notification names, and update behavior? | Round 0 | Demonstrate independent identity and no collision with Squirrel. Disable inherited update routing unless a separately authorized replacement exists. |
| ADR-013 | Which state belongs to the IMK controller, composition coordinator, engine adapter, and service process? | Round 0 | Record ownership, lifecycle, allowed thread access, and failure behavior before the Round 1 state implementation. |
| ADR-014 | What host context/caret information is available in Notes, Xcode, and Terminal on the tested environment? | Round 0 | Record capability evidence, time/call boundaries, and fallback; do not assume all fields or AX attributes are available on macOS 14. |
| ADR-015 | How will long-running cloud tasks be isolated and authenticated? | Round 0 design; Round 4 implementation | Choose a concrete service mechanism based on capability validation; define peer authentication and bounded messages rather than treating process separation as authentication. |
| ADR-016 | What safe build/install/reload procedures work under the no-deletion policy? | Round 0 | Inspect side effects, stop on existing targets, and distinguish install/register/select/input states. |
| ADR-017 | Runtime evidence for the resolved key contract above; phrase entry and full Off mode. | Round 1 acceptance; later feature rounds | Complete installed IMK acceptance; do not treat core tests or Example Off as full product mode acceptance. |
| ADR-018 | Runtime evidence for the implemented snapshot/display model above. | Round 1 acceptance; Round 5 geometry | Test mouse press/release, focus, subtitle arrival, screen edges and scale on the installed bundle. |
| ADR-019 | Runtime and quality limits of the selected dictionary above. | Round 2 acceptance; Round 5 latency | Installed IMK subtitle/commit acceptance and visible-panel latency remain NOT_RUN. One displayed sense is not a professional quality rating. |
| ADR-020 | What is the measured local latency envelope on the supported devices and corpus? | Round 2 baseline; Round 5 acceptance | Measure valid visible translation end-to-end; report cold/warm distributions, maxima, misses, and timeouts without weakening the 150 ms criterion. |
| ADR-021 | What exact outbound-text, retention, cache, and sensitive-field policies apply? | Round 3–4 | Define visible user controls and default behavior; avoid whole-field outbound text and plaintext diagnostic content by default. |
| ADR-022 | Which provider protocol variants and endpoint rules are actually supported? | Round 4 | Separate contract tests, live requests, and quality/latency results for each provider. |
| ADR-023 | What OS/architecture combinations may be advertised as supported? | Round 5–6 | Distinguish compilation from actual runtime verification, including macOS 14 and Intel. |
| ADR-024 | What source delivery method and artifact set satisfy the chosen GPL distribution path? | Before first external binary; final review in Round 6 | Map exact binary to complete corresponding source, dependencies, scripts, notices, and checksums. |

## Deferred or excluded decisions

- Do not decide a new candidate UI dependency unless Squirrel's panel fails a documented requirement.
- Do not start a self-written pinyin engine, cloud sync, URL-level rules, additional languages, automatic updater, or notarized installer in v0.1.
- Do not infer permission to push, release, or distribute from approval to implement.
- Do not introduce a specific cloud model, API key, paid service, or bundled local model merely because the architecture supports it.
- Keep prior proposed translation shortcuts and English phrase-entry shortcuts explicitly tentative until ADR-017 is resolved.
