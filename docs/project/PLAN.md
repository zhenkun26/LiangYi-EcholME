# LiangYi / EcholME — Approved Delivery Plan

Status: **Approved for sequential delivery. Round 0 and Round 1 are delivered with their recorded verification limits. Round 2 was authorized on 2026-10-12; stop before Round 3.**

Plan recorded: 2026-10-11, America/New_York.

Chinese product name: **两仪**. English product name: **EcholME**. Preserve this spelling; it is the user-approved name associated with an echo.

This document preserves the plan approved in the project conversation. It is the durable project memory for scope, architecture, delivery gates, and operating boundaries. It is a plan, not evidence of implementation, compilation, installation, runtime behavior, or license compliance. Current evidence belongs in [STATUS.md](STATUS.md); decisions and unresolved questions belong in [DECISIONS.md](DECISIONS.md).

## 1. Authorization and delivery boundaries

The user approved the Squirrel-derived route and requested durable project documentation and Git version management. Initial authorization covered Round 0 only. After its closeout, the user explicitly authorized **Round 1 only**: define the key contract, unify state/commit management, and implement horizontal two-line candidates with example subtitles. Option+Return was selected for translated commit. On 2026-10-12 the user authorized **Round 2 only** after the Round 1 source and automated checks were revalidated. Round 1 installed IMK acceptance remains NOT_RUN and is not treated as a pass. Stop after Round 2 delivery and wait for confirmation before Round 3. Repeat this boundary between all later rounds.

The authorized sequence is:

1. Persist the complete plan and establish appropriate Git version management.
2. Carry out the currently authorized round only (now Round 2).
3. Report changes, verification results, limitations, and remaining work.
4. Wait for the user before beginning Round 3.

Additional boundaries:

- Do not push commits, create a public release, notarize, deploy, or distribute publicly without explicit authorization for that action and destination. Approval to implement is not approval to publish.
- Preserve unrelated user work. Do not invent Git author identity, credentials, test results, supported platforms, or performance measurements.
- Follow the user's no-deletion rule: no filesystem deletion, trash operation, whole-file deletion, destructive cleanup, or equivalent workaround. Existing install targets must cause a preflight stop. Do not rename or move an existing target merely to evade this boundary.
- Runtime acceptance exception authorized on 2026-10-11: librime may perform normal generated-file/database maintenance only inside the independent LiangYi data and log directories. Squirrel and other user data remain protected. The original exception accompanied Round 0; later Round 1 authorization does not broaden its writable roots or permit manual deletion or pushing.
- Round 0 closeout was authorized on 2026-10-11. The bounded remaining checks and delivery record supersede earlier per-case waiting checkpoints. See [STATUS.md](STATUS.md) for what passed and what remains unverified; closeout does not turn missing checks into passes.
- Inspect upstream build, install, test, and dependency scripts for deletion and other side effects before running them. Installing already-declared dependencies within the approved scope is distinct from adding a new dependency; ask before introducing dependencies beyond the approved Squirrel/librime baseline. The approved route does not preapprove every upstream optional component, resource, dataset, or new service.
- Build/install success, automated checks, manual acceptance, and measured runtime behavior are separate claims.
- Project documents and authored code are primarily English. User-facing reports are Simplified Chinese. The new project's README must be bilingual English and Simplified Chinese.
- Scope expansion or a new round requires user confirmation. Routine implementation details within the current round may be resolved independently.

## 2. Product definition and MVP scope

### Confirmed requirements

- macOS 14 minimum; Swift primarily, with Objective-C/C++ bridging where justified.
- A native InputMethodKit input method derived from Squirrel and using librime rather than a newly written pinyin engine.
- The first usable internal version must support both directions: Chinese pinyin input with English subtitles, and English input with Chinese subtitles.
- Main candidate text and its translated subtitle have explicit, separate commit actions.
- Candidate layout confirmed during Round 0 acceptance: candidates run horizontally; each candidate column shows primary text on the top line and its corresponding opposite-language translation below. English primary input reverses the two languages. Round 1 owns the initial layout with fixtures; Round 2 supplies real translations. This requirement does not authorize a Round 0 layout change.
- Automatic direction primarily uses nearby text and field type. App-level rules are fallback signals; explicit user rules and manual choices remain authoritative within the defined priority system.
- Words and common phrases are the initial translation priority: offline, lightweight, and fast.
- Users may select local-only, local-first, or model-API-first translation behavior.
- Planned provider coverage includes DeepSeek, GLM, OpenAI, Kimi, Claude, Gemini, MiMo, MiniMax, and custom endpoints. Shared protocol implementations are permitted only when compatibility is verified.
- Mode switching, a short-lived HUD, configuration, diagnostics, and development installation/reload guidance are part of v0.1.
- The project is intended for future GitHub open-source distribution. GPL distribution preparation is part of this route; actual publication is a separate authorization boundary.

