#!/bin/bash
set -uo pipefail

LIMIT=90
SCRIPT_PATH="/usr/local/sbin/set-battery-limit.sh"
SERVICE_NAME="set-battery-limit.service"

SUPPORTED=0
for bat in /sys/class/power_supply/BAT*; do
  [ -e "$bat/charge_control_end_threshold" ] && SUPPORTED=1
done

if [ "$SUPPORTED" -eq 0 ]; then
  echo "SEM SUPORTE: nenhuma bateria expõe charge_control_end_threshold."
  echo "Este notebook não suporta limite de carga via sysfs. Considere a versão TLP."
  exit 0
fi

cat > "$SCRIPT_PATH" <<EOF
#!/bin/bash
for bat in /sys/class/power_supply/BAT*; do
  [ -e "\$bat/charge_control_end_threshold" ] && echo $LIMIT > "\$bat/charge_control_end_threshold"
done
EOF
chmod +x "$SCRIPT_PATH"

cat > "/etc/systemd/system/$SERVICE_NAME" <<EOF
[Unit]
Description=Set battery charge limit to ${LIMIT} percent
After=multi-user.target
StartLimitIntervalSec=0

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now "$SERVICE_NAME"

echo "Limite de carga configurado para ${LIMIT}%."
echo "--- verificação ---"
for bat in /sys/class/power_supply/BAT*; do
  echo "$bat -> threshold atual: $(cat $bat/charge_control_end_threshold 2>/dev/null)"
done
