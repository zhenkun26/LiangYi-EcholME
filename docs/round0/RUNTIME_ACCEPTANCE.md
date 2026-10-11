# Round 0 runtime acceptance follow-up

Recorded: 2026-10-11, America/New_York.

**Delivery: AUTOMATED_RUNTIME_CHECKS_DELIVERED; FIXED_INSTALL_AND_HOST_UAT_PENDING.** This is not a full Round 0 acceptance pass. No Round 1 work, push, public distribution or release occurred. [VERIFICATION.md](VERIFICATION.md) preserves the initial delivery at `6e971c2`; this report supersedes its current runtime-policy status.

## Authorization and scope

The user explicitly permitted librime's normal generated-file/database maintenance only within `~/Library/Application Support/LiangYi/` and `~/Library/Logs/LiangYi/`, while protecting Squirrel and other user data. Manual deletion, existing-bundle replacement, new dependencies and system-wide service restarts remain outside the automated workflow. Checks unavailable to automation are provided in [MANUAL_ACCEPTANCE.md](MANUAL_ACCEPTANCE.md).

Independent reviews covered engine paths and the manual test design. Source review and before/after snapshots are not a kernel filesystem sandbox or a system-wide trace. An existing configuration with escaping links or an external `sync_dir` would require a new preflight; the newly generated installation uses LiangYi's own `Rime/sync`.

## Actual failure found and fixed

The first no-argument launch of the installed initial app exposed a real defect: Swift's `URL.path()` defaults to a percent-encoded string. Passing `userDir.path()` to librime caused generated data under `~/Library/Application%20Support/LiangYi/Rime`, outside the intended authorized data root. The earlier source-only path-confinement conclusion was invalidated by this observed failure.

The process, PID 12259, was stopped immediately with SIGTERM once the path error was observed. The incident left 12 generated/configuration files under that accidental LiangYi directory. No cleanup, deletion, move or migration was performed. The first launch's logs were written inside the correct LiangYi log root. [Incident inventory](evidence/runtime-path-incident.json) and [launch record](evidence/runtime-launch.json) preserve the failure; no user typing or input-source selection occurred.

The fix explicitly uses `path(percentEncoded: false)` for every URL-derived filesystem string passed to librime, `RIME_LOG_DIR`, and directory existence checks. Both normal startup and the standalone `--build` path now specify their own bundle `shared_data_dir`; the latter previously depended on the caller's working directory. `Bundle.sharedSupportPath` already supplies a filesystem string and is not decoded again. The API is available before the macOS 14 minimum. [Swift Foundation source](https://github.com/swiftlang/swift-foundation/blob/main/Sources/FoundationEssentials/URL/URL.swift#L1105) documents the default.

Relevant implementation:

```swift
squirrelTraits.setCString(Bundle.main.sharedSupportPath!, to: \.shared_data_dir)
squirrelTraits.setCString(SquirrelApp.userDir.path(percentEncoded: false), to: \.user_data_dir)
squirrelTraits.setCString(SquirrelApp.logDir.path(percentEncoded: false), to: \.log_dir)
```

These are actual statements in `sources/SquirrelApplicationDelegate.swift`; the full compilable implementation remains in the repository. The CLI change is in `sources/Main.swift`.

## Artifacts and changed files

The fixed source built as `round0-path-fix` with the same recorded macOS 26.5 / Xcode 26.6 / arm64 environment, deployment target 14.0 and ad-hoc signature. No new dependencies were introduced.

```text
sources/Main.swift                         decoded paths; explicit deployer shared-data path
sources/SquirrelApplicationDelegate.swift decoded paths and directory checks
tools/round0.py                            static verifier reports only its own scope
tools/RimeSmoke.c                          standalone synthetic real-engine probe
AGENTS.md                                 narrow runtime maintenance authorization
docs/project/{PLAN,STATUS,DECISIONS}.md     authorization, results and pending gate
docs/round0/RUNTIME_ACCEPTANCE.md           this report
docs/round0/MANUAL_ACCEPTANCE.md            fixed-install and host test steps
docs/round0/evidence/                      incident, build, deployment and test evidence
README.md / CHANGES_FROM_UPSTREAM.md        aligned navigation and modification record
```

Fixed artifact:

```text
.artifacts/builds/round0-path-fix/DerivedData/Build/Products/Debug/EcholME.app
```

**The installed `~/Library/Input Methods/EcholME.app` remains the initial, unfixed app.** It was not replaced or mutated. Its 84-file inventory is unchanged. Both its input modes remain disabled/unselected and no EcholME process remains running. Do not enable it before the manual replacement step. Build-directory startup of the fixed artifact did not register that copy or select an input source.

The accidental encoded-path files also remain unchanged after all fixed-build checks. Standard Squirrel installation, preference and Rime-data paths remain absent, as before the run. This verifies the inspected paths; it does not claim a concurrent two-IME coexistence test or prove that every unrelated file on the machine was untouched. [Final isolation snapshot](evidence/runtime-final-isolation.json), [TIS state](evidence/runtime-final-tis.json).

## Verification ledger

