---
name: init-project
description: "プロジェクトを分析してAGENTS.mdを自動生成する。Triggers on: '$init-project', 'プロジェクト初期設定', 'AGENTS.mdを作成'"
---

# プロジェクト初期設定

プロジェクトを自動分析し、`AGENTS.md` を生成します。

---

## 手順

### 1. 既存AGENTS.mdの確認

プロジェクトルートに `AGENTS.md` が既に存在するか確認する。

- **存在する場合**: ユーザーに上書き・マージ・中止を確認する
- **存在しない場合**: そのまま続行

### 2. プロジェクト自動分析

以下のファイル・ディレクトリを調査し、プロジェクト情報を検出する。

#### 2a. パッケージマネージャ & 言語の検出

ロックファイル・設定ファイルから判定:

| ファイル | 判定結果 |
|---------|---------|
| `package-lock.json` | npm |
| `yarn.lock` | yarn |
| `pnpm-lock.yaml` | pnpm |
| `bun.lockb` | bun |
| `Cargo.toml` | Rust/cargo |
| `go.mod` | Go |
| `pyproject.toml` / `requirements.txt` | Python |
| `Gemfile` | Ruby |

#### 2b. 技術スタックの検出

| 検出対象 | 検出元 |
|---------|--------|
| Frontend | `package.json` の dependencies（react, vue, next, nuxt, svelte 等） |
| Backend | `package.json`（express, fastify, nest 等）、`go.mod`、`Cargo.toml` |
| DB | `prisma/`, `drizzle.config.*`, `package.json`（typeorm, sequelize 等） |
| Test | `jest.config.*`, `vitest.config.*`, `playwright.config.*`, `pytest.ini` 等 |
| Infra | `Dockerfile`, `docker-compose.yml`, `terraform/`, `.github/workflows/` |

#### 2c. コマンドの検出

`package.json` の `scripts` セクション（Node.js系）または同等の設定から:

- テスト: `test`, `test:unit`, `test:e2e`
- リント: `lint`, `lint:fix`
- 型チェック: `typecheck`, `type-check`, `tsc`
- フォーマット: `format`, `fmt`
- ビルド: `build`, `dev`, `start`

Node.js以外のプロジェクトの場合:
- Python: `pytest`, `ruff`, `mypy`, `black` 等の設定ファイルから推定
- Rust: `cargo test`, `cargo clippy`, `cargo fmt`
- Go: `go test`, `golangci-lint`

#### 2d. ディレクトリ構成のスキャン

プロジェクトルートからの主要ディレクトリ構造（深さ2-3）を取得する。以下は除外:
- `.git`, `node_modules`, `dist`, `.next`, `target`, `__pycache__`, `.venv`, `vendor`

#### 2e. ドキュメント・テスト配置の検出

- ドキュメント: `docs/` 配下の構造
- テスト: `__tests__/`, `test/`, `tests/`, `spec/`, `*.test.*`, `*.spec.*` のパターン
- E2Eテスト: `e2e/`, `playwright/`, `cypress/`

#### 2f. プロジェクト名の検出

以下の優先順位で検出:
1. `package.json` の `name`
2. `Cargo.toml` の `[package] name`
3. `pyproject.toml` の `[project] name`
4. `go.mod` の module名
5. プロジェクトルートのディレクトリ名

### 3. 検出結果の提示と補完

検出結果をまとめてユーザーに提示し、以下を確認・補完する:

```
## 検出結果

- プロジェクト名: {detected_name}
- パッケージマネージャ: {detected_pm}
- 技術スタック: {detected_stack}
- テストコマンド: {detected_test_cmd}
- リントコマンド: {detected_lint_cmd}
- 型チェック: {detected_typecheck_cmd}
- ディレクトリ構成: （略）

上記の内容で正しいですか？修正があれば指摘してください。
また、以下の情報を教えてください:

1. プロジェクトの概要（1-2文）
2. 追加の開発原則（あれば。YAGNI/KISS/DRYはデフォルトで含まれます）
3. 品質レベル（Lv.1: 最低限 / Lv.2: 標準 / Lv.3: 厳格）
```

> **ポイント**: 検出結果をそのまま提案し、ユーザーは修正したい箇所だけ指摘すればよい形にする。全項目の逐一確認は避ける。

### 4. テンプレート読み込み & AGENTS.md 生成

本スキルの `templates/AGENTS.md.template` を読み込み、検出結果とユーザー入力でプレースホルダーを埋めて `AGENTS.md` を生成する。

生成ルール:
- 検出できなかったセクションは適切なデフォルト値またはコメント付きプレースホルダー（`<!-- TODO: ... -->`）を残す
- 該当しないレイヤー（例: フロントエンドのないバックエンドプロジェクト）は「-」と記入
- コマンドセクションは検出結果から具体的なコマンドを記入する
- 品質ゲートは選択されたレベルに応じて `docs/workflows/quality-gates.md` を参照して記入する
- ディレクトリ構成は実際のスキャン結果を記入する

### 5. 完了報告

```
## プロジェクト初期設定 完了

- 生成ファイル: `AGENTS.md`

次のステップ:
- `AGENTS.md` の内容を確認し、必要に応じて手動で調整してください
- 要件定義を開始するには: $define-requirements [テーマ]
- チケットを作成するには: $create-ticket
```
