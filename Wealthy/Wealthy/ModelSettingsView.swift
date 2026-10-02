// Foundationの容量表示や端末情報を使えるようにします。
import Foundation
// SwiftUIの画面部品を使えるようにします。
import SwiftUI
// iOS設定アプリを開くためのURLを使えるようにします。
import UIKit

// AIモデルとTickerの言語設定を表示する画面を定義します。
struct ModelSettingsView: View {
    // アプリ全体で選ばれている表示言語を参照します。
    @EnvironmentObject private var lm: LanguageManager
    // 画面遷移の前後を検出し、復帰時に端末状態を更新します。
    @Environment(\.scenePhase) private var scenePhase
    // 共有AIサービスの状態変化をこの画面へ反映します。
    @State private var service = LocalLLMService.shared
    // 取得時に発生したエラーを画面上で知らせます。
    @State private var presentedError: String?

    // この画面の内容を組み立てます。
    var body: some View {
        // 画面全体を縦にスクロールできる一覧として構成します。
        List {
            // 端末のストレージとRAM、および現在の実行状態を最初に表示します。
            Section {
                // 空きストレージと端末物理メモリを一目で確認できるようにします。
                deviceResources
                // 選択中のモデル名と実行準備状態を表示します。
                HStack(spacing: 8) {
                    // 推論実行中なら回転表示、それ以外は準備状態のアイコンを表示します。
                    if service.isThinking {
                        // 推論処理が進行中であることを示します。
                        ProgressView()
                    // 推論実行状態の条件分岐を閉じます。
                    } else {
                        // モデルが利用可能かに応じた状態アイコンを表示します。
                        Image(systemName: service.isReady ? "checkmark.circle.fill" : "info.circle")
                            // 準備完了時は緑、それ以外は二次色にします。
                            .foregroundStyle(service.isReady ? Color.green : Color.secondary)
                    // 推論実行状態の条件分岐を閉じます。
                    }
                    // 選択中のモデル名と読み込み状況を表示します。
                    Text("\(service.currentModel.name) · \(service.loadStatus)")
                        // 長い状態文字列を補助サイズで表示します。
                        .font(.caption)
                        // 状態文字列を二次色で示します。
                        .foregroundStyle(.secondary)
                        // 状態説明は複数行で読めるようにします。
                        .fixedSize(horizontal: false, vertical: true)
                // 実行状態の横並び表示を閉じます。
                }
            // 端末と実行状態セクションを閉じます。
            } header: {
                // 端末状態セクションの見出しを表示言語で設定します。
                Text(text("端末の状態", "Device status"))
            // 端末状態セクションのヘッダー定義を閉じます。
            }

            // AIモデルの選択と端末条件を最初のまとまりにします。
            Section {
                // 利用可能なモデルをカード形式で一つずつ表示します。
                ForEach(orderedModels) { model in
                    // モデルの容量や状態を含むカードを表示します。
                    modelCard(model)
                        // カード間に読みやすい縦余白を設定します。
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        // アプリ管理の取得済みモデルにはスワイプ削除を付けます。
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // Apple OS管理モデルはアプリが削除しないよう除外します。
                            if model.backend != .apple && service.isInstalled(modelId: model.id) {
                                // 選択中のモデルも含めて指定モデルを削除する操作を表示します。
                                Button(role: .destructive) {
                                    // 選ばれたモデルIDだけをサービスへ削除依頼します。
                                    service.deleteModel(id: model.id)
                                // 削除操作のラベルを定義します。
                                } label: {
                                    // 日本語または英語の削除ラベルとアイコンを表示します。
                                    Label(text("モデルを削除", "Delete model"), systemImage: "trash")
                                // 削除操作のラベル範囲を閉じます。
                                }
                                // 読み込み中や推論中に削除が競合しないよう無効にします。
                                .disabled(service.isLoading || service.isThinking)
                            // 取得済みMLXモデルかを調べる条件範囲を閉じます。
                            }
                        // スワイプ操作の定義を閉じます。
                        }
                // モデル一覧の繰り返し範囲を閉じます。
                }
            // モデル一覧セクションの範囲を閉じます。
            } header: {
                // セクション名を現在の表示言語で表示します。
                Text(text("AIモデル", "AI models"))
            // セクションのヘッダー定義を閉じます。
            } footer: {
                // 取得が選択中のモデルを自動変更しないことを説明します。
                Text(text("モデルを取得しても現在の選択は変わりません。取得後に「選択」を押してください。端末RAM目安はアプリ側の保守的な基準で、Apple公表の最低要件ではありません。推論時RAMは最大4,096トークンを前提にした推定で、速度と品質は未検証です。", "Downloading a model does not change the current selection; tap Select after installation. Device RAM guides are conservative app estimates, not Apple-published minimums. Runtime RAM assumes up to 4,096 tokens; speed and quality are unverified."))
            // セクションのフッター定義を閉じます。
            }

            // Tickerの出力言語を設定する項目をまとめます。
            Section(text("Tickerの言語", "Ticker language")) {
                // 保存済みのTicker言語を切り替えるPickerを表示します。
                Picker(text("Tickerの言語", "Ticker language"), selection: tickerLanguageBinding) {
                    // 日本語を選択肢として表示します。
                    Text(text("日本語", "Japanese")).tag("日本語")
                    // 英語を選択肢として表示します。
                    Text("English").tag("English")
                // Pickerの選択肢定義を閉じます。
                }
                // 二つの言語を横並びの選択肢として表示します。
                .pickerStyle(.segmented)
            // Ticker言語セクションの範囲を閉じます。
            }
        // 一覧の内容定義を閉じます。
        }
        // 画面タイトルを現在の表示言語で設定します。
        .navigationTitle(text("AIモデル", "AI models"))
        // 長いモデル説明を含む画面で大きなタイトルを使います。
        .navigationBarTitleDisplayMode(.inline)
        // 画面が表示されたときに利用状況を読み直します。
        .task {
            // OSが現在の端末とモデルの利用可否を再評価します。
            service.refreshAvailability()
            // 画面を開いた時点で読み込みに失敗していれば利用者へ知らせます。
            surfaceLoadErrorIfNeeded()
            // 画面を開いた時点ですでに残っている取得エラーも画面へ表示します。
            if let error = service.downloads.lastError, !error.isEmpty {
                // 取得エラーを一度だけ表示するため画面側へ保存します。
                presentedError = error
            // 保存済みエラーの確認範囲を閉じます。
            }
        // 初回更新タスクの範囲を閉じます。
        }
        // アプリが前面に戻ったときにも利用状況を更新します。
        .onChange(of: scenePhase) { _, phase in
            // 前面表示へ戻った場合だけOSの状態を読み直します。
            if phase == .active {
                // 最新の端末利用可否を共有サービスへ問い合わせます。
                service.refreshAvailability()
            // 前面表示時の条件分岐を閉じます。
            }
        // scenePhaseの監視範囲を閉じます。
        }
        // 取得エラーが設定されたときにアラートを表示します。
        .alert(text("AIモデルの操作に失敗しました", "AI model operation failed"), isPresented: errorAlertBinding) {
            // 利用者がエラー案内を閉じるボタンを表示します。
            Button(text("閉じる", "OK"), role: .cancel) {
                // アラートを閉じるために保持中のエラーを消します。
                presentedError = nil
            // ボタンの処理範囲を閉じます。
            }
        // アラートのボタン定義を閉じます。
        } message: {
            // サービスが返したエラーの詳細を表示します。
            Text(presentedError ?? service.downloads.lastError ?? text("不明なエラーです。", "An unknown error occurred."))
        // アラートのメッセージ定義を閉じます。
        }
        // ダウンロード状態の更新に合わせてエラーを取り込みます。
        .onChange(of: service.downloads.stateVersion) { _, _ in
            // エラーが新しく発生したときに画面のアラートへ渡します。
            if let error = service.downloads.lastError, !error.isEmpty {
                // 取得エラーの文字列を画面状態として保存します。
                presentedError = error
            // エラーの有無を判定する範囲を閉じます。
            }
        // ダウンロード状態の監視範囲を閉じます。
        }
        // モデルの選択・読み込み失敗もloadStatusの変化から利用者へ伝えます。
        .onChange(of: service.loadStatus) { _, _ in
            // status文字列にエラーが含まれる場合に単一のエラーアラートへ渡します。
            surfaceLoadErrorIfNeeded()
        // 読み込み状態の監視範囲を閉じます。
        }
    // bodyの定義範囲を閉じます。
    }

    // Appleモデルを先頭に並べ、残りはカタログの順序で返します。
    private var orderedModels: [OnDeviceAIModel] {
        // Appleモデルを前にする安定した並べ替え結果を返します。
        service.availableModels.sorted { left, right in
            // Appleバックエンドかどうかを比較し、Appleを先頭にします。
            left.backend == .apple && right.backend != .apple
        // 並べ替え条件の範囲を閉じます。
        }
    // orderedModelsの定義範囲を閉じます。
    }

    // 現在の画面言語に合う二言語の文言を選びます。
    private func text(_ japanese: String, _ english: String) -> String {
        // LanguageManagerで選択中の言語が日本語なら日本語を返します。
        lm.currentLanguage == .japanese ? japanese : english
    // text関数の定義範囲を閉じます。
    }

    // 非同期のモデル切替がloadStatusに記録した失敗をアラートへ渡します。
    private func surfaceLoadErrorIfNeeded() {
        // エラーらしい状態だけを選択し、成功や進捗の文言は表示しません。
        let status = service.loadStatus
        // 日本語と英語の代表的なエラー表記を大文字小文字を問わず調べます。
        let normalizedStatus = status.lowercased()
        // 日本語または英語の失敗文言が含まれる場合だけエラーとして保持します。
        if status.contains("エラー") || status.contains("失敗") || status.contains("読み込めません") || status.contains("利用できません") || normalizedStatus.contains("error") || normalizedStatus.contains("fail") || normalizedStatus.contains("unable") || normalizedStatus.contains("could not") {
            // 非同期処理が返した失敗文言を表示用に保存します。
            presentedError = status
        // エラー判定の範囲を閉じます。
        }
    // surfaceLoadErrorIfNeeded関数の定義範囲を閉じます。
    }

    // Ticker言語のget/setをサービスAPIへ接続します。
    private var tickerLanguageBinding: Binding<String> {
        // 現在値の読み出しと変更通知を一つのBindingとして返します。
        Binding(
            // サービスに保存されたTicker言語を読み取ります。
            get: { service.tickerLanguage },
            // 選択された言語をサービス経由で保存します。
            set: { service.setTickerLanguage($0) }
        // Bindingの引数を閉じます。
        )
    // tickerLanguageBindingの定義範囲を閉じます。
    }

    // エラー詳細が存在するときだけ表示するアラートBindingを作ります。
    private var errorAlertBinding: Binding<Bool> {
        // エラー文言の有無を表示状態として読み書きします。
        Binding(
            // エラーが保存されているかをアラート表示状態として返します。
            get: { presentedError != nil },
            // 閉じる操作で一時的なエラー文言を消します。
            set: { isPresented in if !isPresented { presentedError = nil } }
        // Bindingの引数を閉じます。
        )
    // errorAlertBindingの定義範囲を閉じます。
    }

    // 一つのモデルについて詳細と操作を表示します。
    private func modelCard(_ model: OnDeviceAIModel) -> some View {
        // 取得済み状態を先に計算し、選択・削除ボタンで共有します。
        let installed = service.isInstalled(modelId: model.id)
        // このモデルのOS判定と説明文を取得します。
        let compatibility = service.compatibility(for: model)
        // 現在このモデルの取得処理が動いているかを調べます。
        let isDownloading = service.downloads.activeModelID == model.id
        // 他モデルの取得中に開始操作を無言で無視しないよう状態を取得します。
        let isOtherDownloadActive = service.downloads.activeModelID != nil && service.downloads.activeModelID != model.id
        // 現在選択されているモデルかをIDで判定します。
        let isSelected = service.currentModelId == model.id

        // カード内の情報を上から下へ並べます。
        // ローカル変数を宣言した後なので、カード全体を明示的に返します。
        return VStack(alignment: .leading, spacing: 10) {
            // モデル名と取得状態を同じ見出し行に置きます。
            HStack(alignment: .top, spacing: 10) {
                // モデル名とバックエンド情報を縦に表示します。
                VStack(alignment: .leading, spacing: 3) {
                    // カタログにあるモデル名を見出しとして表示します。
                    Text(model.name)
                        // モデル名を強調する見出し書体にします。
                        .font(.headline)
                    // Appleモデルの種類を短く表示し、他のモデルには量子化情報を表示します。
                    Text(model.backend == .apple ? text("Apple Intelligence", "Apple Intelligence") : model.quantization)
                        // 補助情報を小さく表示します。
                        .font(.caption)
                        // 補助情報の色を控えめにします。
                        .foregroundStyle(.secondary)
                // モデル名の縦並びを閉じます。
                }
                // 左側の情報と右側の取得状態を離します。
                Spacer(minLength: 4)
                // 現在の取得状態をアイコンと文言で表示します。
                statusBadge(installed: installed, isDownloading: isDownloading, isApple: model.backend == .apple)
            // 見出し行を閉じます。
            }

            // 取得容量、最低端末RAM、実行時RAM目安を三列に分けて表示します。
            HStack(alignment: .top, spacing: 8) {
                // 取得に必要な容量を表示します。
                metric(title: text("取得容量", "Download"), value: downloadSizeText(for: model))
                // モデルが動作対象とする最低物理RAMを表示します。
                metric(title: text("端末RAM目安", "Device RAM guide"), value: model.backend == .apple ? text("OS管理・不明", "OS-managed · unknown") : byteCount(model.minimumMemoryBytes))
                // 推論時に必要となるRAMの目安を表示します。
                metric(title: text("推論時RAM目安", "Estimated RAM"), value: model.backend == .apple ? text("OS管理・不明", "OS-managed · unknown") : byteCount(model.runtimeMemoryBytes))
            // 容量と端末RAMの情報行を閉じます。
            }

            // 端末の利用可否理由を色とアイコンで表示します。
            HStack(alignment: .top, spacing: 7) {
                // 利用可能か検証済みかに応じたシステムアイコンを表示します。
                Image(systemName: compatibilityIcon(compatibility))
                    // 判定状態に対応する色を設定します。
                    .foregroundStyle(compatibilityColor(compatibility))
                // compatibilityに含まれる端末状況の見出しを表示します。
                Text(compatibility.title)
                    // 判定見出しを小さめに表示します。
                    .font(.subheadline.weight(.semibold))
                    // 判定状態に対応する色を設定します。
                    .foregroundStyle(compatibilityColor(compatibility))
            // 利用可否見出しの行を閉じます。
            }
            // OSまたは実装側から返された具体的な判定理由を表示します。
            Text(compatibility.detail)
                // 理由文を補助サイズで表示します。
                .font(.caption)
                // 理由文を読みやすい二次色にします。
                .foregroundStyle(.secondary)

            // 取得と削除、選択のいずれかを表示します。
            actionRow(model, installed: installed, compatibility: compatibility, isDownloading: isDownloading, isOtherDownloadActive: isOtherDownloadActive, isSelected: isSelected)

            // 配布元を必要とする利用者だけが詳細を開けるようにします。
            if let repoId = model.repoId, !repoId.isEmpty {
                // 初期状態では閉じた詳細欄を表示します。
                DisclosureGroup(text("配布元の詳細", "Source details")) {
                    // Hugging Faceのモデルページへ移動するリンクを表示します。
                    Link(repoId, destination: URL(string: "https://huggingface.co/\(repoId)")!)
                        // 配布元リンクを小さく表示します。
                        .font(.caption)
                // 詳細欄を閉じた表示へ戻せるようにします。
                }
                // 開閉の操作性を保つため補助サイズにします。
                .font(.caption)
            // 配布元情報がある場合の条件範囲を閉じます。
            }
        // カード内容のVStackを閉じます。
        }
        // カード全体を角丸の薄い背景でまとめます。
        .padding(12)
        // カードの背景色を設定します。
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    // modelCard関数の定義範囲を閉じます。
    }

    // 端末の空き容量と物理メモリを画面上部に表示します。
    private var deviceResources: some View {
        // 端末情報を見やすい一行のカードにまとめます。
        HStack(alignment: .top, spacing: 12) {
            // 現在の空きストレージをモデルダウンロード管理側から表示します。
            metric(title: text("空きストレージ", "Free storage"), value: service.downloads.availableStorageBytes.map { byteCount($0) } ?? text("取得できません", "Unavailable"))
            // 物理メモリの総量を推論の端末目安として表示します。
            metric(title: text("端末RAM", "Device RAM"), value: byteCount(ProcessInfo.processInfo.physicalMemory))
        // 端末情報の行を閉じます。
        }
        // 端末情報カードの内側に余白を設けます。
        .padding(12)
        // 端末情報カードの背景色を設定します。
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    // deviceResourcesの定義範囲を閉じます。
    }

    // 小見出しと値を一組にして表示します。
    private func metric(title: String, value: String) -> some View {
        // 二つの文字列を縦方向に配置します。
        VStack(alignment: .leading, spacing: 3) {
            // 項目名を小さい補助文字で表示します。
            Text(title)
                // 項目名にキャプション書体を使います。
                .font(.caption2)
                // 項目名を二次色にします。
                .foregroundStyle(.secondary)
            // 容量やメモリの値を読みやすい太字で表示します。
            Text(value)
                // 値を小見出し書体にします。
                .font(.subheadline.weight(.semibold))
                // 桁の見た目が揃う数字用フォントを使います。
                .monospacedDigit()
                // 値が長い場合に省略できるようにします。
                .lineLimit(1)
                // 項目値を可能な範囲で左揃えにします。
                .minimumScaleFactor(0.8)
        // metricのVStackを閉じます。
        }
        // 二つの指標に均等な横幅を割り当てます。
        .frame(maxWidth: .infinity, alignment: .leading)
    // metric関数の定義範囲を閉じます。
    }

    // モデルの利用状態を色付きのラベルで示します。
    private func statusBadge(installed: Bool, isDownloading: Bool, isApple: Bool) -> some View {
        // 表示する状態アイコンと文言と色を決定します。
        let symbol = isDownloading ? "arrow.down.circle.fill" : isApple ? "apple.logo" : installed ? "checkmark.circle.fill" : "icloud.and.arrow.down"
        // 状態に対応する日本語と英語を選びます。
        let label = isDownloading ? text("取得中", "Downloading") : isApple ? text("OS管理", "OS managed") : installed ? text("取得済", "Installed") : text("未取得", "Not installed")
        // 取得状態をアイコンと短い文言で横並び表示します。
        // 状態ラベルを返り値として明示します。
        return Label(label, systemImage: symbol)
            // ラベル文字を小さく表示します。
            .font(.caption.weight(.semibold))
            // 状態別の色を設定します。
            .foregroundStyle(isDownloading ? Color.blue : isApple ? Color.purple : installed ? Color.green : Color.secondary)
            // 長い状態でも一行で収めます。
            .lineLimit(1)
    // statusBadge関数の定義範囲を閉じます。
    }

    // 選択、取得、停止、削除の操作ボタンを条件に応じて表示します。
    // 条件によって異なるSwiftUI部品を返す関数として構築します。
    @ViewBuilder
    // 指定モデルの状態に応じた操作行を返します。
    private func actionRow(_ model: OnDeviceAIModel, installed: Bool, compatibility: AIModelCompatibility, isDownloading: Bool, isOtherDownloadActive: Bool, isSelected: Bool) -> some View {
        // 読み込みに失敗した選択済みMLXモデルは再試行できるようにします。
        let canRetry = model.backend == .mlx && isSelected && !service.isReady
        // 進行中の取得を止める操作を優先して表示します。
        if isDownloading {
            // 取得率と停止操作を一行に配置します。
            HStack(spacing: 12) {
                // サービスが報告する0から1の進捗率を表示します。
                ProgressView(value: service.downloads.progress)
                    // 進捗バーが残り幅を使うようにします。
                    .frame(maxWidth: .infinity)
                // 取得タスクをキャンセルするボタンを表示します。
                Button(text("停止", "Stop"), systemImage: "stop.circle") {
                    // 現在進行中のモデル取得をサービスへ停止依頼します。
                    service.cancelDownload()
                // 停止ボタンの処理範囲を閉じます。
                }
                // 停止操作に控えめな輪郭付きスタイルを使います。
                .buttonStyle(.bordered)
            // 進捗と停止操作の行を閉じます。
            }
            // 進行率を数値でも読めるように表示します。
            Text("\(Int(service.downloads.progress * 100))%")
                // 進行率の表示を小さくします。
                .font(.caption.monospacedDigit())
                // 進行率の表示を二次色にします。
                .foregroundStyle(.secondary)
        // Appleモデルはアプリ内取得済みフラグを使わず、OS互換性で選択可能か判断します。
        } else if model.backend == .apple {
            // 利用できるAppleモデルを選ぶ操作を表示します。
            if compatibility.canSelect {
                // Appleモデルを現在の利用モデルとして選択するボタンを表示します。
                Button {
                    // Appleモデルへの切替をサービスへ依頼します。
                    Task {
                        // 選択操作はsetModelだけを呼び、モデル取得を自動で始めません。
                        await service.setModel(model)
                        // setModel完了後にloadStatusへ記録された失敗を画面へ伝えます。
                        surfaceLoadErrorIfNeeded()
                    // 非同期のモデル選択タスクを閉じます。
                    }
                // Appleモデル選択ボタンのラベルを定義します。
                } label: {
                    // 選択済みかどうかをラベルで示します。
                    Label(canRetry ? text("再読み込み", "Reload") : isSelected ? text("選択中", "Selected") : text("選択", "Select"), systemImage: canRetry ? "arrow.clockwise" : isSelected ? "checkmark.circle.fill" : "checkmark.circle")
                        // 選択ボタンを行幅に広げます。
                        .frame(maxWidth: .infinity)
                // Appleモデル選択ボタンのラベル定義を閉じます。
                }
                // 選択中のモデルを再度選べないようにします。
                .disabled((isSelected && !canRetry) || service.isLoading || service.isThinking)
                // モデルを切り替える主操作を強調します。
                .buttonStyle(.borderedProminent)
            // Appleモデルが利用可能かの条件分岐を閉じます。
            } else {
                // 利用不可理由とiOS設定を開く案内を縦に表示します。
                VStack(alignment: .leading, spacing: 8) {
                    // 利用不可理由は互換性説明を参照できるよう状態を再掲します。
                    Label(compatibility.title, systemImage: compatibilityIcon(compatibility))
                        // 利用不可の状態を判定色で示します。
                        .foregroundStyle(compatibilityColor(compatibility))
                    // Appleモデルの取得や容量はOSが管理することを説明します。
                    Text(text("AppleモデルはiOSが管理し、使用容量は確認できません。設定 > Apple IntelligenceとSiriで利用状況を確認してください。下のボタンはWealthyのアプリ設定を開きます。", "Apple models are managed by iOS, and their storage size is unavailable here. Check availability in Settings > Apple Intelligence & Siri. The button below opens Wealthy's app settings."))
                        // OS管理の説明を補助サイズで表示します。
                        .font(.caption)
                        // 説明文を二次色にします。
                        .foregroundStyle(.secondary)
                    // 必要に応じてiOSのアプリ設定画面を開くボタンを表示します。
                    Button {
                        // iOSのアプリ設定ページを開こうとします。
                        openApplicationSettings()
                    // 設定案内ボタンのラベルを定義します。
                    } label: {
                        // システム設定を開く意味をボタンで伝えます。
                        Label(text("Wealthyのアプリ設定", "Wealthy app settings"), systemImage: "gearshape")
                    // 設定ボタンのラベル範囲を閉じます。
                    }
                    // 設定への導線に輪郭付きスタイルを使います。
                    .buttonStyle(.bordered)
                // Appleモデルの利用不可案内を閉じます。
                }
            // Appleモデルが利用不可の場合の表示を閉じます。
            }
        // Appleモデルの条件範囲を閉じます。
        } else if installed {
            // 取得済みモデルには選択操作を表示し、削除は行スワイプに置きます。
            HStack(spacing: 8) {
                // 利用可能な取得済みモデルを選択できるボタンを表示します。
                Button {
                    // 未選択で利用可能ならサービスへモデル切替を依頼します。
                    Task {
                        // 選択操作はsetModelだけを呼び、取得は取得ボタンからのみ始めます。
                        await service.setModel(model)
                        // 非同期のモデル選択エラーを確認します。
                        surfaceLoadErrorIfNeeded()
                    // 非同期のモデル選択タスクを閉じます。
                    }
                // 選択ボタンのラベルを定義します。
                } label: {
                    // 選択済みと未選択をアイコンと文言で区別します。
                    Label(canRetry ? text("再読み込み", "Reload") : isSelected ? text("選択中", "Selected") : text("選択", "Select"), systemImage: canRetry ? "arrow.clockwise" : isSelected ? "checkmark.circle.fill" : "checkmark.circle")
                        // 選択ボタンを押しやすい文字サイズにします。
                        .frame(maxWidth: .infinity)
                // ボタンラベル定義を閉じます。
                }
                // 端末で使えないモデルを選べないようにします。
                .disabled(!compatibility.canSelect || (isSelected && !canRetry) || service.isLoading || service.isThinking)
                // 選択操作に強調スタイルを使います。
                .buttonStyle(.borderedProminent)
            // 取得済みモデルの操作行を閉じます。
            }
        // 未取得モデル用の取得操作へ分岐します。
        } else {
            // ダウンロード操作と、容量不足時だけの設定導線を横に置きます。
            HStack(spacing: 8) {
                // 容量不足なら取得を無効にしたまま案内文を表示します。
                Button {
                    // 選んだモデルの取得を開始します。
                    service.startBackgroundDownload(model: model)
                // 取得ボタンのラベルを定義します。
                } label: {
                    // 取得操作のラベルを表示します。
                    Label(isOtherDownloadActive ? text("別モデル取得中", "Another model is downloading") : text("モデルを取得", "Download model"), systemImage: isOtherDownloadActive ? "hourglass" : "arrow.down.circle")
                        // 取得ボタンを残りの横幅に広げます。
                        .frame(maxWidth: .infinity)
                // ボタンラベル定義を閉じます。
                }
                // 空き容量が確認できていて不足している場合に取得を止めます。
                .disabled(storageIsInsufficient(for: model) || service.isLoading || isOtherDownloadActive)
                // 取得操作に強調スタイルを使います。
                .buttonStyle(.borderedProminent)
                // ストレージ不足が判明している場合だけ設定アプリへのボタンを出します。
                if storageIsInsufficient(for: model) {
                    // iOS設定画面を開いて空き容量を確保できるようにします。
                    Button {
                        // iOSのアプリ設定ページを開こうとします。
                        openApplicationSettings()
                    // 設定ボタンのラベルを定義します。
                    } label: {
                        // ストレージ不足を設定アイコンで示します。
                        Label(text("Wealthyの設定", "Wealthy settings"), systemImage: "gearshape")
                    // 設定ボタンのラベル範囲を閉じます。
                    }
                    // 設定への導線に輪郭付きスタイルを使います。
                    .buttonStyle(.bordered)
                // 空き容量不足時だけ設定ボタンを出す条件を閉じます。
                }
            // 未取得モデルの操作行を閉じます。
            }
            // OSの作業領域を含む必要空き容量を不足時に具体的に示します。
            if storageIsInsufficient(for: model) {
                // ダウンロードストアと共通の必要空き容量を表示します。
                Text(text("必要な空き容量: \(byteCount(service.downloads.requiredStorageBytes(for: model)))", "Required free space: \(byteCount(service.downloads.requiredStorageBytes(for: model)))"))
                    // 容量不足の補足説明を小さく表示します。
                    .font(.caption)
                    // 補足説明を二次色にします。
                    .foregroundStyle(.secondary)
            // 空き容量不足の説明条件を閉じます。
            }
        // 未取得モデルの条件範囲を閉じます。
        }
    // actionRow関数の定義範囲を閉じます。
    }

    // Wealthy専用の設定画面を開き、Apple Intelligence設定の場所も案内します。
    private func openApplicationSettings() {
        // UIApplicationのURLはApple IntelligenceではなくWealthy専用設定を開きます。
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            // 開けない場合は本来の確認先を明記したエラーを表示します。
            presentedError = text("Wealthyのアプリ設定を開けませんでした。Appleモデルの状態は設定 > Apple IntelligenceとSiriで確認してください。", "Could not open Wealthy's app settings. Check Apple model availability in Settings > Apple Intelligence & Siri.")
            // URLがないため設定アプリを開く処理を終えます。
            return
        // URL生成の確認範囲を閉じます。
        }
        // 端末がWealthy専用の設定ページを開けるかを確認します。
        UIApplication.shared.open(url) { success in
            // 遷移できなかった場合に手動で確認する正しい設定先を示します。
            if !success {
                // Apple Intelligenceの利用可否はiOSの設定内で確認できます。
                presentedError = text("Wealthyのアプリ設定を開けませんでした。Appleモデルの状態は設定 > Apple IntelligenceとSiriで確認してください。", "Could not open Wealthy's app settings. Check Apple model availability in Settings > Apple Intelligence & Siri.")
            // 設定画面への遷移失敗を確認する範囲を閉じます。
            }
        // 設定アプリを開く完了ハンドラを閉じます。
        }
    // openApplicationSettings関数の定義範囲を閉じます。
    }

    // 空き容量が分かっていて取得サイズを下回る場合にtrueを返します。
    private func storageIsInsufficient(for model: OnDeviceAIModel) -> Bool {
        // 空き容量が未取得なら不足と断定せず、取得可能な場合だけ比較します。
        guard let availableBytes = service.downloads.availableStorageBytes else { return false }
        // ダウンロードストアと共通の作業領域込み閾値を比較します。
        return availableBytes < service.downloads.requiredStorageBytes(for: model)
    // storageIsInsufficient関数の定義範囲を閉じます。
    }

    // Appleモデルの容量はOS管理で非公開として明示します。
    private func downloadSizeText(for model: OnDeviceAIModel) -> String {
        // Apple Intelligenceのモデル容量がアプリから分からないことを説明します。
        if model.backend == .apple { return text("0 B（OS管理・容量非公開）", "0 B (OS managed; size unavailable)") }
        // 通常のモデルではカタログにある取得バイト数を表示します。
        return byteCount(model.downloadBytes)
    // downloadSizeText関数の定義範囲を閉じます。
    }

    // バイト数を十進単位のGBまたはMBで表示します。
    private func byteCount<T: BinaryInteger>(_ bytes: T) -> String {
        // ByteCountFormatterを十進単位に設定します。
        let formatter = ByteCountFormatter()
        // 1 GBを1,000,000,000 bytesとして表示させます。
        formatter.countStyle = .decimal
        // 桁数を抑えてモデル容量を読みやすくします。
        formatter.allowedUnits = [.useMB, .useGB]
        // 変換した容量を文字列として返します。
        return formatter.string(fromByteCount: Int64(clamping: bytes))
    // byteCount関数の定義範囲を閉じます。
    }

    // 互換性判定の状態に対応したアイコンを選びます。
    private func compatibilityIcon(_ compatibility: AIModelCompatibility) -> String {
        // OS判定または実推論が確認済みの場合だけ確定アイコンにし、メモリ推定だけなら疑問符にします。
        compatibility.isVerified ? (compatibility.canSelect ? "checkmark.seal.fill" : "xmark.octagon.fill") : "questionmark.circle.fill"
    // compatibilityIcon関数の定義範囲を閉じます。
    }

    // 互換性判定の状態に対応した色を選びます。
    private func compatibilityColor(_ compatibility: AIModelCompatibility) -> Color {
        // OSまたは実推論による確認結果を緑・赤にし、推定にとどまる場合はオレンジにします。
        compatibility.isVerified ? (compatibility.canSelect ? .green : .red) : .orange
    // compatibilityColor関数の定義範囲を閉じます。
    }
// ModelSettingsViewの定義範囲を閉じます。
}
