#!/usr/bin/env python3
"""Exercise critical Round 0 guards without preparing, building, or installing.

Run with: python3 -B tools/check_round0.py

Archive fixtures are BytesIO objects. Filesystem mutation, subprocess execution,
and network access are denied by mocks. No temporary directories or cleanup
operations are used. These tests do not validate a real application bundle.
"""

from __future__ import annotations

import sys

sys.dont_write_bytecode = True

import copy
import io
import os
from pathlib import Path
import plistlib
import tarfile
import types
import unittest
from unittest.mock import patch


TOOLS = Path(__file__).resolve().parent
SOURCE = TOOLS / "round0.py"
round0 = types.ModuleType("round0_under_test")
round0.__file__ = str(SOURCE)
# Do not import through a loader that could create __pycache__ artifacts.
exec(compile(SOURCE.read_text(), str(SOURCE), "exec"), round0.__dict__)


def archive_fixture(name: str, kind: str = "file", link: str = "") -> bytes:
    output = io.BytesIO()
    with tarfile.open(fileobj=output, mode="w") as archive:
        member = tarfile.TarInfo(name)
        if kind == "file":
            member.size = 1
            archive.addfile(member, io.BytesIO(b"x"))
        else:
            member.type = tarfile.SYMTYPE if kind == "symlink" else tarfile.LNKTYPE
            member.linkname = link
            archive.addfile(member)
    return output.getvalue()


class ReadOnlyTestCase(unittest.TestCase):
    def setUp(self) -> None:
        # These guards fail a test if a future refactor unexpectedly adds a
        # side effect. Stopping a patch restores Python state only.
        guards = [
            patch.object(round0.subprocess, "run", side_effect=AssertionError("Subprocess execution forbidden")),
            patch.object(round0.urllib.request, "urlopen", side_effect=AssertionError("Network access forbidden")),
            patch.object(round0.shutil, "copytree", side_effect=AssertionError("Filesystem copy forbidden")),
        ]
        for name in ("mkdir", "chmod", "symlink_to", "unlink", "rmdir", "rename", "replace"):
            guards.append(patch.object(Path, name, side_effect=AssertionError("Filesystem mutation forbidden")))
        for name in ("remove", "unlink", "rmdir", "rename", "replace", "symlink"):
            guards.append(patch.object(os, name, side_effect=AssertionError("Filesystem mutation forbidden")))
        for guard in guards:
            guard.start()
            self.addCleanup(guard.stop)


class ArchiveGuardTests(ReadOnlyTestCase):
    def assert_archive_rejected(self, name: str, kind: str = "file", link: str = "") -> None:
        payload = archive_fixture(name, kind, link)
        specification = {"id": "guard-test", "sha256": "a" * 64}
        with patch.object(round0, "directory"), \
                patch.object(round0, "checked_fetch", return_value=payload), \
                patch.object(round0, "create_or_match") as writer:
            with self.assertRaises(round0.BuildError):
                round0.unpack_selected(specification, ("dist/",))
            writer.assert_not_called()

    def test_parent_traversal_is_rejected(self) -> None:
        self.assert_archive_rejected("dist/../escape")

    def test_absolute_archive_path_is_rejected(self) -> None:
        self.assert_archive_rejected("/escape")

    def test_symlink_outside_extraction_root_is_rejected(self) -> None:
        self.assert_archive_rejected("dist/link", "symlink", "../../../escape")

    def test_archive_hardlink_is_rejected(self) -> None:
        self.assert_archive_rejected("dist/link", "hardlink", "dist/file")


class DestinationGuardTests(ReadOnlyTestCase):
    def test_symlink_parent_is_rejected_before_mkdir(self) -> None:
        with patch.object(Path, "is_symlink", lambda path: str(path) == "/guard/link"), \
                patch.object(Path, "mkdir") as mkdir:
            with self.assertRaises(round0.BuildError):
                round0.directory(Path("/guard/link/child"))
            mkdir.assert_not_called()

    def test_existing_install_target_is_not_copied_or_replaced(self) -> None:
        with patch.object(round0, "verify_bundle", return_value={"result": "PASS"}), \
                patch.object(round0, "present", return_value=True), \
                patch.object(round0.shutil, "copytree") as copier:
            with self.assertRaises(round0.BuildError):
                round0.install_first(Path("/guard/EcholME.app"))
            copier.assert_not_called()


