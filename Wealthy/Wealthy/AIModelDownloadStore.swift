// ファイル操作、通信、JSON処理などFoundationの機能を読み込みます。
import Foundation
// 実ファイルからSHA-256を計算する暗号機能を読み込みます。
import CryptoKit
// SwiftUIのObservationと連携する状態監視機能を読み込みます。
import Observation

// モデル取得で発生する失敗を呼び出し元へ分かりやすく伝える型を定義します。
enum AIModelDownloadError: LocalizedError {
    // Apple管理モデルはアプリから取得や削除ができないことを表します。
    case appleManagedModel
    // モデルまたはrevisionの識別子が安全な形式でないことを表します。
    case invalidModelIdentity
    // 公開取得に必要なrepoIdがモデルに設定されていないことを表します。
    case missingRepository
    // repoIdがowner/name形式でないことを表します。
    case invalidRepository
    // revisionが固定コミットSHAではないことを表します。
    case invalidRevision
    // 同じストアで別モデルの取得が進行中であることを表します。
    case downloadAlreadyActive
    // 公開Hubの応答がHTTP成功ではなかったことを表します(Int)。
    case httpFailure(Int)
    // Hubが返したモデルの一覧を解釈できないことを表します。
    case invalidMetadata
    // 固定revisionの許可対象合計がカタログの公開値と異なることを表します(Int64, Int64)。
    case downloadSizeMismatch(expected: Int64, actual: Int64)
    // 許可した形式のファイルが1つも取得対象に見つからないことを表します。
    case noDownloadableFiles
    // メタデータで報告された容量に対して空き容量が不足していることを表します(Int64, Int64)。
    case insufficientStorage(required: Int64, available: Int64)
    // 推論に必要な設定・トークナイザー・重みが揃わなかったことを表します(String).
    case missingRequiredFiles(String)
    // ダウンロード先がアプリ専用領域の外に解決されたことを表します。
    case unsafeFilePath
    // 配布元のLFSハッシュと取得したファイル内容が一致しないことを表します(String)。
    case checksumMismatch(String)
    // 保存済みの完成マーカーがファイルの実態と一致しないことを表します.
    case invalidInstalledModel

    // 保存済みのアプリ言語に合わせて日本語または英語の説明を返します。
    var errorDescription: String? {
        // 日本語が明示選択されていない場合は英語を既定として扱います。
        let isEnglish = UserDefaults.standard.string(forKey: "selectedLanguage") != "日本語"
        // 各失敗理由を日英の利用者向け説明へ変換します。
        switch self {
        // Apple管理モデルへの非対応を日英で知らせます。
        case .appleManagedModel: return isEnglish ? "Apple-managed models cannot be downloaded or deleted by the app." : "Apple管理モデルはアプリから取得・削除できません。"
        // 安全なモデル識別子が必要だと日英で知らせます。
        case .invalidModelIdentity: return isEnglish ? "The model ID is not a safe path component." : "モデルIDが安全な形式ではありません。"
        // 公開リポジトリの指定漏れを日英で知らせます。
        case .missingRepository: return isEnglish ? "The public model repository ID is missing." : "モデルの公開リポジトリIDがありません。"
        // repoIdが許可する形式でないことを日英で知らせます。
        case .invalidRepository: return isEnglish ? "The repository ID must use owner/name format." : "モデルの公開リポジトリIDがowner/name形式ではありません。"
        // 固定コミットSHAを使う必要があると日英で知らせます。
        case .invalidRevision: return isEnglish ? "The revision must be a fixed 40-character commit SHA." : "revisionには40桁の固定コミットSHAが必要です。"
        // 同時取得が拒否されたことを日英で知らせます。
        case .downloadAlreadyActive: return isEnglish ? "Another model operation is already in progress." : "別のモデル操作が進行中です。"
        // HTTP応答コードを日英で利用者向けに示します。
        case .httpFailure(let code): return isEnglish ? "The model host returned HTTP error \(code)." : "モデル配布元からHTTPエラー（\(code)）が返されました。"
        // APIメタデータ形式の問題を日英で知らせます。
        case .invalidMetadata: return isEnglish ? "The model host returned invalid file metadata." : "モデル配布元のファイル情報を読み取れませんでした。"
        // カタログと固定revisionの容量差を日英で表示します。
        case .downloadSizeMismatch(let expected, let actual): return isEnglish ? "The pinned revision size differs from the catalog (catalog \(expected) bytes, API \(actual) bytes)." : "固定revisionの取得容量がカタログと一致しません（カタログ \(expected) bytes、API \(actual) bytes）。"
        // 取得対象が空であることを日英で知らせます。
        case .noDownloadableFiles: return isEnglish ? "No files with an allowed format were found." : "許可された形式のモデルファイルが見つかりません。"
        // 必要容量と実際の空き容量を日英で表示します。
        case .insufficientStorage(let required, let available): return isEnglish ? "Insufficient storage (required \(required) bytes, available \(available) bytes)." : "空き容量が不足しています（必要 \(required) bytes、空き \(available) bytes）。"
        // 推論に必要なファイル名を日英で表示します。
        case .missingRequiredFiles(let names): return isEnglish ? "Required model files are missing: \(names)" : "推論に必要なファイルがありません: \(names)"
        // 不正な相対パスを日英で拒否したことを知らせます。
        case .unsafeFilePath: return isEnglish ? "The repository contains an unsafe file path." : "配布元に安全でないファイルパスが含まれています。"
        // チェックサムの対象ファイルを日英で表示します。
        case .checksumMismatch(let name): return isEnglish ? "SHA-256 verification failed for \(name)." : "\(name) のSHA-256検証に失敗しました。"
        // 完成マーカーと実ファイルの不一致を日英で知らせます。
        case .invalidInstalledModel: return isEnglish ? "The installed model is incomplete or corrupted." : "保存済みモデルのファイルが不完全または破損しています。"
        // エラー型のswitchを閉じます。
        }
    // errorDescriptionの計算プロパティを閉じます。
    }
// エラー型の定義を閉じます。
}

// Hub API応答で必要なモデルファイル情報を保持します。
private struct AIModelRemoteFile {
    // リポジトリ内の相対ファイル名を保持します。
    let name: String
    // APIが報告したファイル容量を保持します。
    let size: Int64
    // LFSがSHA-256を報告している場合だけ値を保持します。
    let sha256: String?
// リモートファイル情報の定義を閉じます。
}

// 完成マーカーへ保存するモデル識別子と実ファイル容量を保持します。
private struct AIModelInstallMarker: Codable {
    // 完成したモデルのカタログIDを保持します。
    let id: String
    // 完成したモデルの固定revisionを保持します。
    let revision: String
    // 正規化後の実ファイル容量を相対パスごとに記録します。
    let fileSizes: [String: Int64]
// 完成マーカー型の定義を閉じます。
}

