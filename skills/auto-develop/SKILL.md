---
name: auto-develop
description: "要件docまたは親Issueから設計→チケット分解→実装→マージまで一気通貫で自律実行する。Triggers on: '/auto-develop'"
argument-hint: "<要件docパス> | --from-issue <番号> [-i <番号>] [-c N] [--sequential] [--skip-design] [--note \"...\"]"
model: opus
disable-model-invocation: true
---

# 自律開発（Lv.0）

> **このスキルはユーザーが `/auto-develop` で直接起動する専用スキルです。エージェントやサブエージェントから呼び出さないでください。**

**あなたは薄いオーケストレーターです。** 各フェーズの実作業はすべて Task tool（サブエージェント）に委譲し、メインセッションのコンテキスト消費を最小化してください。

> **Lv.0 モード**: ユーザー確認を一切行わず、すべての判断をベストエフォートで自律決定する。提案・確認はすべてオートアグリーで進める。

---

## 入力パラメータ

入力: $ARGUMENTS

### パース方法

`$ARGUMENTS` を以下のルールで解釈する:

#### エントリーポイント（先頭部分）

| 入力形式 | 解釈 | 開始フェーズ |
|---------|------|------------|
| `<path>` | 要件ドキュメントのパス | Phase 1 → 2 → 3 → 4 → 5 |
| `--from-issue <番号>` (短縮: `-i <番号>`) | 親Issue番号（要件チケット済み） | Phase 2 → 3 → 4 → 5 |

#### オプションフラグ

- **`--candidates N`** (短縮: `-c N`): 設計候補数（Phase 2 で設計を N 案比較する。デフォルト: 1）
- **`--sequential`**: 全チケットを逐次実装する（デフォルト: 並列）
- **`--skip-design`**: 設計フェーズ（Phase 2）をスキップする
- **`--note "..."`**: 追加指示。全サブエージェントのプロンプトに注入する

#### 例

```bash
# 要件docからフル実行（Phase 1→2→3→4→5）
/auto-develop docs/req.md
/auto-develop docs/req.md -c 2  # 設計2案比較 + 並列実装（デフォルト）

# 要件docから設計スキップ（Phase 1→3→4→5）
/auto-develop docs/req.md --skip-design

# 親Issueから開始（Phase 2→3→4→5）
/auto-develop --from-issue #42
/auto-develop -i #42 --sequential  # 逐次実装

# 親Issueから設計スキップ（Phase 3→4→5）
/auto-develop -i #42 --skip-design
```

---

## 追加指示の注入

`--note` が指定されている場合、**すべてのサブエージェントプロンプト**の末尾（結果返却セクションの直前）に以下を追加する:

```
## 追加指示

{{NOTE}}
```

`--note` が未指定の場合は何も追加しない。

---

## 参照するスキル・エージェント

本スキルのサブエージェントは以下のスキル・エージェント定義ファイルを **読み込んで手順に従う**。インラインでの手順重複を避け、一元管理されたスキル定義を利用する。

| 用途 | 参照ファイル |
|------|------------|
| チケット作成 | `skills/create-ticket/SKILL.md` + テンプレート |
| 設計 | `skills/design/SKILL.md` + テンプレート |
| 新規機能実装 | `agents/implement-feature.md` |
| 既存機能変更 | `agents/modify-feature.md` |
| 品質チェック | `skills/quality-check/SKILL.md` |
| コミット | `skills/commit/SKILL.md` |
| レビュー対応 | `skills/pr-review-respond/SKILL.md` |
| マージ | `skills/pr-merge/SKILL.md` |

---

## エントリーポイント解決

パース結果に基づき、開始フェーズを決定する:

```
$ARGUMENTS をパース

if --from-issue (-i):
  → parent = 指定されたIssue番号
  → if --skip-design:
      → Phase 3 へ
    else:
      → Phase 2 へ
else (パス指定):
  → doc_path = 指定されたパス
  → Phase 1 へ
```

---

## オーケストレーション手順

---

### Phase 1: 要件分析 & 親チケット作成

> **開始条件**: パスが指定された場合のみ実行。`--from-issue` の場合はスキップ。

Task tool で **general-purpose** サブエージェントを **1つ** 起動する。

以下のプロンプトを渡すこと（`{{DOC_PATH}}` を実際のパスに置換）:

