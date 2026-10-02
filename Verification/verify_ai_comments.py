# 検証対象のファイルを探す標準機能を読み込みます。
import pathlib
# 日本語の有無とGit差分の行番号を調べる機能を読み込みます。
import re
# Gitから追加行だけを読み取る機能を読み込みます。
import subprocess

# このファイルからリポジトリのルートを特定します。
ROOT = pathlib.Path(__file__).resolve().parents[1]
# AIモデル対応で全面作成・置換したアプリソースを列挙します。
sources = [ROOT / "Wealthy/Wealthy" / name for name in ["AIModelCatalog.swift", "AIModelDownloadStore.swift", "LocalLLMService.swift", "ModelSettingsView.swift", "K2HorizonModel.swift", "BonsaiModelSupport.swift"]]
# 検証用コードにも、各行の日本語解説が必要です。
sources += sorted(path for path in (ROOT / "Verification").rglob("*") if path.suffix in {".swift", ".py", ".sh"})
# 説明不足の行をファイル名と一緒に保持します。
missing = []
# 監査したコード行数を集計します。
code_count = 0
# 新規・全面置換した各ファイルを確認します。
for source in sources:
    # 言語に合った一行コメントの記号を選びます。
    prefix = "//" if source.suffix == ".swift" else "#"
    # UTF-8で全行を読み取ります。
    lines = source.read_text(encoding="utf-8").splitlines()
    # 空行とコメントを除く全コード行を調べます。
    for index, line in enumerate(lines):
        # 行頭の空白を取り除きます。
        stripped = line.lstrip()
        # 空行とコメント行はコードとして数えません。
        if not stripped or stripped.startswith(prefix):
            # 次の物理行へ進みます。
            continue
        # コメント監査したコード行数を増やします。
        code_count += 1
        # コード行の直前の行を、安全に取得します。
        previous = lines[index - 1].lstrip() if index else ""
        # 直前の同じ言語のコメントに日本語説明が必要です。
        if not previous.startswith(prefix) or not re.search(r"[\u3040-\u30ff\u3400-\u9fff]", previous):
            # 説明が不足した具体的な位置を記録します。
            missing.append(f"{source.relative_to(ROOT)}:{index + 1}")
# 既存の画面では今回追加したコード行だけを確認します。
for relative in ["Wealthy/Wealthy/ContentView.swift", "Wealthy/Wealthy/DashboardView.swift", "Wealthy/Wealthy/EditExpenseView.swift", "Wealthy/Wealthy/LanguageManager.swift"]:
    # HEADとの文脈なし差分を、引数配列で取得します。
    diff = subprocess.run(["git", "diff", "HEAD", "--unified=0", "--", relative], cwd=ROOT, text=True, capture_output=True, check=True).stdout
    # 追加行の位置を参照できるよう実ソースを読み取ります。
    lines = (ROOT / relative).read_text().splitlines()
    # 現在の差分まとまり内の新ソース側行番号を保持します。
    position = 0
    # 差分の行を順番に確認します。
    for line in diff.splitlines():
        # 新ソース側の開始位置を差分見出しから取り出します。
        hunk = re.match(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@", line)
        # 見出しの場合は、現在位置を更新します。
        if hunk:
            # 差分の開始行を整数にします。
            position = int(hunk.group(1))
        # ファイル見出しを除いた、追加コードを判定します。
        elif position and line.startswith("+") and not line.startswith("+++"):
            # コメントや空行を除き、実際のコードだけを監査します。
            if line[1:].strip() and not line[1:].lstrip().startswith("//"):
                # 追加コード行も監査件数へ数えます。
                code_count += 1
                # 実ソース上の直前の行を取得します。
                previous = lines[position - 2].lstrip() if position > 1 else ""
                # 直前に日本語解説がなければ具体的な位置を記録します。
                if not previous.startswith("//") or not re.search(r"[\u3040-\u30ff\u3400-\u9fff]", previous):
                    # 説明不足を、最終判定へ追加します。
                    missing.append(f"{relative}:{position}")
            # 次の追加行に備えて新ソース側の位置を進めます。
            position += 1
        # 削除行と改行注記以外は、新ソース側に一行存在します。
        elif position and not line.startswith(("-", "\\")):
            # 文脈行を読み取った分だけ位置を進めます。
            position += 1
# 説明不足を具体的な一覧で報告し、見落としたまま成功にしません。
assert not missing, "Missing Japanese comments: " + ", ".join(missing)
# 全ての対象コード行に説明があることを件数と一緒に示します。
print(f"PASS: {code_count} code lines audited; zero missing Japanese comments")
