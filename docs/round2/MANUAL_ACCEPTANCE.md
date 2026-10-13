# Round 2 — Installation and real input acceptance

Current result: **installed 0.0.4; repaired 0.0.6 NOT_INSTALLED; physical Shift acceptance NOT_RUN**.
The current repair bundle is:

```text
.artifacts/builds/shift-handoff-006-final-20261012/DerivedData/Build/Products/Debug/EcholME.app
```

The historical 0.0.4 bundle and TextEdit results below remain separate:

```text
.artifacts/builds/round2-lexicon-20261012c/DerivedData/Build/Products/Debug/EcholME.app
```

On 2026-10-12 the user removed the previous app. The destination was absent,
with no EcholME process. `verify` and `install-first` copied 0.0.4 only after
that check. Installed Info.plist, executable, lexicon, NOTICE, README, and
librime matched the artifact by SHA-256. Registration returned OSStatus 0.
Hans is enabled and selected; Hant is disabled and not selected. A short
`--select-input-source` call returned OSStatus 0 but did not stick until a
small helper kept its run loop alive for 1.5 seconds. The final probe then
showed Hans selected.

The server is the installed 0.0.4 binary. Rime recorded the distribution
version change from 0.0.1 to 0.0.4 and refreshed its build files under
`~/Library/Application Support/LiangYi/Rime/`. Its own deployment log says it
cleaned 4 old log files inside `~/Library/Logs/LiangYi/`; that is engine
maintenance in the authorized log root, not a manual deletion. The only
warning line is the inherited missing optional `grammar.yaml`. The test
strings `nihao`, `hello`, and `你好` do not appear in those logs.

TextEdit received System Events keystrokes in a new unsaved document. This is
real IMK input, not the Notes host named in the table. The candidate panel was
not screenshot-verified. Xcode and Terminal were not exercised. Do not install
over this bundle.

## Installation

Use one checkpoint at a time and wait for user confirmation. The user must
perform the old-bundle removal; Computer Use authorization does not override
the repository's no-deletion rule.

1. Switch to ABC or another working input source and confirm normal typing.
2. Quit the installed EcholME with its own executable. Do not use `killall`
   on system input services.

   ```sh
   "$HOME/Library/Input Methods/EcholME.app/Contents/MacOS/EcholME" --quit
   ```

3. The user removes only `~/Library/Input Methods/EcholME.app` in Finder.
   Keep `~/Library/Application Support/LiangYi/` and `~/Library/Logs/LiangYi/`.
4. After that path is absent:

   ```sh
   cd /Users/zhenkun/GitHub/LiangYi-EcholME
   python3 -B tools/round0.py verify \
     --bundle .artifacts/builds/shift-handoff-006-final-20261012/DerivedData/Build/Products/Debug/EcholME.app
   python3 -B tools/round0.py install-first \
     --bundle .artifacts/builds/shift-handoff-006-final-20261012/DerivedData/Build/Products/Debug/EcholME.app
   "$HOME/Library/Input Methods/EcholME.app/Contents/MacOS/EcholME" --register-input-source
   ```

5. Enable and select 两仪 in System Settings. Registration, selection, and
   typing are separate results. Check that the installed build is **0.0.6**.

## Physical Shift and visible language — 0.0.6

Computer Use can navigate the app/menu and inspect the dedicated synthetic
fixture. Its standalone Shift command is unsupported, so the user performs
each physical tap. Do not substitute a paste or a Shift-plus-letter chord.
Use the note `EcholME Shift acceptance 2026-10-12` or a new synthetic note.
Every row is currently **NOT_RUN**; stop after each row for confirmation.

| ID | Action | Expected result |
| --- | --- | --- |
| L01 | In 两仪's input-source menu select 英文主输入 / English, then type `hello` | English primary `hello`, Chinese subtitle when ready; English status/footer and menu checkmark. Return commits `hello` once without newline. |
| L02 | Empty composition, tap physical left Shift alone in under 0.5 s, then type `nihao`, Space | Chinese status, Chinese candidate, `你好` once. Repeat the empty-composition left tap in both directions ten times; observe the language after each. |
| L03 | Chinese `nihao`, left Shift, `a`, Return | Exact `nihaoa`, no added space/newline, no later duplicate. |
| L04 | English `hello`, left Shift, `nihao`, Space | Exact `hello你好`, no dropped prefix or duplicate. |
| L05 | English mode, Shift+A, release Shift, Return; test each side separately | `A`, still English. A hold longer than 0.5 s alone does not toggle. |
| L06 | Chinese `nihao`, right Shift, `a`, Return | Exact `你好a` under the baseline right-Shift binding. |
| L07 | Type `hello` in English; reselect English, then select Chinese | Reselection leaves the token pending; changing to Chinese submits raw `hello` once and makes the next pinyin input Chinese. |
| L08 | Hold Shift, change field/input source, release, resume input | No old-field insertion or unintended mode toggle in the new field. |

Record committed synthetic text, primary language, underline/panel closure,
and PASS/FAIL. Do not log real documents or unrelated Notes contents.

## Input checks

Use a new synthetic note. Record each row as PASS, FAIL, or NOT_RUN.

| ID | Action | Result |
| --- | --- | --- |
| D01 | Chinese mode, type `nihao`, Space | **PASS in TextEdit.** The synthetic document received `你好` once. The two-line panel itself was not observed. **Notes: NOT_RUN** (a new note was created, but keystrokes did not enter its body). |
| D02 | Option+Return on `nihao` | **PASS in TextEdit.** The document received `hello` once. The pinyin was not appended. |
| D03 | `nihao`, then Return | **PASS in TextEdit.** The document received `nihao` once, with no extra newline and no subtitle. |
| D04 | Unknown Chinese candidate | **NOT_RUN.** |
| D05 | English mode, `hello`, Option+Return | **PASS in TextEdit.** Left Shift switched `nascii` to `ascii`. The document received `你好` once. |
| D06 | English `echolme`, Option+Return, then Space | **PASS in TextEdit.** Option+Return inserted nothing. Space then inserted `echolme` plus one space. The `—` glyph was not seen. |
| D07 | Option+Return while pending or `!` | **NOT_RUN** on the installed host. The in-process timeout check already passed; the warm index did not stay pending. |
| D08 | Local translations off | **NOT_RUN.** |
| D09 | Focus change while composing | **NOT_RUN.** |

Historical CLI mode-change attempts did not produce the expected observed
change; left Shift did. The earlier attribution to a String/Boolean mismatch
is withdrawn: source inspection confirms ApplicationDelegate converts the
distributed string into a Boolean local notification. The exact cause of that
historical runtime failure was not established. In 0.0.6 CLI and menu changes
use the same guarded router, and mode queries ignore inactive controllers;
installed CLI verification remains NOT_RUN.

Xcode and Terminal repeats of D01–D03 are separate rows. They are NOT_RUN until
someone types them. Candidate-panel screenshots, mouse selection, and
multi-display placement are also NOT_RUN.