````
あなたは要件分析エージェントです。以下の手順を実行してください。

## Step 0: プロジェクト理解

プロジェクトルートの `CLAUDE.md` を読み、技術スタック・開発規約・開発原則を把握する。

## Step 1: 要件ドキュメントの読み込み

`{{DOC_PATH}}` を確認し、要件を分析する。

- **ファイルの場合**: そのファイルを読み込む
- **ディレクトリの場合**: 配下の全 `.md` ファイルを Glob で列挙し、すべて読み込む。各ファイルの内容を統合して要件全体を把握する

## Step 2: チケット作成スキルの読み込み

`skills/create-ticket/SKILL.md` を読み込み、チケット作成の手順・テンプレートを把握する。以降のチケット作成はすべてこのスキルの手順に従うこと。

## Step 3: 親チケット（要件）の作成

create-ticket スキルの「要件チケット」の手順に従い、要件全体を表す親チケットを GitHub Issue として作成する。

作成された Issue 番号を記録する。

## Step 4: 結果の返却

**必ず以下の JSON 形式のみを最終出力として返却すること。** 説明文は不要。

```json
{
  "parent": 親チケット番号,
  "doc_path": "{{DOC_PATH}}"
}
```
````

Task の返却値から `parent`, `doc_path` を取得する。

- `--skip-design` の場合: Phase 3 へ進む
- それ以外: Phase 2 へ進む

---

### Phase 2: 設計

> **開始条件**: `--skip-design` が指定されていない場合に実行。
> **スキップ条件**: `--skip-design` 指定時、または `--from-issue` の場合。

Task tool で **general-purpose** サブエージェントを **1つ** 起動する。

以下のプロンプトを渡すこと（`{{PARENT_ISSUE}}` を実際の番号に、`{{CANDIDATES}}` を candidates 値に置換）:

````
あなたは設計エージェントです。親Issue #{{PARENT_ISSUE}} の要件に基づき、設計ドキュメントを作成してください。

## Step 0: 設計スキルの読み込み

`skills/design/SKILL.md` を読み込み、設計の手順・テンプレートを把握する。

## Step 1: 設計の実行

設計スキルの手順に従い、以下を実行する:

- 入力: 親Issue #{{PARENT_ISSUE}}
- モード: `--auto`（自動モード。ユーザー確認なし）
- 候補数: {{CANDIDATES}}（1 の場合は通常実行、2 以上の場合は `-c {{CANDIDATES}} --auto` を渡して設計候補を比較する）

設計スキルの Step 1〜4（プロジェクト理解、要件読み込み、コードベース分析、設計ドキュメント作成）をすべて実行すること。

## Step 2: 結果の返却

**必ず以下の JSON 形式のみを最終出力として返却すること。** 説明文は不要。

```json
{
  "parent": {{PARENT_ISSUE}},
  "design_doc": "設計ドキュメントのパス",
  "candidates_evaluated": {{CANDIDATES}}
}
```
````

Task の返却値から `parent`, `design_doc`, `candidates_evaluated` を取得し、Phase 3 へ進む。

---

### Phase 3: 実装チケットへの分解

> **開始条件**: Phase 2 完了後、または `--from-issue --skip-design` の場合。
> **スキップ条件**: `--from-issue` の場合（チケットが既に存在する）。

Task tool で **general-purpose** サブエージェントを **1つ** 起動する。

以下のプロンプトを渡すこと（`{{PARENT_ISSUE}}`, `{{DESIGN_DOC}}` を実際の値に置換。設計スキップ時は `{{DESIGN_DOC}}` を `null` とする）:

````
あなたはチケット分解エージェントです。親Issue #{{PARENT_ISSUE}} の要件を実装チケットに分解してください。

## Step 0: プロジェクト理解

プロジェクトルートの `CLAUDE.md` を読み、技術スタック・開発規約・開発原則を把握する。

## Step 1: 要件・設計の読み込み

1. 親Issueの内容を取得する:
   ```bash
   gh issue view {{PARENT_ISSUE}} --json title,body,state,labels,number
   ```

2. 設計ドキュメントがある場合は読み込む:
   - 設計ドキュメント: `{{DESIGN_DOC}}`
   - `null` の場合はスキップ。親Issueの要件本文のみを根拠にする

## Step 2: チケット作成スキルの読み込み

