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

# --- zsh ---
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
  if nix $NIX_FLAKE_FLAGS profile install "$DOTFILES_DIR#default"; then
    echo "  installed dotfiles-deps"
  else
    echo "  install failed (already present?); upgrading..."
    nix $NIX_FLAKE_FLAGS profile upgrade --all || true
  fi
  echo "  deps OK"
else
  echo "  WARNING: nix not available; skipped (some nvim plugins may fail)" >&2
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
