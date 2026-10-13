# Round 3 — Context, rules and mode control

Updated: 2026-10-13, America/New_York. Repair artifact: **0.0.8**;
currently installed: **0.0.7**. Round 3 installed acceptance remains partial.
Round 4 is conditionally authorized after all executable Round 3 acceptance
and has not started. Commits stay local; no automatic replacement or push.

## Current repair and acceptance record

The global Secure Event Input flag previously became persistent AX secure-field
evidence, so release could leave the controller in passthrough until
reactivation. The repair separates the live OS flag from field evidence and
schedules a bounded metadata-only review after release. Input stays literal
and translation remains disabled while waiting. A second review finding was
fixed: metadata-only reads must validate final focus/global/deadline state.
Stale focus results keep protection and block retries until field/input-source
reactivation, avoiding a per-key query loop. Known AX secure fields stay
protected. Denied/unsupported/timeout uses existing fallback; it is not a safe
field certification. Off schedules no capture.

Changed production modules: `ContextPolicy.swift`, `ContextCapture.swift` and
`SquirrelInputController.swift`; regressions are in the three existing Round 3
test files. Both project configurations are version 0.0.8. Bilingual README,
upstream modification record, decisions and acceptance ledgers are updated.
No new dependency, cloud integration or permission prompt was added.

| Verification on repaired source | Result and scope |
| --- | --- |
| Policy / capture-settings / async | **PASS**: 166 / 100 / 42 checks. Includes release, reentry, cancellation, Off, unavailable metadata and stale focus. |
| Existing regressions | **PASS**: 79 core, 22 host, 12 guards, 60 real-engine, 72 Shift/router, 136 dictionary checks. Synthetic hosts; no installed IMK claims. |
| Offscreen settings layout | **PASS**: 18 controls, 8 labels. No live button interaction. |
| Build / resources / links / strict ad-hoc signature | **PASS**: arm64 Debug, macOS 14 target. No compiler/linker warnings; one inherited AppIntents metadata extraction warning. |
| Source and artifact correspondence | **PASS**: 40 tested inputs, 42 engine/resource files and 86 repair-bundle file hashes recorded; bundled README matches. |
| Independent source re-review | **PASS, bounded**: recovery/focus findings resolved; no new confirmed P1/P2. Tests do not exercise full InputController/IMK scheduling. |
| Repaired installed acceptance | **NOT_RUN**: 0.0.8 has not been installed. Current 0.0.7 still matches all 86 original delivered hashes. |

Exact retained outputs:

```text
.artifacts/builds/round3-secure-recovery-008-20261013a/DerivedData/Build/Products/Debug/EcholME.app
.artifacts/tests/round3-secure-recovery-20261013a/
.artifacts/tests/round3-secure-recovery-20261013a-r2/
.artifacts/tests/round3-secure-recovery-20261013a-r2-r1/
```

[Repair evidence](evidence/secure-input-recovery-008.json) preserves exact test
reports, hashes and build warnings. [Installed observations](evidence/installed-acceptance-007.json)
and [manual acceptance](MANUAL_ACCEPTANCE.md) distinguish the user's physical
0.0.7 passes from CU limits. Notes Chinese/English commits, both Shift sides and
menu/Off cases passed as reported by the user. Computer Use typed letters did
not exercise the same path; later AX snapshots did not corroborate the edits.
The IME Accessibility switch is off in System Settings. The user opened Input
Context, but CU repeatedly timed out inspecting that app. No permission or
rule change was made, and no settings-interaction pass is claimed.

Remaining gate: installed 0.0.8 recovery, Auto fallback/live context, rule and
learning UI, sensitive-field behavior, Off Tab/shortcuts, format input,
About/licenses, HUD geometry/timing and applicable cross-host checks. Real
nearby-text sampling is blocked by the current permission state; Terminal CU
was denied and Xcode UI unavailable. These limits are not passes. Complete
executable cases and record unavailable ones before advancing to Round 4.
No installation replacement, deletion, push, public release or Round 4 work
occurred in this repair increment.

## Original 0.0.7 delivery snapshot (historical)

The sections below preserve the source-delivery state before the subsequently
authorized installation and physical checks above. Their NOT_RUN results are
historical, not a replacement for the current per-case ledger.

Date: 2026-10-12, America/New_York. Version: **0.0.7**.
Status: **IMPLEMENTED_AND_BUILT_WITH_INSTALLED_ACCEPTANCE_PENDING**.
Branch: `codex/round-3-context`.
This increment does not install, enable, register, push, release, or start Round 4.

## Round 2 closeout

Before Round 3 changes, a read-only audit matched all 27 source hashes and 86
bundle file hashes recorded for 0.0.6; strict signature verification passed.
No extra bundle files or blocking P1/P2 defect were found in the bounded review
of dictionary delivery, cancellation, timeout/miss separation and translated
commit scope. The 0.0.4 removal was already recorded by `323d902`. The install
path is absent; 0.0.6 remains retained but was never installed. Historical
TextEdit results apply only to the exercised 0.0.4 cases. Physical Shift, repaired
menu input and cross-host acceptance remain **NOT_RUN**. Round 2 is closed for
source delivery with these limits; it is not a complete runtime acceptance pass.

