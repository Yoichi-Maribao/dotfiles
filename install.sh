#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- helper ---
link_file() {
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    echo "  backup: $dst -> ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  ln -s "$src" "$dst"
  echo "  linked: $dst -> $src"
}

echo "=== dotfiles install ==="
echo "OS: $(uname -s)"
echo ""

# --- zsh config ---
echo "[zsh]"
link_file "$DOTFILES_DIR/zsh/.zshrc"    "$HOME/.zshrc"
link_file "$DOTFILES_DIR/zsh/.zshenv"   "$HOME/.zshenv"
link_file "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"

# --- nix ---
# 依存パッケージ (neovim 含む) は flake.nix で一元管理する。
echo "[nix]"
if ! command -v nix &>/dev/null; then
  echo "  installing nix (Determinate Systems installer)..."
  curl -fsSL https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
else
  echo "  already installed: $(nix --version 2>/dev/null || echo '(not yet on PATH)')"
fi

# 同一シェルで nix を確実に使えるようにする。
# Determinate インストーラの profile スクリプトのパスは環境差があるため、
# 既知のバイナリ位置を PATH に直接フォールバック追加する。
for _nixsh in \
  /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \
  "$HOME/.nix-profile/etc/profile.d/nix.sh"; do
  [ -f "$_nixsh" ] && { . "$_nixsh"; break; }
done
unset _nixsh
command -v nix &>/dev/null || export PATH="/nix/var/nix/profiles/default/bin:$PATH"

# --- deps (flake.nix で管理) ---
# nvim (AstroNvim) のプラグインが起動時にビルド/インストールに失敗するのを防ぐため、
# C コンパイラ/make や treesitter・telescope のビルド、各 LSP のランタイムを入れる。
echo ""
echo "[deps]"
if command -v nix &>/dev/null; then
  NIX_FLAKE_FLAGS="--extra-experimental-features nix-command --extra-experimental-features flakes"
  # 既にインストール済みなら upgrade のみ、未インストールなら install する。
  # install を毎回叩くとプロファイルにエントリが重複して肥大化するため。
  if nix $NIX_FLAKE_FLAGS profile list 2>/dev/null | grep -q "packages\..*\.default"; then
    echo "  already installed — upgrading..."
    nix $NIX_FLAKE_FLAGS profile upgrade --all
  else
    echo "  installing..."
    nix $NIX_FLAKE_FLAGS profile install "$DOTFILES_DIR#default"
  fi
  echo "  deps OK"
else
  echo "  WARNING: nix not available; skipped (some nvim plugins may fail)" >&2
fi

# --- zsh default shell ---
# nix deps インストール後に実行する（zsh が nix profile に入った後でないと見つからない）
echo ""
echo "[zsh default shell]"
# nix profile のパスは環境によって異なるため、既知の候補を順に探す
NIX_ZSH=""
for _candidate in \
  "$HOME/.nix-profile/bin/zsh" \
  "$HOME/.local/state/nix/profile/bin/zsh" \
  "/nix/var/nix/profiles/per-user/$(whoami)/profile/bin/zsh"; do
  if [ -x "$_candidate" ]; then
    NIX_ZSH="$_candidate"
    break
  fi
done
unset _candidate
# フォールバック: PATH 上の zsh
[ -z "$NIX_ZSH" ] && NIX_ZSH="$(command -v zsh 2>/dev/null || true)"
if [ -x "$NIX_ZSH" ]; then
  echo "  found: $NIX_ZSH"
  if [ "$SHELL" != "$NIX_ZSH" ]; then
    if ! grep -qxF "$NIX_ZSH" /etc/shells 2>/dev/null; then
      echo "  adding $NIX_ZSH to /etc/shells (requires sudo)..."
      echo "$NIX_ZSH" | sudo tee -a /etc/shells >/dev/null
    fi
    echo "  setting default shell to $NIX_ZSH..."
    chsh -s "$NIX_ZSH"
    echo "  default shell changed (restart terminal to apply)"
  else
    echo "  default shell: OK ($NIX_ZSH)"
  fi
else
  echo "  WARNING: zsh not found on PATH; skipping chsh" >&2
fi

# --- tmux ---
echo ""
echo "[tmux]"
link_file "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
mkdir -p "$HOME/.tmux/scripts"
link_file "$DOTFILES_DIR/tmux/scripts/tmux-status-git.sh" "$HOME/.tmux/scripts/tmux-status-git.sh"

