{...}: {
  imports = [
    ../../modules/home/infra/tooling.nix
  ];

  saqula.home.infra.tooling.enable = true;
}
