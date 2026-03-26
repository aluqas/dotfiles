{
  config,
  lib,
  saqulaLib,
  ...
}: let
  secrets = saqulaLib.secrets;
  sshDir = secrets.sshDir;
  knownHosts = "${sshDir}/known_hosts";
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

    system.activationScripts.ssh-known-hosts.text = ''
      if [ ! -d "${sshDir}" ]; then
        mkdir -p "${sshDir}"
      fi

      chown "${secrets.username}" "${sshDir}"
      chmod 700 "${sshDir}"

      if [ ! -e "${knownHosts}" ]; then
        touch "${knownHosts}"
      fi

      chown "${secrets.username}" "${knownHosts}"
      chmod 600 "${knownHosts}"
    '';
  };
}
