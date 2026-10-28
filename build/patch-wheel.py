# SPDX-FileCopyrightText: © 2026 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# /// script
# requires-python = ">=3.11"
# dependencies = ["pip==26.2.2", "wheel==0.48.0"]
# ///
"""Download a pinned wheel, apply ordered runtime patches, and repack it."""

import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def run(*args):
    subprocess.run(args, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("requirement")
    parser.add_argument("patch_dir", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--constraint", type=Path)
    parser.add_argument(
        "--index-url", default=os.environ.get("UV_INDEX", "https://pypi.org/simple")
    )
    args = parser.parse_args()
    if not args.patch_dir.is_dir():
        parser.error("patch directory does not exist")
    patches = sorted(args.patch_dir.glob("*.patch"))
    args.output_dir.mkdir(parents=True, exist_ok=True)
    if any(args.output_dir.glob("*.whl")):
        parser.error("output directory must not already contain wheels")

    with tempfile.TemporaryDirectory(prefix="patched-wheel-") as temporary:
        work = Path(temporary)
        download = [
            sys.executable,
            "-m",
            "pip",
            "download",
            "--quiet",
            "--disable-pip-version-check",
            "--no-deps",
            "--only-binary=:all:",
            "--index-url",
            args.index_url,
            "--dest",
            str(work / "download"),
        ]
        if args.constraint:
            download += ["--constraint", str(args.constraint)]
        run(*download, args.requirement)
        wheels = list((work / "download").glob("*.whl"))
        if len(wheels) != 1:
            parser.error("requirement must resolve to exactly one wheel")
        if not patches:
            shutil.copy2(wheels[0], args.output_dir / wheels[0].name)
            return
        run(
            sys.executable,
            "-m",
            "wheel",
            "unpack",
            str(wheels[0]),
            "--dest",
            str(work / "unpacked"),
        )
        roots = list((work / "unpacked").iterdir())
        if len(roots) != 1 or not roots[0].is_dir():
            parser.error("expected exactly one unpacked wheel directory")
        digest = hashlib.sha256(wheels[0].read_bytes())
        for patch in patches:
            digest.update(patch.name.encode() + b"\0" + patch.read_bytes() + b"\0")
            print(f"Applying {patch.name}", flush=True)
            apply = ("git", "-C", str(roots[0]), "apply", "--whitespace=error-all")
            run(*apply, "--check", str(patch.resolve()))
            run(*apply, str(patch.resolve()))
        run(
            sys.executable,
            "-m",
            "wheel",
            "pack",
            str(roots[0]),
            "--build-number",
            "1p" + digest.hexdigest()[:16],
            "--dest-dir",
            str(args.output_dir.resolve()),
        )


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        # Avoid echoing a package-index URL that might contain credentials.
        raise SystemExit(error.returncode) from None
