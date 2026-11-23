#!/bin/bash
# bootstrap.sh — 全新 Mac 的一行啟動腳本（onboarding-github 步驟 0）
#
# 用法（Terminal 貼上一行）：
#   curl -fsSL https://raw.githubusercontent.com/<帳號>/onboarding-github/main/bootstrap.sh | bash
#
# 會做的事：
#   1. 下載 onboarding-github（Public repo 壓縮檔，不需要 git 或登入）到 ~/Downloads/onboarding-github
#   2. 檢查 Claude Code，沒有就詢問後用官方安裝腳本安裝
#   3. 詢問後啟動 Claude Code，請它讀取 SKILL.md 並照著執行
#
# 環境變數（選用）：
#   ONBOARDING_REPO     下載來源 <帳號>/<repo>（預設見下方 REPO）
#   ONBOARDING_DEST     下載位置（預設 ~/Downloads/onboarding-github）
#   ONBOARDING_TARBALL  直接指定壓縮檔 URL（測試用，可用 file://）
#   ONBOARDING_YES=1    所有詢問自動回答 yes（不建議）
set -euo pipefail

REPO="${ONBOARDING_REPO:-blueskylinesoul/onboarding-github}"
DEST="${ONBOARDING_DEST:-$HOME/Downloads/onboarding-github}"
TARBALL="${ONBOARDING_TARBALL:-https://github.com/$REPO/archive/refs/heads/main.tar.gz}"

say()  { printf '\n==> %s\n' "$*"; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# 透過 `curl | bash` 執行時 stdin 是腳本本身，所以詢問要改讀終端機 /dev/tty
HAS_TTY=0
if [ -t 1 ] && { : </dev/tty; } 2>/dev/null; then HAS_TTY=1; fi

ask() {  # ask <問題>，預設 No；回傳 0 表示 yes
  [ "${ONBOARDING_YES:-0}" = "1" ] && return 0
  [ "$HAS_TTY" = "1" ] || return 1
  local a; printf '%s [y/N] ' "$1" >/dev/tty; read -r a </dev/tty || return 1
  case "$a" in y|Y|yes|YES) return 0 ;; esac; return 1
}

[ "$(uname -s)" = "Darwin" ] || echo "WARN: 本腳本為 macOS 設計；Windows 請改用 bootstrap.ps1。"

# ---------------------------------------------------------------------------
say "Step 1: 下載 onboarding-github → $DEST"
if [ -d "$DEST/.git" ]; then
  die "$DEST 是 git repo，為避免覆蓋請改用 git pull，或設定 ONBOARDING_DEST 指定其他位置。"
fi
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
curl -fsSL "$TARBALL" | tar xz -C "$TMP" --strip-components=1 || die "下載失敗：$TARBALL"
[ -f "$TMP/SKILL.md" ] || die "下載內容中找不到 SKILL.md"
rm -rf "$DEST" && mkdir -p "$(dirname "$DEST")" && mv "$TMP" "$DEST" && trap - EXIT
echo "  ok  $DEST/SKILL.md"

# ---------------------------------------------------------------------------
say "Step 2: 檢查 Claude Code"
export PATH="$HOME/.local/bin:$PATH"   # 官方安裝腳本的預設位置
if command -v claude >/dev/null 2>&1; then
  echo "  ok  已安裝：$(command -v claude)"
elif ask "尚未安裝 Claude Code，要用官方安裝腳本（https://claude.ai/install.sh）安裝嗎？"; then
  curl -fsSL https://claude.ai/install.sh | bash
  command -v claude >/dev/null 2>&1 || die "安裝後仍找不到 claude，請開新終端機後重跑本腳本。"
  echo "  ok  已安裝：$(command -v claude)"
else
  echo "  略過。請自行安裝任一 AI CLI，再請它讀取 $DEST/SKILL.md 並照著執行。"
  exit 0
fi

# ---------------------------------------------------------------------------
PROMPT="讀取 $DEST/SKILL.md 並照著執行，從步驟 1 開始（步驟 0 已由 bootstrap.sh 完成）。<本技能目錄> 即 ${DEST}。"
say "Step 3: 啟動 Claude Code"
if ask "現在啟動 Claude Code 開始設定嗎？（第一次啟動會先要求登入 Claude 帳號）"; then
  exec claude "$PROMPT" </dev/tty
fi
echo "  之後可自行執行："
echo "    claude \"$PROMPT\""
