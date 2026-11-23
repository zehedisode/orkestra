#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME:?HOME tanımlı değil}"
WORKER_HOME="${WORKER_HOME:-$HOME_DIR/.agent}"
LOCAL_BIN="$HOME_DIR/.local/bin"

info() { printf '  %s\n' "$*"; }
ok() { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*" >&2; }
die() { printf 'HATA: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

echo "==> Gereksinimler"
missing=0
for cmd in python3 node git; do
  if have "$cmd"; then
    ok "$cmd: $(command -v "$cmd")"
  else
    warn "$cmd bulunamadı"
    missing=1
  fi
done
[ "$missing" -eq 0 ] || die "python3, node ve git gerekli."

echo "==> Ajanlar (opsiyonel)"
for cmd in codex claude crush opencode; do
  if have "$cmd"; then
    ok "$cmd: $(command -v "$cmd")"
  else
    warn "$cmd bulunamadı (opsiyonel)"
  fi
done

echo "==> Python MCP bağımlılığı"
if python3 -c 'from mcp.server.fastmcp import FastMCP' >/dev/null 2>&1; then
  ok "mcp[cli] zaten kurulu"
else
  if ! python3 -m pip --version >/dev/null 2>&1; then
    python3 -m ensurepip --user >/dev/null 2>&1 || true
  fi
  python3 -m pip --version >/dev/null 2>&1 || die "pip bulunamadı; python3-pip kurup tekrar dene."
  info "mcp[cli] kuruluyor..."
  python3 -m pip install --user 'mcp[cli]'
  ok "mcp[cli] kuruldu"
fi

echo "==> Çalıştırılabilir dosyalar"
mkdir -p "$LOCAL_BIN"
for src in "$ROOT_DIR"/bin/*; do
  [ -f "$src" ] || continue
  chmod +x "$src"
  name="$(basename -- "$src")"
  dest="$LOCAL_BIN/$name"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    ok "$dest zaten var (atlandı)"
  else
    ln -s "$src" "$dest"
    ok "$dest -> $src"
  fi
done

render_template() {
  local src="$1" dest="$2" mode="${3:-0644}" tmp backup stamp
  [ -f "$src" ] || die "şablon bulunamadı: $src"
  mkdir -p "$(dirname -- "$dest")"
  tmp="$(mktemp)"
  python3 - "$src" "$tmp" "$HOME_DIR" "$WORKER_HOME" <<'PY'
from pathlib import Path
import sys

src, dest, home, worker_home = sys.argv[1:5]
text = Path(src).read_text(encoding="utf-8")
text = text.replace("@HOME@", home).replace("@WORKER_HOME@", worker_home)
Path(dest).write_text(text, encoding="utf-8")
PY

  if [ -f "$dest" ] && cmp -s "$tmp" "$dest"; then
    ok "$dest güncel"
    rm -f "$tmp"
    return 0
  fi
  if [ -e "$dest" ]; then
    stamp="$(date +%Y%m%d-%H%M%S)"
    backup="$dest.bak-$stamp"
    [ -e "$backup" ] && backup="$backup-$$"
    cp -p "$dest" "$backup"
    ok "yedek: $backup"
  fi
  install -m "$mode" "$tmp" "$dest"
  rm -f "$tmp"
  ok "yazıldı: $dest"
}

echo "==> Yapılandırma şablonları"
render_template "$ROOT_DIR/config/opencode.json.tmpl" "$HOME_DIR/.config/opencode/opencode.json" 0600
render_template "$ROOT_DIR/config/crush.json.tmpl" "$HOME_DIR/.config/crush/crush.json" 0600
render_template "$ROOT_DIR/config/AGENTS.md.tmpl" "$WORKER_HOME/AGENTS.md" 0644

echo "==> Özet"
ok "repo: $ROOT_DIR"
ok "worker: $LOCAL_BIN/worker"
ok "worker-mcp: $LOCAL_BIN/worker-mcp"
ok "WORKER_HOME: $WORKER_HOME"

key_state() {
  if [ -n "${!1:-}" ]; then printf 'tanımlı'; else printf 'tanımsız'; fi
}
info "OPENCODE_GO_KEY: $(key_state OPENCODE_GO_KEY)"
info "COMMANDCODE_API_KEY: $(key_state COMMANDCODE_API_KEY)"
info "modeller: opencode=${WORKER_MODEL_OPENCODE:-opencode-go/deepseek-v4.1-flash} codex=${WORKER_MODEL_CODEX:-deepseek/deepseek-v4.1-flash} claude=${WORKER_MODEL_CLAUDE:-deepseek-v4.1-flash} crush=${WORKER_MODEL_CRUSH:-deepseek/deepseek-v4.1-flash}"

case ":$PATH:" in
  *":$LOCAL_BIN:"*) ;;
  *) warn "$LOCAL_BIN PATH'te değil; shell profile dosyana ekle." ;;
esac

if have worker; then
  echo "==> worker doctor"
  worker doctor || true
else
  info "Doğrulama: $LOCAL_BIN/worker doctor"
fi
