# Tau（Taubyte）分散 PaaS
#
# WebAssembly ベースの分散 platform
# https://tau.how
#
# 注意: 自己完結した local cloud simulation のために `@taubyte/dream-cli` を使う。
# lab 環境向き。production node では `tau` binary を使う。
#
{pkgs, ...}: {
  # 一部の操作で Tau は Docker を必要とする
  virtualisation.docker.enable = true;

  # firewall port を開く
  networking.firewall.allowedTCPPorts = [
    8080
    4242
  ];

  environment.systemPackages = with pkgs; [
    nodejs # dream-cli に必要
    (writeScriptBin "install-tau-cli" ''
      #!/usr/bin/env bash
      echo "Installing Tau CLI tools..."

      # local development 用に dream-cli を install する
      npm install -g @taubyte/dream-cli

      echo "Tau CLI installed!"
      echo "Run 'dream' to start local Tau environment"
    '')
    (writeScriptBin "tau-start" ''
      #!/usr/bin/env bash
      echo "Starting Tau local environment..."
      npx @taubyte/dream-cli
    '')
  ];
}
