# Round 0 runtime acceptance follow-up

Recorded: 2026-10-11, America/New_York.

**Delivery: DELIVERED_WITH_VERIFICATION_LIMITS; WAITING_FOR_ROUND_1_AUTHORIZATION.** Round 0 is closed at the user's request. This is not a full cross-host acceptance pass. Implementation baseline is `3975903`; this closeout updates documentation/evidence only. No Round 1 work, push, public distribution or release occurred. [VERIFICATION.md](VERIFICATION.md) preserves the initial delivery at `6e971c2`; this report supersedes its current runtime-policy status.

## Authorization and scope

The user explicitly permitted librime's normal generated-file/database maintenance only within `~/Library/Application Support/LiangYi/` and `~/Library/Logs/LiangYi/`, while protecting Squirrel and other user data. Manual deletion, existing-bundle replacement, new dependencies and system-wide service restarts remain outside the automated workflow. Checks unavailable to automation are provided in [MANUAL_ACCEPTANCE.md](MANUAL_ACCEPTANCE.md).

The user subsequently authorized Round 0 closeout, superseding the earlier per-case waiting checkpoints for bounded remaining checks. The disclosed environment/visual gaps below remain unverified; delivery does not approve a later round or redefine them as passes.

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

A later, separately authorized Notes punctuation step exercised digits and 31 distinct symbol keys in Chinese and ASCII modes. Field results matched the configured Chinese mappings or ASCII behavior, with quote transforms also reproduced under system ABC. Slash followed by a digit entered the configured symbol-code recognizer; Escape removed the pending `/1`, and standalone slash plus Space committed `、`. Fresh `nihao` plus Space still produced one `你好`. Automated `equal` produced `+` in both EcholME modes and ABC. At that checkpoint, physical equals verification was **BLOCKED_AUTOMATION_INPUT**, and candidate closure/underline confirmation was pending; an EcholME-specific equals failure was not established. The independent probe confirmed Hans / `nascii` and a running installed process. See [historical synthetic punctuation evidence](evidence/notes-punctuation-acceptance.json).

That punctuation checkpoint is now supplemented by user physical-keyboard reports: ASCII repetition works, Chinese `=` plus Space commits one equals, and three such commits produce `===` without spaces. The user confirmed punctuation/equals panel closure and underline clearing. These reports resolve physical-equals acceptance; the automated-key alias limitation remains historical and was not bypassed.

The next authorized step tested seven email/URL/code payloads in each explicit mode with actual key events, observed before/after Return. **All seven ASCII literal-input checks passed; seven Chinese-mode observations are retained.** In Chinese mode, the structured email became `user——01-test@example.com`, and the code-like payload became `擦了路——愤怒（12+3）；`. The assistant initially mislabeled those observations as faults by imposing an unapproved literal-input criterion. After the user's correction, R0-UAT-001/002 are **WITHDRAWN_INVALID_CRITERION**; raw observations remain unchanged. Explicit Chinese mode applies pinyin/punctuation rules, and these observations do not establish defects. Notes auto-linked ASCII emails/URLs without changing displayed labels. Restored `nascii` plus fresh `nihao`/Space produced one `你好`; independent final source/mode/process checks passed. Panel/underline confirmation for this format step remains pending. [Format and manual-equals evidence](evidence/notes-format-input-acceptance.json) records observations and the criterion correction. No new test or source/schema change was made during this correction.

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
| Notes punctuation / symbols | PASS (bounded field results; physical follow-up user-confirmed) | Digits/31 symbol keys, configured mappings, slash cancellation and recovery; physical equals and punctuation panel/underline confirmed. CUA equals limitation persists; no latency measurement. |
| Notes email / URL / code-like input | ASCII: 7 PASS; Chinese: 7 observations | No English literal-input requirement was agreed for explicit Chinese mode; the two former fault labels are withdrawn while retaining raw results. Format-step panel confirmation pending. |
| Notes closeout editing / mixed / focus / switch / reload | PASS within field scope; observations distinguished | Composition Backspace/recovery, ASCII caret editing, explicit-mode mixed input, Unicode paste only, same-app no-leak check, ABC/Hans switching and post-reload input. [Closeout cases](evidence/notes-closeout-acceptance.json). |
| Remaining Notes visual / key branches | NOT_RUN | Broader grammar/operators, composition-time punctuation, other symbol choices, forward Delete/Tab, typed Unicode, no-candidate Return, keypad Enter, panel geometry/closure and cross-app focus remain unverified. |
| Xcode / Terminal input | BLOCKED_NO_UI_SURFACE / BLOCKED_TOOL_POLICY | Xcode connection timed out, had zero inventory windows and no focused AX element; Terminal remains user-operated with no bypass. |
| Input-source selection | PASS | Hans independently confirmed enabled/selected; active session responded `nascii`. |
| Original-source restoration | NOT_RUN | Original source was Apple Simplified Pinyin. No system input-menu surface was exposed in the inspected Computer Use inventory; Hans remains active and was not disabled. Manual steps provided. |
| Concurrent Squirrel coexistence | NOT_RUN | No Squirrel installation/data here; static identity/path isolation and standard-path absence were checked. |
| macOS 14 / Intel runtime; translation latency | NOT_RUN / NOT_APPLICABLE | No runtime test environment for the former; no translation implemented for the latter. |
| External GPL distribution readiness | NOT_RUN | Existing corresponding-source/data/dependency gates remain; no distribution. |

