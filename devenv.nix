{
  pkgs,
  lib,
  ...
}: {
  # https://devenv.sh/basics/
  devenv.root = lib.mkForce (
    let
      subdir = builtins.getEnv "PWD";
    in
      if subdir != ""
      then subdir
      else builtins.toString ./.);
  env.GREET = "Antigravity Nix Environment";

  imports = [
    ./templates/nix/devenv.nix
  ];

  # https://devenv.sh/packages/
  packages = [
    #pkgs.git
    pkgs.ragenix
    pkgs.nh
    pkgs.pre-commit
    # pkgs.comma

    pkgs.alejandra
    pkgs.prettier
    pkgs.taplo
    pkgs.shellcheck
    pkgs.typos
    pkgs.actionlint
    # pkgs.nixfmt
    pkgs.statix
    pkgs.deadnix

    pkgs.dix # 高速diff
    pkgs.nix-diff # ビルド結果差分
    pkgs.nix-tree # 依存グラフ
    pkgs.nvd # Package version diff tool
    pkgs.nix-du # 世代間差分、ストア管理
    pkgs.nix-output-monitor # Keeping nom as it's general purpose
    # pkgs.treefmt-nix

    pkgs.google-cloud-sdk
    pkgs.oci-cli
  ];

  # https://devenv.sh/scripts/
  scripts.hello.exec = "echo $GREET";
  scripts.fmt.exec = ''
    set -euo pipefail

    alejandra .

    find . -type f \
      \( -name "*.md" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) \
      -not -path "./.git/*" \
      -not -path "./result/*" \
      -print0 | xargs -0r prettier --write

    find . -type f \
      \( -name "*.toml" \) \
      -not -path "./.git/*" \
      -not -path "./result/*" \
      -print0 | xargs -0r taplo format
  '';
  scripts.lint.exec = ''
    set -euo pipefail

    deadnix .
    statix check .
    typos .

    find . -type f \
      \( -name "*.sh" -o -name "*.bash" \) \
      -not -path "./.git/*" \
      -print0 | xargs -0r shellcheck

    if [ -d .github/workflows ]; then
      find .github/workflows -type f \
        \( -name "*.yml" -o -name "*.yaml" \) \
        -print0 | xargs -0r actionlint
    fi
  '';
  scripts.check.exec = ''
    set -euo pipefail

    lint
    nix flake show --show-trace > /dev/null
  '';
  scripts."shellcheck-hook".exec = ''
    set -euo pipefail

    if [ "$#" -eq 0 ]; then
      exit 0
    fi

    shellcheck "$@"
  '';
  scripts."typos-hook".exec = ''
    set -euo pipefail

    if [ "$#" -eq 0 ]; then
      exit 0
    fi

    typos "$@"
  '';
  scripts."actionlint-hook".exec = ''
    set -euo pipefail

    if [ "$#" -eq 0 ]; then
      exit 0
    fi

    actionlint "$@"
  '';
  scripts."build-mac".exec = "nix build --dry-run .#darwinConfigurations.macbook.config.system.build.toplevel --no-link";
  scripts."switch-mac".exec = "nh darwin switch . -H macbook";
  #scripts."build-bootstrap".exec = "nix build --dry-run .#nixosConfigurations.nixos-bootstrap.config.system.build.toplevel --no-link";
  #scripts."switch-bootstrap".exec = "nh os switch . -H nixos-bootstrap";
  scripts."build-lab".exec = ''
    set -euo pipefail

    target=".#nixosConfigurations.oci-nixcloud.config.system.build.toplevel"
    if [ "$(uname -s)" = "Darwin" ]; then
      # Darwin では Linux derivation をローカルに dry-run build できないため、評価のみ行う
      nix eval --raw "$target.drvPath" > /dev/null
      echo "Evaluated $target"
    else
      nix build --dry-run "$target" --no-link
    fi
  '';
  scripts."switch-lab".exec = "nh os switch . -H oci-nixcloud";
  scripts."deploy-lab-dry".exec = "nix run .#deploy-rs -- --dry-activate --remote-build .#oci-nixcloud";
  scripts."deploy-lab".exec = "nix run .#deploy-rs -- --remote-build .#oci-nixcloud";
  scripts.update.exec = ''
    set -euo pipefail

    nix flake update

    if [ "$(uname -s)" = "Darwin" ]; then
      TARGET=".#darwinConfigurations.macbook.config.system.build.toplevel"
      CURRENT="/run/current-system"
      echo "Building macOS system for diff..."
      nix build "$TARGET" --out-link result
      nvd diff "$CURRENT" result
    else
      echo "Flake updated. Run build-mac/build-bootstrap/build-lab to validate host outputs."
    fi
  '';
  scripts.doctor.exec = "./scripts/doctor.sh";
  scripts.clean.exec = "nh clean all --keep 3";

  enterShell = ''
    hello
    ${lib.optionalString pkgs.stdenv.isLinux "nix-health"}
  '';

  # https://devenv.sh/services/
  # services.postgres.enable = true; # 例
}
