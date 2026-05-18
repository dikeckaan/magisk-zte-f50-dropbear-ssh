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
  ui_print "[*] Mevcut authorized_keys korunuyor:"
  ui_print "    $AUTH_KEYS"
elif [ -n "$FOUND" ]; then
  # New key file found
  if [ -s "$AUTH_KEYS" ]; then
    ui_print "[*] Yeni anahtar dosyasi bulundu: $FOUND"
    ui_print ""
    ui_print "    Vol(+) = Uzerine yaz (mevcutlari sil)"
    ui_print "    Vol(-) = Mevcutlara EKLE"
    ui_print ""
    if chooseport; then
      cp "$FOUND" "$AUTH_KEYS"
      ui_print "[OK] Anahtarlar yeniden yazildi."
    else
      cat "$FOUND" >> "$AUTH_KEYS"
      ui_print "[OK] Anahtarlar mevcutlara eklendi."
    fi
  else
    ui_print "[*] Anahtar dosyasi yukleniyor: $FOUND"
    cp "$FOUND" "$AUTH_KEYS"
    ui_print "[OK] Anahtarlar yuklendi."
  fi
  rm -f "$FOUND"
else
  # No existing keys AND no new key file - abort
  ui_print "[!] HATA: authorized_keys bulunamadi!"
  ui_print ""
  ui_print "Kurulumdan once SSH public key dosyasini"
  ui_print "asagidaki konumlardan birine koyun:"
  for f in $KEY_SEARCH; do
    ui_print "  - $f"
  done
  ui_print ""
  ui_print "Ornek (Mac'ten):"
  ui_print "  adb push ~/.ssh/id_*.pub /sdcard/authorized_keys"
  ui_print ""
  ui_print "Sonra modulu tekrar flashlayin."
  abort "[!] Anahtar dosyasi olmadan kurulum iptal edildi."
fi

chmod 600 "$AUTH_KEYS"
chown 2000:2000 "$AUTH_KEYS" 2>/dev/null

# Set perms on binaries
set_perm "$MODPATH/system/bin/dropbear" 0 2000 0755
set_perm "$MODPATH/system/bin/dropbearkey" 0 2000 0755
set_perm "$MODPATH/system/bin/ssh-login" 0 2000 0755

ui_print ""
ui_print "[OK] Kurulum tamamlandi."
ui_print ""
ui_print "Anahtar dosyasi: $AUTH_KEYS"
ui_print "Baglanma: ssh -p 22222 root@HOST"
ui_print "(force command -> shell user, su ile root'a gec)"
ui_print ""
