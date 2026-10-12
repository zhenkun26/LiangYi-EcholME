#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright 2026 EcholME contributors.
"""Run isolated Round 1 core/host/layout checks using existing Apple tools.

Always use a fresh output directory. No cleanup, network, installation, input
source selection or actual IMK client access occurs. Without --engine-bundle,
there is no Rime database access.
The rendered previews use the same geometry and renderer as SquirrelView.

Optional --engine-bundle runs the real engine probe after static verification.
It also links the production Swift Shift router to that engine and a synthetic
host to exercise complete modifier/typing/mode-transition sequences.
It performs authorized librime generation/database maintenance only in fresh
LiangYi/Validation/<run-id> data/log roots. Existing user dictionaries are not
used. No cleanup is performed; a reused run ID fails before initialization.
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


def execute(command: list[str], target: Path, name: str, timeout: int = 120) -> subprocess.CompletedProcess:
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
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,99}", args.run_id):
        parser.error("Run ID must contain letters, digits, dots, dashes, or underscores")
    target = round0.ARTIFACTS / "tests" / args.run_id
    try:
        if round0.present(target):
            raise round0.BuildError(f"Test output exists and was preserved; choose a new run ID: {target}")
        round0.directory(target)
        execute(["/usr/bin/xcrun", "swiftc", "-warnings-as-errors", "-swift-version", "5",
                 "-target", "arm64-apple-macos14.0", "-module-cache-path", str(target / "ModuleCache"),
                 "sources/CompositionState.swift", "sources/ExampleTranslation.swift",
                 "sources/BilingualCandidateLayout.swift", "tests/Round1Checks.swift",
                 "-o", str(target / "core-checks")], target, "core-compile")
        core = execute([str(target / "core-checks"), str(target / "preview")], target, "core-result", 20)
        execute(["/usr/bin/xcrun", "clang", "-fobjc-arc", "-Wall", "-Wextra", "-Werror",
                 "-Wno-unused-parameter", "-mmacosx-version-min=14.0", "-I", "sources",
                 "sources/SafeIMEClient.m", "tests/SafeIMEClientChecks.m", "-framework", "AppKit",
                 "-framework", "InputMethodKit", "-o", str(target / "host-checks")], target, "host-compile")
        host = execute([str(target / "host-checks")], target, "host-result", 20)
        execute([sys.executable, "-B", "tools/check_round0.py"], target, "tool-guards", 20)
        engine = None
        shifts = None
        if args.engine_bundle:
            bundle = args.engine_bundle.expanduser().absolute()
            round0.verify_bundle(bundle)
            frameworks = bundle / "Contents/Frameworks"
            execute(["/usr/bin/xcrun", "clang", "-std=c11", "-Wall", "-Wextra", "-Wpedantic", "-Werror",
                     "-arch", "arm64", "-mmacosx-version-min=14.0", "-I", str(round0.ARTIFACTS / "headers/librime/src"),
                     "-DECHOLME_SHIFT_REGRESSIONS", "-c", "tools/RimeSmoke.c",
                     "-o", str(target / "engine-probe.o")], target, "engine-probe-compile")
            execute(["/usr/bin/xcrun", "swiftc", "-warnings-as-errors", "-swift-version", "5", "-parse-as-library",
                     "-target", "arm64-apple-macos14.0", "-module-cache-path", str(target / "ModuleCache"),
                     "-I", str(round0.ARTIFACTS / "headers/librime/src"),
                     "-I", str(round0.ARTIFACTS / "headers/librime/include"),
                     "-import-objc-header", "tests/ShiftRegressionBridge.h",
                     "sources/CompositionState.swift", "sources/BridgingFunctions.swift", "sources/MacOSKeyCodes.swift",
                     "tests/ShiftRegressionChecks.swift", str(target / "engine-probe.o"), str(frameworks / "librime.1.dylib"),
                     "-Xlinker", "-rpath", "-Xlinker", str(frameworks),
                     "-o", str(target / "engine-checks")], target, "engine-routing-compile")
            result = execute([str(target / "engine-checks"), str(bundle / "Contents/SharedSupport"), args.run_id],
                             target, "engine-result", 120)
            engine = json.loads(result.stdout)
            prefix = "ECHOLME_SHIFT_RESULT "
            records = [line[len(prefix):] for line in result.stderr.splitlines() if line.startswith(prefix)]
            if len(records) != 1:
                raise round0.BuildError("Expected one Shift regression report; inspect engine-result.txt")
            shifts = json.loads(records[0])
            if shifts.get("status") != "PASS" or shifts.get("check_count") != engine.get("shift_regression_checks"):
                raise round0.BuildError("Shift regression status/count mismatch")
            round0.create_or_match(target / "shift-routing.json", (json.dumps(shifts, indent=2) + "\n").encode())
        report = {"status": "PASS", "core": json.loads(core.stdout), "host_wrapper": json.loads(host.stdout),
                  "tool_guards": "PASS (12 mocked guards)", "output": str(target),
                  "real_engine": engine if engine else "NOT_RUN",
                  "shift_routing": shifts if shifts else "NOT_RUN (requires --engine-bundle)",
                  "runtime_input": "NOT_RUN", "installed_bundle_modified": False,
                  "rime_validation_data_accessed": bool(engine), "network_requests": False}
        round0.create_or_match(target / "verification.json", (json.dumps(report, indent=2) + "\n").encode())
        print(json.dumps({"status": report["status"], "core_checks": report["core"]["check_count"],
                          "host_checks": report["host_wrapper"]["check_count"], "tool_guards": report["tool_guards"],
                          "engine_status": engine["status"] if engine else "NOT_RUN",
                          "shift_routing_checks": shifts["check_count"] if shifts else "NOT_RUN",
                          "output": str(target), "runtime_input": "NOT_RUN"}, indent=2))
        return 0
    except (round0.BuildError, subprocess.TimeoutExpired, OSError, ValueError) as error:
        print(f"FAIL: {error}; outputs preserved at {target}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
