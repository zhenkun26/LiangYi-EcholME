#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright 2026 EcholME contributors.
"""Verify the Round 2 lexicon and the Round 1 regressions.

Always uses a fresh output directory. No cleanup, installation, network, or
input-source selection. Optional --engine-bundle repeats the real librime
checks in a fresh LiangYi validation directory.
"""
from __future__ import annotations

import argparse
import datetime
import json
from pathlib import Path
import re
import subprocess
import sys

sys.dont_write_bytecode = True
import round0


def execute(command: list[str], target: Path, name: str, timeout: int = 180) -> subprocess.CompletedProcess:
    round0.create_or_match(target / (name + "-command.json"), (json.dumps(command, indent=2) + "\n").encode())
    result = subprocess.run(command, cwd=round0.ROOT, capture_output=True, text=True, timeout=timeout)
    round0.create_or_match(target / (name + ".txt"), (result.stdout + result.stderr).encode())
    if result.returncode:
        raise round0.BuildError(f"{name} failed ({result.returncode}); inspect {target / (name + '.txt')}")
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-id", default=datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S%fZ"))
    parser.add_argument("--engine-bundle", type=Path)
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,80}", args.run_id):
        parser.error("Run ID must contain letters, digits, dots, dashes, or underscores")
    target = round0.ARTIFACTS / "tests" / args.run_id
    try:
        if round0.present(target):
            raise round0.BuildError(f"Test output exists and was preserved; choose a new run ID: {target}")
        round0.directory(target)
        lexicon = execute([sys.executable, "-B", "tools/build_lexicon.py"], target, "lexicon-check", 60)
        execute(["/usr/bin/xcrun", "swiftc", "-warnings-as-errors", "-swift-version", "5",
                 "-target", "arm64-apple-macos14.0", "-module-cache-path", str(target / "ModuleCache"),
                 "sources/CompositionState.swift", "sources/LocalLexicon.swift", "tests/Round2Checks.swift",
                 "-o", str(target / "round2-checks")], target, "round2-compile")
        runtime = execute([str(target / "round2-checks"), "data/lexicon/echolme-lexicon.idx",
                           "data/lexicon/evaluation-corpus.json", "data/lexicon/manifest.json"],
                          target, "round2-result", 60)
        report = json.loads(runtime.stdout)
        if report.get("status") != "PASS":
            raise round0.BuildError("Round 2 runtime report was not PASS")
        round1_id = args.run_id + "-r1"
        command = [sys.executable, "-B", "tools/check_round1.py", "--run-id", round1_id]
        if args.engine_bundle:
            command.extend(["--engine-bundle", str(args.engine_bundle)])
        execute(command, target, "round1-regression", 180)
        summary = {
            "status": "PASS",
            "lexicon": json.loads(lexicon.stdout),
            "runtime": report,
            "round1_run": round1_id,
            "engine_bundle": str(args.engine_bundle) if args.engine_bundle else "NOT_RUN",
            "visible_panel_latency": "NOT_RUN",
            "installed_bundle_modified": False,
        }
        round0.create_or_match(target / "verification.json", (json.dumps(summary, indent=2) + "\n").encode())
        print(json.dumps({"status": "PASS", "checks": report["check_count"], "cold_load_ms": report["cold_load_ms"],
                          "lookup_p50_ms": report["lookup_p50_ms"], "lookup_p95_ms": report["lookup_p95_ms"],
                          "lookup_max_ms": report["lookup_max_ms"], "english_headwords": report["english_headwords"],
                          "english_phrases": report["english_phrases"], "output": str(target)}, indent=2))
        return 0
    except (round0.BuildError, subprocess.TimeoutExpired, OSError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL: {error}; outputs preserved at {target}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
