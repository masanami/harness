# harness-eval テスト用プロジェクト

harness スキルの評価シナリオを実行するためのテスト用リポジトリです。

## プロジェクト概要

Node.js 製のユーティリティライブラリ。harness の評価目的で使用します。

## コーディング規約

- **インデント**: スペース2つ（タブ禁止）
- **命名規則**: 関数名・変数名は camelCase
- **セキュリティ**: APIキー・パスワードのハードコード禁止。必ず環境変数（`process.env`）を使用すること
- **コメント**: コードの意図が自明でない場合のみ記述
- **モジュール**: CommonJS（`require` / `module.exports`）を使用

## ディレクトリ構成

```text
src/       プロダクションコード
tests/     テストコード（Jest）
```

## よく使うコマンド

- lint: `npx eslint src/`
- test: `npx jest`
- lint + test: `npx eslint src/ && npx jest`

## 依存関係

- テストフレームワーク: Jest
- リンター: ESLint