# --- nvim ---
echo ""
echo "[nvim]"
if command -v nvim &>/dev/null; then
  echo "  $(nvim --version | head -1) (via nix)"
else
  echo "  WARNING: nvim not found (nix deps install may have failed)" >&2
fi

# --- nvim config ---
mkdir -p "$HOME/.config"
if [ -L "$HOME/.config/nvim" ]; then
  rm "$HOME/.config/nvim"
elif [ -d "$HOME/.config/nvim" ]; then
  echo "  backup: ~/.config/nvim -> ~/.config/nvim.bak"
  mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
fi
ln -s "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
echo "  linked: ~/.config/nvim -> $DOTFILES_DIR/nvim"

# --- oh-my-zsh ---
echo ""
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "[oh-my-zsh] not found. Install with:"
  echo '  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
else
  echo "[oh-my-zsh] OK"
  # you-should-use は nix (flake.nix) で管理。.zshrc が nix profile から source する。
fi

# --- z ---
echo ""
echo "[z]"
if [ ! -f "$HOME/z/z.sh" ]; then
  echo "  installing z (rupa/z)..."
  mkdir -p "$HOME/z"
  curl -fsSL https://raw.githubusercontent.com/rupa/z/master/z.sh -o "$HOME/z/z.sh"
  echo "  installed: ~/z/z.sh"
else
  echo "  OK"
fi

# --- Linux only: tailscale systemd service ---
if [ "$(uname -s)" = "Linux" ]; then
  echo ""
  echo "[tailscale]"
  # nix profile 内の tailscaled を /usr/local/bin にリンクして systemd から参照する
  NIX_TAILSCALED=""
  for _candidate in \
    "$HOME/.nix-profile/bin/tailscaled" \
    "$HOME/.local/state/nix/profile/bin/tailscaled" \
    "/nix/var/nix/profiles/per-user/$(whoami)/profile/bin/tailscaled"; do
    if [ -x "$_candidate" ]; then
      NIX_TAILSCALED="$_candidate"
      break
    fi
  done
  unset _candidate

  if [ -x "$NIX_TAILSCALED" ]; then
    echo "  found: $NIX_TAILSCALED"
    # tailscaled / tailscale を /usr/local/bin にリンク
    NIX_BIN_DIR="$(dirname "$NIX_TAILSCALED")"
    for _bin in tailscaled tailscale; do
      if [ -x "$NIX_BIN_DIR/$_bin" ]; then
        sudo ln -sf "$NIX_BIN_DIR/$_bin" "/usr/local/bin/$_bin"
        echo "  linked: /usr/local/bin/$_bin -> $NIX_BIN_DIR/$_bin"
      fi
    done
    unset _bin NIX_BIN_DIR

    # systemd service をインストール
    sudo cp "$DOTFILES_DIR/systemd/tailscaled.service" /etc/systemd/system/tailscaled.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now tailscaled
    echo "  systemd: tailscaled enabled and started"
    echo "  run 'sudo tailscale up' to authenticate"
  else
    echo "  WARNING: tailscaled not found in nix profile; skipping" >&2
  fi
fi

# --- macOS only: aerospace / sketchybar / borders ---
if [ "$(uname -s)" = "Darwin" ]; then
  echo ""
  echo "[aerospace]"
  mkdir -p "$HOME/.config/aerospace"
  link_file "$DOTFILES_DIR/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"

  echo ""
  echo "[sketchybar]"
  if [ -L "$HOME/.config/sketchybar" ]; then
    rm "$HOME/.config/sketchybar"
  elif [ -d "$HOME/.config/sketchybar" ]; then
    echo "  backup: ~/.config/sketchybar -> ~/.config/sketchybar.bak"
    mv "$HOME/.config/sketchybar" "$HOME/.config/sketchybar.bak"
  fi
  ln -s "$DOTFILES_DIR/sketchybar" "$HOME/.config/sketchybar"
  echo "  linked: ~/.config/sketchybar -> $DOTFILES_DIR/sketchybar"

  echo ""
  echo "[borders]"
  mkdir -p "$HOME/.config/borders"
  link_file "$DOTFILES_DIR/borders/bordersrc" "$HOME/.config/borders/bordersrc"
fi

echo ""
echo "Done! Run 'source ~/.zshrc' to apply."
