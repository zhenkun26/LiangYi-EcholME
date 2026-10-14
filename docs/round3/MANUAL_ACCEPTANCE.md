# Round 3 — Guided installation and actual input acceptance

Status: **0.0.8_INSTALLED; REPAIRED_INPUT_ACCEPTANCE_PENDING**, updated
2026-10-14, America/New_York. The user subsequently requested installing 0.0.8
and pushing, then explicitly authorized a public project repository and an
open-source reference record. Audited absent-target installation and static
verification pass; all 86 installed hashes match. Registration/selection and
real input remain separate checkpoints. See [installation evidence](evidence/installed-008.json).
Round 4, integration merge and binary release remain outside this task.

The earlier installed 0.0.7 was moved to Trash through Finder
under a new explicit one-time user authorization. At that removal checkpoint,
the installation path was absent, no EcholME process was found afterward, and
all 309 data files and 3 logs retained their inventory/content digests. No Trash emptying. This exception
and the earlier one in `323d902` are consumed; 0.0.6 was never installed.
The existing physical results below describe 0.0.7 before removal. Stop before
entering Round 4 at that historical checkpoint. The later authorization above
supersedes its installation/push wait. See [removal record](evidence/removal-007.json).

The earlier conditional Round 4 authorization requires the complete executable
Round 3 matrix, not only `nihao`. Round 4 has not started. The current task
authorizes 0.0.8 installation and public source publication only; later
installed acceptance continues one checkpoint at a time.

## Live checkpoint ledger

| Check | Status | Evidence and limit |
| --- | --- | --- |
| Authorized 0.0.8 installation | PASS, static only | Audited absent-target copy, version 0.0.8, 86 artifact file hashes, resources/linkage and strict signature. Registration/selection/typed input NOT_RUN by this installation step. |
| Authorized 0.0.7 removal | PASS, historical | Verified exact bundle/version/hash manifest; normal quit followed by Finder Move to Trash. At that checkpoint: original path absent, no process in two checks, data/log inventories unchanged, 0.0.8 not yet installed. |
| Absent-target 0.0.7 installation | PASS | Reviewed `install-first`; installed version/signature/resources/link paths pass; all 86 file hashes match delivery. No deletion or replacement. |
| Registration and System Settings addition | PASS | Register OSStatus 0 plus visible 两仪 entry; independent TIS check confirms Hans enabled/selectable and Hant disabled. Original globe-key emoji behavior restored after Settings changed it automatically. |
| Notes activation | PASS, bounded | Dedicated `EcholME 0.0.7 — Round 3 验收` note; Hans selected; installed executable path/PID and version checked; `--getascii` responded `nascii`. Initial selection had no process/reply; later activation succeeded. HUD timing is NOT_RUN. |
| Chinese `nihao` panel/subtitle | PASS, user physical report | User observed horizontal two-line candidates, `你好`, and its English subtitle. Exact gloss spelling and visible latency not independently measured. |
| Chinese Space commit | PASS, user physical report | One `你好`; candidate window and underline disappeared. |
| Chinese Return / Esc recovery / numeric choice | PASS, user physical report | Raw `nihao` without extra newline; Esc cancellation followed by successful `你好`; displayed numeric choice committed `中国`; closure confirmed. |
| English `hello` Return / Space / Option+Return | PASS, user physical report | Explicit English selected; raw word, word plus one space, and ready displayed `你好` respectively; no appended `hello` with translation; closure confirmed. |
| Physical left/right Shift, empty and composing | PASS, user physical report | Each side switched empty Chinese/English three round trips. Chinese `nihao` + left Shift + `a` + Return gave `nihaoa`; right Shift gave `你好a`; no failure, loss or duplication reported. |
| Shift handoff/chord/hold/overlap | PASS, user physical report | English `hello` + left Shift + Chinese `nihao` + Space gave `hello你好`; Shift+A preserved English and upper case; approximately one-second hold and overlapping left/right Shift did not toggle. |
| Same/different explicit mode while composing | PASS, user physical report | Re-selecting Chinese or English preserved that composition; switching language committed raw `nihao` or `hello` once. No independent menu/deactivation timing trace. |
| Product Off | PASS, user physical report | Pending raw input committed once; later `hello===` and Return behaved as ordinary literal text/newline without candidates; Chinese restored. Tab/shortcut behavior still NOT_RUN. |
| Automated letter-input control | BLOCKED_AUTOMATION_PATH | CU `pressKey` letters yielded plain `nihao` and Notes correction despite Hans/nascii. Physical behavior differed. No alternate event-injection path used. Later single-note AX reads did not corroborate the physical edits, so no automatic text-result pass is claimed. |
| IME Accessibility permission | PASS, observation only | Computer Use inspected System Settings > Privacy & Security > Accessibility: EcholME.app toggle was off. No toggle or prompt was triggered. This is distinct from Codex/probe permission and does not establish fallback behavior in Auto. |
| Open Input Context settings | PASS, user report; BLOCKED for automated inspection | User opened EcholME — Input Context. Computer Use selecting the installed app by its exact path repeatedly timed out; the metadata-only probe could not retrieve the focused element. Opening is confirmed by the user, but settings edits and validation are NOT_RUN. |
| Real nearby-text detection | BLOCKED_PERMISSION | IME Accessibility permission is off. Synthetic classifier tests do not verify live host range access. No permission change was made. |
| Remaining matrix | NOT_RUN unless updated below | Rule editing/learning, Auto fallback, sensitive-field recovery, HUD geometry/timing, Off Tab/shortcuts and cross-host coverage remain separate. |

Source review identified a transient Secure Event Input recovery issue and a
metadata-only focus race. A separate 0.0.8 repair now passes automated checks
and builds; see [delivery](DELIVERY.md) and [repair evidence](evidence/secure-input-recovery-008.json).
This does not explain the CU letter-path observation. The removed 0.0.7 results
remain separate from repaired 0.0.8 installed input acceptance, which is NOT_RUN.
Never rerun the installer over the existing 0.0.8 target. The structured 0.0.7 record is
[installed-acceptance-007.json](evidence/installed-acceptance-007.json).

Use one checkpoint at a time and wait for the user's confirmation. Computer
Use does not override the no-deletion policy. Terminal automation was previously
denied and must not be retried through another injection path. Physical Shift
tests require the user's keyboard; modifier-only Computer Use is unsupported.
Never use real passwords, private notes, secrets or personal messages as fixtures.

## Installation checkpoints

1. Confirm the system Simplified Pinyin/ABC source is selected and usable. Check
   that `~/Library/Input Methods/EcholME.app` is absent and no EcholME process
   runs. If a target exists, stop; do not replace/delete/move it automatically.
2. Verify the exact 0.0.8 artifact listed in [DELIVERY.md](DELIVERY.md), then use
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

## Input checkpoint specification (results are in the ledger above)

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
| R3-11b, 0.0.8 only | In an explicitly authorized synthetic fixture, enable then release temporary Secure Event Input. Exercise Auto/explicit modes, Off, and a field change during recovery. | Global protection does not persist as AX secure evidence. Pending metadata keeps literal input and no translation; a stable supported field recovers, denied/unsupported/timeout follows fallback. Stale metadata stays protected until field/source reactivation. Known secure fields remain protected. No automatic live fixture or OS security change was performed. |
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

Complete the executable matrix and record unavailable checks before advancing
to the conditionally authorized Round 4. Source pushing to the expressly named
public repository is authorized; Round 5 and binary release are not.
No scheduled continuation is configured.