### Proposed modes requiring precise interaction specification

The design starts from `Auto`, `Zh→En`, `En→Zh`, and `Off`. Round 1 must define the exact meaning of Off and every key action. These names do not resolve whether an operation affects translation, composition, or input passthrough.

Round 1 specifies Space, digits, Tab, Return/keypad Enter, Esc, punctuation, deactivation and focus loss in the [key contract](../round1/KEY_CONTRACT.md). The user selected Option+Return for translated commit. English words are letter-started tokens; spaces commit a token and retain the separator. Multiword English phrase composition, automatic direction and the complete mode UI remain later work. The temporary Example Off control disables examples and English token interception; it is not the complete future Off mode. Tab remains a host action after raw finalization.

### MVP boundaries

- Round 2 is the first complete **internal offline bidirectional experience**, not the complete v0.1 release candidate.
- Round 6 is the **v0.1 release candidate**, with accurate verification and distribution materials.
- A real offline dictionary is required. Target at least 2,000 deduplicated English headwords with Chinese mappings; count common phrases separately. Chinese-to-English coverage and quality must be measured separately rather than inferred from reversing the same table.
- Existing Rime comments, translation subtitles, and the text to be committed are distinct data.
- Translation failure must not prevent normal input.

### Backlog outside v0.1

- A self-developed full-sentence pinyin engine.
- Cloud synchronization.
- Browser URL-level rules.
- Additional language pairs.
- Automatic application updates.
- Notarized installer distribution.

Local small-model inference is an extension point, not a requirement to bundle a model in v0.1. Public release and notarization remain separately authorized activities.

## 3. Architecture and module ownership

Squirrel provides the initial host and librime integration. Reuse its existing native panel before considering another UI implementation. Do not introduce McBopomofo CandidateUI as a second candidate implementation in parallel; retain its design and tests as references. Reconsider replacement only if a documented capability gap is demonstrated.

| Category | Module | Planned handling and boundary |
| --- | --- | --- |
| Reuse | IMK startup and lifecycle | Retain startup, activation, deactivation, and input-source infrastructure; add EcholME session identity. |
| Reuse | librime integration | Retain initialization, sessions, key mapping, candidate retrieval, commits, and resource release. |
| Reuse | Candidate window foundation | Retain nonactivating NSPanel, placement, paging, highlighting, themes, and baseline mouse handling. |
| Reuse | Host compatibility handling | Preserve relevant upstream application workarounds and regress them after changes. |
| Adapt | Product identity and storage | Isolate bundle ID, input-source IDs, IMK connection, configuration, user dictionaries, logs, notifications, and update endpoints. |
| Adapt | Input controller | Add Chinese, English, and passthrough routing without placing translation business logic throughout the controller. |
| Adapt | Candidate data path | Replace assumptions based on parallel text arrays with snapshots carrying stable candidate identity, composition revision, and displayed revision. |
| Adapt | Candidate Panel/View | Add horizontal candidate columns with primary text above the matching translation, translation states, partial refresh, explicit subtitle actions, and accessibility descriptions. |
| Adapt | App rules | Integrate with one priority system so application rules do not compete with context detection. |
| Adapt | Build and installation | Pin dependencies, support user-directory installation, and inspect upstream script side effects. |
| New | `EnglishComposer` | Manage English words, phrases, spaces, punctuation, cancellation, and raw-text commit. |
| New | `SessionState` and `CommitCoordinator` | Own composition, focus generations, cancellation, and the sole host-write boundary. |
| New | `ContextDetector` and `ModeResolver` | Collect available context signals and produce direction, confidence, reason, and deterministic fallback. |
| New | `TranslationCoordinator` and `TranslationRouter` | Coordinate local/API preference, caching, cancellation, timeouts, rate limits, circuit breakers, and stale-result rejection. |
| New | Dictionary and backend adapters | Provide bidirectional lookups, morphology/polysemy treatment, provider protocol mapping, and resource provenance. |
| New | Settings, credentials, and diagnostics | Provide rule editing, Keychain integration, redacted logs, performance records, and diagnostic export. |
| New | Test fixtures and distribution checks | Provide fake host clients, network faults, panel tests, bundle/resource checks, and licensing checks. |

