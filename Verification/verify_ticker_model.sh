#!/bin/sh
set -eu
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_dir=$(mktemp -d /private/tmp/wealthy-ticker-model.XXXXXX)
output_path=${1:-/private/tmp/wealthy-ticker-model-results.json}
trap 'rm -rf "$build_dir"' EXIT
xcrun swiftc -parse-as-library -module-cache-path "$build_dir/module-cache" \
  "$repo_root/Wealthy/Wealthy/AppLanguage.swift" \
  "$repo_root/Wealthy/Wealthy/AppLocalization.swift" \
  "$repo_root/Wealthy/Wealthy/CurrencyPolicy.swift" \
  "$repo_root/Wealthy/Wealthy/CoreTranslations.swift" \
  "$repo_root/Wealthy/Wealthy/UITranslations.swift" \
  "$repo_root/Wealthy/Wealthy/FinanceTranslations.swift" \
  "$repo_root/Wealthy/Wealthy/LocalLLMService.swift" \
  "$repo_root/Wealthy/Wealthy/ReplyLanguagePolicy.swift" \
  "$repo_root/Wealthy/Wealthy/ReceiptCategoryPolicy.swift" \
  "$repo_root/Wealthy/Wealthy/MoneyTipContext.swift" \
  "$repo_root/Wealthy/Wealthy/FinancialDataSummary.swift" \
  "$repo_root/Wealthy/Wealthy/LanguageManager.swift" \
  "$repo_root/Wealthy/Wealthy/Item.swift" \
  "$repo_root/Verification/TickerAdvice/Evaluate.swift" \
  -o "$build_dir/evaluate"
"$build_dir/evaluate" "$output_path"
