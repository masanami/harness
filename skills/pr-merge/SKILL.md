---
name: pr-merge
description: "PRのレビューとマージを実施する。Triggers on: '/pr-merge', 'PRをマージして', 'マージして'"
argument-hint: "[PR番号]"
model: opus
---

# PR確認・マージ指示書

**あなたはPRのレビューとマージを担当する管理エージェントです。**

---

## 前提条件

- このスキルは**メインリポジトリ**で実行される
- GitHub CLIが設定済みであること
- PRは並列実装エージェントによって作成されている

---

## 入力パラメータ

PR番号: $ARGUMENTS

> **注意**: PR番号が指定されない場合は、現在のブランチに関連付けられたPRを対象とします。
> GitHub CLIは引数なしで実行すると、現在のブランチのPRを自動検出します。

---

## 実行手順

### Phase 1: PR情報の確認

1. **PRの詳細を取得**
   ```bash
   gh pr view $ARGUMENTS --json title,body,state,reviews,comments,reviewRequests
   ```

2. **CI/チェック状態の確認**
   ```bash
   gh pr checks $ARGUMENTS
   ```
   - 全てのチェックがパスしているか確認
   - 失敗している場合は原因を報告し、対応を検討

3. **マージ可能性の確認**
   ```bash
   gh pr view $ARGUMENTS --json mergeable,mergeStateStatus
   ```

### Phase 2: コンフリクト解消（必要な場合）

mergeableが`CONFLICTING`の場合：

1. **PRのブランチをローカルに取得**
   ```bash
   git fetch origin
   gh pr checkout $ARGUMENTS
   ```

2. **mainの最新を取り込んでコンフリクト解消**
   ```bash
   git fetch origin main
   git rebase origin/main
   ```
   - コンフリクトが発生したファイルを確認
   - 各ファイルのコンフリクトを手動で解消
   - 解消後: `git add <ファイル> && git rebase --continue`

3. **解消結果をプッシュ**
   ```bash
   git push --force-with-lease
   ```

4. **CI再確認**
   ```bash
   gh pr checks $ARGUMENTS --watch
   ```

### Phase 3: コードレビュー

1. **変更差分の確認**
   ```bash
   gh pr diff $ARGUMENTS
   ```

2. **レビュー観点**
   - 実装がIssueの要件を満たしているか
   - コーディング規約に従っているか
   - テストが適切に書かれているか
   - セキュリティ上の問題がないか

3. **問題がある場合**
   - PRにコメントを残す
   ```bash
   gh pr comment $ARGUMENTS --body "修正依頼: {内容}"
   ```
   - 実装エージェントに修正を依頼

### Phase 4: マージ

1. **マージ実行**
   ```bash
   gh pr merge $ARGUMENTS --squash --delete-branch
   ```
   - `--squash`: コミットを1つにまとめる
   - `--delete-branch`: マージ後にブランチを削除

2. **マージ確認**
   ```bash
   gh pr view $ARGUMENTS --json state
   ```

---

## 判断基準

### マージ可能な条件
- 全てのCIチェックがパス
- コンフリクトがない（または解消済み）
- コードレビューで重大な問題がない

### マージを保留する条件
- CIが失敗している
- 要件を満たしていない
- セキュリティ上の懸念がある

---

## ユーザーへの確認タイミング

以下の場合はユーザーに確認を求めてください：
- コンフリクト解消の判断が難しい場合
- コードに重大な問題を発見した場合
- マージ方法（squash/merge/rebase）を変更したい場合

---

## 作業完了時

作業が完了したら、以下を報告してください：
1. PRの状態（マージ完了 / 保留 / 修正依頼）
2. コンフリクト解消の有無と内容
3. レビューで発見した問題点（あれば）
4. 次のアクション（必要な場合）
