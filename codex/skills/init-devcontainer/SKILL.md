---
name: init-devcontainer
description: "devcontainer環境を構築する設定ファイルを生成する。Triggers on: '$init-devcontainer', '/init-devcontainer', 'devcontainerを設定', 'devcontainer環境を作って'"
---

# devcontainer 環境構築

プロジェクトを分析し、Claude Code をサンドボックス環境で安全に実行するための devcontainer 設定ファイルを生成します。

---

## 手順

### 1. 既存設定の確認

`.devcontainer/` ディレクトリが既に存在する場合はユーザーに上書き・マージ・中止を確認する。

### 2. プロジェクト情報の検出

言語・パッケージマネージャを検出し、適切なベースイメージと features を決定する。

| 検出結果 | ベースイメージ | 追加 features |
|---------|-------------|--------------|
| Node.js | `mcr.microsoft.com/devcontainers/base` | `ghcr.io/devcontainers/features/node` |
| Python | `mcr.microsoft.com/devcontainers/python` | - |
| Go | `mcr.microsoft.com/devcontainers/go` | - |
| Rust | `mcr.microsoft.com/devcontainers/rust` | - |
| 不明 | `mcr.microsoft.com/devcontainers/base` | - |

さらに、以下を確認してプロジェクトのパッケージ管理外でインストールが必要なシステムツールを探索する。

- `README.md` のセットアップ手順
- `Makefile` / `scripts/` 内のセットアップ系スクリプト
- `.github/workflows/` のCI設定（`apt install`、`brew install`、`curl ... | sh` などのパターン）
- `docs/` 内のセットアップガイド

検出したツールは `postCreateCommand` でのインストールコマンドに含める。

### 3. 設定ファイルの生成

以下のファイルを生成する。

#### `.devcontainer/devcontainer.json`

以下の要件を満たす内容で生成する。最新の devcontainer 仕様に従い、実際のスキーマに合わせて適切なフォーマットで記述すること。

| 設定項目 | 内容 |
|---------|------|
| コンテナ名 | `{プロジェクト名} Sandbox` |
| ベースイメージ | 手順2で検出したイメージ |
| features | git、および言語に応じた feature |
| postCreateCommand | Claude Code のインストール + `/workspace/.devcontainer/claude-settings.json` を `~/.claude/settings.json` にコピー + 手順2で検出したシステムツールのインストール |
| マウント | ローカルワークスペースを `/workspace` にバインド |
| workspaceFolder | `/workspace` |
| 環境変数 | `ANTHROPIC_API_KEY` をローカル環境から引き継ぐ |

#### `.devcontainer/claude-settings.json`

`block-dangerous.sh` の PreToolUse フックを設定する。

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/bin/sh -c 'DENYLIST_PATH=/workspace/.devcontainer/denylist.conf /workspace/scripts/block-dangerous.sh'"
          }
        ]
      }
    ]
  }
}
```

#### `scripts/block-dangerous.sh`

ハーネスの `scripts/block-dangerous.sh` をプロジェクトにコピーし、実行権限を付与する。
これはコンテナ内のフック（`/workspace/scripts/block-dangerous.sh`）から参照される。

#### `.devcontainer/denylist.conf`

`scripts/denylist.conf` をコピーし、プロジェクト固有のルールをユーザーが追加できるようコメントを末尾に追加する。

```conf
# プロジェクト固有のdenyルールをここに追加
# 例（パターンとメッセージはタブ文字で区切る）:
# kubectl[[:space:]]+delete[[:space:]]+namespace[[:space:]]+production	productionネームスペースの削除は実行できません
```

### 4. ネットワーク制御の確認（オプション）

外部ネットワークを遮断したい場合は `.devcontainer/docker-compose.yml` も生成するか確認する。

```yaml
services:
  sandbox:
    image: {ベースイメージ}
    volumes:
      - ../:/workspace:cached
    networks:
      - sandbox-net

networks:
  sandbox-net:
    driver: bridge
    internal: true
```

> **注意**: `internal: true` は外部通信を全て遮断する。`postCreateCommand` でのパッケージインストールが失敗するため、必要なものは事前にイメージに含めること。

### 5. 完了報告

```text
## devcontainer 環境構築 完了

- 生成ファイル:
  - `scripts/block-dangerous.sh`
  - `.devcontainer/devcontainer.json`
  - `.devcontainer/claude-settings.json`
  - `.devcontainer/denylist.conf`

次のステップ:
- VS Code: "Reopen in Container" でコンテナを起動
- CLI: `devcontainer up --workspace-folder . && devcontainer exec --workspace-folder . codex --dangerously-bypass-approvals-and-sandbox`
- プロジェクト固有のdenyルールは `.devcontainer/denylist.conf` に追記してください
- denyリストによる安全な運用については [セーフティガイド](../../docs/auto-mode-safety.md) を参照
```
