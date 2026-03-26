#!/usr/bin/env bash
set -euo pipefail

# Ubuntu/Debian ベースの Lima VM を前提に、
# containerd + nerdctl + youki を構成する。

if ! command -v apt-get >/dev/null 2>&1; then
  echo "この初期化スクリプトは apt-get 環境（Ubuntu/Debian）を前提にしています。" >&2
  echo "必要なら手動で containerd / nerdctl / youki を導入してください。" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl jq tar xz-utils uidmap

# containerd は Lima の containerd.system=true で有効化されるが、
# 念のため導入と起動を明示する。
apt-get install -y containerd
systemctl enable --now containerd

NERDCTL_VERSION="${NERDCTL_VERSION:-2.1.6}"
YOUKI_VERSION="${YOUKI_VERSION:-0.5.6}"
ARCH="$(dpkg --print-architecture)"

case "${ARCH}" in
  amd64)
    NERDCTL_ARCH="amd64"
    YOUKI_ARCH="x86_64"
    ;;
  arm64)
    NERDCTL_ARCH="arm64"
    YOUKI_ARCH="aarch64"
    ;;
  *)
    echo "未対応のアーキテクチャです: ${ARCH}" >&2
    exit 1
    ;;
esac

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

curl -fsSL -o "${tmp_dir}/nerdctl-full.tgz" \
  "https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-full-${NERDCTL_VERSION}-linux-${NERDCTL_ARCH}.tar.gz"
tar -C /usr/local -xzf "${tmp_dir}/nerdctl-full.tgz"

curl -fsSL -o "${tmp_dir}/youki.tgz" \
  "https://github.com/containers/youki/releases/download/v${YOUKI_VERSION}/youki-v${YOUKI_VERSION}-${YOUKI_ARCH}-musl.tar.gz"
tar -C "${tmp_dir}" -xzf "${tmp_dir}/youki.tgz"
install -m 0755 "${tmp_dir}/youki" /usr/local/bin/youki

mkdir -p /etc/containerd
if [ ! -f /etc/containerd/config.toml ]; then
  containerd config default >/etc/containerd/config.toml
fi

if ! grep -q '\[plugins\."io.containerd.grpc.v1.cri".containerd.runtimes.youki\]' /etc/containerd/config.toml; then
  cat >>/etc/containerd/config.toml <<'EOF'

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.youki]
  runtime_type = "io.containerd.runc.v2"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.youki.options]
  BinaryName = "/usr/local/bin/youki"
  SystemdCgroup = true
EOF
fi

systemctl restart containerd

echo "=== containerd ==="
systemctl --no-pager --full status containerd | sed -n '1,20p'
echo "=== nerdctl ==="
nerdctl --version
echo "=== youki ==="
youki --version || true
echo "初期化完了: sudo nerdctl run --runtime youki --rm hello-world"
