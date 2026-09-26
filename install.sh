#!/usr/bin/env bash
# Instalador para Arch/CachyOS, outras distribuições Linux e Android/Termux.
set -euo pipefail

VERSION="1.1.0"
REPO_RAW="https://raw.githubusercontent.com/stack-Error404/yt-downloader-cli"
REPO_REF="${YT_REPO_REF:-v$VERSION}"
SCRIPT_PATH="${BASH_SOURCE[0]:-}"

case "${1:-}" in
    -h|--help)
        cat <<EOF
Instalador do Error404 // Media Console v$VERSION

Uso: bash install.sh [--help | --version]

Variáveis opcionais:
  YT_REPO_REF        Tag ou commit usado no download remoto (padrão: v$VERSION)
  YT_SCRIPT_URL      URL alternativa do script yt
  YT_SCRIPT_SHA256   SHA-256 esperado ao usar uma URL alternativa
EOF
        exit 0
        ;;
    -v|--version) printf 'install.sh %s\n' "$VERSION"; exit 0 ;;
    '') ;;
    *) printf 'Erro: argumento desconhecido: %s\n' "$1" >&2; exit 2 ;;
esac
if (($# > 1)); then
    printf 'Erro: argumentos demais.\n' >&2
    exit 2
fi

if [[ -z "${HOME:-}" ]]; then
    printf 'Erro: a variável HOME não está definida.\n' >&2
    exit 1
fi

if [[ -n "${TERMUX_VERSION:-}" && -n "${PREFIX:-}" ]]; then
    INSTALL_DIR="$PREFIX/bin"
else
    INSTALL_DIR="$HOME/.local/bin"
fi
TARGET="$INSTALL_DIR/yt"

install_dependencies() {
    if command -v yt-dlp >/dev/null 2>&1 && command -v ffmpeg >/dev/null 2>&1; then
        return
    fi
    printf 'Instalando dependências ausentes...\n'
    if [[ -n "${TERMUX_VERSION:-}" ]] && command -v pkg >/dev/null 2>&1; then
        pkg install -y python-yt-dlp ffmpeg
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed yt-dlp ffmpeg
    else
        printf 'Instale yt-dlp e ffmpeg pelo gerenciador da sua distribuição e execute novamente.\n' >&2
        exit 1
    fi
}

verify_sha256() {
    local file=$1 expected=$2 actual
    command -v sha256sum >/dev/null 2>&1 || {
        printf 'sha256sum é necessário para verificar a integridade do download.\n' >&2
        exit 1
    }
    actual=$(sha256sum "$file")
    actual=${actual%% *}
    if [[ "$actual" != "$expected" ]]; then
        printf 'Falha de integridade: SHA-256 inesperado para yt.\n' >&2
        exit 1
    fi
}

install_dependencies
mkdir -p -- "$INSTALL_DIR"
tmp=$(mktemp "$INSTALL_DIR/.yt.XXXXXXXX")
checksum_tmp=$(mktemp "$INSTALL_DIR/.yt-checksums.XXXXXXXX")
trap 'rm -f -- "$tmp" "$checksum_tmp"' EXIT

script_dir=''
if [[ -n "$SCRIPT_PATH" && -f "$SCRIPT_PATH" ]]; then
    script_dir=$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd -P)
fi

if [[ -n "$script_dir" && -f "$script_dir/yt" ]]; then
    cp -- "$script_dir/yt" "$tmp"
    if [[ -f "$script_dir/checksums.sha256" ]]; then
        expected=$(awk '$2 == "yt" { print $1; exit }' "$script_dir/checksums.sha256")
        [[ -n "$expected" ]] && verify_sha256 "$tmp" "$expected"
    fi
else
    command -v curl >/dev/null 2>&1 || { printf 'Instale curl para usar a instalação remota.\n' >&2; exit 1; }
    base_url="$REPO_RAW/$REPO_REF"
    curl -fL --retry 2 --proto '=https' --tlsv1.2 "${YT_SCRIPT_URL:-$base_url/yt}" -o "$tmp"
    if [[ -n "${YT_SCRIPT_SHA256:-}" ]]; then
        expected=$YT_SCRIPT_SHA256
    else
        curl -fL --retry 2 --proto '=https' --tlsv1.2 "$base_url/checksums.sha256" -o "$checksum_tmp"
        expected=$(awk '$2 == "yt" { print $1; exit }' "$checksum_tmp")
    fi
    [[ -n "${expected:-}" ]] || { printf 'Checksum de yt não encontrado.\n' >&2; exit 1; }
    verify_sha256 "$tmp" "$expected"
fi

bash -n "$tmp"
chmod 755 "$tmp"
mv -f -- "$tmp" "$TARGET"
trap - EXIT
rm -f -- "$checksum_tmp"

path_line="export PATH=\"\$HOME/.local/bin:\$PATH\""
if [[ "$INSTALL_DIR" == "$HOME/.local/bin" ]]; then
    case "$(basename "${SHELL:-/bin/bash}")" in
        fish)
            if command -v fish >/dev/null 2>&1; then fish -c 'fish_add_path -U ~/.local/bin'; fi ;;
        zsh)
            touch "$HOME/.zshrc"
            grep -Fxq "$path_line" "$HOME/.zshrc" 2>/dev/null || printf '\n%s\n' "$path_line" >> "$HOME/.zshrc" ;;
        bash)
            touch "$HOME/.bashrc"
            grep -Fxq "$path_line" "$HOME/.bashrc" 2>/dev/null || printf '\n%s\n' "$path_line" >> "$HOME/.bashrc" ;;
        *)
            printf 'Aviso: adicione %s ao PATH do seu shell manualmente.\n' "$INSTALL_DIR" >&2 ;;
    esac
fi

printf '\nError404 // Media Console v%s instalado em: %s\n' "$VERSION" "$TARGET"
printf 'Abra um novo terminal e execute: yt\n'