// ダウンロードの進捗コールバックを安全に受け渡すURLSessionデリゲートを定義します。
final class AIModelDownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    // 書き込みbyte数を受け取るコールバックを保持します。
    private let onProgress: @Sendable (Int64, Int64) -> Void
    // download delegateが返す一時ファイルURLへの排他アクセスを行います。
    private let locationLock = NSLock()
    // callback内で確保した一時ファイルURLを保持します。
    private var savedLocationStorage: URL?
    // cancel後に遅れて来たcallbackがtempファイルを残さないための状態を保持します。
    private var isCancelled = false
    // downloadTaskのasync結果を待つcontinuationをlock付きで保持します。
    private var completion: CheckedContinuation<(URL, URLResponse), Error>?
    // completion登録前にdelegateが終了した結果を一時保存します。
    private var terminalResult: Result<(URL, URLResponse), Error>?
    // completionが一度だけ完了したことをlock付きで管理します。
    private var isFinished = false
    // callback内で発生した一時ファイル移動失敗をcompletionへ伝えます。
    private var completionError: Error?

    // 一時ファイルURLをlockで保護して読み出します。
    var savedLocation: URL? {
        // 同時アクセスが重ならないようlockを取ります。
        locationLock.lock()
        // return時にもlockを解除するdeferを設定します。
        defer { locationLock.unlock() }
        // 保存済みlocationを返します。
        return savedLocationStorage
    // savedLocationの計算プロパティを閉じます。
    }

    // 進捗を受け取るクロージャを保存してデリゲートを作成します。
    init(onProgress: @escaping @Sendable (Int64, Int64) -> Void) {
        // 後続イベントで使うコールバックを設定します。
        self.onProgress = onProgress
        // NSObjectの初期化を実行します。
        super.init()
    // 初期化処理を閉じます。
    }

    // DownloadTaskを開始し、完了callbackをasync resultとして返します。
    func download(session: URLSession, request: URLRequest, beforeCancellationHandler: (@Sendable () -> Void)? = nil) async throws -> (URL, URLResponse) {
        // delegate callbackを受け取るdownload taskを作成します。
        let task = session.downloadTask(with: request)
        // 検証時はhandler登録前のcancel競合を決定的に再現します。
        beforeCancellationHandler?()
        // 親Taskがcancelされた場合もtransferを停止してcontinuationを解放します。
        return try await withTaskCancellationHandler {
            // didComplete callbackから値を返すcontinuationを登録します。
            try await withCheckedThrowingContinuation { continuation in
                // callbackと登録処理をlockで直列化します。
                locationLock.lock()
                // 登録より先にcancelまたはcallbackが終わった時の結果を取り出します。
                let pendingResult = terminalResult
                // 取り出した結果を共有領域から消し、二度渡さないようにします。
                terminalResult = nil
                // 先行して確定した結果があればcontinuationへ即時返します。
                if let pendingResult {
                    // callback結果を共有領域から取り出した後でlockを解除します。
                    locationLock.unlock()
                    // 成功または失敗をchecked continuationへ一度だけ渡します。
                    continuation.resume(with: pendingResult)
                // cancelが結果を確定済みなら保存値の有無にかかわらず失敗させます。
                } else if isFinished {
                    // 終了状態の確認を終えてからlockを解除します。
                    locationLock.unlock()
                    // continuation登録前に完了したcancelを即時に返します。
                    continuation.resume(throwing: CancellationError())
                // まだ完了していなければcallback用にcontinuationを保管します。
                } else {
                    // callback完了時に一度だけresumeするcontinuationを保存します。
                    completion = continuation
                    // continuation登録を終えてlockを解除します。
                    locationLock.unlock()
                // pending resultの分岐を閉じます。
                }
                // ファイルを直接diskへdownloadします。
                task.resume()
            // checked continuationの登録closureを閉じます。
            }
        // cancellation handlerのoperationを閉じます。
        } onCancel: {
            // cancellation状態をcallbackより先に確定してcontinuationを必ず解放します。
            self.cancel()
            // 呼び出しTaskのcancelをURLSessionDownloadTaskへ伝えます。
            task.cancel()
        // cancellation handlerを閉じます。
        }
    // download async methodを閉じます。
    }

    // URLSessionがファイル書き込み量を通知した時に進捗を中継します。
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // 現在ファイルの取得済み量と予定量を呼び出し元へ渡します。
        onProgress(totalBytesWritten, totalBytesExpectedToWrite)
    // 進捗通知メソッドを閉じます。
    }

    // URLSessionが消去する前に一時downloadファイルを別の一時URLへ移します。
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // ダウンロード専用tmp内に衝突しない一時ファイル名を作ります。
        let savedLocation = FileManager.default.temporaryDirectory.appendingPathComponent("wealthy-download-\(UUID().uuidString)")
        // cancelとの競合を避けるためURL保存をlockで直列化します。
        locationLock.lock()
        // 保存処理中の全経路でlockを解除します。
        defer { locationLock.unlock() }
        // cancel後ならURLSession自身にcallbackのtempファイルを片付けさせます。
        guard !isCancelled else { return }
        // callback終了で消えるlocationを一時保管先へ移動します。
        do {
            // ファイル本体はメモリへ読み込まずfilesystem上で移動します。
            try FileManager.default.moveItem(at: location, to: savedLocation)
            // URLSession完了後にawait側が参照できるようlocationを記録します。
            savedLocationStorage = savedLocation
        // 一時保管先へ移動できない失敗はsavedLocationを空のままにします。
        } catch {
            // 失敗したlocationを成功値として扱わないようにします。
            savedLocationStorage = nil
            // completionがエラーを返せるように移動失敗を保存します。
            completionError = error
        // 一時ファイル移動の処理を閉じます。
        }
    // download完了callbackを閉じます。
    }

    // URLSessionがdownloadTaskの成否を確定した時にcontinuationを一度だけ再開します。
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // callback結果と一時URLを同時に取り出すためlockを取ります。
        locationLock.lock()
        // cancelや先行callbackで終了済みなら結果を二重確定しません。
        guard !isFinished else {
            // 重複delegate callbackを無視する前にlockを解除します。
            locationLock.unlock()
            // 二度目の完了callbackでは何もしません。
            return
        // 完了済み状態のguardを閉じます。
        }
        // 待機中continuationをlocalへ移します。
        let savedCompletion = completion
        // 二重resumeを防ぐため共有continuationを解除します。
        completion = nil
        // response URLをlocalへ移します。
        let savedLocation = savedLocationStorage
        // callback側の移動失敗をlocalへ移します。
        let savedError = completionError
        // cancel状態も同じlock内でsnapshotします。
        let wasCancelled = isCancelled
        // completionを一度だけ消費可能な終了済み状態へ変更します。
        isFinished = true
        // continuationが登録されていない場合に後から受け渡す値を作ります。
        let result: Result<(URL, URLResponse), Error>
        // cancellation後にcallbackが完了した場合はCancellationErrorを返します。
        if wasCancelled {
            // cancelを通信callback結果より優先します。
            result = .failure(CancellationError())
        // taskが通信エラーで失敗した場合を処理します。
        } else if let error {
            // 通信failureを保持します。
            result = .failure(error)
        // tempファイル移動が失敗した場合を処理します。
        } else if let savedError {
            // filesystem failureを保持します。
            result = .failure(savedError)
        // 完了fileとresponseが揃った正常終了を処理します。
        } else if let savedLocation, let response = task.response {
            // temp URLとHTTP responseを正常結果として保持します。
            result = .success((savedLocation, response))
        // delegate状態が揃わない異常終了を処理します。
        } else {
            // 結果が不完全な時はmetadata errorを保持します。
            result = .failure(AIModelDownloadError.invalidMetadata)
        // completion結果の判定switchを閉じます。
        }
        // continuationがすでにあればcallback側から直接再開します。
        if let savedCompletion {
            // completionを取り出した後で共有状態のlockを解除します。
            locationLock.unlock()
            // 成功または失敗を一度だけasync callerへ渡します。
            savedCompletion.resume(with: result)
        // 登録がまだならdownload()側が後から受け取れるようにします。
        } else {
            // callbackの結果をcontinuation登録時まで保存します。
            terminalResult = result
            // callback結果とfinished状態を同じlock transactionで公開します。
            locationLock.unlock()
        // continuation有無の分岐を閉じます。
        }
    // download完了callbackを閉じます。
    }

    // storeがキャンセルまたはHTTP検査を終えた時に一時ファイルを消します。
    func discardTemporaryFile(cancelled: Bool = false) {
        // cancel時はcontinuationも必ず完了させる専用経路を使います。
        if cancelled {
            // store.cancel()から待機中のasync処理を即時解除します。
            cancel()
        // cancel処理と通常のtemp削除を分けます。
        } else {
        // URL参照を取り出してからファイル削除するためlockを取得します。
        locationLock.lock()
        // 保存済みURLをローカルへ移し、同じURLを二度消さないようにします。
        let location = savedLocationStorage
        // 一時URLを共有状態から外します。
        savedLocationStorage = nil
        // lockを解放してからfilesystem操作を行います。
        locationLock.unlock()
        // 一時ファイルが残っていた時だけ削除します。
        if let location { try? FileManager.default.removeItem(at: location) }
        // 通常削除の分岐を閉じます。
        }
    // discardTemporaryFileを閉じます。
    }

    // Taskまたはstore.cancel()のどちらからでも一度だけcancel結果を確定します。
    func cancel() {
        // cancellationとdelegate完了の状態変更をlockで直列化します。
        locationLock.lock()
        // 遅延callbackに一時ファイルを移させない状態を記録します。
        isCancelled = true
        // すでに保存した一時ファイルを削除用に取り出します。
        let savedLocation = savedLocationStorage
        // 同じ一時ファイルを複数経路から削除しないよう共有値を消します。
        savedLocationStorage = nil
        // すでに結果確定済みなら二重resumeをせずlockを外します。
        guard !isFinished else {
            // 終了済み判定を終えてからlockを解除します。
            locationLock.unlock()
            // 取り出した一時ファイルがあればdiskから消します。
            if let savedLocation { try? FileManager.default.removeItem(at: savedLocation) }
            // 二重完了を避けてcancel処理を終えます。
            return
        // 未完了状態だけcancel結果を確定するguardを閉じます。
        }
        // cancelを一度だけ確定した状態にします。
        isFinished = true
        // すでに登録されたcompletionを取り出します。
        let savedCompletion = completion
        // 後続callbackによる二重resumeを防ぐため共有値を消します。
        completion = nil
        // completion登録前なら後から受け取れるcancel結果を保管します。
        if savedCompletion == nil { terminalResult = .failure(CancellationError()) }
        // 共有状態の更新を終えてlockを解除します。
        locationLock.unlock()
        // cancel時に保管済み一時ファイルがあれば削除します。
        if let savedLocation { try? FileManager.default.removeItem(at: savedLocation) }
        // 待機中のcontinuationがあれば即時にCancellationErrorを返します。
        savedCompletion?.resume(throwing: CancellationError())
    // cancelを閉じます。
    }
