#!/system/bin/sh
SKIPUNZIP=1

ui_print "*******************************"
ui_print "      PIFork Scheduler    "
ui_print "*******************************"

# 1. Extract Module Files
ui_print "- Extracting module files..."
unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >&2

# 2. Define Paths
TERMUX_HOME="/data/data/com.termux/files/home"
SOURCE_SCRIPT="$MODPATH/update_pifork.sh"
TARGET_SCRIPT="$TERMUX_HOME/update_pifork.sh"

# 3. Inject Script into Termux
if [ -d "$TERMUX_HOME" ]; then
    ui_print "- Termux detected!"
    ui_print "- Installing update_pifork.sh to home..."

    # Copy file
    cp -f "$SOURCE_SCRIPT" "$TARGET_SCRIPT"

    # Detect Termux User ID & Group ID (NUMERIC IS SAFER)
    # %u = User ID (e.g. 10123), %g = Group ID
    TERMUX_UID=$(stat -c '%u' "$TERMUX_HOME")
    TERMUX_GID=$(stat -c '%g' "$TERMUX_HOME")

    # Set Permissions
    # We use the numbers directly. chown 10123:10123 works perfectly.
    chown "$TERMUX_UID:$TERMUX_GID" "$TARGET_SCRIPT"
    chmod 755 "$TARGET_SCRIPT"
    
    ui_print "- Script installed (Owner: $TERMUX_UID)."
else
    ui_print "! Termux NOT detected."
    ui_print "! Please install Termux and move update_pifork.sh manually."
fi

# 4. Set Module Permissions
ui_print "- Setting module permissions..."

# This line sets ALL files (including 'root') to 644 (Read/Write).
# This is exactly what crond wants for the schedule file.
set_perm_recursive "$MODPATH" 0 0 0755 0644

# These lines promote specific scripts to 755 (Executable).
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/wrapper.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
# Note: update_pifork.sh inside the module doesn't strictly need 755 
# since we only run the copy inside Termux, but it doesn't hurt.
set_perm "$MODPATH/update_pifork.sh" 0 0 0755
