# SwiftコンパイラとローカルHTTP fixtureを使い、巨大モデルなしで取得処理を検証します。
import hashlib
# JSON応答と合格markerを扱う標準機能を読み込みます。
import json
# 一時rootと一時compiler cacheを作る標準機能を読み込みます。
import tempfile
# fixtureのthreadと、Swift harnessの起動処理を読み込みます。
import subprocess
# fixture serverを一定時間だけ待つ標準機能を読み込みます。
import time
# URL pathとqueryを分ける標準機能を読み込みます。
from urllib.parse import unquote, urlsplit
# lock、threaded HTTP server、response handlerを読み込みます。
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
# local fixtureをserveするthreadを読み込みます。
from threading import Lock, Thread
# repository rootと一時download fileの確認に使う標準機能を読み込みます。
from pathlib import Path
# compiler結果と終了コードを検証する標準機能を読み込みます。
import sys

# この検証スクリプトの所在からrepository rootを解決します。
PROJECT_ROOT = Path(__file__).resolve().parents[1]
# 毎回同じ小さなconfig JSONを生成します。
CONFIG_BYTES = json.dumps({"model_type": "test", "quantization_config": {"bits": 4}, "auto_map": {"x": "evil"}, "model_file": "evil", "trust_remote_code": True, "python_remote_code": True}, separators=(",", ":"), sort_keys=True).encode()
# 必須tokenizer JSONの内容を用意します。
TOKENIZER_BYTES = b'{"version":"1.0","model":{"type":"BPE"}}'
# tokenizer runtime設定JSONの内容を用意します。
TOKENIZER_CONFIG_BYTES = b'{"tokenizer_class":"FixtureTokenizer"}'
# 通常シナリオに使う2 MiBのsynthetic重みを用意します。
SMALL_WEIGHT_BYTES = bytes(range(256)) * 8192
# cancel scenarioに使う4 MiBのsynthetic重みを用意します。
CANCEL_WEIGHT_BYTES = bytes(range(256)) * 16384
# file transferと状態counterを共有するlockを作成します。
STATE_LOCK = Lock()
# slow cancel transferが実際に送信したbyte数を初期化します。
CANCEL_BYTES_WRITTEN = 0
# cancel fixtureのweights request数を初期化します。
CANCEL_WEIGHT_REQUESTS = 0

# repositoryごとの合成ファイルmanifestを作成します。
def make_manifest(repository):
    # cancelだけ4 MiBの重み、それ以外は2 MiBの重みを使います。
    weights = CANCEL_WEIGHT_BYTES if repository == "owner/cancel" else SMALL_WEIGHT_BYTES
    # インストールに必須の設定、tokenizer、重みをfile mapに入れます。
    files = {"config.json": CONFIG_BYTES, "tokenizer.json": TOKENIZER_BYTES, "tokenizer_config.json": TOKENIZER_CONFIG_BYTES, "model.safetensors": weights}
    # file metadataを並べ替え可能な形式へ変換します。
    siblings = []
    # 各ファイルの実容量とSHAをmetadataへ追加します。
    for filename, content in files.items():
        # APIが報告するsizeを実byte数に合わせます。
        file_size = len(content)
        # size failureではsafetensorsの宣言容量だけ一byte増やします。
        if repository == "owner/size" and filename == "model.safetensors":
            # response本体は同じままAPI sizeだけ不一致にします。
            file_size += 1
        # LFS SHA-256を内容から計算します。
        digest = hashlib.sha256(content).hexdigest()
        # hash failureでは重みSHAを明らかに間違った40桁へ置き換えます。
        if repository == "owner/hash" and filename == "model.safetensors":
            # 不一致SHAでverify failureを誘発します。
            digest = "0" * 64
        # standard Hubのsiblings/lfs形に必要な情報を追加します。
        siblings.append({"rfilename": filename, "size": file_size, "lfs": {"size": file_size, "sha256": digest}})
    # 非許可のPythonファイルがfilterされるmetadata entryも追加します。
    siblings.append({"rfilename": "remote.py", "size": 1, "lfs": {"size": 1, "sha256": "0" * 64}})
    # 非許可のREADMEはcatalog download byte合計に入らないentryとして追加します。
    siblings.append({"rfilename": "README.md", "size": 10})
    # API応答とbytesを使う両方のfixtureデータを返します。
    return siblings, files

