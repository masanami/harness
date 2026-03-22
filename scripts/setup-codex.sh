#!/usr/bin/env bash
set -euo pipefail

# Codex CLI セットアップスクリプト
# harness プラグインの Codex CLI 用ファイルをターゲットプロジェクトに配置します。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CODEX_SRC="$HARNESS_ROOT/codex"

# ターゲットディレクトリの決定
TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "=== Codex CLI セットアップ ==="
echo "ソース: $CODEX_SRC"
echo "ターゲット: $TARGET_DIR"
echo ""

# 1. .codex/ ディレクトリ作成、config.toml + agents/*.toml をコピー
echo "[1/3] .codex/ ディレクトリをセットアップ中..."
mkdir -p "$TARGET_DIR/.codex/agents"
cp "$CODEX_SRC/config.toml.template" "$TARGET_DIR/.codex/config.toml"
cp "$CODEX_SRC/agents/"*.toml "$TARGET_DIR/.codex/agents/"
echo "  ✓ .codex/config.toml"
echo "  ✓ .codex/agents/*.toml (5ファイル)"

# 2. .agents/skills/ ディレクトリ作成、全スキルをコピー
echo "[2/3] .agents/skills/ ディレクトリをセットアップ中..."
mkdir -p "$TARGET_DIR/.agents/skills"

for skill_dir in "$CODEX_SRC/skills/"*/; do
    skill_name="$(basename "$skill_dir")"
    mkdir -p "$TARGET_DIR/.agents/skills/$skill_name"
    cp -r "$skill_dir"* "$TARGET_DIR/.agents/skills/$skill_name/"
done
echo "  ✓ .agents/skills/ (18スキル)"

# 3. AGENTS.md をプロジェクトルートにコピー
echo "[3/3] AGENTS.md をセットアップ中..."
if [ -f "$TARGET_DIR/AGENTS.md" ]; then
    echo "  ⚠ AGENTS.md は既に存在します。上書きをスキップしました。"
    echo "    新しいテンプレートは AGENTS.md.new として配置しました。"
    cp "$CODEX_SRC/AGENTS.md.template" "$TARGET_DIR/AGENTS.md.new"
else
    cp "$CODEX_SRC/AGENTS.md.template" "$TARGET_DIR/AGENTS.md"
    echo "  ✓ AGENTS.md"
fi

echo ""
echo "=== セットアップ完了 ==="
echo ""
echo "次のステップ:"
echo "  1. AGENTS.md のプレースホルダー ({...}) をプロジェクトに合わせて記入"
echo "  2. .codex/config.toml の model や sandbox_mode を必要に応じて調整"
echo "  3. Codex CLI で動作確認: codex"
echo ""
echo "セットアップされたファイル構成:"
echo "  $TARGET_DIR/"
echo "  ├── AGENTS.md"
echo "  ├── .codex/"
echo "  │   ├── config.toml"
echo "  │   └── agents/"
echo "  │       ├── code-reviewer.toml"
echo "  │       ├── design-reviewer.toml"
echo "  │       ├── implement-feature.toml"
echo "  │       ├── modify-feature.toml"
echo "  │       └── doc-verifier.toml"
echo "  └── .agents/"
echo "      └── skills/"
echo "          ├── para-impl/SKILL.md"
echo "          ├── self-review/SKILL.md"
echo "          ├── run-e2e/SKILL.md"
echo "          ├── pr-review-respond/SKILL.md"
echo "          ├── rebase/SKILL.md"
echo "          ├── pr-merge/SKILL.md"
echo "          ├── commit/SKILL.md"
echo "          ├── test/SKILL.md"
echo "          ├── quality-check/SKILL.md"
echo "          ├── create-ticket/"
echo "          │   ├── SKILL.md"
echo "          │   └── templates/"
echo "          └── agent-memory/SKILL.md"
