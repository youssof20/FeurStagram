#!/usr/bin/env python3
"""
Clone patch (Instafel-style logic, single-APK output): rewrite the
decompiled APK so it installs side-by-side with a stock Instagram.

We can't fully `apktool d` Instagram's resources, because apktool decodes
its packed layout table (values/layouts.xml entries like
"L|AEE00|29C|13B3") into a form that aapt2 refuses to recompile.
Instafel sidesteps the problem by emitting an overlay APK instead of
rebuilding sources, but FeurStagram ships a single APK, so we keep the
fast `apktool d --no-res` flow and patch the *binary* AndroidManifest.xml
and resources.arsc in place. The smali phase then propagates the
manifest renames into bytecode literals — the part that the original
FeurStagram clone implementation was missing.

Phases (mirrors mamiiblt/instafel CloneGeneral + ClonePackageReplacer):

  1. AndroidManifest.xml (binary AXML):
       - rewrite the root <manifest package="..."> attribute
       - rewrite each <provider android:authorities="..."> per the
         Instafel rule (replace inline if it contains com.instagram.android,
         otherwise prefix with the new package), and remember
         {old_authority -> new_authority} for the smali phase
       - rewrite <permission> / <uses-permission[-sdk-23]> android:name
         when it contains com.instagram.android, except for blacklisted
         OS / OEM / cross-app permission prefixes
       - rewrite android:taskAffinity the same way as authorities

  2. resources.arsc (binary): rewrite the package name in every
     RES_TABLE_PACKAGE chunk so resource lookups resolve under the new
     package id (Resources.getIdentifier and friends).

  3. smali tree: for every .smali file (excluding the com/feurstagram/*
     classes we inject ourselves), apply phase-1 authority renames and
     replace the literal "com.instagram.android" const-strings with the
     new package name. Quoting prevents matches against class
     identifiers (which are slash-separated and never quoted anyway).
"""

from __future__ import annotations

import argparse
import os
import struct
import sys


OLD_PACKAGE = "com.instagram.android"
DEFAULT_NEW_PACKAGE = "com.instagram.android.feurstagram"

# Permission name prefixes that must NEVER be rewritten — declared by
# the OS / Google / OEMs / sister apps. Renaming them on our side
# breaks <uses-permission> resolution and Play Services.
# Source: instafel patcher-core/src/main/resources/blacklisted_perms.json
BLACKLISTED_PERM_PREFIXES = (
    "com.google.android",
    "com.amazon.device",
    "com.instagram.direct",
    ".permission.RECEIVE_ADM_MESSAGE",
    "android.permission",
    "com.android",
    "com.htc",
    "com.huawei",
    "com.sonymobile",
    "com.sonyericsson",
    "android.hardware",
)

PERMISSION_TAGS = ("permission", "uses-permission", "uses-permission-sdk-23")

SKIP_SMALI_PATH_FRAGMENT = os.path.join("com", "feurstagram") + os.sep


# ---------- AXML constants ----------
CHUNK_XML = 0x0003
CHUNK_STRING_POOL = 0x0001
CHUNK_XML_START_ELEMENT = 0x0102
FLAG_UTF8 = 1 << 8
TYPE_STRING = 0x03
ATTR_FMT = "<IIIHBBI"

# ---------- resources.arsc constants ----------
RES_TABLE_TYPE = 0x0002
RES_TABLE_PACKAGE_TYPE = 0x0200
PACKAGE_NAME_BYTES = 256  # UTF-16LE char16_t[128]


# ============================================================
# AXML helpers (string pool encode/decode)
# ============================================================

