# Flutter Desktop プロトタイプ

メディア転送ツールのFlutter Desktop実装です。

## 特徴

- **クロスプラットフォーム**: Windows、macOS、Linuxで動作
- **高性能レンダリング**: Skiaエンジンによる60fpsの描画
- **モダンなUI**: Material Design 3準拠
- **状態管理**: Providerパターン
- **アニメーション**: flutter_animateによる滑らかな動き

## 必要な環境

- Flutter SDK 3.0以上
- Dart SDK 3.0以上
- 各OSの開発環境
  - Windows: Visual Studio 2019以上
  - macOS: Xcode 12以上
  - Linux: GTK開発ライブラリ

## セットアップ

```bash
# Flutter Desktopを有効化
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop

# 依存関係のインストール
flutter pub get
```

## 実行方法

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

## ビルド方法

```bash
# リリースビルド（Windows）
flutter build windows --release

# リリースビルド（macOS）
flutter build macos --release

# リリースビルド（Linux）
flutter build linux --release
```

## プロジェクト構造

```
lib/
├── main.dart              # エントリーポイント
├── screens/               # 画面
│   └── home_screen.dart   # メイン画面
├── widgets/               # UIコンポーネント
│   ├── file_selection_card.dart
│   ├── statistics_cards.dart
│   ├── file_list_view.dart
│   └── settings_panel.dart
├── providers/             # 状態管理
│   └── media_provider.dart
├── models/                # データモデル
│   └── media_file.dart
└── themes/                # テーマ設定
    └── app_theme.dart
```

## 実装された機能

1. **ファイル選択**
   - file_pickerによるネイティブダイアログ
   - 複数ファイルの同時選択

2. **ファイル管理**
   - リスト表示
   - ファイルタイプ別のアイコンと色分け
   - 個別削除機能

3. **統計表示**
   - 総ファイル数
   - 画像/動画別カウント
   - アニメーション付きカード

4. **設定オプション**
   - 出力先選択（ローカル/クラウド）
   - 整理ルール（日付別/デバイス別/重複検出）

5. **処理実行**
   - プログレスバー表示
   - 完了通知

## パフォーマンス最適化

- **仮想スクロール**: 大量ファイルに対応（未実装、ListView.builderで基本対応）
- **遅延読み込み**: 必要に応じて実装可能
- **非同期処理**: Futureによる非ブロッキング処理

## 今後の拡張案

1. **サムネイル表示**: photo_managerによる高速サムネイル生成
2. **ドラッグ&ドロップ**: desktop_drop パッケージの追加
3. **実際のファイル処理**: FFIによるネイティブライブラリ連携
4. **クラウド連携**: 各種APIの実装