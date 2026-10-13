# Round 2 — Offline bidirectional dictionary

Recorded: 2026-10-12, America/New_York.

Closeout: **DELIVERED_WITH_VERIFICATION_LIMITS; INSTALLED_ACCEPTANCE_PENDING**.
Sections 1–5 retain the historical 0.0.4 delivery baseline; Section 6 records
the retained 0.0.6 switching repair. The user subsequently authorized checking
this closeout and advancing Round 3. That advances source work without making
pending installed/physical acceptance a pass. Section 7 records the current
boundary. No installation, push, or release is authorized by this closeout.

## 1. Objective

Replace fixture subtitles with a licensed local dictionary. Chinese pinyin
candidates show an English subtitle. English tokens show a Chinese subtitle.
Primary text and the displayed subtitle commit through the existing
coordinator. Misses, cancellation, reordered results, and timeouts must not
commit the wrong text or block ordinary input.

## 2. Dictionary and license

| Item | Value |
| --- | --- |
| Source | MDBG CC-CEDICT, `data/lexicon/upstream/cedict_1_0_ts_utf-8_mdbg.txt.gz` |
| Header date | 2026-10-11T08:29:27Z |
| Header entries | 125,262, all parsed |
| Grant | Creative Commons Attribution-ShareAlike 4.0 International License, quoted in the file header and `data/lexicon/NOTICE.txt` |
| Gzip SHA-256 | `cf0bf5c8ff94316799bc82755dbe0627658d7167244060d8e4ce8d5928a6b9f5` |
| Uncompressed SHA-256 | `39758f408b1a8c180c8e6b772bde9ae2ffab1794119e65bc0a42f3fc9163e9eb` |
| Derived index | `data/lexicon/echolme-lexicon.idx` |
| Index SHA-256 | `0fe2133f351bcd320cb05eb3d50483d9daeed1c7852a6791c96dcbfbac6c07bc` |

The index is CC-BY-SA-4.0 data. It is not relicensed under GPL-3.0-only.
Project source that reads it remains GPL-3.0-only. No new code dependency was
added. English tie-breaking uses `data/plum/essay.txt` from the already
vendored rime-essay package. Those scores are applied while building the index
and are not read on the key path.

Counts from `data/lexicon/manifest.json`:

| Count | Value |
| --- | --- |
| Simplified keys | 115,355 |
| Single-character Chinese entries | 9,739 |
| Multi-character Chinese entries | 105,616 |
| English headwords | 33,030 |
| English phrases | 59,616 |
| Chinese keys with more than one source entry | 3,131 |
| English headwords with more than one Chinese candidate before ranking | 15,563 |

Chinese-to-English and English-to-Chinese are built by different rules. The
frozen corpus records both `中文` → `Chinese` and `chinese` → `中国人`, and
both `时间` → `time` and `time` → `时候`. Those pairs are the evidence that
one direction is not inferred by reversing the other.

Selection rules:

- A Chinese subtitle is the first plain English word, otherwise a short phrase,
  otherwise a truncated gloss. Archaic, slang, dialect, and bound-form labels
  lose to a plain sense.
- An English headword keeps the earlier CC-CEDICT gloss. The essay score then
  picks among equally prominent senses. Semicolons are synonyms. Commas inside
  a definition are not extra headwords.
- Phrases are two to four words and live in a separate table. The one-word
  English composer still commits on Space, so it does not assemble those
  phrases. A candidate whose whole primary contains a space can resolve one.
- Regular plurals and `-ing`/`-ed` forms fall back only when that surface word
  is not itself a headword. `studies` stays `学业` because it is an exact entry.
  `cats` falls back to `cat`.

The frozen corpus is `data/lexicon/evaluation-corpus.json`: 32 Chinese rows,
32 English rows, 3 phrases, and misses in both directions. Exact match against
it is PASS. That locks the policy. It is not a professional translation rating.
One displayed sense is the text Option+Return will commit.

Reviewed policy results that are real dictionary senses, not the only possible
sense: `input` → `投放` while `输入` displays `import`; `eat` → `食用`;
`time` → `时候`; `phone` → `致电`; `chinese` → `中国人`.

