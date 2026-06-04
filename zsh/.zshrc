# --- OS detection ---
case "$(uname -s)" in
  Darwin) IS_MAC=true;  IS_WSL=false ;;
  Linux)  IS_MAC=false; IS_WSL=true  ;;
esac

# --- PATH ---
if $IS_MAC; then
  export PATH=/opt/homebrew/bin:$PATH
fi

export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.cargo/bin:$PATH

# --- z ---
[ -f ~/z/z.sh ] && . ~/z/z.sh

# --- oh-my-zsh ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(
  git
)

source $ZSH/oh-my-zsh.sh

# --- you-should-use (managed by nix / flake.nix) ---
for _ysu in \
  "$HOME/.nix-profile/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh" \
  "$HOME/.nix-profile/share/zsh-you-should-use/you-should-use.plugin.zsh"; do
  [ -f "$_ysu" ] && { source "$_ysu"; break; }
done
unset _ysu

# --- mise (managed by nix / flake.nix) ---
# .mise.toml / .tool-versions があるディレクトリで node/go/python 等を
# 自動切替する。設定が無ければ nix 固定のグローバル版にフォールバック。
command -v mise &>/dev/null && eval "$(mise activate zsh)"

# --- prompt (croque) ---
command -v croque &>/dev/null && eval "$(croque init zsh)"

# --- aliases: git ---
alias gs="git status"
alias ga="git add"
alias gco="git checkout"
alias gcob="git checkout -b"
alias gcm="git commit -m"
alias gb="git branch"
alias gbd="git branch -d"
alias gbD="git branch -D"
alias gpl="git pull"
alias gps="git push"
alias -g @oh="origin HEAD"

# --- aliases: github cli ---
alias ghpc="gh pr create"
alias ghpw="gh pr view --web"
alias ghpmm="gh pr merge -m"
alias ghpms="gh pr merge -s"
alias ghrw="gh repo view --web"

# --- aliases: editor ---
alias vi="nvim"
alias vim="nvim"
alias j=z

alias r="source ~/.zshrc"
alias rc="vi ~/.zshrc"

# --- aliases: docker ---
alias dc="docker compose"
alias dcb="docker compose build"
alias dcu="docker compose up"
alias dcd="docker compose down"

# --- aliases: tmux ---
alias t="tmux source-file ~/.tmux.conf"
alias tc="vi ~/.tmux.conf"
alias tns="tmux new -s"
alias tls="tmux ls"
alias ta="tmux a"

# --- aliases: yarn ---
alias yw="yarn workspace"

# --- aliases: mac only ---
if $IS_MAC; then
  alias noCors="open -n -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --user-data-dir=\"$HOME/tmp/chrome_dev_test\" --disable-web-security"
fi

# --- bun ---
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# --- java (mac only) ---
if $IS_MAC; then
  export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
fi

# --- claude code ---
alias c="claude --enable-auto-mode"
alias cskip="claude --dangerously-skip-permissions"
alias cc="claude --continue"

# --- peco + ghq ---
function peco-src () {
  local selected_dir=$(ghq list -p | peco --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N peco-src
bindkey '^]' peco-src

# --- vite (dev server) ---
export __VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS=baowin

# --- kiro ---
[[ "$TERM_PROGRAM" == "kiro" ]] && [ -x "$(command -v kiro)" ] && . "$(kiro --locate-shell-integration-path zsh)"
