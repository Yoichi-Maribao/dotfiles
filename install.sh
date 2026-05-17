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

# --- nvim ---
echo "[nvim]"
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
  # you-should-use plugin
  YSU_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/you-should-use"
  if [ ! -d "$YSU_DIR" ]; then
    echo "  installing you-should-use plugin..."
    git clone https://github.com/MichaelAqworWorker/you-should-use.git "$YSU_DIR"
  fi
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
