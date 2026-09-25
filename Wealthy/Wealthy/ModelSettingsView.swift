// `SwiftUI` の機能をこのファイルで使えるように読み込みます。
import SwiftUI

// `ModelSettingsView` という構造体を定義し、関連する値や処理をまとめます。
struct ModelSettingsView: View {
    // 表示言語の管理役を親画面から受け取ります。
    @EnvironmentObject var lm: LanguageManager
    // `localLLM`を画面の状態として保持し、変更時に表示を更新します。
    @State private var localLLM = LocalLLMService.shared
    
    // 画面に表示する部品の並びを返す `body` を定義します。
    var body: some View {
        // 項目を一覧表示します。
        List {
            // MARK: - Ticker Language
            // 関連する項目を一つのまとまりに分けます。
            Section(header: Text(lm.t(.tickerLanguage))) {
                // 選択肢から値を選ぶ部品を作ります。
                Picker(lm.t(.tickerLanguage), selection: Binding(
                    // `get` という引数・項目に続く値を指定します。
                    get: { localLLM.tickerLanguage },
                    // `set` という引数・項目に続く値を指定します。
                    set: { localLLM.setTickerLanguage($0) }
                // 直前に指定した条件や表示内容を使って、続く画面部品を作ります。
                )) {
                    // 文字列を画面に表示します。
                    Text(lm.t(.tickerJP)).tag("日本語")
                    // 文字列を画面に表示します。
                    Text(lm.t(.tickerEN)).tag("English")
                // ))の範囲をここで閉じます。
                }
                // 選択肢を横並びの切替ボタンとして表示します。
                .pickerStyle(.segmented)
            // 開いていた画面部品や処理の範囲を閉じます。
            }
            
            // MARK: - Current Status
            // 関連する項目を一つのまとまりに分けます。
            Section(header: Text(lm.t(.currentStatus))) {
                // 要素を上から下へ並べます。
                VStack(alignment: .leading) {
                    // 文字列を画面に表示します。
                    Text("Status: \(localLLM.loadStatus)")
                        // 文字の大きさや書体を設定します。
                        .font(.caption)
                        // 文字やアイコンの色を設定します。
                        .foregroundStyle(.gray)
                    
                    // AIモデルのダウンロードが始まり、まだ完了していない場合に進捗を表示します。
                    if localLLM.downloadProgress > 0 && localLLM.downloadProgress < 1.0 {
                        // 処理の進行状況を示す表示を作ります。
                        ProgressView(value: localLLM.downloadProgress)
                        // 文字列を画面に表示します。
                        Text("\(Int(localLLM.downloadProgress * 100))%")
                            // 文字の大きさや書体を設定します。
                            .font(.caption)
                    // 条件分岐の範囲をここで閉じます。
                    }
                // 縦並びの表示の範囲をここで閉じます。
                }
            // 開いていた画面部品や処理の範囲を閉じます。
            }
            
            // MARK: - Installed Models
            // 関連する項目を一つのまとまりに分けます。
            Section(header: Text(lm.t(.installedModels))) {
                // `installedModels`を変更できない値として作り、右辺の結果を保存します。
                let installedModels = localLLM.availableModels.filter { localLLM.isInstalled(modelId: $0.id) }
                
                // インストール済みのAIモデルがない場合、空の案内を表示します。
                if installedModels.isEmpty {
                    // 文字列を画面に表示します。
                    Text(lm.t(.noInstalledModels))
                        // 文字やアイコンの色を設定します。
                        .foregroundStyle(.gray)
                        // 文字を斜体で表示します。
                        .italic()
                // 前の条件に当てはまらない場合の処理に進みます。
                } else {
                    // 配列などの各要素について同じ表示を作ります。
                    ForEach(installedModels) { model in
                        // 要素を左から右へ並べます。
                        HStack {
                            // 要素を上から下へ並べます。
                            VStack(alignment: .leading) {
                                // 文字列を画面に表示します。
                                Text(model.name)
                                    // 文字の大きさや書体を設定します。
                                    .font(.headline)
                                // 文字列を画面に表示します。
                                Text(model.repoId)
                                    // 文字の大きさや書体を設定します。
                                    .font(.caption2)
                                    // 文字やアイコンの色を設定します。
                                    .foregroundStyle(.gray)
                            // 縦並びの表示の範囲をここで閉じます。
                            }
                            // 空き領域を使って要素間の距離を広げます。
                            Spacer()
                            
                            // 一覧のモデルが現在選択中のモデルなら、その状態を表示します。
                            if localLLM.currentModelId == model.id {
                                // 要素を左から右へ並べます。
                                HStack {
                                    // 日本語または英語で準備完了と表示されている場合の処理に進みます。
                                    if localLLM.loadStatus.contains("準備完了") || localLLM.loadStatus.contains("Ready") {
                                        // 画像またはシステムアイコンを表示します。
                                        Image(systemName: "checkmark.circle.fill")
                                            // 文字やアイコンの色を設定します。
                                            .foregroundStyle(.green)
                                            // 文字の大きさや書体を設定します。
                                            .font(.title3)
                                            // 表示と非表示を切り替えるときの動きを設定します。
                                            .transition(.scale)
                                    // 前の条件に当てはまらない場合の処理に進みます。
                                    } else {
                                        // 処理の進行状況を示す表示を作ります。
                                        ProgressView()
                                            // 表示の拡大率を設定します。
                                            .scaleEffect(0.8)
                                    // } elseの範囲をここで閉じます。
                                    }
                                    
                                    // 文字列を画面に表示します。
                                    Text(localLLM.currentModelId == model.id ? lm.t(.active) : "")
                                        // 文字の大きさや書体を設定します。
                                        .font(.caption)
                                        // 文字を太字で表示します。
                                        .bold()
                                        // 文字やアイコンの色を設定します。
                                        .foregroundStyle(localLLM.loadStatus.contains("準備完了") ? .green : .secondary)
                                // 横並びの表示の範囲をここで閉じます。
                                }
                            // 前の条件に当てはまらない場合の処理に進みます。
                            } else {
                                // タップで処理を実行するボタンを配置します。
                                Button(lm.t(.select)) {
                                    // 時間のかかる非同期処理を開始します。
                                    Task {
                                        // `localLLM.setModel(model)` が終わるまで待ってから次へ進みます。
                                        await localLLM.setModel(model)
                                    // 非同期処理の範囲をここで閉じます。
                                    }
                                // ボタンの処理の範囲をここで閉じます。
                                }
                                // ボタンの輪郭が見える標準スタイルを使います。
                                .buttonStyle(.bordered)
                            // } elseの範囲をここで閉じます。
                            }
                        // 横並びの表示の範囲をここで閉じます。
                        }
                        // 表示の周囲に余白を設けます。
                        .padding(.vertical, 4)
                        // 横にスワイプしたときの操作を追加します。
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // タップで処理を実行するボタンを配置します。
                            Button(role: .destructive) {
                                // 一覧のモデルが現在選択中のモデルなら、その状態を表示します。
                                if localLLM.currentModelId == model.id {
                                    // 現在選択しているAIモデルの保存データを削除します。
                                    localLLM.deleteModel()
                                // 前の条件に当てはまらない場合の処理に進みます。
                                } else {
                                    // 指定したAIモデルの保存データを削除します。
                                    localLLM.deleteModel(id: model.id)
                                // } elseの範囲をここで閉じます。
                                }
                            // ボタンの処理の範囲をここで閉じます。
                            } label: {
                                // 文字とアイコンを組み合わせた表示を作ります。
                                Label(lm.t(.deleteModel), systemImage: "trash")
                            // } label:の範囲をここで閉じます。
                            }
                        // 開いていた画面部品や処理の範囲を閉じます。
                        }
                    // 繰り返し表示の範囲をここで閉じます。
                    }
                // } elseの範囲をここで閉じます。
                }
            // 開いていた画面部品や処理の範囲を閉じます。
            }
            
            // MARK: - Available (Not Installed)
            // 関連する項目を一つのまとまりに分けます。
            Section(header: Text(lm.t(.availableForDownload))) {
                // `uninstalledModels`を変更できない値として作り、右辺の結果を保存します。
                let uninstalledModels = localLLM.availableModels.filter { !localLLM.isInstalled(modelId: $0.id) }
                
                // 未インストールのAIモデルがない場合、追加候補がないことを示します。
                if uninstalledModels.isEmpty {
                    // 文字列を画面に表示します。
                    Text("All available models are installed")
                        // 文字やアイコンの色を設定します。
                        .foregroundStyle(.gray)
                        // 文字を斜体で表示します。
                        .italic()
                // 前の条件に当てはまらない場合の処理に進みます。
                } else {
                    // 配列などの各要素について同じ表示を作ります。
                    ForEach(uninstalledModels) { model in
                        // 要素を左から右へ並べます。
                        HStack {
                            // 要素を上から下へ並べます。
                            VStack(alignment: .leading) {
                                // 文字列を画面に表示します。
                                Text(model.name)
                                    // 文字の大きさや書体を設定します。
                                    .font(.headline)
                                // 文字列を画面に表示します。
                                Text(model.repoId)
                                    // 文字の大きさや書体を設定します。
                                    .font(.caption2)
                                    // 文字やアイコンの色を設定します。
                                    .foregroundStyle(.gray)
                                    // 表示する文章の行数を制限します。
                                    .lineLimit(1)
                                    // 長すぎる文字列の中央を省略して表示します。
                                    .truncationMode(.middle)
                            // 縦並びの表示の範囲をここで閉じます。
                            }
                            // 空き領域を使って要素間の距離を広げます。
                            Spacer()
                            
                            // タップで処理を実行するボタンを配置します。
                            Button(lm.t(.install)) {
                                // 選んだAIモデルのダウンロードをバックグラウンドで開始します。
                                localLLM.startBackgroundDownload(model: model)
                            // ボタンの処理の範囲をここで閉じます。
                            }
                            // ボタンを強調色で目立たせるスタイルを使います。
                            .buttonStyle(.borderedProminent)
                        // 横並びの表示の範囲をここで閉じます。
                        }
                        // 表示の周囲に余白を設けます。
                        .padding(.vertical, 4)
                    // 繰り返し表示の範囲をここで閉じます。
                    }
                // } elseの範囲をここで閉じます。
                }
            // 開いていた画面部品や処理の範囲を閉じます。
            }
            
            // 関連する項目を一つのまとまりに分けます。
            Section {
                 // 文字列を画面に表示します。
                 Text(lm.t(.uninstallSwipeTip))
                    // 文字の大きさや書体を設定します。
                    .font(.caption)
                    // 文字やアイコンの色を設定します。
                    .foregroundStyle(.gray)
            // Sectionの範囲をここで閉じます。
            }
        // Listの範囲をここで閉じます。
        }
        // 画面上部の見出しを設定します。
        .navigationTitle(lm.t(.aiModelManagement))
    // 画面構成の範囲をここで閉じます。
    }
// 構造体の範囲をここで閉じます。
}
