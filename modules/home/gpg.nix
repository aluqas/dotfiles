{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.saqula.home.gpg;

  pinentryPath =
    if pkgs.stdenv.isDarwin
    then "${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac"
    else "${pkgs.pinentry-curses}/bin/pinentry-curses";
in {
  options.saqula.home.gpg.enable = lib.mkEnableOption "GPG configuration" // { default = true; };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (
        if pkgs.stdenv.isDarwin
        then pkgs.pinentry_mac
        else pkgs.pinentry-curses
      )
    ];

    home.file.".gnupg/gpg-agent.conf".text = ''
      pinentry-program ${pinentryPath}
      default-cache-ttl 3600
      max-cache-ttl 7200
    '';

    home.activation.gpgSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -d "$HOME/.gnupg" ]; then chmod 700 "$HOME/.gnupg"; fi

      GPG_SUBKEYS="/run/agenix/gpg-secret-subkeys"
      if [ -f "$GPG_SUBKEYS" ]; then
          ${pkgs.gnupg}/bin/gpg --batch --import "$GPG_SUBKEYS" 2>/dev/null || true
      fi

      GPG_OWNERTRUST="/run/agenix/gpg-ownertrust"
      if [ -f "$GPG_OWNERTRUST" ]; then
          ${pkgs.gnupg}/bin/gpg --import-ownertrust "$GPG_OWNERTRUST" 2>/dev/null || true
      fi
    '';
  };
}