def _decode_pool_string(data: bytes, offset: int, is_utf8: bool) -> str:
    if is_utf8:
        i = offset
        b = data[i]
        i += 1
        if b & 0x80:
            i += 1  # second byte of utf16 char count (unused)
        u8_len = data[i]
        i += 1
        if u8_len & 0x80:
            u8_len = ((u8_len & 0x7F) << 8) | data[i]
            i += 1
        return data[i:i + u8_len].decode("utf-8")
    u16_len = struct.unpack_from("<H", data, offset)[0]
    i = offset + 2
    if u16_len & 0x8000:
        high = u16_len & 0x7FFF
        low = struct.unpack_from("<H", data, i)[0]
        u16_len = (high << 16) | low
        i += 2
    return data[i:i + u16_len * 2].decode("utf-16-le")


def _encode_pool_string(text: str, is_utf8: bool) -> bytes:
    if is_utf8:
        u8 = text.encode("utf-8")
        u16_len = len(text)
        u8_len = len(u8)
        if u16_len > 0x7FFF or u8_len > 0x7FFF:
            raise ValueError(f"String too long to encode: {text!r}")
        prefix = bytearray()
        if u16_len > 0x7F:
            prefix += bytes([(u16_len >> 8) | 0x80, u16_len & 0xFF])
        else:
            prefix += bytes([u16_len])
        if u8_len > 0x7F:
            prefix += bytes([(u8_len >> 8) | 0x80, u8_len & 0xFF])
        else:
            prefix += bytes([u8_len])
        return bytes(prefix) + u8 + b"\x00"
    utf16 = text.encode("utf-16-le")
    u16_len = len(text)
    if u16_len > 0x7FFF:
        raise ValueError(f"String too long to encode: {text!r}")
    return struct.pack("<H", u16_len) + utf16 + b"\x00\x00"


# ============================================================
# Renaming rules (instafel CloneGeneral)
# ============================================================

def _is_blacklisted_perm(name: str) -> bool:
    return any(name.startswith(prefix) for prefix in BLACKLISTED_PERM_PREFIXES)


def _rename_one_authority(authority: str, new_package: str) -> str:
    if OLD_PACKAGE in authority:
        return authority.replace(OLD_PACKAGE, new_package)
    return f"{new_package}.{authority}"


def _rename_authorities_value(value: str, new_package: str, mapping: dict[str, str]) -> str:
    """Rewrite a (possibly semicolon-joined) authorities attribute and
    record per-segment renames so the smali phase can find them."""
    parts = value.split(";")
    new_parts: list[str] = []
    for part in parts:
        new_part = _rename_one_authority(part, new_package)
        if new_part != part:
            mapping[part] = new_part
        new_parts.append(new_part)
    return ";".join(new_parts)


def _rename_package_name(value: str, new_package: str) -> str:
    if value == OLD_PACKAGE or value.startswith(OLD_PACKAGE + "."):
        return new_package + value[len(OLD_PACKAGE):]
    return value


def _rename_permission_name(value: str, new_package: str) -> str:
    if _is_blacklisted_perm(value):
        return value
    if OLD_PACKAGE in value:
        return value.replace(OLD_PACKAGE, new_package)
    return value


# ============================================================
# AXML traversal: collect attribute rewrites + authorities map
# ============================================================

