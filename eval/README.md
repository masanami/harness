# ハーネス評価シナリオ

harness のスキル・エージェントの品質を検証するための評価シナリオ集です。

評価フレームワークの設計思想・指標の定義・評価実行方法の詳細は [評価フレームワーク設計ドキュメント](../docs/evaluation-framework.md) を参照してください。

---

## シナリオ一覧

| スキル | シナリオファイル | ケース数 |
|--------|----------------|---------|
| self-review | [scenarios/self-review.md](scenarios/self-review.md) | 5 |
| para-impl | [scenarios/para-impl.md](scenarios/para-impl.md) | 5 |
| reduce-debt | [scenarios/reduce-debt.md](scenarios/reduce-debt.md) | 4 |

---

## 評価実行手順

### 1. 評価環境のセットアップ

評価はハーネスをインストール済みのテスト用リポジトリで実施します。

```bash
# テスト用リポジトリを用意（既存の開発リポジトリでも可）
git clone <テスト用リポジトリURL>
cd <リポジトリ名>

# harness がインストールされていることを確認
# Claude Code プラグインとして利用可能な状態にする
```

### 2. シナリオの前提条件を整備

各シナリオの「前提」セクションに従い、評価環境を整えます。

- GitHub Issues の作成（必要な場合）
- テスト用ブランチの準備
- サンプルコードの配置

### 3. スキルを実行して観察

シナリオの「入力」に従いスキルを呼び出し、「期待する動作」と照らし合わせながら実行を観察します。

### 4. 合否を判定

「チェック方法」に従い、「合格基準」を満たしているか確認します。合否は YESかNO で判定します。

### 5. 結果を記録

`eval/results/{YYYY-MM-DD}/{スキル名}.md` に結果を記録します。

```bash
mkdir -p eval/results/$(date +%Y-%m-%d)
```

記録フォーマット:

```markdown
# {スキル名} 評価結果 {YYYY-MM-DD}

## 評価環境
- 実施日: {日付}
- 評価者: {氏名}
- 対象バージョン: {コミットハッシュ（git rev-parse HEAD）}

## 結果サマリー

| ケース | 合否 | 備考 |
|--------|------|------|
| TC-01 | PASS | - |
| TC-02 | FAIL | {失敗理由} |

## 詳細

### TC-01: {ケース名}
- 合否: PASS
- 実行ログ: {ログへのリンクや要約}
- 所見: {気づき・改善提案}
```

---

## 評価実施タイミング

| トリガー | 対象スキル | 実施方式 |
|----------|-----------|----------|
| スキルのプロンプト変更（SKILL.md更新） | 変更対象スキル | 手動評価 |
| エージェント定義変更（agents/*.md更新） | 関連スキル全体 | 手動評価 |
| 新スキル追加 | 追加スキル | 手動評価（全ケース） |
| ハーネス全体のメジャーアップデート | 全スキル | 手動評価 |

---

## 新スキル追加時のシナリオ整備

新しいスキルを harness に追加する際は、以下の手順でシナリオを整備してください。

1. `eval/scenarios/{スキル名}.md` を作成する
2. 既存のシナリオファイル（[self-review.md](scenarios/self-review.md) 等）のフォーマットに準拠する
3. 少なくとも以下のケースを含める:
   - 正常系1ケース（典型的なユースケース）
   - 副作用確認1ケース（スコープ外変更がないこと）
4. このREADMEのシナリオ一覧テーブルに追記する
5. PRレビュー時にシナリオの実行可能性を確認する

---

## テストリポジトリのセットアップ

評価を実行するには、フィクスチャからテスト用リポジトリを作成します。

```bash
# harness リポジトリのルートから実行
bash eval/fixtures/setup.sh [リポジトリ名]
```

作成されるもの:
- フィクスチャコード（`src/utils.js`, `src/auth.js`, `src/legacy.js`）
- 評価シナリオ（`eval/scenarios/` をコピー）
- GitHub リポジトリ・評価用 Issues（任意）

詳細は [eval/fixtures/README.md](fixtures/README.md) を参照。

---

## 評価の実行（`/run-eval` スキル）

テストリポジトリで Claude Code を開き、以下を実行:

```text
/run-eval {スキル名} {TC番号}
例: /run-eval self-review TC-01
```

スキルが以下をガイドします:
1. **セットアップ**: ブランチ作成やコードの準備手順を案内
2. **実行**: 対象スキルのコマンドを提示
3. **判定**: 合格基準を1項目ずつ P/F/S で確認
4. **記録**: `eval/results/{日付}/{スキル名}-{TC番号}.md` に自動保存

---

## ディレクトリ構成

```text
eval/
├── README.md               # このファイル（評価実行方法の説明）
├── fixtures/               # テストリポジトリ テンプレート
│   ├── README.md           # fixtures の説明
│   ├── setup.sh            # テストリポジトリ作成スクリプト
│   ├── CLAUDE.md           # テストリポジトリ用コーディング規約
│   ├── package.json
│   ├── .eslintrc.json
│   ├── src/
│   │   ├── utils.js        # クリーンなコード
│   │   ├── auth.js         # 規約違反・セキュリティ問題あり
│   │   └── legacy.js       # 技術負債あり
│   └── tests/
│       └── utils.test.js
├── scenarios/              # 評価シナリオ
│   ├── self-review.md
│   ├── para-impl.md
│   └── reduce-debt.md
└── results/                # 評価結果（.gitignore 推奨）
    └── YYYY-MM-DD/
        └── {スキル名}-{TC番号}.md
```
