---
name: create-ticket
description: "GitHub Issueとしてチケットを作成する。Triggers on: '/create-ticket', 'チケットを作成', 'Issueを作って', 'create ticket'"
---

# チケット作成

プロジェクトのチケット記述ガイドラインに従い、GitHub Issueとしてチケットを作成します。

## 手順

### 1. チケット種別の確認

ユーザーに確認:
- **要件チケット**（親チケット）: ビジネス要件の定義
- **実装チケット**: 具体的な実装タスク

### 2. 情報の収集

チケットに必要な情報を収集:
- 概要
- 背景・目的
- 完了条件 / 受入基準
- 技術的な制約（あれば）
- 依存関係（あれば）

### 3. テンプレートに沿って記述

チケット種別に応じたテンプレートを使用:
- 要件チケット: `skills/create-ticket/templates/requirement-ticket.md`
- 実装チケット: `skills/create-ticket/templates/implementation-ticket.md`

### 4. GitHub Issue作成

```bash
gh issue create --title "{タイトル}" --body "{本文}" --label "{ラベル}"
```

### 5. 親子関係の設定

実装チケットの場合、親チケットへのリンクを本文に含める:
- `Parent: #番号`