// URLSessionデリゲート型の定義を閉じます。
}

// ローカルに保存するダウンロードモデルを専用領域で管理します。
@MainActor
// 状態変化をSwiftUIなどから観測できるクラスを定義します。
@Observable
// URLSessionの転送を進捗表示、検証、原子的な公開とともに管理します。
final class AIModelDownloadStore {
    // 現在取得中のモデルIDを画面へ公開します。
    var activeModelID: String?
    // 現在モデル全体の取得率を0から1の範囲で公開します。
    var progress: Double = 0
    // 最後の失敗を利用者向け文字列で公開します。
    var lastError: String?
    // インストール状態が成功裏に変わるたび増やす版番号を公開します。
    var stateVersion: Int = 0
    // 現在の取得を識別し、遅れて届く進捗通知を無効化するIDを保持します。
    @ObservationIgnored private var activeOperationID: UUID?
    // 現在のファイル転送に使うsessionを保持し、cancelから確実に止められるようにします。
    @ObservationIgnored private var activeSession: URLSession?
    // sessionの持ち主を記録し、古いoperationが新しい転送を止めないようにします。
    @ObservationIgnored private var activeSessionOperationID: UUID?
    // download callbackの一時ファイルをキャンセル時にも破棄できるよう保持します。
    @ObservationIgnored private var activeDownloadDelegate: AIModelDownloadDelegate?
    // テスト時に実HubとApplication Supportへ触れずに検証する差し替え先を保持します。
    @ObservationIgnored private let injectedRootURL: URL?
    // 通信先の差し替えを許し、通常時は公開Hub URLを使います。
    @ObservationIgnored private let hubBaseURL: URL?
    // ファイルシステム操作に使う管理オブジェクトを保持します。
    @ObservationIgnored private let fileManager = FileManager.default
    // 完成マーカーの名前をモデル専用ディレクトリ内に固定します。
    @ObservationIgnored private let markerName = ".wealthy-install.json"
    // SHA計算で読み込む上限を1 MiBに固定します。
    @ObservationIgnored private let hashChunkSize = 1_048_576

    // 保存先とHub URLを必要に応じて差し替えられる初期化処理を定義します。
    init(rootURL: URL? = nil, hubBaseURL: URL? = nil) {
        // テスト時の指定保存先を絶対パスに正規化して保持します。
        self.injectedRootURL = rootURL?.standardizedFileURL
        // 呼び出し側のlocal fixtureを優先し、未指定なら標準Hub URLを組み立てます。
        if let hubBaseURL {
            // 明示されたHub URLを保持します。
            self.hubBaseURL = hubBaseURL
        // URL未指定時にproductionの公開Hubを準備する分岐です。
        } else {
            // HTTPS URLをURLComponentsで構築します。
            var components = URLComponents()
            // 公開HubへTLS接続するschemeを設定します。
            components.scheme = "https"
            // 公開Hubのホスト名を設定します。
            components.host = "huggingface.co"
            // 構築に成功した場合だけURLを保持し、失敗は通信時に明示します。
            self.hubBaseURL = components.url
        // URL未指定時の分岐を閉じます。
        }
        // 起動時に既知モデルのUUID付きpartial stagingを回収して空き容量を戻します。
        do {
            // このStore専用のroot内にあるカタログ既知の中断データを検査します。
            try removeKnownAbandonedStagingDirectories()
        // 回収できない場合は隠さずlastErrorへ記録します。
        } catch {
            // 利用者が状況を確認できるよう初期化時の失敗内容を保存します。
            self.lastError = error.localizedDescription
        // 初期回収のdo-catchを閉じます。
        }
    // 初期化処理を閉じます。
    }

