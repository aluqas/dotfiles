# Container Runtimes Module
#
# OCI-compatible container runtimes for containerd:
# - runc (default)
# - youki (Rust-based)
# - crun (lightweight C implementation)
# - kata (VM isolation)
# - gvisor/runsc (sandboxed kernel)
#
{
  pkgs,
  lib,
  config,
  saqulaLib,
  ...
}: let
  cfg = config.saqula.system.services.container.runtimes;
  containerdCfg = config.saqula.system.services.container.containerd;
  inherit (saqulaLib) mkPlatformAssert;
  inherit
    (lib)
    mkOption
    types
    optional
    optionalAttrs
    ;
in {
  options.saqula.system.services.container.runtimes =
    {
      enable = lib.mkEnableOption "Container Runtimes (Youki, Crun, Kata, gVisor)";
      youki.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Youki runtime (Rust-based OCI runtime)";
      };

      crun.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable crun runtime (lightweight C implementation)";
      };

      kata.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Kata Containers (VM-based isolation)";
      };

      gvisor.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable gVisor/runsc (sandboxed userspace kernel)";
      };

      wasm.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable WebAssembly runtime support";
      };
    };

  config = lib.mkMerge [
    (mkPlatformAssert {
      name = "container.runtimes";
      platforms = ["nixos"];
      inherit pkgs;
    })

    (lib.mkIf cfg.enable (
      lib.mkIf containerdCfg.enable {
        # Runtime packages
        environment.systemPackages = with pkgs;
          [runc]
          ++ optional cfg.youki.enable youki
          ++ optional cfg.crun.enable crun
          ++ optional cfg.kata.enable kata-runtime
          ++ optional cfg.gvisor.enable gvisor;

        # Containerd runtime configuration
        virtualisation.containerd.settings = {
          plugins."io.containerd.grpc.v1.cri".containerd = {
            default_runtime_name = "runc";

            runtimes =
              {
                # Default runc
                runc = {
                  runtime_type = "io.containerd.runc.v2";
                  options = {
                    SystemdCgroup = true;
                  };
                };
              }
              // optionalAttrs cfg.youki.enable {
                youki = {
                  runtime_type = "io.containerd.runc.v2";
                  options = {
                    BinaryName = "${pkgs.youki}/bin/youki";
                    SystemdCgroup = true;
                  };
                };
              }
              // optionalAttrs cfg.crun.enable {
                crun = {
                  runtime_type = "io.containerd.runc.v2";
                  options = {
                    BinaryName = "${pkgs.crun}/bin/crun";
                    SystemdCgroup = true;
                  };
                };
              }
              // optionalAttrs cfg.wasm.enable {
                wasm = {
                  runtime_type = "io.containerd.runc.v2";
                  options = {
                    BinaryName = "${pkgs.crun}/bin/crun";
                  };
                };
              }
              // optionalAttrs cfg.kata.enable {
                kata = {
                  runtime_type = "io.containerd.kata.v2";
                  options = {
                    ConfigPath = "${pkgs.kata-runtime}/share/defaults/kata-containers/configuration.toml";
                  };
                };
              }
              // optionalAttrs cfg.gvisor.enable {
                runsc = {
                  runtime_type = "io.containerd.runsc.v1";
                  options = {
                    TypeUrl = "io.containerd.runsc.v1.options";
                    ConfigPath = "";
                  };
                };
              };
          };
        };
      }
    ))
  ];
}
