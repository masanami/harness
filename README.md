# harness

AI駆動開発チームのための汎用ハーネスプラグイン。

Claude Code プラグインとして、任意のリポジトリに横展開できるエージェント・スキル・フックのセットを提供します。

---

## 概要

開発者がAIエージェントチームを統率し、並列開発で生産性を最大化する「AI駆動開発」のためのハーネスです。

- **プロジェクト非依存**: 特定のフレームワークやドメインに依存しない汎用設計
- **CLAUDE.md連携**: プロジェクト固有の設定はCLAUDE.mdに記述するだけで動作
- **Agent Teams対応**: 複数Issueの並列実装をAgent Teamsで実行可能
- **カスタマイズ可能**: エージェント・スキルをプロジェクト側でオーバーライド可能

### 含まれる機能

| カテゴリ | 内容 |
|---------|------|
| エージェント (6) | コードレビュー、設計レビュー、新規実装(TDD)、既存機能変更、ドキュメント整合性検証、E2Eテスト作成 |
| スキル | 自律開発(Lv.0)、並列実装、候補比較実装、候補評価、技術負債チェック、要件定義、プロジェクト初期設定、E2Eテスト実行、PRレビュー対応、リベース、PRマージ、Conventional Commits、PRセルフレビュー、テスト実行、品質ゲートチェック、チケット作成、永続メモリ |
| フック (2) | Write/Edit後の自動フォーマット、危険コマンドブロック |
| ワークフロー定義 (4) | ブランチ戦略、開発フロー、チケット記述ガイド、品質ゲート(Lv.1-3) |

---

## インストール

```bash
# マーケットプレイス経由（Claude Code内で実行）
/plugin marketplace add masanami/harness
/plugin install harness@masanami-harness --scope user

# ローカルのプラグインディレクトリを指定して起動
claude --plugin-dir /path/to/harness
```

> **Note**: `--scope user` を指定すると `.claude/settings.json` に記録され、プロジェクト単位で管理できます。省略するとユーザースコープ（全プロジェクト共通）にインストールされます。

### 更新

```
/plugin
```

プラグイン管理画面から harness を選択し、更新を実行してください。

ローカルディレクトリ指定（`--plugin-dir`）の場合は `git pull` で更新してください。

---

## クイックスタート

1. プラグインをインストール
2. `/init-project` で `CLAUDE.md` を自動生成（エージェントはすべて `CLAUDE.md` 経由でプロジェクト情報を取得します）
3. `/para-impl 123` でIssue #123の実装を開始
4. `/para-impl 123 456 789` で複数Issueを Agent Teams で並列実装
5. `/compare-impl 123 --candidates 3` で3候補を並列実装→比較評価→選定まで一括実行

---

## スキル一覧

### 開発ワークフロー

| スキル | 使い方 | 説明 |
|--------|--------|------|
| `/auto-develop` | `/auto-develop {パス} [--parallel] [--candidates N] [--note "..."]` | 要件から自律的にチケット作成→実装→レビュー対応→マージ（Lv.0） |
| `/para-impl` | `/para-impl {Issue番号...} [-c N]` | Issueを分析→実装→PR作成（複数Issue時はAgent Teams提案、-c Nで候補比較） |
| `/compare-impl` | `/compare-impl {Issue番号} --candidates N` | 単一IssueにN案を並列実装→比較評価→選定→ブラッシュアップ |
| `/evaluate-candidates` | `/evaluate-candidates {ブランチ...} [--issue N] [--auto]` | 候補比較→選定→ブラッシュアップ |
| `/pr-review-respond` | `/pr-review-respond [PR番号]` | PRレビューコメントへの対応 |
| `/pr-merge` | `/pr-merge [PR番号]` | PRのレビューとマージ |
| `/rebase` | `/rebase` | origin/mainへのリベースとコンフリクト解消 |
| `/reduce-debt` | `/reduce-debt {親Issue番号}` | 親Issueの実装範囲を技術負債スキャン→必要に応じて修正Issue起票 |

### テスト・品質

| スキル | 使い方 | 説明 |
|--------|--------|------|
| `/run-e2e` | `/run-e2e [ファイル名]` | E2Eテストの実行と結果分析 |
| `/test` | `/test [ファイル]` | テスト実行と結果分析 |
| `/quality-check` | `/quality-check` | lint + typecheck + test の一括実行 |
| `/self-review` | `/self-review` | コード変更のセルフレビュー |

### ユーティリティ

| スキル | 使い方 | 説明 |
|--------|--------|------|
| `/commit` | `/commit` | Conventional Commits形式でコミット |
| `/create-ticket` | `/create-ticket` | GitHub Issueとしてチケット作成 |
| `/define-requirements` | `/define-requirements [テーマ]` | ユーザーとの対話から要件定義ドキュメント＋Issue作成 |
| `/init-project` | `/init-project` | プロジェクトを分析してCLAUDE.mdを自動生成 |

---

## ドキュメント

本プラグインは [AI駆動開発戦略](docs/ai-driven-development-strategy.md) と [開発フロー](docs/workflows/development-flow.md) を前提に設計されています。導入前にこれらのドキュメントを確認してください。

