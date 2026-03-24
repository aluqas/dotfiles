{inputs, ...}: [
  # 1. Rust Overlay
  inputs.rust-overlay.overlays.default

  # 2. Project Overlays
  (_final: prev: {
    # toolchain の短縮名
    rustToolchains = {
      stable = prev.rust-bin.stable.latest.default;
      nightly = prev.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
    };

    # 3. Crane Lib (Build Optimization)
    craneLib = inputs.crane.mkLib prev;
  })
]
