# 技術選定決定書

## 決定事項

### 採用技術: Flutter Desktop

2025年1月13日、メディア転送ツールの開発技術として **Flutter Desktop** を採用することを決定しました。

## 選定理由

### 1. Lightroomライクな高品質UIの実現
- **Material Design 3** による洗練されたUI
- **アニメーション機能** が豊富で滑らかな操作感
- **ダークモード対応** が容易
- **グリッドビュー、リストビュー** などメディア管理に必要なUIコンポーネントが充実

### 2. 開発効率の高さ
- **Hot Reload** による高速開発
- **単一コードベース** でWindows/macOS/Linux対応
- **豊富なウィジェット** により短期間でプロトタイプ作成可能
- **Dart言語** の学習コストが比較的低い

### 3. パフォーマンス
- **Skiaエンジン** による60fps描画
- **ネイティブコンパイル** による高速動作
- **Isolate** による並列処理でUI非ブロッキング

### 4. メディア処理能力
- **file_picker** によるネイティブファイル選択
- **photo_manager** でメディアファイル管理
- **FFI (Foreign Function Interface)** でネイティブライブラリ連携可能
- **image** パッケージによる画像処理

## 技術スタック詳細

### コア技術
```yaml
フレームワーク: Flutter 3.0+
言語: Dart 3.0+
状態管理: Provider / Riverpod
UIテーマ: Material Design 3
```

### 主要パッケージ
```yaml
# UI/UX
google_fonts: 日本語フォント対応
flutter_animate: アニメーション
window_manager: ウィンドウ制御

# ファイル操作
file_picker: ファイル選択
path_provider: パスアクセス
desktop_drop: ドラッグ&ドロップ

# メディア処理
photo_manager: メディア管理
image: 画像処理
video_player: 動画プレビュー
flutter_image_compress: 画像圧縮

# データ管理
sqflite: ローカルDB
shared_preferences: 設定保存
hive: 高速KVストア

# ネットワーク
dio: HTTP通信
flutter_secure_storage: 認証情報保存
```

### アーキテクチャ
```
lib/
├── main.dart                 # エントリーポイント
├── core/                     # コア機能
│   ├── models/              # データモデル
│   ├── services/            # ビジネスロジック
│   └── repositories/        # データアクセス
├── features/                 # 機能別モジュール
│   ├── import/              # インポート機能
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── providers/
│   ├── organize/            # 整理機能
│   ├── transfer/            # 転送機能
│   └── settings/            # 設定
├── shared/                   # 共通コンポーネント
│   ├── widgets/
│   ├── themes/
│   └── utils/
└── native/                   # ネイティブ連携
    └── ffi/                 # FFmpeg等の連携
```

## 開発方針

### フェーズ1: 基本機能実装（2週間）
- デバイス検出とファイル一覧表示
- サムネイル生成とグリッド表示
- 基本的なファイル整理機能
- ローカルへのコピー/移動

### フェーズ2: 高度な機能（2週間）
- メタデータ編集
- 重複検出
- バッチ処理
- プリセット管理

### フェーズ3: クラウド連携（1週間）
- Dropbox/OneDrive/Google Drive連携
- 自動同期機能

## リスクと対策

### リスク
1. **デスクトップ向けパッケージの成熟度**
   - 対策: 不足機能はFFIでネイティブ実装

2. **大容量ファイル処理**
   - 対策: Isolateによる並列処理、ストリーミング処理

3. **プラットフォーム固有機能**
   - 対策: Platform Channelsでネイティブコード呼び出し

## 他候補との比較

| 項目 | Flutter | Tauri | Electron | Qt |
|------|---------|-------|----------|-----|
| UI開発速度 | ◎ | ○ | ◎ | △ |
| パフォーマンス | ◎ | ◎ | △ | ◎ |
| メモリ使用量 | ○ | ◎ | × | ○ |
| 学習コスト | ○ | △ | ◎ | × |
| エコシステム | ○ | △ | ◎ | ○ |
| Lightroomライク UI | ◎ | ○ | ○ | ○ |

## 結論

Flutter Desktopは、Lightroomのような高品質なメディア管理UIを効率的に開発でき、十分なパフォーマンスも期待できるため、本プロジェクトに最適な技術として採用を決定しました。