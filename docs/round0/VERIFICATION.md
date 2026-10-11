# Round 0 verification and delivery

Recorded: 2026-10-11, America/New_York.

**Delivery: CODE_AND_LOCAL_INSTALL_DELIVERED; RUNTIME_ACCEPTANCE_BLOCKED.** Round 0 is not fully accepted. Round 1 has not started and is not authorized. No push, public release, notarization, or external binary distribution occurred.

## Goal and delivered scope

Establish the independently identified Squirrel-derived baseline and its safe build/install workflow. Preserve inherited Chinese input code without adding English composition, translation, automatic language detection, a new HUD, or provider integration.

| Reused | Modified | Added |
| --- | --- | --- |
| Squirrel IMK host, librime bridge/session code, existing candidate panel, icons and frontend configuration | Product/source identity, paths, notifications, CLI exit handling, default registration states, localization, Xcode resources/build configuration | Approved plan/status/ADRs, fixed dependency/data manifests, safe Python build/install/verification entry point, read-only capability probe, guard tests, GPL/provenance records |

The complete code is in the repository; no pseudocode implementation is substituted. Important files:

```text
sources/Main.swift
sources/InputSource.swift
sources/SquirrelApplicationDelegate.swift
sources/SquirrelInputController.swift
resources/Info.plist
resources/InfoPlist.xcstrings
resources/Localizable.xcstrings
Squirrel.xcodeproj/project.pbxproj
tools/round0.py
tools/check_round0.py
tools/CapabilityProbe.swift
dependencies.lock.json
data/schema-manifest.json
data/default.custom.yaml
docs/project/{PLAN,STATUS,DECISIONS}.md
docs/round0/{FOUNDATION,VERIFICATION}.md
docs/round0/evidence/
UPSTREAM.md
CHANGES_FROM_UPSTREAM.md
THIRD_PARTY_NOTICES.md
```

## Environment and artifacts

| Field | Verified value |
| --- | --- |
| Machine architecture | Apple Silicon / arm64 |
| macOS | 26.5, build 25F71 |
| Xcode | 26.6, build 17F113 |
| SDK / Swift | macOS SDK 26.5; Apple Swift 6.3.3 (`swiftlang-6.3.3.1.3`) |
| Python | 3.13.15; standard library only |
| Deployment target | 14.0; not a macOS 14 runtime claim |
| Product version / architecture | 0.0.1 / arm64 main executable; some inherited engine tools/libraries retain universal slices |
| Plan / import commits | `041b643` / `8b507af`; implementation is the commit containing this report |
| Fresh final-source build | `.artifacts/builds/round0-repro/DerivedData/Build/Products/Debug/EcholME.app` |
| Build log | `.artifacts/builds/round0-repro/xcodebuild.log` |
| Installed app | `~/Library/Input Methods/EcholME.app` |
| Installed artifact origin | `round0-final` build, followed by a scoped in-place Info.plist default-state correction and ad-hoc re-signing; its corrected build copy and installed copy match across 84 files |
| Source correspondence | [28 build/source hashes](evidence/build-source-sha256.json), [installed file hashes](evidence/installed-files-sha256.json), dependency/data locks |

`round0-repro` is a fresh successful build of the final source after the metadata fix. It is not claimed byte-identical to a different Debug build directory. The installed artifact and corrected `round0-final` copy are verified separately. Failed and earlier build outputs remain on disk; no cleanup was performed.

## Verification ledger

| Check | Result | Evidence / practical limit |
| --- | --- | --- |
| Plan persisted before implementation | PASS | `041b643`; full plan and explicit round boundary. |
| Upstream provenance/history | PASS | `8b507af`, Squirrel `769ae426f33f500266101a88f694aab0d158e680`; original LICENSE and preserved README bytes match. |
| Locked preparation | PASS | `python3 tools/round0.py prepare`; archive/header/schema/notice sizes and SHA-256 verified; existing-content conflicts refuse replacement. |
| Script side-effect review | PASS | Direct Xcode build; no upstream installer, clean target, dynamic plum recipe, deployment or model download. |
| Final-source compilation | PASS | `python3 tools/round0.py build --configuration Debug --build-id round0-repro`, exit 0, `BUILD SUCCEEDED`; [report](evidence/build-verification.json). |
| Swift/linker warnings | PASS | Zero Swift/compiler/linker warnings in final build; one non-compiler Xcode metadata warning listed below. |
| Product identity/resources | PASS | Independent IDs/connection/classes/default states, 11 locked runtime schema files, schema licenses/AUTHORS, OpenCC resources, architecture and dependency-path checks. |
| Local signature | PASS | `codesign --verify --deep --strict` for fresh and installed bundles; [installed report](evidence/installed-verification.json). Ad-hoc, not Developer ID/notarized. |
| Main binary dynamic loading / CLI | PASS | `--help` exit 0; unknown argument, unexpected register argument and invalid enable/select IDs exit 1; [five cases](evidence/cli-smoke.json). No IMK/engine startup. |
| First install | PASS | Copied to initially absent user target; [initial report](evidence/first-install.json). |
| Existing install guard | PASS | Second install refused before copying; file hashes remained unchanged; [guard record](evidence/registration-and-install-guards.json). |
| Registration | PASS | Installed CLI returned OSStatus 0; Hans and Hant visible in TIS; no global keyboard-server restart. |
| Current enablement/selection | PASS (state inspection only) | Both EcholME modes disabled and unselected after correction/re-registration; `selectable=true` is a TIS property, not an actual selection test. [TIS evidence](evidence/tis-after-registration.json). |
| Default registration state | PASS (static and retained-state checks) | Both plist defaults false; inherited initial Hans auto-enable was explicitly undone, as described below. Fresh-user default behavior still requires separate testing. |
| Actual Chinese input / selection / Esc / focus transitions | BLOCKED | Engine deployment can remove generated files; no runtime startup under the current no-deletion policy. |
| Updater disabled | PASS (source/binary inspection) | No updater initialization/feed/key; Sparkle excluded from the bundle. This is not a packet-capture claim. |
| Squirrel coexistence | PASS (static isolation); NOT_RUN (runtime) | Independent IDs/paths/notifications; no Squirrel sources or standard Squirrel installation/data found in this environment. No actual dual-runtime acceptance. |
| Guard tests | PASS | `python3 -B tools/check_round0.py`: 12 tests, including dangerous archive/link rejection, existing-target refusal, identity/default-state pollution and dynamic-library path checks. [Output](evidence/guard-tests.txt). |
| Diagnostic compiler | PASS | `xcrun swiftc -warnings-as-errors tools/CapabilityProbe.swift`; no warning. |
| macOS 14 / Intel runtime | NOT_RUN | No test machine/session; main executable is arm64. |
| Translation latency / API calls | NOT_APPLICABLE | No translation or provider implementation in Round 0. |
| Complete GPL corresponding-source delivery | NOT_RUN | Initial licenses/notices/provenance are present; recursive source/binary/data-rights closure and release reproduction remain gates before external distribution. |
| Remote CI / push / release | NOT_RUN | Not authorized; inherited CI jobs guarded to run only in `rime/squirrel`. |

