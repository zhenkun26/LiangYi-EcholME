# Round 0 runtime acceptance follow-up

Recorded: 2026-10-11, America/New_York.

**Delivery: FIXED_INSTALL_COMPLETE; NOTES_BASIC_INPUT_PASS; EXTENDED_HOST_UAT_PENDING.** This is not a full Round 0 acceptance pass. Implementation baseline is `3975903`; this guided checkpoint updates documentation only. No Round 1 work, push, public distribution or release occurred. [VERIFICATION.md](VERIFICATION.md) preserves the initial delivery at `6e971c2`; this report supersedes its current runtime-policy status.

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

At the automated-runtime checkpoint, the installed `~/Library/Input Methods/EcholME.app` was still the initial, unfixed app; its 84-file inventory was unchanged. Both input modes were disabled/unselected and no EcholME process remained running. Build-directory startup of the fixed artifact did not register that copy or select an input source. **This historical installed-state snapshot is superseded by the guided installation below.**

At that checkpoint, accidental encoded-path files were unchanged after the fixed-build checks, and standard Squirrel installation, preference and Rime-data paths remained absent. This verifies the inspected historical paths; it does not claim a concurrent two-IME coexistence test or prove that every unrelated file on the machine was untouched. [Automated-run isolation snapshot](evidence/runtime-final-isolation.json), [automated-run TIS state](evidence/runtime-final-tis.json).

## Guided installation and Notes acceptance

The user switched to Apple Simplified Pinyin, quit the old app, confirmed no matching process and moved the old bundle to Trash. The assistant then verified the fixed artifact and installed it with `install-first` only after the destination was absent. Installed-bundle verification passed again before activation. No assistant deletion, existing-target overwrite, keyboard-cache removal or system-wide service restart occurred.

The installed app's `--register-input-source` returned OSStatus 0 and exposed Hans/Hant. Computer Use added 两仪 under Simplified Chinese in System Settings. Hans selection returned OSStatus 0, independent TIS inspection confirmed the selected mode, and the running input session responded `nascii`. The latest checkpoint confirms Hans enabled/selected, Hant disabled/unselected and the installed EcholME process running. Restoration to the original input source is still NOT_RUN.

Five basic Notes cases passed in dedicated synthetic notes: Space commit, numeric selection, Escape cancellation/recovery, Return committing raw unselected letters and Return creating a newline with an empty composition. Computer Use observed the synthetic field results; the user confirmed candidate identity and panel closure because the background candidate panel could not be reliably read through automation. Composing Return was user-operated; empty-composition Return used pasted fixture markers around one real Return event. Full case evidence and remaining coverage are in [MANUAL_ACCEPTANCE.md](MANUAL_ACCEPTANCE.md).

A later, separately authorized Notes punctuation step exercised digits and 31 distinct symbol keys in Chinese and ASCII modes. Field results matched the configured Chinese mappings or ASCII behavior, with quote transforms also reproduced under system ABC. Slash followed by a digit entered the configured symbol-code recognizer; Escape removed the pending `/1`, and standalone slash plus Space committed `、`. Fresh `nihao` plus Space still produced one `你好`. Automated `equal` produced `+` in both EcholME modes and ABC, so physical equals verification is **BLOCKED_AUTOMATION_INPUT**, not an established EcholME-specific failure. Candidate closure/underline confirmation for this step remains pending. The final independent probe confirmed Hans / `nascii` and a running installed process. See [synthetic punctuation evidence](evidence/notes-punctuation-acceptance.json).

The first `nihao` composition ended before the separately authorized Space step. Its already-committed result was not presented as evidence of that Space event; the assistant used a fresh fixture for the controlled Space test. Subsequent fixtures retained prior synthetic notes and avoided overwriting unrelated notes. No screenshots or private note text were copied into project evidence.

## Verification ledger

