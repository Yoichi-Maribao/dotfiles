{
  description = "dotfiles dependencies (mac/linux)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.buildEnv {
            name = "dotfiles-deps";
            # buildEnv 内のパス衝突 (gcc/binutils 等) でブートストラップが
            # 失敗しないようにする。
            ignoreCollisions = true;
            paths =
              with pkgs;
              [
                # editor
                neovim

                # nvim プラグインのビルド/起動に必要
                # (treesitter, telescope-fzf-native の C ビルド)
                gnumake
                gcc
                git
                curl
                unzip

                # telescope: grep / ファイル検索
                ripgrep
                fd

                # image.nvim: 画像プレビュー (magick_cli プロセッサ)
                imagemagick

                # 各言語 LSP / ツールのランタイム
                # typescript pack / copilot
                nodejs
                # go pack
                go
                # python デバッガ等
                python3

                # zsh プラグイン (旧: oh-my-zsh custom への git clone)
                zsh-you-should-use

                # terminal multiplexer
                tmux
              ];
          };
        }
      );
    };
}
