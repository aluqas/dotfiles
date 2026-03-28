#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/aluqas/dotfiles.git}"
DEST_DIR="${DEST_DIR:-$HOME/dotfiles}"
DARWIN_HOST="${DARWIN_HOST:-macbook}"

log() {
  printf '\n==> %s\n' "$1"
}

confirm() {
  local prompt="$1"
  local reply

  while true; do
    printf '%s [y/N] ' "$prompt"
    read -r reply
    case "$reply" in
      [Yy] | [Yy][Ee][Ss])
        return 0
        ;;
      "" | [Nn] | [Nn][Oo])
        return 1
        ;;
      *)
        echo "Please answer y or n."
        ;;
    esac
  done
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

append_line_once() {
  local file="$1"
  local line="$2"

  mkdir -p "$(dirname "$file")"
  touch "$file"

  if ! grep -Fqx "$line" "$file"; then
    printf '%s\n' "$line" >>"$file"
  fi
}

source_nix_env() {
  if have_cmd nix; then
    return 0
  fi

  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck source=/dev/null
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    # shellcheck source=/dev/null
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
}

ensure_xcode_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools already installed"
    return 0
  fi

  if ! confirm "Install Xcode Command Line Tools?"; then
    echo "Xcode Command Line Tools are required for macOS bootstrap." >&2
    exit 1
  fi

  log "Installing Xcode Command Line Tools"
  xcode-select --install || true

  echo "Complete the Xcode Command Line Tools installer, then press Enter to continue."
  read -r

  until xcode-select -p >/dev/null 2>&1; do
    echo "Xcode Command Line Tools are not ready yet. Finish the installer, then press Enter to check again."
    read -r
  done
}

ensure_lix() {
  source_nix_env
  if have_cmd nix; then
    local version
    version="$(nix --version 2>/dev/null || true)"
    if printf '%s' "$version" | grep -qi 'lix'; then
      log "Lix already installed"
      return 0
    fi
  fi

  if ! confirm "Install Lix?"; then
    echo "Lix is required for this bootstrap flow." >&2
    exit 1
  fi

  log "Installing Lix"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.lix.systems/lix | sh -s -- install
  source_nix_env
}

ensure_homebrew() {
  if have_cmd brew; then
    log "Homebrew already installed"
  else
    if ! confirm "Install Homebrew?"; then
      echo "Skipping Homebrew installation."
      return 0
    fi

    log "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    append_line_once "$HOME/.zprofile" "eval \"\$(${HOMEBREW_PREFIX:-/opt/homebrew}/bin/brew shellenv)\""
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
    append_line_once "$HOME/.zprofile" "eval \"\$(${HOMEBREW_PREFIX:-/usr/local}/bin/brew shellenv)\""
  fi
}

resolve_repo_dir() {
  local script_dir repo_root

  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$(cd -- "${script_dir}/.." && pwd)"

  if [ -d "${repo_root}/.git" ] && [ -f "${repo_root}/flake.nix" ]; then
    printf '%s\n' "$repo_root"
  else
    printf '%s\n' "$DEST_DIR"
  fi
}

ensure_repo() {
  local repo_dir
  repo_dir="$(resolve_repo_dir)"

  if [ -d "${repo_dir}/.git" ] && [ -f "${repo_dir}/flake.nix" ]; then
    log "Using existing dotfiles checkout at ${repo_dir}"
    printf '%s\n' "$repo_dir"
    return 0
  fi

  if [ -e "$repo_dir" ] && [ ! -d "${repo_dir}/.git" ]; then
    echo "Destination exists but is not a git checkout: ${repo_dir}" >&2
    exit 1
  fi

  log "Cloning dotfiles to ${repo_dir}"
  git clone "$REPO_URL" "$repo_dir"
  printf '%s\n' "$repo_dir"
}

run_initial_switch() {
  local repo_dir="$1"

  if ! confirm "Run initial nix-darwin switch for ${DARWIN_HOST}?"; then
    echo "Skipping initial nix-darwin switch."
    return 0
  fi

  log "Building initial nix-darwin system for ${DARWIN_HOST}"
  cd "$repo_dir"
  nix build ".#darwinConfigurations.${DARWIN_HOST}.system"

  log "Activating initial nix-darwin system for ${DARWIN_HOST}"
  ./result/sw/bin/darwin-rebuild switch --flake ".#${DARWIN_HOST}"
}

main() {
  local os repo_dir

  log "Starting bootstrap"
  os="$(uname -s)"
  echo "Detected OS: ${os}"

  case "$os" in
    Darwin)
      ensure_xcode_clt
      ensure_lix
      ensure_homebrew
      repo_dir="$(ensure_repo)"
      run_initial_switch "$repo_dir"
      ;;
    *)
      echo "Unsupported OS for this bootstrap flow: ${os}" >&2
      exit 1
      ;;
  esac

  log "Bootstrap complete"
  echo "Repo: ${repo_dir}"
  echo "Next time you can switch with: devenv shell, then run: switch-mac"
}

main "$@"
