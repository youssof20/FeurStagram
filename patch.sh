#!/bin/bash

# FeurStagram Patcher
# Patches an Instagram APK to create a distraction-free version.
#
# Single-APK build: all content blocks (feed, explore, reels, stories) are
# toggled at runtime by long-pressing the Home tab (bottom-left).
#
# Usage: ./patch.sh [--clone [PACKAGE]] <instagram.apk>

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_DIR="$SCRIPT_DIR/patches"
KEYSTORE="${FEURSTAGRAM_KEYSTORE:-$SCRIPT_DIR/feurstagram.keystore}"
KEYSTORE_PASS="${FEURSTAGRAM_KEYSTORE_PASS:-}"
KEY_ALIAS="${FEURSTAGRAM_KEY_ALIAS:-feurstagram}"
KEY_PASS="${FEURSTAGRAM_KEY_PASS:-$KEYSTORE_PASS}"

CLONE_MODE=0
CLONE_PACKAGE="com.instagram.android.feurstagram"

find_build_tools() {
    local paths=(
        "$ANDROID_HOME/build-tools"
        "$ANDROID_SDK_ROOT/build-tools"
        "$HOME/Android/Sdk/build-tools"
        "/usr/lib/android-sdk/build-tools"
        "/opt/homebrew/share/android-commandlinetools/build-tools"
        "$HOME/Library/Android/sdk/build-tools"
        "/usr/local/share/android-commandlinetools/build-tools"
    )
    for base in "${paths[@]}"; do
        if [ -d "$base" ]; then
            local latest=$(ls -1 "$base" 2>/dev/null | sort -V | tail -n1)
            if [ -n "$latest" ] && [ -f "$base/$latest/zipalign" ]; then
                echo "$base/$latest"
                return 0
            fi
        fi
    done
    return 1
}

check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"

    if ! command -v apktool &> /dev/null; then
        echo -e "${RED}Error: apktool not found.${NC}"
        echo "  Linux: sudo apt install apktool"
        echo "  macOS: brew install apktool"
        exit 1
    fi
    if ! command -v java &> /dev/null; then
        echo -e "${RED}Error: java not found. Please install Java runtime.${NC}"
        exit 1
    fi
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: python3 not found. Please install Python 3.${NC}"
        exit 1
    fi

    BUILD_TOOLS=$(find_build_tools)
    if [ -z "$BUILD_TOOLS" ]; then
        echo -e "${RED}Error: Android build-tools not found.${NC}"
        exit 1
    fi

    ZIPALIGN="$BUILD_TOOLS/zipalign"
    APKSIGNER="$BUILD_TOOLS/apksigner"

    if [ ! -f "$KEYSTORE" ]; then
        echo -e "${RED}Error: keystore not found at: $KEYSTORE${NC}"
        exit 1
    fi
    if [ -z "$KEYSTORE_PASS" ]; then
        echo -e "${RED}Error: FEURSTAGRAM_KEYSTORE_PASS is not set.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ All dependencies found${NC}"
}

