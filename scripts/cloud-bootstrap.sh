#!/usr/bin/env bash
set -euo pipefail

# 使い方
usage() {
  echo "Usage: $0 <target-ip> [ssh-user]"
  echo "  target-ip: ターゲットマシンの IP address"
  echo "  ssh-user:  SSH user（OCI では既定で ubuntu）"
  echo ""
  echo "Example: $0 123.45.67.89"
  echo "Example: $0 123.45.67.89 root"
  exit 1
}

# 引数を確認する
if [ "$#" -lt 1 ]; then
  usage
fi

TARGET_IP=$1
SSH_USER=${2:-ubuntu} # OCI では ubuntu user が既定
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(cd -- "${SCRIPT_DIR}/../.." && pwd)
FLAKE_ATTR="${ROOT_DIR}#nixos-bootstrap"
KEY_TRANSFER_DIR="${ROOT_DIR}/secrets/KEY_TRANSFER"

# cleanup 関数（終了時に必ず実行）
cleanup() {
  echo "🧹 Cleaning up temporary files..."
  rm -rf "$KEY_TRANSFER_DIR"
}
trap cleanup EXIT

echo "🚀 Starting NixOS installation on ${TARGET_IP}..."
echo "Target Flake: ${FLAKE_ATTR}"
echo "SSH User: ${SSH_USER}"

# ユーザーに確認する
echo -n "⚠️  WARNING: This will WIPE the target disk on ${TARGET_IP}. Are you sure? [y/N] "
read -r REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

# 衝突を避けるため、古い host key を削除する
echo "🧹 Removing old SSH host keys for ${TARGET_IP}..."
ssh-keygen -R "${TARGET_IP}" 2>/dev/null || true

# Age key の存在を確認する
AGE_KEY_FILE="${HOME}/.config/age/keys.txt"
if [ ! -f "$AGE_KEY_FILE" ]; then
  echo "❌ Age key not found at ${AGE_KEY_FILE}"
  echo "このスクリプトを実行する前に Age private key を用意してください。"
  exit 1
fi

# secret と /persist 構造を転送用に準備する
echo "🔑 Preparing Age identity and /persist structure for transfer..."

# impermanence が期待する /persist 構造をまとめて作る
mkdir -p "${KEY_TRANSFER_DIR}/var/lib/age"
mkdir -p "${KEY_TRANSFER_DIR}/persist/etc/ssh"
mkdir -p "${KEY_TRANSFER_DIR}/persist/etc/NetworkManager/system-connections"
mkdir -p "${KEY_TRANSFER_DIR}/persist/etc/rancher"
mkdir -p "${KEY_TRANSFER_DIR}/persist/var/lib/nixos"
mkdir -p "${KEY_TRANSFER_DIR}/persist/var/lib/tailscale"
mkdir -p "${KEY_TRANSFER_DIR}/persist/var/lib/docker"
mkdir -p "${KEY_TRANSFER_DIR}/persist/var/lib/containers"
mkdir -p "${KEY_TRANSFER_DIR}/persist/var/lib/rancher"
mkdir -p "${KEY_TRANSFER_DIR}/persist/var/lib/acme"
mkdir -p "${KEY_TRANSFER_DIR}/persist/var/lib/age"
mkdir -p "${KEY_TRANSFER_DIR}/persist/var/lib/systemd/coredump"
mkdir -p "${KEY_TRANSFER_DIR}/persist/var/log"
mkdir -p "${KEY_TRANSFER_DIR}/persist/home/saqula/.ssh"
mkdir -p "${KEY_TRANSFER_DIR}/persist/home/saqula/.gnupg"
mkdir -p "${KEY_TRANSFER_DIR}/persist/home/saqula/.kube"
mkdir -p "${KEY_TRANSFER_DIR}/persist/home/saqula/.docker"
mkdir -p "${KEY_TRANSFER_DIR}/persist/home/saqula/.config/gh"
mkdir -p "${KEY_TRANSFER_DIR}/persist/home/saqula/.local/share/fish"
mkdir -p "${KEY_TRANSFER_DIR}/persist/home/saqula/.local/share/zoxide"
mkdir -p "${KEY_TRANSFER_DIR}/persist/home/saqula/.local/share/direnv"
mkdir -p "${KEY_TRANSFER_DIR}/persist/home/saqula/.local/share/mise"
mkdir -p "${KEY_TRANSFER_DIR}/persist/home/saqula/.cache/mise"
mkdir -p "${KEY_TRANSFER_DIR}/persist/home/saqula/.local/share/nvim"
mkdir -p "${KEY_TRANSFER_DIR}/persist/home/saqula/.vscode-server"
mkdir -p "${KEY_TRANSFER_DIR}/persist/home/saqula/dotfiles"

# ブートストラップ時に使う互換コピーを /var/lib/age に残すが、
# 長期的な source of truth は /persist/var/lib/age/keys.txt とする。
cp "$AGE_KEY_FILE" "${KEY_TRANSFER_DIR}/var/lib/age/keys.txt"
cp "$AGE_KEY_FILE" "${KEY_TRANSFER_DIR}/persist/var/lib/age/keys.txt"
chmod 600 "${KEY_TRANSFER_DIR}/var/lib/age/keys.txt"
chmod 600 "${KEY_TRANSFER_DIR}/persist/var/lib/age/keys.txt"

# 必要なら machine-id を生成する
echo "Generating machine-id..."
head -c 16 /dev/urandom | xxd -p >"${KEY_TRANSFER_DIR}/persist/etc/machine-id"
chmod 444 "${KEY_TRANSFER_DIR}/persist/etc/machine-id"

# systemd 用の random-seed を生成する（impermanence で必要）
echo "Generating random-seed..."
mkdir -p "${KEY_TRANSFER_DIR}/persist/var/lib/systemd"
head -c 32 /dev/urandom >"${KEY_TRANSFER_DIR}/persist/var/lib/systemd/random-seed"
chmod 600 "${KEY_TRANSFER_DIR}/persist/var/lib/systemd/random-seed"

echo "📂 /persist structure prepared:"
find "${KEY_TRANSFER_DIR}/persist" -type f | head -20

echo "📦 Running nixos-anywhere..."
nix run github:nix-community/nixos-anywhere -- \
  --flake "${FLAKE_ATTR}" \
  --target-host "${SSH_USER}@${TARGET_IP}" \
  --build-on-remote \
  --extra-files "${KEY_TRANSFER_DIR}" \
  --debug

echo "✅ Installation complete! System should reboot shortly."
echo "You can SSH with: ssh saqula@${TARGET_IP}"
