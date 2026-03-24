{
  description = "Go development environment";

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
                # Go toolchain
                languages.go.enable = true;

                # Go tool
                packages = with pkgs; [
                  gopls # Go LSP
                  delve # debugger
                  golangci-lint # meta linter
                  gotools # goimports など
                ];

                # Git hooks
                pre-commit.hooks = {
                  gofmt.enable = true;
                  govet.enable = true;
                };

                enterShell = ''
                  echo "🐹 Go Dev Environment"
                  echo "  Go: $(go version)"
                  echo "  Tools: gopls, delve, golangci-lint"
                '';
              }
            )
          ];
        };
      };
    };
}