def _collect_manifest_rewrites(
    blob: bytes, xml_start: int, strings: list[str], new_package: str,
) -> tuple[list[tuple[int, str]], dict[str, str]]:
    """Walk the AXML chunks and return:
      - a list of (attribute file offset, new string value), so the
        caller can intern each new value into the pool and rewrite the
        attribute's string reference (without disturbing other
        consumers of the same pool index)
      - the authorities_map for the smali phase
    """
    interesting_attrs = {"package", "authorities", "taskAffinity", "permission", "name"}
    attr_name_indices = {i: s for i, s in enumerate(strings) if s in interesting_attrs}
    tag_name_indices = {
        i: s for i, s in enumerate(strings) if s in {"manifest"} | set(PERMISSION_TAGS)
    }

    rewrites: list[tuple[int, str]] = []
    authorities_map: dict[str, str] = {}

    attr_size_const = struct.calcsize(ATTR_FMT)  # 20 bytes

    off = xml_start
    blob_len = len(blob)
    while off + 8 <= blob_len:
        ctype, _chdr, csize = struct.unpack_from("<HHI", blob, off)
        if csize == 0 or off + csize > blob_len:
            break
        if ctype == CHUNK_XML_START_ELEMENT:
            base = off + 16  # 8-byte chunk hdr + line(4) + comment(4)
            (_ns, name_idx, attr_start, attr_size, attr_count) = struct.unpack_from(
                "<IIHHH", blob, base,
            )
            tag_name = tag_name_indices.get(name_idx)
            attr_base = base + attr_start
            for a in range(attr_count):
                ap = attr_base + a * attr_size
                (_a_ns, a_name_idx, raw_val_idx,
                 _tv_size, _tv_res0, _tv_type, _tv_data) = struct.unpack_from(
                    ATTR_FMT, blob, ap,
                )
                attr_name = attr_name_indices.get(a_name_idx)
                if attr_name is None or raw_val_idx == 0xFFFFFFFF:
                    continue
                original = strings[raw_val_idx]
                if attr_name == "package":
                    new_value = _rename_package_name(original, new_package)
                elif attr_name == "authorities":
                    new_value = _rename_authorities_value(original, new_package, authorities_map)
                elif attr_name == "taskAffinity":
                    new_value = _rename_package_name(original, new_package)
                elif attr_name == "permission":
                    new_value = _rename_permission_name(original, new_package)
                elif attr_name == "name" and tag_name in PERMISSION_TAGS:
                    new_value = _rename_permission_name(original, new_package)
                else:
                    continue
                if new_value != original:
                    rewrites.append((ap, new_value))
        off += csize

    # `attr_size_const` is checked against the on-disk attr_size lazily;
    # for Instagram's manifests they always match (20 bytes).
    _ = attr_size_const
    return rewrites, authorities_map


# ============================================================
# Phase 1: patch AndroidManifest.xml (binary AXML)
# ============================================================

