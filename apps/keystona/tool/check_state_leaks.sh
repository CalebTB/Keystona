#!/usr/bin/env bash
# Guards against state that outlives a screen and reappears on another.
#   1. Every keepAlive provider must be on tool/keepalive_allowlist.txt.
#   2. No screen writes into a provider from an addPostFrameCallback (the
#      "re-apply on every rebuild" pattern: apply input once, from initState).
# Usage (from apps/keystona): tool/check_state_leaks.sh
set -u
cd "$(dirname "$0")/.."
fail=0

# Expected keepAlive count for a path, from the allowlist (0 when absent).
expected_for() {
  awk -F'|' -v p="$1" '
    /^[[:space:]]*#/ || NF < 2 { next }
    { path=$1; gsub(/^[ \t]+|[ \t]+$/, "", path)
      n=$2;    gsub(/[ \t]/, "", n)
      if (path == p) { print n; found=1 } }
    END { if (!found) print 0 }' tool/keepalive_allowlist.txt
}

# ── 1. keepAlive allowlist ──────────────────────────────────────────────────
while IFS= read -r file; do
  rel=${file#lib/}
  actual=$(grep -cE 'keepAlive: true|ref\.keepAlive\(\)' "$file")
  expected=$(expected_for "$rel")
  if [ "$actual" -ne "$expected" ]; then
    echo "keepAlive not reviewed: $rel has $actual (allowlist says $expected)"
    echo "  -> flow state (a form, draft, scan) must not be kept alive without a reset on every exit"
    echo "     and entry; add it to tool/keepalive_allowlist.txt with the reason and the test."
    fail=1
  fi
done < <(grep -rlE 'keepAlive: true|ref\.keepAlive\(\)' lib --include='*.dart' | grep -v '\.g\.dart')

# Allowlist entries whose file no longer has a keepAlive are stale.
while IFS= read -r rel; do
  [ -z "$rel" ] && continue
  if [ ! -f "lib/$rel" ] || ! grep -qE 'keepAlive: true|ref\.keepAlive\(\)' "lib/$rel"; then
    echo "stale allowlist entry (no keepAlive in lib/$rel): remove it from tool/keepalive_allowlist.txt"
    fail=1
  fi
done < <(awk -F'|' '/^[[:space:]]*#/ || NF < 2 { next } { p=$1; gsub(/^[ \t]+|[ \t]+$/, "", p); print p }' tool/keepalive_allowlist.txt)

# ── 2. writes to providers from post-frame callbacks ────────────────────────
hits=$(grep -rn -A4 'addPostFrameCallback' lib --include='*.dart' | grep -v '\.g\.dart' \
  | grep -E '\.notifier\b|notifier\.[a-z]' | grep -v 'state-leak-ok')
if [ -n "$hits" ]; then
  echo "Provider written from a post-frame callback (re-applies on every rebuild):"
  echo "$hits"
  echo "  -> apply input once from initState (ref.listenManual + one post-frame read)."
  echo "     Mark a deliberate exception with // state-leak-ok."
  fail=1
fi

[ $fail -eq 0 ] && echo "No state-leak risks found." || exit 1
