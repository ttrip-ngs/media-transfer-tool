# Media Transfer Tool - 推奨コマンド一覧

## Git操作
```bash
# ブランチ操作
git checkout dev                    # devブランチに切り替え
git checkout -b feature/機能名       # 新規機能ブランチ作成
git pull origin dev                 # 最新のdevブランチを取得
git push -u origin feature/機能名    # ブランチをリモートにプッシュ

# 基本操作
git status                          # 現在の状態確認
git diff                           # 変更内容確認
git add .                          # すべての変更をステージング
git commit -m "メッセージ"          # コミット（pre-commit自動実行）
git log --oneline -10              # 最近のコミット履歴表示
```

## Windows環境でのファイル操作
```bash
# ディレクトリ操作
dir                                # ファイル一覧表示
cd フォルダ名                       # ディレクトリ移動
mkdir フォルダ名                    # ディレクトリ作成

# PowerShellコマンド
Get-ChildItem                      # ファイル一覧（ls相当）
Get-Content ファイル名              # ファイル内容表示（cat相当）
Select-String "パターン" ファイル名  # ファイル内検索（grep相当）
```

## Flutter開発（プロトタイプ）
```bash
# Flutter基本コマンド
flutter doctor                     # 環境確認
flutter pub get                    # 依存関係インストール
flutter run -d windows             # Windows版実行
flutter run -d macos              # macOS版実行
flutter run -d linux              # Linux版実行
flutter build windows             # Windows版ビルド
flutter analyze                   # 静的解析
flutter test                      # テスト実行
```

## 品質チェック
```bash
# pre-commit
pre-commit install                # フック設定
pre-commit run --all-files        # 全ファイルチェック

# セキュリティチェック
gitleaks detect                   # シークレットスキャン
```

## プロジェクトナビゲーション
```bash
# 主要ディレクトリへの移動
cd docs                           # ドキュメント
cd prototypes                     # プロトタイプ
cd prototypes/flutter-prototype   # Flutterプロトタイプ
cd memo/history                   # 開発履歴
```