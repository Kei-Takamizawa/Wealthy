#!/bin/sh
set -eu
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_dir=$(mktemp -d /private/tmp/wealthy-backup-verification.XXXXXX)
trap 'rm -rf "$build_dir"' EXIT
xcrun swiftc -module-cache-path "$build_dir/module-cache" \
  "$repo_root/Wealthy/Wealthy/AppLanguage.swift" \
  "$repo_root/Wealthy/Wealthy/AppLocalization.swift" \
  "$repo_root/Wealthy/Wealthy/CurrencyPolicy.swift" \
  "$repo_root/Wealthy/Wealthy/CoreTranslations.swift" \
  "$repo_root/Wealthy/Wealthy/UITranslations.swift" \
  "$repo_root/Wealthy/Wealthy/FinanceTranslations.swift" \
  "$repo_root/Wealthy/Wealthy/BackupArchiveCodec.swift" \
  "$repo_root/Wealthy/Wealthy/BackupManager.swift" \
  "$repo_root/Wealthy/Wealthy/Item.swift" \
  "$repo_root/Wealthy/Wealthy/ChatMessageModel.swift" \
  "$repo_root/Verification/Backup/main.swift" \
  -o "$build_dir/checks"
"$build_dir/checks"
