#!/usr/bin/env bash
set -euo pipefail

echo "🏥 Running System Doctor..."

# 1. Disk Space
echo "Checking disk usage..."
df -h / | grep -v Filesystem | while read -r line; do
  USAGE=$(echo "$line" | awk '{print $5}' | sed 's/%//')
  if [ "$USAGE" -gt 90 ]; then
    echo "❌ Disk usage is critical: ${USAGE}%"
  else
    echo "✅ Disk usage is healthy: ${USAGE}%"
  fi
done

# 2. Systemd Failed Units
if command -v systemctl >/dev/null 2>&1; then
  echo "Checking systemd failed units..."
  if systemctl --failed --quiet; then
    echo "❌ Found failed systemd units:"
    systemctl --failed
  else
    echo "✅ No failed systemd units."
  fi
else
  echo "⚠️ Systemd not found (checking from non-Systemd env?)"
fi

# 3. Flake Lock Freshness
LOCK_FILE="flake.lock"
if [ -f "$LOCK_FILE" ]; then
  LAST_MOD=$(stat -c %Y "$LOCK_FILE" 2>/dev/null || stat -f %m "$LOCK_FILE")
  NOW=$(date +%s)
  DIFF=$((NOW - LAST_MOD))
  DAYS=$((DIFF / 86400))
  if [ "$DAYS" -gt 30 ]; then
    echo "⚠️ Flake lock is ${DAYS} days old. Consider running 'update' inside devenv."
  else
    echo "✅ Flake lock is fresh (${DAYS} days old)."
  fi
else
  echo "❌ flake.lock not found!"
fi

# 4. Age Keys
AGE_KEY="${HOME}/.config/age/keys.txt"
if [ -f "$AGE_KEY" ]; then
  echo "✅ Age identity found."
else
  echo "❌ Age identity NOT found at ${AGE_KEY}. Secrets will not work."
fi

# 5. Nix Store
echo "Checking Nix store consistency (quick check)..."
if nix-store --verify --check-contents --repair >/dev/null 2>&1; then
  echo "✅ Nix store verify passed."
else
  echo "⚠️ Nix store verify found issues (attempted auto-repair)."
fi

echo "✅ Doctor check complete."
