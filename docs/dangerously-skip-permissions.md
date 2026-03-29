# --dangerously-skip-permissions の安全な利用ガイド

## 概要

`--dangerously-skip-permissions` は Claude Code の実行時オプションで、ツール実行の都度表示される確認プロンプトをスキップします。これにより、長時間の自律実行が可能になりますが、危険なコマンドが意図せず実行されるリスクがあります。

本ガイドでは `block-dangerous.sh` と denyリストを組み合わせることで、このリスクを軽減しながら安全に `--dangerously-skip-permissions` を活用する方法を説明します。

---

## リスクと対策

| リスク | 対策 |
|--------|------|
| 危険なコマンドの意図しない実行 | denyリスト (`denylist.conf`) でブロック |
| カスタマイズしにくいブロックルール | 外部ファイルでのdenyリスト管理 |
| 本番環境での意図しない操作 | devcontainer などのサンドボックス環境で実行 |

---

## セットアップ

### 1. フックの設定

`settings.json`（または `.claude/settings.json`）に以下を追加します。

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/harness/scripts/block-dangerous.sh"
          }
        ]
      }
    ]
  }
}
```

### 2. denyリストの確認・カスタマイズ

デフォルトのdenyリストは `scripts/denylist.conf` に定義されています。

```
# 形式: PATTERN<TAB>MESSAGE  (区切り文字はタブ文字)
rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|...)[[:space:]]+/[[:space:]]*$<TAB>rm -rf / は実行できません
```

プロジェクト固有のルールを追加する場合は、`DENYLIST_PATH` 環境変数でカスタムファイルを指定します。

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "DENYLIST_PATH=/path/to/custom-denylist.conf /path/to/harness/scripts/block-dangerous.sh"
          }
        ]
      }
    ]
  }
}
```

### 3. --dangerously-skip-permissions で起動

```bash
claude --dangerously-skip-permissions
```

---

## denyリストのデフォルト設定

`scripts/denylist.conf` には以下のパターンが初期設定されています。

### ファイルシステム破壊系

| パターン | 説明 |
|----------|------|
| `rm -rf /` | ルートディレクトリ全体の削除 |
| `rm -rf /*` | ルート直下の全ファイル削除 |
| `rm -rf $HOME` / `rm -rf ~` | ホームディレクトリ全体の削除 |

### Gitリポジトリ破壊系

| パターン | 説明 |
|----------|------|
| `git push --force origin main/master` | main/masterへの強制プッシュ |
| `git push -f origin main/master` | main/masterへの強制プッシュ（短縮形） |
| `git reset --hard origin/main` | リモートの状態に強制リセット |

### データベース破壊系

| パターン | 説明 |
|----------|------|
| `DROP TABLE` | テーブルの削除 |
| `DROP DATABASE` | データベースの削除 |
| `TRUNCATE TABLE` | テーブルデータの全削除 |

### システム・権限系

| パターン | 説明 |
|----------|------|
| `chmod 777 /` | ルートディレクトリの権限変更 |
| `chown -R root /` | ルートディレクトリのオーナー変更 |

---

## カスタムdenyリストの書き方

```
# コメント行（# で始まる）
# 空行は無視される

# 形式: PATTERN<TAB>MESSAGE  (区切り文字はタブ文字)
# PATTERN: 拡張正規表現（grep -E で評価）、POSIX文字クラス [[:space:]] を使用
# MESSAGE: ブロック時に表示するメッセージ

# 大文字小文字を区別しない場合は [case-insensitive] プレフィックスを付ける
[case-insensitive]DROP[[:space:]]+(TABLE|DATABASE)<TAB>DROP TABLE/DATABASE は実行できません

# プロジェクト固有のルール例
kubectl[[:space:]]+delete[[:space:]]+namespace[[:space:]]+production<TAB>productionネームスペースの削除は実行できません
```

---

## 推奨設定例

### CI/CD 環境での利用

```bash
# GitHub Actions などで安全に自律実行する場合
export DENYLIST_PATH="/workspace/.github/claude-denylist.conf"
claude --dangerously-skip-permissions --no-update-check
```

### devcontainer 環境での利用

devcontainer を使ったサンドボックス環境での実行については、`skills/sandboxed-run/SKILL.md` を参照してください。

---

## 注意事項

- `--dangerously-skip-permissions` は**信頼できる環境**でのみ使用してください
- denyリストはすべての危険なコマンドを網羅するものではありません。あくまで追加の安全策です
- 本番環境での直接実行は避け、devcontainerやステージング環境で実行することを推奨します
- denyリストのパターンは定期的に見直し、プロジェクトのニーズに合わせて更新してください
