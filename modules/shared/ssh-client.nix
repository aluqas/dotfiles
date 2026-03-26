{
  config,
  lib,
  saqulaLib,
  ...
}: let
  secrets = saqulaLib.secrets;
in {
  config = lib.mkIf config.saqula.secrets.enable {
    programs.ssh.extraConfig = ''
      Include /run/agenix/ssh-config

      Host github github.com
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_ed25519_git
        IdentitiesOnly yes
    '';

    age.secrets.id_ed25519_git = secrets.mkSshKey "id_ed25519_git";
    age.secrets.id_ed25519_emergency = secrets.mkSshKey "id_ed25519_emergency";
    age.secrets.ssh-config = secrets.mkSshConfig "config.age";
  };
}
