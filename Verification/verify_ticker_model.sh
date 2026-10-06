#!/bin/sh
set -eu
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_dir=$(mktemp -d /private/tmp/wealthy-ticker-model.XXXXXX)
output_path=${1:-/private/tmp/wealthy-ticker-model-results.json}
trap 'rm -rf "$build_dir"' EXIT
xcrun swiftc -parse-as-library -module-cache-path "$build_dir/module-cache" \
  "$repo_root/LegacyApp/AppLanguage.swift" \
  "$repo_root/LegacyApp/AppLocalization.swift" \
  "$repo_root/LegacyApp/CurrencyPolicy.swift" \
  "$repo_root/LegacyApp/CoreTranslations.swift" \
  "$repo_root/LegacyApp/UITranslations.swift" \
  "$repo_root/LegacyApp/FinanceTranslations.swift" \
  "$repo_root/LegacyApp/LocalLLMService.swift" \
  "$repo_root/LegacyApp/ReplyLanguagePolicy.swift" \
  "$repo_root/LegacyApp/ReceiptCategoryPolicy.swift" \
  "$repo_root/LegacyApp/MoneyTipContext.swift" \
  "$repo_root/LegacyApp/FinancialDataSummary.swift" \
  "$repo_root/LegacyApp/LanguageManager.swift" \
  "$repo_root/LegacyApp/Item.swift" \
  "$repo_root/Verification/TickerAdvice/Evaluate.swift" \
  -o "$build_dir/evaluate"
"$build_dir/evaluate" "$output_path"
