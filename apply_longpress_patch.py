#!/usr/bin/env python3
"""
Inject a Home-tab long-press hook into the main tab-bar binder.

Target: the constructor of Instagram's main tab-bar binder. It takes a
View, resolves the tab_bar ViewGroup child, and stashes it in field A0F.
We append a call to FeurSettings.installHomeTabWatcher right after that
iput so we can find the feed_tab child (the Home button at the
bottom-left) and attach our long-press listener to it.

Instagram reshuffles obfuscated class names between releases (was
``LX/4jG`` for a while, then ``LX/0YL`` in 426.x, etc.), so we don't
hard-code the class name. We scan every smali tree for any class whose
constructor matches the unique signature:

    .method public constructor <init>(Landroid/view/View;)V
        ...
        iput-object v0, p0, LX/<X>;->A0F:Landroid/view/ViewGroup;

This shape is rare enough that any false positive can be filtered out
with the trailing ``A0E:Landroid/view/View;`` field that the binder also
populates from a sibling resource id immediately after.
"""

import os
import re
import sys


# Field stash specific to the tab-bar binder: A0F holds the tab_bar root
# ViewGroup that the constructor pulls out of the parent view. Pattern
# matches any obfuscated owner class so the patch survives version churn.
TAB_BAR_IPUT_RE = re.compile(
    r"iput-object v0, p0, L(X/[A-Za-z0-9]+);->A0F:Landroid/view/ViewGroup;"
)
# Sibling field populated right after A0F in the same constructor — lets
# us reject classes that just happen to share the A0F name.
SIBLING_IPUT_RE = re.compile(
    r"iput-object v0, p0, L(X/[A-Za-z0-9]+);->A0E:Landroid/view/View;"
)
CTOR_DECL = ".method public constructor <init>(Landroid/view/View;)V"
INJECTION_TEMPLATE = (
    "\n\n    # Feurstagram: watch the tab_bar for feed_tab to attach long-press\n"
    "    invoke-static {{v0}}, "
    "Lcom/feurstagram/FeurSettings;->installHomeTabWatcher(Landroid/view/ViewGroup;)V"
)
MARKER = "Lcom/feurstagram/FeurSettings;->installHomeTabWatcher"


def smali_trees(workdir: str):
    for entry in sorted(os.listdir(workdir)):
        if entry == "smali" or entry.startswith("smali_classes"):
            yield os.path.join(workdir, entry)


def find_target(workdir: str):
    """Locate the tab-bar binder smali by signature, returning (path, class_name).

    Walks every smali tree once, opens any file under X/ (where Instagram
    parks its single-letter classes) and checks for the constructor +
    sibling-iput shape. First match wins.
    """
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
            if CTOR_DECL not in content:
                continue
            tab_match = TAB_BAR_IPUT_RE.search(content)
            sib_match = SIBLING_IPUT_RE.search(content)
            if not tab_match or not sib_match:
                continue
            if tab_match.group(1) != sib_match.group(1):
                continue
            return path, tab_match.group(1)
    return None, None


def patch(workdir: str) -> bool:
    target, class_name = find_target(workdir)
    if target is None:
        print("  Error: tab-bar binder smali not found "
              "(no class with <init>(View) + A0F/A0E iputs)")
        return False

    with open(target, "r") as f:
        content = f.read()

    if MARKER in content:
        print(f"  Already patched: {target}")
        return True

    iput_line = (
        f"iput-object v0, p0, L{class_name};->A0F:Landroid/view/ViewGroup;"
    )
    if iput_line not in content:
        print(f"  Error: tab_bar iput marker not found in {target}")
        return False

    content = content.replace(iput_line, iput_line + INJECTION_TEMPLATE.format(), 1)

    with open(target, "w") as f:
        f.write(content)

    print(f"  Patched: {target} (class L{class_name};)")
    return True


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: apply_longpress_patch.py <decompiled_apk_dir>")
        sys.exit(1)

    if not patch(sys.argv[1]):
        sys.exit(1)
