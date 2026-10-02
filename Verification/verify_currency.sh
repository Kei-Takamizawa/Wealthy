#!/bin/sh
set -eu
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_dir=$(mktemp -d /private/tmp/wealthy-currency.XXXXXX)
trap 'rm -rf "$build_dir"' EXIT
xcrun swiftc -parse-as-library -module-cache-path "$build_dir/module-cache" \
  "$repo_root/Wealthy/Wealthy/CurrencyPolicy.swift" \
  "$repo_root/Wealthy/Wealthy/CurrencyManager.swift" \
  "$repo_root/Verification/Currency/main.swift" \
  -o "$build_dir/checks"
"$build_dir/checks"