## 3. Runtime behavior

`LocalLexicon` loads the index off the key path. Until it is ready, a subtitle
stays pending and then becomes `!` if the 150 ms lookup budget expires. That
failure is not stored as “this word has no translation.” After the index is
ready, the same composition can be looked up again. Cancellation and an older
request cannot overwrite a newer one. Option+Return still requires the ready
subtitle, the current candidate identity, and a preview equal to the whole
primary. A partial candidate may show a subtitle and cannot commit it. Engine
comments stay separate. The host adapter and commit coordinator are unchanged.

The 0.0.4 input menu item is **Local translations**. Turning that control off
hides subtitles and restores ASCII passthrough for that controller. It is not
the complete product Off mode introduced in the separate Round 3 contract.

## 4. Build and verification

Environment: Apple M4, 16 GiB, macOS 26.5 (25F71), Xcode 26.6, arm64, deployment
target 14.0. This is not macOS 14 or Intel runtime evidence.

```sh
python3 -B tools/build_lexicon.py
python3 -B tools/check_round2.py --engine-bundle \
  .artifacts/builds/round2-lexicon-20261012c/DerivedData/Build/Products/Debug/EcholME.app
python3 -B tools/round0.py build --configuration Debug --build-id round2-lexicon-20261012c
```

Final artifact:

```text
.artifacts/builds/round2-lexicon-20261012c/DerivedData/Build/Products/Debug/EcholME.app
```

Version **0.0.4**. Static identity, resources, links, and ad-hoc signature
PASS. The bundled index and NOTICE match the source files. Compiler/linker
warnings: none. One inherited AppIntents metadata extraction warning remains.

| Check | Result |
| --- | --- |
| Pinned CC-CEDICT rebuild matches the committed index and manifest | PASS |
| Dictionary, corpus, cache, timeout, cancellation, morphology, and commit checks | 136 PASS |
| Round 1 core / host / tool guards | 60 / 22 / 12 PASS |
| Real librime and Shift router on the 0.0.4 bundle, synthetic host | PASS, including 57 Shift checks |
| In-process cold index load | 474.8 ms, once, off the key path |
| Warm lookup, 1,300 calls | min 0.0003 ms, P50 0.0010 ms, P95 0.0021 ms, max 0.048 ms |
| Visible panel latency from input change to a drawn subtitle | NOT_RUN |
| Installed 0.0.4 TextEdit input | PASS for Chinese Space, Option+Return, raw Return, and English hello/echolme. Notes, Xcode, Terminal, and the visible panel remain NOT_RUN. See [manual acceptance](MANUAL_ACCEPTANCE.md). |
| macOS 14, Intel, running Squirrel coexistence | NOT_RUN |
| Push, release, notarization | NOT_AUTHORIZED |

At the original code delivery the installed app was **0.0.1**. The later
user-assisted installation moved it to **0.0.4**, as recorded in manual
acceptance. That 0.0.4 app was subsequently moved to Trash under the user's
completed one-time exception, recorded in `323d902`. There is currently no
installed bundle. Version 0.0.6 remains a retained artifact and was not installed.

## 5. Limits and next gate

Translation failure does not block primary input. The 150 ms product limit is
defined from the input change to the first visible valid subtitle. Only the
in-process lookup portion was measured. Do not read the sub-millisecond lookup
numbers as that end-to-end result.

At the Round 2 baseline, English phrase composition, context detection, cloud
providers, and the full Off mode were deferred. Context and product Off belong
to the separately authorized Round 3. English phrase composition and cloud
providers remain outside this closeout. Traditional-Chinese candidates are
not a separate index. Irregular inflections such as `went`/`go` are not stemmed.

The original next gate was installation and acceptance of 0.0.4. The current
repair evidence is in Section 6. The superseding source-work authorization
and still-pending installation/acceptance boundary are in Section 7.

## 6. Primary-language switching repair — 0.0.6

