# Round 1 — Installation and real input acceptance

Current result: **NOT_RUN** for the Round 1 bundle. Round 0 observations are
historical and do not establish that changed input behavior passes.
Current artifact: the repaired **0.0.3** build, `round1-shift-final-03`.

During guided testing, perform one numbered step at a time and wait for human
confirmation. Use dedicated synthetic documents only. A pasted payload is not
evidence of typed-key behavior. Test equals with a physical key: the Computer Use
alias previously produced `+` even in system ABC. Do not bypass the prior
Terminal tool denial; Terminal checks remain user-performed.

## Installation steps

1. Switch to Apple Simplified Pinyin or ABC and confirm normal typing. Do not
   quit the currently selected input source.
2. Quit EcholME through its own installed executable and check that the process
   stopped. Run separately, not as an automatic replacement script:

   ```sh
   "$HOME/Library/Input Methods/EcholME.app/Contents/MacOS/EcholME" --quit
   pgrep -x EcholME
   ```

   No PID normally means no matching running process; check the command result.
   Do not use `killall IMKServer`, kill Squirrel or affect other input methods.
3. The user removes only the old `~/Library/Input Methods/EcholME.app` in Finder.
   Keep Rime configuration, user dictionaries, logs and Round 0 evidence.
   `AGENTS.md` says: "do not perform filesystem-level deletion" and "If removal
   is necessary, explain it and leave it to the user." The assistant cannot
   perform deletion or evade it through a move/rename/overwrite operation.
4. Verify and install the completed artifact at the now-absent target:

   ```sh
   cd /Users/zhenkun/GitHub/LiangYi-EcholME
   python3 -B tools/round0.py verify \
     --bundle .artifacts/builds/round1-shift-final-03/DerivedData/Build/Products/Debug/EcholME.app
   python3 -B tools/round0.py install-first \
     --bundle .artifacts/builds/round1-shift-final-03/DerivedData/Build/Products/Debug/EcholME.app
   ```

   If the installer says the target exists, stop. On a partial copy or stale
   package, inspect it with the user; no cleanup/replacement workaround.
5. Register the installed copy, not the build-directory copy:

   ```sh
   "$HOME/Library/Input Methods/EcholME.app/Contents/MacOS/EcholME" --register-input-source
   ```

   Registration tells macOS where the source lives; it is separate from enabling
   and selecting it. Add/select 两仪 in System Settings > Keyboard > Text Input.
   If the input-source cache is stale, log out/back in only after saving work.
   Confirm installed bundle version **0.0.3**, not the Round 0 version 0.0.1 or
   the initial Round 1 version 0.0.2.
6. Open a new Notes fixture named `EcholME Round 1 acceptance`, select 两仪, and
   start in Chinese. Leave "Example translations" on. Confirm a horizontal
   row with primary text above the matching subtitle; the footer says Examples.

## Notes cases (run separately)

For each case record: mode, physical keys, actual committed text, marked-text
state, candidate visibility, focus/mode after the action, and PASS/FAIL. Do not
store unrelated note content or credentials. All rows below are **NOT_RUN**.

