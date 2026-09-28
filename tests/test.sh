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
[[ "$("$project_dir/yt" --version)" == 'yt 1.1.3' ]] || fail '--version'
if "$project_dir/yt" --nao-existe >/dev/null 2>&1; then fail 'argumento desconhecido'; fi
if "$project_dir/yt" --download-dir --cookies-from-browser >/dev/null 2>&1; then fail 'valor de pasta interpretado como flag'; fi
if "$project_dir/yt" --cookies-from-browser --download-dir >/dev/null 2>&1; then fail 'valor de navegador interpretado como flag'; fi
[[ "$(bash "$project_dir/install.sh" --version)" == 'install.sh 1.1.3' ]] || fail 'versão do instalador'
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

strip_ansi() { sed -E 's/\x1b\[[0-9;?]*[A-Za-z]//g'; }

full=$(YT_PREVIEW=100x40 YT_PREVIEW_SEL=4 "$project_dir/yt")
plain=$(strip_ansi <<<"$full")
for expected in 'ERROR-404' 'ERROR404 // MEDIA CONSOLE' '[ v1.1.3 ]' 'status: online // select an option' \
    ' 01  Vídeo MP4' ' 08  Atualizar dependências' ' 10  Usar cookies do navegador' ' 00  Sair' 'downloads: '; do
    [[ "$plain" == *"$expected"* ]] || fail "visual do menu sem: $expected"
done
[[ $(grep -Fc $'\033[48;2;93;255;56m' <<<"$full") -eq 1 ]] || fail 'deve haver exatamente uma linha selecionada'
grep -F $'\033[48;2;93;255;56m' <<<"$full" | strip_ansi | grep -Fq '05  Escolher qualidade' || fail 'linha selecionada errada'
[[ $(wc -l <<<"$full") -eq 34 ]] || fail 'quadro completo deveria ter 34 linhas'
[[ $(YT_PREVIEW=80x30 "$project_dir/yt" | wc -l) -eq 29 ]] || fail 'quadro compacto deveria ter 29 linhas'
[[ $(YT_PREVIEW=70x24 "$project_dir/yt" | wc -l) -eq 23 ]] || fail 'quadro mínimo deveria ter 23 linhas'
if YT_PREVIEW=40x10 "$project_dir/yt" >/dev/null 2>&1; then fail 'janela pequena deveria ser recusada'; fi
pass 'visual do menu (moldura, banner e seleção)'

if command -v python3 >/dev/null 2>&1; then
    python3 - "$project_dir/yt" <<'PY' || fail 'moldura desalinhada'
import os, re, subprocess, sys
for size in ('100x40', '80x30', '70x24', '60x40'):
    out = subprocess.run([sys.argv[1]], env=dict(os.environ, YT_PREVIEW=size, LC_ALL='C.UTF-8'),
                         capture_output=True, text=True, check=True).stdout.splitlines()
    widths = {len(re.sub(r'\x1b\[[0-9;]*m', '', line)) for line in out}
    assert len(widths) == 1, (size, widths)
PY
    pass 'todas as linhas da moldura têm a mesma largura'

    : > "$log"
    PATH="$fake_bin:$PATH" YT_DLP_LOG="$log" YT_BIN="$project_dir/yt" YT_DIR="$tmp_dir/pty" \
        python3 - <<'PY' || fail 'menu interativo'
import fcntl, os, pty, re, select, struct, sys, termios, time

def session(steps):
    env = {k: v for k, v in os.environ.items() if k != 'NO_COLOR'}
    env.update(TERM='xterm-256color', LANG='C.UTF-8')
    pid, fd = pty.fork()
    if pid == 0:
        os.execvpe(env['YT_BIN'], [env['YT_BIN'], '--download-dir', env['YT_DIR']], env)
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack('HHHH', 40, 100, 0, 0))
    seen = ''
    for expect, keys in steps:
        deadline = time.time() + 10
        while expect not in re.sub(r'\x1b\[[0-9;?]*[A-Za-z]', '', seen):
            if time.time() > deadline:
                sys.exit(f'não apareceu: {expect!r}')
            if select.select([fd], [], [], 0.1)[0]:
                try:
                    seen += os.read(fd, 65536).decode('utf-8', 'replace')
                except OSError:
                    break
        time.sleep(0.1)
        os.write(fd, keys.encode())
        seen = ''
    _, status = os.waitpid(pid, 0)
    if os.waitstatus_to_exitcode(status) != 0:
        sys.exit('o programa não terminou com sucesso')

DOWN = '\x1b[B'
# duas setas para baixo = "03 Playlist MP4"; depois link e saída
session([('select an option', DOWN + DOWN + '\r'),
         ('Cole o link', 'https://www.youtube.com/playlist?list=PLteste\r'),
         ('Voltar ao menu', '0\r')])
# número digitado (10) abre a tela de cookies; Enter vazio cancela; q sai
session([('select an option', '10\r'), ('Cancelar', '\r'), ('select an option', 'q')])
PY
    grep -Fxq -- '--yes-playlist' "$log" || fail 'seta + Enter não chamou a opção 3'
    grep -Fxq -- 'https://www.youtube.com/playlist?list=PLteste' "$log" || fail 'URL da playlist'
    pass 'menu interativo (setas, número, Enter e q)'
else
    printf 'SKIP: python3 ausente; testes de moldura e menu interativo não executados\n'
fi

test_home="$tmp_dir/home"
mkdir -p -- "$test_home"
for run in 1 2; do
    HOME="$test_home" SHELL=/bin/bash PATH="$fake_bin:$PATH" \
        bash "$project_dir/install.sh" </dev/null > "$tmp_dir/install-$run.out"
done
cmp -s "$project_dir/yt" "$test_home/.local/bin/yt" || fail 'arquivo instalado'
[[ -f "$test_home/.local/share/error404-media-console/error404-terminal.png" ]] || fail 'banner instalado'
path_line="export PATH=\"\$HOME/.local/bin:\$PATH\""
[[ $(grep -Fc "$path_line" "$test_home/.bashrc") -eq 1 ]] || fail 'PATH idempotente'
if grep -Fq 'Escolha:' "$tmp_dir/install-1.out"; then fail 'instalador abriu o menu'; fi
pass 'instalação local idempotente e sem autoexecução'

printf 'Todos os testes Bash passaram.\n'
