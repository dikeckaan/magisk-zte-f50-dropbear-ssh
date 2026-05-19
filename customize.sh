#!/system/bin/sh

DATADIR=/data/ssh
AUTH_KEYS="$DATADIR/authorized_keys"
KEY_SEARCH="/sdcard/authorized_keys /sdcard/Download/authorized_keys /data/local/tmp/authorized_keys"

ui_print ""
ui_print "=================================="
ui_print "  Dropbear SSH Server v1.0.0"
ui_print "  Port: 22222"
ui_print "  Auth: SSH key only"
ui_print "  Login: shell (su for root)"
ui_print "=================================="
ui_print ""

# Hard dependency: bin-utils v1.3.0+ for lib/common.sh.
if [ ! -r /data/adb/modules/bin-utils/lib/common.sh ] \
   && [ ! -r /data/adb/modules_update/bin-utils/lib/common.sh ]; then
    ui_print "[!] HATA: bin-utils v1.3.0+ kurulu degil (lib/common.sh yok)."
    abort "[!] Missing dependency: bin-utils v1.3.0+"
fi

mkdir -p "$DATADIR"

# Look for a key file placed by the user
FOUND=""
for f in $KEY_SEARCH; do
  if [ -s "$f" ]; then
    FOUND="$f"
    break
  fi
done

if [ -s "$AUTH_KEYS" ] && [ -z "$FOUND" ]; then
  # Existing install, no new key provided - keep existing
  ui_print "[*] Keeping existing authorized_keys:"
  ui_print "    $AUTH_KEYS"
elif [ -n "$FOUND" ]; then
  # New key file found
  if [ -s "$AUTH_KEYS" ]; then
    ui_print "[*] New key file found: $FOUND"
    ui_print ""
    ui_print "    Vol(+) = Overwrite (remove existing)"
    ui_print "    Vol(-) = Append to existing"
    ui_print ""
    if chooseport; then
      cp "$FOUND" "$AUTH_KEYS"
      ui_print "[OK] Keys overwritten."
    else
      cat "$FOUND" >> "$AUTH_KEYS"
      ui_print "[OK] Keys appended to existing."
    fi
  else
    ui_print "[*] Loading key file: $FOUND"
    cp "$FOUND" "$AUTH_KEYS"
    ui_print "[OK] Keys installed."
  fi
  rm -f "$FOUND"
else
  # No existing keys AND no new key file - abort
  ui_print "[!] ERROR: authorized_keys not found!"
  ui_print ""
  ui_print "Before installing, place your SSH public key at"
  ui_print "one of the following locations:"
  for f in $KEY_SEARCH; do
    ui_print "  - $f"
  done
  ui_print ""
  ui_print "Example (from your Mac):"
  ui_print "  adb push ~/.ssh/id_*.pub /sdcard/authorized_keys"
  ui_print ""
  ui_print "Then re-flash the module."
  abort "[!] Aborted: no key file provided."
fi

chmod 600 "$AUTH_KEYS"
chown 2000:2000 "$AUTH_KEYS" 2>/dev/null

# Set perms on binaries
set_perm "$MODPATH/system/bin/dropbear" 0 2000 0755
set_perm "$MODPATH/system/bin/dropbearkey" 0 2000 0755
set_perm "$MODPATH/system/bin/ssh-login" 0 2000 0755

ui_print ""
ui_print "[OK] Installation complete."
ui_print ""
ui_print "Key file: $AUTH_KEYS"
ui_print "Connect:  ssh -p 22222 root@HOST"
ui_print "(force-command -> shell user, then 'su' for root)"
ui_print ""
