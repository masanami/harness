---
name: agent-memory
description: "Use this skill when the user asks to save, remember, recall, or organize memories. Triggers on: '記憶して', '覚えておいて', 'メモして', '思い出して', '○○について教えて', 'remember this', 'save this', 'recall'. Also use proactively when discovering valuable findings worth preserving."
---

# Agent Memory

会話を超えて知識を保存するための永続的なスペース。

**保存場所**: `.claude/skills/agent-memory/memories/`

## Proactive Usage（積極的な活用）

### 保存すべきもの

- 発見に手間がかかった調査結果
- コードベースの非自明なパターンや落とし穴
- 複雑な問題の解決策
- 設計判断とその根拠
- 後で再開される可能性のある進行中の作業

### 確認すべきタイミング

- 問題領域の調査を開始する前
- 以前対応した機能の作業時
- 会話中断後の作業再開時

### 整理すべきタイミング

- 同一トピックのメモが分散している場合は統合
- 古くなった情報は削除
- 完了・ブロック・放棄時はステータスを更新

## Folder Structure

ケバブケースでカテゴリを作成。

```
memories/
├── issue-123/
│   └── investigation.md
├── feature-auth/
│   ├── design-decision.md
│   └── implementation-notes.md
├── api-integration/
│   └── external-service-mapping.md
└── project-context/
    └── architecture-decisions.md
```

## Frontmatter

### 必須フィールド

```yaml
---
summary: "1-2行の簡潔な説明"
created: 2025-01-10
---
```

### オプションフィールド

```yaml
updated: 2025-01-15
status: in-progress  # in-progress | resolved | blocked | abandoned
tags: [kintone, data-sync, investigation]
related: [src/features/sync/kintone/]
```

## Search Workflow

```bash
# カテゴリ一覧
ls .claude/skills/agent-memory/memories/

# 全サマリーを検索
rg "^summary:" .claude/skills/agent-memory/memories/ --no-ignore --hidden

# キーワード検索（--no-ignore --hidden 必須）
rg "kintone" .claude/skills/agent-memory/memories/ --no-ignore --hidden
```

## Operations

### Save（保存）

1. 適切なカテゴリを決定
2. 既存カテゴリを確認、または新規作成
3. 必須frontmatter付きでファイルを作成

### Maintain（メンテナンス）

- 更新時は `updated` フィールドを追加
- 不要になったメモは削除
- 関連するメモは統合
- 必要に応じてカテゴリを再編成

## Guidelines

1. **自己完結的に**: 前提知識なしで理解できる内容にする
2. **簡潔に**: サマリーは判断材料になる情報を含める
3. **最新に保つ**: 情報が古くなったら更新または削除
4. **実用的に**: 将来役立つ内容のみを記録

## Content Reference

詳細なメモに含める要素（必要なもののみ）：

- **Context**: 目標、背景、制約条件
- **Status**: 完了、進行中、ブロック中
- **Details**: 主要ファイル、コマンド、コードスニペット
- **Next Steps**: 次のアクション、未解決の質問
