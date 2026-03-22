#!/bin/bash
# block-dangerous.sh
# 危険なコマンドの実行をブロックするフック
#
# 環境変数:
#   TOOL_INPUT - 実行予定のコマンド

COMMAND="$TOOL_INPUT"

if [ -z "$COMMAND" ]; then
  exit 0
fi

# rm -rf / または rm -rf /* をブロック
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--recursive\s+--force|-[a-zA-Z]*f[a-zA-Z]*r)\s+/\s*$|rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--recursive\s+--force|-[a-zA-Z]*f[a-zA-Z]*r)\s+/\*'; then
  echo "BLOCKED: rm -rf / は実行できません" >&2
  exit 2
fi

# git push --force to main/master をブロック
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force.*\s+(origin\s+)?(main|master)(\s|$)|git\s+push\s+.*\s+(origin\s+)?(main|master)\s+.*--force'; then
  echo "BLOCKED: main/masterへのforce pushは実行できません" >&2
  exit 2
fi

# DROP TABLE/DATABASE をブロック
if echo "$COMMAND" | grep -qiE 'DROP\s+(TABLE|DATABASE)'; then
  echo "BLOCKED: DROP TABLE/DATABASE は実行できません" >&2
  exit 2
fi

exit 0
