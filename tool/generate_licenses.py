#!/usr/bin/env python3
"""Writes assets/licenses/licenses.json, the third-party notices the app shows
on its open-source licenses page.

Flutter lists Dart packages by itself. This adds what it cannot see: the
docudis-core and docudis-ner native libraries with every Rust crate compiled
into them, and the files listed in tool/licenses/entries.json (native
libraries, fonts, model, icons).

Usage:
  tool/generate_licenses.py --core DIR --core-revision REV [--core-features F]
                            --ner DIR --ner-revision REV --target TRIPLE...

DIR must be a checkout of that repository at REV, so the crate list matches
the libraries the app ships.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENTRIES = ROOT / "tool" / "licenses" / "entries.json"
OUTPUT = ROOT / "assets" / "licenses" / "licenses.json"
LICENSE_PREFIXES = ("license", "licence", "copying", "notice", "unlicense")

MIT_TEMPLATE = """Copyright (c) {holders}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE."""


def run(args, cwd):
    return subprocess.run(args, cwd=cwd, check=True, capture_output=True, text=True).stdout


def check_revision(source, revision, name):
    actual = run(["git", "rev-parse", "HEAD"], source).strip()
    if actual != revision:
        sys.exit(f"{name} checkout {source} is at {actual}, expected {revision}")


def license_files(directory):
    return sorted(
        p for p in directory.iterdir()
        if p.is_file() and p.name.lower().startswith(LICENSE_PREFIXES)
    )


def read_files(paths):
    return "\n\n".join(p.read_text(encoding="utf-8").strip() for p in paths)


def crates(source, package, features, targets):
    """Every third-party crate linked into `package`, keyed by (name, version)."""
    linked = set()
    for target in targets:
        args = ["cargo", "tree", "--locked", "--offline", "-p", package,
                "-e", "normal,no-proc-macro", "--target", target,
                "--prefix", "none", "-f", "{p}"]
        if features:
            args += ["--features", features]
        for line in run(args, source).splitlines():
            name, version = line.split()[:2]
            linked.add((name, version.lstrip("v")))
    # All features, so optional dependencies have a manifest path to read.
    metadata = json.loads(run(
        ["cargo", "metadata", "--locked", "--offline", "--all-features",
         "--format-version", "1"], source))
    found = {}
    for package_info in metadata["packages"]:
        key = (package_info["name"], package_info["version"])
        # Docudis's own crates get one entry per repository instead.
        if key in linked and not key[0].startswith("docudis-"):
            found[key] = package_info
    return found


def crate_text(package_info):
    files = license_files(Path(package_info["manifest_path"]).parent)
    if files:
        return read_files(files)
    expression = package_info.get("license") or ""
    if "MIT" not in expression:
        sys.exit(f"{package_info['name']} ships no license file and is not MIT ({expression!r})")
    holders = ", ".join(package_info.get("authors") or []) or f"the {package_info['name']} authors"
    return f"License: {expression}\n\n" + MIT_TEMPLATE.format(holders=holders)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--core", type=Path, required=True)
    parser.add_argument("--core-revision", required=True)
    parser.add_argument("--core-features", default="")
    parser.add_argument("--ner", type=Path, required=True)
    parser.add_argument("--ner-revision", required=True)
    parser.add_argument("--target", action="append", required=True)
    args = parser.parse_args()

    check_revision(args.core, args.core_revision, "docudis-core")
    check_revision(args.ner, args.ner_revision, "docudis-ner")

    entries = []
    for name, source in (("docudis-core", args.core), ("docudis-ner", args.ner)):
        entries.append({"packages": [name], "text": read_files(license_files(source))})

    linked = crates(args.core, "docudis-capi", args.core_features, args.target)
    linked.update(crates(args.ner, "docudis-ner-capi", "", args.target))
    for (name, _), package_info in sorted(linked.items()):
        entries.append({"packages": [name], "text": crate_text(package_info)})

    for entry in json.loads(ENTRIES.read_text(encoding="utf-8")):
        parts = [entry["notice"]] if "notice" in entry else []
        parts += [(ROOT / f).read_text(encoding="utf-8").strip() for f in entry.get("files", [])]
        entries.append({"packages": entry["packages"], "text": "\n\n".join(parts)})

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(entries, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"wrote {len(entries)} entries to {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
