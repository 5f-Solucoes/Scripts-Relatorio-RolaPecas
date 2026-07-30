#!/bin/bash
set -uo pipefail

CONF="/etc/modprobe.d/99-disable-usb-storage.conf"

cat > "$CONF" <<'EOF'
blacklist usb-storage
blacklist uas
install usb-storage /bin/false
install uas /bin/false
EOF

modprobe -r uas 2>/dev/null || true
modprobe -r usb-storage 2>/dev/null || true

if ! update-initramfs -u; then
    echo "AVISO: update-initramfs retornou erro, mas a config foi escrita em $CONF"
fi

echo "USB mass storage bloqueado. Efeito pleno após reboot."
echo "--- verificação ---"
cat "$CONF"
lsmod | grep -i usb_storage || echo "usb-storage NAO carregado (ok)"
