// JSON、URLSession、filesystemを使う検証用の標準機能を読み込みます。
import Foundation

// AIModelDownloadStoreの公開動作をlocal HTTP fixtureで検証します。
@main
// local fixtureを使う検証プログラムの型を定義します。
struct AIModelDownloadStoreHarness {
    // 非同期検証の入口をMainActorで実行します。
    @MainActor
    // fixture URLと一時保存先を引数に受け取ります。
    static func main() async throws {
        // Python fixtureが起動したHTTP serverのportを読み取ります。
        guard CommandLine.arguments.count == 3, let port = Int(CommandLine.arguments[1]) else { throw HarnessFailure.invalidArguments }
        // 検証用HTTP base URLを作成します。
        guard let hubURL = URL(string: "http://127.0.0.1:\(port)") else { throw HarnessFailure.invalidArguments }
        // テスト専用rootを受け取ります。
        let rootURL = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
        // 各シナリオで共有するURLSessionを準備します。
        let session = URLSession(configuration: .ephemeral)
        // handler登録前にstore.cancel相当とTask cancelが先行する競合を繰り返します。
        for attempt in 0..<8 {
            // 競合ごとに完了状態が独立したdelegateを作ります。
            let earlyCancelDelegate = AIModelDownloadDelegate { _, _ in }
            // handlerが登録されるより前にcancel hookを実行するURLSessionを作ります。
            let earlyCancelSession = URLSession(configuration: .ephemeral, delegate: earlyCancelDelegate, delegateQueue: nil)
            // 通信開始前にcancelするのでfixture内の実在pathは必要ありません。
            guard let earlyCancelURL = URL(string: "http://127.0.0.1:\(port)/early-cancel-\(attempt)") else { throw HarnessFailure.invalidArguments }
            // 検証用GET requestを組み立てます。
            let earlyCancelRequest = URLRequest(url: earlyCancelURL)
            // handler登録前にstore cancelと親Task cancelを確実に起こすTaskを作ります。
            let earlyCancelTask = Task {
                // delegate downloadを実行し、早期cancelをCancellationErrorとして受け取ります。
                try await earlyCancelDelegate.download(session: earlyCancelSession, request: earlyCancelRequest) {
                    // Store.cancel()と同じdelegate cancellation経路をregistration前に実行します。
                    earlyCancelDelegate.cancel()
                    // cancellation handlerがすでにcancel済みTaskを処理する状態にします。
                    withUnsafeCurrentTask { $0?.cancel() }
                // early cancellationの実行hookを閉じます。
                }
            // 早期cancel Taskの定義を閉じます。
            }
            // runner全体の90秒期限内に終了し、continuationがhangしないことを確認します。
            switch await earlyCancelTask.result {
            // 成功で返った場合は早期cancelが失われたので失敗にします。
            case .success:
                // 成功した試行番号を含むassertion failureを返します。
                throw HarnessFailure.expectedFailure("handler登録前のcancelが失われました: \(attempt)")
            // 期待通りthrowした場合はCancellationErrorの型を確認します。
            case .failure(let error):
                // cancel競合が別種類の失敗へ変化していないことを検査します。
                try expect(error is CancellationError, "早期cancel stressが別errorでした: \(error)")
            // 成否switchを閉じます。
            }
            // 各試行のURLSessionを解放し、遅延network callbackを終わらせます。
            earlyCancelSession.finishTasksAndInvalidate()
        // 8回の早期cancel stress loopを閉じます。
        }
        // Storeが未作成rootでも空き容量を読めることを確認します。
        let initialStore = AIModelDownloadStore(rootURL: rootURL.appendingPathComponent("not-created"), hubBaseURL: hubURL)
        // 親volumeの空き容量を取得できる必要があります。
        try expect(initialStore.availableStorageBytes != nil, "未作成rootの空き容量が取得できません")
        // 必要空き容量で64 MiBまたは5%の余裕が共有されることを確認します。
        let storageModel = OnDeviceAIModel(id: "storage-check", name: "Storage Check", backend: .mlx, repoId: "owner/success", revision: String(repeating: "a", count: 40), downloadBytes: 100, quantization: "test", minimumMemoryBytes: 0, runtimeMemoryBytes: 0, isReasoning: false)
        // 小さなfixtureでは最小64 MiBの余裕が加算されます。
        try expect(initialStore.requiredStorageBytes(for: storageModel) == 67_108_964, "requiredStorageBytesの計算が想定と違います")
        // nil・旧モデル・未知IDをAppleモデルへ移行することを検査します。
        for savedID in [nil, "llama", "gemma", "unknown"] as [String?] {
            // 各旧値が既定Appleモデルへ移行することを確認します。
            try expect(AIModelCatalog.restoredSelection(savedID) == AIModelCatalog.defaultID, "旧または未知の選択IDがAppleモデルへ移行しません: \(savedID ?? "nil")")
        // 移行対象の選択IDを一つずつ確認するloopを閉じます。
        }
        // 現行5種類のモデルIDは保存済み選択として維持されることを確認します。
        for model in AIModelCatalog.models {
            // Appleを含む5IDがそのまま復元されることを確認します。
            try expect(AIModelCatalog.restoredSelection(model.id) == model.id, "現行モデルの選択IDが復元されません: \(model.id)")
        // 有効な現行モデルを確認するloopを閉じます。
        }
        // 選択IDを旧モデルへ設定し、ストアが勝手に変更しないことを確認します。
        UserDefaults.standard.set("llama", forKey: "selectedAIModelId")
        // 既知catalog Bonsaiのfixed revisionを検索します。
        guard let catalogBonsai = AIModelCatalog.models.first(where: { $0.id == "bonsai-8b" }), let catalogRevision = catalogBonsai.revision else { throw HarnessFailure.invalidFixture("Bonsai catalog entryがありません") }
        // 初期化時回収用root内にmodel専用directoryを作ります。
        let successModelDirectory = rootURL.appendingPathComponent("success").appendingPathComponent(catalogBonsai.id)
        // partial回収前提のmodel directoryを用意します。
        try FileManager.default.createDirectory(at: successModelDirectory, withIntermediateDirectories: true)
        // catalog fixed revision prefixと有効UUIDを含むstale partial pathを作ります。
        let stalePartial = successModelDirectory.appendingPathComponent(".\(catalogRevision).partial-12345678-1234-1234-1234-123456789ABC", isDirectory: true)
        // stale partial directoryを作成します。
        try FileManager.default.createDirectory(at: stalePartial, withIntermediateDirectories: true)
        // stale dataが消されることを検証するmarker fileを書きます。
        try Data("stale".utf8).write(to: stalePartial.appendingPathComponent("partial.bin"))
        // suffixがUUIDでないfileは誤削除されないことを検証するforeign entryを作ります。
        let malformedStaging = successModelDirectory.appendingPathComponent(".\(catalogRevision).partial-not-a-uuid", isDirectory: true)
        // malformed suffix directoryを作成します。
        try FileManager.default.createDirectory(at: malformedStaging, withIntermediateDirectories: true)
        // suffixが有効UUIDでも未知modelのpartialは消さないことを確認するdirectoryを作ります。
        let foreignModelDirectory = rootURL.appendingPathComponent("success").appendingPathComponent("foreign-model")
        // foreign modelのdirectoryを作成します。
        try FileManager.default.createDirectory(at: foreignModelDirectory, withIntermediateDirectories: true)
        // カタログに存在しないmodelのstagingを作成します。
        try FileManager.default.createDirectory(at: foreignModelDirectory.appendingPathComponent(".\(catalogRevision).partial-12345678-1234-1234-1234-123456789ABC", isDirectory: true), withIntermediateDirectories: true)
        // テストroot内の回収対象を作る前にsuccess Storeを初期化します。
        let successStore = AIModelDownloadStore(rootURL: rootURL.appendingPathComponent("success"), hubBaseURL: hubURL)
        // 起動時に既知modelのUUID付きpartialだけ回収したことを確認します。
        try expect(try FileManager.default.contentsOfDirectory(atPath: successModelDirectory.path) == [malformedStaging.lastPathComponent], "startup partial recoveryの範囲が正しくありません")
        // 未知modelのpartialは残ることを確認します。
        try expect(try FileManager.default.contentsOfDirectory(atPath: foreignModelDirectory.path).count == 1, "未知modelのpartialを誤って削除しました")
        // API値から動的にdownloadBytesを作り、fixtureと同じサイズ契約を使います。
        let successModel = try await makeModel(id: "bonsai-8b", name: "Bonsai 8B", repo: "owner/success", revisionCharacter: "a", hubURL: hubURL, session: session)
        // file delegateの進捗を観測しながら利用者が選んだmodelだけを取得します。
        var successFinished = false
        // MainActor上でdownloadと完了flagを更新します。
        let successTask = Task { @MainActor in
            // download終了時にも監視loopを解放します。
            defer { successFinished = true }
            // 選んだmodelのdownloadを実行します。
            try await successStore.download(successModel)
        // success task closureを閉じます。
        }
        // 不完全な割合の進捗を一度でも画面状態へ反映したか記録します。
        var sawPartialProgress = false
        // download完了までMainActor状態を監視します。
        while !successFinished {
            // 完了前に0と1の間の進捗が来たか確認します。
            if successStore.progress > 0, successStore.progress < 1 { sawPartialProgress = true }
            // delegate callbackがMainActorへ届く時間を与えます。
            try await Task.sleep(nanoseconds: 5_000_000)
        // 成功取得の進捗監視loopを閉じます。
        }
        // successシナリオのdownload結果を再送出します。
        try await successTask.value
        // 少なくとも1度途中progressが観測されたことを確認します。
        try expect(sawPartialProgress, "URLSession delegateの途中進捗を観測できませんでした")
        // ストアがmodel選択を保存領域へ書き換えていないことを確認します。
        try expect(UserDefaults.standard.string(forKey: "selectedAIModelId") == "llama", "ダウンロードがモデル選択を変更しました")
        // 完了状態と物理ファイルからinstalledが導出されることを確認します。
        try expect(successStore.isInstalled(successModel), "正常取得したモデルがinstalled判定されません")
        // 成功で状態版数と進捗が更新されたことを確認します。
        try expect(successStore.stateVersion == 1 && successStore.progress == 1 && successStore.activeModelID == nil, "成功後の観測状態が不正です")
        // 正規化後configの保存内容を開きます。
        let configURL = successStore.directory(for: successModel).appendingPathComponent("config.json")
        // config JSON objectを読み取ります。
        let successConfig = try JSONSerialization.jsonObject(with: Data(contentsOf: configURL)) as? [String: Any] ?? [:]
        // Bonsai runtime向けのmodel_typeが設定されたことを確認します。
        try expect(successConfig["model_type"] as? String == "wealthy_bonsai_qwen3", "Bonsai model_typeの正規化がありません")
        // 正規化後のquantizationと配布元のquantization_configを辞書として読みます。
        let normalizedQuantization = successConfig["quantization"] as? [String: Int] ?? [:]
        // 配布元のquantization設定を数値dictionaryとして読みます。
        let sourceQuantization = successConfig["quantization_config"] as? [String: Int] ?? [:]
        // 配布元の4-bit指定が共通runtime keyにコピーされたことを確認します。
        try expect(normalizedQuantization["bits"] == 4 && normalizedQuantization == sourceQuantization, "quantizationのコピーがありません")
        // Python任意実行につながるconfigキーが取り除かれたことを確認します。
        try expect(successConfig["model_file"] == nil && successConfig["auto_map"] == nil && successConfig["trust_remote_code"] == nil && successConfig["python_remote_code"] == nil, "Python remote-code configが残っています")
        // 完成マーカーの元データを読み取り、破損判定テスト後に戻せるようにします。
        let markerURL = successStore.directory(for: successModel).appendingPathComponent(".wealthy-install.json")
        // 完成マーカーJSONを保存します。
        let markerData = try Data(contentsOf: markerURL)
        // 一つ必須ファイルを欠落させたマーカーを構築します。
        var markerObject = try JSONSerialization.jsonObject(with: markerData) as? [String: Any] ?? [:]
        // markerのfileSizes dictionaryを取り出します。
        var markerSizes = markerObject["fileSizes"] as? [String: Int64] ?? [:]
        // tokenizer.jsonをマーカーから除去します。
        markerSizes.removeValue(forKey: "tokenizer.json")
        // 不完全なサイズ一覧をmarkerへ保存します。
        markerObject["fileSizes"] = markerSizes
        // 不完全なmarkerでinstalled判定がfalseになることを検証します。
        try JSONSerialization.data(withJSONObject: markerObject, options: [.sortedKeys]).write(to: markerURL, options: .atomic)
        // 必須ファイルを省いた完成マーカーを拒否します。
        try expect(!successStore.isInstalled(successModel), "必須tokenizerを欠くmarkerをinstalledと判断しました")
        // 正常マーカーに戻して削除経路を検証します。
        try markerData.write(to: markerURL, options: .atomic)
        // 完成したモデルだけを物理削除できることを確認します。
        try successStore.delete(successModel)
        // delete成功後は版数が増え、物理ディレクトリがなくなることを確認します。
        try expect(successStore.stateVersion == 2 && !successStore.isInstalled(successModel), "成功した削除の状態更新が不正です")
        // AppleのOS管理モデルをアプリストアから削除できないことを確認します。
        let appleModel = AIModelCatalog.models[0]
        // Appleモデルを削除しようとします。
        do {
            // Appleモデル削除は明示エラーになる必要があります。
            try successStore.delete(appleModel)
            // エラーにならなかった場合は検証失敗として止めます。
            throw HarnessFailure.expectedFailure("Appleモデルの削除が拒否されません")
        // Appleモデル削除の失敗を確認します。
        } catch AIModelDownloadError.appleManagedModel {
            // 想定した拒否エラーを受け取ったことを示します。
        // Appleモデル削除のdo-catchを閉じます。
        }
        // checksum不一致で完成版が作られない経路を確認します。
        let hashStore = AIModelDownloadStore(rootURL: rootURL.appendingPathComponent("hash"), hubBaseURL: hubURL)
        // わざと異なるLFS SHAをfixtureが返すモデルを作ります。
        let hashModel = try await makeModel(id: "hash-mismatch", name: "Hash Fixture", repo: "owner/hash", revisionCharacter: "b", hubURL: hubURL, session: session)
        // checksum不一致を受け取ります。
        let hashError = await expectDownloadFailure(store: hashStore, model: hashModel)
        // 英語の設定中は既存lastErrorにも英語文言を保存します。
        try expect(hashError.contains("SHA-256 verification failed"), "英語表示のchecksumエラーが日英設定に追随しません")
        // ハッシュ失敗時に完全版を作らないことを確認します。
        try expect(!hashStore.isInstalled(hashModel) && hashStore.stateVersion == 0, "checksum失敗をinstalled扱いしました")
        // HTTPエラー応答でも完成版を作らず、一時ファイルを残さないことを確認します。
        let httpStore = AIModelDownloadStore(rootURL: rootURL.appendingPathComponent("http"), hubBaseURL: hubURL)
        // safetensorsのHTTP応答を503にするモデルを作ります。
        let httpModel = try await makeModel(id: "http-failure", name: "HTTP Fixture", repo: "owner/http", revisionCharacter: "c", hubURL: hubURL, session: session)
        // HTTP failureを取得します。
        let httpError = await expectDownloadFailure(store: httpStore, model: httpModel)
        // エラーコードが保たれていることを確認します。
        try expect(httpError.contains("503"), "HTTP 503がエラーに含まれません")
        // HTTP失敗時にinstalledでないことを確認します。
        try expect(!httpStore.isInstalled(httpModel), "HTTP失敗をinstalled扱いしました")
        // HTTP metadataのsizeと実ファイルsizeが異なる経路を確認します。
        let sizeStore = AIModelDownloadStore(rootURL: rootURL.appendingPathComponent("size"), hubBaseURL: hubURL)
        // safetensorsの宣言サイズだけを1 byteずらすモデルを作ります。
        let sizeModel = try await makeModel(id: "size-mismatch", name: "Size Fixture", repo: "owner/size", revisionCharacter: "d", hubURL: hubURL, session: session)
        // 実容量検査を通過できない時の説明を得ます。
        let sizeError = await expectDownloadFailure(store: sizeStore, model: sizeModel)
        // size mismatchも正しいエラーで完成版を作らないことを確認します。
        try expect(sizeError.contains("invalid file metadata") && !sizeStore.isInstalled(sizeModel), "サイズ不一致を正しいエラーまたは未インストールへ反映できません")
        // cancellation中のpartialを捨て、同じモデルの即時restartを分離できるか調べます。
        let cancelStore = AIModelDownloadStore(rootURL: rootURL.appendingPathComponent("cancel"), hubBaseURL: hubURL)
        // 大きいがfixtureとして小さいsynthetic weightモデルを作ります。
        let cancelModel = try await makeModel(id: "cancel-restart", name: "Cancel Fixture", repo: "owner/cancel", revisionCharacter: "e", hubURL: hubURL, session: session)
        // Storeに到達する前からcancel済みのTaskを作り、active枠を先取りしないことを確認します。
        let cancelledBeforeStart = Task { @MainActor in
            // 現在のTask自体へcancelを設定します。
            withUnsafeCurrentTask { $0?.cancel() }
            // 入口のcheckCancellationでStoreへ入らずthrowさせます。
            try await cancelStore.download(cancelModel)
        // 事前cancel Task closureを閉じます。
        }
        // 事前cancel TaskがCancellationErrorで終わるか確認します。
        switch await cancelledBeforeStart.result {
        // 事前cancelを無視した成功は検証失敗です。
        case .success:
            // 予期しないdownload開始をHarnessFailureにします。
            throw HarnessFailure.expectedFailure("開始前にcancelされたTaskがdownloadを開始しました")
        // expected cancellation errorは問題ありません。
        case .failure(let error):
            // 失敗理由がCancellationErrorであることを確認します。
            try expect(error is CancellationError, "開始前cancelがCancellationError以外でした: \(error)")
        // 事前cancel結果のswitchを閉じます。
        }
        // 事前cancelがstoreのactive枠を取得しなかったことを確認します。
        try expect(cancelStore.activeModelID == nil, "開始前cancelされたTaskがactive枠を取りました")
        // 1回目のweight応答をslow streamにします。
        let firstDownload = Task { try await cancelStore.download(cancelModel) }
        // Python serverがweight bytesを送り始めるまで状態endpointをpollします。
        try await waitForSlowTransfer(hubURL: hubURL, session: session)
        // 少なくとも一つ進捗通知が送られる時間を与えます。
        try await Task.sleep(nanoseconds: 100_000_000)
        // 呼び出し側TaskをcancelしてURLSessionを明示停止します。
        firstDownload.cancel()
        // Storeの同期状態とdelegate tempも停止します。
        cancelStore.cancel()
        // cancel直後にpartialのモデルがinstalledでないことを確認します。
        try expect(!cancelStore.isInstalled(cancelModel), "cancel直後の部分モデルをinstalled扱いしました")
        // 前operationが戻る前に即時restartし、古いcallback/session競合を検証します。
        let restartedDownload = Task { try await cancelStore.download(cancelModel) }
        // restartが完成するまで待ちます。
        try await restartedDownload.value
        // 1回目TaskがCancellationErrorで終わることを確認します。
        switch await firstDownload.result {
        // 1回目が成功したらcancelが反映されていないので失敗にします。
        case .success:
            // 予期しない成功をHarnessFailureへ変換します。
            throw HarnessFailure.expectedFailure("cancelした1回目のdownloadが成功しました")
        // 1回目が失敗した結果を受け取り、restart側の状態を続けて確認します。
        case .failure(let error):
            // 失敗理由がcancelに対応する型か確認します。
            try expect(error is CancellationError, "cancelした1回目がCancellationError以外で失敗しました: \(error)")
        // task resultのswitchを閉じます。
        }
        // 即時restart完了後はモデルがinstalledである必要があります。
        try expect(cancelStore.isInstalled(cancelModel), "cancel直後のrestartがinstalledへ到達しません")
        // 古いpartial stagingが残らないことを確認します。
        let modelDirectory = rootURL.appendingPathComponent("cancel").appendingPathComponent(cancelModel.id)
        // model専用directoryの残留partialを列挙します。
        let remainingEntries = try FileManager.default.contentsOfDirectory(atPath: modelDirectory.path)
        // 完了revision以外のpartial領域が存在しないことを確認します。
        try expect(remainingEntries == [String(repeating: "e", count: 40)], "cancel/restart後にpartial directoryが残っています")
        // English設定をテスト後に日本語へ戻します。
        UserDefaults.standard.set("日本語", forKey: "selectedLanguage")
        // 検証が完了したことをstdoutに表示します。
        print("AIModelDownloadStore fixture checks passed")
    // mainを閉じます。
    }

