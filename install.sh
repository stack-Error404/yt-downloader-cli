#!/usr/bin/env bash
# Instalação local ou em uma linha pelo GitHub.
set -euo pipefail

INSTALL_DIR="${HOME}/.local/bin"
REPO_RAW="https://raw.githubusercontent.com/stack-Error404/yt-downloader-cli/main"
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
TARGET="$INSTALL_DIR/yt"

if ! command -v pacman >/dev/null 2>&1; then
    printf 'Este instalador foi feito para CachyOS/Arch Linux (pacman).\n' >&2
    exit 1
fi

if ! command -v yt-dlp >/dev/null 2>&1 || ! command -v ffmpeg >/dev/null 2>&1; then
    printf 'Instalando yt-dlp e ffmpeg...\n'
    sudo pacman -S --needed yt-dlp ffmpeg
fi

mkdir -p -- "$INSTALL_DIR"
tmp="$(mktemp "$INSTALL_DIR/.yt.XXXXXXXX")"
trap 'rm -f -- "$tmp"' EXIT

if [[ -f "$SCRIPT_PATH" && "$(basename -- "$SCRIPT_PATH")" == install.sh && -f "$(dirname -- "$SCRIPT_PATH")/yt" ]]; then
    cp -- "$(dirname -- "$SCRIPT_PATH")/yt" "$tmp"
else
    command -v curl >/dev/null 2>&1 || { printf 'Instale curl para usar a instalação remota.\n' >&2; exit 1; }
    curl -fL --retry 2 --proto '=https' --tlsv1.2 "${YT_SCRIPT_URL:-$REPO_RAW/yt}" -o "$tmp"
fi

bash -n "$tmp"
chmod 755 "$tmp"
mv -f -- "$tmp" "$TARGET"
trap - EXIT

# As configurações ficam disponíveis em um novo terminal.
path_line='export PATH="$HOME/.local/bin:$PATH"'
case "$(basename "${SHELL:-/bin/bash}")" in
    fish)
        if command -v fish >/dev/null 2>&1; then fish -c 'fish_add_path -U ~/.local/bin'; fi ;;
    zsh)
        touch "$HOME/.zshrc"
        grep -Fxq "$path_line" "$HOME/.zshrc" 2>/dev/null || printf '\n%s\n' "$path_line" >> "$HOME/.zshrc" ;;
    *)
        touch "$HOME/.bashrc"
        grep -Fxq "$path_line" "$HOME/.bashrc" 2>/dev/null || printf '\n%s\n' "$path_line" >> "$HOME/.bashrc" ;;
esac

printf '\nInstalado em: %s\n' "$TARGET"
printf 'O menu vai abrir agora. Nos próximos terminais, execute: yt\n\n'
exec "$TARGET"
