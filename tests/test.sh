#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
tmp_dir=$(mktemp -d)
trap 'rm -rf -- "$tmp_dir"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; }

bash -n "$project_dir/yt" "$project_dir/install.sh"
pass 'sintaxe Bash'

help_output=$("$project_dir/yt" --help)
[[ "$help_output" == *'Uso: yt [opções]'* ]] || fail '--help'
[[ "$("$project_dir/yt" --version)" == 'yt 1.1.2' ]] || fail '--version'
if "$project_dir/yt" --nao-existe >/dev/null 2>&1; then fail 'argumento desconhecido'; fi
if "$project_dir/yt" --download-dir --cookies-from-browser >/dev/null 2>&1; then fail 'valor de pasta interpretado como flag'; fi
if "$project_dir/yt" --cookies-from-browser --download-dir >/dev/null 2>&1; then fail 'valor de navegador interpretado como flag'; fi
[[ "$(bash "$project_dir/install.sh" --version)" == 'install.sh 1.1.2' ]] || fail 'versão do instalador'
bash "$project_dir/install.sh" --help | grep -Fq 'Uso: bash install.sh' || fail 'ajuda do instalador'
if bash "$project_dir/install.sh" --nao-existe >/dev/null 2>&1; then fail 'argumento desconhecido do instalador'; fi
pass 'argumentos do CLI'

fake_bin="$tmp_dir/bin"
mkdir -p -- "$fake_bin"
cat > "$fake_bin/yt-dlp" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" >> "$YT_DLP_LOG"
exit "${YT_DLP_EXIT:-0}"
STUB
cat > "$fake_bin/ffmpeg" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
chmod +x "$fake_bin/yt-dlp" "$fake_bin/ffmpeg"

log="$tmp_dir/yt-dlp.log"
menu_output="$tmp_dir/menu.out"
printf '6\nhttps://www.tiktok.com/@teste/video/123\n0\n' |
    PATH="$fake_bin:$PATH" YT_DLP_LOG="$log" NO_COLOR=1 \
    "$project_dir/yt" --download-dir "$tmp_dir/100% pronto" > "$menu_output"
grep -Fxq -- '--remux-video' "$log" || fail 'TikTok sem remux'
grep -Fxq -- 'https://www.tiktok.com/@teste/video/123' "$log" || fail 'URL do TikTok'
grep -Fq -- '100%% pronto/TikTok/' "$log" || fail 'escape de porcentagem'
if grep -Fxq -- '--recode-video' "$log"; then fail 'recodificação ainda habilitada'; fi
pass 'fluxo TikTok e remux sem recodificação'

: > "$log"
printf '1\nhttps://www.youtube.com/watch?v=teste\n0\n' |
    PATH="$fake_bin:$PATH" YT_DLP_LOG="$log" NO_COLOR=1 \
    "$project_dir/yt" --download-dir "$tmp_dir/videos" > "$menu_output"
grep -Fxq -- '--remux-video' "$log" || fail 'MP4 sem remux'
if grep -Fxq -- '--recode-video' "$log"; then fail 'MP4 ainda recodifica'; fi
pass 'fluxo MP4 sem recodificação'

: > "$log"
printf '1\nhttps://www.instagram.com/reel/teste\n0\n' |
    PATH="$fake_bin:$PATH" YT_DLP_LOG="$log" NO_COLOR=1 \
    "$project_dir/yt" --cookies-from-browser firefox --download-dir "$tmp_dir/instagram" > "$menu_output"
grep -Fxq -- '--cookies-from-browser' "$log" || fail 'cookies não repassados'
grep -Fxq -- 'firefox' "$log" || fail 'navegador dos cookies não repassado'
grep -Fxq -- 'https://www.instagram.com/reel/teste' "$log" || fail 'URL do Instagram'
grep -Fq -- 'Instagram — iniciando...' "$menu_output" || fail 'detecção de Instagram'
pass 'fallback genérico, detecção de plataforma e cookies'

: > "$log"
printf '1\nhttps://www.netflix.com/watch/123\n0\n' |
    PATH="$fake_bin:$PATH" YT_DLP_LOG="$log" NO_COLOR=1 \
    "$project_dir/yt" --download-dir "$tmp_dir/generic" > "$menu_output"
grep -Fq -- 'yt-dlp (detecção automática) — iniciando...' "$menu_output" || fail 'falso positivo na detecção'
pass 'detecção sem falso positivo de domínio'

: > "$log"
printf '1\nhttps://user:pass@www.youtube.com/watch?v=teste\n0\n' |
    PATH="$fake_bin:$PATH" YT_DLP_LOG="$log" NO_COLOR=1 \
    "$project_dir/yt" --download-dir "$tmp_dir/userinfo" > "$menu_output"
grep -Fq -- 'YouTube — iniciando...' "$menu_output" || fail 'detecção com userinfo'
pass 'detecção de host com userinfo'

: > "$log"
printf '10\n1\n\n0\n' |
    PATH="$fake_bin:$PATH" YT_DLP_LOG="$log" NO_COLOR=1 \
    "$project_dir/yt" --download-dir "$tmp_dir/cookies-menu" > "$menu_output"
grep -Fq -- 'Cookies configurados para: firefox' "$menu_output" || fail 'configuração de cookies pelo menu'
pass 'configuração de cookies pelo menu'

printf 'invalida\n\n0\n' |
    PATH="$fake_bin:$PATH" YT_DLP_LOG="$log" NO_COLOR=1 \
    "$project_dir/yt" --download-dir "$tmp_dir/downloads" > "$menu_output"
grep -Fq 'Opção inválida.' "$menu_output" || fail 'entrada inválida do menu'
pass 'entrada inválida do menu'

test_home="$tmp_dir/home"
mkdir -p -- "$test_home"
for run in 1 2; do
    HOME="$test_home" SHELL=/bin/bash PATH="$fake_bin:$PATH" \
        bash "$project_dir/install.sh" </dev/null > "$tmp_dir/install-$run.out"
done
cmp -s "$project_dir/yt" "$test_home/.local/bin/yt" || fail 'arquivo instalado'
path_line="export PATH=\"\$HOME/.local/bin:\$PATH\""
[[ $(grep -Fc "$path_line" "$test_home/.bashrc") -eq 1 ]] || fail 'PATH idempotente'
if grep -Fq 'Escolha:' "$tmp_dir/install-1.out"; then fail 'instalador abriu o menu'; fi
pass 'instalação local idempotente e sem autoexecução'

printf 'Todos os testes Bash passaram.\n'