    // API fixtureから宣言byte数を取得してOnDeviceAIModelを作ります。
    @MainActor
    // 指定repositoryとrevisionを含むモデルを返します。
    private static func makeModel(id: String, name: String, repo: String, revisionCharacter: Character, hubURL: URL, session: URLSession) async throws -> OnDeviceAIModel {
        // Fixtureのsize endpoint URLを絶対URLから構築します。
        guard let sizeURL = URL(string: "\(hubURL.absoluteString)/__size/\(repo)") else { throw HarnessFailure.invalidArguments }
        // fixtureが返すモデルファイル合計サイズJSONを受け取ります。
        let (sizeData, _) = try await session.data(from: sizeURL)
        // JSONからsizeフィールドを読み取ります。
        guard let sizeObject = try JSONSerialization.jsonObject(with: sizeData) as? [String: Int], let size = sizeObject["size"] else { throw HarnessFailure.invalidFixture("サイズfixtureが不正です: \(repo)") }
        // 40文字固定SHAでOnDeviceAIModelを構成します。
        return OnDeviceAIModel(id: id, name: name, backend: .mlx, repoId: repo, revision: String(repeating: revisionCharacter, count: 40), downloadBytes: Int64(size), quantization: "fixture", minimumMemoryBytes: 0, runtimeMemoryBytes: 0, isReasoning: false)
    // makeModelを閉じます。
    }

