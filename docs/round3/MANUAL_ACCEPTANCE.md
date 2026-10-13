# Round 3 — Guided installation and actual input acceptance

Status: **NOT_RUN**. No 0.0.7 package is installed by this increment. The old
0.0.4 was already removed under the completed one-time exception in `323d902`.
0.0.6 is a retained historical artifact. Do not install it before immediately
replacing it with this round's artifact. Confirm the intended version first.

Use one checkpoint at a time and wait for the user's confirmation. Computer
Use does not override the no-deletion policy. Terminal automation was previously
denied and must not be retried through another injection path. Physical Shift
tests require the user's keyboard; modifier-only Computer Use is unsupported.
Never use real passwords, private notes, secrets or personal messages as fixtures.

## Installation checkpoints

1. Confirm the system Simplified Pinyin/ABC source is selected and usable. Check
   that `~/Library/Input Methods/EcholME.app` is absent and no EcholME process
   runs. If a target exists, stop; do not replace/delete/move it automatically.
2. Verify the exact 0.0.7 artifact listed in [DELIVERY.md](DELIVERY.md), then use
   `python3 -B tools/round0.py install-first --bundle <artifact-path>` only after explicit
   installation confirmation. Compare installed version/signature/file hashes.
   Stop here for confirmation.
3. Register using the installed app's `--register-input-source` command, then separately add
   两仪 in System Settings > Keyboard > Text Input. Verify enabled/selected
   states independently; an OSStatus 0 alone is not proof of selection. A stale
   input-source cache may require user logout/login. Stop for confirmation.
4. Create one dedicated synthetic Notes note and select 两仪. Verify activation
   and the menu/HUD. Record app/version, source, intended mode and exact synthetic
   result. Do not export unrelated Notes titles/content. Stop for confirmation.

## Input checkpoints (each NOT_RUN)

| ID | Action | Expected result / evidence |
| --- | --- | --- |
| R3-01 | Choose Chinese; type `nihao`; Space. Then repeat with Return and Esc. | Space gives `你好`; Return gives raw `nihao` without newline; Esc cancels and later input recovers. Preserve panel/underline observations separately. |
| R3-02 | Chinese `zhongguo`, select the number shown for `中国`. | Exactly the chosen candidate, no duplicate. Candidate panel closes. |
| R3-03 | Choose English before typing `hello`. Exercise Return, Space, Option+Return separately. | Raw `hello`; `hello `; ready displayed `你好`, respectively. Missing/pending subtitle cannot commit a translation. |
| R3-04 | User physically taps left Shift then right Shift separately; test both while empty and with `nihao`/`hello` pending. Add Shift+A, long hold and overlapping Shifts. | Existing Round 1/0.0.6 key contract; no random toggle, duplicate/lost text or stuck modifier. Neither automated tests nor screenshots replace this result. |
| R3-05 | Select the current explicit language while composing, then the other language. | Same selection preserves pending text; different selection finalizes raw once and changes mode. |
| R3-06 | With Chinese or English composition pending, choose Off; type `hello===`, Return, Tab and shortcuts. | Pending raw text once; later keys belong to host, no candidates/subtitles. Choose Auto/explicit mode to resume. |
| R3-07 | In synthetic fields containing `这是中文测试` and `Please continue writing`, leave an empty caret at the end, reactivate input source and wait briefly in Auto. | Corresponding Chinese/English primary direction if the host exposes bounded AX range access; otherwise record fallback/capability limit, not a false detection pass. |
| R3-08 | Select Auto immediately before typing; exercise slow/missing AX, focus switches and a new Notes field. | Live composition remains stable; late own-preedit evidence cannot turn the next Chinese word into English; no prior field text inserted in another field. |
| R3-09 | Test no AX permission, blank/short/mixed samples, search field and synthetic code literal. | Normal input continues. Blank/ambiguous text follows published rules/defaults. Search metadata stays neutral. Code hint cannot override an explicit Chinese choice. No permission prompt. |
| R3-10 | In settings save an exact app rule, remove it, enable learning intentionally, make repeated choices, then clear learning. Test invalid ID. | Rules survive reopening; explicit manual choice outranks rule; rules outrank learned fallback. Invalid input preserves saved values. Learning is off initially and reset preserves explicit rules. |
| R3-11 | Use a dedicated synthetic secure field or Secure Event Input. Never type real credentials. | No candidate/translation or ordinary context-text reading; explicit modes cannot bypass known safety. OS may bypass the IME entirely: record NOT_APPLICABLE for that route, not an IME safety pass. |
| R3-12 | Recheck email/URL/code and repeated equals in explicit English; observe explicit Chinese separately. | Judge literal preservation only against the explicit English contract. Pinyin/punctuation behavior in explicit Chinese is not automatically a defect. |
| R3-13 | Open settings/About/licenses; inspect HUD near screen edges on each display and while typing. | Readable controls/notices; HUD nonactivating, fades near 0.8 seconds, no stuck panel/focus theft. Missing caret geometry may use pointer fallback. |
| R3-14 | Repeat applicable cases in Xcode and Terminal using authorized surfaces/manual keyboard. | Record host-specific outcomes and capability failures. No assertion of universal host support or latency without measurement. |

## Recording results

Use PASS, FAIL, BLOCKED, NOT_RUN or NOT_APPLICABLE for each case and distinguish
user physical reports, Computer Use evidence, backend tests and measured timing.
Visible subtitle latency must include the event-to-render interval, not just
dictionary lookup. A first launch can rebuild Rime data inside LiangYi roots;
ordinary confined engine maintenance is authorized. No cleanup of user data,
Squirrel data, failed artifacts or logs is authorized by this guide.

Stop after this round's acceptance/report. Round 4 and pushing need new explicit
authorization; no automatic continuation is configured.
