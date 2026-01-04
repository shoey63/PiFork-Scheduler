#!/system/bin/sh
MODDIR=${0%/*}

# Wait for boot
while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done

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
# Fix permissions ONLY if incorrect (crond is very picky)

# Scripts: must be 755
for f in service.sh wrapper.sh action.sh; do
    FILE="$MODDIR/$f"
    [ "$("$BUSYBOX" stat -c '%a' "$FILE" 2>/dev/null)" != "755" ] && \
        chmod 755 "$FILE"
done

# Cron file: must be readable, NOT executable (644)
CRON_FILE="$MODDIR/root"
[ "$("$BUSYBOX" stat -c '%a' "$CRON_FILE" 2>/dev/null)" != "644" ] && \
    chmod 644 "$CRON_FILE"

# ---------------------------------------------------------
# 3. Start Scheduler
# ---------------------------------------------------------

echo "--- Boot $(date) ---" > "$MODDIR/cron.log"

"$BUSYBOX" crond -c "$MODDIR" -L "$MODDIR/cron.log"
