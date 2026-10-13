#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright 2026 EcholME contributors.
"""Synthetic context/persistence checks plus existing offline/engine regressions.

Fresh retained outputs only. No live AX reads, prompts, input-source changes,
installation, cleanup, or network. Optional engine validation has the same
confined LiangYi data/log maintenance as check_round2.py.
"""
from __future__ import annotations

import argparse
import datetime
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

sys.dont_write_bytecode = True
import round0
from check_round2 import execute


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-id", default=datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S%fZ"))
    parser.add_argument("--engine-bundle", type=Path)
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,65}", args.run_id):
        parser.error("Use a short, unique alphanumeric run ID")
    target = round0.ARTIFACTS / "tests" / args.run_id
    try:
        if round0.present(target):
            raise round0.BuildError("Existing output preserved; use a new run ID")
        round0.directory(target)
        common = ["sources/CompositionState.swift", "sources/ContextPolicy.swift"]
        reports = {}
        for name, files in [
            ("policy", common + ["tests/Round3Checks.swift"]),
            ("capture-settings", common + ["sources/ContextCapture.swift", "sources/ContextSettingsWindow.swift",
                                            "tests/ContextCaptureChecks.swift"]),
            ("context-async", common + ["sources/ContextCapture.swift", "tests/ContextAsyncChecks.swift"]),
        ]:
            execute(["/usr/bin/xcrun", "swiftc", "-warnings-as-errors", "-swift-version", "5",
                     "-target", "arm64-apple-macos14.0", "-module-cache-path", str(target / "ModuleCache"),
                     *files, "-o", str(target / name)], target, name + "-compile")
            result = execute([str(target / name)], target, name + "-result", 30)
            reports[name] = json.loads(result.stdout)
            if reports[name].get("status") != "PASS":
                raise round0.BuildError(name + " did not pass")
        execute(["/usr/bin/xcrun", "swiftc", "-warnings-as-errors", "-swift-version", "5",
                 "-target", "arm64-apple-macos14.0", "-module-cache-path", str(target / "ModuleCache"),
                 *common, "sources/ContextSettingsWindow.swift", "tools/ContextSettingsPreview.swift",
                 "-o", str(target / "settings-preview")], target, "settings-preview-compile")
        preview = execute([str(target / "settings-preview"), str(target / "settings.png")],
                          target, "settings-preview-result", 30)
        command = [sys.executable, "-B", "tools/check_round2.py", "--run-id", args.run_id + "-r2"]
        if args.engine_bundle:
            command.extend(["--engine-bundle", str(args.engine_bundle)])
        execute(command, target, "round2-regression", 300)
        inputs = sorted(path for folder in ("sources", "tests", "tools")
                        for path in (round0.ROOT / folder).glob("*") if path.is_file())
        inputs.append(round0.ROOT / "Squirrel.xcodeproj/project.pbxproj")
        hashes = {str(path.relative_to(round0.ROOT)): hashlib.sha256(path.read_bytes()).hexdigest() for path in inputs}
        summary = {"status": "PASS", "reports": reports, "round2_run": args.run_id + "-r2",
                   "settings_preview": json.loads(preview.stdout),
                   "source_sha256": hashes, "live_context_read": False, "preferences_written": False,
                   "installed_bundle_modified": False, "installed_IMK_acceptance": "NOT_RUN",
                   "HUD_visual_acceptance": "NOT_RUN"}
        round0.create_or_match(target / "verification.json", (json.dumps(summary, indent=2) + "\n").encode())
        print(json.dumps({"status": "PASS", "checks": {key: value["check_count"] for key, value in reports.items()},
                          "output": str(target)}, indent=2))
        return 0
    except (round0.BuildError, subprocess.TimeoutExpired, OSError, ValueError) as error:
        print(f"FAIL: {error}; outputs preserved at {target}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
