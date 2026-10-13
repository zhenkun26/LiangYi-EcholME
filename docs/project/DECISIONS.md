# LiangYi / EcholME — Decision Register

Updated: 2026-10-13, America/New_York; initial plan recorded 2026-10-11.

This is the decision index for the approved [delivery plan](PLAN.md). An accepted direction is not a claim that its implementation or runtime acceptance has passed. Detailed ADRs may be added during the round that owns the decision.

Latest authorization update (2026-10-13): the user separately approved guided
installation, registration and activation of 0.0.7, then authorized Round 4
only after completing all executable Round 3 installed acceptance. They
explicitly rejected using the `nihao` smoke check alone as that gate. Round 4
has not started. Historical source-increment restrictions below do not undo
these approvals. No push, replacement deletion or Round 5 is authorized.

Evidence decision: distinguish physical-keyboard user reports from Computer
Use events and field snapshots. The latter did not reproduce or independently
corroborate the current physical Notes results. Do not classify literal CU
letters as an IME regression solely from TIS selection and `--getascii`.

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
| ADR-009 | Deliver sequentially within explicit stage gates. | ACCEPTED | On 2026-10-13 the user conditionally authorized Round 4 after all executable Round 3 acceptance. Guided installation of 0.0.7 and partial physical checks are recorded separately; remaining cases are not passes. Keep commits local; no automatic replacement or later-round work. |
| ADR-010 | Honor no filesystem deletion and independent product storage. | ACCEPTED | Review scripts, stop on existing install targets, and never alter Squirrel user data or evade replacement restrictions. |

Runtime acceptance authorization update (2026-10-11): the user permits librime's normal generated-file/database maintenance only within `~/Library/Application Support/LiangYi/` and `~/Library/Logs/LiangYi/`. This supersedes the earlier engine-maintenance blocker for audited, confined operations. Manual deletion, Squirrel/other data changes and pushing remain outside scope. Round 1 was outside scope at that historical authorization; its later explicit authorization is recorded above. Historical verification below records the initial delivery; follow-up runtime results are recorded in [RUNTIME_ACCEPTANCE.md](../round0/RUNTIME_ACCEPTANCE.md).

## Round 0 decision updates

The planning baseline was committed as `041b643` and Squirrel source/history was imported in `8b507af`. Detailed reasoning is in [Round 0 foundation](../round0/FOUNDATION.md), with current measured outcomes in [runtime acceptance](../round0/RUNTIME_ACCEPTANCE.md). These statuses distinguish a selected design from a verified implementation.

| ID | Current decision | Status / remaining evidence |
| --- | --- | --- |
| ADR-011 | Squirrel `769ae426f33f500266101a88f694aab0d158e680`; inherited librime `33e78140250125871856cdc5b42ddc6a5fcd3cd4` / v1.17.0 and Sparkle `41847a58cdef7506b257591fcca6f9495df591d4` / 2.6.2 references; `dependencies.lock.json` and `data/schema-manifest.json` identify artifact/data inputs. | BUILD_VERIFIED on macOS 26.5/arm64; Sparkle excluded. Artifact/data/notice checks pass; complete distribution closure remains pending. |
| ADR-012 | Product identity root `io.github.zhenkun26.inputmethod.EcholME`; user install `~/Library/Input Methods/EcholME.app`; data `~/Library/Application Support/LiangYi/Rime/`; logs `~/Library/Logs/LiangYi/`; runtime updater disabled. | 0.0.7 installed/registered/activated through guided checkpoints; all 86 delivered file hashes match. Hans enabled/selected, Hant disabled. The earlier 0.0.4 removal exception (`323d902`) is consumed. Both bundled mode defaults remain false. Real Squirrel coexistence remains unverified. |
| ADR-013 | IMK adapter owns host access; session state owns lifecycle; engine adapter owns librime; presentation tracks displayed identity; one commit coordinator writes to the host; translation consumes copied values. | IMPLEMENTED_IN_ROUND_1 with fixture translations. Automated state/host/layout/engine checks are separate from pending installed IMK acceptance. |
| ADR-014 | Use privacy-preserving capability probes and separate source, AX, and real IMK evidence. | Notes metadata/basic/punctuation and closeout field checks passed within scope; physical equals/punctuation closure user-confirmed. Format: 7 ASCII passes; 7 Chinese observations; false fault labels withdrawn. Closeout editing/mixed/switch/reload passed; Unicode paste-only and same-app focus observation. Panel/Return branches remain unverified. Xcode BLOCKED_NO_UI_SURFACE; Terminal BLOCKED_TOOL_POLICY. |
| ADR-015 | Isolate long cloud work in a service process; XPC is a proposed mechanism requiring lifecycle, signing, peer-authentication, and failure validation. | DESIGN_PROPOSED; no service implementation or validated platform result. Round 4 is conditionally authorized after the Round 3 acceptance gate and has not started. |
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
and authorized taking over the repair and Computer Use checks. That follow-up
was bounded input-mode maintenance, without authorization for context
detection, cloud work, or a push. Round 3 was authorized separately afterward.
The earlier `992d5ea` fix was not installed.

