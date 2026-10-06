#!/usr/bin/env bash
# Hard-coded value guard. Usage: tool/check_hardcoded.sh [paths...]
# Defaults to all of lib/. Fails if numeric/color literals appear in widget code.
# Allowed only in lib/core/theme/ (token definitions).
set -u
cd "$(dirname "$0")/.."
paths=("$@"); [ ${#paths[@]} -eq 0 ] && paths=(lib)
patterns=(
  'EdgeInsets\.(all|symmetric|only|fromLTRB)\(\s*[0-9]'
  'SizedBox\((width|height):\s*[0-9]'
  'BorderRadius\.circular\(\s*[0-9]'
  'Radius\.circular\(\s*[0-9]'
  'fontSize:\s*[0-9]'
  '\bsize:\s*[0-9]'
  'Color\(0x'
  '(^|[^A-Za-z])Colors\.[a-z]'
  '\bDuration\('
  '\b(height|width):\s*[0-9]'
  'withValues\(alpha:\s*[0-9]'
)
fail=0
for pat in "${patterns[@]}"; do
  out=$(grep -rnE --include='*.dart' "$pat" "${paths[@]}" 2>/dev/null \
    | grep -v '^lib/core/theme/' | grep -v '\.g\.dart' | grep -v '\.freezed\.dart')
  if [ -n "$out" ]; then
    echo "== $pat"; echo "$out" | head -${MAX_LINES:-20}
    echo "   ($(echo "$out" | wc -l | tr -d ' ') total)"; fail=1
  fi
done
[ $fail -eq 0 ] && echo "No hard-coded values found." || { echo "Hard-coded values found."; exit 1; }