    // アプリ専用領域に今ある空き容量をbyte単位で返します。
    var availableStorageBytes: Int64? {
        // 保存rootがまだ無い場合も既存の親directoryからvolume容量を調べます。
        var volumeURL = modelRoot
        // rootが作られる前なら親へ順にたどります。
        while !fileManager.fileExists(atPath: volumeURL.path), volumeURL.path != volumeURL.deletingLastPathComponent().path {
            // ひとつ上の既存候補へ移動します。
            volumeURL = volumeURL.deletingLastPathComponent()
        // volume候補の探索loopを閉じます。
        }
        // 既存volumeの空き容量属性をNSNumber経由で取得します。
        guard let value = try? fileManager.attributesOfFileSystem(forPath: volumeURL.path)[.systemFreeSize] as? NSNumber else { return nil }
        // byte数をInt64に変換して返します。
        return value.int64Value
    // 空き容量の計算プロパティを閉じます。
    }

    // モデルが完成マーカーと全ファイルの実容量を満たすか調べます。
    func isInstalled(_ model: OnDeviceAIModel) -> Bool {
        // Apple管理モデルはアプリ専用領域に置かれないため未インストールとして扱います。
        guard model.backend != .apple else { return false }
        // 安全なパス情報と固定revisionを確認します。
        guard let identity = validatedIdentity(for: model) else { return false }
        // 完成済みモデルのディレクトリを特定します。
        let installDirectory = modelRoot.appendingPathComponent(identity.id, isDirectory: true).appendingPathComponent(identity.revision, isDirectory: true)
        // マーカーを読み取れることを確認します。
        guard let data = try? Data(contentsOf: installDirectory.appendingPathComponent(markerName)) else { return false }
        // マーカー形式をJSONから復元します。
        guard let marker = try? JSONDecoder().decode(AIModelInstallMarker.self, from: data) else { return false }
        // markerのモデルID・revision・ファイル一覧が有効であることを確認します。
        guard marker.id == identity.id, marker.revision == identity.revision, !marker.fileSizes.isEmpty else { return false }
        // markerの各項目も許可拡張子と安全な相対pathだけで構成されることを確認します。
        guard marker.fileSizes.keys.allSatisfy({ isSafeRelativePath($0) && isAllowedFile($0) }) else { return false }
        // markerが推論に必須な設定、tokenizer、少なくとも一つのweightを記録しているか調べます。
        guard (try? validateRequiredFiles(marker.fileSizes)) != nil else { return false }
        // マーカーに記録したすべてのファイルが同じ容量で存在することを調べます。
        return marker.fileSizes.allSatisfy { relativeName, expectedSize in
            // 相対名が安全で、実ファイルの容量も取得できることを確認します。
            guard isSafeRelativePath(relativeName), let actualSize = fileSize(at: installDirectory.appendingPathComponent(relativeName)) else { return false }
            // 実容量と完成時に記録した容量が同じ場合だけ有効とします。
            return actualSize == expectedSize
        // allSatisfyの判定を閉じます。
        }
    // isInstalledを閉じます。
    }

    // モデル専用領域内で最終インストール先のURLを返します。
    func directory(for model: OnDeviceAIModel) -> URL {
        // 安全なIDと固定revisionがある時だけ対応する保存先を返します。
        guard let identity = validatedIdentity(for: model) else { return modelRoot.appendingPathComponent("invalid-model", isDirectory: true) }
        // モデルIDとrevisionを別々のディレクトリ階層にします。
        return modelRoot.appendingPathComponent(identity.id, isDirectory: true).appendingPathComponent(identity.revision, isDirectory: true)
    // directoryを閉じます。
    }

    // downloadBytesに安全余裕を加えた必要空き容量をUIにも公開します。
    func requiredStorageBytes(for model: OnDeviceAIModel) -> Int64 {
        // 負値を0に丸めて安全余裕の基準にします。
        let expectedBytes = max(0, model.downloadBytes)
        // 必要容量の5%または64 MiBの大きい方を余裕として取ります。
        let headroom = max(67_108_864, expectedBytes / 20)
        // 加算overflow時には満たせない最大値を返します。
        let result = expectedBytes.addingReportingOverflow(headroom)
        // overflowの有無に応じた必要容量を返します。
        return result.overflow ? Int64.max : result.partialValue
    // requiredStorageBytesを閉じます。
    }

