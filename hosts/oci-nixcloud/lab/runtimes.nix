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
  ...
}: let
  inherit
    (lib)
    optional
    optionalAttrs
    ;

  enableYouki = true;
  enableCrun = true;
  enableKata = false;
  enableGvisor = false;
  enableWasm = false;
in {
  # Runtime packages
  environment.systemPackages = with pkgs;
    [runc]
    ++ optional enableYouki youki
    ++ optional enableCrun crun
    ++ optional enableKata kata-runtime
    ++ optional enableGvisor gvisor;

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
        // optionalAttrs enableYouki {
          youki = {
            runtime_type = "io.containerd.runc.v2";
            options = {
              BinaryName = "${pkgs.youki}/bin/youki";
              SystemdCgroup = true;
            };
          };
        }
        // optionalAttrs enableCrun {
          crun = {
            runtime_type = "io.containerd.runc.v2";
            options = {
              BinaryName = "${pkgs.crun}/bin/crun";
              SystemdCgroup = true;
            };
          };
        }
        // optionalAttrs enableWasm {
          wasm = {
            runtime_type = "io.containerd.runc.v2";
            options = {
              BinaryName = "${pkgs.crun}/bin/crun";
            };
          };
        }
        // optionalAttrs enableKata {
          kata = {
            runtime_type = "io.containerd.kata.v2";
            options = {
              ConfigPath = "${pkgs.kata-runtime}/share/defaults/kata-containers/configuration.toml";
            };
          };
        }
        // optionalAttrs enableGvisor {
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