Keep the existing 0.5-second left/right contract. Version 0.0.6 extends gesture
handling to key-code-zero events using device/held-side evidence and recovers
from releases omitted before a typed key. Add explicit Chinese/English menu
selection as a visible alternative, using raw finalization and the existing
focus/revision checks. Reselecting the active language is idempotent. Mode
queries only report active controllers. Hardware event delivery and menu
callbacks require installed acceptance; synthetic tests cannot establish them.

Old-package removal exception (2026-10-12): after Finder refused removal because
0.0.4 had relaunched, the user explicitly authorized assistant deletion of only
`~/Library/Input Methods/EcholME.app`. System Settings removed the source from
the enabled list; `--quit` was followed by an independent no-PID check; Finder
moved the exact old app to Trash. No permanent erasure or other deletion was
performed. LiangYi data/log file inventories and content hashes matched before
and after. This one-time exception is complete, not standing deletion authority.
The removal record is `323d902`. Version 0.0.6 remains retained and uninstalled;
the original Round 3 source work did not authorize installation. Subsequent
guided checkpoints separately confirmed the delivered 0.0.7 installation.
Future repair replacement needs its own confirmed sequence. Keep commits local.

### Round 2 decision now resolved

| ID | Decision | Evidence and remaining limit |
| --- | --- | --- |
| ADR-019 | Use the pinned MDBG CC-CEDICT export `cedict_1_0_ts_utf-8_mdbg.txt.gz`, dated 2026-10-11T08:29:27Z, under CC-BY-SA-4.0. Build one simplified-to-English subtitle index and a separate English headword/phrase index. Break English ties with the vendored rime-essay scores. Do not treat either index as the reverse of the other. | Index rebuild and 136 runtime checks PASS. Counts, checksums, and the frozen corpus are in `data/lexicon/`. In-process lookup latency is recorded. The 0.0.7 Notes panel and commit cases have bounded user-reported passes; other hosts/geometry and visible 150 ms measurement remain unverified. |

The Chinese subtitle is one eligible gloss: a plain English word, otherwise a short phrase, otherwise a truncated definition. English headwords prefer the earlier CC-CEDICT sense and then the higher essay score. Phrases of two to four words are stored separately. Labeled surname, variant, abbreviation, archaic, slang, and bound-form senses are demoted or skipped. Regular English plurals and `-ing`/`-ed` forms fall back only when the surface word is absent. The displayed subtitle is exactly what Option+Return can commit, and only when the candidate preview covers the whole composition.

Known policy results, not defects in that contract: English `input` commits `投放` while `输入` displays `import`; `eat` commits `食用`; `time` commits `时候`; `chinese` commits `中国人` while `中文` displays `Chinese`. A miss (`—`) and a timeout (`!`) stay distinct. Round 2 added no cloud provider, context detector, or new code dependency.

### Round 3 — Context, mode, and local retention contract

**ADR-025 — Accepted and implemented in the Round 3 source increment; installed
acceptance is partial.** The original source authorization was followed by
guided 0.0.7 installation and user-reported physical passes. On 2026-10-13 the
user conditionally authorized Round 4 after all executable Round 3 acceptance;
that gate remains open. Keep source repair, installed results, and unavailable
checks separate. No push or automatic replacement. Current build,
automated results, and remaining manual checks belong in the
[Round 3 delivery record](../round3/DELIVERY.md).

