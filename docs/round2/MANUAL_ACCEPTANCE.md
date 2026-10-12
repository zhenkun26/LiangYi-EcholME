# Round 2 — Installation and real input acceptance

Current result: **installed 0.0.4; TextEdit cases below PASS; Notes/Xcode/Terminal NOT_RUN**. The built bundle is version **0.0.4**:

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
     --bundle .artifacts/builds/round2-lexicon-20261012c/DerivedData/Build/Products/Debug/EcholME.app
   python3 -B tools/round0.py install-first \
     --bundle .artifacts/builds/round2-lexicon-20261012c/DerivedData/Build/Products/Debug/EcholME.app
   "$HOME/Library/Input Methods/EcholME.app/Contents/MacOS/EcholME" --register-input-source
   ```

5. Enable and select 两仪 in System Settings. Registration, selection, and
   typing are separate results.

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

CLI `--ascii` / `--nascii` posted a string, while the controller only accepts a Boolean, so those commands did not change mode. Left Shift did. That CLI mismatch was not changed in this check.

Xcode and Terminal repeats of D01–D03 are separate rows. They are NOT_RUN until
someone types them. Candidate-panel screenshots, mouse selection, and
multi-display placement are also NOT_RUN.
