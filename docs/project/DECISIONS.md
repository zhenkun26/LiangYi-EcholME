# LiangYi / EcholME — Decision Register

Recorded: 2026-10-11, America/New_York.

This is the decision index for the approved [delivery plan](PLAN.md). An accepted direction is not a claim that its implementation or runtime acceptance has passed. Detailed ADRs may be added during the round that owns the decision.

## Accepted decisions

| ID | Decision | Status | Basis and consequence |
| --- | --- | --- | --- |
| ADR-001 | Derive the macOS frontend from Squirrel and retain librime. | ACCEPTED | User selected this route to avoid rebuilding the mature host and pinyin integration. |
| ADR-002 | Preserve the names 两仪 and EcholME; target macOS 14; use Swift primarily. | ACCEPTED | Explicit product/platform requirements. ObjC/C++ bridging is permitted where justified. |
| ADR-003 | First usable internal experience must support Chinese→English and English→Chinese. | ACCEPTED | Round 2 is the internal bidirectional milestone; Round 6 is the full v0.1 release candidate. |
| ADR-004 | Reuse and adapt Squirrel's native candidate panel first. | ACCEPTED | Do not add a second CandidateUI implementation in parallel. McBopomofo remains a reference unless a concrete replacement need is established. |
| ADR-005 | Keep translation and context services separate from host writes. | ACCEPTED | One commit coordinator owns host insertion; asynchronous results require explicit identity/version checks. |
| ADR-006 | Prefer field type and nearby text for automatic direction, with explicit rules and stable fallback. | ACCEPTED | Freeze direction per composition; learned preferences never override explicit rules. |
| ADR-007 | Provide local-only, local-first, and API-first translation policies. | ACCEPTED | API-first cannot block primary-text input. Service support requires protocol and live-verification evidence. |
| ADR-008 | Prepare for GPL-derived distribution throughout development. | ACCEPTED | Preserve upstream rights and provide corresponding-source materials before external binary distribution. Exact grant/SPDX and dependency/data inventory still require verification. |
| ADR-009 | Deliver sequentially and stop after Round 0 for confirmation. | ACCEPTED | Current authorization covers plan persistence, Git version management, and Round 0 only. |
| ADR-010 | Honor no filesystem deletion and independent product storage. | ACCEPTED | Review scripts, stop on existing install targets, and never alter Squirrel user data or evade replacement restrictions. |

Runtime acceptance authorization update (2026-10-11): the user permits librime's normal generated-file/database maintenance only within `~/Library/Application Support/LiangYi/` and `~/Library/Logs/LiangYi/`. This supersedes the earlier engine-maintenance blocker for audited, confined operations. Manual deletion, Squirrel/other data changes, Round 1, and pushing remain outside scope. Historical verification below records the initial delivery; follow-up runtime results are recorded in [RUNTIME_ACCEPTANCE.md](../round0/RUNTIME_ACCEPTANCE.md).

## Round 0 decision updates

The planning baseline was committed as `041b643` and Squirrel source/history was imported in `8b507af`. Detailed reasoning is in [Round 0 foundation](../round0/FOUNDATION.md), with current measured outcomes in [runtime acceptance](../round0/RUNTIME_ACCEPTANCE.md). These statuses distinguish a selected design from a verified implementation.

| ID | Current decision | Status / remaining evidence |
| --- | --- | --- |
| ADR-011 | Squirrel `769ae426f33f500266101a88f694aab0d158e680`; inherited librime `33e78140250125871856cdc5b42ddc6a5fcd3cd4` / v1.17.0 and Sparkle `41847a58cdef7506b257591fcca6f9495df591d4` / 2.6.2 references; `dependencies.lock.json` and `data/schema-manifest.json` identify artifact/data inputs. | BUILD_VERIFIED on macOS 26.5/arm64; Sparkle excluded. Artifact/data/notice checks pass; complete distribution closure remains pending. |
| ADR-012 | Product identity root `io.github.zhenkun26.inputmethod.EcholME`; user install `~/Library/Input Methods/EcholME.app`; data `~/Library/Application Support/LiangYi/Rime/`; logs `~/Library/Logs/LiangYi/`; runtime updater disabled. | FIXED_BUILD_STATIC_AND_RUNTIME_PATH_CHECKS_PASS; both mode defaults false. Initial installed path encoding defect fixed in source, replacement pending. Real coexistence remains unverified. |
| ADR-013 | IMK adapter owns host access; session state owns lifecycle; engine adapter owns librime; presentation tracks displayed identity; one commit coordinator writes to the host; translation consumes copied values. | DESIGN_ACCEPTED; no Round 1 state/translation implementation is claimed. |
| ADR-014 | Use privacy-preserving capability probes and separate source, AX, and real IMK evidence. | Notes AX metadata PASS; real IMK NOT_RUN pending manual fixed installation and safe host field; Terminal BLOCKED_TOOL_POLICY. See runtime follow-up report. |
| ADR-015 | Isolate long cloud work in a service process; XPC is a proposed mechanism requiring lifecycle, signing, peer-authentication, and failure validation. | DESIGN_PROPOSED; no service implementation or validated platform result. Round 4 remains unauthorized. |
| ADR-016 | Review recursive tooling; absent-target user installation only; stop at existing target; no cleanup/deletion or system-wide reload; separate registration from selection and input. | NARROW_MAINTENANCE_AUTHORIZED; initial runtime found URL encoding defect, source fixed. Fixed-build startup/idle reload and 30 real-engine checks PASS. Installed initial binary requires manual replacement; real host input remains pending. No deletion or push. |

## Decisions and evidence still required

| ID | Question | Owner round | Exit requirement |
| --- | --- | --- | --- |
| ADR-011 | Which exact Squirrel revision, compatible librime revision, recursive dependencies, and toolchain form the baseline? | Round 0 | Record pinned versions, licenses, source provenance, and observed build compatibility. Planning snapshots do not decide this automatically. |
| ADR-012 | What are the final bundle/input-source identifiers, IMK connection, paths, notification names, and update behavior? | Round 0 | Demonstrate independent identity and no collision with Squirrel. Disable inherited update routing unless a separately authorized replacement exists. |
| ADR-013 | Which state belongs to the IMK controller, composition coordinator, engine adapter, and service process? | Round 0 | Record ownership, lifecycle, allowed thread access, and failure behavior before the Round 1 state implementation. |
| ADR-014 | What host context/caret information is available in Notes, Xcode, and Terminal on the tested environment? | Round 0 | Record capability evidence, time/call boundaries, and fallback; do not assume all fields or AX attributes are available on macOS 14. |
| ADR-015 | How will long-running cloud tasks be isolated and authenticated? | Round 0 design; Round 4 implementation | Choose a concrete service mechanism based on capability validation; define peer authentication and bounded messages rather than treating process separation as authentication. |
| ADR-016 | What safe build/install/reload procedures work under the no-deletion policy? | Round 0 | Inspect side effects, stop on existing targets, and distinguish install/register/select/input states. |
| ADR-017 | What do Space, digits, Tab, Return, Esc, punctuation, focus loss, phrase entry, and Off mean in each mode? | Round 1 | Approve an explicit interaction table; no tentative shortcut becomes a default without this decision. |
| ADR-018 | What candidate value model represents segment text, full commit preview, engine comment, subtitle, and displayed revision? | Round 1 | Prevent stale selection and align translation scope with actual commit scope. |
| ADR-019 | Which licensed dictionary and phrase resources meet offline bidirectional quality targets? | Round 2 | Record provenance, licensing, counts, corpus, and independent directional quality. |
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
