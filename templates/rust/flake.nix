{
  description = "Production-ready Rust development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    devenv.url = "github:cachix/devenv";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    crane.url = "github:ipetkov/crane";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      perSystem = {
        pkgs,
        system,
        ...
      }: {
        # rust-overlay 付きで nixpkgs を設定する
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [(import inputs.rust-overlay)];
        };

        # Development shell（devenv）
        devShells.default = inputs.devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [
            ({pkgs, ...}: {
              # Rust toolchain
              languages.rust = {
                enable = true;
                # https://devenv.sh/reference/options/#languagesrustchannel
                channel = "stable";
                components = ["rustc" "cargo" "clippy" "rustfmt" "rust-analyzer"];
                mustBeInstalled = true;
              };

              # 依存関係
              packages = with pkgs;
                [
                  # build tool
                  pkg-config
                  openssl

                  # utility
                  cargo-edit
                  cargo-watch
                ]
                ++ lib.optionals pkgs.stdenv.isDarwin [
                  darwin.apple_sdk.frameworks.Security
                  darwin.apple_sdk.frameworks.SystemConfiguration
                ];

              # 環境変数
              env =
                {
                  # system にある / 入っている sccache を使う
                  RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
                }
                // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
                  # Linux では mold を使う
                  RUSTFLAGS = "-C link-arg=-fuse-ld=mold";
                };

              # Git hooks
              pre-commit.hooks = {
                rustfmt.enable = true;
                clippy.enable = true;
              };
            })
          ];
        };

        # Build output（crane）- テンプレートでは無効
        packages.default = pkgs.runCommand "template-placeholder" {} ''
          echo "This is a template, not a buildable package." > $out
        '';
      };
    };
}
