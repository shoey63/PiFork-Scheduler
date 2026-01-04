#!/system/bin/sh
# Action.sh - v2.0 (Smart Schedule & Auto-Repair)
MODDIR="/data/adb/modules/pifork-scheduler"
CRON_FILE="$MODDIR/root"
LOG_FILE="$MODDIR/cron.log"
WRAPPER_SCRIPT="$MODDIR/wrapper.sh"

echo "========================================"
echo "   PiFork Scheduler Control      "
echo "========================================"

# --- 1. Robust BusyBox Detection ---
BUSYBOX=""
for path in \
    /data/adb/modules/busybox-ndk/system/bin/busybox \
    /data/adb/magisk/busybox \
    /data/adb/ksu/bin/busybox \
    /data/adb/ap/bin/busybox; do
    if [ -f "$path" ]; then BUSYBOX="$path"; break; fi
done
[ -z "$BUSYBOX" ] && BUSYBOX="busybox"

# --- 2. Helper: Smart Schedule Parser ---
get_schedule_time() {
    # Uses BusyBox awk to decode standard cron syntax
    "$BUSYBOX" awk '
    !/^[ \t]*#/ && NF {
        min=$1; hour=$2; dow=$5;
        
        # Format time (e.g., 4:5 -> 04:05)
        time=sprintf("%02d:%02d", hour, min);
        
        # Decode Day of Week (Field 5)
        if (dow == "*")        label="Daily";
        else if (dow == "0")   label="Sunday Only";
        else if (dow == "7")   label="Sunday Only";
        else if (dow == "1-6") label="Mon-Sat";
        else if (dow == "1-5") label="Mon-Fri";
        else                   label="Day(" dow ")";
        
        print label " @ " time;
    }' "$CRON_FILE" | sort -u
}

# --- 3. Status Check & Toggle ---
PIDS=$("$BUSYBOX" pgrep -f "crond -c $MODDIR")

if [ -n "$PIDS" ]; then
    # === STOPPING ===
    PIDS_CLEAN=$(echo "$PIDS" | tr '\n' ' ')
    echo "🟢 Status: RUNNING (PID: $PIDS_CLEAN)"
    
    # Print parsed schedule
    get_schedule_time | while read line; do echo "🗓️  $line"; done

    echo "----------------------------------------"
    echo "🛑 STOPPING CRON JOB..."
    
    "$BUSYBOX" kill $PIDS
    sleep 1
    
    # Force Kill if stubborn
    if "$BUSYBOX" pgrep -f "crond -c $MODDIR" >/dev/null; then
         echo "⚠️ Force killing stuck process..."
         "$BUSYBOX" kill -9 $("$BUSYBOX" pgrep -f "crond -c $MODDIR")
    fi

    echo ""
    echo "👉 SYSTEM PAUSED."

else
    # === STARTING ===
    echo "🔴 Status: STOPPED"
    echo "----------------------------------------"
    echo "🟢 STARTING CRON JOB..."
    
   # [CRITICAL] Self-Repair Permissions
# crond fails SILENTLY if permissions are wrong. Fix only if needed.

# CRON_FILE: 644 root:root
[ "$("$BUSYBOX" stat -c '%a' "$CRON_FILE" 2>/dev/null)" != "644" ] && \
    chmod 644 "$CRON_FILE"

[ "$("$BUSYBOX" stat -c '%u:%g' "$CRON_FILE" 2>/dev/null)" != "0:0" ] && \
    chown 0:0 "$CRON_FILE"

# WRAPPER_SCRIPT: 755
[ "$("$BUSYBOX" stat -c '%a' "$WRAPPER_SCRIPT" 2>/dev/null)" != "755" ] && \
    chmod 755 "$WRAPPER_SCRIPT"

    # Start Daemon
    "$BUSYBOX" crond -c "$MODDIR" -L "$LOG_FILE"
    
    sleep 1
    NEW_PID=$("$BUSYBOX" pgrep -f "crond -c $MODDIR")
    if [ -n "$NEW_PID" ]; then
        echo "✅ Success! New PID: $NEW_PID"
        
        # Print parsed schedule
        get_schedule_time | while read line; do echo "🗓️  $line"; done
    else
        echo "❌ Error: Failed to start crond."
        echo "   (Check if $CRON_FILE has valid syntax)"
    fi
fi
echo "========================================"

# --- 4. Smart Exit Logic ---

# Check if running under Magisk (returns version string)
case "$(su -v 2>/dev/null)" in
    *MAGISK*|*magisk*)
        exit 0
        ;;
esac

# Fallback: Pause for KernelSU, APatch, and others.
sleep 4
echo " "
echo "exiting..."
sleep 2
echo " "
echo "✅"
sleep 2

exit 0
