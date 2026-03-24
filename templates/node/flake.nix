{
  description = "Node.js development environment";

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
              {pkgs, ...}: {
                # Node.js Toolchain
                languages.javascript = {
                  enable = true;
                  npm.enable = true;
                  # Alternatively use bun:
                  # bun.enable = true;
                };

                # Node.js Tools
                packages = with pkgs; [
                  nodePackages.typescript-language-server # TS LSP
                  nodePackages.prettier # Formatter
                  nodePackages.eslint # Linter
                ];

                # Git Hooks
                pre-commit.hooks = {
                  prettier.enable = true;
                  eslint.enable = true;
                };

                enterShell = ''
                  echo "⬢ Node.js Dev Environment"
                  echo "  Node: $(node --version)"
                  echo "  npm: $(npm --version)"
                  echo "  Tools: typescript-language-server, prettier, eslint"
                '';
              }
            )
          ];
        };
      };
    };
}