# local Hubと同じAPIを返すrequest handlerを定義します。
class FixtureHandler(BaseHTTPRequestHandler):
    # request logsをstderrへ流さずquiet test outputにします。
    def log_message(self, format_string, *args):
        # 標準server logは検証結果に必要ないので空実装にします。
        return

    # GET requestのAPI metadata、state、model fileを応答します。
    def do_GET(self):
        # queryからpathを分離してpercent-escapeされたpathを戻します。
        path_parts = [unquote(part) for part in urlsplit(self.path).path.strip("/").split("/") if part]
        # repository専用のファイルサイズ問い合わせを処理します。
        if path_parts and path_parts[0] == "__size":
            # owner/nameをrepository IDとして結合します。
            repository = "/".join(path_parts[1:])
            # Hub siblingsを組み立てます。
            siblings, _ = make_manifest(repository)
            # allowlist対象だけのsize合計を数えます。
            size = sum(item["size"] for item in siblings if item["rfilename"].endswith((".json", ".safetensors", "tokenizer.model", ".tiktoken", ".txt", ".jinja")))
            # Swift harness向けsize JSONを送ります。
            self.send_json({"size": size})
            # size queryを処理したのでhandlerを終えます。
            return
        # cancel scenarioの進捗を調べるstate endpointを処理します。
        if path_parts == ["__state"]:
            # counterへの同時アクセスをlockで保護します。
            with STATE_LOCK:
                # 現在までにslow weight応答で送信したbyte数を読むためlockを保持します。
                written = CANCEL_BYTES_WRITTEN
            # cancellation testがpollするJSONを返します。
            self.send_json({"cancel_bytes_written": written})
            # state queryを処理したのでhandlerを終えます。
            return
        # Hub API metadata endpointの形かどうか確認します。
        if len(path_parts) >= 6 and path_parts[0:2] == ["api", "models"] and path_parts[-2] == "revision":
            # owner/name要素からrepositoryを作ります。
            repository = "/".join(path_parts[2:-2])
            # 固定revisionを使うHub metadata形式でsiblingsを取得します。
            siblings, _ = make_manifest(repository)
            # model metadata response objectを返します。
            self.send_json({"siblings": siblings})
            # metadata queryを処理したのでhandlerを終えます。
            return
        # resolve/<revision>/<filename> endpointの形式を検査します。
        if len(path_parts) >= 5 and path_parts[2] == "resolve":
            # 最初のowner/name部分からrepositoryを組み立てます。
            repository = "/".join(path_parts[0:2])
            # revisionとresolveを除いた残りをrepo内filenameにします。
            filename = "/".join(path_parts[4:])
            # repositoryが提供するsmall fixture file mapを取得します。
            _, files = make_manifest(repository)
            # server-side response delayとHTTP errorを調整します。
            self.send_model_file(repository, filename, files)
            # model file queryを処理したのでhandlerを終えます。
            return
        # 不明endpointへnot foundを返します。
        self.send_error(404)

    # JSON responseをcontent length付きで送ります。
    def send_json(self, value):
        # JSON objectをUTF-8 byte列にencodeします。
        response = json.dumps(value).encode()
        # status codeを200に設定します。
        self.send_response(200)
        # response content-typeを指定します。
        self.send_header("Content-Type", "application/json")
        # response body byte数を設定します。
        self.send_header("Content-Length", str(len(response)))
        # HTTP headerを確定します。
        self.end_headers()
        # response bodyを送ります。
        self.wfile.write(response)

    # model file bodyをsuccess、size、hash、HTTP、cancel状況に応じて送ります。
    def send_model_file(self, repository, filename, files):
        # 未知のファイル名を拒否します。
        if filename not in files:
            # 404 statusで未知ファイルを終了します。
            self.send_error(404)
            # 未知ファイル処理を終えます。
            return
        # success以外のscenarioでも元file body bytesを使います。
        body = files[filename]
        # HTTP error fixtureはmodel weight取得へ503を返します。
        if repository == "owner/http" and filename == "model.safetensors":
            # HTTP 503 statusを返します。
            self.send_response(503)
            # 小さいresponse textのcontent typeを指定します。
            self.send_header("Content-Type", "text/plain")
            # response body容量を送ります。
            self.send_header("Content-Length", "11")
            # error response headerを確定します。
            self.end_headers()
            # Hub相当のerror messageを返します。
            self.wfile.write(b"unavailable")
            # HTTP error body送信を終了します。
            return
        # size mismatch fixtureでは1byte大きいmetadataと実bodyを返します。
        response_size = len(body)
        # slow cancelは1回目のmodel.safetensors応答だけ行います。
        is_slow_cancel = repository == "owner/cancel" and filename == "model.safetensors"
        # cancel scenario内のrequest番号をlockで取得します。
        if is_slow_cancel:
            # request counterを直列に加算します。
            global CANCEL_WEIGHT_REQUESTS
            # Python threadから見る作成済counterを更新します。
            with STATE_LOCK:
                # cancel request回数を増やします。
                CANCEL_WEIGHT_REQUESTS += 1
                # 最初のtransferだけslowにするため番号を保存します。
                request_number = CANCEL_WEIGHT_REQUESTS
        # model responseを200 statusで始めます。
        self.send_response(200)
        # safetensorsのapplication/octet-stream typeを設定します。
        self.send_header("Content-Type", "application/octet-stream")
        # 全response bodyを送る長さを設定します。
        self.send_header("Content-Length", str(response_size))
        # response headerを確定します。
        self.end_headers()
        # 先頭cancel responseだけ32 KiBずつ遅く書きます。
        if is_slow_cancel and request_number == 1:
            # response bodyを32 KiBごとに分割します。
            chunk_size = 32_768
            # bodyのoffsetを先頭に設定します。
            offset = 0
            # responseが閉じられるまでsynthetic fileを少しずつ送ります。
            while offset < len(body):
                # 次chunkのend offsetを容量内に制限します。
                end_offset = min(offset + chunk_size, len(body))
                # URLSessionへ一つのchunkを送ります。
                try:
                    # slow body chunkをwireへ書きます。
                    self.wfile.write(body[offset:end_offset])
                    # chunkをすぐ受け取れるようflushします。
                    self.wfile.flush()
                # Swift client cancel後のbroken pipeを正常なfixture終了にします。
                except (BrokenPipeError, ConnectionResetError):
                    # client切断ならslow response loopを抜けます。
                    break
                # 送信位置を進めてstate endpointへbyte数を公開します。
                with STATE_LOCK:
                    # slow transferで実際に送った量を加算します。
                    global CANCEL_BYTES_WRITTEN
                    # 今のchunk長をcounterへ追加します。
                    CANCEL_BYTES_WRITTEN += end_offset - offset
                # 次chunkの次の開始位置へ移動します。
                offset = end_offset
                # clientのcancelを観測できるようchunkごとに少し待ちます。
                time.sleep(0.02)
            # 初回slow responseの送信を完了します。
            return
        # progress assertion向けにsuccess weightをchunk送信します。
        if filename == "model.safetensors":
            # 大きなfixture byte列を小さなchunkに分けます。
            chunk_size = 65_536
            # bodyを順に送ります。
            for offset in range(0, len(body), chunk_size):
                # 現chunkのbyte列を求めます。
                chunk = body[offset : offset + chunk_size]
                # chunkを送信します。
                self.wfile.write(chunk)
                # delegate progressを観測できるようすぐ送ります。
                self.wfile.flush()
                # 合成transferに短い遅れを足してprogressをpoll可能にします。
                time.sleep(0.01)
            # weight file responseを完了します。
            return
        # configとtokenizer fixtureを一括送信します。
        self.wfile.write(body)