### Four integration points

1. **Key routing:** select Chinese, English, or passthrough behavior and resolve direction.
2. **Candidate snapshots:** copy engine output into EcholME-owned values, distinguishing a segment from an explicit complete commit preview.
3. **Display updates:** merge translations without changing candidate identity, selection, or page; reject obsolete results.
4. **Unified commit:** validate focus and the displayed version before committing primary or translated text.

Provider calls, caching, credentials, settings, and diagnostics remain outside these integration points. Heavy work should not retain or operate directly on an IMK client.

## 4. Input, translation, and privacy contracts

1. **Synchronous key disposition.** Decide whether a key is consumed or passed through before returning from `handle(event:)`. Network calls, dictionary loading, and Rime deployment must not run in the key handling critical path. A warm, bounded engine key operation may remain synchronous.
2. **One host-write boundary.** Translation components do not retain an IMK client or call `insertText` directly. Validate supported selectors before optional client operations. Handle `NSNotFound`, UTF-16 ranges, actual returned ranges, and selection boundaries explicitly.
3. **Translation scope equals commit scope.** Distinguish Rime segment candidates from complete commit previews. Do not construct a supposed full sentence by guessing how engine fragments concatenate.
4. **Version every asynchronous result.** Check session identity, focus generation, composition revision, candidate identity, direction, and backend configuration version. Cancellation alone is insufficient because a cancelled operation may still finish.
5. **Commit the displayed version.** Track displayed revision separately from current background state. A translation arrival must not silently reorder primary candidates or reset highlight/page.
6. **At-most-once invocation per commit identity.** Correctly terminate the original composition after committing a translation. Do not retry when the outcome of a host insert is uncertain; a void-returning host operation is not an exactly-once transaction acknowledgment.
7. **Freeze direction during a composition.** Avoid switching while the user is typing and avoid language-detection feedback from EcholME's own translated output.
8. **Normal input survives translation failure.** API-first affects the chosen translation source, not the availability of primary-text commit.
9. **Bound context access.** Prefer small surrounding-text snapshots when available. Do not send IMK client objects to background workers, assume a hard timeout can interrupt all synchronous host IPC, or query Accessibility repeatedly for every key.
10. **Protect external data boundaries.** Translation is disabled in sensitive fields. Scenes without a defined outbound policy do not automatically send text. Nearby field content is not automatically included in cloud requests.
11. **Bind credentials to a provider profile and endpoint origin.** Do not forward credentials through cross-origin redirects or retry against a different provider by default. Treat model output as untrusted text and enforce length/format limits.
12. **Minimize retained sensitive data.** Default logs contain neither typed text, translated text, nor secrets. User dictionaries, cached text, and diagnostic exports require explicit retention and redaction policies.
13. **Do not confuse no-result with failure.** Transient transport/provider errors must not be recorded as evidence that a word has no translation.
14. **Isolation is not authentication.** If a service process is used, define peer authentication, bounded messages, and lifecycle behavior. Choose the concrete mechanism after Round 0 capability validation.

## 5. Context and mode resolution

Proposed priority, to be implemented and tested in Round 3:

1. Safety restrictions.
2. Current explicit manual choice.
3. User-configured force rules.
4. Field type and nearby text evidence.
5. Learned preferences.
6. Built-in application defaults.
7. Global default.

Built-in defaults for Xcode, Terminal, and iTerm lean toward English-to-Chinese, but must not override a higher-priority rule. Field access may fail or return insufficient data; failures must lead to a documented fallback rather than a stalled key event. Learned preferences cannot override explicit rules.

Language metadata must be checked against the macOS 14 deployment target; a newer Accessibility attribute must not be assumed available. No permission should be required merely to perform ordinary input.

## 6. Round-by-round delivery plan

Each round's user-facing delivery includes: objective, changed file tree, relevant complete implementation where needed, build/install/verification commands, measured verification results, limitations, and proposed next round. Do not claim an installation or reload command is verified until it has actually been tested on the stated environment.

### Round 0 — Derived baseline and safe coexistence

**Goal:** Establish a source-traceable, independently identified input-method baseline and evaluate required platform capabilities before changing input semantics.

**Deliverables:**

