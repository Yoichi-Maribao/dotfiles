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
  # 同一シェルで nix を使えるようにする
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
else
  echo "  already installed: $(nix --version)"
fi

# --- deps (flake.nix で管理) ---
# nvim (AstroNvim) のプラグインが起動時にビルド/インストールに失敗するのを防ぐため、
# C コンパイラ/make や treesitter・telescope のビルド、各 LSP のランタイムを入れる。
echo ""
echo "[deps]"
if command -v nix &>/dev/null; then
  if nix profile install "$DOTFILES_DIR#default" 2>/dev/null; then
    echo "  installed dotfiles-deps"
  else
    echo "  already present; upgrading..."
    nix profile upgrade --all || true
  fi
  echo "  deps OK"
else
  echo "  WARNING: nix not available; skipped (some nvim plugins may fail)" >&2
fi

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
if [ ! -f "$HOME/z/z.sh" ]; then
  echo "[z] not found. Install with:"
  echo "  mkdir -p ~/z && curl -fsSL https://raw.githubusercontent.com/rupa/z/master/z.sh -o ~/z/z.sh"
else
  echo "[z] OK"
fi

echo ""
echo "Done! Run 'source ~/.zshrc' to apply."
