---
name: init-devcontainer
description: "devcontainer環境を構築する設定ファイルを生成する。Triggers on: '/init-devcontainer', 'devcontainerを設定', 'devcontainer環境を作って'"
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
| Node.js | `mcr.microsoft.com/devcontainers/base:ubuntu-22.04` | `ghcr.io/devcontainers/features/node:1` |
| Python | `mcr.microsoft.com/devcontainers/python:3.11` | - |
| Go | `mcr.microsoft.com/devcontainers/go:1` | - |
| Rust | `mcr.microsoft.com/devcontainers/rust:1` | - |
| 不明 | `mcr.microsoft.com/devcontainers/base:ubuntu-22.04` | - |

### 3. 設定ファイルの生成

以下のファイルを生成する。

#### `.devcontainer/devcontainer.json`

```json
{
  "name": "{プロジェクト名} Sandbox",
  "image": "{検出したベースイメージ}",
  "features": {
    "ghcr.io/devcontainers/features/git:1": {},
    "{言語に応じた feature}": {}
  },
  "postCreateCommand": "npm install -g @anthropic-ai/claude-code && mkdir -p ~/.claude && cp /workspace/.devcontainer/claude-settings.json ~/.claude/settings.json",
  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
  ],
  "workspaceFolder": "/workspace",
  "remoteEnv": {
    "ANTHROPIC_API_KEY": "${localEnv:ANTHROPIC_API_KEY}"
  }
}
```

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
            "command": "DENYLIST_PATH=/workspace/.devcontainer/denylist.conf /workspace/scripts/block-dangerous.sh"
          }
        ]
      }
    ]
  }
}
```

#### `.devcontainer/denylist.conf`

`scripts/denylist.conf` をコピーし、プロジェクト固有のルールをユーザーが追加できるようコメントを末尾に追加する。

```
# プロジェクト固有のdenyルールをここに追加
# 例: kubectl[[:space:]]+delete[[:space:]]+namespace[[:space:]]+production<TAB>productionネームスペースの削除は実行できません
```

### 4. ネットワーク制御の確認（オプション）

外部ネットワークを遮断したい場合は `.devcontainer/docker-compose.yml` も生成するか確認する。

```yaml
version: '3.8'
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

```
## devcontainer 環境構築 完了

- 生成ファイル:
  - `.devcontainer/devcontainer.json`
  - `.devcontainer/claude-settings.json`
  - `.devcontainer/denylist.conf`

次のステップ:
- VS Code: "Reopen in Container" でコンテナを起動
- CLI: `devcontainer up --workspace-folder . && devcontainer exec --workspace-folder . claude --dangerously-skip-permissions`
- プロジェクト固有のdenyルールは `.devcontainer/denylist.conf` に追記してください
```