The user reported that a left Shift tap sometimes failed on installed 0.0.4.
The 0.0.5 repeated-flags patch (`992d5ea`) was present in source but not
installed. A new regression demonstrated a remaining failure when a repeated
modifier event has key code zero. The controller previously inferred from
aggregate changes, discarding that repeat and misidentifying anonymous right
releases. This is a reproduced source defect, not proof of the exact physical
event sequence from the user's report.

Version 0.0.6 keeps raw modifier events until the gesture tracker can use
device bits and held-side history. Typed keys reconcile an omitted release
without generating a tap. Ambiguous overlaps are consumed without toggling.
Existing short-tap, long-hold, capitalization, raw/candidate commit, and
focus/revision protections remain covered. Explicit input-source menu items
select Chinese or English using guarded raw finalization. Reselecting the
current language leaves pending text intact. Activation shows the same
Chinese/English labels, and inactive controllers no longer answer mode queries.

Changed modules: `CompositionState.swift`, `SquirrelInputController.swift`,
the two Shift/core test suites, Xcode version, and the bilingual guide/status
records. No new code dependency or dictionary data was introduced. Existing
GPL and data licenses remain preserved; external corresponding-source review
remains a release gate.

Verification: **75 core checks, 22 host-wrapper checks, 12 tool guards,
69 production-router/real-librime checks, 60 original engine checks, and
136 dictionary checks PASS**. The red regression and complete reports remain
in `.artifacts/tests/shift-handoff-red-20261012` and
`.artifacts/tests/shift-handoff-006-checks-20261012{,-r1}`. They test the shared
production routing with synthetic hosts; they do not instantiate an installed
IMK controller. Build/static identity/resource/link/signature results and
matching tested-source hashes are in [the follow-up evidence](evidence/primary-language-repair.json).

Final artifact:

```text
.artifacts/builds/shift-handoff-006-final-20261012/DerivedData/Build/Products/Debug/EcholME.app
```

Computer Use created the dedicated Notes fixture `EcholME Shift acceptance
2026-10-12`. Its standalone `Shift_L` request was rejected because the tool
requires a non-modifier key; this did not establish an app failure or pass.
No alternate event injection was used. Physical Shift validation, new menu
clicks, repaired installation, and `hello`/Chinese handoffs are **NOT_RUN**.
No screenshot of unrelated notes is retained.

The old **0.0.4** app was removed under the user's explicit one-time exception
and the recorded path/process/source checks passed (`323d902`). The former
**BLOCKED_EXISTING_TARGET** state is no longer current. The repaired artifact
is **NOT_INSTALLED**, and physical/menu/installed IMK checks remain **NOT_RUN**.
Complete a separately confirmed installation checkpoint and physical-key cases
before calling the reported issue resolved in actual use.

## 7. Closeout and Round 3 boundary — 2026-10-12

The user requested checking Round 2 closeout and advancing Round 3. Round 2
closes with its documented automated/build evidence and runtime limitations.
The source contract, license provenance, local dictionary, timeout/cancellation
behavior, and switching repair remain the implementation baseline. Neither
the removed 0.0.4 installation nor the uninstalled 0.0.6 artifact establishes
physical Shift recovery or acceptance of the final source in Notes, Xcode,
and Terminal. Visible-panel latency remains **NOT_RUN**.

Current recorded system state: no `~/Library/Input Methods/EcholME.app`, no
EcholME process, and system Simplified Pinyin selected. The removal comparison
preserved all 236 regular LiangYi data files and 7 log files by content digest.
Trash was not emptied. That one-time removal authorization is completed and
cannot be reused.

Round 3 may implement bounded local context, rules, manual modes, HUD, settings,
and the license entry point; see its [delivery record](../round3/DELIVERY.md).
This source increment does not install 0.0.6 or a newer artifact. Installation
and the retained [manual acceptance](MANUAL_ACCEPTANCE.md) need a separate
confirmed checkpoint. Stop before Round 4 and keep commits local. GPL notices
and dictionary attribution remain mandatory; external distribution and its
complete corresponding-source review are still separate release gates.
