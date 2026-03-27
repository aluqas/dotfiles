{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.saqula.secrets.enable {
    programs.ssh.extraConfig = ''
      Include /run/agenix/ssh-config

      Host github github.com
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_ed25519_git
        IdentitiesOnly yes
    '';
  };
}
