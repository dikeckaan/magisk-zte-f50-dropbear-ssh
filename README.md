# Dropbear SSH Server - Magisk Module v1

Android cihazda Dropbear SSH server'i 22222 portunda calistirir. Sadece SSH key authentication, sifre kapali.

**Login akisi:** `ssh root@HOST` ile baglan (key auth) → force command sayesinde otomatik `shell` user'a dusulur → `su` ile root'a geri donulur.

## Kurulum

1. (Opsiyonel) Public key dosyani asagidaki konumlardan birine kaydet:
   - `/sdcard/authorized_keys`
   - `/sdcard/Download/authorized_keys`
   - `/data/local/tmp/authorized_keys`

   Eger dosya yoksa, module icindeki gomulu varsayilan anahtar kullanilir.

2. Magisk Manager'dan modulu flashla.

3. Cihazi yeniden baslat.

## Baglanma

```bash
ssh -p 22222 root@HOST
```

Cloudflared tunnel ile:
```bash
ssh -o ProxyCommand="cloudflared access ssh --hostname <your-ssh-hostname>" root@<your-ssh-hostname>
```

Login sonrasi `shell` user olarak olursun. `su` ile root'a gec.

Root yetkisi icin:
```
$ su
```

## Ozellikler

- Boot sonrasi otomatik baslama
- Host keys ilk boot'ta otomatik olusur (`/data/ssh/keys/`)
- Sadece key auth (sifre tamamen kapali, `-s -g`)
- Force-command wrapper ile login otomatik `shell` user'a duser
- Keepalive 60s
- Log rotation (max 1 MB)
- Supervisor loop (crash sonrasi 5s'de restart)
- `/data/ssh` -> `/dev/ssh` bind mount (dropbear parent dir permission check icin)

## Dosya Konumlari

| Dosya | Konum |
|-------|-------|
| authorized_keys | `/data/ssh/authorized_keys` |
| Host keys | `/data/ssh/keys/{rsa,ecdsa,ed25519}` |
| Log | `/data/ssh/dropbear.log` |
| PID | `/data/ssh/dropbear.pid` |
| Binaries | `/system/bin/{dropbear,dropbearkey}` |

## Anahtar Yonetimi

Yeni anahtar eklemek icin authorized_keys dosyasini bir yere koyup modulu yeniden flashla:
- Vol(+) = Uzerine yaz
- Vol(-) = Mevcutlara ekle

Elle: `echo "ssh-rsa ..." >> /data/ssh/authorized_keys`

## Kaldirma

Magisk Manager'dan kaldir. `/data/ssh/` korunur (anahtarlar ve loglar).
Tamamen temizlemek: `rm -rf /data/ssh`

## Binary Kaynak

Dropbear v2026.91, ribbons/android-dropbear repo'sundan
aarch64-linux-android NDK r27 ile statik derlenmis.
