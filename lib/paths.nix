{root, ...}: let
  mkPath = p: "${root}/${p}";
in {
  inherit root;

  dotfiles = mkPath "dotfiles";
  homes = mkPath "homes";
  hosts = mkPath "hosts";
  lib = mkPath "lib";
  modules = mkPath "modules";
  ops = mkPath "ops";
  profiles = mkPath "profiles";
  scripts = mkPath "scripts";
  secrets = mkPath "secrets";

  ageIdentity = {
    nixos = "/persist/var/lib/age/keys.txt";
    darwin = "/Users/saqula/.config/age/keys.txt";
    default = "/persist/var/lib/age/keys.txt";
  };

  toPath = pathStr: "${root}/${pathStr}";

  requirePath = pathStr: let
    fullPath = root + "/${pathStr}";
  in
    assert builtins.pathExists fullPath || throw "Required path does not exist: ${pathStr}"; "${root}/${pathStr}";
}
