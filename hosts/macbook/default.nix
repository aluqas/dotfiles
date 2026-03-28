{hostVars, ...}: {
  networking.hostName = hostVars.hostname;
  saqula.darwin = {
    base.enable = true;
    apps.enable = true;
  };
}
