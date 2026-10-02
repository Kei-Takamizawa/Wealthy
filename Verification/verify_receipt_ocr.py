# このスクリプトをPython 3で実行するための実行環境を指定します。
#!/usr/bin/env python3
# パス操作や一時ディレクトリの機能を読み込みます。
import pathlib
# Git差分の行番号と、日本語の説明文があるかを正規表現で調べる機能を読み込みます。
import re
# swiftcなどの外部コマンドを安全な引数配列で実行する機能を読み込みます。
import subprocess
# 失敗時の終了コードを設定する機能を読み込みます。
import sys
# 一時的なビルド出力先を作る機能を読み込みます。
import tempfile

# このファイルの場所を基準にリポジトリのトップディレクトリを特定します。
ROOT = pathlib.Path(__file__).resolve().parents[1]
# 検証するSwiftのパーサーソースの場所を保持します。
PARSER = ROOT / "Wealthy" / "Wealthy" / "ReceiptTextParser.swift"
# OCRスキャナーのソースの場所を保持します。
SCANNER = ROOT / "Wealthy" / "Wealthy" / "ReceiptScanner.swift"
# Swiftの回帰ケースを記述したmainファイルの場所を保持します。
TEST_MAIN = ROOT / "Verification" / "ReceiptOCR" / "main.swift"
# すべての静的検査と実行検査の失敗数を数えます。
failures = 0

# ソースファイルの各コード行に直前コメントがあるかを確認します。
def check_comment_coverage(path, comment_prefix):
    # 検査対象ファイルをUTF-8で読み込みます。
    lines = path.read_text(encoding="utf-8").splitlines()
    # コメント不足となった物理行番号を保存します。
    uncovered = []
    # ファイルの全行を順番に確認します。
    for index, line in enumerate(lines):
        # 行頭の空白だけを除き、空行とコメント行を判定します。
        stripped = line.lstrip()
        # 空行は対象外にし、コメント行は説明として認めます。
        if not stripped or stripped.startswith(comment_prefix):
            # 空行またはコメント行は次の行へ進みます。
            continue
        # コード行の直前にある物理行を安全に取得します。
        previous = lines[index - 1].lstrip() if index > 0 else ""
        # 直前のコメントに日本語が含まれるかを確認し、空のコメントだけでは合格にしません。
        has_japanese = re.search(r"[\u3040-\u30ff\u3400-\u9fff]", previous) is not None
        # 直前行が同じ言語の日本語コメントでなければ行番号を記録します。
        if not previous.startswith(comment_prefix) or not has_japanese:
            # コメントで説明されていないコード行を一覧へ追加します。
            uncovered.append(index + 1)
    # コメントが欠けていた全ての行番号を呼び出し元へ返します。
    return uncovered

# 検査失敗を数えながら、人が読みやすい短い結果を表示します。
def report(name, succeeded, detail=""):
    # 同じ形式で成功または失敗の状態を表示します。
    print(f"{'PASS' if succeeded else 'FAIL'}: {name}{detail}")
    # 失敗の場合は全体の終了判定用カウンターを増やします。
    if not succeeded:
        # 後続の検査も実行できるよう、失敗数だけを更新します。
        global failures
        # 集計用の失敗数を一つ増やします。
        failures += 1

# Scanner・Parser・Swiftテストの日本語コメント行カバレッジを調べます。
for source in [SCANNER, PARSER, TEST_MAIN]:
    # Swiftのコード行の直前に//コメントがあるかを行番号つきで確認します。
    missing = check_comment_coverage(source, "//")
    # 検査結果を表示し、欠落時は該当する物理行番号も表示します。
    report(f"コメント行カバレッジ {source.relative_to(ROOT)}", not missing, f" uncovered={missing}" if missing else "")

# Python runner自身にも同じコメント行カバレッジ検査を実行します。
runner_path = pathlib.Path(__file__).resolve()
# Pythonコード行の直前に#コメントがあるかを確認します。
runner_missing = check_comment_coverage(runner_path, "#")
# runner自身の検査結果と不足行を表示します。
report("コメント行カバレッジ Verification/verify_receipt_ocr.py", not runner_missing, f" uncovered={runner_missing}" if runner_missing else "")

