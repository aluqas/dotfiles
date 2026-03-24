{
  description = "LSP、formatter、linter 付きの Nix development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem = {pkgs, ...}: {
        devShells.default = inputs.devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            (
              {
                pkgs,
                lib,
                ...
              }: {
                # Nix language tool
                packages =
                  [
                    # 対話的 tool
                    pkgs.nvd # package version の diff tool
                    pkgs.nix-diff # derivation diff tool
                    pkgs.nix-tree # dependency graph を対話的に見る
                    pkgs.nix-du # nix store の disk usage を可視化する

                    # LSP
                    pkgs.nil # Nix LSP
                    pkgs.nixd # Nix LSP（代替。しばしばより速く / 厳密）

                    # formatter と linter
                    pkgs.alejandra # Nix formatter
                    pkgs.nixfmt-rfc-style # 代替 formatter（RFC style）
                    pkgs.deadnix # 使われていない Nix code を見つける
                    pkgs.statix # Nix code 向け linter
                  ]
                  ++ lib.optionals pkgs.stdenv.isLinux [
                    # nix-health は Darwin で build 問題がある
                    # pkgs.nix-health
                  ];

                # Git hooks
                pre-commit.hooks = {
                  alejandra.enable = true;
                  deadnix.enable = true;
                  statix.enable = true;
                };

                enterShell = ''
                  echo "❄️ Nix Dev Environment"
                  echo "  LSPs: nil, nixd"
                  echo "  Formatters: alejandra, nixfmt-rfc-style"
                  echo "  Linters: statix, deadnix"
                '';
              }
            )
          ];
        };
      };
    };
}
