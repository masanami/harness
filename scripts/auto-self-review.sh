#!/bin/bash
# auto-self-review.sh
# Write/Edit後にself-reviewの必要性を判定し、トリガー通知を出力するフック
#
# 環境変数（Claude Code hooksから渡される）:
#   TOOL_NAME   - 実行されたツール名（Write / Edit）
#   TOOL_INPUT  - ツールへの入力（JSONを含む場合あり）
#   TOOL_OUTPUT - ツールの出力

# ==========================================
# ファイルパスの抽出
# ==========================================
FILE_PATH=""

# TOOL_INPUTからfile_pathキーを抽出（JSON形式）
if [ -n "$TOOL_INPUT" ]; then
  FILE_PATH=$(echo "$TOOL_INPUT" | grep -oE '"file_path"\s*:\s*"[^"]+"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
fi

# TOOL_OUTPUTからも試みる
if [ -z "$FILE_PATH" ] && [ -n "$TOOL_OUTPUT" ]; then
  FILE_PATH=$(echo "$TOOL_OUTPUT" | grep -oE '/[^ ]+\.[a-zA-Z0-9]+' | head -1)
fi

# ファイルパスが取得できない場合はスキップ
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# ==========================================
# スキップ条件
# ==========================================

# 存在しないファイルはスキップ
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# 一時ファイルはスキップ
case "$FILE_PATH" in
  /tmp/*|*.tmp|*.temp|*.swp|*.bak)
    exit 0
    ;;
esac

# node_modules はスキップ
if echo "$FILE_PATH" | grep -q 'node_modules/'; then
  exit 0
fi

# .git 配下はスキップ
if echo "$FILE_PATH" | grep -q '/.git/'; then
  exit 0
fi

# ビルド成果物はスキップ
if echo "$FILE_PATH" | grep -qE '/(dist|build|out|\.next|\.nuxt|coverage)/'; then
  exit 0
fi

# ロックファイルはスキップ（大量の差分が出るため）
case "$(basename "$FILE_PATH")" in
  package-lock.json|yarn.lock|pnpm-lock.yaml|Gemfile.lock|Cargo.lock)
    exit 0
    ;;
esac

# ==========================================
# レビュー対象ファイル種別の判定
# ==========================================
EXT="${FILE_PATH##*.}"
FILENAME="$(basename "$FILE_PATH")"

SHOULD_REVIEW=0

case "$EXT" in
  # スクリプト・設定・ドキュメント
  sh|bash|zsh|fish)
    SHOULD_REVIEW=1
    REVIEW_REASON="シェルスクリプトの変更（セキュリティ・実行権限に影響する可能性）"
    ;;
  json|yaml|yml|toml)
    SHOULD_REVIEW=1
    REVIEW_REASON="設定ファイルの変更（動作・フック設定に影響する可能性）"
    ;;
  md|markdown)
    SHOULD_REVIEW=1
    REVIEW_REASON="ドキュメントの変更（仕様・手順の正確性確認）"
    ;;
  # プログラミング言語
  js|jsx|ts|tsx|mjs|cjs)
    SHOULD_REVIEW=1
    REVIEW_REASON="JavaScriptコードの変更"
    ;;
  py)
    SHOULD_REVIEW=1
    REVIEW_REASON="Pythonコードの変更"
    ;;
  go)
    SHOULD_REVIEW=1
    REVIEW_REASON="Goコードの変更"
    ;;
  rs)
    SHOULD_REVIEW=1
    REVIEW_REASON="Rustコードの変更"
    ;;
  rb)
    SHOULD_REVIEW=1
    REVIEW_REASON="Rubyコードの変更"
    ;;
  java|kt|kts)
    SHOULD_REVIEW=1
    REVIEW_REASON="JVM言語コードの変更"
    ;;
  cs|fs|vb)
    SHOULD_REVIEW=1
    REVIEW_REASON=".NETコードの変更"
    ;;
  cpp|cc|c|h|hpp)
    SHOULD_REVIEW=1
    REVIEW_REASON="C/C++コードの変更"
    ;;
  # バイナリ・画像はスキップ
  png|jpg|jpeg|gif|svg|ico|webp|bmp)
    exit 0
    ;;
  pdf|doc|docx|xls|xlsx|ppt|pptx)
    exit 0
    ;;
  zip|tar|gz|bz2|xz|7z|rar)
    exit 0
    ;;
  *)
    # 拡張子なし or 不明な場合はファイル名で判断
    case "$FILENAME" in
      Makefile|Dockerfile|Jenkinsfile|Procfile|Rakefile)
        SHOULD_REVIEW=1
        REVIEW_REASON="ビルド・実行定義ファイルの変更"
        ;;
      *)
        # 不明な拡張子はスキップ
        exit 0
        ;;
    esac
    ;;
esac

# ==========================================
# レビュー通知の出力
# ==========================================
if [ "$SHOULD_REVIEW" -eq 1 ]; then
  echo ""
  echo "=========================================="
  echo "  [auto-self-review] レビュー推奨"
  echo "=========================================="
  echo "  対象ファイル : $FILE_PATH"
  echo "  理由         : $REVIEW_REASON"
  echo ""
  echo "  /self-review を呼び出すと変更差分のセルフレビューを実施します。"
  echo "  マルチエージェントでより詳細なレビューを行う場合:"
  echo "  /self-review --agents 3"
  echo "=========================================="
  echo ""
fi

exit 0