### 戦略・ワークフロー

- [AI駆動開発戦略](docs/ai-driven-development-strategy.md) — チーム体制、オーナーシップモデル、フェーズ別レビュー負荷、品質保証フロー
- [開発フロー](docs/workflows/development-flow.md) — 要件定義→設計→実装→レビュー→マージの全体フロー
- [ブランチ戦略](docs/workflows/branching-strategy.md) — GitHub Flow、Conventional Commits、マージ規約
- [チケット記述ガイドライン](docs/workflows/ticket-writing.md) — AIエージェント向けチケットの書き方
- [品質ゲート定義](docs/workflows/quality-gates.md) — 品質保証レベル(Lv.1-3)、品質ゲート、クリティカル箇所の定義

### ガイド

- [セットアップガイド](docs/guides/getting-started.md) — インストールからCLAUDE.md整備、動作確認まで
- [カスタマイズ方法](docs/guides/customization.md) — エージェント/スキルのオーバーライド、フック追加

---

## Codex CLI サポート

harness は Claude Code に加えて [Codex CLI](https://github.com/openai/codex) にも対応しています。`codex/` ディレクトリに Codex CLI 用のエージェント・スキル・設定ファイルが格納されています。

### セットアップ手順

```bash
# harness リポジトリから Codex 用ファイルをプロジェクトにセットアップ
./scripts/setup-codex.sh /path/to/your-project

# セットアップ後
# 1. AGENTS.md のプレースホルダーをプロジェクトに合わせて記入
# 2. .codex/config.toml を必要に応じて調整
# 3. codex コマンドで動作確認
```

### スキル呼び出し対応表

| スキル | Claude Code | Codex CLI |
|--------|------------|-----------|
| 自律開発 | `/auto-develop` | `$auto-develop` |
| 並列実装 | `/para-impl` | `$para-impl` |
| 候補評価 | `/evaluate-candidates` | `$evaluate-candidates` |
| PRレビュー対応 | `/pr-review-respond` | `$pr-review-respond` |
| PRマージ | `/pr-merge` | `$pr-merge` |
| リベース | `/rebase` | `$rebase` |
| E2Eテスト実行 | `/run-e2e` | `$run-e2e` |
| テスト実行 | `/test` | `$test` |
| 品質チェック | `/quality-check` | `$quality-check` |
| セルフレビュー | `/self-review` | `$self-review` |
| コミット | `/commit` | `$commit` |
| チケット作成 | `/create-ticket` | `$create-ticket` |
| 要件定義 | `/define-requirements` | `$define-requirements` |
| プロジェクト初期設定 | `/init-project` | `$init-project` |
| 永続メモリ | `/agent-memory` | `$agent-memory` |

### セットアップ後のディレクトリ構成

```
your-project/
├── AGENTS.md                          # プロジェクトコンテキスト（CLAUDE.md相当）
├── .codex/
│   ├── config.toml                    # Codex プロジェクト設定
│   └── agents/
│       ├── code-reviewer.toml
│       ├── design-reviewer.toml
│       ├── implement-feature.toml
│       ├── modify-feature.toml
│       └── doc-verifier.toml
└── .agents/
    └── skills/
        ├── auto-develop/SKILL.md
        ├── para-impl/SKILL.md
        ├── compare-impl/SKILL.md
        ├── evaluate-candidates/SKILL.md
        ├── reduce-debt/SKILL.md
        ├── self-review/SKILL.md
        ├── run-e2e/SKILL.md
        ├── pr-review-respond/SKILL.md
        ├── rebase/SKILL.md
        ├── pr-merge/SKILL.md
        ├── commit/SKILL.md
        ├── test/SKILL.md
        ├── quality-check/SKILL.md
        ├── create-ticket/
        │   ├── SKILL.md
        │   └── templates/
        ├── define-requirements/
        │   ├── SKILL.md
        │   └── templates/
        │       └── requirements-doc.md
        ├── init-project/
        │   └── SKILL.md
        └── agent-memory/SKILL.md
```

### プラットフォーム差異

| 要素 | Claude Code | Codex CLI |
|------|------------|-----------|
| コンテキストファイル | `CLAUDE.md` | `AGENTS.md` |
| エージェント定義 | `agents/*.md`（YAML フロントマター） | `.codex/agents/*.toml`（TOML） |
| スキル呼び出し | `/skill-name` | `$skill-name` |
| ツール制限 | フロントマター `tools:` | `sandbox_mode`（read-only / workspace-write） |
| メモリパス | `.claude/skills/agent-memory/memories/` | `.agents/skills/agent-memory/memories/` |

---

## 設計思想

### エージェントのオーバーライド

プロジェクト側で `.claude/agents/{agent-name}.md` を配置すると、プラグインの同名エージェントを上書きできます。プロジェクト固有の観点を追加したい場合や、不要な観点を省きたい場合に利用してください。

---

## 横展開手順

新規プロジェクトにharnessを導入する手順:

1. プラグインをインストール
2. `/init-project` で `CLAUDE.md` を自動生成
3. 必要に応じてエージェントをオーバーライド（`.claude/agents/` に配置）
4. `/para-impl` でIssue実装を開始
