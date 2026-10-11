#!/usr/bin/env python3
"""Audited Round 0 preparation, build, verification, and first installation.

Uses only Python's standard library and Apple developer tools. No upstream
script, package manager, cleanup operation, or existing-bundle replacement is
executed. Failed outputs remain on disk for inspection. A new build gets a new
directory; dependency conflicts require human inspection rather than cleanup.
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import plistlib
import re
import shutil
import stat
import subprocess
import sys
import tarfile
import urllib.error
import urllib.request


ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / ".artifacts"
BUNDLE_ID = "io.github.zhenkun26.inputmethod.EcholME"
APP_NAME = "EcholME.app"
MACHO_MAGICS = {b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe", b"\xca\xfe\xba\xbe", b"\xca\xfe\xba\xbf"}


class BuildError(RuntimeError):
    pass


def read_json(path: Path) -> dict:
    return json.loads(path.read_text())


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def present(path: Path) -> bool:
    return os.path.lexists(path)


def directory(path: Path) -> None:
    """Refuse symlink traversal, including an existing ancestor."""
    for ancestor in (path, *path.parents):
        if ancestor.is_symlink():
            raise BuildError(f"Refusing symlink directory: {ancestor}")
    path.mkdir(parents=True, exist_ok=True)


def create_or_match(path: Path, data: bytes, executable: bool = False) -> None:
    directory(path.parent)
    if present(path):
        if path.is_symlink() or not path.is_file() or path.read_bytes() != data:
            raise BuildError(f"Existing content differs; preserved without replacement: {path}")
        return
    # Exclusive creation prevents accidentally overwriting unrelated files.
    with path.open("xb") as output:
        output.write(data)
    if executable:
        path.chmod(0o755)


def checked_fetch(spec: dict) -> bytes:
    """Verify the complete response before writing any bytes to a cache file."""
    url = spec["url"]
    if not url.startswith("https://"):
        raise BuildError(f"Non-HTTPS dependency URL: {url}")
    cache = ARTIFACTS / "downloads" / spec["sha256"]
    if present(cache):
        if cache.is_symlink() or not cache.is_file():
            raise BuildError(f"Invalid cache entry: {cache}")
        data = cache.read_bytes()
    else:
        request = urllib.request.Request(url, headers={"User-Agent": "EcholME-Round0"})
        maximum = spec["size"]
        with urllib.request.urlopen(request, timeout=60) as response:
            if not response.url.startswith("https://"):
                raise BuildError("Dependency request redirected outside HTTPS")
            data = response.read(maximum + 1)
        if len(data) != maximum or digest(data) != spec["sha256"]:
            raise BuildError(f"Downloaded size/digest mismatch; no cache was written: {url}")
        create_or_match(cache, data)
    if len(data) != spec["size"] or digest(data) != spec["sha256"]:
        raise BuildError(f"Cached dependency mismatch; preserved for inspection: {cache}")
    return data


def copy_tree_no_replace(source: Path, destination: Path) -> None:
    """Copy a reviewed tree, retaining only internal relative symbolic links."""
    directory(destination)
    for item in sorted(source.iterdir()):
        target = destination / item.name
        if item.is_symlink():
            link = os.readlink(item)
            if Path(link).is_absolute() or not item.resolve().is_relative_to(source.resolve()):
                # Framework links may point to an ancestor of this subdirectory,
                # so validate against the enclosing dependency root instead.
                if Path(link).is_absolute() or not item.resolve().is_relative_to(ARTIFACTS / "dependencies"):
                    raise BuildError(f"Unsafe dependency link: {item}")
            if present(target):
                if not target.is_symlink() or os.readlink(target) != link:
                    raise BuildError(f"Existing link differs: {target}")
            else:
                target.symlink_to(link)
        elif item.is_dir():
            copy_tree_no_replace(item, target)
        elif item.is_file():
            create_or_match(target, item.read_bytes(), bool(item.stat().st_mode & stat.S_IXUSR))
        else:
            raise BuildError(f"Unsupported dependency entry: {item}")


def unpack_selected(spec: dict, prefixes: tuple[str, ...]) -> Path:
    """No tar.extract/extractall: explicitly validate and create each entry."""
    destination = ARTIFACTS / "dependencies" / (spec["id"] + "-" + spec["sha256"][:12])
    directory(destination)
    pending_links = []
    with tarfile.open(fileobj=io.BytesIO(checked_fetch(spec)), mode="r:*") as archive:
        for member in archive.getmembers():
            name = member.name.removeprefix("./").rstrip("/")
            path = PurePosixPath(name)
            if not name or path.is_absolute() or ".." in path.parts:
                raise BuildError(f"Unsafe archive path: {member.name}")
            if not any(name == prefix.rstrip("/") or name.startswith(prefix) for prefix in prefixes):
                continue
            target = destination.joinpath(*path.parts)
            if member.isdir():
                directory(target)
            elif member.isfile():
                stream = archive.extractfile(member)
                if stream is None or member.size > 100_000_000:
                    raise BuildError(f"Invalid archive file: {member.name}")
                create_or_match(target, stream.read(), bool(member.mode & stat.S_IXUSR))
            elif member.issym():
                pending_links.append((target, member.linkname))
            else:
                raise BuildError(f"Unsupported archive entry: {member.name}")
    for target, link in pending_links:
        if Path(link).is_absolute() or not (target.parent / link).resolve().is_relative_to(destination.resolve()):
            raise BuildError(f"Unsafe archive symlink: {target} -> {link}")
        directory(target.parent)
        if present(target):
            if not target.is_symlink() or os.readlink(target) != link:
                raise BuildError(f"Existing link differs: {target}")
        else:
            target.symlink_to(link)
    return destination


def run(command: list[str], *, check: bool = True) -> subprocess.CompletedProcess:
    result = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
    if check and result.returncode:
        raise BuildError(f"Command failed ({result.returncode}): {' '.join(command)}\n{result.stdout}{result.stderr}")
    return result


def doctor() -> None:
    report = {"platform": sys.platform, "python": sys.version.split()[0], "machine": os.uname().machine}
    for name, command in {
        "macos": ["/usr/bin/sw_vers"],
        "xcode": ["/usr/bin/xcodebuild", "-version"],
        "developer_directory": ["/usr/bin/xcode-select", "-p"],
    }.items():
        result = run(command, check=False)
        report[name] = {"exit_code": result.returncode, "output": (result.stdout + result.stderr).strip()}
    report["installation_exists"] = present(Path.home() / "Library/Input Methods" / APP_NAME)
    report["permission_requests"] = "None; this command does not query document contents or prompt for Accessibility"
    print(json.dumps(report, indent=2))


def prepare() -> None:
    lock = read_json(ROOT / "dependencies.lock.json")
    archives = {item["id"]: item for item in lock["archives"]}
    # Only reviewed binaries/data are assembled. Optional plugin binaries remain
    # in the original cached archive and are never loaded by the Round 0 app.
    rime = unpack_selected(archives["rime"], ("dist/lib/librime.1.17.0.dylib", "dist/bin/rime_deployer", "dist/bin/rime_dict_manager"))
    deps = unpack_selected(archives["rime-deps"], ("share/opencc/",))
    create_or_match(ROOT / "lib/librime.1.dylib", (rime / "dist/lib/librime.1.17.0.dylib").read_bytes(), True)
    for tool in ("rime_deployer", "rime_dict_manager"):
        create_or_match(ROOT / "bin" / tool, (rime / "dist/bin" / tool).read_bytes(), True)
    copy_tree_no_replace(deps / "share/opencc", ROOT / "data/opencc")
    for item in lock["headers"]:
        # Avoid initializing the librime gitlink or its build dependencies.
        create_or_match(ARTIFACTS / "headers/librime" / item["path"], checked_fetch(item))
    for package in lock["source_notices"]:
        for item in package["files"]:
            create_or_match(ARTIFACTS / "licenses" / package["repository"] / item["path"], checked_fetch(item))
    manifest = read_json(ROOT / "data/schema-manifest.json")
    for package in manifest["packages"]:
        for item in package["files"]:
            data = checked_fetch(item)
            original = ARTIFACTS / "schema-sources" / package["repository"] / package["commit"] / item["path"]
            create_or_match(original, data)
            if item["path"] in package["runtime_files"]:
                create_or_match(ROOT / "data/plum" / item["path"], data)
            else:
                create_or_match(ARTIFACTS / "licenses" / package["repository"] / item["path"], data)
    inventory = {}
    input_paths = [ROOT / "lib/librime.1.dylib", ROOT / "bin/rime_deployer", ROOT / "bin/rime_dict_manager"]
    for folder in (ROOT / "data/opencc", ROOT / "data/plum", ARTIFACTS / "headers", ARTIFACTS / "licenses"):
        input_paths.extend(path for path in folder.rglob("*") if path.is_file())
    for path in sorted(input_paths):
        if path.is_symlink():
            raise BuildError(f"Prepared input unexpectedly contains a symlink: {path}")
        inventory[str(path.relative_to(ROOT))] = digest(path.read_bytes())
    create_or_match(prepared_inventory_path(), (json.dumps(inventory, indent=2) + "\n").encode())
    print("PASS: pinned build inputs prepared; no deployment, recipe, installation, or application launch occurred.")


def prepared_inventory_path() -> Path:
    fingerprint = digest((ROOT / "dependencies.lock.json").read_bytes() + (ROOT / "data/schema-manifest.json").read_bytes())
    return ARTIFACTS / "prepared" / (fingerprint + ".json")


def check_prepared() -> None:
    required = ["lib/librime.1.dylib", "data/plum/default.yaml", "data/plum/luna_pinyin_simp.schema.yaml", ".artifacts/headers/librime/src/rime/key_table.h"]
    absent = [name for name in required if not (ROOT / name).is_file()]
    if absent:
        raise BuildError("Run prepare before build. Missing: " + ", ".join(absent))
    manifest = prepared_inventory_path()
    if not manifest.is_file():
        raise BuildError("Run prepare for the current dependency and schema manifests before building")
    for path, expected in read_json(manifest).items():
        file = ROOT / path
        if file.is_symlink() or not file.is_file() or digest(file.read_bytes()) != expected:
            raise BuildError(f"Prepared input changed; preserved for inspection: {file}")


def is_macho(path: Path) -> bool:
    if path.is_symlink() or not path.is_file():
        return False
    with path.open("rb") as source:
        return source.read(4) in MACHO_MAGICS


def sign_local_bundle(bundle: Path) -> None:
    # The upstream command line tools have no rpath in their release archive.
    # Only fresh build copies are edited; verified downloaded inputs stay intact.
    for tool in ("rime_deployer", "rime_dict_manager"):
        executable = bundle / "Contents/MacOS" / tool
        run(["/usr/bin/xcrun", "install_name_tool", "-add_rpath", "@loader_path/../Frameworks", str(executable)])
    children = sorted(bundle.rglob("*"), key=lambda path: len(path.parts), reverse=True)
    main_executable = bundle / "Contents/MacOS/EcholME"
    for child in children:
        # codesign recognizes the main executable as its containing bundle;
        # signing it before sibling tools incorrectly seals an unsigned bundle.
        # The final outer-bundle signing operation signs this executable too.
        if child != main_executable and is_macho(child):
            run(["/usr/bin/codesign", "--force", "--sign", "-", "--timestamp=none", str(child)])
    for child in children:
        if not child.is_symlink() and child.is_dir() and child.suffix in (".framework", ".app", ".xpc"):
            run(["/usr/bin/codesign", "--force", "--sign", "-", "--timestamp=none", str(child)])
    run(["/usr/bin/codesign", "--force", "--sign", "-", "--timestamp=none", "--entitlements", str(ROOT / "resources/Squirrel.entitlements"), str(bundle)])


def build(configuration: str, build_id: str | None) -> None:
    check_prepared()
    if build_id is None:
        build_id = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,99}", build_id):
        raise BuildError("Build ID must be a short filename containing letters, digits, dots, dashes, or underscores")
    output = ARTIFACTS / "builds" / build_id
    if present(output):
        raise BuildError(f"Build destination already exists; select a new build ID: {output}")
    directory(output)
    command = ["/usr/bin/xcodebuild", "-project", "Squirrel.xcodeproj", "-scheme", "Squirrel", "-configuration", configuration,
               "-derivedDataPath", str(output / "DerivedData"), "-destination", "generic/platform=macOS",
               "ARCHS=arm64", "ONLY_ACTIVE_ARCH=YES", "MACOSX_DEPLOYMENT_TARGET=14.0", "CODE_SIGNING_ALLOWED=NO",
               "COPY_PHASE_STRIP=NO", "STRIP_INSTALLED_PRODUCT=NO", "COMPILER_INDEX_STORE_ENABLE=NO",
               "REGISTER_APP_WITH_LAUNCH_SERVICES=NO",
               "CLANG_MODULE_CACHE_PATH=" + str(output / "ModuleCache"), "build"]
    create_or_match(output / "command.json", (json.dumps(command, indent=2) + "\n").encode())
    log = output / "xcodebuild.log"
    with log.open("x") as stream:
        result = subprocess.run(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT)
    print(f"Build log: {log}")
    if result.returncode:
        raise BuildError(f"xcodebuild failed ({result.returncode}); outputs preserved at {output}")
    bundle = output / "DerivedData/Build/Products" / configuration / APP_NAME
    if not bundle.is_dir():
        raise BuildError(f"Build did not produce expected bundle: {bundle}")
    copy_tree_no_replace(ARTIFACTS / "licenses", bundle / "Contents/Resources/Licenses")
    for name in ("dependencies.lock.json", "data/schema-manifest.json", "THIRD_PARTY_NOTICES.md"):
        file = ROOT / name
        if file.is_file():
            create_or_match(bundle / "Contents/Resources" / file.name, file.read_bytes())
    sign_local_bundle(bundle)
    report = verify_bundle(bundle)
    contents = log.read_text(errors="replace")
    report["build_warnings"] = [line.strip() for line in contents.splitlines() if "warning:" in line.lower()]
    report["build_errors"] = [line.strip() for line in contents.splitlines() if "error:" in line.lower()]
    report["build_log"] = str(log)
    create_or_match(output / "verification.json", (json.dumps(report, indent=2) + "\n").encode())
    print(json.dumps(report, indent=2))


def verify_identity(info: dict) -> None:
    expected = {
        "CFBundleIdentifier": BUNDLE_ID,
        "CFBundleExecutable": "EcholME",
        "TISInputSourceID": BUNDLE_ID,
        "InputMethodConnectionName": "EcholME_Connection",
        "InputMethodServerControllerClass": "Squirrel.SquirrelInputController",
        # Preserve the inherited IMK delegate convention; changing it is a
        # separate compatibility decision, not part of product renaming.
        "InputMethodServerDelegateClass": "Squirrel.SquirrelInputController",
    }
    for key, value in expected.items():
        if info.get(key) != value:
            raise BuildError(f"Isolated input-method identity mismatch: {key}")
    component = info.get("ComponentInputModeDict")
    if not isinstance(component, dict):
        raise BuildError("Missing ComponentInputModeDict")
    ordered = [BUNDLE_ID + ".Hans", BUNDLE_ID + ".Hant"]
    modes = component.get("tsInputModeListKey")
    if not isinstance(modes, dict) or set(modes) != set(ordered):
        raise BuildError("Input-mode dictionary identifiers do not match EcholME")
    if component.get("tsVisibleInputModeOrderedArrayKey") != ordered:
        raise BuildError("Visible input-mode order does not match EcholME")
    for suffix in ("Hans", "Hant"):
        identifier = BUNDLE_ID + "." + suffix
        mode = modes[identifier]
        if not isinstance(mode, dict) or mode.get("TISInputSourceID") != identifier:
            raise BuildError(f"Input-mode value has an unexpected identity: {identifier}")
        if mode.get("TISIntendedLanguage") != "zh-" + suffix:
            raise BuildError(f"Unexpected input-mode language: {identifier}")
        if mode.get("tsInputModeDefaultStateKey") is not False:
            raise BuildError(f"Input mode must not be enabled by default during registration: {identifier}")


def macho_load_commands(file: Path) -> tuple[list[str], str | None]:
    output = run(["/usr/bin/otool", "-arch", "arm64", "-l", str(file)]).stdout
    rpaths = []
    library_id = None
    for block in re.split(r"\nLoad command \d+\n", output):
        if re.search(r"^\s*cmd LC_RPATH$", block, re.MULTILINE):
            match = re.search(r"^\s*path (.+?) \(offset \d+\)$", block, re.MULTILINE)
            if match:
                rpaths.append(match.group(1))
        if re.search(r"^\s*cmd LC_ID_DYLIB$", block, re.MULTILINE):
            match = re.search(r"^\s*name (.+?) \(offset \d+\)$", block, re.MULTILINE)
            if match:
                library_id = match.group(1)
    return rpaths, library_id


def verify_link_paths(bundle: Path, file: Path, executable: Path, executable_rpaths: list[str]) -> None:
    """Static resolution for this baseline; does not simulate all dyld behavior."""
    rpaths, library_id = macho_load_commands(file)
    lines = run(["/usr/bin/otool", "-arch", "arm64", "-L", str(file)]).stdout.splitlines()[1:]
    dependencies = [line.strip().split(" (", 1)[0] for line in lines if line[:1].isspace()]

    def expand(path: str, loader: Path) -> Path:
        if path == "@loader_path":
            return loader.parent
        if path == "@executable_path":
            return executable.parent
        if path.startswith("@loader_path/"):
            return loader.parent / path[len("@loader_path/"):]
        if path.startswith("@executable_path/"):
            return executable.parent / path[len("@executable_path/"):]
        if path.startswith("/"):
            return Path(path)
        raise BuildError(f"Unsupported dyld path requires explicit review: {path}")

    search_paths = [(path, file) for path in rpaths] + [(path, executable) for path in executable_rpaths]
    for dependency in dependencies:
        # otool -L lists a dylib's own LC_ID_DYLIB before its dependencies.
        if dependency == library_id:
            continue
        if dependency.startswith(("/System/Library/", "/usr/lib/")):
            # Apple system libraries may exist only in the dyld shared cache.
            continue
        if dependency.startswith("@rpath/"):
            suffix = dependency[len("@rpath/"):]
            candidates = [expand(path, loader) / suffix for path, loader in search_paths]
        elif dependency.startswith(("@loader_path/", "@executable_path/")):
            candidates = [expand(dependency, file)]
        else:
            raise BuildError(f"Nonportable or unsupported dependency: {dependency}")
        resolved = [path.resolve() for path in candidates]
        if not any(path.is_relative_to(bundle.resolve()) and path.is_file() for path in resolved):
            raise BuildError(f"Dependency does not resolve to a bundled file: {file.name}: {dependency}")


def verify_bundle(bundle: Path) -> dict:
    bundle = bundle.expanduser().absolute()
    if bundle.is_symlink() or not bundle.is_dir():
        raise BuildError(f"Not an ordinary app directory: {bundle}")
    info = plistlib.loads((bundle / "Contents/Info.plist").read_bytes())
    verify_identity(info)
    if info.get("LSMinimumSystemVersion") != "14.0":
        raise BuildError("Minimum macOS version does not match 14.0")
    for name in ("SUFeedURL", "SUPublicEDKey"):
        if info.get(name):
            raise BuildError(f"Unexpected inherited update setting: {name}")
    if info.get("SUEnableAutomaticChecks", False):
        raise BuildError("Automatic update checks must remain disabled")
    required = ["Contents/Frameworks/librime.1.dylib", "Contents/SharedSupport/default.yaml", "Contents/SharedSupport/default.custom.yaml", "Contents/SharedSupport/luna_pinyin_simp.schema.yaml", "Contents/SharedSupport/luna_pinyin.schema.yaml", "Contents/SharedSupport/luna_pinyin.dict.yaml", "Contents/SharedSupport/stroke.schema.yaml", "Contents/SharedSupport/stroke.dict.yaml", "Contents/SharedSupport/essay.txt", "Contents/SharedSupport/opencc/t2s.json", "Contents/Resources/LICENSE.txt", "Contents/Resources/Licenses/rime/rime-luna-pinyin/LICENSE"]
    for name in required:
        if not (bundle / name).is_file():
            raise BuildError(f"Missing application resource: {name}")
    if (bundle / "Contents/MacOS/rime-install").exists() or (bundle / "Contents/Frameworks/rime-plugins").exists():
        raise BuildError("Unreviewed optional installer/plugins found in baseline bundle")
    if (bundle / "Contents/Frameworks/Sparkle.framework").exists():
        raise BuildError("The excluded automatic updater must not be bundled")
    manifest = read_json(ROOT / "data/schema-manifest.json")
    for package in manifest["packages"]:
        for item in package["files"]:
            if item["path"] in package["runtime_files"]:
                file = bundle / "Contents/SharedSupport" / item["path"]
            else:
                file = bundle / "Contents/Resources/Licenses" / package["repository"] / item["path"]
            if not file.is_file() or digest(file.read_bytes()) != item["sha256"]:
                raise BuildError(f"Packaged schema/source notice differs from its lock: {file}")
    if (bundle / "Contents/SharedSupport/default.custom.yaml").read_bytes() != (ROOT / "data/default.custom.yaml").read_bytes():
        raise BuildError("Packaged baseline schema selection differs from the project override")
    binary = bundle / "Contents/MacOS/EcholME"
    architectures = run(["/usr/bin/lipo", "-archs", str(binary)]).stdout.strip()
    if architectures != "arm64":
        raise BuildError(f"Unexpected application architectures: {architectures}")
    main_rpaths, _ = macho_load_commands(binary)
    for file in bundle.rglob("*"):
        if is_macho(file):
            architecture_list = run(["/usr/bin/lipo", "-archs", str(file)]).stdout.split()
            if "arm64" not in architecture_list:
                raise BuildError(f"Nested executable lacks arm64: {file}")
            verify_link_paths(bundle, file, binary, main_rpaths)
    signature = run(["/usr/bin/codesign", "--verify", "--deep", "--strict", "--verbose=2", str(bundle)])
    return {"result": "PASS", "scope": "static bundle identity, resources, arm64 dependency-path resolution, and local signature; not runtime input acceptance", "bundle": str(bundle), "bundle_identifier": info["CFBundleIdentifier"], "minimum_macos": info["LSMinimumSystemVersion"], "architectures": architectures, "signature": (signature.stdout + signature.stderr).strip(), "dynamic_loading": "NOT_RUN", "notarized": False, "distribution_ready": False, "runtime_input": "NOT_RUN_BY_STATIC_VERIFIER", "runtime_note": "This command performs static verification only. Runtime acceptance and its authorization are recorded separately in docs/round0/RUNTIME_ACCEPTANCE.md."}


def install_first(bundle: Path) -> None:
    report = verify_bundle(bundle)
    destination = Path.home() / "Library/Input Methods" / APP_NAME
    if present(destination):
        raise BuildError(f"Installation target already exists. It was not replaced, moved, or deleted: {destination}")
    directory(destination.parent)
    # copytree refuses an existing destination. On failure it retains partial
    # output; a future attempt stops and asks for human inspection.
    shutil.copytree(bundle.expanduser().absolute(), destination, symlinks=True)
    installed = verify_bundle(destination)
    print(json.dumps({"source_verification": report["result"], "installed_verification": installed, "registration": "NOT_RUN", "selection": "NOT_RUN", "runtime_input": "NOT_RUN", "note": "No process was launched, killed, registered, or selected."}, indent=2))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subcommands = parser.add_subparsers(dest="command", required=True)
    subcommands.add_parser("doctor")
    subcommands.add_parser("prepare")
    build_parser = subcommands.add_parser("build")
    build_parser.add_argument("--configuration", choices=("Debug", "Release"), default="Debug")
    build_parser.add_argument("--build-id")
    for name in ("verify", "install-first"):
        subcommands.add_parser(name).add_argument("--bundle", type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.command == "doctor":
            doctor()
        elif args.command == "prepare":
            prepare()
        elif args.command == "build":
            build(args.configuration, args.build_id)
        elif args.command == "verify":
            print(json.dumps(verify_bundle(args.bundle), indent=2))
        else:
            install_first(args.bundle)
        return 0
    except (BuildError, OSError, ValueError, tarfile.TarError, urllib.error.URLError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
