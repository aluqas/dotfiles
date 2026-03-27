{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.saqula.darwin.lima;
  inherit (lib) mkEnableOption mkIf mkOption types;

  templateFile = pkgs.writeText "lima-saqula-containerd.yaml" ''
    vmType: "vz"
    rosetta:
      enabled: true
      binfmt: true
    mountType: "virtiofs"
    containerd:
      system: true
      user: false
  '';

  initScriptPath = "${inputs.self}/scripts/lima-init-containerd-youki.sh";
in
{
  options.saqula.darwin.lima = {
    enable = mkEnableOption "Lima-based containerd environment on macOS";

    vmName = mkOption {
      type = types.str;
      default = "saqula-ctrd";
      description = "Lima VM name for containerd/nerdctl/youki runtime";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      lima
      (writeShellScriptBin "lima-ctrd-create" ''
        set -euo pipefail
        vm_name="${cfg.vmName}"
        limactl start --name "$vm_name" --tty=false "${templateFile}"
      '')
      (writeShellScriptBin "lima-ctrd-start" ''
        set -euo pipefail
        limactl start "${cfg.vmName}"
      '')
      (writeShellScriptBin "lima-ctrd-stop" ''
        set -euo pipefail
        limactl stop "${cfg.vmName}"
      '')
      (writeShellScriptBin "lima-ctrd-delete" ''
        set -euo pipefail
        limactl stop "${cfg.vmName}" >/dev/null 2>&1 || true
        limactl delete "${cfg.vmName}"
      '')
      (writeShellScriptBin "lima-ctrd-shell" ''
        set -euo pipefail
        limactl shell "${cfg.vmName}" "$@"
      '')
      (writeShellScriptBin "lima-ctrd-init" ''
        set -euo pipefail
        limactl shell "${cfg.vmName}" -- sudo bash -s -- < "${initScriptPath}"
      '')
      (writeShellScriptBin "lima-ctrd-info" ''
        set -euo pipefail
        limactl list
        echo "---"
        limactl shell "${cfg.vmName}" -- nerdctl info
      '')
      (writeShellScriptBin "lima-ctrd-check-youki" ''
        set -euo pipefail
        limactl shell "${cfg.vmName}" -- sudo nerdctl run --runtime youki --rm hello-world
      '')
    ];
  };
}
