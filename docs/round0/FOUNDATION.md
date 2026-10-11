# Round 0 foundation

Recorded: 2026-10-11, America/New_York.

Scope: independent Squirrel-derived baseline, safe development tooling, provenance, and platform capability assessment. Round 1 behavior is not authorized. The complete plan remains [PLAN.md](../project/PLAN.md).

This document records design choices and their consequences. Implementation and runtime results are tracked separately in [VERIFICATION.md](VERIFICATION.md) and [STATUS.md](../project/STATUS.md).

## ADR-011 — Baseline and dependency boundary

Status: **BUILD_VERIFIED_ON_MACOS_26_5_ARM64; EXTERNAL_DISTRIBUTION_CLOSURE_PENDING**.

- Squirrel: `769ae426f33f500266101a88f694aab0d158e680`, imported with Git history in `8b507af`.
- librime: `33e78140250125871856cdc5b42ddc6a5fcd3cd4`, the imported v1.17.0 baseline.
- Sparkle: `41847a58cdef7506b257591fcca6f9495df591d4`, the imported 2.6.2 reference. Sparkle is excluded from compilation, preparation, linking, and the application bundle; its historical Gitlink remains preserved.
- plum: inherited reference `b1be1969f914cc005add4090631b855db00c2591`; do not use it as authority to fetch arbitrary changing schemas.

The selected artifact hashes, headers, notices, and recursive source references are in [dependencies.lock.json](../../dependencies.lock.json). [data/schema-manifest.json](../../data/schema-manifest.json) locks `luna_pinyin_simp` and its prelude, luna-pinyin, stroke, and essay files; the four packages supply LGPL version 3 root license text. Optional Rime plugins and additional model downloads are excluded from application assembly. Actual artifact/license closure and toolchain results still require evidence. No single top-level license clears every resource or transitive library. [UPSTREAM.md](../../UPSTREAM.md) and [THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md) retain that boundary.

## ADR-012 — Product identity and coexistence

Status: **FIXED_BUILD_PATH_CHECKS_PASS; MANUAL_FIXED_INSTALL_AND_HOST_UAT_PENDING; RUNTIME_COEXISTENCE_NOT_RUN**.

The first runtime invalidated the initial path-confinement claim because `URL.path()` encoded spaces. All C API filesystem strings now explicitly use `path(percentEncoded: false)`; the fixed build deployed into the intended root. See [the incident and runtime results](RUNTIME_ACCEPTANCE.md). The installed initial app remains unfixed and disabled pending manual replacement.

| Surface | EcholME design |
| --- | --- |
| Product | 两仪 / LiangYi / EcholME |
| Deployment target | macOS 14.0 |
| Bundle/input-method identity root | `io.github.zhenkun26.inputmethod.EcholME` |
| User installation | `~/Library/Input Methods/EcholME.app` |
| User Rime data | `~/Library/Application Support/LiangYi/Rime/` |
| Logs | `~/Library/Logs/LiangYi/` |
| Preferences | EcholME's bundle domain, not Squirrel's domain. |
| Input modes | `io.github.zhenkun26.inputmethod.EcholME.Hans` and `io.github.zhenkun26.inputmethod.EcholME.Hant`. |
| IMK connection | `EcholME_Connection`. |
| Distributed notifications | `io.github.zhenkun26.inputmethod.EcholME.` prefix with `Reload`, `Sync`, `ToggleASCII`, `GetASCII`, `ASCIIResponse`, `SetASCII`, and `ReportASCII`. |
| User-notification identifier | `io.github.zhenkun26.inputmethod.EcholME.Notification`; no automatic notification permission request. |
| Temporary launch record | User temporary directory, `io.github.zhenkun26.inputmethod.EcholME.launch.json`. |
| Rime application identifiers | `liangyi.echolme` and builder `liangyi.echolme-builder`; distribution code name `EcholME`, display name `两仪`. |
| Updater | Excluded from the binary; no upstream appcast used. |
| Registration defaults | Both modes false; macOS default-state auto-enable was found and corrected. |

Internal Swift class/module names, the Xcode project/target, and Rime frontend configuration keys may remain inherited where needed to minimize changes. Inspect Objective-C runtime class strings when the product module name differs from the product/bundle name.

The selected runtime class remains `Squirrel.SquirrelInputController`, and `squirrel.yaml` remains the frontend configuration filename inside the independent data tree. `appDir` resolves from `Bundle.main.bundleURL`; registration tooling must run the application at the approved installed location, not register a build-directory copy accidentally.

Coexistence is not established merely by choosing a new bundle ID. Inspect every write path, input-source ID, notification name, connection, log path, preferences domain, and update endpoint. Then verify with the actual bundle and user environment. Do not modify or migrate `~/Library/Rime/` or the installed Squirrel application.

## ADR-013 — Input state ownership

Status: **DESIGN_ACCEPTED; ROUND_1_IMPLEMENTATION_NOT_STARTED**.

