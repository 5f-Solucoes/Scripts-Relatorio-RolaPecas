#!/bin/bash
set -uo pipefail

BINARIOS="/usr/bin/wget"

echo "=== Bloqueio de execução via AppArmor ==="
apt-get install -y -o DPkg::Lock::Timeout=120 apparmor-utils >/dev/null 2>&1 || true

FALHAS=0

for TARGET in $BINARIOS; do
  if [ ! -x "$TARGET" ]; then
    echo "[$TARGET] não existe nesta máquina — ignorado."
    continue
  fi

  PROFILE="/etc/apparmor.d/$(echo "${TARGET#/}" | tr '/' '.')"

  # Perfil VAZIO: AppArmor nega tudo por padrão.
  # Sem abstractions/base, o binário não carrega a libc -> não executa.
  cat > "$PROFILE" <<EOF
#include <tunables/global>

$TARGET {
  # intencionalmente sem regras: nega tudo (deny by default)
}
EOF

  # Carrega mostrando o erro, se houver
  if ! apparmor_parser -r "$PROFILE" 2>&1; then
    echo "[$TARGET] ERRO ao carregar o perfil (veja a mensagem acima)."
    FALHAS=1
    continue
  fi

  aa-enforce "$TARGET" >/dev/null 2>&1 || true

  # Verificação real: o binário ainda executa?
  if "$TARGET" --version >/dev/null 2>&1; then
    echo "[$TARGET] FALHA: ainda executa — bloqueio NÃO efetivo."
    FALHAS=1
  else
    echo "[$TARGET] OK: execução bloqueada."
  fi
done

echo "--- perfis carregados ---"
aa-status 2>/dev/null | grep -i wget || echo "(nenhum perfil wget listado)"

exit $FALHAS