- Pinned Squirrel and librime revisions, recursive dependency/resource inventory, and toolchain record.
- Upstream provenance and initial license/resource manifest.
- Independent EcholME identifiers and storage paths.
- Reviewed build entry point, environment diagnostics, and first-install preflight.
- A capability report covering caret geometry and context access in Notes, Xcode, and Terminal.
- ADRs for the derived boundary, state ownership, installation policy, and cloud-task isolation approach.
- A baseline that preserves inherited Chinese input behavior; new bidirectional semantics belong to later rounds.

**Main risks:** Reusing Squirrel data paths or update endpoints; toolchain/deployment-target mismatches; differing host context support; incomplete dependency or data licenses; upstream script deletion.

**Acceptance:**

- Report build, install, registration, selectability, and real input as separate results.
- Verify coexistence without modifying the user's Squirrel configuration or dictionaries.
- Regress inherited Chinese input behavior.
- Exercise Return with a composition, without a candidate, and with an empty composition separately. Cover punctuation, digits, special characters and mixed input in Notes, Xcode and Terminal; record untested combinations explicitly. Paste-based fixtures do not establish typed-key behavior.
- Context/caret capability failures have documented fallbacks and do not block input.
- No new compiler warnings; list unresolved inherited warnings explicitly.
- Do not include license-unknown dependencies or data in the accepted baseline.
- If the environment prevents a check, record the reason and impact instead of treating the round as fully verified.

**Exit:** Deliver Round 0 only and wait for user confirmation before Round 1. The research snapshot is a candidate baseline, not an already validated release.

### Round 1 — Unified state and commit behavior

**Goal:** Establish a reliable input state model and the single commit boundary before connecting real translation services.

**Deliverables:**

- Candidate snapshots, session state, and unified commit coordinator.
- Baseline English composition and primary-text commit.
- Initial horizontal, two-line panel layout: one primary/translation pair per candidate column.
- Deterministic translation fixtures used only to test asynchronous rendering and commit behavior.
- Explicit keyboard interaction table and fake-host tests.

**Main risks:** Swallowed keys, duplicate inserts, writes after focus changes, selection drift during refresh.

Authorized Round 1 follow-up: fix the two P1 Shift/composition review findings,
cover left/right Shift and Chinese/English handoff with regressions, review the
repair and commit locally. The repaired Shift contract finalizes raw input
before a left tap, preserves the right-tap schema binding and keeps live engine
input out of a second English buffer. See the current status/delivery evidence;
this is Round 1 repair, not authorization to begin Round 2.

The 2026-10-12 takeover adds bounded maintenance to that same input contract
on the current offline-dictionary baseline: repair intermittent left Shift,
provide explicit primary-language menu selection, and perform guided installed
acceptance. This does not start context detection or any later feature round.

**Acceptance:**

- Both Chinese and English primary input work.
- Space, digits, Tab, Return, and Esc each perform their specified behavior exactly once.
- Switching field, input source, or mode invalidates old callbacks.
- Mouse and keyboard selection use the same candidate identity rules.
- A fixture translation commit followed by deactivation does not append the original composition.
- Subtitle refresh preserves highlight/page and never activates the candidate window.
- Fixtures are not presented as completed translation support.

### Round 2 — Real offline bidirectional input

**Goal:** Deliver the first usable internal bidirectional experience with real, licensed local data.

**Deliverables:**

- Bidirectional dictionary, index, provenance/license manifest, and frozen evaluation corpus.
- Chinese pinyin candidates with English subtitles.
- English composition with Chinese subtitles.
- Independent primary/translation commit in both directions.
- Local cache, cancellation, and timeout degradation.
- At least 2,000 deduplicated English headwords with Chinese mappings; separately counted common phrases and independently evaluated Chinese-to-English coverage.

**Main risks:** Unclear dictionary rights, weak polysemy handling, translating a segment as a whole sentence, incorrect asynchronous association.

**Acceptance:**

- Both directions display and commit actual primary and translated text.
- Translation meaning/scope matches what is committed.
- Misses preserve ordinary input; primary-only display does not count as a translation hit.
- Engine comments and translations remain separate.
- Timeouts, cancellation, and response reordering never produce a wrong commit.
- Publish a measured local-latency baseline using the definition in Section 7.

**Exit:** Internal bidirectional milestone only; not the complete v0.1 release candidate.

### Round 3 — Context detection, rules, and HUD

