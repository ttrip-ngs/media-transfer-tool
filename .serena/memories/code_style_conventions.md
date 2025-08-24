# コーディングスタイル・規約

## 全般
- 日本語でのコメント・コミットメッセージ推奨
- 技術文章に絵文字は使用しない（READMEのみ例外）
- コードには必要最小限のコメントのみ追加
- DRY、KISS、YAGNI原則の遵守

## Flutter/Dart（プロトタイプ）
- Material Design 3準拠
- Provider for 状態管理
- ファイル構成：
  - lib/main.dart: エントリーポイント
  - lib/screens/: 画面コンポーネント
  - lib/widgets/: UIコンポーネント
  - lib/providers/: 状態管理
  - lib/models/: データモデル
  - lib/themes/: テーマ設定

## JavaScript/TypeScript（今後の実装）
- ESLint + Prettier設定
- React + TypeScript使用時はfunctional components推奨
- 型定義必須

## Rust（Tauriバックエンド）
- rustfmt使用
- エラーハンドリングはResult型使用
- unsafe最小限

## ファイル命名規則
- Flutter/Dart: snake_case.dart
- TypeScript/JavaScript: camelCase.ts/js
- Rust: snake_case.rs
- ドキュメント: kebab-case.md

## Git規約
- コミットメッセージ：日本語で具体的に
- ブランチ名：feature/機能名（日本語OK）
- PR：実装内容と動作確認結果を記載

## セキュリティ
- シークレット・キーのハードコーディング禁止
- 環境変数で管理
- gitleaksによる自動チェック実施