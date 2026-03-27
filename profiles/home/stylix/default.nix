{inputs, ...}: {
  stylix = {
    enable = true;
    autoEnable = false;
    base16Scheme = "${inputs.self}/profiles/home/stylix/rose-pine-moon.yaml";

    targets = {
      alacritty = {
        enable = true;
        fonts.enable = false;
        opacity.enable = false;
      };
      fish.enable = true;
      tmux.enable = true;
      zellij.enable = true;
    };
  };
}