`skills/create-ticket/SKILL.md` を読み込み、チケット作成の手順・テンプレートを把握する。

## Step 3: 実装チケットへの分解

要件（と設計ドキュメント）を実装可能な単位に分解し、create-ticket スキルの「実装チケット」の手順に従い、各タスクを GitHub Issue として作成する。

**設計ドキュメントがある場合**: 設計書の「実装計画 > チケット分解案」を基にチケットを作成する。設計書に記載された変更対象ファイル・API設計・処理フローを各チケットの技術的指示に反映する。

**依存関係の特定**: 分解時にチケット間の依存関係を分析すること。あるチケットが別のチケットの成果物（API、型定義、DB スキーマ等）に依存する場合、テンプレートの「依存チケット」セクションに明記する。

作成順序に注意: 依存先のチケットを先に作成し、依存元のチケットの本文で依存先の Issue 番号を参照できるようにする。

## Step 4: 結果の返却

**必ず以下の JSON 形式のみを最終出力として返却すること。** 説明文は不要。

`issues` 配列は **依存関係を考慮した実行順序** で並べること（依存先が先、依存元が後）。
`dependencies` には各チケットの依存先チケット番号を記載する。依存がないチケットは空配列。

```json
{
  "parent": {{PARENT_ISSUE}},
  "issues": [実装チケット番号, ...],
  "dependencies": {
    "チケット番号": [依存先チケット番号, ...],
    "チケット番号": []
  }
}
```

例:
```json
{
  "parent": 10,
  "issues": [11, 12, 13, 14],
  "dependencies": {
    "11": [],
    "12": [],
    "13": [11],
    "14": [11, 12]
  }
}
```
この例では #11 と #12 は独立（並列可）、#13 は #11 に依存、#14 は #11 と #12 の両方に依存。
````

Task の返却値から `parent`, `issues`, `dependencies` を取得する。JSON をパースし、チケット番号リスト・依存関係マップを保持する。

---

### Phase 4: チケットの実装→レビュー→マージ

実行モードは `parallel` フラグで決まる（candidates は Phase 2 の設計比較で使用済みのため、Phase 4 では常に単一実装）:

| parallel | 動作 |
|----------|------|
| true（デフォルト） | 並列: ウェーブ内並列実装→逐次リベース&マージ |
| false（--sequential指定時） | 逐次: 実装→マージ→次（issues配列の順序で依存を担保） |


---

#### parallel=false（--sequential指定時）: 逐次実装

各チケットに対して以下の Step A〜B を実行する。

##### Step A: 実装 & PR作成

Task tool で **general-purpose** サブエージェントを **1つ** 起動する。

以下のプロンプトを渡すこと（`{{ISSUE_NUMBER}}` を実際の番号に置換）:

````
あなたは実装エージェントです。GitHub Issue #{{ISSUE_NUMBER}} を実装し、PR作成まで完了してください。

## Step 0: スキル・エージェント定義の読み込み

以下のファイルを読み込み、各工程の手順を把握する:
- `CLAUDE.md` — プロジェクト構成・規約・コマンド
- `agents/implement-feature.md` — TDD実装手順
- `skills/quality-check/SKILL.md` — 品質チェック手順
- `skills/commit/SKILL.md` — コミット規約

## Step 1: チケット内容の把握

```bash
gh issue view {{ISSUE_NUMBER}} --json title,body,state,labels,number
```

チケットの要件・完了条件・技術的指示を理解する。

## Step 2: ブランチ作成

```bash
git fetch origin main
git checkout -b feature/issue-{{ISSUE_NUMBER}}-$(gh issue view {{ISSUE_NUMBER}} --json title -q '.title' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | head -c 40) origin/main
```

## Step 3: 実装

implement-feature エージェントの手順に従い TDD で実装する。依存関係のインストールも含む。

## Step 4: 品質チェック

quality-check スキルの手順に従い lint, typecheck, test を実行する。エラーがあれば修正を試みる。修正できない場合もベストエフォートで続行する。

## Step 5: コミット & プッシュ

commit スキルの手順に従い Conventional Commits 形式でコミットし、プッシュする。

```bash
git push -u origin {ブランチ名}
```

## Step 6: PR 作成

```bash
gh pr create --title "{タイトル}" --body "Closes #{{ISSUE_NUMBER}}\n\n## 変更内容\n\n{変更サマリー}\n\n## テスト\n\n{テスト結果}" --base main
```

