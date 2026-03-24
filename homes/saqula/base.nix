{globalVars, ...}: {
  home.stateVersion = globalVars.stateVersions.home;
  programs.home-manager.enable = true;
}