## Delivered behavior

- **Auto** is the initial setting. Safety, current manual choice, explicit app
  rules, field/text evidence, opt-in learned preference, built-in app defaults,
  and the global fallback resolve in that order. The fallback is Chinese;
  Xcode, Terminal and iTerm have an English fallback. Rules match exact IDs.
- **Chinese / English** persist as explicit modes. Left Shift and schema right
  Shift retain the existing key contract and set a focus-scoped override after
  a successful change. Selecting Auto or activating a new focus clears that
  temporary override. Same-language selection preserves composition; a
  different language uses the guarded raw-commit path.
- **Off** explicitly finalizes pending raw text once, then returns keys to the
  host. It neither starts English token composition nor submits translations.
  Known sensitive fields and Secure Event Input also bypass composition and
  translation, discarding a stale pending composition rather than inserting it
  into a newly identified sensitive field. They outrank manual settings.
- Automatic changes do not rewrite Rime's inline ASCII state during a Chinese
  composition. Queued context evidence must match request, session, focus
  generation and composition revision. Same-focus safety evidence can still
  block after a revision change. This prevents our own marked pinyin from
  becoming an English hint for the next word.
- A nonactivating HUD shows the mode for approximately 0.8 seconds with a fade;
  the next input key hides it. Its anchor uses guarded IMK caret geometry and
  screen clamping; unavailable geometry uses the pointer as a fallback.
- **Language & App Rules…** configures mode, fallback, context analysis, exact
  app rules and learning. Learning is disabled initially. It stores only app
  ID, direction and a capped count; three consistent choices qualify as a
  learned fallback. Rules/learning jointly allow 128 IDs; the versioned JSON
  in the product UserDefaults domain is limited to 64 KiB. Invalid input leaves
  active preferences intact. Invalid persisted bytes fall back without being
  overwritten until an explicit valid change. The UI can clear learned values.
- **About EcholME / Open Source Licenses…** shows the actual bundle version and
  opens inherited GPL, dependency and CC-CEDICT notices. The product settings
  window is excluded from input-method composition.

## Context access and privacy

Only copied classifications leave the background capture adapter. IMK client
objects never cross threads. Auto may read up to 128 UTF-16 units immediately
before an empty caret using AXStringForRange. It never requests AXValue,
selected text, window titles or document URL attributes. Role/subrole detect
text, search and secure fields; conservative whole-sample syntax recognizes
some code/URL/email literals. Chinese/Latin script dominance is a direction
hint, not general semantic language detection. Search syntax stays neutral.

Text is transient and never written to context settings, logs or network.
No AX prompt occurs. Explicit language and context-disabled modes capture
safety metadata only; Off starts no capture. Activation triggers sampling;
selecting Auto while idle can obtain missing evidence. A settings change that
just finalized a composition does not reread that output. Changing surrounding
text later generally requires field/input-source reactivation to resample.

One serial worker and one replaceable pending request bound concurrency. AX
messages use a 25 ms best-effort timeout and a 150 ms processing budget; a
200 ms main-queue watchdog completes the decision with fallback. Cancellation
skips queued work and rejects callbacks, but cannot forcibly interrupt every
in-progress OS IPC. These are budgets, not measured end-to-end latency claims.
Context failure leaves normal input usable. Host-provided security metadata can
be absent or nonstandard; detection is not a guarantee for every third-party
password-like field. Secure Event Input is checked locally on every event.

## Changed modules

```text
sources/
  ContextPolicy.swift             classifier, priority, sampling and request gates
  ContextCapture.swift            background AX adapter, queue, watchdog, cancellation
  ContextSettingsWindow.swift     bounded settings store and native UI/About
  ModeHUD.swift                   nonactivating transient mode panel
  CompositionState.swift         Codable direction; shared guarded Off finalization
  SquirrelInputController.swift  lifecycle/mode/translation integration
tests/
  Round3Checks.swift              synthetic classification, priority and lifecycle policy
  ContextCaptureChecks.swift      bounded reads, sensitive fields, invalid settings
  ContextAsyncChecks.swift        queue, timeout, cancellation and callback fault injection
  Round1Checks.swift              added Off commit/reentrancy regressions
  ShiftRegressionChecks.swift    added Off handoff with pinned real librime
tools/
  check_round3.py                 fresh retained test outputs; prior-round regressions
  ContextSettingsPreview.swift   offscreen production settings view with synthetic values
Squirrel.xcodeproj/project.pbxproj  compiled modules and version 0.0.7
docs/project/, docs/round2/, docs/round3/, README.md, CHANGES_FROM_UPSTREAM.md
```

## Verification