| Owner | Responsibility | Prohibited shortcut |
| --- | --- | --- |
| IMK input controller / host adapter | Activation/deactivation, synchronous key disposition, bounded host calls, and UI-thread coordination. | Handing the IMK client to a background translation task. |
| Composition/session coordinator | Session identity, focus generation, engine/English state, direction freeze, and cancellation. | Letting independent callbacks each maintain their own uncoordinated notion of focus. |
| Engine adapter | librime session ownership, synchronous warm key processing, resource lifetime, and copied candidate/commit snapshots. | Exposing raw engine-owned pointers to asynchronous consumers. |
| Candidate presentation | Stable candidate identity, highlighted item, page, and displayed revision. | Treating latest background state as proof of what the user saw. |
| Commit coordinator | The only path that validates and inserts primary/translated text and closes composition. | Retrying an uncertain host insertion or inserting from provider callbacks. |
| Translation coordinator | Work scheduling, immutable request identity, cache, cancellation, deadline, and result validation. | Holding a client object or bypassing the commit coordinator. |

Round 0 preserves inherited input behavior and documents these boundaries. It does not implement the new English composer, translated commit, or candidate revision model. Each later module must expose explicit failure/cancellation states and copy data across ownership boundaries.

## ADR-014 — Context and caret capability

Status: **NOTES_AX_METADATA_PROBED; XCODE_EDITOR_NOT_RUN; TERMINAL_TOOL_BLOCKED; REAL_IMK_MANUAL_ACCEPTANCE_PENDING**.

The engine-maintenance policy conflict is resolved by a narrow user authorization; see ADR-016. Real IMK checks require manual fixed-bundle installation and a safe synthetic field. Standalone AX and engine probes do not establish host-input behavior.

Round 0 investigates capabilities without collecting document contents. Record the OS/app version, whether relevant interfaces are exposed, permission state, success/failure categories, and durations when safely measurable. Do not persist nearby text or request Accessibility permission automatically.

Capability investigation scope (actual outcomes are in VERIFICATION.md):

- Notes: whether an active IMK client can provide a bounded text/caret interface.
- Xcode: distinguish ordinary editor behavior from other fields where possible.
- Terminal: establish available geometry/context behavior; do not imply reliable shell prompt semantics from an App ID.

Source inspection, a standalone AX capability probe, and a real IMK-host test are different evidence. An AX probe is not a substitute for calling the IMK text client in a real input session. A missing permission or interface is a fallback case, not evidence that text is empty. Do not assume newer language attributes exist on the macOS 14 deployment target.

IMK host methods may involve synchronous IPC. The design does not promise that an arbitrary host call can be interrupted by a hard timeout or safely moved off the required thread. Avoid repeated per-key inspection; later context detection must use bounded snapshots and cached decisions. If Round 0 cannot safely exercise the host, mark the experiment unverified and provide a focused manual acceptance step.

## ADR-015 — Future cloud-service boundary

Status: **DESIGN_PROPOSED; ROUND_4_IMPLEMENTATION_NOT_STARTED; NOT_VALIDATED**.

Long-running cloud tasks should run outside the input event path in a separate service process. An XPC-based service is a candidate, not a verified integration or a mandatory new dependency selected by this document.

Before adopting a concrete mechanism, validate startup/lifecycle from an input method, signing/development behavior, peer identity, request limits, cancellation, service termination, and failure fallback. Define versioned value-only messages with session/configuration identities; no IMK client crosses this boundary. Authenticate the peer and bind credentials to the selected provider origin. Process separation alone is not an authentication control.

Round 0 adds no network service, provider code, model credentials, or translation traffic. Round 4 owns implementation after renewed authorization.

## ADR-016 — Build, install, and reload policy

Status: **FIXED_BUILD_STARTUP_IDLE_RELOAD_PASS; MANUAL_FIXED_INSTALL_AND_HOST_UAT_PENDING**.

- Review scripts and recursive invocations before execution. Inherited Makefile, package, release, and install scripts remain upstream material, not the approved operational entry point.
- Do not run `clean` targets, deletion-based copy/replace operations, keyboard-cache deletion, system-directory permission changes, or generic system-wide reload commands.
- Use an independent build directory for each attempt where needed; do not empty or overwrite an existing unrelated artifact to make a check pass.
- A first installation may target an absent `~/Library/Input Methods/EcholME.app`. An existing destination must stop the operation. Any required removal is left to the user; moving/renaming the existing bundle is not an automatic workaround.
- Separate build, signing, install, input-source registration, enablement, selection, and actual input checks. A registration probe must not silently enable or select a source.
- Do not take over an active user's input source without a documented step and the necessary interaction.
- Scope reload/termination to the EcholME bundle identity and only after review; do not terminate Squirrel or unrelated input methods.
- Registration/activation caching may require user action or logout. Document observed behavior without claiming a universal hot-reload guarantee.

Development signing is separate from Developer ID signing, notarization, and release. Record the actual architecture and signature result of the produced bundle; a build setting is not a runtime compatibility result.

### Reviewed commands

Run from the repository root. `prepare` downloads only locked public dependencies; no credentials or package-manager installation is needed. Each build needs a fresh ID; omission generates a UTC timestamp. Failed outputs remain available for inspection.

