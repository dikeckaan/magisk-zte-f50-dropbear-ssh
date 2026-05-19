#!/system/bin/sh
# Dropbear SSH service — late_start.

DATADIR=/data/ssh
MOUNTDIR=/dev/ssh
KEYDIR="$MOUNTDIR/keys"
LOG="$DATADIR/dropbear.log"
PIDFILE="$DATADIR/dropbear.pid"
BIN=/system/bin/dropbear
KEYGEN=/system/bin/dropbearkey
WRAPPER=/system/bin/ssh-login
PORT=22222

mkdir -p "$DATADIR" "$DATADIR/keys"
chmod 700 "$DATADIR" "$DATADIR/keys"

# bin-utils v1.3.0+ provides lib/common.sh (hard requirement).
. /data/adb/modules/bin-utils/lib/common.sh

# Bind mount /data/ssh -> /dev/ssh to satisfy dropbear's parent-dir
# permission walk (/data is group-writable, /dev is not).
mkdir -p "$MOUNTDIR"
if ! mountpoint -q "$MOUNTDIR" 2>/dev/null; then
    mount --bind "$DATADIR" "$MOUNTDIR" 2>/dev/null
fi

# Generate host keys on first boot.
[ -f "$DATADIR/keys/rsa" ]     || "$KEYGEN" -t rsa     -f "$DATADIR/keys/rsa"     >/dev/null 2>&1
[ -f "$DATADIR/keys/ecdsa" ]   || "$KEYGEN" -t ecdsa   -f "$DATADIR/keys/ecdsa"   >/dev/null 2>&1
[ -f "$DATADIR/keys/ed25519" ] || "$KEYGEN" -t ed25519 -f "$DATADIR/keys/ed25519" >/dev/null 2>&1

# Wait for authorized_keys to be populated (cap at 5 min).
wait_for_file "$DATADIR/authorized_keys" 300 5 || {
    log_line "FATAL: no authorized_keys after 5 min — refusing to start unauthenticated sshd"
    exit 1
}
chmod 600 "$DATADIR/authorized_keys"

# Supervisor loop. Dropbear's -F keeps it in the foreground so the wait
# below blocks until the daemon exits.
(
    while true; do
        log_rotate 1048576
        log_line "starting dropbear on port $PORT"
        "$BIN" -F -E -s -g \
            -D "$MOUNTDIR" \
            -c "$WRAPPER" \
            -r "$KEYDIR/rsa" \
            -r "$KEYDIR/ecdsa" \
            -r "$KEYDIR/ed25519" \
            -p "$PORT" \
            -P "$PIDFILE" \
            -K 60 \
            >> "$LOG" 2>&1
        log_line "dropbear exited rc=$?, restarting in 5s"
        sleep 5
    done
) &
