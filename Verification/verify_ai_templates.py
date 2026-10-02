# コマンドライン引数を扱う標準機能を読み込みます。
import argparse
# パス操作と一時ファイルの準備を行う機能を読み込みます。
import pathlib
# ソースの説明コメントと固定配布情報を確認する機能を読み込みます。
import re
# Swiftの検証処理を引数配列で安全に実行する機能を読み込みます。
import subprocess
# 一時的な検証用パッケージを作成する機能を読み込みます。
import tempfile
# 大きな重みを取得せず、固定revisionの小さなテンプレートだけを取得します。
import urllib.request

# この検証スクリプトからリポジトリの位置を特定します。
ROOT = pathlib.Path(__file__).resolve().parents[1]
# 検証に使う依存パッケージと設定資材の指定を受け取ります。
parser = argparse.ArgumentParser()
# Xcodeが取得済みのチェックアウトを指定する引数を用意します。
parser.add_argument("--checkouts", type=pathlib.Path, required=True)
# 取得済みテンプレートを再利用する場合だけ指定する引数です。
parser.add_argument("--assets", type=pathlib.Path)
# 引数を解析します。
arguments = parser.parse_args()
# 本番カタログから固定されたリポジトリ名とrevisionを取り出します。
catalog = (ROOT / "Wealthy/Wealthy/AIModelCatalog.swift").read_text()
# 新モデルの配布先と40桁のrevisionを正規表現で抽出します。
repositories = re.findall(r'repoId: "([^"]+)", revision: "([a-f0-9]{40})"', catalog)
# MLXモデル四つ以外が含まれていたら検証を停止します。
assert len(repositories) == 4, "Expected four pinned MLX repositories"
# 実行後に削除する検証用ディレクトリを作ります。
with tempfile.TemporaryDirectory(prefix="wealthy-ai-templates-") as temporary:
    # 一時領域をPathとして扱います。
    package = pathlib.Path(temporary)
    # 指定済み資材か一時取得先を、テンプレートの置き場所にします。
    assets = arguments.assets or package / "assets"
    # 取得先のディレクトリを用意します。
    assets.mkdir(parents=True, exist_ok=True)
    # 四つのモデルについて固定revisionのテンプレートを用意します。
    for repository, revision in repositories:
        # 実行用ハーネスが参照する取得先の名前を作ります。
        destination = assets / (repository.replace("/", "--") + ".jinja")
        # 再利用指定がない場合だけ、公開テンプレートを取得します。
        if arguments.assets is None:
            # 取得するのは重みではなく、固定版の小さな文字列ファイルです。
            url = f"https://huggingface.co/{repository}/resolve/{revision}/chat_template.jinja"
            # ネットワーク停止時に永久待機しないよう60秒の上限を設定します。
            with urllib.request.urlopen(url, timeout=60) as response:
                # テンプレート文字列を一時領域へ保存します。
                destination.write_bytes(response.read())
        # 資材が実際に存在することを確認します。
        assert destination.is_file(), f"Missing template: {destination}"
    # 一時パッケージのソースルートを用意します。
    sources = package / "Sources"
    # ソースディレクトリを作ります。
    sources.mkdir()
    # 本番で使うSwift Jinjaのソースをそのまま参照します。
    (sources / "Jinja").symlink_to(arguments.checkouts.resolve() / "swift-jinja/Sources/Jinja", target_is_directory=True)
    # コマンドライン検証のソースを一時パッケージへ参照させます。
    (sources / "Checks").symlink_to(ROOT / "Verification/AIModels", target_is_directory=True)
    # Swift Collectionsだけは取得済みのローカル依存を使い、再解決の通信を避けます。
    collections = str(arguments.checkouts.resolve() / "swift-collections").replace("\\", "\\\\").replace('"', '\\"')
    # Swift manifestの全コード行へ日本語の説明を付けて生成します。
    manifest = ["// swift-tools-version: 6.0", "// Swiftパッケージの構成機能を読み込みます。", "import PackageDescription", "// 取得済み依存だけでテンプレート検査用の実行ファイルを構成します。", 'let package = Package(name: "AIChatTemplateChecks", platforms: [.macOS(.v13)], dependencies: [.package(path: "' + collections + '")], targets: [.target(name: "Jinja", dependencies: [.product(name: "OrderedCollections", package: "swift-collections")]), .executableTarget(name: "Checks", dependencies: ["Jinja"], sources: ["ChatTemplateChecks.swift"])])']
    # 生成manifestをUTF-8で保存します。
    (package / "Package.swift").write_text("\n".join(manifest) + "\n", encoding="utf-8")
    # 本番のJinjaをコンパイルし、四モデル・二会話の実テンプレートを評価します。
    subprocess.run(["swift", "run", "--package-path", str(package), "Checks", str(assets.resolve())], check=True)
