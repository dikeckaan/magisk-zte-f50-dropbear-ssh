#!/system/bin/sh

pkill -f /system/bin/dropbear 2>/dev/null
pkill -f "service.sh" 2>/dev/null
killall dropbear 2>/dev/null

# Unmount bind mount
umount /dev/ssh 2>/dev/null
rmdir /dev/ssh 2>/dev/null

# Keep /data/ssh (host keys + authorized_keys) for reinstall.
# Manual cleanup: rm -rf /data/ssh