## Step 7: 結果の返却

**必ず以下の JSON 形式のみを最終出力として返却すること。** 説明文は不要。

```json
{ "issue": {{ISSUE_NUMBER}}, "pr_number": PR番号, "pr_url": "PR の URL", "status": "success または partial または failed" }
```
````

Task の返却値から `issue`, `pr_number`, `pr_url`, `status` を取得する。

`status` が `failed` の場合は Step B をスキップし、失敗として記録して次のチケットへ進む。

##### Step B: レビュー対応 & マージ

Step A で `status` が `success` または `partial` の場合、Task tool で **general-purpose** サブエージェントを **1つ** 起動する。

以下のプロンプトを渡すこと（`{{PR_NUMBER}}`, `{{ISSUE_NUMBER}}` を実際の値に置換）:

````
あなたはレビュー対応 & マージエージェントです。PR #{{PR_NUMBER}}（Issue #{{ISSUE_NUMBER}}）のレビュー対応とマージを完了してください。

## Step 0: スキル定義の読み込み

以下のファイルを読み込み、各工程の手順を把握する:
- `CLAUDE.md` — プロジェクト構成・規約
- `skills/pr-review-respond/SKILL.md` — レビュー対応手順
- `skills/pr-merge/SKILL.md` — マージ手順

## Step 1: レビュー待ち & 対応

まず、外部レビュー（CodeRabbit等）の投稿を待つ。

```bash
gh pr view {{PR_NUMBER}} --json reviews -q '.reviews | length'
```

レビューがまだ投稿されていない場合は、最大10回まで 60秒間隔で再確認する（最大約10分）。10回確認してもレビューが投稿されなければ、レビューなしとして Step 2 に進む。

レビューが投稿されたら、pr-review-respond スキルの手順に従い、PR #{{PR_NUMBER}} のレビューコメントに対応する。

**Lv.0 モード**: 設計変更の提案は、合理的なら採用。大規模変更はスキップして理由をコメント。

## Step 2: マージ

pr-merge スキルの手順に従い、PR #{{PR_NUMBER}} をマージする。

## Step 3: 結果の返却

**必ず以下の JSON 形式のみを最終出力として返却すること。** 説明文は不要。

```json
{ "issue": {{ISSUE_NUMBER}}, "pr_number": {{PR_NUMBER}}, "merged": true または false, "review_comments_handled": 対応したコメント数, "status": "merged または review_responded または failed" }
```
````

Task の返却値を蓄積し、**次のチケットへ進む**。

---

#### parallel=true（デフォルト）: 依存関係を考慮した並列実装→逐次マージ

依存関係グラフに基づき **ウェーブ方式** でチケットを並列実装する。同じウェーブ内のチケットは並列で実装し、ウェーブ単位で逐次リベース＆マージする。

##### Step 0: ウェーブの算出

`dependencies` マップから実行ウェーブを計算する:

1. **Wave 1**: 依存先がないチケット（`dependencies[issue] == []`）
2. **Wave 2**: 依存先がすべて Wave 1 に含まれるチケット
3. **Wave N**: 依存先がすべて Wave 1〜N-1 に含まれるチケット
4. すべてのチケットがウェーブに割り当てられるまで繰り返す

