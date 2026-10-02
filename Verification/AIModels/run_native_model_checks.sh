#!/bin/zsh
# エラー・未定義変数・パイプ内エラーを見逃さず検証を停止します。
set -euo pipefail
# この検証スクリプトからプロジェクトルートの絶対パスを取得します。
project_root="${0:A:h:h:h}"
# 起動済みSimulatorのUUIDを明示的な第1引数で受け取ります。
simulator_id="${1:-}"
# 依存を再取得せず、既存ビルド済み依存の場所を第2引数で差し替え可能にします。
products="${2:-/private/tmp/wealthy-ocr-build/Build/Products/Debug-iphonesimulator}"
# 依存ソースのチェックアウトを第3引数で差し替え可能にします。
checkouts="${3:-/private/tmp/wealthy-ocr-packages/checkouts}"
# Simulatorの指定がなければ、実行できていない理由と使用方法を示します。
if [[ -z "$simulator_id" ]]; then
    # 大きなモデルやSimulator runtimeを暗黙取得せず、必要な実行環境を説明します。
    print -u2 'Not executed: pass an existing booted Simulator UUID, then optional Products and checkouts paths.'
    # 検証失敗とは区別できる環境未準備コードで停止します。
    exit 2
# Simulator指定の必須確認を閉じます。
fi
# 中間成果物はアプリのモデル保存領域と無関係な一時フォルダへ置きます。
build_dir="$(mktemp -d /private/tmp/wealthy-native-checks.XXXXXX)"
# インストール済みXcodeからSimulator SDKの場所を取得します。
sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
# 既存のSimulator依存モジュールへ接続するコンパイル引数をまとめます。
common_args=(-swift-version 5 -default-isolation MainActor -warnings-as-errors -target arm64-apple-ios18.0-simulator -sdk "$sdk" -I "$products" -I "$checkouts/mlx-swift/Source/Cmlx/include" -I "$checkouts/mlx-swift/Source/Cmlx/mlx-c" -I "$checkouts/mlx-swift/Source/Cmlx" -I "$checkouts/swift-numerics/Sources/_NumericsShims/include" -module-cache-path "$build_dir/modules")
# 実アプリの2モデル実装と小さい検証入口を同じモジュールとしてコンパイルします。
sources=("$project_root/Wealthy/Wealthy/K2HorizonModel.swift" "$project_root/Wealthy/Wealthy/BonsaiModelSupport.swift" "$project_root/Verification/AIModels/NativeModelChecks.swift")
# 使用する依存オブジェクトは既存のSwift packageビルド結果だけに限定します。
objects=("$products"/*.o)
# 大きな学習済み重みなしで、既存依存をリンクした検証プログラムを作ります。
xcrun swiftc "${common_args[@]}" "${sources[@]}" "${objects[@]}" -framework Metal -framework Accelerate -lc++ -o "$build_dir/native-model-checks"
# 指定した起動済みSimulatorでCPU演算の数値検証を実際に実行します。
xcrun simctl spawn "$simulator_id" "$build_dir/native-model-checks"