| Check | Result | Evidence and limit |
| --- | --- | --- |
| Initial installed runtime data path | FAIL; fixed installation now complete | `%20` incident preserved; the user later removed the initial app and the fixed app was installed at the absent target. |
| Fixed-source Debug build | PASS | [Build report](evidence/path-fix-build-verification.json); `BUILD SUCCEEDED`; [input hashes](evidence/path-fix-build-source-sha256.json). |
| Compiler/linker warnings | PASS with listed tool warning | No Swift/compiler/linker warning; inherited AppIntents metadata extraction warning remains. |
| Fixed bundle signature/resources | PASS | [Post-runtime static report](evidence/path-fix-post-runtime-verification.json); app signature remains valid. |
| Fixed-build normal startup and deployment | PASS | PID 12617; expected compiled files created inside decoded LiangYi/Rime; two schemas and `3 tasks ran: 3 success, 0 failure`. [Deployment evidence](evidence/runtime-fixed-deployment.json). |
| Idle reload request and execution | PASS (maintenance only) | CLI returned 0; independent console/log evidence shows reload and a second `3 success, 0 failure` maintenance pass. Does not prove host input after reload. |
| Bundle-specific shutdown | PASS | `--quit` returned 0 and process absence confirmed. [Record](evidence/runtime-quit.json). |
| Probe compilation | PASS | C11, `-Wall -Wextra -Wpedantic -Werror`; no diagnostic. [Compiler record](evidence/rime-smoke-compile.json). |
| Real librime candidates / Space / numeric / Esc | PASS (engine only) | 10 cycles, 30 checks; [result](evidence/rime-smoke-result.json). No IMK client or UI. |
| Guard tests | PASS | Existing 12 tests rerun after verifier change; [output](evidence/runtime-guard-tests.txt). |
| Corrected build installation / registration | PASS | User removal followed by reviewed absent-target installation; installed static verification and registration OSStatus 0. |
| Notes basic actual input | PASS (five bounded cases) | CUA synthetic-field observations plus user candidate/closure confirmations; composing Return was user-operated. See the manual ledger. |
| Notes punctuation / symbols | PASS (bounded field results); equals BLOCKED_AUTOMATION_INPUT | Digits and 31 symbol keys in two modes, configured mappings, slash cancellation and recovery; physical equals and visual panel/underline confirmation pending. No measured latency claim. |
| Remaining Notes / Xcode / Terminal input | NOT_RUN / BLOCKED_TOOL_POLICY | Composition-time punctuation, mixed/Unicode/editing cases, Return branches, caret/focus/switch/reload checks and Xcode are pending; Terminal remains user-operated. |
| Input-source selection | PASS | Hans independently confirmed enabled/selected; active session responded `nascii`. |
| Original-source restoration | NOT_RUN | Original source was Apple Simplified Pinyin; the current guided checkpoint keeps Hans active pending further user-confirmed tests. |
| Concurrent Squirrel coexistence | NOT_RUN | No Squirrel installation/data here; static identity/path isolation and standard-path absence were checked. |
| macOS 14 / Intel runtime; translation latency | NOT_RUN / NOT_APPLICABLE | No runtime test environment for the former; no translation implemented for the latter. |
| External GPL distribution readiness | NOT_RUN | Existing corresponding-source/data/dependency gates remain; no distribution. |

The standalone probe uses the same pinned librime and fixed build's SharedSupport. It selects `luna_pinyin_simp` with ASCII disabled and checks: `nihao` first candidate and Space commit equal “你好”; `zhongguo` numeric selection equals its copied displayed-first candidate; Esc clears input/candidates without a commit; no second unread commit or residual composition remains. It validates writable roots before and after, stops on failures, and never reads host text, syncs, or performs manual cleanup. The IME was stopped before the probe to avoid concurrent database access. Probe and engine-generated data remain within LiangYi's intended roots.

The approximately 622 ms probe duration is total process time for all 10 cycles and startup/finalization, not a candidate UI latency or translation measurement. Successful finite tests do not establish universal crash freedom.

## Warning and UI limitations

The fixed first deployment logged 199 warning lines: 191 dictionary `Encode failure` entries, and eight absent-configuration warnings during the initial build (including optional `grammar.yaml`). Both maintenance passes completed without failed tasks; zero error-level lines were observed. These warnings were not suppressed in the app. Some upstream dictionary entries therefore do not contribute encodable candidates; the tested synthetic words passed, but dictionary-wide coverage was not measured. [Warning summary](evidence/runtime-warning-summary.json) contains counts, not dictionary-entry bodies.

Notes' new-note control was disabled during the initial automated attempt; subsequent guided acceptance successfully created dedicated synthetic notes. The earlier TextEdit timeout remains historical. Candidate-window Computer Use lookup timed out or lacked an observable app surface; field evidence was supplemented by human panel confirmations. Xcode editor verification remains pending. Terminal was previously denied by Computer Use, and no alternate AX or shell UI automation bypass was attempted. No private note content was persisted in project evidence.

The candidate panel remains vertical and Chinese-only. The user confirmed a future horizontal layout with one primary/translation pair per column. This was recorded in the plan without implementing a later-round feature. No candidate or translation latency was measured during the guided Notes checks.

## Reproduction and next gate

Use [MANUAL_ACCEPTANCE.md](MANUAL_ACCEPTANCE.md) to continue the remaining, separately confirmed Notes/Xcode/Terminal checks, including physical equals and visual confirmation, composition-time punctuation, mixed/Unicode input, Return branches, inherited focus-loss behavior, caret placement, source switching and input after reload. Fixed installation is complete. The assistant performed no deletion or existing-target overwrite; optional cleanup of the accidental encoded-path child is a user decision.

Safe automated reproduction commands from the repository root:

```sh
python3 -B tools/check_round0.py
python3 tools/round0.py verify --bundle "$PWD/.artifacts/builds/round0-path-fix/DerivedData/Build/Products/Debug/EcholME.app"
```

The standalone engine probe's exact compiler/run command, roots and working directory are recorded in its evidence. Rerun only after stopping EcholME and rechecking links/configuration; do not point it at Squirrel data. A new full build requires a fresh build ID and keeps all earlier outputs.

Current exit: automated checks, fixed installation/activation and basic Notes acceptance are complete; extended Notes, other-host acceptance and original-source restoration remain pending. Stop for the user's next-step confirmation within Round 0. Do not push, start Round 1 or claim full Round 0 acceptance.
