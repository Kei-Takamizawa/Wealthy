# Wealthy

[English](README.md) · 日本語

iPhoneとiPadで支出・収入・残高を管理するアプリです。家計データの保存、レシートの文字認識、AI推論は端末内で行います。

## 機能

- カテゴリと財布を使い分けて、支出・収入を記録。
- レシートを読み取り、画像を支出記録とともに保存。
- カレンダーで取引を確認し、カテゴリ別の支出を分析。
- 月ごとの固定収支を設定し、アプリを開いたときに反映。
- 端末内のAIチャットと、JSONによる記録の書き出し・読み込み。

## はじめに

iOSまたはiPadOS 26.0以降が必要です。新規インストール時の表示言語は英語です。初回設定、または **ホーム → 設定 → 言語設定** で日本語を選べます。選択した言語は次回起動にも引き継がれます。

レシートの文字認識と手入力は、追加AIモデルのダウンロードとは独立して使えます。初期のAIプロバイダーはApple Foundation Modelsです。利用可否は端末とApple Intelligenceの設定によって決まります。

## 端末内AI

**ホーム → 設定 → AIモデル管理** で、モデルの容量、取得状況、使用端末での利用可否を確認できます。追加モデルは取得後に選択します。ダウンロードだけでは使用中のモデルは変わりません。

| モデル | 形式 | 取得容量 | 端末RAMの目安 | 推論RAMの見積もり |
| --- | --- | ---: | ---: | ---: |
| Apple Foundation Models | OS管理 | 下記参照 | iOSが判定 | 未測定 |
| [Bonsai 8B](https://huggingface.co/inferencerlabs/Bonsai-8B-MLX-Q2) | MLX 2-bit | 2.32 GB | 6 GB | 3.5 GB |
| [MiniCPM5-1B (Reasoning)](https://huggingface.co/mlx-community/MiniCPM5-1B-4bit) | MLX 4-bit | 0.62 GB | 4 GB | 1.6 GB |
| [MiniCPM5-2B](https://huggingface.co/mlx-community/MiniCPM5-2B-mlx-4Bit) | MLX 4-bit | 1.43 GB | 6 GB | 2.5 GB |
| [K2 Horizon 3.7B](https://huggingface.co/mlx-community/K2-Horizon-3.7B-4bit) | MLX 4/8-bit混合 | 4.16 GB | 8 GB | 5.6 GB |

容量は2026年10月2日に固定されたモデルrevisionのファイル一覧で確認しました。GBは十進単位です。4モデルの合計は約 **8.52 GB** で、取得中は追加の空き容量も必要です。同時に読み込むモデルは1つです。

Appleモデルの取得・準備はOSが管理します。Wealthyによる追加取得は **0 B** ですが、OSモデル自体の使用容量がゼロという意味ではありません。[Appleの利用可否API](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.property)を使い、非対応端末、Apple Intelligence無効、モデル準備中を区別して表示します。

RAMはアプリ側の見積もりで、動作確認済みの最低要件ではありません。追加モデルにはMetalと十分な空きメモリが必要です。利用可否は、その起動中に1トークンの実推論が成功するまでは推定扱いです。この確認だけでは品質・速度・長時間の安定性は分かりません。SimulatorではMLXモデルを選択できません。

Bonsaiは第三者による2-bit変換版を採用しており、公式の1-bit版とは異なります。K2はSwiftの独自実装を使います。モデル取得にはインターネット接続が必要です。中断・失敗したダウンロードを取得済みとは扱いません。実装の詳細は[モデル管理の説明](Verification/AIModels/ModelManagement.md)を参照してください。

## レシートの確認

Apple Visionで日本語と英語を認識します。明示的な合計ラベルから、曖昧さのない合計額を選べた場合だけ金額を自動入力します。AIはこの金額を上書きしません。合計が不明な場合は保存画像を確認し、金額を入力してから保存します。

自動抽出の対象は円の整数金額です。ぼけ・影・未対応の合計ラベル、小数や負数の金額は手入力が必要になる場合があります。撮影した実レシートの認識精度は未測定です。

## データとバックアップ

記録とレシート画像は端末内に保存します。JSONの書き出しには記録とチャット履歴が含まれますが、**レシート画像の実体と取得済みモデルは含まれません**。読み込みは既存の記録を置き換えます。画像も残す場合は、別途保管してください。

## ビルドと検証

Xcodeで `Wealthy/Wealthy.xcodeproj` を開き、**Wealthy** スキームを選択し、署名と対応端末を設定してください。下記のビルド確認にはXcode 27.0とSDK 27.0を使っています。利用可能な最古のXcodeバージョンを確認したものではありません。

2026年10月2日に行った、レシート・モデル実装の検証記録です。

| 検査 | 結果 | 対象 |
| --- | --- | --- |
| レシート抽出ルール | 42/42件通過 | 文字列と座標の固定データ |
| モデルの会話テンプレート | 26項目通過 | Swift Jinja、重みの取得なし |
| ダウンロード管理 | キャンセル8回を含め通過 | ローカルHTTPサーバーと合成ファイル |
| アプリ全体のビルド | 成功 | Simulator向け・署名なしの実機向け |
| ネイティブモデル検証コード | 型チェック通過 | 数値実行は未実施 |

その後の言語デフォルト変更についても、Simulator向けビルドとコードの日本語コメント監査が通過しました。

レシートは `python3 Verification/verify_receipt_ocr.py`、ダウンロードは `python3 Verification/ai_model_download_fixture.py`、コードの日本語コメント監査は `python3 Verification/verify_ai_comments.py` で検査できます。テンプレート検査は `python3 Verification/verify_ai_templates.py --checkouts PATH` です。`PATH` にはXcodeの依存パッケージのcheckoutsディレクトリを指定します。

これらはアプリ起動、カメラ撮影、実機でのAppleモデルの応答、追加4モデルの実重み推論を確認する試験ではありません。速度・メモリ使用量のピーク・認識品質は未測定です。残る数値検証は[ネイティブモデルの検証記録](Verification/AIModels/NativeModelVerification.md)に記載しています。

## ライセンス

All rights reserved. ソースコードおよびバイナリの再配布には許可が必要です。
