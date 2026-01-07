#!/system/bin/sh
MODDIR=${0%/*}

# ---------------------------------------------------------
# 0. Wait for boot
# ---------------------------------------------------------
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

# ---------------------------------------------------------
# 1. BusyBox Detection (Universal)
# ---------------------------------------------------------
BUSYBOX=""
for path in \
    /data/adb/modules/busybox-ndk/system/bin/busybox \
    /data/adb/magisk/busybox \
    /data/adb/ksu/bin/busybox \
    /data/adb/ap/bin/busybox; do
    if [ -f "$path" ]; then
        BUSYBOX="$path"
        break
    fi
done
[ -z "$BUSYBOX" ] && BUSYBOX="busybox"

# ---------------------------------------------------------
# 2. Permission Enforcer (Self-Repair, Idempotent)
# ---------------------------------------------------------
# Scripts must be executable
for f in service.sh wrapper.sh action.sh; do
    FILE="$MODDIR/$f"
    [ "$("$BUSYBOX" stat -c '%a' "$FILE" 2>/dev/null)" != "755" ] && \
        chmod 755 "$FILE"
done

# Cron file must be readable, NOT executable
CRON_FILE="$MODDIR/root"
[ "$("$BUSYBOX" stat -c '%a' "$CRON_FILE" 2>/dev/null)" != "644" ] && \
    chmod 644 "$CRON_FILE"

# ---------------------------------------------------------
# 3. Cleanup Leftovers (ONLY if multiple versions exist)
# ---------------------------------------------------------
PIF_DIR="/data/adb/modules/playintegrityfix"

# Always start a fresh log entry
echo "--- Boot $(date) ---" > "$MODDIR/cron.log"

if [ -d "$PIF_DIR" ]; then
    cd "$PIF_DIR" || exit 0

    # -----------------------------
    # A. Scripts: autopif*.sh
    # -----------------------------
    SCRIPT_LIST=$("$BUSYBOX" ls -t autopif*.sh 2>/dev/null)
    SCRIPT_COUNT=$(echo "$SCRIPT_LIST" | wc -l)

    if [ "$SCRIPT_COUNT" -gt 1 ]; then
        LATEST_SCRIPT=$(echo "$SCRIPT_LIST" | head -n 1)

        echo "$SCRIPT_LIST" | tail -n +2 | while read -r f; do
            rm -f "$f"
            echo "🧹 Cleanup: Removed old script $f" >> "$MODDIR/cron.log"
        done
    fi

    # -----------------------------
    # B. Directories: autopif*
    # -----------------------------
    DIR_LIST=$("$BUSYBOX" ls -td autopif*/ 2>/dev/null | sed 's:/*$::')
    DIR_COUNT=$(echo "$DIR_LIST" | wc -l)

    if [ "$DIR_COUNT" -gt 1 ]; then
        LATEST_DIR=$(echo "$DIR_LIST" | head -n 1)

        echo "$DIR_LIST" | tail -n +2 | while read -r d; do
            rm -rf "$d"
            echo "🧹 Cleanup: Removed old folder $d" >> "$MODDIR/cron.log"
        done
    fi
fi

# ---------------------------------------------------------
# 4. Start Scheduler
# ---------------------------------------------------------
"$BUSYBOX" crond -c "$MODDIR" -L "$MODDIR/cron.log"
