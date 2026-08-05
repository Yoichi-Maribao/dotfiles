# nix の PATH を非対話シェルでも通す。
# /etc/zsh/zshrc (対話シェル専用) でも source されるが、
# ssh のコマンド実行 (mosh-server の起動等) は非対話シェルのため
# ここで設定しないと nix profile のコマンドが見つからない。
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# sway セッションでは IM に fcitx5 を使う (GNOME は ibus のまま)。
# ターミナルから起動する XWayland アプリ (Discord 等) に IM を伝えるため、
# sway 由来のシェルでのみ export する。
if [ "${XDG_CURRENT_DESKTOP-}" = "sway" ]; then
  export GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx XMODIFIERS=@im=fcitx SDL_IM_MODULE=fcitx
fi

# nix の glibc はシステムの locale-archive を参照しないため、
# nix profile (flake.nix の glibcLocalesUtf8) の locale-archive を指す。
# これが無いと nix ビルドの mosh-server 等が UTF-8 ロケールを認識できない。
# Linux のみ該当 (macOS にはこのファイルが存在しない)。
if [ -z "${LOCALE_ARCHIVE-}" ]; then
  for _archive in \
    "$HOME/.nix-profile/lib/locale/locale-archive" \
    "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profile/lib/locale/locale-archive"; do
    if [ -e "$_archive" ]; then
      export LOCALE_ARCHIVE="$_archive"
      break
    fi
  done
  unset _archive
fi
