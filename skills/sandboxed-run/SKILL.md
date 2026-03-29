# sandboxed-run スキル

## 概要

devcontainer 環境で Claude Code を安全に実行するためのサンドボックス実行スキルです。`--dangerously-skip-permissions` を使った自律実行を、コンテナの隔離環境で安全に行えるようにします。

このスキルはオプションです。devcontainer を使用するプロジェクト向けに、即座に利用できるセットアップ手順と設定例を提供します。

---

## なぜdevcontainerか

| 課題 | devcontainerによる解決 |
|------|----------------------|
| ホストOS への意図しない変更 | コンテナ内に変更が封じ込められる |
| 本番環境への誤操作 | ネットワーク制御でアクセスを制限可能 |
| 依存関係の汚染 | コンテナ内の独立した環境で実行 |
| チームメンバー間の環境差異 | 同一コンテナイメージで統一された環境 |

---

## セットアップ手順

### 1. devcontainer の設定ファイルを作成

プロジェクトルートに `.devcontainer/devcontainer.json` を作成します。

```json
{
  "name": "Claude Code Sandbox",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu-22.04",
  "features": {
    "ghcr.io/devcontainers/features/git:1": {},
    "ghcr.io/devcontainers/features/node:1": {
      "version": "lts"
    }
  },
  "postCreateCommand": "npm install -g @anthropic-ai/claude-code",
  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
  ],
  "workspaceFolder": "/workspace",
  "remoteEnv": {
    "ANTHROPIC_API_KEY": "${localEnv:ANTHROPIC_API_KEY}"
  }
}
```

### 2. denyリストをプロジェクトに配置

```bash
# harness の denylist.conf をプロジェクトにコピー（またはシンボリックリンク）
cp /path/to/harness/scripts/denylist.conf .devcontainer/denylist.conf
```

必要に応じてプロジェクト固有のルールを追加します。

### 3. Claude Code のフック設定

`.devcontainer/devcontainer.json` に Claude Code の設定を追加します。

```json
{
  "postCreateCommand": "npm install -g @anthropic-ai/claude-code && mkdir -p ~/.claude && cp /workspace/.devcontainer/claude-settings.json ~/.claude/settings.json"
}
```

`.devcontainer/claude-settings.json` を作成します。

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

### 4. devcontainer 内で Claude Code を起動

```bash
# VS Code の "Reopen in Container" またはコマンドラインから
devcontainer exec --workspace-folder . claude --dangerously-skip-permissions
```

---

## 最小構成例

シンプルに試したい場合の最小構成です。

```
your-project/
├── .devcontainer/
│   ├── devcontainer.json
│   └── denylist.conf       # カスタムdenyリスト（任意）
└── scripts/
    ├── block-dangerous.sh   # harness から持ってくる
    └── denylist.conf        # harness から持ってくる
```

**devcontainer.json（最小構成）**

```json
{
  "name": "Claude Code Sandbox",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu-22.04",
  "postCreateCommand": "npm install -g @anthropic-ai/claude-code"
}
```

devcontainer 内で実行するだけで、ホスト環境への影響をコンテナに封じ込められます。

---

## ネットワーク制御（オプション）

外部ネットワークへのアクセスを制限する場合は Docker Compose を使います。

```yaml
# .devcontainer/docker-compose.yml
version: '3.8'
services:
  sandbox:
    image: mcr.microsoft.com/devcontainers/base:ubuntu-22.04
    volumes:
      - ../:/workspace:cached
    networks:
      - sandbox-net

networks:
  sandbox-net:
    driver: bridge
    internal: true   # 外部ネットワークへのアクセスを遮断
```

```json
{
  "dockerComposeFile": "docker-compose.yml",
  "service": "sandbox",
  "workspaceFolder": "/workspace"
}
```

> **注意**: `internal: true` を設定すると npm install などの外部通信もブロックされます。`postCreateCommand` でのパッケージインストールは事前にイメージに含めておくか、ネットワーク設定前に実行してください。

---

## GitHub Actions での利用

```yaml
# .github/workflows/claude-agent.yml
name: Claude Code Agent

on:
  issues:
    types: [opened, assigned]

jobs:
  implement:
    runs-on: ubuntu-latest
    container:
      image: mcr.microsoft.com/devcontainers/base:ubuntu-22.04
    steps:
      - uses: actions/checkout@v4

      - name: Setup Claude Code
        run: npm install -g @anthropic-ai/claude-code

      - name: Setup denylist hook
        run: |
          mkdir -p ~/.claude
          cat > ~/.claude/settings.json <<'EOF'
          {
            "hooks": {
              "PreToolUse": [
                {
                  "matcher": "Bash",
                  "hooks": [
                    {
                      "type": "command",
                      "command": "DENYLIST_PATH=$GITHUB_WORKSPACE/scripts/denylist.conf $GITHUB_WORKSPACE/scripts/block-dangerous.sh"
                    }
                  ]
                }
              ]
            }
          }
          EOF

      - name: Run Claude Code Agent
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude --dangerously-skip-permissions "Issue #${{ github.event.issue.number }} を実装してください"
```

---

## 関連ドキュメント

- [--dangerously-skip-permissions の安全な利用ガイド](../../docs/dangerously-skip-permissions.md)
- [denyリスト設定ファイル](../../scripts/denylist.conf)
- [block-dangerous.sh](../../scripts/block-dangerous.sh)
