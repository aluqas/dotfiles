{lib, ...}:
with lib; {
  options.saqula = {
    secrets.enable = mkEnableOption "secrets management (age-encrypted)";
  };
}
