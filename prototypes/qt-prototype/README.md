# Media Transfer Tool - Qt Prototype

## 概要
Qt6 + C++で実装されたメディア転送ツールのプロトタイプです。

## 特徴
- **高性能**: ネイティブC++による高速処理
- **クロスプラットフォーム**: Windows、macOS、Linux対応
- **豊富なUI**: Qt Widgetsによる洗練されたインターフェース
- **ドラッグ&ドロップ**: 直感的なファイル選択
- **マルチスレッド**: 応答性の高い処理

## 必要な環境
- Qt6 (6.0以上)
- C++17対応コンパイラ
- CMake 3.16以上

## ビルド手順

### 1. 依存関係のインストール

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install qt6-base-dev qt6-tools-dev cmake build-essential
```

#### macOS (Homebrew)
```bash
brew install qt6 cmake
```

#### Windows (Qt Creator)
1. Qt CreatorをQt公式サイトからダウンロード
2. Qt6.0以上をインストール
3. CMakeをインストール

### 2. ビルド
```bash
mkdir build
cd build
cmake ..
make
```

### 3. 実行
```bash
./media-transfer-qt
```

## 機能

### 実装済み機能
- [x] ファイル選択ダイアログ
- [x] ドラッグ&ドロップ対応
- [x] ファイル一覧表示
- [x] 出力先選択（ローカル、Dropbox、OneDrive、S3）
- [x] 整理ルール設定
- [x] 進捗表示
- [x] マルチスレッド処理

### 設定オプション
- **出力先**: ローカル、Dropbox、OneDrive、Amazon S3
- **整理ルール**: 日付別フォルダ、デバイス別フォルダ、重複検出

## プロトタイプの特徴

### 長所
- **最高のパフォーマンス**: C++による高速処理
- **メモリ効率**: 最適化されたメモリ使用
- **安定性**: 成熟したQtフレームワーク
- **ネイティブ感**: OS統合された外観

### 短所
- **開発コスト**: C++の複雑さ
- **学習コスト**: Qtの習得が必要
- **開発速度**: 他の技術より時間がかかる

## 技術詳細

### アーキテクチャ
- **MainWindow**: メインウィンドウとUI制御
- **FileListWidget**: ファイル一覧表示
- **SettingsWidget**: 設定UI
- **ProcessingThread**: バックグラウンド処理

### 使用技術
- **Qt6 Widgets**: GUI フレームワーク
- **C++17**: プログラミング言語
- **CMake**: ビルドシステム
- **QThread**: マルチスレッド処理

## 拡張可能性
- FFmpegライブラリとの統合
- 高度な画像処理機能
- データベース連携
- プラグインシステム