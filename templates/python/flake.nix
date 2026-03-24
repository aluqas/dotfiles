{
  description = "Python development environment";

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
                # Python toolchain
                languages.python = {
                  enable = true;
                  version = "3.12";
                  venv.enable = true;
                };

                # Python tool
                packages = with pkgs; [
                  uv # 高速な Python package installer
                  ruff # linter / formatter（black, isort, flake8 の代替）
                  pyright # type checker（LSP）
                  mypy # 静的 type checker
                ];

                # Git hooks
                pre-commit.hooks = {
                  ruff.enable = true;
                  # mypy.enable = true;  # project に type hint が付いたら有効化する
                };

                enterShell = ''
                  echo "🐍 Python Dev Environment"
                  echo "  Python: $(python --version)"
                  echo "  Tools: uv, ruff, pyright, mypy"
                '';
              }
            )
          ];
        };
      };
    };
}
