# Media Transfer Tool プロジェクト概要

## プロジェクトの目的
スマートフォンやデジタルカメラで撮影した大量の写真・動画ファイルを効率的に整理・転送するユーティリティソフトウェア。

## 主な機能
- 多様な入力源対応（スマートフォン、デジタルカメラ、SDカード）
- クラウド連携（Dropbox、OneDrive、Amazon S3）
- 重複ファイル検出（ハッシュ値による）
- 柔軟な整理ルール（日付、デバイス、ファイル形式による自動分類）
- 動画特化機能（メタデータ解析と専用整理ルール）
- GUI + CLI両対応

## 技術スタック（検討中）
現在3つのプロトタイプを開発中：
1. **Tauri + React + Rust**（推奨）
2. **Electron + React + Node.js**
3. **Qt + C++**
4. **Flutter Desktop**（新規追加）

## 開発状況
- 初期セットアップ完了
- 要件定義書、開発計画書作成済み
- 技術選定評価実施済み
- Flutter Desktopプロトタイプ作成済み
- 各技術スタックのプロトタイプ開発中

## プロジェクト構造
```
media-transfer-tool/
├── docs/                    # ドキュメント
├── prototypes/             # プロトタイプ
│   ├── tauri-prototype/
│   ├── electron-prototype/
│   ├── qt-prototype/
│   ├── flutter-prototype/
│   └── gui-comparison/
└── memo/                   # 開発履歴
```