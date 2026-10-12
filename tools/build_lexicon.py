#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright 2026 EcholME contributors.
"""Build and verify the offline CC-CEDICT lexicon index.

The indexed data remains CC-BY-SA-4.0. This script is project code and does
not relicense the dictionary. It does not download, delete, or install.
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "data/lexicon/upstream/cedict_1_0_ts_utf-8_mdbg.txt.gz"
ESSAY = ROOT / "data/plum/essay.txt"
INDEX = ROOT / "data/lexicon/echolme-lexicon.idx"
MANIFEST = ROOT / "data/lexicon/manifest.json"
CORPUS = ROOT / "data/lexicon/evaluation-corpus.json"

# Pinned MDBG export inspected on 2026-10-12. Updating the dictionary is a
# deliberate provenance change, not a silent rebuild.
EXPECTED_GZIP_SHA256 = "cf0bf5c8ff94316799bc82755dbe0627658d7167244060d8e4ce8d5928a6b9f5"
EXPECTED_TEXT_SHA256 = "39758f408b1a8c180c8e6b772bde9ae2ffab1794119e65bc0a42f3fc9163e9eb"
EXPECTED_DATE = "2026-10-11T08:29:27Z"
EXPECTED_ENTRIES = 125262

SKIP = re.compile(
    r"^(?:surname\b|variant of\b|old variant of\b|see also\b|see\b|CL:|abbr\.|abbr\b|abbreviation\b)",
    re.IGNORECASE,
)
USAGE = re.compile(
    r"^\((?:archaic|literary|coll\.|colloquial|slang|loanword|old|dialect|tw|taiwan|prc|"
    r"cantonese|classical|formal|fig\.|figurative|derog\.|internet|computing|neologism|bound form)\)",
    re.IGNORECASE,
)
PAREN = re.compile(r"\([^()]*\)")
TOKEN = re.compile(r"^[a-z]+(?:[-'][a-z]+)*$")
ENTRY = re.compile(r"^(\S+) (\S+) \[([^\[\]]+)\] /(.*)/$")
HEADER = re.compile(r"^#!\s+([^=]+)=(.*)$")
MAX_SUBTITLE = 48


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


def clean(text: str) -> str:
    value = text.strip()
    while True:
        updated = PAREN.sub("", value)
        if updated == value:
            break
        value = updated
    value = value.replace("\t", " ").replace("\r", " ").replace("\n", " ")
    value = re.sub(r"\s+", " ", value).strip(" ;,./")
    return value


def surface(piece: str) -> str:
    text = piece.strip(" ;,./!?")
    if text.lower().startswith("to "):
        text = text[3:].strip(" ;,./!?")
    if len(text) > MAX_SUBTITLE:
        text = text[: MAX_SUBTITLE - 1].rstrip() + "…"
    return text


def classify(text: str) -> tuple[str, str] | None:
    shown = surface(text)
    token = shown.strip(" -'").lower()
    if not token:
        return None
    if TOKEN.fullmatch(token):
        if len(token) == 1 and token not in {"a", "i"}:
            return None
        return ("word", token)
    parts = token.split(" ")
    if 2 <= len(parts) <= 4 and all(TOKEN.fullmatch(part) and len(part) >= 2 for part in parts):
        return ("phrase", " ".join(parts))
    return None


def gloss_marks(raw: str) -> tuple[bool, bool]:
    strong = bool(USAGE.match(raw))
    mild = "(" in raw and not strong
    return strong, mild


def candidates(gloss: str, slash_index: int) -> list[dict]:
    raw = gloss.strip()
    if not raw or SKIP.match(raw):
        return []
    strong, mild = gloss_marks(raw)
    text = clean(raw)
    if not text or SKIP.match(text):
        return []
    found: list[dict] = []
    # Semicolons separate synonyms. Commas belong to definitions and must not
    # become extra headwords ("earth, water, fire" is not three translations).
    for semi_index, piece in enumerate(re.split(r";", text)):
        item = classify(piece)
        if item is None:
            continue
        found.append({
            "kind": item[0],
            "key": item[1],
            "text": surface(piece),
            "strong": strong,
            "mild": mild,
            "slash": slash_index,
            "semi": semi_index,
        })
    name = re.sub(r"\(.*", "", raw.split(" ", 1)[0]).strip(" ;,./")
    if name[:1].isupper():
        named = classify(name)
        if named is not None and named[0] == "word" and named[1] not in {item["key"] for item in found}:
            found.append({
                "kind": "word",
                "key": named[1],
                "text": surface(name),
                "strong": strong,
                "mild": mild,
                "slash": slash_index,
                "semi": 0,
            })
    if found:
        return found
    return [{
        "kind": "description",
        "key": "",
        "text": surface(text),
        "strong": strong,
        "mild": mild,
        "slash": slash_index,
        "semi": 0,
    }]


def subtitle_rank(item: dict) -> tuple:
    kind_rank = {"word": 0, "phrase": 1, "description": 2}[item["kind"]]
    return (kind_rank, int(item["strong"]), item["slash"], item["semi"], int(item["mild"]), item["line"])


def word_rank(item: dict) -> tuple:
    # Slash order keeps a buried gloss from outranking a head sense. Frequency
    # then chooses among equally prominent senses. Semicolon pieces are one sense.
    return (int(item["strong"]), item["slash"], -item["freq"], item["length"], item["line"])


def phrase_rank(item: dict) -> tuple:
    return (int(item["strong"]), -item["freq"], item["slash"], item["length"], item["line"])


def load_source() -> tuple[bytes, str, dict[str, str]]:
    if not SOURCE.is_file():
        fail(f"missing pinned dictionary: {SOURCE}")
    compressed = SOURCE.read_bytes()
    gzip_sha = hashlib.sha256(compressed).hexdigest()
    if gzip_sha != EXPECTED_GZIP_SHA256:
        fail("gzip checksum does not match the pinned CC-CEDICT export")
    text = gzip.decompress(compressed)
    text_sha = hashlib.sha256(text).hexdigest()
    if text_sha != EXPECTED_TEXT_SHA256:
        fail("uncompressed checksum does not match the pinned CC-CEDICT export")
    header: dict[str, str] = {}
    for raw in text.decode("utf-8").splitlines():
        if raw.startswith("#!"):
            match = HEADER.match(raw)
            if match:
                header[match.group(1).strip()] = match.group(2).strip()
        elif raw and not raw.startswith("#"):
            break
    if header.get("license") != "https://creativecommons.org/licenses/by-sa/4.0/":
        fail("CC-CEDICT license header is not CC-BY-SA-4.0")
    if header.get("date") != EXPECTED_DATE or header.get("entries") != str(EXPECTED_ENTRIES):
        fail("CC-CEDICT date or entry count header changed")
    if "Creative Commons Attribution-ShareAlike 4.0 International License" not in text.decode("utf-8").split("#!", 1)[0]:
        fail("CC-CEDICT grant wording is not present in the file header")
    return text, text_sha, header


def load_essay() -> dict[str, int]:
    if not ESSAY.is_file():
        fail(f"missing vendored frequency list: {ESSAY}")
    scores: dict[str, int] = {}
    for line in ESSAY.read_text(encoding="utf-8").splitlines():
        word, separator, score = line.partition("\t")
        if not separator or not word:
            continue
        try:
            value = int(score)
        except ValueError:
            fail("rime essay row is not a word and an integer score")
        scores[word] = value
    if len(scores) < 100000:
        fail("rime essay frequency list is unexpectedly small")
    return scores


def build(text: bytes) -> dict:
    essay = load_essay()
    chinese: dict[str, str] = {}
    chinese_rank: dict[str, tuple] = {}
    chinese_lines: dict[str, int] = {}
    words: dict[str, tuple] = {}
    word_text: dict[str, str] = {}
    phrases: dict[str, tuple] = {}
    phrase_text: dict[str, str] = {}
    word_alts: dict[str, set[str]] = {}
    parsed = 0
    for line_no, raw in enumerate(text.decode("utf-8").splitlines(), start=1):
        if not raw or raw.startswith("#"):
            continue
        match = ENTRY.match(raw)
        if match is None:
            fail(f"unparsed CC-CEDICT line {line_no}")
        traditional = match.group(1)
        simplified = match.group(2)
        glosses = [item for item in match.group(4).split("/") if item]
        if not simplified or "\t" in simplified or "\n" in simplified or not glosses:
            fail(f"unsafe dictionary headword at line {line_no}")
        parsed += 1
        chinese_lines[simplified] = chinese_lines.get(simplified, 0) + 1
        frequency = max(essay.get(simplified, 0), essay.get(traditional, 0))
        for slash_index, gloss in enumerate(glosses):
            for item in candidates(gloss, slash_index):
                item["line"] = line_no
                item["length"] = len(simplified)
                item["freq"] = frequency
                if item["kind"] != "description":
                    rank = subtitle_rank(item)
                    current = chinese_rank.get(simplified)
                    if current is None or rank < current:
                        chinese_rank[simplified] = rank
                        chinese[simplified] = item["text"]
                if item["kind"] == "description":
                    continue
                target_rank = phrases if item["kind"] == "phrase" else words
                target_text = phrase_text if item["kind"] == "phrase" else word_text
                rank = phrase_rank(item) if item["kind"] == "phrase" else word_rank(item)
                current = target_rank.get(item["key"])
                if current is None or rank < current:
                    target_rank[item["key"]] = rank
                    target_text[item["key"]] = simplified
                if item["kind"] == "word":
                    word_alts.setdefault(item["key"], set()).add(simplified)
    if parsed != EXPECTED_ENTRIES:
        fail(f"parsed {parsed} entries, header declares {EXPECTED_ENTRIES}")
    # A simplified entry whose only glosses were skipped still needs a fallback
    # description when no word or phrase was eligible.
    if len(chinese) != len(chinese_lines):
        for line_no, raw in enumerate(text.decode("utf-8").splitlines(), start=1):
            if not raw or raw.startswith("#"):
                continue
            match = ENTRY.match(raw)
            if match is None:
                continue
            simplified = match.group(2)
            if simplified in chinese:
                continue
            for slash_index, gloss in enumerate([item for item in match.group(4).split("/") if item]):
                for item in candidates(gloss, slash_index):
                    if item["kind"] != "description":
                        continue
                    item["line"] = line_no
                    rank = subtitle_rank(item)
                    current = chinese_rank.get(simplified)
                    if current is None or rank < current:
                        chinese_rank[simplified] = rank
                        chinese[simplified] = item["text"]
    single = sum(1 for key in chinese if len(key) == 1)
    return {
        "chinese": chinese,
        "english": word_text,
        "phrases": phrase_text,
        "chinese_single_character": single,
        "chinese_multicharacter": len(chinese) - single,
        "chinese_polysemous_keys": sum(1 for count in chinese_lines.values() if count > 1),
        "english_polysemous_headwords": sum(1 for alts in word_alts.values() if len(alts) > 1),
        "parsed_entries": parsed,
    }


def render(revision: str, lexicon: dict) -> bytes:
    def section(tag: str, items: dict[str, str]) -> list[str]:
        lines = [f"{tag}\t{len(items)}"]
        for key in sorted(items, key=lambda item: item.encode("utf-8")):
            value = items[key]
            if not key or not value or "\t" in key or "\t" in value or "\n" in key or "\n" in value:
                fail(f"unsafe index record in {tag}")
            lines.append(f"{key}\t{value}")
        return lines

    lines = ["LYLX1", revision]
    lines.extend(section("ZH", lexicon["chinese"]))
    lines.extend(section("EN", lexicon["english"]))
    lines.extend(section("PH", lexicon["phrases"]))
    return ("\n".join(lines) + "\n").encode("utf-8")


def manifest_for(revision: str, index: bytes, lexicon: dict, essay_sha: str) -> bytes:
    payload = {
        "format": 1,
        "ruleset": 1,
        "source": {
            "name": "CC-CEDICT",
            "publisher": "MDBG",
            "license": "CC-BY-SA-4.0",
            "grant": "Creative Commons Attribution-ShareAlike 4.0 International License",
            "url": "https://www.mdbg.net/chinese/export/cedict/cedict_1_0_ts_utf-8_mdbg.txt.gz",
            "date": EXPECTED_DATE,
            "header_entries": EXPECTED_ENTRIES,
            "sha256_gzip": EXPECTED_GZIP_SHA256,
            "sha256_uncompressed": revision,
        },
        "selection": {
            "chinese_to_english": "One subtitle: an unqualified English word, else a short phrase, else a truncated gloss. Archaic, slang, dialect, and similar labels lose to a plain sense. Not reused as the English index.",
            "english_to_chinese": "Separate headword index. A labeled archaic or slang sense loses. Otherwise the earlier CC-CEDICT gloss wins, and the vendored rime-essay score breaks remaining ties. This is not a reversal of the Chinese subtitle table.",
            "english_phrases": "Two-to-four-word glosses, stored separately. The same frequency prior applies. The one-word English composer does not look them up.",
            "frequency_prior": "data/plum/essay.txt from the already vendored rime-essay package. Scores are baked into the index and are not read on the key path.",
            "skipped_glosses": "surname, variant, see, classifier, and abbreviation glosses",
        },
        "frequency_prior_sha256": essay_sha,
        "counts": {
            "parsed_entries": lexicon["parsed_entries"],
            "chinese_simplified_keys": len(lexicon["chinese"]),
            "chinese_single_character": lexicon["chinese_single_character"],
            "chinese_multicharacter": lexicon["chinese_multicharacter"],
            "chinese_polysemous_keys": lexicon["chinese_polysemous_keys"],
            "english_headwords": len(lexicon["english"]),
            "english_phrases": len(lexicon["phrases"]),
            "english_polysemous_headwords": lexicon["english_polysemous_headwords"],
        },
        "index_sha256": hashlib.sha256(index).hexdigest(),
    }
    return (json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode("utf-8")


def asymmetries(lexicon: dict) -> tuple[int, int]:
    forward = 0
    for chinese, english in lexicon["chinese"].items():
        key = english.lower()
        if " " in key:
            back = lexicon["phrases"].get(key)
        else:
            back = lexicon["english"].get(key)
        if back is not None and back != chinese:
            forward += 1
    reverse = 0
    for english, chinese in lexicon["english"].items():
        back = lexicon["chinese"].get(chinese)
        if back is not None and back.lower() != english:
            reverse += 1
    return forward, reverse


def check_corpus(lexicon: dict) -> dict:
    if not CORPUS.is_file():
        fail(f"missing frozen corpus: {CORPUS}")
    corpus = json.loads(CORPUS.read_text())
    counts = {"chinese_to_english": 0, "english_to_chinese": 0, "phrases": 0, "misses": 0}
    for item in corpus["chinese_to_english"]:
        if lexicon["chinese"].get(item["primary"]) != item["subtitle"]:
            fail(f"Chinese corpus mismatch: {item['primary']}")
        counts["chinese_to_english"] += 1
    for item in corpus["english_to_chinese"]:
        if lexicon["english"].get(item["primary"].lower()) != item["subtitle"]:
            fail(f"English corpus mismatch: {item['primary']}")
        counts["english_to_chinese"] += 1
    for item in corpus["english_phrases"]:
        if lexicon["phrases"].get(item["phrase"]) != item["subtitle"]:
            fail(f"Phrase corpus mismatch: {item['phrase']}")
        counts["phrases"] += 1
    for word in corpus["chinese_misses"]:
        if word in lexicon["chinese"]:
            fail(f"Chinese miss is present: {word}")
        counts["misses"] += 1
    for word in corpus["english_misses"]:
        if word.lower() in lexicon["english"]:
            fail(f"English miss is present: {word}")
        counts["misses"] += 1
    if counts["chinese_to_english"] < 30 or counts["english_to_chinese"] < 30:
        fail("frozen directional corpora are too small")
    return counts


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="write the index and manifest")
    parser.add_argument("--query", action="append", default=[], help="print one simplified or English lookup")
    args = parser.parse_args()
    text, revision, _header = load_source()
    essay_sha = hashlib.sha256(ESSAY.read_bytes()).hexdigest()
    lexicon = build(text)
    index = render(revision, lexicon)
    manifest = manifest_for(revision, index, lexicon, essay_sha)
    forward, reverse = asymmetries(lexicon)
    counts = json.loads(manifest.decode())["counts"]
    if counts["english_headwords"] < 2000:
        fail("fewer than 2000 English headwords")
    if counts["english_phrases"] < 1 or counts["chinese_multicharacter"] < 1 or counts["chinese_single_character"] < 1:
        fail("phrase and character counts were not separated")
    if forward < 1 or reverse < 1:
        fail("one direction collapsed into a reversal of the other")
    if args.query:
        for query in args.query:
            key = query.lower()
            print(json.dumps({
                "query": query,
                "chinese": lexicon["chinese"].get(query),
                "english": lexicon["english"].get(key),
                "phrase": lexicon["phrases"].get(key),
            }, ensure_ascii=False))
        return 0
    report = {
        "status": "PASS",
        "counts": counts,
        "asymmetry": {"chinese_subtitle_not_reverse": forward, "english_headword_not_reverse": reverse},
        "index_sha256": hashlib.sha256(index).hexdigest(),
    }
    if args.write:
        INDEX.write_bytes(index)
        MANIFEST.write_bytes(manifest)
        report["wrote"] = True
    else:
        if INDEX.read_bytes() != index or MANIFEST.read_bytes() != manifest:
            fail("committed index or manifest does not match the pinned source and rules")
        report["corpus"] = check_corpus(lexicon)
        report["committed_index"] = "MATCH"
    print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
