#!/bin/bash
# block-dangerous.sh
# 危険なコマンドの実行をブロックするフック
#
# 環境変数:
#   TOOL_INPUT    - 実行予定のコマンド
#   DENYLIST_PATH - カスタムdenyリストのパス（省略時はスクリプトと同じディレクトリの denylist.conf を使用）

COMMAND="$TOOL_INPUT"

if [ -z "$COMMAND" ]; then
  exit 0
fi

# denyリストのパスを決定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DENYLIST_FILE="${DENYLIST_PATH:-$SCRIPT_DIR/denylist.conf}"

# denyリストファイルが存在しない場合はスキップ
if [ ! -f "$DENYLIST_FILE" ]; then
  exit 0
fi

# denyリストを1行ずつ処理（タブ文字で PATTERN と MESSAGE を分割）
while IFS=$'\t' read -r PATTERN MESSAGE; do
  # コメント行・空行はスキップ
  case "$PATTERN" in
    '#'*|'') continue ;;
  esac

  # パターンが空の場合はスキップ
  if [ -z "$PATTERN" ]; then
    continue
  fi

  # [case-insensitive] プレフィックスの処理
  GREP_OPT="-E"
  if [ "${PATTERN#\[case-insensitive\]}" != "$PATTERN" ]; then
    PATTERN="${PATTERN#\[case-insensitive\]}"
    GREP_OPT="-iE"
  fi

  # パターンにマッチした場合はブロック
  if echo "$COMMAND" | grep -q $GREP_OPT "$PATTERN"; then
    echo "BLOCKED: ${MESSAGE}" >&2
    exit 2
  fi

done < "$DENYLIST_FILE"

exit 0
