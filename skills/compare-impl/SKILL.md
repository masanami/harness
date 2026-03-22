---
name: compare-impl
description: "単一Issueに対しN案を並列実装し、比較評価→選定→ブラッシュアップする。Triggers on: '/compare-impl', '候補比較実装'"
argument-hint: "<Issue番号> -c N"
model: opus
---

# 候補比較実装指示書

**あなたは候補比較を統括するリードエージェントです。**

単一のGitHub Issueに対してN個の実装候補をAgent Teamsで並列生成し、比較評価→ユーザー選定→ブラッシュアップを行います。

> 通常のIssue実装（候補比較なし）は `/para-impl` を使用してください。

---

## 入力パラメータ

GitHub Issue番号と候補数: $ARGUMENTS

### パース方法

`$ARGUMENTS` を以下のルールで解釈する:

- **数値**: Issue番号（1つのみ）
- **`--candidates N`** (または `-c N`): 候補数（デフォルト: 2）
- 例:
  - `1 --candidates 3` → issue=1, candidates=3
  - `1 -c 2` → issue=1, candidates=2

---

## 実行手順

> Phase番号は「AI駆動開発戦略」セクション4「エージェントの1チケット実行フロー」に準拠する。

### Phase 1: Issue分析（設計理解）

1. **Issueの取得と分析**
   ```bash
   gh issue view {番号} --json title,body,state,labels,number
   ```
   - Issueの内容を確認し、実装要件を把握する

2. **Issue種別の判断**
   - **新規機能実装**: `implement-feature` エージェントを使用
   - **既存機能の変更/バグ修正**: `modify-feature` エージェントを使用

---

### Phase 2: 実行計画 — Agent Teams構成の提案

N個の候補をAgent Teamsで並列実装する構成をユーザーに提案する。

> **重要**: Agent Teamsはスキルから自動的に起動することはできません。ユーザーがClaude Codeに対して明示的にチーム構成を指示する必要があります。

##### 提案フォーマット

```
## 候補比較 Agent Teams 構成提案

Issue #{番号} に対し、{N}候補の並列実装を行います。

### チーム構成

| teammate | 候補 | ブランチ名 |
|----------|------|-----------|
| teammate-1 | candidate-1 | feature/issue-{番号}-candidate-1-{説明} |
| teammate-2 | candidate-2 | feature/issue-{番号}-candidate-2-{説明} |
| ... | ... | ... |

### 各teammateの実行フロー

**重要: 各候補は他の候補とは異なるアプローチで実装すること。**

各teammateはPhase 3〜5を独立に実行します：

**準備:**
- origin/mainからブランチを作成
- 依存関係のインストール

**Phase 3-5（実装・テスト・コミット）:**
- implement-feature/modify-featureエージェントの手順に従い、独自のアプローチで実装
- 品質チェック（lint, typecheck, test）
- セルフレビュー（code-reviewer, design-reviewer, doc-verifier）
- コミット（Conventional Commits形式）
- プッシュ

### worktreeについて

候補間のファイル競合を排除するため、各teammateはworktreeで独立に作業します。
候補評価・選定完了後、Phase 6.5でworktreeをクリーンアップします。

---

この構成でAgent Teamsを起動してよろしいですか？
```

##### ユーザーの承認後

ユーザーが構成を承認したら、以下のようにAgent Teamsの起動を依頼する：

```
上記の構成でAgent Teamsを起動してください。
各teammateにはworktreeを使用して独立した環境で作業させてください。
```

> **注意**: 実際のAgent Teams起動はユーザー（またはClaude Code本体）が行います。このスキルからは起動できません。

---

### Phase 6: 候補評価・選定・ブラッシュアップ

全teammateの実装完了後、`skills/evaluate-candidates/SKILL.md` の手順に従い、**対話モード**で候補評価を実行する:

1. **比較レポート生成**: 各候補ブランチの比較レポートを生成
2. **ユーザー選定**: レポートを提示し、ユーザーに候補を選択してもらう
3. **ブラッシュアップ**: 不採用候補の優れた点を選定候補に取り込み
4. **セルフレビュー**: ブラッシュアップ後の選定候補に対し、code-reviewer・design-reviewer・doc-verifierの観点でセルフレビューを実施。指摘があれば修正する

セルフレビュー完了後、選定ブランチのプッシュを確認してから次のPhaseへ進む。

#### エッジケース処理

- **全候補 failed**: 評価フェーズをスキップし、失敗報告をユーザーに提示して終了
- **成功候補が1つだけ**: 比較・ブラッシュアップをスキップし、Phase 7へ進む

#### Phase 6.5: Worktreeクリーンアップ

選定・ブラッシュアップ完了後、全候補のworktreeを削除し、選定ブランチを通常チェックアウトする。

```bash
git worktree list
git worktree remove {候補1のworktreeパス} --force
git worktree remove {候補2のworktreeパス} --force
# ... 全候補分を繰り返す

git checkout {選定されたブランチ名}
```

> **重要**: このステップにより、以降の作業（PR作成等）がメインの作業ディレクトリで確実に実行される。

---

### Phase 7: PR作成

1. **選択された候補からPR作成**
   ```bash
   gh pr create --title "{タイトル}" --body "Closes #{番号}\n\n## 変更内容\n\n{選択候補のアプローチ説明}\n\n## ブラッシュアップ\n\n他候補の優れた点を取り込み済み\n\n## 候補比較\n\n{N}候補中から選定" --base main --head {選定ブランチ名}
   ```

2. **不採用ブランチの削除**
   ```bash
   git push origin --delete {不採用ブランチ名}
   ```

---

### Phase 8: 完了報告

以下を報告：
1. 生成した候補数と成功数
2. 選定された候補のアプローチ
3. ブラッシュアップで取り込んだ改善点のサマリー
4. PRのURL
5. 比較レポートのサマリー

---

## 成果物

- プロダクションコード
- テストコード
- Pull Request

---

## 禁止事項

- スコープ外の機能追加
- PRの自己マージ
- 設計ドキュメントなしでの大規模実装開始
- テストなしでのコード追加

---

## ユーザーへの確認タイミング

以下の場合はユーザーに確認を求めてください：
- Issueの要件が不明確な場合
- Agent Teams構成の承認
- 候補選定時
- スコープの拡大が必要と判断した場合
