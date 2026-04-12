#!/usr/bin/env bash
# validate.sh — Validates rule file format in rules/
# Usage: ./scripts/validate.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$(dirname "$SCRIPT_DIR")/rules"

errors=0
checked=0

for rule_file in "$RULES_DIR"/*.md; do
  filename="$(basename "$rule_file")"

  # Skip meta files
  [[ "$filename" == _* ]] && continue

  checked=$((checked + 1))

  # Check prefix matches a valid category
  prefix="${filename%%-*}-"
  valid_prefixes="access- config- supply- crypto- inject- design- auth- integrity- logging- error-"
  if ! echo "$valid_prefixes" | grep -qw "$prefix"; then
    echo "ERROR: $filename — invalid prefix '$prefix'"
    errors=$((errors + 1))
  fi

  # Check for required sections
  if ! grep -q '^\*\*Incorrect' "$rule_file"; then
    echo "ERROR: $filename — missing **Incorrect** section"
    errors=$((errors + 1))
  fi

  if ! grep -q '^\*\*Correct' "$rule_file"; then
    echo "ERROR: $filename — missing **Correct** section"
    errors=$((errors + 1))
  fi

  if ! grep -q '^\*\*Azure/Cloud' "$rule_file"; then
    echo "WARN:  $filename — missing **Azure/Cloud** section"
  fi

  if ! grep -q '^\*\*References' "$rule_file"; then
    echo "WARN:  $filename — missing **References** section"
  fi

  # Check for code blocks
  code_blocks=$(grep -c '```' "$rule_file" || true)
  if [ "$code_blocks" -lt 4 ]; then
    echo "WARN:  $filename — fewer than 2 code examples (found $((code_blocks / 2)) blocks)"
  fi

  # Check title exists (first line should be ## heading)
  first_line=$(head -1 "$rule_file")
  if ! echo "$first_line" | grep -q '^## '; then
    echo "ERROR: $filename — first line must be a ## heading"
    errors=$((errors + 1))
  fi
done

echo ""
echo "Checked $checked rule files, found $errors errors"

if [ "$errors" -gt 0 ]; then
  exit 1
fi

echo "All rules valid."