The resolved mode contract is:

- Auto is the default. Its global fallback is Chinese. Safety checks take
  precedence; product Off then bypasses ordinary language resolution. Current
  focus manual choice, persistent Chinese/English mode, exact app force rule,
  reliable field/nearby-text evidence, enabled learned preference, built-in
  app fallback, and global direction follow in that order.
- Chinese/English menu or settings choices persist. A successful Shift gesture
  establishes a manual override for the current focus. Selecting Auto clears
  that override and restores the resolver. The existing left/right Shift and
  raw/candidate commit contract remains in force.
- Off first finalizes pending raw composition through the guarded host boundary,
  then passes keys through without bilingual composition or translation.
  Sensitive-field protection instead cancels stale pending composition and
  subtitles before passthrough; it must not insert text from a previous field
  into the protected field.
- Ordinary context changes do not switch an active composition's direction.
  Explicit mode changes finalize through the existing guarded commit path.
  Reordered context results require both the current request UUID and matching
  session/focus/composition identity. A secure-field result may cross a revision
  only within that same request and focus. This prevents the input method's own
  preedit or a later commit from becoming stale automatic direction evidence.

The local context boundary is:

- At activation, a background AX adapter may read at most 128 UTF-16 units
  immediately before a collapsed caret using the bounded parameterized range
  API. Full-field `AXValue`, selected text, and document titles are not read.
  A host lacking that capability falls back; no broad text-read alternative is
  used. IMK client objects never leave the controller thread.
  Selecting Auto while idle can sample missing evidence; a mode change that
  just finalized raw input does not read that output. Manual mode changes can
  repeat the safety-metadata check without reading nearby text.
- Text collection occurs only in Auto with nearby context enabled. Explicit
  Chinese/English modes use safety metadata only. Off makes no context request.
  There is no automatic Accessibility permission prompt and no per-key AX
  polling. Ordinary input does not require Accessibility permission.
- Captured text is transient, local, and absent from evidence objects, settings,
  logs, and outbound requests. Classification uses conservative Han/ASCII-script
  dominance and code-literal patterns, not a claim to distinguish all natural
  languages. Short/mixed/unsupported text and failed or late AX responses use
  the documented priority fallback. AX calls have bounded messaging and delivery
  budgets; this is not a guarantee that all platform IPC can be interrupted.

Settings live in the application's own UserDefaults domain, with at most
128 app identifiers across force rules and learned entries and a maximum
64 KiB encoded payload. Learning is disabled by default. When enabled it stores
only app ID, selected direction, and a count capped at three; three consistent
manual choices are required before that learned fallback applies. Invalid
settings do not replace valid active preferences. The settings UI exposes rule
editing, learning reset, mode/context controls, and About/Open Source Licenses.
No new third-party dependency or cloud backend is introduced.

The development target remains macOS 14 and arm64. Source checks, synthetic
capture/policy tests, and a development build do not establish installed IMK
behavior, physical Shift recovery, real cross-host permission/focus behavior,
or a visible-panel latency below 150 ms. Those remain explicit acceptance
carryovers; complete corresponding-source distribution review remains a
separate release gate.

### Round 3 repair — transient security state (2026-10-13)

**ADR-026 — Implemented and built in 0.0.8; repaired installed acceptance
NOT_RUN.** A live global Secure Event Input flag is independent from persistent
AX secure-field evidence. Its release or a delayed skipped capture requires a
bounded metadata-only review. While waiting, ordinary keys pass through and
translations stay disabled; no nearby text is sampled. Request UUID and
session/focus/composition gates reject cancelled or obsolete completions.
Metadata-only reads validate focus, global protection and the deadline before
delivery. A stale field result retires the request, retains protection, and
blocks automatic retries until field/input-source reactivation resets context.
Known AX secure evidence cannot be replaced by unknown/skipped/failed metadata.
Off schedules no review and preserves unresolved safety for resumption.

