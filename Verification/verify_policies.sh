#!/bin/sh
set -eu
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_dir=$(mktemp -d /private/tmp/wealthy-policies.XXXXXX)
trap 'rm -rf "$build_dir"' EXIT
xcrun swiftc -module-cache-path "$build_dir/module-cache" \
  "$repo_root/LegacyApp/ReplyLanguagePolicy.swift" \
  "$repo_root/Verification/ReplyLanguage/main.swift" -o "$build_dir/language"
"$build_dir/language"
xcrun swiftc -module-cache-path "$build_dir/module-cache" \
  "$repo_root/LegacyApp/ChatRetentionPolicy.swift" \
  "$repo_root/Verification/ChatRetention/main.swift" -o "$build_dir/retention"
"$build_dir/retention"
xcrun swiftc -module-cache-path "$build_dir/module-cache" \
  "$repo_root/LegacyApp/AITickerProjection.swift" \
  "$repo_root/Verification/ChatRetention/TickerProjection/main.swift" -o "$build_dir/projection"
"$build_dir/projection"
