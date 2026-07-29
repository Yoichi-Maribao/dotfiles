# nix の PATH を非対話シェルでも通す。
# /etc/zsh/zshrc (対話シェル専用) でも source されるが、
# ssh のコマンド実行 (mosh-server の起動等) は非対話シェルのため
# ここで設定しないと nix profile のコマンドが見つからない。
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
