# Round 1 key and commit contract

Recorded: 2026-10-11, America/New_York.

The user authorized Round 1 and selected **Option+Return** for translated
commit. This contract covers deterministic examples, not a real translation
backend. Space/digits retain the Chinese engine's schema semantics; ASCII
token composition is separate from Chinese pinyin.

| Key | Chinese composition | English token composition | Empty composition |
| --- | --- | --- | --- |
| Space | Confirm current engine candidate; no literal space. Engine may continue a partially selected composition. | Commit raw token plus one literal space, once. | Pass to host. |
| Digits | Engine selection labels on the visible page; recognizer/symbol codes retain engine meaning. | Append digits to the token, never choose by numeric label. | Retain mode/engine behavior. |
| Return / keypad Enter | Commit raw input, not a candidate; no newline. Includes no-candidate compositions. | Commit raw token; no newline. | Pass to host (newline, form submit, etc.). |
| Escape | Cancel input/marked text/panel and invalidate examples. | Same. | Delegate to engine/host, retaining inherited Vim handling. |
| Option+Return | Commit the highlighted **ready** example only when its full commit preview equals the candidate text. Otherwise consume without insertion. | Commit the ready highlighted example; otherwise consume without insertion. | Pass to host. |
| Tab | Finalize raw composition once, then pass Tab. | Same. | Pass to host. |
| Command shortcuts | Finalize raw composition, invalidate callbacks, then pass shortcut. | Same. | Pass to host. |
| Backspace | Delegate to engine; update snapshot. | Remove last token character; empty token clears marked text/panel. | Pass to host/engine. |
| Arrows | Retain engine navigation. | Finalize raw token then pass to host. | Pass to host/engine. |
| Punctuation / non-token input | Retain schema mappings/recognizers. | Finalize raw token, then pass the original key; never translate it automatically. | Retain mode/host handling. |

ASCII tokens start with A–Z/a–z and continue with letters/digits. This avoids
swallowing punctuation or candidate-selection digits in emails/code. A token
has a finite length limit; crossing it finalizes raw input before passing the
next key. Two ordinary Returns are needed for a composed token followed by a
host newline; this matches the Chinese raw-Return contract. Option+Return
does not append a newline or space.

Left Shift tapped alone within 0.5 seconds finalizes the current raw composition
once, clears engine state and switches Chinese/English in either direction.
A repeated flagsChanged event while that Shift key remains down does not cancel
the tap. The menu bar shows 中文 or 英文, and the candidate footer names the
current primary language.
The 0.0.6 repair also retains a known Shift side when a flags event has key code
zero, cancels ambiguous two-Shift changes, and reconciles held state from the
next typed key after an omitted release. If neither a key code nor a device
side is available at the initial press, the inherited left-side default applies.
The input-source menu exposes **中文主输入 / Chinese** and **英文主输入 / English**.
An explicit change finalizes raw input once with the same focus/revision guard
as a left tap. Selecting the current language preserves the pending composition.
The CLI follows that same guarded selection path; it does not automatically
activate an unfocused controller. Installed UI acceptance remains separate.
For example, Chinese `nihao`, Left Shift, English `a`, Return produces `nihaoa`
through two ordered inserts (`nihao`, `a`), with no implicit space or newline.
Right Shift alone within the same window retains the schema binding: the
baseline's `commit_text` confirms the Chinese candidate and enters ASCII mode;
frontend English is finalized raw before replaying a confirmed right tap.
`nihao`, Right Shift, `a`, Return therefore produces `你好a` in that baseline.
Either Shift used with a typed key, another modifier, the other Shift or a
long hold must not toggle mode. Orphan/duplicate releases and releases from a
previous focus/mode boundary cannot manufacture a tap. The frontend owns both
physical Shift gesture streams; Rime receives a right press/release pair only
after it has been verified as a tap, retaining the current Caps Lock mask.
An engine-side inline ASCII composition with a live prefix remains entirely
engine-owned until it finishes; it cannot start a second English buffer.
A CLI mode change or the example toggle finalizes the
old raw composition once and invalidates callbacks before changing mode.
Example Off keeps Chinese input, hides example subtitles, and restores direct
ASCII passthrough. Auto direction/HUD/configuration are later rounds.

Focus deactivation finalizes raw input into the bound old client once, then
invalidates the session. A changed client encountered without deactivation
discards old state rather than sending old text to the new client. Clearing
the engine before translated commit prevents subsequent deactivation from
appending the original pinyin/token. A failed host insertion is never retried
automatically; it must not fall through and insert twice.

Keyboard primary selection and mouse selection must validate the displayed
candidate identity. Mouse release cannot select a row from a different
snapshot than mouse down. Example refresh keeps candidate IDs, page and
highlight; it never activates the panel. Mouse hover has an outline, while
the filled highlight remains the keyboard selection used by Space/Option+Return.
Engine comments remain distinct from
examples. Chinese segment candidates whose full composition preview is not
known are display-only examples and cannot commit a translation. The engine
selection must cover the whole preedit, its preview must equal the primary,
and that ready value must belong to the currently displayed controller/panel.

No-candidate/pending/missing/stale examples do not turn Option+Return into raw
insertion. Real dictionary quality/coverage and context/cloud policies belong
to Round 2 and later. Explicit Chinese conversion is not an ASCII-literal
failure criterion.

## Round 2 addendum (2026-10-12)

The same Option+Return rule now commits a ready local-dictionary subtitle.
The input-menu control is labeled **Local translations**. Turning it off still
hides subtitles and restores direct ASCII passthrough; its state remains per
controller. A dictionary miss displays `—`. A lookup timeout or unavailable
index displays `!` and is not cached as a miss. Pending remains `…`. The
one-word English composer is unchanged: Space commits the token plus one
space, so multiword phrases are counted and stored but are not composed in
this round. An exact spaced primary can resolve a stored phrase if one is
presented as a whole candidate. Engine comments remain separate from
subtitles.
