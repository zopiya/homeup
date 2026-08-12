#!/usr/bin/env python3
"""Update toolchain/lock.sh from official immutable release metadata."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LOCK = ROOT / "toolchain" / "lock.sh"
USER_AGENT = "homeup-linux-toolchain-updater/1"


def fetch(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


def text(url: str) -> str:
    return fetch(url).decode("utf-8")


def release(repository: str) -> dict:
    return json.loads(text(f"https://api.github.com/repos/{repository}/releases/latest"))


def asset(release_data: dict, name: str) -> str:
    for item in release_data["assets"]:
        if item["name"] == name:
            return item["browser_download_url"]
    raise RuntimeError(f"Missing release asset {name}.")


def sums(url: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in text(url).splitlines():
        fields = line.split()
        if len(fields) >= 2 and re.fullmatch(r"[a-f0-9]{64}", fields[0]):
            result[fields[-1].lstrip("*")] = fields[0]
    return result


def sha256(url: str) -> str:
    digest = hashlib.sha256()
    process = subprocess.Popen(
        [
            "curl",
            "--fail",
            "--location",
            "--proto",
            "=https",
            "--tlsv1.2",
            "--connect-timeout",
            "15",
            "--max-time",
            "180",
            "--silent",
            "--show-error",
            url,
        ],
        stdout=subprocess.PIPE,
    )
    if process.stdout is None:
        raise RuntimeError("Could not read curl output.")
    while chunk := process.stdout.read(1024 * 1024):
        digest.update(chunk)
    if process.wait() != 0:
        raise RuntimeError(f"Could not checksum {url}.")
    return digest.hexdigest()


def rust_target(manifest: str, target: str) -> tuple[str, str]:
    match = re.search(
        rf"^\[pkg\.rust\.target\.{re.escape(target)}\]$\n(.*?)(?=^\[)",
        manifest,
        flags=re.MULTILINE | re.DOTALL,
    )
    if not match:
        raise RuntimeError(f"Missing Rust target {target}.")
    body = match.group(1)
    url = re.search(r'^xz_url = "([^"]+)"$', body, re.MULTILINE)
    digest = re.search(r'^xz_hash = "([a-f0-9]{64})"$', body, re.MULTILINE)
    if not url or not digest:
        raise RuntimeError(f"Missing Rust xz metadata for {target}.")
    return url.group(1), digest.group(1)


def resolve() -> dict[str, tuple[str, dict[str, str], dict[str, str]]]:
    node_index = json.loads(text("https://nodejs.org/dist/index.json"))
    node_tag = next(item["version"] for item in node_index if item["lts"])
    node_version = node_tag.removeprefix("v")
    node_sums = sums(f"https://nodejs.org/dist/{node_tag}/SHASUMS256.txt")
    node_urls = {"amd64": f"https://nodejs.org/dist/{node_tag}/node-v{node_version}-linux-x64.tar.xz"}
    node_hashes = {arch: node_sums[Path(url).name] for arch, url in node_urls.items()}

    bun = release("oven-sh/bun")
    bun_version = bun["tag_name"].removeprefix("bun-v")
    bun_sums = sums(asset(bun, "SHASUMS256.txt"))
    bun_urls = {"amd64": asset(bun, "bun-linux-x64.zip")}
    bun_hashes = {arch: bun_sums[Path(url).name] for arch, url in bun_urls.items()}

    just = release("casey/just")
    just_version = just["tag_name"].removeprefix("v")
    just_sums = sums(asset(just, "SHA256SUMS"))
    just_urls = {"amd64": asset(just, f"just-{just_version}-x86_64-unknown-linux-musl.tar.gz")}
    just_hashes = {arch: just_sums[Path(url).name] for arch, url in just_urls.items()}

    chezmoi = release("twpayne/chezmoi")
    chezmoi_version = chezmoi["tag_name"].removeprefix("v")
    chezmoi_sums = sums(asset(chezmoi, f"chezmoi_{chezmoi_version}_checksums.txt"))
    chezmoi_urls = {"amd64": asset(chezmoi, f"chezmoi_{chezmoi_version}_linux_amd64.tar.gz")}
    chezmoi_hashes = {arch: chezmoi_sums[Path(url).name] for arch, url in chezmoi_urls.items()}

    sheldon = release("rossmacarthur/sheldon")
    sheldon_version = sheldon["tag_name"].removeprefix("v")
    sheldon_urls = {"amd64": asset(sheldon, f"sheldon-{sheldon_version}-x86_64-unknown-linux-musl.tar.gz")}
    sheldon_hashes = {arch: sha256(url) for arch, url in sheldon_urls.items()}

    rust_manifest = text("https://static.rust-lang.org/dist/channel-rust-stable.toml")
    rust_version_match = re.search(r"^\[pkg\.rustc\]$\nversion = \"([0-9]+\.[0-9]+\.[0-9]+)", rust_manifest, re.MULTILINE)
    if not rust_version_match:
        raise RuntimeError("Missing Rust stable version.")
    rust_version = rust_version_match.group(1)
    rust_urls: dict[str, str] = {}
    rust_hashes: dict[str, str] = {}
    for arch, target in {"amd64": "x86_64-unknown-linux-gnu"}.items():
        rust_urls[arch], rust_hashes[arch] = rust_target(rust_manifest, target)

    python_release = release("astral-sh/python-build-standalone")
    python_pattern = re.compile(
        r"^cpython-(3\.\d+\.\d+)\+\d+-x86_64-unknown-linux-gnu-install_only_stripped\.tar\.gz$"
    )
    python_assets = [
        (tuple(map(int, match.group(1).split("."))), match.group(1), item["browser_download_url"])
        for item in python_release["assets"]
        if (match := python_pattern.fullmatch(item["name"]))
    ]
    if not python_assets:
        raise RuntimeError("Missing a stable x86_64 prebuilt CPython asset.")
    _, python_version, python_url = max(python_assets)
    python_hash = sha256(python_url)

    return {
        "just": (just_version, just_urls, just_hashes),
        "chezmoi": (chezmoi_version, chezmoi_urls, chezmoi_hashes),
        "sheldon": (sheldon_version, sheldon_urls, sheldon_hashes),
        "node": (node_version, node_urls, node_hashes),
        "bun": (bun_version, bun_urls, bun_hashes),
        "python": (python_version, {"amd64": python_url}, {"amd64": python_hash}),
        "rust": (rust_version, rust_urls, rust_hashes),
    }


def replace_case(text_value: str, function: str, key: str, value: str) -> str:
    start = text_value.index(f"{function}() {{")
    end = text_value.index("\n}\n", start) + 3
    block = text_value[start:end]
    pattern = rf"(?m)^(    {re.escape(key)}\) printf '%s\\n' ')[^']+(' ;;)$"
    updated, count = re.subn(pattern, rf"\g<1>{value}\g<2>", block)
    if count != 1:
        raise RuntimeError(f"Could not update {function} entry {key}.")
    return text_value[:start] + updated + text_value[end:]


def update_lock(data: dict[str, tuple[str, dict[str, str], dict[str, str]]]) -> bool:
    original = LOCK.read_text()
    updated = original
    for component, (version, urls, hashes) in data.items():
        updated = replace_case(updated, "lock_version", component, version)
        labels = {"amd64": f"{component}:amd64"}
        for arch, label in labels.items():
            if label:
                updated = replace_case(updated, "lock_url", label, urls[arch])
                updated = replace_case(updated, "lock_sha256", label, hashes[arch])
    if updated != original:
        LOCK.write_text(updated)
        return True
    return False


def main() -> int:
    changed = update_lock(resolve())
    print("toolchain lock updated" if changed else "toolchain lock already current")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"toolchain update failed: {error}", file=sys.stderr)
        raise SystemExit(1)
