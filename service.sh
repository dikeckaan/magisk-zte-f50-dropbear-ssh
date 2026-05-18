#!/system/bin/sh
# Dropbear SSH service - runs after boot in late_start service mode

DATADIR=/data/ssh
MOUNTDIR=/dev/ssh
KEYDIR="$MOUNTDIR/keys"
AUTH_KEYS="$MOUNTDIR/authorized_keys"
LOGFILE="$DATADIR/dropbear.log"
LOG_MAX_BYTES=1048576
PIDFILE="$DATADIR/dropbear.pid"
BIN=/system/bin/dropbear
KEYGEN=/system/bin/dropbearkey
WRAPPER=/system/bin/ssh-login
PORT=22222

mkdir -p "$DATADIR" "$DATADIR/keys"
chmod 700 "$DATADIR" "$DATADIR/keys"

# Bind mount /data/ssh -> /dev/ssh to satisfy dropbear's parent dir
# permission walk (/data is group-writable, /dev is not).
mkdir -p "$MOUNTDIR"
if ! mountpoint -q "$MOUNTDIR" 2>/dev/null; then
  mount --bind "$DATADIR" "$MOUNTDIR" 2>/dev/null
fi

# Generate host keys on first boot
[ -f "$DATADIR/keys/rsa" ]     || "$KEYGEN" -t rsa     -f "$DATADIR/keys/rsa"     >/dev/null 2>&1
[ -f "$DATADIR/keys/ecdsa" ]   || "$KEYGEN" -t ecdsa   -f "$DATADIR/keys/ecdsa"   >/dev/null 2>&1
[ -f "$DATADIR/keys/ed25519" ] || "$KEYGEN" -t ed25519 -f "$DATADIR/keys/ed25519" >/dev/null 2>&1

# Wait until authorized_keys exists (max 5 min)
i=0
while [ ! -s "$DATADIR/authorized_keys" ]; do
  i=$((i+1))
  [ $i -ge 60 ] && exit 1
  sleep 5
done
chmod 600 "$DATADIR/authorized_keys"

# Supervisor loop
(
  while true; do
    if [ -f "$LOGFILE" ]; then
      size=$(stat -c %s "$LOGFILE" 2>/dev/null || echo 0)
      if [ "$size" -gt "$LOG_MAX_BYTES" ]; then
        mv "$LOGFILE" "$LOGFILE.1"
      fi
    fi

    echo "[$(date)] starting dropbear on port $PORT" >> "$LOGFILE"

    # -F: don't fork (so we can supervise)
    # -E: log to stderr
    # -s: disable password auth (keys only)
    # -g: disable password auth for root
    # -D: directory containing authorized_keys (uses bind-mounted /dev/ssh)
    # -c: force command wrapper (drops to shell user)
    # -r: hostkey files
    # -p: listen port
    # -P: pid file
    # -K: keepalive seconds
    "$BIN" -F -E -s -g \
      -D "$MOUNTDIR" \
      -c "$WRAPPER" \
      -r "$KEYDIR/rsa" \
      -r "$KEYDIR/ecdsa" \
      -r "$KEYDIR/ed25519" \
      -p "$PORT" \
      -P "$PIDFILE" \
      -K 60 \
      >> "$LOGFILE" 2>&1

    echo "[$(date)] dropbear exited rc=$?, restarting in 5s" >> "$LOGFILE"
    sleep 5
  done
) &
