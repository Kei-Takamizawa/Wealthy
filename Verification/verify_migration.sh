#!/bin/sh
set -eu
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_dir=$(mktemp -d /private/tmp/wealthy-migration.XXXXXX)
trap 'rm -rf "$build_dir"' EXIT
git -C "$repo_root" show c0120a0:Wealthy/Wealthy/Item.swift > "$build_dir/LegacyItem.swift"
xcrun swiftc -parse-as-library -module-cache-path "$build_dir/module-cache" \
  "$build_dir/LegacyItem.swift" "$repo_root/Verification/Migration/Create.swift" -o "$build_dir/create"
"$build_dir/create" "$build_dir/store.sqlite"
xcrun swiftc -parse-as-library -module-cache-path "$build_dir/module-cache" \
  "$repo_root/Wealthy/Wealthy/CurrencyPolicy.swift" \
  "$repo_root/Wealthy/Wealthy/Item.swift" "$repo_root/Verification/Migration/Validate.swift" -o "$build_dir/validate"
"$build_dir/validate" "$build_dir/store.sqlite"