patch_apk() {
    local INPUT_APK="$1"
    local WORK_DIR="$SCRIPT_DIR/instagram_source"
    local INPUT_BASENAME
    INPUT_BASENAME="$(basename "$INPUT_APK" .apk)"
    local OUTPUT_DIR="$SCRIPT_DIR/artifacts"
    local OUTPUT_APK
    if [ "$CLONE_MODE" -eq 1 ]; then
        OUTPUT_APK="$OUTPUT_DIR/feurstagram_clone_patched_${INPUT_BASENAME}.apk"
    else
        OUTPUT_APK="$OUTPUT_DIR/feurstagram_patched_${INPUT_BASENAME}.apk"
    fi
    mkdir -p "$OUTPUT_DIR"

    if [ "$CLONE_MODE" -eq 1 ]; then
        echo -e "${YELLOW}Clone mode: new package = ${CLONE_PACKAGE}${NC}"
    fi

    echo -e "\n${YELLOW}[1/6] Decompiling APK...${NC}"
    if [ -d "$WORK_DIR" ]; then
        python3 - "$WORK_DIR" <<'PY'
import shutil, sys, time
work_dir = sys.argv[1]
last_error = None
for _ in range(5):
    try:
        shutil.rmtree(work_dir)
        last_error = None
        break
    except FileNotFoundError:
        last_error = None
        break
    except OSError as err:
        last_error = err
        time.sleep(1)
if last_error is not None:
    raise last_error
PY
    fi
    # We always decode with --no-res. Instagram packs layouts in a private
    # encoding (values/layouts.xml entries like "L|AEE00|29C|13B3") that
    # apktool can decode but aapt2 refuses to recompile, so a full decode
    # never round-trips. For clone mode this means we patch the binary
    # AndroidManifest.xml and resources.arsc directly (apply_clone_patch.py).
    apktool d --no-res "$INPUT_APK" -o "$WORK_DIR"
    echo -e "${GREEN}✓ Decompiled${NC}"

    echo -e "\n${YELLOW}[2/6] Adding FeurStagram classes...${NC}"
    mkdir -p "$WORK_DIR/smali_classes17/com/feurstagram"
    cp "$PATCHES_DIR/FeurConfig.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurHooks.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurSettings.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurSwitchListener.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurSettingsLongClick.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurHomeTabWatcher.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurInstantsHider.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurNotesHider.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurReelsTabHider.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurReelsSwipeCallback.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurDoneClickListener.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurCancelClickListener.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurDoneButtonClickListener.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurDoneConfirmButtonClickListener.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurCacheCleaner.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurHardcoreClickListener.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurHardcoreButtonClickListener.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurHardcoreConfirmClickListener.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    cp "$PATCHES_DIR/FeurHardcoreConfirmButtonClickListener.smali" "$WORK_DIR/smali_classes17/com/feurstagram/"
    echo -e "${GREEN}✓ Added FeurStagram smali classes${NC}"

    echo -e "\n${YELLOW}[3/6] Patching network layer...${NC}"
    local TIGON_FILE="$WORK_DIR/smali/com/instagram/api/tigon/TigonServiceLayer.smali"
    if [ ! -f "$TIGON_FILE" ]; then
        echo -e "${RED}Error: TigonServiceLayer.smali not found${NC}"
        exit 1
    fi
    python3 "$SCRIPT_DIR/apply_network_patch.py" "$TIGON_FILE"
    echo -e "${GREEN}✓ Network hook patch applied${NC}"

    echo -e "\n${YELLOW}[4/6] Injecting long-press settings hook...${NC}"
    python3 "$SCRIPT_DIR/apply_longpress_patch.py" "$WORK_DIR"
    echo -e "${GREEN}✓ Long-press settings hook applied${NC}"

    if [ "$CLONE_MODE" -eq 1 ]; then
        echo -e "\n${YELLOW}[4b/6] Rewriting package ID for clone install...${NC}"
        python3 "$SCRIPT_DIR/apply_clone_patch.py" "$WORK_DIR" "$CLONE_PACKAGE"
        echo -e "${GREEN}✓ Package rewritten to ${CLONE_PACKAGE}${NC}"
    fi

    # Force native libraries to be stored uncompressed in the rebuilt APK.
    # Instagram 426+ ships per-loader manifest .so files (e.g.
    # libbase.soloader-manifest.so) that SoLoader opens via
    # AssetManager.openNonAssetFd, which requires the entry to be STORED.
    # apktool's default rebuild deflates everything not listed in apktool.yml's
    # doNotCompress, so we inject a "so" entry up front. Idempotent.
    python3 - "$WORK_DIR/apktool.yml" <<'PY'
import sys
path = sys.argv[1]
with open(path, "r") as f:
    lines = f.readlines()
# locate the doNotCompress: header and ensure "- so" is among its entries.
out = []
i = 0
inserted = False
while i < len(lines):
    out.append(lines[i])
    if lines[i].rstrip() == "doNotCompress:" and not inserted:
        # collect existing entries for this list
        j = i + 1
        existing = []
        while j < len(lines) and lines[j].startswith("- "):
            existing.append(lines[j].rstrip())
            j += 1
        if "- so" not in existing:
            out.append("- so\n")
        inserted = True
    i += 1
with open(path, "w") as f:
    f.writelines(out)
PY

    echo -e "\n${YELLOW}[5/6] Building APK...${NC}"
    apktool b "$WORK_DIR" -o "$SCRIPT_DIR/feurstagram_unsigned.apk"
    echo -e "${GREEN}✓ APK built${NC}"

    echo -e "\n${YELLOW}[6/6] Signing APK...${NC}"
    # -p page-aligns native .so entries so SoLoader can mmap them without an
    # intermediate copy. Required when libs are stored uncompressed.
    "$ZIPALIGN" -p -f 4 "$SCRIPT_DIR/feurstagram_unsigned.apk" "$SCRIPT_DIR/feurstagram_aligned.apk"
    "$APKSIGNER" sign --ks "$KEYSTORE" --ks-key-alias "$KEY_ALIAS" --ks-pass "pass:$KEYSTORE_PASS" --key-pass "pass:$KEY_PASS" --out "$OUTPUT_APK" "$SCRIPT_DIR/feurstagram_aligned.apk"
    rm -f "$SCRIPT_DIR/feurstagram_unsigned.apk" "$SCRIPT_DIR/feurstagram_aligned.apk"
    echo -e "${GREEN}✓ APK signed${NC}"

    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}SUCCESS! Patched APK: $OUTPUT_APK${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "\nInstall with: adb install -r $OUTPUT_APK"
    echo -e "Long-press the Home tab (bottom-left) to toggle blocks."
}