**Goal:** Apply the user's field-first direction preference with transparent and stable fallback.

**Deliverables:**

- Small surrounding-text snapshots, field signals, and local language detection.
- Unified priority resolver, manual override, and mode HUD.
- Defined behavior for denied permissions, empty fields, code, and mixed language.
- Basic rule settings and an About/Open Source Licenses entry point.

**Main risks:** Unavailable context, slow synchronous host calls, unexpected direction changes, incorrect handling of sensitive fields.

**Acceptance:**

- Known samples resolve as specified; ambiguous samples follow published fallbacks.
- Ordinary input works without Accessibility permission.
- No background use of IMK client objects or repeated per-key AX queries.
- Direction remains stable during the current composition.
- Manual choice remains effective; learned behavior cannot override explicit rules.
- Sensitive fields disable translation; undefined outbound scenarios do not automatically send text.

### Round 4 — Cloud providers and configurable routing

**Goal:** Add provider choice while preserving normal input and precise privacy boundaries.

**Deliverables:**

- Local-only, local-first, and API-first modes.
- Provider profiles, Keychain storage, bounded requests, cancellation, timeouts, rate limits, and circuit breakers.
- Isolation of long-running network work from the IME input path through a separate service process; concrete mechanism follows Round 0 findings.
- Adapters and error/compatibility reports for the requested providers and custom endpoints.

**Main risks:** Credentials sent to the wrong endpoint; obsolete results committed across focus changes; provider failure cached as no translation; service-process failure.

**Acceptance:**

- Cover disconnection, timeout, 401, 429, 5xx, reordering, malformed output, and oversized responses.
- Backend/configuration changes invalidate prior requests.
- No default cross-provider retries or whole-field text transmission.
- Service unavailability leaves primary and local input operational.
- Track configuration, contract tests, live requests, and quality/latency separately for each provider. Missing credentials mean live verification is not run.
- A different endpoint address alone is not proof of protocol compatibility.

### Round 5 — Settings, diagnostics, performance, and compatibility

**Goal:** Turn the internal feature set into an observable and testable application.

**Deliverables:**

- Complete settings UI and redacted diagnostics.
- Cache/cancellation/rendering optimization.
- Installation/reload diagnostics and configuration recovery guidance.
- OS/architecture support matrix.
- Actual host, performance, and fault-test reports.

**Main risks:** Main-thread stalls, sensitive logs, flicker, multi-display placement errors, corrupt configuration.

**Acceptance:**

- Real tests pass in Notes, Xcode, and Terminal.
- Cover emoji, selected-text replacement, undo, repeated backspace, and rapid field/input-source switching.
- Verify negative-coordinate displays, screen edges, and different scale factors.
- Logs contain no input body, translation body, or secrets by default.
- No unresolved crash, hang, data-loss, or duplicate-commit blocker observed in the acceptance run.
- Missing macOS 14 or Intel runtime environments are reported as unverified; compilation does not establish runtime support.

### Round 6 — v0.1 release candidate and distribution materials

**Goal:** Produce an accurately documented, source-correlated release candidate. Publication remains separately authorized.

**Deliverables:**

- Final application artifact, complete corresponding-source archive, and checksums.
- Version/commit/dependency/data-resource manifest.
- Bilingual README and build, install, uninstall, permissions, troubleshooting, and backend-extension documentation.
- GPL and third-party notice review record.
- Final acceptance report and known limitations.

**Main risks:** Binary/source mismatch, missing submodule source, unclear dictionary rights, untested provider claims.

**Acceptance:**

- Build the declared artifact from the delivered source archive in a new build directory using documented steps.
- Include necessary resources and notices.
- Rerun affected verification after the final change.
- Release notes accurately state OS, architecture, provider, and performance verification scope.
- Source access and licensing obligations are satisfied before an external test binary is distributed, not merely before a public release.

**Exit:** Release candidate ready for review; no implicit push, release, notarization, or public distribution.

## 7. Verification, measurements, and expert reviews

### Evidence layers

1. Pure logic tests: state transitions, routing, version checks, UTF-16 ranges, cache semantics.
2. Fake-host tests: insert/marked-text ordering, deactivation, missing selectors, uncertain commit outcomes.
3. Independent panel tests: selection preservation, resizing, positioning, accessibility, no activation.
4. Real IMK/application tests: actual installation, registration, selection, input, focus changes, and host compatibility.
5. Fault injection: delayed/reordered callbacks, network failures, malformed data, service-process failure, missing context, configuration problems.

