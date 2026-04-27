#!/usr/bin/env python3
"""
Resolve Instagram's notification channel enum at patch time.

FeurNotificationChannels.smali iterates the enum returned by Instagram's
NotificationChannelDef.values() and pre-creates each channel with the
system NotificationManager. This is needed in clone mode because some
channels (notably ``ig_direct``) are otherwise registered lazily by code
paths that never fire for the renamed package, so incoming pushes get
dropped with ``No Channel found for pkg=...``.

Instagram reshuffles the obfuscated class name of that enum every release
(``LX/9a2`` in 425.x, ``LX/8pn`` in 426.x, …), so we don't hard-code it.
We scan every smali tree for an enum that:

  1. Declares ``.class public final enum LX/<X>;`` extending
     ``Ljava/lang/Enum;``.
  2. Has the constructor ``<init>(IILjava/lang/String;Ljava/lang/String;)V``
     that ``iput``s its 4th arg into ``A01:Ljava/lang/String;`` and its
     2nd arg into ``A00:I``.
  3. Mentions known channel ids (``ig_direct``, ``ig_other``, …) in its
     ``<clinit>``.

The matching class name is then substituted into our smali template.
"""

from __future__ import annotations

import os
import re
import sys


PLACEHOLDER = "LX/9a2;"
TARGET_REL = os.path.join(
    "smali_classes17", "com", "feurstagram", "FeurNotificationChannels.smali"
)
ENUM_DECL_RE = re.compile(
    r"^\.class public final enum (LX/[A-Za-z0-9]+);", re.MULTILINE
)
CTOR_BODY_RE = re.compile(
    r"\.method public constructor <init>\(IILjava/lang/String;Ljava/lang/String;\)V"
    r"(?P<body>.*?)\.end method",
    re.DOTALL,
)
CHANNEL_FINGERPRINTS = ('"ig_direct"', '"ig_other"', '"ig_likes"')


def smali_trees(workdir: str):
    for entry in sorted(os.listdir(workdir)):
        if entry == "smali" or entry.startswith("smali_classes"):
            yield os.path.join(workdir, entry)


def looks_like_channel_enum(content: str) -> str | None:
    """Return the LX/* class name iff the file matches our enum signature."""
    decl = ENUM_DECL_RE.search(content)
    if not decl:
        return None
    # Constructor must stash the second int into A00:I and the second string
    # into A01:Ljava/lang/String;. This is what FeurNotificationChannels reads.
    ctor = CTOR_BODY_RE.search(content)
    if not ctor:
        return None
    body = ctor.group("body")
    if "iput-object p4, p0," not in body or "->A01:Ljava/lang/String;" not in body:
        return None
    if "iput p2, p0," not in body or "->A00:I" not in body:
        return None
    # Final check: the file's <clinit> should mention several known IG channel
    # ids. This rejects unrelated enums that happen to share the same shape.
    if not all(fp in content for fp in CHANNEL_FINGERPRINTS):
        return None
    return decl.group(1)


def find_channel_enum(workdir: str) -> tuple[str | None, str | None]:
    for tree in smali_trees(workdir):
        x_dir = os.path.join(tree, "X")
        if not os.path.isdir(x_dir):
            continue
        for name in sorted(os.listdir(x_dir)):
            if not name.endswith(".smali"):
                continue
            path = os.path.join(x_dir, name)
            try:
                with open(path, "r") as f:
                    content = f.read()
            except OSError:
                continue
            class_name = looks_like_channel_enum(content)
            if class_name:
                return class_name, path
    return None, None


def rewrite_target(workdir: str, class_name: str) -> bool:
    target = os.path.join(workdir, TARGET_REL)
    if not os.path.isfile(target):
        print(f"  Error: {TARGET_REL} not staged in build dir")
        return False

    with open(target, "r") as f:
        content = f.read()

    # class_name already starts with "LX/"; placeholder is "LX/9a2;" with a
    # trailing semicolon, so we just need to append it.
    new_ref = f"{class_name};"
    if PLACEHOLDER not in content and new_ref in content:
        print(f"  Already rewritten to {new_ref}")
        return True
    if PLACEHOLDER not in content:
        print(f"  Error: placeholder {PLACEHOLDER} not found in {target}")
        return False

    content = content.replace(PLACEHOLDER, new_ref)

    with open(target, "w") as f:
        f.write(content)

    return True


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: apply_clone_notifications_patch.py <decompiled_apk_dir>")
        return 1

    workdir = sys.argv[1]
    class_name, found_path = find_channel_enum(workdir)
    if not class_name:
        print(
            "  Error: Instagram notification channel enum not found "
            "(no enum with <init>(IILstring;Lstring;)V + ig_direct/ig_other ids)"
        )
        return 1

    print(f"  Resolved channel enum: {class_name}; ({found_path})")
    if not rewrite_target(workdir, class_name):
        return 1

    print(f"  Rewrote FeurNotificationChannels to {class_name};")
    return 0


if __name__ == "__main__":
    sys.exit(main())
