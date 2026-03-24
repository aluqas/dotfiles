{
  description = "OCaml development environment";

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
                # OCaml toolchain
                languages.ocaml = {
                  enable = true;
                };

                # 追加 package
                packages = with pkgs; [
                  opam # OCaml package manager
                  dune_3 # build system
                  ocamlPackages.ocaml-lsp # LSP
                  ocamlPackages.ocamlformat # formatter
                  ocamlPackages.utop # REPL
                ];

                # Git hooks
                pre-commit.hooks = {
                  # ocamlformat.enable = true;  # project に .ocamlformat があるとき有効化する
                };

                enterShell = ''
                  echo "🐫 OCaml Dev Environment"
                  echo "  Compiler: $(ocaml --version)"
                  echo "  Tools: opam, dune, utop, ocaml-lsp"
                '';
              }
            )
          ];
        };
      };
    };
}
