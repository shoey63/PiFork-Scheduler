#!/system/bin/sh
# - wrapper.sh: executes update_pifork.sh from the Termux home directory 
# - Uses Numeric UIDs for maximum ROM compatibility
# - Uses Subshells to contain environment variables
# - Prevents library poisoning

# 1. Termux Constants
TERMUX_HOME="/data/data/com.termux/files/home"
TERMUX_BIN="/data/data/com.termux/files/usr/bin"
TERMUX_LIB="/data/data/com.termux/files/usr/lib"
SCRIPT_PATH="$TERMUX_HOME/update_pifork.sh"
LOG_FILE="/data/adb/modules/pifork-scheduler/run.log"

# 2. Get User ID (Numeric is safer than Name)
# %u guarantees a number like 10123, avoiding name lookup issues
TERMUX_UID=$(stat -c '%u' "$TERMUX_HOME")

if [ -z "$TERMUX_UID" ]; then
    echo "[$(date)] ❌ Error: Could not detect Termux UID." >> "$LOG_FILE"
    exit 1
fi

# 3. Extract Token using 'gh' (As User UID)
# We use the numeric UID directly with su
TOKEN=$(su "$TERMUX_UID" -c "export HOME=$TERMUX_HOME; export LD_LIBRARY_PATH=$TERMUX_LIB; $TERMUX_BIN/gh auth token")

if [ -z "$TOKEN" ]; then
    echo "[$(date)] ❌ Error: Could not fetch token via 'gh'." >> "$LOG_FILE"
    exit 1
fi

echo "[$(date)] Cron fired. Token extracted. Running update..." >> "$LOG_FILE"

# 4. Execute in Subshell (Containment)
# The ( ) parenthesis create a temporary environment.
# Variables exported here WILL NOT leak to the main system or persist.
(
    # Root temp environment
    export HOME="/data/local/tmp/pifork_root_home"
    mkdir -p "$HOME"
    export TMPDIR="$HOME"

    # Inject Credentials & Libraries ONLY for this block
    export GH_TOKEN="$TOKEN"
    export PATH=$PATH:$TERMUX_BIN
    export LD_LIBRARY_PATH=$TERMUX_LIB

    # Run the update
    "$TERMUX_BIN/bash" "$SCRIPT_PATH" >> "$LOG_FILE" 2>&1
    
    # When this block ends, GH_TOKEN and LD_LIBRARY_PATH vanish instantly.
)