## Warnings and resolved failures

The final build has one Xcode toolchain warning:

```text
Metadata extraction skipped. No AppIntents.framework dependency found.
```

The IME does not implement App Intents. No dependency was added or diagnostic suppressed to hide this message.

Earlier validation found and fixed: signing the main executable before its sibling tools; stale Sparkle framework search paths; universal `otool` architecture headings misparsed as dependencies; and valid bare `@executable_path`/`@loader_path` entries rejected by the verifier. The final build and 12 guard tests cover the corrected behavior. Earlier failed artifacts remain preserved.

Initial registration also emitted TIS cache and duplicate keyboard-layout-ID notices. Registration still returned OSStatus 0 and both modes were visible. Their origin was not established; no keyboard cache was deleted. Real input remains unverified.

### Registration default-state correction

The inherited Hans plist entry had `tsInputModeDefaultStateKey=true`. macOS reported it enabled after registration even though the CLI never called `TISEnableInputSource`. It remained unselected; no EcholME process or LiangYi user-data directory was present. Explicit disable returned OSStatus 0.

The source now sets both defaults false, and bundle verification rejects automatic default enablement. The Info.plist files in this task's newly created build/installed copies were edited in place and both bundles were re-signed. This was a normal scoped metadata edit: no file or bundle was deleted, moved, or replaced. The installer still refuses an existing destination. Re-registration left both modes disabled. The current active source was Apple's Simplified Pinyin when recorded; the assistant did not select another source.

## Host context/caret findings

| Host | Standalone capability finding | Real IMK result / fallback |
| --- | --- | --- |
| Notes | PASS, AX metadata only: AXTextArea; selected-range and bounds-for-range advertised; zero-length range returned finite bounds with nonzero height; AXLanguage not advertised. Subrole unsupported, so sensitivity is unknown. [Report](evidence/notes-ax-capabilities.json). | BLOCKED by runtime policy. Attribute advertisement is not a text retrieval test or proof of IME permission. Later context detection must tolerate missing language metadata and uncertain sensitivity. |
| Xcode | NOT_RUN for editor capability. Xcode opened at Welcome; UI navigation did not establish a source-editor field. The empty Xcode session was exited. | BLOCKED for real IMK. Do not infer editor capabilities from a file chooser. User-assisted editor verification remains pending. |
| Terminal | BLOCKED_TOOL_POLICY. Computer Use explicitly denied access to `com.apple.Terminal`; no alternative interaction or AX access was used to bypass it. | BLOCKED for real IMK. Requires an allowed/manual test path and runtime-policy resolution. |

The standalone probe never reads AXValue/selected document text, window titles or clipboard data, outputs no selection offsets/coordinates, and never prompts for Accessibility permission. AX messaging timeout is per call; the successful Notes probe ran under an external 10-second process deadline. Its approximately 46 ms metadata probe duration is **not** a candidate/translation latency measurement. Unsupported or failed queries retain unknown/partial states.

## Commands and remaining acceptance

Build/install/diagnostic commands and restrictions are in [FOUNDATION.md](FOUNDATION.md#reviewed-commands). The 12 pure-memory checks are safe to rerun:

```sh
python3 -B tools/check_round0.py
python3 tools/round0.py verify --bundle "$HOME/Library/Input Methods/EcholME.app"
```

The installed app is deliberately disabled. Do not launch, enable/select, deploy or reload it until the narrow engine-maintenance conflict is resolved. librime's dictionary compiler invokes table/prism file removal; see [the audited call chain](FOUNDATION.md#runtime-blocker-engine-deployment-removes-generated-files).

After a user decision permitting the necessary engine-managed generated-file/database maintenance within the independent LiangYi directories, the remaining work stays in Round 0: select the input source, deploy the fixed schema, check candidates and Chinese commits in Notes/Xcode/Terminal, check Esc and focus changes, and record real IMK caret/context behavior. Use synthetic text in a new test field; do not send private text or execute typed shell text. Do not infer zero crashes or host safety from the CLI smoke test.

The deployment rule and Terminal tool restriction are separate. Permission to run the engine would not override the UI tool's Terminal access boundary. Round 1 still requires explicit confirmation after the Round 0 delivery/acceptance discussion.