usage() {
    echo "Usage: $0 [--clone [PACKAGE]] <instagram.apk>"
    echo ""
    echo "Patches an Instagram APK to create FeurStagram (distraction-free)."
    echo ""
    echo "All content blocks (Home Feed, Explore, Reels, Stories) are"
    echo "individually toggleable at runtime: long-press the Home tab (bottom-left)"
    echo "to open the FeurStagram settings dialog."
    echo ""
    echo "Options:"
    echo "  --clone [PACKAGE]          Rename the app's package ID so the patched"
    echo "                             build installs side-by-side with a stock"
    echo "                             Instagram. PACKAGE defaults to"
    echo "                             com.instagram.android.feurstagram."
    echo ""
    echo "Signing environment variables:"
    echo "  FEURSTAGRAM_KEYSTORE       Path to keystore (default: ./feurstagram.keystore)"
    echo "  FEURSTAGRAM_KEYSTORE_PASS  Keystore password (required)"
    echo "  FEURSTAGRAM_KEY_ALIAS      Key alias (default: feurstagram)"
    echo "  FEURSTAGRAM_KEY_PASS       Key password (default: same as keystore password)"
}

INPUT_APK=""

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --clone)
            CLONE_MODE=1
            # Accept an optional package name argument. If the next arg is
            # missing or looks like another flag/file, fall back to the default.
            if [ $# -gt 1 ] && [[ "$2" != -* ]] && [[ "$2" != *.apk ]]; then
                CLONE_PACKAGE="$2"
                shift
            fi
            ;;
        *)
            if [ -z "$INPUT_APK" ]; then
                INPUT_APK="$1"
            else
                echo -e "${RED}Error: Unexpected argument: $1${NC}"
                usage
                exit 1
            fi
            ;;
    esac
    shift
done

if [ -z "$INPUT_APK" ]; then
    usage
    exit 1
fi
if [ ! -f "$INPUT_APK" ]; then
    echo -e "${RED}Error: File not found: $INPUT_APK${NC}"
    exit 1
fi

check_dependencies
patch_apk "$INPUT_APK"
