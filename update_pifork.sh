#!/data/data/com.termux/files/usr/bin/bash

# =========================================================
#  Termux-PIFork Updater
#
#  - Finds latest successful CI run (single Run ID)
#  - Downloads exactly one artifact
#  - Installs into Magisk module path
#  - Fixes permissions idempotently
#  - Runs latest autopif*.sh with -m
#
#  Designed for:
#   - Termux user context
#   - Root execution via su
#   - Android (toybox / BusyBox realities)
# =========================================================

# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------
REPO="osm0sis/PlayIntegrityFork"
MODULE_PATH="/data/adb/modules/playintegrityfix"
TEMP_DIR="$HOME/.pifork_update_cache"

echo "==========================================================="
echo "           Termux-PIFork Updater"
echo "==========================================================="

# ---------------------------------------------------------
# 1. Clean workspace
# ---------------------------------------------------------
echo "🧹 Cleaning up workspace..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# ---------------------------------------------------------
# 2. Find latest successful CI run
# ---------------------------------------------------------
echo "🔍 Looking for latest successful build..."
RUN_ID=$(
    gh run list \
        --repo "$REPO" \
        --status success \
        --branch main \
        --limit 1 \
        --json databaseId \
        --jq '.[0].databaseId'
)

if [ -z "$RUN_ID" ]; then
    echo "❌ Error: Could not find a successful run."
    exit 1
fi

echo "✅ Found Run ID: $RUN_ID"

# ---------------------------------------------------------
# 3. Download artifact from that run
# ---------------------------------------------------------
echo "⬇️  Downloading artifact from Run #$RUN_ID..."
if ! gh run download "$RUN_ID" \
        --repo "$REPO" \
        --pattern "PlayIntegrityFork-CI*" \
        --dir "$TEMP_DIR"; then
    echo "❌ Error: Download failed."
    exit 1
fi

# ---------------------------------------------------------
# 4. Locate latest autopif script inside artifact (by mtime)
# ---------------------------------------------------------
FOUND_SCRIPT=$(ls -t "$TEMP_DIR"/**/autopif*.sh 2>/dev/null | head -n 1)

if [ -z "$FOUND_SCRIPT" ]; then
    echo "❌ Error: Could not find autopif script in downloaded artifact."
    exit 1
fi

SOURCE_DIR=$(dirname "$FOUND_SCRIPT")
echo "✅ Validated content in: $(basename "$SOURCE_DIR")"

# ---------------------------------------------------------
# 5. Install & execute (root context)
# ---------------------------------------------------------
echo "🛡️  Requesting root to install..."

su -c "
    if [ ! -d \"$MODULE_PATH\" ]; then
        echo \"❌ Error: Module not found at $MODULE_PATH\"
        exit 1
    fi

    echo '   -> Overwriting module files...'
    cp -rf \"$SOURCE_DIR\"/. \"$MODULE_PATH\"/

    echo '   -> Applying permissions...'
    for f in \"$MODULE_PATH\"/*.sh; do
        [ -f \"\$f\" ] || continue
        [ -x \"\$f\" ] || chmod 755 \"\$f\"
    done

    rm -f \"$MODULE_PATH/skip_mount\" \"$MODULE_PATH/disable\"

    # -----------------------------------------------------
    # Run latest autopif script (by modification time)
    # -----------------------------------------------------
    AUTOPIF_SCRIPT=\$(ls -t \"$MODULE_PATH\"/autopif*.sh 2>/dev/null | head -n 1)

    if [ -f \"\$AUTOPIF_SCRIPT\" ]; then
        echo \"🏃 Running: \$(basename \"\$AUTOPIF_SCRIPT\") -m\"
        cd \"$MODULE_PATH\"
        /system/bin/sh \"\$AUTOPIF_SCRIPT\" -m
    else
        echo \"❌ Error: autopif script not found after install.\"
        exit 1
    fi
"

# ---------------------------------------------------------
# 6. Cleanup
# ---------------------------------------------------------
rm -rf "$TEMP_DIR"

echo "==========================================================="
echo "           ✨ Update Complete!"
echo "==========================================================="