| Check | Result | Evidence and limit |
| --- | --- | --- |
| Initial installed runtime data path | FAIL; source fixed | `%20` directory incident; initial installed binary still requires manual replacement. |
| Fixed-source Debug build | PASS | [Build report](evidence/path-fix-build-verification.json); `BUILD SUCCEEDED`; [input hashes](evidence/path-fix-build-source-sha256.json). |
| Compiler/linker warnings | PASS with listed tool warning | No Swift/compiler/linker warning; inherited AppIntents metadata extraction warning remains. |
| Fixed bundle signature/resources | PASS | [Post-runtime static report](evidence/path-fix-post-runtime-verification.json); app signature remains valid. |
| Fixed-build normal startup and deployment | PASS | PID 12617; expected compiled files created inside decoded LiangYi/Rime; two schemas and `3 tasks ran: 3 success, 0 failure`. [Deployment evidence](evidence/runtime-fixed-deployment.json). |
| Idle reload request and execution | PASS (maintenance only) | CLI returned 0; independent console/log evidence shows reload and a second `3 success, 0 failure` maintenance pass. Does not prove host input after reload. |
| Bundle-specific shutdown | PASS | `--quit` returned 0 and process absence confirmed. [Record](evidence/runtime-quit.json). |
| Probe compilation | PASS | C11, `-Wall -Wextra -Wpedantic -Werror`; no diagnostic. [Compiler record](evidence/rime-smoke-compile.json). |
| Real librime candidates / Space / numeric / Esc | PASS (engine only) | 10 cycles, 30 checks; [result](evidence/rime-smoke-result.json). No IMK client or UI. |
| Guard tests | PASS | Existing 12 tests rerun after verifier change; [output](evidence/runtime-guard-tests.txt). |
| Corrected build installation | MANUAL_ACTION_REQUIRED | Existing-target refusal preserved; fixed artifact awaits user removal of old bundle followed by reviewed first-install. |
| Notes, Xcode, Terminal actual IMK input | NOT_RUN / BLOCKED_TOOL_POLICY | No safe synthetic UI field established; Terminal access remains denied. Manual checklist supplied. |
| Input-source selection and restoration | NOT_RUN | Current source remains Apple Simplified Pinyin; no source-selection call in this run. |
| Concurrent Squirrel coexistence | NOT_RUN | No Squirrel installation/data here; static identity/path isolation and standard-path absence were checked. |
| macOS 14 / Intel runtime; translation latency | NOT_RUN / NOT_APPLICABLE | No runtime test environment for the former; no translation implemented for the latter. |
| External GPL distribution readiness | NOT_RUN | Existing corresponding-source/data/dependency gates remain; no distribution. |

The standalone probe uses the same pinned librime and fixed build's SharedSupport. It selects `luna_pinyin_simp` with ASCII disabled and checks: `nihao` first candidate and Space commit equal “你好”; `zhongguo` numeric selection equals its copied displayed-first candidate; Esc clears input/candidates without a commit; no second unread commit or residual composition remains. It validates writable roots before and after, stops on failures, and never reads host text, syncs, or performs manual cleanup. The IME was stopped before the probe to avoid concurrent database access. Probe and engine-generated data remain within LiangYi's intended roots.

The approximately 622 ms probe duration is total process time for all 10 cycles and startup/finalization, not a candidate UI latency or translation measurement. Successful finite tests do not establish universal crash freedom.

## Warning and UI limitations

The fixed first deployment logged 199 warning lines: 191 dictionary `Encode failure` entries, and eight absent-configuration warnings during the initial build (including optional `grammar.yaml`). Both maintenance passes completed without failed tasks; zero error-level lines were observed. These warnings were not suppressed in the app. Some upstream dictionary entries therefore do not contribute encodable candidates; the tested synthetic words passed, but dictionary-wide coverage was not measured. [Warning summary](evidence/runtime-warning-summary.json) contains counts, not dictionary-entry bodies.

Notes' new-note control was disabled in the observed UI, so no existing note was modified for typing tests. The TextEdit automation entry point returned `timeoutReached` (`-10005`); no reliable synthetic field was established. Xcode editor verification remains pending. Terminal was previously denied by Computer Use, and no alternate AX or shell UI automation bypass was attempted. No private note content was persisted in project evidence.

## Reproduction and next gate

Use [MANUAL_ACCEPTANCE.md](MANUAL_ACCEPTANCE.md) to replace the initial bundle and perform Notes/Xcode/Terminal checks, including inherited focus-loss behavior, caret placement, source switching and input after reload. The assistant performed no deletion and no bundle replacement; optional cleanup of the accidental encoded-path child is a user decision.

Safe automated reproduction commands from the repository root:

```sh
python3 -B tools/check_round0.py
python3 tools/round0.py verify --bundle "$PWD/.artifacts/builds/round0-path-fix/DerivedData/Build/Products/Debug/EcholME.app"
```

The standalone engine probe's exact compiler/run command, roots and working directory are recorded in its evidence. Rerun only after stopping EcholME and rechecking links/configuration; do not point it at Squirrel data. A new full build requires a fresh build ID and keeps all earlier outputs.

Current exit: automated checks and manual instructions delivered; fixed installation and real IMK host acceptance remain pending user action. Stop at Round 0. Do not push or start Round 1.