| ID | Keys/action | Expected behavior |
| --- | --- | --- |
| N01 | Chinese `nihao`; wait for subtitle | Candidate 你好 above `hello` in its column; horizontal layout; host retains focus. Other candidates may show `—`. |
| N02 | Space | Commit 你好 once; no extra space; panel and underline clear. |
| N03 | `zhongguo`, then visible label `1` | Commit displayed first candidate once; panel/underline clear. |
| N04 | `nihao`, Esc, then `nihao`, Space | First composition produces no text; recovery commits one 你好. |
| N05 | `nihao`, Return; then another Return | First commits literal `nihao` without newline; second creates one host newline. |
| N06 | Verified active composition with zero candidates, Return | Commit its raw input once without newline; next Return reaches host. `/` is only a possible fixture: if it shows candidates or commits directly, this is not the no-candidate branch. Record a qualifying fixture first or leave this branch NOT_RUN. |
| N07 | `nihao`, wait for `hello`, Option+Return, then switch source/field | Commit only `hello`, no appended 你好/nihao, space or newline. |
| N08 | `nihao`, immediate Option+Return before subtitle is ready | No insertion while pending; composition remains available for normal selection. If the subtitle was already ready, leave the pending branch NOT_RUN; do not report that valid translated commit as a failure. Do not infer timing from a paste. |
| N09 | Chinese `/1`, Esc | Retain schema recognizer/symbol behavior; do not interpret the `1` as unconditional candidate choice; cancellation recovers. |
| N10 | Left Shift alone, then English `hello` | One English candidate `hello` above 你好; no mode reversal on ordinary typing. |
| N11 | English `hello`, Space | Exact `hello ` once (one trailing space), panel/underline clear. |
| N12 | English `hello`, Return, Return | Raw `hello` first; newline only on second Return. |
| N13 | English `hello`, wait, Option+Return, then leave field | Only 你好, no later `hello`. |
| N14 | English `hello`, Esc; type `world`, Space | No cancelled hello; exact `world ` after recovery. |
| N15 | English `hello123`, Space; then initial `123` | Token digits remain literal; initial digits pass through; no numeric candidate choice. |
| N16 | English unknown token, wait, Option+Return, then Space | Missing `—` gives no translated insertion; raw token plus space remains possible. |
| N17 | English use Shift with letters to type `HELLO`, Space | Uppercase preserved, no accidental Chinese mode switch. Test Shift combined with another modifier as well. |
| S01 | Chinese `nihao`, quick Left Shift alone, `a`, Return | Exact `nihaoa`, produced by `nihao` then `a`; no loss, space/newline or later duplicate. ASCII mode after Left Shift. |
| S02 | English quick Left Shift+`A`, release Shift, Return; repeat with Right Shift | Exact `A` each time; mode stays ASCII; no buffer/underline loss on release. |
| S03 | English `hello`, quick Left Shift alone, `nihao`, Space; repeat with Right Shift | Exact `hello你好` in both cases; English finalized once before Chinese input. |
| S04 | Chinese `nihao`, quick Right Shift alone, `a`, Return | Baseline `commit_text` produces exact `你好a`; right-tap schema selection preserved. |
| S05 | Hold either Shift for >0.5 seconds and release; overlap both Shift keys; use Shift with Option/Command | No accidental toggle or input loss; test both release orders. Avoid unrelated host shortcuts. |
| S06 | Shift down, change source/field/mode, Shift up | Release cannot change the new focus/mode or revive old input/subtitles. |
| N18 | Tab and Command shortcuts while composing, each in a fresh fixture | Raw text finalized at most once; host receives original action; no late subtitle/panel revival. Do not submit or navigate unsaved documents unintentionally. |
| N19 | English physical `===`; `user@example.com`; `https://example.com/a?q=1`; `x == 1` | Literal punctuation/digits preserved across token boundaries. Notes smart typography/link transforms must be distinguished from IME output. |
| N20 | Chinese physical `=`+Space three times; Chinese punctuation | `===` without separator; retain configured Chinese punctuation/recognizers. Do not require ASCII preservation in explicit Chinese mode. |
| N21 | Change input/new field/mode/Example Off before delayed result arrives | Old result never revives the panel or writes into the new field. Normal deactivation finalizes raw into the old bound client once. |
| N22 | Mouse hover/click lower line; move page before mouse release | Hover outline does not change keyboard selection; click submits that column's primary once; obsolete press/release rejected. |
| N23 | `nihaozhongguo`; choose a shorter candidate leaving a remaining segment, or use engine caret navigation; Option+Return | First verify and record the actual partial composition. No whole-composition translation from that partial candidate, even if it has an example subtitle. If no partial state is established, leave this branch NOT_RUN. |
| N24 | Repeat Backspace to empty, empty Space/Return; keypad Enter if available | No swallowed host newline/space after empty composition; keypad Enter follows Return contract. |
| N25 | Screen edges, external display/Retina scaling; subtitle arrives during hover | Rows stay horizontal, paired text stays in its column, highlight/page stay stable; panel clamped and never activates. Actual hardware required. |
| N26 | Switch Example Off and back on | Old raw text finalized once; no queued result survives Off; ASCII returns to direct passthrough while Off. Preference is per controller, not persistent. |

## Other hosts and latency

After Notes, repeat the core Space/digit/Return/Esc/translated-commit/focus matrix
in a new Xcode scratch document and a harmless Terminal editor buffer. In
Terminal, do not type Return into a shell prompt with executable payloads. Use
physical typing and record host editing/submit differences. Current Xcode and
Terminal outcomes are **NOT_RUN** for Round 1; previous tool/platform blockers
must not be called passing tests or bypassed.

The fixture timer is not a performance measurement. End-to-end translation
latency below 150 ms, real dictionary quality, cold/warm behavior and crash-free
host operation require separate runtime evidence. Do not assign PASS based on
the expected timer value, standalone core tests or engine-only checks.

On any wrong-field or duplicate insertion, stop that case, switch to the system
input source, and report exact synthetic keys/output and version. Preserve
artifacts; do not dump private document content. Delivery acceptance remains
pending until the recorded bundle passes the relevant actual host cases.
