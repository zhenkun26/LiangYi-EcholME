# Round 0 manual acceptance

Recorded: 2026-10-11, America/New_York.

These are pending steps, not passed test evidence. See [RUNTIME_ACCEPTANCE.md](RUNTIME_ACCEPTANCE.md) for automated results and the path-encoding incident. Round 1 and pushing remain unauthorized.

## 1. Install the fixed artifact before testing input

**Do not enable the currently installed initial app.** It contains the path-encoding bug found during runtime acceptance. Its sources are fixed and the replacement artifact is built, but the installer refuses an existing destination under the no-deletion policy.

1. Save any work and use the system input menu to select your original input source. Record its name; do not assume it is ABC.
2. If necessary, quit EcholME only:

   ```sh
   "$HOME/Library/Input Methods/EcholME.app/Contents/MacOS/EcholME" --quit
   ```

3. In Finder, you must remove the old `~/Library/Input Methods/EcholME.app` yourself. The assistant did not remove, rename or replace it. Leave Squirrel and all other input methods untouched. Do not remove the entire `Input Methods` folder.
4. Install the fixed, already-built artifact into the now-absent target:

   ```sh
   cd /Users/zhenkun/GitHub/LiangYi-EcholME &&
   python3 tools/round0.py verify --bundle "$PWD/.artifacts/builds/round0-path-fix/DerivedData/Build/Products/Debug/EcholME.app" &&
   python3 tools/round0.py install-first --bundle "$PWD/.artifacts/builds/round0-path-fix/DerivedData/Build/Products/Debug/EcholME.app" &&
   "$HOME/Library/Input Methods/EcholME.app/Contents/MacOS/EcholME" --register-input-source &&
   "$HOME/Library/Input Methods/EcholME.app/Contents/MacOS/EcholME" --enable-input-source io.github.zhenkun26.inputmethod.EcholME.Hans &&
   "$HOME/Library/Input Methods/EcholME.app/Contents/MacOS/EcholME" --select-input-source io.github.zhenkun26.inputmethod.EcholME.Hans
   ```

   The `&&` chain stops immediately on any nonzero exit status. Do not continue to register/enable/select the old installed app after verification or installation fails. Inspect every exit status. If registration succeeds but the source is missing from the input menu, inspect System Settings > Keyboard > Text Input > Edit. Add 两仪 / EcholME if available. If stale registration persists, save work and log out/in manually; do not delete keyboard caches or restart system-wide services.
5. Normal engine maintenance may modify generated files and databases only within `~/Library/Application Support/LiangYi/` and `~/Library/Logs/LiangYi/`. The audited current roots have no escaping symlinks. Recheck if you edit configuration, add links or change `sync_dir`; an override outside these roots is outside this authorization.

The accidental directory `~/Library/Application%20Support/LiangYi/` was retained as incident evidence and is no longer used by the fixed build. Optional cleanup is a user action in Finder, confined to that `LiangYi` child. Never remove the parent `Application%20Support` directory or other contents. Cleanup is not required for the fixed build to work.

## 2. Notes and Xcode

Use only synthetic text in a new, dedicated test note or scratch file. Do not overwrite existing notes or project source. Xcode can use a new scratch `.swift` file with test text inside a comment. On this automation run, Notes' new-note control was disabled and a separate TextEdit launch timed out; no safe synthetic UI field was established.

Xcode and Terminal inherit `ascii_mode: true`. In an empty composition, briefly press **left Shift** to enter Chinese mode. Its behavior during an existing composition differs. Alternatively, use the inherited Rime switcher (Control+grave or F4). The status icon displays the mode; it is not a clickable mode toggle. Round 0 has no new automatic direction or translation semantics.

Run each row in Notes and Xcode and record the observed outcome separately:

| Case | Steps | Pass criterion | Result |
| --- | --- | --- | --- |
| Candidates and Space | Type `nihao`; confirm a candidate panel and the displayed Chinese candidate; commit with Space. | Displayed primary text appears once; no leftover raw pinyin; panel hides. | PENDING |
| Number selection | Type `zhongguo`; note a visible candidate number/text and press that number. | Committed text equals the displayed choice, once. Do not assume a fixed ranking. | PENDING |
| Esc | Type `nihao`, then Esc. Type and commit again. | Composition/panel disappear without new text; subsequent input works. | PENDING |
| Caret geometry | Move to a new line and near a window edge, then compose again. | Panel follows the current insertion point and stays visible. Record multi-display/scale checks separately when available. | PENDING |
| Focus change | Leave `nihao` uncommitted in one synthetic field; click a second synthetic field. | No old input enters the new field; no duplicate insertion; old panel hides. | PENDING |
| Input-source switch | With empty composition, switch to the original source and back. Repeat once with an uncommitted synthetic composition. | Both sources remain usable; no orphaned panel or duplicate text. Record how the old field finalizes. | PENDING |

Inherited deactivation calls `commitComposition()`, which may commit unfinished **raw pinyin into the old field**. This is the Round 0 baseline, not a failure solely because it is raw pinyin. It must not write that text into the new field or duplicate it. A different focus-loss policy belongs to a later authorized round.

## 3. Terminal — user-operated only

Computer Use denied Terminal access. This permission to run librime does not override that tool boundary. The assistant did not use shell UI automation or AX access to bypass it.

In a new Terminal window, manually start this shell input fixture:

```sh
IFS= read -r ECHOLME_TEST
```

The shell is now reading a value rather than executing the typed test text. Select EcholME, enter Chinese mode with an empty composition, and repeat candidate/Space/number/Esc checks above. Return ends the read. Then inspect only the synthetic result:

```sh
printf '%s\n' "$ECHOLME_TEST"
```

Do not type test pinyin at an ordinary shell command prompt and press Return. Focus/caret checks here remain PENDING until you report results.

## 4. Reload and coexistence

With no unfinished composition, request reload:

```sh
"$HOME/Library/Input Methods/EcholME.app/Contents/MacOS/EcholME" --reload
```

Exit 0 means notification delivery only. Wait for maintenance to finish, then repeat candidates, commit and Esc in the synthetic field. For the automated fixed-build idle run, both maintenance passes reported `3 success, 0 failure`; real host input after reload still needs this step.

If Squirrel is already installed, switch between it and EcholME via the input menu. Confirm Squirrel still uses its own settings/dictionary and EcholME uses `Application Support/LiangYi/Rime`. No Squirrel installation/data was present here, so actual two-IME coexistence was not exercised. Do not install Squirrel just to fill this row without a separate decision.

## 5. Finish and report

1. Restore the original input source using the input menu.
2. Disable the test modes and quit EcholME only:

   ```sh
   "$HOME/Library/Input Methods/EcholME.app/Contents/MacOS/EcholME" --disable-input-source io.github.zhenkun26.inputmethod.EcholME.Hans io.github.zhenkun26.inputmethod.EcholME.Hant
   "$HOME/Library/Input Methods/EcholME.app/Contents/MacOS/EcholME" --quit
   ```

3. Keep logs/data for inspection; no automated cleanup is part of this workflow.
4. Report app/OS versions, case names, PASS/FAIL and any observed crash, hang, wrong-field write or duplicate insertion. Use synthetic examples only; do not send private document text or raw unreviewed logs.

A finite passing run means no crash was observed in that run. It does not establish universal crash freedom, macOS 14 runtime compatibility, Intel support, translation latency, or permission to begin Round 1.