例（`dependencies: { "11": [], "12": [], "13": [11], "14": [11, 12] }`）:
- Wave 1: [#11, #12]（依存なし → 並列実装）
- Wave 2: [#13, #14]（#11, #12 のマージ完了後に並列実装）

##### Step A: ウェーブごとの並列実装

各ウェーブに対して以下を繰り返す:

**A-1. 当該ウェーブのチケットを並列実装**

ウェーブ内の全チケットに対し、Task を **並列** で起動する。

- **subagent_type**: `general-purpose`
- **isolation**: `"worktree"`（チケット同士のファイル競合を排除）

各タスクのプロンプトは逐次モードの Step A 実装エージェントプロンプトと同一。ただしPR作成は **行わない**（ブランチにプッシュするのみ）。

結果返却のJSONに以下を追加:
```json
{ "issue": {{ISSUE_NUMBER}}, "branch": "ブランチ名", "pr_number": null, "status": "success または partial または failed" }
```

**A-2. 当該ウェーブのチケットを逐次リベース & PR作成 & マージ**

当該ウェーブ内の成功したチケットを **逐次** ループし、以下を実行する:

1. **リベース**: `git fetch origin main && git checkout {ブランチ名} && git rebase origin/main`
   コンフリクトが発生した場合はベストエフォートで解消。解消できない場合はスキップして失敗として記録。

2. **品質チェック**: quality-check スキルの手順に従い再実行。失敗した場合は修正を試みる。

3. **プッシュ & PR作成**: `git push -u origin {ブランチ名} --force-with-lease` → `gh pr create`

4. **レビュー対応 & マージ**: 逐次モードの Step B と同じプロンプトでTaskを起動する。

5. **次のチケットへ進む**（次のチケットのリベースは今マージした内容を含む）

**A-3. 次のウェーブへ進む**

当該ウェーブの全チケットのマージが完了（または失敗として記録）されたら、次のウェーブへ進む。

> **依存先が失敗した場合**: 依存先チケットのマージが失敗した場合、そのチケットに依存するチケットもスキップし、失敗として記録する。

> **ポイント**: 依存関係を尊重しつつ、独立したチケットは並列で高速化。ウェーブ単位でマージを完了させるため、次のウェーブは前ウェーブの成果物を利用可能。

---

### Phase 5: 完了報告

全チケットの処理が完了したら、メインセッション内で以下の形式で報告する:

#### candidates == 1 の場合

```
## 自律開発 完了報告

### 親チケット
- #{parent番号}

### 設計ドキュメント
- {design_doc が null の場合は「設計スキップ」、それ以外はパスを表示}

### 実装結果

| Issue | PR | 実装 | レビュー対応 | マージ |
|-------|-----|------|------------|--------|
| #{番号} | PR URL | success/partial/failed | N件対応 | merged/failed/skipped |
| ... | ... | ... | ... | ... |

### サマリー
- 実装成功: N件
- マージ完了: N件
- 失敗: N件
```

#### candidates > 1 の場合（設計比較モード）

```
## 自律開発 完了報告（設計比較モード）

### 親チケット
- #{parent番号}

### 設計比較
- 設計候補数: N案
- 選定された設計: {design_doc のパス}

### 実装結果

| Issue | PR | 実装 | レビュー対応 | マージ |
|-------|-----|------|------------|--------|
| #{番号} | PR URL | success/partial/failed | N件対応 | merged/failed/skipped |
| ... | ... | ... | ... | ... |

### サマリー
- 設計候補: N案比較→選定済み
- 実装成功: N件
- マージ完了: N件
- 失敗: N件
```

---

## 重要な設計判断

- **ユーザー直接起動専用**: エージェントやサブエージェントからの呼び出し禁止
- **ユーザー確認を一切行わない**: AskUserQuestion は使用禁止。判断はすべて自律的に行う
- **エントリーポイント**: 要件docパス指定、または `--from-issue`（`-i`）で親Issue指定の2通り
- **設計フェーズ**: Phase 2 で設計ドキュメントを生成し、Phase 3 のチケット分解に活用。`--skip-design` で省略可能（小規模変更・設計済みの場合）
- **スキル・エージェント参照**: 各工程の詳細手順はスキル/エージェント定義ファイルを読み込んで従う。本スキルでは手順を重複記述しない
- **依存関係の明示**: Phase 3 でチケット間の依存関係を分析し、結果JSONに `dependencies` マップとして返却。逐次モードでは `issues` 配列の順序で依存を担保し、並列モードではウェーブ方式で依存を尊重する
- **並列モード（デフォルト）**: 依存関係グラフからウェーブを算出し、同一ウェーブ内のチケットを並列実装→逐次リベース&マージ。依存先が失敗した場合は依存元もスキップする
- **逐次モード（--sequential）**: チケットを1つずつ「実装→レビュー→マージ」のサイクルで処理。`issues` 配列の順序（依存先が先）で自然に解決する
- **設計比較モード（--candidates N）**: Phase 2 で設計を N 案比較→選定→実装は常に1回。設計比較は design スキル内で完結する
- **追加指示（--note）**: 全サブエージェントプロンプトに追加指示を注入。環境固有の制約を伝達する
- **エラー時はスキップ**: 止まらずマージまで進めて結果を報告
- **コンテキスト節約**: 各 Task は独立。メインセッションはチケット番号・PR番号・ステータスのみ保持
