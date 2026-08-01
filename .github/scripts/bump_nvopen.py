#!/usr/bin/env python3
"""Bump _nvver and the NVIDIA (second) checksum in linux-cachyos kernel templates.

The linux-cachyos / linux-cachyos-v3 kernel templates carry the NVIDIA open
kernel-module version as `_nvver=...` and fetch its source as the SECOND entry
in a dual-distfile block:

    distfiles="<kernel tarball>
     <nvidia open-gpu-kernel-modules tarball>"
    checksum="<kernel sha256>
     <nvidia sha256>"

This helper keeps the module in lockstep with the proprietary `nvidia` driver
package: given a new driver version + the sha256 of its matching
open-gpu-kernel-modules tarball, it rewrites `_nvver` and ONLY the second
(nvidia) checksum, leaving the kernel tarball checksum intact. It is idempotent
(skips a template already at the target version).

Usage:
    bump_nvopen.py <new_nvver> <new_sha256> <template> [<template> ...]

Exit status is always 0; per-template outcome is printed to stdout.
"""
import re
import sys


def bump(path: str, nvver: str, nvsum: str) -> bool:
    s = open(path).read()

    m = re.search(r'^_nvver=(\S+)', s, re.M)
    if not m:
        print(f"{path}: no _nvver line — skip")
        return False

    cur = m.group(1)
    if cur == nvver:
        print(f"{path}: _nvver already {nvver} — skip")
        return False

    # 1) bump _nvver
    s = re.sub(r'^_nvver=.*$', f'_nvver={nvver}', s, count=1, flags=re.M)

    # 2) replace the SECOND sha256 inside the checksum="..." block
    cm = re.search(r'(?ms)^checksum="([^"]*)"', s)
    if not cm:
        print(f"{path}: no checksum block — skip")
        return False

    hashes = re.findall(r'[0-9a-f]{64}', cm.group(1))
    if len(hashes) < 2:
        print(f"{path}: expected 2 checksums, found {len(hashes)} — skip")
        return False

    # Replace only the LAST hash in the block (the nvidia tarball).
    block = cm.group(0)
    new_block = block[::-1].replace(hashes[-1][::-1], nvsum[::-1], 1)[::-1]
    s = s[:cm.start()] + new_block + s[cm.end():]

    open(path, 'w').write(s)
    print(f"{path}: _nvver {cur} -> {nvver}, nvidia sum -> {nvsum[:12]}…")
    return True


if __name__ == "__main__":
    if len(sys.argv) < 4:
        sys.exit("usage: bump_nvopen.py <nvver> <sha256> <template>...")
    nv, sm = sys.argv[1], sys.argv[2]
    if not re.fullmatch(r'[0-9a-f]{64}', sm):
        sys.exit(f"error: '{sm}' is not a 64-char sha256")
    for t in sys.argv[3:]:
        bump(t, nv, sm)
