{ ... }:
{
  imports = [
    ../../modules/home/tooling.nix
  ];

  saqula.home.infra.tooling.enable = true;
}
