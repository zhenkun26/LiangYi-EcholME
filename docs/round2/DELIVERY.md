# Round 2 — Offline bidirectional dictionary

Recorded: 2026-10-12, America/New_York.

Delivery: **IMPLEMENTED_AND_BUILT_WITH_RUNTIME_ACCEPTANCE_PENDING**.
Round 2 is authorized. Stop before Round 3. No push, release, or replacement
of the installed 0.0.1 bundle was performed.

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

The input menu item is now **Local translations**. Off still hides subtitles
and restores ASCII passthrough for that controller.

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

The installed app is still version **0.0.1**. The installer was not run.

## 5. Limits and next gate

Translation failure does not block primary input. The 150 ms product limit is
defined from the input change to the first visible valid subtitle. Only the
in-process lookup portion was measured. Do not read the sub-millisecond lookup
numbers as that end-to-end result.

English phrase composition, context detection, cloud providers, and the full
Off mode remain later rounds. Traditional-Chinese candidates are not a separate
index. Irregular inflections such as `went`/`go` are not stemmed.

Install and accept the 0.0.4 bundle with the user before calling input behavior
passed. Stop before Round 3.