Report checks as `PASS`, `FAIL`, `BLOCKED`, or `NOT_RUN` with reasons. Use `NOT_APPLICABLE` only when a check genuinely does not apply, not when it could not be performed. Keep automated checks, manual acceptance, and live provider calls distinguishable.

### Local 150 ms requirement

Measure from input change to the first visible corresponding **valid translation**, including queuing and rendering. Record hardware, OS, corpus, cold/warm conditions, percentiles, maximum, and timeout count. Do not replace the agreed limit with a P95-only claim. A dictionary miss, original-only display, or empty output is not successful translation. Report cloud latency separately. Specify the accepted corpus and supported device conditions before making a bounded performance claim.

### Stability requirement

The operational release gate is no known unresolved crash, hang, lost-text, or duplicate-insert blocker in the acceptance run. Do not claim that Swift `do/catch` prevents every Objective-C/C++ crash or synchronous IPC hang. Use bounds checking, isolation, fault tests, and recovery behavior as appropriate.

### Expert review gates

- Product/project review: scope, journey, interaction ambiguity, milestone completeness, and risk register.
- Architecture review: contracts, state ownership, platform capability limits, upstream divergence, and ADRs.
- QA review: input correctness, fixture realism, fault coverage, performance measurement, and manual evidence.
- Security/privacy review: data collection, sensitive-field rules, credentials, outbound text, local caches, and logs.
- Delivery/operations review: build/install side effects, coexistence, diagnostics, source reproducibility, and GPL materials.

Independent components may be developed in parallel after input-state and commit contracts are agreed. Integration and round acceptance remain sequential. The project is macOS-focused; Windows-specific security checks from the original example do not become requirements without a Windows scope change.

## 8. GPL and third-party distribution lifecycle

The approved route includes GPL-derived distribution preparation. Verify exact upstream grant wording and component licenses before choosing SPDX identifiers; do not infer `-only` versus `-or-later` from the presence of a generic GPL text.

| Stage | Required preparation |
| --- | --- |
| Round 0 | Preserve copyright, license text, and disclaimers; record upstream revisions and actual grants. |
| Every changed increment | Identify the derived project and significant modifications/dates without erasing upstream authorship. |
| Dependency/resource introduction | Review code, frameworks, plugins, pinyin schemas, dictionaries, icons, and other redistributed assets separately. |
| Before the first external test binary | Provide source and necessary build/install material corresponding to that exact binary through a GPL-compatible delivery method. |
| Release candidate | Validate complete corresponding source, necessary submodules/non-system dependencies, scripts, and notices. |
| Network distribution | Make corresponding source obtainable alongside the binary under the applicable GPL terms; do not rely only on a moving main branch. Preserve recipients' modification and redistribution rights. |

Planned distribution records:

- `UPSTREAM.md`.
- `CHANGES_FROM_UPSTREAM.md`.
- `THIRD_PARTY_NOTICES.md` and `LICENSES/`.
- Dependency lock records and resource/data manifests.
- A release manifest mapping versions, source commits, dependencies, data, and checksums.
- An independently checked corresponding-source archive, including required submodule contents rather than only a root-repository archive.

Additional boundaries:

- Do not represent copied GPL frontend implementation as MIT code.
- MIT/BSD libraries and each dataset retain their own notices and terms within the overall distribution.
- Public source must not contain API keys, signing identities, private certificates, or user data.
- Provide a local-signing development path that does not require the publisher's certificate.
- Do not promise bit-for-bit equality of signed binaries; define reproducibility at an honest, verified level.
- Ordinary use of an independent remote model API does not automatically make the provider's implementation part of the client's corresponding source. A process boundary alone is not sufficient grounds to declare a tightly coupled component independent.
- GPL preparation does not authorize public distribution, a Git push, or a release.

## 9. Installation, reload, and environment boundaries

- Development installation targets `~/Library/Input Methods/` and isolated EcholME data paths.
- Preflight the destination and available permissions. Stop if replacement would require prohibited deletion.
- Do not run inherited install/cleanup commands without reviewing them. Do not unconditionally change permissions on system directories, delete keyboard caches, kill system UI, or execute a generic global reload command.
- Document which process can safely be restarted and which changes require manual input-source reselection or logout, based on observed behavior.
- User-driven deletion is required where uninstall or replacement actually needs it; provide a precise explanation instead of performing it.
- Identify App Sandbox, signing, and service entitlements explicitly. Development signing is separate from notarized distribution.
- Some host/UI checks require an interactive user environment. Record these as unverified when unavailable; do not use a compile result as a substitute.