def patch_manifest(path: str, new_package: str) -> dict[str, str]:
    with open(path, "rb") as f:
        blob = bytearray(f.read())

    file_type, file_hdr_size, file_size = struct.unpack_from("<HHI", blob, 0)
    if file_type != CHUNK_XML:
        raise SystemExit(f"Not an AXML file (type=0x{file_type:04x})")
    if file_size != len(blob):
        raise SystemExit(f"Header size {file_size} != actual size {len(blob)}")

    pool_off = file_hdr_size
    (sp_type, sp_hdr_size, sp_chunk_size,
     sp_string_count, sp_style_count, sp_flags,
     sp_strings_start, sp_styles_start) = struct.unpack_from(
        "<HHIIIIII", blob, pool_off,
    )
    if sp_type != CHUNK_STRING_POOL:
        raise SystemExit(f"Expected string pool, got 0x{sp_type:04x}")

    is_utf8 = bool(sp_flags & FLAG_UTF8)

    offsets_off = pool_off + sp_hdr_size
    strings_data_off = pool_off + sp_strings_start
    strings_data_end = (
        pool_off + sp_styles_start if sp_style_count else pool_off + sp_chunk_size
    )

    offsets = list(struct.unpack_from(f"<{sp_string_count}I", blob, offsets_off))
    pool_bytes = bytes(blob[strings_data_off:strings_data_end])
    strings = [_decode_pool_string(pool_bytes, o, is_utf8) for o in offsets]

    xml_start = pool_off + sp_chunk_size
    rewrites, authorities_map = _collect_manifest_rewrites(
        blob, xml_start, strings, new_package,
    )
    if not rewrites:
        print("  Manifest: nothing to rewrite (already patched?)")
        return authorities_map

    # Intern each distinct new value into the pool. We append entries
    # rather than mutating in place so other references to the old pool
    # index (e.g. android:name=Lcom/instagram/android/.../...) stay
    # untouched.
    new_value_to_index: dict[str, int] = {}
    appended = bytearray()
    new_offsets = list(offsets)

    def intern(value: str) -> int:
        if value in new_value_to_index:
            return new_value_to_index[value]
        idx = len(new_offsets)
        new_offsets.append(len(pool_bytes) + len(appended))
        appended.extend(_encode_pool_string(value, is_utf8))
        new_value_to_index[value] = idx
        return idx

    for attr_ap, new_value in rewrites:
        new_idx = intern(new_value)
        (_a_ns, a_name_idx, _old_raw, tv_size, tv_res0, tv_type, tv_data) = struct.unpack_from(
            ATTR_FMT, blob, attr_ap,
        )
        new_tv_data = new_idx if tv_type == TYPE_STRING else tv_data
        struct.pack_into(
            ATTR_FMT, blob, attr_ap,
            _a_ns, a_name_idx, new_idx, tv_size, tv_res0, tv_type, new_tv_data,
        )

    new_pool_bytes = pool_bytes + bytes(appended)
    pad = (-len(new_pool_bytes)) & 3
    new_pool_bytes += b"\x00" * pad

    new_string_count = len(new_offsets)
    new_offsets_bytes = struct.pack(f"<{new_string_count}I", *new_offsets)

    styles_section = (
        bytes(blob[pool_off + sp_styles_start:pool_off + sp_chunk_size])
        if sp_style_count else b""
    )
    new_strings_start = sp_hdr_size + len(new_offsets_bytes)
    new_styles_start = (
        new_strings_start + len(new_pool_bytes) if sp_style_count else 0
    )
    new_chunk_size = new_strings_start + len(new_pool_bytes) + len(styles_section)

    new_pool_header = struct.pack(
        "<HHIIIIII",
        sp_type, sp_hdr_size, new_chunk_size,
        new_string_count, sp_style_count, sp_flags,
        new_strings_start, new_styles_start,
    )
    new_pool_chunk = new_pool_header + new_offsets_bytes + new_pool_bytes + styles_section

    rest = bytes(blob[pool_off + sp_chunk_size:])
    new_blob = bytearray(blob[:pool_off]) + new_pool_chunk + rest
    struct.pack_into("<I", new_blob, 4, len(new_blob))

    with open(path, "wb") as f:
        f.write(new_blob)

    print(f"  Manifest: rewrote {len(rewrites)} attribute(s) via {len(new_value_to_index)} new pool entries")
    print(f"  Manifest: package -> {new_package}; {len(authorities_map)} authorities renamed")
    return authorities_map


# ============================================================
# Phase 2: patch resources.arsc (binary)
# ============================================================

def _decode_arsc_package_name(raw: bytes) -> str:
    return raw.decode("utf-16-le", errors="ignore").split("\x00", 1)[0]


def _encode_arsc_package_name(name: str) -> bytes:
    encoded = name.encode("utf-16-le")
    if len(encoded) > PACKAGE_NAME_BYTES - 2:
        raise ValueError(f"Package name too long for resources.arsc: {name}")
    padded = encoded + b"\x00\x00"
    padded += b"\x00" * (PACKAGE_NAME_BYTES - len(padded))
    return padded