Final evidence is in [verification.json](evidence/verification.json). All 40
recorded source/test/tool inputs match the final source. All 86 bundle files
have recorded SHA-256 hashes, and its bilingual README matches the repository.
The final documentation-only rebuild updates the idle Auto resampling wording.
Production/test/tool inputs remain identical to the authoritative run; tested
engine/resource and lexicon bytes were compared against its engine artifact.

| Check | Result | Scope |
| --- | --- | --- |
| Context policy and request identity | **PASS**, 104 checks | Script hints, priority collisions, freeze, mode changes, idle resampling and stale self-preedit rejection. |
| Context adapter and settings store | **PASS**, 86 checks | Fake fields; no real AX text reads. Sensitive/denied/stale/oversized inputs and in-memory persistence faults. |
| Async context delivery | **PASS**, 34 checks | Real production queue with injected readers: serialization, coalescing, watchdog, cancellation, expired work and recovery. |
| State/key/layout regression | **PASS**, 79 checks | Includes same-mode preservation and guarded Off completion/reentrancy. |
| Objective-C host wrapper | **PASS**, 22 checks | Selector/exception handling with synthetic hosts. |
| Build/install tool guards | **PASS**, 12 checks | Mocked safety guards; no installation. |
| Real pinned librime | **PASS**, 60 checks over 10 cycles | Chinese candidate/commit, numeric selection, Esc, preview scope and no duplicate engine text. |
| Production Shift router + real librime | **PASS**, 72 checks | Synthetic modifier and host events; includes Off raw-finalization. Not a physical Shift test. |
| Offline dictionary/cache/timeout regression | **PASS**, 136 checks | Rebuilt pinned index verifies; existing direction/commit/cancellation contracts hold. |
| Production settings view | **PASS**, offscreen | 18 controls in bounds, 8 labels unclipped; inspected synthetic screenshot. No visible window or button interaction. |
| xcodebuild and static bundle verification | **PASS** | arm64 Debug, macOS 14 target, resources, dependency paths and strict local ad-hoc signature. |
| Installed IMK/physical keyboard/HUD and real contexts | **NOT_RUN** | No package installed, registered or enabled in this increment. |

The build has no compiler/linker warnings; one inherited AppIntents message
states that metadata extraction was skipped because AppIntents.framework is
not a dependency. Checks compiled with `-warnings-as-errors`. The actual
build log and all outputs remain retained; no clean operation ran.

Final artifact:

```text
.artifacts/builds/round3-context-final-007-20261012b/DerivedData/Build/Products/Debug/EcholME.app
```

Authoritative run:

```text
.artifacts/tests/round3-context-final-check-20261012b/
.artifacts/tests/round3-context-final-check-20261012b-r2/
.artifacts/tests/round3-context-final-check-20261012b-r2-r1/
```

Review found and fixed the self-preedit evidence race and ignored-mode text
capture; subsequent bounded independent review found no remaining confirmed
P1/P2 issue. This is a review result, not proof of crash freedom. These checks
do not establish installed menu/keyboard behavior or live AX capability in
Notes, Xcode, Terminal, Electron, browsers, secure fields or multiple displays.

## Reproduction and installation boundary

Use a new build/run ID each time; outputs are deliberately retained.

```sh
cd /Users/zhenkun/GitHub/LiangYi-EcholME
python3 -B tools/round0.py build --build-id YOUR_NEW_BUILD_ID
python3 -B tools/check_round3.py --run-id YOUR_NEW_RUN_ID --engine-bundle .artifacts/builds/YOUR_NEW_BUILD_ID/DerivedData/Build/Products/Debug/EcholME.app
python3 -B tools/round0.py verify --bundle .artifacts/builds/YOUR_NEW_BUILD_ID/DerivedData/Build/Products/Debug/EcholME.app
```

The engine option writes fresh validation data only inside the authorized
LiangYi data/log roots. No existing dictionary is loaded. The test runner uses
synthetic adapters, not live document queries. Do not run inherited clean or
replacement-install targets. Follow [manual acceptance](MANUAL_ACCEPTANCE.md)
one checkpoint at a time after the user confirms installation.

## Limits and next gate

- **NOT_RUN:** installed 0.0.7 IMK behavior, physical left/right Shift, real
  permission denial/grant transitions, focus changes, HUD fade/position across
  displays, runtime stability in the target hosts, visible subtitle latency.
- **NOT_RUN:** runtime macOS 14, Intel or universal distribution. The development
  build targets macOS 14 on arm64; a deployment target is not runtime testing.
- Context is heuristic and intentionally sparse; very fast first typing may
  invalidate a sample and retain fallback for that focus. It does not examine
  each newly typed word to distinguish English from pinyin.
- The existing one-word English composer and CC-CEDICT one-sense quality limits
  remain. No cloud/model API, credential storage or new dependency is added.
- GPL source headers, original notices and dictionary attribution remain in
  source and the bundle. Full corresponding-source release preparation and
  external distribution review remain separate, unexecuted gates.
- No request to enter Round 4 is inferred. Install and manually accept this
  build before expanding provider work; all commits stay local.