    // Hugging Face上の公開ファイルをstaging領域へ取得し、全検証後に完成場所へ公開します。
    func download(_ model: OnDeviceAIModel) async throws {
        // 呼び出し直後にcancel済みならactive枠を取らずに終了します。
        try Task.checkCancellation()
        // Apple管理モデルを公開配布元から取得させないようにします。
        guard model.backend != .apple else { throw AIModelDownloadError.appleManagedModel }
        // 二重取得を避けるため、開始前に進行中操作がないことを確認します。
        guard activeOperationID == nil else { throw AIModelDownloadError.downloadAlreadyActive }
        // repo、固定revision、IDの安全性を検査して保存先に使います。
        let identity = try validatedIdentityOrThrow(for: model)
        // 完成済みなら同じバイト列を再取得しないで正常終了します。
        if isInstalled(model) { progress = 1; lastError = nil; return }
        // この取得と後続callbackを結び付ける一意な値を作ります。
        let operationID = UUID()
        // 遅れて届くcallbackを判別できるよう現在操作として記録します。
        activeOperationID = operationID
        // 画面に選択されたモデルの取得中状態を公開します。
        activeModelID = identity.id
        // 新規取得の進捗を初期化します。
        progress = 0
        // 以前のエラー表示を消します。
        lastError = nil
        // 最終配置先の親ディレクトリを組み立てます。
        let modelDirectory = modelRoot.appendingPathComponent(identity.id, isDirectory: true)
        // 完成版の配置先をモデルrevisionごとに分けます。
        let finalDirectory = modelDirectory.appendingPathComponent(identity.revision, isDirectory: true)
        // この処理だけが使うstagingディレクトリ名を作成します。
        let stagingDirectory = modelDirectory.appendingPathComponent(".\(identity.revision).partial-\(operationID.uuidString)", isDirectory: true)
        // API取得とファイル保存を含む処理の成否を状態へ反映します。
        do {
        // 同revisionのUUID付き前回partialだけを取得前の回収対象にします。
        try removeAbandonedStagingDirectories(modelDirectory: modelDirectory, revision: identity.revision)
            // 専用領域とstagingフォルダを作成します。
            try fileManager.createDirectory(at: stagingDirectory, withIntermediateDirectories: true)
            // commit SHAを指定して、許可対象の公開ファイル一覧を取得します。
            let remoteFiles = try await fetchRemoteFiles(repoId: identity.repoId, revision: identity.revision, operationID: operationID)
            // metadata応答直後にstore.cancel()されたoperationをここで止めます。
            guard activeOperationID == operationID else { throw CancellationError() }
            // 呼び出し側Taskのcancelもmetadata解析後に反映します。
            try Task.checkCancellation()
            // 合計予定byte数をオーバーフローに注意して計算します。
            let totalBytes = remoteFiles.reduce(Int64(0)) { partial, file in partial.addingReportingOverflow(file.size).overflow ? Int64.max : partial + file.size }
            // metadata filter後の容量がカタログで確認した固定revision合計と等しいか検査します。
            guard totalBytes == model.downloadBytes else { throw AIModelDownloadError.downloadSizeMismatch(expected: model.downloadBytes, actual: totalBytes) }
            // ダウンロード前に実際の空き容量と予定容量を比較します。
            let freeBytes = availableStorageBytes ?? 0
            // UI表示と共通のheadroomを含む必要容量を計算します。
            let requiredBytes = requiredStorageBytes(for: model)
            // 空き容量が予定容量に足りなければ転送を始めません。
            guard freeBytes >= requiredBytes else { throw AIModelDownloadError.insufficientStorage(required: requiredBytes, available: freeBytes) }
            // APIの応答サイズと進捗計算に一貫して使うbyte数を初期化します。
            var completedBytes: Int64 = 0
            // 正規化後に検証する実ファイル容量を収集します。
            var actualFileSizes: [String: Int64] = [:]
            // 許可済みのファイルを一つずつメモリ全体に載せず取得します。
            for remoteFile in remoteFiles {
                // 次ファイルへ移る前に操作キャンセルを検出します。
                try Task.checkCancellation()
                // 相対パスを再検査してstaging内の保存先へ変換します。
                guard isSafeRelativePath(remoteFile.name) else { throw AIModelDownloadError.unsafeFilePath }
                // サブフォルダを含めたファイル保存先を作成します。
                let destination = stagingDirectory.appendingPathComponent(remoteFile.name)
                // Hubのファイル名に含まれる親フォルダを作ります。
                try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
                // 今ファイルより前に完了したbyte数をcallback用の定数へ固定します。
                let completedBytesBeforeFile = completedBytes
                // HTTP失敗やTask cancelでもdelegate一時ファイルを破棄できるよう保持します。
                activeDownloadDelegate = nil
                // ファイル専用の進捗delegateとキャンセル可能なsessionを用意します。
                let delegate = AIModelDownloadDelegate { [weak self] written, expected in
                    // MainActorへ進捗変更を送り、操作IDで古い通知を捨てます。
                    Task { @MainActor [weak self] in
                        // 現在の取得と同じoperationから来た通知だけ反映します。
                        guard let self, self.activeOperationID == operationID else { return }
                        // API容量が不明ならURLSessionの予定量で割合を計算します。
                        let currentExpected = expected > 0 ? min(expected, remoteFile.size) : remoteFile.size
                        // 0 byteファイルや未知容量でも全体progressが破綻しないようにします。
                        let currentWritten = min(max(0, written), max(0, currentExpected))
                        // 完了済みbyteと現在file byteの比率を単調な進捗候補にします。
                        let nextProgress = totalBytes > 0 ? min(0.999, Double(completedBytesBeforeFile + currentWritten) / Double(totalBytes)) : 0
                        // 同operationの遅れたfile callbackで進捗が逆戻りしないよう最大値を保ちます。
                        self.progress = max(self.progress, nextProgress)
                    // MainActor上の進捗更新を閉じます。
                    }
                // delegate生成を閉じます。
                }
                // ファイルごとのdelegateをcancel可能な状態として公開します。
                activeDownloadDelegate = delegate
                // GET要求を固定commitのresolve URLへ作ります。
                let request = try makeDownloadRequest(repoId: identity.repoId, revision: identity.revision, path: remoteFile.name)
                // 今回のファイル取得だけに使うURLSessionを用意します。
                let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
                // store.cancel()から転送を止められるようsessionを公開します。
                activeSession = session
                // catch側でもsession所有者を特定できるよう記録します。
                activeSessionOperationID = operationID
                // DownloadTask delegateからresponseと一時file URLを受け取り、大容量Dataを作りません。
                let (temporaryURL, response) = try await delegate.download(session: session, request: request)
                // response検査がthrowしても一時ファイルが残らないdeferを設定します。
                defer { try? fileManager.removeItem(at: temporaryURL) }
                // delegate成功とTask cancelが競合してもcancel後のfileを配置しません。
                try Task.checkCancellation()
                // HTTP応答が成功範囲であることを確認します。
                guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                    // 失敗応答のstatusを保存してから例外にします。
                    throw AIModelDownloadError.httpFailure((response as? HTTPURLResponse)?.statusCode ?? -1)
                // HTTP検査の条件を閉じます。
                }
                // callbackが古いoperationのものなら途中で公開せずキャンセルします。
                guard activeOperationID == operationID else { throw CancellationError() }
                // APIが報告した容量と一時ファイルの実容量を0 byteも含めて照合します。
                guard fileSize(at: temporaryURL) == remoteFile.size else { throw AIModelDownloadError.invalidMetadata }
                // URLSessionが一時ファイルを消す前に専用stagingへ移動します。
                try fileManager.moveItem(at: temporaryURL, to: destination)
                // LFSがSHAを公開しているファイルだけ1 MiB単位で照合します。
                if let expectedHash = remoteFile.sha256 {
                    // ディスクからstreaming計算したSHAがメタデータと一致するか検証します。
                    let actualHash = try await Self.sha256(of: destination, chunkSize: hashChunkSize)
                    // store.cancel()だけが呼ばれた場合も古いoperationを続行させません。
                    guard activeOperationID == operationID else { throw CancellationError() }
                    // 呼び出し元Taskのcancelもhash完了直後に反映します。
                    try Task.checkCancellation()
                    // 不一致ファイルを完成扱いにしないよう失敗させます。
                    guard actualHash.caseInsensitiveCompare(expectedHash) == .orderedSame else { throw AIModelDownloadError.checksumMismatch(remoteFile.name) }
                // LFS hashがある場合だけ検証する条件を閉じます。
                }
                // BonsaiやMini2の互換性向けにconfig.jsonの量子化情報を正規化します。
                if remoteFile.name == "config.json" { try normalizeConfiguration(at: destination, model: model) }
                // 正規化を終えた実ファイルのbyte数を読み取ります。
                guard let actualSize = fileSize(at: destination) else { throw AIModelDownloadError.invalidMetadata }
                // 完成マーカーに入れる相対名と実容量を記録します。
                actualFileSizes[remoteFile.name] = actualSize
                // 次ファイル進捗の基準をAPI容量分だけ進めます。
                completedBytes += remoteFile.size
                // 完了した転送sessionを閉じてcallbackの残留を抑えます。
                session.finishTasksAndInvalidate()
                // このファイルのsession参照を解除します。
                if activeSession === session {
                    // 完了済みsessionの共有参照を解除します。
                    activeSession = nil
                    // session所有者の記録を解除します。
                    activeSessionOperationID = nil
                // session一致時だけ参照を解除する条件を閉じます。
                }
                // 完了済みdelegateのtemp参照とcancel管理を解除します。
                if activeDownloadDelegate === delegate { activeDownloadDelegate = nil }
            // ファイル取得loopを閉じます。
            }
            // モデル推論に必須の設定・トークナイザー・重みが揃ったか確認します。
            try validateRequiredFiles(actualFileSizes)
            // ID、固定commit、正規化後の実容量を完成マーカーに記録します。
            let marker = AIModelInstallMarker(id: identity.id, revision: identity.revision, fileSizes: actualFileSizes)
            // 後からのinstalled判定に使う完成マーカーを書き込みます。
            let markerData = try JSONEncoder().encode(marker)
            // 完成markerをstaging領域に作ってからディレクトリを公開します。
            try markerData.write(to: stagingDirectory.appendingPathComponent(markerName), options: .atomic)
            // 最終fileとmarkerの後にもcancelが届いていないか公開直前に確認します。
            guard activeOperationID == operationID else { throw CancellationError() }
            // service側Taskのcancelもrename直前に反映します。
            try Task.checkCancellation()
            // 既存の壊れた配置がある場合は専用revision領域だけ片付けます。
            if fileManager.fileExists(atPath: finalDirectory.path) { try fileManager.removeItem(at: finalDirectory) }
            // stagingを同じvolume上でrenameし、完成版として原子的に公開します。
            try fileManager.moveItem(at: stagingDirectory, to: finalDirectory)
            // 完成した状態の更新番号を一度だけ増やします。
            stateVersion += 1
            // UIへ完了を表示します。
            progress = 1
        // 取得処理内の全てのthrow経路を受け止めます。
        } catch {
            // このoperationが今も最新なら、そのsessionだけ停止します。
            if activeSessionOperationID == operationID {
                // このoperationが所有する転送だけを停止します。
                activeSession?.invalidateAndCancel()
                // このoperationのsessionを共有状態から外します。
                activeSession = nil
                // session所有者の記録を解除します。
                activeSessionOperationID = nil
            // session所有者が一致する時だけ止める条件を閉じます。
            }
            // 部分取得や検証失敗をinstalledに見せないようstagingだけ削除します。
            try? fileManager.removeItem(at: stagingDirectory)
            // 現在のoperationからの失敗なら画面状態にエラーを反映します。
            if activeOperationID == operationID {
                // callbackで退避した自分の一時ファイルだけ破棄します。
                activeDownloadDelegate?.discardTemporaryFile(cancelled: true)
                // キャンセル以外の失敗内容を画面へ保存します。
                lastError = error is CancellationError || Task.isCancelled ? nil : error.localizedDescription
                // キャンセル後や失敗後は進捗を0に戻します。
                progress = 0
                // 失敗後も次のモデル取得を開始できるよう進行中IDを解除します。
                activeModelID = nil
                // このoperationの識別情報を解除します。
                activeOperationID = nil
                // session参照を解除します。
                activeSession = nil
                // session所有者も解除します。
                activeSessionOperationID = nil
                // 完了したoperationのdelegate参照を解除します。
                activeDownloadDelegate = nil
            // operation一致時の状態変更を閉じます。
            }
            // 元の失敗型を呼び出し元にも返します。
            throw error
        // 取得処理のdo-catchを閉じます。
        }
        // 完了後に自分のoperation状態だけを解除します。
        if activeOperationID == operationID {
            // 進行中モデルIDを画面から消します。
            activeModelID = nil
            // operation IDを解除して次の取得を受け付けます。
            activeOperationID = nil
            // session参照を解除します。
            activeSession = nil
        // operation一致時の後処理を閉じます。
        }
    // downloadメソッドを閉じます。
    }

    // 進行中のURLSession転送を止め、呼び出し側Taskのcancelも反映できるようにします。
    func cancel() {
        // Task.cancelから届くキャンセル状態をURLSessionの通信へ伝えます。
        activeSession?.invalidateAndCancel()
        // delegate内で退避済みの一時ファイルも破棄し、遅延callbackを拒否します。
        activeDownloadDelegate?.discardTemporaryFile(cancelled: true)
        // delegate参照を解除して次のoperationと分離します。
        activeDownloadDelegate = nil
        // session参照を解除し、次のoperationが古いsessionを誤用しないようにします。
        activeSession = nil
        // session所有者の記録も解除します。
        activeSessionOperationID = nil
        // 遅れて届く進捗callbackを無効化するためoperation IDを破棄します。
        activeOperationID = nil
        // 現在のモデル表示を解除します。
        activeModelID = nil
        // 表示中の進捗を初期値に戻します。
        progress = 0
    // cancelを閉じます。
    }

    // アプリ専用のモデル保存先に限って、完成済みモデルを削除します。
    func delete(_ model: OnDeviceAIModel) throws {
        // Apple管理モデルの保存をアプリから削除しないよう拒否します。
        guard model.backend != .apple else { throw AIModelDownloadError.appleManagedModel }
        // 削除先の識別子を検証してからパスを組み立てます。
        let identity = try validatedIdentityOrThrow(for: model)
        // 同じモデルのダウンロード中に保存先を消さないよう拒否します。
        guard activeModelID != identity.id else { throw AIModelDownloadError.downloadAlreadyActive }
        // 削除対象はこのモデルIDと固定revision専用の最終ディレクトリです。
        let target = directory(for: model)
        // 対象がApplication Supportのモデル専用root内にあることを確かめます。
        guard target.standardizedFileURL.path.hasPrefix(modelRoot.standardizedFileURL.path + "/") else { throw AIModelDownloadError.unsafeFilePath }
        // 物理削除が成功した後だけinstalled状態の版番号を進めます。
        if fileManager.fileExists(atPath: target.path) {
            // モデル専用ディレクトリだけを削除します。
            try fileManager.removeItem(at: target)
            // 削除成功を観測して状態更新を知らせます。
            stateVersion += 1
        // 対象存在時の物理削除を閉じます。
        }
    // deleteを閉じます。
    }

    // Application Support内に専用rootを確保して返します。
    private var modelRoot: URL {
        // 呼び出し側が明示した一時rootをテスト専用に利用します。
        if let injectedRootURL { return injectedRootURL }
        // ユーザーのモデルデータを保存する標準Application Support URLを取得します。
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Library", isDirectory: true).appendingPathComponent("Application Support", isDirectory: true)
        // アプリ専用の固定ディレクトリ名を追加します。
        return support.appendingPathComponent("WealthyAIModels", isDirectory: true)
    // modelRoot計算プロパティを閉じます。
    }

    // モデルの識別子と公開Hub参照を安全な値に検査します。
    private func validatedIdentity(for model: OnDeviceAIModel) -> (id: String, revision: String, repoId: String)? {
        // model IDを英数字・ハイフン・アンダースコアのみに制限します。
        guard !model.id.isEmpty, model.id.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil else { return nil }
        // Hub公開repoはowner/name形式で、空要素やdot要素を含まない形にします。
        guard let repoId = model.repoId, repoId.range(of: "^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", options: .regularExpression) != nil else { return nil }
        // revisionはブランチ名でなく固定40桁のcommit SHAだけを許可します。
        guard let revision = model.revision?.lowercased(), revision.range(of: "^[0-9a-f]{40}$", options: .regularExpression) != nil else { return nil }
        // 検証済みの識別情報だけを後続処理へ返します。
        return (model.id, revision, repoId)
    // validatedIdentityを閉じます。
    }

    // 識別情報が不正なら内容を分けて適切なエラーにして返します。
    private func validatedIdentityOrThrow(for model: OnDeviceAIModel) throws -> (id: String, revision: String, repoId: String) {
        // パストラバーサルにつながるIDを最初に拒否します。
        guard !model.id.isEmpty, model.id.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil else { throw AIModelDownloadError.invalidModelIdentity }
        // repoIdがない時に公開取得できないことを明示します。
        guard model.repoId != nil else { throw AIModelDownloadError.missingRepository }
        // repoIdの安全なowner/name構造を明示的に検査します。
        guard let repoId = model.repoId, repoId.range(of: "^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", options: .regularExpression) != nil else { throw AIModelDownloadError.invalidRepository }
        // ID、repoId、revisionの残りの形式を検査します。
        guard let revision = model.revision?.lowercased(), revision.range(of: "^[0-9a-f]{40}$", options: .regularExpression) != nil else { throw AIModelDownloadError.invalidRevision }
        // 安全性を確認した値だけ返します。
        return (model.id, revision, repoId)
    // validatedIdentityOrThrowを閉じます。
    }

    // 同じmodel/revision用に以前残されたpartial stagingだけを回収します。
    private func removeAbandonedStagingDirectories(modelDirectory: URL, revision: String) throws {
        // model rootが無ければ回収対象もありません。
        guard fileManager.fileExists(atPath: modelDirectory.path) else { return }
        // 現revision用にStoreが作成する一意prefixを固定します。
        let stagingPrefix = ".\(revision).partial-"
        // model directory直下の項目を読み込みます。
        let entries = try fileManager.contentsOfDirectory(at: modelDirectory, includingPropertiesForKeys: nil)
        // 現revisionかつUUID suffixの専用stagingだけを調べます。
        for entry in entries where entry.lastPathComponent.hasPrefix(stagingPrefix) {
            // UUID以外のsuffixや別形式の利用者ファイルには触れません。
            guard UUID(uuidString: String(entry.lastPathComponent.dropFirst(stagingPrefix.count))) != nil else { continue }
            // 通常ディレクトリだけを回収し、symlinkには追従しません。
            guard let attributes = try? fileManager.attributesOfItem(atPath: entry.path), attributes[.type] as? FileAttributeType == .typeDirectory else { continue }
            // 削除失敗を握りつぶさずdownloadまたは初期化エラーとして返します。
            try fileManager.removeItem(at: entry)
        // 同revisionのpartial回収loopを閉じます。
        }
    // removeAbandonedStagingDirectoriesを閉じます。
    }

    // カタログにあるMLXモデルの中断stageだけを起動時に回収します。
    private func removeKnownAbandonedStagingDirectories() throws {
        // rootを使う前に作られたアプリでは回収対象がないので終了します。
        guard fileManager.fileExists(atPath: modelRoot.path) else { return }
        // カタログで管理するモデルだけを順番に調べます。
        for model in AIModelCatalog.models where model.backend == .mlx {
            // 安全なモデルIDと40桁revisionが揃うentryを使います。
            guard let identity = validatedIdentity(for: model) else { continue }
            // 既知モデルの専用directoryを組み立てます。
            let modelDirectory = modelRoot.appendingPathComponent(identity.id, isDirectory: true)
            // 存在するmodel folder内で同revisionのpartialを回収します。
            try removeAbandonedStagingDirectories(modelDirectory: modelDirectory, revision: identity.revision)
        // カタログモデル回収loopを閉じます。
        }
    // removeKnownAbandonedStagingDirectoriesを閉じます。
    }

    // 公開APIのモデルrevision情報を取得し、許可するファイルだけ抽出します。
    private func fetchRemoteFiles(repoId: String, revision: String, operationID: UUID) async throws -> [AIModelRemoteFile] {
        // 設定済みのproductionまたはテストHubをcomponentsへ変換します。
        guard let hubBaseURL, var components = URLComponents(url: hubBaseURL, resolvingAgainstBaseURL: false) else { throw AIModelDownloadError.invalidMetadata }
        // Hugging Faceの固定commit metadata endpointを設定します。
        components.path = "/api/models/\(repoId)/revision/\(revision)"
        // LFSのサイズとsha256をAPI responseへ含めます。
        components.queryItems = [URLQueryItem(name: "blobs", value: "true")]
        // 完全なAPI URLを検証します。
        guard let url = components.url else { throw AIModelDownloadError.invalidMetadata }
        // 公開Hubにmetadataだけを問い合わせるsessionを用意します。
        let session = URLSession(configuration: .default)
        // cancel()からmetadata requestも停止できるようsessionを登録します。
        activeSession = session
        // session所有者を記録します。
        activeSessionOperationID = operationID
        // 公開Hubから小さなmetadata JSONだけを取得します。
        let (data, response) = try await session.data(from: url)
        // metadata取得sessionを閉じます。
        session.finishTasksAndInvalidate()
        // 現在も同じsessionなら共有参照を解除します。
        if activeSession === session {
            // session参照を解除します。
            activeSession = nil
            // session所有者を解除します。
            activeSessionOperationID = nil
        // session一致時の参照解除条件を閉じます。
        }
        // APIが成功statusを返すことを確認します。
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw AIModelDownloadError.httpFailure((response as? HTTPURLResponse)?.statusCode ?? -1) }
        // JSON objectとして応答を読み取ります。
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any], let siblings = root["siblings"] as? [[String: Any]] else { throw AIModelDownloadError.invalidMetadata }
        // 安全で許可された名前のファイルだけをリストに変換します。
        let files = try siblings.compactMap { sibling -> AIModelRemoteFile? in
            // Hubが返した相対ファイル名を取得します。
            guard let name = sibling["rfilename"] as? String else { throw AIModelDownloadError.invalidMetadata }
            // セキュリティ上危険な名前は拡張子判定前に拒否します。
            guard isSafeRelativePath(name) else { throw AIModelDownloadError.unsafeFilePath }
            // 既知のmetadataや未知のバイナリなど許可外拡張子を除外します。
            guard isAllowedFile(name) else { return nil }
            // API file sizeまたはLFS sizeのどちらかを整数として読み取ります。
            let lfs = sibling["lfs"] as? [String: Any]
            // LFSのsizeを優先し、未提供時は通常のsizeを用います。
            guard let sizeNumber = (lfs?["size"] as? NSNumber) ?? (sibling["size"] as? NSNumber) else { throw AIModelDownloadError.invalidMetadata }
            // NSNumberの容量をInt64として保持します。
            let size = sizeNumber.int64Value
            // 負のbyte数を拒否します。
            guard size >= 0 else { throw AIModelDownloadError.invalidMetadata }
            // APIがlfs.sha256を持つ場合だけ値を保持します。
            let sha = lfs?["sha256"] as? String
            // ファイル情報を返します。
            return AIModelRemoteFile(name: name, size: size, sha256: sha)
        // compactMapで許可対象を抽出します。
        }
        // 許可形式が空なら取得を始めないようにします。
        guard !files.isEmpty else { throw AIModelDownloadError.noDownloadableFiles }
        // repositoryの順序に依存しないようファイル名で安定ソートします。
        return files.sorted { $0.name < $1.name }
    // fetchRemoteFilesを閉じます。
    }

    // 固定revisionの一つのファイルをresolveするGET requestを作成します。
    private func makeDownloadRequest(repoId: String, revision: String, path: String) throws -> URLRequest {
        // 相対path各要素をpercent-encodeし、path separatorだけ保持します。
        // path許可文字からURLの制御文字とpercent escapeを除きます。
        var pathCharacters = CharacterSet.urlPathAllowed
        // queryやfragmentとして解釈される文字をencode対象にします。
        pathCharacters.remove(charactersIn: "?#%")
        // 各path要素を個別にencodeして階層separatorだけ維持します。
        let escapedPath = path.split(separator: "/").map { String($0).addingPercentEncoding(withAllowedCharacters: pathCharacters) ?? String($0) }.joined(separator: "/")
        // 設定済みのproductionまたはテストHubをcomponentsへ変換します。
        guard let hubBaseURL, var components = URLComponents(url: hubBaseURL, resolvingAgainstBaseURL: false) else { throw AIModelDownloadError.invalidMetadata }
        // repoとパスをつないでcommit固定のファイルURLにします。
        components.path = "/\(repoId)/resolve/\(revision)/\(escapedPath)"
        // 構築に失敗したURLを通信へ流さないようにします。
        guard let url = components.url else { throw AIModelDownloadError.invalidMetadata }
        // URLSession用の明示的なGET requestを返します。
        var request = URLRequest(url: url)
        // 認証不要な公開ファイルを取得するHTTP methodを設定します。
        request.httpMethod = "GET"
        // requestを返します。
        return request
    // makeDownloadRequestを閉じます。
    }

    // ファイル名の拡張子が取得許可listに含まれるか調べます。
    private func isAllowedFile(_ name: String) -> Bool {
        // 拡張子を大文字小文字に依存せず判定します。
        let lower = name.lowercased()
        // JSON、Safetensors、指定tokenizer資材、文字templateだけ許可します。
        return lower.hasSuffix(".json") || lower.hasSuffix(".safetensors") || lower.hasSuffix("tokenizer.model") || lower.hasSuffix(".tiktoken") || lower.hasSuffix(".txt") || lower.hasSuffix(".jinja")
    // isAllowedFileを閉じます。
    }

    // Hub内相対ファイル名から絶対パスや親移動表現を拒否します。
    private func isSafeRelativePath(_ path: String) -> Bool {
        // 空文字、絶対表記、Windows separator、NUL byteを拒否します。
        guard !path.isEmpty, !path.hasPrefix("/"), !path.contains("\\"), !path.unicodeScalars.contains(where: { $0.value == 0 }) else { return false }
        // 各componentに空要素、dot、親移動要素がないことを確認します。
        return path.split(separator: "/", omittingEmptySubsequences: false).allSatisfy { !$0.isEmpty && $0 != "." && $0 != ".." }
    // isSafeRelativePathを閉じます。
    }

    // config.json内のquantizationをruntime用に正規化します。
    private func normalizeConfiguration(at url: URL, model: OnDeviceAIModel) throws {
        // configのJSON objectを読み取れることを確認します。
        guard var config = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any] else { throw AIModelDownloadError.invalidMetadata }
        // モデルID、配布元、表示名を小文字化して系列名検出に使います。
        let family = "\(model.id) \(model.repoId ?? "") \(model.name)".lowercased()
        // 信頼できないPython実装名やremote-code指定をconfigから除きます。
        config.removeValue(forKey: "model_file")
        // AutoConfigのPythonクラス指定を削除し、Swift runtimeへ渡しません。
        config.removeValue(forKey: "auto_map")
        // Python実装を明示的に信頼する設定値もruntimeへ渡しません。
        config.removeValue(forKey: "trust_remote_code")
        // provider固有のPython remote codeフラグもSwift runtimeへ渡しません。
        config.removeValue(forKey: "python_remote_code")
        // BonsaiまたはMiniCPM5-2B系は共通のquantizationフィールドをruntimeへ渡します。
        if family.contains("bonsai") || family.contains("minicpm5-2b") || family.contains("mini2") {
            // 配布元のquantization_configが存在した場合だけ同じ値をquantizationへコピーします。
            if let quantization = config["quantization_config"] { config["quantization"] = quantization }
        // 特定系列だけに適用する量子化コピー条件を閉じます。
        }
        // Bonsai configのmodel_typeをアプリruntimeが認識する値へ固定します。
        if family.contains("bonsai") { config["model_type"] = "wealthy_bonsai_qwen3" }
        // 整形済みJSONで書き戻し、実際に保存した容量を後段で計測します。
        let normalized = try JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys])
        // 同一staging volume内で安全にconfigを置換します。
        try normalized.write(to: url, options: .atomic)
    // normalizeConfigurationを閉じます。
    }

    // 推論が始められる最小のconfig、tokenizer、safetensorsがあることを確認します。
    private func validateRequiredFiles(_ files: [String: Int64]) throws {
        // 必須のJSON設定とトークナイザー設定を列挙します。
        let required = ["config.json", "tokenizer.json", "tokenizer_config.json"]
        // 不足する必須ファイル名を探します。
        let missing = required.filter { files[$0] == nil }
        // safetensors重みが少なくとも一つあることを確認します。
        let hasWeights = files.keys.contains { $0.lowercased().hasSuffix(".safetensors") }
        // 必須設定か重みが不足する時に具体的な名前を返します。
        guard missing.isEmpty, hasWeights else { throw AIModelDownloadError.missingRequiredFiles((missing + (hasWeights ? [] : ["*.safetensors"])).joined(separator: ", ")) }
    // validateRequiredFilesを閉じます。
    }

    // 指定URLの通常ファイル容量を安全に読み取ります。
    private func fileSize(at url: URL) -> Int64? {
        // FileManager属性のNSNumberから64bit byte数へ変換します。
        guard let value = try? fileManager.attributesOfItem(atPath: url.path)[.size] as? NSNumber else { return nil }
        // 数値化したファイル容量を返します。
        return value.int64Value
    // fileSizeを閉じます。
    }

    // CryptoKitを使い、巨大ファイルを1 MiBずつ読んでSHA-256を計算します。
    nonisolated private static func sha256(of url: URL, chunkSize: Int) async throws -> String {
        // ファイル読み込みをUI actorから切り離したTaskとして起動します。
        let hashTask = Task.detached(priority: .utility) {
            // 追記型SHA256計算器を作成します。
            var hasher = SHA256()
            // ファイルをread-onlyで開きます。
            let handle = try FileHandle(forReadingFrom: url)
            // FileHandleを確実に閉じるdefer処理を設定します。
            defer { try? handle.close() }
            // EOFまで固定サイズchunkを順番に読み込みます。
            while true {
                // 呼び出しTaskからのcancelをchunk境界ごとに反映します。
                try Task.checkCancellation()
                // 最大1 MiBの次のbyte列を読み込みます。
                let chunk = try handle.read(upToCount: chunkSize) ?? Data()
                // 空byte列はEOFを意味するのでloopを終了します。
                if chunk.isEmpty { break }
                // 読み込んだchunkを全体ハッシュへ追加します。
                hasher.update(data: chunk)
            // 読み込みloopを閉じます。
            }
            // 最終ハッシュのbyte列を16進数文字列へ変換します。
            return hasher.finalize().map { String(format: "%02x", $0) }.joined()
        // detached Taskを作成します。
        }
        // 親TaskのcancelをSHAのstreaming Taskへ伝えながら結果をawaitします。
        return try await withTaskCancellationHandler {
            // SHA256結果またはchunk境界でのCancellationErrorを受け取ります。
            try await hashTask.value
        // cancellation handlerのoperationを閉じます。
        } onCancel: {
            // 呼び出し側がcancelしたらhash loopも停止させます。
            hashTask.cancel()
        // cancellation handlerを閉じます。
        }
    // sha256を閉じます。
    }
// ダウンロードストアの定義を閉じます。
}
