# Round 0 manual acceptance

Recorded: 2026-10-11, America/New_York.

This is both the procedure and the guided acceptance ledger. PASS applies only to the exercised cases below; all other cases remain pending. See [RUNTIME_ACCEPTANCE.md](RUNTIME_ACCEPTANCE.md) for automated results and the path-encoding incident. Round 1 and pushing remain unauthorized. Every next UI test requires the user's step confirmation.

## Guided checkpoint

Environment remains macOS 26.5 / arm64; tested implementation is the fixed `3975903` baseline installed from `round0-path-fix`. The user switched to Apple Simplified Pinyin, quit the old process and moved the old app to Trash. Reviewed absent-target installation and installed-bundle verification passed. Registration returned OSStatus 0; System Settings added 两仪; independent TIS inspection confirmed Hans selection, and the active session responded `nascii`.

Dedicated synthetic Notes fixtures were used. Letter sequences, Space, digit 1, Escape and Return were actual key events. Empty-composition Return used two pasted, already-committed markers around one actual Return; this does not validate English typing or clipboard behavior generally. No screenshots or private note text were saved to the repository. Candidate-panel accessibility was unreliable, so human confirmations remain part of the evidence rather than an automated panel-reading claim.

Current state: Hans enabled/selected, Hant disabled/unselected, installed EcholME running. Original-source restoration and shutdown are NOT_RUN. The source was not restored automatically at a step boundary.

The separately authorized punctuation step used an observed empty note and a new synthetic note. Digits and 31 distinct symbol keys were exercised in Chinese and ASCII modes, with existing mode CLI commands used only between completed compositions. A temporary system ABC control reproduced the automated equals-key anomaly and ASCII quote transforms. Hans and the starting `nascii` mode were restored and independently verified. This control is not a complete source-switch regression test. No input-method source changed; [structured punctuation evidence](evidence/notes-punctuation-acceptance.json) contains only synthetic cases and status-safe observations.

## 1. Install the fixed artifact before testing input

**This installation step is complete for the current machine.** The initial app had the path-encoding bug; the user removed it and the fixed app was installed only after the destination was absent. The procedure below is retained for reproduction. Never enable an old, unfixed app or rerun `install-first` over an existing target.

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

Use only synthetic text in a new, dedicated test note or scratch file. Do not overwrite existing notes or project source. Xcode can use a new scratch `.swift` file with test text inside a comment. Notes' new-note control was initially unavailable, but later guided acceptance successfully established dedicated notes. The earlier TextEdit launch timeout remains historical; Xcode has not yet been exercised.

Xcode and Terminal inherit `ascii_mode: true`. In an empty composition, briefly press **left Shift** to enter Chinese mode. Its behavior during an existing composition differs. Alternatively, use the inherited Rime switcher (Control+grave or F4). The status icon displays the mode; it is not a clickable mode toggle. Round 0 has no new automatic direction or translation semantics.

Run each row in Notes and Xcode and record the observed outcome separately. Results below distinguish Computer Use field observations from user-reported UI behavior:

| Case | Steps | Pass criterion | Notes result / evidence | Xcode result |
| --- | --- | --- | --- | --- |
| Candidates and Space | Type `nihao`; confirm a candidate panel and the displayed Chinese candidate; commit with Space. | Displayed primary text appears once; no leftover raw pinyin; panel hides. | PASS: fresh fixture contained one “你好”; user confirmed panel closure. The first interrupted composition was not treated as a Space pass. | NOT_RUN |
| Number selection | Type `zhongguo`; note a visible candidate number/text and press that number. | Committed text equals the displayed choice, once. Do not assume a fixed ranking. | PASS: digit 1 produced one “中国”; user confirmed candidate 1 was “中国” and the panel closed. | NOT_RUN |
| Esc and recovery | Type `nihao`, then Esc. Type and commit again. | Composition/panel disappear without new text; subsequent input works. | PASS: Notes became empty after Escape, then contained one “你好” after fresh input and Space. User separately confirmed Escape closes the panel; the attached `an shi` panel was photographed before Escape, not after it. | NOT_RUN |
| Return while composing | Enter an unselected Latin/pinyin composition, then Return. | Current baseline commits raw unselected input; composition underline/panel clear. | PASS (user-operated, bounded observation): user reported raw letters remained, panel closed and underline disappeared. Source inspection corroborated the inherited mapping; a separate duplicate-count check was not performed. | NOT_RUN |
| Return with empty composition | Insert committed marker A, press Return once, insert committed marker B. | Markers are separated by exactly one newline; no swallowed Return or duplicate text. | PASS: CUA observed `ROUND0_RETURN_A\nROUND0_RETURN_B` in the dedicated fixture after one Return; user confirmed the step complete. | NOT_RUN |
| Return with no candidate / keypad Enter | Establish a live no-candidate composition; test Return. Test keypad Enter separately if available. | Document raw-input/host behavior and confirm no stuck composition, lost text or duplicate insertion. | NOT_RUN; ordinary composing Return does not cover these branches. | NOT_RUN |
| Caret geometry | Move to a new line and near a window edge, then compose again. | Panel follows the current insertion point and stays visible. Record multi-display/scale checks separately when available. | NOT_RUN | NOT_RUN |
| Focus change | Leave `nihao` uncommitted in one synthetic field; click a second synthetic field. | No old input enters the new field; no duplicate insertion; old panel hides. | NOT_RUN | NOT_RUN |
| Input-source switch | With empty composition, switch to the original source and back. Repeat once with an uncommitted synthetic composition. | Both sources remain usable; no orphaned panel or duplicate text. Record how the old field finalizes. | NOT_RUN; initial activation is not a switching-regression test. | NOT_RUN |

