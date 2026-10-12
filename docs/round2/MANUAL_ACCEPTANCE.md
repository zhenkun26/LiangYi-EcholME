# Round 2 — Installation and real input acceptance

Current result: **NOT_RUN**. The built bundle is version **0.0.4**:

```text
.artifacts/builds/round2-lexicon-20261012c/DerivedData/Build/Products/Debug/EcholME.app
```

The installed bundle is still **0.0.1**. Automated dictionary checks do not
replace typed input in Notes, Xcode, or Terminal. Do not install over the
existing app. The assistant does not delete, move, or replace it.

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

| ID | Action | Expected |
| --- | --- | --- |
| D01 | Chinese mode, type `nihao`, wait for candidates | `你好` shows `hello` underneath. The panel stays horizontal. |
| D02 | Option+Return on that candidate | The document receives `你好`'s subtitle `hello` once, and the pinyin is not appended. |
| D03 | Type `nihao` again, press Return | Raw letters commit once. No subtitle is committed. No extra newline. |
| D04 | Type an unknown syllable sequence that still produces an uncommon candidate, or a candidate with no dictionary line | Primary text still commits with Space or the schema binding. A missing subtitle is `—`, not a guessed translation. |
| D05 | English mode, type `hello`, Option+Return | The document receives `你好` once. The token `hello` is not appended. |
| D06 | English mode, type `echolme`, Option+Return | No insertion. The subtitle is `—`. Space still commits `echolme` plus one space. |
| D07 | While a subtitle is still pending or shows `!`, press Option+Return | No translation is inserted. |
| D08 | Turn Local translations off, type `hello` | ASCII is passed through. No Chinese subtitle is committed. |
| D09 | Turn translations back on. Type `nihao`, switch to another note before choosing | The old pinyin is not written into the new note. |

Xcode and Terminal repeats of D01–D03 are separate rows. They are NOT_RUN until
someone types them. Candidate-panel screenshots, mouse selection, and
multi-display placement are also NOT_RUN.