# 独立した一時ディレクトリでcompilerとHTTP integration testを実行します。
def main():
    # temporary directoryがtest binaryとdownloaded modelを掃除します。
    with tempfile.TemporaryDirectory(prefix="wealthy-ai-model-fixture-") as temporary_directory:
        # temp pathをPath objectへ変換します。
        temporary_root = Path(temporary_directory)
        # test専用のcompiler module cache directoryを作ります。
        module_cache = temporary_root / "swift-module-cache"
        # harness executable pathを作ります。
        harness_binary = temporary_root / "AIModelDownloadStoreHarness"
        # production store、catalog、fixture harnessを本来のObservation macro込みでcompileします。
        compile_result = subprocess.run(["xcrun", "swiftc", "-module-cache-path", str(module_cache), "-parse-as-library", str(PROJECT_ROOT / "Wealthy/Wealthy/AIModelCatalog.swift"), str(PROJECT_ROOT / "Wealthy/Wealthy/AIModelDownloadStore.swift"), str(PROJECT_ROOT / "Verification/AIModelDownloadStoreHarness.swift"), "-o", str(harness_binary)], cwd=PROJECT_ROOT, text=True, capture_output=True)
        # compilerが成功しなければ診断を表示して試験を止めます。
        if compile_result.returncode != 0:
            # compiler stdoutをそのまま出します。
            sys.stdout.write(compile_result.stdout)
            # compiler stderrをそのまま出します。
            sys.stderr.write(compile_result.stderr)
            # compiler exit statusをPython試験へ返します。
            raise SystemExit(compile_result.returncode)
        # loopback専用のthreaded HTTP fixtureをephemeral portで作ります。
        server = ThreadingHTTPServer(("127.0.0.1", 0), FixtureHandler)
        # server requestを処理するbackground threadを開始します。
        server_thread = Thread(target=server.serve_forever, daemon=True)
        # HTTP fixture serverを起動します。
        server_thread.start()
        # serverが割り当てたlocal portを取得します。
        port = server.server_address[1]
        # ダウンロードに使う専用一時rootを作成します。
        download_root = temporary_root / "download-root"
        # 本体モデルの一時ファイル残留判定を開始前に取ります。
        existing_temp_files = set(Path(tempfile.gettempdir()).glob("wealthy-download-*"))
        # Swift harnessでローカル通信を含む全検証を実行します。
        try:
            # child processの失敗codeを検証結果として伝えます。
            run_result = subprocess.run([str(harness_binary), str(port), str(download_root)], cwd=PROJECT_ROOT, text=True, capture_output=True, timeout=90)
            # harness stdoutとstderrをユーザーへ表示します。
            sys.stdout.write(run_result.stdout)
            # harness error outputを表示します。
            sys.stderr.write(run_result.stderr)
            # 失敗したassertionや通信エラーをPythonへ返します。
            if run_result.returncode != 0:
                # 終了codeでrunnerを失敗させます。
                raise SystemExit(run_result.returncode)
            # cancel、HTTP error、hash failure後に新しい一時download fileを残していないことを確認します。
            remaining_temp_files = set(Path(tempfile.gettempdir()).glob("wealthy-download-*")) - existing_temp_files
            # 一時ファイル残留があれば検証を失敗させます。
            if remaining_temp_files:
                # 残留URL一覧をエラーに含めます。
                raise AssertionError(f"temporary download files remain: {sorted(str(item) for item in remaining_temp_files)}")
        # local fixtureを必ずshutdownしてportを解放します。
        finally:
            # server request loopを止めます。
            server.shutdown()
            # listen socketを閉じます。
            server.server_close()
            # thread終了を短時間待ちます。
            server_thread.join(timeout=2)

# コマンドラインから起動した時だけfixture testを実行します。
if __name__ == "__main__":
    # fixture、Swift compile、assertionを実行します。
    main()
