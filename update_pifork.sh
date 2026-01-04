#!/data/data/com.termux/files/usr/bin/bash

# =========================================================
#  Termux-PIFork Updater
#  1. Finds exact Run ID (No multi-download)
#  2. Runs autopif with -m (Match Device)
#  3. Enforces clean Magisk permissions
# =========================================================

# --- Configuration ---
REPO="osm0sis/PlayIntegrityFork"
MODULE_PATH="/data/adb/modules/playintegrityfix"
TEMP_DIR="$HOME/.pifork_update_cache"

echo "==========================================================="
echo "           Termux-PIFork Updater"
echo "==========================================================="

# 1. Clean Workspace
# We wipe it fresh to prevent mixing old zip contents
echo "🧹 Cleaning up workspace..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# 2. Find Latest Successful Run ID
echo "🔍 Looking for latest successful build..."
RUN_ID=$(gh run list --repo "$REPO" --status success --branch main --limit 1 --json databaseId --jq '.[0].databaseId')

if [ -z "$RUN_ID" ]; then
    echo "❌ Error: Could not find a successful run."
    exit 1
fi
echo "✅ Found Run ID: $RUN_ID"

# 3. Download Specific Artifact
echo "⬇️  Downloading artifact from Run #$RUN_ID..."
if ! gh run download "$RUN_ID" --repo "$REPO" --pattern "PlayIntegrityFork-CI*" --dir "$TEMP_DIR"; then
    echo "❌ Error: Download failed."
    exit 1
fi

# 4. Smart Detect
FOUND_SCRIPT=$(find "$TEMP_DIR" -name "autopif*.sh" | head -n 1)
if [ -z "$FOUND_SCRIPT" ]; then
    echo "❌ Error: Could not find autopif script in download."
    exit 1
fi

SOURCE_DIR=$(dirname "$FOUND_SCRIPT")
echo "✅ Validated content in: $(basename "$SOURCE_DIR")"

# 5. Install & Execute (Root Mode)
echo "🛡️  Requesting Root to install..."
# We pass the variables into the SU block
su -c "
    if [ ! -d \"$MODULE_PATH\" ]; then
        echo \"❌ Error: Module not found at $MODULE_PATH\"
        exit 1
    fi

    echo '   -> Overwriting module files...'
    cp -rf \"$SOURCE_DIR/\"* \"$MODULE_PATH/\"

    echo '   -> Applying permissions...'
    # 1. Make scripts executable
    for f in "$MODULE_PATH"/*.sh; do
        [ -f "$f" ] && [ ! -x "$f" ] && chmod 755 "$f"
    done
    
    # 2. Clean up junk
    rm -f \"$MODULE_PATH/skip_mount\" \"$MODULE_PATH/disable\"

    # --- Run autopif with -m ---
    # Find the script again inside the installed path
    AUTOPIF_SCRIPT=\$(find \"$MODULE_PATH\" -maxdepth 1 -name \"autopif*.sh\" | sort -r | head -n 1)
    
    if [ -f \"\$AUTOPIF_SCRIPT\" ]; then
        echo \"🏃 Running: \$(basename \"\$AUTOPIF_SCRIPT\") -m\"
        cd \"$MODULE_PATH\"
        # Note: 'sh' can run 644 scripts, but we made it 755 above anyway.
        sh \"\$AUTOPIF_SCRIPT\" -m
    else
        echo \"❌ Error: autopif script not found.\"
    fi
"

# 6. Cleanup
# Remove the cache to save space
rm -rf "$TEMP_DIR"

echo "============================================================"
echo "           ✨ Update Complete!"
echo "============================================================"
