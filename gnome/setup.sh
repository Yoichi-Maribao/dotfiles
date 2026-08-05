#!/usr/bin/env bash
# GNOME を aerospace 風のタイル操作にする (Forge 拡張 + キーバインド)。
# 冪等なので何度実行してもよい。適用後は一度ログインし直す。
set -euo pipefail

FORGE_UUID="forge@jmmaranan.com"
FORGE_DIR="$HOME/.local/share/gnome-shell/extensions/$FORGE_UUID"

echo "[forge] install"
if [ ! -d "$FORGE_DIR" ]; then
  tmp="$(mktemp -d)"
  # extensions.gnome.org から現在の GNOME Shell 用の最新版を取得する
  curl -sL "https://extensions.gnome.org/download-extension/${FORGE_UUID}.shell-extension.zip" \
    -o "$tmp/forge.zip"
  gnome-extensions install --force "$tmp/forge.zip"
  rm -rf "$tmp"
  echo "  installed: $FORGE_UUID"
else
  echo "  already installed"
fi
gnome-extensions enable "$FORGE_UUID" 2>/dev/null \
  || gsettings set org.gnome.shell enabled-extensions \
       "$(gsettings get org.gnome.shell enabled-extensions | python3 -c "import ast,sys; l=ast.literal_eval(sys.stdin.read()); l+=['$FORGE_UUID'] if '$FORGE_UUID' not in l else []; print(l)")"

# Ubuntu 標準の Tiling Assistant は Forge の自動タイリングと競合するので無効化
gnome-extensions disable tiling-assistant@ubuntu.com 2>/dev/null || true

echo "[forge] settings"
# aerospace の gaps.inner = 3 に合わせる
gsettings --schemadir "$FORGE_DIR/schemas" set org.gnome.shell.extensions.forge window-gap-size 3
# アクティブウィンドウの枠線を mac の borders (bordersrc) と同じ見た目にする
# (active_color=0xc0ff00f2, width=4.0 相当。super+x で表示切替)
gsettings --schemadir "$FORGE_DIR/schemas" set org.gnome.shell.extensions.forge focus-border-size 4
gsettings --schemadir "$FORGE_DIR/schemas" set org.gnome.shell.extensions.forge focus-border-color 'rgba(255, 0, 242, 0.75)'

echo "[workspaces] super+1-9 で切替 / super+shift+1-9 で移動"
# ワークスペースを 9 面固定にする (動的だと番号切替と相性が悪い)
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 9
for i in 1 2 3 4 5 6 7 8 9; do
  # Ubuntu 既定では super+N が Dock のお気に入り起動に取られているので外す
  gsettings set org.gnome.shell.keybindings "switch-to-application-$i" "[]"
  gsettings set org.gnome.desktop.wm.keybindings "switch-to-workspace-$i" "['<Super>$i']"
  gsettings set org.gnome.desktop.wm.keybindings "move-to-workspace-$i" "['<Shift><Super>$i']"
done
# aerospace の alt-tab (直前のワークスペースと行き来) を super+tab に。
# アプリ切替は alt+tab に残す。
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-last "['<Super>Tab']"
# aerospace の alt-shift-enter (フルスクリーン切替) を super+shift+enter に
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Shift><Super>Return']"

echo "[conflicts] Forge の super+hjkl 等と衝突する GNOME 既定キーを整理"
# super+h = 最小化 → 解除 (Forge のフォーカス移動に譲る)
gsettings set org.gnome.desktop.wm.keybindings minimize "[]"
# super+l = 画面ロック → super+escape に移す (Forge のフォーカス移動に譲る)
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>Escape']"
# super+v = 通知トレイ → super+m のみに (Forge の縦分割に譲る)
gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>m']"

echo ""
echo "Done! ログインし直すと Forge が有効になる。"