Denied, unsupported and timed-out metadata ends the bounded wait using the
existing fallback contract; this is not proof of a safe field. No new prompt,
dependency, text retention or per-key AX polling is added. Source/queue tests
and bounded review pass; real InputController/IMK recovery, field identity and
OS event delivery require installed acceptance. Current 0.0.7 user physical
passes remain separate from this repair. See [repair evidence](../round3/evidence/secure-input-recovery-008.json).

### Remaining decisions and platform evidence

| ID | Question | Owner round | Exit requirement |
| --- | --- | --- | --- |
| ADR-011 | Which exact Squirrel revision, compatible librime revision, recursive dependencies, and toolchain form the baseline? | Round 0 | Record pinned versions, licenses, source provenance, and observed build compatibility. Planning snapshots do not decide this automatically. |
| ADR-012 | What are the final bundle/input-source identifiers, IMK connection, paths, notification names, and update behavior? | Round 0 | Demonstrate independent identity and no collision with Squirrel. Disable inherited update routing unless a separately authorized replacement exists. |
| ADR-013 | Which state belongs to the IMK controller, composition coordinator, engine adapter, and service process? | Round 0 | Record ownership, lifecycle, allowed thread access, and failure behavior before the Round 1 state implementation. |
| ADR-014 | What host context/caret information is available in Notes, Xcode, and Terminal on the tested environment? | Round 0 | Record capability evidence, time/call boundaries, and fallback; do not assume all fields or AX attributes are available on macOS 14. |
| ADR-015 | How will long-running cloud tasks be isolated and authenticated? | Round 0 design; Round 4 implementation | Choose a concrete service mechanism based on capability validation; define peer authentication and bounded messages rather than treating process separation as authentication. |
| ADR-016 | What safe build/install/reload procedures work under the no-deletion policy? | Round 0 | Inspect side effects, stop on existing targets, and distinguish install/register/select/input states. |
| ADR-017 | Runtime evidence for the resolved key contract above; phrase entry and Round 3 product Off mode. | Round 1/3 acceptance; later phrase work | Complete installed IMK acceptance; do not treat core tests or the historical Example Off control as product Off acceptance. See ADR-025 for the source contract. |
| ADR-018 | Runtime evidence for the implemented snapshot/display model above. | Round 1 acceptance; Round 5 geometry | Test mouse press/release, focus, subtitle arrival, screen edges and scale on the installed bundle. |
| ADR-019 | Runtime and quality limits of the selected dictionary above. | Round 2 acceptance; Round 5 latency | The 0.0.7 Notes subtitle/commit cases have bounded user-reported passes; broader installed coverage and visible-panel latency remain unverified. One displayed sense is not a professional quality rating. |
| ADR-020 | What is the measured local latency envelope on the supported devices and corpus? | Round 2 baseline; Round 5 acceptance | Measure valid visible translation end-to-end; report cold/warm distributions, maxima, misses, and timeouts without weakening the 150 ms criterion. |
| ADR-021 | What exact outbound-text, retention, cache, and sensitive-field policies apply? | Round 3–4 | ADR-025 resolves local context/retention/sensitive-field scope. Installed acceptance remains pending; Round 4 must separately define outbound provider policy without whole-field forwarding or plaintext diagnostic capture. |
| ADR-022 | Which provider protocol variants and endpoint rules are actually supported? | Round 4 | Separate contract tests, live requests, and quality/latency results for each provider. |
| ADR-023 | What OS/architecture combinations may be advertised as supported? | Round 5–6 | Distinguish compilation from actual runtime verification, including macOS 14 and Intel. |
| ADR-024 | What source delivery method and artifact set satisfy the chosen GPL distribution path? | Before first external binary; final review in Round 6 | Map exact binary to complete corresponding source, dependencies, scripts, notices, and checksums. |

## Deferred or excluded decisions

- Do not decide a new candidate UI dependency unless Squirrel's panel fails a documented requirement.
- Do not start a self-written pinyin engine, cloud sync, URL-level rules, additional languages, automatic updater, or notarized installer in v0.1.
- Do not infer permission to push, release, or distribute from approval to implement.
- Do not introduce a specific cloud model, API key, paid service, or bundled local model merely because the architecture supports it.
- Keep prior proposed translation shortcuts and English phrase-entry shortcuts explicitly tentative until ADR-017 is resolved.
