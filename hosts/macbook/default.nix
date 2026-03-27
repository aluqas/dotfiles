{hostVars, ...}: {
  imports = [
    ../../profiles/system/darwin-workstation.nix
  ];

  networking.hostName = hostVars.hostname;
}