class IdentityGuardTests(ReadOnlyTestCase):
    def fixture(self) -> dict:
        info = plistlib.loads((TOOLS.parent / "resources/Info.plist").read_bytes())
        # Resolve only the two normal build substitutions. All IMK/TIS values
        # remain the actual checked-in product identity under test.
        info["CFBundleIdentifier"] = round0.BUNDLE_ID
        info["CFBundleExecutable"] = "EcholME"
        return info

    def test_current_product_identity_is_accepted(self) -> None:
        round0.verify_identity(self.fixture())

    def test_inherited_or_wrong_top_level_identity_is_rejected(self) -> None:
        mutations = {
            "TISInputSourceID": "im.rime.inputmethod.Squirrel",
            "InputMethodConnectionName": "Squirrel_Connection",
            "InputMethodServerControllerClass": "Wrong.Module",
            "InputMethodServerDelegateClass": "Wrong.Module",
        }
        for key, value in mutations.items():
            with self.subTest(key=key):
                info = copy.deepcopy(self.fixture())
                info[key] = value
                with self.assertRaises(round0.BuildError):
                    round0.verify_identity(info)

    def test_inherited_input_mode_identity_is_rejected(self) -> None:
        for change_key in (False, True):
            with self.subTest(change_dictionary_key=change_key):
                info = copy.deepcopy(self.fixture())
                modes = info["ComponentInputModeDict"]["tsInputModeListKey"]
                expected = round0.BUNDLE_ID + ".Hans"
                inherited = "im.rime.inputmethod.Squirrel.Hans"
                if change_key:
                    modes[inherited] = modes.pop(expected)
                else:
                    modes[expected]["TISInputSourceID"] = inherited
                with self.assertRaises(round0.BuildError):
                    round0.verify_identity(info)


    def test_automatic_mode_enablement_is_rejected(self) -> None:
        info = copy.deepcopy(self.fixture())
        modes = info["ComponentInputModeDict"]["tsInputModeListKey"]
        modes[round0.BUNDLE_ID + ".Hans"]["tsInputModeDefaultStateKey"] = True
        with self.assertRaises(round0.BuildError):
            round0.verify_identity(info)


class LinkGuardTests(ReadOnlyTestCase):
    def test_exact_loader_and_executable_rpaths_are_accepted(self) -> None:
        bundle = Path("/guard/EcholME.app")
        executable = bundle / "Contents/MacOS/EcholME"
        loader = bundle / "Contents/Frameworks/helper.dylib"
        for token, expected_parent in (("@loader_path", loader.parent), ("@executable_path", executable.parent)):
            with self.subTest(rpath=token):
                load_commands = (
                    str(loader) + ":\nLoad command 0\n"
                    "          cmd LC_RPATH\n"
                    "      cmdsize 40\n"
                    f"         path {token} (offset 12)\n"
                )
                dependencies = (
                    str(loader) + ":\n"
                    "\t@rpath/same-directory.dylib (compatibility version 1.0.0, current version 1.0.0)\n"
                )
                expected = (expected_parent / "same-directory.dylib").resolve()

                def otool_result(command: list[str]) -> types.SimpleNamespace:
                    self.assertEqual(command[:3], ["/usr/bin/otool", "-arch", "arm64"])
                    return types.SimpleNamespace(stdout=load_commands if "-l" in command else dependencies)

                with patch.object(round0, "run", side_effect=otool_result), \
                        patch.object(Path, "is_file", lambda path: path == expected):
                    round0.verify_link_paths(bundle, loader, executable, [])

    def test_unresolved_rpath_is_rejected(self) -> None:
        bundle = Path("/guard/EcholME.app")
        binary = bundle / "Contents/MacOS/EcholME"
        output = str(binary) + ":\n\t@rpath/missing-library.dylib (compatibility version 1.0.0, current version 1.0.0)\n"
        with patch.object(round0, "macho_load_commands", return_value=(["@executable_path/../Frameworks"], None)), \
                patch.object(round0, "run", return_value=types.SimpleNamespace(stdout=output)), \
                patch.object(Path, "is_file", return_value=False):
            with self.assertRaises(round0.BuildError):
                round0.verify_link_paths(bundle, binary, binary, ["@executable_path/../Frameworks"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