Current deployed `luna_pinyin_simp` uses `express_editor`. Its ordinary Return maps to `CommitRawInput`; Space confirms a selection. This explains retaining raw unselected letters rather than choosing Chinese on Return. See the [pinned librime implementation](https://github.com/rime/librime/blob/33e78140250125871856cdc5b42ddc6a5fcd3cd4/src/rime/gear/editor.cc#L192-L202). Future mode/translation shortcuts remain undecided; this baseline evidence does not settle ADR-017.

### Guided punctuation result

**PASS applies to the observed field results. The earlier equals automation limitation was resolved for acceptance by the user's physical-keyboard checks below.** These cases started without an active pinyin composition. They do not validate every possible symbol sequence or all hosts.

| Case | Actual keys / finalization | Observed Notes result | Status / limit |
| --- | --- | --- | --- |
| Digits outside composition | `1234567890`, in both modes | Exactly `1234567890` | PASS; candidate-selection digits remain a separate case above. |
| Common punctuation | `. , ! ? : ;` | Chinese: `。，！？：；`; ASCII: `.,!?:;` | PASS; intentional Chinese mappings. |
| Paired quotes | Two double-quote presses, then two single-quote presses | Chinese: `“”‘’`; ASCII: `“”’’` | PASS for observed baseline behavior. System ABC reproduced the ASCII result, consistent with Notes/system smart-quote transformation; literal ASCII quote preservation is not established in this host. |
| Parentheses | `( )` | Chinese: `（）`; ASCII: `()` | PASS. |
| Symbol choices | `# @ /` and backslash, then `[ ] { }`; digit 1 for `#`/`@`, Space for the remaining symbol choices | Chinese: `#@、、「」『』`; ASCII keys directly: `#@/` plus backslash and `[]{}` | PASS; choosing a configured symbol is distinct from passing through its source key. |
| Other symbols | `- + _ $ % ^ & *` and pipe, `< >`, grave, tilde; Space for configured choice lists | Chinese mappings: hyphen/plus unchanged; underscore → `——`, dollar → `￥`, percent → `%`, caret → `……`, ampersand/asterisk unchanged, pipe → `·`, angle keys → `《》`, grave/tilde unchanged. ASCII keys preserved these symbols. | PASS; default choices only, not every alternative. |
| Slash followed by a digit | `/1`, then Escape; independently `/` then Space | `/1` was pending input; Escape removed it without altering prior text. Standalone slash plus Space committed one `、`. | PASS for cancellation/recovery and standalone slash. The recognizer `^/([0-9]0?\|[A-Za-z]+)$` makes the digit part of a symbol code; the initial assumption that it selected the slash candidate was invalid. Actual symbol-code selection remains NOT_RUN. |
| Equals automation | CUA `equal`, isolated and repeated in Chinese, ASCII and system ABC | All three produced `+`; literal `pressKey("=")` was rejected before input with `keyNotFound`. | Historical BLOCKED_AUTOMATION_INPUT; physical checks below supersede the physical-acceptance blocker. The tool limitation persists. |
| Physical equals in ASCII | Repeated physical `=` presses | User reported repeated equals input works; exact count was not supplied. | PASS_USER_REPORTED, bounded to the user's observation; no unbounded-input claim. |
| Physical equals in Chinese | Physical `=` then Space; independently repeat that pair three times | User confirmed `=` and then `===`, with no spaces between equals; panel closed and underline cleared. | PASS_USER_REPORTED for individual and repeated committed insertion. |
| Input recovery | Return, fresh `nihao`, then Space after the symbol checks | Final synthetic line contained one `你好` | PASS field result; no claim of panel/underline inspection. |

Candidate-panel closure and underline for this punctuation step were not independently readable through Computer Use. The user subsequently confirmed closure and underline clearing, including both Chinese physical-equals cases. The background process remained running and the final source/mode query returned Hans / `nascii`; this finite check does not prove universal crash freedom or measured latency.

In Chinese mode, the user also reported that directly repeating `=` leaves only one equals. The deployed binding maps `equal` to `Page_Down` when `has_menu`, explaining why pending symbol selection differs from repeated committed insertion. These results preserve the inherited key contract; they do not authorize a change or prove that a code operator such as `==` survives uninterrupted Chinese-mode typing. [Follow-up evidence](evidence/notes-format-input-acceptance.json) records the user-operated equals checks separately from automation.

### Guided email, URL and code-style result

**12 literal-preservation checks PASS; 2 FAIL_LITERAL_PRESERVATION.** Seven synthetic payloads were entered by actual key events in each mode, with field observations before and after Return. Only titles/case markers were pasted into two new test notes. No email was sent, no URL opened and no code executed. The matrix tests literal preservation, not exhaustive email/URL grammar or automatic context detection.

| Typed payload | Chinese mode observed text | ASCII mode observed text | Literal-preservation result |
| --- | --- | --- | --- |
| `user@example.com` | `user@example.com` | Unchanged | PASS in both modes |
| `user_01-test@example.com` | `user——01-test@example.com` | Unchanged | Chinese FAIL; ASCII PASS |
| `user+tag@example.com` | `user+tag@example.com` | Unchanged | PASS in both modes, for this sequence only |
| `https://example.com/path-01` | Unchanged | Unchanged | PASS in both modes |
| `www.example.com/path_01` | Unchanged | Unchanged | PASS in both modes |
| `example.com/path_01` | Unchanged | Unchanged | PASS in both modes |
| `call_fn(12+3);` | `擦了路——愤怒（12+3）；` | Unchanged | Chinese FAIL; ASCII PASS |

Notes auto-linked ASCII-mode emails/URLs after Return. CUA represented them as Markdown-like links; their visible labels and pre-Return text matched the payloads. The [structured evidence](evidence/notes-format-input-acceptance.json) retains both representations instead of treating link formatting as text corruption.

Open issue **R0-UAT-001**: the underscore in the structured email becomes the configured Chinese dash before the completed email token is protected. This causal explanation is a source-based inference; internal execution was not instrumented. Open issue **R0-UAT-002**: explicit Chinese mode interprets the code-like fragments as pinyin and converts punctuation. Both fail literal preservation and pass the corresponding ASCII control. Neither issue was fixed in this step; no new mode or recognizer contract was approved.

The plus-alias email passed even though plus is outside the deployed email regex's local-part character set. This single observed path does not establish full alias support. Equality-containing operators, quoted code strings and broader address grammars remain untested.

After the matrix, the starting Chinese mode was restored; fresh `nihao` plus Space produced one `你好`. Independent checks confirmed Hans / `nascii` and the running installed process. Candidate closure/underline for this format-input step still requires user visual confirmation. Xcode and Terminal have not been tested for these payloads. Stop for confirmation; do not begin another case or a later round automatically.

### Pending special-character and environment coverage

The user explicitly requested this coverage. The bounded Notes punctuation matrix and physical-equals follow-up are complete; the email/URL/code matrix exposes two unresolved literal-preservation issues. Visual confirmation for the format-input step is pending. All extended coverage in Xcode and Terminal remains NOT_RUN, with Terminal automation blocked by tool policy. Remaining Notes cases below require separate step authorization:

- Other symbol choices; punctuation during active pinyin composition and arbitrary repeated/interleaved symbol sequences. Record intentional full-width/half-width conversion and configured paging behavior rather than assuming every difference is a bug.
- Broader email/URL/code input, including case changes, equality-containing operators, quotes and additional grammars; the seven payloads above do not establish blanket coverage. Keep R0-UAT-001/002 open until an authorized fix or explicit mode-contract decision is verified.
- Chinese/Latin mixed segments, spaces, repeated punctuation and editing with Backspace/Delete/arrows/Tab; verify host text and composition boundaries.
- Non-ASCII input such as emoji, accented text and full-width characters through available entry methods. Distinguish typed events from paste/Character Viewer; neither path proves the other.
- Return in each composition state, including no matching candidate and after digit selection/cancellation; keypad Enter is a separate untested key path.

Use only synthetic fixtures. Do not enter test strings as executable Terminal commands; use the read fixture below. Record per-host expected behavior, observed text, composition/panel closure and PASS/FAIL separately. These tests validate the inherited Round 0 input behavior, not translation or automatic context detection.

The vertical Chinese-only candidate panel is the current baseline. The user approved a future horizontal layout with each primary candidate above its corresponding opposite-language subtitle. Layout implementation belongs to Round 1, and real translated subtitles to Round 2; neither is started here.

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