The standalone probe uses the same pinned librime and fixed build's SharedSupport. It selects `luna_pinyin_simp` with ASCII disabled and checks: `nihao` first candidate and Space commit equal “你好”; `zhongguo` numeric selection equals its copied displayed-first candidate; Esc clears input/candidates without a commit; no second unread commit or residual composition remains. It validates writable roots before and after, stops on failures, and never reads host text, syncs, or performs manual cleanup. The IME was stopped before the probe to avoid concurrent database access. Probe and engine-generated data remain within LiangYi's intended roots.

The approximately 622 ms probe duration is total process time for all 10 cycles and startup/finalization, not a candidate UI latency or translation measurement. Successful finite tests do not establish universal crash freedom.

## Warning and UI limitations

The fixed first deployment logged 199 warning lines: 191 dictionary `Encode failure` entries, and eight absent-configuration warnings during the initial build (including optional `grammar.yaml`). Both maintenance passes completed without failed tasks; zero error-level lines were observed. These warnings were not suppressed in the app. Some upstream dictionary entries therefore do not contribute encodable candidates; the tested synthetic words passed, but dictionary-wide coverage was not measured. [Warning summary](evidence/runtime-warning-summary.json) contains counts, not dictionary-entry bodies.

Notes' new-note control was disabled during the initial automated attempt; subsequent guided acceptance successfully created dedicated synthetic notes. The earlier TextEdit timeout remains historical. Candidate-window Computer Use lookup timed out or lacked an observable app surface; field evidence was supplemented by human panel confirmations. Xcode editor verification remains pending. Terminal was previously denied by Computer Use, and no alternate AX or shell UI automation bypass was attempted. No private note content was persisted in project evidence.

The candidate panel remains vertical and Chinese-only. The user confirmed a future horizontal layout with one primary/translation pair per column. This was recorded in the plan without implementing a later-round feature. No candidate or translation latency was measured during the guided Notes checks.

## Final closeout

### Objective and changed files

Finish the authorized Round 0 checks that the available environment supports, preserve truthful manual carryovers, and stop. No implementation/schema/dependency changed, so the earlier complete compilable source and fixed build remain the delivered baseline. The closeout touched:

```text
AGENTS.md                              closeout authority and next-round boundary
docs/project/PLAN.md                   delivery status; approved scope preserved
docs/project/STATUS.md                 final results, limits and next gate
docs/project/DECISIONS.md              observed capability/identity/check status
docs/round0/FOUNDATION.md               remove superseded install/UAT checkpoint claims
docs/round0/RUNTIME_ACCEPTANCE.md       final delivery report
docs/round0/MANUAL_ACCEPTANCE.md        results and actionable manual carryovers
docs/round0/evidence/
  closeout-verification.json           static/guard/hash/probe/reload/system evidence
  notes-closeout-acceptance.json        synthetic field observations and key paths
```

### Verification results