# 既存の大きなファイルは、今回追加・変更したコード行だけをコメント監査します。
for relative_path in ["Wealthy/Wealthy/DashboardView.swift", "Wealthy/Wealthy/EditExpenseView.swift", "Wealthy/Wealthy/LanguageManager.swift"]:
    # HEADとの差分を読み、既存コード全体を今回の監査対象にしないようにします。
    diff_result = subprocess.run(["git", "diff", "HEAD", "--unified=0", "--", relative_path], cwd=ROOT, capture_output=True, text=True, check=False)
    # 差分を取得できたかを記録し、取得失敗を成功扱いしません。
    report(f"追加行監査用のGit差分 {relative_path}", diff_result.returncode == 0)
    # 追加された新しいコードの物理行番号を保持する集合です。
    added_lines = set()
    # 差分の各まとまりにおける、新しいファイル側の現在の行番号を保持します。
    new_line = 0
    # 差分の見出し・追加・削除を一行ずつ読みます。
    for diff_line in diff_result.stdout.splitlines():
        # 差分の見出しから、新しいファイル側の開始行番号を取り出します。
        hunk = re.match(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@", diff_line)
        # 見出しがある場合は、行番号を新しいまとまりの開始位置へ更新します。
        if hunk:
            # 数字文字列を整数へ変換して、新しいファイルの行番号にします。
            new_line = int(hunk.group(1))
        # ファイル名を表す+++見出しを除き、追加された行を記録します。
        elif new_line and diff_line.startswith("+") and not diff_line.startswith("+++"):
            # 追加された行を、今回のコメント監査対象へ加えます。
            added_lines.add(new_line)
            # 次の追加行に対応する新しいファイル側の行番号へ進みます。
            new_line += 1
        # 削除行と改行状態の注記は、新しいファイル側の行番号を進めません。
        elif new_line and not diff_line.startswith(("-", "\\")):
            # 文脈行など、新しいファイルにも存在する行の分だけ番号を進めます。
            new_line += 1
    # ファイル全体のコメント不足行から、今回追加した行だけを選びます。
    missing_added = sorted(added_lines.intersection(check_comment_coverage(ROOT / relative_path, "//")))
    # 今回の追加コードがすべて日本語で説明されているかを記録します。
    report(f"追加コードの日本語コメント {relative_path}", not missing_added, f" uncovered={missing_added}" if missing_added else "")

# ローカルmacOS実行ファイルとiOS Simulator型検査の一時領域を作ります。
with tempfile.TemporaryDirectory(prefix="wealthy-receipt-ocr-") as temporary_directory:
    # 一時領域のパスをPath型として扱います。
    temporary_path = pathlib.Path(temporary_directory)
    # Swift実行ファイルを一時領域内に配置します。
    executable = temporary_path / "receipt-parser-regression"
    # Swiftモジュールキャッシュも一時領域内に配置します。
    module_cache = temporary_path / "module-cache"
    # macOSネイティブの実行ファイルを作るswiftc引数配列を組み立てます。
    compile_command = ["xcrun", "swiftc", "-module-cache-path", str(module_cache), str(PARSER), str(TEST_MAIN), "-o", str(executable)]
    # parserとmainを一緒にコンパイルし、出力を捕捉して確認可能にします。
    compile_result = subprocess.run(compile_command, capture_output=True, text=True, check=False)
    # macOS実行ファイルが正常にコンパイルできたかを記録します。
    report("macOSパーサー回帰ハーネスのコンパイル", compile_result.returncode == 0)
    # コンパイルに失敗した場合はSwiftの標準エラーを表示します。
    if compile_result.returncode != 0:
        # コンパイラーが示した診断をそのまま出力します。
        print(compile_result.stderr)
    # ビルドできた場合は生成した回帰ハーネスを実行します。
    if compile_result.returncode == 0:
        # XCTestやアプリ起動に依存しないSwift実行結果を取得します。
        execution_result = subprocess.run([str(executable)], capture_output=True, text=True, check=False)
        # 回帰テストが成功したかを実行ファイルの終了コードで判定します。
        report("パーサー抽出ルールの回帰実行", execution_result.returncode == 0)
        # テストの成功・失敗行をユーザーへ表示します。
        print(execution_result.stdout, end="")
        # Swiftの致命的エラーなどがあれば標準エラーも表示します。
        if execution_result.stderr:
            # エラー診断を隠さず表示します。
            print(execution_result.stderr, end="", file=sys.stderr)
    # Xcodeが提供するiPhone Simulator SDKのパスを取得します。
    sdk_result = subprocess.run(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"], capture_output=True, text=True, check=False)
    # SDKパスを出力から取り出し、前後の改行を除きます。
    sdk_path = sdk_result.stdout.strip()
    # SDK確認自体が成功し、想定したSDKディレクトリが得られたか記録します。
    report("iPhone Simulator SDKの検出", sdk_result.returncode == 0 and bool(sdk_path), f" path={sdk_path}" if sdk_path else "")
    # SDKが存在する場合にscannerとparserのiOS型検査を実行します。
    if sdk_result.returncode == 0 and sdk_path:
        # iOS 26 Simulatorのarm64を対象にしたswiftc引数配列を作ります。
        typecheck_command = ["xcrun", "swiftc", "-sdk", sdk_path, "-target", "arm64-apple-ios26.0-simulator", "-module-cache-path", str(module_cache), "-typecheck", str(SCANNER), str(PARSER)]
        # 2つのアプリソースを指定SDKとターゲットで型検査します。
        typecheck_result = subprocess.run(typecheck_command, capture_output=True, text=True, check=False)
        # iOS Simulator向け型検査の終了状態を記録します。
        report("ScannerとParserのiOS 26 arm64 Simulator型検査", typecheck_result.returncode == 0)
        # 型検査時にSwiftが出した診断を標準出力へ表示します。
        if typecheck_result.stdout:
            # 標準出力側の診断を見落とさないよう表示します。
            print(typecheck_result.stdout, end="")
        # 型検査時にSwiftが出した診断を標準エラーへ表示します。
        if typecheck_result.stderr:
            # 標準エラー側の診断を見落とさないよう表示します。
            print(typecheck_result.stderr, end="", file=sys.stderr)

# 検査が一つでも失敗した場合にPython runnerを非ゼロで終了します。
if failures:
    # 集計した失敗数を終了コードとして返します。
    sys.exit(1)
# 全てのコメント検査・回帰実行・型検査が成功した場合の処理です。
else:
    # runner全体が成功したことを明示します。
    print("PASS: all requested verification stages completed")