    // download失敗がlastErrorにも反映されたことを確認して文言を返します。
    @MainActor
    // 想定する複数のエラーケースでStoreを呼び出します。
    private static func expectDownloadFailure(store: AIModelDownloadStore, model: OnDeviceAIModel) async -> String {
        // アプリ表示言語を英語に設定します。
        UserDefaults.standard.set("English", forKey: "selectedLanguage")
        // async downloadがthrowすることを確認します。
        do {
            // 指定されたfixture modelを取得し、想定外の成功を失敗にします。
            try await store.download(model)
            // エラーにならなかったケースを返します。
            return "unexpected success"
        // downloadのLocalizedErrorを検査します。
        } catch {
            // 利用者向け英語文言とstore状態の整合を記録します。
            let message = error.localizedDescription
            // Storeが同じ言語のerror文字列を保持することを確認します。
            if store.lastError != message { return "lastError mismatch: \(store.lastError ?? "nil")" }
            // エラー文言を呼び出し側へ返します。
            return message
        // downloadのエラー検査を閉じます。
        }
    // expectDownloadFailureを閉じます。
    }

    // slow transferが実際に開始されたことをfixtureの状態APIで確認します。
    @MainActor
    // weight downloadが始まるまで最大10秒待ちます。
    private static func waitForSlowTransfer(hubURL: URL, session: URLSession) async throws {
        // poll開始時刻を記録して上限時間を設けます。
        let start = Date()
        // fixtureがslow responseのbyteを書き始めるまで待ちます。
        while Date().timeIntervalSince(start) < 10 {
            // fixtureの稼働状態endpointを絶対URLから作ります。
            guard let stateURL = URL(string: "\(hubURL.absoluteString)/__state") else { throw HarnessFailure.invalidArguments }
            // JSON状態responseを読み込みます。
            let (stateData, _) = try await session.data(from: stateURL)
            // JSONからslow write量を読み取ります。
            let state = try JSONSerialization.jsonObject(with: stateData) as? [String: Int] ?? [:]
            // 最初のweight responseがbyteを出した時点で完了します。
            if (state["cancel_bytes_written"] ?? 0) > 0 { return }
            // server側の初回responseを待ちながらCPU pollingを避けます。
            try await Task.sleep(nanoseconds: 10_000_000)
        // 時間制限付きpoll loopを閉じます。
        }
        // slow responseが始まらない場合は検証を明示的に失敗させます。
        throw HarnessFailure.invalidFixture("slow weight responseが開始しません")
    // waitForSlowTransferを閉じます。
    }

    // Bool条件がfalseなら内容を表示して検証を止めます。
    private static func expect(_ condition: Bool, _ message: String) throws {
        // 失敗条件をthrowに変換します。
        if !condition { throw HarnessFailure.expectedFailure(message) }
    // expectを閉じます。
    }
// Harness型を閉じます。
}

// 検証失敗と起動失敗を型で区別します。
enum HarnessFailure: Error, CustomStringConvertible {
    // fixture引数が不足している状態を表します。
    case invalidArguments
    // 検証すべき結果と違った状態を表します(String)。
    case expectedFailure(String)
    // fixture responseや進捗が不正な状態を表します(String)。
    case invalidFixture(String)

    // 失敗内容をプロセスstderrへ表示できる文字列で返します。
    var description: String {
        // ケースごとの具体的な説明を返します。
        switch self {
        // 起動引数不足を示します。
        case .invalidArguments: return "Harness arguments are invalid."
        // 検証失敗の詳細を返します。
        case .expectedFailure(let message): return message
        // HTTP fixtureの不具合を返します。
        case .invalidFixture(let message): return message
        // descriptionのswitchを閉じます。
        }
    // descriptionを閉じます。
    }
// HarnessFailureを閉じます。
}