- **PASS:** installed static identity/resources/arm64 dependency paths/local signature; 12 guard tests rerun. Fixed-build input manifest still matches, and installed executable, Debug library and Info.plist equal the fixed artifact. No rebuild was necessary or performed in this documentation-only closeout.
- **PASS documentation checks:** both new evidence JSON files parse and satisfy the checked scope/result assertions; 16 Notes case records and 53 relative documentation links checked, with no invalid target. Git whitespace/diff checks passed. These are document checks, not additional runtime input tests.
- **PASS within field scope:** Notes composition editing and recovery, ASCII caret/Backspace editing, explicit-mode mixed input, empty/pending ABC/Hans switching, and input after installed reload. Same-app new-note test showed no text leak; old note retained one `ni hao`, unchanged by Escape. That old-field result is a host observation, not a claim of uniform raw-string finalization. Unicode passed only through paste.
- **PASS maintenance and subsequent field input:** confined-path preflight found no escaping links or YAML `sync_dir` override. Installed `--reload` returned 0; the initial log inspection had no acknowledgment. After Notes reactivation, the new log slice recorded 3 tasks, 3 success, 0 failure, and zero warning/error/fatal lines. Space, digit-1, Esc/cancel and fresh input passed afterward. The historical first-deployment warnings remain disclosed above.
- **PASS metadata only:** refreshed Notes AX probe exposed finite caret bounds and no AXLanguage; secure-field status remains unknown. No document text read or permission prompt. This is not IMK-client or panel-position evidence.
- **BLOCKED / NOT_RUN:** Xcode Computer Use timed out (`-10005`), inventory showed zero windows, and its metadata probe found no focused element (`-25212`). No editor input was tested. Terminal retains its tool-policy blocker; no new access or bypass attempted. Manual scratch/read fixtures are provided.
- **NOT_RUN:** closeout candidate-panel closure/underline/geometry, cross-app focus, no-candidate Return, keypad Enter, forward Delete/Tab, typed Unicode, arbitrary symbol/grammar sequences, physical equality-containing code, original-source restoration, real Squirrel coexistence, macOS 14/Intel runtime, and full external distribution closure. These are practical limits of the delivered round.
- **NOT_APPLICABLE:** translated candidate latency/quality, cloud-service behavior and new automatic direction; these features do not exist in Round 0. Primary candidate UI latency was also not measured.

No crash, wrong-new-field insertion or duplicate committed text was observed in the bounded closeout checks. Process presence and finite field results are not proof against every hang or crash. One mode-query attempt returned no response during metadata checks; after actual Notes field reactivation the query returned `nascii`. The evidence preserves both attempts instead of claiming background-query reliability.

### Final state and manual carryovers

EcholME remains installed, Hans enabled/selected, Hant disabled, process running, last active-session mode `nascii`. The dedicated fixture ends with the committed `ROUND0_CLOSEOUT_DONE` marker. Apple Simplified Pinyin has not been restored; no active source was disabled or IME quit. To end this enabled test state, first manually select that original source, verify it works, then optionally follow section 5 of the manual ledger. All data, logs, synthetic fixtures and accidental-path incident files remain intact.

Xcode manual verification uses a fresh scratch file containing `/* ... */` so test strings are not executable source. Terminal uses `IFS= read -r ECHOLME_TEST` before entering any test text; report the printed synthetic value. For either host, distinguish ASCII literal behavior from Chinese composition/punctuation mappings. Visual panel/edge/display checks and no-candidate/keypad Return checks require a real visible field and the appropriate physical input. See the detailed per-case instructions in [MANUAL_ACCEPTANCE.md](MANUAL_ACCEPTANCE.md).

GPL preparation retains upstream history, notices, modification records, locked dependency/data sources and packaged license files. This is **not external-distribution readiness**: complete corresponding source, recursive code/data/visual-resource review and an exact binary/source delivery set still need the existing release gates. Nothing was pushed or distributed.

## Reproduction and next gate

Use [MANUAL_ACCEPTANCE.md](MANUAL_ACCEPTANCE.md) for missing manual checks. Physical equals and punctuation closure are confirmed; the specific format-step panel confirmation remains unverified. R0-UAT-001/002 are withdrawn classifications, not outstanding fixes. Use mode-appropriate criteria and do not infer authorization for a new mode/context policy. Fixed installation is complete. The assistant performed no deletion or existing-target overwrite; optional cleanup of the accidental encoded-path child is a user decision.

Safe automated reproduction commands from the repository root:

```sh
python3 -B tools/check_round0.py
python3 -B tools/round0.py verify --bundle "$HOME/Library/Input Methods/EcholME.app"
```

The standalone engine probe's exact compiler/run command, roots and working directory are recorded in its evidence. Rerun only after stopping EcholME and rechecking links/configuration; do not point it at Squirrel data. A new full build requires a fresh build ID and keeps all earlier outputs.

Current exit: **Round 0 delivered with the verification limits above.** Wait for explicit user confirmation before Round 1. Its proposed scope is the unified state/commit model, ADR-017 key contract and approved horizontal two-line candidate layout with fixtures; real translation remains Round 2. Do not push, start a later round or claim full cross-host acceptance.