## 10. Research references and baseline candidates

These are the fixed snapshots used in planning. They are reference evidence, not proof that a revision builds or runs on the user's machine. Round 0 must verify the chosen baseline and record any intentional deviation.

| Project | Planning snapshot | Role |
| --- | --- | --- |
| Squirrel | `769ae426f33f500266101a88f694aab0d158e680` | Preferred derived macOS frontend; GPL licensing and host/panel references. |
| librime | `33e78140250125871856cdc5b42ddc6a5fcd3cd4` | API and BSD license research; use the actual pinned compatible dependency during implementation rather than assuming this independent snapshot is compatible. |
| Water-sequoia / msime | `330d0fd25053aae29184dcb02ab66812f4a8e717` | Translation selection/commit correctness, fake-host tests, panel positioning, and distribution-test ideas. |
| McBopomofo | `be6564acad6c4d3265c34a2e1a872d80f9db6068` | MIT component comparison, state model, and CandidateUI testing ideas; not an additional adopted UI dependency. |
| Fcitx5 for macOS | `8edbfe59f64ae5de9d0db20d7910c27f937e0f33` | Alternative framework comparison and context-access reference; not the selected implementation route. |

Primary references:

- [Squirrel input controller](https://github.com/rime/squirrel/blob/769ae426f33f500266101a88f694aab0d158e680/sources/SquirrelInputController.swift).
- [Squirrel candidate panel](https://github.com/rime/squirrel/blob/769ae426f33f500266101a88f694aab0d158e680/sources/SquirrelPanel.swift).
- [Squirrel entry point and paths](https://github.com/rime/squirrel/blob/769ae426f33f500266101a88f694aab0d158e680/sources/Main.swift).
- [Squirrel Info.plist](https://github.com/rime/squirrel/blob/769ae426f33f500266101a88f694aab0d158e680/resources/Info.plist).
- [Squirrel build/install rules](https://github.com/rime/squirrel/blob/769ae426f33f500266101a88f694aab0d158e680/Makefile).
- [Squirrel license](https://github.com/rime/squirrel/blob/769ae426f33f500266101a88f694aab0d158e680/LICENSE.txt).
- [librime C API](https://github.com/rime/librime/blob/33e78140250125871856cdc5b42ddc6a5fcd3cd4/src/rime_api.h).
- [librime license](https://github.com/rime/librime/blob/33e78140250125871856cdc5b42ddc6a5fcd3cd4/LICENSE).
- [Water-sequoia candidate identity](https://github.com/metasequoiaime/msime/blob/330d0fd25053aae29184dcb02ab66812f4a8e717/platforms/macos/src/input/InputController.mm#L678-L724).
- [Water-sequoia translation commit](https://github.com/metasequoiaime/msime/blob/330d0fd25053aae29184dcb02ab66812f4a8e717/platforms/macos/src/input/InputController.mm#L1800-L1818).
- [Water-sequoia fake-host tests](https://github.com/metasequoiaime/msime/blob/330d0fd25053aae29184dcb02ab66812f4a8e717/platforms/macos/tests/core/TextClientTest.mm).
- [Water-sequoia placement tests](https://github.com/metasequoiaime/msime/blob/330d0fd25053aae29184dcb02ab66812f4a8e717/platforms/macos/tests/candidate/CandidatePlacementTest.mm).
- [McBopomofo CandidateUI package](https://github.com/openvanilla/McBopomofo/blob/be6564acad6c4d3265c34a2e1a872d80f9db6068/Packages/CandidateUI/Package.swift).
- [McBopomofo input state](https://github.com/openvanilla/McBopomofo/blob/be6564acad6c4d3265c34a2e1a872d80f9db6068/Source/InputState.swift).

## 11. Completion reporting

Before the final commit of an authorized increment, update [STATUS.md](STATUS.md) with actual scope, evidence, limitations, and delivery state. Review the diff and run checks appropriate to the final content. Commit only authorized work using the established repository conventions and verified Git identity. Report the final commit hash when a commit exists.

Round 0 delivery must not imply Round 1 authorization. Any missing runtime acceptance remains visible in the report. If a material blocker prevents completion, state what is complete, what is blocked, why, and what input or environment change is required.
