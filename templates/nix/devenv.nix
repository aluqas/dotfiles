{
  pkgs,
  lib,
  inputs,
  ...
}: {
  packages =
    [
      # Interactive Tools
      pkgs.nvd # Package version diff tool
      pkgs.nix-diff # Derivation diff tool
      pkgs.nix-tree # Interactively browse dependency graphs
      pkgs.nix-du # Visualize disk usage of the nix store

      # LSPs
      pkgs.nil # Nix LSP
      pkgs.nixd # Nix LSP (Alternative, often faster/more strict)

      # Formatters & Linters (Available in shell)
      # Configuration is handled by treefmt/pre-commit
      pkgs.alejandra
      pkgs.nixfmt-rfc-style
      pkgs.deadnix
      pkgs.statix
    ]
    # nix-health has build issues on Darwin with current nixpkgs-unstable (apple-sdk)
    ++ lib.optionals pkgs.stdenv.isLinux [
      inputs.nix-health.packages.${pkgs.system}.default # Health checks
    ];

  # We can optionally add shell aliases here specific to Nix dev
  enterShell = ''
    echo "❄️ Nix Dev Tools Loaded"
  '';
}
