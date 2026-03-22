---
name: commit
description: "Conventional Commits形式でコミットする。Triggers on: '/commit', 'コミットして', 'commit changes'"
model: sonnet
---

# Conventional Commit

変更をConventional Commits形式でコミットします。

## 手順

### 1. 変更の確認

```bash
git status
git diff --staged
git diff
```

ステージされていない変更がある場合は、関連する変更をステージングします。

### 2. 変更の分析

変更内容を分析し、適切なコミットタイプを決定:

| Type       | 説明                      |
|------------|-------------------------|
| `feat`     | 新機能追加                   |
| `fix`      | バグ修正                    |
| `docs`     | ドキュメントのみの変更             |
| `style`    | コードの意味に影響しない変更（フォーマット等） |
| `refactor` | バグ修正でも機能追加でもないコード変更     |
| `perf`     | パフォーマンス改善               |
| `test`     | テストの追加・修正               |
| `chore`    | ビルドプロセスやツールの変更          |
| `ci`       | CI設定の変更                 |

### 3. コミットメッセージの作成

フォーマット:
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

ルール:
- scopeはプロジェクトの規約に従う（パッケージ名、機能領域等）
- descriptionは日本語で記述、命令形（「〜を追加」「〜を修正」）、50文字以内目安
- bodyには変更の詳細を記述（必要な場合）
- footerには関連Issue番号を記載（`Refs: #123`）

### 4. コミット実行

```bash
git commit -m "<message>"
```

### 5. コミット粒度

- 1つのコミットは1つの論理的な変更
- 動作する状態でコミット
- 大きな変更は複数のコミットに分割