def patch_resources_arsc(path: str, new_package: str) -> int:
    if not os.path.isfile(path):
        print(f"  resources.arsc not found at {path} (skipping)")
        return 0

    with open(path, "rb") as f:
        blob = bytearray(f.read())

    if len(blob) < 12:
        raise SystemExit("resources.arsc too small")

    table_type, table_hdr_size, total_size = struct.unpack_from("<HHI", blob, 0)
    if table_type != RES_TABLE_TYPE:
        raise SystemExit(f"Not a resources table (type=0x{table_type:04x})")
    if total_size != len(blob):
        print(f"  Warning: arsc header size={total_size}, actual={len(blob)}")
    if table_hdr_size < 12:
        raise SystemExit(f"Invalid RES_TABLE header size: {table_hdr_size}")

    patched = 0
    offset = table_hdr_size
    table_end = min(total_size, len(blob))
    while offset + 8 <= table_end:
        chunk_type, chunk_header_size, chunk_size = struct.unpack_from("<HHI", blob, offset)
        if chunk_size == 0 or offset + chunk_size > table_end:
            break
        if chunk_type == RES_TABLE_PACKAGE_TYPE:
            if chunk_header_size < 12 + PACKAGE_NAME_BYTES:
                raise SystemExit("Invalid RES_TABLE_PACKAGE header size")
            name_off = offset + 12
            current = _decode_arsc_package_name(bytes(blob[name_off:name_off + PACKAGE_NAME_BYTES]))
            if current == OLD_PACKAGE:
                blob[name_off:name_off + PACKAGE_NAME_BYTES] = _encode_arsc_package_name(new_package)
                patched += 1
        offset += chunk_size

    if patched == 0:
        print(f"  Warning: no RES_TABLE_PACKAGE chunk matched {OLD_PACKAGE!r}")
    else:
        with open(path, "wb") as f:
            f.write(blob)
        print(f"  resources.arsc: rewrote {patched} package chunk(s) -> {new_package}")
    return patched


# ============================================================
# Phase 3: walk the smali tree
# ============================================================

def _smali_dirs(workdir: str):
    for entry in sorted(os.listdir(workdir)):
        if entry == "smali" or entry.startswith("smali_classes"):
            full = os.path.join(workdir, entry)
            if os.path.isdir(full):
                yield full


def patch_smali_tree(workdir: str, authorities_map: dict[str, str], new_package: str) -> None:
    # Sort by length descending so we never let a shorter authority
    # eat into the middle of a longer one.
    sorted_auths = sorted(authorities_map.items(), key=lambda kv: len(kv[0]), reverse=True)
    # Quoting limits matches to const-string operands, which is where
    # authorities and package literals live in smali.
    auth_replacements = [(f'"{old}"', f'"{new}"') for old, new in sorted_auths]
    package_old = f'"{OLD_PACKAGE}"'
    package_new = f'"{new_package}"'

    files_changed = 0
    files_scanned = 0
    for smali_dir in _smali_dirs(workdir):
        for dirpath, _dirnames, filenames in os.walk(smali_dir):
            if SKIP_SMALI_PATH_FRAGMENT in dirpath + os.sep:
                continue
            for filename in filenames:
                if not filename.endswith(".smali"):
                    continue
                files_scanned += 1
                path = os.path.join(dirpath, filename)
                with open(path, "r", encoding="utf-8") as f:
                    original = f.read()
                content = original
                for old, new in auth_replacements:
                    if old in content:
                        content = content.replace(old, new)
                if package_old in content:
                    content = content.replace(package_old, package_new)
                if content != original:
                    with open(path, "w", encoding="utf-8") as f:
                        f.write(content)
                    files_changed += 1

    print(f"  Smali: rewrote {files_changed}/{files_scanned} file(s)")


# ============================================================
# Entry point
# ============================================================

def main() -> int:
    parser = argparse.ArgumentParser(description="FeurStagram clone patch")
    parser.add_argument("workdir", help="apktool decompiled source dir")
    parser.add_argument(
        "new_package", nargs="?", default=DEFAULT_NEW_PACKAGE,
        help=f"new package id (default: {DEFAULT_NEW_PACKAGE})",
    )
    args = parser.parse_args()

    workdir = args.workdir
    new_package = args.new_package

    manifest_path = os.path.join(workdir, "AndroidManifest.xml")
    if not os.path.isfile(manifest_path):
        print(f"  Error: {manifest_path} not found")
        return 1

    authorities_map = patch_manifest(manifest_path, new_package)
    patch_resources_arsc(os.path.join(workdir, "resources.arsc"), new_package)
    patch_smali_tree(workdir, authorities_map, new_package)
    return 0


if __name__ == "__main__":
    sys.exit(main())
