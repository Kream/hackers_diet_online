#!/bin/bash
# Compare two golden-run directories, ignoring per-run session tokens
# Usage: ./compare-golden.sh <test-dir> <reference-dir>
set -euo pipefail

TEST="${1:?Usage: $0 <test-dir> <reference-dir>}"
REF="${2:?Usage: $0 <test-dir> <reference-dir>}"

sanitize() {
  sed -E \
    -e 's/[0-9FGJKQW]{48}/COOKIE/g' \
    -e 's/[0-9FGJKQW]{40}/SESSION/g' \
    -e 's/qx=[A-Za-z0-9]*/qx=QX/g' \
    "$1"
}

fail=0

# Exact files
for f in 2025-12.hdb 2026-01.hdb 2026-02.hdb 2026-04.hdb export-jan.xml chart-jan.png chart-hist.png LastTransaction.hdl session-check.txt remember-check.txt pub-check.txt import-check.txt; do
  if ! cmp -s "$TEST/$f" "$REF/$f"; then
    echo "MISMATCH (exact): $f"
    fail=1
  else
    echo "OK (exact): $f"
  fi
done

# HTML files (normalized)
for f in view-jan.html view-trend.html view-cal.html view-mar.html view-feb.html view-apr.html session-old.html remember-login.html remember-cookie-login.html remember-replay.html pub-settings.html pub-browse.html pub-account.html pub-view-jan.html import-jan.html; do
  if ! diff -q <(sanitize "$TEST/$f") <(sanitize "$REF/$f") >/dev/null; then
    echo "MISMATCH (normalized HTML): $f"
    fail=1
  else
    echo "OK (normalized HTML): $f"
  fi
done

if [[ $fail -eq 0 ]]; then
  echo "All oracles match (after normalization)."
  exit 0
else
  echo "Differences found."
  exit 1
fi
