#!/usr/bin/env bash
# Instala o greeter Quickshell como tela de login do greetd.
#
# Uso: sudo ./install-greeter.sh
#
# O que faz:
#   1. Copia ./greeter.qml para /etc/greetd/greeter.qml
#   2. Cria /etc/greetd/hyprland.conf (compositor Hyprland só para o greeter)
#   3. Cria /etc/greetd/session.sh (configura XDG dirs e inicia o Hyprland)
#   4. Faz backup de /etc/greetd/config.toml para config.toml.bak
#   5. Atualiza /etc/greetd/config.toml para usar o session.sh
#
# Arquitetura:
#   greetd → session.sh → start-hyprland -- -c /etc/greetd/hyprland.conf
#           → exec-once: quickshell -p /etc/greetd/greeter.qml
#
# O Hyprland atua como compositor que hospeda a superfície do greeter.
# O greeter roda como usuário "greeter" e autentica via Quickshell.Services.Greetd.
#
# Para reverter:
#   sudo mv /etc/greetd/config.toml.bak /etc/greetd/config.toml
#   sudo systemctl restart greetd
#
# Depois de instalar, reinicie o serviço:
#   sudo systemctl restart greetd

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_QML="${SCRIPT_DIR}/greeter.qml"
GREETD_DIR="/etc/greetd"
DEST_QML="${GREETD_DIR}/greeter.qml"
GREETD_CONFIG="${GREETD_DIR}/config.toml"

if [[ ! -f "${SOURCE_QML}" ]]; then
    echo "ERRO: ${SOURCE_QML} não encontrado." >&2
    exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERRO: rode com sudo." >&2
    exit 1
fi

# 1. Copia o greeter
echo "==> Copiando greeter para ${DEST_QML}"
install -m 0644 "${SOURCE_QML}" "${DEST_QML}"

# 2. Config do Hyprland para o greeter
echo "==> Criando ${GREETD_DIR}/hyprland.conf"
install -m 0644 /dev/null "${GREETD_DIR}/hyprland.conf"
cat > "${GREETD_DIR}/hyprland.conf" <<EOF
# Compositor config para o greeter do greetd.
# Roda como usuário "greeter" e hospeda apenas a superfície do quickshell greeter.

monitor = , preferred, auto, auto

env = XDG_CURRENT_DESKTOP,Hyprland

exec-once = quickshell -p ${DEST_QML}

input {
    kb_layout = us
    follow_mouse = 1
}

general {
    border_size = 0
    gaps_in = 0
    gaps_out = 0
}

decoration {
    rounding = 0
    blur {
        enabled = false
    }
}

animations {
    enabled = false
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    force_default_wallpaper = 0
    background_color = 0x000000
}

# Escape hatch: encerra o compositor para o greetd reiniciar o greeter.
bind = CTRL ALT, Delete, exit
EOF

# 3. Script da sessão do greeter
echo "==> Criando ${GREETD_DIR}/session.sh"
install -m 0755 /dev/null "${GREETD_DIR}/session.sh"
cat > "${GREETD_DIR}/session.sh" <<'EOF'
#!/bin/sh
# Comando de sessão do greetd (greeter).
# A conta "greeter" tem home / (somente leitura), então aponta os diretórios
# de estado do XDG para um cache gravável antes de iniciar o compositor.
set -eu

export XDG_CACHE_HOME=/var/cache/qs-greeter/cache
export XDG_STATE_HOME=/var/cache/qs-greeter/state
export XDG_DATA_HOME=/var/cache/qs-greeter/data
export XDG_CONFIG_HOME=/var/cache/qs-greeter/config
mkdir -p "$XDG_CACHE_HOME" "$XDG_STATE_HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"

# Pelo wrapper de watchdog, igual a uma sessão normal.
exec start-hyprland -- -c /etc/greetd/hyprland.conf
EOF

# Cria o diretório de cache gravável pela conta "greeter" (o mkdir no
# session.sh sozinho falharia, pois /var/cache pertence ao root).
echo "==> Criando /var/cache/qs-greeter (dono: greeter)"
install -d -o greeter -g greeter -m 755 /var/cache/qs-greeter

# 4. Backup do config
if [[ -f "${GREETD_CONFIG}" && ! -f "${GREETD_CONFIG}.bak" ]]; then
    echo "==> Backup de ${GREETD_CONFIG}"
    cp "${GREETD_CONFIG}" "${GREETD_CONFIG}.bak"
fi

# 5. Atualiza o config
echo "==> Atualizando ${GREETD_CONFIG}"
cat > "${GREETD_CONFIG}" <<EOF
[terminal]
vt = 1

[default_session]
command = "${GREETD_DIR}/session.sh"
user = "greeter"
EOF

echo
echo "Pronto! Reinicie o greetd para aplicar:"
echo "  sudo systemctl restart greetd"
echo
echo "Para reverter para o tuigreet:"
echo "  sudo mv ${GREETD_CONFIG}.bak ${GREETD_CONFIG}"
echo "  sudo systemctl restart greetd"