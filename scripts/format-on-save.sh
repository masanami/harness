#!/bin/bash
# format-on-save.sh
# Write/Edit後にファイルのフォーマットを自動実行するフック
#
# 環境変数:
#   TOOL_OUTPUT - ツール出力（ファイルパスを含む）

# ツール出力からファイルパスを抽出
FILE_PATH=""
if [ -n "$TOOL_OUTPUT" ]; then
  # Write/Edit toolの出力からファイルパスを抽出
  FILE_PATH=$(echo "$TOOL_OUTPUT" | grep -oE '/[^ ]+\.[a-zA-Z]+' | head -1)
fi

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# ファイル拡張子を取得
EXT="${FILE_PATH##*.}"

# プロジェクトルートを探索（git root）
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

format_with_prettier() {
  if command -v npx &>/dev/null && [ -f "$PROJECT_ROOT/node_modules/.bin/prettier" ]; then
    npx prettier --write "$FILE_PATH" 2>/dev/null
    return $?
  elif command -v prettier &>/dev/null; then
    prettier --write "$FILE_PATH" 2>/dev/null
    return $?
  fi
  return 1
}

format_with_black() {
  if command -v black &>/dev/null; then
    black --quiet "$FILE_PATH" 2>/dev/null
    return $?
  fi
  return 1
}

format_with_gofmt() {
  if command -v gofmt &>/dev/null; then
    gofmt -w "$FILE_PATH" 2>/dev/null
    return $?
  fi
  return 1
}

format_with_rustfmt() {
  if command -v rustfmt &>/dev/null; then
    rustfmt "$FILE_PATH" 2>/dev/null
    return $?
  fi
  return 1
}

case "$EXT" in
  js|jsx|ts|tsx|json|css|scss|less|html|md|yaml|yml|vue|svelte)
    format_with_prettier
    ;;
  py)
    format_with_black
    ;;
  go)
    format_with_gofmt
    ;;
  rs)
    format_with_rustfmt
    ;;
  *)
    # 未対応の拡張子はスキップ
    ;;
esac

exit 0