```sh
python3 -B tools/check_round0.py
python3 tools/round0.py doctor
python3 tools/round0.py prepare
python3 tools/round0.py build --configuration Debug --build-id round0-local-01
python3 tools/round0.py verify --bundle "$PWD/.artifacts/builds/round0-local-01/DerivedData/Build/Products/Debug/EcholME.app"
python3 tools/round0.py install-first --bundle "$PWD/.artifacts/builds/round0-local-01/DerivedData/Build/Products/Debug/EcholME.app"
"$HOME/Library/Input Methods/EcholME.app/Contents/MacOS/EcholME" --register-input-source
```

Registration is a deliberate system-state change. The CLI exits before IMK/engine startup for this command. The initial installed app has a measured path defect and must not be enabled. Follow [MANUAL_ACCEPTANCE.md](MANUAL_ACCEPTANCE.md) to install the fixed artifact before enable/select/real-input checks. Inspect the CLI's OSStatus and the separate TIS result; do not infer enablement from registration success.

Compile the optional standalone probe to an unused output name:

```sh
mkdir -p build/round0-diagnostics
xcrun swiftc -warnings-as-errors tools/CapabilityProbe.swift -o build/round0-diagnostics/capability-probe-local
build/round0-diagnostics/capability-probe-local com.apple.Notes
```

The AX messaging timeout is 0.2 seconds per call, not a total deadline. Automation should use `subprocess.run(..., timeout=10)` to bound the standalone process. Permission/interface failures retain distinct states; attribute advertisement does not prove actual text retrieval. The probe reads neither document text nor clipboard data. When a UI tool denies an application, do not use the probe to bypass that tool boundary.

For debugging the CLI, invoke `--help` or an invalid argument from the built executable and inspect the exit code; these paths do not start IMK. Fixed-build idle reload is verified; installed real-input reload still requires the manual fixed-install and host checklist. Logs are isolated at the path in ADR-012; a dedicated diagnostics panel is later-round work.

### Runtime blocker: engine deployment removes generated files

Status: **RESOLVED_BY_NARROW_USER_AUTHORIZATION; FIXED_BUILD_STARTUP_AND_IDLE_RELOAD_PASS**.

Follow-up authorization on 2026-10-11 permits librime's normal generated-file/database maintenance only within the independent LiangYi data and log directories. Audit concrete resolved paths and reject escaping links before runtime checks. This does not authorize bundle replacement, manual deletion, Squirrel/other data changes, Round 1, or pushing. The paragraphs below preserve the rationale for the initial delivery blocker, not a continuing prohibition on the newly authorized confined maintenance.

Source review of the pinned librime identifies calls that remove compiled dictionary/prism files: [`dict_compiler.cc`](https://github.com/rime/librime/blob/33e78140250125871856cdc5b42ddc6a5fcd3cd4/src/rime/dict/dict_compiler.cc#L265) calls `table->Remove()`, and its [prism rebuild](https://github.com/rime/librime/blob/33e78140250125871856cdc5b42ddc6a5fcd3cd4/src/rime/dict/dict_compiler.cc#L358) calls `prism_->Remove()`. [`mapped_file.cc`](https://github.com/rime/librime/blob/33e78140250125871856cdc5b42ddc6a5fcd3cd4/src/rime/dict/mapped_file.cc#L122) implements file removal through `file_mapping::remove`.

Consequently, do not execute schema deployment, launch the IME runtime, enable/select it, reload it into a running input session, or perform actual typing acceptance under the current absolute no-deletion instruction. Creating a fresh directory is not a policy exemption for a code path that attempts deletion. Do not rewrite librime or intercept filesystem calls merely to bypass the instruction.

Reviewed build operations, copying to an absent first-install target, registration-only CLI handling, and read-only TIS inspection are separate possible steps; each must be audited to ensure it does not fall through to engine startup/deployment. Resolving this blocker requires a specific user decision about engine-managed generated files. That decision would complete remaining Round 0 acceptance, not authorize Round 1.

### Inherited automation

The inherited commit, pull-request, and release workflows retain their upstream code but have a repository-identity guard restricting their jobs to `rime/squirrel`. This prevents unintended execution of upstream package/release logic when the derived repository is eventually pushed. Round 0 has no remote CI pass; a new reviewed EcholME CI remains future work. Local build/check evidence must be reported on its own merits.

## GPL distribution gate

Round 0 is local work, not an authorized release. Before even the first external test binary, complete the exact artifact's source/dependency/resource inventory and provide the necessary corresponding source and notices. See [THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md).

Do not claim source completeness from a root-only source archive when submodules or required dependencies are absent. Do not add `or-later` licensing wording without an actual grant. Keep public source free of credentials, signing secrets, and captured user input.

## Round 0 exit

Report exact source changes, the final commit, verification outcomes, and limitations. Round 1 remains stopped until the user confirms. Any incomplete build, license, signing, installation, or real-input acceptance must remain visible rather than being converted into a plan-completion claim.
